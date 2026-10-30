BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttParam NO-UNDO FIELD cod-param AS CHARACTER FIELD val-param AS CHARACTER INDEX pk IS PRIMARY UNIQUE cod-param.
DEFINE VARIABLE request AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE response AS JsonObject NO-UNDO.
DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
DEFINE VARIABLE rejected AS LOGICAL NO-UNDO.
DEFINE VARIABLE invalidIds AS CHARACTER EXTENT 10 NO-UNDO.
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA ttParam
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerCustoBoundary.i}
parser=NEW ObjectModelParser().
OUTPUT TO VALUE("container-custo-boundary-tests-" + SESSION:NUMERIC-FORMAT + ".log").
DO ON ERROR UNDO, THROW:
 request=CAST(parser:Parse('~{"operation":"read","resource":"itens","container_id":71}'),JsonObject).
 RUN Check(ContainerCustoRequest(request)=71,"valid read").
 request:Set("container_id","2147483647"). RUN Check(ContainerCustoRequest(request)=2147483647,"int32 max string").
 ASSIGN invalidIds[1]="0" invalidIds[2]="-1" invalidIds[3]="1.0" invalidIds[4]="1e2" invalidIds[5]=" 71" invalidIds[6]="2147483648" invalidIds[7]="" invalidIds[8]="1,0" invalidIds[9]="71 OR 1" invalidIds[10]="00000000071".
 DO n=1 TO 10:
  request:Set("container_id",invalidIds[n]). RUN RejectRequest.
 END.
 request:SetNull("container_id"). RUN RejectRequest.
 request:Set("container_id",TRUE). RUN RejectRequest.
 request:Set("container_id",1.5). RUN RejectRequest.
 request:Set("container_id",2147483648). RUN RejectRequest.
 request:Set("container_id",-1). RUN RejectRequest.
 request:Set("container_id",0). RUN RejectRequest.
 request:Set("container_id",71).
 request:Set("operation","update"). RUN RejectRequest.
 request:Set("operation","READ"). RUN RejectRequest.
 request:Set("operation","read"). request:Set("resource","tabela"). RUN RejectRequest.
 request:Set("resource","itens"). request:Add("policy",NEW JsonObject()). RUN RejectRequest. request:Remove("policy").
 request:Add("SQL","select"). RUN RejectRequest. request:Remove("SQL").
 request:Add("moeda","real"). RUN Check(ContainerCustoRequest(request)=71,"real").
 request:Set("moeda","dolar"). RUN Check(ContainerCustoRequest(request)=71,"dolar").
 request:Set("moeda","REAL"). RUN RejectRequest. request:Remove("moeda").
 request:Add("id",1). RUN RejectRequest.
 request:Set("operation","get"). request:Add("item_container_id",1). RUN Check(ContainerCustoRequest(request)=71,"matching item alias").
 request:Set("item_container_id",2). RUN RejectRequest. request:Remove("item_container_id").
 request:Set("resource","resumo"). RUN RejectRequest.
 request:Set("id",71). RUN Check(ContainerCustoRequest(request)=71,"summary context id").
 request:Set("resource","rastro"). request:Add("rastro_id",71). RUN Check(ContainerCustoRequest(request)=71,"trace alias").
 request:Add("item_container_id",71). RUN RejectRequest. request:Remove("item_container_id"). request:Remove("rastro_id").
 request:Set("resource","comparativos"). request:Add("item_container_id",71). RUN Check(ContainerCustoRequest(request)=71,"comparison alias").
 request:Remove("id"). RUN RejectRequest.
 request=CAST(parser:Parse('~{"operation":"read","resource":"cotacoes-fiscais","container_id":71}'),JsonObject).
 RUN Check(ContainerCustoRequest(request)=71,"fiscal quotation read default real").
 request:Add("moeda","real"). RUN Check(ContainerCustoRequest(request)=71,"fiscal quotation explicit real").
 request:Set("moeda","dolar"). RUN RejectRequest. request:Set("moeda","real").
 request:Set("operation","get"). request:Add("id",71). RUN RejectRequest.
 request:Set("operation","read"). request:Remove("id"). request:Add("policy",NEW JsonObject()). RUN RejectRequest. request:Remove("policy").
 policy=ContainerCustoPolicy(). RUN Check(policy:GetInteger("cod_despesa_pis")=0,"missing tax id remains zero").
 RUN Check(policy:GetCharacter("naturezas_nota_mae")="","no invented naturezas").
 CREATE ttParam. ASSIGN ttParam.cod-param="cod_despesa_pis" ttParam.val-param="2".
 CREATE ttParam. ASSIGN ttParam.cod-param="cod_despesa_cofins" ttParam.val-param="3".
 CREATE ttParam. ASSIGN ttParam.cod-param="nat_operacao_nf_mae" ttParam.val-param="'99999'".
 CREATE ttParam. ASSIGN ttParam.cod-param="NAT-OPERACAO-IMP" ttParam.val-param="'31201M','31206'".
 policy=ContainerCustoPolicy(). RUN Check(policy:GetInteger("cod_despesa_pis")=2 AND policy:GetInteger("cod_despesa_cofins")=3,"exact configured tax ids").
 RUN Check(policy:GetCharacter("naturezas_nota_mae")="'31201M','31206'","configured import naturezas including alphanumeric code reach cost policy").
 FIND ttParam WHERE ttParam.cod-param="cod_despesa_pis". ttParam.val-param="9".
 policy=ContainerCustoPolicy(). RUN Check(policy:GetInteger("cod_despesa_pis")=9,"direct lookup no cache").
 DO n=1 TO 10:
  IF n=1 THEN NEXT. /* zero is a valid unavailable internal tax id */
  ttParam.val-param=invalidIds[n].
  IF n=7 THEN DO: policy=ContainerCustoPolicy(). RUN Check(policy:GetInteger("cod_despesa_pis")=0,"empty policy zero"). END.
  ELSE DO:
   rejected=FALSE.
   DO ON ERROR UNDO, THROW:
    policy=ContainerCustoPolicy().
    CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH.
   END.
   RUN Check(rejected,"invalid configured id rejected").
  END.
 END.
 /* Batch fixture has no HTTP credential/context. Authentication must precede
    external validation and all DB/helper work, even with hostile fields. */
 request:Add("policy",NEW JsonObject()).
 RUN ContainersCustoRead.p (INPUT request,OUTPUT response).
 RUN Check(NOT response:GetLogical("success"),"wrapper unauthenticated failure").
 RUN Check(response:GetJsonObject("error"):GetInteger("status")=401,"wrapper auth first").
 RUN Check(response:GetJsonObject("error"):GetCharacter("code")="CONTAINER_AUTH_REQUIRED","wrapper stable auth code").
 PUT UNFORMATTED "PASS: " checks " checks NUMERIC-FORMAT=" SESSION:NUMERIC-FORMAT SKIP.
 CATCH err AS Progress.Lang.Error: PUT UNFORMATTED "FAIL: " err:GetMessage(1) SKIP. UNDO, THROW err. END CATCH.
END.
OUTPUT CLOSE.
PROCEDURE RejectRequest:
 rejected=FALSE.
 DO ON ERROR UNDO, THROW:
  valueId=ContainerCustoRequest(request).
  CATCH err AS Progress.Lang.Error: rejected=TRUE. END CATCH.
 END.
 RUN Check(rejected,"invalid request rejected").
END PROCEDURE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER ok AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER messageText AS CHARACTER NO-UNDO.
 IF ok<>TRUE OR ok=? THEN UNDO, THROW NEW Progress.Lang.AppError(messageText,0).
 checks=checks + 1.
END PROCEDURE.
