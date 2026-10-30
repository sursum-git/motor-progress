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
DEFINE VARIABLE resourceValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE scannedOut AS INTEGER NO-UNDO.
DEFINE VARIABLE pidOut AS INTEGER NO-UNDO.
{sursum-api/includes/PurchaseSignalsTable.i}
DEFINE TEMP-TABLE ttContainers NO-UNDO FIELD nr-container AS INTEGER FIELD cod-estabel AS CHARACTER FIELD situacao AS INTEGER FIELD dt_real_embarque AS DATE FIELD dt_prev_embarque AS DATE INDEX pk IS UNIQUE nr-container.
PROCEDURE Check:
 DEFINE INPUT PARAMETER checkedValue AS LOGICAL NO-UNDO.
 IF checkedValue<>TRUE OR checkedValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Collector assertion failed',1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE CallService:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expectedStatus AS INTEGER NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 RUN VALUE(servicePath)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPayments:HANDLE,INPUT BUFFER ttSignals:HANDLE,INPUT BUFFER ttContainers:HANDLE,DATE(10,27,2026),resourceValue,requestValue,OUTPUT resultValue).
 IF expectedStatus=200 THEN RUN Check(resultValue:GetLogical('success')).
 ELSE DO:
  RUN Check(NOT resultValue:GetLogical('success')).
  RUN Check(resultValue:GetJsonObject('error'):GetInteger('status')=expectedStatus).
 END.
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER. SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO 'global-service.log'.
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('No operational database allowed',1).
 servicePath=SEARCH('sursum-api/programs/PurchaseSignalsGlobalService.r').
 parser=NEW ObjectModelParser(). resourceValue='proc_compra_sinalizadores'.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=3 ttCompanies.cod_emp_ems2=9 ttCompanies.cod_emp_ems5=900.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2 ttOrders.cod_situacao=1 ttOrders.dt_registro=DATE(10,1,2026) ttOrders.cod_proc_fornec='T10' ttOrders.fornecedor_id=99.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=11 ttOrders.empresa_id=3 ttOrders.cod_situacao=1 ttOrders.dt_registro=DATE(10,1,2026).
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=12 ttOrders.empresa_id=2 ttOrders.cod_situacao=2 ttOrders.dt_registro=DATE(10,1,2026).
 CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=20 ttItems.proc_compra_id=10 ttItems.descricao='Produção ação' ttItems.codigo_erp='20' ttItems.log_aprov_so_ld=TRUE ttItems.dt_real_envio_desenhos=DATE(10,17,2026).
 CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=21 ttItems.proc_compra_id=10 ttItems.descricao='Item21' ttItems.codigo_erp='21' ttItems.log_aprov_so_ld=TRUE ttItems.dt_real_recbto_so_ld=DATE(10,25,2026) ttItems.dt_prev_termino_producao=DATE(11,3,2026).
 DO k=1 TO 5:
  CREATE ttSignals. ASSIGN ttSignals.sinaliz_imp_id=k ttSignals.nome='rule' + STRING(k) ttSignals.titulo='Título ação' ttSignals.descricao='Description' ttSignals.qt_dias_alerta=IF k=1 THEN 10 ELSE IF k=2 THEN 2 ELSE IF k=5 THEN 5 ELSE 7.
 END.
 DO k=10 TO 15:
  CREATE ttContainers. ASSIGN ttContainers.nr-container=k ttContainers.cod-estabel='501' ttContainers.situacao=1 ttContainers.dt_prev_embarque=DATE(10,27,2026).
 END.
 FIND ttContainers WHERE nr-container=11. ttContainers.dt_prev_embarque=DATE(11,1,2026).
 FIND ttContainers WHERE nr-container=12. ttContainers.dt_prev_embarque=DATE(11,2,2026).
 FIND ttContainers WHERE nr-container=13. ttContainers.dt_prev_embarque=DATE(10,26,2026).
 FIND ttContainers WHERE nr-container=14. ttContainers.cod-estabel='101'.
 FIND ttContainers WHERE nr-container=15. ttContainers.dt_real_embarque=DATE(10,26,2026).
 RUN CallService('~{"operation":"read"~}',200). RUN Check(resultValue:GetInteger('total')=5).
 RUN Check(resultValue:GetJsonArray('data'):GetJsonObject(5):GetInteger('quantidade')=2).
 RUN Check(resultValue:GetJsonArray('data'):GetJsonObject(1):GetCharacter('titulo_configurado')='Título ação').
 resourceValue='proc_compra_sinalizados'.
 RUN CallService('~{"operation":"read"~}',422).
 RUN CallService('~{"operation":"read","sinaliz_imp_id":1~}',200). RUN Check(resultValue:GetInteger('total')=1).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(1). keyValue=rowValue:GetCharacter('record_key').
 RUN Check(rowValue:IsNull('link_container_id')). RUN Check(rowValue:GetInteger('link_proc_compra_id')=10).
 requestValue=NEW JsonObject(). requestValue:Add('operation','get'). requestValue:Add('id',keyValue). requestValue:Add('record_key',keyValue). requestValue:Add('sinaliz_imp_id',1).
 RUN VALUE(servicePath)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPayments:HANDLE,INPUT BUFFER ttSignals:HANDLE,INPUT BUFFER ttContainers:HANDLE,DATE(10,27,2026),resourceValue,requestValue,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical('success')). RUN Check(resultValue:GetJsonObject('data'):GetCharacter('record_key')=keyValue).
 RUN CallService('~{"operation":"read","sinaliz_imp_id":5~}',200). RUN Check(resultValue:GetInteger('total')=2).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(1). RUN Check(rowValue:IsNull('link_proc_compra_id')). RUN Check(rowValue:GetInteger('link_container_id')=10).
 RUN Check(rowValue:GetCharacter('record_key')<>keyValue).
 RUN CallService('~{"operation":"read","sinaliz_imp_id":3~}',200). RUN Check(resultValue:GetInteger('total')=1).
 RUN CallService('~{"operation":"read","sinaliz_imp_id":6~}',422).
 RUN CallService('~{"operation":"read","sinaliz_imp_id":0~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":10~}',422).
 RUN CallService('~{"operation":"read","today":"2000-01-01"~}',422).
 RUN CallService('~{"operation":"read","sql":"FOR EACH other"~}',422).
 RUN CallService('~{"operation":"read","empresa_id":3~}',422).
 RUN CallService('~{"operation":"delete"~}',405).
 RUN CallService('~{"operation":"read","take":201~}',422).
 RUN CallService('~{"operation":"read","filter":~{"field":"other","operator":"eq","value":1~}~}',422).
 DO k=100 TO 300:
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=k ttItems.proc_compra_id=10 ttItems.log_aprov_so_ld=TRUE ttItems.dt_real_envio_desenhos=DATE(10,17,2026).
 END.
 RUN CallService('~{"operation":"read","sinaliz_imp_id":1,"skip":200,"take":200~}',200).
 RUN Check(resultValue:GetInteger('total')=202). RUN Check(resultValue:GetJsonArray('data'):Length=2).
 resourceValue='proc_compra_sinalizadores'.
 collectorPath=SEARCH('sursum-api/programs/PurchaseSignalsCollector.r').
 requestValue=NEW JsonObject(). requestValue:Add('operation','read'). requestValue:Add('proc_compra_id',10).
 RUN VALUE(collectorPath)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPayments:HANDLE,INPUT BUFFER ttSignals:HANDLE,DATE(10,27,2026),2,ETIME,requestValue,OUTPUT resultValue,OUTPUT TABLE ttSignalRead,OUTPUT pidOut,OUTPUT scannedOut).
 RUN Check(NOT resultValue:GetLogical('success')). RUN Check(scannedOut=3).
 RUN Check(resultValue:GetJsonObject('error'):GetCharacter('code')='PURCHASE_SIGNAL_LIMIT').
 RUN Check(NOT CAN-FIND(FIRST ttSignalRead)).
 CREATE ttPayments. ttPayments.proc_compra_id=10.
 RUN CallService('~{"operation":"read"~}',200).
 RUN Check(resultValue:GetJsonArray('data'):GetJsonObject(4):GetInteger('quantidade')=0).
 FIND ttSignals WHERE ttSignals.sinaliz_imp_id=5. ttSignals.qt_dias_alerta=?. RUN CallService('~{"operation":"read"~}',503).
 ttSignals.qt_dias_alerta=5. DELETE ttSignals. RUN CallService('~{"operation":"read"~}',503).
 CREATE ttSignals. ASSIGN ttSignals.sinaliz_imp_id=5 ttSignals.qt_dias_alerta=5.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=13 ttOrders.empresa_id=2 ttOrders.cod_situacao=1.
 DO k=1000 TO 50899:
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=k ttItems.proc_compra_id=13 ttItems.log_aprov_so_ld=FALSE.
 END.
 RUN CallService('~{"operation":"read"~}',503).
 RUN Check(resultValue:GetJsonObject('error'):GetCharacter('code')='PURCHASE_SIGNALS_GLOBAL_LIMIT').
 RUN Check(NOT resultValue:Has('data')).
 RUN Check(NUM-DBS=0).
 PUT UNFORMATTED 'PASS global service checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE.
