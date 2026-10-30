/* Complete physical image. Decimal foreign key is never rounded into another owner. */
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION ExpenseFields RETURNS CHARACTER():
 RETURN 'despesa_proc_compra_id,proc_compra_id,despesa_id,vl_prev,calc_imp_proc_compra_id'.
END FUNCTION.
FUNCTION ExpenseSnapshot RETURNS JsonObject(h AS HANDLE):
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE ownerValue AS DECIMAL NO-UNDO.
 ownerValue=h:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
 IF ownerValue=? OR ownerValue<1 OR ownerValue>2147483647 OR ownerValue<>TRUNCATE(ownerValue,0) THEN UNDO, THROW NEW Progress.Lang.AppError('Dono fisico da despesa invalido.',1).
 o=NEW JsonObject().
 DO k=1 TO NUM-ENTRIES(ExpenseFields()):
  f=h:BUFFER-FIELD(ENTRY(k,ExpenseFields())).
  IF f:BUFFER-VALUE=? THEN o:AddNull(f:NAME).
  ELSE IF f:NAME='vl_prev' THEN o:Add(f:NAME,DECIMAL(f:BUFFER-VALUE)).
  ELSE o:Add(f:NAME,INTEGER(f:BUFFER-VALUE)).
 END. RETURN o.
END FUNCTION.
FUNCTION ExpenseData RETURNS JsonObject(h AS HANDLE,descriptionValue AS CHARACTER):
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=ExpenseSnapshot(h). o:Add('row_stamp',PurchaseJsonStamp(o)). o:Add('despesa_descricao',IF descriptionValue=? THEN '' ELSE descriptionValue). RETURN o.
END FUNCTION.
