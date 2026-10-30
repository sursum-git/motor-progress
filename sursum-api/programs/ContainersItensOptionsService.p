/* Private fixed-buffer options query. Not an allocation authorization. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE buffers AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE fieldsValue AS CHARACTER EXTENT 4 NO-UNDO.
DEFINE VARIABLE typesValue AS CHARACTER EXTENT 4 NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE keyName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseId AS INTEGER NO-UNDO.
DEFINE VARIABLE processId AS INTEGER NO-UNDO.
DEFINE VARIABLE numberValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE allocated AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE balance AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE currentValue AS LOGICAL NO-UNDO.
DEFINE VARIABLE selectionOnly AS LOGICAL NO-UNDO.
DEFINE VARIABLE balancePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE erpCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE descriptionValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE balanceText AS CHARACTER NO-UNDO.
DEFINE VARIABLE labelValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE allocations AS HANDLE NO-UNDO.
DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE failureCode AS CHARACTER NO-UNDO INITIAL "ITENS_OPTIONS_INVALID_REQUEST".
DEFINE VARIABLE statusValue AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
FUNCTION IdText RETURNS CHARACTER(valueId AS INTEGER): RETURN TRIM(STRING(valueId,"->>>>>>>>>9")). END FUNCTION.
FUNCTION NumberField RETURNS DECIMAL(bufferValue AS HANDLE,nameValue AS CHARACTER):
 DEFINE VARIABLE valueNumber AS DECIMAL DECIMALS 10 NO-UNDO.
 valueNumber=bufferValue:BUFFER-FIELD(nameValue):BUFFER-VALUE.
 IF valueNumber=? THEN DO: ASSIGN failureCode="ITENS_OPTIONS_DATA_INVALID" statusValue=422. UNDO, THROW NEW Progress.Lang.AppError("Quantidade ou identificador desconhecido na consulta de itens.",1). END.
 RETURN valueNumber.
END FUNCTION.
FUNCTION TextField RETURNS CHARACTER(bufferValue AS HANDLE,nameValue AS CHARACTER):
 DEFINE VARIABLE valueText AS CHARACTER NO-UNDO.
 valueText=bufferValue:BUFFER-FIELD(nameValue):BUFFER-VALUE.
 IF valueText=? THEN DO: ASSIGN failureCode="ITENS_OPTIONS_DATA_INVALID" statusValue=422. UNDO, THROW NEW Progress.Lang.AppError("Texto desconhecido na consulta de itens.",1). END.
 RETURN valueText.
END FUNCTION.
FUNCTION ReadRow RETURNS LOGICAL(bufferValue AS HANDLE,conditionValue AS CHARACTER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 foundValue=bufferValue:FIND-FIRST("WHERE " + conditionValue,NO-LOCK) NO-ERROR.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN DO: ASSIGN failureCode="ITENS_OPTIONS_CONFIGURATION" statusValue=503. UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa de itens indisponivel.",1). END.
 END.
 RETURN foundValue.
END FUNCTION.
FUNCTION QueryRows RETURNS HANDLE(bufferValue AS HANDLE,conditionValue AS CHARACTER,ordering AS CHARACTER):
 DEFINE VARIABLE queryValue AS HANDLE NO-UNDO.
 CREATE QUERY queryValue. queryValue:SET-BUFFERS(bufferValue).
 IF NOT queryValue:QUERY-PREPARE("FOR EACH " + bufferValue:NAME + " NO-LOCK WHERE " + conditionValue + " " + ordering) THEN DO: DELETE OBJECT queryValue. ASSIGN failureCode="ITENS_OPTIONS_CONFIGURATION" statusValue=503. UNDO, THROW NEW Progress.Lang.AppError("Consulta fixa de itens invalida.",1). END.
 queryValue:QUERY-OPEN(). queryValue:GET-FIRST(NO-LOCK). RETURN queryValue.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError("Informe contexto da consulta de itens.",1).
 names=poRequest:GetNames().
 DO i=1 TO EXTENT(names): keyName=names[i]. IF keyName<>"operation" AND keyName<>"container_id" AND keyName<>"selection_only" THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao permitido na consulta de itens.",1). END.
 IF NOT poRequest:Has("operation") OR poRequest:GetType("operation")<>JsonDataType:STRING OR NOT poRequest:Has("container_id") OR poRequest:GetType("container_id")<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("Informe read e container_id inteiro positivo.",1).
 keyName=poRequest:GetCharacter("operation"). IF keyName<>"read" THEN UNDO, THROW NEW Progress.Lang.AppError("Consulta de opcoes aceita somente read.",1).
 numberValue=poRequest:GetDecimal("container_id").
 IF numberValue=? OR numberValue<=0 OR numberValue>2147483647 OR numberValue<>TRUNCATE(numberValue,0) THEN UNDO, THROW NEW Progress.Lang.AppError("container_id inteiro positivo int32 obrigatorio.",1).
 cid=INTEGER(numberValue).
 IF poRequest:Has('selection_only') THEN DO: IF poRequest:GetType('selection_only')<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError('Modo privado invalido.',1). selectionOnly=poRequest:GetLogical('selection_only'). END.
 balancePath=SEARCH('sursum-api/programs/ContainersAllocationBalance.r'). IF balancePath=? THEN balancePath=SEARCH('ContainersAllocationBalance.r').
 IF balancePath=? THEN DO: ASSIGN failureCode='ITENS_OPTIONS_CONFIGURATION' statusValue=503. UNDO, THROW NEW Progress.Lang.AppError('Rotina compartilhada de saldo ausente.',1). END.

 ASSIGN failureCode="ITENS_OPTIONS_CONFIGURATION" statusValue=503 buffers[1]=phMaster buffers[2]=phItems buffers[3]=phPurchaseItems buffers[4]=phPurchases
  fieldsValue[1]="nr-container" typesValue[1]="INTEGER"
  fieldsValue[2]="container_id,item_proc_compra_id,qt_alocada" typesValue[2]="INTEGER,INTEGER,DECIMAL"
  fieldsValue[3]="item_proc_compra_id,proc_compra_id,codigo_erp,descricao,qt_comprada" typesValue[3]="INTEGER,INTEGER,CHARACTER,CHARACTER,DECIMAL"
  fieldsValue[4]="proc_compra_id,empresa_id,fornecedor_id" typesValue[4]="INTEGER,INTEGER,INTEGER".
 DO i=1 TO 4:
  IF NOT VALID-HANDLE(buffers[i]) THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer fixo de opcoes indisponivel.",1).
  IF buffers[i]:TYPE<>"BUFFER" THEN UNDO, THROW NEW Progress.Lang.AppError("Buffer fixo de opcoes invalido.",1).
  DO j=1 TO NUM-ENTRIES(fieldsValue[i]):
   fieldHandle=?.
   fieldHandle=buffers[i]:BUFFER-FIELD(ENTRY(j,fieldsValue[i])) NO-ERROR.
   IF NOT VALID-HANDLE(fieldHandle) THEN UNDO, THROW NEW Progress.Lang.AppError("Campo fixo de opcoes ausente.",1).
   IF fieldHandle:DATA-TYPE<>ENTRY(j,typesValue[i]) OR fieldHandle:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo fisico de opcoes invalido.",1).
  END.
 END.
 IF NOT ReadRow(phMaster,phMaster:NAME + ".nr-container=" + IdText(cid)) THEN DO: ASSIGN failureCode="ITENS_OPTIONS_NOT_FOUND" statusValue=404. UNDO, THROW NEW Progress.Lang.AppError("Container nao encontrado.",1). END.
 rows=NEW JsonArray(). q=QueryRows(phPurchaseItems,"TRUE","BY " + phPurchaseItems:NAME + ".item_proc_compra_id").
 DO WHILE NOT q:QUERY-OFF-END:
  ASSIGN purchaseId=INTEGER(NumberField(phPurchaseItems,"item_proc_compra_id")) processId=INTEGER(NumberField(phPurchaseItems,"proc_compra_id")) erpCode=TextField(phPurchaseItems,"codigo_erp").
  IF purchaseId<=0 THEN DO: ASSIGN failureCode="ITENS_OPTIONS_DATA_INVALID" statusValue=422. UNDO, THROW NEW Progress.Lang.AppError("Item de compra com chave invalida.",1). END.
  IF TRIM(erpCode)<>"" AND processId>0 AND ReadRow(phPurchases,phPurchases:NAME + ".proc_compra_id=" + IdText(processId)) THEN DO:
   DO ON ERROR UNDO, THROW:
    RUN VALUE(balancePath)(phPurchaseItems,phItems,purchaseId,cid,FALSE,OUTPUT balance,OUTPUT currentValue).
    CATCH balanceError AS Progress.Lang.Error:
     ASSIGN failureCode='ITENS_OPTIONS_DATA_INVALID' statusValue=422.
     UNDO, THROW balanceError.
    END CATCH.
   END.
   IF (selectionOnly AND balance>0 AND NOT currentValue) OR (NOT selectionOnly AND (balance>0 OR currentValue)) THEN DO:
    IF rows:Length>=5000 THEN DO: ASSIGN failureCode="ITENS_OPTIONS_RESULT_LIMIT" statusValue=422. UNDO, THROW NEW Progress.Lang.AppError("Mais de 5.000 opções de itens; refine o contrato da consulta. Nenhuma lista foi truncada.",1). END.
    balanceText=REPLACE(TRIM(STRING(balance,"->>>>>>>>>>>>>9.99")),".",",").
    IF INDEX(balanceText,"*")>0 THEN DO: ASSIGN failureCode="ITENS_OPTIONS_DATA_INVALID" statusValue=422. UNDO, THROW NEW Progress.Lang.AppError("Saldo excede limite de apresentacao.",1). END.
    descriptionValue=TextField(phPurchaseItems,"descricao").
    labelValue="Pedido " + IdText(processId) + " | " + erpCode + " | " + descriptionValue + " | saldo " + balanceText + " | Empresa " + IdText(INTEGER(NumberField(phPurchases,"empresa_id"))) + " | Fornecedor " + IdText(INTEGER(NumberField(phPurchases,"fornecedor_id"))) + (IF currentValue THEN " | já alocado" ELSE "").
    rowValue=NEW JsonObject(). rowValue:Add("item_proc_compra_id",purchaseId). rowValue:Add("label",labelValue). rowValue:Add("saldo_disponivel_texto",balanceText). rows:Add(rowValue).
   END.
  END.
  q:GET-NEXT(NO-LOCK).
 END.
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("data",rows).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add("success",FALSE). err=NEW JsonObject(). err:Add("code",failureCode). err:Add("message",e:GetMessage(1)). err:Add("status",statusValue). poResponse:Add("error",err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(allocations) THEN DELETE OBJECT allocations.
  IF VALID-HANDLE(q) THEN DELETE OBJECT q.
 END FINALLY.
END.
