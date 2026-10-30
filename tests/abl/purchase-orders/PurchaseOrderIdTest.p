BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE TEMP-TABLE ttOrders FIELD proc_compra_id AS INTEGER INDEX pk IS UNIQUE PRIMARY proc_compra_id.
DEFINE TEMP-TABLE ttTxn FIELD id AS INTEGER.
DEFINE VARIABLE counterValue AS INTEGER NO-UNDO.
DEFINE VARIABLE assignedId AS INTEGER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
DEFINE VARIABLE stuck AS LOGICAL NO-UNDO.
DEFINE VARIABLE modeValue AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
OUTPUT TO VALUE('purchase-id-tests-' + SESSION:NUMERIC-FORMAT + '.log').
CREATE ttOrders. ttOrders.proc_compra_id=1679. counterValue=0. RUN Invoke.
RUN Check(NOT failed AND assignedId=1680 AND counterValue=1680,'catch up real sequence without reusing gaps').
RUN Invoke. RUN Check(NOT failed AND assignedId=1681,'ahead sequence monotonic').
modeValue=1. RUN Invoke. RUN Check(failed,'invalid sequence output fails before create').
modeValue=2. counterValue=0. RUN Invoke. RUN Check(failed AND counterValue=100000,'stuck sequence bounded by100000 calls').
FIND ttOrders. ttOrders.proc_compra_id=2147483647. modeValue=0. counterValue=0. RUN Invoke. RUN Check(failed AND counterValue=0,'physical overflow refuses before sequence mutation').
PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP. OUTPUT CLOSE.
PROCEDURE Invoke:
 failed=FALSE.
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTxn. ttTxn.id=1.
  RUN PurchaseOrderIdService.p(INPUT BUFFER ttOrders:HANDLE,THIS-PROCEDURE,OUTPUT assignedId).
  DELETE ttTxn.
  CATCH e AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
END PROCEDURE.
PROCEDURE NextRawOrderId:
 DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. counterValue=counterValue + 1.
 id=IF modeValue=1 THEN ? ELSE IF modeValue=2 THEN 1 ELSE counterValue.
END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF NOT ok THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.
