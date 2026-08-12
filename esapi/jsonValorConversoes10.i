FUNCTION decimalJson RETURNS DECIMAL (INPUT pcValor AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.

    ASSIGN cValor = pcValor.

    IF cValor = ? OR cValor = "" THEN
        RETURN ?.

    IF SESSION:NUMERIC-FORMAT = "EUROPEAN"
       AND INDEX(cValor, ".") > 0
       AND INDEX(cValor, ",") = 0 THEN
        ASSIGN cValor = REPLACE(cValor, ".", ",").

    RETURN DECIMAL(cValor).
END FUNCTION.

FUNCTION intFromChar RETURNS INTEGER (INPUT pcValor AS CHARACTER, INPUT piDefault AS INTEGER):
    DEFINE VARIABLE iRet AS INTEGER NO-UNDO.

    IF pcValor = ? OR TRIM(pcValor) = "" OR LC(TRIM(pcValor)) = "null" THEN
        RETURN piDefault.

    ASSIGN iRet = INTEGER(pcValor) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN piDefault.
    END.

    RETURN iRet.
END FUNCTION.

FUNCTION logFromChar RETURNS LOGICAL (INPUT pcValor AS CHARACTER, INPUT plDefault AS LOGICAL):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.

    ASSIGN cValor = LC(TRIM(pcValor)).

    IF cValor = ? OR cValor = "" OR cValor = "null" THEN
        RETURN plDefault.
    IF LOOKUP(cValor, "true,yes,sim,s,1") > 0 THEN
        RETURN TRUE.
    IF LOOKUP(cValor, "false,no,nao,n,0") > 0 THEN
        RETURN FALSE.

    RETURN plDefault.
END FUNCTION.

FUNCTION decFromChar RETURNS DECIMAL (INPUT pcValor AS CHARACTER, INPUT pdDefault AS DECIMAL):
    DEFINE VARIABLE dRet AS DECIMAL NO-UNDO.

    IF pcValor = ? OR TRIM(pcValor) = "" OR LC(TRIM(pcValor)) = "null" THEN
        RETURN pdDefault.

    ASSIGN dRet = decimalJson(pcValor) NO-ERROR.
    IF ERROR-STATUS:ERROR OR dRet = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN pdDefault.
    END.

    RETURN dRet.
END FUNCTION.
