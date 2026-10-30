/* Entrada autenticada de pagamentos e notas do container. Somente leitura.
   Executar por /SursumPrograms/containers-financeiro em sursum-api/med.
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
DEFINE VARIABLE hEmpresas AS HANDLE NO-UNDO.
DEFINE VARIABLE hItensContainer AS HANDLE NO-UNDO.
DEFINE VARIABLE hItensProcCompra AS HANDLE NO-UNDO.
DEFINE VARIABLE hProcsCompra AS HANDLE NO-UNDO.
DEFINE VARIABLE hPagtos AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE hValTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE hNfs AS HANDLE NO-UNDO.
DEFINE VARIABLE hDocumEst AS HANDLE NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE lOwnIma AS LOGICAL NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE iError AS INTEGER NO-UNDO.
DEFINE VARIABLE joPolicy AS JsonObject NO-UNDO.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerFinancePolicy.i}
FUNCTION FinanceContainerId RETURNS INTEGER ():
 DEFINE VARIABLE textId AS CHARACTER NO-UNDO.
 DEFINE VARIABLE indexId AS INTEGER NO-UNDO.
 DEFINE VARIABLE valueId AS DECIMAL NO-UNDO.
 IF NOT VALID-OBJECT(poRequest) OR NOT poRequest:Has("container_id") OR poRequest:IsNull("container_id") THEN RETURN ?.
 CASE poRequest:GetType("container_id"):
  WHEN JsonDataType:STRING THEN textId=poRequest:GetCharacter("container_id").
  WHEN JsonDataType:NUMBER THEN textId=poRequest:GetJsonText("container_id").
  OTHERWISE RETURN ?.
 END CASE.
 IF LENGTH(textId)<1 OR LENGTH(textId)>10 THEN RETURN ?.
 DO indexId=1 TO LENGTH(textId):
  IF INDEX("0123456789",SUBSTRING(textId,indexId,1))=0 THEN RETURN ?.
 END.
 valueId=DECIMAL(textId).
 IF valueId<1 OR valueId>2147483647 THEN RETURN ?.
 RETURN INTEGER(valueId).
END FUNCTION.
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
 IF NOT CONNECTED("espec") OR NOT CONNECTED("ems5") THEN
  UNDO, THROW NEW Progress.Lang.AppError("Bancos da consulta nao conectados", 0).
 cService = SEARCH("sursum-api/programs/ContainersPainelFinanceReadService.r").
 IF cService = ? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico compilado ausente", 0).
 /* Tabelas e bancos fixos: o navegador nunca escolhe buffer ou consulta ABL. */
 CREATE BUFFER hContainer FOR TABLE "espec.pp-container" BUFFER-NAME "bFinanceContainer".
 CREATE BUFFER hEmpresas FOR TABLE "espec.empresas" BUFFER-NAME "bFinanceEmpresas".
 CREATE BUFFER hItensContainer FOR TABLE "espec.itens_container" BUFFER-NAME "bFinanceItensContainer".
 CREATE BUFFER hItensProcCompra FOR TABLE "espec.itens_proc_compra" BUFFER-NAME "bFinanceItensProcCompra".
 CREATE BUFFER hProcsCompra FOR TABLE "espec.procs_compra" BUFFER-NAME "bFinanceProcsCompra".
 CREATE BUFFER hPagtos FOR TABLE "espec.pagtos_container" BUFFER-NAME "bFinancePagtos".
 CREATE BUFFER hTitAp FOR TABLE "ems5.tit_ap" BUFFER-NAME "bFinanceTitAp".
 CREATE BUFFER hValTitAp FOR TABLE "ems5.val_tit_ap" BUFFER-NAME "bFinanceValTitAp".
 CREATE BUFFER hNfs FOR TABLE "espec.nfs_container" BUFFER-NAME "bFinanceNfs".
 iContainer=FinanceContainerId().
 IF iContainer=? THEN DO: RUN Fail("CONTAINER_VALIDATION","Informe container_id inteiro positivo valido.",422). RETURN. END.
 lFound=hContainer:FIND-FIRST("WHERE " + hContainer:NAME + ".nr-container=" + TRIM(STRING(iContainer)),NO-LOCK) NO-ERROR.
 DO iError=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(iError)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao consultar o container.",0).
 END.
 IF NOT lFound THEN DO:
  RUN Fail("CONTAINER_NOT_FOUND","Container nao encontrado.",404). RETURN.
 END.
 IF NOT poRequest:Has("resource") THEN DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Informe o recurso.",422). RETURN. END.
 IF poRequest:GetType("resource")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Recurso invalido.",422). RETURN. END.
 cResource=poRequest:GetCharacter("resource").
 IF NOT poRequest:Has("operation") THEN DO: RUN Fail("CONTAINER_OPERATION_INVALID","Informe read ou get.",422). RETURN. END.
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_OPERATION_INVALID","Operacao invalida.",422). RETURN. END.
 IF poRequest:GetCharacter("operation")<>"read" AND poRequest:GetCharacter("operation")<>"get" THEN DO:
  RUN Fail("CONTAINER_OPERATION_INVALID","A consulta aceita somente read e get.",422). RETURN.
 END.
 IF cResource="nfs" OR cResource="nfs-disponiveis" THEN DO:
  cEstab=hContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
  IF cResource="nfs-disponiveis" THEN
   IF cEstab=? OR NOT cEstab BEGINS "5" THEN DO: RUN Fail("CONTAINER_NF_MED_REQUIRED","NFs disponiveis exigem container MED.",422). RETURN. END.
  IF cEstab=? OR LENGTH(cEstab)=0 THEN DO: RUN Fail("CONTAINER_COMPANY_CONTEXT","Estabelecimento nao configurado.",422). RETURN. END.
  CASE SUBSTRING(cEstab,1,1):
   WHEN "5" THEN DO:
    IF NOT CONNECTED("ems2med") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco MED indisponivel.",0).
    cDatabase="ems2med".
   END.
   WHEN "1" THEN DO:
    IF CONNECTED("ems2ima") THEN cDatabase="ems2ima".
    ELSE DO:
     IF CONNECTED("ciw_container_ima") THEN UNDO, THROW NEW Progress.Lang.AppError("Alias temporario inesperado.",0).
     CONNECT -db ems2ima -H 127.0.0.1 -S 10030 -N TCP -ld ciw_container_ima -RO NO-ERROR.
     IF NOT CONNECTED("ciw_container_ima") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco IMA indisponivel.",0).
     ASSIGN lOwnIma=TRUE cDatabase="ciw_container_ima".
    END.
   END.
   OTHERWISE DO: RUN Fail("CONTAINER_COMPANY_CONTEXT","Empresa sem banco ERP autorizado.",422). RETURN. END.
  END CASE.
  CREATE BUFFER hDocumEst FOR TABLE (cDatabase + ".docum-est") BUFFER-NAME "bFinanceDocumEst".
  joPolicy=NEW JsonObject().
 END.
 ELSE IF cResource="pagamentos" THEN joPolicy=ContainerFinancePolicy().
 ELSE DO: RUN Fail("CONTAINER_RESOURCE_INVALID","Recurso invalido.",422). RETURN. END.
 RUN VALUE(cService) (INPUT hContainer, INPUT hEmpresas, INPUT hItensContainer, INPUT hItensProcCompra, INPUT hProcsCompra, INPUT hPagtos, INPUT hTitAp, INPUT hValTitAp, INPUT hNfs, INPUT hDocumEst, INPUT joPolicy, INPUT poRequest, OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  RUN Fail("CONTAINER_CONFIGURATION", "Consulta financeira do container indisponivel. Verifique publicacao e conexoes.", 500).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hContainer) THEN DELETE OBJECT hContainer NO-ERROR.
  IF VALID-HANDLE(hEmpresas) THEN DELETE OBJECT hEmpresas NO-ERROR.
  IF VALID-HANDLE(hItensContainer) THEN DELETE OBJECT hItensContainer NO-ERROR.
  IF VALID-HANDLE(hItensProcCompra) THEN DELETE OBJECT hItensProcCompra NO-ERROR.
  IF VALID-HANDLE(hProcsCompra) THEN DELETE OBJECT hProcsCompra NO-ERROR.
  IF VALID-HANDLE(hPagtos) THEN DELETE OBJECT hPagtos NO-ERROR.
  IF VALID-HANDLE(hTitAp) THEN DELETE OBJECT hTitAp NO-ERROR.
  IF VALID-HANDLE(hValTitAp) THEN DELETE OBJECT hValTitAp NO-ERROR.
  IF VALID-HANDLE(hNfs) THEN DELETE OBJECT hNfs NO-ERROR.
  IF VALID-HANDLE(hDocumEst) THEN DELETE OBJECT hDocumEst NO-ERROR.
  IF lOwnIma AND CONNECTED("ciw_container_ima") THEN DISCONNECT ciw_container_ima NO-ERROR.
  IF VALID-OBJECT(joPolicy) THEN DELETE OBJECT joPolicy.
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
