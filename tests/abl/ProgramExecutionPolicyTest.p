USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE catalog AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS ProgramExecutionPolicy NO-UNDO.
DEFINE VARIABLE sourceJson AS LONGCHAR NO-UNDO.
FIX-CODEPAGE(sourceJson) = "UTF-8".
ASSIGN parser = NEW ObjectModelParser()
       sourceJson = '~{"legacy":"legacy.p","getOnly":~{"path":"read.p","methods":["GET"]},"write":~{"path":"write.p","methods":["post","PUT","PATCH","DELETE"]},"invalid":~{"path":"bad.p","methods":["GET","TRACE"]},"empty":~{"path":"bad.p","methods":[]},"missing":~{"path":"bad.p"},"wrongType":~{"path":"bad.p","methods":"GET"},"combined":~{"path":"bad.p","methods":["GET,POST"]}}'
       catalog = CAST(parser:Parse(sourceJson), JsonObject).
OUTPUT TO "temp/program-policy-test.txt".
policy = NEW ProgramExecutionPolicy(catalog, "legacy").
RUN check(policy:IsValid AND policy:ProgramPath = "legacy.p" AND policy:AllowedMethods = "POST", "legacy POST default").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "getOnly").
RUN check(policy:IsValid AND policy:AllowedMethods = "GET", "GET only, POST blocked").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "write").
RUN check(policy:IsValid AND policy:AllowedMethods = "POST,PUT,PATCH,DELETE", "write methods normalized").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "invalid").
RUN check(NOT policy:IsValid AND policy:AllowedMethods = "", "invalid list fails closed").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "empty").
RUN check(NOT policy:IsValid, "empty methods denied").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "missing").
RUN check(NOT policy:IsValid, "missing methods denied").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "wrongType").
RUN check(NOT policy:IsValid, "non-array methods denied").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "combined").
RUN check(NOT policy:IsValid, "one method per entry required").
DELETE OBJECT policy.
policy = NEW ProgramExecutionPolicy(catalog, "unknown").
RUN check(NOT policy:IsConfigured AND NOT policy:IsValid, "unknown program denied").
DELETE OBJECT policy.
PUT UNFORMATTED "PASS: all program policy cases" SKIP.
OUTPUT CLOSE.
QUIT.
PROCEDURE check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
 IF ok <> TRUE OR ok = ? THEN DO:
   PUT UNFORMATTED "FAIL: " pcLabel SKIP.
   OUTPUT CLOSE.
   QUIT.
 END.
 PUT UNFORMATTED "PASS: " pcLabel SKIP.
END PROCEDURE.
