/* Entrada autenticada da consulta de containers. Somente leitura.
   Executar por /SursumPrograms/containers-consulta em sursum-api/med.
   O handler associa usuario, PID, agente, instancia e duracao da execucao.
   Logs manuais podem usar ApiExecutionRepository no contexto existente;
   consultar docs/PROGRAM_LOG.md do motor antes de instrumentar uma regra.
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
DEFINE VARIABLE hContainers AS HANDLE NO-UNDO.
DEFINE VARIABLE hSituacoes AS HANDLE NO-UNDO.
DEFINE VARIABLE hEmitente AS HANDLE NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DO ON ERROR UNDO, THROW:
 cToken = WEB-CONTEXT:GET-CGI-VALUE("ENV", "HTTP_X_CONTAINERS_TOKEN") NO-ERROR.
 IF cToken = ? THEN cToken = "".
 IF LENGTH(cToken) < 32 OR LENGTH(cToken) > 128 THEN DO:
  RUN Fail("CONTAINER_AUTH_REQUIRED", "Credencial da integracao invalida.", 401).
  RETURN.
 END.
 cConfig = SEARCH("sursum-conf/containers-api.json").
 IF cConfig = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente", 0).
 FIX-CODEPAGE(lcConfig) = "UTF-8".
 COPY-LOB FROM FILE cConfig TO lcConfig.
 oParser = NEW ObjectModelParser().
 joConfig = CAST(oParser:Parse(lcConfig), JsonObject).
 IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cToken))) <>
    CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
  RUN Fail("CONTAINER_AUTH_REQUIRED", "Credencial da integracao invalida.", 401).
  RETURN.
 END.
 IF NOT CONNECTED("espec") OR NOT CONNECTED("ems2cad") THEN
  UNDO, THROW NEW Progress.Lang.AppError("Bancos da consulta nao conectados", 0).
 cService = SEARCH("sursum-api/programs/ContainersConsultaService.r").
 IF cService = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico compilado ausente", 0).
 /* Tabelas e bancos fixos: o navegador nunca escolhe buffer ou consulta ABL. */
 CREATE BUFFER hContainers FOR TABLE "espec.pp-container" BUFFER-NAME "bContainerConsulta".
 CREATE BUFFER hSituacoes FOR TABLE "espec.situacoes_container" BUFFER-NAME "bSituacaoConsulta".
 CREATE BUFFER hEmitente FOR TABLE "ems2cad.emitente" BUFFER-NAME "bEmitenteConsulta".
 RUN VALUE(cService) (INPUT hContainers, INPUT hSituacoes, INPUT hEmitente,
                     INPUT poRequest, OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  RUN Fail("CONTAINER_CONFIGURATION", "Consulta de containers indisponivel. Verifique publicacao e conexoes.", 500).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hContainers) THEN DELETE OBJECT hContainers NO-ERROR.
  IF VALID-HANDLE(hSituacoes) THEN DELETE OBJECT hSituacoes NO-ERROR.
  IF VALID-HANDLE(hEmitente) THEN DELETE OBJECT hEmitente NO-ERROR.
  IF VALID-OBJECT(joConfig) THEN DELETE OBJECT joConfig.
  IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser.
 END FINALLY.
END.
PROCEDURE Fail:
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
