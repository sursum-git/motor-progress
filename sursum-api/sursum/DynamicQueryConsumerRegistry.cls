USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* No plaintext token crosses this boundary. Caller must already be an authenticated admin. */
CLASS DynamicQueryConsumerRegistry:
 METHOD PUBLIC JsonObject parseRequest(INPUT bodyValue AS LONGCHAR):
  DEFINE VARIABLE utf8Value AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF bodyValue=? OR LENGTH(bodyValue,"RAW")>65536 THEN RETURN ?.
   FIX-CODEPAGE(utf8Value)="UTF-8". utf8Value=bodyValue.
   parser=NEW ObjectModelParser(). parsed=parser:Parse(utf8Value) NO-ERROR.
   IF NOT VALID-OBJECT(parsed) THEN RETURN ?.
   IF TYPE-OF(parsed,JsonObject) THEN RETURN CAST(parsed,JsonObject).
   DELETE OBJECT parsed. RETURN ?.
   CATCH err AS Progress.Lang.Error: RETURN ?. END CATCH.
   FINALLY: IF VALID-OBJECT(parser) THEN DELETE OBJECT parser. END FINALLY.
  END.
 END METHOD.
 METHOD PUBLIC JsonObject execute(INPUT fileValue AS CHARACTER, INPUT actionValue AS CHARACTER,
  INPUT requestValue AS JsonObject, INPUT nowEpoch AS INT64, OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO.
  DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE matched AS JsonObject NO-UNDO.
  DEFINE VARIABLE queries AS JsonArray NO-UNDO.
  DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
  DEFINE VARIABLE expectedFields AS CHARACTER NO-UNDO.
  DEFINE VARIABLE idValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE revisionValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE tempValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE bytesValue AS MEMPTR NO-UNDO.
  DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
  DEFINE VARIABLE ioSuccess AS LOGICAL NO-UNDO.
  DEFINE VARIABLE daysValue AS INTEGER NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  DEFINE VARIABLE j AS INTEGER NO-UNDO.
  DEFINE VARIABLE requestedAction AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hashField AS CHARACTER NO-UNDO INITIAL "tokenSha256".
  statusValue=503.
  DO ON ERROR UNDO, THROW:
   requestedAction=actionValue.
   IF actionValue="create-client" THEN DO: actionValue="create". hashField="clientSecretSha256". END.
   IF actionValue="credentials" THEN DO: actionValue="rotate". hashField="clientSecretSha256". END.
   IF LOOKUP(actionValue,"list,create,update,rotate,revoke")=0 THEN RETURN THIS-OBJECT:failure("INVALID_ACTION",400,OUTPUT statusValue).
   IF fileValue=? OR fileValue="" THEN RETURN THIS-OBJECT:failure("SECURITY_UNAVAILABLE",503,OUTPUT statusValue).
   /* Serialize snapshot + revision with all writers, including the trusted CLI. */
   RUN QueryConsumerConfigIo.p("acquire",fileValue,"",OUTPUT ownsLock).
   IF NOT ownsLock THEN RETURN THIS-OBJECT:failure("CONFIG_BUSY",409,OUTPUT statusValue).
   policy=NEW DynamicQueryConsumerPolicy(). cfg=policy:loadConfig(fileValue).
   IF NOT policy:isValid(cfg) THEN RETURN THIS-OBJECT:failure("SECURITY_UNAVAILABLE",503,OUTPUT statusValue).
   COPY-LOB FROM FILE fileValue TO bytesValue.
   revisionValue=LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",bytesValue))). SET-SIZE(bytesValue)=0.
   IF actionValue="list" THEN DO:
    statusValue=200. RETURN THIS-OBJECT:snapshot(cfg,revisionValue,nowEpoch).
   END.
   IF NOT VALID-OBJECT(requestValue) THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   expectedFields="action,id,revision".
   IF actionValue<>"revoke" THEN expectedFields=expectedFields + ",days".
   IF actionValue="create" OR actionValue="update" THEN expectedFields=expectedFields + ",queries".
   IF actionValue="create" OR actionValue="rotate" THEN expectedFields=expectedFields + "," + hashField.
   names=requestValue:GetNames().
   IF EXTENT(names)<>NUM-ENTRIES(expectedFields) THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   DO i=1 TO EXTENT(names):
    IF LOOKUP(names[i],expectedFields)=0 THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   END.
   DO i=1 TO NUM-ENTRIES(expectedFields):
    IF NOT requestValue:Has(ENTRY(i,expectedFields)) THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   END.
   IF requestValue:GetType("action")<>JsonDataType:STRING OR requestValue:GetType("id")<>JsonDataType:STRING
    OR requestValue:GetType("revision")<>JsonDataType:STRING THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   IF NOT THIS-OBJECT:exact(requestValue:GetCharacter("action"),requestedAction) THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   idValue=requestValue:GetCharacter("id").
   IF NOT THIS-OBJECT:identifier(idValue) THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   IF idValue="web-query-admin" THEN RETURN THIS-OBJECT:failure("PROTECTED_CONSUMER",403,OUTPUT statusValue).
   IF NOT THIS-OBJECT:exact(requestValue:GetCharacter("revision"),revisionValue) THEN RETURN THIS-OBJECT:failure("STALE_REVISION",409,OUTPUT statusValue).
   entries=cfg:GetJsonArray("consumers").
   DO i=1 TO entries:Length:
    entryValue=entries:GetJsonObject(i).
    IF THIS-OBJECT:exact(entryValue:GetCharacter("id"),idValue) THEN matched=entryValue.
   END.
   IF VALID-OBJECT(matched) THEN DO:
    IF matched:GetCharacter("role")<>"consumer" THEN RETURN THIS-OBJECT:failure("PROTECTED_CONSUMER",403,OUTPUT statusValue).
    IF actionValue="create" THEN RETURN THIS-OBJECT:failure("DUPLICATE_CONSUMER",409,OUTPUT statusValue).
   END.
   ELSE IF actionValue<>"create" THEN RETURN THIS-OBJECT:failure("CONSUMER_NOT_FOUND",404,OUTPUT statusValue).
   IF actionValue<>"revoke" THEN DO:
    IF requestValue:GetType("days")<>JsonDataType:NUMBER THEN RETURN THIS-OBJECT:failure("INVALID_EXPIRY",400,OUTPUT statusValue).
    IF requestValue:GetDecimal("days")<1 OR requestValue:GetDecimal("days")>365
     OR requestValue:GetDecimal("days")<>TRUNCATE(requestValue:GetDecimal("days"),0) THEN RETURN THIS-OBJECT:failure("INVALID_EXPIRY",400,OUTPUT statusValue).
    daysValue=requestValue:GetInteger("days").
   END.
   IF actionValue="create" OR actionValue="update" THEN DO:
    IF requestValue:GetType("queries")<>JsonDataType:ARRAY THEN RETURN THIS-OBJECT:failure("INVALID_QUERIES",400,OUTPUT statusValue).
    queries=requestValue:GetJsonArray("queries").
    IF queries:Length<1 OR queries:Length>1000 THEN RETURN THIS-OBJECT:failure("INVALID_QUERIES",400,OUTPUT statusValue).
    DO i=1 TO queries:Length:
     IF queries:GetType(i)<>JsonDataType:STRING THEN RETURN THIS-OBJECT:failure("INVALID_QUERIES",400,OUTPUT statusValue).
     IF NOT THIS-OBJECT:identifier(queries:GetCharacter(i)) THEN RETURN THIS-OBJECT:failure("INVALID_QUERIES",400,OUTPUT statusValue).
     IF NOT THIS-OBJECT:queryExists(queries:GetCharacter(i)) THEN RETURN THIS-OBJECT:failure("QUERY_NOT_FOUND",400,OUTPUT statusValue).
     DO j=1 TO i - 1:
      IF THIS-OBJECT:exact(queries:GetCharacter(i),queries:GetCharacter(j)) THEN RETURN THIS-OBJECT:failure("INVALID_QUERIES",400,OUTPUT statusValue).
     END.
    END.
   END.
   IF actionValue="create" OR actionValue="rotate" THEN DO:
    IF requestValue:GetType(hashField)<>JsonDataType:STRING THEN RETURN THIS-OBJECT:failure("INVALID_HASH",400,OUTPUT statusValue).
    hashValue=requestValue:GetCharacter(hashField).
    IF LENGTH(hashValue)<>64 THEN RETURN THIS-OBJECT:failure("INVALID_HASH",400,OUTPUT statusValue).
    DO i=1 TO 64:
     IF INDEX("0123456789abcdef",SUBSTRING(hashValue,i,1))=0 THEN RETURN THIS-OBJECT:failure("INVALID_HASH",400,OUTPUT statusValue).
    END.
    DO i=1 TO entries:Length:
     IF CAPS(entries:GetJsonObject(i):GetCharacter("tokenSha256"))=CAPS(hashValue) THEN RETURN THIS-OBJECT:failure("DUPLICATE_CREDENTIAL",409,OUTPUT statusValue).
    END.
   END.
   IF actionValue="create" THEN DO:
    matched=NEW JsonObject(). matched:Add("id",idValue). matched:Add("role","consumer"). matched:Add("active",TRUE).
    matched:Add("tokenSha256",hashValue). matched:Add("queries",queries). matched:Add("expiresAtEpoch",nowEpoch + INT64(daysValue) * 86400).
    entries:Add(matched).
   END.
   IF actionValue="update" THEN DO:
    matched:Set("queries",queries). matched:Set("expiresAtEpoch",nowEpoch + INT64(daysValue) * 86400).
   END.
   IF actionValue="rotate" THEN DO:
    matched:Set("tokenSha256",hashValue). matched:Set("expiresAtEpoch",nowEpoch + INT64(daysValue) * 86400). matched:Set("active",TRUE).
   END.
   IF actionValue="revoke" THEN matched:Set("active",FALSE).
   IF (actionValue="create" OR actionValue="rotate") THEN DO:
    IF hashField="clientSecretSha256" THEN DO:
     IF matched:Has(hashField) THEN matched:Set(hashField,hashValue).
     ELSE matched:Add(hashField,hashValue).
    END.
    ELSE IF matched:Has("clientSecretSha256") THEN matched:Remove("clientSecretSha256").
   END.
   IF NOT policy:isValid(cfg) THEN RETURN THIS-OBJECT:failure("INVALID_REQUEST",400,OUTPUT statusValue).
   tempValue=fileValue + "." + HEX-ENCODE(GENERATE-UUID) + ".tmp".
   IF NOT cfg:WriteFile(tempValue,TRUE) THEN RETURN THIS-OBJECT:failure("WRITE_FAILED",503,OUTPUT statusValue).
   FILE-INFO:FILE-NAME=tempValue.
   IF FILE-INFO:FILE-SIZE=? OR FILE-INFO:FILE-SIZE>1048576 THEN RETURN THIS-OBJECT:failure("CONFIG_TOO_LARGE",400,OUTPUT statusValue).
   RUN QueryConsumerConfigIo.p("replace",fileValue,tempValue,OUTPUT ioSuccess).
   IF NOT ioSuccess THEN RETURN THIS-OBJECT:failure("WRITE_FAILED",503,OUTPUT statusValue).
   tempValue="".
   COPY-LOB FROM FILE fileValue TO bytesValue.
   revisionValue=LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",bytesValue))).
   LOG-MANAGER:WRITE-MESSAGE("action=" + actionValue + " consumer=" + idValue,"QUERY-CONSUMER-ADMIN") NO-ERROR.
   statusValue=200. RETURN THIS-OBJECT:snapshot(cfg,revisionValue,nowEpoch).
   CATCH err AS Progress.Lang.Error:
    RETURN THIS-OBJECT:failure("ADMIN_UNAVAILABLE",503,OUTPUT statusValue).
   END CATCH.
   FINALLY:
    IF tempValue<>"" THEN OS-DELETE VALUE(tempValue).
    IF ownsLock THEN RUN QueryConsumerConfigIo.p("release",fileValue,"",OUTPUT ioSuccess).
    SET-SIZE(bytesValue)=0.
    IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
    IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL queryExists(INPUT codeValue AS CHARACTER):
  DEFINE VARIABLE readable AS LOGICAL NO-UNDO.
  DEFINE VARIABLE candidate AS CHARACTER NO-UNDO.
  DEFINE VARIABLE rootValue AS CHARACTER NO-UNDO INITIAL "sursum-api/querys".
  DEFINE VARIABLE configFile AS CHARACTER NO-UNDO.
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
  DO ON ERROR UNDO, THROW:
   configFile=SEARCH("sursum-conf/query-store.json").
   IF configFile=? THEN configFile=SEARCH("sursum-conf~\query-store.json").
   IF configFile=? THEN DO:
    RUN QueryConsumerConfigIo.p("readable","sursum-conf~\query-store.json","",OUTPUT readable).
    IF readable THEN configFile="sursum-conf~\query-store.json".
   END.
   IF configFile<>? THEN DO:
    parser=NEW ObjectModelParser(). parsed=parser:ParseFile(configFile).
    IF NOT TYPE-OF(parsed,JsonObject) THEN RETURN FALSE.
    cfg=CAST(parsed,JsonObject).
    IF cfg:Has("paths") THEN DO:
     IF cfg:GetJsonObject("paths"):Has("queryStoreRoot") THEN rootValue=cfg:GetJsonObject("paths"):GetCharacter("queryStoreRoot").
    END.
   END.
   IF rootValue=? OR rootValue="" THEN rootValue="sursum-api/querys".
   /* Existing deployed handler also uses literal Windows separators on UNIX. */
   candidate=REPLACE(rootValue,"~\","/") + "/" + codeValue + ".json".
   IF SEARCH(candidate)<>? THEN RETURN TRUE.
   RUN QueryConsumerConfigIo.p("readable",candidate,"",OUTPUT readable).
   IF readable THEN RETURN TRUE.
   candidate=REPLACE(rootValue,"/","~\") + "~\" + codeValue + ".json".
   IF SEARCH(candidate)<>? THEN RETURN TRUE.
   RUN QueryConsumerConfigIo.p("readable",candidate,"",OUTPUT readable).
   RETURN readable.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
   FINALLY:
    IF VALID-OBJECT(parsed) THEN DELETE OBJECT parsed.
    IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE JsonObject snapshot(INPUT cfg AS JsonObject, INPUT revisionValue AS CHARACTER, INPUT nowEpoch AS INT64):
  DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE item AS JsonObject NO-UNDO.
  DEFINE VARIABLE rows AS JsonArray NO-UNDO.
  DEFINE VARIABLE entries AS JsonArray NO-UNDO.
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  resultValue=NEW JsonObject(). rows=NEW JsonArray(). entries=cfg:GetJsonArray("consumers").
  DO i=1 TO entries:Length:
   item=entries:GetJsonObject(i). rowValue=NEW JsonObject().
   rowValue:Add("id",item:GetCharacter("id")). rowValue:Add("role",item:GetCharacter("role")).
   rowValue:Add("active",item:GetLogical("active")). rowValue:Add("expiresAtEpoch",item:GetInt64("expiresAtEpoch")).
   rowValue:Add("expired",item:GetInt64("expiresAtEpoch")<=nowEpoch).
   rowValue:Add("protected",item:GetCharacter("role")<>"consumer" OR item:GetCharacter("id")="web-query-admin").
   rowValue:Add("queries",CAST(item:GetJsonArray("queries"):Clone(),JsonArray)). rows:Add(rowValue).
   rowValue:Add("clientCredentials",item:Has("clientSecretSha256")).
  END.
  resultValue:Add("success",TRUE). resultValue:Add("data",rows). resultValue:Add("revision",revisionValue).
  RETURN resultValue.
 END METHOD.
 METHOD PRIVATE LOGICAL identifier(INPUT valueText AS CHARACTER):
  DEFINE VARIABLE i AS INTEGER NO-UNDO.
  IF valueText=? OR LENGTH(valueText)<1 OR LENGTH(valueText)>128 OR valueText="." OR valueText=".." THEN RETURN FALSE.
  DO i=1 TO LENGTH(valueText):
   IF INDEX("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-",SUBSTRING(valueText,i,1))=0 THEN RETURN FALSE.
  END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL exact(INPUT a AS CHARACTER, INPUT b AS CHARACTER):
  IF a=? OR b=? THEN RETURN FALSE.
  RETURN LENGTH(a,"RAW")=LENGTH(b,"RAW") AND COMPARE(a,"EQ",b,"RAW").
 END METHOD.
 METHOD PRIVATE JsonObject failure(INPUT codeValue AS CHARACTER, INPUT requestedStatus AS INTEGER, OUTPUT statusValue AS INTEGER):
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
  statusValue=requestedStatus. reply=NEW JsonObject(). errorValue=NEW JsonObject().
  errorValue:Add("code",codeValue). errorValue:Add("message",IF statusValue=409 THEN "A lista mudou ou esta em uso. Atualize antes de tentar novamente." ELSE IF statusValue=403 THEN "Credencial administrativa protegida." ELSE IF statusValue=400 THEN "Dados invalidos; confira consultas e validade." ELSE "Administracao indisponivel.").
  reply:Add("success",FALSE). reply:Add("error",errorValue). RETURN reply.
 END METHOD.
END CLASS.


