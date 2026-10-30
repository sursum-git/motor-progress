/* Readonly contextual allocation projection. No tax/cost formulas or writers. */
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
DEFINE TEMP-TABLE ttAllocationRead NO-UNDO
 FIELD item_container_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD item_proc_compra_id AS INTEGER
 FIELD container_id AS INTEGER FIELD qt_alocada AS DECIMAL DECIMALS 2 FIELD situacao AS INTEGER
 FIELD situacao_descricao AS CHARACTER FIELD situacao_container_id AS INTEGER FIELD situacao_acomp AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE item_container_id.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ALLOCATION'.
DEFINE VARIABLE pid AS INTEGER NO-UNDO. DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE recordId AS INTEGER NO-UNDO. DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE situationId AS INTEGER NO-UNDO. DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ALLOCATION_VALIDATION'.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO. DEFINE VARIABLE keyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE errorValue AS JsonObject NO-UNDO. DEFINE VARIABLE keyText AS LONGCHAR NO-UNDO.
DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO. DEFINE VARIABLE scanned AS INTEGER NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
{sursum-api/includes/PurchaseItemContext.i}
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phAllocations) OR NOT VALID-HANDLE(phContainers) OR NOT VALID-HANDLE(phSituations) THEN RUN Fail('PURCHASE_ALLOCATION_CONFIGURATION',503,'Configuracao indisponivel.').
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(code,422,'Requisicao obrigatoria.').
 pid=PurchaseJsonId(poRequest,'proc_compra_id'). itemId=PurchaseJsonId(poRequest,'item_proc_compra_id').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation').
 IF LOOKUP(op,'read,get')=0 THEN RUN Fail('PURCHASE_ALLOCATION_READ_ONLY',405,'Consulta somente leitura.').
 ns=poRequest:GetNames(). DO k=1 TO EXTENT(ns):
  IF LOOKUP(ns[k],IF op='get' THEN 'operation,proc_compra_id,item_proc_compra_id,id,item_container_id' ELSE 'operation,proc_compra_id,item_proc_compra_id,skip,take,sort,filter')=0 THEN RUN Fail(code,422,'Campo nao permitido.').
 END.
 IF op='get' THEN DO:
  recordId=PurchaseJsonId(poRequest,'id').
  IF poRequest:Has('item_container_id') AND PurchaseJsonId(poRequest,'item_container_id')<>recordId THEN RUN Fail(code,422,'Identidade divergente.').
 END.
 RUN ContextCheck(NO-LOCK).
 ASSIGN code='PURCHASE_ALLOCATION_UNAVAILABLE' statusCode=503 started=ETIME.
 CREATE QUERY q. q:SET-BUFFERS(phAllocations).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + phAllocations:NAME + ' WHERE item_proc_compra_id=' + N(itemId) + ' NO-LOCK') THEN RUN Fail(code,503,'Consulta indisponivel.').
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  scanned=scanned + 1. IF scanned>50000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_ALLOCATION_LIMIT',503,'Limite de consulta excedido.').
  containerId=phAllocations:BUFFER-FIELD('container_id'):BUFFER-VALUE.
  /* Preserve the legacy INNER JOIN: an orphan allocation has no container row. */
  IF containerId<>? AND Found(phContainers,'nr-container=' + N(containerId),NO-LOCK) THEN DO:
   recordId=phAllocations:BUFFER-FIELD('item_container_id'):BUFFER-VALUE.
   IF recordId=? OR recordId<1 OR CAN-FIND(FIRST ttAllocationRead WHERE ttAllocationRead.item_container_id=recordId) THEN RUN Fail('PURCHASE_ALLOCATION_AMBIGUOUS',409,'Identidade de alocacao invalida.').
   CREATE ttAllocationRead.
   ASSIGN ttAllocationRead.item_container_id=recordId ttAllocationRead.proc_compra_id=pid ttAllocationRead.item_proc_compra_id=itemId
    ttAllocationRead.container_id=containerId ttAllocationRead.qt_alocada=phAllocations:BUFFER-FIELD('qt_alocada'):BUFFER-VALUE
    ttAllocationRead.situacao=phContainers:BUFFER-FIELD('situacao'):BUFFER-VALUE
    ttAllocationRead.situacao_container_id=phContainers:BUFFER-FIELD('situacao_container_id'):BUFFER-VALUE
    ttAllocationRead.situacao_acomp='Nao Informada'.
   CASE ttAllocationRead.situacao:
    WHEN 1 THEN ttAllocationRead.situacao_descricao='Aberto'.
    WHEN 2 THEN ttAllocationRead.situacao_descricao='Suspenso'.
    WHEN 3 THEN ttAllocationRead.situacao_descricao='Fechado'.
    OTHERWISE ttAllocationRead.situacao_descricao=IF ttAllocationRead.situacao=? THEN '' ELSE N(ttAllocationRead.situacao).
   END CASE.
   situationId=ttAllocationRead.situacao_container_id.
   IF situationId<>? AND Found(phSituations,'situacao_container_id=' + N(situationId),NO-LOCK) THEN DO:
    IF phSituations:BUFFER-FIELD('descricao'):BUFFER-VALUE<>? AND phSituations:BUFFER-FIELD('descricao'):BUFFER-VALUE<>'' THEN ttAllocationRead.situacao_acomp=phSituations:BUFFER-FIELD('descricao'):BUFFER-VALUE.
   END.
  END.
  q:GET-NEXT(NO-LOCK).
 END.
 requestCopy=CAST(poRequest:Clone(),JsonObject). requestCopy:Remove('proc_compra_id'). requestCopy:Remove('item_proc_compra_id').
 IF op='get' THEN DO:
  IF requestCopy:Has('item_container_id') THEN requestCopy:Remove('item_container_id').
  keyValue=NEW JsonObject(). keyValue:Add('item_container_id',PurchaseJsonId(poRequest,'id')). keyValue:Write(keyText,FALSE). requestCopy:Set('id',STRING(keyText)).
 END.
 pathValue=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF pathValue=? THEN RUN Fail('PURCHASE_ALLOCATION_CONFIGURATION',503,'Leitor compartilhado nao publicado.').
 RUN VALUE(pathValue)(INPUT BUFFER ttAllocationRead:HANDLE,'proc_compra_alocacoes',N(itemId),requestCopy,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject(). errorValue:Add('code',code). errorValue:Add('status',statusCode).
  errorValue:Add('message','Consulta de alocacoes invalida ou indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END.
