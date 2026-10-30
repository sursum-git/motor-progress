/* Fixed global discount read and selected-discount ledger; no writer. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phDiscounts AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phLedger AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCurrentAllocations AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCurrentItems AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCurrentEmitters AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER phCurrentReasons AS HANDLE NO-UNDO.
DEFINE INPUT PARAMETER pcResource AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.
{sursum-api/includes/ImportDiscountsReadTables.i}
DEFINE VARIABLE collectorPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE readerPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE op AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE allowedNames AS CHARACTER CASE-SENSITIVE NO-UNDO.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE started AS INTEGER NO-UNDO.
DEFINE VARIABLE rowsRead AS INTEGER NO-UNDO.
DEFINE VARIABLE selectedId AS INTEGER NO-UNDO.
DEFINE VARIABLE isLedger AS LOGICAL NO-UNDO.
DEFINE VARIABLE complete AS LOGICAL NO-UNDO.
DEFINE VARIABLE rowBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE clean AS JsonObject NO-UNDO.
DEFINE VARIABLE labelsPath AS CHARACTER NO-UNDO.
DEFINE VARIABLE labelsValue AS JsonObject NO-UNDO.
FUNCTION Exact RETURNS LOGICAL(nameValue AS CHARACTER,listValue AS CHARACTER):
 DEFINE VARIABLE checkedValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE indexValue AS INTEGER NO-UNDO.
 checkedValue=nameValue.
 DO indexValue=1 TO NUM-ENTRIES(listValue): IF checkedValue=ENTRY(indexValue,listValue) THEN RETURN TRUE. END.
 RETURN FALSE.
END FUNCTION.
FUNCTION ContextId RETURNS INTEGER():
 DEFINE VARIABLE v AS DECIMAL NO-UNDO.
 IF NOT poRequest:Has('desconto_importacao_id') OR poRequest:GetType('desconto_importacao_id')<>JsonDataType:NUMBER THEN RETURN ?.
 v=poRequest:GetDecimal('desconto_importacao_id').
 IF v=? OR v<1 OR v>2147483647 OR v<>TRUNCATE(v,0) THEN RETURN ?.
 RETURN INTEGER(v).
END FUNCTION.
DO ON ERROR UNDO, THROW:
 started=ETIME.
 IF NOT VALID-OBJECT(poRequest) THEN RUN Fail('IMPORT_DISCOUNTS_REQUEST',422).
 IF pcResource<>'import_descontos_geral' AND pcResource<>'import_descontos_lancamentos' THEN RUN Fail('IMPORT_DISCOUNTS_RESOURCE',422).
 isLedger=pcResource='import_descontos_lancamentos'.
 IF NOT poRequest:Has('operation') OR poRequest:GetType('operation')<>JsonDataType:STRING THEN RUN Fail('IMPORT_DISCOUNTS_REQUEST',422).
 op=poRequest:GetCharacter('operation').
 IF op<>'read' AND op<>'get' THEN RUN Fail('IMPORT_DISCOUNTS_READ_ONLY',405).
 allowedNames=IF op='read' THEN 'operation,skip,take,filter,sort' ELSE 'operation,id,record_key'.
 IF isLedger THEN allowedNames=allowedNames + ',desconto_importacao_id'.
 names=poRequest:GetNames().
 DO n=1 TO EXTENT(names): IF NOT Exact(names[n],allowedNames) THEN RUN Fail('IMPORT_DISCOUNTS_REQUEST',422). END.
 selectedId=IF isLedger THEN ContextId() ELSE ?.
 IF isLedger AND selectedId=? THEN RUN Fail('IMPORT_DISCOUNTS_CONTEXT',422).
 collectorPath=SEARCH('sursum-api/programs/ImportDiscountsCollector.r'). readerPath=SEARCH('sursum-api/programs/CiwErpReadService.r').
 IF collectorPath=? OR readerPath=? THEN RUN Fail('IMPORT_DISCOUNTS_CONFIGURATION',503).
 DO STOP-AFTER 10 ON STOP UNDO, LEAVE:
  RUN VALUE(collectorPath)(phDiscounts,phLedger,selectedId,started,50000,INPUT-OUTPUT rowsRead,OUTPUT TABLE ttImportDiscountsRead,OUTPUT TABLE ttImportDiscountLedgerRead).
  IF isLedger AND NOT CAN-FIND(FIRST ttImportDiscountsRead WHERE ttImportDiscountsRead.desconto_importacao_id=selectedId) THEN RUN Fail('IMPORT_DISCOUNTS_PARENT',404).
  IF NOT isLedger THEN DO:
   labelsPath=SEARCH('sursum-api/programs/ContainersVersionHistoryLabels.r').
   IF labelsPath=? THEN RUN Fail('IMPORT_DISCOUNTS_CONFIGURATION',503).
   FOR EACH ttImportDiscountsRead:
    RUN VALUE(labelsPath)(phCurrentAllocations,phCurrentItems,phCurrentEmitters,phCurrentReasons,'item',ttImportDiscountsRead.item_container_id,started,INPUT-OUTPUT rowsRead,OUTPUT labelsValue).
    ASSIGN ttImportDiscountsRead.item_codigo_erp_atual=IF labelsValue:IsNull('item_codigo_erp_atual') THEN ? ELSE labelsValue:GetCharacter('item_codigo_erp_atual')
           ttImportDiscountsRead.item_descricao_atual=IF labelsValue:IsNull('item_descricao_atual') THEN ? ELSE labelsValue:GetCharacter('item_descricao_atual').
    DELETE OBJECT labelsValue.
    RUN VALUE(labelsPath)(phCurrentAllocations,phCurrentItems,phCurrentEmitters,phCurrentReasons,'emitente',ttImportDiscountsRead.fornecedor_id,started,INPUT-OUTPUT rowsRead,OUTPUT labelsValue).
    ttImportDiscountsRead.fornecedor_nome_abrev_atual=IF labelsValue:IsNull('emitente_nome_abrev_atual') THEN ? ELSE labelsValue:GetCharacter('emitente_nome_abrev_atual'). DELETE OBJECT labelsValue.
    RUN VALUE(labelsPath)(phCurrentAllocations,phCurrentItems,phCurrentEmitters,phCurrentReasons,'motivo',ttImportDiscountsRead.motivo_desconto_id,started,INPUT-OUTPUT rowsRead,OUTPUT labelsValue).
    ttImportDiscountsRead.motivo_descricao_atual=IF labelsValue:IsNull('motivo_descricao_atual') THEN ? ELSE labelsValue:GetCharacter('motivo_descricao_atual'). DELETE OBJECT labelsValue.
   END.
  END.
  rowBuffer=IF isLedger THEN BUFFER ttImportDiscountLedgerRead:HANDLE ELSE BUFFER ttImportDiscountsRead:HANDLE.
  clean=CAST(poRequest:Clone(),JsonObject). IF isLedger THEN clean:Remove('desconto_importacao_id').
  RUN VALUE(readerPath)(rowBuffer,pcResource,'',clean,OUTPUT poResponse).
  complete=TRUE.
 END.
 IF NOT complete OR ETIME - started>10000 THEN RUN Fail('IMPORT_DISCOUNTS_TIMEOUT',503).
 CATCH e AS Progress.Lang.Error:
  IF NOT VALID-OBJECT(poResponse) OR NOT poResponse:Has('error') THEN RUN ErrorResponse('IMPORT_DISCOUNTS_CONFIGURATION',503).
 END CATCH.
 FINALLY:
  IF VALID-OBJECT(clean) THEN DELETE OBJECT clean.
  IF VALID-OBJECT(labelsValue) THEN DELETE OBJECT labelsValue.
 END FINALLY.
END.
PROCEDURE Fail:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 RUN ErrorResponse(codeValue,statusValue).
 UNDO, THROW NEW Progress.Lang.AppError(codeValue,1).
END PROCEDURE.
PROCEDURE ErrorResponse:
 DEFINE INPUT PARAMETER codeValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER statusValue AS INTEGER NO-UNDO.
 DEFINE VARIABLE err AS JsonObject NO-UNDO.
 IF VALID-OBJECT(poResponse) THEN DELETE OBJECT poResponse.
 poResponse=NEW JsonObject(). err=NEW JsonObject(). err:Add('code',codeValue). err:Add('status',statusValue). err:Add('message','Consulta de descontos invalida ou indisponivel.').
 poResponse:Add('success',FALSE). poResponse:Add('error',err).
END PROCEDURE.
