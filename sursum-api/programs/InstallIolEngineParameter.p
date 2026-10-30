/* Explicit, idempotent install of one authorized configuration record. No HTTP route.
   Compile on OE12.2/.42. Existing records and values are never overwritten. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE BUFFER bIolEngineParameter FOR espec.im-param.
DEFINE VARIABLE lCreated AS LOGICAL NO-UNDO.
IF SESSION:PARAMETER<>"install-iol-engine-12.2" THEN
 UNDO, THROW NEW Progress.Lang.AppError("IOL_PARAMETER_INSTALL_CONFIRMATION_REQUIRED",1).
DO TRANSACTION ON ERROR UNDO, THROW:
 FIND FIRST bIolEngineParameter EXCLUSIVE-LOCK
  WHERE bIolEngineParameter.cod-param="iol_gerencial_engine" NO-WAIT NO-ERROR.
 IF LOCKED bIolEngineParameter THEN UNDO, THROW NEW Progress.Lang.AppError("IOL_PARAMETER_LOCKED",1).
 IF NOT AVAILABLE bIolEngineParameter THEN DO:
  CREATE bIolEngineParameter.
  ASSIGN bIolEngineParameter.cod-param="iol_gerencial_engine"
   bIolEngineParameter.val-param="12.2" bIolEngineParameter.tp-param=0 bIolEngineParameter.agrup_im_param_id=0
   lCreated=TRUE.
 END.
 IF bIolEngineParameter.val-param<>"12.2" THEN
  UNDO, THROW NEW Progress.Lang.AppError("IOL_PARAMETER_EXISTING_VALUE_PRESERVED",1).
 RELEASE bIolEngineParameter.
END.
OUTPUT TO "iol-engine-parameter-install.log".
PUT UNFORMATTED "PASS parameter=iol_gerencial_engine value=12.2 created=" lCreated
 " database=" PDBNAME("espec") SKIP.
OUTPUT CLOSE.
