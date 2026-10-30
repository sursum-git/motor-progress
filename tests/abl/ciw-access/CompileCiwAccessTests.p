DEFINE VARIABLE fileName AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
OUTPUT TO "compile-ciw-access.log".
PUT UNFORMATTED "OpenEdge " PROVERSION SKIP.
DO j=1 TO 11:
    fileName=ENTRY(j,"CiwAccessService.p,CiwAccessServiceTest.p,RunCiwAccessTests.p,CiwAccessBoundaryTest.p,CiwAccessBoundary.p,CiwAccessRead.p,CiwIdentityService.p,CiwIdentityBoundary.p,CiwIdentityRead.p,CiwIdentityServiceTest.p,CiwIdentityBoundaryTest.p").
    IF SEARCH(fileName)=? THEN DO:
        PUT UNFORMATTED fileName " MISSING" SKIP.
        IF j<>1 AND j<>5 AND j<>6 THEN failed=TRUE.
        NEXT.
    END.
    COMPILE VALUE(fileName) SAVE NO-ERROR.
    PUT UNFORMATTED fileName " COMPILER:ERROR=" COMPILER:ERROR SKIP.
    IF COMPILER:ERROR THEN failed=TRUE.
    DO i=1 TO ERROR-STATUS:NUM-MESSAGES:
        PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(i) SKIP.
    END.
END.
OUTPUT CLOSE.
IF NOT failed THEN RUN RunCiwAccessTests.p.
QUIT.
