/*
Entrada APSV/PASOE para processar jobs pendentes dentro do agente PASOE.
Nao usar QUIT aqui: este programa roda remoto em sessao PASOE.
*/

USING Progress.Json.ObjectModel.JsonObject.

DEFINE OUTPUT PARAMETER pcResultJson AS LONGCHAR NO-UNDO.

DEFINE VARIABLE oOptions AS DynamicQueryWorkerOptions NO-UNDO.
DEFINE VARIABLE oWorker  AS DynamicQueryWorkerService NO-UNDO.
DEFINE VARIABLE joRet    AS JsonObject NO-UNDO.

ASSIGN oOptions = NEW DynamicQueryWorkerOptions()
       oWorker  = NEW DynamicQueryWorkerService().

oOptions:setExecutionMode("PASOE").
oOptions:setWorkerName("pasoe-apsv-worker").
oOptions:setBatchSize(10).
oOptions:setOutputDirectory("D:\opencode\motor-progress\output\jobs").

ASSIGN joRet = oWorker:drain(oOptions).
joRet:Write(pcResultJson, TRUE).

DELETE OBJECT joRet NO-ERROR.
DELETE OBJECT oWorker NO-ERROR.
DELETE OBJECT oOptions NO-ERROR.
