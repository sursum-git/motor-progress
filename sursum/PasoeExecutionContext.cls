/*
Concentrador de contexto de execucao para chamadas REST no PASOE.
Objetivo:
  - identificar em qual agente/processo esta sendo executada a request
  - registrar dados utilitarios (usuario, host, programa, ambiente)
  - permitir anexar metadados da transacao de banco vindos da camada de API
*/

USING Progress.Json.ObjectModel.JsonObject.

CLASS PasoeExecutionContext:

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
            ""
        ).

        ASSIGN cPasoeInstance = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("PASOE_INSTANCE"),
            OS-GETENV("APPSERVER_INSTANCE_NAME"),
            OS-GETENV("DLC_DEFAULT"), /* fallback ambiente de execucao */
            ""
        ).

        ASSIGN cPasoePid = THIS-OBJECT:firstNonEmpty(
            OS-GETENV("PASOE_PID"),
            OS-GETENV("APPSERVER_PID"),
            OS-GETENV("PROCESS_ID"),
            OS-GETENV("PID"),
            ""
        ).

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
