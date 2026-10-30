/* Generic item allocation root. Fiscal/financial rules are trusted callbacks. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemCosts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCommercial AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE operationValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "CONTAINER_ITEM_VALIDATION".
DEFINE VARIABLE failureStatus AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE writableFields AS CHARACTER NO-UNDO INITIAL "qt_alocada,qt_confirm_emb,qt_recbto_fisico,log_rec_doc_prazo_emb,observacao,cod_tipo_calculo,perc_custo,log_calc_icms,log_calc_ipi,perc_icms,perc_ipi".
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseItemId AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseId AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE quantityBefore AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE quantityAfter AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE allocatedTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE boughtQuantity AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE currentQuantity AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE nestedValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE staleValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
DEFINE VARIABLE hAllocations AS HANDLE NO-UNDO.
DEFINE VARIABLE qAllocations AS HANDLE NO-UNDO.
DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE masterBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE masterAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesValue AS JsonObject NO-UNDO.
DEFINE VARIABLE normalizedValues AS JsonObject NO-UNDO.
DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE capsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE ctxValue AS JsonObject NO-UNDO.
DEFINE VARIABLE effectsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
DEFINE VARIABLE auditValue AS JsonObject NO-UNDO.
DEFINE VARIABLE masterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE changesValue AS JsonArray NO-UNDO.
DEFINE VARIABLE childChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE warningsValue AS JsonArray NO-UNDO.

{sursum-api/includes/ContainerBufferSibling.i}
{sursum-api/includes/ContainerTransactionAudit.i}
{sursum-api/includes/ContainerMaintenanceEffects.i}

FUNCTION Exact RETURNS LOGICAL (nameValue AS CHARACTER,listValue AS CHARACTER):
 DEFINE VARIABLE nameText AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 nameText=nameValue. DO j=1 TO NUM-ENTRIES(listValue): IF nameText=ENTRY(j,listValue) THEN RETURN TRUE. END. RETURN FALSE.
END FUNCTION.
FUNCTION Id RETURNS INTEGER (objectValue AS JsonObject,nameValue AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE amount AS DECIMAL NO-UNDO.
 IF NOT objectValue:Has(nameValue) THEN RETURN ?.
 CASE objectValue:GetType(nameValue):
  WHEN JsonDataType:STRING THEN rawValue=objectValue:GetCharacter(nameValue).
  WHEN JsonDataType:NUMBER THEN rawValue=STRING(objectValue:GetJsonText(nameValue)).
  OTHERWISE RETURN ?.
 END CASE.
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN RETURN ?.
 DO j=1 TO LENGTH(rawValue): IF INDEX("0123456789",SUBSTRING(rawValue,j,1))=0 THEN RETURN ?. END.
 amount=DECIMAL(rawValue). IF amount<1 OR amount>2147483647 THEN RETURN ?. RETURN INTEGER(amount).
END FUNCTION.
FUNCTION NumberId RETURNS INTEGER (objectValue AS JsonObject,nameValue AS CHARACTER):
 DEFINE VARIABLE amount AS DECIMAL NO-UNDO.
 IF NOT objectValue:Has(nameValue) THEN RETURN ?.
 IF objectValue:GetType(nameValue)<>JsonDataType:NUMBER THEN RETURN ?.
 amount=objectValue:GetDecimal(nameValue).
 IF amount=? OR amount<1 OR amount>2147483647 OR TRUNCATE(amount,0)<>amount THEN RETURN ?. RETURN INTEGER(amount).
END FUNCTION.
FUNCTION EmptyObject RETURNS LOGICAL (objectValue AS JsonObject):
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. names=objectValue:GetNames().
 IF EXTENT(names)=? THEN RETURN TRUE. RETURN EXTENT(names)=0.
END FUNCTION.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER objectValue AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(objectValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto JSON obrigatorio.",1).
 names=objectValue:GetNames().
 DO j=1 TO EXTENT(names): IF NOT Exact(names[j],allowed) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao permitido: " + names[j],1). END.
END PROCEDURE.
FUNCTION Snapshot RETURNS JsonObject (bufferValue AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cv AS CHARACTER NO-UNDO. DEFINE VARIABLE iv AS INTEGER NO-UNDO. DEFINE VARIABLE iv64 AS INT64 NO-UNDO.
 DEFINE VARIABLE dv AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE lv AS LOGICAL NO-UNDO.
 DEFINE VARIABLE da AS DATE NO-UNDO. DEFINE VARIABLE dt AS DATETIME NO-UNDO. DEFINE VARIABLE dz AS DATETIME-TZ NO-UNDO.
 o=NEW JsonObject().
 DO j=1 TO bufferValue:NUM-FIELDS:
  f=bufferValue:BUFFER-FIELD(j). nameValue=IF f:NAME="nr-container" THEN "container_id" ELSE REPLACE(f:NAME,"-","_").
  IF f:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot escalar obrigatorio.",1).
  IF f:BUFFER-VALUE=? THEN o:AddNull(nameValue).
  ELSE CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: cv=f:BUFFER-VALUE. o:Add(nameValue,cv). END.
   WHEN "INTEGER" THEN DO: iv=f:BUFFER-VALUE. o:Add(nameValue,iv). END.
   WHEN "INT64" THEN DO: iv64=f:BUFFER-VALUE. o:Add(nameValue,iv64). END.
   WHEN "DECIMAL" THEN DO: dv=f:BUFFER-VALUE. o:Add(nameValue,dv). END.
   WHEN "LOGICAL" THEN DO: lv=f:BUFFER-VALUE. o:Add(nameValue,lv). END.
   WHEN "DATE" THEN DO: da=f:BUFFER-VALUE. o:Add(nameValue,da). END.
   WHEN "DATETIME" THEN DO: dt=f:BUFFER-VALUE. o:Add(nameValue,dt). END.
   WHEN "DATETIME-TZ" THEN DO: dz=f:BUFFER-VALUE. o:Add(nameValue,dz). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo fisico de snapshot nao suportado.",1).
  END CASE.
 END. RETURN o.
END FUNCTION.
FUNCTION Found RETURNS LOGICAL (bufferValue AS HANDLE,conditionValue AS CHARACTER,lockValue AS INTEGER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 foundValue=bufferValue:FIND-FIRST("WHERE " + conditionValue,lockValue,NO-WAIT) NO-ERROR.
 IF bufferValue:LOCKED THEN DO: failureCode="CONTAINER_ITEM_BUSY". failureStatus=409. UNDO, THROW NEW Progress.Lang.AppError("Registro em uso.",1). END.
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Falha de leitura nao equivale a ausencia.",1). END.
 RETURN foundValue.
END FUNCTION.
FUNCTION ExistsRow RETURNS LOGICAL (bufferValue AS HANDLE,conditionValue AS CHARACTER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY q. q:SET-BUFFERS(bufferValue).
  IF NOT q:QUERY-PREPARE("FOR EACH " + bufferValue:NAME + " WHERE " + conditionValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa invalida.",1).
  q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  IF bufferValue:LOCKED OR ERROR-STATUS:ERROR THEN DO: failureCode="CONTAINER_ITEM_BUSY". failureStatus=409. UNDO, THROW NEW Progress.Lang.AppError("Referencia em uso.",1). END.
  RETURN NOT q:QUERY-OFF-END.
  FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
 END.
END FUNCTION.

DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,"operation,container_id,id,item_container_id,values").
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao obrigatoria.",1).
 operationValue=poRequest:GetCharacter("operation"). cid=Id(poRequest,"container_id").
 IF NOT Exact(operationValue,"create,update,delete,get") OR cid=? THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao/container invalido.",1).
 IF operationValue="create" THEN DO:
  IF poRequest:Has("id") OR poRequest:Has("item_container_id") THEN UNDO, THROW NEW Progress.Lang.AppError("PK gerada pelo servidor.",1).
 END.
 ELSE DO:
  itemId=Id(poRequest,"id"). IF itemId=? THEN itemId=Id(poRequest,"item_container_id").
  IF itemId=? OR (poRequest:Has("id") AND Id(poRequest,"id")<>itemId) OR (poRequest:Has("item_container_id") AND Id(poRequest,"item_container_id")<>itemId) THEN UNDO, THROW NEW Progress.Lang.AppError("ID/alias invalido ou divergente.",1).
 END.
 IF Exact(operationValue,"create,update") THEN DO:
  IF poRequest:GetType("values")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("values obrigatorio.",1).
  valuesValue=poRequest:GetJsonObject("values"). RUN ValidateValues.
 END.
 ELSE IF poRequest:Has("values") THEN UNDO, THROW NEW Progress.Lang.AppError("values nao permitido nesta operacao.",1).
 failureCode="CONTAINER_ITEM_CONFIGURATION". failureStatus=503.
 IF NOT VALID-HANDLE(phMaster) OR NOT VALID-HANDLE(phItems) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffers fixos indisponiveis.",1).
 IF operationValue="get" THEN DO:
  failureCode="CONTAINER_NOT_FOUND". failureStatus=404.
  IF NOT Found(phMaster,phMaster:NAME + ".nr-container=" + STRING(cid),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1).
  failureCode="CONTAINER_ITEM_NOT_FOUND".
  IF NOT Found(phItems,phItems:NAME + ".item_container_id=" + STRING(itemId) + " AND " + phItems:NAME + ".container_id=" + STRING(cid),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Item nao encontrado neste container.",1).
  poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",Snapshot(phItems)). RETURN.
 END.
 nestedValue=TRANSACTION.
 failureCode="CONTAINER_ITEM_IDENTITY_REQUIRED". failureStatus=401.
 IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Autoria privada obrigatoria.",1).
 IF poPolicy:GetType("actor")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Autoria privada obrigatoria.",1).
 IF poPolicy:GetJsonObject("actor"):GetType("login")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado obrigatorio.",1).
 IF TRIM(poPolicy:GetJsonObject("actor"):GetCharacter("login"))="" OR LENGTH(poPolicy:GetJsonObject("actor"):GetCharacter("login"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado invalido.",1).
 actorValue=NEW JsonObject(). actorValue:Add("login",poPolicy:GetJsonObject("actor"):GetCharacter("login")).
 failureCode="CONTAINER_ITEM_TRANSACTION_CONTEXT". failureStatus=409.
 IF poPolicy:Has("allow_nested") THEN IF poPolicy:GetType("allow_nested")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao privada exige booleano.",1).
 IF nestedValue THEN DO:
  IF NOT poPolicy:Has("allow_nested") THEN UNDO, THROW NEW Progress.Lang.AppError("Item requer transacao raiz propria.",1).
  IF poPolicy:GetLogical("allow_nested")<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("Item requer transacao raiz propria.",1).
 END.
 failureCode="CONTAINER_ITEM_CONFIGURATION". failureStatus=503.
 IF NOT VALID-HANDLE(phPurchaseItems) OR NOT VALID-HANDLE(phPurchases) OR NOT VALID-HANDLE(phDiscounts) OR NOT VALID-HANDLE(phItemCosts) OR NOT VALID-HANDLE(phCommercial) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffers fixos indisponiveis.",1).
 failureCode="CONTAINER_ITEM_RULE_UNAVAILABLE".
 IF NOT VALID-HANDLE(phRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("Provider privado obrigatorio.",1).
 IF phRuntime:TYPE<>"PROCEDURE" THEN UNDO, THROW NEW Progress.Lang.AppError("Provider privado invalido.",1).
 DO n=1 TO 3: IF LOOKUP(ENTRY(n,"GetCapabilities,AfterChange,NextItemId"),phRuntime:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Callback obrigatorio indisponivel.",1). END.
 RUN GetCapabilities IN phRuntime(OUTPUT capsValue).
 IF NOT VALID-OBJECT(capsValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Capacidades nao confirmadas.",1).
 IF capsValue:GetType("contract")<>JsonDataType:STRING OR NOT Exact(capsValue:GetCharacter("contract"),"container-item-rules-v1") THEN UNDO, THROW NEW Progress.Lang.AppError("Contrato do provider invalido.",1).
 IF capsValue:GetType("afterChange")<>JsonDataType:BOOLEAN OR capsValue:GetType("nextItemId")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Capacidades devem ser booleanas.",1).
 IF capsValue:GetLogical("afterChange")<>TRUE OR capsValue:GetLogical("nextItemId")<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("Provider nao confirmou escrita.",1).
 RUN ContainerCreateSiblingBuffer(phItems,"bItemAllocationSum",OUTPUT hAllocations).
 DO TRANSACTION ON ERROR UNDO, THROW:
  failureCode="CONTAINER_NOT_FOUND". failureStatus=404.
  IF NOT Found(phMaster,phMaster:NAME + ".nr-container=" + STRING(cid),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1).
  masterBefore=Snapshot(phMaster).
  beforeValue=NEW JsonObject().
  IF operationValue="create" THEN purchaseItemId=NumberId(valuesValue,"item_proc_compra_id").
  ELSE DO:
   failureCode="CONTAINER_ITEM_NOT_FOUND".
   IF NOT Found(phItems,phItems:NAME + ".item_container_id=" + STRING(itemId) + " AND " + phItems:NAME + ".container_id=" + STRING(cid),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Item nao encontrado neste container.",1).
   beforeValue=Snapshot(phItems). purchaseItemId=NumberId(beforeValue,"item_proc_compra_id"). quantityBefore=beforeValue:GetDecimal("qt_alocada").
   IF operationValue="update" THEN IF valuesValue:Has("item_proc_compra_id") THEN DO:
    failureCode="CONTAINER_ITEM_VALIDATION". failureStatus=422.
    IF NumberId(valuesValue,"item_proc_compra_id")<>purchaseItemId THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra imutavel apos alocacao.",1).
   END.
  END.
  failureCode="CONTAINER_ITEM_REFERENCE_INVALID". failureStatus=422.
  IF purchaseItemId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Referencia de compra invalida.",1).
  IF NOT Found(phPurchaseItems,phPurchaseItems:NAME + ".item_proc_compra_id=" + STRING(purchaseItemId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra nao encontrado.",1).
  purchaseId=phPurchaseItems:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE.
  IF purchaseId=? OR purchaseId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Processo de compra invalido.",1).
  IF NOT Found(phPurchases,phPurchases:NAME + ".proc_compra_id=" + STRING(purchaseId),SHARE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Processo de compra nao encontrado.",1).
  IF phPurchaseItems:BUFFER-FIELD("codigo_erp"):BUFFER-VALUE=? OR TRIM(STRING(phPurchaseItems:BUFFER-FIELD("codigo_erp"):BUFFER-VALUE))="" THEN UNDO, THROW NEW Progress.Lang.AppError("Codigo ERP obrigatorio.",1).
  IF operationValue="create" THEN DO:
   failureCode="CONTAINER_ITEM_EXISTS". failureStatus=409.
   IF ExistsRow(hAllocations,hAllocations:NAME + ".container_id=" + STRING(cid) + " AND " + hAllocations:NAME + ".item_proc_compra_id=" + STRING(purchaseItemId)) THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra ja alocado neste container.",1).
   quantityAfter=normalizedValues:GetDecimal("qt_alocada").
  END.
  ELSE IF operationValue="update" THEN quantityAfter=IF normalizedValues:Has("qt_alocada") THEN normalizedValues:GetDecimal("qt_alocada") ELSE quantityBefore.
  IF operationValue="create" OR (operationValue="update" AND quantityAfter>quantityBefore) THEN RUN CheckAllocation.
  IF operationValue="delete" THEN DO:
   failureCode="CONTAINER_ITEM_DEPENDENCY". failureStatus=409.
   IF ExistsRow(phDiscounts,phDiscounts:NAME + ".item_container_id=" + STRING(itemId)) THEN UNDO, THROW NEW Progress.Lang.AppError("Descontos vinculados impedem exclusao.",1).
   IF ExistsRow(phItemCosts,phItemCosts:NAME + ".item_container_id=" + STRING(itemId)) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots de custo vinculados impedem exclusao.",1).
   IF ExistsRow(phCommercial,phCommercial:NAME + ".nr-container=" + STRING(cid) + " AND " + phCommercial:NAME + ".item_proc_compra_id=" + STRING(purchaseItemId)) THEN UNDO, THROW NEW Progress.Lang.AppError("Vinculo comercial impede exclusao.",1).
  END.
  IF operationValue="create" THEN DO:
   failureCode="CONTAINER_ITEM_SEQUENCE_INVALID". failureStatus=503.
   RUN NextItemId IN phRuntime(OUTPUT itemId).
   IF itemId=? OR itemId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia fixa de item invalida.",1).
   IF Found(phItems,phItems:NAME + ".item_container_id=" + STRING(itemId),SHARE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("ID de sequencia ja utilizado.",1).
   failureCode="CONTAINER_ITEM_PERSISTENCE". failureStatus=409.
   IF NOT phItems:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Criacao de item recusada.",1).
   ASSIGN phItems:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=itemId phItems:BUFFER-FIELD("container_id"):BUFFER-VALUE=cid phItems:BUFFER-FIELD("item_proc_compra_id"):BUFFER-VALUE=purchaseItemId.
  END.
  failureCode="CONTAINER_ITEM_PERSISTENCE". failureStatus=409.
  IF operationValue="delete" THEN DO:
   IF NOT phItems:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao de item recusada.",1).
   afterValue=NEW JsonObject().
  END.
  ELSE DO:
   namesValue=normalizedValues:GetNames().
   DO n=1 TO EXTENT(namesValue):
    fieldName=namesValue[n].
    IF fieldName="item_proc_compra_id" THEN NEXT.
    CASE normalizedValues:GetType(fieldName):
     WHEN JsonDataType:STRING THEN phItems:BUFFER-FIELD(fieldName):BUFFER-VALUE=normalizedValues:GetCharacter(fieldName).
     WHEN JsonDataType:BOOLEAN THEN phItems:BUFFER-FIELD(fieldName):BUFFER-VALUE=normalizedValues:GetLogical(fieldName).
     WHEN JsonDataType:NUMBER THEN phItems:BUFFER-FIELD(fieldName):BUFFER-VALUE=normalizedValues:GetDecimal(fieldName).
    END CASE.
   END.
   IF NOT phItems:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Item recusado pelo banco.",1).
   afterValue=Snapshot(phItems).
  END.
  ctxValue=NEW JsonObject(). ctxValue:Add("operation",operationValue). ctxValue:Add("container_id",cid). ctxValue:Add("before",CAST(beforeValue:Clone(),JsonObject)). ctxValue:Add("after",CAST(afterValue:Clone(),JsonObject)).
  failureCode="CONTAINER_ITEM_RULE_FAILED". failureStatus=422.
  RUN AfterChange IN phRuntime(phMaster,ctxValue,OUTPUT effectsValue).
  RUN ValidateEffects.
  IF operationValue<>"delete" THEN DO:
   IF NOT Found(phItems,phItems:NAME + ".item_container_id=" + STRING(itemId) + " AND " + phItems:NAME + ".container_id=" + STRING(cid),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Provider removeu o item principal.",1).
   afterValue=Snapshot(phItems).
   IF NumberId(afterValue,"item_proc_compra_id")<>purchaseItemId THEN UNDO, THROW NEW Progress.Lang.AppError("Provider alterou referencia imutavel.",1).
  END.
  ELSE IF Found(phItems,phItems:NAME + ".item_container_id=" + STRING(itemId),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Provider recriou o item excluido.",1).
  IF NOT Found(phMaster,phMaster:NAME + ".nr-container=" + STRING(cid),EXCLUSIVE-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Provider perdeu mestre original.",1).
  staleValue=operationValue="create" OR operationValue="delete".
  IF operationValue="update" THEN staleValue=beforeValue:GetDecimal("qt_alocada")<>afterValue:GetDecimal("qt_alocada") OR beforeValue:GetDecimal("qt_confirm_emb")<>afterValue:GetDecimal("qt_confirm_emb").
  IF staleValue THEN DO:
   phMaster:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE. phMaster:BUFFER-FIELD("dt_hr_ult_alt_versao_custo"):BUFFER-VALUE=DATETIME(TODAY,MTIME).
   IF NOT phMaster:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Mestre recusou invalidacao de custo.",1).
  END.
  masterAfter=Snapshot(phMaster).
  changesValue=NEW JsonArray(). eventValue=NEW JsonObject(). eventValue:Add("resource","itens_container"). eventValue:Add("operation",operationValue). eventValue:Add("recordId",itemId). eventValue:Add("before",CAST(beforeValue:Clone(),JsonObject)). eventValue:Add("after",CAST(afterValue:Clone(),JsonObject)). changesValue:Add(eventValue).
  DO n=1 TO childChanges:Length: changesValue:Add(CAST(childChanges:GetJsonObject(n):Clone(),JsonObject)). END.
 END.
 /* Nested callers own commit/UNDO. Only the real root emits confirmed audit. */
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("committed",NOT nestedValue).
 IF operationValue<>"delete" THEN poResponse:Add("data",CAST(afterValue:Clone(),JsonObject)).
 masterValue=NEW JsonObject(). masterValue:Add("before",masterBefore). masterValue:Add("after",masterAfter).
 IF nestedValue THEN DO:
  poResponse:Add("pendingChanges",changesValue). poResponse:Add("pendingMaster",masterValue).
  eventValue=NEW JsonObject(). eventValue:Add("before",beforeValue). eventValue:Add("after",afterValue). poResponse:Add("pendingItem",eventValue). poResponse:Add("warnings",warningsValue).
 END.
 ELSE DO:
  auditValue=NEW JsonObject(). auditValue:Add("version",1). auditValue:Add("source","progress-transaction"). auditValue:Add("resource","container-itens"). auditValue:Add("operation",operationValue). auditValue:Add("recordId",itemId). auditValue:Add("container_id",cid).
  auditValue:Add("before",beforeValue). auditValue:Add("after",afterValue). auditValue:Add("master",masterValue). auditValue:Add("changes",changesValue). auditValue:Add("warnings",warningsValue). auditValue:Add("actor",actorValue). poResponse:Add("audit",auditValue).
  IF LOOKUP("LogRule",phRuntime:INTERNAL-ENTRIES)>0 THEN RUN LogRule IN phRuntime("INFO","Item " + STRING(itemId) + " do container " + STRING(cid) + ": " + operationValue + " confirmado.") NO-ERROR.
 END.
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). eventValue=NEW JsonObject(). eventValue:Add("code",failureCode). eventValue:Add("message",err:GetMessage(1)). eventValue:Add("status",failureStatus). poResponse:Add("success",FALSE). poResponse:Add("error",eventValue).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(qAllocations) THEN DO: qAllocations:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qAllocations NO-ERROR. END.
  IF VALID-HANDLE(hAllocations) THEN DELETE OBJECT hAllocations NO-ERROR.
  IF NOT nestedValue THEN DO:
   IF VALID-HANDLE(phItems) THEN phItems:BUFFER-RELEASE() NO-ERROR.
   IF VALID-HANDLE(phMaster) THEN phMaster:BUFFER-RELEASE() NO-ERROR.
   IF VALID-HANDLE(phPurchaseItems) THEN phPurchaseItems:BUFFER-RELEASE() NO-ERROR.
   IF VALID-HANDLE(phPurchases) THEN phPurchases:BUFFER-RELEASE() NO-ERROR.
   IF VALID-HANDLE(phDiscounts) THEN phDiscounts:BUFFER-RELEASE() NO-ERROR.
   IF VALID-HANDLE(phItemCosts) THEN phItemCosts:BUFFER-RELEASE() NO-ERROR.
   IF VALID-HANDLE(phCommercial) THEN phCommercial:BUFFER-RELEASE() NO-ERROR.
  END.
 END FINALLY.
END.

PROCEDURE ValidateValues:
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE nameValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
 RUN Closed(valuesValue,writableFields + ",item_proc_compra_id").
 IF EmptyObject(valuesValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Nenhum campo informado.",1).
 normalizedValues=NEW JsonObject(). names=valuesValue:GetNames().
 DO j=1 TO EXTENT(names):
  nameValue=names[j].
  IF Exact(nameValue,"log_rec_doc_prazo_emb,log_calc_icms,log_calc_ipi") THEN DO:
   IF valuesValue:GetType(nameValue)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON obrigatorio.",1).
   normalizedValues:Add(nameValue,valuesValue:GetLogical(nameValue)).
  END.
  ELSE IF nameValue="observacao" THEN DO:
   IF valuesValue:GetType(nameValue)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Observacao deve ser texto.",1).
   IF LENGTH(valuesValue:GetCharacter(nameValue))>4000 THEN UNDO, THROW NEW Progress.Lang.AppError("Observacao excede4000caracteres.",1).
   normalizedValues:Add(nameValue,valuesValue:GetCharacter(nameValue)).
  END.
  ELSE DO:
   IF valuesValue:GetType(nameValue)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Numero JSON obrigatorio.",1).
   amount=valuesValue:GetDecimal(nameValue).
   IF amount=? THEN UNDO, THROW NEW Progress.Lang.AppError("Numero desconhecido.",1).
   IF nameValue="item_proc_compra_id" THEN DO:
    IF NumberId(valuesValue,nameValue)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra deve ser inteiro positivo32.",1).
    normalizedValues:Add(nameValue,NumberId(valuesValue,nameValue)).
   END.
   ELSE IF nameValue="cod_tipo_calculo" THEN DO:
    IF amount<0 OR amount>2147483647 OR TRUNCATE(amount,0)<>amount THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de calculo deve ser inteiro nao negativo32.",1).
    normalizedValues:Add(nameValue,INTEGER(amount)).
   END.
   ELSE DO:
    IF Exact(nameValue,"qt_alocada,qt_confirm_emb,qt_recbto_fisico") AND amount<0 THEN UNDO, THROW NEW Progress.Lang.AppError("Quantidade negativa nao permitida.",1).
    normalizedValues:Add(nameValue,ROUND(amount,2)).
   END.
  END.
 END.
 IF operationValue="create" THEN DO:
  IF NOT normalizedValues:Has("item_proc_compra_id") OR NOT normalizedValues:Has("qt_alocada") THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra e quantidade obrigatorios.",1).
  IF normalizedValues:GetDecimal("qt_alocada")<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Alocacao inicial deve ser positiva na escala fisica.",1).
 END.
END PROCEDURE.
PROCEDURE CheckAllocation:
 DEFINE VARIABLE balancePath AS CHARACTER NO-UNDO.
 DEFINE VARIABLE availableQuantity AS DECIMAL NO-UNDO.
 DEFINE VARIABLE existingPair AS LOGICAL NO-UNDO.
 failureCode='CONTAINER_ITEM_ALLOCATION_INVALID'. failureStatus=422.
 balancePath=SEARCH('sursum-api/programs/ContainersAllocationBalance.r'). IF balancePath=? THEN balancePath=SEARCH('ContainersAllocationBalance.r').
 IF balancePath=? THEN DO: failureCode='CONTAINER_ITEM_CONFIGURATION'. failureStatus=503. UNDO, THROW NEW Progress.Lang.AppError('Rotina compartilhada de saldo nao publicada.',1). END.
 DO ON ERROR UNDO, THROW:
  RUN VALUE(balancePath)(phPurchaseItems,hAllocations,purchaseItemId,cid,TRUE,OUTPUT availableQuantity,OUTPUT existingPair).
  CATCH err AS Progress.Lang.Error:
   IF INDEX(err:GetMessage(1),'CONTAINER_ITEM_BUSY:')=1 THEN ASSIGN failureCode='CONTAINER_ITEM_BUSY' failureStatus=409.
   UNDO, THROW err.
  END CATCH.
 END.
 failureCode='CONTAINER_ITEM_ALLOCATION_EXCEEDED'. failureStatus=422.
 IF ROUND(quantityAfter,2) - ROUND(quantityBefore,2)>availableQuantity THEN UNDO, THROW NEW Progress.Lang.AppError('Quantidade acrescida excede saldo global do item de compra.',1).
END PROCEDURE.
PROCEDURE ValidateEffects:
 RUN MaintenanceValidateEffects(effectsValue,cid,"itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp","itens_container",itemId,OUTPUT childChanges,OUTPUT warningsValue).
END PROCEDURE.
