/* Shared strict identity and canonical stamp; shipment wrappers retain compatibility. */
FUNCTION PurchaseJsonId RETURNS INTEGER(o AS JsonObject,n AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF NOT o:Has(n) THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade obrigatoria.',1).
 IF o:GetType(n)=JsonDataType:STRING THEN rawValue=o:GetCharacter(n).
 ELSE IF o:GetType(n)=JsonDataType:NUMBER THEN rawValue=STRING(o:GetJsonText(n)).
 ELSE UNDO, THROW NEW Progress.Lang.AppError('Identidade inteira obrigatoria.',1).
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 OR SUBSTRING(rawValue,1,1)='0' THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade positiva invalida.',1).
 DO k=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade inteira invalida.',1). END.
 IF DECIMAL(rawValue)>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('Identidade fora da faixa.',1).
 RETURN INTEGER(rawValue).
END FUNCTION.
FUNCTION PurchaseJsonStamp RETURNS CHARACTER(o AS JsonObject):
 DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
 o:Write(textValue,FALSE). hashValue=HEX-ENCODE(MESSAGE-DIGEST('SHA-256',textValue)). RETURN CAPS(hashValue).
END FUNCTION.
