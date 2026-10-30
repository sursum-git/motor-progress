/* Transactional temp-tables: intentionally NOT NO-UNDO. Never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttContainer
  FIELD cod-estabel AS CHARACTER
  FIELD nr-container AS INTEGER
  FIELD num-pedido AS INTEGER
  FIELD nome-ab-forn AS CHARACTER
  FIELD cod-emit-forn AS INTEGER
  FIELD comprador AS CHARACTER
  FIELD narrativa AS CHARACTER
  FIELD usuario AS CHARACTER
  FIELD dt-compra AS DATE
  FIELD dt-prev-chegada AS DATE
  FIELD dt-recebimento AS DATE
  FIELD situacao AS INTEGER
  FIELD char-1 AS CHARACTER
  FIELD dec-1 AS DECIMAL DECIMALS 10
  FIELD int-1 AS INTEGER
  FIELD log-1 AS LOGICAL
  FIELD data-1 AS DATE
  FIELD vlr-frete AS DECIMAL DECIMALS 10
  FIELD vlr-seguro AS DECIMAL DECIMALS 10
  FIELD vlr-despesas AS DECIMAL DECIMALS 10
  FIELD exclusivo AS LOGICAL
  FIELD vl-dolar-venda AS DECIMAL DECIMALS 10
  FIELD vl-dolar-compra AS DECIMAL DECIMALS 10
  FIELD log_liberar_custo_realizado AS LOGICAL
  FIELD medidas_container AS CHARACTER
  FIELD dt_prev_embarque AS DATE
  FIELD dt_real_embarque AS DATE
  FIELD ind_dt_embarque AS INTEGER
  FIELD situacao_container_id AS INTEGER
  FIELD ind_dt_prev_chegada AS INTEGER
  FIELD log_pagto_final AS LOGICAL
  FIELD cod_agente_cargas AS INTEGER
  FIELD cod_armador AS INTEGER
  FIELD cod_tipo_calculo AS INTEGER
  FIELD perc_custo AS DECIMAL DECIMALS 10
  FIELD vl_dolar_di AS DECIMAL DECIMALS 10
  FIELD log_gerar_saldo_a_pagar AS LOGICAL
  FIELD log_gerar_distr_custo AS LOGICAL
  FIELD ordem_busca_dolar_compra AS CHARACTER
  FIELD ordem_busca_dolar_di AS CHARACTER
  FIELD cod_tipo_proj_dolar AS INTEGER
  FIELD vl_proj_dolar AS DECIMAL DECIMALS 10
  FIELD log_versao_custo_desatualizada AS LOGICAL
  FIELD dt_hr_ult_alt_versao_custo AS DATETIME
  FIELD ptax AS DECIMAL DECIMALS 10
  FIELD cod-depos AS CHARACTER
  FIELD dt_prev_chegada_loja AS DATE
  FIELD estacao AS INTEGER
  FIELD num_origem AS INTEGER
  FIELD log_rota_indefinida AS LOGICAL
  INDEX pk IS PRIMARY UNIQUE nr-container.
DEFINE TEMP-TABLE ttEmpresas
  FIELD empresa_id AS INTEGER
  FIELD nome AS CHARACTER
  FIELD cod_emp_ems2 AS INTEGER
  FIELD cod_emp_ems5 AS INTEGER
  INDEX pk IS PRIMARY UNIQUE empresa_id.
DEFINE TEMP-TABLE ttItems
  FIELD item_container_id AS INTEGER
  FIELD container_id AS INTEGER
  FIELD item_proc_compra_id AS INTEGER
  FIELD qt_alocada AS DECIMAL DECIMALS 10
  FIELD qt_confirm_emb AS DECIMAL DECIMALS 10
  FIELD qt_recbto_fisico AS DECIMAL DECIMALS 10
  FIELD log_rec_doc_prazo_emb AS LOGICAL
  FIELD observacao AS CHARACTER
  FIELD cod_tipo_calculo AS INTEGER
  FIELD perc_custo AS DECIMAL DECIMALS 10
  FIELD log_calc_icms AS LOGICAL
  FIELD log_calc_ipi AS LOGICAL
  FIELD perc_icms AS DECIMAL DECIMALS 10
  FIELD perc_ipi AS DECIMAL DECIMALS 10
  FIELD preco_liquida_ima AS DECIMAL DECIMALS 10
  INDEX pk IS PRIMARY UNIQUE item_container_id.
DEFINE TEMP-TABLE ttPurchaseItems
  FIELD item_proc_compra_id AS INTEGER
  FIELD descricao AS CHARACTER
  FIELD codigo_erp AS CHARACTER
  FIELD qt_dias_producao AS INTEGER
  FIELD vl_base_tributacao AS DECIMAL DECIMALS 10
  FIELD unid_medida AS CHARACTER
  FIELD proc_compra_id AS INTEGER
  FIELD qt_comprada AS DECIMAL DECIMALS 10
  FIELD vl_custo_dolar AS DECIMAL DECIMALS 10
  FIELD composicao AS CHARACTER
  FIELD peso AS CHARACTER
  FIELD largura AS CHARACTER
  FIELD rolo AS CHARACTER
  FIELD dt_prev_envio_desenhos AS DATE
  FIELD dt_real_envio_desenhos AS DATE
  FIELD log_aprov_so_ld AS LOGICAL
  FIELD dt_prev_recbto_so_ld AS DATE
  FIELD dt_prev_aprov_so_ld AS DATE
  FIELD dt_real_aprov_so_ld AS DATE
  FIELD coloracao_id AS INTEGER
  FIELD dt_maxima_producao AS DATE
  FIELD dt_mostruario AS DATE
  FIELD log_mostruario AS LOGICAL
  FIELD formato_amostra_id AS INTEGER
  FIELD ind_producao_no_prazo AS INTEGER
  FIELD ind_relat_semanal_producao AS INTEGER
  FIELD ind_qualid_emb AS INTEGER
  FIELD ind_laudo_antes_embarque AS INTEGER
  FIELD ind_prod_conf_pi AS INTEGER
  FIELD ind_rec_amostra_antes_emb AS INTEGER
  FIELD ind_qt_conf_proforma AS INTEGER
  FIELD ind_tamanho_pecas_correto AS INTEGER
  FIELD observacao AS CHARACTER
  FIELD dt_cheg_amostras_emb AS DATE
  FIELD dt_termino_producao AS DATE
  FIELD vl_cubagem AS DECIMAL DECIMALS 10
  FIELD dt_recbto_laudo AS DATE
  FIELD dt_recbto_embalagem AS DATE
  FIELD dt_real_recbto_so_ld AS DATE
  FIELD dt_prev_termino_producao AS DATE
  FIELD qt_dias_calc_so_ld AS INTEGER
  FIELD shrinkage AS CHARACTER
  FIELD ind_distr_custo AS INTEGER
  FIELD vl_negociado AS DECIMAL DECIMALS 10
  FIELD item_estacao AS INTEGER
  FIELD dt_item_certificacao AS DATE
  INDEX pk IS PRIMARY UNIQUE item_proc_compra_id.
DEFINE TEMP-TABLE ttPurchases
  FIELD proc_compra_id AS INTEGER
  FIELD empresa_id AS INTEGER
  FIELD qt_container AS INTEGER
  FIELD cod_situacao AS INTEGER
  FIELD cod_proc_fornec AS CHARACTER
  FIELD qt_dias_translado AS INTEGER
  FIELD cotacao_prevista AS DECIMAL DECIMALS 10
  FIELD observacao AS CHARACTER
  FIELD dt_registro AS DATE
  FIELD fornecedor_id AS INTEGER
  FIELD dt_limite AS DATE
  FIELD log_facilid_contato_fornec AS LOGICAL
  FIELD log_considerar_previsao AS LOGICAL
  FIELD nr_container_original AS CHARACTER
  INDEX pk IS PRIMARY UNIQUE proc_compra_id.
DEFINE TEMP-TABLE ttDefs
  FIELD despesa_id AS INTEGER
  FIELD descricao AS CHARACTER
  FIELD log_imposto AS INTEGER
  FIELD ordem AS INTEGER
  FIELD log_calculada AS LOGICAL
  FIELD perc_calculo AS DECIMAL DECIMALS 10
  FIELD log_vl_prod_base_calculo AS LOGICAL
  FIELD log_calc_por_item AS LOGICAL
  FIELD ind_imposto AS INTEGER
  INDEX pk IS PRIMARY UNIQUE despesa_id.
DEFINE TEMP-TABLE ttLinks
  FIELD empresa_despesa_id AS INTEGER
  FIELD despesa_id AS INTEGER
  FIELD empresa_id AS INTEGER
  FIELD codigo_desp_erp AS INTEGER
  FIELD vl_padrao AS DECIMAL DECIMALS 10
  FIELD percentual AS DECIMAL DECIMALS 10
  FIELD cod_nat_operacao AS CHARACTER
  FIELD log_ativo AS INTEGER
  FIELD perc_custo AS INTEGER
  FIELD percentual_custo AS DECIMAL DECIMALS 10
  FIELD despesa_custo_id AS INTEGER
  FIELD log_custo AS INTEGER
  INDEX pk IS PRIMARY UNIQUE empresa_despesa_id.
DEFINE TEMP-TABLE ttTaxBases
  FIELD despesa_id AS INTEGER
  FIELD imposto_id AS INTEGER
  FIELD empresa_id AS INTEGER
  INDEX pk IS PRIMARY UNIQUE despesa_id imposto_id empresa_id.
DEFINE TEMP-TABLE ttRelations
  FIELD relac_desp_calculada_id AS INTEGER
  FIELD despesa_id AS INTEGER
  FIELD despesa_id_base AS INTEGER
  INDEX pk IS PRIMARY UNIQUE despesa_id despesa_id_base.
DEFINE TEMP-TABLE ttCalcs
  FIELD container_id AS INTEGER
  FIELD dt_hr_calculo AS DATETIME
  FIELD usuario_id AS INTEGER
  FIELD memoria_calculo AS INTEGER
  FIELD calc_imp_container_id AS INTEGER
  FIELD desc_memoria_calc AS CHARACTER
  INDEX pk IS PRIMARY UNIQUE calc_imp_container_id.
DEFINE TEMP-TABLE ttExpenses
  FIELD despesa_container_id AS INTEGER
  FIELD despesa_id AS INTEGER
  FIELD vl_prev AS DECIMAL DECIMALS 10
  FIELD container_id AS INTEGER
  FIELD calc_imp_container_id AS INTEGER
  FIELD vl_base_imp AS DECIMAL DECIMALS 10
  FIELD vl_negociado AS DECIMAL DECIMALS 10
  FIELD vl_proforma AS DECIMAL DECIMALS 10
  FIELD cta_corren_custo_distr_id AS INTEGER
  FIELD log_utilizado AS LOGICAL
  FIELD log_manual AS LOGICAL
  FIELD perc_calc AS DECIMAL DECIMALS 10
  FIELD memoria_calculo AS CHARACTER
  FIELD item_container_id AS INTEGER
  INDEX pk IS PRIMARY UNIQUE despesa_container_id.

DEFINE TEMP-TABLE ttProviderLog NO-UNDO FIELD logLevel AS CHARACTER FIELD logMessage AS CHARACTER.
DEFINE VARIABLE joPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE joInputs AS JsonObject NO-UNDO.
DEFINE VARIABLE joRequest AS JsonObject NO-UNDO.
DEFINE VARIABLE joResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE joSnapshot AS JsonObject NO-UNDO.
DEFINE VARIABLE iCalcSeq AS INTEGER NO-UNDO.
DEFINE VARIABLE iExpenseSeq AS INTEGER NO-UNDO.
DEFINE VARIABLE iExpenseCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE iFailAt AS INTEGER NO-UNDO.
DEFINE VARIABLE proofMode AS CHARACTER NO-UNDO.
DEFINE VARIABLE iPassed AS INTEGER NO-UNDO.
DEFINE VARIABLE i As INTEGER NO-UNDO.
OUTPUT TO VALUE("containers-impostos-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
  RUN Seed(0). RUN Request("sincronizar"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"sync successful").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetLogical("committed"),"success only after own transaction ends").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetInteger("calc_imp_container_id")=901,"calculation ID comes from provider, not global MAX").
  FIND ttExpenses WHERE ttExpenses.despesa_id=10 AND ttExpenses.item_container_id=0.
  RUN AssertTrue(ttExpenses.vl_prev=762 AND ttExpenses.vl_proforma=612 AND ttExpenses.vl_negociado=762,"three tax bases and common overridden expense base").
  RUN AssertTrue(ttExpenses.log_manual AND ttExpenses.perc_calc=0,"tax insertion preserves legacy default manual and zero stored percentage").
  FIND ttExpenses WHERE ttExpenses.despesa_id=9 AND ttExpenses.item_container_id=0.
  RUN AssertTrue(ttExpenses.vl_prev=165.24 AND ttExpenses.vl_proforma=135.24,"dependency tax calculated after tax10 despite lower order/ID").
  RUN AssertTrue(NOT ttExpenses.log_manual,"existing manual flag preserved on update").
  FIND ttExpenses WHERE ttExpenses.despesa_id=11.
  RUN AssertTrue(ttExpenses.vl_prev=152.4 AND ttExpenses.vl_proforma=122.4,"nonrecoverable percentage cost").
  FIND ttExpenses WHERE ttExpenses.despesa_id=13.
  RUN AssertTrue(ttExpenses.vl_prev=82.62,"multiple nonrecoverable links traversed without PHP array overwrite bug").
  FIND ttExpenses WHERE ttExpenses.despesa_id=20 AND ttExpenses.item_container_id=1.
  RUN AssertTrue(ttExpenses.vl_prev=254 AND ttExpenses.vl_proforma=163 AND ttExpenses.vl_negociado=122.67,"IPI allocated by each basis and rounded two decimals").
  RUN AssertTrue(ttExpenses.perc_calc=0,"IPI persisted percentage zero follows outer PHP result").
  FIND ttExpenses WHERE ttExpenses.despesa_id=20 AND ttExpenses.item_container_id=2.
  RUN AssertTrue(ttExpenses.vl_prev=555,"disabled IPI preserves previous persisted value").
  RUN AssertTrue(joResponse:GetJsonObject("data"):GetJsonArray("warnings"):Length>0,"preserved IPI reported to operator").
  FIND ttExpenses WHERE ttExpenses.despesa_id=40.
  RUN AssertTrue(ttExpenses.vl_prev=0,"sync menu does not implicitly run calculated expenses").
  RUN AssertTrue(joResponse:GetJsonObject("audit"):GetCharacter("source")="progress-transaction","postcommit audit source").
  RUN AssertTrue(joResponse:GetJsonObject("audit"):GetJsonArray("warnings"):Length>0,"IPI preservation warning included in audit").
  RUN AssertTrue(joResponse:GetJsonObject("audit"):GetJsonArray("children"):Length=6,"calculation and five affected expense snapshots").
  RUN AssertTrue(joResponse:GetJsonObject("audit"):GetJsonArray("children"):GetJsonObject(2):GetJsonObject("before"):GetDecimal("vl_prev")=1,"snapshot before came from locked existing expense").
  RUN AssertTrue(CAN-FIND(ttCalcs WHERE ttCalcs.calc_imp_container_id=999999),"unrelated calculation preserved").
  RUN Seed(0). RUN Request("atualizar_despesas_calculadas"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"calculated expenses successful").
  FIND ttExpenses WHERE ttExpenses.despesa_id=40.
  RUN AssertTrue(ttExpenses.vl_prev=610 AND ttExpenses.vl_proforma=489 AND ttExpenses.vl_negociado=608,"calculated expense purchase quote across all bases and negotiated difference").
  RUN AssertTrue(ttExpenses.perc_calc=10 AND NOT ttExpenses.log_manual AND ttExpenses.calc_imp_container_id=0,"calculated update fields preserved").
  RUN AssertTrue(NOT CAN-FIND(ttCalcs WHERE ttCalcs.calc_imp_container_id=901),"calculated operation does not create fiscal calculation").
  /* Sequence callback fails after an UPDATE, a calculation INSERT and one expense INSERT. */
  RUN Seed(0). iFailAt=2. RUN Request("sincronizar"). RUN ExecuteRequest.
  RUN AssertTrue(NOT joResponse:GetLogical("success") AND NOT joResponse:Has("audit"),"failure has no confirmed audit").
  RUN AssertTrue(NOT CAN-FIND(ttCalcs WHERE ttCalcs.calc_imp_container_id=901),"failure rolls back calculation insert").
  RUN AssertTrue(NOT CAN-FIND(ttExpenses WHERE ttExpenses.despesa_id=10),"failure rolls back child insertion").
  FIND ttExpenses WHERE ttExpenses.despesa_id=9.
  RUN AssertTrue(ttExpenses.vl_prev=1,"failure rolls back earlier expense update").
  RUN AssertTrue(iExpenseCalls=2,"fault reached after first expense inserted").
  RUN AssertTrue(NOT CAN-FIND(FIRST ttProviderLog),"failed transaction emits no confirmation log").
  /* Caller owns the outer commit; nested success cannot claim a commit. */
  RUN Seed(0). RUN Request("sincronizar").
  DO TRANSACTION ON ERROR UNDO, THROW:
    RUN ExecuteRequest.
    RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:Has("pendingChanges") AND joResponse:Has("auditPending"),"nested result pending only").
    RUN AssertTrue(NOT joResponse:Has("audit") AND NOT joResponse:GetJsonObject("data"):GetLogical("committed"),"nested transaction never confirmed").
    UNDO, LEAVE.
  END.
  RUN AssertTrue(NOT CAN-FIND(ttCalcs WHERE ttCalcs.calc_imp_container_id=901),"outer rollback undoes fiscal service").
  RUN AssertTrue(NOT CAN-FIND(FIRST ttProviderLog),"nested transaction emits no confirmation log").
  DO i=1 TO 4:
    RUN Seed(i). RUN Request("sincronizar"). RUN ExecuteRequest.
    RUN ExpectError(ENTRY(i,"CONTAINER_TAX_CYCLE,CONTAINER_ZERO_DENOMINATOR,CONTAINER_EXPENSE_AMBIGUOUS,CONTAINER_ZERO_DENOMINATOR")).
    RUN AssertTrue(NOT CAN-FIND(ttCalcs WHERE ttCalcs.calc_imp_container_id=901),"invalid state never commits calculation").
    RUN AssertTrue(NOT joResponse:Has("audit"),"invalid state no audit claim").
  END.
  RUN Seed(5). RUN Request("atualizar_despesas_calculadas"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_TAX_CYCLE").
  RUN Seed(6). RUN Request("sincronizar"). RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success"),"unused config percentage and disabled IPI unknown do not block unrelated calculations").
  RUN Seed(0). RUN Request("sincronizar").
  DO TRANSACTION ON ERROR UNDO, THROW:
    FIND ttContainer WHERE ttContainer.nr-container=71. ttContainer.vl_proj_dolar=99.
    RUN ExecuteRequest. RUN ExpectError("CONTAINER_INPUT_STALE").
    UNDO, LEAVE.
  END.
  FIND ttContainer WHERE ttContainer.nr-container=71.
  RUN AssertTrue(ttContainer.vl_proj_dolar=0,"outer caller undoes its own header mutation after nested service failure").
  RUN Seed(0). RUN Request("read"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_OPERATION_INVALID").
  RUN Request("sincronizar"). joRequest:Add("percentual",99). RUN ExecuteRequest. RUN ExpectError("CONTAINER_VALIDATION").
  RUN Request("sincronizar"). joInputs:Remove("dolar_di"). joInputs:Add("dolar_di",0). RUN ExecuteRequest. RUN ExpectError("CONTAINER_INPUT_INVALID").
  RUN Seed(0). RUN Request("sincronizar"). joSnapshot=joInputs:GetJsonObject("container_snapshot"). joSnapshot:Remove("vl-dolar-compra"). joSnapshot:Add("vl-dolar-compra",99).
  RUN ExecuteRequest. RUN ExpectError("CONTAINER_INPUT_STALE").
  RUN DistributionTests.
  PUT UNFORMATTED "PASS: " iPassed " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
  CATCH e AS Progress.Lang.Error:
    PUT UNFORMATTED "FAIL after " iPassed " checks: " e:GetMessage(1) SKIP.
    IF VALID-OBJECT(joResponse) THEN PUT UNFORMATTED STRING(joResponse:GetJsonText()) SKIP.
    OUTPUT CLOSE. UNDO, THROW e.
  END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE Seed:
  DEFINE INPUT PARAMETER scenario AS INTEGER NO-UNDO.
  DEFINE VARIABLE j AS INTEGER NO-UNDO.
  DO TRANSACTION:
    EMPTY TEMP-TABLE ttContainer. EMPTY TEMP-TABLE ttEmpresas. EMPTY TEMP-TABLE ttItems. EMPTY TEMP-TABLE ttPurchaseItems.
    EMPTY TEMP-TABLE ttPurchases. EMPTY TEMP-TABLE ttDefs. EMPTY TEMP-TABLE ttLinks. EMPTY TEMP-TABLE ttTaxBases.
    EMPTY TEMP-TABLE ttRelations. EMPTY TEMP-TABLE ttCalcs. EMPTY TEMP-TABLE ttExpenses.
    EMPTY TEMP-TABLE ttProviderLog.
    CREATE ttContainer. ASSIGN ttContainer.nr-container=71 ttContainer.cod-estabel="501" ttContainer.vl-dolar-compra=4 ttContainer.vl_dolar_di=5
      ttContainer.ordem_busca_dolar_compra="2" ttContainer.ordem_busca_dolar_di="4" ttContainer.cod_tipo_proj_dolar=1 ttContainer.vl_proj_dolar=0.
    CREATE ttEmpresas. ASSIGN ttEmpresas.empresa_id=35 ttEmpresas.cod_emp_ems2=5.
    CREATE ttPurchases. ttPurchases.proc_compra_id=21.
    CREATE ttPurchaseItems. ASSIGN ttPurchaseItems.item_proc_compra_id=11 ttPurchaseItems.proc_compra_id=21
      ttPurchaseItems.vl_base_tributacao=100 ttPurchaseItems.vl_custo_dolar=80 ttPurchaseItems.vl_negociado=60.
    DO j=1 TO 2:
      CREATE ttItems. ASSIGN ttItems.item_container_id=j ttItems.container_id=71 ttItems.item_proc_compra_id=11
        ttItems.qt_alocada=IF j=1 THEN 10 ELSE 5 ttItems.qt_confirm_emb=0 ttItems.log_calc_ipi=j=1 ttItems.perc_ipi=5.
    END.
    DO j=1 TO 7:
      CREATE ttDefs.
      ttDefs.despesa_id=INTEGER(ENTRY(j,"9,10,11,13,20,30,40")).
      ASSIGN ttDefs.ordem=j ttDefs.log_imposto=IF LOOKUP(TRIM(STRING(ttDefs.despesa_id)),"9,10,20")>0 THEN 1 ELSE 0.
      IF ttDefs.despesa_id=20 THEN ASSIGN ttDefs.ind_imposto=3 ttDefs.log_calc_por_item=TRUE.
      IF ttDefs.despesa_id=40 THEN ASSIGN ttDefs.log_calculada=TRUE ttDefs.perc_calculo=10 ttDefs.log_vl_prod_base_calculo=TRUE.
      CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=j ttLinks.empresa_id=35 ttLinks.despesa_id=ttDefs.despesa_id.
      CASE ttDefs.despesa_id:
        WHEN 9 THEN ASSIGN ttLinks.percentual=2 ttLinks.percentual_custo=1 ttLinks.despesa_custo_id=13.
        WHEN 10 THEN ASSIGN ttLinks.percentual=10 ttLinks.percentual_custo=2 ttLinks.despesa_custo_id=11.
      END CASE.
    END.
    CREATE ttTaxBases. ASSIGN ttTaxBases.empresa_id=35 ttTaxBases.imposto_id=9 ttTaxBases.despesa_id=10.
    CREATE ttTaxBases. ASSIGN ttTaxBases.empresa_id=35 ttTaxBases.imposto_id=10 ttTaxBases.despesa_id=30.
    CREATE ttTaxBases. ASSIGN ttTaxBases.empresa_id=35 ttTaxBases.imposto_id=20 ttTaxBases.despesa_id=30.
    CREATE ttRelations. ASSIGN ttRelations.relac_desp_calculada_id=1 ttRelations.despesa_id=40 ttRelations.despesa_id_base=30.
    CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=99 ttExpenses.container_id=71 ttExpenses.despesa_id=9 ttExpenses.vl_prev=1 ttExpenses.log_manual=FALSE.
    CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=100 ttExpenses.container_id=71 ttExpenses.despesa_id=30
      ttExpenses.vl_prev=100 ttExpenses.vl_base_imp=120 ttExpenses.vl_proforma=90 ttExpenses.vl_negociado=80 ttExpenses.log_manual=TRUE.
    CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=101 ttExpenses.container_id=71 ttExpenses.despesa_id=40 ttExpenses.log_manual=FALSE.
    CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=202 ttExpenses.container_id=71 ttExpenses.despesa_id=20 ttExpenses.item_container_id=2 ttExpenses.vl_prev=555.
    CREATE ttCalcs. ASSIGN ttCalcs.calc_imp_container_id=999999 ttCalcs.container_id=72.
    CASE scenario:
      WHEN 1 THEN DO: CREATE ttTaxBases. ASSIGN ttTaxBases.empresa_id=35 ttTaxBases.imposto_id=10 ttTaxBases.despesa_id=9. END.
      WHEN 2 THEN DO: FIND ttLinks WHERE ttLinks.despesa_id=10. ttLinks.percentual=0. END.
      WHEN 3 THEN DO: CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=203 ttExpenses.container_id=71 ttExpenses.despesa_id=30. END.
      WHEN 4 THEN DO: FIND ttPurchaseItems. ASSIGN ttPurchaseItems.vl_base_tributacao=0 ttPurchaseItems.vl_custo_dolar=0 ttPurchaseItems.vl_negociado=0. END.
      WHEN 5 THEN DO:
        CREATE ttDefs. ASSIGN ttDefs.despesa_id=41 ttDefs.log_calculada=TRUE ttDefs.perc_calculo=5.
        CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=8 ttLinks.empresa_id=35 ttLinks.despesa_id=41.
        CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=204 ttExpenses.container_id=71 ttExpenses.despesa_id=41 ttExpenses.log_manual=FALSE.
        CREATE ttRelations. ASSIGN ttRelations.relac_desp_calculada_id=2 ttRelations.despesa_id=40 ttRelations.despesa_id_base=41.
        CREATE ttRelations. ASSIGN ttRelations.relac_desp_calculada_id=3 ttRelations.despesa_id=41 ttRelations.despesa_id_base=40.
      END.
      WHEN 6 THEN DO:
        FIND ttDefs WHERE ttDefs.despesa_id=30. ttDefs.perc_calculo=?.
        FIND ttItems WHERE ttItems.item_container_id=2. ttItems.perc_ipi=?.
        FIND ttLinks WHERE ttLinks.despesa_id=30. ASSIGN ttLinks.percentual=? ttLinks.percentual_custo=?.
      END.
    END CASE.
  END.
  proofMode="".
  ASSIGN iCalcSeq=900 iExpenseSeq=9000 iExpenseCalls=0 iFailAt=0.
  joPolicy=NEW JsonObject(). joPolicy:Add("usuario_id",7). joPolicy:Add("actor","test-fiscal").
  joInputs=NEW JsonObject(). joInputs:Add("confirmed",TRUE). joInputs:Add("container_id",71). joInputs:Add("source","container-cost-collector").
  joInputs:Add("dolar_di",5). joInputs:Add("dolar_compra",4).
  joSnapshot=NEW JsonObject(). joSnapshot:Add("vl-dolar-compra",4). joSnapshot:Add("vl_dolar_di",5).
  joSnapshot:Add("ordem_busca_dolar_compra","2"). joSnapshot:Add("ordem_busca_dolar_di","4").
  joSnapshot:Add("cod_tipo_proj_dolar",1). joSnapshot:Add("vl_proj_dolar",0). joInputs:Add("container_snapshot",joSnapshot).
END PROCEDURE.
PROCEDURE NextCalculoId:
  DEFINE OUTPUT PARAMETER piId AS INTEGER NO-UNDO.
  iCalcSeq=iCalcSeq + 1. piId=iCalcSeq.
END PROCEDURE.
PROCEDURE NextDespesaId:
  DEFINE OUTPUT PARAMETER piId AS INTEGER NO-UNDO.
  iExpenseCalls=iExpenseCalls + 1.
  IF iFailAt>0 AND iExpenseCalls=iFailAt THEN UNDO, THROW NEW Progress.Lang.AppError("Injected sequence failure",0).
  iExpenseSeq=iExpenseSeq + 1. piId=iExpenseSeq.
END PROCEDURE.
PROCEDURE LogRule:
  DEFINE INPUT PARAMETER pcLevel AS CHARACTER NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  CREATE ttProviderLog. ASSIGN ttProviderLog.logLevel=pcLevel ttProviderLog.logMessage=pcMessage.
END PROCEDURE.
PROCEDURE Request:
  DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
  joRequest=NEW JsonObject(). joRequest:Add("operation",pcOperation). joRequest:Add("container_id",71).
END PROCEDURE.
PROCEDURE ExecuteRequest:
  RUN ContainersImpostosService.p (INPUT BUFFER ttContainer:HANDLE,INPUT BUFFER ttEmpresas:HANDLE,
    INPUT BUFFER ttItems:HANDLE,INPUT BUFFER ttPurchaseItems:HANDLE,INPUT BUFFER ttPurchases:HANDLE,
    INPUT BUFFER ttDefs:HANDLE,INPUT BUFFER ttLinks:HANDLE,INPUT BUFFER ttTaxBases:HANDLE,INPUT BUFFER ttRelations:HANDLE,
    INPUT BUFFER ttCalcs:HANDLE,INPUT BUFFER ttExpenses:HANDLE,INPUT THIS-PROCEDURE,INPUT joPolicy,INPUT joInputs,INPUT joRequest,OUTPUT joResponse).
END PROCEDURE.
PROCEDURE AssertTrue:
  DEFINE INPUT PARAMETER plValue AS LOGICAL NO-UNDO.
  DEFINE INPUT PARAMETER pcMessage AS CHARACTER NO-UNDO.
  IF plValue<>TRUE OR plValue=? THEN UNDO, THROW NEW Progress.Lang.AppError(pcMessage,0).
  iPassed=iPassed + 1.
END PROCEDURE.
PROCEDURE ExpectError:
  DEFINE INPUT PARAMETER pcCode AS CHARACTER NO-UNDO.
  RUN AssertTrue(NOT joResponse:GetLogical("success"),"expected failed request").
  RUN AssertTrue(joResponse:GetJsonObject("error"):GetCharacter("code")=pcCode,"code " + pcCode).
  RUN AssertTrue(NOT joResponse:Has("audit"),"no confirmed audit in failure").
END PROCEDURE.

PROCEDURE DistributionSeed:
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 RUN Seed(0). joPolicy:Add("despesa_distr_custo",50).
 CREATE ttDefs. ttDefs.despesa_id=50.
 CREATE ttLinks. ASSIGN ttLinks.empresa_despesa_id=9 ttLinks.empresa_id=35 ttLinks.despesa_id=50.
 CREATE ttTaxBases. ASSIGN ttTaxBases.empresa_id=35 ttTaxBases.imposto_id=10 ttTaxBases.despesa_id=50.
 DO j=1 TO 2:
  CREATE ttExpenses. ASSIGN ttExpenses.despesa_container_id=300 + j ttExpenses.container_id=71 ttExpenses.despesa_id=50
   ttExpenses.item_container_id=1 ttExpenses.cta_corren_custo_distr_id=500 + j ttExpenses.vl_prev=IF j=1 THEN 10 ELSE 15 ttExpenses.log_manual=TRUE.
 END.
END PROCEDURE.
PROCEDURE ValidateDistributionExpense:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER expense AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER proof AS JsonObject NO-UNDO.
 DEFINE VARIABLE ledger AS INTEGER NO-UNDO.
 ledger=expense:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE.
 IF NOT TRANSACTION OR master:BUFFER-FIELD("nr-container"):BUFFER-VALUE<>71 OR ledger<501 OR ledger>502 THEN
  UNDO, THROW NEW Progress.Lang.AppError("Unconfirmed distribution",1).
 proof=NEW JsonObject(). proof:Add("confirmed",TRUE). proof:Add("container_id",71).
 proof:Add("despesa_container_id",expense:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE). proof:Add("ledger_id",ledger).
 CASE proofMode:
  WHEN "foreign" THEN proof:Set("container_id",72).
  WHEN "fractional" THEN proof:Set("ledger_id",ledger + 0.5).
  WHEN "string" THEN proof:Set("ledger_id",STRING(ledger)).
  WHEN "unconfirmed" THEN proof:Set("confirmed",FALSE).
  WHEN "missing" THEN proof:Remove("despesa_container_id").
  WHEN "extra" THEN proof:Add("unexpected",TRUE).
 END CASE.
END PROCEDURE.
PROCEDURE DistributionTests:
 RUN DistributionSeed. RUN Request("sincronizar"). RUN ExecuteRequest.
 RUN AssertTrue(joResponse:GetLogical("success"),"distinct proven distribution movements are legitimate repeated expenses").
 FIND ttExpenses WHERE ttExpenses.despesa_id=10.
 RUN AssertTrue(ttExpenses.vl_prev=764.5,"tax sums distribution movements").
 FIND ttExpenses WHERE ttExpenses.despesa_container_id=301.
 RUN AssertTrue(ttExpenses.vl_prev=10 AND ttExpenses.cta_corren_custo_distr_id=501,"first distribution preserved").
 FIND ttExpenses WHERE ttExpenses.despesa_container_id=302.
 RUN AssertTrue(ttExpenses.vl_prev=15 AND ttExpenses.cta_corren_custo_distr_id=502,"second distribution preserved").
 RUN DistributionSeed.
 FIND ttExpenses WHERE ttExpenses.despesa_container_id=301. ttExpenses.vl_base_imp=2.
 FIND ttExpenses WHERE ttExpenses.despesa_container_id=302. ttExpenses.vl_base_imp=3.
 RUN Request("sincronizar"). RUN ExecuteRequest.
 RUN AssertTrue(joResponse:GetLogical("success"),"summed explicit tax bases accepted").
 FIND ttExpenses WHERE ttExpenses.despesa_id=10.
 RUN AssertTrue(ttExpenses.vl_prev=762.5,"summed tax base overrides summed previous value").
 RUN DistributionSeed. joPolicy:Remove("despesa_distr_custo").
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_EXPENSE_AMBIGUOUS").
 RUN DistributionSeed. FIND ttExpenses WHERE ttExpenses.despesa_container_id=302. ttExpenses.cta_corren_custo_distr_id=501.
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_EXPENSE_AMBIGUOUS").
 RUN DistributionSeed. FIND ttExpenses WHERE ttExpenses.despesa_container_id=302. ttExpenses.cta_corren_custo_distr_id=0.
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_EXPENSE_AMBIGUOUS").
 RUN DistributionSeed. FIND ttExpenses WHERE ttExpenses.despesa_container_id=302. ttExpenses.cta_corren_custo_distr_id=999.
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. CREATE ttRelations. ASSIGN ttRelations.relac_desp_calculada_id=9 ttRelations.despesa_id=40 ttRelations.despesa_id_base=50.
 RUN Request("atualizar_despesas_calculadas"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_EXPENSE_AMBIGUOUS").
 RUN DistributionSeed. joPolicy:Set("despesa_distr_custo",50.5).
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_INPUT_INVALID").
 RUN DistributionSeed. joPolicy:Set("despesa_distr_custo","50").
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_INPUT_INVALID").
 RUN DistributionSeed. proofMode="foreign". RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. proofMode="fractional". RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. proofMode="string". RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. proofMode="unconfirmed". RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. proofMode="missing". RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. proofMode="extra". RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_DISTRIBUTION_INVALID").
 RUN DistributionSeed. CREATE ttTaxBases. ASSIGN ttTaxBases.empresa_id=35 ttTaxBases.imposto_id=20 ttTaxBases.despesa_id=50.
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_EXPENSE_AMBIGUOUS").
 /* One managed row is still never an upsert target of fiscal processing. */
 RUN DistributionSeed. FIND ttExpenses WHERE ttExpenses.despesa_container_id=302. DELETE ttExpenses.
 FIND ttExpenses WHERE ttExpenses.despesa_container_id=301. ttExpenses.item_container_id=0.
 FIND ttDefs WHERE ttDefs.despesa_id=50. ttDefs.log_imposto=1.
 RUN Request("sincronizar"). RUN ExecuteRequest. RUN ExpectError("CONTAINER_EXPENSE_AMBIGUOUS").
 RUN DistributionSeed. RUN Request("sincronizar").
 DO TRANSACTION ON ERROR UNDO, THROW:
  FIND ttContainer WHERE ttContainer.nr-container=71. ttContainer.vl_proj_dolar=99.
  joInputs:GetJsonObject("container_snapshot"):Set("vl_proj_dolar",99).
  RUN ExecuteRequest.
  RUN AssertTrue(joResponse:GetLogical("success") AND joResponse:Has("auditPending") AND NOT joResponse:Has("audit"),"managed distributions preserve nested audit pending protocol").
  UNDO, LEAVE.
 END.
 FIND ttContainer WHERE ttContainer.nr-container=71. RUN AssertTrue(ttContainer.vl_proj_dolar=0,"nested caller undo restores master").
 RUN AssertTrue(NOT CAN-FIND(FIRST ttCalcs WHERE ttCalcs.container_id=71),"nested caller undo restores fiscal writes").
 FIND ttExpenses WHERE ttExpenses.despesa_container_id=301. RUN AssertTrue(ttExpenses.vl_prev=10 AND ttExpenses.cta_corren_custo_distr_id=501,"nested undo retains original managed movement").

END PROCEDURE.

