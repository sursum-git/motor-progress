/* New marked records in an isolated fixture database; transaction is rolled back. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE oScope AS JsonObject NO-UNDO.
DEFINE VARIABLE dValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE iChecks AS INTEGER NO-UNDO.
DEFINE VARIABLE cError AS CHARACTER NO-UNDO.
IF NUM-DBS<>1 OR INDEX(PDBNAME(1),"aggregate-fixture")=0 THEN RETURN ERROR "FIXTURE_DATABASE_REQUIRED".
OUTPUT TO VALUE("aggregate128-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "Runtime " PROVERSION SKIP.
DO TRANSACTION ON ERROR UNDO, THROW:
 CREATE espec.metas_repres.
 ASSIGN espec.metas_repres.cod_repres=2147000001 espec.metas_repres.mes=10 espec.metas_repres.ano=2026
  espec.metas_repres.vl_meta=100.25 espec.metas_repres.vl_meta_quinz=50.5.
 CREATE espec.metas_repres.
 ASSIGN espec.metas_repres.cod_repres=2147000002 espec.metas_repres.mes=10 espec.metas_repres.ano=2026
  espec.metas_repres.vl_meta=200.75 espec.metas_repres.vl_meta_quinz=100.
 CREATE espec.metas_repres.
 ASSIGN espec.metas_repres.cod_repres=2147000001 espec.metas_repres.mes=9 espec.metas_repres.ano=2026
  espec.metas_repres.vl_meta=9999 espec.metas_repres.vl_meta_quinz=9999.
 CREATE espec.peds_web. ASSIGN espec.peds_web.login="ZTSC_AGG128_A" espec.peds_web.ind_sit_ped_web=8.
 CREATE espec.peds_web. ASSIGN espec.peds_web.login="ZTSC_AGG128_B" espec.peds_web.ind_sit_ped_web=8.
 CREATE espec.peds_web. ASSIGN espec.peds_web.login="ZTSC_AGG128_A" espec.peds_web.ind_sit_ped_web=1.
 RELEASE espec.metas_repres. RELEASE espec.peds_web.
 oScope=NEW JsonObject(). oScope:Add("general",FALSE).
 oScope:Add("representatives","2147000001"). oScope:Add("names","ZTSC_AGG128_A").
 RUN Check("vl_meta",TRUE,100.25).
 RUN Check("vl_meta_quinz",TRUE,50.5).
 RUN Check("vl_meta",FALSE,301).
 RUN Check("vl_meta_quinz",FALSE,150.5).
 RUN Check("pending",TRUE,1).
 oScope:Set("general",TRUE).
 RUN Check("vl_meta",TRUE,301).
 RUN Check("pending",TRUE,2).
 oScope:Set("general",FALSE). oScope:Set("representatives","2147000003"). oScope:Set("names","").
 RUN Check("vl_meta",TRUE,0).
 RUN Check("vl_meta_quinz",TRUE,0).
 RUN Check("pending",TRUE,0).
 oScope:Set("representatives","2147000001").
 CREATE espec.metas_repres.
 ASSIGN espec.metas_repres.cod_repres=2147000001 espec.metas_repres.mes=10 espec.metas_repres.ano=2026
  espec.metas_repres.vl_meta=? espec.metas_repres.vl_meta_quinz=?.
 RELEASE espec.metas_repres.
 DO ON ERROR UNDO, THROW:
  RUN IolGerencialAggregate128.p("vl_meta",oScope,DATE(10,19,2026),TRUE,OUTPUT dValue).
  CATCH e AS Progress.Lang.Error: cError=e:GetMessage(1). END CATCH.
 END.
 IF cError<>"IOL_DATA_INVALID" THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL unknown must be rejected",1).
 iChecks=iChecks + 1.
 UNDO, LEAVE.
END.
IF CAN-FIND(FIRST espec.metas_repres) OR CAN-FIND(FIRST espec.peds_web) THEN
 UNDO, THROW NEW Progress.Lang.AppError("FAIL fixture records not rolled back",1).
PUT UNFORMATTED "PASS aggregate128 checks=" iChecks " cleanup=rollback" SKIP.
OUTPUT CLOSE.
PROCEDURE Check:
 DEFINE INPUT PARAMETER pcOperation AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER plScoped AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER pdExpected AS DECIMAL NO-UNDO.
 RUN IolGerencialAggregate128.p(pcOperation,oScope,DATE(10,19,2026),plScoped,OUTPUT dValue).
 IF dValue<>pdExpected THEN UNDO, THROW NEW Progress.Lang.AppError("FAIL aggregate " + pcOperation + " actual=" + STRING(dValue),1).
 iChecks=iChecks + 1.
END PROCEDURE.
