/* Only espec ledger is bound. No financial rule, customer DB, writer or lookup. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE ledger AS HANDLE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) OR NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_CONFIGURATION',1).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_REQUEST',1).
 resourceName=poRequest:GetCharacter('resource'). IF resourceName<>'custo_distribuicao_lancamentos_item' THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_REQUEST',1).
 servicePath=SEARCH('sursum-api/programs/CostDistributionLedgerReadService.r'). IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('COST_DISTRIBUTION_LEDGER_CONFIGURATION',1).
 CREATE BUFFER ledger FOR TABLE 'espec.cta_corren_custo_distr'. clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 RUN VALUE(servicePath)(ledger,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code','COST_DISTRIBUTION_LEDGER_CONFIGURATION'). err:Add('status',503). err:Add('message','Conta corrente de distribuicao indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(ledger) THEN DELETE OBJECT ledger NO-ERROR.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
 END FINALLY.
END.
