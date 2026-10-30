/* Authenticated route adapter; database names, buffers, sequence and resources
   are server owned. No public route is added. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
USING OpenEdge.Net.URI.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
CREATE WIDGET-POOL.
DEFINE TEMP-TABLE ttCurrencyOwner NO-UNDO FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE VARIABLE h AS HANDLE EXTENT 13 NO-UNDO.
DEFINE VARIABLE deps AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE runtime AS HANDLE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE actorPolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE financePolicy AS JsonObject NO-UNDO.
DEFINE VARIABLE o AS JsonObject NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL 'espec.procs_compra,espec.empresas,ems2cad.emitente,espec.itens_proc_compra,espec.cta_corren_fornec_imp,espec.pagtos_proc_compra,espec.itens_container,espec.pagtos_container,espec.pp-container,ems5.tit_ap,ems5.val_tit_ap,espec.anexos_proc_compra,espec.despesas_proc_compra'.
DEFINE VARIABLE pth AS CHARACTER NO-UNDO.
DEFINE VARIABLE reader AS CHARACTER NO-UNDO.
DEFINE VARIABLE operationValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE companyCode AS CHARACTER NO-UNDO.
DEFINE VARIABLE companyId AS INTEGER NO-UNDO.
DEFINE VARIABLE pid AS INTEGER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DEFINE VARIABLE textValue AS LONGCHAR NO-UNDO.
DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE statusCode AS INTEGER NO-UNDO INITIAL 503.
DEFINE VARIABLE code AS CHARACTER NO-UNDO INITIAL 'PURCHASE_ORDER_CONFIGURATION'.
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/ContainerFinancePolicy.i}
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT CONNECTED('ems2cad') OR NOT CONNECTED('ems5') THEN UNDO, THROW NEW Progress.Lang.AppError('Bancos da integracao indisponiveis.',1).
 IF poRequest:GetCharacter('resource')<>'procs_compra_med' THEN UNDO, THROW NEW Progress.Lang.AppError('Recurso invalido.',1).
 operationValue=poRequest:GetCharacter('operation'). clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 DO k=1 TO 13: CREATE BUFFER h[k] FOR TABLE (ENTRY(k,tables)) BUFFER-NAME ('bPurchaseOrderApi' + STRING(k,'99')). END.
 pth=SEARCH('sursum-api/programs/CiwMedCompanyContext.r'). IF pth=? THEN UNDO, THROW NEW Progress.Lang.AppError('Resolvedor MED nao publicado.',1).
 RUN VALUE(pth)(h[2],OUTPUT companyCode).
 IF NOT h[2]:FIND-FIRST('WHERE cod_emp_ems2=5',NO-LOCK) THEN UNDO, THROW NEW Progress.Lang.AppError('Empresa MED nao encontrada.',1).
 companyId=h[2]:BUFFER-FIELD('empresa_id'):BUFFER-VALUE.
 IF operationValue='read' OR operationValue='get' THEN DO:
  reader=SEARCH('sursum-api/programs/CiwErpReadService.r'). IF reader=? THEN UNDO, THROW NEW Progress.Lang.AppError('Leitor ERP nao publicado.',1).
  IF operationValue='get' THEN DO:
   statusCode=422. code='PURCHASE_ORDER_VALIDATION'.
   rawValue=IF clean:GetType('id')=JsonDataType:STRING THEN clean:GetCharacter('id') ELSE STRING(clean:GetJsonText('id')).
   IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN UNDO, THROW NEW Progress.Lang.AppError('ID invalido.',1).
   DO k=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError('ID inteiro obrigatorio.',1). END.
   IF DECIMAL(rawValue)<1 OR DECIMAL(rawValue)>2147483647 THEN UNDO, THROW NEW Progress.Lang.AppError('ID fora da faixa.',1).
   pid=INTEGER(rawValue). IF clean:Has('proc_compra_id') THEN DO:
    rawValue=IF clean:GetType('proc_compra_id')=JsonDataType:STRING THEN clean:GetCharacter('proc_compra_id') ELSE STRING(clean:GetJsonText('proc_compra_id')).
    IF LENGTH(rawValue)<1 OR LENGTH(rawValue)>10 THEN UNDO, THROW NEW Progress.Lang.AppError('Alias invalido.',1).
    DO k=1 TO LENGTH(rawValue): IF INDEX('0123456789',SUBSTRING(rawValue,k,1))=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Alias invalido.',1). END.
    IF DECIMAL(rawValue)<>pid THEN UNDO, THROW NEW Progress.Lang.AppError('Alias divergente.',1).
   END.
   /* Preserve the reader's closed request validation before normalizing key. */
   IF clean:Has('proc_compra_id') THEN clean:Remove('proc_compra_id').
   o=NEW JsonObject(). o:Add('proc_compra_id',pid). o:Write(textValue,FALSE). clean:Set('id',STRING(textValue)).
  END.
  RUN VALUE(reader)(h[1],'procs_compra_med',TRIM(STRING(companyId,'->>>>>>>>>9')),clean,OUTPUT poResponse). RETURN.
 END.
 actorPolicy=NEW JsonObject(). o=NEW JsonObject(). o:Add('login',IF pcActor=? THEN '' ELSE URI:Decode(REPLACE(pcActor,'+',' '))). actorPolicy:Add('actor',o).
 financePolicy=ContainerFinancePolicy().
 CREATE ttCurrencyOwner. ttCurrencyOwner.nr-container=1.
 pth=SEARCH('sursum-api/programs/ContainersItensRuntime.r'). IF pth=? THEN UNDO, THROW NEW Progress.Lang.AppError('Runtime financeiro nao publicado.',1).
 RUN VALUE(pth) PERSISTENT SET runtime(INPUT ?,INPUT ?,INPUT BUFFER ttCurrencyOwner:HANDLE,h[7],h[4],h[1],h[5],h[6],h[8],h[9],h[10],h[11],actorPolicy,financePolicy).
 deps[1]=h[4]. deps[2]=h[12]. deps[3]=h[13]. deps[4]=h[6].
 pth=SEARCH('sursum-api/programs/PurchaseOrdersService.r'). IF pth=? THEN UNDO, THROW NEW Progress.Lang.AppError('Writer de pedido nao publicado.',1).
 RUN VALUE(pth)(h[1],h[2],h[3],h[4],h[5],h[6],deps,runtime,actorPolicy,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). o=NEW JsonObject(). o:Add('code',code). o:Add('status',statusCode). o:Add('message',e:GetMessage(1)). poResponse:Add('success',FALSE). poResponse:Add('error',o).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(runtime) THEN DELETE PROCEDURE runtime NO-ERROR.
  DO k=1 TO 13: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END.
 END FINALLY.
END.
