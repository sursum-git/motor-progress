BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchaseOrdersFixture.i}
{PurchaseOrderSnapshot.i}
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO. DEFINE VARIABLE res AS JsonObject NO-UNDO. DEFINE VARIABLE o AS JsonObject NO-UNDO. DEFINE VARIABLE keyText AS LONGCHAR NO-UNDO. DEFINE VARIABLE checks AS INTEGER NO-UNDO.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=101 ttPurchases.empresa_id=2 ttPurchases.fornecedor_id=11 ttPurchases.cod_situacao=0 ttPurchases.cod_proc_fornec='MED ' + CHR(233) ttPurchases.log_considerar_previsao=TRUE.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=102 ttPurchases.empresa_id=1 ttPurchases.fornecedor_id=22.
OUTPUT TO VALUE('purchase-orders-read-tests-' + SESSION:NUMERIC-FORMAT + '.log').
req=NEW JsonObject(). req:Add('operation','read'). req:Add('take',1). RUN Invoke.
RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'scoped paged full header').
o=res:GetJsonArray('data'):GetJsonObject(1). names=o:GetNames(). RUN Check(EXTENT(names)=15 AND NOT o:Has('record_key'),'exact15 full header data without composite presentation key').
FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. RUN Check(o:GetCharacter('row_stamp')=PurchaseOrderStamp(PurchaseOrderSnapshot(BUFFER ttPurchases:HANDLE)) AND o:GetInteger('cod_situacao')=0,'stamp common writer reader and legacy0 readable').
req=NEW JsonObject(). req:Add('operation','read'). req:Add('skip',1). req:Add('take',1). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonArray('data'):Length=0 AND res:GetInteger('total')=1,'paging exact total').
req=NEW JsonObject(). req:Add('operation','read'). o=NEW JsonObject(). o:Add('field','log_considerar_previsao'). o:Add('operator','eq'). o:Add('value',TRUE). req:Add('filter',o). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetInteger('total')=1,'native boolean filter literal').
req=NEW JsonObject(). req:Add('operation','get'). o=NEW JsonObject(). o:Add('proc_compra_id',101). o:Write(keyText,FALSE). req:Add('id',STRING(keyText)). RUN Invoke. RUN Check(res:GetLogical('success') AND res:GetJsonObject('data'):GetInteger('proc_compra_id')=101,'get14 plusstamp').
PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP. OUTPUT CLOSE.
PROCEDURE Invoke: RUN CiwErpReadService.p(INPUT BUFFER ttPurchases:HANDLE,'procs_compra_med','2',req,OUTPUT res). END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN DO: res:WriteFile('reader-failure.json',TRUE). UNDO, THROW NEW Progress.Lang.AppError(msg,1). END. checks=checks + 1. END PROCEDURE.

