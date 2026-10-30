/* JSON lexical precision must be checked before GetDecimal rounds to ABL scale10.
   Decimal exponents emitted by JSON.stringify are valid; integer exponents are not. */
FUNCTION PurchaseItemDecimalFits RETURNS LOGICAL(rawValue AS CHARACTER,scaleValue AS INTEGER):
 DEFINE VARIABLE mantissa AS CHARACTER NO-UNDO. DEFINE VARIABLE digits AS CHARACTER NO-UNDO.
 DEFINE VARIABLE exponentText AS CHARACTER NO-UNDO. DEFINE VARIABLE exponentValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE epos AS INTEGER NO-UNDO. DEFINE VARIABLE dotpos AS INTEGER NO-UNDO.
 DEFINE VARIABLE fractionDigits AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF rawValue=? OR LENGTH(rawValue)<1 OR LENGTH(rawValue)>80 THEN RETURN FALSE.
 epos=INDEX(CAPS(rawValue),'E'). mantissa=IF epos=0 THEN rawValue ELSE SUBSTRING(rawValue,1,epos - 1).
 IF epos>0 THEN DO:
  exponentText=SUBSTRING(rawValue,epos + 1).
  IF SUBSTRING(exponentText,1,1)='+' OR SUBSTRING(exponentText,1,1)='-' THEN exponentText=SUBSTRING(exponentText,2).
  IF LENGTH(exponentText)<1 OR LENGTH(exponentText)>3 THEN RETURN FALSE.
  DO k=1 TO LENGTH(exponentText): IF INDEX('0123456789',SUBSTRING(exponentText,k,1))=0 THEN RETURN FALSE. END.
  exponentValue=INTEGER(SUBSTRING(rawValue,epos + 1)) NO-ERROR. IF ERROR-STATUS:ERROR THEN RETURN FALSE.
 END.
 IF SUBSTRING(mantissa,1,1)='-' THEN mantissa=SUBSTRING(mantissa,2).
 dotpos=INDEX(mantissa,'.'). fractionDigits=IF dotpos=0 THEN 0 ELSE LENGTH(mantissa) - dotpos.
 digits=REPLACE(mantissa,'.',''). IF LENGTH(digits)=0 THEN RETURN FALSE.
 DO k=1 TO LENGTH(digits): IF INDEX('0123456789',SUBSTRING(digits,k,1))=0 THEN RETURN FALSE. END.
 DO WHILE LENGTH(digits)>0 AND SUBSTRING(digits,1,1)='0': digits=SUBSTRING(digits,2). END.
 IF digits='' THEN RETURN TRUE.
 /* Nonzero significant digits beyond the physical scale would be lost. */
 DO WHILE LENGTH(digits)>0 AND SUBSTRING(digits,LENGTH(digits),1)='0':
  digits=SUBSTRING(digits,1,LENGTH(digits) - 1). fractionDigits=fractionDigits - 1.
 END.
 RETURN fractionDigits - exponentValue<=scaleValue AND LENGTH(digits) - fractionDigits + exponentValue<=12.
END FUNCTION.

/* OpenEdge JsonObject:GetDecimal refuses exponent notation (16061). Convert
   only after the exact lexical precision/range gate accepted the JSON number. */
FUNCTION PurchaseItemDecimalNumber RETURNS DECIMAL(rawValue AS CHARACTER):
 DEFINE VARIABLE mantissa AS CHARACTER NO-UNDO. DEFINE VARIABLE digits AS CHARACTER NO-UNDO.
 DEFINE VARIABLE exponentValue AS INTEGER NO-UNDO. DEFINE VARIABLE fractionDigits AS INTEGER NO-UNDO.
 DEFINE VARIABLE epos AS INTEGER NO-UNDO. DEFINE VARIABLE dotpos AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE negativeValue AS LOGICAL NO-UNDO. DEFINE VARIABLE resultValue AS DECIMAL DECIMALS 10 NO-UNDO.
 IF NOT PurchaseItemDecimalFits(rawValue,10) THEN RETURN ?.
 epos=INDEX(CAPS(rawValue),'E'). mantissa=IF epos=0 THEN rawValue ELSE SUBSTRING(rawValue,1,epos - 1).
 IF epos>0 THEN exponentValue=INTEGER(SUBSTRING(rawValue,epos + 1)).
 IF SUBSTRING(mantissa,1,1)='-' THEN DO: negativeValue=TRUE. mantissa=SUBSTRING(mantissa,2). END.
 dotpos=INDEX(mantissa,'.'). fractionDigits=IF dotpos=0 THEN 0 ELSE LENGTH(mantissa) - dotpos.
 digits=REPLACE(mantissa,'.','').
 DO WHILE LENGTH(digits)>0 AND SUBSTRING(digits,1,1)='0': digits=SUBSTRING(digits,2). END.
 IF digits='' THEN RETURN 0.
 DO WHILE LENGTH(digits)>0 AND SUBSTRING(digits,LENGTH(digits),1)='0': digits=SUBSTRING(digits,1,LENGTH(digits) - 1). fractionDigits=fractionDigits - 1. END.
 DO k=1 TO LENGTH(digits): resultValue=resultValue * 10 + INTEGER(SUBSTRING(digits,k,1)). END.
 IF exponentValue>=fractionDigits THEN DO k=1 TO exponentValue - fractionDigits: resultValue=resultValue * 10. END.
 ELSE DO k=1 TO fractionDigits - exponentValue: resultValue=resultValue / 10. END.
 RETURN IF negativeValue THEN - resultValue ELSE resultValue.
END FUNCTION.
