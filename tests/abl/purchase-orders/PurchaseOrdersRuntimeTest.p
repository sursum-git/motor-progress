BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchaseOrdersFixture.i}
DEFINE TEMP-TABLE ttTitles FIELD cod_estab AS CHARACTER FIELD num_id_tit_ap AS INTEGER FIELD cod_empresa AS CHARACTER FIELD cdn_fornecedor AS INTEGER FIELD cod_espec_docto AS CHARACTER FIELD cod_indic_econ AS CHARACTER FIELD val_origin_tit_ap AS DECIMAL INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap.
DEFINE TEMP-TABLE ttValues FIELD cod_estab AS CHARACTER FIELD num_id_tit_ap AS INTEGER FIELD cod_finalid_econ AS CHARACTER FIELD val_origin_tit_ap AS DECIMAL FIELD val_pagto_tit_ap AS DECIMAL INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap cod_finalid_econ.
DEFINE TEMP-TABLE ttOwner FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttTxn FIELD marker AS INTEGER.
DEFINE VARIABLE deps AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE finance AS JsonObject NO-UNDO.
DEFINE VARIABLE req AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE o AS JsonObject NO-UNDO.
DEFINE VARIABLE a AS JsonArray NO-UNDO.
DEFINE VARIABLE changes AS JsonArray NO-UNDO.
DEFINE VARIABLE tid AS INTEGER NO-UNDO.
DEFINE VARIABLE ix AS INTEGER NO-UNDO.
DEFINE VARIABLE sequenceValue AS INTEGER NO-UNDO INITIAL 1000.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE crossSeen AS LOGICAL NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
DEFINE VARIABLE ctx AS JsonObject NO-UNDO.
policy=NEW JsonObject(). o=NEW JsonObject(). o:Add('login','runtime-real-user'). policy:Add('actor',o).
finance=NEW JsonObject(). a=NEW JsonArray(). a:Add('AF'). finance:Add('adiantamentos',a). a=NEW JsonArray(). a:Add('DI'). finance:Add('titulos',a).
CREATE ttOwner. ttOwner.nr-container=1.
CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
CREATE ttSuppliers. ttSuppliers.cod-emitente=11.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=101 ttPurchases.empresa_id=2 ttPurchases.fornecedor_id=11 ttPurchases.log_considerar_previsao=FALSE.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=102 ttPurchases.empresa_id=2 ttPurchases.fornecedor_id=22 ttPurchases.log_considerar_previsao=TRUE.
CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=101 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_negociado=3 ttPurchaseItems.vl_custo_dolar=2.
CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=13 ttPurchaseItems.proc_compra_id=101 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_negociado=1 ttPurchaseItems.vl_custo_dolar=1.
CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=12 ttPurchaseItems.proc_compra_id=102 ttPurchaseItems.qt_comprada=200 ttPurchaseItems.vl_negociado=4 ttPurchaseItems.vl_custo_dolar=3.
CREATE ttAllContainers. ttAllContainers.nr-container=71.
CREATE ttItems. ASSIGN ttItems.item_container_id=1 ttItems.container_id=71 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=10 ttItems.qt_confirm_emb=12.
CREATE ttItems. ASSIGN ttItems.item_container_id=2 ttItems.container_id=71 ttItems.item_proc_compra_id=12 ttItems.qt_alocada=20 ttItems.qt_confirm_emb=20.
CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=101 ttOrderPayments.num_id_tit_ap=600.
CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=71 ttContainerPayments.num_id_tit_ap=500.
DO tid=500 TO 600 BY 100:
 CREATE ttTitles. ASSIGN ttTitles.cod_estab='501' ttTitles.num_id_tit_ap=tid ttTitles.cod_empresa='500' ttTitles.cdn_fornecedor=11 ttTitles.cod_espec_docto='AF' ttTitles.cod_indic_econ='USD' ttTitles.val_origin_tit_ap=IF tid=600 THEN 100 ELSE 80.
 CREATE ttValues. ASSIGN ttValues.cod_estab='501' ttValues.num_id_tit_ap=tid ttValues.cod_finalid_econ='dolar' ttValues.val_origin_tit_ap=IF tid=600 THEN 100 ELSE 80.
 CREATE ttValues. ASSIGN ttValues.cod_estab='501' ttValues.num_id_tit_ap=tid ttValues.cod_finalid_econ='corrente' ttValues.val_origin_tit_ap=IF tid=600 THEN 500 ELSE 400.
END.
CREATE ttLedger. ASSIGN ttLedger.cta_corren_fornec_imp_id=90 ttLedger.fornecedor_id=11 ttLedger.item_proc_compra_id=11 ttLedger.num_id_tit_ap=500 ttLedger.cod_tipo_movto=4 ttLedger.vl_lancto=-40.
ASSIGN deps[1]=BUFFER ttPurchaseItems:HANDLE deps[2]=BUFFER ttDependencies:HANDLE deps[3]=BUFFER ttDependencies:HANDLE deps[4]=BUFFER ttOrderPayments:HANDLE.
/* Host runtime changes only sequence provider in private staging. Every other
   method, title mutex, currency collector and financial source are production. */
RUN ContainersItensRuntimeHost.p PERSISTENT SET runtime(INPUT ?,THIS-PROCEDURE,INPUT BUFFER ttOwner:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,INPUT BUFFER ttTitles:HANDLE,INPUT BUFFER ttValues:HANDLE,policy,finance).
OUTPUT TO VALUE('purchase-orders-integration-' + SESSION:NUMERIC-FORMAT + '.log').
req=NEW JsonObject(). req:Add('operation','get'). req:Add('id',101). RUN Invoke.
o=NEW JsonObject(). o:Add('log_considerar_previsao',TRUE). req=NEW JsonObject(). req:Add('operation','update'). req:Add('id',101). req:Add('row_stamp',response:GetJsonObject('data'):GetCharacter('row_stamp')). req:Add('values',o). RUN Invoke.
RUN Check(response:GetLogical('success') AND response:GetLogical('committed'),'actual writer-runtime-currency-finance integration').
RUN Check(response:GetJsonObject('data'):GetInteger('proc_compra_id')=101 AND response:GetJsonObject('audit'):GetJsonObject('after'):GetInteger('fornecedor_id')=11,'root buffer repositioned after cross-order refresh').
changes=response:GetJsonObject('audit'):GetJsonArray('changes').
DO ix=1 TO changes:Length:
 o=changes:GetJsonObject(ix):GetJsonObject('after').
 IF o:Has('item_proc_compra_id') THEN IF o:GetInteger('item_proc_compra_id')=12 THEN DO: crossSeen=TRUE. RUN Check(o:GetInteger('proc_compra_id')=102 AND o:GetInteger('fornecedor_id')=22,'cross-order effect has real purchase/supplier'). END.
END.
RUN Check(crossSeen,'related container refresh includes other purchase item').
RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=10 AND ttLedger.item_container_id=1 AND ttLedger.vl_lancto=6),'type10 shipped difference reused').
RUN Check(NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90) AND CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=3 AND ttLedger.item_proc_compra_id=11 AND ttLedger.vl_lancto=300),'old image deleted obligations reconstructed').
response:WriteFile('purchase-order-audit-enable-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
o=NEW JsonObject(). o:Add('log_considerar_previsao',FALSE). req=NEW JsonObject(). req:Add('operation','update'). req:Add('id',101). req:Add('row_stamp',response:GetJsonObject('data'):GetCharacter('row_stamp')). req:Add('values',o). RUN Invoke.
RUN Check(response:GetLogical('success') AND CAN-FIND(ttLedger WHERE ttLedger.item_proc_compra_id=12 AND ttLedger.cod_tipo_movto=5),'disable preserves cross-order ledger and clears only owned items').
RUN Check(NOT CAN-FIND(ttLedger WHERE (ttLedger.item_proc_compra_id=11 OR ttLedger.item_proc_compra_id=13) AND ttLedger.cod_tipo_movto>2),'disable applies legacy >2 own scope only').
response:WriteFile('purchase-order-audit-disable-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
OUTPUT CLOSE. DELETE PROCEDURE runtime. QUIT.
PROCEDURE Invoke:
 RUN PurchaseOrdersService.p(INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttSuppliers:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,deps,runtime,policy,req,OUTPUT response).
END PROCEDURE.
PROCEDURE NextLedgerId: DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. sequenceValue=sequenceValue + 1. id=sequenceValue. END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN DO: response:WriteFile('integration-failure.json',TRUE). UNDO, THROW NEW Progress.Lang.AppError(msg,1). END. checks=checks + 1. END PROCEDURE.

