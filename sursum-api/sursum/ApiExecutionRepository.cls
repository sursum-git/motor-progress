/*
Repositorio de execucoes/transacoes da API PASOE.
Usa buffers dinamicos para permitir compilacao antes do .df estar carregado.
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.

CLASS ApiExecutionRepository:

    METHOD PUBLIC LOGICAL schemaAvailable():
        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.

        CREATE BUFFER hExecution FOR TABLE "SursumApiExecution" NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hExecution) THEN
            RETURN FALSE.
        DELETE OBJECT hExecution NO-ERROR.

        CREATE BUFFER hExecution FOR TABLE "SursumApiExecutionEvent" NO-ERROR.
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

        ASSIGN hExecution = THIS-OBJECT:createBuffer("SursumApiExecution").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cExecutionId = THIS-OBJECT:createExecutionId()
               cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        IF pcStatus = "" OR pcStatus = ? THEN
            ASSIGN pcStatus = "received".

        DO TRANSACTION:
            hExecution:BUFFER-CREATE().
            THIS-OBJECT:setCharField(hExecution, "executionId", cExecutionId).
            THIS-OBJECT:setCharField(hExecution, "requestId", IF VALID-OBJECT(poContext) THEN poContext:getRequestId() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "executionStatus", pcStatus).
            THIS-OBJECT:setCharField(hExecution, "executionType", pcExecutionType).
            THIS-OBJECT:setCharField(hExecution, "endpoint", pcEndpoint).
            THIS-OBJECT:setDateTimeField(hExecution, "startedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hExecution, "lastHeartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hExecution, "pasoePid", IF VALID-OBJECT(poContext) THEN poContext:getPasoePid() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "pasoeAgent", IF VALID-OBJECT(poContext) THEN poContext:getPasoeAgent() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "pasoeInstance", IF VALID-OBJECT(poContext) THEN poContext:getPasoeInstance() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "dbTransactionRef", IF VALID-OBJECT(poContext) THEN poContext:getDatabaseTransactionId() ELSE "").
            THIS-OBJECT:setCharField(hExecution, "requestSummary", pcRequestSummary).
            THIS-OBJECT:setLongcharField(hExecution, "requestContextJson", cContextJson).
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

        ASSIGN hExecution = THIS-OBJECT:createBuffer("SursumApiExecution").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE executionId = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            IF pcStatus <> "" AND pcStatus <> ? THEN
                THIS-OBJECT:setCharField(hExecution, "executionStatus", pcStatus).
            THIS-OBJECT:setDateTimeField(hExecution, "lastHeartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setLongcharField(hExecution, "requestContextJson", cContextJson).
            THIS-OBJECT:addEvent(pcExecutionId, IF pcStatus <> "" THEN pcStatus ELSE THIS-OBJECT:getCharField(hExecution, "executionStatus"), pcMessage, cContextJson).
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

        ASSIGN hExecution = THIS-OBJECT:createBuffer("SursumApiExecution").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE executionId = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            THIS-OBJECT:setCharField(hExecution, "executionStatus", "killRequested").
            THIS-OBJECT:setDateTimeField(hExecution, "lastHeartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hExecution, "killRequestedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hExecution, "killRequestedBy", pcRequestedBy).
            THIS-OBJECT:setCharField(hExecution, "killReason", pcReason).
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

        ASSIGN hExecution = THIS-OBJECT:createBuffer("SursumApiExecution").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN iLimit = IF piLimit > 0 THEN MIN(piLimit, 500) ELSE 100
               cWhere = "FOR EACH SursumApiExecution NO-LOCK".
        IF pcStatus <> "" AND pcStatus <> ? THEN
            ASSIGN cWhere = cWhere + " WHERE executionStatus = " + QUOTER(pcStatus).
        IF pcPid <> "" AND pcPid <> ? THEN
            ASSIGN cWhere = cWhere
                + (IF INDEX(cWhere, " WHERE ") > 0 THEN " AND " ELSE " WHERE ")
                + "pasoePid = " + QUOTER(pcPid).
        ASSIGN cWhere = cWhere + " BY startedAt DESC".

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

    METHOD PUBLIC JsonObject getExecution(INPUT pcExecutionId AS CHARACTER):
        DEFINE VARIABLE hExecution AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN hExecution = THIS-OBJECT:createBuffer("SursumApiExecution").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN lFound = hExecution:FIND-FIRST("WHERE executionId = " + QUOTER(pcExecutionId), NO-LOCK) NO-ERROR.
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

        ASSIGN hExecution = THIS-OBJECT:createBuffer("SursumApiExecution").
        IF NOT VALID-HANDLE(hExecution) THEN
            RETURN THIS-OBJECT:buildError("EXECUTION_SCHEMA_MISSING", "Schema de execucao nao encontrado", "Carregue db/sursum_api_execution.df no banco conectado.").

        ASSIGN cContextJson = THIS-OBJECT:contextToLongchar(poContext).
        DO TRANSACTION:
            ASSIGN lFound = hExecution:FIND-FIRST("WHERE executionId = " + QUOTER(pcExecutionId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hExecution NO-ERROR.
                RETURN THIS-OBJECT:buildError("EXECUTION_NOT_FOUND", "Execucao nao encontrada", pcExecutionId).
            END.
            ASSIGN dtStartedAt = THIS-OBJECT:getDateTimeField(hExecution, "startedAt")
                   iDuration = IF dtStartedAt <> ? THEN INTERVAL(THIS-OBJECT:currentDateTime(), dtStartedAt, "milliseconds") ELSE 0.
            THIS-OBJECT:setCharField(hExecution, "executionStatus", pcStatus).
            THIS-OBJECT:setDateTimeField(hExecution, "lastHeartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hExecution, "finishedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setIntField(hExecution, "durationMs", iDuration).
            THIS-OBJECT:setCharField(hExecution, "errorCode", pcErrorCode).
            THIS-OBJECT:setCharField(hExecution, "errorMessage", pcMessage).
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
            THIS-OBJECT:setCharField(phExecution, "hostName", THIS-OBJECT:getJsonChar(joContext, "hostName")).
            THIS-OBJECT:setCharField(phExecution, "databaseName", THIS-OBJECT:getJsonChar(joContext, "databaseName")).
            THIS-OBJECT:setCharField(phExecution, "userName", THIS-OBJECT:getJsonChar(joContext, "currentUser")).
            IF joContext:Has("custom") AND NOT joContext:IsNull("custom") THEN
                ASSIGN joCustom = joContext:GetJsonObject("custom") NO-ERROR.
            IF VALID-OBJECT(joCustom) THEN DO:
                THIS-OBJECT:setCharField(phExecution, "entrypoint", THIS-OBJECT:getJsonChar(joCustom, "entrypoint")).
                THIS-OBJECT:setCharField(phExecution, "companyId", THIS-OBJECT:getJsonChar(joCustom, "companyId")).
                THIS-OBJECT:setCharField(phExecution, "applicationName", THIS-OBJECT:getJsonChar(joCustom, "applicationName")).
                THIS-OBJECT:setCharField(phExecution, "actionCode", THIS-OBJECT:getJsonChar(joCustom, "actionCode")).
                THIS-OBJECT:setCharField(phExecution, "programName", THIS-OBJECT:getJsonChar(joCustom, "programName")).
                THIS-OBJECT:setCharField(phExecution, "queryCode", THIS-OBJECT:getJsonChar(joCustom, "queryCode")).
                THIS-OBJECT:setCharField(phExecution, "jobId", THIS-OBJECT:getJsonChar(joCustom, "jobId")).
                THIS-OBJECT:setCharField(phExecution, "authType", THIS-OBJECT:getJsonChar(joCustom, "authType")).
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

        ASSIGN hEvent = THIS-OBJECT:createBuffer("SursumApiExecutionEvent").
        IF NOT VALID-HANDLE(hEvent) THEN
            RETURN.

        hEvent:BUFFER-CREATE().
        THIS-OBJECT:setCharField(hEvent, "eventId", THIS-OBJECT:createEventId(pcExecutionId)).
        THIS-OBJECT:setCharField(hEvent, "executionId", pcExecutionId).
        THIS-OBJECT:setCharField(hEvent, "eventStatus", pcStatus).
        THIS-OBJECT:setCharField(hEvent, "eventMessage", pcMessage).
        THIS-OBJECT:setLongcharField(hEvent, "eventContextJson", pcContextJson).
        THIS-OBJECT:setDateTimeField(hEvent, "eventTime", THIS-OBJECT:currentDateTime()).
        hEvent:BUFFER-RELEASE().
        DELETE OBJECT hEvent NO-ERROR.
    END METHOD.

    METHOD PRIVATE JsonObject bufferToJson(INPUT phExecution AS HANDLE):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("executionId", THIS-OBJECT:getCharField(phExecution, "executionId")).
        joRet:Add("requestId", THIS-OBJECT:getCharField(phExecution, "requestId")).
        joRet:Add("status", THIS-OBJECT:getCharField(phExecution, "executionStatus")).
        joRet:Add("executionStatus", THIS-OBJECT:getCharField(phExecution, "executionStatus")).
        joRet:Add("executionType", THIS-OBJECT:getCharField(phExecution, "executionType")).
        joRet:Add("entrypoint", THIS-OBJECT:getCharField(phExecution, "entrypoint")).
        joRet:Add("endpoint", THIS-OBJECT:getCharField(phExecution, "endpoint")).
        joRet:Add("actionCode", THIS-OBJECT:getCharField(phExecution, "actionCode")).
        joRet:Add("programName", THIS-OBJECT:getCharField(phExecution, "programName")).
        joRet:Add("queryCode", THIS-OBJECT:getCharField(phExecution, "queryCode")).
        joRet:Add("jobId", THIS-OBJECT:getCharField(phExecution, "jobId")).
        joRet:Add("startedAt", THIS-OBJECT:getCharField(phExecution, "startedAt")).
        joRet:Add("lastHeartbeatAt", THIS-OBJECT:getCharField(phExecution, "lastHeartbeatAt")).
        joRet:Add("finishedAt", THIS-OBJECT:getCharField(phExecution, "finishedAt")).
        joRet:Add("durationMs", THIS-OBJECT:getIntField(phExecution, "durationMs")).
        joRet:Add("pasoePid", THIS-OBJECT:getCharField(phExecution, "pasoePid")).
        joRet:Add("pasoeAgent", THIS-OBJECT:getCharField(phExecution, "pasoeAgent")).
        joRet:Add("pasoeInstance", THIS-OBJECT:getCharField(phExecution, "pasoeInstance")).
        joRet:Add("hostName", THIS-OBJECT:getCharField(phExecution, "hostName")).
        joRet:Add("databaseName", THIS-OBJECT:getCharField(phExecution, "databaseName")).
        joRet:Add("dbTransactionRef", THIS-OBJECT:getCharField(phExecution, "dbTransactionRef")).
        joRet:Add("userName", THIS-OBJECT:getCharField(phExecution, "userName")).
        joRet:Add("errorCode", THIS-OBJECT:getCharField(phExecution, "errorCode")).
        joRet:Add("errorMessage", THIS-OBJECT:getCharField(phExecution, "errorMessage")).
        joRet:Add("killRequestedAt", THIS-OBJECT:getCharField(phExecution, "killRequestedAt")).
        joRet:Add("killRequestedBy", THIS-OBJECT:getCharField(phExecution, "killRequestedBy")).
        joRet:Add("killReason", THIS-OBJECT:getCharField(phExecution, "killReason")).
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
