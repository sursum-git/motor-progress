USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Used only by the MED secured wrapper. No plaintext credentials in persistent state. */
CLASS DynamicQueryClientCredentials:
 METHOD PUBLIC JsonObject issue(INPUT fileValue AS CHARACTER, INPUT requestValue AS JsonObject,
  INPUT nowEpoch AS INT64, OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO.
  DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
  DEFINE VARIABLE store AS JsonObject NO-UNDO.
  DEFINE VARIABLE matched AS JsonObject NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE retained AS JsonArray NO-UNDO.
  DEFINE VARIABLE tokens AS JsonArray NO-UNDO.
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE secretValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE storePath AS CHARACTER NO-UNDO.
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE ioSuccess AS LOGICAL NO-UNDO.
  DEFINE VARIABLE countValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  statusValue=503.
  DO ON ERROR UNDO, THROW:
   IF fileValue=? OR fileValue="" THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   IF NOT VALID-OBJECT(requestValue) THEN RETURN THIS-OBJECT:failure(400,OUTPUT statusValue).
   names=requestValue:GetNames().
   IF EXTENT(names)<>3 THEN RETURN THIS-OBJECT:failure(400,OUTPUT statusValue).
   DO i=1 TO EXTENT(names):
    IF LOOKUP(names[i],"grant_type,client_id,client_secret")=0 THEN RETURN THIS-OBJECT:failure(400,OUTPUT statusValue).
   END.
   IF requestValue:GetType("grant_type")<>JsonDataType:STRING OR requestValue:GetType("client_id")<>JsonDataType:STRING
    OR requestValue:GetType("client_secret")<>JsonDataType:STRING THEN RETURN THIS-OBJECT:failure(400,OUTPUT statusValue).
   IF NOT THIS-OBJECT:exact(requestValue:GetCharacter("grant_type"),"client_credentials") THEN RETURN THIS-OBJECT:failure(400,OUTPUT statusValue).
   idValue=requestValue:GetCharacter("client_id"). secretValue=requestValue:GetCharacter("client_secret").
   IF LENGTH(idValue)<1 OR LENGTH(idValue)>128 OR LENGTH(secretValue)<>64 THEN RETURN THIS-OBJECT:failure(401,OUTPUT statusValue).
   hashValue=LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",secretValue))). secretValue="".
   policy=NEW DynamicQueryConsumerPolicy(). cfg=policy:loadConfig(fileValue).
   IF NOT policy:isValid(cfg) THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   storePath=THIS-OBJECT:storeLocation(cfg,fileValue).
   RUN QueryConsumerConfigIo.p("acquire",storePath,"",OUTPUT ownsLock).
   IF NOT ownsLock THEN RETURN THIS-OBJECT:failure(409,OUTPUT statusValue).
   store=THIS-OBJECT:loadStore(storePath).
   IF NOT VALID-OBJECT(store) THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   IF store:GetInt64("window") + 60<=nowEpoch OR store:GetInt64("window")>nowEpoch THEN DO:
    store:Set("window",nowEpoch). store:Set("attempts",0).
   END.
   IF store:GetInteger("attempts")>=300 THEN RETURN THIS-OBJECT:failure(429,OUTPUT statusValue).
   store:Set("attempts",store:GetInteger("attempts") + 1).
   entries=cfg:GetJsonArray("consumers").
   DO i=1 TO entries:Length:
    entryValue=entries:GetJsonObject(i).
    IF THIS-OBJECT:exact(entryValue:GetCharacter("id"),idValue) THEN matched=entryValue.
   END.
   /* Persist the attempt count for both known and unknown clients. */
   IF NOT THIS-OBJECT:saveStore(store,storePath) THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   IF NOT VALID-OBJECT(matched) THEN RETURN THIS-OBJECT:failure(401,OUTPUT statusValue).
   IF matched:GetCharacter("role")<>"consumer" OR NOT matched:GetLogical("active") OR matched:GetInt64("expiresAtEpoch")<=nowEpoch
    OR NOT matched:Has("clientSecretSha256") THEN RETURN THIS-OBJECT:failure(401,OUTPUT statusValue).
   IF NOT THIS-OBJECT:sameHash(hashValue,matched:GetCharacter("clientSecretSha256")) THEN RETURN THIS-OBJECT:failure(401,OUTPUT statusValue).
   retained=NEW JsonArray(). tokens=store:GetJsonArray("tokens").
   DO i=1 TO tokens:Length:
    entryValue=tokens:GetJsonObject(i).
    IF entryValue:GetInt64("expiresAtEpoch")<=nowEpoch THEN NEXT.
    /* Old secret generations for this consumer cannot authorize and may be pruned. */
    IF THIS-OBJECT:exact(entryValue:GetCharacter("consumerId"),idValue) THEN DO:
     IF NOT THIS-OBJECT:sameHash(entryValue:GetCharacter("credentialHash"),hashValue) THEN NEXT.
     countValue=countValue + 1.
    END.
    retained:Add(CAST(entryValue:Clone(),JsonObject)).
   END.
   IF countValue>=20 OR retained:Length>=8192 THEN RETURN THIS-OBJECT:failure(429,OUTPUT statusValue).
   tokenValue=THIS-OBJECT:randomToken().
   entryValue=NEW JsonObject(). entryValue:Add("consumerId",idValue).
   entryValue:Add("hash",LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue)))).
   entryValue:Add("credentialHash",hashValue). entryValue:Add("expiresAtEpoch",nowEpoch + 900).
   retained:Add(entryValue). store:Set("tokens",retained).
   IF NOT THIS-OBJECT:saveStore(store,storePath) THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   reply=NEW JsonObject(). reply:Add("access_token",tokenValue). reply:Add("token_type","Bearer"). reply:Add("expires_in",900).
   statusValue=200.
   LOG-MANAGER:WRITE-MESSAGE("consumer=" + matched:GetCharacter("id"),"QUERY-TOKEN-ISSUED") NO-ERROR.
   RETURN reply.
   CATCH err AS Progress.Lang.Error: RETURN THIS-OBJECT:failure(503,OUTPUT statusValue). END CATCH.
   FINALLY:
    secretValue="". hashValue="". tokenValue="".
    IF ownsLock THEN RUN QueryConsumerConfigIo.p("release",storePath,"",OUTPUT ioSuccess).
    IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
    IF VALID-OBJECT(store) THEN DELETE OBJECT store.
    IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
   END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject authorize(INPUT cfg AS JsonObject, INPUT fileValue AS CHARACTER,
  INPUT headerValue AS CHARACTER, INPUT methodValue AS CHARACTER, INPUT pathValue AS CHARACTER,
  INPUT bodyValue AS LONGCHAR, INPUT nowEpoch AS INT64, OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO.
  DEFINE VARIABLE store AS JsonObject NO-UNDO.
  DEFINE VARIABLE tokens AS JsonArray NO-UNDO.
  DEFINE VARIABLE consumers AS JsonArray NO-UNDO.
  DEFINE VARIABLE tokenEntry AS JsonObject NO-UNDO.
  DEFINE VARIABLE consumer AS JsonObject NO-UNDO.
  DEFINE VARIABLE proof AS JsonObject NO-UNDO.
  DEFINE VARIABLE copyEntry AS JsonObject NO-UNDO.
  DEFINE VARIABLE proofEntries AS JsonArray NO-UNDO.
  DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  DEFINE VARIABLE j AS INTEGER NO-UNDO.
  statusValue=401.
  DO ON ERROR UNDO, THROW:
   policy=NEW DynamicQueryConsumerPolicy().
   IF NOT policy:isValid(cfg) THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   IF headerValue=? OR LENGTH(headerValue)<>71 OR SUBSTRING(headerValue,1,7)<>"Bearer " THEN RETURN THIS-OBJECT:failure(401,OUTPUT statusValue).
   hashValue=LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",SUBSTRING(headerValue,8)))).
   store=THIS-OBJECT:loadStore(THIS-OBJECT:storeLocation(cfg,fileValue)).
   IF NOT VALID-OBJECT(store) THEN RETURN THIS-OBJECT:failure(503,OUTPUT statusValue).
   tokens=store:GetJsonArray("tokens"). consumers=cfg:GetJsonArray("consumers").
   DO i=1 TO tokens:Length:
    tokenEntry=tokens:GetJsonObject(i).
    IF tokenEntry:GetInt64("expiresAtEpoch")<=nowEpoch OR NOT THIS-OBJECT:sameHash(tokenEntry:GetCharacter("hash"),hashValue) THEN NEXT.
    DO j=1 TO consumers:Length:
     consumer=consumers:GetJsonObject(j).
     IF NOT THIS-OBJECT:exact(consumer:GetCharacter("id"),tokenEntry:GetCharacter("consumerId")) THEN NEXT.
     IF consumer:GetCharacter("role")<>"consumer" OR NOT consumer:Has("clientSecretSha256") THEN NEXT.
     IF NOT THIS-OBJECT:sameHash(consumer:GetCharacter("clientSecretSha256"),tokenEntry:GetCharacter("credentialHash")) THEN NEXT.
     /* Reuse the existing policy with live permissions, activation and authorization expiry. */
     proof=NEW JsonObject(). proof:Add("version",1). proofEntries=NEW JsonArray(). proof:Add("consumers",proofEntries).
     copyEntry=CAST(consumer:Clone(),JsonObject). copyEntry:Remove("clientSecretSha256"). copyEntry:Set("tokenSha256",hashValue). proofEntries:Add(copyEntry).
     RETURN policy:authorize(proof,headerValue,methodValue,pathValue,bodyValue,nowEpoch,OUTPUT statusValue).
    END.
   END.
   RETURN THIS-OBJECT:failure(401,OUTPUT statusValue).
   CATCH err AS Progress.Lang.Error: RETURN THIS-OBJECT:failure(503,OUTPUT statusValue). END CATCH.
   FINALLY:
    headerValue="". hashValue="".
    IF VALID-OBJECT(proof) THEN DELETE OBJECT proof.
    IF VALID-OBJECT(store) THEN DELETE OBJECT store.
    IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE CHARACTER storeLocation(INPUT cfg AS JsonObject, INPUT fileValue AS CHARACTER):
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  IF NOT cfg:Has("accessTokenStore") THEN UNDO, THROW NEW Progress.Lang.AppError("Private token store not configured",0).
  IF cfg:GetType("accessTokenStore")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid token store",0).
  pathValue=cfg:GetCharacter("accessTokenStore").
  IF pathValue=? OR LENGTH(pathValue)<3 OR LENGTH(pathValue)>2048 THEN UNDO, THROW NEW Progress.Lang.AppError("Invalid token store",0).
  IF OPSYS="UNIX" THEN DO:
   IF SUBSTRING(pathValue,1,1)<>"/" THEN UNDO, THROW NEW Progress.Lang.AppError("Token store must be absolute",0).
  END.
  ELSE IF SUBSTRING(pathValue,2,1)<>":" AND SUBSTRING(pathValue,1,2)<>"~\~\" THEN UNDO, THROW NEW Progress.Lang.AppError("Token store must be absolute",0).
  RETURN pathValue.
 END METHOD.
 METHOD PRIVATE CHARACTER randomToken():
  DEFINE VARIABLE algorithmValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE randomValue AS RAW NO-UNDO.
  algorithmValue=SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM.
  DO ON ERROR UNDO, THROW:
   SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM="AES_CBC_256".
   randomValue=GENERATE-RANDOM-KEY.
   IF LENGTH(randomValue,"RAW")<>32 THEN UNDO, THROW NEW Progress.Lang.AppError("Random key unavailable",0).
   RETURN STRING(LC(HEX-ENCODE(randomValue))).
   FINALLY: SECURITY-POLICY:SYMMETRIC-ENCRYPTION-ALGORITHM=algorithmValue. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE JsonObject loadStore(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DEFINE VARIABLE store AS JsonObject NO-UNDO.
  DEFINE VARIABLE tokens AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  DEFINE VARIABLE readable AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   RUN QueryConsumerConfigIo.p("readable",pathValue,"",OUTPUT readable).
   IF NOT readable THEN DO:
    FILE-INFO:FILE-NAME=pathValue.
    IF FILE-INFO:FULL-PATHNAME<>? THEN RETURN ?.
    store=NEW JsonObject(). store:Add("version",1). store:Add("window",0). store:Add("attempts",0). store:Add("tokens",NEW JsonArray()). RETURN store.
   END.
   FILE-INFO:FILE-NAME=pathValue.
   IF FILE-INFO:FILE-SIZE=? OR FILE-INFO:FILE-SIZE>4194304 THEN RETURN ?.
   parser=NEW ObjectModelParser(). parsed=parser:ParseFile(pathValue).
   IF NOT TYPE-OF(parsed,JsonObject) THEN RETURN ?.
   store=CAST(parsed,JsonObject).
   IF store:GetInteger("version")<>1 OR store:GetInt64("window")<0 OR store:GetInteger("attempts")<0 THEN RETURN ?.
   tokens=store:GetJsonArray("tokens"). IF tokens:Length>8192 THEN RETURN ?.
   DO i=1 TO tokens:Length:
    entryValue=tokens:GetJsonObject(i).
    IF LENGTH(entryValue:GetCharacter("hash"))<>64 OR LENGTH(entryValue:GetCharacter("credentialHash"))<>64
     OR LENGTH(entryValue:GetCharacter("consumerId"))<1 OR entryValue:GetInt64("expiresAtEpoch")<=0 THEN RETURN ?.
   END.
   RETURN store.
   CATCH err AS Progress.Lang.Error: RETURN ?. END CATCH.
   FINALLY: IF VALID-OBJECT(parser) THEN DELETE OBJECT parser. END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL saveStore(INPUT store AS JsonObject, INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE temporaryValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE successValue AS LOGICAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   temporaryValue=pathValue + "." + HEX-ENCODE(GENERATE-UUID) + ".tmp".
   IF NOT store:WriteFile(temporaryValue,TRUE) THEN RETURN FALSE.
   FILE-INFO:FILE-NAME=temporaryValue.
   IF FILE-INFO:FILE-SIZE=? OR FILE-INFO:FILE-SIZE>4194304 THEN RETURN FALSE.
   RUN QueryConsumerConfigIo.p("replace",pathValue,temporaryValue,OUTPUT successValue).
   RETURN successValue.
   FINALLY: IF temporaryValue<>"" THEN OS-DELETE VALUE(temporaryValue). END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL sameHash(INPUT a AS CHARACTER, INPUT b AS CHARACTER):
  DEFINE VARIABLE differences AS INTEGER NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  IF a=? OR b=? OR LENGTH(a)<>64 OR LENGTH(b)<>64 THEN RETURN FALSE.
  DO i=1 TO 64:
   IF NOT THIS-OBJECT:exact(SUBSTRING(a,i,1),SUBSTRING(b,i,1)) THEN differences=differences + 1.
  END.
  RETURN differences=0.
 END METHOD.
 METHOD PRIVATE LOGICAL exact(INPUT a AS CHARACTER, INPUT b AS CHARACTER):
  IF a=? OR b=? THEN RETURN FALSE.
  RETURN LENGTH(a,"RAW")=LENGTH(b,"RAW") AND COMPARE(a,"EQ",b,"RAW").
 END METHOD.
 METHOD PRIVATE JsonObject failure(INPUT codeValue AS INTEGER, OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  statusValue=codeValue. reply=NEW JsonObject().
  reply:Add("error",IF codeValue=401 THEN "invalid_client" ELSE IF codeValue=400 THEN "invalid_request" ELSE IF codeValue=429 THEN "rate_limit_exceeded" ELSE "temporarily_unavailable").
  RETURN reply.
 END METHOD.
END CLASS.
