/* Actual CRUD + Runtime + Finance + currency bridge. Fiscal is controlled;
   monetary fixtures are TT only, no real sequence or business DB access. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{ContainersItensCrudFixture.i}
{ContainersItensCompositionFixture.i}
DEFINE VARIABLE runtimeValue AS HANDLE NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE fiscalCalls AS INTEGER NO-UNDO.
RUN Fixture. RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"actual Runtime composes fiscal and financial participant").
RUN Check(responseValue:GetJsonObject("data"):GetDecimal("qt_alocada")=30 AND responseValue:GetJsonObject("data"):GetDecimal("perc_ipi")=17.5,"final main image spans mutation and fiscal callback").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=2,"actual runtime child fiscal event plus one coalesced main item").
RUN Check(fiscalCalls=1 AND NOT TRANSACTION,"runtime calls fiscal once and core owns actual commit").
FIND FIRST ttItemEffects. RUN Check(ttItemEffects.container_id=123,"fiscal write committed alongside item"). RELEASE ttItemEffects.
FIND FIRST ttLedger NO-ERROR. RUN Check(NOT AVAILABLE ttLedger,"no payment means no fake financial allocation or sequence").
RUN CurrencyBridgeTests.
RUN Fixture.
FIND FIRST ttPurchases. ttPurchases.fornecedor_id=0. RELEASE ttPurchases.
RUN Invoke.
RUN Check(NOT responseValue:GetLogical("success") AND NOT responseValue:Has("audit"),"actual financial failure has no successful audit").
FIND ttItems WHERE ttItems.item_container_id=1001.
RUN Check(ttItems.qt_alocada=20 AND ttItems.perc_ipi=0,"financial failure rolls item and fiscal IPI mutation back"). RELEASE ttItems.
FIND FIRST ttItemEffects NO-ERROR. RUN Check(NOT AVAILABLE ttItemEffects AND fiscalCalls=1,"financial failure rolls prior fiscal side effect back").
OUTPUT TO VALUE("containers-itens-composition-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; Runtime/Finance/Totals real, TT only; no real sequence." SKIP. OUTPUT CLOSE.
IF VALID-HANDLE(runtimeValue) THEN DELETE PROCEDURE runtimeValue.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 checks=checks + 1.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue + " " + STRING(responseValue:GetJsonText()),1).
END PROCEDURE.
PROCEDURE Fixture:
 IF VALID-HANDLE(runtimeValue) THEN DELETE PROCEDURE runtimeValue.
 EMPTY TEMP-TABLE ttMaster. EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttPurchaseItems. EMPTY TEMP-TABLE ttPurchases.
 EMPTY TEMP-TABLE ttLedger. EMPTY TEMP-TABLE ttOrderPayments. EMPTY TEMP-TABLE ttContainerPayments. EMPTY TEMP-TABLE ttAllContainers. EMPTY TEMP-TABLE ttItemEffects.
 EMPTY TEMP-TABLE ttTitles. EMPTY TEMP-TABLE ttTitleValues.
 CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.cod-estabel="501" ttMaster.cod-emit-forn=10. RELEASE ttMaster.
 CREATE ttAllContainers. ASSIGN ttAllContainers.nr-container=123 ttAllContainers.cod-emit-forn=10. RELEASE ttAllContainers.
 CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=21 ttPurchases.empresa_id=1 ttPurchases.fornecedor_id=888 ttPurchases.log_considerar_previsao=FALSE. RELEASE ttPurchases.
 CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=21 ttPurchaseItems.codigo_erp="ERP11" ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_custo_dolar=10 ttPurchaseItems.vl_negociado=12. RELEASE ttPurchaseItems.
 CREATE ttItems. ASSIGN ttItems.item_container_id=1001 ttItems.container_id=123 ttItems.item_proc_compra_id=11 ttItems.qt_alocada=20. RELEASE ttItems.
 fiscalCalls=0. parser=NEW ObjectModelParser().
 policyValue=CAST(parser:Parse('~{"actor":~{"login":"item-tester"},"usuario_id":0,"despesa_distr_custo":99}'),JsonObject).
 financePolicy=CAST(parser:Parse('~{"adiantamentos":["AF"],"titulos":["DI"]}'),JsonObject).
 requestValue=CAST(parser:Parse('~{"operation":"update","container_id":123,"id":1001,"values":~{"qt_alocada":30}}'),JsonObject). DELETE OBJECT parser.
 RUN ContainersItensRuntime.p PERSISTENT SET runtimeValue(THIS-PROCEDURE,THIS-PROCEDURE,INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,INPUT BUFFER ttTitles:HANDLE,INPUT BUFFER ttTitleValues:HANDLE,policyValue,financePolicy).
END PROCEDURE.
FUNCTION PaymentRow RETURNS JsonObject (rows AS JsonArray,idValue AS INTEGER):
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DO j=1 TO rows:Length: IF rows:GetJsonObject(j):GetInteger("num_id_tit_ap")=idValue THEN RETURN rows:GetJsonObject(j). END.
 UNDO, THROW NEW Progress.Lang.AppError("Expected linked payment row missing",1).
END FUNCTION.
PROCEDURE CurrencyBridgeTests:
 DEFINE VARIABLE rows AS JsonArray NO-UNDO.
 DEFINE VARIABLE rowValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
 DEFINE VARIABLE errorText AS CHARACTER NO-UNDO.
 /* Runtime already confirmed currentContainer=123 during real AfterChange. */
 DO TRANSACTION:
  CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=123 ttContainerPayments.num_id_tit_ap=7. RELEASE ttContainerPayments.
  CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=123 ttContainerPayments.num_id_tit_ap=8. RELEASE ttContainerPayments.
  CREATE ttContainerPayments. ASSIGN ttContainerPayments.container_id=999 ttContainerPayments.num_id_tit_ap=99. RELEASE ttContainerPayments.
  CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=21 ttOrderPayments.num_id_tit_ap=7. RELEASE ttOrderPayments.
  CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=21 ttOrderPayments.num_id_tit_ap=8. RELEASE ttOrderPayments.
  CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=999 ttOrderPayments.num_id_tit_ap=99. RELEASE ttOrderPayments.
  /* AF uses original amounts even for historical reversed other-company data. */
  CREATE ttTitles. ASSIGN ttTitles.cod_estab="901" ttTitles.num_id_tit_ap=7 ttTitles.cod_espec_docto="AF" ttTitles.cod_empresa="99" ttTitles.cdn_fornecedor=999 ttTitles.log_tit_ap_estordo=TRUE ttTitles.dat_emis_docto=DATE(1,1,1999). RELEASE ttTitles.
  CREATE ttTitleValues. ASSIGN ttTitleValues.cod_estab="901" ttTitleValues.num_id_tit_ap=7 ttTitleValues.cod_finalid_econ="corrente" ttTitleValues.val_origin_tit_ap=123.45678 ttTitleValues.val_pagto_tit_ap=50.12. RELEASE ttTitleValues.
  CREATE ttTitleValues. ASSIGN ttTitleValues.cod_estab="901" ttTitleValues.num_id_tit_ap=7 ttTitleValues.cod_finalid_econ="dolar" ttTitleValues.val_origin_tit_ap=25.125 ttTitleValues.val_pagto_tit_ap=10. RELEASE ttTitleValues.
  /* DI uses paid amount; missing currency purpose remains confirmed zero. */
  CREATE ttTitles. ASSIGN ttTitles.cod_estab="901" ttTitles.num_id_tit_ap=8 ttTitles.cod_espec_docto="DI". RELEASE ttTitles.
  CREATE ttTitleValues. ASSIGN ttTitleValues.cod_estab="901" ttTitleValues.num_id_tit_ap=8 ttTitleValues.cod_finalid_econ="corrente" ttTitleValues.val_origin_tit_ap=200 ttTitleValues.val_pagto_tit_ap=75.98765. RELEASE ttTitleValues.
  FIND ttMaster WHERE ttMaster.nr-container=123 EXCLUSIVE-LOCK.
  RUN CollectContainerPayments IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,OUTPUT rows).
  RUN Check(rows:Length=2,"container currency bridge returns only linked own title IDs").
  rowValue=PaymentRow(rows,7).
  RUN Check(rowValue:GetDecimal("vl_real")=123.45678 AND rowValue:GetDecimal("vl_dolar")=25.125,"container bridge preserves central AF original money precision").
  rowValue=PaymentRow(rows,8).
  RUN Check(rowValue:GetDecimal("vl_real")=75.98765 AND rowValue:GetDecimal("vl_dolar")=0,"container bridge preserves DI paid rule and absent-purpose zero").
  FIND ttPurchases WHERE ttPurchases.proc_compra_id=21 SHARE-LOCK.
  RUN CollectOrderPayments IN runtimeValue(INPUT BUFFER ttPurchases:HANDLE,OUTPUT rows).
  RUN Check(rows:Length=2,"order currency bridge maps only requested purchase title links").
  rowValue=PaymentRow(rows,7).
  RUN Check(rowValue:GetDecimal("vl_real")=123.45678 AND rowValue:GetDecimal("vl_dolar")=25.125,"order bridge delegates same AF currency values").
  rowValue=PaymentRow(rows,8).
  RUN Check(rowValue:GetDecimal("vl_real")=75.98765 AND rowValue:GetDecimal("vl_dolar")=0,"order bridge delegates same DI currency values").
  FIND ttTitleValues WHERE ttTitleValues.num_id_tit_ap=7 AND ttTitleValues.cod_finalid_econ="corrente" EXCLUSIVE-LOCK.
  ttTitleValues.val_origin_tit_ap=300.12345. RELEASE ttTitleValues.
  RUN CollectContainerPayments IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,OUTPUT rows).
  rowValue=PaymentRow(rows,7).
  RUN Check(rowValue:GetDecimal("vl_real")=300.12345,"next currency callback reads actual changed amount without cache").
 END.
 /* Ambiguous FIRST title lookup must throw and undo ancestor's test mutations. */
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTitles. ASSIGN ttTitles.cod_estab="902" ttTitles.num_id_tit_ap=7 ttTitles.cod_espec_docto="AF". RELEASE ttTitles.
  CREATE ttItemEffects. ASSIGN ttItemEffects.calc_imp_container_id=502 ttItemEffects.container_id=123. RELEASE ttItemEffects.
  FIND ttItems WHERE ttItems.item_container_id=1001 EXCLUSIVE-LOCK. ttItems.qt_alocada=31. RELEASE ttItems.
  FIND ttMaster WHERE ttMaster.nr-container=123 EXCLUSIVE-LOCK.
  RUN CollectContainerPayments IN runtimeValue(INPUT BUFFER ttMaster:HANDLE,OUTPUT rows).
  CATCH err AS Progress.Lang.Error: rejected=TRUE. errorText=err:GetMessage(1). END CATCH.
 END.
 RUN Check(rejected AND INDEX(errorText,"CONTAINER_PAYMENT_AMBIGUOUS")>0,"container bridge rejects title ID ambiguous across establishments").
 FIND ttTitles WHERE ttTitles.cod_estab="902" AND ttTitles.num_id_tit_ap=7 NO-ERROR.
 RUN Check(NOT AVAILABLE ttTitles,"ambiguous-title transaction rolls inserted duplicate back").
 FIND ttItemEffects WHERE ttItemEffects.calc_imp_container_id=502 NO-ERROR. RUN Check(NOT AVAILABLE ttItemEffects,"ambiguous-title transaction rolls synthetic effect back").
 FIND ttItems WHERE ttItems.item_container_id=1001. RUN Check(ttItems.qt_alocada=30,"ambiguous-title transaction rolls main quantity back"). RELEASE ttItems.
 /* A second row for one currency purpose is equally ambiguous through order. */
 rejected=FALSE. errorText="".
 DO TRANSACTION ON ERROR UNDO, THROW:
  CREATE ttTitleValues. ASSIGN ttTitleValues.cod_estab="901" ttTitleValues.num_id_tit_ap=7 ttTitleValues.cod_finalid_econ="corrente" ttTitleValues.num_id_movto_tit_ap=1 ttTitleValues.val_origin_tit_ap=9. RELEASE ttTitleValues.
  CREATE ttItemEffects. ASSIGN ttItemEffects.calc_imp_container_id=503 ttItemEffects.container_id=123. RELEASE ttItemEffects.
  FIND ttPurchases WHERE ttPurchases.proc_compra_id=21 SHARE-LOCK.
  RUN CollectOrderPayments IN runtimeValue(INPUT BUFFER ttPurchases:HANDLE,OUTPUT rows).
  CATCH err AS Progress.Lang.Error: rejected=TRUE. errorText=err:GetMessage(1). END CATCH.
 END.
 RUN Check(rejected AND INDEX(errorText,"CONTAINER_PAYMENT_AMBIGUOUS")>0,"order bridge rejects ambiguous currency FIRST value").
 FIND ttTitleValues WHERE ttTitleValues.num_id_tit_ap=7 AND ttTitleValues.num_id_movto_tit_ap=1 NO-ERROR.
 RUN Check(NOT AVAILABLE ttTitleValues,"ambiguous-purpose transaction rolls duplicate currency row back").
 FIND ttItemEffects WHERE ttItemEffects.calc_imp_container_id=503 NO-ERROR. RUN Check(NOT AVAILABLE ttItemEffects,"ambiguous-purpose transaction rolls effect back").
 FIND FIRST ttLedger NO-ERROR. RUN Check(NOT AVAILABLE ttLedger,"currency bridge performs no ledger writes or sequence allocations").
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersItensCrudService.p(INPUT BUFFER ttMaster:HANDLE,INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttDiscounts:HANDLE,INPUT BUFFER ttItemCosts:HANDLE,INPUT BUFFER ttCommercial:HANDLE,runtimeValue,policyValue,requestValue,OUTPUT responseValue).
END PROCEDURE.
PROCEDURE GetCapabilities:
 DEFINE OUTPUT PARAMETER caps AS JsonObject NO-UNDO.
 caps=NEW JsonObject(). caps:Add("contract","container-rules-v1"). caps:Add("onUpdate",TRUE).
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO. DEFINE VARIABLE beforeValue AS JsonObject NO-UNDO. DEFINE VARIABLE afterValue AS JsonObject NO-UNDO.
 IF NOT TRANSACTION OR NOT master:AVAILABLE OR ctx:GetInteger("container_id")<>123 THEN UNDO, THROW NEW Progress.Lang.AppError("Fiscal callback outside trusted transaction",1).
 fiscalCalls=fiscalCalls + 1.
 FIND ttItems WHERE ttItems.item_container_id=1001. ttItems.perc_ipi=17.5. RELEASE ttItems.
 CREATE ttItemEffects. ASSIGN ttItemEffects.calc_imp_container_id=501 ttItemEffects.container_id=123 ttItemEffects.descricao="controlled fiscal effect". RELEASE ttItemEffects.
 beforeValue=NEW JsonObject(). afterValue=NEW JsonObject(). afterValue:Add("calc_imp_container_id",501). afterValue:Add("container_id",123).
 eventValue=NEW JsonObject(). eventValue:Add("resource","calcs_imp_container"). eventValue:Add("operation","create"). eventValue:Add("recordId",501). eventValue:Add("before",beforeValue). eventValue:Add("after",afterValue).
 resultValue=NEW JsonObject(). resultValue:Add("success",TRUE). resultValue:Add("changes",NEW JsonArray()). resultValue:GetJsonArray("changes"):Add(eventValue). resultValue:Add("warnings",NEW JsonArray()).
END PROCEDURE.
