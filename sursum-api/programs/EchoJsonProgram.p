USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

ASSIGN poResponse = NEW JsonObject().
poResponse:Add("success", TRUE).
poResponse:Add("program", "echo-json").

IF VALID-OBJECT(poRequest) THEN
    poResponse:Add("parameters", poRequest).
