BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE TEMP-TABLE ttContainer NO-UNDO FIELD situacao AS INTEGER FIELD dt_real_embarque AS DATE FIELD dt_prev_embarque AS DATE.
DEFINE VARIABLE hit AS LOGICAL NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE dayOffset AS INTEGER NO-UNDO.
DEFINE VARIABLE r AS CHARACTER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER expected AS LOGICAL NO-UNDO.
 RUN VALUE(r)(INPUT BUFFER ttContainer:HANDLE,5,DATE(10,28,2026),OUTPUT hit).
 IF hit<>expected OR hit=? THEN UNDO, THROW NEW Progress.Lang.AppError('Rule5 assertion',1).
 checks=checks + 1.
END PROCEDURE.
OUTPUT TO 'container-rule.log'.
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('TT only',1).
 r=SEARCH('sursum-api/programs/PurchaseSignalContainerRules.r').
 CREATE ttContainer. ttContainer.situacao=1.
 DO dayOffset=-1 TO 6:
  ttContainer.dt_prev_embarque=DATE(10,28,2026) + dayOffset.
  RUN Check(dayOffset>=0 AND dayOffset<=5).
 END.
 ttContainer.dt_prev_embarque=?. RUN Check(FALSE).
 ttContainer.dt_prev_embarque=DATE(10,28,2026). ttContainer.dt_real_embarque=DATE(10,27,2026). RUN Check(FALSE).
 ttContainer.dt_real_embarque=?. ttContainer.situacao=2. RUN Check(FALSE).
 ttContainer.situacao=?. RUN Check(FALSE).
 RUN VALUE(r)(INPUT BUFFER ttContainer:HANDLE,?,DATE(10,28,2026),OUTPUT hit) NO-ERROR.
 IF NOT ERROR-STATUS:ERROR THEN UNDO, THROW NEW Progress.Lang.AppError('Missing config accepted',1).
 checks=checks + 1.
 PUT UNFORMATTED 'PASS container rule checks=' checks ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE.
