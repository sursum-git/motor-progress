DEFINE TEMP-TABLE tt-param  NO-UNDO
    FIELD destino           AS INTEGER
    FIELD arquivo           AS CHAR FORMAT "x(35)"
    FIELD usuario           AS CHAR FORMAT "x(12)"
    FIELD data-exec         AS DATE
    FIELD hora-exec         AS INTEGER
    FIELD l-batch           AS LOG
    FIELD cod-emitente-ini  LIKE emitente.cod-emitente
    FIELD cod-emitente-fim  LIKE emitente.cod-emitente
    FIELD nome-abrev-ini    LIKE emitente.nome-abrev
    FIELD nome-abrev-fim    LIKE emitente.nome-abrev
    FIELD cod-rep-ini       LIKE emitente.cod-rep
    FIELD cod-rep-fim       LIKE emitente.cod-rep
    FIELD cidade-ini        LIKE emitente.cidade
    FIELD cidade-fim        LIKE emitente.cidade
    FIELD uf-ini            LIKE emitente.estado
    FIELD uf-fim            LIKE emitente.estado
    FIELD dt-ini            AS DATE
    FIELD dt-fim            AS DATE
    FIELD dtRefer           AS DATE
    FIELD sitAtuIni         AS INT
    FIELD sitAtuFim         AS INT .
