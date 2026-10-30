/* Real orchestration, trusted doubles for separately tested financial/fiscal rules. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttMaster FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttEffects FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE VARIABLE buffersValue AS HANDLE EXTENT 10 NO-UNDO.
DEFINE VARIABLE runtimeValue AS HANDLE NO-UNDO.
DEFINE VARIABLE ctx AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE orderText AS CHARACTER NO-UNDO.
DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
CREATE ttMaster. ttMaster.nr-container=123. RELEASE ttMaster.
buffersValue[1]=BUFFER ttMaster:HANDLE. policy=NEW JsonObject().
RUN ContainersPagamentosRuntime.p PERSISTENT SET runtimeValue(THIS-PROCEDURE,THIS-PROCEDURE,THIS-PROCEDURE,buffersValue,policy).
ctx=NEW JsonObject(). ctx:Add("operation","associate"). ctx:Add("container_id",123).
DO TRANSACTION ON ERROR UNDO, THROW:
 FIND FIRST ttMaster EXCLUSIVE-LOCK. RUN ChangePayment IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,INPUT ctx,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("success") AND orderText="finance,fiscal","associate reuses finance before fiscal").
 RUN ValidateTitle IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,INPUT 7,OUTPUT resultValue).
 RUN Check(resultValue:GetInteger("num_id_tit_ap")=7,"eligibility uses trusted reader and strict get").
END.
orderText="". ctx:Set("operation","disassociate").
DO TRANSACTION ON ERROR UNDO, THROW:
 FIND FIRST ttMaster EXCLUSIVE-LOCK. RUN ChangePayment IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,INPUT ctx,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("success") AND orderText="finance","unlink does not add unproven fiscal call").
END.
ctx:Set("operation","associate"). modeValue="fiscal-fail". rejected=FALSE.
DO TRANSACTION ON ERROR UNDO, THROW:
 FIND FIRST ttMaster EXCLUSIVE-LOCK. RUN ChangePayment IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,INPUT ctx,OUTPUT resultValue).
 CATCH e AS Progress.Lang.Error: rejected=TRUE. END CATCH.
END.
RUN Check(rejected AND NOT CAN-FIND(FIRST ttEffects),"fiscal failure rolls preceding financial effect back").
rejected=FALSE.
DO ON ERROR UNDO, THROW:
 RUN ChangePayment IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,INPUT ctx,OUTPUT resultValue).
 CATCH e AS Progress.Lang.Error: rejected=TRUE. END CATCH.
END.
RUN Check(rejected,"participants refuse execution outside transaction").
DELETE PROCEDURE runtimeValue.
OUTPUT TO VALUE("containers-pagamentos-composition-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; actual runtime TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER textValue AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + textValue,1).
END PROCEDURE.
PROCEDURE RunFinancial:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 orderText="finance". IF modeValue="fiscal-fail" THEN DO: CREATE ttEffects. ttEffects.id=1. RELEASE ttEffects. END.
 responseValue=NEW JsonObject(). responseValue:Add("success",TRUE). responseValue:Add("changes",NEW JsonArray()). responseValue:Add("warnings",NEW JsonArray()).
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 orderText=orderText + ",fiscal". IF modeValue="fiscal-fail" THEN UNDO, THROW NEW Progress.Lang.AppError("Injected fiscal failure",1).
 responseValue=NEW JsonObject(). responseValue:Add("success",TRUE). responseValue:Add("changes",NEW JsonArray()). responseValue:Add("warnings",NEW JsonArray()).
END PROCEDURE.
PROCEDURE ReadEligible:
 DEFINE INPUT PARAMETER requestValue AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 IF requestValue:GetCharacter("operation")<>"get" OR requestValue:GetCharacter("resource")<>"pagamentos-disponiveis" OR requestValue:GetInteger("container_id")<>123 OR requestValue:GetInteger("id")<>7 THEN UNDO, THROW NEW Progress.Lang.AppError("Bad eligibility proof",1).
 rowValue=NEW JsonObject(). rowValue:Add("num_id_tit_ap",7).
 responseValue=NEW JsonObject(). responseValue:Add("success",TRUE). responseValue:Add("data",rowValue).
END PROCEDURE.
