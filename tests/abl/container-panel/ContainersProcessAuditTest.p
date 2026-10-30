BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
DEFINE VARIABLE incoming AS JsonArray NO-UNDO.
DEFINE VARIABLE resultValue AS JsonArray NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
{sursum-api/includes/ContainerTransactionAudit.i}
parser=NEW ObjectModelParser().
incoming=CAST(parser:Parse('[~{"resource":"item_container_custos","operation":"create","recordId":7,"before":~{},"after":~{"item_container_custo_id":7,"versao_id":1,"vl_unit_prev":13,"vl_custo_distribuido":0}},~{"resource":"item_container_custos","operation":"update","recordId":7,"before":~{"item_container_custo_id":7,"versao_id":1,"vl_custo_distribuido":0},"after":~{"item_container_custo_id":7,"versao_id":1,"vl_custo_distribuido":30}}]'),JsonArray).
RUN ProcessMergeEvents(incoming,123,INPUT-OUTPUT resultValue).
RUN Check(resultValue:Length=1,"same physical item coalesced").
eventValue=resultValue:GetJsonObject(1).
RUN Check(eventValue:GetJsonObject("after"):Has("vl_unit_prev"),"distribution delta retains full created snapshot").
RUN Check(eventValue:GetJsonObject("after"):GetDecimal("vl_unit_prev")=13 AND eventValue:GetJsonObject("after"):GetDecimal("vl_custo_distribuido")=30,"full actual final values composed").
RUN Check(eventValue:GetCharacter("operation")="create","create then distribution update stays create").
RUN Check(eventValue:GetJsonObject("after"):GetInteger("container_id")=123,"physical child enriched with trusted parent").
incoming:GetJsonObject(2):GetJsonObject("after"):Add("container_id",999).
DO ON ERROR UNDO, THROW: RUN ProcessMergeEvents(incoming,123,INPUT-OUTPUT resultValue). CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH. END.
RUN Check(rejected,"foreign child fails before commit").
OUTPUT TO VALUE("containers-process-audit-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks" SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER textValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + textValue + " " + STRING(resultValue:GetJsonText()),1).
 checks=checks + 1.
END PROCEDURE.
