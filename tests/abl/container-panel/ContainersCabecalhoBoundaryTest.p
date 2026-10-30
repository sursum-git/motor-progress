/* Batch has no WEB-CONTEXT credential. Must reject before opening buffers or
   allocating a sequence. Never invokes a business write. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE actionName AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
OUTPUT TO VALUE("containers-cabecalho-boundary-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO n=1 TO 4:
 actionName=ENTRY(n,"create,update,delete,get").
 request=NEW JsonObject(). request:Add("operation",actionName). request:Add("resource","containers").
 RUN ContainersCabecalhoCrud.p(request,OUTPUT response).
 IF response:GetLogical("success") OR response:GetJsonObject("error"):GetInteger("status")<>401 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL authentication boundary",0).
 DELETE OBJECT request. DELETE OBJECT response.
END.
PUT UNFORMATTED "PASS: 4 checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
OUTPUT CLOSE.
