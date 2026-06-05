{esbo/ttCampos.i}

DEFINE TEMP-TABLE ttCpsMeta  NO-UNDO
    FIELD cp1 AS CHAR FORMAT 'x(80)'
    FIELD cp2 AS CHAR FORMAT 'x(80)'.

DEFINE TEMP-TABLE ttTabelas  NO-UNDO
    FIELD nome          AS CHAR
    FIELD descricao     AS CHAR
    FIELD banco         AS CHAR
    FIELD nomeDump      AS CHAR
    FIELD lastChange    AS INT64
    FIELD dtHrAlteracao AS DATETIME
    FIELD numRecid      AS RECID
    FIELD recidIndPri    AS RECID
    INDEX ind_nome nome
    INDEX ind_banco_tb banco nome
    INDEX ind_nomeDump nomeDump
    INDEX ind_alteracao dtHrAlteracao.


DEFINE TEMP-TABLE ttIndices   NO-UNDO
    FIELD id                AS INT
    FIELD recidFile         AS RECID
    FIELD nome              AS CHAR FORMAT 'x(50)'
    FIELD logPrimario       AS LOGICAL 
    FIELD logUnico          AS LOGICAL
    FIELD logAtivo          AS LOGICAL
    FIELD wordIdx           AS INTEGER
    FIELD idxCRC            AS INTEGER
    FIELD dtHrUltAlteracao  AS DATETIME
    FIELD wordRules         AS CHAR
    FIELD recidIndex        AS RECID
    //FIELD descrCampos       AS CHAR FORMAT 'x(400)'
    INDEX nome nome
    INDEX id AS PRIMARY id  
    INDEX indRECID recidIndex .
    
DEFINE TEMP-TABLE ttCpsInd  NO-UNDO
    FIELD id                AS INT    
    FIELD idIndice          AS INT
    FIELD indexSeq          AS INT
    FIELD fieldRecid        AS RECID
    FIELD logUnsorted       AS LOGICAL
    FIELD logAscending      AS LOGICAL
    FIELD logAbbreviate     AS LOGICAL
    FIELD dtHrUtlAlteracao  AS DATETIME
    FIELD indexRecid        AS RECID
    FIELD nome              AS CHAR FORMAT 'x(50)'
    FIELD tipo              AS CHAR
    INDEX ind-id id 
    INDEX ind-seq indexSeq  
    INDEX ind-indice indexRecid .
    
    
    
    
DEFINE TEMP-TABLE ttRelacs    NO-UNDO
    FIELD tb01      AS CHAR
    FIELD tb02      AS CHAR
    FIELD campos    AS CHAR .


    
DEFINE TEMP-TABLE ttRelacEstr NO-UNDO
    FIELD chave AS CHAR
    FIELD agrupIndex AS CHAR
    FIELD tb01 AS CHAR
    FIELD tb02 AS CHAR
    FIELD cp01 AS CHAR
    FIELD cp02 AS CHAR
    FIELD tipoRelac AS CHAR
    INDEX ind-chave AS PRIMARY chave .

DEFINE TEMP-TABLE ttTbsRelac NO-UNDO
    FIELD tabela AS CHAR .

DEFINE TEMP-TABLE ttTbsDireto NO-UNDO
    FIELD tabela AS CHAR.
    
