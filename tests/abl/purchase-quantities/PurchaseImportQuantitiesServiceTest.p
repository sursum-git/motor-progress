BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttOrders NO-UNDO FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD cod_situacao AS INTEGER FIELD dt_registro AS DATE FIELD cod_proc_fornec AS CHARACTER INDEX pk IS UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies NO-UNDO FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER INDEX pk IS UNIQUE empresa_id.
DEFINE TEMP-TABLE ttItems NO-UNDO FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD descricao AS CHARACTER FIELD codigo_erp AS CHARACTER FIELD qt_comprada AS DECIMAL FIELD vl_negociado AS DECIMAL INDEX pk IS UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttAllocations NO-UNDO FIELD item_container_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD container_id AS INTEGER FIELD qt_confirm_emb AS DECIMAL FIELD qt_recbto_fisico AS DECIMAL INDEX pk IS UNIQUE item_container_id.
DEFINE TEMP-TABLE ttContainers NO-UNDO FIELD nr-container AS INTEGER FIELD situacao_container_id AS INTEGER FIELD dt-recebimento AS DATE FIELD dt-prev-chegada AS DATE INDEX pk IS UNIQUE nr-container.
DEFINE TEMP-TABLE ttSituations NO-UNDO FIELD situacao_container_id AS INTEGER FIELD descricao AS CHARACTER INDEX pk IS UNIQUE situacao_container_id.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO. DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO. DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO. DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER checkedValue AS LOGICAL NO-UNDO.
 IF checkedValue<>TRUE OR checkedValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('Quantity collector assertion failed',1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE CallService:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER expectedStatus AS INTEGER NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 RUN VALUE(pathValue)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttAllocations:HANDLE,INPUT BUFFER ttContainers:HANDLE,INPUT BUFFER ttSituations:HANDLE,requestValue,OUTPUT resultValue).
 IF expectedStatus=200 THEN RUN Check(resultValue:GetLogical('success')).
 ELSE DO: RUN Check(NOT resultValue:GetLogical('success')). RUN Check(resultValue:GetJsonObject('error'):GetInteger('status')=expectedStatus). END.
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER. SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO VALUE('quantities-service-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO,THROW NEW Progress.Lang.AppError('No operational DB allowed',1).
 pathValue=SEARCH('sursum-api/programs/PurchaseImportQuantitiesService.r').
 IF pathValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('RED missing quantity collector',1).
 parser=NEW ObjectModelParser().
 CREATE ttSituations. ASSIGN ttSituations.situacao_container_id=3 ttSituations.descricao='Recebido'.
 CREATE ttSituations. ASSIGN ttSituations.situacao_container_id=100 ttSituations.descricao='Nao Alocado'.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=9 ttCompanies.cod_emp_ems5=900.
 DO k=10 TO 14:
  CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=k ttOrders.empresa_id=IF k=11 THEN 3 ELSE 2 ttOrders.cod_situacao=IF k=12 THEN 2 ELSE IF k=13 THEN 3 ELSE IF k=14 THEN ? ELSE 1 ttOrders.dt_registro=DATE(10,1,2026) ttOrders.cod_proc_fornec='T' + STRING(k).
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=k + 10 ttItems.proc_compra_id=k ttItems.descricao='Item' + STRING(k + 10) ttItems.codigo_erp=STRING(k + 10) ttItems.qt_comprada=IF k=10 THEN 10 ELSE 1 ttItems.vl_negociado=IF k=10 THEN 2 ELSE 4.
 END.
 CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=25 ttItems.proc_compra_id=10 ttItems.descricao='Unallocated' ttItems.qt_comprada=5 ttItems.vl_negociado=3.
 CREATE ttContainers. ASSIGN ttContainers.nr-container=100 ttContainers.situacao_container_id=3 ttContainers.dt-recebimento=DATE(10,20,2026) ttContainers.dt-prev-chegada=DATE(10,18,2026).
 CREATE ttAllocations. ASSIGN ttAllocations.item_container_id=30 ttAllocations.item_proc_compra_id=20 ttAllocations.container_id=100 ttAllocations.qt_confirm_emb=20 ttAllocations.qt_recbto_fisico=15.
 CREATE ttAllocations. ASSIGN ttAllocations.item_container_id=31 ttAllocations.item_proc_compra_id=20 ttAllocations.container_id=999 ttAllocations.qt_confirm_emb=8 ttAllocations.qt_recbto_fisico=0.
 RUN CallService('~{"operation":"read"~}',200). RUN Check(resultValue:GetInteger('total')=4).
 RUN CallService('~{"operation":"read","proc_compra_id":10~}',200). RUN Check(resultValue:GetInteger('total')=3).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(1). keyValue=rowValue:GetCharacter('record_key').
 RUN Check(rowValue:GetInteger('item_container_id')=30 AND rowValue:GetDecimal('qt_comprada_final')=15 AND rowValue:GetDecimal('vl_comprada_final')=30 AND rowValue:GetCharacter('desc_situacao_container')='Recebido').
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(2). RUN Check(rowValue:GetInteger('item_container_id')=31 AND rowValue:GetCharacter('nr_container')='Nao Alocado' AND rowValue:GetInteger('situacao_container')=100 AND rowValue:GetDecimal('qt_rec_final')=8).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(3). RUN Check(rowValue:GetInteger('item_container_id')=0 AND rowValue:GetDecimal('qt_rec_final')=0 AND rowValue:GetDecimal('vl_comprada_final')=15).
 requestValue=NEW JsonObject(). requestValue:Add('operation','get'). requestValue:Add('proc_compra_id',10). requestValue:Add('id',keyValue). requestValue:Add('record_key',keyValue).
 RUN VALUE(pathValue)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttAllocations:HANDLE,INPUT BUFFER ttContainers:HANDLE,INPUT BUFFER ttSituations:HANDLE,requestValue,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical('success')). RUN Check(resultValue:GetJsonObject('data'):GetCharacter('record_key')=keyValue).
 requestValue:Set('proc_compra_id',12).
 RUN VALUE(pathValue)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttAllocations:HANDLE,INPUT BUFFER ttContainers:HANDLE,INPUT BUFFER ttSituations:HANDLE,requestValue,OUTPUT resultValue).
 RUN Check(NOT resultValue:GetLogical('success') AND resultValue:GetJsonObject('error'):GetInteger('status')=404).
 RUN CallService('~{"operation":"read","proc_compra_id":12~}',200). RUN Check(resultValue:GetInteger('total')=1).
 RUN CallService('~{"operation":"read","proc_compra_id":13~}',200). RUN Check(resultValue:GetInteger('total')=0).
 RUN CallService('~{"operation":"read","proc_compra_id":14~}',200). RUN Check(resultValue:GetInteger('total')=0).
 RUN CallService('~{"operation":"read","proc_compra_id":11~}',404).
 RUN CallService('~{"operation":"read","proc_compra_id":2147483647~}',404).
 RUN CallService('~{"operation":"read","proc_compra_id":0~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":1.5~}',422).
 RUN CallService('~{"operation":"read","take":1,"skip":1~}',200). RUN Check(resultValue:GetInteger('total')=4 AND resultValue:GetJsonArray('data'):Length=1).
 RUN CallService('~{"operation":"read","filter":~{"field":"item_container_id","operator":"eq","value":31~}~}',200). RUN Check(resultValue:GetInteger('total')=1).
 RUN CallService('~{"operation":"read","take":201~}',422).
 RUN CallService('~{"operation":"read","sql":"FOR EACH other"~}',422).
 RUN CallService('~{"operation":"read","empresa_id":3~}',422).
 RUN CallService('~{"operation":"read","filter":~{"field":"other","operator":"eq","value":1~}~}',422).
 RUN CallService('~{"operation":"delete"~}',405).
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=4 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=501.
 RUN CallService('~{"operation":"read"~}',503). DELETE ttCompanies.
 RUN Check(CAN-FIND(FIRST ttAllocations WHERE ttAllocations.item_container_id=30 AND ttAllocations.qt_confirm_emb=20 AND ttAllocations.qt_recbto_fisico=15)).
 RUN Check(CAN-FIND(FIRST ttItems WHERE ttItems.item_proc_compra_id=20 AND ttItems.qt_comprada=10 AND ttItems.vl_negociado=2)).
 RUN Check(NUM-DBS=0). RUN Check(SESSION:NUMERIC-FORMAT=culture).
 PUT UNFORMATTED 'PASS quantities service checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END. OUTPUT CLOSE. QUIT.
