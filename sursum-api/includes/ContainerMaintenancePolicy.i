/* Include after official parametros_ima.i and ContainerCustoBoundary.i.
   Direct NO-LOCK IMA access on every invocation. No retained session policy. */
FUNCTION ContainerMaintenancePolicy RETURNS JsonObject (loginValue AS CHARACTER):
 DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
 DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
 IF loginValue=? OR TRIM(loginValue)="" OR LENGTH(loginValue)>128 THEN UNDO, THROW NEW Progress.Lang.AppError("Usuario autenticado invalido.",1).
 resultValue=NEW JsonObject(). actorValue=NEW JsonObject(). actorValue:Add("login",loginValue).
 resultValue:Add("actor",actorValue). resultValue:Add("usuario_id",0).
 resultValue:Add("despesa_distr_custo",CustoTaxId("despesa_distr_custo")).
 RETURN resultValue.
END FUNCTION.
FUNCTION ContainerCloseTypes RETURNS JsonArray ():
 DEFINE VARIABLE rawValue AS CHARACTER NO-UNDO.
 DEFINE VARIABLE resultValue AS JsonArray NO-UNDO.
 DEFINE VARIABLE valueId AS INTEGER NO-UNDO.
 DEFINE VARIABLE n AS INTEGER NO-UNDO.
 DEFINE VARIABLE j AS INTEGER NO-UNDO.
 rawValue=buscarParametroIma("tipo_versao_valida_nf","4,5").
 IF rawValue=? OR rawValue="" OR NUM-ENTRIES(rawValue)>100 THEN UNDO, THROW NEW Progress.Lang.AppError("Tipos de versao IMA invalidos.",1).
 resultValue=NEW JsonArray().
 DO n=1 TO NUM-ENTRIES(rawValue):
  valueId=CustoInteger(TRIM(ENTRY(n,rawValue)),FALSE).
  IF valueId=? THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de versao IMA invalido.",1).
  DO j=1 TO resultValue:Length: IF resultValue:GetInteger(j)=valueId THEN UNDO, THROW NEW Progress.Lang.AppError("Tipo de versao IMA repetido.",1). END.
  resultValue:Add(valueId).
 END.
 RETURN resultValue.
END FUNCTION.
