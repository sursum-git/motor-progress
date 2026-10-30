USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.

/* Builds server-configured partitions. Consumer input never selects the strategy or worker count. */
CLASS DynamicQueryConsumerParallelJobs:
 METHOD PUBLIC LOGICAL hasSafePartitionLimits(INPUT parallelValue AS JsonObject):
  DEFINE VARIABLE recordLimitValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE partitionBytesValue AS INT64 NO-UNDO.
  DEFINE VARIABLE resultBytesValue AS INT64 NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT VALID-OBJECT(parallelValue) THEN RETURN FALSE.
   IF NOT parallelValue:Has('maxPartitionRecords') OR NOT parallelValue:Has('maxPartitionBytes') OR NOT parallelValue:Has('maxResultBytes') THEN RETURN FALSE.
   recordLimitValue=parallelValue:GetInteger('maxPartitionRecords').
   partitionBytesValue=parallelValue:GetInt64('maxPartitionBytes').
   resultBytesValue=parallelValue:GetInt64('maxResultBytes').
   IF recordLimitValue<1 OR recordLimitValue>1000000 THEN RETURN FALSE.
   IF partitionBytesValue<1048576 OR partitionBytesValue>1073741824 THEN RETURN FALSE.
   IF resultBytesValue<partitionBytesValue OR resultBytesValue>10737418240 THEN RETURN FALSE.
   RETURN TRUE.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PRIVATE INT64 epoch():
  RETURN INTERVAL(NOW,DATETIME-TZ(DATE(1,1,1970),0,0),'seconds').
 END METHOD.
 METHOD PRIVATE CHARACTER two(INPUT numberValue AS INTEGER):
  RETURN IF numberValue < 10 THEN '0' + STRING(numberValue) ELSE STRING(numberValue).
 END METHOD.
 METHOD PRIVATE DATE parseIsoDate(INPUT textValue AS CHARACTER):
  IF textValue=? OR LENGTH(textValue)<>10 OR SUBSTRING(textValue,5,1)<>'-' OR SUBSTRING(textValue,8,1)<>'-' THEN UNDO,THROW NEW Progress.Lang.AppError('INVALID_PARALLEL_DATE',0).
  RETURN DATE(INTEGER(SUBSTRING(textValue,6,2)),INTEGER(SUBSTRING(textValue,9,2)),INTEGER(SUBSTRING(textValue,1,4))).
 END METHOD.
 METHOD PRIVATE CHARACTER isoDate(INPUT valueDate AS DATE):
  RETURN STRING(YEAR(valueDate)) + '-' + THIS-OBJECT:two(MONTH(valueDate)) + '-' + THIS-OBJECT:two(DAY(valueDate)).
 END METHOD.
 METHOD PUBLIC JsonArray dateDayPartitions(INPUT parallelValue AS JsonObject,INPUT requestValue AS JsonObject):
  DEFINE VARIABLE partitionValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE itemValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE startName AS CHARACTER NO-UNDO.
  DEFINE VARIABLE endName AS CHARACTER NO-UNDO.
  DEFINE VARIABLE currentDate AS DATE NO-UNDO.
  DEFINE VARIABLE finalDate AS DATE NO-UNDO.
  DEFINE VARIABLE maximum AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT parallelValue:GetLogical('enabled') OR NOT parallelValue:Has('partition') OR parallelValue:GetType('partition')<>JsonDataType:OBJECT THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_DISABLED',0).
   partitionValue=parallelValue:GetJsonObject('partition').
   IF partitionValue:GetCharacter('strategy')<>'date-day' THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_STRATEGY_INVALID',0).
   startName=partitionValue:GetCharacter('startParameter'). endName=partitionValue:GetCharacter('endParameter').
   IF NOT requestValue:Has(startName) OR NOT requestValue:Has(endName) OR requestValue:GetType(startName)<>JsonDataType:STRING OR requestValue:GetType(endName)<>JsonDataType:STRING THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_DATE_RANGE_REQUIRED',0).
   currentDate=THIS-OBJECT:parseIsoDate(requestValue:GetCharacter(startName)). finalDate=THIS-OBJECT:parseIsoDate(requestValue:GetCharacter(endName)).
   IF currentDate>finalDate THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_DATE_RANGE_INVALID',0).
   maximum=parallelValue:GetInteger('maxPartitions'). resultValue=NEW JsonArray().
   DO WHILE currentDate<=finalDate:
    IF resultValue:Length>=maximum THEN UNDO,THROW NEW Progress.Lang.AppError('PARALLEL_PARTITION_LIMIT',0).
    itemValue=NEW JsonObject(). itemValue:Add(startName,THIS-OBJECT:isoDate(currentDate)). itemValue:Add(endName,THIS-OBJECT:isoDate(currentDate)). resultValue:Add(itemValue). currentDate=currentDate + 1.
   END.
   RETURN resultValue.
  END.
 END METHOD.
 METHOD PUBLIC LOGICAL initializePlan(INPUT rootValue AS CHARACTER,INPUT jobIdValue AS CHARACTER,INPUT partitionsValue AS JsonArray,INPUT maxWorkersValue AS INTEGER):
  DEFINE VARIABLE planValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE itemValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF rootValue=? OR rootValue='' THEN RETURN FALSE.
  OS-CREATE-DIR VALUE(rootValue) NO-ERROR.
  IF maxWorkersValue<1 OR maxWorkersValue>10 OR partitionsValue:Length<1 OR partitionsValue:Length>2000 THEN RETURN FALSE.
  pathValue=rootValue + '/' + jobIdValue + '.parallel.json'.
  DO n=1 TO partitionsValue:Length:
   itemValue=partitionsValue:GetJsonObject(n).
   itemValue:Add('partitionId',n). itemValue:Add('status','queued').
  END.
  planValue=NEW JsonObject(). planValue:Add('version',1). planValue:Add('jobId',jobIdValue). planValue:Add('maxWorkers',maxWorkersValue).
  planValue:Add('totalPartitions',partitionsValue:Length). planValue:Add('completedPartitions',0). planValue:Add('runningPartitions',0). planValue:Add('failedPartitions',0). planValue:Add('partitions',partitionsValue).
  RETURN planValue:WriteFile(pathValue,FALSE).
 END METHOD.
 METHOD PUBLIC JsonObject readPlan(INPUT rootValue AS CHARACTER,INPUT jobIdValue AS CHARACTER):
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO. DEFINE VARIABLE parsedValue AS JsonConstruct NO-UNDO.
  parserValue=NEW ObjectModelParser(). parsedValue=parserValue:ParseFile(rootValue + '/' + jobIdValue + '.parallel.json').
  RETURN CAST(parsedValue,JsonObject).
 END METHOD.
 METHOD PUBLIC LOGICAL savePlan(INPUT rootValue AS CHARACTER,INPUT jobIdValue AS CHARACTER,INPUT planValue AS JsonObject):
  DEFINE VARIABLE temporaryValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE replaced AS LOGICAL NO-UNDO.
  IF rootValue=? OR rootValue='' OR jobIdValue=? OR jobIdValue='' OR NOT VALID-OBJECT(planValue) THEN RETURN FALSE.
  temporaryValue=rootValue + '/' + jobIdValue + '.' + LC(HEX-ENCODE(GENERATE-UUID)) + '.parallel.tmp'.
  DO ON ERROR UNDO, THROW:
   IF NOT planValue:WriteFile(temporaryValue,FALSE) THEN RETURN FALSE.
   RUN QueryConsumerConfigIo.p('replace',rootValue + '/' + jobIdValue + '.parallel.json',temporaryValue,OUTPUT replaced).
   RETURN replaced.
   FINALLY: OS-DELETE VALUE(temporaryValue) NO-ERROR. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject claimPartition(INPUT planValue AS JsonObject,INPUT leaseSeconds AS INTEGER):
  DEFINE VARIABLE partitionsValue AS JsonArray NO-UNDO. DEFINE VARIABLE itemValue AS JsonObject NO-UNDO. DEFINE VARIABLE resultValue AS JsonObject NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE runningValue AS INTEGER NO-UNDO.
  partitionsValue=planValue:GetJsonArray('partitions').
  DO n=1 TO partitionsValue:Length:
   itemValue=partitionsValue:GetJsonObject(n).
   IF itemValue:GetCharacter('status')='running' AND itemValue:Has('leaseExpires') AND itemValue:GetInt64('leaseExpires')<=THIS-OBJECT:epoch() THEN itemValue:Set('status','queued').
   IF itemValue:GetCharacter('status')='running' THEN runningValue = runningValue + 1.
  END.
  resultValue=NEW JsonObject(). resultValue:Add('success',FALSE).
  IF runningValue>=planValue:GetInteger('maxWorkers') THEN RETURN resultValue.
  DO n=1 TO partitionsValue:Length:
   itemValue=partitionsValue:GetJsonObject(n).
   IF itemValue:GetCharacter('status')='queued' THEN DO:
    itemValue:Set('status','running').
    IF itemValue:Has('lease') THEN itemValue:Set('lease',LC(HEX-ENCODE(GENERATE-UUID))). ELSE itemValue:Add('lease',LC(HEX-ENCODE(GENERATE-UUID))).
    IF itemValue:Has('leaseExpires') THEN itemValue:Set('leaseExpires',THIS-OBJECT:epoch() + leaseSeconds). ELSE itemValue:Add('leaseExpires',THIS-OBJECT:epoch() + leaseSeconds).
    planValue:Set('runningPartitions',runningValue + 1). resultValue:Set('success',TRUE). resultValue:Add('partition',CAST(itemValue:Clone(),JsonObject)). RETURN resultValue.
   END.
  END.
  RETURN resultValue.
 END METHOD.
 METHOD PUBLIC LOGICAL completePartition(INPUT planValue AS JsonObject,INPUT partitionIdValue AS INTEGER,INPUT leaseValue AS CHARACTER,INPUT succeededValue AS LOGICAL,INPUT failureCodeValue AS CHARACTER):
  DEFINE VARIABLE partitionsValue AS JsonArray NO-UNDO. DEFINE VARIABLE itemValue AS JsonObject NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
  partitionsValue=planValue:GetJsonArray('partitions').
  DO n=1 TO partitionsValue:Length:
   itemValue=partitionsValue:GetJsonObject(n).
   IF itemValue:GetInteger('partitionId')<>partitionIdValue THEN NEXT.
   IF itemValue:GetCharacter('status')<>'running' OR NOT COMPARE(itemValue:GetCharacter('lease'),'EQ',leaseValue,'RAW') THEN RETURN FALSE.
   itemValue:Set('status',IF succeededValue THEN 'completed' ELSE 'failed').
   IF NOT succeededValue THEN DO:
    IF itemValue:Has('failureCode') THEN itemValue:Set('failureCode',failureCodeValue). ELSE itemValue:Add('failureCode',failureCodeValue).
   END.
   planValue:Set('runningPartitions',MAXIMUM(0,planValue:GetInteger('runningPartitions') - 1)).
   IF succeededValue THEN planValue:Set('completedPartitions',planValue:GetInteger('completedPartitions') + 1).
   ELSE planValue:Set('failedPartitions',planValue:GetInteger('failedPartitions') + 1).
   RETURN TRUE.
  END.
  RETURN FALSE.
 END METHOD.
END CLASS.
