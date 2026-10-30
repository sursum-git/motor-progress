/* Reusable writer composed by ContainersProcessosService inside its root transaction. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE operationValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE changesValue AS JsonArray NO-UNDO.
DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE dataValue AS JsonObject NO-UNDO.
DEFINE VARIABLE expectedStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE currentStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE whereValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
{sursum-api/includes/ContainerProcessBoundary.i}
{sursum-api/includes/ContainerNfLinkContract.i}
FUNCTION NfWhere RETURNS CHARACTER (rowValue AS JsonObject,cid AS INTEGER):
 RETURN "WHERE " + phNfs:NAME + ".container_id = " + STRING(cid)
  + " AND " + phNfs:NAME + ".documento = " + QUOTER(rowValue:GetCharacter("documento"))
  + " AND " + phNfs:NAME + ".serie = " + QUOTER(rowValue:GetCharacter("serie"))
  + " AND " + phNfs:NAME + ".estab = " + QUOTER(rowValue:GetCharacter("estab"))
  + " AND " + phNfs:NAME + ".nat_operacao = " + QUOTER(rowValue:GetCharacter("nat_operacao"))
  + " AND " + phNfs:NAME + ".cod_emitente = " + STRING(rowValue:GetInteger("cod_emitente")).
END FUNCTION.
cid=ContainerProcessRequest(poRequest).
IF NOT VALID-HANDLE(phMaster) OR NOT VALID-HANDLE(phNfs) OR NOT VALID-OBJECT(poPolicy) OR NOT poPolicy:Has("actor") THEN UNDO, THROW NEW Progress.Lang.AppError("Contexto privado de notas indisponivel.",1).
IF NOT phMaster:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("Container deve estar bloqueado pela transacao raiz.",1).
operationValue=poRequest:GetCharacter("operation"). expectedStamp=poRequest:GetCharacter("expected_nf_stamp").
currentStamp=ContainerNfLinkStamp(phNfs,cid).
IF currentStamp<>expectedStamp THEN UNDO, THROW NEW Progress.Lang.AppError("Notas foram alteradas; atualize a consulta antes de confirmar.",1).
changesValue=NEW JsonArray().
DO n=1 TO poRequest:GetJsonArray("nfs"):Length:
 rowValue=poRequest:GetJsonArray("nfs"):GetJsonObject(n).
 whereValue=NfWhere(rowValue,cid).
 IF operationValue="associar" THEN DO:
  foundValue=phNfs:FIND-FIRST(whereValue,EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF foundValue THEN UNDO, THROW NEW Progress.Lang.AppError("Nota ja esta associada ao container.",1).
  IF phNfs:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Nota em uso.",1).
  phNfs:BUFFER-CREATE().
  ASSIGN phNfs:BUFFER-FIELD("container_id"):BUFFER-VALUE=cid
   phNfs:BUFFER-FIELD("documento"):BUFFER-VALUE=rowValue:GetCharacter("documento")
   phNfs:BUFFER-FIELD("serie"):BUFFER-VALUE=rowValue:GetCharacter("serie")
   phNfs:BUFFER-FIELD("estab"):BUFFER-VALUE=rowValue:GetCharacter("estab")
   phNfs:BUFFER-FIELD("nat_operacao"):BUFFER-VALUE=rowValue:GetCharacter("nat_operacao")
   phNfs:BUFFER-FIELD("cod_emitente"):BUFFER-VALUE=rowValue:GetInteger("cod_emitente").
  afterValue=ContainerNfLinkSnapshot(phNfs). eventValue=NEW JsonObject(). eventValue:Add("resource","nfs_container"). eventValue:Add("operation","create"). eventValue:Add("recordId",ContainerNfLinkRecordId(phNfs)). eventValue:Add("before",NEW JsonObject()). eventValue:Add("after",afterValue). changesValue:Add(eventValue). phNfs:BUFFER-RELEASE().
 END.
 ELSE DO:
  foundValue=phNfs:FIND-FIRST(whereValue,EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF NOT foundValue THEN UNDO, THROW NEW Progress.Lang.AppError("Nota nao esta associada ao container.",1).
  IF phNfs:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Nota em uso.",1).
  beforeValue=ContainerNfLinkSnapshot(phNfs). eventValue=NEW JsonObject(). eventValue:Add("resource","nfs_container"). eventValue:Add("operation","delete"). eventValue:Add("recordId",ContainerNfLinkRecordId(phNfs)). eventValue:Add("before",beforeValue). eventValue:Add("after",NEW JsonObject()). changesValue:Add(eventValue). phNfs:BUFFER-DELETE().
 END.
END.
poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("committed",FALSE). dataValue=NEW JsonObject(). dataValue:Add("container_id",cid). dataValue:Add("count",changesValue:Length). dataValue:Add("nf_stamp",ContainerNfLinkStamp(phNfs,cid)). poResponse:Add("data",dataValue). poResponse:Add("pendingChanges",changesValue).
