DEFINE VARIABLE hServer AS HANDLE NO-UNDO.
DEFINE VARIABLE lConnected AS LOGICAL NO-UNDO.
DEFINE VARIABLE iForEachCount AS INT64 NO-UNDO.
DEFINE VARIABLE iForEachMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iPreselectCount AS INTEGER NO-UNDO.
DEFINE VARIABLE iOpenQueryMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iNumResultsMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iTotalMs AS INTEGER NO-UNDO.
DEFINE VARIABLE cLog AS CHARACTER NO-UNDO INITIAL "D:\opencode\motor-progress\output\customer-count-methods-onserver-benchmark.log".

PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\workers,D:\opencode\motor-progress,":U + PROPATH.

CREATE SERVER hServer.
ASSIGN lConnected = hServer:CONNECT("-URL http://localhost:8890/apsv":U) NO-ERROR.

IF NOT lConnected THEN DO:
    OUTPUT TO VALUE(cLog).
    PUT UNFORMATTED
        "success=false" SKIP
        "error=Could not connect to PASOE APSV" SKIP
        "messages=" ERROR-STATUS:GET-MESSAGE(1) SKIP.
    OUTPUT CLOSE.
    DELETE OBJECT hServer NO-ERROR.
    RETURN.
END.

ETIME(TRUE).
RUN workers/BenchmarkCustomerCountOnServer.p ON SERVER hServer (
    OUTPUT iForEachCount,
    OUTPUT iForEachMs,
    OUTPUT iPreselectCount,
    OUTPUT iOpenQueryMs,
    OUTPUT iNumResultsMs
).
ASSIGN iTotalMs = ETIME.

hServer:DISCONNECT() NO-ERROR.
DELETE OBJECT hServer NO-ERROR.

OUTPUT TO VALUE(cLog).
PUT UNFORMATTED
    "success=true" SKIP
    "runtime=PASOE-APSV-ON-SERVER" SKIP
    "forEachCount=" iForEachCount SKIP
    "forEachElapsedMs=" iForEachMs SKIP
    "preselectCount=" iPreselectCount SKIP
    "openQueryElapsedMs=" iOpenQueryMs SKIP
    "numResultsElapsedMs=" iNumResultsMs SKIP
    "totalOnServerCallElapsedMs=" iTotalMs SKIP.
OUTPUT CLOSE.
