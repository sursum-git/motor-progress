/* Extra physical projections for Runtime/Finance no-payment integration. */
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
DEFINE TEMP-TABLE ttTitles
 FIELD num_id_tit_ap AS INTEGER FIELD cod_estab AS CHARACTER FIELD cod_espec_docto AS CHARACTER
 FIELD log_tit_ap_estordo AS LOGICAL FIELD cod_empresa AS CHARACTER FIELD cdn_fornecedor AS INTEGER FIELD dat_emis_docto AS DATE
 INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap.
DEFINE TEMP-TABLE ttTitleValues
 FIELD cod_estab AS CHARACTER FIELD num_id_tit_ap AS INTEGER FIELD num_id_movto_tit_ap AS INTEGER
 FIELD cod_finalid_econ AS CHARACTER FIELD cod_unid_negoc AS CHARACTER FIELD cod_tip_fluxo_financ AS CHARACTER
 FIELD val_origin_tit_ap AS DECIMAL DECIMALS 10 FIELD val_pagto_tit_ap AS DECIMAL DECIMALS 10
 INDEX pk IS UNIQUE PRIMARY cod_estab num_id_tit_ap num_id_movto_tit_ap cod_finalid_econ cod_unid_negoc cod_tip_fluxo_financ.
