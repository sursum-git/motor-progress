/* Fixed physical image shared by the native adapter and the private locked seam. */
FUNCTION ExpenseBatchFields RETURNS CHARACTER():
 RETURN 'despesa_container_id,despesa_id,vl_prev,container_id,calc_imp_container_id,vl_base_imp,vl_negociado,vl_proforma,cta_corren_custo_distr_id,log_utilizado,log_manual,perc_calc,memoria_calculo,item_container_id'.
END FUNCTION.
FUNCTION ExpenseBatchImageValid RETURNS LOGICAL(o AS JsonObject):
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE n AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE fieldIndex AS INTEGER NO-UNDO. DEFINE VARIABLE v AS DECIMAL NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN RETURN FALSE.
 names=o:GetNames(). IF EXTENT(names)<>14 THEN RETURN FALSE.
 DO j=1 TO EXTENT(names):
  n=names[j]. fieldIndex=LOOKUP(n,ExpenseBatchFields()). IF fieldIndex=0 THEN RETURN FALSE.
  IF COMPARE(n,'<>',ENTRY(fieldIndex,ExpenseBatchFields()),'RAW') THEN RETURN FALSE.
  IF o:IsNull(n) THEN DO: IF LOOKUP(n,'despesa_container_id,container_id,despesa_id')>0 THEN RETURN FALSE. NEXT. END.
  IF n='memoria_calculo' THEN DO: IF o:GetType(n)<>JsonDataType:STRING OR LENGTH(o:GetCharacter(n))>32000 THEN RETURN FALSE. END.
  ELSE IF LOOKUP(n,'log_utilizado,log_manual')>0 THEN DO: IF o:GetType(n)<>JsonDataType:BOOLEAN THEN RETURN FALSE. END.
  ELSE DO:
   IF o:GetType(n)<>JsonDataType:NUMBER THEN RETURN FALSE. v=o:GetDecimal(n).
   IF LOOKUP(n,'despesa_container_id,despesa_id,container_id,calc_imp_container_id,cta_corren_custo_distr_id,item_container_id')>0 THEN DO:
    IF v<>TRUNCATE(v,0) OR v< -2147483648 OR v>2147483647 THEN RETURN FALSE.
    IF LOOKUP(n,'despesa_container_id,container_id,despesa_id')>0 AND v<1 THEN RETURN FALSE.
   END.
  END.
 END.
 RETURN TRUE.
END FUNCTION.
FUNCTION ExpenseBatchImageSame RETURNS LOGICAL(a AS JsonObject,b AS JsonObject):
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE n AS CHARACTER NO-UNDO.
 IF NOT ExpenseBatchImageValid(a) OR NOT ExpenseBatchImageValid(b) THEN RETURN FALSE.
 DO j=1 TO 14:
  n=ENTRY(j,ExpenseBatchFields()). IF a:GetType(n)<>b:GetType(n) THEN RETURN FALSE.
  IF a:IsNull(n) THEN NEXT.
  CASE a:GetType(n):
   WHEN JsonDataType:STRING THEN IF LENGTH(a:GetCharacter(n))<>LENGTH(b:GetCharacter(n)) OR COMPARE(a:GetCharacter(n),'<>',b:GetCharacter(n),'RAW') THEN RETURN FALSE.
   WHEN JsonDataType:NUMBER THEN IF a:GetDecimal(n)<>b:GetDecimal(n) THEN RETURN FALSE.
   WHEN JsonDataType:BOOLEAN THEN IF a:GetLogical(n)<>b:GetLogical(n) THEN RETURN FALSE.
  END CASE.
 END.
 RETURN TRUE.
END FUNCTION.
