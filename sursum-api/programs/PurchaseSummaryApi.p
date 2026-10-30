/* Fixed database binding. No table, SQL, company or writer chosen by client. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 4 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL 'espec.procs_compra,espec.empresas,espec.itens_proc_compra,espec.despesas_proc_compra'.
DEFINE VARIABLE clean AS JsonObject NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError('Summary unavailable',1).
 IF poRequest:GetCharacter('resource')<>'proc_compra_resumo' THEN UNDO, THROW NEW Progress.Lang.AppError('Invalid resource',1).
 DO k=1 TO 4: CREATE BUFFER h[k] FOR TABLE ENTRY(k,tables) BUFFER-NAME ('bPurchaseSummary' + STRING(k,'99')). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 pathValue=SEARCH('sursum-api/programs/PurchaseSummaryService.r'). IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Summary not published',1).
 RUN VALUE(pathValue)(h[1],h[2],h[3],h[4],clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject().
  errorValue:Add('code','PURCHASE_SUMMARY_CONFIGURATION'). errorValue:Add('status',503). errorValue:Add('message','Resumo indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY: DO k=1 TO 4: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END. END FINALLY.
END.
