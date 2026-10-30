/* Shared private maintenance effects contract. Requires ContainerTransactionAudit.i.
   No host globals, DB access, writes, transaction control or confirmed audit.
   CID on a ledger image is the execution origin, not the historical item's owner. */
FUNCTION MaintenanceExact RETURNS LOGICAL (valueText AS CHARACTER,allowedText AS CHARACTER):
 DEFINE VARIABLE exactText AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 exactText=valueText.
 DO n=1 TO NUM-ENTRIES(allowedText): IF exactText=ENTRY(n,allowedText) THEN RETURN TRUE. END.
 RETURN FALSE.
END FUNCTION.
FUNCTION MaintenanceNumberId RETURNS INTEGER (objectValue AS JsonObject,fieldName AS CHARACTER):
 DEFINE VARIABLE amount AS DECIMAL NO-UNDO.
 DEFINE VARIABLE token AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF NOT objectValue:Has(fieldName) THEN RETURN ?.
 IF objectValue:GetType(fieldName)<>JsonDataType:NUMBER THEN RETURN ?.
 /* PHP's confirmed audit importer requires integer JSON tokens, not a
    decimal such as1.0 that merely happens to have an integral numeric value. */
 token=STRING(objectValue:GetJsonText(fieldName)).
 IF LENGTH(token)<1 OR LENGTH(token)>10 THEN RETURN ?.
 DO n=1 TO LENGTH(token): IF INDEX("0123456789",SUBSTRING(token,n,1))=0 THEN RETURN ?. END.
 amount=objectValue:GetDecimal(fieldName).
 IF amount=? OR amount<1 OR amount>2147483647 OR TRUNCATE(amount,0)<>amount THEN RETURN ?.
 RETURN INTEGER(amount).
END FUNCTION.
FUNCTION MaintenanceEmptySnapshot RETURNS LOGICAL (objectValue AS JsonObject):
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 names=objectValue:GetNames().
 IF EXTENT(names)=? THEN RETURN TRUE.
 RETURN EXTENT(names)=0.
END FUNCTION.
PROCEDURE MaintenanceClosedExact:
 DEFINE INPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER allowedText AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER requireAll AS LOGICAL NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(objectValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto JSON de efeitos obrigatorio.",1).
 names=objectValue:GetNames().
 IF requireAll AND EXTENT(names)<>NUM-ENTRIES(allowedText) THEN UNDO, THROW NEW Progress.Lang.AppError("Campos obrigatorios de efeito ausentes.",1).
 DO n=1 TO EXTENT(names):
  IF NOT MaintenanceExact(names[n],allowedText) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo de efeito nao permitido: " + names[n],1).
 END.
END PROCEDURE.
PROCEDURE MaintenanceValidateEvent:
 DEFINE INPUT PARAMETER eventValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER cid AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER allowedResources AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER resourceValue AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER actionValue AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER keyId AS INTEGER NO-UNDO.
 DEFINE VARIABLE image AS JsonObject NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE pkField AS CHARACTER NO-UNDO.
 DEFINE VARIABLE side AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 RUN MaintenanceClosedExact(eventValue,"resource,operation,recordId,before,after",TRUE).
 IF eventValue:GetType("resource")<>JsonDataType:STRING OR eventValue:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso/operacao de efeito invalido.",1).
 ASSIGN resourceValue=eventValue:GetCharacter("resource") actionValue=eventValue:GetCharacter("operation") keyId=MaintenanceNumberId(eventValue,"recordId").
 IF (resourceValue<>"containers" AND NOT MaintenanceExact(resourceValue,allowedResources)) OR NOT MaintenanceExact(resourceValue,"containers,itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp") OR NOT MaintenanceExact(actionValue,"create,update,delete") OR keyId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Efeito fora do contrato fechado.",1).
 IF eventValue:GetType("before")<>JsonDataType:OBJECT OR eventValue:GetType("after")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots de efeito obrigatorios.",1).
 pkField=IF resourceValue="containers" THEN "container_id" ELSE IF resourceValue="itens_container" THEN "item_container_id" ELSE IF resourceValue="despesas_container" THEN "despesa_container_id" ELSE IF resourceValue="calcs_imp_container" THEN "calc_imp_container_id" ELSE "cta_corren_fornec_imp_id".
 DO side=1 TO 2:
  image=eventValue:GetJsonObject(ENTRY(side,"before,after")).
  IF NOT MaintenanceEmptySnapshot(image) THEN DO:
   IF MaintenanceNumberId(image,"container_id")<>cid OR MaintenanceNumberId(image,pkField)<>keyId THEN UNDO, THROW NEW Progress.Lang.AppError("Efeito sem contexto de origem/PK confirmado.",1).
   names=image:GetNames().
   DO n=1 TO EXTENT(names):
    IF image:GetType(names[n])=JsonDataType:OBJECT OR image:GetType(names[n])=JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot fisico de efeito deve ter campos escalares.",1).
   END.
  END.
 END.
 IF actionValue="create" AND (NOT MaintenanceEmptySnapshot(eventValue:GetJsonObject("before")) OR MaintenanceEmptySnapshot(eventValue:GetJsonObject("after"))) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots create inconsistentes.",1).
 IF actionValue="delete" AND (MaintenanceEmptySnapshot(eventValue:GetJsonObject("before")) OR NOT MaintenanceEmptySnapshot(eventValue:GetJsonObject("after"))) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots delete inconsistentes.",1).
 IF actionValue="update" AND (MaintenanceEmptySnapshot(eventValue:GetJsonObject("before")) OR MaintenanceEmptySnapshot(eventValue:GetJsonObject("after"))) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshots update inconsistentes.",1).
 IF resourceValue="containers" AND keyId<>cid THEN UNDO, THROW NEW Progress.Lang.AppError("Efeito de outro mestre.",1).
END PROCEDURE.
PROCEDURE MaintenanceValidateEffects:
 DEFINE INPUT PARAMETER effectsValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER cid AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER allowedResources AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER skipResource AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER skipId AS INTEGER NO-UNDO.
 DEFINE OUTPUT PARAMETER changesValue AS JsonArray NO-UNDO.
 DEFINE OUTPUT PARAMETER warningsValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE incoming AS JsonArray NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE previous AS JsonObject NO-UNDO.
 DEFINE VARIABLE resourceValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE actionValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE keyId AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 changesValue=?. warningsValue=?.
 IF cid=? OR cid<1 THEN UNDO, THROW NEW Progress.Lang.AppError("Contexto de efeitos invalido.",1).
 RUN MaintenanceClosedExact(effectsValue,"success,changes,warnings",FALSE).
 IF effectsValue:GetType("success")<>JsonDataType:BOOLEAN OR effectsValue:GetLogical("success")<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("Provider nao confirmou efeitos.",1).
 IF effectsValue:GetType("changes")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Provider deve devolver mudancas efetivas.",1).
 incoming=effectsValue:GetJsonArray("changes").
 IF incoming:Length>50000 THEN UNDO, THROW NEW Progress.Lang.AppError("Auditoria de efeitos excede limite.",1).
 changesValue=NEW JsonArray(). warningsValue=NEW JsonArray().
 IF effectsValue:Has("warnings") THEN DO:
  IF effectsValue:GetType("warnings")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Avisos devem ser lista.",1).
  IF effectsValue:GetJsonArray("warnings"):Length>1000 THEN UNDO, THROW NEW Progress.Lang.AppError("Avisos excedem limite.",1).
  DO n=1 TO effectsValue:GetJsonArray("warnings"):Length:
   IF effectsValue:GetJsonArray("warnings"):GetType(n)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Aviso deve ser texto.",1).
   IF LENGTH(effectsValue:GetJsonArray("warnings"):GetCharacter(n))>4000 THEN UNDO, THROW NEW Progress.Lang.AppError("Aviso excede limite.",1).
   warningsValue:Add(effectsValue:GetJsonArray("warnings"):GetCharacter(n)).
  END.
 END.
 DO n=1 TO incoming:Length:
  IF incoming:GetType(n)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Mudanca invalida.",1).
  eventValue=incoming:GetJsonObject(n).
  RUN MaintenanceValidateEvent(eventValue,cid,allowedResources,OUTPUT resourceValue,OUTPUT actionValue,OUTPUT keyId).
  IF resourceValue="containers" THEN NEXT.
  IF resourceValue=skipResource AND keyId=skipId THEN NEXT.
  matched=FALSE.
  DO k=1 TO changesValue:Length:
   previous=changesValue:GetJsonObject(k).
   IF previous:GetCharacter("resource")=resourceValue AND previous:GetInteger("recordId")=keyId THEN DO:
    IF previous:GetCharacter("operation")<>"create" THEN RUN ProcessCopyProperties(eventValue:GetJsonObject("before"),previous:GetJsonObject("before"),TRUE).
    IF actionValue="delete" THEN previous:Set("after",NEW JsonObject()).
    ELSE RUN ProcessCopyProperties(eventValue:GetJsonObject("after"),previous:GetJsonObject("after"),FALSE).
    previous:Set("operation",IF MaintenanceEmptySnapshot(previous:GetJsonObject("before")) THEN "create" ELSE IF MaintenanceEmptySnapshot(previous:GetJsonObject("after")) THEN "delete" ELSE "update").
    matched=TRUE. LEAVE.
   END.
  END.
  IF NOT matched THEN changesValue:Add(CAST(eventValue:Clone(),JsonObject)).
 END.
 /* Coalescing must not create an envelope that the transaction importer would
    reject after commit; validate the final event sides/types/identity again. */
 DO n=1 TO changesValue:Length:
  RUN MaintenanceValidateEvent(changesValue:GetJsonObject(n),cid,allowedResources,OUTPUT resourceValue,OUTPUT actionValue,OUTPUT keyId).
 END.
END PROCEDURE.
