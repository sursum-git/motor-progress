/*
Repositorio da fila de consultas dinamicas.
Usa buffers dinamicos para permitir compilacao antes do .df estar carregado.
*/

USING Progress.Json.ObjectModel.JsonObject.

CLASS DynamicQueryJobRepository:

    METHOD PUBLIC LOGICAL schemaAvailable():
        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.

        CREATE BUFFER hJob FOR TABLE "SursumQueryJob" NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hJob) THEN
            RETURN FALSE.
        DELETE OBJECT hJob NO-ERROR.

        CREATE BUFFER hJob FOR TABLE "SursumQueryJobEvent" NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hJob) THEN
            RETURN FALSE.
        DELETE OBJECT hJob NO-ERROR.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC JsonObject createJob(
        INPUT pcRequestJson AS LONGCHAR,
        INPUT pcPlanJson AS LONGCHAR,
        INPUT pcRequestContextJson AS LONGCHAR,
        INPUT pcPreferredMode AS CHARACTER,
        INPUT piMaxAttempts AS INTEGER):

        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.
        DEFINE VARIABLE cJobId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN hJob = THIS-OBJECT:createBuffer("SursumQueryJob").
        IF NOT VALID-HANDLE(hJob) THEN
            RETURN THIS-OBJECT:buildError("QUEUE_SCHEMA_MISSING", "Schema da fila nao encontrado", "Carregue db/sursum_async_queue.df no banco conectado.").

        ASSIGN cJobId = THIS-OBJECT:createJobId().

        DO TRANSACTION:
            hJob:BUFFER-CREATE().
            THIS-OBJECT:setCharField(hJob, "jobId", cJobId).
            THIS-OBJECT:setCharField(hJob, "jobStatus", "queued").
            THIS-OBJECT:setCharField(hJob, "executionMode", pcPreferredMode).
            THIS-OBJECT:setLongcharField(hJob, "requestJson", pcRequestJson).
            THIS-OBJECT:setLongcharField(hJob, "planJson", pcPlanJson).
            THIS-OBJECT:setLongcharField(hJob, "requestContextJson", pcRequestContextJson).
            THIS-OBJECT:setDateTimeField(hJob, "createdAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setIntField(hJob, "attempts", 0).
            THIS-OBJECT:setIntField(hJob, "maxAttempts", IF piMaxAttempts > 0 THEN piMaxAttempts ELSE 3).
            THIS-OBJECT:setDateTimeField(hJob, "nextRunAt", THIS-OBJECT:currentDateTime()).
            hJob:BUFFER-RELEASE().
            THIS-OBJECT:addEvent(cJobId, "queued", "Job enfileirado", pcRequestContextJson).
        END.

        DELETE OBJECT hJob NO-ERROR.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("execution", "async").
        joRet:Add("status", "queued").
        joRet:Add("jobId", cJobId).
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject getJob(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN hJob = THIS-OBJECT:createBuffer("SursumQueryJob").
        IF NOT VALID-HANDLE(hJob) THEN
            RETURN THIS-OBJECT:buildError("QUEUE_SCHEMA_MISSING", "Schema da fila nao encontrado", "Carregue db/sursum_async_queue.df no banco conectado.").

        ASSIGN lFound = hJob:FIND-FIRST("WHERE jobId = " + QUOTER(pcJobId), NO-LOCK) NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
            DELETE OBJECT hJob NO-ERROR.
            RETURN THIS-OBJECT:buildError("JOB_NOT_FOUND", "Job nao encontrado", pcJobId).
        END.

        ASSIGN joRet = THIS-OBJECT:bufferToJson(hJob).
        hJob:BUFFER-RELEASE().
        DELETE OBJECT hJob NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject claimNext(INPUT poOptions AS DynamicQueryWorkerOptions, INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE iAttempts AS INTEGER NO-UNDO.

        ASSIGN hJob = THIS-OBJECT:createBuffer("SursumQueryJob").
        IF NOT VALID-HANDLE(hJob) THEN
            RETURN THIS-OBJECT:buildError("QUEUE_SCHEMA_MISSING", "Schema da fila nao encontrado", "Carregue db/sursum_async_queue.df no banco conectado.").

        DO TRANSACTION:
            ASSIGN lFound = hJob:FIND-FIRST("WHERE jobStatus = 'queued'", EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hJob NO-ERROR.
                RETURN THIS-OBJECT:buildError("QUEUE_EMPTY", "Nenhum job pendente", "").
            END.

            ASSIGN iAttempts = THIS-OBJECT:getIntField(hJob, "attempts") + 1.
            THIS-OBJECT:setCharField(hJob, "jobStatus", "running").
            THIS-OBJECT:setCharField(hJob, "executionMode", poOptions:getExecutionMode()).
            THIS-OBJECT:setCharField(hJob, "lockedByMode", poOptions:getExecutionMode()).
            THIS-OBJECT:setCharField(hJob, "lockedByWorker", poOptions:getWorkerName()).
            THIS-OBJECT:setCharField(hJob, "lockedByAgent", poContext:getPasoeAgent()).
            THIS-OBJECT:setCharField(hJob, "lockedByPid", poContext:getPasoePid()).
            THIS-OBJECT:setDateTimeField(hJob, "lockedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hJob, "startedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hJob, "heartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setIntField(hJob, "attempts", iAttempts).
            THIS-OBJECT:setLongcharField(hJob, "workerContextJson", THIS-OBJECT:contextToLongchar(poContext)).
            THIS-OBJECT:addEvent(THIS-OBJECT:getCharField(hJob, "jobId"), "running", "Job reclamado por worker", THIS-OBJECT:contextToLongchar(poContext)).
            ASSIGN joRet = THIS-OBJECT:bufferToJson(hJob).
            hJob:BUFFER-RELEASE().
        END.

        DELETE OBJECT hJob NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject completeJob(
        INPUT pcJobId AS CHARACTER,
        INPUT pcResultPath AS CHARACTER,
        INPUT piRecordsReturned AS INTEGER,
        INPUT plHasMore AS LOGICAL,
        INPUT pcWorkerContextJson AS LONGCHAR):

        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.

        ASSIGN hJob = THIS-OBJECT:createBuffer("SursumQueryJob").
        IF NOT VALID-HANDLE(hJob) THEN
            RETURN THIS-OBJECT:buildError("QUEUE_SCHEMA_MISSING", "Schema da fila nao encontrado", "Carregue db/sursum_async_queue.df no banco conectado.").

        DO TRANSACTION:
            ASSIGN lFound = hJob:FIND-FIRST("WHERE jobId = " + QUOTER(pcJobId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hJob NO-ERROR.
                RETURN THIS-OBJECT:buildError("JOB_NOT_FOUND", "Job nao encontrado", pcJobId).
            END.
            THIS-OBJECT:setCharField(hJob, "jobStatus", "completed").
            THIS-OBJECT:setDateTimeField(hJob, "finishedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hJob, "heartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hJob, "resultPath", pcResultPath).
            THIS-OBJECT:setIntField(hJob, "recordsReturned", piRecordsReturned).
            THIS-OBJECT:setLogicalField(hJob, "hasMore", plHasMore).
            THIS-OBJECT:setLongcharField(hJob, "workerContextJson", pcWorkerContextJson).
            THIS-OBJECT:addEvent(pcJobId, "completed", "Job concluido", pcWorkerContextJson).
            hJob:BUFFER-RELEASE().
        END.
        DELETE OBJECT hJob NO-ERROR.
        RETURN THIS-OBJECT:getJob(pcJobId).
    END METHOD.

    METHOD PUBLIC JsonObject failJob(
        INPUT pcJobId AS CHARACTER,
        INPUT pcErrorCode AS CHARACTER,
        INPUT pcErrorMessage AS CHARACTER,
        INPUT pcErrorDetail AS CHARACTER,
        INPUT pcWorkerContextJson AS LONGCHAR):

        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE iAttempts AS INTEGER NO-UNDO.
        DEFINE VARIABLE iMaxAttempts AS INTEGER NO-UNDO.
        DEFINE VARIABLE cStatus AS CHARACTER NO-UNDO.

        ASSIGN hJob = THIS-OBJECT:createBuffer("SursumQueryJob").
        IF NOT VALID-HANDLE(hJob) THEN
            RETURN THIS-OBJECT:buildError("QUEUE_SCHEMA_MISSING", "Schema da fila nao encontrado", "Carregue db/sursum_async_queue.df no banco conectado.").

        DO TRANSACTION:
            ASSIGN lFound = hJob:FIND-FIRST("WHERE jobId = " + QUOTER(pcJobId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hJob NO-ERROR.
                RETURN THIS-OBJECT:buildError("JOB_NOT_FOUND", "Job nao encontrado", pcJobId).
            END.

            ASSIGN iAttempts = THIS-OBJECT:getIntField(hJob, "attempts")
                   iMaxAttempts = THIS-OBJECT:getIntField(hJob, "maxAttempts")
                   cStatus = IF iAttempts < iMaxAttempts THEN "queued" ELSE "failed".

            THIS-OBJECT:setCharField(hJob, "jobStatus", cStatus).
            IF cStatus = "failed" THEN
                THIS-OBJECT:setDateTimeField(hJob, "finishedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hJob, "heartbeatAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setDateTimeField(hJob, "nextRunAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hJob, "errorCode", pcErrorCode).
            THIS-OBJECT:setCharField(hJob, "errorMessage", pcErrorMessage).
            THIS-OBJECT:setCharField(hJob, "errorDetail", pcErrorDetail).
            THIS-OBJECT:setLongcharField(hJob, "workerContextJson", pcWorkerContextJson).
            THIS-OBJECT:addEvent(pcJobId, cStatus, pcErrorMessage, pcWorkerContextJson).
            hJob:BUFFER-RELEASE().
        END.
        DELETE OBJECT hJob NO-ERROR.
        RETURN THIS-OBJECT:getJob(pcJobId).
    END METHOD.

    METHOD PUBLIC JsonObject cancelJob(INPUT pcJobId AS CHARACTER, INPUT pcReason AS CHARACTER, INPUT pcContextJson AS LONGCHAR):
        DEFINE VARIABLE hJob AS HANDLE NO-UNDO.
        DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.

        ASSIGN hJob = THIS-OBJECT:createBuffer("SursumQueryJob").
        IF NOT VALID-HANDLE(hJob) THEN
            RETURN THIS-OBJECT:buildError("QUEUE_SCHEMA_MISSING", "Schema da fila nao encontrado", "Carregue db/sursum_async_queue.df no banco conectado.").

        DO TRANSACTION:
            ASSIGN lFound = hJob:FIND-FIRST("WHERE jobId = " + QUOTER(pcJobId), EXCLUSIVE-LOCK, NO-WAIT) NO-ERROR.
            IF ERROR-STATUS:ERROR OR NOT lFound THEN DO:
                DELETE OBJECT hJob NO-ERROR.
                RETURN THIS-OBJECT:buildError("JOB_NOT_FOUND", "Job nao encontrado", pcJobId).
            END.
            IF THIS-OBJECT:getCharField(hJob, "jobStatus") <> "queued" THEN DO:
                hJob:BUFFER-RELEASE().
                DELETE OBJECT hJob NO-ERROR.
                RETURN THIS-OBJECT:buildError("JOB_NOT_CANCELLABLE", "Job nao pode ser cancelado", "Somente jobs queued podem ser cancelados.").
            END.
            THIS-OBJECT:setCharField(hJob, "jobStatus", "cancelled").
            THIS-OBJECT:setDateTimeField(hJob, "finishedAt", THIS-OBJECT:currentDateTime()).
            THIS-OBJECT:setCharField(hJob, "errorMessage", pcReason).
            THIS-OBJECT:addEvent(pcJobId, "cancelled", pcReason, pcContextJson).
            hJob:BUFFER-RELEASE().
        END.
        DELETE OBJECT hJob NO-ERROR.
        RETURN THIS-OBJECT:getJob(pcJobId).
    END METHOD.

    METHOD PRIVATE HANDLE createBuffer(INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
        CREATE BUFFER hBuffer FOR TABLE pcTable NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hBuffer) THEN
            RETURN ?.
        RETURN hBuffer.
    END METHOD.

    METHOD PRIVATE VOID addEvent(INPUT pcJobId AS CHARACTER, INPUT pcStatus AS CHARACTER, INPUT pcMessage AS CHARACTER, INPUT pcContextJson AS LONGCHAR):
        DEFINE VARIABLE hEvent AS HANDLE NO-UNDO.

        ASSIGN hEvent = THIS-OBJECT:createBuffer("SursumQueryJobEvent").
        IF NOT VALID-HANDLE(hEvent) THEN
            RETURN.

        hEvent:BUFFER-CREATE().
        THIS-OBJECT:setCharField(hEvent, "eventId", THIS-OBJECT:createEventId(pcJobId)).
        THIS-OBJECT:setCharField(hEvent, "jobId", pcJobId).
        THIS-OBJECT:setCharField(hEvent, "eventStatus", pcStatus).
        THIS-OBJECT:setCharField(hEvent, "eventMessage", pcMessage).
        THIS-OBJECT:setLongcharField(hEvent, "eventContextJson", pcContextJson).
        THIS-OBJECT:setDateTimeField(hEvent, "eventTime", THIS-OBJECT:currentDateTime()).
        hEvent:BUFFER-RELEASE().
        DELETE OBJECT hEvent NO-ERROR.
    END METHOD.

    METHOD PRIVATE JsonObject bufferToJson(INPUT phJob AS HANDLE):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.
        DEFINE VARIABLE cResultPath AS CHARACTER NO-UNDO.

        ASSIGN cResultPath = THIS-OBJECT:getCharField(phJob, "resultPath")
               joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("jobId", THIS-OBJECT:getCharField(phJob, "jobId")).
        joRet:Add("status", THIS-OBJECT:getCharField(phJob, "jobStatus")).
        joRet:Add("execution", "async").
        joRet:Add("executionMode", THIS-OBJECT:getCharField(phJob, "executionMode")).
        joRet:Add("lockedByMode", THIS-OBJECT:getCharField(phJob, "lockedByMode")).
        joRet:Add("lockedByWorker", THIS-OBJECT:getCharField(phJob, "lockedByWorker")).
        joRet:Add("lockedByAgent", THIS-OBJECT:getCharField(phJob, "lockedByAgent")).
        joRet:Add("lockedByPid", THIS-OBJECT:getCharField(phJob, "lockedByPid")).
        joRet:Add("createdAt", THIS-OBJECT:getCharField(phJob, "createdAt")).
        joRet:Add("startedAt", THIS-OBJECT:getCharField(phJob, "startedAt")).
        joRet:Add("finishedAt", THIS-OBJECT:getCharField(phJob, "finishedAt")).
        joRet:Add("heartbeatAt", THIS-OBJECT:getCharField(phJob, "heartbeatAt")).
        joRet:Add("attempts", THIS-OBJECT:getIntField(phJob, "attempts")).
        joRet:Add("maxAttempts", THIS-OBJECT:getIntField(phJob, "maxAttempts")).
        joRet:Add("recordsReturned", THIS-OBJECT:getIntField(phJob, "recordsReturned")).
        joRet:Add("hasMore", THIS-OBJECT:getLogicalField(phJob, "hasMore")).
        joRet:Add("resultPath", cResultPath).
        joRet:Add("resultAvailable", cResultPath <> "").
        joRet:Add("requestJson", THIS-OBJECT:getLongcharField(phJob, "requestJson")).
        joRet:Add("planJson", THIS-OBJECT:getLongcharField(phJob, "planJson")).
        joRet:Add("requestContextJson", THIS-OBJECT:getLongcharField(phJob, "requestContextJson")).
        joRet:Add("workerContextJson", THIS-OBJECT:getLongcharField(phJob, "workerContextJson")).

        ASSIGN joErr = NEW JsonObject().
        joErr:Add("code", THIS-OBJECT:getCharField(phJob, "errorCode")).
        joErr:Add("message", THIS-OBJECT:getCharField(phJob, "errorMessage")).
        joErr:Add("details", THIS-OBJECT:getCharField(phJob, "errorDetail")).
        joRet:Add("error", joErr).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE LONGCHAR contextToLongchar(INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
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

    METHOD PRIVATE CHARACTER createJobId():
        RETURN "JOB-"
             + STRING(YEAR(TODAY), "9999")
             + STRING(MONTH(TODAY), "99")
             + STRING(DAY(TODAY), "99")
             + "-"
             + STRING(TIME, "999999")
             + "-"
             + STRING(RANDOM(1, 999999), "999999").
    END METHOD.

    METHOD PRIVATE CHARACTER createEventId(INPUT pcJobId AS CHARACTER):
        RETURN pcJobId + "-" + STRING(TIME, "999999") + "-" + STRING(RANDOM(1, 999999), "999999").
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
        IF VALID-HANDLE(hField) THEN DO:
            IF hField:DATA-TYPE = "CLOB" THEN
                COPY-LOB FROM pcValue TO hField:BUFFER-VALUE NO-ERROR.
            ELSE
                ASSIGN hField:BUFFER-VALUE = SUBSTRING(pcValue, 1, 30000) NO-ERROR.
        END.
    END METHOD.

    METHOD PRIVATE VOID setIntField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF VALID-HANDLE(hField) THEN
            ASSIGN hField:BUFFER-VALUE = piValue NO-ERROR.
    END METHOD.

    METHOD PRIVATE VOID setLogicalField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER, INPUT plValue AS LOGICAL):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF VALID-HANDLE(hField) THEN
            ASSIGN hField:BUFFER-VALUE = plValue NO-ERROR.
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

    METHOD PRIVATE LOGICAL getLogicalField(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF NOT VALID-HANDLE(hField) THEN
            RETURN FALSE.
        ASSIGN lValue = LOGICAL(hField:BUFFER-VALUE) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN FALSE.
        RETURN lValue.
    END METHOD.

END CLASS.
