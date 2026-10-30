/* Single read-only collector for contextual and global signals. Business
   evaluation stays in PurchaseSignalRules; reader pagination is outside. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSignals AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pdToday AS DATE NO-UNDO.
DEFINE INPUT PARAMETER piScanBudget AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseSignalsTable.i}
DEFINE OUTPUT PARAMETER TABLE FOR ttSignalRead.
DEFINE OUTPUT PARAMETER piProcess AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piScanned AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SIGNAL'.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SIGNAL_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE signalId AS INTEGER NO-UNDO.
DEFINE VARIABLE days AS INTEGER EXTENT 4 NO-UNDO.
DEFINE VARIABLE titles AS CHARACTER EXTENT 4 NO-UNDO.
DEFINE VARIABLE descriptions AS CHARACTER EXTENT 4 NO-UNDO.
DEFINE VARIABLE matches AS JsonArray NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE copyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE rulePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE hasPayment AS LOGICAL NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE scanned AS INTEGER NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
{sursum-api/includes/PurchaseOrderContext.i}
FUNCTION InternalDate RETURNS DATE(textValue AS CHARACTER):
 RETURN DATE(INTEGER(SUBSTRING(textValue,6,2)),INTEGER(SUBSTRING(textValue,9,2)),INTEGER(SUBSTRING(textValue,1,4))).
END FUNCTION.
PROCEDURE AppendMatches:
 DEFINE INPUT PARAMETER kindValue AS CHARACTER NO-UNDO.
 DO n=1 TO matches:Length:
  rowValue=matches:GetJsonObject(n). signalId=rowValue:GetInteger('sinaliz_imp_id').
  CREATE ttSignalRead.
  ASSIGN ttSignalRead.sinaliz_imp_id=signalId ttSignalRead.proc_compra_id=pid
   ttSignalRead.item_proc_compra_id=IF kindValue='Item' THEN INTEGER(phItems:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE) ELSE 0
   ttSignalRead.tipo_registro=kindValue ttSignalRead.nome_alerta=rowValue:GetCharacter('nome_alerta')
   ttSignalRead.titulo_configurado=titles[signalId] ttSignalRead.descricao_alerta=descriptions[signalId]
   ttSignalRead.dias_alerta=days[signalId] ttSignalRead.data_base=InternalDate(rowValue:GetCharacter('data_base'))
   ttSignalRead.data_alerta=InternalDate(rowValue:GetCharacter('data_alerta')) ttSignalRead.data_consulta=pdToday
   ttSignalRead.cod_proc_fornec=phOrders:BUFFER-FIELD('cod_proc_fornec'):BUFFER-VALUE
   ttSignalRead.fornecedor_id=phOrders:BUFFER-FIELD('fornecedor_id'):BUFFER-VALUE
   ttSignalRead.item_descricao=IF kindValue='Item' THEN STRING(phItems:BUFFER-FIELD('descricao'):BUFFER-VALUE) ELSE ''
   ttSignalRead.codigo_erp=IF kindValue='Item' THEN STRING(phItems:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE) ELSE ''.
 END.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF piScanBudget=? OR piScanBudget<0 OR piScanBudget>50000 OR piStarted=? OR piStarted<0 THEN RUN Fail('PURCHASE_SIGNAL_CONFIGURATION',503,'Private budget required.').
 started=piStarted.
 IF NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phPayments) OR NOT VALID-HANDLE(phSignals) OR pdToday=? THEN RUN Fail('PURCHASE_SIGNAL_CONFIGURATION',503,'Configuracao indisponivel.').
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(code,422,'Requisicao obrigatoria.').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'read,get')=0 THEN RUN Fail('PURCHASE_SIGNAL_READ_ONLY',405,'Somente leitura.').
 ns=poRequest:GetNames(). DO k=1 TO EXTENT(ns):
  IF LOOKUP(ns[k],IF op='get' THEN 'operation,proc_compra_id,id,record_key' ELSE 'operation,proc_compra_id,skip,take,sort,filter')=0 THEN RUN Fail(code,422,'Campo nao permitido.').
 END.
 pid=PurchaseJsonId(poRequest,'proc_compra_id'). RUN OrderContextCheck(NO-LOCK).
 ASSIGN code='PURCHASE_SIGNAL_CONFIGURATION' statusCode=503.
 rulePath=SEARCH('sursum-api/programs/PurchaseSignalRules.r').
 IF rulePath=? THEN RUN Fail(code,503,'Rotina compartilhada indisponivel.').
 DO k=1 TO 4:
  IF NOT Found(phSignals,'sinaliz_imp_id=' + N(k),NO-LOCK) THEN RUN Fail(code,503,'Sinalizador nao cadastrado.').
  days[k]=phSignals:BUFFER-FIELD('qt_dias_alerta'):BUFFER-VALUE.
  IF days[k]=? THEN RUN Fail(code,503,'Dias do sinalizador nao informados.').
  ASSIGN titles[k]=phSignals:BUFFER-FIELD('titulo'):BUFFER-VALUE descriptions[k]=phSignals:BUFFER-FIELD('descricao'):BUFFER-VALUE.
 END.
 IF phOrders:BUFFER-FIELD('cod_situacao'):BUFFER-VALUE=1 THEN DO:
  hasPayment=Found(phPayments,'proc_compra_id=' + N(pid),NO-LOCK).
  RUN VALUE(rulePath)('processo',phOrders,days,pdToday,hasPayment,OUTPUT matches). RUN AppendMatches('Processo').
  CREATE QUERY q. q:SET-BUFFERS(phItems).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phItems:NAME + ' NO-LOCK WHERE proc_compra_id=' + N(pid)) THEN RUN Fail(code,503,'Consulta indisponivel.').
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   scanned=scanned + 1. IF scanned>piScanBudget OR ETIME - started>10000 THEN RUN Fail('PURCHASE_SIGNAL_LIMIT',503,'Limite de consulta atingido.').
   RUN VALUE(rulePath)('item',phItems,days,pdToday,FALSE,OUTPUT matches). RUN AppendMatches('Item').
   q:GET-NEXT(NO-LOCK).
  END.
  q:QUERY-CLOSE(). DELETE OBJECT q. q=?.
 END.
 ASSIGN piProcess=pid piScanned=scanned.
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE).
 CATCH e AS Progress.Lang.Error:
  piScanned=scanned.
  EMPTY TEMP-TABLE ttSignalRead.
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code',code). err:Add('status',statusCode). err:Add('message','Consulta de alertas invalida ou indisponivel.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END.
