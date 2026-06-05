USING Progress.Json.ObjectModel.JsonObject.

DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
DEFINE VARIABLE lcOut AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

COPY-LOB FROM FILE "D:\opencode\motor-progress\examples\customer-pipeline-advanced-request.json" TO lcJson.

ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
       oRequest = oSerializer:fromLongchar(lcJson)
       oService = NEW DynamicMultiTableQueryService()
       joRet = oService:executeSyncNow(oRequest).

joRet:Write(lcOut, TRUE).
COPY-LOB lcOut TO FILE "D:\opencode\motor-progress\examples\responses\customer-pipeline-advanced-client-response.json".

DELETE OBJECT joRet NO-ERROR.
DELETE OBJECT oService NO-ERROR.
DELETE OBJECT oRequest NO-ERROR.
DELETE OBJECT oSerializer NO-ERROR.
