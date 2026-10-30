/* Reusable evaluation only. Fixed caller supplies a row, thresholds and clock.
   No query, transaction, cache, fiscal/financial formula or HTTP input. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER pcKind AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER phRow AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piDays AS INTEGER EXTENT 4 NO-UNDO.
DEFINE INPUT PARAMETER pdToday AS DATE NO-UNDO.
DEFINE INPUT PARAMETER plHasPayment AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER poMatches AS JsonArray NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE sentDate AS DATE NO-UNDO.
DEFINE VARIABLE receivedDate AS DATE NO-UNDO.
DEFINE VARIABLE approvedDate AS DATE NO-UNDO.
DEFINE VARIABLE finishedDate AS DATE NO-UNDO.
DEFINE VARIABLE predictedDate AS DATE NO-UNDO.
DEFINE VARIABLE approvalRequired AS LOGICAL NO-UNDO.
PROCEDURE Evaluate:
 DEFINE INPUT PARAMETER signalId AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER baseDate AS DATE NO-UNDO.
 DEFINE INPUT PARAMETER offsetDays AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER strictGreater AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE dueDate AS DATE NO-UNDO.
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 IF baseDate=? THEN RETURN.
 dueDate=baseDate + offsetDays.
 IF (strictGreater AND pdToday>dueDate) OR (NOT strictGreater AND pdToday>=dueDate) THEN DO:
  rowValue=NEW JsonObject(). rowValue:Add('sinaliz_imp_id',signalId).
  rowValue:Add('nome_alerta',labelValue). rowValue:Add('data_base',ISO-DATE(baseDate)). rowValue:Add('data_alerta',ISO-DATE(dueDate)).
  poMatches:Add(rowValue).
 END.
END PROCEDURE.
IF NOT VALID-HANDLE(phRow) THEN UNDO, THROW NEW Progress.Lang.AppError('Fixed signal row required',1).
IF NOT phRow:AVAILABLE OR pdToday=? OR LOOKUP(pcKind,'processo,item')=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Signal context unavailable',1).
DO n=1 TO 4:
 IF piDays[n]=? THEN UNDO, THROW NEW Progress.Lang.AppError('Configured signal days required',1).
END.
poMatches=NEW JsonArray().
IF pcKind='processo' THEN DO:
 IF plHasPayment=? THEN UNDO, THROW NEW Progress.Lang.AppError('Payment membership required',1).
 IF NOT plHasPayment THEN RUN Evaluate(4,DATE(phRow:BUFFER-FIELD('dt_registro'):BUFFER-VALUE),piDays[4],TRUE,'Adiantamento').
 RETURN.
END.
ASSIGN sentDate=phRow:BUFFER-FIELD('dt_real_envio_desenhos'):BUFFER-VALUE
 receivedDate=phRow:BUFFER-FIELD('dt_real_recbto_so_ld'):BUFFER-VALUE
 approvedDate=phRow:BUFFER-FIELD('dt_real_aprov_so_ld'):BUFFER-VALUE
 finishedDate=phRow:BUFFER-FIELD('dt_termino_producao'):BUFFER-VALUE
 predictedDate=phRow:BUFFER-FIELD('dt_prev_termino_producao'):BUFFER-VALUE
 approvalRequired=phRow:BUFFER-FIELD('log_aprov_so_ld'):BUFFER-VALUE.
IF approvalRequired=TRUE AND receivedDate=? THEN RUN Evaluate(1,sentDate,piDays[1],FALSE,'Recebimento SO/LD').
IF approvalRequired=TRUE AND approvedDate=? THEN RUN Evaluate(2,receivedDate,piDays[2],FALSE,'Aprovação SO/LD').
/* The received-date condition is present in the PHP and must not be dropped. */
IF finishedDate=? AND receivedDate<>? THEN RUN Evaluate(3,predictedDate,0 - piDays[3],FALSE,'Término de produção').
