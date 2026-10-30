/* Participante reutilizavel: nenhuma formula de custo ou commit proprio. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainer AS HANDLE NO-UNDO.
DEFINE OUTPUT PARAMETER poChanges AS JsonArray NO-UNDO.
DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE beforeRow AS JsonObject NO-UNDO.
DEFINE VARIABLE afterRow AS JsonObject NO-UNDO.
DEFINE VARIABLE eventRow AS JsonObject NO-UNDO.
DEFINE VARIABLE id AS INTEGER NO-UNDO.
DEFINE VARIABLE previousId AS INTEGER NO-UNDO.
FUNCTION Snapshot RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 o=NEW JsonObject(). o:Add('container_id',INTEGER(b:BUFFER-FIELD('nr-container'):BUFFER-VALUE)).
 o:Add('situacao',INTEGER(b:BUFFER-FIELD('situacao'):BUFFER-VALUE)).
 o:Add('ordem_busca_dolar_compra',STRING(b:BUFFER-FIELD('ordem_busca_dolar_compra'):BUFFER-VALUE)).
 IF b:BUFFER-FIELD('log_versao_custo_desatualizada'):BUFFER-VALUE=? THEN o:AddNull('log_versao_custo_desatualizada').
 ELSE o:Add('log_versao_custo_desatualizada',LOGICAL(b:BUFFER-FIELD('log_versao_custo_desatualizada'):BUFFER-VALUE)).
 IF b:BUFFER-FIELD('dt_hr_ult_alt_versao_custo'):BUFFER-VALUE=? THEN o:AddNull('dt_hr_ult_alt_versao_custo').
 ELSE o:Add('dt_hr_ult_alt_versao_custo',ISO-DATE(DATETIME(b:BUFFER-FIELD('dt_hr_ult_alt_versao_custo'):BUFFER-VALUE))).
 RETURN o.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT TRANSACTION THEN UNDO,THROW NEW Progress.Lang.AppError('Invalidacao exige transacao do chamador',0).
 CREATE BUFFER b FOR TABLE phContainer. CREATE QUERY q. q:SET-BUFFERS(b).
 /* Igualdade textual EXATA do legado, nao LOOKUP em lista. */
 IF NOT q:QUERY-PREPARE('FOR EACH ' + b:NAME + ' WHERE ' + b:NAME + '.situacao = 1 AND ' + b:NAME + '.ordem_busca_dolar_compra = "1" EXCLUSIVE-LOCK BY ' + b:NAME + '.nr-container')
  THEN UNDO,THROW NEW Progress.Lang.AppError('Consulta de invalidacao indisponivel',0).
 q:QUERY-OPEN(). q:GET-FIRST(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
 poChanges=NEW JsonArray().
 DO WHILE NOT q:QUERY-OFF-END:
  IF b:LOCKED OR ERROR-STATUS:ERROR OR NOT b:AVAILABLE THEN UNDO,THROW NEW Progress.Lang.AppError('Container em uso',0).
  /* A igualdade CHARACTER do ABL ignora padding; o contrato exige valor exato. */
  IF LENGTH(STRING(b:BUFFER-FIELD('ordem_busca_dolar_compra'):BUFFER-VALUE),'RAW')<>1 THEN DO:
   q:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR. NEXT.
  END.
  id=INTEGER(b:BUFFER-FIELD('nr-container'):BUFFER-VALUE).
  IF id=? OR id<=0 OR id=previousId THEN UNDO,THROW NEW Progress.Lang.AppError('Identidade de container inconsistente',0).
  previousId=id. beforeRow=Snapshot().
  ASSIGN b:BUFFER-FIELD('log_versao_custo_desatualizada'):BUFFER-VALUE=TRUE
         b:BUFFER-FIELD('dt_hr_ult_alt_versao_custo'):BUFFER-VALUE=NOW.
  IF NOT b:BUFFER-VALIDATE() THEN UNDO,THROW NEW Progress.Lang.AppError('Invalidacao recusada',0).
  afterRow=Snapshot(). eventRow=NEW JsonObject().
  eventRow:Add('resource','containers'). eventRow:Add('operation','update'). eventRow:Add('recordId',id).
  eventRow:Add('before',beforeRow). eventRow:Add('after',afterRow). poChanges:Add(eventRow).
  q:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
 END.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(b) THEN DO: b:BUFFER-RELEASE() NO-ERROR. DELETE OBJECT b NO-ERROR. END.
 END FINALLY.
END.
