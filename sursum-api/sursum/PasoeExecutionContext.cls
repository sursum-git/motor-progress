/*
Concentrador de contexto de execucao para chamadas REST no PASOE.
Objetivo:
  - identificar em qual agente/processo esta sendo executada a request
  - registrar dados utilitarios (usuario, host, programa, ambiente)
  - permitir anexar metadados da transacao de banco vindos da camada de API
*/

USING Progress.Json.ObjectModel.JsonObject.

CLASS PasoeExecutionContext:

    /* Escopo da request ABL, preenchido/limpo pelo handler; nunca pelo JSON. */
    DEFINE PUBLIC STATIC PROPERTY Current AS PasoeExecutionContext NO-UNDO GET. PRIVATE SET.
    DEFINE PRIVATE VARIABLE logSequence AS INTEGER NO-UNDO.
    DEFINE PRIVATE TEMP-TABLE ttProgramLog NO-UNDO
        FIELD sequenceId AS INTEGER
        FIELD logLevel AS CHARACTER
        FIELD logMessage AS CHARACTER
        FIELD occurredAt AS DATETIME
        INDEX seq IS PRIMARY UNIQUE sequenceId.

    METHOD PUBLIC STATIC VOID setCurrent(INPUT poContext AS PasoeExecutionContext):
        PasoeExecutionContext:Current = poContext.
    END METHOD.

    METHOD PUBLIC STATIC VOID clearCurrent():
        PasoeExecutionContext:Current = ?.
    END METHOD.

    METHOD PUBLIC LOGICAL queueLogMessage(INPUT pcLevel AS CHARACTER, INPUT pcMessage AS CHARACTER):
        DEFINE VARIABLE levelName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE executionId AS CHARACTER NO-UNDO.
        executionId = THIS-OBJECT:getCustomField("executionId").
        IF executionId = "" OR executionId = ? OR pcLevel = ? OR pcMessage = ? THEN RETURN FALSE.
        /* Mensagem de log, nao payload: impede truncamento do contexto JSON. */
        IF LENGTH(pcMessage) > 4000 THEN RETURN FALSE.
        levelName = LC(TRIM(pcLevel)).
        IF LOOKUP(levelName,"debug,info,warning,error") = 0 THEN RETURN FALSE.
        logSequence = logSequence + 1.
        CREATE ttProgramLog.
        ASSIGN ttProgramLog.sequenceId = logSequence
               ttProgramLog.logLevel = levelName
               ttProgramLog.logMessage = pcMessage
               ttProgramLog.occurredAt = NOW.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC Progress.Json.ObjectModel.JsonArray getLogMessages():
        DEFINE VARIABLE items AS Progress.Json.ObjectModel.JsonArray NO-UNDO.
        DEFINE VARIABLE item AS JsonObject NO-UNDO.
        items = NEW Progress.Json.ObjectModel.JsonArray().
        FOR EACH ttProgramLog BY sequenceId:
            item = NEW JsonObject().
            item:Add("level",ttProgramLog.logLevel).
            item:Add("message",ttProgramLog.logMessage).
            item:Add("occurredAt",ttProgramLog.occurredAt).
            items:Add(item).
        END.
        RETURN items.
    END METHOD.

    METHOD PUBLIC VOID clearLogMessages():
        EMPTY TEMP-TABLE ttProgramLog.
    END METHOD.



    DEFINE PRIVATE VARIABLE cRequestId          AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cCapturedAt         AS DATETIME NO-UNDO.
    DEFINE PRIVATE VARIABLE cRuntimeVersion     AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cProgramName        AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cOperatingSystem    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cCurrentUser        AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cEnvUser            AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cHostName           AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cPasoeAgent         AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cPasoeInstance      AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cPasoePid           AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cPasoeThread        AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cDatabaseName       AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cDbTransactionId    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cRequesterIp        AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cRequesterBrowser   AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE cRequesterSessionId AS CHARACTER NO-UNDO.

    DEFINE PRIVATE TEMP-TABLE ttCustom NO-UNDO
        FIELD customKey   AS CHARACTER
        FIELD customValue AS CHARACTER.

    CONSTRUCTOR PUBLIC PasoeExecutionContext():
        ASSIGN cRequestId = THIS-OBJECT:createRequestId().
        THIS-OBJECT:refresh().
    END CONSTRUCTOR.

    METHOD PUBLIC VOID refresh():
        ASSIGN cCapturedAt      = NOW
               cRuntimeVersion  = PROVERSION
               cProgramName     = PROGRAM-NAME(1)
               cOperatingSystem = OPSYS
               cCurrentUser     = "".

        ASSIGN cEnvUser = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("USERNAME"),
            OS-GETENV("USER"),
            ""
        ).
        IF cCurrentUser = "" THEN
            ASSIGN cCurrentUser = cEnvUser.

        ASSIGN cHostName = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("COMPUTERNAME"),
            OS-GETENV("HOSTNAME"),
            OS-GETENV("AGENT_HOST"),
            "nao-disponivel"
        ).

        ASSIGN cPasoeAgent = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("PASOE_AGENT_NAME"),
            OS-GETENV("APPSERVER_AGENT_NAME"),
            OS-GETENV("PASOE_AGENT"),
            OS-GETENV("APPSERVER_NAME"),
            PasoeRuntimeIdentity:AgentName(SESSION:STARTUP-PARAMETERS)
        ).

        ASSIGN cPasoeInstance = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("PASOE_INSTANCE"),
            OS-GETENV("APPSERVER_INSTANCE_NAME"),
            PasoeRuntimeIdentity:InstanceName(OS-GETENV("CATALINA_BASE")),
            ""
        ).

        ASSIGN cPasoePid = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("PASOE_PID"),
            OS-GETENV("APPSERVER_PID"),
            OS-GETENV("PROCESS_ID"),
            OS-GETENV("PID"),
            ""
        ).
        IF cPasoePid = "" OR cPasoePid = ? THEN
            ASSIGN cPasoePid = THIS-OBJECT:tryReadProcessPid().

        ASSIGN cPasoeThread = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("TID"),
            OS-GETENV("THREAD_ID"),
            ""
        ).

        ASSIGN cDatabaseName = THIS-OBJECT:tryReadDatabaseName().
    END METHOD.

    METHOD PRIVATE CHARACTER tryReadDatabaseName():
        DEFINE VARIABLE cDb AS CHARACTER NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            ASSIGN cDb = LDBNAME(1).
        END.
        IF cDb = ? OR cDb = "" THEN
            RETURN "nao-disponivel".
        RETURN cDb.
    END METHOD.

    METHOD PRIVATE CHARACTER tryReadProcessPid():
        DEFINE VARIABLE cPid AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cCommand AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iPid AS INTEGER NO-UNDO.

        IF OPSYS <> "UNIX" THEN
            RETURN "".

        ASSIGN cCommand = "sh -c " + QUOTER("echo $PPID").
        DO ON ERROR UNDO, LEAVE:
            INPUT THROUGH VALUE(cCommand) NO-ECHO.
            IMPORT UNFORMATTED cPid.
            INPUT CLOSE.
        END.
        IF ERROR-STATUS:ERROR THEN DO:
            INPUT CLOSE.
            RETURN "".
        END.

        ASSIGN cPid = TRIM(cPid).
        IF cPid = "" OR cPid = ? THEN
            RETURN "".

        DO ON ERROR UNDO, LEAVE:
            ASSIGN iPid = INTEGER(cPid).
        END.
        IF ERROR-STATUS:ERROR OR iPid <= 0 THEN
            RETURN "".

        RETURN STRING(iPid).
    END METHOD.

    METHOD PRIVATE CHARACTER createRequestId():
        RETURN STRING(YEAR(TODAY), "9999")
             + STRING(MONTH(TODAY), "99")
             + STRING(DAY(TODAY), "99")
             + "-"
             + STRING(TIME, "999999")
             + "-"
             + STRING(RANDOM(1, 999999), "999999").
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER, INPUT pcC AS CHARACTER, INPUT pcD AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN RETURN pcA.
        IF pcB <> "" AND pcB <> ? THEN RETURN pcB.
        IF pcC <> "" AND pcC <> ? THEN RETURN pcC.
        IF pcD <> "" AND pcD <> ? THEN RETURN pcD.
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER, INPUT pcC AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN RETURN pcA.
        IF pcB <> "" AND pcB <> ? THEN RETURN pcB.
        IF pcC <> "" AND pcC <> ? THEN RETURN pcC.
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(
        INPUT pcA AS CHARACTER,
        INPUT pcB AS CHARACTER,
        INPUT pcC AS CHARACTER,
        INPUT pcD AS CHARACTER,
        INPUT pcE AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN RETURN pcA.
        IF pcB <> "" AND pcB <> ? THEN RETURN pcB.
        IF pcC <> "" AND pcC <> ? THEN RETURN pcC.
        IF pcD <> "" AND pcD <> ? THEN RETURN pcD.
        IF pcE <> "" AND pcE <> ? THEN RETURN pcE.
        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER coalesce(INPUT pcValue AS CHARACTER, INPUT pcDefault AS CHARACTER):
        IF pcValue = ? OR TRIM(pcValue) = "" THEN
            RETURN pcDefault.
        RETURN pcValue.
    END METHOD.

    METHOD PUBLIC VOID setCurrentUser(INPUT pcUserName AS CHARACTER):
        ASSIGN cCurrentUser = THIS-OBJECT:coalesce(pcUserName, cCurrentUser).
    END METHOD.

    METHOD PUBLIC VOID setRequesterInfo(INPUT pcIp AS CHARACTER, INPUT pcBrowser AS CHARACTER, INPUT pcSessionId AS CHARACTER):
        ASSIGN cRequesterIp = THIS-OBJECT:coalesce(pcIp, cRequesterIp)
               cRequesterBrowser = THIS-OBJECT:coalesce(pcBrowser, cRequesterBrowser)
               cRequesterSessionId = THIS-OBJECT:coalesce(pcSessionId, cRequesterSessionId).
    END METHOD.

    METHOD PUBLIC VOID setDatabaseTransactionId(INPUT pcTransactionId AS CHARACTER):
        ASSIGN cDbTransactionId = pcTransactionId.
    END METHOD.

    METHOD PUBLIC CHARACTER getDatabaseTransactionId():
        RETURN cDbTransactionId.
    END METHOD.

    METHOD PUBLIC CHARACTER getRequestId():
        RETURN cRequestId.
    END METHOD.

    METHOD PUBLIC CHARACTER getPasoePid():
        RETURN cPasoePid.
    END METHOD.

    METHOD PUBLIC CHARACTER getPasoeAgent():
        RETURN cPasoeAgent.
    END METHOD.

    METHOD PUBLIC CHARACTER getPasoeInstance():
        RETURN cPasoeInstance.
    END METHOD.

    METHOD PUBLIC VOID setCustomField(
        INPUT pcKey   AS CHARACTER,
        INPUT pcValue AS CHARACTER):

        DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cTrimKey AS CHARACTER NO-UNDO.

        ASSIGN cKey = pcKey
               cTrimKey = TRIM(cKey)
               cValue = pcValue.
        IF cTrimKey = "" THEN RETURN.

        FIND FIRST ttCustom WHERE ttCustom.customKey = cTrimKey NO-ERROR.
        IF AVAILABLE ttCustom THEN
            ASSIGN ttCustom.customValue = cValue.
        ELSE DO:
            CREATE ttCustom.
            ASSIGN ttCustom.customKey = cTrimKey
                   ttCustom.customValue = cValue.
        END.
    END METHOD.

    METHOD PUBLIC VOID clearCustom():
        EMPTY TEMP-TABLE ttCustom.
    END METHOD.

    METHOD PUBLIC CHARACTER getCustomField(INPUT pcKey AS CHARACTER):
        DEFINE VARIABLE cTrimKey AS CHARACTER NO-UNDO.
        ASSIGN cTrimKey = TRIM(pcKey).
        IF cTrimKey = "" THEN
            RETURN "".
        FIND FIRST ttCustom WHERE ttCustom.customKey = cTrimKey NO-ERROR.
        IF AVAILABLE ttCustom THEN
            RETURN ttCustom.customValue.
        RETURN "".
    END METHOD.

    METHOD PUBLIC JsonObject toJson():
        DEFINE VARIABLE joContext AS JsonObject NO-UNDO.
        DEFINE VARIABLE joCustom  AS JsonObject NO-UNDO.

        ASSIGN joContext = NEW JsonObject()
               joCustom  = NEW JsonObject().

        joContext:Add("requestId", cRequestId).
        joContext:Add("capturedAt", STRING(cCapturedAt)).
        joContext:Add("runtimeVersion", cRuntimeVersion).
        joContext:Add("programName", cProgramName).
        joContext:Add("operatingSystem", cOperatingSystem).
        joContext:Add("currentUser", cCurrentUser).
        joContext:Add("envUser", cEnvUser).
        joContext:Add("hostName", cHostName).
        joContext:Add("pasoeAgent", cPasoeAgent).
        joContext:Add("pasoeInstance", cPasoeInstance).
        joContext:Add("pasoePid", cPasoePid).
        joContext:Add("pasoeThread", cPasoeThread).
        joContext:Add("databaseName", cDatabaseName).
        joContext:Add("dbTransactionId", cDbTransactionId).
        joContext:Add("databaseTransaction", cDbTransactionId).
        joContext:Add("requesterIp", cRequesterIp).
        joContext:Add("requesterBrowser", cRequesterBrowser).
        joContext:Add("requesterSessionId", cRequesterSessionId).

        FOR EACH ttCustom:
            joCustom:Add(ttCustom.customKey, ttCustom.customValue).
        END.
        joContext:Add("custom", joCustom).
        RETURN joContext.
    END METHOD.

    METHOD PUBLIC CHARACTER toDebugString():
        RETURN "ctx=" + cRequestId
             + ", agent=" + THIS-OBJECT:getPasoeAgent()
             + ", pid=" + cPasoePid
             + ", dbTxn=" + cDbTransactionId
             + ", host=" + cHostName
             + ", user=" + cCurrentUser.
    END METHOD.

END CLASS.

