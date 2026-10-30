/* Real payment orchestration -> shared financial runtime -> financial rules ->
   currency collector. Zero-value titles ensure no real sequence can be used. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItensCrudFixture.i}
{ContainersItensCompositionFixture.i}
DEFINE VARIABLE itemRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE paymentRuntime AS HANDLE NO-UNDO.
DEFINE VARIABLE buffersValue AS HANDLE EXTENT 10 NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE ctx AS JsonObject NO-UNDO.
DEFINE VARIABLE image AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE fiscalCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
IF CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Bridge proof requires a separate AVM without business DB connections.",1).
CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.cod-estabel="501". RELEASE ttMaster.
CREATE ttAllContainers. ttAllContainers.nr-container=123. RELEASE ttAllContainers.
CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=21 ttPurchases.fornecedor_id=888 ttPurchases.log_considerar_previsao=TRUE. RELEASE ttPurchases.
CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=21 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_custo_dolar=1 ttPurchaseItems.vl_negociado=1. RELEASE ttPurchaseItems.
CREATE ttItems. ASSIGN ttItems.item_container_id=1001 ttItems.container_id=123 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=10. RELEASE ttItems.
CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=123 ttContainerPayments.num_id_tit_ap=7. RELEASE ttContainerPayments.
CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=21 ttOrderPayments.num_id_tit_ap=7. RELEASE ttOrderPayments.
CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=7 ttTitles.cod_estab="001" ttTitles.cod_espec_docto="AF". RELEASE ttTitles.
DO n=1 TO 2:
 CREATE ttTitleValues. ASSIGN ttTitleValues.num_id_tit_ap=7 ttTitleValues.cod_estab="001" ttTitleValues.cod_finalid_econ=ENTRY(n,"corrente,dolar") ttTitleValues.val_origin_tit_ap=0 ttTitleValues.val_pagto_tit_ap=0. RELEASE ttTitleValues.
END.
parser=NEW ObjectModelParser(). policy=CAST(parser:Parse('~{"actor":~{"login":"payment-tester"}}'),JsonObject).
financePolicy=CAST(parser:Parse('~{"adiantamentos":["AF"],"titulos":["DI"]}'),JsonObject). DELETE OBJECT parser.
RUN ContainersItensRuntime.p PERSISTENT SET itemRuntime(THIS-PROCEDURE,THIS-PROCEDURE,INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,INPUT BUFFER ttTitles:HANDLE,INPUT BUFFER ttTitleValues:HANDLE,policy,financePolicy).
buffersValue[1]=BUFFER ttMaster:HANDLE.
RUN ContainersPagamentosRuntime.p PERSISTENT SET paymentRuntime(THIS-PROCEDURE,itemRuntime,INPUT ?,buffersValue,financePolicy).
image=NEW JsonObject(). image:Add("container_id",123). image:Add("num_id_tit_ap",7).
ctx=NEW JsonObject(). ctx:Add("operation","associate"). ctx:Add("container_id",123). ctx:Add("before",NEW JsonObject()). ctx:Add("after",CAST(image:Clone(),JsonObject)).
DO TRANSACTION ON ERROR UNDO, THROW:
 FIND FIRST ttMaster EXCLUSIVE-LOCK.
 RUN ChangePayment IN paymentRuntime(INPUT BUFFER ttMaster:HANDLE,ctx,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("success") AND resultValue:GetJsonArray("changes"):Length=0,"real association bridge yields no invented zero movements").
 RUN Check(fiscalCalls=1,"real association bridge composes fiscal exactly once").
END.
ctx:Set("operation","disassociate"). ctx:Set("before",CAST(image:Clone(),JsonObject)). ctx:Set("after",NEW JsonObject()).
DO TRANSACTION ON ERROR UNDO, THROW:
 FIND FIRST ttMaster EXCLUSIVE-LOCK.
 RUN ChangePayment IN paymentRuntime(INPUT BUFFER ttMaster:HANDLE,ctx,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("success") AND resultValue:GetJsonArray("changes"):Length=0,"real forced order rerateio uses same zero currency bridge").
 RUN Check(fiscalCalls=1,"real disassociation does not call fiscal").
END.
RUN Check(NOT CAN-FIND(FIRST ttLedger) AND NOT CONNECTED("espec"),"no sequence or business database used by real bridge proof").
DELETE PROCEDURE paymentRuntime. DELETE PROCEDURE itemRuntime.
OUTPUT TO VALUE("containers-pagamentos-bridge-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; actual Runtime/Finance/Totals, TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER textValue AS CHARACTER NO-UNDO.
 checks=checks + 1. IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + textValue,1).
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER contextValue AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER responseValue AS JsonObject NO-UNDO.
 fiscalCalls=fiscalCalls + 1. responseValue=NEW JsonObject(). responseValue:Add("success",TRUE). responseValue:Add("changes",NEW JsonArray()). responseValue:Add("warnings",NEW JsonArray()).
END PROCEDURE.
