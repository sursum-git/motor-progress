/* Nonrollback sequence state is private TT test callback; no DB/DDL. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE TEMP-TABLE ttItems FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttHistory FIELD item_proc_compra_id AS INTEGER INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttTxn FIELD marker AS INTEGER.
DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO.
DEFINE VARIABLE sequenceCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE modeValue AS INTEGER NO-UNDO.
DEFINE VARIABLE nextId AS INTEGER NO-UNDO.
DEFINE VARIABLE parentId AS INTEGER NO-UNDO INITIAL 101.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
DEFINE VARIABLE failureText AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE savedCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failLate AS LOGICAL NO-UNDO.
OUTPUT TO VALUE('purchase-item-id-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Invoke. RUN Check(NOT failed AND nextId=1,'fixed sequence first identity').
 FIND ttItems WHERE ttItems.item_proc_compra_id=1. DELETE ttItems.
 RUN Invoke. RUN Check(NOT failed AND nextId=2 AND CAN-FIND(ttHistory WHERE ttHistory.item_proc_compra_id=1),'delete maximum never reuses persistent identity or history').
 FIND ttItems WHERE ttItems.item_proc_compra_id=2. DELETE ttItems. parentId=102. RUN Invoke.
 RUN Check(NOT failed AND nextId=3 AND CAN-FIND(ttHistory WHERE ttHistory.item_proc_compra_id=2),'new parent shares monotonic sequence').
 failLate=TRUE. RUN Invoke. failLate=FALSE.
 RUN Check(failed AND sequenceValue=4 AND NOT CAN-FIND(ttItems WHERE ttItems.item_proc_compra_id=4),'root rollback preserves consumed sequence gap').
 RUN Invoke. RUN Check(NOT failed AND nextId=5 AND CAN-FIND(ttItems WHERE ttItems.item_proc_compra_id=5),'next create never reuses rolled-back identity').

 modeValue=1. savedCalls=sequenceCalls. RUN Invoke. RUN Check(failed AND sequenceCalls=savedCalls + 1,'zero sequence value refused with no loop').
 modeValue=2. savedCalls=sequenceCalls. RUN Invoke. RUN Check(failed AND sequenceCalls=savedCalls + 1,'unknown sequence value refused with no fallback').
 modeValue=3. savedCalls=sequenceCalls. RUN Invoke. RUN Check(failed AND INDEX(failureText,'PURCHASE_ITEM_IDENTITY_COLLISION')>0 AND sequenceCalls=savedCalls + 1,'stale sequence occupied key refused without repairing counter').
 modeValue=4. savedCalls=sequenceCalls. RUN Invoke. RUN Check(failed AND INDEX(failureText,'PURCHASE_ITEM_SEQUENCE_CONFIGURATION')>0 AND sequenceCalls=savedCalls + 1,'missing configuration blocks create').
 modeValue=0. sequenceValue=2147483647. savedCalls=sequenceCalls. RUN Invoke.
 RUN Check(failed AND INDEX(failureText,'PURCHASE_ITEM_SEQUENCE_EXHAUSTED')>0 AND sequenceCalls=savedCalls + 1,'exhaustion blocks create without wraparound').
 RUN Check(CAN-FIND(ttItems WHERE ttItems.item_proc_compra_id=3) AND NOT CAN-FIND(ttItems WHERE ttItems.item_proc_compra_id=0),'rejected allocations preserve existing parent item').
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' checks ': ' e:GetMessage(1) ' / ' failureText SKIP. END CATCH.
END. OUTPUT CLOSE.
PROCEDURE Invoke:
 failed=FALSE. failureText=''.
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTxn. ttTxn.marker=1.
  RUN PurchaseItemIdService.p(INPUT BUFFER ttItems:HANDLE,THIS-PROCEDURE,OUTPUT nextId).
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=nextId ttItems.proc_compra_id=parentId.
  CREATE ttHistory. ttHistory.item_proc_compra_id=nextId.
  IF failLate THEN UNDO, THROW NEW Progress.Lang.AppError('Injected failure after identity and item',1).
  DELETE ttTxn.
  CATCH e AS Progress.Lang.Error: failed=TRUE. failureText=e:GetMessage(1). END CATCH.
 END.
END PROCEDURE.
PROCEDURE NextRawPurchaseItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 sequenceCalls=sequenceCalls + 1.
 CASE modeValue:
  WHEN 1 THEN DO: valueId=0. RETURN. END.
  WHEN 2 THEN DO: valueId=?. RETURN. END.
  WHEN 3 THEN DO: valueId=3. RETURN. END.
  WHEN 4 THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: fixed sequence unavailable.',1).
 END CASE.
 IF sequenceValue=2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_EXHAUSTED: fixed sequence exhausted.',1).
 sequenceValue=sequenceValue + 1. valueId=sequenceValue.
END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.
