USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE TEMP-TABLE ttCursor NO-UNDO
 FIELD id AS INTEGER FIELD labelValue AS CHARACTER FIELD dayValue AS DATE
 FIELD decimalValue AS DECIMAL FIELD logicalValue AS LOGICAL FIELD bigValue AS INT64
 INDEX id IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttJoinCursor NO-UNDO
 FIELD id AS INTEGER
 INDEX id IS PRIMARY UNIQUE id.
DEFINE TEMP-TABLE ttFallback NO-UNDO
 FIELD category AS INTEGER FIELD id AS INTEGER
 INDEX category IS PRIMARY category INDEX id IS UNIQUE id.
DEFINE VARIABLE helper AS DynamicQueryCursor NO-UNDO.
DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE bodyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesValue AS JsonArray NO-UNDO.
DEFINE VARIABLE restoredValue AS JsonArray NO-UNDO.
DEFINE VARIABLE textValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE tokenValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE hashValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE hQuery AS HANDLE NO-UNDO.
DEFINE VARIABLE expectedIds AS CHARACTER NO-UNDO.
DEFINE VARIABLE actualIds AS CHARACTER NO-UNDO.
DEFINE VARIABLE errorSeen AS LOGICAL NO-UNDO.
helper=NEW DynamicQueryCursor().
RUN Assert(helper:mac('The quick brown fox jumps over the lazy dog','key')='f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8','HMAC SHA256 reference vector').
DELETE OBJECT helper.
DO n=1 TO 8:
 CREATE ttCursor. ASSIGN ttCursor.id=n ttCursor.labelValue=IF n<=4 THEN 'mesmo' ELSE 'outro' ttCursor.dayValue=DATE(10,n,2026)
 ttCursor.decimalValue=n / 10 ttCursor.logicalValue=n MODULO 2=0 ttCursor.bigValue=2147483648 + INT64(n).
END.
FOR EACH ttCursor WHERE ttCursor.id=7: ttCursor.labelValue=?. END.
RUN Initialize('context',1000,FALSE).
FIND ttCursor WHERE id=2.
valuesValue=helper:capture(). tokenValue=helper:issue(valuesValue).
restoredValue=helper:resume(tokenValue).
RUN Assert(restoredValue:Length=2,'primary key completes equal sort').
/* A nested method without a routine-level THROW can swallow errors. The service
   handles resume in an explicit CATCH scope and preserves the classified error. */
RUN Assert(INDEX(helper:orderClause(),'ttCursor.id')>0,'unique key appended').
DELETE OBJECT restoredValue.
RUN ExpectError('v1.aa.' + FILL('0',64),'CURSOR_INVALID').
textValue=SUBSTRING(tokenValue,1,LENGTH(tokenValue) - 1) + (IF SUBSTRING(tokenValue,LENGTH(tokenValue),1)='a' THEN 'b' ELSE 'a').
RUN ExpectError(textValue,'CURSOR_INVALID').
DELETE OBJECT helper. RUN Initialize('changed-context',1000,FALSE). RUN ExpectError(tokenValue,'CURSOR_INVALID').
DELETE OBJECT helper. RUN Initialize('context',1900,FALSE). RUN ExpectError(tokenValue,'CURSOR_EXPIRED').
DELETE OBJECT helper. RUN Initialize('context',1899,FALSE).
restoredValue=helper:resume(tokenValue). RUN Assert(VALID-OBJECT(restoredValue),'cursor valid before expiry'). DELETE OBJECT restoredValue.
DELETE OBJECT valuesValue. DELETE OBJECT helper.
/* Numeric JSON literals remain independent of the AVM decimal separator. */
helper=NEW DynamicQueryCursor().
helper:addOrder(BUFFER ttCursor:HANDLE,'ttCursor','decimalValue',FALSE,FALSE).
helper:addOrder(BUFFER ttCursor:HANDLE,'ttCursor','logicalValue',FALSE,FALSE).
helper:addOrder(BUFFER ttCursor:HANDLE,'ttCursor','bigValue',FALSE,FALSE).
helper:addSource(BUFFER ttCursor:HANDLE,'ttCursor'). helper:initialize('key','typed',1000).
FIND ttCursor WHERE id=1.
valuesValue=helper:capture(). restoredValue=helper:resume(helper:issue(valuesValue)).
RUN Assert(INDEX(helper:predicate(restoredValue),'0.1')>0,'decimal literal uses dot').
RUN Assert(INDEX(helper:predicate(restoredValue),'FALSE')>0,'logical literal').
RUN Assert(INDEX(helper:predicate(restoredValue),'2147483649')>0,'int64 literal').
DELETE OBJECT restoredValue. DELETE OBJECT valuesValue. DELETE OBJECT helper.
/* Seek results must exactly match the ordered suffix, including nulls and equal sort values. */
DO n=1 TO 2:
 RUN Initialize('walk',1000,n=2).
 CREATE QUERY hQuery. hQuery:SET-BUFFERS(BUFFER ttCursor:HANDLE).
 hQuery:QUERY-PREPARE('FOR EACH ttCursor NO-LOCK BY ' + helper:orderClause()). hQuery:QUERY-OPEN().
 expectedIds=''.
 REPEAT:
  hQuery:GET-NEXT(). IF hQuery:QUERY-OFF-END THEN LEAVE.
  expectedIds=expectedIds + STRING(ttCursor.id) + ','.
 END.
 hQuery:QUERY-CLOSE().
 actualIds=''. restoredValue=?.
 REPEAT:
  hQuery:QUERY-PREPARE('FOR EACH ttCursor NO-LOCK' + (IF VALID-OBJECT(restoredValue) THEN ' WHERE ' + helper:predicate(restoredValue) ELSE '') + ' BY ' + helper:orderClause()). hQuery:QUERY-OPEN().
  hQuery:GET-NEXT(). IF hQuery:QUERY-OFF-END THEN LEAVE.
  actualIds=actualIds + STRING(ttCursor.id) + ','.
  IF VALID-OBJECT(valuesValue) THEN DELETE OBJECT valuesValue.
  valuesValue=helper:capture(). tokenValue=helper:issue(valuesValue).
  IF VALID-OBJECT(restoredValue) THEN DELETE OBJECT restoredValue.
  restoredValue=helper:resume(tokenValue).
  hQuery:QUERY-CLOSE().
 END.
 RUN Assert(actualIds=expectedIds,'seek suffix asc/desc/nulls').
 IF hQuery:IS-OPEN THEN hQuery:QUERY-CLOSE(). DELETE OBJECT hQuery.
 IF VALID-OBJECT(valuesValue) THEN DELETE OBJECT valuesValue.
 IF VALID-OBJECT(restoredValue) THEN DELETE OBJECT restoredValue.
 DELETE OBJECT helper.
END.
helper=NEW DynamicQueryCursor().
helper:addOrder(BUFFER ttCursor:HANDLE,'ttCursor','dayValue',TRUE,FALSE). helper:addSource(BUFFER ttCursor:HANDLE,'ttCursor').
helper:initialize('key','date',1000). FIND ttCursor WHERE id=1.
valuesValue=helper:capture(). restoredValue=helper:resume(helper:issue(valuesValue)).
RUN Assert(INDEX(helper:predicate(restoredValue),'DATE(10,1,2026)')>0,'date literal independent of locale').
DELETE OBJECT restoredValue. DELETE OBJECT valuesValue. DELETE OBJECT helper.
helper=NEW DynamicQueryCursor(). helper:addSource(BUFFER ttCursor:HANDLE,'ttCursor'). helper:addSource(BUFFER ttJoinCursor:HANDLE,'ttJoinCursor').
helper:initialize('key','join',1000). CREATE ttJoinCursor. ttJoinCursor.id=5.
valuesValue=helper:capture(). RUN Assert(valuesValue:Length=2,'each joined source contributes unique key').
DELETE OBJECT valuesValue. DELETE OBJECT helper.
CREATE ttJoinCursor. ttJoinCursor.id=6.
helper=NEW DynamicQueryCursor(). helper:addSource(BUFFER ttCursor:HANDLE,'ttCursor'). helper:addSource(BUFFER ttJoinCursor:HANDLE,'ttJoinCursor'). helper:initialize('key','join-walk',1000).
CREATE QUERY hQuery. hQuery:SET-BUFFERS(BUFFER ttCursor:HANDLE,BUFFER ttJoinCursor:HANDLE).
actualIds=''. restoredValue=?.
REPEAT:
 hQuery:QUERY-PREPARE('FOR EACH ttCursor NO-LOCK, EACH ttJoinCursor NO-LOCK' + (IF VALID-OBJECT(restoredValue) THEN ' WHERE ' + helper:predicate(restoredValue) ELSE '') + ' BY ' + helper:orderClause()). hQuery:QUERY-OPEN().
 hQuery:GET-NEXT(). IF hQuery:QUERY-OFF-END THEN LEAVE.
 actualIds=actualIds + STRING(ttCursor.id) + ':' + STRING(ttJoinCursor.id) + ','.
 IF VALID-OBJECT(valuesValue) THEN DELETE OBJECT valuesValue.
 valuesValue=helper:capture(). tokenValue=helper:issue(valuesValue).
 IF VALID-OBJECT(restoredValue) THEN DELETE OBJECT restoredValue.
 restoredValue=helper:resume(tokenValue). hQuery:QUERY-CLOSE().
END.
expectedIds=''. DO n=1 TO 8: expectedIds=expectedIds + STRING(n) + ':5,' + STRING(n) + ':6,'. END.
RUN Assert(actualIds=expectedIds,'joined tuple seek visits each pair once').
IF hQuery:IS-OPEN THEN hQuery:QUERY-CLOSE(). DELETE OBJECT hQuery.
DELETE OBJECT valuesValue. DELETE OBJECT restoredValue. DELETE OBJECT helper.
helper=NEW DynamicQueryCursor(). helper:addSource(BUFFER ttFallback:HANDLE,'ttFallback').
RUN Assert(INDEX(helper:orderClause(),'ttFallback.id')>0,'fallback finds a unique index'). DELETE OBJECT helper.
OUTPUT TO 'cursor-tests.log'. PUT UNFORMATTED 'PASS ' checks ' cursor checks; NUMDBS=' NUM-DBS SKIP. OUTPUT CLOSE.

PROCEDURE Initialize:
 DEFINE INPUT PARAMETER contextText AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER epochValue AS INT64 NO-UNDO.
 DEFINE INPUT PARAMETER descendingFlag AS LOGICAL NO-UNDO.
 helper=NEW DynamicQueryCursor(). helper:addOrder(BUFFER ttCursor:HANDLE,'ttCursor','labelValue',descendingFlag,FALSE).
 helper:addSource(BUFFER ttCursor:HANDLE,'ttCursor'). helper:initialize('key',contextText,epochValue).
END PROCEDURE.
PROCEDURE ExpectError:
 DEFINE INPUT PARAMETER cursorText AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expectedCode AS CHARACTER NO-UNDO.
 errorSeen=FALSE.
 DO ON ERROR UNDO, THROW:
  restoredValue=helper:resume(cursorText).
  CATCH err AS Progress.Lang.Error: errorSeen=err:GetMessage(1)=expectedCode. END CATCH.
 END.
 RUN Assert(errorSeen,expectedCode).
END PROCEDURE.
PROCEDURE Assert:
 DEFINE INPUT PARAMETER conditionValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelText AS CHARACTER NO-UNDO.
 IF conditionValue<>TRUE THEN UNDO,THROW NEW Progress.Lang.AppError('FAIL cursor ' + labelText,0).
 checks=checks + 1.
END PROCEDURE.
