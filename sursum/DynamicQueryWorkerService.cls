/*
Executor da fila assincrona.
Pode ser usado por worker PASOE ou CLIENT.
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Lang.Error.

CLASS DynamicQueryWorkerService:

    DEFINE PRIVATE VARIABLE oRepository AS DynamicQueryJobRepository NO-UNDO.
    DEFINE PRIVATE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
    DEFINE PRIVATE VARIABLE oQueryService AS DynamicMultiTableQueryService NO-UNDO.
    DEFINE PRIVATE VARIABLE oWriter AS DynamicQueryResultWriter NO-UNDO.

    CONSTRUCTOR PUBLIC DynamicQueryWorkerService():
        ASSIGN oRepository = NEW DynamicQueryJobRepository()
               oSerializer = NEW DynamicQueryRequestSerializer()
               oQueryService = NEW DynamicMultiTableQueryService()
               oWriter = NEW DynamicQueryResultWriter().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC DynamicQueryWorkerService():
        IF VALID-OBJECT(oRepository) THEN DELETE OBJECT oRepository.
        IF VALID-OBJECT(oSerializer) THEN DELETE OBJECT oSerializer.
        IF VALID-OBJECT(oQueryService) THEN DELETE OBJECT oQueryService.
        IF VALID-OBJECT(oWriter) THEN DELETE OBJECT oWriter.
    END DESTRUCTOR.

    METHOD PUBLIC JsonObject drain(INPUT poOptions AS DynamicQueryWorkerOptions):
        DEFINE VARIABLE joSummary AS JsonObject NO-UNDO.
        DEFINE VARIABLE joJob AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRun AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE lcRequestJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcContextJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJobId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cResultPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iProcessed AS INTEGER NO-UNDO.
        DEFINE VARIABLE iCompleted AS INTEGER NO-UNDO.
        DEFINE VARIABLE iFailed AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLoop AS INTEGER NO-UNDO.
        DEFINE VARIABLE iRecords AS INTEGER NO-UNDO.
        DEFINE VARIABLE lHasMore AS LOGICAL NO-UNDO.

        IF NOT VALID-OBJECT(poOptions) THEN
            ASSIGN poOptions = NEW DynamicQueryWorkerOptions().

        DO iLoop = 1 TO poOptions:getBatchSize():
            ASSIGN oContext = NEW PasoeExecutionContext().
            oContext:setCustomField("workerMode", poOptions:getExecutionMode()).
            oContext:setCustomField("workerName", poOptions:getWorkerName()).

            ASSIGN joJob = oRepository:claimNext(poOptions, oContext).
            IF NOT joJob:GetLogical("success") THEN DO:
                DELETE OBJECT joJob NO-ERROR.
                DELETE OBJECT oContext NO-ERROR.
                LEAVE.
            END.

            ASSIGN iProcessed = iProcessed + 1
                   cJobId = joJob:GetCharacter("jobId")
                   lcRequestJson = joJob:GetLongchar("requestJson")
                   lcContextJson = oSerializer:contextToLongchar(oContext).

            DO ON ERROR UNDO, THROW:
                ASSIGN oRequest = oSerializer:fromLongchar(lcRequestJson).
                ASSIGN joRun = oQueryService:executeSyncNow(oRequest).
                IF joRun:GetLogical("success") THEN DO:
                    ASSIGN cResultPath = oWriter:writeResult(cJobId, joRun, poOptions:getOutputDirectory())
                           iRecords = joRun:GetInteger("recordsReturned")
                           lHasMore = joRun:GetLogical("hasMore") NO-ERROR.
                    IF cResultPath = "" THEN DO:
                        oRepository:failJob(cJobId, "RESULT_WRITE_ERROR", "Falha ao gravar arquivo de resultado", poOptions:getOutputDirectory(), lcContextJson).
                        ASSIGN iFailed = iFailed + 1.
                    END.
                    ELSE DO:
                        oRepository:completeJob(cJobId, cResultPath, iRecords, lHasMore, lcContextJson).
                        ASSIGN iCompleted = iCompleted + 1.
                    END.
                END.
                ELSE DO:
                    ASSIGN joErr = joRun:GetJsonObject("error") NO-ERROR.
                    IF VALID-OBJECT(joErr) THEN
                        oRepository:failJob(cJobId, joErr:GetCharacter("code"), joErr:GetCharacter("message"), joErr:GetCharacter("details"), lcContextJson).
                    ELSE
                        oRepository:failJob(cJobId, "QUERY_ERROR", "Falha ao executar consulta", "", lcContextJson).
                    ASSIGN iFailed = iFailed + 1.
                END.
                CATCH oErr AS Error:
                    oRepository:failJob(cJobId, "WORKER_ERROR", oErr:GetMessage(1), "", lcContextJson).
                    ASSIGN iFailed = iFailed + 1.
                END CATCH.
            END.

            IF VALID-OBJECT(oRequest) THEN DELETE OBJECT oRequest NO-ERROR.
            IF VALID-OBJECT(joRun) THEN DELETE OBJECT joRun NO-ERROR.
            DELETE OBJECT joJob NO-ERROR.
            DELETE OBJECT oContext NO-ERROR.
        END.

        ASSIGN joSummary = NEW JsonObject().
        joSummary:Add("success", TRUE).
        joSummary:Add("workerMode", poOptions:getExecutionMode()).
        joSummary:Add("workerName", poOptions:getWorkerName()).
        joSummary:Add("processed", iProcessed).
        joSummary:Add("completed", iCompleted).
        joSummary:Add("failed", iFailed).
        RETURN joSummary.
    END METHOD.

END CLASS.
