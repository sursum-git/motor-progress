/* Transactional NF link service contract. Temp tables only, no database. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttContainer NO-UNDO
 FIELD nr-container AS INTEGER
 FIELD cod-estabel AS CHARACTER
 INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttNfs NO-UNDO
 FIELD container_id AS INTEGER
 FIELD documento AS CHARACTER
 FIELD serie AS CHARACTER
 FIELD estab AS CHARACTER
 FIELD nat_operacao AS CHARACTER
 FIELD cod_emitente AS INTEGER
 INDEX pk IS UNIQUE PRIMARY container_id documento serie estab nat_operacao cod_emitente.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE master AS HANDLE NO-UNDO.
DEFINE VARIABLE nfs AS HANDLE NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
CREATE ttContainer. ASSIGN ttContainer.nr-container=123 ttContainer.cod-estabel="5". RELEASE ttContainer.
ASSIGN master=BUFFER ttContainer:HANDLE nfs=BUFFER ttNfs:HANDLE.
policyValue=NEW JsonObject(). policyValue:Add("actor","CIW_TEST"). policyValue:Add("usuario_id",1).
DO TRANSACTION:
FIND FIRST ttContainer WHERE ttContainer.nr-container=123 EXCLUSIVE-LOCK.
parser=NEW ObjectModelParser().
requestValue=CAST(parser:Parse('~{"resource":"nfs","operation":"associar","container_id":123,"expected_nf_stamp":"E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855","nfs":[~{"documento":"100","serie":"A","estab":"5","nat_operacao":"31201","cod_emitente":77}]}'),JsonObject).
RUN VALUE("sursum-api/programs/ContainersNfsLinkService.p")(master,nfs,policyValue,requestValue,OUTPUT responseValue).
RUN Check(responseValue:GetLogical("success") AND responseValue:GetLogical("committed")=FALSE,"associate composes root transaction").
RUN Check(responseValue:GetJsonArray("pendingChanges"):Length=1,"associate reports one audit image").
RUN Check(CAN-FIND(FIRST ttNfs WHERE ttNfs.container_id=123 AND ttNfs.documento="100" AND ttNfs.serie="A" AND ttNfs.estab="5" AND ttNfs.nat_operacao="31201" AND ttNfs.cod_emitente=77),"associate creates complete tuple").
requestValue=CAST(parser:Parse('~{"resource":"nfs","operation":"desassociar","container_id":123,"expected_nf_stamp":"x","nfs":[~{"documento":"100","serie":"A","estab":"5","nat_operacao":"31201","cod_emitente":77}]}'),JsonObject).
requestValue:Set("expected_nf_stamp",responseValue:GetJsonObject("data"):GetCharacter("nf_stamp")).
RUN VALUE("sursum-api/programs/ContainersNfsLinkService.p")(master,nfs,policyValue,requestValue,OUTPUT responseValue).
RUN Check(responseValue:GetLogical("success") AND responseValue:GetJsonArray("pendingChanges"):GetJsonObject(1):GetCharacter("operation")="delete","disassociate reports deletion audit image").
RUN Check(NOT CAN-FIND(FIRST ttNfs WHERE ttNfs.container_id=123),"disassociate deletes complete tuple only").
END.
OUTPUT TO VALUE("containers-nfs-link-service-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks" SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue,1).
 checks=checks + 1.
END PROCEDURE.
