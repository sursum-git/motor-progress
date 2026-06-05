DEFINE VARIABLE iCount AS INT64 NO-UNDO.
DEFINE VARIABLE iMillis AS INTEGER NO-UNDO.
DEFINE VARIABLE cLog AS CHARACTER NO-UNDO INITIAL "D:\opencode\motor-progress\output\customer-count-benchmark.log".

ETIME(TRUE).

FOR EACH Customer NO-LOCK:
    ASSIGN iCount = iCount + 1.
END.

ASSIGN iMillis = ETIME.

OUTPUT TO VALUE(cLog).
PUT UNFORMATTED
    "count=" iCount SKIP
    "elapsedMs=" iMillis SKIP.
OUTPUT CLOSE.
