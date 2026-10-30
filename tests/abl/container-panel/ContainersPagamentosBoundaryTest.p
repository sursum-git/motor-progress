/* Unauthenticated callers never reach database handles or mutation code. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DO n=1 TO 4:
 requestValue=NEW JsonObject(). requestValue:Add("operation",ENTRY(n,"create,delete,read,update")).
 requestValue:Add("resource",IF n=3 THEN "pagamentos-disponiveis" ELSE "container-pagamentos").
 requestValue:Add("container_id",123).
 RUN ContainersPagamentosCrud.p(requestValue,OUTPUT responseValue).
 IF responseValue:GetLogical("success") OR responseValue:GetJsonObject("error"):GetInteger("status")<>401 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL unauthenticated payment boundary",1).
END.
OUTPUT TO VALUE("containers-pagamentos-boundary-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS 4 checks; no authenticated business execution." SKIP. OUTPUT CLOSE.
