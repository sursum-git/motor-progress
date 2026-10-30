BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE hdr AS JsonObject NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE ident AS JsonObject NO-UNDO.
DEFINE VARIABLE pol AS JsonObject NO-UNDO.
DEFINE VARIABLE resp AS JsonObject NO-UNDO.
DEFINE VARIABLE providers AS JsonArray NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
OUTPUT TO VALUE("ciw-access-boundary-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 pathValue=SEARCH("CiwAccessBoundary.p").
 RUN Check(pathValue<>?,"CiwAccessBoundary ainda nao implementado").
 RUN ResetCase. RUN ExecuteCase.
 RUN Check(NOT VALID-OBJECT(resp),"contrato valido passa a fronteira").
 RUN Check(pol:GetCharacter("legacy_application")="grid_pub_coloracoes","mapa privado grid").
 RUN Check(ident:GetCharacter("login")="CIW_TEST_USER","identidade de headers privados").
 RUN ResetCase. hdr:Remove("token"). RUN ExecuteCase. RUN ErrorCase(401).
 RUN ResetCase. hdr:Set("token",FILL("b",64)). RUN ExecuteCase. RUN ErrorCase(401).
 RUN ResetCase. cfg:Remove("tokenSha256"). RUN ExecuteCase. RUN ErrorCase(500).
 DO n=1 TO 5:
  RUN ResetCase. req:Add(ENTRY(n,"login,user,provider,table,application"),"forged").
  RUN ExecuteCase. RUN ErrorCase(400).
 END.
 RUN ResetCase. req:Set("operation","unknown"). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. req:Set("operation","AUTHORIZE"). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. req:Set("resource","other"). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. req:Set("action","unknown"). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. req:Set("action",NEW JsonArray()). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. req:Remove("action"). RUN ExecuteCase. RUN ErrorCase(400).
 DO n=1 TO 3:
  RUN ResetCase. hdr:Remove(ENTRY(n,"login,session_id,auth_provider")).
  RUN ExecuteCase. RUN ErrorCase(401).
 END.
 RUN ResetCase. req:Set("action","create"). RUN ExecuteCase.
 RUN Check(NOT VALID-OBJECT(resp),"acao create apenas autoriza, nao grava").
 RUN Check(pol:GetCharacter("legacy_application")="form_pub_coloracoes","mapa privado form").
 RUN ResetCase. req:Set("action","read "). RUN ExecuteCase. RUN ErrorCase(400).
 RUN ResetCase. hdr:Set("auth_provider","ima-ldap" + CHR(13)). RUN ExecuteCase. RUN ErrorCase(401).
 PUT UNFORMATTED "PASS " checks " boundary checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
RUN CleanCase.
PROCEDURE ResetCase:
 RUN CleanCase.
 req=NEW JsonObject(). hdr=NEW JsonObject(). cfg=NEW JsonObject(). providers=NEW JsonArray().
 req:Add("operation","authorize"). req:Add("resource","cadastros.coloracoes"). req:Add("action","read").
 hdr:Add("token",FILL("a",64)). hdr:Add("login","CIW_TEST_USER"). hdr:Add("session_id","CIW_TEST_SESSION"). hdr:Add("auth_provider","ima-ldap").
 cfg:Add("tokenSha256",HEX-ENCODE(MESSAGE-DIGEST("SHA-256",FILL("a",64)))).
 providers:Add("ima-ldap"). cfg:Add("allowedAuthProviders",providers).
END PROCEDURE.
PROCEDURE CleanCase:
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 IF VALID-OBJECT(hdr) THEN DELETE OBJECT hdr.
 IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
 IF VALID-OBJECT(providers) THEN DELETE OBJECT providers.
 IF VALID-OBJECT(ident) THEN DELETE OBJECT ident.
 IF VALID-OBJECT(pol) THEN DELETE OBJECT pol.
 IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
END PROCEDURE.
PROCEDURE ExecuteCase:
 IF VALID-OBJECT(ident) THEN DELETE OBJECT ident.
 IF VALID-OBJECT(pol) THEN DELETE OBJECT pol.
 IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
 RUN VALUE(pathValue)(req,hdr,cfg,OUTPUT ident,OUTPUT pol,OUTPUT resp).
END PROCEDURE.
PROCEDURE ErrorCase:
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN Check(VALID-OBJECT(resp),"erro presente").
 RUN Check(NOT resp:GetLogical("success"),"falha explicita").
 RUN Check(resp:GetJsonObject("error"):GetInteger("status")=statusCode,"status correto").
 RUN Check(NOT VALID-OBJECT(ident) AND NOT VALID-OBJECT(pol),"nao produz identidade/policy em falha").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER description AS CHARACTER NO-UNDO.
 IF ok=? OR NOT ok THEN UNDO,THROW NEW Progress.Lang.AppError(description,0).
 checks = checks + 1.
END PROCEDURE.
