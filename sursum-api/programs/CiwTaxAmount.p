/* Common fiscal arithmetic. Collectors decide product/component bases and rates;
   writers decide rounding. No database, currency assumption or persistence. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER pdProductBase AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER pdExpenseBase AS DECIMAL NO-UNDO.
DEFINE INPUT PARAMETER pdPercentage AS DECIMAL NO-UNDO.
DEFINE OUTPUT PARAMETER pdAmount AS DECIMAL DECIMALS 10 NO-UNDO.
IF pdProductBase=? OR pdExpenseBase=? OR pdPercentage=? THEN UNDO, THROW NEW Progress.Lang.AppError('Base ou percentual fiscal indefinido.',1).
pdAmount=(pdProductBase + pdExpenseBase) * pdPercentage / 100.
