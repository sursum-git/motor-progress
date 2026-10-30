/* Public authenticated fixed-buffer expense CRUD. All rules stay in services. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE loginValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE runtimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL "pp-container,empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container".
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerMaintenancePolicy.i}
{sursum-api/includes/ContainerApiIdentity.i}
DO ON ERROR UNDO, THROW:
 loginValue=ContainerApiLogin().
 ASSIGN apiCode="CONTAINER_VALIDATION" apiMessage="Requisicao de despesas invalida." apiStatus=422.
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 IF NOT poRequest:Has("resource") THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 IF poRequest:GetType("resource")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 IF COMPARE(poRequest:GetCharacter("resource"),"<>","container-despesas","RAW") THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove("resource").
 IF clean:Has("operation") THEN IF clean:GetType("operation")=JsonDataType:STRING THEN
  IF clean:GetCharacter("operation")="delete" AND clean:Has("values") THEN clean:Remove("values").
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Manutencao de despesas indisponivel. Verifique publicacao e conexoes." apiStatus=503.
 IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 ASSIGN servicePath=SEARCH("sursum-api/programs/ContainersDespesasCrudService.r") runtimePath=SEARCH("sursum-api/programs/ContainersCabecalhoRuntime.r").
 IF servicePath=? OR runtimePath=? THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
 DO n=1 TO 11: CREATE BUFFER h[n] FOR TABLE ("espec." + ENTRY(n,tables)) BUFFER-NAME ("bExpenseApi" + STRING(n,"99")). END.
 ASSIGN apiCode="CONTAINER_POLICY_INVALID" apiMessage="Parametros internos de manutencao invalidos." apiStatus=422.
 policy=ContainerMaintenancePolicy(loginValue).
 ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Manutencao de despesas indisponivel." apiStatus=503.
 RUN VALUE(runtimePath) PERSISTENT SET runtime(INPUT ?).
 RUN VALUE(servicePath)(h[1],h[2],h[3],h[4],h[5],h[6],h[7],h[8],h[9],h[10],h[11],runtime,policy,clean,OUTPUT poResponse).
 CATCH err AS Progress.Lang.Error: RUN Fail(apiCode,apiMessage,apiStatus). END CATCH.
 FINALLY:
  IF VALID-HANDLE(runtime) THEN DELETE PROCEDURE runtime NO-ERROR.
  DO n=1 TO EXTENT(h): IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean NO-ERROR.
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy NO-ERROR.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorValue=NEW JsonObject(). errorValue:Add("code",codeValue). errorValue:Add("message",messageValue). errorValue:Add("status",statusValue).
 poResponse:Add("success",FALSE). poResponse:Add("error",errorValue).
END PROCEDURE.
