/* Fixed MED attachment adapter. Caller cannot choose tables, sequence, actor or database. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 5 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL 'espec.anexos_proc_compra,espec.itens_proc_compra,espec.procs_compra,espec.empresas,espec.tipos_anexo'.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE errValue AS JsonObject NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE k AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('Bancos de anexos indisponiveis.',1).
 IF NOT VALID-OBJECT(poRequest) OR poRequest:GetCharacter('resource')<>'proc_compra_documentos' THEN UNDO, THROW NEW Progress.Lang.AppError('Recurso invalido.',1).
 DO k=1 TO 5: CREATE BUFFER h[k] FOR TABLE ENTRY(k,tables) BUFFER-NAME ('bPurchaseOrderAttachmentsApi' + STRING(k,'99')). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 servicePath=SEARCH('sursum-api/programs/PurchaseAttachmentsService.r'). IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Servico de anexos nao publicado.',1).
 RUN VALUE(servicePath)(h[1],h[2],h[3],h[4],h[5],THIS-PROCEDURE,pcActor,'order',clean,OUTPUT poResponse).
 CATCH err AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). poResponse:Add('committed',FALSE).
  errValue=NEW JsonObject(). errValue:Add('code','PURCHASE_ATTACHMENT_CONFIGURATION'). errValue:Add('status',503). errValue:Add('message','Servico de anexos indisponivel.'). poResponse:Add('error',errValue).
 END CATCH.
 FINALLY:
  DO k=1 TO 5: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END.
 END FINALLY.
END.
PROCEDURE NextRawPurchaseAttachmentId:
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Sequencia exige transacao raiz.',1).
 idValue=DYNAMIC-NEXT-VALUE('seq_anexos_proc_compra','espec').
END PROCEDURE.
