FUNCTION HexToInt RETURNS INT64
    ( INPUT  pcRowid     AS CHARACTER,
      OUTPUT piPartition AS INTEGER ):
    DEFINE VARIABLE iRecid AS INT64   NO-UNDO INITIAL 0.
    DEFINE VARIABLE iChar  AS INTEGER NO-UNDO.

    DEFINE VARIABLE iCode AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iExp  AS INT64       NO-UNDO.

    /* Strip the leading 0x from the ROWID value */    
    IF pcRowid BEGINS "0x" THEN
        pcRowid = SUBSTRING(pcRowid,3).

    IF LENGTH(pcRowid) GT 16 THEN
        ASSIGN piPartition = INTEGER(SUBSTRING(pcRowid,17))
               pcRowid     = SUBSTRING(pcRowid,1,16).
    ELSE piPartition = ?.

    pcRowid = CAPS(pcRowid).
    DO iChar = 1 TO LENGTH(pcRowid):
        IF CAN-DO("0,1,2,3,4,5,6,7,8,9", 
                  (SUBSTRING(pcRowid, iChar, 1))) THEN
            ASSIGN iRecid = iRecid + INTEGER(SUBSTRING(pcRowid, iChar, 1)) *
                     EXP(16, (LENGTH(pcRowid) - iChar)).
        ELSE
            ASSIGN iRecid = iRecid + (KEYCODE(SUBSTRING(pcRowid,iChar,1)) -
                            KEYCODE("A") + 10) * INT64(EXP(16, LENGTH(pcRowid) - iChar)).
    END.

    RETURN iRecid.
END FUNCTION.

FUNCTION IntToHex RETURNS CHARACTER
    ( /* RECID to ROWID conversion */
      INPUT piRecid  AS INT64,
      INPUT piPartId AS INTEGER ):

    DEFINE VARIABLE cRowid     AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE iRemainder AS INTEGER     NO-UNDO.
    DEFINE VARIABLE iAsc       AS INTEGER     NO-UNDO.

    ASSIGN /*piPartId = (if piPartId EQ ? THEN 0 ELSE piPartId)*/
           iAsc     = ASC("a").     

    DO WHILE TRUE:        
        ASSIGN iRemainder = (piRecid MOD 16)
               cRowid = (IF iRemainder LT 10 THEN
                             STRING(iRemainder)
                         ELSE
                             CHR(iAsc + iRemainder - 10)) +
                        cRowid.

        IF piRecid LT 16 THEN
            LEAVE.
 
        piRecid = (piRecid - iRemainder) / 16.
    END.

    iRemainder = (16 - LENGTH(cRowid)).
    DO piRecid = 1 TO iRemainder:
        cRowid = "0" + cRowid.
    END.

    cRowid = "0x" + cRowid.
    IF piPartId NE ? AND
       piPartId GE 0 THEN
        cRowid = cRowid + STRING(piPartId,"9999").
    
    RETURN cRowid.
END FUNCTION.
