BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE orders FIELD proc_compra_id AS INTEGER FIELD empresa_id AS INTEGER FIELD qt_container AS INTEGER FIELD cotacao_prevista AS DECIMAL DECIMALS 10 INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE companies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE items FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD qt_comprada AS DECIMAL DECIMALS 10 FIELD vl_negociado AS DECIMAL DECIMALS 10 INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE expenses FIELD despesa_proc_compra_id AS INTEGER FIELD proc_compra_id AS DECIMAL DECIMALS 2 FIELD vl_prev AS DECIMAL DECIMALS 2 INDEX pk IS PRIMARY UNIQUE despesa_proc_compra_id.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO. DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
IF SESSION:PARAMETER<>'' THEN SESSION:NUMERIC-FORMAT=SESSION:PARAMETER.
culture=SESSION:NUMERIC-FORMAT. OUTPUT TO VALUE('summary-tests-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 CREATE companies. ASSIGN companies.empresa_id=2 companies.cod_emp_ems2=5.
 CREATE companies. ASSIGN companies.empresa_id=3 companies.cod_emp_ems2=1.
 CREATE orders. ASSIGN orders.proc_compra_id=10 orders.empresa_id=2 orders.qt_container=3 orders.cotacao_prevista=5.12345678.
 CREATE orders. ASSIGN orders.proc_compra_id=20 orders.empresa_id=3 orders.qt_container=9 orders.cotacao_prevista=8.
 CREATE items. ASSIGN items.item_proc_compra_id=1 items.proc_compra_id=10 items.qt_comprada=2.5 items.vl_negociado=1.25.
 CREATE items. ASSIGN items.item_proc_compra_id=2 items.proc_compra_id=20 items.qt_comprada=999 items.vl_negociado=999.
 CREATE items. ASSIGN items.item_proc_compra_id=3 items.proc_compra_id=10 items.qt_comprada=? items.vl_negociado=50.
 CREATE expenses. ASSIGN expenses.despesa_proc_compra_id=1 expenses.proc_compra_id=10 expenses.vl_prev=12.34.
 CREATE expenses. ASSIGN expenses.despesa_proc_compra_id=2 expenses.proc_compra_id=10 expenses.vl_prev=?.
 CREATE expenses. ASSIGN expenses.despesa_proc_compra_id=3 expenses.proc_compra_id=20 expenses.vl_prev=999.
 CREATE expenses. ASSIGN expenses.despesa_proc_compra_id=4 expenses.proc_compra_id=10.5 expenses.vl_prev=999.
 RUN Request('read',10). RUN Invoke.
 RUN Check(VALID-OBJECT(res),'summary service not implemented').
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'one contextual row').
 rowValue=res:GetJsonArray('data'):GetJsonObject(1).
 RUN Check(rowValue:GetDecimal('custo_prev_itens')=16.0108024375,'SQL sum preserves multiplication precision and ignores null operands').
 RUN Check(rowValue:GetDecimal('despesas_base')=12.34 AND rowValue:GetDecimal('custo_prev_despesas')=37.02,'expenses multiply by container count; other/fractional owners excluded').
 RUN Check(rowValue:GetInteger('qt_container')=3 AND rowValue:GetDecimal('cotacao_prevista')=5.12345678,'calculation inputs explicit').
 RUN Check(NOT rowValue:Has('record_key') AND NOT res:Has('audit') AND NOT res:Has('committed'),'read has no synthetic transaction/audit').
 RUN Request('get',10). req:Add('id','10'). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('proc_compra_id')=10,'typed detail').
 RUN Request('get',10). req:Add('id','20'). RUN Invoke. RUN Status(404,'detail cannot cross context').
 RUN Request('read',20). RUN Invoke. RUN Status(404,'other company not exposed').
 RUN Request('read',99). RUN Invoke. RUN Status(404,'missing parent').
 RUN Request('read',10). req:Remove('proc_compra_id'). RUN Invoke. RUN Status(422,'mandatory parent').
 RUN Request('read',10). req:Remove('proc_compra_id'). req:Add('proc_compra_id',10.5). RUN Invoke. RUN Status(422,'fractional parent refused').
 RUN Request('read',10). req:Add('values',NEW JsonObject()). RUN Invoke. RUN Status(422,'closed contract').
 RUN Request('create',10). RUN Invoke. RUN Status(405,'no writer').
 RUN Request('read',10). req:Add('skip',1). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1 AND res:GetJsonArray('data'):Length=0,'shared reader paging').
 RUN Request('read',10). req:Add('take',201). RUN Invoke. RUN Status(422,'bounded reader').
 FIND orders WHERE orders.proc_compra_id=10. ASSIGN orders.qt_container=0 orders.cotacao_prevista=?.
 RUN Request('get',10). req:Add('id',10). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetDecimal('custo_prev_itens')=0 AND res:GetJsonObject('data'):GetDecimal('custo_prev_despesas')=0,'zero containers/null exchange follow legacy zero').
 FOR EACH items WHERE items.proc_compra_id=10: DELETE items. END.
 FOR EACH expenses WHERE expenses.proc_compra_id=10: DELETE expenses. END.
 RUN Request('get',10). req:Add('id',10). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetDecimal('despesas_base')=0 AND res:GetJsonObject('data'):GetDecimal('custo_prev_itens')=0,'empty sums zero').
 RUN Check(CAN-FIND(FIRST items WHERE items.proc_compra_id=20) AND CAN-FIND(FIRST expenses WHERE expenses.proc_compra_id=20),'other rows preserved').
 PUT UNFORMATTED 'PASS summary checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1).
END PROCEDURE.
PROCEDURE Request:
 DEFINE INPUT PARAMETER operationValue AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER parentValue AS INTEGER NO-UNDO.
 req=NEW JsonObject(). req:Add('operation',operationValue). req:Add('proc_compra_id',parentValue).
END PROCEDURE.
PROCEDURE Status:
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetInteger('status')=statusValue,msg).
END PROCEDURE.
PROCEDURE Invoke:
 res=?. IF SEARCH('sursum-api/programs/PurchaseSummaryService.p')=? THEN RETURN.
 RUN VALUE('sursum-api/programs/PurchaseSummaryService.p')(INPUT BUFFER orders:HANDLE,INPUT BUFFER companies:HANDLE,INPUT BUFFER items:HANDLE,INPUT BUFFER expenses:HANDLE,req,OUTPUT res).
END PROCEDURE.
