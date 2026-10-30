BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttUser FIELD Login AS CHARACTER FIELD senha AS CHARACTER FIELD ativo AS LOGICAL.
DEFINE VARIABLE boundary AS CiwAuthenticationBoundary NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE resp AS JsonObject NO-UNDO.
DEFINE VARIABLE body AS LONGCHAR NO-UNDO.
DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE methodValue AS CHARACTER NO-UNDO.
OUTPUT TO VALUE("ciw-auth-boundary-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 boundary=NEW CiwAuthenticationBoundary(SEARCH("CiwAuthenticationService.r")).
 cfg=NEW JsonObject(). cfg:Add("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",FILL("a",64)))).
 CREATE ttUser. ASSIGN ttUser.Login="CIW_TEST" ttUser.senha="CIW_AUTH_SYNTHETIC" ttUser.ativo=TRUE. RELEASE ttUser.
 body='~{"operation":"authenticate","username":"CIW_TEST","password":"CIW_AUTH_SYNTHETIC"~}'.
 resp=boundary:authenticate("POST","",body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(401).
 resp=boundary:authenticate("POST",FILL("b",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(401).
 DO n=1 TO 2:
  methodValue=ENTRY(n,"GET,OPTIONS").
  resp=boundary:authenticate(methodValue,FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
  RUN ErrorCase(405).
 END.
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN Check(statusValue=200 AND resp:GetLogical("success"),"boundary success").
 DELETE OBJECT resp.
 body='~{"operation":"authenticate","username":"CIW_TEST","password":"wrong"~}'.
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(401).
 body='[]'.
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(400).
 body='~{"password":"CIW_AUTH_SYNTHETIC"'.
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(400).
 body=FILL("x",16385).
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(400).
 body='~{"operation":"authenticate","username":"CIW_TEST","password":"CIW_AUTH_SYNTHETIC","table":"forged"~}'.
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(400).
 cfg:Remove("tokenSha256").
 resp=boundary:authenticate("POST",FILL("a",64),body,cfg,BUFFER ttUser:HANDLE,OUTPUT statusValue).
 RUN ErrorCase(503).
 PUT UNFORMATTED "PASS " checks " boundary checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
IF VALID-OBJECT(boundary) THEN DELETE OBJECT boundary.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER description AS CHARACTER NO-UNDO.
 IF ok=? OR NOT ok THEN UNDO,THROW NEW Progress.Lang.AppError(description,0).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE ErrorCase:
 DEFINE INPUT PARAMETER expected AS INTEGER NO-UNDO.
 DEFINE VARIABLE serialized AS LONGCHAR NO-UNDO.
 RUN Check(statusValue=expected,"boundary status").
 RUN Check(NOT resp:GetLogical("success"),"boundary denial").
 resp:Write(serialized).
 RUN Check(INDEX(serialized,"CIW_AUTH_SYNTHETIC")=0 AND INDEX(serialized,FILL("a",64))=0,"no credential in response").
 DELETE OBJECT resp.
END PROCEDURE.
