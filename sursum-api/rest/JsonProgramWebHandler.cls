USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.ObjectModelParser.
USING Progress.Web.IWebHandler.
USING OpenEdge.Web.WebResponse.
USING OpenEdge.Web.WebResponseWriter.

/* Register the SursumPrograms prefix separately in PASOE. */
CLASS JsonProgramWebHandler IMPLEMENTS IWebHandler:
    METHOD PUBLIC INTEGER HandleRequest():
        DEFINE VARIABLE oRouter AS JsonProgramRouter NO-UNDO.
        DEFINE VARIABLE oResponse AS WebResponse NO-UNDO.
        DEFINE VARIABLE oWriter AS WebResponseWriter NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oExec AS ApiExecutionRepository NO-UNDO.
        DEFINE VARIABLE joExecution AS JsonObject NO-UNDO.
        DEFINE VARIABLE cExecutionId AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cMethod AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cQuery AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lcBody AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcRawBody AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE lcReply AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE mReply AS MEMPTR NO-UNDO.
        DEFINE VARIABLE mBody AS MEMPTR NO-UNDO.
        DEFINE VARIABLE jaProgramLogs AS JsonArray NO-UNDO.
        DEFINE VARIABLE iProgramLogCount AS INTEGER NO-UNDO.

        PasoeExecutionContext:clearCurrent().

        FIX-CODEPAGE(lcBody) = "UTF-8".
        FIX-CODEPAGE(lcReply) = "UTF-8".
        /* FORM-INPUT carries the raw JSON bytes; interpret them as UTF-8. */
        lcRawBody = WEB-CONTEXT:FORM-INPUT.
        IF lcRawBody <> "" AND lcRawBody <> ? THEN DO:
            COPY-LOB FROM lcRawBody TO mBody NO-CONVERT.
            COPY-LOB FROM mBody TO lcBody CONVERT SOURCE CODEPAGE "UTF-8" NO-ERROR.
            IF ERROR-STATUS:ERROR THEN lcBody = "invalid-json".
        END.

        ASSIGN cMethod = WEB-CONTEXT:GET-CGI-VALUE("ENV", "REQUEST_METHOD")
               cPath = WEB-CONTEXT:GET-CGI-VALUE("ENV", "PATH_INFO")
               cQuery = WEB-CONTEXT:GET-CGI-VALUE("ENV", "QUERY_STRING")
               oRouter = NEW JsonProgramRouter("conf-web-handler/program-routes.json").

        IF cMethod <> "OPTIONS" THEN DO:
            ASSIGN oContext = NEW PasoeExecutionContext()
                   oExec = NEW ApiExecutionRepository().
            oContext:setCustomField("entrypoint", "WEB").
            oContext:setCustomField("transport", "PASOE-WEB").
            oContext:setCustomField("programName", cPath).
            THIS-OBJECT:applyCallerUser(oContext, lcBody, cQuery).
            THIS-OBJECT:applyRequestMetadata(oContext).

            ASSIGN joExecution = oExec:startExecution(oContext, "program", cMethod + " " + cPath, "running", THIS-OBJECT:buildRequestSummary(cPath, cQuery, lcBody)).
            IF VALID-OBJECT(joExecution) AND joExecution:Has("success") AND joExecution:GetLogical("success") THEN DO:
                ASSIGN cExecutionId = THIS-OBJECT:getJsonChar(joExecution, "executionId").
                oContext:setCustomField("executionId", cExecutionId).
                PasoeExecutionContext:setCurrent(oContext).
            END.
            DELETE OBJECT joExecution NO-ERROR.
            IF cExecutionId <> "" THEN DO:
                ASSIGN joExecution = oExec:updateExecutionPayloads(cExecutionId, lcBody, ?).
                DELETE OBJECT joExecution NO-ERROR.
            END.
        END.

        ASSIGN lcReply = oRouter:dispatch(cMethod, cPath, cQuery, lcBody).

        IF cExecutionId <> "" THEN DO:
            jaProgramLogs = oContext:getLogMessages().
            iProgramLogCount = jaProgramLogs:Length.
            DELETE OBJECT jaProgramLogs.
            IF NOT oExec:flushLogMessages(oContext) THEN
                LOG-MANAGER:WRITE-MESSAGE("Falha ao persistir logs da execucao " + cExecutionId,"PROGRAM-LOG").
            IF oRouter:StatusCode >= 400 OR THIS-OBJECT:replyIsBusinessFailure(lcReply) THEN
                ASSIGN joExecution = oExec:failExecution(cExecutionId, "PROGRAM_RESPONSE_ERROR", "Programa retornou erro", oContext).
            ELSE
                ASSIGN joExecution = oExec:finishExecution(cExecutionId, "completed", "Programa executado", oContext).
            DELETE OBJECT joExecution NO-ERROR.
            ASSIGN joExecution = oExec:updateExecutionPayloads(cExecutionId, ?, lcReply).
            DELETE OBJECT joExecution NO-ERROR.
        END.

        ASSIGN oResponse = NEW WebResponse(oRouter:StatusCode)
               oWriter = NEW WebResponseWriter(oResponse).
        oResponse:SetHeader("Cache-Control", "no-store").
        IF cExecutionId <> "" THEN DO:
            oResponse:SetHeader("X-Sursum-Execution-Id", cExecutionId).
            oResponse:SetHeader("X-Sursum-Log-Count", TRIM(STRING(iProgramLogCount,">>>>>>>>>9"))).
        END.
        IF oRouter:StatusCode <> 204 THEN
            oResponse:SetHeader("Content-Type", "application/json; charset=UTF-8").
        IF oRouter:AllowMethods <> "" THEN DO:
            oResponse:SetHeader("Allow", oRouter:AllowMethods).
            oResponse:SetHeader("Access-Control-Allow-Methods", oRouter:AllowMethods).
        END.
        oResponse:SetHeader("Access-Control-Allow-Headers", "Content-Type, Accept, X-Sursum-User, X-Session-Id").
        oWriter:Open().
        IF oRouter:StatusCode <> 204 THEN DO:
            /* Write bytes to avoid conversion through the WebSpeed stream codepage. */
            COPY-LOB FROM lcReply TO mReply NO-CONVERT.
            oWriter:Write(mReply, 1, GET-SIZE(mReply)).
        END.
        oWriter:Flush().
        oWriter:Close().
        RETURN 0.
        FINALLY:
            IF VALID-OBJECT(jaProgramLogs) THEN DELETE OBJECT jaProgramLogs NO-ERROR.
            IF VALID-OBJECT(oExec) AND VALID-OBJECT(oContext) THEN DO:
                IF NOT oExec:flushLogMessages(oContext) THEN
                    LOG-MANAGER:WRITE-MESSAGE("Falha ao persistir logs pendentes da execucao " + cExecutionId,"PROGRAM-LOG").
            END.
            PasoeExecutionContext:clearCurrent().
            SET-SIZE(mReply) = 0.
            SET-SIZE(mBody) = 0.
            IF VALID-OBJECT(joExecution) THEN DELETE OBJECT joExecution.
            IF VALID-OBJECT(oExec) THEN DELETE OBJECT oExec.
            IF VALID-OBJECT(oContext) THEN DELETE OBJECT oContext.
            IF VALID-OBJECT(oWriter) THEN DELETE OBJECT oWriter.
            IF VALID-OBJECT(oResponse) THEN DELETE OBJECT oResponse.
            IF VALID-OBJECT(oRouter) THEN DELETE OBJECT oRouter.
        END FINALLY.
    END METHOD.
    METHOD PRIVATE VOID applyRequestMetadata(INPUT poContext AS PasoeExecutionContext):
        IF NOT VALID-OBJECT(poContext) THEN
            RETURN.
        poContext:setRequesterInfo(THIS-OBJECT:getRequesterIp(), THIS-OBJECT:getRequesterBrowser(), THIS-OBJECT:getRequesterSessionId()).
    END METHOD.

    METHOD PRIVATE CHARACTER getRequesterIp():
        DEFINE VARIABLE cIp AS CHARACTER NO-UNDO.
        ASSIGN cIp = THIS-OBJECT:firstNonEmpty(
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "HTTP_X_FORWARDED_FOR":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "HTTP_X_REAL_IP":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "REMOTE_ADDR":U),
            ""
        ) NO-ERROR.
        IF cIp <> "" AND cIp <> ? AND INDEX(cIp, ",") > 0 THEN
            ASSIGN cIp = TRIM(ENTRY(1, cIp)).
        RETURN cIp.
    END METHOD.

    METHOD PRIVATE CHARACTER getRequesterBrowser():
        RETURN THIS-OBJECT:firstNonEmpty(
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "HTTP_USER_AGENT":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "User-Agent":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "USER_AGENT":U),
            ""
        ) NO-ERROR.
    END METHOD.

    METHOD PRIVATE CHARACTER getRequesterSessionId():
        DEFINE VARIABLE cSession AS CHARACTER NO-UNDO.
        ASSIGN cSession = THIS-OBJECT:firstNonEmpty(
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "HTTP_X_SESSION_ID":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "X-Session-Id":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "X_SESSION_ID":U),
            ""
        ) NO-ERROR.
        IF cSession <> "" AND cSession <> ? THEN
            RETURN cSession.
        RETURN THIS-OBJECT:getCookieValue("JSESSIONID").
    END METHOD.

    METHOD PRIVATE CHARACTER getCookieValue(INPUT pcCookieName AS CHARACTER):
        DEFINE VARIABLE cCookie AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPair AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ASSIGN cCookie = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "HTTP_COOKIE":U) NO-ERROR.
        IF cCookie = "" OR cCookie = ? THEN
            RETURN "".
        DO i = 1 TO NUM-ENTRIES(cCookie, ";"):
            ASSIGN cPair = TRIM(ENTRY(i, cCookie, ";")).
            IF ENTRY(1, cPair + "=", "=") = pcCookieName THEN
                RETURN ENTRY(2, cPair + "=", "=").
        END.
        RETURN "".
    END METHOD.

    METHOD PRIVATE VOID applyCallerUser(INPUT poContext AS PasoeExecutionContext, INPUT pcBody AS LONGCHAR, INPUT pcQuery AS CHARACTER):
        DEFINE VARIABLE cUser AS CHARACTER NO-UNDO.
        DEFINE VARIABLE joBody AS JsonObject NO-UNDO.

        IF NOT VALID-OBJECT(poContext) THEN
            RETURN.

        ASSIGN cUser = THIS-OBJECT:firstNonEmpty(
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "HTTP_X_SURSUM_USER":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "X-Sursum-User":U),
            WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "X_SURSUM_USER":U),
            ""
        ) NO-ERROR.

        IF cUser = "" OR cUser = ? THEN
            ASSIGN cUser = THIS-OBJECT:firstNonEmpty(
                THIS-OBJECT:getQueryValue(pcQuery, "usuario"),
                THIS-OBJECT:getQueryValue(pcQuery, "userName"),
                THIS-OBJECT:getQueryValue(pcQuery, "requestUser"),
                ""
            ).
        IF cUser <> "" AND cUser <> ? THEN
            ASSIGN cUser = OpenEdge.Net.URI:Decode(REPLACE(cUser, "+", " ")).

        IF (cUser = "" OR cUser = ?) AND pcBody <> "" AND pcBody <> ? THEN DO:
            ASSIGN joBody = THIS-OBJECT:parseJsonObject(pcBody) NO-ERROR.
            IF VALID-OBJECT(joBody) THEN
                ASSIGN cUser = THIS-OBJECT:firstNonEmpty(
                    THIS-OBJECT:getJsonChar(joBody, "usuario"),
                    THIS-OBJECT:getJsonChar(joBody, "userName"),
                    THIS-OBJECT:getJsonChar(joBody, "requestUser"),
                    ""
                ).
            DELETE OBJECT joBody NO-ERROR.
        END.

        IF cUser <> "" AND cUser <> ? THEN
            poContext:setCurrentUser(cUser).
    END METHOD.

    METHOD PRIVATE CHARACTER buildRequestSummary(INPUT pcPath AS CHARACTER, INPUT pcQuery AS CHARACTER, INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE cSummary AS CHARACTER NO-UNDO.
        ASSIGN cSummary = pcPath.
        IF pcQuery <> "" AND pcQuery <> ? THEN
            ASSIGN cSummary = cSummary + "?" + pcQuery.
        IF pcBody <> "" AND pcBody <> ? THEN
            ASSIGN cSummary = cSummary + " body=" + SUBSTRING(STRING(pcBody), 1, 900).
        RETURN SUBSTRING(cSummary, 1, 1000).
    END METHOD.

    METHOD PRIVATE LOGICAL replyIsBusinessFailure(INPUT pcReply AS LONGCHAR):
        DEFINE VARIABLE joReply AS JsonObject NO-UNDO.
        DEFINE VARIABLE lFailed AS LOGICAL NO-UNDO.

        ASSIGN joReply = THIS-OBJECT:parseJsonObject(pcReply) NO-ERROR.
        IF VALID-OBJECT(joReply) AND joReply:Has("success") AND NOT joReply:IsNull("success") THEN
            ASSIGN lFailed = NOT joReply:GetLogical("success") NO-ERROR.
        DELETE OBJECT joReply NO-ERROR.
        RETURN lFailed.
    END METHOD.

    METHOD PRIVATE JsonObject parseJsonObject(INPUT pcJson AS LONGCHAR):
        DEFINE VARIABLE oParser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE oConstruct AS JsonConstruct NO-UNDO.
        DEFINE VARIABLE joValue AS JsonObject NO-UNDO.
        DEFINE VARIABLE cJson AS CHARACTER NO-UNDO.

        ASSIGN cJson = STRING(pcJson) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN ?.

        ASSIGN oParser = NEW ObjectModelParser().
        ASSIGN oConstruct = oParser:Parse(cJson) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            DELETE OBJECT oParser NO-ERROR.
            RETURN ?.
        END.
        ASSIGN joValue = CAST(oConstruct, JsonObject) NO-ERROR.
        DELETE OBJECT oParser NO-ERROR.
        RETURN joValue.
    END METHOD.

    METHOD PRIVATE CHARACTER getJsonChar(INPUT poJson AS JsonObject, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE cValue AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(poJson) OR NOT poJson:Has(pcName) OR poJson:IsNull(pcName) THEN
            RETURN "".
        ASSIGN cValue = poJson:GetCharacter(pcName) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN
            RETURN "".
        RETURN cValue.
    END METHOD.

    METHOD PRIVATE CHARACTER getQueryValue(INPUT pcQuery AS CHARACTER, INPUT pcName AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE cPair AS CHARACTER NO-UNDO.

        IF pcQuery = ? OR pcQuery = "" THEN
            RETURN "".

        DO i = 1 TO NUM-ENTRIES(pcQuery, "&"):
            ASSIGN cPair = ENTRY(i, pcQuery, "&").
            IF ENTRY(1, cPair + "=", "=") = pcName THEN
                RETURN ENTRY(2, cPair + "=", "=").
        END.

        RETURN "".
    END METHOD.

    METHOD PRIVATE CHARACTER firstNonEmpty(INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER, INPUT pcC AS CHARACTER, INPUT pcD AS CHARACTER):
        IF pcA <> "" AND pcA <> ? THEN RETURN pcA.
        IF pcB <> "" AND pcB <> ? THEN RETURN pcB.
        IF pcC <> "" AND pcC <> ? THEN RETURN pcC.
        IF pcD <> "" AND pcD <> ? THEN RETURN pcD.
        RETURN "".
    END METHOD.
END CLASS.







