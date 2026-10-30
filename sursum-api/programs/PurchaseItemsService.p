/* Contextual purchase item writer. The locked MED parent is the first mutex.
   All physical images and reusable fiscal/financial effects share one root transaction. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phColors AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phFormats AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSeason AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phDependencies AS HANDLE EXTENT 4 NO-UNDO.
DEFINE INPUT PARAMETER phRuntime AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poPolicy AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/PurchaseItemSnapshot.i}
{sursum-api/includes/PurchaseItemValueRules.i}
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE actor AS CHARACTER NO-UNDO.
DEFINE VARIABLE submittedStamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ITEM_VALIDATION'.
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
DEFINE VARIABLE allocated AS DECIMAL NO-UNDO.
DEFINE VARIABLE countRows AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE writeComplete AS LOGICAL NO-UNDO.
DEFINE VARIABLE keepOriginal AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER(n AS INTEGER): RETURN TRIM(STRING(n,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER st AS INTEGER NO-UNDO.
 code=c. statusCode=st. UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER o AS JsonObject NO-UNDO. DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 IF NOT VALID-OBJECT(o) THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Objeto obrigatorio.',422).
 ns=o:GetNames(). DO j=1 TO EXTENT(ns):
  matched=FALSE. DO k=1 TO NUM-ENTRIES(allowed): IF COMPARE(ns[j],'=',ENTRY(k,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN RUN Fail('PURCHASE_ITEM_FIELD_INVALID','Campo nao permitido.',422).
 END.
END PROCEDURE.
FUNCTION Id RETURNS INTEGER(o AS JsonObject,nameValue AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE d AS DECIMAL NO-UNDO.
 IF NOT o:Has(nameValue) THEN RUN Fail('PURCHASE_ITEM_VALIDATION','ID obrigatorio.',422).
 IF o:GetType(nameValue)=JsonDataType:STRING THEN rawValue=o:GetCharacter(nameValue).
 ELSE IF o:GetType(nameValue)=JsonDataType:NUMBER THEN rawValue=STRING(o:GetJsonText(nameValue)).
 ELSE RUN Fail('PURCHASE_ITEM_VALIDATION','ID inteiro obrigatorio.',422).
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','ID invalido.',422).
 DO k=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,k,1))=0 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','ID inteiro obrigatorio.',422). END.
 d=DECIMAL(rawValue). IF d<1 OR d>2147483647 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','ID fora da faixa.',422). RETURN INTEGER(d).
END FUNCTION.
FUNCTION Found RETURNS LOGICAL(h AS HANDLE,predicate AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE ok AS LOGICAL NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 ok=h:FIND-FIRST('WHERE ' + predicate,lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN RUN Fail('PURCHASE_ITEM_BUSY','Registro em uso.',409).
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(j)<>565 THEN RUN Fail('PURCHASE_ITEM_QUERY','Leitura nao confirmada.',503). END.
 RETURN ok.
END FUNCTION.
PROCEDURE ResolveCompany:
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 DEFINE VARIABLE c AS INTEGER NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(phCompanies). q:QUERY-PREPARE('FOR EACH ' + phCompanies:NAME + ' WHERE cod_emp_ems2=5').
 q:QUERY-OPEN(). q:GET-FIRST(lockMode,NO-WAIT) NO-ERROR.
 DO WHILE NOT q:QUERY-OFF-END:
  IF phCompanies:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_ITEM_BUSY','Empresa em uso.',409).
  c=c + 1. companyId=phCompanies:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
  IF c>1 OR phCompanies:BUFFER-FIELD('cod_emp_ems5'):BUFFER-VALUE<>500 THEN RUN Fail('PURCHASE_ITEM_COMPANY','Cadastro MED ausente ou ambiguo.',422).
  q:GET-NEXT(lockMode,NO-WAIT) NO-ERROR.
 END. DELETE OBJECT q. q=?.
 IF c<>1 OR companyId=? OR companyId<1 THEN RUN Fail('PURCHASE_ITEM_COMPANY','Cadastro MED ausente ou ambiguo.',422).
END PROCEDURE.
PROCEDURE ValidateValues:
 DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO. DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE d AS DATE NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE maxLength AS INTEGER NO-UNDO.
 DEFINE VARIABLE nval AS DECIMAL DECIMALS 10 NO-UNDO.
 RUN Closed(v,REPLACE(REPLACE(PurchaseItemFields(),'item_proc_compra_id,',''),'proc_compra_id,','')).
 EXTENT(names)=?. names=v:GetNames().
 DO i=1 TO EXTENT(names):
  nameValue=names[i].
  IF LOOKUP(nameValue,PurchaseItemFields())=0 OR LOOKUP(nameValue,'item_proc_compra_id,proc_compra_id')>0 THEN RUN Fail('PURCHASE_ITEM_FIELD_INVALID','Campo nao editavel.',422).
  f=phItems:BUFFER-FIELD(nameValue).
  IF v:IsNull(nameValue) THEN DO:
   IF f:DATA-TYPE='DATE' OR op='update' AND LOOKUP(nameValue,'descricao,unid_medida')=0 THEN NEXT.
   RUN Fail('PURCHASE_ITEM_VALIDATION','Valor desconhecido nao permitido.',422).
  END.
  CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN DO:
    IF v:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Texto obrigatorio.',422).
    rawValue=v:GetCharacter(nameValue).
    maxLength=0. CASE nameValue: WHEN 'descricao' THEN maxLength=100. WHEN 'codigo_erp' THEN maxLength=20. WHEN 'composicao' THEN maxLength=30. WHEN 'shrinkage' THEN maxLength=100. WHEN 'peso' OR WHEN 'largura' OR WHEN 'rolo' THEN maxLength=30. WHEN 'observacao' THEN maxLength=8000. WHEN 'unid_medida' THEN maxLength=8. END CASE.
    IF maxLength=0 OR LENGTH(rawValue)>maxLength THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Texto excedeu limite do formulario.',422).
    IF nameValue='descricao' AND TRIM(rawValue)='' THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Descricao obrigatoria.',422).
    IF nameValue='unid_medida' AND NOT COMPARE(rawValue,'=','MT','RAW') AND NOT COMPARE(rawValue,'=','KG','RAW') THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Unidade deve ser MT ou KG.',422).
    IF nameValue='codigo_erp' THEN DO j=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,j,1))=0 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Codigo ERP aceita somente digitos.',422). END.
   END.
   WHEN 'LOGICAL' THEN IF v:GetType(nameValue)<>JsonDataType:BOOLEAN THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Booleano obrigatorio.',422).
   WHEN 'INTEGER' OR WHEN 'DECIMAL' THEN DO:
    IF v:GetType(nameValue)<>JsonDataType:NUMBER THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Numero JSON obrigatorio.',422).
    rawValue=STRING(v:GetJsonText(nameValue)).
    IF f:DATA-TYPE='INTEGER' THEN DO j=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,j,1))=0 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Inteiro canonico obrigatorio.',422). END.
    ELSE IF NOT PurchaseItemDecimalFits(rawValue,f:DECIMALS) THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Precisao ou faixa decimal invalida.',422).
    nval=IF f:DATA-TYPE='INTEGER' THEN v:GetDecimal(nameValue) ELSE PurchaseItemDecimalNumber(rawValue).
    IF nval=? OR ABSOLUTE(nval)>999999999999 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Numero fora da faixa.',422).
    IF f:DATA-TYPE='INTEGER' THEN DO:
     IF INDEX(rawValue,'.')>0 OR nval<0 OR nval>2147483647 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Inteiro sem fracao fora da faixa.',422).
     IF nameValue BEGINS 'ind_' THEN IF nval>(IF nameValue='ind_distr_custo' THEN 3 ELSE 2) THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Opcao invalida.',422).
     IF nameValue='qt_dias_producao' AND nval>9999 OR nameValue='qt_dias_calc_so_ld' AND nval>999 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Dias fora do limite.',422).
    END.

   END.
   WHEN 'DATE' THEN DO:
    IF v:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Data ISO obrigatoria.',422).
    rawValue=v:GetCharacter(nameValue).
    IF LENGTH(rawValue)<>10 OR SUBSTRING(rawValue,5,1)<>'-' OR SUBSTRING(rawValue,8,1)<>'-' THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Data ISO obrigatoria.',422).
    d=DATE(INTEGER(SUBSTRING(rawValue,6,2)),INTEGER(SUBSTRING(rawValue,9,2)),INTEGER(SUBSTRING(rawValue,1,4))) NO-ERROR.
    IF ERROR-STATUS:ERROR OR d=? OR ISO-DATE(d)<>rawValue THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Data civil invalida.',422).
   END.
   OTHERWISE RUN Fail('PURCHASE_ITEM_CONFIGURATION','Tipo fisico nao suportado.',503).
  END CASE.
 END.
END PROCEDURE.
PROCEDURE ApplyValues:
 DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO.
 DO i=1 TO EXTENT(names):
  f=phItems:BUFFER-FIELD(names[i]).
  IF v:IsNull(names[i]) THEN DO:
   IF f:DATA-TYPE<>'DATE' AND f:BUFFER-VALUE<>? THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Somente desconhecido preexistente pode ser preservado.',422).
   f:BUFFER-VALUE=?.
  END.
  ELSE CASE f:DATA-TYPE:
   WHEN 'INTEGER' THEN f:BUFFER-VALUE=v:GetInteger(names[i]).
   WHEN 'DECIMAL' THEN f:BUFFER-VALUE=PurchaseItemDecimalNumber(STRING(v:GetJsonText(names[i]))).
   WHEN 'CHARACTER' THEN f:BUFFER-VALUE=v:GetCharacter(names[i]).
   WHEN 'LOGICAL' THEN f:BUFFER-VALUE=v:GetLogical(names[i]).
   WHEN 'DATE' THEN DO: rawValue=v:GetCharacter(names[i]). f:BUFFER-VALUE=DATE(INTEGER(SUBSTRING(rawValue,6,2)),INTEGER(SUBSTRING(rawValue,9,2)),INTEGER(SUBSTRING(rawValue,1,4))). END.
  END CASE.
 END.
END PROCEDURE.
FUNCTION Changed RETURNS LOGICAL(fieldName AS CHARACTER):
 IF NOT v:Has(fieldName) THEN RETURN FALSE.
 IF op='create' THEN RETURN TRUE.
 RETURN NOT COMPARE(STRING(v:GetJsonText(fieldName)),'=',STRING(beforeImage:GetJsonText(fieldName)),'RAW').
END FUNCTION.
PROCEDURE SuggestDate:
 DEFINE INPUT PARAMETER sourceName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER daysName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER targetName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE d AS DATE NO-UNDO. DEFINE VARIABLE daysValue AS INTEGER NO-UNDO.
 IF NOT (Changed(sourceName) OR Changed(daysName)) THEN RETURN.
 IF Changed(targetName) THEN IF NOT v:IsNull(targetName) THEN RETURN.
 d=phItems:BUFFER-FIELD(sourceName):BUFFER-VALUE. daysValue=phItems:BUFFER-FIELD(daysName):BUFFER-VALUE.
 IF d=? OR daysValue=? THEN RETURN.
 phItems:BUFFER-FIELD(targetName):BUFFER-VALUE=d + daysValue.
END PROCEDURE.
PROCEDURE SuggestValues:
 DEFINE VARIABLE proforma AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE negotiated AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE baseValue AS DECIMAL DECIMALS 5 NO-UNDO.
 IF NOT (Changed('vl_custo_dolar') OR Changed('vl_negociado')) THEN RETURN.
 ASSIGN proforma=phItems:BUFFER-FIELD('vl_custo_dolar'):BUFFER-VALUE negotiated=phItems:BUFFER-FIELD('vl_negociado'):BUFFER-VALUE baseValue=phItems:BUFFER-FIELD('vl_base_tributacao'):BUFFER-VALUE.
 IF Changed('vl_custo_dolar') AND proforma<>? AND proforma<>0 AND (baseValue=0 OR baseValue=?) AND (op='create' OR NOT Changed('vl_base_tributacao')) THEN phItems:BUFFER-FIELD('vl_base_tributacao'):BUFFER-VALUE=proforma.
 IF proforma=? OR negotiated=? THEN RETURN.
 /* A changed non-default selection is an explicit override. Full native
    create values send0; that default must not suppress the active suggestion. */
 IF Changed('ind_distr_custo') THEN IF NOT v:IsNull('ind_distr_custo') THEN IF op='update' OR v:GetInteger('ind_distr_custo')<>0 THEN RETURN.
 phItems:BUFFER-FIELD('ind_distr_custo'):BUFFER-VALUE=IF negotiated>proforma THEN 1 ELSE IF negotiated<proforma THEN 2 ELSE 3.
END PROCEDURE.
PROCEDURE AllocatedQuantity:
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 DEFINE VARIABLE quantity AS DECIMAL NO-UNDO.
 allocated=0. countRows=0.
 CREATE QUERY q. q:SET-BUFFERS(phAllocations).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + phAllocations:NAME + ' WHERE item_proc_compra_id=' + N(itemId) + ' BY item_container_id') THEN RUN Fail('PURCHASE_ITEM_QUERY','Consulta de alocacoes recusada.',503).
 q:QUERY-OPEN(). q:GET-FIRST(lockMode,NO-WAIT) NO-ERROR.
 DO WHILE NOT q:QUERY-OFF-END:
  IF phAllocations:LOCKED OR ERROR-STATUS:ERROR THEN RUN Fail('PURCHASE_ITEM_BUSY','Alocacoes em uso.',409).
  countRows=countRows + 1. quantity=phAllocations:BUFFER-FIELD('qt_alocada'):BUFFER-VALUE.
  IF quantity=? OR quantity<0 THEN RUN Fail('PURCHASE_ITEM_QUANTITY','Quantidade alocada indefinida.',409).
  allocated=allocated + quantity. q:GET-NEXT(lockMode,NO-WAIT) NO-ERROR.
 END. DELETE OBJECT q. q=?.
END PROCEDURE.
PROCEDURE NextIdentity:
 IF NOT VALID-HANDLE(phRuntime) OR LOOKUP('NextPurchaseItemId',phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_ITEM_SEQUENCE_CONFIGURATION','Alocador persistente de item ausente.',503).
 code='PURCHASE_ITEM_SEQUENCE_CONFIGURATION'. statusCode=503.
 RUN NextPurchaseItemId IN phRuntime(OUTPUT itemId).
 IF itemId=? OR itemId<1 THEN RUN Fail('PURCHASE_ITEM_SEQUENCE_CONFIGURATION','Sequencia fixa retornou identidade invalida.',503).
 code='PURCHASE_ITEM_VALIDATION'. statusCode=422.
END PROCEDURE.
PROCEDURE ValidateReference:
 DEFINE INPUT PARAMETER fieldName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE VARIABLE keyValue AS INTEGER NO-UNDO.
 IF NOT Changed(fieldName) THEN RETURN.
 keyValue=phItems:BUFFER-FIELD(fieldName):BUFFER-VALUE. IF keyValue=? OR keyValue=0 THEN RETURN.
 IF NOT Found(h,fieldName + '=' + N(keyValue),SHARE-LOCK) THEN RUN Fail('PURCHASE_ITEM_REFERENCE','Referencia nao encontrada.',422).
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 RUN Closed(poRequest,'operation,id,proc_compra_id,row_stamp,values').
 IF poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Operacao obrigatoria.',422).
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'get,create,update,delete')=0 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Operacao invalida.',422).
 pid=Id(poRequest,'proc_compra_id').
 IF op='create' THEN DO: IF poRequest:Has('id') OR poRequest:Has('row_stamp') THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Inclusao nao recebe identidade.',422). END.
 ELSE itemId=Id(poRequest,'id').
 IF LOOKUP(op,'update,delete')>0 THEN DO:
  IF NOT poRequest:Has('row_stamp') OR poRequest:GetType('row_stamp')<>JsonDataType:STRING THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Stamp obrigatorio.',422).
  submittedStamp=poRequest:GetCharacter('row_stamp'). IF LENGTH(submittedStamp)<>64 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Stamp invalido.',422).
  DO i=1 TO 64: IF INDEX('0123456789ABCDEF',SUBSTRING(submittedStamp,i,1))=0 THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Stamp invalido.',422). END.
 END.
 IF op='get' THEN DO:
  IF poRequest:Has('values') OR poRequest:Has('row_stamp') THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Consulta nao recebe valores.',422).
  RUN ResolveCompany(NO-LOCK).
  IF NOT Found(phOrders,'proc_compra_id=' + N(pid) + ' AND empresa_id=' + N(companyId),NO-LOCK) THEN RUN Fail('PURCHASE_ITEM_PARENT','Processo MED nao encontrado.',404).
  IF NOT Found(phItems,'item_proc_compra_id=' + N(itemId) + ' AND proc_compra_id=' + N(pid),NO-LOCK) THEN RUN Fail('PURCHASE_ITEM_NOT_FOUND','Item contextual nao encontrado.',404).
  RUN AllocatedQuantity(NO-LOCK).
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',PurchaseItemData(phItems,allocated)). RETURN.
 END.
 IF TRANSACTION THEN RUN Fail('PURCHASE_ITEM_TRANSACTION','Transacao raiz propria obrigatoria.',409).
 actor=poPolicy:GetJsonObject('actor'):GetCharacter('login'). IF actor=? OR TRIM(actor)='' OR LENGTH(actor)>128 THEN RUN Fail('PURCHASE_ITEM_IDENTITY','Ator autenticado obrigatorio.',401).
 IF NOT VALID-HANDLE(phRuntime) OR LOOKUP('RunPurchaseItemChange',phRuntime:INTERNAL-ENTRIES)=0 THEN RUN Fail('PURCHASE_ITEM_CONFIGURATION','Runtime de itens ausente.',503).
 IF op='delete' THEN DO: IF poRequest:Has('values') THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Exclusao nao recebe valores.',422). END.
 ELSE DO: v=poRequest:GetJsonObject('values'). RUN ValidateValues. END.
 beforeImage=NEW JsonObject(). afterImage=NEW JsonObject().
 DO STOP-AFTER 20 ON STOP UNDO, LEAVE:
 DO TRANSACTION ON ERROR UNDO, THROW:
  /* Parent first, then the existing shared MED company mutex, then item and
     related owners. Every lock is NO-WAIT; cross-writer inversion aborts. */
  IF NOT Found(phOrders,'proc_compra_id=' + N(pid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ITEM_PARENT','Processo nao encontrado.',404).
  RUN ResolveCompany(EXCLUSIVE-LOCK).
  IF phOrders:BUFFER-FIELD('empresa_id'):BUFFER-VALUE<>companyId THEN RUN Fail('PURCHASE_ITEM_PARENT','Processo pertence a outra origem.',404).
  IF op='create' THEN DO:
   RUN NextIdentity.
   IF Found(phItems,'item_proc_compra_id=' + N(itemId),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ITEM_IDENTITY','Identidade concorrente ocupada.',409).
   IF NOT phItems:BUFFER-CREATE() THEN RUN Fail('PURCHASE_ITEM_WRITE','Inclusao recusada.',422).
   phItems:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE=itemId. phItems:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE=pid.
   phItems:BUFFER-FIELD('log_mostruario'):BUFFER-VALUE=TRUE.
  END.
  ELSE DO:
   IF NOT Found(phItems,'item_proc_compra_id=' + N(itemId) + ' AND proc_compra_id=' + N(pid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ITEM_NOT_FOUND','Item contextual nao encontrado.',404).
   beforeImage=PurchaseItemSnapshot(phItems).
   IF NOT COMPARE(PurchaseItemStamp(beforeImage),'=',submittedStamp,'RAW') THEN RUN Fail('PURCHASE_ITEM_CHANGED','Item alterado; recarregue.',409).
  END.
  RUN AllocatedQuantity(SHARE-LOCK).
  IF op='delete' THEN DO:
   IF countRows>0 THEN RUN Fail('PURCHASE_ITEM_DEPENDENCY','Item possui vinculo em container.',409).
   DO i=1 TO 4:
    IF NOT VALID-HANDLE(phDependencies[i]) THEN RUN Fail('PURCHASE_ITEM_CONFIGURATION','Dependencia fisica ausente.',503).
    IF Found(phDependencies[i],'item_proc_compra_id=' + N(itemId),SHARE-LOCK) THEN RUN Fail('PURCHASE_ITEM_DEPENDENCY','Item possui dependencia fisica.',409).
   END.
  END.
  ELSE DO:
   RUN ApplyValues.
   IF phItems:BUFFER-FIELD('descricao'):BUFFER-VALUE=? OR TRIM(STRING(phItems:BUFFER-FIELD('descricao'):BUFFER-VALUE))='' OR phItems:BUFFER-FIELD('unid_medida'):BUFFER-VALUE=? OR TRIM(STRING(phItems:BUFFER-FIELD('unid_medida'):BUFFER-VALUE))='' THEN RUN Fail('PURCHASE_ITEM_VALIDATION','Descricao e unidade obrigatorias.',422).
   IF phItems:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE=? OR DECIMAL(phItems:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE)<allocated THEN RUN Fail('PURCHASE_ITEM_QUANTITY','Compra menor que quantidade alocada.',409).
   RUN ValidateReference('coloracao_id',phColors). RUN ValidateReference('formato_amostra_id',phFormats).
   IF Changed('item_estacao') THEN IF phItems:BUFFER-FIELD('item_estacao'):BUFFER-VALUE<>? AND phItems:BUFFER-FIELD('item_estacao'):BUFFER-VALUE<>0 THEN
    IF NOT Found(phSeason,'lista_id=15 AND cod_opcao=' + QUOTER(N(INTEGER(phItems:BUFFER-FIELD('item_estacao'):BUFFER-VALUE))),SHARE-LOCK) THEN RUN Fail('PURCHASE_ITEM_REFERENCE','Estacao fora da lista15.',422).
   RUN SuggestDate('dt_real_aprov_so_ld','qt_dias_producao','dt_maxima_producao').
   RUN SuggestDate('dt_real_envio_desenhos','qt_dias_calc_so_ld','dt_prev_recbto_so_ld').
   RUN SuggestValues.
   IF NOT phItems:BUFFER-VALIDATE() THEN RUN Fail('PURCHASE_ITEM_WRITE','Item recusado.',422).
   afterImage=PurchaseItemSnapshot(phItems).
  END.
  ctx=NEW JsonObject(). ctx:Add('operation','purchase-item-' + op). ctx:Add('proc_compra_id',pid). ctx:Add('item_proc_compra_id',itemId). ctx:Add('before',beforeImage). ctx:Add('after',afterImage).
  code='PURCHASE_ITEM_EFFECTS'. statusCode=422. RUN RunPurchaseItemChange IN phRuntime(phOrders,ctx,OUTPUT financial).
  IF NOT VALID-OBJECT(financial) OR NOT financial:GetLogical('success') THEN RUN Fail('PURCHASE_ITEM_EFFECTS','Efeitos recusados.',422).
  changes=CAST(financial:GetJsonArray('changes'):Clone(),JsonArray). warnings=CAST(financial:GetJsonArray('warnings'):Clone(),JsonArray).
  IF changes:Length>2000 THEN RUN Fail('PURCHASE_ITEM_LIMIT','Mais de2000efeitos.',422).
  IF NOT Found(phItems,'item_proc_compra_id=' + N(itemId) + ' AND proc_compra_id=' + N(pid),EXCLUSIVE-LOCK) THEN RUN Fail('PURCHASE_ITEM_CHANGED','Item perdeu contexto.',409).
  IF op='delete' THEN DO: IF NOT phItems:BUFFER-DELETE() THEN RUN Fail('PURCHASE_ITEM_WRITE','Exclusao recusada.',422). END.
  ELSE dataRow=PurchaseItemData(phItems,allocated).
  poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('committed',TRUE). IF op<>'delete' THEN poResponse:Add('data',dataRow).
  audit=NEW JsonObject(). audit:Add('version',1). audit:Add('source','progress-transaction'). audit:Add('resource','itens-proc-compra'). audit:Add('operation',op). audit:Add('recordId',itemId).
  effect=NEW JsonObject(). effect:Add('login',actor). audit:Add('actor',effect). audit:Add('before',beforeImage). audit:Add('after',afterImage). audit:Add('changes',changes). audit:Add('warnings',warnings). poResponse:Add('audit',audit).
 END.
 writeComplete=TRUE.
 END.
 IF NOT writeComplete THEN RUN Fail('PURCHASE_ITEM_TIMEOUT','Prazo excedido; alteracoes desfeitas.',503).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). effect=NEW JsonObject(). effect:Add('code',code). effect:Add('status',statusCode). effect:Add('message',e:GetMessage(1)). poResponse:Add('success',FALSE). poResponse:Add('error',effect).
 END CATCH.
 FINALLY: IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR. END FINALLY.
END.
