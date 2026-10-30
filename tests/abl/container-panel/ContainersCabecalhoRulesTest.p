/* Test-only real undoable schema-shaped tables. No business DB. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 26 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 26 NO-UNDO.
DEFINE VARIABLE hp AS HANDLE NO-UNDO.
DEFINE VARIABLE requestContext AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE caps AS JsonObject NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE seq AS INTEGER NO-UNDO INITIAL 900.
DEFINE VARIABLE inputCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE failInputs AS LOGICAL NO-UNDO.
FUNCTION CountRows RETURNS INTEGER (hIndex AS INTEGER) FORWARD.

RUN Fixture.
RUN GetCapabilities IN hp(OUTPUT caps).
IF SESSION:PARAMETER="missing-fiscal" THEN DO:
 RUN Check(NOT caps:GetLogical("onUpdate") AND caps:GetLogical("beforeDelete"),"missing compiled fiscal disables update before writes").
 OUTPUT TO "containers-cabecalho-rules-missing-fiscal.log". PUT UNFORMATTED "PASS missing compiled fiscal" SKIP. OUTPUT CLOSE.
 RETURN.
END.
RUN Check(caps:GetLogical("beforeDelete") AND caps:GetLogical("onUpdate"),"concrete callbacks available").
hb[21]:FIND-FIRST("WHERE fx21.nr-container=123",NO-LOCK).
hb[10]:FIND-FIRST("WHERE fx10.despesa_container_id=1",NO-LOCK).
hb[10]:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE=800.
RUN ValidateDistributionExpense IN hp(hb[21],hb[10],OUTPUT caps) NO-ERROR.
RUN Check(NOT ERROR-STATUS:ERROR,"trusted distribution proof callback forwarded through header provider").
RUN Check(caps:GetLogical("confirmed") AND caps:GetInteger("ledger_id")=800,"forward preserves physical distribution proof").
RUN Fixture.
policy:Add("despesa_distr_custo",99).
RUN Seed(5,'~{"despesa_id":99,"ordem":99,"log_imposto":0,"log_calculada":false}').
RUN Seed(10,'~{"despesa_container_id":601,"container_id":123,"despesa_id":99,"item_container_id":1,"vl_prev":20,"cta_corren_custo_distr_id":5001,"log_manual":true}').
RUN Seed(10,'~{"despesa_container_id":602,"container_id":123,"despesa_id":99,"item_container_id":1,"vl_prev":-5,"cta_corren_custo_distr_id":5002,"log_manual":true}').
RUN CrudUpdate.
RUN Check(result:GetLogical("success"),"header forwards private distribution ID and physical validation to central fiscal").
RUN Check(hb[10]:FIND-FIRST("WHERE fx10.despesa_container_id=601",NO-LOCK) AND hb[10]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=20,"header fiscal preserves first managed history").
RUN Check(hb[10]:FIND-FIRST("WHERE fx10.despesa_container_id=602",NO-LOCK) AND hb[10]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE= -5,"header fiscal preserves second managed history").
RUN Fixture.
RUN Seed(11,'~{"nr-container":123,"it-codigo":"COMERCIAL"}').
RUN DeleteAttempt("commercial").
RUN Check(CountRows(2)=1 AND CountRows(10)=2,"commercial dependency blocks before cascade").
RUN Fixture. RUN Seed(18,'~{"container_id":123,"num_id_tit_ap":55}'). RUN DeleteAttempt("payments").
RUN Check(CountRows(2)=1 AND CountRows(10)=2,"linked payments block before child writes").
RUN Fixture. RUN Seed(20,'~{"item_container_custo_id":1,"item_container_id":1,"versao_id":999}'). RUN DeleteAttempt("costs").
RUN Check(CountRows(2)=1 AND CountRows(10)=2,"item cost blocks before child writes").
RUN Fixture. RUN Seed(20,'~{"item_container_custo_id":1,"item_container_id":999,"versao_id":2}'). RUN DeleteAttempt("costs").
RUN Check(CountRows(17)=1,"cost reference by container version also blocks").
RUN Fixture.
RUN DeleteAttempt("rollback").
RUN Check(CountRows(2)=1 AND CountRows(10)=2,"outer rollback restores all deleted children").
RUN DeleteAttempt("ok").
RUN Check(result:GetLogical("success"),"concrete cascade success").
RUN Check(result:GetJsonArray("changes"):Length=9,"one snapshot for each actual deleted child").
RUN Check(CountRows(2)=0 AND CountRows(10)=0 AND CountRows(17)=0,"scoped children deleted").
RUN Check(CountRows(19)=1,"unrelated historical supplier ledger is preserved").
RUN Check(CountRows(21)=1,"provider never deletes master").

RUN Fixture.
requestContext:Set("operation","update").
DO TRANSACTION ON ERROR UNDO, THROW:
 hb[21]:FIND-FIRST("WHERE fx21.nr-container=123",EXCLUSIVE-LOCK).
 RUN OnUpdate IN hp(hb[21],requestContext,OUTPUT result).
 RUN Check(result:GetLogical("success"),"real frozen fiscal service composes both operations").
 RUN Check(inputCalls=1,"quotes collected under master lock once for both fiscal operations").
 RUN Check(NOT result:Has("audit"),"provider emits pending changes only").
 RUN Check(result:GetJsonArray("changes"):Length>0,"fiscal snapshots propagated to parent").
END.
RUN Check(CountRows(9)=2,"fiscal calculation created alongside unrelated existing one").
RUN Check(hb[10]:FIND-FIRST("WHERE fx10.despesa_container_id=1",NO-LOCK),"fiscal expense retained").
RUN Check(hb[10]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=10,"calculated expense runs after fiscal500 and sets final10").
RUN Check(result:GetJsonArray("changes"):Length=2,"same expense changed twice coalesces to single audit event").
RUN Check(result:GetJsonArray("changes"):GetJsonObject(2):GetJsonObject("before"):GetDecimal("vl_prev")=1,"coalesced first before snapshot preserved").
RUN Check(result:GetJsonArray("changes"):GetJsonObject(2):GetJsonObject("after"):GetDecimal("vl_prev")=10,"coalesced final after snapshot preserved").
RUN Fixture. failInputs=TRUE. requestContext:Set("operation","update").
DO TRANSACTION ON ERROR UNDO, THROW:
 hb[21]:FIND-FIRST("WHERE fx21.nr-container=123",EXCLUSIVE-LOCK).
 RUN OnUpdate IN hp(hb[21],requestContext,OUTPUT result) NO-ERROR.
 RUN Check(ERROR-STATUS:ERROR,"missing confirmed quote fails composed update").
 UNDO, LEAVE.
END.
RUN Check(CountRows(9)=1 AND CountRows(10)=2,"quote failure leaves fiscal tables unchanged").
RUN Fixture.
hb[5]:FIND-FIRST("WHERE fx5.despesa_id=10",NO-LOCK). hb[5]:BUFFER-FIELD("perc_calculo"):BUFFER-VALUE=?.
RUN CrudUpdate.
RUN Check(NOT result:GetLogical("success") AND NOT result:Has("audit"),"second fiscal action failure has no confirmed audit").
RUN Check(CountRows(9)=1,"second fiscal failure rolls back earlier calculation insert").
hb[10]:FIND-FIRST("WHERE fx10.despesa_container_id=1",NO-LOCK).
RUN Check(hb[10]:BUFFER-FIELD("vl_prev"):BUFFER-VALUE=1,"second fiscal failure rolls back earlier tax update").
hb[21]:FIND-FIRST("WHERE fx21.nr-container=123",NO-LOCK).
RUN Check(hb[21]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="","real header update also rolls back on second fiscal failure").
RUN Fixture. RUN CrudUpdate.
RUN Check(result:GetLogical("success") AND result:Has("audit"),"real header plus concrete provider commits together").
RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length=2,"confirmed header audit owns coalesced fiscal snapshots").
RUN Fixture.
caps=NEW JsonObject(). caps:Add("operation","delete"). caps:Add("container_id",123).
RUN ContainersCabecalhoCrudService.p(hb[21],hb[22],hb[1],hp,policy,caps,OUTPUT result).
RUN Check(result:GetLogical("success") AND result:Has("audit"),"real header delete owns concrete cascade commit").
RUN Check(CountRows(21)=0 AND CountRows(2)=0 AND CountRows(10)=0,"real header and children removed together").
RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length=9,"confirmed delete audit carries every child snapshot").
RUN VersionSnapshotsDeleteTests.
DO i=1 TO 26: DELETE OBJECT ht[i]. END.
DELETE PROCEDURE hp.
OUTPUT TO VALUE("containers-cabecalho-rules-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
OUTPUT CLOSE.

FUNCTION CountRows RETURNS INTEGER (hIndex AS INTEGER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(hb[hIndex]). q:QUERY-PREPARE("FOR EACH " + hb[hIndex]:NAME + " NO-LOCK"). q:QUERY-OPEN(). q:GET-FIRST().
 DO WHILE NOT q:QUERY-OFF-END: n=n + 1. q:GET-NEXT(). END.
 q:QUERY-CLOSE(). DELETE OBJECT q. RETURN n.
END FUNCTION.
PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 checks=checks + 1. IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + c,1).
END PROCEDURE.
PROCEDURE DeleteAttempt:
 DEFINE INPUT PARAMETER mode AS CHARACTER NO-UNDO.
 DEFINE VARIABLE messageText AS CHARACTER NO-UNDO.
 DO TRANSACTION ON ERROR UNDO, THROW:
  hb[21]:FIND-FIRST("WHERE fx21.nr-container=123",EXCLUSIVE-LOCK).
  RUN BeforeDelete IN hp(hb[21],requestContext,OUTPUT result) NO-ERROR.
  IF mode="commercial" OR mode="payments" OR mode="costs" THEN DO:
   RUN Check(ERROR-STATUS:ERROR,"guard rejects " + mode).
   messageText=ERROR-STATUS:GET-MESSAGE(1).
   RUN Check(INDEX(messageText,ENTRY(LOOKUP(mode,"commercial,payments,costs"),"CONTAINER_COMMERCIAL_DEPENDENCY,CONTAINER_PAYMENTS_LINKED,CONTAINER_COSTS_LINKED"))>0,"specific guard diagnosis " + mode).
   UNDO, LEAVE.
  END.
  IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError(ERROR-STATUS:GET-MESSAGE(1),1).
  IF mode="rollback" THEN UNDO, LEAVE.
 END.
END PROCEDURE.
PROCEDURE CrudUpdate:
 DEFINE VARIABLE req AS JsonObject NO-UNDO.
 DEFINE VARIABLE inputValues AS JsonObject NO-UNDO.
 req=NEW JsonObject(). req:Add("operation","update"). req:Add("container_id",123).
 inputValues=NEW JsonObject(). inputValues:Add("narrativa","provider integrated"). req:Add("values",inputValues).
 RUN ContainersCabecalhoCrudService.p(hb[21],hb[22],hb[1],hp,policy,req,OUTPUT result).
END PROCEDURE.
PROCEDURE SeedVersionSnapshots:
 RUN Seed(17,'~{"versao_id":3,"container_id":123}').
 RUN Seed(17,'~{"versao_id":999,"container_id":124}').
 DO i=1 TO 3:
  RUN Seed(23,'~{"versao_id":' + STRING(IF i=3 THEN 999 ELSE i + 1) + ',"despesa_id":10,"vl_prev":25}').
  RUN Seed(24,'~{"versao_id":' + STRING(IF i=3 THEN 999 ELSE i + 1) + ',"documento":"NF2","serie":"A","estab":"501","nat_operacao":"3102","cod_emitente":7}').
  RUN Seed(25,'~{"versao_id":' + STRING(IF i=3 THEN 999 ELSE i + 1) + ',"num_id_tit_ap":8,"vl_real":15}').
  RUN Seed(26,'~{"versao_id":' + STRING(IF i=3 THEN 999 ELSE i + 1) + ',"desconto_importacao_id":9,"vl_autoriz_real":5}').
 END.
END PROCEDURE.
PROCEDURE VersionSnapshotsDeleteTests:
 DEFINE VARIABLE indexValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE eventIndex AS INTEGER NO-UNDO.
 DEFINE VARIABLE eventValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE arrayValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE parserValue AS ObjectModelParser NO-UNDO.
 DEFINE VARIABLE versionSeen AS LOGICAL NO-UNDO.
 DEFINE VARIABLE auxCount AS INTEGER NO-UNDO.
 RUN Fixture. RUN SeedVersionSnapshots.
 RUN DeleteAttempt("rollback").
 DO indexValue=23 TO 26: RUN Check(CountRows(indexValue)=3,"ancestor rollback restores owned and foreign snapshots " + STRING(indexValue)). END.
 RUN Check(CountRows(17)=3,"ancestor rollback restores both owned versions").
 caps=NEW JsonObject(). caps:Add("operation","delete"). caps:Add("container_id",123).
 RUN ContainersCabecalhoCrudService.p(hb[21],hb[22],hb[1],hp,policy,caps,OUTPUT result).
 RUN Check(result:GetLogical("success") AND result:Has("audit"),"master deletion commits complete reusable version cascade").
 DO indexValue=23 TO 26: RUN Check(CountRows(indexValue)=1,"delete removes all owned snapshots and preserves foreign snapshot " + STRING(indexValue)). END.
 RUN Check(CountRows(17)=1 AND CountRows(21)=0,"delete removes owned versions and master while preserving foreign version").
 RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length=18,"root audit contains every actual deleted auxiliary row").
 parserValue=NEW ObjectModelParser().
 DO eventIndex=1 TO result:GetJsonObject("audit"):GetJsonArray("changes"):Length:
  eventValue=result:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(eventIndex).
  IF eventValue:GetCharacter("resource")="versoes_item_custo_container" THEN versionSeen=TRUE.
  IF LOOKUP(eventValue:GetCharacter("resource"),"item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos")=0 THEN NEXT.
  auxCount=auxCount + 1.
  RUN Check(NOT versionSeen,"auxiliary delete is planned before version delete").
  RUN Check(eventValue:GetCharacter("operation")="delete" AND STRING(eventValue:GetJsonObject("after"):GetJsonText())="~{~}","auxiliary audit is actual delete with empty after").
  RUN Check(eventValue:GetJsonObject("before"):GetInteger("container_id")=123,"auxiliary snapshot bound to locked master").
  arrayValue=CAST(parserValue:Parse(eventValue:GetCharacter("recordId")),JsonArray).
  RUN Check(arrayValue:GetInteger(1)=eventValue:GetJsonObject("before"):GetInteger("versao_id"),"composite key starts with actual owning version").
  RUN Check(arrayValue:Length=(IF eventValue:GetCharacter("resource")="item_container_custo_nfs" THEN 6 ELSE 2),"composite key follows physical primary index").
  IF eventValue:GetCharacter("resource")="item_container_custo_nfs" THEN RUN Check(arrayValue:GetCharacter(2)="NF2" AND arrayValue:GetCharacter(3)="A" AND arrayValue:GetCharacter(4)="501" AND arrayValue:GetCharacter(5)="3102" AND arrayValue:GetInteger(6)=7,"invoice composite key preserves physical component order and types").
  ELSE RUN Check(arrayValue:GetInteger(2)=(IF eventValue:GetCharacter("resource")="item_container_custo_despesas" THEN 10 ELSE IF eventValue:GetCharacter("resource")="item_container_custo_pgtos" THEN 8 ELSE 9),"auxiliary key includes correct physical reference").
 END.
 RUN Check(auxCount=8,"all four auxiliary kinds from two versions audited").
 DELETE OBJECT parserValue.
 /* A legacy 20-buffer consumer cannot silently orphan existing snapshots. */
 RUN Fixture. RUN SeedVersionSnapshots.
 RUN SetVersionDeleteTargets IN hp(?,hb[24],hb[25],hb[26]) NO-ERROR.
 caps=NEW JsonObject(). caps:Add("operation","delete"). caps:Add("container_id",123).
 RUN ContainersCabecalhoCrudService.p(hb[21],hb[22],hb[1],hp,policy,caps,OUTPUT result).
 RUN Check(NOT result:GetLogical("success") AND NOT result:Has("audit"),"missing version target fails closed without confirmed audit").
 RUN Check(CountRows(2)=1 AND CountRows(17)=3 AND CountRows(21)=1,"missing target fails before any deletion").
 DO indexValue=23 TO 26: RUN Check(CountRows(indexValue)=3,"missing target preserves every auxiliary kind " + STRING(indexValue)). END.
 /* No version means the unchanged constructor remains usable without targets. */
 RUN Fixture.
 hb[17]:FIND-FIRST(). hb[17]:BUFFER-DELETE().
 RUN SetVersionDeleteTargets IN hp(?,?,?,?) NO-ERROR.
 caps=NEW JsonObject(). caps:Add("operation","delete"). caps:Add("container_id",123).
 RUN ContainersCabecalhoCrudService.p(hb[21],hb[22],hb[1],hp,policy,caps,OUTPUT result).
 RUN Check(result:GetLogical("success") AND CountRows(21)=0,"no-version delete preserves legacy 20-buffer constructor behavior").
END PROCEDURE.
PROCEDURE TableDef:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER cFieldDefs AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(ht[n]) THEN DELETE OBJECT ht[n].
 CREATE TEMP-TABLE ht[n]. ht[n]:UNDO=TRUE.
 DO j=1 TO NUM-ENTRIES(cFieldDefs): f=ENTRY(j,cFieldDefs). ht[n]:ADD-NEW-FIELD(ENTRY(1,f,":"),ENTRY(2,f,":"),INTEGER(ENTRY(3,f,":"))). END.
 ht[n]:TEMP-TABLE-PREPARE("fx" + STRING(n)). hb[n]=ht[n]:DEFAULT-BUFFER-HANDLE.
END PROCEDURE.
PROCEDURE Seed:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO. DEFINE INPUT PARAMETER lc AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO. DEFINE VARIABLE o AS JsonObject NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE f AS HANDLE NO-UNDO.
 parser=NEW ObjectModelParser(). o=CAST(parser:Parse(lc),JsonObject). names=o:GetNames(). hb[n]:BUFFER-CREATE().
 DO j=1 TO EXTENT(names):
  f=hb[n]:BUFFER-FIELD(names[j]).
  CASE f:DATA-TYPE:
   WHEN "CHARACTER" THEN f:BUFFER-VALUE=o:GetCharacter(names[j]).
   WHEN "INTEGER" THEN f:BUFFER-VALUE=o:GetInteger(names[j]).
   WHEN "DECIMAL" THEN f:BUFFER-VALUE=o:GetDecimal(names[j]).
   WHEN "LOGICAL" THEN f:BUFFER-VALUE=o:GetLogical(names[j]).
  END CASE.
 END.
 DELETE OBJECT parser. DELETE OBJECT o.
END PROCEDURE.
PROCEDURE CollectCalculationInputs:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE VARIABLE snap AS JsonObject NO-UNDO. DEFINE VARIABLE f AS CHARACTER NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE d AS DECIMAL NO-UNDO. DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 IF NOT TRANSACTION OR NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("quote collection outside parent lock",1).
 inputCalls=inputCalls + 1. IF failInputs THEN UNDO, THROW NEW Progress.Lang.AppError("confirmed quote unavailable",1).
 snap=NEW JsonObject().
 DO j=1 TO 6:
  f=ENTRY(j,"vl-dolar-compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar").
  IF master:BUFFER-FIELD(f):DATA-TYPE="CHARACTER" THEN DO: c=master:BUFFER-FIELD(f):BUFFER-VALUE. snap:Add(f,c). END.
  ELSE DO: d=master:BUFFER-FIELD(f):BUFFER-VALUE. snap:Add(f,d). END.
 END.
 o=NEW JsonObject(). o:Add("confirmed",TRUE). o:Add("source","container-cost-collector"). o:Add("container_id",123).
 o:Add("dolar_di",5). o:Add("dolar_compra",5). o:Add("container_snapshot",snap).
END PROCEDURE.
PROCEDURE NextCalculoId:
 DEFINE OUTPUT PARAMETER n AS INTEGER NO-UNDO. seq=seq + 1. n=seq.
END PROCEDURE.
PROCEDURE NextDespesaId:
 DEFINE OUTPUT PARAMETER n AS INTEGER NO-UNDO. seq=seq + 1. n=seq.
END PROCEDURE.
PROCEDURE LogRule:
 DEFINE INPUT PARAMETER levelName AS CHARACTER NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 /* Tests don't persist logs. Production runtime queues through ApiExecutionRepository. */
END PROCEDURE.
PROCEDURE ValidateDistributionExpense:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER expense AS HANDLE NO-UNDO. DEFINE OUTPUT PARAMETER proof AS JsonObject NO-UNDO.
 proof=NEW JsonObject(). proof:Add("confirmed",TRUE). proof:Add("container_id",INTEGER(master:BUFFER-FIELD("nr-container"):BUFFER-VALUE)).
 proof:Add("despesa_container_id",INTEGER(expense:BUFFER-FIELD("despesa_container_id"):BUFFER-VALUE)). proof:Add("ledger_id",INTEGER(expense:BUFFER-FIELD("cta_corren_custo_distr_id"):BUFFER-VALUE)).
END PROCEDURE.
PROCEDURE Fixture:
 IF VALID-HANDLE(hp) THEN DELETE PROCEDURE hp.
 /* Schema-derived declarations inserted below; no schema files needed at runtime. */
 RUN TableDef(1,"empresa_id:integer:0,nome:character:0,cod_emp_ems2:integer:0,cod_emp_ems5:integer:0").
 RUN TableDef(2,"item_container_id:integer:0,container_id:integer:0,item_proc_compra_id:integer:0,qt_alocada:decimal:0,qt_confirm_emb:decimal:0,qt_recbto_fisico:decimal:0,log_rec_doc_prazo_emb:logical:0,observacao:character:0,cod_tipo_calculo:integer:0,perc_custo:decimal:0,log_calc_icms:logical:0,log_calc_ipi:logical:0,perc_icms:decimal:0,perc_ipi:decimal:0,preco_liquida_ima:decimal:0").
 RUN TableDef(3,"item_proc_compra_id:integer:0,descricao:character:0,codigo_erp:character:0,qt_dias_producao:integer:0,vl_base_tributacao:decimal:0,unid_medida:character:0,proc_compra_id:integer:0,qt_comprada:decimal:0,vl_custo_dolar:decimal:0,composicao:character:0,peso:character:0,largura:character:0,rolo:character:0,dt_prev_envio_desenhos:date:0,dt_real_envio_desenhos:date:0,log_aprov_so_ld:logical:0,dt_prev_recbto_so_ld:date:0,dt_prev_aprov_so_ld:date:0,dt_real_aprov_so_ld:date:0,coloracao_id:integer:0,dt_maxima_producao:date:0,dt_mostruario:date:0,log_mostruario:logical:0,formato_amostra_id:integer:0,ind_producao_no_prazo:integer:0,ind_relat_semanal_producao:integer:0,ind_qualid_emb:integer:0,ind_laudo_antes_embarque:integer:0,ind_prod_conf_pi:integer:0,ind_rec_amostra_antes_emb:integer:0,ind_qt_conf_proforma:integer:0,ind_tamanho_pecas_correto:integer:0,observacao:character:0,dt_cheg_amostras_emb:date:0,dt_termino_producao:date:0,vl_cubagem:decimal:0,dt_recbto_laudo:date:0,dt_recbto_embalagem:date:0,dt_real_recbto_so_ld:date:0,dt_prev_termino_producao:date:0,qt_dias_calc_so_ld:integer:0,shrinkage:character:0,ind_distr_custo:integer:0,vl_negociado:decimal:0,item_estacao:integer:0,dt_item_certificacao:date:0").
 RUN TableDef(4,"proc_compra_id:integer:0,empresa_id:integer:0,qt_container:integer:0,cod_situacao:integer:0,cod_proc_fornec:character:0,qt_dias_translado:integer:0,cotacao_prevista:decimal:0,observacao:character:0,dt_registro:date:0,fornecedor_id:integer:0,dt_limite:date:0,log_facilid_contato_fornec:logical:0,log_considerar_previsao:logical:0,nr_container_original:character:0").
 RUN TableDef(5,"despesa_id:integer:0,descricao:character:0,log_imposto:integer:0,ordem:integer:0,log_calculada:logical:0,perc_calculo:decimal:0,log_vl_prod_base_calculo:logical:0,log_calc_por_item:logical:0,ind_imposto:integer:0").
 RUN TableDef(6,"empresa_despesa_id:integer:0,despesa_id:integer:0,empresa_id:integer:0,codigo_desp_erp:integer:0,vl_padrao:decimal:0,percentual:decimal:0,cod_nat_operacao:character:0,log_ativo:integer:0,perc_custo:integer:0,percentual_custo:decimal:0,despesa_custo_id:integer:0,log_custo:integer:0").
 RUN TableDef(7,"despesa_id:integer:0,imposto_id:integer:0,empresa_id:integer:0").
 RUN TableDef(8,"relac_desp_calculada_id:integer:0,despesa_id:integer:0,despesa_id_base:integer:0").
 RUN TableDef(9,"container_id:integer:0,dt_hr_calculo:datetime:0,usuario_id:integer:0,memoria_calculo:integer:0,calc_imp_container_id:integer:0,desc_memoria_calc:character:0").
 RUN TableDef(10,"despesa_container_id:integer:0,despesa_id:integer:0,vl_prev:decimal:0,container_id:integer:0,calc_imp_container_id:integer:0,vl_base_imp:decimal:0,vl_negociado:decimal:0,vl_proforma:decimal:0,cta_corren_custo_distr_id:integer:0,log_utilizado:logical:0,log_manual:logical:0,perc_calc:decimal:0,memoria_calculo:character:0,item_container_id:integer:0").
 RUN TableDef(11,"nr-container:integer:0,it-comprado:character:0,desc-item:character:0,ref-comprada:character:0,qt-pedida:decimal:0,qt-vendida:decimal:0,qt-recebida:decimal:0,preco-compra:decimal:0,it-codigo:character:0,cod-refer:character:0,char-1:character:0,dec-1:decimal:0,int-1:integer:0,log-1:logical:0,data-1:date:0,preco-venda:decimal:0,narrativa:character:0,class-fiscal:character:0,perc-dsp-venda:decimal:0,mo-codigo:integer:0,preco-vd-real:decimal:0,preco-vd-dolar:decimal:0,qt_faturada:decimal:0,vl_preco_medio:decimal:0,qt_prazo_medio:integer:0,dt_hr_atu_fat:datetime:0,transacao_id_qt_fat:int64:0,qt_devolvida:decimal:0,preco_medio_atu:decimal:0,preco_medio_meta:decimal:0,item_proc_compra_id:integer:0,cod_estab_definido:character:0").
 RUN TableDef(12,"nr_container:integer:0,cod_repres:integer:0,regiao_repres:character:0,tipo_repres:integer:0").
 RUN TableDef(13,"nr_container:integer:0,cod_repres:integer:0,regiao_repres:character:0,tipo_repres:integer:0,perc_saldo:decimal:0").
 RUN TableDef(14,"documento:character:0,serie:character:0,estab:character:0,nat_operacao:character:0,cod_emitente:integer:0,container_id:integer:0").
 RUN TableDef(15,"cta_corren_desconto_id:integer:0,desconto_importacao_id:integer:0,container_id:integer:0,valor_utilizado:decimal:0,data:date:0,cod_usuario:date:0").
 RUN TableDef(16,"anexo_container_id:integer:0,container_id:integer:0,item_container_id:integer:0,descricao:character:0,tipos_anexo_id:integer:0,caminho_arquivo:character:0,dt_hr_arquivo:datetime:0").
 RUN TableDef(17,"versao_id:integer:0,dt_hr_versao:datetime-tz:0,cod_usuario:character:0,descricao:character:0,ind_sit_versao:integer:0,vl_dolar_compra:decimal:0,vl_desconto_utiliz_dolar:decimal:0,vl_desconto_utiliz_real:decimal:0,tipo_versao_id:integer:0,container_id:integer:0,vl_dolar_medio:decimal:0,vl_dolar_di:decimal:0,usuario_id:integer:0,log_gerar_saldo_a_pagar:logical:0,log_gerar_distr_custo:logical:0,situacao_container_id:integer:0,desc_sit_container:character:0,cod_tipo_cotacao:integer:0,vl_cotacao:decimal:0,data_ref_cotacao:date:0,perc_fixo_container:decimal:0,hist_dolar:character:0").
 RUN TableDef(18,"num_id_tit_ap:integer:0,container_id:integer:0,vl_pago_em_dolar:decimal:0,vl_pago_em_real:decimal:0,vl_aprop_em_dolar:decimal:0,vl_cotacao_dolar:decimal:0,dt_pagto:date:0").
 RUN TableDef(19,"cta_corren_fornec_imp_id:integer:0,fornecedor_id:integer:0,data:date:0,historico:character:0,cod_tipo_movto:integer:0,vl_lancto:decimal:0,cod_acao:integer:0,login:character:0,data_hora:datetime:0,num_id_tit_ap:integer:0,item_proc_compra_id:integer:0,item_container_id:integer:0,transacao_id:integer:0").
 RUN TableDef(20,"item_container_custo_id:integer:0,vl_custo_prev_dolar:decimal:0,qt_embarcada:decimal:0,it_codigo:character:0,item_custo_id:integer:0,versao_id:integer:0,memoria_calculo:character:0,vl_custo_prev_real:decimal:0,vl_desp_prev_dolar:decimal:0,vl_desp_prev_real:decimal:0,vl_pago_dolar:decimal:0,vl_pago_real:decimal:0,qt_alocada:decimal:0,qt_confirm_emb:decimal:0,qt_recebto_fisico:decimal:0,vl_desp_realiz_real:decimal:0,vl_desp_realiz_dolar:decimal:0,vl_desconto_utiliz_dolar:decimal:0,vl_desconto_utiliz_real:character:0,vl_unit_prev:decimal:0,vl_unit_realiz:decimal:0,item_container_id:integer:0,vl_unit_prev_dolar:decimal:0,vl_unit_realiz_dolar:decimal:0,vl_desp_prev_perc_fixo:decimal:0,vl_custo_distribuido:decimal:0,vl_negociado:decimal:0,vl_saldo_a_pagar:decimal:0,vl_desp_prev_real_sem_distr_cust:decimal:0,vl_desp_prev_dolar_sem_distr_cus:decimal:0,vl_distr_custo:decimal:0").
 RUN TableDef(21,"cod-estabel:character:0,nr-container:integer:0,num-pedido:integer:0,nome-ab-forn:character:0,cod-emit-forn:integer:0,comprador:character:0,narrativa:character:0,usuario:character:0,dt-compra:date:0,dt-prev-chegada:date:0,dt-recebimento:date:0,situacao:integer:0,char-1:character:0,dec-1:decimal:0,int-1:integer:0,log-1:logical:0,data-1:date:0,vlr-frete:decimal:0,vlr-seguro:decimal:0,vlr-despesas:decimal:0,exclusivo:logical:0,vl-dolar-venda:decimal:0,vl-dolar-compra:decimal:0,log_liberar_custo_realizado:logical:0,medidas_container:character:0,dt_prev_embarque:date:0,dt_real_embarque:date:0,ind_dt_embarque:integer:0,situacao_container_id:integer:0,ind_dt_prev_chegada:integer:0,log_pagto_final:logical:0,cod_agente_cargas:integer:0,cod_armador:integer:0,cod_tipo_calculo:integer:0,perc_custo:decimal:0,vl_dolar_di:decimal:0,log_gerar_saldo_a_pagar:logical:0,log_gerar_distr_custo:logical:0,ordem_busca_dolar_compra:character:0,ordem_busca_dolar_di:character:0,cod_tipo_proj_dolar:integer:0,vl_proj_dolar:decimal:0,log_versao_custo_desatualizada:logical:0,dt_hr_ult_alt_versao_custo:datetime:0,ptax:decimal:0,cod-depos:character:0,dt_prev_chegada_loja:date:0,estacao:integer:0,num_origem:integer:0,log_rota_indefinida:logical:0").

 RUN TableDef(23,"versao_id:integer:0,despesa_id:integer:0,vl_prev:decimal:0,calc_imp_container_id:integer:0,log_custo:integer:0,vl_negociado:decimal:0,vl_proforma:decimal:0,vl_base_imp:decimal:0").
 RUN TableDef(24,"item_container_custo_id:integer:0,versao_id:integer:0,documento:character:0,serie:character:0,estab:character:0,nat_operacao:character:0,cod_emitente:integer:0,vl_mercadoria:decimal:0,vl_despesa:decimal:0").
 RUN TableDef(25,"versao_id:integer:0,num_id_tit_ap:integer:0,vl_real:decimal:0,vl_dolar:decimal:0").
 RUN TableDef(26,"versao_id:integer:0,desconto_importacao_id:integer:0,vl_autoriz_dolar:decimal:0,vl_autoriz_real:decimal:0,log_custo:integer:0").
 policy=NEW JsonObject(). policy:Add("usuario_id",7). caps=NEW JsonObject(). caps:Add("login","test-actor"). policy:Add("actor",caps).
 requestContext=NEW JsonObject(). requestContext:Add("operation","delete"). requestContext:Add("container_id",123). requestContext:Add("actor",caps). requestContext:Add("before",NEW JsonObject()).
 RUN Seed(21,'~{"nr-container":123,"cod-estabel":"501","cod-emit-forn":10,"vl-dolar-compra":5,"vl_dolar_di":5,"ordem_busca_dolar_compra":"2","ordem_busca_dolar_di":"4","cod_tipo_proj_dolar":1,"vl_proj_dolar":0}').
 RUN TableDef(22,"cdn_fornecedor:integer:0,nom_abrev:character:0,cod_empresa:character:0").
 RUN Seed(22,'~{"cdn_fornecedor":10,"nom_abrev":"Fornecedor ERP","cod_empresa":"50"}').
 RUN Seed(1,'~{"empresa_id":1,"cod_emp_ems2":5,"cod_emp_ems5":50}').
 RUN Seed(2,'~{"item_container_id":1,"container_id":123,"item_proc_compra_id":11,"qt_alocada":10,"qt_confirm_emb":10,"log_calc_ipi":false}').
 RUN Seed(3,'~{"item_proc_compra_id":11,"proc_compra_id":21,"vl_base_tributacao":100,"vl_custo_dolar":90,"vl_negociado":80}').
 RUN Seed(4,'~{"proc_compra_id":21,"fornecedor_id":10}').
 RUN Seed(5,'~{"despesa_id":10,"ordem":1,"log_imposto":1,"log_calc_por_item":false,"log_calculada":true,"perc_calculo":10}').
 RUN Seed(6,'~{"empresa_despesa_id":1,"empresa_id":1,"despesa_id":10,"percentual":10,"despesa_custo_id":0,"percentual_custo":0}').
 RUN Seed(9,'~{"calc_imp_container_id":9999,"container_id":999}').
 RUN Seed(10,'~{"despesa_container_id":1,"container_id":123,"despesa_id":10,"item_container_id":0,"vl_prev":1,"vl_proforma":1,"vl_negociado":1,"log_manual":false,"vl_base_imp":0}').
 RUN Seed(10,'~{"despesa_container_id":2,"container_id":123,"despesa_id":1,"item_container_id":0,"vl_prev":100,"vl_proforma":100,"vl_negociado":100,"log_manual":false,"vl_base_imp":0}').
 RUN Seed(8,'~{"despesa_id":10,"despesa_id_base":1}').
 RUN Seed(12,'~{"nr_container":123,"cod_repres":1,"regiao_repres":"A","tipo_repres":1}').
 RUN Seed(13,'~{"nr_container":123,"cod_repres":1,"regiao_repres":"A","tipo_repres":1}').
 RUN Seed(14,'~{"container_id":123,"documento":"NF","serie":"A","estab":"501","nat_operacao":"3102","cod_emitente":10}').
 RUN Seed(15,'~{"cta_corren_desconto_id":1,"container_id":123}').
 RUN Seed(16,'~{"anexo_container_id":1,"container_id":123,"caminho_arquivo":"preserve-file.pdf"}').
 RUN Seed(17,'~{"versao_id":2,"container_id":123}').
 RUN Seed(19,'~{"cta_corren_fornec_imp_id":1,"item_container_id":1,"num_id_tit_ap":55,"cod_tipo_movto":5,"vl_lancto":-100}').
 inputCalls=0. failInputs=FALSE.
 RUN ContainersCabecalhoRules.p PERSISTENT SET hp(hb[1],hb[2],hb[3],hb[4],hb[5],hb[6],hb[7],hb[8],hb[9],hb[10],hb[11],hb[12],hb[13],hb[14],hb[15],hb[16],hb[17],hb[18],hb[19],hb[20],THIS-PROCEDURE,policy).
 IF LOOKUP("SetVersionDeleteTargets",hp:INTERNAL-ENTRIES)>0 THEN RUN SetVersionDeleteTargets IN hp(hb[23],hb[24],hb[25],hb[26]).
END PROCEDURE.
