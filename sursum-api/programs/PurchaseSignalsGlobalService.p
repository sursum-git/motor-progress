/* Read-only orchestration. Contextual and global callers share one collector
   and evaluator; this layer only unifies and counts their projections. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPayments AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSignals AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pdToday AS DATE NO-UNDO.
DEFINE INPUT PARAMETER pcResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseSignalsTable.i}
DEFINE TEMP-TABLE ttDetail NO-UNDO
 FIELD sinaliz_imp_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD container_id AS INTEGER
 FIELD tipo_registro AS CHARACTER FIELD nome_alerta AS CHARACTER FIELD titulo_configurado AS CHARACTER FIELD descricao_alerta AS CHARACTER
 FIELD dias_alerta AS INTEGER FIELD data_base AS DATE FIELD data_alerta AS DATE FIELD data_consulta AS DATE
 FIELD cod_proc_fornec AS CHARACTER FIELD fornecedor_id AS INTEGER FIELD item_descricao AS CHARACTER FIELD codigo_erp AS CHARACTER
 FIELD link_proc_compra_id AS INTEGER INITIAL ? FIELD link_container_id AS INTEGER INITIAL ?
 INDEX pk IS PRIMARY UNIQUE sinaliz_imp_id tipo_registro proc_compra_id item_proc_compra_id container_id.
DEFINE TEMP-TABLE ttSummary NO-UNDO
 FIELD sinaliz_imp_id AS INTEGER FIELD tipo_registro AS CHARACTER FIELD nome_alerta AS CHARACTER
 FIELD titulo_configurado AS CHARACTER FIELD descricao_alerta AS CHARACTER FIELD dias_alerta AS INTEGER FIELD quantidade AS INTEGER FIELD data_consulta AS DATE
 INDEX pk IS PRIMARY UNIQUE sinaliz_imp_id.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE bOrders AS HANDLE NO-UNDO.
DEFINE VARIABLE bCompanies AS HANDLE NO-UNDO.
DEFINE VARIABLE companyPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE rulePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE medCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_SIGNALS_GLOBAL_VALIDATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE selectedRule AS INTEGER NO-UNDO.
DEFINE VARIABLE collectedProcess AS INTEGER NO-UNDO.
DEFINE VARIABLE collectedScanned AS INTEGER NO-UNDO.
DEFINE VARIABLE scanned AS INTEGER NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE matches AS LOGICAL NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 code=c. statusCode=s. UNDO, THROW NEW Progress.Lang.AppError(c,1).
END PROCEDURE.
PROCEDURE LimitCheck:
 scanned=scanned + 1.
 IF scanned>50000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_SIGNALS_GLOBAL_LIMIT',503).
END PROCEDURE.
FUNCTION FindSignal RETURNS LOGICAL(idValue AS INTEGER):
 DEFINE VARIABLE ok AS LOGICAL NO-UNDO. DEFINE VARIABLE m AS INTEGER NO-UNDO.
 ok=phSignals:FIND-FIRST('WHERE sinaliz_imp_id=' + N(idValue),NO-LOCK) NO-ERROR.
 DO m=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(m)<>565 THEN RUN Fail('PURCHASE_SIGNALS_GLOBAL_CONFIGURATION',503). END.
 RETURN ok.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phPayments) OR NOT VALID-HANDLE(phSignals) OR NOT VALID-HANDLE(phContainers) OR pdToday=? THEN RUN Fail('PURCHASE_SIGNALS_GLOBAL_CONFIGURATION',503).
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail(code,422).
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422).
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'read,get')=0 THEN RUN Fail('PURCHASE_SIGNALS_GLOBAL_READ_ONLY',405).
 IF LOOKUP(pcResource,'proc_compra_sinalizadores,proc_compra_sinalizados')=0 THEN RUN Fail(code,422).
 names=poRequest:GetNames(). DO k=1 TO EXTENT(names):
  IF LOOKUP(names[k],IF op='get' THEN 'operation,id,record_key,sinaliz_imp_id' ELSE 'operation,skip,take,sort,filter,sinaliz_imp_id')=0 THEN RUN Fail(code,422).
 END.
 IF pcResource='proc_compra_sinalizados' AND NOT poRequest:Has('sinaliz_imp_id') THEN RUN Fail(code,422).
 IF poRequest:Has('sinaliz_imp_id') THEN DO:
  IF pcResource<>'proc_compra_sinalizados' THEN RUN Fail(code,422).
  selectedRule=PurchaseJsonId(poRequest,'sinaliz_imp_id'). IF selectedRule>5 THEN RUN Fail(code,422).
 END.
 ASSIGN servicePath=SEARCH('sursum-api/programs/PurchaseSignalsCollector.r') rulePath=SEARCH('sursum-api/programs/PurchaseSignalContainerRules.r')
  companyPath=SEARCH('sursum-api/programs/CiwMedCompanyContext.r') readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF servicePath=? OR rulePath=? OR companyPath=? OR readerPath=? THEN RUN Fail('PURCHASE_SIGNALS_GLOBAL_CONFIGURATION',503).
 ASSIGN code='PURCHASE_SIGNALS_GLOBAL_CONFIGURATION' statusCode=503 started=ETIME.
 RUN VALUE(companyPath)(phCompanies,OUTPUT medCode).
 DO k=1 TO 5:
  IF NOT FindSignal(k) THEN RUN Fail(code,503).
  IF phSignals:BUFFER-FIELD('qt_dias_alerta'):BUFFER-VALUE=? THEN RUN Fail(code,503).
  CREATE ttSummary. ASSIGN ttSummary.sinaliz_imp_id=k ttSummary.dias_alerta=phSignals:BUFFER-FIELD('qt_dias_alerta'):BUFFER-VALUE
   ttSummary.titulo_configurado=phSignals:BUFFER-FIELD('titulo'):BUFFER-VALUE ttSummary.descricao_alerta=phSignals:BUFFER-FIELD('descricao'):BUFFER-VALUE
   ttSummary.tipo_registro=IF k<4 THEN 'Item' ELSE IF k=4 THEN 'Processo' ELSE 'Container'
   ttSummary.nome_alerta=ENTRY(k,'Recebimento SO/LD,Aprovação SO/LD,Término de produção,Adiantamento,Previsão de embarque') ttSummary.data_consulta=pdToday.
 END.
 CREATE BUFFER bOrders FOR TABLE phOrders BUFFER-NAME 'bSignalGlobalOrders'.
 CREATE BUFFER bCompanies FOR TABLE phCompanies BUFFER-NAME 'bSignalGlobalCompanies'.
 CREATE QUERY q. q:SET-BUFFERS(bOrders,bCompanies).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + bOrders:NAME + ' NO-LOCK WHERE cod_situacao=1, FIRST ' + bCompanies:NAME + ' NO-LOCK WHERE ' + bCompanies:NAME + '.empresa_id=' + bOrders:NAME + '.empresa_id AND ' + bCompanies:NAME + '.cod_emp_ems2=5') THEN RUN Fail(code,503).
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  RUN LimitCheck. pid=bOrders:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE.

   req=NEW JsonObject(). req:Add('operation','read'). req:Add('proc_compra_id',pid).
   RUN VALUE(servicePath)(phOrders,phCompanies,phItems,phPayments,phSignals,pdToday,50000 - scanned,started,req,OUTPUT responseValue,OUTPUT TABLE ttSignalRead,OUTPUT collectedProcess,OUTPUT collectedScanned).
   IF NOT responseValue:GetLogical('success') THEN DO:
    IF responseValue:GetJsonObject('error'):GetCharacter('code')='PURCHASE_SIGNAL_LIMIT' THEN RUN Fail('PURCHASE_SIGNALS_GLOBAL_LIMIT',503).
    RUN Fail(code,503).
   END.
   IF collectedProcess<>pid THEN RUN Fail(code,503).
   scanned=scanned + collectedScanned. RUN LimitCheck.
   FOR EACH ttSignalRead:
    CREATE ttDetail. BUFFER-COPY ttSignalRead TO ttDetail.
    ttDetail.link_proc_compra_id=ttDetail.proc_compra_id.
   END.

  q:GET-NEXT(NO-LOCK).
 END.
 q:QUERY-CLOSE(). DELETE OBJECT q. q=?.
 FIND ttSummary WHERE ttSummary.sinaliz_imp_id=5.
 CREATE QUERY q. q:SET-BUFFERS(phContainers).
 IF NOT q:QUERY-PREPARE('FOR EACH ' + phContainers:NAME + ' NO-LOCK WHERE situacao=1 AND dt_real_embarque=? AND SUBSTRING(cod-estabel,1,1)=~'5~'') THEN RUN Fail(code,503).
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  RUN LimitCheck.
  RUN VALUE(rulePath)(phContainers,ttSummary.dias_alerta,pdToday,OUTPUT matches).
  IF matches THEN DO:
   CREATE ttDetail. ASSIGN ttDetail.sinaliz_imp_id=5 ttDetail.tipo_registro='Container'
    ttDetail.container_id=phContainers:BUFFER-FIELD('nr-container'):BUFFER-VALUE ttDetail.link_container_id=ttDetail.container_id
    ttDetail.nome_alerta=ttSummary.nome_alerta ttDetail.titulo_configurado=ttSummary.titulo_configurado ttDetail.descricao_alerta=ttSummary.descricao_alerta
    ttDetail.dias_alerta=ttSummary.dias_alerta ttDetail.data_consulta=pdToday ttDetail.data_base=phContainers:BUFFER-FIELD('dt_prev_embarque'):BUFFER-VALUE
    ttDetail.data_alerta=pdToday + ttSummary.dias_alerta ttDetail.fornecedor_id=? .
  END.
  q:GET-NEXT(NO-LOCK).
 END.
 q:QUERY-CLOSE(). DELETE OBJECT q. q=?.
 FOR EACH ttDetail:
  FIND ttSummary WHERE ttSummary.sinaliz_imp_id=ttDetail.sinaliz_imp_id. ttSummary.quantidade=ttSummary.quantidade + 1.
 END.
 clean=CAST(poRequest:Clone(),JsonObject). IF clean:Has('sinaliz_imp_id') THEN clean:Remove('sinaliz_imp_id').
 IF pcResource='proc_compra_sinalizados' THEN DO:
  IF selectedRule>0 THEN FOR EACH ttDetail WHERE ttDetail.sinaliz_imp_id<>selectedRule: DELETE ttDetail. END.
  RUN VALUE(readerPath)(INPUT BUFFER ttDetail:HANDLE,pcResource,'5',clean,OUTPUT poResponse).
 END.
 ELSE RUN VALUE(readerPath)(INPUT BUFFER ttSummary:HANDLE,pcResource,'5',clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code',code). err:Add('status',statusCode). err:Add('message','Sinalizadores MED invalidos ou indisponiveis.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(bOrders) THEN DELETE OBJECT bOrders NO-ERROR.
  IF VALID-HANDLE(bCompanies) THEN DELETE OBJECT bCompanies NO-ERROR.
 END FINALLY.
END.



