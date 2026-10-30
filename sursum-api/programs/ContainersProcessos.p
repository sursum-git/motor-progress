/* Public command composition. Names/connections/policies never come from HTTP. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE loginValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE ownedCount AS INTEGER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE cIma AS CHARACTER NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO.
DEFINE VARIABLE ownIma AS LOGICAL NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE hOwned AS HANDLE EXTENT 80 NO-UNDO.
DEFINE VARIABLE hHeader AS HANDLE EXTENT 20 NO-UNDO.
DEFINE VARIABLE hCollector AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE hSources AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE hTargets AS HANDLE EXTENT 5 NO-UNDO.
DEFINE VARIABLE hVersion AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE hFiscal AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE hClose AS HANDLE EXTENT 14 NO-UNDO.
DEFINE VARIABLE hHeaderRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE hHeaderRules AS HANDLE NO-UNDO.
DEFINE VARIABLE hVersionRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE hPrivateContext AS HANDLE NO-UNDO.
DEFINE VARIABLE headerPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE closePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE helperPath AS CHARACTER NO-UNDO.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerMaintenancePolicy.i}
{sursum-api/includes/ContainerProcessBoundary.i}
{sursum-api/includes/ContainerApiIdentity.i}
FUNCTION FixedBuffer RETURNS HANDLE (tableValue AS CHARACTER):
 ownedCount=ownedCount + 1.
 IF ownedCount>EXTENT(hOwned) THEN UNDO, THROW NEW Progress.Lang.AppError("Limite interno de buffers.",1).
 CREATE BUFFER hOwned[ownedCount] FOR TABLE tableValue BUFFER-NAME ("bProcessApi" + STRING(ownedCount,"99")).
 RETURN hOwned[ownedCount].
END FUNCTION.
FUNCTION Compiled RETURNS CHARACTER (nameValue AS CHARACTER):
 DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
 pathValue=SEARCH("sursum-api/programs/" + nameValue + ".r").
 IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("Helper compilado ausente.",1).
 RETURN pathValue.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 loginValue=ContainerApiLogin().
 ASSIGN apiCode="CONTAINER_PROCESS_INVALID_REQUEST" apiMessage="Comando de container invalido." apiStatus=422.
 cid=ContainerProcessRequest(poRequest). op=poRequest:GetCharacter("operation").
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Processo indisponivel. Verifique publicacao e conexoes." apiStatus=503.
 IF NOT CONNECTED("espec") OR NOT CONNECTED("ems5") THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 servicePath=Compiled("ContainersProcessosService").
 tables="pp-container,itens_container,itens_proc_compra,procs_compra,empresas,empresas_despesa,despesas,despesas_container,cta_corren_custo_distr,descontos_importacao,motivos_desconto,cta_corren_desconto,hist_cotacoes_bc,item_container_custos,versoes_item_custo_container,nfs_container,ped-venda-ext".
 DO n=1 TO 17: hCollector[n]=FixedBuffer("espec." + ENTRY(n,tables)). END.
 foundValue=hCollector[1]:FIND-FIRST("WHERE " + hCollector[1]:NAME + ".nr-container=" + TRIM(STRING(cid,"->>>>>>>>>9")),NO-LOCK) NO-ERROR.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1). END.
 IF NOT foundValue THEN DO: RUN Fail("CONTAINER_NOT_FOUND","Container nao encontrado.",404). RETURN. END.
 cEstab=hCollector[1]:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
 IF cEstab=? OR cEstab="" THEN DO: RUN Fail("CONTAINER_CONFIGURATION","Estabelecimento ausente.",422). RETURN. END.
 IF SUBSTRING(cEstab,1,1)<>"1" AND SUBSTRING(cEstab,1,1)<>"5" THEN DO: RUN Fail("CONTAINER_CONFIGURATION","Empresa sem banco ERP autorizado.",422). RETURN. END.
 IF (op="calcular_impostos" OR op="selecionar_despesas" OR op="options") AND NOT cEstab BEGINS "5" THEN DO: RUN Fail("CONTAINER_PROCESS_MED_REQUIRED","Comando fiscal exige container MED.",422). RETURN. END.
 hCollector[1]:BUFFER-RELEASE().
 tables="empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container,pp-it-container,pp_container_permissao,pp_container_saldo_repres,nfs_container,cta_corren_desconto,anexos_container,versoes_item_custo_container,pagtos_container,cta_corren_fornec_imp,item_container_custos".
 DO n=1 TO 20: hHeader[n]=FixedBuffer("espec." + ENTRY(n,tables)). END.
 hSources[1]=hHeader[18]. hSources[2]=FixedBuffer("ems5.tit_ap"). hSources[3]=FixedBuffer("ems5.val_tit_ap"). hSources[4]=FixedBuffer("espec.situacoes_container").
 tables="tipos_versao_custo,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos".
 DO n=1 TO 5: hTargets[n]=FixedBuffer("espec." + ENTRY(n,tables)). END.
 ASSIGN hVersion[1]=hCollector[1] hVersion[2]=hTargets[1] hVersion[3]=hCollector[15] hVersion[4]=hCollector[14].
 DO n=1 TO 4: hVersion[n + 4]=hTargets[n + 1]. END.
 hFiscal[1]=hCollector[1]. DO n=1 TO 10: hFiscal[n + 1]=hHeader[n]. END.
 IF op="gerar" OR op="fechar" THEN DO:
  IF NOT CONNECTED("ems2med") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco MED indisponivel.",1).
  IF CONNECTED("ems2ima") THEN cIma="ems2ima".
  ELSE DO:
   IF CONNECTED("ciw_container_ima") THEN UNDO, THROW NEW Progress.Lang.AppError("Alias temporario inesperado.",1).
   CONNECT -db ems2ima -H 127.0.0.1 -S 10030 -N TCP -ld ciw_container_ima -RO NO-ERROR.
   IF NOT CONNECTED("ciw_container_ima") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco IMA indisponivel.",1).
   ASSIGN ownIma=TRUE cIma="ciw_container_ima".
  END.
 END.
 IF op="gerar" THEN DO:
  hCollector[18]=FixedBuffer("ems2med.item-doc-est"). hCollector[19]=FixedBuffer("ems2med.docum-est").
  hCollector[20]=FixedBuffer(cIma + ".item-doc-est"). hCollector[21]=FixedBuffer(cIma + ".docum-est").
 END.
 ASSIGN apiCode="CONTAINER_POLICY_INVALID" apiMessage="Parametros internos de processo invalidos." apiStatus=422.
 headerPolicy=ContainerMaintenancePolicy(loginValue).
 /* Explicit internal opt-in for the approved distribution/version composition. */
 IF op="gerar" THEN headerPolicy:Add("enable_distribution",TRUE).
 IF op="fechar" THEN DO:
  IF LENGTH(loginValue)>30 THEN DO: RUN Fail("CONTAINER_IDENTITY_INVALID","Login excede o campo fisico de autoria do custo (30 caracteres).",422). RETURN. END.
  closePolicy=NEW JsonObject(). closePolicy:Add("actor",loginValue). closePolicy:Add("tipo_versao_valida_nf",ContainerCloseTypes()).
  ASSIGN hClose[1]=hCollector[1] hClose[2]=hCollector[2] hClose[3]=hCollector[3] hClose[4]=hCollector[15] hClose[5]=hCollector[14] hClose[6]=FixedBuffer("espec.item_custos") hClose[7]=hCollector[16].
  hClose[8]=FixedBuffer("espec.locais_estoq_portal"). hClose[9]=FixedBuffer("espec.ob-etiqueta").
  hClose[10]=FixedBuffer(cIma + ".saldo-estoq"). hClose[11]=FixedBuffer("ems2med.saldo-estoq"). hClose[12]=FixedBuffer("ems2med.movto-estoq").
  hClose[13]=FixedBuffer(cIma + ".nota-fiscal"). hClose[14]=FixedBuffer("ems2med.nota-fiscal").
 END.
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Processo de container indisponivel." apiStatus=503.
 helperPath=Compiled("ContainersCabecalhoRuntime"). RUN VALUE(helperPath) PERSISTENT SET hHeaderRuntime(INPUT ?).
 IF op="gerar" THEN DO:
  helperPath=Compiled("ContainersCabecalhoRules").
  RUN VALUE(helperPath) PERSISTENT SET hHeaderRules(hHeader[1],hHeader[2],hHeader[3],hHeader[4],hHeader[5],hHeader[6],hHeader[7],hHeader[8],hHeader[9],hHeader[10],hHeader[11],hHeader[12],hHeader[13],hHeader[14],hHeader[15],hHeader[16],hHeader[17],hHeader[18],hHeader[19],hHeader[20],hHeaderRuntime,headerPolicy).
  helperPath=Compiled("ContainersVersionContext"). RUN VALUE(helperPath) PERSISTENT SET hPrivateContext.
 END.
 IF op="gerar" OR op="fechar" THEN DO:
  helperPath=Compiled("ContainersVersionRuntime"). RUN VALUE(helperPath) PERSISTENT SET hVersionRuntime(hHeaderRules,hHeaderRuntime,hCollector,hSources,hTargets,hPrivateContext,headerPolicy,?).
 END.
 RUN VALUE(servicePath)(hVersion,hFiscal,hClose,hVersionRuntime,hHeaderRuntime,headerPolicy,closePolicy,poRequest,OUTPUT poResponse).
 CATCH err AS Progress.Lang.Error: RUN Fail(apiCode,apiMessage,apiStatus). END CATCH.
 FINALLY:
  IF VALID-HANDLE(hVersionRuntime) THEN DELETE PROCEDURE hVersionRuntime NO-ERROR.
  IF VALID-HANDLE(hPrivateContext) THEN DELETE PROCEDURE hPrivateContext NO-ERROR.
  IF VALID-HANDLE(hHeaderRules) THEN DELETE PROCEDURE hHeaderRules NO-ERROR.
  IF VALID-HANDLE(hHeaderRuntime) THEN DELETE PROCEDURE hHeaderRuntime NO-ERROR.
  DO n=1 TO ownedCount: IF VALID-HANDLE(hOwned[n]) THEN DELETE OBJECT hOwned[n] NO-ERROR. END.
  IF ownIma AND CONNECTED("ciw_container_ima") THEN DISCONNECT ciw_container_ima NO-ERROR.
  IF VALID-OBJECT(headerPolicy) THEN DELETE OBJECT headerPolicy NO-ERROR.
  IF VALID-OBJECT(closePolicy) THEN DELETE OBJECT closePolicy NO-ERROR.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorValue=NEW JsonObject(). errorValue:Add("code",codeValue). errorValue:Add("message",messageValue). errorValue:Add("status",statusValue).
 poResponse:Add("success",FALSE). poResponse:Add("error",errorValue).
END PROCEDURE.
