/* Only shipment maintenance. Item format and fiscal/financial rules stay in PurchaseItemsService. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phSamples AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phReps AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdentity AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/PurchaseSampleSnapshot.i}
DEFINE TEMP-TABLE ttSampleRead NO-UNDO
 FIELD envio_amostra_repres_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD cod_rep AS INTEGER
 FIELD dt_envio AS DATE FIELD apont_amostra_id AS INTEGER FIELD proc_compra_id AS INTEGER
 FIELD row_stamp AS CHARACTER FIELD representante_nome AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE envio_amostra_repres_id.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SAMPLE'.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE recordId AS INTEGER NO-UNDO.
DEFINE VARIABLE repId AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SAMPLE_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE oldImage AS JsonObject NO-UNDO.
DEFINE VARIABLE newImage AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesObject AS JsonObject NO-UNDO.
DEFINE VARIABLE resultData AS JsonObject NO-UNDO.
DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE rawDate AS CHARACTER NO-UNDO.
DEFINE VARIABLE dateValue AS DATE NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsCount AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO.
DEFINE VARIABLE representativesSeen AS JsonObject NO-UNDO.
DEFINE VARIABLE writeComplete AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fieldNames AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 fieldNames=o:GetNames(). DO i=1 TO EXTENT(fieldNames):
  matched=FALSE. DO j=1 TO NUM-ENTRIES(allowed): IF COMPARE(fieldNames[i],'=',ENTRY(j,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN RUN Fail('PURCHASE_SAMPLE_FIELD_INVALID',422,'Campo nao permitido.').
 END.
END PROCEDURE.
{sursum-api/includes/PurchaseItemContext.i}
FUNCTION RepName RETURNS CHARACTER():
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
 idValue=phSamples:BUFFER-FIELD('cod_rep'):BUFFER-VALUE.
 IF idValue=? OR idValue<1 THEN RETURN ''.
 IF Found(phReps,'cod-rep=' + N(idValue),NO-LOCK) THEN RETURN STRING(phReps:BUFFER-FIELD('nome-abrev'):BUFFER-VALUE).
 RETURN ''.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phSamples) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phReps) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail('PURCHASE_SAMPLE_CONFIGURATION',503,'Configuracao de envios indisponivel.').
 pid=SampleId(poRequest,'proc_compra_id'). itemId=SampleId(poRequest,'item_proc_compra_id').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_SAMPLE_VALIDATION',422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation').
 IF LOOKUP(op,'read,get,create,update,delete,options')=0 THEN RUN Fail('PURCHASE_SAMPLE_OPERATION',405,'Operacao indisponivel.').
 RUN ContextCheck(NO-LOCK).
 IF op='options' THEN DO:
  RUN Closed(poRequest,'operation,proc_compra_id,item_proc_compra_id,lookup').
  IF NOT poRequest:Has('lookup') OR poRequest:GetType('lookup')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_SAMPLE_OPTIONS',422,'Consulta de opcoes invalida.').
  IF poRequest:GetCharacter('lookup')<>'representante' THEN RUN Fail('PURCHASE_SAMPLE_OPTIONS',422,'Consulta de opcoes invalida.').
  started=ETIME. rowsValue=NEW JsonArray(). representativesSeen=NEW JsonObject(). CREATE QUERY q. q:SET-BUFFERS(phReps).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phReps:NAME + ' WHERE ind-situacao=1 NO-LOCK BY nome-abrev BY cod-rep') THEN RUN Fail('PURCHASE_SAMPLE_OPTIONS',503,'Consulta de representantes recusada.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   rowsCount=rowsCount + 1. IF rowsCount>4000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_SAMPLE_LIMIT',503,'Consulta de representantes excedeu limite.').
   actor=NEW JsonObject(). actor:Add('value',INTEGER(phReps:BUFFER-FIELD('cod-rep'):BUFFER-VALUE)). actor:Add('text',N(phReps:BUFFER-FIELD('cod-rep'):BUFFER-VALUE) + ' - ' + STRING(phReps:BUFFER-FIELD('nome-abrev'):BUFFER-VALUE)). rowsValue:Add(actor). representativesSeen:Add(N(phReps:BUFFER-FIELD('cod-rep'):BUFFER-VALUE),TRUE).
   q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
  /* Native dropdowns must retain historical values. Writes still reject a new
     or changed inactive representative; only the unchanged value is allowed. */
  CREATE QUERY q. q:SET-BUFFERS(phSamples). rowsCount=0.
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phSamples:NAME + ' WHERE item_proc_compra_id=' + N(itemId) + ' NO-LOCK') THEN RUN Fail('PURCHASE_SAMPLE_OPTIONS',503,'Historico de representantes indisponivel.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   rowsCount=rowsCount + 1. IF rowsCount>4000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_SAMPLE_LIMIT',503,'Consulta de representantes excedeu limite.').
   repId=phSamples:BUFFER-FIELD('cod_rep'):BUFFER-VALUE.
   IF repId<>? AND repId>0 AND NOT representativesSeen:Has(N(repId)) THEN DO:
    IF rowsValue:Length>=4000 THEN RUN Fail('PURCHASE_SAMPLE_LIMIT',503,'Consulta de representantes excedeu limite.').
    actor=NEW JsonObject(). actor:Add('value',repId). actor:Add('text',N(repId) + ' - ' + RepName() + ' (historico; somente manter)'). rowsValue:Add(actor). representativesSeen:Add(N(repId),TRUE).
   END.
   q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q. DELETE OBJECT representativesSeen.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',rowsValue). poResponse:Add('total',rowsValue:Length). RETURN.
 END.
 IF op='read' THEN DO:
  RUN Closed(poRequest,'operation,proc_compra_id,item_proc_compra_id,skip,take,filter,sort').
  started=ETIME. CREATE QUERY q. q:SET-BUFFERS(phSamples).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phSamples:NAME + ' WHERE item_proc_compra_id=' + N(itemId) + ' NO-LOCK') THEN RUN Fail('PURCHASE_SAMPLE_READ_FAILED',503,'Consulta recusada.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   rowsCount=rowsCount + 1. IF rowsCount>4000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_SAMPLE_LIMIT',503,'Consulta de envios excedeu limite.').
   resultData=SampleData(phSamples,pid,RepName()).
   CREATE ttSampleRead. BUFFER ttSampleRead:HANDLE:BUFFER-COPY(phSamples).
   ASSIGN ttSampleRead.proc_compra_id=pid ttSampleRead.row_stamp=resultData:GetCharacter('row_stamp') ttSampleRead.representante_nome=resultData:GetCharacter('representante_nome').
   DELETE OBJECT resultData. q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
  requestCopy=CAST(poRequest:Clone(),JsonObject). requestCopy:Remove('proc_compra_id'). requestCopy:Remove('item_proc_compra_id').
  readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF readerPath=? THEN RUN Fail('PURCHASE_SAMPLE_CONFIGURATION',503,'Leitor compartilhado indisponivel.').
  RUN VALUE(readerPath)(INPUT BUFFER ttSampleRead:HANDLE,'proc_compra_amostras',N(itemId),requestCopy,OUTPUT poResponse). RETURN.
 END.
 IF op<>'create' THEN recordId=SampleId(poRequest,'id').
 IF op='get' THEN DO:
  RUN Closed(poRequest,'operation,proc_compra_id,item_proc_compra_id,id').
  IF NOT Found(phSamples,'envio_amostra_repres_id=' + N(recordId) + ' AND item_proc_compra_id=' + N(itemId),NO-LOCK) THEN RUN Fail('PURCHASE_SAMPLE_NOT_FOUND',404,'Envio nao encontrado.').
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',SampleData(phSamples,pid,RepName())). RETURN.
 END.
 RUN Closed(poRequest,IF op='create' THEN 'operation,proc_compra_id,item_proc_compra_id,values' ELSE IF op='update' THEN 'operation,proc_compra_id,item_proc_compra_id,id,row_stamp,values' ELSE 'operation,proc_compra_id,item_proc_compra_id,id,row_stamp').
 IF pcActor=? OR pcActor='' OR LENGTH(pcActor)>256 THEN RUN Fail('PURCHASE_SAMPLE_IDENTITY',401,'Usuario autenticado obrigatorio.').
 IF TRANSACTION THEN RUN Fail('PURCHASE_SAMPLE_TRANSACTION',409,'Uma transacao raiz independente e obrigatoria.').
 IF op<>'delete' THEN DO:
  IF NOT poRequest:Has('values') OR poRequest:GetType('values')<>JsonDataType:OBJECT THEN RUN Fail('PURCHASE_SAMPLE_VALIDATION',422,'Dados obrigatorios.').
  valuesObject=poRequest:GetJsonObject('values'). RUN Closed(valuesObject,'cod_rep,dt_envio').
  IF op='create' AND NOT valuesObject:Has('cod_rep') THEN RUN Fail('PURCHASE_SAMPLE_REPRESENTATIVE',422,'Informe o representante.').
  IF valuesObject:Has('cod_rep') THEN repId=SampleId(valuesObject,'cod_rep').
 END.
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN ContextCheck(EXCLUSIVE-LOCK).
  IF op='create' THEN DO:
   IF NOT VALID-HANDLE(phIdentity) OR LOOKUP('NextRawPurchaseSampleId',phIdentity:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_SAMPLE_SEQUENCE',503,'Sequencia de envios indisponivel.').
   ASSIGN code='PURCHASE_SAMPLE_SEQUENCE' statusCode=503.
   RUN NextRawPurchaseSampleId IN phIdentity(OUTPUT recordId).
   ASSIGN code='PURCHASE_SAMPLE_VALIDATION' statusCode=422.
   IF recordId=? OR recordId<1 THEN RUN Fail('PURCHASE_SAMPLE_SEQUENCE',503,'Identidade positiva indisponivel.').
   IF Found(phSamples,'envio_amostra_repres_id=' + N(recordId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_SAMPLE_ID_COLLISION',409,'Sequencia de envios atrasada. Nenhum reparo automatico foi aplicado.').
   IF NOT phSamples:BUFFER-CREATE() THEN RUN Fail('PURCHASE_SAMPLE_WRITE',409,'Inclusao recusada.').
   ASSIGN phSamples:BUFFER-FIELD('envio_amostra_repres_id'):BUFFER-VALUE=recordId phSamples:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE=itemId phSamples:BUFFER-FIELD('apont_amostra_id'):BUFFER-VALUE=0.
  END.
  ELSE DO:
   IF NOT Found(phSamples,'envio_amostra_repres_id=' + N(recordId) + ' AND item_proc_compra_id=' + N(itemId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_SAMPLE_NOT_FOUND',404,'Envio nao encontrado.').
   oldImage=SampleSnapshot(phSamples,pid).
   IF NOT poRequest:Has('row_stamp') OR poRequest:GetType('row_stamp')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_SAMPLE_STAMP',422,'Versao obrigatoria.').
   IF NOT COMPARE(poRequest:GetCharacter('row_stamp'),'=',SampleStamp(oldImage),'RAW') THEN RUN Fail('PURCHASE_SAMPLE_CONFLICT',409,'Envio alterado. Atualize os dados.').
  END.
  IF op='delete' THEN DO:
   IF NOT phSamples:BUFFER-DELETE() THEN RUN Fail('PURCHASE_SAMPLE_WRITE',409,'Exclusao recusada.').
  END.
  ELSE DO:
   IF valuesObject:Has('cod_rep') THEN DO:
    IF op='create' OR phSamples:BUFFER-FIELD('cod_rep'):BUFFER-VALUE<>repId THEN DO:
     IF NOT Found(phReps,'cod-rep=' + N(repId),SHARE-LOCK) OR phReps:BUFFER-FIELD('ind-situacao'):BUFFER-VALUE<>1 THEN RUN Fail('PURCHASE_SAMPLE_REPRESENTATIVE',422,'Representante ativo nao encontrado.').
    END.
    phSamples:BUFFER-FIELD('cod_rep'):BUFFER-VALUE=repId.
   END.
   IF valuesObject:Has('dt_envio') THEN DO:
    dateValue=?.
    IF NOT valuesObject:IsNull('dt_envio') THEN DO:
     IF valuesObject:GetType('dt_envio')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_SAMPLE_DATE',422,'Data ISO obrigatoria.').
     rawDate=valuesObject:GetCharacter('dt_envio').
     IF LENGTH(rawDate)<>10 OR SUBSTRING(rawDate,5,1)<>'-' OR SUBSTRING(rawDate,8,1)<>'-' THEN RUN Fail('PURCHASE_SAMPLE_DATE',422,'Data ISO invalida.').
     dateValue=DATE(INTEGER(SUBSTRING(rawDate,6,2)),INTEGER(SUBSTRING(rawDate,9,2)),INTEGER(SUBSTRING(rawDate,1,4))) NO-ERROR.
     IF ERROR-STATUS:ERROR OR dateValue=? THEN RUN Fail('PURCHASE_SAMPLE_DATE',422,'Data civil invalida.').
     IF ISO-DATE(dateValue)<>rawDate THEN RUN Fail('PURCHASE_SAMPLE_DATE',422,'Data ISO invalida.').
    END.
    phSamples:BUFFER-FIELD('dt_envio'):BUFFER-VALUE=dateValue.
   END.
   IF NOT phSamples:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_SAMPLE_WRITE',409,'Validacao do envio recusada.').
   newImage=SampleSnapshot(phSamples,pid). resultData=SampleData(phSamples,pid,RepName()).
  END.
 END.
 writeComplete=TRUE. poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE).
 IF op='delete' THEN DO: resultData=NEW JsonObject(). resultData:Add('envio_amostra_repres_id',recordId). END.
 poResponse:Add('data',resultData).
 actor=NEW JsonObject(). actor:Add('login',pcActor).
 audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction'). audit:Add('resource','envios-amostras-repres'). audit:Add('operation',op). audit:Add('recordId',recordId). audit:Add('actor',actor).
 IF op='create' THEN audit:Add('before',NEW JsonArray()). ELSE audit:Add('before',oldImage).
 IF op='delete' THEN audit:Add('after',NEW JsonArray()). ELSE audit:Add('after',newImage).
 audit:Add('changes',NEW JsonArray()). audit:Add('warnings',NEW JsonArray()). poResponse:Add('audit',audit).
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). poResponse:Add('committed',writeComplete).
  actor=NEW JsonObject(). actor:Add('code',code). actor:Add('status',statusCode). actor:Add('message',IF writeComplete THEN 'Operacao confirmada; nao repetir. Consulte os logs.' ELSE err:GetMessage(1)). poResponse:Add('error',actor).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
 END FINALLY.
END.
