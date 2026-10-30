/* Entrada fechada, somente leitura. X-CiwAccess-Token autentica o transporte PHP. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hdr AS JsonObject NO-UNDO.
DEFINE VARIABLE cfg AS JsonObject NO-UNDO.
DEFINE VARIABLE ident AS JsonObject NO-UNDO.
DEFINE VARIABLE pol AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE configText AS LONGCHAR NO-UNDO.
DEFINE VARIABLE configPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE boundaryPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE valueText AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE hu AS HANDLE NO-UNDO.
DEFINE VARIABLE hm AS HANDLE NO-UNDO.
DEFINE VARIABLE hg AS HANDLE NO-UNDO.
DO ON ERROR UNDO, THROW:
 tokenValue=WEB-CONTEXT:GET-CGI-VALUE("ENV","HTTP_X_CIWACCESS_TOKEN") NO-ERROR.
 IF tokenValue=? THEN tokenValue="".
 IF LENGTH(tokenValue)<32 OR LENGTH(tokenValue)>128 THEN DO: RUN Fail("CIW_IDENTITY_REQUIRED",401). RETURN. END.
 configPath=SEARCH("sursum-conf/ciw-access.json").
 boundaryPath=SEARCH("sursum-api/programs/CiwAccessBoundary.r").
 servicePath=SEARCH("sursum-api/programs/CiwAccessService.r").
 IF configPath=? OR boundaryPath=? OR servicePath=? THEN UNDO,THROW NEW Progress.Lang.AppError("Configuracao incompleta",0).
 FIX-CODEPAGE(configText)="UTF-8". COPY-LOB FROM FILE configPath TO configText.
 parser=NEW ObjectModelParser(). cfg=CAST(parser:Parse(configText),JsonObject).
 hdr=NEW JsonObject(). hdr:Add("token",tokenValue).
 DO n=1 TO 3:
  valueText=WEB-CONTEXT:GET-CGI-VALUE("ENV",ENTRY(n,"HTTP_X_SURSUM_USER,HTTP_X_SESSION_ID,HTTP_X_SURSUM_AUTH_SOURCE")) NO-ERROR.
  IF valueText<>? THEN hdr:Add(ENTRY(n,"login,session_id,auth_provider"),valueText).
 END.
 RUN VALUE(boundaryPath)(poRequest,hdr,cfg,OUTPUT ident,OUTPUT pol,OUTPUT poResponse).
 IF VALID-OBJECT(poResponse) THEN RETURN.
 IF NOT CONNECTED("espec") THEN UNDO,THROW NEW Progress.Lang.AppError("Banco fixo indisponivel",0).
 CREATE BUFFER hu FOR TABLE "espec.user-web".
 CREATE BUFFER hm FOR TABLE "espec.usuarios_grupos".
 CREATE BUFFER hg FOR TABLE "espec.grupos_aplicacoes".
 RUN VALUE(servicePath)(hu,hm,hg,ident,pol,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  RUN Fail("CIW_ACCESS_CONFIGURATION",500).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hu) THEN DELETE OBJECT hu.
  IF VALID-HANDLE(hm) THEN DELETE OBJECT hm.
  IF VALID-HANDLE(hg) THEN DELETE OBJECT hg.
  IF VALID-OBJECT(hdr) THEN DELETE OBJECT hdr.
  IF VALID-OBJECT(cfg) THEN DELETE OBJECT cfg.
  IF VALID-OBJECT(ident) THEN DELETE OBJECT ident.
  IF VALID-OBJECT(pol) THEN DELETE OBJECT pol.
  IF VALID-OBJECT(parser) THEN DELETE OBJECT parser.
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
