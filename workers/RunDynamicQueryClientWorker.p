/*
Worker CLIENT/batch para processar a fila assincrona.
*/

USING Progress.Json.ObjectModel.JsonObject.

PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\rest,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress," + PROPATH.

DEFINE VARIABLE oOptions AS DynamicQueryWorkerOptions NO-UNDO.
DEFINE VARIABLE oWorker  AS DynamicQueryWorkerService NO-UNDO.
DEFINE VARIABLE joRet    AS JsonObject NO-UNDO.

ASSIGN oOptions = NEW DynamicQueryWorkerOptions()
       oWorker  = NEW DynamicQueryWorkerService().

oOptions:setExecutionMode("CLIENT").
oOptions:setWorkerName("client-batch-worker").
oOptions:setBatchSize(10).
oOptions:setOutputDirectory("D:\opencode\motor-progress\output\jobs").

ASSIGN joRet = oWorker:drain(oOptions).

MESSAGE "WORKER_MODE=" + joRet:GetCharacter("workerMode").
MESSAGE "WORKER_PROCESSED=" + STRING(joRet:GetInteger("processed")).
MESSAGE "WORKER_COMPLETED=" + STRING(joRet:GetInteger("completed")).
MESSAGE "WORKER_FAILED=" + STRING(joRet:GetInteger("failed")).

DELETE OBJECT joRet NO-ERROR.
DELETE OBJECT oWorker NO-ERROR.
DELETE OBJECT oOptions NO-ERROR.

QUIT.
