DEFINE VARIABLE files AS CHARACTER NO-UNDO.
DEFINE VARIABLE filename AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
files="CiwAuthenticationService.p,CiwAuthenticationServiceTest.p,CiwAuthenticationBoundary.cls,CiwAuthenticationBoundaryTest.p,CiwAuthenticationWebHandler.cls,RunCiwAuthenticationTests.p".
PROPATH = "." + ",C:/Progress_12/OE/tty/netlib/OpenEdge.Net.pl," + PROPATH.
OUTPUT TO "ciw-auth-compile.log".
PUT UNFORMATTED "OpenEdge " PROVERSION SKIP.
DO j=1 TO NUM-ENTRIES(files):
 filename=ENTRY(j,files).
 IF SEARCH(filename)=? THEN DO:
  PUT UNFORMATTED filename " MISSING" SKIP.
  IF j<>1 THEN failed=TRUE.
  NEXT.
 END.
 COMPILE VALUE(filename) SAVE NO-ERROR.
 PUT UNFORMATTED filename " COMPILER:ERROR=" COMPILER:ERROR SKIP.
 IF COMPILER:ERROR THEN failed=TRUE.
 DO i=1 TO ERROR-STATUS:NUM-MESSAGES:
  PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(i) SKIP.
 END.
END.
OUTPUT CLOSE.
IF NOT failed THEN RUN RunCiwAuthenticationTests.p.
QUIT.
