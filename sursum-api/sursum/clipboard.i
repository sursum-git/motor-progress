
DEFINE {1}  TEMP-TABLE ttClipBoard  NO-UNDO
        FIELD dthr      AS DATETIME
        FIELD texto     AS CHAR
        INDEX ind-dthr AS PRIMARY dthr DESC.

PROCEDURE getDadoBrowseToClipBoard:
    DEFINE INPUT  PARAMETER phbrowse          AS HANDLE      NO-UNDO.
    DEFINE INPUT  PARAMETER pListaCampos      AS CHARACTER   NO-UNDO.
    DEFINE INPUT  PARAMETER pSeparadorRetorno AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE cDados AS CHARACTER   NO-UNDO.

    RUN getDadosBrowse(phBrowse, pListaCampos,pSeparadorRetorno,
                       OUTPUT cDados).
    
    ASSIGN CLIPBOARD:VALUE = cDados.
    RUN inserirTTClipBoard(cDados).



END PROCEDURE.
PROCEDURE limparClipboard:

    EMPTY TEMP-TABLE ttClipBoard.

END PROCEDURE.

PROCEDURE inserirttClipBoard:
    DEFINE INPUT  PARAMETER cDados AS CHARACTER   NO-UNDO.
    CREATE ttClipBoard.
    ASSIGN ttClipBoard.dthr = NOW
           ttClipBoard.texto = cDados.

END PROCEDURE.

