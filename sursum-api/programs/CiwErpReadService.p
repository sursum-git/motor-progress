/* Leitura compartilhada e limitada: buffer/empresa recebidos apenas do wrapper.
   Nao calcula impostos/custos, nao escreve e nao aceita SQL ou origem do cliente. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phData AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER pcCompany AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE b AS HANDLE NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE cFieldList AS CHARACTER NO-UNDO.
DEFINE VARIABLE cAliasList AS CHARACTER NO-UNDO.
DEFINE VARIABLE cKeyList AS CHARACTER NO-UNDO.
DEFINE VARIABLE baseWhere AS CHARACTER NO-UNDO.
DEFINE VARIABLE whereText AS CHARACTER NO-UNDO.
DEFINE VARIABLE orderText AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE takeValue AS INTEGER NO-UNDO INITIAL 50.
DEFINE VARIABLE skipValue AS INTEGER NO-UNDO.
DEFINE VARIABLE totalValue AS INTEGER NO-UNDO.
DEFINE VARIABLE leaves AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
DEFINE VARIABLE direction AS CHARACTER NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE sorting AS JsonArray NO-UNDO.
DEFINE VARIABLE item AS JsonObject NO-UNDO.
DEFINE VARIABLE keyObject AS JsonObject NO-UNDO.
DEFINE VARIABLE seen AS JsonObject NO-UNDO.
DEFINE TEMP-TABLE ttRelationIdentity NO-UNDO FIELD record_key AS CHARACTER CASE-SENSITIVE INDEX pk IS PRIMARY UNIQUE record_key.
DEFINE VARIABLE ordered AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
DEFINE VARIABLE priorNumericFormat AS CHARACTER NO-UNDO.
DEFINE VARIABLE prepared AS LOGICAL NO-UNDO.
DEFINE VARIABLE scanComplete AS LOGICAL NO-UNDO.
DEFINE VARIABLE comparisonHasErrors AS LOGICAL NO-UNDO.
{sursum-api/includes/PurchaseOrderSnapshot.i}
{sursum-api/includes/PurchaseItemSnapshot.i}
{sursum-api/includes/PurchaseItemValueRules.i}
FUNCTION FilterExpr RETURNS CHARACTER (o AS JsonObject,depthValue AS INTEGER) FORWARD.
FUNCTION FieldHandle RETURNS HANDLE (nameValue AS CHARACTER):
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 n=LOOKUP(nameValue,cAliasList).
 IF n=0 THEN RUN Fail('CIW_ERP_FIELD_INVALID',422).
 IF (pcResource='despesas_impostos_geral' OR pcResource='container_nfs_disponiveis') AND NOT COMPARE(nameValue,'=',ENTRY(n,cAliasList),'RAW') THEN RUN Fail('CIW_ERP_FIELD_INVALID',422).
 RETURN b:BUFFER-FIELD(ENTRY(n,cFieldList)).
END FUNCTION.
FUNCTION TextChecked RETURNS CHARACTER (v AS CHARACTER):
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF v=? OR LENGTH(v)>256 THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
 DO n=1 TO LENGTH(v): IF ASC(SUBSTRING(v,n,1))<32 OR ASC(SUBSTRING(v,n,1))=127 THEN RUN Fail('CIW_ERP_VALUE_INVALID',422). END.
 RETURN v.
END FUNCTION.
FUNCTION NumText RETURNS CHARACTER (v AS DECIMAL):
 DEFINE VARIABLE resultValue AS CHARACTER NO-UNDO.
 resultValue=IF v=TRUNCATE(v,0) THEN TRIM(STRING(v,'->>>>>>>>>>>>>>>>>>>>9')) ELSE TRIM(STRING(v,'->>>>>>>>>>>>>>>>>>>>9.9999999999')).
 IF INDEX(resultValue,'*')>0 OR v=? THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
 RETURN REPLACE(resultValue,SESSION:NUMERIC-DECIMAL-POINT,'.').
END FUNCTION.
FUNCTION IntValue RETURNS INTEGER (o AS JsonObject,nameValue AS CHARACTER,minValue AS INTEGER,maxValue AS INTEGER):
 DEFINE VARIABLE v AS DECIMAL NO-UNDO.
 IF o:GetType(nameValue)<>JsonDataType:NUMBER THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
 v=o:GetDecimal(nameValue).
 IF v<minValue OR v>maxValue OR v<>TRUNCATE(v,0) THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
 RETURN INTEGER(v).
END FUNCTION.
FUNCTION Literal RETURNS CHARACTER (o AS JsonObject,nameValue AS CHARACTER,f AS HANDLE):
 DEFINE VARIABLE d AS DATE NO-UNDO.
 DEFINE VARIABLE v AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS DECIMAL NO-UNDO.
 IF NOT o:Has(nameValue) THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
 IF o:IsNull(nameValue) THEN RETURN '?'.
 CASE f:DATA-TYPE:
  WHEN 'CHARACTER' THEN DO:
   IF o:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   IF pcResource='container_nfs_disponiveis' THEN
    RETURN QUOTER(REPLACE(TextChecked(o:GetCharacter(nameValue)),CHR(126),CHR(126) + CHR(126))).
   RETURN QUOTER(TextChecked(o:GetCharacter(nameValue))).
  END.
  WHEN 'INTEGER' THEN RETURN NumText(IntValue(o,nameValue,-2147483648,2147483647)).
  WHEN 'LOGICAL' THEN DO:
   IF o:GetType(nameValue)<>JsonDataType:BOOLEAN THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   RETURN IF o:GetLogical(nameValue) THEN 'TRUE' ELSE 'FALSE'.
  END.
  WHEN 'DECIMAL' THEN DO:
   IF o:GetType(nameValue)<>JsonDataType:NUMBER THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   IF pcResource='proc_compra_itens' THEN DO:
    IF NOT PurchaseItemDecimalFits(STRING(o:GetJsonText(nameValue)),f:DECIMALS) THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
    n=PurchaseItemDecimalNumber(STRING(o:GetJsonText(nameValue))).
   END.
   ELSE n=o:GetDecimal(nameValue).
   IF ABSOLUTE(n)>999999999999999999 THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   IF n<>ROUND(n,10) THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   RETURN NumText(n).
  END.
  WHEN 'DATE' THEN DO:
   IF o:GetType(nameValue)<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   v=o:GetCharacter(nameValue).
   IF LENGTH(v)<>10 OR SUBSTRING(v,5,1)<>'-' OR SUBSTRING(v,8,1)<>'-' THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   d=DATE(INTEGER(SUBSTRING(v,6,2)),INTEGER(SUBSTRING(v,9,2)),INTEGER(SUBSTRING(v,1,4))) NO-ERROR.
   IF ERROR-STATUS:ERROR OR d=? THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   IF ISO-DATE(d)<>v THEN RUN Fail('CIW_ERP_VALUE_INVALID',422).
   RETURN 'DATE(' + NumText(MONTH(d)) + ',' + NumText(DAY(d)) + ',' + NumText(YEAR(d)) + ')'.
  END.
  OTHERWISE RUN Fail('CIW_ERP_SCHEMA_INVALID',503).
 END CASE.
 RETURN ''.
END FUNCTION.
FUNCTION FilterExpr RETURNS CHARACTER (o AS JsonObject,depthValue AS INTEGER):
 DEFINE VARIABLE localNames AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE resultValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE logicValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE operatorValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE fieldValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE valueText AS CHARACTER NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE children AS JsonArray NO-UNDO.
 IF depthValue>6 OR NOT VALID-OBJECT(o) THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
 localNames=o:GetNames().
 IF o:Has('filters') THEN DO:
  DO k=1 TO EXTENT(localNames): IF LOOKUP(localNames[k],'logic,filters')=0 THEN RUN Fail('CIW_ERP_FILTER_INVALID',422). END.
  IF o:GetType('filters')<>JsonDataType:ARRAY OR NOT o:Has('logic') OR o:GetType('logic')<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
  logicValue=o:GetCharacter('logic'). IF LOOKUP(logicValue,'and,or')=0 THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
  children=o:GetJsonArray('filters'). IF children:Length<1 OR children:Length>50 THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
  DO k=1 TO children:Length:
   IF children:GetType(k)<>JsonDataType:OBJECT THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
   IF k>1 THEN resultValue=resultValue + ' ' + logicValue + ' '.
   resultValue=resultValue + '(' + FilterExpr(children:GetJsonObject(k),depthValue + 1) + ')'.
  END.
  RETURN resultValue.
 END.
 leaves=leaves + 1. IF leaves>50 THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
 DO k=1 TO EXTENT(localNames): IF LOOKUP(localNames[k],'field,operator,value,ignoreCase')=0 THEN RUN Fail('CIW_ERP_FILTER_INVALID',422). END.
 IF NOT o:Has('field') OR NOT o:Has('operator') OR o:GetType('field')<>JsonDataType:STRING OR o:GetType('operator')<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
 IF o:Has('ignoreCase') THEN IF o:GetType('ignoreCase')<>JsonDataType:BOOLEAN OR NOT o:GetLogical('ignoreCase') THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
 IF comparisonHasErrors AND LOOKUP(o:GetCharacter('field'),'vl_tot_prev,vl_tot_sem_distr_custo,vl_unit_sem_distr_custo,vl_desp_prev_perc_fixo,vl_tot_perc_fixo,vl_unit_perc_fixo')>0 THEN RUN Fail('COMPARISON_DERIVED_FILTER_UNPROVEN',503).
 f=FieldHandle(o:GetCharacter('field')). fieldValue=b:NAME + '.' + f:NAME. operatorValue=o:GetCharacter('operator').
 IF LOOKUP(operatorValue,'isnull,isnotnull')>0 THEN DO:
  IF o:Has('value') THEN IF NOT o:IsNull('value') THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
  RETURN fieldValue + (IF operatorValue='isnull' THEN ' = ?' ELSE ' <> ?').
 END.
 IF LOOKUP(operatorValue,'isempty,isnotempty')>0 THEN DO:
  IF f:DATA-TYPE<>'CHARACTER' THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
  RETURN fieldValue + (IF operatorValue='isempty' THEN " = ''" ELSE " <> ''").
 END.
 valueText=Literal(o,'value',f).
 IF f:DATA-TYPE='LOGICAL' AND LOOKUP(operatorValue,'eq,neq')=0 THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
 CASE operatorValue:
  WHEN 'eq' THEN RETURN fieldValue + ' = ' + valueText.
  WHEN 'neq' THEN RETURN fieldValue + ' <> ' + valueText.
  WHEN 'gt' THEN RETURN fieldValue + ' > ' + valueText.
  WHEN 'gte' THEN RETURN fieldValue + ' >= ' + valueText.
  WHEN 'lt' THEN RETURN fieldValue + ' < ' + valueText.
  WHEN 'lte' THEN RETURN fieldValue + ' <= ' + valueText.
  WHEN 'startswith' OR WHEN 'contains' OR WHEN 'doesnotcontain' OR WHEN 'endswith' THEN DO:
   IF f:DATA-TYPE<>'CHARACTER' OR valueText='?' THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
   CASE operatorValue:
    WHEN 'startswith' THEN RETURN fieldValue + ' BEGINS ' + valueText.
    WHEN 'contains' THEN RETURN 'INDEX(' + fieldValue + ',' + valueText + ') > 0'.
    WHEN 'doesnotcontain' THEN RETURN 'INDEX(' + fieldValue + ',' + valueText + ') = 0'.
    WHEN 'endswith' THEN RETURN 'SUBSTRING(' + fieldValue + ',MAXIMUM(1,LENGTH(' + fieldValue + ')-LENGTH(' + valueText + ')+1)) = ' + valueText.
   END CASE.
  END.
 END CASE.
 RUN Fail('CIW_ERP_FILTER_INVALID',422). RETURN ''.
END FUNCTION.
FUNCTION RowJson RETURNS JsonObject ():
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE k AS JsonObject NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE nameValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE lc AS LONGCHAR NO-UNDO.
 IF pcResource='container_nfs_disponiveis' THEN DO:
  /* This private fixed TT is supplied by the Finance service only. Return
     its NfRow JSON verbatim; do not rebuild the NF mapper or opaque key. */
  FIX-CODEPAGE(lc)='UTF-8'. lc=b:BUFFER-FIELD('nf_original_json'):BUFFER-VALUE.
  IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
  RETURN CAST(parser:Parse(lc),JsonObject).
 END.
 IF pcResource='procs_compra_med' THEN RETURN PurchaseOrderData(b).
 o=NEW JsonObject(). k=NEW JsonObject().
 DO n=1 TO NUM-ENTRIES(cFieldList):
  f=b:BUFFER-FIELD(ENTRY(n,cFieldList)). nameValue=ENTRY(n,cAliasList).
  IF f:BUFFER-VALUE=? THEN o:AddNull(nameValue).
  ELSE CASE f:DATA-TYPE:
   WHEN 'CHARACTER' THEN o:Add(nameValue,STRING(f:BUFFER-VALUE)).
   WHEN 'INTEGER' THEN o:Add(nameValue,INTEGER(f:BUFFER-VALUE)).
   WHEN 'DECIMAL' THEN o:Add(nameValue,DECIMAL(f:BUFFER-VALUE)).
   WHEN 'DATE' THEN o:Add(nameValue,ISO-DATE(DATE(f:BUFFER-VALUE))).
   WHEN 'LOGICAL' THEN o:Add(nameValue,LOGICAL(f:BUFFER-VALUE)).
   WHEN 'DATETIME' THEN DO: IF pcResource<>'item_custos_manual' THEN RUN Fail('CIW_ERP_SCHEMA_INVALID',503). o:Add(nameValue,ISO-DATE(DATETIME(f:BUFFER-VALUE))). END.
   OTHERWISE RUN Fail('CIW_ERP_SCHEMA_INVALID',503).
  END CASE.
  IF LOOKUP(nameValue,cKeyList)>0 THEN DO:
   IF o:IsNull(nameValue) THEN DO:
    IF pcResource<>'despesas_impostos_geral' THEN RUN Fail('CIW_ERP_KEY_INVALID',409).
    k:AddNull(nameValue).
   END.
   ELSE CASE f:DATA-TYPE:
    WHEN 'CHARACTER' THEN k:Add(nameValue,o:GetCharacter(nameValue)).
    WHEN 'INTEGER' THEN k:Add(nameValue,o:GetInteger(nameValue)).
   END CASE.
  END.
 END.
 IF LOOKUP(pcResource,'proc_compra_itens,proc_compra_amostras,proc_compra_anexos,proc_compra_documentos,proc_compra_despesas,proc_compra_resumo,proc_compra_alocacoes,container_calculos_impostos_med,container_despesa_memoria_med,container_despesas_lote')>0 THEN DO: DELETE OBJECT k. RETURN o. END.
 k:Write(lc,FALSE). o:Add('record_key',STRING(lc)). DELETE OBJECT k. RETURN o.
END FUNCTION.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-HANDLE(phData) OR NOT VALID-OBJECT(poRequest) THEN RUN Fail('CIW_ERP_UNAVAILABLE',503).
 CREATE BUFFER b FOR TABLE phData BUFFER-NAME 'bCiwErpRead'.
 CASE pcResource:
  WHEN 'container_nfs_disponiveis' THEN ASSIGN cFieldList='container_id,nf_key,documento_localizado,estab,documento,serie,cod_emitente,nat_operacao,especie,dt_emissao,dt_trans,tot_valor,despesa_nota,valor_embal,valor_frete,valor_mercad,valor_outras,valor_seguro' cAliasList=cFieldList cKeyList='nf_key' baseWhere='TRUE'.
  WHEN 'despesas_impostos_geral' THEN ASSIGN cFieldList='despesa_id,imposto_id,empresa_id' cAliasList=cFieldList cKeyList=cFieldList baseWhere='TRUE'.
  WHEN 'item_custos_manual' THEN ASSIGN cFieldList='item_custo_id,dt_hr_custo,vl_unit_novo,dt_referencia,caminho_arquivo,cod_tipo_custo,memoria_calculo,it_codigo,qt_estoque,qt_nf_mae,qt_etiq_container,qt_etiq_branco,qt_etiq_outros_container,vl_unit_anterior,cod_situacao,cod_usuario,qt_estoque_selecionado,it_codigo_media,qt_estoque_media,vl_unit_media,vl_unit_container,qt_container,media_custo_id' cAliasList=cFieldList cKeyList='item_custo_id' baseWhere=b:NAME + '.cod_tipo_custo = 1'.
  WHEN 'item_container_amostra' THEN ASSIGN cFieldList='item_container_id,codigo_erp,descricao,container_id' cAliasList=cFieldList cKeyList='item_container_id' baseWhere='TRUE'.
  WHEN 'import_descontos_geral' THEN ASSIGN cFieldList='desconto_importacao_id,motivo_desconto_id,descricao,log_credito,vl_dolar,vl_real,vl_cotacao_dolar,item_container_id,cod_tipo,fornecedor_id,vl_real_autorizado,vl_dolar_autorizado,dt_autorizacao,vl_utiliz,vl_utiliz_detalhe,vl_saldo,item_codigo_erp_atual,item_descricao_atual,fornecedor_nome_abrev_atual,motivo_descricao_atual' cAliasList=cFieldList cKeyList='desconto_importacao_id' baseWhere='TRUE'.
  WHEN 'import_descontos_lancamentos' THEN ASSIGN cFieldList='cta_corren_desconto_id,desconto_importacao_id,container_id,valor_utilizado,data,cod_usuario' cAliasList=cFieldList cKeyList='desconto_importacao_id,cta_corren_desconto_id' baseWhere='TRUE'.
  WHEN 'custo_distribuicao_itens_aptos' THEN ASSIGN cFieldList='pedido_imp,processo_fornec,fornec_pi,item_pedido,container,fornec,item_container,descricao,codigo_erp,fornec_pi_nome_abrev_atual,fornec_nome_abrev_atual' cAliasList=cFieldList cKeyList='item_container' baseWhere='TRUE'.
  WHEN 'custo_distribuicao_lancamentos_item' THEN ASSIGN cFieldList='cta_corren_custo_distr_id,data,historico,vl_lancto,login,item_container_custo_id,item_container_id,cod_tipo_movto' cAliasList=cFieldList cKeyList='item_container_id,cta_corren_custo_distr_id' baseWhere='TRUE'.
  WHEN 'container_versao_pagtos_historico_med' THEN ASSIGN cFieldList='container_id,versao_id,num_id_tit_ap,vl_real,vl_dolar' cAliasList=cFieldList cKeyList='container_id,versao_id,num_id_tit_ap' baseWhere='TRUE'.
  WHEN 'container_versao_nfs_historico_med' THEN ASSIGN cFieldList='container_id,versao_id,documento,serie,estab,nat_operacao,cod_emitente,vl_mercadoria,vl_despesa,emitente_nome_abrev_atual' cAliasList=cFieldList cKeyList='container_id,versao_id,documento,serie,estab,nat_operacao,cod_emitente' baseWhere='TRUE'.
  WHEN 'container_versao_descontos_historico_med' THEN ASSIGN cFieldList='container_id,versao_id,desconto_importacao_id,vl_autoriz_real,vl_autoriz_dolar,log_custo' cAliasList=cFieldList cKeyList='container_id,versao_id,desconto_importacao_id' baseWhere='TRUE'.
  WHEN 'container_versao_despesas_historico_med' THEN ASSIGN cFieldList='container_id,versao_id,despesa_id,vl_prev,vl_base_imp,vl_negociado,log_custo,despesa_descricao_atual' cAliasList=cFieldList cKeyList='container_id,versao_id,despesa_id' baseWhere='TRUE'.
  WHEN 'container_custos_comparacao_real' OR WHEN 'container_custos_comparacao_dolar' THEN ASSIGN cFieldList='container_id,versao_id,item_container_custo_id,item_container_id,codigo_erp,descricao,qt_alocada,qt_confirm_emb,vl_custo_prev,vl_desp_prev,vl_tot_prev,vl_unit_prev,vl_desp_prev_sem_distr_custo,vl_tot_sem_distr_custo,vl_unit_sem_distr_custo,vl_desp_prev_perc_fixo,vl_tot_perc_fixo,vl_unit_perc_fixo' cAliasList=cFieldList cKeyList='container_id,versao_id,item_container_custo_id' baseWhere='TRUE'.
  WHEN 'container_versoes_historico_med' THEN ASSIGN
   cFieldList='container_id,item_container_custo_id,versao_id,item_container_id,it_codigo,item_custo_id,memoria_calculo,vl_desp_prev_real,vl_custo_prev_real,vl_pago_real,qt_alocada,qt_confirm_emb,qt_recebto_fisico,vl_desp_realiz_real,vl_unit_prev,vl_unit_realiz,vl_desp_prev_dolar,vl_custo_prev_dolar,vl_pago_dolar,vl_desp_realiz_dolar,vl_desconto_utiliz_dolar,vl_unit_prev_dolar,vl_unit_realiz_dolar,vl_custo_distribuido,vl_negociado,vl_desp_prev_real_sem_distr_cust,vl_desp_prev_dolar_sem_distr_cus,qt_embarcada,vl_desconto_utiliz_real,item_descricao_atual'
   cAliasList=cFieldList cKeyList='container_id,versao_id,item_container_custo_id' baseWhere='TRUE'.
  WHEN 'proc_compra_anexos' OR WHEN 'proc_compra_documentos' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='anexo_proc_compra_id,proc_compra_id,item_proc_compra_id,descricao,tipos_anexo_id,caminho_arquivo,dt_hr_arquivo,proc_compra_id_registro,row_stamp,tipo_anexo_descricao,arquivo_upload' cAliasList=cFieldList cKeyList='anexo_proc_compra_id' baseWhere=b:NAME + (IF pcResource='proc_compra_anexos' THEN '.item_proc_compra_id = ' ELSE '.proc_compra_id = ') + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_quantidades_periodo_med' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='row_key,empresa_id,cod_situacao,pedido_fornec,vl_negociado,qt_comprada,qt_confirmada_embarque,qt_recbto_fisico,qt_rec_final,vl_rec_final,qt_comprada_final,vl_comprada_final,nr_container,situacao_container,dt_registro,dt_recebimento,dt_prev_chegada,codigo_erp,desc_item_fornec,desc_situacao_container' cAliasList=cFieldList cKeyList='row_key'
    baseWhere=b:NAME + '.empresa_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_quantidades' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='proc_compra_id,empresa_id,item_proc_compra_id,item_container_id,container_id,cod_situacao,pedido_fornec,codigo_erp,desc_item_fornec,qt_comprada_final,vl_comprada_final,qt_rec_final,vl_rec_final,nr_container,situacao_container,dt_registro,dt_recebimento,dt_prev_chegada,qt_comprada,vl_negociado,qt_confirmada_embarque,qt_recbto_fisico,desc_situacao_container' cAliasList=cFieldList cKeyList='proc_compra_id,item_proc_compra_id,item_container_id'
    baseWhere=b:NAME + '.empresa_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_sinalizadores' THEN DO:
   ASSIGN cFieldList='sinaliz_imp_id,tipo_registro,nome_alerta,titulo_configurado,descricao_alerta,dias_alerta,quantidade,data_consulta' cAliasList=cFieldList cKeyList='sinaliz_imp_id' baseWhere='TRUE'.
  END.
  WHEN 'proc_compra_sinalizados' THEN DO:
   ASSIGN cFieldList='sinaliz_imp_id,proc_compra_id,item_proc_compra_id,container_id,tipo_registro,nome_alerta,titulo_configurado,descricao_alerta,dias_alerta,data_base,data_alerta,data_consulta,cod_proc_fornec,fornecedor_id,item_descricao,codigo_erp,link_proc_compra_id,link_container_id' cAliasList=cFieldList cKeyList='sinaliz_imp_id,tipo_registro,proc_compra_id,item_proc_compra_id,container_id' baseWhere='TRUE'.
  END.
  WHEN 'proc_compra_alertas' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='sinaliz_imp_id,proc_compra_id,item_proc_compra_id,tipo_registro,nome_alerta,titulo_configurado,descricao_alerta,dias_alerta,data_base,data_alerta,data_consulta,cod_proc_fornec,fornecedor_id,item_descricao,codigo_erp'
    cAliasList=cFieldList cKeyList='sinaliz_imp_id,proc_compra_id,item_proc_compra_id' baseWhere=b:NAME + '.proc_compra_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'container_calculos_impostos_med' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='calc_imp_container_id,container_id,dt_hr_calculo,data_calculo,usuario_id,memoria_calculo,desc_memoria_calc' cAliasList=cFieldList cKeyList='calc_imp_container_id' baseWhere=b:NAME + '.container_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'container_despesa_memoria_med' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='despesa_container_id,container_id,calc_imp_container_id,memoria_calculo,link_calculo_id' cAliasList=cFieldList cKeyList='despesa_container_id' baseWhere=b:NAME + '.container_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'container_despesas_lote' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='despesa_container_id,despesa_id,vl_prev,container_id,calc_imp_container_id,vl_base_imp,vl_negociado,vl_proforma,cta_corren_custo_distr_id,log_utilizado,log_manual,perc_calc,memoria_calculo,item_container_id' cAliasList=cFieldList cKeyList='despesa_container_id' baseWhere=b:NAME + '.container_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_alocacoes' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='item_container_id,proc_compra_id,item_proc_compra_id,container_id,qt_alocada,situacao,situacao_descricao,situacao_container_id,situacao_acomp' cAliasList=cFieldList cKeyList='item_container_id' baseWhere=b:NAME + '.item_proc_compra_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_resumo' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='proc_compra_id,qt_container,cotacao_prevista,custo_prev_itens,despesas_base,custo_prev_despesas' cAliasList=cFieldList cKeyList='proc_compra_id' baseWhere=b:NAME + '.proc_compra_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_despesas' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='despesa_proc_compra_id,proc_compra_id,despesa_id,vl_prev,calc_imp_proc_compra_id,row_stamp,despesa_descricao' cAliasList=cFieldList cKeyList='despesa_proc_compra_id' baseWhere=b:NAME + '.proc_compra_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'proc_compra_amostras' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='envio_amostra_repres_id,item_proc_compra_id,cod_rep,dt_envio,apont_amostra_id,proc_compra_id,row_stamp,representante_nome' cAliasList=cFieldList cKeyList='envio_amostra_repres_id' baseWhere=b:NAME + '.item_proc_compra_id = ' + NumText(DECIMAL(pcCompany)).
  END.

  WHEN 'proc_compra_itens' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList=PurchaseItemFields() + ',row_stamp,qt_alocada,qt_saldo,calc_gm' cAliasList=cFieldList cKeyList='item_proc_compra_id'
    baseWhere=b:NAME + '.proc_compra_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'procs_compra_med' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList=PurchaseOrderFields() cAliasList=cFieldList cKeyList='proc_compra_id'
    baseWhere=b:NAME + '.empresa_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'processos_compra_med' THEN DO:
   IF pcCompany=? OR pcCompany='' THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='proc_compra_id,empresa_id,fornecedor_id,cod_proc_fornec,dt_registro,cod_situacao'
    cAliasList=cFieldList cKeyList='proc_compra_id'
    baseWhere=b:NAME + '.empresa_id = ' + NumText(DECIMAL(pcCompany)).
  END.
  WHEN 'notas_fiscais_med' THEN ASSIGN
   cFieldList='nr-nota-fis,cod-emitente,nat-operacao,dt-emis-nota,vl-tot-nota,vl-mercad,val-desp-outros,val-desp-outros-inf,cod-estabel,serie'
   cAliasList='nr_nota_fis,cod_emitente,nat_operacao,dt_emis_nota,vl_tot_nota,vl_mercad,val_desp_outros,val_desp_outros_inf,cod_estabel,serie'
   cKeyList='cod_estabel,serie,nr_nota_fis' baseWhere=b:NAME + ".nat-operacao BEGINS '3'".
  WHEN 'titulos_pagar_med' THEN DO:
   IF pcCompany=? OR pcCompany='' OR LENGTH(pcCompany)>32 THEN RUN Fail('CIW_ERP_COMPANY_UNAVAILABLE',503).
   ASSIGN cFieldList='cod_estab,cod_espec_docto,cod_ser_docto,cdn_fornecedor,cod_tit_ap,cod_parcela,dat_emis_docto,dat_vencto_tit_ap,cod_indic_econ,val_origin_tit_ap,cod_empresa,num_id_tit_ap'
    cAliasList=cFieldList cKeyList='cod_empresa,cod_estab,num_id_tit_ap'
    baseWhere=b:NAME + '.cod_empresa = ' + QUOTER(TextChecked(pcCompany)) + ' AND ' + b:NAME + '.log_tit_ap_estordo = FALSE AND SUBSTRING(' + b:NAME + ".ind_tip_espec_docto,1,8) = 'antecipa'".
  END.
  OTHERWISE RUN Fail('CIW_ERP_RESOURCE_INVALID',422).
 END CASE.
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_REQUEST_INVALID',422).
 op=poRequest:GetCharacter('operation'). IF LOOKUP(op,'read,get')=0 THEN RUN Fail('CIW_ERP_READ_ONLY',405).
 IF pcResource='container_nfs_disponiveis' AND op<>'read' THEN RUN Fail('CIW_ERP_READ_ONLY',405).
 EXTENT(names)=?. names=poRequest:GetNames().
 DO i=1 TO EXTENT(names):
  IF LOOKUP(names[i],IF op='get' THEN 'operation,id,record_key' ELSE 'operation,skip,take,filter,sort')=0 THEN RUN Fail('CIW_ERP_REQUEST_INVALID',422).
 END.
 IF poRequest:Has('take') THEN takeValue=IntValue(poRequest,'take',1,200).
 IF poRequest:Has('skip') THEN skipValue=IntValue(poRequest,'skip',0,100000).
 whereText='(' + baseWhere + ')'.
 IF LOOKUP(pcResource,'container_custos_comparacao_real,container_custos_comparacao_dolar')>0 THEN DO:
  comparisonHasErrors=b:FIND-FIRST('WHERE ' + b:NAME + '.projection_error <> ' + QUOTER(''),NO-LOCK) NO-ERROR.
  DO i=1 TO ERROR-STATUS:NUM-MESSAGES: IF ERROR-STATUS:GET-NUMBER(i)<>565 THEN RUN Fail('COMPARISON_CONFIGURATION',503). END.
 END.
 IF poRequest:Has('filter') AND NOT poRequest:IsNull('filter') THEN DO:
  IF poRequest:GetType('filter')<>JsonDataType:OBJECT THEN RUN Fail('CIW_ERP_FILTER_INVALID',422).
  whereText=whereText + ' AND (' + FilterExpr(poRequest:GetJsonObject('filter'),0) + ')'.
 END.
 ordered=NEW JsonObject().
 IF poRequest:Has('sort') THEN DO:
  IF poRequest:GetType('sort')<>JsonDataType:ARRAY THEN RUN Fail('CIW_ERP_SORT_INVALID',422).
  sorting=poRequest:GetJsonArray('sort'). IF sorting:Length>4 THEN RUN Fail('CIW_ERP_SORT_INVALID',422).
  DO i=1 TO sorting:Length:
   IF sorting:GetType(i)<>JsonDataType:OBJECT THEN RUN Fail('CIW_ERP_SORT_INVALID',422).
   item=sorting:GetJsonObject(i). EXTENT(names)=?. names=item:GetNames().
   DO j=1 TO EXTENT(names): IF LOOKUP(names[j],'field,dir')=0 THEN RUN Fail('CIW_ERP_SORT_INVALID',422). END.
   IF NOT item:Has('field') OR NOT item:Has('dir') OR item:GetType('field')<>JsonDataType:STRING OR item:GetType('dir')<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_SORT_INVALID',422).
   fieldName=item:GetCharacter('field'). direction=item:GetCharacter('dir').
   IF LOOKUP(direction,'asc,desc')=0 OR ordered:Has(fieldName) THEN RUN Fail('CIW_ERP_SORT_INVALID',422).
   orderText=orderText + ' BY ' + b:NAME + '.' + FieldHandle(fieldName):NAME + (IF direction='desc' THEN ' DESCENDING' ELSE ''). ordered:Add(fieldName,TRUE).
  END.
 END.
 IF pcResource='container_nfs_disponiveis' AND orderText='' THEN
  orderText=' BY ' + b:NAME + '.documento BY ' + b:NAME + '.serie BY ' + b:NAME + '.nat_operacao'.
 DO i=1 TO NUM-ENTRIES(cKeyList):
  fieldName=ENTRY(i,cKeyList). IF NOT ordered:Has(fieldName) THEN orderText=orderText + ' BY ' + b:NAME + '.' + FieldHandle(fieldName):NAME.
 END.
 IF op='get' THEN DO:
  IF NOT poRequest:Has('id') OR poRequest:GetType('id')<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
  IF poRequest:Has('record_key') THEN DO:
   IF poRequest:GetType('record_key')<>JsonDataType:STRING THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
   IF NOT COMPARE(poRequest:GetCharacter('record_key'),'=',poRequest:GetCharacter('id'),'RAW') THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
  END.
  IF LENGTH(poRequest:GetCharacter('id'))>2048 THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
  parser=NEW ObjectModelParser(). keyObject=CAST(parser:Parse(poRequest:GetCharacter('id')),JsonObject) NO-ERROR.
  IF ERROR-STATUS:ERROR OR NOT VALID-OBJECT(keyObject) THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
  EXTENT(names)=?. names=keyObject:GetNames(). IF EXTENT(names)<>NUM-ENTRIES(cKeyList) THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
  DO i=1 TO NUM-ENTRIES(cKeyList):
   fieldName=ENTRY(i,cKeyList). IF NOT keyObject:Has(fieldName) THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
   IF keyObject:IsNull(fieldName) AND pcResource<>'despesas_impostos_geral' THEN RUN Fail('CIW_ERP_KEY_INVALID',422).
   whereText=whereText + ' AND ' + b:NAME + '.' + FieldHandle(fieldName):NAME + ' = ' + Literal(keyObject,fieldName,FieldHandle(fieldName)).
  END.
 END.
 rows=NEW JsonArray(). seen=NEW JsonObject(). CREATE QUERY q. q:SET-BUFFERS(b).
 /* O texto fechado usa literais canonicos. Restaurar o estado da sessao ate em erro. */
 priorNumericFormat=SESSION:NUMERIC-FORMAT.
 DO ON ERROR UNDO, THROW:
  SESSION:NUMERIC-FORMAT='AMERICAN'.
  prepared=q:QUERY-PREPARE('FOR EACH ' + b:NAME + ' WHERE ' + whereText + ' NO-LOCK' + orderText).
  FINALLY: SESSION:NUMERIC-FORMAT=priorNumericFormat. END FINALLY.
 END.
 IF NOT prepared THEN RUN Fail('CIW_ERP_QUERY_UNAVAILABLE',503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
 q:QUERY-OPEN(). q:GET-FIRST(NO-LOCK).
 DO WHILE NOT q:QUERY-OFF-END:
  totalValue=totalValue + 1.
  IF pcResource='container_nfs_disponiveis' AND totalValue>50000 THEN RUN Fail('CONTAINER_NF_SOURCE_LIMIT',503).
  IF (pcResource='item_custos_manual' OR pcResource='despesas_impostos_geral') AND totalValue>50000 THEN RUN Fail('CIW_ERP_QUERY_LIMIT',503).
  IF LOOKUP(pcResource,'container_custos_comparacao_real,container_custos_comparacao_dolar')>0 THEN DO:
   IF totalValue>50000 THEN RUN Fail('CIW_ERP_QUERY_LIMIT',503).
   IF b:BUFFER-FIELD('projection_error'):BUFFER-VALUE='COMPARISON_ZERO_DIVISOR' THEN RUN Fail('COMPARISON_ZERO_DIVISOR',422).
   IF b:BUFFER-FIELD('projection_error'):BUFFER-VALUE<>'' THEN RUN Fail('COMPARISON_CONFIGURATION',503).
  END.
  IF op='get' AND totalValue>1 THEN RUN Fail('CIW_ERP_KEY_AMBIGUOUS',409).
  IF pcResource='despesas_impostos_geral' THEN DO:
   /* UNKNOWN components permit duplicate UNIQUE index entries. Validate the
      complete bounded result before accepting any page; never deduplicate. */
   item=RowJson(). fieldName=item:GetCharacter('record_key'). DELETE OBJECT item.
   IF CAN-FIND(ttRelationIdentity WHERE ttRelationIdentity.record_key=fieldName) THEN RUN Fail('CIW_ERP_KEY_AMBIGUOUS',409).
   CREATE ttRelationIdentity. ttRelationIdentity.record_key=fieldName. RELEASE ttRelationIdentity.
  END.
  IF op='get' OR totalValue>skipValue AND rows:Length<takeValue THEN DO:
   item=RowJson(). fieldName=IF LOOKUP(pcResource,'procs_compra_med,proc_compra_resumo')>0 THEN NumText(item:GetInteger('proc_compra_id')) ELSE IF pcResource='container_calculos_impostos_med' THEN NumText(item:GetInteger('calc_imp_container_id')) ELSE IF pcResource='container_despesa_memoria_med' THEN NumText(item:GetInteger('despesa_container_id')) ELSE IF pcResource='container_despesas_lote' THEN NumText(item:GetInteger('despesa_container_id')) ELSE IF pcResource='proc_compra_alocacoes' THEN NumText(item:GetInteger('item_container_id')) ELSE IF pcResource='proc_compra_itens' THEN NumText(item:GetInteger('item_proc_compra_id')) ELSE IF LOOKUP(pcResource,'proc_compra_anexos,proc_compra_documentos')>0 THEN NumText(item:GetInteger('anexo_proc_compra_id')) ELSE IF pcResource='proc_compra_despesas' THEN NumText(item:GetInteger('despesa_proc_compra_id')) ELSE IF pcResource='proc_compra_amostras' THEN NumText(item:GetInteger('envio_amostra_repres_id')) ELSE IF pcResource='container_nfs_disponiveis' THEN item:GetCharacter('nf_key') ELSE item:GetCharacter('record_key').
   IF seen:Has(fieldName) THEN RUN Fail('CIW_ERP_KEY_AMBIGUOUS',409).
   seen:Add(fieldName,TRUE). rows:Add(item).
  END.
  q:GET-NEXT(NO-LOCK).
 END.
 scanComplete=TRUE.
 END.
 IF NOT scanComplete THEN RUN Fail('CIW_ERP_QUERY_TIMEOUT',503).
 IF op='get' AND totalValue=0 THEN RUN Fail('CIW_ERP_NOT_FOUND',404).
 poResponse=NEW JsonObject(). poResponse:Add('success',TRUE).
 IF op='get' THEN poResponse:Add('data',rows:GetJsonObject(1)).
 ELSE DO: poResponse:Add('data',rows). poResponse:Add('total',totalValue). END.
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('CIW_ERP_UNAVAILABLE',503).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(q) THEN DELETE OBJECT q NO-ERROR.
  IF VALID-HANDLE(b) THEN DELETE OBJECT b NO-ERROR.
  IF VALID-OBJECT(ordered) THEN DELETE OBJECT ordered NO-ERROR.
  IF VALID-OBJECT(seen) THEN DELETE OBJECT seen NO-ERROR.
  IF VALID-OBJECT(keyObject) THEN DELETE OBJECT keyObject NO-ERROR.
  IF VALID-OBJECT(parser) THEN DELETE OBJECT parser NO-ERROR.
 END FINALLY.
END.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 DEFINE VARIABLE errorObject AS JsonObject NO-UNDO.
 poResponse=NEW JsonObject(). errorObject=NEW JsonObject(). errorObject:Add('code',code). errorObject:Add('status',statusCode).
 errorObject:Add('message','Consulta ERP MED invalida ou indisponivel. Confira os filtros e tente novamente.'). poResponse:Add('success',FALSE). poResponse:Add('error',errorObject).
END PROCEDURE.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusCode AS INTEGER NO-UNDO.
 RUN ErrorResponse(code,statusCode). UNDO,THROW NEW Progress.Lang.AppError(code,0).
END PROCEDURE.

