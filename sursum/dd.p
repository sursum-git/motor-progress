DEFINE VARIABLE hSursum80 AS HANDLE      NO-UNDO.
IF NOT VALID-HANDLE(hSursum80) THEN DO:
   RUN db/sursum80.w PERSIST SET hSursum80 .
   RUN enable_ui IN hSursum80.
END.
ELSE DO:
   RUN viewObject IN hSursum80.
END.
   

