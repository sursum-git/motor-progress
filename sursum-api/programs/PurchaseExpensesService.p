/* One writer for manual maintenance and idempotent template generation.
   No tax/financial calculation: the source form calls only its logging hooks. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdentity AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/PurchaseExpenseSnapshot.i}
{sursum-api/includes/PurchaseOrderSnapshot.i}
{sursum-api/includes/PurchaseItemValueRules.i}
DEFINE TEMP-TABLE ttExpenseRead NO-UNDO
 FIELD despesa_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD despesa_id AS INTEGER
 FIELD vl_prev AS DECIMAL DECIMALS 2 FIELD calc_imp_proc_compra_id AS INTEGER
 FIELD row_stamp AS CHARACTER FIELD despesa_descricao AS CHARACTER INDEX pk IS PRIMARY UNIQUE despesa_proc_compra_id.
/* NO-UNDO plan is discarded on exit; only the fixed physical writer persists rows. */
DEFINE TEMP-TABLE ttPlan NO-UNDO FIELD despesa_id AS INTEGER FIELD amountValue AS DECIMAL DECIMALS 2 FIELD existsValue AS LOGICAL INDEX pk IS PRIMARY UNIQUE despesa_id.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_EXPENSE'.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO. DEFINE VARIABLE recordId AS INTEGER NO-UNDO. DEFINE VARIABLE definitionId AS INTEGER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO. DEFINE VARIABLE createdCount AS INTEGER NO-UNDO. DEFINE VARIABLE skippedCount AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_EXPENSE_VALIDATION'. DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE oldImage AS JsonObject NO-UNDO. DEFINE VARIABLE newImage AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesObject AS JsonObject NO-UNDO. DEFINE VARIABLE resultData AS JsonObject NO-UNDO.
DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO. DEFINE VARIABLE actor AS JsonObject NO-UNDO. DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE changeValue AS JsonObject NO-UNDO. DEFINE VARIABLE changesValue AS JsonArray NO-UNDO.
DEFINE VARIABLE rowsValue AS JsonArray NO-UNDO. DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO. DEFINE VARIABLE scanned AS INTEGER NO-UNDO.
DEFINE VARIABLE writeComplete AS LOGICAL NO-UNDO. DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE amountValue AS DECIMAL DECIMALS 2 NO-UNDO.
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 ns=o:GetNames(). DO i=1 TO EXTENT(ns):
  matched=FALSE. DO j=1 TO NUM-ENTRIES(allowed): IF COMPARE(ns[i],'=',ENTRY(j,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN RUN Fail('PURCHASE_EXPENSE_FIELD_INVALID',422,'Campo nao permitido.').
 END.
END PROCEDURE.
{sursum-api/includes/PurchaseOrderContext.i}
FUNCTION DescriptionValue RETURNS CHARACTER():
 DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
 idValue=phExpenses:BUFFER-FIELD('despesa_id'):BUFFER-VALUE.
 IF idValue=? OR idValue<1 THEN RETURN ''.
 IF Found(phDefs,'despesa_id=' + N(idValue),NO-LOCK) THEN RETURN STRING(phDefs:BUFFER-FIELD('descricao'):BUFFER-VALUE).
 RETURN ''.
END FUNCTION.
PROCEDURE LimitCheck:
 DEFINE INPUT PARAMETER limitValue AS INTEGER NO-UNDO.
 scanned=scanned + 1.
 IF scanned>limitValue OR ETIME - started>10000 THEN RUN Fail('PURCHASE_EXPENSE_LIMIT',503,'Consulta de despesas excedeu limite.').
END PROCEDURE.
/* Called only under the root transaction and parent mutex; no MAX/identity repair. */
{sursum-api/includes/PurchaseExpenseInsert.i}
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phExpenses) OR NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phDefs) OR NOT VALID-HANDLE(phLinks) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail('PURCHASE_EXPENSE_CONFIGURATION',503,'Configuracao de despesas indisponivel.').
 pid=PurchaseJsonId(poRequest,'proc_compra_id').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_EXPENSE_VALIDATION',422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation').
 IF LOOKUP(op,'read,get,create,update,delete,options,generate')=0 THEN RUN Fail('PURCHASE_EXPENSE_OPERATION',405,'Operacao indisponivel.').
 RUN OrderContextCheck(NO-LOCK). companyId=phOrders:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
 started=ETIME.
 IF op='options' THEN DO:
  RUN Closed(poRequest,'operation,proc_compra_id,lookup').
  IF NOT poRequest:Has('lookup') OR poRequest:GetType('lookup')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_EXPENSE_OPTIONS',422,'Consulta de opcoes invalida.').
  IF poRequest:GetCharacter('lookup')<>'despesa' THEN RUN Fail('PURCHASE_EXPENSE_OPTIONS',422,'Consulta de opcoes invalida.').
  rowsValue=NEW JsonArray(). CREATE QUERY q. q:SET-BUFFERS(phDefs).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phDefs:NAME + ' NO-LOCK BY descricao BY despesa_id') THEN RUN Fail('PURCHASE_EXPENSE_READ',503,'Consulta recusada.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN LimitCheck(4000).
   definitionId=phDefs:BUFFER-FIELD('despesa_id'):BUFFER-VALUE.
   IF definitionId<>? AND definitionId>0 THEN DO:
    actor=NEW JsonObject(). actor:Add('value',definitionId). actor:Add('text',N(definitionId) + ' - ' + STRING(phDefs:BUFFER-FIELD('descricao'):BUFFER-VALUE)). rowsValue:Add(actor).
   END.
   q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',rowsValue). poResponse:Add('total',rowsValue:Length). RETURN.
 END.
 IF op='read' THEN DO:
  RUN Closed(poRequest,'operation,proc_compra_id,skip,take,filter,sort').
  CREATE QUERY q. q:SET-BUFFERS(phExpenses).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phExpenses:NAME + ' WHERE proc_compra_id=' + N(pid) + ' NO-LOCK') THEN RUN Fail('PURCHASE_EXPENSE_READ',503,'Consulta recusada.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN LimitCheck(4000). resultData=ExpenseData(phExpenses,DescriptionValue()).
   CREATE ttExpenseRead. BUFFER ttExpenseRead:HANDLE:BUFFER-COPY(phExpenses).
   ASSIGN ttExpenseRead.proc_compra_id=pid ttExpenseRead.row_stamp=resultData:GetCharacter('row_stamp') ttExpenseRead.despesa_descricao=resultData:GetCharacter('despesa_descricao').
   DELETE OBJECT resultData. q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q.
  requestCopy=CAST(poRequest:Clone(),JsonObject). requestCopy:Remove('proc_compra_id').
  readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF readerPath=? THEN RUN Fail('PURCHASE_EXPENSE_CONFIGURATION',503,'Leitor compartilhado indisponivel.').
  RUN VALUE(readerPath)(INPUT BUFFER ttExpenseRead:HANDLE,'proc_compra_despesas',N(pid),requestCopy,OUTPUT poResponse). RETURN.
 END.
 IF LOOKUP(op,'get,update,delete')>0 THEN recordId=PurchaseJsonId(poRequest,'id').
 IF op='get' THEN DO:
  RUN Closed(poRequest,'operation,proc_compra_id,id').
  IF NOT Found(phExpenses,'despesa_proc_compra_id=' + N(recordId) + ' AND proc_compra_id=' + N(pid),NO-LOCK) THEN RUN Fail('PURCHASE_EXPENSE_NOT_FOUND',404,'Despesa nao encontrada.').
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',ExpenseData(phExpenses,DescriptionValue())). RETURN.
 END.
 RUN Closed(poRequest,IF op='create' THEN 'operation,proc_compra_id,values' ELSE IF op='update' THEN 'operation,proc_compra_id,id,row_stamp,values' ELSE IF op='delete' THEN 'operation,proc_compra_id,id,row_stamp' ELSE 'operation,proc_compra_id').
 IF pcActor=? OR pcActor='' OR LENGTH(pcActor)>256 THEN RUN Fail('PURCHASE_EXPENSE_IDENTITY',401,'Usuario autenticado obrigatorio.').
 IF TRANSACTION THEN RUN Fail('PURCHASE_EXPENSE_TRANSACTION',409,'Uma transacao raiz independente e obrigatoria.').
 IF LOOKUP(op,'create,update')>0 THEN DO:
  IF NOT poRequest:Has('values') OR poRequest:GetType('values')<>JsonDataType:OBJECT THEN RUN Fail('PURCHASE_EXPENSE_VALIDATION',422,'Dados obrigatorios.').
  valuesObject=poRequest:GetJsonObject('values'). RUN Closed(valuesObject,'despesa_id,vl_prev').
  IF op='create' AND NOT valuesObject:Has('despesa_id') THEN RUN Fail('PURCHASE_EXPENSE_DEFINITION',422,'Informe a despesa.').
  IF valuesObject:Has('despesa_id') THEN definitionId=PurchaseJsonId(valuesObject,'despesa_id').
  IF valuesObject:Has('vl_prev') THEN DO:
   IF valuesObject:GetType('vl_prev')<>JsonDataType:NUMBER THEN RUN Fail('PURCHASE_EXPENSE_VALUE',422,'Valor numerico obrigatorio.').
   IF NOT PurchaseItemDecimalFits(STRING(valuesObject:GetJsonText('vl_prev')),2) THEN RUN Fail('PURCHASE_EXPENSE_VALUE',422,'Valor deve respeitar duas casas decimais.').
   amountValue=PurchaseItemDecimalNumber(STRING(valuesObject:GetJsonText('vl_prev'))).
  END.
 END.
 changesValue=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN OrderContextCheck(EXCLUSIVE-LOCK). companyId=phOrders:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
  IF op='generate' THEN DO:
   oldImage=PurchaseOrderSnapshot(phOrders).
   CREATE QUERY q. q:SET-BUFFERS(phLinks).
   IF NOT q:QUERY-PREPARE('FOR EACH ' + phLinks:NAME + ' WHERE empresa_id=' + N(companyId) + ' AND log_ativo=1 SHARE-LOCK') THEN RUN Fail('PURCHASE_EXPENSE_READ',503,'Configuracao recusada.').
   q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
   DO WHILE NOT q:QUERY-OFF-END:
    IF phLinks:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_EXPENSE_BUSY',409,'Configuracao em uso.').
    RUN LimitCheck(5000). definitionId=phLinks:BUFFER-FIELD('despesa_id'):BUFFER-VALUE.
    IF definitionId<>? AND definitionId>0 THEN DO:
     IF NOT Found(phDefs,'despesa_id=' + N(definitionId),SHARE-LOCK) THEN RUN Fail('PURCHASE_EXPENSE_DEFINITION',409,'Configuracao aponta despesa inexistente.').
     IF phDefs:BUFFER-FIELD('log_imposto'):BUFFER-VALUE=0 THEN DO:
      IF CAN-FIND(FIRST ttPlan WHERE ttPlan.despesa_id=definitionId) THEN RUN Fail('PURCHASE_EXPENSE_AMBIGUOUS',409,'Vinculos ativos duplicados. Corrija o cadastro antes de gerar.').
      CREATE ttPlan. ASSIGN ttPlan.despesa_id=definitionId ttPlan.amountValue=phLinks:BUFFER-FIELD('vl_padrao'):BUFFER-VALUE.
      IF ttPlan.amountValue=? THEN RUN Fail('PURCHASE_EXPENSE_VALUE',422,'Valor padrao indefinido.').
      ttPlan.existsValue=Found(phExpenses,'proc_compra_id=' + N(pid) + ' AND despesa_id=' + N(definitionId),SHARE-LOCK).
      IF ttPlan.existsValue THEN skippedCount=skippedCount + 1.
      ELSE createdCount=createdCount + 1.
      IF createdCount>200 THEN RUN Fail('PURCHASE_EXPENSE_LIMIT',422,'Geracao excede200despesas novas.').
     END.
    END.
    q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
   END.
   IF phLinks:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_EXPENSE_BUSY',409,'Configuracao em uso.').
   q:QUERY-CLOSE(). DELETE OBJECT q.
   FOR EACH ttPlan WHERE NOT ttPlan.existsValue:
    RUN InsertExpense(ttPlan.despesa_id,ttPlan.amountValue,0).
    changeValue=NEW JsonObject(). changeValue:Add('resource','despesas-proc-compra'). changeValue:Add('operation','create'). changeValue:Add('recordId',recordId).
    changeValue:Add('before',NEW JsonArray()). changeValue:Add('after',ExpenseSnapshot(phExpenses)). changesValue:Add(changeValue).
   END.
   newImage=PurchaseOrderSnapshot(phOrders).
  END.
  ELSE DO:
   IF op='create' THEN DO:
    IF NOT Found(phDefs,'despesa_id=' + N(definitionId),SHARE-LOCK) THEN RUN Fail('PURCHASE_EXPENSE_DEFINITION',422,'Despesa nao encontrada.').
    RUN InsertExpense(definitionId,amountValue,0).
   END.
   ELSE DO:
    IF NOT Found(phExpenses,'despesa_proc_compra_id=' + N(recordId) + ' AND proc_compra_id=' + N(pid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_EXPENSE_NOT_FOUND',404,'Despesa nao encontrada.').
    oldImage=ExpenseSnapshot(phExpenses).
    IF NOT poRequest:Has('row_stamp') OR poRequest:GetType('row_stamp')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_EXPENSE_STAMP',422,'Versao obrigatoria.').
    IF NOT COMPARE(poRequest:GetCharacter('row_stamp'),'=',PurchaseJsonStamp(oldImage),'RAW') THEN RUN Fail('PURCHASE_EXPENSE_CONFLICT',409,'Despesa alterada. Atualize os dados.').
    IF op='delete' THEN DO:
     IF NOT phExpenses:BUFFER-DELETE() THEN RUN Fail('PURCHASE_EXPENSE_WRITE',409,'Exclusao recusada.').
    END.
    ELSE DO:
     IF valuesObject:Has('despesa_id') AND definitionId<>phExpenses:BUFFER-FIELD('despesa_id'):BUFFER-VALUE THEN DO:
      IF NOT Found(phDefs,'despesa_id=' + N(definitionId),SHARE-LOCK) THEN RUN Fail('PURCHASE_EXPENSE_DEFINITION',422,'Despesa nao encontrada.').
      phExpenses:BUFFER-FIELD('despesa_id'):BUFFER-VALUE=definitionId.
     END.
     IF valuesObject:Has('vl_prev') THEN phExpenses:BUFFER-FIELD('vl_prev'):BUFFER-VALUE=amountValue.
     IF NOT phExpenses:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_EXPENSE_WRITE',409,'Validacao da despesa recusada.').
    END.
   END.
   IF op<>'delete' THEN DO: newImage=ExpenseSnapshot(phExpenses). resultData=ExpenseData(phExpenses,DescriptionValue()). END.
  END.
 END.
 writeComplete=TRUE. poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE).
 IF op='generate' THEN DO:
  resultData=NEW JsonObject(). resultData:Add('type','message'). resultData:Add('message',N(createdCount) + ' despesas criadas; ' + N(skippedCount) + ' existentes preservadas.').
  poResponse:Add('created',createdCount). poResponse:Add('skipped',skippedCount).
 END.
 IF op='delete' THEN DO: resultData=NEW JsonObject(). resultData:Add('despesa_proc_compra_id',recordId). END.
 poResponse:Add('data',resultData). actor=NEW JsonObject(). actor:Add('login',pcActor).
 audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction'). audit:Add('resource',IF op='generate' THEN 'procs-compra' ELSE 'despesas-proc-compra').
 audit:Add('operation',op). audit:Add('recordId',IF op='generate' THEN pid ELSE recordId). audit:Add('actor',actor).
 IF op='create' THEN audit:Add('before',NEW JsonArray()). ELSE audit:Add('before',oldImage).
 IF op='delete' THEN audit:Add('after',NEW JsonArray()). ELSE audit:Add('after',newImage).
 audit:Add('changes',changesValue). audit:Add('warnings',NEW JsonArray()). poResponse:Add('audit',audit).
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). poResponse:Add('committed',writeComplete).
  actor=NEW JsonObject(). actor:Add('code',code). actor:Add('status',statusCode). actor:Add('message',IF writeComplete THEN 'Operacao confirmada; nao repetir. Consulte os logs.' ELSE err:GetMessage(1)). poResponse:Add('error',actor).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END.
