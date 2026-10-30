USING Progress.Json.ObjectModel.*.
/* Sem dependencia de auditoria/persistencia; nunca registra corpo ou excecao. */
CLASS CiwAuthenticationBoundary:
 DEFINE PRIVATE VARIABLE servicePath AS CHARACTER NO-UNDO.
 CONSTRUCTOR PUBLIC CiwAuthenticationBoundary(INPUT pcService AS CHARACTER):
  servicePath=pcService.
 END CONSTRUCTOR.
 METHOD PUBLIC JsonObject authenticate(
  INPUT pcMethod AS CHARACTER,INPUT pcToken AS CHARACTER,INPUT pcBody AS LONGCHAR,
  INPUT poConfig AS JsonObject,INPUT phUser AS HANDLE,OUTPUT piStatus AS INTEGER):
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DEFINE VARIABLE req AS JsonObject NO-UNDO.
  DEFINE VARIABLE resp AS JsonObject NO-UNDO.
  DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE digestValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  piStatus=503.
  DO ON ERROR UNDO, THROW:
   IF pcMethod=? THEN pcMethod="".
   IF NOT COMPARE(pcMethod,"EQ","POST","RAW") OR LENGTH(pcMethod)<>4 THEN DO:
    piStatus=405. RETURN THIS-OBJECT:failure("AUTH_METHOD_NOT_ALLOWED",piStatus).
   END.
   IF pcToken=? THEN pcToken="".
   IF LENGTH(pcToken)<>64 THEN DO:
    piStatus=401. RETURN THIS-OBJECT:failure("AUTH_INTEGRATION_REQUIRED",piStatus).
   END.
   IF NOT VALID-OBJECT(poConfig) THEN RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   IF NOT poConfig:Has("tokenSha256") THEN RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   IF poConfig:GetType("tokenSha256")<>JsonDataType:STRING THEN RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   hashValue=CAPS(poConfig:GetCharacter("tokenSha256")).
   IF LENGTH(hashValue)<>64 THEN RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   DO n=1 TO 64:
    IF INDEX("0123456789ABCDEF",SUBSTRING(hashValue,n,1))=0 THEN RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   END.
   digestValue=CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",pcToken))).
   IF NOT COMPARE(digestValue,"EQ",hashValue,"RAW") THEN DO:
    piStatus=401. RETURN THIS-OBJECT:failure("AUTH_INTEGRATION_REQUIRED",piStatus).
   END.
   IF pcBody=? OR LENGTH(pcBody,"RAW")>16384 THEN DO:
    piStatus=400. RETURN THIS-OBJECT:failure("AUTH_INVALID_REQUEST",piStatus).
   END.
   parser=NEW ObjectModelParser().
   parsed=parser:Parse(pcBody) NO-ERROR.
   IF ERROR-STATUS:ERROR OR NOT VALID-OBJECT(parsed) THEN DO:
    piStatus=400. RETURN THIS-OBJECT:failure("AUTH_INVALID_REQUEST",piStatus).
   END.
   req=CAST(parsed,JsonObject) NO-ERROR.
   IF NOT VALID-OBJECT(req) THEN DO:
    piStatus=400. RETURN THIS-OBJECT:failure("AUTH_INVALID_REQUEST",piStatus).
   END.
   IF servicePath=? OR servicePath="" THEN RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   RUN VALUE(servicePath)(phUser,req,OUTPUT resp).
   IF resp:GetLogical("success") THEN piStatus=200.
   ELSE piStatus=resp:GetJsonObject("error"):GetInteger("status").
   RETURN resp.
   CATCH e AS Progress.Lang.Error:
    IF VALID-OBJECT(resp) THEN DELETE OBJECT resp.
    piStatus=503. RETURN THIS-OBJECT:failure("AUTH_PROVIDER_UNAVAILABLE",piStatus).
   END CATCH.
   FINALLY:
    pcToken="". pcBody="".
    IF VALID-OBJECT(parsed) THEN DELETE OBJECT parsed.
    IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
   END FINALLY.
  END.
 END METHOD.
 METHOD PRIVATE JsonObject failure(INPUT codeValue AS CHARACTER,INPUT statusValue AS INTEGER):
  DEFINE VARIABLE err AS JsonObject NO-UNDO.
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  err=NEW JsonObject(). err:Add("code",codeValue). err:Add("status",statusValue).
  err:Add("message",IF statusValue=401 THEN "Usuario ou senha invalidos." ELSE "Autenticacao indisponivel ou solicitacao invalida.").
  reply=NEW JsonObject(). reply:Add("success",FALSE). reply:Add("error",err).
  RETURN reply.
 END METHOD.
END CLASS.
