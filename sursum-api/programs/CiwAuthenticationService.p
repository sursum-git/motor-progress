/* Credencial apenas em memoria. Sem SQL, logs, escrita ou sequencias. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phUser AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poCredentials AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hu AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE f AS HANDLE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE username AS CHARACTER NO-UNDO.
DEFINE VARIABLE supplied AS LONGCHAR NO-UNDO.
DEFINE VARIABLE stored AS CHARACTER NO-UNDO.
DEFINE VARIABLE canonical AS CHARACTER NO-UNDO.
DEFINE VARIABLE activeValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE matches AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE dataValue AS JsonArray NO-UNDO.
FUNCTION Exact RETURNS LOGICAL (a AS CHARACTER,b AS CHARACTER):
 IF a=? OR b=? THEN RETURN FALSE.
 RETURN LENGTH(a,"RAW")=LENGTH(b,"RAW") AND COMPARE(a,"EQ",b,"RAW").
END FUNCTION.
FUNCTION ExactPassword RETURNS LOGICAL (expected AS CHARACTER,actual AS LONGCHAR):
 DEFINE VARIABLE expectedUtf8 AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE a AS MEMPTR NO-UNDO.
 DEFINE VARIABLE b AS MEMPTR NO-UNDO.
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 IF expected=? OR actual=? THEN RETURN FALSE.
 DO ON ERROR UNDO, THROW:
  FIX-CODEPAGE(expectedUtf8)="UTF-8".
  expectedUtf8=expected.
  COPY-LOB FROM expectedUtf8 TO a NO-CONVERT.
  COPY-LOB FROM actual TO b NO-CONVERT.
  IF GET-SIZE(a)<>GET-SIZE(b) THEN RETURN FALSE.
  DO i=1 TO GET-SIZE(a):
   IF GET-BYTE(a,i)<>GET-BYTE(b,i) THEN RETURN FALSE.
  END.
  RETURN TRUE.
  FINALLY:
   SET-SIZE(a)=0. SET-SIZE(b)=0.
   expectedUtf8="".
  END FINALLY.
 END.
END FUNCTION.
FUNCTION Fold RETURNS CHARACTER (v AS CHARACTER):
 DEFINE VARIABLE result AS CHARACTER NO-UNDO.
 DEFINE VARIABLE groupsValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE ch AS CHARACTER NO-UNDO.
 DEFINE VARIABLE i AS INTEGER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 IF v=? THEN RETURN ?.
 groupsValue="áàãâäÁÀÃÂÄ|éèêëÉÈÊË|íìîïÍÌÎÏ|óòõôöÓÒÕÔÖ|úùûüÚÙÛÜ|ñÑ|çÇ".
 DO i=1 TO LENGTH(v):
  ch=SUBSTRING(v,i,1).
  DO j=1 TO 7:
   IF INDEX(ENTRY(j,groupsValue,"|"),ch)>0 THEN DO:
    ch=SUBSTRING("aeiounc",j,1). LEAVE.
   END.
  END.
  result=result + ch.
 END.
 RETURN CAPS(result).
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poCredentials) THEN DO: RUN Fail("AUTH_INVALID_REQUEST",400). RETURN. END.
 names=poCredentials:GetNames().
 IF EXTENT(names)<>3 THEN DO: RUN Fail("AUTH_INVALID_REQUEST",400). RETURN. END.
 DO n=1 TO EXTENT(names):
  IF NOT Exact(names[n],"operation") AND NOT Exact(names[n],"username") AND NOT Exact(names[n],"password") THEN DO:
   RUN Fail("AUTH_INVALID_REQUEST",400). RETURN.
  END.
  IF poCredentials:GetType(names[n])<>JsonDataType:STRING THEN DO: RUN Fail("AUTH_INVALID_REQUEST",400). RETURN. END.
 END.
 IF NOT Exact(poCredentials:GetCharacter("operation"),"authenticate") THEN DO: RUN Fail("AUTH_INVALID_REQUEST",400). RETURN. END.
 username=poCredentials:GetCharacter("username"). supplied=poCredentials:GetLongchar("password","UTF-8").
 IF LENGTH(TRIM(username))=0 OR LENGTH(username)>160 OR LENGTH(supplied,"RAW")=0 OR LENGTH(supplied,"RAW")>1024 THEN DO:
  RUN Fail("AUTH_INVALID_REQUEST",400). RETURN.
 END.
 IF NOT VALID-HANDLE(phUser) THEN DO: RUN Fail("AUTH_PROVIDER_UNAVAILABLE",503). RETURN. END.
 IF phUser:TYPE<>"BUFFER" THEN DO: RUN Fail("AUTH_PROVIDER_UNAVAILABLE",503). RETURN. END.
 DO n=1 TO 3:
  f=phUser:BUFFER-FIELD(ENTRY(n,"Login,senha,ativo")).
  IF f:DATA-TYPE<>(IF n=3 THEN "LOGICAL" ELSE "CHARACTER") OR f:EXTENT<>0 THEN DO:
   RUN Fail("AUTH_PROVIDER_UNAVAILABLE",503). RETURN.
  END.
 END.
 CREATE BUFFER hu FOR TABLE phUser.
 CREATE QUERY q. q:SET-BUFFERS(hu).
 q:QUERY-PREPARE("FOR EACH " + hu:NAME + " NO-LOCK").
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  IF Exact(Fold(hu:BUFFER-FIELD("Login"):BUFFER-VALUE),Fold(username)) THEN DO:
   matches=matches + 1.
   IF matches>1 THEN DO: RUN Fail("INVALID_CREDENTIALS",401). RETURN. END.
   canonical=hu:BUFFER-FIELD("Login"):BUFFER-VALUE.
   stored=hu:BUFFER-FIELD("senha"):BUFFER-VALUE.
   activeValue=hu:BUFFER-FIELD("ativo"):BUFFER-VALUE.
  END.
  q:GET-NEXT(NO-LOCK).
 END.
 IF matches<>1 OR activeValue=? OR activeValue<>TRUE OR NOT ExactPassword(stored,supplied) THEN DO:
  RUN Fail("INVALID_CREDENTIALS",401). RETURN.
 END.
 rowValue=NEW JsonObject(). rowValue:Add("login",canonical).
 dataValue=NEW JsonArray(). dataValue:Add(rowValue).
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",dataValue).
 CATCH e AS Progress.Lang.Error:
  RUN Fail("AUTH_PROVIDER_UNAVAILABLE",503).
 END CATCH.
 FINALLY:
  supplied="". stored="".
  IF VALID-HANDLE(q) THEN DELETE OBJECT q.
  IF VALID-HANDLE(hu) THEN DELETE OBJECT hu.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 err=NEW JsonObject(). err:Add("code",codeValue). err:Add("status",statusValue).
 err:Add("message",IF statusValue=401 THEN "Usuario ou senha invalidos." ELSE "Autenticacao indisponivel ou solicitacao invalida.").
 poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). poResponse:Add("error",err).
END PROCEDURE.
