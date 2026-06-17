/*
Servico de fila assincrona para consulta dinamica.
*/

USING Progress.Json.ObjectModel.JsonObject.

CLASS DynamicQueryAsyncService:

    DEFINE PRIVATE VARIABLE oRepository AS DynamicQueryJobRepository NO-UNDO.
    DEFINE PRIVATE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.

    CONSTRUCTOR PUBLIC DynamicQueryAsyncService():
        ASSIGN oRepository = NEW DynamicQueryJobRepository()
               oSerializer = NEW DynamicQueryRequestSerializer().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC DynamicQueryAsyncService():
        IF VALID-OBJECT(oRepository) THEN
            DELETE OBJECT oRepository.
        IF VALID-OBJECT(oSerializer) THEN
            DELETE OBJECT oSerializer.
    END DESTRUCTOR.

    METHOD PUBLIC JsonObject enqueue(
        INPUT poRequest AS DynamicQueryRequestModel,
        INPUT poContext AS PasoeExecutionContext,
        INPUT pcPlanJson AS LONGCHAR,
        INPUT pcPreferredMode AS CHARACTER):

        DEFINE VARIABLE lcRequestJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcContextJson AS LONGCHAR NO-UNDO.

        ASSIGN lcRequestJson = oSerializer:toLongchar(poRequest)
               lcContextJson = oSerializer:contextToLongchar(poContext).

        RETURN oRepository:createJob(
            lcRequestJson,
            pcPlanJson,
            lcContextJson,
            pcPreferredMode,
            3
        ).
    END METHOD.

    METHOD PUBLIC JsonObject getStatus(INPUT pcJobId AS CHARACTER):
        RETURN oRepository:getJob(pcJobId).
    END METHOD.

    METHOD PUBLIC JsonObject cancel(INPUT pcJobId AS CHARACTER, INPUT pcReason AS CHARACTER, INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE lcContextJson AS LONGCHAR NO-UNDO.
        ASSIGN lcContextJson = oSerializer:contextToLongchar(poContext).
        RETURN oRepository:cancelJob(pcJobId, pcReason, lcContextJson).
    END METHOD.

    METHOD PUBLIC CHARACTER getResultPath(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE joJob AS JsonObject NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.

        ASSIGN joJob = oRepository:getJob(pcJobId).
        IF joJob:GetLogical("success") THEN
            ASSIGN cPath = joJob:GetCharacter("resultPath") NO-ERROR.
        DELETE OBJECT joJob NO-ERROR.
        RETURN cPath.
    END METHOD.

END CLASS.
