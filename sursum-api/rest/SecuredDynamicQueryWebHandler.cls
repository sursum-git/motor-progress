USING Progress.Json.ObjectModel.*.
USING OpenEdge.Web.WebResponse.
USING OpenEdge.Web.WebResponseWriter.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* MED maps to this wrapper. Other applications keep their existing handler. */
CLASS SecuredDynamicQueryWebHandler INHERITS DynamicQueryWebHandler:
 DEFINE PRIVATE VARIABLE cursorConfig AS JsonObject NO-UNDO.
 DEFINE PRIVATE VARIABLE cursorNow AS INT64 NO-UNDO.
 METHOD OVERRIDE PROTECTED JsonObject executeStoredQueryService(INPUT poBody AS JsonObject, INPUT poDefinition AS JsonObject, INPUT poModel AS DynamicQueryRequestModel,
  INPUT poService AS DynamicMultiTableQueryService, INPUT poContext AS PasoeExecutionContext):
  DEFINE VARIABLE pagination AS DynamicQueryConsumerPagination NO-UNDO.
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE generationValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE jobsValue AS DynamicQueryConsumerJobs NO-UNDO.
  DEFINE VARIABLE loadedDefinitionValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parameterValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE querystringValue AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   pagination=NEW DynamicQueryConsumerPagination().
   /* This high-volume MED query must always be bounded by date or product. */
   IF cAuthenticatedConsumerRole='consumer' AND poBody:Has('code') THEN IF poBody:GetCharacter('code')='movimentacoes-estoque' THEN DO:
    IF poBody:Has('parameters') THEN parameterValue=poBody:GetJsonObject('parameters').
    IF VALID-OBJECT(parameterValue) THEN IF parameterValue:Has('querystring') THEN querystringValue=parameterValue:GetJsonObject('querystring').
    IF NOT VALID-OBJECT(querystringValue) OR (NOT querystringValue:Has('dataInicial') AND NOT querystringValue:Has('produto')) THEN DO:
     resultValue=NEW JsonObject(). errorValue=NEW JsonObject(). resultValue:Add('success',FALSE).
     errorValue:Add('code','REQUIRED_EXTERNAL_FILTER_MISSING'). errorValue:Add('status',400). errorValue:Add('message','Informe dataInicial ou produto.'). resultValue:Add('error',errorValue). THIS-OBJECT:setConsumerQueryStatus(400). RETURN resultValue.
    END.
   END.
   /* External consumers opt into the owned queue explicitly; saved auto/async never uses the legacy unowned queue. */
   IF cAuthenticatedConsumerRole='consumer' THEN poModel:setExecution('sync').
   IF poBody:Has('execution') THEN IF poBody:GetCharacter('execution')='async' THEN DO:
    /* The generic stored-query pipeline may pass only query. Reload the saved
       definition so optional asyncParallel metadata remains JSON-driven. */
    loadedDefinitionValue=THIS-OBJECT:loadConsumerSavedDefinition(poBody:GetCharacter('code')).
    jobsValue=NEW DynamicQueryConsumerJobs().
    resultValue=jobsValue:enqueue(poModel,poBody,IF VALID-OBJECT(loadedDefinitionValue) THEN loadedDefinitionValue ELSE poDefinition,cursorConfig,cAuthenticatedConsumer,poContext,cursorNow).
    IF resultValue:GetLogical('success') THEN THIS-OBJECT:setConsumerQueryStatus(202).
    ELSE THIS-OBJECT:setConsumerQueryStatus(resultValue:GetJsonObject('error'):GetInteger('status')).
    RETURN resultValue.
   END.
   IF cAuthenticatedConsumerRole<>"consumer" OR NOT pagination:isCursor(poBody) THEN RETURN SUPER:executeStoredQueryService(poBody,poDefinition,poModel,poService,poContext).
   IF NOT pagination:isCursorDefinitionSupported(poDefinition) THEN DO:
    resultValue=NEW JsonObject(). errorValue=NEW JsonObject(). resultValue:Add("success",FALSE).
    errorValue:Add("code","CURSOR_UNSUPPORTED"). errorValue:Add("status",400).
    errorValue:Add("message","Consulta com transformacao incompativel com cursor."). resultValue:Add("error",errorValue).
    THIS-OBJECT:setConsumerQueryStatus(400). RETURN resultValue.
   END.
   IF VALID-OBJECT(cursorConfig) THEN DO:
    IF cursorConfig:Has("accessTokenStore") THEN IF cursorConfig:GetType("accessTokenStore")=JsonDataType:STRING THEN pathValue=cursorConfig:GetCharacter("accessTokenStore") + ".cursor.key".
    entries=cursorConfig:GetJsonArray("consumers").
    DO n=1 TO entries:Length:
     entryValue=entries:GetJsonObject(n).
     IF NOT COMPARE(entryValue:GetCharacter("id"),"EQ",cAuthenticatedConsumer,"RAW") THEN NEXT.
     generationValue=IF entryValue:Has("clientSecretSha256") THEN entryValue:GetCharacter("clientSecretSha256") ELSE entryValue:GetCharacter("tokenSha256").
    END.
   END.
   resultValue=poService:executeCursor(poModel,poBody,poDefinition,cAuthenticatedConsumer,generationValue,pathValue,cursorNow).
   IF NOT resultValue:GetLogical("success") THEN DO:
    errorValue=resultValue:GetJsonObject("error"). THIS-OBJECT:setConsumerQueryStatus(errorValue:GetInteger("status")).
   END.
   RETURN resultValue.
   FINALLY:
    IF VALID-OBJECT(pagination) THEN DELETE OBJECT pagination.
    IF VALID-OBJECT(jobsValue) THEN DELETE OBJECT jobsValue.
    IF VALID-OBJECT(loadedDefinitionValue) THEN DELETE OBJECT loadedDefinitionValue.
    IF VALID-OBJECT(parameterValue) THEN DELETE OBJECT parameterValue.
    IF VALID-OBJECT(querystringValue) THEN DELETE OBJECT querystringValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE JsonObject loadConsumerSavedDefinition(INPUT codeValue AS CHARACTER):
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE configPathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsedValue AS JsonConstruct NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF codeValue=? OR codeValue='' THEN RETURN ?.
   pathValue=SEARCH('sursum-api/querys/' + codeValue + '.json').
   IF pathValue=? OR pathValue='' THEN DO:
    configPathValue=SEARCH('sursum-conf/query-consumers.json').
    IF configPathValue<>? AND configPathValue<>'' THEN
     pathValue=SUBSTRING(configPathValue,1,LENGTH(configPathValue) - LENGTH('sursum-conf/query-consumers.json')) + 'sursum-api/querys/' + codeValue + '.json'.
   END.
   IF pathValue=? OR pathValue='' THEN RETURN ?.
   parserValue=NEW ObjectModelParser(). parsedValue=parserValue:ParseFile(pathValue).
   IF TYPE-OF(parsedValue,JsonObject) THEN RETURN CAST(parsedValue,JsonObject).
   DELETE OBJECT parsedValue. RETURN ?.
   CATCH err AS Progress.Lang.Error:
    RETURN ?.
   END CATCH.
   FINALLY:
    IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue.
   END FINALLY.
  END.
 END METHOD.
 METHOD OVERRIDE PROTECTED JsonObject applyStoredQueryPagination(INPUT poBody AS JsonObject, INPUT poModel AS DynamicQueryRequestModel):
  DEFINE VARIABLE pagination AS DynamicQueryConsumerPagination NO-UNDO.
  IF cAuthenticatedConsumerRole<>"consumer" THEN RETURN ?.
  DO ON ERROR UNDO, THROW:
   pagination=NEW DynamicQueryConsumerPagination().
   lConsumerPaginationEnabled=TRUE.
   IF pagination:isValid(poBody) THEN lConsumerPaginationEnabled=pagination:isPaginated(poBody).
   RETURN pagination:applyPagination(poBody,poModel).
   FINALLY: IF VALID-OBJECT(pagination) THEN DELETE OBJECT pagination. END FINALLY.
  END.
 END METHOD.
 METHOD OVERRIDE PUBLIC INTEGER HandleRequest():
  DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO.
  DEFINE VARIABLE config AS JsonObject NO-UNDO.
  DEFINE VARIABLE decision AS JsonObject NO-UNDO.
  DEFINE VARIABLE responseValue AS WebResponse NO-UNDO.
  DEFINE VARIABLE writerValue AS WebResponseWriter NO-UNDO.
  DEFINE VARIABLE methodValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE headerValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE customToken AS CHARACTER NO-UNDO.
  DEFINE VARIABLE fileValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE bodyValue AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE replyText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE replyBytes AS MEMPTR NO-UNDO.
  DEFINE VARIABLE nowEpoch AS INT64 NO-UNDO.
  DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE registry AS DynamicQueryConsumerRegistry NO-UNDO.
  DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE actionValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE adminRoute AS LOGICAL NO-UNDO.
  DEFINE VARIABLE tokenRoute AS LOGICAL NO-UNDO.
  DEFINE VARIABLE issuer AS DynamicQueryClientCredentials NO-UNDO.
  DEFINE VARIABLE jobsValue AS DynamicQueryConsumerJobs NO-UNDO.
  DEFINE VARIABLE jobRoute AS LOGICAL NO-UNDO.
  DEFINE VARIABLE jobSuffix AS CHARACTER NO-UNDO.
  DEFINE VARIABLE jobOwner AS CHARACTER NO-UNDO.
  DEFINE VARIABLE jobPosition AS INTEGER NO-UNDO.
  DEFINE VARIABLE downloadValue AS LOGICAL NO-UNDO.
  DEFINE VARIABLE webhooksValue AS DynamicQueryConsumerWebhooks NO-UNDO.
  DEFINE VARIABLE webhookRoute AS LOGICAL NO-UNDO.
  DEFINE VARIABLE queryValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE webhookWorkerRoute AS LOGICAL NO-UNDO.
  DEFINE VARIABLE artifactDownload AS LOGICAL NO-UNDO.
  DEFINE VARIABLE artifactPath AS CHARACTER NO-UNDO.
  DEFINE VARIABLE artifactBytes AS INT64 NO-UNDO.
  DEFINE VARIABLE artifactOffset AS INT64 NO-UNDO.
  DEFINE VARIABLE artifactChunk AS INT64 NO-UNDO.
  DEFINE VARIABLE jobAdmin AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   methodValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","REQUEST_METHOD").
   pathValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","PATH_INFO").
   queryValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","QUERY_STRING").
   headerValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_AUTHORIZATION").
   IF headerValue=? OR headerValue="" THEN headerValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","AUTHORIZATION").
   IF headerValue=? OR headerValue="" THEN headerValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","Authorization").
   bodyValue=WEB-CONTEXT:FORM-INPUT.
   policy=NEW DynamicQueryConsumerPolicy().
   customToken=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_SURSUM_QUERY_TOKEN").
   headerValue=policy:credentialHeader(headerValue,customToken).
   customToken="".
   fileValue=OS-GETENV("SURSUM_QUERY_CONSUMERS_FILE").
   IF fileValue=? OR fileValue="" THEN fileValue=SEARCH("sursum-conf/query-consumers.json").
   IF methodValue<>"OPTIONS" THEN config=policy:loadConfig(fileValue).
   nowEpoch=policy:epochSeconds(NOW).
   tokenRoute=pathValue="/SursumDynamicQuery/token".
   issuer=NEW DynamicQueryClientCredentials().
   IF tokenRoute AND methodValue<>"OPTIONS" THEN DO:
    registry=NEW DynamicQueryConsumerRegistry(). requestValue=registry:parseRequest(bodyValue).
    IF methodValue="POST" THEN decision=issuer:issue(fileValue,requestValue,nowEpoch,OUTPUT statusValue).
    ELSE DO: statusValue=405. decision=NEW JsonObject(). decision:Add("error","invalid_request"). END.
   END.
   ELSE DO:
    decision=policy:authorize(config,headerValue,methodValue,pathValue,bodyValue,nowEpoch,OUTPUT statusValue).
    IF statusValue=401 THEN DO:
     DELETE OBJECT decision.
     decision=issuer:authorize(config,fileValue,headerValue,methodValue,pathValue,bodyValue,nowEpoch,OUTPUT statusValue).
     IF NOT decision:Has("success") THEN DO:
      DELETE OBJECT decision. decision=NEW JsonObject(). requestValue=NEW JsonObject().
      requestValue:Add("code",IF statusValue=401 THEN "AUTH_REQUIRED" ELSE "SECURITY_UNAVAILABLE").
      requestValue:Add("message",IF statusValue=401 THEN "Credencial ausente ou invalida." ELSE "Servico de autorizacao indisponivel.").
      decision:Add("success",FALSE). decision:Add("error",requestValue).
     END.
    END.
   END.
   headerValue="".
   adminRoute=pathValue<>? AND LENGTH(pathValue)>=LENGTH("/SursumDynamicQuery/consumers")
    AND SUBSTRING(pathValue,LENGTH(pathValue) - LENGTH("/SursumDynamicQuery/consumers") + 1)="/SursumDynamicQuery/consumers".
   IF statusValue=200 AND adminRoute THEN DO:
    DELETE OBJECT decision.
    registry=NEW DynamicQueryConsumerRegistry().
    /* Consumer policy has already required admin for every non-query route. */
    IF methodValue="GET" THEN actionValue="list".
    ELSE IF methodValue="POST" THEN DO:
     requestValue=registry:parseRequest(bodyValue).
     IF VALID-OBJECT(requestValue) THEN DO:
      IF requestValue:Has("action") THEN IF requestValue:GetType("action")=JsonDataType:STRING THEN actionValue=requestValue:GetCharacter("action").
     END.
    END.
    IF methodValue<>"GET" AND methodValue<>"POST" THEN DO:
     statusValue=405. decision=NEW JsonObject(). decision:Add("success",FALSE).
    END.
    ELSE DO:
     decision=registry:execute(fileValue,actionValue,requestValue,nowEpoch,OUTPUT statusValue).
    END.
    /* Reply below; never delegate admin payloads to the generic execution logger. */
   END.
   webhookRoute=pathValue<>? AND LENGTH(pathValue)>=LENGTH('/SursumDynamicQuery/consumer-webhooks') AND SUBSTRING(pathValue,LENGTH(pathValue) - LENGTH('/SursumDynamicQuery/consumer-webhooks') + 1)='/SursumDynamicQuery/consumer-webhooks'.
   IF statusValue=200 AND webhookRoute THEN DO:
    webhooksValue=NEW DynamicQueryConsumerWebhooks().
    jobOwner=decision:GetCharacter('consumerId'). DELETE OBJECT decision.
    decision=webhooksValue:execute(fileValue,methodValue,bodyValue,queryValue,jobOwner,nowEpoch,OUTPUT statusValue).
   END.
   webhookWorkerRoute=pathValue<>? AND (pathValue='/SursumDynamicQuery/consumer-webhooks/drain' OR pathValue='/SursumDynamicQuery/consumer-webhooks/complete').
   IF statusValue=200 AND webhookWorkerRoute THEN DO:
    IF decision:GetCharacter('role')<>'admin' THEN DO: DELETE OBJECT decision. decision=NEW JsonObject(). decision:Add('success',FALSE). statusValue=403. END.
    ELSE DO:
     DELETE OBJECT decision. webhooksValue=NEW DynamicQueryConsumerWebhooks().
     IF pathValue='/SursumDynamicQuery/consumer-webhooks/drain' AND methodValue='POST' THEN decision=webhooksValue:claim(config,OUTPUT statusValue).
     ELSE IF pathValue='/SursumDynamicQuery/consumer-webhooks/complete' AND methodValue='POST' THEN decision=webhooksValue:complete(config,bodyValue,OUTPUT statusValue).
     ELSE DO: decision=NEW JsonObject(). decision:Add('success',FALSE). statusValue=405. END.
    END.
   END.
   jobPosition=R-INDEX(pathValue,'/SursumDynamicQuery/consumer-jobs/').
   IF statusValue=200 AND NOT webhookRoute AND jobPosition>0 THEN DO:
    jobRoute=TRUE. jobSuffix=SUBSTRING(pathValue,jobPosition + LENGTH('/SursumDynamicQuery/consumer-jobs/')).
    jobOwner=decision:GetCharacter('consumerId'). jobAdmin=decision:GetCharacter('role')='admin'. jobsValue=NEW DynamicQueryConsumerJobs().
    DELETE OBJECT decision.
    IF jobSuffix='drain' AND methodValue='POST' THEN DO:
     /* Policy permits this route only to admin. No caller body selects a job or worker target. */
     decision=jobsValue:drain(fileValue).
     IF NOT decision:GetLogical('success') THEN statusValue=503.
    END.
    ELSE DO:
     downloadValue=LENGTH(jobSuffix)=33 AND SUBSTRING(jobSuffix,27)='/result'.
     IF downloadValue THEN jobSuffix=SUBSTRING(jobSuffix,1,26).
     IF downloadValue THEN DO:
      decision=jobsValue:openParallelArtifact(jobSuffix,config,jobOwner,jobAdmin,nowEpoch,OUTPUT statusValue).
      IF statusValue=200 AND decision:GetLogical('success') THEN DO: artifactDownload=TRUE. artifactPath=decision:GetCharacter('path'). artifactBytes=decision:GetInt64('bytes'). END.
      ELSE IF statusValue=409 THEN decision=jobsValue:readJob(jobSuffix,TRUE,config,jobOwner,nowEpoch,OUTPUT statusValue).
     END.
     ELSE decision=jobsValue:readJob(jobSuffix,FALSE,config,jobOwner,nowEpoch,OUTPUT statusValue).
    END.
   END.
   bodyValue="".
   IF statusValue=200 AND NOT adminRoute AND NOT tokenRoute AND NOT jobRoute AND NOT webhookRoute AND NOT webhookWorkerRoute THEN DO:
    cursorConfig=config. cursorNow=nowEpoch.
    cAuthenticatedConsumer=decision:GetCharacter("consumerId").
    cAuthenticatedConsumerRole=decision:GetCharacter("role").
    /* Authenticated identity is independent of spoofable X-Sursum-User/body fields. */
    LOG-MANAGER:WRITE-MESSAGE("consumer=" + decision:GetCharacter("consumerId") + " role=" + decision:GetCharacter("role") + " query=" + decision:GetCharacter("queryCode"),"QUERY-AUTH").
    RETURN SUPER:HandleRequest().
   END.
   responseValue=NEW WebResponse(statusValue).
   responseValue:SetHeader("Cache-Control","no-store").
   responseValue:SetHeader("Pragma","no-cache").
   IF statusValue=429 THEN responseValue:SetHeader("Retry-After","60").
   responseValue:SetHeader("Access-Control-Allow-Headers","Authorization, X-Sursum-Query-Token, Content-Type, Accept, X-Sursum-User, X-Session-Id").
   responseValue:SetHeader("Access-Control-Allow-Methods","GET, POST, PUT, PATCH, DELETE, OPTIONS").
   IF statusValue=401 THEN responseValue:SetHeader("WWW-Authenticate",'Bearer realm="sursum-query"').
   writerValue=NEW WebResponseWriter(responseValue).
   IF artifactDownload THEN DO:
    responseValue:SetHeader("Content-Type","application/x-ndjson"). responseValue:SetHeader("Content-Encoding","gzip").
    responseValue:SetHeader("Content-Disposition",'attachment; filename="' + jobSuffix + '.ndjson.gz"'). responseValue:SetHeader("Content-Length",STRING(artifactBytes)).
    responseValue:SetHeader("X-Sursum-Result-SHA256",decision:GetCharacter('sha256')).
   END.
   ELSE IF statusValue<>204 THEN responseValue:SetHeader("Content-Type","application/json; charset=UTF-8").
   writerValue:Open().
   IF artifactDownload THEN DO:
    artifactOffset=1.
    DO WHILE artifactOffset<=artifactBytes:
     artifactChunk=MINIMUM(INT64(1048576),artifactBytes - artifactOffset + 1). SET-SIZE(replyBytes)=0.
     COPY-LOB FROM FILE artifactPath STARTING AT artifactOffset FOR artifactChunk TO replyBytes NO-CONVERT.
     writerValue:Write(replyBytes,1,GET-SIZE(replyBytes)). artifactOffset=artifactOffset + artifactChunk.
    END.
   END.
   ELSE IF statusValue<>204 THEN DO:
    FIX-CODEPAGE(replyText)="UTF-8".
    IF jobRoute THEN decision:Write(replyText,FALSE). ELSE decision:Write(replyText).
    COPY-LOB FROM replyText TO replyBytes NO-CONVERT.
    writerValue:Write(replyBytes,1,GET-SIZE(replyBytes)).
   END.
   writerValue:Flush(). writerValue:Close().
   RETURN 0.
   FINALLY:
    cAuthenticatedConsumer="". cAuthenticatedConsumerRole="".
    lConsumerPaginationEnabled=TRUE.
    cursorConfig=?. cursorNow=0.
    headerValue="". bodyValue="". SET-SIZE(replyBytes)=0.
    IF VALID-OBJECT(writerValue) THEN DELETE OBJECT writerValue.
    IF VALID-OBJECT(responseValue) THEN DELETE OBJECT responseValue.
    IF VALID-OBJECT(decision) THEN DELETE OBJECT decision.
    IF VALID-OBJECT(config) THEN DELETE OBJECT config.
    IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
    IF VALID-OBJECT(registry) THEN DELETE OBJECT registry.
    IF VALID-OBJECT(requestValue) THEN DELETE OBJECT requestValue.
    IF VALID-OBJECT(issuer) THEN DELETE OBJECT issuer.
    IF VALID-OBJECT(jobsValue) THEN DELETE OBJECT jobsValue.
    IF VALID-OBJECT(webhooksValue) THEN DELETE OBJECT webhooksValue.
   END FINALLY.
  END.
 END METHOD.
END CLASS.
