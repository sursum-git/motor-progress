/* Executar apenas em staging do compilador 12.2; nao publicar este runner. */
DEFINE VARIABLE cSource AS CHARACTER NO-UNDO.
DEFINE VARIABLE iSource AS INTEGER NO-UNDO.
DEFINE VARIABLE iMessage AS INTEGER NO-UNDO.
DEFINE VARIABLE lFailed AS LOGICAL NO-UNDO.
OUTPUT TO "compile-empresas.log".
DO iSource = 1 TO 3:
  cSource = ENTRY(iSource, "EmpresasCrudService.p,EmpresasCrud.p,RunEmpresasCrudTests.p").
  COMPILE VALUE(cSource) SAVE NO-ERROR.
  PUT UNFORMATTED cSource " COMPILER:ERROR=" COMPILER:ERROR SKIP.
  IF COMPILER:ERROR OR ERROR-STATUS:ERROR THEN lFailed = TRUE.
  DO iMessage = 1 TO ERROR-STATUS:NUM-MESSAGES:
    PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(iMessage) SKIP.
  END.
END.
PUT UNFORMATTED (IF lFailed THEN "FAIL: compilacao" ELSE "PASS: compilacao 12.2") SKIP.
OUTPUT CLOSE.
QUIT.
