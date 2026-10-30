/* Request and direct IMA policy contract. TT only, no database or sequence. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttParam NO-UNDO FIELD cod-param AS CHARACTER FIELD val-param AS CHARACTER INDEX pk IS UNIQUE PRIMARY cod-param.
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE types AS JsonArray NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE cid AS INTEGER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA ttParam
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
{sursum-api/includes/ContainerMaintenancePolicy.i}
{sursum-api/includes/ContainerProcessBoundary.i}
parser=NEW ObjectModelParser().
requestValue=CAST(parser:Parse('~{"resource":"versoes","operation":"gerar","container_id":123,"tipo_versao_id":1,"descricao":"TT","expected_latest_version_id":0}'),JsonObject).
cid=ContainerProcessRequest(requestValue). RUN Check(cid=123,"generation accepts first version expectation zero").
requestValue:Add("actor","forged"). RUN RejectRequest. requestValue:Remove("actor").
requestValue:Add("policy",NEW JsonObject()). RUN RejectRequest. requestValue:Remove("policy").
requestValue:Add("database","espec"). RUN RejectRequest. requestValue:Remove("database").
requestValue:Set("operation","consultar"). RUN RejectRequest.
requestValue:Set("operation","excluir_incompleta"). RUN RejectRequest.
requestValue:Set("operation","gerar"). requestValue:Set("container_id","123"). RUN RejectRequest.
requestValue:Set("container_id",123.5). RUN RejectRequest.
requestValue:Set("container_id",123). requestValue:Set("expected_latest_version_id",-1). RUN RejectRequest.
requestValue:Set("expected_latest_version_id",0). requestValue:Set("descricao",""). RUN RejectRequest.
requestValue=CAST(parser:Parse('~{"resource":"custos","operation":"fechar","container_id":123,"versao_id":7,"expected_latest_version_id":7,"log_priorizar_custo_previsto":false}'),JsonObject).
RUN Check(ContainerProcessRequest(requestValue)=123,"close accepts explicit preference").
requestValue:Remove("log_priorizar_custo_previsto"). RUN RejectRequest. requestValue:Add("log_priorizar_custo_previsto",0). RUN RejectRequest.
requestValue:Set("log_priorizar_custo_previsto",FALSE). requestValue:Set("expected_latest_version_id",0). RUN RejectRequest.
requestValue=CAST(parser:Parse('~{"resource":"impostos","operation":"sincronizar","container_id":123,"request_id":"TT"}'),JsonObject).
RUN Check(ContainerProcessRequest(requestValue)=123,"explicit synchronize command").
requestValue:Add("tipo_versao_id",1). RUN RejectRequest.
requestValue=CAST(parser:Parse('~{"resource":"nfs","operation":"associar","container_id":123,"expected_nf_stamp":"sha","nfs":[~{"documento":"100","serie":"A","estab":"5","nat_operacao":"31201","cod_emitente":77}]}'),JsonObject).
RUN Check(ContainerProcessRequest(requestValue)=123,"NF association accepts complete immutable key").
requestValue:GetJsonArray("nfs"):GetJsonObject(1):Remove("nat_operacao"). RUN RejectRequest.
requestValue=CAST(parser:Parse('~{"resource":"nfs","operation":"desassociar","container_id":123,"expected_nf_stamp":"sha","nfs":[~{"documento":"100","serie":"A","estab":"5","nat_operacao":"31201","cod_emitente":77}]}'),JsonObject).
RUN Check(ContainerProcessRequest(requestValue)=123,"NF disassociation accepts complete immutable key").
policyValue=ContainerMaintenancePolicy("TT"). RUN Check(policyValue:GetInteger("despesa_distr_custo")=0,"absent distribution expense keeps legacy zero").
CREATE ttParam. ASSIGN ttParam.cod-param="despesa_distr_custo" ttParam.val-param="99". RELEASE ttParam.
policyValue=ContainerMaintenancePolicy("TT"). RUN Check(policyValue:GetInteger("despesa_distr_custo")=99,"managed expense direct read").
FIND FIRST ttParam. ttParam.val-param="100". RELEASE ttParam.
policyValue=ContainerMaintenancePolicy("TT"). RUN Check(policyValue:GetInteger("despesa_distr_custo")=100,"next call sees parameter change without cache").
FIND FIRST ttParam. ttParam.val-param="1.5". RELEASE ttParam.
RUN InvalidPolicy.
FIND FIRST ttParam. ttParam.val-param="2147483648". RELEASE ttParam. RUN InvalidPolicy.
FIND FIRST ttParam. DELETE ttParam.
types=ContainerCloseTypes(). RUN Check(types:Length=2 AND types:GetInteger(1)=4 AND types:GetInteger(2)=5,"documented type defaults").
CREATE ttParam. ASSIGN ttParam.cod-param="tipo_versao_valida_nf" ttParam.val-param="2,7". RELEASE ttParam.
types=ContainerCloseTypes(). RUN Check(types:GetInteger(1)=2 AND types:GetInteger(2)=7,"close types read direct IMA").
FIND FIRST ttParam. ttParam.val-param="2,2". RELEASE ttParam. RUN InvalidTypes.
FIND FIRST ttParam. ttParam.val-param="2,7.5". RELEASE ttParam. RUN InvalidTypes.
OUTPUT TO VALUE("containers-process-boundary-tests-" + SESSION:NUMERIC-FORMAT + ".log"). PUT UNFORMATTED "PASS " checks " checks" SKIP. OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO. DEFINE INPUT PARAMETER messageValue AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL: " + messageValue,1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE RejectRequest:
 DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
 DO ON ERROR UNDO, THROW: cid=ContainerProcessRequest(requestValue). CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH. END.
 RUN Check(rejected,"request must reject unsupported external input").
END PROCEDURE.
PROCEDURE InvalidPolicy:
 DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
 DO ON ERROR UNDO, THROW: policyValue=ContainerMaintenancePolicy("TT"). CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH. END.
 RUN Check(rejected,"private policy rejects malformed managed expense").
END PROCEDURE.
PROCEDURE InvalidTypes:
 DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
 DO ON ERROR UNDO, THROW: types=ContainerCloseTypes(). CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH. END.
 RUN Check(rejected,"close type list must contain unique integer keys").
END PROCEDURE.
