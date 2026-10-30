/* Identidade do runtime: somente dados do servidor, sem entrada HTTP. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
CLASS PasoeRuntimeIdentity:
    METHOD PUBLIC STATIC CHARACTER InstanceName(INPUT pcBase AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        IF pcBase = ? OR TRIM(pcBase) = "" THEN RETURN "".
        cPath = TRIM(REPLACE(TRIM(pcBase), CHR(92), "/"), "/").
        IF cPath = "" THEN RETURN "".
        RETURN ENTRY(NUM-ENTRIES(cPath, "/"), cPath, "/").
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER AgentName(INPUT pcParams AS CHARACTER):
        DEFINE VARIABLE cPart AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DEFINE VARIABLE iId AS INTEGER NO-UNDO.
        IF pcParams = ? OR pcParams = "" THEN RETURN "".
        DO i = 1 TO NUM-ENTRIES(pcParams):
            cPart = TRIM(REPLACE(ENTRY(i, pcParams), CHR(9), " ")).
            IF ENTRY(1, cPart, " ") <> "-ASID" THEN NEXT.
            cId = TRIM(SUBSTRING(cPart, 6)).
            IF cId = "" OR LENGTH(cId) > 10 THEN RETURN "".
            DO j = 1 TO LENGTH(cId):
                IF INDEX("0123456789", SUBSTRING(cId, j, 1)) = 0 THEN RETURN "".
            END.
            iId = INTEGER(cId) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN RETURN "".
            RETURN "agent-" + TRIM(STRING(iId)).
        END.
        RETURN "".
    END METHOD.
END CLASS.
