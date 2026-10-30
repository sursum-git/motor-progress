PROCEDURE TableDef:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER cFields AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(ht[n]) THEN DELETE OBJECT ht[n].
 CREATE TEMP-TABLE ht[n].
 DO j=1 TO NUM-ENTRIES(cFields):
  c=ENTRY(j,cFields).
  ht[n]:ADD-NEW-FIELD(ENTRY(1,c,":"),ENTRY(2,c,":"),IF NUM-ENTRIES(c,":")=3 THEN INTEGER(ENTRY(3,c,":")) ELSE 0).
 END.
 ht[n]:TEMP-TABLE-PREPARE("fx" + STRING(n)). hb[n]=ht[n]:DEFAULT-BUFFER-HANDLE.
END PROCEDURE.
PROCEDURE Seed:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER lc AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE p AS ObjectModelParser NO-UNDO.
 DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS HANDLE NO-UNDO.
 p=NEW ObjectModelParser(). o=CAST(p:Parse(lc),JsonObject). names=o:GetNames().
 hb[n]:BUFFER-CREATE().
 DO j=1 TO EXTENT(names):
  f=hb[n]:BUFFER-FIELD(names[j]).
  IF f:EXTENT>0 THEN f:BUFFER-VALUE(1)=o:GetDecimal(names[j]).
  ELSE CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN f:BUFFER-VALUE=o:GetCharacter(names[j]).
   WHEN "INTEGER" THEN f:BUFFER-VALUE=o:GetInteger(names[j]).
   WHEN "DECIMAL" THEN f:BUFFER-VALUE=o:GetDecimal(names[j]).
   WHEN "LOGICAL" THEN f:BUFFER-VALUE=o:GetLogical(names[j]).
   WHEN "DATE" THEN f:BUFFER-VALUE=DATE(INTEGER(SUBSTRING(o:GetCharacter(names[j]),6,2)),INTEGER(SUBSTRING(o:GetCharacter(names[j]),9,2)),INTEGER(SUBSTRING(o:GetCharacter(names[j]),1,4))).
  END CASE.
 END.
 DELETE OBJECT o. DELETE OBJECT p.
END PROCEDURE.
PROCEDURE Fixture:
 DEFINE VARIABLE p AS ObjectModelParser NO-UNDO.
 RUN TableDef(1,"nr-container:integer,cod-estabel:character,ordem_busca_dolar_compra:character,ordem_busca_dolar_di:character,cod_tipo_proj_dolar:integer,vl_proj_dolar:decimal,vl-dolar-compra:decimal,vl_dolar_di:decimal,vl-dolar-venda:decimal,log_versao_custo_desatualizada:logical").
 RUN TableDef(2,"item_container_id:integer,container_id:integer,item_proc_compra_id:integer,qt_alocada:decimal,qt_confirm_emb:decimal,qt_recbto_fisico:decimal").
 RUN TableDef(3,"item_proc_compra_id:integer,proc_compra_id:integer,descricao:character,codigo_erp:character,vl_base_tributacao:decimal,vl_custo_dolar:decimal,vl_negociado:decimal").
 RUN TableDef(4,"proc_compra_id:integer,empresa_id:integer").
 RUN TableDef(5,"empresa_id:integer,cod_emp_ems2:integer,cod_emp_ems5:integer").
 RUN TableDef(6,"empresa_despesa_id:integer,empresa_id:integer,despesa_id:integer,log_custo:integer,percentual_custo:decimal").
 RUN TableDef(7,"despesa_id:integer").
 RUN TableDef(8,"despesa_container_id:integer,container_id:integer,item_container_id:integer,despesa_id:integer,vl_prev:decimal,vl_proforma:decimal,vl_negociado:decimal").
 RUN TableDef(9,"cta_corren_custo_distr_id:integer,item_container_id:integer,cod_tipo_movto:integer,vl_lancto:decimal").
 RUN TableDef(10,"desconto_importacao_id:integer,item_container_id:integer,motivo_desconto_id:integer,log_credito:logical,vl_dolar:decimal,vl_real:decimal,vl_cotacao_dolar:decimal").
 RUN TableDef(11,"motivo_desconto_id:integer,log_considerar_custo:logical").
 RUN TableDef(12,"cta_corren_desconto_id:integer,container_id:integer,desconto_importacao_id:integer,valor_utilizado:decimal").
 RUN TableDef(13,"hist_cotacao_bc_id:integer,serie:integer,data:date,valor:decimal,log_ok:logical,log_manual:logical").
 RUN TableDef(14,"item_container_custo_id:integer,versao_id:integer,item_container_id:integer,vl_unit_prev:decimal,vl_unit_realiz:decimal").
 RUN TableDef(15,"versao_id:integer,container_id:integer,ind_sit_versao:integer").
 RUN TableDef(16,"container_id:integer,documento:character,serie:character,estab:character,nat_operacao:character,cod_emitente:integer").
 RUN TableDef(17,"nr-container:integer,nr-pedido:integer,cod-estabel:character").
 RUN TableDef(18,"cod-emitente:integer,nro-docto:character,serie-docto:character,nat-operacao:character,it-codigo:character,sequencia:integer,quantidade:decimal,preco-total:decimal:2,despesas:decimal:2,val-cofins:decimal,val-aliq-cofins:decimal,valor-pis:decimal,val-aliq-pis:decimal").
 RUN TableDef(19,"cod-estabel:character,serie-docto:character,nro-docto:character,nat-operacao:character,cod-emitente:integer").
 RUN TableDef(20,"cod-emitente:integer,nro-docto:character,serie-docto:character,nat-operacao:character,it-codigo:character,sequencia:integer,quantidade:decimal,preco-total:decimal:2,despesas:decimal:2,val-cofins:decimal,val-aliq-cofins:decimal,valor-pis:decimal,val-aliq-pis:decimal").
 RUN TableDef(21,"cod-estabel:character,serie-docto:character,nro-docto:character,nat-operacao:character,cod-emitente:integer").
 RUN TableDef(22,"nr-pedido:integer,cod-estabel:character,nome-abrev:character,nr-pedcli:character,cod-sit-ped:integer,mo-codigo:integer,cod-priori:integer").
 RUN TableDef(23,"nome-abrev:character,nr-pedcli:character,qt-pedida:decimal,vl-preuni:decimal").
 RUN TableDef(24,"nr-pedido:integer,cod-estabel:character,nome-abrev:character,nr-pedcli:character,cod-sit-ped:integer,mo-codigo:integer,cod-priori:integer").
 RUN TableDef(25,"nome-abrev:character,nr-pedcli:character,qt-pedida:decimal,vl-preuni:decimal").
 RUN Seed(1,'~{"nr-container":123,"cod-estabel":"5","ordem_busca_dolar_compra":"2","ordem_busca_dolar_di":"4","cod_tipo_proj_dolar":1,"vl_proj_dolar":0,"vl-dolar-compra":5,"vl_dolar_di":5,"vl-dolar-venda":5,"log_versao_custo_desatualizada":false}').
 RUN Seed(2,'~{"item_container_id":1,"container_id":123,"item_proc_compra_id":1,"qt_alocada":10,"qt_confirm_emb":10,"qt_recbto_fisico":10}').
 RUN Seed(3,'~{"item_proc_compra_id":1,"proc_compra_id":1,"descricao":"Item um","codigo_erp":"ERP1","vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":80}').
 RUN Seed(4,'~{"proc_compra_id":1,"empresa_id":1}').
 RUN Seed(5,'~{"empresa_id":1,"cod_emp_ems2":5,"cod_emp_ems5":10}').
 RUN Seed(6,'~{"empresa_despesa_id":1,"empresa_id":1,"despesa_id":1,"log_custo":1,"percentual_custo":0}').
 RUN Seed(6,'~{"empresa_despesa_id":2,"empresa_id":1,"despesa_id":2,"log_custo":1,"percentual_custo":1}').
 RUN Seed(6,'~{"empresa_despesa_id":3,"empresa_id":1,"despesa_id":3,"log_custo":1,"percentual_custo":2}').
 RUN Seed(7,'~{"despesa_id":1}'). RUN Seed(7,'~{"despesa_id":2}'). RUN Seed(7,'~{"despesa_id":3}').
 RUN Seed(8,'~{"despesa_container_id":1,"container_id":123,"item_container_id":0,"despesa_id":1,"vl_prev":100,"vl_proforma":100,"vl_negociado":100}').
 RUN Seed(8,'~{"despesa_container_id":2,"container_id":123,"item_container_id":1,"despesa_id":1,"vl_prev":30,"vl_proforma":30,"vl_negociado":30}').
 RUN Seed(13,'~{"hist_cotacao_bc_id":1,"serie":1,"data":"2026-10-16","valor":5,"log_ok":true,"log_manual":false}').
 RUN Seed(16,'~{"container_id":123,"documento":"N1","serie":"A","estab":"5","nat_operacao":"3102","cod_emitente":10}').
 RUN Seed(19,'~{"cod-estabel":"5","serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","cod-emitente":10}').
 RUN Seed(18,'~{"cod-emitente":10,"serie-docto":"A","nro-docto":"N1","nat-operacao":"3102","it-codigo":"ERP1","sequencia":1,"quantidade":10,"preco-total":1000,"despesas":100,"val-cofins":40,"val-aliq-cofins":4,"valor-pis":20,"val-aliq-pis":2}').
 p=NEW ObjectModelParser().
 oReq=CAST(p:Parse('~{"operation":"read","resource":"itens","container_id":123,"moeda":"real"}'),JsonObject).
 oFin=CAST(p:Parse('~{"container_id":123,"confirmed":true,"payments":~{"real":1000,"dolar":200},"source":"legacy_linked_title_totals"}'),JsonObject).
 oPolicy=CAST(p:Parse('~{"naturezas_nota_mae":"3102","cod_despesa_pis":2,"cod_despesa_cofins":3}'),JsonObject).
 DELETE OBJECT p.
END PROCEDURE.
