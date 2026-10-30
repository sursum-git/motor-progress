USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE issuer AS DynamicQueryClientCredentials NO-UNDO.
DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
DEFINE VARIABLE entries AS JsonArray NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE reply AS JsonObject NO-UNDO.
DEFINE VARIABLE queries AS JsonArray NO-UNDO.
DEFINE VARIABLE fileValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE secondToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE secretValue AS CHARACTER NO-UNDO INITIAL "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef".
DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE bodyValue AS LONGCHAR NO-UNDO INITIAL '~{"code":"saldo-estoque-por-referencia"~}'.
DEFINE VARIABLE ownsLock AS LOGICAL NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE storeParser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE storeFixture AS JsonObject NO-UNDO.
DEFINE VARIABLE malformed AS LONGCHAR NO-UNDO.
DEFINE VARIABLE storeFile AS CHARACTER NO-UNDO.
issuer=NEW DynamicQueryClientCredentials(). policy=NEW DynamicQueryConsumerPolicy().
fileValue=SESSION:TEMP-DIRECTORY + "oauth-test-" + HEX-ENCODE(GENERATE-UUID) + ".json".
cfg=NEW JsonObject(). cfg:Add("version",1). entries=NEW JsonArray(). cfg:Add("consumers",entries).
cfg:Add("accessTokenStore",fileValue + ".oauth.json").
entryValue=NEW JsonObject(). entryValue:Add("id","partner"). entryValue:Add("role","consumer"). entryValue:Add("active",TRUE).
entryValue:Add("tokenSha256",FILL("a",64)). entryValue:Add("expiresAtEpoch",2000000000).
entryValue:Add("clientSecretSha256",LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",secretValue)))).
entryValue:Set("tokenSha256",entryValue:GetCharacter("clientSecretSha256")).
queries=NEW JsonArray(). queries:Add("saldo-estoque-por-referencia"). entryValue:Add("queries",queries). entries:Add(entryValue).
cfg:WriteFile(fileValue,TRUE).
RUN checkCase(policy:isValid(cfg),"credential config valid").
requestValue=NEW JsonObject(). requestValue:Add("grant_type","client_credentials"). requestValue:Add("client_id","partner"). requestValue:Add("client_secret",secretValue).
reply=issuer:issue(fileValue,requestValue,1800000000,OUTPUT statusValue).
RUN checkCase(statusValue=200,"issue").
RUN checkCase(reply:GetInteger("expires_in")=900 AND reply:GetCharacter("token_type")="Bearer","15 minute response").
tokenValue=reply:GetCharacter("access_token").
RUN checkCase(LENGTH(tokenValue)=64 AND tokenValue<>secretValue,"distinct opaque token").
RUN authCase(tokenValue,1800000000,200,"issued token accepted").
RUN authCase(tokenValue,1800000899,200,"before expiry").
RUN authCase(tokenValue,1800000900,401,"exact expiry").
RUN authCase(secretValue,1800000000,401,"secret is not query token").
reply=policy:authorize(cfg,"Bearer " + secretValue,"POST","/SursumDynamicQuery/query",bodyValue,1800000000,OUTPUT statusValue).
RUN checkCase(statusValue=401,"secret not legacy token").
bodyValue='~{"code":"not-allowed"~}'. RUN authCase(tokenValue,1800000000,403,"query permission").
bodyValue='~{"code":"saldo-estoque-por-referencia"~}'.
reply=issuer:authorize(cfg,fileValue,"Bearer " + tokenValue,"GET","/SursumDynamicQuery/consumers","",1800000000,OUTPUT statusValue).
RUN checkCase(statusValue=403,"token cannot administer").
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). secondToken=reply:GetCharacter("access_token").
RUN checkCase(statusValue=200 AND secondToken<>tokenValue,"automatic reacquisition").
RUN authCase(tokenValue,1800000010,200,"multiple valid tokens coexist").
RUN authCase(secondToken,1800000901,200,"new token survives previous expiry").
requestValue:Set("client_secret",FILL("b",64)). reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue).
RUN checkCase(statusValue=401,"incorrect secret").
requestValue:Set("client_secret",secretValue). requestValue:Set("client_id","missing").
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). RUN checkCase(statusValue=401,"unknown client").
requestValue:Set("client_id","partner"). requestValue:Add("scope","admin").
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). RUN checkCase(statusValue=400,"no scope elevation"). requestValue:Remove("scope").
entryValue:Set("active",FALSE). cfg:WriteFile(fileValue,TRUE).
RUN authCase(tokenValue,1800000010,401,"immediate revoke").
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). RUN checkCase(statusValue=401,"revoked cannot issue").
entryValue:Set("active",TRUE). entryValue:Set("expiresAtEpoch",1800000010). cfg:WriteFile(fileValue,TRUE).
RUN authCase(tokenValue,1800000010,401,"authorization expiry").
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). RUN checkCase(statusValue=401,"expired authorization cannot renew").
entryValue:Set("expiresAtEpoch",2000000000). entryValue:Set("clientSecretSha256",FILL("c",64)). cfg:WriteFile(fileValue,TRUE).
RUN authCase(tokenValue,1800000010,401,"secret rotation invalidates access tokens").
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). RUN checkCase(statusValue=401,"old secret invalid").
entryValue:Set("clientSecretSha256",LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",secretValue)))).
entryValue:Set("queries",NEW JsonArray()). cfg:WriteFile(fileValue,TRUE). RUN authCase(tokenValue,1800000010,403,"permission removal immediate").
entryValue:Set("role","admin"). RUN checkCase(NOT policy:isValid(cfg),"admin cannot become issuer client"). entryValue:Set("role","consumer").
entryValue:Set("queries",queries). cfg:WriteFile(fileValue,TRUE).
RUN QueryConsumerConfigIo.p("acquire",fileValue + ".oauth.json","",OUTPUT ownsLock).
reply=issuer:issue(fileValue,requestValue,1800000010,OUTPUT statusValue). RUN checkCase(statusValue=409,"issuance lock").
RUN QueryConsumerConfigIo.p("release",fileValue + ".oauth.json","",OUTPUT ownsLock).
DO n=1 TO 25: reply=issuer:issue(fileValue,requestValue,1800000020,OUTPUT statusValue). END.
RUN checkCase(statusValue=429,"bounded active tokens per consumer").
reply=issuer:issue(fileValue,requestValue,1800001000,OUTPUT statusValue). RUN checkCase(statusValue=200,"expired tokens pruned").
storeParser=NEW ObjectModelParser(). storeFixture=CAST(storeParser:ParseFile(fileValue + ".oauth.json"),JsonObject).
storeFixture:Set("window",1800001000). storeFixture:Set("attempts",300). storeFixture:WriteFile(fileValue + ".oauth.json",TRUE).
reply=issuer:issue(fileValue,requestValue,1800001000,OUTPUT statusValue). RUN checkCase(statusValue=429,"global attempt limit").
reply=issuer:issue(fileValue,requestValue,1800001060,OUTPUT statusValue). RUN checkCase(statusValue=200,"rate window recovery").
storeFile=fileValue + ".oauth.json". malformed="{}". COPY-LOB FROM malformed TO FILE storeFile.
reply=issuer:issue(fileValue,requestValue,1800001060,OUTPUT statusValue). RUN checkCase(statusValue=503,"corrupt store denies issuance").
RUN authCase(tokenValue,1800000000,503,"corrupt store denies token authorization").
reply=issuer:issue(fileValue + ".missing",requestValue,1800001060,OUTPUT statusValue). RUN checkCase(statusValue=503,"missing policy denies issuance").
cfg:Set("accessTokenStore",fileValue + ".private.json"). cfg:WriteFile(fileValue,TRUE).
reply=issuer:issue(fileValue,requestValue,1800001060,OUTPUT statusValue). RUN checkCase(statusValue=200,"configured private store").
tokenValue=reply:GetCharacter("access_token").
RUN QueryConsumerConfigIo.p("readable",fileValue + ".private.json","",OUTPUT ownsLock). RUN checkCase(ownsLock,"private store created").
RUN authCase(tokenValue,1800001060,200,"private store token authorized").
cfg:Set("accessTokenStore","relative-store.json"). cfg:WriteFile(fileValue,TRUE).
reply=issuer:issue(fileValue,requestValue,1800001060,OUTPUT statusValue). RUN checkCase(statusValue=503,"relative private store rejected").
cfg:Remove("accessTokenStore"). cfg:WriteFile(fileValue,TRUE).
reply=issuer:issue(fileValue,requestValue,1800001060,OUTPUT statusValue). RUN checkCase(statusValue=503,"unconfigured store denies issuance").
OUTPUT TO "client-credentials-tests.log". PUT UNFORMATTED "PASS " checks " client credentials checks; NUMDBS=" NUM-DBS SKIP. OUTPUT CLOSE.
OS-DELETE VALUE(fileValue) VALUE(fileValue + ".oauth.json").
OS-DELETE VALUE(fileValue + ".private.json").
DELETE OBJECT issuer. DELETE OBJECT policy.
PROCEDURE authCase:
 DEFINE INPUT PARAMETER token AS CHARACTER. DEFINE INPUT PARAMETER moment AS INT64.
 DEFINE INPUT PARAMETER expected AS INTEGER. DEFINE INPUT PARAMETER labelValue AS CHARACTER.
 reply=issuer:authorize(cfg,fileValue,"Bearer " + token,"POST","/SursumDynamicQuery/query",bodyValue,moment,OUTPUT statusValue).
 RUN checkCase(statusValue=expected,labelValue).
END PROCEDURE.
PROCEDURE checkCase:
 DEFINE INPUT PARAMETER passed AS LOGICAL. DEFINE INPUT PARAMETER labelValue AS CHARACTER.
 IF passed<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + labelValue + " status=" + STRING(statusValue),0).
 checks=checks + 1.
END PROCEDURE.
