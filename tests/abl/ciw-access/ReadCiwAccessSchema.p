/* Somente dicionario. Nao le registros das tabelas de usuarios/permissoes. */
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE tableName AS CHARACTER NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE fieldList AS JsonArray NO-UNDO.
DEFINE VARIABLE indexes AS JsonArray NO-UNDO.
DEFINE VARIABLE indexFields AS JsonArray NO-UNDO.
DEFINE VARIABLE item AS JsonObject NO-UNDO.
DO n=1 TO 3:
 tableName=ENTRY(n,"user-web,usuarios_grupos,grupos_aplicacoes").
 FIND FIRST espec._File WHERE espec._File._File-Name=tableName NO-LOCK NO-ERROR.
 IF NOT AVAILABLE espec._File THEN UNDO,THROW NEW Progress.Lang.AppError("Dicionario CIW ausente",0).
 result=NEW JsonObject(). fieldList=NEW JsonArray(). indexes=NEW JsonArray().
 result:Add("database","espec"). result:Add("table",tableName).
 FOR EACH espec._Field WHERE espec._Field._File-recid=RECID(espec._File) NO-LOCK BY espec._Field._Order:
  item=NEW JsonObject(). item:Add("name",espec._Field._Field-Name).
  item:Add("type",espec._Field._Data-Type). item:Add("format",espec._Field._Format).
  item:Add("mandatory",espec._Field._Mandatory). item:Add("extent",espec._Field._Extent).
  fieldList:Add(item).
 END.
 FOR EACH espec._Index WHERE espec._Index._File-recid=RECID(espec._File) NO-LOCK:
  item=NEW JsonObject(). indexFields=NEW JsonArray().
  item:Add("name",espec._Index._Index-Name). item:Add("unique",espec._Index._Unique).
  item:Add("primary",RECID(espec._Index)=espec._File._Prime-Index).
  FOR EACH espec._Index-field WHERE espec._Index-field._Index-recid=RECID(espec._Index) NO-LOCK BY espec._Index-field._Index-Seq:
   FIND espec._Field WHERE RECID(espec._Field)=espec._Index-field._Field-recid NO-LOCK.
   indexFields:Add(espec._Field._Field-Name).
  END.
  item:Add("fields",indexFields). indexes:Add(item).
 END.
 result:Add("fields",fieldList). result:Add("indexes",indexes).
 result:WriteFile("schema-ciw-" + tableName + ".json",TRUE).
END.
QUIT.
