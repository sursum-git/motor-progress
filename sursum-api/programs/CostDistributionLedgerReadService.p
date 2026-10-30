BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/CostDistributionLedgerTable.i}
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsRead AS INTEGER NO-UNDO.
DEFINE VARIABLE selectedId AS DECIMAL NO-UNDO.
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE allowed AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE nameValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE foundName AS LOGICAL NO-UNDO.
DEFINE VARIABLE rowBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DO ON ERROR UNDO, THROW:
 started=ETIME.
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail('COST_DISTRIBUTION_LEDGER_REQUEST',422).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('COST_DISTRIBUTION_LEDGER_REQUEST',422).
 op=poRequest:GetCharacter('operation'). IF op<>'read' AND op<>'get' THEN RUN Fail('COST_DISTRIBUTION_LEDGER_READ_ONLY',405).
 allowed=IF op='read' THEN 'operation,item_container_id,skip,take,filter,sort' ELSE 'operation,item_container_id,id,record_key'. names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  nameValue=names[n]. foundName=FALSE. DO i=1 TO NUM-ENTRIES(allowed): IF nameValue=ENTRY(i,allowed) THEN foundName=TRUE. END.
  IF NOT foundName THEN RUN Fail('COST_DISTRIBUTION_LEDGER_REQUEST',422).
 END.
 IF NOT poRequest:Has('item_container_id') OR poRequest:GetType('item_container_id')<>JsonDataType:NUMBER THEN RUN Fail('COST_DISTRIBUTION_LEDGER_CONTEXT',422).
 selectedId=poRequest:GetDecimal('item_container_id'). IF selectedId=? OR selectedId<1 OR selectedId>2147483647 OR selectedId<>TRUNCATE(selectedId,0) THEN RUN Fail('COST_DISTRIBUTION_LEDGER_CONTEXT',422).
 collectorPath=SEARCH('sursum-api/programs/CostDistributionLedgerCollector.r'). readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF collectorPath=? OR readerPath=? THEN RUN Fail('COST_DISTRIBUTION_LEDGER_CONFIGURATION',503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  RUN VALUE(collectorPath)(phLedger,INTEGER(selectedId),started,50000,INPUT-OUTPUT rowsRead,OUTPUT TABLE ttCostDistributionLedger).
  clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('item_container_id'). rowBuffer=BUFFER ttCostDistributionLedger:HANDLE.
  RUN VALUE(readerPath)(rowBuffer,'custo_distribuicao_lancamentos_item','',clean,OUTPUT poResponse). complete=TRUE.
 END.
 IF NOT complete OR ETIME - started>10000 THEN RUN Fail('COST_DISTRIBUTION_LEDGER_TIMEOUT',503).
 CATCH e AS Progress.Lang.Error: IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('COST_DISTRIBUTION_LEDGER_CONFIGURATION',503). END CATCH.
 FINALLY: IF VALID-OBJECT(clean) THEN DELETE OBJECT clean. END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN ErrorResponse(codeValue,statusValue). UNDO, THROW NEW Progress.Lang.AppError(codeValue,1).
END PROCEDURE.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO. DEFINE VARIABLE err AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code',codeValue). err:Add('status',statusValue). err:Add('message','Conta corrente de distribuicao invalida ou indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',err).
END PROCEDURE.
