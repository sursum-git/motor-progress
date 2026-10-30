USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE registry AS DynamicQueryConsumerRegistry NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE entries AS JsonArray NO-UNDO.
DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE reply AS JsonObject NO-UNDO.
DEFINE VARIABLE queries AS JsonArray NO-UNDO.
DEFINE VARIABLE fileValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE revisionValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
DEFINE VARIABLE checkCount AS INTEGER NO-UNDO.
DEFINE VARIABLE rawValue AS LONGCHAR NO-UNDO.
DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
DEFINE VARIABLE paddingValue AS LONGCHAR NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
registry=NEW DynamicQueryConsumerRegistry().
rawValue='~{"action":"create"~}'.
reply=registry:parseRequest(rawValue).
RUN assertCase(VALID-OBJECT(reply) AND reply:GetCharacter("action")="create","runtime body encoding").
rawValue='[]'. reply=registry:parseRequest(rawValue).
RUN assertCase(NOT VALID-OBJECT(reply),"array body rejected").
rawValue='invalid'. reply=registry:parseRequest(rawValue).
RUN assertCase(NOT VALID-OBJECT(reply),"malformed body rejected").
fileValue=SESSION:TEMP-DIRECTORY + "registry-test-" + HEX-ENCODE(GENERATE-UUID) + ".json".
cfg=NEW JsonObject(). cfg:Add("version",1). entries=NEW JsonArray(). cfg:Add("consumers",entries).
entryValue=NEW JsonObject(). entryValue:Add("id","web-query-admin"). entryValue:Add("active",TRUE).
entryValue:Add("role","admin"). entryValue:Add("expiresAtEpoch",2000000000).
entryValue:Add("tokenSha256",FILL("a",64)). entryValue:Add("queries",NEW JsonArray()). entries:Add(entryValue).
cfg:WriteFile(fileValue,TRUE).
RUN QueryConsumerConfigIo.p("readable",fileValue,"",OUTPUT ownsLock).
RUN assertCase(ownsLock,"native file readable").
RUN QueryConsumerConfigIo.p("readable",fileValue + ".missing","",OUTPUT ownsLock).
RUN assertCase(NOT ownsLock,"native missing file").
reply=registry:execute(fileValue,"list",?,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200 AND reply:GetJsonArray("data"):Length=1,"list").
revisionValue=reply:GetCharacter("revision").
RUN assertCase(NOT reply:GetJsonArray("data"):GetJsonObject(1):Has("tokenSha256"),"no hash").
requestValue=NEW JsonObject(). requestValue:Add("action","create"). requestValue:Add("id","partner").
requestValue:Add("revision",revisionValue). requestValue:Add("days",90).
queries=NEW JsonArray(). queries:Add("saldo-estoque-por-referencia"). requestValue:Add("queries",queries).
requestValue:Add("tokenSha256",FILL("b",64)).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).

RUN assertCase(statusValue=200 AND reply:GetJsonArray("data"):Length=2,"create").
RUN assertCase(reply:GetCharacter("revision")<>revisionValue,"revision changes").
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=409,"stale revision").
RUN reloadRevision.
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=409,"duplicate id").
requestValue:Set("id","other"). requestValue:Set("queries",NEW JsonArray()).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"empty permissions").
requestValue:Set("queries",queries). requestValue:Set("days",0).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"invalid expiry").
requestValue:Set("days",90). requestValue:Set("id","web-query-admin").
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=403,"protected id").
requestValue:Set("id","partner"). requestValue:Set("action","update"). requestValue:Remove("tokenSha256").
reply=registry:execute(fileValue,"update",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200,"update").
RUN reloadRevision.
requestValue:Set("action","rotate"). requestValue:Remove("queries"). requestValue:Add("tokenSha256",FILL("c",64)).
reply=registry:execute(fileValue,"rotate",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200,"rotate").
RUN reloadRevision.
requestValue:Set("action","revoke"). requestValue:Remove("days"). requestValue:Remove("tokenSha256").
reply=registry:execute(fileValue,"revoke",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200 AND NOT reply:GetJsonArray("data"):GetJsonObject(2):GetLogical("active"),"revoke").
RUN reloadRevision.
requestValue:Set("id","web-query-admin").
reply=registry:execute(fileValue,"revoke",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=403,"admin immutable").
requestValue:Set("id","partner").
RUN QueryConsumerConfigIo.p("acquire",fileValue,"",OUTPUT ownsLock).
RUN assertCase(ownsLock,"exclusive acquire").
reply=registry:execute(fileValue,"list",?,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=409,"snapshot shares writer lock").
reply=registry:execute(fileValue,"revoke",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=409,"other writer lock").
RUN QueryConsumerConfigIo.p("release",fileValue,"",OUTPUT ownsLock).
requestValue:Add("role","admin").
reply=registry:execute(fileValue,"revoke",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"unexpected fields").
requestValue:Remove("role"). requestValue:Set("action","create"). requestValue:Set("id","other").
requestValue:Add("days",90). requestValue:Add("tokenSha256",FILL("d",64)). requestValue:Add("queries","bad").
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"non array queries").
queries=NEW JsonArray(). queries:Add("does-not-exist-registry-test"). requestValue:Set("queries",queries).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"nonexistent query").
queries=NEW JsonArray(). queries:Add("saldo-estoque-por-referencia"). queries:Add("saldo-estoque-por-referencia"). requestValue:Set("queries",queries).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"duplicate queries").
queries=NEW JsonArray(). queries:Add("saldo-estoque-por-referencia"). requestValue:Set("queries",queries).
requestValue:Set("days",90.5).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"fractional days").
requestValue:Set("days",90). requestValue:Set("tokenSha256",FILL("a",64)).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=409,"duplicate hash").
COPY-LOB FROM FILE fileValue TO rawValue.
requestValue:Set("tokenSha256",FILL("z",64)).
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"invalid hash").
DEFINE VARIABLE afterValue AS LONGCHAR NO-UNDO.
COPY-LOB FROM FILE fileValue TO afterValue.
RUN assertCase(rawValue=afterValue,"rejections preserve bytes").
requestValue:Set("id","partner"). requestValue:Set("action","revoke").
requestValue:Remove("days"). requestValue:Remove("queries"). requestValue:Remove("tokenSha256").
requestValue:Set("revision",FILL("0",64)).
reply=registry:execute(fileValue,"revoke",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=409,"stale revoke").
RUN reloadRevision.
requestValue:Set("action","create-client"). requestValue:Set("id","automatic-partner").
requestValue:Add("days",90). requestValue:Add("queries",queries). requestValue:Add("clientSecretSha256",FILL("f",64)).
reply=registry:execute(fileValue,"create-client",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200 AND reply:GetJsonArray("data"):GetJsonObject(3):GetLogical("clientCredentials"),"create automatic client").
RUN assertCase(NOT reply:GetJsonArray("data"):GetJsonObject(3):Has("clientSecretSha256"),"list hides client secret hash").
RUN reloadRevision.
requestValue:Set("action","credentials"). requestValue:Remove("queries"). requestValue:Set("clientSecretSha256",FILL("e",64)).
reply=registry:execute(fileValue,"credentials",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200 AND reply:GetJsonArray("data"):GetJsonObject(3):GetLogical("clientCredentials"),"rotate client credential").
RUN assertCase(reply:GetJsonArray("data"):GetJsonObject(3):GetJsonArray("queries"):GetCharacter(1)="saldo-estoque-por-referencia","credential rotation preserves permissions").
RUN reloadRevision.
requestValue:Set("id","partner"). requestValue:Set("clientSecretSha256",FILL("d",64)).
reply=registry:execute(fileValue,"credentials",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200 AND reply:GetJsonArray("data"):GetJsonObject(2):GetLogical("clientCredentials"),"explicit legacy migration").
requestValue=NEW JsonObject(). requestValue:Add("revision",reply:GetCharacter("revision")).
DO n=1 TO 35: paddingValue=paddingValue + FILL("x",30000). END.
cfg:Add("padding",paddingValue). cfg:WriteFile(fileValue,TRUE).
FILE-INFO:FILE-NAME=fileValue.
paddingValue=SUBSTRING(paddingValue,1,1050000 + 1048500 - FILE-INFO:FILE-SIZE).
cfg:Set("padding",paddingValue). cfg:WriteFile(fileValue,TRUE).
reply=registry:execute(fileValue,"list",?,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=200,"near limit readable").
requestValue:Set("revision",reply:GetCharacter("revision")). requestValue:Add("action","create").
requestValue:Add("id","too-large"). requestValue:Add("days",90). requestValue:Add("queries",queries). requestValue:Add("tokenSha256",FILL("e",64)).
COPY-LOB FROM FILE fileValue TO rawValue.
reply=registry:execute(fileValue,"create",requestValue,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=400,"oversize write rejected").
COPY-LOB FROM FILE fileValue TO afterValue.
RUN assertCase(rawValue=afterValue,"oversize preserves bytes").
rawValue="{}". COPY-LOB FROM rawValue TO FILE fileValue.
reply=registry:execute(fileValue,"list",?,1800000000,OUTPUT statusValue).
RUN assertCase(statusValue=503,"invalid config").
OS-DELETE VALUE(fileValue).
OUTPUT TO "registry-tests.log".
PUT UNFORMATTED "PASS " checkCount " registry checks; NUMDBS=" NUM-DBS SKIP.
OUTPUT CLOSE.
PROCEDURE reloadRevision:
 reply=registry:execute(fileValue,"list",?,1800000000,OUTPUT statusValue).
 requestValue:Set("revision",reply:GetCharacter("revision")).
END.
PROCEDURE assertCase:
 DEFINE INPUT PARAMETER conditionValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF conditionValue<>TRUE OR conditionValue=? THEN UNDO,THROW NEW Progress.Lang.AppError("FAIL " + labelValue,0).
 checkCount=checkCount + 1.
END.



