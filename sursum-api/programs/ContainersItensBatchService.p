/* Generic item allocation root. Fiscal/financial rules are trusted callbacks. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItemCosts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCommercial AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/ContainerBufferSibling.i}
{sursum-api/includes/ContainerTransactionAudit.i}
DEFINE TEMP-TABLE ttPlan NO-UNDO FIELD id AS INTEGER FIELD amount AS DECIMAL DECIMALS 2 FIELD already AS LOGICAL FIELD slot AS INTEGER FIELD itemId AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE VARIABLE cid AS INTEGER NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE valueId AS DECIMAL NO-UNDO. DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE ids AS JsonArray NO-UNDO. DEFINE VARIABLE skipped AS JsonArray NO-UNDO. DEFINE VARIABLE allocated AS JsonArray NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO. DEFINE VARIABLE folded AS JsonArray NO-UNDO. DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE masterBefore AS JsonObject NO-UNDO. DEFINE VARIABLE masterAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE nestedPolicy AS JsonObject NO-UNDO. DEFINE VARIABLE requestValue AS JsonObject NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE nestedResult AS JsonObject NO-UNDO. DEFINE VARIABLE auditValue AS JsonObject NO-UNDO. DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE dataValue AS JsonObject NO-UNDO. DEFINE VARIABLE errValue AS JsonObject NO-UNDO.
DEFINE VARIABLE purchaseLocks AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE orderLocks AS HANDLE EXTENT 25 NO-UNDO.
DEFINE VARIABLE slotValue AS INTEGER NO-UNDO.
DEFINE VARIABLE hAllocations AS HANDLE NO-UNDO. DEFINE VARIABLE balancePath AS CHARACTER NO-UNDO. DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE already AS LOGICAL NO-UNDO. DEFINE VARIABLE availableQuantity AS DECIMAL NO-UNDO.
DEFINE VARIABLE snapshotProven AS LOGICAL NO-UNDO.
DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE committed AS LOGICAL NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL 'CONTAINER_ALLOCATION_VALIDATION'. DEFINE VARIABLE failureStatus AS INTEGER NO-UNDO INITIAL 422.
FUNCTION N RETURNS CHARACTER(id AS INTEGER): RETURN TRIM(STRING(id,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 failureCode=codeValue. failureStatus=statusValue. UNDO, THROW NEW Progress.Lang.AppError(messageValue,1).
END PROCEDURE.
PROCEDURE FindRow:
 DEFINE INPUT PARAMETER bufferValue AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER conditionValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER modeValue AS INTEGER NO-UNDO.
 DEFINE OUTPUT PARAMETER found AS LOGICAL NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 found=bufferValue:FIND-FIRST('WHERE ' + conditionValue,modeValue,NO-WAIT) NO-ERROR.
 IF bufferValue:LOCKED THEN RUN Fail('CONTAINER_ALLOCATION_BUSY',409,'Registro em uso.').
 DO k=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(k)<>565 THEN RUN Fail('CONTAINER_ALLOCATION_BUSY',409,'Leitura bloqueada ou indisponivel.'). END.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(failureCode,422,'Requisicao obrigatoria.').
 names=poRequest:GetNames(). DO n=1 TO EXTENT(names): IF LOOKUP(names[n],'operation,container_id,item_ids')=0 THEN RUN Fail(failureCode,422,'Campo nao permitido.'). END.
 IF poRequest:GetType('operation')<>JsonDataType:STRING OR poRequest:GetCharacter('operation')<>'allocate' OR poRequest:GetType('container_id')<>JsonDataType:NUMBER OR poRequest:GetType('item_ids')<>JsonDataType:ARRAY THEN RUN Fail(failureCode,422,'Operacao, container e selecao obrigatorios.').
 valueId=poRequest:GetDecimal('container_id'). IF valueId=? OR valueId<1 OR valueId>2147483647 OR valueId<>TRUNCATE(valueId,0) THEN RUN Fail(failureCode,422,'Container deve ser inteiro positivo.'). cid=INTEGER(valueId).
 ids=poRequest:GetJsonArray('item_ids'). IF ids:Length<1 OR ids:Length>25 THEN RUN Fail(failureCode,422,'Selecione de 1 a 25 itens.').
 DO n=1 TO ids:Length:
  IF ids:GetType(n)<>JsonDataType:NUMBER THEN RUN Fail(failureCode,422,'ID inteiro obrigatorio.'). valueId=ids:GetDecimal(n).
  IF valueId=? OR valueId<1 OR valueId>2147483647 OR valueId<>TRUNCATE(valueId,0) THEN RUN Fail(failureCode,422,'ID inteiro positivo obrigatorio.').
  IF CAN-FIND(FIRST ttPlan WHERE ttPlan.id=INTEGER(valueId)) THEN RUN Fail(failureCode,422,'Selecao repetida.').
  CREATE ttPlan. ttPlan.id=INTEGER(valueId).
 END.
 IF TRANSACTION THEN RUN Fail('CONTAINER_ALLOCATION_TRANSACTION',409,'Lote exige transacao raiz propria.').
 ASSIGN failureCode='CONTAINER_ALLOCATION_IDENTITY' failureStatus=401.
 IF NOT VALID-OBJECT(poPolicy) OR NOT VALID-OBJECT(poPolicy:GetJsonObject('actor')) THEN RUN Fail('CONTAINER_ALLOCATION_IDENTITY',401,'Usuario autenticado obrigatorio.').
 actor=poPolicy:GetJsonObject('actor'). IF actor:GetType('login')<>JsonDataType:STRING OR TRIM(actor:GetCharacter('login'))='' OR LENGTH(actor:GetCharacter('login'))>128 THEN RUN Fail('CONTAINER_ALLOCATION_IDENTITY',401,'Usuario autenticado invalido.').
 actor=NEW JsonObject(). actor:Add('login',poPolicy:GetJsonObject('actor'):GetCharacter('login')).
 ASSIGN failureCode='CONTAINER_ALLOCATION_CONFIGURATION' failureStatus=503.
 balancePath=SEARCH('sursum-api/programs/ContainersAllocationBalance.r'). IF balancePath=? THEN balancePath=SEARCH('ContainersAllocationBalance.r').
 servicePath=SEARCH('sursum-api/programs/ContainersItensCrudService.r'). IF servicePath=? THEN servicePath=SEARCH('ContainersItensCrudService.r').
 IF balancePath=? OR servicePath=? THEN RUN Fail('CONTAINER_ALLOCATION_CONFIGURATION',503,'Rotinas compartilhadas indisponiveis.').
 RUN ContainerCreateSiblingBuffer(phItems,'bBatchAllocationSum',OUTPUT hAllocations).
 nestedPolicy=CAST(poPolicy:Clone(),JsonObject). IF nestedPolicy:Has('allow_nested') THEN nestedPolicy:Set('allow_nested',TRUE). ELSE nestedPolicy:Add('allow_nested',TRUE).
 ASSIGN changes=NEW JsonArray() warnings=NEW JsonArray() skipped=NEW JsonArray() allocated=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN FindRow(phMaster,'nr-container=' + N(cid),EXCLUSIVE-LOCK,OUTPUT foundValue). IF NOT foundValue THEN RUN Fail('CONTAINER_NOT_FOUND',404,'Container inexistente.').
  masterBefore=ProcessSnapshot(phMaster,cid).
  /* All rows and balances are planned before any sequence/side effect. */
  FOR EACH ttPlan BY ttPlan.id:
   slotValue=slotValue + 1. ttPlan.slot=slotValue.
   RUN ContainerCreateSiblingBuffer(phPurchaseItems,'bAllocPurchase' + N(slotValue),OUTPUT purchaseLocks[slotValue]).
   RUN ContainerCreateSiblingBuffer(phPurchases,'bAllocOrder' + N(slotValue),OUTPUT orderLocks[slotValue]).
   RUN FindRow(purchaseLocks[slotValue],'item_proc_compra_id=' + N(ttPlan.id),EXCLUSIVE-LOCK,OUTPUT foundValue). IF NOT foundValue THEN RUN Fail('CONTAINER_ALLOCATION_REFERENCE',422,'Item do pedido inexistente.').
   valueId=purchaseLocks[slotValue]:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
   IF valueId=? OR valueId<1 OR valueId>2147483647 OR valueId<>TRUNCATE(valueId,0) THEN RUN Fail('CONTAINER_ALLOCATION_REFERENCE',422,'Pedido invalido.').
   RUN FindRow(orderLocks[slotValue],'proc_compra_id=' + N(INTEGER(valueId)),SHARE-LOCK,OUTPUT foundValue). IF NOT foundValue THEN RUN Fail('CONTAINER_ALLOCATION_REFERENCE',422,'Pedido inexistente.').
   ASSIGN failureCode='CONTAINER_ALLOCATION_BALANCE' failureStatus=422.
   RUN VALUE(balancePath)(purchaseLocks[slotValue],hAllocations,ttPlan.id,cid,TRUE,OUTPUT availableQuantity,OUTPUT already).
   ASSIGN ttPlan.amount=availableQuantity ttPlan.already=already.
   IF NOT already THEN DO:
    IF purchaseLocks[slotValue]:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE=? OR TRIM(STRING(purchaseLocks[slotValue]:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE))='' THEN RUN Fail('CONTAINER_ALLOCATION_REFERENCE',422,'Item sem codigo ERP.').
    IF availableQuantity<=0 THEN RUN Fail('CONTAINER_ALLOCATION_BALANCE',409,'Saldo disponivel esgotado; lote cancelado.').
   END.
  END.
  FOR EACH ttPlan BY ttPlan.id:
   IF ttPlan.already THEN DO: skipped:Add(ttPlan.id). NEXT. END.
   requestValue=NEW JsonObject(). requestValue:Add('operation','create'). requestValue:Add('container_id',cid).
   rowValue=NEW JsonObject(). rowValue:Add('item_proc_compra_id',ttPlan.id). rowValue:Add('qt_alocada',ttPlan.amount). requestValue:Add('values',rowValue).
   ASSIGN failureCode='CONTAINER_ALLOCATION_RULE' failureStatus=422.
   RUN VALUE(servicePath)(phMaster,phItems,phPurchaseItems,phPurchases,phDiscounts,phItemCosts,phCommercial,phRuntime,nestedPolicy,requestValue,OUTPUT nestedResult).
   IF NOT VALID-OBJECT(nestedResult) THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Retorno da manutencao ausente.').
   IF NOT nestedResult:GetLogical('success') THEN DO:
    errValue=nestedResult:GetJsonObject('error'). RUN Fail(errValue:GetCharacter('code'),errValue:GetInteger('status'),errValue:GetCharacter('message')).
   END.
   IF nestedResult:GetLogical('committed') OR nestedResult:Has('audit') THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Participante confirmou antes da transacao raiz.').
   ttPlan.itemId=nestedResult:GetJsonObject('data'):GetInteger('item_container_id').
   RUN ProcessMergeItemEvents(nestedResult:GetJsonArray('pendingChanges'),cid,INPUT-OUTPUT changes).
   IF warnings:Length + nestedResult:GetJsonArray('warnings'):Length>1000 OR changes:Length>50000 THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Limite de auditoria do lote excedido.').
   DO j=1 TO nestedResult:GetJsonArray('warnings'):Length: warnings:Add(nestedResult:GetJsonArray('warnings'):GetCharacter(j)). END.
  END.
  FOR EACH ttPlan WHERE NOT ttPlan.already BY ttPlan.id:
   RUN FindRow(phItems,'item_container_id=' + N(ttPlan.itemId) + ' AND container_id=' + N(cid),EXCLUSIVE-LOCK,OUTPUT foundValue).
   IF NOT foundValue THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Item deixou de existir apos efeitos.').
   IF phItems:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE<>ttPlan.id OR phItems:BUFFER-FIELD('qt_alocada'):BUFFER-VALUE<>ttPlan.amount THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Efeito alterou identidade ou quantidade alocada.').
   rowValue=ProcessSnapshot(phItems,cid). snapshotProven=FALSE.
   DO j=1 TO changes:Length:
    auditValue=changes:GetJsonObject(j).
    IF auditValue:GetCharacter('resource')='itens_container' AND auditValue:GetInteger('recordId')=ttPlan.itemId THEN DO:
     snapshotProven=COMPARE(STRING(auditValue:GetJsonObject('after'):GetJsonText()),'=',STRING(rowValue:GetJsonText()),'RAW'). LEAVE.
    END.
   END.
   IF NOT snapshotProven THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Imagem final do item nao corresponde aos efeitos registrados; lote cancelado.').
   allocated:Add(rowValue).
  END.
  RUN FindRow(phMaster,'nr-container=' + N(cid),EXCLUSIVE-LOCK,OUTPUT foundValue). IF NOT foundValue THEN RUN Fail('CONTAINER_ALLOCATION_RULE',422,'Mestre deixou de existir.').
  masterAfter=ProcessSnapshot(phMaster,cid).
 END.
 committed=TRUE.
 folded=NEW JsonArray().
 DO n=1 TO changes:Length:
  rowValue=changes:GetJsonObject(n). IF STRING(rowValue:GetJsonObject('before'):GetJsonText())='~{~}' AND STRING(rowValue:GetJsonObject('after'):GetJsonText())='~{~}' THEN NEXT.
  folded:Add(rowValue).
 END.
 auditValue=NEW JsonObject(). auditValue:Add('version',1). auditValue:Add('source','progress-transaction'). auditValue:Add('resource','container-alocacoes'). auditValue:Add('operation','allocate'). auditValue:Add('recordId',cid). auditValue:Add('container_id',cid). auditValue:Add('before',masterBefore). auditValue:Add('after',masterAfter). auditValue:Add('changes',folded). auditValue:Add('warnings',warnings). auditValue:Add('actor',actor).
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE). poResponse:Add('audit',auditValue). poResponse:Add('allocated',allocated). poResponse:Add('skipped',skipped).
 dataValue=NEW JsonObject(). dataValue:Add('type','message'). dataValue:Add('message','Alocacao confirmada: ' + N(allocated:Length) + ' itens incluidos; ' + N(skipped:Length) + ' ja alocados preservados. Consulte os itens e os logs do container.'). poResponse:Add('data',dataValue).
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',committed). poResponse:Add('committed',committed).
  IF committed THEN DO:
   dataValue=NEW JsonObject(). dataValue:Add('type','message'). dataValue:Add('message','Lote confirmado; auditoria de resposta indisponivel. Nao repita; consulte a transacao.'). poResponse:Add('data',dataValue).
  END.
  ELSE DO:
  errValue=NEW JsonObject(). errValue:Add('code',failureCode). errValue:Add('status',failureStatus). errValue:Add('message',IF committed THEN 'Lote confirmado; nao repetir. Consulte logs.' ELSE err:GetMessage(1)). poResponse:Add('error',errValue).
  END.
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(hAllocations) THEN DELETE OBJECT hAllocations NO-ERROR.
  DO n=1 TO 25: IF VALID-HANDLE(purchaseLocks[n]) THEN DELETE OBJECT purchaseLocks[n] NO-ERROR. IF VALID-HANDLE(orderLocks[n]) THEN DELETE OBJECT orderLocks[n] NO-ERROR. END.
 END FINALLY.
END.
