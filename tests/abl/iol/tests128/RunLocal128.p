BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE f AS CHARACTER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
IF NUM-DBS<>1 OR INDEX(PDBNAME(1),"aggregate-fixture")=0 THEN RETURN ERROR "FIXTURE_DATABASE_REQUIRED".
CREATE ALIAS ems2cad FOR DATABASE espec.
CREATE ALIAS ems2med FOR DATABASE espec.
CREATE ALIAS ems5 FOR DATABASE espec.
OUTPUT TO "local128-build.log".
PUT UNFORMATTED "OpenEdge " PROVERSION " local fixture only; not PASOE" SKIP.
DO i=1 TO NUM-ENTRIES("IolGerencialAggregate128.p,IolGerencialEnginePolicy.p,IolGerencialEnginePolicyTest.p,IolGerencialIdentityService.p,IolGerencialCollector.p,IolGerencialCalculator.p,IolInicialGerencial.p,InstallIolEngineParameter.p,IolGerencialIdentityTest.p,IolGerencialCalculatorTest.p,IolInicialGerencialBoundaryTest.p,Aggregate128Test.p,Collector128ParityTest.p,InstallParameterTest.p,CompileIolGerencial128.p"):
 f=ENTRY(i,"IolGerencialAggregate128.p,IolGerencialEnginePolicy.p,IolGerencialEnginePolicyTest.p,IolGerencialIdentityService.p,IolGerencialCollector.p,IolGerencialCalculator.p,IolInicialGerencial.p,InstallIolEngineParameter.p,IolGerencialIdentityTest.p,IolGerencialCalculatorTest.p,IolInicialGerencialBoundaryTest.p,Aggregate128Test.p,Collector128ParityTest.p,InstallParameterTest.p,CompileIolGerencial128.p").
 COMPILE VALUE(f) SAVE NO-ERROR.
 IF COMPILER:ERROR OR ERROR-STATUS:ERROR THEN failed=TRUE.
 PUT UNFORMATTED f " error=" COMPILER:ERROR SKIP.
 DO j=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(j) SKIP. END.
END.
IF NOT failed THEN RUN CompileIolGerencial128.r NO-ERROR.
IF ERROR-STATUS:ERROR THEN failed=TRUE.
IF NOT failed THEN DO i=1 TO 2:
 SESSION:NUMERIC-FORMAT=ENTRY(i,"AMERICAN,EUROPEAN").
 RUN IolGerencialEnginePolicyTest.r NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN IolGerencialIdentityTest.r NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN IolGerencialCalculatorTest.r NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN IolInicialGerencialBoundaryTest.r NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN Aggregate128Test.r NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN Collector128ParityTest.r NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN RUN InstallParameterTest.r NO-ERROR.
 IF ERROR-STATUS:ERROR THEN DO:
  failed=TRUE.
  DO j=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(j) SKIP. END.
 END.
END.
PUT UNFORMATTED (IF failed THEN "FAIL LOCAL128" ELSE "PASS LOCAL128") SKIP.
OUTPUT CLOSE.
QUIT.
