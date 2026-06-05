&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-digita 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i XX9999 9.99.99.999}
/*------------------------------------------------------------------------

  File: 

  Description: from cntnrwin.w - ADM SmartWindow Template

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  History: 
          
------------------------------------------------------------------------*/
/*          This .W file was created with the Progress UIB.             */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */
DEF TEMP-TABLE tt-digita
    FIELD opcao  AS CHAR
    FIELD campo AS CHAR
    FIELD valor AS CHAR.

/* Local Variable Definitions ---                                       */
DEF TEMP-TABLE tt-estoque
    FIELD cod-estabel   LIKE saldo-estoq.cod-estabel
    FIELD it-codigo     LIKE saldo-estoq.it-codigo
    FIELD desc-item     LIKE item.desc-item    
    FIELD cod-refer     LIKE saldo-estoq.cod-refer    
    FIELD fm-cod-com    LIKE item.fm-cod-com
    FIELD un            LIKE item.un
    FIELD qtidade-atu   LIKE saldo-estoq.qtidade-atu
    FIELD dt-ult-compra AS DATE FORMAT "99/99/9999"
    FIELD marca         AS LOG INIT NO
    INDEX indice1 it-codigo cod-refer.

DEF TEMP-TABLE tt-liquida-ima LIKE tt-estoque
    FIELD preco-item  AS DECIMAL FORMAT ">>9.99"
    FIELD preco-tab   AS DECIMAL FORMAT ">>9.99"
    FIELD dt-inicio   LIKE liquida-ima.dt-inicio
    FIELD dt-final    LIKE liquida-ima.dt-final
    FIELD acao        AS    CHAR.

DEF TEMP-TABLE tt-aux
    FIELD it-codigo AS CHAR
    FIELD cod-refer AS CHAR
    FIELD preco-item AS DECIMAL.

DEF BUFFER b-tt-liquida-ima FOR tt-liquida-ima.
DEF BUFFER b-tt-estoque FOR tt-estoque.

DEFINE VARIABLE h-acomp   AS HANDLE     NO-UNDO.
DEFINE VARIABLE i-row     AS INT.
DEFINE VARIABLE i-font    AS INT.
DEFINE VARIABLE c-erro    AS CHAR.
DEFINE VARIABLE c-num-id  AS CHAR.
DEFINE VARIABLE c-arquivo AS CHAR.
DEFINE VARIABLE l-ok      AS LOGICAL.

DEFINE VARIABLE c-item    AS CHAR.
DEFINE VARIABLE c-refer   AS CHAR.

// Vari†veis Excel
DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF var chWorksheet AS COM-HANDLE NO-UNDO.
DEF VAR cFileName   AS CHAR.
DEF VAR i-Lin       AS INT INITIAL 2.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Digitacao
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME br-estoque

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-estoque tt-liquida-ima

/* Definitions for BROWSE br-estoque                                    */
&Scoped-define FIELDS-IN-QUERY-br-estoque tt-estoque.it-codigo tt-estoque.cod-refer tt-estoque.qtidade-atu tt-estoque.un tt-estoque.dt-ult-compra   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-estoque   
&Scoped-define SELF-NAME br-estoque
&Scoped-define QUERY-STRING-br-estoque FOR EACH tt-estoque WHERE                                  tt-estoque.it-codigo  >= fi-it-codigo-ini AND                                  tt-estoque.it-codigo  <= fi-it-codigo-fin AND                                  tt-estoque.cod-refer  >= fi-cod-refer-ini AND                                  tt-estoque.cod-refer  <= fi-cod-refer-fin AND                                  tt-estoque.fm-cod-com >= fi-fm-codigo-ini AND                                  tt-estoque.fm-cod-com <= fi-fm-codigo-fin AND                                  (tt-estoque.cod-refer = '888' OR tg-rp) AND                                  (tt-estoque.cod-refer <> '888' OR tg-rd)                                  NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-estoque OPEN QUERY {&SELF-NAME} FOR EACH tt-estoque WHERE                                  tt-estoque.it-codigo  >= fi-it-codigo-ini AND                                  tt-estoque.it-codigo  <= fi-it-codigo-fin AND                                  tt-estoque.cod-refer  >= fi-cod-refer-ini AND                                  tt-estoque.cod-refer  <= fi-cod-refer-fin AND                                  tt-estoque.fm-cod-com >= fi-fm-codigo-ini AND                                  tt-estoque.fm-cod-com <= fi-fm-codigo-fin AND                                  (tt-estoque.cod-refer = '888' OR tg-rp) AND                                  (tt-estoque.cod-refer <> '888' OR tg-rd)                                  NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-estoque tt-estoque
&Scoped-define FIRST-TABLE-IN-QUERY-br-estoque tt-estoque


/* Definitions for BROWSE br-liquida                                    */
&Scoped-define FIELDS-IN-QUERY-br-liquida tt-liquida-ima.it-codigo tt-liquida-ima.cod-refer tt-liquida-ima.un tt-liquida-ima.qtidade-atu tt-liquida-ima.preco-tab tt-liquida-ima.preco-item   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-liquida   
&Scoped-define SELF-NAME br-liquida
&Scoped-define QUERY-STRING-br-liquida FOR EACH tt-liquida-ima WHERE                                  tt-liquida-ima.dt-final   = ? AND                                  tt-liquida-ima.it-codigo  >= fi-it-codigo-ini AND                                  tt-liquida-ima.it-codigo  <= fi-it-codigo-fin AND                                  tt-liquida-ima.cod-refer  >= fi-cod-refer-ini AND                                  tt-liquida-ima.cod-refer  <= fi-cod-refer-fin AND                                  tt-liquida-ima.fm-cod-com >= fi-fm-codigo-ini AND                                  tt-liquida-ima.fm-cod-com <= fi-fm-codigo-fin AND                                  (tt-liquida-ima.cod-refer = '888' OR tg-rp) AND                                  (tt-liquida-ima.cod-refer <> '888' OR tg-rd)                                  NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-liquida OPEN QUERY {&SELF-NAME} FOR EACH tt-liquida-ima WHERE                                  tt-liquida-ima.dt-final   = ? AND                                  tt-liquida-ima.it-codigo  >= fi-it-codigo-ini AND                                  tt-liquida-ima.it-codigo  <= fi-it-codigo-fin AND                                  tt-liquida-ima.cod-refer  >= fi-cod-refer-ini AND                                  tt-liquida-ima.cod-refer  <= fi-cod-refer-fin AND                                  tt-liquida-ima.fm-cod-com >= fi-fm-codigo-ini AND                                  tt-liquida-ima.fm-cod-com <= fi-fm-codigo-fin AND                                  (tt-liquida-ima.cod-refer = '888' OR tg-rp) AND                                  (tt-liquida-ima.cod-refer <> '888' OR tg-rd)                                  NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-liquida tt-liquida-ima
&Scoped-define FIRST-TABLE-IN-QUERY-br-liquida tt-liquida-ima


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-br-estoque}~
    ~{&OPEN-QUERY-br-liquida}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 IMAGE-2 IMAGE-73 RECT-57 IMAGE-106 ~
IMAGE-107 IMAGE-108 IMAGE-109 RECT-58 RECT-60 bt-processa fi-it-codigo-ini ~
fi-it-codigo-fin bt-dig-item bt-ex-item tg-rp fi-cod-refer-ini ~
fi-cod-refer-fin bt-dig-ref bt-ex-ref tg-rd fi-fm-codigo-ini ~
fi-fm-codigo-fin bt-dig-fam bt-ex-fam br-estoque br-liquida bt-excel ~
fi-preco-item fi-dt-inicio bt-ajuda bt-ok bt-cancelar 
&Scoped-Define DISPLAYED-OBJECTS fi-it-codigo-ini fi-it-codigo-fin tg-rp ~
fi-cod-refer-ini fi-cod-refer-fin tg-rd fi-fm-codigo-ini fi-fm-codigo-fin ~
fi-desc-it-est fi-desc-it-liq fi-preco-item fi-dt-inicio 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-1 fi-it-codigo-ini fi-it-codigo-fin fi-cod-refer-ini ~
fi-cod-refer-fin fi-fm-codigo-ini fi-fm-codigo-fin 
&Scoped-define List-3 bt-marca-est bt-desmarca-est bt-todos-est ~
bt-nenhum-est bt-marca-liq bt-desmarca-liq bt-todos-liq bt-nenhum-liq 
&Scoped-define List-6 bt-excel 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-digita AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-add 
     IMAGE-UP FILE "image/im-add.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25.

DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Sair" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-del 
     IMAGE-UP FILE "image/im-era.bmp":U
     LABEL "" 
     SIZE 5 BY 1.29.

DEFINE BUTTON bt-desmarca-est AUTO-GO 
     IMAGE-UP FILE "image/im-cllps.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Desmarca Referencia"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-desmarca-liq AUTO-GO 
     IMAGE-UP FILE "image/im-cllps.bmp":U
     LABEL "" 
     SIZE 4 BY 1.25 TOOLTIP "Desmarca Referencia"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-dig-fam 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Itens".

DEFINE BUTTON bt-dig-item 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Itens".

DEFINE BUTTON bt-dig-ref 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Itens".

DEFINE BUTTON bt-ex-fam 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Itens".

DEFINE BUTTON bt-ex-item 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Itens".

DEFINE BUTTON bt-ex-ref 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Itens".

DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/excel.bmp":U
     LABEL "Button 2" 
     SIZE 5 BY 1.29 TOOLTIP "Importa ou Exporta Dados EXCEL".

DEFINE BUTTON bt-marca-est AUTO-GO 
     IMAGE-UP FILE "image/im-expan.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Marca Refeància"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-marca-liq AUTO-GO 
     IMAGE-UP FILE "image/im-expan.bmp":U
     LABEL "" 
     SIZE 4 BY 1.25 TOOLTIP "Marca Refeància"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-nenhum-est AUTO-GO 
     IMAGE-UP FILE "image/im-nenhum.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Desmarca TODAS as Referencias"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-nenhum-liq AUTO-GO 
     IMAGE-UP FILE "image/im-nenhum.bmp":U
     LABEL "" 
     SIZE 4 BY 1.25 TOOLTIP "Desmarca TODAS as Referencias"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "Efetivar Alteraá‰es" 
     SIZE 19.14 BY 1.

DEFINE BUTTON bt-processa 
     IMAGE-UP FILE "image/im-chck2.bmp":U
     LABEL "Processa" 
     SIZE 15 BY 2.75.

DEFINE BUTTON bt-todos-est AUTO-GO 
     IMAGE-UP FILE "image\im-ran_a.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Marca TODAS as Referencias"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-todos-liq AUTO-GO 
     IMAGE-UP FILE "image\im-ran_a.bmp":U
     LABEL "" 
     SIZE 4 BY 1.25 TOOLTIP "Marca TODAS as Referencias"
     BGCOLOR 8 FONT 10.

DEFINE VARIABLE fi-cod-refer-fin AS CHARACTER FORMAT "X(12)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cod-refer-ini AS CHARACTER FORMAT "X(12)":U 
     LABEL "Referància" 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-it-est AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 48 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-it-liq AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 60 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-inicio AS DATE FORMAT "99/99/9999":U 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-fm-codigo-fin AS CHARACTER FORMAT "X(12)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE VARIABLE fi-fm-codigo-ini AS CHARACTER FORMAT "X(12)":U 
     LABEL "Categoria" 
     VIEW-AS FILL-IN 
     SIZE 5.14 BY .88 NO-UNDO.

DEFINE VARIABLE fi-it-codigo-fin AS CHARACTER FORMAT "X(12)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-it-codigo-ini AS CHARACTER FORMAT "X(12)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-preco-item AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-106
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-107
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-108
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-109
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-73
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 110.29 BY 1.38
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-57
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 110 BY 3.75.

DEFINE RECTANGLE RECT-58
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 60 BY 2.13.

DEFINE RECTANGLE RECT-60
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 48 BY 2.13.

DEFINE VARIABLE tg-rd AS LOGICAL INITIAL yes 
     LABEL "2¶ Qualidade" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.43 BY .88 TOOLTIP "Apenas Rolo de 2¶ Qualidade." NO-UNDO.

DEFINE VARIABLE tg-rp AS LOGICAL INITIAL yes 
     LABEL "1¶ Qualidade" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.43 BY .88 TOOLTIP "Apenas Rolo de 1¶ Qualidade ." NO-UNDO.

DEFINE BUTTON bt-ajuda-excel 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-arquivo 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4.29 BY 1.

DEFINE BUTTON bt-cancela 
     LABEL "Cancela" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-importa 
     LABEL "OK" 
     SIZE 10 BY 1.

DEFINE VARIABLE fi-arquivo AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 50 BY .88 NO-UNDO.

DEFINE VARIABLE text-entrada AS CHARACTER FORMAT "X(256)":U INITIAL " Arquivo de Entrada" 
      VIEW-AS TEXT 
     SIZE 14.86 BY .63 NO-UNDO.

DEFINE VARIABLE rs-opcao AS INTEGER 
     VIEW-AS RADIO-SET VERTICAL
     RADIO-BUTTONS 
          "Importar Dados do Excel", 1,
"Exportar Dados para Excel", 2
     SIZE 23 BY 2
     FONT 1 NO-UNDO.

DEFINE RECTANGLE RECT-61
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 57 BY 1.38
     BGCOLOR 8 .

DEFINE RECTANGLE RECT-62
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 57 BY 1.75.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-estoque FOR 
      tt-estoque SCROLLING.

DEFINE QUERY br-liquida FOR 
      tt-liquida-ima SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-estoque
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-estoque w-digita _FREEFORM
  QUERY br-estoque NO-LOCK DISPLAY
      tt-estoque.it-codigo     COLUMN-LABEL "Item" 
      tt-estoque.cod-refer     COLUMN-LABEL "Ref" 
      tt-estoque.qtidade-atu   COLUMN-LABEL "Qtde Dispon°vel" 
      tt-estoque.un            COLUMN-LABEL "Un" 
      tt-estoque.dt-ult-compra COLUMN-LABEL "Ult.Compra"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 48 BY 13
         FONT 1
         TITLE "Estoque Dispon°vel".

DEFINE BROWSE br-liquida
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-liquida w-digita _FREEFORM
  QUERY br-liquida NO-LOCK DISPLAY
      tt-liquida-ima.it-codigo      COLUMN-LABEL "Item"              
      tt-liquida-ima.cod-refer      COLUMN-LABEL "Ref"               
      tt-liquida-ima.un             COLUMN-LABEL "Un"                
      tt-liquida-ima.qtidade-atu    COLUMN-LABEL "Qtde Dispon°vel"    
      tt-liquida-ima.preco-tab      COLUMN-LABEL "Preáo TAB" 
      tt-liquida-ima.preco-item     COLUMN-LABEL "Preáo RUBI"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 60 BY 13
         FONT 1
         TITLE "Estoque Tabela RUBI".


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     bt-processa AT ROW 1.67 COL 95 WIDGET-ID 488
     fi-it-codigo-ini AT ROW 1.75 COL 15 COLON-ALIGNED WIDGET-ID 72
     fi-it-codigo-fin AT ROW 1.75 COL 36.14 COLON-ALIGNED NO-LABEL WIDGET-ID 70
     bt-dig-item AT ROW 1.75 COL 50.14 WIDGET-ID 54 NO-TAB-STOP 
     bt-ex-item AT ROW 1.75 COL 54.57 WIDGET-ID 58 NO-TAB-STOP 
     tg-rp AT ROW 2.25 COL 64 WIDGET-ID 452
     fi-cod-refer-ini AT ROW 2.75 COL 15 COLON-ALIGNED WIDGET-ID 476
     fi-cod-refer-fin AT ROW 2.75 COL 36.14 COLON-ALIGNED NO-LABEL WIDGET-ID 474
     bt-dig-ref AT ROW 2.75 COL 50.14 WIDGET-ID 470 NO-TAB-STOP 
     bt-ex-ref AT ROW 2.75 COL 54.57 WIDGET-ID 472 NO-TAB-STOP 
     tg-rd AT ROW 3 COL 64 WIDGET-ID 450
     fi-fm-codigo-ini AT ROW 3.75 COL 14.86 COLON-ALIGNED WIDGET-ID 442
     fi-fm-codigo-fin AT ROW 3.75 COL 36 COLON-ALIGNED NO-LABEL WIDGET-ID 440
     bt-dig-fam AT ROW 3.75 COL 50.14 WIDGET-ID 436 NO-TAB-STOP 
     bt-ex-fam AT ROW 3.75 COL 54.57 WIDGET-ID 438 NO-TAB-STOP 
     br-estoque AT ROW 5 COL 2 WIDGET-ID 500
     br-liquida AT ROW 5 COL 52 WIDGET-ID 600
     fi-desc-it-est AT ROW 18.08 COL 2 NO-LABEL WIDGET-ID 466
     fi-desc-it-liq AT ROW 18.08 COL 50 COLON-ALIGNED NO-LABEL WIDGET-ID 468
     bt-marca-est AT ROW 19.5 COL 3.14 WIDGET-ID 460
     bt-desmarca-est AT ROW 19.5 COL 8.72 WIDGET-ID 458
     bt-todos-est AT ROW 19.5 COL 14.43 WIDGET-ID 464
     bt-nenhum-est AT ROW 19.5 COL 20 WIDGET-ID 462
     bt-add AT ROW 19.5 COL 28.29 WIDGET-ID 454
     bt-marca-liq AT ROW 19.5 COL 53 WIDGET-ID 430
     bt-desmarca-liq AT ROW 19.5 COL 57.57 WIDGET-ID 428
     bt-todos-liq AT ROW 19.5 COL 62.14 WIDGET-ID 434
     bt-nenhum-liq AT ROW 19.5 COL 66.72 WIDGET-ID 432
     bt-del AT ROW 19.5 COL 74.14 WIDGET-ID 456
     bt-excel AT ROW 19.5 COL 81.43 WIDGET-ID 484
     fi-preco-item AT ROW 20.04 COL 86.43 COLON-ALIGNED NO-LABEL WIDGET-ID 486
     fi-dt-inicio AT ROW 20.08 COL 98.14 COLON-ALIGNED NO-LABEL WIDGET-ID 494
     bt-ajuda AT ROW 21.63 COL 100.86
     bt-ok AT ROW 21.67 COL 2.86
     bt-cancelar AT ROW 21.67 COL 23
     "In°cio Validade" VIEW-AS TEXT
          SIZE 11 BY .54 AT ROW 19.42 COL 100.14 WIDGET-ID 492
     " Seleá∆o" VIEW-AS TEXT
          SIZE 7 BY .54 AT ROW 1 COL 3.43 WIDGET-ID 426
     "Preáo Rubi" VIEW-AS TEXT
          SIZE 10.29 BY .54 AT ROW 19.42 COL 88.43 WIDGET-ID 490
     RECT-1 AT ROW 21.46 COL 1.72
     IMAGE-2 AT ROW 1.75 COL 34.29 WIDGET-ID 76
     IMAGE-73 AT ROW 1.79 COL 29.14 WIDGET-ID 82
     RECT-57 AT ROW 1.25 COL 2 WIDGET-ID 424
     IMAGE-106 AT ROW 3.75 COL 34.14 WIDGET-ID 444
     IMAGE-107 AT ROW 3.79 COL 29 WIDGET-ID 446
     IMAGE-108 AT ROW 2.75 COL 34.29 WIDGET-ID 478
     IMAGE-109 AT ROW 2.79 COL 29.14 WIDGET-ID 480
     RECT-58 AT ROW 19.08 COL 52 WIDGET-ID 496
     RECT-60 AT ROW 19.08 COL 2 WIDGET-ID 500
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 112.57 BY 22.08
         FONT 1 WIDGET-ID 100.

DEFINE FRAME frm-excel
     rs-opcao AT ROW 1.58 COL 3 NO-LABEL WIDGET-ID 2
     bt-arquivo AT ROW 5.42 COL 53.72 HELP
          "Escolha do nome do arquivo" WIDGET-ID 16
     fi-arquivo AT ROW 5.5 COL 1 COLON-ALIGNED NO-LABEL WIDGET-ID 10
     bt-importa AT ROW 7.21 COL 2.86 WIDGET-ID 6
     bt-cancela AT ROW 7.21 COL 13.14 WIDGET-ID 8
     bt-ajuda-excel AT ROW 7.21 COL 48 WIDGET-ID 20
     text-entrada AT ROW 4.67 COL 3.14 NO-LABEL WIDGET-ID 18
     RECT-61 AT ROW 7 COL 2 WIDGET-ID 12
     RECT-62 AT ROW 5 COL 2 WIDGET-ID 14
    WITH 1 DOWN KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 22 ROW 6.5
         SIZE 59 BY 8.5
         FONT 1
         TITLE "Importa / Exporta dados EXCEL" WIDGET-ID 700.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: Digitacao
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Design Page: 1
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-digita ASSIGN
         HIDDEN             = YES
         TITLE              = "Template de Digitaá∆o"
         HEIGHT             = 22.08
         WIDTH              = 112.57
         MAX-HEIGHT         = 22.08
         MAX-WIDTH          = 147
         VIRTUAL-HEIGHT     = 22.08
         VIRTUAL-WIDTH      = 147
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = no
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-digita 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-digit.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-digita
  VISIBLE,,RUN-PERSISTENT                                               */
/* REPARENT FRAME */
ASSIGN FRAME frm-excel:FRAME = FRAME F-Main:HANDLE.

/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
/* BROWSE-TAB br-estoque bt-ex-fam F-Main */
/* BROWSE-TAB br-liquida br-estoque F-Main */
/* SETTINGS FOR BUTTON bt-add IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-del IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-desmarca-est IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-desmarca-liq IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-excel IN FRAME F-Main
   6                                                                    */
/* SETTINGS FOR BUTTON bt-marca-est IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-marca-liq IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-nenhum-est IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-nenhum-liq IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-todos-est IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR BUTTON bt-todos-liq IN FRAME F-Main
   NO-ENABLE 3                                                          */
/* SETTINGS FOR FILL-IN fi-cod-refer-fin IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-cod-refer-ini IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-desc-it-est IN FRAME F-Main
   NO-ENABLE ALIGN-L                                                    */
/* SETTINGS FOR FILL-IN fi-desc-it-liq IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-fm-codigo-fin IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-fm-codigo-ini IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-it-codigo-fin IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-it-codigo-ini IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FRAME frm-excel
                                                                        */
/* SETTINGS FOR FILL-IN text-entrada IN FRAME frm-excel
   NO-DISPLAY NO-ENABLE ALIGN-L                                         */
ASSIGN 
       text-entrada:PRIVATE-DATA IN FRAME frm-excel     = 
                " Arquivo de Entrada".

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-digita)
THEN w-digita:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-estoque
/* Query rebuild information for BROWSE br-estoque
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-estoque WHERE
                                 tt-estoque.it-codigo  >= fi-it-codigo-ini AND
                                 tt-estoque.it-codigo  <= fi-it-codigo-fin AND
                                 tt-estoque.cod-refer  >= fi-cod-refer-ini AND
                                 tt-estoque.cod-refer  <= fi-cod-refer-fin AND
                                 tt-estoque.fm-cod-com >= fi-fm-codigo-ini AND
                                 tt-estoque.fm-cod-com <= fi-fm-codigo-fin AND
                                 (tt-estoque.cod-refer = '888' OR tg-rp) AND
                                 (tt-estoque.cod-refer <> '888' OR tg-rd)
                                 NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-estoque */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-liquida
/* Query rebuild information for BROWSE br-liquida
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-liquida-ima WHERE
                                 tt-liquida-ima.dt-final   = ? AND
                                 tt-liquida-ima.it-codigo  >= fi-it-codigo-ini AND
                                 tt-liquida-ima.it-codigo  <= fi-it-codigo-fin AND
                                 tt-liquida-ima.cod-refer  >= fi-cod-refer-ini AND
                                 tt-liquida-ima.cod-refer  <= fi-cod-refer-fin AND
                                 tt-liquida-ima.fm-cod-com >= fi-fm-codigo-ini AND
                                 tt-liquida-ima.fm-cod-com <= fi-fm-codigo-fin AND
                                 (tt-liquida-ima.cod-refer = '888' OR tg-rp) AND
                                 (tt-liquida-ima.cod-refer <> '888' OR tg-rd)
                                 NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-liquida */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-digita w-digita
ON END-ERROR OF w-digita /* Template de Digitaá∆o */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-digita w-digita
ON WINDOW-CLOSE OF w-digita /* Template de Digitaá∆o */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-estoque
&Scoped-define SELF-NAME br-estoque
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-estoque w-digita
ON MOUSE-SELECT-DBLCLICK OF br-estoque IN FRAME F-Main /* Estoque Dispon°vel */
DO:
   IF tt-estoque.marca THEN
      APPLY "CHOOSE" TO bt-desmarca-est.
   ELSE
      APPLY "CHOOSE" TO bt-marca-est.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-estoque w-digita
ON ROW-DISPLAY OF br-estoque IN FRAME F-Main /* Estoque Dispon°vel */
DO:
   ASSIGN i-font = ?.
   IF tt-estoque.marca THEN
      ASSIGN i-font = 6.

   ASSIGN tt-estoque.it-codigo:FONT IN BROWSE br-estoque = i-font
          tt-estoque.cod-refer:FONT = i-font     
          tt-estoque.qtidade-atu:FONT = i-font        
          tt-estoque.un:FONT = i-font     
          tt-estoque.dt-ult-compra:FONT = i-font.     
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-estoque w-digita
ON VALUE-CHANGED OF br-estoque IN FRAME F-Main /* Estoque Dispon°vel */
DO:
   ASSIGN bt-marca-est:SENSITIVE = NO
          bt-desmarca-est:SENSITIVE = NO
          bt-todos-est:SENSITIVE = NO
          bt-nenhum-est:SENSITIVE = NO
          bt-add:SENSITIVE = NO.
   IF AVAIL tt-estoque THEN DO.
      ASSIGN fi-desc-it-est:SCREEN-VALUE = tt-estoque.desc-item.

      ASSIGN bt-marca-est:SENSITIVE = YES
             bt-desmarca-est:SENSITIVE = YES
             bt-todos-est:SENSITIVE = YES
             bt-nenhum-est:SENSITIVE = YES.

      ASSIGN bt-add:SENSITIVE = CAN-FIND(FIRST b-tt-estoque WHERE b-tt-estoque.marca = YES).

   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-liquida
&Scoped-define SELF-NAME br-liquida
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-liquida w-digita
ON MOUSE-SELECT-DBLCLICK OF br-liquida IN FRAME F-Main /* Estoque Tabela RUBI */
DO:
  IF tt-liquida-ima.marca THEN
     APPLY "CHOOSE" TO bt-desmarca-liq.
  ELSE
     APPLY "CHOOSE" TO bt-marca-liq.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-liquida w-digita
ON ROW-DISPLAY OF br-liquida IN FRAME F-Main /* Estoque Tabela RUBI */
DO:
   ASSIGN i-font = ?.
   IF tt-liquida-ima.marca THEN
      ASSIGN i-font = 6.

   ASSIGN tt-liquida-ima.it-codigo:FONT IN BROWSE br-liquida = i-font
          tt-liquida-ima.cod-refer:FONT = i-font     
          tt-liquida-ima.qtidade-atu:FONT = i-font        
          tt-liquida-ima.un:FONT = i-font     
          tt-liquida-ima.preco-item:FONT = i-font.  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-liquida w-digita
ON VALUE-CHANGED OF br-liquida IN FRAME F-Main /* Estoque Tabela RUBI */
DO:
    ASSIGN bt-marca-liq:SENSITIVE = NO
           bt-desmarca-liq:SENSITIVE = NO
           bt-todos-liq:SENSITIVE = NO
           bt-nenhum-liq:SENSITIVE = NO
           bt-del:SENSITIVE = NO
           bt-excel:SENSITIVE = NO.

    ASSIGN fi-preco-item:SENSITIVE = NO
           fi-dt-inicio:SENSITIVE = NO.

    IF AVAIL tt-liquida-ima THEN DO.
       ASSIGN fi-desc-it-liq:SCREEN-VALUE = tt-liquida-ima.desc-item
              fi-preco-item:SCREEN-VALUE = STRING(tt-liquida-ima.preco-item)
              fi-dt-inicio:SCREEN-VALUE = STRING(tt-liquida-ima.dt-inicio).

       ASSIGN bt-marca-liq:SENSITIVE = YES
              bt-desmarca-liq:SENSITIVE = YES
              bt-todos-liq:SENSITIVE = YES
              bt-nenhum-liq:SENSITIVE = YES
              bt-excel:SENSITIVE = YES.

       IF CAN-FIND(FIRST b-tt-liquida-ima WHERE 
                         b-tt-liquida-ima.marca = YES) THEN
          ASSIGN bt-del:SENSITIVE = YES 
                 fi-preco-item:SENSITIVE = YES
                 fi-dt-inicio:SENSITIVE = YES.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-add
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-add w-digita
ON CHOOSE OF bt-add IN FRAME F-Main
DO:
    FOR EACH tt-estoque WHERE  
             tt-estoque.marca NO-LOCK.
        FIND tt-liquida-ima WHERE
             tt-liquida-ima.cod-estab = tt-estoque.cod-estab AND
             tt-liquida-ima.it-codigo = tt-estoque.it-codigo AND
             tt-liquida-ima.cod-refer = tt-estoque.cod-refer NO-ERROR.
        IF NOT AVAIL tt-liquida-ima THEN DO.
           CREATE tt-liquida-ima.
           BUFFER-COPY tt-estoque TO tt-liquida-ima
              ASSIGN tt-liquida-ima.preco-item = 0
                     tt-liquida-ima.marca       = NO
                     tt-liquida-ima.acao        = 'I'. 
        END.
        ELSE 
           ASSIGN tt-liquida-ima.acao = ''. 

        DELETE tt-estoque.
    END.

    {&OPEN-QUERY-br-estoque}
    {&OPEN-QUERY-br-liquida}

    APPLY 'VALUE-CHANGED' TO br-estoque.
    APPLY 'VALUE-CHANGED' TO br-liquida.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-digita
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME frm-excel
&Scoped-define SELF-NAME bt-ajuda-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda-excel w-digita
ON CHOOSE OF bt-ajuda-excel IN FRAME frm-excel /* Ajuda */
DO:
    IF rs-opcao = 1 THEN
       MESSAGE ' Para Importar Dados, Utilize faáa uma Planilha Excel ' SKIP
               ' com o seguinte Layout...' SKIP(1)
               ' Item|Referància|Preáo' SKIP(1)
               ' Caso a Referància n∆o seja informada, ou seja est† BRANCO,' SKIP
               ' ser† considerado TODAS as Referàncias do Item ' SKIP
               ' com Quantidade em Estoque..'
           VIEW-AS ALERT-BOX INFO BUTTONS OK TITLE "Layout de para Importaá∆o dos Dados".
    ELSE
       MESSAGE 'Ser∆o gerados os Dados com o Layout' SKIP(1)
               ' Item|Descriá∆o|Referància|Un|Preáo|Qtde Atual|PreáoTAB|PreáoRUBI'
           VIEW-AS ALERT-BOX INFO BUTTONS OK TITLE 'Exportaá∆o dos Dados'.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-arquivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-arquivo w-digita
ON CHOOSE OF bt-arquivo IN FRAME frm-excel
DO:
   IF rs-opcao = 1 THEN
      SYSTEM-DIALOG GET-FILE c-arquivo
             FILTERS "*.xls" "*.xls",
                     "*.xlsx" "*.xlsx",
                     "*.*" "*.*"
             DEFAULT-EXTENSION "xls"
             INITIAL-DIR "c:\temp" 
             MUST-EXIST 
             USE-FILENAME
             UPDATE l-ok.
   ELSE
       SYSTEM-DIALOG GET-FILE c-arquivo
              FILTERS "*.xls" "*.xls",
                      "*.xlsx" "*.xlsx",
                      "*.*" "*.*"
              DEFAULT-EXTENSION "xls"
              INITIAL-DIR "c:\temp" 
              USE-FILENAME
              UPDATE l-ok.

   IF l-ok THEN
      ASSIGN fi-arquivo:SCREEN-VALUE = c-arquivo.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancela
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancela w-digita
ON CHOOSE OF bt-cancela IN FRAME frm-excel /* Cancela */
DO:
   HIDE FRAME frm-excel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME F-Main
&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-digita
ON CHOOSE OF bt-cancelar IN FRAME F-Main /* Sair */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-del
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-del w-digita
ON CHOOSE OF bt-del IN FRAME F-Main
DO:
   FOR EACH tt-liquida-ima WHERE
            tt-liquida-ima.marca = YES NO-LOCK.
       FIND tt-estoque WHERE
            tt-estoque.it-codigo = tt-liquida-ima.it-codigo AND 
            tt-estoque.cod-refer = tt-liquida-ima.cod-refer NO-ERROR.

       IF NOT AVAIL tt-estoque THEN DO.
          CREATE tt-estoque.
          BUFFER-COPY tt-liquida-ima TO tt-estoque
               ASSIGN tt-estoque.marca = NO.
       END.
       ASSIGN tt-liquida-ima.dt-final = TODAY
              tt-liquida-ima.acao     = 'D'.
   END.
   
   ASSIGN bt-ok:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
                                  
   {&OPEN-QUERY-br-estoque}
   {&OPEN-QUERY-br-liquida}

   APPLY 'VALUE-CHANGED' TO br-estoque.
   APPLY 'VALUE-CHANGED' TO br-liquida.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-desmarca-est
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-desmarca-est w-digita
ON CHOOSE OF bt-desmarca-est IN FRAME F-Main
DO:
    IF AVAIL tt-estoque THEN
       ASSIGN tt-estoque.marca = NO.

    br-estoque:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-estoque.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-desmarca-liq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-desmarca-liq w-digita
ON CHOOSE OF bt-desmarca-liq IN FRAME F-Main
DO:
    IF AVAIL tt-liquida-ima THEN
       ASSIGN tt-liquida-ima.marca = NO.

    br-liquida:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-liquida.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-fam
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-fam w-digita
ON CHOOSE OF bt-dig-fam IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Categoria").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-item w-digita
ON CHOOSE OF bt-dig-item IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Item").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-ref
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-ref w-digita
ON CHOOSE OF bt-dig-ref IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Referencia").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-fam
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-fam w-digita
ON CHOOSE OF bt-ex-fam IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                              INPUT "E",
                              INPUT "Categoria").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-item w-digita
ON CHOOSE OF bt-ex-item IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "E",
                            INPUT "Item").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-ref
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-ref w-digita
ON CHOOSE OF bt-ex-ref IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                              INPUT "E",
                              INPUT "Referencia").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel w-digita
ON CHOOSE OF bt-excel IN FRAME F-Main /* Button 2 */
DO:
   VIEW FRAME frm-excel.
   APPLY 'VALUE-CHANGED' TO rs-opcao.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME frm-excel
&Scoped-define SELF-NAME bt-importa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-importa w-digita
ON CHOOSE OF bt-importa IN FRAME frm-excel /* OK */
DO:
   ASSIGN INPUT FRAME frm-excel fi-arquivo.

   IF fi-arquivo = '' THEN DO.
      MESSAGE 'Favor Informar o Arquivo...'
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
      RETURN NO-APPLY.
   END.

   IF SEARCH(fi-arquivo) = ? THEN DO.
      MESSAGE 'Arquivo n∆o Encontrado, verifique...'
           VIEW-AS ALERT-BOX INFO BUTTONS OK.
      RETURN NO-APPLY.
   END.

   ASSIGN cFileName = fi-arquivo.

   CREATE "Excel.Application" chExcelApp.
   chExcelApp:VISIBLE = TRUE.

   IF rs-opcao = 2 THEN
      RUN pi-exporta-dados.
   ELSE 
      RUN pi-importa-planilha.

   HIDE FRAME frm-excel.

   APPLY 'ENTRY' TO br-estoque IN FRAME f-main.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME F-Main
&Scoped-define SELF-NAME bt-marca-est
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-marca-est w-digita
ON CHOOSE OF bt-marca-est IN FRAME F-Main
DO:
    IF AVAIL tt-estoque THEN
       ASSIGN tt-estoque.marca = YES.

    br-estoque:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-estoque.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-marca-liq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-marca-liq w-digita
ON CHOOSE OF bt-marca-liq IN FRAME F-Main
DO:
    IF AVAIL tt-liquida-ima THEN
       ASSIGN tt-liquida-ima.marca = YES.

    br-liquida:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-liquida.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-nenhum-est
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-nenhum-est w-digita
ON CHOOSE OF bt-nenhum-est IN FRAME F-Main
DO:
    FOR EACH b-tt-estoque.
        ASSIGN b-tt-estoque.marca = NO.
    END.
    br-estoque:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-estoque.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-nenhum-liq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-nenhum-liq w-digita
ON CHOOSE OF bt-nenhum-liq IN FRAME F-Main
DO:
    FOR EACH b-tt-liquida-ima.
        ASSIGN b-tt-liquida-ima.marca = NO.
    END.
    br-liquida:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-liquida.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-digita
ON CHOOSE OF bt-ok IN FRAME F-Main /* Efetivar Alteraá‰es */
DO:
  FIND FIRST tt-liquida-ima WHERE
             tt-liquida-ima.preco-item = 0 NO-LOCK NO-ERROR.
  IF AVAIL tt-liquida-ima THEN DO.
     MESSAGE 'Existem Itens na Tabela RUBI sem o Percentual de Desconto...' SKIP
             'Verifique...'
         VIEW-AS ALERT-BOX INFO BUTTONS OK.

     RETURN NO-APPLY.
  END.

  FOR EACH tt-liquida-ima WHERE
           tt-liquida-ima.acao <> '' NO-LOCK.

      FOR EACH liquida-ima WHERE
               liquida-ima.cod-estabel = tt-liquida-ima.cod-estabel AND
               liquida-ima.it-codigo   = tt-liquida-ima.it-codigo AND 
               liquida-ima.cod-refer   = tt-liquida-ima.cod-refer AND
               liquida-ima.tipo-tab    = 2 AND // Rubi
               liquida-ima.dt-final    = ? SHARE-LOCK.
          ASSIGN liquida-ima.dt-final  = TODAY.
      END.

      CASE tt-liquida-ima.acao.
          WHEN 'I' THEN DO.
             RUN esapi/calcula-id.p (OUTPUT c-num-id).

             CREATE liquida-ima.
             ASSIGN liquida-ima.tipo-tab      = 2  // Rubi
                    liquida-ima.cod-estabel   = tt-liquida-ima.cod-estabel
                    liquida-ima.it-codigo     = tt-liquida-ima.it-codigo
                    liquida-ima.cod-refer     = tt-liquida-ima.cod-refer
                    liquida-ima.preco-item    = tt-liquida-ima.preco-item
                    liquida-ima.usuario       = c-seg-usuario 
                    liquida-ima.dt-inicio     = TODAY + 1
                    liquida-ima.num-id-liquida-ima = c-num-id.
          END.
          WHEN 'D' THEN DO.
              FIND liquida-ima WHERE
                   liquida-ima.cod-estabel = tt-liquida-ima.cod-estabel AND
                   liquida-ima.it-codigo   = tt-liquida-ima.it-codigo AND
                   liquida-ima.cod-refer   = tt-liquida-ima.cod-refer AND
                   liquida-ima.tipo-tab    = 2 AND // Rubi
                   liquida-ima.dt-final    = ? 
                   SHARE-LOCK NO-ERROR.
              IF AVAIL liquida-ima THEN
                 ASSIGN liquida-ima.dt-final  = TODAY.
          END.
          WHEN 'A' THEN DO.
              // Finaliza a Atual
              FIND liquida-ima WHERE
                   liquida-ima.cod-estabel = tt-liquida-ima.cod-estabel AND
                   liquida-ima.it-codigo   = tt-liquida-ima.it-codigo AND
                   liquida-ima.cod-refer   = tt-liquida-ima.cod-refer AND
                   liquida-ima.tipo-tab    = 2 AND // Rubi
                   liquida-ima.dt-final    = ? 
                   SHARE-LOCK NO-ERROR.
              IF AVAIL liquida-ima THEN
                 ASSIGN liquida-ima.dt-final  = TODAY.

              // Cria Novo Registro com o novo percentual
              RUN esapi/calcula-id.p (OUTPUT c-num-id).

              CREATE liquida-ima.
              ASSIGN liquida-ima.tipo-tab      = 2  // Rubi
                     liquida-ima.cod-estabel   = tt-liquida-ima.cod-estabel
                     liquida-ima.it-codigo     = tt-liquida-ima.it-codigo
                     liquida-ima.cod-refer     = tt-liquida-ima.cod-refer
                     liquida-ima.preco-item    = tt-liquida-ima.preco-item
                     liquida-ima.usuario       = c-seg-usuario 
                     liquida-ima.dt-inicio     = TODAY + 1
                     liquida-ima.num-id-liquida-ima = c-num-id.
          END.
      END.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-processa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-processa w-digita
ON CHOOSE OF bt-processa IN FRAME F-Main /* Processa */
DO:
    RUN pi-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-todos-est
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-todos-est w-digita
ON CHOOSE OF bt-todos-est IN FRAME F-Main
DO:
    FOR EACH b-tt-estoque NO-LOCK.
        ASSIGN b-tt-estoque.marca = YES.
    END.
    br-estoque:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-estoque.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-todos-liq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-todos-liq w-digita
ON CHOOSE OF bt-todos-liq IN FRAME F-Main
DO:
    FOR EACH b-tt-liquida-ima NO-LOCK.
        ASSIGN b-tt-liquida-ima.marca = YES.
    END.
    br-liquida:REFRESH().

    APPLY 'VALUE-CHANGED' TO br-liquida.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-refer-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer-fin w-digita
ON LEAVE OF fi-cod-refer-fin IN FRAME F-Main
DO:
    APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-refer-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer-ini w-digita
ON LEAVE OF fi-cod-refer-ini IN FRAME F-Main /* Referància */
DO:
    ASSIGN fi-cod-refer-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZ'.
    IF SELF:SCREEN-VALUE <> '' THEN
      ASSIGN fi-cod-refer-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.

   APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer-ini w-digita
ON MOUSE-SELECT-DBLCLICK OF fi-cod-refer-ini IN FRAME F-Main /* Referància */
DO:
  {include/zoomvar.i &prog-zoom = inzoom/z02in377.w
                     &campo     = fi-cod-refer-ini
                     &campozoom = cod-refer}

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-fm-codigo-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-fm-codigo-fin w-digita
ON LEAVE OF fi-fm-codigo-fin IN FRAME F-Main
DO:
    APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-fm-codigo-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-fm-codigo-ini w-digita
ON LEAVE OF fi-fm-codigo-ini IN FRAME F-Main /* Categoria */
DO:
  ASSIGN fi-fm-codigo-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZ'.
  IF SELF:SCREEN-VALUE <> '' THEN
     ASSIGN fi-fm-codigo-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.

  APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-fm-codigo-ini w-digita
ON MOUSE-SELECT-DBLCLICK OF fi-fm-codigo-ini IN FRAME F-Main /* Categoria */
DO:
  {include/zoomvar.i &prog-zoom = dizoom/z01di050.w
                     &campo     = fi-fm-codigo-ini
                     &campozoom = fm-cod-com}

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-it-codigo-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo-fin w-digita
ON LEAVE OF fi-it-codigo-fin IN FRAME F-Main
DO:
    APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-it-codigo-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo-ini w-digita
ON LEAVE OF fi-it-codigo-ini IN FRAME F-Main /* Item */
DO:
  ASSIGN fi-it-codigo-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZ'.
  IF SELF:SCREEN-VALUE <> '' THEN
     ASSIGN fi-it-codigo-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.

  APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo-ini w-digita
ON MOUSE-SELECT-DBLCLICK OF fi-it-codigo-ini IN FRAME F-Main /* Item */
DO:
  {include/zoomvar.i &prog-zoom = inzoom/z02in172.w
                     &campo     = fi-it-codigo-ini
                     &campozoom = it-codigo}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-preco-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-item w-digita
ON LEAVE OF fi-preco-item IN FRAME F-Main
DO:
   ASSIGN INPUT FRAME {&FRAME-NAME} fi-preco-item.

   FOR EACH tt-liquida-ima WHERE
            tt-liquida-ima.marca = YES NO-LOCK.
       ASSIGN tt-liquida-ima.preco-item = fi-preco-item
              tt-liquida-ima.marca = NO.

       IF tt-liquida-ima.acao = '' THEN
          ASSIGN tt-liquida-ima.acao = 'A'.
   END.
   br-liquida:REFRESH().
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME frm-excel
&Scoped-define SELF-NAME rs-opcao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-opcao w-digita
ON VALUE-CHANGED OF rs-opcao IN FRAME frm-excel
DO:
    ASSIGN INPUT FRAME frm-excel rs-opcao.

   IF rs-opcao = 1 THEN
      ASSIGN text-entrada:SCREEN-VALUE = 'Arquivo de Entrada'.
   ELSE
      ASSIGN text-entrada:SCREEN-VALUE = 'Arquivo de Sa°da'.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME F-Main
&Scoped-define SELF-NAME tg-rd
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-rd w-digita
ON VALUE-CHANGED OF tg-rd IN FRAME F-Main /* 2¶ Qualidade */
DO:
  APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-rp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-rp w-digita
ON VALUE-CHANGED OF tg-rp IN FRAME F-Main /* 1¶ Qualidade */
DO:
   APPLY 'CHOOSE' TO bt-processa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-estoque
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-digita 


/* ***************************  Main Block  *************************** */
fi-it-codigo-ini:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-it-codigo-fin:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-cod-refer-ini:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-cod-refer-fin:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-fm-codigo-ini:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-fm-codigo-fin:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-digita  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE adm-current-page  AS INTEGER NO-UNDO.

  RUN get-attribute IN THIS-PROCEDURE ('Current-Page':U).
  ASSIGN adm-current-page = INTEGER(RETURN-VALUE).

  /* Select a Startup page. */
  IF adm-current-page eq 0 
  THEN RUN select-page IN THIS-PROCEDURE ( 1 ).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-digita  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-digita  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-digita)
  THEN DELETE WIDGET w-digita.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-digita  _DEFAULT-ENABLE
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
  DISPLAY fi-it-codigo-ini fi-it-codigo-fin tg-rp fi-cod-refer-ini 
          fi-cod-refer-fin tg-rd fi-fm-codigo-ini fi-fm-codigo-fin 
          fi-desc-it-est fi-desc-it-liq fi-preco-item fi-dt-inicio 
      WITH FRAME F-Main IN WINDOW w-digita.
  ENABLE RECT-1 IMAGE-2 IMAGE-73 RECT-57 IMAGE-106 IMAGE-107 IMAGE-108 
         IMAGE-109 RECT-58 RECT-60 bt-processa fi-it-codigo-ini 
         fi-it-codigo-fin bt-dig-item bt-ex-item tg-rp fi-cod-refer-ini 
         fi-cod-refer-fin bt-dig-ref bt-ex-ref tg-rd fi-fm-codigo-ini 
         fi-fm-codigo-fin bt-dig-fam bt-ex-fam br-estoque br-liquida bt-excel 
         fi-preco-item fi-dt-inicio bt-ajuda bt-ok bt-cancelar 
      WITH FRAME F-Main IN WINDOW w-digita.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  DISPLAY rs-opcao fi-arquivo 
      WITH FRAME frm-excel IN WINDOW w-digita.
  ENABLE RECT-61 RECT-62 rs-opcao bt-arquivo fi-arquivo bt-importa bt-cancela 
         bt-ajuda-excel 
      WITH FRAME frm-excel IN WINDOW w-digita.
  {&OPEN-BROWSERS-IN-QUERY-frm-excel}
  VIEW w-digita.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-digita 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-digita 
PROCEDURE local-exit :
/* -----------------------------------------------------------
  Purpose:  Starts an "exit" by APPLYing CLOSE event, which starts "destroy".
  Parameters:  <none>
  Notes:    If activated, should APPLY CLOSE, *not* dispatch adm-exit.   
-------------------------------------------------------------*/
   APPLY "CLOSE":U TO THIS-PROCEDURE.
   
   RETURN.
       
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-digita 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  {utp/ut9000.i "ESCE001" "2.04.00.001"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  HIDE FRAME frm-excel.
  FIND LAST para-ped NO-LOCK NO-ERROR.

  RUN pi-processa.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-exporta-dados w-digita 
PROCEDURE pi-exporta-dados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    /*
    DEF VAR c-esp-movto AS CHAR.
    DEF VAR i-total-peso AS DEC.
    DEF VAR d-dt-ini AS DATE.
    DEF VAR d-dt-fim AS DATE.
    DEF VAR c-container AS CHAR.
    DEF VAR                 chExcelApp     AS COM-HANDLE   NO-UNDO.
    DEF VAR                 chWorkSheet     AS COM-HANDLE   NO-UNDO.  
    DEF VAR                 chWorkbook      AS COM-HANDLE   NO-UNDO.
    DEFINE VARIABLE i-lin AS INTEGER    NO-UNDO.
    */
    
    
    /*** Cria a Inst≥ncia do Excel ***/
    ASSIGN i-lin = 1.
    
    ASSIGN chExcelApp:VISIBLE                   = TRUE /* FALSE = Nío Mostra - TRUE = Mostra Excel */
           chExcelApp:displayalerts             = FALSE /* FALSE = Nío Mostra Mensagens de Alerta   */
           chWorkbook                           = chExcelApp:workbooks:ADD()
           chWorkSheet                          = chWorkbook:worksheets:ITEM(1).

    ASSIGN chWorkSheet:cells(1,1):VALUE = "Item".
    ASSIGN chWorkSheet:cells(1,2):VALUE = "Descriá∆o".
    ASSIGN chWorkSheet:cells(1,3):VALUE = "Refer".
    ASSIGN chWorkSheet:cells(1,4):VALUE = "Un".
    ASSIGN chWorkSheet:cells(1,5):VALUE = "Saldo Estoque".
    ASSIGN chWorkSheet:cells(1,6):VALUE = "Preco TAB".
    ASSIGN chWorkSheet:cells(1,6):VALUE = "Preco RUBI".
    ASSIGN chWorkSheet:cells(1,6):VALUE = "Data Inicio".

    FOR EACH tt-liquida-ima NO-LOCK
          BY tt-liquida-ima.it-codigo 
          BY tt-liquida-ima.cod-refer.
    
        FIND item WHERE   
             item.it-codigo = tt-liquida-ima.it-codigo NO-LOCK NO-ERROR.

        ASSIGN i-lin = i-lin + 1.
        ASSIGN chWorkSheet:cells(i-lin,1):VALUE = tt-liquida-ima.it-codigo
               chWorkSheet:cells(i-lin,2):VALUE = tt-liquida-ima.desc-item
               chWorkSheet:cells(i-lin,3):VALUE = tt-liquida-ima.cod-refer
               chWorkSheet:cells(i-lin,4):VALUE = tt-liquida-ima.un
               chWorkSheet:cells(i-lin,5):VALUE = tt-liquida-ima.qtidade-atu
               chWorkSheet:cells(i-lin,6):VALUE = tt-liquida-ima.preco-tab
               chWorkSheet:cells(i-lin,7):VALUE = tt-liquida-ima.preco-item 
               chWorkSheet:cells(i-lin,8):VALUE = tt-liquida-ima.dt-inicio.  
    END.
    ASSIGN chExcelApp:VISIBLE                     = TRUE /* FALSE = Nío Mostra - TRUE = Mostra Excel*/ .
    chWorkbook:Saveas (cFileName, 1,'','',FALSE,FALSE,FALSE). /* Salvar o arquivo no format XLS */
    RELEASE OBJECT chWorkSheet NO-ERROR.
    RELEASE OBJECT chExcelApp NO-ERROR.
    RELEASE OBJECT chWorkbook  NO-ERROR.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-importa-planilha w-digita 
PROCEDURE pi-importa-planilha :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    /* Abre a Planilha */
    chExcelApp:VISIBLE = FALSE.  /* A Planilha Ficar† Visivel */
    chWorkbook         = chExcelApp:Workbooks:OPEN(cFileName).
    chWorkSheet        = chExcelApp:Sheets:Item(1).
    
    /* Salva e Imprime e Fecha a Planilha */
    
    ASSIGN i-lin = 1.
    REPEAT.
       ASSIGN c-item = ENTRY(1,chWorksheet:range("A" + STRING(i-lin)):VALUE)
              c-refer = ENTRY(1,chWorksheet:range("B" + STRING(i-lin)):VALUE).
    
       IF c-item = '' OR c-item = ? THEN LEAVE.

       FIND item WHERE
            item.it-codigo = c-item NO-LOCK NO-ERROR.
       IF AVAIL item THEN DO.
          CREATE tt-aux.
          ASSIGN tt-aux.it-codigo  = c-item
                 tt-aux.cod-refer  = c-refer
                 tt-aux.preco-item = chWorksheet:range("C" + STRING(i-lin)):VALUE.
       END.
       ASSIGN i-lin = i-lin + 1.
    END.
    
    /*chWorkBook:SaveAs(cFileName,,,,,,,).*/
    chWorkBook:CLOSE().
    chExcelApp:QUIT().
    
    RELEASE OBJECT chExcelApp. 
    RELEASE OBJECT chworkBook.
    RELEASE OBJECT chworksheet.
    
    FOR EACH tt-aux.
        IF tt-aux.it-codigo = '' OR 
           tt-aux.it-codigo = ? THEN NEXT.
    
        IF tt-aux.cod-refer = ? THEN
           ASSIGN tt-aux.cod-refer = ''.

        FIND item WHERE
             item.it-codigo = tt-aux.it-codigo NO-LOCK NO-ERROR.
        IF NOT AVAIL item THEN NEXT.

        IF tt-aux.cod-refer <> '' THEN DO.
           FIND tt-liquida-ima WHERE
                tt-liquida-ima.cod-estab = para-ped.estab-padr AND
                tt-liquida-ima.it-codigo = tt-aux.it-codigo AND
                tt-liquida-ima.cod-refer = tt-aux.cod-refer NO-ERROR.
           IF NOT AVAIL tt-liquida-ima THEN DO.
              CREATE tt-liquida-ima.
              ASSIGN tt-liquida-ima.it-codigo = tt-aux.it-codigo
                     tt-liquida-ima.cod-refer = tt-aux.cod-refer
                     tt-liquida-ima.acao = 'I'. 
           END.
           ELSE 
              ASSIGN tt-liquida-ima.acao = 'A'. 
    
           ASSIGN tt-liquida-ima.preco-item = tt-aux.preco-item
                  tt-liquida-ima.marca = NO.
    
           FIND tt-estoque WHERE
                tt-estoque.it-codigo = tt-aux.it-codigo AND 
                tt-estoque.cod-refer = tt-aux.cod-refer NO-ERROR.
           IF AVAIL tt-estoque THEN
              DELETE tt-estoque.
        END.
        ELSE DO.
           FOR EACH saldo-estoq WHERE
                    saldo-estoq.cod-estabel = para-ped.estab-padr AND
                    saldo-estoq.it-codigo = tt-aux.it-codigo NO-LOCK.
               FIND tt-liquida-ima WHERE
                    tt-liquida-ima.cod-estab = para-ped.estab-padr AND
                    tt-liquida-ima.it-codigo = saldo-estoq.it-codigo AND
                    tt-liquida-ima.cod-refer = saldo-estoq.cod-refer NO-ERROR.
               IF NOT AVAIL tt-liquida-ima THEN DO.
                  CREATE tt-liquida-ima.
                  ASSIGN tt-liquida-ima.it-codigo = saldo-estoq.it-codigo
                         tt-liquida-ima.cod-refer = saldo-estoq.cod-refer
                         tt-liquida-ima.acao = 'I'. 
               END.
               ELSE 
                  ASSIGN tt-liquida-ima.acao = 'A'. 

               ASSIGN tt-liquida-ima.preco-item = tt-aux.preco-item
                      tt-liquida-ima.marca = NO.

               FIND tt-estoque WHERE
                    tt-estoque.it-codigo = saldo-estoq.it-codigo AND 
                    tt-estoque.cod-refer = saldo-estoq.cod-refer NO-ERROR.
               IF AVAIL tt-estoque THEN
                  DELETE tt-estoque.
           END.
        END.
    END.

    {&OPEN-QUERY-br-estoque}
    {&OPEN-QUERY-br-liquida}

    APPLY 'VALUE-CHANGED' TO br-estoque IN FRAME {&FRAME-NAME}.
    APPLY 'VALUE-CHANGED' TO br-liquida IN FRAME {&FRAME-NAME}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-processa w-digita 
PROCEDURE pi-processa :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    EMPTY TEMP-TABLE tt-estoque.
    EMPTY TEMP-TABLE tt-liquida-ima.

    ASSIGN INPUT FRAME {&FRAME-NAME} fi-it-codigo-ini 
                                     fi-it-codigo-fin
                                     fi-cod-refer-ini 
                                     fi-cod-refer-fin
                                     fi-fm-codigo-ini 
                                     fi-fm-codigo-fin
                                     tg-rp
                                     tg-rd.

    RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
    {utp/ut-liter.i Selecionando_Estoque *}
    RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

    FOR EACH item WHERE
             item.it-codigo >= fi-it-codigo-ini AND
             item.it-codigo <= fi-it-codigo-fin AND
             item.fm-cod-com >= fi-fm-codigo-ini AND
             item.fm-cod-com <= fi-fm-codigo-fin AND
             item.ge-codigo >= 50 AND
             item.ge-codigo <= 60 NO-LOCK.

        RUN pi-acompanhar IN  h-acomp (INPUT "Item: " + item.it-codigo).

        RUN pi-ver-digita (INPUT "Item",
                           INPUT item.it-codigo).
        IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

        RUN pi-ver-digita (INPUT "Categoria",
                           INPUT item.fm-cod-com).
        IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

        FOR EACH saldo-estoq WHERE
                 saldo-estoq.cod-estabel = para-ped.estab-padr AND
                 saldo-estoq.it-codigo = item.it-codigo AND
                 saldo-estoq.cod-refer >= fi-cod-refer-ini AND
                 saldo-estoq.cod-refer <= fi-cod-refer-fin AND
                 saldo-estoq.qtidade-atu > 0 NO-LOCK.
    
            IF saldo-estoq.lote <> saldo-estoq.cod-refer THEN NEXT.

            IF NOT tg-rp AND saldo-estoq.cod-refer <> '888' THEN NEXT.
            IF NOT tg-rd AND saldo-estoq.cod-refer  = '888' THEN NEXT.

            RUN pi-ver-digita (INPUT "Referància",
                               INPUT saldo-estoq.cod-refer).
            IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

            
            FOR LAST pp-it-container WHERE
                     pp-it-container.it-codigo = saldo-estoq.it-codigo AND
                     pp-it-container.cod-refer = saldo-estoq.cod-refer NO-LOCK,
                FIRST pp-container OF pp-it-container NO-LOCK 
                   BY pp-container.dt-receb.
            END.

            FIND FIRST liquida-ima WHERE
                       liquida-ima.cod-estabel = saldo-estoq.cod-estabel AND
                       liquida-ima.it-codigo   = saldo-estoq.it-codigo AND
                       liquida-ima.cod-refer   = saldo-estoq.cod-refer AND
                       liquida-ima.tipo-tab    = 2 AND // Rubi
                       liquida-ima.dt-final    = ? NO-LOCK NO-ERROR.
            IF AVAIL liquida-ima THEN DO.
               CREATE tt-liquida-ima.
               ASSIGN tt-liquida-ima.cod-estabel   = saldo-estoq.cod-estabel
                      tt-liquida-ima.it-codigo     = saldo-estoq.it-codigo
                      tt-liquida-ima.desc-item     = item.desc-item
                      tt-liquida-ima.cod-refer     = saldo-estoq.cod-refer
                      tt-liquida-ima.fm-cod-com    = item.fm-cod-com
                      tt-liquida-ima.un            = item.un
                      tt-liquida-ima.qtidade-atu   = saldo-estoq.qtidade-atu
                      tt-liquida-ima.preco-tab     = liquida-ima.preco-tab
                      tt-liquida-ima.preco-item    = liquida-ima.preco-item
                      tt-liquida-ima.dt-inicio     = liquida-ima.dt-inicio.
               IF AVAIL pp-container THEN
                  ASSIGN tt-liquida-ima.dt-ult-compra = pp-container.dt-receb.
            END.
            ELSE DO.
               CREATE tt-estoque.
               ASSIGN tt-estoque.cod-estabel   = saldo-estoq.cod-estabel
                      tt-estoque.it-codigo     = saldo-estoq.it-codigo
                      tt-estoque.desc-item     = item.desc-item
                      tt-estoque.cod-refer     = saldo-estoq.cod-refer
                      tt-estoque.fm-cod-com    = item.fm-cod-com
                      tt-estoque.un            = item.un
                      tt-estoque.qtidade-atu   = saldo-estoq.qtidade-atu.
               IF AVAIL pp-container THEN
                  ASSIGN tt-estoque.dt-ult-compra = pp-container.dt-receb.
            END.
        END.
    END.
    RUN pi-finalizar in h-acomp.

    {&OPEN-QUERY-br-estoque}
    {&OPEN-QUERY-br-liquida}    

    APPLY 'VALUE-CHANGED' TO br-estoque IN FRAME {&FRAME-NAME}.
    APPLY 'VALUE-CHANGED' TO br-liquida IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-ver-digita w-digita 
PROCEDURE pi-ver-digita :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER p-campo AS CHAR.
    DEF INPUT PARAMETER p-valor AS CHAR.

    IF CAN-FIND(FIRST tt-digita WHERE
                      tt-digita.opcao = 'D' AND
                      tt-digita.campo = p-campo) AND
       NOT CAN-FIND(FIRST tt-digita WHERE
                          tt-digita.opcao = 'D' AND
                          tt-digita.campo = p-campo AND
                          tt-digita.valor = p-valor) THEN RETURN 'ADM-ERROR'.
    ELSE
      IF CAN-FIND(FIRST tt-digita WHERE
                        tt-digita.opcao = 'E' AND
                        tt-digita.campo = p-campo AND
                        tt-digita.valor = p-valor) THEN RETURN 'ADM-ERROR'.
      ELSE
         RETURN 'OK'.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-digita  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-liquida-ima"}
  {src/adm/template/snd-list.i "tt-estoque"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-digita 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

