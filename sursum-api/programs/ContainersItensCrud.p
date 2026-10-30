/* Fixed authenticated boundary. The browser cannot choose tables, policies,
   sequences, callbacks, databases or the audit actor. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE loginName AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE baseRuntimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE fiscalRulesPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE itemRuntimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE baseRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE fiscalRules AS HANDLE NO-UNDO.
DEFINE VARIABLE itemRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE hMaster AS HANDLE NO-UNDO.
DEFINE VARIABLE hDiscounts AS HANDLE NO-UNDO.
DEFINE VARIABLE hOrderPayments AS HANDLE NO-UNDO.
DEFINE VARIABLE hAllContainers AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE hValTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 20 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL "empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container,pp-it-container,pp_container_permissao,pp_container_saldo_repres,nfs_container,cta_corren_desconto,anexos_container,versoes_item_custo_container,pagtos_container,cta_corren_fornec_imp,item_container_custos".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerMaintenancePolicy.i}
{sursum-api/includes/ContainerFinancePolicy.i}
{sursum-api/includes/ContainerApiIdentity.i}
DO ON ERROR UNDO, THROW:
 loginName=ContainerApiLogin().
 IF NOT VALID-OBJECT(poRequest) THEN DO: RUN Fail("CONTAINER_VALIDATION","Requisicao ausente.",422). RETURN. END.
 IF NOT poRequest:Has("resource") OR NOT poRequest:Has("operation") THEN DO: RUN Fail("CONTAINER_VALIDATION","Informe recurso e operacao.",422). RETURN. END.
 IF poRequest:GetType("resource")<>JsonDataType:STRING OR poRequest:GetType("operation")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_VALIDATION","Recurso ou operacao invalida.",422). RETURN. END.
 resourceName=poRequest:GetCharacter("resource"). op=poRequest:GetCharacter("operation").
 IF NOT (resourceName="container-itens" AND LOOKUP(op,"create,update,delete,get")>0 OR LOOKUP(resourceName,"itens-disponiveis,itens-alocacao-disponiveis")>0 AND op="read" OR resourceName="container-alocacoes" AND op="allocate") THEN DO:
  RUN Fail("CONTAINER_VALIDATION","Recurso ou operacao invalida.",422). RETURN.
 END.
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Manutencao e alocacao de itens indisponiveis. Verifique publicacao e conexoes." apiStatus=503.
 IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco fixo indisponivel.",1).
 CREATE BUFFER hMaster FOR TABLE "espec.pp-container" BUFFER-NAME "bItemsApiMaster".
 DO n=1 TO 20: CREATE BUFFER h[n] FOR TABLE ("espec." + ENTRY(n,tables)) BUFFER-NAME ("bItemsApi" + STRING(n,"99")). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove("resource").
 IF clean:Has('selection_only') THEN DO: RUN Fail('CONTAINER_VALIDATION','Campo nao permitido.',422). RETURN. END.
 IF LOOKUP(resourceName,'itens-disponiveis,itens-alocacao-disponiveis')>0 THEN DO:
  IF resourceName='itens-alocacao-disponiveis' THEN clean:Add('selection_only',TRUE).
  servicePath=SEARCH("sursum-api/programs/ContainersItensOptionsService.r").
  IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de itens disponiveis nao publicada.",1).
  RUN VALUE(servicePath)(hMaster,h[2],h[3],h[4],clean,OUTPUT poResponse).
  RETURN.
 END.
 IF NOT CONNECTED("ems5") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco financeiro fixo indisponivel.",1).
 ASSIGN servicePath=SEARCH("sursum-api/programs/ContainersItensCrudService.r")
  baseRuntimePath=SEARCH("sursum-api/programs/ContainersCabecalhoRuntime.r")
  fiscalRulesPath=SEARCH("sursum-api/programs/ContainersCabecalhoRules.r")
  itemRuntimePath=SEARCH("sursum-api/programs/ContainersItensRuntime.r").
 IF resourceName='container-alocacoes' THEN servicePath=SEARCH('sursum-api/programs/ContainersItensBatchService.r').
 IF servicePath=? OR baseRuntimePath=? OR fiscalRulesPath=? OR itemRuntimePath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Servicos de manutencao compilados ausentes.",1).
 CREATE BUFFER hDiscounts FOR TABLE "espec.descontos_importacao" BUFFER-NAME "bItemsApiDiscounts".
 CREATE BUFFER hOrderPayments FOR TABLE "espec.pagtos_proc_compra" BUFFER-NAME "bItemsApiOrderPayments".
 CREATE BUFFER hAllContainers FOR TABLE "espec.pp-container" BUFFER-NAME "bItemsApiAllContainers".
 CREATE BUFFER hTitAp FOR TABLE "ems5.tit_ap" BUFFER-NAME "bItemsApiTitles".
 CREATE BUFFER hValTitAp FOR TABLE "ems5.val_tit_ap" BUFFER-NAME "bItemsApiTitleValues".
 ASSIGN apiCode="CONTAINER_POLICY_INVALID" apiMessage="Parametros internos de manutencao invalidos." apiStatus=422.
 policy=ContainerMaintenancePolicy(loginName). financePolicy=ContainerFinancePolicy().
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Manutencao de itens indisponivel." apiStatus=503.
 RUN VALUE(baseRuntimePath) PERSISTENT SET baseRuntime(INPUT ?).
 RUN VALUE(fiscalRulesPath) PERSISTENT SET fiscalRules(INPUT h[1],INPUT h[2],INPUT h[3],INPUT h[4],INPUT h[5],INPUT h[6],INPUT h[7],INPUT h[8],INPUT h[9],INPUT h[10],INPUT h[11],INPUT h[12],INPUT h[13],INPUT h[14],INPUT h[15],INPUT h[16],INPUT h[17],INPUT h[18],INPUT h[19],INPUT h[20],INPUT baseRuntime,INPUT policy).
 RUN VALUE(itemRuntimePath) PERSISTENT SET itemRuntime(fiscalRules,baseRuntime,hMaster,h[2],h[3],h[4],h[19],hOrderPayments,h[18],hAllContainers,hTitAp,hValTitAp,policy,financePolicy).
 /* Delete snapshots come from the locked database row, never displayed values. */
 IF op="delete" AND clean:Has("values") THEN clean:Remove("values").
 RUN VALUE(servicePath)(hMaster,h[2],h[3],h[4],hDiscounts,h[20],h[11],itemRuntime,policy,clean,OUTPUT poResponse).
 IF poResponse:GetLogical("success") AND op<>"get" THEN RUN LogRule IN baseRuntime("INFO","Container: item " + op + " confirmado para usuario " + loginName) NO-ERROR.
 CATCH err AS Progress.Lang.Error:
  RUN Fail(apiCode,apiMessage,apiStatus).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(itemRuntime) THEN DELETE PROCEDURE itemRuntime NO-ERROR.
  IF VALID-HANDLE(fiscalRules) THEN DELETE PROCEDURE fiscalRules NO-ERROR.
  IF VALID-HANDLE(baseRuntime) THEN DELETE PROCEDURE baseRuntime NO-ERROR.
  DO n=1 TO 20: IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
  IF VALID-HANDLE(hMaster) THEN DELETE OBJECT hMaster NO-ERROR.
  IF VALID-HANDLE(hDiscounts) THEN DELETE OBJECT hDiscounts NO-ERROR.
  IF VALID-HANDLE(hOrderPayments) THEN DELETE OBJECT hOrderPayments NO-ERROR.
  IF VALID-HANDLE(hAllContainers) THEN DELETE OBJECT hAllContainers NO-ERROR.
  IF VALID-HANDLE(hTitAp) THEN DELETE OBJECT hTitAp NO-ERROR.
  IF VALID-HANDLE(hValTitAp) THEN DELETE OBJECT hValTitAp NO-ERROR.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean NO-ERROR.
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy NO-ERROR.
  IF VALID-OBJECT(financePolicy) THEN DELETE OBJECT financePolicy NO-ERROR.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE errorObject AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorObject=NEW JsonObject().
 errorObject:Add("code",code). errorObject:Add("message",messageText). errorObject:Add("status",statusCode).
 poResponse:Add("success",FALSE). poResponse:Add("error",errorObject).
END PROCEDURE.
