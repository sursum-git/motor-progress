/* Shared authenticated program boundary. Actual handler context owns logs. */
DEFINE VARIABLE apiCode AS CHARACTER NO-UNDO INITIAL "CONTAINER_AUTH_REQUIRED".
DEFINE VARIABLE apiMessage AS CHARACTER NO-UNDO INITIAL "Credencial da integracao invalida.".
DEFINE VARIABLE apiStatus AS INTEGER NO-UNDO INITIAL 401.
FUNCTION ContainerApiLogin RETURNS CHARACTER ():
 DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE configPath AS CHARACTER NO-UNDO.
 DEFINE VARIABLE configText AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
 DEFINE VARIABLE configValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE headerValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE loginValue AS CHARACTER NO-UNDO.
 DO ON ERROR UNDO, THROW:
  tokenValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_CONTAINERS_TOKEN") NO-ERROR.
  IF tokenValue=? OR LENGTH(tokenValue)<32 OR LENGTH(tokenValue)>128 THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  ASSIGN apiCode="CONTAINER_CONFIGURATION" apiMessage="Configuracao da integracao indisponivel." apiStatus=503.
  configPath=SEARCH("sursum-conf/containers-api.json").
  IF configPath=? THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  FIX-CODEPAGE(configText)="UTF-8". COPY-LOB FROM FILE configPath TO configText.
  parserValue=NEW ObjectModelParser(). configValue=CAST(parserValue:Parse(configText),JsonObject).
  ASSIGN apiCode="CONTAINER_AUTH_REQUIRED" apiMessage="Credencial da integracao invalida." apiStatus=401.
  IF CAPS(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",tokenValue)))<>CAPS(configValue:GetCharacter("tokenSha256")) THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  ASSIGN apiCode="CONTAINER_IDENTITY_REQUIRED" apiMessage="Usuario autenticado da integracao ausente ou divergente." apiStatus=401.
  headerValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_SURSUM_USER") NO-ERROR.
  IF headerValue=? OR TRIM(headerValue)="" OR LENGTH(headerValue)>384 THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  IF NOT VALID-OBJECT(PasoeExecutionContext:Current) THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  contextValue=PasoeExecutionContext:Current:toJson(). loginValue=contextValue:GetCharacter("currentUser").
  IF loginValue=? OR TRIM(loginValue)="" OR LENGTH(loginValue)>128 THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  IF URI:Decode(REPLACE(headerValue,"+"," "))<>loginValue THEN UNDO, THROW NEW Progress.Lang.AppError(apiMessage,1).
  RETURN loginValue.
  FINALLY:
   tokenValue="". configText="".
   IF VALID-OBJECT(contextValue) THEN DELETE OBJECT contextValue NO-ERROR.
   IF VALID-OBJECT(configValue) THEN DELETE OBJECT configValue NO-ERROR.
   IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue NO-ERROR.
  END FINALLY.
 END.
END FUNCTION.
