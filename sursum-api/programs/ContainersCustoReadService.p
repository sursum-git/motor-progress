/* Fixed-buffer NO-LOCK collector. Internal financial/policy JSON originates only
   in the authenticated wrapper, never in the external request. calc_v1. */
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
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttItem NO-UNDO
 FIELD id AS INTEGER FIELD procItem AS INTEGER FIELD procId AS INTEGER
 FIELD descricao AS CHARACTER FIELD erp AS CHARACTER
 FIELD aloc AS DECIMAL DECIMALS 10 FIELD emb AS DECIMAL DECIMALS 10 FIELD recb AS DECIMAL DECIMALS 10
 FIELD tributado AS DECIMAL DECIMALS 10 FIELD proforma AS DECIMAL DECIMALS 10 FIELD negociado AS DECIMAL DECIMALS 10
 FIELD despTrib AS DECIMAL DECIMALS 10 FIELD despPro AS DECIMAL DECIMALS 10 FIELD despNeg AS DECIMAL DECIMALS 10
 FIELD descontoReal AS DECIMAL DECIMALS 10 FIELD descontoDolar AS DECIMAL DECIMALS 10 FIELD distr AS DECIMAL DECIMALS 10
 INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttReal NO-UNDO
 FIELD erp AS CHARACTER CASE-SENSITIVE FIELD motherMerc AS DECIMAL DECIMALS 10
 FIELD motherExpense AS DECIMAL DECIMALS 10 FIELD otherMerc AS DECIMAL DECIMALS 10
 INDEX pk IS PRIMARY UNIQUE erp.
DEFINE TEMP-TABLE ttNote NO-UNDO
 FIELD estab AS CHARACTER FIELD serie AS CHARACTER FIELD documento AS CHARACTER
 FIELD natureza AS CHARACTER FIELD emitente AS INTEGER
 INDEX pk IS PRIMARY UNIQUE estab serie documento natureza emitente.
DEFINE TEMP-TABLE ttSale NO-UNDO
 FIELD situacao AS INTEGER FIELD moeda AS INTEGER FIELD valor AS DECIMAL DECIMALS 10 FIELD desconto AS DECIMAL DECIMALS 10
 INDEX pk IS PRIMARY UNIQUE situacao moeda.
DEFINE VARIABLE cCode AS CHARACTER NO-UNDO INITIAL "COST_DATA_INCOMPLETE".
DEFINE VARIABLE cOperation AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cCurrency AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cRequestName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cPrefix AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNaturezas AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNat AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDoc AS CHARACTER NO-UNDO.
DEFINE VARIABLE cItemCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCalculator AS CHARACTER NO-UNDO.
DEFINE VARIABLE cWarningText AS CHARACTER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE iGet AS INTEGER NO-UNDO.
DEFINE VARIABLE iEmpresa AS INTEGER NO-UNDO.
DEFINE VARIABLE iDespesa AS INTEGER NO-UNDO.
DEFINE VARIABLE iItem AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersion AS INTEGER NO-UNDO.
DEFINE VARIABLE iEmit AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
DEFINE VARIABLE iTrace AS INTEGER NO-UNDO.
DEFINE VARIABLE hq AS HANDLE NO-UNDO.
DEFINE VARIABLE hSub AS HANDLE NO-UNDO.
DEFINE VARIABLE hThird AS HANDLE NO-UNDO.
DEFINE VARIABLE hItemDoc AS HANDLE NO-UNDO.
DEFINE VARIABLE hDoc AS HANDLE NO-UNDO.
DEFINE VARIABLE hPed AS HANDLE NO-UNDO.
DEFINE VARIABLE hPedItem AS HANDLE NO-UNDO.
DEFINE VARIABLE aInput AS JsonArray NO-UNDO.
DEFINE VARIABLE aRows AS JsonArray NO-UNDO.
DEFINE VARIABLE aRaw AS JsonArray NO-UNDO.
DEFINE VARIABLE aWarnings AS JsonArray NO-UNDO.
DEFINE VARIABLE oInput AS JsonObject NO-UNDO.
DEFINE VARIABLE oContainer AS JsonObject NO-UNDO.
DEFINE VARIABLE oQuote AS JsonObject NO-UNDO.
DEFINE VARIABLE oExpenses AS JsonObject NO-UNDO.
DEFINE VARIABLE oDiscounts AS JsonObject NO-UNDO.
DEFINE VARIABLE oItem AS JsonObject NO-UNDO.
DEFINE VARIABLE oPart AS JsonObject NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE oMath AS JsonObject NO-UNDO.
DEFINE VARIABLE oCalc AS JsonObject NO-UNDO.
DEFINE VARIABLE oData AS JsonObject NO-UNDO.
DEFINE VARIABLE oRaw AS JsonObject NO-UNDO.
DEFINE VARIABLE oMemory AS JsonObject NO-UNDO.
DEFINE VARIABLE oTotals AS JsonObject NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE dGeneral AS DECIMAL DECIMALS 10 EXTENT 3 NO-UNDO.
DEFINE VARIABLE dCreditDollar AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dCreditReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDiscountDollar AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDiscountReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dQuote AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dtQuote AS DATE NO-UNDO.
DEFINE VARIABLE dtQuoteLatest AS DATE NO-UNDO.
DEFINE VARIABLE lQuoteAmbiguous AS LOGICAL NO-UNDO.
DEFINE VARIABLE oQuoteSelection AS JsonObject NO-UNDO.
DEFINE VARIABLE oQuoteWarning AS JsonObject NO-UNDO.
DEFINE VARIABLE dMotherTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dMerc AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dExpense AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dCofins AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dPis AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dTaxCost AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSaleRate AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSalesPrev AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dSalesReal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDiscount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE lActual AS LOGICAL NO-UNDO.
DEFINE VARIABLE lVersion AS LOGICAL NO-UNDO.
DEFINE VARIABLE lCapture AS LOGICAL NO-UNDO.
DEFINE VARIABLE cProfile AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE lMother AS LOGICAL NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE BUFFER bOtherItem FOR ttItem.

FUNCTION C RETURNS CHARACTER (h AS HANDLE, f AS CHARACTER):
 DEFINE VARIABLE v AS CHARACTER NO-UNDO.
 v=h:BUFFER-FIELD(f):BUFFER-VALUE.
 IF v=? THEN UNDO, THROW NEW Progress.Lang.AppError("Campo texto desconhecido: " + f,1).
 RETURN v.
END FUNCTION.
FUNCTION AblQuote RETURNS CHARACTER (pcValue AS CHARACTER):
 DEFINE VARIABLE quoted AS CHARACTER NO-UNDO.
 IF pcValue=? THEN RETURN "?".
 quoted=REPLACE(pcValue,CHR(126),CHR(126) + CHR(126)).
 quoted=REPLACE(quoted,CHR(34),CHR(126) + CHR(34)).
 quoted=REPLACE(quoted,CHR(10),CHR(126) + "n").
 quoted=REPLACE(quoted,CHR(13),CHR(126) + "r").
 quoted=REPLACE(quoted,CHR(9),CHR(126) + "t").
 RETURN CHR(34) + quoted + CHR(34).
END FUNCTION.
FUNCTION D RETURNS DECIMAL (h AS HANDLE, f AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL DECIMALS 10 NO-UNDO.
 IF h:BUFFER-FIELD(f):EXTENT>0 THEN v=h:BUFFER-FIELD(f):BUFFER-VALUE(1).
 ELSE v=h:BUFFER-FIELD(f):BUFFER-VALUE.
 IF v=? THEN UNDO, THROW NEW Progress.Lang.AppError("Valor numerico desconhecido: " + f,1).
 RETURN v.
END FUNCTION.
FUNCTION B RETURNS LOGICAL (h AS HANDLE, f AS CHARACTER):
 DEFINE VARIABLE v AS LOGICAL NO-UNDO.
 v=h:BUFFER-FIELD(f):BUFFER-VALUE.
 IF v=? THEN UNDO, THROW NEW Progress.Lang.AppError("Valor logico desconhecido: " + f,1).
 RETURN v.
END FUNCTION.
FUNCTION Q RETURNS HANDLE (h AS HANDLE, w AS CHARACTER):
 DEFINE VARIABLE qh AS HANDLE NO-UNDO.
 CREATE QUERY qh.
 qh:SET-BUFFERS(h).
 IF NOT qh:QUERY-PREPARE("FOR EACH " + h:NAME + " NO-LOCK WHERE " + w) THEN
  UNDO, THROW NEW Progress.Lang.AppError("Consulta de custo indisponivel.",1).
 qh:QUERY-OPEN(). qh:GET-FIRST(). RETURN qh.
END FUNCTION.
FUNCTION UniqueRow RETURNS LOGICAL (h AS HANDLE, w AS CHARACTER):
 DEFINE VARIABLE qh AS HANDLE NO-UNDO.
 DEFINE VARIABLE r AS ROWID NO-UNDO.
 DEFINE VARIABLE found AS LOGICAL NO-UNDO.
 DO ON ERROR UNDO, THROW:
  qh=Q(h,w).
  IF qh:QUERY-OFF-END THEN RETURN FALSE.
  r=h:ROWID. qh:GET-NEXT().
  IF NOT qh:QUERY-OFF-END THEN DO:
   cCode="COST_AMBIGUOUS_DATA". UNDO, THROW NEW Progress.Lang.AppError("Vinculo ambiguo no coletor de custo.",1).
  END.
  found=h:FIND-BY-ROWID(r,NO-LOCK).
  IF NOT found THEN UNDO, THROW NEW Progress.Lang.AppError("Registro mudou durante a leitura.",1).
  RETURN TRUE.
  FINALLY:
   IF VALID-HANDLE(qh) THEN DO: qh:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qh NO-ERROR. END.
  END FINALLY.
 END.
END FUNCTION.
FUNCTION ExternalId RETURNS INTEGER (o AS JsonObject, f AS CHARACTER):
 DEFINE VARIABLE v AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE x AS DECIMAL NO-UNDO.
 IF NOT o:Has(f) THEN RETURN ?.
 IF o:GetType(f)=JsonDataType:NUMBER THEN v=o:GetJsonText(f).
 ELSE IF o:GetType(f)=JsonDataType:STRING THEN v=o:GetCharacter(f).
 ELSE RETURN ?.
 IF LENGTH(v)<1 OR LENGTH(v)>10 THEN RETURN ?.
 DO j=1 TO LENGTH(v): IF INDEX("0123456789",SUBSTRING(v,j,1))=0 THEN RETURN ?. END.
 x=DECIMAL(v). IF x<1 OR x>2147483647 THEN RETURN ?. RETURN INTEGER(x).
END FUNCTION.
FUNCTION Mother RETURNS LOGICAL (v AS CHARACTER):
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE e AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE cNatureValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 cNatureValue=v.
 DO j=1 TO NUM-ENTRIES(cNaturezas):
  e=TRIM(ENTRY(j,cNaturezas)).
  IF LENGTH(e)>1 AND SUBSTRING(e,1,1)="'" AND SUBSTRING(e,LENGTH(e),1)="'" THEN e=SUBSTRING(e,2,LENGTH(e) - 2).
  IF e=cNatureValue THEN RETURN TRUE.
 END.
 RETURN FALSE.
END FUNCTION.
FUNCTION TaxPart RETURNS DECIMAL (h AS HANDLE, pcField AS CHARACTER, pcRate AS CHARACTER, policyName AS CHARACTER):
 DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE aliquot AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE cost AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE id AS INTEGER NO-UNDO.
 amount=D(h,pcField).
 IF amount=0 THEN RETURN 0.
 aliquot=D(h,pcRate).
 IF aliquot=0 THEN DO:
  cCode="ZERO_DENOMINATOR". UNDO, THROW NEW Progress.Lang.AppError("Aliquota nula para tributo de NF positivo.",1).
 END.
 IF NOT poPolicy:Has(policyName) THEN DO:
  cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Parametro fiscal de despesa ausente.",1).
 END.
 id=ExternalId(poPolicy,policyName).
 IF id=? THEN DO:
  cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Parametro fiscal de despesa invalido.",1).
 END.
 IF NOT UniqueRow(phEmpDesp,phEmpDesp:NAME + ".empresa_id=" + STRING(iEmpresa) + " AND " + phEmpDesp:NAME + ".despesa_id=" + STRING(id)) THEN DO:
  cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Despesa fiscal sem vinculo a empresa.",1).
 END.
 cost=D(phEmpDesp,"percentual_custo").
 RETURN amount / aliquot * cost.
END FUNCTION.

DO ON ERROR UNDO, THROW:
 cCode="INVALID_REQUEST".
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError("Requisicao ausente.",1).
 IF NOT poRequest:Has("operation") OR NOT poRequest:Has("resource") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao e recurso necessarios.",1).
 IF poRequest:GetType("operation")<>JsonDataType:STRING OR poRequest:GetType("resource")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao ou recurso invalido.",1).
 ASSIGN cOperation=poRequest:GetCharacter("operation") cResource=poRequest:GetCharacter("resource") cCurrency="real" iContainer=ExternalId(poRequest,"container_id").
 IF NOT (cOperation="read" OR cOperation="get") OR NOT (cResource="itens" OR cResource="resumo" OR cResource="comparativos" OR cResource="rastro" OR cResource="cotacoes-fiscais") OR iContainer=? THEN
  UNDO, THROW NEW Progress.Lang.AppError("Consulta de custo invalida.",1).
 IF poRequest:Has("moeda") THEN DO:
  IF poRequest:GetType("moeda")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Moeda invalida.",1).
  cCurrency=poRequest:GetCharacter("moeda").
  IF cCurrency<>"real" AND cCurrency<>"dolar" THEN UNDO, THROW NEW Progress.Lang.AppError("Moeda invalida.",1).
 END.
 IF cResource="cotacoes-fiscais" AND (cOperation<>"read" OR cCurrency<>"real") THEN
  UNDO, THROW NEW Progress.Lang.AppError("Cotacoes fiscais aceitam somente read em real.",1).
 IF cOperation="get" THEN DO:
  iGet=ExternalId(poRequest,"id"). IF iGet=? THEN UNDO, THROW NEW Progress.Lang.AppError("Identificador necessario.",1).
  IF cResource="resumo" AND iGet<>iContainer THEN UNDO, THROW NEW Progress.Lang.AppError("ID do resumo difere do container.",1).
 END.
 ELSE IF poRequest:Has("id") THEN UNDO, THROW NEW Progress.Lang.AppError("id somente em detalhe.",1).
 cNames=poRequest:GetNames().
 DO n=1 TO EXTENT(cNames):
  cRequestName=cNames[n].
  IF cRequestName="operation" OR cRequestName="resource" OR cRequestName="container_id" OR cRequestName="id" OR cRequestName="moeda" THEN NEXT.
  IF cOperation="get" AND (((cResource="itens" OR cResource="comparativos") AND cRequestName="item_container_id") OR (cResource="rastro" AND cRequestName="rastro_id")) THEN DO:
   IF ExternalId(poRequest,cRequestName)=? OR ExternalId(poRequest,cRequestName)<>iGet THEN UNDO, THROW NEW Progress.Lang.AppError("Alias de identificador divergente.",1).
  END.
  ELSE UNDO, THROW NEW Progress.Lang.AppError("Campo externo nao permitido.",1).
 END.
 cCode="COST_CONFIGURATION".
 RUN BufferCheck(phContainer). RUN BufferCheck(phItens). RUN BufferCheck(phItensProc). RUN BufferCheck(phProcs). RUN BufferCheck(phEmpresas).
 RUN BufferCheck(phEmpDesp). RUN BufferCheck(phDespesas). RUN BufferCheck(phDespContainer). RUN BufferCheck(phDistr). RUN BufferCheck(phDescontos).
 RUN BufferCheck(phMotivos). RUN BufferCheck(phCtaDesc). RUN BufferCheck(phCotacoes). RUN BufferCheck(phItemCustos). RUN BufferCheck(phVersoes). RUN BufferCheck(phNfs).
 cCode="COST_DATA_INCOMPLETE".
 IF NOT UniqueRow(phContainer,phContainer:NAME + ".nr-container=" + STRING(iContainer)) THEN DO:
  cCode="NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1).
 END.
 ASSIGN cEstab=C(phContainer,"cod-estabel") cPrefix=SUBSTRING(cEstab,1,1) lActual=cResource="itens" OR cResource="resumo".
 IF cPrefix<>"1" AND cPrefix<>"5" THEN DO:
  cCode="COST_CONFIGURATION". UNDO, THROW NEW Progress.Lang.AppError("Empresa ERP nao mapeada.",1).
 END.
 IF NOT UniqueRow(phEmpresas,phEmpresas:NAME + ".cod_emp_ems2=" + cPrefix) THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa do container nao localizada.",1).
 iEmpresa=INTEGER(D(phEmpresas,"empresa_id")).
 IF cPrefix="5" THEN ASSIGN hItemDoc=phItemDocMed hDoc=phDocMed hPed=phPedVendaMed hPedItem=phPedItemMed.
 ELSE ASSIGN hItemDoc=phItemDocIma hDoc=phDocIma hPed=phPedVendaIma hPedItem=phPedItemIma.
 cCode="FINANCIAL_CONTEXT_MISMATCH".
 IF NOT VALID-OBJECT(poFinancial) THEN UNDO, THROW NEW Progress.Lang.AppError("Totais financeiros internos necessarios.",1).
 IF NOT poFinancial:Has("confirmed") OR NOT poFinancial:Has("container_id") OR NOT poFinancial:Has("payments") OR NOT poFinancial:Has("source") THEN
  UNDO, THROW NEW Progress.Lang.AppError("Totais financeiros internos incompletos.",1).
 IF poFinancial:GetType("confirmed")<>JsonDataType:BOOLEAN OR ExternalId(poFinancial,"container_id")<>iContainer THEN UNDO, THROW NEW Progress.Lang.AppError("Contexto financeiro invalido.",1).
 IF NOT poFinancial:GetLogical("confirmed") OR poFinancial:GetType("payments")<>JsonDataType:OBJECT OR poFinancial:GetType("source")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Leitura financeira nao confirmada.",1).
 IF NOT VALID-OBJECT(poPolicy) THEN DO: cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Politica interna ausente.",1). END.
 cCode="COST_POLICY_INVALID".
 IF poPolicy:Has("calculation_profile") THEN DO:
  IF poPolicy:GetType("calculation_profile")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Perfil interno de calculo invalido.",1).
  cProfile=poPolicy:GetCharacter("calculation_profile").
  IF cProfile<>"version" THEN UNDO, THROW NEW Progress.Lang.AppError("Perfil interno de calculo invalido.",1).
  lVersion=TRUE.
  IF cResource<>"itens" OR cOperation<>"read" OR cCurrency<>"real" THEN UNDO, THROW NEW Progress.Lang.AppError("Perfil de versao requer coleta interna unica de itens em real.",1).
 END.
 IF poPolicy:Has("capture_input") THEN DO:
  IF poPolicy:GetType("capture_input")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Captura interna de insumos invalida.",1).
  lCapture=poPolicy:GetLogical("capture_input").
  IF lCapture AND NOT lVersion THEN UNDO, THROW NEW Progress.Lang.AppError("Captura de insumos restrita ao perfil privado de versao.",1).
 END.
 ASSIGN cCode="COST_DATA_INCOMPLETE" aInput=NEW JsonArray() aRaw=NEW JsonArray() aWarnings=NEW JsonArray().
 oContainer=NEW JsonObject().
 cFields="nr-container,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar,vl-dolar-compra,vl_dolar_di,log_versao_custo_desatualizada".
 DO n=1 TO NUM-ENTRIES(cFields): RUN CopyField(oContainer,phContainer,ENTRY(n,cFields),ENTRY(n,cFields)). END.
 hq=Q(phItens,phItens:NAME + ".container_id=" + STRING(iContainer)).
 DO WHILE NOT hq:QUERY-OFF-END:
  iItem=INTEGER(D(phItens,"item_container_id")).
  CREATE ttItem. ASSIGN ttItem.id=iItem ttItem.procItem=INTEGER(D(phItens,"item_proc_compra_id")) ttItem.aloc=D(phItens,"qt_alocada") ttItem.emb=D(phItens,"qt_confirm_emb") ttItem.recb=D(phItens,"qt_recbto_fisico").
  IF NOT UniqueRow(phItensProc,phItensProc:NAME + ".item_proc_compra_id=" + STRING(ttItem.procItem)) THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra inexistente.",1).
  ASSIGN ttItem.procId=INTEGER(D(phItensProc,"proc_compra_id")) ttItem.descricao=C(phItensProc,"descricao") ttItem.erp=C(phItensProc,"codigo_erp") ttItem.tributado=D(phItensProc,"vl_base_tributacao") ttItem.proforma=D(phItensProc,"vl_custo_dolar") ttItem.negociado=D(phItensProc,"vl_negociado").
  IF NOT UniqueRow(phProcs,phProcs:NAME + ".proc_compra_id=" + STRING(ttItem.procId)) THEN UNDO, THROW NEW Progress.Lang.AppError("Processo de compra inexistente.",1).
  hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 IF NOT CAN-FIND(FIRST ttItem) AND cResource<>"cotacoes-fiscais" THEN DO:
  IF cResource="resumo" OR cResource="rastro" OR lVersion THEN UNDO, THROW NEW Progress.Lang.AppError("Container sem itens para calcular custo.",1).
  IF cOperation="get" THEN DO:
   cCode="NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Registro nao encontrado no container.",1).
  END.
  poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",NEW JsonArray()). RETURN.
 END.
 IF lActual THEN DO:
  /* ERP realization is aggregated by item code. Reusing the aggregate for
     two container children would duplicate payments, expenses and credits. */
  FOR EACH ttItem:
   IF ttItem.erp<>"" AND CAN-FIND(FIRST bOtherItem WHERE bOtherItem.erp=ttItem.erp AND bOtherItem.id<>ttItem.id) THEN DO:
    cCode="COST_AMBIGUOUS_DATA". UNDO, THROW NEW Progress.Lang.AppError("Codigo ERP corresponde a mais de um item do container; rateio por ocorrencia nao definido.",1).
   END.
  END.
  cCode="COST_CONFIGURATION". RUN BufferCheck(hItemDoc). RUN BufferCheck(hDoc).
 END.
 IF cResource="resumo" THEN DO: cCode="COST_CONFIGURATION". RUN BufferCheck(phPedVendaExt). RUN BufferCheck(hPed). RUN BufferCheck(hPedItem). END.
 cCode="COST_DATA_INCOMPLETE".
 /* Expenses use the same company/log_custo joins as the legacy SUM. */
 hq=Q(phDespContainer,phDespContainer:NAME + ".container_id=" + STRING(iContainer)).
 DO WHILE NOT hq:QUERY-OFF-END:
  ASSIGN iDespesa=INTEGER(D(phDespContainer,"despesa_id")) iItem=INTEGER(D(phDespContainer,"item_container_id")).
  lFound=UniqueRow(phEmpDesp,phEmpDesp:NAME + ".empresa_id=" + STRING(iEmpresa) + " AND " + phEmpDesp:NAME + ".despesa_id=" + STRING(iDespesa)).
  IF lFound AND UniqueRow(phDespesas,phDespesas:NAME + ".despesa_id=" + STRING(iDespesa)) THEN DO:
   IF D(phEmpDesp,"log_custo")=1 THEN DO:
    IF iItem=0 THEN DO n=1 TO 3: dGeneral[n]=dGeneral[n] + D(phDespContainer,ENTRY(n,"vl_prev,vl_proforma,vl_negociado")). END.
    ELSE DO:
     FIND ttItem WHERE ttItem.id=iItem NO-ERROR.
      /* Fiscal synchronization follows the item mutation. A removed child's
         old expense cannot supply a unit cost or enter quotation aggregates. */
      IF NOT AVAILABLE ttItem THEN DO:
       IF cResource<>"cotacoes-fiscais" THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa aponta item fora do container.",1).
      END.
      ELSE ASSIGN ttItem.despTrib=ttItem.despTrib + D(phDespContainer,"vl_prev") ttItem.despPro=ttItem.despPro + D(phDespContainer,"vl_proforma") ttItem.despNeg=ttItem.despNeg + D(phDespContainer,"vl_negociado").
    END.
   END.
  END.
  hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 FOR EACH ttItem:
  hq=Q(phDescontos,phDescontos:NAME + ".item_container_id=" + STRING(ttItem.id)).
  DO WHILE NOT hq:QUERY-OFF-END:
   IF NOT B(phDescontos,"log_credito") THEN DO:
    IF UniqueRow(phMotivos,phMotivos:NAME + ".motivo_desconto_id=" + STRING(INTEGER(D(phDescontos,"motivo_desconto_id")))) THEN DO:
     IF B(phMotivos,"log_considerar_custo") THEN ASSIGN ttItem.descontoReal=ttItem.descontoReal + D(phDescontos,"vl_real") ttItem.descontoDolar=ttItem.descontoDolar + D(phDescontos,"vl_dolar").
    END.
   END.
   hq:GET-NEXT().
  END.
  RUN CloseQ(INPUT-OUTPUT hq).
  ASSIGN dDiscountReal=dDiscountReal + ttItem.descontoReal dDiscountDollar=dDiscountDollar + ttItem.descontoDolar.
  hq=Q(phDistr,phDistr:NAME + ".item_container_id=" + STRING(ttItem.id) + " AND " + phDistr:NAME + ".cod_tipo_movto=4").
  DO WHILE NOT hq:QUERY-OFF-END: ttItem.distr=ttItem.distr + D(phDistr,"vl_lancto"). hq:GET-NEXT(). END.
  RUN CloseQ(INPUT-OUTPUT hq).
 END.
 hq=Q(phCtaDesc,phCtaDesc:NAME + ".container_id=" + STRING(iContainer)).
 DO WHILE NOT hq:QUERY-OFF-END:
  IF NOT UniqueRow(phDescontos,phDescontos:NAME + ".desconto_importacao_id=" + STRING(INTEGER(D(phCtaDesc,"desconto_importacao_id")))) THEN UNDO, THROW NEW Progress.Lang.AppError("Credito de desconto inexistente.",1).
  IF B(phDescontos,"log_credito") THEN ASSIGN dCreditDollar=dCreditDollar + D(phCtaDesc,"valor_utilizado") dCreditReal=dCreditReal + D(phCtaDesc,"valor_utilizado") * D(phDescontos,"vl_cotacao_dolar").
  hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 hq=Q(phCotacoes,phCotacoes:NAME + ".serie=1").
 DO WHILE NOT hq:QUERY-OFF-END:
  IF phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE<>? THEN DO:
   IF dtQuoteLatest=? OR phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE>dtQuoteLatest THEN dtQuoteLatest=phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE.
  END.
  IF B(phCotacoes,"log_ok") OR B(phCotacoes,"log_manual") THEN DO:
   IF D(phCotacoes,"valor")<>0 THEN DO:
    IF phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE=? THEN UNDO, THROW NEW Progress.Lang.AppError("Data de cotacao desconhecida.",1).
    IF dtQuote=? OR phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE>dtQuote THEN ASSIGN dtQuote=phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE dQuote=D(phCotacoes,"valor") lQuoteAmbiguous=FALSE.
    ELSE IF phCotacoes:BUFFER-FIELD("data"):BUFFER-VALUE=dtQuote AND dQuote<>D(phCotacoes,"valor") THEN lQuoteAmbiguous=TRUE.
   END.
  END.
  hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 IF dtQuote=? THEN UNDO, THROW NEW Progress.Lang.AppError("Cotacao valida nao encontrada.",1).
 IF lQuoteAmbiguous THEN DO:
  cCode="COST_AMBIGUOUS_DATA". UNDO, THROW NEW Progress.Lang.AppError("Cotacoes divergentes na ultima data valida.",1).
 END.
 oQuoteSelection=NEW JsonObject().
 oQuoteSelection:Add("source","hist_cotacoes_bc.latest-valid-series1"). oQuoteSelection:Add("latest_record_date",dtQuoteLatest).
 oQuoteSelection:Add("selected_date",dtQuote). oQuoteSelection:Add("selected_value",dQuote).
 oQuoteSelection:Add("skipped_invalid_latest",dtQuoteLatest>dtQuote).
 IF dtQuoteLatest>dtQuote THEN DO:
  oQuoteWarning=NEW JsonObject(). oQuoteWarning:Add("code","LATEST_QUOTATION_INVALID_SKIPPED").
  oQuoteWarning:Add("origin","calc_v1.latest-valid"). oQuoteWarning:Add("reason","Última data sem cotacao aprovada/manual de valor nao zero; usada ultima cotacao valida.").
  oQuoteSelection:Add("warning",oQuoteWarning). aWarnings:Add("LATEST_QUOTATION_INVALID_SKIPPED: calculation.quotation_selection informa datas bruta e selecionada.").
 END.
 ELSE oQuoteSelection:AddNull("warning").
 IF lActual THEN RUN CollectActual.
 FOR EACH ttItem BY ttItem.id:
  IF lActual AND aRaw:Length>0 AND ttItem.erp="" THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra sem codigo ERP para reconciliar NF.",1).
  oItem=NEW JsonObject().
  oItem:Add("item_container_id",ttItem.id). oItem:Add("qt_alocada",ttItem.aloc). oItem:Add("qt_confirm_emb",ttItem.emb). oItem:Add("qt_recbto_fisico",ttItem.recb).
  oItem:Add("vl_base_tributacao",ttItem.tributado). oItem:Add("vl_custo_dolar",ttItem.proforma). oItem:Add("vl_negociado",ttItem.negociado).
  oPart=NEW JsonObject(). oPart:Add("tributado",ttItem.despTrib). oPart:Add("proforma",ttItem.despPro). oPart:Add("negociado",ttItem.despNeg). oItem:Add("despesa_item",oPart).
  oItem:Add("distribuicao_real",ttItem.distr). oItem:Add("desconto_real",ttItem.descontoReal). oItem:Add("desconto_dolar",ttItem.descontoDolar).
  FIND ttReal WHERE ttReal.erp=ttItem.erp NO-ERROR.
  IF AVAILABLE ttReal AND lActual THEN DO:
   IF dMotherTotal=0 THEN DO: cCode="ZERO_DENOMINATOR". UNDO, THROW NEW Progress.Lang.AppError("Valor total de nota mae zerado.",1). END.
   oPart=NEW JsonObject().
   oPart:Add("vl_custo",poFinancial:GetJsonObject("payments"):GetDecimal("real") * ttReal.motherMerc / dMotherTotal).
   oPart:Add("vl_desp",ttReal.motherExpense + ttReal.otherMerc). oPart:Add("perc_rateio",ttReal.motherMerc / dMotherTotal).
   oItem:Add("erp_real",oPart).
  END.
  ELSE oItem:AddNull("erp_real").
  aInput:Add(oItem).
 END.
 ASSIGN oInput=NEW JsonObject() oQuote=NEW JsonObject() oExpenses=NEW JsonObject() oDiscounts=NEW JsonObject().
 oInput:Add("mode",IF lVersion THEN "gerar_versao" ELSE IF cResource="cotacoes-fiscais" THEN "fiscal_inputs" ELSE cResource). oInput:Add("currency",cCurrency). oInput:Add("calculationBasis","current"). oInput:Add("container",oContainer).
 oQuote:Add("valor",dQuote). oQuote:Add("data",dtQuote). oInput:Add("quotation",oQuote). oInput:Add("payments",poFinancial:GetJsonObject("payments")).
 oDiscounts:Add("credito_real",dCreditReal). oDiscounts:Add("credito_dolar",dCreditDollar). oDiscounts:Add("total_real",dDiscountReal). oDiscounts:Add("total_dolar",dDiscountDollar). oInput:Add("discounts",oDiscounts).
 DO n=1 TO 3: oExpenses:Add(ENTRY(n,"tributado,proforma,negociado"),dGeneral[n]). END.
 oInput:Add("expenses",oExpenses). oInput:Add("items",aInput).
 /* Prefer the published compiled artifact. The fixed bare .r supports the
    isolated TT runner or an explicit programs PROPATH; never compile a .p
    at runtime and never accept a procedure/path from the external request. */
 cCalculator=SEARCH("sursum-api/programs/ContainersCustoCalculator.r").
 IF cCalculator=? THEN cCalculator=SEARCH("ContainersCustoCalculator.r").
 IF cCalculator=? THEN DO:
  cCode="COST_CONFIGURATION". UNDO, THROW NEW Progress.Lang.AppError("Calculador de custo compilado indisponivel.",1).
 END.
 RUN VALUE(cCalculator)(oInput,OUTPUT oMath).
 IF NOT oMath:GetLogical("success") THEN DO: poResponse=oMath. RETURN. END.
 ASSIGN oData=oMath:GetJsonObject("data") oMemory=oData:GetJsonObject("memory") oTotals=oData:GetJsonObject("totals") aRows=NEW JsonArray().
 DO n=1 TO oData:GetJsonArray("warnings"):Length: aWarnings:Add(oData:GetJsonArray("warnings"):GetCharacter(n)). END.
 oCalc=NEW JsonObject(). oCalc:Add("source","calc_v1"). oCalc:Add("financial_source",poFinancial:GetCharacter("source")). oCalc:Add("memory",oMemory). oCalc:Add("raw_erp",aRaw). oCalc:Add("warnings",aWarnings).
 oCalc:Add("quotation_selection",oQuoteSelection).
 hq=Q(phVersoes,phVersoes:NAME + ".container_id=" + STRING(iContainer)).
 DO WHILE NOT hq:QUERY-OFF-END:
  iVersion=MAXIMUM(iVersion,INTEGER(D(phVersoes,"versao_id"))). hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 IF iVersion>0 THEN oCalc:Add("ultima_versao_id",iVersion). ELSE oCalc:AddNull("ultima_versao_id").
 oCalc:Add("versao_desatualizada",oContainer:GetLogical("log_versao_custo_desatualizada")).
 IF cResource="itens" OR cResource="comparativos" THEN DO:
  DO n=1 TO oData:GetJsonArray("items"):Length:
   oRow=oData:GetJsonArray("items"):GetJsonObject(n).
   FIND ttItem WHERE ttItem.id=oRow:GetInteger("item_container_id").
   oRow:Add("container_id",iContainer). oRow:Add("descricao",ttItem.descricao). oRow:Add("codigo_erp",ttItem.erp). oRow:Add("item_proc_compra_id",ttItem.procItem). oRow:Add("proc_compra_id",ttItem.procId).
   oRow:Add("qt_alocada",ttItem.aloc). oRow:Add("qt_confirm_emb",ttItem.emb). oRow:Add("qt_recbto_fisico",ttItem.recb).
   oRow:Add("dolar_medio",oData:GetDecimal("dolar_medio")). oRow:Add("moeda",cCurrency).
   IF iVersion>0 THEN oRow:Add("ultima_versao_id",iVersion). ELSE oRow:AddNull("ultima_versao_id").
   oRow:Add("versao_desatualizada",oContainer:GetLogical("log_versao_custo_desatualizada")).
   IF iVersion>0 AND UniqueRow(phItemCustos,phItemCustos:NAME + ".versao_id=" + STRING(iVersion) + " AND " + phItemCustos:NAME + ".item_container_id=" + STRING(ttItem.id)) THEN DO:
    /* Optional historical display fields are not current calculation inputs.
       A generated snapshot may legitimately have no realized ERP cost. */
    IF phItemCustos:BUFFER-FIELD("vl_unit_prev"):BUFFER-VALUE=? THEN oRow:AddNull("vl_unit_prev_versao").
    ELSE oRow:Add("vl_unit_prev_versao",D(phItemCustos,"vl_unit_prev")).
    IF phItemCustos:BUFFER-FIELD("vl_unit_realiz"):BUFFER-VALUE=? THEN oRow:AddNull("vl_unit_real_versao").
    ELSE oRow:Add("vl_unit_real_versao",D(phItemCustos,"vl_unit_realiz")).
   END.
   ELSE DO: oRow:AddNull("vl_unit_prev_versao"). oRow:AddNull("vl_unit_real_versao"). END.
   aRows:Add(oRow).
  END.
 END.
 ELSE IF cResource="resumo" THEN DO:
  RUN CollectSales.
  oRow=NEW JsonObject(). oRow:Add("container_id",iContainer). oRow:Add("moeda",cCurrency).
  oRow:Add("vl_total_prev",oTotals:GetDecimal("vl_total_prev")).
  IF oTotals:IsNull("vl_total_real") THEN oRow:AddNull("vl_total_real"). ELSE oRow:Add("vl_total_real",oTotals:GetDecimal("vl_total_real")).
  oRow:Add("actual_complete",oTotals:GetLogical("actual_complete")). oRow:Add("dolar_medio",oData:GetDecimal("dolar_medio")). oRow:Add("cotacao_saldo",oData:GetDecimal("cotacao_saldo")).
  oRow:Add("vl_saldo_dolar",oMemory:GetDecimal("vl_saldo_dolar")). oRow:Add("pagamentos_real",poFinancial:GetJsonObject("payments"):GetDecimal("real")). oRow:Add("pagamentos_dolar",poFinancial:GetJsonObject("payments"):GetDecimal("dolar")).
  oRow:Add("vendas_prev_real",dSalesPrev). oRow:Add("vendas_realizadas_real",dSalesReal). oRow:Add("cotacao_venda",dSaleRate). aRows:Add(oRow).
 END.
 ELSE DO:
  cFields="total_tributado_dolar,total_proforma_dolar,total_negociado_dolar,ajuste_negociado_proforma,base_dolar_medio,media_pagamentos,credito_real_convertido,desconto_real_convertido,vl_saldo_dolar,numerador_dolar_medio,denominador_dolar_medio".
  DO n=1 TO NUM-ENTRIES(cFields):
   oRow=NEW JsonObject(). oRow:Add("container_id",iContainer). oRow:Add("rastro_id",n). oRow:Add("etapa",ENTRY(n,cFields)). oRow:Add("valor",oMemory:GetDecimal(ENTRY(n,cFields))). oRow:Add("origem","calc_v1"). aRows:Add(oRow).
  END.
  oRow=NEW JsonObject(). oRow:Add("container_id",iContainer). oRow:Add("rastro_id",12). oRow:Add("etapa","dolar_medio"). oRow:Add("valor",oData:GetDecimal("dolar_medio")). oRow:Add("origem","round(numerador/denominador,5)"). aRows:Add(oRow).
 END.
 /* The generic API client retains data rows and may discard sibling metadata.
    Preserve the full calculation above and expose its scalar provenance on
    every real row so the native grid/form can display the same warnings. */
 DO n=1 TO aWarnings:Length:
  IF LENGTH(cWarningText)>=4000 THEN LEAVE.
  cWarningText=SUBSTRING(cWarningText + (IF cWarningText="" THEN "" ELSE CHR(10)) + aWarnings:GetCharacter(n),1,4000).
 END.
 DO n=1 TO aRows:Length:
  oRow=aRows:GetJsonObject(n).
  oRow:Add("calculation_source","calc_v1"). oRow:Add("calculation_warning",cWarningText).
  oRow:Add("quotation_date",dtQuote). oRow:Add("quotation_latest_date",dtQuoteLatest).
  IF oQuoteSelection:IsNull("warning") THEN oRow:AddNull("quotation_warning").
  ELSE oRow:Add("quotation_warning",oQuoteSelection:GetJsonObject("warning"):GetCharacter("code")).
 END.
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("calculation",oCalc).
 IF cOperation="get" THEN DO:
  DO n=1 TO aRows:Length:
   oRow=aRows:GetJsonObject(n).
   IF (cResource="resumo" AND iGet=iContainer) OR ((cResource="itens" OR cResource="comparativos") AND oRow:GetInteger("item_container_id")=iGet) OR (cResource="rastro" AND oRow:GetInteger("rastro_id")=iGet) THEN DO:
    poResponse:Add("data",oRow). RETURN.
   END.
  END.
  cCode="NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Registro nao encontrado no container.",1).
 END.
 poResponse:Add("data",aRows).
 IF lVersion THEN oCalc:Add("calculation_profile","version").
 IF lCapture THEN poResponse:Add("input_snapshot",CAST(oInput:Clone(),JsonObject)).
 CATCH e AS Progress.Lang.Error:
  RUN Fail(cCode,e:GetMessage(1)).
 END CATCH.
 FINALLY:
  RUN CloseQ(INPUT-OUTPUT hq). RUN CloseQ(INPUT-OUTPUT hSub). RUN CloseQ(INPUT-OUTPUT hThird).
 END FINALLY.
END.

PROCEDURE BufferCheck:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 IF NOT VALID-HANDLE(h) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer/banco requerido nao conectado.",1).
 IF h:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("Handle de buffer invalido.",1).
END PROCEDURE.
PROCEDURE CloseQ:
 DEFINE INPUT-OUTPUT PARAMETER h AS HANDLE NO-UNDO.
 IF VALID-HANDLE(h) THEN DO: h:QUERY-CLOSE() NO-ERROR. DELETE OBJECT h NO-ERROR. END.
 h=?.
END PROCEDURE.
PROCEDURE CopyField:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER f AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER dest AS CHARACTER NO-UNDO.
 CASE h:BUFFER-FIELD(f):DATA-TYPE:
  WHEN "CHARACTER" THEN o:Add(dest,C(h,f)).
  WHEN "INTEGER" THEN o:Add(dest,INTEGER(D(h,f))).
  WHEN "DECIMAL" THEN o:Add(dest,D(h,f)).
  WHEN "LOGICAL" THEN o:Add(dest,B(h,f)).
  OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo inesperado no mestre de custo.",1).
 END CASE.
END PROCEDURE.
PROCEDURE CollectActual:
 DEFINE VARIABLE rowCount AS INTEGER NO-UNDO.
 IF NOT poPolicy:Has("naturezas_nota_mae") THEN DO: cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Parametro de natureza NF mae ausente.",1). END.
 IF poPolicy:GetType("naturezas_nota_mae")<>JsonDataType:STRING THEN DO: cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Naturezas NF mae invalidas.",1). END.
 cNaturezas=poPolicy:GetCharacter("naturezas_nota_mae").
 IF cNaturezas="" THEN DO: cCode="COST_POLICY_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Parametro NAT-OPERACAO-IMP vazio.",1). END.
 hq=Q(phNfs,phNfs:NAME + ".container_id=" + STRING(iContainer)).
 DO WHILE NOT hq:QUERY-OFF-END:
  ASSIGN cSerie=C(phNfs,"serie") cDoc=C(phNfs,"documento") cNat=C(phNfs,"nat_operacao") iEmit=INTEGER(D(phNfs,"cod_emitente")).
  IF SUBSTRING(C(phNfs,"estab"),1,1)<>cPrefix THEN UNDO, THROW NEW Progress.Lang.AppError("NF associada pertence a outra empresa ERP.",1).
  FIND ttNote WHERE ttNote.estab=C(phNfs,"estab") AND ttNote.serie=cSerie AND ttNote.documento=cDoc AND ttNote.natureza=cNat AND ttNote.emitente=iEmit NO-ERROR.
  IF AVAILABLE ttNote THEN DO: cCode="COST_AMBIGUOUS_DATA". UNDO, THROW NEW Progress.Lang.AppError("NF associada duplicada.",1). END.
  CREATE ttNote. ASSIGN ttNote.estab=C(phNfs,"estab") ttNote.serie=cSerie ttNote.documento=cDoc ttNote.natureza=cNat ttNote.emitente=iEmit.
  cWhere=hDoc:NAME + ".cod-estabel=" + AblQuote(ttNote.estab) + " AND " + hDoc:NAME + ".serie-docto=" + AblQuote(cSerie) + " AND " + hDoc:NAME + ".nro-docto=" + AblQuote(cDoc) + " AND " + hDoc:NAME + ".nat-operacao=" + AblQuote(cNat) + " AND " + hDoc:NAME + ".cod-emitente=" + STRING(iEmit).
  IF NOT UniqueRow(hDoc,cWhere) THEN UNDO, THROW NEW Progress.Lang.AppError("Documento ERP associado nao encontrado.",1).
  cWhere=hItemDoc:NAME + ".serie-docto=" + AblQuote(cSerie) + " AND " + hItemDoc:NAME + ".nro-docto=" + AblQuote(cDoc) + " AND " + hItemDoc:NAME + ".nat-operacao=" + AblQuote(cNat) + " AND " + hItemDoc:NAME + ".cod-emitente=" + STRING(iEmit).
  ASSIGN hSub=Q(hItemDoc,cWhere) rowCount=0 lMother=Mother(cNat).
  DO WHILE NOT hSub:QUERY-OFF-END:
   ASSIGN cItemCode=C(hItemDoc,"it-codigo") dMerc=D(hItemDoc,"preco-total") dExpense=D(hItemDoc,"despesas") dCofins=0 dPis=0.
   IF NOT CAN-FIND(FIRST ttItem WHERE ttItem.erp=cItemCode) THEN DO:
    cCode="COST_DATA_INCOMPLETE". UNDO, THROW NEW Progress.Lang.AppError("Item da NF nao corresponde a item alocado no container.",1).
   END.
   IF lMother THEN DO:
    dCofins=TaxPart(hItemDoc,"val-cofins","val-aliq-cofins","cod_despesa_cofins").
    dPis=TaxPart(hItemDoc,"valor-pis","val-aliq-pis","cod_despesa_pis").
    dExpense=dExpense - D(hItemDoc,"val-cofins") + dCofins - D(hItemDoc,"valor-pis") + dPis.
   END.
   FIND ttReal WHERE ttReal.erp=cItemCode NO-ERROR.
   IF NOT AVAILABLE ttReal THEN DO: CREATE ttReal. ttReal.erp=cItemCode. END.
   IF lMother THEN ASSIGN ttReal.motherMerc=ttReal.motherMerc + dMerc ttReal.motherExpense=ttReal.motherExpense + dExpense dMotherTotal=dMotherTotal + dMerc.
   ELSE ttReal.otherMerc=ttReal.otherMerc + dMerc.
   oRaw=NEW JsonObject(). oRaw:Add("documento",cDoc). oRaw:Add("serie",cSerie). oRaw:Add("natureza",cNat). oRaw:Add("emitente",iEmit). oRaw:Add("item",cItemCode). oRaw:Add("nota_mae",lMother).
   oRaw:Add("mercadoria",dMerc). oRaw:Add("despesa_original",D(hItemDoc,"despesas")). oRaw:Add("cofins_original",D(hItemDoc,"val-cofins")). oRaw:Add("pis_original",D(hItemDoc,"valor-pis")).
   oRaw:Add("cofins_custo",dCofins). oRaw:Add("pis_custo",dPis). oRaw:Add("despesa_ajustada",dExpense). aRaw:Add(oRaw).
   ASSIGN rowCount=rowCount + 1.
   hSub:GET-NEXT().
  END.
  RUN CloseQ(INPUT-OUTPUT hSub).
  IF rowCount=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Documento ERP sem itens para reconciliar custo.",1).
  hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 IF aRaw:Length>0 AND dMotherTotal=0 THEN DO: cCode="ZERO_DENOMINATOR". UNDO, THROW NEW Progress.Lang.AppError("NF mae sem valor positivo para rateio.",1). END.
 aWarnings:Add("calc_v1: pertinencia exata na lista de naturezas e agregacao por item corrigem strpos/ultimo grupo/percentual100 do PHP; componentes ERP brutos incluidos para reconciliacao.").
END PROCEDURE.
PROCEDURE CollectSales:
 DEFINE VARIABLE sit AS INTEGER NO-UNDO.
 DEFINE VARIABLE currency AS INTEGER NO-UNDO.
 cCode="COST_DATA_INCOMPLETE".
 hq=Q(phPedVendaExt,phPedVendaExt:NAME + ".nr-container=" + STRING(iContainer)).
 DO WHILE NOT hq:QUERY-OFF-END:
  cWhere=hPed:NAME + ".nr-pedido=" + STRING(INTEGER(D(phPedVendaExt,"nr-pedido"))) + " AND " + hPed:NAME + ".cod-estabel=" + AblQuote(C(phPedVendaExt,"cod-estabel")).
  IF NOT UniqueRow(hPed,cWhere) THEN UNDO, THROW NEW Progress.Lang.AppError("Pedido de venda associado nao encontrado.",1).
  ASSIGN sit=INTEGER(D(hPed,"cod-sit-ped")) currency=INTEGER(D(hPed,"mo-codigo")).
  IF sit<>6 THEN DO:
   IF currency<>0 AND currency<>3 THEN UNDO, THROW NEW Progress.Lang.AppError("Moeda de venda nao suportada pelo resumo legado.",1).
   hSub=Q(hPedItem,hPedItem:NAME + ".nome-abrev=" + AblQuote(C(hPed,"nome-abrev")) + " AND " + hPedItem:NAME + ".nr-pedcli=" + AblQuote(C(hPed,"nr-pedcli"))).
   DO WHILE NOT hSub:QUERY-OFF-END:
    ASSIGN dValue=D(hPedItem,"qt-pedida") * D(hPedItem,"vl-preuni") dDiscount=dValue * ((20 - INTEGER(D(hPed,"cod-priori"))) MODULO 10) / 10.
    FIND ttSale WHERE ttSale.situacao=sit AND ttSale.moeda=currency NO-ERROR.
    IF NOT AVAILABLE ttSale THEN DO: CREATE ttSale. ASSIGN ttSale.situacao=sit ttSale.moeda=currency. END.
    ASSIGN ttSale.valor=ttSale.valor + dValue ttSale.desconto=ttSale.desconto + dDiscount.
    hSub:GET-NEXT().
   END.
   RUN CloseQ(INPUT-OUTPUT hSub).
  END.
  hq:GET-NEXT().
 END.
 RUN CloseQ(INPUT-OUTPUT hq).
 dSaleRate=D(phContainer,"vl-dolar-venda"). IF dSaleRate=0 THEN dSaleRate=dQuote.
 IF dSaleRate<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Cotacao de venda indisponivel.",1).
 FOR EACH ttSale:
  dValue=(ttSale.valor + ttSale.desconto) * (IF ttSale.moeda=3 THEN dSaleRate ELSE 1).
  IF LOOKUP(STRING(ttSale.situacao),"1,2,4,7")>0 THEN dSalesPrev=dSalesPrev + dValue.
  IF ttSale.situacao=3 THEN dSalesReal=dSalesReal + dValue.
 END.
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). err=NEW JsonObject().
 err:Add("code",code). err:Add("message",msg). err:Add("status",IF code="NOT_FOUND" THEN 404 ELSE IF code="COST_CONFIGURATION" THEN 503 ELSE 422).
 poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.



