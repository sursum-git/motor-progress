BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchaseItemsFinanceFixture.i}
DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER.
DEFINE TEMP-TABLE ttSuppliers FIELD cod-emitente AS INTEGER.
DEFINE TEMP-TABLE ttDependencies FIELD dependency_id AS INTEGER FIELD proc_compra_id AS INTEGER.
DEFINE TEMP-TABLE ttFiscal FIELD container_id AS INTEGER FIELD changed AS LOGICAL INDEX pk IS UNIQUE PRIMARY container_id.
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
DEFINE VARIABLE fiscalOrder AS CHARACTER NO-UNDO.
DEFINE VARIABLE failContainer AS INTEGER NO-UNDO.
DEFINE VARIABLE effect AS JsonObject NO-UNDO.
DEFINE VARIABLE ns AS CHARACTER EXTENT NO-UNDO.
policy=NEW JsonObject(). o=NEW JsonObject(). o:Add('login','runtime-real-user'). policy:Add('actor',o).
finance=NEW JsonObject(). a=NEW JsonArray(). a:Add('AF'). finance:Add('adiantamentos',a). a=NEW JsonArray(). a:Add('DI'). finance:Add('titulos',a).
CREATE ttOwner. ttOwner.nr-container=1.
CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500.
CREATE ttSuppliers. ttSuppliers.cod-emitente=11.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=101 ttPurchases.fornecedor_id=11 ttPurchases.log_considerar_previsao=FALSE.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=102 ttPurchases.fornecedor_id=22 ttPurchases.log_considerar_previsao=TRUE.
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

FIND ttPurchases WHERE ttPurchases.proc_compra_id=101. ttPurchases.log_considerar_previsao=TRUE.
CREATE ttAllContainers. ttAllContainers.nr-container=72.
CREATE ttItems. ASSIGN ttItems.item_container_id=3 ttItems.container_id=72 ttItems.item_proc_compra_id=13 ttItems.qt_alocada=4 ttItems.qt_confirm_emb=5.
RUN PurchaseItemsRuntimeHost.p PERSISTENT SET runtime(THIS-PROCEDURE,THIS-PROCEDURE,INPUT BUFFER ttOwner:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,INPUT BUFFER ttTitles:HANDLE,INPUT BUFFER ttValues:HANDLE,policy,finance).
OUTPUT TO VALUE('purchase-item-runtime-' + SESSION:NUMERIC-FORMAT + '.log').
DO ON ERROR UNDO, THROW:
 RUN Invoke. RUN Check(NOT failed AND response:GetLogical('success'),'real runtime financial currency with fiscal callback').
 RUN Check(fiscalOrder='71,72','all related containers fiscal in sorted order').
 RUN Check(CAN-FIND(ttFiscal WHERE ttFiscal.container_id=71) AND CAN-FIND(ttFiscal WHERE ttFiscal.container_id=72),'fiscal participant included in root transaction').
 changes=response:GetJsonArray('changes'). crossSeen=FALSE.
 DO ix=1 TO changes:Length:
  effect=changes:GetJsonObject(ix). o=effect:GetJsonObject('after').
  RUN Check(effect:GetJsonObject('metadata'):GetInteger('originProcCompraId')=101 AND effect:GetJsonObject('metadata'):GetInteger('originItemProcCompraId')=11,'effect origin distinct from owner').
  IF o:Has('item_proc_compra_id') THEN IF o:GetInteger('item_proc_compra_id')=12 THEN DO:
   crossSeen=TRUE. RUN Check(o:GetInteger('proc_compra_id')=102 AND o:GetInteger('fornecedor_id')=22,'cross-order real ledger owner preserved').
  END.
 END.
 RUN Check(crossSeen,'cross-order container financial effect exists').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90),'old payment history retained').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cod_tipo_movto=10 AND ttLedger.item_container_id=1 AND ttLedger.vl_lancto=6),'shared shipped difference type10').
 response:WriteFile('purchase-item-runtime-effects-' + SESSION:NUMERIC-FORMAT + '.json',TRUE).
 FOR EACH ttFiscal: DELETE ttFiscal. END.
 FOR EACH ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000: DELETE ttLedger. END.
 fiscalOrder=''. failContainer=72. RUN Invoke.
 RUN Check(failed AND fiscalOrder='71,72','second container failure reached in order').
 RUN Check(NOT CAN-FIND(FIRST ttFiscal) AND NOT CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id>=1000),'rollback covers first fiscal container and all financial appends').
 RUN Check(CAN-FIND(ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=90),'rollback preserves original ledger').
 PUT UNFORMATTED 'PASS ' checks ' checks ' SESSION:NUMERIC-FORMAT ' NUMDBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' checks ': ' e:GetMessage(1) SKIP. END CATCH.
END. OUTPUT CLOSE. DELETE PROCEDURE runtime.
PROCEDURE Invoke:
 failed=FALSE. ctx=NEW JsonObject(). ctx:Add('operation','purchase-item-update'). ctx:Add('proc_compra_id',101). ctx:Add('item_proc_compra_id',11). ctx:Add('before',NEW JsonObject()). ctx:Add('after',NEW JsonObject()).
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTxn. ttTxn.marker=1.
  FIND ttPurchases WHERE ttPurchases.proc_compra_id=101 EXCLUSIVE-LOCK.
  RUN RunPurchaseItemChange IN runtime(INPUT BUFFER ttPurchases:HANDLE,ctx,OUTPUT response).
  DELETE ttTxn.
  CATCH e AS Progress.Lang.Error: failed=TRUE. PUT UNFORMATTED 'EXPECTED_OR_ERROR ' e:GetMessage(1) SKIP e:CallStack SKIP. END CATCH.
 END.
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER contextData AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Fiscal outside root transaction',1).
 cid=master:BUFFER-FIELD('nr-container'):BUFFER-VALUE.
 fiscalOrder=fiscalOrder + (IF fiscalOrder='' THEN '' ELSE ',') + TRIM(STRING(cid,'->>>>>>>>>9')).
 CREATE ttFiscal. ASSIGN ttFiscal.container_id=cid ttFiscal.changed=TRUE.
 IF failContainer=cid THEN UNDO, THROW NEW Progress.Lang.AppError('Injected second fiscal failure',1).
 result=NEW JsonObject(). result:Add('success',TRUE). result:Add('changes',NEW JsonArray()). result:Add('warnings',NEW JsonArray()).
END PROCEDURE.
PROCEDURE NextLedgerId: DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. sequenceValue=sequenceValue + 1. id=sequenceValue. END PROCEDURE.
PROCEDURE Check: DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1. END PROCEDURE.

PROCEDURE NextPurchaseItemId: DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. UNDO, THROW NEW Progress.Lang.AppError('This runtime suite must not consume purchase item identities',1). END PROCEDURE.
