/* Fixed-buffer fiscal collection/dependency plan. Caller owns root transaction;
   no persistent mutations and no sequence consumption here. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDefs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phBases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piOrder AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piCompany AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poPlan AS JsonArray NO-UNDO.
DEFINE TEMP-TABLE ttDef NO-UNDO FIELD id AS INTEGER FIELD tax AS INTEGER FIELD perItem AS INTEGER INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttTax NO-UNDO FIELD id AS INTEGER FIELD percentage AS DECIMAL DECIMALS 10 FIELD linkCount AS INTEGER FIELD needed AS LOGICAL FIELD done AS LOGICAL FIELD amountValue AS DECIMAL DECIMALS 2 INDEX pk IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttBase NO-UNDO FIELD taxId AS INTEGER FIELD expenseId AS INTEGER FIELD repeatCount AS INTEGER INDEX pk IS PRIMARY UNIQUE taxId expenseId.
DEFINE TEMP-TABLE ttExpense NO-UNDO FIELD id AS INTEGER FIELD countValue AS INTEGER FIELD sumValue AS DECIMAL DECIMALS 10 FIELD recordId AS INTEGER FIELD beforeText AS CHARACTER INDEX pk IS PRIMARY UNIQUE id.
DEFINE BUFFER bTax FOR ttTax.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE sourceBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE pass AS INTEGER NO-UNDO. DEFINE VARIABLE scanned AS INTEGER NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE idValue AS INTEGER NO-UNDO. DEFINE VARIABLE parentId AS INTEGER NO-UNDO. DEFINE VARIABLE neededCount AS INTEGER NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE conditionValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE productBase AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE expenseBase AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE rawAmount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE progressValue AS LOGICAL NO-UNDO. DEFINE VARIABLE readyValue AS LOGICAL NO-UNDO. DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DEFINE VARIABLE imageValue AS JsonObject NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO. DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE imageText AS LONGCHAR NO-UNDO.
{sursum-api/includes/PurchaseExpenseSnapshot.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT TRANSACTION OR piOrder=? OR piOrder<1 OR piCompany=? OR piCompany<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Plano fiscal exige contexto e transacao.',1).
 started=ETIME.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  DO pass=1 TO 4:
   ASSIGN sourceBuffer=IF pass=1 THEN phDefs ELSE IF pass=2 THEN phLinks ELSE IF pass=3 THEN phBases ELSE phExpenses
    conditionValue=IF pass=1 THEN '' ELSE IF pass=2 OR pass=3 THEN ' WHERE empresa_id=' + N(piCompany) ELSE ' WHERE proc_compra_id=' + N(piOrder).
   IF NOT VALID-HANDLE(sourceBuffer) THEN UNDO, THROW NEW Progress.Lang.AppError('Buffer fiscal ausente.',1).
   CREATE QUERY q. q:SET-BUFFERS(sourceBuffer).
   IF NOT q:QUERY-PREPARE('FOR EACH ' + sourceBuffer:NAME + conditionValue) THEN UNDO, THROW NEW Progress.Lang.AppError('Consulta fiscal recusada.',1).
   q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
   DO WHILE NOT q:QUERY-OFF-END:
    IF sourceBuffer:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Configuracao fiscal em uso.',1).
    scanned=scanned + 1. IF scanned>15000 OR ETIME - started>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('Plano fiscal excedeu limite.',1).
    idValue=sourceBuffer:BUFFER-FIELD('despesa_id'):BUFFER-VALUE.
    IF idValue=? OR idValue<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Despesa fiscal sem identidade.',1).
    CASE pass:
     WHEN 1 THEN DO:
      CREATE ttDef. ASSIGN ttDef.id=idValue ttDef.tax=sourceBuffer:BUFFER-FIELD('log_imposto'):BUFFER-VALUE ttDef.perItem=sourceBuffer:BUFFER-FIELD('log_calc_por_item'):BUFFER-VALUE.
     END.
     WHEN 2 THEN DO:
      FIND ttDef WHERE ttDef.id=idValue NO-ERROR.
      IF AVAILABLE ttDef AND ttDef.tax=1 THEN DO:
       FIND ttTax WHERE ttTax.id=idValue NO-ERROR.
       IF NOT AVAILABLE ttTax THEN DO: CREATE ttTax. ASSIGN ttTax.id=idValue ttTax.percentage=sourceBuffer:BUFFER-FIELD('percentual'):BUFFER-VALUE ttTax.needed=ttDef.perItem=0. END.
       ttTax.linkCount=ttTax.linkCount + 1.
      END.
     END.
     WHEN 3 THEN DO:
      parentId=sourceBuffer:BUFFER-FIELD('imposto_id'):BUFFER-VALUE.
      FIND ttBase WHERE ttBase.taxId=parentId AND ttBase.expenseId=idValue NO-ERROR.
      IF NOT AVAILABLE ttBase THEN DO: CREATE ttBase. ASSIGN ttBase.taxId=parentId ttBase.expenseId=idValue. END.
      ttBase.repeatCount=ttBase.repeatCount + 1.
     END.
     WHEN 4 THEN DO:
      FIND ttExpense WHERE ttExpense.id=idValue NO-ERROR.
      IF NOT AVAILABLE ttExpense THEN DO: CREATE ttExpense. ASSIGN ttExpense.id=idValue ttExpense.recordId=sourceBuffer:BUFFER-FIELD('despesa_proc_compra_id'):BUFFER-VALUE. imageValue=ExpenseSnapshot(sourceBuffer). imageValue:Write(imageText,FALSE). ttExpense.beforeText=STRING(imageText). DELETE OBJECT imageValue. END.
      ttExpense.countValue=ttExpense.countValue + 1. rawAmount=sourceBuffer:BUFFER-FIELD('vl_prev'):BUFFER-VALUE.
      IF rawAmount<>? THEN ttExpense.sumValue=ttExpense.sumValue + rawAmount.
     END.
    END CASE.
    q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
   END.
   IF sourceBuffer:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Leitura fiscal nao confirmada.',1).
   DELETE OBJECT q.
  END.
  /* Transitive closure, so per-item taxes are computed only when required. */
  progressValue=TRUE.
  DO WHILE progressValue:
   progressValue=FALSE.
   FOR EACH ttTax WHERE ttTax.needed:
    FOR EACH ttBase WHERE ttBase.taxId=ttTax.id:
     IF ttBase.repeatCount<>1 THEN UNDO, THROW NEW Progress.Lang.AppError('Componente fiscal duplicado.',1).
     FIND ttDef WHERE ttDef.id=ttBase.expenseId NO-ERROR.
     IF NOT AVAILABLE ttDef THEN UNDO, THROW NEW Progress.Lang.AppError('Componente fiscal inexistente.',1).
     IF ttDef.tax=1 THEN DO:
      FIND bTax WHERE bTax.id=ttDef.id NO-ERROR.
      IF NOT AVAILABLE bTax THEN UNDO, THROW NEW Progress.Lang.AppError('Imposto componente sem percentual da empresa.',1).
      IF NOT bTax.needed THEN ASSIGN bTax.needed=TRUE progressValue=TRUE.
     END.
    END.
   END.
  END.
  FOR EACH ttTax WHERE ttTax.needed:
   neededCount=neededCount + 1.
   IF neededCount>200 THEN UNDO, THROW NEW Progress.Lang.AppError('Plano fiscal excede200impostos.',1).
   IF ttTax.percentage=? OR ttTax.linkCount<>1 THEN UNDO, THROW NEW Progress.Lang.AppError('Percentual fiscal indefinido ou ambiguo.',1).
   FIND ttExpense WHERE ttExpense.id=ttTax.id NO-ERROR.
   IF AVAILABLE ttExpense AND ttExpense.countValue<>1 THEN UNDO, THROW NEW Progress.Lang.AppError('Imposto com despesas duplicadas no processo.',1).
  END.
  pathValue=SEARCH('sursum-api/programs/PurchaseItemAmounts.r'). IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Coletor de itens nao publicado.',1).
  RUN VALUE(pathValue)(phItems,piOrder,'tax_base',0,SHARE-LOCK,OUTPUT productBase).
  pathValue=SEARCH('sursum-api/programs/CiwTaxAmount.r'). IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Calculador fiscal nao publicado.',1).
  DO WHILE CAN-FIND(FIRST ttTax WHERE ttTax.needed AND NOT ttTax.done):
   progressValue=FALSE.
   FOR EACH ttTax WHERE ttTax.needed AND NOT ttTax.done BY ttTax.id:
    readyValue=TRUE.
    FOR EACH ttBase WHERE ttBase.taxId=ttTax.id: IF CAN-FIND(FIRST bTax WHERE bTax.id=ttBase.expenseId AND bTax.needed AND NOT bTax.done) THEN readyValue=FALSE. END.
    IF NOT readyValue THEN NEXT.
    expenseBase=0.
    FOR EACH ttBase WHERE ttBase.taxId=ttTax.id:
     FIND bTax WHERE bTax.id=ttBase.expenseId AND bTax.needed NO-ERROR.
     IF AVAILABLE bTax THEN expenseBase=expenseBase + bTax.amountValue.
     ELSE DO: FIND ttExpense WHERE ttExpense.id=ttBase.expenseId NO-ERROR. IF AVAILABLE ttExpense THEN expenseBase=expenseBase + ttExpense.sumValue. END.
    END.
    RUN VALUE(pathValue)(productBase,expenseBase,ttTax.percentage,OUTPUT rawAmount).
    ASSIGN ttTax.amountValue=ROUND(rawAmount,2) ttTax.done=TRUE progressValue=TRUE.
   END.
   IF NOT progressValue THEN UNDO, THROW NEW Progress.Lang.AppError('Dependencias fiscais ciclicas.',1).
  END.
  poPlan=NEW JsonArray(). parser=NEW ObjectModelParser().
  FOR EACH ttTax WHERE ttTax.needed BY ttTax.id:
   rowValue=NEW JsonObject(). rowValue:Add('despesa_id',ttTax.id). rowValue:Add('vl_prev',ttTax.amountValue).
   FIND ttExpense WHERE ttExpense.id=ttTax.id NO-ERROR.
   IF AVAILABLE ttExpense THEN DO: rowValue:Add('existing_id',ttExpense.recordId). rowValue:Add('before',CAST(parser:Parse(ttExpense.beforeText),JsonObject)). END.
   ELSE DO: rowValue:Add('existing_id',0). rowValue:Add('before',NEW JsonArray()). END.
   poPlan:Add(rowValue).
  END.
  complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('Plano fiscal excedeu tempo limite.',1).
 FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. IF VALID-OBJECT(parser) THEN DELETE OBJECT parser NO-ERROR. END FINALLY.
END.
