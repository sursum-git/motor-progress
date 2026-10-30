DEFINE VARIABLE f AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
OUTPUT TO "compile-iol.log".
PUT UNFORMATTED "OpenEdge " PROVERSION SKIP.
DO i=1 TO NUM-ENTRIES("IolGerencialCalculator.p,IolGerencialCalculatorTest.p,IolGerencialIdentityTest.p,IolGerencialIdentityService.p,IolGerencialCollector.p,IolInicialGerencialBoundaryTest.p,IolInicialGerencial.p,IolGerencialEnginePolicy.p,IolGerencialEnginePolicyTest.p,InstallIolEngineParameter.p"):
 f=ENTRY(i,"IolGerencialCalculator.p,IolGerencialCalculatorTest.p,IolGerencialIdentityTest.p,IolGerencialIdentityService.p,IolGerencialCollector.p,IolInicialGerencialBoundaryTest.p,IolInicialGerencial.p,IolGerencialEnginePolicy.p,IolGerencialEnginePolicyTest.p,InstallIolEngineParameter.p").
 IF SEARCH(f)=? THEN DO: PUT UNFORMATTED "MISSING " f SKIP. failed=TRUE. NEXT. END.
 COMPILE VALUE(f) SAVE NO-ERROR.
 PUT UNFORMATTED f " COMPILER:ERROR=" COMPILER:ERROR SKIP.
 IF COMPILER:ERROR OR ERROR-STATUS:ERROR THEN failed=TRUE.
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(j) SKIP. END.
END.
OUTPUT CLOSE.
IF NOT failed THEN DO i=1 TO 2:
 SESSION:NUMERIC-FORMAT=ENTRY(i,"AMERICAN,EUROPEAN").
 RUN IolGerencialCalculatorTest.p NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN IolGerencialIdentityTest.p NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN IolInicialGerencialBoundaryTest.p NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN IolGerencialEnginePolicyTest.p NO-ERROR.
 OUTPUT TO "compile-iol.log" APPEND.
 IF ERROR-STATUS:ERROR THEN DO:
  failed=TRUE.
  DO j=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(j) SKIP. END.
 END.
 OUTPUT CLOSE.
END.
OUTPUT TO "compile-iol.log" APPEND.
PUT UNFORMATTED (IF failed THEN "FAIL IOL" ELSE "PASS IOL") SKIP.
OUTPUT CLOSE.
QUIT.
