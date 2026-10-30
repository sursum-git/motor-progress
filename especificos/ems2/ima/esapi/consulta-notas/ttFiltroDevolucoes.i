/* Parametros do chamador/adaptador. Esta TT nao e uma interface da BO.
   Exatamente um registro por chamada ao adaptador.
   Limites ? sao abertos; CHARACTER vazio tambem. Zero e limite numerico real. */
DEFINE TEMP-TABLE ttFiltroDevolucoes NO-UNDO
    FIELD empresa           AS CHARACTER
    FIELD estabel-de        AS CHARACTER
    FIELD estabel-ate       AS CHARACTER
    FIELD cliente-de        AS INTEGER INITIAL ?
    FIELD cliente-ate       AS INTEGER INITIAL ?
    FIELD nota-de           AS CHARACTER
    FIELD nota-ate          AS CHARACTER
    FIELD pedido-de         AS CHARACTER
    FIELD pedido-ate        AS CHARACTER
    FIELD representante-de  AS INTEGER INITIAL ?
    FIELD representante-ate AS INTEGER INITIAL ?
    FIELD emissao-de        AS DATE INITIAL ?
    FIELD emissao-ate       AS DATE INITIAL ?.
