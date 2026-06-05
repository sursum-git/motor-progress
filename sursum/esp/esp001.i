/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
/*:T*******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/

/*------------------------------------------------------------------------
  File        : SPOF004.I.
  Purpose     : Atualizar, Exportar ou Importar as al°quitas do m¢dulo de
                Obrigaá‰es Fiscais (MOF). No caso de atualizar, as mesmas
                s∆o feitas baseadas no Recebimento e Faturamento.
                Para exportaá∆o e importaá∆o, o mesmo Ç feito baseado em
                arquivos CSV (separados por ponto-e-v°rgula (';'), que
                pode ser aberto no Microsoft Excel ou outra plan°lha
                eletrìnica similar).
  Syntax      : <none>
  Description : <none>
  
  Author(s)   : Fabiano Sakae Ribeiro (Exponencial TI)
  Created     : Abril/Maio de 2011
  Notes       : <none>
------------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

/* Temp-Table Definitions ---                                           */

DEFINE TEMP-TABLE {1} NO-UNDO
    FIELD destino          AS INTEGER
    FIELD arquivo          AS CHARACTER FORMAT "x(60)":U
    FIELD usuario          AS CHARACTER FORMAT "x(12)":U
    FIELD data-exec        AS DATE
    FIELD hora-exec        AS INTEGER
    FIELD cod-estabel-ini  LIKE doc-fiscal.cod-estabel
    FIELD cod-estabel-fin  LIKE doc-fiscal.cod-estabel
    FIELD serie-ini        LIKE doc-fiscal.serie
    FIELD serie-fin        LIKE doc-fiscal.serie
    FIELD nr-doc-fis-ini   LIKE doc-fiscal.nr-doc-fis
    FIELD nr-doc-fis-fin   LIKE doc-fiscal.nr-doc-fis
    FIELD cod-emitente-ini LIKE doc-fiscal.cod-emitente
    FIELD cod-emitente-fin LIKE doc-fiscal.cod-emitente
    FIELD nat-operacao-ini LIKE doc-fiscal.nat-operacao
    FIELD nat-operacao-fin LIKE doc-fiscal.nat-operacao
    FIELD dt-docto-ini     LIKE doc-fiscal.dt-docto
    FIELD dt-docto-fin     LIKE doc-fiscal.dt-docto
    FIELD atual-aliq       AS LOGICAL   FORMAT "Sim/N∆o"
    FIELD export-import    AS INTEGER
    FIELD arq-exp-imp      AS CHARACTER FORMAT "x(100)":U
    FIELD apenas-aliq-zero AS LOGICAL   FORMAT "Sim/N∆o":U
    FIELD imp-param        AS LOGICAL
    .

DEFINE TEMP-TABLE tt-raw-digita NO-UNDO
    FIELD raw-digita  AS RAW
    .


