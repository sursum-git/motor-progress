/* Root transaction driver. Fixed reusable services own every business rule. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phVersion AS HANDLE EXTENT 8 NO-UNDO.
DEFINE INPUT PARAMETER phFiscal AS HANDLE EXTENT 11 NO-UNDO.
DEFINE INPUT PARAMETER phClose AS HANDLE EXTENT 14 NO-UNDO.
DEFINE INPUT PARAMETER phVersionRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phHeaderRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poHeaderPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poClosePolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE op AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "CONTAINER_PROCESS_INVALID_REQUEST".
DEFINE VARIABLE failureStatus AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE master AS HANDLE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE inputs AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE auditValue AS JsonObject NO-UNDO.
DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
DEFINE VARIABLE dataValue AS JsonObject NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE messageValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE idsValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
{sursum-api/includes/ContainerProcessBoundary.i}
{sursum-api/includes/ContainerTransactionAudit.i}
DO ON ERROR UNDO, THROW:
 cid=ContainerProcessRequest(poRequest). op=poRequest:GetCharacter("operation").
 IF TRANSACTION THEN DO: failureCode="CONTAINER_PROCESS_TRANSACTION_CONTEXT". failureStatus=409. UNDO, THROW NEW Progress.Lang.AppError("Comando exige transacao raiz propria.",1). END.
 failureCode="CONTAINER_PROCESS_CONFIGURATION". failureStatus=503.
 IF NOT VALID-OBJECT(poHeaderPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Politica autenticada ausente.",1).
 IF poHeaderPolicy:GetType("actor")<>JsonDataType:OBJECT OR NOT VALID-HANDLE(phVersion[1]) THEN UNDO, THROW NEW Progress.Lang.AppError("Contexto privado indisponivel.",1).
 master=phVersion[1].
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove("resource").
 policy=CAST(poHeaderPolicy:Clone(),JsonObject).
 IF op="gerar" THEN DO:
  IF policy:Has("allow_nested") THEN policy:Set("allow_nested",TRUE). ELSE policy:Add("allow_nested",TRUE).
  IF policy:Has("enable_distribution") THEN policy:Set("enable_distribution",TRUE). ELSE policy:Add("enable_distribution",TRUE).
  servicePath=SEARCH("sursum-api/programs/ContainersVersionService.r").
  IF servicePath=? THEN servicePath=SEARCH("ContainersVersionService.r").
 END.
 ELSE IF op="fechar" THEN DO:
  IF NOT VALID-OBJECT(poClosePolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Politica de fechamento ausente.",1).
  DELETE OBJECT policy. policy=CAST(poClosePolicy:Clone(),JsonObject).
  IF policy:Has("allow_nested") THEN policy:Set("allow_nested",TRUE). ELSE policy:Add("allow_nested",TRUE).
  servicePath=SEARCH("sursum-api/programs/ContainersItemCustoCloseService.r").
  IF servicePath=? THEN servicePath=SEARCH("ContainersItemCustoCloseService.r").
 END.
 ELSE DO:
  DELETE OBJECT policy. policy=NEW JsonObject(). policy:Add("actor",poHeaderPolicy:GetJsonObject("actor"):GetCharacter("login")).
  policy:Add("usuario_id",poHeaderPolicy:GetInteger("usuario_id")). policy:Add("despesa_distr_custo",poHeaderPolicy:GetInteger("despesa_distr_custo")).
  IF clean:Has("request_id") THEN clean:Remove("request_id").
  IF poRequest:GetCharacter("resource")="nfs" THEN DO:
   servicePath=SEARCH("sursum-api/programs/ContainersNfsLinkService.r").
   IF servicePath=? THEN servicePath=SEARCH("ContainersNfsLinkService.r").
  END.
  ELSE DO:
   servicePath=SEARCH("sursum-api/programs/ContainersImpostosService.r").
   IF servicePath=? THEN servicePath=SEARCH("ContainersImpostosService.r").
  END.
 END.
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Servico compilado ausente.",1).
 IF op="options" THEN DO:
  clean:Set("operation","opcoes_despesas_selecao").
  RUN VALUE(servicePath)(phFiscal[1],phFiscal[2],phFiscal[3],phFiscal[4],phFiscal[5],phFiscal[6],phFiscal[7],phFiscal[8],phFiscal[9],phFiscal[10],phFiscal[11],phHeaderRuntime,policy,?,clean,OUTPUT poResponse).
  RETURN.
 END.
 rootTransaction: DO TRANSACTION ON ERROR UNDO, THROW:
  failureCode="CONTAINER_PROCESS_BUSY". failureStatus=409.
  foundValue=master:FIND-FIRST("WHERE " + master:NAME + ".nr-container=" + TRIM(STRING(cid,"->>>>>>>>>9")),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF master:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Container em uso.",1).
  DO n=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Falha ao bloquear container.",1). END.
  IF NOT foundValue THEN DO: failureCode="CONTAINER_NOT_FOUND". failureStatus=404. UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1). END.
  IF op="calcular_impostos" OR op="selecionar_despesas" THEN DO:
   failureCode="CONTAINER_PROCESS_MED_REQUIRED". failureStatus=422.
   IF master:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE=? OR NOT STRING(master:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE) BEGINS "5" THEN UNDO, THROW NEW Progress.Lang.AppError("Comando fiscal exige container MED sob lock.",1).
   failureCode="CONTAINER_PROCESS_BUSY". failureStatus=409.
  END.
  beforeValue=ProcessSnapshot(master,cid).
  IF op="gerar" THEN RUN VALUE(servicePath)(phVersion[1],phVersion[2],phVersion[3],phVersion[4],phVersion[5],phVersion[6],phVersion[7],phVersion[8],phVersionRuntime,policy,clean,OUTPUT resultValue).
  ELSE IF op="fechar" THEN RUN VALUE(servicePath)(phClose[1],phClose[2],phClose[3],phClose[4],phClose[5],phClose[6],phClose[7],phClose[8],phClose[9],phClose[10],phClose[11],phClose[12],phClose[13],phClose[14],phVersionRuntime,policy,clean,OUTPUT resultValue).
  ELSE IF poRequest:GetCharacter("resource")="nfs" THEN RUN VALUE(servicePath)(master,phVersion[4],policy,clean,OUTPUT resultValue).
  ELSE DO:
   RUN CollectCalculationInputs IN phHeaderRuntime(master,OUTPUT inputs).
   RUN VALUE(servicePath)(phFiscal[1],phFiscal[2],phFiscal[3],phFiscal[4],phFiscal[5],phFiscal[6],phFiscal[7],phFiscal[8],phFiscal[9],phFiscal[10],phFiscal[11],phHeaderRuntime,policy,inputs,clean,OUTPUT resultValue).
  END.
  IF NOT VALID-OBJECT(resultValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Servico sem resultado.",1).
  IF NOT resultValue:GetLogical("success") THEN DO: poResponse=CAST(resultValue:Clone(),JsonObject). UNDO rootTransaction, LEAVE rootTransaction. END.
  IF resultValue:Has("audit") OR NOT resultValue:Has("pendingChanges") THEN UNDO, THROW NEW Progress.Lang.AppError("Servico confirmou auditoria antes da raiz.",1).
  IF op="sincronizar" OR op="calcular_impostos" OR op="selecionar_despesas" THEN DO:
   IF resultValue:GetJsonObject("data"):GetLogical("committed")<>FALSE THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal nao confirmou composicao pendente.",1).
  END.
  ELSE IF resultValue:GetLogical("committed")<>FALSE THEN UNDO, THROW NEW Progress.Lang.AppError("Servico nao confirmou composicao pendente.",1).
  IF NOT master:FIND-FIRST("WHERE " + master:NAME + ".nr-container=" + TRIM(STRING(cid,"->>>>>>>>>9")),EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("Mestre indisponivel apos processo.",1).
  /* The legacy explicit sync event does not invalidate the master/version.
     Expense CRUD applies its own separate approved invalidation policy. */
  afterValue=ProcessSnapshot(master,cid).
  RUN ProcessMergeEvents(resultValue:GetJsonArray("pendingChanges"),cid,INPUT-OUTPUT changes).
  IF beforeValue:GetJsonText()<>afterValue:GetJsonText() THEN DO:
   eventValue=NEW JsonObject(). eventValue:Add("resource","containers"). eventValue:Add("operation","update"). eventValue:Add("recordId",cid).
   eventValue:Add("before",CAST(beforeValue:Clone(),JsonObject)). eventValue:Add("after",CAST(afterValue:Clone(),JsonObject)). changes:Add(eventValue).
  END.
 END.
 IF VALID-OBJECT(poResponse) THEN RETURN.
 /* No JSON below is exposed until the actual root transaction has committed. */
 messageValue="Container " + TRIM(STRING(cid,"->>>>>>>>>9")) + ": ".
 IF op="gerar" OR op="fechar" THEN DO:
  DO n=1 TO changes:Length:
   eventValue=changes:GetJsonObject(n).
   IF eventValue:GetCharacter("resource")=(IF op="gerar" THEN "container_versions" ELSE "item_custos") AND eventValue:GetCharacter("operation")="create" THEN
    idsValue=idsValue + (IF idsValue="" THEN "" ELSE ", ") + TRIM(STRING(eventValue:GetInteger("recordId"),"->>>>>>>>>9")).
  END.
 END.
 IF op="gerar" THEN messageValue=messageValue + "versoes geradas: " + idsValue + ".".
 ELSE IF op="fechar" THEN messageValue=messageValue + "versao " + STRING(poRequest:GetInteger("versao_id")) + "; custos gravados: " + idsValue + ".".
 ELSE IF poRequest:GetCharacter("resource")="nfs" THEN messageValue=messageValue + STRING(resultValue:GetJsonObject("data"):GetInteger("count")) + " nota(s) " + (IF op="associar" THEN "associada(s)." ELSE "desassociada(s). ").
 ELSE messageValue=messageValue + (IF op="calcular_impostos" THEN "impostos calculados; memoria " ELSE IF op="selecionar_despesas" THEN "defaults e despesas selecionadas processados; memoria " ELSE "impostos sincronizados; memoria ") + STRING(resultValue:GetJsonObject("data"):GetInteger("calc_imp_container_id")) + ".".
 poResponse=NEW JsonObject(). IF op="calcular_impostos" OR op="selecionar_despesas" THEN poResponse:Add("committed",TRUE). dataValue=NEW JsonObject(). dataValue:Add("type","message"). dataValue:Add("message",messageValue). poResponse:Add("success",TRUE). poResponse:Add("data",dataValue).
 auditValue=NEW JsonObject(). auditValue:Add("version",1). auditValue:Add("source","progress-transaction"). auditValue:Add("resource","container_processes"). auditValue:Add("operation",op).
 actorValue=NEW JsonObject(). actorValue:Add("login",poHeaderPolicy:GetJsonObject("actor"):GetCharacter("login")).
 auditValue:Add("recordId",cid). auditValue:Add("container_id",cid). auditValue:Add("before",beforeValue). auditValue:Add("after",afterValue). auditValue:Add("changes",changes). auditValue:Add("actor",actorValue).
 IF poRequest:Has("request_id") THEN auditValue:Add("request_id",poRequest:GetCharacter("request_id")). poResponse:Add("audit",auditValue).
 IF VALID-HANDLE(phHeaderRuntime) THEN IF LOOKUP("LogRule",phHeaderRuntime:INTERNAL-ENTRIES)>0 THEN RUN LogRule IN phHeaderRuntime("INFO",messageValue) NO-ERROR.
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). eventValue=NEW JsonObject(). eventValue:Add("code",failureCode). eventValue:Add("message",err:GetMessage(1)). eventValue:Add("status",failureStatus).
  poResponse:Add("success",FALSE). poResponse:Add("error",eventValue).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(master) THEN master:BUFFER-RELEASE() NO-ERROR.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean NO-ERROR.
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy NO-ERROR.
  IF VALID-OBJECT(inputs) THEN DELETE OBJECT inputs NO-ERROR.
  IF VALID-OBJECT(resultValue) THEN DELETE OBJECT resultValue NO-ERROR.
 END FINALLY.
END.
