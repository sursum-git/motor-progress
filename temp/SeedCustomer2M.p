DEFINE VARIABLE iTarget AS INTEGER NO-UNDO INITIAL 2000000.
DEFINE VARIABLE iBatchSize AS INTEGER NO-UNDO INITIAL 5000.
DEFINE VARIABLE iCreated AS INTEGER NO-UNDO.
DEFINE VARIABLE iBatch AS INTEGER NO-UNDO.
DEFINE VARIABLE iNextCustNum AS INTEGER NO-UNDO.
DEFINE VARIABLE iMaxCustNum AS INTEGER NO-UNDO.
DEFINE VARIABLE iStartMillis AS INTEGER NO-UNDO.
DEFINE VARIABLE iLastLog AS INTEGER NO-UNDO.
DEFINE VARIABLE cLog AS CHARACTER NO-UNDO INITIAL "D:\opencode\motor-progress\output\seed-customer-2m.log".

PROPATH = "D:\opencode\motor-progress\sursum,D:\opencode\motor-progress,":U + PROPATH.

FIND LAST Customer NO-LOCK USE-INDEX CustNum NO-ERROR.
IF AVAILABLE Customer THEN
    ASSIGN iMaxCustNum = Customer.CustNum.
ELSE
    ASSIGN iMaxCustNum = 0.

ASSIGN iNextCustNum = iMaxCustNum + 1
       iStartMillis = ETIME(TRUE)
       iLastLog = 0.

OUTPUT TO VALUE(cLog).
PUT UNFORMATTED
    "SeedCustomer2M started" SKIP
    "startMaxCustNum=" iMaxCustNum SKIP
    "target=" iTarget SKIP
    "batchSize=" iBatchSize SKIP.
OUTPUT CLOSE.

DO WHILE iCreated < iTarget:
    DO TRANSACTION:
        DO iBatch = 1 TO iBatchSize WHILE iCreated < iTarget:
            CREATE Customer.
            ASSIGN
                Customer.CustNum = iNextCustNum
                Customer.Name = "Load Customer " + STRING(iNextCustNum)
                Customer.Address = "Load Address " + STRING(iNextCustNum)
                Customer.Address2 = ""
                Customer.City = "LoadCity" + STRING(iNextCustNum MODULO 1000)
                Customer.State = "LD"
                Customer.PostalCode = STRING(10000000 + (iNextCustNum MODULO 89999999))
                Customer.Country = "USA"
                Customer.Contact = "Load Contact"
                Customer.Phone = "555-" + STRING(1000000 + (iNextCustNum MODULO 8999999))
                Customer.SalesRep = "HXM"
                Customer.CreditLimit = 1000
                Customer.Balance = 0
                Customer.Discount = 0
                Customer.Comments = "Generated for pagination benchmark".

            ASSIGN iCreated = iCreated + 1
                   iNextCustNum = iNextCustNum + 1.
        END.
    END.

    IF iCreated - iLastLog >= 100000 OR iCreated = iTarget THEN DO:
        OUTPUT TO VALUE(cLog) APPEND.
        PUT UNFORMATTED
            "created=" iCreated
            " elapsedMs=" ETIME
            " lastCustNum=" (iNextCustNum - 1) SKIP.
        OUTPUT CLOSE.
        ASSIGN iLastLog = iCreated.
    END.
END.

OUTPUT TO VALUE(cLog) APPEND.
PUT UNFORMATTED
    "SeedCustomer2M finished" SKIP
    "created=" iCreated SKIP
    "firstNewCustNum=" (iMaxCustNum + 1) SKIP
    "lastNewCustNum=" (iNextCustNum - 1) SKIP
    "elapsedMs=" ETIME SKIP.
OUTPUT CLOSE.
