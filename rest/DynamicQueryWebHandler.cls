/*
WebHandler HTTP para validacao REST real no PASOE.
URLs esperadas:
  GET  /web/SursumDynamicQuery
  POST /web/SursumDynamicQuery/query
  GET  /web/SursumDynamicQuery/jobs/{jobId}
  GET  /web/SursumDynamicQuery/jobs/{jobId}/result
  POST /web/SursumDynamicQuery/jobs/drain
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

    DEFINE QUERY qBenchCustomer FOR Customer
        FIELDS(CustNum)
        SCROLLING.

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
                    IF cPath MATCHES "*/jobs/drain" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleDrain().
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
                    IF cPath MATCHES "*/metadata/cache-status" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleMetadataCacheStatus().
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
                    ELSE IF cPath MATCHES "*/metadata/relations/*/*" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetRelation(cPath).
                    END.
                    ELSE IF THIS-OBJECT:isRootPath(cPath) THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleIndex().
                    END.
                    ELSE IF cPath MATCHES "*/benchmarks/customer-count" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleCustomerCountBenchmark().
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

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /query").

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

    METHOD PRIVATE JsonObject handleIndex():
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joEndpoints AS JsonObject NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               joEndpoints = NEW JsonObject().

        joEndpoints:Add("query", "POST /web/SursumDynamicQuery/query").
        joEndpoints:Add("metadataDatabases", "GET /web/SursumDynamicQuery/metadata/databases").
        joEndpoints:Add("metadataCacheStatus", "GET /web/SursumDynamicQuery/metadata/cache-status?database=:database").
        joEndpoints:Add("metadataTables", "GET /web/SursumDynamicQuery/metadata/tables").
        joEndpoints:Add("metadataFields", "GET /web/SursumDynamicQuery/metadata/tables/:table/fields").
        joEndpoints:Add("metadataSaveRelation", "POST /web/SursumDynamicQuery/metadata/relations").
        joEndpoints:Add("metadataGetRelation", "GET /web/SursumDynamicQuery/metadata/relations/:left/:right").
        joEndpoints:Add("drain", "POST /web/SursumDynamicQuery/jobs/drain").
        joEndpoints:Add("jobStatus", "GET /web/SursumDynamicQuery/jobs/:jobId").
        joEndpoints:Add("jobResult", "GET /web/SursumDynamicQuery/jobs/:jobId/result").
        joEndpoints:Add("customerCountBenchmark", "GET /web/SursumDynamicQuery/benchmarks/customer-count").

        joRet:Add("success", TRUE).
        joRet:Add("service", "SursumDynamicQuery").
        joRet:Add("runtime", "PASOE-WEB").
        joRet:Add("endpoints", joEndpoints).

        RETURN joRet.
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
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().

        IF cDatabase = "TODOS" OR cDatabase = "ALL" THEN DO:
            ASSIGN lHasCache = NUM-DBS > 0.
            DO iDb = 1 TO NUM-DBS:
                ASSIGN cFile = "D:\opencode\motor-progress\conf\metadata~\" + LC(LDBNAME(iDb)) + "__tables.json".
                FILE-INFO:FILE-NAME = cFile.
                IF FILE-INFO:FULL-PATHNAME = ? THEN
                    ASSIGN lHasCache = FALSE.
            END.
        END.
        ELSE DO:
            ASSIGN cFile = "D:\opencode\motor-progress\conf\metadata~\" + LC(cDatabase) + "__tables.json".
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

    METHOD PRIVATE JsonObject handleDrain():
        DEFINE VARIABLE oOptions AS DynamicQueryWorkerOptions NO-UNDO.
        DEFINE VARIABLE oWorker AS DynamicQueryWorkerService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN oOptions = NEW DynamicQueryWorkerOptions()
               oWorker = NEW DynamicQueryWorkerService().

        oOptions:setExecutionMode("PASOE").
        oOptions:setWorkerName("pasoe-web-drain").
        oOptions:setBatchSize(10).
        oOptions:setOutputDirectory("D:\opencode\motor-progress\output\jobs").

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

    METHOD PRIVATE JsonObject handleCustomerCountBenchmark():
        DEFINE VARIABLE iCount AS INT64 NO-UNDO.
        DEFINE VARIABLE iForEachMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iOpenMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResultsMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResults AS INTEGER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joForEach AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPreselect AS JsonObject NO-UNDO.

        ETIME(TRUE).
        FOR EACH Customer NO-LOCK:
            ASSIGN iCount = iCount + 1.
        END.
        ASSIGN iForEachMs = ETIME.

        ETIME(TRUE).
        OPEN QUERY qBenchCustomer PRESELECT EACH Customer NO-LOCK.
        ASSIGN iOpenMs = ETIME.

        ETIME(TRUE).
        ASSIGN iNumResults = NUM-RESULTS("qBenchCustomer").
        ASSIGN iNumResultsMs = ETIME.

        CLOSE QUERY qBenchCustomer.

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
            ASSIGN cDatabase = THIS-OBJECT:getDefaultDatabase().
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
               cUpdatedAt = STRING(NOW).

        THIS-OBJECT:writeMetadataCacheFile(cDatabaseDisplay, "fields", pcTable, jaFields).

        joRet:Add("success", TRUE).
        joRet:Add("database", cDatabaseDisplay).
        joRet:Add("updatedAt", cUpdatedAt).
        joRet:Add("table", pcTable).
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

        ASSIGN cBase = "D:\opencode\motor-progress\conf\relations"
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

    METHOD PRIVATE VOID writeMetadataCacheFile(INPUT pcDatabase AS CHARACTER, INPUT pcKind AS CHARACTER, INPUT pcTable AS CHARACTER, INPUT poData AS JsonArray):
        DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcData AS LONGCHAR NO-UNDO.

        IF NOT VALID-OBJECT(poData) THEN
            RETURN.

        FIX-CODEPAGE(lcData) = "UTF-8".
        FIX-CODEPAGE(lcJson) = "UTF-8".

        ASSIGN cBase = "D:\opencode\motor-progress\conf\metadata".
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

        oResponse:SetHeader("Content-Type":U, "application/json; charset=windows-1252":U).
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
