/* Legacy inner joins only. No amount, eligibility formula or business mutation. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{sursum-api/includes/CostDistributionEligibleTable.i}
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phEmitters AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piMaxRows AS INTEGER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piRowsRead AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttCostDistributionEligible.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE stateValue AS INTEGER NO-UNDO.
DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
DEFINE VARIABLE labelsPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE labelsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
FUNCTION NumberKey RETURNS CHARACTER(checkedValue AS INTEGER):
 RETURN TRIM(STRING(checkedValue,'->>>>>>>>>9')).
END FUNCTION.
FUNCTION FindJoined RETURNS LOGICAL(bufferValue AS HANDLE,keyName AS CHARACTER,keyValue AS INTEGER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF keyValue=? THEN RETURN FALSE.
 RUN Budget.
 foundValue=bufferValue:FIND-FIRST('WHERE ' + bufferValue:NAME + '.' + keyName + '=' + NumberKey(keyValue),NO-LOCK) NO-ERROR.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 END.
 RETURN foundValue.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phAllocations) OR NOT VALID-HANDLE(phContainers) OR NOT VALID-HANDLE(phPurchaseItems) OR NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phEmitters) OR piStarted=? OR piMaxRows=? OR piMaxRows<1 OR piMaxRows>50000 OR piRowsRead=? OR piRowsRead<0 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 RUN Shape(phAllocations,'item_container_id:INTEGER,item_proc_compra_id:INTEGER,container_id:INTEGER').
 RUN Shape(phContainers,'nr-container:INTEGER,situacao:INTEGER,cod-emit-forn:INTEGER').
 RUN Shape(phPurchaseItems,'item_proc_compra_id:INTEGER,proc_compra_id:INTEGER,descricao:CHARACTER,codigo_erp:CHARACTER').
 RUN Shape(phOrders,'proc_compra_id:INTEGER,cod_proc_fornec:CHARACTER,fornecedor_id:INTEGER').
 RUN Shape(phEmitters,'cod-emitente:INTEGER,nome-abrev:CHARACTER').
 labelsPath=SEARCH('sursum-api/programs/ContainersVersionHistoryLabels.r').
 IF labelsPath=? THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 RUN Clock.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  CREATE QUERY q. q:SET-BUFFERS(phAllocations).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phAllocations:NAME + ' NO-LOCK') THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN Budget.
   idValue=phAllocations:BUFFER-FIELD('container_id'):BUFFER-VALUE.
   IF FindJoined(phContainers,'nr-container',idValue) THEN DO:
    stateValue=phContainers:BUFFER-FIELD('situacao'):BUFFER-VALUE.
    /* SQL WHERE status<>3 excludes NULL; ABL unknown has different ordering. */
    IF stateValue<>? AND stateValue<>3 THEN DO:
     idValue=phAllocations:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE.
     IF FindJoined(phPurchaseItems,'item_proc_compra_id',idValue) THEN DO:
      idValue=phPurchaseItems:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
      IF FindJoined(phOrders,'proc_compra_id',idValue) THEN DO:
       CREATE ttCostDistributionEligible.
       RUN CopyField(phPurchaseItems,'proc_compra_id','pedido_imp').
       RUN CopyField(phOrders,'cod_proc_fornec','processo_fornec').
       RUN CopyField(phOrders,'fornecedor_id','fornec_pi').
       RUN CopyField(phPurchaseItems,'item_proc_compra_id','item_pedido').
       RUN CopyField(phContainers,'nr-container','container').
       RUN CopyField(phContainers,'cod-emit-forn','fornec').
       RUN CopyField(phAllocations,'item_container_id','item_container').
       RUN CopyField(phPurchaseItems,'descricao','descricao').
       RUN CopyField(phPurchaseItems,'codigo_erp','codigo_erp').
       IF ttCostDistributionEligible.item_container=? THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_IDENTITY',1).
       /* Both labels share the proven emitente lookup and the same global budget. */
       RUN VALUE(labelsPath)(?,?,phEmitters,?,'emitente',ttCostDistributionEligible.fornec_pi,piStarted,INPUT-OUTPUT piRowsRead,OUTPUT labelsValue).
       ttCostDistributionEligible.fornec_pi_nome_abrev_atual=IF labelsValue:IsNull('emitente_nome_abrev_atual') THEN ? ELSE labelsValue:GetCharacter('emitente_nome_abrev_atual'). DELETE OBJECT labelsValue.
       RUN WithinBudget.
       RUN VALUE(labelsPath)(?,?,phEmitters,?,'emitente',ttCostDistributionEligible.fornec,piStarted,INPUT-OUTPUT piRowsRead,OUTPUT labelsValue).
       ttCostDistributionEligible.fornec_nome_abrev_atual=IF labelsValue:IsNull('emitente_nome_abrev_atual') THEN ? ELSE labelsValue:GetCharacter('emitente_nome_abrev_atual'). DELETE OBJECT labelsValue.
       RUN WithinBudget.
       RELEASE ttCostDistributionEligible.
      END.
     END.
    END.
   END.
   q:GET-NEXT(NO-LOCK).
  END.
  RUN Clock. complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_TIMEOUT',1).
 CATCH e AS Progress.Lang.Error:
  EMPTY TEMP-TABLE ttCostDistributionEligible. UNDO, THROW e.
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
  IF VALID-HANDLE(phAllocations) THEN phAllocations:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phContainers) THEN phContainers:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phPurchaseItems) THEN phPurchaseItems:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phOrders) THEN phOrders:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phEmitters) THEN phEmitters:BUFFER-RELEASE() NO-ERROR.
  IF VALID-OBJECT(labelsValue) THEN DELETE OBJECT labelsValue.
 END FINALLY.
END.
PROCEDURE Shape:
 DEFINE INPUT PARAMETER sourceBuffer AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER definitions AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
 DO n=1 TO NUM-ENTRIES(definitions):
  fieldValue=sourceBuffer:BUFFER-FIELD(ENTRY(1,ENTRY(n,definitions),':')).
  IF fieldValue:DATA-TYPE<>ENTRY(2,ENTRY(n,definitions),':') OR fieldValue:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 END.
END PROCEDURE.
PROCEDURE CopyField:
 DEFINE INPUT PARAMETER fromBuffer AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER fromName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER toName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fromField AS HANDLE NO-UNDO. DEFINE VARIABLE toField AS HANDLE NO-UNDO.
 DEFINE VARIABLE targetBuffer AS HANDLE NO-UNDO.
 targetBuffer=BUFFER ttCostDistributionEligible:HANDLE. fromField=fromBuffer:BUFFER-FIELD(fromName). toField=targetBuffer:BUFFER-FIELD(toName).
 IF fromField:DATA-TYPE<>toField:DATA-TYPE OR fromField:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 toField:BUFFER-VALUE=fromField:BUFFER-VALUE.
END PROCEDURE.
PROCEDURE Clock:
 IF ETIME - piStarted>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_TIMEOUT',1).
END PROCEDURE.
PROCEDURE WithinBudget:
 RUN Clock. IF piRowsRead>piMaxRows THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LIMIT',1).
END PROCEDURE.
PROCEDURE Budget:
 RUN Clock. IF piRowsRead>=piMaxRows THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LIMIT',1).
 piRowsRead=piRowsRead + 1.
END PROCEDURE.
