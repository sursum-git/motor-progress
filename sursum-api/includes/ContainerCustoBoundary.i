/* Fixed external request/policy boundary. Include after parametros_ima.i.
   Kept independently testable with an im-param temp-table; no business writes. */
FUNCTION CustoInteger RETURNS INTEGER (pcText AS CHARACTER, plZero AS LOGICAL):
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE valueId AS DECIMAL NO-UNDO.
 IF pcText=? OR LENGTH(pcText)<1 OR LENGTH(pcText)>10 THEN RETURN ?.
 DO n=1 TO LENGTH(pcText):
  IF INDEX("0123456789",SUBSTRING(pcText,n,1))=0 THEN RETURN ?.
 END.
 valueId=DECIMAL(pcText).
 IF valueId>2147483647 OR (NOT plZero AND valueId<1) THEN RETURN ?.
 RETURN INTEGER(valueId).
END FUNCTION.
FUNCTION CustoId RETURNS INTEGER (poObject AS JsonObject, pcField AS CHARACTER):
 IF NOT VALID-OBJECT(poObject) THEN RETURN ?.
 IF NOT poObject:Has(pcField) THEN RETURN ?.
 CASE poObject:GetType(pcField):
  WHEN JsonDataType:STRING THEN RETURN CustoInteger(poObject:GetCharacter(pcField),FALSE).
  WHEN JsonDataType:NUMBER THEN RETURN CustoInteger(STRING(poObject:GetJsonText(pcField)),FALSE).
 END CASE.
 RETURN ?.
END FUNCTION.
FUNCTION ContainerCustoRequest RETURNS INTEGER (poObject AS JsonObject):
 DEFINE VARIABLE operationName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE resourceName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE fieldName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE currencyName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE containerId AS INTEGER NO-UNDO.
 DEFINE VARIABLE recordId AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 IF NOT VALID-OBJECT(poObject) THEN UNDO, THROW NEW Progress.Lang.AppError("Requisicao ausente.",0).
 IF NOT poObject:Has("operation") OR NOT poObject:Has("resource") THEN UNDO, THROW NEW Progress.Lang.AppError("Informe operacao e recurso.",0).
 IF poObject:GetType("operation")<>JsonDataType:STRING OR poObject:GetType("resource")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Operacao ou recurso invalido.",0).
 ASSIGN operationName=poObject:GetCharacter("operation") resourceName=poObject:GetCharacter("resource") containerId=CustoId(poObject,"container_id").
 IF operationName<>"read" AND operationName<>"get" THEN UNDO, THROW NEW Progress.Lang.AppError("A consulta aceita somente read e get.",0).
 IF resourceName<>"itens" AND resourceName<>"resumo" AND resourceName<>"comparativos" AND resourceName<>"rastro" AND resourceName<>"cotacoes-fiscais" THEN UNDO, THROW NEW Progress.Lang.AppError("Recurso de custo invalido.",0).
 IF containerId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Informe container_id inteiro positivo valido.",0).
 currencyName="real".
 IF poObject:Has("moeda") THEN DO:
  IF poObject:GetType("moeda")<>JsonDataType:STRING THEN UNDO, THROW NEW Progress.Lang.AppError("Moeda invalida.",0).
  currencyName=poObject:GetCharacter("moeda").
  IF currencyName<>"real" AND currencyName<>"dolar" THEN UNDO, THROW NEW Progress.Lang.AppError("Moeda invalida.",0).
 END.
 IF resourceName="cotacoes-fiscais" AND (operationName<>"read" OR currencyName<>"real") THEN UNDO, THROW NEW Progress.Lang.AppError("Cotacoes fiscais aceitam somente read em real.",0).
 IF operationName="get" THEN DO:
  recordId=CustoId(poObject,"id").
  IF recordId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Informe id inteiro positivo valido.",0).
  IF resourceName="resumo" AND recordId<>containerId THEN UNDO, THROW NEW Progress.Lang.AppError("ID do resumo difere do container.",0).
 END.
 ELSE IF poObject:Has("id") THEN UNDO, THROW NEW Progress.Lang.AppError("id somente em detalhe.",0).
 names=poObject:GetNames().
 DO n=1 TO EXTENT(names):
  fieldName=names[n].
  IF fieldName="operation" OR fieldName="resource" OR fieldName="container_id" OR fieldName="id" OR fieldName="moeda" THEN NEXT.
  IF operationName="get" AND (((resourceName="itens" OR resourceName="comparativos") AND fieldName="item_container_id") OR (resourceName="rastro" AND fieldName="rastro_id")) THEN DO:
   IF CustoId(poObject,fieldName)=? OR CustoId(poObject,fieldName)<>recordId THEN UNDO, THROW NEW Progress.Lang.AppError("Alias de identificador divergente.",0).
  END.
  ELSE UNDO, THROW NEW Progress.Lang.AppError("Campo externo nao permitido.",0).
 END.
 RETURN containerId.
END FUNCTION.
FUNCTION CustoTaxId RETURNS INTEGER (pcParameter AS CHARACTER):
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 rawValue=buscarParametroIma(pcParameter,"").
 IF rawValue=? OR rawValue="" THEN RETURN 0.
 valueId=CustoInteger(rawValue,TRUE).
 IF valueId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Parametro fiscal de despesa invalido.",0).
 RETURN valueId.
END FUNCTION.
FUNCTION ContainerCustoPolicy RETURNS JsonObject ():
 DEFINE VARIABLE policy AS JsonObject NO-UNDO.
 DEFINE VARIABLE naturezas AS CHARACTER NO-UNDO.
 naturezas=getListaNatOperNotaMae().
 IF naturezas=? THEN naturezas="".
 policy=NEW JsonObject().
 policy:Add("naturezas_nota_mae",naturezas).
 policy:Add("cod_despesa_pis",CustoTaxId("cod_despesa_pis")).
 policy:Add("cod_despesa_cofins",CustoTaxId("cod_despesa_cofins")).
 RETURN policy.
END FUNCTION.
