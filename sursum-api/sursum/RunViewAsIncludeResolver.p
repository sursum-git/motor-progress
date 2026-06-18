DEFINE VARIABLE cParam AS CHARACTER NO-UNDO.
DEFINE VARIABLE cInputFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOutputFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAliasFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLine AS CHARACTER NO-UNDO.
DEFINE VARIABLE cInclude AS CHARACTER NO-UNDO.
DEFINE VARIABLE cReturn AS CHARACTER NO-UNDO.
DEFINE VARIABLE cError AS CHARACTER NO-UNDO.

PROPATH = "C:\opencode\motor-progress\sursum-api\sursum,C:\opencode\motor-progress\sursum-api\rest,C:\opencode\motor-progress\sursum-api\workers,C:\opencode\motor-progress\sursum-api\runners,C:\opencode\motor-progress\sursum-api\sursum\esp,C:\opencode\motor-progress\ems2,C:\opencode\motor-progress,C:\Progress_12\OE\tty\netlib\OpenEdge.Net.pl," + PROPATH.

ASSIGN cParam = SESSION:PARAMETER
       cInputFile = ENTRY(1, cParam, "|")
       cOutputFile = ENTRY(2, cParam, "|")
       cAliasFile = IF NUM-ENTRIES(cParam, "|") >= 3 THEN ENTRY(3, cParam, "|") ELSE "" NO-ERROR.

IF cInputFile = "" OR cInputFile = ? OR cOutputFile = "" OR cOutputFile = ? THEN
    RETURN "Parametros invalidos.".

IF cAliasFile <> "" AND cAliasFile <> ? THEN
    RUN VALUE(cAliasFile) NO-ERROR.

INPUT FROM VALUE(cInputFile).
OUTPUT TO VALUE(cOutputFile).

REPEAT:
    IMPORT UNFORMATTED cLine.
    ASSIGN cInclude = TRIM(cLine)
           cReturn = ""
           cError = "".

    IF cInclude = "" THEN
        NEXT.

    RUN esp/include_dinamica.i cInclude NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        IF ERROR-STATUS:NUM-MESSAGES > 0 THEN
            ASSIGN cError = ERROR-STATUS:GET-MESSAGE(1).
        ELSE
            ASSIGN cError = "Erro ao resolver include.".
    END.
    ELSE
        ASSIGN cReturn = IF RETURN-VALUE = ? THEN "" ELSE RETURN-VALUE.

    PUT UNFORMATTED cInclude CHR(1) cError CHR(1) cReturn SKIP.
END.

INPUT CLOSE.
OUTPUT CLOSE.

RETURN "".
