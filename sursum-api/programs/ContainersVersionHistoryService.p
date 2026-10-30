/* Read-only adapter of the central persisted-version snapshot. No calculation. */
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
DEFINE INPUT PARAMETER phCurrentAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCurrentItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/ContainersVersionHistoryTable.i}
DEFINE VARIABLE central AS CHARACTER NO-UNDO.
DEFINE VARIABLE reader AS CHARACTER NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE vid AS INTEGER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
DEFINE VARIABLE rowBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE child AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshot AS JsonObject NO-UNDO.
DEFINE VARIABLE persisted AS JsonArray NO-UNDO.
DEFINE VARIABLE internalRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE internalResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DEFINE VARIABLE prefix AS CHARACTER NO-UNDO.
DEFINE VARIABLE clockStarted AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsRead AS INTEGER NO-UNDO.
DEFINE VARIABLE labelsPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE labelsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE labelId AS INTEGER NO-UNDO.
DEFINE VARIABLE labelKind AS CHARACTER NO-UNDO.
DEFINE VARIABLE labelField AS CHARACTER NO-UNDO.
DEFINE VARIABLE masterFound AS LOGICAL NO-UNDO.
DEFINE VARIABLE masterError AS INTEGER NO-UNDO.
FUNCTION Exact RETURNS LOGICAL(nameValue AS CHARACTER,listValue AS CHARACTER):
 DEFINE VARIABLE checkedValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE indexValue AS INTEGER NO-UNDO.
 checkedValue=nameValue.
 DO indexValue=1 TO NUM-ENTRIES(listValue): IF checkedValue=ENTRY(indexValue,listValue) THEN RETURN TRUE. END.
 RETURN FALSE.
END FUNCTION.
FUNCTION IdValue RETURNS INTEGER(nameValue AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL NO-UNDO.
 IF NOT poRequest:Has(nameValue) OR poRequest:GetType(nameValue)<>JsonDataType:NUMBER THEN RETURN ?.
 v=poRequest:GetDecimal(nameValue).
 IF v=? OR v<1 OR v>2147483647 OR v<>TRUNCATE(v,0) THEN RETURN ?.
 RETURN INTEGER(v).
END FUNCTION.
DO ON ERROR UNDO, THROW:
 clockStarted=ETIME.
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail('VERSION_HISTORY_REQUEST',422).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('VERSION_HISTORY_REQUEST',422).
 op=poRequest:GetCharacter('operation').
 IF op<>'read' AND op<>'get' THEN RUN Fail('VERSION_HISTORY_READ_ONLY',405).
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names):
  IF NOT Exact(names[n],IF op='get' THEN 'operation,container_id,versao_id,id,record_key' ELSE 'operation,container_id,versao_id,skip,take,filter,sort') THEN RUN Fail('VERSION_HISTORY_REQUEST',422).
 END.
 cid=IdValue('container_id'). vid=IdValue('versao_id').
 IF cid=? OR vid=? THEN RUN Fail('VERSION_HISTORY_CONTEXT',422).
 labelsPath=SEARCH('sursum-api/programs/ContainersVersionHistoryLabels.r').
 IF labelsPath=? THEN RUN Fail('VERSION_HISTORY_LABEL_CONFIGURATION',503).
 central=SEARCH('sursum-api/programs/ContainersVersionService.r'). reader=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF central=? OR reader=? OR NOT VALID-HANDLE(phMaster) THEN RUN Fail('VERSION_HISTORY_CONFIGURATION',503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  masterFound=phMaster:FIND-FIRST('WHERE ' + phMaster:NAME + '.nr-container=' + TRIM(STRING(cid,'->>>>>>>>>9')),NO-LOCK) NO-ERROR.
  DO masterError=1 TO ERROR-STATUS:NUM-MESSAGES:
   IF ERROR-STATUS:GET-NUMBER(masterError)<>565 THEN RUN Fail('VERSION_HISTORY_CONFIGURATION',503).
  END.
  IF NOT masterFound THEN RUN Fail('VERSION_HISTORY_PARENT',404).
  prefix=phMaster:BUFFER-FIELD('cod-estabel'):BUFFER-VALUE.
  IF prefix=? OR LENGTH(prefix)=0 THEN RUN Fail('VERSION_HISTORY_PARENT',404).
  IF SUBSTRING(prefix,1,1)<>'5' THEN RUN Fail('VERSION_HISTORY_PARENT',404).
  internalRequest=NEW JsonObject(). internalRequest:Add('operation','consultar'). internalRequest:Add('container_id',cid). internalRequest:Add('versao_id',vid).
  /* Reserve two parent reads outside central counted snapshot rows. */
  policy=NEW JsonObject(). policy:Add('read_max_rows',49998).
  RUN VALUE(central)(phMaster,phTypes,phVersions,phItems,phExpenses,phNfs,phPayments,phDiscounts,?,policy,internalRequest,OUTPUT internalResponse).
  IF NOT internalResponse:GetLogical('success') THEN DO: poResponse=CAST(internalResponse:Clone(),JsonObject). RETURN. END.
  snapshot=internalResponse:GetJsonObject('snapshot'). persisted=snapshot:GetJsonArray('items').
  rowsRead=3. DO j=1 TO 5: rowsRead=rowsRead + snapshot:GetJsonArray(ENTRY(j,'items,expenses,nfs,payments,discounts')):Length. END.
  DO n=1 TO persisted:Length:
   child=persisted:GetJsonObject(n).
   IF child:GetInteger('versao_id')<>vid OR child:GetInteger('item_container_custo_id')<=0 THEN RUN Fail('VERSION_HISTORY_IDENTITY',409).
   CREATE ttVersionHistory. ttVersionHistory.container_id=cid.
   rowBuffer=BUFFER ttVersionHistory:HANDLE.
   DO j=2 TO rowBuffer:NUM-FIELDS:
    fieldValue=rowBuffer:BUFFER-FIELD(j).
    IF fieldValue:NAME='item_descricao_atual' THEN NEXT.
    IF NOT child:Has(fieldValue:NAME) THEN RUN Fail('VERSION_HISTORY_SNAPSHOT',503).
    IF child:IsNull(fieldValue:NAME) THEN fieldValue:BUFFER-VALUE=?.
    ELSE CASE fieldValue:DATA-TYPE:
     WHEN 'INTEGER' THEN fieldValue:BUFFER-VALUE=child:GetInteger(fieldValue:NAME).
     WHEN 'DECIMAL' THEN fieldValue:BUFFER-VALUE=child:GetDecimal(fieldValue:NAME).
     WHEN 'CHARACTER' THEN fieldValue:BUFFER-VALUE=child:GetCharacter(fieldValue:NAME).
     OTHERWISE RUN Fail('VERSION_HISTORY_CONFIGURATION',503).
    END CASE.
   END.
   labelId=IF child:IsNull('item_container_id') THEN ? ELSE child:GetInteger('item_container_id').
   RUN VALUE(labelsPath)(phCurrentAllocations,phCurrentItems,?,?, 'item',labelId,clockStarted,INPUT-OUTPUT rowsRead,OUTPUT labelsValue).
   rowBuffer:BUFFER-FIELD('item_descricao_atual'):BUFFER-VALUE=IF labelsValue:IsNull('item_descricao_atual') THEN ? ELSE labelsValue:GetCharacter('item_descricao_atual').
   DELETE OBJECT labelsValue.
   RELEASE ttVersionHistory.
  END.
  clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('container_id'). clean:Remove('versao_id').
  RUN VALUE(reader)(INPUT BUFFER ttVersionHistory:HANDLE,'container_versoes_historico_med','',clean,OUTPUT poResponse).
  complete=TRUE.
 END.
 IF NOT complete OR ETIME - clockStarted>10000 THEN RUN Fail('VERSION_HISTORY_TIMEOUT',503).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('VERSION_HISTORY_CONFIGURATION',503).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(phMaster) THEN phMaster:BUFFER-RELEASE() NO-ERROR.
  IF VALID-OBJECT(internalRequest) THEN DELETE OBJECT internalRequest.
  IF VALID-OBJECT(internalResponse) THEN DELETE OBJECT internalResponse.
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
  IF VALID-OBJECT(labelsValue) THEN DELETE OBJECT labelsValue.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN ErrorResponse(codeValue,statusValue).
 UNDO, THROW NEW Progress.Lang.AppError(codeValue,1).
END PROCEDURE.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code',codeValue). err:Add('status',statusValue). err:Add('message','Consulta historica de versao indisponivel.').
 poResponse:Add('success',FALSE). poResponse:Add('error',err).
END PROCEDURE.
