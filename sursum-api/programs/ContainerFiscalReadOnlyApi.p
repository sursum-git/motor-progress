/* Fixed spec bindings; no table, program or company can be chosen over HTTP. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE h AS HANDLE EXTENT 3 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL 'espec.pp-container,espec.calcs_imp_container,espec.despesas_container'.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO. DEFINE VARIABLE k AS INTEGER NO-UNDO. DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError('Unavailable',1).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError('Resource required',1).
 IF LOOKUP(poRequest:GetCharacter('resource'),'container_calculos_impostos_med,container_despesa_memoria_med')=0 THEN UNDO, THROW NEW Progress.Lang.AppError('Resource invalid',1).
 DO k=1 TO 3: CREATE BUFFER h[k] FOR TABLE ENTRY(k,tables) BUFFER-NAME ('bContainerFiscal' + STRING(k,'99')). END.
 pathValue=SEARCH('sursum-api/programs/ContainerFiscalReadOnlyService.r'). IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Not published',1).
 RUN VALUE(pathValue)(h[1],h[2],h[3],poRequest,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). poResponse:Add('success',FALSE). errorValue=NEW JsonObject().
  errorValue:Add('code','CONTAINER_FISCAL_CONFIGURATION'). errorValue:Add('status',503). errorValue:Add('message','Consulta fiscal indisponivel.'). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY: DO k=1 TO 3: IF VALID-HANDLE(h[k]) THEN DELETE OBJECT h[k] NO-ERROR. END. END FINALLY.
END.
