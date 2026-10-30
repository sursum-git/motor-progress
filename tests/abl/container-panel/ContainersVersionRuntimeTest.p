/* Real helper pipeline over TT fixtures. No database or sequence invocation. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 34 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 34 NO-UNDO.
DEFINE VARIABLE collectors AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE sources AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE targets AS HANDLE EXTENT 5 NO-UNDO.
DEFINE VARIABLE runtimeValue AS HANDLE NO-UNDO.
DEFINE VARIABLE oReq AS JsonObject NO-UNDO.
DEFINE VARIABLE oFin AS JsonObject NO-UNDO.
DEFINE VARIABLE oPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE contextCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE fiscalCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE rejectContext AS LOGICAL NO-UNDO.
DEFINE VARIABLE errorValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO.
RUN Fixture.
DO i=1 TO 25: collectors[i]=hb[i]. END.
DO i=1 TO 4: sources[i]=hb[i + 25]. END.
DO i=1 TO 5: targets[i]=hb[i + 29]. END.
policyValue=NEW JsonObject().
RUN ContainersVersionRuntime.p PERSISTENT SET runtimeValue(THIS-PROCEDURE,THIS-PROCEDURE,collectors,sources,targets,THIS-PROCEDURE,policyValue,?).
RUN GetStatus IN runtimeValue(OUTPUT resultValue).
RUN Check(resultValue:GetLogical("confirmed") AND NOT resultValue:GetLogical("distribution_enabled"),"private capabilities do not enable distribution").
RUN NextVersionId IN runtimeValue(OUTPUT sequenceValue) NO-ERROR.
RUN Check(ERROR-STATUS:ERROR,"sequence callback refuses outside transaction before real sequence").
RUN CollectVersionSnapshot IN runtimeValue(hb[1],OUTPUT resultValue) NO-ERROR.
RUN Check(ERROR-STATUS:ERROR AND contextCalls=0,"snapshot refuses no transaction before context or helper").
DO TRANSACTION:
 hb[1]:FIND-FIRST("WHERE " + hb[1]:NAME + ".nr-container=123",EXCLUSIVE-LOCK).
 RUN PrepareVersionFiscal IN runtimeValue(hb[1],OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("success") AND NOT resultValue:Has("audit") AND fiscalCalls=1,"single HeaderRules delegate has no commit audit").
 RUN CollectVersionSnapshot IN runtimeValue(hb[1],OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("confirmed") AND resultValue:GetInteger("container_id")=123,"real pipeline returns confirmed scoped DTO").
 RUN Check(resultValue:GetJsonObject("cost"):GetCharacter("source")="container-version-cost-snapshot","single central adapter provenance").
 RUN Check(resultValue:GetJsonArray("payments"):GetJsonObject(1):GetDecimal("vl_real")=1000,"same totals helper row values flow through snapshot").
 RUN Check(resultValue:GetJsonObject("cost"):GetJsonArray("items_real"):GetJsonObject(1):GetDecimal("vl_total_real")=1070,"real collector and math reused unchanged").
 RUN Check(resultValue:GetJsonObject("header"):GetDecimal("perc_fixo_container")=7,"physical master captured by central auxiliary").
 RUN CollectVersionSnapshot IN runtimeValue(hb[1],OUTPUT resultValue).
 RUN Check(contextCalls=2,"private context read every collection; no session cache").
 rejectContext=TRUE.
 RUN CollectVersionSnapshot IN runtimeValue(hb[1],OUTPUT resultValue) NO-ERROR. errorValue=ERROR-STATUS:ERROR.
 RUN Check(errorValue,"unconfirmed private context fails before helper output").
END.
RUN Check(NOT policyValue:Has("capture_rows"),"caller policy unchanged by private row capture").
DELETE PROCEDURE runtimeValue.
RUN ContainersVersionRuntime.p PERSISTENT SET runtimeValue(THIS-PROCEDURE,THIS-PROCEDURE,collectors,sources,targets,THIS-PROCEDURE,policyValue,THIS-PROCEDURE).
RUN NextItemCustoId IN runtimeValue(OUTPUT sequenceValue) NO-ERROR.
RUN Check(ERROR-STATUS:ERROR,"item cost sequence refuses outside root transaction").
DO TRANSACTION:
 RUN NextItemCustoId IN runtimeValue(OUTPUT sequenceValue).
 RUN Check(sequenceValue=2501,"item cost sequence uses trusted private TT provider").
END.
OUTPUT TO VALUE("containers-version-runtime-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks; real helpers, TT only." SKIP. OUTPUT CLOSE.
DELETE PROCEDURE runtimeValue.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue,1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE GetVersionContext:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE financeValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE species AS JsonArray NO-UNDO.
 contextCalls=contextCalls + 1.
 contextValue=NEW JsonObject(). contextValue:Add("confirmed",NOT rejectContext). contextValue:Add("container_id",INTEGER(master:BUFFER-FIELD("nr-container"):BUFFER-VALUE)).
 contextValue:Add("cost_policy",CAST(oPolicy:Clone(),JsonObject)). financeValue=NEW JsonObject().
 species=NEW JsonArray(). species:Add("AF"). financeValue:Add("adiantamentos",species).
 species=NEW JsonArray(). species:Add("DI"). financeValue:Add("titulos",species). contextValue:Add("finance_policy",financeValue).
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 IF contextValue:GetInteger("container_id")<>123 OR contextValue:GetCharacter("operation")<>"update" OR NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid delegated fiscal context",1).
 fiscalCalls=fiscalCalls + 1. responseValue=NEW JsonObject(). responseValue:Add("success",TRUE). responseValue:Add("changes",NEW JsonArray()). responseValue:Add("warnings",NEW JsonArray()).
END PROCEDURE.
{ContainersVersionRuntimeFixture.i}
PROCEDURE NextItemCustoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Test provider outside transaction",1).
 valueId=2501.
END PROCEDURE.

