/*
Runtime screen service for builder contracts.
Loads declarative screen metadata and executes closed endpoints by id.
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.ObjectModelParser.

CLASS RuntimeScreenService:

    METHOD PUBLIC JsonObject getScreenDefinition(INPUT pcScreenId AS CHARACTER):
        DEFINE VARIABLE joScreen AS JsonObject NO-UNDO.
        DEFINE VARIABLE joDefinition AS JsonObject NO-UNDO.

        IF NOT THIS-OBJECT:isSafeId(pcScreenId) THEN
            RETURN THIS-OBJECT:buildError("INVALID_SCREEN_ID", "screenId invalido.", pcScreenId).

        ASSIGN joScreen = THIS-OBJECT:getScreen(pcScreenId).
        IF NOT VALID-OBJECT(joScreen) THEN
            RETURN THIS-OBJECT:buildError("SCREEN_NOT_FOUND", "Tela nao configurada.", pcScreenId).

        ASSIGN joDefinition = joScreen:GetJsonObject("definition") NO-ERROR.
        IF NOT VALID-OBJECT(joDefinition) THEN
            RETURN THIS-OBJECT:buildError("SCREEN_DEFINITION_NOT_CONFIGURED", "Definicao da tela nao configurada.", pcScreenId).

        RETURN THIS-OBJECT:cloneJsonObject(joDefinition).
    END METHOD.

    METHOD PUBLIC JsonObject executeEndpoint(INPUT pcScreenId AS CHARACTER, INPUT pcEndpointId AS CHARACTER, INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE joScreen AS JsonObject NO-UNDO.
        DEFINE VARIABLE joEndpoints AS JsonObject NO-UNDO.
        DEFINE VARIABLE joEndpoint AS JsonObject NO-UNDO.
        DEFINE VARIABLE cType AS CHARACTER NO-UNDO.

        IF NOT THIS-OBJECT:isSafeId(pcScreenId) THEN
            RETURN THIS-OBJECT:buildError("INVALID_SCREEN_ID", "screenId invalido.", pcScreenId).
        IF NOT THIS-OBJECT:isSafeId(pcEndpointId) THEN
            RETURN THIS-OBJECT:buildError("INVALID_ENDPOINT_ID", "endpointId invalido.", pcEndpointId).

        ASSIGN joScreen = THIS-OBJECT:getScreen(pcScreenId).
        IF NOT VALID-OBJECT(joScreen) THEN
            RETURN THIS-OBJECT:buildError("SCREEN_NOT_FOUND", "Tela nao configurada.", pcScreenId).

        IF joScreen:Has("endpoints") AND NOT joScreen:IsNull("endpoints") THEN
            ASSIGN joEndpoints = joScreen:GetJsonObject("endpoints") NO-ERROR.
        IF NOT VALID-OBJECT(joEndpoints) OR NOT joEndpoints:Has(pcEndpointId) OR joEndpoints:IsNull(pcEndpointId) THEN
            RETURN THIS-OBJECT:buildError("ENDPOINT_NOT_CONFIGURED", "Endpoint da tela nao configurado.", pcScreenId + "/" + pcEndpointId).

        ASSIGN joEndpoint = joEndpoints:GetJsonObject(pcEndpointId) NO-ERROR.
        IF NOT VALID-OBJECT(joEndpoint) THEN
            RETURN THIS-OBJECT:buildError("ENDPOINT_NOT_CONFIGURED", "Endpoint da tela nao configurado.", pcScreenId + "/" + pcEndpointId).

        ASSIGN cType = LC(THIS-OBJECT:getJsonChar(joEndpoint, "type")).
        CASE cType:
            WHEN "query" THEN
                RETURN THIS-OBJECT:executeQueryEndpoint(pcScreenId, pcEndpointId, joEndpoint, pcBody).
            WHEN "program" THEN
                RETURN THIS-OBJECT:executeProgramEndpoint(pcScreenId, pcEndpointId, joEndpoint, pcBody).
            OTHERWISE
                RETURN THIS-OBJECT:buildError("ENDPOINT_TYPE_NOT_SUPPORTED", "Tipo de endpoint nao suportado.", cType).
        END CASE.
    END METHOD.

    METHOD PRIVATE JsonObject executeQueryEndpoint(INPUT pcScreenId AS CHARACTER, INPUT pcEndpointId AS CHARACTER, INPUT poEndpoint AS JsonObject, INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
        DEFINE VARIABLE joQuery AS JsonObject NO-UNDO.
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRaw AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        IF NOT poEndpoint:Has("query") OR poEndpoint:IsNull("query") THEN
            RETURN THIS-OBJECT:buildError("ENDPOINT_QUERY_NOT_CONFIGURED", "Query do endpoint nao configurada.", pcScreenId + "/" + pcEndpointId).

        ASSIGN joQuery = poEndpoint:GetJsonObject("query") NO-ERROR.
        IF NOT VALID-OBJECT(joQuery) THEN
            RETURN THIS-OBJECT:buildError("ENDPOINT_QUERY_NOT_CONFIGURED", "Query do endpoint nao configurada.", pcScreenId + "/" + pcEndpointId).

        ASSIGN joQuery = THIS-OBJECT:cloneJsonObject(joQuery)
               joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN
            ASSIGN joBody = NEW JsonObject().

        ASSIGN joRet = THIS-OBJECT:applyEndpointRequest(poEndpoint, joQuery, joBody).
        IF VALID-OBJECT(joRet) THEN
            RETURN joRet.

        ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
               oRequest = oSerializer:fromJsonObject(joQuery)
               oContext = NEW PasoeExecutionContext()
               oService = NEW DynamicMultiTableQueryService().

        oContext:setCustomField("entrypoint", "RUNTIME").
        oContext:setCustomField("screenId", pcScreenId).
        oContext:setCustomField("endpointId", pcEndpointId).

        ASSIGN joRaw = oService:execute(oRequest, oContext).
        ASSIGN joRet = THIS-OBJECT:shapeQueryResponse(poEndpoint, joRaw).

        DELETE OBJECT oSerializer NO-ERROR.
        DELETE OBJECT oRequest NO-ERROR.
        DELETE OBJECT oContext NO-ERROR.
        DELETE OBJECT oService NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject executeProgramEndpoint(INPUT pcScreenId AS CHARACTER, INPUT pcEndpointId AS CHARACTER, INPUT poEndpoint AS JsonObject, INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE joParams AS JsonObject NO-UNDO.
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE cProgramCode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cProgramPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRunPath AS CHARACTER NO-UNDO.

        ASSIGN cProgramCode = THIS-OBJECT:getJsonChar(poEndpoint, "program").
        IF NOT THIS-OBJECT:isSafeId(cProgramCode) THEN
            RETURN THIS-OBJECT:buildError("INVALID_PROGRAM_CODE", "Codigo de programa invalido.", cProgramCode).

        ASSIGN cProgramPath = THIS-OBJECT:getConfiguredProgramPath(cProgramCode).
        IF cProgramPath = "" THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_NOT_ALLOWED", "Programa nao cadastrado para execucao.", cProgramCode).
        IF NOT THIS-OBJECT:isAllowedProgramPath(cProgramPath) THEN
            RETURN THIS-OBJECT:buildError("INVALID_PROGRAM_PATH", "Caminho de programa invalido no catalogo.", cProgramCode + "=" + cProgramPath).

        ASSIGN cRunPath = THIS-OBJECT:resolveProgramRunPath(cProgramPath).
        IF cRunPath = "" THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_NOT_FOUND", "Programa cadastrado nao encontrado no PROPATH.", cProgramCode + "=" + cProgramPath).

        ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
        IF NOT VALID-OBJECT(joBody) THEN
            ASSIGN joBody = NEW JsonObject().

        ASSIGN joParams = NEW JsonObject().
        joParams:Add("screenId", pcScreenId).
        joParams:Add("endpointId", pcEndpointId).
        joParams:Add("program", cProgramCode).
        joParams:Add("payload", joBody).

        RUN VALUE(cRunPath) (INPUT joParams, OUTPUT joRet) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_EXECUTION_ERROR", "Erro ao executar programa Progress.", ERROR-STATUS:GET-MESSAGE(1)).
        IF NOT VALID-OBJECT(joRet) THEN
            RETURN THIS-OBJECT:buildError("PROGRAM_EMPTY_RESPONSE", "Programa nao retornou JsonObject.", cProgramCode).

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject applyEndpointRequest(INPUT poEndpoint AS JsonObject, INPUT poQuery AS JsonObject, INPUT poBody AS JsonObject):
        DEFINE VARIABLE jaFilters AS JsonArray NO-UNDO.
        DEFINE VARIABLE joFilter AS JsonObject NO-UNDO.
        DEFINE VARIABLE cEndpointIdField AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

        ASSIGN cEndpointIdField = THIS-OBJECT:getJsonChar(poEndpoint, "idField").
        IF cEndpointIdField <> "" THEN DO:
            ASSIGN cValue = THIS-OBJECT:getJsonChar(poBody, cEndpointIdField).
            IF cValue = "" THEN
                ASSIGN cValue = THIS-OBJECT:getJsonChar(poBody, "id").
            IF cValue = "" THEN
                RETURN THIS-OBJECT:buildError("ID_REQUIRED", "Identificador obrigatorio.", cEndpointIdField).

            IF poQuery:Has("filters") AND NOT poQuery:IsNull("filters") THEN
                ASSIGN jaFilters = poQuery:GetJsonArray("filters") NO-ERROR.
            IF NOT VALID-OBJECT(jaFilters) THEN DO:
                ASSIGN jaFilters = NEW JsonArray().
                poQuery:Add("filters", jaFilters) NO-ERROR.
            END.

            IF poEndpoint:Has("idFilter") AND NOT poEndpoint:IsNull("idFilter") THEN
                ASSIGN joFilter = THIS-OBJECT:cloneJsonObject(poEndpoint:GetJsonObject("idFilter")).
            IF NOT VALID-OBJECT(joFilter) THEN DO:
                ASSIGN joFilter = NEW JsonObject().
                joFilter:Add("sourceAlias", "customer").
                joFilter:Add("field", "CustNum").
                joFilter:Add("operator", "=").
            END.
            joFilter:Add("value", cValue).
            jaFilters:Add(joFilter).
        END.

        RETURN ?.
    END METHOD.

    METHOD PRIVATE JsonObject shapeQueryResponse(INPUT poEndpoint AS JsonObject, INPUT poRaw AS JsonObject):
        DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaData AS JsonArray NO-UNDO.
        DEFINE VARIABLE cMode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iTotal AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poRaw) THEN
            RETURN THIS-OBJECT:buildError("QUERY_EMPTY_RESPONSE", "Query nao retornou JsonObject.", "").
        IF poRaw:Has("error") THEN
            RETURN poRaw.

        IF poEndpoint:Has("response") AND NOT poEndpoint:IsNull("response") THEN
            ASSIGN joResponse = poEndpoint:GetJsonObject("response") NO-ERROR.
        ASSIGN cMode = THIS-OBJECT:getJsonChar(joResponse, "mode").

        IF cMode = "crudRead" THEN DO:
            ASSIGN joRet = NEW JsonObject().
            IF poRaw:Has("data") AND NOT poRaw:IsNull("data") THEN
                ASSIGN jaData = poRaw:GetJsonArray("data") NO-ERROR.
            IF VALID-OBJECT(jaData) THEN
                joRet:Add("data", jaData).
            ELSE
                joRet:Add("data", NEW JsonArray()).
            ASSIGN iTotal = THIS-OBJECT:getJsonInt(poRaw, "total", THIS-OBJECT:getJsonInt(poRaw, "recordsReturned", 0)).
            joRet:Add("total", iTotal).
            RETURN joRet.
        END.

        IF cMode = "crudGet" THEN DO:
            ASSIGN joRet = NEW JsonObject().
            IF poRaw:Has("data") AND NOT poRaw:IsNull("data") THEN
                ASSIGN jaData = poRaw:GetJsonArray("data") NO-ERROR.
            IF VALID-OBJECT(jaData) AND jaData:Length > 0 THEN
                joRet:Add("data", jaData:GetJsonObject(1)).
            ELSE
                joRet:Add("data", NEW JsonObject()).
            RETURN joRet.
        END.

        RETURN poRaw.
    END METHOD.

    METHOD PRIVATE JsonObject getScreen(INPUT pcScreenId AS CHARACTER):
        DEFINE VARIABLE joCatalog AS JsonObject NO-UNDO.
        DEFINE VARIABLE joScreens AS JsonObject NO-UNDO.

        ASSIGN joCatalog = THIS-OBJECT:readRuntimeCatalog().
        IF VALID-OBJECT(joCatalog) AND joCatalog:Has("screens") AND NOT joCatalog:IsNull("screens") THEN
            ASSIGN joScreens = joCatalog:GetJsonObject("screens") NO-ERROR.
        IF VALID-OBJECT(joScreens) AND joScreens:Has(pcScreenId) AND NOT joScreens:IsNull(pcScreenId) THEN
            RETURN joScreens:GetJsonObject(pcScreenId).
        RETURN ?.
    END METHOD.

    METHOD PRIVATE JsonObject readRuntimeCatalog():
        RETURN THIS-OBJECT:readJsonFile(THIS-OBJECT:resolveConfigFile("sursum-conf/runtime-screens.json")).
    END METHOD.

    METHOD PRIVATE JsonObject readProgramExecutorConfig():
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.

        ASSIGN joConfig = THIS-OBJECT:readJsonFile(THIS-OBJECT:resolveConfigFile("sursum-conf/program-executor.json")).
        IF VALID-OBJECT(joConfig) THEN
            RETURN joConfig.

        ASSIGN joConfig = THIS-OBJECT:readJsonFile("/dados/pasoe/sursum-api/sursum-conf/program-executor.json").
        IF VALID-OBJECT(joConfig) THEN
            RETURN joConfig.

        RETURN THIS-OBJECT:readJsonFile("/mnt/datasul/ERP/sursum/sursum-conf/program-executor.json").
    END METHOD.

    METHOD PRIVATE CHARACTER getConfiguredProgramPath(INPUT pcProgramCode AS CHARACTER):
        DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPrograms AS JsonObject NO-UNDO.

        ASSIGN joConfig = THIS-OBJECT:readProgramExecutorConfig().
        IF VALID-OBJECT(joConfig) AND joConfig:Has("programs") AND NOT joConfig:IsNull("programs") THEN
            ASSIGN joPrograms = joConfig:GetJsonObject("programs") NO-ERROR.
        RETURN THIS-OBJECT:getJsonChar(joPrograms, pcProgramCode).
    END METHOD.

    METHOD PRIVATE CHARACTER resolveProgramRunPath(INPUT pcProgramPath AS CHARACTER):
        DEFINE VARIABLE cResolved AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cRun AS CHARACTER NO-UNDO.

        ASSIGN cResolved = THIS-OBJECT:resolveConfigFile(pcProgramPath)
               cRun = THIS-OBJECT:firstExistingProgramArtifact(cResolved).
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

    METHOD PRIVATE JsonObject parseJsonObject(INPUT pcJson AS LONGCHAR):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.

        IF pcJson = ? OR pcJson = "" THEN
            RETURN ?.
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

    METHOD PRIVATE JsonObject cloneJsonObject(INPUT poJson AS JsonObject):
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.

        IF NOT VALID-OBJECT(poJson) THEN
            RETURN ?.
        poJson:Write(lcJson, TRUE).
        RETURN THIS-OBJECT:parseJsonObject(lcJson).
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
        IF cPath <> "" AND SUBSTRING(cPath, 1, 1) = "/" THEN
            ASSIGN cPath = SUBSTRING(cPath, 2).
        RETURN cPath.
    END METHOD.

    METHOD PRIVATE LOGICAL isSafeId(INPUT pcCode AS CHARACTER):
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

    METHOD PRIVATE INTEGER getJsonInt(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER, INPUT piDefault AS INTEGER):
        DEFINE VARIABLE iValue AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poJson) THEN
            RETURN piDefault.
        IF NOT poJson:Has(pcName) THEN
            RETURN piDefault.
        IF poJson:IsNull(pcName) THEN
            RETURN piDefault.

        ASSIGN iValue = poJson:GetInteger(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN piDefault.
        RETURN iValue.
    END METHOD.

    METHOD PRIVATE JsonObject buildError(INPUT pcCode AS CHARACTER, INPUT pcMessage AS CHARACTER, INPUT pcDetails AS CHARACTER):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               joErr = NEW JsonObject().
        joErr:Add("code", pcCode).
        joErr:Add("message", pcMessage).
        joErr:Add("details", pcDetails).
        joRet:Add("error", joErr).
        RETURN joRet.
    END METHOD.

END CLASS.
