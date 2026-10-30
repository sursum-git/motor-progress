BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE hdr AS JsonObject NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE ident AS JsonObject NO-UNDO.
DEFINE VARIABLE pol AS JsonObject NO-UNDO.
DEFINE VARIABLE resp AS JsonObject NO-UNDO.
DEFINE VARIABLE allowed AS JsonArray NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
OUTPUT TO VALUE("ciw-identity-boundary-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 pathValue=SEARCH("CiwIdentityBoundary.p").
 RUN Check(pathValue<>?,"identity boundary must exist").
 RUN ResetCase. RUN ExecuteCase. RUN Check(NOT VALID-OBJECT(resp),"valid request").
 RUN Check(ident:GetCharacter("login")="CIW_TEST_USER","trusted login").
 RUN ResetCase. hdr:Remove("token"). RUN ExecuteCase. RUN ErrorCase(401).
 RUN ResetCase. hdr:Set("token",FILL("b",64)). RUN ExecuteCase. RUN ErrorCase(401).
 RUN ResetCase. req:Add("login","admin"). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. req:Set("operation","authorize"). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. hdr:Set("auth_provider","local"). RUN ExecuteCase. RUN ErrorCase(403).
 RUN ResetCase. hdr:Remove("session_id"). RUN ExecuteCase. RUN ErrorCase(401).
 RUN ResetCase. cfg:Remove("tokenSha256"). RUN ExecuteCase. RUN ErrorCase(500).
 RUN ResetCase. cfg:Remove("allowedAuthProviders"). RUN ExecuteCase. RUN ErrorCase(403).
 PUT UNFORMATTED "PASS " checks " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE ResetCase:
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 IF VALID-OBJECT(hdr) THEN DELETE OBJECT hdr.
 IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
 req=NEW JsonObject(). req:Add("operation","identify").
 hdr=NEW JsonObject(). hdr:Add("token",FILL("a",64)). hdr:Add("login","CIW_TEST_USER"). hdr:Add("session_id","test-session"). hdr:Add("auth_provider","ima-user-web").
 allowed=NEW JsonArray(). allowed:Add("ima-user-web").
 cfg=NEW JsonObject(). cfg:Add("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",FILL("a",64)))). cfg:Add("allowedAuthProviders",allowed).
END PROCEDURE.
PROCEDURE ExecuteCase:
 IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
 IF VALID-OBJECT(ident) THEN DELETE OBJECT ident.
 IF VALID-OBJECT(pol) THEN DELETE OBJECT pol.
 RUN VALUE(pathValue)(INPUT req,INPUT hdr,INPUT cfg,OUTPUT ident,OUTPUT pol,OUTPUT resp).
END PROCEDURE.
PROCEDURE ErrorCase:
 DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 RUN Check(VALID-OBJECT(resp),"error envelope").
 RUN Check(NOT resp:GetLogical("success"),"denied").
 RUN Check(resp:GetJsonObject("error"):GetInteger("status")=s,"status").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError(labelText,0).
 checks = checks + 1.
END PROCEDURE.
