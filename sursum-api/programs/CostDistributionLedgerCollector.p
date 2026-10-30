/* Original eight-field ledger projection; no balance, lookup or writer. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
{sursum-api/includes/CostDistributionLedgerTable.i}
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piItem AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piMaxRows AS INTEGER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piRowsRead AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttCostDistributionLedger.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE targetBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE sourceField AS HANDLE NO-UNDO.
DEFINE VARIABLE targetField AS HANDLE NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phLedger) OR piItem=? OR piItem<1 OR piStarted=? OR piMaxRows=? OR piMaxRows<1 OR piMaxRows>50000 OR piRowsRead=? OR piRowsRead<0 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_CONFIGURATION',1).
 targetBuffer=BUFFER ttCostDistributionLedger:HANDLE.
 DO n=1 TO targetBuffer:NUM-FIELDS:
  targetField=targetBuffer:BUFFER-FIELD(n). sourceField=phLedger:BUFFER-FIELD(targetField:NAME).
  IF sourceField:DATA-TYPE<>targetField:DATA-TYPE OR sourceField:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_CONFIGURATION',1).
 END.
 RUN Clock.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  CREATE QUERY q. q:SET-BUFFERS(phLedger).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phLedger:NAME + ' NO-LOCK WHERE ' + phLedger:NAME + '.item_container_id=' + TRIM(STRING(piItem,'->>>>>>>>>9'))) THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_CONFIGURATION',1).
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN Clock. IF piRowsRead>=piMaxRows THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_LIMIT',1).
   piRowsRead=piRowsRead + 1. CREATE ttCostDistributionLedger.
   DO n=1 TO targetBuffer:NUM-FIELDS:
    targetField=targetBuffer:BUFFER-FIELD(n). sourceField=phLedger:BUFFER-FIELD(targetField:NAME). targetField:BUFFER-VALUE=sourceField:BUFFER-VALUE.
   END.
   IF ttCostDistributionLedger.cta_corren_custo_distr_id=? OR ttCostDistributionLedger.item_container_id<>piItem THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_IDENTITY',1).
   RELEASE ttCostDistributionLedger. q:GET-NEXT(NO-LOCK).
  END.
  RUN Clock. complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_TIMEOUT',1).
 CATCH e AS Progress.Lang.Error: EMPTY TEMP-TABLE ttCostDistributionLedger. UNDO, THROW e. END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
  IF VALID-HANDLE(phLedger) THEN phLedger:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE Clock:
 IF ETIME - piStarted>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_TIMEOUT',1).
END PROCEDURE.
