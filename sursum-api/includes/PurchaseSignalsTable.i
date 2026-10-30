/* Shared projection contract for contextual and global signals. */
DEFINE TEMP-TABLE ttSignalRead NO-UNDO
 FIELD sinaliz_imp_id AS INTEGER FIELD proc_compra_id AS INTEGER FIELD item_proc_compra_id AS INTEGER
 FIELD tipo_registro AS CHARACTER FIELD nome_alerta AS CHARACTER FIELD titulo_configurado AS CHARACTER FIELD descricao_alerta AS CHARACTER
 FIELD dias_alerta AS INTEGER FIELD data_base AS DATE FIELD data_alerta AS DATE FIELD data_consulta AS DATE
 FIELD cod_proc_fornec AS CHARACTER FIELD fornecedor_id AS INTEGER FIELD item_descricao AS CHARACTER FIELD codigo_erp AS CHARACTER
 INDEX pk IS PRIMARY UNIQUE sinaliz_imp_id proc_compra_id item_proc_compra_id.
