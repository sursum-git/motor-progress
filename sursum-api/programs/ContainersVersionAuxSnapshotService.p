/* Private version-specific physical snapshot collector. No business writes. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscountLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDocMed AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDocIma AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSituacoes AS HANDLE NO-UNDO.
DEFINE TEMP-TABLE expenseRows NO-UNDO
 FIELD expenseId AS INTEGER FIELD calculationId AS INTEGER FIELD costFlag AS INTEGER
 FIELD previousValue AS DECIMAL FIELD negotiatedValue AS DECIMAL FIELD proformaValue AS DECIMAL FIELD baseValue AS DECIMAL
 INDEX pk IS PRIMARY UNIQUE expenseId.
DEFINE TEMP-TABLE discountRows NO-UNDO
 FIELD discountId AS INTEGER FIELD realValue AS DECIMAL FIELD dollarValue AS DECIMAL
 INDEX pk IS PRIMARY UNIQUE discountId.
FUNCTION NumberText RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,">>>>>>>>>9")). END FUNCTION.
FUNCTION CloneObject RETURNS JsonObject(v AS JsonObject):
 DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
 v:Write(textValue). parser=NEW ObjectModelParser(). resultValue=CAST(parser:Parse(textValue),JsonObject). DELETE OBJECT parser. RETURN resultValue.
END FUNCTION.
FUNCTION OpenRows RETURNS HANDLE(b AS HANDLE, predicate AS CHARACTER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(b).
 q:QUERY-PREPARE("FOR EACH " + b:NAME + " WHERE " + predicate + " SHARE-LOCK"). q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT). RETURN q.
END FUNCTION.
FUNCTION OpenErpRows RETURNS HANDLE(b AS HANDLE,predicate AS CHARACTER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(b). q:QUERY-PREPARE("FOR EACH " + b:NAME + " NO-LOCK WHERE " + predicate). q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK). RETURN q.
END FUNCTION.
FUNCTION FieldNumber RETURNS DECIMAL(b AS HANDLE,f AS CHARACTER): RETURN b:BUFFER-FIELD(f):BUFFER-VALUE. END FUNCTION.
PROCEDURE CheckMaster:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 IF NOT TRANSACTION OR NOT VALID-HANDLE(master) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SNAPSHOT_TRANSACTION_REQUIRED",1).
 IF NOT master:AVAILABLE OR FieldNumber(master,"nr-container")<=0 OR FieldNumber(master,"nr-container")=? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SNAPSHOT_CONTEXT",1).
 IF NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTAINER_BUSY",1).
END PROCEDURE.
PROCEDURE CollectPhysical:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER financial AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER physical AS JsonObject NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE companyValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE expenseValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE calcValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE logValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE discountValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE amountValue AS DECIMAL NO-UNDO.
 DEFINE VARIABLE ratioValue AS DECIMAL NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE innerQ AS HANDLE NO-UNDO.
 DEFINE VARIABLE objectValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE headerValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE expenseValues AS JsonArray NO-UNDO.
 DEFINE VARIABLE discountValues AS JsonArray NO-UNDO.
 DEFINE VARIABLE nfValues AS JsonArray NO-UNDO.
 DEFINE VARIABLE paymentValues AS JsonArray NO-UNDO.
 DEFINE VARIABLE fieldsValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE docHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE predicate AS CHARACTER NO-UNDO.
 DEFINE VARIABLE foundDoc AS LOGICAL NO-UNDO.
 DEFINE VARIABLE warningsValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE prefixValue AS CHARACTER NO-UNDO.
 RUN CheckMaster(master). cid=FieldNumber(master,"nr-container").
 IF NOT VALID-OBJECT(financial) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FINANCIAL_UNCONFIRMED",1).
 IF NOT financial:GetLogical("confirmed") OR financial:GetInteger("container_id")<>cid OR financial:GetCharacter("source")<>"linked-payment-totals" OR NOT financial:Has("payment_rows") THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FINANCIAL_UNCONFIRMED",1).
 EMPTY TEMP-TABLE expenseRows. EMPTY TEMP-TABLE discountRows.
 ASSIGN expenseValues=NEW JsonArray() discountValues=NEW JsonArray() nfValues=NEW JsonArray() warningsValue=NEW JsonArray().
 prefixValue=SUBSTRING(STRING(master:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE),1,1).
 IF prefixValue=? OR LOOKUP(prefixValue,"1,2,3,4,5,6,7,8,9")=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_COMPANY_INVALID",1).
 q=OpenRows(phEmpresas,phEmpresas:NAME + ".cod_emp_ems2=" + prefixValue).
 IF q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_COMPANY_NOT_FOUND",1).
 companyValue=FieldNumber(phEmpresas,"empresa_id"). q:GET-NEXT(SHARE-LOCK,NO-WAIT).
 IF NOT q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_COMPANY_AMBIGUOUS",1).
 DELETE OBJECT q.
 q=OpenRows(phExpenses,phExpenses:NAME + ".container_id=" + NumberText(cid)).
 DO WHILE NOT q:QUERY-OFF-END:
  expenseValue=FieldNumber(phExpenses,"despesa_id"). calcValue=FieldNumber(phExpenses,"calc_imp_container_id").
  innerQ=OpenRows(phLinks,phLinks:NAME + ".empresa_id=" + NumberText(companyValue) + " AND " + phLinks:NAME + ".despesa_id=" + NumberText(expenseValue)).
  IF innerQ:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_EXPENSE_COMPANY_NOT_FOUND",1).
  logValue=FieldNumber(phLinks,"log_custo"). innerQ:GET-NEXT(SHARE-LOCK,NO-WAIT).
  IF NOT innerQ:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_EXPENSE_COMPANY_AMBIGUOUS",1).
  DELETE OBJECT innerQ.
  FIND expenseRows WHERE expenseId=expenseValue NO-ERROR.
  IF NOT AVAILABLE expenseRows THEN DO: CREATE expenseRows. ASSIGN expenseId=expenseValue calculationId=calcValue costFlag=logValue. END.
  ELSE IF calculationId<>calcValue OR costFlag<>logValue OR calculationId=? OR calcValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_EXPENSE_AMBIGUOUS",1).
  ASSIGN previousValue=previousValue + FieldNumber(phExpenses,"vl_prev") negotiatedValue=negotiatedValue + FieldNumber(phExpenses,"vl_negociado") proformaValue=proformaValue + FieldNumber(phExpenses,"vl_proforma") baseValue=baseValue + FieldNumber(phExpenses,"vl_base_imp").
  q:GET-NEXT(SHARE-LOCK,NO-WAIT).
 END. DELETE OBJECT q.
 FOR EACH expenseRows BY expenseId:
  objectValue=NEW JsonObject(). objectValue:Add("despesa_id",expenseId). objectValue:Add("log_custo",costFlag). objectValue:Add("calc_imp_container_id",calculationId).
  objectValue:Add("vl_prev",previousValue). objectValue:Add("vl_negociado",negotiatedValue). objectValue:Add("vl_proforma",proformaValue). objectValue:Add("vl_base_imp",baseValue). expenseValues:Add(objectValue).
 END.
 q=OpenRows(phItems,phItems:NAME + ".container_id=" + NumberText(cid)).
 DO WHILE NOT q:QUERY-OFF-END:
  innerQ=OpenRows(phDiscounts,phDiscounts:NAME + ".item_container_id=" + NumberText(INTEGER(FieldNumber(phItems,"item_container_id"))) + " AND " + phDiscounts:NAME + ".log_credito=FALSE").
  DO WHILE NOT innerQ:QUERY-OFF-END:
   CREATE discountRows. ASSIGN discountId=FieldNumber(phDiscounts,"desconto_importacao_id") realValue=FieldNumber(phDiscounts,"vl_real_autorizado") dollarValue=FieldNumber(phDiscounts,"vl_dolar_autorizado"). innerQ:GET-NEXT(SHARE-LOCK,NO-WAIT).
  END. DELETE OBJECT innerQ. q:GET-NEXT(SHARE-LOCK,NO-WAIT).
 END. DELETE OBJECT q.
 q=OpenRows(phDiscountLedger,phDiscountLedger:NAME + ".container_id=" + NumberText(cid)).
 DO WHILE NOT q:QUERY-OFF-END:
  discountValue=FieldNumber(phDiscountLedger,"desconto_importacao_id").
  innerQ=OpenRows(phDiscounts,phDiscounts:NAME + ".desconto_importacao_id=" + NumberText(discountValue) + " AND " + phDiscounts:NAME + ".log_credito=TRUE").
  IF innerQ:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CREDIT_NOT_FOUND",1).
  IF FieldNumber(phDiscounts,"vl_real_autorizado")=? OR FieldNumber(phDiscounts,"vl_dolar_autorizado")=? OR FieldNumber(phDiscounts,"vl_dolar_autorizado")=0 OR FieldNumber(phDiscountLedger,"valor_utilizado")=? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CREDIT_AUTHORIZED_RATIO_INVALID",1).
  ratioValue=FieldNumber(phDiscounts,"vl_real_autorizado") / FieldNumber(phDiscounts,"vl_dolar_autorizado").
  amountValue=FieldNumber(phDiscountLedger,"valor_utilizado"). innerQ:GET-NEXT(SHARE-LOCK,NO-WAIT).
  IF NOT innerQ:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CREDIT_AMBIGUOUS",1).
  DELETE OBJECT innerQ.
  FIND discountRows WHERE discountId=discountValue NO-ERROR.
  IF NOT AVAILABLE discountRows THEN DO: CREATE discountRows. discountId=discountValue. END.
  ASSIGN realValue=realValue + ratioValue * amountValue dollarValue=dollarValue + amountValue.
  q:GET-NEXT(SHARE-LOCK,NO-WAIT).
 END. DELETE OBJECT q.
 FOR EACH discountRows BY discountId:
  objectValue=NEW JsonObject(). objectValue:Add("desconto_importacao_id",discountId). objectValue:Add("log_custo",0). objectValue:Add("vl_autoriz_real",realValue). objectValue:Add("vl_autoriz_dolar",dollarValue). discountValues:Add(objectValue).
 END.
 q=OpenRows(phNfs,phNfs:NAME + ".container_id=" + NumberText(cid)).
 DO WHILE NOT q:QUERY-OFF-END:
  objectValue=NEW JsonObject(). fieldsValue="documento,serie,estab,nat_operacao".
  DO n=1 TO NUM-ENTRIES(fieldsValue): objectValue:Add(ENTRY(n,fieldsValue),STRING(phNfs:BUFFER-FIELD(ENTRY(n,fieldsValue)):BUFFER-VALUE)). END.
  objectValue:Add("cod_emitente",INTEGER(FieldNumber(phNfs,"cod_emitente"))).
  docHandle=IF objectValue:GetCharacter("estab")="1" THEN phDocIma ELSE phDocMed.
  predicate=docHandle:NAME + ".cod-estabel=" + QUOTER(objectValue:GetCharacter("estab")) + " AND " + docHandle:NAME + ".nro-docto=" + QUOTER(objectValue:GetCharacter("documento")) + " AND " + docHandle:NAME + ".serie-docto=" + QUOTER(objectValue:GetCharacter("serie")) + " AND " + docHandle:NAME + ".nat-operacao=" + QUOTER(objectValue:GetCharacter("nat_operacao")) + " AND " + docHandle:NAME + ".cod-emitente=" + NumberText(objectValue:GetInteger("cod_emitente")).
  innerQ=OpenErpRows(docHandle,predicate). foundDoc=NOT innerQ:QUERY-OFF-END.
  IF foundDoc THEN DO: objectValue:Add("vl_mercadoria",FieldNumber(docHandle,"valor-mercad")). objectValue:Add("vl_despesa",FieldNumber(docHandle,"despesa-nota")). innerQ:GET-NEXT(NO-LOCK). IF NOT innerQ:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_NF_AMBIGUOUS",1). END.
  ELSE DO: objectValue:AddNull("vl_mercadoria"). objectValue:AddNull("vl_despesa"). warningsValue:Add("VERSION_NF_ERP_NOT_FOUND: " + objectValue:GetCharacter("estab") + "/" + objectValue:GetCharacter("documento")). END.
  DELETE OBJECT innerQ. nfValues:Add(objectValue). q:GET-NEXT(SHARE-LOCK,NO-WAIT).
 END. DELETE OBJECT q.
 headerValue=NEW JsonObject(). fieldsValue="vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,situacao_container_id".
 DO n=1 TO NUM-ENTRIES(fieldsValue):
  IF master:BUFFER-FIELD(ENTRY(n,fieldsValue)):DATA-TYPE="LOGICAL" THEN headerValue:Add(ENTRY(n,fieldsValue),LOGICAL(master:BUFFER-FIELD(ENTRY(n,fieldsValue)):BUFFER-VALUE)).
  ELSE headerValue:Add(ENTRY(n,fieldsValue),FieldNumber(master,ENTRY(n,fieldsValue))).
 END.
 headerValue:Add("perc_fixo_container",FieldNumber(master,"perc_custo")).
 q=OpenRows(phSituacoes,phSituacoes:NAME + ".situacao_container_id=" + NumberText(INTEGER(FieldNumber(master,"situacao_container_id")))).
 IF q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_STATUS_NOT_FOUND",1).
 headerValue:Add("desc_sit_container",STRING(phSituacoes:BUFFER-FIELD("descricao"):BUFFER-VALUE) + (IF LOGICAL(phSituacoes:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE) THEN "(Marcado para Distribuir Custo)" ELSE "(Marcado para Não Distribuir Custo)")). q:GET-NEXT(SHARE-LOCK,NO-WAIT).
 IF NOT q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_STATUS_AMBIGUOUS",1).
 DELETE OBJECT q.
 physical=NEW JsonObject(). physical:Add("container_id",cid). physical:Add("header",headerValue). physical:Add("expenses",expenseValues). physical:Add("discounts",discountValues). physical:Add("nfs",nfValues). physical:Add("warnings",warningsValue).
 objectValue=CloneObject(financial). physical:Add("payments",objectValue:GetJsonArray("payment_rows")).
 FINALLY:
  IF VALID-HANDLE(innerQ) THEN DELETE OBJECT innerQ.
  IF VALID-HANDLE(q) THEN DELETE OBJECT q.
 END FINALLY.
END PROCEDURE.
PROCEDURE FinalizeSnapshot:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER physical AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER cost AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER snapshot AS JsonObject NO-UNDO.
 DEFINE VARIABLE headerValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE inputValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE attempts AS JsonArray NO-UNDO.
 DEFINE VARIABLE memoryText AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE costClone AS JsonObject NO-UNDO.
 DEFINE VARIABLE physicalClone AS JsonObject NO-UNDO.
 RUN CheckMaster(master). cid=FieldNumber(master,"nr-container").
 IF NOT VALID-OBJECT(physical) OR NOT VALID-OBJECT(cost) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SNAPSHOT_UNCONFIRMED",1).
 IF physical:GetInteger("container_id")<>cid OR cost:GetInteger("container_id")<>cid OR NOT cost:GetLogical("confirmed") OR cost:GetCharacter("source")<>"container-version-cost-snapshot" THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SNAPSHOT_CONTEXT",1).
 physicalClone=CloneObject(physical). snapshot=NEW JsonObject(). snapshot:Add("container_id",cid).
 DO n=1 TO 5:
  IF n=1 THEN snapshot:Add("header",physicalClone:GetJsonObject("header")).
  ELSE snapshot:Add(ENTRY(n,"header,expenses,nfs,payments,discounts"),physicalClone:GetJsonArray(ENTRY(n,"header,expenses,nfs,payments,discounts"))).
 END.
 headerValue=snapshot:GetJsonObject("header"). inputValue=cost:GetJsonObject("input_snapshot").
 attempts=cost:GetJsonObject("master_average"):GetJsonObject("memory"):GetJsonArray("compra_attempts").
 IF attempts:Length=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_PURCHASE_RATE_MISSING",1).
 headerValue:Add("vl_dolar_compra",attempts:GetJsonObject(attempts:Length):GetDecimal("value")).
 headerValue:Add("vl_desconto_utiliz_real",inputValue:GetJsonObject("discounts"):GetDecimal("credito_real")).
 headerValue:Add("vl_desconto_utiliz_dolar",inputValue:GetJsonObject("discounts"):GetDecimal("credito_dolar")).
 headerValue:AddNull("cod_tipo_cotacao"). headerValue:Add("vl_cotacao",inputValue:GetJsonObject("quotation"):GetDecimal("valor")).
 headerValue:Add("data_ref_cotacao",inputValue:GetJsonObject("quotation"):GetCharacter("data")).
 attempts:Write(memoryText). headerValue:Add("hist_dolar",memoryText).
 costClone=CloneObject(cost).
 DO n=1 TO physicalClone:GetJsonArray("warnings"):Length: costClone:GetJsonObject("calculation"):GetJsonArray("warnings"):Add(physicalClone:GetJsonArray("warnings"):GetCharacter(n)). END.
 snapshot:Add("confirmed",TRUE). snapshot:Add("actual_complete",cost:GetLogical("actual_complete")). snapshot:Add("cost",costClone).
END PROCEDURE.


