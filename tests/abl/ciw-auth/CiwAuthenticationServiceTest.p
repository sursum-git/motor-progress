BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttUser
 FIELD Login AS CHARACTER FIELD senha AS CHARACTER FIELD ativo AS LOGICAL.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE resp AS JsonObject NO-UNDO.
DEFINE VARIABLE programPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
OUTPUT TO VALUE("ciw-auth-service-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 programPath=SEARCH("CiwAuthenticationService.p").
 RUN Check(programPath<>?,"authentication service missing").
 RUN ResetCase. RUN ExecuteCase. RUN GoodCase.
 RUN Check(resp:GetJsonArray("data"):GetJsonObject(1):GetCharacter("login")="CIW_TEST","canonical login").
 RUN ResetCase. req:Set("username","ciw_test"). RUN ExecuteCase. RUN GoodCase.
 RUN ResetCase. req:Set("username","UNKNOWN_TEST"). RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN ResetCase. FIND FIRST ttUser. ttUser.ativo=FALSE. RELEASE ttUser.
 RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN ResetCase. FIND FIRST ttUser. ttUser.ativo=?. RELEASE ttUser.
 RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN ResetCase. req:Set("password","wrong"). RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN ResetCase. req:Set("password",""). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. req:Remove("password"). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. req:Set("password",123). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. req:Add("provider","forged"). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. req:Set("operation","AUTHENTICATE"). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. req:Set("username",FILL("x",161)). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. req:Set("password",FILL("x",1025)). RUN ExecuteCase. RUN ErrorCase("AUTH_INVALID_REQUEST",400).
 RUN ResetCase. FIND FIRST ttUser. ttUser.senha=?. RELEASE ttUser.
 RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 /* Password is an opaque exact value; never include it in assertion messages. */
 RUN ResetCase. FIND FIRST ttUser. ttUser.senha="A'ç ". RELEASE ttUser.
 req:Set("password","A'ç "). RUN ExecuteCase. RUN GoodCase.
 req:Set("password","a'ç "). RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 req:Set("password","A'ç"). RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 req:Set("password","A'c "). RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN ResetCase. FIND FIRST ttUser. ttUser.Login="CAFE". RELEASE ttUser.
 req:Set("username","café"). RUN ExecuteCase. RUN GoodCase.
 CREATE ttUser. ASSIGN ttUser.Login="CAFÉ" ttUser.senha="CIW_TEST_SYNTHETIC" ttUser.ativo=TRUE. RELEASE ttUser.
 RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN ResetCase. RUN ExecuteCase. RUN GoodCase.
 FIND FIRST ttUser. ttUser.ativo=FALSE. RELEASE ttUser.
 RUN ExecuteCase. RUN ErrorCase("INVALID_CREDENTIALS",401).
 RUN Check(CAN-FIND(ttUser WHERE ttUser.Login="CIW_TEST"),"record retained").
 PUT UNFORMATTED "PASS " checks " service checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL " e:GetMessage(1) SKIP.
 END CATCH.
END.
OUTPUT CLOSE.
RUN CleanCase.
PROCEDURE ResetCase:
 RUN CleanCase.
 FOR EACH ttUser: DELETE ttUser. END.
 CREATE ttUser. ASSIGN ttUser.Login="CIW_TEST" ttUser.senha="CIW_TEST_SYNTHETIC" ttUser.ativo=TRUE. RELEASE ttUser.
 req=NEW JsonObject(). req:Add("operation","authenticate"). req:Add("username","CIW_TEST"). req:Add("password","CIW_TEST_SYNTHETIC").
END PROCEDURE.
PROCEDURE ExecuteCase:
 IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
 RUN VALUE(programPath)(INPUT BUFFER ttUser:HANDLE,req,OUTPUT resp).
END PROCEDURE.
PROCEDURE GoodCase:
 RUN Check(VALID-OBJECT(resp),"response present").
 RUN Check(resp:GetLogical("success"),"success expected").
 RUN Check(resp:GetJsonArray("data"):Length=1,"one identity").
 names=resp:GetJsonArray("data"):GetJsonObject(1):GetNames().
 RUN Check(EXTENT(names)=1,"minimal identity").
END PROCEDURE.
PROCEDURE ErrorCase:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN Check(VALID-OBJECT(resp),"error present").
 RUN Check(NOT resp:GetLogical("success"),"denial expected").
 RUN Check(resp:GetJsonObject("error"):GetCharacter("code")=codeValue,"error code").
 RUN Check(resp:GetJsonObject("error"):GetInteger("status")=statusValue,"error status").
 RUN Check(NOT resp:Has("data") AND NOT resp:Has("password"),"no data on error").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER description AS CHARACTER NO-UNDO.
 IF ok=? OR NOT ok THEN UNDO,THROW NEW Progress.Lang.AppError(description,0).
 checks = checks + 1.
END PROCEDURE.
PROCEDURE CleanCase:
 IF VALID-OBJECT(req) THEN DELETE OBJECT req.
 IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
END PROCEDURE.
