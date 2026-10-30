/* Fixed binding: owner MED is verified by the reusable item context. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 6 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL 'espec.procs_compra,espec.empresas,espec.itens_proc_compra,espec.itens_container,espec.pp-container,espec.situacoes_container'.
DEFINE VARIABLE clean AS JsonObject NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError('Allocation read unavailable',1).
 IF poRequest:GetCharacter('resource')<>'proc_compra_alocacoes' THEN UNDO, THROW NEW Progress.Lang.AppError('Invalid resource',1).
 DO k=1 TO 6: CREATE BUFFER h[k] FOR TABLE ENTRY(k,tables) BUFFER-NAME ('bPurchaseAllocations' + STRING(k,'99')). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 pathValue=SEARCH('sursum-api/programs/PurchaseItemAllocationsService.r'). IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Allocation read not published',1).
 RUN VALUE(pathValue)(h[1],h[2],h[3],h[4],h[5],h[6],clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject().
  errorValue:Add('code','PURCHASE_ALLOCATION_CONFIGURATION'). errorValue:Add('status',503). errorValue:Add('message','Consulta de alocacoes indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY: DO k=1 TO 6: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END. END FINALLY.
END.
