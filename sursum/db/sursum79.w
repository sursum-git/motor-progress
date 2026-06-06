&ANALYZE-SUSPEND _VERSION-NUMBER AB_v10r12 GUI ADM2
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME gDialog
{adecomm/appserv.i}
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS gDialog 
/*------------------------------------------------------------------------

  File: 

  Description: from cntnrdlg.w - ADM2 SmartDialog Template

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  Author: 

  Created: 
------------------------------------------------------------------------*/
/*          This .W file was created with the Progress AppBuilder.      */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

{src/adm2/widgetprto.i}

{esbo/boMetaDados.i}

DEFINE OUTPUT PARAMETER cBAncoSel  AS CHARACTER   NO-UNDO.
DEFINE OUTPUT PARAMETER cTabelaSel AS CHARACTER   NO-UNDO.
DEFINE OUTPUT PARAMETER cAcao      AS CHARACTER   NO-UNDO.
 
DEFINE VARIABLE h AS HANDLE      NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

&Scoped-define ADM-SUPPORTED-LINKS Data-Target,Data-Source,Page-Target,Update-Source,Update-Target

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME gDialog
&Scoped-define BROWSE-NAME brTabelas

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttTabelas

/* Definitions for BROWSE brTabelas                                     */
&Scoped-define FIELDS-IN-QUERY-brTabelas ttTabelas.nome ttTabelas.descricao ttTabelas.banco   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brTabelas   
&Scoped-define SELF-NAME brTabelas
&Scoped-define QUERY-STRING-brTabelas FOR EACH ttTabelas
&Scoped-define OPEN-QUERY-brTabelas OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas.
&Scoped-define TABLES-IN-QUERY-brTabelas ttTabelas
&Scoped-define FIRST-TABLE-IN-QUERY-brTabelas ttTabelas


/* Definitions for DIALOG-BOX gDialog                                   */
&Scoped-define OPEN-BROWSERS-IN-QUERY-gDialog ~
    ~{&OPEN-QUERY-brTabelas}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-10 RECT-11 btBuscar cbBancos fiTb ~
brTabelas Btn_OK Btn_Cancel 
&Scoped-Define DISPLAYED-OBJECTS cbBancos fiTb 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON btBuscar 
     LABEL "Buscar" 
     SIZE 15 BY 1.14.

DEFINE BUTTON Btn_Cancel AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 15 BY 1.14.

DEFINE BUTTON Btn_OK AUTO-GO 
     LABEL "Selecionar" 
     SIZE 15 BY 1.14.

DEFINE VARIABLE cbBancos AS CHARACTER FORMAT "X(256)":U INITIAL "Todos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEMS "Todos" 
     DROP-DOWN-LIST
     SIZE 19.4 BY 1 NO-UNDO.

DEFINE VARIABLE fiTb AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 28 BY .86 NO-UNDO.

DEFINE RECTANGLE RECT-10
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 75 BY 2.86.

DEFINE RECTANGLE RECT-11
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 74.8 BY 1.71
     BGCOLOR 8 FGCOLOR 15 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY brTabelas FOR 
      ttTabelas SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE brTabelas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brTabelas gDialog _FREEFORM
  QUERY brTabelas DISPLAY
      ttTabelas.nome       COLUMN-LABEL "Nome"    FORMAT 'x(30)'
ttTabelas.descricao  COLUMN-LABEL "Descrição" FORMAT 'x(100)'
ttTabelas.banco COLUMN-LABEL "Banco" FORMAT 'x(30)'
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 75 BY 9.52.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME gDialog
     btBuscar AT ROW 2.1 COL 53 WIDGET-ID 22
     cbBancos AT ROW 2.19 COL 1.6 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     fiTb AT ROW 2.29 COL 22 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     brTabelas AT ROW 4.24 COL 2 WIDGET-ID 200
     Btn_OK AT ROW 14.57 COL 3
     Btn_Cancel AT ROW 14.57 COL 18
     "Tabela" VIEW-AS TEXT
          SIZE 8.8 BY .52 AT ROW 1.52 COL 24 WIDGET-ID 18
          FONT 6
     "Banco" VIEW-AS TEXT
          SIZE 8.8 BY .52 AT ROW 1.52 COL 4 WIDGET-ID 20
          FONT 6
     RECT-10 AT ROW 1.29 COL 2 WIDGET-ID 24
     RECT-11 AT ROW 14.33 COL 2 WIDGET-ID 26
     SPACE(1.39) SKIP(0.24)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         TITLE "Seleção de  Tabela"
         DEFAULT-BUTTON Btn_OK CANCEL-BUTTON Btn_Cancel WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartDialog
   Allow: Basic,Browse,DB-Fields,Query,Smart
   Container Links: Data-Target,Data-Source,Page-Target,Update-Source,Update-Target
   Other Settings: APPSERVER
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB gDialog 
/* ************************* Included-Libraries *********************** */

{src/adm2/containr.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR DIALOG-BOX gDialog
   FRAME-NAME                                                           */
/* BROWSE-TAB brTabelas fiTb gDialog */
ASSIGN 
       FRAME gDialog:SCROLLABLE       = FALSE
       FRAME gDialog:HIDDEN           = TRUE.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brTabelas
/* Query rebuild information for BROWSE brTabelas
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttTabelas.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE brTabelas */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK DIALOG-BOX gDialog
/* Query rebuild information for DIALOG-BOX gDialog
     _Options          = "SHARE-LOCK"
     _Query            is NOT OPENED
*/  /* DIALOG-BOX gDialog */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME gDialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL gDialog gDialog
ON WINDOW-CLOSE OF FRAME gDialog /* Seleção de  Tabela */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME brTabelas
&Scoped-define SELF-NAME brTabelas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL brTabelas gDialog
ON MOUSE-SELECT-DBLCLICK OF brTabelas IN FRAME gDialog
DO:
  IF AVAIL ttTabelas THEN
     APPLY 'choose' TO btn_Ok.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btBuscar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btBuscar gDialog
ON CHOOSE OF btBuscar IN FRAME gDialog /* Buscar */
DO:
    EMPTY TEMP-TABLE ttTabelas.
    RUN limparFiltros IN h.

    IF cbBancos:SCREEN-VALUE <> 'todos' THEN
       RUN setFiltrosTb IN h('banco',cbBancos:SCREEN-VALUE).

    IF fiTb:SCREEN-VALUE <> '' THEN
       RUN setFiltrosTb IN h('tabela',fiTb:SCREEN-VALUE).
   
    RUN setFiltrosTb IN h('mostrar_tbs_sys','NO' ).

    RUN getTbs IN h(OUTPUT TABLE ttTabelas).

    {&open-query-brTabelas}

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME Btn_Cancel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL Btn_Cancel gDialog
ON CHOOSE OF Btn_Cancel IN FRAME gDialog /* Cancelar */
DO:
  ASSIGN cAcao = "Cancelar".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME Btn_OK
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL Btn_OK gDialog
ON CHOOSE OF Btn_OK IN FRAME gDialog /* Selecionar */
DO:
  IF AVAIL ttTabelas THEN
     ASSIGN cTabelaSel = ttTabelas.nome:SCREEN-VALUE IN BROWSE brTabelas
            cBancoSel  = ttTabelas.banco:SCREEN-VALUE IN BROWSE brtabelas .

  IF cTabelaSel = '' THEN DO:
     MESSAGE 'Nenhuma tabela foi selecionada'
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
     RETURN NO-APPLY.
  END.

  ASSIGN cAcao = "OK".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiTb
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiTb gDialog
ON RETURN OF fiTb IN FRAME gDialog
DO:
  APPLY 'choose' TO btBuscar.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK gDialog 


/* ***************************  Main Block  *************************** */

{src/adm2/dialogmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects gDialog  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI gDialog  _DEFAULT-DISABLE
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
  HIDE FRAME gDialog.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI gDialog  _DEFAULT-ENABLE
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
  DISPLAY cbBancos fiTb 
      WITH FRAME gDialog.
  ENABLE RECT-10 RECT-11 btBuscar cbBancos fiTb brTabelas Btn_OK Btn_Cancel 
      WITH FRAME gDialog.
  VIEW FRAME gDialog.
  {&OPEN-BROWSERS-IN-QUERY-gDialog}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE initializeObject gDialog 
PROCEDURE initializeObject :
/*------------------------------------------------------------------------------
  Purpose:     Super Override
  Parameters:  
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  RUN SUPER.

  RUN esbo/boMetaDados.p PERSIST SET h.
  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

