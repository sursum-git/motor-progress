/* Undoable TT projections generated from the checked physical dictionaries. Tests only. */
DEFINE TEMP-TABLE ttMaster
 FIELD nr-container AS INTEGER
 FIELD log_liberar_custo_realizado AS LOGICAL
 FIELD log_versao_custo_desatualizada AS LOGICAL
 INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttItems
 FIELD item_container_id AS INTEGER
 FIELD container_id AS INTEGER
 FIELD item_proc_compra_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttPurchaseItems
 FIELD item_proc_compra_id AS INTEGER
 FIELD codigo_erp AS CHARACTER
 INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttVersions
 FIELD versao_id AS INTEGER
 FIELD container_id AS INTEGER
 FIELD tipo_versao_id AS INTEGER
 FIELD ind_sit_versao AS INTEGER
 INDEX pk IS UNIQUE PRIMARY versao_id.
DEFINE TEMP-TABLE ttVersionItems
 FIELD item_container_custo_id AS INTEGER
 FIELD versao_id AS INTEGER
 FIELD item_container_id AS INTEGER
 FIELD item_custo_id AS INTEGER
 FIELD it_codigo AS CHARACTER
 FIELD vl_unit_prev AS DECIMAL DECIMALS 5
 FIELD vl_unit_realiz AS DECIMAL DECIMALS 5
 FIELD qt_alocada AS DECIMAL DECIMALS 2
 FIELD qt_confirm_emb AS DECIMAL DECIMALS 2
 FIELD qt_recebto_fisico AS DECIMAL DECIMALS 2
 INDEX pk IS UNIQUE PRIMARY item_container_custo_id.
DEFINE TEMP-TABLE ttItemCosts
 FIELD item_custo_id AS INTEGER
 FIELD dt_hr_custo AS DATETIME
 FIELD vl_unit_novo AS DECIMAL DECIMALS 2
 FIELD dt_referencia AS DATE
 FIELD caminho_arquivo AS CHARACTER
 FIELD cod_tipo_custo AS INTEGER
 FIELD memoria_calculo AS CHARACTER
 FIELD it_codigo AS CHARACTER
 FIELD qt_estoque AS DECIMAL DECIMALS 2
 FIELD qt_nf_mae AS DECIMAL DECIMALS 2
 FIELD qt_etiq_container AS DECIMAL DECIMALS 2
 FIELD qt_etiq_branco AS DECIMAL DECIMALS 2
 FIELD qt_etiq_outros_container AS DECIMAL DECIMALS 2
 FIELD vl_unit_anterior AS DECIMAL DECIMALS 2
 FIELD cod_situacao AS INTEGER
 FIELD cod_usuario AS CHARACTER
 FIELD qt_estoque_selecionado AS DECIMAL DECIMALS 2
 FIELD it_codigo_media AS CHARACTER
 FIELD qt_estoque_media AS DECIMAL DECIMALS 2
 FIELD vl_unit_media AS DECIMAL DECIMALS 2
 FIELD vl_unit_container AS DECIMAL DECIMALS 2
 FIELD qt_container AS DECIMAL DECIMALS 2
 FIELD media_custo_id AS INTEGER
 INDEX pk IS UNIQUE PRIMARY item_custo_id.
DEFINE TEMP-TABLE ttNfs
 FIELD documento AS CHARACTER
 FIELD serie AS CHARACTER
 FIELD estab AS CHARACTER
 FIELD nat_operacao AS CHARACTER
 FIELD cod_emitente AS INTEGER
 FIELD container_id AS INTEGER
.
DEFINE TEMP-TABLE ttLocations
 FIELD local_estoq_portal_id AS INTEGER
 FIELD cod_empresa AS CHARACTER
 FIELD cod_estab AS CHARACTER
 FIELD cod_depos AS CHARACTER
 INDEX pk IS UNIQUE PRIMARY local_estoq_portal_id.
DEFINE TEMP-TABLE ttLabels
 FIELD cod-estabel AS CHARACTER
 FIELD num-etiqueta AS INTEGER
 FIELD it-codigo AS CHARACTER
 FIELD nr-container AS INTEGER
 FIELD situacao AS INTEGER
 FIELD quantidade AS DECIMAL DECIMALS 5
.
DEFINE TEMP-TABLE ttStockIma
 FIELD it-codigo AS CHARACTER
 FIELD cod-estabel AS CHARACTER
 FIELD cod-depos AS CHARACTER
 FIELD qtidade-atu AS DECIMAL DECIMALS 4
.
DEFINE TEMP-TABLE ttStockMed
 FIELD it-codigo AS CHARACTER
 FIELD cod-estabel AS CHARACTER
 FIELD cod-depos AS CHARACTER
 FIELD qtidade-atu AS DECIMAL DECIMALS 4
.
DEFINE TEMP-TABLE ttMovementsMed
 FIELD nr-trans AS INT64
 FIELD it-codigo AS CHARACTER
 FIELD dt-trans AS DATE
 FIELD tipo-trans AS INTEGER
 FIELD quantidade AS DECIMAL DECIMALS 4
 INDEX pk IS UNIQUE PRIMARY nr-trans.
DEFINE TEMP-TABLE ttInvoicesIma
 FIELD cod-estabel AS CHARACTER
 FIELD serie AS CHARACTER
 FIELD nr-nota-fis AS CHARACTER
 FIELD dt-emis-nota AS DATE
 INDEX pk IS UNIQUE PRIMARY cod-estabel serie nr-nota-fis.
DEFINE TEMP-TABLE ttInvoicesMed
 FIELD cod-estabel AS CHARACTER
 FIELD serie AS CHARACTER
 FIELD nr-nota-fis AS CHARACTER
 FIELD dt-emis-nota AS DATE
 INDEX pk IS UNIQUE PRIMARY cod-estabel serie nr-nota-fis.
