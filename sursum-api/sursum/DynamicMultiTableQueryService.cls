/*
Orquestrador de consulta dinâmica multi-tabela.
Responsável por: validação, montagem do plano e execução inicial (sync).
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.ObjectModelParser.

CLASS DynamicMultiTableQueryService:

    DEFINE PRIVATE VARIABLE oValidator AS DynamicQueryValidationService NO-UNDO.
    DEFINE PRIVATE VARIABLE oBuilder  AS DynamicQueryPlanBuilder NO-UNDO.
    DEFINE PRIVATE VARIABLE iMaxSyncRecords AS INTEGER NO-UNDO INIT 5000.
    DEFINE PRIVATE VARIABLE lPaginationEnabled AS LOGICAL NO-UNDO INIT TRUE.
    /* A consumer parallel worker can bound an unpaged partition before the
       response JsonArray is materialized. Zero means the legacy unbounded mode. */
    DEFINE PRIVATE VARIABLE iUnpagedRecordLimit AS INTEGER NO-UNDO INIT 0.
    DEFINE PRIVATE VARIABLE cursorValue AS DynamicQueryCursor NO-UNDO.
    DEFINE PRIVATE VARIABLE cursorSecret AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cursorToken AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cursorBinding AS LONGCHAR NO-UNDO.
    DEFINE PRIVATE VARIABLE cursorEpoch AS INT64 NO-UNDO.
    DEFINE PRIVATE VARIABLE hCursorQuery AS HANDLE NO-UNDO.

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
        FIELD sourceOrder AS INTEGER
        FIELD sourceAlias AS CHARACTER
        FIELD sourceTable AS CHARACTER
        FIELD sourceBanco AS CHARACTER
        FIELD hBuffer     AS HANDLE.

    DEFINE PRIVATE TEMP-TABLE ttResolvedField NO-UNDO
        FIELD sourceAlias AS CHARACTER
        FIELD tableName   AS CHARACTER
        FIELD fieldName   AS CHARACTER
        FIELD dataType    AS CHARACTER
        FIELD fieldExtent AS INTEGER.

    DEFINE PRIVATE TEMP-TABLE ttPostSeen NO-UNDO
        FIELD keyValue AS CHARACTER.

    DEFINE PRIVATE TEMP-TABLE ttPostGroup NO-UNDO
        FIELD keyValue AS CHARACTER
        FIELD groupValues AS CHARACTER
        FIELD rowCount AS INTEGER
        FIELD sumValue AS DECIMAL
        FIELD minValue AS DECIMAL
        FIELD maxValue AS DECIMAL.

    DEFINE PRIVATE TEMP-TABLE ttPipelineStep NO-UNDO
        FIELD stepOrder      AS INTEGER
        FIELD stepType       AS CHARACTER
        FIELD stepPayload    AS CHARACTER
        FIELD stepRaw        AS CHARACTER.

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

    METHOD PUBLIC JsonObject validateConsumerAsync(INPUT poRequest AS DynamicQueryRequestModel):
        RETURN THIS-OBJECT:preparePlan(poRequest).
    END METHOD.

    METHOD PUBLIC JsonObject executeCursor(INPUT poRequest AS DynamicQueryRequestModel, INPUT bodyValue AS JsonObject, INPUT definitionValue AS JsonObject,
        INPUT consumerValue AS CHARACTER, INPUT generationValue AS CHARACTER, INPUT keyFile AS CHARACTER, INPUT epochValue AS INT64):
        DEFINE VARIABLE serializerValue AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE modelValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE pipelineCount AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            poRequest:getPipelineSteps(OUTPUT TABLE ttPipelineStep).
            FOR EACH ttPipelineStep:
                pipelineCount=pipelineCount + 1.
                IF LOOKUP(LC(ttPipelineStep.stepType),"source,join,select,filter,sort,limit,map")=0 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
            END.
            IF definitionValue:Has("pipeline") THEN IF NOT definitionValue:IsNull("pipeline") THEN
                IF definitionValue:GetJsonArray("pipeline"):Length<>pipelineCount THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
            resultValue=THIS-OBJECT:preparePlan(poRequest).
            IF NOT resultValue:GetLogical("success") THEN DO: DELETE OBJECT resultValue. RETURN THIS-OBJECT:cursorError("CURSOR_UNSUPPORTED",400). END.
            DELETE OBJECT resultValue.
            FOR EACH ttPlanJoin:
                IF LC(ttPlanJoin.joinType)<>"inner" THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
            END.
            cursorValue=NEW DynamicQueryCursor(). cursorSecret=cursorValue:readKey(keyFile). cursorEpoch=epochValue.
            cursorToken="". IF bodyValue:Has("cursor") THEN cursorToken=bodyValue:GetCharacter("cursor").
            serializerValue=NEW DynamicQueryRequestSerializer(). modelValue=serializerValue:toJsonObject(poRequest).
            FIX-CODEPAGE(textValue)="UTF-8". modelValue:Write(textValue,FALSE).
            contextValue=NEW JsonObject(). contextValue:Add("code",bodyValue:GetCharacter("code")).
            contextValue:Add("consumer",consumerValue). contextValue:Add("generation",generationValue).
            contextValue:Add("model",LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",textValue)))). contextValue:Add("pageSize",poRequest:getPageSize()).
            definitionValue:Write(textValue,FALSE).
            contextValue:Add("definition",LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",textValue)))).
            FIX-CODEPAGE(cursorBinding)="UTF-8". contextValue:Write(cursorBinding,FALSE).
            lPaginationEnabled=TRUE.
            resultValue=THIS-OBJECT:executeSync(poRequest).
            IF NOT resultValue:GetLogical("success") THEN DO:
                IF resultValue:Has("error") THEN DO:
                    codeValue=resultValue:GetJsonObject("error"):GetCharacter("code").
                    IF LOOKUP(codeValue,"CURSOR_INVALID,CURSOR_EXPIRED,CURSOR_UNSUPPORTED")>0 THEN RETURN resultValue.
                END.
                DELETE OBJECT resultValue. RETURN THIS-OBJECT:cursorError("CURSOR_UNAVAILABLE",503).
            END.
            RETURN resultValue.
            CATCH err AS Progress.Lang.Error:
                codeValue=err:GetMessage(1).
                IF LOOKUP(codeValue,"CURSOR_INVALID,CURSOR_EXPIRED,CURSOR_UNSUPPORTED")=0 THEN codeValue="CURSOR_UNAVAILABLE".
                RETURN THIS-OBJECT:cursorError(codeValue,IF codeValue="CURSOR_UNAVAILABLE" THEN 503 ELSE 400).
            END CATCH.
            FINALLY:
                IF VALID-HANDLE(hCursorQuery) THEN DO:
                    IF hCursorQuery:IS-OPEN THEN hCursorQuery:QUERY-CLOSE().
                    DELETE OBJECT hCursorQuery NO-ERROR.
                END.
                hCursorQuery=?. THIS-OBJECT:releaseBuffers().
                IF VALID-OBJECT(cursorValue) THEN DELETE OBJECT cursorValue.
                IF VALID-OBJECT(serializerValue) THEN DELETE OBJECT serializerValue.
                IF VALID-OBJECT(modelValue) THEN DELETE OBJECT modelValue.
                IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue.
                cursorSecret="". cursorToken="". cursorBinding="". lPaginationEnabled=TRUE.
            END FINALLY.
        END.
    END METHOD.

    METHOD PRIVATE JsonObject cursorError(INPUT codeValue AS CHARACTER, INPUT statusValue AS INTEGER):
        DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
        resultValue=NEW JsonObject(). errorValue=NEW JsonObject(). resultValue:Add("success",FALSE).
        errorValue:Add("code",codeValue). errorValue:Add("status",statusValue).
        errorValue:Add("message",IF codeValue="CURSOR_UNSUPPORTED" THEN "Consulta sem chave unica ou com transformacao incompativel com cursor." ELSE IF codeValue="CURSOR_EXPIRED" THEN "Cursor expirado. Reinicie a navegacao." ELSE IF codeValue="CURSOR_INVALID" THEN "Cursor invalido ou contexto alterado. Reinicie a navegacao." ELSE "Paginacao por cursor indisponivel.").
        resultValue:Add("error",errorValue). RETURN resultValue.
    END METHOD.

    METHOD PUBLIC JsonObject executeUnpaged(INPUT poRequest AS DynamicQueryRequestModel):
        RETURN THIS-OBJECT:executeUnpagedLimited(poRequest,0).
    END METHOD.

    METHOD PUBLIC JsonObject executeUnpagedLimited(INPUT poRequest AS DynamicQueryRequestModel, INPUT piRecordLimit AS INTEGER):
        /* Called only by the secured consumer entrypoint; ordinary executions remain paginated.
           The limit never truncates a result silently: executeSync exposes hasMore=TRUE
           and the parallel worker converts that state into a failed partition. */
        DO ON ERROR UNDO, THROW:
            lPaginationEnabled=FALSE.
            iUnpagedRecordLimit=MAXIMUM(0,piRecordLimit).
            RETURN THIS-OBJECT:executeSyncNow(poRequest).
            FINALLY:
                lPaginationEnabled=TRUE.
                iUnpagedRecordLimit=0.
            END FINALLY.
        END.
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
        DEFINE VARIABLE cursorKeys AS JsonArray NO-UNDO.
        DEFINE VARIABLE nextKeys AS JsonArray NO-UNDO.
        DEFINE VARIABLE cursorBuffer AS HANDLE NO-UNDO.
        DEFINE VARIABLE seenTables AS CHARACTER NO-UNDO.

        EMPTY TEMP-TABLE ttExecSource.

        ASSIGN iPage = poRequest:getPage()
               iPageSize = poRequest:getPageSize()
               iSkip = (iPage - 1) * iPageSize
               iSkip = MAX(0, iSkip).
        IF NOT lPaginationEnabled OR VALID-OBJECT(cursorValue) THEN iSkip=0.

        FOR EACH ttPlanSource:
            ASSIGN cTableName = THIS-OBJECT:buildPhysicalTableName(ttPlanSource.sourceBanco, ttPlanSource.sourceTable).
            CREATE BUFFER hBuffer FOR TABLE cTableName NO-ERROR.
            IF NOT VALID-HANDLE(hBuffer) THEN DO:
                THIS-OBJECT:releaseBuffers().
                RETURN THIS-OBJECT:buildError("INVALID_TABLE", "Fonte invalida", "table=" + cTableName).
            END.

            CREATE ttExecSource.
            ASSIGN ttExecSource.sourceOrder = ttPlanSource.sourceOrder
                   ttExecSource.sourceAlias = ttPlanSource.sourceAlias
                   ttExecSource.sourceTable = ttPlanSource.sourceTable
                   ttExecSource.sourceBanco = ttPlanSource.sourceBanco
                   ttExecSource.hBuffer = hBuffer.
        END.

        ASSIGN cQuery = oBuilder:getQuery().
        IF VALID-OBJECT(cursorValue) THEN DO ON ERROR UNDO, THROW:
            FOR EACH ttPlanOrder BY orderOrder:
                FIND FIRST ttExecSource WHERE ttExecSource.sourceAlias=ttPlanOrder.sourceAlias NO-ERROR.
                IF NOT AVAILABLE ttExecSource THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
                cursorValue:addOrder(ttExecSource.hBuffer,ttExecSource.sourceTable,ttPlanOrder.sourceField,LC(ttPlanOrder.direction)="descending",FALSE).
            END.
            FOR EACH ttExecSource BY ttExecSource.sourceOrder:
                IF LOOKUP(ttExecSource.sourceTable,seenTables)>0 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
                seenTables=seenTables + (IF seenTables="" THEN "" ELSE ",") + ttExecSource.sourceTable.
                cursorValue:addSource(ttExecSource.hBuffer,ttExecSource.sourceTable).
            END.
            cursorValue:initialize(cursorSecret,cursorBinding,cursorEpoch).
            cursorKeys=cursorValue:resume(cursorToken).
            cQuery=oBuilder:getCursorQuery(cursorValue:predicate(cursorKeys),cursorValue:orderClause()).
            IF VALID-OBJECT(cursorKeys) THEN DELETE OBJECT cursorKeys.
            CATCH cursorError AS Progress.Lang.Error:
                seenTables=cursorError:GetMessage(1).
                IF LOOKUP(seenTables,"CURSOR_INVALID,CURSOR_EXPIRED,CURSOR_UNSUPPORTED")=0 THEN seenTables="CURSOR_UNAVAILABLE".
                RETURN THIS-OBJECT:cursorError(seenTables,IF seenTables="CURSOR_UNAVAILABLE" THEN 503 ELSE 400).
            END CATCH.
        END.
        CREATE QUERY hQuery.
        IF VALID-OBJECT(cursorValue) THEN hCursorQuery=hQuery.
        FOR EACH ttExecSource:
            hQuery:ADD-BUFFER(ttExecSource.hBuffer).
        END.

        hQuery:QUERY-PREPARE(cQuery) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            THIS-OBJECT:releaseBuffers().
            DELETE OBJECT hQuery NO-ERROR.
            RETURN THIS-OBJECT:buildError("QUERY_PREPARE_ERROR", "Falha ao preparar consulta", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        hQuery:QUERY-OPEN() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            THIS-OBJECT:releaseBuffers().
            DELETE OBJECT hQuery NO-ERROR.
            RETURN THIS-OBJECT:buildError("QUERY_OPEN_ERROR", "Falha ao abrir consulta", ERROR-STATUS:GET-MESSAGE(1)).
        END.
        FOR EACH ttExecSource BY ttExecSource.sourceOrder:
            ASSIGN ttExecSource.hBuffer = hQuery:GET-BUFFER-HANDLE(ttExecSource.sourceOrder) NO-ERROR.
        END.
        ASSIGN joData = NEW JsonArray().

        REPEAT iCont = 1 TO iSkip + 1:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN LEAVE.
        END.

        REPEAT:
            IF hQuery:QUERY-OFF-END THEN LEAVE.
            IF lPaginationEnabled AND iReturned >= iPageSize THEN DO:
                ASSIGN lHasMore = YES.
                LEAVE.
            END.
            IF NOT lPaginationEnabled AND iUnpagedRecordLimit > 0 AND iReturned >= iUnpagedRecordLimit THEN DO:
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
            IF VALID-OBJECT(cursorValue) THEN DO:
                IF VALID-OBJECT(nextKeys) THEN DELETE OBJECT nextKeys.
                nextKeys=cursorValue:capture().
            END.

            hQuery:GET-NEXT().
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery.
        IF VALID-OBJECT(cursorValue) THEN hCursorQuery=?.
        THIS-OBJECT:releaseBuffers().

        ASSIGN joData = THIS-OBJECT:applyPostQueryPipeline(poRequest, joData).
        ASSIGN iReturned = joData:Length.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("execution", "sync").
        joRet:Add("status", "completed").
        IF VALID-OBJECT(cursorValue) THEN DO:
            joRet:AddNull("page"). joRet:Add("paginationMode","cursor"). joRet:Add("cursorExpiresIn",900).
            IF lHasMore THEN joRet:Add("nextCursor",cursorValue:issue(nextKeys)). ELSE joRet:AddNull("nextCursor").
            IF VALID-OBJECT(nextKeys) THEN DELETE OBJECT nextKeys.
        END.
        ELSE joRet:Add("page", poRequest:getPage()).
        IF lPaginationEnabled THEN joRet:Add("pageSize", poRequest:getPageSize()).
        ELSE DO: joRet:AddNull("pageSize"). joRet:Add("paginate",FALSE). END.
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
        ASSIGN pcBanco = THIS-OBJECT:resolveDatabaseName(pcBanco).
        IF pcBanco <> "" THEN
            RETURN pcBanco + "." + pcTabela.
        RETURN pcTabela.
    END METHOD.

    METHOD PRIVATE CHARACTER resolveDatabaseName(INPUT pcDatabase AS CHARACTER):
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.
        DEFINE VARIABLE cPhysical AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        ASSIGN cName = TRIM(pcDatabase).
        IF cName = "" OR cName = ? THEN
            RETURN "".
        DO iDb = 1 TO NUM-DBS:
            IF LC(LDBNAME(iDb)) = LC(cName) THEN
                RETURN LDBNAME(iDb).
            ASSIGN cPhysical = REPLACE(PDBNAME(iDb), "/", "~\").
            IF LC(cName) = LC(ENTRY(NUM-ENTRIES(cPhysical, "~\"), cPhysical, "~\")) THEN
                RETURN LDBNAME(iDb).
        END.
        RETURN cName.
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
        DEFINE VARIABLE cBaseField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iExtentIndex AS INTEGER NO-UNDO.

        THIS-OBJECT:parseExtentField(pcField, OUTPUT cBaseField, OUTPUT iExtentIndex).
        IF cBaseField = "" THEN
            RETURN "".

        ASSIGN hField = phBuffer:BUFFER-FIELD(cBaseField) NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(hField) THEN
            RETURN "".

        IF iExtentIndex > 0 THEN
            ASSIGN cRaw = STRING(hField:BUFFER-VALUE(iExtentIndex)) NO-ERROR.
        ELSE
            ASSIGN cRaw = STRING(hField:BUFFER-VALUE) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN RETURN "".
        ASSIGN cText = cRaw.
        IF cText = ? THEN ASSIGN cText = "".
        RETURN cText.
    END METHOD.

    METHOD PRIVATE VOID parseExtentField(
        INPUT  pcFieldRef AS CHARACTER,
        OUTPUT pcBaseField AS CHARACTER,
        OUTPUT piExtentIndex AS INTEGER):

        DEFINE VARIABLE iOpen AS INTEGER NO-UNDO.
        DEFINE VARIABLE iClose AS INTEGER NO-UNDO.
        DEFINE VARIABLE cIndex AS CHARACTER NO-UNDO.

        ASSIGN pcBaseField = TRIM(pcFieldRef)
               piExtentIndex = 0
               iOpen = INDEX(pcBaseField, "[")
               iClose = INDEX(pcBaseField, "]").

        IF iOpen = 0 AND iClose = 0 THEN
            RETURN.

        IF iOpen <= 1 OR iClose <= iOpen OR iClose <> LENGTH(pcBaseField) THEN DO:
            ASSIGN pcBaseField = ""
                   piExtentIndex = 0.
            RETURN.
        END.

        ASSIGN cIndex = SUBSTRING(pcBaseField, iOpen + 1, iClose - iOpen - 1)
               pcBaseField = SUBSTRING(pcBaseField, 1, iOpen - 1)
               piExtentIndex = INTEGER(cIndex) NO-ERROR.

        IF ERROR-STATUS:ERROR OR piExtentIndex < 1 THEN DO:
            ASSIGN pcBaseField = ""
                   piExtentIndex = 0.
        END.
    END METHOD.

    METHOD PRIVATE JsonArray applyPostQueryPipeline(INPUT poRequest AS DynamicQueryRequestModel, INPUT poData AS JsonArray):
        DEFINE VARIABLE cGroupFields AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDistinctFields AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAggOp AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAggField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAggAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE joPayload AS JsonObject NO-UNDO.

        EMPTY TEMP-TABLE ttPipelineStep.
        poRequest:getPipelineSteps(OUTPUT TABLE ttPipelineStep).

        FOR EACH ttPipelineStep BY ttPipelineStep.stepOrder:
            ASSIGN joPayload = THIS-OBJECT:parsePayload(ttPipelineStep.stepPayload).
            IF NOT VALID-OBJECT(joPayload) THEN NEXT.

            CASE LC(ttPipelineStep.stepType):
                WHEN "map" THEN
                    ASSIGN poData = THIS-OBJECT:applyMap(poData, joPayload).
                WHEN "distinct" THEN
                    ASSIGN cDistinctFields = THIS-OBJECT:getFieldsList(joPayload).
                WHEN "group" THEN
                    ASSIGN cGroupFields = THIS-OBJECT:getFieldsList(joPayload).
                WHEN "aggregate" THEN DO:
                    THIS-OBJECT:getAggregateSpec(joPayload, OUTPUT cAggOp, OUTPUT cAggField, OUTPUT cAggAlias).
                END.
            END CASE.

            DELETE OBJECT joPayload NO-ERROR.
        END.

        IF cDistinctFields <> "" THEN
            ASSIGN poData = THIS-OBJECT:applyDistinct(poData, cDistinctFields).

        IF cGroupFields <> "" THEN
            ASSIGN poData = THIS-OBJECT:applyGroup(poData, cGroupFields, cAggOp, cAggField, cAggAlias).
        ELSE IF cAggOp <> "" THEN
            ASSIGN poData = THIS-OBJECT:applyAggregate(poData, cAggOp, cAggField, cAggAlias).

        RETURN poData.
    END METHOD.

    METHOD PRIVATE JsonArray applyMap(INPUT poData AS JsonArray, INPUT poPayload AS JsonObject):
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaNew AS JsonArray NO-UNDO.
        DEFINE VARIABLE joOld AS JsonObject NO-UNDO.
        DEFINE VARIABLE joNew AS JsonObject NO-UNDO.
        DEFINE VARIABLE joField AS JsonObject NO-UNDO.
        DEFINE VARIABLE iRow AS INTEGER NO-UNDO.
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cFrom AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTo AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        IF NOT poPayload:Has("fields") THEN
            RETURN poData.

        ASSIGN jaFields = poPayload:GetJsonArray("fields")
               jaNew = NEW JsonArray().

        DO iRow = 1 TO poData:Length:
            ASSIGN joOld = poData:GetJsonObject(iRow)
                   joNew = NEW JsonObject().
            DO iField = 1 TO jaFields:Length:
                ASSIGN joField = jaFields:GetJsonObject(iField)
                       cFrom = THIS-OBJECT:getJsonChar(joField, "from")
                       cTo = THIS-OBJECT:getJsonChar(joField, "to").
                IF cFrom = "" THEN
                    ASSIGN cFrom = THIS-OBJECT:getJsonChar(joField, "field").
                IF cTo = "" THEN
                    ASSIGN cTo = cFrom.
                IF cTo = "" THEN NEXT.
                ASSIGN cValue = THIS-OBJECT:getJsonChar(joOld, cFrom).
                joNew:Add(cTo, cValue).
            END.
            jaNew:Add(joNew).
        END.

        RETURN jaNew.
    END METHOD.

    METHOD PRIVATE JsonArray applyDistinct(INPUT poData AS JsonArray, INPUT pcFields AS CHARACTER):
        DEFINE VARIABLE jaNew AS JsonArray NO-UNDO.
        DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
        DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iRow AS INTEGER NO-UNDO.

        EMPTY TEMP-TABLE ttPostSeen.
        ASSIGN jaNew = NEW JsonArray().

        DO iRow = 1 TO poData:Length:
            ASSIGN joRow = poData:GetJsonObject(iRow)
                   cKey = THIS-OBJECT:buildRowKey(joRow, pcFields).
            IF CAN-FIND(FIRST ttPostSeen WHERE ttPostSeen.keyValue = cKey) THEN
                NEXT.
            CREATE ttPostSeen.
            ASSIGN ttPostSeen.keyValue = cKey.
            jaNew:Add(joRow).
        END.

        RETURN jaNew.
    END METHOD.

    METHOD PRIVATE JsonArray applyGroup(INPUT poData AS JsonArray, INPUT pcFields AS CHARACTER, INPUT pcAggOp AS CHARACTER, INPUT pcAggField AS CHARACTER, INPUT pcAggAlias AS CHARACTER):
        DEFINE VARIABLE jaNew AS JsonArray NO-UNDO.
        DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
        DEFINE VARIABLE joOut AS JsonObject NO-UNDO.
        DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValues AS CHARACTER NO-UNDO.
        DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
        DEFINE VARIABLE iRow AS INTEGER NO-UNDO.
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAlias AS CHARACTER NO-UNDO.

        EMPTY TEMP-TABLE ttPostGroup.

        DO iRow = 1 TO poData:Length:
            ASSIGN joRow = poData:GetJsonObject(iRow)
                   cKey = THIS-OBJECT:buildRowKey(joRow, pcFields)
                   cValues = THIS-OBJECT:buildRowValues(joRow, pcFields)
                   dValue = DECIMAL(THIS-OBJECT:getJsonChar(joRow, pcAggField)) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN
                ASSIGN dValue = 0.

            FIND FIRST ttPostGroup WHERE ttPostGroup.keyValue = cKey NO-ERROR.
            IF NOT AVAILABLE ttPostGroup THEN DO:
                CREATE ttPostGroup.
                ASSIGN ttPostGroup.keyValue = cKey
                       ttPostGroup.groupValues = cValues
                       ttPostGroup.rowCount = 0
                       ttPostGroup.sumValue = 0
                       ttPostGroup.minValue = dValue
                       ttPostGroup.maxValue = dValue.
            END.

            ASSIGN ttPostGroup.rowCount = ttPostGroup.rowCount + 1
                   ttPostGroup.sumValue = ttPostGroup.sumValue + dValue
                   ttPostGroup.minValue = MIN(ttPostGroup.minValue, dValue)
                   ttPostGroup.maxValue = MAX(ttPostGroup.maxValue, dValue).
        END.

        ASSIGN jaNew = NEW JsonArray().
        FOR EACH ttPostGroup:
            ASSIGN joOut = NEW JsonObject().
            DO iField = 1 TO NUM-ENTRIES(pcFields):
                ASSIGN cField = TRIM(ENTRY(iField, pcFields)).
                joOut:Add(cField, ENTRY(iField, ttPostGroup.groupValues, CHR(1))).
            END.
            joOut:Add("count", ttPostGroup.rowCount).

            IF pcAggOp <> "" THEN DO:
                ASSIGN cAlias = IF pcAggAlias = "" THEN pcAggOp ELSE pcAggAlias.
                CASE LC(pcAggOp):
                    WHEN "sum" THEN joOut:Add(cAlias, ttPostGroup.sumValue).
                    WHEN "min" THEN joOut:Add(cAlias, ttPostGroup.minValue).
                    WHEN "max" THEN joOut:Add(cAlias, ttPostGroup.maxValue).
                    WHEN "avg" THEN joOut:Add(cAlias, IF ttPostGroup.rowCount = 0 THEN 0 ELSE ttPostGroup.sumValue / ttPostGroup.rowCount).
                    OTHERWISE joOut:Add(cAlias, ttPostGroup.rowCount).
                END CASE.
            END.
            jaNew:Add(joOut).
        END.

        RETURN jaNew.
    END METHOD.

    METHOD PRIVATE JsonArray applyAggregate(INPUT poData AS JsonArray, INPUT pcAggOp AS CHARACTER, INPUT pcAggField AS CHARACTER, INPUT pcAggAlias AS CHARACTER):
        DEFINE VARIABLE jaNew AS JsonArray NO-UNDO.
        DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
        DEFINE VARIABLE joOut AS JsonObject NO-UNDO.
        DEFINE VARIABLE iRow AS INTEGER NO-UNDO.
        DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
        DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
        DEFINE VARIABLE dSum AS DECIMAL NO-UNDO.
        DEFINE VARIABLE dMin AS DECIMAL NO-UNDO.
        DEFINE VARIABLE dMax AS DECIMAL NO-UNDO.
        DEFINE VARIABLE cAlias AS CHARACTER NO-UNDO.

        DO iRow = 1 TO poData:Length:
            ASSIGN joRow = poData:GetJsonObject(iRow)
                   dValue = DECIMAL(THIS-OBJECT:getJsonChar(joRow, pcAggField)) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN
                ASSIGN dValue = 0.
            IF iCount = 0 THEN
                ASSIGN dMin = dValue dMax = dValue.
            ASSIGN iCount = iCount + 1
                   dSum = dSum + dValue
                   dMin = MIN(dMin, dValue)
                   dMax = MAX(dMax, dValue).
        END.

        ASSIGN cAlias = IF pcAggAlias = "" THEN pcAggOp ELSE pcAggAlias
               joOut = NEW JsonObject()
               jaNew = NEW JsonArray().

        CASE LC(pcAggOp):
            WHEN "sum" THEN joOut:Add(cAlias, dSum).
            WHEN "min" THEN joOut:Add(cAlias, dMin).
            WHEN "max" THEN joOut:Add(cAlias, dMax).
            WHEN "avg" THEN joOut:Add(cAlias, IF iCount = 0 THEN 0 ELSE dSum / iCount).
            OTHERWISE joOut:Add(cAlias, iCount).
        END CASE.

        jaNew:Add(joOut).
        RETURN jaNew.
    END METHOD.

    METHOD PRIVATE CHARACTER getFieldsList(INPUT poPayload AS JsonObject):
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cList AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.

        IF poPayload:Has("fields") THEN DO:
            ASSIGN jaFields = poPayload:GetJsonArray("fields") NO-ERROR.
            IF NOT ERROR-STATUS:ERROR AND VALID-OBJECT(jaFields) THEN DO:
                DO iField = 1 TO jaFields:Length:
                    ASSIGN cField = jaFields:GetCharacter(iField) NO-ERROR.
                    IF ERROR-STATUS:ERROR THEN NEXT.
                    ASSIGN cList = IF cList = "" THEN cField ELSE cList + "," + cField.
                END.
                RETURN cList.
            END.
        END.

        RETURN THIS-OBJECT:getJsonChar(poPayload, "fields").
    END METHOD.

    METHOD PRIVATE VOID getAggregateSpec(INPUT poPayload AS JsonObject, OUTPUT pcOp AS CHARACTER, OUTPUT pcField AS CHARACTER, OUTPUT pcAlias AS CHARACTER):
        DEFINE VARIABLE jaFuncs AS JsonArray NO-UNDO.
        DEFINE VARIABLE joFunc AS JsonObject NO-UNDO.

        ASSIGN pcOp = THIS-OBJECT:getJsonChar(poPayload, "op")
               pcField = THIS-OBJECT:getJsonChar(poPayload, "field")
               pcAlias = THIS-OBJECT:getJsonChar(poPayload, "as").

        IF pcOp <> "" THEN
            RETURN.

        IF poPayload:Has("functions") THEN DO:
            ASSIGN jaFuncs = poPayload:GetJsonArray("functions") NO-ERROR.
            IF NOT ERROR-STATUS:ERROR AND VALID-OBJECT(jaFuncs) AND jaFuncs:Length > 0 THEN DO:
                ASSIGN joFunc = jaFuncs:GetJsonObject(1).
                ASSIGN pcOp = THIS-OBJECT:getJsonChar(joFunc, "op")
                       pcField = THIS-OBJECT:getJsonChar(joFunc, "field")
                       pcAlias = THIS-OBJECT:getJsonChar(joFunc, "as").
            END.
        END.

        IF pcOp = "" THEN
            ASSIGN pcOp = "count".
        IF pcAlias = "" THEN
            ASSIGN pcAlias = pcOp.
    END METHOD.

    METHOD PRIVATE CHARACTER buildRowKey(INPUT poRow AS JsonObject, INPUT pcFields AS CHARACTER):
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.

        DO iField = 1 TO NUM-ENTRIES(pcFields):
            ASSIGN cField = TRIM(ENTRY(iField, pcFields)).
            ASSIGN cKey = cKey + CHR(1) + THIS-OBJECT:getJsonChar(poRow, cField).
        END.
        RETURN cKey.
    END METHOD.

    METHOD PRIVATE CHARACTER buildRowValues(INPUT poRow AS JsonObject, INPUT pcFields AS CHARACTER):
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValues AS CHARACTER NO-UNDO.

        DO iField = 1 TO NUM-ENTRIES(pcFields):
            ASSIGN cField = TRIM(ENTRY(iField, pcFields)).
            ASSIGN cValues = IF cValues = "" THEN THIS-OBJECT:getJsonChar(poRow, cField) ELSE cValues + CHR(1) + THIS-OBJECT:getJsonChar(poRow, cField).
        END.
        RETURN cValues.
    END METHOD.

    METHOD PRIVATE CHARACTER getJsonChar(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
        DEFINE VARIABLE i64Value AS INT64 NO-UNDO.
        DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
        DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.
        IF NOT VALID-OBJECT(poJson) THEN RETURN "".
        IF pcName = "" THEN RETURN "".
        IF NOT poJson:Has(pcName) THEN RETURN "".
        IF poJson:IsNull(pcName) THEN RETURN "".

        ASSIGN cValue = poJson:GetCharacter(pcName) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN RETURN cValue.

        ASSIGN iValue = poJson:GetInteger(pcName) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN RETURN STRING(iValue).

        ASSIGN i64Value = poJson:GetInt64(pcName) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN RETURN STRING(i64Value).

        ASSIGN dValue = poJson:GetDecimal(pcName) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN RETURN STRING(dValue).

        ASSIGN lValue = poJson:GetLogical(pcName) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN RETURN STRING(lValue).

        RETURN cValue.
    END METHOD.

    METHOD PRIVATE JsonObject parsePayload(INPUT pcPayload AS CHARACTER):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joPayload AS JsonObject NO-UNDO.

        IF pcPayload = "" OR pcPayload = ? THEN
            RETURN ?.

        ASSIGN oParser = NEW ObjectModelParser().
        ASSIGN oConstruct = oParser:Parse(pcPayload) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN ?.
        END.
        ASSIGN joPayload = CAST(oConstruct, JsonObject) NO-ERROR.
        DELETE OBJECT oParser NO-ERROR.
        RETURN joPayload.
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
