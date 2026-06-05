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
DEF NEW GLOBAL SHARED VAR  c-seg-usuario  AS CHAR NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME DEFAULT-FRAME

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS bt-espp-12 bt-digi-container ~
bt-relatorio-geral-2 bt-espp11 bt-espp009 bt-digi-pedidos bt-etiquetas ~
bt-fecha-container bt-relatorio-geral bt-relpp002 bt-troca-item ~
bt-troca-preco 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR C-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-digi-container  NO-FOCUS FLAT-BUTTON
     LABEL "&1. Digitaá∆o de Container":L31 
     SIZE 25 BY 1.08
     FONT 1.

DEFINE BUTTON bt-digi-pedidos  NO-FOCUS FLAT-BUTTON
     LABEL "&2. Digitaá∆o de Pedidos":L31 
     SIZE 25 BY 1.08
     FONT 1.

DEFINE BUTTON bt-espp-12  NO-FOCUS FLAT-BUTTON NO-CONVERT-3D-COLORS
     LABEL "&11. Transf. Dep. Fechado":L30 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-espp009  NO-FOCUS FLAT-BUTTON NO-CONVERT-3D-COLORS
     LABEL "&9. Fecha Cont Manual":L30 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-espp11  NO-FOCUS FLAT-BUTTON NO-CONVERT-3D-COLORS
     LABEL "&10. Produtos Vendidos":L30 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-etiquetas  NO-FOCUS FLAT-BUTTON
     LABEL "&6. Etiquetas":L38 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-fecha-container  NO-FOCUS FLAT-BUTTON
     LABEL "&7. Fechamento de Container":L26 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-relatorio-geral  NO-FOCUS FLAT-BUTTON
     LABEL "&5. Relatorio Geral":L35 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-relatorio-geral-2  NO-FOCUS FLAT-BUTTON
     LABEL "&5.1 Relatorio Geral Excel":L35 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-relpp002  NO-FOCUS FLAT-BUTTON NO-CONVERT-3D-COLORS
     LABEL "&8. Relatorio de Saldo":L32 
     SIZE 25 BY 1.08.

DEFINE BUTTON bt-troca-item  NO-FOCUS FLAT-BUTTON
     LABEL "&3. Troca de Item":L36 
     SIZE 25 BY 1.08
     FONT 1.

DEFINE BUTTON bt-troca-preco  NO-FOCUS FLAT-BUTTON
     LABEL "&4. Troca de Preáos":L33 
     SIZE 25 BY 1.08
     FONT 1.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME DEFAULT-FRAME
     bt-espp-12 AT ROW 15.25 COL 25 RIGHT-ALIGNED WIDGET-ID 8
     bt-digi-container AT ROW 1.42 COL 1
     bt-relatorio-geral-2 AT ROW 7.67 COL 1 WIDGET-ID 6
     bt-espp11 AT ROW 13.92 COL 25 RIGHT-ALIGNED WIDGET-ID 4
     bt-espp009 AT ROW 12.67 COL 25 RIGHT-ALIGNED WIDGET-ID 2
     bt-digi-pedidos AT ROW 2.67 COL 1
     bt-etiquetas AT ROW 9 COL 1
     bt-fecha-container AT ROW 10.21 COL 1
     bt-relatorio-geral AT ROW 6.42 COL 1
     bt-relpp002 AT ROW 11.42 COL 1
     bt-troca-item AT ROW 3.92 COL 1
     bt-troca-preco AT ROW 5.17 COL 1
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 44.43 BY 18.25
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
         TITLE              = "Menu PI"
         COLUMN             = 44.72
         ROW                = 7.21
         HEIGHT             = 15.5
         WIDTH              = 26
         MAX-HEIGHT         = 29.42
         MAX-WIDTH          = 195.14
         VIRTUAL-HEIGHT     = 29.42
         VIRTUAL-WIDTH      = 195.14
         RESIZE             = yes
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



/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW C-Win
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME DEFAULT-FRAME
   FRAME-NAME                                                           */
/* SETTINGS FOR BUTTON bt-espp-12 IN FRAME DEFAULT-FRAME
   ALIGN-R                                                              */
ASSIGN 
       bt-espp-12:HIDDEN IN FRAME DEFAULT-FRAME           = TRUE.

/* SETTINGS FOR BUTTON bt-espp009 IN FRAME DEFAULT-FRAME
   ALIGN-R                                                              */
ASSIGN 
       bt-espp009:HIDDEN IN FRAME DEFAULT-FRAME           = TRUE.

/* SETTINGS FOR BUTTON bt-espp11 IN FRAME DEFAULT-FRAME
   ALIGN-R                                                              */
ASSIGN 
       bt-espp11:HIDDEN IN FRAME DEFAULT-FRAME           = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
THEN C-Win:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON END-ERROR OF C-Win /* Menu PI */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON WINDOW-CLOSE OF C-Win /* Menu PI */
DO:
  /* This event will close the window and terminate the procedure.  */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-digi-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-digi-container C-Win
ON CHOOSE OF bt-digi-container IN FRAME DEFAULT-FRAME /* 1. Digitaá∆o de Container */
DO:
   RUN esp/espp001.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-digi-pedidos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-digi-pedidos C-Win
ON CHOOSE OF bt-digi-pedidos IN FRAME DEFAULT-FRAME /* 2. Digitaá∆o de Pedidos */
DO:
  RUN esp/espp002.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-espp-12
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-espp-12 C-Win
ON CHOOSE OF bt-espp-12 IN FRAME DEFAULT-FRAME /* 11. Transf. Dep. Fechado */
DO:
   RUN esp/essp0189.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-espp009
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-espp009 C-Win
ON CHOOSE OF bt-espp009 IN FRAME DEFAULT-FRAME /* 9. Fecha Cont Manual */
DO:
   RUN esp/espp009.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-espp11
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-espp11 C-Win
ON CHOOSE OF bt-espp11 IN FRAME DEFAULT-FRAME /* 10. Produtos Vendidos */
DO:
   RUN esp/espp011.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-etiquetas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-etiquetas C-Win
ON CHOOSE OF bt-etiquetas IN FRAME DEFAULT-FRAME /* 6. Etiquetas */
DO:
  FIND param-re WHERE
       param-re.usuario = c-seg-usuario
       NO-LOCK NO-ERROR.
  IF NOT AVAIL param-re THEN DO:
     MESSAGE "Usu†rio n∆o pertence ao recebimento..."
     VIEW-AS ALERT-BOX INFO BUTTONS OK.
     RETURN NO-APPLY.
  END.
  RUN esp/espp003.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-fecha-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-fecha-container C-Win
ON CHOOSE OF bt-fecha-container IN FRAME DEFAULT-FRAME /* 7. Fechamento de Container */
DO:
   FIND param-re WHERE
       param-re.usuario = c-seg-usuario
       NO-LOCK NO-ERROR.
   IF NOT AVAIL param-re THEN DO:
     MESSAGE "Usu†rio n∆o pertence ao recebimento..."
     VIEW-AS ALERT-BOX INFO BUTTONS OK.
     RETURN NO-APPLY.
  END. 
  RUN esp/espp005.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-relatorio-geral
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-relatorio-geral C-Win
ON CHOOSE OF bt-relatorio-geral IN FRAME DEFAULT-FRAME /* 5. Relatorio Geral */
DO:
  RUN esp/espp008.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-relatorio-geral-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-relatorio-geral-2 C-Win
ON CHOOSE OF bt-relatorio-geral-2 IN FRAME DEFAULT-FRAME /* 5.1 Relatorio Geral Excel */
DO:
  RUN esp/relpp001excel.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-relpp002
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-relpp002 C-Win
ON CHOOSE OF bt-relpp002 IN FRAME DEFAULT-FRAME /* 8. Relatorio de Saldo */
DO:
   RUN esp/relpp002.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-troca-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-troca-item C-Win
ON CHOOSE OF bt-troca-item IN FRAME DEFAULT-FRAME /* 3. Troca de Item */
DO:
  RUN esp/espp004.w.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-troca-preco
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-troca-preco C-Win
ON CHOOSE OF bt-troca-preco IN FRAME DEFAULT-FRAME /* 4. Troca de Preáos */
DO:
  RUN esp/espp006.w.
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
  IF NOT THIS-PROCEDURE:PERSISTENT THEN
    WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.
/*
ON '1':U ANYWHERE DO:
    RUN esp/espp001.w.
END.
ON '2':U ANYWHERE DO:
    RUN esp/espp002.w.
END.
ON '3':U ANYWHERE DO:
    RUN esp/espp004.w.
END.
ON '4':U ANYWHERE DO:
    RUN esp/espp006.w.
END.
ON '5':U ANYWHERE DO:
    RUN esp/relpp001.w.
END.
ON '6':U ANYWHERE DO:
    RUN esp/espp003.w.
END.
ON '7':U ANYWHERE DO:
    RUN esp/espp005.w.
END.
*/

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
  ENABLE bt-espp-12 bt-digi-container bt-relatorio-geral-2 bt-espp11 bt-espp009 
         bt-digi-pedidos bt-etiquetas bt-fecha-container bt-relatorio-geral 
         bt-relpp002 bt-troca-item bt-troca-preco 
      WITH FRAME DEFAULT-FRAME IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-DEFAULT-FRAME}
  VIEW C-Win.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

