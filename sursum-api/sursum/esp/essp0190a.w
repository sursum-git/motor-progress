&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-window 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i XX9999 9.99.99.999}

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

/* Local Variable Definitions --- */  
DEF INPUT-OUTPUT PARAMETER TABLE FOR tt-digita.
DEFINE INPUT-OUTPUT PARAMETER i-tp-selecao        AS INT.
DEFINE INPUT-OUTPUT PARAMETER c-dt-faturar        AS CHAR.                                  
DEFINE INPUT-OUTPUT PARAMETER c-dt-faturadas-ini  AS DATE.
DEFINE INPUT-OUTPUT PARAMETER c-dt-faturadas-fin  AS DATE.
DEFINE INPUT-OUTPUT PARAMETER c-dt-vendido-ini    AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER c-dt-vendido-fin    AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER c-cod-estabel-ini   LIKE estabelec.cod-estabel.
DEFINE INPUT-OUTPUT PARAMETER c-cod-estabel-fin   LIKE estabelec.cod-estabel.
DEFINE INPUT-OUTPUT PARAMETER c-nr-pedcli-ini     LIKE ped-venda.nr-pedcli.
DEFINE INPUT-OUTPUT PARAMETER c-nr-pedcli-fin     LIKE ped-venda.nr-pedcli.
DEFINE INPUT-OUTPUT PARAMETER c-it-codigo-ini     LIKE ped-item.it-codigo.
DEFINE INPUT-OUTPUT PARAMETER c-it-codigo-fin     LIKE ped-item.it-codigo.
DEFINE INPUT-OUTPUT PARAMETER c-cod-refer-ini     LIKE ped-item.cod-refer.                              
DEFINE INPUT-OUTPUT PARAMETER c-cod-refer-fin     LIKE ped-item.cod-refer.
DEFINE INPUT-OUTPUT PARAMETER c-nome-abrev-ini    LIKE ped-venda.nome-abrev. 
DEFINE INPUT-OUTPUT PARAMETER c-nome-abrev-fin    LIKE ped-venda.nome-abrev.
DEFINE INPUT-OUTPUT PARAMETER c-no-ab-reppri-ini  LIKE ped-venda.no-ab-reppri. 
DEFINE INPUT-OUTPUT PARAMETER c-no-ab-reppri-fin  LIKE ped-venda.no-ab-reppri.
DEFINE INPUT-OUTPUT PARAMETER c-fm-cod-com-ini  AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER c-fm-cod-com-fin  AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER i-ge-codigo-ini     LIKE grup-estoque.ge-codigo.
DEFINE INPUT-OUTPUT PARAMETER i-ge-codigo-fin     LIKE grup-estoque.ge-codigo.
DEFINE INPUT-OUTPUT PARAMETER c-matriz-ini        LIKE emitente.nome-matriz.
DEFINE INPUT-OUTPUT PARAMETER c-matriz-fin        LIKE emitente.nome-matriz.
DEFINE INPUT-OUTPUT PARAMETER c-tp-pedido         AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER i-tb_preco_id       AS INT.
DEFINE INPUT-OUTPUT PARAMETER l-lote-rp           AS LOG.
DEFINE INPUT-OUTPUT PARAMETER l-lote-rd           AS LOG.
DEFINE INPUT-OUTPUT PARAMETER i-outlet            AS INTEGER.
DEFINE INPUT-OUTPUT PARAMETER c-tipo-acabamento   AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER c-tipo-mercado      AS CHAR.
DEFINE INPUT-OUTPUT PARAMETER l-gera-duplicata    AS LOG.
DEFINE INPUT-OUTPUT PARAMETER l-nao-gera-dupl     AS LOG.
DEFINE INPUT-OUTPUT PARAMETER l-outros-fat        AS LOG.
DEFINE INPUT-OUTPUT PARAMETER l-pilotagem         AS LOG.
DEFINE INPUT-OUTPUT PARAMETER l-ok                AS LOG.

DEF NEW GLOBAL SHARED VAR c-seg-usuario AS CHAR NO-UNDO.

DEF VAR c-lst-tab AS CHAR.
DEF VAR base AS CHAR.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE JanelaDetalhe
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS tg-piloto rs-outlet cb-tb-preco rs-estab ~
rs-selecao fi-dt-faturar fi-dt-faturadas-ini fi-dt-faturadas-fin ~
fi-dt-vendido-ini fi-dt-vendido-fin fi-nr-pedcli-ini fi-nr-pedcli-fin ~
fi-it-codigo-ini fi-it-codigo-fin fi-cod-refer-ini fi-cod-refer-fin ~
fi-nome-abrev-ini fi-nome-abrev-fin fi-no-ab-reppri-ini fi-no-ab-reppri-fin ~
fi-ge-codigo-ini fi-ge-codigo-fin fi-matriz-ini fi-matriz-fin cb-tp-pedido ~
tg-lote-rp tg-lote-rd rs-opc-acab rs-tipo-mercado tg-gera-dupl ~
tg-nao-gera-dupl tg-outros-fat bt-dig-ped bt-ex-ped bt-dig-item bt-ex-item ~
bt-dig-ref bt-ex-ref bt-dig-cli bt-ex-cli bt-dig-rep bt-ex-rep bt-ok ~
bt-cancelar bt-ajuda bt-dig-ge bt-ex-ge bt-dig-matriz bt-ex-matriz ~
fi-fm-cod-com-ini fi-fm-cod-com-fin bt-dig-fam bt-ex-fam IMAGE-102 ~
IMAGE-103 IMAGE-104 IMAGE-105 IMAGE-3 IMAGE-4 IMAGE-5 IMAGE-6 IMAGE-77 ~
IMAGE-78 IMAGE-83 IMAGE-87 IMAGE-90 IMAGE-91 IMAGE-94 IMAGE-95 IMAGE-96 ~
IMAGE-97 IMAGE-98 IMAGE-99 RECT-1 RECT-51 RECT-52 RECT-56 RECT-58 RECT-59 ~
RECT-60 
&Scoped-Define DISPLAYED-OBJECTS tg-piloto rs-outlet cb-tb-preco rs-estab ~
rs-selecao fi-dt-faturar fi-dt-faturadas-ini fi-dt-faturadas-fin ~
fi-dt-vendido-ini fi-dt-vendido-fin fi-nr-pedcli-ini fi-nr-pedcli-fin ~
fi-it-codigo-ini fi-it-codigo-fin fi-cod-refer-ini fi-cod-refer-fin ~
fi-nome-abrev-ini fi-nome-abrev-fin fi-no-ab-reppri-ini fi-no-ab-reppri-fin ~
fi-ge-codigo-ini fi-ge-codigo-fin fi-matriz-ini fi-matriz-fin cb-tp-pedido ~
tg-lote-rp tg-lote-rd rs-opc-acab rs-tipo-mercado tg-gera-dupl ~
tg-nao-gera-dupl tg-outros-fat fi-fm-cod-com-ini fi-fm-cod-com-fin 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-1 fi-fm-cod-com-ini fi-fm-cod-com-fin 
&Scoped-define List-5 cb-tp-pedido 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-window AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-dig-cli 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Cliente".

DEFINE BUTTON bt-dig-fam 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Itens".

DEFINE BUTTON bt-dig-ge 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita C¢digo Obsoleto".

DEFINE BUTTON bt-dig-item 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Itens".

DEFINE BUTTON bt-dig-matriz 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita C¢digo Obsoleto".

DEFINE BUTTON bt-dig-ped 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Pedidos".

DEFINE BUTTON bt-dig-ref 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Referàncias".

DEFINE BUTTON bt-dig-rep 
     IMAGE-UP FILE "image/im-ran.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-ran.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Digita Representante".

DEFINE BUTTON bt-ex-cli 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Cliente".

DEFINE BUTTON bt-ex-fam 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Itens".

DEFINE BUTTON bt-ex-ge 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto C¢digo Obsoleto".

DEFINE BUTTON bt-ex-item 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Itens".

DEFINE BUTTON bt-ex-matriz 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto C¢digo Obsoleto".

DEFINE BUTTON bt-ex-ped 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Pedidos".

DEFINE BUTTON bt-ex-ref 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Referàncias".

DEFINE BUTTON bt-ex-rep 
     IMAGE-UP FILE "image/imt-retira.bmp":U
     IMAGE-INSENSITIVE FILE "image/iit-retira.bmp":U
     LABEL "" 
     SIZE 4 BY 1 TOOLTIP "Exceto Representante".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "OK" 
     SIZE 10 BY 1.

DEFINE VARIABLE cb-tb-preco AS INTEGER FORMAT "9":U INITIAL 0 
     LABEL "Analise por Tabela" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Todas",9
     DROP-DOWN-LIST
     SIZE 23 BY 1 NO-UNDO.

DEFINE VARIABLE cb-tp-pedido AS CHARACTER FORMAT "X(256)":U INITIAL "Todos" 
     LABEL "Tipo de Pedido" 
     VIEW-AS COMBO-BOX INNER-LINES 10
     LIST-ITEMS "Todos","Normal","Reserva","Amostra","∑ Vista","Operaá∆o Triangular","Exportaá∆o","Bonificaá∆o","Doaá∆o","Bancado","Refaturamento","Amostra Exportaá∆o","Rem.Industrializaá∆o" 
     DROP-DOWN-LIST
     SIZE 23 BY 1 NO-UNDO.

DEFINE VARIABLE fi-cod-refer-fin AS CHARACTER FORMAT "x(16)" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Referància final." NO-UNDO.

DEFINE VARIABLE fi-cod-refer-ini AS CHARACTER FORMAT "x(16)" 
     LABEL "Referància" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Referància inicial." NO-UNDO.

DEFINE VARIABLE fi-dt-faturadas-fin AS DATE FORMAT "99/99/9999":U 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-faturadas-ini AS DATE FORMAT "99/99/9999":U 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-faturar AS CHARACTER FORMAT "99/9999":U 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-vendido-fin AS CHARACTER FORMAT "99/9999":U 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-vendido-ini AS CHARACTER FORMAT "99/9999":U 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-fm-cod-com-fin AS CHARACTER FORMAT "X(12)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE VARIABLE fi-fm-cod-com-ini AS CHARACTER FORMAT "X(12)":U 
     LABEL "Categoria" 
     VIEW-AS FILL-IN 
     SIZE 5.14 BY .88 NO-UNDO.

DEFINE VARIABLE fi-ge-codigo-fin AS INTEGER FORMAT ">9" INITIAL 99 
     VIEW-AS FILL-IN 
     SIZE 3 BY .88 TOOLTIP "Grupo de estoque final" NO-UNDO.

DEFINE VARIABLE fi-ge-codigo-ini AS INTEGER FORMAT ">9" INITIAL 0 
     LABEL "Grupo Estoque":R16 
     VIEW-AS FILL-IN 
     SIZE 3 BY .88 TOOLTIP "Grupo de estoque inicial" NO-UNDO.

DEFINE VARIABLE fi-it-codigo-fin AS CHARACTER FORMAT "x(16)" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Item final." NO-UNDO.

DEFINE VARIABLE fi-it-codigo-ini AS CHARACTER FORMAT "x(16)" 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Item inicial." NO-UNDO.

DEFINE VARIABLE fi-matriz-fin AS CHARACTER FORMAT "x(12)" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Cliente final." NO-UNDO.

DEFINE VARIABLE fi-matriz-ini AS CHARACTER FORMAT "x(12)" 
     LABEL "Matriz":R9 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Cliente inicial." NO-UNDO.

DEFINE VARIABLE fi-no-ab-reppri-fin AS CHARACTER FORMAT "x(16)" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Representante final." NO-UNDO.

DEFINE VARIABLE fi-no-ab-reppri-ini AS CHARACTER FORMAT "x(16)" 
     LABEL "Representante" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Representante inicial." NO-UNDO.

DEFINE VARIABLE fi-nome-abrev-fin AS CHARACTER FORMAT "x(12)" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Cliente final." NO-UNDO.

DEFINE VARIABLE fi-nome-abrev-ini AS CHARACTER FORMAT "x(12)" 
     LABEL "Cliente":R9 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 TOOLTIP "Cliente inicial." NO-UNDO.

DEFINE VARIABLE fi-nr-pedcli-fin AS CHARACTER FORMAT "x(12)" 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88 TOOLTIP "Pedido final." NO-UNDO.

DEFINE VARIABLE fi-nr-pedcli-ini AS CHARACTER FORMAT "x(12)" 
     LABEL "Pedido":R17 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88 TOOLTIP "Pedido inicial." NO-UNDO.

DEFINE IMAGE im-ima
     FILENAME "image/ico/ima3.ico":U
     SIZE 6 BY 1.75.

DEFINE IMAGE im-med
     FILENAME "image/ico/med3.ico":U
     SIZE 5.29 BY 1.67.

DEFINE IMAGE IMAGE-102
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-103
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-104
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-105
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-3
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-4
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-5
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-6
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-77
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-78
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-83
     FILENAME "image\im-las":U
     SIZE 3 BY .79.

DEFINE IMAGE IMAGE-87
     FILENAME "image\im-las":U
     SIZE 3 BY .79.

DEFINE IMAGE IMAGE-90
     FILENAME "image\im-fir":U
     SIZE 3 BY 1.

DEFINE IMAGE IMAGE-91
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-94
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-95
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-96
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-97
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-98
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-99
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE VARIABLE rs-estab AS CHARACTER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "MedTextil", "5",
"Itajai", "505",
"Ambos", "999"
     SIZE 38.72 BY .75 NO-UNDO.

DEFINE VARIABLE rs-opc-acab AS CHARACTER 
     VIEW-AS RADIO-SET VERTICAL
     RADIO-BUTTONS 
          "Liso", "L",
"Estampado", "E",
"Ambos", "A"
     SIZE 11.57 BY 2 TOOLTIP "Tipo de artigo." NO-UNDO.

DEFINE VARIABLE rs-outlet AS INTEGER 
     VIEW-AS RADIO-SET VERTICAL
     RADIO-BUTTONS 
          "Outlet IMA", 1,
"Tabela Normal", 2,
"Ambos", 3
     SIZE 17 BY 2.58 NO-UNDO.

DEFINE VARIABLE rs-selecao AS INTEGER 
     VIEW-AS RADIO-SET VERTICAL
     RADIO-BUTTONS 
          "A Faturar AtÇ:", 1,
"Faturadas de :", 2,
"Vendido de   :", 3
     SIZE 12.72 BY 3
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE rs-tipo-mercado AS CHARACTER 
     VIEW-AS RADIO-SET VERTICAL
     RADIO-BUTTONS 
          "Nacional", "0",
"Importaá∆o Direta", "1",
"Importaá∆o Indireta", "2",
"Todos", "T"
     SIZE 16 BY 2.79 TOOLTIP "Tipo de mercado." NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 74.14 BY 1.38
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-51
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 74.14 BY 5.

DEFINE RECTANGLE RECT-52
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 74.14 BY 11.

DEFINE RECTANGLE RECT-56
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 34.72 BY 2.25.

DEFINE RECTANGLE RECT-58
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 32 BY 3.63.

DEFINE RECTANGLE RECT-59
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 20 BY 3.63.

DEFINE RECTANGLE RECT-60
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 19 BY 3.63.

DEFINE VARIABLE tg-gera-dupl AS LOGICAL INITIAL yes 
     LABEL "Faturamento" 
     VIEW-AS TOGGLE-BOX
     SIZE 15 BY .58 TOOLTIP "Totaliza todo faturamento que gera duplicata" NO-UNDO.

DEFINE VARIABLE tg-lote-rd AS LOGICAL INITIAL no 
     LABEL "2¶" 
     VIEW-AS TOGGLE-BOX
     SIZE 5 BY .58 TOOLTIP "Apenas Rolo de 2¶ Qualidade." NO-UNDO.

DEFINE VARIABLE tg-lote-rp AS LOGICAL INITIAL no 
     LABEL "1¶" 
     VIEW-AS TOGGLE-BOX
     SIZE 5 BY .58 TOOLTIP "Apenas Rolo de 1¶ Qualidade ." NO-UNDO.

DEFINE VARIABLE tg-nao-gera-dupl AS LOGICAL INITIAL no 
     LABEL "Vendas entre Estab." 
     VIEW-AS TOGGLE-BOX
     SIZE 15.86 BY .58 TOOLTIP "Totaliza todo faturamento que n∆o gera duplicata" NO-UNDO.

DEFINE VARIABLE tg-outros-fat AS LOGICAL INITIAL no 
     LABEL "Outras Saidas" 
     VIEW-AS TOGGLE-BOX
     SIZE 12.29 BY .58 NO-UNDO.

DEFINE VARIABLE tg-piloto AS LOGICAL INITIAL no 
     LABEL "Pilotagem" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.57 BY .58 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     tg-piloto AT ROW 16.25 COL 42 WIDGET-ID 446
     rs-outlet AT ROW 18.67 COL 3 NO-LABEL WIDGET-ID 18
     cb-tb-preco AT ROW 16.13 COL 14 COLON-ALIGNED WIDGET-ID 12
     rs-estab AT ROW 1.75 COL 15.43 NO-LABEL WIDGET-ID 6
     rs-selecao AT ROW 3 COL 3.43 NO-LABEL
     fi-dt-faturar AT ROW 3 COL 14 COLON-ALIGNED NO-LABEL
     fi-dt-faturadas-ini AT ROW 4 COL 14 COLON-ALIGNED NO-LABEL
     fi-dt-faturadas-fin AT ROW 4 COL 42 COLON-ALIGNED NO-LABEL
     fi-dt-vendido-ini AT ROW 5 COL 14 COLON-ALIGNED NO-LABEL
     fi-dt-vendido-fin AT ROW 5 COL 42 COLON-ALIGNED NO-LABEL
     fi-nr-pedcli-ini AT ROW 6.83 COL 14 COLON-ALIGNED HELP
          "N£mero do pedido do cliente"
     fi-nr-pedcli-fin AT ROW 6.83 COL 42 COLON-ALIGNED HELP
          "N£mero do pedido do cliente" NO-LABEL
     fi-it-codigo-ini AT ROW 7.83 COL 14 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS"
     fi-it-codigo-fin AT ROW 7.83 COL 42 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" NO-LABEL
     fi-cod-refer-ini AT ROW 8.83 COL 14 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS"
     fi-cod-refer-fin AT ROW 8.83 COL 42 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" NO-LABEL
     fi-nome-abrev-ini AT ROW 9.83 COL 14 COLON-ALIGNED HELP
          "Nome abreviado do cliente"
     fi-nome-abrev-fin AT ROW 9.83 COL 42 COLON-ALIGNED HELP
          "Nome abreviado do cliente" NO-LABEL
     fi-no-ab-reppri-ini AT ROW 10.83 COL 14 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS"
     fi-no-ab-reppri-fin AT ROW 10.83 COL 42 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" NO-LABEL
     fi-ge-codigo-ini AT ROW 12.83 COL 14 COLON-ALIGNED HELP
          "Grupo de estoque a que pertence o item"
     fi-ge-codigo-fin AT ROW 12.83 COL 42 COLON-ALIGNED HELP
          "Grupo de estoque a que pertence o item" NO-LABEL
     fi-matriz-ini AT ROW 13.83 COL 14 COLON-ALIGNED HELP
          "Nome abreviado do cliente"
     fi-matriz-fin AT ROW 13.83 COL 42 COLON-ALIGNED HELP
          "Nome abreviado do cliente" NO-LABEL
     cb-tp-pedido AT ROW 15.08 COL 14 COLON-ALIGNED
     tg-lote-rp AT ROW 18.63 COL 55
     tg-lote-rd AT ROW 18.63 COL 61.29
     rs-opc-acab AT ROW 19.54 COL 55 NO-LABEL
     rs-tipo-mercado AT ROW 18.67 COL 24.43 NO-LABEL
     tg-gera-dupl AT ROW 15.5 COL 56 RIGHT-ALIGNED
     tg-nao-gera-dupl AT ROW 16.25 COL 72.86 RIGHT-ALIGNED
     tg-outros-fat AT ROW 15.5 COL 69.29 RIGHT-ALIGNED
     bt-dig-ped AT ROW 6.83 COL 60
     bt-ex-ped AT ROW 6.83 COL 65
     bt-dig-item AT ROW 7.83 COL 60
     bt-ex-item AT ROW 7.83 COL 65
     bt-dig-ref AT ROW 8.83 COL 60
     bt-ex-ref AT ROW 8.83 COL 65
     bt-dig-cli AT ROW 9.83 COL 60
     bt-ex-cli AT ROW 9.83 COL 65
     bt-dig-rep AT ROW 10.83 COL 60
     bt-ex-rep AT ROW 10.83 COL 65
     bt-ok AT ROW 22.08 COL 2.86
     bt-cancelar AT ROW 22.08 COL 13.86
     bt-ajuda AT ROW 22.08 COL 64.86
     bt-dig-ge AT ROW 12.79 COL 60 WIDGET-ID 30
     bt-ex-ge AT ROW 12.79 COL 65 WIDGET-ID 32
     bt-dig-matriz AT ROW 13.75 COL 60 WIDGET-ID 34
     bt-ex-matriz AT ROW 13.75 COL 65 WIDGET-ID 36
     fi-fm-cod-com-ini AT ROW 11.83 COL 14 COLON-ALIGNED WIDGET-ID 442
     fi-fm-cod-com-fin AT ROW 11.83 COL 41.86 COLON-ALIGNED NO-LABEL WIDGET-ID 440
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 106.57 BY 23.71
         FONT 1
         DEFAULT-BUTTON bt-ok.

/* DEFINE FRAME statement is approaching 4K Bytes.  Breaking it up   */
DEFINE FRAME F-Main
     bt-dig-fam AT ROW 11.79 COL 60 WIDGET-ID 436 NO-TAB-STOP 
     bt-ex-fam AT ROW 11.79 COL 65 WIDGET-ID 438 NO-TAB-STOP 
     "Tipo do Faturamento" VIEW-AS TEXT
          SIZE 14 BY .54 AT ROW 14.79 COL 52
     "Qualidade:" VIEW-AS TEXT
          SIZE 7.57 BY .54 AT ROW 18.63 COL 47.14 WIDGET-ID 26
     " Outlet" VIEW-AS TEXT
          SIZE 9.29 BY .75 AT ROW 17.79 COL 6.57 WIDGET-ID 28
     "Estabelecimento:" VIEW-AS TEXT
          SIZE 12 BY .54 AT ROW 1.79 COL 3.14 WIDGET-ID 10
     " Seleá∆o" VIEW-AS TEXT
          SIZE 7 BY .54 AT ROW 1 COL 3.57
     "Acabamento:" VIEW-AS TEXT
          SIZE 9.43 BY .54 AT ROW 19.5 COL 45.29
     " Origem do Produto:" VIEW-AS TEXT
          SIZE 14 BY .75 AT ROW 17.79 COL 24
     IMAGE-102 AT ROW 4.04 COL 31.57
     IMAGE-103 AT ROW 5.08 COL 31.57
     IMAGE-104 AT ROW 4.08 COL 40.57
     IMAGE-105 AT ROW 5.08 COL 40.57
     IMAGE-3 AT ROW 6.83 COL 31.57
     IMAGE-4 AT ROW 6.83 COL 40.57
     IMAGE-5 AT ROW 7.83 COL 31.57
     IMAGE-6 AT ROW 7.83 COL 40.57
     IMAGE-77 AT ROW 11.83 COL 31.72
     IMAGE-78 AT ROW 12.83 COL 31.57
     IMAGE-83 AT ROW 11.83 COL 40.57
     IMAGE-87 AT ROW 12.83 COL 40.57
     IMAGE-90 AT ROW 8.83 COL 31.57
     IMAGE-91 AT ROW 8.83 COL 40.57
     IMAGE-94 AT ROW 9.83 COL 31.57
     IMAGE-95 AT ROW 9.83 COL 40.57
     IMAGE-96 AT ROW 10.83 COL 31.57
     IMAGE-97 AT ROW 10.83 COL 40.57
     IMAGE-98 AT ROW 13.83 COL 31.57
     IMAGE-99 AT ROW 13.83 COL 40.57
     RECT-1 AT ROW 21.88 COL 1.86
     RECT-51 AT ROW 1.25 COL 1.86
     RECT-52 AT ROW 6.5 COL 1.86
     RECT-56 AT ROW 15.04 COL 40.29
     im-ima AT ROW 1.5 COL 60 WIDGET-ID 2
     im-med AT ROW 1.54 COL 69.29 WIDGET-ID 4
     RECT-58 AT ROW 18.13 COL 44 WIDGET-ID 16
     RECT-59 AT ROW 18.13 COL 22.43 WIDGET-ID 22
     RECT-60 AT ROW 18.13 COL 2 WIDGET-ID 24
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 106.57 BY 23.71
         FONT 1
         DEFAULT-BUTTON bt-ok.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: JanelaDetalhe
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-window ASSIGN
         HIDDEN             = YES
         TITLE              = "Seleá∆o da Administraá∆o da Carteira e do Faturamento - ESSP0190a"
         HEIGHT             = 22.38
         WIDTH              = 75.86
         MAX-HEIGHT         = 28.96
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 28.96
         VIRTUAL-WIDTH      = 146.29
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         FONT               = 1
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-window 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-window.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-window
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME Custom                                                    */
/* SETTINGS FOR COMBO-BOX cb-tp-pedido IN FRAME F-Main
   5                                                                    */
/* SETTINGS FOR FILL-IN fi-fm-cod-com-fin IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-fm-cod-com-ini IN FRAME F-Main
   1                                                                    */
/* SETTINGS FOR IMAGE im-ima IN FRAME F-Main
   NO-ENABLE                                                            */
ASSIGN 
       im-ima:HIDDEN IN FRAME F-Main           = TRUE.

/* SETTINGS FOR IMAGE im-med IN FRAME F-Main
   NO-ENABLE                                                            */
ASSIGN 
       im-med:HIDDEN IN FRAME F-Main           = TRUE.

/* SETTINGS FOR TOGGLE-BOX tg-gera-dupl IN FRAME F-Main
   ALIGN-R                                                              */
/* SETTINGS FOR TOGGLE-BOX tg-nao-gera-dupl IN FRAME F-Main
   ALIGN-R                                                              */
/* SETTINGS FOR TOGGLE-BOX tg-outros-fat IN FRAME F-Main
   ALIGN-R                                                              */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
THEN w-window:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON END-ERROR OF w-window /* Seleá∆o da Administraá∆o da Carteira e do Faturamento - ESSP0190a */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON WINDOW-CLOSE OF w-window /* Seleá∆o da Administraá∆o da Carteira e do Faturamento - ESSP0190a */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-window
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-window
ON CHOOSE OF bt-cancelar IN FRAME F-Main /* Cancelar */
DO:
  ASSIGN l-ok = NO.
  APPLY "close":U TO THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-cli
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-cli w-window
ON CHOOSE OF bt-dig-cli IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Cliente").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-fam
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-fam w-window
ON CHOOSE OF bt-dig-fam IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Categoria").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-ge
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-ge w-window
ON CHOOSE OF bt-dig-ge IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Codigo_Obsoleto").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-item w-window
ON CHOOSE OF bt-dig-item IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Item").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-matriz
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-matriz w-window
ON CHOOSE OF bt-dig-matriz IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Codigo_Obsoleto").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-ped w-window
ON CHOOSE OF bt-dig-ped IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Pedido_de_Venda").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-ref
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-ref w-window
ON CHOOSE OF bt-dig-ref IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Referància").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-dig-rep
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-dig-rep w-window
ON CHOOSE OF bt-dig-rep IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                            INPUT "D",
                            INPUT "Representante").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-cli
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-cli w-window
ON CHOOSE OF bt-ex-cli IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                              INPUT "E",
                              INPUT "Cliente").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-fam
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-fam w-window
ON CHOOSE OF bt-ex-fam IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                              INPUT "E",
                              INPUT "Categoria").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-ge
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-ge w-window
ON CHOOSE OF bt-ex-ge IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita,
                              INPUT "E",
                              INPUT "Codigo_Obsoleto").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-item w-window
ON CHOOSE OF bt-ex-item IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                              INPUT "E",
                              INPUT "Item").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-matriz
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-matriz w-window
ON CHOOSE OF bt-ex-matriz IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita,
                              INPUT "E",
                              INPUT "Codigo_Obsoleto").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-ped w-window
ON CHOOSE OF bt-ex-ped IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita,
                            INPUT "E",
                            INPUT "Pedido_de_Venda").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-ref
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-ref w-window
ON CHOOSE OF bt-ex-ref IN FRAME F-Main
DO:
   RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                             INPUT "E",
                             INPUT "Referància").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ex-rep
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ex-rep w-window
ON CHOOSE OF bt-ex-rep IN FRAME F-Main
DO:
    RUN esdlg/d01-digita.w (INPUT-OUTPUT TABLE tt-digita, 
                              INPUT "E",
                              INPUT "Representante").

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-window
ON CHOOSE OF bt-ok IN FRAME F-Main /* OK */
DO:
    ASSIGN INPUT FRAME {&FRAME-NAME} fi-dt-faturar
           INPUT FRAME {&FRAME-NAME} fi-dt-vendido-ini
           INPUT FRAME {&FRAME-NAME} fi-dt-vendido-fin
           INPUT FRAME {&FRAME-NAME} rs-selecao
           INPUT FRAME {&FRAME-NAME} rs-estab
           INPUT FRAME {&FRAME-NAME} tg-gera-dupl
           INPUT FRAME {&FRAME-NAME} tg-nao-gera-dupl
           INPUT FRAME {&FRAME-NAME} tg-outros-fat
           INPUT FRAME {&FRAME-NAME} tg-piloto.

    CASE rs-selecao:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
        WHEN "1" THEN DO:
            IF INT(SUBSTR(fi-dt-faturar,1,2)) <  1 OR
               INT(SUBSTR(fi-dt-faturar,1,2)) > 12  THEN DO:
                MESSAGE "MES invalido ! ! !"  VIEW-AS ALERT-BOX. 
                APPLY 'entry' TO fi-dt-faturar.
                RETURN NO-APPLY.
            END.
            IF INT(SUBSTR(fi-dt-faturar,4,4)) <  1 THEN DO:
                MESSAGE "ANO invalido ! ! !"  VIEW-AS ALERT-BOX. 
                APPLY 'entry' TO fi-dt-faturar.
                RETURN NO-APPLY.
            END.
        END.
        WHEN "2" THEN DO:
            /*
            /*  Retirado Consistencia da Pedida Dentro do Mesmo Periodo em 17/04/2010 FABIO LANZA */
            IF SUBSTR(fi-dt-faturadas-ini:SCREEN-VALUE,4,2) <>
               SUBSTR(fi-dt-faturadas-fin:SCREEN-VALUE,4,2) THEN DO:
               MESSAGE "MES Inicial n∆o pode ser DIFERENTE do mes Final ! ! !"  VIEW-AS ALERT-BOX. 
               APPLY 'entry' TO fi-dt-faturadas-ini.
               RETURN NO-APPLY.
            END.
            IF SUBSTR(fi-dt-faturadas-ini:SCREEN-VALUE,7,4) <>
               SUBSTR(fi-dt-faturadas-fin:SCREEN-VALUE,7,4) THEN DO:
               MESSAGE "ANO Inicial n∆o pode ser DIFERENTE do Ano Final ! ! !"  VIEW-AS ALERT-BOX. 
               APPLY 'entry' TO fi-dt-faturadas-ini.
               RETURN NO-APPLY.
            END.
            */
        END.
        WHEN "3" THEN DO:
            IF INT(SUBSTR(fi-dt-vendido-ini,1,2)) <  1 OR
               INT(SUBSTR(fi-dt-vendido-ini,1,2)) > 12  THEN DO:
                MESSAGE "MES invalido ! ! !"  VIEW-AS ALERT-BOX. 
                APPLY 'entry' TO fi-dt-vendido-ini.
                RETURN NO-APPLY.
            END.
            IF INT(SUBSTR(fi-dt-vendido-ini,4,4)) <  1 THEN DO:
                MESSAGE "ANO invalido ! ! !"  VIEW-AS ALERT-BOX. 
                APPLY 'entry' TO fi-dt-vendido-ini.
                RETURN NO-APPLY.
            END.

            IF INT(SUBSTR(fi-dt-vendido-fin,1,2)) <  1 OR
               INT(SUBSTR(fi-dt-vendido-fin,1,2)) > 12  THEN DO:
                MESSAGE "MES invalido ! ! !"  VIEW-AS ALERT-BOX. 
                APPLY 'entry' TO fi-dt-vendido-fin.
                RETURN NO-APPLY.
            END.
            IF INT(SUBSTR(fi-dt-vendido-fin,4,4)) <  1 THEN DO:
                MESSAGE "ANO invalido ! ! !"  VIEW-AS ALERT-BOX. 
                APPLY 'entry' TO fi-dt-vendido-fin.
                RETURN NO-APPLY.
            END.
        END.
    END CASE.

    IF rs-selecao = 2 THEN DO:
       IF tg-gera-dupl = NO      AND  tg-piloto = NO AND 
          tg-nao-gera-dupl = NO  AND  tg-outros-fat = NO  THEN DO:
          MESSAGE "ê obrigat¢rio selecionar um tipo do faturamento ! ! !"  VIEW-AS ALERT-BOX. 
          APPLY 'entry' TO tg-gera-dupl.
          RETURN NO-APPLY.
       END.
    END.
    ASSIGN i-tp-selecao       = INPUT FRAME {&FRAME-NAME} rs-selecao
           c-dt-faturar       = INPUT FRAME {&FRAME-NAME} fi-dt-faturar   
           c-dt-faturadas-ini = INPUT FRAME {&FRAME-NAME} fi-dt-faturadas-ini
           c-dt-faturadas-fin = INPUT FRAME {&FRAME-NAME} fi-dt-faturadas-fin
           c-dt-vendido-ini   = INPUT FRAME {&FRAME-NAME} fi-dt-vendido-ini
           c-dt-vendido-fin   = INPUT FRAME {&FRAME-NAME} fi-dt-vendido-fin
           c-cod-estabel-ini  = IF rs-estab = '999' 
                                THEN "1"
                                ELSE rs-estab
           c-cod-estabel-fin  = rs-estab 
           c-nr-pedcli-ini    = INPUT FRAME {&FRAME-NAME} fi-nr-pedcli-ini   
           c-nr-pedcli-fin    = INPUT FRAME {&FRAME-NAME} fi-nr-pedcli-fin   
           c-it-codigo-ini    = INPUT FRAME {&FRAME-NAME} fi-it-codigo-ini   
           c-it-codigo-fin    = INPUT FRAME {&FRAME-NAME} fi-it-codigo-fin   
           c-cod-refer-ini    = INPUT FRAME {&FRAME-NAME} fi-cod-refer-ini   
           c-cod-refer-fin    = INPUT FRAME {&FRAME-NAME} fi-cod-refer-fin   
           c-nome-abrev-ini   = INPUT FRAME {&FRAME-NAME} fi-nome-abrev-ini
           c-nome-abrev-fin   = INPUT FRAME {&FRAME-NAME} fi-nome-abrev-fin
           c-no-ab-reppri-ini = INPUT FRAME {&FRAME-NAME} fi-no-ab-reppri-ini
           c-no-ab-reppri-fin = INPUT FRAME {&FRAME-NAME} fi-no-ab-reppri-fin
           c-fm-cod-com-ini   = INPUT FRAME {&FRAME-NAME} fi-fm-cod-com-ini
           c-fm-cod-com-fin   = INPUT FRAME {&FRAME-NAME} fi-fm-cod-com-fin 
           i-ge-codigo-ini    = INPUT FRAME {&FRAME-NAME} fi-ge-codigo-ini
           i-ge-codigo-fin    = INPUT FRAME {&FRAME-NAME} fi-ge-codigo-fin
           c-matriz-ini       = INPUT FRAME {&FRAME-NAME} fi-matriz-ini
           c-matriz-fin       = INPUT FRAME {&FRAME-NAME} fi-matriz-fin
           c-tp-pedido        = INPUT FRAME {&FRAME-NAME} cb-tp-pedido
           i-tb_preco_id      = INPUT FRAME {&FRAME-NAME} cb-tb-preco
           l-lote-rp          = INPUT FRAME {&FRAME-NAME} tg-lote-rp
           l-lote-rd          = INPUT FRAME {&FRAME-NAME} tg-lote-rd
           i-outlet           = INPUT FRAME {&FRAME-NAME} rs-outlet
           c-tipo-acabamento  = INPUT FRAME {&FRAME-NAME} rs-opc-acab   
           c-tipo-mercado     = INPUT FRAME {&FRAME-NAME} rs-tipo-mercado   
           l-gera-duplicata   = INPUT FRAME {&FRAME-NAME} tg-gera-dupl
           l-nao-gera-dupl    = INPUT FRAME {&FRAME-NAME} tg-nao-gera-dupl
           l-outros-fat       = INPUT FRAME {&FRAME-NAME} tg-outros-fat
           l-pilotagem        = INPUT FRAME {&FRAME-NAME} tg-piloto
           l-ok = YES.  
    
    APPLY "close":U TO THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-refer-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer-fin w-window
ON MOUSE-SELECT-DBLCLICK OF fi-cod-refer-fin IN FRAME F-Main
DO:
    {include/zoomvar.i &prog-zoom = inzoom/z02in377.w
                       &campo     = fi-cod-refer-fin
                       &campozoom = cod-refer}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-refer-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer-ini w-window
ON LEAVE OF fi-cod-refer-ini IN FRAME F-Main /* Referància */
DO:
  IF SELF:SCREEN-VALUE <> '' THEN
     ASSIGN fi-cod-refer-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer-ini w-window
ON LEFT-MOUSE-DBLCLICK OF fi-cod-refer-ini IN FRAME F-Main /* Referància */
DO:
    {include/zoomvar.i &prog-zoom = inzoom/z02in377.w
                       &campo     = fi-cod-refer-ini
                       &campozoom = cod-refer}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-fm-cod-com-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-fm-cod-com-ini w-window
ON LEAVE OF fi-fm-cod-com-ini IN FRAME F-Main /* Categoria */
DO:
  ASSIGN fi-fm-cod-com-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZ'.
  IF SELF:SCREEN-VALUE <> '' THEN
     ASSIGN fi-fm-cod-com-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-fm-cod-com-ini w-window
ON MOUSE-SELECT-DBLCLICK OF fi-fm-cod-com-ini IN FRAME F-Main /* Categoria */
DO:
  {include/zoomvar.i &prog-zoom = dizoom/z01di050.w
                     &campo     = fi-fm-cod-com-ini
                     &campozoom = fm-cod-com}

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-ge-codigo-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-ge-codigo-fin w-window
ON MOUSE-SELECT-DBLCLICK OF fi-ge-codigo-fin IN FRAME F-Main
DO:
  {include/zoomvar.i &prog-zoom = inzoom/z01in142.w
                     &campo     = fi-ge-codigo-fin
                     &campozoom = ge-codigo}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-ge-codigo-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-ge-codigo-ini w-window
ON MOUSE-SELECT-DBLCLICK OF fi-ge-codigo-ini IN FRAME F-Main /* Grupo Estoque */
DO:
  {include/zoomvar.i &prog-zoom = inzoom/z01in142.w
                     &campo     = fi-ge-codigo-ini
                     &campozoom = ge-codigo}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-it-codigo-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo-fin w-window
ON MOUSE-SELECT-DBLCLICK OF fi-it-codigo-fin IN FRAME F-Main
DO:
    {include/zoomvar.i &prog-zoom = inzoom/z02in172.w
                     &campo     = fi-it-codigo-fin
                     &campozoom = it-codigo}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-it-codigo-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo-ini w-window
ON LEAVE OF fi-it-codigo-ini IN FRAME F-Main /* Item */
DO:
  IF SELF:SCREEN-VALUE <> '' AND
     SELF:SCREEN-VALUE <> '5' THEN
     ASSIGN fi-it-codigo-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo-ini w-window
ON MOUSE-SELECT-DBLCLICK OF fi-it-codigo-ini IN FRAME F-Main /* Item */
DO:
  {include/zoomvar.i &prog-zoom = inzoom/z02in172.w
                     &campo     = fi-it-codigo-ini
                     &campozoom = it-codigo}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-matriz-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-matriz-fin w-window
ON LEAVE OF fi-matriz-fin IN FRAME F-Main
DO:
   IF SELF:SCREEN-VALUE <> '' THEN DO.
      FIND emitente USE-INDEX nome WHERE 
           emitente.nome-abrev = INPUT FRAME {&FRAME-NAME} fi-matriz-fin NO-LOCK NO-ERROR.
      IF NOT AVAIL emitente THEN
         FIND emitente USE-INDEX codigo WHERE 
              STRING(emitente.cod-emit) = INPUT FRAME {&FRAME-NAME} fi-matriz-fin NO-LOCK NO-ERROR.

      IF AVAIL emitente THEN
          ASSIGN fi-matriz-fin:SCREEN-VALUE IN FRAME {&FRAME-NAME} = emitente.nome-abrev.
END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-matriz-fin w-window
ON MOUSE-SELECT-DBLCLICK OF fi-matriz-fin IN FRAME F-Main
DO:
    {include/zoomvar.i &prog-zoom = adzoom/z02ad098.w
                       &campo     = fi-nome-abrev-fin
                       &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-matriz-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-matriz-ini w-window
ON LEAVE OF fi-matriz-ini IN FRAME F-Main /* Matriz */
DO:
  IF SELF:SCREEN-VALUE <> '' THEN DO:
     FIND emitente WHERE 
          emitente.nome-abrev = INPUT FRAME {&FRAME-NAME} fi-matriz-ini
          USE-INDEX nome NO-LOCK NO-ERROR.
     IF NOT AVAIL emitente THEN
        FIND emitente WHERE 
             STRING(emitente.cod-emit) = INPUT FRAME {&FRAME-NAME} fi-matriz-ini 
             USE-INDEX codigo NO-LOCK NO-ERROR.

     IF AVAIL emitente THEN
         ASSIGN fi-matriz-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME} = emitente.nome-abrev.

     ASSIGN fi-matriz-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-matriz-ini w-window
ON MOUSE-SELECT-DBLCLICK OF fi-matriz-ini IN FRAME F-Main /* Matriz */
DO:
    {include/zoomvar.i &prog-zoom = adzoom/z02ad098.w
                       &campo     = fi-nome-abrev-ini
                       &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-no-ab-reppri-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-no-ab-reppri-fin w-window
ON LEAVE OF fi-no-ab-reppri-fin IN FRAME F-Main
DO:
    IF SELF:SCREEN-VALUE <> '' THEN DO:
       FIND repres WHERE 
            STRING(repres.cod-rep) = INPUT FRAME {&FRAME-NAME} fi-no-ab-reppri-fin
            USE-INDEX codigo NO-LOCK NO-ERROR.
       IF NOT AVAIL repres THEN
          FIND repres WHERE 
               repres.nome-abrev = INPUT FRAME {&FRAME-NAME} fi-no-ab-reppri-fin 
               USE-INDEX abrev NO-LOCK NO-ERROR.

       IF AVAIL repres THEN
           ASSIGN fi-no-ab-reppri-fin:SCREEN-VALUE IN FRAME {&FRAME-NAME} = repres.nome-abrev.

    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-no-ab-reppri-fin w-window
ON MOUSE-SELECT-DBLCLICK OF fi-no-ab-reppri-fin IN FRAME F-Main
DO:
  {include/zoomvar.i &prog-zoom = adzoom/z01ad229.w
                     &campo     = fi-no-ab-reppri-fin
                     &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-no-ab-reppri-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-no-ab-reppri-ini w-window
ON LEAVE OF fi-no-ab-reppri-ini IN FRAME F-Main /* Representante */
DO:
  IF SELF:SCREEN-VALUE <> '' THEN DO:
     FIND repres WHERE 
          STRING(repres.cod-rep) = INPUT FRAME {&FRAME-NAME} fi-no-ab-reppri-ini
          USE-INDEX codigo NO-LOCK NO-ERROR.
     IF NOT AVAIL repres THEN
        FIND repres WHERE 
             repres.nome-abrev = INPUT FRAME {&FRAME-NAME} fi-no-ab-reppri-ini 
             USE-INDEX abrev NO-LOCK NO-ERROR.

     IF AVAIL repres THEN
         ASSIGN fi-no-ab-reppri-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME} = repres.nome-abrev.

     ASSIGN fi-no-ab-reppri-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-no-ab-reppri-ini w-window
ON MOUSE-SELECT-DBLCLICK OF fi-no-ab-reppri-ini IN FRAME F-Main /* Representante */
DO:
  {include/zoomvar.i &prog-zoom = adzoom/z01ad229.w
                     &campo     = fi-no-ab-reppri-ini
                     &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-nome-abrev-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nome-abrev-fin w-window
ON LEAVE OF fi-nome-abrev-fin IN FRAME F-Main
DO:
   IF SELF:SCREEN-VALUE <> '' THEN DO.
      FIND emitente USE-INDEX nome WHERE 
           emitente.nome-abrev = INPUT FRAME {&FRAME-NAME} fi-nome-abrev-fin NO-LOCK NO-ERROR.
      IF NOT AVAIL emitente THEN
         FIND emitente USE-INDEX codigo WHERE 
              STRING(emitente.cod-emit) = INPUT FRAME {&FRAME-NAME} fi-nome-abrev-fin NO-LOCK NO-ERROR.

      IF AVAIL emitente THEN
          ASSIGN fi-nome-abrev-fin:SCREEN-VALUE IN FRAME {&FRAME-NAME} = emitente.nome-abrev.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nome-abrev-fin w-window
ON MOUSE-SELECT-DBLCLICK OF fi-nome-abrev-fin IN FRAME F-Main
DO:
    {include/zoomvar.i &prog-zoom = adzoom/z02ad098.w
                       &campo     = fi-nome-abrev-fin
                       &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-nome-abrev-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nome-abrev-ini w-window
ON LEAVE OF fi-nome-abrev-ini IN FRAME F-Main /* Cliente */
DO:
  IF SELF:SCREEN-VALUE <> '' THEN DO:
     FIND emitente WHERE 
          emitente.nome-abrev = INPUT FRAME {&FRAME-NAME} fi-nome-abrev-ini
          USE-INDEX nome NO-LOCK NO-ERROR.
     IF NOT AVAIL emitente THEN
        FIND emitente WHERE 
             STRING(emitente.cod-emit) = INPUT FRAME {&FRAME-NAME} fi-nome-abrev-ini 
             USE-INDEX codigo NO-LOCK NO-ERROR.

     IF AVAIL emitente THEN
         ASSIGN fi-nome-abrev-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME} = emitente.nome-abrev.

     ASSIGN fi-nome-abrev-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nome-abrev-ini w-window
ON MOUSE-SELECT-DBLCLICK OF fi-nome-abrev-ini IN FRAME F-Main /* Cliente */
DO:
    {include/zoomvar.i &prog-zoom = adzoom/z02ad098.w
                       &campo     = fi-nome-abrev-ini
                       &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-nr-pedcli-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nr-pedcli-ini w-window
ON LEAVE OF fi-nr-pedcli-ini IN FRAME F-Main /* Pedido */
DO:
  IF SELF:SCREEN-VALUE <> '' THEN
     ASSIGN fi-nr-pedcli-fin:SCREEN-VALUE = SELF:SCREEN-VALUE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-estab
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-estab w-window
ON VALUE-CHANGED OF rs-estab IN FRAME F-Main
DO:
   ASSIGN im-ima:VISIBLE IN FRAME {&FRAME-NAME} = NO
          im-med:VISIBLE = NO.
   CASE SELF:SCREEN-VALUE.
       //WHEN '1' THEN ASSIGN im-ima:VISIBLE = YES.
       WHEN '5' THEN ASSIGN im-med:VISIBLE = YES.
       WHEN '999' THEN ASSIGN im-ima:VISIBLE = YES
                             im-med:VISIBLE = YES.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-selecao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-selecao w-window
ON VALUE-CHANGED OF rs-selecao IN FRAME F-Main
DO:
  fi-dt-faturar:SENSITIVE IN FRAME {&FRAME-NAME}       = NO.
  fi-dt-faturadas-ini:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
  fi-dt-faturadas-fin:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
  fi-dt-vendido-ini:SENSITIVE IN FRAME {&FRAME-NAME}   = NO.
  fi-dt-vendido-fin:SENSITIVE IN FRAME {&FRAME-NAME}   = NO.

  ASSIGN tg-outros-fat:SCREEN-VALUE      = "NO".

  /*IF base BEGINS "IMA" THEN
     ASSIGN rs-estab:SCREEN-VALUE = "1".
  ELSE
     ASSIGN rs-estab:SCREEN-VALUE = "5".*/

  CASE rs-selecao:SCREEN-VALUE:
      WHEN "1" THEN DO:
          fi-dt-faturar:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
          APPLY "entry" TO fi-dt-faturar.
      END.
      WHEN "2" THEN DO:
          fi-dt-faturadas-ini:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
          fi-dt-faturadas-fin:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
          APPLY "entry" TO fi-dt-faturadas-ini.
      END.
      WHEN "3" THEN DO:
          fi-dt-vendido-ini:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
          fi-dt-vendido-fin:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
          APPLY "entry" TO fi-dt-vendido-ini.
      END.
  END CASE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-gera-dupl
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-gera-dupl w-window
ON VALUE-CHANGED OF tg-gera-dupl IN FRAME F-Main /* Faturamento */
DO:
   ASSIGN tg-outros-fat:SCREEN-VALUE  = "NO"
          tg-nao-gera-dupl:SCREEN-VALUE = "NO".
          
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-nao-gera-dupl
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-nao-gera-dupl w-window
ON VALUE-CHANGED OF tg-nao-gera-dupl IN FRAME F-Main /* Vendas entre Estab. */
DO:
    ASSIGN tg-outros-fat:SCREEN-VALUE = "NO"
           tg-gera-dupl:SCREEN-VALUE  = "NO"
           tg-piloto:SCREEN-VALUE = "NO".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-outros-fat
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-outros-fat w-window
ON VALUE-CHANGED OF tg-outros-fat IN FRAME F-Main /* Outras Saidas */
DO:
   ASSIGN tg-gera-dupl:SCREEN-VALUE     = "NO"
          tg-nao-gera-dupl:SCREEN-VALUE = "NO"
          tg-piloto:SCREEN-VALUE = "NO".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-piloto
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-piloto w-window
ON VALUE-CHANGED OF tg-piloto IN FRAME F-Main /* Pilotagem */
DO:
    ASSIGN tg-outros-fat:SCREEN-VALUE    = "NO"
           tg-nao-gera-dupl:SCREEN-VALUE = "NO".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-window 


/* ***************************  Main Block  *************************** */
fi-it-codigo-ini:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-it-codigo-fin:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-cod-refer-ini:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-cod-refer-fin:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-nome-abrev-ini:LOAD-MOUSE-POINTER("image/lupa.cur")   IN FRAME {&FRAME-NAME}.
fi-nome-abrev-fin:LOAD-MOUSE-POINTER("image/lupa.cur")   IN FRAME {&FRAME-NAME}.
fi-no-ab-reppri-ini:LOAD-MOUSE-POINTER("image/lupa.cur") IN FRAME {&FRAME-NAME}.
fi-no-ab-reppri-fin:LOAD-MOUSE-POINTER("image/lupa.cur") IN FRAME {&FRAME-NAME}.
fi-fm-cod-com-ini:LOAD-MOUSE-POINTER("image/lupa.cur") IN FRAME {&FRAME-NAME}.
fi-fm-cod-com-fin:LOAD-MOUSE-POINTER("image/lupa.cur") IN FRAME {&FRAME-NAME}.
fi-ge-codigo-ini:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.
fi-ge-codigo-fin:LOAD-MOUSE-POINTER("image/lupa.cur")    IN FRAME {&FRAME-NAME}.

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-window  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-window  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
  THEN DELETE WIDGET w-window.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-window  _DEFAULT-ENABLE
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
  DISPLAY tg-piloto rs-outlet cb-tb-preco rs-estab rs-selecao fi-dt-faturar 
          fi-dt-faturadas-ini fi-dt-faturadas-fin fi-dt-vendido-ini 
          fi-dt-vendido-fin fi-nr-pedcli-ini fi-nr-pedcli-fin fi-it-codigo-ini 
          fi-it-codigo-fin fi-cod-refer-ini fi-cod-refer-fin fi-nome-abrev-ini 
          fi-nome-abrev-fin fi-no-ab-reppri-ini fi-no-ab-reppri-fin 
          fi-ge-codigo-ini fi-ge-codigo-fin fi-matriz-ini fi-matriz-fin 
          cb-tp-pedido tg-lote-rp tg-lote-rd rs-opc-acab rs-tipo-mercado 
          tg-gera-dupl tg-nao-gera-dupl tg-outros-fat fi-fm-cod-com-ini 
          fi-fm-cod-com-fin 
      WITH FRAME F-Main IN WINDOW w-window.
  ENABLE tg-piloto rs-outlet cb-tb-preco rs-estab rs-selecao fi-dt-faturar 
         fi-dt-faturadas-ini fi-dt-faturadas-fin fi-dt-vendido-ini 
         fi-dt-vendido-fin fi-nr-pedcli-ini fi-nr-pedcli-fin fi-it-codigo-ini 
         fi-it-codigo-fin fi-cod-refer-ini fi-cod-refer-fin fi-nome-abrev-ini 
         fi-nome-abrev-fin fi-no-ab-reppri-ini fi-no-ab-reppri-fin 
         fi-ge-codigo-ini fi-ge-codigo-fin fi-matriz-ini fi-matriz-fin 
         cb-tp-pedido tg-lote-rp tg-lote-rd rs-opc-acab rs-tipo-mercado 
         tg-gera-dupl tg-nao-gera-dupl tg-outros-fat bt-dig-ped bt-ex-ped 
         bt-dig-item bt-ex-item bt-dig-ref bt-ex-ref bt-dig-cli bt-ex-cli 
         bt-dig-rep bt-ex-rep bt-ok bt-cancelar bt-ajuda bt-dig-ge bt-ex-ge 
         bt-dig-matriz bt-ex-matriz fi-fm-cod-com-ini fi-fm-cod-com-fin 
         bt-dig-fam bt-ex-fam IMAGE-102 IMAGE-103 IMAGE-104 IMAGE-105 IMAGE-3 
         IMAGE-4 IMAGE-5 IMAGE-6 IMAGE-77 IMAGE-78 IMAGE-83 IMAGE-87 IMAGE-90 
         IMAGE-91 IMAGE-94 IMAGE-95 IMAGE-96 IMAGE-97 IMAGE-98 IMAGE-99 RECT-1 
         RECT-51 RECT-52 RECT-56 RECT-58 RECT-59 RECT-60 
      WITH FRAME F-Main IN WINDOW w-window.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW w-window.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-window 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  {include/win-size.i}
 
  ASSIGN rs-selecao          = i-tp-selecao
         rs-estab            = '5'
         //rs-estab            = c-cod-estabel-fin
         fi-dt-faturar       = c-dt-faturar       
         fi-dt-faturadas-ini = c-dt-faturadas-ini 
         fi-dt-faturadas-fin = c-dt-faturadas-fin 
         fi-dt-vendido-ini   = c-dt-vendido-ini   
         fi-dt-vendido-fin   = c-dt-vendido-fin  
         fi-nr-pedcli-ini    = c-nr-pedcli-ini    
         fi-nr-pedcli-fin    = c-nr-pedcli-fin    
         fi-it-codigo-ini    = c-it-codigo-ini    
         fi-it-codigo-fin    = c-it-codigo-fin    
         fi-cod-refer-ini    = c-cod-refer-ini    
         fi-cod-refer-fin    = c-cod-refer-fin    
         fi-nome-abrev-ini   = c-nome-abrev-ini   
         fi-nome-abrev-fin   = c-nome-abrev-fin   
         fi-no-ab-reppri-ini = c-no-ab-reppri-ini 
         fi-no-ab-reppri-fin = c-no-ab-reppri-fin 
         fi-fm-cod-com-ini = c-fm-cod-com-ini 
         fi-fm-cod-com-fin = c-fm-cod-com-fin 
         fi-fm-cod-com-ini = c-fm-cod-com-ini 
         fi-fm-cod-com-fin = c-fm-cod-com-fin 
         fi-ge-codigo-ini    = i-ge-codigo-ini    
         fi-ge-codigo-fin    = i-ge-codigo-fin    
         fi-matriz-ini       = c-matriz-ini       
         fi-matriz-fin       = c-matriz-fin       
         cb-tp-pedido        = c-tp-pedido        
         cb-tb-preco         = 9
         tg-lote-rp          = l-lote-rp          
         tg-lote-rd          = l-lote-rd          
         rs-outlet           = i-outlet
         rs-opc-acab         = c-tipo-acabamento  
         rs-tipo-mercado     = c-tipo-mercado     
         tg-gera-dupl        = l-gera-duplicata 
         tg-nao-gera-dupl    = l-nao-gera-dupl
         tg-outros-fat       = l-outros-fat
         tg-piloto           = l-pilotagem.
 
 
  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  FIND fnd_usuar_univ WHERE
       fnd_usuar_univ.cod_usuario = c-seg-usuario NO-LOCK NO-ERROR.

  ASSIGN base = IF fnd_usuar_univ.cod_empresa = '1' 
                THEN 'IMA' ELSE 'MED'.

/*
  ASSIGN fi-dt-faturar:SCREEN-VALUE = STRING(MONTH(TODAY),'99') + STRING(YEAR(TODAY),'9999').

  ASSIGN fi-dt-faturadas-ini:SCREEN-VALUE = "01" + STRING(MONTH(TODAY), "99") + STRING(YEAR(TODAY), "9999")
         fi-dt-faturadas-fin:SCREEN-VALUE = STRING(TODAY, "99/99/9999").

  ASSIGN fi-dt-vendido-ini:SCREEN-VALUE = "010001"                                                
         fi-dt-vendido-fin:SCREEN-VALUE = STRING(MONTH(TODAY),"99") + STRING(YEAR(TODAY),"9999").
*/         


  ASSIGN c-lst-tab = "".
  FOR EACH tbs_preco NO-LOCK.
  ASSIGN c-lst-tab = IF c-lst-tab = ''
                     THEN "Todas,9," + tbs_preco.descricao + "," + STRING(tbs_preco.tb_preco_id) 
                     ELSE c-lst-tab + "," + tbs_preco.descricao + "," + STRING(tbs_preco.tb_preco_id).
  END.
  ASSIGN cb-tb-preco:LIST-ITEM-PAIRS = c-lst-tab.

  ASSIGN cb-tb-preco:SCREEN-VALUE = STRING(i-tb_preco_id).



  /*
  ASSIGN c-lst-tab = "".
  FOR EACH tb-preco.
      ASSIGN c-lst-tab = IF c-lst-tab = ""
                         THEN "Nenhuma," + tb-preco.nr-tabpre
                         ELSE c-lst-tab + "," + tb-preco.nr-tabpre.
  END.
  ASSIGN cb-tb-preco:LIST-ITEMS = c-lst-tab.
  ASSIGN cb-tb-preco:SCREEN-VALUE = ENTRY(1,c-lst-tab).
  */




  APPLY "value-changed" TO rs-selecao.
  APPLY 'value-changed' TO rs-estab.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-window  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this JanelaDetalhe, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-window 
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

