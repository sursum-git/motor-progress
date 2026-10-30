/* One bounded item collector for forecast and taxable purchase bases.
   Fixed modes are internal callers only; SQL SUM ignores unknown terms. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piOrder AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcMode AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER pdExchange AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER piReadLock AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pdTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE amountTerm AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO. DEFINE VARIABLE scanned AS INTEGER NO-UNDO. DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
IF NOT VALID-HANDLE(phItems) OR piOrder=? OR piOrder<1 OR LOOKUP(pcMode,'forecast,tax_base')=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Contexto de itens invalido.',1).
IF piReadLock<>NO-LOCK AND piReadLock<>SHARE-LOCK THEN UNDO, THROW NEW Progress.Lang.AppError('Leitura de itens invalida.',1).
IF piReadLock=SHARE-LOCK AND NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Leitura fiscal exige transacao raiz.',1).
ASSIGN pdTotal=0 started=ETIME.
DO ON ERROR UNDO, THROW:
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  CREATE QUERY q. q:SET-BUFFERS(phItems).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phItems:NAME + ' WHERE proc_compra_id=' + TRIM(STRING(piOrder,'->>>>>>>>>9'))) THEN UNDO, THROW NEW Progress.Lang.AppError('Consulta de itens indisponivel.',1).
  q:QUERY-OPEN(). q:GET-FIRST(piReadLock,NO-WAIT) NO-ERROR.
  DO WHILE NOT q:QUERY-OFF-END:
   IF phItems:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Item em uso ou leitura nao confirmada.',1).
   scanned=scanned + 1. IF scanned>50000 OR ETIME - started>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('Limite de itens excedido.',1).
   amountTerm=IF pcMode='forecast' THEN pdExchange * DECIMAL(phItems:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE) * DECIMAL(phItems:BUFFER-FIELD('vl_negociado'):BUFFER-VALUE)
    ELSE DECIMAL(phItems:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE) * DECIMAL(phItems:BUFFER-FIELD('vl_base_tributacao'):BUFFER-VALUE).
   IF amountTerm<>? THEN pdTotal=pdTotal + amountTerm.
   q:GET-NEXT(piReadLock,NO-WAIT) NO-ERROR.
  END.
  IF phItems:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Leitura de itens nao confirmada.',1).
  complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('Tempo de leitura de itens excedido.',1).
 FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. END FINALLY.
END.
