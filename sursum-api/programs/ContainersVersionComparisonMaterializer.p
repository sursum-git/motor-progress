/* Snapshot assembly and current INNER JOIN only. Financial projection is shared. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phPurchaseItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER poSnapshot AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER piContainer AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piVersion AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcCurrency AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER piStarted AS INTEGER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piReads AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER poOutput AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttSeen NO-UNDO FIELD idValue AS INTEGER INDEX pk IS PRIMARY UNIQUE idValue.
DEFINE VARIABLE headerValue AS JsonObject NO-UNDO.
DEFINE VARIABLE itemsValue AS JsonArray NO-UNDO.
DEFINE VARIABLE resultRows AS JsonArray NO-UNDO.
DEFINE VARIABLE itemValue AS JsonObject NO-UNDO.
DEFINE VARIABLE normalized AS JsonObject NO-UNDO.
DEFINE VARIABLE projected AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE labelsValue AS JsonObject NO-UNDO.
DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE labelsPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE projectionPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE mapFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE outputFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE sourceField AS CHARACTER NO-UNDO.
DEFINE VARIABLE targetField AS CHARACTER NO-UNDO.
DEFINE VARIABLE errorCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE idValue AS INTEGER NO-UNDO.
DEFINE VARIABLE allocationValue AS INTEGER NO-UNDO.
DEFINE VARIABLE completed AS LOGICAL NO-UNDO.
FUNCTION KeyValue RETURNS INTEGER(objectValue AS JsonObject,fieldName AS CHARACTER,nullableValue AS LOGICAL):
 DEFINE VARIABLE amountValue AS DECIMAL NO-UNDO.
 IF NOT objectValue:Has(fieldName) THEN RUN Fail('COMPARISON_SNAPSHOT',503).
 IF objectValue:IsNull(fieldName) AND nullableValue THEN RETURN ?.
 IF objectValue:GetType(fieldName)<>JsonDataType:NUMBER THEN RUN Fail('COMPARISON_SNAPSHOT',503).
 amountValue=objectValue:GetDecimal(fieldName).
 IF amountValue=? OR amountValue<1 OR amountValue>2147483647 OR amountValue<>TRUNCATE(amountValue,0) THEN RUN Fail('COMPARISON_SNAPSHOT',503).
 RETURN INTEGER(amountValue).
END FUNCTION.
PROCEDURE CopyNumber:
 DEFINE INPUT PARAMETER fromValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER fromField AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER toValue AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER toField AS CHARACTER NO-UNDO.
 IF NOT fromValue:Has(fromField) THEN RUN Fail('COMPARISON_SNAPSHOT',503).
 IF fromValue:IsNull(fromField) THEN toValue:AddNull(toField).
 ELSE DO:
  IF fromValue:GetType(fromField)<>JsonDataType:NUMBER THEN RUN Fail('COMPARISON_SNAPSHOT',503).
  toValue:Add(toField,fromValue:GetDecimal(fromField)).
 END.
END PROCEDURE.
DO ON ERROR UNDO, THROW:
 IF pcCurrency<>'real' AND pcCurrency<>'dolar' THEN RUN Fail('COMPARISON_CONTEXT',422).
 IF piContainer=? OR piContainer<1 OR piVersion=? OR piVersion<1 OR piStarted=? OR piReads=? OR piReads<0 OR piReads>50000 THEN RUN Fail('COMPARISON_CONTEXT',422).
 IF NOT VALID-OBJECT(poSnapshot) THEN RUN Fail('COMPARISON_SNAPSHOT',503).
 headerValue=poSnapshot:GetJsonObject('header'). itemsValue=poSnapshot:GetJsonArray('items').
 IF KeyValue(headerValue,'container_id',FALSE)<>piContainer OR KeyValue(headerValue,'versao_id',FALSE)<>piVersion THEN RUN Fail('COMPARISON_CONTEXT',422).
 labelsPath=SEARCH('sursum-api/programs/ContainersVersionHistoryLabels.r').
 IF labelsPath=? THEN labelsPath=SEARCH('ContainersVersionHistoryLabels.r').
 IF labelsPath=? THEN labelsPath=SEARCH('ContainersVersionHistoryLabels.p').
 projectionPath=SEARCH('sursum-api/programs/ContainersVersionComparisonProjection.r').
 IF projectionPath=? THEN projectionPath=SEARCH('ContainersVersionComparisonProjection.r').
 IF projectionPath=? THEN projectionPath=SEARCH('ContainersVersionComparisonProjection.p').
 IF labelsPath=? OR projectionPath=? THEN RUN Fail('COMPARISON_CONFIGURATION',503).
 mapFields=IF pcCurrency='real' THEN 'qt_alocada,qt_confirm_emb,vl_custo_prev_real,vl_desp_prev_real,vl_unit_prev,vl_desp_prev_real_sem_distr_cust'
  ELSE 'qt_alocada,qt_confirm_emb,vl_custo_prev_dolar,vl_desp_prev_dolar,vl_unit_prev_dolar,vl_desp_prev_dolar_sem_distr_cus'.
 outputFields='qt_alocada,qt_confirm_emb,vl_custo_prev,vl_desp_prev,vl_tot_prev,vl_unit_prev,vl_desp_prev_sem_distr_custo,vl_tot_sem_distr_custo,vl_unit_sem_distr_custo,vl_desp_prev_perc_fixo,vl_tot_perc_fixo,vl_unit_perc_fixo'.
 resultRows=NEW JsonArray().
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  DO n=1 TO itemsValue:Length:
   IF piReads>=50000 OR ETIME - piStarted>10000 THEN RUN Fail('COMPARISON_READ_BUDGET',503).
   itemValue=itemsValue:GetJsonObject(n).
   IF KeyValue(itemValue,'versao_id',FALSE)<>piVersion THEN RUN Fail('COMPARISON_CONTEXT',422).
   idValue=KeyValue(itemValue,'item_container_custo_id',FALSE). allocationValue=KeyValue(itemValue,'item_container_id',TRUE).
   FIND FIRST ttSeen WHERE ttSeen.idValue=idValue NO-ERROR.
   IF AVAILABLE ttSeen THEN RUN Fail('COMPARISON_AMBIGUOUS',409).
   CREATE ttSeen. ttSeen.idValue=idValue. RELEASE ttSeen.
   RUN VALUE(labelsPath)(phAllocations,phPurchaseItems,?,?, 'item_join',allocationValue,piStarted,INPUT-OUTPUT piReads,OUTPUT labelsValue).
   IF NOT labelsValue:GetLogical('item_join_exists') THEN NEXT.
   normalized=NEW JsonObject().
   DO j=1 TO 6:
    sourceField=ENTRY(j,mapFields). targetField=ENTRY(j,'qt_alocada,qt_confirm_emb,vl_custo_prev,vl_desp_prev,vl_unit_prev,vl_desp_prev_sem_distr_custo').
    RUN CopyNumber(itemValue,sourceField,normalized,targetField).
   END.
   RUN CopyNumber(headerValue,'perc_fixo_container',normalized,'perc_fixo_container').
   RUN VALUE(projectionPath)(normalized,OUTPUT projected).
   errorCode=''.
   IF projected:GetLogical('success') THEN rowValue=projected:GetJsonObject('data').
   ELSE DO:
    errorCode=projected:GetJsonObject('error'):GetCharacter('code').
    IF errorCode<>'COMPARISON_ZERO_DIVISOR' THEN RUN Fail(errorCode,503).
    rowValue=NEW JsonObject().
    DO j=1 TO NUM-ENTRIES(outputFields):
     targetField=ENTRY(j,outputFields).
     IF normalized:Has(targetField) THEN RUN CopyNumber(normalized,targetField,rowValue,targetField).
     ELSE rowValue:AddNull(targetField).
    END.
   END.
   rowValue:Add('container_id',piContainer). rowValue:Add('versao_id',piVersion).
   rowValue:Add('item_container_custo_id',idValue).
   IF allocationValue=? THEN rowValue:AddNull('item_container_id'). ELSE rowValue:Add('item_container_id',allocationValue).
   IF labelsValue:IsNull('item_codigo_erp_atual') THEN rowValue:AddNull('codigo_erp'). ELSE rowValue:Add('codigo_erp',labelsValue:GetCharacter('item_codigo_erp_atual')).
   IF labelsValue:IsNull('item_descricao_atual') THEN rowValue:AddNull('descricao'). ELSE rowValue:Add('descricao',labelsValue:GetCharacter('item_descricao_atual')).
   rowValue:Add('_projection_error',errorCode). resultRows:Add(rowValue).
  END.
  completed=TRUE.
 END.
 IF NOT completed THEN RUN Fail('COMPARISON_READ_BUDGET',503).
 poOutput=NEW JsonObject(). poOutput:Add('success',TRUE). poOutput:Add('data',resultRows).
 CATCH err AS Progress.Lang.Error:
  errorCode=err:GetMessage(1).
  IF LOOKUP(errorCode,'COMPARISON_CONTEXT,COMPARISON_SNAPSHOT,COMPARISON_CONFIGURATION,COMPARISON_READ_BUDGET,COMPARISON_AMBIGUOUS,COMPARISON_SQL_NULL_ZERO_UNPROVEN')=0 THEN errorCode='COMPARISON_CONFIGURATION'.
  errorValue=NEW JsonObject(). errorValue:Add('code',errorCode). errorValue:Add('status',IF errorCode='COMPARISON_CONTEXT' THEN 422 ELSE IF errorCode='COMPARISON_AMBIGUOUS' THEN 409 ELSE 503).
  poOutput=NEW JsonObject(). poOutput:Add('success',FALSE). poOutput:Add('error',errorValue).
 END CATCH.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER errorCode AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 UNDO,THROW NEW Progress.Lang.AppError(errorCode,statusValue).
END PROCEDURE.
