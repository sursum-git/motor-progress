/*
Facade inicial para uso pela camada REST/PASOE.
Esta classe evita acoplar o contrato REST diretamente ao motor/worker.
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.ObjectModelParser.

CLASS DynamicQueryRestResource:

    METHOD PUBLIC JsonObject postDynamicQuery(INPUT pcRequestJson AS LONGCHAR):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
               oRequest = oSerializer:fromLongchar(pcRequestJson)
               oContext = NEW PasoeExecutionContext()
               oService = NEW DynamicMultiTableQueryService().
        oContext:setCustomField("entrypoint", "REST").
        ASSIGN joRet = oService:execute(oRequest, oContext).

        DELETE OBJECT oSerializer NO-ERROR.
        DELETE OBJECT oRequest NO-ERROR.
        DELETE OBJECT oContext NO-ERROR.
        DELETE OBJECT oService NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject getJobStatus(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        ASSIGN oAsync = NEW DynamicQueryAsyncService().
        ASSIGN joRet = oAsync:getStatus(pcJobId).
        DELETE OBJECT oAsync NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject cancelJob(INPUT pcJobId AS CHARACTER, INPUT pcReason AS CHARACTER):
        DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        ASSIGN oAsync = NEW DynamicQueryAsyncService()
               oContext = NEW PasoeExecutionContext().
        oContext:setCustomField("entrypoint", "REST").
        ASSIGN joRet = oAsync:cancel(pcJobId, pcReason, oContext).
        DELETE OBJECT oAsync NO-ERROR.
        DELETE OBJECT oContext NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject drainJobs(INPUT piBatchSize AS INTEGER):
        DEFINE VARIABLE oOptions AS DynamicQueryWorkerOptions NO-UNDO.
        DEFINE VARIABLE oWorker AS DynamicQueryWorkerService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN oOptions = NEW DynamicQueryWorkerOptions()
               oWorker = NEW DynamicQueryWorkerService().
        oOptions:setExecutionMode("PASOE").
        oOptions:setWorkerName("pasoe-drain").
        oOptions:setBatchSize(IF piBatchSize > 0 THEN piBatchSize ELSE 1).
        ASSIGN joRet = oWorker:drain(oOptions).
        DELETE OBJECT oOptions NO-ERROR.
        DELETE OBJECT oWorker NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject getJobResult(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.

        ASSIGN oAsync = NEW DynamicQueryAsyncService()
               joRet = oAsync:getStatus(pcJobId).
        IF joRet:GetLogical("success") THEN DO:
            ASSIGN cPath = joRet:GetCharacter("resultPath") NO-ERROR.
            IF joRet:GetCharacter("status") = "completed" AND cPath <> "" THEN DO:
                ASSIGN oParser = NEW ObjectModelParser().
                ASSIGN oConstruct = oParser:ParseFile(cPath) NO-ERROR.
                IF NOT ERROR-STATUS:ERROR THEN DO:
                    DELETE OBJECT joRet NO-ERROR.
                    ASSIGN joRet = CAST(oConstruct, JsonObject).
                END.
                ELSE DO:
                    joRet:Add("resultReadError", ERROR-STATUS:GET-MESSAGE(1)).
                    joRet:Add("resultDelivery", "file").
                END.
                DELETE OBJECT oParser NO-ERROR.
            END.
        END.
        DELETE OBJECT oAsync NO-ERROR.
        RETURN joRet.
    END METHOD.

END CLASS.
