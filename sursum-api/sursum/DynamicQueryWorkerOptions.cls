/*
Opcoes de execucao do worker assincrono.
*/

CLASS DynamicQueryWorkerOptions:

    DEFINE PRIVATE VARIABLE cExecutionMode AS CHARACTER NO-UNDO INIT "CLIENT".
    DEFINE PRIVATE VARIABLE cOutputDir     AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cWorkerName    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE iBatchSize     AS INTEGER   NO-UNDO INIT 1.
    DEFINE PRIVATE VARIABLE iStaleMinutes  AS INTEGER   NO-UNDO INIT 30.
    DEFINE PRIVATE VARIABLE iMaxAttempts   AS INTEGER   NO-UNDO INIT 3.

    CONSTRUCTOR PUBLIC DynamicQueryWorkerOptions():
        ASSIGN cOutputDir = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("SURSUM_OUTPUT_DIR"),
            THIS-OBJECT:resolveDirectory("output/jobs")
        ).
        ASSIGN cWorkerName = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("SURSUM_WORKER_NAME"),
            "sursum-worker"
        ).
    END CONSTRUCTOR.

    METHOD PUBLIC VOID setExecutionMode(INPUT pcMode AS CHARACTER):
        IF LC(TRIM(pcMode)) = "pasoe" THEN
            ASSIGN cExecutionMode = "PASOE".
        ELSE
            ASSIGN cExecutionMode = "CLIENT".
    END METHOD.

    METHOD PUBLIC CHARACTER getExecutionMode():
        RETURN cExecutionMode.
    END METHOD.

    METHOD PUBLIC VOID setOutputDirectory(INPUT pcOutputDir AS CHARACTER):
        IF TRIM(pcOutputDir) <> "" THEN
            ASSIGN cOutputDir = pcOutputDir.
    END METHOD.

    METHOD PUBLIC CHARACTER getOutputDirectory():
        RETURN cOutputDir.
    END METHOD.

    METHOD PUBLIC VOID setWorkerName(INPUT pcWorkerName AS CHARACTER):
        IF TRIM(pcWorkerName) <> "" THEN
            ASSIGN cWorkerName = pcWorkerName.
    END METHOD.

    METHOD PUBLIC CHARACTER getWorkerName():
        RETURN cWorkerName.
    END METHOD.

    METHOD PUBLIC VOID setBatchSize(INPUT piBatchSize AS INTEGER):
        IF piBatchSize > 0 THEN
            ASSIGN iBatchSize = piBatchSize.
    END METHOD.

    METHOD PUBLIC INTEGER getBatchSize():
        RETURN iBatchSize.
    END METHOD.

    METHOD PUBLIC VOID setStaleMinutes(INPUT piStaleMinutes AS INTEGER):
        IF piStaleMinutes > 0 THEN
            ASSIGN iStaleMinutes = piStaleMinutes.
    END METHOD.

    METHOD PUBLIC INTEGER getStaleMinutes():
        RETURN iStaleMinutes.
    END METHOD.

    METHOD PUBLIC VOID setMaxAttempts(INPUT piMaxAttempts AS INTEGER):
        IF piMaxAttempts > 0 THEN
            ASSIGN iMaxAttempts = piMaxAttempts.
    END METHOD.

    METHOD PUBLIC INTEGER getMaxAttempts():
        RETURN iMaxAttempts.
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN
            RETURN pcA.
        RETURN pcB.
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
