BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttOrders NO-UNDO FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD cod_situacao AS INTEGER FIELD dt_registro AS DATE FIELD cod_proc_fornec AS CHARACTER FIELD fornecedor_id AS INTEGER INDEX pk IS UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies NO-UNDO FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER INDEX pk IS UNIQUE empresa_id.
DEFINE TEMP-TABLE ttItems NO-UNDO FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD descricao AS CHARACTER FIELD codigo_erp AS CHARACTER FIELD dt_real_envio_desenhos AS DATE FIELD dt_real_recbto_so_ld AS DATE FIELD dt_real_aprov_so_ld AS DATE FIELD dt_termino_producao AS DATE FIELD dt_prev_termino_producao AS DATE FIELD log_aprov_so_ld AS LOGICAL INDEX pk IS UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttPayments NO-UNDO FIELD proc_compra_id AS INTEGER FIELD num_id_tit_ap AS INTEGER.
DEFINE TEMP-TABLE ttSignals NO-UNDO FIELD sinaliz_imp_id AS INTEGER FIELD nome AS CHARACTER FIELD titulo AS CHARACTER FIELD descricao AS CHARACTER FIELD qt_dias_alerta AS INTEGER INDEX pk IS UNIQUE sinaliz_imp_id.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER checkedValue AS LOGICAL NO-UNDO.
 IF checkedValue<>TRUE OR checkedValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Collector assertion failed',1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE CallService:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expectedStatus AS INTEGER NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 RUN VALUE(servicePath)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPayments:HANDLE,INPUT BUFFER ttSignals:HANDLE,DATE(10,27,2026),requestValue,OUTPUT resultValue).
 IF expectedStatus=200 THEN RUN Check(resultValue:GetLogical('success')).
 ELSE DO:
  RUN Check(NOT resultValue:GetLogical('success')).
  RUN Check(resultValue:GetJsonObject('error'):GetInteger('status')=expectedStatus).
 END.
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER. SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO VALUE('signals-service-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('No operational database allowed',1).
 servicePath=SEARCH('sursum-api/programs/PurchaseSignalsService.r').
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('RED missing PurchaseSignalsService',1).
 parser=NEW ObjectModelParser().
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=9 ttCompanies.cod_emp_ems5=900.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2 ttOrders.cod_situacao=1 ttOrders.dt_registro=DATE(10,1,2026) ttOrders.cod_proc_fornec='T10' ttOrders.fornecedor_id=99.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=11 ttOrders.empresa_id=3 ttOrders.cod_situacao=1.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=12 ttOrders.empresa_id=2 ttOrders.cod_situacao=2.
 CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=20 ttItems.proc_compra_id=10 ttItems.descricao='Item20' ttItems.codigo_erp='20' ttItems.log_aprov_so_ld=TRUE ttItems.dt_real_envio_desenhos=DATE(10,17,2026).
 CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=21 ttItems.proc_compra_id=10 ttItems.descricao='Item21' ttItems.codigo_erp='21' ttItems.log_aprov_so_ld=TRUE ttItems.dt_real_recbto_so_ld=DATE(10,25,2026) ttItems.dt_prev_termino_producao=DATE(11,3,2026).
 DO k=1 TO 4:
  CREATE ttSignals. ASSIGN ttSignals.sinaliz_imp_id=k ttSignals.nome='rule' + STRING(k) ttSignals.titulo='Title' + STRING(k) ttSignals.descricao='Description' ttSignals.qt_dias_alerta=IF k=1 THEN 10 ELSE IF k=2 THEN 2 ELSE 7.
 END.
 RUN CallService('~{"operation":"read","proc_compra_id":10~}',200).
 RUN Check(resultValue:GetInteger('total')=4).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(1). keyValue=rowValue:GetCharacter('record_key').
 RUN Check(rowValue:GetInteger('proc_compra_id')=10).
 requestValue=NEW JsonObject(). requestValue:Add('operation','get'). requestValue:Add('proc_compra_id',10). requestValue:Add('id',keyValue). requestValue:Add('record_key',keyValue).
 RUN VALUE(servicePath)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPayments:HANDLE,INPUT BUFFER ttSignals:HANDLE,DATE(10,27,2026),requestValue,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical('success')). RUN Check(resultValue:GetJsonObject('data'):GetCharacter('record_key')=keyValue).
 RUN CallService('~{"operation":"read","proc_compra_id":10,"take":2,"skip":1~}',200). RUN Check(resultValue:GetInteger('total')=4 AND resultValue:GetJsonArray('data'):Length=2).
 RUN CallService('~{"operation":"read","proc_compra_id":10,"filter":~{"field":"sinaliz_imp_id","operator":"eq","value":3~}~}',200). RUN Check(resultValue:GetInteger('total')=1).
 RUN CallService('~{"operation":"read","proc_compra_id":11~}',404).
 RUN CallService('~{"operation":"read","proc_compra_id":12~}',200). RUN Check(resultValue:GetInteger('total')=0).
 RUN CallService('~{"operation":"update","proc_compra_id":10~}',405).
 RUN CallService('~{"operation":"read","proc_compra_id":10,"sql":"FOR EACH other"~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":10,"today":"2000-01-01"~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":0~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":10,"take":201~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":10,"filter":~{"field":"other","operator":"eq","value":1~}~}',422).
 CREATE ttPayments. ASSIGN ttPayments.proc_compra_id=10 ttPayments.num_id_tit_ap=0.
 RUN CallService('~{"operation":"read","proc_compra_id":10~}',200). RUN Check(resultValue:GetInteger('total')=3). DELETE ttPayments.
 FIND ttSignals WHERE ttSignals.sinaliz_imp_id=3. ttSignals.qt_dias_alerta=?.
 RUN CallService('~{"operation":"read","proc_compra_id":10~}',503). ttSignals.qt_dias_alerta=7.
 DELETE ttSignals. RUN CallService('~{"operation":"read","proc_compra_id":10~}',503).
 RUN Check(CAN-FIND(FIRST ttItems WHERE ttItems.item_proc_compra_id=20 AND ttItems.dt_real_envio_desenhos=DATE(10,17,2026))).
 RUN Check(NUM-DBS=0). RUN Check(SESSION:NUMERIC-FORMAT=culture).
 PUT UNFORMATTED 'PASS signals service checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
