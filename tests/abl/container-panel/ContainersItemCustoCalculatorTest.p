/* Pure fixture data includes multiple real temp-table items for error gating. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE inputData AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE item AS JsonObject NO-UNDO.
DEFINE VARIABLE row AS JsonObject NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE inputBefore AS LONGCHAR NO-UNDO.
DEFINE TEMP-TABLE ttCases FIELD id AS INTEGER FIELD erp AS CHARACTER FIELD missingVersion AS LOGICAL FIELD missingPrevious AS LOGICAL INDEX pk IS PRIMARY UNIQUE id.
FUNCTION HasWarning RETURNS LOGICAL (code AS CHARACTER) FORWARD.
RUN Fixture. inputBefore=inputData:GetJsonText(). RUN Invoke.
RUN Check(result:GetLogical("success"),"confirmed weighted final cost").
RUN Check(inputBefore=inputData:GetJsonText(),"pure calculation leaves confirmed input unchanged").
row=result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Equal(row:GetDecimal("vl_unit_novo"),18.89,"weighted average rounds2").
RUN Equal(row:GetDecimal("qt_saldo_estoq_atu"),120,"IMA and MED stock summed").
RUN Equal(row:GetDecimal("qt_saldo_estoq"),100,"mother labels subtracted from stock").
RUN Equal(row:GetDecimal("qt_diferenca"),70,"label difference uses both current and other containers").
RUN Equal(row:GetDecimal("qt_restante"),30,"other-container labels retained separately").
RUN Equal(row:GetDecimal("qt_container"),80,"shipped quantity preferred over allocated").
RUN Equal(row:GetDecimal("qt_nota_mae"),80,"mother quantity is snapshot shipped quantity, not label count").
RUN Equal(row:GetDecimal("vl_unit_container"),30,"released realized cost selected").
inputData:GetJsonObject("policy"):Set("log_priorizar_custo_previsto",TRUE). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo"),14.44,"explicit prioritize uses forecast").
RUN Fixture. inputData:GetJsonObject("policy"):Set("log_liberar_custo_realizado",FALSE). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_container"),20,"unreleased realized cost uses forecast").
RUN Fixture. item:GetJsonObject("version_cost"):Set("vl_unit_realiz",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_container"),20,"realized zero explicit fallback to forecast").
RUN Fixture. inputData:GetJsonObject("policy"):Set("log_liberar_custo_realizado",FALSE). item:GetJsonObject("version_cost"):SetNull("vl_unit_realiz"). RUN Invoke.
RUN Check(result:GetLogical("success"),"unreleased forecast does not invent or require unused actual cost").
RUN Fixture. item:GetJsonObject("version_cost"):SetNull("vl_unit_prev"). item:GetJsonObject("version_cost"):SetNull("qt_alocada"). item:GetJsonObject("version_cost"):SetNull("qt_recebto_fisico"). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo"),18.89,"unused forecast allocated and received values may remain null").
RUN Check(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetJsonObject("memory"):IsNull("qt_recebto_fisico_unused"),"unused received quantity remains explicitly null").
RUN Fixture. item:GetJsonObject("version_cost"):Set("qt_confirm_emb",0). item:GetJsonObject("version_cost"):SetNull("qt_alocada"). RUN Invoke. RUN ErrorPresent("ITEM_DATA_INVALID").
RUN Fixture. item:GetJsonObject("version_cost"):SetNull("vl_unit_realiz"). RUN Invoke. RUN ErrorPresent("ITEM_DATA_INVALID").
RUN Fixture. item:Set("movimentos_med",NEW JsonArray()). item:SetNull("previous_cost"). item:GetJsonObject("version_cost"):Set("vl_unit_realiz",30.1234567891). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo"),30.1234567891,"no historical movement uses container unit without ROUND2").
RUN Check(HasWarning("PREVIOUS_COST_ABSENCE_ALLOWED"),"legitimate absent prior cost is disclosed").
RUN Fixture. item:GetJsonArray("movimentos_med"):GetJsonObject(1):Set("dt_trans","2026-10-01"). item:GetJsonArray("movimentos_med"):GetJsonObject(2):Set("dt_trans","2026-10-02"). item:SetNull("previous_cost"). RUN Invoke.
RUN Check(result:GetLogical("success"),"same-date and later MED movements do not count as prior").
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo"),30,"strict date cutoff produces direct unit override").
RUN Fixture. item:GetJsonArray("movimentos_med"):GetJsonObject(2):Set("quantidade",100). item:SetNull("previous_cost"). RUN Invoke.
RUN Check(result:GetLogical("success"),"zero historical balance permits absent previous cost by explicit source condition").
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo"),13.33,"historical zero balance still uses weighted branch").
RUN Fixture. inputData:Set("nfs",NEW JsonArray()). RUN Invoke.
RUN Check(result:GetLogical("success"),"version not requiring mother allows confirmed absence").
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("qt_saldo_estoq"),120,"no mother does not subtract labels").
RUN Check(HasWarning("MOTHER_DATE_LEGACY_DEFAULT"),"2001 cutoff has explicit legacy origin warning").
inputData:GetJsonObject("version"):Set("tipo_versao_id",4). RUN Invoke. RUN ErrorPresent("MOTHER_NF_REQUIRED").
inputData:GetJsonObject("version"):Set("tipo_versao_id",14). RUN Invoke. RUN Check(result:GetLogical("success"),"version type membership is exact, not substring").
RUN Fixture. item:GetJsonObject("version_cost"):Set("qt_confirm_emb",0). RUN Invoke.
row=result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Equal(row:GetDecimal("qt_container"),100,"allocated quantity fallback"). RUN Equal(row:GetDecimal("qt_nota_mae"),0,"unshipped mother quantity is zero per legacy").
RUN Fixture. item:GetJsonObject("stock"):Set("ima",-100). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("qt_saldo_estoq"),0,"mother-adjusted negative stock clamps to zero").
RUN Fixture. item:GetJsonObject("stock"):Set("ima",0). item:GetJsonObject("stock"):Set("med",0). item:Set("etiquetas",NEW JsonArray()).
item:GetJsonObject("version_cost"):Set("qt_confirm_emb",0). item:GetJsonObject("version_cost"):Set("qt_alocada",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("vl_unit_novo"),0,"explicit nonpositive formula branch yields zero").
RUN Check(HasWarning("LEGACY_NONPOSITIVE_RESULT"),"zero formula branch is disclosed, never mistaken for missing data").
RUN Fixture. rows=inputData:GetJsonArray("nfs"). row=CAST(rows:GetJsonObject(1):Clone(),JsonObject). row:Set("documento","NF2"). row:Set("dt_emis_nota","2026-10-02"). rows:Add(row). RUN Invoke. RUN ErrorPresent("MOTHER_DATE_AMBIGUOUS").
RUN Fixture. rows=inputData:GetJsonArray("nfs"). row=CAST(rows:GetJsonObject(1):Clone(),JsonObject). row:Set("documento","NF2"). rows:Add(row). RUN Invoke.
RUN Check(result:GetLogical("success") AND HasWarning("MULTIPLE_MOTHER_SAME_DATE"),"identical mother cutoff accepted and disclosed").
RUN Fixture. item:SetNull("previous_cost"). RUN Invoke. RUN ErrorPresent("PREVIOUS_COST_REQUIRED").
RUN Fixture. item:GetJsonObject("stock"):SetNull("med"). RUN Invoke. RUN ErrorPresent("ITEM_DATA_INVALID").
RUN Fixture. item:GetJsonObject("version_cost"):Set("versao_id",99). RUN Invoke. RUN ErrorPresent("VERSION_ITEM_MISMATCH").
RUN Fixture. inputData:GetJsonObject("version"):Set("log_versao_custo_desatualizada",TRUE). RUN Invoke. RUN ErrorPresent("STALE_VERSION").
RUN Fixture. inputData:GetJsonObject("policy"):Set("log_priorizar_custo_previsto","false"). RUN Invoke. RUN ErrorPresent("INPUT_INVALID").
RUN Fixture. item:GetJsonObject("stock"):Set("med","70,0"). RUN Invoke. RUN ErrorPresent("ITEM_DATA_INVALID").
RUN Fixture. item:GetJsonArray("movimentos_med"):GetJsonObject(1):Set("dt_trans","2026-02-30"). RUN Invoke. RUN ErrorPresent("ITEM_DATA_INVALID").
RUN Fixture. inputData:GetJsonArray("nfs"):GetJsonObject(1):Set("dt_emis_nota","0099-01-01"). RUN Invoke.
IF result:GetLogical("success") THEN RUN Check(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetJsonObject("memory"):GetCharacter("reference_date")="0099-01-01","ISO century is never silently expanded").
ELSE RUN ErrorPresent("INPUT_INVALID").
RUN Fixture. inputData:Add("qt_erros",0). RUN Invoke. RUN ErrorPresent("INPUT_INVALID").

/* DB-like TT iteration proves all items are collected, including final row. */
RUN SeedCases. RUN Fixture. rows=NEW JsonArray().
FOR EACH ttCases BY ttCases.id:
 row=CAST(item:Clone(),JsonObject). row:Set("item_container_id",ttCases.id). row:Set("it_codigo",ttCases.erp).
 row:GetJsonObject("version_cost"):Set("item_container_id",ttCases.id).
 IF ttCases.missingVersion THEN row:SetNull("version_cost").
 IF ttCases.missingPrevious THEN row:SetNull("previous_cost").
 rows:Add(row).
END.
inputData:Set("items",rows). RUN Invoke.
RUN Check(NOT result:GetLogical("success") AND NOT result:Has("data"),"all-item gate has no partial writable data").
RUN Check(result:GetJsonObject("error"):GetJsonArray("items"):Length=2,"both invalid items including final group reported").
RUN ErrorPresent("ERP_CODE_MISSING"). RUN ErrorPresent("VERSION_ITEM_MISSING"). RUN ErrorPresent("PREVIOUS_COST_REQUIRED").
RUN Fixture. row=CAST(item:Clone(),JsonObject). row:Set("item_container_id",2). row:GetJsonObject("version_cost"):Set("item_container_id",2). inputData:GetJsonArray("items"):Add(row). RUN Invoke. RUN ErrorPresent("VERSION_COST_ID_DUPLICATE").
row:GetJsonObject("version_cost"):Set("item_container_custo_id",9). RUN Invoke.
RUN Check(result:GetLogical("success") AND result:GetJsonObject("data"):GetJsonArray("items"):Length=2,"complete valid multi-item set calculates both rows").
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(2):GetDecimal("vl_unit_novo"),18.89,"final valid item retains its own result").
RUN Fixture. inputData:GetJsonArray("items"):Add(CAST(item:Clone(),JsonObject)). RUN Invoke. RUN ErrorPresent("ITEM_ID_DUPLICATE").
DELETE OBJECT parser.
OUTPUT TO VALUE("containers-item-custo-tests-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP. OUTPUT CLOSE.

FUNCTION HasWarning RETURNS LOGICAL (code AS CHARACTER):
 DEFINE VARIABLE a AS JsonArray NO-UNDO. DEFINE VARIABLE j AS INTEGER NO-UNDO.
 a=result:GetJsonObject("data"):GetJsonArray("warnings"). DO j=1 TO a:Length: IF a:GetJsonObject(j):GetCharacter("code")=code THEN RETURN TRUE. END. RETURN FALSE.
END FUNCTION.
PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 checks=checks + 1. IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + c + " result=" + STRING(result:GetJsonText()),1).
END PROCEDURE.
PROCEDURE Equal:
 DEFINE INPUT PARAMETER actual AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE INPUT PARAMETER expected AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 RUN Check(actual=expected,messageText).
END PROCEDURE.
PROCEDURE ErrorPresent:
 DEFINE INPUT PARAMETER code AS CHARACTER NO-UNDO.
 DEFINE VARIABLE textJson AS LONGCHAR NO-UNDO.
 RUN Check(NOT result:GetLogical("success") AND NOT result:Has("data"),"error gate " + code).
 textJson=result:GetJsonObject("error"):GetJsonText(). RUN Check(INDEX(textJson,CHR(34) + code + CHR(34))>0,"structured error " + code).
END PROCEDURE.
PROCEDURE Invoke:
 RUN ContainersItemCustoCalculator.p(inputData,OUTPUT result).
END PROCEDURE.
PROCEDURE SeedCases:
 EMPTY TEMP-TABLE ttCases.
 CREATE ttCases. ASSIGN ttCases.id=1 ttCases.erp="" ttCases.missingVersion=TRUE.
 CREATE ttCases. ASSIGN ttCases.id=2 ttCases.erp="ERP2" ttCases.missingPrevious=TRUE.
END PROCEDURE.
PROCEDURE Fixture:
 DEFINE VARIABLE lc AS LONGCHAR NO-UNDO.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 lc='~{"confirmed":true,"source":"item-cost-inputs-v1","container_id":123,"policy":~{"log_liberar_custo_realizado":true,"log_priorizar_custo_previsto":false,"tipo_versao_valida_nf":[4,5]},"version":~{"versao_id":7,"tipo_versao_id":2,"log_versao_custo_desatualizada":false},"nfs":[~{"documento":"NF1","serie":"A","estab":"501","nat_operacao":"3102","cod_emitente":10,"dt_emis_nota":"2026-10-01"}],"items":[~{"item_container_id":1,"item_proc_compra_id":11,"it_codigo":"ERP1","previous_cost":~{"item_custo_id":3,"vl_unit_novo":10},"version_cost":~{"item_container_custo_id":8,"versao_id":7,"item_container_id":1,"vl_unit_prev":20,"vl_unit_realiz":30,"qt_alocada":100,"qt_confirm_emb":80,"qt_recebto_fisico":0},"stock":~{"ima":50,"med":70},"movimentos_med":[~{"dt_trans":"2026-09-01","tipo_trans":1,"quantidade":100},~{"dt_trans":"2026-09-02","tipo_trans":2,"quantidade":20}],"etiquetas":[~{"nr_container":123,"situacao":3,"quantidade":20},~{"nr_container":999,"situacao":4,"quantidade":30},~{"nr_container":123,"situacao":2,"quantidade":999}]}]}'.
 inputData=CAST(parser:Parse(lc),JsonObject). item=inputData:GetJsonArray("items"):GetJsonObject(1).
END PROCEDURE.
