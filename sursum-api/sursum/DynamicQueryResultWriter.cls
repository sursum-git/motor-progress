/*
Grava o resultado JSON de um job assincrono em arquivo.
*/

USING Progress.Json.ObjectModel.JsonObject.

CLASS DynamicQueryResultWriter:

    METHOD PUBLIC CHARACTER writeResult(
        INPUT pcJobId AS CHARACTER,
        INPUT poResult AS JsonObject,
        INPUT pcBaseDir AS CHARACTER):

        DEFINE VARIABLE cBaseDir AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cDayDir  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTmpFile AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lOk      AS LOGICAL NO-UNDO.

        ASSIGN cBaseDir = IF TRIM(pcBaseDir) = "" THEN THIS-OBJECT:resolveDirectory("output/jobs") ELSE pcBaseDir
               cDayDir  = cBaseDir + "\" + STRING(YEAR(TODAY), "9999") + STRING(MONTH(TODAY), "99") + STRING(DAY(TODAY), "99")
               cFile    = cDayDir + "\" + pcJobId + ".json"
               cTmpFile = cFile + ".tmp".

        OS-CREATE-DIR VALUE(THIS-OBJECT:resolveDirectory("output")) NO-ERROR.
        OS-CREATE-DIR VALUE(cBaseDir) NO-ERROR.
        OS-CREATE-DIR VALUE(cDayDir) NO-ERROR.

        ASSIGN lOk = poResult:WriteFile(cTmpFile, TRUE) NO-ERROR.
        IF ERROR-STATUS:ERROR OR NOT lOk THEN
            RETURN "".

        OS-DELETE VALUE(cFile) NO-ERROR.
        OS-RENAME VALUE(cTmpFile) VALUE(cFile).
        IF OS-ERROR <> 0 THEN
            RETURN "".

        RETURN cFile.
    END METHOD.

    METHOD PRIVATE CHARACTER resolveDirectory(INPUT pcRelative AS CHARACTER):
        DEFINE VARIABLE cRelative AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFound AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iSlash AS INTEGER NO-UNDO.

        ASSIGN cRelative = TRIM(REPLACE(pcRelative, "~\", "/"))
               cFound = SEARCH(cRelative + "/.keep").
        IF cFound <> ? AND cFound <> "" THEN DO:
            ASSIGN cPath = REPLACE(cFound, "/", "~\")
                   iSlash = R-INDEX(cPath, "~\").
            IF iSlash > 0 THEN
                RETURN SUBSTRING(cPath, 1, iSlash - 1).
        END.

        ASSIGN cFound = SEARCH(cRelative).
        IF cFound <> ? AND cFound <> "" THEN
            RETURN REPLACE(cFound, "/", "~\").

        RETURN REPLACE(cRelative, "/", "~\").
    END METHOD.

END CLASS.
