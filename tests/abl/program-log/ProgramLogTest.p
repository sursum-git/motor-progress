USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE ctx AS PasoeExecutionContext NO-UNDO.
DEFINE VARIABLE other AS PasoeExecutionContext NO-UNDO.
DEFINE VARIABLE repo AS ApiExecutionRepository NO-UNDO.
DEFINE VARIABLE logs AS JsonArray NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE ok AS LOGICAL NO-UNDO.
DEFINE TEMP-TABLE ttBusiness FIELD businessValue AS INTEGER.
OUTPUT TO "program-log-tests.log".
ctx = NEW PasoeExecutionContext().
other = NEW PasoeExecutionContext().
repo = NEW ApiExecutionRepository().
PasoeExecutionContext:clearCurrent().
RUN Check(NOT repo:logMessage("info","Sem request"),"Sem contexto retorna false").
PasoeExecutionContext:setCurrent(ctx).
RUN Check(NOT repo:logMessage("info","Sem execucao"),"Sem executionId retorna false").
ctx:setCustomField("executionId","EXE-UNIT-TEST").
RUN Check(repo:logMessage("INFO","Mensagem ação"),"Registro INFO case insensitive").
RUN Check(NOT repo:logMessage("invalid","Não registrar"),"Nivel invalido recusado").
RUN Check(NOT repo:logMessage("warning",?),"Mensagem desconhecida recusada").
RUN Check(NOT repo:logMessage("info",FILL("x",4001)),"Mensagem longa recusada sem truncar JSON").
ctx:setCustomField("executionId",?).
RUN Check(NOT repo:logMessage("info","ID desconhecido"),"ExecutionId desconhecido recusado").
ctx:setCustomField("executionId","EXE-UNIT-TEST").
DO TRANSACTION ON ERROR UNDO, LEAVE:
 CREATE ttBusiness. ttBusiness.businessValue = 9.
 ok = repo:logMessage("warning","Antes do rollback").
 UNDO, LEAVE.
END.
RUN Check(NOT CAN-FIND(FIRST ttBusiness),"Rollback negocio confirmado").
logs = ctx:getLogMessages().
RUN Check(logs:Length = 2,"Logs sobrevivem ao rollback").
RUN Check(logs:GetJsonObject(1):GetCharacter("level")="info","Nivel normalizado").
RUN Check(logs:GetJsonObject(1):GetCharacter("message")="Mensagem ação","Unicode preservado").
RUN Check(logs:GetJsonObject(2):GetCharacter("message")="Antes do rollback","Ordem preservada").
RUN Check(logs:GetJsonObject(2):Has("occurredAt"),"Instante original registrado").
logs:GetJsonObject(1):Set("message","Alterado na copia").
DELETE OBJECT logs.
logs=ctx:getLogMessages().
RUN Check(logs:GetJsonObject(1):GetCharacter("message")="Mensagem ação","Snapshot independente").
DELETE OBJECT logs.
DO TRANSACTION:
 CREATE ttBusiness. ttBusiness.businessValue=1.
 RUN Check(NOT repo:flushLogMessages(ctx),"Nao grava dentro da transacao negocio").
END.
RUN Check(NOT repo:flushLogMessages(ctx),"Banco ausente nao finge persistencia").
logs=ctx:getLogMessages(). RUN Check(logs:Length=2,"Falha preserva fila"). DELETE OBJECT logs.
PasoeExecutionContext:clearCurrent().
RUN Check(NOT VALID-OBJECT(PasoeExecutionContext:Current),"Contexto limpo").
RUN Check(NOT repo:logMessage("error","Outra request"),"Sem vazamento entre requests").
other:setCustomField("executionId","EXE-UNIT-OTHER").
PasoeExecutionContext:setCurrent(other).
logs=other:getLogMessages(). RUN Check(logs:Length=0,"Segunda request sem logs antigos"). DELETE OBJECT logs.
RUN Check(repo:logMessage("debug","Segunda request"),"Log segunda request").
ctx:clearLogMessages(). logs=ctx:getLogMessages(). RUN Check(logs:Length=0,"Limpeza explicita"). DELETE OBJECT logs.
RUN Check(repo:flushLogMessages(ctx),"Fila vazia nao exige banco").
PasoeExecutionContext:clearCurrent().
DELETE OBJECT ctx. DELETE OBJECT other. DELETE OBJECT repo.
PUT UNFORMATTED "PASS: " checks " verificacoes de log transacional" SKIP.
OUTPUT CLOSE.
QUIT.
PROCEDURE Check:
 DEFINE INPUT PARAMETER condition AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
 checks = checks + 1.
 IF condition <> TRUE OR condition=? THEN DO:
  PUT UNFORMATTED "FAIL: " pcMessage SKIP. OUTPUT CLOSE. QUIT.
 END.
END PROCEDURE.


