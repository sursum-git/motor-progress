&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS W-Win 
/*********************************************************************
* Copyright (C) 2000 by Progress Software Corporation. All rights    *
* reserved. Prior versions of this work may contain portions         *
* contributed by participants of Possenet.                           *
*                                                                    *
*********************************************************************/
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
{CLIPBOARD.i "NEW GLOBAL SHARED" }
/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
DEFINE VARIABLE iCont        AS INTEGER     NO-UNDO.
DEFINE VARIABLE h            AS HANDLE      NO-UNDO.
DEFINE VARIABLE cListaBancos AS CHARACTER   NO-UNDO.
DEFINE VARIABLE hProg        AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBrCps       AS HANDLE      NO-UNDO.
DEFINE VARIABLE hQCps        AS HANDLE      NO-UNDO.
DEFINE VARIABLE hSursum90    AS HANDLE      NO-UNDO.
DEFINE VARIABLE cmd          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE complemento  AS CHARACTER    NO-UNDO.
DEFINE VARIABLE lPesquisaCP    AS LOGICAL     NO-UNDO.
{esbo/boMetadados.i}
{util.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME BROWSE-2

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttTabelas

/* Definitions for BROWSE BROWSE-2                                      */
&Scoped-define FIELDS-IN-QUERY-BROWSE-2 ttTabelas.banco ttTabelas.nome ttTabelas.nomeDump ttTabelas.descricao ttTabelas.dtHrAlteracao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BROWSE-2   
&Scoped-define SELF-NAME BROWSE-2
&Scoped-define OPEN-QUERY-BROWSE-2  CASE cbOrdenacao:SCREEN-VALUE IN FRAME f-main:     WHEN '1' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.nome  .     END.     WHEN '2' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.dtHrAlteracao DESC  .     END.     WHEN '3' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.banco BY ttTabelas.nome  .     END.   END CASE.
&Scoped-define TABLES-IN-QUERY-BROWSE-2 ttTabelas
&Scoped-define FIRST-TABLE-IN-QUERY-BROWSE-2 ttTabelas


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-BROWSE-2}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-2 RECT-3 RECT-4 btPesq cbComparacao ~
cbBancos fiDtHr tgTbSys cbordenacao fiTb fidump fiCampo BROWSE-2 rsDetOpcao ~
btAreaTrans btAreaTransf btDados 
&Scoped-Define DISPLAYED-OBJECTS cbComparacao cbBancos fiDtHr tgTbSys ~
cbordenacao fiTb fidump fiCampo rsDetOpcao 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR W-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btAreaTrans 
     LABEL "Copiar Nome Tbs. Sel." 
     SIZE 16.8 BY 1.14 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btAreaTransf 
     LABEL "µrea de Transf." 
     SIZE 16.8 BY 1.14.

DEFINE BUTTON btDados 
     LABEL "Dados" 
     SIZE 13.2 BY 1.14 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btPesq 
     LABEL "Pesquisar" 
     SIZE 13.2 BY 1.14.

DEFINE VARIABLE cbBancos AS CHARACTER FORMAT "X(256)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Todos" 
     DROP-DOWN-LIST
     SIZE 14.4 BY 1 NO-UNDO.

DEFINE VARIABLE cbComparacao AS INTEGER FORMAT "9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Maior Que",1,
                     "Menor Que",2
     DROP-DOWN-LIST
     SIZE 10.8 BY 1 NO-UNDO.

DEFINE VARIABLE cbordenacao AS INTEGER FORMAT ">9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome Tabela",1,
                     "Dt.Hr.Alteraá∆o",2,
                     "Banco + Tabela",3
     DROP-DOWN-LIST
     SIZE 15.4 BY 1 NO-UNDO.

DEFINE VARIABLE fiCampo AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 16.4 BY .81 NO-UNDO.

DEFINE VARIABLE fiDtHr AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     VIEW-AS FILL-IN 
     SIZE 18.8 BY .81 NO-UNDO.

DEFINE VARIABLE fidump AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 11.2 BY .81 NO-UNDO.

DEFINE VARIABLE fiTb AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 19.6 BY .81 NO-UNDO.

DEFINE VARIABLE rsDetOpcao AS INTEGER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Campos", 1,
"÷ndices", 2,
"Tbs.Relacionadas", 3
     SIZE 41.2 BY 1.24 NO-UNDO.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 44 BY 1.76.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 38.6 BY 1.76.

DEFINE RECTANGLE RECT-4
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 55 BY 1.76.

DEFINE VARIABLE tgTbSys AS LOGICAL INITIAL no 
     LABEL "Tabelas Sistema" 
     VIEW-AS TOGGLE-BOX
     SIZE 15 BY .81 NO-UNDO.

DEFINE BUTTON btExecAcaoCp 
     LABEL "Executar" 
     SIZE 8.8 BY 1.14 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btPesqCp 
     LABEL "Pesquisar" 
     SIZE 9.4 BY 1.14 TOOLTIP "Tabelas Relacionadas".

DEFINE VARIABLE cbAcaoCp AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 1 
     LABEL "Aá∆o Campos Selecionados" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Copiar Nome Campo",1,
                     "Copiar Lista do Campo",2
     DROP-DOWN-LIST
     SIZE 24.2 BY 1 NO-UNDO.

DEFINE VARIABLE cbFiltro AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 1 
     LABEL "Filtrar Por" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome Campo",1,
                     "Campos Com Lista",2,
                     "Campos com Extens∆o",3,
                     "Campos com °ndice",4,
                     "Por Tipo",5
     DROP-DOWN-LIST
     SIZE 22 BY 1 NO-UNDO.

DEFINE VARIABLE cbOrdCampos AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 1 
     LABEL "Ordem Campos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome",1,
                     "Ordem",2
     DROP-DOWN-LIST
     SIZE 16 BY 1 NO-UNDO.

DEFINE VARIABLE cbTipoCp AS CHARACTER FORMAT "X(50)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Todos","Character","Integer","Int64","Decimal","Date","DateTime","Logical","Blob","Clob","Raw","Recid" 
     DROP-DOWN-LIST
     SIZE 14.6 BY 1 NO-UNDO.

DEFINE VARIABLE fiNome AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 14.8 BY .81 NO-UNDO.

DEFINE RECTANGLE RECT-5
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 61.8 BY 1.24.

DEFINE RECTANGLE RECT-6
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 54.8 BY 1.19.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY BROWSE-2 FOR 
      ttTabelas SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE BROWSE-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BROWSE-2 W-Win _FREEFORM
  QUERY BROWSE-2 DISPLAY
      ttTabelas.banco       COLUMN-LABEL "Banco"        FORMAT 'x(20)'
ttTabelas.nome        COLUMN-LABEL "Tabela"       FORMAT 'x(50)'
ttTabelas.nomeDump    COLUMN-LABEL "Dump Name"    FORMAT 'x(20)'
ttTabelas.descricao   COLUMN-LABEL "Descriá∆o"    FORMAT 'x(120)'
ttTabelas.dtHrAlteracao COLUMN-LABEL "Dt.Hr.Alteraá∆o"    FORMAT '99/99/9999 hh:mm:ss'
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS MULTIPLE SIZE 145.2 BY 13.24
         FONT 1 ROW-HEIGHT-CHARS .54 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     btPesq AT ROW 1.95 COL 134.8 WIDGET-ID 20
     cbComparacao AT ROW 2.1 COL 67.4 COLON-ALIGNED NO-LABEL WIDGET-ID 26
     cbBancos AT ROW 2.14 COL 1.6 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     fiDtHr AT ROW 2.14 COL 78.2 COLON-ALIGNED NO-LABEL WIDGET-ID 22
     tgTbSys AT ROW 2.14 COL 101.2 WIDGET-ID 30
     cbordenacao AT ROW 2.14 COL 113.6 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     fiTb AT ROW 2.19 COL 16.8 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     fidump AT ROW 2.19 COL 36.8 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     fiCampo AT ROW 2.19 COL 49 COLON-ALIGNED NO-LABEL WIDGET-ID 10
     BROWSE-2 AT ROW 3.52 COL 3 WIDGET-ID 200
     rsDetOpcao AT ROW 17.24 COL 4.8 NO-LABEL WIDGET-ID 58
     btAreaTrans AT ROW 17.24 COL 56.6 WIDGET-ID 44
     btAreaTransf AT ROW 17.24 COL 73.6 WIDGET-ID 50
     btDados AT ROW 17.33 COL 134.8 WIDGET-ID 42
     "Data/Hora Alteraá∆o Estrut. Tabela" VIEW-AS TEXT
          SIZE 24.2 BY .52 AT ROW 1.52 COL 69.8 WIDGET-ID 24
     "Campo" VIEW-AS TEXT
          SIZE 8 BY .52 AT ROW 1.48 COL 51.4 WIDGET-ID 14
     "Dump Name" VIEW-AS TEXT
          SIZE 10.8 BY .52 AT ROW 1.48 COL 39.2 WIDGET-ID 16
     "Tabela" VIEW-AS TEXT
          SIZE 8 BY .52 AT ROW 1.48 COL 19.2 WIDGET-ID 18
     "Ordenaá∆o" VIEW-AS TEXT
          SIZE 11.4 BY .52 AT ROW 1.48 COL 115.6 WIDGET-ID 34
     "Banco" VIEW-AS TEXT
          SIZE 8 BY .52 AT ROW 1.48 COL 4 WIDGET-ID 12
     RECT-2 AT ROW 17 COL 3 WIDGET-ID 46
     RECT-3 AT ROW 17 COL 53 WIDGET-ID 48
     RECT-4 AT ROW 17 COL 94 WIDGET-ID 52
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 148.72 BY 28.29
         FONT 1 WIDGET-ID 100.

DEFINE FRAME frCampos
     btExecAcaoCp AT ROW 9.29 COL 46.4 WIDGET-ID 64
     btPesqCp AT ROW 9.29 COL 108 WIDGET-ID 70
     cbAcaoCp AT ROW 9.38 COL 26.4 COLON-ALIGNED WIDGET-ID 66
     cbFiltro AT ROW 9.43 COL 61.4 COLON-ALIGNED WIDGET-ID 72
     cbOrdCampos AT ROW 9.43 COL 127.4 COLON-ALIGNED WIDGET-ID 62
     cbTipoCp AT ROW 9.48 COL 84 COLON-ALIGNED NO-LABEL WIDGET-ID 74
     fiNome AT ROW 9.52 COL 83.8 COLON-ALIGNED NO-LABEL WIDGET-ID 68
     RECT-5 AT ROW 9.24 COL 56.2 WIDGET-ID 78
     RECT-6 AT ROW 9.29 COL 1.2 WIDGET-ID 80
    WITH 1 DOWN KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 19
         SIZE 146 BY 9.75
         FONT 1 WIDGET-ID 400.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartWindow
   Allow: Basic,Browse,DB-Fields,Query,Smart,Window
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW W-Win ASSIGN
         HIDDEN             = YES
         TITLE              = "Pesquisa Tabelas"
         HEIGHT             = 28.29
         WIDTH              = 148.8
         MAX-HEIGHT         = 42.38
         MAX-WIDTH          = 274.2
         VIRTUAL-HEIGHT     = 42.38
         VIRTUAL-WIDTH      = 274.2
         MAX-BUTTON         = no
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB W-Win 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW W-Win
  VISIBLE,,RUN-PERSISTENT                                               */
/* REPARENT FRAME */
ASSIGN FRAME frCampos:FRAME = FRAME F-Main:HANDLE.

/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
/* BROWSE-TAB BROWSE-2 fiCampo F-Main */
ASSIGN 
       FRAME F-Main:HIDDEN           = TRUE.

ASSIGN 
       BROWSE-2:NUM-LOCKED-COLUMNS IN FRAME F-Main     = 3.

ASSIGN 
       btDados:HIDDEN IN FRAME F-Main           = TRUE.

ASSIGN 
       RECT-4:HIDDEN IN FRAME F-Main           = TRUE.

/* SETTINGS FOR FRAME frCampos
                                                                        */
/* SETTINGS FOR BUTTON btExecAcaoCp IN FRAME frCampos
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON btPesqCp IN FRAME frCampos
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cbAcaoCp IN FRAME frCampos
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cbFiltro IN FRAME frCampos
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cbOrdCampos IN FRAME frCampos
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX cbTipoCp IN FRAME frCampos
   NO-ENABLE                                                            */
ASSIGN 
       cbTipoCp:HIDDEN IN FRAME frCampos           = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(W-Win)
THEN W-Win:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BROWSE-2
/* Query rebuild information for BROWSE BROWSE-2
     _START_FREEFORM

CASE cbOrdenacao:SCREEN-VALUE IN FRAME f-main:
    WHEN '1' THEN DO:
        OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.nome  .
    END.
    WHEN '2' THEN DO:
        OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.dtHrAlteracao DESC  .
    END.
    WHEN '3' THEN DO:
        OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.banco BY ttTabelas.nome  .
    END.


END CASE.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE BROWSE-2 */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON END-ERROR OF W-Win /* Pesquisa Tabelas */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON WINDOW-CLOSE OF W-Win /* Pesquisa Tabelas */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME BROWSE-2
&Scoped-define SELF-NAME BROWSE-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL BROWSE-2 W-Win
ON VALUE-CHANGED OF BROWSE-2 IN FRAME F-Main
DO:
 ASSIGN lPesquisaCP = FALSE.
 IF AVAIL ttTabelas THEN DO:
    CASE rsDetOpcao:SCREEN-VALUE :
       WHEN '1' THEN DO:
          RUN limparTTCampos IN h.
          RUN setBanco IN h(ttTabelas.banco).
          RUN setTabela IN h(ttTabelas.nome).
          RUN getCpsTb IN h.
          RUN getTTCps IN h(OUTPUT TABLE ttCampos).
          //{&open-query-browse-10}
          //hqCps:QUERY-OPEN.  
       END.
    END CASE.


 END.

 RUN atuCampos.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btAreaTrans
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btAreaTrans W-Win
ON CHOOSE OF btAreaTrans IN FRAME F-Main /* Copiar Nome Tbs. Sel. */
DO:
  RUN getDadoBrowseToClipBoard({&browse-name}:HANDLE,'nome',CHR(10)).
  FOR EACH ttClipBoard:
      MESSAGE dthr SKIP
              texto
          VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
  END.
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btAreaTransf
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btAreaTransf W-Win
ON CHOOSE OF btAreaTransf IN FRAME F-Main /* µrea de Transf. */
DO:
  /*IF NOT VALID-HANDLE(hSursum90) THEN DO:
    RUN esp/sursum90.w  PERSISTENT SET hSursum90.
    RUN initializeObject IN hSursum90.

  END.
  ELSE
    RUN viewObject IN hSursum90.   */
  RUN esp/sursum90.w .
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btDados
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btDados W-Win
ON CHOOSE OF btDados IN FRAME F-Main /* Dados */
DO:
  EMPTY TEMP-TABLE ttTabelas.
  RUN limparFiltros IN h.

  IF cbBancos:SCREEN-VALUE <> 'todos' THEN
     RUN setFiltrosTb IN h('banco',cbBancos:SCREEN-VALUE).
  
  IF fiTb:SCREEN-VALUE <> '' THEN
     RUN setFiltrosTb IN h('tabela',fiTb:SCREEN-VALUE).
  
  IF fiDump:SCREEN-VALUE <> '' THEN
     RUN setFiltrosTb IN h('dump_name',fiDump:SCREEN-VALUE).

  IF fiCampo:SCREEN-VALUE <> '' THEN
     RUN setFiltrosTb IN h('campo',fiCampo:SCREEN-VALUE).


  IF fiDtHr:SCREEN-VALUE <> '' THEN DO:
     RUN setFiltrosTb IN h('dt_hr_alteracao',fiDtHr:SCREEN-VALUE ).
     RUN setFiltrosTb IN h('operador_dt_hr',cbComparacao:SCREEN-VALUE ).
  
  END.
  RUN setFiltrosTb IN h('mostrar_tbs_sys',tgTbSys:SCREEN-VALUE ).

  RUN getTbs IN h(OUTPUT TABLE ttTabelas).

  {&open-query-browse-2}

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME frCampos
&Scoped-define SELF-NAME btExecAcaoCp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExecAcaoCp W-Win
ON CHOOSE OF btExecAcaoCp IN FRAME frCampos /* Executar */
DO:
  CASE cbAcaoCp:SCREEN-VALUE IN FRAME frCampos:
      WHEN '1' THEN
        RUN getDadoBrowseToClipBoard(hbrCps,'nome',CHR(10)).
      WHEN '2' THEN
        RUN getDadoBrowseToClipBoard(hBrCps,'lista',CHR(10)).
  END CASE.
  
  
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME F-Main
&Scoped-define SELF-NAME btPesq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btPesq W-Win
ON CHOOSE OF btPesq IN FRAME F-Main /* Pesquisar */
DO:
  ASSIGN lPesquisaCP = FALSE.
  EMPTY TEMP-TABLE ttTabelas.
  RUN limparFiltros IN h.

  IF cbBancos:SCREEN-VALUE <> 'todos' THEN
     RUN setFiltrosTb IN h('banco',cbBancos:SCREEN-VALUE).
  
  IF fiTb:SCREEN-VALUE <> '' THEN
     RUN setFiltrosTb IN h('tabela',fiTb:SCREEN-VALUE).
  
  IF fiDump:SCREEN-VALUE <> '' THEN
     RUN setFiltrosTb IN h('dump_name',fiDump:SCREEN-VALUE).

  IF fiCampo:SCREEN-VALUE <> '' THEN
     RUN setFiltrosTb IN h('campo',fiCampo:SCREEN-VALUE).


  IF fiDtHr:SCREEN-VALUE <> '' THEN DO:
     RUN setFiltrosTb IN h('dt_hr_alteracao',fiDtHr:SCREEN-VALUE ).
     RUN setFiltrosTb IN h('operador_dt_hr',cbComparacao:SCREEN-VALUE ).
  
  END.
  RUN setFiltrosTb IN h('mostrar_tbs_sys',tgTbSys:SCREEN-VALUE ).

  RUN getTbs IN h(OUTPUT TABLE ttTabelas).

  {&open-query-browse-2}
  APPLY 'value-changed' TO BROWSE browse-2.


END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME frCampos
&Scoped-define SELF-NAME btPesqCp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btPesqCp W-Win
ON CHOOSE OF btPesqCp IN FRAME frCampos /* Pesquisar */
DO:
  ASSIGN lPesquisaCP = TRUE.
  RUN atuCampos.
  
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbFiltro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbFiltro W-Win
ON VALUE-CHANGED OF cbFiltro IN FRAME frCampos /* Filtrar Por */
DO:
  RUN tratarFiltrosCp.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbOrdCampos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbOrdCampos W-Win
ON VALUE-CHANGED OF cbOrdCampos IN FRAME frCampos /* Ordem Campos */
DO:
  RUN atuCampos.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME F-Main
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK W-Win 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

RUN tratarFiltrosCp.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects W-Win  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available W-Win  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE atuBrCps W-Win 
PROCEDURE atuBrCps :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER ordem       AS CHARACTER   NO-UNDO.
DEFINE INPUT  PARAMETER tipoFiltro  AS CHARACTER   NO-UNDO.
DEFINE INPUT  PARAMETER complFiltro AS CHARACTER   NO-UNDO.

ASSIGN cmd = "for each ttCampos ".

CASE tipoFiltro:
    WHEN '1' THEN DO: //nome do campo
        IF complFiltro <> '' THEN DO:
           RUN incrValor(INPUT-OUTPUT cmd,
                         " where ttCampos.nome matches '" + complFiltro +  "'",
                         " ").
        END.
        ELSE 
          APPLY 'value-changed' TO BROWSE browse-2.
    END.
    WHEN '2' THEN DO: //campo com lista
        RUN incrValor(INPUT-OUTPUT cmd,
                      " where ttCampos.lista <> '' ",
                      " ").
    END.
    WHEN '3' THEN DO: //campo com extens∆o
        RUN incrValor(INPUT-OUTPUT cmd,
                      " where ttCampos.extensao <> 0 ",
                      " ").
    END.
    WHEN '4' THEN DO: //campo com indice
        RUN incrValor(INPUT-OUTPUT cmd,
                      " where ttCampos.indice <> '' ",
                      " ").
    END.
    WHEN '5' THEN DO: //por tipo
        IF complFiltro <> 'todos' THEN
           RUN incrValor(INPUT-OUTPUT cmd,
                         " where ttCampos.tipo ='" + complFiltro + "'",
                        " ").
        ELSE
          APPLY 'value-changed' TO BROWSE browse-2.

    END.                                                     

END CASE.


CASE ordem:
    WHEN '1' THEN
        RUN incrValor(INPUT-OUTPUT cmd," by nome "," ").
    WHEN '2' THEN
        RUN incrValor(INPUT-OUTPUT cmd," by ordem "," ").
END CASE.

/*MESSAGE 'comando:' cmd SKIP
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/


hqCps:QUERY-PREPARE(cmd).
hqCps:QUERY-OPEN.
IF lPesquisaCP THEN
   RUN habilitarObjCps(TRUE).
ELSE
   RUN habilitarObjCps(hBrCps:query:NUM-RESULTS  > 0).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE atuCampos W-Win 
PROCEDURE atuCampos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
  
------------------------------------------------------------------------------*/

IF cbOrdCampos:SCREEN-VALUE IN FRAME frCampos = '1'  THEN
    ASSIGN complemento = fiNome:SCREEN-VALUE IN FRAME frCampos.  
 ELSE
    IF cbOrdCampos:SCREEN-VALUE IN FRAME frCampos = '5'  THEN
       ASSIGN complemento = cbTipoCp:SCREEN-VALUE IN FRAME frCampos . 
    ELSE 
       ASSIGN complemento = ''.

 RUN atuBrCps(cbOrdCampos:SCREEN-VALUE IN FRAME frCampos,
              cbFiltro:SCREEN-VALUE IN FRAME frCampos,
              complemento  ).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI W-Win  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(W-Win)
  THEN DELETE WIDGET W-Win.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI W-Win  _DEFAULT-ENABLE
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
  DISPLAY cbComparacao cbBancos fiDtHr tgTbSys cbordenacao fiTb fidump fiCampo 
          rsDetOpcao 
      WITH FRAME F-Main IN WINDOW W-Win.
  ENABLE RECT-2 RECT-3 RECT-4 btPesq cbComparacao cbBancos fiDtHr tgTbSys 
         cbordenacao fiTb fidump fiCampo BROWSE-2 rsDetOpcao btAreaTrans 
         btAreaTransf btDados 
      WITH FRAME F-Main IN WINDOW W-Win.
  VIEW FRAME F-Main IN WINDOW W-Win.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  DISPLAY cbAcaoCp cbFiltro cbOrdCampos cbTipoCp fiNome 
      WITH FRAME frCampos IN WINDOW W-Win.
  ENABLE RECT-5 RECT-6 fiNome 
      WITH FRAME frCampos IN WINDOW W-Win.
  {&OPEN-BROWSERS-IN-QUERY-frCampos}
  VIEW W-Win.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE habilitarObjCps W-Win 
PROCEDURE habilitarObjCps :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER lhabilita AS LOGICAL     NO-UNDO.
/*MESSAGE lhabilita
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
*/
ASSIGN cbAcaoCp:SENSITIVE IN FRAME frCampos       = lHabilita
        btExecAcaoCp:SENSITIVE IN FRAME frCampos   = lHabilita
        cbFiltro:SENSITIVE IN FRAME frCampos       = lHabilita 
        cbTipoCp:SENSITIVE IN FRAME frCampos       = lHabilita
        btPesqCp:SENSITIVE IN FRAME frCampos       = lHabilita 
        cbOrdCampos:SENSITIVE IN FRAME frCampos    = lHabilita 
        //btLimparFiltroCP:SENSITIVE IN FRAME frCampos = lHabilita 
        .
 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-create-objects W-Win 
PROCEDURE local-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'create-objects':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  RUN esbo/boMetaDados.p PERSISTENT SET h.
  RUN getBancos IN h(OUTPUT cListaBancos).
  ASSIGN cbBancos:LIST-ITEMS IN FRAME {&FRAME-NAME} = cbBancos:LIST-ITEMS + "," + cListaBancos. 
  
  //criar a query
  CREATE QUERY hqCps.
  hqCps:SET-BUFFERS(BUFFER  ttCampos:HANDLE).
  
  
  CREATE BROWSE hBrCps
  ASSIGN 
    MULTIPLE  = YES
    TITLE     = "Campos"
    FRAME     = FRAME frCampos:HANDLE
    QUERY     = hQCps
   /* X         = 2.43
    Y         = 32*/
    WIDTH     = 141
    DOWN      = 7.75
    VISIBLE   = YES
    READ-ONLY = NO
    SENSITIVE = TRUE 
          ROW = 1.25
           COL = 4
         SEPARATORS = YES .
  //ASSIGN hbrCps:MULTIPLE = YES.

hbrCps:ADD-COLUMNS-FROM(BUFFER ttCampos:HANDLE,"tabela,id" ) .

RUN habilitarObjCps(NO).
   

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit W-Win 
PROCEDURE local-exit :
/* -----------------------------------------------------------
  Purpose:  Starts an "exit" by APPLYing CLOSE event, which starts "destroy".
  Parameters:  <none>
  Notes:    If activated, should APPLY CLOSE, *not* dispatch adm-exit.   
-------------------------------------------------------------*/
   IF VALID-HANDLE(h) THEN
      DELETE PROCEDURE h .
   APPLY "CLOSE":U TO THIS-PROCEDURE.
   
   RETURN.
       
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records W-Win  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "ttTabelas"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed W-Win 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE tratarFiltrosCp W-Win 
PROCEDURE tratarFiltrosCp :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

CASE cbfiltro:SCREEN-VALUE IN FRAME frCampos:

    WHEN '1' THEN DO: //nome campo
        ASSIGN cbTipoCp:VISIBLE IN FRAME frCampos = FALSE 
               fiNome:VISIBLE IN FRAME frCampos  = TRUE .
    END.

    WHEN '5' THEN DO: //nome campo
        ASSIGN cbTipoCp:VISIBLE IN FRAME frCampos = TRUE 
               fiNome:VISIBLE IN FRAME frCampos  = FALSE .
    END.

    OTHERWISE DO:
        ASSIGN cbTipoCp:VISIBLE IN FRAME frCampos = FALSE
               fiNome:VISIBLE IN FRAME frCampos   = FALSE .

    END.

END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

