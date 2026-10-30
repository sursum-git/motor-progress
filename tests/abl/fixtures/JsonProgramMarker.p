USING Progress.Json.ObjectModel.JsonObject.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
OUTPUT TO "temp/json-router-invoked.txt" APPEND.
PUT UNFORMATTED "called" SKIP.
OUTPUT CLOSE.
/* Return the same object to verify ownership and unchanged response semantics. */
poResponse = poRequest.
