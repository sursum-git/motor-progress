/*
Repositorio de execucoes/transacoes da API PASOE.
Usa buffers dinamicos para permitir compilacao antes do .df estar carregado.
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.

CLASS ApiExecutionRepository:

    /* Uso manual pelos programas: associa ao contexto confiavel da request. */
    METHOD PUBLIC LOGICAL logMessage(INPUT pcLevel AS CHARACTER, INPUT pcMessage AS CHARACTER):
        DEFINE VARIABLE context AS PasoeExecutionContext NO-UNDO.
        context = PasoeExecutionContext:Current.
        IF NOT VALID-OBJECT(context) THEN RETURN FALSE.
        RETURN context:queueLogMessage(pcLevel,pcMessage).
    END METHOD.

    /* Persistencia depois da transacao de negocio: a fila NO-UNDO sobrevive ao rollback. */
    METHOD PUBLIC LOGICAL flushLogMessages(INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE items AS JsonArray NO-UNDO.
        DEFINE VARIABLE item AS JsonObject NO-UNDO.
        DEFINE VARIABLE eventContext AS JsonObject NO-UNDO.
        DEFINE VARIABLE execution AS JsonObject NO-UNDO.
        DEFINE VARIABLE contextJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE executionId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE eventBuffer AS HANDLE NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poContext) OR TRANSACTION THEN RETURN FALSE.
        items = poContext:getLogMessages().
        IF items:Length = 0 THEN RETURN TRUE.
        executionId = poContext:getCustomField("executionId").
        IF executionId = "" OR NOT THIS-OBJECT:schemaAvailable() THEN RETURN FALSE.
        execution = THIS-OBJECT:getExecution(executionId).
        IF NOT execution:GetLogical("success") THEN RETURN FALSE.
        eventBuffer = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe_evento").
        IF NOT VALID-HANDLE(eventBuffer) THEN RETURN FALSE.
        DO TRANSACTION ON ERROR UNDO, THROW:
            DO i=1 TO items:Length:
                item = items:GetJsonObject(i).
                eventContext = poContext:toJson().
                eventContext:Add("programLog",CAST(item:Clone(),JsonObject)).
                eventContext:Write(contextJson).
                IF LENGTH(contextJson) > 30000 THEN
                    UNDO, THROW NEW Progress.Lang.AppError("Contexto de log excede o limite de persistencia",0).
                IF NOT eventBuffer:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao criar evento de log",0).
                THIS-OBJECT:setCharField(eventBuffer,"id_evento",THIS-OBJECT:createEventId(executionId)).
                THIS-OBJECT:setCharField(eventBuffer,"id_execucao",executionId).
                THIS-OBJECT:setCharField(eventBuffer,"status_evento","log." + item:GetCharacter("level")).
                THIS-OBJECT:setCharField(eventBuffer,"mensagem_evento",item:GetCharacter("message")).
                THIS-OBJECT:setLongcharField(eventBuffer,"contexto_evento_json",contextJson).
                THIS-OBJECT:setDateTimeField(eventBuffer,"data_hora_evento",item:GetDatetime("occurredAt")).
                IF NOT eventBuffer:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Evento de log recusado",0).
                eventBuffer:BUFFER-RELEASE().
                DELETE OBJECT eventContext.
            END.
        END.
        poContext:clearLogMessages().
        RETURN TRUE.
        CATCH error AS Progress.Lang.Error:
            RETURN FALSE.
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(eventBuffer) THEN DELETE OBJECT eventBuffer NO-ERROR.
            IF VALID-OBJECT(eventContext) THEN DELETE OBJECT eventContext NO-ERROR.
            IF VALID-OBJECT(execution) THEN DELETE OBJECT execution NO-ERROR.
            IF VALID-OBJECT(items) THEN DELETE OBJECT items NO-ERROR.
        END FINALLY.
    END METHOD.



    METHOD PUBLIC LOGICAL schemaAvailable():
        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.

        CREATE BUFFER hExecution FOR TABLE "espec.sursum_req_pasoe" NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hExecution) THEN
            RETURN FALSE.
        DELETE OBJECT hExecution NO-ERROR.

        CREATE BUFFER hExecution FOR TABLE "espec.sursum_req_pasoe_evento" NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hExecution) THEN
            RETURN FALSE.
        DELETE OBJECT hExecution NO-ERROR.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC JsonObject startExecution(
        INPUT poContext AS PasoeExecutionContext,
        INPUT pcExecutionType AS CHARACTER,
        INPUT pcEndpoint AS CHARACTER,
        INPUT pcStatus AS CHARACTER,
        INPUT pcRequestSummary AS CHARACTER):

        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE cExecutionId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cContextJson AS LONGCHAR NO-UNDO.

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cExecutionId = THIS-OBJECT:createExecutionId()
               cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        IF pcStatus = "" OR pcStatus = ? THEN
            ASSIGN pcStatus = "received".

        DO TRANSACTION:
            hExecution:BUFFER-CREATE().
            THIS-OBJECT:setCharField(hExecution, "id_execucao", cExecutionId).
            THIS-OBJECT:setCharField(hExecution, "id_requisicao", IF VALID-OBJECT(poContext) THEN poContext:getRequestId() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "status_execucao", pcStatus).
            THIS-OBJECT:setCharField(hExecution, "tipo_execucao", pcExecutionType).
            THIS-OBJECT:setCharField(hExecution, "rota_endpoint", pcEndpoint).
            THIS-OBJECT:setDateTimeField(hExecution, "data_hora_inicio", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hExecution, "dt_hr_ult_sinal", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hExecution, "pid_pasoe", IF VALID-OBJECT(poContext) THEN poContext:getPasoePid() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "agente_pasoe", IF VALID-OBJECT(poContext) THEN poContext:getPasoeAgent() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "instancia_pasoe", IF VALID-OBJECT(poContext) THEN poContext:getPasoeInstance() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "ref_trans_banco", IF VALID-OBJECT(poContext) THEN poContext:getDatabaseTransactionId() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "resumo_requisicao", pcRequestSummary).
            THIS-OBJECT:setLongcharField(hExecution, "ctx_req_json", cContextJson).
            THIS-OBJECT:applyContextCustomFields(hExecution, poContext).
            THIS-OBJECT:addEvent(cExecutionId, pcStatus, "Execucao registrada", cContextJson).
            hExecution:BUFFER-RELEASE().
        END.

        DELETE OBJECT hExecution NO-ERROR.
        RETURN THIS-OBJECT:getExecution(cExecutionId).
    END METHOD.

    METHOD PUBLIC JsonObject heartbeat(
        INPUT pcExecutionId AS CHARACTER,
        INPUT pcStatus AS CHARACTER,
        INPUT pcMessage AS CHARACTER,
        INPUT poContext AS PasoeExecutionContext):

        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE cContextJson AS LONGCHAR NO-UNDO.

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE id_execucao = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            IF pcStatus <> "" AND pcStatus <> ? THEN
                THIS-OBJECT:setCharField(hExecution, "status_execucao", pcStatus).
            THIS-OBJECT:setDateTimeField(hExecution, "dt_hr_ult_sinal", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setLongcharField(hExecution, "ctx_req_json", cContextJson).
            THIS-OBJECT:addEvent(pcExecutionId, IF pcStatus <> "" THEN pcStatus ELSE THIS-OBJECT:getCharField(hExecution, "status_execucao"), pcMessage, cContextJson).
            hExecution:BUFFER-RELEASE().
        END.
        DELETE OBJECT hExecution NO-ERROR.
        RETURN THIS-OBJECT:getExecution(pcExecutionId).
    END METHOD.

    METHOD PUBLIC JsonObject finishExecution(
        INPUT pcExecutionId AS CHARACTER,
        INPUT pcStatus AS CHARACTER,
        INPUT pcMessage AS CHARACTER,
        INPUT poContext AS PasoeExecutionContext):

        RETURN THIS-OBJECT:finishWithError(pcExecutionId, pcStatus, "", pcMessage, poContext).
    END METHOD.

    METHOD PUBLIC JsonObject failExecution(
        INPUT pcExecutionId AS CHARACTER,
        INPUT pcErrorCode AS CHARACTER,
        INPUT pcErrorMessage AS CHARACTER,
        INPUT poContext AS PasoeExecutionContext):

        RETURN THIS-OBJECT:finishWithError(pcExecutionId, "failed", pcErrorCode, pcErrorMessage, poContext).
    END METHOD.

    METHOD PUBLIC JsonObject requestKill(
        INPUT pcExecutionId AS CHARACTER,
        INPUT pcRequestedBy AS CHARACTER,
        INPUT pcReason AS CHARACTER,
        INPUT poContext AS PasoeExecutionContext):

        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE cContextJson AS LONGCHAR NO-UNDO.

        IF pcReason = "" OR pcReason = ? THEN
            RETURN THIS-OBJECT:buildError("KILL_REASON_REQUIRED", "Motivo obrigatorio para solicitar kill", pcExecutionId).

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE id_execucao = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            THIS-OBJECT:setCharField(hExecution, "status_execucao", "killRequested").
            THIS-OBJECT:setDateTimeField(hExecution, "dt_hr_ult_sinal", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hExecution, "dt_hr_solic_interrupcao", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hExecution, "usuario_solic_interrupcao", pcRequestedBy).
            THIS-OBJECT:setCharField(hExecution, "motivo_interrupcao", pcReason).
            THIS-OBJECT:addEvent(pcExecutionId, "killRequested", pcReason, cContextJson).
            hExecution:BUFFER-RELEASE().
        END.
        DELETE OBJECT hExecution NO-ERROR.
        RETURN THIS-OBJECT:getExecution(pcExecutionId).
    END METHOD.

    METHOD PUBLIC JsonObject listExecutions(INPUT pcStatus AS CHARACTER, INPUT pcPid AS CHARACTER, INPUT piLimit AS INTEGER):
        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLimit AS INTEGER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN iLimit = IF piLimit > 0 THEN MIN(piLimit, 500) ELSE 100
               cWhere = "FOR EACH espec.sursum_req_pasoe NO-LOCK".
        IF pcStatus <> "" AND pcStatus <> ? THEN
            ASSIGN cWhere = cWhere + " WHERE status_execucao = " + QUOTER(pcStatus).
        IF pcPid <> "" AND pcPid <> ? THEN
            ASSIGN cWhere = cWhere
                + (IF INDEX(cWhere, " WHERE ") > 0 THEN " AND " ELSE " WHERE ")
                + "pid_pasoe = " + QUOTER(pcPid).
        ASSIGN cWhere = cWhere + " BY data_hora_inicio DESC".

        CREATE QUERY hQuery.
        hQuery:ADD-BUFFER(hExecution).
        hQuery:QUERY-PREPARE(cWhere) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hExecution NO-ERROR.
            RETURN THIS-OBJECT:buildError("EXECUTION_QUERY_ERROR", "Falha ao preparar consulta de execucoes", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        ASSIGN jaData = NEW JsonArray().
        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN LEAVE.
            IF iCount >= iLimit THEN LEAVE.
            jaData:Add(THIS-OBJECT:bufferToJson(hExecution)).
            ASSIGN iCount = iCount + 1.
        END.
        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hExecution NO-ERROR.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("data", jaData).
        joRet:Add("recordsReturned", iCount).
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject listExecutionEvents(INPUT pcExecutionId AS CHARACTER, INPUT piLimit AS INTEGER):
        DEFINE VARIABLE hEvent AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLimit AS INTEGER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.

        IF pcExecutionId = "" OR pcExecutionId = ? THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_ID_REQUIRED", "ID da execucao obrigatorio", "GET /executions/id/events").

        ASSIGN hEvent = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe_evento").
        IF NOT VALID-HANDLE(hEvent) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de eventos de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN iLimit = IF piLimit > 0 THEN MIN(piLimit, 500) ELSE 200
               cQuery = "FOR EACH espec.sursum_req_pasoe_evento NO-LOCK WHERE id_execucao = "
                      + QUOTER(pcExecutionId)
                      + " BY data_hora_evento".

        CREATE QUERY hQuery.
        hQuery:ADD-BUFFER(hEvent).
        hQuery:QUERY-PREPARE(cQuery) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hEvent NO-ERROR.
            RETURN THIS-OBJECT:buildError("EXECUTION_EVENT_QUERY_ERROR", "Falha ao preparar consulta de eventos", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        ASSIGN jaData = NEW JsonArray().
        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN LEAVE.
            IF iCount >= iLimit THEN LEAVE.
            jaData:Add(THIS-OBJECT:eventBufferToJson(hEvent)).
            ASSIGN iCount = iCount + 1.
        END.
        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hEvent NO-ERROR.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("executionId", pcExecutionId).
        joRet:Add("data", jaData).
        joRet:Add("recordsReturned", iCount).
        RETURN joRet.
    END METHOD.
    METHOD PUBLIC JsonObject updateExecutionPayloads(INPUT pcExecutionId AS CHARACTER, INPUT pcRequestJson AS LONGCHAR, INPUT pcResponseJson AS LONGCHAR):
        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.

        IF pcExecutionId = "" OR pcExecutionId = ? THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_ID_REQUIRED", "ID da execucao obrigatorio", "updateExecutionPayloads").

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE id_execucao = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            IF pcRequestJson <> ? THEN
                THIS-OBJECT:setLongcharField(hExecution, "dados_envio_json", pcRequestJson).
            IF pcResponseJson <> ? THEN
                THIS-OBJECT:setLongcharField(hExecution, "dados_retorno_json", pcResponseJson).
            hExecution:BUFFER-RELEASE().
        END.
        DELETE OBJECT hExecution NO-ERROR.
        RETURN THIS-OBJECT:getExecution(pcExecutionId).
    END METHOD.
    METHOD PUBLIC JsonObject getExecution(INPUT pcExecutionId AS CHARACTER):
        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN lFound = hExecution:FIND-FIRST("WHERE id_execucao = " + QUOTER(pcExecutionId), NO-LOCK) NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
            DELETE OBJECT hExecution NO-ERROR.
            RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
        END.

        ASSIGN joRet = THIS-OBJECT:bufferToJson(hExecution).
        hExecution:BUFFER-RELEASE().
        DELETE OBJECT hExecution NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject finishWithError(
        INPUT pcExecutionId AS CHARACTER,
        INPUT pcStatus AS CHARACTER,
        INPUT pcErrorCode AS CHARACTER,
        INPUT pcMessage AS CHARACTER,
        INPUT poContext AS PasoeExecutionContext):

        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE cContextJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE dtStartedAt AS DATETIME NO-UNDO.
        DEFINE VARIABLE iDuration AS INTEGER NO-UNDO.

        ASSIGN hExecution = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE id_execucao = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            ASSIGN dtStartedAt = THIS-OBJECT:getDateTimeField(hExecution, "data_hora_inicio")
                   iDuration = IF dtStartedAt <> ? THEN INTERVAL(THIS-OBJECT:currentDateTime(), dtStartedAt, "milliseconds") ELSE 0.
            THIS-OBJECT:setCharField(hExecution, "status_execucao", pcStatus).
            THIS-OBJECT:setDateTimeField(hExecution, "dt_hr_ult_sinal", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hExecution, "data_hora_fim", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setIntField(hExecution, "duracao_ms", iDuration).
            THIS-OBJECT:setCharField(hExecution, "codigo_erro", pcErrorCode).
            THIS-OBJECT:setCharField(hExecution, "mensagem_erro", pcMessage).
            THIS-OBJECT:addEvent(pcExecutionId, pcStatus, pcMessage, cContextJson).
            hExecution:BUFFER-RELEASE().
        END.
        DELETE OBJECT hExecution NO-ERROR.
        RETURN THIS-OBJECT:getExecution(pcExecutionId).
    END METHOD.

    METHOD PRIVATE VOID applyContextCustomFields(INPUT phExecution AS HANDLE, INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE joContext AS JsonObject NO-UNDO.
        DEFINE VARIABLE joCustom AS JsonObject NO-UNDO.

        IF NOT VALID-OBJECT(poContext) THEN
            RETURN.
        ASSIGN joContext = poContext:toJson().
        IF VALID-OBJECT(joContext) THEN DO:
            THIS-OBJECT:setCharField(phExecution, "nome_host", THIS-OBJECT:getJsonChar(joContext, "hostName")).
            THIS-OBJECT:setCharField(phExecution, "nome_banco", THIS-OBJECT:getJsonChar(joContext, "databaseName")).
            THIS-OBJECT:setCharField(phExecution, "nome_usuario", THIS-OBJECT:getJsonChar(joContext, "currentUser")).
            THIS-OBJECT:setCharField(phExecution, "ip_requisitante", THIS-OBJECT:getJsonChar(joContext, "requesterIp")).
            THIS-OBJECT:setCharField(phExecution, "navegador_requisitante", THIS-OBJECT:getJsonChar(joContext, "requesterBrowser")).
            THIS-OBJECT:setCharField(phExecution, "id_sessao_requisitante", THIS-OBJECT:getJsonChar(joContext, "requesterSessionId")).
            IF joContext:Has("custom") AND NOT joContext:IsNull("custom") THEN
                ASSIGN joCustom = joContext:GetJsonObject("custom") NO-ERROR.
            IF VALID-OBJECT(joCustom) THEN DO:
                THIS-OBJECT:setCharField(phExecution, "ponto_entrada", THIS-OBJECT:getJsonChar(joCustom, "entrypoint")).
                THIS-OBJECT:setCharField(phExecution, "id_empresa", THIS-OBJECT:getJsonChar(joCustom, "companyId")).
                THIS-OBJECT:setCharField(phExecution, "nome_aplicacao", THIS-OBJECT:getJsonChar(joCustom, "applicationName")).
                THIS-OBJECT:setCharField(phExecution, "codigo_acao", THIS-OBJECT:getJsonChar(joCustom, "actionCode")).
                THIS-OBJECT:setCharField(phExecution, "nome_programa", THIS-OBJECT:getJsonChar(joCustom, "programName")).
                THIS-OBJECT:setCharField(phExecution, "codigo_consulta", THIS-OBJECT:getJsonChar(joCustom, "queryCode")).
                THIS-OBJECT:setCharField(phExecution, "id_tarefa", THIS-OBJECT:getJsonChar(joCustom, "jobId")).
                THIS-OBJECT:setCharField(phExecution, "tipo_autenticacao", THIS-OBJECT:getJsonChar(joCustom, "authType")).
            END.
        END.
        DELETE OBJECT joContext NO-ERROR.
    END METHOD.

    METHOD PRIVATE HANDLE createBuffer(INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
        CREATE BUFFER hBuffer FOR TABLE pcTable NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hBuffer) THEN
            RETURN ?.
        RETURN hBuffer.
    END METHOD.

    METHOD PRIVATE VOID addEvent(INPUT pcExecutionId AS CHARACTER, INPUT pcStatus AS CHARACTER, INPUT pcMessage AS CHARACTER, INPUT pcContextJson AS LONGCHAR):
        DEFINE VARIABLE hEvent AS HANDLE NO-UNDO.

        ASSIGN hEvent = THIS-OBJECT:createBuffer("espec.sursum_req_pasoe_evento").
        IF NOT VALID-HANDLE(hEvent) THEN
            RETURN.

        hEvent:BUFFER-CREATE().
        THIS-OBJECT:setCharField(hEvent, "id_evento", THIS-OBJECT:createEventId(pcExecutionId)).
        THIS-OBJECT:setCharField(hEvent, "id_execucao", pcExecutionId).
        THIS-OBJECT:setCharField(hEvent, "status_evento", pcStatus).
        THIS-OBJECT:setCharField(hEvent, "mensagem_evento", pcMessage).
        THIS-OBJECT:setLongcharField(hEvent, "contexto_evento_json", pcContextJson).
        THIS-OBJECT:setDateTimeField(hEvent, "data_hora_evento", THIS-OBJECT:currentDateTime()).
        hEvent:BUFFER-RELEASE().
        DELETE OBJECT hEvent NO-ERROR.
    END METHOD.

    METHOD PRIVATE JsonObject bufferToJson(INPUT phExecution AS HANDLE):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("executionId", THIS-OBJECT:getCharField(phExecution, "id_execucao")).
        joRet:Add("requestId", THIS-OBJECT:getCharField(phExecution, "id_requisicao")).
        joRet:Add("status", THIS-OBJECT:getCharField(phExecution, "status_execucao")).
        joRet:Add("executionStatus", THIS-OBJECT:getCharField(phExecution, "status_execucao")).
        joRet:Add("executionType", THIS-OBJECT:getCharField(phExecution, "tipo_execucao")).
        joRet:Add("entrypoint", THIS-OBJECT:getCharField(phExecution, "ponto_entrada")).
        joRet:Add("endpoint", THIS-OBJECT:getCharField(phExecution, "rota_endpoint")).
        joRet:Add("actionCode", THIS-OBJECT:getCharField(phExecution, "codigo_acao")).
        joRet:Add("programName", THIS-OBJECT:getCharField(phExecution, "nome_programa")).
        joRet:Add("queryCode", THIS-OBJECT:getCharField(phExecution, "codigo_consulta")).
        joRet:Add("jobId", THIS-OBJECT:getCharField(phExecution, "id_tarefa")).
        joRet:Add("startedAt", THIS-OBJECT:getCharField(phExecution, "data_hora_inicio")).
        joRet:Add("lastHeartbeatAt", THIS-OBJECT:getCharField(phExecution, "dt_hr_ult_sinal")).
        joRet:Add("finishedAt", THIS-OBJECT:getCharField(phExecution, "data_hora_fim")).
        joRet:Add("durationMs", THIS-OBJECT:getIntField(phExecution, "duracao_ms")).
        joRet:Add("pasoePid", THIS-OBJECT:getCharField(phExecution, "pid_pasoe")).
        joRet:Add("pasoeAgent", THIS-OBJECT:getCharField(phExecution, "agente_pasoe")).
        joRet:Add("pasoeInstance", THIS-OBJECT:getCharField(phExecution, "instancia_pasoe")).
        joRet:Add("hostName", THIS-OBJECT:getCharField(phExecution, "nome_host")).
        joRet:Add("databaseName", THIS-OBJECT:getCharField(phExecution, "nome_banco")).
        joRet:Add("dbTransactionRef", THIS-OBJECT:getCharField(phExecution, "ref_trans_banco")).
        joRet:Add("userName", THIS-OBJECT:getCharField(phExecution, "nome_usuario")).
        joRet:Add("errorCode", THIS-OBJECT:getCharField(phExecution, "codigo_erro")).
        joRet:Add("errorMessage", THIS-OBJECT:getCharField(phExecution, "mensagem_erro")).
        joRet:Add("killRequestedAt", THIS-OBJECT:getCharField(phExecution, "dt_hr_solic_interrupcao")).
        joRet:Add("killRequestedBy", THIS-OBJECT:getCharField(phExecution, "usuario_solic_interrupcao")).
        joRet:Add("killReason", THIS-OBJECT:getCharField(phExecution, "motivo_interrupcao")).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject eventBufferToJson(INPUT phEvent AS HANDLE):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        ASSIGN joRet = NEW JsonObject().
        joRet:Add("eventId", THIS-OBJECT:getCharField(phEvent, "id_evento")).
        joRet:Add("executionId", THIS-OBJECT:getCharField(phEvent, "id_execucao")).
        joRet:Add("eventStatus", THIS-OBJECT:getCharField(phEvent, "status_evento")).
        joRet:Add("eventMessage", THIS-OBJECT:getCharField(phEvent, "mensagem_evento")).
        joRet:Add("eventContextJson", THIS-OBJECT:getCharField(phEvent, "contexto_evento_json")).
        joRet:Add("eventTime", THIS-OBJECT:getCharField(phEvent, "data_hora_evento")).
        RETURN joRet.
    END METHOD.
    METHOD PRIVATE LONGCHAR contextToLongchar(INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        IF NOT VALID-OBJECT(poContext) THEN
            RETURN "".
        ASSIGN oSerializer = NEW DynamicQueryRequestSerializer().
        ASSIGN lcJson = oSerializer:contextToLongchar(poContext).
        DELETE OBJECT oSerializer NO-ERROR.
        RETURN lcJson.
    END METHOD.

    METHOD PRIVATE JsonObject buildError(INPUT pcCode AS CHARACTER, INPUT pcMessage AS CHARACTER, INPUT pcDetails AS CHARACTER):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.
        ASSIGN joRet = NEW JsonObject()
               joErr = NEW JsonObject().
        joErr:Add("code", pcCode).
        joErr:Add("message", pcMessage).
        joErr:Add("details", pcDetails).
        joRet:Add("success", FALSE).
        joRet:Add("error", joErr).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE CHARACTER createExecutionId():
        RETURN "EXE-"
             + STRING(YEAR(TODAY), "9999")
             + STRING(MONTH(TODAY), "99")
             + STRING(DAY(TODAY), "99")
             + "-"
             + STRING(TIME, "999999")
             + "-"
             + STRING(RANDOM(1, 999999), "999999").
    END METHOD.

    METHOD PRIVATE CHARACTER createEventId(INPUT pcExecutionId AS CHARACTER):
        RETURN pcExecutionId + "-" + STRING(TIME, "999999") + "-" + STRING(RANDOM(1, 999999), "999999").
    END METHOD.

    METHOD PRIVATE DATETIME currentDateTime():
        RETURN DATETIME(TODAY, MTIME).
    END METHOD.

    METHOD PRIVATE VOID setCharField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF VALID-HANDLE(hField) THEN
            ASSIGN hField:BUFFER-VALUE = pcValue NO-ERROR.
    END METHOD.

    METHOD PRIVATE VOID setLongcharField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER, INPUT pcValue AS LONGCHAR):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF VALID-HANDLE(hField) THEN
            ASSIGN hField:BUFFER-VALUE = SUBSTRING(pcValue, 1, 30000) NO-ERROR.
    END METHOD.

    METHOD PRIVATE VOID setIntField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF VALID-HANDLE(hField) THEN
            ASSIGN hField:BUFFER-VALUE = piValue NO-ERROR.
    END METHOD.

    METHOD PRIVATE VOID setDateTimeField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER, INPUT ptValue AS DATETIME):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF VALID-HANDLE(hField) THEN
            ASSIGN hField:BUFFER-VALUE = ptValue NO-ERROR.
    END METHOD.

    METHOD PRIVATE CHARACTER getCharField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF NOT VALID-HANDLE(hField) THEN
            RETURN "".
        ASSIGN cValue = STRING(hField:BUFFER-VALUE) NO-ERROR.
        IF ERROR-STATUS:ERROR OR cValue = ? THEN
            RETURN "".
        RETURN cValue.
    END METHOD.

    METHOD PRIVATE LONGCHAR getLongcharField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE lcValue AS LONGCHAR NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF NOT VALID-HANDLE(hField) THEN
            RETURN "".
        IF hField:DATA-TYPE = "CLOB" THEN DO:
            COPY-LOB FROM hField:BUFFER-VALUE TO lcValue NO-ERROR.
            IF ERROR-STATUS:ERROR THEN
                ASSIGN lcValue = "".
        END.
        ELSE
            ASSIGN lcValue = THIS-OBJECT:getCharField(phBuffer, pcField).
        RETURN lcValue.
    END METHOD.
    METHOD PRIVATE INTEGER getIntField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF NOT VALID-HANDLE(hField) THEN
            RETURN 0.
        ASSIGN iValue = INTEGER(hField:BUFFER-VALUE) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN 0.
        RETURN iValue.
    END METHOD.

    METHOD PRIVATE DATETIME getDateTimeField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE dtValue AS DATETIME NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF NOT VALID-HANDLE(hField) THEN
            RETURN ?.
        ASSIGN dtValue = DATETIME(hField:BUFFER-VALUE) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN ?.
        RETURN dtValue.
    END METHOD.

    METHOD PRIVATE CHARACTER getJsonChar(INPUT poObject AS JsonObject, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(poObject) THEN
            RETURN "".
        IF NOT poObject:Has(pcName) OR poObject:IsNull(pcName) THEN
            RETURN "".
        ASSIGN cValue = poObject:GetCharacter(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            ASSIGN cValue = "".
        RETURN cValue.
    END METHOD.

END CLASS.




