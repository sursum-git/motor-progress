PROCEDURE GetVersionContext:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO.
 DEFINE OUTPUT PARAMETER contextValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE distributionValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE globalValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE expenseId AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTEXT_TRANSACTION_REQUIRED",1).
 IF NOT VALID-HANDLE(master) THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTEXT_PARENT_REQUIRED",1).
 IF NOT master:AVAILABLE THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTEXT_PARENT_REQUIRED",1).
 cid=master:BUFFER-FIELD("nr-container"):BUFFER-VALUE.
 IF cid=? OR cid<=0 THEN UNDO, THROW NEW Progress.Lang.AppError("VERSION_CONTEXT_PARENT_REQUIRED",1).
 contextValue=NEW JsonObject(). contextValue:Add("confirmed",TRUE). contextValue:Add("container_id",cid).
 /* Functions use the official include on every invocation; no retained policy. */
 contextValue:Add("cost_policy",ContainerCustoPolicy()). contextValue:Add("finance_policy",ContainerFinancePolicy()).
 distributionValue=NEW JsonObject(). globalValue=getParamDistrCusto().
 IF globalValue="0" OR globalValue="1" THEN distributionValue:Add("gerar_distr_custo",globalValue="1").
 ELSE distributionValue:AddNull("gerar_distr_custo").
 expenseId=CustoInteger(buscarParametroIma("despesa_distr_custo",""),FALSE).
 IF expenseId=? THEN distributionValue:AddNull("despesa_distr_custo"). ELSE distributionValue:Add("despesa_distr_custo",expenseId).
 /* Unknown private distribution fields only reject an activated distribution;
    unrelated version capture keeps its existing contract. Company is fixed by Runtime. */
 contextValue:Add("distribution_policy",distributionValue).
END PROCEDURE.
