BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
{PurchasePaymentsFixture.i}
DEFINE VARIABLE requestData AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE a AS JsonArray NO-UNDO.
DEFINE VARIABLE o AS JsonObject NO-UNDO.
DEFINE VARIABLE rowData AS JsonObject NO-UNDO.
DEFINE VARIABLE keyValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE seqValue AS INTEGER NO-UNDO INITIAL 1000.
DEFINE VARIABLE failFinancial AS LOGICAL NO-UNDO.
DEFINE VARIABLE titleId AS INTEGER NO-UNDO.
DEFINE VARIABLE emptyText AS LONGCHAR NO-UNDO.
OUTPUT TO VALUE("purchase-payments-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 RUN Seed. requestData=NEW JsonObject(). requestData:Add("operation","available"). requestData:Add("proc_compra_id",101). RUN Invoke.
 RUN Check(response:GetLogical("success") AND response:GetJsonArray("data"):Length=2,"available scope company supplier date reversal and unambiguous identity").
 RUN AvailableCases.
 RUN Seed.
 RUN CreateRequest(600,601). RUN Invoke.
 RUN Check(response:GetLogical("success") AND response:GetLogical("committed"),"multi-title association committed").
 response:WriteFile("purchase-audit-create-" + SESSION:NUMERIC-FORMAT + ".json",TRUE).
 RUN Check(CAN-FIND(ttOrderPayments WHERE ttOrderPayments.proc_compra_id=101 AND ttOrderPayments.num_id_tit_ap=600) AND CAN-FIND(ttOrderPayments WHERE ttOrderPayments.num_id_tit_ap=601),"both links persisted").
 RUN Check(response:GetJsonObject("audit"):GetJsonArray("changes"):Length=6,"links and all four financial plans captured").
 FIND ttLedger WHERE ttLedger.cta_corren_fornec_imp_id=1001.
 RUN Check(ttLedger.login="test-purchase" AND ttLedger.cod_tipo_movto=4 AND ttLedger.vl_lancto=-75,"shared rateio physical actor and value").
 rowData=response:GetJsonObject("data"). keyValue=rowData:GetCharacter("pagamento_key").
 RUN Check(rowData:GetInteger("proc_compra_id")=101 AND rowData:GetJsonArray("titulos"):GetInteger(1)=600,"create returns native selector/detail row").
 RUN CreateRequest(600,0). RUN Invoke. RUN Check(NOT response:GetLogical("success"),"cannot duplicate existing association").
 requestData=NEW JsonObject(). requestData:Add("operation","delete"). requestData:Add("proc_compra_id",101). requestData:Add("id",keyValue). RUN Invoke.
 RUN Check(response:GetLogical("success") AND NOT CAN-FIND(ttOrderPayments WHERE ttOrderPayments.num_id_tit_ap=600),"disassociation removes only requested link").
 RUN Check(CAN-FIND(ttOrderPayments WHERE ttOrderPayments.num_id_tit_ap=601),"other title link preserved").
 response:GetJsonObject("audit"):GetJsonObject("after"):Write(emptyText,FALSE).
 RUN Check(response:GetJsonObject("audit"):GetJsonObject("before"):GetInteger("num_id_tit_ap")=600 AND TRIM(STRING(emptyText))="~{~}","physical before and empty after deletion").
 RUN Seed. RUN CreateRequest(600,602). RUN Invoke.
 RUN Check(NOT response:GetLogical("success") AND NOT CAN-FIND(FIRST ttOrderPayments) AND NOT CAN-FIND(FIRST ttLedger),"second ineligible title rolls back earlier link and every ledger").
 RUN Seed. failFinancial=TRUE. RUN CreateRequest(600,0). RUN Invoke.
 RUN Check(NOT response:GetLogical("success") AND NOT CAN-FIND(FIRST ttOrderPayments) AND NOT CAN-FIND(FIRST ttLedger),"participant failure after effects rolls back root").
 RUN Seed. RUN CreateRequest(600,600). RUN Invoke. RUN Check(NOT response:GetLogical("success") AND NOT CAN-FIND(FIRST ttOrderPayments),"duplicate selection rejected").
 RUN Seed. CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=600 ttTitles.cod_estab="502" ttTitles.cod_empresa="500".
 RUN CreateRequest(600,0). RUN Invoke. RUN Check(NOT response:GetLogical("success") AND NOT CAN-FIND(FIRST ttOrderPayments),"ambiguous title ID rejected before association").
 RUN Seed. RUN CreateRequest(600,0). requestData:Set("proc_compra_id",102). RUN Invoke.
 RUN Check(NOT response:GetLogical("success") AND NOT CAN-FIND(FIRST ttOrderPayments),"other company parent cannot be selected").
 RUN Seed. RUN CreateRequest(600,0). requestData:Add("actor","forged"). RUN Invoke. RUN Check(NOT response:GetLogical("success"),"browser cannot supply actor").
 RUN Seed. RUN CreateRequest(600,0). requestData:GetJsonObject("values"):Add("usuario","spoof"). RUN Invoke. RUN Check(NOT response:GetLogical("success"),"unknown write values refused").
 RUN Seed. RUN CreateRequest(600,0). requestData:GetJsonObject("values"):GetJsonArray("titulos"):Set(1,600.5). RUN Invoke. RUN Check(NOT response:GetLogical("success"),"fractional selected ID refused").
 RUN Seed. RUN CreateRequest(600,0). a=requestData:GetJsonObject("values"):GetJsonArray("titulos"). DO titleId=1 TO 101: a:Add(titleId). END. RUN Invoke. RUN Check(NOT response:GetLogical("success"),"over100 selected titles refused").
 RUN Seed. RUN CreateRequest(600,0). policy:GetJsonObject("actor"):Set("login",""). RUN Invoke. RUN Check(NOT response:GetLogical("success") AND NOT CAN-FIND(FIRST ttOrderPayments),"no write without authenticated actor").
 RUN Seed. RUN CreateRequest(600,0). requestData:Set("proc_compra_id",999). RUN Invoke. RUN Check(NOT response:GetLogical("success"),"missing parent refused").
 RUN Seed. RUN CreateRequest(600,0). FIND ttTitles WHERE ttTitles.num_id_tit_ap=600. ttTitles.log_tit_ap_estordo=TRUE. RUN Invoke. RUN Check(NOT response:GetLogical("success"),"reversed title refused").
 RUN Seed. RUN CreateRequest(600,0). FIND ttTitles WHERE ttTitles.num_id_tit_ap=600. ttTitles.dat_emis_docto=DATE(1,1,2025). RUN Invoke. RUN Check(NOT response:GetLogical("success"),"title predates purchase registration refused").
 RUN Seed. RUN CreateRequest(600,0). FIND ttTitles WHERE ttTitles.num_id_tit_ap=600. ttTitles.cdn_fornecedor=22. RUN Invoke. RUN Check(NOT response:GetLogical("success"),"title of different supplier refused").
 PUT UNFORMATTED "PASS " checks " checks " SESSION:NUMERIC-FORMAT SKIP.
 CATCH e AS Progress.Lang.Error:
  PUT UNFORMATTED "FAIL after " checks ": " e:GetMessage(1) SKIP.
  IF VALID-OBJECT(response) THEN PUT UNFORMATTED STRING(response:GetJsonText()) SKIP.
  OUTPUT CLOSE. UNDO, THROW e.
 END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE Seed:
 DO TRANSACTION:
  EMPTY TEMP-TABLE ttPurchases. EMPTY TEMP-TABLE ttCompanies. EMPTY TEMP-TABLE ttTitles. EMPTY TEMP-TABLE ttValues.
  EMPTY TEMP-TABLE ttOrderPayments. EMPTY TEMP-TABLE ttLedger. EMPTY TEMP-TABLE ttPurchaseItems.
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=2 ttCompanies.cod_emp_ems2=5 ttCompanies.cod_emp_ems5=500 ttCompanies.nome="MED".
  CREATE ttCompanies. ASSIGN ttCompanies.empresa_id=1 ttCompanies.cod_emp_ems2=1 ttCompanies.cod_emp_ems5=100 ttCompanies.nome="IMA".
  CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=101 ttPurchases.empresa_id=2 ttPurchases.fornecedor_id=11 ttPurchases.dt_registro=DATE(1,1,2026).
  CREATE ttPurchases. ASSIGN ttPurchases.proc_compra_id=102 ttPurchases.empresa_id=1 ttPurchases.fornecedor_id=11 ttPurchases.dt_registro=DATE(1,1,2026).
  CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=101 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_negociado=3.
  CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=13 ttPurchaseItems.proc_compra_id=101 ttPurchaseItems.qt_comprada=100 ttPurchaseItems.vl_negociado=1.
  DO titleId=600 TO 602:
   CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=titleId ttTitles.cod_estab="501" ttTitles.cod_empresa=(IF titleId=602 THEN "100" ELSE "500") ttTitles.cod_espec_docto="AF"
    ttTitles.cdn_fornecedor=11 ttTitles.cod_tit_ap=STRING(titleId) ttTitles.cod_parcela="01" ttTitles.dat_emis_docto=DATE(10,22,2026) ttTitles.dat_vencto_tit_ap=DATE(11,1,2026)
    ttTitles.cod_indic_econ="USD" ttTitles.val_origin_tit_ap=100 ttTitles.ind_tip_espec_docto="Antecipacao".
   CREATE ttValues. ASSIGN ttValues.cod_estab="501" ttValues.num_id_tit_ap=titleId ttValues.cod_finalid_econ="dolar" ttValues.val_origin_tit_ap=100.
   CREATE ttValues. ASSIGN ttValues.cod_estab="501" ttValues.num_id_tit_ap=titleId ttValues.cod_finalid_econ="corrente" ttValues.val_origin_tit_ap=500.
  END.
 END.
 actor=NEW JsonObject(). actor:Add("login","test-purchase"). policy=NEW JsonObject(). policy:Add("actor",actor).
 financePolicy=NEW JsonObject(). a=NEW JsonArray(). a:Add("AF"). financePolicy:Add("adiantamentos",a). a=NEW JsonArray(). a:Add("DI"). financePolicy:Add("titulos",a).
 seqValue=1000. failFinancial=FALSE.
END PROCEDURE.
PROCEDURE AvailableCases:
 /* A linked ID is not a candidate: even a second establishment must not make
    this unrelated option fail. All unlinked IDs still require global identity. */
 RUN Seed. CREATE ttOrderPayments. ASSIGN ttOrderPayments.proc_compra_id=999 ttOrderPayments.num_id_tit_ap=600.
 CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=600 ttTitles.cod_estab="999" ttTitles.cod_empresa="100".
 requestData=NEW JsonObject(). requestData:Add("operation","available"). requestData:Add("proc_compra_id",101). RUN Invoke.
 RUN Check(response:GetLogical("success") AND response:GetJsonArray("data"):Length=1 AND response:GetJsonArray("data"):GetJsonObject(1):GetInteger("num_id_tit_ap")=601,"available excludes linked IDs before global identity validation").
 RUN Seed. CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=601 ttTitles.cod_estab="999" ttTitles.cod_empresa="100" ttTitles.cdn_fornecedor=22.
 requestData=NEW JsonObject(). requestData:Add("operation","available"). requestData:Add("proc_compra_id",101). RUN Invoke.
 RUN Check(NOT response:GetLogical("success") AND response:GetJsonObject("error"):GetCharacter("code")="PURCHASE_PAYMENT_AMBIGUOUS" AND NOT response:Has("data"),"available rejects global ambiguity outside scope without partial rows").
 RUN Seed.
 DO titleId=1000 TO 1997:
  CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=titleId ttTitles.cod_estab="501" ttTitles.cod_empresa="500" ttTitles.cdn_fornecedor=11
   ttTitles.cod_tit_ap=STRING(titleId) ttTitles.dat_emis_docto=DATE(10,22,2026) ttTitles.ind_tip_espec_docto="Antecipacao".
 END.
 requestData=NEW JsonObject(). requestData:Add("operation","available"). requestData:Add("proc_compra_id",101). RUN Invoke.
 RUN Check(response:GetLogical("success") AND response:GetJsonArray("data"):Length=1000,"available accepts exactly1000 scoped unlinked options").
 CREATE ttTitles. ASSIGN ttTitles.num_id_tit_ap=1998 ttTitles.cod_estab="501" ttTitles.cod_empresa="500" ttTitles.cdn_fornecedor=11
  ttTitles.cod_tit_ap="1998" ttTitles.dat_emis_docto=DATE(10,22,2026) ttTitles.ind_tip_espec_docto="Antecipacao".
 RUN Invoke.
 RUN Check(NOT response:GetLogical("success") AND response:GetJsonObject("error"):GetCharacter("code")="PURCHASE_PAYMENT_TOO_MANY" AND NOT response:Has("data"),"available over1000 fails without partial rows").
END PROCEDURE.
PROCEDURE CreateRequest:
 DEFINE INPUT PARAMETER firstId AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER secondId AS INTEGER NO-UNDO.
 requestData=NEW JsonObject(). requestData:Add("operation","create"). requestData:Add("proc_compra_id",101). o=NEW JsonObject(). a=NEW JsonArray(). a:Add(firstId). IF secondId>0 THEN a:Add(secondId). o:Add("titulos",a). requestData:Add("values",o).
END PROCEDURE.
PROCEDURE Invoke:
 RUN VALUE("PurchasePaymentsService.p")(INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttCompanies:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttTitles:HANDLE,INPUT BUFFER ttValues:HANDLE,THIS-PROCEDURE,policy,financePolicy,requestData,OUTPUT response).
END PROCEDURE.
PROCEDURE RunOrderFinancial:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 RUN ContainersItensFinanceiroService.p(INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,INPUT BUFFER ttLedger:HANDLE,INPUT BUFFER ttOrderPayments:HANDLE,INPUT BUFFER ttContainerPayments:HANDLE,INPUT BUFFER ttAllContainers:HANDLE,THIS-PROCEDURE,policy,ctx,OUTPUT result).
 IF failFinancial THEN UNDO, THROW NEW Progress.Lang.AppError("Injected after financial persistence",1).
END PROCEDURE.
PROCEDURE NextLedgerId: DEFINE OUTPUT PARAMETER id AS INTEGER NO-UNDO. seqValue=seqValue + 1. id=seqValue. END PROCEDURE.
PROCEDURE CollectOrderPayments:
 DEFINE INPUT PARAMETER purchase AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER rows AS JsonArray NO-UNDO. DEFINE VARIABLE item AS JsonObject NO-UNDO.
 rows=NEW JsonArray(). FOR EACH ttOrderPayments WHERE ttOrderPayments.proc_compra_id=101:
  item=NEW JsonObject(). item:Add("num_id_tit_ap",ttOrderPayments.num_id_tit_ap). item:Add("vl_dolar",100). item:Add("vl_real",500). rows:Add(item).
 END.
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER msg AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(msg,1). checks=checks + 1.
END PROCEDURE.
