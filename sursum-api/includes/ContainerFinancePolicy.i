/* Include after parametros_ima.i. Every invocation reads im-param directly. */
FUNCTION ContainerSpecies RETURNS JsonArray (pcRaw AS CHARACTER, pcDefault AS CHARACTER):
 DEFINE VARIABLE list AS JsonArray NO-UNDO.
 DEFINE VARIABLE token AS CHARACTER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 IF pcRaw = ? OR TRIM(pcRaw) = "" THEN pcRaw = pcDefault.
 IF LENGTH(pcRaw) > 2000 OR NUM-ENTRIES(pcRaw) > 100 THEN
  UNDO, THROW NEW Progress.Lang.AppError("Configuracao de especies invalida.",0).
 list = NEW JsonArray().
 DO n = 1 TO NUM-ENTRIES(pcRaw):
  token = TRIM(ENTRY(n,pcRaw)).
  IF LENGTH(token) >= 2 AND SUBSTRING(token,1,1) = "'" AND SUBSTRING(token,LENGTH(token),1) = "'" THEN
   token = SUBSTRING(token,2,LENGTH(token) - 2).
  IF LENGTH(token) < 1 OR LENGTH(token) > 12 THEN UNDO, THROW NEW Progress.Lang.AppError("Configuracao de especies invalida.",0).
  DO k = 1 TO LENGTH(token):
   IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(token,k,1)) = 0 THEN
    UNDO, THROW NEW Progress.Lang.AppError("Configuracao de especies invalida.",0).
  END.
  list:Add(token).
 END.
 RETURN list.
END FUNCTION.
FUNCTION ContainerFinancePolicy RETURNS JsonObject ():
 DEFINE VARIABLE policy AS JsonObject NO-UNDO.
 policy = NEW JsonObject().
 policy:Add("adiantamentos",ContainerSpecies(buscarParametroIma("especs_adiant_importacao",""),"'AF'")).
 policy:Add("titulos",ContainerSpecies(buscarParametroIma("especs_tit_importacao",""),"'DI'")).
 RETURN policy.
END FUNCTION.
