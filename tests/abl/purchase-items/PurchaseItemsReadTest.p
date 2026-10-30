BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{sursum-api/includes/PurchaseItemsReadBuffer.i}
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE res AS JsonObject NO-UNDO.
DEFINE VARIABLE o AS JsonObject NO-UNDO.
DEFINE VARIABLE a AS JsonArray NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
OUTPUT TO VALUE('purchase-item-read-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 DO i=1 TO 3:
  CREATE ttPurchaseItemRead. ASSIGN ttPurchaseItemRead.item_proc_compra_id=i ttPurchaseItemRead.proc_compra_id=IF i=3 THEN 102 ELSE 101
   ttPurchaseItemRead.descricao=IF i=1 THEN 'Alpha' ELSE 'Beta' ttPurchaseItemRead.qt_comprada=10 ttPurchaseItemRead.qt_alocada=i ttPurchaseItemRead.qt_saldo=10 - i ttPurchaseItemRead.row_stamp=FILL('A',64)
   ttPurchaseItemRead.log_mostruario=i=1 ttPurchaseItemRead.dt_item_certificacao=DATE(10,22,2026).
 END.
 RUN BaseRequest. RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=2,'context excludes other parent').
 EXTENT(ns)=?. ns=res:GetJsonArray('data'):GetJsonObject(1):GetNames(). RUN Check(EXTENT(ns)=50,'reader DTO50 no synthetic record_key').
 RUN BaseRequest. req:Add('take',1). req:Add('skip',1). RUN Invoke. RUN Check(res:GetInteger('total')=2 AND res:GetJsonArray('data'):GetJsonObject(1):GetInteger('item_proc_compra_id')=2,'stable paging total').
 RUN BaseRequest. o=NEW JsonObject(). o:Add('field','qt_saldo'). o:Add('operator','gte'). o:Add('value',9). req:Add('filter',o). RUN Invoke.
 RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'computed quantity filter').
 RUN BaseRequest. o=NEW JsonObject(). o:Add('field','log_mostruario'). o:Add('operator','eq'). o:Add('value',TRUE). req:Add('filter',o). RUN Invoke. RUN Check(res:GetInteger('total')=1,'boolean filter').
 RUN BaseRequest. o=NEW JsonObject(). o:Add('field','dt_item_certificacao'). o:Add('operator','eq'). o:Add('value','2026-10-22'). req:Add('filter',o). RUN Invoke. RUN Check(res:GetInteger('total')=2,'DATE field filter').
 RUN BaseRequest. o=NEW JsonObject(). o:Add('field','forged'). o:Add('operator','eq'). o:Add('value',1). req:Add('filter',o). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'unknown field refused').
 RUN BaseRequest. req:Add('take',201). RUN Invoke. RUN Check(NOT res:GetLogical('success'),'bounded page').
 RUN BaseRequest. req:Add('sort',NEW JsonArray()). o=NEW JsonObject(). o:Add('field','descricao'). o:Add('dir','desc'). req:GetJsonArray('sort'):Add(o). RUN Invoke.
 RUN Check(res:GetJsonArray('data'):GetJsonObject(1):GetInteger('item_proc_compra_id')=2,'native sort reused').
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' checks ': ' e:GetMessage(1) SKIP. IF VALID-OBJECT(res) THEN res:WriteFile('purchase-item-read-failure.json',TRUE). END CATCH.
END. OUTPUT CLOSE.
PROCEDURE BaseRequest: req=NEW JsonObject(). req:Add('operation','read'). END PROCEDURE.
PROCEDURE Invoke: RUN CiwErpReadService.p(INPUT BUFFER ttPurchaseItemRead:HANDLE,'proc_compra_itens','101',req,OUTPUT res). END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.
