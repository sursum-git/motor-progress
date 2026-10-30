/* Item owner check composes the same MED order/lock validation as general documents. */
{sursum-api/includes/PurchaseOrderContext.i}
PROCEDURE ContextCheck:
 DEFINE INPUT PARAMETER locks AS INTEGER NO-UNDO.
 RUN OrderContextCheck(locks).
 IF NOT Found(phItems,'item_proc_compra_id=' + N(itemId) + ' AND proc_compra_id=' + N(pid),locks) THEN RUN Fail(purchaseContextCode + '_ITEM',404,'Item do processo nao encontrado.').
END PROCEDURE.
