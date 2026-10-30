BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttProc NO-UNDO FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD fornecedor_id AS INTEGER FIELD cod_proc_fornec AS CHARACTER FIELD dt_registro AS DATE FIELD cod_situacao AS INTEGER INDEX pk IS UNIQUE PRIMARY proc_compra_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE rowData AS JsonObject NO-UNDO. DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE keyText AS CHARACTER NO-UNDO.
OUTPUT TO VALUE('purchase-parent-tests-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 CREATE ttProc. ASSIGN ttProc.proc_compra_id=101 ttProc.empresa_id=2 ttProc.fornecedor_id=11 ttProc.cod_proc_fornec='TEST_MED' ttProc.dt_registro=DATE(10,22,2026).
 CREATE ttProc. ASSIGN ttProc.proc_compra_id=102 ttProc.empresa_id=1 ttProc.fornecedor_id=22 ttProc.cod_proc_fornec='OTHER'.
 req=NEW JsonObject(). req:Add('operation','read'). req:Add('take',1). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'parent MED scope'). rowData=res:GetJsonArray('data'):GetJsonObject(1).
 RUN Check(rowData:GetInteger('proc_compra_id')=101 AND rowData:GetInteger('empresa_id')=2,'parent integer PK and company'). keyText=rowData:GetCharacter('record_key').
 req=NEW JsonObject(). req:Add('operation','get'). req:Add('id',keyText). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('proc_compra_id')=101,'parent composite encoded get').
 req=NEW JsonObject(). req:Add('operation','read'). rowData=NEW JsonObject(). rowData:Add('field','fornecedor_id'). rowData:Add('operator','eq'). rowData:Add('value',22). req:Add('filter',rowData). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=0,'filter cannot expand fixed company').
 req=NEW JsonObject(). req:Add('operation','delete'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'parent readonly').
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. OUTPUT CLOSE. UNDO, THROW e. END CATCH.
END. OUTPUT CLOSE.
PROCEDURE Invoke: RUN CiwErpReadService.p(INPUT BUFFER ttProc:HANDLE,'processos_compra_med','2',req,OUTPUT res). END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.
