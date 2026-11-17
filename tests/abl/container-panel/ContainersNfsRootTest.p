BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE masterTable AS HANDLE NO-UNDO.
DEFINE VARIABLE notesTable AS HANDLE NO-UNDO.
DEFINE VARIABLE master AS HANDLE NO-UNDO.
DEFINE VARIABLE notes AS HANDLE NO-UNDO.
DEFINE VARIABLE versionBuffers AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE fiscalBuffers AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE closeBuffers AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE emptyStamp AS CHARACTER NO-UNDO INITIAL "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855".
DEFINE VARIABLE currentStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
{sursum-api/includes/ContainerNfLinkContract.i}

CREATE TEMP-TABLE masterTable.
masterTable:UNDO=TRUE.
masterTable:ADD-NEW-FIELD("nr-container","integer").
masterTable:ADD-NEW-FIELD("cod-estabel","character").
masterTable:TEMP-TABLE-PREPARE("rootContainer").
master=masterTable:DEFAULT-BUFFER-HANDLE.
CREATE TEMP-TABLE notesTable.
notesTable:UNDO=TRUE.
notesTable:ADD-NEW-FIELD("container_id","integer").
notesTable:ADD-NEW-FIELD("documento","character").
notesTable:ADD-NEW-FIELD("serie","character").
notesTable:ADD-NEW-FIELD("estab","character").
notesTable:ADD-NEW-FIELD("nat_operacao","character").
notesTable:ADD-NEW-FIELD("cod_emitente","integer").
notesTable:TEMP-TABLE-PREPARE("rootNotes").
notes=notesTable:DEFAULT-BUFFER-HANDLE.
DO TRANSACTION:
 master:BUFFER-CREATE().
 master:BUFFER-FIELD("nr-container"):BUFFER-VALUE=123.
 master:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE="5".
 master:BUFFER-RELEASE().
END.
versionBuffers[1]=master. versionBuffers[4]=notes.
policy=NEW JsonObject(). actor=NEW JsonObject(). actor:Add("login","CIW_NF_ROOT_TEST").
policy:Add("actor",actor). policy:Add("usuario_id",1). policy:Add("despesa_distr_custo",1).
requestValue=NEW JsonObject().
requestValue:Add("resource","nfs"). requestValue:Add("operation","associar").
requestValue:Add("container_id",123). requestValue:Add("expected_nf_stamp",emptyStamp).
rowsValue=NEW JsonArray(). rowValue=NEW JsonObject().
rowValue:Add("documento","CIW_NEW_TEST"). rowValue:Add("serie","A").
rowValue:Add("estab","5"). rowValue:Add("nat_operacao","31201"). rowValue:Add("cod_emitente",77).
rowsValue:Add(rowValue). requestValue:Add("nfs",rowsValue).
RUN Invoke.
RUN Check(resultValue:GetLogical("success"),"association through root driver").
RUN Check(resultValue:GetLogical("committed"),"association confirms actual root commit").
RUN Check(resultValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=1,"one link audited").
RUN Check(resultValue:GetJsonObject("audit"):GetJsonObject("actor"):GetCharacter("login")="CIW_NF_ROOT_TEST","trusted actor").
RUN Check(NOT TRANSACTION,"response after root commit").
currentStamp=ContainerNfLinkStamp(notes,123).
RUN Check(currentStamp<>emptyStamp,"stamp changed after association").
RUN Invoke.
RUN Check(NOT resultValue:GetLogical("success") AND NOT resultValue:Has("audit"),"stale request rejects without audit").
RUN Check(ContainerNfLinkStamp(notes,123)=currentStamp,"conflict preserves link").
requestValue:Set("operation","desassociar").
requestValue:Set("expected_nf_stamp",currentStamp).
rowValue:Set("nat_operacao","DIFFERENT").
RUN Invoke.
RUN Check(NOT resultValue:GetLogical("success"),"different full key cannot remove link").
RUN Check(ContainerNfLinkStamp(notes,123)=currentStamp,"wrong key preserves stamp").
rowValue:Set("nat_operacao","31201").
RUN Invoke.
RUN Check(resultValue:GetLogical("success") AND resultValue:GetLogical("committed"),"disassociation commits").
RUN Check(resultValue:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(1):GetCharacter("operation")="delete","deletion image audited").
RUN Check(ContainerNfLinkStamp(notes,123)=emptyStamp,"test links removed").
OUTPUT TO "containers-nfs-root-tests.log".
PUT UNFORMATTED "PASS " checks " checks; NUM-DBS=" NUM-DBS SKIP.
OUTPUT CLOSE.

PROCEDURE Invoke:
 RUN VALUE("sursum-api/programs/ContainersProcessosService.r")
  (versionBuffers,fiscalBuffers,closeBuffers,?, ?,policy,?,requestValue,OUTPUT resultValue).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + " " + STRING(resultValue:GetJsonText()),1).
 checks=checks + 1.
END PROCEDURE.
