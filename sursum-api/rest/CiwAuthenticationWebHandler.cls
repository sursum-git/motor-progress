USING Progress.Json.ObjectModel.*.
USING Progress.Web.IWebHandler.
USING OpenEdge.Web.WebResponse.
USING OpenEdge.Web.WebResponseWriter.
/* Entrada dedicada: nenhuma auditoria de payload nem dependencia do roteador. */
CLASS CiwAuthenticationWebHandler IMPLEMENTS IWebHandler:
 METHOD PUBLIC INTEGER HandleRequest():
  DEFINE VARIABLE boundary AS CiwAuthenticationBoundary NO-UNDO.
  DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE parsed AS JsonConstruct NO-UNDO.
  DEFINE VARIABLE responseValue AS WebResponse NO-UNDO.
  DEFINE VARIABLE writerValue AS WebResponseWriter NO-UNDO.
  DEFINE VARIABLE hu AS HANDLE NO-UNDO.
  DEFINE VARIABLE rawBody AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE body AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE configText AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE serialized AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE bufferValue AS MEMPTR NO-UNDO.
  DEFINE VARIABLE replyBytes AS MEMPTR NO-UNDO.
  DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE methodValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE statusValue AS INTEGER INITIAL 503 NO-UNDO.
  DO ON ERROR UNDO, THROW:
   FIX-CODEPAGE(body)="UTF-8". FIX-CODEPAGE(serialized)="UTF-8".
   FIX-CODEPAGE(configText)="UTF-8".
   methodValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","REQUEST_METHOD").
   tokenValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_CIW_AUTH_TOKEN").
   cfg=NEW JsonObject().
   /* Nao abrir banco/configuracao para credencial de transporte ausente. */
   IF LENGTH(tokenValue)=64 AND methodValue="POST" THEN DO:
    pathValue=SEARCH("sursum-conf/ciw-authentication.json").
    IF pathValue<>? THEN DO:
     COPY-LOB FROM FILE pathValue TO configText.
     parser=NEW ObjectModelParser(). parsed=parser:Parse(configText).
     DELETE OBJECT cfg. cfg=CAST(parsed,JsonObject).
    END.
   END.
   rawBody=WEB-CONTEXT:FORM-INPUT.
   IF rawBody<>? AND LENGTH(rawBody,"RAW")<=16384 THEN DO:
    COPY-LOB FROM rawBody TO bufferValue NO-CONVERT.
    COPY-LOB FROM bufferValue TO body CONVERT SOURCE CODEPAGE "UTF-8" NO-ERROR.
    IF ERROR-STATUS:ERROR THEN body=FILL("x",16385).
   END.
   ELSE body=FILL("x",16385).
   boundary=NEW CiwAuthenticationBoundary(SEARCH("sursum-api/programs/CiwAuthenticationService.r")).
   /* Buffers fixos; nenhum registro e lido antes de validar o token. */
   IF CONNECTED("espec") THEN CREATE BUFFER hu FOR TABLE "espec.user-web".
   reply=boundary:authenticate(methodValue,tokenValue,body,cfg,hu,OUTPUT statusValue).
   CATCH e AS Progress.Lang.Error:
    IF VALID-OBJECT(reply) THEN DELETE OBJECT reply.
    IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
    reply=NEW JsonObject().
    cfg=NEW JsonObject(). cfg:Add("code","AUTH_PROVIDER_UNAVAILABLE"). cfg:Add("status",503).
    cfg:Add("message","Autenticacao IMA indisponivel.").
    reply:Add("success",FALSE). reply:Add("error",cfg).
    statusValue=503.
   END CATCH.
  END.
  DO ON ERROR UNDO, THROW:
   reply:Write(serialized).
   responseValue=NEW WebResponse(statusValue). writerValue=NEW WebResponseWriter(responseValue).
   responseValue:SetHeader("Content-Type","application/json; charset=UTF-8").
   responseValue:SetHeader("Cache-Control","no-store").
   IF statusValue=405 THEN responseValue:SetHeader("Allow","POST").
   writerValue:Open().
   COPY-LOB FROM serialized TO replyBytes NO-CONVERT.
   writerValue:Write(replyBytes,1,GET-SIZE(replyBytes)).
   writerValue:Flush(). writerValue:Close().
   FINALLY:
    tokenValue="". rawBody="". body="". configText="".
    SET-SIZE(bufferValue)=0. SET-SIZE(replyBytes)=0.
    IF VALID-HANDLE(hu) THEN DELETE OBJECT hu.
    IF VALID-OBJECT(boundary) THEN DELETE OBJECT boundary.
    IF VALID-OBJECT(reply) THEN DELETE OBJECT reply.
    IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
    IF VALID-OBJECT(parsed) THEN DELETE OBJECT parsed.
    IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
    IF VALID-OBJECT(writerValue) THEN DELETE OBJECT writerValue.
    IF VALID-OBJECT(responseValue) THEN DELETE OBJECT responseValue.
   END FINALLY.
  END.
  RETURN 0.
 END METHOD.
END CLASS.
