/* Server-owned composition. Item maintenance owns the transaction. Fiscal,
   payment currency conversion and supplier allocations stay reusable services. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phFiscalRules AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phBaseRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phMaster AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrderPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainerPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTitAp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phValTitAp AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poFinancePolicy AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/ContainerBufferSibling.i}
DEFINE TEMP-TABLE ttCurrencyLinks NO-UNDO FIELD container_id AS INTEGER FIELD num_id_tit_ap AS INTEGER
 INDEX pk IS PRIMARY UNIQUE container_id num_id_tit_ap.
DEFINE VARIABLE financePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE paymentPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE currentContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE selectedOrderTitle AS INTEGER NO-UNDO.
DEFINE VARIABLE refreshingOrderContainers AS LOGICAL NO-UNDO.
DEFINE VARIABLE orderForecastActive AS LOGICAL NO-UNDO.
DEFINE VARIABLE purchaseItemFiscal AS LOGICAL NO-UNDO.
DEFINE TEMP-TABLE ttRefreshContainers NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
ASSIGN financePath=SEARCH("sursum-api/programs/ContainersItensFinanceiroService.r")
 paymentPath=SEARCH("sursum-api/programs/ContainersPagamentoTotalsService.r").
IF financePath=? THEN financePath=SEARCH("ContainersItensFinanceiroService.r").
IF paymentPath=? THEN paymentPath=SEARCH("ContainersPagamentoTotalsService.r").

PROCEDURE RequireTransaction:
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_TRANSACTION_CONTEXT: composicao de itens requer transacao raiz.",1).
END PROCEDURE.
PROCEDURE GetCapabilities:
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscal AS JsonObject NO-UNDO.
 DEFINE VARIABLE ready AS LOGICAL NO-UNDO.
 IF VALID-HANDLE(phFiscalRules) THEN DO:
  IF phFiscalRules:TYPE="PROCEDURE" AND LOOKUP("GetCapabilities",phFiscalRules:INTERNAL-ENTRIES)>0 THEN DO:
   RUN GetCapabilities IN phFiscalRules(OUTPUT fiscal).
   IF VALID-OBJECT(fiscal) THEN ready=fiscal:GetCharacter("contract")="container-rules-v1" AND fiscal:GetLogical("onUpdate").
  END.
 END.
 result=NEW JsonObject(). result:Add("contract","container-item-rules-v1").
 result:Add("afterChange",ready AND financePath<>? AND paymentPath<>?). result:Add("nextItemId",TRUE).
END PROCEDURE.
PROCEDURE NextItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 valueId=DYNAMIC-NEXT-VALUE("seq_itens_container","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_SEQUENCE_UNAVAILABLE: sequencia de itens indisponivel.",1).
END PROCEDURE.
PROCEDURE NextLedgerId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 valueId=DYNAMIC-NEXT-VALUE("seq_cta_corren_fornec_imp","espec").
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_SEQUENCE_UNAVAILABLE: sequencia financeira indisponivel.",1).
END PROCEDURE.
/* Purchase-item identity is a separate fixed persistent sequence. No fallback
   to MAX/live rows or to order/container/ledger sequences is allowed. */
PROCEDURE NextPurchaseItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE allocatorPath AS CHARACTER NO-UNDO.
 RUN RequireTransaction.
 allocatorPath=SEARCH('sursum-api/programs/PurchaseItemIdService.r'). IF allocatorPath=? THEN allocatorPath=SEARCH('PurchaseItemIdService.r').
 IF allocatorPath=? THEN UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: alocador de item nao publicado.',1).
 RUN VALUE(allocatorPath)(phPurchaseItems,THIS-PROCEDURE,OUTPUT valueId).
END PROCEDURE.
PROCEDURE NextRawPurchaseItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 DO ON ERROR UNDO, THROW:
  valueId=DYNAMIC-NEXT-VALUE('seq_itens_proc_compra','espec').
  IF valueId=? OR valueId<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Sequencia de item esgotada ou ausente.',1).
  CATCH e AS Progress.Lang.Error:
   UNDO, THROW NEW Progress.Lang.AppError('PURCHASE_ITEM_SEQUENCE_CONFIGURATION: seq_itens_proc_compra ausente, esgotada ou invalida; inclusao bloqueada.',1).
  END CATCH.
 END.
END PROCEDURE.
PROCEDURE NextOrderId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE allocatorPath AS CHARACTER NO-UNDO.
 RUN RequireTransaction.
 allocatorPath=SEARCH('sursum-api/programs/PurchaseOrderIdService.r'). IF allocatorPath=? THEN allocatorPath=SEARCH('PurchaseOrderIdService.r').
 IF allocatorPath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Alocador de identidade nao publicado.',1).
 RUN VALUE(allocatorPath)(phPurchases,THIS-PROCEDURE,OUTPUT valueId).
END PROCEDURE.
PROCEDURE NextRawOrderId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 valueId=DYNAMIC-NEXT-VALUE('seq_procs_compra','espec').
 IF valueId=? OR valueId<=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Sequencia de processos indisponivel.',1).
END PROCEDURE.
PROCEDURE AfterChange:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscalCtx AS JsonObject NO-UNDO.
 DEFINE VARIABLE fiscal AS JsonObject NO-UNDO.
 DEFINE VARIABLE financial AS JsonObject NO-UNDO.
 DEFINE VARIABLE financialPolicy AS JsonObject NO-UNDO.
 DEFINE VARIABLE changes AS JsonArray NO-UNDO.
 DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF NOT VALID-HANDLE(master) OR NOT VALID-OBJECT(ctx) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: contexto ausente.",1).
 IF NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre nao localizado.",1).
 currentContainer=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
 IF currentContainer<>ctx:GetInteger("container_id") OR NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN
  UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: contexto do mestre divergente ou em uso.",1).
 IF financePath=? OR paymentPath=? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: composicao financeira nao publicada.",1).
 fiscalCtx=NEW JsonObject(). fiscalCtx:Add("operation","update"). fiscalCtx:Add("container_id",currentContainer).
 RUN OnUpdate IN phFiscalRules(master,fiscalCtx,OUTPUT fiscal).
 IF NOT VALID-OBJECT(fiscal) OR NOT fiscal:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: sincronizacao fiscal recusada.",1).
 RUN RunFinancial(master,ctx,OUTPUT financial).
 changes=CAST(fiscal:GetJsonArray("changes"):Clone(),JsonArray). warnings=NEW JsonArray().
 DO n=1 TO financial:GetJsonArray("changes"):Length: changes:Add(CAST(financial:GetJsonArray("changes"):GetJsonObject(n):Clone(),JsonObject)). END.
 IF fiscal:Has("warnings") THEN DO n=1 TO fiscal:GetJsonArray("warnings"):Length: warnings:Add(fiscal:GetJsonArray("warnings"):GetCharacter(n)). END.
 IF financial:Has("warnings") THEN DO n=1 TO financial:GetJsonArray("warnings"):Length:
  IF financial:GetJsonArray("warnings"):GetType(n)=JsonDataType:OBJECT THEN warnings:Add(financial:GetJsonArray("warnings"):GetJsonObject(n):GetCharacter("message")).
  ELSE warnings:Add(financial:GetJsonArray("warnings"):GetCharacter(n)).
 END.
 result=NEW JsonObject(). result:Add("success",TRUE). result:Add("changes",changes). result:Add("warnings",warnings).
END PROCEDURE.
PROCEDURE RunFinancial:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE actorPolicy AS JsonObject NO-UNDO.
 RUN RequireTransaction.
 IF NOT master:AVAILABLE OR NOT VALID-OBJECT(ctx) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: mestre/contexto financeiro ausente.",1).
 currentContainer=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
 IF currentContainer<>ctx:GetInteger("container_id") OR NOT master:FIND-BY-ROWID(master:ROWID,EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: contexto financeiro divergente ou em uso.",1).
 IF financePath=? OR paymentPath=? THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: composicao financeira nao publicada.",1).
 actorPolicy=NEW JsonObject(). actorPolicy:Add("actor",CAST(poPolicy:GetJsonObject("actor"):Clone(),JsonObject)).
 RUN VALUE(financePath)(phItems,phPurchaseItems,phPurchases,phLedger,phOrderPayments,phContainerPayments,phAllContainers,THIS-PROCEDURE,actorPolicy,ctx,OUTPUT result).
 IF NOT VALID-OBJECT(result) OR NOT result:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_UNAVAILABLE: rateios financeiros recusados.",1).
END PROCEDURE.
PROCEDURE CollectContainerPayments:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE source AS HANDLE NO-UNDO.
 RUN RequireTransaction.
 IF NOT master:AVAILABLE OR master:BUFFER-FIELD("nr-container"):BUFFER-VALUE<>currentContainer THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: pagamentos de outro container.",1).
 RUN ContainerCreateSiblingBuffer(phContainerPayments,"bItemsCurrencyContainerLinks",OUTPUT source).
 DO ON ERROR UNDO, THROW:
  RUN PrepareLinks(source,"container_id",currentContainer,OUTPUT q).
  RUN ReadCurrencyRows(OUTPUT rows).
  FINALLY:
   IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
   IF VALID-HANDLE(source) THEN DELETE OBJECT source NO-ERROR.
  END FINALLY.
 END.
END PROCEDURE.
PROCEDURE CollectOrderPayments:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE source AS HANDLE NO-UNDO.
 DEFINE VARIABLE orderId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF NOT purchase:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_RULE_CONTEXT: pedido de compra nao localizado.",1).
 orderId=purchase:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE.
 RUN ContainerCreateSiblingBuffer(phOrderPayments,"bItemsCurrencyOrderLinks",OUTPUT source).
 DO ON ERROR UNDO, THROW:
  RUN PrepareLinks(source,"proc_compra_id",orderId,OUTPUT q).
  RUN ReadCurrencyRows(OUTPUT rows).
  FINALLY:
   IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
   IF VALID-HANDLE(source) THEN DELETE OBJECT source NO-ERROR.
  END FINALLY.
 END.
END PROCEDURE.
PROCEDURE PrepareLinks:
 DEFINE INPUT PARAMETER source AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER fk AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER valueId AS INTEGER NO-UNDO.
 DEFINE OUTPUT PARAMETER q AS HANDLE NO-UNDO.
 EMPTY TEMP-TABLE ttCurrencyLinks.
 CREATE QUERY q. q:SET-BUFFERS(source).
 IF NOT q:QUERY-PREPARE("FOR EACH " + source:NAME + " WHERE " + source:NAME + "." + fk + "=" + TRIM(STRING(valueId,"->>>>>>>>>9"))) THEN
  UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_CONFIGURATION: consulta fixa de pagamentos invalida.",1).
 q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
 DO WHILE NOT q:QUERY-OFF-END:
  IF source:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: vinculo financeiro em uso.",1).
  IF (selectedOrderTitle=0 OR selectedOrderTitle=source:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE) AND NOT CAN-FIND(FIRST ttCurrencyLinks WHERE ttCurrencyLinks.container_id=currentContainer AND ttCurrencyLinks.num_id_tit_ap=source:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE) THEN DO:
   CREATE ttCurrencyLinks. ASSIGN ttCurrencyLinks.container_id=currentContainer ttCurrencyLinks.num_id_tit_ap=source:BUFFER-FIELD("num_id_tit_ap"):BUFFER-VALUE.
  END.
  q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
 END.
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("CONTAINER_BUSY: leitura financeira nao confirmada.",1).
END PROCEDURE.
PROCEDURE ReadCurrencyRows:
 DEFINE OUTPUT PARAMETER rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE response AS JsonObject NO-UNDO.
 DEFINE VARIABLE policy AS JsonObject NO-UNDO.
 DEFINE VARIABLE paymentMaster AS HANDLE NO-UNDO.
 RUN RequireTransaction.
 IF orderForecastActive THEN RUN LockForecastTitles.
 /* Same central conversion used by cost/version collection; adapters only
    normalize trusted link FKs. Do not infer currency from the payment grid. */
 policy=CAST(poFinancePolicy:Clone(),JsonObject). policy:Add("capture_rows",TRUE).
 RUN ContainerCreateSiblingBuffer(IF refreshingOrderContainers THEN phAllContainers ELSE phMaster,"bItemsCurrencyMaster",OUTPUT paymentMaster).
 DO ON ERROR UNDO, THROW:
  RUN VALUE(paymentPath)(INPUT paymentMaster,INPUT BUFFER ttCurrencyLinks:HANDLE,INPUT phTitAp,INPUT phValTitAp,INPUT policy,INPUT currentContainer,OUTPUT response).
  IF NOT response:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError(response:GetJsonObject("error"):GetCharacter("code") + ": " + response:GetJsonObject("error"):GetCharacter("message"),1).
  rows=CAST(response:GetJsonObject("data"):GetJsonArray("payment_rows"):Clone(),JsonArray).
  FINALLY:
   IF VALID-HANDLE(paymentMaster) THEN DELETE OBJECT paymentMaster NO-ERROR.
   IF VALID-OBJECT(policy) THEN DELETE OBJECT policy NO-ERROR.
   IF VALID-OBJECT(response) THEN DELETE OBJECT response NO-ERROR.
  END FINALLY.
 END.
END PROCEDURE.

/* Shared financial participant for a purchase-owned transaction. The master
   passed by this private adapter is a one-row TT currency owner, never a DB
   container. Normalizing FK to that TT reuses the existing currency collector. */
PROCEDURE RunOrderFinancial:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE actorPolicy AS JsonObject NO-UNDO.
 DEFINE VARIABLE previousOwner AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF NOT purchase:AVAILABLE OR purchase:BUFFER-FIELD("proc_compra_id"):BUFFER-VALUE<>ctx:GetInteger("proc_compra_id") THEN UNDO, THROW NEW Progress.Lang.AppError("Pedido/contexto financeiro divergente.",1).
 IF financePath=? OR paymentPath=? THEN UNDO, THROW NEW Progress.Lang.AppError("Composicao financeira nao publicada.",1).
 previousOwner=currentContainer. currentContainer=1.
 IF ctx:GetCharacter("operation")="order-associate" THEN selectedOrderTitle=ctx:GetJsonObject("after"):GetInteger("num_id_tit_ap").
 ELSE selectedOrderTitle=ctx:GetJsonObject("before"):GetInteger("num_id_tit_ap").
 actorPolicy=NEW JsonObject(). actorPolicy:Add("actor",CAST(poPolicy:GetJsonObject("actor"):Clone(),JsonObject)).
 RUN VALUE(financePath)(phItems,phPurchaseItems,phPurchases,phLedger,phOrderPayments,phContainerPayments,phAllContainers,THIS-PROCEDURE,actorPolicy,ctx,OUTPUT result).
 IF NOT VALID-OBJECT(result) OR NOT result:GetLogical("success") THEN UNDO, THROW NEW Progress.Lang.AppError("Rateio do pedido recusado.",1).
 FINALLY:
  currentContainer=previousOwner. selectedOrderTitle=0.
  IF VALID-OBJECT(actorPolicy) THEN DELETE OBJECT actorPolicy NO-ERROR.
 END FINALLY.
END PROCEDURE.
/* Shared forecast reconstruction. The header owner supplies the transaction;
   collection and all arithmetic remain in the existing financial participant. */
PROCEDURE RunOrderForecast:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE actorPolicy AS JsonObject NO-UNDO.
 DEFINE VARIABLE previousOwner AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 IF NOT purchase:AVAILABLE OR purchase:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE<>ctx:GetInteger('proc_compra_id') THEN UNDO, THROW NEW Progress.Lang.AppError('Pedido/contexto de previsao divergente.',1).
 IF financePath=? OR paymentPath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Composicao financeira nao publicada.',1).
 previousOwner=currentContainer. currentContainer=1. selectedOrderTitle=0. orderForecastActive=TRUE.
 actorPolicy=NEW JsonObject(). actorPolicy:Add('actor',CAST(poPolicy:GetJsonObject('actor'):Clone(),JsonObject)).
 RUN VALUE(financePath)(phItems,phPurchaseItems,phPurchases,phLedger,phOrderPayments,phContainerPayments,phAllContainers,THIS-PROCEDURE,actorPolicy,ctx,OUTPUT result).
 FINALLY:
  currentContainer=previousOwner. selectedOrderTitle=0. refreshingOrderContainers=FALSE. orderForecastActive=FALSE.
  IF VALID-OBJECT(actorPolicy) THEN DELETE OBJECT actorPolicy NO-ERROR.
 END FINALLY.
END PROCEDURE.
PROCEDURE RefreshOrderContainers:
 DEFINE INPUT PARAMETER orderId AS INTEGER NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE purchaseItems AS HANDLE NO-UNDO.
 DEFINE VARIABLE items AS HANDLE NO-UNDO.
 DEFINE VARIABLE oq AS HANDLE NO-UNDO.
 DEFINE VARIABLE iq AS HANDLE NO-UNDO.
 DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE ctx AS JsonObject NO-UNDO.
 DEFINE VARIABLE r AS JsonObject NO-UNDO.
 DEFINE VARIABLE a AS JsonArray NO-UNDO.
 DEFINE VARIABLE changes AS JsonArray NO-UNDO.
 DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 RUN RequireTransaction. EMPTY TEMP-TABLE ttRefreshContainers.
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 RUN ContainerCreateSiblingBuffer(phPurchaseItems,'bForecastPurchaseItems',OUTPUT purchaseItems).
 RUN ContainerCreateSiblingBuffer(phItems,'bForecastContainerItems',OUTPUT items).
 CREATE QUERY oq. oq:SET-BUFFERS(purchaseItems). oq:QUERY-PREPARE('FOR EACH ' + purchaseItems:NAME + ' WHERE proc_compra_id=' + TRIM(STRING(orderId,'->>>>>>>>>9'))).
 oq:QUERY-OPEN(). oq:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
 DO WHILE NOT oq:QUERY-OFF-END:
  IF purchaseItems:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Itens do pedido em uso.',1).
  itemId=purchaseItems:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE.
  CREATE QUERY iq. iq:SET-BUFFERS(items). iq:QUERY-PREPARE('FOR EACH ' + items:NAME + ' WHERE item_proc_compra_id=' + TRIM(STRING(itemId,'->>>>>>>>>9'))).
  iq:QUERY-OPEN(). iq:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  DO WHILE NOT iq:QUERY-OFF-END:
   IF items:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Alocacoes do pedido em uso.',1).
   cid=items:BUFFER-FIELD('container_id'):BUFFER-VALUE.
   IF cid=? OR cid<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Container alocado invalido.',1).
   IF NOT CAN-FIND(ttRefreshContainers WHERE ttRefreshContainers.id=cid) THEN DO: CREATE ttRefreshContainers. ttRefreshContainers.id=cid. END.
   iq:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
  END. DELETE OBJECT iq. iq=?.
  oq:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
 END. DELETE OBJECT oq. oq=?.
 refreshingOrderContainers=TRUE.
 FOR EACH ttRefreshContainers BY ttRefreshContainers.id:
  IF NOT phAllContainers:FIND-FIRST('WHERE nr-container=' + TRIM(STRING(ttRefreshContainers.id,'->>>>>>>>>9')),EXCLUSIVE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError('Container alocado ausente ou em uso.',1).
  ctx=NEW JsonObject(). ctx:Add('operation','refresh-container'). ctx:Add('container_id',ttRefreshContainers.id).
  IF purchaseItemFiscal THEN DO:
   IF NOT VALID-HANDLE(phFiscalRules) THEN UNDO, THROW NEW Progress.Lang.AppError('Regras fiscais de item ausentes.',1).
   RUN AfterChange(phAllContainers,ctx,OUTPUT r).
  END.
  ELSE RUN RunFinancial(phAllContainers,ctx,OUTPUT r).
  a=r:GetJsonArray('changes'). DO j=1 TO a:Length: changes:Add(CAST(a:GetJsonObject(j):Clone(),JsonObject)). END.
  a=r:GetJsonArray('warnings'). DO j=1 TO a:Length:
   IF a:GetType(j)=JsonDataType:OBJECT THEN warnings:Add(CAST(a:GetJsonObject(j):Clone(),JsonObject)). ELSE warnings:Add(a:GetCharacter(j)).
  END.
  IF changes:Length>2000 THEN UNDO, THROW NEW Progress.Lang.AppError('Mais de2000efeitos em containers relacionados.',1).
 END.
 result=NEW JsonObject(). result:Add('success',TRUE). result:Add('changes',changes). result:Add('warnings',warnings).
 FINALLY:
  refreshingOrderContainers=FALSE.
  IF VALID-HANDLE(iq) THEN DELETE OBJECT iq NO-ERROR.
  IF VALID-HANDLE(oq) THEN DELETE OBJECT oq NO-ERROR.
  IF VALID-HANDLE(items) THEN DELETE OBJECT items NO-ERROR.
  IF VALID-HANDLE(purchaseItems) THEN DELETE OBJECT purchaseItems NO-ERROR.
 END FINALLY.
END PROCEDURE.
/* Serialize forecast reads against payment association and ERP title changes.
   Buffers are read/locked only; no EMS5 field is assigned. */
PROCEDURE LockForecastTitles:
 DEFINE VARIABLE b AS HANDLE NO-UNDO. DEFINE VARIABLE vals AS HANDLE NO-UNDO.
 DEFINE VARIABLE tq AS HANDLE NO-UNDO. DEFINE VARIABLE vq AS HANDLE NO-UNDO.
 DEFINE VARIABLE countValue AS INTEGER NO-UNDO.
 RUN ContainerCreateSiblingBuffer(phTitAp,'bForecastTitleMutex',OUTPUT b).
 RUN ContainerCreateSiblingBuffer(phValTitAp,'bForecastCurrencyMutex',OUTPUT vals).
 FOR EACH ttCurrencyLinks BY ttCurrencyLinks.num_id_tit_ap:
  countValue=0. CREATE QUERY tq. tq:SET-BUFFERS(b).
  IF NOT tq:QUERY-PREPARE('FOR EACH ' + b:NAME + ' WHERE num_id_tit_ap=' + TRIM(STRING(ttCurrencyLinks.num_id_tit_ap,'->>>>>>>>>9'))) THEN UNDO, THROW NEW Progress.Lang.AppError('Consulta de mutex invalida.',1).
  tq:QUERY-OPEN(). tq:GET-FIRST(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  DO WHILE NOT tq:QUERY-OFF-END:
   IF b:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Titulo da previsao em uso.',1).
   countValue=countValue + 1. IF countValue>1 THEN UNDO, THROW NEW Progress.Lang.AppError('Titulo da previsao globalmente ambiguo.',1).
   tq:GET-NEXT(EXCLUSIVE-LOCK,NO-WAIT) NO-ERROR.
  END. DELETE OBJECT tq. tq=?.
  IF countValue<>1 THEN UNDO, THROW NEW Progress.Lang.AppError('Titulo da previsao ausente.',1).
  CREATE QUERY vq. vq:SET-BUFFERS(vals).
  IF NOT vq:QUERY-PREPARE('FOR EACH ' + vals:NAME + ' WHERE num_id_tit_ap=' + TRIM(STRING(ttCurrencyLinks.num_id_tit_ap,'->>>>>>>>>9'))) THEN UNDO, THROW NEW Progress.Lang.AppError('Consulta de valores invalida.',1).
  vq:QUERY-OPEN(). vq:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
  DO WHILE NOT vq:QUERY-OFF-END:
   IF vals:LOCKED OR ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Valores da previsao em uso.',1).
   vq:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
  END. DELETE OBJECT vq. vq=?.
 END.
 FINALLY:
  IF VALID-HANDLE(tq) THEN DELETE OBJECT tq NO-ERROR.
  IF VALID-HANDLE(vq) THEN DELETE OBJECT vq NO-ERROR.
  IF VALID-HANDLE(b) THEN DELETE OBJECT b NO-ERROR.
  IF VALID-HANDLE(vals) THEN DELETE OBJECT vals NO-ERROR.
 END FINALLY.
END PROCEDURE.

PROCEDURE RunPurchaseItemChange:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE actorPolicy AS JsonObject NO-UNDO.
 DEFINE VARIABLE financeResult AS JsonObject NO-UNDO.
 DEFINE VARIABLE refreshResult AS JsonObject NO-UNDO.
 DEFINE VARIABLE changes AS JsonArray NO-UNDO.
 DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
 DEFINE VARIABLE a AS JsonArray NO-UNDO.
 DEFINE VARIABLE e AS JsonObject NO-UNDO.
 DEFINE VARIABLE metadata AS JsonObject NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE priorOwner AS INTEGER NO-UNDO.
 DEFINE VARIABLE orderId AS INTEGER NO-UNDO.
 DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
 RUN RequireTransaction.
 orderId=ctx:GetInteger('proc_compra_id'). itemId=ctx:GetInteger('item_proc_compra_id').
 IF NOT purchase:AVAILABLE OR purchase:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE<>orderId THEN UNDO, THROW NEW Progress.Lang.AppError('Contexto de item/processo divergente.',1).
 IF financePath=? OR paymentPath=? OR NOT VALID-HANDLE(phFiscalRules) THEN UNDO, THROW NEW Progress.Lang.AppError('Composicao de item nao publicada.',1).
 priorOwner=currentContainer. currentContainer=1. selectedOrderTitle=0. orderForecastActive=TRUE.
 actorPolicy=NEW JsonObject(). actorPolicy:Add('actor',CAST(poPolicy:GetJsonObject('actor'):Clone(),JsonObject)).
 RUN VALUE(financePath)(phItems,phPurchaseItems,phPurchases,phLedger,phOrderPayments,phContainerPayments,phAllContainers,THIS-PROCEDURE,actorPolicy,ctx,OUTPUT financeResult).
 IF NOT VALID-OBJECT(financeResult) OR NOT financeResult:GetLogical('success') THEN UNDO, THROW NEW Progress.Lang.AppError('Financeiro incremental recusado.',1).
 changes=CAST(financeResult:GetJsonArray('changes'):Clone(),JsonArray). warnings=CAST(financeResult:GetJsonArray('warnings'):Clone(),JsonArray).
 purchaseItemFiscal=TRUE.
 RUN RefreshOrderContainers(orderId,OUTPUT refreshResult).
 IF NOT VALID-OBJECT(refreshResult) OR NOT refreshResult:GetLogical('success') THEN UNDO, THROW NEW Progress.Lang.AppError('Reconciliacao fiscal/financeira recusada.',1).
 a=refreshResult:GetJsonArray('changes'). DO j=1 TO a:Length: changes:Add(CAST(a:GetJsonObject(j):Clone(),JsonObject)). END.
 a=refreshResult:GetJsonArray('warnings'). DO j=1 TO a:Length:
  IF a:GetType(j)=JsonDataType:OBJECT THEN warnings:Add(CAST(a:GetJsonObject(j):Clone(),JsonObject)). ELSE warnings:Add(a:GetCharacter(j)).
 END.
 IF changes:Length>2000 THEN UNDO, THROW NEW Progress.Lang.AppError('Mais de2000efeitos do item.',1).
 DO j=1 TO changes:Length:
  e=changes:GetJsonObject(j).
  IF e:GetCharacter('resource')='cta_corren_fornec_imp' THEN DO:
   RUN PurchaseLedgerOwner(e:GetJsonObject('before')). RUN PurchaseLedgerOwner(e:GetJsonObject('after')).
  END.
  IF e:Has('metadata') THEN metadata=e:GetJsonObject('metadata'). ELSE DO: metadata=NEW JsonObject(). e:Add('metadata',metadata). END.
  IF metadata:Has('originProcCompraId') THEN metadata:Set('originProcCompraId',orderId). ELSE metadata:Add('originProcCompraId',orderId).
  IF metadata:Has('originItemProcCompraId') THEN metadata:Set('originItemProcCompraId',itemId). ELSE metadata:Add('originItemProcCompraId',itemId).
 END.
 result=NEW JsonObject(). result:Add('success',TRUE). result:Add('changes',changes). result:Add('warnings',warnings).
 FINALLY:
  currentContainer=priorOwner. selectedOrderTitle=0. orderForecastActive=FALSE. refreshingOrderContainers=FALSE. purchaseItemFiscal=FALSE.
 END FINALLY.
END PROCEDURE.

/* Synthetic purchase ownership is derived from each real ledger item, including
   effects on a different purchase sharing a refreshed container. */
PROCEDURE PurchaseLedgerOwner:
 DEFINE INPUT PARAMETER image AS JsonObject NO-UNDO.
 DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE b AS HANDLE NO-UNDO.
 DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
 DEFINE VARIABLE ownerId AS INTEGER NO-UNDO.
 ns=image:GetNames(). IF EXTENT(ns)=? OR EXTENT(ns)=0 THEN RETURN.
 itemId=image:GetInteger('item_proc_compra_id').
 IF itemId<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Ledger sem item proprietario real.',1).
 RUN ContainerCreateSiblingBuffer(phPurchaseItems,'bPurchaseItemAuditOwner',OUTPUT b).
 IF NOT b:FIND-FIRST('WHERE item_proc_compra_id=' + TRIM(STRING(itemId,'->>>>>>>>>9')),SHARE-LOCK,NO-WAIT) THEN UNDO, THROW NEW Progress.Lang.AppError('Proprietario real do ledger ausente ou em uso.',1).
 ownerId=b:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
 IF ownerId=? OR ownerId<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Processo real do ledger ausente.',1).
 IF image:Has('proc_compra_id') THEN DO:
  IF image:GetInteger('proc_compra_id')<>ownerId THEN UNDO, THROW NEW Progress.Lang.AppError('Proprietario do ledger diverge da imagem.',1).
 END.
 ELSE image:Add('proc_compra_id',ownerId).
 FINALLY: IF VALID-HANDLE(b) THEN DELETE OBJECT b NO-ERROR. END FINALLY.
END PROCEDURE.
