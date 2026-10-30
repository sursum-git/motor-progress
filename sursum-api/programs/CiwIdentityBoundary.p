/* Fronteira pura compartilhada pelo wrapper real e testes. Sem acesso a bancos. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poHeaders AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poConfig AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poIdentity AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE digestValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER NO-UNDO.
DEFINE VARIABLE actionName AS CHARACTER NO-UNDO.
DEFINE VARIABLE appName AS CHARACTER NO-UNDO.
DEFINE VARIABLE headerValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE allowed AS JsonArray NO-UNDO.
DEFINE VARIABLE allowedCopy AS JsonArray NO-UNDO.
FUNCTION TextValue RETURNS CHARACTER (o AS JsonObject,k AS CHARACTER):
 IF NOT VALID-OBJECT(o) THEN RETURN ?.
 IF NOT o:Has(k) THEN RETURN ?.
 IF o:GetType(k)<>JsonDataType:STRING THEN RETURN ?.
 RETURN o:GetCharacter(k).
END FUNCTION.
FUNCTION Exact RETURNS LOGICAL (a AS CHARACTER,b AS CHARACTER):
 IF a=? OR b=? THEN RETURN FALSE.
 RETURN LENGTH(a,"RAW")=LENGTH(b,"RAW") AND COMPARE(a,"EQ",b,"RAW").
END FUNCTION.
FUNCTION ValidHeader RETURNS LOGICAL (v AS CHARACTER,maxSize AS INTEGER):
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 IF v=? THEN RETURN FALSE.
 IF LENGTH(TRIM(v))=0 OR LENGTH(v)>maxSize THEN RETURN FALSE.
 DO i=1 TO LENGTH(v):
  IF ASC(SUBSTRING(v,i,1))<32 OR ASC(SUBSTRING(v,i,1))=127 THEN RETURN FALSE.
 END.
 RETURN TRUE.
END FUNCTION.
FUNCTION ValidProvider RETURNS LOGICAL (v AS CHARACTER):
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 IF NOT ValidHeader(v,80) THEN RETURN FALSE.
 DO i=1 TO LENGTH(v):
  IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.:-",SUBSTRING(v,i,1))=0 THEN RETURN FALSE.
 END.
 RETURN TRUE.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 tokenValue=TextValue(poHeaders,"token").
 IF NOT ValidHeader(tokenValue,128) THEN DO: RUN Fail("CIW_IDENTITY_REQUIRED",401). RETURN. END.
 IF LENGTH(tokenValue)<32 THEN DO: RUN Fail("CIW_IDENTITY_REQUIRED",401). RETURN. END.
 hashValue=TextValue(poConfig,"tokenSha256").
 IF hashValue=? THEN DO: RUN Fail("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
 IF LENGTH(hashValue)<>64 THEN DO: RUN Fail("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
 DO n=1 TO LENGTH(hashValue):
  IF INDEX("0123456789ABCDEF",CAPS(SUBSTRING(hashValue,n,1)))=0 THEN DO: RUN Fail("CIW_ACCESS_CONFIGURATION",500). RETURN. END.
 END.
 digestValue=HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue)).
 IF NOT Exact(CAPS(digestValue),CAPS(hashValue)) THEN DO:
  RUN Fail("CIW_IDENTITY_REQUIRED",401). RETURN.
 END.
 IF NOT VALID-OBJECT(poRequest) THEN DO: RUN Fail("CIW_ACCESS_INVALID_REQUEST",400). RETURN. END.
 names=poRequest:GetNames().
 IF EXTENT(names)<>1 THEN DO: RUN Fail("CIW_ACCESS_INVALID_REQUEST",400). RETURN. END.
 IF NOT Exact(names[1],"operation") OR NOT Exact(TextValue(poRequest,"operation"),"identify") THEN DO: RUN Fail("CIW_ACCESS_INVALID_REQUEST",400). RETURN. END.
 DO n=1 TO 3:
  headerValue=TextValue(poHeaders,ENTRY(n,"login,session_id,auth_provider")).
  IF NOT ValidHeader(headerValue,IF n=3 THEN 80 ELSE 256) THEN DO: RUN Fail("CIW_IDENTITY_REQUIRED",401). RETURN. END.
  IF n=3 THEN IF NOT ValidProvider(headerValue) THEN DO: RUN Fail("CIW_IDENTITY_REQUIRED",401). RETURN. END.
 END.
 IF NOT Exact(TextValue(poHeaders,"auth_provider"),"ima-user-web") THEN DO: RUN Fail("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
 IF NOT poConfig:Has("allowedAuthProviders") THEN DO: RUN Fail("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
 IF poConfig:GetType("allowedAuthProviders")<>JsonDataType:ARRAY THEN DO: RUN Fail("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
 allowed=poConfig:GetJsonArray("allowedAuthProviders"). allowedCopy=NEW JsonArray().
 DO j=1 TO allowed:Length:
  IF allowed:GetType(j)<>JsonDataType:STRING THEN DO: RUN Fail("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
  IF NOT ValidProvider(allowed:GetCharacter(j)) THEN DO: RUN Fail("CIW_AUTH_SOURCE_DENIED",403). RETURN. END.
  allowedCopy:Add(allowed:GetCharacter(j)).
 END.
 poIdentity=NEW JsonObject().
 DO n=1 TO 3:
  poIdentity:Add(ENTRY(n,"login,session_id,auth_provider"),TextValue(poHeaders,ENTRY(n,"login,session_id,auth_provider"))).
 END.
 poPolicy=NEW JsonObject(). poPolicy:Add("allowed_auth_providers",allowedCopy).
 CATCH e AS Progress.Lang.Error:
  RUN Fail("CIW_ACCESS_CONFIGURATION",500).
 END CATCH.
 FINALLY:
  IF VALID-OBJECT(poResponse) THEN DO:
   IF VALID-OBJECT(poIdentity) THEN DELETE OBJECT poIdentity.
   IF VALID-OBJECT(poPolicy) THEN DELETE OBJECT poPolicy.
   IF VALID-OBJECT(allowedCopy) THEN DELETE OBJECT allowedCopy.
  END.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 err=NEW JsonObject(). err:Add("code",codeValue). err:Add("status",statusValue).
 err:Add("message","Solicitacao nao autorizada ou configuracao indisponivel.").
 poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.
