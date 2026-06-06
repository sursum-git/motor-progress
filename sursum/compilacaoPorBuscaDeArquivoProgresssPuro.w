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

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

{buscarArquivos.i}
{esbo/bomsg.i}
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

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 fiTextos tgCaseInsensitive ~
fiExtensoes edDiretorios btExecutar 
&Scoped-Define DISPLAYED-OBJECTS fiTextos tgCaseInsensitive fiExtensoes ~
edDiretorios 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR W-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btExecutar 
     LABEL "Compilar" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE edDiretorios AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 57 BY 2 NO-UNDO.

DEFINE VARIABLE fiExtensoes AS CHARACTER FORMAT "X(256)":U 
     LABEL "Extensoes" 
     VIEW-AS FILL-IN 
     SIZE 57.29 BY .88 NO-UNDO.

DEFINE VARIABLE fiTextos AS CHARACTER FORMAT "X(256)":U 
     LABEL "Textos a Pesquisar" 
     VIEW-AS FILL-IN 
     SIZE 57.43 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 97 BY 6.5.

DEFINE VARIABLE tgCaseInsensitive AS LOGICAL INITIAL yes 
     LABEL "Case Insensitive?" 
     VIEW-AS TOGGLE-BOX
     SIZE 15.57 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     fiTextos AT ROW 3.5 COL 18.14 COLON-ALIGNED WIDGET-ID 4
     tgCaseInsensitive AT ROW 3.5 COL 77.86 WIDGET-ID 6
     fiExtensoes AT ROW 4.5 COL 18.29 COLON-ALIGNED WIDGET-ID 12
     edDiretorios AT ROW 6.17 COL 20.14 NO-LABEL WIDGET-ID 8
     btExecutar AT ROW 9.5 COL 2 WIDGET-ID 14
     "Diret¢rios" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 5.5 COL 20.43 WIDGET-ID 10
     RECT-1 AT ROW 2.75 COL 1.57 WIDGET-ID 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 120 BY 10.21
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
         TITLE              = "Compilar Fontes Com Filtro por Conte£do"
         HEIGHT             = 10.17
         WIDTH              = 101.72
         MAX-HEIGHT         = 47.38
         MAX-WIDTH          = 274.29
         VIRTUAL-HEIGHT     = 47.38
         VIRTUAL-WIDTH      = 274.29
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
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(W-Win)
THEN W-Win:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON END-ERROR OF W-Win /* Compilar Fontes Com Filtro por Conte£do */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON WINDOW-CLOSE OF W-Win /* Compilar Fontes Com Filtro por Conte£do */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExecutar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExecutar W-Win
ON CHOOSE OF btExecutar IN FRAME F-Main /* Compilar */
DO:
  ASSIGN btExecutar:SENSITIVE = NO. 
  ASSIGN btExecutar:LABEL = "Buscando Arquivos".
  RUN buscarArquivos.
  ASSIGN btExecutar:LABEL = "Compilando".
  RUN compilarArquivos.
  {esp/exportarTabelaCsv3.i ttArquivos " " " " "ArquivosCompilados"}
  ASSIGN btExecutar:SENSITIVE = YES. 
  ASSIGN btExecutar:LABEL = "Compilar".
  
  OS-COMMAND SILENT VALUE(' start ' + cArqTTArquivos).
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE buscarArquivos W-Win 
PROCEDURE buscarArquivos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

DEFINE VARIABLE hBo AS HANDLE      NO-UNDO.
RUN buscarArquivos.p PERSISTENT SET hBo.
RUN iniciar                       IN hBo.
RUN limparTTs                     IN hBo.
RUN setDesconsiderarCaseSensitive IN hBo(INPUT FRAME {&frame-name} tgCaseInsensitive).
RUN setDiretorios                 IN hBo(INPUT FRAME {&frame-name} edDiretorios).
RUN setTermos                     IN hbo(INPUT FRAME {&frame-name} fiTextos).
RUN setExtensoes                  IN hBo(INPUT FRAME {&frame-name} fiExtensoes).
RUN setArquivoResultado           IN hBo(SESSION:TEMP-DIRECTORY + 'result_compilacao-' + STRING(TIME) + '.txt').
RUN executar                      IN hBo.
RUN getTtEstatistica              IN hBo(OUTPUT TABLE ttEstatistica).

IF RETURN-VALUE = 'nok' THEN DO:
   RUN getTTMsg IN hBo(OUTPUT TABLE ttMsg).
   FOR EACH ttMsg:
       MESSAGE ttMsg.cod SKIP
               ttMsg.descricao
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
       
   END.
    
END.
ELSE DO:
    RUN getTTArquivos IN hBo(OUTPUT TABLE ttArquivos).
    /*FOR EACH ttArquivos:
         DISP ttArquivos.nomeArquivo WITH WIDTH 550.
    END.*/
END.

RUN finalizar IN hBo.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE compilarArquivos W-Win 
PROCEDURE compilarArquivos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

FOR EACH ttArquivos WHERE ttArquivos.nomeArquivo <> '':
    RUN compilarFonte.p(ttArquivos.nomeArquivo,OUTPUT ttArquivos.historico).    
    IF ttArquivos.historico <> ''  THEN
       ASSIGN ttArquivos.historico = STRING(NOW) + "-(ERRO)-" + ttArquivos.historico .
    ELSE
       ASSIGN ttArquivos.historico = STRING(NOW).
    
                                  .
                                  
END.

FOR EACH ttArquivos WHERE ttArquivos.nomeArquivo = '':
    DELETE ttArquivos.
END.


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
  DISPLAY fiTextos tgCaseInsensitive fiExtensoes edDiretorios 
      WITH FRAME F-Main IN WINDOW W-Win.
  ENABLE RECT-1 fiTextos tgCaseInsensitive fiExtensoes edDiretorios btExecutar 
      WITH FRAME F-Main IN WINDOW W-Win.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW W-Win.
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

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this SmartWindow, and there are no
     tables specified in any contained Browse, Query, or Frame. */

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

