BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttUser FIELD Login AS CHARACTER FIELD ativo AS LOGICAL FIELD id AS INTEGER FIELD usuario AS CHARACTER FIELD tp-usuario AS INTEGER.
DEFINE VARIABLE ident AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE providers AS JsonArray NO-UNDO.
DEFINE VARIABLE passed AS INTEGER NO-UNDO.
DEFINE VARIABLE cService AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLog AS CHARACTER NO-UNDO.
cLog="ciw-identity-tests-" + SESSION:NUMERIC-FORMAT + ".log".
OUTPUT TO VALUE(cLog).
DO ON ERROR UNDO, THROW:
 cService=SEARCH("CiwIdentityService.p").
 RUN Check(cService<>?,"identity service must exist").
 RUN ResetFixture. RUN ExecuteService.
 RUN Check(response:GetLogical("success"),"active user").
 RUN Check(response:GetJsonArray("data"):GetJsonObject(1):GetCharacter("login")="CIW_TEST_USER","canonical login").
 RUN Check(response:GetJsonArray("data"):GetJsonObject(1):GetInteger("ima_user_id")=101,"legacy attributes").
 RUN Check(NOT response:GetJsonArray("data"):GetJsonObject(1):Has("senha"),"no credentials").
 RUN ResetFixture. ident:Remove("login"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_REQUIRED",401).
 RUN ResetFixture. ident:Remove("session_id"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_REQUIRED",401).
 RUN ResetFixture. ident:Set("auth_provider","local"). RUN ExecuteService. RUN ExpectError("CIW_AUTH_SOURCE_DENIED",403).
 RUN ResetFixture. policy:Set("allowed_auth_providers",NEW JsonArray()). RUN ExecuteService. RUN ExpectError("CIW_AUTH_SOURCE_DENIED",403).
 RUN ResetFixture. ident:Set("login","unknown"). RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_NOT_LINKED",403).
 RUN ResetFixture. FIND FIRST ttUser. ttUser.ativo=FALSE. RELEASE ttUser. RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_INACTIVE",403).
 RUN ResetFixture. FIND FIRST ttUser. ttUser.ativo=?. RELEASE ttUser. RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_INACTIVE",403).
 RUN ResetFixture. CREATE ttUser. ttUser.Login="ciw_test_user". ttUser.ativo=TRUE. RELEASE ttUser.
 RUN ExecuteService. RUN ExpectError("CIW_IDENTITY_AMBIGUOUS",409).
 RUN ResetFixture. RUN VALUE(cService)(?,ident,policy,OUTPUT response). RUN ExpectError("CIW_ACCESS_CONFIGURATION",500).
 PUT UNFORMATTED "PASS " passed " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE ResetFixture:
 EMPTY TEMP-TABLE ttUser.
 CREATE ttUser. ASSIGN ttUser.Login="CIW_TEST_USER" ttUser.ativo=TRUE ttUser.id=101 ttUser.usuario="CIW TEST" ttUser.tp-usuario=1. RELEASE ttUser.
 IF VALID-OBJECT(ident) THEN DELETE OBJECT ident.
 IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
 ident=NEW JsonObject(). ident:Add("login","ciw_test_user"). ident:Add("session_id","session-test"). ident:Add("auth_provider","ima-user-web").
 providers=NEW JsonArray(). providers:Add("ima-user-web").
 policy=NEW JsonObject(). policy:Add("allowed_auth_providers",providers).
END PROCEDURE.
PROCEDURE ExecuteService:
 IF VALID-OBJECT(response) THEN DELETE OBJECT response.
 RUN VALUE(cService)(INPUT BUFFER ttUser:HANDLE,INPUT ident,INPUT policy,OUTPUT response).
END PROCEDURE.
PROCEDURE ExpectError:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 RUN Check(NOT response:GetLogical("success"),"denied").
 RUN Check(response:GetJsonObject("error"):GetCharacter("code")=c,c).
 RUN Check(response:GetJsonObject("error"):GetInteger("status")=s,"status").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError(labelText,0).
 passed = passed + 1.
END PROCEDURE.
