FUNCTION getChar RETURNS CHARACTER (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER, INPUT pcDefault AS CHARACTER):
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.

    IF NOT VALID-OBJECT(poObj) OR NOT poObj:Has(pcName) OR poObj:IsNull(pcName) THEN
        RETURN pcDefault.

    ASSIGN cRet = poObj:GetCharacter(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR OR cRet = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN pcDefault.
    END.

    RETURN cRet.
END FUNCTION.

FUNCTION getInt RETURNS INTEGER (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER, INPUT piDefault AS INTEGER):
    DEFINE VARIABLE iRet AS INTEGER NO-UNDO.

    IF NOT VALID-OBJECT(poObj) OR NOT poObj:Has(pcName) OR poObj:IsNull(pcName) THEN
        RETURN piDefault.

    ASSIGN iRet = poObj:GetInteger(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        ASSIGN iRet = INTEGER(getChar(poObj, pcName, STRING(piDefault))) NO-ERROR.
    END.
    IF ERROR-STATUS:ERROR THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN piDefault.
    END.

    RETURN iRet.
END FUNCTION.

FUNCTION getInt64 RETURNS INT64 (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER, INPUT piDefault AS INT64):
    DEFINE VARIABLE iRet AS INT64 NO-UNDO.

    IF NOT VALID-OBJECT(poObj) OR NOT poObj:Has(pcName) OR poObj:IsNull(pcName) THEN
        RETURN piDefault.

    ASSIGN iRet = INT64(getChar(poObj, pcName, STRING(piDefault))) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN piDefault.
    END.

    RETURN iRet.
END FUNCTION.

FUNCTION getDec RETURNS DECIMAL (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER, INPUT pdDefault AS DECIMAL):
    DEFINE VARIABLE dRet AS DECIMAL NO-UNDO.

    IF NOT VALID-OBJECT(poObj) OR NOT poObj:Has(pcName) OR poObj:IsNull(pcName) THEN
        RETURN pdDefault.

    ASSIGN dRet = poObj:GetDecimal(pcName) NO-ERROR.
    IF NOT ERROR-STATUS:ERROR AND dRet <> ? THEN
        RETURN dRet.

    ERROR-STATUS:ERROR = FALSE.
    ASSIGN dRet = decimalJson(getChar(poObj, pcName, STRING(pdDefault))) NO-ERROR.
    IF ERROR-STATUS:ERROR OR dRet = ? THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN pdDefault.
    END.

    RETURN dRet.
END FUNCTION.

FUNCTION getLog RETURNS LOGICAL (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER, INPUT plDefault AS LOGICAL):
    DEFINE VARIABLE lRet AS LOGICAL NO-UNDO.

    IF NOT VALID-OBJECT(poObj) OR NOT poObj:Has(pcName) OR poObj:IsNull(pcName) THEN
        RETURN plDefault.

    ASSIGN lRet = poObj:GetLogical(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ERROR-STATUS:ERROR = FALSE.
        RETURN plDefault.
    END.

    RETURN lRet.
END FUNCTION.

FUNCTION getObject RETURNS JsonObject (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER):
    DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

    IF VALID-OBJECT(poObj) AND poObj:Has(pcName) AND NOT poObj:IsNull(pcName) THEN
        ASSIGN joRet = poObj:GetJsonObject(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN
        ERROR-STATUS:ERROR = FALSE.

    RETURN joRet.
END FUNCTION.

FUNCTION getArray RETURNS JsonArray (INPUT poObj AS JsonObject, INPUT pcName AS CHARACTER):
    DEFINE VARIABLE jaRet AS JsonArray NO-UNDO.

    IF VALID-OBJECT(poObj) AND poObj:Has(pcName) AND NOT poObj:IsNull(pcName) THEN
        ASSIGN jaRet = poObj:GetJsonArray(pcName) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN
        ERROR-STATUS:ERROR = FALSE.

    RETURN jaRet.
END FUNCTION.

FUNCTION listFromArray RETURNS CHARACTER (INPUT poArray AS JsonArray):
    DEFINE VARIABLE cRet AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iItem AS INTEGER NO-UNDO.

    IF NOT VALID-OBJECT(poArray) THEN
        RETURN "".

    DO iItem = 1 TO poArray:Length:
        IF cRet <> "" THEN
            ASSIGN cRet = cRet + ",".
        ASSIGN cRet = cRet + poArray:GetCharacter(iItem) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            ERROR-STATUS:ERROR = FALSE.
    END.

    RETURN cRet.
END FUNCTION.
