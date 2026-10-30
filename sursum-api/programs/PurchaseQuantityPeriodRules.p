/* Legacy predicates, including the explicitly preserved asymmetric end bound.
   Pure: no database, clock, locks or session cache. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRow AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poPeriods AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER piDays AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poResult AS JsonObject NO-UNDO.
DEFINE VARIABLE registration AS DATE NO-UNDO.
DEFINE VARIABLE received AS DATE NO-UNDO.
DEFINE VARIABLE arrival AS DATE NO-UNDO.
DEFINE VARIABLE actualEnd AS DATE NO-UNDO.
DEFINE VARIABLE plannedEnd AS DATE NO-UNDO.
DEFINE VARIABLE maximumEnd AS DATE NO-UNDO.
DEFINE VARIABLE orderBranch AS LOGICAL NO-UNDO.
DEFINE VARIABLE containerBranch AS LOGICAL NO-UNDO.
DEFINE VARIABLE registrationMatches AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE periodValue AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseQuantityPeriodDates.i}
FUNCTION InRange RETURNS LOGICAL(d AS DATE,p AS JsonObject):
 IF d=? THEN RETURN FALSE.
 RETURN d>=PurchasePeriodDate(p,'start') AND d<=PurchasePeriodDate(p,'end').
END FUNCTION.
FUNCTION ProductionInRange RETURNS LOGICAL(d AS DATE,p AS JsonObject):
 IF d=? THEN RETURN FALSE.
 /* Do not add piDays to the upper comparison: user preserved Scriptcase. */
 RETURN d + piDays>=PurchasePeriodDate(p,'start') AND d<=PurchasePeriodDate(p,'end').
END FUNCTION.
ASSIGN registration=PurchasePeriodDate(poRow,'dt_registro') received=PurchasePeriodDate(poRow,'dt_recebimento')
 arrival=PurchasePeriodDate(poRow,'dt_prev_chegada') actualEnd=PurchasePeriodDate(poRow,'dt_termino_producao')
 plannedEnd=PurchasePeriodDate(poRow,'dt_prev_termino_producao') maximumEnd=PurchasePeriodDate(poRow,'dt_maxima_producao').
orderBranch=NOT poPeriods:Has('dt_recebimento'). containerBranch=TRUE.
IF poPeriods:Has('dt_prev_chegada') THEN DO:
 periodValue=poPeriods:GetJsonObject('dt_prev_chegada').
 orderBranch=orderBranch AND (ProductionInRange(actualEnd,periodValue) OR ProductionInRange(plannedEnd,periodValue)).
 containerBranch=InRange(arrival,periodValue).
END.
IF poPeriods:Has('dt_recebimento') THEN containerBranch=containerBranch AND InRange(received,poPeriods:GetJsonObject('dt_recebimento')).
poResult=NEW JsonObject().
IF poPeriods:Has('dt_registro') THEN registrationMatches=InRange(registration,poPeriods:GetJsonObject('dt_registro')).
poResult:Add('admitted',(orderBranch OR containerBranch) AND registrationMatches).
/* The display fallback is a separate source rule, not the parameter above. */
IF arrival=? AND maximumEnd<>? THEN arrival=maximumEnd + 30.
IF arrival=? THEN poResult:AddNull('dt_prev_chegada'). ELSE poResult:Add('dt_prev_chegada',ISO-DATE(arrival)).
