/* Only the proven global INNER JOIN projection; no business formula. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
{sursum-api/includes/SampleContainerItemsTable.i}
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piMaxRows AS INTEGER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piRowsRead AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttSampleContainerItems.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE stateValue AS INTEGER NO-UNDO.
DEFINE VARIABLE sampleState AS INTEGER NO-UNDO.
DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
FUNCTION FindJoined RETURNS LOGICAL(bufferValue AS HANDLE,keyName AS CHARACTER,keyValue AS INTEGER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF keyValue=? THEN RETURN FALSE.
 RUN Budget.
 foundValue=bufferValue:FIND-FIRST('WHERE ' + bufferValue:NAME + '.' + keyName + '=' + TRIM(STRING(keyValue,'->>>>>>>>>9')),NO-LOCK) NO-ERROR.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_CONFIGURATION',1).
 END.
 RETURN foundValue.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phAllocations) OR NOT VALID-HANDLE(phContainers) OR NOT VALID-HANDLE(phPurchaseItems) OR piStarted=? OR piMaxRows=? OR piMaxRows<1 OR piMaxRows>50000 OR piRowsRead=? OR piRowsRead<0 THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_CONFIGURATION',1).
 RUN Shape(phAllocations,'item_container_id:INTEGER,item_proc_compra_id:INTEGER,container_id:INTEGER').
 RUN Shape(phContainers,'nr-container:INTEGER,situacao:INTEGER,situacao_container_id:INTEGER').
 RUN Shape(phPurchaseItems,'item_proc_compra_id:INTEGER,descricao:CHARACTER,codigo_erp:CHARACTER').
 RUN Clock.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  CREATE QUERY q. q:SET-BUFFERS(phAllocations).
  IF NOT q:QUERY-PREPARE('FOR EACH ' + phAllocations:NAME + ' NO-LOCK') THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_CONFIGURATION',1).
  q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   RUN Budget.
   idValue=phAllocations:BUFFER-FIELD('container_id'):BUFFER-VALUE.
   IF FindJoined(phContainers,'nr-container',idValue) THEN DO:
    ASSIGN stateValue=phContainers:BUFFER-FIELD('situacao'):BUFFER-VALUE sampleState=phContainers:BUFFER-FIELD('situacao_container_id'):BUFFER-VALUE.
    /* SQL requires BOTH states=3; unknown must not pass ABL comparisons. */
    IF stateValue<>? AND sampleState<>? AND stateValue=3 AND sampleState=3 THEN DO:
     idValue=phAllocations:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE.
     IF FindJoined(phPurchaseItems,'item_proc_compra_id',idValue) THEN DO:
      CREATE ttSampleContainerItems.
      ASSIGN ttSampleContainerItems.item_container_id=phAllocations:BUFFER-FIELD('item_container_id'):BUFFER-VALUE
             ttSampleContainerItems.container_id=phAllocations:BUFFER-FIELD('container_id'):BUFFER-VALUE
             ttSampleContainerItems.codigo_erp=phPurchaseItems:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE
             ttSampleContainerItems.descricao=phPurchaseItems:BUFFER-FIELD('descricao'):BUFFER-VALUE.
      IF ttSampleContainerItems.item_container_id=? THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_IDENTITY',1).
      RELEASE ttSampleContainerItems.
     END.
    END.
   END.
   q:GET-NEXT(NO-LOCK).
  END.
  RUN Clock. complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_TIMEOUT',1).
 CATCH e AS Progress.Lang.Error:
  EMPTY TEMP-TABLE ttSampleContainerItems. UNDO, THROW e.
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
  IF VALID-HANDLE(phAllocations) THEN phAllocations:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phContainers) THEN phContainers:BUFFER-RELEASE() NO-ERROR.
  IF VALID-HANDLE(phPurchaseItems) THEN phPurchaseItems:BUFFER-RELEASE() NO-ERROR.
 END FINALLY.
END.
PROCEDURE Shape:
 DEFINE INPUT PARAMETER sourceBuffer AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER definitions AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO. DEFINE VARIABLE fieldValue AS HANDLE NO-UNDO.
 DO n=1 TO NUM-ENTRIES(definitions):
  fieldValue=sourceBuffer:BUFFER-FIELD(ENTRY(1,ENTRY(n,definitions),':')).
  IF fieldValue:DATA-TYPE<>ENTRY(2,ENTRY(n,definitions),':') OR fieldValue:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_CONFIGURATION',1).
 END.
END PROCEDURE.
PROCEDURE Clock:
 IF ETIME - piStarted>10000 THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_TIMEOUT',1).
END PROCEDURE.
PROCEDURE Budget:
 RUN Clock. IF piRowsRead>=piMaxRows THEN UNDO, THROW NEW Progress.Lang.AppError('SAMPLE_CONTAINER_ITEMS_LIMIT',1).
 piRowsRead=piRowsRead + 1.
END PROCEDURE.
