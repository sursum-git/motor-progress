&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
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
{esp/CLIPBOARD.i "NEW GLOBAL SHARED" }
/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
DEFINE VARIABLE iCont        AS INTEGER     NO-UNDO.
DEFINE VARIABLE h            AS HANDLE      NO-UNDO.
DEFINE VARIABLE cListaBancos AS CHARACTER   NO-UNDO.

{esbo/boMetadados.i}
{esp/util.i}

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
&Scoped-define FIELDS-IN-QUERY-BROWSE-2 banco nome nomeDump descricao dtHrAlteracao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BROWSE-2   
&Scoped-define SELF-NAME BROWSE-2
&Scoped-define OPEN-QUERY-BROWSE-2 CASE cbOrdenacao:SCREEN-VALUE:     WHEN '1' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.nome  .     END.     WHEN '2' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.dtHrAlteracao DESC  .     END.     WHEN '3' THEN DO:         OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas BY ttTabelas.banco BY ttTabelas.nome  .     END.   END CASE.
&Scoped-define TABLES-IN-QUERY-BROWSE-2 ttTabelas
&Scoped-define FIRST-TABLE-IN-QUERY-BROWSE-2 ttTabelas


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-BROWSE-2}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-2 RECT-3 btPesq cbComparacao cbBancos ~
fiDtHr tgTbSys cbordenacao fiTb fidump fiCampo BROWSE-2 btCampos btIndices ~
btTbRelacs btDados btAreaTrans btAreaTransf 
&Scoped-Define DISPLAYED-OBJECTS cbComparacao cbBancos fiDtHr tgTbSys ~
cbordenacao fiTb fidump fiCampo 

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
     SIZE 16.86 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btAreaTransf 
     LABEL "µrea de Transf." 
     SIZE 16.86 BY 1.13.

DEFINE BUTTON btCampos 
     LABEL "Campos" 
     SIZE 13.29 BY 1.13.

DEFINE BUTTON btDados 
     LABEL "Dados" 
     SIZE 13.29 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE BUTTON btIndices 
     LABEL "Indices" 
     SIZE 13.29 BY 1.13.

DEFINE BUTTON btPesq 
     LABEL "Pesquisar" 
     SIZE 13.29 BY 1.13.

DEFINE BUTTON btTbRelacs 
     LABEL "Tabs. Relacs." 
     SIZE 13.29 BY 1.13 TOOLTIP "Tabelas Relacionadas".

DEFINE VARIABLE cbBancos AS CHARACTER FORMAT "X(256)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Todos" 
     DROP-DOWN-LIST
     SIZE 14.43 BY 1 NO-UNDO.

DEFINE VARIABLE cbComparacao AS CHARACTER FORMAT "X(256)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Maior que","Menor que" 
     DROP-DOWN-LIST
     SIZE 10.72 BY 1 NO-UNDO.

DEFINE VARIABLE cbordenacao AS INTEGER FORMAT ">9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nome Tabela",1,
                     "Dt.Hr.Altera‡Æo",2,
                     "Banco + Tabela",3
     DROP-DOWN-LIST
     SIZE 15.43 BY 1 NO-UNDO.

DEFINE VARIABLE fiCampo AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 16.43 BY .79 NO-UNDO.

DEFINE VARIABLE fiDtHr AS DATETIME FORMAT "99/99/9999 HH:MM:SS":U 
     VIEW-AS FILL-IN 
     SIZE 18.86 BY .79 NO-UNDO.

DEFINE VARIABLE fidump AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 11.14 BY .79 NO-UNDO.

DEFINE VARIABLE fiTb AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 19.57 BY .79 NO-UNDO.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 44 BY 2.75.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 44 BY 2.75.

DEFINE VARIABLE tgTbSys AS LOGICAL INITIAL no 
     LABEL "Tabelas Sistema" 
     VIEW-AS TOGGLE-BOX
     SIZE 15 BY .83 NO-UNDO.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY BROWSE-2 FOR 
      ttTabelas SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE BROWSE-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BROWSE-2 W-Win _FREEFORM
  QUERY BROWSE-2 DISPLAY
      banco       COLUMN-LABEL "Banco"        FORMAT 'x(20)'
nome        COLUMN-LABEL "Tabela"       FORMAT 'x(50)'
nomeDump    COLUMN-LABEL "Dump Name"    FORMAT 'x(20)'
descricao   COLUMN-LABEL "Descri‡Æo"    FORMAT 'x(120)'
dtHrAlteracao COLUMN-LABEL "Dt.Hr.Altera‡Æo"    FORMAT '99/99/9999 hh:mm:ss'
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS MULTIPLE SIZE 145.14 BY 13.25
         FONT 1 ROW-HEIGHT-CHARS .54 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     btPesq AT ROW 1.96 COL 134.86 WIDGET-ID 20
     cbComparacao AT ROW 2.08 COL 67.43 COLON-ALIGNED NO-LABEL WIDGET-ID 26
     cbBancos AT ROW 2.13 COL 1.57 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     fiDtHr AT ROW 2.13 COL 78.29 COLON-ALIGNED NO-LABEL WIDGET-ID 22
     tgTbSys AT ROW 2.13 COL 101.14 WIDGET-ID 30
     cbordenacao AT ROW 2.13 COL 113.57 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     fiTb AT ROW 2.17 COL 16.72 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     fidump AT ROW 2.17 COL 36.86 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     fiCampo AT ROW 2.17 COL 49 COLON-ALIGNED NO-LABEL WIDGET-ID 10
     BROWSE-2 AT ROW 3.5 COL 3.86 WIDGET-ID 200
     btCampos AT ROW 17.88 COL 4.29 WIDGET-ID 36
     btIndices AT ROW 17.88 COL 17.72 WIDGET-ID 38
     btTbRelacs AT ROW 17.88 COL 31.14 WIDGET-ID 40
     btDados AT ROW 17.88 COL 135.43 WIDGET-ID 42
     btAreaTrans AT ROW 17.92 COL 48.14 WIDGET-ID 44
     btAreaTransf AT ROW 17.92 COL 65.14 WIDGET-ID 50
     "Tabela" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 1.46 COL 19.14 WIDGET-ID 18
     "Dump Name" VIEW-AS TEXT
          SIZE 10.72 BY .54 AT ROW 1.46 COL 39.29 WIDGET-ID 16
     "Campo" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 1.46 COL 51.43 WIDGET-ID 14
     "Banco" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 1.46 COL 4 WIDGET-ID 12
     "Data/Hora Altera‡Æo Estrut. Tabela" VIEW-AS TEXT
          SIZE 24.29 BY .54 AT ROW 1.5 COL 69.72 WIDGET-ID 24
     "Ordena‡Æo" VIEW-AS TEXT
          SIZE 11.43 BY .54 AT ROW 1.46 COL 115.57 WIDGET-ID 34
     RECT-2 AT ROW 17 COL 3 WIDGET-ID 46
     RECT-3 AT ROW 17 COL 47.57 WIDGET-ID 48
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 148.57 BY 27.04
         FONT 1 WIDGET-ID 100.


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
         HEIGHT             = 27.04
         WIDTH              = 148.57
         MAX-HEIGHT         = 29.38
         MAX-WIDTH          = 195.14
         VIRTUAL-HEIGHT     = 29.38
         VIRTUAL-WIDTH      = 195.14
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
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
/* BROWSE-TAB BROWSE-2 fiCampo F-Main */
ASSIGN 
       FRAME F-Main:HIDDEN           = TRUE.

ASSIGN 
       BROWSE-2:NUM-LOCKED-COLUMNS IN FRAME F-Main     = 3.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(W-Win)
THEN W-Win:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BROWSE-2
/* Query rebuild information for BROWSE BROWSE-2
     _START_FREEFORM
CASE cbOrdenacao:SCREEN-VALUE:
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
  RUN esp/sursum90.w.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btCampos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btCampos W-Win
ON CHOOSE OF btCampos IN FRAME F-Main /* Campos */
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


&Scoped-define SELF-NAME btIndices
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btIndices W-Win
ON CHOOSE OF btIndices IN FRAME F-Main /* Indices */
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


&Scoped-define SELF-NAME btPesq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btPesq W-Win
ON CHOOSE OF btPesq IN FRAME F-Main /* Pesquisar */
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


&Scoped-define SELF-NAME btTbRelacs
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btTbRelacs W-Win
ON CHOOSE OF btTbRelacs IN FRAME F-Main /* Tabs. Relacs. */
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


&Scoped-define BROWSE-NAME BROWSE-2
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK W-Win 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

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
      WITH FRAME F-Main IN WINDOW W-Win.
  ENABLE RECT-2 RECT-3 btPesq cbComparacao cbBancos fiDtHr tgTbSys cbordenacao 
         fiTb fidump fiCampo BROWSE-2 btCampos btIndices btTbRelacs btDados 
         btAreaTrans btAreaTransf 
      WITH FRAME F-Main IN WINDOW W-Win.
  VIEW FRAME F-Main IN WINDOW W-Win.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW W-Win.
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

