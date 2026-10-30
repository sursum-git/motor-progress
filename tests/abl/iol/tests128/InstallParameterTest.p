BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE VARIABLE cError AS CHARACTER NO-UNDO.
IF NUM-DBS<>1 OR INDEX(PDBNAME(1),"aggregate-fixture")=0 THEN RETURN ERROR "FIXTURE_DATABASE_REQUIRED".
IF CAN-FIND(FIRST espec.im-param) THEN RETURN ERROR "FIXTURE_PARAMETER_TABLE_NOT_EMPTY".
DO TRANSACTION ON ERROR UNDO, THROW:
 CREATE espec.im-param.
 ASSIGN espec.im-param.cod-param="__ZTSC_IOL_ENGINE_KEEP__" espec.im-param.val-param="keep".
 RELEASE espec.im-param.
 RUN InstallIolEngineParameter.r.
 FIND FIRST espec.im-param WHERE espec.im-param.cod-param="iol_gerencial_engine" NO-LOCK.
 IF espec.im-param.val-param<>"12.2" THEN RETURN ERROR "FAIL initial engine value".
 FIND CURRENT espec.im-param EXCLUSIVE-LOCK.
 ASSIGN espec.im-param.tp-param=7 espec.im-param.agrup_im_param_id=2147000019.
 RELEASE espec.im-param.
 RUN InstallIolEngineParameter.r.
 FIND FIRST espec.im-param WHERE espec.im-param.cod-param="iol_gerencial_engine" NO-LOCK.
 IF espec.im-param.val-param<>"12.2" OR espec.im-param.tp-param<>7 OR espec.im-param.agrup_im_param_id<>2147000019 THEN
  RETURN ERROR "FAIL existing parameter changed".
 FIND CURRENT espec.im-param EXCLUSIVE-LOCK. espec.im-param.val-param="12.8". RELEASE espec.im-param.
 DO ON ERROR UNDO, THROW:
  RUN InstallIolEngineParameter.r.
  CATCH e AS Progress.Lang.Error: cError=e:GetMessage(1). END CATCH.
 END.
 IF cError<>"IOL_PARAMETER_EXISTING_VALUE_PRESERVED" THEN RETURN ERROR "FAIL existing value not rejected".
 FIND FIRST espec.im-param WHERE espec.im-param.cod-param="iol_gerencial_engine" NO-LOCK.
 IF espec.im-param.val-param<>"12.8" THEN RETURN ERROR "FAIL existing value overwritten".
 FIND FIRST espec.im-param WHERE espec.im-param.cod-param="__ZTSC_IOL_ENGINE_KEEP__" NO-LOCK.
 IF espec.im-param.val-param<>"keep" THEN RETURN ERROR "FAIL unrelated parameter changed".
 RELEASE espec.im-param.
 UNDO, LEAVE.
END.
IF CAN-FIND(FIRST espec.im-param) THEN RETURN ERROR "FAIL parameter fixture cleanup".
OUTPUT TO VALUE("parameter-install-" + SESSION:NUMERIC-FORMAT + ".log").
PUT UNFORMATTED "PASS parameter install checks=5 cleanup=rollback" SKIP.
OUTPUT CLOSE.
