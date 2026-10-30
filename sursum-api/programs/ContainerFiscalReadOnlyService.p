/* Projections of persisted fiscal memories. Never invokes a fiscal/cost writer. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCalcs AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phExpenses AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttCalc NO-UNDO
 FIELD calc_imp_container_id AS INTEGER FIELD container_id AS INTEGER FIELD dt_hr_calculo AS CHARACTER
 FIELD data_calculo AS DATE FIELD usuario_id AS INTEGER FIELD memoria_calculo AS INTEGER FIELD desc_memoria_calc AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE calc_imp_container_id.
DEFINE TEMP-TABLE ttExpense NO-UNDO
 FIELD despesa_container_id AS INTEGER FIELD container_id AS INTEGER FIELD calc_imp_container_id AS INTEGER FIELD memoria_calculo AS CHARACTER FIELD link_calculo_id AS INTEGER
 INDEX pk IS PRIMARY UNIQUE despesa_container_id.
DEFINE VARIABLE cid AS INTEGER NO-UNDO. DEFINE VARIABLE rid AS INTEGER NO-UNDO. DEFINE VARIABLE sourceId AS INTEGER NO-UNDO.
DEFINE VARIABLE scanned AS INTEGER NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE finished AS LOGICAL NO-UNDO. DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE resourceValue AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE keyName AS CHARACTER NO-UNDO. DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'CONTAINER_FISCAL_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE hSource AS HANDLE NO-UNDO. DEFINE VARIABLE hRead AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO. DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO. DEFINE VARIABLE keyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE errorValue AS JsonObject NO-UNDO. DEFINE VARIABLE keyText AS LONGCHAR NO-UNDO. DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE dateTimeValue AS DATETIME NO-UNDO. DEFINE VARIABLE establishment AS CHARACTER NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(c,1).
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phContainers) OR NOT VALID-HANDLE(phCalcs) OR NOT VALID-HANDLE(phExpenses) THEN RUN Fail('CONTAINER_FISCAL_CONFIGURATION',503).
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(code,422).
 cid=PurchaseJsonId(poRequest,'container_id').
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING OR NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN RUN Fail(code,422).
 ASSIGN op=poRequest:GetCharacter('operation') resourceValue=poRequest:GetCharacter('resource').
 IF LOOKUP(op,'read,get')=0 THEN RUN Fail('CONTAINER_FISCAL_READ_ONLY',405).
 CASE resourceValue:
  WHEN 'container_calculos_impostos_med' THEN ASSIGN keyName='calc_imp_container_id' hSource=phCalcs hRead=BUFFER ttCalc:HANDLE.
  WHEN 'container_despesa_memoria_med' THEN ASSIGN keyName='despesa_container_id' hSource=phExpenses hRead=BUFFER ttExpense:HANDLE.
  OTHERWISE RUN Fail(code,422).
 END CASE.
 names=poRequest:GetNames(). DO k=1 TO EXTENT(names):
  IF LOOKUP(names[k],IF op='get' THEN 'operation,resource,container_id,id,' + keyName ELSE 'operation,resource,container_id,skip,take,sort,filter,' + keyName)=0 THEN RUN Fail(code,422).
 END.
 rid=PurchaseJsonId(poRequest,keyName).
 IF op='get' AND PurchaseJsonId(poRequest,'id')<>rid THEN RUN Fail(code,422).
 foundValue=phContainers:FIND-FIRST('WHERE nr-container=' + N(cid),NO-LOCK,NO-WAIT) NO-ERROR.
 DO k=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(k)<>565 THEN RUN Fail('CONTAINER_FISCAL_UNAVAILABLE',503). END.
 IF NOT foundValue THEN RUN Fail('CONTAINER_FISCAL_PARENT',404).
 establishment=phContainers:BUFFER-FIELD('cod-estabel'):BUFFER-VALUE.
 IF establishment=? OR NOT establishment BEGINS '5' THEN RUN Fail('CONTAINER_FISCAL_PARENT',404).
 ASSIGN code='CONTAINER_FISCAL_UNAVAILABLE' statusCode=503 started=ETIME.
 CREATE QUERY q. q:SET-BUFFERS(hSource).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + hSource:NAME + ' WHERE container_id=' + N(cid) + ' AND ' + keyName + '=' + N(rid) + ' NO-LOCK') THEN RUN Fail(code,503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  scanned=scanned + 1. IF scanned>50000 OR ETIME - started>10000 THEN RUN Fail('CONTAINER_FISCAL_LIMIT',503).
  sourceId=hSource:BUFFER-FIELD(keyName):BUFFER-VALUE.
  IF sourceId=? OR sourceId<1 THEN RUN Fail('CONTAINER_FISCAL_IDENTITY',409).
  IF resourceValue='container_calculos_impostos_med' THEN DO:
   IF CAN-FIND(FIRST ttCalc WHERE ttCalc.calc_imp_container_id=sourceId) THEN RUN Fail('CONTAINER_FISCAL_IDENTITY',409).
   CREATE ttCalc. ASSIGN ttCalc.calc_imp_container_id=sourceId ttCalc.container_id=cid
    ttCalc.usuario_id=hSource:BUFFER-FIELD('usuario_id'):BUFFER-VALUE
    ttCalc.memoria_calculo=hSource:BUFFER-FIELD('memoria_calculo'):BUFFER-VALUE
    ttCalc.desc_memoria_calc=hSource:BUFFER-FIELD('desc_memoria_calc'):BUFFER-VALUE
    dateTimeValue=hSource:BUFFER-FIELD('dt_hr_calculo'):BUFFER-VALUE
    ttCalc.dt_hr_calculo=IF dateTimeValue=? THEN ? ELSE ISO-DATE(dateTimeValue)
    ttCalc.data_calculo=IF dateTimeValue=? THEN ? ELSE DATE(dateTimeValue).
  END.
  ELSE DO:
   IF CAN-FIND(FIRST ttExpense WHERE ttExpense.despesa_container_id=sourceId) THEN RUN Fail('CONTAINER_FISCAL_IDENTITY',409).
   CREATE ttExpense. ASSIGN ttExpense.despesa_container_id=sourceId ttExpense.container_id=cid
    ttExpense.calc_imp_container_id=hSource:BUFFER-FIELD('calc_imp_container_id'):BUFFER-VALUE
    ttExpense.memoria_calculo=hSource:BUFFER-FIELD('memoria_calculo'):BUFFER-VALUE
    /* PHP <> '' treats whitespace as a present memory; do not TRIM or use ABL blank equality. */
    ttExpense.link_calculo_id=IF ttExpense.memoria_calculo<>? AND LENGTH(ttExpense.memoria_calculo)>0 THEN ? ELSE IF ttExpense.calc_imp_container_id<>? AND ttExpense.calc_imp_container_id>0 THEN ttExpense.calc_imp_container_id ELSE ?.
  END.
  q:GET-NEXT(NO-LOCK).
 END.
 finished=TRUE.
 END.
 IF NOT finished THEN RUN Fail('CONTAINER_FISCAL_LIMIT',503).
 IF scanned=0 THEN RUN Fail('CONTAINER_FISCAL_RECORD',404).
 requestCopy=CAST(poRequest:Clone(),JsonObject). requestCopy:Remove('resource'). requestCopy:Remove('container_id').
 requestCopy:Remove(keyName).
 IF op='get' THEN DO:
  keyValue=NEW JsonObject(). keyValue:Add(keyName,rid). keyValue:Write(keyText,FALSE). requestCopy:Set('id',STRING(keyText)).
 END.
 pathValue=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF pathValue=? THEN RUN Fail('CONTAINER_FISCAL_CONFIGURATION',503).
 RUN VALUE(pathValue)(hRead,resourceValue,N(cid),requestCopy,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject(). errorValue:Add('code',code). errorValue:Add('status',statusCode).
  errorValue:Add('message','Consulta fiscal de container invalida ou indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END. END FINALLY.
END.
