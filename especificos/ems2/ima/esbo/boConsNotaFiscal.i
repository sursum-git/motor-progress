/* Contrato comum das BOs de notas e devolucoes. Campos originais preservados. */
DEFINE TEMP-TABLE tt-NF NO-UNDO
    FIELD cod-estabel       AS CHARACTER
    FIELD serie             AS CHARACTER
    FIELD nf                AS CHARACTER
    FIELD data              AS DATE
    FIELD nr-Pedido         AS INTEGER
    FIELD nome-abrev        AS CHARACTER
    FIELD nome-ab-reppri    AS CHARACTER
    FIELD perc-comis        AS DECIMAL
    FIELD cidade            AS CHARACTER
    FIELD estado            AS CHARACTER
    FIELD vl-bruto          AS DECIMAL
    FIELD vl-nota           AS DECIMAL
    FIELD vl-desconto       AS DECIMAL
    FIELD descr-mot-dev     AS CHARACTER
    /* Contexto explicito para persistencia; nao deduzir tipo pelo sinal. */
    FIELD tipo-nota         AS INTEGER INITIAL ?
    FIELD cod-emitente      AS INTEGER INITIAL ?
    FIELD cod-rep           AS INTEGER INITIAL ?
    FIELD nf-original       AS CHARACTER
    FIELD nr-pedcli         AS CHARACTER
    FIELD preposto          AS CHARACTER
    FIELD dt-emis-nota      AS DATE INITIAL ?.
