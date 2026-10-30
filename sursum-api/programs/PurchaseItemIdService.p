/* Persistent identity participant. The caller owns parent/MED mutex and root
   transaction. Fixed sequence increments survive UNDO; never MAX, reset or reuse gaps. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSequence AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER piId AS INTEGER NO-UNDO.
DEFINE VARIABLE candidateId AS INTEGER NO-UNDO.
DEFINE VARIABLE existsValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
IF NOT TRANSACTION OR NOT VALID-HANDLE(phSequence) OR LOOKUP('NextRawPurchaseItemId',phSequence:INTERNAL-ENTRIES)=0 THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: transacao e callback fixo obrigatorios.',1).
IF NOT VALID-HANDLE(phItems) THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: buffer fixo ausente.',1).
RUN NextRawPurchaseItemId IN phSequence(OUTPUT candidateId).
IF candidateId=? OR candidateId<1 THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: identidade positiva indisponivel.',1).
existsValue=phItems:FIND-FIRST('WHERE item_proc_compra_id=' + TRIM(STRING(candidateId,'->>>>>>>>>9')),EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
IF phItems:LOCKED THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_BUSY: identidade em uso.',1).
DO j=1 TO ERROR-STATUS:NUM-MESSAGES:
 IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: leitura da chave nao confirmada.',1).
END.
IF existsValue THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_IDENTITY_COLLISION: sequencia atrasada; nenhuma tentativa de reparo automatica.',1).
piId=candidateId.
