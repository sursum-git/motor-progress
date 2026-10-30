/* Original import-quantity CASE expressions, shared by read projections.
   Physical quantity has precedence over confirmed quantity; this is not MAX. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER pdBought AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER pdPrice AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER pdConfirmed AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER pdPhysical AS DECIMAL NO-UNDO.
DEFINE OUTPUT PARAMETER poResult AS JsonObject NO-UNDO.
DEFINE VARIABLE confirmedValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE physicalValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE boughtFinal AS DECIMAL NO-UNDO.
DEFINE VARIABLE receivedFinal AS DECIMAL NO-UNDO.
DEFINE VARIABLE physicalAmount AS DECIMAL NO-UNDO.
PROCEDURE PutNumber:
 DEFINE INPUT PARAMETER fieldValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER amountValue AS DECIMAL NO-UNDO.
 IF amountValue=? THEN poResult:AddNull(fieldValue). ELSE poResult:Add(fieldValue,amountValue).
END PROCEDURE.
ASSIGN confirmedValue=IF pdConfirmed=? THEN 0 ELSE pdConfirmed
 physicalValue=IF pdPhysical=? THEN 0 ELSE pdPhysical boughtFinal=pdBought.
IF pdBought<>? THEN DO:
 IF physicalValue>pdBought THEN boughtFinal=physicalValue.
 ELSE IF confirmedValue>pdBought THEN boughtFinal=confirmedValue.
END.
ASSIGN receivedFinal=IF physicalValue=0 THEN confirmedValue ELSE physicalValue
 physicalAmount=physicalValue * pdPrice.
poResult=NEW JsonObject().
RUN PutNumber('qt_comprada_final',boughtFinal).
RUN PutNumber('vl_comprada_final',boughtFinal * pdPrice).
RUN PutNumber('qt_rec_final',receivedFinal).
RUN PutNumber('vl_rec_final',IF physicalAmount=0 THEN confirmedValue * pdPrice ELSE physicalAmount).
