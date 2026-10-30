DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE fileName AS CHARACTER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
DEFINE VARIABLE cDlc AS CHARACTER NO-UNDO.
cDlc=OS-GETENV("DLC").
IF cDlc=? OR cDlc="" THEN cDlc="C:/Progress/OpenEdge".
PROPATH = ".,dependencies," + cDlc + "/gui/netlib/OpenEdge.Net.pl," + PROPATH.
OUTPUT TO "compile-program-log.log".
PUT UNFORMATTED "OpenEdge " PROVERSION SKIP.
DO j=1 TO 5:
 fileName=ENTRY(j,"PasoeExecutionContext.cls,ApiExecutionRepository.cls,ProgramLogTest.p,JsonProgramWebHandler.cls,ProgramLogProbe.p").
 COMPILE VALUE(fileName) SAVE NO-ERROR.
 failed=COMPILER:ERROR.
 PUT UNFORMATTED fileName " COMPILER:ERROR=" failed SKIP.
 DO i=1 TO ERROR-STATUS:NUM-MESSAGES: PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(i) SKIP. END.
 IF failed THEN LEAVE.
END.
IF NOT failed THEN PUT UNFORMATTED "PASS: compile program log" SKIP.
OUTPUT CLOSE.
IF NOT failed THEN RUN ProgramLogTest.p.
QUIT.


