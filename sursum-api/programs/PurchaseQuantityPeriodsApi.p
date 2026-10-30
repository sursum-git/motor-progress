/* Fixed authenticated resource adapter. The parameter helper is the existing
   NO-LOCK/no-cache include; dates and predicates are never read as SQL. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 6 NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE daysValue AS INTEGER NO-UNDO.
DEFINE VARIABLE rawDays AS CHARACTER NO-UNDO. DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO. DEFINE VARIABLE err AS JsonObject NO-UNDO.
{sursum-api/includes/parametros_ima.i}
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') THEN UNDO,THROW NEW Progress.Lang.AppError('Banco indisponivel.',1).
 IF poRequest:GetCharacter('resource')<>'proc_compra_quantidades_periodo_med' THEN UNDO,THROW NEW Progress.Lang.AppError('Recurso invalido.',1).
 rawDays=getQtDiasCalcPrevChegadaPedImp().
 IF rawDays=? OR LENGTH(rawDays)<1 OR LENGTH(rawDays)>8 THEN UNDO,THROW NEW Progress.Lang.AppError('Prazo invalido.',1).
 DO k=1 TO LENGTH(rawDays):
  IF INDEX('0123456789',SUBSTRING(rawDays,k,1))=0 AND NOT (k=1 AND SUBSTRING(rawDays,k,1)='-') THEN UNDO,THROW NEW Progress.Lang.AppError('Prazo inteiro obrigatorio.',1).
 END.
 daysValue=INTEGER(rawDays) NO-ERROR. IF ERROR-STATUS:ERROR THEN UNDO,THROW NEW Progress.Lang.AppError('Prazo invalido.',1).
 servicePath=SEARCH('sursum-api/programs/PurchaseQuantityPeriodsService.r'). IF servicePath=? THEN UNDO,THROW NEW Progress.Lang.AppError('Servico indisponivel.',1).
 DO k=1 TO 6: CREATE BUFFER h[k] FOR TABLE ENTRY(k,'espec.procs_compra,espec.empresas,espec.itens_proc_compra,espec.itens_container,espec.pp-container,espec.situacoes_container'). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 RUN VALUE(servicePath)(h[1],h[2],h[3],h[4],h[5],h[6],daysValue,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). err=NEW JsonObject(). err:Add('code','PURCHASE_QUANTITY_PERIOD_CONFIGURATION'). err:Add('status',503). err:Add('message','Consulta por periodo indisponivel.'). poResponse:Add('error',err).
 END CATCH.
 FINALLY: DO k=1 TO 6: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END. END FINALLY.
END.
