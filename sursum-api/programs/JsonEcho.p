USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

/* Example: return exactly the input. Business programs implement their own logic. */
poResponse = poRequest.
