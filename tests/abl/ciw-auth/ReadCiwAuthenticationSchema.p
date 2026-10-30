USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE result AS JsonObject NO-UNDO.
DEFINE VARIABLE fieldList AS JsonArray NO-UNDO.
DEFINE VARIABLE item AS JsonObject NO-UNDO.
FIND FIRST espec._File WHERE espec._File._File-Name="user-web" NO-LOCK.
result=NEW JsonObject(). fieldList=NEW JsonArray().
FOR EACH espec._Field WHERE espec._Field._File-recid=RECID(espec._File) NO-LOCK:
 IF LOOKUP(espec._Field._Field-Name,"Login,senha,ativo")=0 THEN NEXT.
 item=NEW JsonObject(). item:Add("name",espec._Field._Field-Name).
 item:Add("type",espec._Field._Data-Type). item:Add("extent",espec._Field._Extent).
 fieldList:Add(item).
END.
result:Add("database","espec"). result:Add("table","user-web"). result:Add("fields",fieldList).
result:Add("databaseCodepage",DBCODEPAGE("espec")).
result:WriteFile("ciw-auth-schema.json",TRUE).
QUIT.
