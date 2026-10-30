BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hSignals AS HANDLE NO-UNDO.
DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('espec required',1).
 servicePath=SEARCH('sursum-api/programs/PurchaseSignalConfigService.r').
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Signal configuration absent',1).
 CREATE BUFFER hSignals FOR TABLE 'espec.sinalizadores_importacao'.
 requestCopy=CAST(poRequest:Clone(),JsonObject).
 IF requestCopy:Has('resource') THEN requestCopy:Remove('resource').
 RUN VALUE(servicePath)(hSignals,requestCopy,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). err=NEW JsonObject(). poResponse:Add('success',FALSE).
  err:Add('code','PURCHASE_SIGNAL_CONFIG_CONFIGURATION'). err:Add('status',503).
  err:Add('message','Configuracao de sinalizadores indisponivel.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hSignals) THEN DELETE OBJECT hSignals NO-ERROR.
  IF VALID-OBJECT(requestCopy) THEN DELETE OBJECT requestCopy.
 END FINALLY.
END.
