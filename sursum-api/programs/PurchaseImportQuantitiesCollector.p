/* Fixed MED projection of the legacy LEFT JOIN, global or process-contextual.
   Only temp rows are created. Rules, owner validation and reader are reused. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSituations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseImportQuantitiesTable.i}
DEFINE OUTPUT PARAMETER TABLE FOR ttQuantityRead.
DEFINE OUTPUT PARAMETER piCompanyId AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseContextCode AS CHARACTER NO-UNDO INITIAL 'PURCHASE_QUANTITY'.
DEFINE VARIABLE pid AS INTEGER NO-UNDO. DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE itemId AS INTEGER NO-UNDO. DEFINE VARIABLE allocationId AS INTEGER NO-UNDO.
DEFINE VARIABLE containerId AS INTEGER NO-UNDO. DEFINE VARIABLE statusValue AS INTEGER NO-UNDO.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422. DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_QUANTITY_VALIDATION'.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE scanned AS INTEGER NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE rulePath AS CHARACTER NO-UNDO. DEFINE VARIABLE readPath AS CHARACTER NO-UNDO. DEFINE VARIABLE medPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE ems5 AS CHARACTER NO-UNDO. DEFINE VARIABLE rules AS JsonObject NO-UNDO. DEFINE VARIABLE requestCopy AS JsonObject NO-UNDO. DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE qo AS HANDLE NO-UNDO. DEFINE VARIABLE qi AS HANDLE NO-UNDO. DEFINE VARIABLE qa AS HANDLE NO-UNDO.
DEFINE VARIABLE hasAllocation AS LOGICAL NO-UNDO. DEFINE VARIABLE hasContainer AS LOGICAL NO-UNDO.
DEFINE VARIABLE confirmedValue AS DECIMAL NO-UNDO. DEFINE VARIABLE physicalValue AS DECIMAL NO-UNDO.
{sursum-api/includes/PurchaseJsonContract.i}
FUNCTION N RETURNS CHARACTER(v AS INTEGER): RETURN TRIM(STRING(v,'->>>>>>>>>9')). END FUNCTION.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 code=c. statusCode=s. UNDO,THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
{sursum-api/includes/PurchaseOrderContext.i}
PROCEDURE GuardScan:
 scanned=scanned + 1.
 IF scanned>50000 OR ETIME - started>10000 THEN RUN Fail('PURCHASE_QUANTITY_LIMIT',503,'Limite de leitura excedido.').
END PROCEDURE.
FUNCTION ItemDate RETURNS DATE(fieldName AS CHARACTER):
 DEFINE VARIABLE h AS HANDLE NO-UNDO.
 h=phItems:BUFFER-FIELD(fieldName) NO-ERROR.
 IF NOT VALID-HANDLE(h) THEN RETURN ?.
 IF h:DATA-TYPE<>'DATE' THEN RUN Fail('PURCHASE_QUANTITY_CONFIGURATION',503,'Campo de data invalido.').
 RETURN h:BUFFER-VALUE.
END FUNCTION.
PROCEDURE AppendRow:
 ASSIGN allocationId=IF hasAllocation THEN phAllocations:BUFFER-FIELD('item_container_id'):BUFFER-VALUE ELSE 0
  containerId=IF hasAllocation THEN phAllocations:BUFFER-FIELD('container_id'):BUFFER-VALUE ELSE 0
  confirmedValue=IF hasAllocation THEN phAllocations:BUFFER-FIELD('qt_confirm_emb'):BUFFER-VALUE ELSE 0
  physicalValue=IF hasAllocation THEN phAllocations:BUFFER-FIELD('qt_recbto_fisico'):BUFFER-VALUE ELSE 0.
 IF allocationId=? OR allocationId<0 OR (hasAllocation AND allocationId=0) THEN RUN Fail('PURCHASE_QUANTITY_IDENTITY',409,'Identidade invalida.').
 hasContainer=FALSE. IF containerId<>? AND containerId>0 THEN hasContainer=Found(phContainers,'nr-container=' + N(containerId),NO-LOCK).
 RUN VALUE(rulePath)(DECIMAL(phItems:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE),DECIMAL(phItems:BUFFER-FIELD('vl_negociado'):BUFFER-VALUE),confirmedValue,physicalValue,OUTPUT rules).
 CREATE ttQuantityRead.
 ASSIGN ttQuantityRead.proc_compra_id=phOrders:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE ttQuantityRead.empresa_id=companyId ttQuantityRead.item_proc_compra_id=itemId ttQuantityRead.item_container_id=allocationId ttQuantityRead.container_id=containerId
  ttQuantityRead.cod_situacao=statusValue ttQuantityRead.pedido_fornec=phOrders:BUFFER-FIELD('cod_proc_fornec'):BUFFER-VALUE ttQuantityRead.codigo_erp=phItems:BUFFER-FIELD('codigo_erp'):BUFFER-VALUE ttQuantityRead.desc_item_fornec=phItems:BUFFER-FIELD('descricao'):BUFFER-VALUE
  ttQuantityRead.qt_comprada_final=IF rules:IsNull('qt_comprada_final') THEN ? ELSE rules:GetDecimal('qt_comprada_final')
  ttQuantityRead.vl_comprada_final=IF rules:IsNull('vl_comprada_final') THEN ? ELSE rules:GetDecimal('vl_comprada_final')
  ttQuantityRead.qt_rec_final=rules:GetDecimal('qt_rec_final') ttQuantityRead.vl_rec_final=IF rules:IsNull('vl_rec_final') THEN ? ELSE rules:GetDecimal('vl_rec_final')
  ttQuantityRead.nr_container=IF hasContainer THEN N(containerId) ELSE 'Nao Alocado'
  ttQuantityRead.situacao_container=IF hasContainer AND phContainers:BUFFER-FIELD('situacao_container_id'):BUFFER-VALUE<>? THEN phContainers:BUFFER-FIELD('situacao_container_id'):BUFFER-VALUE ELSE 100
  ttQuantityRead.dt_termino_producao=ItemDate('dt_termino_producao') ttQuantityRead.dt_prev_termino_producao=ItemDate('dt_prev_termino_producao') ttQuantityRead.dt_maxima_producao=ItemDate('dt_maxima_producao')
  ttQuantityRead.dt_registro=phOrders:BUFFER-FIELD('dt_registro'):BUFFER-VALUE
  ttQuantityRead.dt_recebimento=IF hasContainer THEN phContainers:BUFFER-FIELD('dt-recebimento'):BUFFER-VALUE ELSE ?
  ttQuantityRead.dt_prev_chegada=IF hasContainer THEN phContainers:BUFFER-FIELD('dt-prev-chegada'):BUFFER-VALUE ELSE ?
  ttQuantityRead.qt_comprada=phItems:BUFFER-FIELD('qt_comprada'):BUFFER-VALUE ttQuantityRead.vl_negociado=phItems:BUFFER-FIELD('vl_negociado'):BUFFER-VALUE
  ttQuantityRead.qt_confirmada_embarque=IF confirmedValue=? THEN 0 ELSE confirmedValue ttQuantityRead.qt_recbto_fisico=IF physicalValue=? THEN 0 ELSE physicalValue.
 ttQuantityRead.desc_situacao_container=N(ttQuantityRead.situacao_container).
 IF Found(phSituations,'situacao_container_id=' + N(ttQuantityRead.situacao_container),NO-LOCK) THEN ttQuantityRead.desc_situacao_container=phSituations:BUFFER-FIELD('descricao'):BUFFER-VALUE.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phOrders) OR NOT VALID-HANDLE(phCompanies) OR NOT VALID-HANDLE(phItems) OR NOT VALID-HANDLE(phAllocations) OR NOT VALID-HANDLE(phContainers) OR NOT VALID-HANDLE(phSituations) THEN RUN Fail('PURCHASE_QUANTITY_CONFIGURATION',503,'Configuracao indisponivel.').
 IF NOT VALID-OBJECT(poRequest) OR NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422,'Operacao obrigatoria.').
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'read,get')=0 THEN RUN Fail('PURCHASE_QUANTITY_READ_ONLY',405,'Somente leitura.').
 ns=poRequest:GetNames(). DO k=1 TO EXTENT(ns):
  IF LOOKUP(ns[k],IF op='get' THEN 'operation,proc_compra_id,id,record_key' ELSE 'operation,proc_compra_id,skip,take,sort,filter')=0 THEN RUN Fail(code,422,'Campo nao permitido.').
 END.
 IF poRequest:Has('proc_compra_id') THEN DO: pid=PurchaseJsonId(poRequest,'proc_compra_id'). RUN OrderContextCheck(NO-LOCK). END.
 ASSIGN code='PURCHASE_QUANTITY_CONFIGURATION' statusCode=503.
 medPath=SEARCH('sursum-api/programs/CiwMedCompanyContext.r'). rulePath=SEARCH('sursum-api/programs/PurchaseImportQuantityRules.r').
 IF medPath=? OR rulePath=? THEN RUN Fail(code,503,'Rotina compartilhada indisponivel.').
 RUN VALUE(medPath)(phCompanies,OUTPUT ems5).
 IF NOT Found(phCompanies,'cod_emp_ems2=5',NO-LOCK) THEN RUN Fail(code,503,'Empresa MED indisponivel.').
 companyId=phCompanies:BUFFER-FIELD('empresa_id'):BUFFER-VALUE. IF companyId=? OR companyId<1 THEN RUN Fail(code,503,'Empresa invalida.').
 started=ETIME.
 CREATE QUERY qo. qo:SET-BUFFERS(phOrders).
 IF NOT qo:QUERY-PREPARE('FOR EACH ' + phOrders:NAME + ' NO-LOCK WHERE empresa_id=' + N(companyId) + (IF pid>0 THEN ' AND proc_compra_id=' + N(pid) ELSE '')) THEN RUN Fail(code,503,'Consulta indisponivel.').
 qo:QUERY-OPEN(). qo:GET-FIRST(NO-LOCK).
 DO WHILE NOT qo:QUERY-OFF-END:
  RUN GuardScan. statusValue=phOrders:BUFFER-FIELD('cod_situacao'):BUFFER-VALUE.
  IF statusValue<>? AND statusValue<>3 THEN DO:
   CREATE QUERY qi. qi:SET-BUFFERS(phItems).
   IF NOT qi:QUERY-PREPARE('FOR EACH ' + phItems:NAME + ' NO-LOCK WHERE proc_compra_id=' + N(phOrders:BUFFER-FIELD('proc_compra_id'):BUFFER-VALUE)) THEN RUN Fail(code,503,'Consulta indisponivel.').
   qi:QUERY-OPEN(). qi:GET-FIRST(NO-LOCK).
   DO WHILE NOT qi:QUERY-OFF-END:
    RUN GuardScan. itemId=phItems:BUFFER-FIELD('item_proc_compra_id'):BUFFER-VALUE. IF itemId=? OR itemId<1 THEN RUN Fail(code,503,'Identidade invalida.').
    CREATE QUERY qa. qa:SET-BUFFERS(phAllocations).
    IF NOT qa:QUERY-PREPARE('FOR EACH ' + phAllocations:NAME + ' NO-LOCK WHERE item_proc_compra_id=' + N(itemId)) THEN RUN Fail(code,503,'Consulta indisponivel.').
    qa:QUERY-OPEN(). qa:GET-FIRST(NO-LOCK). hasAllocation=NOT qa:QUERY-OFF-END.
    IF NOT hasAllocation THEN RUN AppendRow.
    DO WHILE NOT qa:QUERY-OFF-END:
     RUN GuardScan. RUN AppendRow. qa:GET-NEXT(NO-LOCK).
    END.
    qa:QUERY-CLOSE(). DELETE OBJECT qa. qa=?. qi:GET-NEXT(NO-LOCK).
   END.
   qi:QUERY-CLOSE(). DELETE OBJECT qi. qi=?.
  END.
  qo:GET-NEXT(NO-LOCK).
 END.
 piCompanyId=companyId. poResponse=NEW JsonObject(). poResponse:Add('success',TRUE).
 CATCH e AS Progress.Lang.Error:
  EMPTY TEMP-TABLE ttQuantityRead.
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code',code). err:Add('status',statusCode). err:Add('message','Consulta de quantidades invalida ou indisponivel.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(qa) THEN DO: qa:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qa NO-ERROR. END.
  IF VALID-HANDLE(qi) THEN DO: qi:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qi NO-ERROR. END.
  IF VALID-HANDLE(qo) THEN DO: qo:QUERY-CLOSE() NO-ERROR. DELETE OBJECT qo NO-ERROR. END.
 END FINALLY.
END.
