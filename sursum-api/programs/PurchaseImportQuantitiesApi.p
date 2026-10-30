BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE hOrders AS HANDLE NO-UNDO.
DEFINE VARIABLE hCompanies AS HANDLE NO-UNDO.
DEFINE VARIABLE hItems AS HANDLE NO-UNDO.
DEFINE VARIABLE hAllocations AS HANDLE NO-UNDO.
DEFINE VARIABLE hContainers AS HANDLE NO-UNDO.
DEFINE VARIABLE hSituations AS HANDLE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE cleanRequest AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('espec required',1).
 servicePath=SEARCH('sursum-api/programs/PurchaseImportQuantitiesService.r').
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Quantity service absent',1).
 CREATE BUFFER hOrders FOR TABLE 'espec.procs_compra'.
 CREATE BUFFER hCompanies FOR TABLE 'espec.empresas'.
 CREATE BUFFER hItems FOR TABLE 'espec.itens_proc_compra'.
 CREATE BUFFER hAllocations FOR TABLE 'espec.itens_container'.
 CREATE BUFFER hContainers FOR TABLE 'espec.pp-container'.
 CREATE BUFFER hSituations FOR TABLE 'espec.situacoes_container'.
 cleanRequest=CAST(poRequest:Clone(),JsonObject).
 IF cleanRequest:Has('resource') THEN cleanRequest:Remove('resource').
 RUN VALUE(servicePath)(hOrders,hCompanies,hItems,hAllocations,hContainers,hSituations,cleanRequest,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code','PURCHASE_QUANTITY_CONFIGURATION'). err:Add('status',503). err:Add('message','Quantidades indisponiveis.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hSituations) THEN DELETE OBJECT hSituations NO-ERROR.
  IF VALID-HANDLE(hContainers) THEN DELETE OBJECT hContainers NO-ERROR.
  IF VALID-HANDLE(hAllocations) THEN DELETE OBJECT hAllocations NO-ERROR.
  IF VALID-HANDLE(hItems) THEN DELETE OBJECT hItems NO-ERROR.
  IF VALID-HANDLE(hCompanies) THEN DELETE OBJECT hCompanies NO-ERROR.
  IF VALID-HANDLE(hOrders) THEN DELETE OBJECT hOrders NO-ERROR.
 END FINALLY.
END.
