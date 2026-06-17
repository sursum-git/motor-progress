
DEFINE VARIABLE cCampos{1} AS CHARACTER   NO-UNDO.

OUTPUT TO value('c:\temp\{1}_' + string(RANDOM(1,999999)) + '_.csv') .

RUN getCpsTT(TEMP-TABLE {1}:HANDLE,";", OUTPUT cCampos{1}).
PUT UNFORM cCampos{1} SKIP.
FOR EACH {1} {2} NO-LOCK:
    EXPORT DELIMITER ";" {1} {3}.
END.

OUTPUT CLOSE.
