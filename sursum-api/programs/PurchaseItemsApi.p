/* Fixed CIW adapter. Parent MED context, tables, actor and callbacks are server-owned. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
{sursum-api/includes/PurchaseItemsReadBuffer.i}
{sursum-api/includes/PurchaseItemSnapshot.i}
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerMaintenancePolicy.i}
{sursum-api/includes/ContainerFinancePolicy.i}
DEFINE TEMP-TABLE ttCurrencyOwner NO-UNDO FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE loginName AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE baseRuntimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE fiscalRulesPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE itemRuntimePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE baseRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE fiscalRules AS HANDLE NO-UNDO.
DEFINE VARIABLE itemRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE hOrderPayments AS HANDLE NO-UNDO.
DEFINE VARIABLE hAllContainers AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE hValTitAp AS HANDLE NO-UNDO.
DEFINE VARIABLE hColors AS HANDLE NO-UNDO.
DEFINE VARIABLE hFormats AS HANDLE NO-UNDO.
DEFINE VARIABLE hSeason AS HANDLE NO-UNDO.
DEFINE VARIABLE deps AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 20 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL "empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container,pp-it-container,pp_container_permissao,pp_container_saldo_repres,nfs_container,cta_corren_desconto,anexos_container,versoes_item_custo_container,pagtos_container,cta_corren_fornec_imp,item_container_custos".
DEFINE VARIABLE depTables AS CHARACTER NO-UNDO INITIAL 'anexos_proc_compra,envios_amostras_repres,itens_liber,pp-it-container'.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE companyCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 503.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ITEM_CONFIGURATION'.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE aq AS HANDLE NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE matched AS LOGICAL NO-UNDO.
 ns=poRequest:GetNames(). DO i=1 TO EXTENT(ns):
  matched=FALSE. DO j=1 TO NUM-ENTRIES(allowed): IF COMPARE(ns[i],'=',ENTRY(j,allowed),'RAW') THEN matched=TRUE. END.
  IF NOT matched THEN UNDO, THROW NEW Progress.Lang.AppError('Campo raiz nao permitido.',1).
 END.
END PROCEDURE.
FUNCTION Id RETURNS INTEGER(o AS JsonObject,nameValue AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO. DEFINE VARIABLE i AS INTEGER NO-UNDO.
 IF NOT o:Has(nameValue) THEN UNDO, THROW NEW Progress.Lang.AppError('Contexto inteiro obrigatorio.',1).
 IF o:GetType(nameValue)=JsonDataType:STRING THEN rawValue=o:GetCharacter(nameValue).
 ELSE IF o:GetType(nameValue)=JsonDataType:NUMBER THEN rawValue=STRING(o:GetJsonText(nameValue)).
 ELSE UNDO, THROW NEW Progress.Lang.AppError('Contexto inteiro obrigatorio.',1).
 IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN UNDO, THROW NEW Progress.Lang.AppError('Contexto fora da faixa.',1).
 DO i=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,i,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Contexto inteiro obrigatorio.',1). END.
 IF DECIMAL(rawValue)<1 OR DECIMAL(rawValue)>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('Contexto fora da faixa.',1).
 RETURN INTEGER(rawValue).
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('Banco especifico indisponivel.',1).
 IF poRequest:GetCharacter('resource')<>'proc_compra_itens' THEN UNDO, THROW NEW Progress.Lang.AppError('Recurso invalido.',1).
 DO n=1 TO 20: CREATE BUFFER h[n] FOR TABLE ('espec.' + ENTRY(n,tables)) BUFFER-NAME ('bPurchaseItemsApi' + STRING(n,'99')). END.
 CREATE BUFFER hColors FOR TABLE 'espec.coloracoes' BUFFER-NAME 'bPurchaseItemsColors'.
 CREATE BUFFER hFormats FOR TABLE 'espec.formatos_amostra' BUFFER-NAME 'bPurchaseItemsFormats'.
 CREATE BUFFER hSeason FOR TABLE 'espec.opcoes_lista' BUFFER-NAME 'bPurchaseItemsSeason'.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource'). op=clean:GetCharacter('operation').
 statusCode=422. code='PURCHASE_ITEM_VALIDATION'. pid=Id(clean,'proc_compra_id').
 servicePath=SEARCH('sursum-api/programs/CiwMedCompanyContext.r'). IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Resolvedor MED nao publicado.',1).
 RUN VALUE(servicePath)(h[1],OUTPUT companyCode).
 IF NOT h[1]:FIND-FIRST('WHERE cod_emp_ems2=5',NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError('Empresa MED ausente.',1).
 companyId=h[1]:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
 IF NOT h[4]:FIND-FIRST('WHERE proc_compra_id=' + N(pid) + ' AND empresa_id=' + N(companyId),NO-LOCK) THEN DO: code='PURCHASE_ITEM_PARENT'. statusCode=404. UNDO, THROW NEW Progress.Lang.AppError('Processo MED nao encontrado.',1). END.
 IF op='options' THEN DO:
  RUN Closed('resource,operation,proc_compra_id,lookup'). RUN ReadOptions. RETURN.
 END.
 IF op='read' THEN DO:
  RUN Closed('resource,operation,proc_compra_id,skip,take,sort,filter').
  RUN ProjectRows.
  servicePath=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Leitor compartilhado nao publicado.',1).
  clean:Remove('proc_compra_id').
  RUN VALUE(servicePath)(INPUT BUFFER ttPurchaseItemRead:HANDLE,'proc_compra_itens',N(pid),clean,OUTPUT poResponse). RETURN.
 END.
 IF op='get' THEN DO:
  servicePath=SEARCH('sursum-api/programs/PurchaseItemsService.r'). IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Servico de itens nao publicado.',1).
  RUN VALUE(servicePath)(h[3],h[4],h[1],h[2],hColors,hFormats,hSeason,deps,?, ?,clean,OUTPUT poResponse). RETURN.
 END.
 code='PURCHASE_ITEM_CONFIGURATION'. statusCode=503.
 IF NOT CONNECTED('ems5') THEN UNDO, THROW NEW Progress.Lang.AppError('Banco financeiro indisponivel.',1).
 DO n=1 TO 4: CREATE BUFFER deps[n] FOR TABLE ('espec.' + ENTRY(n,depTables)) BUFFER-NAME ('bPurchaseItemsDep' + STRING(n,'99')). END.
 ASSIGN servicePath=SEARCH('sursum-api/programs/PurchaseItemsService.r') baseRuntimePath=SEARCH('sursum-api/programs/ContainersCabecalhoRuntime.r') fiscalRulesPath=SEARCH('sursum-api/programs/ContainersCabecalhoRules.r') itemRuntimePath=SEARCH('sursum-api/programs/ContainersItensRuntime.r').
 IF servicePath=? OR baseRuntimePath=? OR fiscalRulesPath=? OR itemRuntimePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Composicao de itens nao publicada.',1).
 CREATE BUFFER hOrderPayments FOR TABLE 'espec.pagtos_proc_compra' BUFFER-NAME 'bPurchaseItemsPayments'.
 CREATE BUFFER hAllContainers FOR TABLE 'espec.pp-container' BUFFER-NAME 'bPurchaseItemsContainers'.
 CREATE BUFFER hTitAp FOR TABLE 'ems5.tit_ap' BUFFER-NAME 'bPurchaseItemsTitles'.
 CREATE BUFFER hValTitAp FOR TABLE 'ems5.val_tit_ap' BUFFER-NAME 'bPurchaseItemsValues'.
 CREATE ttCurrencyOwner. ttCurrencyOwner.nr-container=1.
 loginName=pcActor. policy=ContainerMaintenancePolicy(loginName). financePolicy=ContainerFinancePolicy().
 RUN VALUE(baseRuntimePath) PERSISTENT SET baseRuntime(INPUT ?).
 RUN VALUE(fiscalRulesPath) PERSISTENT SET fiscalRules(INPUT h[1],INPUT h[2],INPUT h[3],INPUT h[4],INPUT h[5],INPUT h[6],INPUT h[7],INPUT h[8],INPUT h[9],INPUT h[10],INPUT h[11],INPUT h[12],INPUT h[13],INPUT h[14],INPUT h[15],INPUT h[16],INPUT h[17],INPUT h[18],INPUT h[19],INPUT h[20],INPUT baseRuntime,INPUT policy).
 RUN VALUE(itemRuntimePath) PERSISTENT SET itemRuntime(fiscalRules,baseRuntime,INPUT BUFFER ttCurrencyOwner:HANDLE,h[2],h[3],h[4],h[19],hOrderPayments,h[18],hAllContainers,hTitAp,hValTitAp,policy,financePolicy).
 RUN VALUE(servicePath)(h[3],h[4],h[1],h[2],hColors,hFormats,hSeason,deps,itemRuntime,policy,clean,OUTPUT poResponse).
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). policy=NEW JsonObject(). policy:Add('code',code). policy:Add('status',statusCode). policy:Add('message',err:GetMessage(1)). poResponse:Add('success',FALSE). poResponse:Add('error',policy).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(itemRuntime) THEN DELETE PROCEDURE itemRuntime NO-ERROR.
  IF VALID-HANDLE(fiscalRules) THEN DELETE PROCEDURE fiscalRules NO-ERROR.
  IF VALID-HANDLE(baseRuntime) THEN DELETE PROCEDURE baseRuntime NO-ERROR.
  DO n=1 TO 20: IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
  DO n=1 TO 4: IF VALID-HANDLE(deps[n]) THEN DELETE OBJECT deps[n] NO-ERROR. END.
  IF VALID-HANDLE(hOrderPayments) THEN DELETE OBJECT hOrderPayments NO-ERROR.
  IF VALID-HANDLE(hAllContainers) THEN DELETE OBJECT hAllContainers NO-ERROR.
  IF VALID-HANDLE(hTitAp) THEN DELETE OBJECT hTitAp NO-ERROR.
  IF VALID-HANDLE(hValTitAp) THEN DELETE OBJECT hValTitAp NO-ERROR.
  IF VALID-HANDLE(hColors) THEN DELETE OBJECT hColors NO-ERROR.
  IF VALID-HANDLE(hFormats) THEN DELETE OBJECT hFormats NO-ERROR.
  IF VALID-HANDLE(hSeason) THEN DELETE OBJECT hSeason NO-ERROR.
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(aq) THEN DELETE OBJECT aq NO-ERROR.
 END FINALLY.
END.
PROCEDURE ProjectRows:
 DEFINE VARIABLE allocated AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE VARIABLE valueQuantity AS DECIMAL NO-UNDO.
 DEFINE VARIABLE image AS JsonObject NO-UNDO.
 EMPTY TEMP-TABLE ttPurchaseItemRead.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
 CREATE QUERY q. q:SET-BUFFERS(h[3]). q:QUERY-PREPARE('FOR EACH ' + h[3]:NAME + ' WHERE proc_compra_id=' + N(pid) + ' NO-LOCK'). q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  CREATE ttPurchaseItemRead.
  IF NOT BUFFER ttPurchaseItemRead:HANDLE:BUFFER-COPY(h[3]) THEN UNDO, THROW NEW Progress.Lang.AppError('Projecao recusada.',1).
  image=PurchaseItemSnapshot(h[3]). ttPurchaseItemRead.row_stamp=PurchaseItemStamp(image). ttPurchaseItemRead.calc_gm=PurchaseItemGm(h[3]). allocated=0.
  CREATE QUERY aq. aq:SET-BUFFERS(h[2]). aq:QUERY-PREPARE('FOR EACH ' + h[2]:NAME + ' WHERE item_proc_compra_id=' + N(ttPurchaseItemRead.item_proc_compra_id) + ' NO-LOCK'). aq:QUERY-OPEN(). aq:GET-FIRST(NO-LOCK).
  DO WHILE NOT aq:QUERY-OFF-END:
   valueQuantity=h[2]:BUFFER-FIELD('qt_alocada'):BUFFER-VALUE.
   IF valueQuantity=? OR valueQuantity<0 THEN UNDO, THROW NEW Progress.Lang.AppError('Alocacao indefinida.',1).
   allocated=allocated + valueQuantity. aq:GET-NEXT(NO-LOCK).
  END. DELETE OBJECT aq. aq=?.
  ASSIGN ttPurchaseItemRead.qt_alocada=allocated ttPurchaseItemRead.qt_saldo=ttPurchaseItemRead.qt_comprada - allocated.
  q:GET-NEXT(NO-LOCK).
 END. DELETE OBJECT q. q=?. complete=TRUE.
 END.
 IF NOT complete THEN DO: code='PURCHASE_ITEM_TIMEOUT'. statusCode=503. UNDO, THROW NEW Progress.Lang.AppError('Projecao excedeu prazo; sem pagina parcial.',1). END.
END PROCEDURE.
PROCEDURE ReadOptions:
 DEFINE VARIABLE hLookup AS HANDLE NO-UNDO. DEFINE VARIABLE keyName AS CHARACTER NO-UNDO. DEFINE VARIABLE textName AS CHARACTER NO-UNDO.
 DEFINE VARIABLE lookupName AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE whereText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE rows AS JsonArray NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE seen AS JsonObject NO-UNDO. DEFINE VARIABLE keyObject AS JsonObject NO-UNDO.
 DEFINE VARIABLE optionId AS INTEGER NO-UNDO. DEFINE VARIABLE labelValue AS CHARACTER NO-UNDO.
 lookupName=poRequest:GetCharacter('lookup').
 CASE lookupName:
  WHEN 'coloracao' THEN ASSIGN hLookup=hColors keyName='coloracao_id' textName='descricao'.
  WHEN 'formato_amostra' THEN ASSIGN hLookup=hFormats keyName='formato_amostra_id' textName='descricao'.
  WHEN 'estacao' THEN DO:
   ASSIGN hLookup=hSeason keyName='cod_opcao' textName='desc_opcao' whereText=' WHERE lista_id=15'.
  END.
  OTHERWISE UNDO, THROW NEW Progress.Lang.AppError('Lookup invalido.',1).
 END CASE.
 rows=NEW JsonArray(). seen=NEW JsonObject(). complete=FALSE.
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
 CREATE QUERY q. q:SET-BUFFERS(hLookup). q:QUERY-PREPARE('FOR EACH ' + hLookup:NAME + whereText + ' NO-LOCK BY ' + textName + ' BY ' + keyName). q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  keyObject=NEW JsonObject(). keyObject:Add('id',STRING(hLookup:BUFFER-FIELD(keyName):BUFFER-VALUE)). optionId=Id(keyObject,'id').
  IF seen:Has(N(optionId)) THEN UNDO, THROW NEW Progress.Lang.AppError('Opcao fisica ambigua apos normalizacao.',1).
  seen:Add(N(optionId),TRUE). labelValue=hLookup:BUFFER-FIELD(textName):BUFFER-VALUE.
  IF optionId=? OR optionId<1 OR labelValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Opcao fisica invalida.',1).
  IF rows:Length>=1000 THEN UNDO, THROW NEW Progress.Lang.AppError('Lookup excedeu1000opcoes.',1).
  rowValue=NEW JsonObject(). rowValue:Add('value',optionId). rowValue:Add('text',labelValue). rows:Add(rowValue).
  q:GET-NEXT(NO-LOCK).
 END. DELETE OBJECT q. q=?. complete=TRUE.
 END.
 IF NOT complete THEN UNDO, THROW NEW Progress.Lang.AppError('Lookup excedeu prazo.',1).
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('data',rows). poResponse:Add('total',rows:Length).
END PROCEDURE.
