/* Metadata only. The shared PHP storage owns bytes; no file IO or formulas here. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phAttachments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTypes AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdentity AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcScope AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/PurchaseAttachmentSnapshot.i}
DEFINE TEMP-TABLE ttAttachmentRead NO-UNDO
 FIELD anexo_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD item_proc_compra_id AS INTEGER
 FIELD descricao AS CHARACTER FIELD tipos_anexo_id AS INTEGER FIELD caminho_arquivo AS CHARACTER FIELD dt_hr_arquivo AS CHARACTER
 FIELD proc_compra_id_registro AS INTEGER FIELD row_stamp AS CHARACTER FIELD tipo_anexo_descricao AS CHARACTER FIELD arquivo_upload AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE anexo_proc_compra_id.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ATTACHMENT'.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE contextNames AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO. DEFINE VARIABLE itemId AS INTEGER NO-UNDO. DEFINE VARIABLE recordId AS INTEGER NO-UNDO.
DEFINE VARIABLE typeId AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ATTACHMENT_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE oldImage AS JsonObject NO-UNDO. DEFINE VARIABLE newImage AS JsonObject NO-UNDO. DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO. DEFINE VARIABLE valuesObject AS JsonObject NO-UNDO. DEFINE VARIABLE resultData AS JsonObject NO-UNDO. DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE referenceValue AS CHARACTER NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO. DEFINE VARIABLE rowsCount AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO. DEFINE VARIABLE writeComplete AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 namesValue=o:GetNames(). DO i=1 TO EXTENT(namesValue):
  matched=FALSE. DO j=1 TO NUM-ENTRIES(allowed): IF COMPARE(namesValue[i],'=',ENTRY(j,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN RUN Fail('PURCHASE_ATTACHMENT_FIELD_INVALID',422,'Campo nao permitido.').
 END.
END PROCEDURE.
{sursum-api/includes/PurchaseItemContext.i}

PROCEDURE AttachmentContextCheck:
 DEFINE INPUT PARAMETER locks AS INTEGER NO-UNDO.
 IF pcScope='item' THEN RUN ContextCheck(locks). ELSE RUN OrderContextCheck(locks).
END PROCEDURE.
FUNCTION LinkedOwner RETURNS LOGICAL(locks AS INTEGER):
 DEFINE VARIABLE childId AS INTEGER NO-UNDO.
 IF pcScope='item' THEN RETURN TRUE.
 childId=phAttachments:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE.
 IF childId=? OR childId=0 THEN RETURN TRUE.
 IF childId<0 THEN RETURN FALSE.
 RETURN Found(phItems,'item_proc_compra_id=' + N(childId) + ' AND proc_compra_id=' + N(pid),locks).
END FUNCTION.
FUNCTION FindAttachment RETURNS LOGICAL(locks AS INTEGER):
 DEFINE VARIABLE conditionValue AS CHARACTER NO-UNDO.
 conditionValue='anexo_proc_compra_id=' + N(recordId) + ' AND ' + (IF pcScope='item' THEN 'item_proc_compra_id=' + N(itemId) ELSE 'proc_compra_id=' + N(pid)).
 IF NOT Found(phAttachments,conditionValue,locks) THEN RETURN FALSE.
 RETURN LinkedOwner(locks).
END FUNCTION.

FUNCTION TypeName RETURNS CHARACTER():
 DEFINE VARIABLE v AS INTEGER NO-UNDO.
 v=phAttachments:BUFFER-FIELD('tipos_anexo_id'):BUFFER-VALUE.
 IF v=? OR v<1 THEN RETURN ''.
 IF Found(phTypes,'tipo_anexo_id=' + N(v),NO-LOCK) THEN RETURN STRING(phTypes:BUFFER-FIELD('descricao'):BUFFER-VALUE).
 RETURN ''.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phAttachments) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phTypes) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail('PURCHASE_ATTACHMENT_CONFIGURATION',503,'Configuracao de anexos indisponivel.').
 IF LOOKUP(pcScope,'item,order')=0 THEN RUN Fail('PURCHASE_ATTACHMENT_CONFIGURATION',503,'Escopo interno invalido.').
 pid=AttachmentId(poRequest,'proc_compra_id').
 IF pcScope='item' THEN itemId=AttachmentId(poRequest,'item_proc_compra_id'). ELSE itemId=0.
 ASSIGN contextNames=IF pcScope='item' THEN 'proc_compra_id,item_proc_compra_id' ELSE 'proc_compra_id'
 resourceValue=IF pcScope='item' THEN 'proc_compra_anexos' ELSE 'proc_compra_documentos'.
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ATTACHMENT_VALIDATION',422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'read,get,create,update,delete,options')=0 THEN RUN Fail('PURCHASE_ATTACHMENT_OPERATION',405,'Operacao indisponivel.').
 RUN AttachmentContextCheck(NO-LOCK).
 IF op='options' THEN DO:
  RUN Closed(poRequest,'operation,' + contextNames + ',lookup').
  IF NOT poRequest:Has('lookup') OR poRequest:GetType('lookup')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ATTACHMENT_OPTIONS',422,'Consulta de tipos invalida.').
  IF poRequest:GetCharacter('lookup')<>'tipo_anexo' THEN RUN Fail('PURCHASE_ATTACHMENT_OPTIONS',422,'Consulta de tipos invalida.').
  rowsValue=NEW JsonArray(). started=ETIME. CREATE QUERY q. q:SET-BUFFERS(phTypes).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phTypes:NAME + ' NO-LOCK BY descricao BY tipo_anexo_id') THEN RUN Fail('PURCHASE_ATTACHMENT_OPTIONS',503,'Consulta recusada.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   rowsCount=rowsCount + 1. IF rowsCount>4000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_ATTACHMENT_LIMIT',503,'Consulta de tipos excedeu limite.').
   typeId=phTypes:BUFFER-FIELD('tipo_anexo_id'):BUFFER-VALUE.
   IF typeId<>? AND typeId>0 THEN DO: actor=NEW JsonObject(). actor:Add('value',typeId). actor:Add('text',N(typeId) + ' - ' + STRING(phTypes:BUFFER-FIELD('descricao'):BUFFER-VALUE)). rowsValue:Add(actor). END.
   q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',rowsValue). poResponse:Add('total',rowsValue:Length). RETURN.
 END.
 IF op='read' THEN DO:
  RUN Closed(poRequest,'operation,' + contextNames + ',skip,take,filter,sort').
  started=ETIME. CREATE QUERY q. q:SET-BUFFERS(phAttachments).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phAttachments:NAME + ' WHERE ' + (IF pcScope='item' THEN 'item_proc_compra_id=' + N(itemId) ELSE 'proc_compra_id=' + N(pid)) + ' NO-LOCK') THEN RUN Fail('PURCHASE_ATTACHMENT_READ_FAILED',503,'Consulta recusada.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   rowsCount=rowsCount + 1. IF rowsCount>4000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_ATTACHMENT_LIMIT',503,'Consulta de anexos excedeu limite.').
   IF NOT LinkedOwner(NO-LOCK) THEN DO: q:GET-NEXT(NO-LOCK). NEXT. END.
   resultData=AttachmentData(phAttachments,pid,TypeName()). CREATE ttAttachmentRead.
   BUFFER ttAttachmentRead:HANDLE:BUFFER-COPY(phAttachments, 'dt_hr_arquivo').
   ASSIGN ttAttachmentRead.proc_compra_id=pid ttAttachmentRead.proc_compra_id_registro=phAttachments:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE
    ttAttachmentRead.dt_hr_arquivo=IF resultData:IsNull('dt_hr_arquivo') THEN ? ELSE resultData:GetCharacter('dt_hr_arquivo')
    ttAttachmentRead.row_stamp=resultData:GetCharacter('row_stamp') ttAttachmentRead.tipo_anexo_descricao=resultData:GetCharacter('tipo_anexo_descricao') ttAttachmentRead.arquivo_upload=?.
   DELETE OBJECT resultData. q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q. requestCopy=CAST(poRequest:Clone(),JsonObject). requestCopy:Remove('proc_compra_id'). IF requestCopy:Has('item_proc_compra_id') THEN requestCopy:Remove('item_proc_compra_id').
  readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF readerPath=? THEN RUN Fail('PURCHASE_ATTACHMENT_CONFIGURATION',503,'Leitor compartilhado indisponivel.').
  RUN VALUE(readerPath)(INPUT BUFFER ttAttachmentRead:HANDLE,resourceValue,N(IF pcScope='item' THEN itemId ELSE pid),requestCopy,OUTPUT poResponse). RETURN.
 END.
 IF op<>'create' THEN recordId=AttachmentId(poRequest,'id').
 IF op='get' THEN DO:
  RUN Closed(poRequest,'operation,' + contextNames + ',id').
  IF NOT FindAttachment(NO-LOCK) THEN RUN Fail('PURCHASE_ATTACHMENT_NOT_FOUND',404,'Anexo nao encontrado.').
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',AttachmentData(phAttachments,pid,TypeName())). RETURN.
 END.
 RUN Closed(poRequest,'operation,' + contextNames + (IF op='create' THEN ',values' ELSE IF op='update' THEN ',id,row_stamp,values' ELSE ',id,row_stamp')).
 IF pcActor=? OR pcActor='' OR LENGTH(pcActor)>256 THEN RUN Fail('PURCHASE_ATTACHMENT_IDENTITY',401,'Usuario autenticado obrigatorio.').
 IF TRANSACTION THEN RUN Fail('PURCHASE_ATTACHMENT_TRANSACTION',409,'Transacao raiz independente obrigatoria.').
 IF op<>'delete' THEN DO:
  IF NOT poRequest:Has('values') OR poRequest:GetType('values')<>JsonDataType:OBJECT THEN RUN Fail('PURCHASE_ATTACHMENT_VALIDATION',422,'Dados obrigatorios.').
  valuesObject=poRequest:GetJsonObject('values'). RUN Closed(valuesObject,'descricao,tipos_anexo_id,caminho_arquivo').
  IF op='create' AND NOT valuesObject:Has('caminho_arquivo') THEN RUN Fail('PURCHASE_ATTACHMENT_FILE',422,'Envie um arquivo.').
  IF valuesObject:Has('tipos_anexo_id') THEN DO:
   typeId=0. IF NOT valuesObject:IsNull('tipos_anexo_id') THEN DO:
    IF valuesObject:GetType('tipos_anexo_id')=JsonDataType:NUMBER AND valuesObject:GetDecimal('tipos_anexo_id')=0 THEN typeId=0.
    ELSE typeId=AttachmentId(valuesObject,'tipos_anexo_id').
   END.
  END.
  IF valuesObject:Has('descricao') AND (valuesObject:GetType('descricao')<>JsonDataType:STRING OR LENGTH(valuesObject:GetCharacter('descricao'))>800) THEN RUN Fail('PURCHASE_ATTACHMENT_DESCRIPTION',422,'Descricao deve ter ate 800 caracteres.').
  IF valuesObject:Has('caminho_arquivo') THEN DO:
   IF valuesObject:GetType('caminho_arquivo')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ATTACHMENT_FILE',422,'Referencia de arquivo invalida.').
   referenceValue=valuesObject:GetCharacter('caminho_arquivo').
   IF LENGTH(referenceValue)<45 OR LENGTH(referenceValue)>180 OR NOT referenceValue BEGINS 'ciwatt_' THEN RUN Fail('PURCHASE_ATTACHMENT_FILE',422,'Referencia de arquivo invalida.').
   DO k=1 TO LENGTH(referenceValue): IF INDEX('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-',SUBSTRING(referenceValue,k,1))=0 THEN RUN Fail('PURCHASE_ATTACHMENT_FILE',422,'Referencia de arquivo invalida.'). END.
  END.
 END.
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN AttachmentContextCheck(EXCLUSIVE-LOCK).
  IF op='create' THEN DO:
   IF NOT VALID-HANDLE(phIdentity) OR LOOKUP('NextRawPurchaseAttachmentId',phIdentity:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_ATTACHMENT_SEQUENCE',503,'Sequencia de anexos indisponivel.').
   ASSIGN code='PURCHASE_ATTACHMENT_SEQUENCE' statusCode=503. RUN NextRawPurchaseAttachmentId IN phIdentity(OUTPUT recordId). ASSIGN code='PURCHASE_ATTACHMENT_VALIDATION' statusCode=422.
   IF recordId=? OR recordId<1 THEN RUN Fail('PURCHASE_ATTACHMENT_SEQUENCE',503,'Identidade indisponivel.').
   IF Found(phAttachments,'anexo_proc_compra_id=' + N(recordId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ATTACHMENT_ID_COLLISION',409,'Sequencia atrasada; nenhum reparo automatico.').
   IF NOT phAttachments:BUFFER-CREATE() THEN RUN Fail('PURCHASE_ATTACHMENT_WRITE',409,'Inclusao recusada.').
   ASSIGN phAttachments:BUFFER-FIELD('anexo_proc_compra_id'):BUFFER-VALUE=recordId phAttachments:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE=pid phAttachments:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE=itemId phAttachments:BUFFER-FIELD('tipos_anexo_id'):BUFFER-VALUE=0.
  END.
  ELSE DO:
   IF NOT FindAttachment(EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ATTACHMENT_NOT_FOUND',404,'Anexo nao encontrado.').
   oldImage=AttachmentSnapshot(phAttachments,pid).
   IF NOT poRequest:Has('row_stamp') OR poRequest:GetType('row_stamp')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ATTACHMENT_STAMP',422,'Versao obrigatoria.').
   IF NOT COMPARE(poRequest:GetCharacter('row_stamp'),'=',AttachmentStamp(oldImage),'RAW') THEN RUN Fail('PURCHASE_ATTACHMENT_CONFLICT',409,'Anexo alterado. Atualize os dados.').
  END.
  IF op='delete' THEN DO: IF NOT phAttachments:BUFFER-DELETE() THEN RUN Fail('PURCHASE_ATTACHMENT_WRITE',409,'Exclusao recusada.'). END.
  ELSE DO:
   IF valuesObject:Has('descricao') THEN phAttachments:BUFFER-FIELD('descricao'):BUFFER-VALUE=valuesObject:GetCharacter('descricao').
   IF valuesObject:Has('tipos_anexo_id') THEN DO:
    IF typeId>0 AND (op='create' OR phAttachments:BUFFER-FIELD('tipos_anexo_id'):BUFFER-VALUE<>typeId) THEN
     IF NOT Found(phTypes,'tipo_anexo_id=' + N(typeId),SHARE-LOCK) THEN RUN Fail('PURCHASE_ATTACHMENT_TYPE',422,'Tipo de anexo nao encontrado.').
    phAttachments:BUFFER-FIELD('tipos_anexo_id'):BUFFER-VALUE=typeId.
   END.
   IF valuesObject:Has('caminho_arquivo') THEN ASSIGN phAttachments:BUFFER-FIELD('caminho_arquivo'):BUFFER-VALUE=referenceValue phAttachments:BUFFER-FIELD('dt_hr_arquivo'):BUFFER-VALUE=DATETIME(TODAY,MTIME).
   IF NOT phAttachments:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_ATTACHMENT_WRITE',409,'Validacao recusada.').
   newImage=AttachmentSnapshot(phAttachments,pid). resultData=AttachmentData(phAttachments,pid,TypeName()).
  END.
 END.
 writeComplete=TRUE. poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE).
 IF op='delete' THEN DO: resultData=NEW JsonObject(). resultData:Add('anexo_proc_compra_id',recordId). END.
 poResponse:Add('data',resultData). actor=NEW JsonObject(). actor:Add('login',pcActor).
 audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction'). audit:Add('resource','anexos-proc-compra'). audit:Add('operation',op). audit:Add('recordId',recordId). audit:Add('actor',actor).
 IF op='create' THEN audit:Add('before',NEW JsonArray()). ELSE audit:Add('before',oldImage).
 IF op='delete' THEN audit:Add('after',NEW JsonArray()). ELSE audit:Add('after',newImage).
 audit:Add('changes',NEW JsonArray()). audit:Add('warnings',NEW JsonArray()). poResponse:Add('audit',audit).
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). poResponse:Add('committed',writeComplete).
  actor=NEW JsonObject(). actor:Add('code',code). actor:Add('status',statusCode). actor:Add('message',IF writeComplete THEN 'Operacao confirmada; nao repetir.' ELSE err:GetMessage(1)). poResponse:Add('error',actor).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END.
