/* Entrada autenticada do painel de containers. Somente leitura.
   Executar por /SursumPrograms/containers-painel em sursum-api/med.
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
DEFINE VARIABLE hContainer AS HANDLE NO-UNDO.
DEFINE VARIABLE hVersoes AS HANDLE NO-UNDO.
DEFINE VARIABLE hAnexos AS HANDLE NO-UNDO.
DEFINE VARIABLE hTiposAnexo AS HANDLE NO-UNDO.
DEFINE VARIABLE hDespesasContainer AS HANDLE NO-UNDO.
DEFINE VARIABLE hEmpresasDespesa AS HANDLE NO-UNDO.
DEFINE VARIABLE hDespesas AS HANDLE NO-UNDO.
DEFINE VARIABLE hEmpresas AS HANDLE NO-UNDO.
DEFINE VARIABLE hItensContainer AS HANDLE NO-UNDO.
DEFINE VARIABLE hItensProcCompra AS HANDLE NO-UNDO.
DEFINE VARIABLE hProcsCompra AS HANDLE NO-UNDO.
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
 IF NOT CONNECTED("espec") THEN
  UNDO, THROW NEW Progress.Lang.AppError("Bancos da consulta nao conectados", 0).
 cService = SEARCH("sursum-api/programs/ContainersPainelReadService.r").
 IF cService = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico compilado ausente", 0).
 /* Tabelas e bancos fixos: o navegador nunca escolhe buffer ou consulta ABL. */
 CREATE BUFFER hContainer FOR TABLE "espec.pp-container" BUFFER-NAME "bPanelContainer".
 CREATE BUFFER hVersoes FOR TABLE "espec.versoes_item_custo_container" BUFFER-NAME "bPanelVersoes".
 CREATE BUFFER hAnexos FOR TABLE "espec.anexos_container" BUFFER-NAME "bPanelAnexos".
 CREATE BUFFER hTiposAnexo FOR TABLE "espec.tipos_anexo" BUFFER-NAME "bPanelTiposAnexo".
 CREATE BUFFER hDespesasContainer FOR TABLE "espec.despesas_container" BUFFER-NAME "bPanelDespesasContainer".
 CREATE BUFFER hEmpresasDespesa FOR TABLE "espec.empresas_despesa" BUFFER-NAME "bPanelEmpresasDespesa".
 CREATE BUFFER hDespesas FOR TABLE "espec.despesas" BUFFER-NAME "bPanelDespesas".
 CREATE BUFFER hEmpresas FOR TABLE "espec.empresas" BUFFER-NAME "bPanelEmpresas".
 CREATE BUFFER hItensContainer FOR TABLE "espec.itens_container" BUFFER-NAME "bPanelItensContainer".
 CREATE BUFFER hItensProcCompra FOR TABLE "espec.itens_proc_compra" BUFFER-NAME "bPanelItensProcCompra".
 CREATE BUFFER hProcsCompra FOR TABLE "espec.procs_compra" BUFFER-NAME "bPanelProcsCompra".
 RUN VALUE(cService) (INPUT hContainer, INPUT hVersoes, INPUT hAnexos, INPUT hTiposAnexo, INPUT hDespesasContainer, INPUT hEmpresasDespesa, INPUT hDespesas, INPUT hEmpresas, INPUT hItensContainer, INPUT hItensProcCompra, INPUT hProcsCompra, INPUT poRequest, OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  RUN Fail("CONTAINER_CONFIGURATION", "Painel do container indisponivel. Verifique publicacao e conexoes.", 500).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hContainer) THEN DELETE OBJECT hContainer NO-ERROR.
  IF VALID-HANDLE(hVersoes) THEN DELETE OBJECT hVersoes NO-ERROR.
  IF VALID-HANDLE(hAnexos) THEN DELETE OBJECT hAnexos NO-ERROR.
  IF VALID-HANDLE(hTiposAnexo) THEN DELETE OBJECT hTiposAnexo NO-ERROR.
  IF VALID-HANDLE(hDespesasContainer) THEN DELETE OBJECT hDespesasContainer NO-ERROR.
  IF VALID-HANDLE(hEmpresasDespesa) THEN DELETE OBJECT hEmpresasDespesa NO-ERROR.
  IF VALID-HANDLE(hDespesas) THEN DELETE OBJECT hDespesas NO-ERROR.
  IF VALID-HANDLE(hEmpresas) THEN DELETE OBJECT hEmpresas NO-ERROR.
  IF VALID-HANDLE(hItensContainer) THEN DELETE OBJECT hItensContainer NO-ERROR.
  IF VALID-HANDLE(hItensProcCompra) THEN DELETE OBJECT hItensProcCompra NO-ERROR.
  IF VALID-HANDLE(hProcsCompra) THEN DELETE OBJECT hProcsCompra NO-ERROR.
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
