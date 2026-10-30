BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE orders FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE companies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE items FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE allocations FIELD item_container_id AS INTEGER FIELD container_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD qt_alocada AS DECIMAL DECIMALS 2 INDEX pk IS PRIMARY UNIQUE item_container_id.
DEFINE TEMP-TABLE containers FIELD nr-container AS INTEGER FIELD situacao AS INTEGER FIELD situacao_container_id AS INTEGER INDEX pk IS PRIMARY UNIQUE nr-container.
DEFINE TEMP-TABLE situations FIELD situacao_container_id AS INTEGER FIELD descricao AS CHARACTER INDEX pk IS PRIMARY UNIQUE situacao_container_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE filterValue AS JsonObject NO-UNDO. DEFINE VARIABLE sortValue AS JsonObject NO-UNDO. DEFINE VARIABLE arrayValue AS JsonArray NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('allocations-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 CREATE companies. ASSIGN companies.empresa_id=2 companies.cod_emp_ems2=5.
 CREATE companies. ASSIGN companies.empresa_id=3 companies.cod_emp_ems2=1.
 CREATE orders. ASSIGN orders.proc_compra_id=10 orders.empresa_id=2.
 CREATE orders. ASSIGN orders.proc_compra_id=20 orders.empresa_id=3.
 CREATE items. ASSIGN items.item_proc_compra_id=1 items.proc_compra_id=10.
 CREATE items. ASSIGN items.item_proc_compra_id=2 items.proc_compra_id=20.
 CREATE items. ASSIGN items.item_proc_compra_id=3 items.proc_compra_id=10.
 CREATE containers. ASSIGN containers.nr-container=100 containers.situacao=1 containers.situacao_container_id=4.
 CREATE containers. ASSIGN containers.nr-container=200 containers.situacao=3 containers.situacao_container_id=99.
 CREATE situations. ASSIGN situations.situacao_container_id=4 situations.descricao='Embarcado'.
 CREATE allocations. ASSIGN allocations.item_container_id=11 allocations.container_id=100 allocations.item_proc_compra_id=1 allocations.qt_alocada=2.34.
 CREATE allocations. ASSIGN allocations.item_container_id=12 allocations.container_id=200 allocations.item_proc_compra_id=1 allocations.qt_alocada=5.
 CREATE allocations. ASSIGN allocations.item_container_id=13 allocations.container_id=100 allocations.item_proc_compra_id=2 allocations.qt_alocada=99.
 CREATE allocations. ASSIGN allocations.item_container_id=14 allocations.container_id=999 allocations.item_proc_compra_id=1 allocations.qt_alocada=9.
 RUN Request('read',10,1). RUN Invoke.
 RUN Check(VALID-OBJECT(res),'service not implemented').
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=2,'inner join excludes orphan and different item').
 rowValue=res:GetJsonArray('data'):GetJsonObject(1).
 RUN Check(rowValue:GetInteger('item_container_id')=11 AND rowValue:GetInteger('proc_compra_id')=10 AND rowValue:GetInteger('item_proc_compra_id')=1,'stable PK and explicit owners').
 RUN Check(rowValue:GetDecimal('qt_alocada')=2.34 AND rowValue:GetCharacter('situacao_descricao')='Aberto' AND rowValue:GetCharacter('situacao_acomp')='Embarcado','physical amount and legacy status descriptions').
 RUN Check(res:GetJsonArray('data'):GetJsonObject(2):GetCharacter('situacao_acomp')='Nao Informada','missing lookup has explicit fallback').
 RUN Check(NOT res:Has('audit') AND NOT res:Has('committed') AND NOT rowValue:Has('record_key'),'readonly does not invent audit or composite key').
 RUN Request('get',10,1). req:Add('id','12'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('container_id')=200,'typed detail').
 RUN Request('get',10,1). req:Add('id','12'). req:Add('item_container_id','12'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('item_container_id')=12,'native detail sends id and primary key alias').
 RUN Request('get',10,1). req:Add('id','12'). req:Add('item_container_id','11'). RUN Invoke. RUN Status(422,'conflicting primary key alias').
 RUN Request('get',10,1). req:Add('item_container_id','12'). RUN Invoke. RUN Status(422,'alias alone cannot replace canonical id').
 RUN Request('read',10,1). req:Add('item_container_id',11). RUN Invoke. RUN Status(422,'alias not accepted in list').
 RUN Request('get',10,1). req:Add('id',13). RUN Invoke. RUN Status(404,'detail cannot cross item').
 RUN Request('read',10,2). RUN Invoke. RUN Status(404,'item of another order').
 RUN Request('read',20,2). RUN Invoke. RUN Status(404,'other company').
 RUN Request('read',10,99). RUN Invoke. RUN Status(404,'missing item').
 RUN Request('read',10,3). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=0,'empty allocation list').
 RUN Request('read',10,1). req:Remove('proc_compra_id'). RUN Invoke. RUN Status(422,'mandatory parent').
 RUN Request('read',10,1). req:Remove('item_proc_compra_id'). req:Add('item_proc_compra_id',1.5). RUN Invoke. RUN Status(422,'fractional item').
 RUN Request('read',10,1). req:Add('sql','FOR EACH other'). RUN Invoke. RUN Status(422,'closed contract').
 RUN Request('create',10,1). RUN Invoke. RUN Status(405,'no writer').
 RUN Request('read',10,1). req:Add('skip',1). req:Add('take',1). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=2 AND res:GetJsonArray('data'):Length=1 AND res:GetJsonArray('data'):GetJsonObject(1):GetInteger('item_container_id')=12,'stable shared paging').
 RUN Request('read',10,1). filterValue=NEW JsonObject(). filterValue:Add('field','item_proc_compra_id'). filterValue:Add('operator','eq'). filterValue:Add('value',2). req:Add('filter',filterValue). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=0,'contradictory filter cannot widen context').
 RUN Request('read',10,1). sortValue=NEW JsonObject(). sortValue:Add('field','qt_alocada'). sortValue:Add('dir','desc'). arrayValue=NEW JsonArray(). arrayValue:Add(sortValue). req:Add('sort',arrayValue). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):GetJsonObject(1):GetInteger('item_container_id')=12,'shared bounded sort').
 RUN Request('read',10,1). req:Add('take',201). RUN Invoke. RUN Status(422,'bounded page size').
 FIND containers WHERE containers.nr-container=100. containers.situacao=9.
 RUN Request('get',10,1). req:Add('id',11). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('situacao_descricao')='9','unknown status code remains visible').
 RUN Check(NUM-DBS=0 AND SESSION:NUMERIC-FORMAT=culture,'isolated and numeric culture preserved').
 RUN Check(CAN-FIND(FIRST allocations WHERE allocations.item_container_id=11 AND allocations.qt_alocada=2.34) AND CAN-FIND(FIRST allocations WHERE allocations.item_container_id=14),'business rows unchanged').
 PUT UNFORMATTED 'PASS allocations checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER operationValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER parentValue AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER itemValue AS INTEGER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',operationValue). req:Add('proc_compra_id',parentValue). req:Add('item_proc_compra_id',itemValue).
END PROCEDURE.
PROCEDURE Status:
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetInteger('status')=statusValue,msg).
END PROCEDURE.
PROCEDURE Invoke:
 res=?. IF SEARCH('sursum-api/programs/PurchaseItemAllocationsService.p')=? THEN RETURN.
 RUN VALUE('sursum-api/programs/PurchaseItemAllocationsService.p')(INPUT BUFFER orders:HANDLE,INPUT BUFFER companies:HANDLE,INPUT BUFFER items:HANDLE,INPUT BUFFER allocations:HANDLE,INPUT BUFFER containers:HANDLE,INPUT BUFFER situations:HANDLE,req,OUTPUT res).
END PROCEDURE.
