/* Fixture temporaria protegida: exercita somente temp-table, nao dados de negocio. */
USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER request AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER response AS JsonObject NO-UNDO.
DEFINE VARIABLE repo AS ApiExecutionRepository NO-UNDO.
DEFINE VARIABLE ctx AS PasoeExecutionContext NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE config AS JsonObject NO-UNDO.
DEFINE VARIABLE configFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE content AS LONGCHAR NO-UNDO.
DEFINE VARIABLE token AS CHARACTER NO-UNDO.
DEFINE VARIABLE modeName AS CHARACTER NO-UNDO.
DEFINE VARIABLE queued AS LOGICAL NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttBusiness FIELD businessValue AS INTEGER.
token=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_DESPESAS_TOKEN").
configFile=SEARCH("sursum-conf/despesas-api.json").
response=NEW JsonObject().
IF token="" OR token=? OR configFile=? THEN DO:
 response:Add("success",FALSE). err=NEW JsonObject(). err:Add("code","AUTH_REQUIRED"). err:Add("message","Credencial requerida"). err:Add("status",401). response:Add("error",err). RETURN.
END.
FIX-CODEPAGE(content)="UTF-8".
COPY-LOB FROM FILE configFile TO content.
parser=NEW ObjectModelParser(). config=CAST(parser:Parse(content),JsonObject).
IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",token))) <> CAPS(config:GetCharacter("tokenSha256")) THEN DO:
 response:Add("success",FALSE). err=NEW JsonObject(). err:Add("code","AUTH_REQUIRED"). err:Add("message","Credencial invalida"). err:Add("status",401). RETURN.
END.
repo=NEW ApiExecutionRepository(). ctx=PasoeExecutionContext:Current.
IF NOT VALID-OBJECT(ctx) THEN UNDO,THROW NEW Progress.Lang.AppError("Contexto nao associado",0).
modeName=IF request:Has("mode") THEN request:GetCharacter("mode") ELSE "success".
response:Add("executionId",ctx:getCustomField("executionId")).
response:Add("pendingBefore",ctx:getLogMessages():Length).
IF modeName <> "silent" THEN DO:
 DO TRANSACTION ON ERROR UNDO, LEAVE:
  CREATE ttBusiness. ttBusiness.businessValue=42.
  queued=repo:logMessage("info","Log manual de teste: ação dentro da transação").
  IF modeName="rollback" THEN UNDO,LEAVE.
 END.
 response:Add("queued",queued).
 response:Add("businessRolledBack",NOT CAN-FIND(FIRST ttBusiness)).
 IF modeName="rollback" THEN queued=repo:logMessage("warning","Rollback de teste concluído").
END.
response:Add("transactionActiveAfter",TRANSACTION).
IF modeName="rollback" THEN DO:
 response:Add("success",FALSE). err=NEW JsonObject(). err:Add("code","PROBE_ROLLBACK"). err:Add("message","Rollback de fixture em temp-table"). err:Add("status",422). response:Add("error",err).
END.
ELSE response:Add("success",TRUE).
CATCH diagnostic AS Progress.Lang.Error:
 IF VALID-OBJECT(response) THEN DELETE OBJECT response.
 response=NEW JsonObject(). response:Add("success",FALSE).
 err=NEW JsonObject(). err:Add("code","PROBE_DIAGNOSTIC").
 err:Add("message",diagnostic:GetMessage(1)). err:Add("status",500).
 response:Add("error",err).
END CATCH.
FINALLY:
 IF VALID-OBJECT(repo) THEN DELETE OBJECT repo.
 IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
 IF VALID-OBJECT(config) THEN DELETE OBJECT config.
END FINALLY.
