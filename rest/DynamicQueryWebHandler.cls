/*
WebHandler HTTP para validacao REST real no PASOE.
URLs esperadas:
  POST /web/SursumDynamicQuery/query
  GET  /web/SursumDynamicQuery/jobs/{jobId}
  GET  /web/SursumDynamicQuery/jobs/{jobId}/result
  POST /web/SursumDynamicQuery/jobs/drain
  GET  /web/SursumDynamicQuery/benchmarks/customer-count
*/

USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Lang.Error.
USING Progress.Web.IWebHandler.
USING OpenEdge.Web.WebResponse.
USING OpenEdge.Web.WebResponseWriter.

CLASS DynamicQueryWebHandler IMPLEMENTS IWebHandler:

    DEFINE QUERY qBenchCustomer FOR Customer
        FIELDS(CustNum)
        SCROLLING.

    METHOD PUBLIC INTEGER HandleRequest():
        DEFINE VARIABLE cMethod AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cBody AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN cMethod = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "REQUEST_METHOD":U) NO-ERROR.
        ASSIGN cPath = WEB-CONTEXT:GET-CGI-VALUE("ENV":U, "PATH_INFO":U) NO-ERROR.
        ASSIGN cBody = WEB-CONTEXT:FORM-INPUT NO-ERROR.

        DO ON ERROR UNDO, THROW:
            CASE cMethod:
                WHEN "POST" THEN DO:
                    IF cPath MATCHES "*/jobs/drain" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleDrain().
                    END.
                    ELSE IF cPath MATCHES "*/query" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handlePostQuery(cBody).
                    END.
                    ELSE
                        ASSIGN joRet = THIS-OBJECT:buildError("NOT_FOUND", "Endpoint nao encontrado", cMethod + " " + cPath).
                END.
                WHEN "GET" THEN DO:
                    IF cPath MATCHES "*/benchmarks/customer-count" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleCustomerCountBenchmark().
                    END.
                    ELSE IF cPath MATCHES "*/jobs/*/result" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetResult(THIS-OBJECT:getJobIdFromPath(cPath)).
                    END.
                    ELSE IF cPath MATCHES "*/jobs/*" THEN DO:
                        ASSIGN joRet = THIS-OBJECT:handleGetStatus(THIS-OBJECT:getJobIdFromPath(cPath)).
                    END.
                    ELSE
                        ASSIGN joRet = THIS-OBJECT:buildError("NOT_FOUND", "Endpoint nao encontrado", cMethod + " " + cPath).
                END.
                OTHERWISE
                    ASSIGN joRet = THIS-OBJECT:buildError("METHOD_NOT_ALLOWED", "Metodo nao suportado", cMethod).
            END CASE.

            THIS-OBJECT:writeJson(joRet).

            CATCH oErr AS Error:
                ASSIGN joRet = THIS-OBJECT:buildError("WEB_HANDLER_ERROR", oErr:GetMessage(1), cMethod + " " + cPath).
                THIS-OBJECT:writeJson(joRet).
            END CATCH.
        END.

        IF VALID-OBJECT(joRet) THEN
            DELETE OBJECT joRet NO-ERROR.

        RETURN 0.
    END METHOD.

    METHOD PRIVATE JsonObject handlePostQuery(INPUT pcBody AS LONGCHAR):
        DEFINE VARIABLE oSerializer AS DynamicQueryRequestSerializer NO-UNDO.
        DEFINE VARIABLE oRequest AS DynamicQueryRequestModel NO-UNDO.
        DEFINE VARIABLE oContext AS PasoeExecutionContext NO-UNDO.
        DEFINE VARIABLE oService AS DynamicMultiTableQueryService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        IF pcBody = "" OR pcBody = ? THEN
            RETURN THIS-OBJECT:buildError("EMPTY_BODY", "Body JSON obrigatorio", "POST /query").

        ASSIGN oSerializer = NEW DynamicQueryRequestSerializer()
               oRequest = oSerializer:fromLongchar(pcBody)
               oContext = NEW PasoeExecutionContext()
               oService = NEW DynamicMultiTableQueryService().

        oContext:setCustomField("entrypoint", "WEB").
        oContext:setCustomField("transport", "PASOE-WEB").

        ASSIGN joRet = oService:execute(oRequest, oContext).

        DELETE OBJECT oSerializer NO-ERROR.
        DELETE OBJECT oRequest NO-ERROR.
        DELETE OBJECT oContext NO-ERROR.
        DELETE OBJECT oService NO-ERROR.

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleDrain():
        DEFINE VARIABLE oOptions AS DynamicQueryWorkerOptions NO-UNDO.
        DEFINE VARIABLE oWorker AS DynamicQueryWorkerService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        ASSIGN oOptions = NEW DynamicQueryWorkerOptions()
               oWorker = NEW DynamicQueryWorkerService().

        oOptions:setExecutionMode("PASOE").
        oOptions:setWorkerName("pasoe-web-drain").
        oOptions:setBatchSize(10).
        oOptions:setOutputDirectory("D:\opencode\motor-progress\output\jobs").

        ASSIGN joRet = oWorker:drain(oOptions).

        DELETE OBJECT oOptions NO-ERROR.
        DELETE OBJECT oWorker NO-ERROR.

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleGetStatus(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE oAsync AS DynamicQueryAsyncService NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        IF pcJobId = "" THEN
            RETURN THIS-OBJECT:buildError("JOB_ID_REQUIRED", "jobId obrigatorio", "").

        ASSIGN oAsync = NEW DynamicQueryAsyncService().
        ASSIGN joRet = oAsync:getStatus(pcJobId).
        DELETE OBJECT oAsync NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleGetResult(INPUT pcJobId AS CHARACTER):
        DEFINE VARIABLE oRest AS DynamicQueryRestResource NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.

        IF pcJobId = "" THEN
            RETURN THIS-OBJECT:buildError("JOB_ID_REQUIRED", "jobId obrigatorio", "").

        ASSIGN oRest = NEW DynamicQueryRestResource().
        ASSIGN joRet = oRest:getJobResult(pcJobId).
        DELETE OBJECT oRest NO-ERROR.
        RETURN joRet.
    END METHOD.

    METHOD PRIVATE JsonObject handleCustomerCountBenchmark():
        DEFINE VARIABLE iCount AS INT64 NO-UNDO.
        DEFINE VARIABLE iForEachMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iOpenMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResultsMs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iNumResults AS INTEGER NO-UNDO.
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joForEach AS JsonObject NO-UNDO.
        DEFINE VARIABLE joPreselect AS JsonObject NO-UNDO.

        ETIME(TRUE).
        FOR EACH Customer NO-LOCK:
            ASSIGN iCount = iCount + 1.
        END.
        ASSIGN iForEachMs = ETIME.

        ETIME(TRUE).
        OPEN QUERY qBenchCustomer PRESELECT EACH Customer NO-LOCK.
        ASSIGN iOpenMs = ETIME.

        ETIME(TRUE).
        ASSIGN iNumResults = NUM-RESULTS("qBenchCustomer").
        ASSIGN iNumResultsMs = ETIME.

        CLOSE QUERY qBenchCustomer.

        ASSIGN joRet = NEW JsonObject()
               joForEach = NEW JsonObject()
               joPreselect = NEW JsonObject().

        joForEach:Add("count", iCount).
        joForEach:Add("elapsedMs", iForEachMs).

        joPreselect:Add("openQueryElapsedMs", iOpenMs).
        joPreselect:Add("numResults", iNumResults).
        joPreselect:Add("numResultsElapsedMs", iNumResultsMs).

        joRet:Add("success", TRUE).
        joRet:Add("runtime", "PASOE-WEB").
        joRet:Add("forEachNoLock", joForEach).
        joRet:Add("preselectNumResults", joPreselect).

        RETURN joRet.
    END METHOD.

    METHOD PRIVATE CHARACTER getJobIdFromPath(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE cPath AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iJobs AS INTEGER NO-UNDO.
        DEFINE VARIABLE iResult AS INTEGER NO-UNDO.

        ASSIGN cPath = REPLACE(pcPath, "~\", "/").
        ASSIGN iJobs = INDEX(cPath, "/jobs/").
        IF iJobs = 0 THEN
            RETURN "".

        ASSIGN cPath = SUBSTRING(cPath, iJobs + 6).
        ASSIGN iResult = INDEX(cPath, "/result").
        IF iResult > 0 THEN
            ASSIGN cPath = SUBSTRING(cPath, 1, iResult - 1).

        RETURN cPath.
    END METHOD.

    METHOD PRIVATE VOID writeJson(INPUT poJson AS JsonObject):
        DEFINE VARIABLE lcJson AS LONGCHAR NO-UNDO.
        DEFINE VARIABLE oResponse AS WebResponse NO-UNDO.
        DEFINE VARIABLE oWriter AS WebResponseWriter NO-UNDO.

        IF NOT VALID-OBJECT(poJson) THEN
            ASSIGN poJson = THIS-OBJECT:buildError("NO_RESPONSE", "Resposta nao gerada", "").

        poJson:Write(lcJson, TRUE).

        ASSIGN oResponse = NEW WebResponse()
               oWriter = NEW WebResponseWriter(oResponse).

        oResponse:SetHeader("Content-Type":U, "application/json; charset=utf-8":U).
        oResponse:SetHeader("Cache-Control":U, "no-store":U).

        oWriter:Open().
        oWriter:Write(lcJson).
        oWriter:Flush().
        oWriter:Close().

        DELETE OBJECT oWriter NO-ERROR.
        DELETE OBJECT oResponse NO-ERROR.
    END METHOD.

    METHOD PRIVATE JsonObject buildError(INPUT pcCode AS CHARACTER, INPUT pcMessage AS CHARACTER, INPUT pcDetails AS CHARACTER):
        DEFINE VARIABLE joRet AS JsonObject NO-UNDO.
        DEFINE VARIABLE joErr AS JsonObject NO-UNDO.

        ASSIGN joRet = NEW JsonObject()
               joErr = NEW JsonObject().
        joErr:Add("code", pcCode).
        joErr:Add("message", pcMessage).
        joErr:Add("details", pcDetails).
        joRet:Add("success", FALSE).
        joRet:Add("error", joErr).
        RETURN joRet.
    END METHOD.

END CLASS.
