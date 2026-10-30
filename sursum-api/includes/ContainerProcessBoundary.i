/* Public command allowlist. No callback, calculation, policy or DB from HTTP. */
FUNCTION ProcessInteger RETURNS INTEGER (requestValue AS JsonObject,nameValue AS CHARACTER,allowZero AS LOGICAL):
 DEFINE VARIABLE valueId AS DECIMAL NO-UNDO.
 IF NOT requestValue:Has(nameValue) THEN RETURN ?.
 IF requestValue:GetType(nameValue)<>JsonDataType:NUMBER THEN RETURN ?.
 valueId=requestValue:GetDecimal(nameValue).
 IF valueId=? OR valueId < (IF allowZero THEN 0 ELSE 1) OR valueId>2147483647 OR TRUNCATE(valueId,0)<>valueId THEN RETURN ?.
 RETURN INTEGER(valueId).
END FUNCTION.
FUNCTION ContainerNfText RETURNS CHARACTER (rowValue AS JsonObject,nameValue AS CHARACTER,maximumLength AS INTEGER):
 DEFINE VARIABLE valueText AS CHARACTER CASE-SENSITIVE NO-UNDO.
 IF NOT VALID-OBJECT(rowValue) OR NOT rowValue:Has(nameValue) THEN RETURN ?.
 IF rowValue:GetType(nameValue)<>JsonDataType:STRING THEN RETURN ?.
 valueText=TRIM(rowValue:GetCharacter(nameValue)).
 IF valueText="" OR LENGTH(valueText)>maximumLength OR INDEX(valueText,CHR(1))>0 THEN RETURN ?.
 RETURN valueText.
END FUNCTION.
FUNCTION ContainerProcessRequest RETURNS INTEGER (requestValue AS JsonObject):
 DEFINE VARIABLE resourceValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE operationValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE propertyValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE fieldsValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE namesValue AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE cid AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE accepted AS LOGICAL NO-UNDO.
 DEFINE VARIABLE nfsValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE nfValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE nfKeys AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE documentoValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE serieValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE estabValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE naturezaValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE nfKeyValue AS CHARACTER CASE-SENSITIVE NO-UNDO.
 IF NOT VALID-OBJECT(requestValue) THEN UNDO, THROW NEW Progress.Lang.AppError("Requisicao obrigatoria.",1).
 IF NOT requestValue:Has("resource") OR NOT requestValue:Has("operation") THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso e operacao obrigatorios.",1).
 IF requestValue:GetType("resource")<>JsonDataType:STRING OR requestValue:GetType("operation")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso/operacao invalidos.",1).
 resourceValue=requestValue:GetCharacter("resource"). operationValue=requestValue:GetCharacter("operation").
 fieldsValue="resource,operation,container_id,request_id".
 IF resourceValue="versoes" AND operationValue="gerar" THEN DO:
  fieldsValue=fieldsValue + ",tipo_versao_id,descricao,expected_latest_version_id".
  IF ProcessInteger(requestValue,"tipo_versao_id",FALSE)=? OR ProcessInteger(requestValue,"expected_latest_version_id",TRUE)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo e expectativa da ultima versao obrigatorios.",1).
  IF NOT requestValue:Has("descricao") THEN UNDO, THROW NEW Progress.Lang.AppError("Descricao obrigatoria.",1).
  IF requestValue:GetType("descricao")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Descricao invalida.",1).
  IF TRIM(requestValue:GetCharacter("descricao"))="" OR LENGTH(requestValue:GetCharacter("descricao"))>8000 THEN UNDO, THROW NEW Progress.Lang.AppError("Descricao invalida.",1).
 END.
 ELSE IF resourceValue="custos" AND operationValue="fechar" THEN DO:
  fieldsValue=fieldsValue + ",versao_id,expected_latest_version_id,log_priorizar_custo_previsto".
  IF ProcessInteger(requestValue,"versao_id",FALSE)=? OR ProcessInteger(requestValue,"expected_latest_version_id",FALSE)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Versao e expectativa obrigatorias.",1).
  IF NOT requestValue:Has("log_priorizar_custo_previsto") THEN UNDO, THROW NEW Progress.Lang.AppError("Preferencia obrigatoria.",1).
  IF requestValue:GetType("log_priorizar_custo_previsto")<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Preferencia deve ser booleana.",1).
 END.
 ELSE IF resourceValue="despesas-selecao" AND operationValue="options" THEN fieldsValue=fieldsValue + ",ordem_campo,ordem_direcao".
 ELSE IF resourceValue="impostos" AND operationValue="selecionar_despesas" THEN DO:
  fieldsValue=fieldsValue + ",despesa_ids,ordem_campo,ordem_direcao".
  IF NOT requestValue:Has("despesa_ids") THEN UNDO, THROW NEW Progress.Lang.AppError("Selecao obrigatoria.",1).
  IF requestValue:GetType("despesa_ids")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Selecao invalida.",1).
  IF requestValue:GetJsonArray("despesa_ids"):Length<1 OR requestValue:GetJsonArray("despesa_ids"):Length>100 THEN UNDO, THROW NEW Progress.Lang.AppError("Selecione de1a100despesas.",1).
 END.
 ELSE IF resourceValue="nfs" AND (operationValue="associar" OR operationValue="desassociar") THEN DO:
  fieldsValue=fieldsValue + ",expected_nf_stamp,nfs".
  IF ContainerNfText(requestValue,"expected_nf_stamp",128)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Expectativa das notas obrigatoria.",1).
  IF NOT requestValue:Has("nfs") OR requestValue:GetType("nfs")<>JsonDataType:ARRAY THEN UNDO, THROW NEW Progress.Lang.AppError("Notas obrigatorias.",1).
  nfsValue=requestValue:GetJsonArray("nfs").
  IF nfsValue:Length<1 OR nfsValue:Length>100 THEN UNDO, THROW NEW Progress.Lang.AppError("Selecione de1a100notas.",1).
  EXTENT(nfKeys)=nfsValue:Length.
  DO n=1 TO nfsValue:Length:
   IF nfsValue:GetType(n)<>JsonDataType:OBJECT THEN UNDO, THROW NEW Progress.Lang.AppError("Nota invalida.",1).
   nfValue=nfsValue:GetJsonObject(n).
   documentoValue=ContainerNfText(nfValue,"documento",60).
   serieValue=ContainerNfText(nfValue,"serie",20).
   estabValue=ContainerNfText(nfValue,"estab",20).
   naturezaValue=ContainerNfText(nfValue,"nat_operacao",60).
   IF documentoValue=? OR serieValue=? OR estabValue=? OR naturezaValue=? OR ProcessInteger(nfValue,"cod_emitente",FALSE)=? THEN UNDO, THROW NEW Progress.Lang.AppError("Chave completa da nota obrigatoria.",1).
   namesValue=nfValue:GetNames().
   DO j=1 TO EXTENT(namesValue):
    propertyValue=namesValue[j].
    IF propertyValue<>"documento" AND propertyValue<>"serie" AND propertyValue<>"estab" AND propertyValue<>"nat_operacao" AND propertyValue<>"cod_emitente" THEN UNDO, THROW NEW Progress.Lang.AppError("Campo de nota nao permitido: " + propertyValue,1).
   END.
   nfKeyValue=documentoValue + CHR(1) + serieValue + CHR(1) + estabValue + CHR(1) + naturezaValue + CHR(1) + STRING(ProcessInteger(nfValue,"cod_emitente",FALSE)).
   DO j=1 TO n - 1: IF nfKeys[j]=nfKeyValue THEN UNDO, THROW NEW Progress.Lang.AppError("Nota repetida na requisicao.",1). END.
   nfKeys[n]=nfKeyValue.
  END.
 END.
 ELSE IF resourceValue<>"impostos" OR (operationValue<>"sincronizar" AND operationValue<>"calcular_impostos") THEN UNDO, THROW NEW Progress.Lang.AppError("Comando nao suportado.",1).
 cid=ProcessInteger(requestValue,"container_id",FALSE).
 IF cid=? THEN UNDO, THROW NEW Progress.Lang.AppError("Container inteiro positivo obrigatorio.",1).
 IF requestValue:Has("request_id") THEN DO:
  IF requestValue:GetType("request_id")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Rastreio invalido.",1).
  IF LENGTH(requestValue:GetCharacter("request_id"))>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Rastreio excede limite.",1).
 END.
 namesValue=requestValue:GetNames().
 DO n=1 TO EXTENT(namesValue):
  propertyValue=namesValue[n]. accepted=FALSE.
  DO j=1 TO NUM-ENTRIES(fieldsValue): IF propertyValue=ENTRY(j,fieldsValue) THEN accepted=TRUE. END.
  IF NOT accepted THEN UNDO, THROW NEW Progress.Lang.AppError("Campo externo nao permitido: " + propertyValue,1).
 END.
 RETURN cid.
END FUNCTION.
