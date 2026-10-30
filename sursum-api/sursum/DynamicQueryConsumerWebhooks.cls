USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Private per-consumer/per-query webhook registry. It never returns a stored secret. */
CLASS DynamicQueryConsumerWebhooks:
 METHOD PRIVATE LOGICAL exact(INPUT a AS CHARACTER,INPUT b AS CHARACTER):
  RETURN a<>? AND b<>? AND LENGTH(a,"RAW")=LENGTH(b,"RAW") AND COMPARE(a,"EQ",b,"RAW").
 END METHOD.
 METHOD PRIVATE LOGICAL identifier(INPUT valueText AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF valueText=? OR LENGTH(valueText)=0 OR LENGTH(valueText)>128 OR valueText="." OR valueText=".." THEN RETURN FALSE.
  DO n=1 TO LENGTH(valueText): IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-",SUBSTRING(valueText,n,1))=0 THEN RETURN FALSE. END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE JsonObject reply(INPUT successValue AS LOGICAL,INPUT codeValue AS CHARACTER):
  DEFINE VARIABLE replyValue AS JsonObject NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
  replyValue=NEW JsonObject(). replyValue:Add('success',successValue).
  IF NOT successValue THEN DO: errorValue=NEW JsonObject(). errorValue:Add('code',codeValue). replyValue:Add('error',errorValue). END.
  RETURN replyValue.
 END METHOD.
 METHOD PRIVATE CHARACTER path(INPUT cfg AS JsonObject):
  IF NOT cfg:Has('accessTokenStore') OR cfg:GetType('accessTokenStore')<>JsonDataType:STRING THEN RETURN ''.
  RETURN cfg:GetCharacter('accessTokenStore') + '.webhooks'.
 END METHOD.
 METHOD PRIVATE JsonObject load(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO. DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO. DEFINE VARIABLE storeValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   FILE-INFO:FILE-NAME=pathValue.
   IF FILE-INFO:FULL-PATHNAME=? THEN DO: storeValue=NEW JsonObject(). storeValue:Add('version',1). storeValue:Add('webhooks',NEW JsonArray()). RETURN storeValue. END.
   IF FILE-INFO:FILE-SIZE=? OR FILE-INFO:FILE-SIZE>1048576 THEN RETURN ?.
   parser=NEW ObjectModelParser(). parsed=parser:ParseFile(pathValue).
   IF NOT TYPE-OF(parsed,JsonObject) THEN RETURN ?.
   storeValue=CAST(parsed,JsonObject). IF storeValue:GetInteger('version')<>1 OR storeValue:GetJsonArray('webhooks'):Length>1000 THEN RETURN ?.
   RETURN storeValue.
   CATCH err AS Progress.Lang.Error: RETURN ?. END CATCH.
   FINALLY: IF VALID-OBJECT(parser) THEN DELETE OBJECT parser. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL permitted(INPUT cfg AS JsonObject,INPUT ownerValue AS CHARACTER,INPUT codeValue AS CHARACTER,INPUT nowValue AS INT64):
  DEFINE VARIABLE entries AS JsonArray NO-UNDO. DEFINE VARIABLE entryValue AS JsonObject NO-UNDO. DEFINE VARIABLE codes AS JsonArray NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   entries=cfg:GetJsonArray('consumers'). DO i=1 TO entries:Length:
    entryValue=entries:GetJsonObject(i). IF NOT THIS-OBJECT:exact(entryValue:GetCharacter('id'),ownerValue) THEN NEXT.
    IF entryValue:GetCharacter('role')<>'consumer' OR NOT entryValue:GetLogical('active') OR entryValue:GetInt64('expiresAtEpoch')<=nowValue THEN RETURN FALSE.
    codes=entryValue:GetJsonArray('queries'). DO j=1 TO codes:Length: IF THIS-OBJECT:exact(codes:GetCharacter(j),codeValue) THEN RETURN TRUE. END. RETURN FALSE.
   END. RETURN FALSE.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PRIVATE CHARACTER randomSecret():
  DEFINE VARIABLE algorithmValue AS CHARACTER NO-UNDO. DEFINE VARIABLE rawValue AS RAW NO-UNDO.
  algorithmValue=SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM.
  DO ON ERROR UNDO, THROW:
   SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM='AES_CBC_256'. rawValue=GENERATE-RANDOM-KEY.
   RETURN LC(STRING(HEX-ENCODE(rawValue))).
   FINALLY: SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM=algorithmValue. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject execute(INPUT configFile AS CHARACTER,INPUT methodValue AS CHARACTER,INPUT bodyValue AS LONGCHAR,INPUT queryValue AS CHARACTER,INPUT ownerValue AS CHARACTER,INPUT nowValue AS INT64,OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO. DEFINE VARIABLE cfg AS JsonObject NO-UNDO. DEFINE VARIABLE registry AS DynamicQueryConsumerRegistry NO-UNDO. DEFINE VARIABLE requestValue AS JsonObject NO-UNDO. DEFINE VARIABLE store AS JsonObject NO-UNDO. DEFINE VARIABLE entries AS JsonArray NO-UNDO. DEFINE VARIABLE entryValue AS JsonObject NO-UNDO. DEFINE VARIABLE resultValue AS JsonObject NO-UNDO. DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO. DEFINE VARIABLE urlValue AS CHARACTER NO-UNDO. DEFINE VARIABLE storePath AS CHARACTER NO-UNDO. DEFINE VARIABLE tempValue AS CHARACTER NO-UNDO. DEFINE VARIABLE hasConfigLock AS LOGICAL NO-UNDO. DEFINE VARIABLE written AS LOGICAL NO-UNDO. DEFINE VARIABLE entryIndex AS INTEGER NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
  statusValue=503.
  DO ON ERROR UNDO, THROW:
   policy=NEW DynamicQueryConsumerPolicy(). cfg=policy:loadConfig(configFile). IF NOT policy:isValid(cfg) THEN RETURN THIS-OBJECT:reply(FALSE,'SECURITY_UNAVAILABLE').
   IF methodValue='GET' THEN DO:
    IF INDEX(queryValue,'=')=0 OR NUM-ENTRIES(queryValue,'=')<>2 OR ENTRY(1,queryValue,'=')<>'code' THEN DO: statusValue=400. RETURN THIS-OBJECT:reply(FALSE,'INVALID_WEBHOOK_REQUEST'). END.
    codeValue=ENTRY(2,queryValue,'='). IF NOT THIS-OBJECT:identifier(codeValue) THEN DO: statusValue=400. RETURN THIS-OBJECT:reply(FALSE,'INVALID_WEBHOOK_REQUEST'). END.
   END.
   ELSE DO:
    registry=NEW DynamicQueryConsumerRegistry(). requestValue=registry:parseRequest(bodyValue). IF NOT VALID-OBJECT(requestValue) OR NOT requestValue:Has('code') OR requestValue:GetType('code')<>JsonDataType:STRING THEN DO: statusValue=400. RETURN THIS-OBJECT:reply(FALSE,'INVALID_WEBHOOK_REQUEST'). END.
    codeValue=requestValue:GetCharacter('code').
    names=requestValue:GetNames(). IF NOT THIS-OBJECT:identifier(codeValue) OR (methodValue='PUT' AND (EXTENT(names)<>2 OR NOT requestValue:Has('url') OR requestValue:GetType('url')<>JsonDataType:STRING)) OR (methodValue='DELETE' AND EXTENT(names)<>1) THEN DO: statusValue=400. RETURN THIS-OBJECT:reply(FALSE,'INVALID_WEBHOOK_REQUEST'). END.
    IF methodValue='PUT' THEN urlValue=requestValue:GetCharacter('url').
   END.
   IF NOT THIS-OBJECT:permitted(cfg,ownerValue,codeValue,nowValue) THEN DO: statusValue=403. RETURN THIS-OBJECT:reply(FALSE,'QUERY_FORBIDDEN'). END.
   storePath=THIS-OBJECT:path(cfg). IF storePath='' THEN RETURN THIS-OBJECT:reply(FALSE,'SECURITY_UNAVAILABLE').
   RUN QueryConsumerConfigIo.p('acquire',storePath,'',OUTPUT hasConfigLock). IF NOT hasConfigLock THEN DO: statusValue=409. RETURN THIS-OBJECT:reply(FALSE,'CONFIG_BUSY'). END.
   store=THIS-OBJECT:load(storePath). IF NOT VALID-OBJECT(store) THEN RETURN THIS-OBJECT:reply(FALSE,'SECURITY_UNAVAILABLE'). entries=store:GetJsonArray('webhooks').
   DO n=1 TO entries:Length: IF THIS-OBJECT:exact(entries:GetJsonObject(n):GetCharacter('consumerId'),ownerValue) AND THIS-OBJECT:exact(entries:GetJsonObject(n):GetCharacter('code'),codeValue) THEN DO: entryValue=entries:GetJsonObject(n). entryIndex=n. END. END.
   IF methodValue='GET' THEN DO:
    IF NOT VALID-OBJECT(entryValue) THEN DO: statusValue=404. RETURN THIS-OBJECT:reply(FALSE,'WEBHOOK_NOT_FOUND'). END.
    resultValue=THIS-OBJECT:reply(TRUE,''). resultValue:Add('code',codeValue). resultValue:Add('url',entryValue:GetCharacter('url')). resultValue:Add('version',entryValue:GetInteger('version')). resultValue:Add('active',TRUE). statusValue=200. RETURN resultValue.
   END.
   IF methodValue='DELETE' THEN DO:
    IF NOT VALID-OBJECT(entryValue) THEN DO: statusValue=404. RETURN THIS-OBJECT:reply(FALSE,'WEBHOOK_NOT_FOUND'). END.
    entries:Remove(entryIndex). tempValue=storePath + '.' + HEX-ENCODE(GENERATE-UUID) + '.tmp'. IF NOT store:WriteFile(tempValue,TRUE) THEN RETURN THIS-OBJECT:reply(FALSE,'WRITE_FAILED'). RUN QueryConsumerConfigIo.p('replace',storePath,tempValue,OUTPUT written). IF NOT written THEN RETURN THIS-OBJECT:reply(FALSE,'WRITE_FAILED'). statusValue=204. RETURN THIS-OBJECT:reply(TRUE,'').
   END.
   /* URL syntax/public-address verification is repeated by the worker before every delivery. */
   IF NOT (CAPS(SUBSTRING(urlValue,1,8))='HTTPS://' AND INDEX(urlValue,'@')=0 AND INDEX(urlValue,'#')=0) THEN DO: statusValue=400. RETURN THIS-OBJECT:reply(FALSE,'INVALID_WEBHOOK_URL'). END.
   IF VALID-OBJECT(entryValue) THEN DO: entryValue:Set('url',urlValue). entryValue:Set('version',entryValue:GetInteger('version') + 1). entryValue:Set('secret',THIS-OBJECT:randomSecret()). END.
   ELSE DO: entryValue=NEW JsonObject(). entryValue:Add('consumerId',ownerValue). entryValue:Add('code',codeValue). entryValue:Add('url',urlValue). entryValue:Add('version',1). entryValue:Add('secret',THIS-OBJECT:randomSecret()). entries:Add(entryValue). END.
   tempValue=storePath + '.' + HEX-ENCODE(GENERATE-UUID) + '.tmp'. IF NOT store:WriteFile(tempValue,TRUE) THEN RETURN THIS-OBJECT:reply(FALSE,'WRITE_FAILED'). RUN QueryConsumerConfigIo.p('replace',storePath,tempValue,OUTPUT written). IF NOT written THEN RETURN THIS-OBJECT:reply(FALSE,'WRITE_FAILED').
   resultValue=THIS-OBJECT:reply(TRUE,''). resultValue:Add('code',codeValue). resultValue:Add('url',urlValue). resultValue:Add('version',entryValue:GetInteger('version')). resultValue:Add('webhook_secret',entryValue:GetCharacter('secret')). statusValue=200. RETURN resultValue.
   CATCH err AS Progress.Lang.Error: statusValue=503. RETURN THIS-OBJECT:reply(FALSE,'WEBHOOK_UNAVAILABLE'). END CATCH.
   FINALLY: IF tempValue<>'' THEN OS-DELETE VALUE(tempValue). IF hasConfigLock THEN RUN QueryConsumerConfigIo.p('release',storePath,'',OUTPUT written). IF VALID-OBJECT(policy) THEN DELETE OBJECT policy. IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg. IF VALID-OBJECT(registry) THEN DELETE OBJECT registry. IF VALID-OBJECT(store) THEN DELETE OBJECT store. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC VOID queueForJob(INPUT configValue AS JsonObject,INPUT jobIdValue AS CHARACTER,INPUT ownerValue AS CHARACTER,INPUT codeValue AS CHARACTER,INPUT deliveryValue AS CHARACTER):
  DEFINE VARIABLE store AS JsonObject NO-UNDO. DEFINE VARIABLE entries AS JsonArray NO-UNDO. DEFINE VARIABLE entryValue AS JsonObject NO-UNDO. DEFINE VARIABLE taskValue AS JsonObject NO-UNDO. DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO. DEFINE VARIABLE storePath AS CHARACTER NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   storePath=THIS-OBJECT:path(configValue). IF storePath='' THEN RETURN. store=THIS-OBJECT:load(storePath). IF NOT VALID-OBJECT(store) THEN RETURN. entries=store:GetJsonArray('webhooks').
   DO n=1 TO entries:Length: IF THIS-OBJECT:exact(entries:GetJsonObject(n):GetCharacter('consumerId'),ownerValue) AND THIS-OBJECT:exact(entries:GetJsonObject(n):GetCharacter('code'),codeValue) THEN entryValue=entries:GetJsonObject(n). END.
   IF NOT VALID-OBJECT(entryValue) THEN RETURN.
   taskValue=NEW JsonObject(). taskValue:Add('consumerId',ownerValue). taskValue:Add('code',codeValue). taskValue:Add('url',entryValue:GetCharacter('url')). taskValue:Add('secret',entryValue:GetCharacter('secret')). taskValue:Add('version',entryValue:GetInteger('version')). taskValue:Add('delivery',IF LOOKUP(deliveryValue,'full,manifest')>0 THEN deliveryValue ELSE 'full').
   repositoryValue=NEW DynamicQueryConsumerJobRepository(configValue:GetCharacter('accessTokenStore') + '.jobs'). repositoryValue:queueWebhook(jobIdValue,taskValue).
   FINALLY: IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue. IF VALID-OBJECT(store) THEN DELETE OBJECT store. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject claim(INPUT configValue AS JsonObject,OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO. DEFINE VARIABLE jobValue AS JsonObject NO-UNDO. DEFINE VARIABLE taskValue AS JsonObject NO-UNDO. DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO. DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO. DEFINE VARIABLE manifestValue AS JsonObject NO-UNDO. DEFINE VARIABLE resultValue AS JsonObject NO-UNDO. DEFINE VARIABLE payloadText AS LONGCHAR NO-UNDO.
  statusValue=503.
  DO ON ERROR UNDO, THROW:
   repositoryValue=NEW DynamicQueryConsumerJobRepository(configValue:GetCharacter('accessTokenStore') + '.jobs'). jobValue=repositoryValue:claimWebhookNext(). IF NOT jobValue:GetLogical('success') THEN DO: statusValue=204. RETURN NEW JsonObject(). END.
   taskValue=jobValue:GetJsonObject('webhook').
   resultValue=NEW JsonObject(). resultValue:Add('success',TRUE). resultValue:Add('jobId',jobValue:GetCharacter('jobId')). resultValue:Add('lease',jobValue:GetJsonObject('webhook'):GetCharacter('lease')). resultValue:Add('url',taskValue:GetCharacter('url')). resultValue:Add('secret',taskValue:GetCharacter('secret')).
   IF taskValue:Has('delivery') AND taskValue:GetCharacter('delivery')='manifest' AND jobValue:Has('resultFormat') AND jobValue:GetCharacter('resultFormat')='ndjson+gzip' THEN DO:
    manifestValue=NEW JsonObject(). manifestValue:Add('jobId',jobValue:GetCharacter('jobId')). manifestValue:Add('format','ndjson+gzip'). manifestValue:Add('bytes',jobValue:GetInt64('resultBytes')). manifestValue:Add('sha256',jobValue:GetCharacter('resultSha256')). manifestValue:Add('recordsReturned',jobValue:GetInteger('recordsReturned')). manifestValue:Add('resultUrl','https://iol.imatextil.com.br/query-progress/api/job-result.php?jobId=' + jobValue:GetCharacter('jobId')). resultValue:Add('payload',manifestValue). statusValue=200. RETURN resultValue.
   END.
   IF taskValue:Has('delivery') AND taskValue:GetCharacter('delivery')='full' AND jobValue:Has('resultFormat') AND jobValue:GetCharacter('resultFormat')='ndjson+gzip' THEN DO:
    resultValue:Add('artifactPath','/consumer-jobs/' + jobValue:GetCharacter('jobId') + '/result'). resultValue:Add('contentType','application/x-ndjson'). resultValue:Add('contentEncoding','gzip'). resultValue:Add('resultBytes',jobValue:GetInt64('resultBytes')). statusValue=200. RETURN resultValue.
   END.
   FIX-CODEPAGE(payloadText)='UTF-8'. COPY-LOB FROM FILE jobValue:GetCharacter('resultPath') TO payloadText. IF ERROR-STATUS:ERROR THEN RETURN ?.
   parser=NEW ObjectModelParser(). parsed=parser:Parse(payloadText). IF NOT TYPE-OF(parsed,JsonObject) THEN RETURN ?.
   resultValue:Add('payload',CAST(parsed,JsonObject)). statusValue=200. RETURN resultValue.
   CATCH err AS Progress.Lang.Error: statusValue=503. RETURN THIS-OBJECT:reply(FALSE,'WEBHOOK_UNAVAILABLE'). END CATCH.
   FINALLY: IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue. IF VALID-OBJECT(jobValue) THEN DELETE OBJECT jobValue. IF VALID-OBJECT(parser) THEN DELETE OBJECT parser. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject complete(INPUT configValue AS JsonObject,INPUT bodyValue AS LONGCHAR,OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE registry AS DynamicQueryConsumerRegistry NO-UNDO. DEFINE VARIABLE requestValue AS JsonObject NO-UNDO. DEFINE VARIABLE repositoryValue AS DynamicQueryConsumerJobRepository NO-UNDO. DEFINE VARIABLE replyValue AS JsonObject NO-UNDO.
  statusValue=400.
  DO ON ERROR UNDO, THROW:
   registry=NEW DynamicQueryConsumerRegistry(). requestValue=registry:parseRequest(bodyValue). IF NOT VALID-OBJECT(requestValue) OR NOT requestValue:Has('jobId') OR NOT requestValue:Has('lease') OR NOT requestValue:Has('retry') OR requestValue:GetType('jobId')<>JsonDataType:STRING OR requestValue:GetType('lease')<>JsonDataType:STRING OR requestValue:GetType('retry')<>JsonDataType:BOOLEAN THEN RETURN THIS-OBJECT:reply(FALSE,'INVALID_WEBHOOK_REQUEST').
   repositoryValue=NEW DynamicQueryConsumerJobRepository(configValue:GetCharacter('accessTokenStore') + '.jobs'). replyValue=repositoryValue:completeWebhook(requestValue:GetCharacter('jobId'),requestValue:GetCharacter('lease'),requestValue:GetLogical('retry')). statusValue=IF replyValue:GetLogical('success') THEN 200 ELSE 409. RETURN replyValue.
   CATCH err AS Progress.Lang.Error: statusValue=503. RETURN THIS-OBJECT:reply(FALSE,'WEBHOOK_UNAVAILABLE'). END CATCH.
   FINALLY: IF VALID-OBJECT(registry) THEN DELETE OBJECT registry. IF VALID-OBJECT(repositoryValue) THEN DELETE OBJECT repositoryValue. END FINALLY.
  END.
 END METHOD.
END CLASS.
