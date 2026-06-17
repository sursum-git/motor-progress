/*
Entrada APSV/PASOE para consultar status de job dentro do agente PASOE.
*/

USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT  PARAMETER pcJobId AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcResultJson AS LONGCHAR NO-UNDO.

DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
DEFINE VARIABLE joRet  AS JsonObject NO-UNDO.

ASSIGN oAsync = NEW DynamicQueryAsyncService().
ASSIGN joRet = oAsync:getStatus(pcJobId).

joRet:Write(pcResultJson, TRUE).

DELETE OBJECT joRet NO-ERROR.
DELETE OBJECT oAsync NO-ERROR.
