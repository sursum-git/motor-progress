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
DEFINE VARIABLE h AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE cTables AS CHARACTER NO-UNDO INITIAL "despesas,empresas_despesa,empresas,relacs_desp_calculada,despesas_impostos,despesas_proc_compra,despesas_container,item_container_custo_despesas".
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
 /* Token privado via header, nunca em payload ou resposta. Configuracao contem somente hash. */
 cToken = WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_DESPESAS_TOKEN") NO-ERROR.
 IF cToken = ? THEN cToken = "".
 IF LENGTH(cToken) < 32 OR LENGTH(cToken) > 128 THEN DO:
  RUN ErrorResponse("DESPESAS_AUTH_REQUIRED","Credencial da integracao invalida.",401). RETURN.
 END.
 cConfig = SEARCH("sursum-conf/despesas-api.json").
 IF cConfig = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente",0).
 FIX-CODEPAGE(lcConfig) = "UTF-8". COPY-LOB FROM FILE cConfig TO lcConfig.
 oParser = NEW ObjectModelParser(). joConfig = CAST(oParser:Parse(lcConfig),JsonObject).
 IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cToken))) <> CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
  RUN ErrorResponse("DESPESAS_AUTH_REQUIRED","Credencial da integracao invalida.",401). RETURN.
 END.
 IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco espec nao conectado",0).
 cService = SEARCH("sursum-api/programs/DespesasCrudService.r").
 IF cService = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico compilado ausente",0).
 DO i = 1 TO 8:
  CREATE BUFFER h[i] FOR TABLE ("espec." + ENTRY(i,cTables)) BUFFER-NAME ("bDespesasApi" + TRIM(STRING(i))).
 END.
 joClean = CAST(poRequest:Clone(),JsonObject).
 RUN VALUE(cService) (INPUT h[1], INPUT h[2], INPUT h[3], INPUT h[4], INPUT h[5], INPUT h[6], INPUT h[7], INPUT h[8], INPUT joClean, OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  RUN ErrorResponse("DESPESAS_CONFIGURATION","API de despesas indisponivel. Verifique publicacao e banco espec.",500).
 END CATCH.
 FINALLY:
  DO i = 1 TO 8: IF VALID-HANDLE(h[i]) THEN DELETE OBJECT h[i] NO-ERROR. END.
  IF VALID-OBJECT(joConfig) THEN DELETE OBJECT joConfig.
  IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
  IF VALID-OBJECT(joClean) THEN DELETE OBJECT joClean.
 END FINALLY.
END.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER stat AS INTEGER NO-UNDO.
 DEFINE VARIABLE e AS JsonObject NO-UNDO.
 poResponse = NEW JsonObject(). e = NEW JsonObject(). poResponse:Add("success",FALSE).
 e:Add("code",code). e:Add("message",msg). e:Add("status",stat). poResponse:Add("error",e).
END PROCEDURE.
