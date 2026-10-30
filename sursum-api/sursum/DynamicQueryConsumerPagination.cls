USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Consumer-only bounds; independent of database and authentication credentials. */
CLASS DynamicQueryConsumerPagination:
 METHOD PUBLIC LOGICAL isValid(INPUT requestValue AS JsonObject):
  DEFINE VARIABLE names AS CHARACTER EXTENT 2 NO-UNDO.
  DEFINE VARIABLE limits AS INTEGER EXTENT 2 NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE numericValue AS DECIMAL NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT VALID-OBJECT(requestValue) THEN RETURN FALSE.
   IF requestValue:Has('execution') THEN DO:
    IF requestValue:GetType('execution')<>JsonDataType:STRING THEN RETURN FALSE.
    IF NOT COMPARE(requestValue:GetCharacter('execution'),'EQ','sync','RAW') AND NOT COMPARE(requestValue:GetCharacter('execution'),'EQ','async','RAW') THEN RETURN FALSE.
    IF THIS-OBJECT:isCursor(requestValue) AND requestValue:GetCharacter('execution')='async' THEN RETURN FALSE.
   END.
   IF requestValue:Has('paginate') THEN IF requestValue:GetType('paginate')<>JsonDataType:BOOLEAN THEN RETURN FALSE.
   IF requestValue:Has('paginationMode') THEN DO:
    IF requestValue:GetType('paginationMode')<>JsonDataType:STRING THEN RETURN FALSE.
    IF NOT COMPARE(requestValue:GetCharacter('paginationMode'),'EQ','offset','RAW') AND NOT COMPARE(requestValue:GetCharacter('paginationMode'),'EQ','cursor','RAW') THEN RETURN FALSE.
   END.
   IF THIS-OBJECT:isCursor(requestValue) THEN DO:
    IF requestValue:Has('page') THEN RETURN FALSE.
    IF requestValue:Has('paginate') THEN IF NOT requestValue:GetLogical('paginate') THEN RETURN FALSE.
   END.
   IF requestValue:Has('cursor') THEN DO:
    IF NOT THIS-OBJECT:isCursor(requestValue) OR requestValue:GetType('cursor')<>JsonDataType:STRING THEN RETURN FALSE.
    IF NOT THIS-OBJECT:validCursorText(requestValue:GetCharacter('cursor')) THEN RETURN FALSE.
   END.
   names[1]='page'. names[2]='pageSize'. limits[1]=1000000. limits[2]=1000.
   DO n=1 TO 2:
    IF NOT requestValue:Has(names[n]) THEN NEXT.
    IF requestValue:GetType(names[n])<>JsonDataType:NUMBER THEN RETURN FALSE.
    numericValue=requestValue:GetDecimal(names[n]).
    IF numericValue=? OR numericValue<1 OR numericValue>limits[n] OR numericValue<>TRUNCATE(numericValue,0) THEN RETURN FALSE.
   END.
   RETURN TRUE.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PUBLIC LOGICAL isCursor(INPUT requestValue AS JsonObject):
  IF NOT requestValue:Has('paginationMode') THEN RETURN FALSE.
  IF requestValue:GetType('paginationMode')<>JsonDataType:STRING THEN RETURN FALSE.
  RETURN COMPARE(requestValue:GetCharacter('paginationMode'),'EQ','cursor','RAW').
 END METHOD.
 METHOD PUBLIC LOGICAL isCursorDefinitionSupported(INPUT definitionValue AS JsonObject):
  DEFINE VARIABLE stepsValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE stepValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF NOT VALID-OBJECT(definitionValue) THEN RETURN FALSE.
   IF NOT definitionValue:Has('pipeline') THEN RETURN TRUE.
   IF definitionValue:IsNull('pipeline') THEN RETURN TRUE.
   IF definitionValue:GetType('pipeline')<>JsonDataType:ARRAY THEN RETURN FALSE.
   stepsValue=definitionValue:GetJsonArray('pipeline').
   DO n=1 TO stepsValue:Length:
    stepValue=stepsValue:GetJsonObject(n).
    IF LOOKUP(LC(stepValue:GetCharacter('type')),'source,join,select,filter,sort,limit,map')=0 THEN RETURN FALSE.
   END.
   RETURN TRUE.
   CATCH err AS Progress.Lang.Error: RETURN FALSE. END CATCH.
  END.
 END METHOD.
 METHOD PRIVATE LOGICAL validCursorText(INPUT textValue AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE payloadValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE signatureValue AS CHARACTER NO-UNDO.
  IF textValue='' THEN RETURN TRUE.
  IF textValue=? OR LENGTH(textValue,'RAW')>16384 OR NUM-ENTRIES(textValue,'.')<>3 THEN RETURN FALSE.
  IF NOT COMPARE(ENTRY(1,textValue,'.'),'EQ','v1','RAW') THEN RETURN FALSE.
  payloadValue=ENTRY(2,textValue,'.'). signatureValue=ENTRY(3,textValue,'.').
  IF LENGTH(payloadValue)=0 OR LENGTH(payloadValue)>16000 OR LENGTH(payloadValue) MODULO 2<>0 OR LENGTH(signatureValue)<>64 THEN RETURN FALSE.
  textValue=payloadValue + signatureValue.
  DO n=1 TO LENGTH(textValue): IF INDEX('0123456789abcdef',SUBSTRING(textValue,n,1))=0 THEN RETURN FALSE. END.
  RETURN TRUE.
 END METHOD.
 METHOD PUBLIC LOGICAL isPaginated(INPUT requestValue AS JsonObject):
  IF requestValue:Has('paginate') THEN RETURN requestValue:GetLogical('paginate').
  RETURN TRUE.
 END METHOD.
 METHOD PUBLIC JsonObject applyPagination(INPUT requestValue AS JsonObject, INPUT modelValue AS DynamicQueryRequestModel):
  DEFINE VARIABLE pageValue AS INTEGER NO-UNDO INITIAL 1.
  DEFINE VARIABLE sizeValue AS INTEGER NO-UNDO INITIAL 50.
  DEFINE VARIABLE reply AS JsonObject NO-UNDO.
  DEFINE VARIABLE detail AS JsonObject NO-UNDO.
  IF NOT THIS-OBJECT:isValid(requestValue) THEN DO:
   reply=NEW JsonObject(). detail=NEW JsonObject(). reply:Add('success',FALSE).
   detail:Add('code','INVALID_PAGINATION'). detail:Add('message','paginate deve ser booleano; page inteiro de 1 a 1000000; pageSize de 1 a 1000.').
   reply:Add('error',detail). RETURN reply.
  END.
  pageValue=modelValue:getPage(). sizeValue=modelValue:getPageSize().
  IF requestValue:Has('page') THEN pageValue=INTEGER(requestValue:GetDecimal('page')).
  IF requestValue:Has('pageSize') THEN sizeValue=INTEGER(requestValue:GetDecimal('pageSize')).
  /* Bound saved defaults too: omission must not bypass the consumer page-size limit. */
  sizeValue=MINIMUM(sizeValue,1000).
  IF NOT THIS-OBJECT:isPaginated(requestValue) THEN pageValue=1.
  IF THIS-OBJECT:isCursor(requestValue) THEN pageValue=1.
  modelValue:setPagination(pageValue,sizeValue).
  RETURN ?.
 END METHOD.
END CLASS.
