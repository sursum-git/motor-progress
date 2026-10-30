BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttMaster FIELD nr-container AS INTEGER FIELD cod-estabel AS CHARACTER FIELD situacao_container_id AS INTEGER FIELD log_gerar_distr_custo AS LOGICAL INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE TEMP-TABLE ttCompany FIELD empresa_id AS INTEGER FIELD cod_emp_ems2 AS INTEGER INDEX pk IS UNIQUE PRIMARY empresa_id.
DEFINE TEMP-TABLE ttStatus FIELD situacao_container_id AS INTEGER FIELD log_gerar_distr_custo AS LOGICAL INDEX pk IS UNIQUE PRIMARY situacao_container_id.
DEFINE TEMP-TABLE ttItem FIELD item_container_id AS INTEGER FIELD container_id AS INTEGER FIELD item_proc_compra_id AS INTEGER FIELD qt_alocada AS DECIMAL DECIMALS 10 FIELD qt_confirm_emb AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY item_container_id.
DEFINE TEMP-TABLE ttPurchase FIELD item_proc_compra_id AS INTEGER FIELD ind_distr_custo AS INTEGER FIELD vl_base_tributacao AS DECIMAL DECIMALS 10 FIELD vl_negociado AS DECIMAL DECIMALS 10 INDEX pk IS UNIQUE PRIMARY item_proc_compra_id.
DEFINE TEMP-TABLE ttLink FIELD empresas_despesa_id AS INTEGER FIELD empresa_id AS INTEGER FIELD despesa_id AS INTEGER FIELD log_custo AS INTEGER.
DEFINE TEMP-TABLE ttDef FIELD despesa_id AS INTEGER INDEX pk IS UNIQUE PRIMARY despesa_id.
DEFINE TEMP-TABLE ttLedger FIELD cta_corren_custo_distr_id AS INTEGER FIELD data AS DATE FIELD item_container_custo_id AS INTEGER FIELD item_container_id AS INTEGER FIELD historico AS CHARACTER FIELD cod_tipo_movto AS INTEGER FIELD vl_lancto AS DECIMAL DECIMALS 2 FIELD despesa_container_id AS INTEGER FIELD login AS CHARACTER INDEX pk IS UNIQUE PRIMARY cta_corren_custo_distr_id.
DEFINE TEMP-TABLE ttVersionItem FIELD item_container_custo_id AS INTEGER FIELD versao_id AS INTEGER FIELD item_container_id AS INTEGER FIELD vl_custo_distribuido AS DECIMAL DECIMALS 2 INDEX pk IS UNIQUE PRIMARY item_container_custo_id.
DEFINE TEMP-TABLE ttVersion FIELD versao_id AS INTEGER FIELD container_id AS INTEGER FIELD ind_sit_versao AS INTEGER INDEX pk IS UNIQUE PRIMARY versao_id.
DEFINE TEMP-TABLE ttExpense FIELD despesa_container_id AS INTEGER FIELD despesa_id AS INTEGER FIELD vl_prev AS DECIMAL DECIMALS 2 FIELD container_id AS INTEGER FIELD calc_imp_container_id AS INTEGER FIELD vl_base_imp AS DECIMAL DECIMALS 2 FIELD vl_negociado AS DECIMAL DECIMALS 2 FIELD vl_proforma AS DECIMAL DECIMALS 2 FIELD cta_corren_custo_distr_id AS INTEGER FIELD log_utilizado AS LOGICAL FIELD log_manual AS LOGICAL FIELD perc_calc AS DECIMAL FIELD memoria_calculo AS CHARACTER FIELD item_container_id AS INTEGER INDEX pk IS UNIQUE PRIMARY despesa_container_id.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE requestData AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE snapshotData AS JsonObject NO-UNDO.
DEFINE VARIABLE a AS JsonArray NO-UNDO.
DEFINE VARIABLE o AS JsonObject NO-UNDO.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE countValue AS INTEGER NO-UNDO.
DEFINE VARIABLE hb AS HANDLE EXTENT 11 NO-UNDO.
ASSIGN hb[1]=BUFFER ttMaster:HANDLE hb[2]=BUFFER ttCompany:HANDLE hb[3]=BUFFER ttStatus:HANDLE hb[4]=BUFFER ttItem:HANDLE hb[5]=BUFFER ttPurchase:HANDLE hb[6]=BUFFER ttLink:HANDLE hb[7]=BUFFER ttDef:HANDLE hb[8]=BUFFER ttLedger:HANDLE hb[9]=BUFFER ttVersionItem:HANDLE hb[10]=BUFFER ttVersion:HANDLE hb[11]=BUFFER ttExpense:HANDLE.
RUN ContainersDistribuicaoRuntimeFixture.p PERSISTENT SET runtime.
RUN Fixture. requestData:Set("operation","simulate"). requestData:Remove("version_id"). requestData:Remove("item_mappings"). requestData:Remove("snapshot"). RUN Invoke.
RUN Check(result:GetLogical("success") AND NOT result:GetLogical("committed"),"read-only simulation").
RUN Check(NOT CAN-FIND(FIRST ttLedger) AND NOT CAN-FIND(FIRST ttExpense WHERE ttExpense.despesa_id=99),"simulation no writes").
RUN Check(NOT result:Has("audit") AND result:GetJsonObject("data"):Has("plan"),"simulation only plan no confirmed audit").
RUN Fixture. policy:Set("company_policy","container_company").
FOR EACH ttLink: ttLink.empresa_id=9. END. RUN Invoke.
RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetJsonObject("plan"):GetInteger("company_id")=9,"approved production policy derives container company").
RUN Check(result:GetJsonObject("data"):GetJsonObject("plan"):GetDecimal("expense_pool")=45,"derived company selects its own links").
RUN Fixture. requestData:Set("operation","simulate"). requestData:Remove("version_id"). requestData:Remove("item_mappings"). requestData:Remove("snapshot").
CREATE ttVersionItem. ASSIGN ttVersionItem.item_container_custo_id=1 ttVersionItem.item_container_id=1 ttVersionItem.versao_id=0 ttVersionItem.vl_custo_distribuido=3. RUN Invoke.
RUN Check(result:GetJsonObject("data"):GetJsonObject("plan"):GetJsonArray("items"):GetJsonObject(1):GetJsonObject("memory"):GetDecimal("previous_distribution")=5,"simulation includes all historical snapshots including versionzero as legacy SUM").
RUN Fixture. RUN Invoke.
RUN Check(result:GetLogical("success") AND result:GetLogical("committed"),"root version effect transaction commits").
RUN Check(result:GetLogical("requiredNewSnapshot"),"automatic effect requests followup").
FIND ttVersionItem WHERE ttVersionItem.item_container_custo_id=71.
RUN Check(ttVersionItem.vl_custo_distribuido=18,"target snapshot raw delta").
FIND ttLedger WHERE ttLedger.item_container_custo_id=71.
RUN Check(ttLedger.cod_tipo_movto=3 AND ttLedger.item_container_id=0 AND ttLedger.vl_lancto=18 AND ttLedger.data=TODAY AND ttLedger.login="actor-test","physical ledger source fields").
FIND ttExpense WHERE ttExpense.cta_corren_custo_distr_id=ttLedger.cta_corren_custo_distr_id.
RUN Check(ttExpense.container_id=123 AND ttExpense.item_container_id=1 AND ttExpense.despesa_id=99 AND ttExpense.vl_prev=18,"managed expense explicitly owns container and item").
RUN Check(ttExpense.log_manual AND ttExpense.vl_negociado=0 AND ttExpense.calc_imp_container_id=0 AND NOT ttExpense.log_utilizado,"managed expense source defaults").
RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length=6,"audit two snapshots two ledgers two expenses").
RUN Fixture. requestData:Set("operation","version_check"). RUN Invoke.
RUN Check(result:GetLogical("success") AND result:GetLogical("requiredNewSnapshot") AND NOT result:GetLogical("committed"),"check exposes unstable delta read only").
RUN Check(NOT CAN-FIND(FIRST ttLedger),"version_check never emits movements").
FIND ttVersionItem WHERE ttVersionItem.item_container_custo_id=71. RUN Check(ttVersionItem.vl_custo_distribuido=0,"version_check never mutates snapshots").
RUN Fixture.
DO TRANSACTION:
 RUN Invoke.
 RUN Check(result:GetLogical("success") AND NOT result:GetLogical("committed") AND result:Has("pendingChanges") AND NOT result:Has("audit"),"nested pending no early audit").
 UNDO.
END.
RUN Check(NOT CAN-FIND(FIRST ttLedger),"outer rollback removes all nested effects").
RUN Fixture. policy:Set("allow_nested",FALSE).
DO TRANSACTION: RUN Invoke. RUN ErrorCode("DISTRIBUTION_TRANSACTION_CONTEXT"). END.
RUN Check(NOT CAN-FIND(FIRST ttLedger),"unapproved ambient transaction fails before writes").
RUN Fixture. requestData:GetJsonArray("item_mappings"):GetJsonObject(2):Set("item_container_custo_id",71). RUN Invoke. RUN ErrorCode("DISTRIBUTION_MAPPING_INVALID").
RUN Check(NOT CAN-FIND(FIRST ttLedger),"bad final mapping writes nothing").
RUN Fixture. requestData:GetJsonArray("item_mappings"):Remove(2). RUN Invoke. RUN ErrorCode("DISTRIBUTION_MAPPING_INVALID").
RUN Fixture. FIND ttVersionItem WHERE ttVersionItem.item_container_custo_id=72. ttVersionItem.versao_id=6. RUN Invoke. RUN ErrorCode("DISTRIBUTION_MAPPING_INVALID").
RUN Fixture. requestData:GetJsonObject("snapshot"):Set("container_id",999). RUN Invoke. RUN ErrorCode("DISTRIBUTION_SNAPSHOT_INVALID").
RUN Fixture. CREATE ttVersion. ASSIGN ttVersion.versao_id=8 ttVersion.container_id=123 ttVersion.ind_sit_versao=2. RUN Invoke. RUN ErrorCode("DISTRIBUTION_VERSION_CONFLICT").
RUN Fixture. CREATE ttVersion. ASSIGN ttVersion.versao_id=999 ttVersion.container_id=999 ttVersion.ind_sit_versao=2. RUN Invoke.
RUN Check(result:GetLogical("success"),"latest version scoped to this container").
RUN Fixture. policy:Remove("company_policy"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_CONFIGURATION").
RUN Fixture. requestData:Add("company_policy","container_company"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INVALID_REQUEST").
RUN Fixture. policy:Set("allow_version",FALSE). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INVALID_REQUEST").
RUN Fixture. RUN SetFailAfter IN runtime(1). RUN Invoke. RUN ErrorCode("DISTRIBUTION_CALLBACK_FAILED").
RUN Check(NOT CAN-FIND(FIRST ttLedger) AND NOT CAN-FIND(FIRST ttExpense WHERE ttExpense.despesa_id=99),"sequence failure after first effect undoes all").
FIND ttVersionItem WHERE ttVersionItem.item_container_custo_id=71. RUN Check(ttVersionItem.vl_custo_distribuido=0,"sequence failure restores snapshot").
RUN Fixture. policy:Set("gerar_distr_custo",FALSE). RUN Invoke.
RUN Check(result:GetLogical("success"),"global disabled proven zero-entry source behavior").
FOR EACH ttLedger: RUN Check(ttLedger.vl_lancto=0,"global disabled zeroed ledger"). END.
RUN Fixture. RUN Invoke. RUN Invoke. RUN ErrorCode("DISTRIBUTION_ALREADY_APPLIED").
RUN Fixture. FIND ttExpense WHERE ttExpense.despesa_container_id=1. ttExpense.vl_negociado=50.01.
FIND ttVersionItem WHERE ttVersionItem.item_container_custo_id=61. ttVersionItem.vl_custo_distribuido=5.
RUN Invoke.
RUN Check(result:GetLogical("success"),"fractional pool with physical two-place snapshots").
FIND ttVersionItem WHERE ttVersionItem.item_container_custo_id=71.
RUN Check(ttVersionItem.vl_custo_distribuido=0,"tiny residual is not a material snapshot write").
RUN Check(result:GetJsonObject("data"):GetJsonObject("plan"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("snapshot_distribution")=0.0033333333,"raw residual preserved in plan").
RUN Check(result:GetJsonObject("audit"):GetJsonArray("changes"):Length=3,"only material second item produces snapshot movement expense").
RUN Check(INDEX(result:GetJsonObject("data"):GetJsonArray("warnings"):GetJsonText(),"DISTRIBUTION_STORAGE_ROUNDING")>0,"physical scale warning preserved").
/* The same pool after storing both previous physical snapshots stabilizes. */
FIND ttVersion WHERE ttVersion.versao_id=7. ttVersion.ind_sit_versao=2.
CREATE ttVersion. ASSIGN ttVersion.versao_id=8 ttVersion.container_id=123 ttVersion.ind_sit_versao=1.
CREATE ttVersionItem. ASSIGN ttVersionItem.item_container_custo_id=81 ttVersionItem.versao_id=8 ttVersionItem.item_container_id=1.
CREATE ttVersionItem. ASSIGN ttVersionItem.item_container_custo_id=82 ttVersionItem.versao_id=8 ttVersionItem.item_container_id=2.
requestData:Set("version_id",8). requestData:Set("operation","version_check").
requestData:GetJsonArray("item_mappings"):GetJsonObject(1):Set("item_container_custo_id",81).
requestData:GetJsonArray("item_mappings"):GetJsonObject(2):Set("item_container_custo_id",82). RUN Invoke.
RUN Check(result:GetLogical("success") AND NOT result:GetLogical("requiredNewSnapshot"),"subcent residual cannot require third version").
RUN Check(NOT result:Has("audit") AND NOT result:GetLogical("committed"),"stability check remains read only").
OUTPUT TO VALUE("containers-distribuicao-service-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP. OUTPUT CLOSE.
DELETE PROCEDURE runtime.
PROCEDURE Invoke:
 RUN ContainersDistribuicaoService.p(hb[1],hb[2],hb[3],hb[4],hb[5],hb[6],hb[7],hb[8],hb[9],hb[10],hb[11],runtime,policy,requestData,OUTPUT result).
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 checks=checks + 1. IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + c + " result=" + STRING(result:GetJsonText()),1).
END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. RUN Check(NOT result:GetLogical("success") AND NOT result:Has("data"),"error gate " + c). RUN Check(result:GetJsonObject("error"):GetCharacter("code")=c,"structured " + c).
END PROCEDURE.
PROCEDURE Fixture:
 EMPTY TEMP-TABLE ttMaster. EMPTY TEMP-TABLE ttCompany. EMPTY TEMP-TABLE ttStatus. EMPTY TEMP-TABLE ttItem. EMPTY TEMP-TABLE ttPurchase. EMPTY TEMP-TABLE ttLink. EMPTY TEMP-TABLE ttDef. EMPTY TEMP-TABLE ttLedger. EMPTY TEMP-TABLE ttVersionItem. EMPTY TEMP-TABLE ttVersion. EMPTY TEMP-TABLE ttExpense.
 RUN Reset IN runtime.
 CREATE ttMaster. ASSIGN ttMaster.nr-container=123 ttMaster.cod-estabel="501" ttMaster.situacao_container_id=1 ttMaster.log_gerar_distr_custo=TRUE.
 CREATE ttCompany. ASSIGN ttCompany.empresa_id=9 ttCompany.cod_emp_ems2=5.
 CREATE ttStatus. ASSIGN ttStatus.situacao_container_id=1 ttStatus.log_gerar_distr_custo=TRUE.
 CREATE ttItem. ASSIGN ttItem.item_container_id=1 ttItem.container_id=123 ttItem.item_proc_compra_id=11 ttItem.qt_alocada=10 ttItem.qt_confirm_emb=5.
 CREATE ttItem. ASSIGN ttItem.item_container_id=2 ttItem.container_id=123 ttItem.item_proc_compra_id=12 ttItem.qt_alocada=10 ttItem.qt_confirm_emb=10.
 CREATE ttPurchase. ASSIGN ttPurchase.item_proc_compra_id=11 ttPurchase.ind_distr_custo=1 ttPurchase.vl_base_tributacao=6 ttPurchase.vl_negociado=10.
 CREATE ttPurchase. ASSIGN ttPurchase.item_proc_compra_id=12 ttPurchase.ind_distr_custo=1 ttPurchase.vl_base_tributacao=6 ttPurchase.vl_negociado=10.
 CREATE ttLink. ASSIGN ttLink.empresas_despesa_id=1 ttLink.empresa_id=2 ttLink.despesa_id=10 ttLink.log_custo=1.
 CREATE ttLink. ASSIGN ttLink.empresas_despesa_id=2 ttLink.empresa_id=2 ttLink.despesa_id=11 ttLink.log_custo=1.
 CREATE ttDef. ttDef.despesa_id=10. CREATE ttDef. ttDef.despesa_id=11. CREATE ttDef. ttDef.despesa_id=99.
 CREATE ttVersion. ASSIGN ttVersion.versao_id=6 ttVersion.container_id=123 ttVersion.ind_sit_versao=2.
 CREATE ttVersion. ASSIGN ttVersion.versao_id=7 ttVersion.container_id=123 ttVersion.ind_sit_versao=1.
 CREATE ttVersionItem. ASSIGN ttVersionItem.item_container_custo_id=61 ttVersionItem.versao_id=6 ttVersionItem.item_container_id=1 ttVersionItem.vl_custo_distribuido=2.
 CREATE ttVersionItem. ASSIGN ttVersionItem.item_container_custo_id=71 ttVersionItem.versao_id=7 ttVersionItem.item_container_id=1.
 CREATE ttVersionItem. ASSIGN ttVersionItem.item_container_custo_id=72 ttVersionItem.versao_id=7 ttVersionItem.item_container_id=2.
 CREATE ttExpense. ASSIGN ttExpense.despesa_container_id=1 ttExpense.container_id=123 ttExpense.despesa_id=10 ttExpense.vl_prev=50 ttExpense.vl_negociado=95.
 CREATE ttExpense. ASSIGN ttExpense.despesa_container_id=2 ttExpense.container_id=123 ttExpense.despesa_id=11 ttExpense.item_container_id=1 ttExpense.vl_prev=10 ttExpense.vl_negociado=15.
 policy=NEW JsonObject(). policy:Add("company_policy","legacy_company_2"). policy:Add("gerar_distr_custo",TRUE). policy:Add("despesa_distr_custo",99). policy:Add("allow_nested",TRUE). policy:Add("allow_version",TRUE).
 o=NEW JsonObject(). o:Add("login","actor-test"). policy:Add("actor",o).
 requestData=NEW JsonObject(). requestData:Add("operation","version"). requestData:Add("container_id",123). requestData:Add("version_id",7).
 a=NEW JsonArray(). o=NEW JsonObject(). o:Add("item_container_id",1). o:Add("item_container_custo_id",71). a:Add(o).
 o=NEW JsonObject(). o:Add("item_container_id",2). o:Add("item_container_custo_id",72). a:Add(o). requestData:Add("item_mappings",a).
 snapshotData=NEW JsonObject(). snapshotData:Add("confirmed",TRUE). snapshotData:Add("container_id",123). snapshotData:Add("actual_complete",FALSE). requestData:Add("snapshot",snapshotData).
END PROCEDURE.
