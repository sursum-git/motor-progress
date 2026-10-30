/* Called only by the existing authenticated CIW dispatcher. Fixed physical sources. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE buffers AS HANDLE EXTENT 10 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT CONNECTED('espec') OR NOT VALID-OBJECT(poRequest) THEN UNDO, THROW NEW Progress.Lang.AppError('Configuration',1).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError('Resource',1).
 resourceName=poRequest:GetCharacter('resource').
 IF resourceName<>'container_versao_pagtos_historico_med' AND resourceName<>'container_versao_nfs_historico_med' AND resourceName<>'container_versao_descontos_historico_med' AND resourceName<>'container_versao_despesas_historico_med' THEN UNDO, THROW NEW Progress.Lang.AppError('Resource',1).
 servicePath=SEARCH('sursum-api/programs/ContainersVersionAuxHistoryService.r').
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('Service',1).
 tables='pp-container,tipos_versao_custo,versoes_item_custo_container,item_container_custos,item_container_custo_despesas,item_container_custo_nfs,item_container_custo_pgtos,item_container_custo_descontos'.
 DO n=1 TO 8: CREATE BUFFER buffers[n] FOR TABLE 'espec.' + ENTRY(n,tables). END.
 IF resourceName='container_versao_nfs_historico_med' THEN DO:
  IF NOT CONNECTED('ems2cad') THEN UNDO, THROW NEW Progress.Lang.AppError('Emitter alias unavailable',1).
  CREATE BUFFER buffers[9] FOR TABLE 'ems2cad.emitente'.
 END.
 IF resourceName='container_versao_despesas_historico_med' THEN CREATE BUFFER buffers[10] FOR TABLE 'espec.despesas'.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 RUN VALUE(servicePath)(buffers[1],buffers[2],buffers[3],buffers[4],buffers[5],buffers[6],buffers[7],buffers[8],resourceName,buffers[9],buffers[10],clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code','VERSION_HISTORY_CONFIGURATION'). err:Add('status',503). err:Add('message','Consulta historica de versao indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  DO n=1 TO 10: IF VALID-HANDLE(buffers[n]) THEN DELETE OBJECT buffers[n] NO-ERROR. END.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
 END FINALLY.
END.
