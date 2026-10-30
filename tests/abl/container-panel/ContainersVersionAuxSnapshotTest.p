/* TT-only physical snapshot profile. Never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE t AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 11 NO-UNDO.
DEFINE VARIABLE aux AS HANDLE NO-UNDO.
DEFINE VARIABLE physicalValue AS JsonObject NO-UNDO.
DEFINE VARIABLE costValue AS JsonObject NO-UNDO.
DEFINE VARIABLE financialValue AS JsonObject NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE failedValue AS LOGICAL NO-UNDO.
RUN Fixture.
RUN Collect.
RUN Check(physicalValue:GetJsonArray("expenses"):Length=1,"expense grouped once per physical PK").
RUN Check(physicalValue:GetJsonArray("expenses"):GetJsonObject(1):GetDecimal("vl_prev")=11,"same calculation expense values summed centrally").
RUN Check(physicalValue:GetJsonArray("discounts"):Length=2,"regular and credit snapshots in own container only").
RUN Check(physicalValue:GetJsonArray("discounts"):GetJsonObject(2):GetDecimal("vl_autoriz_real")=25 AND physicalValue:GetJsonArray("discounts"):GetJsonObject(2):GetDecimal("vl_autoriz_dolar")=5,"credit snapshot uses authorized ratio, not cost quotation9").
RUN Check(physicalValue:GetJsonArray("payments"):GetJsonObject(1):GetDecimal("vl_real")=99.12345,"payment snapshot reuses captured helper value").
RUN Check(physicalValue:GetJsonArray("nfs"):Length=1 AND physicalValue:GetJsonArray("nfs"):GetJsonObject(1):GetCharacter("estab")="5","NF includes establishment physical identity").
RUN Check(physicalValue:GetJsonArray("nfs"):GetJsonObject(1):GetDecimal("vl_mercadoria")=100,"NF exact ERP header values reused").
RUN Check(physicalValue:GetJsonObject("header"):GetCharacter("desc_sit_container")="Teste(Marcado para Não Distribuir Custo)","status snapshot retains legacy explanation").
RUN Finalize.
RUN Check(resultValue:GetLogical("confirmed") AND NOT resultValue:GetLogical("actual_complete"),"confirmed independent of realized completeness").
RUN Check(resultValue:GetJsonObject("header"):GetDecimal("vl_dolar_compra")=5,"purchase rate extracted from central master memory").
RUN Check(resultValue:GetJsonObject("header"):GetDecimal("vl_desconto_utiliz_real")=45,"header cost credit quotation profile differs intentionally from child ratio25").
RUN Check(resultValue:GetJsonObject("header"):GetDecimal("perc_fixo_container")=7,"physical fixed percentage copied, not recalculated").
RUN Check(resultValue:GetJsonObject("header"):IsNull("cod_tipo_cotacao"),"unused legacy type has explicit unknown provenance").

RUN Seed(6,'~{"desconto_importacao_id":30,"log_credito":true,"vl_real_autorizado":50,"vl_dolar_autorizado":0,"vl_cotacao_dolar":9}').
RUN CollectExpectError. RUN Check(failedValue,"credit zero denominator fails without numeric fallback").
RUN Seed(6,'~{"desconto_importacao_id":30,"log_credito":true,"vl_real_autorizado":50,"vl_dolar_autorizado":10,"vl_cotacao_dolar":9}').
h[6]:FIND-FIRST("WHERE " + h[6]:NAME + ".desconto_importacao_id=30") NO-ERROR. h[6]:BUFFER-FIELD("vl_real_autorizado"):BUFFER-VALUE=?.
RUN CollectExpectError. RUN Check(failedValue,"credit unknown authorized amount fails explicitly").
RUN Fixture. financialValue:Set("container_id",999). RUN CollectExpectError. RUN Check(failedValue,"financial context mismatch rejected").
RUN Fixture. costValue:Set("container_id",999). RUN Collect. RUN FinalizeExpectError. RUN Check(failedValue,"cost context mismatch rejected").
RUN Fixture.
RUN Seed(5,'~{"despesa_container_id":3,"container_id":123,"despesa_id":1,"vl_prev":2,"vl_negociado":2,"vl_proforma":2,"vl_base_imp":2,"calc_imp_container_id":99}').
RUN CollectExpectError. RUN Check(failedValue,"two calculation IDs cannot silently collide with version expense PK").
RUN Fixture.
h[9]:FIND-FIRST() NO-ERROR. h[9]:BUFFER-DELETE().
RUN Collect. RUN Finalize.
RUN Check(resultValue:GetJsonArray("nfs"):GetJsonObject(1):IsNull("vl_mercadoria"),"missing ERP header remains unknown, not zero").
RUN Check(resultValue:GetJsonObject("cost"):GetJsonObject("calculation"):GetJsonArray("warnings"):Length>0,"missing ERP header carries source warning").
RUN Fixture.
RUN Seed(9,'~{"cod-estabel":"5","nro-docto":"NF1","serie-docto":"A","nat-operacao":"301","cod-emitente":10,"valor-mercad":200,"despesa-nota":30}').
RUN CollectExpectError. RUN Check(failedValue,"ambiguous ERP document fails instead of FIRST row").
RUN Fixture. h[1]:FIND-FIRST() NO-ERROR. h[1]:BUFFER-FIELD("cod-estabel"):BUFFER-VALUE="501".
RUN Collect. RUN Check(physicalValue:GetJsonArray("expenses"):Length=1,"company uses first establishment character, not full code").
OUTPUT TO VALUE("containers-version-aux-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks; TT only." SKIP. OUTPUT CLOSE.

PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + labelValue,1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE Collect:
 DO TRANSACTION:
  h[1]:FIND-FIRST("WHERE " + h[1]:NAME + ".nr-container=123",EXCLUSIVE-LOCK) NO-ERROR.
  RUN CollectPhysical IN aux(h[1],financialValue,OUTPUT physicalValue).
 END.
END PROCEDURE.
PROCEDURE CollectExpectError:
 failedValue=FALSE.
 RUN Collect NO-ERROR. failedValue=ERROR-STATUS:ERROR.
END PROCEDURE.
PROCEDURE Finalize:
 DO TRANSACTION:
  h[1]:FIND-FIRST("WHERE " + h[1]:NAME + ".nr-container=123",EXCLUSIVE-LOCK) NO-ERROR.
  RUN FinalizeSnapshot IN aux(h[1],physicalValue,costValue,OUTPUT resultValue).
 END.
END PROCEDURE.
PROCEDURE FinalizeExpectError:
 failedValue=FALSE.
 RUN Finalize NO-ERROR. failedValue=ERROR-STATUS:ERROR.
END PROCEDURE.
PROCEDURE Parse:
 DEFINE INPUT PARAMETER json AS LONGCHAR NO-UNDO.
 DEFINE OUTPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
 parser=NEW ObjectModelParser(). objectValue=CAST(parser:Parse(json),JsonObject). DELETE OBJECT parser.
END PROCEDURE.
PROCEDURE TableDef:
 DEFINE INPUT PARAMETER rowNo AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER fieldsValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE definitionValue AS CHARACTER NO-UNDO.
 CREATE TEMP-TABLE t[rowNo].
 DO j=1 TO NUM-ENTRIES(fieldsValue): definitionValue=ENTRY(j,fieldsValue). t[rowNo]:ADD-NEW-FIELD(ENTRY(1,definitionValue,":"),ENTRY(2,definitionValue,":")). END.
 t[rowNo]:TEMP-TABLE-PREPARE("fxAux" + STRING(rowNo)). h[rowNo]=t[rowNo]:DEFAULT-BUFFER-HANDLE.
END PROCEDURE.
PROCEDURE Seed:
 DEFINE INPUT PARAMETER rowNo AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER json AS LONGCHAR NO-UNDO.
 DEFINE VARIABLE objectValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldsValue AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 RUN Parse(json,OUTPUT objectValue). fieldsValue=objectValue:GetNames().
 IF rowNo=6 THEN h[rowNo]:FIND-FIRST("WHERE " + h[rowNo]:NAME + ".desconto_importacao_id=" + STRING(objectValue:GetInteger("desconto_importacao_id"))) NO-ERROR.
 ELSE h[rowNo]:BUFFER-RELEASE().
 IF NOT h[rowNo]:AVAILABLE THEN h[rowNo]:BUFFER-CREATE().
 DO j=1 TO EXTENT(fieldsValue):
  CASE objectValue:GetType(fieldsValue[j]):
   WHEN JsonDataType:STRING THEN h[rowNo]:BUFFER-FIELD(fieldsValue[j]):BUFFER-VALUE=objectValue:GetCharacter(fieldsValue[j]).
   WHEN JsonDataType:NUMBER THEN h[rowNo]:BUFFER-FIELD(fieldsValue[j]):BUFFER-VALUE=objectValue:GetDecimal(fieldsValue[j]).
   WHEN JsonDataType:BOOLEAN THEN h[rowNo]:BUFFER-FIELD(fieldsValue[j]):BUFFER-VALUE=objectValue:GetLogical(fieldsValue[j]).
  END CASE.
 END.
 h[rowNo]:BUFFER-RELEASE().
END PROCEDURE.
PROCEDURE Fixture:
 IF VALID-HANDLE(aux) THEN DELETE PROCEDURE aux.
 DO n=1 TO 11: IF VALID-HANDLE(t[n]) THEN DELETE OBJECT t[n]. END.
 RUN TableDef(1,"nr-container:integer,cod-estabel:character,vl_dolar_di:decimal,log_gerar_saldo_a_pagar:logical,log_gerar_distr_custo:logical,situacao_container_id:integer,perc_custo:decimal").
 RUN TableDef(2,"item_container_id:integer,container_id:integer").
 RUN TableDef(3,"empresa_id:integer,cod_emp_ems2:integer").
 RUN TableDef(4,"despesa_id:integer,empresa_id:integer,log_custo:integer").
 RUN TableDef(5,"despesa_container_id:integer,container_id:integer,despesa_id:integer,vl_prev:decimal,vl_negociado:decimal,vl_proforma:decimal,vl_base_imp:decimal,calc_imp_container_id:integer").
 RUN TableDef(6,"desconto_importacao_id:integer,item_container_id:integer,log_credito:logical,vl_real_autorizado:decimal,vl_dolar_autorizado:decimal,vl_cotacao_dolar:decimal").
 RUN TableDef(7,"container_id:integer,desconto_importacao_id:integer,valor_utilizado:decimal").
 RUN TableDef(8,"container_id:integer,documento:character,serie:character,estab:character,nat_operacao:character,cod_emitente:integer").
 RUN TableDef(9,"cod-estabel:character,nro-docto:character,serie-docto:character,nat-operacao:character,cod-emitente:integer,valor-mercad:decimal,despesa-nota:decimal").
 RUN TableDef(10,"cod-estabel:character,nro-docto:character,serie-docto:character,nat-operacao:character,cod-emitente:integer,valor-mercad:decimal,despesa-nota:decimal").
 RUN TableDef(11,"situacao_container_id:integer,descricao:character,log_gerar_distr_custo:logical").
 RUN Seed(1,'~{"nr-container":123,"cod-estabel":"5","vl_dolar_di":5,"log_gerar_saldo_a_pagar":false,"log_gerar_distr_custo":false,"situacao_container_id":1,"perc_custo":7}').
 RUN Seed(2,'~{"item_container_id":11,"container_id":123}'). RUN Seed(2,'~{"item_container_id":22,"container_id":999}').
 RUN Seed(3,'~{"empresa_id":1,"cod_emp_ems2":5}'). RUN Seed(4,'~{"despesa_id":1,"empresa_id":1,"log_custo":1}').
 RUN Seed(5,'~{"despesa_container_id":1,"container_id":123,"despesa_id":1,"vl_prev":10,"vl_negociado":20,"vl_proforma":30,"vl_base_imp":40,"calc_imp_container_id":8}').
 RUN Seed(5,'~{"despesa_container_id":2,"container_id":123,"despesa_id":1,"vl_prev":1,"vl_negociado":2,"vl_proforma":3,"vl_base_imp":4,"calc_imp_container_id":8}').
 RUN Seed(6,'~{"desconto_importacao_id":20,"item_container_id":11,"log_credito":false,"vl_real_autorizado":8,"vl_dolar_autorizado":2,"vl_cotacao_dolar":9}').
 RUN Seed(6,'~{"desconto_importacao_id":21,"item_container_id":22,"log_credito":false,"vl_real_autorizado":800,"vl_dolar_autorizado":200,"vl_cotacao_dolar":9}').
 RUN Seed(6,'~{"desconto_importacao_id":30,"log_credito":true,"vl_real_autorizado":50,"vl_dolar_autorizado":10,"vl_cotacao_dolar":9}').
 RUN Seed(7,'~{"container_id":123,"desconto_importacao_id":30,"valor_utilizado":3}'). RUN Seed(7,'~{"container_id":123,"desconto_importacao_id":30,"valor_utilizado":2}').
 RUN Seed(7,'~{"container_id":999,"desconto_importacao_id":30,"valor_utilizado":100}').
 RUN Seed(8,'~{"container_id":123,"documento":"NF1","serie":"A","estab":"5","nat_operacao":"301","cod_emitente":10}').
 RUN Seed(9,'~{"cod-estabel":"5","nro-docto":"NF1","serie-docto":"A","nat-operacao":"301","cod-emitente":10,"valor-mercad":100,"despesa-nota":20}').
 RUN Seed(11,'~{"situacao_container_id":1,"descricao":"Teste","log_gerar_distr_custo":false}').
 RUN Parse('~{"confirmed":true,"source":"linked-payment-totals","container_id":123,"payments":~{"real":99.12345,"dolar":20},"payment_rows":[~{"num_id_tit_ap":7,"vl_real":99.12345,"vl_dolar":20}]}',OUTPUT financialValue).
 RUN Parse('~{"confirmed":true,"source":"container-version-cost-snapshot","container_id":123,"actual_complete":false,"input_snapshot":~{"discounts":~{"credito_real":45,"credito_dolar":5},"quotation":~{"valor":5,"data":"2026-10-16"}},"master_average":~{"memory":~{"compra_attempts":[~{"priority":2,"value":5}]}},"calculation":~{"warnings":[]}}',OUTPUT costValue).
 RUN ContainersVersionAuxSnapshotService.p PERSISTENT SET aux(h[2],h[3],h[4],h[5],h[6],h[7],h[8],h[9],h[10],h[11]).
END PROCEDURE.



