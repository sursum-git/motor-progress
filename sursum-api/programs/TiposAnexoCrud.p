BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
DEFINE VARIABLE joClean AS JsonObject NO-UNDO.
DEFINE VARIABLE hTipo AS HANDLE NO-UNDO.
DEFINE VARIABLE hContainer AS HANDLE NO-UNDO.
DEFINE VARIABLE hCompra AS HANDLE NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE cProForma AS CHARACTER NO-UNDO.
DEFINE VARIABLE lConfigured AS LOGICAL NO-UNDO.
{sursum-api/includes/parametros_ima.i}

DO ON ERROR UNDO, THROW:
    /* Credencial em header privado, fora do corpo auditado. */
    cToken = WEB-CONTEXT:GET-CGI-VALUE("ENV", "HTTP_X_TIPOS_ANEXO_TOKEN") NO-ERROR.
    IF cToken = ? THEN cToken = "".
    IF LENGTH(cToken) < 32 OR LENGTH(cToken) > 128 THEN DO:
        RUN ErrorResponse("TIPO_ANEXO_AUTH_REQUIRED", "Credencial da integracao invalida.", 401). RETURN.
    END.
    cConfig = SEARCH("sursum-conf/tipos-anexo-api.json").
    IF cConfig = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente", 0).
    FIX-CODEPAGE(lcConfig) = "UTF-8".
    COPY-LOB FROM FILE cConfig TO lcConfig.
    oParser = NEW ObjectModelParser().
    joConfig = CAST(oParser:Parse(lcConfig), JsonObject).
    IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cToken))) <> CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
        RUN ErrorResponse("TIPO_ANEXO_AUTH_REQUIRED", "Credencial da integracao invalida.", 401). RETURN.
    END.
    IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco espec nao conectado", 0).
    cService = SEARCH("sursum-api/programs/TiposAnexoCrudService.r").
    IF cService = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico compilado ausente", 0).
    CREATE BUFFER hTipo FOR TABLE "espec.tipos_anexo" BUFFER-NAME "bTipoAnexoCrud".
    CREATE BUFFER hContainer FOR TABLE "espec.anexos_container" BUFFER-NAME "bAnexoContainerCrud".
    CREATE BUFFER hCompra FOR TABLE "espec.anexos_proc_compra" BUFFER-NAME "bAnexoCompraCrud".
    /* Codigo identificado no banco real. A include le diretamente, sem cache. */
    cProForma = buscarParametroIma("TP_ANEXO_PRO_FORMA", ?).
    lConfigured = cProForma <> ? AND LENGTH(cProForma) > 0.
    joClean = CAST(poRequest:Clone(), JsonObject).
    RUN VALUE(cService) (INPUT hTipo, INPUT hContainer, INPUT hCompra,
        INPUT cProForma, INPUT lConfigured, INPUT joClean, OUTPUT poResponse).
    CATCH e AS Progress.Lang.Error:
        RUN ErrorResponse("TIPO_ANEXO_CONFIGURATION", "API de tipos de anexo indisponivel. Verifique publicacao e banco espec.", 500).
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hTipo) THEN DELETE OBJECT hTipo NO-ERROR.
        IF VALID-HANDLE(hContainer) THEN DELETE OBJECT hContainer NO-ERROR.
        IF VALID-HANDLE(hCompra) THEN DELETE OBJECT hCompra NO-ERROR.
        IF VALID-OBJECT(joConfig) THEN DELETE OBJECT joConfig.
        IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
        IF VALID-OBJECT(joClean) THEN DELETE OBJECT joClean.
    END FINALLY.
END.
PROCEDURE ErrorResponse:
    DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
    DEFINE VARIABLE joError AS JsonObject NO-UNDO.
    poResponse = NEW JsonObject(). joError = NEW JsonObject().
    poResponse:Add("success", FALSE). joError:Add("code", pcCode).
    joError:Add("message", pcMessage). joError:Add("status", piStatus).
    poResponse:Add("error", joError).
END PROCEDURE.
