&ANALYZE-SUSPEND _VERSION-NUMBER AB_v10r12 GUI ADM2
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME wWin
{adecomm/appserv.i}
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS wWin 
/*------------------------------------------------------------------------

  File: 

  Description: from cntnrwin.w - ADM SmartWindow Template

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  History: New V9 Version - January 15, 1998
          
------------------------------------------------------------------------*/
/*          This .W file was created with the Progress AB.              */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.


{src/adm2/widgetprto.i}

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
DEFINE VARIABLE complemento  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lPesquisaCP    AS LOGICAL   NO-UNDO.
{esbo/boMetadados.i}
{util.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

&Scoped-define ADM-SUPPORTED-LINKS Data-Target,Data-Source,Page-Target,Update-Source,Update-Target,Filter-target,Filter-Source

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fMain
&Scoped-define BROWSE-NAME BROWSE-2

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttTabelas

/* Definitions for BROWSE BROWSE-2                                      */
&Scoped-define FIELDS-IN-QUERY-BROWSE-2 ttTabelas.banco ttTabelas.nome ttTabelas.nomeDump ttTabelas.descricao ttTabelas.dtHrAlteracao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BROWSE-2   
&Scoped-define SELF-NAME BROWSE-2
&Scoped-define OPEN-QUERY-BROWSE-2  CASE cbOrdenacao:SCREEN-VALUE IN FRAME fmain :     WHEN '1' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.nome  .     END.     WHEN '2' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.dtHrAlteracao DESC  .     END.     WHEN '3' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.banco BY ttTabelas.nome  .     END.   END CASE.
&Scoped-define TABLES-IN-QUERY-BROWSE-2 ttTabelas
&Scoped-define FIRST-TABLE-IN-QUERY-BROWSE-2 ttTabelas


/* Definitions for FRAME fMain                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-fMain ~
    ~{&OPEN-QUERY-BROWSE-2}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-7 RECT-2 RECT-3 RECT-4 cbComparacao ~
cbBancos fiDtHr fiTb fiCampo btPesq cbordenacao tgTbSys fidump BROWSE-2 ~
rsDetOpcao btAreaTrans btAreaTransf btDados 
&Scoped-Define DISPLAYED-OBJECTS cbComparacao cbBancos fiDtHr fiTb fiCampo ~
cbordenacao tgTbSys fidump rsDetOpcao 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR wWin AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btAreaTrans 
     LABEL "Copiar Nome Tbs. Sel." 
     SIZE 24 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btAreaTransf 
     LABEL "µ¡rea de Transf." 
     SIZE 23.43 BY 1.13.

DEFINE BUTTON btDados 
     LABEL "Dados" 
     SIZE 13.14 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btPesq AUTO-GO 
     LABEL "Pesquisar" 
     SIZE 13.14 BY 1.13.

DEFINE VARIABLE cbBancos AS CHARACTER FORMAT "X(256)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Todos" 
     DROP-DOWN-LIST
     SIZE 19.43 BY 1 NO-UNDO.

DEFINE VARIABLE cbComparacao AS INTEGER FORMAT "9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Maior Que",1,
                     "Menor Que",2
     DROP-DOWN-LIST
     SIZE 15.43 BY 1 NO-UNDO.

DEFINE VARIABLE cbordenacao AS INTEGER FORMAT ">9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome Tabela",1,
                     "Dt.Hr.Alteraá∆o",2,
                     "Banco + Tabela",3
     DROP-DOWN-LIST
     SIZE 26.86 BY 1 NO-UNDO.

DEFINE VARIABLE fiCampo AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 23.14 BY .79 NO-UNDO.

DEFINE VARIABLE fiDtHr AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     VIEW-AS FILL-IN 
     SIZE 21.57 BY .79 NO-UNDO.

DEFINE VARIABLE fidump AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 23.14 BY .79 NO-UNDO.

DEFINE VARIABLE fiTb AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 24.14 BY .79 NO-UNDO.

DEFINE VARIABLE rsDetOpcao AS INTEGER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Campos", 1,
"Õ÷ndices", 2,
"Tbs.Relacionadas", 3
     SIZE 46.14 BY 1.25 NO-UNDO.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 49 BY 1.75.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 50.43 BY 1.75.

DEFINE RECTANGLE RECT-4
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 15.86 BY 1.75.

DEFINE RECTANGLE RECT-7
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 116.86 BY 4.5.

DEFINE VARIABLE tgTbSys AS LOGICAL INITIAL no 
     LABEL "Tabelas Sistema" 
     VIEW-AS TOGGLE-BOX
     SIZE 22.14 BY .79 NO-UNDO.

DEFINE BUTTON btExecAcaoCp 
     LABEL "Executar" 
     SIZE 12 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btPesqCp 
     LABEL "Pesquisar" 
     SIZE 10.86 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE VARIABLE cbAcaoCp AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 1 
     LABEL "Aá∆o Campos Selecionados" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Copiar Nome Campo",1,
                     "Copiar Lista do Campo",2
     DROP-DOWN-LIST
     SIZE 35.14 BY 1 NO-UNDO.

DEFINE VARIABLE cbFiltro AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 1 
     LABEL "Filtrar Por" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome Campo",1,
                     "Campos Com Lista",2,
                     "Campos com Extens∆o",3,
                     "Campos com °ndice",4,
                     "Por Tipo",5
     DROP-DOWN-LIST
     SIZE 28.57 BY 1 NO-UNDO.

DEFINE VARIABLE cbOrdCampos AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 1 
     LABEL "Ordem Campos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome",1,
                     "Ordem",2
     DROP-DOWN-LIST
     SIZE 18.57 BY 1 NO-UNDO.

DEFINE VARIABLE cbTipoCp AS CHARACTER FORMAT "X(50)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Todos","Character","Integer","Int64","Decimal","Date","DateTime","Logical","Blob","Clob","Raw","Recid" 
     DROP-DOWN-LIST
     SIZE 18.57 BY 1 NO-UNDO.

DEFINE VARIABLE fiNome AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 18 BY .79 NO-UNDO.

DEFINE RECTANGLE RECT-5
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 71.14 BY 1.42.

DEFINE RECTANGLE RECT-6
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 114.43 BY 1.29.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY BROWSE-2 FOR 
      ttTabelas SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE BROWSE-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BROWSE-2 wWin _FREEFORM
  QUERY BROWSE-2 DISPLAY
      ttTabelas.banco       COLUMN-LABEL "Banco"        FORMAT 'x(20)'
ttTabelas.nome        COLUMN-LABEL "Tabela"       FORMAT 'x(50)'
ttTabelas.nomeDump    COLUMN-LABEL "Dump Name"    FORMAT 'x(20)'
ttTabelas.descricao   COLUMN-LABEL "Descriá∆o"    FORMAT 'x(120)'
ttTabelas.dtHrAlteracao COLUMN-LABEL "Dt.Hr.Alteraá∆o"    FORMAT '99/99/9999 hh:mm:ss'
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS MULTIPLE SIZE 116.57 BY 6.42
         FONT 1 ROW-HEIGHT-CHARS .54 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fMain
     cbComparacao AT ROW 2.13 COL 73 COLON-ALIGNED NO-LABEL WIDGET-ID 26
     cbBancos AT ROW 2.21 COL 1.57 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     fiDtHr AT ROW 2.21 COL 89.14 COLON-ALIGNED NO-LABEL WIDGET-ID 22
     fiTb AT ROW 2.25 COL 23.57 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     fiCampo AT ROW 2.25 COL 49 COLON-ALIGNED NO-LABEL WIDGET-ID 10
     btPesq AT ROW 3.88 COL 99.72 WIDGET-ID 20
     cbordenacao AT ROW 4 COL 49.14 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     tgTbSys AT ROW 4.04 COL 4.14 WIDGET-ID 30
     fidump AT ROW 4.04 COL 23.86 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     BROWSE-2 AT ROW 6 COL 2.43 WIDGET-ID 200
     rsDetOpcao AT ROW 12.75 COL 4.43 NO-LABEL WIDGET-ID 58
     btAreaTrans AT ROW 12.88 COL 53.57 WIDGET-ID 44
     btAreaTransf AT ROW 12.88 COL 78 WIDGET-ID 50
     btDados AT ROW 12.88 COL 104.57 WIDGET-ID 42
     "Banco Selecionado" VIEW-AS TEXT
          SIZE 19 BY .5 AT ROW 1.5 COL 4 WIDGET-ID 12
     "Data/Hora Alteraá∆o Estrut.Tabela" VIEW-AS TEXT
          SIZE 34.43 BY .5 AT ROW 1.58 COL 75.14 WIDGET-ID 24
     "Ordenaá∆o" VIEW-AS TEXT
          SIZE 11.43 BY .5 AT ROW 3.38 COL 51.43 WIDGET-ID 62
     "Tabela" VIEW-AS TEXT
          SIZE 8 BY .5 AT ROW 1.5 COL 25.57 WIDGET-ID 18
     "Campo" VIEW-AS TEXT
          SIZE 8 BY .5 AT ROW 1.5 COL 51.57 WIDGET-ID 14
     "Dump Name" VIEW-AS TEXT
          SIZE 17.57 BY .5 AT ROW 3.33 COL 25.86 WIDGET-ID 16
     RECT-7 AT ROW 1.25 COL 2.14 WIDGET-ID 34
     RECT-2 AT ROW 12.5 COL 2.57 WIDGET-ID 46
     RECT-3 AT ROW 12.5 COL 52.57 WIDGET-ID 48
     RECT-4 AT ROW 12.5 COL 103.43 WIDGET-ID 52
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 118.8 BY 24.86
         FONT 1 WIDGET-ID 100.

DEFINE FRAME frCampos
     btPesqCp AT ROW 1.33 COL 61.43 WIDGET-ID 70
     fiNome AT ROW 1.46 COL 40.57 COLON-ALIGNED NO-LABEL WIDGET-ID 68
     cbFiltro AT ROW 1.5 COL 10.86 COLON-ALIGNED WIDGET-ID 72
     cbTipoCp AT ROW 1.5 COL 40.29 COLON-ALIGNED NO-LABEL WIDGET-ID 74
     cbOrdCampos AT ROW 1.5 COL 92.86 COLON-ALIGNED WIDGET-ID 62
     btExecAcaoCp AT ROW 10.63 COL 58.43 WIDGET-ID 64
     cbAcaoCp AT ROW 10.75 COL 20.43 COLON-ALIGNED WIDGET-ID 66
     RECT-5 AT ROW 1.25 COL 2 WIDGET-ID 78
     RECT-6 AT ROW 10.58 COL 1.57 WIDGET-ID 80
    WITH 1 DOWN KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 2.6 ROW 14.38
         SIZE 116.4 BY 11.14
         FONT 1 WIDGET-ID 400.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartWindow
   Allow: Basic,Browse,DB-Fields,Query,Smart,Window
   Container Links: Data-Target,Data-Source,Page-Target,Update-Source,Update-Target,Filter-target,Filter-Source
   Other Settings: COMPILE APPSERVER
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW wWin ASSIGN
         HIDDEN             = YES
         TITLE              = "Sursum - Adm.Tabelas"
         HEIGHT             = 24.88
         WIDTH              = 118.86
         MAX-HEIGHT         = 33.58
         MAX-WIDTH          = 273.14
         VIRTUAL-HEIGHT     = 33.58
         VIRTUAL-WIDTH      = 273.14
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB wWin 
/* ************************* Included-Libraries *********************** */

{src/adm2/containr.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW wWin
  VISIBLE,,RUN-PERSISTENT                                               */
/* REPARENT FRAME */
ASSIGN FRAME frCampos:FRAME = FRAME fMain:HANDLE.

/* SETTINGS FOR FRAME fMain
   FRAME-NAME                                                           */
/* BROWSE-TAB BROWSE-2 fidump fMain */
ASSIGN 
       BROWSE-2:NUM-LOCKED-COLUMNS IN FRAME fMain     = 3.

ASSIGN 
       btDados:HIDDEN IN FRAME fMain           = TRUE.

ASSIGN 
       RECT-4:HIDDEN IN FRAME fMain           = TRUE.

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

/* SETTINGS FOR FILL-IN fiNome IN FRAME frCampos
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWin)
THEN wWin:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BROWSE-2
/* Query rebuild information for BROWSE BROWSE-2
     _START_FREEFORM

CASE cbOrdenacao:SCREEN-VALUE IN FRAME fmain :
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

&Scoped-define SELF-NAME wWin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWin wWin
ON END-ERROR OF wWin /* Sursum - Adm.Tabelas */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL wWin wWin
ON WINDOW-CLOSE OF wWin /* Sursum - Adm.Tabelas */
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
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL BROWSE-2 wWin
ON VALUE-CHANGED OF BROWSE-2 IN FRAME fMain
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
 RUN tratarFiltrosCp.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btAreaTrans
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btAreaTrans wWin
ON CHOOSE OF btAreaTrans IN FRAME fMain /* Copiar Nome Tbs. Sel. */
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
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btAreaTransf wWin
ON CHOOSE OF btAreaTransf IN FRAME fMain /* µ¡rea de Transf. */
DO:
  IF NOT VALID-HANDLE(hSursum90) THEN DO:
    RUN db/sursum90novo.w  PERSISTENT SET hSursum90.
    RUN initializeObject IN hSursum90.

  END.
  ELSE
    RUN viewObject IN hSursum90.   
  
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btDados
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btDados wWin
ON CHOOSE OF btDados IN FRAME fMain /* Dados */
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
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExecAcaoCp wWin
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


&Scoped-define FRAME-NAME fMain
&Scoped-define SELF-NAME btPesq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btPesq wWin
ON CHOOSE OF btPesq IN FRAME fMain /* Pesquisar */
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
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btPesqCp wWin
ON CHOOSE OF btPesqCp IN FRAME frCampos /* Pesquisar */
DO:
  ASSIGN lPesquisaCP = TRUE.
  RUN atuCampos.
  
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbFiltro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbFiltro wWin
ON VALUE-CHANGED OF cbFiltro IN FRAME frCampos /* Filtrar Por */
DO:
  RUN tratarFiltrosCp.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbOrdCampos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbOrdCampos wWin
ON VALUE-CHANGED OF cbOrdCampos IN FRAME frCampos /* Ordem Campos */
DO:
  RUN atuCampos.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME fMain
&Scoped-define SELF-NAME fiCampo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiCampo wWin
ON RETURN OF fiCampo IN FRAME fMain
DO:
  APPLY 'choose' TO btPesq .
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiDtHr
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiDtHr wWin
ON RETURN OF fiDtHr IN FRAME fMain
DO:
  APPLY 'choose' TO btPesq .
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fidump
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fidump wWin
ON RETURN OF fidump IN FRAME fMain
DO:
  APPLY 'choose' TO btPesq .
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiTb
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiTb wWin
ON RETURN OF fiTb IN FRAME fMain
DO:
  APPLY 'choose' TO btPesq.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK wWin 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm2/windowmn.i}

APPLY 'entry' TO fiTb IN FRAME {&FRAME-NAME} .

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects wWin  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE atuBrCps wWin 
PROCEDURE atuBrCps :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE atuCampos wWin 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE createObjects wWin 
PROCEDURE createObjects :
/*------------------------------------------------------------------------------
  Purpose:     Super Override
  Parameters:  
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  RUN SUPER.

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
    //TITLE     = "Campos"
    FRAME     = FRAME frCampos:HANDLE
    QUERY     = hQCps
   /* X         = 2.43
    Y         = 32*/
    WIDTH     = 112
    DOWN      = 7.25
    VISIBLE   = YES
    READ-ONLY = NO
    SENSITIVE = TRUE 
          ROW = 2.70
           COL = 2
         SEPARATORS = YES
         .
  //ASSIGN hbrCps:MULTIPLE = YES.

hbrCps:ADD-COLUMNS-FROM(BUFFER ttCampos:HANDLE,"tabela,id" ) .
hBrCps:NUM-LOCKED-COLUMNS =  2.
RUN habilitarObjCps(NO).
  


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI wWin  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(wWin)
  THEN DELETE WIDGET wWin.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enableObject wWin 
PROCEDURE enableObject :
/*------------------------------------------------------------------------------
  Purpose:     Super Override
  Parameters:  
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  RUN SUPER.
  
  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI wWin  _DEFAULT-ENABLE
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
  DISPLAY cbComparacao cbBancos fiDtHr fiTb fiCampo cbordenacao tgTbSys fidump 
          rsDetOpcao 
      WITH FRAME fMain IN WINDOW wWin.
  ENABLE RECT-7 RECT-2 RECT-3 RECT-4 cbComparacao cbBancos fiDtHr fiTb fiCampo 
         btPesq cbordenacao tgTbSys fidump BROWSE-2 rsDetOpcao btAreaTrans 
         btAreaTransf btDados 
      WITH FRAME fMain IN WINDOW wWin.
  {&OPEN-BROWSERS-IN-QUERY-fMain}
  DISPLAY fiNome cbFiltro cbTipoCp cbOrdCampos cbAcaoCp 
      WITH FRAME frCampos IN WINDOW wWin.
  ENABLE RECT-5 RECT-6 
      WITH FRAME frCampos IN WINDOW wWin.
  {&OPEN-BROWSERS-IN-QUERY-frCampos}
  VIEW wWin.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE exitObject wWin 
PROCEDURE exitObject :
/*------------------------------------------------------------------------------
  Purpose:  Window-specific override of this procedure which destroys 
            its contents and itself.
    Notes:  
------------------------------------------------------------------------------*/

  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE habilitarObjCps wWin 
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
        fiNome:SENSITIVE IN FRAME frCampos         = lHabilita
        //btLimparFiltroCP:SENSITIVE IN FRAME frCampos = lHabilita 
        .
 




END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE tratarFiltrosCp wWin 
PROCEDURE tratarFiltrosCp :
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

