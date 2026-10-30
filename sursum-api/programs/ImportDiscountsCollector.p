/* One read-only aggregate for the legacy global list, detail and owned ledger. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
{sursum-api/includes/ImportDiscountsReadTables.i}
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piSelectedId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piMaxRows AS INTEGER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piRowsRead AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttImportDiscountsRead.
DEFINE OUTPUT PARAMETER TABLE FOR ttImportDiscountLedgerRead.
DEFINE VARIABLE headerQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE ledgerQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE discountId AS INTEGER NO-UNDO.
DEFINE VARIABLE rawSum AS DECIMAL NO-UNDO.
DEFINE VARIABLE amountValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE sourceField AS HANDLE NO-UNDO.
DEFINE VARIABLE targetField AS HANDLE NO-UNDO.
DEFINE VARIABLE targetBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE whereClause AS CHARACTER NO-UNDO.
DEFINE VARIABLE headerFields AS CHARACTER NO-UNDO INITIAL 'desconto_importacao_id,motivo_desconto_id,descricao,log_credito,vl_dolar,vl_real,vl_cotacao_dolar,item_container_id,cod_tipo,fornecedor_id,vl_real_autorizado,vl_dolar_autorizado,dt_autorizacao'.
FUNCTION IdText RETURNS CHARACTER(idValue AS INTEGER):
 RETURN TRIM(STRING(idValue,'->>>>>>>>>9')).
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phDiscounts) OR NOT VALID-HANDLE(phLedger) OR piStarted=? OR piMaxRows=? OR piMaxRows<1 OR piMaxRows>50000 OR piRowsRead=? OR piRowsRead<0 THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
 RUN CheckClock.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  CREATE QUERY headerQuery. headerQuery:SET-BUFFERS(phDiscounts).
  whereClause=IF piSelectedId=? THEN 'TRUE' ELSE phDiscounts:NAME + '.desconto_importacao_id=' + IdText(piSelectedId).
  IF NOT headerQuery:QUERY-PREPARE('FOR EACH ' + phDiscounts:NAME + ' NO-LOCK WHERE ' + whereClause) THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
  headerQuery:QUERY-OPEN(). headerQuery:GET-FIRST(NO-LOCK).
  CREATE QUERY ledgerQuery. ledgerQuery:SET-BUFFERS(phLedger).
  DO WHILE NOT headerQuery:QUERY-OFF-END:
   RUN CountRow.
   discountId=phDiscounts:BUFFER-FIELD('desconto_importacao_id'):BUFFER-VALUE.
   IF discountId=? THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_IDENTITY',1).
   CREATE ttImportDiscountsRead. targetBuffer=BUFFER ttImportDiscountsRead:HANDLE.
   DO n=1 TO NUM-ENTRIES(headerFields):
    targetField=targetBuffer:BUFFER-FIELD(ENTRY(n,headerFields)). sourceField=phDiscounts:BUFFER-FIELD(targetField:NAME).
    IF sourceField:DATA-TYPE<>targetField:DATA-TYPE OR sourceField:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
    targetField:BUFFER-VALUE=sourceField:BUFFER-VALUE.
   END.
   rawSum=?.
   IF NOT ledgerQuery:QUERY-PREPARE('FOR EACH ' + phLedger:NAME + ' NO-LOCK WHERE ' + phLedger:NAME + '.desconto_importacao_id=' + IdText(discountId)) THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
   ledgerQuery:QUERY-OPEN(). ledgerQuery:GET-FIRST(NO-LOCK).
   DO WHILE NOT ledgerQuery:QUERY-OFF-END:
    RUN CountRow.
    CREATE ttImportDiscountLedgerRead. targetBuffer=BUFFER ttImportDiscountLedgerRead:HANDLE.
    DO n=1 TO targetBuffer:NUM-FIELDS:
     targetField=targetBuffer:BUFFER-FIELD(n). sourceField=phLedger:BUFFER-FIELD(targetField:NAME).
     IF sourceField:DATA-TYPE<>targetField:DATA-TYPE OR sourceField:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
     targetField:BUFFER-VALUE=sourceField:BUFFER-VALUE.
    END.
    IF ttImportDiscountLedgerRead.cta_corren_desconto_id=? OR ttImportDiscountLedgerRead.desconto_importacao_id<>discountId THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_IDENTITY',1).
    amountValue=ttImportDiscountLedgerRead.valor_utilizado.
    /* SQL SUM ignores NULL; the empty/all-NULL aggregate itself remains NULL. */
    IF amountValue<>? THEN rawSum=(IF rawSum=? THEN 0 ELSE rawSum) + amountValue.
    RELEASE ttImportDiscountLedgerRead.
    ledgerQuery:GET-NEXT(NO-LOCK).
   END.
   ledgerQuery:QUERY-CLOSE().
   ASSIGN ttImportDiscountsRead.vl_utiliz_detalhe=rawSum
          ttImportDiscountsRead.vl_utiliz=IF rawSum=? THEN 0 ELSE rawSum
          ttImportDiscountsRead.vl_saldo=ttImportDiscountsRead.vl_dolar_autorizado - ttImportDiscountsRead.vl_utiliz.
   RELEASE ttImportDiscountsRead.
   headerQuery:GET-NEXT(NO-LOCK).
  END.
  RUN CheckClock. complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_TIMEOUT',1).
 CATCH e AS Progress.Lang.Error:
  EMPTY TEMP-TABLE ttImportDiscountsRead. EMPTY TEMP-TABLE ttImportDiscountLedgerRead.
  UNDO, THROW e.
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(headerQuery) THEN DO: headerQuery:QUERY-CLOSE() NO-ERROR. DELETE OBJECT headerQuery NO-ERROR. END.
  IF VALID-HANDLE(ledgerQuery) THEN DO: ledgerQuery:QUERY-CLOSE() NO-ERROR. DELETE OBJECT ledgerQuery NO-ERROR. END.
  IF VALID-HANDLE(phDiscounts) THEN phDiscounts:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phLedger) THEN phLedger:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE CheckClock:
 IF ETIME - piStarted>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_TIMEOUT',1).
END PROCEDURE.
PROCEDURE CountRow:
 RUN CheckClock.
 IF piRowsRead>=piMaxRows THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_LIMIT',1).
 piRowsRead=piRowsRead + 1.
END PROCEDURE.
