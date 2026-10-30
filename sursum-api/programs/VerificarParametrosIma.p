/* Diagnostico operacional protegido. Nao retorna nomes/valores de parametros.
   Valida leitura real da include sem alterar banco ou usar cache. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
DEFINE VARIABLE joData AS JsonObject NO-UNDO.
DEFINE VARIABLE cExpected AS CHARACTER NO-UNDO INITIAL "__ausente__".
DEFINE VARIABLE cActual AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMissingExpected AS CHARACTER NO-UNDO INITIAL "padrao".
DEFINE VARIABLE cBaseExpected AS CHARACTER NO-UNDO INITIAL "".
DEFINE VARIABLE cFreteExpected AS CHARACTER NO-UNDO INITIAL "1500".
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE BUFFER bDiagnostico FOR espec.im-param.
{sursum-api/includes/parametros_ima.i}

DO ON ERROR UNDO, THROW:
    cToken = WEB-CONTEXT:GET-CGI-VALUE("ENV", "HTTP_X_PARAMETROS_IMA_TOKEN") NO-ERROR.
    IF cToken = ? THEN cToken = "".
    IF LENGTH(cToken) < 32 OR LENGTH(cToken) > 128 THEN DO:
        RUN Falhar("PARAMETRO_AUTH_REQUIRED", "Credencial da integracao invalida.", 401).
        RETURN.
    END.
    cConfig = SEARCH("sursum-conf/parametros-ima-api.json").
    IF cConfig = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente", 0).
    FIX-CODEPAGE(lcConfig) = "UTF-8".
    COPY-LOB FROM FILE cConfig TO lcConfig.
    oParser = NEW ObjectModelParser().
    joConfig = CAST(oParser:Parse(lcConfig), JsonObject).
    IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cToken))) <> CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
        RUN Falhar("PARAMETRO_AUTH_REQUIRED", "Credencial da integracao invalida.", 401).
        RETURN.
    END.
    FOR FIRST bDiagnostico NO-LOCK WHERE bDiagnostico.cod-param = "QT_DIAS_PREV_EMBARQUE":
        ASSIGN cExpected = bDiagnostico.val-param lFound = TRUE.
    END.
    cActual = buscarParametroIma("QT_DIAS_PREV_EMBARQUE", "__ausente__").
    IF cActual <> cExpected OR (cActual = ? AND cExpected <> ?) OR (cActual <> ? AND cExpected = ?) THEN
        UNDO, THROW NEW Progress.Lang.AppError("Leitura divergente", 0).
    FOR FIRST bDiagnostico NO-LOCK WHERE bDiagnostico.cod-param = "__diagnostico_parametros_ima_ausente__":
        cMissingExpected = bDiagnostico.val-param.
    END.
    IF buscarParametroIma("__diagnostico_parametros_ima_ausente__", "padrao") <> cMissingExpected THEN
        UNDO, THROW NEW Progress.Lang.AppError("Padrao divergente", 0).
    FOR FIRST bDiagnostico NO-LOCK WHERE bDiagnostico.cod-param = "base":
        cBaseExpected = bDiagnostico.val-param.
    END.
    IF getBase() <> cBaseExpected THEN
        UNDO, THROW NEW Progress.Lang.AppError("Getter base divergente", 0).
    FOR FIRST bDiagnostico NO-LOCK WHERE bDiagnostico.cod-param = "vl_min_cif_sudeste":
        cFreteExpected = bDiagnostico.val-param.
    END.
    IF getVlMinFreteCIFSudeste("real") <> cFreteExpected THEN
        UNDO, THROW NEW Progress.Lang.AppError("Getter CIF divergente", 0).
    joData = NEW JsonObject().
    joData:Add("databaseConnected", CONNECTED("espec")).
    joData:Add("parameterExists", lFound).
    joData:Add("valueMatchesDatabase", TRUE).
    joData:Add("defaultValueVerified", TRUE).
    joData:Add("cacheEnabled", FALSE).
    joData:Add("helpersVerified", TRUE).
    poResponse = NEW JsonObject().
    poResponse:Add("success", TRUE).
    poResponse:Add("data", joData).
    CATCH e AS Progress.Lang.Error:
        RUN Falhar("PARAMETRO_DIAGNOSTICO_FAILED", "Nao foi possivel verificar os parametros.", 500).
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(joConfig) THEN DELETE OBJECT joConfig.
        IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
    END FINALLY.
END.
PROCEDURE Falhar:
    DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
    DEFINE VARIABLE joError AS JsonObject NO-UNDO.
    joError = NEW JsonObject().
    joError:Add("code", pcCode).
    joError:Add("message", pcMessage).
    joError:Add("status", piStatus).
    poResponse = NEW JsonObject().
    poResponse:Add("success", FALSE).
    poResponse:Add("error", joError).
END PROCEDURE.
