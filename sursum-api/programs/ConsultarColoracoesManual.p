/* API manual de leitura de espec.coloracoes.
   Compilar em OpenEdge 12.2 conectado ao banco logico espec.
   Executar pelo JsonProgramWebHandler, que registra usuario/PID/duracao.
*/
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.

DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
DEFINE VARIABLE jaColoracoes AS JsonArray NO-UNDO.
DEFINE VARIABLE joColoracao AS JsonObject NO-UNDO.

DO ON ERROR UNDO, THROW:
    /* Credencial privada da fonte motor_progress_coloracoes_manual.
       Nao receber senha ou token de integracao no corpo JSON. */
    cToken = WEB-CONTEXT:GET-CGI-VALUE("ENV", "HTTP_X_COLORACOES_TOKEN") NO-ERROR.
    IF cToken = ? THEN cToken = "".
    IF LENGTH(cToken) < 32 OR LENGTH(cToken) > 128 THEN DO:
        RUN Falhar("COLORACAO_AUTH_REQUIRED", "Credencial da integracao invalida.", 401).
        RETURN.
    END.
    cConfig = SEARCH("sursum-conf/coloracoes-api.json").
    IF cConfig = ? THEN
        UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente", 0).
    FIX-CODEPAGE(lcConfig) = "UTF-8".
    COPY-LOB FROM FILE cConfig TO lcConfig.
    oParser = NEW ObjectModelParser().
    joConfig = CAST(oParser:Parse(lcConfig), JsonObject).
    IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cToken))) <>
       CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
        RUN Falhar("COLORACAO_AUTH_REQUIRED", "Credencial da integracao invalida.", 401).
        RETURN.
    END.

    IF NOT CONNECTED("espec") THEN
        UNDO, THROW NEW Progress.Lang.AppError("Banco espec nao conectado", 0).

    jaColoracoes = NEW JsonArray().

    /* Consulta manual: a regra de negocio fica neste FOR EACH.
       Retornar a lista completa; PHP aplica filtro/ordenacao/paginacao. */
    FOR EACH espec.coloracoes NO-LOCK BY espec.coloracoes.coloracao_id:
        joColoracao = NEW JsonObject().
        IF espec.coloracoes.coloracao_id = ? THEN joColoracao:AddNull("coloracao_id").
        ELSE joColoracao:Add("coloracao_id", espec.coloracoes.coloracao_id).
        IF espec.coloracoes.descricao = ? THEN joColoracao:AddNull("descricao").
        ELSE joColoracao:Add("descricao", espec.coloracoes.descricao).
        IF espec.coloracoes.log_inativo = ? THEN joColoracao:AddNull("log_inativo").
        ELSE joColoracao:Add("log_inativo", espec.coloracoes.log_inativo).
        jaColoracoes:Add(joColoracao).
    END.

    poResponse = NEW JsonObject().
    poResponse:Add("success", TRUE).
    poResponse:Add("data", jaColoracoes).

    CATCH e AS Progress.Lang.Error:
        RUN Falhar("COLORACAO_QUERY_FAILED", "Nao foi possivel consultar coloracoes.", 500).
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
    poResponse = NEW JsonObject().
    joError = NEW JsonObject().
    joError:Add("code", pcCode).
    joError:Add("message", pcMessage).
    joError:Add("status", piStatus).
    poResponse:Add("success", FALSE).
    poResponse:Add("error", joError).
END PROCEDURE.
