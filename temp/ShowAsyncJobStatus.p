/*
Mostra status do ultimo job async gerado por RunAsyncCustomerQueue.p.
*/

USING Progress.Json.ObjectModel.JsonObject.

PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\rest,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress," + PROPATH.

DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
DEFINE VARIABLE joRet  AS JsonObject NO-UNDO.
DEFINE VARIABLE cJobId AS CHARACTER NO-UNDO.

INPUT FROM VALUE("D:\opencode\motor-progress\temp\last_async_job.txt").
IMPORT UNFORMATTED cJobId.
INPUT CLOSE.

ASSIGN oAsync = NEW DynamicQueryAsyncService().
ASSIGN joRet = oAsync:getStatus(cJobId).

IF joRet:GetLogical("success") THEN DO:
    MESSAGE "ASYNC_JOB_ID=" + joRet:GetCharacter("jobId").
    MESSAGE "ASYNC_STATUS=" + joRet:GetCharacter("status").
    MESSAGE "ASYNC_MODE=" + joRet:GetCharacter("lockedByMode").
    MESSAGE "ASYNC_WORKER=" + joRet:GetCharacter("lockedByWorker").
    MESSAGE "ASYNC_RECORDS=" + STRING(joRet:GetInteger("recordsReturned")).
    MESSAGE "ASYNC_RESULT_PATH=" + joRet:GetCharacter("resultPath").
    MESSAGE "ASYNC_ERROR_CODE=" + joRet:GetJsonObject("error"):GetCharacter("code").
    MESSAGE "ASYNC_ERROR_MESSAGE=" + joRet:GetJsonObject("error"):GetCharacter("message").
    MESSAGE "ASYNC_ERROR_DETAIL=" + joRet:GetJsonObject("error"):GetCharacter("details").
END.
ELSE DO:
    MESSAGE "ASYNC_STATUS_SUCCESS=no".
    MESSAGE joRet:GetJsonObject("error"):GetCharacter("code").
    MESSAGE joRet:GetJsonObject("error"):GetCharacter("message").
    MESSAGE joRet:GetJsonObject("error"):GetCharacter("details").
END.

DELETE OBJECT joRet NO-ERROR.
DELETE OBJECT oAsync NO-ERROR.

QUIT.
