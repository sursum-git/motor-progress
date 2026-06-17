 
/*------------------------------------------------------------------------
   File        : UrlEncode
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : administrator
   Created     : Tue Aug 26 15:56:46 BRT 2025
   Notes       : 
 ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Comum.UrlEncode: 
        
    
     
    METHOD PUBLIC STATIC CHARACTER getUrlEncode(texto AS CHARACTER, tipo AS CHARACTER):
        
        DEFINE VARIABLE cHex        AS CHARACTER NO-UNDO INITIAL "0123456789ABCDEF".
        DEFINE VARIABLE cUnsafe     AS CHARACTER NO-UNDO INITIAL " <>~"#%~{}|~\^~~[]`".
        DEFINE VARIABLE cReserved   AS CHARACTER NO-UNDO INITIAL "~;/?:@=&".
        DEFINE VARIABLE cEncodeList AS CHARACTER NO-UNDO INITIAL "query".
        DEFINE VARIABLE iCounter    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cChar       AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iAscii      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cResult     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE iLength     AS INTEGER   NO-UNDO.

        CASE tipo:    
            WHEN "query" THEN
                cEncodeList = cUnsafe + cReserved + "+".
            WHEN "cookie" THEN        
                cEncodeList = cUnsafe + " ,~;".
            WHEN "default" OR 
            WHEN "" THEN        
                cEncodeList = cUnsafe.    
            OTHERWISE    
            cEncodeList = cUnsafe + tipo.
        END CASE.

        iLength = LENGTH(texto,"RAW").
        DO iCounter = 1 TO iLength:    
            cChar  = SUBSTRING(texto, iCounter, 1, "RAW").    
            iAscii = ASC(cChar, "1252", "1252").    
            IF iAscii LE 31 OR iAscii GE 127 OR INDEX(cEncodeList, cChar) GT 0 THEN         
                cResult = cResult + "%" 
                    + SUBSTRING(cHex, int(TRUNCATE(iAscii / 16, 0) + 1) , 1 , "RAW")
                    + SUBSTRING(cHex, int(iAscii MODULO 16 + 1), 1, "RAW")
                    .    
            ELSE         
                cResult = cResult + cChar.
        END.

        RETURN cResult. 

    END METHOD.
     
     

END CLASS.