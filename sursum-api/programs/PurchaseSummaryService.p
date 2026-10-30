/* Context and transport for readonly summary; all arithmetic is shared. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttSummary NO-UNDO
 FIELD proc_compra_id AS INTEGER FIELD qt_container AS INTEGER
 FIELD cotacao_prevista AS DECIMAL DECIMALS 10 FIELD custo_prev_itens AS DECIMAL DECIMALS 10
 FIELD despesas_base AS DECIMAL DECIMALS 10 FIELD custo_prev_despesas AS DECIMAL DECIMALS 10
 INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE VARIABLE pid AS INTEGER NO-UNDO. DEFINE VARIABLE recordId AS INTEGER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SUMMARY'.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SUMMARY_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE dataValue AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
{sursum-api/includes/PurchaseOrderContext.i}
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phExpenses) THEN RUN Fail('PURCHASE_SUMMARY_CONFIGURATION',503,'Configuracao indisponivel.').
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(code,422,'Requisicao obrigatoria.').
 pid=PurchaseJsonId(poRequest,'proc_compra_id').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation').
 IF LOOKUP(op,'read,get')=0 THEN RUN Fail('PURCHASE_SUMMARY_READ_ONLY',405,'Resumo somente leitura.').
 ns=poRequest:GetNames().
 DO i=1 TO EXTENT(ns):
  IF LOOKUP(ns[i],IF op='get' THEN 'operation,proc_compra_id,id' ELSE 'operation,proc_compra_id,skip,take,sort,filter')=0 THEN RUN Fail(code,422,'Campo nao permitido.').
 END.
 IF op='get' THEN DO: recordId=PurchaseJsonId(poRequest,'id'). IF recordId<>pid THEN RUN Fail('PURCHASE_SUMMARY_NOT_FOUND',404,'Resumo nao encontrado.'). END.
 RUN OrderContextCheck(NO-LOCK).
 CREATE ttSummary. ASSIGN ttSummary.proc_compra_id=pid
  ttSummary.qt_container=phOrders:BUFFER-FIELD('qt_container'):BUFFER-VALUE
  ttSummary.cotacao_prevista=phOrders:BUFFER-FIELD('cotacao_prevista'):BUFFER-VALUE.
 pathValue=SEARCH('sursum-api/programs/PurchaseForecastTotals.r').
 IF pathValue=? THEN RUN Fail('PURCHASE_SUMMARY_CONFIGURATION',503,'Coletor nao publicado.').
 ASSIGN code='PURCHASE_SUMMARY_UNAVAILABLE' statusCode=503.
 RUN VALUE(pathValue)(phItems,phExpenses,pid,ttSummary.cotacao_prevista,ttSummary.qt_container,OUTPUT ttSummary.custo_prev_itens,OUTPUT ttSummary.despesas_base,OUTPUT ttSummary.custo_prev_despesas).
 /* Reuse bounded sort/filter/paging. get is converted to the same one-row read. */
 requestCopy=CAST(poRequest:Clone(),JsonObject). requestCopy:Remove('proc_compra_id').
 IF op='get' THEN DO: requestCopy:Remove('id'). requestCopy:Set('operation','read'). END.
 pathValue=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF pathValue=? THEN RUN Fail('PURCHASE_SUMMARY_CONFIGURATION',503,'Leitor nao publicado.').
 RUN VALUE(pathValue)(INPUT BUFFER ttSummary:HANDLE,'proc_compra_resumo',N(pid),requestCopy,OUTPUT poResponse).
 IF op='get' AND poResponse:GetLogical('success') THEN DO:
  dataValue=CAST(poResponse:GetJsonArray('data'):GetJsonObject(1):Clone(),JsonObject).
  poResponse:Remove('total'). poResponse:Remove('data'). poResponse:Add('data',dataValue).
 END.
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE).
  errorValue=NEW JsonObject(). errorValue:Add('code',code). errorValue:Add('status',statusCode).
  errorValue:Add('message','Resumo do processo invalido ou indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
END.
