/* Authenticated dispatcher only. Fixed espec tables; no company narrowing. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE buffers AS HANDLE EXTENT 10 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE currencyValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE resourceValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE errorValue AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT VALID-OBJECT(poRequest) THEN UNDO,THROW NEW Progress.Lang.AppError('Configuration',1).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN UNDO,THROW NEW Progress.Lang.AppError('Resource',1).
 resourceValue=poRequest:GetCharacter('resource').
 CASE resourceValue:
  WHEN 'container_custos_comparacao_real' THEN currencyValue='real'.
  WHEN 'container_custos_comparacao_dolar' THEN currencyValue='dolar'.
  OTHERWISE UNDO,THROW NEW Progress.Lang.AppError('Resource',1).
 END CASE.
 servicePath=SEARCH('sursum-api/programs/ContainersVersionComparisonService.r').
 IF servicePath=? THEN UNDO,THROW NEW Progress.Lang.AppError('Service',1).
 tables='pp-container,tipos_versao_custo,versoes_item_custo_container,item_container_custos,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos,itens_container,itens_proc_compra'.
 DO n=1 TO 10: CREATE BUFFER buffers[n] FOR TABLE 'espec.' + ENTRY(n,tables). END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 RUN VALUE(servicePath)(buffers[1],buffers[2],buffers[3],buffers[4],buffers[5],buffers[6],buffers[7],buffers[8],buffers[9],buffers[10],currencyValue,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). errorValue=NEW JsonObject(). errorValue:Add('code','COMPARISON_CONFIGURATION'). errorValue:Add('status',503). errorValue:Add('message','Consulta comparativa indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',errorValue).
 END CATCH.
 FINALLY:
  DO n=1 TO 10: IF VALID-HANDLE(buffers[n]) THEN DELETE OBJECT buffers[n] NO-ERROR. END.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
 END FINALLY.
END.
