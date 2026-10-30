/* Compatible contextual adapter; collection shared with global dashboard. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSignals AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pdToday AS DATE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseSignalsTable.i}
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE scanned AS INTEGER NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 collectorPath=SEARCH('sursum-api/programs/PurchaseSignalsCollector.r'). readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF collectorPath=? OR readerPath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Collector absent',1).
 RUN VALUE(collectorPath)(phOrders,phCompanies,phItems,phPayments,phSignals,pdToday,50000,ETIME,poRequest,OUTPUT poResponse,OUTPUT TABLE ttSignalRead,OUTPUT pid,OUTPUT scanned).
 IF NOT poResponse:GetLogical('success') THEN RETURN.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('proc_compra_id').
 RUN VALUE(readerPath)(INPUT BUFFER ttSignalRead:HANDLE,'proc_compra_alertas',TRIM(STRING(pid,'->>>>>>>>>9')),clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code','PURCHASE_SIGNAL_CONFIGURATION'). err:Add('status',503). err:Add('message','Consulta de alertas invalida ou indisponivel.'). poResponse:Add('error',err).
 END CATCH.
END.
