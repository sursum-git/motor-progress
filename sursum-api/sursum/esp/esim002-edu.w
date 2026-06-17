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
{include/i-prgvrs.i ESIM002 9.99.99.999}
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
DEF BUFFER unid-feder FOR ems2ima.unid-feder.


DEFINE TEMP-TABLE RowErrors NO-UNDO
       FIELD ErrorSequence    AS INTEGER
       FIELD ErrorNumber      AS INTEGER
       FIELD ErrorDescription AS CHARACTER
       FIELD ErrorParameters  AS CHARACTER
       FIELD ErrorType        AS CHARACTER
       FIELD ErrorHelp        AS CHARACTER
       FIELD ErrorSubType     AS CHARACTER.


DEF TEMP-TABLE tt-ped-venda LIKE ped-venda
    FIELD desc-cond-pagto AS CHAR FORMAT "x(50)".

DEF TEMP-TABLE tt-ped-item LIKE ped-item
    FIELD vl-precalc LIKE ped-item.vl-pretab
    FIELD vl-dif AS DEC
    FIELD perc-dif AS DEC FORMAT "->>9.99"
    FIELD vl-premin LIKE ped-item.vl-pretab
    FIELD preco-alterado AS LOG
    INDEX indice1 it-codigo cod-refer.

DEF BUFFER b-tt-ped-item FOR tt-ped-item.

/* Local Variable Definitions ---                                       */
DEF VAR h-bodi159com AS HANDLE.
DEF VAR de-ind-finan AS DEC.
DEF VAR de-tot-prazo AS INT.
DEF VAR i-prazo-medio AS INT.
DEF VAR i-ct AS INT.
DEF VAR de-perc-aceito AS DEC.
DEF VAR c-desc-condpag AS CHAR FORMAT "x(30)".
DEF VAR l-ok AS LOG.

DEF NEW GLOBAL SHARED VAR gr-ped-venda AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR c-seg-usuario AS CHAR NO-UNDO.

DEF VAR c-usu AS CHAR.
DEF VAR c-usu-altern AS CHAR.

DEF VAR c-sit-com AS CHAR.

DEF VAR r-rowid AS ROWID.
DEF VAR q-br-ped AS HANDLE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Digitacao
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME br-itens

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-ped-item tt-ped-venda

/* Definitions for BROWSE br-itens                                      */
&Scoped-define FIELDS-IN-QUERY-br-itens tt-ped-item.it-codigo tt-ped-item.cod-refer tt-ped-item.qt-pedida tt-ped-item.vl-preori tt-ped-item.vl-pretab tt-ped-item.vl-premin tt-ped-item.perc-dif   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-itens   
&Scoped-define SELF-NAME br-itens
&Scoped-define OPEN-QUERY-br-itens RUN pi-totais. OPEN QUERY {&SELF-NAME} FOR EACH tt-ped-item NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-itens tt-ped-item
&Scoped-define FIRST-TABLE-IN-QUERY-br-itens tt-ped-item


/* Definitions for BROWSE br-ped                                        */
&Scoped-define FIELDS-IN-QUERY-br-ped tt-ped-venda.nr-pedcli tt-ped-venda.nome-abrev tt-ped-venda.desc-cond-pag   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-ped   
&Scoped-define SELF-NAME br-ped
&Scoped-define QUERY-STRING-br-ped FOR EACH tt-ped-venda WHERE                                  tt-ped-venda.cod-sit-com = rs-sit-ped NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-ped OPEN QUERY {&SELF-NAME} FOR EACH tt-ped-venda WHERE                                  tt-ped-venda.cod-sit-com = rs-sit-ped NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-ped tt-ped-venda
&Scoped-define FIRST-TABLE-IN-QUERY-br-ped tt-ped-venda


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-br-itens}~
    ~{&OPEN-QUERY-br-ped}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 RECT-2 RECT-11 RECT-40 rs-sit-ped ~
br-ped br-itens FILL-IN-1 bt-mod-premin FILL-IN-2 bt-ok bt-ajuda bt-log ~
bt-desaprova 
&Scoped-Define DISPLAYED-OBJECTS rs-sit-ped fi-repres fi-desc fi-desc-item ~
fi-nr-tbpreco fi-tot-qtd-m FILL-IN-1 fi-vl-premin fi-vlr-total ~
fi-tot-qtd-kg FILL-IN-2 ed-obs ed-narr-aprov 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-digita AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     IMAGE-UP FILE "image/im-hel.bmp":U
     LABEL "Ajuda" 
     SIZE 10 BY 1.21.

DEFINE BUTTON bt-aprova 
     IMAGE-UP FILE "image/imt-aval.bmp":U
     LABEL "Aprovar Pedido" 
     SIZE 35 BY 1.21 TOOLTIP "Aprova Pre‡o do Pedido".

DEFINE BUTTON bt-desaprova 
     IMAGE-UP FILE "image/im-reprova-cred.bmp":U
     LABEL "Reprova" 
     SIZE 36 BY 1.21 TOOLTIP "Desaprova Pre‡o do Pedido".

DEFINE BUTTON bt-detalhe 
     IMAGE-UP FILE "image/img-det.bmp":U
     LABEL "Detalhar Pedido" 
     SIZE 10 BY 1.21 TOOLTIP "Detalhar Pedido".

DEFINE BUTTON bt-log AUTO-GO 
     IMAGE-UP FILE "image/im-log.bmp":U
     LABEL "" 
     SIZE 10 BY 1.21 TOOLTIP "Hist¢rico do Pedido"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-mod-premin 
     IMAGE-UP FILE "image/im-mod.bmp":U
     LABEL "Button 1" 
     SIZE 3.72 BY 1 TOOLTIP "Modifica Pre‡o Minimo".

DEFINE BUTTON bt-ok AUTO-GO 
     IMAGE-UP FILE "image/im-exi.bmp":U
     LABEL "Sair" 
     SIZE 10 BY 1.21.

DEFINE VARIABLE ed-narr-aprov AS CHARACTER 
     VIEW-AS EDITOR SCROLLBAR-VERTICAL
     SIZE 58 BY 3 NO-UNDO.

DEFINE VARIABLE ed-obs AS CHARACTER 
     VIEW-AS EDITOR SCROLLBAR-VERTICAL
     SIZE 56.14 BY 2.79
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-desc AS CHARACTER FORMAT "X(256)":U 
     LABEL "% Desc." 
     VIEW-AS FILL-IN 
     SIZE 5.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-item AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 56 BY .88
     BGCOLOR 15  NO-UNDO.

DEFINE VARIABLE fi-nr-tbpreco AS CHARACTER FORMAT "X(256)":U 
     LABEL "Tab Pre‡o" 
     VIEW-AS FILL-IN 
     SIZE 8.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-repres AS CHARACTER FORMAT "X(256)":U 
     LABEL "Representante" 
     VIEW-AS FILL-IN 
     SIZE 15.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-kg AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tot-qtd-m AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8.43 BY .88 NO-UNDO.

DEFINE VARIABLE fi-vl-premin AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     LABEL "Pre‡o Minimo" 
     VIEW-AS FILL-IN 
     SIZE 8.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-vlr-total AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8.86 BY .88 NO-UNDO.

DEFINE VARIABLE FILL-IN-1 AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 2 BY .5
     BGCOLOR 12  NO-UNDO.

DEFINE VARIABLE FILL-IN-2 AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 2 BY .5
     BGCOLOR 2 FGCOLOR 2  NO-UNDO.

DEFINE VARIABLE rs-sit-ped AS INTEGER INITIAL 1 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "NÆo Avaliados", 1,
"Reprovados", 3
     SIZE 55 BY .79
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 115 BY 1.5
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-11
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 58 BY 3.25.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 115 BY 1.25
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-40
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 57 BY 3.25.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-itens FOR 
      tt-ped-item SCROLLING.

DEFINE QUERY br-ped FOR 
      tt-ped-venda SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-itens
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-itens w-digita _FREEFORM
  QUERY br-itens NO-LOCK DISPLAY
      tt-ped-item.it-codigo FORMAT "x(16)":U       WIDTH 8
      tt-ped-item.cod-refer                        WIDTH 5
      tt-ped-item.qt-pedida FORMAT ">>,>>9.99":U   WIDTH 8
      tt-ped-item.vl-preori FORMAT ">,>>9.99":U    WIDTH 8 COLUMN-LABEL "Preco INF" 
      tt-ped-item.vl-pretab FORMAT ">,>>9.99":U    WIDTH 8 COLUMN-LABEL "Preco TAB"
      tt-ped-item.vl-premin FORMAT ">,>>9.99":U    WIDTH 8 COLUMN-LABEL "Preco MIN"
      tt-ped-item.perc-dif  FORMAT "->>9.99":U     WIDTH 6 COLUMN-LABEL "% DIF"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 58 BY 10
         FONT 1
         TITLE "Itens do Pedido".

DEFINE BROWSE br-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-ped w-digita _FREEFORM
  QUERY br-ped NO-LOCK DISPLAY
      tt-ped-venda.nr-pedcli     WIDTH 6 
     tt-ped-venda.nome-abrev     WIDTH 12
     tt-ped-venda.desc-cond-pag  WIDTH 60 COLUMN-LABEL "Cond Pagto"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 56 BY 10
         FONT 1
         TITLE "Pedidos Pendentes".


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     rs-sit-ped AT ROW 1.25 COL 3 NO-LABEL WIDGET-ID 14
     br-ped AT ROW 2.5 COL 2 WIDGET-ID 200
     br-itens AT ROW 2.5 COL 59 WIDGET-ID 300
     fi-repres AT ROW 12.92 COL 11.14 COLON-ALIGNED WIDGET-ID 28
     fi-desc AT ROW 12.92 COL 44.14 COLON-ALIGNED WIDGET-ID 44
     fi-desc-item AT ROW 13.5 COL 58 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     fi-nr-tbpreco AT ROW 13.92 COL 11.14 COLON-ALIGNED WIDGET-ID 30
     fi-tot-qtd-m AT ROW 13.92 COL 44.14 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     FILL-IN-1 AT ROW 14.5 COL 57.86 COLON-ALIGNED NO-LABEL WIDGET-ID 60
     bt-mod-premin AT ROW 14.63 COL 112.43 WIDGET-ID 52
     fi-vl-premin AT ROW 14.71 COL 101.29 COLON-ALIGNED WIDGET-ID 50
     fi-vlr-total AT ROW 14.92 COL 11.14 COLON-ALIGNED NO-LABEL WIDGET-ID 42
     fi-tot-qtd-kg AT ROW 14.92 COL 44.14 COLON-ALIGNED NO-LABEL WIDGET-ID 38
     FILL-IN-2 AT ROW 15.21 COL 59.86 NO-LABEL WIDGET-ID 62
     ed-obs AT ROW 16.83 COL 1.86 NO-LABEL WIDGET-ID 12
     ed-narr-aprov AT ROW 16.83 COL 59 NO-LABEL WIDGET-ID 22
     bt-ok AT ROW 20 COL 3
     bt-aprova AT ROW 20 COL 13.43 WIDGET-ID 4
     bt-detalhe AT ROW 20 COL 59.29 WIDGET-ID 6
     bt-ajuda AT ROW 20 COL 106.57
     bt-log AT ROW 20.04 COL 49 WIDGET-ID 46
     bt-desaprova AT ROW 20.04 COL 70 WIDGET-ID 10
     "Pre‡o Menor % Aceito" VIEW-AS TEXT
          SIZE 26.57 BY .67 AT ROW 14.42 COL 62.43 WIDGET-ID 64
          BGCOLOR 8 FGCOLOR 12 FONT 6
     "Pre‡o Alterado Ap¢s Aprova‡Æo" VIEW-AS TEXT
          SIZE 26.43 BY .67 AT ROW 15.13 COL 62.57 WIDGET-ID 66
          BGCOLOR 8 FGCOLOR 2 FONT 6
     "Valor Total:" VIEW-AS TEXT
          SIZE 10 BY .46 AT ROW 15.08 COL 3.14 WIDGET-ID 40
          FGCOLOR 1 FONT 6
     "Observa‡äes do Pedido" VIEW-AS TEXT
          SIZE 56 BY .54 AT ROW 16.25 COL 2 WIDGET-ID 26
          FGCOLOR 1 FONT 6
     "Descri‡Æo do Item" VIEW-AS TEXT
          SIZE 18 BY .54 AT ROW 12.96 COL 60.14 WIDGET-ID 56
     "Descri‡Æo Aprova‡Æo de Pre‡o" VIEW-AS TEXT
          SIZE 57.57 BY .54 AT ROW 16.25 COL 59.43 WIDGET-ID 24
          FGCOLOR 1 FONT 6
     "Qtd Total (kg):" VIEW-AS TEXT
          SIZE 12 BY .54 AT ROW 15 COL 33.43 WIDGET-ID 36
          FGCOLOR 1 FONT 6
     "Qtd Total (m):" VIEW-AS TEXT
          SIZE 11.29 BY .75 AT ROW 13.96 COL 34.14 WIDGET-ID 34
          FGCOLOR 1 FONT 6
     RECT-1 AT ROW 19.83 COL 2
     RECT-2 AT ROW 1 COL 2 WIDGET-ID 20
     RECT-11 AT ROW 12.75 COL 59 WIDGET-ID 48
     RECT-40 AT ROW 12.75 COL 1 WIDGET-ID 54
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 116.72 BY 20.54
         FONT 1 WIDGET-ID 100.


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
         TITLE              = "Aprova Pre‡o dos Pedidos - ESIM002"
         HEIGHT             = 20.54
         WIDTH              = 116.72
         MAX-HEIGHT         = 29
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 29
         VIRTUAL-WIDTH      = 146.29
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
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
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
/* BROWSE-TAB br-ped rs-sit-ped F-Main */
/* BROWSE-TAB br-itens br-ped F-Main */
/* SETTINGS FOR BUTTON bt-aprova IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-detalhe IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR EDITOR ed-narr-aprov IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR EDITOR ed-obs IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-desc IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-desc-item IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-nr-tbpreco IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-repres IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-kg IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd-m IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-vl-premin IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-vlr-total IN FRAME F-Main
   NO-ENABLE                                                            */
ASSIGN 
       FILL-IN-1:READ-ONLY IN FRAME F-Main        = TRUE.

/* SETTINGS FOR FILL-IN FILL-IN-2 IN FRAME F-Main
   ALIGN-L                                                              */
ASSIGN 
       FILL-IN-2:READ-ONLY IN FRAME F-Main        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-digita)
THEN w-digita:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-itens
/* Query rebuild information for BROWSE br-itens
     _START_FREEFORM
RUN pi-totais.
OPEN QUERY {&SELF-NAME} FOR EACH tt-ped-item NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Where[1]         = "ems204.ped-item.nome-abrev = ped-venda.nome-abrev
 AND ems204.ped-item.nr-pedcli = ped-venda.nr-pedcli"
     _Query            is OPENED
*/  /* BROWSE br-itens */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-ped
/* Query rebuild information for BROWSE br-ped
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-ped-venda WHERE
                                 tt-ped-venda.cod-sit-com = rs-sit-ped NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Where[1]         = "ems204.ped-venda.cod-sit-ped = 4"
     _Query            is OPENED
*/  /* BROWSE br-ped */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-digita w-digita
ON END-ERROR OF w-digita /* Aprova Pre‡o dos Pedidos - ESIM002 */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-digita w-digita
ON WINDOW-CLOSE OF w-digita /* Aprova Pre‡o dos Pedidos - ESIM002 */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-itens
&Scoped-define SELF-NAME br-itens
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-itens w-digita
ON ROW-DISPLAY OF br-itens IN FRAME F-Main /* Itens do Pedido */
DO:
   IF tt-ped-item.perc-dif > de-perc-aceito THEN DO.
      tt-ped-item.it-codigo:FONT IN BROWSE br-itens = 6.
      tt-ped-item.cod-refer:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.qt-pedida:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.vl-preori:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.vl-pretab:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.perc-dif:FONT IN BROWSE br-itens = 6.  
      tt-ped-item.vl-premin:FONT IN BROWSE br-itens = 6. 

      tt-ped-item.it-codigo:FGCOLOR IN BROWSE br-itens = 12.
      tt-ped-item.cod-refer:FGCOLOR IN BROWSE br-itens = 12. 
      tt-ped-item.qt-pedida:FGCOLOR IN BROWSE br-itens = 12. 
      tt-ped-item.vl-preori:FGCOLOR IN BROWSE br-itens = 12. 
      tt-ped-item.vl-pretab:FGCOLOR IN BROWSE br-itens = 12. 
      tt-ped-item.perc-dif:FGCOLOR IN BROWSE br-itens = 12.  
      tt-ped-item.vl-premin:FGCOLOR IN BROWSE br-itens = 12. 
   END.
   IF tt-ped-item.preco-alterado THEN DO.
      tt-ped-item.it-codigo:FONT IN BROWSE br-itens = 6.
      tt-ped-item.cod-refer:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.qt-pedida:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.vl-preori:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.vl-pretab:FONT IN BROWSE br-itens = 6. 
      tt-ped-item.perc-dif:FONT IN BROWSE br-itens = 6.  
      tt-ped-item.vl-premin:FONT IN BROWSE br-itens = 6. 

      tt-ped-item.it-codigo:FGCOLOR IN BROWSE br-itens = 2.
      tt-ped-item.cod-refer:FGCOLOR IN BROWSE br-itens = 2. 
      tt-ped-item.qt-pedida:FGCOLOR IN BROWSE br-itens = 2. 
      tt-ped-item.vl-preori:FGCOLOR IN BROWSE br-itens = 2. 
      tt-ped-item.vl-pretab:FGCOLOR IN BROWSE br-itens = 2. 
      tt-ped-item.perc-dif:FGCOLOR IN BROWSE br-itens = 2.  
      tt-ped-item.vl-premin:FGCOLOR IN BROWSE br-itens = 2. 
   END.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-itens w-digita
ON VALUE-CHANGED OF br-itens IN FRAME F-Main /* Itens do Pedido */
DO:
   IF AVAIL tt-ped-item THEN DO.
      ASSIGN fi-desc-item:SCREEN-VALUE = ''.
      FIND ITEM WHERE
           ITEM.it-codigo = tt-ped-item.it-codigo NO-LOCK NO-ERROR.
      IF AVAIL ITEM THEN
         ASSIGN fi-desc-item:SCREEN-VALUE = ITEM.desc-item.
    
      ASSIGN fi-vl-premin:SCREEN-VALUE = STRING(tt-ped-item.vl-premin).
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-ped
&Scoped-define SELF-NAME br-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-ped w-digita
ON VALUE-CHANGED OF br-ped IN FRAME F-Main /* Pedidos Pendentes */
DO:
   FOR EACH tt-ped-item.
       DELETE tt-ped-item.
   END.

   ASSIGN ed-obs:SCREEN-VALUE = ''
          ed-narr-aprov:SCREEN-VALUE = ''.

   IF AVAIL tt-ped-venda THEN DO.
      ASSIGN bt-detalhe:SENSITIVE = YES.
     
      ASSIGN fi-repres:SCREEN-VALUE = tt-ped-venda.no-ab-reppri
             fi-desc:SCREEN-VALUE = STRING(INT(tt-ped-venda.val-pct-desconto-total))
             ed-obs:SCREEN-VALUE = tt-ped-venda.observacoes
             ed-narr-aprov:SCREEN-VALUE = REPLACE(tt-ped-venda.desc-lib-preco," ; ",CHR(10)).

      IF tt-ped-venda.cod-estab = '1' THEN
         FIND im-param WHERE
              im-param.cod-param = "PERC_DIF_ACEITA_IMA" NO-LOCK NO-ERROR.
      ELSE
         FIND im-param WHERE
              im-param.cod-param = "PERC_DIF_ACEITA_MED" NO-LOCK NO-ERROR.

      IF AVAIL im-param THEN
         ASSIGN de-perc-aceito = DEC(im-para.val-param).
      
      IF LOOKUP(c-seg-usuario, c-usu) = 0 AND
         LOOKUP(c-seg-usuario, c-usu-altern) = 0  THEN
         ASSIGN bt-aprova:SENSITIVE = NO
                bt-desaprova:SENSITIVE = NO
                ed-narr-aprov:SENSITIVE = NO. 
      ELSE
         ASSIGN bt-aprova:SENSITIVE = YES
                bt-desaprova:SENSITIVE = rs-sit-ped = 1
                ed-narr-aprov:SENSITIVE = YES.
   
      FIND cond-pagto WHERE
           cond-pagto.cod-cond-pag = tt-ped-venda.cod-cond-pag NO-LOCK NO-ERROR.
      
      ASSIGN de-ind-finan = 1.
      IF AVAIL cond-pagto THEN DO.
         IF cond-pagto.nr-tab-finan <> 0 AND
            cond-pagto.nr-ind-finan <> 0 THEN DO.
            FIND tab-finan WHERE
                 tab-finan.nr-tab-finan = cond-pagto.nr-tab-finan NO-LOCK NO-ERROR.
            IF tab-finan.tab-ind-fin[cond-pagto.nr-ind-finan] <> 0 THEN
               ASSIGN de-ind-finan = tab-finan.tab-ind-fin[cond-pagto.nr-ind-finan].
         END.
      END.
      ELSE DO.
         ASSIGN de-tot-prazo = 0
                i-ct = 0.
         FOR EACH cond-ped WHERE
                  cond-ped.nr-pedido = tt-ped-venda.nr-pedido NO-LOCK.
             ASSIGN de-tot-prazo = de-tot-prazo + cond-ped.nr-dias-venc.
             ASSIGN i-ct = i-ct + 1.
         END.
         ASSIGN i-prazo-medio = de-tot-prazo / i-ct.

         FIND FIRST tab-finan WHERE 
                    tab-finan.dt-ini-val <= TODAY AND 
                    tab-finan.dt-fim-val >= TODAY NO-LOCK NO-ERROR.
         
         DO i-ct = 1 TO EXTENT(tab-finan.tab-dia-fin).
            IF tab-finan.tab-dia-fin[i-ct] >= i-prazo-medio THEN
               LEAVE. 
         END.
         IF i-ct > EXTENT(tab-finan.tab-ind-fin) THEN
            ASSIGN i-ct = EXTENT(tab-finan.tab-ind-fin).

         ASSIGN de-ind-finan = tab-finan.tab-ind-fin[i-ct].
      END.

      IF de-ind-finan = 0 THEN
         ASSIGN de-ind-finan = 1.

      IF tt-ped-venda.cod-estab = '1' THEN DO.
         FIND unid-feder WHERE
              unid-feder.estado = tt-ped-venda.estado NO-LOCK NO-ERROR.

         IF unid-feder.char-2 = 'SUL' OR
            (unid-feder.char-2 = 'SUDESTE' AND unid-feder.estado <> "ES") THEN
            FIND im-param WHERE
                 im-param.cod-param = "tabela_ima12" NO-LOCK NO-ERROR.
         ELSE
            FIND im-param WHERE
                 im-param.cod-param = "tabela_ima07" NO-LOCK NO-ERROR.
      END.
      ELSE
         FIND im-param WHERE
              im-param.cod-param = "tabela_med" NO-LOCK NO-ERROR.
    
      ASSIGN fi-nr-tbpreco:SCREEN-VALUE = im-param.val-param.

      FOR EACH ped-item OF tt-ped-venda WHERE
               ped-item.cod-sit-item = 1 NO-LOCK.
          CREATE tt-ped-item.
          BUFFER-COPY ped-item TO tt-ped-item.
    
          FIND preco-item WHERE
               preco-item.nr-tabpre = im-param.val-param AND
               preco-item.it-codigo = ped-item.it-codigo AND
               preco-item.cod-refer = ped-item.cod-refer
               NO-LOCK NO-ERROR.
          
          ASSIGN tt-ped-item.vl-pretab = 0.
          IF AVAIL preco-item THEN
             ASSIGN tt-ped-item.vl-pretab = preco-item.preco-venda * de-ind-finan.

          ASSIGN tt-ped-item.perc-dif = 100 - (tt-ped-item.vl-preori / tt-ped-item.vl-pretab * 100).

          FIND ped-item-ext WHERE 
               ped-item-ext.cod-estabel  = tt-ped-venda.cod-estabel AND
               ped-item-ext.nome-abrev   = tt-ped-venda.nome-abrev  AND
               ped-item-ext.nr-pedcli    = ped-item.nr-pedcli   AND
               ped-item-ext.nr-sequencia = ped-item.nr-sequencia 
               NO-LOCK NO-ERROR.

          ASSIGN tt-ped-item.preco-alterado = ped-item-ext.preco-alterado.
          IF ped-item-ext.vl-pre-min <> 0 THEN
             ASSIGN tt-ped-item.vl-premin = IF ped-item-ext.vl-pre-min > tt-ped-item.vl-pretab 
                                            THEN tt-ped-item.vl-pretab - (tt-ped-item.vl-pretab * de-perc-aceito / 100)
                                            ELSE ped-item-ext.vl-pre-min.
          ELSE
             ASSIGN tt-ped-item.vl-premin = tt-ped-item.vl-pretab - (tt-ped-item.vl-pretab * de-perc-aceito / 100).
      END.
   END.

   {&OPEN-QUERY-br-itens}
   APPLY 'VALUE-CHANGED' TO br-itens.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-digita
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  MESSAGE 'Programa para Aprovar Pre‡o de Itens dos Pedidos' SKIP
          'que foram Informados abaixo da Tabela de Pre‡o'
      VIEW-AS ALERT-BOX INFO BUTTONS OK.
  RETURN "OK".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-aprova
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-aprova w-digita
ON CHOOSE OF bt-aprova IN FRAME F-Main /* Aprovar Pedido */
DO:
   ASSIGN INPUT FRAME {&FRAME-NAME} ed-narr-aprov.

   IF ed-narr-aprov <> "" THEN DO.
      ASSIGN ed-narr-aprov = REPLACE(ed-narr-aprov,CHR(10)," ; ").
      ASSIGN ed-narr-aprov = "PRE€O APROVADO POR " + c-seg-usuario + " ; " + ed-narr-aprov. 
   END.
   ELSE
      ASSIGN ed-narr-aprov = "PRE€O APROVADO POR " + c-seg-usuario. 

   FIND ped-venda WHERE
        ped-venda.cod-estabel = tt-ped-venda.cod-estabel AND
        ped-venda.nome-abrev = tt-ped-venda.nome-abrev AND
        ped-venda.nr-pedcli = tt-ped-venda.nr-pedcli SHARE-LOCK NO-ERROR.

   ASSIGN ped-venda.cod-sit-com = 2
          ped-venda.log-ped-bonif-pendente = NO
          ped-venda.desc-lib-preco = ed-narr-aprov.

   RUN esapi/cria-log-pedvenda.p (INPUT ped-venda.nr-pedcli,
                                  INPUT ped-venda.nome-abrev,
                                  INPUT "PRE€O APROVADO POR " + c-seg-usuario,
                                  INPUT YES).

   FIND CURRENT ped-venda NO-LOCK NO-ERROR.

   ASSIGN tt-ped-venda.cod-sit-com = 2.

   FOR EACH ped-item OF ped-venda NO-LOCK.
       FIND ped-item-ext WHERE
            ped-item-ext.cod-estabel = ped-venda.cod-estabel AND
            ped-item-ext.nr-pedcli = ped-item.nr-pedcli AND
            ped-item-ext.nome-abrev = ped-item.nome-abrev AND
            ped-item-ext.nr-sequencia = ped-item.nr-sequencia SHARE-LOCK NO-ERROR.
       ASSIGN ped-item-ext.preco-alterado = NO.
       FIND ped-item-ext WHERE
            ped-item-ext.cod-estabel = ped-venda.cod-estabel AND
            ped-item-ext.nr-pedcli = ped-item.nr-pedcli AND
            ped-item-ext.nome-abrev = ped-item.nome-abrev AND
            ped-item-ext.nr-sequencia = ped-item.nr-sequencia NO-LOCK NO-ERROR.
   END.

   ASSIGN r-rowid = ?.
   q-br-ped:GET-NEXT() NO-ERROR.
   IF NOT AVAIL tt-ped-venda THEN DO.
      q-br-ped:GET-LAST() NO-ERROR.
      q-br-ped:GET-PREV() NO-ERROR.
   END.
   IF AVAIL tt-ped-venda THEN
      ASSIGN r-rowid = ROWID(tt-ped-venda).

   {&OPEN-QUERY-br-ped}

   IF r-rowid <> ? THEN
      q-br-ped:REPOSITION-TO-ROWID(r-rowid).

   APPLY 'VALUE-CHANGED' TO br-ped.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-desaprova
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-desaprova w-digita
ON CHOOSE OF bt-desaprova IN FRAME F-Main /* Reprova */
DO:
   ASSIGN INPUT FRAME {&FRAME-NAME} ed-narr-aprov.

   IF ed-narr-aprov <> "" THEN DO.
      ASSIGN ed-narr-aprov = REPLACE(ed-narr-aprov,CHR(10)," ; ").
      ASSIGN ed-narr-aprov = "PRE€O REPROVADO POR " + c-seg-usuario + " ; " + ed-narr-aprov. 
   END.
   ELSE
      ASSIGN ed-narr-aprov = "PRE€O REPROVADO POR " + c-seg-usuario. 

   FIND ped-venda WHERE
        ped-venda.cod-estabel = tt-ped-venda.cod-estabel AND
        ped-venda.nome-abrev = tt-ped-venda.nome-abrev AND
        ped-venda.nr-pedcli = tt-ped-venda.nr-pedcli SHARE-LOCK NO-ERROR.

   ASSIGN ped-venda.cod-sit-com = 3
          ped-venda.desc-lib-preco = ed-narr-aprov.
   
   FIND CURRENT ped-venda NO-LOCK NO-ERROR.

   FOR EACH ped-item OF ped-venda NO-LOCK.
       FIND ped-item-ext WHERE
            ped-item-ext.cod-estabel = ped-venda.cod-estabel AND
            ped-item-ext.nr-pedcli = ped-item.nr-pedcli AND
            ped-item-ext.nome-abrev = ped-item.nome-abrev AND
            ped-item-ext.nr-sequencia = ped-item.nr-sequencia SHARE-LOCK NO-ERROR.
       ASSIGN ped-item-ext.preco-alterado = NO.
       FIND ped-item-ext WHERE
            ped-item-ext.cod-estabel = ped-venda.cod-estabel AND
            ped-item-ext.nr-pedcli = ped-item.nr-pedcli AND
            ped-item-ext.nome-abrev = ped-item.nome-abrev AND
            ped-item-ext.nr-sequencia = ped-item.nr-sequencia NO-LOCK NO-ERROR.
   END.

   RUN esapi/cria-log-pedvenda.p (INPUT ped-venda.nr-pedcli,
                                  INPUT ped-venda.nome-abrev,
                                  INPUT "PRE€O REPROVADO POR " + c-seg-usuario,
                                  INPUT YES).

   ASSIGN tt-ped-venda.cod-sit-com = 3.

   ASSIGN r-rowid = ?.
   q-br-ped:GET-NEXT() NO-ERROR.
   IF NOT AVAIL tt-ped-venda THEN DO.
      q-br-ped:GET-LAST() NO-ERROR.
      q-br-ped:GET-PREV() NO-ERROR.
   END.
   IF AVAIL tt-ped-venda THEN
      ASSIGN r-rowid = ROWID(tt-ped-venda).

   {&OPEN-QUERY-br-ped}

   IF r-rowid <> ? THEN
      q-br-ped:REPOSITION-TO-ROWID(r-rowid).

   APPLY 'VALUE-CHANGED' TO br-ped.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-detalhe
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-detalhe w-digita
ON CHOOSE OF bt-detalhe IN FRAME F-Main /* Detalhar Pedido */
DO:
   FIND ped-venda WHERE
        ped-venda.nome-abrev = tt-ped-venda.nome-abrev AND
        ped-venda.nr-pedcli = tt-ped-venda.nr-pedcli NO-LOCK NO-ERROR.
   ASSIGN gr-ped-venda = ROWID(ped-venda).
   RUN pdp/pd1001.p.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-log
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-log w-digita
ON CHOOSE OF bt-log IN FRAME F-Main
DO:
   RUN esp/essp0155b.p (INPUT tt-ped-venda.nr-pedcli).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-mod-premin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-mod-premin w-digita
ON CHOOSE OF bt-mod-premin IN FRAME F-Main /* Button 1 */
DO:
   ASSIGN fi-vl-premin:SENSITIVE = YES.
   APPLY 'ENTRY' TO fi-vl-premin.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-digita
ON CHOOSE OF bt-ok IN FRAME F-Main /* Sair */
DO:
  apply "close":U to this-procedure.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-vl-premin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-vl-premin w-digita
ON LEAVE OF fi-vl-premin IN FRAME F-Main /* Pre‡o Minimo */
DO:
   ASSIGN tt-ped-item.vl-premin = SELF:INPUT-VALUE.
   ASSIGN SELF:SENSITIVE = NO.

   FOR EACH b-tt-ped-item WHERE
            b-tt-ped-item.it-codigo = tt-ped-item.it-codigo SHARE-LOCK.

       ASSIGN b-tt-ped-item.vl-premin = tt-ped-item.vl-premin.

       FIND ped-item-ext WHERE 
            ped-item-ext.cod-estabel = tt-ped-venda.cod-estabel AND
            ped-item-ext.nome-abrev = tt-ped-venda.nome-abrev AND
            ped-item-ext.nr-pedcli = b-tt-ped-item.nr-pedcli AND
            ped-item-ext.nr-sequencia = b-tt-ped-item.nr-sequencia 
            SHARE-LOCK NO-ERROR.

       IF AVAIL ped-item-ext THEN
          ASSIGN ped-item-ext.vl-pre-min = b-tt-ped-item.vl-premin.
   END.

   br-itens:REFRESH().
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-sit-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-sit-ped w-digita
ON VALUE-CHANGED OF rs-sit-ped IN FRAME F-Main
DO: 
   ASSIGN INPUT FRAME {&FRAME-NAME} rs-sit-ped.

   {&OPEN-QUERY-br-ped}

   APPLY 'VALUE-CHANGED' TO br-ped.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-itens
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-digita 


/* ***************************  Main Block  *************************** */

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
  DISPLAY rs-sit-ped fi-repres fi-desc fi-desc-item fi-nr-tbpreco fi-tot-qtd-m 
          FILL-IN-1 fi-vl-premin fi-vlr-total fi-tot-qtd-kg FILL-IN-2 ed-obs 
          ed-narr-aprov 
      WITH FRAME F-Main IN WINDOW w-digita.
  ENABLE RECT-1 RECT-2 RECT-11 RECT-40 rs-sit-ped br-ped br-itens FILL-IN-1 
         bt-mod-premin FILL-IN-2 bt-ok bt-ajuda bt-log bt-desaprova 
      WITH FRAME F-Main IN WINDOW w-digita.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
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

  /*{utp/ut9000.i "esim002" "2.00.04.001"}*/
  
  ASSIGN c-sit-com = '1'.
  RUN pi-popula-ped.

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

   FIND im-param WHERE 
        im-param.cod-param = "APROV_PED" NO-LOCK NO-ERROR.

   IF AVAIL im-param THEN
      ASSIGN c-usu = im-param.val-param.

   FIND im-param WHERE 
        im-param.cod-param = "APROV_ALTERNATIVO" NO-LOCK NO-ERROR.

   IF AVAIL im-param THEN
      ASSIGN c-usu-altern = im-param.val-param.


  ASSIGN q-br-ped = br-ped:QUERY IN FRAME {&FRAME-NAME}.

  APPLY 'value-changed' TO br-ped IN FRAME {&FRAME-NAME}.

  /*{include/i-inifld.i}*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-popula-ped w-digita 
PROCEDURE pi-popula-ped :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

     FOR EACH tt-ped-venda.
         DELETE tt-ped-venda.
     END.

     FOR EACH ped-venda WHERE
              ped-venda.cod-sit-ped = 1 AND
              (ped-venda.cod-sit-com = 1 OR
               ped-venda.cod-sit-com = 3 OR
               ped-venda.log-ped-bonif-pendente) NO-LOCK.

         IF ped-venda.tp-pedido = 'PI' THEN NEXT.
           
         FIND ped-venda-ext WHERE
              ped-venda-ext.cod-estabel = ped-venda.cod-estabel AND
              ped-venda-ext.nr-pedido = ped-venda.nr-pedido NO-LOCK NO-ERROR.
         IF NOT AVAIL ped-venda-ext THEN NEXT.

         IF ped-venda-ext.l-nao-aprovar THEN NEXT.

         IF ped-venda-ext.tp-pedido = "Exporta‡Æo" OR 
            ped-venda-ext.tp-pedido = "Bonifica‡Æo" OR
            ped-venda-ext.tp-pedido = "Doa‡Æo" 
            THEN NEXT.

         IF ped-venda-ext.tp-pedido = "Amostra" OR
            ped-venda-ext.tp-pedido = "Amostra Exporta‡Æo" THEN DO.
            FIND natur-oper WHERE
                 natur-oper.nat-operacao = ped-venda.nat-oper NO-LOCK NO-ERROR.
            IF natur-oper.emite-duplic = NO THEN NEXT.
         END.

         CREATE tt-ped-venda.
         BUFFER-COPY ped-venda TO tt-ped-venda.

         FIND cond-pagto WHERE
              cond-pagto.cod-cond-pag = ped-venda.cod-cond-pag NO-LOCK NO-ERROR.

         IF AVAIL cond-pagto THEN
            ASSIGN tt-ped-venda.desc-cond-pag = cond-pagto.descricao.
         ELSE DO.
            ASSIGN c-desc-condpag = ''.
            FOR EACH cond-ped OF ped-venda NO-LOCK.
                ASSIGN c-desc-condpag = IF c-desc-condpag = ''
                                        THEN "ESP: " + STRING(cond-ped.nr-dias)
                                        ELSE c-desc-condpag + "/" + STRING(cond-ped.nr-dias).
            END.
            ASSIGN tt-ped-venda.desc-cond-pag = c-desc-condpag + " DD".
         END.
     END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-totais w-digita 
PROCEDURE pi-totais :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    ASSIGN fi-tot-qtd-m = 0
           fi-tot-qtd-kg = 0
           fi-vlr-total = 0.
    FOR EACH tt-ped-item.
        FIND ITEM WHERE
             ITEM.it-codigo = tt-ped-item.it-codigo NO-LOCK NO-ERROR.
        IF ITEM.un = 'm' THEN
           ASSIGN fi-tot-qtd-m = fi-tot-qtd-m + tt-ped-item.qt-pedida.
        ELSE
           ASSIGN fi-tot-qtd-kg = fi-tot-qtd-kg + tt-ped-item.qt-pedida.

        ASSIGN fi-vlr-total = fi-vlr-total + (tt-ped-item.qt-pedida * tt-ped-item.vl-preori). 
    END.
    DISP fi-tot-qtd-m
         fi-tot-qtd-kg
         fi-vlr-total
         WITH FRAME {&FRAME-NAME}.
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
  {src/adm/template/snd-list.i "tt-ped-venda"}
  {src/adm/template/snd-list.i "tt-ped-item"}

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

