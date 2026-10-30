/* Undoable real temp-tables, no business database. Test provider never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE NO-UNDO.
DEFINE VARIABLE hb AS HANDLE NO-UNDO.
DEFINE VARIABLE hRules AS HANDLE NO-UNDO.
DEFINE VARIABLE hSaved AS HANDLE NO-UNDO.
DEFINE VARIABLE hFornec AS HANDLE NO-UNDO.
DEFINE VARIABLE hEmpresa AS HANDLE NO-UNDO.
DEFINE VARIABLE hChild AS HANDLE NO-UNDO.
DEFINE VARIABLE oReq AS JsonObject NO-UNDO.
DEFINE VARIABLE oPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE oResult AS JsonObject NO-UNDO.
DEFINE VARIABLE oRow AS JsonObject NO-UNDO.
DEFINE VARIABLE iChecks AS INTEGER NO-UNDO.
DEFINE TEMP-TABLE ttFornecedor FIELD cdn_fornecedor AS INTEGER FIELD nom_abrev AS CHARACTER FIELD cod_empresa AS CHARACTER.
DEFINE TEMP-TABLE ttEmpresa FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER FIELD cod_emp_ems5 AS INTEGER.
DEFINE TEMP-TABLE ttChild FIELD valor AS INTEGER.

FUNCTION PropertyCount RETURNS INTEGER (o AS JsonObject):
 DEFINE VARIABLE cNames AS CHARACTER EXTENT NO-UNDO.
 cNames=o:GetNames(). IF EXTENT(cNames)=? THEN RETURN 0. RETURN EXTENT(cNames).
END FUNCTION.

RUN Fixture.
RUN Check(NOT TRANSACTION,"caller has no ambient transaction before create").
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"manual container create").
oRow=oResult:GetJsonObject("data").
RUN Eq(oRow:GetInteger("container_id"),123,"manual ID preserved").
RUN Eq(oRow:GetInteger("situacao"),1,"ERP default1").
RUN Check(oRow:GetLogical("log_versao_custo_desatualizada"),"new version stale default").
RUN Check(oRow:GetCharacter("nome_ab_forn")="Fornecedor ERP","supplier abbreviation derived in server").
RUN Check(PropertyCount(oResult:GetJsonObject("audit"):GetJsonObject("before"))=0,"create empty before").
RUN Check(oResult:GetJsonObject("audit"):GetJsonObject("after"):GetInteger("container_id")=123,"confirmed create snapshot").
RUN Check(oResult:GetJsonObject("audit"):GetJsonObject("actor"):GetCharacter("login")="admin-test","private actor snapshot").
DO TRANSACTION:
 RUN Parse('~{"operation":"update","container_id":123,"values":~{"narrativa":"ambient"}}',OUTPUT oReq).
 RUN Invoke. RUN Code("CONTAINER_TRANSACTION_CONTEXT").
END.
RUN Parse('~{"operation":"create","container_id":123,"values":~{"cod_estabel":"5","cod_emit_forn":10,"ordem_busca_dolar_compra":"2,1","ordem_busca_dolar_di":"4,1","cod_tipo_proj_dolar":1}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_EXISTS").
hb:FIND-FIRST() NO-ERROR. hb:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=FALSE.
RUN Parse('~{"operation":"update","container_id":123,"values":~{"narrativa":"atual","dt_prev_chegada_loja":"2027-01-15"}}',OUTPUT oReq).
RUN SetMode IN hRules("warning").
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"update with rule provider").
RUN Check(NOT oResult:GetJsonObject("data"):GetLogical("log_versao_custo_desatualizada"),"ordinary change preserves current version flag").
FIND FIRST ttChild. RUN Eq(ttChild.valor,11,"provider child committed with master").
RUN Check(oResult:GetJsonObject("audit"):GetJsonArray("changes"):Length=1,"child audit emitted with confirmed transaction").
RUN Check(oResult:GetJsonObject("audit"):GetJsonArray("warnings"):GetCharacter(1)="IPI preservado conforme regra fiscal.","controlled provider warning reaches confirmed audit").
RUN Check(oResult:GetJsonObject("data"):GetCharacter("dt_prev_chegada_loja")="2027-01-15","DATE ISO without culture shift").
RUN SetMode IN hRules("fail").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"narrativa":"rollback"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_RULE_FAILED").
hb:FIND-FIRST() NO-ERROR. RUN Check(hb:BUFFER-FIELD("narrativa"):BUFFER-VALUE="atual","master rollback on child failure").
FIND FIRST ttChild. RUN Eq(ttChild.valor,11,"child rollback on provider failure").
RUN SetMode IN hRules("invalid-audit"). RUN Invoke. RUN Code("CONTAINER_RULE_FAILED").
FIND FIRST ttChild. RUN Eq(ttChild.valor,11,"invalid child audit rolls back business writes").
RUN SetMode IN hRules("invalid-warning"). RUN Invoke. RUN Code("CONTAINER_RULE_FAILED").
FIND FIRST ttChild. RUN Eq(ttChild.valor,11,"invalid warning also rolls back child writes").
RUN SetMode IN hRules("ok").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"vl_dolar_compra":5.1234567891}}',OUTPUT oReq).
RUN Invoke.
RUN Check(oResult:GetLogical("success"),"dollar update succeeds").
RUN Check(oResult:GetJsonObject("data"):GetLogical("log_versao_custo_desatualizada"),"dollar parameters invalidate version").
RUN Check(NOT oResult:GetJsonObject("data"):IsNull("dt_hr_ult_alt_versao_custo"),"dollar change stamps current datetime").
RUN Check(oResult:GetJsonObject("data"):GetCharacter("dt_prev_chegada_loja")="2027-01-15","omitted store arrival preserves persisted date").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"container_id":999}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"values":~{}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"id":124,"values":~{"narrativa":"divergente"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"nome_ab_forn":"client name"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"log_versao_custo_desatualizada":false}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"vl_dolar_compra":"5,25"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"log_pagto_final":"true"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Parse('~{"operation":"update","container_id":123,"values":~{"dt_prev_chegada_loja":"2027-02-30"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
hSaved=hRules. hRules=?.
RUN Parse('~{"operation":"update","container_id":123,"values":~{"narrativa":"sem regra"}}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_RULE_UNAVAILABLE"). hRules=hSaved.
RUN SetMode IN hRules("unsupported"). RUN Invoke. RUN Code("CONTAINER_RULE_UNAVAILABLE").
RUN SetMode IN hRules("blocked").
RUN Parse('~{"operation":"delete","container_id":123}',OUTPUT oReq).
RUN Invoke. RUN Code("CONTAINER_RULE_FAILED").
hb:FIND-FIRST() NO-ERROR. RUN Check(hb:AVAILABLE,"dependency rejection retains master").
FIND FIRST ttChild. RUN Eq(ttChild.valor,12,"dependency rejection before estorno leaves child").
RUN SetMode IN hRules("fail"). RUN Invoke. RUN Code("CONTAINER_RULE_FAILED").
hb:FIND-FIRST() NO-ERROR. RUN Check(hb:AVAILABLE,"delete callback failure rolls back master").
FIND FIRST ttChild. RUN Eq(ttChild.valor,12,"delete callback failure restores removed child").
RUN SetMode IN hRules("ok"). RUN Invoke.
RUN Check(oResult:GetLogical("success"),"delete complete composite transaction").
RUN Check(PropertyCount(oResult:GetJsonObject("audit"):GetJsonObject("after"))=0,"delete empty current snapshot").
hb:FIND-FIRST() NO-ERROR. RUN Check(NOT hb:AVAILABLE,"master deleted after child operation confirmed").
FIND FIRST ttChild NO-ERROR. RUN Check(NOT AVAILABLE ttChild,"child deletion committed together").
RUN Parse('~{"operation":"get","id":123}',OUTPUT oReq). RUN Invoke. RUN Code("CONTAINER_NOT_FOUND").
RUN Fixture.
oReq:Set("container_id",2147483648). RUN Invoke. RUN Code("CONTAINER_VALIDATION").
RUN Fixture.
oPolicy:GetJsonObject("actor"):Set("login",""). RUN Invoke. RUN Code("CONTAINER_IDENTITY_REQUIRED").
RUN Fixture.
RUN DuplicateSupplier.
RUN Invoke. RUN Code("CONTAINER_VALIDATION").
hb:FIND-FIRST() NO-ERROR. RUN Check(NOT hb:AVAILABLE,"ambiguous supplier rolls back new master").
RUN Fixture.
oReq:GetJsonObject("values"):Set("cod_emit_forn",999). RUN Invoke. RUN Code("CONTAINER_VALIDATION").
hb:FIND-FIRST() NO-ERROR. RUN Check(NOT hb:AVAILABLE,"missing supplier rolls back new master").

IF VALID-HANDLE(hRules) THEN DELETE PROCEDURE hRules.
IF VALID-HANDLE(ht) THEN DELETE OBJECT ht.
OUTPUT TO VALUE("containers-cabecalho-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " iChecks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 iChecks=iChecks + 1. IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + c,1).
END PROCEDURE.
PROCEDURE Eq:
 DEFINE INPUT PARAMETER d AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER e AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 RUN Check(d=e,c).
END PROCEDURE.
PROCEDURE Code:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 RUN Check(oResult:GetLogical("success")=FALSE,"failure " + c).
 RUN Check(oResult:GetJsonObject("error"):GetCharacter("code")=c,"code " + c).
 RUN Check(NOT oResult:Has("audit"),"no confirmed audit on rollback").
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersCabecalhoCrudService.p(hb,hFornec,hEmpresa,hRules,oPolicy,oReq,OUTPUT oResult) NO-ERROR.
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL service missing or failed " + ERROR-STATUS:GET-MESSAGE(1),1).
END PROCEDURE.
PROCEDURE Parse:
 DEFINE INPUT PARAMETER lc AS LONGCHAR NO-UNDO.
 DEFINE OUTPUT PARAMETER o AS JsonObject NO-UNDO.
 DEFINE VARIABLE p AS ObjectModelParser NO-UNDO.
 p=NEW ObjectModelParser(). o=CAST(p:Parse(lc),JsonObject). DELETE OBJECT p.
END PROCEDURE.
PROCEDURE DuplicateSupplier:
 CREATE ttFornecedor. ASSIGN ttFornecedor.cdn_fornecedor=10 ttFornecedor.nom_abrev="Duplicado" ttFornecedor.cod_empresa="50".
END PROCEDURE.
PROCEDURE Fixture:
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE f AS CHARACTER NO-UNDO.
 DEFINE VARIABLE cFieldDefs AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(hRules) THEN DELETE PROCEDURE hRules.
 IF VALID-HANDLE(ht) THEN DELETE OBJECT ht.
 CREATE TEMP-TABLE ht.
 cFieldDefs="cod-estabel:character,nr-container:integer,num-pedido:integer,nome-ab-forn:character,cod-emit-forn:integer,comprador:character,narrativa:character,usuario:character,dt-compra:date,dt-prev-chegada:date,dt-recebimento:date,situacao:integer,char-1:character,dec-1:decimal,int-1:integer,log-1:logical,data-1:date,vlr-frete:decimal,vlr-seguro:decimal,vlr-despesas:decimal,exclusivo:logical,vl-dolar-venda:decimal,vl-dolar-compra:decimal,log_liberar_custo_realizado:logical,medidas_container:character,dt_prev_embarque:date,dt_real_embarque:date,ind_dt_embarque:integer,situacao_container_id:integer,ind_dt_prev_chegada:integer,log_pagto_final:logical,cod_agente_cargas:integer,cod_armador:integer,cod_tipo_calculo:integer,perc_custo:decimal,vl_dolar_di:decimal,log_gerar_saldo_a_pagar:logical,log_gerar_distr_custo:logical,ordem_busca_dolar_compra:character,ordem_busca_dolar_di:character,cod_tipo_proj_dolar:integer,vl_proj_dolar:decimal,log_versao_custo_desatualizada:logical,dt_hr_ult_alt_versao_custo:datetime,ptax:decimal,cod-depos:character,dt_prev_chegada_loja:date,estacao:integer,num_origem:integer,log_rota_indefinida:logical".
 DO j=1 TO NUM-ENTRIES(cFieldDefs): f=ENTRY(j,cFieldDefs). ht:ADD-NEW-FIELD(ENTRY(1,f,":"),ENTRY(2,f,":")). END.
 ht:UNDO=TRUE. ht:ADD-NEW-INDEX("pk",TRUE,TRUE). ht:ADD-INDEX-FIELD("pk","nr-container"). ht:TEMP-TABLE-PREPARE("fxContainer"). hb=ht:DEFAULT-BUFFER-HANDLE.
 EMPTY TEMP-TABLE ttFornecedor. EMPTY TEMP-TABLE ttEmpresa. EMPTY TEMP-TABLE ttChild.
 CREATE ttFornecedor. ASSIGN ttFornecedor.cdn_fornecedor=10 ttFornecedor.nom_abrev="Fornecedor ERP" ttFornecedor.cod_empresa="50".
 CREATE ttEmpresa. ASSIGN ttEmpresa.empresa_id=1 ttEmpresa.cod_emp_ems2=5 ttEmpresa.cod_emp_ems5=50.
 CREATE ttChild. ttChild.valor=10.
 ASSIGN hFornec=BUFFER ttFornecedor:HANDLE hEmpresa=BUFFER ttEmpresa:HANDLE hChild=BUFFER ttChild:HANDLE.
 RUN ContainersCabecalhoRulesFixture.p PERSISTENT SET hRules(hChild).
 RUN Parse('~{"actor":~{"login":"admin-test","id":"test-user"}}',OUTPUT oPolicy).
 RUN Parse('~{"operation":"create","container_id":123,"values":~{"cod_estabel":"5","cod_emit_forn":10,"ordem_busca_dolar_compra":"2,1","ordem_busca_dolar_di":"4,1","cod_tipo_proj_dolar":1}}',OUTPUT oReq).
END PROCEDURE.

