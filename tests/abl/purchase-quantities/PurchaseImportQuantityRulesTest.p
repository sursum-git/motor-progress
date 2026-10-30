BLOCK-LEVEL ON ERROR UNDO, THROW.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE pathValue AS CHARACTER NO-UNDO.
DEFINE VARIABLE resultValue AS JsonObject NO-UNDO.
DEFINE VARIABLE culture AS CHARACTER NO-UNDO.
DEFINE VARIABLE checks AS INTEGER NO-UNDO.
PROCEDURE Check:
 DEFINE INPUT PARAMETER checkedValue AS LOGICAL NO-UNDO.
 IF checkedValue<>TRUE OR checkedValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('Quantity rule assertion failed',1).
 checks=checks + 1.
END PROCEDURE.
PROCEDURE ExpectField:
 DEFINE INPUT PARAMETER fieldValue AS CHARACTER NO-UNDO.
 DEFINE INPUT PARAMETER expectedValue AS DECIMAL NO-UNDO.
 IF expectedValue=? THEN RUN Check(resultValue:IsNull(fieldValue)).
 ELSE RUN Check(NOT resultValue:IsNull(fieldValue) AND resultValue:GetDecimal(fieldValue)=expectedValue).
END PROCEDURE.
PROCEDURE Expect:
 DEFINE INPUT PARAMETER boughtValue AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER priceValue AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER confirmedValue AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER physicalValue AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER boughtFinal AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER boughtAmount AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER receivedFinal AS DECIMAL NO-UNDO.
 DEFINE INPUT PARAMETER receivedAmount AS DECIMAL NO-UNDO.
 RUN VALUE(pathValue)(boughtValue,priceValue,confirmedValue,physicalValue,OUTPUT resultValue).
 RUN ExpectField('qt_comprada_final',boughtFinal). RUN ExpectField('vl_comprada_final',boughtAmount).
 RUN ExpectField('qt_rec_final',receivedFinal). RUN ExpectField('vl_rec_final',receivedAmount).
END PROCEDURE.
culture=IF SESSION:PARAMETER='' THEN 'AMERICAN' ELSE SESSION:PARAMETER. SESSION:NUMERIC-FORMAT=culture.
OUTPUT TO VALUE('quantity-rules-' + culture + '.log').
DO ON ERROR UNDO, THROW:
 IF NUM-DBS<>0 THEN UNDO,THROW NEW Progress.Lang.AppError('No operational DB allowed',1).
 pathValue=SEARCH('sursum-api/programs/PurchaseImportQuantityRules.r').
 IF pathValue=? THEN UNDO,THROW NEW Progress.Lang.AppError('RED missing quantity rules',1).
 RUN Expect(10,2,20,15,15,30,15,30).
 RUN Expect(10,2,20,0,20,40,20,40).
 RUN Expect(10,2,8,5,10,20,5,10).
 RUN Expect(10,2,10,10,10,20,10,20).
 RUN Expect(10,2,?,?,10,20,0,0).
 RUN Expect(?,2,20,15,?,?,15,30).
 RUN Expect(10,?,20,15,15,?,15,?).
 RUN Expect(10,0,20,15,15,0,15,0).
 RUN Expect(-10,2,-5,-3,-3,-6,-3,-6).
 RUN Expect(0,2,0,0,0,0,0,0).
 RUN Expect(1.25,1.2,1.75,1.5,1.5,1.8,1.5,1.8).
 RUN Expect(10,2,?,0,10,20,0,0).
 RUN Check(NUM-DBS=0). RUN Check(SESSION:NUMERIC-FORMAT=culture).
 PUT UNFORMATTED 'PASS quantity rules checks=' checks ' culture=' culture ' NUM-DBS=' NUM-DBS SKIP.
 CATCH e AS Progress.Lang.Error: PUT UNFORMATTED 'FAIL ' e:GetMessage(1) SKIP. END CATCH.
END. OUTPUT CLOSE. QUIT.
