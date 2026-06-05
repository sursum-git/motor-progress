DEFINE VARIABLE iCount AS INT64 NO-UNDO.
DEFINE VARIABLE iForEachMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iOpenMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iNumResultsMs AS INTEGER NO-UNDO.
DEFINE VARIABLE iNumResults AS INTEGER NO-UNDO.
DEFINE VARIABLE cLog AS CHARACTER NO-UNDO INITIAL "D:\opencode\motor-progress\output\customer-count-methods-benchmark.log".

DEFINE QUERY qCustomer FOR Customer
    FIELDS(CustNum)
    SCROLLING.

ETIME(TRUE).
FOR EACH Customer NO-LOCK:
    ASSIGN iCount = iCount + 1.
END.
ASSIGN iForEachMs = ETIME.

ETIME(TRUE).
OPEN QUERY qCustomer PRESELECT EACH Customer NO-LOCK.
ASSIGN iOpenMs = ETIME.

ETIME(TRUE).
ASSIGN iNumResults = NUM-RESULTS("qCustomer").
ASSIGN iNumResultsMs = ETIME.

CLOSE QUERY qCustomer.

OUTPUT TO VALUE(cLog).
PUT UNFORMATTED
    "method=for_each_no_lock" SKIP
    "count=" iCount SKIP
    "elapsedMs=" iForEachMs SKIP(1)
    "method=preselect_num_results" SKIP
    "openQueryElapsedMs=" iOpenMs SKIP
    "numResults=" iNumResults SKIP
    "numResultsElapsedMs=" iNumResultsMs SKIP.
OUTPUT CLOSE.
