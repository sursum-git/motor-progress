/* Somente ASCII no fonte: exercitar o mesmo JSON UTF8 em duas CPINTERNAL. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttUser FIELD Login AS CHARACTER FIELD senha AS CHARACTER FIELD ativo AS LOGICAL.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE resp AS JsonObject NO-UNDO.
DEFINE VARIABLE body AS LONGCHAR NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
FIX-CODEPAGE(body)="UTF-8".
OUTPUT TO VALUE("ciw-auth-encoding-" + SESSION:CPINTERNAL + ".log").
DO ON ERROR UNDO, THROW:
 CREATE ttUser. ASSIGN ttUser.Login="CIW_TEST" ttUser.senha="?" ttUser.ativo=TRUE. RELEASE ttUser.
 parser=NEW ObjectModelParser().
 body='~{"operation":"authenticate","username":"CIW_TEST","password":"\uD83D\uDE00"~}'.
 req=CAST(parser:Parse(body),JsonObject).
 RUN CiwAuthenticationService.r(INPUT BUFFER ttUser:HANDLE,req,OUTPUT resp).
 IF resp:GetLogical("success") THEN UNDO,THROW NEW Progress.Lang.AppError("Nonrepresentable password was accepted",0).
 checks=checks + 1.
 DELETE OBJECT req. DELETE OBJECT resp.
 DO n=512 TO 513:
  body='~{"operation":"authenticate","username":"CIW_TEST","password":"' + FILL('\u00e7',n) + '"~}'.
  req=CAST(parser:Parse(body),JsonObject).
  FIND FIRST ttUser. ttUser.senha=req:GetCharacter("password"). RELEASE ttUser.
  RUN CiwAuthenticationService.r(INPUT BUFFER ttUser:HANDLE,req,OUTPUT resp).
  IF n=512 THEN DO:
   IF NOT resp:GetLogical("success") THEN UNDO,THROW NEW Progress.Lang.AppError("UTF8 1024-byte password rejected",0).
  END.
  ELSE IF resp:GetLogical("success") THEN UNDO,THROW NEW Progress.Lang.AppError("UTF8 password limit depends on CPINTERNAL",0).
  ELSE IF resp:GetJsonObject("error"):GetInteger("status")<>400 THEN UNDO,THROW NEW Progress.Lang.AppError("UTF8 byte limit status",0).
  checks=checks + 1.
  DELETE OBJECT req. DELETE OBJECT resp.
 END.
 PUT UNFORMATTED "PASS " checks " encoding checks CPINTERNAL=" SESSION:CPINTERNAL SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) " CPINTERNAL=" SESSION:CPINTERNAL SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
QUIT.
