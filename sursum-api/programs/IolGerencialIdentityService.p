BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER pcLogin AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER phSources AS HANDLE EXTENT 20 NO-UNDO.
DEFINE OUTPUT PARAMETER poScope AS JsonObject NO-UNDO.
DEFINE VARIABLE roleNumber AS INTEGER NO-UNDO.
DEFINE VARIABLE repNumber AS INTEGER NO-UNDO.
DEFINE VARIABLE hierarchyType AS INTEGER NO-UNDO.
DEFINE VARIABLE childNumber AS INTEGER NO-UNDO.
DEFINE VARIABLE cReps AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNames AS CHARACTER NO-UNDO.
DEFINE VARIABLE q AS HANDLE NO-UNDO.
DEFINE VARIABLE restrictionId AS INTEGER NO-UNDO.
DEFINE VARIABLE isRestricted AS LOGICAL NO-UNDO.
DEFINE VARIABLE isGeneral AS LOGICAL NO-UNDO.
{IolReadBuffers.i}
DO ON ERROR UNDO, THROW:
 IF pcLogin=? OR pcLogin="" OR LENGTH(pcLogin)>120 OR INDEX(pcLogin,CHR(10))>0 OR INDEX(pcLogin,CHR(13))>0 THEN
  UNDO, THROW NEW Progress.Lang.AppError("IOL_IDENTITY_REQUIRED",1).
 IF NOT FindRow(1,FieldName(1,"Login") + " = " + QUOTER(pcLogin)) THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_IDENTITY_INVALID",1).
 IF FieldHandle(1,"ativo"):BUFFER-VALUE<>TRUE THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_IDENTITY_INACTIVE",1).
 roleNumber=NumValue(1,"tp-usuario").
 IF LOOKUP(STRING(roleNumber),"2,3,4")=0 THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_FORBIDDEN",1).
 IF FindRow(3,FieldName(3,"nome-abrev") + " = " + QUOTER(pcLogin)) THEN repNumber=NumValue(3,"cod-rep").
 IF roleNumber=2 THEN DO:
  IF repNumber=0 OR NOT FindRow(2,FieldName(2,"login_usuario") + " = " + QUOTER(pcLogin) + " AND " + FieldName(2,"cod_grupo") + " = 2") THEN
   UNDO, THROW NEW Progress.Lang.AppError("IOL_FORBIDDEN",1).
  ASSIGN cReps=STRING(repNumber) cNames=pcLogin.
 END.
 ELSE DO:
  IF repNumber>0 THEN DO:
   IF FindRow(5,FieldName(5,"cod-rep") + " = " + STRING(repNumber)) THEN hierarchyType=NumValue(5,"tp-aplic-comis").
   IF roleNumber=3 AND hierarchyType=3 THEN DO:
   q=OpenRows(4,FieldName(4,"cod-rep") + " = " + STRING(repNumber)).
   DO WHILE NOT q:QUERY-OFF-END:
    childNumber=NumValue(4,"cod-depend").
    IF NOT FindRow(3,FieldName(3,"cod-rep") + " = " + STRING(childNumber)) THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_HIERARCHY_INVALID",1).
    IF LOOKUP(STRING(childNumber),cReps)=0 THEN DO:
     cReps=cReps + (IF cReps="" THEN "" ELSE ",") + STRING(childNumber).
     cNames=cNames + (IF cNames="" THEN "" ELSE ",") + TextValue(3,"nome-abrev").
    END.
    q:GET-NEXT().
   END.
   RUN CloseRows(q).
   END.
  END.
  /* Explicit per-user representative restrictions override the manager hierarchy. */
  IF FindRow(19,FieldName(19,"login") + " = " + QUOTER(pcLogin)) THEN DO:
   IF NumValue(19,"ind_segur_cli_ativo")=3 THEN DO:
    isRestricted=TRUE.
    restrictionId=NumValue(19,"restrs_clientes_usuario_id").
    ASSIGN cReps="" cNames="".
    q=OpenRows(20,FieldName(20,"restr_cliente_usuario_id") + " = " + STRING(restrictionId)).
    DO WHILE NOT q:QUERY-OFF-END:
     childNumber=NumValue(20,"cod_repres").
     IF NOT FindRow(3,FieldName(3,"cod-rep") + " = " + STRING(childNumber)) THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_HIERARCHY_INVALID",1).
     IF LOOKUP(STRING(childNumber),cReps)=0 THEN DO:
      cReps=cReps + (IF cReps="" THEN "" ELSE ",") + STRING(childNumber).
      cNames=cNames + (IF cNames="" THEN "" ELSE ",") + TextValue(3,"nome-abrev").
     END.
     q:GET-NEXT().
    END.
    RUN CloseRows(q).
    IF cReps="" THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_HIERARCHY_INVALID",1).
   END.
  END.
  /* General access only for a verified admin with no scoped hierarchy or restriction. */
  IF roleNumber=3 AND hierarchyType=3 AND cReps="" THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_HIERARCHY_INVALID",1).
  isGeneral=(cReps="" AND NOT isRestricted).
 END.
 poScope=NEW JsonObject().
 poScope:Add("login",pcLogin).
 poScope:Add("role",roleNumber).
 poScope:Add("representative",repNumber).
 poScope:Add("hierarchy_type",hierarchyType).
 poScope:Add("general",isGeneral).
 poScope:Add("representatives",cReps).
 poScope:Add("names",cNames).
 FINALLY: RUN ReleaseQueries. END FINALLY.
END.
