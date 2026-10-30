/* Purchase-payment transaction owner. Currency and type4 accounting are shared
   with container programs; no title EMS5 field is ever assigned. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phPurchases AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLinks AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phTitles AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phValues AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poFinancePolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/ContainerPaymentIdentity.i}
{sursum-api/includes/ContainerBufferSibling.i}
DEFINE TEMP-TABLE ttSelection NO-UNDO FIELD id AS INTEGER INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttAvailable NO-UNDO FIELD id AS INTEGER FIELD titleRow AS ROWID FIELD occurrences AS INTEGER
 INDEX pk IS UNIQUE PRIMARY id.
DEFINE TEMP-TABLE ttCurrencyOwner NO-UNDO FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttCurrencyLink NO-UNDO FIELD container_id AS INTEGER FIELD num_id_tit_ap AS INTEGER INDEX pk IS UNIQUE PRIMARY container_id num_id_tit_ap.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE eid AS INTEGER NO-UNDO.
DEFINE VARIABLE supplier AS INTEGER NO-UNDO.
DEFINE VARIABLE companyCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE registrationDate AS DATE NO-UNDO.
DEFINE VARIABLE tid AS INTEGER NO-UNDO.
DEFINE VARIABLE titleEstab AS CHARACTER NO-UNDO.
DEFINE VARIABLE selectedKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_PAYMENT_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE actorName AS CHARACTER NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE scanTitle AS HANDLE NO-UNDO.
DEFINE VARIABLE currencyTitle AS HANDLE NO-UNDO.
DEFINE VARIABLE listTitle AS HANDLE NO-UNDO.
DEFINE VARIABLE allLinks AS HANDLE NO-UNDO.
DEFINE VARIABLE resultRows AS JsonArray NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE warnings AS JsonArray NO-UNDO.
DEFINE VARIABLE selected AS JsonArray NO-UNDO.
DEFINE VARIABLE valuesObject AS JsonObject NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE beforeData AS JsonObject NO-UNDO.
DEFINE VARIABLE afterData AS JsonObject NO-UNDO.
DEFINE VARIABLE firstBefore AS JsonObject NO-UNDO.
DEFINE VARIABLE firstAfter AS JsonObject NO-UNDO.
DEFINE VARIABLE contextData AS JsonObject NO-UNDO.
DEFINE VARIABLE financial AS JsonObject NO-UNDO.
DEFINE VARIABLE audit AS JsonObject NO-UNDO.
DEFINE VARIABLE eventData AS JsonObject NO-UNDO.
DEFINE VARIABLE firstKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE currencyPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE vr AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE vd AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
DEFINE VARIABLE originalId AS ROWID NO-UNDO.
DEFINE VARIABLE readComplete AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER (v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER st AS INTEGER NO-UNDO.
 code=c. statusCode=st. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Objeto obrigatorio.',422).
 names=o:GetNames(). DO k=1 TO EXTENT(names): IF LOOKUP(names[k],allowed)=0 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Campo nao permitido.',422). END.
END PROCEDURE.
FUNCTION IdText RETURNS INTEGER (rawText AS CHARACTER):
 DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE v AS DECIMAL NO-UNDO.
 IF LENGTH(rawText)<1 OR LENGTH(rawText)>10 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','ID invalido.',422).
 DO k=1 TO LENGTH(rawText): IF INDEX('0123456789',SUBSTRING(rawText,k,1))=0 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','ID deve ser inteiro.',422). END.
 v=DECIMAL(rawText). IF v<1 OR v>2147483647 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','ID fora da faixa.',422). RETURN INTEGER(v).
END FUNCTION.
FUNCTION Id RETURNS INTEGER (o AS JsonObject,name AS CHARACTER):
 IF NOT o:Has(name) OR o:GetType(name)<>JsonDataType:NUMBER THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','ID numerico obrigatorio.',422).
 RETURN IdText(STRING(o:GetJsonText(name))).
END FUNCTION.
FUNCTION Found RETURNS LOGICAL (h AS HANDLE,conditionText AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE foundValue AS LOGICAL NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
 foundValue=h:FIND-FIRST('WHERE ' + conditionText,lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail('PURCHASE_PAYMENT_BUSY','Registro em uso.',409).
 DO k=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(k)<>565 THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta nao confirmada.',503). END.
 RETURN foundValue.
END FUNCTION.
PROCEDURE ResolveParent:
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 IF NOT Found(phPurchases,phPurchases:NAME + '.proc_compra_id=' + N(pid),lockMode) THEN RUN Fail('PURCHASE_NOT_FOUND','Processo de compra nao encontrado.',404).
 eid=phPurchases:BUFFER-FIELD('empresa_id'):BUFFER-VALUE. supplier=phPurchases:BUFFER-FIELD('fornecedor_id'):BUFFER-VALUE.
 registrationDate=phPurchases:BUFFER-FIELD('dt_registro'):BUFFER-VALUE.
 IF eid=? OR eid<1 OR supplier=? OR supplier<1 THEN RUN Fail('PURCHASE_PAYMENT_PARENT_INVALID','Empresa/fornecedor do pedido invalidos.',422).
 IF NOT Found(phCompanies,phCompanies:NAME + '.empresa_id=' + N(eid),IF lockMode=NO-LOCK THEN NO-LOCK ELSE SHARE-LOCK) THEN RUN Fail('PURCHASE_PAYMENT_COMPANY','Empresa do pedido nao encontrada.',422).
 IF phCompanies:BUFFER-FIELD('cod_emp_ems2'):BUFFER-VALUE<>5 THEN RUN Fail('PURCHASE_PAYMENT_COMPANY','Esta consulta esta disponivel inicialmente para MED.',422).
 IF phCompanies:BUFFER-FIELD('cod_emp_ems5'):BUFFER-VALUE=? THEN RUN Fail('PURCHASE_PAYMENT_COMPANY','Codigo EMS5 ausente.',422).
 companyCode=N(INTEGER(phCompanies:BUFFER-FIELD('cod_emp_ems5'):BUFFER-VALUE)).
END PROCEDURE.
PROCEDURE ResolveTitle:
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 DEFINE VARIABLE tq AS HANDLE NO-UNDO. DEFINE VARIABLE total AS INTEGER NO-UNDO. DEFINE VARIABLE rowId AS ROWID NO-UNDO. DEFINE VARIABLE lockedValue AS LOGICAL NO-UNDO.
 CREATE QUERY tq. tq:SET-BUFFERS(scanTitle).
 IF NOT tq:QUERY-PREPARE('FOR EACH ' + scanTitle:NAME + ' WHERE num_id_tit_ap=' + N(tid) + ' NO-LOCK') THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta de titulo invalida.',503).
 tq:QUERY-OPEN(). tq:GET-FIRST(NO-LOCK).
 DO WHILE NOT tq:QUERY-OFF-END AND total<2: total=total  +  1. rowId=scanTitle:ROWID. tq:GET-NEXT(NO-LOCK). END.
 IF total=0 THEN RUN Fail('PURCHASE_PAYMENT_TITLE_NOT_FOUND','Titulo nao encontrado.',404).
 IF total<>1 THEN RUN Fail('PURCHASE_PAYMENT_AMBIGUOUS','ID de titulo ambiguo entre estabelecimentos.',422).
 lockedValue=phTitles:FIND-BY-ROWID(rowId,lockMode,NO-WAIT) NO-ERROR.
 IF NOT lockedValue OR ERROR-STATUS:ERROR OR phTitles:LOCKED THEN RUN Fail('PURCHASE_PAYMENT_BUSY','Titulo em uso ou alterado.',409).
 IF phTitles:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE<>tid THEN RUN Fail('PURCHASE_PAYMENT_BUSY','Titulo mudou durante a consulta.',409).
 titleEstab=phTitles:BUFFER-FIELD('cod_estab'):BUFFER-VALUE.
 IF titleEstab=? OR titleEstab='' THEN RUN Fail('PURCHASE_PAYMENT_TITLE_INVALID','Estabelecimento ausente.',422).
 FINALLY: IF VALID-HANDLE(tq) THEN DELETE OBJECT tq NO-ERROR. END FINALLY.
END PROCEDURE.
FUNCTION Eligible RETURNS LOGICAL ():
 IF phTitles:BUFFER-FIELD('cod_empresa'):BUFFER-VALUE=? OR phTitles:BUFFER-FIELD('cdn_fornecedor'):BUFFER-VALUE=? OR phTitles:BUFFER-FIELD('cod_empresa'):BUFFER-VALUE<>companyCode OR phTitles:BUFFER-FIELD('cdn_fornecedor'):BUFFER-VALUE<>supplier THEN RETURN FALSE.
 IF phTitles:BUFFER-FIELD('log_tit_ap_estordo'):BUFFER-VALUE=? OR phTitles:BUFFER-FIELD('log_tit_ap_estordo'):BUFFER-VALUE<>FALSE THEN RETURN FALSE.
 IF SUBSTRING(STRING(phTitles:BUFFER-FIELD('ind_tip_espec_docto'):BUFFER-VALUE),1,8)<>'antecipa' THEN RETURN FALSE.
 IF registrationDate<>? AND (phTitles:BUFFER-FIELD('dat_emis_docto'):BUFFER-VALUE=? OR phTitles:BUFFER-FIELD('dat_emis_docto'):BUFFER-VALUE<registrationDate) THEN RETURN FALSE.
 RETURN TRUE.
END FUNCTION.
PROCEDURE GlobalOwner:
 DEFINE INPUT PARAMETER creating AS LOGICAL NO-UNDO.
 DEFINE VARIABLE lq AS HANDLE NO-UNDO. DEFINE VARIABLE total AS INTEGER NO-UNDO. DEFINE VARIABLE owner AS INTEGER NO-UNDO.
 CREATE QUERY lq. lq:SET-BUFFERS(allLinks).
 IF NOT lq:QUERY-PREPARE('FOR EACH ' + allLinks:NAME + ' WHERE num_id_tit_ap=' + N(tid)) THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta de vinculos invalida.',503).
 lq:QUERY-OPEN(). lq:GET-FIRST(SHARE-LOCK,NO-WAIT) NO-ERROR.
 DO WHILE NOT lq:QUERY-OFF-END:
  IF allLinks:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_PAYMENT_BUSY','Vinculos em uso.',409).
  total=total  +  1. owner=allLinks:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.
  IF total>1 THEN RUN Fail('PURCHASE_PAYMENT_AMBIGUOUS','Titulo associado a mais de um pedido.',409).
  lq:GET-NEXT(SHARE-LOCK,NO-WAIT) NO-ERROR.
 END.
 IF creating AND total>0 THEN RUN Fail('PURCHASE_PAYMENT_EXISTS','Titulo ja associado a um processo de compra.',409).
 IF NOT creating AND (total<>1 OR owner<>pid) THEN RUN Fail('PURCHASE_PAYMENT_AMBIGUOUS','Dono do titulo divergente.',409).
 FINALLY: IF VALID-HANDLE(lq) THEN DELETE OBJECT lq NO-ERROR. END FINALLY.
END PROCEDURE.
PROCEDURE Currency:
 DEFINE VARIABLE policy AS JsonObject NO-UNDO. DEFINE VARIABLE response AS JsonObject NO-UNDO.
 EMPTY TEMP-TABLE ttCurrencyLink. CREATE ttCurrencyLink. ASSIGN ttCurrencyLink.container_id=1 ttCurrencyLink.num_id_tit_ap=tid.
 policy=CAST(poFinancePolicy:Clone(),JsonObject). policy:Add('capture_rows',TRUE).
 RUN VALUE(currencyPath)(INPUT BUFFER ttCurrencyOwner:HANDLE,INPUT BUFFER ttCurrencyLink:HANDLE,currencyTitle,phValues,policy,1,OUTPUT response).
 IF NOT response:GetLogical('success') THEN RUN Fail('PURCHASE_PAYMENT_CURRENCY',response:GetJsonObject('error'):GetCharacter('message'),422).
 vr=response:GetJsonObject('data'):GetJsonObject('payments'):GetDecimal('real'). vd=response:GetJsonObject('data'):GetJsonObject('payments'):GetDecimal('dolar').
 FINALLY:
  IF VALID-OBJECT(policy) THEN DELETE OBJECT policy NO-ERROR.
  IF VALID-OBJECT(response) THEN DELETE OBJECT response NO-ERROR.
 END FINALLY.
END PROCEDURE.
FUNCTION TitleRow RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE a AS JsonArray NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE name AS CHARACTER NO-UNDO.
 RUN Currency. o=NEW JsonObject(). o:Add('proc_compra_id',pid). o:Add('empresa_id',eid). o:Add('pagamento_key',ContainerPaymentKey(pid,titleEstab,tid)).
 DO k=1 TO NUM-ENTRIES('num_id_tit_ap,cod_empresa,cod_estab,cod_espec_docto,cod_ser_docto,cdn_fornecedor,cod_tit_ap,cod_parcela,dat_emis_docto,dat_vencto_tit_ap,cod_indic_econ,val_origin_tit_ap'):
  name=ENTRY(k,'num_id_tit_ap,cod_empresa,cod_estab,cod_espec_docto,cod_ser_docto,cdn_fornecedor,cod_tit_ap,cod_parcela,dat_emis_docto,dat_vencto_tit_ap,cod_indic_econ,val_origin_tit_ap'). f=phTitles:BUFFER-FIELD(name).
  IF f:BUFFER-VALUE=? THEN o:AddNull(name).
  ELSE CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN o:Add(name,STRING(f:BUFFER-VALUE)).
   WHEN 'INTEGER' THEN o:Add(name,INTEGER(f:BUFFER-VALUE)).
   WHEN 'DECIMAL' THEN o:Add(name,DECIMAL(f:BUFFER-VALUE)).
   WHEN 'DATE' THEN o:Add(name,ISO-DATE(DATE(f:BUFFER-VALUE))).
   OTHERWISE RUN Fail('PURCHASE_PAYMENT_SCHEMA','Campo de titulo inesperado.',503).
  END CASE.
 END.
 o:Add('valor_real',vr). o:Add('valor_dolar',vd). a=NEW JsonArray(). a:Add(tid). o:Add('titulos',a). RETURN o.
END FUNCTION.
PROCEDURE AddEvent:
 DEFINE INPUT PARAMETER resource AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER action AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER id AS CHARACTER NO-UNDO.
 eventData=NEW JsonObject(). eventData:Add('resource',resource). eventData:Add('operation',action). eventData:Add('recordId',id).
 eventData:Add('before',beforeData). eventData:Add('after',afterData). changes:Add(eventData).
END PROCEDURE.
PROCEDURE ReadAvailable:
 DEFINE VARIABLE tq AS HANDLE NO-UNDO.
 DEFINE VARIABLE candidateId AS INTEGER NO-UNDO.
 /* The physical EMS5 key starts with cod_estab. Resolving each numeric ID
    separately would scan the whole title table once per option. */
 CREATE QUERY tq. tq:SET-BUFFERS(listTitle).
 IF NOT tq:QUERY-PREPARE('FOR EACH ' + listTitle:NAME + ' WHERE cod_empresa=' + QUOTER(companyCode) + ' AND cdn_fornecedor=' + N(supplier) + ' AND log_tit_ap_estordo=FALSE AND SUBSTRING(ind_tip_espec_docto,1,8)=' + QUOTER('antecipa') + (IF registrationDate=? THEN '' ELSE ' AND dat_emis_docto>=DATE(' + N(MONTH(registrationDate)) + ',' + N(DAY(registrationDate)) + ',' + N(YEAR(registrationDate)) + ')') + ' NO-LOCK') THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta de disponiveis invalida.',503).
 tq:QUERY-OPEN(). tq:GET-FIRST(NO-LOCK).
 DO WHILE NOT tq:QUERY-OFF-END:
  candidateId=listTitle:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE.
  IF candidateId=? OR candidateId<1 THEN RUN Fail('PURCHASE_PAYMENT_TITLE_INVALID','ID de titulo invalido.',422).
  IF NOT Found(phLinks,phLinks:NAME + '.num_id_tit_ap=' + N(candidateId),NO-LOCK) THEN DO:
   IF CAN-FIND(ttAvailable WHERE ttAvailable.id=candidateId) THEN RUN Fail('PURCHASE_PAYMENT_AMBIGUOUS','ID de titulo ambiguo entre estabelecimentos.',422).
   countRows=countRows + 1.
   IF countRows>1000 THEN RUN Fail('PURCHASE_PAYMENT_TOO_MANY','Mais de1000titulos no contexto. Refine o processo de compra.',422).
   CREATE ttAvailable. ASSIGN ttAvailable.id=candidateId ttAvailable.titleRow=listTitle:ROWID.
  END.
  tq:GET-NEXT(NO-LOCK).
 END.
 DELETE OBJECT tq. tq=?.
 IF CAN-FIND(FIRST ttAvailable) THEN DO:
  /* One global pass also catches collisions outside company/supplier/date. */
  CREATE QUERY tq. tq:SET-BUFFERS(scanTitle).
  IF NOT tq:QUERY-PREPARE('FOR EACH ' + scanTitle:NAME + ' NO-LOCK') THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta global de titulos invalida.',503).
  tq:QUERY-OPEN(). tq:GET-FIRST(NO-LOCK).
  DO WHILE NOT tq:QUERY-OFF-END:
   candidateId=scanTitle:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE.
   FIND ttAvailable WHERE ttAvailable.id=candidateId NO-ERROR.
   IF AVAILABLE ttAvailable THEN DO:
    ttAvailable.occurrences=ttAvailable.occurrences + 1.
    IF ttAvailable.occurrences>1 THEN RUN Fail('PURCHASE_PAYMENT_AMBIGUOUS','ID de titulo ambiguo entre estabelecimentos.',422).
   END.
   tq:GET-NEXT(NO-LOCK).
  END.
  DELETE OBJECT tq. tq=?.
 END.
 FOR EACH ttAvailable BY ttAvailable.id:
  tid=ttAvailable.id.
  IF ttAvailable.occurrences<>1 OR NOT phTitles:FIND-BY-ROWID(ttAvailable.titleRow,NO-LOCK,NO-WAIT) THEN RUN Fail('PURCHASE_PAYMENT_BUSY','Titulo mudou durante a consulta.',409).
  IF phTitles:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE<>tid OR NOT Eligible() OR Found(phLinks,phLinks:NAME + '.num_id_tit_ap=' + N(tid),NO-LOCK) THEN RUN Fail('PURCHASE_PAYMENT_BUSY','Contexto do titulo mudou durante a consulta.',409).
  titleEstab=phTitles:BUFFER-FIELD('cod_estab'):BUFFER-VALUE.
  IF titleEstab=? OR titleEstab='' THEN RUN Fail('PURCHASE_PAYMENT_TITLE_INVALID','Estabelecimento ausente.',422).
  rowData=NEW JsonObject(). rowData:Add('num_id_tit_ap',tid). rowData:Add('descricao',STRING(phTitles:BUFFER-FIELD('cod_tit_ap'):BUFFER-VALUE) + ' / ' + titleEstab + ' / ' + ISO-DATE(DATE(phTitles:BUFFER-FIELD('dat_emis_docto'):BUFFER-VALUE))). resultRows:Add(rowData).
 END.
 FINALLY: IF VALID-HANDLE(tq) THEN DELETE OBJECT tq NO-ERROR. END FINALLY.
END PROCEDURE.
PROCEDURE ReadRows:
 DEFINE VARIABLE tq AS HANDLE NO-UNDO. DEFINE VARIABLE isLinked AS LOGICAL NO-UNDO. DEFINE VARIABLE hasLink AS LOGICAL NO-UNDO. DEFINE VARIABLE seen AS JsonObject NO-UNDO.
 resultRows=NEW JsonArray(). seen=NEW JsonObject().
 IF op='available' THEN DO:
  RUN ReadAvailable.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',resultRows). poResponse:Add('total',resultRows:Length). RETURN.
 END.
 ELSE DO:
  CREATE QUERY tq. tq:SET-BUFFERS(allLinks).
  IF NOT tq:QUERY-PREPARE('FOR EACH ' + allLinks:NAME + ' WHERE proc_compra_id=' + N(pid) + ' NO-LOCK BY num_id_tit_ap') THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta de vinculos invalida.',503).
  tq:QUERY-OPEN(). tq:GET-FIRST(NO-LOCK).
 END.
 DO WHILE NOT tq:QUERY-OFF-END:
  IF op='available' THEN tid=INTEGER(listTitle:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE). ELSE tid=INTEGER(allLinks:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE).
  /* A separate cursor is required: ResolveTitle must not move this scan. */
  RUN ResolveTitle(NO-LOCK).
  hasLink=Found(phLinks,phLinks:NAME + '.num_id_tit_ap=' + N(tid),NO-LOCK).
  IF op<>'available' OR NOT hasLink THEN DO:
   IF seen:Has(N(tid)) THEN RUN Fail('PURCHASE_PAYMENT_AMBIGUOUS','Titulo repetido no conjunto.',422).
   seen:Add(N(tid),TRUE). countRows=countRows  +  1.
   IF countRows>1000 THEN RUN Fail('PURCHASE_PAYMENT_TOO_MANY','Mais de1000titulos no contexto. Refine o processo de compra.',422).
   IF op='available' THEN DO:
    rowData=NEW JsonObject(). rowData:Add('num_id_tit_ap',tid). rowData:Add('descricao',STRING(phTitles:BUFFER-FIELD('cod_tit_ap'):BUFFER-VALUE) + ' / ' + titleEstab + ' / ' + ISO-DATE(DATE(phTitles:BUFFER-FIELD('dat_emis_docto'):BUFFER-VALUE))). resultRows:Add(rowData).
   END.
   ELSE DO:
    rowData=TitleRow().
    IF op='get' THEN DO: IF rowData:GetCharacter('pagamento_key')=selectedKey THEN resultRows:Add(rowData). END.
    ELSE resultRows:Add(rowData).
   END.
  END.
  tq:GET-NEXT(NO-LOCK).
 END.
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE).
 IF op='get' THEN DO: IF resultRows:Length<>1 THEN RUN Fail('PURCHASE_PAYMENT_NOT_FOUND','Vinculo nao encontrado neste processo.',404). poResponse:Add('data',resultRows:GetJsonObject(1)). END.
 ELSE DO: poResponse:Add('data',resultRows). poResponse:Add('total',resultRows:Length). END.
 FINALLY:
  IF VALID-HANDLE(tq) THEN DELETE OBJECT tq NO-ERROR.
  IF VALID-OBJECT(seen) THEN DELETE OBJECT seen NO-ERROR.
 END FINALLY.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,'operation,proc_compra_id,id,pagamento_key,values').
 IF poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Operacao obrigatoria.',422).
 op=poRequest:GetCharacter('operation'). pid=Id(poRequest,'proc_compra_id').
 IF LOOKUP(op,'read,get,available,create,delete')=0 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Operacao nao suportada.',422).
 currencyPath=SEARCH('sursum-api/programs/ContainersPagamentoTotalsService.r'). IF currencyPath=? THEN currencyPath=SEARCH('ContainersPagamentoTotalsService.r').
 IF currencyPath=? THEN RUN Fail('PURCHASE_PAYMENT_CONFIGURATION','Coletor de moedas nao publicado.',503).
 CREATE ttCurrencyOwner. ttCurrencyOwner.nr-container=1.
 RUN ContainerCreateSiblingBuffer(phTitles,'bPurchaseTitleIdentity',OUTPUT scanTitle).
 RUN ContainerCreateSiblingBuffer(phTitles,'bPurchaseCurrencyTitle',OUTPUT currencyTitle).
 RUN ContainerCreateSiblingBuffer(phTitles,'bPurchaseListTitle',OUTPUT listTitle).
 RUN ContainerCreateSiblingBuffer(phLinks,'bPurchaseAllLinks',OUTPUT allLinks).
 IF op='delete' OR op='get' THEN DO:
  IF NOT poRequest:Has('id') OR poRequest:GetType('id')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Chave obrigatoria.',422).
  selectedKey=poRequest:GetCharacter('id'). IF LENGTH(selectedKey)<>66 OR SUBSTRING(selectedKey,1,2)<>'p_' THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Chave invalida.',422).
  DO n=3 TO 66: IF INDEX('0123456789ABCDEF',SUBSTRING(selectedKey,n,1))=0 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Chave invalida.',422). END.
  IF poRequest:Has('pagamento_key') THEN IF NOT COMPARE(poRequest:GetCharacter('pagamento_key'),'=',selectedKey,'RAW') THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Alias da chave divergente.',422).
 END.
 IF op='read' OR op='get' OR op='available' THEN DO:
  IF poRequest:Has('values') THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Consulta nao recebe valores.',422).
  DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
   RUN ResolveParent(NO-LOCK). RUN ReadRows. readComplete=TRUE.
  END.
  IF NOT readComplete THEN RUN Fail('PURCHASE_PAYMENT_QUERY_TIMEOUT','Consulta de pagamentos excedeu o prazo.',503).
  RETURN.
 END.
 IF TRANSACTION THEN RUN Fail('PURCHASE_PAYMENT_TRANSACTION','Transacao raiz propria obrigatoria.',409).
 actorName=poPolicy:GetJsonObject('actor'):GetCharacter('login').
 IF actorName=? OR TRIM(actorName)='' OR LENGTH(actorName)>128 THEN RUN Fail('PURCHASE_PAYMENT_IDENTITY','Usuario autenticado obrigatorio.',401).
 IF NOT VALID-HANDLE(phRuntime) OR LOOKUP('RunOrderFinancial',phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_PAYMENT_CONFIGURATION','Rotina financeira ausente.',503).
 IF op='create' THEN DO:
  valuesObject=poRequest:GetJsonObject('values'). RUN Closed(valuesObject,'titulos'). selected=valuesObject:GetJsonArray('titulos').
  IF selected:Length<1 OR selected:Length>100 THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Selecione1a100titulos.',422).
  DO n=1 TO selected:Length:
   IF selected:GetType(n)<>JsonDataType:NUMBER THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Titulo deve ser inteiro.',422).
   /* GetJsonText is raw JSON: validate lexical integer before conversion. */
   tid=IdText(STRING(selected:GetJsonText(n))).
   IF CAN-FIND(ttSelection WHERE ttSelection.id=tid) THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Titulo repetido.',422).
   CREATE ttSelection. ttSelection.id=tid.
  END.
 END.
 ELSE IF poRequest:Has('values') THEN RUN Fail('PURCHASE_PAYMENT_VALIDATION','Desvinculacao nao recebe valores.',422).
 changes=NEW JsonArray(). warnings=NEW JsonArray().
 DO TRANSACTION ON ERROR UNDO, THROW:
  RUN ResolveParent(EXCLUSIVE-LOCK).
  IF op='delete' THEN DO:
   CREATE QUERY q. q:SET-BUFFERS(allLinks).
   IF NOT q:QUERY-PREPARE('FOR EACH ' + allLinks:NAME + ' WHERE proc_compra_id=' + N(pid) + ' NO-LOCK BY num_id_tit_ap') THEN RUN Fail('PURCHASE_PAYMENT_QUERY','Consulta fixa invalida.',503).
   q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
   DO WHILE NOT q:QUERY-OFF-END:
    tid=allLinks:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE. RUN ResolveTitle(NO-LOCK).
    IF ContainerPaymentKey(pid,titleEstab,tid)=selectedKey THEN DO: CREATE ttSelection. ttSelection.id=tid. LEAVE. END.
    q:GET-NEXT(NO-LOCK).
   END.
   DELETE OBJECT q. q=?.
   IF NOT CAN-FIND(FIRST ttSelection) THEN RUN Fail('PURCHASE_PAYMENT_NOT_FOUND','Vinculo nao encontrado neste processo.',404).
  END.
  FOR EACH ttSelection BY ttSelection.id:
   tid=ttSelection.id. RUN ResolveTitle(EXCLUSIVE-LOCK). RUN GlobalOwner(op='create').
   beforeData=NEW JsonObject(). afterData=NEW JsonObject().
   IF op='create' THEN DO:
    IF NOT Eligible() THEN RUN Fail('PURCHASE_PAYMENT_INELIGIBLE','Titulo de outra empresa/fornecedor, estornado ou anterior ao processo.',422).
    IF NOT phLinks:BUFFER-CREATE() THEN RUN Fail('PURCHASE_PAYMENT_WRITE','Criacao de vinculo recusada.',422).
    ASSIGN phLinks:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE=pid phLinks:BUFFER-FIELD('num_id_tit_ap'):BUFFER-VALUE=tid.
    IF NOT phLinks:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_PAYMENT_WRITE','Vinculo recusado.',422).
    afterData=TitleRow().
   END.
   ELSE DO:
    IF NOT Found(phLinks,phLinks:NAME + '.proc_compra_id=' + N(pid) + ' AND num_id_tit_ap=' + N(tid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_PAYMENT_NOT_FOUND','Vinculo ausente.',404).
    beforeData=TitleRow().
   END.
   RUN AddEvent('purchase_payment_links',op,ContainerPaymentKey(pid,titleEstab,tid)).
   IF firstKey='' THEN DO: firstKey=ContainerPaymentKey(pid,titleEstab,tid). firstBefore=CAST(beforeData:Clone(),JsonObject). firstAfter=CAST(afterData:Clone(),JsonObject). END.
   contextData=NEW JsonObject(). contextData:Add('operation',IF op='create' THEN 'order-associate' ELSE 'order-disassociate'). contextData:Add('proc_compra_id',pid).
   rowData=NEW JsonObject(). rowData:Add('proc_compra_id',pid). rowData:Add('num_id_tit_ap',tid).
   contextData:Add('before',IF op='create' THEN NEW JsonObject() ELSE rowData). contextData:Add('after',IF op='create' THEN rowData ELSE NEW JsonObject()).
   RUN RunOrderFinancial IN phRuntime(phPurchases,contextData,OUTPUT financial).
   IF NOT VALID-OBJECT(financial) OR NOT financial:GetLogical('success') THEN RUN Fail('PURCHASE_PAYMENT_FINANCIAL','Rateio recusado.',422).
   DO n=1 TO financial:GetJsonArray('changes'):Length:
    eventData=financial:GetJsonArray('changes'):GetJsonObject(n).
    IF eventData:GetCharacter('resource')<>'cta_corren_fornec_imp' OR eventData:GetCharacter('operation')<>'create' OR eventData:GetJsonObject('after'):GetInteger('proc_compra_id')<>pid OR eventData:GetJsonObject('after'):GetInteger('num_id_tit_ap')<>tid THEN RUN Fail('PURCHASE_PAYMENT_FINANCIAL','Efeito financeiro fora do contexto.',422).
    changes:Add(CAST(eventData:Clone(),JsonObject)).
   END.
   IF changes:Length>2000 THEN RUN Fail('PURCHASE_PAYMENT_TOO_MANY','Mais de2000efeitos na operacao; reduza a selecao.',422).
   IF op='delete' THEN DO:
    IF NOT Found(phLinks,phLinks:NAME + '.proc_compra_id=' + N(pid) + ' AND num_id_tit_ap=' + N(tid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_PAYMENT_WRITE','Vinculo mudou durante rateio.',409).
    IF NOT phLinks:BUFFER-DELETE() THEN RUN Fail('PURCHASE_PAYMENT_WRITE','Desvinculacao recusada.',422).
   END.
  END.
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE).
  IF op='create' THEN poResponse:Add('data',CAST(firstAfter:Clone(),JsonObject)).
  audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction'). audit:Add('resource','proc-compra-pagamentos'). audit:Add('operation',op).
  audit:Add('recordId',firstKey). audit:Add('proc_compra_id',pid). audit:Add('before',firstBefore). audit:Add('after',firstAfter). audit:Add('changes',changes). audit:Add('warnings',warnings).
  eventData=NEW JsonObject(). eventData:Add('login',actorName). audit:Add('actor',eventData). poResponse:Add('audit',audit).
 END.
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). eventData=NEW JsonObject(). eventData:Add('code',code). eventData:Add('status',statusCode). eventData:Add('message',e:GetMessage(1)). poResponse:Add('success',FALSE). poResponse:Add('error',eventData).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(scanTitle) THEN DELETE OBJECT scanTitle NO-ERROR.
  IF VALID-HANDLE(currencyTitle) THEN DELETE OBJECT currencyTitle NO-ERROR.
  IF VALID-HANDLE(listTitle) THEN DELETE OBJECT listTitle NO-ERROR.
  IF VALID-HANDLE(allLinks) THEN DELETE OBJECT allLinks NO-ERROR.
 END FINALLY.
END.
