/*
Exemplo: exporta registros da tabela Customer para um arquivo JSON.

Execucao:
  _progres.exe -b -db D:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB -p D:\opencode\motor-progress\temp\ExportCustomerJson.p
*/

USING Progress.Json.ObjectModel.JsonObject.

DEFINE VARIABLE oSvc     AS DynamicMultiTableQueryService NO-UNDO.
DEFINE VARIABLE joResult AS JsonObject NO-UNDO.
DEFINE VARIABLE cOutDir  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOutFile AS CHARACTER NO-UNDO.
DEFINE VARIABLE lOk      AS LOGICAL   NO-UNDO.

ASSIGN
    PROPATH  = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress," + PROPATH
    cOutDir  = "D:\opencode\motor-progress\output"
    cOutFile = cOutDir + "\customer.json".

OS-CREATE-DIR VALUE(cOutDir) NO-ERROR.

ASSIGN oSvc = NEW DynamicMultiTableQueryService().

ASSIGN joResult = oSvc:executeSingleTable(
    "Customer",
    "CustNum,Name,Address,City,State,PostalCode,Contact,Phone",
    "DICTDB",
    1,
    100,
    "sync"
).

ASSIGN lOk = joResult:WriteFile(cOutFile, TRUE) NO-ERROR.

IF ERROR-STATUS:ERROR OR NOT lOk THEN DO:
    MESSAGE "JSON_EXPORT_ERROR=" + ERROR-STATUS:GET-MESSAGE(1).
END.
ELSE DO:
    MESSAGE "JSON_EXPORT_FILE=" + cOutFile.
    MESSAGE "JSON_EXPORT_SUCCESS=" + STRING(joResult:GetLogical("success")).
    MESSAGE "JSON_RECORDS_RETURNED=" + STRING(joResult:GetInteger("recordsReturned")).
END.

DELETE OBJECT joResult NO-ERROR.
DELETE OBJECT oSvc NO-ERROR.

QUIT.
