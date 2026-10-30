BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE tests AS JsonArray NO-UNDO.
DEFINE VARIABLE testcase AS JsonObject NO-UNDO.
DEFINE VARIABLE expected AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE row AS JsonObject NO-UNDO.
DEFINE VARIABLE aFieldNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
parser = NEW ObjectModelParser().
tests = CAST(parser:ParseFile("calculator-cases.json"),JsonArray).
DO i=1 TO tests:Length:
 testcase=tests:GetJsonObject(i).
 RUN IolGerencialCalculator.p(testcase:GetJsonObject("snapshot"),OUTPUT result) NO-ERROR.
 IF testcase:Has("error") THEN DO:
  IF NOT ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL expected invalid snapshot",1).
  checks=checks + 1.
  NEXT.
 END.
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError(ERROR-STATUS:GET-MESSAGE(1),1).
 row=result:GetJsonArray("resumo"):GetJsonObject(1).
 expected=testcase:GetJsonObject("expected").
 EXTENT(aFieldNames)=?.
 aFieldNames=expected:GetNames().
 DO j=1 TO EXTENT(aFieldNames):
  IF row:GetDecimal(aFieldNames[j])<>expected:GetDecimal(aFieldNames[j]) THEN
   UNDO, THROW NEW Progress.Lang.AppError("FAIL " + aFieldNames[j] + " case " + STRING(i),1).
  checks=checks + 1.
 END.
 IF testcase:Has("seller_percent") THEN DO:
  row=result:GetJsonArray("vendedores"):GetJsonObject(1).
  IF row:GetDecimal("percentual_vendido")<>testcase:GetDecimal("seller_percent") THEN
   UNDO, THROW NEW Progress.Lang.AppError("FAIL seller percent",1).
  checks=checks + 1.
 END.
 DELETE OBJECT result.
END.
OUTPUT TO VALUE("calculator-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS calculator checks=" checks SKIP.
OUTPUT CLOSE.
DELETE OBJECT tests.
DELETE OBJECT parser.
