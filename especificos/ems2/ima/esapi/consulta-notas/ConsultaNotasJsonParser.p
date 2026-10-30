/* Valida exclusivamente propriedades da raiz; nao consulta nem grava banco. */
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.AppError.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esapi/consulta-notas/ttFiltroDevolucoes.i}
DEFINE INPUT PARAMETER requestJSON AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttFiltroDevolucoes.
DEFINE OUTPUT PARAMETER login AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pagina AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER filtro AS CHARACTER NO-UNDO.
DEFINE VARIABLE names AS CHARACTER NO-UNDO.
DEFINE VARIABLE fieldName AS CHARACTER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE requestText AS LONGCHAR NO-UNDO.
FUNCTION textValue RETURNS CHARACTER (n AS CHARACTER, fallback AS CHARACTER) FORWARD.
FUNCTION intValue RETURNS INTEGER (n AS CHARACTER) FORWARD.
FUNCTION dateValue RETURNS DATE (n AS CHARACTER) FORWARD.
IF NOT VALID-OBJECT(requestJSON) THEN UNDO, THROW NEW AppError("Informe um JsonObject de entrada",0).
/* Valida tambem aliases nao selecionados, para nao esconder metadata mal tipada. */
names = "login,usuario,requestUser,userName".
DO i = 1 TO NUM-ENTRIES(names):
 fieldName = ENTRY(i,names).
 IF requestJSON:Has(fieldName) THEN textValue(fieldName, "").
END.
login = TRIM(textValue("login", textValue("usuario", textValue("userName", textValue("requestUser", ""))))).
IF login = "" THEN UNDO, THROW NEW AppError("Informe login ou usuario",0).
pagina = textValue("pagina", "consulta-notas-fiscais-wp").
filtro = textValue("filtro", "").
IF filtro = "" THEN DO:
 requestJSON:Write(requestText).
 filtro = STRING(requestText).
END.
CREATE ttFiltroDevolucoes.
ASSIGN ttFiltroDevolucoes.empresa = textValue("empresa", "")
 ttFiltroDevolucoes.estabel-de = textValue("estabIni", "")
 ttFiltroDevolucoes.estabel-ate = textValue("estabFim", "")
 ttFiltroDevolucoes.cliente-de = intValue("clienteIni")
 ttFiltroDevolucoes.cliente-ate = intValue("clienteFim")
 ttFiltroDevolucoes.nota-de = textValue("nrNotaIni", "")
 ttFiltroDevolucoes.nota-ate = textValue("nrNotaFim", "")
 ttFiltroDevolucoes.pedido-de = textValue("nrPedidoIni", "")
 ttFiltroDevolucoes.pedido-ate = textValue("nrPedidoFim", "")
 ttFiltroDevolucoes.representante-de = intValue("represIni")
 ttFiltroDevolucoes.representante-ate = intValue("represFim")
 ttFiltroDevolucoes.emissao-de = dateValue("dtEmisIni")
 ttFiltroDevolucoes.emissao-ate = dateValue("dtEmisFim").
IF (ttFiltroDevolucoes.estabel-de <> "" AND ttFiltroDevolucoes.estabel-ate <> "" AND ttFiltroDevolucoes.estabel-de > ttFiltroDevolucoes.estabel-ate)
 OR (ttFiltroDevolucoes.nota-de <> "" AND ttFiltroDevolucoes.nota-ate <> "" AND ttFiltroDevolucoes.nota-de > ttFiltroDevolucoes.nota-ate)
 OR (ttFiltroDevolucoes.pedido-de <> "" AND ttFiltroDevolucoes.pedido-ate <> "" AND ttFiltroDevolucoes.pedido-de > ttFiltroDevolucoes.pedido-ate)
 OR ttFiltroDevolucoes.cliente-de > ttFiltroDevolucoes.cliente-ate
 OR ttFiltroDevolucoes.representante-de > ttFiltroDevolucoes.representante-ate
 OR ttFiltroDevolucoes.emissao-de > ttFiltroDevolucoes.emissao-ate THEN
 UNDO, THROW NEW AppError("Intervalo inicial maior que final",0).
FUNCTION textValue RETURNS CHARACTER (n AS CHARACTER, fallback AS CHARACTER):
 IF NOT requestJSON:Has(n) THEN RETURN fallback.
 IF requestJSON:GetType(n) <> JsonDataType:STRING THEN UNDO, THROW NEW AppError(n + " deve ser texto",0).
 RETURN requestJSON:GetCharacter(n).
END FUNCTION.
FUNCTION intValue RETURNS INTEGER (n AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE v AS INTEGER NO-UNDO.
 IF NOT requestJSON:Has(n) THEN RETURN ?.
 IF requestJSON:GetType(n) <> JsonDataType:NUMBER THEN UNDO, THROW NEW AppError(n + " deve ser inteiro",0).
 c = STRING(requestJSON:GetJsonText(n)).
 DO k = 1 TO LENGTH(c):
  IF k = 1 AND SUBSTRING(c,k,1) = "-" THEN NEXT.
  IF INDEX("0123456789",SUBSTRING(c,k,1)) = 0 THEN UNDO, THROW NEW AppError(n + " deve ser inteiro",0).
 END.
 v = INTEGER(c) NO-ERROR.
 IF ERROR-STATUS:ERROR OR v = ? THEN UNDO, THROW NEW AppError(n + " fora do intervalo INTEGER",0).
 RETURN v.
END FUNCTION.
FUNCTION dateValue RETURNS DATE (n AS CHARACTER):
 DEFINE VARIABLE c AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 DEFINE VARIABLE d AS DATE NO-UNDO.
 IF NOT requestJSON:Has(n) THEN RETURN ?.
 c = textValue(n, "").
 IF LENGTH(c) <> 10 OR SUBSTRING(c,5,1) <> "-" OR SUBSTRING(c,8,1) <> "-" THEN UNDO, THROW NEW AppError(n + " deve usar YYYY-MM-DD",0).
 DO k = 1 TO 10:
  IF k = 5 OR k = 8 THEN NEXT.
  IF INDEX("0123456789",SUBSTRING(c,k,1)) = 0 THEN UNDO, THROW NEW AppError(n + " deve usar YYYY-MM-DD",0).
 END.
 d = DATE(INTEGER(SUBSTRING(c,6,2)),INTEGER(SUBSTRING(c,9,2)),INTEGER(SUBSTRING(c,1,4))) NO-ERROR.
 IF ERROR-STATUS:ERROR OR d = ? THEN UNDO, THROW NEW AppError(n + " data invalida",0).
 RETURN d.
END FUNCTION.

