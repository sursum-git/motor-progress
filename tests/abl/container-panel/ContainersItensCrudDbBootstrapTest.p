/* Read-only connected-DB regression for allocation buffer construction.
   phItems is a real espec DB buffer; the parent is deliberately an EMPTY TT,
   guaranteeing 404 before any business query/mutation/sequence/effect. No HTTP.
   Run only with espec already connected. This program never CONNECTs a DB. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttAbsentMaster FIELD nr-container AS INTEGER INDEX pk IS UNIQUE PRIMARY nr-container.
DEFINE VARIABLE h AS HANDLE EXTENT 7 NO-UNDO.
DEFINE VARIABLE tables AS CHARACTER NO-UNDO INITIAL "pp-container,itens_container,itens_proc_compra,procs_compra,descontos_importacao,item_container_custos,pp-it-container".
DEFINE VARIABLE requestValue AS JsonObject NO-UNDO.
DEFINE VARIABLE policyValue AS JsonObject NO-UNDO.
DEFINE VARIABLE responseValue AS JsonObject NO-UNDO.
DEFINE VARIABLE actorValue AS JsonObject NO-UNDO.
DEFINE VARIABLE valuesValue AS JsonObject NO-UNDO.
DEFINE VARIABLE n AS INTEGER NO-UNDO.
DEFINE VARIABLE sequenceCalls AS INTEGER NO-UNDO.
DEFINE VARIABLE effectsCalls AS INTEGER NO-UNDO.
IF NOT CONNECTED("espec") THEN UNDO, THROW NEW Progress.Lang.AppError("Connected espec required for DB buffer bootstrap regression; no connection attempted.",1).
DO ON ERROR UNDO, THROW:
 h[1]=BUFFER ttAbsentMaster:HANDLE.
 DO n=2 TO 7: CREATE BUFFER h[n] FOR TABLE ("espec." + ENTRY(n,tables)) BUFFER-NAME ("bItemsDbBootstrap" + STRING(n)). END.
 IF VALID-HANDLE(h[2]:TABLE-HANDLE) THEN UNDO, THROW NEW Progress.Lang.AppError("Regression requires a DB source rather than a temp-table source.",1).
 requestValue=NEW JsonObject(). requestValue:Add("operation","create"). requestValue:Add("container_id",123).
 valuesValue=NEW JsonObject(). valuesValue:Add("item_proc_compra_id",1). valuesValue:Add("qt_alocada",1). requestValue:Add("values",valuesValue).
 policyValue=NEW JsonObject(). actorValue=NEW JsonObject(). actorValue:Add("login","readonly-bootstrap"). policyValue:Add("actor",actorValue).
 RUN ContainersItensCrudService.r(h[1],h[2],h[3],h[4],h[5],h[6],h[7],THIS-PROCEDURE,policyValue,requestValue,OUTPUT responseValue).
 IF responseValue:GetLogical("success") OR responseValue:GetJsonObject("error"):GetCharacter("code")<>"CONTAINER_NOT_FOUND" OR responseValue:GetJsonObject("error"):GetInteger("status")<>404 THEN
  UNDO, THROW NEW Progress.Lang.AppError("DB sibling must initialize before safe 404, instead of error7333: " + STRING(responseValue:GetJsonText()),1).
 IF sequenceCalls<>0 OR effectsCalls<>0 OR responseValue:Has("audit") OR responseValue:Has("pendingChanges") THEN UNDO, THROW NEW Progress.Lang.AppError("DB bootstrap must not reach sequences/effects/audit.",1).
 OUTPUT TO VALUE("containers-itens-db-bootstrap-tests-" + SESSION:NUMERIC-FORMAT + ".log").
 PUT UNFORMATTED "PASS 3 checks; real DB items buffer; empty TT parent; zero business/sequence/effect." SKIP. OUTPUT CLOSE.
 FINALLY:
  DO n=2 TO 7: IF VALID-HANDLE(h[n]) THEN DELETE OBJECT h[n] NO-ERROR. END.
 END FINALLY.
END.
PROCEDURE GetCapabilities:
 DEFINE OUTPUT PARAMETER caps AS JsonObject NO-UNDO.
 caps=NEW JsonObject(). caps:Add("contract","container-item-rules-v1"). caps:Add("afterChange",TRUE). caps:Add("nextItemId",TRUE).
END PROCEDURE.
PROCEDURE NextItemId:
 DEFINE OUTPUT PARAMETER valueId AS INTEGER NO-UNDO.
 sequenceCalls=sequenceCalls + 1.
 UNDO, THROW NEW Progress.Lang.AppError("Forbidden sequence callback in read-only bootstrap.",1).
END PROCEDURE.
PROCEDURE AfterChange:
 DEFINE INPUT PARAMETER master AS HANDLE NO-UNDO. DEFINE INPUT PARAMETER ctx AS JsonObject NO-UNDO. DEFINE OUTPUT PARAMETER resultValue AS JsonObject NO-UNDO.
 effectsCalls=effectsCalls + 1.
 UNDO, THROW NEW Progress.Lang.AppError("Forbidden effects callback in read-only bootstrap.",1).
END PROCEDURE.
