USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.

/* Resolves legacy POST-only entries and explicit HTTP method allowlists. */
CLASS ProgramExecutionPolicy:
    DEFINE PUBLIC PROPERTY ProgramPath AS CHARACTER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY AllowedMethods AS CHARACTER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY IsConfigured AS LOGICAL NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY IsValid AS LOGICAL NO-UNDO GET. PRIVATE SET.

    CONSTRUCTOR PUBLIC ProgramExecutionPolicy(INPUT poPrograms AS JsonObject, INPUT pcCode AS CHARACTER):
        DEFINE VARIABLE joEntry AS JsonObject NO-UNDO.
        DEFINE VARIABLE jaMethods AS JsonArray NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cMethods AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cMethod AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        ASSIGN ProgramPath = "" AllowedMethods = "" IsConfigured = FALSE IsValid = FALSE.
        IF NOT VALID-OBJECT(poPrograms) THEN RETURN.
        IF NOT poPrograms:Has(pcCode) THEN RETURN.
        IsConfigured = TRUE.
        IF poPrograms:IsNull(pcCode) THEN RETURN.

        ASSIGN cPath = poPrograms:GetCharacter(pcCode) NO-ERROR.
        IF NOT ERROR-STATUS:ERROR AND cPath <> ? THEN DO:
            ASSIGN ProgramPath = TRIM(cPath)
                   AllowedMethods = "POST"
                   IsValid = ProgramPath <> "".
            RETURN.
        END.
        ASSIGN joEntry = poPrograms:GetJsonObject(pcCode) NO-ERROR.
        IF NOT VALID-OBJECT(joEntry) THEN RETURN.
        ASSIGN cPath = joEntry:GetCharacter("path") NO-ERROR.
        IF ERROR-STATUS:ERROR OR cPath = ? OR TRIM(cPath) = "" THEN RETURN.
        ProgramPath = TRIM(cPath).
        ASSIGN jaMethods = joEntry:GetJsonArray("methods") NO-ERROR.
        IF NOT VALID-OBJECT(jaMethods) THEN RETURN.
        IF jaMethods:Length = 0 THEN RETURN.
        DO i = 1 TO jaMethods:Length:
            ASSIGN cMethod = CAPS(TRIM(jaMethods:GetCharacter(i))) NO-ERROR.
            IF ERROR-STATUS:ERROR OR cMethod = ? THEN RETURN.
            IF NUM-ENTRIES(cMethod) <> 1 OR LOOKUP(cMethod, "GET,POST,PUT,PATCH,DELETE") = 0 THEN RETURN.
            IF LOOKUP(cMethod, cMethods) = 0 THEN
                cMethods = cMethods + (IF cMethods = "" THEN "" ELSE ",") + cMethod.
        END.
        ASSIGN AllowedMethods = cMethods IsValid = TRUE.
    END CONSTRUCTOR.
END CLASS.
