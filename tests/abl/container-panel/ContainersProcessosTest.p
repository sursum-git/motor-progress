/* Root driver over real version writer. Undoable TT, no business DB. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE versionBuffers AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE fiscalBuffers AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE closeBuffers AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE runtimeProvider AS HANDLE NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER EXTENT 8 NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE idx AS INTEGER NO-UNDO.
RUN Fixture. RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"public root commits real version writer").
RUN Check(NOT TRANSACTION,"response after actual root commit").
RUN Check(responseValue:GetJsonObject("data"):GetCharacter("type")="message","command returns message").
RUN Check(INDEX(responseValue:GetJsonObject("data"):GetCharacter("message"),"1001")>0,"message contains version ID").
RUN Check(responseValue:GetJsonObject("audit"):GetCharacter("resource")="container_processes","normalized audit resource").
RUN Check(responseValue:GetJsonObject("audit"):GetInteger("recordId")=123,"recordId is container").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("before"):GetCharacter("narrativa")="original","locked before precedes fiscal side effect").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("after"):GetCharacter("narrativa")="fiscal","after includes fiscal side effect").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=7,"version five children and one unified master").
DO idx=1 TO 7:
 RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(idx):GetJsonObject("after"):GetInteger("container_id")=123,"every event has trusted context").
END.
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(3):GetType("recordId")=JsonDataType:STRING,"composite physical key preserved").
RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT responseValue:Has("audit"),"stale command has no confirmed audit").
RUN Check(responseValue:GetJsonObject("error"):GetCharacter("code")="VERSION_CONFLICT","helper conflict preserved").
RUN Fixture. RUN SetMode IN runtimeProvider("fiscal-fail"). RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT responseValue:Has("audit"),"failure never claims audit").
hb[1]:FIND-FIRST(). RUN Check(hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original","fiscal failure rolled back").
hb[3]:FIND-FIRST() NO-ERROR. RUN Check(NOT hb[3]:AVAILABLE,"failed root has no version").
RUN Fixture.
DO TRANSACTION: RUN Invoke. RUN Check(NOT responseValue:GetLogical("success"),"root refuses surrounding transaction"). END.
OUTPUT TO VALUE("containers-processes-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; real writer, TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Invoke:
 RUN ContainersProcessosService.p(versionBuffers,fiscalBuffers,closeBuffers,runtimeProvider,?,policyValue,?,requestValue,OUTPUT responseValue).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + " " + (IF VALID-OBJECT(responseValue) THEN STRING(responseValue:GetJsonText()) ELSE "no response"),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE Parse:
 DEFINE INPUT PARAMETER textValue AS LONGCHAR NO-UNDO. DEFINE OUTPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO. parserValue=NEW ObjectModelParser(). objectValue=CAST(parserValue:Parse(textValue),JsonObject). DELETE OBJECT parserValue.
END PROCEDURE.
{ContainersProcessosFixture.i}
