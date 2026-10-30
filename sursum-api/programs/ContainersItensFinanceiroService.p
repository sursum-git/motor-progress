/* Private participant of the caller's item transaction. No commit, confirmed
   audit, currency conversion, session state, HTTP or client-selected SQL. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrderPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainerPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poContext AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttItem NO-UNDO FIELD id AS INTEGER FIELD purchaseId AS INTEGER
 FIELD allocated AS DECIMAL DECIMALS 10 FIELD shipped AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttPurchase NO-UNDO FIELD id AS INTEGER FIELD orderId AS INTEGER
 FIELD bought AS DECIMAL DECIMALS 10 FIELD proforma AS DECIMAL DECIMALS 10 FIELD negotiated AS DECIMAL DECIMALS 10
 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttOrder NO-UNDO FIELD id AS INTEGER FIELD supplier AS INTEGER FIELD enabled AS LOGICAL INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttTitle NO-UNDO FIELD scopeName AS CHARACTER FIELD ownerId AS INTEGER FIELD id AS INTEGER
 FIELD usd AS DECIMAL DECIMALS 10 FIELD realValue AS DECIMAL DECIMALS 10 FIELD confirmed AS LOGICAL FIELD eligible AS LOGICAL
 INDEX pk IS UNIQUE PRIMARY scopeName ownerId id.
DEFINE TEMP-TABLE ttHistory NO-UNDO FIELD id AS INTEGER FIELD kind AS INTEGER FIELD supplier AS INTEGER FIELD titleKey AS INTEGER
 FIELD purchaseId AS INTEGER FIELD itemId AS INTEGER FIELD amount AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY id.
{sursum-api/includes/ContainerBufferSibling.i}
DEFINE TEMP-TABLE ttSettledPurchase NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttOrphanGroup NO-UNDO FIELD supplier AS INTEGER FIELD titleKey AS INTEGER FIELD purchaseId AS INTEGER FIELD itemId AS INTEGER
 FIELD amount AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY supplier titleKey purchaseId itemId.
DEFINE TEMP-TABLE ttLedgerId NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttGroup NO-UNDO FIELD supplier AS INTEGER FIELD titleKey AS INTEGER FIELD purchaseId AS INTEGER FIELD itemId AS INTEGER
 FIELD amount AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY supplier titleKey purchaseId itemId.
DEFINE TEMP-TABLE ttPlan NO-UNDO FIELD ordinal AS INTEGER FIELD kind AS INTEGER FIELD supplier AS INTEGER FIELD titleKey AS INTEGER
 FIELD purchaseId AS INTEGER FIELD itemId AS INTEGER FIELD amount AS DECIMAL DECIMALS 10 FIELD historyText AS CHARACTER FIELD actionValue AS INTEGER
 INDEX pk IS UNIQUE PRIMARY ordinal.
DEFINE BUFFER bHistory FOR ttHistory.
DEFINE VARIABLE bh AS HANDLE EXTENT 7 NO-UNDO.
DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
DEFINE VARIABLE changedItemId AS INTEGER NO-UNDO.
DEFINE VARIABLE changedPurchaseId AS INTEGER NO-UNDO.
DEFINE VARIABLE changedOrderId AS INTEGER NO-UNDO.
DEFINE VARIABLE selectedTitleId AS INTEGER NO-UNDO.
DEFINE VARIABLE paymentOperation AS LOGICAL NO-UNDO.
DEFINE VARIABLE purchasePaymentOperation AS LOGICAL NO-UNDO.
DEFINE VARIABLE forecastOperation AS LOGICAL NO-UNDO.
DEFINE VARIABLE purchaseItemOperation AS LOGICAL NO-UNDO.
DEFINE VARIABLE refreshOperation AS LOGICAL NO-UNDO.
DEFINE VARIABLE operationName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE actor AS CHARACTER NO-UNDO.
DEFINE VARIABLE actorData AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeData AS JsonObject NO-UNDO.
DEFINE VARIABLE afterData AS JsonObject NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE paymentRows AS JsonArray NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE eventData AS JsonObject NO-UNDO.
DEFINE VARIABLE warningData AS JsonObject NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE qAux AS HANDLE NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE currentId AS INTEGER NO-UNDO.
DEFINE VARIABLE ownerId AS INTEGER NO-UNDO.
DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
DEFINE VARIABLE planCount AS INTEGER NO-UNDO.
DEFINE VARIABLE newId AS INTEGER NO-UNDO.
DEFINE VARIABLE kindValue AS INTEGER NO-UNDO.
DEFINE VARIABLE titleId AS INTEGER NO-UNDO.
DEFINE VARIABLE supplierId AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseId AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE totalAllocated AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE totalShipped AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE totalProforma AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE itemProforma AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE targetValue AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE balance AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE delta AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE weight AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE totalWeight AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE enabledCount AS INTEGER NO-UNDO.
DEFINE VARIABLE timestampValue AS DATETIME NO-UNDO.
DEFINE VARIABLE textValue AS CHARACTER NO-UNDO.

FUNCTION N RETURNS CHARACTER (v AS INTEGER): RETURN TRIM(STRING(v,"->>>>>>>>>9")). END FUNCTION.
FUNCTION ForecastLedgerSnapshot RETURNS JsonObject () FORWARD.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 UNDO, THROW NEW Progress.Lang.AppError(code + ": " + messageText,1).
END PROCEDURE.
FUNCTION NumberValue RETURNS DECIMAL (o AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL DECIMALS 10 NO-UNDO.
 IF o:GetType(name)<>JsonDataType:NUMBER THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Numero JSON confirmado necessario: " + name).
 v=o:GetDecimal(name). IF v=? THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Numero desconhecido: " + name). RETURN v.
END FUNCTION.
FUNCTION KeyId RETURNS INTEGER (o AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL DECIMALS 10 NO-UNDO. v=NumberValue(o,name).
 IF v<=0 OR v>2147483647 OR v<>TRUNCATE(v,0) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","ID inteiro positivo necessario: " + name).
 RETURN INTEGER(v).
END FUNCTION.
FUNCTION I RETURNS INTEGER (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE v AS INTEGER NO-UNDO.
 IF h:BUFFER-FIELD(name):DATA-TYPE<>"INTEGER" THEN RUN Fail("ITEMS_FINANCE_DATA","Chave fisica nao inteira.").
 v=h:BUFFER-FIELD(name):BUFFER-VALUE. IF v=? THEN RUN Fail("ITEMS_FINANCE_DATA","Chave fisica desconhecida: " + name). RETURN v.
END FUNCTION.
FUNCTION D RETURNS DECIMAL (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE v AS DECIMAL DECIMALS 10 NO-UNDO.
 v=h:BUFFER-FIELD(name):BUFFER-VALUE. IF v=? THEN RUN Fail("ITEMS_FINANCE_DATA","Valor fisico desconhecido: " + name). RETURN v.
END FUNCTION.
FUNCTION Used RETURNS DECIMAL (v AS DECIMAL):
 IF v=? THEN RUN Fail("ITEMS_FINANCE_DATA","Componente financeiro necessario desconhecido."). RETURN v.
END FUNCTION.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE name AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE ok AS LOGICAL NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Objeto JSON interno obrigatorio.").
 names=o:GetNames().
 DO j=1 TO EXTENT(names):
  name=names[j]. ok=FALSE.
  DO k=1 TO NUM-ENTRIES(allowed): IF name=ENTRY(k,allowed) THEN ok=TRUE. END.
  IF NOT ok THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Campo interno nao permitido: " + name).
 END.
END PROCEDURE.
FUNCTION Found RETURNS LOGICAL (h AS HANDLE,conditionText AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE foundRow AS LOGICAL NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 foundRow=h:FIND-FIRST("WHERE " + conditionText,lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail("ITEMS_FINANCE_BUSY","Registro em uso.").
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN RUN Fail("ITEMS_FINANCE_DATA","Falha na leitura fisica; nao equivale a ausencia.").
 END. RETURN foundRow.
END FUNCTION.
FUNCTION Rows RETURNS HANDLE (h AS HANDLE,conditionText AS CHARACTER,ordering AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE queryHandle AS HANDLE NO-UNDO.
 CREATE QUERY queryHandle. queryHandle:SET-BUFFERS(h).
 IF NOT queryHandle:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + conditionText + " " + ordering) THEN DO:
  DELETE OBJECT queryHandle. RUN Fail("ITEMS_FINANCE_CONFIGURATION","Consulta fisica fixa invalida.").
 END.
 queryHandle:QUERY-OPEN(). queryHandle:GET-FIRST(lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED OR ERROR-STATUS:ERROR THEN DO:
  queryHandle:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryHandle. RUN Fail("ITEMS_FINANCE_BUSY","Leitura financeira recusada.").
 END. RETURN queryHandle.
END FUNCTION.
PROCEDURE NextRow:
 DEFINE INPUT PARAMETER queryHandle AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 queryHandle:GET-NEXT(lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail("ITEMS_FINANCE_BUSY","Conjunto financeiro em uso.").
END PROCEDURE.
PROCEDURE CloseQuery:
 DEFINE INPUT-OUTPUT PARAMETER queryHandle AS HANDLE NO-UNDO.
 IF VALID-HANDLE(queryHandle) THEN DO: queryHandle:QUERY-CLOSE() NO-ERROR. DELETE OBJECT queryHandle NO-ERROR. END.
 queryHandle=?.
END PROCEDURE.
PROCEDURE AddPurchaseRef:
 DEFINE INPUT PARAMETER valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE orderValue AS INTEGER NO-UNDO.
 IF valueId<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Item do pedido sem chave positiva.").
 IF CAN-FIND(ttPurchase WHERE ttPurchase.id=valueId) THEN RETURN.
 IF NOT Found(phPurchaseItems,phPurchaseItems:NAME + ".item_proc_compra_id=" + N(valueId),NO-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Item do pedido inexistente.").
 orderValue=I(phPurchaseItems,"proc_compra_id").
 IF orderValue<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Pedido sem chave positiva.").
 CREATE ttPurchase. ASSIGN ttPurchase.id=valueId ttPurchase.orderId=orderValue.
 IF NOT CAN-FIND(ttOrder WHERE ttOrder.id=orderValue) THEN DO: CREATE ttOrder. ttOrder.id=orderValue. END.
END PROCEDURE.
/* Historical type4 may refer to a deleted item. Such rows are ignorable only
   after ALL groups for that missing owner are locked and proven exactly zero.
   Active owner references still use the strict AddPurchaseRef above. */
PROCEDURE RequireSettledOrphan:
 DEFINE INPUT PARAMETER missingId AS INTEGER NO-UNDO.
 DEFINE VARIABLE historyBuffer AS HANDLE NO-UNDO.
 DEFINE VARIABLE historyQuery AS HANDLE NO-UNDO.
 DEFINE VARIABLE supplierValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE titleValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE itemValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE foundRows AS INTEGER NO-UNDO.
 IF missingId<1 THEN RUN Fail('ITEMS_FINANCE_DATA','Item historico sem identidade.').
 IF CAN-FIND(ttSettledPurchase WHERE ttSettledPurchase.id=missingId) THEN RETURN.
 EMPTY TEMP-TABLE ttOrphanGroup.
 RUN ContainerCreateSiblingBuffer(phLedger,'bSettledMissingPurchaseLedger',OUTPUT historyBuffer).
 historyQuery=Rows(historyBuffer,'item_proc_compra_id=' + N(missingId) + ' AND cod_tipo_movto=4','BY cta_corren_fornec_imp_id',EXCLUSIVE-LOCK).
 DO WHILE NOT historyQuery:QUERY-OFF-END:
  ASSIGN foundRows=foundRows + 1 supplierValue=I(historyBuffer,'fornecedor_id') titleValue=I(historyBuffer,'num_id_tit_ap') itemValue=I(historyBuffer,'item_container_id').
  IF supplierValue<1 OR titleValue<1 OR itemValue<0 THEN RUN Fail('ITEMS_FINANCE_DATA','Grupo historico sem proprietario valido.').
  FIND ttOrphanGroup WHERE ttOrphanGroup.supplier=supplierValue AND ttOrphanGroup.titleKey=titleValue AND ttOrphanGroup.purchaseId=missingId AND ttOrphanGroup.itemId=itemValue NO-ERROR.
  IF NOT AVAILABLE ttOrphanGroup THEN DO:
   CREATE ttOrphanGroup. ASSIGN ttOrphanGroup.supplier=supplierValue ttOrphanGroup.titleKey=titleValue ttOrphanGroup.purchaseId=missingId ttOrphanGroup.itemId=itemValue.
  END.
  ttOrphanGroup.amount=ttOrphanGroup.amount + D(historyBuffer,'vl_lancto').
  RUN NextRow(historyQuery,historyBuffer,EXCLUSIVE-LOCK).
 END.
 IF foundRows=0 THEN RUN Fail('ITEMS_FINANCE_DATA','Historico mudou durante prova de quitacao.').
 IF Found(phPurchaseItems,'item_proc_compra_id=' + N(missingId),SHARE-LOCK) THEN RUN Fail('ITEMS_FINANCE_DATA','Proprietario reapareceu durante prova de quitacao.').
 FOR EACH ttOrphanGroup:
  IF ttOrphanGroup.amount<>0 THEN RUN Fail('ITEMS_FINANCE_ORPHAN_BALANCE','Item fisico ausente possui saldo historico nao quitado.').
 END.
 CREATE ttSettledPurchase. ttSettledPurchase.id=missingId.
 FINALLY:
  RUN CloseQuery(INPUT-OUTPUT historyQuery).
  IF VALID-HANDLE(historyBuffer) THEN DELETE OBJECT historyBuffer NO-ERROR.
 END FINALLY.
END PROCEDURE.
PROCEDURE CollectLedgerIds:
 DEFINE INPUT PARAMETER conditionText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE queryHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE purchaseValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE settledMissing AS LOGICAL NO-UNDO.
 queryHandle=Rows(phLedger,conditionText,"BY " + phLedger:NAME + ".cta_corren_fornec_imp_id",NO-LOCK).
 DO WHILE NOT queryHandle:QUERY-OFF-END:
  valueId=I(phLedger,"cta_corren_fornec_imp_id"). settledMissing=FALSE.
  IF valueId<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Ledger sem chave positiva.").
  IF I(phLedger,"cod_tipo_movto")=4 THEN DO:
   purchaseValue=I(phLedger,'item_proc_compra_id').
   IF CAN-FIND(ttSettledPurchase WHERE ttSettledPurchase.id=purchaseValue) THEN settledMissing=TRUE.
   ELSE IF NOT Found(phPurchaseItems,'item_proc_compra_id=' + N(purchaseValue),SHARE-LOCK) THEN DO:
    RUN RequireSettledOrphan(purchaseValue). settledMissing=TRUE.
   END.
   IF NOT settledMissing THEN RUN AddPurchaseRef(purchaseValue).
  END.
  IF NOT settledMissing AND NOT CAN-FIND(ttLedgerId WHERE ttLedgerId.id=valueId) THEN DO: CREATE ttLedgerId. ttLedgerId.id=valueId. END.
  RUN NextRow(queryHandle,phLedger,NO-LOCK).
 END.
 FINALLY: RUN CloseQuery(INPUT-OUTPUT queryHandle). END FINALLY.
END PROCEDURE.
PROCEDURE ValidatePaymentRows:
 DEFINE INPUT PARAMETER scopeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER ownerValue AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER valuesArray AS JsonArray NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(valuesArray) THEN RUN Fail("ITEMS_FINANCE_PAYMENTS","Valores de titulos nao confirmados.").
 DO j=1 TO valuesArray:Length:
  o=valuesArray:GetJsonObject(j). RUN Closed(o,"num_id_tit_ap,vl_dolar,vl_real").
  valueId=KeyId(o,"num_id_tit_ap").
  FIND ttTitle WHERE ttTitle.scopeName=scopeValue AND ttTitle.ownerId=ownerValue AND ttTitle.id=valueId NO-ERROR.
  IF NOT AVAILABLE ttTitle THEN RUN Fail("ITEMS_FINANCE_PAYMENTS","Callback devolveu titulo sem vinculo fisico.").
  IF ttTitle.confirmed THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Callback duplicou um titulo.").
  ASSIGN ttTitle.usd=NumberValue(o,"vl_dolar") ttTitle.realValue=NumberValue(o,"vl_real") ttTitle.confirmed=TRUE.
 END.
 IF CAN-FIND(FIRST ttTitle WHERE ttTitle.scopeName=scopeValue AND ttTitle.ownerId=ownerValue AND NOT ttTitle.confirmed) THEN
  RUN Fail("ITEMS_FINANCE_PAYMENTS","Callback omitiu titulo associado.").
END PROCEDURE.
FUNCTION EligibleOrderTitle RETURNS LOGICAL (valueId AS INTEGER):
 DEFINE VARIABLE queryHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE linkedId AS INTEGER NO-UNDO.
 DEFINE VARIABLE countLinks AS INTEGER NO-UNDO.
 DEFINE VARIABLE resultValue AS LOGICAL NO-UNDO INITIAL TRUE.
 queryHandle=Rows(phOrderPayments,phOrderPayments:NAME + ".num_id_tit_ap=" + N(valueId),"BY " + phOrderPayments:NAME + ".proc_compra_id",SHARE-LOCK).
 DO WHILE NOT queryHandle:QUERY-OFF-END:
  countLinks=countLinks + 1. RUN NextRow(queryHandle,phOrderPayments,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT queryHandle).
 IF countLinks>1 THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Titulo associado a mais de um pedido.").
 countLinks=0.
 queryHandle=Rows(phContainerPayments,phContainerPayments:NAME + ".num_id_tit_ap=" + N(valueId),"BY " + phContainerPayments:NAME + ".container_id",SHARE-LOCK).
 DO WHILE NOT queryHandle:QUERY-OFF-END:
  countLinks=countLinks + 1. linkedId=I(phContainerPayments,"container_id").
  IF linkedId<=0 OR NOT Found(phAllContainers,phAllContainers:NAME + ".nr-container=" + N(linkedId),SHARE-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Vinculo de titulo com container inexistente.").
  IF Found(phItems,phItems:NAME + ".container_id=" + N(linkedId),SHARE-LOCK) THEN resultValue=FALSE.
  RUN NextRow(queryHandle,phContainerPayments,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT queryHandle).
 IF countLinks>1 THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Titulo associado a mais de um container.").
 RETURN resultValue.
 FINALLY: RUN CloseQuery(INPUT-OUTPUT queryHandle). END FINALLY.
END FUNCTION.
PROCEDURE AddPlan:
 DEFINE INPUT PARAMETER kind AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER supplier AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER titleKey AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER purchase AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER item AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER valueAmount AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER actionValue AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 /* Preserve exact raw sign before physical DECIMALS2; all source paths round
    their deltas except an exact reversal of the already stored ledger. */
 IF valueAmount=? THEN RUN Fail("ITEMS_FINANCE_DATA","Lancamento desconhecido.").
 IF valueAmount=0 THEN RETURN.
 IF supplier<=0 OR purchase<=0 OR (kind<>4 AND kind<>3 AND item<=0) OR (kind<>10 AND kind<>3 AND titleKey<=0) THEN RUN Fail("ITEMS_FINANCE_DATA","Vinculo de lancamento invalido.").
 planCount=planCount + 1. CREATE ttPlan.
 ASSIGN ttPlan.ordinal=planCount ttPlan.kind=kind ttPlan.supplier=supplier ttPlan.titleKey=titleKey ttPlan.purchaseId=purchase ttPlan.itemId=item
  ttPlan.amount=valueAmount ttPlan.historyText=labelText ttPlan.actionValue=actionValue.
 CREATE ttHistory. ASSIGN ttHistory.id= - planCount ttHistory.kind=kind ttHistory.supplier=supplier ttHistory.titleKey=titleKey
  ttHistory.purchaseId=purchase ttHistory.itemId=item ttHistory.amount=ROUND(valueAmount,2).
END PROCEDURE.
FUNCTION BalanceValue RETURNS DECIMAL (kind AS INTEGER,supplier AS INTEGER,titleKey AS INTEGER,purchase AS INTEGER,item AS INTEGER):
 DEFINE VARIABLE totalValue AS DECIMAL DECIMALS 10 NO-UNDO.
 FOR EACH bHistory WHERE bHistory.kind=kind AND bHistory.supplier=supplier AND bHistory.titleKey=titleKey AND bHistory.purchaseId=purchase:
  IF item>=0 AND bHistory.itemId<>item THEN NEXT.
  totalValue=totalValue + bHistory.amount.
 END. RETURN totalValue.
END FUNCTION.
PROCEDURE GroupHistory:
 DEFINE INPUT PARAMETER kind AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER titleKey AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER item AS INTEGER NO-UNDO.
 EMPTY TEMP-TABLE ttGroup.
 FOR EACH bHistory WHERE (kind<>56 AND bHistory.kind=kind) OR (kind=56 AND (bHistory.kind=5 OR bHistory.kind=6)):
  IF titleKey>0 AND bHistory.titleKey<>titleKey THEN NEXT.
  IF item>0 AND bHistory.itemId<>item THEN NEXT.
  FIND ttGroup WHERE ttGroup.supplier=bHistory.supplier AND ttGroup.titleKey=bHistory.titleKey AND ttGroup.purchaseId=bHistory.purchaseId AND ttGroup.itemId=bHistory.itemId NO-ERROR.
  IF NOT AVAILABLE ttGroup THEN DO:
   CREATE ttGroup. ASSIGN ttGroup.supplier=bHistory.supplier ttGroup.titleKey=bHistory.titleKey ttGroup.purchaseId=bHistory.purchaseId ttGroup.itemId=bHistory.itemId.
  END.
  ttGroup.amount=ttGroup.amount + bHistory.amount.
 END.
END PROCEDURE.

poResponse=?.
DO ON ERROR UNDO, THROW:
 IF NOT TRANSACTION THEN RUN Fail("ITEMS_FINANCE_TRANSACTION","Transacao raiz de itens obrigatoria.").
 IF VALID-OBJECT(poContext) THEN IF poContext:Has("operation") THEN IF poContext:GetType("operation")=JsonDataType:STRING THEN
  IF LOOKUP(poContext:GetCharacter("operation"),"purchase-item-create,purchase-item-update,purchase-item-delete")>0 THEN DO:
   purchaseItemOperation=TRUE. forecastOperation=TRUE. RUN PurchaseItemChange. RETURN.
  END.
 IF VALID-OBJECT(poContext) THEN IF poContext:Has("operation") THEN IF poContext:GetType("operation")=JsonDataType:STRING THEN
  IF LOOKUP(poContext:GetCharacter("operation"),"order-enable,order-disable")>0 THEN DO:
   forecastOperation=TRUE. RUN OrderForecast. RETURN.
  END.
 IF VALID-OBJECT(poContext) THEN IF poContext:Has("operation") THEN IF poContext:GetType("operation")=JsonDataType:STRING THEN
  IF LOOKUP(poContext:GetCharacter("operation"),"order-associate,order-disassociate")>0 THEN DO:
   purchasePaymentOperation=TRUE. RUN PurchasePayment. RETURN.
  END.
 RUN Closed(poContext,"operation,container_id,before,after"). RUN Closed(poPolicy,"actor").
 IF poContext:GetType("operation")<>JsonDataType:STRING THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Operacao interna obrigatoria.").
 operationName=poContext:GetCharacter("operation").
 refreshOperation=operationName="refresh-container". forecastOperation=refreshOperation.
 IF operationName<>"create" AND operationName<>"update" AND operationName<>"delete" AND operationName<>"associate" AND operationName<>"disassociate" AND NOT refreshOperation THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Operacao nao suportada.").
 paymentOperation=operationName="associate" OR operationName="disassociate" OR refreshOperation.
 containerId=KeyId(poContext,"container_id"). actorData=poPolicy:GetJsonObject("actor").
 IF actorData:GetType("login")<>JsonDataType:STRING THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Login autenticado interno obrigatorio.").
 actor=actorData:GetCharacter("login").
 IF TRIM(actor)="" OR LENGTH(actor)>128 THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Login autenticado interno deve conter1a128caracteres.").
 IF refreshOperation THEN DO:
  RUN Closed(poContext,"operation,container_id"). rowData=NEW JsonObject(). rowData:Add("container_id",containerId).
 END.
 ELSE IF operationName="create" OR operationName="associate" THEN DO:
  IF NOT poContext:IsNull("before") THEN DO: beforeData=poContext:GetJsonObject("before"). RUN Closed(beforeData,""). END.
  afterData=poContext:GetJsonObject("after"). rowData=afterData.
 END.
 ELSE DO:
  beforeData=poContext:GetJsonObject("before"). rowData=beforeData.
  IF operationName="delete" OR operationName="disassociate" THEN DO: IF NOT poContext:IsNull("after") THEN DO: afterData=poContext:GetJsonObject("after"). RUN Closed(afterData,""). END. END.
  ELSE afterData=poContext:GetJsonObject("after").
 END.
 IF paymentOperation AND NOT refreshOperation THEN DO:
  RUN Closed(rowData,"container_id,num_id_tit_ap"). selectedTitleId=KeyId(rowData,"num_id_tit_ap").
 END.
 ELSE IF NOT refreshOperation THEN ASSIGN changedItemId=KeyId(rowData,"item_container_id") changedPurchaseId=KeyId(rowData,"item_proc_compra_id").
 IF KeyId(rowData,"container_id")<>containerId THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Snapshot de outro container.").
 IF operationName="update" THEN
  IF KeyId(afterData,"item_container_id")<>changedItemId OR KeyId(afterData,"item_proc_compra_id")<>changedPurchaseId OR KeyId(afterData,"container_id")<>containerId THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Referencias do item sao imutaveis.").
 ASSIGN bh[1]=phItems bh[2]=phPurchaseItems bh[3]=phPurchases bh[4]=phLedger bh[5]=phOrderPayments bh[6]=phContainerPayments bh[7]=phAllContainers.
 DO n=1 TO 7:
  IF NOT VALID-HANDLE(bh[n]) THEN RUN Fail("ITEMS_FINANCE_CONFIGURATION","Buffer fixo ausente.").
  IF bh[n]:TYPE<>"BUFFER" THEN RUN Fail("ITEMS_FINANCE_CONFIGURATION","Buffer fixo invalido.").
 END.
 IF NOT VALID-HANDLE(phRuntime) THEN RUN Fail("ITEMS_FINANCE_CONFIGURATION","Runtime privado ausente.").
 IF phRuntime:TYPE<>"PROCEDURE" THEN RUN Fail("ITEMS_FINANCE_CONFIGURATION","Runtime privado invalido.").
 IF LOOKUP("NextLedgerId",phRuntime:INTERNAL-ENTRIES)=0 OR LOOKUP("CollectContainerPayments",phRuntime:INTERNAL-ENTRIES)=0 OR LOOKUP("CollectOrderPayments",phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail("ITEMS_FINANCE_CONFIGURATION","Callbacks privados incompletos.").
 IF NOT Found(phAllContainers,phAllContainers:NAME + ".nr-container=" + N(containerId),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Container pai inexistente.").
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 q=Rows(phItems,phItems:NAME + ".container_id=" + N(containerId),"BY " + phItems:NAME + ".item_container_id",SHARE-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  CREATE ttItem. ASSIGN ttItem.id=I(phItems,"item_container_id") ttItem.purchaseId=I(phItems,"item_proc_compra_id")
   ttItem.allocated=D(phItems,"qt_alocada") ttItem.shipped=D(phItems,"qt_confirm_emb").
  IF ttItem.id<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Item sem chave positiva.").
  RUN AddPurchaseRef(ttItem.purchaseId).
  RUN NextRow(q,phItems,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 IF NOT paymentOperation THEN DO:
 FIND ttItem WHERE ttItem.id=changedItemId NO-ERROR.
 IF operationName="delete" THEN DO: IF AVAILABLE ttItem THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Item ainda existe no estado after de delete."). END.
 ELSE DO:
  IF NOT AVAILABLE ttItem THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Item after nao pertence ao conjunto atual.").
  IF ttItem.purchaseId<>changedPurchaseId OR ttItem.allocated<>NumberValue(afterData,"qt_alocada") OR ttItem.shipped<>NumberValue(afterData,"qt_confirm_emb") THEN RUN Fail("ITEMS_FINANCE_CONTEXT","After difere do registro fisico.").
 END.
 RUN AddPurchaseRef(changedPurchaseId). FIND ttPurchase WHERE ttPurchase.id=changedPurchaseId. changedOrderId=ttPurchase.orderId.
 END.
 IF operationName="disassociate" THEN DO:
  /* The selected title may have no order. Never choose FIRST of many owners. */
  q=Rows(phOrderPayments,phOrderPayments:NAME + ".num_id_tit_ap=" + N(selectedTitleId),"BY " + phOrderPayments:NAME + ".proc_compra_id",SHARE-LOCK).
  countRows=0.
  DO WHILE NOT q:QUERY-OFF-END:
   countRows=countRows + 1. changedOrderId=I(phOrderPayments,"proc_compra_id").
   IF changedOrderId<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Pedido vinculado sem chave positiva.").
   RUN NextRow(q,phOrderPayments,SHARE-LOCK).
  END. RUN CloseQuery(INPUT-OUTPUT q).
  IF countRows>1 THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Titulo associado a mais de um pedido.").
  IF changedOrderId>0 AND NOT CAN-FIND(ttOrder WHERE ttOrder.id=changedOrderId) THEN DO: CREATE ttOrder. ttOrder.id=changedOrderId. END.
 END.
 q=Rows(phContainerPayments,phContainerPayments:NAME + ".container_id=" + N(containerId),"BY " + phContainerPayments:NAME + ".num_id_tit_ap",SHARE-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  titleId=I(phContainerPayments,"num_id_tit_ap").
  IF titleId<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Titulo vinculado sem chave positiva.").
  CREATE ttTitle. ASSIGN ttTitle.scopeName="C" ttTitle.ownerId=containerId ttTitle.id=titleId.
  RUN NextRow(q,phContainerPayments,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 IF paymentOperation AND NOT refreshOperation AND NOT CAN-FIND(ttTitle WHERE ttTitle.scopeName="C" AND ttTitle.id=selectedTitleId) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Vinculo selecionado deve existir durante callback financeiro.").
 /* Every container title must have an unambiguous owner before any money is
    collected. Eligibility itself only controls the later order rerateio. */
 FOR EACH ttTitle WHERE ttTitle.scopeName="C" BY ttTitle.id:
  ttTitle.eligible=EligibleOrderTitle(ttTitle.id).
 END.
 /* Gather references first; lock owners by primary key before financial reads. */
 IF operationName="create" OR operationName="associate" OR refreshOperation THEN FOR EACH ttTitle WHERE ttTitle.scopeName="C":
  RUN CollectLedgerIds(phLedger:NAME + ".num_id_tit_ap=" + N(ttTitle.id) + " AND " + phLedger:NAME + ".cod_tipo_movto=4").
 END.
 IF operationName="disassociate" THEN RUN CollectLedgerIds(phLedger:NAME + ".num_id_tit_ap=" + N(selectedTitleId) + " AND (" + phLedger:NAME + ".cod_tipo_movto=5 OR " + phLedger:NAME + ".cod_tipo_movto=6)").
 FOR EACH ttOrder BY ttOrder.id:
  IF NOT Found(phPurchases,phPurchases:NAME + ".proc_compra_id=" + N(ttOrder.id),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Pedido inexistente.").
  ASSIGN ttOrder.supplier=I(phPurchases,"fornecedor_id") ttOrder.enabled=phPurchases:BUFFER-FIELD("log_considerar_previsao"):BUFFER-VALUE.
  IF ttOrder.supplier<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Fornecedor do pedido sem chave positiva.").
 END.
 IF operationName="delete" OR (operationName="disassociate" AND changedOrderId>0) THEN DO:
  q=Rows(phPurchaseItems,phPurchaseItems:NAME + ".proc_compra_id=" + N(changedOrderId),"BY " + phPurchaseItems:NAME + ".item_proc_compra_id",SHARE-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   currentId=I(phPurchaseItems,"item_proc_compra_id").
   IF NOT CAN-FIND(ttPurchase WHERE ttPurchase.id=currentId) THEN DO: CREATE ttPurchase. ASSIGN ttPurchase.id=currentId ttPurchase.orderId=changedOrderId. END.
   RUN NextRow(q,phPurchaseItems,SHARE-LOCK).
  END. RUN CloseQuery(INPUT-OUTPUT q).
 END.
 FOR EACH ttPurchase BY ttPurchase.id:
  IF NOT Found(phPurchaseItems,phPurchaseItems:NAME + ".item_proc_compra_id=" + N(ttPurchase.id),SHARE-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Item do pedido deixou de existir.").
  IF I(phPurchaseItems,"proc_compra_id")<>ttPurchase.orderId THEN RUN Fail("ITEMS_FINANCE_DATA","Pedido do item mudou durante coleta.").
  ASSIGN ttPurchase.bought=phPurchaseItems:BUFFER-FIELD("qt_comprada"):BUFFER-VALUE ttPurchase.proforma=phPurchaseItems:BUFFER-FIELD("vl_custo_dolar"):BUFFER-VALUE
   ttPurchase.negotiated=phPurchaseItems:BUFFER-FIELD("vl_negociado"):BUFFER-VALUE.
 END.
 IF operationName<>"disassociate" AND CAN-FIND(FIRST ttTitle WHERE ttTitle.scopeName="C") THEN DO:
  IF NOT Found(phAllContainers,phAllContainers:NAME + ".nr-container=" + N(containerId),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Pai perdeu contexto.").
  RUN CollectContainerPayments IN phRuntime(phAllContainers,OUTPUT paymentRows).
  RUN ValidatePaymentRows("C",containerId,paymentRows).
 END.
 IF operationName<>"disassociate" THEN FOR EACH ttItem:
  RUN CollectLedgerIds(phLedger:NAME + ".item_container_id=" + N(ttItem.id) + " AND " + phLedger:NAME + ".cod_tipo_movto=5").
 END.
 IF operationName="delete" THEN RUN CollectLedgerIds(phLedger:NAME + ".item_container_id=" + N(changedItemId) + " AND " + phLedger:NAME + ".cod_tipo_movto=5").
 IF operationName="update" THEN RUN CollectLedgerIds(phLedger:NAME + ".item_container_id=" + N(changedItemId) + " AND " + phLedger:NAME + ".cod_tipo_movto=10").
 IF refreshOperation THEN FOR EACH ttItem:
  RUN CollectLedgerIds(phLedger:NAME + ".item_container_id=" + N(ttItem.id) + " AND " + phLedger:NAME + ".cod_tipo_movto=10").
 END.
 IF operationName="delete" OR (operationName="disassociate" AND changedOrderId>0) THEN DO:
  FIND ttOrder WHERE ttOrder.id=changedOrderId.
  IF ttOrder.enabled=? THEN RUN Fail("ITEMS_FINANCE_DATA","Flag de previsao do pedido desconhecida.").
  IF ttOrder.enabled THEN DO:
   q=Rows(phOrderPayments,phOrderPayments:NAME + ".proc_compra_id=" + N(changedOrderId),"BY " + phOrderPayments:NAME + ".num_id_tit_ap",SHARE-LOCK).
   DO WHILE NOT q:QUERY-OFF-END:
    titleId=I(phOrderPayments,"num_id_tit_ap").
    IF titleId<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Titulo do pedido sem chave positiva.").
    CREATE ttTitle. ASSIGN ttTitle.scopeName="O" ttTitle.ownerId=changedOrderId ttTitle.id=titleId.
    RUN NextRow(q,phOrderPayments,SHARE-LOCK).
   END. RUN CloseQuery(INPUT-OUTPUT q).
   FOR EACH ttTitle WHERE ttTitle.scopeName="O":
    ttTitle.eligible=EligibleOrderTitle(ttTitle.id).
    /* TRUE force in legacy unlink bypasses container eligibility only; owner
       ambiguity is still validated above by the same shared collector. */
    IF operationName="disassociate" THEN ttTitle.eligible=TRUE.
    IF ttTitle.eligible THEN enabledCount=enabledCount + 1.
    RUN CollectLedgerIds(phLedger:NAME + ".num_id_tit_ap=" + N(ttTitle.id) + " AND " + phLedger:NAME + ".cod_tipo_movto=4").
   END.
   IF enabledCount>0 THEN DO:
    IF NOT Found(phPurchases,phPurchases:NAME + ".proc_compra_id=" + N(changedOrderId),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Pedido perdeu contexto.").
    RUN CollectOrderPayments IN phRuntime(phPurchases,OUTPUT paymentRows).
    RUN ValidatePaymentRows("O",changedOrderId,paymentRows).
   END.
  END.
 END.
 FOR EACH ttLedgerId BY ttLedgerId.id:
  IF NOT Found(phLedger,phLedger:NAME + ".cta_corren_fornec_imp_id=" + N(ttLedgerId.id),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Ledger mudou durante coleta.").
  CREATE ttHistory. ASSIGN ttHistory.id=ttLedgerId.id ttHistory.kind=I(phLedger,"cod_tipo_movto") ttHistory.supplier=I(phLedger,"fornecedor_id")
   ttHistory.titleKey=I(phLedger,"num_id_tit_ap") ttHistory.purchaseId=I(phLedger,"item_proc_compra_id") ttHistory.itemId=I(phLedger,"item_container_id") ttHistory.amount=D(phLedger,"vl_lancto").
 END.
 IF operationName="create" OR operationName="associate" OR refreshOperation THEN RUN ReverseOrderAllocation.
 IF operationName<>"disassociate" THEN RUN AllocateContainer.
 IF operationName="update" THEN RUN ShippedDifference.
 IF refreshOperation THEN FOR EACH ttItem BY ttItem.id: changedItemId=ttItem.id. RUN ShippedDifference. END.
 IF operationName="delete" THEN DO: RUN ReverseDeletedItem. RUN AllocateOrder. END.
 IF operationName="disassociate" THEN DO:
  RUN ReverseContainerPayment.
  IF changedOrderId>0 THEN RUN AllocateOrder.
 END.
 RUN PersistPlans.
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("changes",changes). poResponse:Add("warnings",warnings).
 FINALLY:
  RUN CloseQuery(INPUT-OUTPUT q). RUN CloseQuery(INPUT-OUTPUT qAux).
  /* Root caller owns all locks and commit/UNDO. Never release them here. */
 END FINALLY.
END.
PROCEDURE ReverseOrderAllocation:
 FOR EACH ttTitle WHERE ttTitle.scopeName="C" BY ttTitle.id:
  /* verifTitPedImp is existence of type4 ledger, not order-payment lookup. */
  RUN GroupHistory(4,ttTitle.id,0).
  FOR EACH ttGroup BY ttGroup.supplier BY ttGroup.purchaseId BY ttGroup.itemId:
   RUN AddPlan(4,ttGroup.supplier,ttTitle.id,ttGroup.purchaseId,0, - ttGroup.amount,1,"Estorno de rateio do pedido; alocacao no container " + N(containerId)).
  END.
 END.
END PROCEDURE.
PROCEDURE AllocateContainer:
 IF NOT CAN-FIND(FIRST ttTitle WHERE ttTitle.scopeName="C") THEN RETURN.
 ASSIGN totalAllocated=0 totalShipped=0.
 FOR EACH ttItem:
  FIND ttPurchase WHERE ttPurchase.id=ttItem.purchaseId.
  ASSIGN totalAllocated=totalAllocated + Used(ttPurchase.proforma) * ttItem.allocated totalShipped=totalShipped + Used(ttPurchase.proforma) * ttItem.shipped.
 END.
 totalProforma=IF totalShipped=0 THEN totalAllocated ELSE totalShipped.
 FOR EACH ttTitle WHERE ttTitle.scopeName="C" BY ttTitle.id:
  FOR EACH ttItem BY ttItem.id:
   FIND ttPurchase WHERE ttPurchase.id=ttItem.purchaseId. FIND ttOrder WHERE ttOrder.id=ttPurchase.orderId.
   itemProforma=Used(ttPurchase.proforma) * ttItem.shipped.
   IF itemProforma=0 THEN itemProforma=Used(ttPurchase.proforma) * ttItem.allocated.
   targetValue=IF totalProforma * ttTitle.usd<>0 THEN itemProforma / totalProforma * ttTitle.usd ELSE 0.
   balance=ROUND(BalanceValue(5,ttOrder.supplier,ttTitle.id,ttPurchase.id,ttItem.id),2).
   delta=ROUND(targetValue + balance,2).
   RUN AddPlan(5,ttOrder.supplier,ttTitle.id,ttPurchase.id,ttItem.id, - delta,IF delta>0 THEN 1 ELSE 3,"Rateio de pagamento no container " + N(containerId)).
  END.
 END.
END PROCEDURE.
PROCEDURE ShippedDifference:
 FIND ttItem WHERE ttItem.id=changedItemId. FIND ttPurchase WHERE ttPurchase.id=ttItem.purchaseId. FIND ttOrder WHERE ttOrder.id=ttPurchase.orderId.
 IF ttItem.shipped<=0 OR ttItem.shipped=ttItem.allocated THEN DO:
  IF CAN-FIND(FIRST ttHistory WHERE ttHistory.kind=10 AND ttHistory.itemId=changedItemId) THEN DO:
   warningData=NEW JsonObject(). warningData:Add("code","ITEMS_FINANCE_LEGACY_TYPE10_RETAINED"). warningData:Add("item_container_id",changedItemId).
   warningData:Add("message","Tipo10 anterior mantido: ramo legado nao estorna quando confirmada zera ou iguala alocada."). warnings:Add(warningData).
  END.
  RETURN.
 END.
 RUN GroupHistory(10,0,changedItemId).
 countRows=0. balance=0.
 FOR EACH ttGroup: ASSIGN countRows=countRows + 1 balance=ttGroup.amount. END.
 IF countRows>1 THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Tipo10 anterior possui mais de um grupo financeiro.").
 delta=ROUND((ttItem.shipped - ttItem.allocated) * Used(ttPurchase.negotiated) - balance,2).
 RUN AddPlan(10,ttOrder.supplier,0,ttPurchase.id,ttItem.id,delta,2,"Confirmacao de quantidade embarcada; container " + N(containerId)).
END PROCEDURE.
PROCEDURE ReverseDeletedItem:
 RUN GroupHistory(5,0,changedItemId).
 FOR EACH ttGroup BY ttGroup.supplier BY ttGroup.titleKey BY ttGroup.purchaseId:
  IF ttGroup.purchaseId<>changedPurchaseId THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Saldo do item excluido aponta para outro item do pedido.").
  RUN AddPlan(6,ttGroup.supplier,ttGroup.titleKey,ttGroup.purchaseId,changedItemId, - ttGroup.amount,3,"Estorno de pagamento do item excluido; container " + N(containerId)).
 END.
END PROCEDURE.
PROCEDURE ReverseContainerPayment:
 /* Legacy estornarPagtosContainer: SUM5+6 GLOBAL by selected title and
    supplier/purchase/item. New5 action3, before DELETElink; no rateio C. */
 RUN GroupHistory(56,selectedTitleId,0).
 FOR EACH ttGroup BY ttGroup.supplier BY ttGroup.purchaseId BY ttGroup.itemId:
  RUN AddPlan(5,ttGroup.supplier,selectedTitleId,ttGroup.purchaseId,ttGroup.itemId, - ttGroup.amount,3,"Estorno de pagamento desvinculado do container " + N(containerId)).
 END.
END PROCEDURE.
PROCEDURE AllocateOrder:
 IF NOT CAN-FIND(FIRST ttTitle WHERE ttTitle.scopeName="O" AND ttTitle.eligible) THEN RETURN.
 FIND ttOrder WHERE ttOrder.id=changedOrderId. totalWeight=0.
 FOR EACH ttPurchase WHERE ttPurchase.orderId=changedOrderId:
  totalWeight=totalWeight + Used(ttPurchase.bought) * Used(ttPurchase.negotiated).
 END.
 IF totalWeight=0 AND operationName<>"order-disassociate" AND operationName<>"purchase-item-delete" THEN RUN Fail("ITEMS_FINANCE_ZERO_WEIGHT","Peso negociado do pedido zero impede rateio.").
 FOR EACH ttTitle WHERE ttTitle.scopeName="O" AND ttTitle.eligible BY ttTitle.id:
  FOR EACH ttPurchase WHERE ttPurchase.orderId=changedOrderId BY ttPurchase.id:
   weight=Used(ttPurchase.bought) * Used(ttPurchase.negotiated).
   targetValue=IF operationName="order-disassociate" OR totalWeight=0 THEN 0 ELSE ttTitle.usd * weight / totalWeight.
   balance=BalanceValue(4,ttOrder.supplier,ttTitle.id,ttPurchase.id, - 1).
   delta=ROUND(targetValue + balance,2).
   RUN AddPlan(4,ttOrder.supplier,ttTitle.id,ttPurchase.id,0, - delta,IF delta>0 THEN 1 ELSE 3,"Rateio de pagamento do pedido " + N(changedOrderId) + (IF purchasePaymentOperation OR purchaseItemOperation THEN "" ELSE "; container " + N(containerId))).
  END.
 END.
END PROCEDURE.
FUNCTION LedgerSnapshot RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE dateValue AS DATE NO-UNDO.
 DEFINE VARIABLE timeValue AS DATETIME NO-UNDO.
 IF forecastOperation THEN RETURN ForecastLedgerSnapshot().
 o=NEW JsonObject().
 o:Add("cta_corren_fornec_imp_id",I(phLedger,"cta_corren_fornec_imp_id")). o:Add("fornecedor_id",I(phLedger,"fornecedor_id")).
 dateValue=phLedger:BUFFER-FIELD("data"):BUFFER-VALUE. o:Add("data",dateValue).
 o:Add("item_proc_compra_id",I(phLedger,"item_proc_compra_id")). textValue=phLedger:BUFFER-FIELD("historico"):BUFFER-VALUE. o:Add("historico",textValue).
 o:Add("cod_tipo_movto",I(phLedger,"cod_tipo_movto")). o:Add("vl_lancto",D(phLedger,"vl_lancto")). o:Add("cod_acao",I(phLedger,"cod_acao")).
 textValue=phLedger:BUFFER-FIELD("login"):BUFFER-VALUE. o:Add("login",textValue). timeValue=phLedger:BUFFER-FIELD("data_hora"):BUFFER-VALUE. o:Add("data_hora",timeValue).
 o:Add("num_id_tit_ap",I(phLedger,"num_id_tit_ap")). o:Add("item_container_id",I(phLedger,"item_container_id")). o:Add("transacao_id",I(phLedger,"transacao_id")).
 /* Synthetic origin for audit only; the physical table has no container_id. */
 IF forecastOperation THEN DO:
  FIND ttPurchase WHERE ttPurchase.id=I(phLedger,"item_proc_compra_id") NO-ERROR.
  IF NOT AVAILABLE ttPurchase THEN RUN Fail("ITEMS_FINANCE_DATA","Escopo real do lancamento ausente.").
  o:Add("proc_compra_id",ttPurchase.orderId).
 END.
 ELSE IF purchasePaymentOperation THEN o:Add("proc_compra_id",changedOrderId). ELSE o:Add("container_id",containerId). RETURN o.
END FUNCTION.
FUNCTION ForecastLedgerSnapshot RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE ix AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldsValue AS CHARACTER NO-UNDO INITIAL 'cta_corren_fornec_imp_id,fornecedor_id,data,item_proc_compra_id,historico,cod_tipo_movto,vl_lancto,cod_acao,login,data_hora,num_id_tit_ap,item_container_id,transacao_id'.
 o=NEW JsonObject().
 DO ix=1 TO NUM-ENTRIES(fieldsValue):
  f=phLedger:BUFFER-FIELD(ENTRY(ix,fieldsValue)).
  IF f:BUFFER-VALUE=? THEN o:AddNull(f:NAME).
  ELSE CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN o:Add(f:NAME,STRING(f:BUFFER-VALUE)).
   WHEN 'INTEGER' THEN o:Add(f:NAME,INTEGER(f:BUFFER-VALUE)).
   WHEN 'DECIMAL' THEN o:Add(f:NAME,DECIMAL(f:BUFFER-VALUE)).
   WHEN 'DATE' THEN o:Add(f:NAME,DATE(f:BUFFER-VALUE)).
   WHEN 'DATETIME' THEN o:Add(f:NAME,DATETIME(f:BUFFER-VALUE)).
   OTHERWISE RUN Fail('ITEMS_FINANCE_DATA','Tipo fisico do ledger inesperado.').
  END CASE.
 END.
 FIND ttPurchase WHERE ttPurchase.id=I(phLedger,'item_proc_compra_id') NO-ERROR.
 IF NOT AVAILABLE ttPurchase THEN RUN Fail('ITEMS_FINANCE_DATA','Escopo real do lancamento ausente.').
 o:Add('proc_compra_id',ttPurchase.orderId). RETURN o.
END FUNCTION.
PROCEDURE PersistPlans:
 timestampValue=NOW.
 FOR EACH ttPlan BY ttPlan.ordinal:

  RUN NextLedgerId IN phRuntime(OUTPUT newId).
  IF newId=? OR newId<=0 THEN RUN Fail("ITEMS_FINANCE_SEQUENCE","Sequencia fixa retornou ID invalido.").
  IF Found(phLedger,phLedger:NAME + ".cta_corren_fornec_imp_id=" + N(newId),SHARE-LOCK) THEN RUN Fail("ITEMS_FINANCE_SEQUENCE","ID financeiro ja existe.").
  IF NOT phLedger:BUFFER-CREATE() THEN RUN Fail("ITEMS_FINANCE_PERSISTENCE","Criacao de lancamento recusada.").
  ASSIGN phLedger:BUFFER-FIELD("cta_corren_fornec_imp_id"):BUFFER-VALUE=newId phLedger:BUFFER-FIELD("fornecedor_id"):BUFFER-VALUE=ttPlan.supplier
   phLedger:BUFFER-FIELD("data"):BUFFER-VALUE=DATE(timestampValue) phLedger:BUFFER-FIELD("item_proc_compra_id"):BUFFER-VALUE=ttPlan.purchaseId
   phLedger:BUFFER-FIELD("historico"):BUFFER-VALUE=ttPlan.historyText phLedger:BUFFER-FIELD("cod_tipo_movto"):BUFFER-VALUE=ttPlan.kind
   phLedger:BUFFER-FIELD("vl_lancto"):BUFFER-VALUE=ttPlan.amount phLedger:BUFFER-FIELD("cod_acao"):BUFFER-VALUE=ttPlan.actionValue
   phLedger:BUFFER-FIELD("login"):BUFFER-VALUE=actor phLedger:BUFFER-FIELD("data_hora"):BUFFER-VALUE=timestampValue
   phLedger:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE=ttPlan.titleKey phLedger:BUFFER-FIELD("item_container_id"):BUFFER-VALUE=ttPlan.itemId
   phLedger:BUFFER-FIELD("transacao_id"):BUFFER-VALUE=0.
  IF NOT phLedger:BUFFER-VALIDATE() THEN RUN Fail("ITEMS_FINANCE_PERSISTENCE","Lancamento recusado por validacao fisica.").
  eventData=NEW JsonObject(). eventData:Add("resource","cta_corren_fornec_imp"). eventData:Add("operation","create"). eventData:Add("recordId",newId).
  eventData:Add("before",NEW JsonObject()). eventData:Add("after",LedgerSnapshot()). changes:Add(eventData).
 END.
END PROCEDURE.

/* Direct association/removal from a purchase uses the SAME AllocateOrder,
   balances, rounding and PersistPlans as container rerateio. Root owns commit. */
PROCEDURE PurchasePayment:
 DEFINE VARIABLE selectedRows AS JsonArray NO-UNDO.
 DEFINE VARIABLE valueRow AS JsonObject NO-UNDO.
 DEFINE VARIABLE linkQuery AS HANDLE NO-UNDO.
 DEFINE VARIABLE totalLinks AS INTEGER NO-UNDO.
 RUN Closed(poContext,"operation,proc_compra_id,before,after"). RUN Closed(poPolicy,"actor").
 operationName=poContext:GetCharacter("operation"). changedOrderId=KeyId(poContext,"proc_compra_id"). actorData=poPolicy:GetJsonObject("actor").
 IF actorData:GetType("login")<>JsonDataType:STRING THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Autoria interna obrigatoria.").
 actor=actorData:GetCharacter("login"). IF TRIM(actor)="" OR LENGTH(actor)>128 THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Autoria interna invalida.").
 IF operationName="order-associate" THEN DO:
  beforeData=poContext:GetJsonObject("before"). RUN Closed(beforeData,""). rowData=poContext:GetJsonObject("after").
 END.
 ELSE DO: afterData=poContext:GetJsonObject("after"). RUN Closed(afterData,""). rowData=poContext:GetJsonObject("before"). END.
 RUN Closed(rowData,"proc_compra_id,num_id_tit_ap"). selectedTitleId=KeyId(rowData,"num_id_tit_ap").
 IF KeyId(rowData,"proc_compra_id")<>changedOrderId THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Snapshot de outro pedido.").
 IF NOT VALID-HANDLE(phRuntime) OR LOOKUP("CollectOrderPayments",phRuntime:INTERNAL-ENTRIES)=0 OR LOOKUP("NextLedgerId",phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail("ITEMS_FINANCE_CONFIGURATION","Composicao financeira ausente.").
 IF NOT Found(phPurchases,phPurchases:NAME + ".proc_compra_id=" + N(changedOrderId),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Pedido ausente.").
 CREATE ttOrder. ASSIGN ttOrder.id=changedOrderId ttOrder.supplier=I(phPurchases,"fornecedor_id") ttOrder.enabled=TRUE.
 IF ttOrder.supplier<=0 THEN RUN Fail("ITEMS_FINANCE_DATA","Fornecedor invalido.").
 linkQuery=Rows(phOrderPayments,phOrderPayments:NAME + ".num_id_tit_ap=" + N(selectedTitleId),"",SHARE-LOCK).
 DO WHILE NOT linkQuery:QUERY-OFF-END:
  totalLinks=totalLinks + 1. IF I(phOrderPayments,"proc_compra_id")<>changedOrderId THEN RUN Fail("ITEMS_FINANCE_AMBIGUOUS","Titulo ligado a outro pedido.").
  RUN NextRow(linkQuery,phOrderPayments,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT linkQuery).
 IF totalLinks<>1 THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Vinculo fisico unico obrigatorio.").
 q=Rows(phPurchaseItems,phPurchaseItems:NAME + ".proc_compra_id=" + N(changedOrderId),"BY " + phPurchaseItems:NAME + ".item_proc_compra_id",SHARE-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  CREATE ttPurchase. ASSIGN ttPurchase.id=I(phPurchaseItems,"item_proc_compra_id") ttPurchase.orderId=changedOrderId
   ttPurchase.bought=D(phPurchaseItems,"qt_comprada") ttPurchase.negotiated=D(phPurchaseItems,"vl_negociado").
  RUN NextRow(q,phPurchaseItems,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 CREATE ttTitle. ASSIGN ttTitle.scopeName="O" ttTitle.ownerId=changedOrderId ttTitle.id=selectedTitleId ttTitle.eligible=TRUE.
 IF operationName="order-associate" THEN DO:
  IF NOT Found(phPurchases,phPurchases:NAME + ".proc_compra_id=" + N(changedOrderId),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_CONTEXT","Pedido perdeu contexto.").
  RUN CollectOrderPayments IN phRuntime(phPurchases,OUTPUT paymentRows). selectedRows=NEW JsonArray().
  DO n=1 TO paymentRows:Length:
   valueRow=paymentRows:GetJsonObject(n).
   IF KeyId(valueRow,"num_id_tit_ap")=selectedTitleId THEN selectedRows:Add(CAST(valueRow:Clone(),JsonObject)).
  END.
  RUN ValidatePaymentRows("O",changedOrderId,selectedRows).
 END.
 RUN CollectLedgerIds(phLedger:NAME + ".num_id_tit_ap=" + N(selectedTitleId) + " AND " + phLedger:NAME + ".cod_tipo_movto=4").
 FOR EACH ttLedgerId BY ttLedgerId.id:
  IF NOT Found(phLedger,phLedger:NAME + ".cta_corren_fornec_imp_id=" + N(ttLedgerId.id),EXCLUSIVE-LOCK) THEN RUN Fail("ITEMS_FINANCE_DATA","Historico financeiro mudou.").
  CREATE ttHistory. ASSIGN ttHistory.id=ttLedgerId.id ttHistory.kind=I(phLedger,"cod_tipo_movto") ttHistory.supplier=I(phLedger,"fornecedor_id")
   ttHistory.titleKey=I(phLedger,"num_id_tit_ap") ttHistory.purchaseId=I(phLedger,"item_proc_compra_id") ttHistory.itemId=I(phLedger,"item_container_id") ttHistory.amount=D(phLedger,"vl_lancto").
 END.
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 RUN AllocateOrder. RUN PersistPlans.
 poResponse=NEW JsonObject(). poResponse:Add("success",TRUE). poResponse:Add("changes",changes). poResponse:Add("warnings",warnings).
 FINALLY: RUN CloseQuery(INPUT-OUTPUT linkQuery). END FINALLY.
END PROCEDURE.
/* Forecast reconstruction is a reusable participant, never a transaction owner.
   Only this branch owns legacy >2 deletion; all calculations share the helpers. */
PROCEDURE OrderForecast:
 DEFINE VARIABLE ownOrder AS INTEGER NO-UNDO.
 DEFINE VARIABLE r AS JsonObject NO-UNDO.
 DEFINE VARIABLE a AS JsonArray NO-UNDO.
 DEFINE VARIABLE ix AS INTEGER NO-UNDO.
 RUN Closed(poContext,'operation,proc_compra_id'). RUN Closed(poPolicy,'actor').
 operationName=poContext:GetCharacter('operation'). changedOrderId=KeyId(poContext,'proc_compra_id'). ownOrder=changedOrderId.
 actor=poPolicy:GetJsonObject('actor'):GetCharacter('login').
 IF actor=? OR TRIM(actor)='' OR LENGTH(actor)>128 THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Autoria interna obrigatoria.').
 IF NOT Found(phPurchases,phPurchases:NAME + '.proc_compra_id=' + N(ownOrder),EXCLUSIVE-LOCK) THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Pedido ausente.').
 CREATE ttOrder. ASSIGN ttOrder.id=ownOrder ttOrder.supplier=I(phPurchases,'fornecedor_id') ttOrder.enabled=phPurchases:BUFFER-FIELD('log_considerar_previsao'):BUFFER-VALUE.
 IF ttOrder.enabled=? OR ttOrder.enabled<>(operationName='order-enable') THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Flag fisica diverge da operacao.').
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 q=Rows(phPurchaseItems,phPurchaseItems:NAME + '.proc_compra_id=' + N(ownOrder),'BY item_proc_compra_id',SHARE-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  CREATE ttPurchase. ASSIGN ttPurchase.id=I(phPurchaseItems,'item_proc_compra_id') ttPurchase.orderId=ownOrder
   ttPurchase.bought=IF operationName='order-enable' THEN D(phPurchaseItems,'qt_comprada') ELSE 0
   ttPurchase.negotiated=IF operationName='order-enable' THEN D(phPurchaseItems,'vl_negociado') ELSE 0.
  RUN NextRow(q,phPurchaseItems,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 FOR EACH ttPurchase BY ttPurchase.id:
  q=Rows(phLedger,phLedger:NAME + '.item_proc_compra_id=' + N(ttPurchase.id) + ' AND cod_tipo_movto>2','BY cta_corren_fornec_imp_id',EXCLUSIVE-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   eventData=NEW JsonObject(). eventData:Add('resource','cta_corren_fornec_imp'). eventData:Add('operation','delete'). eventData:Add('recordId',I(phLedger,'cta_corren_fornec_imp_id')).
   eventData:Add('before',LedgerSnapshot()). eventData:Add('after',NEW JsonObject()). changes:Add(eventData).
   IF NOT phLedger:BUFFER-DELETE() THEN RUN Fail('ITEMS_FINANCE_PERSISTENCE','Exclusao de previsao recusada.').
   RUN NextRow(q,phLedger,EXCLUSIVE-LOCK).
  END. RUN CloseQuery(INPUT-OUTPUT q).
 END.
 IF operationName='order-enable' THEN DO:
  FIND ttOrder WHERE ttOrder.id=ownOrder.
  FOR EACH ttPurchase BY ttPurchase.id:
   RUN AddPlan(3,ttOrder.supplier,0,ttPurchase.id,0,Used(ttPurchase.bought) * Used(ttPurchase.negotiated),1,'Obrigacao do pedido ' + N(ownOrder)).
  END.
  q=Rows(phOrderPayments,phOrderPayments:NAME + '.proc_compra_id=' + N(ownOrder),'BY num_id_tit_ap',SHARE-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   titleId=I(phOrderPayments,'num_id_tit_ap').
   CREATE ttTitle. ASSIGN ttTitle.scopeName='O' ttTitle.ownerId=ownOrder ttTitle.id=titleId ttTitle.eligible=TRUE.
   /* Shared ownership ambiguity guard; forced allocation preserves legacy. */
   balance=IF EligibleOrderTitle(titleId) THEN 1 ELSE 0.
   RUN NextRow(q,phOrderPayments,SHARE-LOCK).
  END. RUN CloseQuery(INPUT-OUTPUT q).
  IF CAN-FIND(FIRST ttTitle) THEN DO:
   IF NOT Found(phPurchases,phPurchases:NAME + '.proc_compra_id=' + N(ownOrder),EXCLUSIVE-LOCK) THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Pedido mudou.').
   RUN CollectOrderPayments IN phRuntime(phPurchases,OUTPUT paymentRows).
   RUN ValidatePaymentRows('O',ownOrder,paymentRows).
   RUN AllocateOrder.
  END.
  RUN PersistPlans.
  RUN RefreshOrderContainers IN phRuntime(ownOrder,OUTPUT r).
  IF NOT VALID-OBJECT(r) OR NOT r:GetLogical('success') THEN RUN Fail('ITEMS_FINANCE_CONFIGURATION','Reconciliacao de containers recusada.').
  a=r:GetJsonArray('changes'). DO ix=1 TO a:Length: changes:Add(CAST(a:GetJsonObject(ix):Clone(),JsonObject)). END.
  a=r:GetJsonArray('warnings'). DO ix=1 TO a:Length:
   IF a:GetType(ix)=JsonDataType:OBJECT THEN warnings:Add(CAST(a:GetJsonObject(ix):Clone(),JsonObject)). ELSE warnings:Add(a:GetCharacter(ix)).
  END.
 END.
 IF changes:Length>2000 THEN RUN Fail('ITEMS_FINANCE_LIMIT','Mais de2000efeitos na previsao.').
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('changes',changes). poResponse:Add('warnings',warnings).
 FINALLY: RUN CloseQuery(INPUT-OUTPUT q). END FINALLY.
END PROCEDURE.

/* Incremental item lifecycle: preserve every historical row. Root writer holds
   parent/company/item locks; deletion is physically applied AFTER this participant. */
PROCEDURE PurchaseItemChange:
 DEFINE VARIABLE expectedItem AS INTEGER NO-UNDO.
 DEFINE VARIABLE expectedOrder AS INTEGER NO-UNDO.
 DEFINE VARIABLE obligation AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE ownBalance AS DECIMAL DECIMALS 10 NO-UNDO.
 RUN Closed(poContext,'operation,proc_compra_id,item_proc_compra_id,before,after'). RUN Closed(poPolicy,'actor').
 operationName=poContext:GetCharacter('operation'). changedOrderId=KeyId(poContext,'proc_compra_id'). expectedOrder=changedOrderId.
 changedPurchaseId=KeyId(poContext,'item_proc_compra_id'). expectedItem=changedPurchaseId.
 actor=poPolicy:GetJsonObject('actor'):GetCharacter('login').
 IF actor=? OR TRIM(actor)='' OR LENGTH(actor)>128 THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Autoria interna obrigatoria.').
 IF NOT VALID-HANDLE(phRuntime) OR LOOKUP('NextLedgerId',phRuntime:INTERNAL-ENTRIES)=0 OR LOOKUP('CollectOrderPayments',phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail('ITEMS_FINANCE_CONFIGURATION','Composicao de item incompleta.').
 IF NOT Found(phPurchases,'proc_compra_id=' + N(expectedOrder),EXCLUSIVE-LOCK) THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Processo fisico ausente.').
 CREATE ttOrder. ASSIGN ttOrder.id=expectedOrder ttOrder.supplier=I(phPurchases,'fornecedor_id') ttOrder.enabled=phPurchases:BUFFER-FIELD('log_considerar_previsao'):BUFFER-VALUE.
 IF ttOrder.supplier<1 OR ttOrder.enabled=? THEN RUN Fail('ITEMS_FINANCE_DATA','Contexto financeiro indefinido.').
 q=Rows(phPurchaseItems,'proc_compra_id=' + N(expectedOrder),'BY item_proc_compra_id',SHARE-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  CREATE ttPurchase. ASSIGN ttPurchase.id=I(phPurchaseItems,'item_proc_compra_id') ttPurchase.orderId=expectedOrder
   ttPurchase.bought=D(phPurchaseItems,'qt_comprada') ttPurchase.negotiated=D(phPurchaseItems,'vl_negociado') ttPurchase.proforma=D(phPurchaseItems,'vl_custo_dolar').
  IF ttPurchase.id=expectedItem AND operationName='purchase-item-delete' THEN ttPurchase.bought=0.
  RUN NextRow(q,phPurchaseItems,SHARE-LOCK).
 END. RUN CloseQuery(INPUT-OUTPUT q).
 FIND ttPurchase WHERE ttPurchase.id=expectedItem NO-ERROR.
 IF NOT AVAILABLE ttPurchase THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Item fisico contextual ausente.').
 FIND ttOrder WHERE ttOrder.id=expectedOrder.
 obligation=IF ttOrder.enabled THEN Used(ttPurchase.bought) * Used(ttPurchase.negotiated) ELSE 0.
 RUN CollectLedgerIds('item_proc_compra_id=' + N(expectedItem) + ' AND cod_tipo_movto=3').
 IF operationName='purchase-item-delete' THEN RUN CollectLedgerIds('item_proc_compra_id=' + N(expectedItem) + ' AND cod_tipo_movto=4').
 IF ttOrder.enabled THEN DO:
  q=Rows(phOrderPayments,'proc_compra_id=' + N(expectedOrder),'BY num_id_tit_ap',SHARE-LOCK).
  DO WHILE NOT q:QUERY-OFF-END:
   titleId=I(phOrderPayments,'num_id_tit_ap').
   IF titleId<1 THEN RUN Fail('ITEMS_FINANCE_DATA','Titulo sem identidade.').
   CREATE ttTitle. ASSIGN ttTitle.scopeName='O' ttTitle.ownerId=expectedOrder ttTitle.id=titleId.
   RUN NextRow(q,phOrderPayments,SHARE-LOCK).
  END. RUN CloseQuery(INPUT-OUTPUT q).
  FOR EACH ttTitle BY ttTitle.id:
   ttTitle.eligible=EligibleOrderTitle(ttTitle.id).
   IF ttTitle.eligible THEN enabledCount=enabledCount + 1.
   RUN CollectLedgerIds('num_id_tit_ap=' + N(ttTitle.id) + ' AND cod_tipo_movto=4').
  END.
  IF enabledCount>0 THEN DO:
   IF NOT Found(phPurchases,'proc_compra_id=' + N(expectedOrder),EXCLUSIVE-LOCK) THEN RUN Fail('ITEMS_FINANCE_CONTEXT','Processo mudou durante coleta.').
   RUN CollectOrderPayments IN phRuntime(phPurchases,OUTPUT paymentRows).
   RUN ValidatePaymentRows('O',expectedOrder,paymentRows).
  END.
 END.
 FOR EACH ttLedgerId BY ttLedgerId.id:
  IF NOT Found(phLedger,'cta_corren_fornec_imp_id=' + N(ttLedgerId.id),EXCLUSIVE-LOCK) THEN RUN Fail('ITEMS_FINANCE_DATA','Historico alterado durante coleta.').
  CREATE ttHistory. ASSIGN ttHistory.id=ttLedgerId.id ttHistory.kind=I(phLedger,'cod_tipo_movto') ttHistory.supplier=I(phLedger,'fornecedor_id')
   ttHistory.titleKey=I(phLedger,'num_id_tit_ap') ttHistory.purchaseId=I(phLedger,'item_proc_compra_id') ttHistory.itemId=I(phLedger,'item_container_id') ttHistory.amount=D(phLedger,'vl_lancto').
 END.
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 FIND ttOrder WHERE ttOrder.id=expectedOrder.
 IF ttOrder.enabled THEN DO:
 RUN GroupHistory(3,0,0).
 FOR EACH ttGroup WHERE ttGroup.purchaseId=expectedItem BY ttGroup.supplier BY ttGroup.titleKey BY ttGroup.itemId:
  IF ttGroup.titleKey<>0 OR ttGroup.itemId<>0 THEN RUN Fail('ITEMS_FINANCE_AMBIGUOUS','Obrigacao tipo3 possui vinculo inesperado.').
  IF ttGroup.supplier=ttOrder.supplier THEN ownBalance=ownBalance + ttGroup.amount.
  ELSE RUN AddPlan(3,ttGroup.supplier,0,expectedItem,0,- ttGroup.amount,3,'Estorno da obrigacao anterior do item ' + N(expectedItem)).
 END.
 delta=ROUND(obligation - ownBalance,2).
 RUN AddPlan(3,ttOrder.supplier,0,expectedItem,0,delta,IF delta<0 THEN 3 ELSE IF operationName='purchase-item-create' THEN 1 ELSE 2,'Diferenca da obrigacao do item ' + N(expectedItem)).
 END.
 IF operationName='purchase-item-delete' THEN DO:
  RUN GroupHistory(4,0,0).
  FOR EACH ttGroup WHERE ttGroup.purchaseId=expectedItem BY ttGroup.supplier BY ttGroup.titleKey BY ttGroup.itemId:
   RUN AddPlan(4,ttGroup.supplier,ttGroup.titleKey,expectedItem,ttGroup.itemId,- ttGroup.amount,3,'Estorno de pagamento por exclusao do item ' + N(expectedItem)).
  END.
 END.
 RUN AllocateOrder.
 IF planCount>2000 THEN RUN Fail('ITEMS_FINANCE_LIMIT','Mais de2000efeitos do item.').
 RUN PersistPlans.
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('changes',changes). poResponse:Add('warnings',warnings).
 FINALLY: RUN CloseQuery(INPUT-OUTPUT q). END FINALLY.
END PROCEDURE.
