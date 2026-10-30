/* Payment association boundary. The browser cannot choose tables, policies,
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
DEFINE VARIABLE paymentRuntimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE paymentRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE financeBuffers AS HANDLE EXTENT 10 NO-UNDO.
DEFINE VARIABLE baseRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE fiscalRules AS HANDLE NO-UNDO.
DEFINE VARIABLE itemRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE hMaster AS HANDLE NO-UNDO.
DEFINE VARIABLE hOrderPayments AS HANDLE NO-UNDO.
DEFINE VARIABLE hAllContainers AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitleMutex AS HANDLE NO-UNDO.
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
 IF NOT (resourceName="container-pagamentos" AND LOOKUP(op,"create,delete")>0 OR resourceName="pagamentos-disponiveis" AND op="read") THEN DO:
  RUN Fail("CONTAINER_VALIDATION","Recurso ou operacao invalida.",422). RETURN.
 END.
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Associacao de pagamentos indisponiveis. Verifique publicacao e conexoes." apiStatus=503.
 IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco fixo indisponivel.",1).
 CREATE BUFFER hMaster FOR TABLE "espec.pp-container" BUFFER-NAME "bPaymentApiMaster".
 DO n=1 TO 20: CREATE BUFFER h[n] FOR TABLE ("espec." + ENTRY(n,tables)) BUFFER-NAME ("bPaymentApi" + STRING(n,"99")). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove("resource").
 IF NOT CONNECTED("ems5") THEN UNDO, THROW NEW Progress.Lang.AppError("Banco financeiro fixo indisponivel.",1).
 ASSIGN servicePath=SEARCH("sursum-api/programs/ContainersPagamentosCrudService.r")
  baseRuntimePath=SEARCH("sursum-api/programs/ContainersCabecalhoRuntime.r")
  fiscalRulesPath=SEARCH("sursum-api/programs/ContainersCabecalhoRules.r")
  itemRuntimePath=SEARCH("sursum-api/programs/ContainersItensRuntime.r")
  paymentRuntimePath=SEARCH("sursum-api/programs/ContainersPagamentosRuntime.r").
 IF servicePath=? OR baseRuntimePath=? OR fiscalRulesPath=? OR itemRuntimePath=? OR paymentRuntimePath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Servicos de manutencao compilados ausentes.",1).
 CREATE BUFFER hOrderPayments FOR TABLE "espec.pagtos_proc_compra" BUFFER-NAME "bPaymentApiOrderPayments".
 CREATE BUFFER hAllContainers FOR TABLE "espec.pp-container" BUFFER-NAME "bPaymentApiAllContainers".
 CREATE BUFFER hTitAp FOR TABLE "ems5.tit_ap" BUFFER-NAME "bPaymentApiTitles".
 CREATE BUFFER hTitleMutex FOR TABLE "ems5.tit_ap" BUFFER-NAME "bPaymentApiTitleMutex".
 CREATE BUFFER hValTitAp FOR TABLE "ems5.val_tit_ap" BUFFER-NAME "bPaymentApiTitleValues".
 ASSIGN apiCode="CONTAINER_POLICY_INVALID" apiMessage="Parametros internos de manutencao invalidos." apiStatus=422.
 financePolicy=ContainerFinancePolicy().
 ASSIGN financeBuffers[1]=hMaster financeBuffers[2]=h[1] financeBuffers[3]=h[2] financeBuffers[4]=h[3] financeBuffers[5]=h[4] financeBuffers[6]=h[18] financeBuffers[7]=hTitAp financeBuffers[8]=hValTitAp financeBuffers[9]=? financeBuffers[10]=?.
 IF resourceName="pagamentos-disponiveis" THEN DO:
  servicePath=SEARCH("sursum-api/programs/ContainersPainelFinanceReadService.r").
  IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de pagamentos nao publicada.",1).
  RUN VALUE(servicePath)(financeBuffers[1],financeBuffers[2],financeBuffers[3],financeBuffers[4],financeBuffers[5],financeBuffers[6],financeBuffers[7],financeBuffers[8],financeBuffers[9],financeBuffers[10],financePolicy,poRequest,OUTPUT poResponse).
  RETURN.
 END.
 policy=ContainerMaintenancePolicy(loginName).
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Associacao de pagamentos indisponivel." apiStatus=503.
 RUN VALUE(baseRuntimePath) PERSISTENT SET baseRuntime(INPUT ?).
 RUN VALUE(fiscalRulesPath) PERSISTENT SET fiscalRules(INPUT h[1],INPUT h[2],INPUT h[3],INPUT h[4],INPUT h[5],INPUT h[6],INPUT h[7],INPUT h[8],INPUT h[9],INPUT h[10],INPUT h[11],INPUT h[12],INPUT h[13],INPUT h[14],INPUT h[15],INPUT h[16],INPUT h[17],INPUT h[18],INPUT h[19],INPUT h[20],INPUT baseRuntime,INPUT policy).
 RUN VALUE(itemRuntimePath) PERSISTENT SET itemRuntime(fiscalRules,baseRuntime,hMaster,h[2],h[3],h[4],h[19],hOrderPayments,h[18],hAllContainers,hTitAp,hValTitAp,policy,financePolicy).
 RUN VALUE(paymentRuntimePath) PERSISTENT SET paymentRuntime(fiscalRules,itemRuntime,INPUT ?,financeBuffers,financePolicy).
 /* Delete snapshots come from the locked physical link, never displayed values. */
 IF op="delete" AND clean:Has("values") THEN clean:Remove("values").
 /* Currency/eligibility readers own hTitAp; they cannot reuse the mutex buffer. */
 RUN VALUE(servicePath)(hMaster,h[18],hTitleMutex,paymentRuntime,policy,clean,OUTPUT poResponse).
 IF poResponse:GetLogical("success") AND op<>"get" THEN RUN LogRule IN baseRuntime("INFO","Container: pagamento " + op + " confirmado para usuario " + loginName) NO-ERROR.
 CATCH err AS Progress.Lang.Error:
  RUN Fail(apiCode,apiMessage,apiStatus).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(paymentRuntime) THEN DELETE PROCEDURE paymentRuntime NO-ERROR.
  IF VALID-HANDLE(itemRuntime) THEN DELETE PROCEDURE itemRuntime NO-ERROR.
  IF VALID-HANDLE(fiscalRules) THEN DELETE PROCEDURE fiscalRules NO-ERROR.
  IF VALID-HANDLE(baseRuntime) THEN DELETE PROCEDURE baseRuntime NO-ERROR.
  DO n=1 TO 20: IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
  IF VALID-HANDLE(hMaster) THEN DELETE OBJECT hMaster NO-ERROR.
  IF VALID-HANDLE(hOrderPayments) THEN DELETE OBJECT hOrderPayments NO-ERROR.
  IF VALID-HANDLE(hAllContainers) THEN DELETE OBJECT hAllContainers NO-ERROR.
  IF VALID-HANDLE(hTitAp) THEN DELETE OBJECT hTitAp NO-ERROR.
  IF VALID-HANDLE(hTitleMutex) THEN DELETE OBJECT hTitleMutex NO-ERROR.
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
