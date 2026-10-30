/* Extract only complete conjunctive legacy periods; other predicates stay in
   the existing closed reader. Never accepts SQL or a client predicate string. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE periods AS JsonObject NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE filtered AS JsonObject NO-UNDO.
DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE rangeValue AS JsonObject NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE leaves AS INTEGER NO-UNDO.
{sursum-api/includes/PurchaseQuantityPeriodDates.i}
FUNCTION Extract RETURNS JsonObject(node AS JsonObject,depthValue AS INTEGER,conjunctive AS LOGICAL) FORWARD.
PROCEDURE Invalid:
 UNDO,THROW NEW Progress.Lang.AppError('Use Igual ou Entre com faixa completa para os periodos, unidos por E.',1).
END PROCEDURE.
PROCEDURE Bound:
 DEFINE INPUT PARAMETER fieldName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER boundName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER dateValue AS DATE NO-UNDO.
 DEFINE VARIABLE bounds AS JsonObject NO-UNDO.
 IF NOT periods:Has(fieldName) THEN periods:Add(fieldName,NEW JsonObject()).
 bounds=periods:GetJsonObject(fieldName).
 IF bounds:Has(boundName) OR dateValue=? THEN RUN Invalid.
 bounds:Add(boundName,ISO-DATE(dateValue)).
END PROCEDURE.
FUNCTION Extract RETURNS JsonObject(node AS JsonObject,depthValue AS INTEGER,conjunctive AS LOGICAL):
 DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE children AS JsonArray NO-UNDO.
 DEFINE VARIABLE kept AS JsonArray NO-UNDO.
 DEFINE VARIABLE child AS JsonObject NO-UNDO.
 DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE logicValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE fieldName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE operatorValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE dateValue AS DATE NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(node) OR depthValue>6 THEN RUN Invalid.
 ns=node:GetNames().
 IF node:Has('filters') THEN DO:
  IF EXTENT(ns)<>2 OR NOT node:Has('logic') OR node:GetType('logic')<>JsonDataType:STRING THEN RUN Invalid.
  logicValue=node:GetCharacter('logic'). IF LOOKUP(logicValue,'and,or')=0 THEN RUN Invalid.
  children=node:GetJsonArray('filters'). IF children:Length<1 OR children:Length>50 THEN RUN Invalid.
  kept=NEW JsonArray().
  DO j=1 TO children:Length:
   child=Extract(children:GetJsonObject(j),depthValue + 1,conjunctive AND logicValue='and').
   IF VALID-OBJECT(child) THEN kept:Add(child).
  END.
  IF kept:Length=0 THEN RETURN ?.
  IF kept:Length=1 THEN RETURN kept:GetJsonObject(1).
  resultValue=NEW JsonObject(). resultValue:Add('logic',logicValue). resultValue:Add('filters',kept). RETURN resultValue.
 END.
 leaves=leaves + 1. IF leaves>50 OR NOT node:Has('field') OR node:GetType('field')<>JsonDataType:STRING THEN RUN Invalid.
 fieldName=node:GetCharacter('field').
 /* JSON names are case sensitive. A misspelled period must never be removed
    and silently ignored, nor fall through to a different reader predicate. */
 IF LOOKUP(CAPS(fieldName),'DT_REGISTRO,DT_RECEBIMENTO,DT_PREV_CHEGADA')>0
  AND LOOKUP(fieldName,'dt_registro,dt_recebimento,dt_prev_chegada')=0 THEN RUN Invalid.
 IF LOOKUP(fieldName,'dt_registro,dt_recebimento,dt_prev_chegada')=0 THEN RETURN CAST(node:Clone(),JsonObject).
 IF NOT conjunctive OR NOT node:Has('operator') OR node:GetType('operator')<>JsonDataType:STRING THEN RUN Invalid.
 DO j=1 TO EXTENT(ns): IF LOOKUP(ns[j],'field,operator,value,ignoreCase')=0 THEN RUN Invalid. END.
 IF node:Has('ignoreCase') THEN DO: IF node:GetType('ignoreCase')<>JsonDataType:BOOLEAN OR NOT node:GetLogical('ignoreCase') THEN RUN Invalid. END.
 operatorValue=node:GetCharacter('operator'). IF LOOKUP(operatorValue,'gte,lte,eq')=0 THEN RUN Invalid.
 dateValue=PurchasePeriodDate(node,'value'). IF dateValue=? THEN RUN Invalid.
 IF operatorValue='gte' OR operatorValue='eq' THEN RUN Bound(fieldName,'start',dateValue).
 IF operatorValue='lte' OR operatorValue='eq' THEN RUN Bound(fieldName,'end',dateValue).
 RETURN ?.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 periods=NEW JsonObject(). clean=CAST(poRequest:Clone(),JsonObject).
 IF clean:Has('filter') THEN DO:
  filtered=Extract(clean:GetJsonObject('filter'),0,TRUE). clean:Remove('filter').
  IF VALID-OBJECT(filtered) THEN clean:Add('filter',filtered).
 END.
 names=periods:GetNames(). DO k=1 TO EXTENT(names):
  rangeValue=periods:GetJsonObject(names[k]).
  IF NOT rangeValue:Has('start') OR NOT rangeValue:Has('end') THEN RUN Invalid.
  IF PurchasePeriodDate(rangeValue,'start')>PurchasePeriodDate(rangeValue,'end') THEN RUN Invalid.
 END.
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE). poResponse:Add('request',clean). poResponse:Add('periods',periods).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject(). errorValue:Add('code','PURCHASE_QUANTITY_PERIOD_FILTER'). errorValue:Add('status',422). errorValue:Add('message','Periodos invalidos. Use Igual ou Entre com faixa completa, unidos por E.'). poResponse:Add('error',errorValue).
 END CATCH.
END.
