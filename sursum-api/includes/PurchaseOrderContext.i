/* Shared owner/lock checks for contextual purchase children. Caller supplies fixed
   buffers, pid/itemId, N(), Fail() and purchaseContextCode. No table names from HTTP. */
FUNCTION Found RETURNS LOGICAL(h AS HANDLE,conditionValue AS CHARACTER,lockValue AS INTEGER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO.
 foundValue=h:FIND-FIRST('WHERE ' + conditionValue,lockValue,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail(purchaseContextCode + '_BUSY',409,'Registro em uso.').
 DO i=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(i)<>565 THEN RUN Fail(purchaseContextCode + '_READ_FAILED',503,'Leitura nao confirmada.'). END.
 RETURN foundValue.
END FUNCTION.
PROCEDURE OrderContextCheck:
 DEFINE INPUT PARAMETER locks AS INTEGER NO-UNDO.
 IF NOT Found(phOrders,'proc_compra_id=' + N(pid),locks) THEN RUN Fail(purchaseContextCode + '_PARENT',404,'Processo nao encontrado.').
 IF NOT Found(phCompanies,'empresa_id=' + N(phOrders:BUFFER-FIELD('empresa_id'):BUFFER-VALUE),IF locks=NO-LOCK THEN NO-LOCK ELSE SHARE-LOCK) THEN RUN Fail(purchaseContextCode + '_PARENT',404,'Processo MED nao encontrado.').
 IF phCompanies:BUFFER-FIELD('cod_emp_ems2'):BUFFER-VALUE=? OR phCompanies:BUFFER-FIELD('cod_emp_ems2'):BUFFER-VALUE<>5 THEN RUN Fail(purchaseContextCode + '_PARENT',404,'Processo MED nao encontrado.').
END PROCEDURE.
