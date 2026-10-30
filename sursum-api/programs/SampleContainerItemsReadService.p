/* One global source projection, native reader for filters/sort/page/full-key GET. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/SampleContainerItemsTable.i}
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE defaultOrder AS JsonArray NO-UNDO.
DEFINE VARIABLE sortField AS JsonObject NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsRead AS INTEGER NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DEFINE VARIABLE rowBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE allowed AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE nameValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE foundName AS LOGICAL NO-UNDO.
DO ON ERROR UNDO, THROW:
 started=ETIME.
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail('SAMPLE_CONTAINER_ITEMS_REQUEST',422).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('SAMPLE_CONTAINER_ITEMS_REQUEST',422).
 op=poRequest:GetCharacter('operation'). IF op<>'read' AND op<>'get' THEN RUN Fail('SAMPLE_CONTAINER_ITEMS_READ_ONLY',405).
 allowed=IF op='read' THEN 'operation,skip,take,filter,sort' ELSE 'operation,id,record_key'.
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  nameValue=names[n]. foundName=FALSE.
  DO i=1 TO NUM-ENTRIES(allowed): IF nameValue=ENTRY(i,allowed) THEN foundName=TRUE. END.
  IF NOT foundName THEN RUN Fail('SAMPLE_CONTAINER_ITEMS_REQUEST',422).
 END.
 collectorPath=SEARCH('sursum-api/programs/SampleContainerItemsCollector.r'). readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF collectorPath=? OR readerPath=? THEN RUN Fail('SAMPLE_CONTAINER_ITEMS_CONFIGURATION',503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  RUN VALUE(collectorPath)(phAllocations,phContainers,phPurchaseItems,started,50000,INPUT-OUTPUT rowsRead,OUTPUT TABLE ttSampleContainerItems).
  clean=CAST(poRequest:Clone(),JsonObject).
  IF op='read' AND NOT clean:Has('sort') THEN DO:
   defaultOrder=NEW JsonArray(). sortField=NEW JsonObject(). sortField:Add('field','container_id'). sortField:Add('dir','asc'). defaultOrder:Add(sortField). clean:Add('sort',defaultOrder).
  END.
  rowBuffer=BUFFER ttSampleContainerItems:HANDLE.
  RUN VALUE(readerPath)(rowBuffer,'item_container_amostra','',clean,OUTPUT poResponse).
  complete=TRUE.
 END.
 IF NOT complete OR ETIME - started>10000 THEN RUN Fail('SAMPLE_CONTAINER_ITEMS_TIMEOUT',503).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('SAMPLE_CONTAINER_ITEMS_CONFIGURATION',503).
 END CATCH.
 FINALLY:
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN ErrorResponse(codeValue,statusValue). UNDO, THROW NEW Progress.Lang.AppError(codeValue,1).
END PROCEDURE.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code',codeValue). err:Add('status',statusValue). err:Add('message','Consulta de itens de amostra invalida ou indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',err).
END PROCEDURE.
