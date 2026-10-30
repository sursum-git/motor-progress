/* Only temp-tables; no business database connection or write. Never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttContainer NO-UNDO
  FIELD nr-container AS INTEGER FIELD cod-estabel AS CHARACTER FIELD cod-emit-forn AS INTEGER
  INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttEmpresas NO-UNDO
  FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER
  INDEX pk IS UNIQUE PRIMARY empresa_id.
DEFINE TEMP-TABLE ttItens NO-UNDO
  FIELD item_container_id AS INTEGER FIELD container_id AS INTEGER FIELD item_proc_compra_id AS INTEGER
  INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttItensCompra NO-UNDO
  FIELD item_proc_compra_id AS INTEGER FIELD proc_compra_id AS INTEGER
  INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttCompra NO-UNDO
  FIELD proc_compra_id AS INTEGER FIELD fornecedor_id AS INTEGER FIELD dt_registro AS DATE
  INDEX pk IS UNIQUE PRIMARY proc_compra_id.
DEFINE TEMP-TABLE ttPagtos NO-UNDO
  FIELD num_id_tit_ap AS INTEGER FIELD container_id AS INTEGER
  INDEX pk IS UNIQUE PRIMARY num_id_tit_ap container_id.
DEFINE TEMP-TABLE ttTit NO-UNDO
  FIELD num_id_tit_ap AS INTEGER FIELD cod_estab AS CHARACTER FIELD cod_empresa AS CHARACTER
  FIELD log_tit_ap_estordo AS LOGICAL FIELD cdn_fornecedor AS INTEGER
  FIELD ind_tip_espec_docto AS CHARACTER FIELD log_sdo_tit_ap AS LOGICAL
  FIELD cod_espec_docto AS CHARACTER FIELD cod_ser_docto AS CHARACTER FIELD cod_tit_ap AS CHARACTER
  FIELD cod_parcela AS CHARACTER FIELD dat_emis_docto AS DATE FIELD dat_vencto_tit_ap AS DATE
  FIELD cod_indic_econ AS CHARACTER FIELD val_origin_tit_ap AS DECIMAL DECIMALS 10
  INDEX token IS UNIQUE PRIMARY cod_estab num_id_tit_ap.
DEFINE TEMP-TABLE ttVal NO-UNDO
  FIELD cod_estab AS CHARACTER FIELD num_id_tit_ap AS INTEGER FIELD num_id_movto_tit_ap AS INTEGER
  FIELD cod_finalid_econ AS CHARACTER FIELD cod_unid_negoc AS CHARACTER FIELD cod_tip_fluxo_financ AS CHARACTER
  FIELD val_origin_tit_ap AS DECIMAL DECIMALS 10 FIELD val_pagto_tit_ap AS DECIMAL DECIMALS 10
  INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap num_id_movto_tit_ap cod_finalid_econ cod_unid_negoc cod_tip_fluxo_financ.
DEFINE TEMP-TABLE ttNfs NO-UNDO
  FIELD documento AS CHARACTER FIELD serie AS CHARACTER FIELD estab AS CHARACTER
  FIELD nat_operacao AS CHARACTER FIELD cod_emitente AS INTEGER FIELD container_id AS INTEGER
  INDEX pk IS UNIQUE PRIMARY documento serie estab nat_operacao cod_emitente container_id.
DEFINE TEMP-TABLE ttDoc NO-UNDO
  FIELD cod-estabel AS CHARACTER FIELD nro-docto AS CHARACTER FIELD esp-docto AS INTEGER
  FIELD serie-docto AS CHARACTER FIELD cod-emitente AS INTEGER FIELD dt-emissao AS DATE FIELD dt-trans AS DATE
  FIELD nat-operacao AS CHARACTER FIELD tot-valor AS DECIMAL DECIMALS 10 FIELD despesa-nota AS DECIMAL DECIMALS 10
  FIELD valor-embal AS DECIMAL DECIMALS 10 FIELD valor-frete AS DECIMAL DECIMALS 10
  FIELD valor-mercad AS DECIMAL DECIMALS 10 FIELD valor-outras AS DECIMAL DECIMALS 10 FIELD valor-seguro AS DECIMAL DECIMALS 10
  INDEX pk IS UNIQUE PRIMARY serie-docto nro-docto cod-emitente nat-operacao.
DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE joPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE joRow AS JsonObject NO-UNDO.
DEFINE VARIABLE jaRows AS JsonArray NO-UNDO.
DEFINE VARIABLE jaSpecies AS JsonArray NO-UNDO.
DEFINE VARIABLE cPayKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNfKey AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cResource AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.
DEFINE VARIABLE noNfBuffers AS LOGICAL NO-UNDO.
OUTPUT TO VALUE("container-panel-finance-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
  joPolicy=NEW JsonObject(). jaSpecies=NEW JsonArray(). jaSpecies:Add("AF"). joPolicy:Add("adiantamentos",jaSpecies).
  jaSpecies=NEW JsonArray(). jaSpecies:Add("DI"). joPolicy:Add("titulos",jaSpecies).
  RUN Request("read","pagamentos",71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_NOT_FOUND",404).
  RUN Request("read","nfs",71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_NOT_FOUND",404).
  CREATE ttContainer. ASSIGN ttContainer.nr-container=71 ttContainer.cod-estabel="501" ttContainer.cod-emit-forn=51.
  CREATE ttContainer. ASSIGN ttContainer.nr-container=72 ttContainer.cod-estabel="501" ttContainer.cod-emit-forn=61.
  CREATE ttEmpresas. ASSIGN ttEmpresas.empresa_id=35 ttEmpresas.cod_emp_ems2=5 ttEmpresas.cod_emp_ems5=9.
  CREATE ttItens. ASSIGN ttItens.item_container_id=1 ttItens.container_id=71 ttItens.item_proc_compra_id=11.
  CREATE ttItensCompra. ASSIGN ttItensCompra.item_proc_compra_id=11 ttItensCompra.proc_compra_id=21.
  CREATE ttCompra. ASSIGN ttCompra.proc_compra_id=21 ttCompra.fornecedor_id=51 ttCompra.dt_registro=DATE(1,10,2026).
  /* Same title number in two establishments proves composite identity and value join. */
  CREATE ttPagtos. ASSIGN ttPagtos.num_id_tit_ap=5 ttPagtos.container_id=71.
  CREATE ttTit. ASSIGN ttTit.num_id_tit_ap=5 ttTit.cod_estab="901" ttTit.cod_empresa="9"
    ttTit.cdn_fornecedor=51 ttTit.dat_emis_docto=DATE(1,10,2026) ttTit.dat_vencto_tit_ap=DATE(12,31,2026)
    ttTit.cod_espec_docto="AF" ttTit.cod_tit_ap="AÇÃO-005" ttTit.val_origin_tit_ap=9999.
  CREATE ttTit. ASSIGN ttTit.num_id_tit_ap=5 ttTit.cod_estab="902" ttTit.cod_empresa="9"
    ttTit.cdn_fornecedor=51 ttTit.dat_emis_docto=DATE(1,10,2026) ttTit.cod_espec_docto="DI".
  CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=5 ttVal.cod_estab="901" ttVal.cod_finalid_econ="corrente"
    ttVal.val_origin_tit_ap=123.45678 ttVal.val_pagto_tit_ap=50.12.
  CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=5 ttVal.cod_estab="901" ttVal.cod_finalid_econ="dolar"
    ttVal.val_origin_tit_ap=25.125 ttVal.val_pagto_tit_ap=10.
  CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=5 ttVal.cod_estab="902" ttVal.cod_finalid_econ="corrente"
    ttVal.val_origin_tit_ap=200 ttVal.val_pagto_tit_ap=75.98765.
  CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=5 ttVal.cod_estab="902" ttVal.cod_finalid_econ="dolar"
    ttVal.val_origin_tit_ap=40 ttVal.val_pagto_tit_ap=15.2.
  RUN Request("read","pagamentos",71,""). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"payment read success").
  jaRows=joResponse:GetJsonArray("data"). RUN AssertTrue(jaRows:Length=2,"same title in two establishments retained").
  joRow=jaRows:GetJsonObject(1). cPayKey=joRow:GetCharacter("pagamento_key").
  RUN AssertTrue(LENGTH(cPayKey)=66 AND SUBSTRING(cPayKey,1,2)="p_","opaque stable payment key").
  RUN AssertTrue(joRow:GetDecimal("valor_real")=123.45678 AND joRow:GetDecimal("valor_dolar")=25.125,"advance uses original each currency").
  RUN AssertTrue(joRow:GetCharacter("valor_real_origem")="original" AND joRow:GetInteger("valor_real_registros")=1,"payment numeric origin explicit").
  RUN AssertTrue(joRow:GetCharacter("cod_tit_ap")="AÇÃO-005" AND joRow:GetCharacter("data_inicio_filtro")="2026-01-10","UTF8 and minimum purchase registration date").
  RUN AssertTrue(joRow:GetCharacter("data_inicio_origem")="pedidos","date origin explicit").
  RUN CheckFields("container_id,pagamento_key,num_id_tit_ap,cod_estab,cod_empresa,cod_espec_docto,cod_ser_docto,cdn_fornecedor,cod_tit_ap,cod_parcela,dat_emis_docto,dat_vencto_tit_ap,cod_indic_econ,val_origin_tit_ap,valor_real,valor_dolar,valor_real_origem,valor_dolar_origem,valor_real_registros,valor_dolar_registros,data_inicio_filtro,data_inicio_origem").
  joRow=jaRows:GetJsonObject(2).
  RUN AssertTrue(joRow:GetDecimal("valor_real")=75.98765 AND joRow:GetDecimal("valor_dolar")=15.2,"DI uses paid and exact establishment").
  RUN AssertTrue(joRow:GetCharacter("pagamento_key")<>cPayKey,"payment IDs distinct across establishments").
  RUN Request("get","pagamentos",71,cPayKey). joRequest:Add("pagamento_key",cPayKey). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetCharacter("pagamento_key")=cPayKey,"payment get shape and alias").
  RUN Request("get","pagamentos",72,cPayKey). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).

  /* No linkage, reversed titles, other company, date before import and wrong supplier are excluded. */
  DO i=6 TO 10:
    CREATE ttTit. ASSIGN ttTit.num_id_tit_ap=i ttTit.cod_estab="901" ttTit.cod_empresa="9"
      ttTit.cdn_fornecedor=51 ttTit.dat_emis_docto=DATE(1,10,2026).
    IF i<>6 THEN DO: CREATE ttPagtos. ASSIGN ttPagtos.num_id_tit_ap=i ttPagtos.container_id=71. END.
    CASE i:
      WHEN 7 THEN ttTit.log_tit_ap_estordo=TRUE.
      WHEN 8 THEN ttTit.cod_empresa="1".
      WHEN 9 THEN ttTit.dat_emis_docto=DATE(1,9,2026).
      WHEN 10 THEN ttTit.cdn_fornecedor=61.
    END CASE.
  END.
  RUN Request("read","pagamentos",71,""). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonArray("data"):Length=2,"payment mandatory scope, company, supplier, date and reversal filters").
  /* Multiple value rows are not summed: explicit deterministic order and count. */
  CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=5 ttVal.cod_estab="901" ttVal.cod_finalid_econ="corrente"
    ttVal.num_id_movto_tit_ap=9 ttVal.val_origin_tit_ap=800 ttVal.val_pagto_tit_ap=900.
  RUN Request("get","pagamentos",71,cPayKey). RUN ExecuteRequest. joRow=joResponse:GetJsonObject("data").
  RUN AssertTrue(joRow:GetDecimal("valor_real")=123.45678 AND joRow:GetInteger("valor_real_registros")=2,"multiple movements not incorrectly aggregated").
  FIND ttTit WHERE ttTit.cod_estab="901" AND ttTit.num_id_tit_ap=5. ttTit.cod_espec_docto="XX".
  RUN Request("get","pagamentos",71,cPayKey). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetDecimal("valor_real")=50.12,"unconfigured species numeric fallback paid").
  FIND ttVal WHERE ttVal.cod_estab="901" AND ttVal.num_id_tit_ap=5 AND ttVal.cod_finalid_econ="corrente" AND ttVal.num_id_movto_tit_ap=0.
  ttVal.val_pagto_tit_ap=0.
  RUN Request("get","pagamentos",71,cPayKey). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetDecimal("valor_real")=123.45678,"zero paid falls back original").
  FIND ttTit WHERE ttTit.cod_estab="901" AND ttTit.num_id_tit_ap=5. ttTit.cod_espec_docto="AF".
  FIND ttVal WHERE ttVal.cod_estab="901" AND ttVal.num_id_tit_ap=5 AND ttVal.cod_finalid_econ="corrente" AND ttVal.num_id_movto_tit_ap=0.
  ttVal.val_origin_tit_ap=?.
  RUN Request("get","pagamentos",71,cPayKey). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):IsNull("valor_real"),"unknown financial value preserved").
  FIND ttVal WHERE ttVal.cod_estab="901" AND ttVal.num_id_tit_ap=5 AND ttVal.cod_finalid_econ="dolar". DELETE ttVal.
  RUN Request("get","pagamentos",71,cPayKey). RUN ExecuteRequest. joRow=joResponse:GetJsonObject("data").
  RUN AssertTrue(joRow:GetDecimal("valor_dolar")=0 AND joRow:GetCharacter("valor_dolar_origem")="ausente","missing currency explicit zero and origin").
  /* Internal policy can change between calls; no cache and no policy from request. */
  jaSpecies=joPolicy:GetJsonArray("titulos"). jaSpecies:Add("AF").
  RUN Request("get","pagamentos",71,cPayKey). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetCharacter("valor_real_origem")="original_fallback","DI classification has same override precedence as legacy").
  /* No items: supplier fallback from parent and date fallback 2005. */
  CREATE ttPagtos. ASSIGN ttPagtos.container_id=72 ttPagtos.num_id_tit_ap=20.
  CREATE ttTit. ASSIGN ttTit.cod_estab="902" ttTit.num_id_tit_ap=20 ttTit.cod_empresa="9"
    ttTit.cdn_fornecedor=61 ttTit.dat_emis_docto=DATE(1,1,2005).
  RUN Request("read","pagamentos",72,""). RUN ExecuteRequest. joRow=joResponse:GetJsonArray("data"):GetJsonObject(1).
  RUN AssertTrue(joRow:GetCharacter("data_inicio_filtro")="2005-01-01" AND joRow:GetCharacter("data_inicio_origem")="padrao_2005","missing items fallback date and parent supplier").

  /* NF same three-key link matches multiple real documents; duplicate links do not duplicate docs. */
  CREATE ttNfs. ASSIGN ttNfs.documento="000123" ttNfs.serie="a'~~" ttNfs.estab="501"
    ttNfs.nat_operacao="3999" ttNfs.cod_emitente=51 ttNfs.container_id=71.
  CREATE ttNfs. ASSIGN ttNfs.documento="000123" ttNfs.serie="A'~~" ttNfs.estab="501"
    ttNfs.nat_operacao="3888" ttNfs.cod_emitente=61 ttNfs.container_id=71.
  CREATE ttDoc. ASSIGN ttDoc.nro-docto="000123" ttDoc.serie-docto="A'~~" ttDoc.cod-estabel="501"
    ttDoc.cod-emitente=51 ttDoc.nat-operacao="3101" ttDoc.esp-docto=21 ttDoc.dt-emissao=DATE(10,16,2026)
    ttDoc.tot-valor=1234.56789 ttDoc.valor-frete=1.23456 ttDoc.valor-seguro=?.
  CREATE ttDoc. ASSIGN ttDoc.nro-docto="000123" ttDoc.serie-docto="A'~~" ttDoc.cod-estabel="501"
    ttDoc.cod-emitente=52 ttDoc.nat-operacao="3102" ttDoc.esp-docto=21.
  CREATE ttDoc. ASSIGN ttDoc.nro-docto="000123" ttDoc.serie-docto="A'~~" ttDoc.cod-estabel="501"
    ttDoc.cod-emitente=53 ttDoc.nat-operacao="1101" ttDoc.esp-docto=21.
  CREATE ttNfs. ASSIGN ttNfs.documento="ORFA" ttNfs.serie="" ttNfs.estab="501"
    ttNfs.nat_operacao="3101" ttNfs.cod_emitente=51 ttNfs.container_id=71.
  CREATE ttNfs. ASSIGN ttNfs.documento="ALHEIA" ttNfs.serie="" ttNfs.estab="501"
    ttNfs.nat_operacao="3101" ttNfs.cod_emitente=51 ttNfs.container_id=72.
  RUN Request("read","nfs",71,""). RUN ExecuteRequest.
  jaRows=joResponse:GetJsonArray("data"). RUN AssertTrue(jaRows:Length=3,"three-key NF join, duplicate link dedup and orphan").
  joRow=jaRows:GetJsonObject(1). cNfKey=joRow:GetCharacter("nf_key").
  RUN AssertTrue(joRow:GetLogical("documento_localizado") AND joRow:GetInteger("cod_emitente")=51,"NF first physical document stable").
  RUN AssertTrue(joRow:GetDecimal("tot_valor")=1234.56789 AND joRow:GetDecimal("valor_frete")=1.23456 AND joRow:IsNull("valor_seguro"),"NF typed values and precision").
  RUN AssertTrue(joRow:GetCharacter("serie")="A'~~" AND joRow:GetCharacter("documento")="000123","NF quoted keys preserve exact text").
  RUN CheckFields("container_id,nf_key,estab,documento,serie,especie,cod_emitente,nat_operacao,dt_emissao,dt_trans,tot_valor,despesa_nota,valor_embal,valor_frete,valor_mercad,valor_outras,valor_seguro,documento_localizado").
  RUN AssertTrue(jaRows:GetJsonObject(2):GetCharacter("nf_key")<>cNfKey,"NF same number different issuer has distinct key").
  joRow=jaRows:GetJsonObject(3).
  RUN AssertTrue(NOT joRow:GetLogical("documento_localizado") AND joRow:IsNull("tot_valor") AND joRow:IsNull("especie"),"orphan exposes no invented totals").
  RUN Request("get","nfs",71,cNfKey). joRequest:Add("nf_key",cNfKey). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetCharacter("nf_key")=cNfKey,"NF get by generated stable key").
  RUN Request("get","nfs",72,cNfKey). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).
  DO i=1 TO 2:
    cResource=ENTRY(i,"pagamentos,nfs").
    RUN Request("get",cResource,71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
    RUN Request("read",cResource,71,cPayKey). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
    RUN Request("delete",cResource,71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_OPERATION_INVALID",422).
    RUN Request("read",cResource,999,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_NOT_FOUND",404).
    RUN Request("read",cResource,71,""). joRequest:Add("policy","attacker"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  END.
  RUN Request("get","pagamentos",71,cPayKey). joRequest:Add("pagamento_key",cNfKey). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN Request("read","pagamentos",71,""). joRequest:Remove("container_id"). joRequest:Add("container_id","71 OR TRUE"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN Request("get","nfs",71,"nf_SQL free"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  FIND ttContainer WHERE ttContainer.nr-container=71. ttContainer.cod-estabel="X01".
  RUN Request("read","pagamentos",71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_COMPANY_CONTEXT",422).
  RUN AvailablePaymentsTests.
  PUT UNFORMATTED "PASS: " iPassed " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
  CATCH e AS Progress.Lang.Error:
    PUT UNFORMATTED "FAIL after " iPassed " checks: " e:GetMessage(1) SKIP.
    IF VALID-OBJECT(joResponse) THEN PUT UNFORMATTED STRING(joResponse:GetJsonText()) SKIP.
    OUTPUT CLOSE. UNDO, THROW e.
  END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE Request:
  DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcResource AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piContainer AS INTEGER NO-UNDO.
  DEFINE INPUT PARAMETER pcKey AS CHARACTER NO-UNDO.
  IF VALID-OBJECT(joRequest) THEN DELETE OBJECT joRequest.
  IF VALID-OBJECT(joResponse) THEN DELETE OBJECT joResponse.
  joRequest=NEW JsonObject(). joRequest:Add("operation",pcOperation). joRequest:Add("resource",pcResource).
  joRequest:Add("container_id",piContainer). IF pcKey<>"" THEN joRequest:Add("id",pcKey).
END PROCEDURE.
PROCEDURE ExecuteRequest:
  IF noNfBuffers THEN DO:
    RUN ContainersPainelFinanceReadService.p (INPUT BUFFER ttContainer:HANDLE, INPUT BUFFER ttEmpresas:HANDLE,
      INPUT BUFFER ttItens:HANDLE, INPUT BUFFER ttItensCompra:HANDLE, INPUT BUFFER ttCompra:HANDLE,
      INPUT BUFFER ttPagtos:HANDLE, INPUT BUFFER ttTit:HANDLE, INPUT BUFFER ttVal:HANDLE,
      INPUT ?,INPUT ?,INPUT joPolicy,INPUT joRequest,OUTPUT joResponse).
    RETURN.
  END.
  RUN ContainersPainelFinanceReadService.p (INPUT BUFFER ttContainer:HANDLE, INPUT BUFFER ttEmpresas:HANDLE,
    INPUT BUFFER ttItens:HANDLE, INPUT BUFFER ttItensCompra:HANDLE, INPUT BUFFER ttCompra:HANDLE,
    INPUT BUFFER ttPagtos:HANDLE, INPUT BUFFER ttTit:HANDLE, INPUT BUFFER ttVal:HANDLE,
    INPUT BUFFER ttNfs:HANDLE, INPUT BUFFER ttDoc:HANDLE, INPUT joPolicy, INPUT joRequest, OUTPUT joResponse).
END PROCEDURE.
PROCEDURE AvailablePaymentsFixture:
  EMPTY TEMP-TABLE ttContainer. EMPTY TEMP-TABLE ttEmpresas. EMPTY TEMP-TABLE ttItens. EMPTY TEMP-TABLE ttItensCompra.
  EMPTY TEMP-TABLE ttCompra. EMPTY TEMP-TABLE ttPagtos. EMPTY TEMP-TABLE ttTit. EMPTY TEMP-TABLE ttVal.
  joPolicy=NEW JsonObject(). jaSpecies=NEW JsonArray(). jaSpecies:Add("AF"). joPolicy:Add("adiantamentos",jaSpecies).
  jaSpecies=NEW JsonArray(). jaSpecies:Add("DI"). joPolicy:Add("titulos",jaSpecies).
  CREATE ttContainer. ASSIGN ttContainer.nr-container=71 ttContainer.cod-estabel="501" ttContainer.cod-emit-forn=51.
  CREATE ttEmpresas. ASSIGN ttEmpresas.empresa_id=35 ttEmpresas.cod_emp_ems2=5 ttEmpresas.cod_emp_ems5=9.
  CREATE ttItens. ASSIGN ttItens.item_container_id=1 ttItens.container_id=71 ttItens.item_proc_compra_id=11.
  CREATE ttItensCompra. ASSIGN ttItensCompra.item_proc_compra_id=11 ttItensCompra.proc_compra_id=21.
  CREATE ttCompra. ASSIGN ttCompra.proc_compra_id=21 ttCompra.fornecedor_id=61 ttCompra.dt_registro=DATE(1,10,2026).
  DO i=101 TO 116:
    CREATE ttTit. ASSIGN ttTit.num_id_tit_ap=i ttTit.cod_estab="901" ttTit.cod_empresa="9"
      ttTit.cdn_fornecedor=61 ttTit.dat_emis_docto=DATE(1,10,2026) ttTit.dat_vencto_tit_ap=DATE(1,1,2000)
      ttTit.cod_espec_docto="AF" ttTit.ind_tip_espec_docto="antecipacao" ttTit.cod_tit_ap="TIT-" + TRIM(STRING(i)).
    CASE i:
      WHEN 102 THEN ASSIGN ttTit.cod_espec_docto="DI" ttTit.ind_tip_espec_docto="titulo".
      WHEN 105 THEN ttTit.cod_empresa="1".
      WHEN 106 THEN ttTit.cdn_fornecedor=51.
      WHEN 107 THEN ttTit.dat_emis_docto=DATE(1,9,2026).
      WHEN 108 THEN ttTit.log_tit_ap_estordo=TRUE.
      WHEN 109 THEN ASSIGN ttTit.cod_espec_docto="DI" ttTit.ind_tip_espec_docto="titulo" ttTit.log_sdo_tit_ap=TRUE.
      WHEN 110 THEN ttTit.ind_tip_espec_docto="titulo".
      WHEN 111 THEN ttTit.cod_espec_docto="DI".
      WHEN 112 THEN ttTit.log_tit_ap_estordo=?.
      WHEN 113 THEN ASSIGN ttTit.cod_espec_docto="DI" ttTit.ind_tip_espec_docto="titulo" ttTit.log_sdo_tit_ap=?.
      WHEN 114 THEN ttTit.dat_emis_docto=?.
      WHEN 115 THEN ttTit.cod_espec_docto="XX".
    END CASE.
    IF i=103 OR i=104 THEN DO: CREATE ttPagtos. ASSIGN ttPagtos.num_id_tit_ap=i ttPagtos.container_id=IF i=103 THEN 72 ELSE 71. END.
    CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=i ttVal.cod_estab="901" ttVal.cod_finalid_econ="corrente"
      ttVal.val_origin_tit_ap=50 ttVal.val_pagto_tit_ap=20.
    CREATE ttVal. ASSIGN ttVal.num_id_tit_ap=i ttVal.cod_estab="901" ttVal.cod_finalid_econ="dolar"
      ttVal.val_origin_tit_ap=10 ttVal.val_pagto_tit_ap=4.
  END.
END PROCEDURE.
PROCEDURE AvailablePaymentsTests:
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  RUN AvailablePaymentsFixture. noNfBuffers=TRUE.
  RUN Request("read","pagamentos-disponiveis",71,""). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"private payment options accept absent NF handles").
  jaRows=joResponse:GetJsonArray("data").
  RUN AssertTrue(jaRows:Length=4,"form options union includes current own link and excludes other links and ineligible titles").
  joRow=jaRows:GetJsonObject(1).
  RUN AssertTrue(joRow:GetInteger("value")=101 AND joRow:GetCharacter("modalidade")="adiantamento","options numeric identity and advance mode").
  RUN AssertTrue(joRow:GetCharacter("label") BEGINS "Adiantamento" AND INDEX(joRow:GetCharacter("label"),"901")>0 AND INDEX(joRow:GetCharacter("label"),"AF")>0,"commercial option label includes mode establishment and species").
  RUN AssertTrue(joRow:GetDecimal("valor_real")=50 AND joRow:GetDecimal("valor_dolar")=10,"options reuse original advance currency values").
  RUN CheckFields("container_id,pagamento_key,num_id_tit_ap,cod_estab,cod_empresa,cod_espec_docto,cod_ser_docto,cdn_fornecedor,cod_tit_ap,cod_parcela,dat_emis_docto,dat_vencto_tit_ap,cod_indic_econ,val_origin_tit_ap,valor_real,valor_dolar,valor_real_origem,valor_dolar_origem,valor_real_registros,valor_dolar_registros,data_inicio_filtro,data_inicio_origem,value,label,modalidade").
  joRow=jaRows:GetJsonObject(2).
  RUN AssertTrue(joRow:GetInteger("value")=102 AND joRow:GetCharacter("modalidade")="apos_di" AND joRow:GetDecimal("valor_real")=20 AND joRow:GetDecimal("valor_dolar")=4,"union title mode reuses paid values").
  RUN AssertTrue(jaRows:GetJsonObject(3):GetInteger("value")=104 AND jaRows:GetJsonObject(3):GetCharacter("label") BEGINS "Já associado","current own link retains commercial label for readonly form").
  RUN AssertTrue(jaRows:GetJsonObject(4):GetInteger("value")=116,"overdue title not excluded by invented due-date rule").
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",104). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",101). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:GetJsonObject("data"):GetInteger("value")=101,"numeric get returns same eligible candidate").
  CREATE ttPagtos. ASSIGN ttPagtos.num_id_tit_ap=101 ttPagtos.container_id=999.
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",101). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",109). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",106). RUN ExecuteRequest. RUN ExpectError("CONTAINER_CHILD_NOT_FOUND",404).
  RUN Request("read","pagamentos-disponiveis",999,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_NOT_FOUND",404).
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",102). joRequest:Add("num_id_tit_ap",102). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN Request("read","pagamentos-disponiveis",71,""). joRequest:Add("policy",NEW JsonObject()). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",1.5). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN Request("read","pagamentos-disponiveis",71,""). joRequest:Add("id",102). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION",422).
  RUN Request("delete","pagamentos-disponiveis",71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_OPERATION_INVALID",422).
  /* A second occurrence outside company eligibility still makes legacy numeric identity ambiguous. */
  CREATE ttTit. ASSIGN ttTit.cod_estab="101" ttTit.num_id_tit_ap=102 ttTit.cod_empresa="1" ttTit.cdn_fornecedor=999.
  RUN Request("read","pagamentos-disponiveis",71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_PAYMENT_AMBIGUOUS",422).
  RUN Request("get","pagamentos-disponiveis",71,""). joRequest:Add("id",102). RUN ExecuteRequest. RUN ExpectError("CONTAINER_PAYMENT_AMBIGUOUS",422).
  FIND ttTit WHERE ttTit.cod_estab="101" AND ttTit.num_id_tit_ap=102. DELETE ttTit.
  EMPTY TEMP-TABLE ttItens.
  RUN Request("read","pagamentos-disponiveis",71,""). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonArray("data"):Length=1 AND joResponse:GetJsonArray("data"):GetJsonObject(1):GetInteger("value")=106,"no items falls back parent supplier without new same-supplier restriction").
  joRow=joResponse:GetJsonArray("data"):GetJsonObject(1).
  RUN AssertTrue(joRow:GetCharacter("data_inicio_filtro")="2005-01-01","option missing purchase date uses existing date fallback").
  RUN AvailablePaymentsFixture.
  EMPTY TEMP-TABLE ttTit. EMPTY TEMP-TABLE ttVal.
  DO k=1 TO 5001:
    CREATE ttTit. ASSIGN ttTit.cod_estab="901" ttTit.num_id_tit_ap=10000 + k ttTit.cod_empresa="9"
      ttTit.cdn_fornecedor=61 ttTit.dat_emis_docto=DATE(1,10,2026) ttTit.cod_espec_docto="AF" ttTit.ind_tip_espec_docto="antecipacao".
  END.
  RUN Request("read","pagamentos-disponiveis",71,""). RUN ExecuteRequest. RUN ExpectError("CONTAINER_OPTIONS_LIMIT",422).
  FIND ttTit WHERE ttTit.cod_estab="901" AND ttTit.num_id_tit_ap=15001. DELETE ttTit.
  RUN Request("read","pagamentos-disponiveis",71,""). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:GetJsonArray("data"):Length=5000,"exact option limit returns complete result").
  RUN AssertTrue(joResponse:GetJsonArray("data"):GetJsonObject(1):GetInteger("value")=10001 AND joResponse:GetJsonArray("data"):GetJsonObject(5000):GetInteger("value")=15000,"options retain stable numeric order at the limit").
  EMPTY TEMP-TABLE ttTit.
  CREATE ttContainer. ASSIGN ttContainer.nr-container=123 ttContainer.cod-estabel="501" ttContainer.cod-emit-forn=61.
  CREATE ttTit. ASSIGN ttTit.cod_estab="505" ttTit.num_id_tit_ap=7 ttTit.cod_empresa="9"
    ttTit.cdn_fornecedor=61 ttTit.dat_emis_docto=DATE(1,10,2026) ttTit.cod_espec_docto="AF" ttTit.ind_tip_espec_docto="antecipacao".
  RUN Request("read","pagamentos-disponiveis",123,""). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetJsonArray("data"):GetJsonObject(1):GetCharacter("pagamento_key")="p_705E79307E0086168A96492D7A1C6BD6DAEBB0C51A6EADC83E6792771AA42F09","reader delegates exact shared payment identity").
  noNfBuffers=FALSE.
END PROCEDURE.
PROCEDURE AssertTrue:
  DEFINE INPUT PARAMETER plValue AS LOGICAL NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  IF plValue<>TRUE OR plValue=? THEN UNDO, THROW NEW Progress.Lang.AppError(pcMessage,0).
  iPassed=iPassed + 1.
END PROCEDURE.
PROCEDURE ExpectError:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER piStatus AS INTEGER NO-UNDO.
  RUN AssertTrue(NOT joResponse:GetLogical("success"),"expected failed request").
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetCharacter("code")=pcCode,"error code " + pcCode).
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetInteger("status")=piStatus,"error status").
  RUN AssertTrue(NOT joResponse:Has("data"),"failed request has no data").
END PROCEDURE.
PROCEDURE CheckFields:
  DEFINE INPUT PARAMETER pcFields AS CHARACTER NO-UNDO.
  DEFINE VARIABLE k AS INTEGER NO-UNDO.
  EXTENT(cNames)=?. cNames=joRow:GetNames().
  RUN AssertTrue(EXTENT(cNames)=NUM-ENTRIES(pcFields),"closed field count").
  DO k=1 TO NUM-ENTRIES(pcFields): RUN AssertTrue(joRow:Has(ENTRY(k,pcFields)),"field " + ENTRY(k,pcFields)). END.
END PROCEDURE.
