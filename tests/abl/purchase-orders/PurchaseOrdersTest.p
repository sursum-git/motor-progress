BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchaseOrdersFixture.i}
DEFINE VARIABLE deps AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesData AS JsonObject NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE nextId AS INTEGER NO-UNDO INITIAL 100.
DEFINE VARIABLE failLate AS LOGICAL NO-UNDO.
DEFINE VARIABLE stopLate AS LOGICAL NO-UNDO.
DEFINE VARIABLE financialCalls AS INTEGER NO-UNDO.
ASSIGN deps[1]=BUFFER ttPurchaseItems:HANDLE deps[2]=BUFFER ttDependencies:HANDLE deps[3]=BUFFER ttDependencies:HANDLE deps[4]=BUFFER ttOrderPayments:HANDLE.
OUTPUT TO VALUE('purchase-orders-tests-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Seed. RUN CreateRequest. RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'header create commits new MED row').
 res:WriteFile('purchase-order-audit-create-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 rowData=res:GetJsonObject('data'). stamp=rowData:GetCharacter('row_stamp').
 RUN Check(rowData:GetInteger('empresa_id')=2 AND rowData:GetInteger('proc_compra_id')=101 AND LENGTH(stamp)=64,'identity MED and opaque stamp').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('after'):GetCharacter('cod_proc_fornec')='Joao ' + CHR(233) AND NOT res:GetJsonObject('audit'):GetJsonObject('after'):Has('row_stamp'),'Unicode physical14 audit withoutstamp').
 RUN UpdateRequest. valuesData:Add('observacao','texto alterado'). RUN Invoke. RUN Check(res:GetLogical('success'),'update own current stamp'). res:WriteFile('purchase-order-audit-update-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Invoke. RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetInteger('status')=409,'stale before image rejected').
 FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. stamp=res:GetJsonObject('error'):GetCharacter('code').
 req=NEW JsonObject(). req:Add('operation','get'). req:Add('id',101). RUN Invoke. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN UpdateRequest. valuesData:Add('empresa_id',1). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'readonly company cannot be submitted').
 RUN UpdateRequest. valuesData:Add('dt_registro','2026-02-30'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'invalid civil date rejected').
 RUN UpdateRequest. valuesData:Add('fornecedor_id',11.5). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'fractional supplier rejected lexically').
 RUN UpdateRequest. valuesData:Add('nr_container_original','123X'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'container original only digits').
 RUN UpdateRequest. valuesData:Add('cod_proc_fornec',FILL('x',101)). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'legacy text limit100').
 RUN UpdateRequest. valuesData:Add('fornecedor_id',22). CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=101 ttOrderPayments.num_id_tit_ap=600. RUN Invoke. RUN Check(NOT res:GetLogical('success'),'supplier change blocked by any payment link'). EMPTY TEMP-TABLE ttOrderPayments.
 CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=101.
 CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=90 ttLedger.item_proc_compra_id=11 ttLedger.cod_tipo_movto=1.
 RUN UpdateRequest. valuesData:Add('fornecedor_id',22). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'supplier change blocked even manual ledger'). EMPTY TEMP-TABLE ttLedger.
 RUN DeleteRequest. RUN Invoke. RUN Check(NOT res:GetLogical('success') AND CAN-FIND(FIRST ttPurchases),'delete refuses child records'). EMPTY TEMP-TABLE ttPurchaseItems.
 CREATE ttDependencies. ASSIGN ttDependencies.dependency_id=1 ttDependencies.proc_compra_id=101.
 RUN Invoke. RUN Check(NOT res:GetLogical('success'),'delete refuses attachment expense dependency'). EMPTY TEMP-TABLE ttDependencies.
 RUN UpdateRequest. valuesData:Add('log_considerar_previsao',FALSE). failLate=TRUE. RUN Invoke.
 RUN Check(NOT res:GetLogical('success') AND NOT CAN-FIND(FIRST ttLedger),'late callback failure rolls back header and ledger').
 FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. RUN Check(ttPurchases.log_considerar_previsao,'physical flag rolled back').
 failLate=FALSE. RUN Invoke. RUN Check(res:GetLogical('success') AND financialCalls=2 AND res:GetJsonObject('audit'):GetJsonArray('changes'):Length=1,'forecast mutation delegates and audits effects').
 stamp=res:GetJsonObject('data'):GetCharacter('row_stamp'). RUN DeleteRequest. RUN Invoke. RUN Check(res:GetLogical('success') AND NOT CAN-FIND(FIRST ttPurchases),'empty header delete commits'). res:WriteFile('purchase-order-audit-delete-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Seed. RUN CreateRequest. req:GetJsonObject('values'):Add('id',999). RUN Invoke. RUN Check(NOT res:GetLogical('success') AND NOT CAN-FIND(FIRST ttPurchases),'client PK forbidden').
 RUN Seed. RUN CreateRequest. req:Add('actor','forged'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'closed root rejects browser actor').
 RUN LegacyCases.
 RUN StopCases.
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' checks ': ' e:GetMessage(1) SKIP. IF VALID-OBJECT(res) THEN res:WriteFile('writer-failure.json',TRUE). OUTPUT CLOSE. UNDO, THROW e. END CATCH.
END. OUTPUT CLOSE.
PROCEDURE Seed:
 EMPTY TEMP-TABLE ttPurchases. EMPTY TEMP-TABLE ttCompanies. EMPTY TEMP-TABLE ttSuppliers. EMPTY TEMP-TABLE ttLedger. EMPTY TEMP-TABLE ttPurchaseItems. EMPTY TEMP-TABLE ttDependencies. EMPTY TEMP-TABLE ttOrderPayments.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
 CREATE ttSuppliers. ttSuppliers.cod-emitente=11. CREATE ttSuppliers. ttSuppliers.cod-emitente=22.
 nextId=100. financialCalls=0. failLate=FALSE. policy=NEW JsonObject(). rowData=NEW JsonObject(). rowData:Add('login','real-user'). policy:Add('actor',rowData).
END PROCEDURE.
PROCEDURE CreateRequest:
 req=NEW JsonObject(). req:Add('operation','create'). valuesData=NEW JsonObject(). valuesData:Add('fornecedor_id',11). valuesData:Add('cod_proc_fornec','Joao ' + CHR(233)). req:Add('values',valuesData).
END PROCEDURE.
PROCEDURE UpdateRequest:
 req=NEW JsonObject(). req:Add('operation','update'). req:Add('id',101). req:Add('row_stamp',stamp). valuesData=NEW JsonObject(). req:Add('values',valuesData).
END PROCEDURE.
PROCEDURE DeleteRequest: req=NEW JsonObject(). req:Add('operation','delete'). req:Add('id',101). req:Add('row_stamp',stamp). END PROCEDURE.
PROCEDURE Invoke:
 RUN PurchaseOrdersService.p(INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttSuppliers:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,deps,THIS-PROCEDURE,policy,req,OUTPUT res).
END PROCEDURE.
PROCEDURE NextOrderId: DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. nextId=nextId + 1. id=nextId. END PROCEDURE.
PROCEDURE RunOrderForecast:
 DEFINE INPUT PARAMETER orderBuffer AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE changes AS JsonArray NO-UNDO. DEFINE VARIABLE e AS JsonObject NO-UNDO.
 financialCalls=financialCalls + 1. CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=200 ttLedger.item_proc_compra_id=11.
 IF stopLate THEN STOP.
 IF failLate THEN UNDO, THROW NEW Progress.Lang.AppError('late injected',1).
 result=NEW JsonObject(). result:Add('success',TRUE). changes=NEW JsonArray(). e=NEW JsonObject(). e:Add('resource','cta_corren_fornec_imp'). e:Add('operation','delete'). changes:Add(e). result:Add('changes',changes). result:Add('warnings',NEW JsonArray()).
END PROCEDURE.
PROCEDURE StopCases:
 RUN Seed. RUN CreateRequest. RUN Invoke. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN UpdateRequest. valuesData:Add('log_considerar_previsao',FALSE). stopLate=TRUE. RUN Invoke. stopLate=FALSE.
 RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetInteger('status')=503 AND NOT res:Has('committed'),'STOP callback returns503 without committed success').
 FIND ttPurchases WHERE ttPurchases.proc_compra_id=101.
 RUN Check(ttPurchases.log_considerar_previsao AND NOT CAN-FIND(FIRST ttLedger),'STOP after ledger insert rolls back header and ledger').
END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.
PROCEDURE LegacyCases:
 RUN Seed. RUN CreateRequest. RUN Invoke. RUN Check(res:GetLogical('success'),'create for preserved legacy state').
 FIND ttPurchases WHERE ttPurchases.proc_compra_id=101.
 ASSIGN ttPurchases.cod_situacao=0 ttPurchases.qt_container=7 ttPurchases.cotacao_prevista=12.34 ttPurchases.log_considerar_previsao=?.
 req=NEW JsonObject(). req:Add('operation','get'). req:Add('id',101). RUN Invoke. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp').
 RUN UpdateRequest. valuesData:Add('observacao','preserva legado'). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('cod_situacao')=0 AND res:GetJsonObject('data'):IsNull('log_considerar_previsao') AND res:GetJsonObject('data'):GetInteger('qt_container')=7 AND res:GetJsonObject('data'):GetDecimal('cotacao_prevista')=12.34,'partial update preserves legacy0 unknownflag and readonly physical values').
 stamp=res:GetJsonObject('data'):GetCharacter('row_stamp'). RUN UpdateRequest. valuesData:Add('cod_situacao',0). valuesData:AddNull('log_considerar_previsao'). RUN Invoke. RUN Check(res:GetLogical('success'),'explicit unchanged0/null can be preserved').
 stamp=res:GetJsonObject('data'):GetCharacter('row_stamp'). RUN UpdateRequest. valuesData:Add('log_considerar_previsao',TRUE). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'unknown prior flag cannot invent financial transition').
 RUN UpdateRequest. valuesData:Add('cod_situacao',1). RUN Invoke. RUN Check(res:GetLogical('success'),'legacy status0 may transition to valid1').
 stamp=res:GetJsonObject('data'):GetCharacter('row_stamp'). RUN UpdateRequest. valuesData:Add('cod_situacao',0). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'known status cannot transition to0').
 RUN Seed. RUN CreateRequest. valuesData:Add('FORNECEDOR_ID',22). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'closed JSON rejects case aliases').
 RUN Seed. CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500. RUN CreateRequest. RUN Invoke. RUN Check(NOT res:GetLogical('success') AND NOT CAN-FIND(FIRST ttPurchases),'ambiguous company cannot write').
END PROCEDURE.

