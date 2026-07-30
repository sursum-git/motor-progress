/*
WebHandler HTTP para validacao REST real no PASOE.
URLs esperadas:
  GET  /web/SursumDynamicQuery
  POST /web/SursumDynamicQuery/query
  POST /web/SursumDynamicQuery/query-store
  POST /web/SursumDynamicQuery/table-browse
  POST /web/SursumDynamicQuery/program/execute
  GET  /web/SursumDynamicQuery/jobs/{jobId}
  GET  /web/SursumDynamicQuery/jobs/{jobId}/result
  POST /web/SursumDynamicQuery/jobs/drain
  GET  /web/SursumDynamicQuery/diagnostics/runtime
  GET  /web/SursumDynamicQuery/count
  GET  /web/SursumDynamicQuery/benchmarks/customer-count
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.ObjectModelParser.
USING Progress.Lang.Error.
USING Progress.Web.IWebHandler.
USING OpenEdge.Web.WebResponse.
USING OpenEdge.Web.WebResponseWriter.

CLASS DynamicQueryWebHandler IMPLEMENTS IWebHandler:

    DEFINE PRIVATE TEMP-TABLE ttBrowseKey NO-UNDO
        FIELD fieldOrder AS INTEGER
        FIELD fieldName AS CHARACTER
        FIELD dataType AS CHARACTER
        FIELD ascendingFlag AS LOGICAL
        FIELD fieldHandle AS HANDLE.

    DEFINE PRIVATE TEMP-TABLE ttBrowseField NO-UNDO
        FIELD fieldOrder AS INTEGER
        FIELD fieldName AS CHARACTER
        FIELD dataType AS CHARACTER
        FIELD extentIndex AS INTEGER
        FIELD outputName AS CHARACTER
        FIELD fieldHandle AS HANDLE.


    METHOD PUBLIC INTEGER HandleRequest():
        DEFINE VARIABLE cMethod AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cBody AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN cMethod = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "REQUEST_METHOD":U) NO-ERROR.
        ASSIGN cPath = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "PATH_INFO":U) NO-ERROR.
        ASSIGN cBody = WEB-CONTEXT:FORM-INPUT NO-ERROR.

        DO ON ERROR UNDO, THROW:
            CASE cMethod:
                WHEN "POST" THEN DO:
                    IF cPath MATCHES "*/context/config" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleSaveContextConfig(cBody).
                    END.
                    ELSE IF cPath MATCHES "*/jobs/drain" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleDrain().
                    END.
                    ELSE IF cPath MATCHES "*/query-store" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleSaveQueryStore(cBody).
                    END.
                    ELSE IF cPath MATCHES "*/table-browse" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleTableBrowse(cBody).
                    END.
                    ELSE IF cPath MATCHES "*/program/execute" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleProgramExecute(cBody).
                    END.
                    ELSE IF cPath MATCHES "*/metadata/view-as/resolve" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleResolveViewAs(cBody).
                    END.
                    ELSE IF cPath MATCHES "*/query" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handlePostQuery(cBody).
                    END.
                    ELSE IF cPath MATCHES "*/metadata/relations" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleSaveRelation(cBody).
                    END.
                    ELSE
                        ASSIGN joRet = THIS-OBJECT:buildError("NOT_FOUND", "Endpoint nao encontrado", cMethod + " " + cPath).
                END.
                WHEN "GET" THEN DO:
                    IF cPath MATCHES "*/context/config" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetContextConfig().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/sync" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataSync().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/cache-status" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataCacheStatus().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/database-catalog" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataDatabaseCatalog(FALSE).
                    END.
                    ELSE IF cPath MATCHES "*/metadata/databases/sync" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataDatabaseCatalog(TRUE).
                    END.
                    ELSE IF cPath MATCHES "*/metadata/databases" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataDatabases().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/tables/*/fields" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataFields(THIS-OBJECT:getTableFromMetadataPath(cPath)).
                    END.
                    ELSE IF cPath MATCHES "*/metadata/tables" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataTables().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/relations/of" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataRelationsOf().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/relations" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataRelations().
                    END.
                    ELSE IF cPath MATCHES "*/metadata/relations/*/*" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetRelation(cPath).
                    END.
                    ELSE IF cPath MATCHES "*/diagnostics/runtime" OR cPath MATCHES "*/diagnostics/agent" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleRuntimeDiagnostics(cMethod, cPath).
                    END.
                    ELSE IF THIS-OBJECT:isRootPath(cPath) THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleIndex().
                    END.
                    ELSE IF cPath MATCHES "*/count" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleCount().
                    END.
                    ELSE IF cPath MATCHES "*/benchmarks/customer-count" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleRecordCountBenchmark().
                    END.
                    ELSE IF cPath MATCHES "*/jobs/*/result" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetResult(THIS-OBJECT:getJobIdFromPath(cPath)).
                    END.
                    ELSE IF cPath MATCHES "*/jobs/*" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetStatus(THIS-OBJECT:getJobIdFromPath(cPath)).
                    END.
                    ELSE
                        ASSIGN joRet = THIS-OBJECT:buildError("NOT_FOUND", "Endpoint nao encontrado", cMethod + " " + cPath).
                END.
                WHEN "OPTIONS" THEN DO:
                    ASSIGN joRet = NEW JsonObject().
                    joRet:Add("success", TRUE).
                END.
                OTHERWISE
                    ASSIGN joRet = THIS-OBJECT:buildError("METHOD_NOT_ALLOWED", "Metodo nao suportado", cMethod).
            END CASE.

            THIS-OBJECT:writeJson(joRet).

            CATCH oErr AS Error:
                ASSIGN joRet = THIS-OBJECT:buildError("WEB_HANDLER_ERROR", oErr:GetMessage(1), cMethod + " " + cPath).
                THIS-OBJECT:writeJson(joRet).
            END CATCH.
        END.

        IF VALID-OBJECT(joRet) THEN
            DELETE OBJECT joRet NO-ERROR.

        RETURN 0.
    END METHOD.

    METHOD PRIVATE JsonObject handlePostQuery(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /query").

        ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF VALID-OBJECT(joBody) AND THIS-OBJECT:getJsonChar(joBody, "code") <> "" THEN
            RETURN THIS-OBJECT:handlePostStoredQuery(joBody).

        ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
               oRequest = oSerializer:fromLongchar(pcBody)
               oContext = NEW PasoeExecutionContext()
               oService = NEW DynamicMultiTableQueryService().

        oContext:setCustomField("entrypoint", "WEB").
        oContext:setCustomField("transport", "PASOE-WEB").

        ASSIGN joRet = oService:execute(oRequest, oContext).

        DELETE OBJECT oSerializer NO-ERROR.
        DELETE OBJECT oRequest NO-ERROR.
        DELETE OBJECT oContext NO-ERROR.
        DELETE OBJECT oService NO-ERROR.

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleSaveQueryStore(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joQuery AS JsonObject NO-UNDO.
        DEFINE VARIABLE joSaved AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cCode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cStatus AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /query-store").

        ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON de consulta salva invalido", "").

        ASSIGN cCode = THIS-OBJECT:getJsonChar(joBody, "code")
               cStatus = LC(THIS-OBJECT:getJsonChar(joBody, "status")).
        IF NOT THIS-OBJECT:isQueryCode(cCode) THEN
            RETURN THIS-OBJECT:buildError("INVALID_QUERY_CODE", "Codigo de consulta invalido", cCode).
        IF cStatus = "" THEN
            ASSIGN cStatus = "draft".
        IF cStatus <> "draft" AND cStatus <> "ready" THEN
            RETURN THIS-OBJECT:buildError("INVALID_QUERY_STATUS", "Status deve ser draft ou ready", cStatus).

        IF joBody:Has("query") AND NOT joBody:IsNull("query") THEN
            ASSIGN joQuery = joBody:GetJsonObject("query") NO-ERROR.
        IF NOT VALID-OBJECT(joQuery) THEN
            RETURN THIS-OBJECT:buildError("QUERY_REQUIRED", "Campo query deve conter a consulta a salvar", cCode).

        ASSIGN joSaved = NEW JsonObject().
        joSaved:Add("code", cCode).
        joSaved:Add("status", cStatus).
        joSaved:Add("query", joQuery).
        IF joBody:Has("externalFilters") AND NOT joBody:IsNull("externalFilters") THEN
            joSaved:Add("externalFilters", joBody:GetJsonArray("externalFilters")) NO-ERROR.
        ELSE IF joQuery:Has("externalFilters") AND NOT joQuery:IsNull("externalFilters") THEN
            joSaved:Add("externalFilters", joQuery:GetJsonArray("externalFilters")) NO-ERROR.
        joSaved:Add("updatedAt", STRING(NOW)).

        ASSIGN cFile = THIS-OBJECT:buildQueryStoreFile(cCode).
        joSaved:Write(lcJson, TRUE).
        COPY-LOB FROM lcJson TO FILE cFile NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN THIS-OBJECT:buildError("QUERY_STORE_WRITE_ERROR", "Nao foi possivel gravar consulta salva", ERROR-STATUS:GET-MESSAGE(1)).

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("code", cCode).
        joRet:Add("status", cStatus).
        joRet:Add("path", cFile).
        joRet:Add("data", joSaved).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handlePostStoredQuery(INPUT poBody AS JsonObject):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
        DEFINE VARIABLE joStored AS JsonObject NO-UNDO.
        DEFINE VARIABLE joQuery AS JsonObject NO-UNDO.
        DEFINE VARIABLE joParams AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cCode AS CHARACTER NO-UNDO.

        ASSIGN cCode = THIS-OBJECT:getJsonChar(poBody, "code").
        IF NOT THIS-OBJECT:isQueryCode(cCode) THEN
            RETURN THIS-OBJECT:buildError("INVALID_QUERY_CODE", "Codigo de consulta invalido", cCode).

        ASSIGN joStored = THIS-OBJECT:readStoredQuery(cCode).
        IF NOT VALID-OBJECT(joStored) THEN
            RETURN THIS-OBJECT:buildError("QUERY_NOT_FOUND", "Consulta salva nao encontrada", cCode).

        IF joStored:Has("query") AND NOT joStored:IsNull("query") THEN
            ASSIGN joQuery = joStored:GetJsonObject("query") NO-ERROR.
        IF NOT VALID-OBJECT(joQuery) THEN
            RETURN THIS-OBJECT:buildError("QUERY_STORE_INVALID", "Consulta salva sem query valida", cCode).

        IF poBody:Has("parameters") AND NOT poBody:IsNull("parameters") THEN
            ASSIGN joParams = poBody:GetJsonObject("parameters") NO-ERROR.

        ASSIGN joRet = THIS-OBJECT:applyStoredQueryParameters(joStored, joQuery, joParams).
        IF VALID-OBJECT(joRet) AND joRet:Has("success") AND NOT joRet:GetLogical("success") THEN
            RETURN joRet.
        DELETE OBJECT joRet NO-ERROR.

        ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
               oRequest = oSerializer:fromJsonObject(joQuery)
               oContext = NEW PasoeExecutionContext()
               oService = NEW DynamicMultiTableQueryService().

        oContext:setCustomField("entrypoint", "WEB").
        oContext:setCustomField("transport", "PASOE-WEB").
        oContext:setCustomField("queryCode", cCode).

        ASSIGN joRet = oService:execute(oRequest, oContext).

        DELETE OBJECT oSerializer NO-ERROR.
        DELETE OBJECT oRequest NO-ERROR.
        DELETE OBJECT oContext NO-ERROR.
        DELETE OBJECT oService NO-ERROR.

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleProgramExecute(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joParams AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cProgramCode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cProgramPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRunPath AS CHARACTER NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /program/execute").

        ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON de execucao de programa invalido", "").

        ASSIGN cProgramCode = THIS-OBJECT:getJsonChar(joBody, "program").
        IF NOT THIS-OBJECT:isProgramCode(cProgramCode) THEN
            RETURN THIS-OBJECT:buildError("INVALID_PROGRAM_CODE", "Codigo de programa invalido", cProgramCode).

        ASSIGN cProgramPath = THIS-OBJECT:getConfiguredProgramPath(cProgramCode).
        IF cProgramPath = "" THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_NOT_ALLOWED", "Programa nao cadastrado para execucao", cProgramCode).
        IF NOT THIS-OBJECT:isAllowedProgramPath(cProgramPath) THEN
            RETURN THIS-OBJECT:buildError("INVALID_PROGRAM_PATH", "Caminho de programa invalido no catalogo", cProgramCode + "=" + cProgramPath).

        ASSIGN cRunPath = THIS-OBJECT:resolveProgramRunPath(cProgramPath).
        IF cRunPath = "" THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_NOT_FOUND", "Programa cadastrado nao encontrado no PROPATH", cProgramCode + "=" + cProgramPath).

        IF joBody:Has("parameters") AND NOT joBody:IsNull("parameters") THEN DO:
            ASSIGN joParams = joBody:GetJsonObject("parameters") NO-ERROR.
            IF NOT VALID-OBJECT(joParams) THEN
                RETURN THIS-OBJECT:buildError("INVALID_PARAMETERS", "Campo parameters deve ser um objeto JSON", cProgramCode).
        END.
        ELSE
            ASSIGN joParams = NEW JsonObject().

        RUN VALUE(cRunPath) (INPUT joParams, OUTPUT joRet) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_EXECUTION_ERROR", "Erro ao executar programa Progress", ERROR-STATUS:GET-MESSAGE(1)).

        IF NOT VALID-OBJECT(joRet) THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_EMPTY_RESPONSE", "Programa nao retornou JsonObject", cProgramCode).

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE CHARACTER getConfiguredProgramPath(INPUT pcProgramCode AS CHARACTER):
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPrograms AS JsonObject NO-UNDO.

        ASSIGN joConfig = THIS-OBJECT:readProgramExecutorConfig().
        IF VALID-OBJECT(joConfig) AND joConfig:Has("programs") AND NOT joConfig:IsNull("programs") THEN
            ASSIGN joPrograms = joConfig:GetJsonObject("programs") NO-ERROR.
        RETURN THIS-OBJECT:getJsonChar(joPrograms, pcProgramCode).
    END METHOD.

    METHOD PRIVATE JsonObject readProgramExecutorConfig():
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:resolveConfigFile("sursum-conf/program-executor.json").
        ASSIGN joConfig = THIS-OBJECT:readJsonFile(cFile).
        IF VALID-OBJECT(joConfig) THEN
            RETURN joConfig.

        ASSIGN joConfig = THIS-OBJECT:readJsonFile("/dados/pasoe/sursum-api/sursum-conf/program-executor.json").
        IF VALID-OBJECT(joConfig) THEN
            RETURN joConfig.

        RETURN THIS-OBJECT:readJsonFile("/mnt/datasul/ERP/sursum/sursum-conf/program-executor.json").
    END METHOD.

    METHOD PRIVATE CHARACTER resolveProgramRunPath(INPUT pcProgramPath AS CHARACTER):
        DEFINE VARIABLE cResolved AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRun AS CHARACTER NO-UNDO.

        ASSIGN cResolved = THIS-OBJECT:resolveConfigFile(pcProgramPath).
        ASSIGN cRun = THIS-OBJECT:firstExistingProgramArtifact(cResolved).
        IF cRun <> "" THEN
            RETURN cRun.

        ASSIGN cResolved = "/mnt/datasul/ERP/sursum/" + THIS-OBJECT:normalizeConfigPath(pcProgramPath)
               cRun = THIS-OBJECT:firstExistingProgramArtifact(cResolved).
        IF cRun <> "" THEN
            RETURN cRun.

        ASSIGN cResolved = "/dados/pasoe/sursum-api/" + THIS-OBJECT:normalizeConfigPath(pcProgramPath)
               cRun = THIS-OBJECT:firstExistingProgramArtifact(cResolved).
        IF cRun <> "" THEN
            RETURN cRun.

        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER firstExistingProgramArtifact(INPUT pcProgramPath AS CHARACTER):
        DEFINE VARIABLE cAlt AS CHARACTER NO-UNDO.

        FILE-INFO:FILE-NAME = pcProgramPath.
        IF FILE-INFO:FULL-PATHNAME <> ? THEN
            RETURN pcProgramPath.

        IF LENGTH(pcProgramPath) > 2 AND LC(SUBSTRING(pcProgramPath, LENGTH(pcProgramPath) - 1)) = ".p" THEN DO:
            ASSIGN cAlt = SUBSTRING(pcProgramPath, 1, LENGTH(pcProgramPath) - 2) + ".r".
            FILE-INFO:FILE-NAME = cAlt.
            IF FILE-INFO:FULL-PATHNAME <> ? THEN
                RETURN cAlt.
        END.

        RETURN "".
    END METHOD.

    METHOD PRIVATE JsonObject handleIndex():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joEndpoints AS JsonObject NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               joEndpoints = NEW JsonObject().

        joEndpoints:Add("contextConfig", "GET/POST /web/SursumDynamicQuery/context/config").
        joEndpoints:Add("query", "POST /web/SursumDynamicQuery/query").
        joEndpoints:Add("queryStore", "POST /web/SursumDynamicQuery/query-store").
        joEndpoints:Add("tableBrowse", "POST /web/SursumDynamicQuery/table-browse").
        joEndpoints:Add("programExecute", "POST /web/SursumDynamicQuery/program/execute").
        joEndpoints:Add("metadataSync", "GET /web/SursumDynamicQuery/metadata/sync?include=banks,aliases,tables,fields&database=:database&table=:table").
        joEndpoints:Add("metadataDatabases", "GET /web/SursumDynamicQuery/metadata/databases").
        joEndpoints:Add("metadataDatabaseCatalog", "GET /web/SursumDynamicQuery/metadata/database-catalog").
        joEndpoints:Add("metadataDatabaseSync", "GET /web/SursumDynamicQuery/metadata/databases/sync").
        joEndpoints:Add("metadataCacheStatus", "GET /web/SursumDynamicQuery/metadata/cache-status?database=:database").
        joEndpoints:Add("metadataTables", "GET /web/SursumDynamicQuery/metadata/tables").
        joEndpoints:Add("metadataFields", "GET /web/SursumDynamicQuery/metadata/tables/:table/fields").
        joEndpoints:Add("metadataViewAsResolve", "POST /web/SursumDynamicQuery/metadata/view-as/resolve").
        joEndpoints:Add("metadataSaveRelation", "POST /web/SursumDynamicQuery/metadata/relations").
        joEndpoints:Add("metadataGetRelation", "GET /web/SursumDynamicQuery/metadata/relations/:left/:right").
        joEndpoints:Add("diagnosticsRuntime", "GET /web/SursumDynamicQuery/diagnostics/runtime?waitSeconds=:seconds&label=:label").
        joEndpoints:Add("drain", "POST /web/SursumDynamicQuery/jobs/drain").
        joEndpoints:Add("jobStatus", "GET /web/SursumDynamicQuery/jobs/:jobId").
        joEndpoints:Add("jobResult", "GET /web/SursumDynamicQuery/jobs/:jobId/result").
        joEndpoints:Add("count", "GET /web/SursumDynamicQuery/count?database=:database&table=:table").
        joEndpoints:Add("customerCountBenchmark", "GET /web/SursumDynamicQuery/benchmarks/customer-count").

        joRet:Add("success", TRUE).
        joRet:Add("service", "SursumDynamicQuery").
        joRet:Add("runtime", "PASOE-WEB").
        joRet:Add("endpoints", joEndpoints).

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleRuntimeDiagnostics(INPUT pcMethod AS CHARACTER, INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
        DEFINE VARIABLE joSession AS JsonObject NO-UNDO.
        DEFINE VARIABLE joContext AS JsonObject NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cWait AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLabel AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cServerConnectionId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cServerOperatingMode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lRemote AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lServerConnectionBound AS LOGICAL NO-UNDO.
        DEFINE VARIABLE iWaitSeconds AS INTEGER NO-UNDO.
        DEFINE VARIABLE iElapsedMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE dtStartedAt AS DATETIME NO-UNDO.
        DEFINE VARIABLE dtFinishedAt AS DATETIME NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cWait = THIS-OBJECT:getQueryValue(cQuery, "waitSeconds").
        IF cWait = "" THEN
            ASSIGN cWait = THIS-OBJECT:getQueryValue(cQuery, "wait").
        ASSIGN cLabel = THIS-OBJECT:getQueryValue(cQuery, "label").

        ASSIGN iWaitSeconds = INTEGER(cWait) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            ASSIGN iWaitSeconds = 0.
        END.
        IF iWaitSeconds < 0 THEN
            ASSIGN iWaitSeconds = 0.
        IF iWaitSeconds > 30 THEN
            ASSIGN iWaitSeconds = 30.

        ASSIGN oContext = NEW PasoeExecutionContext()
               dtStartedAt = NOW.

        ETIME(TRUE).
        IF iWaitSeconds > 0 THEN
            PAUSE iWaitSeconds NO-MESSAGE.
        ASSIGN iElapsedMs = ETIME
               dtFinishedAt = NOW.

        ASSIGN lRemote = SESSION:REMOTE NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            ASSIGN lRemote = FALSE.
        END.

        IF lRemote THEN DO:
            ASSIGN cServerConnectionId = SESSION:SERVER-CONNECTION-ID NO-ERROR.
            IF ERROR-STATUS:ERROR THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                ASSIGN cServerConnectionId = "".
            END.

            ASSIGN cServerOperatingMode = SESSION:SERVER-OPERATING-MODE NO-ERROR.
            IF ERROR-STATUS:ERROR THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                ASSIGN cServerOperatingMode = "".
            END.

            ASSIGN lServerConnectionBound = SESSION:SERVER-CONNECTION-BOUND NO-ERROR.
            IF ERROR-STATUS:ERROR THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                ASSIGN lServerConnectionBound = FALSE.
            END.
        END.

        ASSIGN joRequest = NEW JsonObject()
               joSession = NEW JsonObject()
               joRet = NEW JsonObject().

        joRequest:Add("method", pcMethod).
        joRequest:Add("path", pcPath).
        joRequest:Add("queryString", IF cQuery = ? THEN "" ELSE cQuery).
        joRequest:Add("label", cLabel).
        joRequest:Add("waitSecondsRequested", cWait).
        joRequest:Add("waitSecondsApplied", iWaitSeconds).
        joRequest:Add("maxWaitSeconds", 30).

        joSession:Add("remote", lRemote).
        joSession:Add("serverConnectionId", cServerConnectionId).
        joSession:Add("serverOperatingMode", cServerOperatingMode).
        joSession:Add("serverConnectionBound", lServerConnectionBound).
        joSession:Add("tempDirectory", SESSION:TEMP-DIRECTORY).
        joSession:Add("startupParameters", SESSION:STARTUP-PARAMETERS).

        ASSIGN joContext = oContext:toJson().

        joRet:Add("success", TRUE).
        joRet:Add("service", "SursumDynamicQuery").
        joRet:Add("runtime", "PASOE-WEB").
        joRet:Add("startedAt", STRING(dtStartedAt)).
        joRet:Add("finishedAt", STRING(dtFinishedAt)).
        joRet:Add("elapsedMs", iElapsedMs).
        joRet:Add("request", joRequest).
        joRet:Add("session", joSession).
        joRet:Add("context", joContext).

        DELETE OBJECT oContext NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleGetContextConfig():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:getContextConfigFile()
               joConfig = THIS-OBJECT:readContextConfig().
        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("path", cFile).
        joRet:Add("data", joConfig).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleSaveContextConfig(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /context/config").

        ASSIGN oParser = NEW ObjectModelParser()
               cJson = STRING(pcBody) NO-ERROR.
        ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON de contexto invalido", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        ASSIGN joBody = CAST(oConstruct, JsonObject) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON de contexto deve ser um objeto", "").
        END.

        IF joBody:Has("data") AND NOT joBody:IsNull("data") THEN
            ASSIGN joConfig = joBody:GetJsonObject("data") NO-ERROR.
        IF NOT VALID-OBJECT(joConfig) THEN
            ASSIGN joConfig = joBody.

        ASSIGN cFile = THIS-OBJECT:getContextConfigFile().
        joConfig:Write(lcJson, TRUE).
        COPY-LOB FROM lcJson TO FILE cFile NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("CONTEXT_WRITE_ERROR", "Nao foi possivel gravar contexto", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("path", cFile).
        joRet:Add("data", joConfig).
        DELETE OBJECT oParser NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject readContextConfig():
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:getContextConfigFile().
        FILE-INFO:FILE-NAME = cFile.
        IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
            COPY-LOB FROM FILE cFile TO lcJson NO-ERROR.
            IF NOT ERROR-STATUS:ERROR THEN DO:
                ASSIGN cJson = STRING(lcJson) NO-ERROR.
                ASSIGN oParser = NEW ObjectModelParser().
                ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
                ASSIGN joConfig = CAST(oConstruct, JsonObject) NO-ERROR.
                DELETE OBJECT oParser NO-ERROR.
                IF VALID-OBJECT(joConfig) THEN
                    RETURN joConfig.
            END.
        END.

        RETURN THIS-OBJECT:buildDefaultContextConfig().
    END METHOD.

    METHOD PRIVATE JsonObject buildDefaultContextConfig():
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPaths AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaClients AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaEnvironments AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaCompanies AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaEmpty AS JsonArray NO-UNDO.
        DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
        DEFINE VARIABLE joSelected AS JsonObject NO-UNDO.

        ASSIGN joConfig = NEW JsonObject()
               joPaths = NEW JsonObject().
        joPaths:Add("metadataRoot", "sursum-conf/metadata").
        joPaths:Add("relationsRoot", "sursum-conf/relations").
        joPaths:Add("pasoeRoot", "sursum-conf/pasoe").
        joPaths:Add("databaseCatalog", "sursum-conf/metadata/database-catalog.json").
        joPaths:Add("aliasesFile", "sursum-conf/pasoe/datasul-prod-aliases.p").

        ASSIGN jaClients = NEW JsonArray()
               joItem = NEW JsonObject().
        joItem:Add("id", "cliente-padrao").
        joItem:Add("name", "Cliente padrao").
        jaClients:Add(joItem).

        ASSIGN jaEnvironments = NEW JsonArray()
               joItem = NEW JsonObject().
        joItem:Add("id", "ambiente-local").
        joItem:Add("clientId", "cliente-padrao").
        joItem:Add("name", "Ambiente local").
        joItem:Add("pasoeBaseUrl", "http://localhost:8890/web/SursumDynamicQuery").
        joItem:Add("authMode", "none").
        joItem:Add("authorization", "").
        joItem:Add("companyIdMode", "query").
        joItem:Add("extraQueryParams", "").
        jaEnvironments:Add(joItem).

        ASSIGN jaCompanies = NEW JsonArray()
               joItem = NEW JsonObject().
        joItem:Add("id", "empresa-padrao").
        joItem:Add("clientId", "cliente-padrao").
        joItem:Add("environmentId", "ambiente-local").
        joItem:Add("name", "Empresa padrao").
        joItem:Add("code", "empresa-padrao").
        jaCompanies:Add(joItem).

        ASSIGN joSelected = NEW JsonObject().
        joSelected:Add("clientId", "cliente-padrao").
        joSelected:Add("environmentId", "ambiente-local").
        joSelected:Add("companyId", "empresa-padrao").

        joConfig:Add("version", 4).
        joConfig:Add("paths", joPaths).
        joConfig:Add("clients", jaClients).
        joConfig:Add("environments", jaEnvironments).
        joConfig:Add("companies", jaCompanies).
        ASSIGN jaEmpty = NEW JsonArray().
        joConfig:Add("physicalDatabases", jaEmpty).
        ASSIGN jaEmpty = NEW JsonArray().
        joConfig:Add("aliases", jaEmpty).
        joConfig:Add("selected", joSelected).
        RETURN joConfig.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataCacheStatus():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.
        DEFINE VARIABLE lHasCache AS LOGICAL NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = "TODOS".

        IF cDatabase = "TODOS" OR cDatabase = "ALL" THEN DO:
            ASSIGN lHasCache = NUM-DBS > 0.
            DO iDb = 1 TO NUM-DBS:
                ASSIGN cFile = THIS-OBJECT:getMetadataCacheFile(LDBNAME(iDb), "tables", "").
                FILE-INFO:FILE-NAME = cFile.
                IF FILE-INFO:FULL-PATHNAME = ? THEN
                    ASSIGN lHasCache = FALSE.
            END.
        END.
        ELSE DO:
            ASSIGN cFile = THIS-OBJECT:getMetadataCacheFile(cDatabase, "tables", "").
            FILE-INFO:FILE-NAME = cFile.
            ASSIGN lHasCache = FILE-INFO:FULL-PATHNAME <> ?.
        END.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabase).
        joRet:Add("hasCache", lHasCache).
        joRet:Add("path", cFile).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataSync():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joOptions AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaSteps AS JsonArray NO-UNDO.
        DEFINE VARIABLE joStep AS JsonObject NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lBanks AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lAliases AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lTables AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lFields AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lIndices AS LOGICAL NO-UNDO.
        DEFINE VARIABLE lViewAs AS LOGICAL NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cInclude = LC(THIS-OBJECT:getQueryValue(cQuery, "include"))
               cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database")
               cTable = THIS-OBJECT:getQueryValue(cQuery, "table").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "banco").
        IF cTable = "" THEN
            ASSIGN cTable = THIS-OBJECT:getQueryValue(cQuery, "tabela").

        IF cInclude = "" THEN
            ASSIGN cInclude = "banks,aliases,tables".

        ASSIGN lBanks = THIS-OBJECT:hasSyncOption(cInclude, "banks") OR THIS-OBJECT:hasSyncOption(cInclude, "bancos")
               lAliases = THIS-OBJECT:hasSyncOption(cInclude, "aliases") OR THIS-OBJECT:hasSyncOption(cInclude, "alias")
               lTables = THIS-OBJECT:hasSyncOption(cInclude, "tables") OR THIS-OBJECT:hasSyncOption(cInclude, "tabelas")
               lFields = THIS-OBJECT:hasSyncOption(cInclude, "fields") OR THIS-OBJECT:hasSyncOption(cInclude, "campos")
               lIndices = THIS-OBJECT:hasSyncOption(cInclude, "indices") OR THIS-OBJECT:hasSyncOption(cInclude, "indexes")
               lViewAs = THIS-OBJECT:hasSyncOption(cInclude, "view-as") OR THIS-OBJECT:hasSyncOption(cInclude, "viewas").

        ASSIGN joRet = NEW JsonObject()
               joOptions = NEW JsonObject()
               jaSteps = NEW JsonArray().

        joOptions:Add("include", cInclude).
        joOptions:Add("database", cDatabase).
        joOptions:Add("table", cTable).
        joOptions:Add("banks", lBanks).
        joOptions:Add("aliases", lAliases).
        joOptions:Add("tables", lTables).
        joOptions:Add("fields", lFields).
        joOptions:Add("indices", lIndices).
        joOptions:Add("viewAs", lViewAs).

        IF lBanks OR lAliases THEN DO:
            ASSIGN joStep = THIS-OBJECT:handleMetadataDatabaseCatalog(TRUE).
            joStep:Add("step", "database-catalog") NO-ERROR.
            jaSteps:Add(joStep).
        END.

        IF lTables THEN DO:
            ASSIGN joStep = THIS-OBJECT:handleMetadataTables().
            joStep:Add("step", "tables") NO-ERROR.
            jaSteps:Add(joStep).
        END.

        IF lFields OR lIndices OR lViewAs THEN DO:
            ASSIGN joStep = THIS-OBJECT:syncMetadataFields(cDatabase, cTable, lIndices, lViewAs).
            jaSteps:Add(joStep).
        END.

        joRet:Add("success", TRUE).
        joRet:Add("updatedAt", STRING(NOW)).
        joRet:Add("options", joOptions).
        joRet:Add("steps", jaSteps).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject syncMetadataFields(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT plIndices AS LOGICAL, INPUT plViewAs AS LOGICAL):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaUpdated AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaSkipped AS JsonArray NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cResolved AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               jaUpdated = NEW JsonArray()
               jaSkipped = NEW JsonArray()
               cDatabase = pcDatabase.

        IF cDatabase = "" OR cDatabase = ? THEN
            ASSIGN cDatabase = "TODOS".

        IF cDatabase = "TODOS" OR cDatabase = "ALL" THEN DO:
            DO iDb = 1 TO NUM-DBS:
                THIS-OBJECT:syncMetadataFieldsForDatabase(LDBNAME(iDb), THIS-OBJECT:getDatabaseDisplayName(iDb), pcTable, jaUpdated, jaSkipped).
            END.
        END.
        ELSE DO:
            ASSIGN cResolved = THIS-OBJECT:resolveDatabaseName(cDatabase)
                   cDisplay = THIS-OBJECT:getDatabaseDisplayNameByName(cDatabase).
            IF NOT THIS-OBJECT:isRelationIdentifier(cResolved) THEN
                RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cDatabase).
            THIS-OBJECT:syncMetadataFieldsForDatabase(cResolved, cDisplay, pcTable, jaUpdated, jaSkipped).
        END.

        joRet:Add("success", TRUE).
        joRet:Add("step", "fields").
        joRet:Add("database", cDatabase).
        joRet:Add("table", pcTable).
        joRet:Add("includesIndices", plIndices).
        joRet:Add("includesViewAs", plViewAs).
        joRet:Add("updatedCount", jaUpdated:Length).
        joRet:Add("skippedCount", jaSkipped:Length).
        joRet:Add("updated", jaUpdated).
        joRet:Add("skipped", jaSkipped).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE VOID syncMetadataFieldsForDatabase(INPUT pcLogicalDatabase AS CHARACTER, INPUT pcDisplayDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT-OUTPUT poUpdated AS JsonArray, INPUT-OUTPUT poSkipped AS JsonArray):
        DEFINE VARIABLE oMetadata AS DynamicMetadataService NO-UNDO.
        DEFINE VARIABLE jaTables AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE joTable AS JsonObject NO-UNDO.
        DEFINE VARIABLE joItem AS JsonObject NO-UNDO.
        DEFINE VARIABLE iTable AS INTEGER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLastUpdate AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lForceTable AS LOGICAL NO-UNDO.

        ASSIGN oMetadata = NEW DynamicMetadataService()
               lForceTable = pcTable <> "" AND pcTable <> ?.
        oMetadata:setBanco(pcLogicalDatabase).
        oMetadata:setBancoExibicao(pcDisplayDatabase).
        ASSIGN jaTables = oMetadata:getTablesJson(IF lForceTable THEN pcTable ELSE "").

        DO iTable = 1 TO jaTables:Length:
            ASSIGN joTable = jaTables:GetJsonObject(iTable)
                   cTable = THIS-OBJECT:getJsonChar(joTable, "name")
                   cLastUpdate = THIS-OBJECT:getJsonChar(joTable, "lastUpdate").

            IF lForceTable AND LC(cTable) <> LC(pcTable) THEN
                NEXT.

            IF NOT lForceTable AND NOT THIS-OBJECT:isFieldCacheOutdated(pcDisplayDatabase, cTable, cLastUpdate) THEN DO:
                ASSIGN joItem = NEW JsonObject().
                joItem:Add("database", pcDisplayDatabase).
                joItem:Add("table", cTable).
                joItem:Add("tableLastUpdate", cLastUpdate).
                joItem:Add("reason", "cache-current").
                poSkipped:Add(joItem).
                NEXT.
            END.

            ASSIGN jaFields = oMetadata:getFieldsJson(cTable).
            THIS-OBJECT:writeMetadataFieldsCacheFile(pcDisplayDatabase, cTable, jaFields, cLastUpdate).
            ASSIGN joItem = NEW JsonObject().
            joItem:Add("database", pcDisplayDatabase).
            joItem:Add("table", cTable).
            joItem:Add("tableLastUpdate", cLastUpdate).
            joItem:Add("fieldCount", jaFields:Length).
            poUpdated:Add(joItem).
        END.

        DELETE OBJECT oMetadata NO-ERROR.
    END METHOD.

    METHOD PRIVATE JsonObject handleResolveViewAs(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
        DEFINE VARIABLE joOut AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE joEnvironment AS JsonObject NO-UNDO.
        DEFINE VARIABLE iRow AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cViewAs AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cList AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cError AS CHARACTER NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /metadata/view-as/resolve").

        ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON de view-as invalido", "").

        ASSIGN jaRows = joBody:GetJsonArray("rows") NO-ERROR.
        IF NOT VALID-OBJECT(jaRows) THEN
            ASSIGN jaRows = NEW JsonArray().

        ASSIGN jaData = NEW JsonArray()
               joEnvironment = THIS-OBJECT:getViewAsResolverEnvironment(joBody).
        DO iRow = 1 TO jaRows:Length:
            ASSIGN joRow = jaRows:GetJsonObject(iRow) NO-ERROR.
            IF NOT VALID-OBJECT(joRow) THEN
                NEXT.

            ASSIGN cField = THIS-OBJECT:getJsonChar(joRow, "field").
            IF cField = "" THEN
                ASSIGN cField = THIS-OBJECT:getJsonChar(joRow, "name").
            ASSIGN cViewAs = THIS-OBJECT:getJsonChar(joRow, "viewAs").
            IF cViewAs = "" THEN
                ASSIGN cViewAs = THIS-OBJECT:getJsonChar(joRow, "view_as").

            ASSIGN cInclude = THIS-OBJECT:extractViewAsInclude(cViewAs)
                   cError = ""
                   cList = "".
            IF cInclude <> "" THEN
                ASSIGN cList = THIS-OBJECT:resolveViewAsInclude(cInclude, joEnvironment, OUTPUT cError).
            ELSE
                ASSIGN cList = THIS-OBJECT:normalizeViewAsList(cViewAs).

            ASSIGN joOut = NEW JsonObject().
            joOut:Add("field", cField).
            joOut:Add("viewAs", cViewAs).
            joOut:Add("listExpression", cList).
            joOut:Add("options", THIS-OBJECT:parseViewAsOptions(cList, THIS-OBJECT:isSingleViewAsList(cViewAs, cInclude))).
            joOut:Add("source", "PASOE").
            IF cInclude <> "" THEN DO:
                joOut:Add("include", cInclude).
                IF cError <> "" THEN
                    joOut:Add("resolverError", cError).
            END.
            jaData:Add(joOut).
        END.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("data", jaData).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject getViewAsResolverEnvironment(INPUT poBody AS JsonObject):
        DEFINE VARIABLE joEnvironment AS JsonObject NO-UNDO.

        IF VALID-OBJECT(poBody) AND poBody:Has("environment") AND NOT poBody:IsNull("environment") THEN
            ASSIGN joEnvironment = poBody:GetJsonObject("environment") NO-ERROR.
        IF NOT VALID-OBJECT(joEnvironment) THEN
            ASSIGN joEnvironment = NEW JsonObject().
        RETURN joEnvironment.
    END METHOD.

    METHOD PRIVATE LOGICAL isSingleViewAsList(INPUT pcViewAs AS CHARACTER, INPUT pcInclude AS CHARACTER):
        DEFINE VARIABLE cViewAs AS CHARACTER NO-UNDO.

        IF pcInclude <> "" THEN
            RETURN TRUE.
        ASSIGN cViewAs = LC(IF pcViewAs = ? THEN "" ELSE pcViewAs).
        IF INDEX(cViewAs, "list-item-pairs") > 0 THEN
            RETURN FALSE.
        IF INDEX(cViewAs, "list-items") > 0 OR INDEX(cViewAs, "list-item") > 0 THEN
            RETURN TRUE.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE CHARACTER extractViewAsInclude(INPUT pcViewAs AS CHARACTER):
        DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOpen AS CHARACTER NO-UNDO.

        ASSIGN cOpen = CHR(123).
        IF pcViewAs = ? OR INDEX(pcViewAs, ".i") = 0 OR INDEX(pcViewAs, cOpen) = 0 THEN
            RETURN "".

        ASSIGN cInclude = ENTRY(2, pcViewAs, cOpen) NO-ERROR.
        IF ERROR-STATUS:ERROR OR cInclude = "" OR cInclude = ? THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            RETURN "".
        END.

        ASSIGN cInclude = ENTRY(1, cInclude, ".i") NO-ERROR.
        IF ERROR-STATUS:ERROR OR cInclude = "" OR cInclude = ? THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            RETURN "".
        END.

        RETURN LC(TRIM(REPLACE(cInclude + ".i 3", "~\", "/"))).
    END METHOD.

    METHOD PRIVATE CHARACTER resolveViewAsInclude(INPUT pcInclude AS CHARACTER, INPUT poEnvironment AS JsonObject, OUTPUT pcError AS CHARACTER):
        DEFINE VARIABLE cReturn AS CHARACTER NO-UNDO.

        ASSIGN pcError = "".
        IF pcInclude = ? OR TRIM(pcInclude) = "" THEN
            RETURN "".

        IF THIS-OBJECT:useViewAsSshResolver(poEnvironment) THEN DO:
            ASSIGN cReturn = THIS-OBJECT:resolveViewAsIncludeViaSsh(pcInclude, poEnvironment, OUTPUT pcError).
            IF pcError <> "" THEN
                RETURN "".
            RETURN THIS-OBJECT:normalizeViewAsList(cReturn).
        END.

        ASSIGN cReturn = THIS-OBJECT:resolveViewAsIncludeCompiled(pcInclude, OUTPUT pcError).
        IF pcError <> "" THEN
            RETURN "".

        RETURN THIS-OBJECT:normalizeViewAsList(cReturn).
    END METHOD.

    METHOD PRIVATE CHARACTER resolveViewAsIncludeCompiled(INPUT pcInclude AS CHARACTER, OUTPUT pcError AS CHARACTER):
        DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRcode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cProgram AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cReturn AS CHARACTER NO-UNDO.

        ASSIGN pcError = "".
        ASSIGN cInclude = LC(TRIM(ENTRY(1, pcInclude, " "))) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            ASSIGN cInclude = "".
        END.
        IF cInclude = "cxinc/i01cx373.i" THEN
            RETURN "Ativo,Inativo".

        ASSIGN pcError = ""
               cRcode = SEARCH("ViewAsIncludeResolver.r").
        IF cRcode = ? THEN
            ASSIGN cRcode = SEARCH("sursum/ViewAsIncludeResolver.r").
        IF cRcode = ? THEN DO:
            ASSIGN pcError = "Resolvedor compilado ViewAsIncludeResolver.r nao encontrado. Configure SSH no ambiente ou use a importacao CSV.".
            RETURN "".
        END.
        ASSIGN cProgram = "ViewAsIncludeResolver.r".

        DO ON ERROR UNDO, THROW:
            RUN VALUE(cProgram) pcInclude.
            ASSIGN cReturn = IF RETURN-VALUE = ? THEN "" ELSE RETURN-VALUE.

            CATCH oErr AS Error:
                IF oErr:NumMessages > 0 THEN
                    ASSIGN pcError = "Falha no resolvedor compilado " + cRcode + ": " + oErr:GetMessage(1).
                ELSE
                    ASSIGN pcError = "Falha no resolvedor compilado " + cRcode + ".".
                RETURN "".
            END CATCH.
        END.

        IF TRIM(cReturn) = "" THEN
            ASSIGN pcError = "Include " + pcInclude + " nao foi resolvida pelo ViewAsIncludeResolver.r. Configure SSH no ambiente ou use a importacao CSV.".

        RETURN cReturn.
    END METHOD.

    METHOD PRIVATE LOGICAL useViewAsSshResolver(INPUT poEnvironment AS JsonObject):
        RETURN THIS-OBJECT:getJsonChar(poEnvironment, "servidor") <> ""
           AND THIS-OBJECT:getJsonChar(poEnvironment, "usuario") <> "".
    END METHOD.

    METHOD PRIVATE CHARACTER resolveViewAsIncludeViaSsh(INPUT pcInclude AS CHARACTER, INPUT poEnvironment AS JsonObject, OUTPUT pcError AS CHARACTER):
        DEFINE VARIABLE cHost AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cUser AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPassword AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cArquivoPf AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cArquivoAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cJob AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLocalOut AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRemoteIn AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRemoteOut AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRemoteScript AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRemoteCommand AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cCommand AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOutput AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLine AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cError AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cList AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLine AS INTEGER NO-UNDO.

        ASSIGN pcError = ""
               cHost = THIS-OBJECT:getJsonChar(poEnvironment, "servidor")
               cUser = THIS-OBJECT:getJsonChar(poEnvironment, "usuario")
               cPassword = THIS-OBJECT:getJsonChar(poEnvironment, "senha")
               cArquivoPf = THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getJsonChar(poEnvironment, "arquivoPf"), THIS-OBJECT:getJsonChar(poEnvironment, "arquivo_pf"))
               cArquivoAlias = THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getJsonChar(poEnvironment, "arquivoAlias"), THIS-OBJECT:getJsonChar(poEnvironment, "arquivo_alias")).

        IF NOT THIS-OBJECT:isSafeShellText(cHost)
            OR NOT THIS-OBJECT:isSafeShellText(cUser)
            OR NOT THIS-OBJECT:isSafeShellText(cPassword)
            OR NOT THIS-OBJECT:isSafeShellText(cArquivoPf)
            OR NOT THIS-OBJECT:isSafeShellText(cArquivoAlias)
            OR NOT THIS-OBJECT:isSafeShellText(pcInclude) THEN DO:
            ASSIGN pcError = "Configuracao SSH contem caracteres nao suportados pelo resolvedor PASOE.".
            RETURN "".
        END.

        ASSIGN cJob = "viewas_" + REPLACE(GUID(GENERATE-UUID), "-", "")
               cLocalOut = SESSION:TEMP-DIRECTORY + cJob + ".out"
               cRemoteIn = "C:/opencode/motor-progress/temp/" + cJob + ".in"
               cRemoteOut = "C:/opencode/motor-progress/temp/" + cJob + ".out".

        ASSIGN cRemoteScript =
            "Set-Location " + THIS-OBJECT:psQuote("C:\opencode\motor-progress") + "; "
          + "$in=" + THIS-OBJECT:psQuote(cRemoteIn) + "; "
          + "$out=" + THIS-OBJECT:psQuote(cRemoteOut) + "; "
          + "Set-Content -LiteralPath $in -Value " + THIS-OBJECT:psQuote(pcInclude) + " -Encoding ASCII; "
          + "& " + THIS-OBJECT:psQuote("C:\Progress_12\OE\bin\_progres.exe")
          + " -b "
          + (IF cArquivoPf <> "" THEN "-pf " + THIS-OBJECT:psQuote(cArquivoPf) ELSE "-db " + THIS-OBJECT:psQuote("C:\opencode\motor-progress\db\sports2000") + " -1 -ld DICTDB")
          + " -param ($in + " + THIS-OBJECT:psQuote("|") + " + $out + " + THIS-OBJECT:psQuote("|") + " + " + THIS-OBJECT:psQuote(cArquivoAlias) + ")"
          + " -p " + THIS-OBJECT:psQuote("C:\opencode\motor-progress\sursum-api\sursum\RunViewAsIncludeResolver.p") + "; "
          + "if (Test-Path -LiteralPath $out) ~{ Get-Content -Raw -LiteralPath $out ~}; "
          + "Remove-Item -Force $in,$out -ErrorAction SilentlyContinue".

        ASSIGN cRemoteCommand = "powershell -NoProfile -ExecutionPolicy Bypass -Command " + THIS-OBJECT:commandQuote(cRemoteScript)
               cCommand = "".
        IF cPassword <> "" THEN
            ASSIGN cCommand = "sshpass -p " + THIS-OBJECT:shellQuote(cPassword) + " ".
        ASSIGN cCommand = cCommand
               + "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=15 "
               + THIS-OBJECT:shellQuote(cUser + "@" + cHost) + " "
               + THIS-OBJECT:shellQuote(cRemoteCommand).

        ASSIGN cOutput = THIS-OBJECT:runShellCommand(cCommand, cLocalOut, OUTPUT cError).
        OS-DELETE VALUE(cLocalOut) NO-ERROR.
        IF cError <> "" THEN DO:
            ASSIGN pcError = cError.
            RETURN "".
        END.

        DO iLine = NUM-ENTRIES(cOutput, CHR(10)) TO 1 BY -1:
            ASSIGN cLine = TRIM(REPLACE(ENTRY(iLine, cOutput, CHR(10)), CHR(13), "")).
            IF INDEX(cLine, CHR(1)) = 0 THEN
                NEXT.
            ASSIGN cError = IF NUM-ENTRIES(cLine, CHR(1)) >= 2 THEN ENTRY(2, cLine, CHR(1)) ELSE ""
                   cList = IF NUM-ENTRIES(cLine, CHR(1)) >= 3 THEN ENTRY(3, cLine, CHR(1)) ELSE "".
            IF cError <> "" THEN DO:
                ASSIGN pcError = cError.
                RETURN "".
            END.
            RETURN cList.
        END.

        ASSIGN pcError = "Resolvedor SSH nao retornou lista para " + pcInclude + ". Saida: " + THIS-OBJECT:compactShellOutput(cOutput).
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER runShellCommand(INPUT pcCommand AS CHARACTER, INPUT pcOutputFile AS CHARACTER, OUTPUT pcError AS CHARACTER):
        DEFINE VARIABLE cWrapped AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOutput AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLine AS CHARACTER NO-UNDO.

        ASSIGN pcError = ""
               cOutput = ""
               cWrapped = pcCommand + " > " + THIS-OBJECT:shellQuote(pcOutputFile) + " 2>&1".

        OS-DELETE VALUE(pcOutputFile) NO-ERROR.
        OS-COMMAND SILENT VALUE(cWrapped).
        IF ERROR-STATUS:ERROR THEN DO:
            IF ERROR-STATUS:NUM-MESSAGES > 0 THEN
                ASSIGN pcError = ERROR-STATUS:GET-MESSAGE(1).
            ELSE
                ASSIGN pcError = "Falha ao executar comando OS-COMMAND.".
            ERROR-STATUS:ERROR = FALSE.
            RETURN "".
        END.

        FILE-INFO:FILE-NAME = pcOutputFile.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            RETURN "".

        INPUT FROM VALUE(pcOutputFile) NO-ECHO.
        REPEAT:
            IMPORT UNFORMATTED cLine.
            ASSIGN cOutput = cOutput + cLine + CHR(10).
        END.
        INPUT CLOSE.

        RETURN cOutput.
    END METHOD.

    METHOD PRIVATE CHARACTER shellQuote(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN cValue = IF pcValue = ? THEN "" ELSE pcValue
               cValue = REPLACE(cValue, '"', '\"')
               cValue = REPLACE(cValue, "$", "\$")
               cValue = REPLACE(cValue, "`", "\`").
        RETURN '"' + cValue + '"'.
    END METHOD.

    METHOD PRIVATE CHARACTER commandQuote(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN cValue = IF pcValue = ? THEN "" ELSE pcValue
               cValue = REPLACE(cValue, '"', '\"').
        RETURN '"' + cValue + '"'.
    END METHOD.

    METHOD PRIVATE CHARACTER psQuote(INPUT pcValue AS CHARACTER):
        IF pcValue = ? THEN
            RETURN "''".
        RETURN "'" + REPLACE(pcValue, "'", "''") + "'".
    END METHOD.

    METHOD PRIVATE LOGICAL isSafeShellText(INPUT pcValue AS CHARACTER):
        IF pcValue = ? THEN
            RETURN TRUE.
        RETURN INDEX(pcValue, CHR(10)) = 0
           AND INDEX(pcValue, CHR(13)) = 0.
    END METHOD.

    METHOD PRIVATE CHARACTER compactShellOutput(INPUT pcOutput AS CHARACTER):
        DEFINE VARIABLE cOutput AS CHARACTER NO-UNDO.

        ASSIGN cOutput = TRIM(REPLACE(REPLACE(IF pcOutput = ? THEN "" ELSE pcOutput, CHR(13), " "), CHR(10), " ")).
        IF cOutput = "" THEN
            RETURN "sem saida".
        IF LENGTH(cOutput) > 1800 THEN
            RETURN SUBSTRING(cOutput, 1, 1800) + "...".
        RETURN cOutput.
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeViewAsList(INPUT pcText AS CHARACTER):
        DEFINE VARIABLE cText AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLower AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
        DEFINE VARIABLE cNeedle AS CHARACTER NO-UNDO.

        IF pcText = ? THEN
            RETURN "".

        ASSIGN cText = TRIM(pcText)
               cLower = LC(cText).

        ASSIGN iPos = INDEX(cLower, "radio-buttons").
        IF iPos > 0 THEN
            ASSIGN cText = TRIM(SUBSTRING(cText, iPos + LENGTH("radio-buttons"))).
        ELSE DO:
            ASSIGN iPos = INDEX(cLower, "list-item-pairs").
            IF iPos > 0 THEN
                ASSIGN cText = TRIM(SUBSTRING(cText, iPos + LENGTH("list-item-pairs"))).
            ELSE DO:
                ASSIGN iPos = INDEX(cLower, "list-items").
                ASSIGN cNeedle = "list-items".
                IF iPos = 0 THEN DO:
                    ASSIGN iPos = INDEX(cLower, "list-item").
                    ASSIGN cNeedle = "list-item".
                END.
                IF iPos > 0 THEN
                    ASSIGN cText = TRIM(SUBSTRING(cText, iPos + LENGTH(cNeedle))).
            END.
        END.

        IF INDEX(LC(cText), "toggle-box") > 0 OR INDEX(LC(cText), "editor") > 0 THEN
            RETURN "".
        IF LENGTH(cText) >= 2 AND SUBSTRING(cText, 1, 1) = CHR(123) AND SUBSTRING(cText, LENGTH(cText), 1) = CHR(125) THEN
            RETURN "".
        IF cText = "?" THEN
            RETURN "".

        RETURN TRIM(cText).
    END METHOD.

    METHOD PRIVATE JsonArray parseViewAsOptions(INPUT pcList AS CHARACTER, INPUT plSingleItems AS LOGICAL):
        DEFINE VARIABLE jaOptions AS JsonArray NO-UNDO.
        DEFINE VARIABLE joOption AS JsonObject NO-UNDO.
        DEFINE VARIABLE iItem AS INTEGER NO-UNDO.
        DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.
        DEFINE VARIABLE cLabel AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN jaOptions = NEW JsonArray().
        IF pcList = ? OR TRIM(pcList) = "" THEN
            RETURN jaOptions.

        ASSIGN iTotal = NUM-ENTRIES(pcList).
        IF plSingleItems OR iTotal MODULO 2 <> 0 THEN DO:
            DO iItem = 1 TO iTotal:
                ASSIGN cLabel = THIS-OBJECT:cleanViewAsToken(ENTRY(iItem, pcList)).
                IF cLabel = "" THEN
                    NEXT.
                ASSIGN joOption = NEW JsonObject().
                joOption:Add("label", cLabel).
                joOption:Add("value", cLabel).
                jaOptions:Add(joOption).
            END.
            RETURN jaOptions.
        END.

        DO iItem = 1 TO iTotal BY 2:
            ASSIGN cLabel = THIS-OBJECT:cleanViewAsToken(ENTRY(iItem, pcList))
                   cValue = IF iItem + 1 <= iTotal THEN THIS-OBJECT:cleanViewAsToken(ENTRY(iItem + 1, pcList)) ELSE cLabel.
            IF cLabel = "" AND cValue = "" THEN
                NEXT.
            ASSIGN joOption = NEW JsonObject().
            joOption:Add("label", cLabel).
            joOption:Add("value", cValue).
            jaOptions:Add(joOption).
        END.
        RETURN jaOptions.
    END METHOD.

    METHOD PRIVATE CHARACTER cleanViewAsToken(INPUT pcToken AS CHARACTER):
        DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.

        IF pcToken = ? THEN
            RETURN "".
        ASSIGN cToken = TRIM(pcToken)
               cToken = REPLACE(cToken, '"', "")
               cToken = REPLACE(cToken, "'", "")
               cToken = REPLACE(cToken, "/", "").
        RETURN TRIM(cToken).
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataDatabases():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE joDb AS JsonObject NO-UNDO.
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               jaData = NEW JsonArray().

        DO iDb = 1 TO NUM-DBS:
            ASSIGN joDb = NEW JsonObject().
            joDb:Add("name", THIS-OBJECT:getDatabaseDisplayName(iDb)).
            joDb:Add("logicalName", LDBNAME(iDb)).
            joDb:Add("displayName", THIS-OBJECT:getDatabaseDisplayName(iDb)).
            joDb:Add("physicalName", PDBNAME(iDb)).
            joDb:Add("type", DBTYPE(iDb)).
            jaData:Add(joDb).
        END.

        joRet:Add("success", TRUE).
        joRet:Add("data", jaData).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataDatabaseCatalog(INPUT plRefresh AS LOGICAL):
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joCatalog AS JsonObject NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:getDatabaseCatalogFile().
        FILE-INFO:FILE-NAME = cFile.

        IF NOT plRefresh AND FILE-INFO:FULL-PATHNAME <> ? THEN DO:
            COPY-LOB FROM FILE cFile TO lcJson NO-ERROR.
            IF NOT ERROR-STATUS:ERROR THEN DO:
                ASSIGN cJson = STRING(lcJson) NO-ERROR.
                ASSIGN oParser = NEW ObjectModelParser().
                ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
                ASSIGN joCatalog = CAST(oConstruct, JsonObject) NO-ERROR.
                DELETE OBJECT oParser NO-ERROR.
                IF VALID-OBJECT(joCatalog) THEN
                    RETURN joCatalog.
            END.
        END.

        RETURN THIS-OBJECT:syncMetadataDatabaseCatalog().
    END METHOD.

    METHOD PRIVATE JsonObject syncMetadataDatabaseCatalog():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaPhysical AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaAliases AS JsonArray NO-UNDO.
        DEFINE VARIABLE joDb AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPhysical AS JsonObject NO-UNDO.
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.
        DEFINE VARIABLE cPhysicalId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLogical AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPhysical AS CHARACTER NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               jaData = NEW JsonArray()
               jaPhysical = NEW JsonArray()
               jaAliases = NEW JsonArray().

        DO iDb = 1 TO NUM-DBS:
            ASSIGN cLogical = LDBNAME(iDb)
                   cPhysical = PDBNAME(iDb)
                   cDisplay = THIS-OBJECT:getDatabaseDisplayName(iDb)
                   cPhysicalId = THIS-OBJECT:databaseCatalogId(cPhysical, cLogical).

            ASSIGN joPhysical = NEW JsonObject().
            joPhysical:Add("id", cPhysicalId).
            joPhysical:Add("name", cDisplay).
            joPhysical:Add("logicalName", cLogical).
            joPhysical:Add("displayName", cDisplay).
            joPhysical:Add("physicalName", cPhysical).
            joPhysical:Add("type", DBTYPE(iDb)).
            joPhysical:Add("status", "active").
            jaPhysical:Add(joPhysical).

            ASSIGN joDb = NEW JsonObject().
            joDb:Add("id", cPhysicalId).
            joDb:Add("physicalId", cPhysicalId).
            joDb:Add("name", cDisplay).
            joDb:Add("logicalName", cLogical).
            joDb:Add("displayName", cDisplay).
            joDb:Add("physicalName", cPhysical).
            joDb:Add("type", DBTYPE(iDb)).
            joDb:Add("status", "active").
            jaData:Add(joDb).

            THIS-OBJECT:addAliasToCatalog(jaAliases, cLogical, cPhysicalId, "connected").
        END.

        THIS-OBJECT:addAliasesFromFile(jaAliases, jaPhysical).
        THIS-OBJECT:addAliasRowsToData(jaData, jaAliases, jaPhysical).

        joRet:Add("success", TRUE).
        joRet:Add("version", 1).
        joRet:Add("updatedAt", STRING(NOW)).
        joRet:Add("path", THIS-OBJECT:getDatabaseCatalogFile()).
        joRet:Add("data", jaData).
        joRet:Add("physicalDatabases", jaPhysical).
        joRet:Add("aliases", jaAliases).

        THIS-OBJECT:writeDatabaseCatalogFile(joRet).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE VOID addAliasesFromFile(INPUT-OUTPUT poAliases AS JsonArray, INPUT poPhysical AS JsonArray):
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLine AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cNorm AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPhysicalId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iEntry AS INTEGER NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:getConfiguredFile("aliasesFile", "sursum-conf/pasoe/datasul-prod-aliases.p").
        FILE-INFO:FILE-NAME = cFile.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            RETURN.

        INPUT FROM VALUE(cFile).

        REPEAT:
            IMPORT UNFORMATTED cLine.
            ASSIGN cNorm = THIS-OBJECT:compactSpaces(REPLACE(TRIM(cLine), CHR(9), " "))
                   cAlias = ""
                   cDatabase = "".
            IF INDEX(LC(cNorm), "create ") <> 1 OR INDEX(LC(cNorm), " alias ") = 0 THEN
                NEXT.

            DO iEntry = 1 TO NUM-ENTRIES(cNorm, " "):
                IF LC(ENTRY(iEntry, cNorm, " ")) = "alias" AND iEntry < NUM-ENTRIES(cNorm, " ") THEN
                    ASSIGN cAlias = ENTRY(iEntry + 1, cNorm, " ").
                IF LC(ENTRY(iEntry, cNorm, " ")) = "database" AND iEntry < NUM-ENTRIES(cNorm, " ") THEN
                    ASSIGN cDatabase = ENTRY(iEntry + 1, cNorm, " ").
            END.

            IF cAlias = "" OR cDatabase = "" THEN
                NEXT.

            ASSIGN cPhysicalId = THIS-OBJECT:findPhysicalId(poPhysical, cDatabase).
            IF cPhysicalId <> "" THEN
                THIS-OBJECT:addAliasToCatalog(poAliases, cAlias, cPhysicalId, "alias-file").
        END.

        INPUT CLOSE.
    END METHOD.

    METHOD PRIVATE VOID addAliasRowsToData(INPUT-OUTPUT poData AS JsonArray, INPUT poAliases AS JsonArray, INPUT poPhysical AS JsonArray):
        DEFINE VARIABLE joAlias AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPhysical AS JsonObject NO-UNDO.
        DEFINE VARIABLE joDb AS JsonObject NO-UNDO.
        DEFINE VARIABLE iAlias AS INTEGER NO-UNDO.
        DEFINE VARIABLE cAlias AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPhysicalId AS CHARACTER NO-UNDO.

        DO iAlias = 1 TO poAliases:Length:
            ASSIGN joAlias = poAliases:GetJsonObject(iAlias)
                   cAlias = THIS-OBJECT:getJsonChar(joAlias, "alias")
                   cPhysicalId = THIS-OBJECT:getJsonChar(joAlias, "physicalId").
            IF cAlias = "" OR THIS-OBJECT:dataHasDatabase(poData, cAlias) THEN
                NEXT.

            ASSIGN joPhysical = THIS-OBJECT:getPhysicalById(poPhysical, cPhysicalId).
            ASSIGN joDb = NEW JsonObject().
            joDb:Add("id", "alias-" + LC(cAlias)).
            joDb:Add("physicalId", cPhysicalId).
            joDb:Add("name", cAlias).
            joDb:Add("logicalName", cAlias).
            joDb:Add("displayName", cAlias).
            joDb:Add("physicalName", IF VALID-OBJECT(joPhysical) THEN THIS-OBJECT:getJsonChar(joPhysical, "physicalName") ELSE "").
            joDb:Add("type", IF VALID-OBJECT(joPhysical) THEN THIS-OBJECT:getJsonChar(joPhysical, "type") ELSE "ALIAS").
            joDb:Add("source", THIS-OBJECT:getJsonChar(joAlias, "source")).
            joDb:Add("status", "active").
            poData:Add(joDb).
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL dataHasDatabase(INPUT poData AS JsonArray, INPUT pcDatabase AS CHARACTER):
        DEFINE VARIABLE joDb AS JsonObject NO-UNDO.
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.

        DO iDb = 1 TO poData:Length:
            ASSIGN joDb = poData:GetJsonObject(iDb).
            IF LC(THIS-OBJECT:getJsonChar(joDb, "name")) = LC(pcDatabase)
               OR LC(THIS-OBJECT:getJsonChar(joDb, "logicalName")) = LC(pcDatabase) THEN
                RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE JsonObject getPhysicalById(INPUT poPhysical AS JsonArray, INPUT pcPhysicalId AS CHARACTER):
        DEFINE VARIABLE joPhysical AS JsonObject NO-UNDO.
        DEFINE VARIABLE iPhysical AS INTEGER NO-UNDO.

        DO iPhysical = 1 TO poPhysical:Length:
            ASSIGN joPhysical = poPhysical:GetJsonObject(iPhysical).
            IF THIS-OBJECT:getJsonChar(joPhysical, "id") = pcPhysicalId THEN
                RETURN joPhysical.
        END.
        RETURN ?.
    END METHOD.

    METHOD PRIVATE VOID addAliasToCatalog(INPUT-OUTPUT poAliases AS JsonArray, INPUT pcAlias AS CHARACTER, INPUT pcPhysicalId AS CHARACTER, INPUT pcSource AS CHARACTER):
        DEFINE VARIABLE joAlias AS JsonObject NO-UNDO.
        DEFINE VARIABLE iAlias AS INTEGER NO-UNDO.

        IF pcAlias = "" OR pcPhysicalId = "" THEN
            RETURN.

        DO iAlias = 1 TO poAliases:Length:
            ASSIGN joAlias = poAliases:GetJsonObject(iAlias).
            IF LC(THIS-OBJECT:getJsonChar(joAlias, "alias")) = LC(pcAlias) THEN
                RETURN.
        END.

        ASSIGN joAlias = NEW JsonObject().
        joAlias:Add("physicalId", pcPhysicalId).
        joAlias:Add("alias", pcAlias).
        joAlias:Add("name", pcAlias).
        joAlias:Add("source", pcSource).
        joAlias:Add("status", "active").
        poAliases:Add(joAlias).
    END METHOD.

    METHOD PRIVATE CHARACTER findPhysicalId(INPUT poPhysical AS JsonArray, INPUT pcDatabase AS CHARACTER):
        DEFINE VARIABLE joPhysical AS JsonObject NO-UNDO.
        DEFINE VARIABLE iPhysical AS INTEGER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.

        ASSIGN cDatabase = LC(pcDatabase).
        DO iPhysical = 1 TO poPhysical:Length:
            ASSIGN joPhysical = poPhysical:GetJsonObject(iPhysical).
            IF LC(THIS-OBJECT:getJsonChar(joPhysical, "logicalName")) = cDatabase
               OR LC(THIS-OBJECT:getJsonChar(joPhysical, "displayName")) = cDatabase
               OR LC(THIS-OBJECT:getJsonChar(joPhysical, "name")) = cDatabase THEN
                RETURN THIS-OBJECT:getJsonChar(joPhysical, "id").
        END.

        RETURN "".
    END METHOD.

    METHOD PRIVATE VOID writeDatabaseCatalogFile(INPUT poCatalog AS JsonObject):
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF NOT VALID-OBJECT(poCatalog) THEN
            RETURN.

        FIX-CODEPAGE(lcJson) = "UTF-8".
        ASSIGN cBase = THIS-OBJECT:getConfiguredRoot("metadataRoot", "sursum-conf/metadata")
               cFile = THIS-OBJECT:getDatabaseCatalogFile().
        FILE-INFO:FILE-NAME = cBase.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            OS-CREATE-DIR VALUE(cBase) NO-ERROR.

        poCatalog:Write(lcJson, TRUE).
        COPY-LOB FROM lcJson TO FILE cFile NO-ERROR.
    END METHOD.

    METHOD PRIVATE CHARACTER getDatabaseCatalogFile():
        RETURN THIS-OBJECT:getConfiguredFile("databaseCatalog", "sursum-conf/metadata/database-catalog.json").
    END METHOD.

    METHOD PRIVATE CHARACTER compactSpaces(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN cValue = pcValue.
        DO WHILE INDEX(cValue, "  ") > 0:
            ASSIGN cValue = REPLACE(cValue, "  ", " ").
        END.
        RETURN cValue.
    END METHOD.

    METHOD PRIVATE CHARACTER databaseCatalogId(INPUT pcPhysicalName AS CHARACTER, INPUT pcLogicalName AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN cValue = LC(pcPhysicalName).
        IF cValue = "" OR cValue = ? THEN
            ASSIGN cValue = LC(pcLogicalName).
        ASSIGN cValue = REPLACE(cValue, "~\", "-")
               cValue = REPLACE(cValue, "/", "-")
               cValue = REPLACE(cValue, ":", "")
               cValue = REPLACE(cValue, " ", "-")
               cValue = REPLACE(cValue, ".", "-").
        DO WHILE INDEX(cValue, "--") > 0:
            ASSIGN cValue = REPLACE(cValue, "--", "-").
        END.
        IF cValue = "" THEN
            ASSIGN cValue = "database".
        RETURN cValue.
    END METHOD.

    METHOD PRIVATE JsonObject handleDrain():
        DEFINE VARIABLE oOptions AS DynamicQueryWorkerOptions NO-UNDO.
        DEFINE VARIABLE oWorker AS DynamicQueryWorkerService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN oOptions = NEW DynamicQueryWorkerOptions()
               oWorker = NEW DynamicQueryWorkerService().

        oOptions:setExecutionMode("PASOE").
        oOptions:setWorkerName("pasoe-web-drain").
        oOptions:setBatchSize(10).
        oOptions:setOutputDirectory(THIS-OBJECT:getConfiguredRoot("jobOutputRoot", "output/jobs")).

        ASSIGN joRet = oWorker:drain(oOptions).

        DELETE OBJECT oOptions NO-ERROR.
        DELETE OBJECT oWorker NO-ERROR.

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleGetStatus(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        IF pcJobId = "" THEN
            RETURN THIS-OBJECT:buildError("JOB_ID_REQUIRED", "jobId obrigatorio", "").

        ASSIGN oAsync = NEW DynamicQueryAsyncService().
        ASSIGN joRet = oAsync:getStatus(pcJobId).
        DELETE OBJECT oAsync NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleGetResult(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE oRest AS DynamicQueryRestResource NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        IF pcJobId = "" THEN
            RETURN THIS-OBJECT:buildError("JOB_ID_REQUIRED", "jobId obrigatorio", "").

        ASSIGN oRest = NEW DynamicQueryRestResource().
        ASSIGN joRet = oRest:getJobResult(pcJobId).
        DELETE OBJECT oRest NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleTableBrowse(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joCursor AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaFieldsIn AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaKeyFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
        DEFINE VARIABLE joNextCursor AS JsonObject NO-UNDO.
        DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabaseDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFullTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDirection AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cCursorWhere AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFilterWhere AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFilterError AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPageSize AS INTEGER NO-UNDO.
        DEFINE VARIABLE iRead AS INTEGER NO-UNDO.
        DEFINE VARIABLE lHasMore AS LOGICAL NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /table-browse").

        ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON de navegacao invalido", "").

        ASSIGN cDatabase = THIS-OBJECT:getJsonChar(joBody, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getJsonChar(joBody, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        ASSIGN cDatabaseDisplay = cDatabase
               cDatabase = THIS-OBJECT:resolveDatabaseName(cDatabase)
               cTable = THIS-OBJECT:getJsonChar(joBody, "table").
        IF cTable = "" THEN
            ASSIGN cTable = THIS-OBJECT:getJsonChar(joBody, "tabela").
        IF NOT THIS-OBJECT:isRelationIdentifier(cDatabase) OR NOT THIS-OBJECT:isRelationIdentifier(cTable) THEN
            RETURN THIS-OBJECT:buildError("BROWSE_TABLE_INVALID", "Banco ou tabela invalido", cDatabase + "." + cTable).

        ASSIGN iPageSize = 50 NO-ERROR.
        IF joBody:Has("pageSize") AND NOT joBody:IsNull("pageSize") THEN
            ASSIGN iPageSize = joBody:GetInteger("pageSize") NO-ERROR.
        IF iPageSize < 1 THEN
            ASSIGN iPageSize = 50.

        ASSIGN cDirection = CAPS(THIS-OBJECT:getJsonChar(joBody, "direction")).
        IF cDirection = "" THEN
            ASSIGN cDirection = "ASC".
        IF cDirection <> "ASC" AND cDirection <> "DESC" THEN
            RETURN THIS-OBJECT:buildError("BROWSE_DIRECTION_INVALID", "Direcao deve ser ASC ou DESC", cDirection).

        EMPTY TEMP-TABLE ttBrowseKey.
        EMPTY TEMP-TABLE ttBrowseField.

        IF NOT THIS-OBJECT:loadBrowseKey(cDatabase, cTable) THEN
            RETURN THIS-OBJECT:buildError("BROWSE_KEY_NOT_FOUND", "Nenhum indice ativo adequado encontrado para navegacao", cDatabase + "." + cTable).

        IF joBody:Has("fields") AND NOT joBody:IsNull("fields") THEN
            ASSIGN jaFieldsIn = joBody:GetJsonArray("fields") NO-ERROR.
        THIS-OBJECT:loadBrowseFields(cDatabase, cTable, jaFieldsIn).
        IF NOT CAN-FIND(FIRST ttBrowseField) THEN
            RETURN THIS-OBJECT:buildError("BROWSE_FIELDS_NOT_FOUND", "Nenhum campo valido encontrado para navegacao", cDatabase + "." + cTable).

        IF joBody:Has("cursor") AND NOT joBody:IsNull("cursor") THEN
            ASSIGN joCursor = joBody:GetJsonObject("cursor") NO-ERROR.
        ASSIGN cCursorWhere = THIS-OBJECT:buildBrowseCursorWhere(cDatabase, cTable, joCursor, cDirection).
        IF cCursorWhere = ? THEN
            RETURN THIS-OBJECT:buildError("BROWSE_CURSOR_INVALID", "Cursor invalido para a chave selecionada", cTable).
        ASSIGN cFilterWhere = THIS-OBJECT:buildBrowseFiltersWhere(cDatabase, cTable, joBody, OUTPUT cFilterError).
        IF cFilterWhere = ? THEN
            RETURN THIS-OBJECT:buildError("BROWSE_FILTER_INVALID", "Filtro invalido para navegacao", cFilterError).
        IF cFilterWhere <> "" AND cCursorWhere <> "" THEN
            ASSIGN cWhere = "(" + cFilterWhere + ") AND (" + cCursorWhere + ")".
        ELSE
            ASSIGN cWhere = IF cFilterWhere <> "" THEN cFilterWhere ELSE cCursorWhere.

        ASSIGN cFullTable = cDatabase + "." + cTable.
        CREATE BUFFER hBuffer FOR TABLE cFullTable NO-ERROR.
        IF NOT VALID-HANDLE(hBuffer) THEN
            RETURN THIS-OBJECT:buildError("BROWSE_TABLE_NOT_FOUND", "Tabela nao encontrada", cFullTable).
        THIS-OBJECT:prepareBrowseHandles(hBuffer).

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hBuffer).
        ASSIGN cPrepare = "FOR EACH " + cFullTable + " NO-LOCK".
        IF cWhere <> "" THEN
            ASSIGN cPrepare = cPrepare + " WHERE " + cWhere.
        ASSIGN cPrepare = cPrepare + THIS-OBJECT:buildBrowseOrder(cDatabase, cTable, cDirection).

        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hBuffer NO-ERROR.
            RETURN THIS-OBJECT:buildError("BROWSE_QUERY_ERROR", ERROR-STATUS:GET-MESSAGE(1), cPrepare).
        END.

        ASSIGN jaData = NEW JsonArray().
        hQuery:QUERY-OPEN() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hBuffer NO-ERROR.
            RETURN THIS-OBJECT:buildError("BROWSE_QUERY_ERROR", ERROR-STATUS:GET-MESSAGE(1), cPrepare).
        END.

        hQuery:GET-FIRST().
        DO WHILE NOT hQuery:QUERY-OFF-END:
            ASSIGN iRead = iRead + 1.
            IF iRead > iPageSize THEN DO:
                ASSIGN lHasMore = TRUE.
                LEAVE.
            END.
            ASSIGN joRow = THIS-OBJECT:buildBrowseRow(hBuffer).
            jaData:Add(joRow).
            ASSIGN joNextCursor = THIS-OBJECT:buildBrowseCursor(hBuffer).
            hQuery:GET-NEXT().
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hBuffer NO-ERROR.

        ASSIGN jaKeyFields = THIS-OBJECT:buildBrowseKeyFieldsJson(cDirection)
               jaFields = THIS-OBJECT:buildBrowseFieldsJson()
               joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabaseDisplay).
        joRet:Add("table", cTable).
        joRet:Add("direction", cDirection).
        joRet:Add("pageSize", iPageSize).
        joRet:Add("recordsReturned", jaData:Length).
        joRet:Add("hasMore", lHasMore).
        joRet:Add("keyFields", jaKeyFields).
        joRet:Add("fields", jaFields).
        joRet:Add("data", jaData).
        IF VALID-OBJECT(joNextCursor) THEN
            joRet:Add("nextCursor", joNextCursor).
        ELSE
            joRet:Add("nextCursor", NEW JsonObject()).
        joRet:Add("strategy", "KEYSET_CURSOR").
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleCount():
        DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE iOpenMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResultsMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iTotalMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResults AS INTEGER NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFullTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database")
               cTable = THIS-OBJECT:getQueryValue(cQuery, "table").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        IF cTable = "" THEN
            RETURN THIS-OBJECT:buildError("COUNT_TABLE_REQUIRED", "Informe a tabela da contagem", "table").
        IF NOT THIS-OBJECT:isRelationIdentifier(cDatabase) OR NOT THIS-OBJECT:isRelationIdentifier(cTable) THEN
            RETURN THIS-OBJECT:buildError("COUNT_TABLE_INVALID", "Banco ou tabela invalido", cDatabase + "." + cTable).

        ASSIGN cFullTable = cDatabase + "." + cTable.
        CREATE BUFFER hBuffer FOR TABLE cFullTable NO-ERROR.
        IF NOT VALID-HANDLE(hBuffer) THEN
            RETURN THIS-OBJECT:buildError("COUNT_TABLE_NOT_FOUND", "Tabela de contagem nao encontrada", cFullTable).

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hBuffer).
        ASSIGN cPrepare = "PRESELECT EACH " + cFullTable + " NO-LOCK".

        ETIME(TRUE).
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hBuffer NO-ERROR.
            RETURN THIS-OBJECT:buildError("COUNT_QUERY_ERROR", ERROR-STATUS:GET-MESSAGE(1), cPrepare).
        END.

        hQuery:QUERY-OPEN() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hBuffer NO-ERROR.
            RETURN THIS-OBJECT:buildError("COUNT_QUERY_ERROR", ERROR-STATUS:GET-MESSAGE(1), cPrepare).
        END.
        ASSIGN iOpenMs = ETIME.

        ETIME(TRUE).
        ASSIGN iNumResults = hQuery:NUM-RESULTS.
        ASSIGN iNumResultsMs = ETIME
               iTotalMs = iOpenMs + iNumResultsMs.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hBuffer NO-ERROR.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("runtime", "PASOE-WEB").
        joRet:Add("database", cDatabase).
        joRet:Add("table", cTable).
        joRet:Add("physicalTable", cFullTable).
        joRet:Add("count", iNumResults).
        joRet:Add("openQueryElapsedMs", iOpenMs).
        joRet:Add("numResultsElapsedMs", iNumResultsMs).
        joRet:Add("totalElapsedMs", iTotalMs).
        joRet:Add("strategy", "PRESELECT_NUM_RESULTS").
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleRecordCountBenchmark():
        DEFINE VARIABLE hBuffer AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE iCount AS INT64 NO-UNDO.
        DEFINE VARIABLE iForEachMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iOpenMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResultsMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResults AS INTEGER NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joForEach AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPreselect AS JsonObject NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database")
               cTable = THIS-OBJECT:getQueryValue(cQuery, "table").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        IF cTable = "" THEN
            RETURN THIS-OBJECT:buildError("BENCHMARK_TABLE_REQUIRED", "Informe a tabela do benchmark", "table").
        IF NOT THIS-OBJECT:isRelationIdentifier(cDatabase) OR NOT THIS-OBJECT:isRelationIdentifier(cTable) THEN
            RETURN THIS-OBJECT:buildError("BENCHMARK_TABLE_INVALID", "Banco ou tabela invalido", cDatabase + "." + cTable).

        ASSIGN cTable = cDatabase + "." + cTable.
        CREATE BUFFER hBuffer FOR TABLE cTable NO-ERROR.
        IF NOT VALID-HANDLE(hBuffer) THEN
            RETURN THIS-OBJECT:buildError("BENCHMARK_TABLE_NOT_FOUND", "Tabela de benchmark nao encontrada", cTable).

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hBuffer).
        ASSIGN cPrepare = "FOR EACH " + cTable + " NO-LOCK".

        ETIME(TRUE).
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hBuffer NO-ERROR.
            RETURN THIS-OBJECT:buildError("BENCHMARK_QUERY_ERROR", ERROR-STATUS:GET-MESSAGE(1), cPrepare).
        END.
        hQuery:QUERY-OPEN().
        hQuery:GET-FIRST().
        DO WHILE NOT hQuery:QUERY-OFF-END:
            ASSIGN iCount = iCount + 1.
            hQuery:GET-NEXT().
        END.
        hQuery:QUERY-CLOSE().
        ASSIGN iForEachMs = ETIME.

        ETIME(TRUE).
        hQuery:QUERY-PREPARE("PRESELECT EACH " + cTable + " NO-LOCK") NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hBuffer NO-ERROR.
            RETURN THIS-OBJECT:buildError("BENCHMARK_QUERY_ERROR", ERROR-STATUS:GET-MESSAGE(1), "PRESELECT EACH " + cTable + " NO-LOCK").
        END.
        hQuery:QUERY-OPEN().
        ASSIGN iOpenMs = ETIME.

        ETIME(TRUE).
        ASSIGN iNumResults = hQuery:NUM-RESULTS.
        ASSIGN iNumResultsMs = ETIME.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hBuffer NO-ERROR.

        ASSIGN joRet = NEW JsonObject()
               joForEach = NEW JsonObject()
               joPreselect = NEW JsonObject().

        joForEach:Add("count", iCount).
        joForEach:Add("elapsedMs", iForEachMs).

        joPreselect:Add("openQueryElapsedMs", iOpenMs).
        joPreselect:Add("numResults", iNumResults).
        joPreselect:Add("numResultsElapsedMs", iNumResultsMs).

        joRet:Add("success", TRUE).
        joRet:Add("runtime", "PASOE-WEB").
        joRet:Add("table", cTable).
        joRet:Add("forEachNoLock", joForEach).
        joRet:Add("preselectNumResults", joPreselect).

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE CHARACTER getJobIdFromPath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iJobs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iResult AS INTEGER NO-UNDO.

        ASSIGN cPath = REPLACE(pcPath, "~\", "/").
        ASSIGN iJobs = INDEX(cPath, "/jobs/").
        IF iJobs = 0 THEN
            RETURN "".

        ASSIGN cPath = SUBSTRING(cPath, iJobs + 6).
        ASSIGN iResult = INDEX(cPath, "/result").
        IF iResult > 0 THEN
            ASSIGN cPath = SUBSTRING(cPath, 1, iResult - 1).

        RETURN cPath.
    END METHOD.

    METHOD PRIVATE LOGICAL isRootPath(INPUT pcPath AS CHARACTER):
        IF pcPath = ? THEN
            RETURN TRUE.
        IF pcPath = "" THEN
            RETURN TRUE.
        IF pcPath = "/" THEN
            RETURN TRUE.
        IF pcPath = "/SursumDynamicQuery" THEN
            RETURN TRUE.
        IF pcPath = "/SursumDynamicQuery/" THEN
            RETURN TRUE.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataTables():
        DEFINE VARIABLE oMetadata AS DynamicMetadataService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFilter AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabaseDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE jaTables AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaDbTables AS JsonArray NO-UNDO.
        DEFINE VARIABLE cUpdatedAt AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cFilter = THIS-OBJECT:getQueryValue(cQuery, "q").
        IF cFilter = "" THEN
            ASSIGN cFilter = THIS-OBJECT:getQueryValue(cQuery, "filter").
        ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = "TODOS".
        ASSIGN cDatabaseDisplay = cDatabase
               cDatabase = THIS-OBJECT:resolveDatabaseName(cDatabase).
        IF cDatabase <> "TODOS" AND cDatabase <> "ALL" AND NOT THIS-OBJECT:isRelationIdentifier(cDatabase) THEN
            RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cDatabase).

        ASSIGN oMetadata = NEW DynamicMetadataService()
               joRet = NEW JsonObject().
        ASSIGN jaTables = NEW JsonArray().

        IF cDatabase = "TODOS" OR cDatabase = "ALL" THEN DO:
            DO iDb = 1 TO NUM-DBS:
                oMetadata:setBanco(LDBNAME(iDb)).
                oMetadata:setBancoExibicao(THIS-OBJECT:getDatabaseDisplayName(iDb)).
                ASSIGN jaDbTables = oMetadata:getTablesJson(cFilter).
                THIS-OBJECT:appendJsonArray(jaTables, jaDbTables).
                THIS-OBJECT:writeMetadataCacheFile(THIS-OBJECT:getDatabaseDisplayName(iDb), "tables", "", jaDbTables).
            END.
        END.
        ELSE DO:
            oMetadata:setBanco(cDatabase).
            oMetadata:setBancoExibicao(cDatabaseDisplay).
            ASSIGN jaTables = oMetadata:getTablesJson(cFilter).
            THIS-OBJECT:writeMetadataCacheFile(cDatabaseDisplay, "tables", "", jaTables).
        END.

        ASSIGN cUpdatedAt = STRING(NOW).

        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabaseDisplay).
        joRet:Add("updatedAt", cUpdatedAt).
        joRet:Add("data", jaTables).

        DELETE OBJECT oMetadata NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataFields(INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE oMetadata AS DynamicMetadataService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabaseDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE cUpdatedAt AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTableLastUpdate AS CHARACTER NO-UNDO.

        IF NOT THIS-OBJECT:isRelationIdentifier(pcTable) THEN
            RETURN THIS-OBJECT:buildError("INVALID_TABLE", "Nome de tabela invalido", pcTable).

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        ASSIGN cDatabaseDisplay = cDatabase
               cDatabase = THIS-OBJECT:resolveDatabaseName(cDatabase).
        IF NOT THIS-OBJECT:isRelationIdentifier(cDatabase) THEN
            RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cDatabase).

        ASSIGN oMetadata = NEW DynamicMetadataService()
               joRet = NEW JsonObject().
        oMetadata:setBanco(cDatabase).
        oMetadata:setBancoExibicao(cDatabaseDisplay).

        ASSIGN jaFields = oMetadata:getFieldsJson(pcTable)
               cUpdatedAt = STRING(NOW)
               cTableLastUpdate = THIS-OBJECT:getDatabaseTableLastUpdate(cDatabase, pcTable).

        DO ON ERROR UNDO, LEAVE ON STOP UNDO, LEAVE:
            THIS-OBJECT:writeMetadataFieldsCacheFile(cDatabaseDisplay, pcTable, jaFields, cTableLastUpdate).
        END.

        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabaseDisplay).
        joRet:Add("updatedAt", cUpdatedAt).
        joRet:Add("table", pcTable).
        joRet:Add("tableLastUpdate", cTableLastUpdate).
        joRet:Add("data", jaFields).

        DELETE OBJECT oMetadata NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleSaveRelation(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cLeft AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRight AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLeftDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRightDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /metadata/relations").

        ASSIGN oParser = NEW ObjectModelParser()
               cJson = STRING(pcBody) NO-ERROR.
        ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON da relacao invalido", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        ASSIGN joBody = CAST(oConstruct, JsonObject) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("INVALID_JSON", "JSON da relacao deve ser um objeto", "").
        END.

        ASSIGN cLeft = THIS-OBJECT:getJsonChar(joBody, "leftTable").
        IF cLeft = "" THEN
            ASSIGN cLeft = THIS-OBJECT:getJsonChar(joBody, "left").
        ASSIGN cRight = THIS-OBJECT:getJsonChar(joBody, "rightTable").
        IF cRight = "" THEN
            ASSIGN cRight = THIS-OBJECT:getJsonChar(joBody, "right").
        ASSIGN cDatabase = THIS-OBJECT:getJsonChar(joBody, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getJsonChar(joBody, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        ASSIGN cLeftDatabase = THIS-OBJECT:getJsonChar(joBody, "leftDatabase").
        IF cLeftDatabase = "" THEN
            ASSIGN cLeftDatabase = cDatabase.
        ASSIGN cRightDatabase = THIS-OBJECT:getJsonChar(joBody, "rightDatabase").
        IF cRightDatabase = "" THEN
            ASSIGN cRightDatabase = cDatabase.

        IF NOT THIS-OBJECT:isRelationIdentifier(cLeft) OR NOT THIS-OBJECT:isRelationIdentifier(cRight) THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("INVALID_RELATION", "leftTable e rightTable sao obrigatorios e devem ser nomes seguros", cLeft + " / " + cRight).
        END.
        IF NOT THIS-OBJECT:isRelationIdentifier(cLeftDatabase) OR NOT THIS-OBJECT:isRelationIdentifier(cRightDatabase) THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cLeftDatabase + " / " + cRightDatabase).
        END.

        ASSIGN cLeftDatabase = THIS-OBJECT:getDatabaseDisplayNameByName(cLeftDatabase)
               cRightDatabase = THIS-OBJECT:getDatabaseDisplayNameByName(cRightDatabase).
        ASSIGN cFile = THIS-OBJECT:buildRelationFile(cLeftDatabase, cLeft, cRightDatabase, cRight).
        joBody:Add("database", cLeftDatabase) NO-ERROR.
        joBody:Add("leftDatabase", cLeftDatabase) NO-ERROR.
        joBody:Add("rightDatabase", cRightDatabase) NO-ERROR.
        joBody:Add("fileName", ENTRY(NUM-ENTRIES(cFile, "~\"), cFile, "~\")) NO-ERROR.
        joBody:Write(lcJson, TRUE).
        COPY-LOB FROM lcJson TO FILE cFile NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN THIS-OBJECT:buildError("RELATION_WRITE_ERROR", "Nao foi possivel gravar relacao", ERROR-STATUS:GET-MESSAGE(1)).
        END.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("database", cLeftDatabase).
        joRet:Add("leftDatabase", cLeftDatabase).
        joRet:Add("rightDatabase", cRightDatabase).
        joRet:Add("leftTable", cLeft).
        joRet:Add("rightTable", cRight).
        joRet:Add("path", cFile).
        joRet:Add("relation", joBody).

        DELETE OBJECT oParser NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataRelations():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joRelation AS JsonObject NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabaseDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFullPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAttr AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cNeedle AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cTable = THIS-OBJECT:getQueryValue(cQuery, "table")
               cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        ASSIGN cDatabaseDisplay = THIS-OBJECT:getDatabaseDisplayNameByName(cDatabase).

        IF NOT THIS-OBJECT:isRelationIdentifier(cTable) THEN
            RETURN THIS-OBJECT:buildError("INVALID_TABLE", "Nome de tabela invalido", cTable).
        IF NOT THIS-OBJECT:isRelationIdentifier(cDatabaseDisplay) THEN
            RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cDatabaseDisplay).

        ASSIGN cBase = THIS-OBJECT:getConfiguredRoot("relationsRoot", "sursum-conf/relations")
               cNeedle = LC(cDatabaseDisplay) + "__" + LC(cTable)
               jaData = NEW JsonArray().

        FILE-INFO:FILE-NAME = cBase.
        IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
            INPUT FROM OS-DIR(cBase) NO-ECHO.
            REPEAT:
                IMPORT cName cFullPath cAttr.
                IF cAttr <> "F" THEN
                    NEXT.
                IF INDEX(LC(cName), cNeedle) = 0 OR NOT LC(cName) MATCHES "*.json" THEN
                    NEXT.

                COPY-LOB FROM FILE cFullPath TO lcJson NO-ERROR.
                IF ERROR-STATUS:ERROR THEN
                    NEXT.

                ASSIGN cJson = STRING(lcJson) NO-ERROR.
                ASSIGN oParser = NEW ObjectModelParser().
                ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
                ASSIGN joRelation = CAST(oConstruct, JsonObject) NO-ERROR.
                IF VALID-OBJECT(joRelation) THEN DO:
                    joRelation:Add("path", cFullPath) NO-ERROR.
                    joRelation:Add("fileName", cName) NO-ERROR.
                    jaData:Add(joRelation).
                END.
                DELETE OBJECT oParser NO-ERROR.
            END.
            INPUT CLOSE.
        END.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabaseDisplay).
        joRet:Add("table", cTable).
        joRet:Add("data", jaData).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleMetadataRelationsOf():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTable AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabaseDisplay AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cResolvedDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.

        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cTable = THIS-OBJECT:getQueryValue(cQuery, "table")
               cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        ASSIGN cDatabaseDisplay = THIS-OBJECT:getDatabaseDisplayNameByName(cDatabase)
               cResolvedDatabase = THIS-OBJECT:resolveDatabaseName(cDatabase).

        IF NOT THIS-OBJECT:isRelationIdentifier(cTable) THEN
            RETURN THIS-OBJECT:buildError("INVALID_TABLE", "Nome de tabela invalido", cTable).
        IF NOT THIS-OBJECT:isRelationIdentifier(cResolvedDatabase) THEN
            RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cResolvedDatabase).

        ASSIGN jaData = THIS-OBJECT:discoverOfRelations(cResolvedDatabase, cDatabaseDisplay, cTable)
               joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabaseDisplay).
        joRet:Add("table", cTable).
        joRet:Add("source", "OF").
        joRet:Add("data", jaData).
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonArray discoverOfRelations(INPUT pcDatabase AS CHARACTER, INPUT pcDisplayDatabase AS CHARACTER, INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE hIndex AS HANDLE NO-UNDO.
        DEFINE VARIABLE hOwnerFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hMemberFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE hMemberQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOwner AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cMember AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cSeen AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rOwnerFile AS RECID NO-UNDO.
        DEFINE VARIABLE rTargetFile AS RECID NO-UNDO.

        ASSIGN jaData = NEW JsonArray().
        CREATE BUFFER hIndex FOR TABLE pcDatabase + "._Index" NO-ERROR.
        CREATE BUFFER hOwnerFile FOR TABLE pcDatabase + "._File" NO-ERROR.
        CREATE BUFFER hMemberFile FOR TABLE pcDatabase + "._File" NO-ERROR.
        IF NOT VALID-HANDLE(hIndex) OR NOT VALID-HANDLE(hOwnerFile) OR NOT VALID-HANDLE(hMemberFile) THEN DO:
            IF VALID-HANDLE(hIndex) THEN DELETE OBJECT hIndex NO-ERROR.
            IF VALID-HANDLE(hOwnerFile) THEN DELETE OBJECT hOwnerFile NO-ERROR.
            IF VALID-HANDLE(hMemberFile) THEN DELETE OBJECT hMemberFile NO-ERROR.
            RETURN jaData.
        END.

        hMemberFile:FIND-FIRST("WHERE _File-Name = " + QUOTER(pcTable) + " AND _File-Number > 0", NO-LOCK) NO-ERROR.
        IF NOT hMemberFile:AVAILABLE THEN DO:
            DELETE OBJECT hIndex NO-ERROR.
            DELETE OBJECT hOwnerFile NO-ERROR.
            DELETE OBJECT hMemberFile NO-ERROR.
            RETURN jaData.
        END.
        ASSIGN rTargetFile = hMemberFile:RECID.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hIndex).
        ASSIGN cPrepare = "FOR EACH " + pcDatabase + "._Index NO-LOCK WHERE " + pcDatabase + "._Index._Unique = TRUE BY " + pcDatabase + "._Index._Index-Name".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hIndex NO-ERROR.
            DELETE OBJECT hOwnerFile NO-ERROR.
            DELETE OBJECT hMemberFile NO-ERROR.
            RETURN jaData.
        END.

        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN
                LEAVE.

            ASSIGN rOwnerFile = hIndex:BUFFER-FIELD("_File-Recid"):BUFFER-VALUE NO-ERROR.
            hOwnerFile:FIND-FIRST("WHERE RECID(_File) = " + STRING(rOwnerFile), NO-LOCK) NO-ERROR.
            IF NOT hOwnerFile:AVAILABLE THEN
                NEXT.
            IF INTEGER(hOwnerFile:BUFFER-FIELD("_File-Number"):BUFFER-VALUE) <= 0 THEN
                NEXT.

            ASSIGN cOwner = STRING(hOwnerFile:BUFFER-FIELD("_File-Name"):BUFFER-VALUE)
                   cFields = THIS-OBJECT:getDynamicIndexFieldNames(pcDatabase, hIndex:RECID).
            IF cFields = "" THEN
                NEXT.

            IF LC(cOwner) = LC(pcTable) THEN DO:
                CREATE QUERY hMemberQuery.
                hMemberQuery:SET-BUFFERS(hMemberFile).
                hMemberQuery:QUERY-PREPARE("FOR EACH " + pcDatabase + "._File NO-LOCK WHERE " + pcDatabase + "._File._File-Number > 0 BY " + pcDatabase + "._File._File-Name") NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    DELETE OBJECT hMemberQuery NO-ERROR.
                    NEXT.
                END.
                hMemberQuery:QUERY-OPEN().
                REPEAT:
                    hMemberQuery:GET-NEXT().
                    IF hMemberQuery:QUERY-OFF-END THEN
                        LEAVE.
                    ASSIGN cMember = STRING(hMemberFile:BUFFER-FIELD("_File-Name"):BUFFER-VALUE).
                    IF cMember <> cOwner
                       AND THIS-OBJECT:fileHasFields(pcDatabase, hMemberFile:RECID, cFields) THEN DO:
                        ASSIGN cKey = LC(cMember) + "|" + LC(cOwner) + "|" + LC(cFields).
                        IF LOOKUP(cKey, cSeen, CHR(1)) = 0 THEN DO:
                            IF cSeen = "" THEN ASSIGN cSeen = cKey.
                            ELSE ASSIGN cSeen = cSeen + CHR(1) + cKey.
                            jaData:Add(THIS-OBJECT:buildOfRelation(pcDisplayDatabase, cMember, cOwner, cFields)).
                        END.
                    END.
                END.
                hMemberQuery:QUERY-CLOSE().
                DELETE OBJECT hMemberQuery NO-ERROR.
            END.
            ELSE IF THIS-OBJECT:fileHasFields(pcDatabase, rTargetFile, cFields) THEN DO:
                ASSIGN cKey = LC(pcTable) + "|" + LC(cOwner) + "|" + LC(cFields).
                IF LOOKUP(cKey, cSeen, CHR(1)) = 0 THEN DO:
                    IF cSeen = "" THEN ASSIGN cSeen = cKey.
                    ELSE ASSIGN cSeen = cSeen + CHR(1) + cKey.
                    jaData:Add(THIS-OBJECT:buildOfRelation(pcDisplayDatabase, pcTable, cOwner, cFields)).
                END.
            END.
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        IF VALID-HANDLE(hMemberQuery) THEN DELETE OBJECT hMemberQuery NO-ERROR.
        DELETE OBJECT hIndex NO-ERROR.
        DELETE OBJECT hOwnerFile NO-ERROR.
        DELETE OBJECT hMemberFile NO-ERROR.
        RETURN jaData.
    END METHOD.

    METHOD PRIVATE CHARACTER getDynamicIndexFieldNames(INPUT pcDatabase AS CHARACTER, INPUT prIndex AS RECID):
        DEFINE VARIABLE hIndexField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFields AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rField AS RECID NO-UNDO.

        CREATE BUFFER hIndexField FOR TABLE pcDatabase + "._Index-Field" NO-ERROR.
        CREATE BUFFER hField FOR TABLE pcDatabase + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hIndexField) OR NOT VALID-HANDLE(hField) THEN DO:
            IF VALID-HANDLE(hIndexField) THEN DELETE OBJECT hIndexField NO-ERROR.
            IF VALID-HANDLE(hField) THEN DELETE OBJECT hField NO-ERROR.
            RETURN "".
        END.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hIndexField).
        ASSIGN cPrepare = "FOR EACH " + pcDatabase + "._Index-Field NO-LOCK WHERE "
                        + pcDatabase + "._Index-Field._Index-Recid = " + STRING(prIndex) + " BY "
                        + pcDatabase + "._Index-Field._Index-Seq".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hIndexField NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN "".
        END.

        hQuery:QUERY-OPEN().
        REPEAT:
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN
                LEAVE.
            ASSIGN rField = hIndexField:BUFFER-FIELD("_Field-Recid"):BUFFER-VALUE NO-ERROR.
            hField:FIND-FIRST("WHERE RECID(_Field) = " + STRING(rField), NO-LOCK) NO-ERROR.
            IF NOT hField:AVAILABLE THEN
                NEXT.
            ASSIGN cField = STRING(hField:BUFFER-FIELD("_Field-Name"):BUFFER-VALUE).
            IF cFields = "" THEN ASSIGN cFields = cField.
            ELSE ASSIGN cFields = cFields + "," + cField.
        END.

        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hIndexField NO-ERROR.
        DELETE OBJECT hField NO-ERROR.
        RETURN cFields.
    END METHOD.

    METHOD PRIVATE LOGICAL fileHasFields(INPUT pcDatabase AS CHARACTER, INPUT prFile AS RECID, INPUT pcFields AS CHARACTER):
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.

        CREATE BUFFER hField FOR TABLE pcDatabase + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hField) THEN
            RETURN FALSE.

        DO iField = 1 TO NUM-ENTRIES(pcFields):
            ASSIGN cField = ENTRY(iField, pcFields).
            hField:FIND-FIRST("WHERE _File-Recid = " + STRING(prFile) + " AND _Field-Name = " + QUOTER(cField), NO-LOCK) NO-ERROR.
            IF NOT hField:AVAILABLE THEN DO:
                DELETE OBJECT hField NO-ERROR.
                RETURN FALSE.
            END.
        END.

        DELETE OBJECT hField NO-ERROR.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE JsonObject buildOfRelation(INPUT pcDatabase AS CHARACTER, INPUT pcMember AS CHARACTER, INPUT pcOwner AS CHARACTER, INPUT pcFields AS CHARACTER):
        DEFINE VARIABLE joRelation AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE joField AS JsonObject NO-UNDO.
        DEFINE VARIABLE iField AS INTEGER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.

        ASSIGN joRelation = NEW JsonObject()
               jaFields = NEW JsonArray().
        DO iField = 1 TO NUM-ENTRIES(pcFields):
            ASSIGN cField = ENTRY(iField, pcFields)
                   joField = NEW JsonObject().
            joField:Add("leftField", cField).
            joField:Add("rightField", cField).
            jaFields:Add(joField).
        END.

        joRelation:Add("database", pcDatabase).
        joRelation:Add("leftDatabase", pcDatabase).
        joRelation:Add("rightDatabase", pcDatabase).
        joRelation:Add("leftTable", pcMember).
        joRelation:Add("rightTable", pcOwner).
        joRelation:Add("leftField", ENTRY(1, pcFields)).
        joRelation:Add("rightField", ENTRY(1, pcFields)).
        joRelation:Add("type", "INNER").
        joRelation:Add("source", "OF").
        joRelation:Add("fields", jaFields).
        RETURN joRelation.
    END METHOD.

    METHOD PRIVATE JsonObject handleGetRelation(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE cLeft AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRight AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLeftDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRightDatabase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joRelation AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        THIS-OBJECT:parseRelationPath(pcPath, OUTPUT cLeft, OUTPUT cRight).
        ASSIGN cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "QUERY_STRING":U) NO-ERROR.
        ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "database").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getQueryValue(cQuery, "banco").
        IF cDatabase = "" THEN
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
        ASSIGN cLeftDatabase = THIS-OBJECT:getQueryValue(cQuery, "leftDatabase").
        IF cLeftDatabase = "" THEN
            ASSIGN cLeftDatabase = cDatabase.
        ASSIGN cRightDatabase = THIS-OBJECT:getQueryValue(cQuery, "rightDatabase").
        IF cRightDatabase = "" THEN
            ASSIGN cRightDatabase = cDatabase.

        IF NOT THIS-OBJECT:isRelationIdentifier(cLeft) OR NOT THIS-OBJECT:isRelationIdentifier(cRight) THEN
            RETURN THIS-OBJECT:buildError("INVALID_RELATION", "Rota de relacao invalida", pcPath).
        ASSIGN cLeftDatabase = THIS-OBJECT:getDatabaseDisplayNameByName(cLeftDatabase)
               cRightDatabase = THIS-OBJECT:getDatabaseDisplayNameByName(cRightDatabase).
        IF NOT THIS-OBJECT:isRelationIdentifier(cLeftDatabase) OR NOT THIS-OBJECT:isRelationIdentifier(cRightDatabase) THEN
            RETURN THIS-OBJECT:buildError("INVALID_DATABASE", "Banco logico invalido", cLeftDatabase + " / " + cRightDatabase).

        ASSIGN cFile = THIS-OBJECT:buildRelationFile(cLeftDatabase, cLeft, cRightDatabase, cRight).
        FILE-INFO:FILE-NAME = cFile.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            RETURN THIS-OBJECT:buildError("RELATION_NOT_FOUND", "Relacao nao encontrada", cLeft + " / " + cRight).

        COPY-LOB FROM FILE cFile TO lcJson NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN THIS-OBJECT:buildError("RELATION_READ_ERROR", "Nao foi possivel ler relacao", ERROR-STATUS:GET-MESSAGE(1)).

        ASSIGN cJson = STRING(lcJson) NO-ERROR.
        ASSIGN oParser = NEW ObjectModelParser().
        ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
        ASSIGN joRelation = CAST(oConstruct, JsonObject) NO-ERROR.

        ASSIGN joRet = NEW JsonObject().
        joRet:Add("success", TRUE).
        joRet:Add("database", cLeftDatabase).
        joRet:Add("leftDatabase", cLeftDatabase).
        joRet:Add("rightDatabase", cRightDatabase).
        joRet:Add("leftTable", cLeft).
        joRet:Add("rightTable", cRight).
        joRet:Add("path", cFile).
        IF VALID-OBJECT(joRelation) THEN
            joRet:Add("relation", joRelation).
        ELSE
            joRet:Add("raw", cJson).

        DELETE OBJECT oParser NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE CHARACTER getTableFromMetadataPath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iStart AS INTEGER NO-UNDO.
        DEFINE VARIABLE iEnd AS INTEGER NO-UNDO.

        ASSIGN cPath = REPLACE(pcPath, "~\", "/")
               iStart = INDEX(cPath, "/metadata/tables/").
        IF iStart = 0 THEN
            RETURN "".

        ASSIGN cPath = SUBSTRING(cPath, iStart + LENGTH("/metadata/tables/"))
               iEnd = INDEX(cPath, "/fields").
        IF iEnd > 0 THEN
            ASSIGN cPath = SUBSTRING(cPath, 1, iEnd - 1).

        RETURN cPath.
    END METHOD.

    METHOD PRIVATE VOID parseRelationPath(INPUT pcPath AS CHARACTER, OUTPUT pcLeft AS CHARACTER, OUTPUT pcRight AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iStart AS INTEGER NO-UNDO.

        ASSIGN pcLeft = ""
               pcRight = ""
               cPath = REPLACE(pcPath, "~\", "/")
               iStart = INDEX(cPath, "/metadata/relations/").
        IF iStart = 0 THEN
            RETURN.

        ASSIGN cPath = SUBSTRING(cPath, iStart + LENGTH("/metadata/relations/")).
        IF NUM-ENTRIES(cPath, "/") >= 2 THEN DO:
            ASSIGN pcLeft = ENTRY(1, cPath, "/")
                   pcRight = ENTRY(2, cPath, "/").
        END.
    END METHOD.

    METHOD PRIVATE CHARACTER buildRelationFile(INPUT pcLeftDatabase AS CHARACTER, INPUT pcLeft AS CHARACTER, INPUT pcRightDatabase AS CHARACTER, INPUT pcRight AS CHARACTER):
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDir AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLeftKey AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRightKey AS CHARACTER NO-UNDO.

        ASSIGN cBase = THIS-OBJECT:getConfiguredRoot("relationsRoot", "sursum-conf/relations")
               cDir = cBase
               cLeftKey = LC(pcLeftDatabase) + "__" + LC(pcLeft)
               cRightKey = LC(pcRightDatabase) + "__" + LC(pcRight).

        FILE-INFO:FILE-NAME = cBase.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            OS-CREATE-DIR VALUE(cBase) NO-ERROR.

        IF cLeftKey > cRightKey THEN
            RETURN cDir + "~\" + cRightKey + "__" + cLeftKey + ".json".
        RETURN cDir + "~\" + cLeftKey + "__" + cRightKey + ".json".
    END METHOD.

    METHOD PRIVATE CHARACTER getDefaultDatabase():
        IF NUM-DBS > 0 THEN
            RETURN LDBNAME(1).
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER resolveDatabaseName(INPUT pcDatabase AS CHARACTER):
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.
        DEFINE VARIABLE cDisplay AS CHARACTER NO-UNDO.

        IF pcDatabase = "TODOS" OR pcDatabase = "ALL" THEN
            RETURN pcDatabase.

        DO iDb = 1 TO NUM-DBS:
            ASSIGN cDisplay = THIS-OBJECT:getDatabaseDisplayName(iDb).
            IF LC(pcDatabase) = LC(cDisplay) OR LC(pcDatabase) = LC(LDBNAME(iDb)) THEN
                RETURN LDBNAME(iDb).
        END.

        RETURN pcDatabase.
    END METHOD.

    METHOD PRIVATE CHARACTER getDatabaseDisplayNameByName(INPUT pcDatabase AS CHARACTER):
        DEFINE VARIABLE iDb AS INTEGER NO-UNDO.
        DEFINE VARIABLE cDisplay AS CHARACTER NO-UNDO.

        DO iDb = 1 TO NUM-DBS:
            ASSIGN cDisplay = THIS-OBJECT:getDatabaseDisplayName(iDb).
            IF LC(pcDatabase) = LC(cDisplay) OR LC(pcDatabase) = LC(LDBNAME(iDb)) THEN
                RETURN cDisplay.
        END.

        RETURN pcDatabase.
    END METHOD.

    METHOD PRIVATE CHARACTER getDatabaseDisplayName(INPUT piDb AS INTEGER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.

        ASSIGN cPath = REPLACE(PDBNAME(piDb), "/", "~\").
        IF cPath = ? OR cPath = "" THEN
            RETURN LDBNAME(piDb).

        RETURN ENTRY(NUM-ENTRIES(cPath, "~\"), cPath, "~\").
    END METHOD.

    METHOD PRIVATE VOID appendJsonArray(INPUT-OUTPUT poTarget AS JsonArray, INPUT poSource AS JsonArray):
        DEFINE VARIABLE iItem AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poTarget) OR NOT VALID-OBJECT(poSource) THEN
            RETURN.

        DO iItem = 1 TO poSource:Length:
            poTarget:Add(poSource:GetJsonObject(iItem)).
        END.
    END METHOD.

    METHOD PRIVATE VOID writeMetadataFieldsCacheFile(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT poData AS JsonArray, INPUT pcTableLastUpdate AS CHARACTER):
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcData AS LONGCHAR NO-UNDO.

        IF NOT VALID-OBJECT(poData) THEN
            RETURN.

        FIX-CODEPAGE(lcData) = "UTF-8".
        FIX-CODEPAGE(lcJson) = "UTF-8".

        ASSIGN cBase = THIS-OBJECT:getConfiguredRoot("metadataRoot", "sursum-conf/metadata").
        FILE-INFO:FILE-NAME = cBase.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            OS-CREATE-DIR VALUE(cBase) NO-ERROR.

        ASSIGN cFile = THIS-OBJECT:getMetadataCacheFile(pcDatabase, "fields", pcTable).
        poData:Write(lcData, TRUE).
        ASSIGN lcJson = '~{"database":' + QUOTER(pcDatabase)
                      + ',"kind":"fields"'
                      + ',"table":' + QUOTER(pcTable)
                      + ',"updatedAt":' + QUOTER(STRING(NOW))
                      + ',"tableLastUpdate":' + QUOTER(pcTableLastUpdate)
                      + ',"data":' + lcData
                      + '}'.
        COPY-LOB FROM lcJson TO FILE cFile NO-ERROR.
    END METHOD.

    METHOD PRIVATE VOID writeMetadataCacheFile(INPUT pcDatabase AS CHARACTER, INPUT pcKind AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT poData AS JsonArray):
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcData AS LONGCHAR NO-UNDO.

        IF NOT VALID-OBJECT(poData) THEN
            RETURN.

        FIX-CODEPAGE(lcData) = "UTF-8".
        FIX-CODEPAGE(lcJson) = "UTF-8".

        ASSIGN cBase = THIS-OBJECT:getConfiguredRoot("metadataRoot", "sursum-conf/metadata").
        FILE-INFO:FILE-NAME = cBase.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            OS-CREATE-DIR VALUE(cBase) NO-ERROR.

        IF pcKind = "fields" THEN
            ASSIGN cFile = cBase + "~\" + LC(pcDatabase) + "__" + LC(pcTable) + "__fields.json".
        ELSE
            ASSIGN cFile = cBase + "~\" + LC(pcDatabase) + "__tables.json".

        poData:Write(lcData, TRUE).
        ASSIGN lcJson = '~{"database":' + QUOTER(pcDatabase)
                      + ',"kind":' + QUOTER(pcKind)
                      + ',"table":' + QUOTER(pcTable)
                      + ',"updatedAt":' + QUOTER(STRING(NOW))
                      + ',"data":' + lcData
                      + '}'.
        COPY-LOB FROM lcJson TO FILE cFile NO-ERROR.
    END METHOD.

    METHOD PRIVATE LOGICAL isFieldCacheOutdated(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT pcTableLastUpdate AS CHARACTER):
        DEFINE VARIABLE cCachedLastUpdate AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iCached AS INT64 NO-UNDO.
        DEFINE VARIABLE iCurrent AS INT64 NO-UNDO.

        ASSIGN cCachedLastUpdate = THIS-OBJECT:getFieldCacheTableLastUpdate(pcDatabase, pcTable).
        IF cCachedLastUpdate = "" THEN
            RETURN TRUE.
        IF pcTableLastUpdate = "" OR pcTableLastUpdate = ? THEN
            RETURN FALSE.

        ASSIGN iCached = INT64(cCachedLastUpdate) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN TRUE.
        ASSIGN iCurrent = INT64(pcTableLastUpdate) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN TRUE.

        RETURN iCached < iCurrent.
    END METHOD.

    METHOD PRIVATE CHARACTER getFieldCacheTableLastUpdate(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joCache AS JsonObject NO-UNDO.
        DEFINE VARIABLE cLastUpdate AS CHARACTER NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:getMetadataCacheFile(pcDatabase, "fields", pcTable).
        FILE-INFO:FILE-NAME = cFile.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            RETURN "".

        COPY-LOB FROM FILE cFile TO lcJson NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN "".
        ASSIGN cJson = STRING(lcJson) NO-ERROR.
        ASSIGN oParser = NEW ObjectModelParser().
        ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
        ASSIGN joCache = CAST(oConstruct, JsonObject) NO-ERROR.
        IF VALID-OBJECT(joCache) THEN
            ASSIGN cLastUpdate = THIS-OBJECT:getJsonChar(joCache, "tableLastUpdate").
        DELETE OBJECT oParser NO-ERROR.
        RETURN cLastUpdate.
    END METHOD.

    METHOD PRIVATE CHARACTER getDatabaseTableLastUpdate(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE hLastChange AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLastUpdate AS CHARACTER NO-UNDO.

        CREATE BUFFER hFile FOR TABLE pcDatabase + "._File" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) THEN
            RETURN "".

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hFile).
        ASSIGN cPrepare = "FOR FIRST " + pcDatabase + "._File NO-LOCK WHERE "
                        + pcDatabase + "._File._File-Name = " + QUOTER(pcTable).
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hFile NO-ERROR.
            RETURN "".
        END.
        hQuery:QUERY-OPEN().
        hQuery:GET-FIRST().
        IF NOT hQuery:QUERY-OFF-END THEN DO:
            ASSIGN hLastChange = hFile:BUFFER-FIELD("_Last-Change") NO-ERROR.
            IF VALID-HANDLE(hLastChange) THEN
                ASSIGN cLastUpdate = IF hLastChange:BUFFER-VALUE = ? THEN "" ELSE STRING(hLastChange:BUFFER-VALUE).
        END.
        hQuery:QUERY-CLOSE().
        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hFile NO-ERROR.
        RETURN cLastUpdate.
    END METHOD.

    METHOD PRIVATE CHARACTER getMetadataCacheFile(INPUT pcDatabase AS CHARACTER, INPUT pcKind AS CHARACTER, INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.

        ASSIGN cBase = THIS-OBJECT:getConfiguredRoot("metadataRoot", "sursum-conf/metadata").
        IF pcKind = "fields" THEN
            RETURN cBase + "~\" + LC(pcDatabase) + "__" + LC(pcTable) + "__fields.json".
        RETURN cBase + "~\" + LC(pcDatabase) + "__tables.json".
    END METHOD.

    METHOD PRIVATE LOGICAL loadBrowseKey(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER):
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hIndex AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE rFile AS RECID NO-UNDO.
        DEFINE VARIABLE rPrimary AS RECID NO-UNDO.
        DEFINE VARIABLE rChosen AS RECID NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.

        CREATE BUFFER hFile FOR TABLE pcDatabase + "._File" NO-ERROR.
        CREATE BUFFER hIndex FOR TABLE pcDatabase + "._Index" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) OR NOT VALID-HANDLE(hIndex) THEN DO:
            IF VALID-HANDLE(hFile) THEN DELETE OBJECT hFile NO-ERROR.
            IF VALID-HANDLE(hIndex) THEN DELETE OBJECT hIndex NO-ERROR.
            RETURN FALSE.
        END.

        hFile:FIND-FIRST("WHERE _File-Name = " + QUOTER(pcTable), NO-LOCK) NO-ERROR.
        IF NOT hFile:AVAILABLE THEN DO:
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hIndex NO-ERROR.
            RETURN FALSE.
        END.

        ASSIGN rFile = hFile:RECID
               rPrimary = hFile:BUFFER-FIELD("_Prime-Index"):BUFFER-VALUE NO-ERROR.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hIndex).
        ASSIGN cPrepare = "FOR EACH " + pcDatabase + "._Index NO-LOCK "
                        + "WHERE " + pcDatabase + "._Index._File-Recid = " + STRING(rFile) + " "
                        + "BY " + pcDatabase + "._Index._Idx-Num".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hIndex NO-ERROR.
            RETURN FALSE.
        END.

        hQuery:QUERY-OPEN().
        hQuery:GET-FIRST().
        DO WHILE NOT hQuery:QUERY-OFF-END:
            IF LOGICAL(hIndex:BUFFER-FIELD("_Active"):BUFFER-VALUE) AND hIndex:RECID = rPrimary THEN DO:
                ASSIGN rChosen = hIndex:RECID.
                LEAVE.
            END.
            hQuery:GET-NEXT().
        END.
        IF rChosen = ? THEN DO:
            hQuery:GET-FIRST().
            DO WHILE NOT hQuery:QUERY-OFF-END:
                IF LOGICAL(hIndex:BUFFER-FIELD("_Active"):BUFFER-VALUE)
                   AND LOGICAL(hIndex:BUFFER-FIELD("_Unique"):BUFFER-VALUE) THEN DO:
                    ASSIGN rChosen = hIndex:RECID.
                    LEAVE.
                END.
                hQuery:GET-NEXT().
            END.
        END.
        IF rChosen = ? THEN DO:
            hQuery:GET-FIRST().
            DO WHILE NOT hQuery:QUERY-OFF-END:
                IF LOGICAL(hIndex:BUFFER-FIELD("_Active"):BUFFER-VALUE)
                   AND INTEGER(hIndex:BUFFER-FIELD("_Wordidx"):BUFFER-VALUE) = 0 THEN DO:
                    ASSIGN rChosen = hIndex:RECID.
                    LEAVE.
                END.
                hQuery:GET-NEXT().
            END.
        END.
        hQuery:QUERY-CLOSE().

        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hFile NO-ERROR.
        DELETE OBJECT hIndex NO-ERROR.

        IF rChosen = ? THEN
            RETURN FALSE.

        RETURN THIS-OBJECT:loadBrowseKeyFields(pcDatabase, rChosen).
    END METHOD.

    METHOD PRIVATE LOGICAL loadBrowseKeyFields(INPUT pcDatabase AS CHARACTER, INPUT prIndex AS RECID):
        DEFINE VARIABLE hIndexField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iOrder AS INTEGER NO-UNDO.
        DEFINE VARIABLE rField AS RECID NO-UNDO.

        CREATE BUFFER hIndexField FOR TABLE pcDatabase + "._Index-Field" NO-ERROR.
        CREATE BUFFER hField FOR TABLE pcDatabase + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hIndexField) OR NOT VALID-HANDLE(hField) THEN DO:
            IF VALID-HANDLE(hIndexField) THEN DELETE OBJECT hIndexField NO-ERROR.
            IF VALID-HANDLE(hField) THEN DELETE OBJECT hField NO-ERROR.
            RETURN FALSE.
        END.

        CREATE QUERY hQuery.
        hQuery:SET-BUFFERS(hIndexField).
        ASSIGN cPrepare = "FOR EACH " + pcDatabase + "._Index-Field NO-LOCK "
                        + "WHERE " + pcDatabase + "._Index-Field._Index-Recid = " + STRING(prIndex) + " "
                        + "BY " + pcDatabase + "._Index-Field._Index-Seq".
        hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT hQuery NO-ERROR.
            DELETE OBJECT hIndexField NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN FALSE.
        END.

        hQuery:QUERY-OPEN().
        hQuery:GET-FIRST().
        DO WHILE NOT hQuery:QUERY-OFF-END:
            ASSIGN rField = hIndexField:BUFFER-FIELD("_Field-Recid"):BUFFER-VALUE NO-ERROR.
            hField:FIND-FIRST("WHERE RECID(_Field) = " + STRING(rField), NO-LOCK) NO-ERROR.
            IF hField:AVAILABLE THEN DO:
                ASSIGN iOrder = iOrder + 1.
                CREATE ttBrowseKey.
                ASSIGN ttBrowseKey.fieldOrder = iOrder
                       ttBrowseKey.fieldName = STRING(hField:BUFFER-FIELD("_Field-Name"):BUFFER-VALUE)
                       ttBrowseKey.dataType = THIS-OBJECT:normalizeBrowseDataType(STRING(hField:BUFFER-FIELD("_Data-Type"):BUFFER-VALUE))
                       ttBrowseKey.ascendingFlag = LOGICAL(hIndexField:BUFFER-FIELD("_Ascending"):BUFFER-VALUE).
            END.
            hQuery:GET-NEXT().
        END.
        hQuery:QUERY-CLOSE().

        DELETE OBJECT hQuery NO-ERROR.
        DELETE OBJECT hIndexField NO-ERROR.
        DELETE OBJECT hField NO-ERROR.

        RETURN CAN-FIND(FIRST ttBrowseKey).
    END METHOD.

    METHOD PRIVATE VOID loadBrowseFields(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT poFields AS JsonArray):
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
        DEFINE VARIABLE rFile AS RECID NO-UNDO.
        DEFINE VARIABLE cPrepare AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cBaseName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iExtent AS INTEGER NO-UNDO.
        DEFINE VARIABLE iItem AS INTEGER NO-UNDO.
        DEFINE VARIABLE iOrder AS INTEGER NO-UNDO.
        DEFINE VARIABLE joField AS JsonObject NO-UNDO.

        CREATE BUFFER hFile FOR TABLE pcDatabase + "._File" NO-ERROR.
        CREATE BUFFER hField FOR TABLE pcDatabase + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) OR NOT VALID-HANDLE(hField) THEN DO:
            IF VALID-HANDLE(hFile) THEN DELETE OBJECT hFile NO-ERROR.
            IF VALID-HANDLE(hField) THEN DELETE OBJECT hField NO-ERROR.
            RETURN.
        END.

        hFile:FIND-FIRST("WHERE _File-Name = " + QUOTER(pcTable), NO-LOCK) NO-ERROR.
        IF NOT hFile:AVAILABLE THEN DO:
            DELETE OBJECT hFile NO-ERROR.
            DELETE OBJECT hField NO-ERROR.
            RETURN.
        END.
        ASSIGN rFile = hFile:RECID.

        IF VALID-OBJECT(poFields) AND poFields:Length > 0 THEN DO iItem = 1 TO poFields:Length:
            ASSIGN cName = "" iExtent = 0.
            ASSIGN cName = poFields:GetCharacter(iItem) NO-ERROR.
            IF cName = "" THEN DO:
                ASSIGN joField = poFields:GetJsonObject(iItem) NO-ERROR.
                IF VALID-OBJECT(joField) THEN DO:
                    ASSIGN cName = THIS-OBJECT:getJsonChar(joField, "name") NO-ERROR.
                    IF joField:Has("extent") AND NOT joField:IsNull("extent") THEN
                        ASSIGN iExtent = joField:GetInteger("extent") NO-ERROR.
                END.
            END.
            ASSIGN cBaseName = THIS-OBJECT:parseBrowseFieldName(cName, OUTPUT iExtent).
            IF cBaseName = "" OR NOT THIS-OBJECT:isRelationIdentifier(cBaseName) THEN
                NEXT.
            hField:FIND-FIRST("WHERE _File-Recid = " + STRING(rFile) + " AND _Field-Name = " + QUOTER(cBaseName), NO-LOCK) NO-ERROR.
            IF NOT hField:AVAILABLE THEN
                NEXT.
            ASSIGN iOrder = iOrder + 1.
            CREATE ttBrowseField.
            ASSIGN ttBrowseField.fieldOrder = iOrder
                   ttBrowseField.fieldName = cBaseName
                   ttBrowseField.dataType = THIS-OBJECT:normalizeBrowseDataType(STRING(hField:BUFFER-FIELD("_Data-Type"):BUFFER-VALUE))
                   ttBrowseField.extentIndex = iExtent.
        END.
        ELSE DO:
            CREATE QUERY hQuery.
            hQuery:SET-BUFFERS(hField).
            ASSIGN cPrepare = "FOR EACH " + pcDatabase + "._Field NO-LOCK "
                            + "WHERE " + pcDatabase + "._Field._File-Recid = " + STRING(rFile) + " "
                            + "BY " + pcDatabase + "._Field._Order".
            hQuery:QUERY-PREPARE(cPrepare) NO-ERROR.
            IF NOT ERROR-STATUS:ERROR THEN DO:
                hQuery:QUERY-OPEN().
                hQuery:GET-FIRST().
                DO WHILE NOT hQuery:QUERY-OFF-END AND iOrder < 50:
                    ASSIGN iOrder = iOrder + 1.
                    CREATE ttBrowseField.
                    ASSIGN ttBrowseField.fieldOrder = iOrder
                           ttBrowseField.fieldName = STRING(hField:BUFFER-FIELD("_Field-Name"):BUFFER-VALUE)
                           ttBrowseField.dataType = THIS-OBJECT:normalizeBrowseDataType(STRING(hField:BUFFER-FIELD("_Data-Type"):BUFFER-VALUE))
                           ttBrowseField.extentIndex = 0.
                    hQuery:GET-NEXT().
                END.
                hQuery:QUERY-CLOSE().
            END.
            IF VALID-HANDLE(hQuery) THEN DELETE OBJECT hQuery NO-ERROR.
        END.

        DELETE OBJECT hFile NO-ERROR.
        DELETE OBJECT hField NO-ERROR.
    END METHOD.

    METHOD PRIVATE CHARACTER parseBrowseFieldName(INPUT pcName AS CHARACTER, OUTPUT piExtent AS INTEGER):
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iOpen AS INTEGER NO-UNDO.
        DEFINE VARIABLE iClose AS INTEGER NO-UNDO.

        ASSIGN cName = TRIM(pcName).
        IF cName = ? THEN
            RETURN "".
        ASSIGN iOpen = INDEX(cName, "[")
               iClose = INDEX(cName, "]").
        IF iOpen > 1 AND iClose > iOpen THEN DO:
            ASSIGN piExtent = INTEGER(SUBSTRING(cName, iOpen + 1, iClose - iOpen - 1)) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN
                ASSIGN piExtent = 0.
            ASSIGN cName = SUBSTRING(cName, 1, iOpen - 1).
        END.
        RETURN cName.
    END METHOD.

    METHOD PRIVATE CHARACTER buildBrowseCursorWhere(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT poCursor AS JsonObject, INPUT pcDirection AS CHARACTER):
        DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPart AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cEquals AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOp AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        IF NOT VALID-OBJECT(poCursor) THEN
            RETURN "".

        ASSIGN cOp = IF pcDirection = "DESC" THEN "<" ELSE ">".
        FOR EACH ttBrowseKey BY ttBrowseKey.fieldOrder:
            IF NOT poCursor:Has(ttBrowseKey.fieldName) OR poCursor:IsNull(ttBrowseKey.fieldName) THEN
                RETURN ?.
            ASSIGN cValue = THIS-OBJECT:getBrowseCursorValue(poCursor, ttBrowseKey.fieldName, ttBrowseKey.dataType).
            ASSIGN cPart = cEquals
                         + pcDatabase + "." + pcTable + "." + ttBrowseKey.fieldName
                         + " " + cOp + " " + THIS-OBJECT:browseLiteral(cValue, ttBrowseKey.dataType).
            IF cWhere = "" THEN
                ASSIGN cWhere = "(" + cPart + ")".
            ELSE
                ASSIGN cWhere = cWhere + " OR (" + cPart + ")".
            IF cEquals = "" THEN
                ASSIGN cEquals = pcDatabase + "." + pcTable + "." + ttBrowseKey.fieldName + " = " + THIS-OBJECT:browseLiteral(cValue, ttBrowseKey.dataType) + " AND ".
            ELSE
                ASSIGN cEquals = cEquals + pcDatabase + "." + pcTable + "." + ttBrowseKey.fieldName + " = " + THIS-OBJECT:browseLiteral(cValue, ttBrowseKey.dataType) + " AND ".
        END.

        IF cWhere <> "" THEN
            ASSIGN cWhere = "(" + cWhere + ")".
        RETURN cWhere.
    END METHOD.

    METHOD PRIVATE CHARACTER buildBrowseFiltersWhere(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT poBody AS JsonObject, OUTPUT pcError AS CHARACTER):
        DEFINE VARIABLE jaFilters AS JsonArray NO-UNDO.
        DEFINE VARIABLE joFilter AS JsonObject NO-UNDO.
        DEFINE VARIABLE cWhere AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPart AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOperator AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iFilter AS INTEGER NO-UNDO.

        ASSIGN pcError = "".
        IF NOT VALID-OBJECT(poBody) OR NOT poBody:Has("filters") OR poBody:IsNull("filters") THEN
            RETURN "".

        ASSIGN jaFilters = poBody:GetJsonArray("filters") NO-ERROR.
        IF NOT VALID-OBJECT(jaFilters) THEN
            RETURN "".

        DO iFilter = 1 TO jaFilters:Length:
            ASSIGN joFilter = jaFilters:GetJsonObject(iFilter) NO-ERROR.
            IF NOT VALID-OBJECT(joFilter) THEN
                NEXT.

            ASSIGN cField = THIS-OBJECT:getJsonChar(joFilter, "field")
                   cOperator = LC(THIS-OBJECT:getJsonChar(joFilter, "operator"))
                   cValue = THIS-OBJECT:getJsonChar(joFilter, "value").
            IF cField = "" THEN
                ASSIGN cField = THIS-OBJECT:getJsonChar(joFilter, "name").
            IF cField = "" OR NOT THIS-OBJECT:isRelationIdentifier(cField) THEN DO:
                ASSIGN pcError = "Campo invalido: " + cField.
                RETURN ?.
            END.
            IF cOperator = "" THEN
                ASSIGN cOperator = "=".
            ASSIGN cType = THIS-OBJECT:getBrowseFieldDataType(pcDatabase, pcTable, cField).
            IF cType = "" THEN DO:
                ASSIGN pcError = "Campo nao encontrado: " + cField.
                RETURN ?.
            END.
            ASSIGN cPart = THIS-OBJECT:buildBrowseFilterExpression(pcDatabase, pcTable, cField, cType, cOperator, cValue, OUTPUT pcError).
            IF cPart = ? THEN
                RETURN ?.
            IF cPart = "" THEN
                NEXT.
            IF cWhere = "" THEN
                ASSIGN cWhere = cPart.
            ELSE
                ASSIGN cWhere = cWhere + " AND " + cPart.
        END.

        RETURN cWhere.
    END METHOD.

    METHOD PRIVATE CHARACTER getBrowseFieldDataType(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT pcField AS CHARACTER):
        DEFINE VARIABLE hFile AS HANDLE NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.

        CREATE BUFFER hFile FOR TABLE pcDatabase + "._File" NO-ERROR.
        CREATE BUFFER hField FOR TABLE pcDatabase + "._Field" NO-ERROR.
        IF NOT VALID-HANDLE(hFile) OR NOT VALID-HANDLE(hField) THEN DO:
            IF VALID-HANDLE(hFile) THEN DELETE OBJECT hFile NO-ERROR.
            IF VALID-HANDLE(hField) THEN DELETE OBJECT hField NO-ERROR.
            RETURN "".
        END.

        hFile:FIND-FIRST("WHERE _File-Name = " + QUOTER(pcTable), NO-LOCK) NO-ERROR.
        IF hFile:AVAILABLE THEN DO:
            hField:FIND-FIRST("WHERE _File-Recid = " + STRING(hFile:RECID) + " AND _Field-Name = " + QUOTER(pcField), NO-LOCK) NO-ERROR.
            IF hField:AVAILABLE THEN
                ASSIGN cType = THIS-OBJECT:normalizeBrowseDataType(STRING(hField:BUFFER-FIELD("_Data-Type"):BUFFER-VALUE)).
        END.

        DELETE OBJECT hFile NO-ERROR.
        DELETE OBJECT hField NO-ERROR.
        RETURN cType.
    END METHOD.

    METHOD PRIVATE CHARACTER buildBrowseFilterExpression(
        INPUT pcDatabase AS CHARACTER,
        INPUT pcTable AS CHARACTER,
        INPUT pcField AS CHARACTER,
        INPUT pcType AS CHARACTER,
        INPUT pcOperator AS CHARACTER,
        INPUT pcValue AS CHARACTER,
        OUTPUT pcError AS CHARACTER):
        DEFINE VARIABLE cColumn AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOperator AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cLiteral AS CHARACTER NO-UNDO.

        ASSIGN pcError = ""
               cOperator = LC(TRIM(pcOperator))
               cColumn = pcDatabase + "." + pcTable + "." + pcField.

        CASE cOperator:
            WHEN "=" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " = " + cLiteral.
            END.
            WHEN "eq" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " = " + cLiteral.
            END.
            WHEN "<>" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " <> " + cLiteral.
            END.
            WHEN "ne" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " <> " + cLiteral.
            END.
            WHEN ">" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " > " + cLiteral.
            END.
            WHEN "gt" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " > " + cLiteral.
            END.
            WHEN ">=" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " >= " + cLiteral.
            END.
            WHEN "gte" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " >= " + cLiteral.
            END.
            WHEN "<" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " < " + cLiteral.
            END.
            WHEN "lt" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " < " + cLiteral.
            END.
            WHEN "<=" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " <= " + cLiteral.
            END.
            WHEN "lte" THEN DO:
                ASSIGN cLiteral = THIS-OBJECT:browseLiteral(pcValue, pcType) NO-ERROR.
                IF ERROR-STATUS:ERROR THEN DO:
                    ASSIGN pcError = "Valor invalido para " + pcField + ": " + pcValue.
                    ERROR-STATUS:ERROR = FALSE.
                    RETURN ?.
                END.
                RETURN cColumn + " <= " + cLiteral.
            END.
            WHEN "contains" THEN DO:
                IF pcType <> "character" THEN DO:
                    ASSIGN pcError = "Operador contem requer campo character: " + pcField.
                    RETURN ?.
                END.
                RETURN "INDEX(" + cColumn + ", " + QUOTER(pcValue) + ") > 0".
            END.
            WHEN "begins" THEN DO:
                IF pcType <> "character" THEN DO:
                    ASSIGN pcError = "Operador comeca com requer campo character: " + pcField.
                    RETURN ?.
                END.
                RETURN cColumn + " BEGINS " + QUOTER(pcValue).
            END.
        END CASE.

        ASSIGN pcError = "Operador nao suportado: " + pcOperator.
        RETURN ?.
    END METHOD.

    METHOD PRIVATE CHARACTER buildBrowseOrder(INPUT pcDatabase AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT pcDirection AS CHARACTER):
        DEFINE VARIABLE cOrder AS CHARACTER NO-UNDO.

        FOR EACH ttBrowseKey BY ttBrowseKey.fieldOrder:
            ASSIGN cOrder = cOrder + " BY " + pcDatabase + "." + pcTable + "." + ttBrowseKey.fieldName.
            IF pcDirection = "DESC" THEN
                ASSIGN cOrder = cOrder + " DESCENDING".
        END.
        RETURN cOrder.
    END METHOD.

    METHOD PRIVATE JsonObject buildBrowseRow(INPUT phBuffer AS HANDLE):
        DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.

        ASSIGN joRow = NEW JsonObject().
        FOR EACH ttBrowseField BY ttBrowseField.fieldOrder:
            ASSIGN hField = ttBrowseField.fieldHandle NO-ERROR.
            IF NOT VALID-HANDLE(hField) THEN
                NEXT.
            THIS-OBJECT:addBrowseValue(joRow, ttBrowseField.outputName, hField, ttBrowseField.dataType, ttBrowseField.extentIndex).
        END.
        RETURN joRow.
    END METHOD.

    METHOD PRIVATE JsonObject buildBrowseCursor(INPUT phBuffer AS HANDLE):
        DEFINE VARIABLE joCursor AS JsonObject NO-UNDO.
        DEFINE VARIABLE hField AS HANDLE NO-UNDO.

        ASSIGN joCursor = NEW JsonObject().
        FOR EACH ttBrowseKey BY ttBrowseKey.fieldOrder:
            ASSIGN hField = ttBrowseKey.fieldHandle NO-ERROR.
            IF NOT VALID-HANDLE(hField) THEN
                NEXT.
            THIS-OBJECT:addBrowseValue(joCursor, ttBrowseKey.fieldName, hField, ttBrowseKey.dataType, 0).
        END.
        RETURN joCursor.
    END METHOD.

    METHOD PRIVATE VOID prepareBrowseHandles(INPUT phBuffer AS HANDLE):
        FOR EACH ttBrowseField:
            ASSIGN ttBrowseField.fieldHandle = phBuffer:BUFFER-FIELD(ttBrowseField.fieldName) NO-ERROR.
            IF ttBrowseField.extentIndex > 0 THEN
                ASSIGN ttBrowseField.outputName = ttBrowseField.fieldName + "[" + STRING(ttBrowseField.extentIndex) + "]".
            ELSE
                ASSIGN ttBrowseField.outputName = ttBrowseField.fieldName.
        END.

        FOR EACH ttBrowseKey:
            ASSIGN ttBrowseKey.fieldHandle = phBuffer:BUFFER-FIELD(ttBrowseKey.fieldName) NO-ERROR.
        END.
    END METHOD.

    METHOD PRIVATE JsonArray buildBrowseKeyFieldsJson(INPUT pcDirection AS CHARACTER):
        DEFINE VARIABLE jaKeys AS JsonArray NO-UNDO.
        DEFINE VARIABLE joKey AS JsonObject NO-UNDO.

        ASSIGN jaKeys = NEW JsonArray().
        FOR EACH ttBrowseKey BY ttBrowseKey.fieldOrder:
            ASSIGN joKey = NEW JsonObject().
            joKey:Add("name", ttBrowseKey.fieldName).
            joKey:Add("type", ttBrowseKey.dataType).
            joKey:Add("ascending", pcDirection <> "DESC").
            jaKeys:Add(joKey).
        END.
        RETURN jaKeys.
    END METHOD.

    METHOD PRIVATE JsonArray buildBrowseFieldsJson():
        DEFINE VARIABLE jaFields AS JsonArray NO-UNDO.
        DEFINE VARIABLE joField AS JsonObject NO-UNDO.

        ASSIGN jaFields = NEW JsonArray().
        FOR EACH ttBrowseField BY ttBrowseField.fieldOrder:
            ASSIGN joField = NEW JsonObject().
            joField:Add("name", IF ttBrowseField.extentIndex > 0 THEN ttBrowseField.fieldName + "[" + STRING(ttBrowseField.extentIndex) + "]" ELSE ttBrowseField.fieldName).
            joField:Add("type", ttBrowseField.dataType).
            IF ttBrowseField.extentIndex > 0 THEN
                joField:Add("extent", ttBrowseField.extentIndex).
            jaFields:Add(joField).
        END.
        RETURN jaFields.
    END METHOD.

    METHOD PRIVATE VOID addBrowseValue(INPUT poTarget AS JsonObject, INPUT pcName AS CHARACTER, INPUT phField AS HANDLE, INPUT pcType AS CHARACTER, INPUT piExtent AS INTEGER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
        DEFINE VARIABLE i64Value AS INT64 NO-UNDO.
        DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
        DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.
        DEFINE VARIABLE dtValue AS DATE NO-UNDO.
        DEFINE VARIABLE dtmValue AS DATETIME NO-UNDO.

        IF piExtent > 0 AND phField:BUFFER-VALUE(piExtent) = ? THEN DO:
            poTarget:AddNull(pcName).
            RETURN.
        END.
        IF piExtent <= 0 AND phField:BUFFER-VALUE = ? THEN DO:
            poTarget:AddNull(pcName).
            RETURN.
        END.

        CASE pcType:
            WHEN "integer" THEN DO:
                IF piExtent > 0 THEN
                    ASSIGN iValue = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN iValue = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN poTarget:Add(pcName, cValue).
                ELSE poTarget:Add(pcName, iValue).
            END.
            WHEN "int64" THEN DO:
                IF piExtent > 0 THEN
                    ASSIGN i64Value = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN i64Value = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN poTarget:Add(pcName, cValue).
                ELSE poTarget:Add(pcName, i64Value).
            END.
            WHEN "decimal" THEN DO:
                IF piExtent > 0 THEN
                    ASSIGN dValue = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN dValue = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN poTarget:Add(pcName, cValue).
                ELSE poTarget:Add(pcName, dValue).
            END.
            WHEN "logical" THEN DO:
                IF piExtent > 0 THEN
                    ASSIGN lValue = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN lValue = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN poTarget:Add(pcName, cValue).
                ELSE poTarget:Add(pcName, lValue).
            END.
            WHEN "date" THEN DO:
                IF piExtent > 0 THEN
                    ASSIGN dtValue = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN dtValue = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN poTarget:Add(pcName, cValue).
                ELSE poTarget:Add(pcName, ISO-DATE(dtValue)).
            END.
            WHEN "datetime" THEN DO:
                IF piExtent > 0 THEN
                    ASSIGN dtmValue = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN dtmValue = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN poTarget:Add(pcName, cValue).
                ELSE poTarget:Add(pcName, STRING(dtmValue)).
            END.
            OTHERWISE DO:
                IF piExtent > 0 THEN
                    ASSIGN cValue = phField:BUFFER-VALUE(piExtent) NO-ERROR.
                ELSE
                    ASSIGN cValue = phField:BUFFER-VALUE NO-ERROR.
                IF ERROR-STATUS:ERROR THEN
                    poTarget:Add(pcName, "").
                ELSE
                    poTarget:Add(pcName, cValue).
            END.
        END CASE.
    END METHOD.

    METHOD PRIVATE CHARACTER safeJsonChar(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE cOut AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iChar AS INTEGER NO-UNDO.
        DEFINE VARIABLE iAsc AS INTEGER NO-UNDO.

        IF pcValue = ? THEN
            RETURN "".

        DO iChar = 1 TO LENGTH(pcValue):
            ASSIGN cChar = SUBSTRING(pcValue, iChar, 1) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                NEXT.
            END.

            ASSIGN iAsc = ASC(cChar) NO-ERROR.
            IF ERROR-STATUS:ERROR OR iAsc = ? THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                NEXT.
            END.

            IF iAsc < 32 OR iAsc > 126 THEN
                ASSIGN cOut = cOut + " ".
            ELSE
                ASSIGN cOut = cOut + cChar.
        END.

        RETURN cOut.
    END METHOD.

    METHOD PRIVATE CHARACTER browseLiteral(INPUT pcValue AS CHARACTER, INPUT pcType AS CHARACTER):
        CASE pcType:
            WHEN "integer" THEN RETURN STRING(INTEGER(pcValue)).
            WHEN "int64" THEN RETURN STRING(INT64(pcValue)).
            WHEN "decimal" THEN RETURN STRING(DECIMAL(pcValue)).
            WHEN "logical" THEN RETURN IF LOGICAL(pcValue) THEN "TRUE" ELSE "FALSE".
            WHEN "date" THEN RETURN "DATE(" + QUOTER(ISO-DATE(DATE(pcValue))) + ")".
            WHEN "datetime" THEN RETURN "DATETIME(" + QUOTER(pcValue) + ")".
            OTHERWISE RETURN QUOTER(pcValue).
        END CASE.
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeBrowseDataType(INPUT pcType AS CHARACTER):
        CASE LC(pcType):
            WHEN "char" THEN RETURN "character".
            WHEN "character" THEN RETURN "character".
            WHEN "int" THEN RETURN "integer".
            WHEN "integer" THEN RETURN "integer".
            WHEN "int64" THEN RETURN "int64".
            WHEN "dec" THEN RETURN "decimal".
            WHEN "decimal" THEN RETURN "decimal".
            WHEN "logical" THEN RETURN "logical".
            WHEN "date" THEN RETURN "date".
            WHEN "datetime" THEN RETURN "datetime".
            WHEN "datetime-tz" THEN RETURN "datetime-tz".
        END CASE.
        RETURN LC(pcType).
    END METHOD.

    METHOD PRIVATE CHARACTER getBrowseCursorValue(INPUT poCursor AS JsonObject, INPUT pcName AS CHARACTER, INPUT pcType AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.
        DEFINE VARIABLE i64Value AS INT64 NO-UNDO.
        DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
        DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.

        IF NOT VALID-OBJECT(poCursor) THEN
            RETURN "".
        IF NOT poCursor:Has(pcName) OR poCursor:IsNull(pcName) THEN
            RETURN "".

        ASSIGN cValue = poCursor:GetCharacter(pcName) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR THEN
            RETURN cValue.

        CASE pcType:
            WHEN "integer" THEN DO:
                ASSIGN iValue = poCursor:GetInteger(pcName) NO-ERROR.
                IF NOT ERROR-STATUS:ERROR THEN
                    RETURN STRING(iValue).
            END.
            WHEN "int64" THEN DO:
                ASSIGN i64Value = poCursor:GetInt64(pcName) NO-ERROR.
                IF NOT ERROR-STATUS:ERROR THEN
                    RETURN STRING(i64Value).
            END.
            WHEN "decimal" THEN DO:
                ASSIGN dValue = poCursor:GetDecimal(pcName) NO-ERROR.
                IF NOT ERROR-STATUS:ERROR THEN
                    RETURN STRING(dValue).
            END.
            WHEN "logical" THEN DO:
                ASSIGN lValue = poCursor:GetLogical(pcName) NO-ERROR.
                IF NOT ERROR-STATUS:ERROR THEN
                    RETURN STRING(lValue).
            END.
        END CASE.

        RETURN "".
    END METHOD.


    METHOD PRIVATE JsonObject parseJsonObject(INPUT pcJson AS LONGCHAR):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.

        ASSIGN cJson = STRING(pcJson) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN ?.

        ASSIGN oParser = NEW ObjectModelParser().
        ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN ?.
        END.
        ASSIGN joValue = CAST(oConstruct, JsonObject) NO-ERROR.
        DELETE OBJECT oParser NO-ERROR.
        RETURN joValue.
    END METHOD.

    METHOD PRIVATE JsonObject readJsonFile(INPUT pcFile AS CHARACTER):
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF pcFile = ? OR pcFile = "" THEN
            RETURN ?.

        FILE-INFO:FILE-NAME = pcFile.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            RETURN ?.

        COPY-LOB FROM FILE pcFile TO lcJson NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            ERROR-STATUS:ERROR = FALSE.
            RETURN ?.
        END.

        RETURN THIS-OBJECT:parseJsonObject(lcJson).
    END METHOD.

    METHOD PRIVATE JsonObject readStoredQuery(INPUT pcCode AS CHARACTER):
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cAltFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF NOT THIS-OBJECT:isQueryCode(pcCode) THEN
            RETURN ?.

        ASSIGN cFile = THIS-OBJECT:buildQueryStoreFile(pcCode).
        COPY-LOB FROM FILE cFile TO lcJson NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            ASSIGN cAltFile = REPLACE(cFile, "~\", "/").
            IF cAltFile <> cFile THEN
                COPY-LOB FROM FILE cAltFile TO lcJson NO-ERROR.
        END.
        IF ERROR-STATUS:ERROR THEN
            RETURN ?.

        RETURN THIS-OBJECT:parseJsonObject(lcJson).
    END METHOD.

    METHOD PRIVATE JsonObject applyStoredQueryParameters(INPUT poStored AS JsonObject, INPUT poQuery AS JsonObject, INPUT poParams AS JsonObject):
        DEFINE VARIABLE jaExternal AS JsonArray NO-UNDO.
        DEFINE VARIABLE joFilter AS JsonObject NO-UNDO.
        DEFINE VARIABLE cSource AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iFilter AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poQuery) THEN
            RETURN THIS-OBJECT:buildError("QUERY_STORE_INVALID", "Consulta salva sem query valida", "").

        IF VALID-OBJECT(poStored) AND poStored:Has("externalFilters") AND NOT poStored:IsNull("externalFilters") THEN
            ASSIGN jaExternal = poStored:GetJsonArray("externalFilters") NO-ERROR.
        IF NOT VALID-OBJECT(jaExternal) AND poQuery:Has("externalFilters") AND NOT poQuery:IsNull("externalFilters") THEN
            ASSIGN jaExternal = poQuery:GetJsonArray("externalFilters") NO-ERROR.

        IF THIS-OBJECT:hasAnyParameters(poParams) AND NOT VALID-OBJECT(jaExternal) THEN
            RETURN THIS-OBJECT:buildError("EXTERNAL_FILTER_NOT_ALLOWED", "Consulta salva nao aceita parametros externos", "externalFilters ausente").

        IF VALID-OBJECT(poParams) AND VALID-OBJECT(jaExternal) THEN DO:
            ASSIGN joFilter = THIS-OBJECT:validateParameterBucket(jaExternal, poParams, "querystring").
            IF VALID-OBJECT(joFilter) THEN RETURN joFilter.
            ASSIGN joFilter = THIS-OBJECT:validateParameterBucket(jaExternal, poParams, "header").
            IF VALID-OBJECT(joFilter) THEN RETURN joFilter.
            ASSIGN joFilter = THIS-OBJECT:validateParameterBucket(jaExternal, poParams, "headers").
            IF VALID-OBJECT(joFilter) THEN RETURN joFilter.
            ASSIGN joFilter = THIS-OBJECT:validateParameterBucket(jaExternal, poParams, "body").
            IF VALID-OBJECT(joFilter) THEN RETURN joFilter.
        END.

        IF VALID-OBJECT(jaExternal) THEN DO:
            DO iFilter = 1 TO jaExternal:Length:
                ASSIGN joFilter = jaExternal:GetJsonObject(iFilter) NO-ERROR.
                IF NOT VALID-OBJECT(joFilter) THEN NEXT.
                ASSIGN cSource = THIS-OBJECT:normalizeExternalSource(THIS-OBJECT:getJsonChar(joFilter, "source"))
                       cName = THIS-OBJECT:getJsonChar(joFilter, "name")
                       cValue = THIS-OBJECT:getExternalParameterValue(poParams, cSource, cName).
                IF cValue = "" AND THIS-OBJECT:getJsonLogical(joFilter, "required", FALSE) THEN
                    RETURN THIS-OBJECT:buildError("REQUIRED_EXTERNAL_FILTER_MISSING", "Filtro externo obrigatorio ausente", cSource + "." + cName).
                IF cValue <> "" THEN
                    THIS-OBJECT:addExternalRuntimeFilter(poQuery, joFilter, cValue).
            END.
        END.

        ASSIGN joFilter = NEW JsonObject().
        joFilter:Add("success", TRUE).
        RETURN joFilter.
    END METHOD.

    METHOD PRIVATE JsonObject validateParameterBucket(INPUT poAllowed AS JsonArray, INPUT poParams AS JsonObject, INPUT pcBucket AS CHARACTER):
        DEFINE VARIABLE joBucket AS JsonObject NO-UNDO.
        DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
        DEFINE VARIABLE iName AS INTEGER NO-UNDO.
        DEFINE VARIABLE cSource AS CHARACTER NO-UNDO.

        ASSIGN joBucket = THIS-OBJECT:getParameterBucket(poParams, pcBucket).
        IF NOT VALID-OBJECT(joBucket) THEN
            RETURN ?.

        ASSIGN cSource = THIS-OBJECT:normalizeExternalSource(pcBucket).
        ASSIGN cNames = joBucket:GetNames() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN ?.

        DO iName = 1 TO EXTENT(cNames):
            IF NOT THIS-OBJECT:isExternalFilterAllowed(poAllowed, cSource, cNames[iName]) THEN
                RETURN THIS-OBJECT:buildError("EXTERNAL_FILTER_NOT_ALLOWED", "Parametro externo nao declarado em externalFilters", cSource + "." + cNames[iName]).
        END.

        RETURN ?.
    END METHOD.

    METHOD PRIVATE LOGICAL isExternalFilterAllowed(INPUT poAllowed AS JsonArray, INPUT pcSource AS CHARACTER, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE joFilter AS JsonObject NO-UNDO.
        DEFINE VARIABLE iFilter AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poAllowed) THEN
            RETURN FALSE.

        DO iFilter = 1 TO poAllowed:Length:
            ASSIGN joFilter = poAllowed:GetJsonObject(iFilter) NO-ERROR.
            IF VALID-OBJECT(joFilter)
               AND THIS-OBJECT:normalizeExternalSource(THIS-OBJECT:getJsonChar(joFilter, "source")) = THIS-OBJECT:normalizeExternalSource(pcSource)
               AND THIS-OBJECT:getJsonChar(joFilter, "name") = pcName THEN
                RETURN TRUE.
        END.

        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE CHARACTER getExternalParameterValue(INPUT poParams AS JsonObject, INPUT pcSource AS CHARACTER, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE joBucket AS JsonObject NO-UNDO.

        IF pcName = "" THEN
            RETURN "".
        ASSIGN joBucket = THIS-OBJECT:getParameterBucket(poParams, pcSource).
        RETURN THIS-OBJECT:getJsonChar(joBucket, pcName).
    END METHOD.

    METHOD PRIVATE JsonObject getParameterBucket(INPUT poParams AS JsonObject, INPUT pcSource AS CHARACTER):
        DEFINE VARIABLE joBucket AS JsonObject NO-UNDO.
        DEFINE VARIABLE cSource AS CHARACTER NO-UNDO.

        IF NOT VALID-OBJECT(poParams) THEN
            RETURN ?.

        ASSIGN cSource = THIS-OBJECT:normalizeExternalSource(pcSource).
        IF cSource = "header" THEN DO:
            IF poParams:Has("headers") AND NOT poParams:IsNull("headers") THEN
                ASSIGN joBucket = poParams:GetJsonObject("headers") NO-ERROR.
            IF NOT VALID-OBJECT(joBucket) AND poParams:Has("header") AND NOT poParams:IsNull("header") THEN
                ASSIGN joBucket = poParams:GetJsonObject("header") NO-ERROR.
            RETURN joBucket.
        END.

        IF poParams:Has(cSource) AND NOT poParams:IsNull(cSource) THEN
            ASSIGN joBucket = poParams:GetJsonObject(cSource) NO-ERROR.
        RETURN joBucket.
    END METHOD.

    METHOD PRIVATE VOID addExternalRuntimeFilter(INPUT poQuery AS JsonObject, INPUT poExternal AS JsonObject, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE jaFilters AS JsonArray NO-UNDO.
        DEFINE VARIABLE jaPipeline AS JsonArray NO-UNDO.
        DEFINE VARIABLE joFilter AS JsonObject NO-UNDO.
        DEFINE VARIABLE joStep AS JsonObject NO-UNDO.
        DEFINE VARIABLE lcPayload AS LONGCHAR NO-UNDO.

        ASSIGN joFilter = NEW JsonObject().
        joFilter:Add("sourceAlias", THIS-OBJECT:getJsonChar(poExternal, "sourceAlias")).
        joFilter:Add("field", THIS-OBJECT:getJsonChar(poExternal, "field")).
        joFilter:Add("operator", THIS-OBJECT:firstNonEmpty(THIS-OBJECT:getJsonChar(poExternal, "operator"), "=")).
        joFilter:Add("value", pcValue).

        IF poQuery:Has("pipeline") AND NOT poQuery:IsNull("pipeline") THEN DO:
            ASSIGN jaPipeline = poQuery:GetJsonArray("pipeline") NO-ERROR.
            IF VALID-OBJECT(jaPipeline) THEN DO:
                ASSIGN joStep = NEW JsonObject().
                joStep:Add("type", "filter").
                joFilter:Write(lcPayload, FALSE).
                joStep:Add("payload", STRING(lcPayload)).
                jaPipeline:Add(joStep).
                RETURN.
            END.
        END.

        IF poQuery:Has("filters") AND NOT poQuery:IsNull("filters") THEN
            ASSIGN jaFilters = poQuery:GetJsonArray("filters") NO-ERROR.
        IF NOT VALID-OBJECT(jaFilters) THEN DO:
            ASSIGN jaFilters = NEW JsonArray().
            poQuery:Add("filters", jaFilters) NO-ERROR.
        END.
        jaFilters:Add(joFilter).
    END METHOD.

    METHOD PRIVATE LOGICAL hasAnyParameters(INPUT poParams AS JsonObject):
        DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.

        IF NOT VALID-OBJECT(poParams) THEN
            RETURN FALSE.
        ASSIGN cNames = poParams:GetNames() NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN FALSE.
        RETURN EXTENT(cNames) > 0.
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeExternalSource(INPUT pcSource AS CHARACTER):
        DEFINE VARIABLE cSource AS CHARACTER NO-UNDO.
        ASSIGN cSource = LC(TRIM(pcSource)).
        IF cSource = "headers" THEN
            RETURN "header".
        RETURN cSource.
    END METHOD.

    METHOD PRIVATE CHARACTER buildQueryStoreFile(INPUT pcCode AS CHARACTER):
        RETURN THIS-OBJECT:getQueryStoreRoot() + "~\" + pcCode + ".json".
    END METHOD.

    METHOD PRIVATE CHARACTER getQueryStoreRoot():
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPaths AS JsonObject NO-UNDO.
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.

        ASSIGN joConfig = THIS-OBJECT:readQueryStoreConfig().
        IF VALID-OBJECT(joConfig) AND joConfig:Has("paths") AND NOT joConfig:IsNull("paths") THEN
            ASSIGN joPaths = joConfig:GetJsonObject("paths") NO-ERROR.
        ASSIGN cBase = THIS-OBJECT:getJsonChar(joPaths, "queryStoreRoot").
        IF cBase = "" THEN
            ASSIGN cBase = "sursum-api/querys".

        ASSIGN cBase = THIS-OBJECT:resolveConfigDirectory(cBase).
        FILE-INFO:FILE-NAME = cBase.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            OS-CREATE-DIR VALUE(cBase) NO-ERROR.
        RETURN cBase.
    END METHOD.

    METHOD PRIVATE JsonObject readQueryStoreConfig():
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        ASSIGN cFile = THIS-OBJECT:resolveConfigFile("sursum-conf/query-store.json").
        FILE-INFO:FILE-NAME = cFile.
        IF FILE-INFO:FULL-PATHNAME = ? THEN
            RETURN ?.
        COPY-LOB FROM FILE cFile TO lcJson NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN ?.
        RETURN THIS-OBJECT:parseJsonObject(lcJson).
    END METHOD.

    METHOD PRIVATE LOGICAL isQueryCode(INPUT pcCode AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS CHARACTER NO-UNDO.

        IF pcCode = ? OR pcCode = "" THEN
            RETURN FALSE.
        IF LENGTH(pcCode) > 120 THEN
            RETURN FALSE.

        DO i = 1 TO LENGTH(pcCode):
            ASSIGN c = SUBSTRING(pcCode, i, 1).
            IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.", c) = 0 THEN
                RETURN FALSE.
        END.

        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL isProgramCode(INPUT pcCode AS CHARACTER):
        RETURN THIS-OBJECT:isQueryCode(pcCode).
    END METHOD.

    METHOD PRIVATE LOGICAL isAllowedProgramPath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.

        IF pcPath = ? OR TRIM(pcPath) = "" THEN
            RETURN FALSE.

        ASSIGN cPath = THIS-OBJECT:normalizeConfigPath(pcPath).
        IF INDEX(cPath, "..") > 0 THEN
            RETURN FALSE.
        IF INDEX(cPath, ":") > 0 THEN
            RETURN FALSE.
        IF LENGTH(cPath) < 3 THEN
            RETURN FALSE.
        IF LC(SUBSTRING(cPath, LENGTH(cPath) - 1)) <> ".p" THEN
            RETURN FALSE.

        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL getJsonLogical(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER, INPUT plDefault AS LOGICAL):
        DEFINE VARIABLE lValue AS LOGICAL NO-UNDO.

        IF NOT VALID-OBJECT(poJson) THEN
            RETURN plDefault.
        IF NOT poJson:Has(pcName) THEN
            RETURN plDefault.
        IF poJson:IsNull(pcName) THEN
            RETURN plDefault.
        ASSIGN lValue = poJson:GetLogical(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN plDefault.
        RETURN lValue.
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN
            RETURN pcA.
        RETURN pcB.
    END METHOD.

    METHOD PRIVATE CHARACTER getContextConfigFile():
        RETURN THIS-OBJECT:resolveConfigFile("sursum-conf/context.json").
    END METHOD.

    METHOD PRIVATE CHARACTER getConfiguredRoot(INPUT pcName AS CHARACTER, INPUT pcDefault AS CHARACTER):
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPaths AS JsonObject NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN joConfig = THIS-OBJECT:readContextConfig().
        IF VALID-OBJECT(joConfig) AND joConfig:Has("paths") AND NOT joConfig:IsNull("paths") THEN
            ASSIGN joPaths = joConfig:GetJsonObject("paths") NO-ERROR.
        ASSIGN cValue = THIS-OBJECT:getJsonChar(joPaths, pcName).
        IF cValue = "" THEN
            ASSIGN cValue = pcDefault.
        RETURN THIS-OBJECT:resolveConfigDirectory(cValue).
    END METHOD.

    METHOD PRIVATE CHARACTER getConfiguredFile(INPUT pcName AS CHARACTER, INPUT pcDefault AS CHARACTER):
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPaths AS JsonObject NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN joConfig = THIS-OBJECT:readContextConfig().
        IF VALID-OBJECT(joConfig) AND joConfig:Has("paths") AND NOT joConfig:IsNull("paths") THEN
            ASSIGN joPaths = joConfig:GetJsonObject("paths") NO-ERROR.
        ASSIGN cValue = THIS-OBJECT:getJsonChar(joPaths, pcName).
        IF cValue = "" THEN
            ASSIGN cValue = pcDefault.
        RETURN THIS-OBJECT:resolveConfigFile(cValue).
    END METHOD.

    METHOD PRIVATE CHARACTER resolveConfigFile(INPUT pcRelative AS CHARACTER):
        DEFINE VARIABLE cRelative AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFound AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDir AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iSlash AS INTEGER NO-UNDO.

        ASSIGN cRelative = THIS-OBJECT:normalizeConfigPath(pcRelative)
               cFound = SEARCH(cRelative).
        IF cFound <> ? AND cFound <> "" THEN
            RETURN REPLACE(cFound, "/", "~\").

        ASSIGN iSlash = R-INDEX(cRelative, "/").
        IF iSlash > 0 THEN DO:
            ASSIGN cDir = SUBSTRING(cRelative, 1, iSlash - 1)
                   cName = SUBSTRING(cRelative, iSlash + 1).
            RETURN THIS-OBJECT:resolveConfigDirectory(cDir) + "~\" + cName.
        END.

        RETURN cRelative.
    END METHOD.

    METHOD PRIVATE CHARACTER resolveConfigDirectory(INPUT pcRelative AS CHARACTER):
        DEFINE VARIABLE cRelative AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFound AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iSlash AS INTEGER NO-UNDO.

        ASSIGN cRelative = THIS-OBJECT:normalizeConfigPath(pcRelative)
               cFound = SEARCH(cRelative + "/.keep").
        IF cFound <> ? AND cFound <> "" THEN DO:
            ASSIGN cPath = REPLACE(cFound, "/", "~\")
                   iSlash = R-INDEX(cPath, "~\").
            IF iSlash > 0 THEN
                RETURN SUBSTRING(cPath, 1, iSlash - 1).
        END.

        ASSIGN cFound = SEARCH(cRelative).
        IF cFound <> ? AND cFound <> "" THEN
            RETURN REPLACE(cFound, "/", "~\").

        RETURN REPLACE(cRelative, "/", "~\").
    END METHOD.

    METHOD PRIVATE CHARACTER normalizeConfigPath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.

        ASSIGN cPath = TRIM(REPLACE(pcPath, "~\", "/")).
        DO WHILE INDEX(cPath, "//") > 0:
            ASSIGN cPath = REPLACE(cPath, "//", "/").
        END.
        IF SUBSTRING(cPath, 1, 1) = "/" THEN
            ASSIGN cPath = SUBSTRING(cPath, 2).
        RETURN cPath.
    END METHOD.

    METHOD PRIVATE LOGICAL isRelationIdentifier(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS CHARACTER NO-UNDO.

        IF pcName = ? OR pcName = "" THEN
            RETURN FALSE.
        IF LENGTH(pcName) > 64 THEN
            RETURN FALSE.

        DO i = 1 TO LENGTH(pcName):
            ASSIGN c = SUBSTRING(pcName, i, 1).
            IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", c) = 0 THEN
                RETURN FALSE.
        END.

        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE CHARACTER getJsonChar(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        IF NOT VALID-OBJECT(poJson) THEN
            RETURN "".
        IF NOT poJson:Has(pcName) THEN
            RETURN "".
        IF poJson:IsNull(pcName) THEN
            RETURN "".

        ASSIGN cValue = poJson:GetCharacter(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN "".
        RETURN cValue.
    END METHOD.

    METHOD PRIVATE CHARACTER getQueryValue(INPUT pcQuery AS CHARACTER, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE cPair AS CHARACTER NO-UNDO.

        IF pcQuery = ? OR pcQuery = "" THEN
            RETURN "".

        DO i = 1 TO NUM-ENTRIES(pcQuery, "&"):
            ASSIGN cPair = ENTRY(i, pcQuery, "&").
            IF ENTRY(1, cPair + "=", "=") = pcName THEN
                RETURN ENTRY(2, cPair + "=", "=").
        END.

        RETURN "".
    END METHOD.

    METHOD PRIVATE LOGICAL hasSyncOption(INPUT pcInclude AS CHARACTER, INPUT pcOption AS CHARACTER):
        DEFINE VARIABLE iOption AS INTEGER NO-UNDO.
        DEFINE VARIABLE cOption AS CHARACTER NO-UNDO.

        DO iOption = 1 TO NUM-ENTRIES(pcInclude):
            ASSIGN cOption = TRIM(ENTRY(iOption, pcInclude)).
            IF LC(cOption) = LC(pcOption) THEN
                RETURN TRUE.
        END.

        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE LONGCHAR escapeJsonForWeb(INPUT pcJson AS LONGCHAR):
        DEFINE VARIABLE lcEscaped AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE cChar AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cHex AS CHARACTER NO-UNDO INITIAL "0123456789ABCDEF".
        DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLen AS INTEGER NO-UNDO.
        DEFINE VARIABLE iCode AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNibble AS INTEGER NO-UNDO.
        DEFINE VARIABLE cEscape AS CHARACTER NO-UNDO.

        IF pcJson = ? THEN
            RETURN pcJson.

        FIX-CODEPAGE(lcEscaped) = "UTF-8".
        ASSIGN iLen = LENGTH(pcJson).

        DO iPos = 1 TO iLen:
            ASSIGN cChar = SUBSTRING(pcJson, iPos, 1)
                   iCode = ASC(cChar) NO-ERROR.

            IF ERROR-STATUS:ERROR OR iCode = ? THEN DO:
                ERROR-STATUS:ERROR = FALSE.
                ASSIGN lcEscaped = lcEscaped + "\uFFFD".
                NEXT.
            END.

            IF iCode > 126 THEN DO:
                ASSIGN cEscape = "\u"
                       iNibble = TRUNCATE(iCode / 4096, 0)
                       cEscape = cEscape + SUBSTRING(cHex, iNibble + 1, 1)
                       iCode = iCode MODULO 4096
                       iNibble = TRUNCATE(iCode / 256, 0)
                       cEscape = cEscape + SUBSTRING(cHex, iNibble + 1, 1)
                       iCode = iCode MODULO 256
                       iNibble = TRUNCATE(iCode / 16, 0)
                       cEscape = cEscape + SUBSTRING(cHex, iNibble + 1, 1)
                       iNibble = iCode MODULO 16
                       cEscape = cEscape + SUBSTRING(cHex, iNibble + 1, 1)
                       lcEscaped = lcEscaped + cEscape.
            END.
            ELSE
                ASSIGN lcEscaped = lcEscaped + cChar.
        END.

        RETURN lcEscaped.
    END METHOD.

    METHOD PRIVATE VOID writeJson(INPUT poJson AS JsonObject):
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE oResponse AS WebResponse NO-UNDO.
        DEFINE VARIABLE oWriter AS WebResponseWriter NO-UNDO.

        IF NOT VALID-OBJECT(poJson) THEN
            ASSIGN poJson = THIS-OBJECT:buildError("NO_RESPONSE", "Resposta nao gerada", "").

        FIX-CODEPAGE(lcJson) = "UTF-8".
        poJson:Write(lcJson, TRUE).

        ASSIGN oResponse = NEW WebResponse()
               oWriter = NEW WebResponseWriter(oResponse).

        oResponse:SetHeader("Content-Type":U, "application/json; charset=UTF-8":U).
        oResponse:SetHeader("Cache-Control":U, "no-store":U).
        oResponse:SetHeader("Access-Control-Allow-Methods":U, "GET, POST, OPTIONS":U).
        oResponse:SetHeader("Access-Control-Allow-Headers":U, "Content-Type, Accept, Origin":U).

        oWriter:Open().
        oWriter:Write(lcJson).
        oWriter:Flush().
        oWriter:Close().

        DELETE OBJECT oWriter NO-ERROR.
        DELETE OBJECT oResponse NO-ERROR.
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

END CLASS.
