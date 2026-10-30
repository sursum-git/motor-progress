/* Closed reusable header transaction owner. Finance arithmetic belongs to the
   existing item financial participant. Read pages use CiwErpReadService. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSuppliers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDependencies AS HANDLE EXTENT 4 NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/PurchaseOrderSnapshot.i}
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE actor AS CHARACTER NO-UNDO.
DEFINE VARIABLE submittedStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ORDER_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE v AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeImage AS JsonObject NO-UNDO.
DEFINE VARIABLE afterImage AS JsonObject NO-UNDO.
DEFINE VARIABLE dataRow AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE effect AS JsonObject NO-UNDO.
DEFINE VARIABLE financial AS JsonObject NO-UNDO.
DEFINE VARIABLE ctx AS JsonObject NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE oldFlag AS LOGICAL NO-UNDO.
DEFINE VARIABLE newFlag AS LOGICAL NO-UNDO.
DEFINE VARIABLE writeComplete AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER(n AS INTEGER): RETURN TRIM(STRING(n,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER st AS INTEGER NO-UNDO.
 code=c. statusCode=st. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Objeto obrigatorio.',422).
 ns=o:GetNames(). DO j=1 TO EXTENT(ns):
  matched=FALSE. DO k=1 TO NUM-ENTRIES(allowed): IF COMPARE(ns[j],'=',ENTRY(k,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN RUN Fail('PURCHASE_ORDER_FIELD_INVALID','Campo nao permitido.',422).
 END.
END PROCEDURE.
FUNCTION Id RETURNS INTEGER(o AS JsonObject,nameValue AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT o:Has(nameValue) THEN RUN Fail('PURCHASE_ORDER_VALIDATION','ID obrigatorio.',422).
 IF o:GetType(nameValue)=JsonDataType:STRING THEN rawValue=o:GetCharacter(nameValue).
 ELSE IF o:GetType(nameValue)=JsonDataType:NUMBER THEN rawValue=STRING(o:GetJsonText(nameValue)).
 ELSE RUN Fail('PURCHASE_ORDER_VALIDATION','ID inteiro obrigatorio.',422).
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','ID invalido.',422).
 DO k=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,k,1))=0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','ID inteiro obrigatorio.',422). END.
 d=DECIMAL(rawValue). IF d<1 OR d>2147483647 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','ID fora da faixa.',422). RETURN INTEGER(d).
END FUNCTION.
FUNCTION Found RETURNS LOGICAL(h AS HANDLE,predicate AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE ok AS LOGICAL NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 ok=h:FIND-FIRST('WHERE ' + predicate,lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail('PURCHASE_ORDER_BUSY','Registro em uso.',409).
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN RUN Fail('PURCHASE_ORDER_QUERY','Leitura nao confirmada.',503). END.
 RETURN ok.
END FUNCTION.
PROCEDURE ResolveCompany:
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 DEFINE VARIABLE c AS INTEGER NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(phCompanies). q:QUERY-PREPARE('FOR EACH ' + phCompanies:NAME + ' WHERE cod_emp_ems2=5').
 q:QUERY-OPEN(). q:GET-FIRST(lockMode,NO-WAIT) NO-ERROR.
 DO WHILE NOT q:QUERY-OFF-END:
  IF phCompanies:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_ORDER_BUSY','Empresa em uso.',409).
  c=c + 1. companyId=phCompanies:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
  IF c>1 OR phCompanies:BUFFER-FIELD('cod_emp_ems5'):BUFFER-VALUE<>500 THEN RUN Fail('PURCHASE_ORDER_COMPANY','Cadastro MED ausente ou ambiguo.',422).
  q:GET-NEXT(lockMode,NO-WAIT) NO-ERROR.
 END. DELETE OBJECT q. q=?.
 IF c<>1 OR companyId=? OR companyId<1 THEN RUN Fail('PURCHASE_ORDER_COMPANY','Cadastro MED ausente ou ambiguo.',422).
END PROCEDURE.
PROCEDURE ValidateValues:
 DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO. DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE d AS DATE NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 RUN Closed(v,'cod_situacao,cod_proc_fornec,qt_dias_translado,observacao,dt_registro,fornecedor_id,dt_limite,log_facilid_contato_fornec,log_considerar_previsao,nr_container_original').
 EXTENT(names)=?. names=v:GetNames().
 DO i=1 TO EXTENT(names):
  nameValue=names[i].
  IF v:IsNull(nameValue) THEN DO:
   IF LOOKUP(nameValue,'dt_registro,dt_limite')>0 OR (op='update' AND nameValue<>'fornecedor_id') THEN NEXT.
   RUN Fail('PURCHASE_ORDER_VALIDATION','Valor desconhecido nao permitido na inclusao.',422).
  END.
  CASE nameValue:
   WHEN 'fornecedor_id' THEN DO:
    IF v:GetType(nameValue)<>JsonDataType:NUMBER THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Fornecedor numerico obrigatorio.',422).
    IF Id(v,nameValue)<1 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Fornecedor invalido.',422).
   END.
   WHEN 'cod_situacao' OR WHEN 'qt_dias_translado' THEN DO:
    IF v:GetType(nameValue)<>JsonDataType:NUMBER THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Inteiro obrigatorio.',422).
    rawValue=STRING(v:GetJsonText(nameValue)).
    IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>4 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Inteiro fora do limite.',422).
    DO j=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,j,1))=0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Inteiro sem fracao obrigatorio.',422). END.
    IF nameValue='cod_situacao' AND LOOKUP(rawValue,'0,1,2,3')=0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Situacao invalida.',422).
   END.
   WHEN 'log_facilid_contato_fornec' OR WHEN 'log_considerar_previsao' THEN IF v:GetType(nameValue)<>JsonDataType:BOOLEAN THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Booleano obrigatorio.',422).
   WHEN 'dt_registro' OR WHEN 'dt_limite' THEN IF NOT v:IsNull(nameValue) THEN DO:
    IF v:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Data ISO obrigatoria.',422).
    rawValue=v:GetCharacter(nameValue).
    IF LENGTH(rawValue)<>10 OR SUBSTRING(rawValue,5,1)<>'-' OR SUBSTRING(rawValue,8,1)<>'-' THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Data ISO obrigatoria.',422).
    d=DATE(INTEGER(SUBSTRING(rawValue,6,2)),INTEGER(SUBSTRING(rawValue,9,2)),INTEGER(SUBSTRING(rawValue,1,4))) NO-ERROR.
    IF ERROR-STATUS:ERROR OR d=? OR ISO-DATE(d)<>rawValue THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Data civil invalida.',422).
   END.
   OTHERWISE DO:
    IF v:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Texto obrigatorio.',422).
    rawValue=v:GetCharacter(nameValue).
    IF LENGTH(rawValue)>(IF nameValue='observacao' THEN 16000 ELSE IF nameValue='cod_proc_fornec' THEN 100 ELSE 20) THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Texto excedeu limite.',422).
    IF nameValue='nr_container_original' THEN DO j=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,j,1))=0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Container original aceita apenas digitos.',422). END.
   END.
  END CASE.
 END.
END PROCEDURE.
PROCEDURE ApplyValues:
 DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE d AS DATE NO-UNDO. DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO.
 DO i=1 TO EXTENT(names):
  f=phOrders:BUFFER-FIELD(names[i]).
  IF v:IsNull(names[i]) THEN f:BUFFER-VALUE=?.
  ELSE CASE f:DATA-TYPE:
   WHEN 'INTEGER' THEN f:BUFFER-VALUE=v:GetInteger(names[i]).
   WHEN 'CHARACTER' THEN f:BUFFER-VALUE=v:GetCharacter(names[i]).
   WHEN 'LOGICAL' THEN f:BUFFER-VALUE=v:GetLogical(names[i]).
   WHEN 'DATE' THEN DO: rawValue=v:GetCharacter(names[i]). d=DATE(INTEGER(SUBSTRING(rawValue,6,2)),INTEGER(SUBSTRING(rawValue,9,2)),INTEGER(SUBSTRING(rawValue,1,4))). f:BUFFER-VALUE=d. END.
  END CASE.
 END.
END PROCEDURE.
PROCEDURE NoLedgerOrLinks:
 IF Found(phLinks,'proc_compra_id=' + N(pid),SHARE-LOCK) THEN RUN Fail('PURCHASE_ORDER_DEPENDENCY','Fornecedor possui pagamentos associados.',409).
 CREATE QUERY q. q:SET-BUFFERS(phPurchaseItems). q:QUERY-PREPARE('FOR EACH ' + phPurchaseItems:NAME + ' WHERE proc_compra_id=' + N(pid)). q:QUERY-OPEN(). q:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
 DO WHILE NOT q:QUERY-OFF-END:
  IF phPurchaseItems:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_ORDER_BUSY','Itens em uso.',409).
  IF Found(phLedger,'item_proc_compra_id=' + N(INTEGER(phPurchaseItems:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE)),SHARE-LOCK) THEN RUN Fail('PURCHASE_ORDER_DEPENDENCY','Fornecedor possui lancamentos anteriores; migracao nao autorizada.',409).
  q:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
 END. DELETE OBJECT q. q=?.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,'operation,id,proc_compra_id,row_stamp,values').
 IF poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Operacao obrigatoria.',422).
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'get,create,update,delete')=0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Operacao invalida.',422).
 IF op='create' THEN DO:
  IF poRequest:Has('id') OR poRequest:Has('proc_compra_id') OR poRequest:Has('row_stamp') THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Inclusao nao recebe identidade.',422).
 END.
 ELSE DO:
  pid=IF poRequest:Has('id') THEN Id(poRequest,'id') ELSE Id(poRequest,'proc_compra_id').
  IF poRequest:Has('proc_compra_id') THEN IF Id(poRequest,'proc_compra_id')<>pid THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Alias divergente.',422).
  IF op<>'get' THEN DO:
   IF NOT poRequest:Has('row_stamp') OR poRequest:GetType('row_stamp')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Imagem original obrigatoria.',422).
   submittedStamp=poRequest:GetCharacter('row_stamp'). IF LENGTH(submittedStamp)<>64 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Hash invalido.',422).
   DO i=1 TO 64: IF INDEX('0123456789ABCDEF',SUBSTRING(submittedStamp,i,1))=0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Hash invalido.',422). END.
  END.
 END.
 IF op='get' THEN DO:
  IF poRequest:Has('values') OR poRequest:Has('row_stamp') THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Consulta nao recebe valores.',422).
  RUN ResolveCompany(NO-LOCK).
  IF NOT Found(phOrders,'proc_compra_id=' + N(pid) + ' AND empresa_id=' + N(companyId),NO-LOCK) THEN RUN Fail('PURCHASE_ORDER_NOT_FOUND','Pedido MED nao encontrado.',404).
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',PurchaseOrderData(phOrders)). RETURN.
 END.
 IF TRANSACTION THEN RUN Fail('PURCHASE_ORDER_TRANSACTION','Transacao raiz propria obrigatoria.',409).
 actor=poPolicy:GetJsonObject('actor'):GetCharacter('login'). IF actor=? OR TRIM(actor)='' OR LENGTH(actor)>128 THEN RUN Fail('PURCHASE_ORDER_IDENTITY','Ator autenticado obrigatorio.',401).
 IF NOT VALID-HANDLE(phRuntime) THEN RUN Fail('PURCHASE_ORDER_CONFIGURATION','Runtime obrigatorio.',503).
 IF op='delete' THEN DO: IF poRequest:Has('values') THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Exclusao nao recebe valores.',422). END.
 ELSE DO: v=poRequest:GetJsonObject('values'). RUN ValidateValues. END.
 beforeImage=NEW JsonObject(). afterImage=NEW JsonObject(). changes=NEW JsonArray(). warnings=NEW JsonArray().
 DO STOP-AFTER 20 ON STOP UNDO, LEAVE:
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN ResolveCompany(IF op='create' THEN EXCLUSIVE-LOCK ELSE SHARE-LOCK).
  IF op='create' THEN DO:
   IF LOOKUP('NextOrderId',phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_ORDER_CONFIGURATION','Alocador privado ausente.',503).
   code='PURCHASE_ORDER_SEQUENCE'. statusCode=503. RUN NextOrderId IN phRuntime(OUTPUT pid).
   code='PURCHASE_ORDER_VALIDATION'. statusCode=422.
   IF pid=? OR pid<1 OR Found(phOrders,'proc_compra_id=' + N(pid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ORDER_IDENTITY','ID retornado ocupado ou invalido.',409).
   IF NOT phOrders:BUFFER-CREATE() THEN RUN Fail('PURCHASE_ORDER_WRITE','Inclusao recusada.',422).
   ASSIGN phOrders:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE=pid phOrders:BUFFER-FIELD('empresa_id'):BUFFER-VALUE=companyId
    phOrders:BUFFER-FIELD('qt_container'):BUFFER-VALUE=0 phOrders:BUFFER-FIELD('cotacao_prevista'):BUFFER-VALUE=0
    phOrders:BUFFER-FIELD('cod_situacao'):BUFFER-VALUE=1 phOrders:BUFFER-FIELD('qt_dias_translado'):BUFFER-VALUE=0
    phOrders:BUFFER-FIELD('log_facilid_contato_fornec'):BUFFER-VALUE=TRUE phOrders:BUFFER-FIELD('log_considerar_previsao'):BUFFER-VALUE=TRUE.
  END.
  ELSE DO:
   IF NOT Found(phOrders,'proc_compra_id=' + N(pid) + ' AND empresa_id=' + N(companyId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ORDER_NOT_FOUND','Pedido MED nao encontrado.',404).
   beforeImage=PurchaseOrderSnapshot(phOrders).
   IF NOT COMPARE(PurchaseOrderStamp(beforeImage),'=',submittedStamp,'RAW') THEN RUN Fail('PURCHASE_ORDER_CHANGED','Pedido alterado; recarregue.',409).
  END.
  IF op='delete' THEN DO:
   DO i=1 TO 4:
    IF NOT VALID-HANDLE(phDependencies[i]) THEN RUN Fail('PURCHASE_ORDER_CONFIGURATION','Dependencia fisica ausente.',503).
    IF Found(phDependencies[i],'proc_compra_id=' + N(pid),SHARE-LOCK) THEN RUN Fail('PURCHASE_ORDER_DEPENDENCY','Pedido possui dependencias; exclusao bloqueada.',409).
   END.
   IF NOT phOrders:BUFFER-DELETE() THEN RUN Fail('PURCHASE_ORDER_WRITE','Exclusao recusada.',422).
  END.
  ELSE DO:
   DO i=1 TO EXTENT(names):
    IF v:IsNull(names[i]) AND LOOKUP(names[i],'dt_registro,dt_limite')=0 AND phOrders:BUFFER-FIELD(names[i]):BUFFER-VALUE<>? THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Somente desconhecido preexistente pode ser preservado.',422).
   END.
   IF v:Has('cod_situacao') THEN IF NOT v:IsNull('cod_situacao') THEN IF v:GetInteger('cod_situacao')=0 THEN DO:
    IF op='create' THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Nova situacao deve ser1,2ou3.',422).
    IF beforeImage:IsNull('cod_situacao') OR beforeImage:GetInteger('cod_situacao')<>0 THEN RUN Fail('PURCHASE_ORDER_VALIDATION','Transicao para situacao0 nao permitida.',422).
   END.
   oldFlag=IF op='create' THEN ? ELSE phOrders:BUFFER-FIELD('log_considerar_previsao'):BUFFER-VALUE.
   IF op='update' AND v:Has('fornecedor_id') THEN IF Id(v,'fornecedor_id')<>INTEGER(phOrders:BUFFER-FIELD('fornecedor_id'):BUFFER-VALUE) THEN RUN NoLedgerOrLinks.
   RUN ApplyValues.
   IF phOrders:BUFFER-FIELD('fornecedor_id'):BUFFER-VALUE=? OR INTEGER(phOrders:BUFFER-FIELD('fornecedor_id'):BUFFER-VALUE)<1 OR NOT Found(phSuppliers,'cod-emitente=' + N(INTEGER(phOrders:BUFFER-FIELD('fornecedor_id'):BUFFER-VALUE)),SHARE-LOCK) THEN RUN Fail('PURCHASE_ORDER_SUPPLIER','Fornecedor ERP inexistente.',422).
   IF NOT phOrders:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_ORDER_WRITE','Cabecalho recusado.',422).
   newFlag=phOrders:BUFFER-FIELD('log_considerar_previsao'):BUFFER-VALUE.
   IF op='update' AND NOT (oldFlag=? AND newFlag=?) AND newFlag<>oldFlag THEN DO:
    IF oldFlag=? OR newFlag=? OR LOOKUP('RunOrderForecast',phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_ORDER_CONFIGURATION','Transicao financeira indefinida.',422).
    ctx=NEW JsonObject(). ctx:Add('operation',IF newFlag THEN 'order-enable' ELSE 'order-disable'). ctx:Add('proc_compra_id',pid).
    RUN RunOrderForecast IN phRuntime(phOrders,ctx,OUTPUT financial).
    IF NOT VALID-OBJECT(financial) OR NOT financial:GetLogical('success') THEN RUN Fail('PURCHASE_ORDER_FINANCIAL','Reconstrucao financeira recusada.',422).
    changes=CAST(financial:GetJsonArray('changes'):Clone(),JsonArray). warnings=CAST(financial:GetJsonArray('warnings'):Clone(),JsonArray).
    IF changes:Length>2000 THEN RUN Fail('PURCHASE_ORDER_LIMIT','Mais de2000efeitos.',422).
    IF NOT Found(phOrders,'proc_compra_id=' + N(pid) + ' AND empresa_id=' + N(companyId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ORDER_CHANGED','Pedido perdeu contexto.',409).
   END.
   afterImage=PurchaseOrderSnapshot(phOrders). dataRow=PurchaseOrderData(phOrders).
  END.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE). IF op<>'delete' THEN poResponse:Add('data',dataRow).
  audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction'). audit:Add('resource','procs-compra'). audit:Add('operation',op). audit:Add('recordId',pid).
  effect=NEW JsonObject(). effect:Add('login',actor). audit:Add('actor',effect). audit:Add('before',beforeImage). audit:Add('after',afterImage). audit:Add('changes',changes). audit:Add('warnings',warnings). poResponse:Add('audit',audit).
 END.
 writeComplete=TRUE.
 END.
 IF NOT writeComplete THEN RUN Fail('PURCHASE_ORDER_TIMEOUT','Transacao excedeu o prazo; alteracoes desfeitas.',503).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). effect=NEW JsonObject(). effect:Add('code',code). effect:Add('status',statusCode). effect:Add('message',e:GetMessage(1)). poResponse:Add('success',FALSE). poResponse:Add('error',effect).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. END FINALLY.
END.

