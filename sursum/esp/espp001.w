&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          ems2med          PROGRESS
*/
&Scoped-define WINDOW-NAME w-cadsim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-cadsim 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/

{include/i-prgvrs.i "ESPP001" "2.04.00.001"}


/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
{esp/util.i}
{esp/params.i}
/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-pp-container AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR i-sit-container AS INT NO-UNDO.
DEF NEW GLOBAL SHARED VAR l-acao AS LOGICAL.

DEF TEMP-TABLE tt-it-container NO-UNDO LIKE pp-it-container
    FIELD tp-acao AS CHAR
    INDEX indice1 it-comprado ref-comprada.

DEF TEMP-TABLE tt-pack-list
    FIELD it-codigo  AS CHAR
    FIELD cod-refer  AS CHAR
    FIELD quantidade AS DECIMAL
    FIELD estab      AS INT
    FIELD matric     AS INT
    FIELD nome       AS CHAR
    FIELD setor      AS CHAR
    FIELD dt-admis   AS CHAR
    FIELD limite     AS DEC
    FIELD sld-disp   AS DEC
    FIELD so-pode    AS CHAR
    FIELD vlr-compra AS DEC
    FIELD prazo      AS INT
    FIELD parcela    AS DEC
    FIELD a-vista    AS DEC
    FIELD parc-unica AS DEC
    FIELD parcelado  AS DEC.

DEF BUFFER b-tt-it-container FOR tt-it-container.

DEF VAR r-row-table AS ROWID.
DEF VAR c-arq-conv  as char no-undo.
DEF VAR l-ok as logical no-undo.
DEF VAR l-new AS LOG.
DEF VAR i-nr-container AS INT.
DEF VAR de-qt-vend AS DECIMAL.

// Var veis Indice de Financiamento
DEF VAR i-prazo-medio AS DECIMAL  INIT 90.
DEF VAR i-ct AS INTEGER.
DEF VAR de-ind-finan AS DECIMAL.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-cadsim
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME br-ped-item

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-it-container ITEM

/* Definitions for BROWSE br-ped-item                                   */
&Scoped-define FIELDS-IN-QUERY-br-ped-item tt-it-container.it-comprado item.desc-item tt-it-container.ref-comprada tt-it-container.qt-pedida tt-it-container.preco-vd-real tt-it-container.preco-vd-dolar tt-it-container.perc-dsp-venda tt-it-container.qt-vendida   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-ped-item   
&Scoped-define SELF-NAME br-ped-item
&Scoped-define OPEN-QUERY-br-ped-item RUN pi-total. OPEN QUERY {&self-name} FOR EACH tt-it-container WHERE                                  tt-it-container.tp-acao <> 'Del' NO-LOCK, ~
                                   FIRST ITEM WHERE                                   ITEM.it-codigo = tt-it-container.it-comprado OUTER-JOIN                             BY tt-it-container.it-comprado                             BY tt-it-container.ref-comprada.
&Scoped-define TABLES-IN-QUERY-br-ped-item tt-it-container ITEM
&Scoped-define FIRST-TABLE-IN-QUERY-br-ped-item tt-it-container
&Scoped-define SECOND-TABLE-IN-QUERY-br-ped-item ITEM


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-br-ped-item}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS txt-preco bt-suspende br-ped-item bt-param ~
RECT-7 RECT-2 RECT-3 rt-button 
&Scoped-Define DISPLAYED-OBJECTS txt-preco fi-it-codigo fi-cod-refer ~
fi-qt-pedida fi-perc-dsp-venda fi-preco-90-real fi-preco-90-dolar ~
fi-preco-real fi-preco-dolar fi-total 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-1 bt-inc bt-mod bt-del 
&Scoped-define List-4 fi-it-codigo fi-cod-refer fi-qt-pedida ~
fi-perc-dsp-venda fi-preco-90-real fi-preco-90-dolar bt-conf bt-can 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-cadsim AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU mi-arquivo 
       MENU-ITEM mi-primeiro    LABEL "&Primeiro"      ACCELERATOR "CTRL-HOME"
       MENU-ITEM mi-anterior    LABEL "An&terior"      ACCELERATOR "CTRL-CURSOR-LEFT"
       MENU-ITEM mi-proximo     LABEL "Pr&¢ximo"       ACCELERATOR "CTRL-CURSOR-RIGHT"
       MENU-ITEM mi-ultimo      LABEL "&éltimo"        ACCELERATOR "CTRL-END"
       MENU-ITEM mi-va-para     LABEL "&V  para"       ACCELERATOR "CTRL-T"
       MENU-ITEM mi-pesquisa    LABEL "Pes&quisa"      ACCELERATOR "CTRL-F5"
       RULE
       MENU-ITEM mi-incluir     LABEL "&Incluir"       ACCELERATOR "CTRL-INS"
       MENU-ITEM mi-copiar      LABEL "C&opiar"        ACCELERATOR "CTRL-C"
       MENU-ITEM mi-alterar     LABEL "A&lterar"       ACCELERATOR "CTRL-A"
       MENU-ITEM mi-eliminar    LABEL "&Eliminar"      ACCELERATOR "CTRL-DEL"
       RULE
       MENU-ITEM mi-desfazer    LABEL "&Desfazer"      ACCELERATOR "CTRL-U"
       MENU-ITEM mi-cancelar    LABEL "&Cancelar"      ACCELERATOR "CTRL-F4"
       RULE
       MENU-ITEM mi-salvar      LABEL "Sal&var"        ACCELERATOR "CTRL-S"
       RULE
       MENU-ITEM mi-consultas   LABEL "Co&nsultas"     ACCELERATOR "CTRL-L"
       MENU-ITEM mi-imprimir    LABEL "&Relat¢rios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU mi-ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-cadastro MENUBAR
       SUB-MENU  mi-arquivo     LABEL "&Arquivo"      
       SUB-MENU  mi-ajuda       LABEL "A&juda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_p-cadsim AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-navega AS HANDLE NO-UNDO.
DEFINE VARIABLE h_q01pp001 AS HANDLE NO-UNDO.
DEFINE VARIABLE h_v01pp001 AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-can AUTO-END-KEY 
     IMAGE-UP FILE "image/im-can.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-can.bmp":U
     LABEL "bt inclui 2" 
     SIZE 5.57 BY 1.13 TOOLTIP "Cancela modo Manuten‡Æo".

DEFINE BUTTON bt-conf 
     IMAGE-UP FILE "image/im-chck3.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-cq.bmp":U
     LABEL "Button 1" 
     SIZE 5.29 BY 1.13 TOOLTIP "Confirma Altera‡äes".

DEFINE BUTTON bt-del 
     IMAGE-UP FILE "image/im-era.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-era.bmp":U
     LABEL "bt inclui 2" 
     SIZE 5.29 BY 1.13 TOOLTIP "Elimina Item do Container".

DEFINE BUTTON bt-excel 
     LABEL "Importa Itens Excel" 
     SIZE 15 BY 1.13 TOOLTIP "Importa‡Æo dos itens pelo arquivo excel".

DEFINE BUTTON bt-inc 
     IMAGE-UP FILE "image/im-add.bmp":U
     LABEL "Button 3" 
     SIZE 5.43 BY 1.13 TOOLTIP "Cria Itens no Container".

DEFINE BUTTON bt-mod 
     IMAGE-UP FILE "image/im-mod.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-mod.bmp":U
     LABEL "bt inclui 2" 
     SIZE 5.29 BY 1.13 TOOLTIP "Modifica Itens do Container".

DEFINE BUTTON bt-param 
     IMAGE-UP FILE "image/im-fil.bmp":U
     LABEL "Button 1" 
     SIZE 5 BY 1.21.

DEFINE BUTTON bt-suspende 
     IMAGE-UP FILE "image/im-cance.bmp":U
     LABEL "Button 1" 
     SIZE 5 BY 1.21 TOOLTIP "Suspende/Reativa Vendas do Container".

DEFINE BUTTON bt-vld-preco 
     IMAGE-UP FILE "image/im-vendas-tot.bmp":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Valida Pre‡os dos Itens na Tabela PE".

DEFINE VARIABLE fi-cod-refer AS CHARACTER FORMAT "X(256)":U 
     LABEL "Referˆncia" 
     VIEW-AS FILL-IN 
     SIZE 5.29 BY .88 NO-UNDO.

DEFINE VARIABLE fi-it-codigo AS CHARACTER FORMAT "X(256)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88 NO-UNDO.

DEFINE VARIABLE fi-perc-dsp-venda AS DECIMAL FORMAT ">>9.99":U INITIAL 0 
     LABEL "% Venda" 
     VIEW-AS FILL-IN 
     SIZE 6 BY .88 NO-UNDO.

DEFINE VARIABLE fi-preco-90-dolar AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 6.86 BY .88
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-preco-90-real AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 6.86 BY .88
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-preco-dolar AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-preco-real AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-qt-pedida AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     LABEL "Qtd Pedida" 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88 NO-UNDO.

DEFINE VARIABLE fi-total AS DECIMAL FORMAT ">>>,>>9.99":R15 INITIAL 0 
     LABEL "Qt.Total" 
     VIEW-AS FILL-IN 
     SIZE 10.72 BY .88 NO-UNDO.

DEFINE VARIABLE txt-preco AS CHARACTER FORMAT "X(256)":U INITIAL "Pre‡o" 
      VIEW-AS TEXT 
     SIZE 5 BY .67
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 29 BY 8.5
     BGCOLOR 8 .

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 29.29 BY 1.5
     BGCOLOR 8 .

DEFINE RECTANGLE RECT-7
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 29 BY .25.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 95.43 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-ped-item FOR 
      tt-it-container, 
      ITEM SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-ped-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-ped-item w-cadsim _FREEFORM
  QUERY br-ped-item DISPLAY
      tt-it-container.it-comprado    FORMAT "x(8)"                                  WIDTH 8
      item.desc-item                 FORMAT "x(25)"                                 WIDTH 24
      tt-it-container.ref-comprada   FORMAT "x(5)"         COLUMN-LABEL "Ref"       WIDTH 5
      tt-it-container.qt-pedida      FORMAT ">>>,>>9.99"   COLUMN-LABEL "Qt Pedida" WIDTH 10
      tt-it-container.preco-vd-real  FORMAT ">,>>9.99"     COLUMN-LABEL "Pr Real"
      tt-it-container.preco-vd-dolar FORMAT ">,>>9.99"     COLUMN-LABEL "Pr Dolar"
      tt-it-container.perc-dsp-venda
      tt-it-container.qt-vendida     FORMAT "->>>,>>9.99"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 65.57 BY 8.5
         FONT 1
         TITLE "Itens do Container" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     txt-preco AT ROW 14 COL 69.57 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     bt-excel AT ROW 17.75 COL 51.72 WIDGET-ID 2
     bt-suspende AT ROW 1.38 COL 62.86
     bt-inc AT ROW 17.71 COL 68.57
     fi-it-codigo AT ROW 9.25 COL 76.29 COLON-ALIGNED
     fi-cod-refer AT ROW 10.25 COL 76.29 COLON-ALIGNED
     fi-qt-pedida AT ROW 11.25 COL 76.29 COLON-ALIGNED
     fi-perc-dsp-venda AT ROW 12.25 COL 76 COLON-ALIGNED WIDGET-ID 4
     fi-preco-90-real AT ROW 14.79 COL 76 COLON-ALIGNED NO-LABEL
     fi-preco-90-dolar AT ROW 14.79 COL 85 COLON-ALIGNED NO-LABEL WIDGET-ID 26
     fi-preco-real AT ROW 16.04 COL 76 COLON-ALIGNED NO-LABEL WIDGET-ID 14
     fi-preco-dolar AT ROW 16.04 COL 85 COLON-ALIGNED NO-LABEL WIDGET-ID 22
     bt-conf AT ROW 17.71 COL 91
     bt-mod AT ROW 17.71 COL 74
     bt-del AT ROW 17.71 COL 79.29
     bt-can AT ROW 17.71 COL 85.29
     fi-total AT ROW 17.83 COL 38 COLON-ALIGNED
     br-ped-item AT ROW 9 COL 1.43
     bt-param AT ROW 1.33 COL 57.72
     bt-vld-preco AT ROW 1.38 COL 68.72 WIDGET-ID 34
     "90dd" VIEW-AS TEXT
          SIZE 4 BY .54 AT ROW 14.96 COL 72.72 WIDGET-ID 16
     "BASE" VIEW-AS TEXT
          SIZE 4.29 BY .54 AT ROW 16.21 COL 72.72 WIDGET-ID 18
     "Real" VIEW-AS TEXT
          SIZE 5 BY .54 AT ROW 14.08 COL 77.86 WIDGET-ID 28
          FONT 1
     "Dolar" VIEW-AS TEXT
          SIZE 5 BY .54 AT ROW 14.08 COL 86.86 WIDGET-ID 30
          FONT 1
     RECT-7 AT ROW 13.38 COL 68 WIDGET-ID 20
     RECT-2 AT ROW 9 COL 68
     RECT-3 AT ROW 17.5 COL 67.72
     rt-button AT ROW 1.21 COL 1.57
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 96.57 BY 18.17
         FONT 1.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-cadsim
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-cadsim ASSIGN
         HIDDEN             = YES
         TITLE              = "Manuten‡Æo Pedido de Compra"
         HEIGHT             = 18.17
         WIDTH              = 96.57
         MAX-HEIGHT         = 21.13
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 21.13
         VIRTUAL-WIDTH      = 114.29
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU m-cadastro:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-cadsim 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-cadsim.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-cadsim
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-cad
   FRAME-NAME Custom                                                    */
/* BROWSE-TAB br-ped-item fi-total f-cad */
/* SETTINGS FOR BUTTON bt-can IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR BUTTON bt-conf IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR BUTTON bt-del IN FRAME f-cad
   NO-ENABLE 1                                                          */
/* SETTINGS FOR BUTTON bt-excel IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-inc IN FRAME f-cad
   NO-ENABLE 1                                                          */
/* SETTINGS FOR BUTTON bt-mod IN FRAME f-cad
   NO-ENABLE 1                                                          */
/* SETTINGS FOR BUTTON bt-vld-preco IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-cod-refer IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR FILL-IN fi-it-codigo IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR FILL-IN fi-perc-dsp-venda IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR FILL-IN fi-preco-90-dolar IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR FILL-IN fi-preco-90-real IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR FILL-IN fi-preco-dolar IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-preco-real IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-qt-pedida IN FRAME f-cad
   NO-ENABLE 4                                                          */
/* SETTINGS FOR FILL-IN fi-total IN FRAME f-cad
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-cadsim)
THEN w-cadsim:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-ped-item
/* Query rebuild information for BROWSE br-ped-item
     _START_FREEFORM
RUN pi-total.
OPEN QUERY {&self-name} FOR EACH tt-it-container WHERE
                                 tt-it-container.tp-acao <> 'Del' NO-LOCK,
                            FIRST ITEM WHERE
                                  ITEM.it-codigo = tt-it-container.it-comprado OUTER-JOIN
                            BY tt-it-container.it-comprado
                            BY tt-it-container.ref-comprada.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-ped-item */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-cadsim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-cadsim w-cadsim
ON END-ERROR OF w-cadsim /* Manuten‡Æo Pedido de Compra */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-cadsim w-cadsim
ON WINDOW-CLOSE OF w-cadsim /* Manuten‡Æo Pedido de Compra */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-ped-item
&Scoped-define SELF-NAME br-ped-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-ped-item w-cadsim
ON VALUE-CHANGED OF br-ped-item IN FRAME f-cad /* Itens do Container */
DO:
   ASSIGN fi-it-codigo = ''
          fi-cod-refer = ''
          fi-qt-pedida = 0
          fi-preco-90-real = 0
          fi-preco-90-dolar = 0
          fi-preco-real = 0
          fi-preco-dolar = 0
          fi-perc-dsp-venda = 0.

   IF NUM-RESULTS("br-ped-item":U) > 0 THEN DO.
      ASSIGN fi-it-codigo = tt-it-container.it-comprado
             fi-cod-refer = tt-it-container.ref-comprada
             fi-qt-pedida = tt-it-container.qt-pedida
             fi-preco-90-real = tt-it-container.preco-vd-real * de-ind-finan
             fi-preco-90-dolar = tt-it-container.preco-vd-dolar * de-ind-finan
             fi-preco-real = tt-it-container.preco-vd-real
             fi-preco-dolar = tt-it-container.preco-vd-dolar
             fi-perc-dsp-venda = tt-it-container.perc-dsp-venda.
   END.
   DISP fi-it-codigo
        fi-cod-refer
        fi-qt-pedida
        fi-preco-90-real 
        fi-preco-90-dolar
        fi-preco-real
        fi-preco-dolar
        fi-perc-dsp-venda
        WITH FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-can
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-can w-cadsim
ON CHOOSE OF bt-can IN FRAME f-cad /* bt inclui 2 */
DO:
   DISABLE {&list-4} WITH FRAME {&FRAME-NAME}.
   ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-can:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

   APPLY 'value-changed' TO br-ped-item.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-conf
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-conf w-cadsim
ON CHOOSE OF bt-conf IN FRAME f-cad /* Button 1 */
DO:
    RUN pi-busca-container IN h_v01pp001 (OUTPUT i-nr-container).
    
    FIND pp-it-container WHERE 
         pp-it-container.nr-container = i-nr-container  AND
         pp-it-container.it-comprado  = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}  AND
         pp-it-container.ref-comprada = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME} 
         NO-LOCK NO-ERROR.
    IF AVAIL pp-it-container THEN DO:
       IF pp-it-container.qt-vendida  > (pp-it-container.qt-pedida * pp-it-container.perc-dsp-venda) THEN DO:
          MESSAGE "Quantidade Disp. Venda (" (pp-it-container.qt-pedida * pp-it-container.perc-dsp-venda) ")"  SKIP 
                  "Quantidade Vendida (" pp-it-container.qt-vendida ")" SKIP 
                  "Favor modificar os pedidos de venda antes."
              VIEW-AS ALERT-BOX INFO BUTTONS OK.
          APPLY 'entry' TO fi-qt-pedida IN  FRAME {&FRAME-NAME}.
          RETURN NO-APPLY.
       END.
    END.

    FIND tt-it-container WHERE
         tt-it-container.it-comprado = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME} AND
         tt-it-container.ref-comprada = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME}
         NO-ERROR.

    IF NOT AVAIL tt-it-container THEN DO.
       CREATE tt-it-container.
       ASSIGN tt-it-container.it-comprado = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}
              tt-it-container.ref-comprada = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME}
              tt-it-container.tp-acao = 'Inc'
              tt-it-container.cod-refer = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME}.
    END.
    ASSIGN tt-it-container.qt-pedida = INPUT FRAME {&FRAME-NAME} fi-qt-pedida
           tt-it-container.preco-vd-real = INPUT FRAME {&FRAME-NAME} fi-preco-real
           tt-it-container.preco-vd-dolar = INPUT FRAME {&FRAME-NAME} fi-preco-dolar
           tt-it-container.perc-dsp-venda = INPUT FRAME {&FRAME-NAME} fi-perc-dsp-venda
           tt-it-container.tp-acao = IF tt-it-container.tp-acao = ''
                                     THEN 'Mod' ELSE tt-it-container.tp-acao.

    IF tt-it-container.tp-acao = 'inc' THEN
       ASSIGN l-new = YES.

    IF FRAME {&FRAME-NAME} fi-preco-90-real ENTERED OR 
       FRAME {&FRAME-NAME} fi-preco-90-dolar ENTERED THEN DO.
       FOR EACH tt-it-container WHERE
                tt-it-container.it-comprado = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}
                SHARE-LOCK.
           ASSIGN tt-it-container.preco-vd-real = INPUT FRAME {&FRAME-NAME} fi-preco-real
                  tt-it-container.preco-vd-dolar = INPUT FRAME {&FRAME-NAME} fi-preco-dolar
                  tt-it-container.tp-acao = IF tt-it-container.tp-acao = ''
                                            THEN 'Mod' ELSE tt-it-container.tp-acao.
       END.
    END.

    {&OPEN-QUERY-br-ped-item}

    DISABLE {&list-4} WITH FRAME {&FRAME-NAME}.
    ASSIGN bt-inc:SENSITIVE IN FRAME  {&FRAME-NAME} = YES
           bt-mod:SENSITIVE IN FRAME  {&FRAME-NAME} = YES
           bt-del:SENSITIVE IN FRAME  {&FRAME-NAME} = YES
           bt-can:SENSITIVE IN FRAME  {&FRAME-NAME} = NO
           bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
   
    IF l-new THEN DO.
       APPLY 'entry' TO bt-inc.
       RETURN NO-APPLY.
    END.
    ELSE DO.
       APPLY 'entry' TO fi-qt-pedida.
       RETURN NO-APPLY.
    END.
    RUN piSincrRefItem .
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-conf w-cadsim
ON LEAVE OF bt-conf IN FRAME f-cad /* Button 1 */
DO:
  IF l-new THEN DO.
     APPLY 'entry' TO bt-inc.
     RETURN NO-APPLY.
  END.
  ELSE DO.
     APPLY 'entry' TO fi-qt-pedida.
     RETURN NO-APPLY.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-del
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-del w-cadsim
ON CHOOSE OF bt-del IN FRAME f-cad /* bt inclui 2 */
DO:
  RUN pi-busca-container IN h_v01pp001 (OUTPUT i-nr-container).
  
  FIND FIRST  pp-ped-item WHERE
              pp-ped-item.nr-container = i-nr-container AND
              pp-ped-item.it-codigo    = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME} AND
              pp-ped-item.cod-refer    = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME} NO-LOCK NO-ERROR.
  IF AVAIL pp-ped-item THEN DO:
     MESSAGE "Item " pp-ped-item.it-codigo " x referˆncia " pp-ped-item.cod-refer " possui pedidos de venda." SKIP
             "Exclua primeiro os Pedidos de venda!"
             VIEW-AS ALERT-BOX INFO BUTTONS OK.
     RETURN NO-APPLY. 
  END.

  // Por Toninho em 08/02/2019
  ASSIGN de-qt-vend = 0.
  FOR EACH ped-venda-ext WHERE
           ped-venda-ext.nr-container = i-nr-container NO-LOCK.
      FIND ped-venda WHERE
           ped-venda.nr-pedido = ped-venda-ext.nr-pedido NO-LOCK NO-ERROR.

      IF ped-venda.cod-sit-ped = 6 THEN NEXT.

      FOR EACH ped-item OF ped-venda WHERE
               ped-item.cod-sit-item <> 6 AND
               ped-item.it-codigo = tt-it-container.it-codigo AND
               ped-item.cod-refer = tt-it-container.cod-refer NO-LOCK.
          ASSIGN de-qt-vend = de-qt-vend + ped-item.qt-pedida.
      END.
  END.
  IF de-qt-vend > 0 THEN DO:
     MESSAGE "Eistem Pedidos de Venda para esse Item/Referˆncia..." SKIP
             "Elimina‡Æo nÆo Permitida..."
             VIEW-AS ALERT-BOX ERROR BUTTONS OK.
     RETURN NO-APPLY. 
  END.


  IF br-ped-item:NUM-SELECTED-ROWS > 0 THEN DO ON ERROR UNDO, RETURN NO-APPLY:
     GET CURRENT br-ped-item.

     ASSIGN tt-it-container.tp-acao = "Del".
     IF br-ped-item:DELETE-CURRENT-ROW() IN FRAME {&FRAME-NAME} THEN.

     ASSIGN r-row-table = ROWID(tt-it-container).
  END.

  ASSIGN fi-it-codigo = ''
         fi-cod-refer = ''
         fi-qt-pedida = 0
         fi-preco-real = 0
         fi-preco-dolar = 0
         fi-perc-dsp-venda = 0.

  IF NUM-RESULTS("br-ped-item":U) = 0 THEN 
     ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO 
            bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

  DISP fi-it-codigo
       fi-cod-refer
       fi-qt-pedida
       fi-preco-real 
       fi-preco-dolar
       fi-perc-dsp-venda
       WITH FRAME {&FRAME-NAME}.

  {&OPEN-QUERY-br-ped-item}
  br-ped-item:QUERY:REPOSITION-TO-ROWID(r-row-table).
  APPLY "VALUE-CHANGED" TO br-ped-item.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel w-cadsim
ON CHOOSE OF bt-excel IN FRAME f-cad /* Importa Itens Excel */
DO:
  SYSTEM-DIALOG GET-FILE c-arq-conv
         FILTERS "*.xls" "*.xls",
                 "*.*" "*.*"
         DEFAULT-EXTENSION "xls"
         INITIAL-DIR "c:\desktop" 
         MUST-EXIST
         USE-FILENAME
         UPDATE l-ok.

  IF l-ok = YES THEN
     RUN pi-load-excel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-inc
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-inc w-cadsim
ON CHOOSE OF bt-inc IN FRAME f-cad /* Button 3 */
DO:
   ENABLE {&list-4} WITH FRAME {&FRAME-NAME}.
   ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-can:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = YES.

   IF fi-perc-dsp-venda = 0 THEN
      ASSIGN fi-perc-dsp-venda:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "100".

   APPLY 'entry' TO fi-it-codigo.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-inc w-cadsim
ON RETURN OF bt-inc IN FRAME f-cad /* Button 3 */
DO:
  APPLY 'choose' TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-mod
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-mod w-cadsim
ON CHOOSE OF bt-mod IN FRAME f-cad /* bt inclui 2 */
DO:
   ENABLE {&list-4} WITH FRAME {&FRAME-NAME}.
   ASSIGN fi-it-codigo:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          fi-cod-refer:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

   ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-excel:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-can:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = YES.

   APPLY 'entry' TO fi-qt-pedida.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-param
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-param w-cadsim
ON CHOOSE OF bt-param IN FRAME f-cad /* Button 1 */
DO:
   RUN esp/espp003a.p.
   RUN adm-open-query-cases IN h_q01pp001.
   RUN pi-primeiro IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-suspende
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-suspende w-cadsim
ON CHOOSE OF bt-suspende IN FRAME f-cad /* Button 1 */
DO:
   FIND CURRENT pp-container NO-ERROR.
   CASE pp-container.situacao. 
       WHEN 1 THEN DO.
           ASSIGN pp-container.situacao = 2.
       END.
       WHEN 2 THEN DO.
           ASSIGN pp-container.situacao = 1.
       END.
   END CASE.
   RUN pi-change-image IN h_v01pp001.
   RUN pi-enable-buttons.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vld-preco
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vld-preco w-cadsim
ON CHOOSE OF bt-vld-preco IN FRAME f-cad
DO:
   RUN esp/espp001a.p (INPUT pp-container.nr-container).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-refer
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer w-cadsim
ON LEAVE OF fi-cod-refer IN FRAME f-cad /* Referˆncia */
DO:
    ASSIGN fi-qt-pedida:SCREEN-VALUE = '0'
           fi-preco-real:SCREEN-VALUE = '0'
           fi-preco-dolar:SCREEN-VALUE = '0'
           fi-perc-dsp-venda:SCREEN-VALUE = '0'.
    FIND referencia
        WHERE referencia.cod-refer = SELF:SCREEN-VALUE 
        NO-LOCK NO-ERROR.
    IF NOT AVAIL referencia THEN DO:
       MESSAGE 'Referˆncia nÆo encontrada. Necess rio o cadastro no programa CD0415'
           VIEW-AS ALERT-BOX INFO BUTTONS OK.
       RETURN NO-APPLY.
    END.

    FIND b-tt-it-container WHERE
         b-tt-it-container.it-comprado = fi-it-codigo:SCREEN-VALUE AND
         b-tt-it-container.ref-comprada = SELF:SCREEN-VALUE
         NO-LOCK NO-ERROR.
    IF AVAIL b-tt-it-container THEN
       ASSIGN fi-qt-pedida:SCREEN-VALUE = STRING(b-tt-it-container.qt-pedida)   
              fi-preco-real:SCREEN-VALUE = STRING(b-tt-it-container.preco-vd-real)   
              fi-preco-dolar:SCREEN-VALUE = STRING(b-tt-it-container.preco-vd-dolar)   
              fi-perc-dsp-venda:SCREEN-VALUE = STRING(b-tt-it-container.perc-dsp-venda).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer w-cadsim
ON RETURN OF fi-cod-refer IN FRAME f-cad /* Referˆncia */
DO:
  APPLY 'TAB' TO SELF.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-it-codigo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo w-cadsim
ON LEAVE OF fi-it-codigo IN FRAME f-cad /* Item */
DO:
    /*
  IF l-new-item <> fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME} THEN
     ASSIGN fi-preco:SCREEN-VALUE IN FRAME {&FRAME-NAME} = " ".
  ELSE
    ASSIGN fi-preco:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(l-new-preco).

    
  ASSIGN l-new-item = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}.
  FIND FIRST b-ped-item WHERE
             b-ped-item.it-codigo = l-new-item NO-LOCK NO-ERROR.

  IF AVAIL b-ped-item THEN
     ASSIGN fi-preco:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(b-ped-item.vl-preuni).
  ELSE
     ASSIGN fi-preco:SCREEN-VALUE IN FRAME {&FRAME-NAME} = " ".  */
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-it-codigo w-cadsim
ON RETURN OF fi-it-codigo IN FRAME f-cad /* Item */
DO:
  APPLY 'TAB' TO SELF.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-perc-dsp-venda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-perc-dsp-venda w-cadsim
ON LEAVE OF fi-perc-dsp-venda IN FRAME f-cad /* % Venda */
DO:
    /*ASSIGN l-new-preco = INPUT FRAME {&FRAME-NAME} fi-preco .*/
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-perc-dsp-venda w-cadsim
ON RETURN OF fi-perc-dsp-venda IN FRAME f-cad /* % Venda */
DO:
   APPLY 'choose' TO bt-conf.
   APPLY 'choose' TO bt-inc.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-preco-90-dolar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-90-dolar w-cadsim
ON LEAVE OF fi-preco-90-dolar IN FRAME f-cad
DO:
    ASSIGN fi-preco-dolar:SCREEN-VALUE = STRING(SELF:INPUT-VALUE / de-ind-finan).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-90-dolar w-cadsim
ON RETURN OF fi-preco-90-dolar IN FRAME f-cad
DO:
    APPLY 'TAB' TO SELF.
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-preco-90-real
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-90-real w-cadsim
ON LEAVE OF fi-preco-90-real IN FRAME f-cad
DO:
    ASSIGN fi-preco-real:SCREEN-VALUE = STRING(SELF:INPUT-VALUE / de-ind-finan).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-90-real w-cadsim
ON RETURN OF fi-preco-90-real IN FRAME f-cad
DO:
    APPLY 'TAB' TO SELF.
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-preco-dolar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-dolar w-cadsim
ON RETURN OF fi-preco-dolar IN FRAME f-cad
DO:
    APPLY 'TAB' TO SELF.
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-preco-real
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco-real w-cadsim
ON RETURN OF fi-preco-real IN FRAME f-cad
DO:
    APPLY 'TAB' TO SELF.
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-qt-pedida
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-qt-pedida w-cadsim
ON LEAVE OF fi-qt-pedida IN FRAME f-cad /* Qtd Pedida */
DO:
  /*ASSIGN nova-qte = INPUT FRAME {&FRAME-NAME} fi-qt-pedida.*/
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-qt-pedida w-cadsim
ON RETURN OF fi-qt-pedida IN FRAME f-cad /* Qtd Pedida */
DO:
  APPLY 'TAB' TO SELF.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-alterar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-alterar w-cadsim
ON CHOOSE OF MENU-ITEM mi-alterar /* Alterar */
DO:
  RUN pi-alterar IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-anterior
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-anterior w-cadsim
ON CHOOSE OF MENU-ITEM mi-anterior /* Anterior */
DO:
  RUN pi-anterior IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-arquivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-arquivo w-cadsim
ON MENU-DROP OF MENU mi-arquivo /* Arquivo */
DO:
  run pi-disable-menu.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-cancelar w-cadsim
ON CHOOSE OF MENU-ITEM mi-cancelar /* Cancelar */
DO:
  RUN pi-cancelar IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-cadsim
ON CHOOSE OF MENU-ITEM mi-consultas /* Consultas */
DO:
  RUN pi-consulta IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-cadsim
ON CHOOSE OF MENU-ITEM mi-conteudo /* Conteudo */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  RUN pi-ajuda IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-copiar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-copiar w-cadsim
ON CHOOSE OF MENU-ITEM mi-copiar /* Copiar */
DO:
  RUN pi-copiar IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-desfazer
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-desfazer w-cadsim
ON CHOOSE OF MENU-ITEM mi-desfazer /* Desfazer */
DO:
  RUN pi-desfazer IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-eliminar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-eliminar w-cadsim
ON CHOOSE OF MENU-ITEM mi-eliminar /* Eliminar */
DO:
  RUN pi-eliminar IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-cadsim
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relat¢rios */
DO:
  RUN pi-imprimir IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-incluir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-incluir w-cadsim
ON CHOOSE OF MENU-ITEM mi-incluir /* Incluir */
DO:
  RUN pi-incluir IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-pesquisa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-pesquisa w-cadsim
ON CHOOSE OF MENU-ITEM mi-pesquisa /* Pesquisa */
DO:
  RUN pi-pesquisa IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-primeiro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-primeiro w-cadsim
ON CHOOSE OF MENU-ITEM mi-primeiro /* Primeiro */
DO:
  RUN pi-primeiro IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-proximo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-proximo w-cadsim
ON CHOOSE OF MENU-ITEM mi-proximo /* Pr¢ximo */
DO:
  RUN pi-proximo IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-cadsim
ON CHOOSE OF MENU-ITEM mi-sair /* Sair */
DO:
  RUN pi-sair IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-salvar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-salvar w-cadsim
ON CHOOSE OF MENU-ITEM mi-salvar /* Salvar */
DO:
  RUN pi-salvar IN h_p-cadsim.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-cadsim
ON CHOOSE OF MENU-ITEM mi-sobre /* Sobre... */
DO:
  {include/sobre.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-ultimo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-ultimo w-cadsim
ON CHOOSE OF MENU-ITEM mi-ultimo /* éltimo */
DO:
  RUN pi-ultimo IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-va-para
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-va-para w-cadsim
ON CHOOSE OF MENU-ITEM mi-va-para /* V  para */
DO:
  RUN pi-vapara IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-cadsim 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-cadsim  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE adm-current-page  AS INTEGER NO-UNDO.

  RUN get-attribute IN THIS-PROCEDURE ('Current-Page':U).
  ASSIGN adm-current-page = INTEGER(RETURN-VALUE).

  CASE adm-current-page: 

    WHEN 0 THEN DO:
       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-navega.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 0,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-navega ).
       RUN set-position IN h_p-navega ( 1.33 , 2.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 24.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-cadsim.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 0,
                     SmartPanelType = Update,
                     AddFunction = One-Record':U ,
             OUTPUT h_p-cadsim ).
       RUN set-position IN h_p-cadsim ( 1.33 , 27.29 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 28.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-exihel.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 0,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-exihel ).
       RUN set-position IN h_p-exihel ( 1.33 , 80.43 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esvwr/v01pp001.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Layout = ':U ,
             OUTPUT h_v01pp001 ).
       RUN set-position IN h_v01pp001 ( 2.71 , 1.00 ) NO-ERROR.
       /* Size in UIB:  ( 6.04 , 96.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esqry/q01pp001.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'ProgPesquisa = eszoom\z01pp001.w,
                     ProgVaPara = esgo\g01pp001.w,
                     ProgIncMod = ,
                     Implantar = no':U ,
             OUTPUT h_q01pp001 ).
       RUN set-position IN h_q01pp001 ( 1.33 , 75.43 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 4.86 ) */

       /* Links to SmartPanelCadastro h_p-cadsim. */
       RUN add-link IN adm-broker-hdl ( h_p-cadsim , 'State':U , THIS-PROCEDURE ).

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-cadsim , 'State':U , h_p-exihel ).

       /* Links to SmartViewer h_v01pp001. */
       RUN add-link IN adm-broker-hdl ( h_p-cadsim , 'TableIO':U , h_v01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_q01pp001 , 'Record':U , h_v01pp001 ).

       /* Links to SmartQuery h_q01pp001. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , h_q01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'Navigation':U , h_q01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'State':U , h_q01pp001 ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-navega ,
             bt-suspende:HANDLE IN FRAME f-cad , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-cadsim ,
             h_p-navega , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             h_p-cadsim , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_v01pp001 ,
             h_p-exihel , 'AFTER':U ).
    END. /* Page 0 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-cadsim  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-cadsim  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-cadsim)
  THEN DELETE WIDGET w-cadsim.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-cadsim  _DEFAULT-ENABLE
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
  DISPLAY txt-preco fi-it-codigo fi-cod-refer fi-qt-pedida fi-perc-dsp-venda 
          fi-preco-90-real fi-preco-90-dolar fi-preco-real fi-preco-dolar 
          fi-total 
      WITH FRAME f-cad IN WINDOW w-cadsim.
  ENABLE txt-preco bt-suspende br-ped-item bt-param RECT-7 RECT-2 RECT-3 
         rt-button 
      WITH FRAME f-cad IN WINDOW w-cadsim.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-cadsim.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-cadsim 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-cadsim 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-cadsim 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  {include/win-size.i}

  run pi-before-initialize.
  {utp/ut9000.i "espp001" "2.04.00.001"}

  RUN set-attribute-list IN h_q01pp001
      (INPUT "Reposition-Peding=YES":U).

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  ASSIGN txt-preco:FONT = 6.


  ASSIGN de-ind-finan = 1.
  FIND FIRST tab-finan WHERE 
             tab-finan.dt-ini-val <= TODAY AND 
             tab-finan.dt-fim-val >= TODAY NO-LOCK NO-ERROR.

  /*
  DO i-ct = 1 TO EXTENT(tab-finan.tab-dia-fin).
     IF tab-finan.tab-dia-fin[i-ct] >= i-prazo-medio THEN DO.
        ASSIGN l-ok = YES.
        LEAVE. 
     END.
  END.
  IF l-ok THEN
     ASSIGN de-ind-finan = tab-finan.tab-ind-fin[i-ct].
  */
   FIND FIRST tab-finan-indice OF tab-finan WHERE 
              tab-finan-indice.tab-dia-fin >= i-prazo-medio NO-LOCK NO-ERROR.
   IF AVAIL tab-finan-indice THEN
      ASSIGN de-ind-finan = tab-finan-indice.tab-ind-fin.

  IF gr-pp-container <> ? THEN DO.
     RUN pi-reposiciona-query IN h_q01pp001 (INPUT gr-pp-container).
        RUN pi-disable-all IN h_p-navega.
        bt-param:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
        bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
        RUN pi-alterar IN h_p-cadsim.
  END.
  ELSE DO.
     IF i-sit-container = 9 THEN DO.  /* vai incluir direto */
        RUN pi-incluir IN h_p-cadsim.
        bt-param:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
        bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
        
     END.
     ELSE DO.
        RUN pi-after-initialize.
        APPLY 'choose' TO bt-param.
    
        RUN pi-ultimo IN h_p-navega.
     END.
  END.
  
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-enable-buttons w-cadsim 
PROCEDURE pi-enable-buttons :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    RUN enable-copia IN h_p-cadsim (INPUT NO).

    ASSIGN bt-vld-preco:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
    bt-vld-preco:LOAD-IMAGE("image/ii-vendas-tot.gif") IN FRAME {&FRAME-NAME}.
    CASE pp-container.situacao:
        WHEN 1 THEN DO.   // Aberto
             RUN enable-modifica IN h_p-cadsim (INPUT YES).
             bt-suspende:LOAD-IMAGE("image/im-cance.bmp") IN FRAME {&FRAME-NAME}.
             bt-suspende:TOOLTIP = 'Suspende Container para Venda'.
             ASSIGN bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
        END.
        WHEN 2 THEN DO.   // Suspenso
             bt-suspende:LOAD-IMAGE("image/im-grava.bmp").
             bt-suspende:TOOLTIP = 'Reativa Container para Venda'.
        END.
        WHEN 3 THEN DO.   // Fechado
             ASSIGN bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

             ASSIGN bt-vld-preco:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
             bt-vld-preco:LOAD-IMAGE("image/im-vendas-tot.gif") IN FRAME {&FRAME-NAME}.
        END.
    END CASE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grava-itens w-cadsim 
PROCEDURE pi-grava-itens :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER p-row-container AS ROWID.
    
    FIND pp-container WHERE 
         ROWID(pp-container) = p-row-container NO-LOCK NO-ERROR.

    FOR EACH tt-it-container WHERE 
             tt-it-container.tp-acao <> '' .

        CASE tt-it-container.tp-acao.
            WHEN 'Inc' THEN DO.
                FIND pp-it-container WHERE
                     pp-it-container.nr-container = pp-container.nr-container AND
                     pp-it-container.it-comprado  = tt-it-container.it-comprado AND
                     pp-it-container.ref-comprada = tt-it-container.ref-comprada
                     NO-ERROR.
                IF NOT AVAIL pp-it-container THEN DO.
                    CREATE pp-it-container.
                    ASSIGN pp-it-container.nr-container   = pp-container.nr-container
                           pp-it-container.it-comprado    = tt-it-container.it-comprado
                           pp-it-container.ref-comprada   = tt-it-container.ref-comprada
                           pp-it-container.preco-venda    = tt-it-container.preco-venda
                           pp-it-container.preco-vd-real  = tt-it-container.preco-vd-real
                           pp-it-container.preco-vd-dolar = tt-it-container.preco-vd-dolar
                           pp-it-container.mo-codigo      = tt-it-container.mo-codigo
                           pp-it-container.qt-pedida      = tt-it-container.qt-pedida
                           pp-it-container.perc-dsp-venda = tt-it-container.perc-dsp-venda.
    
                    FIND ITEM WHERE
                         ITEM.it-codigo = tt-it-container.it-comprado NO-LOCK NO-ERROR.
                    IF AVAIL ITEM THEN DO.
                       ASSIGN pp-it-container.it-codigo = tt-it-container.it-comprado
                              pp-it-container.cod-refer = tt-it-container.ref-comprada
                              pp-it-container.desc-item = item.desc-item.
                    END.

                    CREATE controle_preco.
                    ASSIGN controle_preco.nr_container = pp-container.nr-container
                           controle_preco.cod_controle_preco = NEXT-VALUE(seq_controle_preco)
                           controle_preco.tp_preco = 2
                           controle_preco.dt_inicial = TODAY           
                           controle_preco.it_codigo = tt-it-container.it-comprado           
                           controle_preco.cod_refer = tt-it-container.cod-refer           
                           controle_preco.dt_hr_criacao = NOW
                           controle_preco.cod_usuario_criacao = c-seg-usuario
                           controle_preco.dt_final = 12.31.9999  .

                    ASSIGN controle_preco.vl_real = tt-it-container.preco-vd-real
                           controle_preco.vl_dolar = tt-it-container.preco-vd-dolar.
                END.
                ELSE DO:
                    MESSAGE "J  existe o item " + tt-it-container.it-comprado + " de refer: " + tt-it-container.ref-comprada
                        VIEW-AS ALERT-BOX ERROR BUTTONS OK.
                END.
            END.
            WHEN 'Mod' THEN DO.
                FIND pp-it-container WHERE
                     pp-it-container.nr-container = pp-container.nr-container AND
                     pp-it-container.it-comprado  = tt-it-container.it-comprado AND
                     pp-it-container.ref-comprada = tt-it-container.ref-comprada
                     NO-ERROR.
                IF AVAIL pp-it-container THEN DO.
                   ASSIGN pp-it-container.preco-venda = tt-it-container.preco-venda
                          pp-it-container.preco-vd-real  = tt-it-container.preco-vd-real
                          pp-it-container.preco-vd-dolar = tt-it-container.preco-vd-dolar
                          pp-it-container.mo-codigo   = tt-it-container.mo-codigo
                          pp-it-container.qt-pedida   = tt-it-container.qt-pedida
                          pp-it-container.perc-dsp-venda = tt-it-container.perc-dsp-venda.
   
                   FIND ITEM WHERE
                        ITEM.it-codigo = tt-it-container.it-comprado NO-LOCK NO-ERROR.
                   IF AVAIL ITEM THEN
                      ASSIGN pp-it-container.it-codigo = tt-it-container.it-comprado
                             pp-it-container.cod-refer = tt-it-container.cod-refer
                             pp-it-container.desc-item = item.desc-item.

                   FIND FIRST controle_preco WHERE
                              controle_preco.nr_container = pp-container.nr-container AND
                              controle_preco.it_codigo    = tt-it-container.it-comprado AND
                              controle_preco.cod_refer    = tt-it-container.cod-refer AND
                              controle_preco.dt_final     = ? 
                              SHARE-LOCK NO-ERROR.
                   IF AVAIL controle_preco THEN
                      ASSIGN controle_preco.dt_final = TODAY               
                             controle_preco.cod_usuario_alteracao = c-seg-usuario       
                             controle_preco.dt_hr_alteracao = NOW.

                   CREATE controle_preco.
                   ASSIGN controle_preco.nr_container = pp-container.nr-container
                          controle_preco.cod_controle_preco = NEXT-VALUE(seq_controle_preco)
                          controle_preco.tp_preco     = 2
                          controle_preco.dt_inicial   = TODAY           
                          controle_preco.it_codigo    = tt-it-container.it-comprado           
                          controle_preco.cod_refer    = tt-it-container.cod-refer           
                          controle_preco.cod_usuario_criacao = c-seg-usuario
                          controle_preco.dt_hr_criacao = NOW
                          controle_preco.dt_final = 12.31.9999    .

                   ASSIGN controle_preco.vl_real = tt-it-container.preco-vd-real
                          controle_preco.vl_dolar = tt-it-container.preco-vd-dolar.
                END.
            END.
            WHEN 'Del' THEN DO.
                FIND FIRST pp-it-container WHERE
                           pp-it-container.nr-container = pp-container.nr-container AND
                           pp-it-container.it-comprado  = tt-it-container.it-comprado AND
                           pp-it-container.ref-comprada = tt-it-container.ref-comprada
                           NO-ERROR.

                IF AVAIL pp-it-container THEN
                   DELETE pp-it-container.

                FOR EACH controle_preco WHERE
                         controle_preco.nr_container = pp-container.nr-container AND
                         controle_preco.it_codigo    = tt-it-container.it-comprado AND
                         controle_preco.cod_refer    = tt-it-container.cod-refer SHARE-LOCK.
                    DELETE controle_preco.
                END.
            END.
        END CASE.
    END.

    {&OPEN-QUERY-br-ped-item}

    DISABLE {&list-4} WITH FRAME {&FRAME-NAME}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-load-excel w-cadsim 
PROCEDURE pi-load-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF var chWorksheet AS COM-HANDLE NO-UNDO.
DEF VAR i-Lin       AS INT.
DEF VAR c-comando   AS CHAR.

DEF VAR de-valor-cel   AS DECIMAL NO-UNDO.
DEF VAR de-tot-vlr-cel AS DECIMAL NO-UNDO.
DEF VAR c-controle     AS CHAR NO-UNDO.
DEF VAR i-it-codigo    AS INTEGER NO-UNDO.
DEF VAR c-cod-refer    AS CHAR NO-UNDO.
DEF VAR l-item         AS LOGICAL INITIAL YES.
DEF VAR c-cod-emit     AS CHAR.
DEF VAR c-pais         AS CHAR.
DEF VAR i-cod-fornec   AS INTEGER NO-UNDO.
    
    
DEF VAR i-cont AS INTEGER NO-UNDO.
DEF VAR i-ccont AS INTEGER NO-UNDO.

/*
MESSAGE c-arq-conv
    VIEW-AS ALERT-BOX INFO BUTTONS OK.
*/
bt-param:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = NO.


FOR EACH tt-pack-list NO-LOCK.
    DELETE tt-pack-list.
END.

ASSIGN de-valor-cel = 0
       i-cont = 0
       i-ccont = 0.

RUN pi-busca-container IN h_v01pp001 (OUTPUT i-nr-container).


/* Inicializa»’o da Planilha */
CREATE "Excel.Application" chExcelApp NO-ERROR.
IF chExcelApp <> ? THEN /* Cria a Planilha */
   ASSIGN chExcelApp:SheetsInNewWorkbook = 1 /* Nõ PLANILHAS A SEREM CRIADAS */
          chExcelApp:VISIBLE = FALSE  /* A Planilha n’o Ficarÿ Visivel */
          /*chWorkbook         = chExcelApp:Workbooks:OPEN("T:\janete\Lojinha\venda_loja_funcionario.xls") */
          chWorkbook         = chExcelApp:Workbooks:OPEN(c-arq-conv)
          chWorksheet        = chExcelapp:Sheets:ITEM(1).
ELSE DO:
   MESSAGE "O Aplicativo EXCEL n’o foi encontrado. N’o foi poss­vel executar o programa."
       VIEW-AS ALERT-BOX INFO BUTTONS OK.
   RETURN.
END.

/* Atualiza a Temp-Table */
chWorkbook:Worksheets(1):activate.
ASSIGN i-Lin = 10.
ASSIGN i-cod-fornec =  INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE).
REPEAT:
       
       IF l-item = YES THEN DO.
          ASSIGN i-Lin = i-Lin + 9.
          ASSIGN i-it-codigo = INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE)
                 c-cod-refer = chWorksheet:range("B" + STRING(i-Lin + 2)):VALUE.
            /*   MESSAGE i-cod-fornec
        VIEW-AS ALERT-BOX INFO BUTTONS OK.  */ 
          IF chWorksheet:range("B" + STRING(i-Lin)):VALUE = ? THEN LEAVE.
          FIND tt-pack-list WHERE 
               tt-pack-list.it-codigo = STRING(i-it-codigo) AND
               tt-pack-list.cod-refer = STRING(c-cod-refer) NO-LOCK NO-ERROR.
          IF NOT AVAIL tt-pack-list THEN DO.
             /* MESSAGE i-it-codigo
                 VIEW-AS ALERT-BOX INFO BUTTONS OK. */
             CREATE tt-pack-list.
             ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                    tt-pack-list.cod-refer = STRING(c-cod-refer)
                    de-valor-cel = 0
                    i-cont = i-cont + 1.
          END.

          ASSIGN l-item = NO.
          ASSIGN i-Lin = i-Lin + 3.
       END.
       ELSE DO.
          
            /*   MESSAGE i-Lin
                       chWorksheet:range("B" + STRING(i-Lin)):VALUE
                       chWorksheet:range("D" + STRING(i-Lin)):VALUE
                       chWorksheet:range("F" + STRING(i-Lin)):VALUE
                       chWorksheet:range("H" + STRING(i-Lin)):VALUE
                       chWorksheet:range("J" + STRING(i-Lin)):VALUE
                  VIEW-AS ALERT-BOX INFO BUTTONS OK.   */


            
            IF chWorksheet:range("A" + STRING(i-Lin)):VALUE <> "TOTAL" AND
               chWorksheet:range("A" + STRING(i-Lin)):VALUE <> "TOTAL GERAL" THEN DO.

            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("B" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("D" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("D" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("F" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("F" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("H" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("H" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("J" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("J" + STRING(i-Lin)):VALUE).
            
            END.
                      /*     MESSAGE de-valor-cel
                                VIEW-AS ALERT-BOX INFO BUTTONS OK.  */
       END.

       ASSIGN c-controle = IF chWorksheet:range("A" + STRING(i-Lin)):VALUE = "?" THEN "0.00" ELSE  chWorksheet:range("A" + STRING(i-Lin)):VALUE.

       IF c-controle = "TOTAL" THEN DO.
          ASSIGN tt-pack-list.quantidade = decimal(de-valor-cel).
          ASSIGN i-Lin = i-Lin + 10.
          ASSIGN de-tot-vlr-cel = de-tot-vlr-cel + de-valor-cel.
          l-item = YES.
        /*   MESSAGE c-controle 
              VIEW-AS ALERT-BOX INFO BUTTONS OK. */

       END.

       IF c-controle = "TOTAL GERAL" THEN DO.
          chExcelApp:DisplayAlerts = FALSE. 
          chWorkBook:CLOSE().
       END.

   ASSIGN i-Lin = i-Lin + 1.
END.

/* Fecha Planilha */
chExcelApp:DisplayAlerts = FALSE. 
chWorkBook:CLOSE().

FOR EACH tt-pack-list NO-LOCK.
    FIND item-fornec WHERE 
         item-fornec.it-codigo = tt-pack-list.it-codigo NO-LOCK NO-ERROR.
    IF AVAIL item-fornec THEN
       ASSIGN i-ccont = i-ccont + 1.
    ELSE DO.
         MESSAGE " Item " + tt-pack-list.it-codigo + " " + tt-pack-list.cod-refer + " nÆo est  cadastrado no sistema !!! "
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
    END.
END.

IF i-cont = i-ccont THEN DO.

    FOR EACH tt-pack-list NO-LOCK.
        DISP tt-pack-list.it-codigo
             tt-pack-list.quantidade. 
    
        FIND item-fornec WHERE 
             item-fornec.it-codigo = tt-pack-list.it-codigo NO-LOCK NO-ERROR.
        IF AVAIL item-fornec THEN DO.
            FIND tt-it-container WHERE 
                 tt-it-container.nr-container = i-nr-container AND
                 tt-it-container.it-comprado = tt-pack-list.it-codigo AND
                 tt-it-container.ref-comprada = tt-pack-list.cod-refer NO-LOCK NO-ERROR.
            IF NOT AVAIL tt-it-container THEN DO.
                
                CREATE tt-it-container.
                ASSIGN tt-it-container.nr-container = i-nr-container
                       tt-it-container.it-codigo =  tt-pack-list.it-codigo
                       tt-it-container.it-comprado = tt-pack-list.it-codigo
                       tt-it-container.qt-recebida = tt-pack-list.quantidade
                       tt-it-container.ref-comprada = tt-pack-list.cod-refer  
                       tt-it-container.qt-pedida    = tt-pack-list.quantidade
                       tt-it-container.preco-venda  = 0.00
                       tt-it-container.preco-vd-real = 0.00
                       tt-it-container.preco-vd-dolar = 0.00
                       tt-it-container.tp-acao = 'Inc'.
            END.
            ELSE DO.
            ASSIGN tt-it-container.qt-recebida = tt-pack-list.quantidade.
            END. 
        END.
    END.
END.
ELSE DO.
MESSAGE " Impossivel a importacÆo do arquivo Excel !!! "
               VIEW-AS ALERT-BOX INFO BUTTONS OK.
END.

RUN pi-fornec IN h_v01pp001 (INPUT i-cod-fornec).

/* MESSAGE de-tot-vlr-cel
    VIEW-AS ALERT-BOX INFO BUTTONS OK. */

ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = NO
       bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
       bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
       bt-can:SENSITIVE IN FRAME {&FRAME-NAME} = YES
       bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = YES.

{&OPEN-QUERY-br-ped-item}

/* 
FOR EACH tt-pack-list.
    DISP tt-pack-list.vlr-compra FORMAT ">>>>>>>9.9999999999999"
         tt-pack-list.vlr-compra > 0
         DEC(STRING(tt-pack-list.vlr-compra)) > 0.
    DISP tt-pack-list 
         WITH SIDE-LABELS 1 COLUMN.
END.
 
 */


/*
FOR EACH tt-pack-list NO-LOCK.
     DISP tt-pack-list.it-codigo
          tt-pack-list.quantidade.
END.
*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-popula-browse w-cadsim 
PROCEDURE pi-popula-browse :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER p-row-container AS ROWID.
    EMPTY TEMP-TABLE tt-it-container.
    FIND pp-container WHERE 
         ROWID(pp-container) = p-row-container NO-LOCK NO-ERROR.

    IF AVAIL pp-container THEN DO.
       RUN pi-enable-buttons.

       FOR EACH pp-it-container OF pp-container.
           CREATE tt-it-container.
           BUFFER-COPY pp-it-container TO tt-it-container.
       END.
    END.

    {&OPEN-QUERY-br-ped-item}
    
    APPLY 'value-changed' TO br-ped-item IN FRAME {&FRAME-NAME}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-replica-perc w-cadsim 
PROCEDURE pi-replica-perc :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER p-perc-venda AS DECIMAL.

    FOR EACH tt-it-container.
        ASSIGN tt-it-container.perc-dsp-venda = p-perc-venda
               tt-it-container.tp-acao = 'Mod' .
    END.

    {&OPEN-QUERY-br-ped-item}
    APPLY 'value-changed' TO br-ped-item IN FRAME {&FRAME-NAME}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-total w-cadsim 
PROCEDURE pi-total :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    ASSIGN fi-total = 0.
    FOR EACH tt-it-container WHERE
             tt-it-container.tp-acao <> "DEL".
        ASSIGN fi-total = fi-total + tt-it-container.qt-pedida.
    END.
    DISP fi-total WITH FRAME {&FRAME-NAME}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-valida-itens w-cadsim 
PROCEDURE pi-valida-itens :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    FIND FIRST tt-it-container NO-LOCK NO-ERROR.
    IF NOT AVAIL tt-it-container THEN
       RETURN 'ADM-ERROR'.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE piSincrRefItem w-cadsim 
PROCEDURE piSincrRefItem :
FIND ref-item
    WHERE ref-item.it-codigo = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}
    AND   ref-item.cod-refer = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME}
    NO-LOCK NO-ERROR.
IF NOT AVAIL ref-item THEN DO:
   CREATE ref-item.
   ASSIGN ref-item.it-codigo = fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          ref-item.cod-refer = fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME}.
END.



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-cadsim  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-it-container"}
  {src/adm/template/snd-list.i "ITEM"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-cadsim 
PROCEDURE state-changed :
/*:T -----------------------------------------------------------
  Purpose:     Manuseia trocas de estado dos SmartObjects
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lAlterar AS LOGICAL     NO-UNDO.
  
  ASSIGN lAlterar =  getEspp001AlterarItens() = '1' .
 /* MESSAGE p-state
      VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
  CASE p-state.
      WHEN 'disable-button' THEN
          ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                 bt-excel:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                 bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

      WHEN 'update-begin' THEN DO.
        
         FIND FIRST tt-it-container NO-ERROR.
         IF AVAIL tt-it-container  THEN
             ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                    bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                    bt-excel:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
         IF lAlterar = NO THEN
         DO:
            DISABLE {&list-1} WITH FRAME {&frame-name}  .
            MESSAGE 'Todas as manuten‡äes de itens devem ser feitas pelo Imaonline'
                VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
         END.
         QUERY br-ped-item:REPOSITION-TO-ROW(1).
      END.

      WHEN 'enable-button' THEN DO.
          ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                 bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                 bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                 bt-can:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                 bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                 bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                 bt-excel:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
          DISABLE {&list-4} WITH FRAME {&FRAME-NAME}.
      END.

      WHEN 'add-record'     THEN DO:
          EMPTY TEMP-TABLE tt-it-container.
          {&OPEN-QUERY-br-ped-item} 
          ASSIGN fi-it-codigo = ''
                 fi-cod-refer = ''
                 fi-qt-pedida = 0
                 fi-preco-real = 0
                 fi-preco-dolar = 0.
          DISP fi-it-codigo fi-cod-refer fi-qt-pedida fi-preco-real fi-preco-dolar
               WITH FRAME {&FRAME-NAME}.
      END.
      WHEN 'endupdate' THEN DO:
          ASSIGN l-acao = YES.
      END.
  END.
  IF gr-pp-container <> ? THEN DO:
     RUN pi-disable-all IN h_p-navega.
         bt-param:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
         bt-suspende:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
     ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = NO
            bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = YES
            bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
            bt-can:SENSITIVE IN FRAME {&FRAME-NAME} = NO
            bt-conf:SENSITIVE IN FRAME {&FRAME-NAME} = NO
            bt-excel:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
     DISABLE {&list-4} WITH FRAME {&FRAME-NAME}.


  END.
  RUN pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

