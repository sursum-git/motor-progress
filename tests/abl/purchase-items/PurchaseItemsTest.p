BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchaseItemsFixture.i}
{sursum-api/includes/PurchaseItemValueRules.i}
DEFINE VARIABLE deps AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE v AS JsonObject NO-UNDO.
DEFINE VARIABLE stamp AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE purchaseSequence AS INTEGER NO-UNDO.
DEFINE VARIABLE failLate AS LOGICAL NO-UNDO.
DEFINE VARIABLE stopLate AS LOGICAL NO-UNDO.
DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
ASSIGN deps[1]=BUFFER ttSideEffect:HANDLE deps[2]=BUFFER ttSideEffect:HANDLE deps[3]=BUFFER ttSideEffect:HANDLE deps[4]=BUFFER ttSideEffect:HANDLE.
OUTPUT TO VALUE('purchase-items-tests-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Check(PurchaseItemDecimalFits('1e-7',10),'JSON exponent1e-7 accepted').
 RUN Check(PurchaseItemDecimalFits('1e-10',10),'JSON exponent1e-10 accepted').
 RUN Check(NOT PurchaseItemDecimalFits('1e-11',10),'JSON exponent1e-11 refused before rounding').
 RUN Check(PurchaseItemDecimalFits('1.200000e-4',5),'trailing zeros exact physical precision').
 RUN Seed. RUN CreateRequest. RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetLogical('committed'),'create committed').
 RUN Check(res:GetJsonObject('data'):GetInteger('item_proc_compra_id')=1 AND res:GetJsonObject('data'):GetInteger('proc_compra_id')=101,'server identity and context').
 ns=res:GetJsonObject('audit'):GetJsonObject('after'):GetNames(). RUN Check(EXTENT(ns)=46,'audit physical46').
 EXTENT(ns)=?. ns=res:GetJsonObject('data'):GetNames(). RUN Check(EXTENT(ns)=50,'DTO50').
 RUN Check(res:GetJsonObject('audit'):GetJsonObject('actor'):GetCharacter('login')='trusted-user','authenticated actor').
 stamp=res:GetJsonObject('data'):GetCharacter('row_stamp'). RUN Check(LENGTH(stamp)=64,'opaque stamp').
 res:WriteFile('purchase-item-create-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN UpdateRequest. v:Add('observacao','alterado'). RUN Invoke. RUN Check(res:GetLogical('success'),'partial update').
 res:WriteFile('purchase-item-update-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Invoke. RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetInteger('status')=409,'stale rejected').
 RUN GetStamp. RUN UpdateRequest. v:Add('peso','150'). v:Add('largura','140,5'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetDecimal('calc_gm')=210.75,'GM shared formula comma without culture').
 RUN GetStamp. RUN UpdateRequest. v:Add('peso','abc'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):IsNull('calc_gm'),'GM invalid numeric text isnull').
 RUN GetStamp. RUN UpdateRequest. v:Add('qt_comprada',5). CREATE ttAlloc. ASSIGN ttAlloc.item_container_id=10 ttAlloc.item_proc_compra_id=1 ttAlloc.qt_alocada=6.
 RUN Invoke. RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetCharacter('code')='PURCHASE_ITEM_QUANTITY','quantity floor').
 RUN DeleteRequest. ttAlloc.qt_alocada=0. RUN Invoke. RUN Check(NOT res:GetLogical('success') AND res:GetJsonObject('error'):GetCharacter('code')='PURCHASE_ITEM_DEPENDENCY','any zero allocation blocks delete').
 EMPTY TEMP-TABLE ttAlloc.
 RUN UpdateRequest. v:Add('proc_compra_id',102). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'immutable context').
 RUN UpdateRequest. v:Add('item_proc_compra_id',22). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'immutable identity').
 RUN UpdateRequest. v:Add('qt_dias_producao',1.2). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'integer fraction refused').
 RUN UpdateRequest. v:Add('dt_item_certificacao','2026-02-30'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'invalid date').
 RUN UpdateRequest. v:Add('dt_item_certificacao','2026-10-22'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('dt_item_certificacao')='2026-10-22','certification DATE'). RUN GetStamp.
 RUN UpdateRequest. parser=NEW ObjectModelParser(). v=CAST(parser:Parse(CHR(123) + '"vl_custo_dolar":1e-7' + CHR(125)),JsonObject). req:Set('values',v). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetDecimal('vl_custo_dolar')=0.0000001,'actual JSON exponent1e-7 accepted').
 RUN GetStamp. RUN UpdateRequest. v=CAST(parser:Parse(CHR(123) + '"vl_custo_dolar":1e-10' + CHR(125)),JsonObject). req:Set('values',v). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetDecimal('vl_custo_dolar')=0.0000000001,'actual JSON exponent1e-10 accepted').
 RUN GetStamp. RUN UpdateRequest. v=CAST(parser:Parse(CHR(123) + '"vl_custo_dolar":1e-11' + CHR(125)),JsonObject). req:Set('values',v). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'actual JSON exponent1e-11 refused before rounding').
 RUN UpdateRequest. v:Add('item_estacao',2). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'season outside physical list15 refused').
 CREATE ttSeason. ASSIGN ttSeason.lista_id=15 ttSeason.cod_opcao='2'. RUN Invoke. RUN Check(res:GetLogical('success'),'season string physicalcode resolved'). RUN GetStamp.
 RUN UpdateRequest. v:Add('Descricao','case alias'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'values names RAW closed').
 RUN UpdateRequest. v:Add('calc_gm',3). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'GM projection readonly').
 RUN UpdateRequest. v:Add('codigo_erp','12A'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'ERP digits only').
 RUN UpdateRequest. v:Add('descricao',FILL('x',101)). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'description100').
 RUN UpdateRequest. v:Add('unid_medida','XX'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'unit closed').
 RUN UpdateRequest. v:AddNull('qt_comprada'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'new unknown quantity rejected').
 RUN UpdateRequest. v:Add('qt_comprada','10'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'numeric string refused').
 RUN UpdateRequest. v:Add('vl_base_tributacao',0.000001). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'decimal precision refused').
 RUN UpdateRequest. req:Set('proc_compra_id',102). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'item cannot escape parent').
 RUN UpdateRequest. req:Remove('proc_compra_id'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'mandatory parent').
 RUN UpdateRequest. req:Add('actor','forged'). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'forged actor refused').
 RUN UpdateRequest. v:Add('observacao','late failure'). failLate=TRUE. RUN Invoke. failLate=FALSE.
 FIND ttPurchaseItems WHERE ttPurchaseItems.item_proc_compra_id=1. RUN Check(NOT res:GetLogical('success') AND ttPurchaseItems.observacao='alterado' AND NOT CAN-FIND(FIRST ttSideEffect),'late effects rollback together').
 RUN UpdateRequest. v:Add('observacao','stop failure'). stopLate=TRUE. RUN Invoke. stopLate=FALSE.
 RUN Check(NOT res:GetLogical('success') AND NOT res:Has('committed') AND NOT CAN-FIND(FIRST ttSideEffect),'STOP rollback').
 RUN UpdateRequest. v:Add('dt_real_aprov_so_ld','2026-10-22'). v:Add('qt_dias_producao',5). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('dt_maxima_producao')='2026-10-27','date suggestion actual inputs'). RUN GetStamp.
 RUN UpdateRequest. v:Add('dt_maxima_producao','2026-11-01'). RUN Invoke. RUN Check(res:GetLogical('success'),'manual date override'). RUN GetStamp.
 RUN UpdateRequest. v:Add('observacao','preserve manual'). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('dt_maxima_producao')='2026-11-01','unrelated edit preserves manual'). RUN GetStamp.
 RUN DeleteRequest. RUN Invoke. RUN Check(res:GetLogical('success') AND NOT CAN-FIND(FIRST ttPurchaseItems),'delete empty item'). res:WriteFile('purchase-item-delete-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 RUN Seed. RUN CreateRequest. RUN FullDefaults. v:Set('dt_real_aprov_so_ld','2026-10-22'). v:Set('qt_dias_producao',5). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetCharacter('dt_maxima_producao')='2026-10-27','full44 defaults targetnull allows date suggestion').
 RUN Check(res:GetJsonObject('data'):GetDecimal('vl_base_tributacao')=2 AND res:GetJsonObject('data'):GetInteger('ind_distr_custo')=1,'active base and distribution suggestions').
 RUN Seed. RUN CreateRequest. v:Remove('unid_medida'). RUN Invoke. RUN Check(NOT res:GetLogical('success') AND NOT CAN-FIND(FIRST ttPurchaseItems),'create unit required').
 RUN Seed. RUN CreateRequest. FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.empresa_id=99. RUN Invoke. RUN Check(NOT res:GetLogical('success'),'non MED parent refused').
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' checks ': ' e:GetMessage(1) SKIP. IF VALID-OBJECT(res) THEN res:WriteFile('purchase-item-failure.json',TRUE). END CATCH.
END. OUTPUT CLOSE.
PROCEDURE Seed:
 purchaseSequence=0.
 EMPTY TEMP-TABLE ttPurchaseItems. EMPTY TEMP-TABLE ttCompanies. EMPTY TEMP-TABLE ttPurchases. EMPTY TEMP-TABLE ttAlloc. EMPTY TEMP-TABLE ttSideEffect.
 CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
 CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=101 ttPurchases.empresa_id=2 ttPurchases.fornecedor_id=11 ttPurchases.log_considerar_previsao=TRUE.
 policy=NEW JsonObject(). v=NEW JsonObject(). v:Add('login','trusted-user'). policy:Add('actor',v).
END PROCEDURE.
PROCEDURE CreateRequest:
 req=NEW JsonObject(). req:Add('operation','create'). req:Add('proc_compra_id',101). v=NEW JsonObject(). v:Add('descricao','test item'). v:Add('unid_medida','MT'). v:Add('qt_comprada',10). v:Add('vl_custo_dolar',2). v:Add('vl_negociado',3). req:Add('values',v).
END PROCEDURE.
PROCEDURE GetStamp: req=NEW JsonObject(). req:Add('operation','get'). req:Add('proc_compra_id',101). req:Add('id',1). RUN Invoke. stamp=res:GetJsonObject('data'):GetCharacter('row_stamp'). END PROCEDURE.
PROCEDURE UpdateRequest: req=NEW JsonObject(). req:Add('operation','update'). req:Add('proc_compra_id',101). req:Add('id',1). req:Add('row_stamp',stamp). v=NEW JsonObject(). req:Add('values',v). END PROCEDURE.
PROCEDURE DeleteRequest: req=NEW JsonObject(). req:Add('operation','delete'). req:Add('proc_compra_id',101). req:Add('id',1). req:Add('row_stamp',stamp). END PROCEDURE.
PROCEDURE Invoke:
 RUN PurchaseItemsService.p(INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttAlloc:HANDLE,INPUT BUFFER ttColors:HANDLE,INPUT BUFFER ttFormats:HANDLE,INPUT BUFFER ttSeason:HANDLE,deps,THIS-PROCEDURE,policy,req,OUTPUT res).
END PROCEDURE.
PROCEDURE RunPurchaseItemChange:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER r AS JsonObject NO-UNDO.
 IF failLate OR stopLate THEN DO: CREATE ttSideEffect. ttSideEffect.id=1. IF stopLate THEN STOP. UNDO, THROW NEW Progress.Lang.AppError('late failure',1). END.
 r=NEW JsonObject(). r:Add('success',TRUE). r:Add('changes',NEW JsonArray()). r:Add('warnings',NEW JsonArray()).
END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.


PROCEDURE FullDefaults:
 DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DO k=1 TO BUFFER ttPurchaseItems:NUM-FIELDS:
  f=BUFFER ttPurchaseItems:BUFFER-FIELD(k). fieldName=f:NAME.
  IF LOOKUP(fieldName,'item_proc_compra_id,proc_compra_id')>0 OR v:Has(fieldName) THEN NEXT.
  CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN v:Add(fieldName,'').
   WHEN 'INTEGER' THEN v:Add(fieldName,0).
   WHEN 'DECIMAL' THEN v:Add(fieldName,0).
   WHEN 'DATE' THEN v:AddNull(fieldName).
   WHEN 'LOGICAL' THEN v:Add(fieldName,fieldName='log_mostruario').
  END CASE.
 END.
END PROCEDURE.

PROCEDURE NextPurchaseItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Private item sequence outside root transaction',1).
 purchaseSequence=purchaseSequence + 1. valueId=purchaseSequence.
END PROCEDURE.
