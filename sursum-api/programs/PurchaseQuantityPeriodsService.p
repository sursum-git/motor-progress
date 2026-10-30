/* Read-only UNION projection over the ONE shared collector. Physical identities
   never participate in duplicate elimination or point to an arbitrary row. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phOrders AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCompanies AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phContainers AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phSituations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER piDays AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/PurchaseImportQuantitiesTable.i}
DEFINE TEMP-TABLE ttPeriod NO-UNDO
 FIELD row_key AS CHARACTER CASE-SENSITIVE FIELD empresa_id AS INTEGER
 FIELD cod_situacao AS INTEGER FIELD pedido_fornec AS CHARACTER FIELD codigo_erp AS CHARACTER FIELD desc_item_fornec AS CHARACTER
 FIELD qt_comprada_final AS DECIMAL DECIMALS 10 FIELD vl_comprada_final AS DECIMAL DECIMALS 10 FIELD qt_rec_final AS DECIMAL DECIMALS 10 FIELD vl_rec_final AS DECIMAL DECIMALS 10
 FIELD nr_container AS CHARACTER FIELD situacao_container AS INTEGER FIELD dt_registro AS DATE FIELD dt_recebimento AS DATE FIELD dt_prev_chegada AS DATE
 FIELD qt_comprada AS DECIMAL DECIMALS 10 FIELD vl_negociado AS DECIMAL DECIMALS 10 FIELD qt_confirmada_embarque AS DECIMAL DECIMALS 10 FIELD qt_recbto_fisico AS DECIMAL DECIMALS 10
 FIELD desc_situacao_container AS CHARACTER FIELD canonical_text AS CHARACTER CASE-SENSITIVE
 INDEX pk IS PRIMARY UNIQUE row_key.
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO. DEFINE VARIABLE filterPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE rulesPath AS CHARACTER NO-UNDO. DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO. DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 422.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_QUANTITY_PERIOD_VALIDATION'.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO. DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE filterResult AS JsonObject NO-UNDO. DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE collected AS JsonObject NO-UNDO. DEFINE VARIABLE periods AS JsonObject NO-UNDO.
DEFINE VARIABLE rowDates AS JsonObject NO-UNDO. DEFINE VARIABLE decision AS JsonObject NO-UNDO.
DEFINE VARIABLE projection AS JsonObject NO-UNDO. DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE f AS HANDLE NO-UNDO. DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO. DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE canonical AS LONGCHAR NO-UNDO.
DEFINE VARIABLE projectionFields AS CHARACTER NO-UNDO INITIAL 'cod_situacao,pedido_fornec,vl_negociado,qt_comprada,qt_confirmada_embarque,qt_recbto_fisico,qt_rec_final,vl_rec_final,qt_comprada_final,vl_comprada_final,nr_container,situacao_container,dt_registro,dt_recebimento,dt_prev_chegada,codigo_erp,desc_item_fornec'.
{sursum-api/includes/PurchaseQuantityPeriodDates.i}
PROCEDURE Fail:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER s AS INTEGER NO-UNDO.
 code=c. statusCode=s. UNDO,THROW NEW Progress.Lang.AppError('Consulta por periodo invalida ou indisponivel.',1).
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 started=ETIME.
 IF NOT VALID-OBJECT(poRequest) OR NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail(code,422).
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'read,get')=0 THEN RUN Fail('PURCHASE_QUANTITY_READ_ONLY',405).
 names=poRequest:GetNames(). DO k=1 TO EXTENT(names):
  IF LOOKUP(names[k],IF op='get' THEN 'operation,id,record_key' ELSE 'operation,skip,take,sort,filter')=0 THEN RUN Fail(code,422).
 END.
 IF NOT VALID-HANDLE(phItems) THEN RUN Fail('PURCHASE_QUANTITY_PERIOD_CONFIGURATION',503).
 DO k=1 TO 3:
  f=phItems:BUFFER-FIELD(ENTRY(k,'dt_termino_producao,dt_prev_termino_producao,dt_maxima_producao')) NO-ERROR.
  IF NOT VALID-HANDLE(f) THEN RUN Fail('PURCHASE_QUANTITY_PERIOD_CONFIGURATION',503).
  IF f:DATA-TYPE<>'DATE' THEN RUN Fail('PURCHASE_QUANTITY_PERIOD_CONFIGURATION',503).
 END.
 ASSIGN code='PURCHASE_QUANTITY_PERIOD_CONFIGURATION' statusCode=503.
 collectorPath=SEARCH('sursum-api/programs/PurchaseImportQuantitiesCollector.r'). filterPath=SEARCH('sursum-api/programs/PurchaseQuantityPeriodFilter.r').
 rulesPath=SEARCH('sursum-api/programs/PurchaseQuantityPeriodRules.r'). readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF collectorPath=? OR filterPath=? OR rulesPath=? OR readerPath=? THEN RUN Fail(code,503).
 RUN VALUE(filterPath)(poRequest,OUTPUT filterResult). IF NOT filterResult:GetLogical('success') THEN DO: poResponse=filterResult. RETURN. END.
 clean=filterResult:GetJsonObject('request'). periods=filterResult:GetJsonObject('periods').
 /* Collector validates the closed envelope and MED; no repeated API paging. */
 RUN VALUE(collectorPath)(phOrders,phCompanies,phItems,phAllocations,phContainers,phSituations,clean,OUTPUT collected,OUTPUT TABLE ttQuantityRead,OUTPUT companyId).
 IF NOT collected:GetLogical('success') THEN DO: poResponse=collected. RETURN. END.
 b=BUFFER ttQuantityRead:HANDLE.
 FIX-CODEPAGE(canonical)='UTF-8'.
 FOR EACH ttQuantityRead:
  IF ETIME - started>10000 THEN RUN Fail('PURCHASE_QUANTITY_LIMIT',503).
  rowDates=NEW JsonObject().
  DO k=1 TO 6:
   fieldName=ENTRY(k,'dt_registro,dt_recebimento,dt_prev_chegada,dt_termino_producao,dt_prev_termino_producao,dt_maxima_producao'). f=b:BUFFER-FIELD(fieldName).
   IF f:BUFFER-VALUE=? THEN rowDates:AddNull(fieldName). ELSE rowDates:Add(fieldName,ISO-DATE(DATE(f:BUFFER-VALUE))).
  END.
  RUN VALUE(rulesPath)(rowDates,periods,piDays,OUTPUT decision).
  IF NOT decision:GetLogical('admitted') THEN NEXT.
  ttQuantityRead.dt_prev_chegada=PurchasePeriodDate(decision,'dt_prev_chegada').
  projection=NEW JsonObject().
  DO k=1 TO NUM-ENTRIES(projectionFields):
   fieldName=ENTRY(k,projectionFields). f=b:BUFFER-FIELD(fieldName).
   IF f:BUFFER-VALUE=? THEN projection:AddNull(fieldName).
   ELSE CASE f:DATA-TYPE:
    WHEN 'CHARACTER' THEN projection:Add(fieldName,STRING(f:BUFFER-VALUE)).
    WHEN 'INTEGER' THEN projection:Add(fieldName,INTEGER(f:BUFFER-VALUE)).
    WHEN 'DECIMAL' THEN projection:Add(fieldName,DECIMAL(f:BUFFER-VALUE)).
    WHEN 'DATE' THEN projection:Add(fieldName,ISO-DATE(DATE(f:BUFFER-VALUE))).
   END CASE.
  END.
  projection:Write(canonical,FALSE). keyValue=CAPS(HEX-ENCODE(MESSAGE-DIGEST('SHA-256',canonical))).
  FIND ttPeriod WHERE ttPeriod.row_key=keyValue NO-ERROR.
  IF AVAILABLE ttPeriod THEN DO:
   /* A digest collision fails closed instead of dropping a distinct row. */
   IF NOT COMPARE(ttPeriod.canonical_text,'=',STRING(canonical),'RAW') THEN RUN Fail('PURCHASE_QUANTITY_PERIOD_COLLISION',503).
   NEXT.
  END.
  CREATE ttPeriod.
  BUFFER-COPY ttQuantityRead EXCEPT proc_compra_id item_proc_compra_id item_container_id container_id dt_termino_producao dt_prev_termino_producao dt_maxima_producao TO ttPeriod.
  ASSIGN ttPeriod.row_key=keyValue ttPeriod.canonical_text=STRING(canonical).
 END.
 RUN VALUE(readerPath)(INPUT BUFFER ttPeriod:HANDLE,'proc_compra_quantidades_periodo_med',TRIM(STRING(companyId,'->>>>>>>>>9')),clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code',code). err:Add('status',statusCode). err:Add('message','Consulta por periodo invalida ou indisponivel.'). poResponse:Add('error',err).
 END CATCH.
END.
