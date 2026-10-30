/* Fixed MED projection of the legacy LEFT JOIN, global or process-contextual.
   Only temp rows are created. Rules, owner validation and reader are reused. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSituations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseImportQuantitiesTable.i}
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 collectorPath=SEARCH('sursum-api/programs/PurchaseImportQuantitiesCollector.r'). readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF collectorPath=? OR readerPath=? THEN UNDO,THROW NEW Progress.Lang.AppError('Coletor indisponivel.',1).
 RUN VALUE(collectorPath)(phOrders,phCompanies,phItems,phAllocations,phContainers,phSituations,poRequest,OUTPUT poResponse,OUTPUT TABLE ttQuantityRead,OUTPUT companyId).
 IF NOT poResponse:GetLogical('success') THEN RETURN.
 clean=CAST(poRequest:Clone(),JsonObject). IF clean:Has('proc_compra_id') THEN clean:Remove('proc_compra_id').
 RUN VALUE(readerPath)(INPUT BUFFER ttQuantityRead:HANDLE,'proc_compra_quantidades',TRIM(STRING(companyId,'->>>>>>>>>9')),clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code','PURCHASE_QUANTITY_CONFIGURATION'). err:Add('status',503). err:Add('message','Consulta de quantidades indisponivel.'). poResponse:Add('error',err).
 END CATCH.
END.
