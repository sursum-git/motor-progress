/* Missing integration credential must reject before a connection or sequence. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE programValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DO n=1 TO 3:
 programValue=ENTRY(n,"ContainersCabecalhoCrud.r,ContainersDespesasCrud.r,ContainersProcessos.r").
 requestValue=NEW JsonObject(). requestValue:Add("resource",IF n=1 THEN "containers" ELSE IF n=2 THEN "container-despesas" ELSE "versoes").
 requestValue:Add("operation",IF n=3 THEN "gerar" ELSE "update"). requestValue:Add("container_id",123).
 RUN VALUE(programValue)(requestValue,OUTPUT responseValue).
 IF responseValue:GetLogical("success") OR responseValue:Has("audit") OR responseValue:GetJsonObject("error"):GetInteger("status")<>401 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL credential boundary " + programValue,1).
 checks=checks + 1. DELETE OBJECT requestValue. DELETE OBJECT responseValue.
END.
OUTPUT TO VALUE("containers-public-boundary-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; unauthenticated, no business." SKIP. OUTPUT CLOSE.
