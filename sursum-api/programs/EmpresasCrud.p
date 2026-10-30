BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hEmpresa AS HANDLE NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE joError AS JsonObject NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
DEFINE VARIABLE joClean AS JsonObject NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.

DO ON ERROR UNDO, THROW:
  /* Headers de credenciais nao entram no corpo auditado pelo roteador JSON. */
  cToken = WEB-CONTEXT:GET-CGI-VALUE("ENV", "HTTP_X_EMPRESAS_TOKEN") NO-ERROR.
  IF cToken = ? THEN cToken = "".
  IF LENGTH(cToken) < 32 OR LENGTH(cToken) > 128 THEN DO:
    RUN AuthenticationFailed. RETURN.
  END.
  cConfig = SEARCH("sursum-conf/empresas-api.json").
  IF cConfig = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente", 0).
  FIX-CODEPAGE(lcConfig) = "UTF-8".
  COPY-LOB FROM FILE cConfig TO lcConfig.
  oParser = NEW ObjectModelParser().
  joConfig = CAST(oParser:Parse(lcConfig), JsonObject).
  IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cToken))) <> CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
    RUN AuthenticationFailed. RETURN.
  END.
  joClean = CAST(poRequest:Clone(), JsonObject).
  IF NOT CONNECTED("espec") THEN
    UNDO, THROW NEW Progress.Lang.AppError("Banco espec nao conectado", 0).
  cService = SEARCH("sursum-api/programs/EmpresasCrudService.r").
  IF cService = ? THEN
    UNDO, THROW NEW Progress.Lang.AppError("Servico compilado nao publicado", 0).
  CREATE BUFFER hEmpresa FOR TABLE "espec.empresas" BUFFER-NAME "bEmpresaCrud".
  RUN VALUE(cService) (INPUT hEmpresa, INPUT joClean, OUTPUT poResponse).
  CATCH e AS Progress.Lang.Error:
    poResponse = NEW JsonObject().
    poResponse:Add("success", FALSE).
    joError = NEW JsonObject().
    joError:Add("code", "EMPRESA_CONFIGURATION").
    joError:Add("message", "API de empresas indisponivel. Verifique a publicacao e o banco espec.").
    joError:Add("status", 500).
    poResponse:Add("error", joError).
  END CATCH.
  FINALLY:
    IF VALID-HANDLE(hEmpresa) THEN DELETE OBJECT hEmpresa NO-ERROR.
    IF VALID-OBJECT(joClean) THEN DELETE OBJECT joClean.
    IF VALID-OBJECT(joConfig) THEN DELETE OBJECT joConfig.
    IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
  END FINALLY.
END.

PROCEDURE AuthenticationFailed:
  poResponse = NEW JsonObject().
  poResponse:Add("success", FALSE).
  joError = NEW JsonObject().
  joError:Add("code", "EMPRESA_AUTH_REQUIRED").
  joError:Add("message", "Credencial da integracao de empresas invalida.").
  joError:Add("status", 401).
  poResponse:Add("error", joError).
END PROCEDURE.
