/* IMA include tested over TT. No business database. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttParam NO-UNDO FIELD cod-param AS CHARACTER FIELD val-param AS CHARACTER INDEX pk IS PRIMARY UNIQUE cod-param.
DEFINE TEMP-TABLE ttMaster NO-UNDO FIELD nr-container AS INTEGER.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA ttParam
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerFinancePolicy.i}
CREATE ttMaster. ttMaster.nr-container=123. RELEASE ttMaster.
RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue) NO-ERROR.
RUN Check(ERROR-STATUS:ERROR,"no private policy before parent transaction").
DO TRANSACTION:
 FIND FIRST ttMaster EXCLUSIVE-LOCK.
 CREATE ttParam. ASSIGN ttParam.cod-param="NAT-OPERACAO-IMP" ttParam.val-param="31201M,31206". RELEASE ttParam.
 RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue).
 RUN Check(resultValue:GetLogical("confirmed") AND resultValue:GetInteger("container_id")=123,"context bound to physical parent").
 RUN Check(resultValue:GetJsonObject("cost_policy"):GetCharacter("naturezas_nota_mae")="31201M,31206","official import naturezas accessor reused").
 FIND FIRST ttParam WHERE ttParam.cod-param="NAT-OPERACAO-IMP". ttParam.val-param="31207". RELEASE ttParam.
 RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue).
 RUN Check(resultValue:GetJsonObject("cost_policy"):GetCharacter("naturezas_nota_mae")="31207","next callback sees changed IMA value without cache").
 FIND FIRST ttParam WHERE ttParam.cod-param="NAT-OPERACAO-IMP". DELETE ttParam.
 RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue).
 RUN Check(resultValue:GetJsonObject("cost_policy"):GetCharacter("naturezas_nota_mae")="","missing naturezas remains empty, no invented default").
 RUN Check(NOT resultValue:GetJsonObject("finance_policy"):Has("capture_rows"),"context does not expose internal row flag").
 RUN Check(resultValue:Has("distribution_policy"),"private distribution policy accompanies captured context").
 RUN Check(resultValue:GetJsonObject("distribution_policy"):IsNull("despesa_distr_custo"),"missing managed expense remains unknown until distribution is requested").
 CREATE ttParam. ASSIGN ttParam.cod-param="gerar_distr_custo" ttParam.val-param="1". RELEASE ttParam.
 CREATE ttParam. ASSIGN ttParam.cod-param="despesa_distr_custo" ttParam.val-param="99". RELEASE ttParam.
 RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue).
 RUN Check(resultValue:GetJsonObject("distribution_policy"):GetLogical("gerar_distr_custo") AND resultValue:GetJsonObject("distribution_policy"):GetInteger("despesa_distr_custo")=99,"distribution parameters read privately from official include").
 FIND FIRST ttParam WHERE ttParam.cod-param="despesa_distr_custo". ttParam.val-param="100". RELEASE ttParam.
 RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue).
 RUN Check(resultValue:GetJsonObject("distribution_policy"):GetInteger("despesa_distr_custo")=100,"managed expense policy has no cache").
 FIND FIRST ttParam WHERE ttParam.cod-param="gerar_distr_custo". ttParam.val-param="true". RELEASE ttParam.
 RUN GetVersionContext(INPUT BUFFER ttMaster:HANDLE,OUTPUT resultValue).
 RUN Check(resultValue:GetJsonObject("distribution_policy"):IsNull("gerar_distr_custo"),"invalid flag is unknown rather than silently enabled").
END.
OUTPUT TO VALUE("containers-version-context-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks; official IMA include, TT only." SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue,1).
 checks=checks + 1.
END PROCEDURE.
{ContainersVersionContextBody.i}

