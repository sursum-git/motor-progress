DEFINE VARIABLE iQtErro         AS INTEGER     NO-UNDO.
DEFINE VARIABLE cErroProgress   AS CHARACTER   NO-UNDO.
IF  ERROR-STATUS:ERROR THEN DO:

    DO iqtErro= 1 TO ERROR-STATUS:NUM-MESSAGES:
       ASSIGN cErroProgress = cErroProgress + chr(13) + 'Nro:' 
                                + string(ERROR-STATUS:GET-NUMBER(iQtErro)) + '-'
                                + ERROR-STATUS:GET-MESSAGE(iQtErro).
   END.                                                             
END.
