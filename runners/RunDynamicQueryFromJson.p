/*
Executor generico de extracoes dinamicas.

Uso recomendado:

  _progres.exe -b -db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB ^
    -p D:\opencode\motor-progress\runners\RunDynamicQueryFromJson.p ^
    -param "request=D:\opencode\motor-progress\examples\customer-pipeline-advanced-request.json;output=D:\opencode\motor-progress\output\extracts\customer-pipeline-advanced.json"

Formato alternativo:

  -param "D:\path\request.json|D:\path\output.json"
*/

USING Progress.Json.ObjectModel.JsonObject.

PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\rest,D:\opencode\motor-progress\workers,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress,C:\Progress\OpenEdge\tty\netlib\OpenEdge.Net.pl," + PROPATH.

DEFINE VARIABLE cParam AS CHARACTER NO-UNDO.
DEFINE VARIABLE cRequestFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOutputFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcRequest AS LONGCHAR NO-UNDO.
DEFINE VARIABLE lcOutput AS LONGCHAR NO-UNDO.
DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
DEFINE VARIABLE joResult AS JsonObject NO-UNDO.

ASSIGN cParam = SESSION:PARAMETER.

RUN parseParameters(cParam, OUTPUT cRequestFile, OUTPUT cOutputFile).

IF cRequestFile = "" THEN DO:
    RUN writeError("INVALID_PARAMETER", "Parametro request obrigatorio.", cParam, cOutputFile).
    RETURN.
END.

IF cOutputFile = "" THEN
    RUN buildDefaultOutputFile(cRequestFile, OUTPUT cOutputFile).

FILE-INFO:FILE-NAME = cRequestFile.
IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
    RUN writeError("REQUEST_NOT_FOUND", "Arquivo JSON de request nao encontrado.", cRequestFile, cOutputFile).
    RETURN.
END.

DO ON ERROR UNDO, THROW:
    COPY-LOB FROM FILE cRequestFile TO lcRequest.

    ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
           oRequest = oSerializer:fromLongchar(lcRequest)
           oService = NEW DynamicMultiTableQueryService()
           joResult = oService:executeSyncNow(oRequest).

    joResult:Add("requestFile", cRequestFile).
    joResult:Add("outputFile", cOutputFile).

    RUN ensureParentDirectory(cOutputFile).
    joResult:Write(lcOutput, TRUE).
    COPY-LOB lcOutput TO FILE cOutputFile.

    CATCH oErr AS Progress.Lang.Error:
        RUN writeError("RUNNER_ERROR", oErr:GetMessage(1), cRequestFile, cOutputFile).
    END CATCH.

    FINALLY:
        DELETE OBJECT joResult NO-ERROR.
        DELETE OBJECT oService NO-ERROR.
        DELETE OBJECT oRequest NO-ERROR.
        DELETE OBJECT oSerializer NO-ERROR.
    END FINALLY.
END.

PROCEDURE parseParameters:
    DEFINE INPUT PARAMETER pcParam AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcRequest AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcOutput AS CHARACTER NO-UNDO.

    DEFINE VARIABLE iEntry AS INTEGER NO-UNDO.
    DEFINE VARIABLE cEntry AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cKey AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.

    ASSIGN pcParam = TRIM(pcParam).

    IF INDEX(pcParam, "|") > 0 THEN DO:
        ASSIGN pcRequest = TRIM(ENTRY(1, pcParam, "|"))
               pcOutput = TRIM(ENTRY(2, pcParam, "|")) NO-ERROR.
        RETURN.
    END.

    DO iEntry = 1 TO NUM-ENTRIES(pcParam, ";"):
        ASSIGN cEntry = TRIM(ENTRY(iEntry, pcParam, ";")).
        IF cEntry = "" OR INDEX(cEntry, "=") = 0 THEN NEXT.

        ASSIGN cKey = LC(TRIM(ENTRY(1, cEntry, "=")))
               cValue = TRIM(SUBSTRING(cEntry, INDEX(cEntry, "=") + 1)).

        CASE cKey:
            WHEN "request" THEN ASSIGN pcRequest = cValue.
            WHEN "input" THEN ASSIGN pcRequest = cValue.
            WHEN "json" THEN ASSIGN pcRequest = cValue.
            WHEN "output" THEN ASSIGN pcOutput = cValue.
            WHEN "out" THEN ASSIGN pcOutput = cValue.
        END CASE.
    END.
END PROCEDURE.

PROCEDURE buildDefaultOutputFile:
    DEFINE INPUT PARAMETER pcRequestFile AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcOutputFile AS CHARACTER NO-UNDO.

    DEFINE VARIABLE cBase AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cName AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iSlash AS INTEGER NO-UNDO.
    DEFINE VARIABLE iDot AS INTEGER NO-UNDO.

    ASSIGN iSlash = R-INDEX(pcRequestFile, "\").
    IF iSlash = 0 THEN
        ASSIGN cName = pcRequestFile.
    ELSE
        ASSIGN cName = SUBSTRING(pcRequestFile, iSlash + 1).

    ASSIGN iDot = R-INDEX(cName, ".").
    IF iDot > 0 THEN
        ASSIGN cName = SUBSTRING(cName, 1, iDot - 1).

    ASSIGN cBase = "D:\opencode\motor-progress\output\extracts".
    ASSIGN pcOutputFile = cBase + "\" + cName + "-result.json".
END PROCEDURE.

PROCEDURE ensureParentDirectory:
    DEFINE INPUT PARAMETER pcFile AS CHARACTER NO-UNDO.

    DEFINE VARIABLE cDir AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iSlash AS INTEGER NO-UNDO.

    ASSIGN iSlash = R-INDEX(pcFile, "\").
    IF iSlash <= 0 THEN
        RETURN.

    ASSIGN cDir = SUBSTRING(pcFile, 1, iSlash - 1).
    OS-CREATE-DIR VALUE("D:\opencode\motor-progress\output") NO-ERROR.
    OS-CREATE-DIR VALUE("D:\opencode\motor-progress\output\extracts") NO-ERROR.
    OS-CREATE-DIR VALUE(cDir) NO-ERROR.
END PROCEDURE.

PROCEDURE writeError:
    DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcDetails AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcOutputFile AS CHARACTER NO-UNDO.

    DEFINE VARIABLE joError AS JsonObject NO-UNDO.
    DEFINE VARIABLE joDetail AS JsonObject NO-UNDO.
    DEFINE VARIABLE lcError AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE cFile AS CHARACTER NO-UNDO.

    ASSIGN cFile = pcOutputFile.
    IF cFile = "" THEN
        ASSIGN cFile = "D:\opencode\motor-progress\output\extracts\last-run-error.json".

    RUN ensureParentDirectory(cFile).

    ASSIGN joError = NEW JsonObject()
           joDetail = NEW JsonObject().

    joDetail:Add("code", pcCode).
    joDetail:Add("message", pcMessage).
    joDetail:Add("details", pcDetails).
    joError:Add("success", FALSE).
    joError:Add("error", joDetail).
    joError:Add("outputFile", cFile).

    joError:Write(lcError, TRUE).
    COPY-LOB lcError TO FILE cFile.

    DELETE OBJECT joDetail NO-ERROR.
    DELETE OBJECT joError NO-ERROR.
END PROCEDURE.
