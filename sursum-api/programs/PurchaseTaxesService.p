/* One root transaction for the entire fiscal plan. The reusable planner never
   writes; the shared expense inserter owns new expense identities/validation. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phBases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCalcs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phIdentity AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseExpenseSnapshot.i}
{sursum-api/includes/PurchaseOrderSnapshot.i}
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_TAX'.
DEFINE VARIABLE pid AS INTEGER NO-UNDO. DEFINE VARIABLE recordId AS INTEGER NO-UNDO. DEFINE VARIABLE calculationId AS INTEGER NO-UNDO.
DEFINE VARIABLE createdCount AS INTEGER NO-UNDO. DEFINE VARIABLE updatedCount AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_TAX_VALIDATION'. DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE oldImage AS JsonObject NO-UNDO. DEFINE VARIABLE newImage AS JsonObject NO-UNDO. DEFINE VARIABLE existingImage AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO. DEFINE VARIABLE effectValue AS JsonObject NO-UNDO. DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE planValue AS JsonArray NO-UNDO. DEFINE VARIABLE effectsValue AS JsonArray NO-UNDO. DEFINE VARIABLE auditValue AS JsonObject NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
{sursum-api/includes/PurchaseOrderContext.i}
{sursum-api/includes/PurchaseExpenseInsert.i}
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phExpenses) OR NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phDefs) OR NOT VALID-HANDLE(phLinks) OR NOT VALID-HANDLE(phBases) OR NOT VALID-HANDLE(phCalcs) OR NOT VALID-HANDLE(phIdentity) THEN RUN Fail('PURCHASE_TAX_CONFIGURATION',503,'Configuracao fiscal indisponivel.').
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(code,422,'Requisicao obrigatoria.').
 pid=PurchaseJsonId(poRequest,'proc_compra_id').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422,'Operacao obrigatoria.').
 IF poRequest:GetCharacter('operation')<>'calculate_taxes' THEN RUN Fail('PURCHASE_TAX_OPERATION',405,'Operacao fiscal fixa obrigatoria.').
 ns=poRequest:GetNames(). DO k=1 TO EXTENT(ns): IF LOOKUP(ns[k],'operation,proc_compra_id')=0 THEN RUN Fail(code,422,'Campo nao permitido.'). END.
 IF pcActor=? OR TRIM(pcActor)='' OR LENGTH(pcActor)>256 THEN RUN Fail('PURCHASE_TAX_IDENTITY',401,'Usuario autenticado obrigatorio.').
 IF TRANSACTION THEN RUN Fail('PURCHASE_TAX_TRANSACTION',409,'Uma transacao raiz independente e obrigatoria.').
 IF LOOKUP('NextRawPurchaseTaxCalcId',phIdentity:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_TAX_CONFIGURATION',503,'Provider fiscal indisponivel.').
 RUN OrderContextCheck(NO-LOCK).
 effectsValue=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN OrderContextCheck(EXCLUSIVE-LOCK). oldImage=PurchaseOrderSnapshot(phOrders).
  pathValue=SEARCH('sursum-api/programs/PurchaseTaxPlan.r'). IF pathValue=? THEN RUN Fail('PURCHASE_TAX_CONFIGURATION',503,'Planejador fiscal nao publicado.').
  ASSIGN code='PURCHASE_TAX_PLAN' statusCode=422.
  RUN VALUE(pathValue)(phItems,phDefs,phLinks,phBases,phExpenses,pid,INTEGER(phOrders:BUFFER-FIELD('empresa_id'):BUFFER-VALUE),OUTPUT planValue).
  IF NOT VALID-OBJECT(planValue) OR planValue:Length>200 THEN RUN Fail('PURCHASE_TAX_PLAN',422,'Plano fiscal invalido.').
  ASSIGN code='PURCHASE_TAX_WRITE' statusCode=409.
  RUN NextRawPurchaseTaxCalcId IN phIdentity(OUTPUT calculationId).
  IF calculationId=? OR calculationId<1 OR Found(phCalcs,'calc_imp_proc_compra_id=' + N(calculationId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_TAX_COLLISION',409,'Identidade fiscal indisponivel; nenhum reparo aplicado.').
  IF NOT phCalcs:BUFFER-CREATE() THEN RUN Fail('PURCHASE_TAX_WRITE',409,'Inclusao do calculo recusada.').
  ASSIGN phCalcs:BUFFER-FIELD('calc_imp_proc_compra_id'):BUFFER-VALUE=calculationId phCalcs:BUFFER-FIELD('dt_hr_calculo'):BUFFER-VALUE=NOW phCalcs:BUFFER-FIELD('usuario_id'):BUFFER-VALUE=pcActor.
  IF NOT phCalcs:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_TAX_WRITE',409,'Validacao do calculo recusada.').
  rowValue=NEW JsonObject(). rowValue:Add('calc_imp_proc_compra_id',calculationId). rowValue:Add('dt_hr_calculo',ISO-DATE(DATETIME(phCalcs:BUFFER-FIELD('dt_hr_calculo'):BUFFER-VALUE))). rowValue:Add('usuario_id',pcActor).
  effectValue=NEW JsonObject(). effectValue:Add('resource','calcs-imp-proc-compra'). effectValue:Add('operation','create'). effectValue:Add('recordId',calculationId). effectValue:Add('before',NEW JsonArray()). effectValue:Add('after',rowValue). effectsValue:Add(effectValue).
  DO k=1 TO planValue:Length:
   rowValue=planValue:GetJsonObject(k). recordId=rowValue:GetInteger('existing_id').
   effectValue=NEW JsonObject(). effectValue:Add('resource','despesas-proc-compra').
   IF recordId=0 THEN DO:
    RUN InsertExpense(rowValue:GetInteger('despesa_id'),rowValue:GetDecimal('vl_prev'),calculationId).
    effectValue:Add('operation','create'). effectValue:Add('before',NEW JsonArray()). createdCount=createdCount + 1.
   END.
   ELSE DO:
    IF NOT Found(phExpenses,'despesa_proc_compra_id=' + N(recordId) + ' AND proc_compra_id=' + N(pid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_TAX_CONFLICT',409,'Despesa fiscal alterada.').
    existingImage=ExpenseSnapshot(phExpenses).
    IF NOT COMPARE(PurchaseJsonStamp(existingImage),'=',PurchaseJsonStamp(rowValue:GetJsonObject('before')),'RAW') THEN RUN Fail('PURCHASE_TAX_CONFLICT',409,'Despesa fiscal alterada durante o calculo.').
    effectValue:Add('before',existingImage). effectValue:Add('operation','update').
    ASSIGN phExpenses:BUFFER-FIELD('vl_prev'):BUFFER-VALUE=rowValue:GetDecimal('vl_prev') phExpenses:BUFFER-FIELD('calc_imp_proc_compra_id'):BUFFER-VALUE=calculationId.
    IF NOT phExpenses:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_TAX_WRITE',409,'Validacao da despesa fiscal recusada.').
    updatedCount=updatedCount + 1.
   END.
   effectValue:Add('recordId',recordId). effectValue:Add('after',ExpenseSnapshot(phExpenses)). effectsValue:Add(effectValue).
  END.
  newImage=PurchaseOrderSnapshot(phOrders).
 END.
 complete=TRUE.
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE). poResponse:Add('calculationId',calculationId). poResponse:Add('created',createdCount). poResponse:Add('updated',updatedCount).
 rowValue=NEW JsonObject(). rowValue:Add('type','message'). rowValue:Add('message','Calculo ' + N(calculationId) + ' confirmado: ' + N(createdCount) + ' impostos incluidos e ' + N(updatedCount) + ' atualizados. Consulte as despesas e os logs do processo.'). poResponse:Add('data',rowValue).
 actor=NEW JsonObject(). actor:Add('login',pcActor).
 auditValue=NEW JsonObject(). auditValue:Add('version',1). auditValue:Add('source','progress-transaction'). auditValue:Add('resource','procs-compra'). auditValue:Add('operation','calculate_taxes'). auditValue:Add('recordId',pid). auditValue:Add('actor',actor). auditValue:Add('before',oldImage). auditValue:Add('after',newImage). auditValue:Add('changes',effectsValue). auditValue:Add('warnings',NEW JsonArray()). poResponse:Add('audit',auditValue).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). poResponse:Add('committed',complete). actor=NEW JsonObject(). actor:Add('code',code). actor:Add('status',statusCode). actor:Add('message',IF complete THEN 'Calculo confirmado; nao repetir. Consulte a transacao.' ELSE e:GetMessage(1)). poResponse:Add('error',actor).
 END CATCH.
END.
