/* Private fixed-buffer distribution composition. No browser financial values.
   Manual return/redistribution is deliberately outside this closed contract. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSituacoes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanyExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenseDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersionItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersions AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttMapping NO-UNDO FIELD id AS INTEGER FIELD snapshotId AS INTEGER FIELD recordRow AS ROWID INDEX pk IS UNIQUE PRIMARY id INDEX snapshotKey IS UNIQUE snapshotId.
DEFINE TEMP-TABLE ttSourceItem NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE VARIABLE bh AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE operationName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "DISTRIBUTION_INVALID_REQUEST".
DEFINE VARIABLE calculatorProgram AS CHARACTER NO-UNDO.
DEFINE VARIABLE companyMode AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE prefixValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
DEFINE VARIABLE latestVersion AS INTEGER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE managedExpenseId AS INTEGER NO-UNDO.
DEFINE VARIABLE snapshotId AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE newLedgerId AS INTEGER NO-UNDO.
DEFINE VARIABLE newExpenseId AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE rowCount AS INTEGER NO-UNDO.
DEFINE VARIABLE nestedValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE allowNested AS LOGICAL NO-UNDO.
DEFINE VARIABLE readOnlyValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE requiredVersion AS LOGICAL NO-UNDO.
DEFINE VARIABLE amountValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE sumValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE inputData AS JsonObject NO-UNDO.
DEFINE VARIABLE planResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE plan AS JsonObject NO-UNDO.
DEFINE VARIABLE data AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeData AS JsonObject NO-UNDO.
DEFINE VARIABLE afterData AS JsonObject NO-UNDO.
DEFINE VARIABLE eventData AS JsonObject NO-UNDO.
DEFINE VARIABLE auditData AS JsonObject NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE qHistory AS HANDLE NO-UNDO.
DEFINE VARIABLE mappings AS JsonArray NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
FUNCTION Exact RETURNS LOGICAL (textValue AS CHARACTER,allowed AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 c=textValue. DO j=1 TO NUM-ENTRIES(allowed): IF c=ENTRY(j,allowed) THEN RETURN TRUE. END. RETURN FALSE.
END FUNCTION.
FUNCTION NumberValue RETURNS DECIMAL (objectData AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO.
 IF objectData:GetType(name)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Numero JSON necessario: " + name,1).
 d=objectData:GetDecimal(name). IF d=? THEN UNDO, THROW NEW Progress.Lang.AppError("Valor desconhecido: " + name,1). RETURN d.
END FUNCTION.
FUNCTION KeyValue RETURNS INTEGER (objectData AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE d AS DECIMAL DECIMALS 10 NO-UNDO. d=NumberValue(objectData,name).
 IF d<=0 OR d>2147483647 OR d<>TRUNCATE(d,0) THEN UNDO, THROW NEW Progress.Lang.AppError("ID inteiro positivo necessario: " + name,1). RETURN INTEGER(d).
END FUNCTION.
FUNCTION Flag RETURNS LOGICAL (objectData AS JsonObject,name AS CHARACTER):
 IF objectData:GetType(name)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario: " + name,1). RETURN objectData:GetLogical(name).
END FUNCTION.
FUNCTION D RETURNS DECIMAL (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL DECIMALS 10 NO-UNDO. v=h:BUFFER-FIELD(name):BUFFER-VALUE.
 IF v=? THEN UNDO, THROW NEW Progress.Lang.AppError("Campo fisico desconhecido: " + name,1). RETURN v.
END FUNCTION.
FUNCTION I RETURNS INTEGER (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL DECIMALS 10 NO-UNDO. v=D(h,name).
 IF v<>TRUNCATE(v,0) OR v< -2147483648 OR v>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError("Campo inteiro invalido: " + name,1). RETURN INTEGER(v).
END FUNCTION.
FUNCTION L RETURNS LOGICAL (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE v AS LOGICAL NO-UNDO. v=h:BUFFER-FIELD(name):BUFFER-VALUE.
 IF v=? THEN UNDO, THROW NEW Progress.Lang.AppError("Campo logico desconhecido: " + name,1). RETURN v.
END FUNCTION.
FUNCTION QueryRows RETURNS HANDLE (h AS HANDLE,conditionText AS CHARACTER):
 DEFINE VARIABLE queryHandle AS HANDLE NO-UNDO.
 CREATE QUERY queryHandle. queryHandle:SET-BUFFERS(h).
 IF NOT queryHandle:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + conditionText + " NO-LOCK") THEN DO:
  DELETE OBJECT queryHandle. UNDO, THROW NEW Progress.Lang.AppError("Consulta de escopo fixo invalida.",1).
 END.
 IF NOT queryHandle:QUERY-OPEN() THEN DO: DELETE OBJECT queryHandle. UNDO, THROW NEW Progress.Lang.AppError("Consulta indisponivel.",1). END.
 queryHandle:GET-FIRST(NO-LOCK). RETURN queryHandle.
END FUNCTION.
FUNCTION Snapshot RETURNS JsonObject (h AS HANDLE):
 DEFINE VARIABLE resultObject AS JsonObject NO-UNDO. DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE name AS CHARACTER NO-UNDO.
 DEFINE VARIABLE textValue AS CHARACTER NO-UNDO. DEFINE VARIABLE intValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE decimalValue AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE flagValue AS LOGICAL NO-UNDO.
 DEFINE VARIABLE dateValue AS DATE NO-UNDO. DEFINE VARIABLE datetimeValue AS DATETIME NO-UNDO. DEFINE VARIABLE zoneValue AS DATETIME-TZ NO-UNDO.
 resultObject=NEW JsonObject().
 DO j=1 TO h:NUM-FIELDS:
  fieldHandle=h:BUFFER-FIELD(j). name=REPLACE(fieldHandle:NAME,"-","_").
  IF fieldHandle:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot extent nao previsto.",1).
  IF fieldHandle:BUFFER-VALUE=? THEN resultObject:AddNull(name).
  ELSE CASE fieldHandle:DATA-TYPE:
   WHEN "INTEGER" THEN DO: intValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,intValue). END.
   WHEN "CHARACTER" THEN DO: textValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,textValue). END.
   WHEN "DECIMAL" THEN DO: decimalValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,decimalValue). END.
   WHEN "LOGICAL" THEN DO: flagValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,flagValue). END.
   WHEN "DATE" THEN DO: dateValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,dateValue). END.
   WHEN "DATETIME" THEN DO: datetimeValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,datetimeValue). END.
   WHEN "DATETIME-TZ" THEN DO: zoneValue=fieldHandle:BUFFER-VALUE. resultObject:Add(name,zoneValue). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo de snapshot nao previsto.",1).
  END CASE.
 END.
 RETURN resultObject.
END FUNCTION.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER objectData AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 names=objectData:GetNames(). DO j=1 TO EXTENT(names): IF NOT Exact(names[j],allowed) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao permitido: " + names[j],1). END.
END PROCEDURE.
PROCEDURE CloseQuery:
 DEFINE INPUT-OUTPUT PARAMETER queryHandle AS HANDLE NO-UNDO.
 IF VALID-HANDLE(queryHandle) THEN DO: queryHandle:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryHandle NO-ERROR. END. queryHandle=?.
END PROCEDURE.
PROCEDURE Warning:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE w AS JsonObject NO-UNDO. w=NEW JsonObject(). w:Add("code",code). w:Add("message",messageText). w:Add("origin","distribution-source-v1"). warnings:Add(w).
END PROCEDURE.
PROCEDURE AddChange:
 DEFINE INPUT PARAMETER resourceName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER operationValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER recordId AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER beforeValue AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER afterValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE eventObject AS JsonObject NO-UNDO.
 eventObject=NEW JsonObject(). eventObject:Add("resource",resourceName). eventObject:Add("operation",operationValue). eventObject:Add("recordId",recordId).
 eventObject:Add("before",beforeValue). eventObject:Add("after",afterValue). changes:Add(eventObject).
END PROCEDURE.
ASSIGN bh[1]=phContainer bh[2]=phEmpresas bh[3]=phSituacoes bh[4]=phItems bh[5]=phPurchaseItems bh[6]=phCompanyExpenses bh[7]=phExpenseDefs bh[8]=phLedger bh[9]=phVersionItems bh[10]=phVersions bh[11]=phExpenses.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError("Request necessario.",1).
 RUN Closed(poRequest,"operation,container_id,version_id,item_mappings,snapshot").
 IF poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao necessaria.",1).
 operationName=poRequest:GetCharacter("operation").
 IF NOT Exact(operationName,"simulate,version,version_check") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao nao habilitada.",1).
 containerId=KeyValue(poRequest,"container_id"). readOnlyValue=operationName<>"version".
 IF operationName="simulate" THEN RUN Closed(poRequest,"operation,container_id").
 ELSE DO:
  IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao privada obrigatoria.",1).
  IF NOT poPolicy:Has("allow_version") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao interna indisponivel.",1).
  IF NOT Flag(poPolicy,"allow_version") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao interna indisponivel.",1).
  versionId=KeyValue(poRequest,"version_id"). mappings=poRequest:GetJsonArray("item_mappings").
  snapshotData=poRequest:GetJsonObject("snapshot"). failureCode="DISTRIBUTION_SNAPSHOT_INVALID".
  IF NOT Flag(snapshotData,"confirmed") OR KeyValue(snapshotData,"container_id")<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot central nao confirmado para este container.",1).
 END.
 failureCode="DISTRIBUTION_CONFIGURATION".
 DO n=1 TO 11: IF NOT VALID-HANDLE(bh[n]) OR bh[n]:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer fixo indisponivel.",1). END.
 IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Politica privada obrigatoria.",1).
 IF poPolicy:GetType("company_policy")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Politica privada de empresa obrigatoria.",1).
 companyMode=poPolicy:GetCharacter("company_policy"). IF NOT Exact(companyMode,"legacy_company_2,container_company") THEN UNDO, THROW NEW Progress.Lang.AppError("Politica privada de empresa invalida.",1).
 foundValue=Flag(poPolicy,"gerar_distr_custo"). managedExpenseId=KeyValue(poPolicy,"despesa_distr_custo").
 calculatorProgram=SEARCH("sursum-api/programs/ContainersDistribuicaoCalculator.r"). IF calculatorProgram=? THEN calculatorProgram=SEARCH("ContainersDistribuicaoCalculator.r").
 IF calculatorProgram=? THEN UNDO, THROW NEW Progress.Lang.AppError("Calculador central compilado indisponivel.",1).
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 IF operationName="simulate" THEN DO:
  failureCode="DISTRIBUTION_CONTAINER_NOT_FOUND".
  IF NOT phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(containerId),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container inexistente.",1).
  RUN LoadPlan. RUN BuildResponse. RETURN.
 END.
 nestedValue=TRANSACTION. allowNested=FALSE.
 IF poPolicy:Has("allow_nested") THEN allowNested=Flag(poPolicy,"allow_nested").
 failureCode="DISTRIBUTION_TRANSACTION_CONTEXT".
 IF nestedValue AND NOT allowNested THEN UNDO, THROW NEW Progress.Lang.AppError("Transacao ambiente exige composicao privada autorizada.",1).
 IF operationName="version" THEN DO:
  failureCode="DISTRIBUTION_IDENTITY_REQUIRED".
  actor=poPolicy:GetJsonObject("actor").
  IF actor:GetType("login")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Ator privado necessario.",1).
  IF TRIM(actor:GetCharacter("login"))="" OR LENGTH(actor:GetCharacter("login"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Login privado invalido.",1).
  rowData=NEW JsonObject(). rowData:Add("login",actor:GetCharacter("login")).
  IF actor:Has("id") THEN DO:
   IF actor:GetType("id")<>JsonDataType:STRING OR LENGTH(actor:GetCharacter("id"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Identidade opaca invalida.",1).
   rowData:Add("id",actor:GetCharacter("id")).
  END. actor=rowData.
  failureCode="DISTRIBUTION_CALLBACK_FAILED".
  IF NOT VALID-HANDLE(phRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("Runtime privado indisponivel.",1).
  IF NOT Exact("NextDistribuicaoId",phRuntime:INTERNAL-ENTRIES) OR NOT Exact("NextDespesaId",phRuntime:INTERNAL-ENTRIES) THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencias fixas indisponiveis.",1).
 END.
 DO TRANSACTION ON ERROR UNDO, THROW:
  failureCode="DISTRIBUTION_BUSY".
  foundValue=phContainer:FIND-FIRST("WHERE " + phContainer:NAME + ".nr-container=" + STRING(containerId),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF phContainer:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Container em uso.",1).
  IF NOT foundValue THEN DO: failureCode="DISTRIBUTION_CONTAINER_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container inexistente.",1). END.
  RUN ValidateVersionAndMappings.
  RUN LoadPlan.
  IF operationName="version" THEN RUN ApplyPlan.
 END.
 RUN BuildResponse.
 IF NOT readOnlyValue AND NOT nestedValue THEN DO:
  auditData=NEW JsonObject(). auditData:Add("version",1). auditData:Add("source","progress-transaction"). auditData:Add("resource","container_distribution").
  auditData:Add("operation",operationName). auditData:Add("container_id",containerId). auditData:Add("recordId",versionId).
  auditData:Add("actor",actor). auditData:Add("changes",changes). auditData:Add("warnings",warnings). poResponse:Add("audit",auditData).
  IF Exact("LogRule",phRuntime:INTERNAL-ENTRIES) THEN RUN LogRule IN phRuntime("info","Distribuicao automatica de custo confirmada.") NO-ERROR.
 END.
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). rowData=NEW JsonObject(). rowData:Add("code",failureCode). rowData:Add("message",e:GetMessage(1)). rowData:Add("status",422). poResponse:Add("error",rowData).
 END CATCH.
 FINALLY:
  RUN CloseQuery(INPUT-OUTPUT q). RUN CloseQuery(INPUT-OUTPUT qHistory).
  DO n=1 TO 11: IF VALID-HANDLE(bh[n]) THEN bh[n]:BUFFER-RELEASE() NO-ERROR. END.
 END FINALLY.
END.
PROCEDURE ValidateVersionAndMappings:
 failureCode="DISTRIBUTION_VERSION_CONFLICT". latestVersion=0.
 q=QueryRows(phVersions,phVersions:NAME + ".container_id=" + STRING(containerId)).
 DO WHILE NOT q:QUERY-OFF-END:
  latestVersion=MAXIMUM(latestVersion,I(phVersions,"versao_id")). q:GET-NEXT(NO-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 IF latestVersion<>versionId THEN UNDO, THROW NEW Progress.Lang.AppError("Versao alvo nao e a ultima deste container.",1).
 failureCode="DISTRIBUTION_MAPPING_INVALID".
 IF mappings:Length=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Mapeamento completo dos itens e obrigatorio.",1).
 DO n=1 TO mappings:Length:
  rowData=mappings:GetJsonObject(n). RUN Closed(rowData,"item_container_id,item_container_custo_id").
  itemId=KeyValue(rowData,"item_container_id"). snapshotId=KeyValue(rowData,"item_container_custo_id").
  FIND ttMapping WHERE ttMapping.id=itemId NO-ERROR. IF AVAILABLE ttMapping THEN UNDO, THROW NEW Progress.Lang.AppError("Item repetido no mapeamento.",1).
  FIND ttMapping WHERE ttMapping.snapshotId=snapshotId NO-ERROR. IF AVAILABLE ttMapping THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot repetido no mapeamento.",1).
  foundValue=phVersionItems:FIND-FIRST("WHERE " + phVersionItems:NAME + ".item_container_custo_id=" + STRING(snapshotId),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF phVersionItems:LOCKED OR NOT foundValue THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot ausente ou em uso.",1).
  IF I(phVersionItems,"versao_id")<>versionId OR I(phVersionItems,"item_container_id")<>itemId THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot nao pertence ao par item/versao.",1).
  CREATE ttMapping. ASSIGN ttMapping.id=itemId ttMapping.snapshotId=snapshotId ttMapping.recordRow=phVersionItems:ROWID.
  IF operationName="version" THEN DO:
   failureCode="DISTRIBUTION_ALREADY_APPLIED".
   IF D(phVersionItems,"vl_custo_distribuido")<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot ja contem distribuicao aplicada.",1).
   q=QueryRows(phLedger,phLedger:NAME + ".item_container_custo_id=" + STRING(snapshotId)).
   IF NOT q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot ja possui movimento de distribuicao.",1).
   RUN CloseQuery(INPUT-OUTPUT q). failureCode="DISTRIBUTION_MAPPING_INVALID".
  END.
 END.
 rowCount=0. q=QueryRows(phVersionItems,phVersionItems:NAME + ".versao_id=" + STRING(versionId)).
 DO WHILE NOT q:QUERY-OFF-END:
  rowCount=rowCount + 1. snapshotId=I(phVersionItems,"item_container_custo_id"). FIND ttMapping WHERE ttMapping.snapshotId=snapshotId NO-ERROR.
  IF NOT AVAILABLE ttMapping THEN UNDO, THROW NEW Progress.Lang.AppError("Mapeamento omite snapshot da versao.",1).
  q:GET-NEXT(NO-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 IF rowCount<>mappings:Length THEN UNDO, THROW NEW Progress.Lang.AppError("Quantidade de snapshots divergente.",1).
END PROCEDURE.
PROCEDURE LoadPlan:
 failureCode="DISTRIBUTION_DATA_INVALID".
 prefixValue=phContainer:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE.
 IF prefixValue=? OR LENGTH(prefixValue)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Estabelecimento do container ausente.",1).
 prefixValue=SUBSTRING(prefixValue,1,1). IF prefixValue<>"1" AND prefixValue<>"5" THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa ERP nao reconhecida.",1).
 q=QueryRows(phEmpresas,phEmpresas:NAME + ".cod_emp_ems2=" + prefixValue).
 IF q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa nao encontrada.",1).
 companyId=I(phEmpresas,"empresa_id"). q:GET-NEXT(NO-LOCK). IF NOT q:QUERY-OFF-END THEN UNDO, THROW NEW Progress.Lang.AppError("Empresa ERP ambigua.",1). RUN CloseQuery(INPUT-OUTPUT q).
 IF NOT phSituacoes:FIND-FIRST("WHERE " + phSituacoes:NAME + ".situacao_container_id=" + STRING(I(phContainer,"situacao_container_id")),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Situacao do container inexistente.",1).
 inputData=NEW JsonObject(). inputData:Add("confirmed",TRUE). inputData:Add("source","distribution-inputs-v1"). inputData:Add("container_id",containerId).
 inputData:Add("container_company_id",companyId). inputData:Add("company_policy",companyMode). inputData:Add("global_enabled",Flag(poPolicy,"gerar_distr_custo")).
 inputData:Add("container_enabled",L(phContainer,"log_gerar_distr_custo")). inputData:Add("status_enabled",L(phSituacoes,"log_gerar_distr_custo")).
 rows=NEW JsonArray(). q=QueryRows(phItems,phItems:NAME + ".container_id=" + STRING(containerId)).
 DO WHILE NOT q:QUERY-OFF-END:
  itemId=I(phItems,"item_container_id"). CREATE ttSourceItem. ttSourceItem.id=itemId.
  IF operationName<>"simulate" THEN DO:
   failureCode="DISTRIBUTION_MAPPING_INVALID". FIND ttMapping WHERE ttMapping.id=itemId NO-ERROR.
   IF NOT AVAILABLE ttMapping THEN UNDO, THROW NEW Progress.Lang.AppError("Mapeamento omite item atual do container.",1). failureCode="DISTRIBUTION_DATA_INVALID".
  END.
  IF NOT phPurchaseItems:FIND-FIRST("WHERE " + phPurchaseItems:NAME + ".item_proc_compra_id=" + STRING(I(phItems,"item_proc_compra_id")),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Item de compra inexistente.",1).
  rowData=NEW JsonObject(). rowData:Add("item_container_id",itemId). rowData:Add("item_proc_compra_id",I(phItems,"item_proc_compra_id")).
  rowData:Add("qt_alocada",D(phItems,"qt_alocada")). rowData:Add("qt_confirm_emb",D(phItems,"qt_confirm_emb")).
  rowData:Add("ind_distr_custo",I(phPurchaseItems,"ind_distr_custo")). rowData:Add("vl_base_tributacao",D(phPurchaseItems,"vl_base_tributacao")). rowData:Add("vl_negociado",D(phPurchaseItems,"vl_negociado")).
  sumValue=0. qHistory=QueryRows(phVersionItems,phVersionItems:NAME + ".item_container_id=" + STRING(itemId) + (IF versionId>0 THEN " AND " + phVersionItems:NAME + ".versao_id<>" + STRING(versionId) ELSE "")).
  DO WHILE NOT qHistory:QUERY-OFF-END: sumValue=sumValue + D(phVersionItems,"vl_custo_distribuido"). qHistory:GET-NEXT(NO-LOCK). END.
  RUN CloseQuery(INPUT-OUTPUT qHistory). rowData:Add("previous_distribution",sumValue). rows:Add(rowData). q:GET-NEXT(NO-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 IF operationName<>"simulate" THEN FOR EACH ttMapping:
  FIND ttSourceItem WHERE ttSourceItem.id=ttMapping.id NO-ERROR.
  IF NOT AVAILABLE ttSourceItem THEN DO: failureCode="DISTRIBUTION_MAPPING_INVALID". UNDO, THROW NEW Progress.Lang.AppError("Mapeamento contem item fora do container.",1). END.
 END.
 inputData:Add("items",rows). rows=NEW JsonArray().
 q=QueryRows(phExpenses,phExpenses:NAME + ".container_id=" + STRING(containerId)).
 DO WHILE NOT q:QUERY-OFF-END:
  rowData=NEW JsonObject(). rowData:Add("despesa_container_id",I(phExpenses,"despesa_container_id")). rowData:Add("despesa_id",I(phExpenses,"despesa_id")).
  rowData:Add("item_container_id",I(phExpenses,"item_container_id")). rowData:Add("vl_prev",D(phExpenses,"vl_prev")). rowData:Add("vl_negociado",D(phExpenses,"vl_negociado")). rows:Add(rowData). q:GET-NEXT(NO-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q). inputData:Add("expenses",rows). rows=NEW JsonArray().
 q=QueryRows(phCompanyExpenses,phCompanyExpenses:NAME + ".empresa_id=" + STRING(IF companyMode="legacy_company_2" THEN 2 ELSE companyId)).
 DO WHILE NOT q:QUERY-OFF-END:
  rowData=NEW JsonObject(). rowData:Add("empresa_id",I(phCompanyExpenses,"empresa_id")). rowData:Add("despesa_id",I(phCompanyExpenses,"despesa_id")). rowData:Add("log_custo",I(phCompanyExpenses,"log_custo")). rows:Add(rowData). q:GET-NEXT(NO-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q). inputData:Add("company_links",rows).
 RUN VALUE(calculatorProgram)(inputData,OUTPUT planResponse).
 IF NOT planResponse:GetLogical("success") THEN DO:
  failureCode=planResponse:GetJsonObject("error"):GetCharacter("code"). UNDO, THROW NEW Progress.Lang.AppError(planResponse:GetJsonObject("error"):GetCharacter("message"),1).
 END.
 plan=planResponse:GetJsonObject("data"). requiredVersion=plan:GetLogical("requiredNewSnapshot").
 DO k=1 TO plan:GetJsonArray("warnings"):Length: warnings:Add(CAST(plan:GetJsonArray("warnings"):GetJsonObject(k):Clone(),JsonObject)). END.
END PROCEDURE.
PROCEDURE ApplyPlan:
 failureCode="DISTRIBUTION_CONFIGURATION".
 IF requiredVersion AND NOT phExpenseDefs:FIND-FIRST("WHERE " + phExpenseDefs:NAME + ".despesa_id=" + STRING(managedExpenseId),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa gerenciada de distribuicao inexistente.",1).
 IF requiredVersion THEN RUN Warning("DISTRIBUTION_CONTAINER_SCOPE_CORRECTION","Despesa automatica usa explicitamente o container validado; o ledger tipo3 possui item direto zero no legado.").
 rows=plan:GetJsonArray("items").
 DO k=1 TO rows:Length:
  rowData=rows:GetJsonObject(k). itemId=rowData:GetInteger("item_container_id"). FIND ttMapping WHERE ttMapping.id=itemId.
  failureCode="DISTRIBUTION_BUSY".
  IF NOT phVersionItems:FIND-BY-ROWID(ttMapping.recordRow,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot em uso.",1).
  beforeData=Snapshot(phVersionItems). amountValue=rowData:GetDecimal("snapshot_persisted_distribution").
  IF D(phVersionItems,"vl_custo_distribuido")<>amountValue THEN DO:
   failureCode="DISTRIBUTION_PERSISTENCE_FAILED". phVersionItems:BUFFER-FIELD("vl_custo_distribuido"):BUFFER-VALUE=amountValue.
   IF NOT phVersionItems:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot de distribuicao recusado.",1).
   afterData=Snapshot(phVersionItems). RUN AddChange("item_container_custos","update",ttMapping.snapshotId,beforeData,afterData).
  END.
  IF NOT rowData:GetLogical("emit_entry") THEN NEXT.
  failureCode="DISTRIBUTION_CALLBACK_FAILED". RUN NextDistribuicaoId IN phRuntime(OUTPUT newLedgerId).
  IF newLedgerId=? OR newLedgerId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia fixa de conta corrente invalida.",1).
  failureCode="DISTRIBUTION_SEQUENCE_CONFLICT".
  foundValue=phLedger:FIND-FIRST("WHERE " + phLedger:NAME + ".cta_corren_custo_distr_id=" + STRING(newLedgerId),NO-LOCK) NO-ERROR.
  IF foundValue THEN UNDO, THROW NEW Progress.Lang.AppError("ID de conta corrente ja existe.",1).
  failureCode="DISTRIBUTION_PERSISTENCE_FAILED".
  IF NOT phLedger:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Movimento recusado.",1).
  phLedger:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE=newLedgerId. phLedger:BUFFER-FIELD("data"):BUFFER-VALUE=TODAY.
  phLedger:BUFFER-FIELD("item_container_custo_id"):BUFFER-VALUE=ttMapping.snapshotId. phLedger:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=0.
  phLedger:BUFFER-FIELD("historico"):BUFFER-VALUE="Vl.Distribuicao de Custo Automatico" + (IF Flag(poPolicy,"gerar_distr_custo") THEN "" ELSE " - Lancamento zerado devido a distribuicao de custo estar desligada").
  phLedger:BUFFER-FIELD("cod_tipo_movto"):BUFFER-VALUE=3. phLedger:BUFFER-FIELD("vl_lancto"):BUFFER-VALUE=rowData:GetDecimal("ledger_amount").
  phLedger:BUFFER-FIELD("login"):BUFFER-VALUE=actor:GetCharacter("login").
  IF NOT phLedger:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Movimento invalido.",1).
  RUN AddChange("cta_corren_custo_distr","create",newLedgerId,NEW JsonObject(),Snapshot(phLedger)). phLedger:BUFFER-RELEASE().
  failureCode="DISTRIBUTION_CALLBACK_FAILED". RUN NextDespesaId IN phRuntime(OUTPUT newExpenseId).
  IF newExpenseId=? OR newExpenseId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia fixa de despesa invalida.",1).
  failureCode="DISTRIBUTION_SEQUENCE_CONFLICT".
  foundValue=phExpenses:FIND-FIRST("WHERE " + phExpenses:NAME + ".despesa_container_id=" + STRING(newExpenseId),NO-LOCK) NO-ERROR.
  IF foundValue THEN UNDO, THROW NEW Progress.Lang.AppError("ID de despesa ja existe.",1).
  failureCode="DISTRIBUTION_PERSISTENCE_FAILED".
  IF NOT phExpenses:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa gerenciada recusada.",1).
  phExpenses:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE=newExpenseId. phExpenses:BUFFER-FIELD("despesa_id"):BUFFER-VALUE=managedExpenseId.
  phExpenses:BUFFER-FIELD("container_id"):BUFFER-VALUE=containerId. phExpenses:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=itemId.
  phExpenses:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=rowData:GetDecimal("ledger_amount"). phExpenses:BUFFER-FIELD("calc_imp_container_id"):BUFFER-VALUE=0.
  phExpenses:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE=0. phExpenses:BUFFER-FIELD("vl_proforma"):BUFFER-VALUE=0.
  phExpenses:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE=newLedgerId. phExpenses:BUFFER-FIELD("perc_calc"):BUFFER-VALUE=0.
  phExpenses:BUFFER-FIELD("log_manual"):BUFFER-VALUE=TRUE.
  phExpenses:BUFFER-FIELD("memoria_calculo"):BUFFER-VALUE=IF Flag(poPolicy,"gerar_distr_custo") THEN "" ELSE "Valor do lancamento zerado devido a distr. custo estar desligada por parametro".
  IF NOT phExpenses:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Despesa gerenciada invalida.",1).
  RUN AddChange("despesas_container","create",newExpenseId,NEW JsonObject(),Snapshot(phExpenses)). phExpenses:BUFFER-RELEASE().
 END.
END PROCEDURE.
PROCEDURE BuildResponse:
 data=NEW JsonObject(). data:Add("container_id",containerId). IF versionId>0 THEN data:Add("version_id",versionId).
 data:Add("plan",plan). data:Add("requiredNewSnapshot",requiredVersion). data:Add("warnings",warnings).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("committed",NOT readOnlyValue AND NOT nestedValue). poResponse:Add("data",data). poResponse:Add("requiredNewSnapshot",requiredVersion).
 IF NOT readOnlyValue AND nestedValue THEN poResponse:Add("pendingChanges",changes).
END PROCEDURE.
