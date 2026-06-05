DEFINE TEMP-TABLE ttCampos
    FIELD id            AS INT
    FIELD ordem         AS INT COLUMN-LABEL "Ordem"
    FIELD nome          AS CHAR FORMAT 'x(80)' COLUMN-LABEL "Nome"
    FIELD tipo          AS CHAR COLUMN-LABEL "Tipo" FORMAT 'x(20)'
    FIELD formato       AS CHAR FORMAT 'x(50)'  COLUMN-LABEL "Formato"
    FIELD labelCampo    AS CHAR FORMAT 'x(100)' COLUMN-LABEL "Label"
    FIELD extensao      AS INT  COLUMN-LABEL "Extens∆o"
    FIELD qtDecimais    AS INT COLUMN-LABEL "Qt.Decimais"
    FIELD obrigatorio   AS LOGICAL COLUMN-LABEL "Obrigat¢rio"
    FIELD tabela        AS CHAR FORMAT 'x(50)'
    FIELD indices       AS CHAR
    FIELD banco         AS CHAR
    FIELD lista         AS CHAR FORMAT 'x(100)' COLUMN-LABEL "Lista"
    INDEX ind-tb-cp tabela nome
    INDEX ind-cp nome
    INDEX ind-ordem ordem.

DEFINE TEMP-TABLE ttCpsMeta
    FIELD cp1 AS CHAR FORMAT 'x(80)'
    FIELD cp2 AS CHAR FORMAT 'x(80)'.

DEFINE TEMP-TABLE ttTabelas
    FIELD nome      AS CHAR
    FIELD descricao AS CHAR
    FIELD banco     AS CHAR
    FIELD nomeDump  AS CHAR
    FIELD lastChange AS INT64
    FIELD dtHrAlteracao AS DATETIME
    INDEX ind_nome nome
    INDEX ind_banco_tb banco nome
    INDEX ind_nomeDump nomeDump
    INDEX ind_alteracao dtHrAlteracao.


DEFINE TEMP-TABLE ttRelacs
    FIELD tb01      AS CHAR
    FIELD tb02      AS CHAR
    FIELD campos    AS CHAR .

