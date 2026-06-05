/*
Orquestrador de consulta dinâmica multi-tabela.
Responsável por: validação, montagem do plano e execução inicial (sync).
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.

CLASS DynamicMultiTableQueryService:

    DEFINE PRIVATE VARIABLE oValidator AS DynamicQueryValidationService NO-UNDO.
    DEFINE PRIVATE VARIABLE oBuilder  AS DynamicQueryPlanBuilder NO-UNDO.
    DEFINE PRIVATE VARIABLE iMaxSyncRecords AS INTEGER NO-UNDO INIT 5000.

    DEFINE PRIVATE TEMP-TABLE ttPlanSource NO-UNDO
        FIELD sourceOrder AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceBanco AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanSelect NO-UNDO
        FIELD fieldOrder  AS INTEGER
        FIELD outputAlias AS CHARACTER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceField AS CHARACTER
        FIELD dataType    AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanJoin NO-UNDO
        FIELD joinOrder  AS INTEGER
        FIELD joinType   AS CHARACTER
        FIELD leftAlias  AS CHARACTER
        FIELD leftField  AS CHARACTER
        FIELD rightAlias AS CHARACTER
        FIELD rightField AS CHARACTER
        FIELD leftTable  AS CHARACTER
        FIELD rightTable AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPlanOrder NO-UNDO
        FIELD orderOrder  AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceField AS CHARACTER
        FIELD direction   AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttExecSource NO-UNDO
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceBanco AS CHARACTER
        FIELD hBuffer     AS HANDLE.

    DEFINE PRIVATE TEMP-TABLE ttResolvedField NO-UNDO
        FIELD sourceAlias AS CHARACTER
        FIELD tableName   AS CHARACTER
        FIELD fieldName   AS CHARACTER
        FIELD dataType    AS CHARACTER.

    CONSTRUCTOR PUBLIC DynamicMultiTableQueryService():
        ASSIGN oValidator = NEW DynamicQueryValidationService().
        ASSIGN oBuilder  = NEW DynamicQueryPlanBuilder().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC DynamicMultiTableQueryService():
        IF VALID-OBJECT(oValidator) THEN
            DELETE OBJECT oValidator.
        IF VALID-OBJECT(oBuilder) THEN
            DELETE OBJECT oBuilder.
    END DESTRUCTOR.

    METHOD PUBLIC JsonObject execute(INPUT poRequest AS DynamicQueryRequestModel):
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN oContext = NEW PasoeExecutionContext().
        ASSIGN joRet = THIS-OBJECT:execute(poRequest, oContext).
        DELETE OBJECT oContext NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject execute(INPUT poRequest AS DynamicQueryRequestModel, INPUT poContext AS PasoeExecutionContext):
        DEFINE VARIABLE joPrepared  AS JsonObject NO-UNDO.
        DEFINE VARIABLE oAsync      AS DynamicQueryAsyncService NO-UNDO.
        DEFINE VARIABLE cMode       AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iEstimated  AS INTEGER NO-UNDO.
        DEFINE VARIABLE lcPlanJson  AS LONGCHAR NO-UNDO.

        ASSIGN joPrepared = THIS-OBJECT:preparePlan(poRequest).
        IF NOT joPrepared:GetLogical("success") THEN
            RETURN joPrepared.
        DELETE OBJECT joPrepared NO-ERROR.

        ASSIGN cMode = LC(TRIM(poRequest:getExecution())).
        IF cMode = "" THEN
            ASSIGN cMode = "auto".

        ASSIGN iEstimated = poRequest:getPage() * poRequest:getPageSize().
        IF cMode = "auto" AND iEstimated > iMaxSyncRecords THEN
            ASSIGN cMode = "async".

        IF cMode = "async" THEN DO:
            ASSIGN lcPlanJson = THIS-OBJECT:buildPlanJson(poRequest, cMode).
            ASSIGN oAsync = NEW DynamicQueryAsyncService().
            ASSIGN joPrepared = oAsync:enqueue(poRequest, poContext, lcPlanJson, "").
            DELETE OBJECT oAsync NO-ERROR.
            RETURN joPrepared.
        END.

        RETURN THIS-OBJECT:executeSync(poRequest).
    END METHOD.

    METHOD PUBLIC JsonObject executeSyncNow(INPUT poRequest AS DynamicQueryRequestModel):
        DEFINE VARIABLE joPrepared AS JsonObject NO-UNDO.

        ASSIGN joPrepared = THIS-OBJECT:preparePlan(poRequest).
        IF NOT joPrepared:GetLogical("success") THEN
            RETURN joPrepared.
        DELETE OBJECT joPrepared NO-ERROR.

        RETURN THIS-OBJECT:executeSync(poRequest).
    END METHOD.

    METHOD PRIVATE JsonObject preparePlan(INPUT poRequest AS DynamicQueryRequestModel):
        DEFINE VARIABLE cErrCode    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cErrMsg     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cErrDetail  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lValid      AS LOGICAL NO-UNDO.
        DEFINE VARIABLE joRet       AS JsonObject NO-UNDO.

        ASSIGN lValid = oValidator:validate(
            poRequest,
            OUTPUT cErrCode,
            OUTPUT cErrMsg,
            OUTPUT cErrDetail
        ).
        IF cErrCode <> "" THEN
            RETURN THIS-OBJECT:buildError(cErrCode, cErrMsg, cErrDetail).

        oValidator:getResolvedFields(OUTPUT TABLE ttResolvedField).
        oBuilder:build(poRequest, INPUT TABLE ttResolvedField).
        oBuilder:getSources(OUTPUT TABLE ttPlanSource).
        oBuilder:getSelectPlan(OUTPUT TABLE ttPlanSelect).
        oBuilder:getJoinPlan(OUTPUT TABLE ttPlanJoin).
        oBuilder:getOrderPlan(OUTPUT TABLE ttPlanOrder).

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC JsonObject executeSingleTable(
        INPUT pcTable       AS CHARACTER,
        INPUT pcCampos      AS CHARACTER,
        INPUT pcBanco       AS CHARACTER,
        INPUT piPage        AS INTEGER,
        INPUT piPageSize    AS INTEGER,
        INPUT pcExecution   AS CHARACTER):

        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE joRet    AS JsonObject NO-UNDO.

        ASSIGN oRequest = NEW DynamicQueryRequestModel().
        oRequest:setPagination(piPage, piPageSize).
        oRequest:setDefaultBanco(pcBanco).
        oRequest:setExecution(pcExecution).
        oRequest:addLegacySingleSource(pcTable, pcBanco, pcCampos).

        ASSIGN joRet = THIS-OBJECT:execute(oRequest).
        DELETE OBJECT oRequest.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject executeSync(INPUT poRequest AS DynamicQueryRequestModel):
        DEFINE VARIABLE cQuery     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPage      AS INTEGER NO-UNDO.
        DEFINE VARIABLE iPageSize  AS INTEGER NO-UNDO.
        DEFINE VARIABLE iSkip      AS INTEGER NO-UNDO.
        DEFINE VARIABLE iCont      AS INTEGER NO-UNDO.
        DEFINE VARIABLE iReturned  AS INTEGER NO-UNDO.
        DEFINE VARIABLE lHasMore   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE cAlias     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTableName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE hQuery     AS HANDLE NO-UNDO.
        DEFINE VARIABLE hBuffer    AS HANDLE NO-UNDO.
        DEFINE VARIABLE joRet      AS JsonObject NO-UNDO.
        DEFINE VARIABLE joData     AS JsonArray NO-UNDO.
        DEFINE VARIABLE joRow      AS JsonObject NO-UNDO.

        EMPTY TEMP-TABLE ttExecSource.

        ASSIGN iPage = poRequest:getPage()
               iPageSize = poRequest:getPageSize()
               iSkip = (iPage - 1) * iPageSize
               iSkip = MAX(0, iSkip).

        FOR EACH ttPlanSource:
            ASSIGN cTableName = THIS-OBJECT:buildPhysicalTableName(ttPlanSource.sourceBanco, ttPlanSource.sourceTable).
            CREATE BUFFER hBuffer FOR TABLE cTableName NO-ERROR.
            IF NOT VALID-HANDLE(hBuffer) THEN DO:
                THIS-OBJECT:releaseBuffers().
                RETURN THIS-OBJECT:buildError("INVALID_TABLE", "Fonte invalida", "table=" + cTableName).
            END.

            CREATE ttExecSource.
            ASSIGN ttExecSource.sourceAlias = ttPlanSource.sourceAlias
                   ttExecSource.sourceTable = ttPlanSource.sourceTable
                   ttExecSource.sourceBanco = ttPlanSource.sourceBanco
                   ttExecSource.hBuffer = hBuffer.
        END.

        ASSIGN cQuery = oBuilder:getQuery().
        CREATE QUERY hQuery.
        FOR EACH ttExecSource:
            hQuery:ADD-BUFFER(ttExecSource.hBuffer).
        END.

        hQuery:QUERY-PREPARE(cQuery) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            THIS-OBJECT:releaseBuffers().
            DELETE OBJECT hQuery NO-ERROR.
            RETURN THIS-OBJECT:buildError("QUERY_PREPARE_ERROR", "Falha ao preparar consulta", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        hQuery:QUERY-OPEN().
        ASSIGN joData = NEW JsonArray().

        IF iSkip > 0 THEN DO:
            REPEAT iCont = 1 TO iSkip:
                hQuery:GET-NEXT().
                IF hQuery:QUERY-OFF-END THEN LEAVE.
            END.
        END.
        ELSE DO:
            hQuery:GET-FIRST().
        END.

        REPEAT:
            IF hQuery:QUERY-OFF-END THEN LEAVE.
            IF iReturned >= iPageSize THEN DO:
                ASSIGN lHasMore = YES.
                LEAVE.
            END.

            ASSIGN joRow = NEW JsonObject().
            FOR EACH ttPlanSelect BY ttPlanSelect.fieldOrder:
                FIND FIRST ttExecSource
                    WHERE ttExecSource.sourceAlias = ttPlanSelect.sourceAlias
                    NO-ERROR.
                IF NOT AVAILABLE ttExecSource THEN
                    FIND FIRST ttExecSource
                        WHERE ttExecSource.sourceTable = ttPlanSelect.sourceTable
                        NO-ERROR.
                IF NOT AVAILABLE ttExecSource THEN NEXT.

                ASSIGN hBuffer = ttExecSource.hBuffer.
                ASSIGN joRow = THIS-OBJECT:setJsonField(
                    joRow,
                    ttPlanSelect.outputAlias,
                    hBuffer,
                    ttPlanSelect.sourceField
                ).
            END.
            joData:ADD(joRow).
            ASSIGN iReturned = iReturned + 1.

            hQuery:GET-NEXT().
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery.
        THIS-OBJECT:releaseBuffers().

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("execution", "sync").
        joRet:Add("status", "completed").
        joRet:Add("page", poRequest:getPage()).
        joRet:Add("pageSize", poRequest:getPageSize()).
        joRet:Add("recordsReturned", iReturned).
        joRet:Add("hasMore", lHasMore).
        joRet:Add("data", joData).
        joRet:Add("pipelineVersion", poRequest:getPipelineVersion()).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE VOID releaseBuffers():
        FOR EACH ttExecSource:
            IF VALID-HANDLE(ttExecSource.hBuffer) THEN DO:
                ttExecSource.hBuffer:BUFFER-RELEASE() NO-ERROR.
                DELETE OBJECT ttExecSource.hBuffer NO-ERROR.
            END.
            DELETE ttExecSource.
        END.
    END METHOD.

    METHOD PRIVATE CHARACTER buildPhysicalTableName(INPUT pcBanco AS CHARACTER, INPUT pcTabela AS CHARACTER):
        IF pcBanco <> "" THEN
            RETURN pcBanco + "." + pcTabela.
        RETURN pcTabela.
    END METHOD.

    METHOD PRIVATE LONGCHAR buildPlanJson(INPUT poRequest AS DynamicQueryRequestModel, INPUT pcExecutionMode AS CHARACTER):
        DEFINE VARIABLE joPlan AS JsonObject NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        ASSIGN joPlan = NEW JsonObject().
        joPlan:Add("version", "1").
        joPlan:Add("executionMode", pcExecutionMode).
        joPlan:Add("query", oBuilder:getQuery()).
        joPlan:Add("select", oBuilder:getSelectClause()).
        joPlan:Add("where", oBuilder:getWhereClause()).
        joPlan:Add("sourceCount", oBuilder:getSourceCount()).
        joPlan:Add("page", poRequest:getPage()).
        joPlan:Add("pageSize", poRequest:getPageSize()).
        joPlan:Add("pipelineVersion", poRequest:getPipelineVersion()).

        joPlan:Write(lcJson, TRUE).
        DELETE OBJECT joPlan NO-ERROR.
        RETURN lcJson.
    END METHOD.

    METHOD PRIVATE JsonObject setJsonField(
        INPUT joRow AS JsonObject,
        INPUT pcAlias AS CHARACTER,
        INPUT phBuffer AS HANDLE,
        INPUT pcField AS CHARACTER):
        DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
        ASSIGN cText = THIS-OBJECT:getBufferFieldText(phBuffer, pcField).
        joRow:Add(pcAlias, cText).
        RETURN joRow.
    END METHOD.

    METHOD PRIVATE CHARACTER getBufferFieldText(INPUT phBuffer AS HANDLE, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE cText  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRaw   AS CHARACTER NO-UNDO.
        ASSIGN hField = phBuffer:BUFFER-FIELD(pcField) NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hField) THEN
            RETURN "".
        ASSIGN cRaw = STRING(hField:BUFFER-VALUE) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN RETURN "".
        ASSIGN cText = cRaw.
        IF cText = ? THEN ASSIGN cText = "".
        RETURN cText.
    END METHOD.

    METHOD PRIVATE JsonObject buildError(
        INPUT pcErrorCode AS CHARACTER,
        INPUT pcErrorMessage AS CHARACTER,
        INPUT pcErrorDetail AS CHARACTER):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.
        ASSIGN joRet = NEW JsonObject()
               joErr = NEW JsonObject().
        joErr:Add("code", pcErrorCode).
        joErr:Add("message", pcErrorMessage).
        joErr:Add("details", pcErrorDetail).
        joRet:Add("success", FALSE).
        joRet:Add("error", joErr).
        RETURN joRet.
    END METHOD.

    METHOD PUBLIC INTEGER getMaxSyncRecords():
        RETURN iMaxSyncRecords.
    END METHOD.

    METHOD PUBLIC VOID setMaxSyncRecords(INPUT piMaxSyncRecords AS INTEGER):
        IF piMaxSyncRecords > 0 THEN
            ASSIGN iMaxSyncRecords = piMaxSyncRecords.
    END METHOD.

END CLASS.
