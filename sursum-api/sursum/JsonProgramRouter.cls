USING Progress.Json.ObjectModel.*.
USING Progress.Lang.Error.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* Independent JSON-to-program router. No dependency on the query engine. */
CLASS JsonProgramRouter:
    DEFINE PUBLIC PROPERTY StatusCode AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY AllowMethods AS CHARACTER NO-UNDO GET. PRIVATE SET.
    DEFINE PRIVATE VARIABLE cConfigFile AS CHARACTER NO-UNDO.
    DEFINE PRIVATE TEMP-TABLE ttRoute NO-UNDO
        FIELD routePath AS CHARACTER CASE-SENSITIVE
        FIELD httpMethod AS CHARACTER
        FIELD programPath AS CHARACTER
        FIELD responseMode AS CHARACTER
        INDEX routeMethod IS UNIQUE routePath httpMethod.

    CONSTRUCTOR PUBLIC JsonProgramRouter(INPUT pcConfigFile AS CHARACTER):
        ASSIGN cConfigFile = pcConfigFile StatusCode = 200 AllowMethods = "".
    END CONSTRUCTOR.

    METHOD PUBLIC LONGCHAR dispatch(INPUT pcMethod AS CHARACTER, INPUT pcPath AS CHARACTER,
                                   INPUT pcQuery AS CHARACTER, INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE cMethod AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cProgram AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cArtifact AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cResponseMode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cMethods AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oParsed AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE oInput AS JsonObject NO-UNDO.
        DEFINE VARIABLE oOutput AS JsonObject NO-UNDO.
        DEFINE VARIABLE lcBody AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcReply AS LONGCHAR NO-UNDO.
        FIX-CODEPAGE(lcBody) = "UTF-8".
        FIX-CODEPAGE(lcReply) = "UTF-8".
        ASSIGN StatusCode = 200 AllowMethods = "" cMethod = CAPS(TRIM(pcMethod)).

        IF NOT THIS-OBJECT:loadRoutes() THEN
            RETURN THIS-OBJECT:failure(500, "INVALID_ROUTE_CONFIG", "Arquivo de rotas ausente ou invalido").
        FOR EACH ttRoute WHERE ttRoute.routePath = pcPath:
            cMethods = cMethods + (IF cMethods = "" THEN "" ELSE ",") + ttRoute.httpMethod.
            IF ttRoute.httpMethod = cMethod THEN ASSIGN cProgram = ttRoute.programPath cResponseMode = ttRoute.responseMode.
        END.
        IF cMethods = "" THEN
            RETURN THIS-OBJECT:failure(404, "ROUTE_NOT_FOUND", "Rota nao cadastrada").
        AllowMethods = cMethods + ",OPTIONS".
        IF cMethod = "OPTIONS" THEN DO:
            StatusCode = 204.
            RETURN "".
        END.
        IF cProgram = "" THEN
            RETURN THIS-OBJECT:failure(405, "METHOD_NOT_ALLOWED", "Metodo nao permitido para a rota").

        IF cMethod = "GET" THEN
            oInput = THIS-OBJECT:queryObject(pcQuery).
        ELSE IF pcBody = ? OR TRIM(pcBody) = "" THEN
            oInput = NEW JsonObject().
        ELSE DO:
            ASSIGN lcBody = pcBody oParser = NEW ObjectModelParser().
            ASSIGN oParsed = oParser:Parse(lcBody) NO-ERROR.
            IF NOT VALID-OBJECT(oParsed) THEN
                RETURN THIS-OBJECT:failure(400, "INVALID_JSON", "O corpo deve ser um objeto JSON valido").
            ASSIGN oInput = CAST(oParsed, JsonObject) NO-ERROR.
            IF NOT VALID-OBJECT(oInput) THEN
                RETURN THIS-OBJECT:failure(400, "INVALID_JSON", "O corpo deve ser um objeto JSON valido").
        END.
        IF NOT VALID-OBJECT(oInput) THEN
            RETURN THIS-OBJECT:failure(400, "INVALID_QUERY_STRING", "Query string invalida").

        /* Runtime installations may contain only compiled artifacts. Prefer .r. */
        cArtifact = SEARCH(SUBSTRING(cProgram, 1, LENGTH(cProgram) - 2) + ".r").
        IF cArtifact = ? THEN cArtifact = SEARCH(cProgram).
        IF cArtifact = ? THEN
            RETURN THIS-OBJECT:failure(500, "PROGRAM_NOT_FOUND", "Programa cadastrado nao encontrado no PROPATH").
        IF cResponseMode = "raw-longchar" THEN DO:
            RUN VALUE(cArtifact) (INPUT oInput, OUTPUT lcReply) NO-ERROR.
            IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN
                RETURN THIS-OBJECT:failure(500, "PROGRAM_EXECUTION_ERROR", "Falha ao executar o programa cadastrado").
            RETURN lcReply.
        END.
        RUN VALUE(cArtifact) (INPUT oInput, OUTPUT oOutput) NO-ERROR.
        IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN
            RETURN THIS-OBJECT:failure(500, "PROGRAM_EXECUTION_ERROR", "Falha ao executar o programa cadastrado").
        IF NOT VALID-OBJECT(oOutput) THEN
            RETURN THIS-OBJECT:failure(500, "PROGRAM_EMPTY_RESPONSE", "O programa nao retornou JsonObject").
        oOutput:Write(lcReply, TRUE).
        RETURN lcReply.

        CATCH oError AS Error:
            RETURN THIS-OBJECT:failure(500, "PROGRAM_EXECUTION_ERROR", "Falha ao processar a requisicao").
        END CATCH.
        FINALLY:
            /* Serialize before cleanup: output may be the input object itself. */
            IF VALID-OBJECT(oOutput) THEN DELETE OBJECT oOutput.
            IF VALID-OBJECT(oInput) THEN DELETE OBJECT oInput.
            IF VALID-OBJECT(oParsed) THEN DELETE OBJECT oParsed.
            IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
        END FINALLY.
    END METHOD.

    METHOD PRIVATE LOGICAL loadRoutes():
        DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oParsed AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE oConfig AS JsonObject NO-UNDO.
        DEFINE VARIABLE aRoutes AS JsonArray NO-UNDO.
        DEFINE VARIABLE oRoute AS JsonObject NO-UNDO.
        DEFINE VARIABLE cRoute AS CHARACTER CASE-SENSITIVE NO-UNDO.
        DEFINE VARIABLE cMethod AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cProgram AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cResponseMode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        EMPTY TEMP-TABLE ttRoute.
        FIX-CODEPAGE(lcConfig) = "UTF-8".
        cFile = SEARCH(cConfigFile).
        IF cFile = ? THEN RETURN FALSE.
        COPY-LOB FROM FILE cFile TO lcConfig.
        ASSIGN oParser = NEW ObjectModelParser()
               oParsed = oParser:Parse(lcConfig)
               oConfig = CAST(oParsed, JsonObject)
               aRoutes = oConfig:GetJsonArray("routes").
        DO i = 1 TO aRoutes:Length:
            ASSIGN oRoute = aRoutes:GetJsonObject(i)
                   cRoute = oRoute:GetCharacter("route")
                   cMethod = CAPS(TRIM(oRoute:GetCharacter("method")))
                   cProgram = oRoute:GetCharacter("program")
                   cResponseMode = "".
            IF oRoute:Has("response") THEN cResponseMode = oRoute:GetCharacter("response").
            IF NOT THIS-OBJECT:isRoutePath(cRoute) OR NOT THIS-OBJECT:isProgramPath(cProgram) THEN RETURN FALSE.
            IF cMethod = ? OR NUM-ENTRIES(cMethod) <> 1 THEN RETURN FALSE.
            IF LOOKUP(cMethod, "GET,POST,PUT,PATCH,DELETE") = 0 THEN RETURN FALSE.
            IF cResponseMode <> "" AND cResponseMode <> "raw-longchar" THEN RETURN FALSE.
            FIND FIRST ttRoute WHERE ttRoute.routePath = cRoute AND ttRoute.httpMethod = cMethod NO-ERROR.
            IF AVAILABLE ttRoute THEN RETURN FALSE.
            CREATE ttRoute.
            ASSIGN ttRoute.routePath = cRoute ttRoute.httpMethod = cMethod ttRoute.programPath = cProgram ttRoute.responseMode = cResponseMode.
        END.
        RETURN TRUE.
        CATCH oError AS Error:
            RETURN FALSE.
        END CATCH.
        FINALLY:
            IF VALID-OBJECT(oParsed) THEN DELETE OBJECT oParsed.
            IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
        END FINALLY.
    END METHOD.

    METHOD PRIVATE LOGICAL isRoutePath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF pcPath = ? OR pcPath = "" THEN RETURN FALSE.
        IF SUBSTRING(pcPath, 1, 1) <> "/" OR INDEX(pcPath, "//") > 0 OR INDEX(pcPath, "..") > 0 THEN RETURN FALSE.
        DO i = 1 TO LENGTH(pcPath):
            IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/_-.", SUBSTRING(pcPath, i, 1)) = 0 THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL isProgramPath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF pcPath = ? OR pcPath = "" THEN RETURN FALSE.
        IF NOT pcPath MATCHES "*.p" THEN RETURN FALSE.
        IF NOT (pcPath BEGINS "sursum-api/" OR
                pcPath BEGINS "especificos/ems2/ima/http-api/") THEN RETURN FALSE.
        IF INDEX(pcPath, "..") > 0 OR INDEX(pcPath, "//") > 0 THEN RETURN FALSE.
        DO i = 1 TO LENGTH(pcPath):
            IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/_-.", SUBSTRING(pcPath, i, 1)) = 0 THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE JsonObject queryObject(INPUT pcQuery AS CHARACTER):
        DEFINE VARIABLE oQuery AS JsonObject NO-UNDO.
        DEFINE VARIABLE aValues AS JsonArray NO-UNDO.
        DEFINE VARIABLE cPair AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cOld AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE iEquals AS INTEGER NO-UNDO.
        oQuery = NEW JsonObject().
        IF pcQuery = ? OR pcQuery = "" THEN RETURN oQuery.
        DO i = 1 TO NUM-ENTRIES(pcQuery, "&"):
            ASSIGN cPair = ENTRY(i, pcQuery, "&") iEquals = INDEX(cPair, "=").
            IF cPair = "" THEN NEXT.
            ASSIGN cName = IF iEquals = 0 THEN cPair ELSE SUBSTRING(cPair, 1, iEquals - 1)
                   cValue = IF iEquals = 0 THEN "" ELSE SUBSTRING(cPair, iEquals + 1)
                   cName = THIS-OBJECT:decodeQueryComponent(cName)
                   cValue = THIS-OBJECT:decodeQueryComponent(cValue).
            IF cName = "" THEN UNDO, THROW NEW Progress.Lang.AppError("Nome de parametro vazio", 0).
            IF NOT oQuery:Has(cName) THEN oQuery:Add(cName, cValue).
            ELSE DO:
                aValues = ?.
                ASSIGN aValues = oQuery:GetJsonArray(cName) NO-ERROR.
                IF NOT VALID-OBJECT(aValues) THEN DO:
                    ASSIGN cOld = oQuery:GetCharacter(cName) aValues = NEW JsonArray().
                    aValues:Add(cOld).
                    oQuery:Remove(cName).
                    oQuery:Add(cName, aValues).
                END.
                aValues:Add(cValue).
            END.
        END.
        RETURN oQuery.
        CATCH oError AS Error:
            IF VALID-OBJECT(oQuery) THEN DELETE OBJECT oQuery.
            RETURN ?.
        END CATCH.
    END METHOD.

    /* ABL 12.2 built-ins only. Decode bytes once, then validate UTF-8 before
       converting to the session codepage. Never reinterpret UTF-8 as CPINTERNAL. */
    METHOD PRIVATE CHARACTER decodeQueryComponent(INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE lcEncoded AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE mEncoded AS MEMPTR NO-UNDO.
        DEFINE VARIABLE mDecoded AS MEMPTR NO-UNDO.
        DEFINE VARIABLE iLength AS INTEGER NO-UNDO.
        DEFINE VARIABLE iRead AS INTEGER NO-UNDO.
        DEFINE VARIABLE iWritten AS INTEGER NO-UNDO.
        DEFINE VARIABLE iByte AS INTEGER NO-UNDO.
        DEFINE VARIABLE iHigh AS INTEGER NO-UNDO.
        DEFINE VARIABLE iLow AS INTEGER NO-UNDO.
        DEFINE VARIABLE iRemaining AS INTEGER NO-UNDO.
        DEFINE VARIABLE iMin AS INTEGER NO-UNDO.
        DEFINE VARIABLE iMax AS INTEGER NO-UNDO.
        IF pcValue = "" OR pcValue = ? THEN RETURN "".
        FIX-CODEPAGE(lcEncoded) = "UTF-8".
        lcEncoded = pcValue.
        COPY-LOB FROM lcEncoded TO mEncoded NO-CONVERT.
        ASSIGN iLength = GET-SIZE(mEncoded) iRead = 1.
        SET-SIZE(mDecoded) = iLength.
        DO WHILE iRead <= iLength:
            iByte = GET-BYTE(mEncoded, iRead).
            IF iByte = 37 THEN DO: /* percent */
                IF iRead + 2 > iLength THEN
                    UNDO, THROW NEW Progress.Lang.AppError("Escape percentual incompleto", 0).
                ASSIGN iHigh = INDEX("0123456789ABCDEF", CAPS(CHR(GET-BYTE(mEncoded, iRead + 1)))) - 1
                       iLow = INDEX("0123456789ABCDEF", CAPS(CHR(GET-BYTE(mEncoded, iRead + 2)))) - 1.
                IF iHigh < 0 OR iLow < 0 THEN
                    UNDO, THROW NEW Progress.Lang.AppError("Escape percentual invalido", 0).
                ASSIGN iByte = iHigh * 16 + iLow iRead = iRead + 2.
            END.
            ELSE IF iByte = 43 THEN iByte = 32. /* literal plus is a space */
            IF iByte = 0 THEN
                UNDO, THROW NEW Progress.Lang.AppError("Byte nulo na query string", 0).
            iWritten = iWritten + 1.
            PUT-BYTE(mDecoded, iWritten) = iByte.
            iRead = iRead + 1.
        END.
        /* Validate UTF-8, including overlong forms, surrogates and range limits. */
        ASSIGN iRemaining = 0 iMin = 128 iMax = 191.
        DO iRead = 1 TO iWritten:
            iByte = GET-BYTE(mDecoded, iRead).
            IF iRemaining > 0 THEN DO:
                IF iByte < iMin OR iByte > iMax THEN
                    UNDO, THROW NEW Progress.Lang.AppError("UTF-8 invalido", 0).
                ASSIGN iRemaining = iRemaining - 1 iMin = 128 iMax = 191.
            END.
            ELSE IF iByte >= 128 THEN DO:
                IF iByte >= 194 AND iByte <= 223 THEN iRemaining = 1.
                ELSE IF iByte >= 224 AND iByte <= 239 THEN DO:
                    iRemaining = 2.
                    IF iByte = 224 THEN iMin = 160.
                    IF iByte = 237 THEN iMax = 159.
                END.
                ELSE IF iByte >= 240 AND iByte <= 244 THEN DO:
                    iRemaining = 3.
                    IF iByte = 240 THEN iMin = 144.
                    IF iByte = 244 THEN iMax = 143.
                END.
                ELSE UNDO, THROW NEW Progress.Lang.AppError("UTF-8 invalido", 0).
            END.
        END.
        IF iRemaining <> 0 THEN
            UNDO, THROW NEW Progress.Lang.AppError("UTF-8 incompleto", 0).
        RETURN CODEPAGE-CONVERT(GET-STRING(mDecoded, 1, iWritten), SESSION:CPINTERNAL, "UTF-8").
        FINALLY:
            SET-SIZE(mEncoded) = 0.
            SET-SIZE(mDecoded) = 0.
        END FINALLY.
    END METHOD.

    METHOD PRIVATE LONGCHAR failure(INPUT piStatus AS INTEGER, INPUT pcCode AS CHARACTER, INPUT pcMessage AS CHARACTER):
        DEFINE VARIABLE oReply AS JsonObject NO-UNDO.
        DEFINE VARIABLE oError AS JsonObject NO-UNDO.
        DEFINE VARIABLE lcReply AS LONGCHAR NO-UNDO.
        FIX-CODEPAGE(lcReply) = "UTF-8".
        ASSIGN StatusCode = piStatus oReply = NEW JsonObject() oError = NEW JsonObject().
        oError:Add("code", pcCode).
        oError:Add("message", pcMessage).
        oReply:Add("error", oError).
        oReply:Write(lcReply, TRUE).
        DELETE OBJECT oReply.
        RETURN lcReply.
    END METHOD.
END CLASS.




