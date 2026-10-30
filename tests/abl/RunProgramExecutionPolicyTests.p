/* Run with _progres -b -p tests/abl/RunProgramExecutionPolicyTests.p.
   The working directory must be the repository root. No database is required. */
DEFINE VARIABLE i AS INTEGER NO-UNDO.
OS-CREATE-DIR "temp" NO-ERROR.
PROPATH = "sursum-api/sursum," + PROPATH.
OUTPUT TO "temp/compile-policy.txt".
COMPILE "tests/abl/ProgramExecutionPolicyTest.p" SAVE NO-ERROR.
DO i = 1 TO ERROR-STATUS:NUM-MESSAGES:
    PUT UNFORMATTED ERROR-STATUS:GET-MESSAGE(i) SKIP.
END.
IF COMPILER:ERROR THEN DO:
    PUT UNFORMATTED "COMPILE FAILED" SKIP.
    OUTPUT CLOSE.
    QUIT.
END.
OUTPUT CLOSE.
RUN tests/abl/ProgramExecutionPolicyTest.p.
