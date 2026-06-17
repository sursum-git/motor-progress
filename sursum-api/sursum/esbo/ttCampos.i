DEFINE TEMP-TABLE ttCampos   NO-UNDO
    FIELD id            AS INT64
    FIELD ordem         AS INT COLUMN-LABEL "Ordem"
    FIELD nome          AS CHAR FORMAT 'x(40)' COLUMN-LABEL "Nome"
    FIELD tipo          AS CHAR COLUMN-LABEL "Tipo" FORMAT 'x(20)'
    FIELD formato       AS CHAR FORMAT 'x(50)'  COLUMN-LABEL "Formato"
    FIELD labelCampo    AS CHAR FORMAT 'x(100)' COLUMN-LABEL "Label"
    FIELD extensao      AS INT  COLUMN-LABEL "Extens∆o"
    FIELD qtDecimais    AS INT COLUMN-LABEL "Qt.Decimais"
    FIELD obrigatorio   AS LOGICAL COLUMN-LABEL "Obrigat¢rio"    
    FIELD indices       AS CHAR COLUMN-LABEL "Indices"    
    FIELD lista         AS CHAR FORMAT 'x(100)' COLUMN-LABEL "Lista"
    FIELD numRecid      AS RECID  COLUMN-LABEL "RECID"
    FIELD tabela        AS CHAR FORMAT 'x(50)' COLUMN-LABEL "Tb."
    FIELD banco         AS CHAR  COLUMN-LABEL "Banco"
    INDEX ind-tb-cp tabela nome
    INDEX ind-cp nome
    INDEX ind-ordem ordem nome.
