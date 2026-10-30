/* Fixed current labels; never replace persisted values. One caller-owned budget. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmitters AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcKind AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER piId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piRows AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poLabels AS JsonObject NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE target AS HANDLE NO-UNDO.
DEFINE VARIABLE physicalField AS CHARACTER NO-UNDO.
DEFINE VARIABLE publicField AS CHARACTER NO-UNDO.
DEFINE VARIABLE keyField AS CHARACTER NO-UNDO.
DEFINE VARIABLE availableValue AS LOGICAL NO-UNDO.
FUNCTION FindCurrent RETURNS LOGICAL(bufferValue AS HANDLE,conditionValue AS CHARACTER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 foundValue=bufferValue:FIND-FIRST('WHERE ' + conditionValue,NO-LOCK) NO-ERROR.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError('VERSION_HISTORY_LABEL_READ_FAILED',1).
 END.
 RETURN foundValue.
END FUNCTION.
poLabels=NEW JsonObject().
CASE pcKind:
 WHEN 'item' THEN ASSIGN target=phPurchaseItems physicalField='descricao' publicField='item_descricao_atual' keyField='item_proc_compra_id'.
 WHEN 'item_join' THEN ASSIGN target=phPurchaseItems physicalField='descricao' publicField='item_descricao_atual' keyField='item_proc_compra_id'.
 WHEN 'emitente' THEN ASSIGN target=phEmitters physicalField='nome-abrev' publicField='emitente_nome_abrev_atual' keyField='cod-emitente'.
 WHEN 'despesa' THEN ASSIGN target=phExpenses physicalField='descricao' publicField='despesa_descricao_atual' keyField='despesa_id'.
 WHEN 'motivo' THEN ASSIGN target=phExpenses physicalField='descricao' publicField='motivo_descricao_atual' keyField='motivo_desconto_id'.
 OTHERWISE UNDO, THROW NEW Progress.Lang.AppError('VERSION_HISTORY_LABEL_KIND',1).
END CASE.
poLabels:AddNull(publicField).
IF pcKind='item_join' THEN poLabels:Add('item_join_exists',FALSE).
IF pcKind='item' OR pcKind='item_join' THEN poLabels:AddNull('item_codigo_erp_atual').
DO ON ERROR UNDO, THROW:
 IF piId=? THEN RETURN.
 IF NOT VALID-HANDLE(target) THEN UNDO, THROW NEW Progress.Lang.AppError('VERSION_HISTORY_LABEL_CONFIGURATION',1).
 IF pcKind='item' OR pcKind='item_join' THEN DO:
  IF NOT VALID-HANDLE(phAllocations) THEN UNDO, THROW NEW Progress.Lang.AppError('VERSION_HISTORY_LABEL_CONFIGURATION',1).
  RUN Budget.
  availableValue=FindCurrent(phAllocations,phAllocations:NAME + '.item_container_id=' + TRIM(STRING(piId,'->>>>>>>>>9'))).
  IF NOT availableValue THEN RETURN.
  itemId=phAllocations:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE.
  IF itemId=? THEN RETURN.
 END.
 ELSE itemId=piId.
 RUN Budget.
 availableValue=FindCurrent(target,target:NAME + '.' + keyField + '=' + TRIM(STRING(itemId,'->>>>>>>>>9'))).
 IF availableValue THEN DO:
  IF pcKind='item_join' THEN poLabels:Set('item_join_exists',TRUE).
  IF target:BUFFER-FIELD(physicalField):BUFFER-VALUE<>? THEN poLabels:Set(publicField,STRING(target:BUFFER-FIELD(physicalField):BUFFER-VALUE)).
  IF pcKind='item' OR pcKind='item_join' THEN IF target:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE<>? THEN poLabels:Set('item_codigo_erp_atual',STRING(target:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE)).
 END.
 FINALLY:
  IF VALID-HANDLE(phAllocations) THEN phAllocations:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(target) THEN target:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE Budget:
 IF piRows=? OR piRows<0 OR piRows>50000 OR piStarted=? THEN UNDO, THROW NEW Progress.Lang.AppError('VERSION_HISTORY_LABEL_CONFIGURATION',1).
 IF piRows>=50000 OR ETIME - piStarted>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('VERSION_HISTORY_LABEL_BUDGET',1).
 piRows=piRows + 1.
END PROCEDURE.
