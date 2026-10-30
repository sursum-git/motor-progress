USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE policy AS DynamicQueryConsumerPolicy NO-UNDO.
DEFINE VARIABLE config AS JsonObject NO-UNDO.
DEFINE VARIABLE users AS JsonArray NO-UNDO.
DEFINE VARIABLE userEntry AS JsonObject NO-UNDO.
DEFINE VARIABLE adminEntry AS JsonObject NO-UNDO.
DEFINE VARIABLE queries AS JsonArray NO-UNDO.
DEFINE VARIABLE body AS LONGCHAR NO-UNDO.
DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE adminToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE checkCount AS INTEGER NO-UNDO.
DEFINE VARIABLE emptyConfig AS JsonObject NO-UNDO.
policy = NEW DynamicQueryConsumerPolicy().
tokenValue = FILL("a",64). adminToken = FILL("c",64).
config = NEW JsonObject(). config:Add("version",1).
users = NEW JsonArray(). config:Add("consumers",users).
userEntry = NEW JsonObject(). userEntry:Add("id","estoque-integracao").
userEntry:Add("active",TRUE). userEntry:Add("role","consumer").
userEntry:Add("expiresAtEpoch",2000000000).
userEntry:Add("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue))).
queries = NEW JsonArray(). queries:Add("saldo-estoque-por-referencia").
userEntry:Add("queries",queries). users:Add(userEntry).
adminEntry = NEW JsonObject(). adminEntry:Add("id","web-admin").
adminEntry:Add("active",TRUE). adminEntry:Add("role","admin").
adminEntry:Add("expiresAtEpoch",2000000000).
adminEntry:Add("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",adminToken))).
adminEntry:Add("queries",NEW JsonArray()). users:Add(adminEntry).
body = '~{"code":"saldo-estoque-por-referencia","parameters":~{"querystring":~{"item":"0001"~}~}~}'.
RUN Check("permitida",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,200).
RUN Check('async',config,'Bearer ' + tokenValue,'POST','/SursumDynamicQuery/query','~{"code":"saldo-estoque-por-referencia","execution":"async"~}',1700000000,200).
RUN Check('job status',config,'Bearer ' + tokenValue,'GET','/SursumDynamicQuery/consumer-jobs/JOB-20261028-000001-123456','',1700000000,200).
RUN Check('job result',config,'Bearer ' + tokenValue,'GET','/SursumDynamicQuery/consumer-jobs/JOB-20261028-000001-123456/result','',1700000000,200).
RUN Check('job token required',config,'','GET','/SursumDynamicQuery/consumer-jobs/JOB-20261028-000001-123456','',1700000000,401).
RUN Check('job invalid id',config,'Bearer ' + tokenValue,'GET','/SursumDynamicQuery/consumer-jobs/../consumers','',1700000000,403).
RUN Check('drain protected',config,'Bearer ' + tokenValue,'POST','/SursumDynamicQuery/consumer-jobs/drain','~{~}',1700000000,403).
RUN Check('legacy job protected',config,'Bearer ' + tokenValue,'GET','/SursumDynamicQuery/jobs/JOB-20261028-000001-123456','',1700000000,403).
RUN Check("sem token",config,"","POST","/SursumDynamicQuery/query",body,1700000000,401).
RUN Check("token incorreto",config,"Bearer " + FILL("b",64),"POST","/SursumDynamicQuery/query",body,1700000000,401).
RUN Check("basic",config,"Basic " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,401).
RUN Check("scheme case",config,"bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,200).
RUN Check("token case",config,"Bearer " + CAPS(tokenValue),"POST","/SursumDynamicQuery/query",body,1700000000,401).
RUN Check("token curto",config,"Bearer abc","POST","/SursumDynamicQuery/query",body,1700000000,401).
RUN Check("token grande",config,"Bearer " + tokenValue + "a","POST","/SursumDynamicQuery/query",body,1700000000,401).
RUN Check("expirado",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,2000000000,401).
userEntry:Set("active",FALSE).
RUN Check("revogado",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,401).
userEntry:Set("active",TRUE).
RUN Check("sem config",?,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
emptyConfig = NEW JsonObject().
RUN Check("config vazia",emptyConfig,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
RUN Check("sem permissao",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"outra"~}',1700000000,403).
RUN Check("case exato",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"SALDO-ESTOQUE-POR-REFERENCIA"~}',1700000000,403).
RUN Check("sem code",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"sources":[]~}',1700000000,403).
RUN Check("override",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","sources":[]~}',1700000000,400).
RUN Check("auto execution rejected",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","execution":"auto"~}',1700000000,400).
RUN Check("parameters tipo",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","parameters":[]~}',1700000000,400).
RUN Check("pagination",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","page":2,"pageSize":1000~}',1700000000,200).
RUN Check("cursor",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","paginationMode":"cursor","pageSize":20~}',1700000000,200).
RUN Check("cursor page conflict",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","paginationMode":"cursor","page":2~}',1700000000,400).
RUN Check("cursor full conflict",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","paginationMode":"cursor","paginate":false~}',1700000000,400).
RUN Check("cursor syntax",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","paginationMode":"cursor","cursor":"invalid"~}',1700000000,400).
RUN Check("cursor permission",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"outra","paginationMode":"cursor"~}',1700000000,403).
RUN Check("no pagination",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","paginate":false~}',1700000000,200).
RUN Check("paginate text",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","paginate":"false"~}',1700000000,400).
RUN Check("page bound",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","page":1000001~}',1700000000,400).
RUN Check("size bound",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","pageSize":1001~}',1700000000,400).
RUN Check("page text",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","page":"2"~}',1700000000,400).
RUN Check("size null",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","pageSize":null~}',1700000000,400).
RUN Check("page decimal",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","page":1.5~}',1700000000,400).
RUN Check("size boolean",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"saldo-estoque-por-referencia","pageSize":true~}',1700000000,400).
RUN Check("pagination permission",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"outra","page":2,"pageSize":2~}',1700000000,403).
RUN Check("json invalido",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{',1700000000,400).
RUN Check("array raiz",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'[]',1700000000,400).
RUN Check("code numero",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":123~}',1700000000,400).
RUN Check("traversal",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",'~{"code":"../saldo"~}',1700000000,400).
RUN Check("metodo get",config,"Bearer " + tokenValue,"GET","/SursumDynamicQuery/query",body,1700000000,403).
RUN Check("query store",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query-store",body,1700000000,403).
RUN Check("metadata",config,"Bearer " + tokenValue,"GET","/SursumDynamicQuery/metadata/databases","",1700000000,403).
RUN Check("logs",config,"Bearer " + tokenValue,"GET","/SursumDynamicQuery/executions","",1700000000,403).
RUN Check("context",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/context/config",'~{~}',1700000000,403).
RUN Check("program",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/program/execute",'~{~}',1700000000,403).
RUN Check("jobs",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/jobs/drain",'~{~}',1700000000,403).
RUN Check("prefixo falso",config,"Bearer " + tokenValue,"POST","/outro/query",body,1700000000,403).
RUN Check("admin metadata",config,"Bearer " + adminToken,"GET","/SursumDynamicQuery/metadata/databases","",1700000000,200).
RUN Check("admin store",config,"Bearer " + adminToken,"POST","/SursumDynamicQuery/query-store",'~{~}',1700000000,200).
RUN Check("admin livre",config,"Bearer " + adminToken,"POST","/SursumDynamicQuery/query",'~{"sources":[]~}',1700000000,200).
RUN Check("options",?,"","OPTIONS","/SursumDynamicQuery/query","",1700000000,204).
config:Set("version",2).
RUN Check("version",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
config:Set("version",1). userEntry:Set("tokenSha256","invalid").
RUN Check("hash invalido",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
userEntry:Set("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue))). adminEntry:Set("id","estoque-integracao").
RUN Check("id duplicado",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
adminEntry:Set("id","web-admin"). adminEntry:Set("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue))).
RUN Check("hash duplicado",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
adminEntry:Set("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",adminToken))). queries:Add("*").
RUN Check("wildcard",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
queries:Remove(2). userEntry:Set("role","ADMIN").
RUN Check("perfil estrito",config,"Bearer " + tokenValue,"POST","/SursumDynamicQuery/query",body,1700000000,503).
RUN CheckHeader("custom", "", tokenValue, "Bearer " + tokenValue).
RUN CheckHeader("bearer", "Bearer " + tokenValue, "", "Bearer " + tokenValue).
RUN CheckHeader("ambos iguais", "Bearer " + tokenValue, tokenValue, "Bearer " + tokenValue).
RUN CheckHeader("ambos scheme case", "bearer " + tokenValue, tokenValue, "Bearer " + tokenValue).
RUN CheckHeader("conflito", "Bearer " + FILL("b",64), tokenValue, "").
RUN CheckHeader("scheme invalido", "Basic " + tokenValue, tokenValue, "").
RUN CheckHeader("sem headers", "", "", "").
RUN CheckEpoch(DATETIME-TZ(1,1,1970,0,0,0,0,0),0).
RUN CheckEpoch(DATETIME-TZ(12,31,1969,21,0,0,0,-180),0).
RUN CheckEpoch(DATETIME-TZ(1,1,1970,0,0,0,0,-180),10800).
RUN CheckEpoch(DATETIME-TZ(1,1,1970,2,0,0,0,120),0).
RUN CheckEpoch(DATETIME-TZ(10,27,2026,11,28,22,0,-180),1793111302).
OUTPUT TO "temp/query-consumers-20261027/policy-tests.log".
PUT UNFORMATTED "PASS " checkCount " checks; NUMDBS=" NUM-DBS SKIP.
OUTPUT CLOSE.
DELETE OBJECT policy. DELETE OBJECT config. DELETE OBJECT emptyConfig.
PROCEDURE Check:
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER cfg AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER authValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER methodValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER pathValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER requestValue AS LONGCHAR NO-UNDO.
 DEFINE INPUT PARAMETER nowValue AS INT64 NO-UNDO.
 DEFINE INPUT PARAMETER expectedStatus AS INTEGER NO-UNDO.
 DEFINE VARIABLE decision AS JsonObject NO-UNDO.
 DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
 decision = policy:authorize(cfg,authValue,methodValue,pathValue,requestValue,nowValue,OUTPUT statusValue).
 IF statusValue <> expectedStatus OR decision:GetLogical("success") <> (statusValue < 300) THEN
  UNDO, THROW NEW Progress.Lang.AppError("FAIL " + labelText + ": " + STRING(statusValue) + " expected " + STRING(expectedStatus),0).
 IF statusValue = 200 THEN DO:
  IF authValue = "Bearer " + adminToken THEN DO:
   IF decision:GetCharacter("consumerId") <> "web-admin" THEN UNDO, THROW NEW Progress.Lang.AppError("Wrong admin identity",0).
  END.
  ELSE IF decision:GetCharacter("consumerId") <> "estoque-integracao" THEN UNDO, THROW NEW Progress.Lang.AppError("Wrong consumer identity",0).
 END.
 checkCount = checkCount + 1. DELETE OBJECT decision.
END PROCEDURE.

PROCEDURE CheckHeader:
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER bearerValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER customValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expectedValue AS CHARACTER NO-UNDO.
 IF NOT COMPARE(policy:credentialHeader(bearerValue,customValue),"EQ",expectedValue,"RAW") THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL header " + labelValue,0).
 checkCount=checkCount + 1.
END PROCEDURE.

PROCEDURE CheckEpoch:
 DEFINE INPUT PARAMETER moment AS DATETIME-TZ NO-UNDO.
 DEFINE INPUT PARAMETER expected AS INT64 NO-UNDO.
 IF policy:epochSeconds(moment)<>expected THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL UTC epoch",0).
 checkCount=checkCount + 1.
END PROCEDURE.
