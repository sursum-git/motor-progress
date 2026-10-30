BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE hTables AS HANDLE EXTENT 20 NO-UNDO.
DEFINE VARIABLE hSources AS HANDLE EXTENT 20 NO-UNDO.
DEFINE VARIABLE cTables AS CHARACTER NO-UNDO INITIAL "espec.user-web,espec.usuarios_grupos,ems2cad.repres,espec.cm-hierarquia,espec.cm-ext-repres,espec.fats_repres,espec.transacoes,espec.metas_repres,espec.metas_gerencial,espec.metas_geral,espec.peds_web,ems2med.ped-venda,ems2med.ped-repre,ems2med.nota-fiscal,ems2med.natur-oper,ems2med.devol-cli,ems2med.docum-est,ems5.dia_calend_glob,espec.restrs_clientes_usuario,espec.repres_restr_cliente_usuario".
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE dtDay AS DATE NO-UNDO.
DEFINE VARIABLE scopeData AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DO i=1 TO 20:
 CREATE TEMP-TABLE hTables[i].
 hTables[i]:CREATE-LIKE(ENTRY(i,cTables)).
 hTables[i]:TEMP-TABLE-PREPARE("ttIol" + STRING(i)).
 hSources[i]=hTables[i]:DEFAULT-BUFFER-HANDLE.
END.
RUN IolGerencialIdentityService.p("missing",hSources,OUTPUT scopeData) NO-ERROR.
IF NOT ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL unknown identity",1).
RUN NewRow(1,"Login,ativo,tp-usuario","vendedor,yes,2").
RUN NewRow(2,"login_usuario,cod_grupo","vendedor,2").
RUN NewRow(3,"cod-rep,nome-abrev","7,vendedor").
RUN IolGerencialIdentityService.p("vendedor",hSources,OUTPUT scopeData).
IF scopeData:GetInteger("representative")<>7 OR scopeData:GetLogical("general") THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL seller own scope",1).
scopeData:Add("calendar_code","fiscal").
RUN NewRow(6,"cod_rep,mes,ano,vl_faturamento,vl_devolucoes,transacao_id,cod_estabel","7,10,2026,1000,150,1,5").
RUN NewRow(7,"transacao_id,ind_sit_transacao","1,1").
RUN NewRow(8,"cod_repres,mes,ano,vl_meta,vl_meta_quinz","7,10,2026,1000,500").
RUN NewRow(1,"Login,ativo,tp-usuario","otherseller,yes,2").
RUN NewRow(2,"login_usuario,cod_grupo","otherseller,2").
RUN NewRow(3,"cod-rep,nome-abrev","8,otherseller").
RUN NewRow(8,"meta_repres_id,cod_repres,mes,ano,vl_meta,vl_meta_quinz","2,8,10,2026,1000,500").
RUN NewRow(9,"cod_rep_ger,mes,ano,meta","11130,10,2026,2000").
RUN NewRow(11,"login,ind_sit_ped_web","vendedor,8").
RUN NewRow(12,"nr-pedido,no-ab-reppri,cod-sit-ped,completo,tp-pedido,val-pct-desconto-total","101,vendedor,1,yes,PI,0").
RUN NewRow(13,"nr-pedido,nome-ab-rep","101,vendedor").
RUN NewRow(15,"nat-operacao,tp-rec-desp,tipo-compra","5102,1,1").
RUN NewRow(15,"nat-operacao,tp-rec-desp,tipo-compra","1202,1,3").
RUN NewRow(14,"cod-estabel,serie,nr-nota-fis,cod-rep,nr-pedcli,nat-operacao,cod-emitente,vl-tot-nota","5,1,001,7,101,5102,2,500").
hSources[14]:BUFFER-FIELD("dt-emis-nota"):BUFFER-VALUE=DATE(10,5,2026).
hSources[14]:BUFFER-FIELD("dt-cancela"):BUFFER-VALUE=?.
RUN NewRow(17,"serie-docto,nro-docto,cod-emitente,nat-operacao","1,010,2,1202").
RUN NewRow(16,"cod-estabel,serie,nr-nota-fis,serie-docto,nro-docto,cod-emitente,nat-operacao,vl-devol","5,1,001,1,010,2,1202,100").
hSources[16]:BUFFER-FIELD("dt-devol"):BUFFER-VALUE=DATE(10,10,2026).
DO dtDay=DATE(10,1,2026) TO DATE(10,31,2026):
 hSources[18]:BUFFER-CREATE().
 hSources[18]:BUFFER-FIELD("cod_calend"):BUFFER-VALUE="fiscal".
 hSources[18]:BUFFER-FIELD("dat_calend"):BUFFER-VALUE=dtDay.
 hSources[18]:BUFFER-FIELD("log_dia_util"):BUFFER-VALUE=TRUE.
END.
RUN IolGerencialCollector.p(scopeData,DATE(10,16,2026),hSources,OUTPUT snapshotData).
IF snapshotData:GetJsonObject("monthly"):GetDecimal("sales")<>1000 OR snapshotData:GetJsonObject("monthly"):GetDecimal("returns")<>150 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL monthly collector",1).
IF snapshotData:GetJsonObject("calendar"):GetInteger("total")<>22 OR snapshotData:GetJsonObject("calendar"):GetInteger("elapsed")<>12 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL commercial calendar",1).
IF snapshotData:GetJsonObject("orders"):GetInteger("pending")<>1 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL pending orders",1).
IF snapshotData:GetJsonObject("orders"):GetInteger("open")<>1 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL open orders",1).
IF snapshotData:GetJsonObject("store"):GetDecimal("adjusted_sales")<>500 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL invoice sales",1).
IF snapshotData:GetJsonArray("sellers"):GetJsonObject(1):GetDecimal("returns")<>100 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL linked return",1).
IF snapshotData:GetJsonArray("sellers"):Length<>1 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL seller received global seller list",1).
&IF DEFINED(IOL_TEST_AGGREGATE_128) <> 0 &THEN
{Collector128Parity.i}
&ENDIF
RUN NewRow(1,"Login,ativo,tp-usuario","inactive,no,4").
RUN IolGerencialIdentityService.p("inactive",hSources,OUTPUT scopeData) NO-ERROR.
IF NOT ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL inactive identity",1).
RUN NewRow(1,"Login,ativo,tp-usuario","manager,yes,3").
RUN NewRow(3,"cod-rep,nome-abrev","9,manager").
RUN NewRow(4,"cod-rep,cod-depend","9,7").
RUN NewRow(5,"cod-rep,tp-aplic-comis","9,3").
RUN IolGerencialIdentityService.p("manager",hSources,OUTPUT scopeData).
IF scopeData:GetLogical("general") OR LOOKUP("7",scopeData:GetCharacter("representatives"))=0 THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL hierarchy scope",1).
RUN NewRow(1,"Login,ativo,tp-usuario","emptyger,yes,3").
RUN NewRow(3,"cod-rep,nome-abrev","19,emptyger").
RUN NewRow(5,"cod-rep,tp-aplic-comis","19,3").
RUN IolGerencialIdentityService.p("emptyger",hSources,OUTPUT scopeData) NO-ERROR.
IF NOT ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL missing hierarchy became general",1).
RUN NewRow(1,"Login,ativo,tp-usuario","restricted,yes,4").
RUN NewRow(19,"login,ind_segur_cli_ativo,restrs_clientes_usuario_id","restricted,3,41").
RUN NewRow(20,"restr_cliente_usuario_id,cod_repres","41,7").
RUN IolGerencialIdentityService.p("restricted",hSources,OUTPUT scopeData).
IF scopeData:GetLogical("general") OR scopeData:GetCharacter("representatives")<>"7" THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL user restriction scope",1).
RUN NewRow(1,"Login,ativo,tp-usuario","emptyrestr,yes,4").
RUN NewRow(19,"login,ind_segur_cli_ativo,restrs_clientes_usuario_id","emptyrestr,3,42").
RUN IolGerencialIdentityService.p("emptyrestr",hSources,OUTPUT scopeData) NO-ERROR.
IF NOT ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL empty user restriction became general",1).
OUTPUT TO VALUE("identity-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS identity/collector checks=14" SKIP.
OUTPUT CLOSE.
DO i=1 TO 20: DELETE OBJECT hTables[i]. END.

PROCEDURE NewRow:
 DEFINE INPUT PARAMETER n AS INTEGER NO-UNDO.
 DEFINE INPUT PARAMETER fieldNames AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER fieldValues AS CHARACTER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE hf AS HANDLE NO-UNDO.
 hSources[n]:BUFFER-CREATE().
 DO j=1 TO NUM-ENTRIES(fieldNames):
  hf=hSources[n]:BUFFER-FIELD(ENTRY(j,fieldNames)).
  CASE hf:DATA-TYPE:
   WHEN "INTEGER" THEN hf:BUFFER-VALUE=INTEGER(ENTRY(j,fieldValues)).
   WHEN "DECIMAL" THEN hf:BUFFER-VALUE=DECIMAL(ENTRY(j,fieldValues)).
   WHEN "LOGICAL" THEN hf:BUFFER-VALUE=(ENTRY(j,fieldValues)="yes").
   OTHERWISE hf:BUFFER-VALUE=ENTRY(j,fieldValues).
  END CASE.
 END.
END PROCEDURE.
