/* Native envelope adapter. All tax/calculated/stale rules remain in the core. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmpresas AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTaxBases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRelations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCalcs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE kind AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO. DEFINE VARIABLE rid AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'CONTAINER_EXPENSE_BATCH_VALIDATION'. DEFINE VARIABLE statusValue AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE changes AS JsonArray NO-UNDO. DEFINE VARIABLE rows AS JsonArray NO-UNDO. DEFINE VARIABLE results AS JsonArray NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO. DEFINE VARIABLE image AS JsonObject NO-UNDO. DEFINE VARIABLE valuesValue AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO. DEFINE VARIABLE policyValue AS JsonObject NO-UNDO. DEFINE VARIABLE expected AS JsonObject NO-UNDO.
DEFINE VARIABLE one AS JsonObject NO-UNDO. DEFINE VARIABLE seenIds AS JsonObject NO-UNDO. DEFINE VARIABLE seenClients AS JsonObject NO-UNDO.
DEFINE VARIABLE clientValue AS CHARACTER NO-UNDO. DEFINE VARIABLE fieldValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE t AS HANDLE NO-UNDO. DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE scanned AS INTEGER NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO. DEFINE VARIABLE finished AS LOGICAL NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE keyText AS LONGCHAR NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
{sursum-api/includes/ContainerExpenseBatchSnapshot.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 code=c. statusValue=s. UNDO, THROW NEW Progress.Lang.AppError(c,1).
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) OR NOT VALID-HANDLE(phContainer) OR NOT VALID-HANDLE(phExpenses) THEN RUN Fail(code,422).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING OR COMPARE(poRequest:GetCharacter('resource'),'<>','container-despesas-lote','RAW') THEN RUN Fail(code,422).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422).
 ASSIGN op=poRequest:GetCharacter('operation') cid=PurchaseJsonId(poRequest,'container_id').
 IF LOOKUP(op,'read,get,batch')=0 THEN RUN Fail('CONTAINER_EXPENSE_BATCH_OPERATION',405).
 EXTENT(names)=?. names=poRequest:GetNames(). DO j=1 TO EXTENT(names):
  IF LOOKUP(names[j],IF op='batch' THEN 'resource,operation,container_id,changes' ELSE IF op='get' THEN 'resource,operation,container_id,id,despesa_container_id' ELSE 'resource,operation,container_id,skip,take,filter,sort')=0 THEN RUN Fail(code,422).
 END.
 foundValue=phContainer:FIND-FIRST('WHERE nr-container=' + N(cid),NO-LOCK,NO-WAIT) NO-ERROR.
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN RUN Fail('CONTAINER_EXPENSE_BATCH_UNAVAILABLE',503). END.
 IF NOT foundValue THEN RUN Fail('CONTAINER_EXPENSE_BATCH_PARENT',404).
 IF phContainer:BUFFER-FIELD('cod-estabel'):BUFFER-VALUE=? OR NOT STRING(phContainer:BUFFER-FIELD('cod-estabel'):BUFFER-VALUE) BEGINS '5' THEN RUN Fail('CONTAINER_EXPENSE_BATCH_PARENT',404).
 IF op<>'batch' THEN DO:
  IF op='get' THEN DO:
   rid=PurchaseJsonId(poRequest,'id').
   IF poRequest:Has('despesa_container_id') AND PurchaseJsonId(poRequest,'despesa_container_id')<>rid THEN RUN Fail(code,422).
  END.
  CREATE TEMP-TABLE t. t:ADD-FIELDS-FROM(phExpenses). t:TEMP-TABLE-PREPARE('ttNativeExpenseRead'). b=t:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY q. q:SET-BUFFERS(phExpenses).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phExpenses:NAME + ' WHERE container_id=' + N(cid) + (IF op='get' THEN ' AND despesa_container_id=' + N(rid) ELSE '') + ' NO-LOCK') THEN RUN Fail('CONTAINER_EXPENSE_BATCH_CONFIGURATION',503).
  started=ETIME.
  DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
   q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
   DO WHILE NOT q:QUERY-OFF-END:
    scanned=scanned + 1. IF scanned>50000 OR ETIME - started>10000 THEN RUN Fail('CONTAINER_EXPENSE_BATCH_LIMIT',503).
    b:BUFFER-CREATE(). b:BUFFER-COPY(phExpenses). q:GET-NEXT(NO-LOCK).
   END.
   finished=TRUE.
  END.
  IF NOT finished THEN RUN Fail('CONTAINER_EXPENSE_BATCH_LIMIT',503).
  clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource'). clean:Remove('container_id').
  IF clean:Has('despesa_container_id') THEN clean:Remove('despesa_container_id').
  IF op='get' THEN DO: one=NEW JsonObject(). one:Add('despesa_container_id',rid). one:Write(keyText,FALSE). clean:Set('id',STRING(keyText)). END.
  pathValue=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF pathValue=? THEN RUN Fail('CONTAINER_EXPENSE_BATCH_CONFIGURATION',503).
  RUN VALUE(pathValue)(b,'container_despesas_lote',N(cid),clean,OUTPUT poResponse). RETURN.
 END.
 IF NOT poRequest:Has('changes') OR poRequest:GetType('changes')<>JsonDataType:ARRAY THEN RUN Fail(code,422).
 changes=poRequest:GetJsonArray('changes'). IF changes:Length<1 OR changes:Length>100 THEN RUN Fail(code,422).
 ASSIGN rows=NEW JsonArray() results=NEW JsonArray() expected=NEW JsonObject() seenIds=NEW JsonObject() seenClients=NEW JsonObject().
 DO j=1 TO changes:Length:
  IF changes:GetType(j)<>JsonDataType:OBJECT THEN RUN Fail(code,422).
  rowValue=changes:GetJsonObject(j). EXTENT(names)=?. names=rowValue:GetNames(). DO k=1 TO EXTENT(names): IF LOOKUP(names[k],'operation,clientId,id,data,original')=0 THEN RUN Fail(code,422). END.
  IF NOT rowValue:Has('operation') OR rowValue:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422).
  fieldValue=rowValue:GetCharacter('operation'). IF LOOKUP(fieldValue,'update,delete')=0 OR (kind<>'' AND fieldValue<>kind) THEN RUN Fail(code,422). kind=fieldValue.
  rid=PurchaseJsonId(rowValue,'id'). IF seenIds:Has(N(rid)) THEN RUN Fail(code,422). seenIds:Add(N(rid),TRUE).
  IF NOT rowValue:Has('clientId') OR rowValue:GetType('clientId')<>JsonDataType:STRING THEN RUN Fail(code,422).
  clientValue=rowValue:GetCharacter('clientId'). IF LENGTH(clientValue)<1 OR LENGTH(clientValue)>160 OR seenClients:Has(clientValue) THEN RUN Fail(code,422).
  DO k=1 TO LENGTH(clientValue): IF INDEX('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.:-',SUBSTRING(clientValue,k,1))=0 THEN RUN Fail(code,422). END. seenClients:Add(clientValue,TRUE).
  IF NOT rowValue:Has('original') OR rowValue:GetType('original')<>JsonDataType:OBJECT THEN RUN Fail(code,422).
  image=rowValue:GetJsonObject('original'). IF NOT ExpenseBatchImageValid(image) THEN RUN Fail(code,422).
  IF image:GetInteger('container_id')<>cid OR image:GetInteger('despesa_container_id')<>rid THEN RUN Fail(code,422).
  expected:Add(N(rid),CAST(image:Clone(),JsonObject)). one=NEW JsonObject(). one:Add('id',rid).
  IF kind='delete' THEN DO: IF rowValue:Has('data') THEN RUN Fail(code,422). END.
  ELSE DO:
   IF NOT rowValue:Has('data') OR rowValue:GetType('data')<>JsonDataType:OBJECT THEN RUN Fail(code,422).
   valuesValue=rowValue:GetJsonObject('data'). EXTENT(names)=?. names=valuesValue:GetNames(). IF EXTENT(names)=? OR EXTENT(names)=0 THEN RUN Fail(code,422).
   DO k=1 TO EXTENT(names):
    fieldValue=names[k]. IF LOOKUP(fieldValue,'vl_prev,vl_base_imp,log_manual')=0 THEN RUN Fail(code,422).
    IF valuesValue:GetType(fieldValue)<>(IF fieldValue='log_manual' THEN JsonDataType:BOOLEAN ELSE JsonDataType:NUMBER) THEN RUN Fail(code,422).
   END.
   one:Add('values',CAST(valuesValue:Clone(),JsonObject)).
  END.
  rows:Add(one). one=NEW JsonObject(). one:Add('clientId',clientValue). one:Add('id',rid). one:Add('operation',kind). results:Add(one).
 END.
 IF NOT VALID-OBJECT(poPolicy) THEN RUN Fail('CONTAINER_EXPENSE_BATCH_IDENTITY',401).
 policyValue=CAST(poPolicy:Clone(),JsonObject). IF policyValue:Has('batch_expected_before') THEN policyValue:Remove('batch_expected_before'). policyValue:Add('batch_expected_before',expected).
 clean=NEW JsonObject(). clean:Add('operation','batch_' + kind). clean:Add('container_id',cid). clean:Add('rows',rows).
 pathValue=SEARCH('sursum-api/programs/ContainersDespesasCrudService.r'). IF pathValue=? THEN RUN Fail('CONTAINER_EXPENSE_BATCH_CONFIGURATION',503).
 RUN VALUE(pathValue)(phContainer,phEmpresas,phItems,phPurchaseItems,phPurchases,phDefs,phLinks,phTaxBases,phRelations,phCalcs,phExpenses,phRuntime,policyValue,clean,OUTPUT poResponse).
 IF poResponse:GetLogical('success') THEN DO: poResponse:Add('committed',TRUE). poResponse:Add('results',results). END.
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject(). errorValue:Add('code',code). errorValue:Add('status',statusValue). errorValue:Add('message','Lote de despesas invalido ou indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(t) THEN DELETE OBJECT t NO-ERROR.
 END FINALLY.
END.
