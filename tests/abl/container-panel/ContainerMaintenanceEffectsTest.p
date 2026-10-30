/* Independent JSON protocol vectors. No DB, sequences or business records. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE effects AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE image AS JsonObject NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
DEFINE VARIABLE skipName AS CHARACTER NO-UNDO.
DEFINE VARIABLE skipId AS INTEGER NO-UNDO.
{sursum-api/includes/ContainerTransactionAudit.i}
{sursum-api/includes/ContainerMaintenanceEffects.i}
RUN Fixture. RUN Invoke.
RUN Check(NOT rejected AND changes:Length=0 AND warnings:Length=0,"empty effects normalize to empty outputs").
DO n=1 TO 23:
 RUN Fixture. RUN Event("create",1,0,1).
 rowValue=effects:GetJsonArray("changes"):GetJsonObject(1).
 CASE n:
  WHEN 1 THEN rowValue:Remove("recordId").
  WHEN 2 THEN rowValue:Remove("operation").
  WHEN 3 THEN rowValue:Set("recordId","1").
  WHEN 4 THEN rowValue:Set("recordId",1.5).
  WHEN 5 THEN rowValue:Set("resource","DESPESAS_CONTAINER").
  WHEN 6 THEN rowValue:Set("operation","CREATE").
  WHEN 7 THEN rowValue:GetJsonObject("after"):Set("despesa_container_id",2).
  WHEN 8 THEN rowValue:GetJsonObject("after"):Set("container_id",999).
  WHEN 9 THEN rowValue:GetJsonObject("after"):Add("nested",NEW JsonObject()).
  WHEN 10 THEN rowValue:GetJsonObject("after"):Add("nested",NEW JsonArray()).
  WHEN 11 THEN rowValue:Set("after",NEW JsonObject()).
  WHEN 12 THEN rowValue:Set("before",CAST(rowValue:GetJsonObject("after"):Clone(),JsonObject)).
  WHEN 13 THEN rowValue:Add("Operation","create").
  WHEN 14 THEN rowValue:GetJsonObject("after"):Set("container_id","123").
  WHEN 15 THEN effects:Set("success","true").
  WHEN 16 THEN effects:Add("audit",NEW JsonObject()).
  WHEN 17 THEN DO: warnings=NEW JsonArray(). warnings:Add(2). effects:Add("warnings",warnings). END.
  WHEN 18 THEN DO: warnings=NEW JsonArray(). warnings:Add(FILL("x",4001)). effects:Add("warnings",warnings). END.
  WHEN 19 THEN rowValue:Set("before",NEW JsonArray()).
  WHEN 20 THEN rowValue:GetJsonObject("after"):SetNull("despesa_container_id").
  WHEN 21 THEN rowValue:Set("recordId",DECIMAL(1)).
  WHEN 22 THEN rowValue:GetJsonObject("after"):Set("despesa_container_id",DECIMAL(1)).
  WHEN 23 THEN rowValue:GetJsonObject("after"):Set("container_id",DECIMAL(123)).
 END CASE.
 RUN Invoke. RUN Check(rejected,"malformed independent vector " + STRING(n)).
END.
RUN Fixture. RUN Event("update",1,10,20). RUN Event("update",1,20,30). RUN Invoke.
RUN Check(NOT rejected AND changes:Length=1,"two updates coalesce one identity").
RUN Check(changes:GetJsonObject(1):GetJsonObject("before"):GetInteger("valor")=10 AND changes:GetJsonObject(1):GetJsonObject("after"):GetInteger("valor")=30,"coalesce preserves first before and last after").
RUN Fixture. RUN Event("create",1,0,20). RUN Event("update",1,20,30). RUN Invoke.
RUN Check(NOT rejected AND changes:GetJsonObject(1):GetCharacter("operation")="create","create plus update stays create").
RUN Check(changes:GetJsonObject(1):GetJsonObject("after"):GetType("despesa_container_id")=JsonDataType:NUMBER AND changes:GetJsonObject(1):GetJsonObject("after"):GetJsonText("despesa_container_id")="1","coalescing keeps integer JSON PK token").
RUN Fixture. RUN Event("update",1,10,20). RUN Event("delete",1,20,0). RUN Invoke.
RUN Check(NOT rejected AND changes:GetJsonObject(1):GetCharacter("operation")="delete","update then delete keeps original before and empty after").
RUN Fixture. RUN Event("create",1,0,20). RUN Event("create",1,0,20). RUN Invoke.
RUN Check(NOT rejected AND changes:Length=1,"duplicate event is one audited identity").
RUN Fixture. RUN Event("create",1,0,20). RUN Event("delete",1,20,0). RUN Invoke.
RUN Check(rejected,"net empty coalesced lifecycle cannot emit invalid create envelope").
RUN Fixture. RUN Event("update",1,10,20).
rowValue=effects:GetJsonArray("changes"):GetJsonObject(1). rowValue:Set("resource","containers"). rowValue:Set("recordId",123).
rowValue:GetJsonObject("before"):Remove("despesa_container_id"). rowValue:GetJsonObject("after"):Remove("despesa_container_id"). RUN Invoke.
RUN Check(NOT rejected AND changes:Length=0,"verified container event skipped for root full snapshot").
rowValue:Set("recordId",999). RUN Invoke. RUN Check(rejected,"skip container still validates master identity").
RUN Fixture. RUN Event("update",1,10,20).
rowValue=effects:GetJsonArray("changes"):GetJsonObject(1). rowValue:Set("resource","itens_container").
rowValue:GetJsonObject("before"):Remove("despesa_container_id"). rowValue:GetJsonObject("after"):Remove("despesa_container_id").
rowValue:GetJsonObject("before"):Add("item_container_id",1). rowValue:GetJsonObject("after"):Add("item_container_id",1).
ASSIGN skipName="itens_container" skipId=1. RUN Invoke. RUN Check(NOT rejected AND changes:Length=0,"main item event skipped after full validation").
rowValue:GetJsonObject("after"):Set("container_id",999). RUN Invoke. RUN Check(rejected,"skip item cannot hide cross-container snapshot").
RUN Fixture. RUN Event("create",1,0,20).
rowValue=effects:GetJsonArray("changes"):GetJsonObject(1). rowValue:Set("resource","cta_corren_fornec_imp").
rowValue:GetJsonObject("after"):Remove("despesa_container_id"). rowValue:GetJsonObject("after"):Add("cta_corren_fornec_imp_id",1).
rowValue:GetJsonObject("after"):Add("item_container_id",999). rowValue:GetJsonObject("after"):Add("item_proc_compra_id",999).
RUN Invoke. RUN Check(NOT rejected,"ledger CID is execution origin; external historical item is preserved").
RUN Fixture. warnings=NEW JsonArray(). DO n=1 TO 1001: warnings:Add("warning"). END. effects:Add("warnings",warnings).
RUN Invoke. RUN Check(rejected,"warning count bounded").
OUTPUT TO VALUE("container-maintenance-effects-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks; JSON only." SKIP. OUTPUT CLOSE.
PROCEDURE Fixture:
 effects=NEW JsonObject(). effects:Add("success",TRUE). effects:Add("changes",NEW JsonArray()).
 skipName="". skipId=0.
END PROCEDURE.
PROCEDURE Event:
 DEFINE INPUT PARAMETER actionName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER keyId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER beforeAmount AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER afterAmount AS INTEGER NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE beforeImage AS JsonObject NO-UNDO.
 DEFINE VARIABLE afterImage AS JsonObject NO-UNDO.
 eventValue=NEW JsonObject(). eventValue:Add("resource","despesas_container"). eventValue:Add("operation",actionName). eventValue:Add("recordId",keyId).
 beforeImage=NEW JsonObject(). afterImage=NEW JsonObject().
 IF actionName<>"create" THEN DO: beforeImage:Add("container_id",123). beforeImage:Add("despesa_container_id",keyId). beforeImage:Add("valor",beforeAmount). END.
 IF actionName<>"delete" THEN DO: afterImage:Add("container_id",123). afterImage:Add("despesa_container_id",keyId). afterImage:Add("valor",afterAmount). END.
 eventValue:Add("before",beforeImage). eventValue:Add("after",afterImage). effects:GetJsonArray("changes"):Add(eventValue).
END PROCEDURE.
PROCEDURE Invoke:
 rejected=FALSE. changes=?. warnings=?.
 DO ON ERROR UNDO, THROW:
  RUN MaintenanceValidateEffects(effects,123,"itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp",skipName,skipId,OUTPUT changes,OUTPUT warnings).
  CATCH e AS Progress.Lang.Error: rejected=TRUE. END CATCH.
 END.
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + messageValue,1).
END PROCEDURE.
