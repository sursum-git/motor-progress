/* Authenticated read-only cost entry. Fixed collector25 ABI; no business
   writes, sequence calls, process callbacks or client-selected SQL/database. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConfig AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcConfig AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE joConfig AS JsonObject NO-UNDO.
DEFINE VARIABLE joPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE joFinancePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE joFinancial AS JsonObject NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTotals AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDatabase AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTables AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cCode AS CHARACTER NO-UNDO INITIAL "COST_CONFIGURATION".
DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO INITIAL "Consulta de custo indisponivel. Verifique publicacao e conexoes.".
DEFINE VARIABLE iStatus AS INTEGER NO-UNDO INITIAL 503.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE offsetErp AS INTEGER NO-UNDO.
DEFINE VARIABLE offsetSales AS INTEGER NO-UNDO.
DEFINE VARIABLE lFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE lOwnIma AS LOGICAL NO-UNDO.
/*1..25 collector,26..28 private payment helper. Every name below is fixed.*/
DEFINE VARIABLE h AS HANDLE EXTENT 28 NO-UNDO.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerFinancePolicy.i}
{sursum-api/includes/ContainerCustoBoundary.i}
DO ON ERROR UNDO, THROW:
 cToken=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_CONTAINERS_TOKEN") NO-ERROR.
 IF cToken=? THEN cToken="".
 IF LENGTH(cToken)<32 OR LENGTH(cToken)>128 THEN DO:
  RUN Fail("CONTAINER_AUTH_REQUIRED","Credencial da integracao invalida.",401). RETURN.
 END.
 cConfig=SEARCH("sursum-conf/containers-api.json").
 IF cConfig=? THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao ausente.",0).
 FIX-CODEPAGE(lcConfig)="UTF-8".
 COPY-LOB FROM FILE cConfig TO lcConfig.
 oParser=NEW ObjectModelParser().
 joConfig=CAST(oParser:Parse(lcConfig),JsonObject).
 IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",cToken)))<>CAPS(joConfig:GetCharacter("tokenSha256")) THEN DO:
  RUN Fail("CONTAINER_AUTH_REQUIRED","Credencial da integracao invalida.",401). RETURN.
 END.
 ASSIGN cCode="INVALID_REQUEST" cMessage="Requisicao de custo invalida." iStatus=422.
 iContainer=ContainerCustoRequest(poRequest).
 cResource=poRequest:GetCharacter("resource").
 ASSIGN cCode="COST_CONFIGURATION" cMessage="Consulta de custo indisponivel. Verifique publicacao e conexoes." iStatus=503.
 IF NOT CONNECTED("espec") OR NOT CONNECTED("ems5") THEN UNDO, THROW NEW Progress.Lang.AppError("Bancos fixos indisponiveis.",0).
 ASSIGN cService=SEARCH("sursum-api/programs/ContainersCustoReadService.r") cTotals=SEARCH("sursum-api/programs/ContainersPagamentoTotalsService.r").
 IF cService=? OR cTotals=? THEN UNDO, THROW NEW Progress.Lang.AppError("Servicos compilados ausentes.",0).
 cTables="pp-container,itens_container,itens_proc_compra,procs_compra,empresas,empresas_despesa,despesas,despesas_container,cta_corren_custo_distr,descontos_importacao,motivos_desconto,cta_corren_desconto,hist_cotacoes_bc,item_container_custos,versoes_item_custo_container,nfs_container,ped-venda-ext".
 DO n=1 TO 17:
  CREATE BUFFER h[n] FOR TABLE ("espec." + ENTRY(n,cTables)) BUFFER-NAME ("bCost" + STRING(n,"99")).
 END.
 lFound=h[1]:FIND-FIRST("WHERE " + h[1]:NAME + ".nr-container=" + TRIM(STRING(iContainer)),NO-LOCK) NO-ERROR.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao consultar container.",0).
 END.
 IF NOT lFound THEN DO: RUN Fail("NOT_FOUND","Container nao encontrado.",404). RETURN. END.
 cEstab=h[1]:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
 IF cEstab=? OR LENGTH(cEstab)=0 THEN DO: RUN Fail("COST_CONFIGURATION","Estabelecimento nao configurado.",422). RETURN. END.
 IF SUBSTRING(cEstab,1,1)<>"1" AND SUBSTRING(cEstab,1,1)<>"5" THEN DO:
  RUN Fail("COST_CONFIGURATION","Empresa sem banco ERP autorizado.",422). RETURN.
 END.
 /* Rastro/comparativos/cotacoes-fiscais deliberately do not require ERP reads.
    Fiscal quotations use the same authenticated collector25 and financial
    helper even for zero items; the boundary allows only read in real. */
 IF cResource="itens" OR cResource="resumo" THEN DO:
  IF SUBSTRING(cEstab,1,1)="5" THEN DO:
   IF NOT CONNECTED("ems2med") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco MED indisponivel.",0).
   ASSIGN cDatabase="ems2med" offsetErp=18 offsetSales=22.
  END.
  ELSE DO:
   ASSIGN offsetErp=20 offsetSales=24.
   IF CONNECTED("ems2ima") THEN cDatabase="ems2ima".
   ELSE DO:
    IF CONNECTED("ciw_container_ima") THEN UNDO, THROW NEW Progress.Lang.AppError("Alias temporario inesperado.",0).
    CONNECT -db ems2ima -H 127.0.0.1 -S 10030 -N TCP -ld ciw_container_ima -RO NO-ERROR.
    IF NOT CONNECTED("ciw_container_ima") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco IMA indisponivel.",0).
    ASSIGN lOwnIma=TRUE cDatabase="ciw_container_ima".
   END.
  END.
  CREATE BUFFER h[offsetErp] FOR TABLE (cDatabase + ".item-doc-est") BUFFER-NAME "bCostItemDoc".
  CREATE BUFFER h[offsetErp + 1] FOR TABLE (cDatabase + ".docum-est") BUFFER-NAME "bCostDoc".
  IF cResource="resumo" THEN DO:
   CREATE BUFFER h[offsetSales] FOR TABLE (cDatabase + ".ped-venda") BUFFER-NAME "bCostPedVenda".
   CREATE BUFFER h[offsetSales + 1] FOR TABLE (cDatabase + ".ped-item") BUFFER-NAME "bCostPedItem".
  END.
 END.
 CREATE BUFFER h[26] FOR TABLE "espec.pagtos_container" BUFFER-NAME "bCostPagtos".
 CREATE BUFFER h[27] FOR TABLE "ems5.tit_ap" BUFFER-NAME "bCostTitAp".
 CREATE BUFFER h[28] FOR TABLE "ems5.val_tit_ap" BUFFER-NAME "bCostValTitAp".
 ASSIGN cCode="COST_POLICY_INVALID" cMessage="Parametros internos de custo invalidos." iStatus=422.
 /* Every call uses parametros_ima.i directly NO-LOCK, never a session cache. */
 ASSIGN joPolicy=ContainerCustoPolicy() joFinancePolicy=ContainerFinancePolicy().
 ASSIGN cCode="COST_CONFIGURATION" cMessage="Consulta de custo indisponivel. Verifique publicacao e conexoes." iStatus=503.
 RUN VALUE(cTotals) (INPUT h[1],INPUT h[26],INPUT h[27],INPUT h[28],INPUT joFinancePolicy,INPUT iContainer,OUTPUT joFinancial).
 IF NOT VALID-OBJECT(joFinancial) THEN UNDO, THROW NEW Progress.Lang.AppError("Retorno financeiro ausente.",0).
 IF NOT joFinancial:GetLogical("success") THEN DO:
  poResponse=joFinancial. joFinancial=?. RETURN.
 END.
 RUN VALUE(cService) (INPUT h[1],INPUT h[2],INPUT h[3],INPUT h[4],INPUT h[5],INPUT h[6],INPUT h[7],INPUT h[8],INPUT h[9],INPUT h[10],INPUT h[11],INPUT h[12],INPUT h[13],INPUT h[14],INPUT h[15],INPUT h[16],INPUT h[17],INPUT h[18],INPUT h[19],INPUT h[20],INPUT h[21],INPUT h[22],INPUT h[23],INPUT h[24],INPUT h[25],INPUT joFinancial:GetJsonObject("data"),INPUT joPolicy,INPUT poRequest,OUTPUT poResponse).
 CATCH err AS Progress.Lang.Error:
  RUN Fail(cCode,cMessage,iStatus).
 END CATCH.
 FINALLY:
  DO n=1 TO EXTENT(h): IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
  IF lOwnIma AND CONNECTED("ciw_container_ima") THEN DISCONNECT ciw_container_ima NO-ERROR.
  IF VALID-OBJECT(joFinancial) THEN DELETE OBJECT joFinancial NO-ERROR.
  IF VALID-OBJECT(joFinancePolicy) THEN DELETE OBJECT joFinancePolicy NO-ERROR.
  IF VALID-OBJECT(joPolicy) THEN DELETE OBJECT joPolicy NO-ERROR.
  IF VALID-OBJECT(joConfig) THEN DELETE OBJECT joConfig NO-ERROR.
  IF VALID-OBJECT(oParser) THEN DELETE OBJECT oParser NO-ERROR.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
 DEFINE VARIABLE joError AS JsonObject NO-UNDO.
 ASSIGN poResponse=NEW JsonObject() joError=NEW JsonObject().
 joError:Add("code",pcCode). joError:Add("message",pcMessage). joError:Add("status",piStatus).
 poResponse:Add("success",FALSE). poResponse:Add("error",joError).
END PROCEDURE.
