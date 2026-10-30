/* Authenticated adapter only. Header rules, fiscal math and cost collection
   remain in their reusable services. No business formula lives here. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE loginName AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE runtimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE rulesPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE rules AS HANDLE NO-UNDO.
DEFINE VARIABLE hMaster AS HANDLE NO-UNDO.
DEFINE VARIABLE hSupplier AS HANDLE NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 20 NO-UNDO.
DEFINE VARIABLE hVersionDelete AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE versionDeleteTables AS CHARACTER NO-UNDO INITIAL "item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos".
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL "empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container,pp-it-container,pp_container_permissao,pp_container_saldo_repres,nfs_container,cta_corren_desconto,anexos_container,versoes_item_custo_container,pagtos_container,cta_corren_fornec_imp,item_container_custos".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerMaintenancePolicy.i}
{sursum-api/includes/ContainerApiIdentity.i}
DO ON ERROR UNDO, THROW:
 loginName=ContainerApiLogin().
 IF NOT VALID-OBJECT(poRequest) THEN DO: RUN Fail("CONTAINER_VALIDATION","Requisicao ausente.",422). RETURN. END.
 IF NOT poRequest:Has("resource") OR NOT poRequest:Has("operation") THEN DO: RUN Fail("CONTAINER_VALIDATION","Informe recurso e operacao.",422). RETURN. END.
 IF poRequest:GetType("resource")<>JsonDataType:STRING OR poRequest:GetType("operation")<>JsonDataType:STRING THEN DO: RUN Fail("CONTAINER_VALIDATION","Recurso ou operacao invalida.",422). RETURN. END.
 resourceName=poRequest:GetCharacter("resource").
 IF resourceName<>"containers" THEN DO: RUN Fail("CONTAINER_VALIDATION","Recurso invalido.",422). RETURN. END.
 op=poRequest:GetCharacter("operation").
 IF op<>"create" AND op<>"update" AND op<>"delete" AND op<>"get" THEN DO: RUN Fail("CONTAINER_VALIDATION","Operacao invalida.",422). RETURN. END.
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Manutencao do container indisponivel. Verifique publicacao e conexoes." apiStatus=503.
 IF NOT CONNECTED("espec") OR NOT CONNECTED("ems5") THEN UNDO, THROW NEW Progress.Lang.AppError("Bancos fixos indisponiveis.",0).
 ASSIGN servicePath=SEARCH("sursum-api/programs/ContainersCabecalhoCrudService.r") runtimePath=SEARCH("sursum-api/programs/ContainersCabecalhoRuntime.r") rulesPath=SEARCH("sursum-api/programs/ContainersCabecalhoRules.r").
 IF servicePath=? OR runtimePath=? OR rulesPath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Servicos compilados ausentes.",0).
 CREATE BUFFER hMaster FOR TABLE "espec.pp-container" BUFFER-NAME "bHeaderApiMaster".
 CREATE BUFFER hSupplier FOR TABLE "ems5.fornecedor" BUFFER-NAME "bHeaderApiSupplier".
 DO n=1 TO EXTENT(h): CREATE BUFFER h[n] FOR TABLE ("espec." + ENTRY(n,tables)) BUFFER-NAME ("bHeaderApi" + STRING(n,"99")). END.
 ASSIGN apiCode="CONTAINER_POLICY_INVALID" apiMessage="Parametros internos de manutencao invalidos." apiStatus=422.
 policy=ContainerMaintenancePolicy(loginName).
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Manutencao do container indisponivel." apiStatus=503.
 /* Construtor user IDs are not the legacy Progress numeric user IDs. Zero is
    the documented legacy default; authenticated login remains in the audit. */
 RUN VALUE(runtimePath) PERSISTENT SET runtime(INPUT ?).
 RUN VALUE(rulesPath) PERSISTENT SET rules(INPUT h[1],INPUT h[2],INPUT h[3],INPUT h[4],INPUT h[5],INPUT h[6],INPUT h[7],INPUT h[8],INPUT h[9],INPUT h[10],INPUT h[11],INPUT h[12],INPUT h[13],INPUT h[14],INPUT h[15],INPUT h[16],INPUT h[17],INPUT h[18],INPUT h[19],INPUT h[20],INPUT runtime,INPUT policy).
 IF op="delete" THEN DO:
  DO n=1 TO 4: CREATE BUFFER hVersionDelete[n] FOR TABLE ("espec." + ENTRY(n,versionDeleteTables)) BUFFER-NAME ("bHeaderApiVersionDelete" + STRING(n)). END.
  RUN SetVersionDeleteTargets IN rules(hVersionDelete[1],hVersionDelete[2],hVersionDelete[3],hVersionDelete[4]).
 END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove("resource").
 /* Runtime deletes may carry the displayed record. Values never control
    deletion; the fixed service resolves and locks the persisted target. */
 IF op="delete" AND clean:Has("values") THEN clean:Remove("values").
 RUN VALUE(servicePath)(INPUT hMaster,INPUT hSupplier,INPUT h[1],INPUT rules,INPUT policy,INPUT clean,OUTPUT poResponse).
 IF poResponse:GetLogical("success") AND op<>"get" THEN RUN LogRule IN runtime("INFO","Container: operacao " + op + " confirmada para usuario " + loginName) NO-ERROR.
 /* Existing HTTP handler flushes queued rule logs after this root transaction. */
 CATCH err AS Progress.Lang.Error:
  RUN Fail(apiCode,apiMessage,apiStatus).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(rules) THEN DELETE PROCEDURE rules NO-ERROR.
  IF VALID-HANDLE(runtime) THEN DELETE PROCEDURE runtime NO-ERROR.
  DO n=1 TO EXTENT(h): IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
  DO n=1 TO EXTENT(hVersionDelete): IF VALID-HANDLE(hVersionDelete[n]) THEN DELETE OBJECT hVersionDelete[n] NO-ERROR. END.
  IF VALID-HANDLE(hMaster) THEN DELETE OBJECT hMaster NO-ERROR.
  IF VALID-HANDLE(hSupplier) THEN DELETE OBJECT hSupplier NO-ERROR.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean NO-ERROR.
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy NO-ERROR.
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
