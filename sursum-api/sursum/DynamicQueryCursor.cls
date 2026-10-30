USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Stateless, authenticated continuation over a unique tuple. No ROWID or open session cursor. */
CLASS DynamicQueryCursor:
 DEFINE PRIVATE VARIABLE secretValue AS CHARACTER NO-UNDO.
 DEFINE PRIVATE VARIABLE bindingValue AS CHARACTER NO-UNDO.
 DEFINE PRIVATE VARIABLE schemaValue AS CHARACTER NO-UNDO.
 DEFINE PRIVATE VARIABLE nowValue AS INT64 NO-UNDO.
 DEFINE PRIVATE VARIABLE keyCount AS INTEGER NO-UNDO.
 DEFINE PRIVATE TEMP-TABLE ttKey NO-UNDO
  FIELD keyOrder AS INTEGER FIELD tableName AS CHARACTER FIELD fieldName AS CHARACTER
  FIELD bufferValue AS HANDLE FIELD fieldValue AS HANDLE FIELD typeValue AS CHARACTER
  FIELD descendingValue AS LOGICAL FIELD uniqueValue AS LOGICAL
  INDEX keyOrder IS PRIMARY UNIQUE keyOrder.

 DESTRUCTOR PUBLIC DynamicQueryCursor(): secretValue="". END DESTRUCTOR.

 METHOD PUBLIC CHARACTER readKey(INPUT pathValue AS CHARACTER):
  DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
  IF pathValue=? OR pathValue="" THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNAVAILABLE",0).
  FILE-INFO:FILE-NAME=pathValue.
  IF FILE-INFO:FULL-PATHNAME=? OR FILE-INFO:FILE-SIZE<>64 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNAVAILABLE",0).
  COPY-LOB FROM FILE pathValue TO textValue.
  IF NOT THIS-OBJECT:isHex(STRING(textValue)) THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNAVAILABLE",0).
  RETURN STRING(textValue).
 END METHOD.

 METHOD PUBLIC VOID addOrder(INPUT sourceBuffer AS HANDLE, INPUT sourceTable AS CHARACTER,
  INPUT fieldNameValue AS CHARACTER, INPUT descendingFlag AS LOGICAL, INPUT uniqueFlag AS LOGICAL):
  DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
  FIND FIRST ttKey WHERE ttKey.bufferValue=sourceBuffer AND ttKey.fieldName=fieldNameValue NO-ERROR.
  IF AVAILABLE ttKey THEN DO: ttKey.uniqueValue=ttKey.uniqueValue OR uniqueFlag. RETURN. END.
  IF keyCount>=32 OR NOT THIS-OBJECT:isName(sourceTable) OR NOT THIS-OBJECT:isName(fieldNameValue) THEN
   UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
  fieldHandle=sourceBuffer:BUFFER-FIELD(fieldNameValue) NO-ERROR.
  IF NOT VALID-HANDLE(fieldHandle) THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
  IF fieldHandle:EXTENT<>0 OR LOOKUP(fieldHandle:DATA-TYPE,"CHARACTER,INTEGER,INT64,DECIMAL,DATE,LOGICAL")=0 THEN
   UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
  keyCount=keyCount + 1. CREATE ttKey.
  ASSIGN ttKey.keyOrder=keyCount ttKey.tableName=sourceTable ttKey.fieldName=fieldNameValue
   ttKey.bufferValue=sourceBuffer ttKey.fieldValue=fieldHandle ttKey.typeValue=fieldHandle:DATA-TYPE
   ttKey.descendingValue=descendingFlag ttKey.uniqueValue=uniqueFlag.
 END METHOD.

 METHOD PUBLIC VOID addSource(INPUT sourceBuffer AS HANDLE, INPUT sourceTable AS CHARACTER):
  DEFINE VARIABLE namesValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE infoValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE j AS INTEGER NO-UNDO.
  namesValue=sourceBuffer:KEYS.
  IF namesValue=? OR namesValue="" OR CAPS(namesValue)="ROWID" THEN DO:
   namesValue="".
   DO n=1 TO 1024:
    infoValue=sourceBuffer:INDEX-INFORMATION(n).
    IF infoValue=? THEN LEAVE.
    IF NUM-ENTRIES(infoValue)<6 THEN NEXT.
    IF ENTRY(2,infoValue)<>"1" OR ENTRY(4,infoValue)<>"0" THEN NEXT.
    DO j=5 TO NUM-ENTRIES(infoValue) BY 2:
     namesValue=namesValue + (IF namesValue="" THEN "" ELSE ",") + ENTRY(j,infoValue).
    END.
    LEAVE.
   END.
  END.
  IF namesValue=? OR namesValue="" OR CAPS(namesValue)="ROWID" THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
  schemaValue=schemaValue + "|" + sourceTable + ":" + STRING(sourceBuffer:CRC-VALUE) + ":" + namesValue.
  DO n=1 TO NUM-ENTRIES(namesValue):
   THIS-OBJECT:addOrder(sourceBuffer,sourceTable,ENTRY(n,namesValue),FALSE,TRUE).
  END.
 END METHOD.

 METHOD PUBLIC CHARACTER orderClause():
  DEFINE VARIABLE resultValue AS CHARACTER NO-UNDO.
  FOR EACH ttKey BY keyOrder:
   resultValue=resultValue + (IF resultValue="" THEN "" ELSE " BY ") + ttKey.tableName + "." + ttKey.fieldName + (IF ttKey.descendingValue THEN " DESCENDING" ELSE "").
  END.
  RETURN resultValue.
 END METHOD.

 METHOD PUBLIC VOID initialize(INPUT keyValue AS CHARACTER, INPUT contextValue AS LONGCHAR, INPUT epochValue AS INT64):
  IF keyCount=0 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
  secretValue=keyValue. nowValue=epochValue.
  bindingValue=LC(HEX-ENCODE(MESSAGE-DIGEST("SHA-256",contextValue + "|" + schemaValue + "|" + THIS-OBJECT:orderClause()))).
 END METHOD.

 METHOD PUBLIC CHARACTER mac(INPUT textValue AS CHARACTER, INPUT keyValue AS CHARACTER):
  RETURN STRING(LC(HEX-ENCODE(MESSAGE-DIGEST("HMAC-SHA-256",textValue,keyValue)))).
 END METHOD.

 METHOD PUBLIC JsonArray capture():
  DEFINE VARIABLE valuesValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE charValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE intValue AS INT64 NO-UNDO.
  DEFINE VARIABLE decimalValue AS DECIMAL NO-UNDO.
  DEFINE VARIABLE dateValue AS DATE NO-UNDO.
  DEFINE VARIABLE logicalValue AS LOGICAL NO-UNDO.
  valuesValue=NEW JsonArray().
  FOR EACH ttKey BY keyOrder:
   entryValue=NEW JsonObject().
   IF ttKey.fieldValue:BUFFER-VALUE=? THEN DO:
    IF ttKey.uniqueValue THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
    entryValue:AddNull("v").
   END.
   ELSE CASE ttKey.typeValue:
    WHEN "CHARACTER" THEN DO: charValue=ttKey.fieldValue:BUFFER-VALUE. entryValue:Add("v",charValue). END.
    WHEN "INTEGER" OR WHEN "INT64" THEN DO: intValue=ttKey.fieldValue:BUFFER-VALUE. entryValue:Add("v",intValue). END.
    WHEN "DECIMAL" THEN DO: decimalValue=ttKey.fieldValue:BUFFER-VALUE. entryValue:Add("v",decimalValue). END.
    WHEN "DATE" THEN DO: dateValue=ttKey.fieldValue:BUFFER-VALUE. entryValue:Add("v",INTEGER(dateValue)). END.
    WHEN "LOGICAL" THEN DO: logicalValue=ttKey.fieldValue:BUFFER-VALUE. entryValue:Add("v",logicalValue). END.
   END CASE.
   valuesValue:Add(entryValue).
  END.
  RETURN valuesValue.
 END METHOD.

 METHOD PUBLIC CHARACTER issue(INPUT valuesValue AS JsonArray):
  DEFINE VARIABLE payloadValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE bytesValue AS MEMPTR NO-UNDO.
  DEFINE VARIABLE encodedValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE resultValue AS CHARACTER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   payloadValue=NEW JsonObject(). payloadValue:Add("v",1). payloadValue:Add("binding",bindingValue).
   payloadValue:Add("expires",nowValue + 900). payloadValue:Add("keys",CAST(valuesValue:Clone(),JsonArray)).
   FIX-CODEPAGE(textValue)="UTF-8". payloadValue:Write(textValue,FALSE).
   COPY-LOB FROM textValue TO bytesValue NO-CONVERT.
   encodedValue=LC(HEX-ENCODE(bytesValue)).
   IF LENGTH(encodedValue)>16000 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
   resultValue="v1." + encodedValue + "." + THIS-OBJECT:mac(encodedValue,secretValue).
   IF LENGTH(resultValue)>16384 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
   RETURN resultValue.
   FINALLY: SET-SIZE(bytesValue)=0. IF VALID-OBJECT(payloadValue) THEN DELETE OBJECT payloadValue. END FINALLY.
  END.
 END METHOD.

 METHOD PUBLIC JsonArray resume(INPUT tokenValue AS CHARACTER):
  DEFINE VARIABLE encodedValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE signatureValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE rawValue AS RAW NO-UNDO.
  DEFINE VARIABLE bytesValue AS MEMPTR NO-UNDO.
  DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
  DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
  DEFINE VARIABLE payloadValue AS JsonObject NO-UNDO.
  DEFINE VARIABLE keysValue AS JsonArray NO-UNDO.
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DO ON ERROR UNDO, THROW:
   IF tokenValue="" THEN RETURN ?.
   IF tokenValue=? OR LENGTH(tokenValue)>16384 OR NUM-ENTRIES(tokenValue,".")<>3 THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   IF NOT COMPARE(ENTRY(1,tokenValue,"."),"EQ","v1","RAW") THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   encodedValue=ENTRY(2,tokenValue,"."). signatureValue=ENTRY(3,tokenValue,".").
   IF LENGTH(encodedValue)>16000 OR LENGTH(encodedValue) MODULO 2<>0 OR NOT THIS-OBJECT:isHex(encodedValue) OR LENGTH(signatureValue)<>64 OR NOT THIS-OBJECT:isHex(signatureValue) THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   IF NOT THIS-OBJECT:sameDigest(signatureValue,THIS-OBJECT:mac(encodedValue,secretValue)) THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   rawValue=HEX-DECODE(encodedValue). SET-SIZE(bytesValue)=LENGTH(rawValue,"RAW").
   DO n=1 TO LENGTH(rawValue,"RAW"): PUT-BYTE(bytesValue,n)=GET-BYTE(rawValue,n). END.
   FIX-CODEPAGE(textValue)="UTF-8". COPY-LOB FROM bytesValue TO textValue NO-CONVERT.
   parserValue=NEW ObjectModelParser(). payloadValue=CAST(parserValue:Parse(textValue),JsonObject).
   IF payloadValue:GetInteger("v")<>1 OR NOT THIS-OBJECT:sameDigest(payloadValue:GetCharacter("binding"),bindingValue) THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   IF payloadValue:GetInt64("expires")<=nowValue THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_EXPIRED",0).
   keysValue=payloadValue:GetJsonArray("keys").
   IF keysValue:Length<>keyCount THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   /* Validate all typed values before producing any predicate text. */
   FOR EACH ttKey: encodedValue=THIS-OBJECT:literal(keysValue:GetJsonObject(ttKey.keyOrder),ttKey.typeValue,ttKey.uniqueValue). END.
   RETURN CAST(keysValue:Clone(),JsonArray).
   FINALLY:
    SET-SIZE(bytesValue)=0.
    IF VALID-OBJECT(payloadValue) THEN DELETE OBJECT payloadValue.
    IF VALID-OBJECT(parserValue) THEN DELETE OBJECT parserValue.
   END FINALLY.
  END.
 END METHOD.

 METHOD PUBLIC CHARACTER predicate(INPUT keysValue AS JsonArray):
  DEFINE VARIABLE resultValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE prefixValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE fieldText AS CHARACTER NO-UNDO.
  DEFINE VARIABLE literalValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE greaterValue AS CHARACTER NO-UNDO.
  DEFINE VARIABLE entryValue AS JsonObject NO-UNDO.
  IF NOT VALID-OBJECT(keysValue) THEN RETURN "".
  FOR EACH ttKey BY keyOrder:
   entryValue=keysValue:GetJsonObject(ttKey.keyOrder).
   fieldText=ttKey.tableName + "." + ttKey.fieldName.
   literalValue=THIS-OBJECT:literal(entryValue,ttKey.typeValue,ttKey.uniqueValue).
   IF entryValue:IsNull("v") THEN greaterValue=IF ttKey.descendingValue THEN fieldText + " <> ?" ELSE "FALSE".
   ELSE IF ttKey.descendingValue THEN greaterValue=fieldText + " < " + literalValue.
   ELSE greaterValue="(" + fieldText + " > " + literalValue + " OR " + fieldText + " = ?)".
   resultValue=resultValue + (IF resultValue="" THEN "" ELSE " OR ") + "(" + prefixValue + greaterValue + ")".
   prefixValue=prefixValue + fieldText + " = " + literalValue + " AND ".
  END.
  RETURN "(" + resultValue + ")".
 END METHOD.

 METHOD PRIVATE CHARACTER literal(INPUT entryValue AS JsonObject, INPUT typeValue AS CHARACTER, INPUT uniqueFlag AS LOGICAL):
  DEFINE VARIABLE dateValue AS DATE NO-UNDO.
  DEFINE VARIABLE rawText AS LONGCHAR NO-UNDO.
  IF entryValue:IsNull("v") THEN DO:
   IF uniqueFlag THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
   RETURN "?".
  END.
  CASE typeValue:
   WHEN "CHARACTER" THEN RETURN QUOTER(entryValue:GetCharacter("v")).
   WHEN "INTEGER" OR WHEN "INT64" OR WHEN "DECIMAL" THEN DO:
    IF entryValue:GetType("v")<>JsonDataType:NUMBER THEN UNDO,THROW NEW Progress.Lang.AppError("CURSOR_INVALID",0).
    rawText=entryValue:GetJsonText("v"). RETURN STRING(rawText).
   END.
   WHEN "LOGICAL" THEN RETURN IF entryValue:GetLogical("v") THEN "TRUE" ELSE "FALSE".
   WHEN "DATE" THEN DO:
    dateValue=DATE(entryValue:GetInteger("v")).
    RETURN "DATE(" + STRING(MONTH(dateValue)) + "," + STRING(DAY(dateValue)) + "," + STRING(YEAR(dateValue)) + ")".
   END.
  END CASE.
  UNDO,THROW NEW Progress.Lang.AppError("CURSOR_UNSUPPORTED",0).
 END METHOD.

 METHOD PRIVATE LOGICAL sameDigest(INPUT a AS CHARACTER, INPUT b AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  DEFINE VARIABLE differences AS INTEGER NO-UNDO.
  IF a=? OR b=? OR LENGTH(a)<>64 OR LENGTH(b)<>64 THEN RETURN FALSE.
  DO n=1 TO 64: IF NOT COMPARE(SUBSTRING(a,n,1),"EQ",SUBSTRING(b,n,1),"RAW") THEN differences=differences + 1. END.
  RETURN differences=0.
 END METHOD.
 METHOD PRIVATE LOGICAL isHex(INPUT textValue AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF textValue=? OR textValue="" THEN RETURN FALSE.
  DO n=1 TO LENGTH(textValue): IF INDEX("0123456789abcdef",SUBSTRING(textValue,n,1))=0 THEN RETURN FALSE. END.
  RETURN TRUE.
 END METHOD.
 METHOD PRIVATE LOGICAL isName(INPUT textValue AS CHARACTER):
  DEFINE VARIABLE n AS INTEGER NO-UNDO.
  IF textValue=? OR textValue="" THEN RETURN FALSE.
  DO n=1 TO LENGTH(textValue): IF INDEX("abcdefghijklmnopqrstuvwxyz0123456789_-",LC(SUBSTRING(textValue,n,1)))=0 THEN RETURN FALSE. END.
  RETURN TRUE.
 END METHOD.
END CLASS.
