USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Pure authorization boundary: no database, caller identity, cache or token logs. */
CLASS DynamicQueryConsumerPolicy:
 METHOD PUBLIC LOGICAL isValid(INPUT cfg AS JsonObject):
  DO ON ERROR UNDO, THROW:
   RETURN THIS-OBJECT:validConfig(cfg).
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PUBLIC INT64 epochSeconds(INPUT moment AS DATETIME-TZ):
  RETURN INTERVAL(moment,DATETIME-TZ(DATE(1,1,1970),0,0),"seconds").
 END METHOD.
 METHOD PUBLIC CHARACTER credentialHeader(INPUT authorizationValue AS CHARACTER, INPUT customToken AS CHARACTER):
  IF authorizationValue=? THEN authorizationValue="".
  IF customToken=? THEN customToken="".
  IF customToken="" THEN RETURN authorizationValue.
  IF authorizationValue<>"" THEN DO:
   IF LENGTH(authorizationValue)<>71 OR CAPS(SUBSTRING(authorizationValue,1,7))<>"BEARER " THEN RETURN "".
   IF NOT THIS-OBJECT:exact(SUBSTRING(authorizationValue,8),customToken) THEN RETURN "".
  END.
  RETURN "Bearer " + customToken.
 END METHOD.
 METHOD PUBLIC JsonObject authorize(
  INPUT cfg AS JsonObject, INPUT authorizationValue AS CHARACTER,
  INPUT methodValue AS CHARACTER, INPUT pathValue AS CHARACTER,
  INPUT bodyValue AS LONGCHAR, INPUT nowEpoch AS INT64,
  OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE matched AS JsonObject NO-UNDO.
  DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
  DEFINE VARIABLE digestValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE bodyUtf8 AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE roleValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  DEFINE VARIABLE allowed AS LOGICAL NO-UNDO.
  DEFINE VARIABLE pagination AS DynamicQueryConsumerPagination NO-UNDO.
  statusValue = 503.
  DO ON ERROR UNDO, THROW:
   IF THIS-OBJECT:exact(methodValue,"OPTIONS") THEN DO:
    statusValue=204. reply=NEW JsonObject(). reply:Add("success",TRUE). RETURN reply.
   END.
   IF NOT THIS-OBJECT:validConfig(cfg) THEN RETURN THIS-OBJECT:failure("SECURITY_UNAVAILABLE",503,OUTPUT statusValue).
   statusValue=401.
   IF authorizationValue=? OR LENGTH(authorizationValue)<>71 THEN RETURN THIS-OBJECT:failure("AUTH_REQUIRED",401,OUTPUT statusValue).
   IF CAPS(SUBSTRING(authorizationValue,1,7))<>"BEARER " THEN RETURN THIS-OBJECT:failure("AUTH_REQUIRED",401,OUTPUT statusValue).
   tokenValue=SUBSTRING(authorizationValue,8).
   IF NOT THIS-OBJECT:isHex(tokenValue) THEN RETURN THIS-OBJECT:failure("AUTH_REQUIRED",401,OUTPUT statusValue).
   digestValue=CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue))).
   tokenValue="". authorizationValue="".
   entries=cfg:GetJsonArray("consumers").
   DO i=1 TO entries:Length:
    entryValue=entries:GetJsonObject(i).
    IF entryValue:Has("clientSecretSha256") THEN NEXT.
    IF THIS-OBJECT:sameHash(digestValue,CAPS(entryValue:GetCharacter("tokenSha256"))) THEN matched=entryValue.
   END.
   IF NOT VALID-OBJECT(matched) THEN RETURN THIS-OBJECT:failure("AUTH_REQUIRED",401,OUTPUT statusValue).
   IF NOT matched:GetLogical("active") OR matched:GetInt64("expiresAtEpoch")<=nowEpoch THEN
    RETURN THIS-OBJECT:failure("AUTH_REQUIRED",401,OUTPUT statusValue).
   roleValue=matched:GetCharacter("role").
   IF NOT THIS-OBJECT:exact(roleValue,"admin") THEN DO:
    statusValue=403.
    IF THIS-OBJECT:isConsumerWebhookPath(pathValue) AND LOOKUP(methodValue,"GET,PUT,DELETE")>0 THEN DO:
     statusValue=200. reply=NEW JsonObject(). reply:Add('success',TRUE). reply:Add('consumerId',matched:GetCharacter('id')).
     reply:Add('role',roleValue). reply:Add('queryCode',''). RETURN reply.
    END.
    IF THIS-OBJECT:exact(methodValue,"GET") AND THIS-OBJECT:isConsumerJobPath(pathValue) THEN DO:
     statusValue=200. reply=NEW JsonObject(). reply:Add('success',TRUE). reply:Add('consumerId',matched:GetCharacter('id')).
     reply:Add('role',roleValue). reply:Add('queryCode',''). RETURN reply.
    END.
    IF NOT THIS-OBJECT:exact(methodValue,"POST") OR NOT THIS-OBJECT:isQueryPath(pathValue) THEN
     RETURN THIS-OBJECT:failure("ADMIN_REQUIRED",403,OUTPUT statusValue).
    IF bodyValue=? OR LENGTH(bodyValue,"RAW")>65536 THEN RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    parser=NEW ObjectModelParser().
    FIX-CODEPAGE(bodyUtf8)="UTF-8". bodyUtf8=bodyValue.
    parsed=parser:Parse(bodyUtf8) NO-ERROR.
    IF ERROR-STATUS:ERROR OR NOT VALID-OBJECT(parsed) THEN RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    IF NOT TYPE-OF(parsed,JsonObject) THEN RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    requestValue=CAST(parsed,JsonObject).
    IF NOT requestValue:Has("code") THEN RETURN THIS-OBJECT:failure("QUERY_REQUIRED",403,OUTPUT statusValue).
    IF requestValue:GetType("code")<>JsonDataType:STRING THEN RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    codeValue=requestValue:GetCharacter("code").
    IF NOT THIS-OBJECT:isIdentifier(codeValue) THEN RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    names=requestValue:GetNames().
    DO i=1 TO EXTENT(names):
     IF NOT THIS-OBJECT:exact(names[i],"code") AND NOT THIS-OBJECT:exact(names[i],"parameters")
      AND NOT THIS-OBJECT:exact(names[i],"page") AND NOT THIS-OBJECT:exact(names[i],"pageSize")
      AND NOT THIS-OBJECT:exact(names[i],"paginate") AND NOT THIS-OBJECT:exact(names[i],"paginationMode") AND NOT THIS-OBJECT:exact(names[i],"cursor") AND NOT THIS-OBJECT:exact(names[i],"execution") AND NOT THIS-OBJECT:exact(names[i],"webhookDelivery") THEN
      RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    END.
    IF requestValue:Has("parameters") THEN
     IF requestValue:GetType("parameters")<>JsonDataType:OBJECT THEN RETURN THIS-OBJECT:failure("INVALID_CONSUMER_REQUEST",400,OUTPUT statusValue).
    pagination=NEW DynamicQueryConsumerPagination().
    allowed=pagination:isValid(requestValue). DELETE OBJECT pagination.
    IF NOT allowed THEN RETURN THIS-OBJECT:failure("INVALID_PAGINATION",400,OUTPUT statusValue).
    allowed=FALSE.
    entries=matched:GetJsonArray("queries").
    DO i=1 TO entries:Length:
     IF THIS-OBJECT:exact(codeValue,entries:GetCharacter(i)) THEN allowed=TRUE.
    END.
    IF NOT allowed THEN RETURN THIS-OBJECT:failure("QUERY_FORBIDDEN",403,OUTPUT statusValue).
   END.
   statusValue=200.
   reply=NEW JsonObject(). reply:Add("success",TRUE).
   reply:Add("consumerId",matched:GetCharacter("id")). reply:Add("role",roleValue).
   reply:Add("queryCode",codeValue).
   RETURN reply.
   CATCH err AS Progress.Lang.Error:
    statusValue=503. RETURN THIS-OBJECT:failure("SECURITY_UNAVAILABLE",503,OUTPUT statusValue).
   END CATCH.
   FINALLY:
    tokenValue="". authorizationValue="". digestValue="". bodyValue="".
    IF VALID-OBJECT(parsed) THEN DELETE OBJECT parsed.
    IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
    IF VALID-OBJECT(pagination) THEN DELETE OBJECT pagination.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL isConsumerWebhookPath(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE suffixValue AS CHARACTER NO-UNDO INITIAL "/SursumDynamicQuery/consumer-webhooks".
  IF pathValue=? OR LENGTH(pathValue)<LENGTH(suffixValue) THEN RETURN FALSE.
  RETURN THIS-OBJECT:exact(SUBSTRING(pathValue,LENGTH(pathValue) - LENGTH(suffixValue) + 1),suffixValue).
 END METHOD.
 METHOD PUBLIC JsonObject loadConfig(INPUT fileValue AS CHARACTER):
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF fileValue=? OR fileValue="" THEN RETURN ?.
   FILE-INFO:FILE-NAME=fileValue.
   IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE>1048576 THEN RETURN ?.
   parser=NEW ObjectModelParser(). parsed=parser:ParseFile(fileValue).
   IF NOT TYPE-OF(parsed,JsonObject) THEN DO: DELETE OBJECT parsed. RETURN ?. END.
   RETURN CAST(parsed,JsonObject).
   CATCH err AS Progress.Lang.Error:
    IF VALID-OBJECT(parsed) THEN DELETE OBJECT parsed.
    RETURN ?.
   END CATCH.
   FINALLY:
    IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL validConfig(INPUT cfg AS JsonObject):
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE queries AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE other AS JsonObject NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  DEFINE VARIABLE j AS INTEGER NO-UNDO.
  DEFINE VARIABLE roleValue AS CHARACTER NO-UNDO.
  IF NOT VALID-OBJECT(cfg) THEN RETURN FALSE.
  IF cfg:GetInteger("version")<>1 THEN RETURN FALSE.
  entries=cfg:GetJsonArray("consumers").
  IF entries:Length>1000 THEN RETURN FALSE.
  DO i=1 TO entries:Length:
   entryValue=entries:GetJsonObject(i).
   IF NOT THIS-OBJECT:isIdentifier(entryValue:GetCharacter("id")) THEN RETURN FALSE.
   IF entryValue:GetType("active")<>JsonDataType:BOOLEAN THEN RETURN FALSE.
   IF entryValue:GetType("expiresAtEpoch")<>JsonDataType:NUMBER OR entryValue:GetInt64("expiresAtEpoch")<=0 THEN RETURN FALSE.
   IF NOT THIS-OBJECT:isHex(entryValue:GetCharacter("tokenSha256")) THEN RETURN FALSE.
   roleValue=entryValue:GetCharacter("role").
   IF entryValue:Has("clientSecretSha256") THEN DO:
    IF NOT THIS-OBJECT:exact(roleValue,"consumer") THEN RETURN FALSE.
    IF entryValue:GetType("clientSecretSha256")<>JsonDataType:STRING THEN RETURN FALSE.
    IF NOT THIS-OBJECT:isHex(entryValue:GetCharacter("clientSecretSha256")) THEN RETURN FALSE.
   END.
   IF NOT THIS-OBJECT:exact(roleValue,"admin") AND NOT THIS-OBJECT:exact(roleValue,"consumer") THEN RETURN FALSE.
   queries=entryValue:GetJsonArray("queries").
   IF queries:Length>1000 THEN RETURN FALSE.
   DO j=1 TO queries:Length:
    IF NOT THIS-OBJECT:isIdentifier(queries:GetCharacter(j)) THEN RETURN FALSE.
   END.
   DO j=1 TO i - 1:
    other=entries:GetJsonObject(j).
    IF THIS-OBJECT:exact(other:GetCharacter("id"),entryValue:GetCharacter("id")) OR
     THIS-OBJECT:sameHash(CAPS(other:GetCharacter("tokenSha256")),CAPS(entryValue:GetCharacter("tokenSha256"))) THEN RETURN FALSE.
   END.
  END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL isIdentifier(INPUT valueText AS CHARACTER):
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  IF valueText=? OR LENGTH(valueText)=0 OR LENGTH(valueText)>128 THEN RETURN FALSE.
  IF valueText="." OR valueText=".." THEN RETURN FALSE.
  DO i=1 TO LENGTH(valueText):
   IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-",SUBSTRING(valueText,i,1))=0 THEN RETURN FALSE.
  END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL isHex(INPUT valueText AS CHARACTER):
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  IF valueText=? OR LENGTH(valueText)<>64 THEN RETURN FALSE.
  DO i=1 TO 64:
   IF INDEX("0123456789abcdefABCDEF",SUBSTRING(valueText,i,1))=0 THEN RETURN FALSE.
  END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL sameHash(INPUT leftValue AS CHARACTER, INPUT rightValue AS CHARACTER):
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  DEFINE VARIABLE differences AS INTEGER NO-UNDO.
  IF LENGTH(leftValue)<>64 OR LENGTH(rightValue)<>64 THEN RETURN FALSE.
  DO i=1 TO 64:
   IF NOT THIS-OBJECT:exact(SUBSTRING(leftValue,i,1),SUBSTRING(rightValue,i,1)) THEN differences=differences + 1.
  END.
  RETURN differences=0.
 END METHOD.
 METHOD PRIVATE LOGICAL exact(INPUT leftValue AS CHARACTER, INPUT rightValue AS CHARACTER):
  IF leftValue=? OR rightValue=? THEN RETURN FALSE.
  RETURN LENGTH(leftValue,"RAW")=LENGTH(rightValue,"RAW") AND COMPARE(leftValue,"EQ",rightValue,"RAW").
 END METHOD.
 METHOD PRIVATE LOGICAL isConsumerJobPath(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE marker AS CHARACTER NO-UNDO INITIAL '/SursumDynamicQuery/consumer-jobs/'.
  DEFINE VARIABLE positionValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF pathValue=? THEN RETURN FALSE.
  positionValue=R-INDEX(pathValue,marker). IF positionValue=0 THEN RETURN FALSE.
  idValue=SUBSTRING(pathValue,positionValue + LENGTH(marker)).
  IF LENGTH(idValue)=33 AND SUBSTRING(idValue,27)='/result' THEN idValue=SUBSTRING(idValue,1,26).
  IF LENGTH(idValue)<>26 OR NOT COMPARE(SUBSTRING(idValue,1,4),'EQ','JOB-','RAW') THEN RETURN FALSE.
  IF SUBSTRING(idValue,13,1)<>'-' OR SUBSTRING(idValue,20,1)<>'-' THEN RETURN FALSE.
  DO n=5 TO 26:
   IF n=13 OR n=20 THEN NEXT.
   IF INDEX('0123456789',SUBSTRING(idValue,n,1))=0 THEN RETURN FALSE.
  END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL isQueryPath(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE suffixValue AS CHARACTER NO-UNDO INITIAL "/SursumDynamicQuery/query".
  IF pathValue=? OR LENGTH(pathValue)<LENGTH(suffixValue) THEN RETURN FALSE.
  RETURN THIS-OBJECT:exact(SUBSTRING(pathValue,LENGTH(pathValue) - LENGTH(suffixValue) + 1),suffixValue).
 END METHOD.
 METHOD PRIVATE JsonObject failure(INPUT codeValue AS CHARACTER, INPUT requestedStatus AS INTEGER, OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE detail AS JsonObject NO-UNDO.
  statusValue=requestedStatus.
  reply=NEW JsonObject(). detail=NEW JsonObject().
  detail:Add("code",codeValue). detail:Add("status",statusValue).
  detail:Add("message",IF statusValue=401 THEN "Credencial ausente ou invalida." ELSE IF statusValue=403 THEN "Acesso nao autorizado." ELSE IF statusValue=400 THEN "Solicitacao invalida." ELSE "Servico de autorizacao indisponivel.").
  reply:Add("success",FALSE). reply:Add("error",detail).
  RETURN reply.
 END METHOD.
END CLASS.
