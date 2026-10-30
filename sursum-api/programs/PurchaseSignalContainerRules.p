/* Pure rule 5 from bl_sinaliz/index.php:7911-7939. Caller owns clock/config. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piDays AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pdToday AS DATE NO-UNDO.
DEFINE OUTPUT PARAMETER plMatches AS LOGICAL NO-UNDO.
DEFINE VARIABLE predicted AS DATE NO-UNDO.
IF NOT VALID-HANDLE(phContainer) OR piDays=? OR pdToday=? THEN
 UNDO, THROW NEW Progress.Lang.AppError('Signal configuration required',1).
IF NOT phContainer:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError('Container required',1).
plMatches=FALSE.
IF phContainer:BUFFER-FIELD('situacao'):BUFFER-VALUE<>1 OR phContainer:BUFFER-FIELD('situacao'):BUFFER-VALUE=? THEN RETURN.
IF phContainer:BUFFER-FIELD('dt_real_embarque'):BUFFER-VALUE<>? THEN RETURN.
predicted=phContainer:BUFFER-FIELD('dt_prev_embarque'):BUFFER-VALUE.
IF predicted=? THEN RETURN.
/* Inclusive future window. Do not turn overdue shipments into this signal. */
plMatches=predicted>=pdToday AND predicted<=pdToday + piDays.
