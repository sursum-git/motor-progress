&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS D-Dialog 
/*:T*******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i ESSP0190E6 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
DEF BUFFER empresa FOR mgcad.empresa.

/* Parameters Definitions ---                                           */
DEF TEMP-TABLE tt-trab      NO-UNDO
    FIELD visualiza         AS LOG
    FIELD seq-item          AS INT
    FIELD seq-repres        AS INT
    FIELD seq-grupo         AS INT
    FIELD seq-cliente       AS INT
    FIELD seq-regiao        AS INT
    FIELD seq-uf            AS INT
    FIELD seq-nat-oper      AS INT
    FIELD seq-cond-pg       AS INT
    FIELD it-codigo         LIKE ped-item.it-codigo
    FIELD desc-item         LIKE ITEM.desc-item
    FIELD classif           LIKE fam-comerc.descricao
    FIELD acabamento        AS   CHAR FORMAT "x(30)"
    FIELD no-ab-reppri      LIKE ped-venda.no-ab-reppri
    FIELD cod-rep           LIKE repres.cod-rep
    FIELD matriz            LIKE it-nota-fisc.aliquota-icm
    FIELD nome-abrev        LIKE ped-venda.nome-abrev
    FIELD cod-emit          LIKE emitente.cod-emit
    FIELD regiao            AS CHAR FORMAT "x(20)"
    FIELD nat-operacao      LIKE natur-oper.nat-operacao
    FIELD aliq-icms         LIKE natur-oper.aliquota-icm
    FIELD vl-icms           LIKE it-nota-fisc.vl-icms-it
    FIELD desc-pratic       AS DEC
    FIELD cond-pagto        AS CHAR
    FIELD uf                AS CHAR
    FIELD lote              AS CHAR
    FIELD Und               AS CHAR
    FIELD qtd               AS DEC
    FIELD qtd-devol         AS DEC
    FIELD vlr               AS DEC
    FIELD vlr-devol         AS DEC
    FIELD vlr-custo         AS DEC
    FIELD preco-medio       AS DEC
    FIELD prazo-medio       AS DEC
    FIELD rentabilidade     AS DEC
    FIELD perc-sobr-total   AS DEC
    INDEX indice1 it-codigo    und lote 
    INDEX indice2 no-ab-reppri und lote 
    INDEX indice3 matriz       und lote 
    INDEX indice4 nome-abrev   und lote 
    INDEX indice5 regiao       und lote uf
    INDEX indice6 nat-operacao und lote 
    INDEX indice7 cond-pagto   und lote.

DEF TEMP-TABLE tt-work      NO-UNDO
    FIELD cond-pagto        AS CHAR
    FIELD Und               AS CHAR
    FIELD qtd               AS DEC
    FIELD vlr               AS DEC
    FIELD desc-pratic       AS DEC
    FIELD preco-medio       AS DEC
    FIELD qtd-devol         AS DEC
    FIELD vlr-devol         AS DEC.


DEF BUFFER b-tt-work FOR tt-work.                                                         

/* PARAMETROS RECEBIDOS */
DEFINE INPUT PARAMETER TABLE FOR tt-trab.  
DEFINE INPUT PARAMETER p-tipo-consulta    AS CHAR.
DEFINE INPUT PARAMETER p-tipo-selecao     AS INT.
DEFINE INPUT PARAMETER p-dt-faturar       AS CHAR.
DEFINE INPUT PARAMETER p-dt-faturadas-ini AS DATE.
DEFINE INPUT PARAMETER p-dt-faturadas-fin AS DATE.
DEFINE INPUT PARAMETER p-dt-vendido-ini   AS CHAR.
DEFINE INPUT PARAMETER p-dt-vendido-fin   AS CHAR.

/* Local Variable Definitions ---                                       */
DEF VAR h-acomp  AS HANDLE NO-UNDO.
DEF VAR c-codigo AS CHAR.
DEF VAR c-titulo AS CHAR.
DEF VAR h-query  AS HANDLE. 
DEF VAR c-empresa AS CHAR.

/* Variaveis para o Excel */
DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF VAR chworksheet AS COM-HANDLE NO-UNDO.
DEF VAR c-lin       AS CHAR FORMAT "x(500)".
DEF VAR arq-saida   AS CHAR FORMAT "x(50)".

/* Variaveis da Rotina de Impress∆o */
DEFINE VAR l-ok         AS LOG.
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-ct         AS INT.
DEFINE VAR i-lin        AS INT.
DEFINE VAR i-pag        AS INT.

/* Variaveis da Rotina de CLASSIFICAÄ«O POR COLUNAS DO BROWSE */
DEFINE VAR  h-col      AS HANDLE.
DEFINE VAR  i-col      AS INT.
DEFINE VAR sort-col    AS INT INIT 1.
DEFINE VAR order-col   AS INT INIT 1.
DEFINE VAR c-label     AS CHAR.
DEFINE VAR c-label-ori AS CHAR.

/* Preprocessor usado na Classificaá∆o do Browse */
&GLOBAL-DEFINE SORTBY-PHRASE BY IF sort-col = 1 ~
                                 THEN tt-work.cond-pagto ~
                                ELSE IF sort-col = 2 ~
                                     THEN tt-work.und + tt-work.cond-pagto ~
                                    ELSE IF sort-col = 3 ~
                                         THEN STRING(tt-work.qtd, "999,999,999.99") ~
                                        ELSE IF sort-col = 4 ~
                                             THEN STRING(tt-work.qtd, "999,999,999.99") ~
                                            ELSE IF sort-col = 5 ~
                                                 THEN STRING(tt-work.preco-medio, "999,999,999.99") ~
                                                 ELSE IF sort-col = 6 ~
                                                      THEN STRING(tt-work.desc-pratic, "999,999,999.99") ~
                                                       ELSE IF sort-col = 7 ~
                                                           THEN STRING(tt-work.qtd-devol, "999,999,999.99") ~
                                                           ELSE STRING(tt-work.vlr-devol, "999,999,999.99") ~

/* Preprocessor usado na Classificaá∆o do Relatorio Impress∆o / Gerar EXCEL */
&GLOBAL-DEFINE SORTBY-IMP-EXCEL BY IF sort-col = 1 ~
                                   THEN b-tt-work.cond-pagto ~
                                  ELSE IF sort-col = 2 ~
                                       THEN b-tt-work.und + b-tt-work.cond-pagto ~
                                      ELSE IF sort-col = 3 ~
                                           THEN STRING(b-tt-work.qtd, "999,999,999.99") ~
                                          ELSE IF sort-col = 4 ~
                                               THEN STRING(b-tt-work.qtd, "999,999,999.99") ~
                                              ELSE IF sort-col = 5 ~
                                                   THEN STRING(b-tt-work.preco-medio, "999,999,999.99") ~
                                                   ELSE IF sort-col = 6 ~
                                                        THEN STRING(b-tt-work.desc-pratic, "999,999,999.99") ~
                                                        ELSE IF sort-col = 7 ~
                                                             THEN STRING(b-tt-work.qtd-devol, "999,999,999.99") ~
                                                             ELSE STRING(b-tt-work.vlr-devol, "999,999,999.99") ~

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME D-Dialog
&Scoped-define BROWSE-NAME br-work

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-work

/* Definitions for BROWSE br-work                                       */
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.cond-pagto tt-work.und tt-work.qtd tt-work.vlr tt-work.desc-pratic tt-work.preco-medio tt-work.qtd-devol tt-work.vlr-devol   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work tt-work.cond-pagto   tt-work.und   tt-work.qtd   tt-work.vlr   tt-work.preco-medio   tt-work.qtd-devol   tt-work.vlr-devol   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-work tt-work
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY br-work FOR EACH tt-work NO-LOCK {&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-work RECT-1 rt-buttom bt-vapara bt-excel ~
bt-imprime bt-exit bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-qtd-m fi-tot-vlr-m fi-media-m ~
fi-tot-qtd-dev-m fi-tot-vlr-dev-m fi-tot-desc-m fi-tot-qtd-kg fi-tot-vlr-kg ~
fi-media-kg fi-tot-qtd-dev-kg fi-tot-vlr-dev-kg fi-tot-desc-kg ~
fi-tot-qtd-und fi-tot-vlr-und fi-media-und fi-tot-qtd-dev-und ~
fi-tot-vlr-dev-und fi-tot-desc-und fi-tot-geral fi-ger-vlr-dev 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-6 bt-excel 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "&Ajuda" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-cancela AUTO-END-KEY 
     LABEL "&Cancelar" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/excel.bmp":U
     LABEL "Button 2" 
     SIZE 5.86 BY 1.5 TOOLTIP "Gerar Planilha".

DEFINE BUTTON bt-exit AUTO-END-KEY 
     IMAGE-UP FILE "image/im-exi.bmp":U
     LABEL "" 
     SIZE 5.86 BY 1.5 TOOLTIP "Fechar Programa"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/im-pri.bmp":U
     LABEL "" 
     SIZE 5.86 BY 1.5 TOOLTIP "Imprimir Informaá‰es do Browse.".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-vapara AUTO-GO 
     IMAGE-UP FILE "image/im-vapra.bmp":U
     LABEL "" 
     SIZE 5.86 BY 1.5 TOOLTIP "Posicionar no Item"
     BGCOLOR 8 FONT 10.

DEFINE VARIABLE fi-ger-vlr-dev AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 4  NO-UNDO.

DEFINE VARIABLE fi-media-kg AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-media-m AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-media-und AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-desc-kg AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-desc-m AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-desc-und AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.57 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-geral AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 4  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-dev-kg AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-dev-m AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-dev-und AS DECIMAL FORMAT "ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-kg AS DECIMAL FORMAT "    ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-m AS DECIMAL FORMAT " ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-und AS DECIMAL FORMAT "   ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr-dev-kg AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr-dev-m AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr-dev-und AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr-kg AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr-m AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr-und AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 6.86 BY 17.42.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 109.43 BY 1.42
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-work FOR 
      tt-work SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-work D-Dialog _FREEFORM
  QUERY br-work NO-LOCK DISPLAY
      tt-work.cond-pagto      COLUMN-LABEL "Condiá∆o Pagamento"   FORMAT "x(27)"              WIDTH 43.5
      tt-work.und             COLUMN-LABEL "Und"                  FORMAT "x(03)"              WIDTH 03.0
      tt-work.qtd             COLUMN-LABEL "Quantidade"           FORMAT ">>>,>>>,>>9.99"     WIDTH 11.0
      tt-work.vlr             COLUMN-LABEL "Valor"                FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 11.0
      tt-work.desc-pratic     COLUMN-LABEL "Desc. Pratic"         FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 10.5
      tt-work.preco-medio     COLUMN-LABEL "Preco Medio"          FORMAT ">>>,>>9.99"         WIDTH 11.0 
      tt-work.qtd-devol       COLUMN-LABEL "Qtd Devoluá∆o"        FORMAT ">>>,>>>,>>9.99"     WIDTH 11.0
      tt-work.vlr-devol       COLUMN-LABEL "Valor Devoluá∆o"      FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 12.2
ENABLE
    tt-work.cond-pagto
    tt-work.und
    tt-work.qtd
    tt-work.vlr
    tt-work.preco-medio
    tt-work.qtd-devol
    tt-work.vlr-devol
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 109.29 BY 11.92
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1.72
     bt-vapara AT ROW 1.38 COL 112
     bt-excel AT ROW 2.92 COL 112
     bt-imprime AT ROW 4.5 COL 112
     fi-tot-qtd-m AT ROW 13.08 COL 34.72 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr-m AT ROW 13.08 COL 46.14 COLON-ALIGNED NO-LABEL
     fi-media-m AT ROW 13.08 COL 70.57 COLON-ALIGNED NO-LABEL
     fi-tot-qtd-dev-m AT ROW 13.08 COL 82.57 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr-dev-m AT ROW 13.08 COL 94.29 COLON-ALIGNED NO-LABEL
     fi-tot-desc-m AT ROW 13.13 COL 58.57 COLON-ALIGNED NO-LABEL WIDGET-ID 2
     fi-tot-qtd-kg AT ROW 14.08 COL 34.72 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr-kg AT ROW 14.08 COL 46.14 COLON-ALIGNED NO-LABEL
     fi-media-kg AT ROW 14.08 COL 70.57 COLON-ALIGNED NO-LABEL
     fi-tot-qtd-dev-kg AT ROW 14.08 COL 82.57 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr-dev-kg AT ROW 14.08 COL 94.29 COLON-ALIGNED NO-LABEL
     fi-tot-desc-kg AT ROW 14.17 COL 58.72 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     fi-tot-qtd-und AT ROW 15.08 COL 34.72 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr-und AT ROW 15.08 COL 46.14 COLON-ALIGNED NO-LABEL
     fi-media-und AT ROW 15.08 COL 70.57 COLON-ALIGNED NO-LABEL
     fi-tot-qtd-dev-und AT ROW 15.08 COL 82.57 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr-dev-und AT ROW 15.08 COL 94.29 COLON-ALIGNED NO-LABEL
     fi-tot-desc-und AT ROW 15.13 COL 58.72 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     fi-tot-geral AT ROW 16.08 COL 46.14 COLON-ALIGNED NO-LABEL
     fi-ger-vlr-dev AT ROW 16.08 COL 94.29 COLON-ALIGNED NO-LABEL
     bt-exit AT ROW 16.83 COL 112
     bt-ok AT ROW 17.42 COL 2.57
     bt-cancela AT ROW 17.42 COL 13.57
     bt-ajuda AT ROW 17.42 COL 100.14
     "KG" VIEW-AS TEXT
          SIZE 2 BY .54 AT ROW 14.29 COL 34.14
          FGCOLOR 12 
     "UND" VIEW-AS TEXT
          SIZE 3.29 BY .54 AT ROW 15.17 COL 33
          FGCOLOR 12 
     "M" VIEW-AS TEXT
          SIZE 1.57 BY .54 AT ROW 13.33 COL 34.86
          FGCOLOR 12 
     "TOTAIS:" VIEW-AS TEXT
          SIZE 6.72 BY .88 AT ROW 13.17 COL 26.86
          FONT 0
     "TOTAL GERAL:" VIEW-AS TEXT
          SIZE 11.29 BY .71 AT ROW 16.17 COL 35.86
          FGCOLOR 4 
     RECT-1 AT ROW 1.17 COL 111.43
     rt-buttom AT ROW 17.17 COL 1.57
     SPACE(7.85) SKIP(0.07)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "TOTALIZADOR - ESSP0190E"
         DEFAULT-BUTTON bt-ok.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartDialog
   Allow: Basic,Browse,DB-Fields,Query,Smart
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB D-Dialog 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/d-dialog.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR DIALOG-BOX D-Dialog
   NOT-VISIBLE FRAME-NAME L-To-R                                        */
/* BROWSE-TAB br-work TEXT-2 D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR BUTTON bt-excel IN FRAME D-Dialog
   6                                                                    */
/* SETTINGS FOR FILL-IN fi-ger-vlr-dev IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-media-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-media-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-media-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-desc-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-desc-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-desc-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-geral IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-dev-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-dev-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-dev-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr-dev-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr-dev-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr-dev-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY br-work FOR EACH tt-work NO-LOCK {&SORTBY-PHRASE}.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-work */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK DIALOG-BOX D-Dialog
/* Query rebuild information for DIALOG-BOX D-Dialog
     _Options          = "SHARE-LOCK"
     _Query            is NOT OPENED
*/  /* DIALOG-BOX D-Dialog */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL D-Dialog D-Dialog
ON WINDOW-CLOSE OF FRAME D-Dialog /* TOTALIZADOR - ESSP0190E */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON ROW-DISPLAY OF br-work IN FRAME D-Dialog
DO:
  IF tt-work.qtd-devol = 0 THEN 
     tt-work.qtd-devol:FGCOLOR IN BROWSE br-work = 15.
  IF tt-work.vlr-devol = 0 THEN 
     tt-work.vlr-devol:FGCOLOR IN BROWSE br-work = 15.
  IF tt-work.qtd-devol <> 0 THEN
     tt-work.qtd-devol:FGCOLOR IN BROWSE br-work =  4.
  IF tt-work.vlr-devol <> 0 THEN
     tt-work.vlr-devol:FGCOLOR IN BROWSE br-work =  4.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON START-SEARCH OF br-work IN FRAME D-Dialog
DO:
   ASSIGN h-col = br-work:CURRENT-COLUMN.

   DO i-col = 1 TO br-work:NUM-COLUMNS.
      IF br-work:GET-BROWSE-COLUMN(i-col) <> h-col THEN DO.
         IF br-work:GET-BROWSE-COLUMN(i-col):LABEL-FGCOLOR = 3 THEN
            br-work:GET-BROWSE-COLUMN(i-col):LABEL = c-label-ori. 

         ASSIGN br-work:GET-BROWSE-COLUMN(i-col):LABEL-FGCOLOR = ?.
      END.
   END.

   DO i-col = 1 TO br-work:NUM-COLUMNS.
      IF br-work:GET-BROWSE-COLUMN(i-col) = h-col THEN DO.
         ASSIGN sort-col = i-col.

         IF h-col:LABEL-FGCOLOR = 3 THEN 
            ASSIGN order-col = IF order-col = 1 THEN 4 ELSE 1.
         ELSE
            ASSIGN h-col:LABEL-FGCOLOR = 3
                   order-col           = 1
                   c-label-ori         = h-col:LABEL.
      END.
   END.

   ASSIGN c-label = c-label-ori.
   IF order-col = 1 THEN
      OVERLAY(c-label,LENGTH(c-label) + 1,2) = " " + CHR(171). 
   ELSE
      OVERLAY(c-label,LENGTH(c-label) + 1,2) = " " + CHR(187). 

   h-col:LABEL = c-label. 

   {&OPEN-QUERY-br-work} 

   APPLY "leave" TO br-work.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda D-Dialog
ON CHOOSE OF bt-ajuda IN FRAME D-Dialog /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO: /* Call Help Function (or a simple message). */
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel D-Dialog
ON CHOOSE OF bt-excel IN FRAME D-Dialog /* Button 2 */
DO:
  
   RUN esdlg/d02essp0190.w (OUTPUT arq-saida,
                            INPUT p-tipo-selecao,
                            INPUT p-dt-faturar,
                            INPUT p-dt-faturadas-ini,
                            INPUT p-dt-faturadas-fin,
                            INPUT p-dt-vendido-ini,
                            INPUT p-dt-vendido-fin).
   IF arq-saida <> "" THEN DO:
      RUN pi-gera-excel. 
      MESSAGE "O arquivo foi gerado em " TRIM(arq-saida) + "." SKIP 
              "Para acess†-lo,  abra-o atravÇs do Excel."
          VIEW-AS ALERT-BOX INFO BUTTONS OK. 
   END.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-exit
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exit D-Dialog
ON CHOOSE OF bt-exit IN FRAME D-Dialog
DO:
   APPLY 'CLOSE':U TO THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime D-Dialog
ON CHOOSE OF bt-imprime IN FRAME D-Dialog
DO:
  RUN pi-imprime.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vapara
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vapara D-Dialog
ON CHOOSE OF bt-vapara IN FRAME D-Dialog
DO:
   RUN esdlg/d01essp0190.w (OUTPUT c-codigo).

   IF c-codigo <> "" THEN DO:
      FIND FIRST tt-work WHERE
                 tt-work.cond-pagto = c-codigo NO-LOCK NO-ERROR.
      IF NOT AVAIL tt-work THEN DO.
         MESSAGE "C¢digo n∆o est† contido na seleá∆o!"
             VIEW-AS ALERT-BOX INFO BUTTONS OK.
         RETURN NO-APPLY.
      END.
      h-query:REPOSITION-TO-ROWID(ROWID(tt-work)) NO-ERROR. 
      APPLY 'VALUE-CHANGED' TO br-work. 
   END.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */
 ASSIGN FRAME d-dialog:TITLE = "Totais Por Vencimentos - ESSP0190E6".

 tt-work.cond-pagto:READ-ONLY IN BROWSE br-work       = YES.
 tt-work.und:READ-ONLY IN BROWSE br-work          = YES.
 tt-work.qtd:READ-ONLY IN BROWSE br-work          = YES.
 tt-work.vlr:READ-ONLY IN BROWSE br-work          = YES.
 tt-work.preco-medio:READ-ONLY IN BROWSE br-work  = YES.
 tt-work.qtd-devol:READ-ONLY IN BROWSE br-work    = YES.
 tt-work.vlr-devol:READ-ONLY IN BROWSE br-work    = YES.

 ASSIGN h-query  = br-work:QUERY.

{src/adm/template/dialogmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects D-Dialog  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available D-Dialog  _ADM-ROW-AVAILABLE
PROCEDURE adm-row-available :
/*------------------------------------------------------------------------------
  Purpose:     Dispatched to this procedure when the Record-
               Source has a new row available.  This procedure
               tries to get the new row (or foriegn keys) from
               the Record-Source and process it.
  Parameters:  <none>
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.             */
  {src/adm/template/row-head.i}

  /* Process the newly available records (i.e. display fields,
     open queries, and/or pass records on to any RECORD-TARGETS).    */
  {src/adm/template/row-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI D-Dialog  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Hide all frames. */
  HIDE FRAME D-Dialog.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI D-Dialog  _DEFAULT-ENABLE
PROCEDURE enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  DISPLAY fi-tot-qtd-m fi-tot-vlr-m fi-media-m fi-tot-qtd-dev-m fi-tot-vlr-dev-m 
          fi-tot-desc-m fi-tot-qtd-kg fi-tot-vlr-kg fi-media-kg 
          fi-tot-qtd-dev-kg fi-tot-vlr-dev-kg fi-tot-desc-kg fi-tot-qtd-und 
          fi-tot-vlr-und fi-media-und fi-tot-qtd-dev-und fi-tot-vlr-dev-und 
          fi-tot-desc-und fi-tot-geral fi-ger-vlr-dev 
      WITH FRAME D-Dialog.
  ENABLE br-work RECT-1 rt-buttom bt-vapara bt-excel bt-imprime bt-exit bt-ok 
         bt-cancela bt-ajuda 
      WITH FRAME D-Dialog.
  {&OPEN-BROWSERS-IN-QUERY-D-Dialog}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy D-Dialog 
PROCEDURE local-destroy :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'destroy':U ) .
  {include/i-logfin.i}

  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize D-Dialog 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* {utp/ut9000.i "ESSP0174A" "2.04.00.000"} */ 

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  FIND FIRST param-global NO-LOCK NO-ERROR.
  FIND FIRST empresa
       WHERE empresa.ep-codigo = param-global.empresa-prin NO-LOCK NO-ERROR. 
  ASSIGN c-empresa = (IF AVAIL empresa THEN empresa.razao-social ELSE "").

  RUN pi-processa.

  {&OPEN-QUERY-br-work}

  /* Marcar a coluna de classificaá∆o */
  ASSIGN h-col   = br-work:GET-BROWSE-COLUMN(1) IN FRAME {&FRAME-NAME}
         c-label = h-col:LABEL
         c-label-ori = c-label.
  OVERLAY(c-label,LENGTH(c-label) + 1,2) = " " + CHR(171). 
  ASSIGN h-col:LABEL         = c-label 
         h-col:LABEL-FGCOLOR = 3.

  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-abre-excel D-Dialog 
PROCEDURE pi-abre-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 CREATE "Excel.Application" chExcelApp NO-ERROR.
 IF chExcelApp <> ? THEN /* Cria a Planilha */
    ASSIGN chExcelApp:VISIBLE     = TRUE  /* A Planilha Ficar† Visivel */
           chExcelApp:SheetsInNewWorkbook = 1 /* Nı PLANILHAS A SEREM CRIADAS */
           chWorkbook             = chExcelApp:Workbooks:ADD() /* Cria Planilha */
           chworksheet            = chExcelapp:sheets:ITEM(1).


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-gera-excel D-Dialog 
PROCEDURE pi-gera-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  RUN pi-abre-excel.
  IF chExcelApp = ? THEN DO:
     MESSAGE "O Aplicativo EXCEL n∆o foi encontrado. N∆o Ç possivel a execuá∆o do programa."
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     ASSIGN arq-saida = "".
     RETURN.
  END.

  RUN pi-monta-planilha.

  /* Posiciona o Foco no Inicio da Planilha */
  chExcelApp:Range("A1"):SELECT.
  chExcelApp:Range("A:A"):EntireColumn:AutoFit.

  /* Posiciona na Planilha 1, Salva e Fecha */
  chWorkSheet = chExcelapp:Sheets:ITEM(1).
  chWorkbook:Worksheets(1):activate.

 /* ASSIGN arq-saida = "C:\TEMP\LIXO.XLS". */

  /* Salva e Fecha Planilha */
  OS-DELETE VALUE(arq-saida).

  /* chWorkBook:SaveAs(arq-saida,39,,,,,,,TRUE). /* Salva em formato mais Antigo EXCEL97 */ */
  chWorkBook:SaveAs(arq-saida,,,,,,,).  /* Salva na Vers∆o da planilha da ESTAÄ«O */
  chWorkBook:CLOSE().
  chExcelApp:QUIT().
  RELEASE OBJECT chExcelApp. 
  RELEASE OBJECT chworkBook.
  RELEASE OBJECT chworksheet.
    

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-cabec D-Dialog 
PROCEDURE pi-imp-cabec :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    PUT c-empresa FORMAT "x(40)"                  AT   1
        "DATA: "                                  AT  66
        STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  72
        "HORA: "                                  AT  88
        STRING(TIME,"hh:mm:ss")                   AT  94
        "PAG:"                                    AT 125
        i-pag FORMAT ">>>"                        AT 130
        SKIP(1).

    PUT c-titulo FORMAT "X(60)" AT 50 SKIP(1).


    PUT "VENCIMENTOS                                      UND    QUANTIDADE          VALOR   DESC PRATIC  PRECO MEDIO" AT 1.
    PUT "-----------------------------------------------  ---  ------------   ------------  ------------  -----------" AT 1.
         
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imprime D-Dialog 
PROCEDURE pi-imprime :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  DEF VAR h-prog AS HANDLE NO-UNDO.
  DEF VAR i-ct   AS INT.

  RUN utp/ut-utils.p PERSISTENT SET h-prog.


  RUN esapi/saida-imp.p (OUTPUT i-saida,
                         OUTPUT c-saida,
                         OUTPUT i-num-copias,
                         OUTPUT l-ok).

  CASE i-saida:
      WHEN 1 THEN DO.
          OUTPUT TO VALUE(c-saida) CONVERT TARGET "ibm850" PAGED PAGE-SIZE 62.
          PUT CONTROL "~033E~033(s18H".  /* ORIENTAÄ«O RETRATO & COMPACTA */
/*          PUT CONTROL "~033&l2S~033(s16H". /* DUPLEX BORDA CURTA */ */
/*          PUT CONTROL "~033&l1O~033(s16H". /* ORIENTAÄ«O PAISAGEM & COMPACTA */  */
      END.
      WHEN 2 THEN
          OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
      WHEN 3 THEN DO.
          ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0191-sint.tmp".
          OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
      END.
  END CASE.

  DO i-ct = 1 TO i-num-copias.
     ASSIGN i-pag      =  1
            i-lin      = 99.

     ASSIGN fi-tot-qtd-m  = 0 fi-tot-vlr-m   = 0 fi-tot-qtd-kg  = 0 
            fi-tot-vlr-kg = 0 fi-tot-qtd-und = 0 fi-tot-vlr-und = 0
            fi-tot-desc-m = 0 fi-tot-desc-kg = 0 fi-tot-desc-und = 0.

     FOR EACH b-tt-work NO-LOCK {&SORTBY-IMP-EXCEL}.
         IF i-lin > 62 THEN DO:
            RUN pi-imp-cabec.
            ASSIGN i-lin = 7.
         END.
         PUT b-tt-work.cond-pagto   FORMAT "x(40)"          AT   1 
             b-tt-work.un           FORMAT "x(3)"           AT  50
             b-tt-work.qtd          FORMAT "->,>>>,>>9.99"  AT  54
             b-tt-work.vlr          FORMAT "->,>>>,>>9.99"  AT  69
             b-tt-work.desc-pratic  FORMAT "->,>>>,>>9.99"  AT  83
             (b-tt-work.vlr /
              b-tt-work.qtd)        FORMAT "->>>,>>9.99"    AT  98.
         ASSIGN i-lin = i-lin + 1.
         CASE b-tt-work.un:
             WHEN 'M'   THEN
                 ASSIGN fi-tot-qtd-m = fi-tot-qtd-m + b-tt-work.qtd
                        fi-tot-vlr-m = fi-tot-vlr-m + b-tt-work.vlr
                        fi-tot-desc-m = fi-tot-desc-m + b-tt-work.desc-pratic.
             WHEN 'KG'  THEN
                 ASSIGN fi-tot-qtd-kg = fi-tot-qtd-kg + b-tt-work.qtd
                        fi-tot-vlr-kg = fi-tot-vlr-kg + b-tt-work.vlr
                        fi-tot-vlr-dev-kg = fi-tot-vlr-dev-kg + b-tt-work.vlr-devol.
             WHEN 'UN' THEN
                 ASSIGN fi-tot-qtd-und = fi-tot-qtd-und + b-tt-work.qtd
                        fi-tot-vlr-und = fi-tot-vlr-und + b-tt-work.vlr
                        fi-tot-desc-und = fi-tot-desc-und + b-tt-work.desc-pratic.
         END CASE.
     END.
     IF i-lin > 62 THEN DO:
        RUN pi-imp-cabec.
        ASSIGN i-lin = 7.
     END.
     PUT "---  ------------   ------------   -----------" AT 50.
     PUT "TOTAL GERAL:   M" AT 36.
     PUT fi-tot-qtd-m    FORMAT "->,>>>,>>9.99"  AT  54
         fi-tot-vlr-m    FORMAT "->,>>>,>>9.99"  AT  69
         fi-tot-desc-m   FORMAT "->,>>>,>>9.99"  AT  83.
     IF fi-tot-vlr-m > 0  THEN
     PUT (fi-tot-vlr-m / 
          fi-tot-qtd-m)  FORMAT "->>>,>>9.99"  AT  98.
     PUT "KG" AT 51.
     PUT fi-tot-qtd-kg    FORMAT "->,>>>,>>9.99"  AT  54
         fi-tot-vlr-kg    FORMAT "->,>>>,>>9.99"  AT  69
         fi-tot-desc-KG   FORMAT "->,>>>,>>9.99"  AT  83.
     IF fi-tot-vlr-kg > 0 THEN
     PUT (fi-tot-vlr-kg / 
          fi-tot-qtd-kg)  FORMAT "->>>,>>9.99"  AT  98.
     PUT "UND" AT 50.
     PUT fi-tot-qtd-und    FORMAT "->,>>>,>>9.99"  AT  54
         fi-tot-vlr-und    FORMAT "->,>>>,>>9.99"  AT  69
         fi-tot-desc-und   FORMAT "->,>>>,>>9.99"  AT  83.
     IF fi-tot-vlr-und > 0 THEN
     PUT (fi-tot-vlr-und / 
          fi-tot-qtd-und)  FORMAT "->>>,>>9.99"  AT  98.
     PUT "------------" AT 70.
     PUT (fi-tot-vlr-m +
          fi-tot-vlr-kg +
          fi-tot-vlr-und)   FORMAT "->,>>>,>>9.99"  AT  69.

     IF i-saida = 1 THEN DO:
        PAGE.
        PUT "" AT 1.
     END.
  END.
  IF i-saida = 3 THEN DO.
     RUN EXECUTE IN h-prog(INPUT "notepad.exe",
                           INPUT c-saida).
     DELETE PROCEDURE h-prog.
  END.
  OUTPUT CLOSE.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-monta-planilha D-Dialog 
PROCEDURE pi-monta-planilha :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 /* Nomear Aba da Planilha */
 chWorkSheet = chExcelapp:Sheets:ITEM(1).
 chWorkSheet:NAME = "Faturamento Por Grupos".
 chWorkSheet:TAB:ColorIndex = 19.

 /* Ativar a Planilha */
 chWorkSheet = chExcelapp:Sheets:ITEM(1).
 chWorkbook:Worksheets(1):activate.
 chExcelApp:ActiveWindow:Zoom = 100.

 ASSIGN chworksheet:range("A1"):VALUE = c-titulo.

 /* Configura Alinhamento Horizontal do Titulo da Planilha */
 ChWorkSheet:range("A1:F1"):SELECT().
 ChWorksheet:range("A1:F1"):Merge.
 Chworksheet:Range("A1:F1"):HorizontalAlignment =  3.
 /* Colorir Titulo da Planilha */
 chWorkSheet:Range("A1:F1"):FONT:ColorIndex     = 18. /* Avermelhado */
 chWorkSheet:Range("A1:F1"):Interior:ColorIndex = 2. /* Branco */

 /* Configura a Linha do Titulo da Planilha */
 ASSIGN chWorkSheet:Rows("1:1"):RowHeight = 25
        chWorkSheet:Rows("2:2"):RowHeight =  4
        chWorkSheet:Rows("1:1"):FONT:SIZE = 12
        chWorkSheet:Rows("1:1"):FONT:bold = TRUE.

 /* Titulo das Colunas */
 ASSIGN chworksheet:range("A3"):VALUE = "VENCIMENTOS"
        chworksheet:range("B3"):VALUE = "UND"  
        chworksheet:range("C3"):VALUE = "QUANTIDADE"
        chworksheet:range("D3"):VALUE = "VALOR"     
        chworksheet:range("E3"):VALUE = "VALOR"     
        chworksheet:range("F3"):VALUE = "PREÄO MêDIO". 


 /* Tamanho das Colunas */
 ASSIGN chWorkSheet:Columns("A"):ColumnWidth = 20
        chWorkSheet:Columns("B"):ColumnWidth =  4
        chWorkSheet:Columns("C"):ColumnWidth = 15
        chWorkSheet:Columns("D"):ColumnWidth = 15
        chWorkSheet:Columns("E"):ColumnWidth = 15
        chWorkSheet:Columns("F"):ColumnWidth = 11.

 /* Configura as Colunas da Planilha */
 ASSIGN chworksheet:range("A:B"):NumberFormat        = "@".
 ASSIGN chworksheet:range("C:F"):NumberFormat        = "###.###.##0,00"
        Chworksheet:range("C:F"):HorizontalAlignment = 4. /* Alinhamento a Direita */

 /* Configura Cabeáalho das Colunas */
 chWorkSheet:Range("A3:E3"):SELECT().
 ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
        chExcelApp:SELECTION:FONT:SIZE               = 09
        chExcelApp:SELECTION:FONT:Bold               = TRUE 
        chExcelApp:SELECTION:Interior:ColorIndex     = 19
        chExcelApp:SELECTION:FONT:ColorIndex         = 11.

 ASSIGN i-Lin    = 4.

ASSIGN fi-tot-qtd-m  = 0 fi-tot-vlr-m   = 0 fi-tot-qtd-kg  = 0 
       fi-tot-vlr-kg = 0 fi-tot-qtd-und = 0 fi-tot-vlr-und = 0
       fi-tot-desc-m = 0 fi-tot-desc-kg = 0 fi-tot-desc-und = 0.

FOR EACH b-tt-work NO-LOCK {&SORTBY-IMP-EXCEL}.
    ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.cond-pagto
           chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.un
           chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.qtd
           chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.vlr
           chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.desc-pratic
           chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.

    /*  Configura Tamanho da Fonte */
    ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
           chworksheet:Rows(c-lin):FONT:SIZE = 9.

    ASSIGN i-lin = i-lin + 1.

    CASE b-tt-work.un:
        WHEN 'M'   THEN
            ASSIGN fi-tot-qtd-m = fi-tot-qtd-m + b-tt-work.qtd
                   fi-tot-vlr-m = fi-tot-vlr-m + b-tt-work.vlr
                   fi-tot-desc-m = fi-tot-desc-m + b-tt-work.desc-pratic.
        WHEN 'KG'  THEN
            ASSIGN fi-tot-qtd-kg = fi-tot-qtd-kg + b-tt-work.qtd
                   fi-tot-vlr-kg = fi-tot-vlr-kg + b-tt-work.vlr
                   fi-tot-desc-kg = fi-tot-desc-kg + b-tt-work.desc-pratic.
        WHEN 'UN' THEN
            ASSIGN fi-tot-qtd-und = fi-tot-qtd-und + b-tt-work.qtd
                   fi-tot-vlr-und = fi-tot-vlr-und + b-tt-work.vlr
                   fi-tot-desc-und  = fi-tot-desc-und + b-tt-work.desc-pratic.
    END CASE.

END.
IF i-lin <> 4 THEN DO:
   ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = "TOTAL GERAL"
          chworksheet:range("B" + STRING(i-lin)):VALUE = "  M".
   ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = fi-tot-qtd-m     
          chworksheet:range("D" + STRING(i-lin)):VALUE = fi-tot-vlr-m     
          chworksheet:range("F" + STRING(i-lin)):VALUE = fi-tot-desc-m 
          chworksheet:range("F" + STRING(i-lin)):VALUE = (fi-tot-vlr-m / fi-tot-qtd-m). 
    /* Colorir a Linha / Negrito */
   ASSIGN chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):Interior:ColorIndex = 14
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:ColorIndex     =  2
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:Bold           = TRUE.
   ASSIGN i-lin = i-lin + 1.
   ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = " KG".
   ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = fi-tot-qtd-kg     
          chworksheet:range("D" + STRING(i-lin)):VALUE = fi-tot-vlr-kg     
          chworksheet:range("E" + STRING(i-lin)):VALUE = fi-tot-desc-kg 
          chworksheet:range("F" + STRING(i-lin)):VALUE = (fi-tot-vlr-kg / fi-tot-qtd-kg). 
    /* Colorir a Linha / Negrito */
   ASSIGN chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):Interior:ColorIndex = 14
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:ColorIndex     =  2
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:Bold           = TRUE.

   ASSIGN i-lin = i-lin + 1.
   ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = "UND".
   ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = fi-tot-qtd-und     
          chworksheet:range("D" + STRING(i-lin)):VALUE = fi-tot-vlr-und     
          chworksheet:range("E" + STRING(i-lin)):VALUE = fi-tot-desc-und     
          chworksheet:range("F" + STRING(i-lin)):VALUE = (fi-tot-vlr-und / fi-tot-qtd-und). 

    /* Colorir a Linha / Negrito */
   ASSIGN chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):Interior:ColorIndex = 14
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:ColorIndex     =  2
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:Bold           = TRUE.
   ASSIGN i-lin = i-lin + 2.
   ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "VALOR TOTAL DO FATURAMENTO".
   ASSIGN chworksheet:range("D" + STRING(i-lin)):VALUE = fi-tot-vlr-m + fi-tot-vlr-kg + fi-tot-vlr-und.     

    /* Colorir a Linha / Negrito */
   ASSIGN chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):Interior:ColorIndex = 18
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:ColorIndex     =  2
          chWorkSheet:Range("A" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:Bold           = TRUE.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-processa D-Dialog 
PROCEDURE pi-processa :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Selecionando_Totais *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 CASE p-tipo-selecao:
     WHEN 1 THEN DO:
         ASSIGN c-titulo = "ANALISE DA CARTEIRA A FATURAR NO PERIODO: " +            
                           SUBSTR(p-dt-faturar,1,2) + "/"+ SUBSTR(p-dt-faturar,3,4). 
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = c-titulo. 
     END.
     WHEN 2 THEN DO:
         ASSIGN c-titulo = "ANALISE DO FATURAMENTO DE: " +                   
                           STRING(p-dt-faturadas-ini, "99/99/9999") + " A " +
                           STRING(p-dt-faturadas-fin, "99/99/9999").         
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = c-titulo.
     END.
     WHEN 3 THEN DO:
         ASSIGN c-titulo = "ANALISE DAS VENDAS DE: " +                                                  
                           SUBSTR(p-dt-vendido-ini,1,2) + "/"+ SUBSTR(p-dt-vendido-ini,3,4) + " A " +   
                           SUBSTR(p-dt-vendido-fin,1,2) + "/"+ SUBSTR(p-dt-vendido-fin,3,4).            
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = c-titulo.
     END.
 END CASE.
 
 FOR EACH tt-trab WHERE
     tt-trab.cond-pagto <> "" AND
     tt-trab.uf      = "ZZ" NO-LOCK.
     CREATE tt-work.
     ASSIGN tt-work.cond-pagto  = tt-trab.cond-pagto
            tt-work.Und         = tt-trab.und
            tt-work.qtd         = tt-trab.qtd
            tt-work.vlr         = tt-trab.vlr
            tt-work.preco-medio = tt-trab.preco-medio
            tt-work.qtd-devol   = tt-trab.qtd-devol
            tt-work.vlr-devol   = tt-trab.vlr-devol.
 END.                

 RUN pi-finalizar in h-acomp.
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-total D-Dialog 
PROCEDURE pi-total :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 ASSIGN fi-tot-qtd-m       = 0
        fi-tot-qtd-kg      = 0
        fi-tot-qtd-und     = 0
        fi-tot-qtd-dev-m   = 0
        fi-tot-qtd-dev-kg  = 0
        fi-tot-qtd-dev-und = 0
        fi-tot-vlr-m       = 0
        fi-tot-vlr-kg      = 0
        fi-tot-vlr-und     = 0
        fi-tot-desc-m      = 0
        fi-tot-desc-kg     = 0
        fi-tot-desc-und    = 0
        fi-tot-vlr-dev-m   = 0
        fi-tot-vlr-dev-kg  = 0
        fi-tot-vlr-dev-und = 0.
 FOR EACH tt-work NO-LOCK.
     CASE tt-work.und:
         WHEN "M" THEN
             ASSIGN fi-tot-qtd-m     = fi-tot-qtd-m     + tt-work.qtd  
                    fi-tot-vlr-m     = fi-tot-vlr-m     + tt-work.vlr
                    fi-tot-desc-m    = fi-tot-desc-m    + tt-work.desc-pratic
                    fi-tot-qtd-dev-m = fi-tot-qtd-dev-m + tt-work.qtd-devol
                    fi-tot-vlr-dev-m = fi-tot-vlr-dev-m + tt-work.vlr-devol.
         WHEN "KG" THEN
             ASSIGN fi-tot-qtd-kg     = fi-tot-qtd-kg     + tt-work.qtd  
                    fi-tot-vlr-kg     = fi-tot-vlr-kg     + tt-work.vlr
                    fi-tot-desc-kg    = fi-tot-desc-kg    + tt-work.desc-pratic
                    fi-tot-qtd-dev-kg = fi-tot-qtd-dev-kg + tt-work.qtd-devol
                    fi-tot-vlr-dev-kg = fi-tot-vlr-dev-kg + tt-work.vlr-devol.
         WHEN "UN" THEN
             ASSIGN fi-tot-qtd-und     = fi-tot-qtd-und     + tt-work.qtd  
                    fi-tot-vlr-und     = fi-tot-vlr-und     + tt-work.vlr
                    fi-tot-desc-und  = fi-tot-desc-und + tt-work.desc-pratic
                    fi-tot-qtd-dev-und = fi-tot-qtd-dev-und + tt-work.qtd-devol
                    fi-tot-vlr-dev-und = fi-tot-vlr-dev-und + tt-work.vlr-devol.
     END CASE.
 END.
 ASSIGN fi-media-m     = fi-tot-vlr-m / fi-tot-qtd-m
        fi-media-kg    = fi-tot-vlr-kg / fi-tot-qtd-kg
        fi-media-und   = fi-tot-vlr-und / fi-tot-vlr-und
        fi-tot-geral   = fi-tot-vlr-m + fi-tot-vlr-kg + fi-tot-vlr-und
        fi-ger-vlr-dev = fi-tot-vlr-dev-m + fi-tot-vlr-dev-kg + fi-tot-vlr-dev-und.

 DISP fi-tot-qtd-m 
      fi-tot-vlr-m 
      fi-media-m WHEN fi-media-m > 0
      fi-tot-qtd-dev-m
      fi-tot-vlr-dev-m
      fi-tot-qtd-kg
      fi-tot-vlr-kg
      fi-media-kg   WHEN fi-media-kg > 0
      fi-tot-qtd-dev-kg
      fi-tot-vlr-dev-kg
      fi-tot-qtd-und
      fi-tot-vlr-und
      fi-media-und WHEN fi-media-und > 0
      fi-tot-qtd-dev-und
      fi-tot-vlr-dev-und
      fi-tot-geral
      fi-ger-vlr-dev
      fi-tot-desc-m
      fi-tot-desc-kg
      fi-tot-desc-und
      WITH FRAME {&FRAME-NAME}.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records D-Dialog  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-work"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed D-Dialog 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
  
  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

