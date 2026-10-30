BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE requestData AS JsonObject NO-UNDO.
DEFINE VARIABLE responseData AS JsonObject NO-UNDO.
requestData=NEW JsonObject().
requestData:Add("operation","read"). requestData:Add("resource","resumo").
RUN IolInicialGerencial.p(requestData,OUTPUT responseData).
IF responseData:GetLogical("success") OR responseData:GetJsonObject("error"):GetInteger("status")<>401 THEN
 UNDO, THROW NEW Progress.Lang.AppError("FAIL boundary authentication",1).
OUTPUT TO VALUE("boundary-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS boundary unauthenticated=401" SKIP.
OUTPUT CLOSE.
requestData=NEW JsonObject().
requestData:Add("operation","read"). requestData:Add("resource","painel").
RUN IolInicialGerencial.p(requestData,OUTPUT responseData).
IF responseData:GetLogical("success") OR responseData:GetJsonObject("error"):GetInteger("status")<>401 THEN
 UNDO, THROW NEW Progress.Lang.AppError("FAIL grouped boundary authentication",1).
