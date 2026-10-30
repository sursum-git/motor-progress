/* Test-only transactional provider; never publish. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE INPUT PARAMETER phChild AS HANDLE NO-UNDO.
DEFINE VARIABLE cMode AS CHARACTER NO-UNDO INITIAL "ok".
PROCEDURE SetMode:
 DEFINE INPUT PARAMETER c AS CHARACTER NO-UNDO.
 cMode=c.
END PROCEDURE.
PROCEDURE GetCapabilities:
 DEFINE OUTPUT PARAMETER o AS JsonObject NO-UNDO.
 o=NEW JsonObject(). o:Add("contract","container-rules-v1"). o:Add("onUpdate",cMode<>"unsupported"). o:Add("beforeDelete",cMode<>"unsupported").
END PROCEDURE.
PROCEDURE OnUpdate:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE a AS JsonArray NO-UNDO.
 DEFINE VARIABLE change AS JsonObject NO-UNDO.
 DEFINE VARIABLE before AS JsonObject NO-UNDO.
 DEFINE VARIABLE after AS JsonObject NO-UNDO.
 DEFINE VARIABLE v AS INTEGER NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Provider outside transaction",1).
 phChild:FIND-FIRST() NO-ERROR.
 v=phChild:BUFFER-FIELD("valor"):BUFFER-VALUE.
 before=NEW JsonObject(). before:Add("valor",v).
 phChild:BUFFER-FIELD("valor"):BUFFER-VALUE=v + 1.
 IF cMode="fail" THEN UNDO, THROW NEW Progress.Lang.AppError("Forced provider error after child write",1).
 after=NEW JsonObject(). after:Add("valor",v + 1).
 change=NEW JsonObject(). change:Add("resource","despesas_container"). change:Add("operation","update"). change:Add("recordId",777).
 change:Add("before",before). change:Add("after",after).
 a=NEW JsonArray(). a:Add(change).
 result=NEW JsonObject(). result:Add("success",TRUE).
 IF cMode="invalid-audit" THEN result:Add("changes","invalid"). ELSE result:Add("changes",a).
 IF cMode="warning" THEN DO: a=NEW JsonArray(). a:Add("IPI preservado conforme regra fiscal."). result:Add("warnings",a). END.
 IF cMode="invalid-warning" THEN DO: a=NEW JsonArray(). a:Add(NEW JsonObject()). result:Add("warnings",a). END.
END PROCEDURE.
PROCEDURE BeforeDelete:
 DEFINE INPUT PARAMETER h AS HANDLE NO-UNDO.
 DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO.
 DEFINE OUTPUT PARAMETER result AS JsonObject NO-UNDO.
 DEFINE VARIABLE a AS JsonArray NO-UNDO.
 DEFINE VARIABLE change AS JsonObject NO-UNDO.
 DEFINE VARIABLE before AS JsonObject NO-UNDO.
 IF NOT TRANSACTION THEN UNDO, THROW NEW Progress.Lang.AppError("Provider outside transaction",1).
 IF cMode="blocked" THEN UNDO, THROW NEW Progress.Lang.AppError("Commercial dependency blocks before any child change",1).
 phChild:FIND-FIRST() NO-ERROR.
 before=NEW JsonObject(). before:Add("valor",INTEGER(phChild:BUFFER-FIELD("valor"):BUFFER-VALUE)).
 phChild:BUFFER-DELETE().
 IF cMode="fail" THEN UNDO, THROW NEW Progress.Lang.AppError("Forced delete error after child removal",1).
 change=NEW JsonObject(). change:Add("resource","despesas_container"). change:Add("operation","delete"). change:Add("recordId",777). change:Add("before",before). change:Add("after",NEW JsonObject()).
 a=NEW JsonArray(). a:Add(change).
 result=NEW JsonObject(). result:Add("success",TRUE). result:Add("changes",a).
END PROCEDURE.
