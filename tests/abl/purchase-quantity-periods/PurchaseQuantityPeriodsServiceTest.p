BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttOrders NO-UNDO FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD cod_situacao AS INTEGER FIELD dt_registro AS DATE FIELD cod_proc_fornec AS CHARACTER INDEX pk IS UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttCompanies NO-UNDO FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER INDEX pk IS UNIQUE empresa_id.
DEFINE TEMP-TABLE ttItems NO-UNDO FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD descricao AS CHARACTER FIELD codigo_erp AS CHARACTER FIELD qt_comprada AS DECIMAL FIELD vl_negociado AS DECIMAL FIELD dt_termino_producao AS DATE FIELD dt_prev_termino_producao AS DATE FIELD dt_maxima_producao AS DATE INDEX pk IS UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttAllocations NO-UNDO FIELD item_container_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD container_id AS INTEGER FIELD qt_confirm_emb AS DECIMAL FIELD qt_recbto_fisico AS DECIMAL INDEX pk IS UNIQUE item_container_id.
DEFINE TEMP-TABLE ttContainers NO-UNDO FIELD nr-container AS INTEGER FIELD situacao_container_id AS INTEGER FIELD dt-recebimento AS DATE FIELD dt-prev-chegada AS DATE INDEX pk IS UNIQUE nr-container.
DEFINE TEMP-TABLE ttSituations NO-UNDO FIELD situacao_container_id AS INTEGER FIELD descricao AS CHARACTER INDEX pk IS UNIQUE situacao_container_id.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO. DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE culture AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO,THROW NEW Progress.Lang.AppError('Period service assertion ' + STRING(checks + 1),1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE CallService:
 DEFINE INPUT PARAMETER body AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER expectedStatus AS INTEGER NO-UNDO.
 requestValue=CAST(parser:Parse(body),JsonObject).
 RUN VALUE(pathValue)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttAllocations:HANDLE,INPUT BUFFER ttContainers:HANDLE,INPUT BUFFER ttSituations:HANDLE,60,requestValue,OUTPUT resultValue).
 IF expectedStatus=200 THEN RUN Check(resultValue:GetLogical('success')).
 ELSE DO: RUN Check(NOT resultValue:GetLogical('success')). RUN Check(resultValue:GetJsonObject('error'):GetInteger('status')=expectedStatus). END.
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER. SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO VALUE('quantity-period-service-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO,THROW NEW Progress.Lang.AppError('No DB allowed',1).
 pathValue=SEARCH('sursum-api/programs/PurchaseQuantityPeriodsService.r').
 IF pathValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('RED missing period projection',1).
 parser=NEW ObjectModelParser().
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
 CREATE ttSituations. ASSIGN ttSituations.situacao_container_id=100 ttSituations.descricao='Nao Alocado'.
 CREATE ttOrders. ASSIGN ttOrders.proc_compra_id=10 ttOrders.empresa_id=2 ttOrders.cod_situacao=1 ttOrders.dt_registro=DATE(10,1,2026) ttOrders.cod_proc_fornec='P'.
 DO k=20 TO 22:
  CREATE ttItems. ASSIGN ttItems.item_proc_compra_id=k ttItems.proc_compra_id=10 ttItems.codigo_erp=IF k=22 THEN 'B' ELSE 'A' ttItems.descricao='Same' ttItems.qt_comprada=10 ttItems.vl_negociado=2 ttItems.dt_termino_producao=DATE(10,15,2026) ttItems.dt_maxima_producao=DATE(10,20,2026).
 END.
 RUN CallService('~{"operation":"read"~}',200). RUN Check(resultValue:GetInteger('total')=2).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(1). keyValue=rowValue:GetCharacter('record_key').
 RUN Check(NOT rowValue:Has('item_proc_compra_id') AND NOT rowValue:Has('proc_compra_id')).
 RUN Check(rowValue:GetCharacter('dt_prev_chegada')='2026-11-19').
 requestValue=NEW JsonObject(). requestValue:Add('operation','get'). requestValue:Add('id',keyValue). requestValue:Add('record_key',keyValue).
 RUN VALUE(pathValue)(INPUT BUFFER ttOrders:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttAllocations:HANDLE,INPUT BUFFER ttContainers:HANDLE,INPUT BUFFER ttSituations:HANDLE,60,requestValue,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical('success')). RUN Check(resultValue:GetJsonObject('data'):GetCharacter('record_key')=keyValue).
 RUN CallService('~{"operation":"read","skip":1,"take":1~}',200). RUN Check(resultValue:GetInteger('total')=2 AND resultValue:GetJsonArray('data'):Length=1).
 RUN CallService('~{"operation":"read","filter":~{"logic":"and","filters":[~{"field":"dt_prev_chegada","operator":"gte","value":"2026-11-01"~},~{"field":"dt_prev_chegada","operator":"lte","value":"2026-11-30"~}]~}~}',200). RUN Check(resultValue:GetInteger('total')=2).
 CREATE ttContainers. ASSIGN ttContainers.nr-container=100 ttContainers.situacao_container_id=3 ttContainers.dt-recebimento=DATE(10,15,2026) ttContainers.dt-prev-chegada=DATE(11,10,2026).
 DO k=30 TO 31: CREATE ttAllocations. ASSIGN ttAllocations.item_container_id=k ttAllocations.item_proc_compra_id=20 ttAllocations.container_id=100 ttAllocations.qt_confirm_emb=8 ttAllocations.qt_recbto_fisico=0. END.
 RUN CallService('~{"operation":"read"~}',200). RUN Check(resultValue:GetInteger('total')=3).
 RUN CallService('~{"operation":"read","filter":~{"logic":"and","filters":[~{"field":"dt_recebimento","operator":"gte","value":"2026-10-10"~},~{"field":"dt_recebimento","operator":"lte","value":"2026-10-20"~}]~}~}',200). RUN Check(resultValue:GetInteger('total')=1).
 rowValue=resultValue:GetJsonArray('data'):GetJsonObject(1). RUN Check(rowValue:GetDecimal('qt_rec_final')=8 AND rowValue:GetDecimal('vl_rec_final')=16).
 RUN CallService('~{"operation":"read","filter":~{"field":"dt_registro","operator":"eq","value":"2026-10-02"~}~}',200). RUN Check(resultValue:GetInteger('total')=0).
 RUN CallService('~{"operation":"read","filter":~{"field":"codigo_erp","operator":"eq","value":"B"~}~}',200). RUN Check(resultValue:GetInteger('total')=1).
 RUN CallService('~{"operation":"read","take":201~}',422).
 RUN CallService('~{"operation":"read","empresa_id":3~}',422).
 RUN CallService('~{"operation":"read","proc_compra_id":10~}',422).
 RUN CallService('~{"operation":"read","sql":"other"~}',422).
 RUN CallService('~{"operation":"delete"~}',405).
 RUN CallService('~{"operation":"read","filter":~{"field":"DT_REGISTRO","operator":"eq","value":"2026-10-02"~}~}',422).
 RUN Check(NUM-DBS=0 AND SESSION:NUMERIC-FORMAT=culture).
 RUN Check(CAN-FIND(FIRST ttItems WHERE item_proc_compra_id=20 AND qt_comprada=10)).
 PUT UNFORMATTED 'PASS period service checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END. OUTPUT CLOSE. QUIT.
