/* Global selected-version readonly view; persistence stays in the central service. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTypes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phVersions AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phNfs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcCurrency AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{ContainersVersionComparisonTable.i}
DEFINE VARIABLE centralPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE assemblerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE opValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE nameValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE vid AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE reads AS INTEGER NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE completed AS LOGICAL NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE internalRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE internalResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotValue AS JsonObject NO-UNDO.
DEFINE VARIABLE materialized AS JsonObject NO-UNDO.
DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO.
DEFINE VARIABLE childValue AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
DEFINE VARIABLE rowBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE sourceField AS CHARACTER NO-UNDO.
FUNCTION PositiveKey RETURNS INTEGER(fieldName AS CHARACTER):
 DEFINE VARIABLE amountValue AS DECIMAL NO-UNDO.
 IF NOT poRequest:Has(fieldName) OR poRequest:GetType(fieldName)<>JsonDataType:NUMBER THEN RETURN ?.
 amountValue=poRequest:GetDecimal(fieldName).
 IF amountValue=? OR amountValue<1 OR amountValue>2147483647 OR amountValue<>TRUNCATE(amountValue,0) THEN RETURN ?.
 RETURN INTEGER(amountValue).
END FUNCTION.
DO ON ERROR UNDO, THROW:
 started=ETIME.
 IF pcCurrency<>'real' AND pcCurrency<>'dolar' THEN RUN Fail('COMPARISON_CONTEXT',422).
 resourceValue='container_custos_comparacao_' + pcCurrency.
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail('COMPARISON_REQUEST',422).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('COMPARISON_REQUEST',422).
 opValue=poRequest:GetCharacter('operation').
 IF opValue<>'read' AND opValue<>'get' THEN RUN Fail('COMPARISON_READ_ONLY',405).
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  nameValue=names[n].
  IF LOOKUP(nameValue,IF opValue='get' THEN 'operation,container_id,versao_id,id,record_key' ELSE 'operation,container_id,versao_id,skip,take,filter,sort')=0 THEN RUN Fail('COMPARISON_REQUEST',422).
 END.
 cid=PositiveKey('container_id'). vid=PositiveKey('versao_id').
 IF cid=? OR vid=? THEN RUN Fail('COMPARISON_CONTEXT',422).
 centralPath=SEARCH('sursum-api/programs/ContainersVersionService.r').
 readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 assemblerPath=SEARCH('sursum-api/programs/ContainersVersionComparisonMaterializer.r').
 IF centralPath=? OR readerPath=? OR assemblerPath=? OR NOT VALID-HANDLE(phMaster) THEN RUN Fail('COMPARISON_CONFIGURATION',503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  /* Source joins selected version/current items, without a master dependency. */
  internalRequest=NEW JsonObject(). internalRequest:Add('operation','consultar').
  internalRequest:Add('container_id',cid). internalRequest:Add('versao_id',vid).
  policyValue=NEW JsonObject(). policyValue:Add('read_max_rows',50000). policyValue:Add('read_require_master',FALSE).
  RUN VALUE(centralPath)(phMaster,phTypes,phVersions,phItems,phExpenses,phNfs,phPayments,phDiscounts,?,policyValue,internalRequest,OUTPUT internalResponse).
  IF NOT internalResponse:GetLogical('success') THEN DO: poResponse=CAST(internalResponse:Clone(),JsonObject). RETURN. END.
  snapshotValue=internalResponse:GetJsonObject('snapshot').
  reads=1.
  DO j=1 TO 5: reads=reads + snapshotValue:GetJsonArray(ENTRY(j,'items,expenses,nfs,payments,discounts')):Length. END.
  RUN VALUE(assemblerPath)(phAllocations,phPurchaseItems,snapshotValue,cid,vid,pcCurrency,started,INPUT-OUTPUT reads,OUTPUT materialized).
  IF NOT materialized:GetLogical('success') THEN DO: poResponse=CAST(materialized:Clone(),JsonObject). RETURN. END.
  rowsValue=materialized:GetJsonArray('data'). rowBuffer=BUFFER ttVersionComparison:HANDLE.
  DO n=1 TO rowsValue:Length:
   childValue=rowsValue:GetJsonObject(n). CREATE ttVersionComparison.
   DO j=1 TO rowBuffer:NUM-FIELDS:
    fieldValue=rowBuffer:BUFFER-FIELD(j).
    sourceField=IF fieldValue:NAME='projection_error' THEN '_projection_error' ELSE fieldValue:NAME.
    IF NOT childValue:Has(sourceField) THEN RUN Fail('COMPARISON_SNAPSHOT',503).
    IF childValue:IsNull(sourceField) THEN fieldValue:BUFFER-VALUE=?.
    ELSE CASE fieldValue:DATA-TYPE:
     WHEN 'INTEGER' THEN fieldValue:BUFFER-VALUE=childValue:GetInteger(sourceField).
     WHEN 'DECIMAL' THEN fieldValue:BUFFER-VALUE=childValue:GetDecimal(sourceField).
     WHEN 'CHARACTER' THEN fieldValue:BUFFER-VALUE=childValue:GetCharacter(sourceField).
     OTHERWISE RUN Fail('COMPARISON_CONFIGURATION',503).
    END CASE.
   END.
   RELEASE ttVersionComparison.
  END.
  clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('container_id'). clean:Remove('versao_id').
  RUN VALUE(readerPath)(INPUT BUFFER ttVersionComparison:HANDLE,resourceValue,'',clean,OUTPUT poResponse).
  completed=TRUE.
 END.
 IF NOT completed OR ETIME - started>10000 THEN RUN Fail('COMPARISON_READ_BUDGET',503).
 CATCH err AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('COMPARISON_CONFIGURATION',503).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(phMaster) THEN phMaster:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN ErrorResponse(codeValue,statusValue).
 UNDO,THROW NEW Progress.Lang.AppError(codeValue,1).
END PROCEDURE.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorValue=NEW JsonObject(). errorValue:Add('code',codeValue).
 errorValue:Add('status',statusValue). errorValue:Add('message','Consulta comparativa indisponivel.').
 poResponse:Add('success',FALSE). poResponse:Add('error',errorValue).
END PROCEDURE.
