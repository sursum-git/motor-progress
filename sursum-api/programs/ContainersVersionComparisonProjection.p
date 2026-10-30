/* One private presentation projection of persisted operands for BRL and USD.
   Never generates/persists a cost. SQL precision and mixed NULL/zero gates remain. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poInput AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE nameValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE quantityValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE shippedValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE costValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE expenseValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE withoutValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE unitValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE percentValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE totalValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE withoutTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE withoutUnit AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE ratioValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE fixedExpense AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE fixedTotal AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE fixedUnit AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE codeValue AS CHARACTER NO-UNDO.
FUNCTION NumberValue RETURNS DECIMAL (fieldName AS CHARACTER):
 IF NOT poInput:Has(fieldName) THEN RUN Fail('COMPARISON_PROJECTION_REQUEST',422).
 IF poInput:IsNull(fieldName) THEN RETURN ?.
 IF poInput:GetType(fieldName)<>JsonDataType:NUMBER THEN RUN Fail('COMPARISON_PROJECTION_REQUEST',422).
 RETURN poInput:GetDecimal(fieldName).
END FUNCTION.
PROCEDURE AddNumber:
 DEFINE INPUT PARAMETER fieldName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER amountValue AS DECIMAL DECIMALS 10 NO-UNDO.
 IF amountValue=? THEN rowValue:AddNull(fieldName). ELSE rowValue:Add(fieldName,amountValue).
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poInput) THEN RUN Fail('COMPARISON_PROJECTION_REQUEST',422).
 names=poInput:GetNames().
 IF EXTENT(names)<>7 THEN RUN Fail('COMPARISON_PROJECTION_REQUEST',422).
 DO n=1 TO EXTENT(names):
  nameValue=names[n].
  IF nameValue<>'qt_alocada' AND nameValue<>'qt_confirm_emb' AND nameValue<>'vl_custo_prev'
   AND nameValue<>'vl_desp_prev' AND nameValue<>'vl_unit_prev' AND nameValue<>'vl_desp_prev_sem_distr_custo'
   AND nameValue<>'perc_fixo_container' THEN RUN Fail('COMPARISON_PROJECTION_REQUEST',422).
 END.
 ASSIGN quantityValue=NumberValue('qt_alocada') shippedValue=NumberValue('qt_confirm_emb')
  costValue=NumberValue('vl_custo_prev') expenseValue=NumberValue('vl_desp_prev')
  unitValue=NumberValue('vl_unit_prev') withoutValue=NumberValue('vl_desp_prev_sem_distr_custo')
  percentValue=NumberValue('perc_fixo_container')
  totalValue=IF costValue=? OR expenseValue=? THEN ? ELSE costValue + expenseValue
  withoutTotal=IF costValue=? OR withoutValue=? THEN ? ELSE costValue + withoutValue
  fixedExpense=IF costValue=? OR percentValue=? THEN ? ELSE ROUND(costValue * percentValue / 100,8)
  fixedTotal=IF costValue=? OR percentValue=? THEN ? ELSE costValue * (1 + (percentValue / 100)).
 /* The exact source DERIVED v2 proves these NULL/zero cases; physical scale
    equivalence is a separate, still-held gate. Never turn SQL NULL into zero. */
 IF unitValue=0 AND totalValue<>? THEN RUN Fail('COMPARISON_ZERO_DIVISOR',422).
 /* Physical SQLDescribeCol: BRL ratio NUMERIC(25,8), USD(29,8),
    both output units scale8. This is expression typing, not UI rounding.
    Fixed totals keep their full operands (physical scales10/13). */
 ratioValue=IF totalValue=? OR unitValue=? THEN ? ELSE ROUND(totalValue / unitValue,8).
 IF ratioValue=0 AND (withoutTotal<>? OR fixedTotal<>?) THEN RUN Fail('COMPARISON_ZERO_DIVISOR',422).
 ASSIGN withoutUnit=IF ratioValue=? OR withoutTotal=? THEN ? ELSE ROUND(withoutTotal / ratioValue,8)
  fixedUnit=IF ratioValue=? OR fixedTotal=? THEN ? ELSE ROUND(fixedTotal / ratioValue,8).
 rowValue=NEW JsonObject().
 RUN AddNumber('qt_alocada',quantityValue). RUN AddNumber('qt_confirm_emb',shippedValue).
 RUN AddNumber('vl_custo_prev',costValue). RUN AddNumber('vl_desp_prev',expenseValue).
 RUN AddNumber('vl_tot_prev',totalValue). RUN AddNumber('vl_unit_prev',unitValue).
 RUN AddNumber('vl_desp_prev_sem_distr_custo',withoutValue). RUN AddNumber('vl_tot_sem_distr_custo',withoutTotal).
 RUN AddNumber('vl_unit_sem_distr_custo',withoutUnit). RUN AddNumber('vl_desp_prev_perc_fixo',fixedExpense).
 RUN AddNumber('vl_tot_perc_fixo',fixedTotal). RUN AddNumber('vl_unit_perc_fixo',fixedUnit).
 poOutput=NEW JsonObject(). poOutput:Add('success',TRUE). poOutput:Add('data',rowValue).
 CATCH err AS Progress.Lang.Error:
  codeValue=err:GetMessage(1).
  IF codeValue<>'COMPARISON_PROJECTION_REQUEST' AND codeValue<>'COMPARISON_ZERO_DIVISOR' THEN codeValue='COMPARISON_PROJECTION_CONFIGURATION'.
  errorValue=NEW JsonObject(). errorValue:Add('code',codeValue). errorValue:Add('status',IF codeValue='COMPARISON_PROJECTION_REQUEST' OR codeValue='COMPARISON_ZERO_DIVISOR' THEN 422 ELSE 503).
  poOutput=NEW JsonObject(). poOutput:Add('success',FALSE). poOutput:Add('error',errorValue).
 END CATCH.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER errorCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 UNDO,THROW NEW Progress.Lang.AppError(errorCode,statusValue).
END PROCEDURE.
