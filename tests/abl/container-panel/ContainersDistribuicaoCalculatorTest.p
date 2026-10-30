BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE inputData AS JsonObject NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE item AS JsonObject NO-UNDO.
DEFINE VARIABLE row AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE beforeText AS LONGCHAR NO-UNDO.
DEFINE TEMP-TABLE ttCase FIELD id AS INTEGER FIELD previous AS DECIMAL DECIMALS 10 INDEX pk IS PRIMARY UNIQUE id.
FUNCTION HasWarning RETURNS LOGICAL (c AS CHARACTER) FORWARD.
RUN Fixture. beforeText=inputData:GetJsonText(). RUN Invoke.
RUN Check(result:GetLogical("success"),"confirmed central distribution").
RUN Check(beforeText=inputData:GetJsonText(),"no mutation of confirmed inputs").
row=result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Equal(row:GetDecimal("snapshot_distribution"),18,"general share plus exclusive minus all history").
RUN Equal(row:GetDecimal("ledger_amount"),18,"ledger round2").
RUN Equal(result:GetJsonObject("data"):GetDecimal("expense_pool"),45,"legacy literal company2 pool").
RUN Equal(row:GetJsonObject("memory"):GetDecimal("weight"),20,"confirmed negotiated less tributary products").
RUN Check(result:GetJsonObject("data"):GetLogical("requiredNewSnapshot"),"any item contribution requires new snapshot").
RUN Fixture. inputData:Set("company_policy","container_company"). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetDecimal("expense_pool"),90,"explicit container company pool").
RUN Check(HasWarning("DISTRIBUTION_COMPANY_POLICY"),"private company origin disclosed").
RUN Fixture. item:Set("qt_confirm_emb",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetJsonObject("memory"):GetDecimal("weight"),40,"allocated fallback when confirmed tributary product zero").
RUN Fixture. item:Set("vl_base_tributacao",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetJsonObject("memory"):GetDecimal("weight"),100,"product-zero fallback even positive shipped quantity").
RUN Fixture. item:Set("ind_distr_custo",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("snapshot_distribution"),3,"excluded weight still retains exclusive delta and history").
RUN Fixture. item:Set("vl_negociado",5). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetJsonObject("memory"):GetDecimal("weight"),0,"negative margin clamps weight to zero").
RUN Fixture. inputData:GetJsonArray("expenses"):GetJsonObject(1):Set("vl_negociado",40). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetDecimal("expense_pool"),0,"negotiated below forecast omitted").
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("snapshot_distribution"),3,"exclusive-only with no pool avoids denominator").
RUN Fixture. inputData:GetJsonArray("expenses"):GetJsonObject(1):Set("vl_prev",-10). inputData:GetJsonArray("expenses"):GetJsonObject(1):Set("vl_negociado",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetDecimal("expense_pool"),0,"negotiated zero excluded even above negative forecast").
RUN Fixture. inputData:Set("container_enabled",FALSE). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("snapshot_distribution"),0,"master gate disabled snapshot distribution zero").
RUN Check(NOT result:GetJsonObject("data"):GetLogical("requiredNewSnapshot"),"disabled master no recursive request").
RUN Fixture. inputData:Set("status_enabled",FALSE). RUN Invoke.
RUN Check(NOT result:GetJsonObject("data"):GetLogical("requiredNewSnapshot"),"status gate also required").
RUN Fixture. inputData:Set("global_enabled",FALSE). RUN Invoke.
row=result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Equal(row:GetDecimal("snapshot_distribution"),18,"global gate does not erase snapshot delta").
RUN Equal(row:GetDecimal("ledger_amount"),0,"global IMA gate explicitly zeroes entry").
RUN Check(row:GetLogical("emit_entry") AND HasWarning("DISTRIBUTION_GLOBAL_DISABLED"),"zero entry source branch explicit").
RUN Fixture. item:Set("previous_distribution",20). inputData:GetJsonArray("items"):GetJsonObject(2):Set("previous_distribution",30). RUN Invoke.
RUN Check(NOT result:GetJsonObject("data"):GetLogical("requiredNewSnapshot"),"fully distributed history stabilizes").
RUN Fixture. inputData:GetJsonArray("items"):GetJsonObject(2):Set("previous_distribution",30). RUN Invoke.
RUN Check(result:GetJsonObject("data"):GetLogical("requiredNewSnapshot"),"nonzero first item survives final zero item").
RUN Fixture. inputData:GetJsonArray("expenses"):GetJsonObject(1):Set("vl_negociado",50.01). item:Set("previous_distribution",5). RUN Invoke.
row=result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1).
RUN Equal(row:GetDecimal("snapshot_distribution"),0.0033333333,"snapshot retains ten decimal fraction").
RUN Equal(row:GetDecimal("snapshot_persisted_distribution"),0,"physical snapshot rounds according to DECIMALS2 dictionary").
RUN Equal(row:GetDecimal("ledger_amount"),0,"subcent snapshot remains distinct from ledger").
RUN Check(NOT row:GetLogical("emit_entry"),"subcent delta no entry").
RUN Fixture. item:Set("previous_distribution",20.005). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetJsonArray("items"):GetJsonObject(1):GetDecimal("ledger_amount"),-0.01,"negative half rounds away from zero").
RUN Fixture. item:Set("ind_distr_custo",0). inputData:GetJsonArray("items"):GetJsonObject(2):Set("ind_distr_custo",0). RUN Invoke. RUN ErrorCode("DISTRIBUTION_ZERO_WEIGHT").
RUN Fixture. item:SetNull("vl_negociado"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. item:Set("vl_negociado","50,00"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. inputData:Set("company_policy",""). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. inputData:Remove("company_policy"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. inputData:Set("confirmed",FALSE). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. inputData:Set("global_enabled","false"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. inputData:Add("Company_policy","legacy_company_2"). RUN Invoke. RUN ErrorCode("DISTRIBUTION_INPUT_INVALID").
RUN Fixture. inputData:GetJsonArray("items"):Add(CAST(item:Clone(),JsonObject)). RUN Invoke. RUN ErrorCode("DISTRIBUTION_ITEM_DUPLICATE").
RUN Fixture. inputData:GetJsonArray("company_links"):Add(CAST(inputData:GetJsonArray("company_links"):GetJsonObject(1):Clone(),JsonObject)). RUN Invoke. RUN ErrorCode("DISTRIBUTION_LINK_AMBIGUOUS").
RUN Fixture. inputData:GetJsonArray("expenses"):GetJsonObject(2):Set("item_container_id",99). RUN Invoke. RUN ErrorCode("DISTRIBUTION_ITEM_UNKNOWN").
RUN Fixture. inputData:GetJsonArray("expenses"):Add(CAST(inputData:GetJsonArray("expenses"):GetJsonObject(1):Clone(),JsonObject)). RUN Invoke. RUN ErrorCode("DISTRIBUTION_EXPENSE_DUPLICATE").
RUN Fixture. inputData:GetJsonArray("company_links"):GetJsonObject(1):Set("log_custo",0). RUN Invoke.
RUN Equal(result:GetJsonObject("data"):GetDecimal("expense_pool"),0,"non-cost company link excluded").
/* TT iteration catches accidental last-row boolean overwrite. */
CREATE ttCase. ASSIGN ttCase.id=1 ttCase.previous=2.
CREATE ttCase. ASSIGN ttCase.id=2 ttCase.previous=30.
RUN Fixture.
FOR EACH ttCase BY ttCase.id: inputData:GetJsonArray("items"):GetJsonObject(ttCase.id):Set("previous_distribution",ttCase.previous). END.
RUN Invoke. RUN Check(result:GetJsonObject("data"):GetLogical("requiredNewSnapshot"),"multi-row TT OR aggregate").
OUTPUT TO VALUE("containers-distribuicao-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP. OUTPUT CLOSE.
PROCEDURE Invoke: RUN ContainersDistribuicaoCalculator.p(inputData,OUTPUT result). END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER l AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 checks=checks + 1. IF l<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL " + c + " result=" + STRING(result:GetJsonText()),1).
END PROCEDURE.
PROCEDURE Equal:
 DEFINE INPUT PARAMETER actual AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE INPUT PARAMETER expected AS DECIMAL DECIMALS 10 NO-UNDO. DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. RUN Check(actual=expected,c).
END PROCEDURE.
PROCEDURE ErrorCode:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO. RUN Check(NOT result:GetLogical("success") AND NOT result:Has("data"),"fail closed " + c). RUN Check(result:GetJsonObject("error"):GetCharacter("code")=c,"structured " + c).
END PROCEDURE.
FUNCTION HasWarning RETURNS LOGICAL (c AS CHARACTER):
 DEFINE VARIABLE j AS INTEGER NO-UNDO. DEFINE VARIABLE a AS JsonArray NO-UNDO.
 a=result:GetJsonObject("data"):GetJsonArray("warnings"). DO j=1 TO a:Length: IF a:GetJsonObject(j):GetCharacter("code")=c THEN RETURN TRUE. END. RETURN FALSE.
END FUNCTION.
PROCEDURE Fixture:
 DEFINE VARIABLE lc AS LONGCHAR NO-UNDO.
 IF NOT VALID-OBJECT(parser) THEN parser=NEW ObjectModelParser().
 lc='~{"confirmed":true,"source":"distribution-inputs-v1","container_id":123,"container_company_id":9,"company_policy":"legacy_company_2","global_enabled":true,"container_enabled":true,"status_enabled":true,"items":[~{"item_container_id":1,"item_proc_compra_id":11,"ind_distr_custo":1,"qt_alocada":10,"qt_confirm_emb":5,"vl_base_tributacao":6,"vl_negociado":10,"previous_distribution":2},~{"item_container_id":2,"item_proc_compra_id":12,"ind_distr_custo":1,"qt_alocada":10,"qt_confirm_emb":10,"vl_base_tributacao":6,"vl_negociado":10,"previous_distribution":0}],"expenses":[~{"despesa_container_id":1,"despesa_id":10,"item_container_id":0,"vl_prev":50,"vl_negociado":95},~{"despesa_container_id":2,"despesa_id":11,"item_container_id":1,"vl_prev":10,"vl_negociado":15},~{"despesa_container_id":3,"despesa_id":12,"item_container_id":0,"vl_prev":10,"vl_negociado":100}],"company_links":[~{"empresa_id":2,"despesa_id":10,"log_custo":1},~{"empresa_id":2,"despesa_id":11,"log_custo":1},~{"empresa_id":9,"despesa_id":12,"log_custo":1}]}'.
 inputData=CAST(parser:Parse(lc),JsonObject). item=inputData:GetJsonArray("items"):GetJsonObject(1).
END PROCEDURE.
