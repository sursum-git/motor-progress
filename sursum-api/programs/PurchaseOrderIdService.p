/* Private allocator. Caller MUST own the MED company mutex/root transaction.
   Sequence increments do not roll back; never SET-CURRENT-VALUE or reuse gaps. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSequence AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER piId AS INTEGER NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE maximumId AS INTEGER NO-UNDO.
DEFINE VARIABLE candidate AS INTEGER NO-UNDO.
DEFINE VARIABLE calls AS INTEGER NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
{sursum-api/includes/ContainerBufferSibling.i}
IF NOT TRANSACTION OR NOT VALID-HANDLE(phSequence) OR LOOKUP('NextRawOrderId',phSequence:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Alocador privado requer mutex e transacao raiz.',1).
DO STOP-AFTER 5 ON STOP UNDO, LEAVE:
 RUN ContainerCreateSiblingBuffer(phOrders,'bOrderMaximumIdentity',OUTPUT b).
 CREATE QUERY q. q:SET-BUFFERS(b).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + b:NAME + ' NO-LOCK BY proc_compra_id DESCENDING') THEN UNDO, THROW NEW Progress.Lang.AppError('Indice de identidade indisponivel.',1).
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 IF NOT q:QUERY-OFF-END THEN maximumId=b:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
 IF maximumId=? OR maximumId<0 OR maximumId=2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('Maior ID fisico invalido ou esgotado.',1).
 DO calls=1 TO 100000:
  RUN NextRawOrderId IN phSequence(OUTPUT candidate).
  IF candidate=? OR candidate<=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Sequencia retornou identidade invalida.',1).
  IF candidate>maximumId THEN DO: piId=candidate. complete=TRUE. LEAVE. END.
 END.
END.
IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('Sequencia atrasada excedeu100000incrementos ou5segundos; nenhum pedido criado.',1).
FINALLY:
 IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
 IF VALID-HANDLE(b) THEN DELETE OBJECT b NO-ERROR.
END FINALLY.
