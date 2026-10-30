/* Single shared insert used by maintenance, missing-only generation and fiscal processing. */
PROCEDURE InsertExpense:
 DEFINE INPUT PARAMETER did AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER amount AS DECIMAL NO-UNDO. DEFINE INPUT PARAMETER calcId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION OR NOT VALID-HANDLE(phIdentity) OR LOOKUP('NextRawPurchaseExpenseId',phIdentity:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_EXPENSE_SEQUENCE',503,'Sequencia de despesas indisponivel.').
 ASSIGN code='PURCHASE_EXPENSE_SEQUENCE' statusCode=503.
 RUN NextRawPurchaseExpenseId IN phIdentity(OUTPUT recordId).
 ASSIGN code='PURCHASE_EXPENSE_VALIDATION' statusCode=422.
 IF recordId=? OR recordId<1 THEN RUN Fail('PURCHASE_EXPENSE_SEQUENCE',503,'Identidade positiva indisponivel.').
 IF Found(phExpenses,'despesa_proc_compra_id=' + N(recordId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_EXPENSE_COLLISION',409,'Sequencia atrasada. Nenhum reparo automatico foi aplicado.').
 IF NOT phExpenses:BUFFER-CREATE() THEN RUN Fail('PURCHASE_EXPENSE_WRITE',409,'Inclusao recusada.').
 ASSIGN phExpenses:BUFFER-FIELD('despesa_proc_compra_id'):BUFFER-VALUE=recordId
  phExpenses:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE=pid phExpenses:BUFFER-FIELD('despesa_id'):BUFFER-VALUE=did
  phExpenses:BUFFER-FIELD('vl_prev'):BUFFER-VALUE=amount phExpenses:BUFFER-FIELD('calc_imp_proc_compra_id'):BUFFER-VALUE=calcId.
 IF NOT phExpenses:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_EXPENSE_WRITE',409,'Validacao da despesa recusada.').
END PROCEDURE.
