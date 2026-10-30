/* One global balance rule for maintenance, selection and atomic allocation. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER phPurchase AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piPurchaseId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piContainerId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER plLocked AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pdBalance AS DECIMAL NO-UNDO.
DEFINE OUTPUT PARAMETER plExisting AS LOGICAL NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE bought AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE used AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE amount AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE finished AS LOGICAL NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE modeValue AS INTEGER NO-UNDO.
DO STOP-AFTER 10 ON STOP UNDO, LEAVE ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phPurchase) OR NOT VALID-HANDLE(phAllocations) OR piPurchaseId=? OR piPurchaseId<1 OR piContainerId=? OR piContainerId<1 OR plLocked=? THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_ALLOCATION_INVALID: contexto de saldo invalido.',1).
 IF plLocked AND NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_TRANSACTION_CONTEXT: saldo bloqueado exige transacao.',1).
 IF NOT phPurchase:AVAILABLE OR phPurchase:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE=? OR phPurchase:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE<>piPurchaseId THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_ALLOCATION_INVALID: item de compra divergente.',1).
 bought=phPurchase:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE.
 IF bought=? THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_ALLOCATION_INVALID: quantidade comprada desconhecida.',1).
 ASSIGN modeValue=IF plLocked THEN SHARE-LOCK ELSE NO-LOCK used=0 plExisting=FALSE.
 CREATE QUERY q. q:SET-BUFFERS(phAllocations).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + phAllocations:NAME + ' WHERE ' + phAllocations:NAME + '.item_proc_compra_id=' + TRIM(STRING(piPurchaseId,'->>>>>>>>>9'))) THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_CONFIGURATION: consulta fixa de saldo invalida.',1).
 q:QUERY-OPEN(). q:GET-FIRST(modeValue,NO-WAIT) NO-ERROR.
 DO WHILE NOT q:QUERY-OFF-END:
  IF phAllocations:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_BUSY: alocacao em uso.',1).
  n=n + 1. IF n>50000 THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_ALLOCATION_INVALID: limite de leitura de saldo excedido.',1).
  amount=phAllocations:BUFFER-FIELD('qt_alocada'):BUFFER-VALUE.
  IF amount=? OR amount<0 THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_ALLOCATION_INVALID: quantidade alocada invalida.',1).
  used=used + amount. IF phAllocations:BUFFER-FIELD('container_id'):BUFFER-VALUE=piContainerId THEN plExisting=TRUE.
  q:GET-NEXT(modeValue,NO-WAIT) NO-ERROR.
 END.
 IF phAllocations:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_BUSY: leitura de saldo recusada.',1).
 pdBalance=ROUND(bought,2) - ROUND(used,2). finished=TRUE.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END.
IF NOT finished THEN UNDO, THROW NEW Progress.Lang.AppError('CONTAINER_ITEM_ALLOCATION_INVALID: tempo de leitura de saldo excedido.',1).
