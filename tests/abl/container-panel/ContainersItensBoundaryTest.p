/* No authenticated WEB-CONTEXT: reject before fixed buffers or sequences. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
OUTPUT TO VALUE("containers-itens-boundary-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO n=1 TO 5:
 request=NEW JsonObject(). request:Add("resource",IF n=5 THEN "itens-disponiveis" ELSE "container-itens").
 request:Add("operation",ENTRY(n,"create,update,delete,get,read")).
 request:Add("actor","forged"). request:Add("container_id",332526).
 RUN ContainersItensCrud.p(request,OUTPUT response).
 IF response:GetLogical("success") OR response:GetJsonObject("error"):GetInteger("status")<>401 THEN
  UNDO, THROW NEW Progress.Lang.AppError("FAIL authenticated item boundary",1).
 DELETE OBJECT request. DELETE OBJECT response.
END.
PUT UNFORMATTED "PASS: 5 checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
OUTPUT CLOSE.
