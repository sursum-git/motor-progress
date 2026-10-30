/* Shared civil ISO date conversion; no session-format dependency. */
FUNCTION PurchasePeriodDate RETURNS DATE(o AS JsonObject,n AS CHARACTER):
 DEFINE VARIABLE v AS CHARACTER NO-UNDO. DEFINE VARIABLE d AS DATE NO-UNDO.
 IF NOT o:Has(n) OR o:IsNull(n) THEN RETURN ?.
 IF o:GetType(n)<>JsonDataType:STRING THEN UNDO,THROW NEW Progress.Lang.AppError('Data ISO obrigatoria.',1).
 v=o:GetCharacter(n).
 IF LENGTH(v)<>10 OR SUBSTRING(v,5,1)<>'-' OR SUBSTRING(v,8,1)<>'-' THEN UNDO,THROW NEW Progress.Lang.AppError('Data ISO invalida.',1).
 d=DATE(INTEGER(SUBSTRING(v,6,2)),INTEGER(SUBSTRING(v,9,2)),INTEGER(SUBSTRING(v,1,4))) NO-ERROR.
 IF ERROR-STATUS:ERROR OR d=? OR ISO-DATE(d)<>v THEN UNDO,THROW NEW Progress.Lang.AppError('Data ISO invalida.',1).
 RETURN d.
END FUNCTION.
