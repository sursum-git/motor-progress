&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v9r12 GUI
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS C-Win 
/*------------------------------------------------------------------------

  File: 

  Description: 

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

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME DEFAULT-FRAME

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS IMAGE-1 IMAGE-10 IMAGE-11 IMAGE-12 IMAGE-2 ~
IMAGE-3 IMAGE-4 IMAGE-5 IMAGE-6 IMAGE-7 IMAGE-8 IMAGE-9 rt-button fi-dt-ini ~
fi-dt-fim fi-cod-estabel fi-cod-estabel-fim fi-nome-ab-rep ~
fi-nome-ab-rep-fim fi-cod-emitente fi-cod-emitente-fim fi-motivo ~
fi-motivo-fim fi-it-codigo fi-it-codigo-fim bt-excel 
&Scoped-Define DISPLAYED-OBJECTS fi-dt-ini fi-dt-fim fi-cod-estabel ~
fi-cod-estabel-fim fi-nome-ab-rep fi-nome-ab-rep-fim fi-cod-emitente ~
fi-cod-emitente-fim fi-motivo fi-motivo-fim fi-it-codigo fi-it-codigo-fim 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR C-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/im-exp-excel.bmp":U
     LABEL "Excel" 
     SIZE 16 BY 1.25
     FONT 0.

DEFINE VARIABLE fi-cod-emitente AS CHARACTER FORMAT "X(15)":U 
     LABEL "Cod Cliente" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cod-emitente-fim AS CHARACTER FORMAT "X(15)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cod-estabel AS CHARACTER FORMAT "X(15)":U 
     LABEL "Estabelecimento" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cod-estabel-fim AS CHARACTER FORMAT "X(15)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-fim AS DATE FORMAT "99/99/9999":U INITIAL 12/31/9999 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-ini AS DATE FORMAT "99/99/9999":U INITIAL 01/01/01 
     LABEL "Data Devol" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-it-codigo AS CHARACTER FORMAT "X(15)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-it-codigo-fim AS CHARACTER FORMAT "X(15)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-motivo AS CHARACTER FORMAT "X(15)":U 
     LABEL "Motivo" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-motivo-fim AS CHARACTER FORMAT "X(15)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-nome-ab-rep AS CHARACTER FORMAT "X(15)":U 
     LABEL "Nome Abrev Repres" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-nome-ab-rep-fim AS CHARACTER FORMAT "X(15)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-10
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-11
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-12
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
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

DEFINE IMAGE IMAGE-7
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-8
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-9
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 65 BY 1.46
     BGCOLOR 7 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME DEFAULT-FRAME
     fi-dt-ini AT ROW 2.75 COL 13.57 COLON-ALIGNED
     fi-dt-fim AT ROW 2.75 COL 39.14 COLON-ALIGNED NO-LABEL
     fi-cod-estabel AT ROW 3.71 COL 13.57 COLON-ALIGNED
     fi-cod-estabel-fim AT ROW 3.71 COL 39.14 COLON-ALIGNED NO-LABEL
     fi-nome-ab-rep AT ROW 4.71 COL 13.57 COLON-ALIGNED
     fi-nome-ab-rep-fim AT ROW 4.71 COL 39.14 COLON-ALIGNED NO-LABEL
     fi-cod-emitente AT ROW 5.75 COL 13.57 COLON-ALIGNED
     fi-cod-emitente-fim AT ROW 5.75 COL 39.14 COLON-ALIGNED NO-LABEL
     fi-motivo AT ROW 6.75 COL 13.57 COLON-ALIGNED
     fi-motivo-fim AT ROW 6.75 COL 39.14 COLON-ALIGNED NO-LABEL
     fi-it-codigo AT ROW 7.75 COL 13.57 COLON-ALIGNED
     fi-it-codigo-fim AT ROW 7.75 COL 39.14 COLON-ALIGNED NO-LABEL
     bt-excel AT ROW 9.63 COL 2.14
     IMAGE-1 AT ROW 2.75 COL 31.14
     IMAGE-10 AT ROW 6.75 COL 38.29
     IMAGE-11 AT ROW 7.75 COL 38.29
     IMAGE-12 AT ROW 7.75 COL 31.14
     IMAGE-2 AT ROW 2.75 COL 38.29
     IMAGE-3 AT ROW 3.71 COL 31.14
     IMAGE-4 AT ROW 3.71 COL 38.29
     IMAGE-5 AT ROW 4.71 COL 31.14
     IMAGE-6 AT ROW 4.71 COL 38.29
     IMAGE-7 AT ROW 5.75 COL 31.14
     IMAGE-8 AT ROW 5.75 COL 38.29
     IMAGE-9 AT ROW 6.75 COL 31.14
     rt-button AT ROW 9.5 COL 1
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 65.57 BY 10
         FONT 1.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: Window
   Allow: Basic,Browse,DB-Fields,Window,Query
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW C-Win ASSIGN
         HIDDEN             = YES
         TITLE              = "Controle de Devolu‡äes"
         HEIGHT             = 10
         WIDTH              = 65.57
         MAX-HEIGHT         = 29.88
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 29.88
         VIRTUAL-WIDTH      = 146.29
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = no
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME



/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW C-Win
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME DEFAULT-FRAME
   FRAME-NAME                                                           */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
THEN C-Win:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON END-ERROR OF C-Win /* Controle de Devolu‡äes */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON WINDOW-CLOSE OF C-Win /* Controle de Devolu‡äes */
DO:
  /* This event will close the window and terminate the procedure.  */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel C-Win
ON CHOOSE OF bt-excel IN FRAME DEFAULT-FRAME /* Excel */
DO:
  RUN esrp\es100rp.p (INPUT FRAME {&FRAME-NAME} fi-dt-ini,
                      INPUT FRAME {&FRAME-NAME} fi-dt-fim,
                      INPUT FRAME {&FRAME-NAME} fi-cod-estabel,
                      INPUT FRAME {&FRAME-NAME} fi-cod-estabel-fim,
                      INPUT FRAME {&FRAME-NAME} fi-cod-emitente,
                      INPUT FRAME {&FRAME-NAME} fi-cod-emitente-fim,
                      INPUT FRAME {&FRAME-NAME} fi-nome-ab-rep,
                      INPUT FRAME {&FRAME-NAME} fi-nome-ab-rep-fim,
                      INPUT FRAME {&FRAME-NAME} fi-motivo,
                      INPUT FRAME {&FRAME-NAME} fi-motivo-fim,
                      INPUT FRAME {&FRAME-NAME} fi-it-codigo,
                      INPUT FRAME {&FRAME-NAME} fi-it-codigo-fim).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK C-Win 


/* ***************************  Main Block  *************************** */

/* Set CURRENT-WINDOW: this will parent dialog-boxes and frames.        */
ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME} 
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.

/* The CLOSE event can be used from inside or outside the procedure to  */
/* terminate it.                                                        */
ON CLOSE OF THIS-PROCEDURE 
   RUN disable_UI.

/* Best default for GUI applications is...                              */
PAUSE 0 BEFORE-HIDE.

/* Now enable the interface and wait for the exit condition.            */
/* (NOTE: handle ERROR and END-KEY so cleanup code will always fire.    */
MAIN-BLOCK:
DO ON ERROR   UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK
   ON END-KEY UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK:

  RUN enable_UI.

  ASSIGN fi-dt-ini:SCREEN-VALUE = STRING(TODAY - DAY(TODAY) + 1)
         fi-dt-fim:SCREEN-VALUE = STRING(TODAY ).

  IF NOT THIS-PROCEDURE:PERSISTENT THEN
    WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI C-Win  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
  THEN DELETE WIDGET C-Win.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI C-Win  _DEFAULT-ENABLE
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
  DISPLAY fi-dt-ini fi-dt-fim fi-cod-estabel fi-cod-estabel-fim fi-nome-ab-rep 
          fi-nome-ab-rep-fim fi-cod-emitente fi-cod-emitente-fim fi-motivo 
          fi-motivo-fim fi-it-codigo fi-it-codigo-fim 
      WITH FRAME DEFAULT-FRAME IN WINDOW C-Win.
  ENABLE IMAGE-1 IMAGE-10 IMAGE-11 IMAGE-12 IMAGE-2 IMAGE-3 IMAGE-4 IMAGE-5 
         IMAGE-6 IMAGE-7 IMAGE-8 IMAGE-9 rt-button fi-dt-ini fi-dt-fim 
         fi-cod-estabel fi-cod-estabel-fim fi-nome-ab-rep fi-nome-ab-rep-fim 
         fi-cod-emitente fi-cod-emitente-fim fi-motivo fi-motivo-fim 
         fi-it-codigo fi-it-codigo-fim bt-excel 
      WITH FRAME DEFAULT-FRAME IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-DEFAULT-FRAME}
  VIEW C-Win.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

