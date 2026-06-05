PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress\sursum\esp,D:\opencode\motor-progress," + PROPATH.

DEFINE VARIABLE oMeta AS DynamicMetadataService NO-UNDO.
DEFINE VARIABLE oSvc AS DynamicMultiTableQueryService NO-UNDO.
DEFINE VARIABLE joRet AS Progress.Json.ObjectModel.JsonObject NO-UNDO.
DEFINE VARIABLE iCampos AS INTEGER NO-UNDO.

{esbo/ttCampos.i}

ASSIGN oMeta = NEW DynamicMetadataService().
oMeta:carregarCampos("Customer", "CustNum,Name").
oMeta:getCampos(OUTPUT TABLE ttCampos).

FOR EACH ttCampos:
    ASSIGN iCampos = iCampos + 1.
END.

MESSAGE "OO_METADATA_FIELDS=" + STRING(iCampos).

ASSIGN oSvc = NEW DynamicMultiTableQueryService().
ASSIGN joRet = oSvc:executeSingleTable("Customer", "CustNum,Name", "DICTDB", 1, 2, "sync").
MESSAGE "OO_QUERY_SUCCESS=" + STRING(joRet:GetLogical("success")).

DELETE OBJECT oMeta.
DELETE OBJECT oSvc.
DELETE OBJECT joRet.

QUIT.
