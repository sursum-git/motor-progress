
DEFINE TEMP-TABLE ttArquivos NO-UNDO
    FIELD nomeArquivo AS CHAR
    FIELD historico   AS CHAR
    INDEX primario IS PRIMARY nomeArquivo.
    
DEFINE TEMP-TABLE ttEstatistica NO-UNDO
    FIELD dtHrIni       AS DATETIME
    FIELD dtHrFim       AS DATETIME 
    FIELD segundos      AS INT
    FIELD qtArquivo     AS INT .
    
