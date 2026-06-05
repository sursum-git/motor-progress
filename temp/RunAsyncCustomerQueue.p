/*
Enfileira uma consulta async simples da tabela Customer.
Grava o jobId em temp/last_async_job.txt para os passos seguintes.
*/

USING Progress.Json.ObjectModel.JsonObject.

PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\rest,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress," + PROPATH.

DEFINE VARIABLE oSvc  AS DynamicMultiTableQueryService NO-UNDO.
DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
DEFINE VARIABLE cJobId AS CHARACTER NO-UNDO.

ASSIGN oSvc = NEW DynamicMultiTableQueryService().

ASSIGN joRet = oSvc:executeSingleTable(
    "Customer",
    "CustNum,Name,City,State",
    "DICTDB",
    1,
    25,
    "async"
).

IF joRet:GetLogical("success") THEN DO:
    ASSIGN cJobId = joRet:GetCharacter("jobId").
    OUTPUT TO VALUE("D:\opencode\motor-progress\temp\last_async_job.txt").
    PUT UNFORMATTED cJobId SKIP.
    OUTPUT CLOSE.
    MESSAGE "ASYNC_QUEUE_SUCCESS=yes".
    MESSAGE "ASYNC_JOB_ID=" + cJobId.
    MESSAGE "ASYNC_STATUS=" + joRet:GetCharacter("status").
END.
ELSE DO:
    MESSAGE "ASYNC_QUEUE_SUCCESS=no".
    MESSAGE joRet:GetJsonObject("error"):GetCharacter("code").
    MESSAGE joRet:GetJsonObject("error"):GetCharacter("message").
    MESSAGE joRet:GetJsonObject("error"):GetCharacter("details").
END.

DELETE OBJECT joRet NO-ERROR.
DELETE OBJECT oSvc NO-ERROR.

QUIT.
