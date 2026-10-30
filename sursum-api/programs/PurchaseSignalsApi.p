BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hOrders AS HANDLE NO-UNDO.
DEFINE VARIABLE hCompanies AS HANDLE NO-UNDO.
DEFINE VARIABLE hItems AS HANDLE NO-UNDO.
DEFINE VARIABLE hPayments AS HANDLE NO-UNDO.
DEFINE VARIABLE hSignals AS HANDLE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE cleanRequest AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('espec required',1).
 servicePath=SEARCH('sursum-api/programs/PurchaseSignalsService.r').
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Signal service absent',1).
 CREATE BUFFER hOrders FOR TABLE 'espec.procs_compra'.
 CREATE BUFFER hCompanies FOR TABLE 'espec.empresas'.
 CREATE BUFFER hItems FOR TABLE 'espec.itens_proc_compra'.
 CREATE BUFFER hPayments FOR TABLE 'espec.pagtos_proc_compra'.
 CREATE BUFFER hSignals FOR TABLE 'espec.sinalizadores_importacao'.
 cleanRequest=CAST(poRequest:Clone(),JsonObject).
 IF cleanRequest:Has('resource') THEN cleanRequest:Remove('resource').
 RUN VALUE(servicePath)(hOrders,hCompanies,hItems,hPayments,hSignals,TODAY,cleanRequest,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code','PURCHASE_SIGNAL_CONFIGURATION'). err:Add('status',503). err:Add('message','Alertas indisponiveis.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hSignals) THEN DELETE OBJECT hSignals NO-ERROR.
  IF VALID-HANDLE(hPayments) THEN DELETE OBJECT hPayments NO-ERROR.
  IF VALID-HANDLE(hItems) THEN DELETE OBJECT hItems NO-ERROR.
  IF VALID-HANDLE(hCompanies) THEN DELETE OBJECT hCompanies NO-ERROR.
  IF VALID-HANDLE(hOrders) THEN DELETE OBJECT hOrders NO-ERROR.
 END FINALLY.
END.
