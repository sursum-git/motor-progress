&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          espec            PROGRESS
          ems206           PROGRESS
*/
&Scoped-define WINDOW-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS W-Win 
/*********************************************************************
* Copyright (C) 2000 by Progress Software Corporation ("PSC"),       *
* 14 Oak Park, Bedford, MA 01730, and other contributors as listed   *
* below.  All Rights Reserved.                                       *
*                                                                    *
* The Initial Developer of the Original Code is PSC.  The Original   *
* Code is Progress IDE code released to open source December 1, 2000.*
*                                                                    *
* The contents of this file are subject to the Possenet Public       *
* License Version 1.0 (the "License"); you may not use this file     *
* except in compliance with the License.  A copy of the License is   *
* available as of the date of this notice at                         *
* http://www.possenet.org/license.html                               *
*                                                                    *
* Software distributed under the License is distributed on an "AS IS"*
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. You*
* should refer to the License for the specific language governing    *
* rights and limitations under the License.                          *
*                                                                    *
* Contributors:                                                      *
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

DEFINE VARIABLE var-descricao AS CHARACTER INITIAL "*"  NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME br-item

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ITEM item-ext

/* Definitions for BROWSE br-item                                       */
&Scoped-define FIELDS-IN-QUERY-br-item item.it-codigo item.desc-item item-ext.gramatura   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-item   
&Scoped-define SELF-NAME br-item
&Scoped-define QUERY-STRING-br-item FOR EACH ITEM WHERE ITEM.desc-item MATCHES var-descricao                                                AND item.it-codigo >= fi-item-ini:screen-value in frame {&frame-name}                                                AND item.it-codigo <= fi-item-fim:screen-value in frame {&frame-name}                                                AND item.ge-codigo >= 50                                                AND item.ge-codigo <= 60                                                NO-LOCK, ~
                    EACH espec.item-ext WHERE espec.item-ext.it-codigo = item.it-codigo NO-LOCK     BY item.it-codigo INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-item OPEN QUERY {&SELF-NAME} FOR EACH ITEM WHERE ITEM.desc-item MATCHES var-descricao                                                AND item.it-codigo >= fi-item-ini:screen-value in frame {&frame-name}                                                AND item.it-codigo <= fi-item-fim:screen-value in frame {&frame-name}                                                AND item.ge-codigo >= 50                                                AND item.ge-codigo <= 60                                                NO-LOCK, ~
                    EACH espec.item-ext WHERE espec.item-ext.it-codigo = item.it-codigo NO-LOCK     BY item.it-codigo INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-item ITEM item-ext
&Scoped-define FIRST-TABLE-IN-QUERY-br-item ITEM
&Scoped-define SECOND-TABLE-IN-QUERY-br-item item-ext


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-br-item}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS IMAGE-1 IMAGE-2 RECT-2 fi-item-ini ~
fi-item-fim bt-atualizar fi-descricao br-item 
&Scoped-Define DISPLAYED-OBJECTS fi-item-ini fi-item-fim fi-descricao ~
fi-dt-it-codigo fi-dt-desc-item fi-dt-gramatura ed-dt-narrativa 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR W-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-atualizar 
     IMAGE-UP FILE "image/im-chck1.bmp":U
     LABEL "Atualizar" 
     SIZE 4 BY 1.13.

DEFINE VARIABLE ed-dt-narrativa AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 81 BY 3.75
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-descricao AS CHARACTER FORMAT "X(256)":U 
     LABEL "Descricao" 
     VIEW-AS FILL-IN 
     SIZE 39.14 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-desc-item AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 52 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-gramatura AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     LABEL "Gramatura" 
     VIEW-AS FILL-IN 
     SIZE 7.86 BY .79 NO-UNDO.

DEFINE VARIABLE fi-dt-it-codigo AS CHARACTER FORMAT "X(256)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88 NO-UNDO.

DEFINE VARIABLE fi-item-fim AS CHARACTER FORMAT "X(256)":U INITIAL "999999" 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88 NO-UNDO.

DEFINE VARIABLE fi-item-ini AS CHARACTER FORMAT "X(256)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 83.14 BY 2.5.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 83.14 BY 5.92.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-item FOR 
      ITEM, 
      item-ext SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-item W-Win _FREEFORM
  QUERY br-item NO-LOCK DISPLAY
      item.it-codigo FORMAT "x(16)":U WIDTH 7
     item.desc-item FORMAT "x(60)":U WIDTH 60
     item-ext.gramatura COLUMN-LABEL "Gramatura" FORMAT ">>9.99":U WIDTH 12 COLUMN-FGCOLOR 1 COLUMN-FONT 0 LABEL-FGCOLOR 1
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ASSIGN NO-ROW-MARKERS SEPARATORS NO-TAB-STOP SIZE 83.14 BY 10.04
         FONT 1 ROW-HEIGHT-CHARS .58 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     fi-item-ini AT ROW 1.5 COL 21.86 COLON-ALIGNED WIDGET-ID 2
     fi-item-fim AT ROW 1.5 COL 46.86 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     bt-atualizar AT ROW 2.5 COL 80.57 WIDGET-ID 6
     fi-descricao AT ROW 2.63 COL 21.86 COLON-ALIGNED WIDGET-ID 22
     br-item AT ROW 3.96 COL 1.86 WIDGET-ID 200
     fi-dt-it-codigo AT ROW 14.25 COL 3.14 WIDGET-ID 26
     fi-dt-desc-item AT ROW 14.25 COL 15 NO-LABEL WIDGET-ID 28
     fi-dt-gramatura AT ROW 14.25 COL 74 COLON-ALIGNED WIDGET-ID 30
     ed-dt-narrativa AT ROW 16 COL 3 NO-LABEL WIDGET-ID 16
     "Narrativa" VIEW-AS TEXT
          SIZE 8.57 BY .67 AT ROW 15.33 COL 3.14 WIDGET-ID 18
     RECT-1 AT ROW 1.25 COL 1.86 WIDGET-ID 10
     IMAGE-1 AT ROW 1.5 COL 38.57 WIDGET-ID 12
     IMAGE-2 AT ROW 1.5 COL 45.57 WIDGET-ID 14
     RECT-2 AT ROW 14.08 COL 1.86 WIDGET-ID 32
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1 SCROLLABLE 
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
         TITLE              = "Gamatura do Item"
         HEIGHT             = 19.29
         WIDTH              = 85
         MAX-HEIGHT         = 30.04
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 30.04
         VIRTUAL-WIDTH      = 146.29
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
   FRAME-NAME Size-to-Fit                                               */
/* BROWSE-TAB br-item fi-descricao F-Main */
ASSIGN 
       FRAME F-Main:SCROLLABLE       = FALSE.

/* SETTINGS FOR EDITOR ed-dt-narrativa IN FRAME F-Main
   NO-ENABLE                                                            */
ASSIGN 
       ed-dt-narrativa:READ-ONLY IN FRAME F-Main        = TRUE.

/* SETTINGS FOR FILL-IN fi-dt-desc-item IN FRAME F-Main
   NO-ENABLE ALIGN-L                                                    */
/* SETTINGS FOR FILL-IN fi-dt-gramatura IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-dt-it-codigo IN FRAME F-Main
   NO-ENABLE ALIGN-L                                                    */
/* SETTINGS FOR RECTANGLE RECT-1 IN FRAME F-Main
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(W-Win)
THEN W-Win:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-item
/* Query rebuild information for BROWSE br-item
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ITEM WHERE ITEM.desc-item MATCHES var-descricao
                                               AND item.it-codigo >= fi-item-ini:screen-value in frame {&frame-name}
                                               AND item.it-codigo <= fi-item-fim:screen-value in frame {&frame-name}
                                               AND item.ge-codigo >= 50
                                               AND item.ge-codigo <= 60
                                               NO-LOCK,
             EACH espec.item-ext WHERE espec.item-ext.it-codigo = item.it-codigo NO-LOCK
    BY item.it-codigo INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _TblOptList       = ","
     _OrdList          = "item.it-codigo|yes"
     _Where[1]         = "item.it-codigo >= fi-item-ini:screen-value in frame {&frame-name}
 AND item.it-codigo <= fi-item-fim:screen-value in frame {&frame-name}"
     _JoinCode[2]      = "espec.item-ext.it-codigo = item.it-codigo"
     _Query            is OPENED
*/  /* BROWSE br-item */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON END-ERROR OF W-Win /* Gamatura do Item */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON WINDOW-CLOSE OF W-Win /* Gamatura do Item */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-item
&Scoped-define SELF-NAME br-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-item W-Win
ON MOUSE-SELECT-CLICK OF br-item IN FRAME F-Main
DO:
  ASSIGN ed-dt-narrativa:SCREEN-VALUE IN FRAME {&FRAME-NAME} = ITEM.narrativa
         fi-dt-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME} = ITEM.it-codigo
         fi-dt-desc-item:SCREEN-VALUE IN FRAME {&FRAME-NAME} = ITEM.desc-item
         fi-dt-gramatura:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(item-ext.gramatura).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-atualizar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-atualizar W-Win
ON CHOOSE OF bt-atualizar IN FRAME F-Main /* Atualizar */
DO:
    IF fi-descricao:screen-value in FRAME {&frame-name} <> "" THEN
       ASSIGN var-descricao = "*" + trim(fi-descricao:screen-value in FRAME {&frame-name}) + "*".
    ELSE
       ASSIGN var-descricao = "*".
    {&OPEN-QUERY-br-item}
    APPLY "mouse-select-click" TO br-item IN FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-descricao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-descricao W-Win
ON LEAVE OF fi-descricao IN FRAME F-Main /* Descricao */
DO:
  APPLY "CHOOSE" TO bt-atualizar IN FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-item-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-item-ini W-Win
ON LEAVE OF fi-item-ini IN FRAME F-Main /* Item */
DO:
  APPLY "CHOOSE" TO bt-atualizar IN FRAME {&FRAME-NAME}.

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
  DISPLAY fi-item-ini fi-item-fim fi-descricao fi-dt-it-codigo fi-dt-desc-item 
          fi-dt-gramatura ed-dt-narrativa 
      WITH FRAME F-Main IN WINDOW W-Win.
  ENABLE IMAGE-1 IMAGE-2 RECT-2 fi-item-ini fi-item-fim bt-atualizar 
         fi-descricao br-item 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize W-Win 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  APPLY "mouse-select-click" TO br-item IN FRAME {&FRAME-NAME}.

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
  {src/adm/template/snd-list.i "ITEM"}
  {src/adm/template/snd-list.i "item-ext"}

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

