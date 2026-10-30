/* Temp-table-only tests for the private cost payment collector. Never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttContainer NO-UNDO FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttPagtos NO-UNDO FIELD container_id AS INTEGER FIELD num_id_tit_ap AS INTEGER
  INDEX pk IS UNIQUE PRIMARY num_id_tit_ap container_id.
DEFINE TEMP-TABLE ttTit NO-UNDO FIELD num_id_tit_ap AS INTEGER FIELD cod_estab AS CHARACTER FIELD cod_espec_docto AS CHARACTER
  FIELD log_tit_ap_estordo AS LOGICAL FIELD cod_empresa AS CHARACTER FIELD cdn_fornecedor AS INTEGER FIELD dat_emis_docto AS DATE
  INDEX token IS UNIQUE PRIMARY cod_estab num_id_tit_ap.
DEFINE TEMP-TABLE ttVal NO-UNDO FIELD cod_estab AS CHARACTER FIELD num_id_tit_ap AS INTEGER
  FIELD num_id_movto_tit_ap AS INTEGER FIELD cod_finalid_econ AS CHARACTER FIELD cod_unid_negoc AS CHARACTER FIELD cod_tip_fluxo_financ AS CHARACTER
  FIELD val_origin_tit_ap AS DECIMAL DECIMALS 10 FIELD val_pagto_tit_ap AS DECIMAL DECIMALS 10
  INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap num_id_movto_tit_ap cod_finalid_econ cod_unid_negoc cod_tip_fluxo_financ.
DEFINE VARIABLE joPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE joData AS JsonObject NO-UNDO.
DEFINE VARIABLE ja As JsonArray NO-UNDO.
DEFINE VARIABLE iContainer AS INTEGER NO-UNDO INITIAL 71.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.
OUTPUT TO VALUE("container-payment-totals-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
  joPolicy=NEW JsonObject(). ja=NEW JsonArray(). ja:Add("AF"). joPolicy:Add("adiantamentos",ja).
  ja=NEW JsonArray(). ja:Add("DI"). joPolicy:Add("titulos",ja).
  RUN ExecuteRequest. RUN ExpectError("CONTAINER_NOT_FOUND").
  CREATE ttContainer. ttContainer.nr-container=71.
  CREATE ttContainer. ttContainer.nr-container=72.
  RUN ExecuteRequest. joData=joResponse:GetJsonObject("data").
  RUN AssertTrue(joData:GetJsonObject("payments"):GetDecimal("real")=0 AND joData:GetJsonObject("payments"):GetDecimal("dolar")=0,"no linked payments has exact zero totals").
  RUN AssertTrue(joData:GetLogical("confirmed") AND joData:GetCharacter("source")="linked-payment-totals","private provenance explicit").
  RUN AssertTrue(NOT joData:Has("payment_rows"),"default payment helper response unchanged").
  CREATE ttPagtos. ASSIGN ttPagtos.container_id=71 ttPagtos.num_id_tit_ap=5.
  CREATE ttTit. ASSIGN ttTit.cod_estab="901" ttTit.num_id_tit_ap=5 ttTit.cod_espec_docto="AF"
    ttTit.log_tit_ap_estordo=TRUE ttTit.cod_empresa="99" ttTit.cdn_fornecedor=999 ttTit.dat_emis_docto=DATE(1,1,1999).
  CREATE ttVal. ASSIGN ttVal.cod_estab="901" ttVal.num_id_tit_ap=5 ttVal.cod_finalid_econ="corrente"
    ttVal.val_origin_tit_ap=123.45678 ttVal.val_pagto_tit_ap=50.12.
  CREATE ttVal. ASSIGN ttVal.cod_estab="901" ttVal.num_id_tit_ap=5 ttVal.cod_finalid_econ="dolar"
    ttVal.val_origin_tit_ap=25.125 ttVal.val_pagto_tit_ap=10.
  RUN ExecuteRequest. joData=joResponse:GetJsonObject("data").
  RUN AssertTrue(joData:GetJsonObject("payments"):GetDecimal("real")=123.45678 AND joData:GetJsonObject("payments"):GetDecimal("dolar")=25.125,"cost totals do not copy grid filters for old reversed other-company supplier title").
  /* Same title linked to another parent is not counted a second time. */
  CREATE ttPagtos. ASSIGN ttPagtos.container_id=72 ttPagtos.num_id_tit_ap=5.
  CREATE ttTit. ASSIGN ttTit.cod_estab="901" ttTit.num_id_tit_ap=6 ttTit.cod_espec_docto="DI".
  CREATE ttVal. ASSIGN ttVal.cod_estab="901" ttVal.num_id_tit_ap=6 ttVal.cod_finalid_econ="corrente"
    ttVal.val_origin_tit_ap=200 ttVal.val_pagto_tit_ap=75.98765.
  RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetJsonObject("payments"):GetDecimal("real")=123.45678,"unlinked title excluded").
  CREATE ttPagtos. ASSIGN ttPagtos.container_id=71 ttPagtos.num_id_tit_ap=6.
  RUN ExecuteRequest. joData=joResponse:GetJsonObject("data").
  RUN AssertTrue(joData:GetJsonObject("payments"):GetDecimal("real")=199.44443 AND joData:GetJsonObject("payments"):GetDecimal("dolar")=25.125,"currency formulas sum only linked IDs and missing purpose preserves legacy zero").
  CREATE ttTit. ASSIGN ttTit.cod_estab="902" ttTit.num_id_tit_ap=5 ttTit.cod_espec_docto="AF".
  RUN ExecuteRequest. RUN ExpectError("CONTAINER_PAYMENT_AMBIGUOUS").
  FIND ttTit WHERE ttTit.cod_estab="902" AND ttTit.num_id_tit_ap=5. DELETE ttTit.
  CREATE ttVal. ASSIGN ttVal.cod_estab="901" ttVal.num_id_tit_ap=5 ttVal.cod_finalid_econ="corrente" ttVal.num_id_movto_tit_ap=1.
  RUN ExecuteRequest. RUN ExpectError("CONTAINER_PAYMENT_AMBIGUOUS").
  FIND ttVal WHERE ttVal.cod_estab="901" AND ttVal.num_id_tit_ap=5 AND ttVal.cod_finalid_econ="corrente" AND ttVal.num_id_movto_tit_ap=1. DELETE ttVal.
  FIND ttVal WHERE ttVal.cod_estab="901" AND ttVal.num_id_tit_ap=5 AND ttVal.cod_finalid_econ="corrente". ttVal.val_origin_tit_ap=?.
  RUN ExecuteRequest. RUN ExpectError("CONTAINER_PAYMENT_VALUE_UNKNOWN").
  FIND ttVal WHERE ttVal.cod_estab="901" AND ttVal.num_id_tit_ap=5 AND ttVal.cod_finalid_econ="corrente". ttVal.val_origin_tit_ap=300.12345.
  RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetJsonObject("payments"):GetDecimal("real")=376.1111,"fresh values read each call").
  joPolicy:Add("capture_rows",TRUE). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"private row capture succeeds").
  ja=joResponse:GetJsonObject("data"):GetJsonArray("payment_rows").
  RUN AssertTrue(ja:Length=2,"one snapshot per linked title only").
  RUN AssertTrue(ja:GetJsonObject(1):GetInteger("num_id_tit_ap")=5 AND ja:GetJsonObject(1):GetDecimal("vl_real")=300.12345 AND ja:GetJsonObject(1):GetDecimal("vl_dolar")=25.125,"snapshot reuses selected currency values without recalculation").
  RUN AssertTrue(ja:GetJsonObject(2):GetInteger("num_id_tit_ap")=6 AND ja:GetJsonObject(2):GetDecimal("vl_real")=75.98765 AND ja:GetJsonObject(2):GetDecimal("vl_dolar")=0,"missing purpose retains same confirmed zero in snapshot").
  joPolicy:Set("capture_rows",1). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CONFIGURATION").
  joPolicy:Set("capture_rows",FALSE). RUN ExecuteRequest.
  RUN AssertTrue(NOT joResponse:GetJsonObject("data"):Has("payment_rows"),"false capture preserves legacy shape").
  CREATE ttPagtos. ASSIGN ttPagtos.container_id=71 ttPagtos.num_id_tit_ap=99.
  RUN ExecuteRequest. RUN ExpectError("CONTAINER_PAYMENT_NOT_FOUND").
  FIND ttPagtos WHERE ttPagtos.container_id=71 AND ttPagtos.num_id_tit_ap=99. DELETE ttPagtos.
  iContainer=0. RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION").
  iContainer=?. RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION").
  PUT UNFORMATTED "PASS: " iPassed " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
  CATCH e AS Progress.Lang.Error:
    PUT UNFORMATTED "FAIL after " iPassed " checks: " e:GetMessage(1) SKIP.
    IF VALID-OBJECT(joResponse) THEN PUT UNFORMATTED STRING(joResponse:GetJsonText()) SKIP.
    OUTPUT CLOSE. UNDO, THROW e.
  END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE ExecuteRequest:
  IF VALID-OBJECT(joResponse) THEN DELETE OBJECT joResponse.
  RUN ContainersPagamentoTotalsService.p (INPUT BUFFER ttContainer:HANDLE, INPUT BUFFER ttPagtos:HANDLE,
    INPUT BUFFER ttTit:HANDLE,INPUT BUFFER ttVal:HANDLE,INPUT joPolicy,INPUT iContainer,OUTPUT joResponse).
END PROCEDURE.
PROCEDURE AssertTrue:
  DEFINE INPUT PARAMETER plValue AS LOGICAL NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  IF plValue<>TRUE OR plValue=? THEN UNDO, THROW NEW Progress.Lang.AppError(pcMessage,0).
  iPassed=iPassed + 1.
END PROCEDURE.
PROCEDURE ExpectError:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  RUN AssertTrue(NOT joResponse:GetLogical("success"),"expected failure").
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetCharacter("code")=pcCode,"code " + pcCode).
  RUN AssertTrue(NOT joResponse:Has("data"),"no partial confirmed data").
END PROCEDURE.
