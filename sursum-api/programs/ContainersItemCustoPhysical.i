/* Helpers shared only by physical collection/closing. No financial formula. */
FUNCTION KeyId RETURNS INTEGER (objectData AS JsonObject,name AS CHARACTER):
 DEFINE VARIABLE valueId AS DECIMAL DECIMALS 10 NO-UNDO.
 IF objectData:GetType(name)<>JsonDataType:NUMBER THEN UNDO, THROW NEW Progress.Lang.AppError("ID JSON numerico obrigatorio: " + name,1).
 valueId=objectData:GetDecimal(name).
 IF valueId=? OR valueId<=0 OR valueId>2147483647 OR TRUNCATE(valueId,0)<>valueId THEN UNDO, THROW NEW Progress.Lang.AppError("ID inteiro positivo invalido: " + name,1).
 RETURN INTEGER(valueId).
END FUNCTION.
FUNCTION Flag RETURNS LOGICAL (objectData AS JsonObject,name AS CHARACTER):
 IF objectData:GetType(name)<>JsonDataType:BOOLEAN THEN UNDO, THROW NEW Progress.Lang.AppError("Boolean JSON obrigatorio: " + name,1).
 RETURN objectData:GetLogical(name).
END FUNCTION.
FUNCTION IntField RETURNS INTEGER (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 IF h:BUFFER-FIELD(name):DATA-TYPE<>"INTEGER" THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo inteiro fisico obrigatorio: " + name,1).
 valueId=h:BUFFER-FIELD(name):BUFFER-VALUE.
 IF valueId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Inteiro desconhecido: " + name,1).
 RETURN valueId.
END FUNCTION.
FUNCTION TextField RETURNS CHARACTER (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE valueText AS CHARACTER NO-UNDO.
 valueText=h:BUFFER-FIELD(name):BUFFER-VALUE.
 IF valueText=? THEN UNDO, THROW NEW Progress.Lang.AppError("Texto desconhecido: " + name,1).
 RETURN valueText.
END FUNCTION.
FUNCTION NumField RETURNS DECIMAL (h AS HANDLE,name AS CHARACTER):
 DEFINE VARIABLE valueNum AS DECIMAL DECIMALS 10 NO-UNDO.
 valueNum=h:BUFFER-FIELD(name):BUFFER-VALUE.
 IF valueNum=? THEN UNDO, THROW NEW Progress.Lang.AppError("Numero desconhecido: " + name,1).
 RETURN valueNum.
END FUNCTION.
FUNCTION NumText RETURNS CHARACTER (v AS INTEGER): RETURN TRIM(STRING(v,"->>>>>>>>>9")). END FUNCTION.
FUNCTION AblQuote RETURNS CHARACTER (valueText AS CHARACTER):
 DEFINE VARIABLE quoted AS CHARACTER NO-UNDO.
 IF valueText=? THEN UNDO, THROW NEW Progress.Lang.AppError("Texto de chave desconhecido.",1).
 quoted=REPLACE(valueText,CHR(126),CHR(126) + CHR(126)).
 quoted=REPLACE(quoted,CHR(34),CHR(126) + CHR(34)).
 quoted=REPLACE(quoted,CHR(10),CHR(126) + "n"). quoted=REPLACE(quoted,CHR(13),CHR(126) + "r"). quoted=REPLACE(quoted,CHR(9),CHR(126) + "t").
 RETURN CHR(34) + quoted + CHR(34).
END FUNCTION.
PROCEDURE Closed:
 DEFINE INPUT PARAMETER objectData AS JsonObject NO-UNDO.
 DEFINE INPUT PARAMETER allowed AS CHARACTER NO-UNDO.
 DEFINE VARIABLE names AS CHARACTER EXTENT NO-UNDO.
 DEFINE VARIABLE keyName AS CHARACTER CASE-SENSITIVE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 DEFINE VARIABLE validName AS LOGICAL NO-UNDO.
 IF NOT VALID-OBJECT(objectData) THEN UNDO, THROW NEW Progress.Lang.AppError("Objeto JSON obrigatorio.",1).
 names=objectData:GetNames().
 DO n=1 TO EXTENT(names):
  keyName=names[n]. validName=FALSE.
  DO j=1 TO NUM-ENTRIES(allowed): IF keyName=ENTRY(j,allowed) THEN validName=TRUE. END.
  IF NOT validName THEN UNDO, THROW NEW Progress.Lang.AppError("Campo nao permitido: " + keyName,1).
 END.
END PROCEDURE.
FUNCTION ReadFound RETURNS LOGICAL (h AS HANDLE,conditionText AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE foundRow AS LOGICAL NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 foundRow=h:FIND-FIRST("WHERE " + conditionText,lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED THEN DO: failureCode="ITEM_COST_BUSY". UNDO, THROW NEW Progress.Lang.AppError("Registro em uso; tente novamente.",1). END.
 DO n=1 TO ERROR-STATUS:NUM-MESSAGES:
  IF ERROR-STATUS:GET-NUMBER(n)<>565 THEN UNDO, THROW NEW Progress.Lang.AppError("Falha na leitura fisica; nao equivale a ausencia.",1).
 END.
 RETURN foundRow.
END FUNCTION.
FUNCTION QueryRows RETURNS HANDLE (h AS HANDLE,conditionText AS CHARACTER,ordering AS CHARACTER,lockMode AS INTEGER):
 DEFINE VARIABLE q AS HANDLE NO-UNDO.
 CREATE QUERY q. q:SET-BUFFERS(h).
 IF NOT q:QUERY-PREPARE("FOR EACH " + h:NAME + " WHERE " + conditionText + " " + ordering) THEN DO: DELETE OBJECT q. UNDO, THROW NEW Progress.Lang.AppError("Consulta fisica fixa invalida.",1). END.
 q:QUERY-OPEN(). q:GET-FIRST(lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED OR ERROR-STATUS:ERROR THEN DO:
  failureCode="ITEM_COST_BUSY". q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q.
  UNDO, THROW NEW Progress.Lang.AppError("Leitura de conjunto recusada; nao equivale a conjunto vazio.",1).
 END.
 RETURN q.
END FUNCTION.
PROCEDURE NextRow:
 DEFINE INPUT PARAMETER q AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER lockMode AS INTEGER NO-UNDO.
 q:GET-NEXT(lockMode,NO-WAIT) NO-ERROR.
 IF h:LOCKED OR ERROR-STATUS:ERROR THEN DO: failureCode="ITEM_COST_BUSY". UNDO, THROW NEW Progress.Lang.AppError("Conjunto em uso; nenhuma ausencia inferida.",1). END.
END PROCEDURE.
PROCEDURE CloseQuery:
 DEFINE INPUT-OUTPUT PARAMETER q AS HANDLE NO-UNDO.
 IF VALID-HANDLE(q) THEN DO: q:QUERY-CLOSE() NO-ERROR. DELETE OBJECT q NO-ERROR. END.
 q=?.
END PROCEDURE.
FUNCTION PhysicalJson RETURNS JsonObject (h AS HANDLE,fieldList AS CHARACTER):
 DEFINE VARIABLE objectData AS JsonObject NO-UNDO.
 DEFINE VARIABLE fieldHandle AS HANDLE NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE name AS CHARACTER NO-UNDO.
 DEFINE VARIABLE iv AS INTEGER NO-UNDO.
 DEFINE VARIABLE dv AS DECIMAL DECIMALS 10 NO-UNDO.
 DEFINE VARIABLE cv AS CHARACTER NO-UNDO.
 DEFINE VARIABLE lv AS LOGICAL NO-UNDO.
 DEFINE VARIABLE dateValue AS DATE NO-UNDO.
 DEFINE VARIABLE timeValue AS DATETIME NO-UNDO.
 objectData=NEW JsonObject().
 DO n=1 TO NUM-ENTRIES(fieldList):
  name=ENTRY(n,fieldList). fieldHandle=h:BUFFER-FIELD(name).
  IF fieldHandle:EXTENT<>0 THEN UNDO, THROW NEW Progress.Lang.AppError("Campo fisico escalar obrigatorio.",1).
  IF fieldHandle:BUFFER-VALUE=? THEN objectData:AddNull(name).
  ELSE CASE fieldHandle:DATA-TYPE:
   WHEN "INTEGER" THEN DO: iv=fieldHandle:BUFFER-VALUE. objectData:Add(name,iv). END.
   WHEN "DECIMAL" THEN DO: dv=fieldHandle:BUFFER-VALUE. objectData:Add(name,dv). END.
   WHEN "CHARACTER" THEN DO: cv=fieldHandle:BUFFER-VALUE. objectData:Add(name,cv). END.
   WHEN "LOGICAL" THEN DO: lv=fieldHandle:BUFFER-VALUE. objectData:Add(name,lv). END.
   WHEN "DATE" THEN DO: dateValue=fieldHandle:BUFFER-VALUE. objectData:Add(name,dateValue). END.
   WHEN "DATETIME" THEN DO: timeValue=fieldHandle:BUFFER-VALUE. objectData:Add(name,timeValue). END.
   OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Tipo fisico nao suportado.",1).
  END CASE.
 END.
 RETURN objectData.
END FUNCTION.
