/* Internal fixed-buffer version service. HTTP integration is separate. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTypes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersions AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE children AS HANDLE EXTENT 5 NO-UNDO.
DEFINE VARIABLE childFields AS CHARACTER EXTENT 5 NO-UNDO.
DEFINE VARIABLE headerFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE versionFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE itemFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE operationValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "VERSION_INVALID_REQUEST".
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE versionId AS INTEGER NO-UNDO.
DEFINE VARIABLE typeId AS INTEGER NO-UNDO.
DEFINE VARIABLE expectedId AS INTEGER NO-UNDO.
DEFINE VARIABLE latestId AS INTEGER NO-UNDO.
DEFINE VARIABLE newItemId AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE actualComplete AS LOGICAL NO-UNDO.
DEFINE VARIABLE nestedValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE allowNested AS LOGICAL NO-UNDO.
DEFINE VARIABLE enableDistribution AS LOGICAL NO-UNDO.
DEFINE VARIABLE runtimeStatus AS JsonObject NO-UNDO.
DEFINE VARIABLE distributionValue AS JsonObject NO-UNDO.
DEFINE VARIABLE itemMappings AS JsonArray NO-UNDO.
DEFINE VARIABLE distributionChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE loginValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE fiscalValue AS JsonObject NO-UNDO.
DEFINE VARIABLE collectedValue AS JsonObject NO-UNDO.
DEFINE VARIABLE costValue AS JsonObject NO-UNDO.
DEFINE VARIABLE headerValue AS JsonObject NO-UNDO.
DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE itemValue AS JsonObject NO-UNDO.
DEFINE VARIABLE dollarValue AS JsonObject NO-UNDO.
DEFINE VARIABLE inputValue AS JsonObject NO-UNDO.
DEFINE VARIABLE mappedValue AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotValue AS JsonObject NO-UNDO.
DEFINE VARIABLE masterBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE masterAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE masterEvent AS JsonObject NO-UNDO.
DEFINE VARIABLE pendingChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE childEvents AS JsonArray NO-UNDO.
DEFINE VARIABLE auditValue AS JsonObject NO-UNDO.
DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO.
/* Read-only public projection shares this persisted-snapshot collector. */
DEFINE VARIABLE readRows AS INTEGER NO-UNDO.
DEFINE VARIABLE readMaxRows AS INTEGER NO-UNDO INITIAL 50000.
DEFINE VARIABLE readStarted AS INTEGER NO-UNDO.
DEFINE VARIABLE readComplete AS LOGICAL NO-UNDO.
DEFINE VARIABLE readRequireMaster AS LOGICAL NO-UNDO INITIAL TRUE.
DEFINE VARIABLE realRows AS JsonArray NO-UNDO.
DEFINE VARIABLE dollarRows AS JsonArray NO-UNDO.
DEFINE VARIABLE inputRows AS JsonArray NO-UNDO.
DEFINE VARIABLE memoryText AS LONGCHAR NO-UNDO.
DEFINE TEMP-TABLE ttPair NO-UNDO FIELD id AS INTEGER FIELD brl AS INTEGER FIELD usd AS INTEGER FIELD component AS INTEGER INDEX pk IS UNIQUE PRIMARY id.

FUNCTION Exact RETURNS LOGICAL (nameValue AS CHARACTER,listValue AS CHARACTER):
 DEFINE VARIABLE textValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE indexValue AS INTEGER NO-UNDO.
 textValue=nameValue.
 DO indexValue=1 TO NUM-ENTRIES(listValue): IF textValue=ENTRY(indexValue,listValue) THEN RETURN TRUE. END.
 RETURN FALSE.
END FUNCTION.
FUNCTION JsonRecord RETURNS JsonObject (bufferValue AS HANDLE,fieldsValue AS CHARACTER) FORWARD.
FUNCTION MasterRecord RETURNS JsonObject ():
 DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldsValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DO n=1 TO phMaster:NUM-FIELDS: fieldsValue=fieldsValue + (IF n=1 THEN "" ELSE ",") + phMaster:BUFFER-FIELD(n):NAME. END.
 resultValue=JsonRecord(phMaster,fieldsValue).
 resultValue:Add("container_id",containerId).
 RETURN resultValue.
END FUNCTION.
FUNCTION Key RETURNS INTEGER (objectValue AS JsonObject,nameValue AS CHARACTER,allowZero AS LOGICAL):
 DEFINE VARIABLE textValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE digitNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE amountValue AS DECIMAL NO-UNDO.
 IF NOT VALID-OBJECT(objectValue) THEN RETURN ?.
 IF NOT objectValue:Has(nameValue) THEN RETURN ?.
 IF objectValue:GetType(nameValue)=JsonDataType:NUMBER THEN textValue=objectValue:GetJsonText(nameValue).
 ELSE IF objectValue:GetType(nameValue)=JsonDataType:STRING THEN textValue=objectValue:GetCharacter(nameValue).
 ELSE RETURN ?.
 IF LENGTH(textValue)<1 OR LENGTH(textValue)>10 THEN RETURN ?.
 DO digitNo=1 TO LENGTH(textValue): IF INDEX("0123456789",SUBSTRING(textValue,digitNo,1))=0 THEN RETURN ?. END.
 amountValue=DECIMAL(textValue).
 IF amountValue>2147483647 OR amountValue<(IF allowZero THEN 0 ELSE 1) THEN RETURN ?.
 RETURN INTEGER(amountValue).
END FUNCTION.
FUNCTION JsonRecord RETURNS JsonObject (bufferValue AS HANDLE,fieldsValue AS CHARACTER):
 DEFINE VARIABLE objectValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
 DEFINE VARIABLE indexValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE stringValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE integerValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE decimalValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE logicalValue AS LOGICAL NO-UNDO.
 DEFINE VARIABLE dateValue AS DATE NO-UNDO.
 DEFINE VARIABLE dateTimeValue AS DATETIME-TZ NO-UNDO.
 DEFINE VARIABLE plainTimeValue AS DATETIME NO-UNDO.
 objectValue=NEW JsonObject().
 DO indexValue=1 TO NUM-ENTRIES(fieldsValue):
  fieldName=ENTRY(indexValue,fieldsValue). fieldValue=bufferValue:BUFFER-FIELD(fieldName).
  IF fieldValue:BUFFER-VALUE=? THEN objectValue:AddNull(fieldName).
  ELSE CASE fieldValue:DATA-TYPE:
   WHEN "CHARACTER" THEN DO: stringValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,stringValue). END.
   WHEN "INTEGER" THEN DO: integerValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,integerValue). END.
   WHEN "DECIMAL" THEN DO: decimalValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,decimalValue). END.
   WHEN "LOGICAL" THEN DO: logicalValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,logicalValue). END.
   WHEN "DATE" THEN DO: dateValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,dateValue). END.
   WHEN "DATETIME-TZ" THEN DO: dateTimeValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,dateTimeValue). END.
   WHEN "DATETIME" THEN DO: plainTimeValue=fieldValue:BUFFER-VALUE. objectValue:Add(fieldName,plainTimeValue). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo de snapshot nao suportado.",1).
  END CASE.
 END.
 RETURN objectValue.
END FUNCTION.

ASSIGN children[1]=phItems children[2]=phExpenses children[3]=phNfs children[4]=phPayments children[5]=phDiscounts
 headerFields="vl_dolar_compra,vl_desconto_utiliz_dolar,vl_desconto_utiliz_real,vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,situacao_container_id,desc_sit_container,cod_tipo_cotacao,vl_cotacao,data_ref_cotacao,perc_fixo_container,hist_dolar"
 versionFields="versao_id,container_id,tipo_versao_id,dt_hr_versao,cod_usuario,descricao,ind_sit_versao,vl_dolar_medio," + headerFields
 itemFields="item_container_custo_id,versao_id,item_container_id,it_codigo,item_custo_id,memoria_calculo,vl_desp_prev_real,vl_custo_prev_real,vl_pago_real,qt_alocada,qt_confirm_emb,qt_recebto_fisico,vl_desp_realiz_real,vl_unit_prev,vl_unit_realiz,vl_desp_prev_dolar,vl_custo_prev_dolar,vl_pago_dolar,vl_desp_realiz_dolar,vl_desconto_utiliz_dolar,vl_unit_prev_dolar,vl_unit_realiz_dolar,vl_custo_distribuido,vl_negociado,vl_desp_prev_real_sem_distr_cust,vl_desp_prev_dolar_sem_distr_cus"
 childFields[1]=itemFields
 childFields[2]="despesa_id,vl_prev,vl_negociado,vl_proforma,vl_base_imp,calc_imp_container_id,log_custo"
 childFields[3]="documento,serie,estab,nat_operacao,cod_emitente,vl_mercadoria,vl_despesa"
 childFields[4]="num_id_tit_ap,vl_real,vl_dolar"
 childFields[5]="desconto_importacao_id,vl_autoriz_real,vl_autoriz_dolar,log_custo".
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,"operation,container_id,versao_id,tipo_versao_id,descricao,expected_latest_version_id,request_id").
 IF NOT poRequest:Has("operation") OR poRequest:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao obrigatoria.",1).
 operationValue=poRequest:GetCharacter("operation").
 IF NOT Exact(operationValue,"gerar,consultar,excluir_incompleta") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao nao suportada.",1).
 containerId=Key(poRequest,"container_id",FALSE).
 IF containerId=? THEN UNDO, THROW NEW Progress.Lang.AppError("container_id inteiro positivo obrigatorio.",1).
 IF operationValue="consultar" THEN RUN Closed(poRequest,"operation,container_id,versao_id").
 ELSE IF operationValue="gerar" THEN RUN Closed(poRequest,"operation,container_id,tipo_versao_id,descricao,expected_latest_version_id,request_id").
 ELSE RUN Closed(poRequest,"operation,container_id,versao_id,expected_latest_version_id,request_id").
 IF poRequest:Has("versao_id") THEN DO:
  versionId=Key(poRequest,"versao_id",FALSE). IF versionId=? THEN UNDO, THROW NEW Progress.Lang.AppError("versao_id invalido.",1).
 END.
 IF operationValue="excluir_incompleta" AND versionId=0 THEN UNDO, THROW NEW Progress.Lang.AppError("versao_id obrigatorio.",1).
 IF operationValue<>"consultar" THEN DO:
  expectedId=Key(poRequest,"expected_latest_version_id",TRUE).
  IF expectedId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Expectativa da ultima versao obrigatoria.",1).
  IF poRequest:Has("request_id") AND (poRequest:GetType("request_id")<>JsonDataType:STRING OR LENGTH(poRequest:GetCharacter("request_id"))>128) THEN UNDO, THROW NEW Progress.Lang.AppError("Rastreio invalido.",1).
 END.
 IF operationValue="gerar" THEN DO:
  typeId=Key(poRequest,"tipo_versao_id",FALSE).
  IF typeId=? OR NOT poRequest:Has("descricao") THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo e descricao obrigatorios.",1).
  IF poRequest:GetType("descricao")<>JsonDataType:STRING OR TRIM(poRequest:GetCharacter("descricao"))="" OR LENGTH(poRequest:GetCharacter("descricao"))>8000 THEN UNDO, THROW NEW Progress.Lang.AppError("Descricao invalida.",1).
 END.
 failureCode="VERSION_CONFIGURATION".
 IF VALID-OBJECT(poPolicy) THEN IF poPolicy:Has("enable_distribution") THEN DO:
  IF poPolicy:GetType("enable_distribution")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao privada exige booleano explicito.",1).
  enableDistribution=poPolicy:GetLogical("enable_distribution").
 END.
 /* Private policy, never accepted in poRequest. Only selected readonly snapshots
    may omit the master existence read; writers/list/default retain their contract. */
 IF VALID-OBJECT(poPolicy) THEN IF poPolicy:Has("read_require_master") THEN DO:
  IF operationValue<>"consultar" OR poPolicy:GetType("read_require_master")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Politica privada de leitura invalida.",1).
  readRequireMaster=poPolicy:GetLogical("read_require_master").
  IF NOT readRequireMaster AND versionId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Leitura sem mestre exige versao especifica.",1).
 END.
 IF NOT VALID-HANDLE(phMaster) OR NOT VALID-HANDLE(phTypes) OR NOT VALID-HANDLE(phVersions) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffers fixos indisponiveis.",1).
 DO i=1 TO 5: IF NOT VALID-HANDLE(children[i]) THEN UNDO, THROW NEW Progress.Lang.AppError("Filho fixo indisponivel.",1). END.
 IF operationValue="consultar" THEN DO:
  readStarted=ETIME.
  failureCode="VERSION_CONFIGURATION".
  /* Trusted private policy may only lower the ceiling; HTTP never supplies it. */
  IF VALID-OBJECT(poPolicy) THEN IF poPolicy:Has("read_max_rows") THEN DO:
   IF poPolicy:GetType("read_max_rows")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Orcamento privado invalido.",1).
   IF poPolicy:GetDecimal("read_max_rows")<1 OR poPolicy:GetDecimal("read_max_rows")>50000 OR poPolicy:GetDecimal("read_max_rows")<>TRUNCATE(poPolicy:GetDecimal("read_max_rows"),0) THEN UNDO, THROW NEW Progress.Lang.AppError("Orcamento privado invalido.",1).
   readMaxRows=poPolicy:GetInteger("read_max_rows").
  END.
  DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  failureCode="VERSION_NOT_FOUND".
  IF readRequireMaster THEN
   IF NOT phMaster:FIND-FIRST("WHERE " + phMaster:NAME + ".nr-container=" + STRING(containerId),NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1).
  poResponse=NEW JsonObject().
  IF versionId>0 THEN DO:
   RUN FindVersion(NO-LOCK).
   RUN CheckReadBudget.
   poResponse:Add("data",JsonRecord(phVersions,versionFields)).
   RUN CaptureSnapshot(OUTPUT snapshotValue). poResponse:Add("snapshot",snapshotValue).
  END.
  ELSE DO: RUN VersionRows(OUTPUT rowsValue). poResponse:Add("data",rowsValue). END.
  readComplete=TRUE.
  END.
  IF NOT readComplete THEN DO: failureCode="VERSION_READ_TIMEOUT". UNDO, THROW NEW Progress.Lang.AppError("Consulta historica excedeu 10 segundos.",1). END.
  poResponse:Add("success",TRUE). RETURN.
 END.
 failureCode="VERSION_TRANSACTION_CONTEXT".
 nestedValue=TRANSACTION.
 IF VALID-OBJECT(poPolicy) THEN IF poPolicy:Has("allow_nested") THEN DO:
  IF poPolicy:GetType("allow_nested")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao privada exige booleano explicito.",1).
  allowNested=poPolicy:GetLogical("allow_nested").
 END.
 IF nestedValue AND NOT allowNested THEN UNDO, THROW NEW Progress.Lang.AppError("Versoes exigem transacao raiz propria ou composicao privada explicita.",1).
 failureCode="VERSION_IDENTITY_REQUIRED".
 IF NOT VALID-OBJECT(poPolicy) THEN UNDO, THROW NEW Progress.Lang.AppError("Ator autenticado necessario.",1).
 IF NOT poPolicy:Has("actor") OR poPolicy:GetType("actor")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Ator autenticado necessario.",1).
 actorValue=poPolicy:GetJsonObject("actor").
 RUN Closed(actorValue,"login,id").
 IF NOT actorValue:Has("login") OR actorValue:GetType("login")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado necessario.",1).
 loginValue=actorValue:GetCharacter("login").
 IF TRIM(loginValue)="" OR LENGTH(loginValue)>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Login autenticado invalido.",1).
 IF actorValue:Has("id") AND (actorValue:GetType("id")<>JsonDataType:STRING OR LENGTH(actorValue:GetCharacter("id"))>128) THEN UNDO, THROW NEW Progress.Lang.AppError("Identidade opaca invalida.",1).
 failureCode="VERSION_CALLBACK_UNAVAILABLE".
 IF operationValue="gerar" THEN DO:
  IF NOT VALID-HANDLE(phRuntime) THEN UNDO, THROW NEW Progress.Lang.AppError("Provider confiavel ausente.",1).
  DO i=1 TO 4:
   IF LOOKUP(ENTRY(i,"NextVersionId,NextVersionItemId,PrepareVersionFiscal,CollectVersionSnapshot"),phRuntime:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Callback confiavel ausente.",1).
  END.
 END.
 DO TRANSACTION ON ERROR UNDO, THROW:
  childEvents=NEW JsonArray().
  failureCode="VERSION_BUSY".
  foundValue=phMaster:FIND-FIRST("WHERE " + phMaster:NAME + ".nr-container=" + STRING(containerId),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  IF phMaster:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError("Container em uso.",1).
  IF NOT foundValue THEN DO: failureCode="VERSION_NOT_FOUND". UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1). END.
  masterBefore=MasterRecord().
  RUN LatestVersion(OUTPUT latestId).
  failureCode="VERSION_CONFLICT".
  IF latestId<>expectedId THEN UNDO, THROW NEW Progress.Lang.AppError("A ultima versao mudou; consulte antes de repetir.",1).
  IF operationValue="gerar" THEN DO:
   failureCode="VERSION_TYPE_NOT_FOUND".
   IF NOT phTypes:FIND-FIRST("WHERE " + phTypes:NAME + ".tipo_versao_custo_id=" + STRING(typeId),SHARE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de versao inexistente.",1).
   failureCode="VERSION_CALLBACK_FAILED".
   RUN PrepareVersionFiscal IN phRuntime(phMaster,OUTPUT fiscalValue).
   RUN ValidateFiscal.
   RUN CollectVersionSnapshot IN phRuntime(phMaster,OUTPUT collectedValue).
   failureCode="VERSION_SNAPSHOT_INVALID". RUN ValidateCollected.
   failureCode="VERSION_SEQUENCE_INVALID".
   RUN NextVersionId IN phRuntime(OUTPUT versionId).
   IF versionId=? OR versionId<1 THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia de versao invalida.",1).
   failureCode="VERSION_PERSISTENCE_REJECTED".
   IF NOT phVersions:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Nao foi possivel criar versao.",1).
   phVersions:BUFFER-FIELD("versao_id"):BUFFER-VALUE=versionId.
   phVersions:BUFFER-FIELD("container_id"):BUFFER-VALUE=containerId.
   phVersions:BUFFER-FIELD("tipo_versao_id"):BUFFER-VALUE=typeId.
   phVersions:BUFFER-FIELD("descricao"):BUFFER-VALUE=poRequest:GetCharacter("descricao").
   phVersions:BUFFER-FIELD("dt_hr_versao"):BUFFER-VALUE=NOW.
   phVersions:BUFFER-FIELD("cod_usuario"):BUFFER-VALUE=loginValue.
   phVersions:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=1.
   RUN AssignRow(phVersions,collectedValue:GetJsonObject("header"),headerFields).
   RUN AssignField(phVersions,costValue:GetJsonObject("master_average"),"dolar_medio","vl_dolar_medio").
   itemMappings=NEW JsonArray().
   DO i=1 TO realRows:Length:
    RUN PersistItem(i).
    mappedValue=NEW JsonObject(). mappedValue:Add("item_container_id",realRows:GetJsonObject(i):GetInteger("item_container_id")). mappedValue:Add("item_container_custo_id",newItemId). itemMappings:Add(mappedValue).
   END.
   DO i=2 TO 5:
    rowsValue=collectedValue:GetJsonArray(ENTRY(i,"items,expenses,nfs,payments,discounts")).
    DO j=1 TO rowsValue:Length:
     IF NOT children[i]:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Filho recusado.",1).
     children[i]:BUFFER-FIELD("versao_id"):BUFFER-VALUE=versionId.
     RUN AssignRow(children[i],rowsValue:GetJsonObject(j),childFields[i]).
     IF NOT children[i]:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot de filho recusado.",1).
     RUN ChildEvent(children[i],i,"create").
     children[i]:BUFFER-RELEASE().
    END.
   END.
   phVersions:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=2.
   IF NOT phVersions:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Versao completa recusada.",1).
   IF headerValue:GetLogical("log_gerar_distr_custo") THEN DO:
    failureCode="VERSION_DISTRIBUTION_FAILED".
    RUN ApplyVersionDistribution IN phRuntime(phMaster,versionId,itemMappings,collectedValue,OUTPUT distributionValue).
    RUN ValidateDistribution.
    /* Nested follow-up may reposition all shared buffers. Reacquire own row. */
    RUN FindVersion(EXCLUSIVE-LOCK).
    IF NOT phMaster:FIND-FIRST("WHERE " + phMaster:NAME + ".nr-container=" + STRING(containerId),EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("Mestre indisponivel apos distribuicao.",1).
   END.
   phMaster:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=FALSE.
   IF NOT phMaster:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Cabecalho recusado.",1).
   beforeValue=NEW JsonObject(). afterValue=JsonRecord(phVersions,versionFields).
   RUN CaptureSnapshot(OUTPUT snapshotValue).
  END.
  ELSE DO:
   failureCode="VERSION_NOT_FOUND". RUN FindVersion(EXCLUSIVE-LOCK).
   failureCode="VERSION_COMPLETE".
   IF phVersions:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE<>1 THEN UNDO, THROW NEW Progress.Lang.AppError("Somente versao incompleta pode ser excluida.",1).
   beforeValue=JsonRecord(phVersions,versionFields).
   RUN CaptureSnapshot(OUTPUT snapshotValue).
   failureCode="VERSION_PERSISTENCE_REJECTED".
   DO i=1 TO 5: RUN DeleteChildren(children[i],i=1). END.
   IF NOT phVersions:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao de versao recusada.",1).
   afterValue=NEW JsonObject().
  END.
  masterAfter=MasterRecord().
 END.
 /* Nested objects remain private pending effects. Only the ancestor can commit. */
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("committed",NOT nestedValue). poResponse:Add("data",afterValue). poResponse:Add("snapshot",snapshotValue).
 IF VALID-OBJECT(distributionValue) THEN poResponse:Add("distribution",CAST(distributionValue:Clone(),JsonObject)).
 masterEvent=NEW JsonObject(). masterEvent:Add("before",masterBefore). masterEvent:Add("after",masterAfter).
 IF nestedValue THEN DO:
  RUN PendingEvents(OUTPUT pendingChanges).
  poResponse:Add("pendingChanges",pendingChanges). poResponse:Add("pendingMaster",masterEvent).
  IF operationValue="gerar" THEN poResponse:Add("warnings",CAST(fiscalValue:GetJsonArray("warnings"):Clone(),JsonArray)).
  RETURN.
 END.
 /* Only a root commit exposes a confirmed audit, including the changed master. */
 auditValue=NEW JsonObject(). auditValue:Add("version",1). auditValue:Add("source","progress-transaction"). auditValue:Add("resource","container_versions").
 auditValue:Add("operation",operationValue). auditValue:Add("recordId",versionId). auditValue:Add("container_id",containerId).
 auditValue:Add("before",beforeValue). auditValue:Add("after",CAST(afterValue:Clone(),JsonObject)). auditValue:Add("actor",CAST(actorValue:Clone(),JsonObject)).
 auditValue:Add("master",masterEvent).
 IF poRequest:Has("request_id") THEN auditValue:Add("request_id",poRequest:GetCharacter("request_id")).
 IF operationValue="gerar" THEN DO:
  RUN PendingEvents(OUTPUT rowsValue).
  auditValue:Add("changes",rowsValue). auditValue:Add("warnings",fiscalValue:GetJsonArray("warnings")).
  mappedValue=NEW JsonObject(). mappedValue:Add("actual_complete",actualComplete). mappedValue:Add("source","container-version-cost-snapshot").
  mappedValue:Add("provenance",CAST(costValue:GetJsonObject("calculation"):Clone(),JsonObject)). poResponse:Add("calculation",mappedValue).
 END.
 ELSE DO: RUN PendingEvents(OUTPUT rowsValue). auditValue:Add("changes",rowsValue). auditValue:Add("warnings",NEW JsonArray()). END.
 poResponse:Add("audit",auditValue).
 CATCH e AS Progress.Lang.Error:
  RUN Fail(failureCode,e:GetMessage(1)).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(phMaster) THEN phMaster:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phTypes) THEN phTypes:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phVersions) THEN phVersions:BUFFER-RELEASE() NO-ERROR.
  DO i=1 TO 5: IF VALID-HANDLE(children[i]) THEN children[i]:BUFFER-RELEASE() NO-ERROR. END.
 END FINALLY.
END.

PROCEDURE PendingEvents:
 DEFINE OUTPUT PARAMETER resultValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 IF operationValue="gerar" THEN resultValue=CAST(fiscalValue:GetJsonArray("changes"):Clone(),JsonArray).
 ELSE resultValue=NEW JsonArray().
 eventValue=NEW JsonObject(). eventValue:Add("resource","container_versions"). eventValue:Add("operation",IF operationValue="gerar" THEN "create" ELSE "delete").
 eventValue:Add("recordId",versionId). eventValue:Add("before",CAST(beforeValue:Clone(),JsonObject)). eventValue:Add("after",CAST(afterValue:Clone(),JsonObject)). resultValue:Add(eventValue).
 IF VALID-OBJECT(childEvents) THEN DO i=1 TO childEvents:Length: resultValue:Add(CAST(childEvents:GetJsonObject(i):Clone(),JsonObject)). END.
 IF VALID-OBJECT(distributionChanges) THEN DO i=1 TO distributionChanges:Length: resultValue:Add(CAST(distributionChanges:GetJsonObject(i):Clone(),JsonObject)). END.
 IF masterBefore:GetJsonText()<>masterAfter:GetJsonText() THEN DO:
  eventValue=NEW JsonObject(). eventValue:Add("resource","containers"). eventValue:Add("operation","update"). eventValue:Add("recordId",containerId).
  eventValue:Add("before",CAST(masterBefore:Clone(),JsonObject)). eventValue:Add("after",CAST(masterAfter:Clone(),JsonObject)). resultValue:Add(eventValue).
 END.
END PROCEDURE.
PROCEDURE ChildEvent:
 DEFINE INPUT PARAMETER bufferValue AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER tableNo AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER actionValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE keyValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE fieldList AS CHARACTER NO-UNDO.
 DEFINE VARIABLE keyFields AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DO n=1 TO bufferValue:NUM-FIELDS: fieldList=fieldList + (IF n=1 THEN "" ELSE ",") + bufferValue:BUFFER-FIELD(n):NAME. END.
 rowValue=JsonRecord(bufferValue,fieldList). rowValue:Add("container_id",containerId).
 eventValue=NEW JsonObject(). eventValue:Add("resource",ENTRY(tableNo,"item_container_custos,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos")).
 eventValue:Add("operation",actionValue).
 IF tableNo=1 THEN eventValue:Add("recordId",rowValue:GetInteger("item_container_custo_id")).
 ELSE DO:
  keyValue=NEW JsonArray(). keyValue:Add(versionId).
  keyFields=IF tableNo=2 THEN "despesa_id" ELSE IF tableNo=3 THEN "documento,serie,estab,nat_operacao,cod_emitente" ELSE IF tableNo=4 THEN "num_id_tit_ap" ELSE "desconto_importacao_id".
  DO n=1 TO NUM-ENTRIES(keyFields):
   IF rowValue:GetType(ENTRY(n,keyFields))=JsonDataType:NUMBER THEN keyValue:Add(rowValue:GetInteger(ENTRY(n,keyFields))).
   ELSE keyValue:Add(rowValue:GetCharacter(ENTRY(n,keyFields))).
  END.
  eventValue:Add("recordId",STRING(keyValue:GetJsonText())). DELETE OBJECT keyValue.
 END.
 eventValue:Add("before",IF actionValue="delete" THEN rowValue ELSE NEW JsonObject()).
 eventValue:Add("after",IF actionValue="create" THEN rowValue ELSE NEW JsonObject()). childEvents:Add(eventValue).
END PROCEDURE.
PROCEDURE ValidateDistribution:
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(distributionValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao sem retorno.",1).
 IF distributionValue:GetType("success")<>JsonDataType:BOOLEAN OR distributionValue:GetLogical("success")<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao nao confirmada.",1).
 IF distributionValue:Has("audit") OR NOT distributionValue:Has("committed") THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao deve retornar somente efeitos pendentes.",1).
 IF distributionValue:GetType("committed")<>JsonDataType:BOOLEAN OR distributionValue:GetLogical("committed")<>FALSE THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao nao pode confirmar commit.",1).
 distributionChanges=distributionValue:GetJsonArray("pendingChanges").
 DO n=1 TO distributionChanges:Length:
  rowValue=distributionChanges:GetJsonObject(n). RUN Closed(rowValue,"resource,operation,recordId,before,after").
  IF rowValue:GetType("resource")<>JsonDataType:STRING OR rowValue:GetType("operation")<>JsonDataType:STRING OR (rowValue:GetType("recordId")<>JsonDataType:NUMBER AND rowValue:GetType("recordId")<>JsonDataType:STRING) OR rowValue:GetType("before")<>JsonDataType:OBJECT OR rowValue:GetType("after")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Efeito pendente invalido.",1).
 END.
END PROCEDURE.

PROCEDURE Closed:
 DEFINE INPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER allowedValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE propertyNames AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE positionValue AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(objectValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto obrigatorio.",1).
 propertyNames=objectValue:GetNames().
 DO positionValue=1 TO EXTENT(propertyNames): IF NOT Exact(propertyNames[positionValue],allowedValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao permitido: " + propertyNames[positionValue],1). END.
END PROCEDURE.
PROCEDURE AssignField:
 DEFINE INPUT PARAMETER bufferValue AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER sourceName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER targetName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
 DEFINE VARIABLE amountValue AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE textValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE dateValue AS DATE NO-UNDO.
 IF NOT objectValue:Has(sourceName) THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot sem campo necessario: " + sourceName,1).
 fieldValue=bufferValue:BUFFER-FIELD(targetName).
 IF objectValue:IsNull(sourceName) THEN DO: fieldValue:BUFFER-VALUE=?. RETURN. END.
 CASE fieldValue:DATA-TYPE:
  WHEN "CHARACTER" THEN DO:
   IF objectValue:GetType(sourceName)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Texto de snapshot invalido.",1).
   fieldValue:BUFFER-VALUE=objectValue:GetCharacter(sourceName).
  END.
  WHEN "INTEGER" THEN DO:
   IF objectValue:GetType(sourceName)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro JSON necessario.",1).
   amountValue=objectValue:GetDecimal(sourceName).
   IF amountValue<>TRUNCATE(amountValue,0) OR amountValue < -2147483648 OR amountValue>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro de snapshot invalido.",1).
   fieldValue:BUFFER-VALUE=INTEGER(amountValue).
  END.
  WHEN "DECIMAL" THEN DO:
   IF objectValue:GetType(sourceName)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Decimal JSON necessario.",1).
   fieldValue:BUFFER-VALUE=objectValue:GetDecimal(sourceName).
  END.
  WHEN "LOGICAL" THEN DO:
   IF objectValue:GetType(sourceName)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON necessario.",1).
   fieldValue:BUFFER-VALUE=objectValue:GetLogical(sourceName).
  END.
  WHEN "DATE" THEN DO:
   IF objectValue:GetType(sourceName)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Data ISO necessaria.",1).
   textValue=objectValue:GetCharacter(sourceName).
   IF LENGTH(textValue)<>10 OR SUBSTRING(textValue,5,1)<>"-" OR SUBSTRING(textValue,8,1)<>"-" THEN UNDO, THROW NEW Progress.Lang.AppError("Data ISO invalida.",1).
   dateValue=DATE(INTEGER(SUBSTRING(textValue,6,2)),INTEGER(SUBSTRING(textValue,9,2)),INTEGER(SUBSTRING(textValue,1,4))) NO-ERROR.
   IF ERROR-STATUS:ERROR OR dateValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("Data inexistente.",1).
   fieldValue:BUFFER-VALUE=dateValue.
  END.
  OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo fisico nao suportado.",1).
 END CASE.
END PROCEDURE.
PROCEDURE AssignRow:
 DEFINE INPUT PARAMETER bufferValue AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER allowedValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fieldNo AS INTEGER NO-UNDO.
 RUN Closed(objectValue,allowedValue).
 DO fieldNo=1 TO NUM-ENTRIES(allowedValue): RUN AssignField(bufferValue,objectValue,ENTRY(fieldNo,allowedValue),ENTRY(fieldNo,allowedValue)). END.
END PROCEDURE.
PROCEDURE LatestVersion:
 DEFINE OUTPUT PARAMETER resultValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY queryValue. queryValue:SET-BUFFERS(phVersions).
  queryValue:QUERY-PREPARE("FOR EACH " + phVersions:NAME + " NO-LOCK WHERE " + phVersions:NAME + ".container_id=" + STRING(containerId)).
  queryValue:QUERY-OPEN(). queryValue:GET-FIRST().
  DO WHILE NOT queryValue:QUERY-OFF-END:
   resultValue=MAXIMUM(resultValue,INTEGER(phVersions:BUFFER-FIELD("versao_id"):BUFFER-VALUE)). queryValue:GET-NEXT().
  END.
  FINALLY: IF VALID-HANDLE(queryValue) THEN DO: queryValue:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryValue NO-ERROR. END. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE FindVersion:
 DEFINE INPUT PARAMETER lockValue AS INTEGER NO-UNDO.
 IF NOT phVersions:FIND-FIRST("WHERE " + phVersions:NAME + ".versao_id=" + STRING(versionId) + " AND " + phVersions:NAME + ".container_id=" + STRING(containerId),lockValue,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("Versao nao encontrada no container.",1).
END PROCEDURE.
PROCEDURE VersionRows:
 DEFINE OUTPUT PARAMETER resultValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
 resultValue=NEW JsonArray().
 DO ON ERROR UNDO, THROW:
  CREATE QUERY queryValue. queryValue:SET-BUFFERS(phVersions).
  queryValue:QUERY-PREPARE("FOR EACH " + phVersions:NAME + " NO-LOCK WHERE " + phVersions:NAME + ".container_id=" + STRING(containerId)).
  queryValue:QUERY-OPEN(). queryValue:GET-FIRST().
  DO WHILE NOT queryValue:QUERY-OFF-END: RUN CheckReadBudget. resultValue:Add(JsonRecord(phVersions,versionFields)). queryValue:GET-NEXT(). END.
  FINALLY: IF VALID-HANDLE(queryValue) THEN DO: queryValue:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryValue NO-ERROR. END. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE CheckReadBudget:
 /* CaptureSnapshot is also used by writers: their path is unchanged. */
 IF NOT Exact(operationValue,"consultar") THEN RETURN.
 readRows=readRows + 1.
 IF readRows>readMaxRows THEN DO: failureCode="VERSION_READ_LIMIT". UNDO, THROW NEW Progress.Lang.AppError("Consulta historica excedeu orcamento de registros.",1). END.
 IF ETIME - readStarted>10000 THEN DO: failureCode="VERSION_READ_TIMEOUT". UNDO, THROW NEW Progress.Lang.AppError("Consulta historica excedeu 10 segundos.",1). END.
END PROCEDURE.
PROCEDURE ChildRows:
 DEFINE INPUT PARAMETER bufferValue AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER fieldsValue AS CHARACTER NO-UNDO.
 DEFINE OUTPUT PARAMETER resultValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
 resultValue=NEW JsonArray().
 DO ON ERROR UNDO, THROW:
  CREATE QUERY queryValue. queryValue:SET-BUFFERS(bufferValue).
  queryValue:QUERY-PREPARE("FOR EACH " + bufferValue:NAME + " NO-LOCK WHERE " + bufferValue:NAME + ".versao_id=" + STRING(versionId)).
  queryValue:QUERY-OPEN(). queryValue:GET-FIRST().
  DO WHILE NOT queryValue:QUERY-OFF-END: RUN CheckReadBudget. resultValue:Add(JsonRecord(bufferValue,fieldsValue)). queryValue:GET-NEXT(). END.
  FINALLY: IF VALID-HANDLE(queryValue) THEN DO: queryValue:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryValue NO-ERROR. END. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE CaptureSnapshot:
 DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE tableNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE arrayValue AS JsonArray NO-UNDO.
 resultValue=NEW JsonObject(). resultValue:Add("header",JsonRecord(phVersions,versionFields)).
 DO tableNo=1 TO 5:
  RUN ChildRows(children[tableNo],IF tableNo=1 THEN itemFields + (IF Exact(operationValue,"consultar") THEN ",qt_embarcada,vl_desconto_utiliz_real" ELSE "") ELSE "versao_id," + childFields[tableNo],OUTPUT arrayValue).
  resultValue:Add(ENTRY(tableNo,"items,expenses,nfs,payments,discounts"),arrayValue).
 END.
END PROCEDURE.
PROCEDURE DeleteChildren:
 DEFINE INPUT PARAMETER bufferValue AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER itemTable AS LOGICAL NO-UNDO.
 DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
 DEFINE VARIABLE usedId AS INTEGER NO-UNDO.
 DO ON ERROR UNDO, THROW:
  CREATE QUERY queryValue. queryValue:SET-BUFFERS(bufferValue).
  queryValue:QUERY-PREPARE("FOR EACH " + bufferValue:NAME + " WHERE " + bufferValue:NAME + ".versao_id=" + STRING(versionId)).
  queryValue:QUERY-OPEN(). queryValue:GET-FIRST(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  DO WHILE NOT queryValue:QUERY-OFF-END:
   IF bufferValue:LOCKED OR NOT bufferValue:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("Filho em uso.",1).
   IF itemTable THEN DO:
    usedId=bufferValue:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE.
    IF usedId=? OR usedId<>0 THEN DO: failureCode="VERSION_USED". UNDO, THROW NEW Progress.Lang.AppError("Versao utilizada ou sem confirmacao de nao utilizacao.",1). END.
   END.
   RUN ChildEvent(bufferValue,IF itemTable THEN 1 ELSE i,"delete").
   IF NOT bufferValue:BUFFER-DELETE() THEN UNDO, THROW NEW Progress.Lang.AppError("Exclusao de filho recusada.",1).
   queryValue:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  END.
  FINALLY: IF VALID-HANDLE(queryValue) THEN DO: queryValue:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryValue NO-ERROR. END. END FINALLY.
 END.
END PROCEDURE.
PROCEDURE ValidateFiscal:
 DEFINE VARIABLE indexValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE changeValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
 IF NOT VALID-OBJECT(fiscalValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal sem resposta.",1).
 IF NOT fiscalValue:Has("success") OR fiscalValue:GetType("success")<>JsonDataType:BOOLEAN OR NOT fiscalValue:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal nao confirmou operacao.",1).
 IF NOT fiscalValue:Has("changes") OR NOT fiscalValue:Has("warnings") THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal sem auditoria interna.",1).
 IF fiscalValue:GetType("changes")<>JsonDataType:ARRAY OR fiscalValue:GetType("warnings")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Auditoria fiscal invalida.",1).
 IF fiscalValue:GetJsonArray("changes"):Length>50000 OR fiscalValue:GetJsonArray("warnings"):Length>1000 THEN UNDO, THROW NEW Progress.Lang.AppError("Auditoria fiscal excede limite.",1).
 DO indexValue=1 TO fiscalValue:GetJsonArray("changes"):Length:
  IF fiscalValue:GetJsonArray("changes"):GetType(indexValue)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Mudanca fiscal invalida.",1).
  changeValue=fiscalValue:GetJsonArray("changes"):GetJsonObject(indexValue).
  RUN Closed(changeValue,"resource,operation,recordId,before,after").
  DO fieldNo=1 TO 5:
   fieldName=ENTRY(fieldNo,"resource,operation,recordId,before,after").
   IF NOT changeValue:Has(fieldName) THEN UNDO, THROW NEW Progress.Lang.AppError("Mudanca fiscal incompleta.",1).
  END.
  IF changeValue:GetType("resource")<>JsonDataType:STRING OR TRIM(changeValue:GetCharacter("resource"))="" OR LENGTH(changeValue:GetCharacter("resource"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso de auditoria invalido.",1).
  IF changeValue:GetType("operation")<>JsonDataType:STRING OR NOT Exact(changeValue:GetCharacter("operation"),"create,update,delete") THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao de auditoria invalida.",1).
  IF changeValue:GetType("recordId")=JsonDataType:NUMBER THEN DO:
   IF Key(changeValue,"recordId",FALSE)=? THEN UNDO, THROW NEW Progress.Lang.AppError("ID de auditoria invalido.",1).
  END.
  ELSE IF changeValue:GetType("recordId")=JsonDataType:STRING THEN DO:
   IF TRIM(changeValue:GetCharacter("recordId"))="" OR LENGTH(changeValue:GetCharacter("recordId"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("ID opaco de auditoria invalido.",1).
  END.
  ELSE UNDO, THROW NEW Progress.Lang.AppError("ID de auditoria invalido.",1).
  IF changeValue:GetType("before")<>JsonDataType:OBJECT OR changeValue:GetType("after")<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot fiscal invalido.",1).
 END.
 DO indexValue=1 TO fiscalValue:GetJsonArray("warnings"):Length:
  IF fiscalValue:GetJsonArray("warnings"):GetType(indexValue)<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Aviso fiscal invalido.",1).
  IF LENGTH(fiscalValue:GetJsonArray("warnings"):GetCharacter(indexValue))>4000 THEN UNDO, THROW NEW Progress.Lang.AppError("Aviso fiscal excede limite.",1).
 END.
END PROCEDURE.
PROCEDURE ValidateCollected:
 DEFINE VARIABLE arrayNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE rowNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE arrayValue AS JsonArray NO-UNDO.
 RUN Closed(collectedValue,"confirmed,container_id,actual_complete,cost,header,expenses,nfs,payments,discounts").
 IF collectedValue:GetType("confirmed")<>JsonDataType:BOOLEAN OR collectedValue:GetType("actual_complete")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Confirmacao e completude devem ser booleanas.",1).
 IF NOT collectedValue:GetLogical("confirmed") OR Key(collectedValue,"container_id",FALSE)<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot nao confirmado para este container.",1).
 actualComplete=collectedValue:GetLogical("actual_complete"). costValue=collectedValue:GetJsonObject("cost").
 IF costValue:GetType("confirmed")<>JsonDataType:BOOLEAN OR costValue:GetType("actual_complete")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Confirmacao do calculo deve ser booleana.",1).
 IF NOT costValue:GetLogical("confirmed") OR Key(costValue,"container_id",FALSE)<>containerId OR costValue:GetCharacter("source")<>"container-version-cost-snapshot" OR costValue:GetCharacter("calculation_profile")<>"version" OR costValue:GetLogical("actual_complete")<>actualComplete THEN UNDO, THROW NEW Progress.Lang.AppError("Calculo central de versao invalido.",1).
 headerValue=collectedValue:GetJsonObject("header"). RUN Closed(headerValue,headerFields).
 IF headerValue:GetType("log_gerar_distr_custo")<>JsonDataType:BOOLEAN OR headerValue:GetType("log_gerar_saldo_a_pagar")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Flags de versao devem ser booleanas conhecidas.",1).
 IF headerValue:GetLogical("log_gerar_distr_custo") THEN DO:
  failureCode="VERSION_DISTRIBUTION_UNSUPPORTED".
  IF NOT enableDistribution THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao exige opt-in privado.",1).
  IF LOOKUP("GetStatus",phRuntime:INTERNAL-ENTRIES)=0 OR LOOKUP("ApplyVersionDistribution",phRuntime:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Distribuicao exige provider central.",1).
  RUN GetStatus IN phRuntime(OUTPUT runtimeStatus).
  IF NOT VALID-OBJECT(runtimeStatus) THEN UNDO, THROW NEW Progress.Lang.AppError("Provider de distribuicao nao confirmado.",1).
  IF runtimeStatus:GetType("confirmed")<>JsonDataType:BOOLEAN OR runtimeStatus:GetType("distribution_enabled")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Capacidade privada invalida.",1).
  IF NOT runtimeStatus:GetLogical("confirmed") OR NOT runtimeStatus:GetLogical("distribution_enabled") THEN UNDO, THROW NEW Progress.Lang.AppError("Provider de distribuicao nao confirmado.",1).
 END.
 realRows=costValue:GetJsonArray("items_real"). dollarRows=costValue:GetJsonArray("items_dolar"). inputRows=costValue:GetJsonObject("input_snapshot"):GetJsonArray("items").
 IF realRows:Length<1 OR realRows:Length>10000 OR dollarRows:Length<>realRows:Length OR inputRows:Length<>realRows:Length THEN UNDO, THROW NEW Progress.Lang.AppError("Conjunto de itens incompleto.",1).
 DO arrayNo=1 TO 3:
  arrayValue=IF arrayNo=1 THEN realRows ELSE IF arrayNo=2 THEN dollarRows ELSE inputRows.
  DO rowNo=1 TO arrayValue:Length:
   idValue=Key(arrayValue:GetJsonObject(rowNo),"item_container_id",FALSE).
   IF idValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("ID de item invalido.",1).
   FIND ttPair WHERE ttPair.id=idValue NO-ERROR.
   IF NOT AVAILABLE ttPair THEN DO: CREATE ttPair. ttPair.id=idValue. END.
   CASE arrayNo:
    WHEN 1 THEN DO: IF ttPair.brl>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Item real duplicado.",1). ttPair.brl=rowNo. END.
    WHEN 2 THEN DO: IF ttPair.usd>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Item dolar duplicado.",1). ttPair.usd=rowNo. END.
    WHEN 3 THEN DO: IF ttPair.component>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Componente duplicado.",1). ttPair.component=rowNo. END.
   END CASE.
  END.
 END.
 FOR EACH ttPair: IF ttPair.brl=0 OR ttPair.usd=0 OR ttPair.component=0 THEN UNDO, THROW NEW Progress.Lang.AppError("Itens das moedas divergem.",1). END.
 DO arrayNo=1 TO 4:
  arrayValue=collectedValue:GetJsonArray(ENTRY(arrayNo,"expenses,nfs,payments,discounts")).
  IF arrayValue:Length>50000 THEN UNDO, THROW NEW Progress.Lang.AppError("Muitos filhos na versao.",1).
  DO rowNo=1 TO arrayValue:Length:
   mappedValue=arrayValue:GetJsonObject(rowNo). RUN Closed(mappedValue,childFields[arrayNo + 1]).
   IF arrayNo=1 AND Key(mappedValue,"despesa_id",FALSE)=? OR arrayNo=2 AND Key(mappedValue,"cod_emitente",FALSE)=? OR arrayNo=3 AND Key(mappedValue,"num_id_tit_ap",FALSE)=? OR arrayNo=4 AND Key(mappedValue,"desconto_importacao_id",FALSE)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Chave de filho invalida.",1).
  END.
 END.
END PROCEDURE.
PROCEDURE PersistItem:
 DEFINE INPUT PARAMETER rowNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE mapNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE mappingValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fieldList AS CHARACTER NO-UNDO.
 itemValue=realRows:GetJsonObject(rowNo).
 FIND ttPair WHERE ttPair.id=Key(itemValue,"item_container_id",FALSE).
 dollarValue=dollarRows:GetJsonObject(ttPair.usd). inputValue=inputRows:GetJsonObject(ttPair.component).
 RUN NextVersionItemId IN phRuntime(OUTPUT newItemId).
 IF newItemId=? OR newItemId<1 THEN UNDO, THROW NEW Progress.Lang.AppError("Sequencia de item invalida.",1).
 IF NOT phItems:BUFFER-CREATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Criacao de item recusada.",1).
 phItems:BUFFER-FIELD("item_container_custo_id"):BUFFER-VALUE=newItemId. phItems:BUFFER-FIELD("versao_id"):BUFFER-VALUE=versionId.
 phItems:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=ttPair.id. phItems:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE=0.
 RUN AssignField(phItems,itemValue,"codigo_erp","it_codigo").
 fieldList="vl_desp_prev:vl_desp_prev_real,vl_merc_prev:vl_custo_prev_real,vl_merc_real:vl_pago_real,vl_desp_real:vl_desp_realiz_real,vl_unit_prev:vl_unit_prev,vl_unit_real:vl_unit_realiz,vl_desp_prev_sem_distr_custo:vl_desp_prev_real_sem_distr_cust".
 DO mapNo=1 TO NUM-ENTRIES(fieldList): mappingValue=ENTRY(mapNo,fieldList). RUN AssignField(phItems,itemValue,ENTRY(1,mappingValue,":"),ENTRY(2,mappingValue,":")). END.
 fieldList="vl_desp_prev:vl_desp_prev_dolar,vl_merc_prev:vl_custo_prev_dolar,vl_merc_real:vl_pago_dolar,vl_desp_real:vl_desp_realiz_dolar,vl_unit_prev:vl_unit_prev_dolar,vl_unit_real:vl_unit_realiz_dolar,vl_desc_item:vl_desconto_utiliz_dolar,vl_desp_prev_sem_distr_custo:vl_desp_prev_dolar_sem_distr_cus".
 DO mapNo=1 TO NUM-ENTRIES(fieldList): mappingValue=ENTRY(mapNo,fieldList). RUN AssignField(phItems,dollarValue,ENTRY(1,mappingValue,":"),ENTRY(2,mappingValue,":")). END.
 fieldList="qt_alocada:qt_alocada,qt_confirm_emb:qt_confirm_emb,qt_recbto_fisico:qt_recebto_fisico,vl_negociado:vl_negociado".
 DO mapNo=1 TO NUM-ENTRIES(fieldList): mappingValue=ENTRY(mapNo,fieldList). RUN AssignField(phItems,inputValue,ENTRY(1,mappingValue,":"),ENTRY(2,mappingValue,":")). END.
 phItems:BUFFER-FIELD("vl_custo_distribuido"):BUFFER-VALUE=0.
 mappedValue=NEW JsonObject(). mappedValue:Add("source","container-version-cost-snapshot"). mappedValue:Add("actual_complete",actualComplete). mappedValue:Add("real",CAST(itemValue:Clone(),JsonObject)). mappedValue:Add("dolar",CAST(dollarValue:Clone(),JsonObject)).
 mappedValue:Write(memoryText). phItems:BUFFER-FIELD("memoria_calculo"):BUFFER-VALUE=STRING(memoryText).
 IF NOT phItems:BUFFER-VALIDATE() THEN UNDO, THROW NEW Progress.Lang.AppError("Snapshot de item recusado.",1).
 RUN ChildEvent(phItems,1,"create").
 phItems:BUFFER-RELEASE().
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorValue=NEW JsonObject().
 errorValue:Add("code",codeValue). errorValue:Add("message",messageValue).
 errorValue:Add("status",IF codeValue="VERSION_NOT_FOUND" OR codeValue="VERSION_TYPE_NOT_FOUND" THEN 404 ELSE IF Exact(codeValue,"VERSION_BUSY,VERSION_CONFLICT,VERSION_COMPLETE,VERSION_USED,VERSION_PERSISTENCE_REJECTED") THEN 409 ELSE IF Exact(codeValue,"VERSION_CONFIGURATION,VERSION_CALLBACK_UNAVAILABLE,VERSION_DISTRIBUTION_UNSUPPORTED,VERSION_READ_LIMIT,VERSION_READ_TIMEOUT") THEN 503 ELSE 422).
 poResponse:Add("success",FALSE). poResponse:Add("error",errorValue).
END PROCEDURE.
