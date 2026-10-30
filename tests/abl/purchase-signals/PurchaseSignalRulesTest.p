BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE TEMP-TABLE ttOrder NO-UNDO FIELD dt_registro AS DATE.
DEFINE TEMP-TABLE ttItem NO-UNDO FIELD dt_real_envio_desenhos AS DATE FIELD dt_real_recbto_so_ld AS DATE FIELD dt_real_aprov_so_ld AS DATE FIELD dt_termino_producao AS DATE FIELD dt_prev_termino_producao AS DATE FIELD log_aprov_so_ld AS LOGICAL.
DEFINE VARIABLE resultValue AS JsonArray NO-UNDO.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
DEFINE VARIABLE days AS INTEGER EXTENT 4 NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
DEFINE VARIABLE failed AS LOGICAL NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER checkedValue AS LOGICAL NO-UNDO.
 IF checkedValue<>TRUE OR checkedValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('Assertion failed',1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE ResetItem:
 ASSIGN ttItem.dt_real_envio_desenhos=? ttItem.dt_real_recbto_so_ld=? ttItem.dt_real_aprov_so_ld=? ttItem.dt_termino_producao=? ttItem.dt_prev_termino_producao=? ttItem.log_aprov_so_ld=FALSE.
END PROCEDURE.
PROCEDURE Expect:
 DEFINE INPUT PARAMETER kindValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER todayValue AS DATE NO-UNDO.
 DEFINE INPUT PARAMETER paymentValue AS LOGICAL NO-UNDO.
 DEFINE INPUT PARAMETER ids AS CHARACTER NO-UNDO.
 DEFINE VARIABLE actual AS CHARACTER NO-UNDO.
 DEFINE VARIABLE k AS INTEGER NO-UNDO.
 RUN VALUE(pathValue)(kindValue,IF kindValue='processo' THEN BUFFER ttOrder:HANDLE ELSE BUFFER ttItem:HANDLE,days,todayValue,paymentValue,OUTPUT resultValue).
 DO k=1 TO resultValue:Length:
  actual=actual + (IF actual='' THEN '' ELSE ',') + STRING(resultValue:GetJsonObject(k):GetInteger('sinaliz_imp_id')).
 END.
 RUN Check(actual=ids).
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER.
SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO VALUE('signal-rules-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO, THROW NEW Progress.Lang.AppError('No operational DB allowed',1).
 pathValue=SEARCH('sursum-api/programs/PurchaseSignalRules.r').
 IF pathValue=? THEN UNDO, THROW NEW Progress.Lang.AppError('RED missing PurchaseSignalRules',1).
 ASSIGN days[1]=10 days[2]=2 days[3]=7 days[4]=7.
 CREATE ttOrder. CREATE ttItem. RUN ResetItem.
 RUN Expect('item',DATE(10,27,2026),FALSE,'').
 ASSIGN ttItem.log_aprov_so_ld=TRUE ttItem.dt_real_envio_desenhos=DATE(10,17,2026).
 RUN Expect('item',DATE(10,26,2026),FALSE,'').
 RUN Expect('item',DATE(10,27,2026),FALSE,'1').
 RUN Expect('item',DATE(10,28,2026),FALSE,'1').
 ttItem.dt_real_recbto_so_ld=DATE(10,27,2026). RUN Expect('item',DATE(10,27,2026),FALSE,'').
 RUN Expect('item',DATE(10,28,2026),FALSE,'').
 RUN Expect('item',DATE(10,29,2026),FALSE,'2').
 ttItem.dt_real_aprov_so_ld=DATE(10,29,2026). RUN Expect('item',DATE(10,30,2026),FALSE,'').
 ttItem.dt_real_aprov_so_ld=?. ttItem.log_aprov_so_ld=FALSE. RUN Expect('item',DATE(10,30,2026),FALSE,'').
 RUN ResetItem. ttItem.dt_prev_termino_producao=DATE(11,3,2026).
 RUN Expect('item',DATE(10,27,2026),FALSE,'').
 ttItem.dt_real_recbto_so_ld=DATE(10,20,2026).
 RUN Expect('item',DATE(10,26,2026),FALSE,'').
 RUN Expect('item',DATE(10,27,2026),FALSE,'3').
 RUN Expect('item',DATE(10,28,2026),FALSE,'3').
 ttItem.dt_termino_producao=DATE(10,28,2026). RUN Expect('item',DATE(10,29,2026),FALSE,'').
 ttItem.dt_termino_producao=?. ttItem.log_aprov_so_ld=TRUE.
 RUN Expect('item',DATE(10,27,2026),FALSE,'2,3').
 ttItem.log_aprov_so_ld=?. RUN Expect('item',DATE(10,27,2026),FALSE,'3').
 ttOrder.dt_registro=DATE(10,20,2026).
 RUN Expect('processo',DATE(10,26,2026),FALSE,'').
 RUN Expect('processo',DATE(10,27,2026),FALSE,'').
 RUN Expect('processo',DATE(10,28,2026),FALSE,'4').
 RUN Expect('processo',DATE(10,28,2026),TRUE,'').
 ttOrder.dt_registro=?. RUN Expect('processo',DATE(10,28,2026),FALSE,'').
 ttOrder.dt_registro=DATE(2,27,2024). days[4]=2.
 RUN Expect('processo',DATE(2,29,2024),FALSE,'').
 RUN Expect('processo',DATE(3,1,2024),FALSE,'4').
 days[4]=0. RUN Expect('processo',DATE(2,27,2024),FALSE,'').
 RUN Expect('processo',DATE(2,28,2024),FALSE,'4').
 days[4]=-1. RUN Expect('processo',DATE(2,27,2024),FALSE,'4').
 days[1]=?. failed=FALSE.
 DO ON ERROR UNDO, THROW:
  RUN Expect('item',DATE(10,27,2026),FALSE,'').
  CATCH e AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
 RUN Check(failed). days[1]=10. failed=FALSE.
 DO ON ERROR UNDO, THROW:
  RUN Expect('item',?,FALSE,'').
  CATCH e AS Progress.Lang.Error: failed=TRUE. END CATCH.
 END.
 RUN Check(failed). RUN Check(NUM-DBS=0). RUN Check(SESSION:NUMERIC-FORMAT=culture).
 PUT UNFORMATTED 'PASS signal rules checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END.
OUTPUT CLOSE. QUIT.
