DEFINE INPUT  PARAMETER pPrograma AS CHARACTER   NO-UNDO.
DEFINE OUTPUT PARAMETER hBo       AS HANDLE      NO-UNDO.

IF SEARCH(pPrograma)<> ? THEN DO:
   RUN value(pPrograma) PERSIST SET hBo.
END.              
ELSE DO:
    MESSAGE 'O programa:' + pPrograma + ' n∆o foi encontrado.' SKIP
        'Envie esta mensagem ao setor de desenvolvimento' SKIP
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
    QUIT .
END.

