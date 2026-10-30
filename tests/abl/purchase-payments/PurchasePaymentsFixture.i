/* Test-only undoable projections from the real dictionaries. */
DEFINE TEMP-TABLE ttItems
 FIELD item_container_id AS INTEGER
 FIELD container_id AS INTEGER
 FIELD item_proc_compra_id AS INTEGER
 FIELD qt_alocada AS DECIMAL DECIMALS 2
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 2
 INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttPurchaseItems
 FIELD item_proc_compra_id AS INTEGER
 FIELD proc_compra_id AS INTEGER
 FIELD qt_comprada AS DECIMAL DECIMALS 2
 FIELD vl_custo_dolar AS DECIMAL DECIMALS 10
 FIELD vl_negociado AS DECIMAL DECIMALS 5
 INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttPurchases
 FIELD proc_compra_id AS INTEGER
 FIELD empresa_id AS INTEGER
 FIELD dt_registro AS DATE
 FIELD fornecedor_id AS INTEGER
 FIELD log_considerar_previsao AS LOGICAL
 INDEX pk IS UNIQUE PRIMARY proc_compra_id.
DEFINE TEMP-TABLE ttLedger
 FIELD cta_corren_fornec_imp_id AS INTEGER
 FIELD fornecedor_id AS INTEGER
 FIELD data AS DATE
 FIELD historico AS CHARACTER
 FIELD cod_tipo_movto AS INTEGER
 FIELD vl_lancto AS DECIMAL DECIMALS 2
 FIELD cod_acao AS INTEGER
 FIELD login AS CHARACTER
 FIELD data_hora AS DATETIME
 FIELD num_id_tit_ap AS INTEGER
 FIELD item_proc_compra_id AS INTEGER
 FIELD item_container_id AS INTEGER
 FIELD transacao_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY cta_corren_fornec_imp_id.
DEFINE TEMP-TABLE ttOrderPayments
 FIELD num_id_tit_ap AS INTEGER
 FIELD proc_compra_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY num_id_tit_ap proc_compra_id.
DEFINE TEMP-TABLE ttContainerPayments
 FIELD num_id_tit_ap AS INTEGER
 FIELD container_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY num_id_tit_ap container_id.
DEFINE TEMP-TABLE ttAllContainers
 FIELD nr-container AS INTEGER
 FIELD cod-emit-forn AS INTEGER
 INDEX pk IS UNIQUE PRIMARY nr-container.

DEFINE TEMP-TABLE ttCompanies FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER FIELD nome AS CHARACTER INDEX pk IS UNIQUE PRIMARY empresa_id.
DEFINE TEMP-TABLE ttTitles FIELD num_id_tit_ap AS INTEGER FIELD cod_estab AS CHARACTER FIELD cod_empresa AS CHARACTER
 FIELD cod_espec_docto AS CHARACTER FIELD cod_ser_docto AS CHARACTER FIELD cdn_fornecedor AS INTEGER FIELD cod_tit_ap AS CHARACTER FIELD cod_parcela AS CHARACTER
 FIELD dat_emis_docto AS DATE FIELD dat_vencto_tit_ap AS DATE FIELD cod_indic_econ AS CHARACTER FIELD val_origin_tit_ap AS DECIMAL DECIMALS 10
 FIELD log_tit_ap_estordo AS LOGICAL FIELD ind_tip_espec_docto AS CHARACTER INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap.
DEFINE TEMP-TABLE ttValues FIELD cod_estab AS CHARACTER FIELD num_id_tit_ap AS INTEGER FIELD cod_finalid_econ AS CHARACTER
 FIELD val_origin_tit_ap AS DECIMAL DECIMALS 10 FIELD val_pagto_tit_ap AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap cod_finalid_econ.
