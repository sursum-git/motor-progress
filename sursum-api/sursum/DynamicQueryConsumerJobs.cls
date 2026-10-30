USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Only the MED secured wrapper invokes this consumer-specific queue. No tokens are persisted. */
CLASS DynamicQueryConsumerJobs:
 METHOD PUBLIC LOGICAL isJobId(INPUT idValue AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF idValue=? OR LENGTH(idValue)<>26 THEN RETURN FALSE.
  IF NOT COMPARE(SUBSTRING(idValue,1,4),'EQ','JOB-','RAW') OR SUBSTRING(idValue,13,1)<>'-' OR SUBSTRING(idValue,20,1)<>'-' THEN RETURN FALSE.
  DO n=5 TO 26:
   IF n=13 OR n=20 THEN NEXT.
   IF INDEX('0123456789',SUBSTRING(idValue,n,1))=0 THEN RETURN FALSE.
  END.
  RETURN TRUE.
 END METHOD.
 METHOD PUBLIC LOGICAL canAccess(INPUT configValue AS JsonObject,INPUT consumerValue AS CHARACTER,INPUT codeValue AS CHARACTER,INPUT nowValue AS INT64):
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE queries AS JsonArray NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE j AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   entries=configValue:GetJsonArray('consumers').
   DO n=1 TO entries:Length:
    entryValue=entries:GetJsonObject(n).
    IF NOT COMPARE(entryValue:GetCharacter('id'),'EQ',consumerValue,'RAW') THEN NEXT.
    IF entryValue:GetCharacter('role')<>'consumer' OR NOT entryValue:GetLogical('active') OR entryValue:GetInt64('expiresAtEpoch')<=nowValue THEN RETURN FALSE.
    queries=entryValue:GetJsonArray('queries').
    DO j=1 TO queries:Length: IF COMPARE(queries:GetCharacter(j),'EQ',codeValue,'RAW') THEN RETURN TRUE. END.
   END.
   RETURN FALSE.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject failure(INPUT codeValue AS CHARACTER, INPUT statusValue AS INTEGER):
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
  resultValue=NEW JsonObject(). errorValue=NEW JsonObject(). resultValue:Add('success',FALSE).
  errorValue:Add('code',codeValue). errorValue:Add('status',statusValue).
  errorValue:Add('message',IF statusValue=404 THEN 'Job nao encontrado.' ELSE IF statusValue=403 THEN 'Consulta sem permissao.' ELSE IF statusValue=409 THEN 'Resultado ainda nao disponivel.' ELSE IF statusValue=410 THEN 'Resultado expirado.' ELSE IF statusValue=429 THEN 'Limite de jobs ou armazenamento atingido.' ELSE IF codeValue='ASYNC_QUERY_UNSUPPORTED' THEN 'Consulta com configuracao incompativel com processamento assincrono.' ELSE IF codeValue='ASYNC_PARALLEL_REQUIRES_UNPAGED' THEN 'Processamento paralelo requer paginate=false.' ELSE IF codeValue='PARALLEL_DATE_RANGE_REQUIRED' THEN 'Processamento paralelo requer dataInicial e dataFinal.' ELSE 'Servico de jobs indisponivel.').
  resultValue:Add('error',errorValue). RETURN resultValue.
 END METHOD.
 METHOD PRIVATE CHARACTER jobRoot(INPUT configValue AS JsonObject):
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  pathValue=configValue:GetCharacter('accessTokenStore') + '.jobs'.
  IF pathValue=? OR SUBSTRING(pathValue,1,1)<>'/' OR INDEX(pathValue,'/../')>0 THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_STORAGE_UNAVAILABLE',0).
  FILE-INFO:FILE-NAME=pathValue.
  IF FILE-INFO:FULL-PATHNAME=? OR INDEX(FILE-INFO:FILE-TYPE,'D')=0 THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_STORAGE_UNAVAILABLE',0).
  /* The advisory queue lock is stored below the private job root.  Create it
     before attempting the first enqueue so a freshly provisioned store is
     usable without a manual server-side mkdir. */
  OS-CREATE-DIR VALUE(pathValue + '/queue') NO-ERROR.
  FILE-INFO:FILE-NAME=pathValue + '/queue'.
  IF FILE-INFO:FULL-PATHNAME=? OR INDEX(FILE-INFO:FILE-TYPE,'D')=0 THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_STORAGE_UNAVAILABLE',0).
  RETURN pathValue.
 END METHOD.
 METHOD PUBLIC JsonObject enqueue(INPUT modelValue AS DynamicQueryRequestModel, INPUT bodyValue AS JsonObject, INPUT definitionValue AS JsonObject, INPUT configValue AS JsonObject, INPUT ownerValue AS CHARACTER, INPUT contextValue AS PasoeExecutionContext, INPUT nowValue AS INT64):
  DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO.
  DEFINE VARIABLE serializerValue AS DynamicQueryRequestSerializer NO-UNDO.
  DEFINE VARIABLE quotaValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE modelText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE metadataText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1.
  DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE paginated AS LOGICAL NO-UNDO INITIAL TRUE.
  DEFINE VARIABLE webhookDeliveryValue AS CHARACTER NO-UNDO INITIAL 'full'.
  DEFINE VARIABLE validationValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE serviceValue AS DynamicMultiTableQueryService NO-UNDO.
  DEFINE VARIABLE snapshotValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE stepsValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE postSteps AS JsonArray NO-UNDO.
  DEFINE VARIABLE stepValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parallelConfigValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parallelSnapshotConfigValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parallelStatusValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parametersValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE querystringValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE plannerValue AS DynamicQueryConsumerParallelJobs NO-UNDO.
  DEFINE VARIABLE partitionsValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE reservedIdValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE parallelPlanCreated AS LOGICAL NO-UNDO.
  DEFINE VARIABLE resolvedWorkerLimitValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE parallelStageValue AS CHARACTER NO-UNDO INITIAL 'prepare'.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT THIS-OBJECT:canAccess(configValue,ownerValue,bodyValue:GetCharacter('code'),nowValue) THEN RETURN THIS-OBJECT:failure('QUERY_FORBIDDEN',403).
   serviceValue=NEW DynamicMultiTableQueryService(). validationValue=serviceValue:validateConsumerAsync(modelValue).
   IF NOT validationValue:GetLogical('success') THEN RETURN THIS-OBJECT:failure('JOB_QUERY_INVALID',400).
   pathValue=THIS-OBJECT:jobRoot(configValue) + '/queue'.
   RUN QueryConsumerQueueLock.p('acquire',pathValue,INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock).
   IF NOT ownsLock THEN RETURN THIS-OBJECT:failure('QUEUE_BUSY',409).
   repositoryValue=NEW DynamicQueryConsumerJobRepository(THIS-OBJECT:jobRoot(configValue)). quotaValue=repositoryValue:pendingConsumerJobs(ownerValue).
   IF NOT quotaValue:GetLogical('success') THEN RETURN THIS-OBJECT:failure('QUEUE_UNAVAILABLE',503).
   IF quotaValue:GetInteger('total')>=1000 OR quotaValue:GetInteger('consumer')>=5 OR quotaValue:GetInteger('stored')>=1000 OR quotaValue:GetInt64('bytes') + 131072>1073741824 THEN RETURN THIS-OBJECT:failure('JOB_LIMIT',429).
   serializerValue=NEW DynamicQueryRequestSerializer(). modelValue:setExecution('sync'). FIX-CODEPAGE(modelText)='UTF-8'.
   snapshotValue=serializerValue:toJsonObject(modelValue). stepsValue=snapshotValue:GetJsonArray('pipeline').
   IF definitionValue:Has('pipeline') THEN IF NOT definitionValue:IsNull('pipeline') THEN
    IF definitionValue:GetJsonArray('pipeline'):Length<>stepsValue:Length THEN RETURN THIS-OBJECT:failure('ASYNC_QUERY_UNSUPPORTED',400).
   /* The snapshot already contains materialized sources/joins/filters/order/limits.
      Keep only post-query steps so deserialization cannot materialize them twice. */
   postSteps=NEW JsonArray().
   DO n=1 TO stepsValue:Length:
    stepValue=stepsValue:GetJsonObject(n).
    IF LOOKUP(LC(stepValue:GetCharacter('type')),'source,join,select,filter,sort,limit')>0 THEN NEXT.
    IF LOOKUP(LC(stepValue:GetCharacter('type')),'map,distinct,group,aggregate')=0 THEN RETURN THIS-OBJECT:failure('ASYNC_QUERY_UNSUPPORTED',400).
    postSteps:Add(CAST(stepValue:Clone(),JsonObject)).
   END.
   snapshotValue:Set('pipeline',postSteps). snapshotValue:Write(modelText,FALSE).
   IF LENGTH(modelText,'RAW')>30000 THEN RETURN THIS-OBJECT:failure('JOB_REQUEST_TOO_LARGE',413).
   IF bodyValue:Has('paginate') THEN paginated=bodyValue:GetLogical('paginate').
   IF bodyValue:Has('webhookDelivery') THEN webhookDeliveryValue=bodyValue:GetCharacter('webhookDelivery').
   IF LOOKUP(webhookDeliveryValue,'full,manifest')=0 THEN RETURN THIS-OBJECT:failure('INVALID_WEBHOOK_DELIVERY',400).
   /* Never silently downgrade this export: an unpaged movement request must carry
      the JSON parallel policy, otherwise it could run as a huge serial job. */
   IF bodyValue:GetCharacter('code')='movimentacoes-estoque' AND NOT paginated
    AND (NOT definitionValue:Has('asyncParallel') OR definitionValue:GetType('asyncParallel')<>JsonDataType:OBJECT) THEN
    RETURN THIS-OBJECT:failure('ASYNC_PARALLEL_CONFIG_MISSING',503).
   /* Parallel execution is configured exclusively in the saved-query JSON. It requires
      a full, bounded range because the final artifact is an aggregate, not one page. */
   IF definitionValue:Has('asyncParallel') AND definitionValue:GetType('asyncParallel')=JsonDataType:OBJECT THEN DO:
    parallelConfigValue=definitionValue:GetJsonObject('asyncParallel').
    IF parallelConfigValue:GetLogical('enabled') THEN DO:
     IF paginated THEN RETURN THIS-OBJECT:failure('ASYNC_PARALLEL_REQUIRES_UNPAGED',400).
     plannerValue=NEW DynamicQueryConsumerParallelJobs().
     IF NOT plannerValue:hasSafePartitionLimits(parallelConfigValue) THEN RETURN THIS-OBJECT:failure('PARALLEL_PARTITION_LIMIT_CONFIG_INVALID',503).
     resolvedWorkerLimitValue=plannerValue:currentWorkerLimit(parallelConfigValue).
     IF resolvedWorkerLimitValue=? THEN RETURN THIS-OBJECT:failure('PARALLEL_PARTITION_LIMIT_CONFIG_INVALID',503).
     IF NOT bodyValue:Has('webhookDelivery') THEN webhookDeliveryValue='manifest'.
     IF NOT bodyValue:Has('parameters') OR bodyValue:GetType('parameters')<>JsonDataType:OBJECT THEN RETURN THIS-OBJECT:failure('PARALLEL_DATE_RANGE_REQUIRED',400).
     parametersValue=bodyValue:GetJsonObject('parameters').
     IF NOT parametersValue:Has('querystring') OR parametersValue:GetType('querystring')<>JsonDataType:OBJECT THEN RETURN THIS-OBJECT:failure('PARALLEL_DATE_RANGE_REQUIRED',400).
     querystringValue=parametersValue:GetJsonObject('querystring').
     parallelStageValue='partitions'. partitionsValue=plannerValue:dateDayPartitions(parallelConfigValue,querystringValue).
     parallelStageValue='reserve'. reservedIdValue=repositoryValue:reserveJobId().
     IF reservedIdValue='' THEN RETURN THIS-OBJECT:failure('QUEUE_BUSY',409).
     parallelStageValue='plan-write'.
     IF NOT plannerValue:initializePlan(THIS-OBJECT:jobRoot(configValue),reservedIdValue,partitionsValue,resolvedWorkerLimitValue) THEN RETURN THIS-OBJECT:failure('QUEUE_UNAVAILABLE',503).
     parallelPlanCreated=TRUE.
    END.
   END.
   metadataValue=NEW JsonObject(). metadataValue:Add('kind','consumer-query-v1'). metadataValue:Add('consumerId',ownerValue).
   metadataValue:Add('code',bodyValue:GetCharacter('code')). metadataValue:Add('paginate',paginated).
   metadataValue:Add('createdEpoch',nowValue).
   metadataValue:Add('webhookDelivery',webhookDeliveryValue).
   IF parallelPlanCreated THEN DO:
    parallelStatusValue=NEW JsonObject(). parallelStatusValue:Add('enabled',TRUE).
    parallelStatusValue:Add('totalPartitions',partitionsValue:Length). parallelStatusValue:Add('completedPartitions',0).
    parallelStatusValue:Add('runningPartitions',0). parallelStatusValue:Add('failedPartitions',0).
    parallelStatusValue:Add('maxWorkers',resolvedWorkerLimitValue).
    parallelStatusValue:Add('resultFormat','ndjson+gzip').
    metadataValue:Add('parallel',parallelStatusValue).
    parallelSnapshotConfigValue=CAST(parallelConfigValue:Clone(),JsonObject).
    parallelSnapshotConfigValue:Set('maxWorkers',resolvedWorkerLimitValue).
    metadataValue:Add('parallelConfig',parallelSnapshotConfigValue).
   END.
   metadataValue:Write(metadataText,FALSE).
   parallelStageValue='job-create'.
   IF parallelPlanCreated THEN resultValue=repositoryValue:createJobWithId(reservedIdValue,modelText,metadataText,metadataText,'CONSUMER',3,contextValue:getCustomField('executionId')).
   ELSE resultValue=repositoryValue:createJob(modelText,metadataText,metadataText,'CONSUMER',3,contextValue:getCustomField('executionId')).
   IF NOT resultValue:GetLogical('success') THEN DO:
    IF parallelPlanCreated THEN OS-DELETE VALUE(THIS-OBJECT:jobRoot(configValue) + '/' + reservedIdValue + '.parallel.json') NO-ERROR.
    DELETE OBJECT resultValue. RETURN THIS-OBJECT:failure('QUEUE_UNAVAILABLE',503).
   END.
   RETURN THIS-OBJECT:publicStatus(resultValue,metadataValue).
   CATCH err AS Progress.Lang.Error:
    /* Keep the client response generic, but retain the root exception in the
       MED agent log so operational failures can be diagnosed without exposing
       storage details to a consumer. */
    LOG-MANAGER:WRITE-MESSAGE('Consumer parallel enqueue failed at ' + parallelStageValue + ': ' + err:GetMessage(1)).
    RETURN THIS-OBJECT:failure(IF parallelStageValue='prepare' THEN 'QUEUE_UNAVAILABLE' ELSE 'PARALLEL_' + parallelStageValue,503).
   END CATCH.
   FINALLY:
    IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',pathValue,INPUT-OUTPUT lockDescriptor,OUTPUT released).
    IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue.
    IF VALID-OBJECT(serializerValue) THEN DELETE OBJECT serializerValue.
    IF VALID-OBJECT(quotaValue) THEN DELETE OBJECT quotaValue.
    IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue.
    IF VALID-OBJECT(resultValue) THEN DELETE OBJECT resultValue.
    IF VALID-OBJECT(validationValue) THEN DELETE OBJECT validationValue.
    IF VALID-OBJECT(serviceValue) THEN DELETE OBJECT serviceValue.
    IF VALID-OBJECT(snapshotValue) THEN DELETE OBJECT snapshotValue.
    IF VALID-OBJECT(postSteps) THEN DELETE OBJECT postSteps.
    IF VALID-OBJECT(parallelConfigValue) THEN DELETE OBJECT parallelConfigValue.
    IF VALID-OBJECT(parallelSnapshotConfigValue) THEN DELETE OBJECT parallelSnapshotConfigValue.
    IF VALID-OBJECT(parallelStatusValue) THEN DELETE OBJECT parallelStatusValue.
    IF VALID-OBJECT(parametersValue) THEN DELETE OBJECT parametersValue.
    IF VALID-OBJECT(querystringValue) THEN DELETE OBJECT querystringValue.
    IF VALID-OBJECT(plannerValue) THEN DELETE OBJECT plannerValue.
    IF VALID-OBJECT(partitionsValue) THEN DELETE OBJECT partitionsValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE INTEGER partitionRecordLimit(INPUT metadataValue AS JsonObject):
  DO ON ERROR UNDO, THROW:
   IF NOT VALID-OBJECT(metadataValue) OR NOT metadataValue:Has('parallelConfig') THEN RETURN 0.
   RETURN metadataValue:GetJsonObject('parallelConfig'):GetInteger('maxPartitionRecords').
   CATCH err AS Progress.Lang.Error: RETURN 0. END CATCH.
  END.
 END METHOD.
 METHOD PRIVATE INT64 partitionByteLimit(INPUT metadataValue AS JsonObject):
  DO ON ERROR UNDO, THROW:
   IF NOT VALID-OBJECT(metadataValue) OR NOT metadataValue:Has('parallelConfig') THEN RETURN 0.
   RETURN metadataValue:GetJsonObject('parallelConfig'):GetInt64('maxPartitionBytes').
   CATCH err AS Progress.Lang.Error: RETURN 0. END CATCH.
  END.
 END METHOD.
 METHOD PRIVATE JsonObject metadata(INPUT jobValue AS JsonObject):
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT jobValue:GetLogical('success') OR jobValue:GetCharacter('executionMode')<>'CONSUMER' THEN RETURN ?.
   parserValue=NEW ObjectModelParser(). resultValue=CAST(parserValue:Parse(STRING(jobValue:GetLongchar('planJson'))),JsonObject).
   IF resultValue:GetCharacter('kind')<>'consumer-query-v1' THEN DO: DELETE OBJECT resultValue. RETURN ?. END.
   RETURN resultValue.
   CATCH err AS Progress.Lang.Error: IF VALID-OBJECT(resultValue) THEN DELETE OBJECT resultValue. RETURN ?. END CATCH.
   FINALLY: IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject publicStatus(INPUT jobValue AS JsonObject,INPUT metadataValue AS JsonObject):
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE statusValue AS CHARACTER NO-UNDO.
  idValue=jobValue:GetCharacter('jobId'). statusValue=jobValue:GetCharacter('status').
  resultValue=NEW JsonObject(). resultValue:Add('success',TRUE). resultValue:Add('execution','async').
  resultValue:Add('jobId',idValue). resultValue:Add('code',metadataValue:GetCharacter('code')). resultValue:Add('status',statusValue).
  resultValue:Add('resultAvailable',statusValue='completed' AND (IF metadataValue:Has('createdEpoch') THEN metadataValue:GetInt64('createdEpoch') + 86400>INTERVAL(NOW,DATETIME-TZ(DATE(1,1,1970),0,0),'seconds') ELSE TRUE)).
  resultValue:Add('statusUrl','https://iol.imatextil.com.br/query-progress/api/jobs.php?jobId=' + idValue).
  resultValue:Add('resultUrl','https://iol.imatextil.com.br/query-progress/api/job-result.php?jobId=' + idValue).
  IF jobValue:Has('recordsReturned') THEN resultValue:Add('recordsReturned',jobValue:GetInteger('recordsReturned')).
  IF metadataValue:Has('parallel') THEN IF metadataValue:GetType('parallel')=JsonDataType:OBJECT THEN resultValue:Add('parallel',CAST(metadataValue:GetJsonObject('parallel'):Clone(),JsonObject)).
  IF metadataValue:Has('createdEpoch') THEN resultValue:Add('resultExpiresAtEpoch',metadataValue:GetInt64('createdEpoch') + 86400).
  IF statusValue='failed' THEN resultValue:Add('errorCode','JOB_EXECUTION_FAILED').
  RETURN resultValue.
 END METHOD.
 METHOD PRIVATE VOID audit(INPUT jobValue AS JsonObject,INPUT ownerValue AS CHARACTER,INPUT stateValue AS CHARACTER,INPUT contextValue AS PasoeExecutionContext):
  DEFINE VARIABLE repositoryValue AS ApiExecutionRepository NO-UNDO.
  DEFINE VARIABLE replyValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   idValue=jobValue:GetCharacter('executionId'). IF idValue='' THEN RETURN.
   contextValue:setCurrentUser(ownerValue). contextValue:setCustomField('executionId',idValue). contextValue:setCustomField('jobId',jobValue:GetCharacter('jobId')).
   repositoryValue=NEW ApiExecutionRepository().
   IF stateValue='completed' THEN replyValue=repositoryValue:finishExecution(idValue,'completed','Job do consumidor concluido',contextValue).
   ELSE IF stateValue='failed' THEN replyValue=repositoryValue:failExecution(idValue,'CONSUMER_JOB_FAILED','Falha no processamento da consulta.',contextValue).
   ELSE replyValue=repositoryValue:heartbeat(idValue,stateValue,'Job do consumidor em processamento',contextValue).
   CATCH err AS Progress.Lang.Error: /* Audit failure must not overwrite a completed result. */ END CATCH.
   FINALLY:
    IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue.
    IF VALID-OBJECT(replyValue) THEN DELETE OBJECT replyValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL applyParallelPartition(INPUT modelJsonValue AS JsonObject,INPUT metadataValue AS JsonObject,INPUT partitionValue AS JsonObject):
  DEFINE VARIABLE parallelValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE filtersValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE filterValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE startName AS CHARACTER NO-UNDO.
  DEFINE VARIABLE endName AS CHARACTER NO-UNDO.
  DEFINE VARIABLE sourceAlias AS CHARACTER NO-UNDO.
  DEFINE VARIABLE fieldValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE foundStart AS LOGICAL NO-UNDO.
  DEFINE VARIABLE foundEnd AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT metadataValue:Has('parallelConfig') OR metadataValue:GetType('parallelConfig')<>JsonDataType:OBJECT THEN RETURN FALSE.
   parallelValue=metadataValue:GetJsonObject('parallelConfig'):GetJsonObject('partition'). startName=parallelValue:GetCharacter('startParameter'). endName=parallelValue:GetCharacter('endParameter').
   sourceAlias=parallelValue:GetCharacter('sourceAlias'). fieldValue=parallelValue:GetCharacter('field').
   IF NOT partitionValue:Has(startName) OR NOT partitionValue:Has(endName) OR NOT modelJsonValue:Has('filters') THEN RETURN FALSE.
   filtersValue=modelJsonValue:GetJsonArray('filters').
   DO n=1 TO filtersValue:Length:
    filterValue=filtersValue:GetJsonObject(n).
    IF NOT COMPARE(filterValue:GetCharacter('sourceAlias'),'EQ',sourceAlias,'RAW') OR NOT COMPARE(filterValue:GetCharacter('field'),'EQ',fieldValue,'RAW') THEN NEXT.
    IF filterValue:GetCharacter('operator')='>=' THEN DO: filterValue:Set('value',partitionValue:GetCharacter(startName)). foundStart=TRUE. END.
    IF filterValue:GetCharacter('operator')='<=' THEN DO: filterValue:Set('value',partitionValue:GetCharacter(endName)). foundEnd=TRUE. END.
   END.
   RETURN foundStart AND foundEnd.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject readJob(INPUT idValue AS CHARACTER,INPUT downloadValue AS LOGICAL,INPUT configValue AS JsonObject,INPUT ownerValue AS CHARACTER,INPUT nowValue AS INT64,OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   statusValue=404.
   IF NOT THIS-OBJECT:isJobId(idValue) THEN RETURN THIS-OBJECT:failure('JOB_NOT_FOUND',404).
   repositoryValue=NEW DynamicQueryConsumerJobRepository(THIS-OBJECT:jobRoot(configValue)). jobValue=repositoryValue:getJob(idValue).
   metadataValue=THIS-OBJECT:metadata(jobValue).
   IF NOT VALID-OBJECT(metadataValue) THEN RETURN THIS-OBJECT:failure('JOB_NOT_FOUND',404).
   IF NOT COMPARE(metadataValue:GetCharacter('consumerId'),'EQ',ownerValue,'RAW') THEN RETURN THIS-OBJECT:failure('JOB_NOT_FOUND',404).
   statusValue=403.
   IF NOT THIS-OBJECT:canAccess(configValue,ownerValue,metadataValue:GetCharacter('code'),nowValue) THEN RETURN THIS-OBJECT:failure('QUERY_FORBIDDEN',403).
   IF NOT downloadValue THEN DO:
    statusValue=200. RETURN THIS-OBJECT:publicStatus(jobValue,metadataValue).
   END.
   IF metadataValue:Has('createdEpoch') THEN IF metadataValue:GetInt64('createdEpoch') + 86400<=nowValue THEN DO:
    statusValue=410. RETURN THIS-OBJECT:failure('JOB_RESULT_EXPIRED',410).
   END.
   statusValue=409.
   IF jobValue:GetCharacter('status')<>'completed' THEN RETURN THIS-OBJECT:failure('JOB_NOT_READY',409).
   pathValue=THIS-OBJECT:jobRoot(configValue) + '/' + idValue + '.json'.
   IF NOT COMPARE(jobValue:GetCharacter('resultPath'),'EQ',pathValue,'RAW') THEN RETURN THIS-OBJECT:failure('JOB_NOT_READY',409).
   FILE-INFO:FILE-NAME=pathValue.
   IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE>67108864 THEN RETURN THIS-OBJECT:failure('JOB_NOT_READY',409).
   parserValue=NEW ObjectModelParser(). statusValue=200.
   RETURN CAST(parserValue:ParseFile(pathValue),JsonObject).
   CATCH err AS Progress.Lang.Error: statusValue=503. RETURN THIS-OBJECT:failure('JOB_UNAVAILABLE',503). END CATCH.
   FINALLY:
    IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue.
    IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue.
    IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue.
    IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject openParallelArtifact(INPUT idValue AS CHARACTER,INPUT configValue AS JsonObject,INPUT ownerValue AS CHARACTER,INPUT allowAdminValue AS LOGICAL,INPUT nowValue AS INT64,OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO. DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO. DEFINE VARIABLE resultValue AS JsonObject NO-UNDO. DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   statusValue=404. IF NOT THIS-OBJECT:isJobId(idValue) THEN RETURN THIS-OBJECT:failure('JOB_NOT_FOUND',404).
   repositoryValue=NEW DynamicQueryConsumerJobRepository(THIS-OBJECT:jobRoot(configValue)). jobValue=repositoryValue:getJob(idValue). metadataValue=THIS-OBJECT:metadata(jobValue).
   IF NOT VALID-OBJECT(metadataValue) OR (NOT allowAdminValue AND NOT COMPARE(metadataValue:GetCharacter('consumerId'),'EQ',ownerValue,'RAW')) THEN RETURN THIS-OBJECT:failure('JOB_NOT_FOUND',404).
   statusValue=403. IF NOT THIS-OBJECT:canAccess(configValue,ownerValue,metadataValue:GetCharacter('code'),nowValue) THEN RETURN THIS-OBJECT:failure('QUERY_FORBIDDEN',403).
   IF metadataValue:GetInt64('createdEpoch') + 86400<=nowValue THEN DO: statusValue=410. RETURN THIS-OBJECT:failure('JOB_RESULT_EXPIRED',410). END.
   statusValue=409. IF jobValue:GetCharacter('status')<>'completed' OR NOT jobValue:Has('resultFormat') OR jobValue:GetCharacter('resultFormat')<>'ndjson+gzip' THEN RETURN THIS-OBJECT:failure('JOB_NOT_READY',409).
   pathValue=THIS-OBJECT:jobRoot(configValue) + '/' + idValue + '.ndjson.gz'. IF NOT COMPARE(jobValue:GetCharacter('resultPath'),'EQ',pathValue,'RAW') THEN RETURN THIS-OBJECT:failure('JOB_NOT_READY',409).
   FILE-INFO:FILE-NAME=pathValue. IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE<1 THEN RETURN THIS-OBJECT:failure('JOB_NOT_READY',409).
   resultValue=NEW JsonObject(). resultValue:Add('success',TRUE). resultValue:Add('path',FILE-INFO:FULL-PATHNAME). resultValue:Add('bytes',FILE-INFO:FILE-SIZE). resultValue:Add('sha256',jobValue:GetCharacter('resultSha256')). resultValue:Add('recordsReturned',jobValue:GetInteger('recordsReturned')). statusValue=200. RETURN resultValue.
   CATCH err AS Progress.Lang.Error: statusValue=503. RETURN THIS-OBJECT:failure('JOB_UNAVAILABLE',503). END CATCH.
   FINALLY: IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue. IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue. END FINALLY.
  END.
 END METHOD.
  /* Parallel workers may finish together. The repository lock intentionally
     rejects a contended write, so retry that short metadata commit instead of
     abandoning a valid partition lease for its two-hour lifetime. */
  METHOD PRIVATE JsonObject completeParallelPartitionWithRetry(
   INPUT repositoryValue AS DynamicQueryConsumerJobRepository,
   INPUT idValue AS CHARACTER, INPUT partitionIdValue AS INTEGER,
   INPUT leaseValue AS CHARACTER, INPUT succeededValue AS LOGICAL,
   INPUT failureCodeValue AS CHARACTER):
   DEFINE VARIABLE replyValue AS JsonObject NO-UNDO.
   DEFINE VARIABLE retryValue AS INTEGER NO-UNDO.
   DO retryValue=1 TO 25:
    replyValue=repositoryValue:completeParallelPartition(idValue,partitionIdValue,leaseValue,succeededValue,failureCodeValue).
    IF replyValue:GetLogical('success') THEN RETURN replyValue.
    IF NOT replyValue:Has('error') OR replyValue:GetJsonObject('error'):GetCharacter('code')<>'QUEUE_BUSY' THEN RETURN replyValue.
    IF retryValue<25 THEN DO:
     DELETE OBJECT replyValue. replyValue=? .
     PAUSE 0.1 NO-MESSAGE.
    END.
   END.
   RETURN replyValue.
  END METHOD.
  METHOD PUBLIC JsonObject drain(INPUT configFile AS CHARACTER):
  DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO.
  DEFINE VARIABLE serializerValue AS DynamicQueryRequestSerializer NO-UNDO.
  DEFINE VARIABLE optionsValue AS DynamicQueryWorkerOptions NO-UNDO.
  DEFINE VARIABLE policyValue AS DynamicQueryConsumerPolicy NO-UNDO.
  DEFINE VARIABLE serviceValue AS DynamicMultiTableQueryService NO-UNDO.
  DEFINE VARIABLE contextValue AS PasoeExecutionContext NO-UNDO.
  DEFINE VARIABLE modelValue AS DynamicQueryRequestModel NO-UNDO.
  DEFINE VARIABLE configValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE receiptValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE replyValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE contextText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE nowValue AS INT64 NO-UNDO.
  DEFINE VARIABLE processedValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE replaced AS LOGICAL NO-UNDO.
  DEFINE VARIABLE temporaryValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE rootValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE resultText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE modelText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE modelParserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE modelJsonValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE webhooksValue AS DynamicQueryConsumerWebhooks NO-UNDO.
  DEFINE VARIABLE parallelClaimValue AS LOGICAL NO-UNDO.
  DEFINE VARIABLE partitionValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE exporterValue AS DynamicQueryConsumerParallelExport NO-UNDO.
  DEFINE VARIABLE exportValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   policyValue=NEW DynamicQueryConsumerPolicy(). configValue=policyValue:loadConfig(configFile).
   rootValue=THIS-OBJECT:jobRoot(configValue). DELETE OBJECT configValue.
   repositoryValue=NEW DynamicQueryConsumerJobRepository(rootValue). serializerValue=NEW DynamicQueryRequestSerializer().
   optionsValue=NEW DynamicQueryWorkerOptions(). optionsValue:setExecutionMode('PASOE'). optionsValue:setWorkerName('sursum-med-consumer-worker').
   contextValue=NEW PasoeExecutionContext().
   contextText=serializerValue:contextToLongchar(contextValue).
   DO n=1 TO 2:
    configValue=policyValue:loadConfig(configFile). nowValue=policyValue:epochSeconds(NOW).
    IF NOT policyValue:isValid(configValue) THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_CONFIG_UNAVAILABLE',0).
    IF NOT COMPARE(rootValue,'EQ',THIS-OBJECT:jobRoot(configValue),'RAW') THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_CONFIG_CHANGED',0).
    parallelClaimValue=FALSE.
    jobValue=repositoryValue:claimParallelNext().
    IF jobValue:GetLogical('success') THEN parallelClaimValue=TRUE.
    ELSE DO:
     DELETE OBJECT jobValue.
     jobValue=repositoryValue:claimConsumerNext(optionsValue,contextValue).
    END.
    IF NOT jobValue:GetLogical('success') THEN DO:
     IF jobValue:GetJsonObject('error'):GetCharacter('code')<>'QUEUE_EMPTY' THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_UNAVAILABLE',0).
     DELETE OBJECT jobValue. DELETE OBJECT configValue. LEAVE.
    END.
    idValue=jobValue:GetCharacter('jobId'). processedValue=processedValue + 1.
    DO ON ERROR UNDO, THROW:
     metadataValue=THIS-OBJECT:metadata(jobValue).
     IF NOT VALID-OBJECT(metadataValue) OR NOT THIS-OBJECT:isJobId(idValue) THEN UNDO,THROW NEW Progress.Lang.AppError('INVALID_JOB',0).
     IF NOT THIS-OBJECT:canAccess(configValue,metadataValue:GetCharacter('consumerId'),metadataValue:GetCharacter('code'),nowValue) THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_PERMISSION_REVOKED',0).
     THIS-OBJECT:audit(jobValue,metadataValue:GetCharacter('consumerId'),'running',contextValue).
     IF metadataValue:GetInt64('createdEpoch') + 86400<=nowValue THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_EXPIRED',0).
    IF jobValue:Has('parallelConsolidate') THEN DO:
     exporterValue=NEW DynamicQueryConsumerParallelExport().
     exportValue=exporterValue:consolidate(rootValue,idValue,metadataValue:GetJsonObject('parallel'):GetInteger('totalPartitions'),metadataValue:GetJsonObject('parallelConfig'):GetInt64('maxResultBytes'),THIS-OBJECT:partitionByteLimit(metadataValue)).
     receiptValue=repositoryValue:completeParallelExport(idValue,jobValue:GetCharacter('consolidationLease'),exportValue).
     IF NOT receiptValue:GetLogical('success') THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_LEASE_LOST',0).
     webhooksValue=NEW DynamicQueryConsumerWebhooks(). webhooksValue:queueForJob(configValue,idValue,metadataValue:GetCharacter('consumerId'),metadataValue:GetCharacter('code'),metadataValue:GetCharacter('webhookDelivery')). DELETE OBJECT webhooksValue. webhooksValue=? .
     THIS-OBJECT:audit(jobValue,metadataValue:GetCharacter('consumerId'),'completed',contextValue).
     NEXT.
    END.
     FIX-CODEPAGE(modelText)='UTF-8'. modelText=jobValue:GetLongchar('requestJson').
     modelParserValue=NEW ObjectModelParser(). modelJsonValue=CAST(modelParserValue:Parse(modelText),JsonObject).
    IF parallelClaimValue THEN DO:
     partitionValue=jobValue:GetJsonObject('parallelPartition').
     IF NOT THIS-OBJECT:applyParallelPartition(modelJsonValue,metadataValue,partitionValue) THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_INVALID',0).
    END.
     modelValue=serializerValue:fromJsonObject(modelJsonValue).
     serviceValue=NEW DynamicMultiTableQueryService().
     IF metadataValue:GetLogical('paginate') THEN resultValue=serviceValue:executeSyncNow(modelValue).
     ELSE IF parallelClaimValue THEN resultValue=serviceValue:executeUnpagedLimited(modelValue,THIS-OBJECT:partitionRecordLimit(metadataValue)).
     ELSE resultValue=serviceValue:executeUnpaged(modelValue).
     IF NOT VALID-OBJECT(resultValue) OR NOT resultValue:GetLogical('success') THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_QUERY_FAILED',0).
     resultValue:Set('execution','async'). resultValue:Add('jobId',idValue).
     IF parallelClaimValue THEN DO:
      IF THIS-OBJECT:partitionRecordLimit(metadataValue)<1 OR THIS-OBJECT:partitionByteLimit(metadataValue)<1048576 THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_LIMIT_CONFIG_INVALID',0).
      IF resultValue:GetLogical('hasMore') THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_RECORD_LIMIT',0).
      FIX-CODEPAGE(resultText)='UTF-8'. resultValue:Write(resultText,FALSE).
      IF LENGTH(resultText,'RAW')>THIS-OBJECT:partitionByteLimit(metadataValue) THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_BYTE_LIMIT',0).
      IF NOT repositoryValue:writeParallelResult(idValue,partitionValue:GetInteger('partitionId'),resultValue,THIS-OBJECT:partitionByteLimit(metadataValue)) THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_RESULT_WRITE_FAILED',0).
      receiptValue=THIS-OBJECT:completeParallelPartitionWithRetry(repositoryValue,idValue,partitionValue:GetInteger('partitionId'),partitionValue:GetCharacter('lease'),TRUE,'').
      IF NOT receiptValue:GetLogical('success') THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_LEASE_LOST',0).
      THIS-OBJECT:audit(jobValue,metadataValue:GetCharacter('consumerId'),'running',contextValue).
      NEXT.
     END.
     FIX-CODEPAGE(resultText)='UTF-8'. resultValue:Write(resultText,FALSE).
     IF LENGTH(resultText,'RAW')>67108864 THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_RESULT_TOO_LARGE',0).
     pathValue=THIS-OBJECT:jobRoot(configValue) + '/' + idValue + '.json'.
     temporaryValue=repositoryValue:temporaryResultPath(idValue).
     IF NOT resultValue:WriteFile(temporaryValue,FALSE) THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_WRITE_FAILED',0).
     FILE-INFO:FILE-NAME=temporaryValue.
     IF FILE-INFO:FILE-SIZE>67108864 THEN UNDO,THROW NEW Progress.Lang.AppError('JOB_RESULT_TOO_LARGE',0).
     receiptValue=repositoryValue:completeJob(idValue,pathValue,resultValue:GetInteger('recordsReturned'),resultValue:GetLogical('hasMore'),contextText).
     webhooksValue=NEW DynamicQueryConsumerWebhooks(). webhooksValue:queueForJob(configValue,idValue,metadataValue:GetCharacter('consumerId'),metadataValue:GetCharacter('code'),metadataValue:GetCharacter('webhookDelivery')). DELETE OBJECT webhooksValue. webhooksValue=?.
     THIS-OBJECT:audit(jobValue,metadataValue:GetCharacter('consumerId'),'completed',contextValue).
     CATCH err AS Progress.Lang.Error:
      LOG-MANAGER:WRITE-MESSAGE('job=' + idValue + ' error=' + STRING(err:GetMessageNum(1)) + ' ' + err:GetMessage(1) + ' stack=' + err:CallStack,'CONSUMER-JOB').
      IF jobValue:Has('parallelConsolidate') THEN receiptValue=repositoryValue:failJob(idValue,'PARALLEL_EXPORT_FAILED','Falha ao consolidar o resultado paralelo.','',contextText).
      ELSE IF parallelClaimValue AND VALID-OBJECT(partitionValue) THEN receiptValue=THIS-OBJECT:completeParallelPartitionWithRetry(repositoryValue,idValue,partitionValue:GetInteger('partitionId'),partitionValue:GetCharacter('lease'),FALSE,IF LOOKUP(err:GetMessage(1),'PARALLEL_PARTITION_RECORD_LIMIT,PARALLEL_PARTITION_BYTE_LIMIT,PARALLEL_PARTITION_LIMIT_CONFIG_INVALID')>0 THEN err:GetMessage(1) ELSE 'PARALLEL_PARTITION_FAILED').
      ELSE receiptValue=repositoryValue:failJob(idValue,'CONSUMER_JOB_FAILED','Falha no processamento da consulta.','',contextText).
      IF receiptValue:GetLogical('success') AND VALID-OBJECT(metadataValue) THEN THIS-OBJECT:audit(jobValue,metadataValue:GetCharacter('consumerId'),receiptValue:GetCharacter('status'),contextValue).
      IF temporaryValue<>'' THEN OS-DELETE VALUE(temporaryValue) NO-ERROR.
     END CATCH.
     FINALLY:
      pathValue=''. temporaryValue=''. resultText=''. modelText=''.
      IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue.
      IF VALID-OBJECT(modelValue) THEN DELETE OBJECT modelValue.
      IF VALID-OBJECT(serviceValue) THEN DELETE OBJECT serviceValue.
      IF VALID-OBJECT(resultValue) THEN DELETE OBJECT resultValue.
      IF VALID-OBJECT(receiptValue) THEN DELETE OBJECT receiptValue.
      IF VALID-OBJECT(modelJsonValue) THEN DELETE OBJECT modelJsonValue.
      IF VALID-OBJECT(partitionValue) THEN DELETE OBJECT partitionValue.
      IF VALID-OBJECT(exporterValue) THEN DELETE OBJECT exporterValue.
      IF VALID-OBJECT(exportValue) THEN DELETE OBJECT exportValue.
    IF VALID-OBJECT(webhooksValue) THEN DELETE OBJECT webhooksValue.
      IF VALID-OBJECT(modelParserValue) THEN DELETE OBJECT modelParserValue.
     END FINALLY.
    END.
    DELETE OBJECT jobValue. DELETE OBJECT configValue.
   END.
   replyValue=NEW JsonObject(). replyValue:Add('success',TRUE). replyValue:Add('processed',processedValue). RETURN replyValue.
   CATCH err AS Progress.Lang.Error: RETURN THIS-OBJECT:failure('QUEUE_UNAVAILABLE',503). END CATCH.
   FINALLY:
    IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue.
    IF VALID-OBJECT(serializerValue) THEN DELETE OBJECT serializerValue.
    IF VALID-OBJECT(optionsValue) THEN DELETE OBJECT optionsValue.
    IF VALID-OBJECT(policyValue) THEN DELETE OBJECT policyValue.
    IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue.
    IF VALID-OBJECT(configValue) THEN DELETE OBJECT configValue.
    IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue.
   END FINALLY.
  END.
 END METHOD.
END CLASS.


