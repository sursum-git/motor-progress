/* Only these physical sources; resource dispatch never accepts client SQL/DB. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
DEFINE VARIABLE discountBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE ledgerBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE currentAllocations AS HANDLE NO-UNDO.
DEFINE VARIABLE currentItems AS HANDLE NO-UNDO.
DEFINE VARIABLE currentEmitters AS HANDLE NO-UNDO.
DEFINE VARIABLE currentReasons AS HANDLE NO-UNDO.
DEFINE VARIABLE servicePath AS CHARACTER NO-UNDO.
DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE err AS JsonObject NO-UNDO.
DO ON ERROR UNDO, THROW:
 IF NOT VALID-OBJECT(poRequest) OR NOT CONNECTED('espec') THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
 IF NOT poRequest:Has('resource') OR poRequest:GetType('resource')<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_REQUEST',1).
 resourceName=poRequest:GetCharacter('resource').
 IF resourceName<>'import_descontos_geral' AND resourceName<>'import_descontos_lancamentos' THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_RESOURCE',1).
 servicePath=SEARCH('sursum-api/programs/ImportDiscountsReadService.r').
 IF servicePath=? THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
 CREATE BUFFER discountBuffer FOR TABLE 'espec.descontos_importacao'.
 CREATE BUFFER ledgerBuffer FOR TABLE 'espec.cta_corren_desconto'.
 IF resourceName='import_descontos_geral' THEN DO:
  IF NOT CONNECTED('ems2cad') THEN UNDO, THROW NEW Progress.Lang.AppError('IMPORT_DISCOUNTS_CONFIGURATION',1).
  CREATE BUFFER currentAllocations FOR TABLE 'espec.itens_container'.
  CREATE BUFFER currentItems FOR TABLE 'espec.itens_proc_compra'.
  CREATE BUFFER currentEmitters FOR TABLE 'ems2cad.emitente'.
  CREATE BUFFER currentReasons FOR TABLE 'espec.motivos_desconto'.
 END.
 clean=CAST(poRequest:Clone(),JsonObject). clean:Remove('resource').
 RUN VALUE(servicePath)(discountBuffer,ledgerBuffer,currentAllocations,currentItems,currentEmitters,currentReasons,resourceName,clean,OUTPUT poResponse).
 CATCH e AS Progress.Lang.Error:
  poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code','IMPORT_DISCOUNTS_CONFIGURATION'). err:Add('status',503). err:Add('message','Consulta de descontos indisponivel.'). poResponse:Add('success',FALSE). poResponse:Add('error',err).
 END CATCH.
 FINALLY:
  IF VALID-HANDLE(discountBuffer) THEN DELETE OBJECT discountBuffer NO-ERROR.
  IF VALID-HANDLE(ledgerBuffer) THEN DELETE OBJECT ledgerBuffer NO-ERROR.
  IF VALID-HANDLE(currentAllocations) THEN DELETE OBJECT currentAllocations NO-ERROR.
  IF VALID-HANDLE(currentItems) THEN DELETE OBJECT currentItems NO-ERROR.
  IF VALID-HANDLE(currentEmitters) THEN DELETE OBJECT currentEmitters NO-ERROR.
  IF VALID-HANDLE(currentReasons) THEN DELETE OBJECT currentReasons NO-ERROR.
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
 END FINALLY.
END.
