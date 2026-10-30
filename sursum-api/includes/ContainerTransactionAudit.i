/* Physical snapshots and event coalescing only. No business calculation. */
FUNCTION ProcessSnapshot RETURNS JsonObject (bufferValue AS HANDLE,cid AS INTEGER):
 DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
 DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE iv AS INTEGER NO-UNDO.
 DEFINE VARIABLE i64 AS INT64 NO-UNDO.
 DEFINE VARIABLE dv AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE cv AS CHARACTER NO-UNDO.
 DEFINE VARIABLE lv AS LOGICAL NO-UNDO.
 DEFINE VARIABLE da AS DATE NO-UNDO.
 DEFINE VARIABLE dt AS DATETIME NO-UNDO.
 DEFINE VARIABLE dz AS DATETIME-TZ NO-UNDO.
 resultValue=NEW JsonObject().
 DO n=1 TO bufferValue:NUM-FIELDS:
  fieldValue=bufferValue:BUFFER-FIELD(n). fieldName=REPLACE(fieldValue:NAME,"-","_").
  IF fieldName="nr_container" THEN fieldName="container_id".
  IF fieldValue:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot escalar obrigatorio.",1).
  IF fieldValue:BUFFER-VALUE=? THEN resultValue:AddNull(fieldName).
  ELSE CASE fieldValue:DATA-TYPE:
   WHEN "INTEGER" THEN DO: iv=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,iv). END.
   WHEN "INT64" THEN DO: i64=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,i64). END.
   WHEN "DECIMAL" THEN DO: dv=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,dv). END.
   WHEN "CHARACTER" THEN DO: cv=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,cv). END.
   WHEN "LOGICAL" THEN DO: lv=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,lv). END.
   WHEN "DATE" THEN DO: da=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,da). END.
   WHEN "DATETIME" THEN DO: dt=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,dt). END.
   WHEN "DATETIME-TZ" THEN DO: dz=fieldValue:BUFFER-VALUE. resultValue:Add(fieldName,dz). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo fisico de auditoria nao suportado.",1).
  END CASE.
 END.
 IF NOT resultValue:Has("container_id") THEN resultValue:Add("container_id",cid).
 RETURN resultValue.
END FUNCTION.
PROCEDURE ProcessCopyProperties:
 DEFINE INPUT PARAMETER sourceValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER targetValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER missingOnly AS LOGICAL NO-UNDO.
 DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 namesValue=sourceValue:GetNames().
 DO n=1 TO EXTENT(namesValue):
  nameValue=namesValue[n].
  IF missingOnly AND targetValue:Has(nameValue) THEN NEXT.
  IF targetValue:Has(nameValue) THEN targetValue:Remove(nameValue).
  IF sourceValue:IsNull(nameValue) THEN targetValue:AddNull(nameValue).
  ELSE CASE sourceValue:GetType(nameValue):
   WHEN JsonDataType:STRING THEN targetValue:Add(nameValue,sourceValue:GetCharacter(nameValue)).
   WHEN JsonDataType:NUMBER THEN DO:
    /* Preserve integer JSON tokens for PK/type checking by the PHP importer. */
    IF INDEX(STRING(sourceValue:GetJsonText(nameValue)),".")=0 AND INDEX(CAPS(STRING(sourceValue:GetJsonText(nameValue))),"E")=0 THEN targetValue:Add(nameValue,sourceValue:GetInt64(nameValue)).
    ELSE targetValue:Add(nameValue,sourceValue:GetDecimal(nameValue)).
   END.
   WHEN JsonDataType:BOOLEAN THEN targetValue:Add(nameValue,sourceValue:GetLogical(nameValue)).
   WHEN JsonDataType:OBJECT THEN targetValue:Add(nameValue,CAST(sourceValue:GetJsonObject(nameValue):Clone(),JsonObject)).
   WHEN JsonDataType:ARRAY THEN targetValue:Add(nameValue,CAST(sourceValue:GetJsonArray(nameValue):Clone(),JsonArray)).
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo JSON de auditoria invalido.",1).
  END CASE.
 END.
END PROCEDURE.
PROCEDURE ProcessMergeEvents:
 DEFINE INPUT PARAMETER incoming AS JsonArray NO-UNDO.
 DEFINE INPUT PARAMETER cid AS INTEGER NO-UNDO.
 DEFINE INPUT-OUTPUT PARAMETER resultValue AS JsonArray NO-UNDO.
 RUN ProcessMergeScopedEvents(incoming,cid,'container_versions,item_container_custos,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos,despesas_container,calcs_imp_container,cta_corren_custo_distr,item_custos,nfs_container',FALSE,INPUT-OUTPUT resultValue).
END PROCEDURE.
/* Full maintenance images must form a continuous chain within the root. */
PROCEDURE ProcessMergeItemEvents:
 DEFINE INPUT PARAMETER incoming AS JsonArray NO-UNDO.
 DEFINE INPUT PARAMETER cid AS INTEGER NO-UNDO.
 DEFINE INPUT-OUTPUT PARAMETER resultValue AS JsonArray NO-UNDO.
 RUN ProcessMergeScopedEvents(incoming,cid,'itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp',TRUE,INPUT-OUTPUT resultValue).
END PROCEDURE.
PROCEDURE ProcessMergeScopedEvents:
 DEFINE INPUT PARAMETER incoming AS JsonArray NO-UNDO.
 DEFINE INPUT PARAMETER cid AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER allowedResources AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER strictImages AS LOGICAL NO-UNDO.
 DEFINE INPUT-OUTPUT PARAMETER resultValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE previous AS JsonObject NO-UNDO.
 DEFINE VARIABLE snapshotValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE resourceValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(resultValue) THEN resultValue=NEW JsonArray().
 DO n=1 TO incoming:Length:
  eventValue=CAST(incoming:GetJsonObject(n):Clone(),JsonObject). resourceValue=eventValue:GetCharacter("resource").
  /* The root's full locked master snapshots replace every intermediate state. */
  IF resourceValue="containers" THEN DO: DELETE OBJECT eventValue. NEXT. END.
  IF LOOKUP(resourceValue,allowedResources)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso de auditoria interno invalido.",1).
  DO j=1 TO 2:
   snapshotValue=eventValue:GetJsonObject(ENTRY(j,"before,after")). EXTENT(namesValue)=?. namesValue=snapshotValue:GetNames().
   IF EXTENT(namesValue)>0 THEN DO:
    IF snapshotValue:Has("container_id") THEN DO:
     IF snapshotValue:GetType("container_id")<>JsonDataType:NUMBER OR snapshotValue:GetInteger("container_id")<>cid THEN UNDO, THROW NEW Progress.Lang.AppError("Auditoria de outro container.",1).
    END.
    ELSE snapshotValue:Add("container_id",cid).
   END.
  END.
  foundValue=FALSE.
  DO k=1 TO resultValue:Length:
   previous=resultValue:GetJsonObject(k).
   IF previous:GetCharacter("resource")=resourceValue AND previous:GetJsonText("recordId")=eventValue:GetJsonText("recordId") THEN DO:
    IF strictImages AND NOT COMPARE(STRING(previous:GetJsonObject('after'):GetJsonText()),'=',STRING(eventValue:GetJsonObject('before'):GetJsonText()),'RAW') THEN UNDO, THROW NEW Progress.Lang.AppError('Imagens de auditoria descontinuas no lote.',1).
    /* Distribution intentionally reports a narrow changed-field snapshot.
       Keep the complete create image and apply its actual final delta. */
    IF previous:GetCharacter("operation")<>"create" THEN RUN ProcessCopyProperties(eventValue:GetJsonObject("before"),previous:GetJsonObject("before"),TRUE).
    IF eventValue:GetCharacter("operation")="delete" THEN previous:Set("after",NEW JsonObject()).
    ELSE RUN ProcessCopyProperties(eventValue:GetJsonObject("after"),previous:GetJsonObject("after"),FALSE).
    previous:Set("operation",IF STRING(previous:GetJsonObject("before"):GetJsonText())="~{~}" THEN "create" ELSE IF eventValue:GetCharacter("operation")="delete" THEN "delete" ELSE "update").
    foundValue=TRUE. LEAVE.
   END.
  END.
  IF NOT foundValue THEN resultValue:Add(eventValue). ELSE DELETE OBJECT eventValue.
 END.
END PROCEDURE.
