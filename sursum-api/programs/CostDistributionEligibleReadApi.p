/* Fixed database binding; client cannot select SQL, DB, company or program. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE allocations AS HANDLE NO-UNDO.
DEFINE VARIABLE containers AS HANDLE NO-UNDO.
DEFINE VARIABLE purchaseItems AS HANDLE NO-UNDO.
DEFINE VARIABLE orders AS HANDLE NO-UNDO.
DEFINE VARIABLE emitters AS HANDLE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) OR NOT CONNECTED('espec') OR NOT CONNECTED('ems2cad') THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_REQUEST',1).
 resourceName=poRequest:GetCharacter('resource').
 IF resourceName<>'custo_distribuicao_itens_aptos' THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_REQUEST',1).
 servicePath=SEARCH('sursum-api/programs/CostDistributionEligibleReadService.r'). IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_CONFIGURATION',1).
 CREATE BUFFER allocations FOR TABLE 'espec.itens_container'. CREATE BUFFER containers FOR TABLE 'espec.pp-container'.
 CREATE BUFFER purchaseItems FOR TABLE 'espec.itens_proc_compra'. CREATE BUFFER orders FOR TABLE 'espec.procs_compra'. CREATE BUFFER emitters FOR TABLE 'ems2cad.emitente'.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 RUN VALUE(servicePath)(allocations,containers,purchaseItems,orders,emitters,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code','COST_DISTRIBUTION_CONFIGURATION'). err:Add('status',503). err:Add('message','Consulta de distribuicao indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(allocations) THEN DELETE OBJECT allocations NO-ERROR.
  IF VALID-HANDLE(containers) THEN DELETE OBJECT containers NO-ERROR.
  IF VALID-HANDLE(purchaseItems) THEN DELETE OBJECT purchaseItems NO-ERROR.
  IF VALID-HANDLE(orders) THEN DELETE OBJECT orders NO-ERROR.
  IF VALID-HANDLE(emitters) THEN DELETE OBJECT emitters NO-ERROR.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
 END FINALLY.
END.
