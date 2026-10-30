/* Fronteira tipada: apenas criterios conhecidos, sem acesso a banco. */
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esbo/boSaldoPV.i}
DEFINE INPUT PARAMETER requestJSON AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttFiltroSaldoPV.
DEFINE OUTPUT PARAMETER TABLE FOR ttSelecaoSaldoPV.
DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE selectionNames AS CHARACTER EXTENT NO-UNDO.
DEFINE VARIABLE nameField AS CHARACTER NO-UNDO.
DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
DEFINE VARIABLE rows AS JsonArray NO-UNDO.
DEFINE VARIABLE rowJSON AS JsonObject NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE j AS INTEGER NO-UNDO.
DEFINE VARIABLE loginAlias AS CHARACTER NO-UNDO.
DEFINE VARIABLE loginValue AS CHARACTER NO-UNDO.
IF NOT VALID-OBJECT(requestJSON) THEN UNDO, THROW NEW AppError("Informe um objeto JSON",0).
CREATE ttFiltroSaldoPV.
names = requestJSON:GetNames().
DO i = 1 TO EXTENT(names):
 nameField = names[i].
 IF LOOKUP(nameField,"login,usuario,userName,requestUser",",") > 0 THEN DO:
  IF requestJSON:GetType(nameField) <> JsonDataType:STRING THEN
   UNDO, THROW NEW AppError(nameField + " deve ser texto",0).
  loginValue = TRIM(requestJSON:GetCharacter(nameField)).
  IF loginAlias <> "" AND loginValue <> ttFiltroSaldoPV.login THEN
   UNDO, THROW NEW AppError("Aliases de login divergentes",0).
  ASSIGN ttFiltroSaldoPV.login = loginValue loginAlias = nameField.
  NEXT.
 END.
 IF nameField = "selecoes":U THEN NEXT.
 /* Contexto de usuario sempre e resolvido no servidor. */
 IF nameField = "tipoUsuario":U OR nameField = "representante":U THEN
  UNDO, THROW NEW AppError(nameField + " e determinado pelo cadastro do usuario",0).
 fieldHandle = BUFFER ttFiltroSaldoPV:HANDLE:BUFFER-FIELD(nameField) NO-ERROR.
 IF NOT VALID-HANDLE(fieldHandle) THEN
  UNDO, THROW NEW AppError("Parametro desconhecido: " + nameField,0).
 RUN assignField(requestJSON, nameField, fieldHandle).
END.
IF ttFiltroSaldoPV.login = "" THEN UNDO, THROW NEW AppError("Informe login ou usuario",0).
IF NOT requestJSON:Has("selecoes") THEN RETURN.
IF requestJSON:GetType("selecoes") <> JsonDataType:ARRAY THEN
 UNDO, THROW NEW AppError("selecoes deve ser um array",0).
rows = requestJSON:GetJsonArray("selecoes").
DO i = 1 TO rows:Length:
 IF rows:GetType(i) <> JsonDataType:OBJECT THEN UNDO, THROW NEW AppError("Cada selecao deve ser objeto",0).
 rowJSON = rows:GetJsonObject(i).
 CREATE ttSelecaoSaldoPV.
 selectionNames = rowJSON:GetNames().
 DO j = 1 TO EXTENT(selectionNames):
  nameField = selectionNames[j].
  fieldHandle = BUFFER ttSelecaoSaldoPV:HANDLE:BUFFER-FIELD(nameField) NO-ERROR.
  IF NOT VALID-HANDLE(fieldHandle) THEN UNDO, THROW NEW AppError("Campo de selecao desconhecido: " + nameField,0).
  RUN assignField(rowJSON, nameField, fieldHandle).
 END.
 IF LOOKUP(ttSelecaoSaldoPV.tipo,"ITEM,REF,ESTAB,LOCAL,CONTAINER,LIQUIDACAO,PRECO,CONTAINER_A_DEFINIR") = 0 THEN
  UNDO, THROW NEW AppError("Tipo de selecao invalido",0).
END.

PROCEDURE assignField:
 DEFINE INPUT PARAMETER sourceJSON AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER propertyName AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER targetField AS HANDLE NO-UNDO.
 DEFINE VARIABLE rawNumber AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE intNumber AS INTEGER NO-UNDO.
 DEFINE VARIABLE decNumber AS DECIMAL NO-UNDO.
 IF sourceJSON:IsNull(propertyName) THEN DO:
  IF targetField:DATA-TYPE = "DECIMAL"
   AND LOOKUP(propertyName,"gramaturaIni,gramaturaFim,pesoLiquidoIni,pesoLiquidoFim,maximoKG,maximoMT") > 0 THEN DO:
   targetField:BUFFER-VALUE = ?. RETURN.
  END.
  UNDO, THROW NEW AppError(propertyName + " nao aceita null",0).
 END.
 CASE targetField:DATA-TYPE:
  WHEN "CHARACTER" THEN DO:
   IF sourceJSON:GetType(propertyName) <> JsonDataType:STRING THEN
    UNDO, THROW NEW AppError(propertyName + " deve ser texto",0).
   targetField:BUFFER-VALUE = sourceJSON:GetCharacter(propertyName).
  END.
  WHEN "LOGICAL" THEN DO:
   IF sourceJSON:GetType(propertyName) <> JsonDataType:BOOLEAN THEN
    UNDO, THROW NEW AppError(propertyName + " deve ser booleano",0).
   targetField:BUFFER-VALUE = sourceJSON:GetLogical(propertyName).
  END.
  WHEN "INTEGER" THEN DO:
   IF sourceJSON:GetType(propertyName) <> JsonDataType:NUMBER THEN
    UNDO, THROW NEW AppError(propertyName + " deve ser inteiro",0).
   rawNumber = STRING(sourceJSON:GetJsonText(propertyName)).
   DO k = 1 TO LENGTH(rawNumber):
    IF k = 1 AND SUBSTRING(rawNumber,k,1) = "-" THEN NEXT.
    IF INDEX("0123456789",SUBSTRING(rawNumber,k,1)) = 0 THEN
     UNDO, THROW NEW AppError(propertyName + " deve ser inteiro sem fracao ou expoente",0).
   END.
   intNumber = INTEGER(rawNumber) NO-ERROR.
   IF ERROR-STATUS:ERROR OR intNumber = ? THEN UNDO, THROW NEW AppError(propertyName + " fora do intervalo INTEGER",0).
   targetField:BUFFER-VALUE = intNumber.
  END.
  WHEN "DECIMAL" THEN DO:
   IF sourceJSON:GetType(propertyName) <> JsonDataType:NUMBER THEN
    UNDO, THROW NEW AppError(propertyName + " deve ser numero",0).
   decNumber = sourceJSON:GetDecimal(propertyName).
   targetField:BUFFER-VALUE = decNumber.
  END.
  OTHERWISE UNDO, THROW NEW AppError("Tipo de parametro nao suportado",0).
 END CASE.
END PROCEDURE.
