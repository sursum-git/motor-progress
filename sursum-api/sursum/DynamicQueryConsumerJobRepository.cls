USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Private, atomic MED queue. The legacy database queue is not changed or consumed. */
CLASS DynamicQueryConsumerJobRepository:
 DEFINE PRIVATE VARIABLE rootValue AS CHARACTER NO-UNDO.
 DEFINE PRIVATE VARIABLE claimId AS CHARACTER NO-UNDO.
 DEFINE PRIVATE VARIABLE claimLease AS CHARACTER NO-UNDO.
 DEFINE PRIVATE STREAM dirStream.
 DEFINE PRIVATE TEMP-TABLE ttName NO-UNDO FIELD fileName AS CHARACTER INDEX fileName IS PRIMARY UNIQUE fileName.
 CONSTRUCTOR PUBLIC DynamicQueryConsumerJobRepository(INPUT directoryValue AS CHARACTER):
  rootValue=directoryValue.
 END CONSTRUCTOR.
 METHOD PRIVATE INT64 epoch():
  RETURN INTERVAL(NOW,DATETIME-TZ(DATE(1,1,1970),0,0),'seconds').
 END METHOD.
 METHOD PRIVATE LOGICAL validId(INPUT idValue AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF idValue=? OR LENGTH(idValue)<>26 THEN RETURN FALSE.
  IF NOT COMPARE(SUBSTRING(idValue,1,4),'EQ','JOB-','RAW') OR SUBSTRING(idValue,13,1)<>'-' OR SUBSTRING(idValue,20,1)<>'-' THEN RETURN FALSE.
  DO n=5 TO 26: IF n=13 OR n=20 THEN NEXT. IF INDEX('0123456789',SUBSTRING(idValue,n,1))=0 THEN RETURN FALSE. END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL validLease(INPUT leaseValue AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF leaseValue=? OR LENGTH(leaseValue)<>32 THEN RETURN FALSE.
  DO n=1 TO 32: IF INDEX('0123456789abcdef',SUBSTRING(leaseValue,n,1))=0 THEN RETURN FALSE. END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE VOID pruneTemps():
  DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE typeValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE oldValue AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   INPUT STREAM dirStream FROM OS-DIR(rootValue) NO-ECHO.
   REPEAT:
    IMPORT STREAM dirStream nameValue pathValue typeValue.
    IF INDEX(typeValue,'F')=0 OR NOT THIS-OBJECT:validId(SUBSTRING(nameValue,1,26)) OR SUBSTRING(nameValue,27,1)<>'.' THEN NEXT.
    IF NOT THIS-OBJECT:validLease(SUBSTRING(nameValue,28,32)) THEN NEXT.
    IF SUBSTRING(nameValue,60)<>'.result.tmp' AND SUBSTRING(nameValue,60)<>'.meta.tmp' THEN NEXT.
    FILE-INFO:FILE-NAME=rootValue + '/' + nameValue.
    oldValue=FILE-INFO:FILE-MOD-DATE<TODAY - 1.
    jobValue=THIS-OBJECT:getJob(SUBSTRING(nameValue,1,26)).
    IF jobValue:GetLogical('success') THEN
     IF LOOKUP(jobValue:GetCharacter('status'),'completed,failed')>0 AND jobValue:GetInt64('createdEpoch') + 172800<THIS-OBJECT:epoch() THEN oldValue=TRUE.
    IF jobValue:GetLogical('success') THEN IF jobValue:GetCharacter('status')='running' THEN
     IF COMPARE(jobValue:GetCharacter('lease'),'EQ',SUBSTRING(nameValue,28,32),'RAW') AND jobValue:GetInt64('leaseExpires')>THIS-OBJECT:epoch() THEN oldValue=FALSE.
    DELETE OBJECT jobValue.
    IF oldValue THEN OS-DELETE VALUE(rootValue + '/' + nameValue) NO-ERROR.
   END.
   FINALLY: INPUT STREAM dirStream CLOSE. IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE INT64 usage():
  DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE typeValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE allIds AS JsonArray NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE totalValue AS INT64 NO-UNDO.
  DEFINE VARIABLE temporaryBytes AS INT64 NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   allIds=THIS-OBJECT:ids().
   DO n=1 TO allIds:Length:
    jobValue=THIS-OBJECT:getJob(allIds:GetCharacter(n)).
    IF jobValue:GetCharacter('status')='running' AND THIS-OBJECT:validLease(jobValue:GetCharacter('lease')) THEN DO:
     FILE-INFO:FILE-NAME=rootValue + '/' + allIds:GetCharacter(n) + '.' + jobValue:GetCharacter('lease') + '.result.tmp'.
     temporaryBytes=IF FILE-INFO:FULL-PATHNAME=? THEN 0 ELSE FILE-INFO:FILE-SIZE.
     totalValue=totalValue + MAXIMUM(INT64(0),67108864 - temporaryBytes).
    END.
    DELETE OBJECT jobValue.
   END.
   INPUT STREAM dirStream FROM OS-DIR(rootValue) NO-ECHO.
   REPEAT:
    IMPORT STREAM dirStream nameValue pathValue typeValue.
    IF INDEX(typeValue,'F')=0 THEN NEXT.
    FILE-INFO:FILE-NAME=rootValue + '/' + nameValue.
    IF FILE-INFO:FULL-PATHNAME<>? THEN totalValue=totalValue + FILE-INFO:FILE-SIZE.
   END.
   RETURN totalValue.
   FINALLY:
    INPUT STREAM dirStream CLOSE.
    IF VALID-OBJECT(allIds) THEN DELETE OBJECT allIds.
    IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE JsonObject errorValue(INPUT codeValue AS CHARACTER):
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE detail AS JsonObject NO-UNDO.
  reply=NEW JsonObject(). detail=NEW JsonObject(). reply:Add('success',FALSE). detail:Add('code',codeValue). reply:Add('error',detail). RETURN reply.
 END METHOD.
 METHOD PRIVATE LOGICAL isParallelJob(INPUT jobValue AS JsonObject):
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   parserValue=NEW ObjectModelParser(). metadataValue=CAST(parserValue:Parse(STRING(jobValue:GetLongchar('planJson'))),JsonObject).
   RETURN metadataValue:Has('parallel') AND metadataValue:GetType('parallel')=JsonDataType:OBJECT AND metadataValue:GetJsonObject('parallel'):GetLogical('enabled').
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
   FINALLY: IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue. IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE INT64 parallelResultLimit(INPUT jobValue AS JsonObject):
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO. DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO. DEFINE VARIABLE configValue AS JsonObject NO-UNDO. DEFINE VARIABLE resultValue AS INT64 NO-UNDO INITIAL 67108864.
  DO ON ERROR UNDO, THROW:
   parserValue=NEW ObjectModelParser(). metadataValue=CAST(parserValue:Parse(STRING(jobValue:GetLongchar('planJson'))),JsonObject).
   IF metadataValue:Has('parallelConfig') AND metadataValue:GetType('parallelConfig')=JsonDataType:OBJECT THEN DO:
    configValue=metadataValue:GetJsonObject('parallelConfig').
    IF configValue:Has('maxResultBytes') THEN resultValue=configValue:GetInt64('maxResultBytes').
   END.
   IF resultValue<67108864 OR resultValue>10737418240 THEN RETURN 67108864.
   RETURN resultValue.
   CATCH err AS Progress.Lang.Error: RETURN 67108864. END CATCH.
   FINALLY: IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue. IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE JsonArray ids():
  DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE typeValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonArray NO-UNDO.
  DO ON ERROR UNDO, THROW:
   resultValue=NEW JsonArray(). EMPTY TEMP-TABLE ttName.
   INPUT STREAM dirStream FROM OS-DIR(rootValue) NO-ECHO.
   REPEAT:
    IMPORT STREAM dirStream nameValue pathValue typeValue.
    IF LENGTH(nameValue)=35 AND SUBSTRING(nameValue,27)='.job.json' AND THIS-OBJECT:validId(SUBSTRING(nameValue,1,26)) AND INDEX(typeValue,'F')>0 THEN DO:
     CREATE ttName. ttName.fileName=SUBSTRING(nameValue,1,26).
    END.
   END.
   FOR EACH ttName BY fileName: resultValue:Add(ttName.fileName). END.
   RETURN resultValue.
   FINALLY: INPUT STREAM dirStream CLOSE. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE VOID save(INPUT jobValue AS JsonObject):
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE temporaryValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE succeeded AS LOGICAL NO-UNDO.
  idValue=jobValue:GetCharacter('jobId').
  temporaryValue=rootValue + '/' + idValue + '.' + LC(HEX-ENCODE(GENERATE-UUID)) + '.meta.tmp'.
  DO ON ERROR UNDO, THROW:
   IF NOT jobValue:WriteFile(temporaryValue,FALSE) THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_WRITE_FAILED',0).
   RUN QueryConsumerConfigIo.p('replace',rootValue + '/' + idValue + '.job.json',temporaryValue,OUTPUT succeeded).
   IF NOT succeeded THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_WRITE_FAILED',0).
   FINALLY: OS-DELETE VALUE(temporaryValue) NO-ERROR. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject getJob(INPUT idValue AS CHARACTER):
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT THIS-OBJECT:validId(idValue) THEN RETURN THIS-OBJECT:errorValue('JOB_NOT_FOUND').
   pathValue=rootValue + '/' + idValue + '.job.json'. FILE-INFO:FILE-NAME=pathValue.
   IF FILE-INFO:FULL-PATHNAME=? THEN RETURN THIS-OBJECT:errorValue('JOB_NOT_FOUND').
   IF FILE-INFO:FILE-SIZE>131072 THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_RECORD_INVALID',0).
   parserValue=NEW ObjectModelParser(). jobValue=CAST(parserValue:ParseFile(pathValue),JsonObject).
   IF NOT COMPARE(jobValue:GetCharacter('jobId'),'EQ',idValue,'RAW') OR jobValue:GetCharacter('executionMode')<>'CONSUMER' THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_RECORD_INVALID',0).
   RETURN jobValue.
   FINALLY:
    IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC CHARACTER reserveJobId():
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO n=1 TO 10:
   idValue='JOB-' + STRING(YEAR(TODAY),'9999') + STRING(MONTH(TODAY),'99') + STRING(DAY(TODAY),'99') + '-' + STRING(TIME,'999999') + '-' + STRING(RANDOM(1,999999),'999999').
   FILE-INFO:FILE-NAME=rootValue + '/' + idValue + '.job.json'.
   IF FILE-INFO:FULL-PATHNAME=? THEN LEAVE.
  END.
  RETURN IF n>10 THEN '' ELSE idValue.
 END METHOD.
 METHOD PUBLIC JsonObject createJobWithId(INPUT idValue AS CHARACTER,INPUT requestText AS LONGCHAR,INPUT planText AS LONGCHAR,INPUT contextText AS LONGCHAR,INPUT modeValue AS CHARACTER,INPUT maxAttempts AS INTEGER,INPUT executionValue AS CHARACTER):
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  IF NOT THIS-OBJECT:validId(idValue) THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
  FILE-INFO:FILE-NAME=rootValue + '/' + idValue + '.job.json'.
  IF FILE-INFO:FULL-PATHNAME<>? THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
  jobValue=NEW JsonObject(). jobValue:Add('success',TRUE). jobValue:Add('jobId',idValue).
  jobValue:Add('status','queued'). jobValue:Add('execution','async'). jobValue:Add('executionMode','CONSUMER').
  jobValue:Add('requestJson',requestText). jobValue:Add('planJson',planText). jobValue:Add('requestContextJson',contextText).
  jobValue:Add('executionId',executionValue). jobValue:Add('createdEpoch',THIS-OBJECT:epoch()).
  jobValue:Add('attempts',0). jobValue:Add('maxAttempts',3). jobValue:Add('resultPath',''). jobValue:Add('recordsReturned',0). jobValue:Add('hasMore',FALSE).
  THIS-OBJECT:save(jobValue). RETURN jobValue.
 END METHOD.
 METHOD PUBLIC JsonObject createJob(INPUT requestText AS LONGCHAR,INPUT planText AS LONGCHAR,INPUT contextText AS LONGCHAR,INPUT modeValue AS CHARACTER,INPUT maxAttempts AS INTEGER,INPUT executionValue AS CHARACTER):
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  idValue=THIS-OBJECT:reserveJobId().
  IF idValue='' THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
  RETURN THIS-OBJECT:createJobWithId(idValue,requestText,planText,contextText,modeValue,maxAttempts,executionValue).
 END METHOD.
 METHOD PUBLIC JsonObject pendingConsumerJobs(INPUT consumerValue AS CHARACTER):
  DEFINE VARIABLE allIds AS JsonArray NO-UNDO.
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE totalValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE ownValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   allIds=THIS-OBJECT:ids(). parserValue=NEW ObjectModelParser().
   DO n=1 TO allIds:Length:
    jobValue=THIS-OBJECT:getJob(allIds:GetCharacter(n)).
    IF LOOKUP(jobValue:GetCharacter('status'),'queued,running')>0 THEN DO:
     totalValue=totalValue + 1. metadataValue=CAST(parserValue:Parse(STRING(jobValue:GetLongchar('planJson'))),JsonObject).
     IF COMPARE(metadataValue:GetCharacter('consumerId'),'EQ',consumerValue,'RAW') THEN ownValue=ownValue + 1.
     DELETE OBJECT metadataValue.
    END.
    DELETE OBJECT jobValue.
   END.
   reply=NEW JsonObject(). reply:Add('success',TRUE). reply:Add('total',totalValue). reply:Add('consumer',ownValue). reply:Add('stored',allIds:Length). reply:Add('bytes',THIS-OBJECT:usage()). RETURN reply.
   FINALLY:
    IF VALID-OBJECT(allIds) THEN DELETE OBJECT allIds.
    IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue.
    IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue.
    IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject claimConsumerNext(INPUT optionsValue AS DynamicQueryWorkerOptions,INPUT contextValue AS PasoeExecutionContext):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1.
  DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE allIds AS JsonArray NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock).
   IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_EMPTY').
   THIS-OBJECT:pruneTemps().
   allIds=THIS-OBJECT:ids().
   DO n=1 TO allIds:Length:
    idValue=allIds:GetCharacter(n). jobValue=THIS-OBJECT:getJob(idValue).
    IF jobValue:GetInt64('createdEpoch') + 172800<THIS-OBJECT:epoch() AND LOOKUP(jobValue:GetCharacter('status'),'completed,failed')>0 THEN DO:
     OS-DELETE VALUE(rootValue + '/' + idValue + '.json') VALUE(rootValue + '/' + idValue + '.job.json') NO-ERROR.
     DELETE OBJECT jobValue. NEXT.
    END.
    IF jobValue:GetCharacter('status')='running' THEN IF jobValue:GetInt64('leaseExpires')<=THIS-OBJECT:epoch() THEN DO:
     jobValue:Set('status',IF jobValue:GetInteger('attempts')<3 THEN 'queued' ELSE 'failed'). THIS-OBJECT:save(jobValue).
    END.
    IF jobValue:GetCharacter('status')='queued' AND THIS-OBJECT:isParallelJob(jobValue) THEN DO: DELETE OBJECT jobValue. NEXT. END.
    IF jobValue:GetCharacter('status')='queued' THEN DO:
     IF THIS-OBJECT:usage() + 67108864 + 1048576>1073741824 THEN DO: DELETE OBJECT jobValue. NEXT. END.
     claimId=idValue. claimLease=LC(HEX-ENCODE(GENERATE-UUID)).
     jobValue:Set('status','running'). jobValue:Set('attempts',jobValue:GetInteger('attempts') + 1).
     IF jobValue:Has('lease') THEN jobValue:Set('lease',claimLease). ELSE jobValue:Add('lease',claimLease).
     IF jobValue:Has('leaseExpires') THEN jobValue:Set('leaseExpires',THIS-OBJECT:epoch() + 7200). ELSE jobValue:Add('leaseExpires',THIS-OBJECT:epoch() + 7200).
     THIS-OBJECT:save(jobValue). RETURN jobValue.
    END.
    DELETE OBJECT jobValue.
   END.
   RETURN THIS-OBJECT:errorValue('QUEUE_EMPTY').
   FINALLY:
    IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released).
    IF VALID-OBJECT(allIds) THEN DELETE OBJECT allIds.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject claimParallelNext():
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO. DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1. DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE allIds AS JsonArray NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO. DEFINE VARIABLE planValue AS JsonObject NO-UNDO. DEFINE VARIABLE claimValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE plannerValue AS DynamicQueryConsumerParallelJobs NO-UNDO. DEFINE VARIABLE idValue AS CHARACTER NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock). IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_EMPTY').
   allIds=THIS-OBJECT:ids(). plannerValue=NEW DynamicQueryConsumerParallelJobs().
   DO n=1 TO allIds:Length:
    idValue=allIds:GetCharacter(n). jobValue=THIS-OBJECT:getJob(idValue).
    IF LOOKUP(jobValue:GetCharacter('status'),'queued,parallel')=0 OR NOT THIS-OBJECT:isParallelJob(jobValue) THEN DO: DELETE OBJECT jobValue. NEXT. END.
    IF jobValue:GetCharacter('status')='queued' THEN DO: jobValue:Set('status','parallel'). THIS-OBJECT:save(jobValue). END.
    planValue=plannerValue:readPlan(rootValue,idValue). claimValue=plannerValue:claimPartition(planValue,7200).
    IF claimValue:GetLogical('success') THEN DO:
     IF NOT plannerValue:savePlan(rootValue,idValue,planValue) THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PLAN_WRITE_FAILED',0).
     jobValue:Add('parallelPartition',CAST(claimValue:GetJsonObject('partition'):Clone(),JsonObject)). RETURN jobValue.
    END.
    IF planValue:GetInteger('completedPartitions')=planValue:GetInteger('totalPartitions') AND planValue:GetInteger('failedPartitions')=0 THEN DO:
     jobValue:Set('status','consolidating').
     IF jobValue:Has('consolidationLease') THEN jobValue:Set('consolidationLease',LC(HEX-ENCODE(GENERATE-UUID))). ELSE jobValue:Add('consolidationLease',LC(HEX-ENCODE(GENERATE-UUID))).
     IF jobValue:Has('consolidationLeaseExpires') THEN jobValue:Set('consolidationLeaseExpires',THIS-OBJECT:epoch() + 7200). ELSE jobValue:Add('consolidationLeaseExpires',THIS-OBJECT:epoch() + 7200).
     THIS-OBJECT:save(jobValue). jobValue:Add('parallelConsolidate',TRUE). RETURN jobValue.
    END.
    DELETE OBJECT claimValue. claimValue=? . DELETE OBJECT planValue. planValue=? . DELETE OBJECT jobValue.
   END.
   RETURN THIS-OBJECT:errorValue('QUEUE_EMPTY').
   FINALLY:
    IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released).
    IF VALID-OBJECT(allIds) THEN DELETE OBJECT allIds. IF VALID-OBJECT(plannerValue) THEN DELETE OBJECT plannerValue. IF VALID-OBJECT(planValue) THEN DELETE OBJECT planValue. IF VALID-OBJECT(claimValue) THEN DELETE OBJECT claimValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject completeParallelExport(INPUT idValue AS CHARACTER,INPUT leaseValue AS CHARACTER,INPUT exportValue AS JsonObject):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO. DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1. DEFINE VARIABLE released AS LOGICAL NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock). IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
   jobValue=THIS-OBJECT:getJob(idValue).
   IF jobValue:GetCharacter('status')<>'consolidating' OR NOT jobValue:Has('consolidationLease') OR NOT COMPARE(jobValue:GetCharacter('consolidationLease'),'EQ',leaseValue,'RAW') THEN RETURN THIS-OBJECT:errorValue('LEASE_LOST').
   IF NOT exportValue:GetLogical('success') OR NOT COMPARE(exportValue:GetCharacter('resultPath'),'EQ',rootValue + '/' + idValue + '.ndjson.gz','RAW') THEN RETURN THIS-OBJECT:errorValue('RESULT_PATH_INVALID').
   jobValue:Set('status','completed'). jobValue:Set('resultPath',exportValue:GetCharacter('resultPath')). jobValue:Set('recordsReturned',exportValue:GetInteger('recordsReturned')). jobValue:Set('hasMore',FALSE).
   jobValue:Add('resultFormat',exportValue:GetCharacter('format')). jobValue:Add('resultBytes',exportValue:GetInt64('bytes')). jobValue:Add('resultSha256',exportValue:GetCharacter('sha256')). THIS-OBJECT:save(jobValue). RETURN jobValue.
   FINALLY: IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released). IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject completeParallelPartition(INPUT idValue AS CHARACTER,INPUT partitionIdValue AS INTEGER,INPUT leaseValue AS CHARACTER,INPUT succeededValue AS LOGICAL,INPUT failureCodeValue AS CHARACTER):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO. DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1. DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO. DEFINE VARIABLE plannerValue AS DynamicQueryConsumerParallelJobs NO-UNDO. DEFINE VARIABLE planValue AS JsonObject NO-UNDO. DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO. DEFINE VARIABLE metadataValue AS JsonObject NO-UNDO. DEFINE VARIABLE metadataText AS LONGCHAR NO-UNDO. DEFINE VARIABLE parallelValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock). IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
   jobValue=THIS-OBJECT:getJob(idValue). IF jobValue:GetCharacter('status')<>'parallel' OR NOT THIS-OBJECT:isParallelJob(jobValue) THEN RETURN THIS-OBJECT:errorValue('LEASE_LOST').
   plannerValue=NEW DynamicQueryConsumerParallelJobs(). planValue=plannerValue:readPlan(rootValue,idValue).
   IF NOT plannerValue:completePartition(planValue,partitionIdValue,leaseValue,succeededValue,failureCodeValue) THEN RETURN THIS-OBJECT:errorValue('LEASE_LOST').
   IF NOT plannerValue:savePlan(rootValue,idValue,planValue) THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PLAN_WRITE_FAILED',0).
   parserValue=NEW ObjectModelParser(). metadataValue=CAST(parserValue:Parse(STRING(jobValue:GetLongchar('planJson'))),JsonObject). parallelValue=metadataValue:GetJsonObject('parallel').
   parallelValue:Set('completedPartitions',planValue:GetInteger('completedPartitions')). parallelValue:Set('runningPartitions',planValue:GetInteger('runningPartitions')). parallelValue:Set('failedPartitions',planValue:GetInteger('failedPartitions')).
   IF NOT succeededValue THEN IF LOOKUP(failureCodeValue,'PARALLEL_PARTITION_RECORD_LIMIT,PARALLEL_PARTITION_BYTE_LIMIT,PARALLEL_PARTITION_LIMIT_CONFIG_INVALID')>0 THEN DO:
    IF parallelValue:Has('lastFailureCode') THEN parallelValue:Set('lastFailureCode',failureCodeValue). ELSE parallelValue:Add('lastFailureCode',failureCodeValue).
   END.
   metadataValue:Write(metadataText,FALSE). jobValue:Set('planJson',metadataText).
   /* A partition is a required slice of one export. Continuing after any failure
      would waste agents and could never yield a complete result. */
   IF NOT succeededValue THEN jobValue:Set('status','failed').
   THIS-OBJECT:save(jobValue). RETURN jobValue.
   FINALLY:
    IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released).
    IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. IF VALID-OBJECT(plannerValue) THEN DELETE OBJECT plannerValue. IF VALID-OBJECT(planValue) THEN DELETE OBJECT planValue. IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue. IF VALID-OBJECT(metadataValue) THEN DELETE OBJECT metadataValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC LOGICAL writeParallelResult(INPUT idValue AS CHARACTER,INPUT partitionIdValue AS INTEGER,INPUT resultValue AS JsonObject,INPUT maxBytesValue AS INT64):
  DEFINE VARIABLE finalPath AS CHARACTER NO-UNDO. DEFINE VARIABLE temporaryValue AS CHARACTER NO-UNDO. DEFINE VARIABLE replaced AS LOGICAL NO-UNDO.
  IF NOT THIS-OBJECT:validId(idValue) OR partitionIdValue<1 OR NOT VALID-OBJECT(resultValue) OR maxBytesValue<1048576 OR maxBytesValue>1073741824 THEN RETURN FALSE.
  finalPath=rootValue + '/' + idValue + '.part-' + STRING(partitionIdValue) + '.json'.
  temporaryValue=finalPath + '.' + LC(HEX-ENCODE(GENERATE-UUID)) + '.tmp'.
  DO ON ERROR UNDO, THROW:
   IF NOT resultValue:WriteFile(temporaryValue,FALSE) THEN RETURN FALSE.
   FILE-INFO:FILE-NAME=temporaryValue. IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE>maxBytesValue THEN RETURN FALSE.
   RUN QueryConsumerConfigIo.p('replace',finalPath,temporaryValue,OUTPUT replaced). RETURN replaced.
   FINALLY: OS-DELETE VALUE(temporaryValue) NO-ERROR. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE CHARACTER attemptPath(INPUT idValue AS CHARACTER):
  IF NOT COMPARE(idValue,'EQ',claimId,'RAW') OR claimLease='' THEN UNDO,THROW NEW Progress.Lang.AppError('LEASE_REQUIRED',0).
  RETURN rootValue + '/' + idValue + '.' + claimLease + '.result.tmp'.
 END METHOD.
 METHOD PUBLIC CHARACTER temporaryResultPath(INPUT idValue AS CHARACTER):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1.
  DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock).
   IF NOT ownsLock THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_BUSY',0).
   jobValue=THIS-OBJECT:getJob(idValue).
   IF jobValue:GetCharacter('status')<>'running' OR NOT COMPARE(jobValue:GetCharacter('lease'),'EQ',claimLease,'RAW') OR NOT COMPARE(idValue,'EQ',claimId,'RAW') THEN UNDO,THROW NEW Progress.Lang.AppError('LEASE_LOST',0).
   jobValue:Set('leaseExpires',THIS-OBJECT:epoch() + 7200). THIS-OBJECT:save(jobValue).
   RETURN THIS-OBJECT:attemptPath(idValue).
   FINALLY:
    IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released).
    IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject completeJob(INPUT idValue AS CHARACTER,INPUT resultPath AS CHARACTER,INPUT recordsValue AS INTEGER,INPUT hasMoreValue AS LOGICAL,INPUT contextText AS LONGCHAR):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1.
  DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE replaced AS LOGICAL NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE allIds AS JsonArray NO-UNDO.
  DEFINE VARIABLE bytesValue AS INT64 NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock).
   IF NOT ownsLock THEN UNDO,THROW NEW Progress.Lang.AppError('QUEUE_BUSY',0).
   jobValue=THIS-OBJECT:getJob(idValue).
   IF jobValue:GetCharacter('status')<>'running' OR NOT COMPARE(jobValue:GetCharacter('lease'),'EQ',claimLease,'RAW') OR NOT COMPARE(idValue,'EQ',claimId,'RAW') THEN UNDO,THROW NEW Progress.Lang.AppError('LEASE_LOST',0).
   IF NOT COMPARE(resultPath,'EQ',rootValue + '/' + idValue + '.json','RAW') THEN UNDO,THROW NEW Progress.Lang.AppError('RESULT_PATH_INVALID',0).
   bytesValue=THIS-OBJECT:usage().
   FILE-INFO:FILE-NAME=THIS-OBJECT:attemptPath(idValue).
   IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE>67108864 THEN UNDO,THROW NEW Progress.Lang.AppError('RESULT_LIMIT',0).
   IF bytesValue>1073741824 THEN UNDO,THROW NEW Progress.Lang.AppError('RESULT_STORAGE_LIMIT',0).
   RUN QueryConsumerConfigIo.p('replace',resultPath,THIS-OBJECT:attemptPath(idValue),OUTPUT replaced).
   IF NOT replaced THEN UNDO,THROW NEW Progress.Lang.AppError('RESULT_WRITE_FAILED',0).
   jobValue:Set('status','completed'). jobValue:Set('resultPath',resultPath). jobValue:Set('recordsReturned',recordsValue). jobValue:Set('hasMore',hasMoreValue).
   THIS-OBJECT:save(jobValue). RETURN jobValue.
   FINALLY:
    IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released).
    IF VALID-OBJECT(allIds) THEN DELETE OBJECT allIds.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject queueWebhook(INPUT idValue AS CHARACTER,INPUT webhookValue AS JsonObject):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO. DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1. DEFINE VARIABLE released AS LOGICAL NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock). IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
   jobValue=THIS-OBJECT:getJob(idValue). IF jobValue:GetCharacter('status')<>'completed' THEN RETURN THIS-OBJECT:errorValue('JOB_NOT_READY').
   webhookValue:Add('status','queued'). webhookValue:Add('attempts',0). webhookValue:Add('nextEpoch',THIS-OBJECT:epoch()).
   jobValue:Add('webhook',webhookValue). THIS-OBJECT:save(jobValue). RETURN jobValue.
   FINALLY: IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released). IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject claimWebhookNext():
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO. DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1. DEFINE VARIABLE released AS LOGICAL NO-UNDO. DEFINE VARIABLE allIds AS JsonArray NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO. DEFINE VARIABLE webhookValue AS JsonObject NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE leaseValue AS CHARACTER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock). IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_EMPTY'). allIds=THIS-OBJECT:ids().
   DO n=1 TO allIds:Length:
    jobValue=THIS-OBJECT:getJob(allIds:GetCharacter(n)). IF jobValue:GetCharacter('status')<>'completed' OR NOT jobValue:Has('webhook') THEN DO: DELETE OBJECT jobValue. NEXT. END.
    webhookValue=jobValue:GetJsonObject('webhook'). IF webhookValue:GetCharacter('status')='running' AND webhookValue:GetInt64('leaseExpires')<=THIS-OBJECT:epoch() THEN webhookValue:Set('status','queued').
    IF webhookValue:GetCharacter('status')='queued' AND webhookValue:GetInt64('nextEpoch')<=THIS-OBJECT:epoch() AND webhookValue:GetInteger('attempts')<6 THEN DO:
     leaseValue=LC(HEX-ENCODE(GENERATE-UUID)). webhookValue:Set('status','running').
     IF webhookValue:Has('lease') THEN webhookValue:Set('lease',leaseValue). ELSE webhookValue:Add('lease',leaseValue).
     IF webhookValue:Has('leaseExpires') THEN webhookValue:Set('leaseExpires',THIS-OBJECT:epoch() + 900). ELSE webhookValue:Add('leaseExpires',THIS-OBJECT:epoch() + 900).
     webhookValue:Set('attempts',webhookValue:GetInteger('attempts') + 1). THIS-OBJECT:save(jobValue). RETURN jobValue.
    END. DELETE OBJECT jobValue.
   END. RETURN THIS-OBJECT:errorValue('QUEUE_EMPTY').
   FINALLY: IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released). IF VALID-OBJECT(allIds) THEN DELETE OBJECT allIds. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject completeWebhook(INPUT idValue AS CHARACTER,INPUT leaseValue AS CHARACTER,INPUT retryValue AS LOGICAL):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO. DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1. DEFINE VARIABLE released AS LOGICAL NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO. DEFINE VARIABLE webhookValue AS JsonObject NO-UNDO. DEFINE VARIABLE delayValue AS INTEGER NO-UNDO EXTENT INITIAL [0,60,300,900,3600,21600].
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock). IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY'). jobValue=THIS-OBJECT:getJob(idValue).
   IF NOT jobValue:Has('webhook') THEN RETURN THIS-OBJECT:errorValue('LEASE_LOST'). webhookValue=jobValue:GetJsonObject('webhook'). IF webhookValue:GetCharacter('status')<>'running' OR NOT COMPARE(webhookValue:GetCharacter('lease'),'EQ',leaseValue,'RAW') THEN RETURN THIS-OBJECT:errorValue('LEASE_LOST').
   IF retryValue AND webhookValue:GetInteger('attempts')<6 THEN DO: webhookValue:Set('status','queued'). webhookValue:Set('nextEpoch',THIS-OBJECT:epoch() + delayValue[webhookValue:GetInteger('attempts')]). END. ELSE webhookValue:Set('status',IF retryValue THEN 'failed' ELSE 'delivered').
   THIS-OBJECT:save(jobValue). RETURN jobValue.
   FINALLY: IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released). IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject failJob(INPUT idValue AS CHARACTER,INPUT codeValue AS CHARACTER,INPUT messageValue AS CHARACTER,INPUT detailValue AS CHARACTER,INPUT contextText AS LONGCHAR):
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE lockDescriptor AS INTEGER NO-UNDO INITIAL -1.
  DEFINE VARIABLE released AS LOGICAL NO-UNDO.
  DEFINE VARIABLE jobValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerQueueLock.p('acquire',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT ownsLock).
   IF NOT ownsLock THEN RETURN THIS-OBJECT:errorValue('QUEUE_BUSY').
   jobValue=THIS-OBJECT:getJob(idValue).
   IF jobValue:GetCharacter('status')<>'running' OR NOT COMPARE(jobValue:GetCharacter('lease'),'EQ',claimLease,'RAW') OR NOT COMPARE(idValue,'EQ',claimId,'RAW') THEN RETURN THIS-OBJECT:errorValue('LEASE_LOST').
   jobValue:Set('status',IF jobValue:GetInteger('attempts')<3 THEN 'queued' ELSE 'failed'). THIS-OBJECT:save(jobValue). RETURN jobValue.
   FINALLY: IF ownsLock THEN RUN QueryConsumerQueueLock.p('release',rootValue + '/queue',INPUT-OUTPUT lockDescriptor,OUTPUT released). END FINALLY.
  END.
 END METHOD.
END CLASS.
