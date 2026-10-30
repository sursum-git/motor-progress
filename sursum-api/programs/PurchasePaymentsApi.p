/* Closed adapter under authenticated CiwCadastrosCrud route. No public new route,
   no dynamic resource names or executable paths supplied by the browser. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
DEFINE TEMP-TABLE ttCurrencyOwner NO-UNDO FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE VARIABLE hMaster AS HANDLE NO-UNDO.
DEFINE VARIABLE hPurchase AS HANDLE NO-UNDO.
DEFINE VARIABLE hCompanies AS HANDLE NO-UNDO.
DEFINE VARIABLE hLinks AS HANDLE NO-UNDO.
DEFINE VARIABLE hTitle AS HANDLE NO-UNDO.
DEFINE VARIABLE hCurrencyTitle AS HANDLE NO-UNDO.
DEFINE VARIABLE hValue AS HANDLE NO-UNDO.
DEFINE VARIABLE hItems AS HANDLE NO-UNDO.
DEFINE VARIABLE hPurchaseItems AS HANDLE NO-UNDO.
DEFINE VARIABLE hLedger AS HANDLE NO-UNDO.
DEFINE VARIABLE hContainerLinks AS HANDLE NO-UNDO.
DEFINE VARIABLE hAllContainers AS HANDLE NO-UNDO.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE pth AS CHARACTER NO-UNDO.
DEFINE VARIABLE resolver AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMed AS CHARACTER NO-UNDO.
DEFINE VARIABLE medId AS INTEGER NO-UNDO.
DEFINE VARIABLE parentId AS INTEGER NO-UNDO.
DEFINE VARIABLE resource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE policy AS JsonObject NO-UNDO.
DEFINE VARIABLE finance AS JsonObject NO-UNDO.
DEFINE VARIABLE actor AS JsonObject NO-UNDO.
DEFINE VARIABLE keyObject AS JsonObject NO-UNDO.
DEFINE VARIABLE textKey AS LONGCHAR NO-UNDO.
DEFINE VARIABLE rawId AS CHARACTER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_PAYMENT_CONFIGURATION'.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 503.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerFinancePolicy.i}
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT CONNECTED('ems5') THEN UNDO, THROW NEW Progress.Lang.AppError('Bancos da integracao indisponiveis.',1).
 resource=poRequest:GetCharacter('resource'). op=poRequest:GetCharacter('operation').
 CREATE BUFFER hPurchase FOR TABLE 'espec.procs_compra' BUFFER-NAME 'bPurchaseApiMaster'.
 CREATE BUFFER hCompanies FOR TABLE 'espec.empresas' BUFFER-NAME 'bPurchaseApiCompanies'.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 IF resource='procs_compra_financeiro_med' THEN DO:
  IF LOOKUP(op,'read,get')=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Consulta de processos somente leitura.',1).
  resolver=SEARCH('sursum-api/programs/CiwMedCompanyContext.r'). pth=SEARCH('sursum-api/programs/CiwErpReadService.r').
  IF resolver=? OR pth=? THEN UNDO, THROW NEW Progress.Lang.AppError('Leitores compartilhados nao publicados.',1).
  RUN VALUE(resolver)(hCompanies,OUTPUT cMed).
  IF NOT hCompanies:FIND-FIRST('WHERE cod_emp_ems2=5',NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError('Empresa MED nao localizada.',1).
  medId=hCompanies:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
  IF medId=? OR medId<1 THEN UNDO, THROW NEW Progress.Lang.AppError('Empresa MED invalida.',1).
  IF op='get' THEN DO:
   code='PURCHASE_PAYMENT_VALIDATION'. statusCode=422.
   rawId=STRING(clean:GetJsonText('id')).
   IF clean:GetType('id')=JsonDataType:STRING THEN rawId=clean:GetCharacter('id').
   IF LENGTH(rawId)<1 OR LENGTH(rawId)>10 THEN UNDO, THROW NEW Progress.Lang.AppError('ID invalido.',1).
   DO k=1 TO LENGTH(rawId): IF INDEX('0123456789',SUBSTRING(rawId,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError('ID inteiro obrigatorio.',1). END.
   IF DECIMAL(rawId)<1 OR DECIMAL(rawId)>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('ID fora da faixa.',1).
   parentId=INTEGER(rawId). keyObject=NEW JsonObject(). keyObject:Add('proc_compra_id',parentId). keyObject:Write(textKey,FALSE).
   IF clean:Has('proc_compra_id') THEN IF clean:GetInteger('proc_compra_id')<>parentId THEN UNDO, THROW NEW Progress.Lang.AppError('Alias divergente.',1).
   clean=NEW JsonObject(). clean:Add('operation','get'). clean:Add('id',STRING(textKey)).
  END.
  RUN VALUE(pth)(hPurchase,'processos_compra_med',TRIM(STRING(medId,'->>>>>>>>>9')),clean,OUTPUT poResponse). RETURN.
 END.
 IF resource<>'proc_compra_pagamentos' AND resource<>'proc_compra_titulos_disponiveis' THEN UNDO, THROW NEW Progress.Lang.AppError('Recurso invalido.',1).
 IF resource='proc_compra_titulos_disponiveis' THEN DO:
  IF op<>'read' THEN UNDO, THROW NEW Progress.Lang.AppError('Opcoes somente leitura.',1).
  clean:Set('operation','available').
 END.
 CREATE BUFFER hLinks FOR TABLE 'espec.pagtos_proc_compra' BUFFER-NAME 'bPurchaseApiLinks'.
 CREATE BUFFER hTitle FOR TABLE 'ems5.tit_ap' BUFFER-NAME 'bPurchaseApiTitleMutex'.
 CREATE BUFFER hCurrencyTitle FOR TABLE 'ems5.tit_ap' BUFFER-NAME 'bPurchaseApiCurrencyTitles'.
 CREATE BUFFER hValue FOR TABLE 'ems5.val_tit_ap' BUFFER-NAME 'bPurchaseApiValues'.
 pth=SEARCH('sursum-api/programs/PurchasePaymentsService.r'). IF pth=? THEN UNDO, THROW NEW Progress.Lang.AppError('Servico de pagamentos nao publicado.',1).
 policy=NEW JsonObject(). finance=ContainerFinancePolicy(). actor=NEW JsonObject(). actor:Add('login',IF pcActor=? THEN '' ELSE URI:Decode(REPLACE(pcActor,'+',' '))). policy:Add('actor',actor).
 IF op='create' OR op='delete' THEN DO:
  resolver=SEARCH('sursum-api/programs/ContainersItensRuntime.r'). IF resolver=? THEN UNDO, THROW NEW Progress.Lang.AppError('Runtime financeiro nao publicado.',1).
  CREATE BUFFER hItems FOR TABLE 'espec.itens_container' BUFFER-NAME 'bPurchaseApiContainerItems'.
  CREATE BUFFER hPurchaseItems FOR TABLE 'espec.itens_proc_compra' BUFFER-NAME 'bPurchaseApiOrderItems'.
  CREATE BUFFER hLedger FOR TABLE 'espec.cta_corren_fornec_imp' BUFFER-NAME 'bPurchaseApiLedger'.
  CREATE BUFFER hContainerLinks FOR TABLE 'espec.pagtos_container' BUFFER-NAME 'bPurchaseApiContainerPayments'.
  CREATE BUFFER hAllContainers FOR TABLE 'espec.pp-container' BUFFER-NAME 'bPurchaseApiContainers'.
  CREATE ttCurrencyOwner. ttCurrencyOwner.nr-container=1.
  RUN VALUE(resolver) PERSISTENT SET runtime(INPUT ?,INPUT ?,INPUT BUFFER ttCurrencyOwner:HANDLE,hItems,hPurchaseItems,hPurchase,hLedger,hLinks,hContainerLinks,hAllContainers,hCurrencyTitle,hValue,policy,finance).
 END.
 /* Generic PHP delete may submit readonly presentation; no client values are
    used for a removal. ID+parent select the locked physical snapshot. */
 IF op='delete' AND clean:Has('values') THEN clean:Remove('values').
 RUN VALUE(pth)(hPurchase,hCompanies,hLinks,hTitle,hValue,runtime,policy,finance,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). actor=NEW JsonObject(). actor:Add('code',code). actor:Add('status',statusCode). actor:Add('message',e:GetMessage(1)). poResponse:Add('success',FALSE). poResponse:Add('error',actor).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(runtime) THEN DELETE PROCEDURE runtime NO-ERROR.
 END FINALLY.
END.
