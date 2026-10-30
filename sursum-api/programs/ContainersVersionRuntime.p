/* Private provider, fixed dependencies; never a public route. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phHeaderRules AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phHeaderRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCollector AS HANDLE EXTENT 25 NO-UNDO.
DEFINE INPUT PARAMETER phSources AS HANDLE EXTENT 4 NO-UNDO.
DEFINE INPUT PARAMETER phTargets AS HANDLE EXTENT 5 NO-UNDO.
DEFINE INPUT PARAMETER phPrivateContext AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
/* Production always passes ?. TT tests supply a private sequence provider. */
DEFINE INPUT PARAMETER phSequenceProvider AS HANDLE NO-UNDO.
DEFINE VARIABLE followupDepth AS INTEGER NO-UNDO.
DEFINE VARIABLE activeCompositionVersion AS INTEGER NO-UNDO.
FUNCTION Compiled RETURNS CHARACTER(nameValue AS CHARACTER):
 DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
 pathValue=SEARCH("sursum-api/programs/" + nameValue + ".r").
 IF pathValue=? THEN pathValue=SEARCH(nameValue + ".r").
 IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_RUNTIME_CONFIGURATION: helper compilado ausente.",1).
 RETURN pathValue.
END FUNCTION.
FUNCTION CopyObject RETURNS JsonObject(valueObject AS JsonObject): RETURN CAST(valueObject:Clone(),JsonObject). END FUNCTION.
PROCEDURE RequireTransaction:
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_TRANSACTION_CONTEXT: callback exige transacao raiz ativa.",1).
END PROCEDURE.
PROCEDURE CheckMaster:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 RUN RequireTransaction.
 IF NOT VALID-HANDLE(master) OR NOT VALID-HANDLE(phCollector[1]) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_RUNTIME_CONTEXT",1).
 IF NOT master:AVAILABLE OR master:TABLE-HANDLE<>phCollector[1]:TABLE-HANDLE THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_RUNTIME_CONTEXT",1).
 IF master:BUFFER-FIELD("nr-container"):BUFFER-VALUE=? OR master:BUFFER-FIELD("nr-container"):BUFFER-VALUE<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_RUNTIME_CONTEXT",1).
 IF NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTAINER_BUSY",1).
END PROCEDURE.
PROCEDURE CheckConfirmed:
 DEFINE INPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 IF NOT VALID-OBJECT(resultValue) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_HELPER_NO_RESULT",1).
 IF resultValue:GetType("success")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_HELPER_UNCONFIRMED",1).
 IF NOT resultValue:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_HELPER_FAILED: " + resultValue:GetJsonObject("error"):GetCharacter("message"),1).
END PROCEDURE.
PROCEDURE GetStatus:
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE enabledValue AS LOGICAL NO-UNDO.
 IF VALID-OBJECT(poPolicy) THEN IF poPolicy:Has("enable_distribution") THEN DO:
  IF poPolicy:GetType("enable_distribution")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_RUNTIME_CONFIGURATION: opt-in deve ser booleano.",1).
  enabledValue=poPolicy:GetLogical("enable_distribution").
 END.
 resultValue=NEW JsonObject(). resultValue:Add("confirmed",TRUE). resultValue:Add("distribution_enabled",enabledValue).
END PROCEDURE.
PROCEDURE NextVersionId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF VALID-HANDLE(phSequenceProvider) THEN DO: RUN NextVersionId IN phSequenceProvider(OUTPUT valueId). RETURN. END.
 IF phSequenceProvider<>? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SEQUENCE_PROVIDER_INVALID",1).
 valueId=DYNAMIC-NEXT-VALUE("seq_versao_item_container_custo","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SEQUENCE_UNAVAILABLE",1).
END PROCEDURE.
PROCEDURE NextVersionItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF VALID-HANDLE(phSequenceProvider) THEN DO: RUN NextVersionItemId IN phSequenceProvider(OUTPUT valueId). RETURN. END.
 IF phSequenceProvider<>? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SEQUENCE_PROVIDER_INVALID",1).
 valueId=DYNAMIC-NEXT-VALUE("seq_item_container_custos","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_ITEM_SEQUENCE_UNAVAILABLE",1).
END PROCEDURE.
PROCEDURE NextDistribuicaoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF VALID-HANDLE(phSequenceProvider) THEN DO: RUN NextDistribuicaoId IN phSequenceProvider(OUTPUT valueId). RETURN. END.
 IF phSequenceProvider<>? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SEQUENCE_PROVIDER_INVALID",1).
 valueId=DYNAMIC-NEXT-VALUE("seq_cta_corren_custo_distr","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_DISTRIBUTION_SEQUENCE_UNAVAILABLE",1).
END PROCEDURE.
PROCEDURE NextItemCustoId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF VALID-HANDLE(phSequenceProvider) THEN DO: RUN NextItemCustoId IN phSequenceProvider(OUTPUT valueId). RETURN. END.
 IF phSequenceProvider<>? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SEQUENCE_PROVIDER_INVALID",1).
 valueId=DYNAMIC-NEXT-VALUE("seq_item_custos","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("ITEM_COST_SEQUENCE_UNAVAILABLE",1).
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF VALID-HANDLE(phSequenceProvider) THEN DO: RUN NextDespesaId IN phSequenceProvider(OUTPUT valueId). RETURN. END.
 IF phSequenceProvider<>? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_SEQUENCE_PROVIDER_INVALID",1).
 RUN NextDespesaId IN phHeaderRuntime(OUTPUT valueId).
END PROCEDURE.
PROCEDURE RunDistribution:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER versionValue AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER mappings AS JsonArray NO-UNDO.
 DEFINE INPUT PARAMETER snapshotValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER checkOnly AS LOGICAL NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 RUN CheckMaster(master). cid=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
 RUN GetVersionContext IN phPrivateContext(master,OUTPUT contextValue).
 IF NOT VALID-OBJECT(contextValue) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_PRIVATE_CONTEXT_UNCONFIRMED",1).
 IF contextValue:GetType("confirmed")<>JsonDataType:BOOLEAN OR contextValue:GetLogical("confirmed")<>TRUE OR contextValue:GetInteger("container_id")<>cid THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_PRIVATE_CONTEXT_UNCONFIRMED",1).
 policyValue=CopyObject(contextValue:GetJsonObject("distribution_policy")).
 policyValue:Add("company_policy","container_company"). policyValue:Add("allow_nested",TRUE). policyValue:Add("allow_version",TRUE). policyValue:Add("actor",CopyObject(poPolicy:GetJsonObject("actor"))).
 requestValue=NEW JsonObject(). requestValue:Add("operation",IF checkOnly THEN "version_check" ELSE "version"). requestValue:Add("container_id",cid). requestValue:Add("version_id",versionValue). requestValue:Add("item_mappings",CAST(mappings:Clone(),JsonArray)). requestValue:Add("snapshot",CopyObject(snapshotValue)).
 servicePath=Compiled("ContainersDistribuicaoService").
 RUN VALUE(servicePath)(master,phCollector[5],phSources[4],phCollector[2],phCollector[3],phCollector[6],phCollector[7],phCollector[9],phCollector[14],phCollector[15],phCollector[8],THIS-PROCEDURE,policyValue,requestValue,OUTPUT resultValue).
 RUN CheckConfirmed(resultValue).
 IF resultValue:Has("audit") OR resultValue:GetLogical("committed")<>FALSE THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_DISTRIBUTION_PREMATURE_COMMIT",1).
 IF resultValue:GetType("requiredNewSnapshot")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_DISTRIBUTION_INVALID_RESULT",1).
 FINALLY:
  IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue.
  IF VALID-OBJECT(policyValue) THEN DELETE OBJECT policyValue.
  IF VALID-OBJECT(requestValue) THEN DELETE OBJECT requestValue.
 END FINALLY.
END PROCEDURE.
PROCEDURE ApplyVersionDistribution:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER versionValue AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER mappings AS JsonArray NO-UNDO.
 DEFINE INPUT PARAMETER snapshotValue AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE statusValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE effects AS JsonObject NO-UNDO.
 DEFINE VARIABLE followupValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE changes AS JsonArray NO-UNDO.
 DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE masterRow AS ROWID NO-UNDO.
 DEFINE VARIABLE previousActiveVersion AS INTEGER NO-UNDO.
 previousActiveVersion=activeCompositionVersion.
 RUN CheckMaster(master). ASSIGN cid=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE masterRow=master:ROWID.
 RUN GetStatus(OUTPUT statusValue).
 IF NOT statusValue:GetLogical("distribution_enabled") THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_DISTRIBUTION_UNSUPPORTED",1).
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 /* The legacy combined flags disable distribution before reading its pool. */
 IF NOT phSources[4]:FIND-FIRST("WHERE " + phSources[4]:NAME + ".situacao_container_id=" + STRING(master:BUFFER-FIELD("situacao_container_id"):BUFFER-VALUE),SHARE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_DISTRIBUTION_STATUS_INVALID",1).
 IF phSources[4]:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE=? OR master:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE=? THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_DISTRIBUTION_STATUS_INVALID",1).
 IF master:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE AND phSources[4]:BUFFER-FIELD("log_gerar_distr_custo"):BUFFER-VALUE THEN DO:
  IF followupDepth=0 THEN DO:
   IF activeCompositionVersion<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("UNSTABLE_DISTRIBUTION: composicao raiz ja ativa.",1).
   activeCompositionVersion=versionValue.
  END.
  RUN RunDistribution(master,versionValue,mappings,snapshotValue,followupDepth=1,OUTPUT effects).
  /* The nested distribution service releases shared buffers in FINALLY. */
  IF NOT master:FIND-BY-ROWID(masterRow,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTAINER_BUSY",1).
  IF followupDepth=1 THEN DO:
   IF effects:GetLogical("requiredNewSnapshot") THEN UNDO, THROW NEW Progress.Lang.AppError("UNSTABLE_DISTRIBUTION: segunda fotografia ainda exige delta persistivel.",1).
  END.
  ELSE DO:
   changes=CAST(effects:GetJsonArray("pendingChanges"):Clone(),JsonArray).
   warnings=CAST(effects:GetJsonObject("data"):GetJsonArray("warnings"):Clone(),JsonArray).
   IF effects:GetLogical("requiredNewSnapshot") THEN DO:
    contextValue=NEW JsonObject(). contextValue:Add("expected_latest_version_id",versionValue). contextValue:Add("reason","automatic-distribution").
    RUN GenerateFollowupVersion(master,contextValue,OUTPUT followupValue).
    DO n=1 TO followupValue:GetJsonArray("pendingChanges"):Length: changes:Add(CopyObject(followupValue:GetJsonArray("pendingChanges"):GetJsonObject(n))). END.
    IF followupValue:Has("warnings") THEN DO n=1 TO followupValue:GetJsonArray("warnings"):Length: warnings:Add(followupValue:GetJsonArray("warnings"):GetCharacter(n)). END.
   END.
  END.
 END.
 resultValue=NEW JsonObject(). resultValue:Add("success",TRUE). resultValue:Add("committed",FALSE). resultValue:Add("requiredNewSnapshot",FALSE). resultValue:Add("pendingChanges",changes). resultValue:Add("warnings",warnings).
 IF VALID-OBJECT(followupValue) THEN resultValue:Add("followup",CopyObject(followupValue)).
 FINALLY:
  activeCompositionVersion=previousActiveVersion.
  IF VALID-OBJECT(statusValue) THEN DELETE OBJECT statusValue.
  IF VALID-OBJECT(effects) THEN DELETE OBJECT effects.
  IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue.
  IF VALID-OBJECT(followupValue) THEN DELETE OBJECT followupValue.
 END FINALLY.
END PROCEDURE.
PROCEDURE GenerateFollowupVersion:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
 DEFINE VARIABLE previousDepth AS INTEGER NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE latestValue AS INTEGER NO-UNDO.
 previousDepth=followupDepth.
 DO ON ERROR UNDO, THROW:
  RUN CheckMaster(master). cid=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
  IF followupDepth<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("UNSTABLE_DISTRIBUTION: limite de duas fotografias.",1).
  IF activeCompositionVersion<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FOLLOWUP_OUTSIDE_DRIVER",1).
  latestValue=contextValue:GetInteger("expected_latest_version_id").
  IF latestValue<>activeCompositionVersion THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FOLLOWUP_CONFLICT",1).
  IF NOT phCollector[15]:FIND-FIRST("WHERE " + phCollector[15]:NAME + ".versao_id=" + STRING(latestValue) + " AND " + phCollector[15]:NAME + ".container_id=" + STRING(cid),EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FOLLOWUP_CONFLICT",1).
  requestValue=NEW JsonObject(). requestValue:Add("operation","gerar"). requestValue:Add("container_id",cid). requestValue:Add("expected_latest_version_id",latestValue).
  requestValue:Add("tipo_versao_id",INTEGER(phCollector[15]:BUFFER-FIELD("tipo_versao_id"):BUFFER-VALUE)). requestValue:Add("descricao",STRING(phCollector[15]:BUFFER-FIELD("descricao"):BUFFER-VALUE)).
  policyValue=CopyObject(poPolicy).
  IF policyValue:Has("allow_nested") THEN policyValue:Set("allow_nested",TRUE). ELSE policyValue:Add("allow_nested",TRUE).
  IF policyValue:Has("enable_distribution") THEN policyValue:Set("enable_distribution",TRUE). ELSE policyValue:Add("enable_distribution",TRUE).
  followupDepth=1.
  servicePath=Compiled("ContainersVersionService").
  RUN VALUE(servicePath)(master,phTargets[1],phCollector[15],phCollector[14],phTargets[2],phTargets[3],phTargets[4],phTargets[5],THIS-PROCEDURE,policyValue,requestValue,OUTPUT resultValue).
  RUN CheckConfirmed(resultValue).
  IF resultValue:Has("audit") OR resultValue:GetLogical("committed")<>FALSE THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FOLLOWUP_PREMATURE_COMMIT",1).
  FINALLY:
   followupDepth=previousDepth.
   IF VALID-OBJECT(requestValue) THEN DELETE OBJECT requestValue.
   IF VALID-OBJECT(policyValue) THEN DELETE OBJECT policyValue.
  END FINALLY.
 END.
END PROCEDURE.
PROCEDURE PrepareVersionFiscal:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
 RUN CheckMaster(master).
 IF NOT VALID-HANDLE(phHeaderRules) OR NOT VALID-HANDLE(phHeaderRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FISCAL_CONFIGURATION",1).
 contextValue=NEW JsonObject(). contextValue:Add("operation","update"). contextValue:Add("container_id",INTEGER(master:BUFFER-FIELD("nr-container"):BUFFER-VALUE)).
 RUN OnUpdate IN phHeaderRules(master,contextValue,OUTPUT responseValue).
 RUN CheckConfirmed(responseValue).
 IF responseValue:Has("audit") THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FISCAL_PREMATURE_AUDIT",1).
 IF responseValue:Has("committed") THEN IF responseValue:GetLogical("committed")<>FALSE THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_FISCAL_PREMATURE_COMMIT",1).
 FINALLY: IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue. END FINALLY.
END PROCEDURE.
PROCEDURE CollectVersionSnapshot:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER snapshot AS JsonObject NO-UNDO.
 DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
 DEFINE VARIABLE financial AS JsonObject NO-UNDO.
 DEFINE VARIABLE calculated AS JsonObject NO-UNDO.
 DEFINE VARIABLE physical AS JsonObject NO-UNDO.
 DEFINE VARIABLE aux AS HANDLE NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE masterRow AS ROWID NO-UNDO.
 DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
 RUN CheckMaster(master). ASSIGN cid=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE masterRow=master:ROWID.
 IF NOT VALID-HANDLE(phPrivateContext) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_PRIVATE_CONTEXT_REQUIRED",1).
 RUN GetVersionContext IN phPrivateContext(master,OUTPUT contextValue).
 IF NOT VALID-OBJECT(contextValue) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_PRIVATE_CONTEXT_UNCONFIRMED",1).
 IF contextValue:GetType("confirmed")<>JsonDataType:BOOLEAN OR contextValue:GetLogical("confirmed")<>TRUE OR contextValue:GetInteger("container_id")<>cid THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_PRIVATE_CONTEXT_UNCONFIRMED",1).
 financePolicy=CopyObject(contextValue:GetJsonObject("finance_policy")). financePolicy:Add("capture_rows",TRUE).
 servicePath=Compiled("ContainersPagamentoTotalsService").
 RUN VALUE(servicePath)(master,phSources[1],phSources[2],phSources[3],financePolicy,cid,OUTPUT financial).
 RUN CheckConfirmed(financial).
 IF NOT master:FIND-BY-ROWID(masterRow,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTAINER_BUSY",1).
 servicePath=Compiled("ContainersVersionAuxSnapshotService").
 RUN VALUE(servicePath) PERSISTENT SET aux(phCollector[2],phCollector[5],phCollector[6],phCollector[8],phCollector[10],phCollector[12],phCollector[16],phCollector[19],phCollector[21],phSources[4]).
 RUN CollectPhysical IN aux(master,financial:GetJsonObject("data"),OUTPUT physical).
 servicePath=Compiled("ContainersVersaoCostAdapter").
 RUN VALUE(servicePath)(phCollector[1],phCollector[2],phCollector[3],phCollector[4],phCollector[5],phCollector[6],phCollector[7],phCollector[8],phCollector[9],phCollector[10],phCollector[11],phCollector[12],phCollector[13],phCollector[14],phCollector[15],phCollector[16],phCollector[17],phCollector[18],phCollector[19],phCollector[20],phCollector[21],phCollector[22],phCollector[23],phCollector[24],phCollector[25],financial:GetJsonObject("data"),contextValue:GetJsonObject("cost_policy"),cid,OUTPUT calculated).
 RUN CheckConfirmed(calculated).
 IF NOT master:FIND-BY-ROWID(masterRow,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTAINER_BUSY",1).
 RUN FinalizeSnapshot IN aux(master,physical,calculated:GetJsonObject("data"),OUTPUT snapshot).
 FINALLY:
  IF VALID-HANDLE(aux) THEN DELETE PROCEDURE aux.
  IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue.
  IF VALID-OBJECT(financePolicy) THEN DELETE OBJECT financePolicy.
  IF VALID-OBJECT(financial) THEN DELETE OBJECT financial.
  IF VALID-OBJECT(calculated) THEN DELETE OBJECT calculated.
  IF VALID-OBJECT(physical) THEN DELETE OBJECT physical.
 END FINALLY.
END PROCEDURE.
