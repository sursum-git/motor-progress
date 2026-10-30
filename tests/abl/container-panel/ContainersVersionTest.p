/* Undoable TT only. Never publish this test or provider. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE ht AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE runtimeProvider AS HANDLE NO-UNDO.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE cFields AS CHARACTER EXTENT 8 NO-UNDO.
DEFINE VARIABLE idx AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE modeValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE distributionCalls AS INTEGER NO-UNDO.

FUNCTION CountRows RETURNS INTEGER (tableNo AS INTEGER):
 DEFINE VARIABLE queryHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE totalRows AS INTEGER NO-UNDO.
 CREATE QUERY queryHandle. queryHandle:SET-BUFFERS(hb[tableNo]).
 queryHandle:QUERY-PREPARE("FOR EACH " + hb[tableNo]:NAME + " NO-LOCK"). queryHandle:QUERY-OPEN(). queryHandle:GET-FIRST().
 DO WHILE NOT queryHandle:QUERY-OFF-END: totalRows=totalRows + 1. queryHandle:GET-NEXT(). END.
 queryHandle:QUERY-CLOSE(). DELETE OBJECT queryHandle. RETURN totalRows.
END FUNCTION.

RUN Fixture.
RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"generate commits complete version").
RUN Check(NOT TRANSACTION,"service returned after root commit").
RUN Check(responseValue:GetJsonObject("data"):GetInteger("versao_id")=1001,"trusted version sequence captured").
RUN Check(responseValue:Has("audit"),"confirmed audit after commit").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=7,"audit contains version, five persisted child kinds and changed master").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(2):GetCharacter("resource")="item_container_custos","child audit uses physical resource").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):GetJsonObject(2):GetJsonObject("after"):GetInteger("item_container_custo_id")=2001,"child audit uses physical item key").
RUN Check(responseValue:Has("committed"),"root response declares commit state").
RUN Check(responseValue:GetLogical("committed"),"root response confirms actual commit").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("before"):GetLogical("log_versao_custo_desatualizada"),"audit records stale master before generation").
RUN Check(NOT responseValue:GetJsonObject("audit"):GetJsonObject("master"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"audit records master stale reset after commit").
hb[3]:FIND-FIRST() NO-ERROR.
RUN Check(hb[3]:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=2,"complete only after all children").
RUN Check(hb[3]:BUFFER-FIELD("container_id"):BUFFER-VALUE=123,"version belongs to context").
RUN Check(hb[3]:BUFFER-FIELD("vl_dolar_medio"):BUFFER-VALUE=5,"master average supplied by central calculator").
hb[4]:FIND-FIRST() NO-ERROR.
RUN Check(hb[4]:BUFFER-FIELD("vl_unit_prev"):BUFFER-VALUE=13,"real item snapshot reused").
RUN Check(hb[4]:BUFFER-FIELD("vl_unit_prev_dolar"):BUFFER-VALUE=2.6,"dollar item snapshot reused by id").
RUN Check(hb[4]:BUFFER-FIELD("item_container_custo_id"):BUFFER-VALUE=2001,"trusted item sequence captured").
DO idx=5 TO 8: hb[idx]:FIND-FIRST() NO-ERROR. RUN Check(hb[idx]:AVAILABLE,"physical child persisted " + STRING(idx)). END.
hb[1]:FIND-FIRST() NO-ERROR.
RUN Check(NOT hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE,"stale reset after complete snapshot").
RUN Invoke. RUN Code("VERSION_CONFLICT").
RUN Check(CountRows(3)=1,"same expected_latest prevents optimistic repetition").
RUN Parse('~{"operation":"consultar","container_id":123}',OUTPUT requestValue). RUN Invoke.
RUN Check(responseValue:GetJsonArray("data"):Length=1,"contextual version list").
RUN Parse('~{"operation":"consultar","container_id":999,"versao_id":1001}',OUTPUT requestValue). RUN Invoke. RUN Code("VERSION_NOT_FOUND").
RUN Parse('~{"operation":"excluir_incompleta","container_id":123,"versao_id":1001,"expected_latest_version_id":1001}',OUTPUT requestValue). RUN Invoke. RUN Code("VERSION_COMPLETE").
RUN Check(CountRows(4)=1,"complete version children retained").

/* Every callback failure must roll back fiscal, master and all children. */
DO idx=1 TO 14:
 modeValue=ENTRY(idx,"fiscal-fail,collect-fail,wrong-context,duplicate-expense,bad-child,unknown-field,wrong-cost-source,duplicate-item,invalid-audit,invalid-warning,distribution,null-confirmed,null-complete,null-distribution").
 RUN Fixture. RUN SetMode IN runtimeProvider(modeValue). RUN Invoke.
 RUN Check(NOT responseValue:GetLogical("success"),"reject provider mode " + modeValue).
 RUN Check(NOT responseValue:Has("audit"),"no confirmed audit on callback rollback").
 RUN Check(NOT responseValue:Has("pendingMaster"),"failed generation has no successful pending snapshot").
 RUN Check(CountRows(3)=0 AND CountRows(4)=0 AND CountRows(5)=0,"no partial version/children " + modeValue).
 hb[1]:FIND-FIRST() NO-ERROR.
 RUN Check(hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE,"stale restored " + modeValue).
 RUN Check(hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original","fiscal rollback " + modeValue).
END.
RUN Fixture. RUN SetMode IN runtimeProvider("real-null"). RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"unknown realized does not prohibit generating version").
hb[4]:FIND-FIRST() NO-ERROR.
RUN Check(hb[4]:BUFFER-FIELD("vl_unit_realiz"):BUFFER-VALUE=?,"unknown BRL stored unknown, never fake zero").
RUN Check(hb[4]:BUFFER-FIELD("vl_unit_realiz_dolar"):BUFFER-VALUE=?,"unknown USD stored unknown").
RUN Check(NOT responseValue:GetJsonObject("calculation"):GetLogical("actual_complete"),"incomplete provenance exposed explicitly").

hb[3]:FIND-FIRST() NO-ERROR. hb[3]:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=1.
hb[4]:FIND-FIRST() NO-ERROR. hb[4]:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE=999.
RUN Parse('~{"operation":"excluir_incompleta","container_id":123,"versao_id":1001,"expected_latest_version_id":1001}',OUTPUT requestValue). RUN Invoke. RUN Code("VERSION_USED").
RUN Check(CountRows(3)=1 AND CountRows(4)=1,"used version and child retained").
hb[4]:FIND-FIRST() NO-ERROR. hb[4]:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE=?.
RUN Invoke. RUN Code("VERSION_USED").
RUN Check(CountRows(3)=1 AND CountRows(4)=1,"unknown usage cannot authorize deletion").
hb[4]:FIND-FIRST() NO-ERROR. hb[4]:BUFFER-FIELD("item_custo_id"):BUFFER-VALUE=0.

/* Delete only incomplete, unused version and its own children. */
hb[3]:FIND-FIRST() NO-ERROR. hb[3]:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=1.
RUN Parse('~{"operation":"excluir_incompleta","container_id":123,"versao_id":1001,"expected_latest_version_id":1001}',OUTPUT requestValue). RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"incomplete version deleted").
DO idx=3 TO 8: RUN Check(CountRows(idx)=0,"own child removed " + STRING(idx)). END.

RUN Fixture.
hb[3]:BUFFER-CREATE(). hb[3]:BUFFER-FIELD("versao_id"):BUFFER-VALUE=9000. hb[3]:BUFFER-FIELD("container_id"):BUFFER-VALUE=999. hb[3]:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=2. hb[3]:BUFFER-RELEASE().
RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"higher id in other container does not change expected_latest").
RUN Check(responseValue:GetJsonObject("data"):GetInteger("versao_id")=1001,"sequence callback, not global MAX+1").
RUN Check(CountRows(3)=2,"other container version preserved").
DO TRANSACTION:
 hb[3]:FIND-FIRST("WHERE " + hb[3]:NAME + ".versao_id=1001",EXCLUSIVE-LOCK) NO-ERROR.
 RUN Check(hb[3]:AVAILABLE,"new contextual version available after foreign seed").
 hb[3]:BUFFER-FIELD("ind_sit_versao"):BUFFER-VALUE=1. hb[3]:BUFFER-RELEASE().
END.
RUN Parse('~{"operation":"excluir_incompleta","container_id":123,"versao_id":1001,"expected_latest_version_id":1001}',OUTPUT requestValue). RUN Invoke.
RUN Check(responseValue:GetLogical("success") AND CountRows(3)=1,"deletion retains unrelated container").

RUN Fixture. RUN SetMode IN runtimeProvider("unordered-items"). RUN Invoke.
RUN Check(responseValue:GetLogical("success") AND CountRows(4)=2,"two central items persisted").
hb[4]:FIND-FIRST("WHERE " + hb[4]:NAME + ".item_container_id=11",NO-LOCK) NO-ERROR.
RUN Check(hb[4]:BUFFER-FIELD("vl_unit_prev_dolar"):BUFFER-VALUE=2.6,"USD paired by id11 despite reverse order").
hb[4]:FIND-FIRST("WHERE " + hb[4]:NAME + ".item_container_id=22",NO-LOCK) NO-ERROR.
RUN Check(hb[4]:BUFFER-FIELD("vl_unit_prev_dolar"):BUFFER-VALUE=5.2 AND hb[4]:BUFFER-FIELD("vl_unit_prev"):BUFFER-VALUE=26,"BRL and USD id22 matched").

RUN Fixture.
policyValue:GetJsonObject("actor"):Set("login",""). RUN Invoke. RUN Code("VERSION_IDENTITY_REQUIRED").
RUN Check(CountRows(3)=0,"missing actor never writes").
RUN Fixture. requestValue:Add("sql","forged"). RUN Invoke. RUN Code("VERSION_INVALID_REQUEST").
RUN Fixture. requestValue:Set("expected_latest_version_id",1). RUN Invoke. RUN Code("VERSION_CONFLICT").
RUN Fixture. requestValue:Set("tipo_versao_id",999). RUN Invoke. RUN Code("VERSION_TYPE_NOT_FOUND").
RUN Fixture. requestValue:Set("container_id",2147483648). RUN Invoke. RUN Code("VERSION_INVALID_REQUEST").
RUN Fixture.
DO TRANSACTION:
 RUN Invoke. RUN Code("VERSION_TRANSACTION_CONTEXT").
END.
RUN Fixture. policyValue:Add("allow_nested",TRUE).
nestedVersion: DO TRANSACTION:
 RUN Invoke.
 RUN Check(responseValue:GetLogical("success"),"private nested service reuses same writer").
 RUN Check(NOT responseValue:GetLogical("committed") AND NOT responseValue:Has("audit"),"nested response never confirms ancestor commit").
 RUN Check(responseValue:GetJsonArray("pendingChanges"):Length=7,"pending version, five children and master events ready for ancestor").
 RUN Check(responseValue:GetJsonObject("pendingMaster"):GetJsonObject("before"):GetLogical("log_versao_custo_desatualizada") AND NOT responseValue:GetJsonObject("pendingMaster"):GetJsonObject("after"):GetLogical("log_versao_custo_desatualizada"),"pending master snapshots are explicit").
 UNDO nestedVersion, LEAVE nestedVersion.
END.
RUN Check(CountRows(3)=0 AND CountRows(4)=0,"ancestor rollback undoes nested version and children").
hb[1]:FIND-FIRST() NO-ERROR.
RUN Check(hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE AND hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original","ancestor rollback restores nested master and fiscal effects").
RUN Fixture. RUN SetMode IN runtimeProvider("distribution"). policyValue:Add("enable_distribution",TRUE). RUN Invoke.
RUN Check(responseValue:GetLogical("success"),"explicit private optin enables central distribution callback").
RUN GetDistributionCalls IN runtimeProvider(OUTPUT distributionCalls).
RUN Check(distributionCalls=1,"one central callback after physical child IDs").
RUN Check(responseValue:GetJsonObject("audit"):GetJsonArray("changes"):Length=8,"distribution and all snapshot effects join root audit only after commit").
RUN Fixture. RUN SetMode IN runtimeProvider("distribution-untrusted"). policyValue:Add("enable_distribution",TRUE). RUN Invoke. RUN Code("VERSION_DISTRIBUTION_UNSUPPORTED").
RUN GetDistributionCalls IN runtimeProvider(OUTPUT distributionCalls). RUN Check(distributionCalls=0,"unconfirmed capability cannot enable callback").
RUN Fixture. RUN SetMode IN runtimeProvider("distribution"). policyValue:Add("enable_distribution",1). RUN Invoke. RUN Code("VERSION_CONFIGURATION").
RUN Fixture. RUN SetMode IN runtimeProvider("distribution-fail"). policyValue:Add("enable_distribution",TRUE). RUN Invoke.
RUN Code("VERSION_DISTRIBUTION_FAILED"). RUN Check(CountRows(3)=0 AND CountRows(4)=0,"distribution failure rolls back root version and children").
hb[1]:FIND-FIRST() NO-ERROR. RUN Check(hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original" AND hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE,"distribution failure restores fiscal and master changes").
RUN Fixture. RUN SetMode IN runtimeProvider("distribution-early-audit"). policyValue:Add("enable_distribution",TRUE). RUN Invoke.
RUN Code("VERSION_DISTRIBUTION_FAILED"). RUN Check(CountRows(3)=0,"early audit rejected and all writes undone").
OUTPUT TO VALUE("containers-version-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks; undoable TT only; no business database." SKIP.
OUTPUT CLOSE.


PROCEDURE Check:
 DEFINE INPUT PARAMETER conditionValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER labelValue AS CHARACTER NO-UNDO.
 checks=checks + 1.
 IF conditionValue<>TRUE OR conditionValue=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + labelValue,1).
END PROCEDURE.
PROCEDURE Code:
 DEFINE INPUT PARAMETER expectedCode AS CHARACTER NO-UNDO.
 RUN Check(responseValue:GetLogical("success")=FALSE,"failure " + expectedCode).
 RUN Check(responseValue:GetJsonObject("error"):GetCharacter("code")=expectedCode,"code " + expectedCode).
 RUN Check(NOT responseValue:Has("audit"),"no audit on failure").
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersVersionService.p(hb[1],hb[2],hb[3],hb[4],hb[5],hb[6],hb[7],hb[8],runtimeProvider,policyValue,requestValue,OUTPUT responseValue) NO-ERROR.
 IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError("Service missing/failed: " + ERROR-STATUS:GET-MESSAGE(1),1).
END PROCEDURE.
PROCEDURE Parse:
 DEFINE INPUT PARAMETER jsonValue AS LONGCHAR NO-UNDO.
 DEFINE OUTPUT PARAMETER objectValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
 parser=NEW ObjectModelParser(). objectValue=CAST(parser:Parse(jsonValue),JsonObject). DELETE OBJECT parser.
END PROCEDURE.
PROCEDURE Fixture:
 DEFINE VARIABLE tableNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldNo AS INTEGER NO-UNDO.
 DEFINE VARIABLE fieldDefinition AS CHARACTER NO-UNDO.
 DEFINE VARIABLE keyFields AS CHARACTER NO-UNDO.
 IF VALID-HANDLE(runtimeProvider) THEN DELETE PROCEDURE runtimeProvider.
 {ContainersVersionTestTables.i}
 DO tableNo=1 TO 8:
  IF VALID-HANDLE(ht[tableNo]) THEN DELETE OBJECT ht[tableNo].
  CREATE TEMP-TABLE ht[tableNo].
  DO fieldNo=1 TO NUM-ENTRIES(cFields[tableNo]):
   fieldDefinition=ENTRY(fieldNo,cFields[tableNo]).
   ht[tableNo]:ADD-NEW-FIELD(ENTRY(1,fieldDefinition,":"),ENTRY(2,fieldDefinition,":")).
  END.
  keyFields=ENTRY(tableNo,"nr-container;tipo_versao_custo_id;versao_id;item_container_custo_id;versao_id,despesa_id;versao_id,documento,serie,estab,nat_operacao,cod_emitente;versao_id,num_id_tit_ap;versao_id,desconto_importacao_id",";").
  ht[tableNo]:UNDO=TRUE. ht[tableNo]:ADD-NEW-INDEX("pk",TRUE,TRUE).
  DO fieldNo=1 TO NUM-ENTRIES(keyFields): ht[tableNo]:ADD-INDEX-FIELD("pk",ENTRY(fieldNo,keyFields)). END.
  ht[tableNo]:TEMP-TABLE-PREPARE("fxVersion" + STRING(tableNo)). hb[tableNo]=ht[tableNo]:DEFAULT-BUFFER-HANDLE.
 END.
 hb[1]:BUFFER-CREATE(). hb[1]:BUFFER-FIELD("nr-container"):BUFFER-VALUE=123.
 hb[1]:BUFFER-FIELD("log_versao_custo_desatualizada"):BUFFER-VALUE=TRUE. hb[1]:BUFFER-FIELD("narrativa"):BUFFER-VALUE="original". hb[1]:BUFFER-RELEASE().
 hb[2]:BUFFER-CREATE(). hb[2]:BUFFER-FIELD("tipo_versao_custo_id"):BUFFER-VALUE=1. hb[2]:BUFFER-RELEASE().
 RUN ContainersVersionFixture.p PERSISTENT SET runtimeProvider.
 RUN Parse('~{"actor":~{"login":"version-test","id":"opaque-user"}}',OUTPUT policyValue).
 RUN Parse('~{"operation":"gerar","container_id":123,"tipo_versao_id":1,"descricao":"TT VERSION TEST","expected_latest_version_id":0}',OUTPUT requestValue).
END PROCEDURE.
