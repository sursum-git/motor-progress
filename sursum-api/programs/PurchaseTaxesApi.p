/* Fixed fiscal adapter. Existing sequence names and authenticated actor only. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE INPUT PARAMETER pcActor AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 8 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL 'espec.despesas_proc_compra,espec.procs_compra,espec.empresas,espec.itens_proc_compra,espec.despesas,espec.empresas_despesa,espec.despesas_impostos,espec.calcs_imp_proc_compra'.
DEFINE VARIABLE clean AS JsonObject NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO. DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError('Fiscal configuration unavailable',1).
 IF poRequest:GetCharacter('resource')<>'proc_compra_despesas' THEN UNDO, THROW NEW Progress.Lang.AppError('Invalid fiscal resource',1).
 DO k=1 TO 8: CREATE BUFFER h[k] FOR TABLE ENTRY(k,tables) BUFFER-NAME ('bPurchaseTax' + STRING(k,'99')). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 pathValue=SEARCH('sursum-api/programs/PurchaseTaxesService.r'). IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Tax service not published',1).
 RUN VALUE(pathValue)(h[1],h[2],h[3],h[4],h[5],h[6],h[7],h[8],THIS-PROCEDURE,pcActor,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). poResponse:Add('committed',FALSE). errorValue=NEW JsonObject(). errorValue:Add('code','PURCHASE_TAX_CONFIGURATION'). errorValue:Add('status',503). errorValue:Add('message','Servico fiscal indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY: DO k=1 TO 8: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END. END FINALLY.
END.
PROCEDURE NextRawPurchaseTaxCalcId:
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Fiscal sequence requires root transaction',1).
 idValue=DYNAMIC-NEXT-VALUE('seq_calcs_imp_proc_compra','espec').
END PROCEDURE.
PROCEDURE NextRawPurchaseExpenseId:
 DEFINE OUTPUT PARAMETER idValue AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError('Expense sequence requires root transaction',1).
 idValue=DYNAMIC-NEXT-VALUE('seq_despesas_proc_compra','espec').
END PROCEDURE.
