USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE router AS JsonProgramRouter NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE reply AS JsonObject NO-UNDO.
DEFINE VARIABLE responseText AS LONGCHAR NO-UNDO.
DEFINE VARIABLE requestText AS LONGCHAR NO-UNDO.
DEFINE VARIABLE routes AS LONGCHAR NO-UNDO.
DEFINE VARIABLE marker AS CHARACTER NO-UNDO INITIAL "temp/json-router-invoked.txt".
DEFINE STREAM results.
FIX-CODEPAGE(responseText) = "UTF-8".
FIX-CODEPAGE(requestText) = "UTF-8".
FIX-CODEPAGE(routes) = "UTF-8".
OUTPUT STREAM results TO "temp/json-router-test.txt".
OS-CREATE-DIR "temp/json-router-fixture".
OS-CREATE-DIR "temp/json-router-fixture/sursum-api".
OS-CREATE-DIR "temp/json-router-fixture/sursum-api/programs".
OS-COPY "tests/abl/fixtures/JsonProgramMarker.p" "temp/json-router-fixture/sursum-api/programs/Marker.p".
OS-COPY "tests/abl/fixtures/JsonProgramFailure.p" "temp/json-router-fixture/sursum-api/programs/Failure.p".
OS-COPY "tests/abl/fixtures/JsonProgramEmpty.p" "temp/json-router-fixture/sursum-api/programs/Empty.p".
PROPATH = "temp/json-router-fixture," + PROPATH.
COMPILE "temp/json-router-fixture/sursum-api/programs/Marker.p" SAVE NO-ERROR.
RUN check(NOT COMPILER:ERROR, "compiled fixture is available").
routes = '~{"routes":[~{"route":"/SursumPrograms/echo","method":"POST","program":"sursum-api/programs/Marker.p"},~{"route":"/SursumPrograms/echo","method":"GET","program":"sursum-api/programs/Marker.p"},~{"route":"/SursumPrograms/write","method":"PUT","program":"sursum-api/programs/Marker.p"},~{"route":"/SursumPrograms/write","method":"PATCH","program":"sursum-api/programs/Marker.p"},~{"route":"/SursumPrograms/write","method":"DELETE","program":"sursum-api/programs/Marker.p"}]}'.
COPY-LOB FROM routes TO FILE "temp/json-router-routes.json".
ASSIGN router = NEW JsonProgramRouter("temp/json-router-routes.json") parser = NEW ObjectModelParser().
requestText = '~{"pedido":123,"ativo":true,"program":"ordinary-data","parameters":~{"id":7},"items":[1,2]}'.
responseText = router:dispatch("POST", "/SursumPrograms/echo", "ignored=query", requestText).
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(router:StatusCode = 200 AND reply:GetInteger("pedido") = 123, "route executes configured program with entire body").
RUN check(reply:GetCharacter("program") = "ordinary-data" AND reply:GetJsonObject("parameters"):GetInteger("id") = 7, "program and parameters are ordinary business fields").
RUN check(reply:GetLogical("ativo") AND reply:GetJsonArray("items"):Length = 2, "JSON types and arrays preserved").
DELETE OBJECT reply.
OS-DELETE VALUE(marker).
responseText = router:dispatch("DELETE", "/SursumPrograms/echo", "", "invalid-json").
FILE-INFO:FILE-NAME = marker.
RUN check(router:StatusCode = 405 AND FILE-INFO:FULL-PATHNAME = ?, "method denied before parsing or running").
RUN check(LOOKUP("POST",router:AllowMethods) > 0 AND LOOKUP("GET",router:AllowMethods) > 0, "405 lists methods for route").
responseText = router:dispatch("POST", "/SursumPrograms/unknown", "", requestText).
RUN check(router:StatusCode = 404, "unknown route").
responseText = router:dispatch("POST", "/sursumprograms/echo", "", requestText).
RUN check(router:StatusCode = 404, "route is case sensitive").
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", "[]").
RUN check(router:StatusCode = 400, "body must be a JSON object").
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", "invalid-json").
RUN check(router:StatusCode = 400, "malformed JSON rejected").
responseText = router:dispatch("OPTIONS", "/SursumPrograms/echo", "", "").
FILE-INFO:FILE-NAME = marker.
RUN check(router:StatusCode = 204 AND FILE-INFO:FULL-PATHNAME = ?, "OPTIONS never executes program").
responseText = router:dispatch("GET", "/SursumPrograms/echo", "pedido=00123&texto=a%26b%3Dc%2B+d&tag=x&tag=y", "").
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(reply:GetCharacter("pedido") = "00123" AND reply:GetCharacter("texto") = "a&b=c+ d", "GET decodes query string and preserves strings").
RUN check(reply:GetJsonArray("tag"):GetCharacter(2) = "y", "repeated query keys form an array").
DELETE OBJECT reply.
responseText = router:dispatch("PUT", "/SursumPrograms/write", "", requestText).
RUN check(router:StatusCode = 200, "PUT body accepted").
responseText = router:dispatch("PATCH", "/SursumPrograms/write", "", requestText).
RUN check(router:StatusCode = 200, "PATCH body accepted").
responseText = router:dispatch("DELETE", "/SursumPrograms/write", "", requestText).
RUN check(router:StatusCode = 200, "DELETE body accepted").
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", "").
RUN check(router:StatusCode = 200 AND responseText <> "", "empty body supplies empty object").
requestText = '~{"texto":"a\u00e7\u00e3o","success":false}'.
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", requestText).
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(reply:GetCharacter("texto") = "a" + CHR(231, SESSION:CPINTERNAL, "ISO8859-1") + CHR(227, SESSION:CPINTERNAL, "ISO8859-1") + "o" AND NOT reply:GetLogical("success") AND router:StatusCode = 200, "UTF-8 body and business response unchanged").
DELETE OBJECT reply.
responseText = router:dispatch("GET", "/SursumPrograms/echo", "texto=a%C3%A7%C3%A3o", "").
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(reply:GetCharacter("texto") = "a" + CHR(231, SESSION:CPINTERNAL, "ISO8859-1") + CHR(227, SESSION:CPINTERNAL, "ISO8859-1") + "o", "GET UTF-8 decoded once").
DELETE OBJECT reply.
responseText = router:dispatch("GET", "/SursumPrograms/echo", "=value", "").
RUN check(router:StatusCode = 400, "empty query key rejected").
responseText = router:dispatch("GET", "/SursumPrograms/echo", "texto=%2526%252B%253D&flag&vazio=", "").
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(reply:GetCharacter("texto") = "%26%2B%3D" AND reply:GetCharacter("flag") = "" AND reply:GetCharacter("vazio") = "", "decode once and preserve empty query values").
DELETE OBJECT reply.
IF SESSION:CPINTERNAL = "UTF-8" THEN DO:
    responseText = router:dispatch("GET", "/SursumPrograms/echo", "texto=%E2%82%AC%F0%9F%98%80", "").
    reply = CAST(parser:Parse(responseText), JsonObject).
    requestText = '~{"texto":"\u20ac\ud83d\ude00"}'.
    DEFINE VARIABLE unicodeReply AS JsonObject NO-UNDO.
    unicodeReply = CAST(parser:Parse(requestText), JsonObject).
    RUN check(reply:GetCharacter("texto") = unicodeReply:GetCharacter("texto"), "UTF-8 euro and supplementary character preserved").
    DELETE OBJECT unicodeReply.
    DELETE OBJECT reply.
END.
RUN badQuery("texto=%", "truncated percent rejected").
RUN badQuery("texto=%A", "single hex digit rejected").
RUN badQuery("texto=%GG", "non-hex percent rejected").
RUN badQuery("texto=%C3", "truncated UTF-8 rejected").
RUN badQuery("texto=%C0%AF", "overlong UTF-8 rejected").
RUN badQuery("texto=%ED%A0%80", "UTF-8 surrogate rejected").
RUN badQuery("texto=%F4%90%80%80", "UTF-8 above Unicode maximum rejected").
RUN badQuery("texto=%80", "UTF-8 lone continuation rejected").
RUN badQuery("texto=%00", "NUL rejected without truncation").
OS-COPY "tests/abl/fixtures/JsonProgramFailure.p" "temp/json-router-fixture/sursum-api/programs/Marker.p".
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", requestText).
RUN check(router:StatusCode = 200, "compiled r preferred over source p").
OS-DELETE "temp/json-router-fixture/sursum-api/programs/Marker.p".
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", requestText).
RUN check(router:StatusCode = 200, "compiled-only deployment supported").
/* Re-read the catalog each time; invalid edits must not reuse a previous route. */
routes = '~{"routes":[~{"route":"/SursumPrograms/echo","method":"POST","program":"../unsafe.p"}]}'.
COPY-LOB FROM routes TO FILE "temp/json-router-routes.json".
OS-DELETE VALUE(marker).
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", requestText).
FILE-INFO:FILE-NAME = marker.
RUN check(router:StatusCode = 500 AND FILE-INFO:FULL-PATHNAME = ?, "invalid catalog fails closed without stale routes").
RUN badCatalog('not-json', "malformed catalog").
RUN badCatalog('~{"routes":null}', "null routes").
RUN badCatalog('~{"routes":[~{"route":"/SursumPrograms/echo","method":"POST"}]}', "missing program").
RUN badCatalog('~{"routes":[~{"route":"/SursumPrograms/echo","method":"GET,POST","program":"sursum-api/programs/Marker.p"}]}', "method must be a single verb").
RUN badCatalog('~{"routes":[~{"route":"/SursumPrograms/echo","method":"TRACE","program":"sursum-api/programs/Marker.p"}]}', "unsupported catalog method").
RUN badCatalog('~{"routes":[~{"route":"/SursumPrograms/echo","method":"POST","program":"sursum-api/programs/Marker.p"},~{"route":"/SursumPrograms/echo","method":"post","program":"sursum-api/programs/Marker.p"}]}', "duplicate route and method").
routes = '~{"routes":[~{"route":"/missing","method":"POST","program":"sursum-api/programs/DoesNotExist.p"},~{"route":"/failure","method":"POST","program":"sursum-api/programs/Failure.p"},~{"route":"/empty","method":"POST","program":"sursum-api/programs/Empty.p"}]}'.
COPY-LOB FROM routes TO FILE "temp/json-router-routes.json".
responseText = router:dispatch("POST", "/missing", "", requestText).
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(router:StatusCode = 500 AND reply:GetJsonObject("error"):GetCharacter("code") = "PROGRAM_NOT_FOUND", "missing program is reported").
DELETE OBJECT reply.
responseText = router:dispatch("POST", "/failure", "", requestText).
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(router:StatusCode = 500 AND reply:GetJsonObject("error"):GetCharacter("code") = "PROGRAM_EXECUTION_ERROR", "program error is reported").
DELETE OBJECT reply.
responseText = router:dispatch("POST", "/empty", "", requestText).
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(router:StatusCode = 500 AND reply:GetJsonObject("error"):GetCharacter("code") = "PROGRAM_EMPTY_RESPONSE", "missing output object is reported").
DELETE OBJECT reply.
/* A second allowed root is relative to the ERP root in PROPATH. */
OS-CREATE-DIR "temp/json-router-fixture/especificos".
OS-CREATE-DIR "temp/json-router-fixture/especificos/ems2".
OS-CREATE-DIR "temp/json-router-fixture/especificos/ems2/ima".
OS-CREATE-DIR "temp/json-router-fixture/especificos/ems2/ima/http-api".
OS-COPY "tests/abl/fixtures/JsonProgramMarker.p" "temp/json-router-fixture/especificos/ems2/ima/http-api/Marker.p".
COMPILE "temp/json-router-fixture/especificos/ems2/ima/http-api/Marker.p" SAVE NO-ERROR.
RUN check(NOT COMPILER:ERROR, "external root fixture compiled").
OS-DELETE "temp/json-router-fixture/especificos/ems2/ima/http-api/Marker.p".
routes = '~{"routes":[~{"route":"/SursumPrograms/external","method":"POST","program":"especificos/ems2/ima/http-api/Marker.p"}]}'.
COPY-LOB FROM routes TO FILE "temp/json-router-routes.json".
OS-DELETE VALUE(marker).
responseText = router:dispatch("POST", "/SursumPrograms/external", "", '~{"pedido":456}').
FILE-INFO:FILE-NAME = marker.
RUN check(router:StatusCode = 200 AND FILE-INFO:FULL-PATHNAME <> ?, "external http-api compiled program executed").
reply = CAST(parser:Parse(responseText), JsonObject).
RUN check(reply:GetInteger("pedido") = 456, "external http-api receives full JSON").
DELETE OBJECT reply.
RUN badCatalog('~{"routes":[~{"route":"/SursumPrograms/echo","method":"POST","program":"especificos/ems2/ima/http-api-other/Marker.p"}]}', "sibling of allowed http-api root rejected").
RUN badCatalog('~{"routes":[~{"route":"/SursumPrograms/echo","method":"POST","program":"especificos/ems2/ima/http-api/../Marker.p"}]}', "traversal from http-api root rejected").
DELETE OBJECT router.
router = NEW JsonProgramRouter("temp/no-such-route-catalog.json").
responseText = router:dispatch("POST", "/SursumPrograms/echo", "", requestText).
RUN check(router:StatusCode = 500, "missing catalog is a server error").
PUT STREAM results UNFORMATTED "PASS: all JSON route cases" SKIP.
OUTPUT STREAM results CLOSE.
QUIT.
PROCEDURE check:
 DEFINE INPUT PARAMETER plOk AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
 IF plOk <> TRUE OR plOk = ? THEN DO:
   PUT STREAM results UNFORMATTED "FAIL: " pcLabel SKIP.
   OUTPUT STREAM results CLOSE.
   QUIT.
 END.
 PUT STREAM results UNFORMATTED "PASS: " pcLabel SKIP.
END PROCEDURE.

PROCEDURE badCatalog:
 DEFINE INPUT PARAMETER pcJson AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
 routes = pcJson.
 COPY-LOB FROM routes TO FILE "temp/json-router-routes.json".
 OS-DELETE VALUE(marker).
 responseText = router:dispatch("POST", "/SursumPrograms/echo", "", requestText).
 FILE-INFO:FILE-NAME = marker.
 RUN check(router:StatusCode = 500 AND FILE-INFO:FULL-PATHNAME = ?, pcLabel).
END PROCEDURE.

PROCEDURE badQuery:
 DEFINE INPUT PARAMETER pcQuery AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
 OS-DELETE VALUE(marker).
 responseText = router:dispatch("GET", "/SursumPrograms/echo", pcQuery, "").
 FILE-INFO:FILE-NAME = marker.
 RUN check(router:StatusCode = 400 AND FILE-INFO:FULL-PATHNAME = ?, pcLabel).
END PROCEDURE.
