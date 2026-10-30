/* Private reusable version-generation snapshot. Exactly one DB collector run;
   both currencies and the distinct header average share its captured input.
   No HTTP, sequence, business write, or copied financial formula. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItens AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItensProc AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phProcs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpDesp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDespesas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDespContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDistr AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDescontos AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phMotivos AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCtaDesc AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCotacoes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemCustos AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersoes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPedVendaExt AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemDocMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDocMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemDocIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDocIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPedVendaMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPedItemMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPedVendaIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPedItemIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poFinancial AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER piContainer AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttPair NO-UNDO
 FIELD itemId AS INTEGER FIELD inputPos AS INTEGER FIELD realPos AS INTEGER FIELD dollarPos AS INTEGER
 INDEX pk IS PRIMARY UNIQUE itemId.
DEFINE VARIABLE privatePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE collected AS JsonObject NO-UNDO.
DEFINE VARIABLE captured AS JsonObject NO-UNDO.
DEFINE VARIABLE dollarInput AS JsonObject NO-UNDO.
DEFINE VARIABLE dollarResult AS JsonObject NO-UNDO.
DEFINE VARIABLE traceInput AS JsonObject NO-UNDO.
DEFINE VARIABLE traceResult AS JsonObject NO-UNDO.
DEFINE VARIABLE dollarData AS JsonObject NO-UNDO.
DEFINE VARIABLE traceData AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE average AS JsonObject NO-UNDO.
DEFINE VARIABLE row AS JsonObject NO-UNDO.
DEFINE VARIABLE realRow AS JsonObject NO-UNDO.
DEFINE VARIABLE dollarRow AS JsonObject NO-UNDO.
DEFINE VARIABLE sourceItems AS JsonArray NO-UNDO.
DEFINE VARIABLE realItems AS JsonArray NO-UNDO.
DEFINE VARIABLE dollarItems AS JsonArray NO-UNDO.
DEFINE VARIABLE pairedReal AS JsonArray NO-UNDO.
DEFINE VARIABLE pairedDollar AS JsonArray NO-UNDO.
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE calculatorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL "COST_DATA_INCOMPLETE".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF piContainer=? OR piContainer<=0 THEN DO: code="INVALID_REQUEST". UNDO, THROW NEW Progress.Lang.AppError("Container inteiro positivo necessario.",1). END.
 IF NOT VALID-OBJECT(poPolicy) OR NOT VALID-OBJECT(poFinancial) THEN UNDO, THROW NEW Progress.Lang.AppError("Contexto privado de custo necessario.",1).
 code="FINANCIAL_CONTEXT_MISMATCH".
 IF NOT poFinancial:Has("source") THEN UNDO, THROW NEW Progress.Lang.AppError("Origem financeira vinculada ausente.",1).
 IF poFinancial:GetType("source")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Origem financeira vinculada invalida.",1).
 IF poFinancial:GetCharacter("source")<>"linked-payment-totals" THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot requer totais de pagamentos vinculados, sem filtros de grade.",1).
 code="COST_DATA_INCOMPLETE".
 collectorPath=SEARCH("sursum-api/programs/ContainersCustoReadService.r").
 IF collectorPath=? THEN collectorPath=SEARCH("ContainersCustoReadService.r").
 calculatorPath=SEARCH("sursum-api/programs/ContainersCustoCalculator.r").
 IF calculatorPath=? THEN calculatorPath=SEARCH("ContainersCustoCalculator.r").
 IF collectorPath=? OR calculatorPath=? THEN DO: code="COST_CONFIGURATION". UNDO, THROW NEW Progress.Lang.AppError("Coletor/calculador compilado indisponivel.",1). END.
 privatePolicy=CAST(poPolicy:Clone(),JsonObject).
 IF privatePolicy:Has("calculation_profile") THEN privatePolicy:Remove("calculation_profile").
 IF privatePolicy:Has("capture_input") THEN privatePolicy:Remove("capture_input").
 privatePolicy:Add("calculation_profile","version"). privatePolicy:Add("capture_input",TRUE).
 request=NEW JsonObject(). request:Add("operation","read"). request:Add("resource","itens"). request:Add("container_id",piContainer). request:Add("moeda","real").
 /* Single collection. All subsequent RUNs are pure JSON calculations. */
 RUN VALUE(collectorPath)(phContainer,phItens,phItensProc,phProcs,phEmpresas,phEmpDesp,phDespesas,phDespContainer,phDistr,phDescontos,phMotivos,phCtaDesc,phCotacoes,phItemCustos,phVersoes,phNfs,phPedVendaExt,phItemDocMed,phDocMed,phItemDocIma,phDocIma,phPedVendaMed,phPedItemMed,phPedVendaIma,phPedItemIma,poFinancial,privatePolicy,request,OUTPUT collected).
 IF NOT collected:GetLogical("success") THEN DO: poResponse=collected. collected=?. RETURN. END.
 captured=collected:GetJsonObject("input_snapshot").
 IF captured:GetCharacter("mode")<>"gerar_versao" OR captured:GetCharacter("currency")<>"real" OR captured:GetCharacter("calculationBasis")<>"current" OR captured:GetJsonObject("container"):GetInteger("nr-container")<>piContainer THEN UNDO, THROW NEW Progress.Lang.AppError("Perfil/contexto do snapshot de custo divergente.",1).
 dollarInput=CAST(captured:Clone(),JsonObject). dollarInput:Set("currency","dolar").
 RUN VALUE(calculatorPath)(dollarInput,OUTPUT dollarResult).
 IF NOT dollarResult:GetLogical("success") THEN DO: poResponse=dollarResult. dollarResult=?. RETURN. END.
 /* The separate legacy header call uses default logSaldoNeg=false, while
    version item cost explicitly enables the negotiated/proforma adjustment. */
 traceInput=CAST(captured:Clone(),JsonObject). traceInput:Set("mode","rastro").
 RUN VALUE(calculatorPath)(traceInput,OUTPUT traceResult).
 IF NOT traceResult:GetLogical("success") THEN DO: poResponse=traceResult. traceResult=?. RETURN. END.
 ASSIGN dollarData=dollarResult:GetJsonObject("data") traceData=traceResult:GetJsonObject("data")
  sourceItems=captured:GetJsonArray("items") realItems=collected:GetJsonArray("data") dollarItems=dollarData:GetJsonArray("items").
 DO n=1 TO sourceItems:Length:
  itemId=sourceItems:GetJsonObject(n):GetInteger("item_container_id").
  IF itemId<=0 OR CAN-FIND(FIRST ttPair WHERE ttPair.itemId=itemId) THEN UNDO, THROW NEW Progress.Lang.AppError("Identificador de item ambiguo no snapshot.",1).
  CREATE ttPair. ASSIGN ttPair.itemId=itemId ttPair.inputPos=n.
 END.
 DO n=1 TO realItems:Length:
  row=realItems:GetJsonObject(n). itemId=row:GetInteger("item_container_id").
  FIND ttPair WHERE ttPair.itemId=itemId NO-ERROR.
  IF NOT AVAILABLE ttPair THEN UNDO, THROW NEW Progress.Lang.AppError("Item em real fora dos insumos capturados.",1).
  IF ttPair.realPos<>0 OR row:GetInteger("container_id")<>piContainer THEN UNDO, THROW NEW Progress.Lang.AppError("Item em real duplicado ou fora do container.",1).
  ttPair.realPos=n.
 END.
 DO n=1 TO dollarItems:Length:
  itemId=dollarItems:GetJsonObject(n):GetInteger("item_container_id").
  FIND ttPair WHERE ttPair.itemId=itemId NO-ERROR.
  IF NOT AVAILABLE ttPair THEN UNDO, THROW NEW Progress.Lang.AppError("Item em dolar fora dos insumos capturados.",1).
  IF ttPair.dollarPos<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Item em dolar duplicado.",1).
  ttPair.dollarPos=n.
 END.
 ASSIGN pairedReal=NEW JsonArray() pairedDollar=NEW JsonArray().
 FOR EACH ttPair BY ttPair.itemId:
  IF ttPair.realPos=0 OR ttPair.dollarPos=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Conjunto de itens difere entre insumos e moedas.",1).
  ASSIGN realRow=realItems:GetJsonObject(ttPair.realPos) dollarRow=dollarItems:GetJsonObject(ttPair.dollarPos).
  IF realRow:IsNull("vl_total_real")<>dollarRow:IsNull("vl_total_real") THEN UNDO, THROW NEW Progress.Lang.AppError("Completude realizada difere entre moedas.",1).
  pairedReal:Add(CAST(realRow:Clone(),JsonObject)). pairedDollar:Add(CAST(dollarRow:Clone(),JsonObject)).
 END.
 average=NEW JsonObject(). average:Add("dolar_medio",traceData:GetDecimal("dolar_medio")). average:Add("cotacao_saldo",traceData:GetDecimal("cotacao_saldo")).
 average:Add("memory",CAST(traceData:GetJsonObject("memory"):Clone(),JsonObject)).
 data=NEW JsonObject(). data:Add("container_id",piContainer). data:Add("confirmed",TRUE). data:Add("source","container-version-cost-snapshot"). data:Add("calculation_profile","version").
 data:Add("actual_complete",dollarData:GetJsonObject("totals"):GetLogical("actual_complete")).
 data:Add("items_real",pairedReal). data:Add("items_dolar",pairedDollar). data:Add("input_snapshot",CAST(captured:Clone(),JsonObject)).
 data:Add("master_average",average). data:Add("calculation",CAST(collected:GetJsonObject("calculation"):Clone(),JsonObject)).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",data).
 CATCH err AS Progress.Lang.Error:
  RUN Fail(code,err:GetMessage(1)).
 END CATCH.
 FINALLY:
  IF VALID-OBJECT(privatePolicy) THEN DELETE OBJECT privatePolicy NO-ERROR.
  IF VALID-OBJECT(request) THEN DELETE OBJECT request NO-ERROR.
  IF VALID-OBJECT(collected) THEN DELETE OBJECT collected NO-ERROR.
  IF VALID-OBJECT(dollarInput) THEN DELETE OBJECT dollarInput NO-ERROR.
  IF VALID-OBJECT(dollarResult) THEN DELETE OBJECT dollarResult NO-ERROR.
  IF VALID-OBJECT(traceInput) THEN DELETE OBJECT traceInput NO-ERROR.
  IF VALID-OBJECT(traceResult) THEN DELETE OBJECT traceResult NO-ERROR.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER errorCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE errorObject AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorObject=NEW JsonObject().
 errorObject:Add("code",errorCode). errorObject:Add("message",messageText). errorObject:Add("status",IF errorCode="COST_CONFIGURATION" THEN 503 ELSE 422).
 poResponse:Add("success",FALSE). poResponse:Add("error",errorObject).
END PROCEDURE.
