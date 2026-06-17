&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS D-Dialog 
/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i D99XX999 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
DEFINE TEMP-TABLE tt-ref-item
       FIELD cod-refer   LIKE saldo-estoq.cod-refer
       FIELD qtidade-atu LIKE saldo-estoq.qtidade-atu
       FIELD preco-un    LIKE preco-item.preco-venda
       FIELD qt-pedida   LIKE ped-item.qt-pedida
       FIELD vl-tot-ref  AS   DEC FORMAT ">>>,>>>,>>9.9999"
       FIELD cod-depos   LIKE saldo-estoq.cod-depos
       INDEX indice1 cod-refer.

DEFINE INPUT-OUTPUT PARAMETER TABLE FOR tt-ref-item.  
DEFINE INPUT  PARAMETER p-it-codigo    LIKE ITEM.it-codigo.
DEFINE INPUT  PARAMETER p-tab-preco    LIKE preco-item.nr-tabpre.
DEFINE INPUT  PARAMETER p-ind-finan AS DEC.
DEFINE INPUT  PARAMETER p-cod-estabel  LIKE saldo-estoq.cod-estabel.
DEFINE INPUT  PARAMETER p-nr-container LIKE pp-container.nr-container.
DEFINE INPUT  PARAMETER p-tp-preco    AS CHAR.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME D-Dialog
&Scoped-define BROWSE-NAME br-ref-item

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-ref-item

/* Definitions for BROWSE br-ref-item                                   */
&Scoped-define FIELDS-IN-QUERY-br-ref-item tt-ref-item.cod-refer tt-ref-item.qtidade-atu tt-ref-item.qt-pedida tt-ref-item.preco-un tt-ref-item.vl-tot-ref   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-ref-item tt-ref-item.qt-pedida   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-ref-item tt-ref-item
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-ref-item tt-ref-item
&Scoped-define SELF-NAME br-ref-item
&Scoped-define QUERY-STRING-br-ref-item FOR EACH tt-ref-item NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-ref-item OPEN QUERY {&SELF-NAME} FOR EACH tt-ref-item NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-ref-item tt-ref-item
&Scoped-define FIRST-TABLE-IN-QUERY-br-ref-item tt-ref-item


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-ref-item}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-5 bt-exp-preco rt-buttom fi-cod-refer ~
fi-quantidade fi-valor-un br-ref-item bt-exp-qtde bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-it-codigo fi-desc-item fi-cod-refer ~
fi-quantidade fi-valor-un fi-tot-estoq fi-tot-qt-pedida fi-vlr-total 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "&Ajuda" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-cancela AUTO-END-KEY 
     LABEL "&Cancelar" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-exp-preco 
     IMAGE-UP FILE "image/im-raneg.bmp":U NO-FOCUS
     LABEL "Button 3" 
     SIZE 4 BY 1.21 TOOLTIP "Exporta Pre‡o para todas Referˆncias".

DEFINE BUTTON bt-exp-qtde 
     IMAGE-UP FILE "image/im-aloca.bmp":U NO-FOCUS
     LABEL "Button 2" 
     SIZE 4 BY 1.21 TOOLTIP "Exporta Quantidade para todas Referˆncias".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-cod-refer AS CHARACTER FORMAT "X(256)":U 
     LABEL "Referˆncia" 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-item AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 45.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-it-codigo AS CHARACTER FORMAT "X(256)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-quantidade AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     LABEL "Quantidade" 
     VIEW-AS FILL-IN 
     SIZE 8.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tot-estoq AS DECIMAL FORMAT "-ZZZ,ZZZ,ZZZ,ZZ9.9999" INITIAL 0 
      VIEW-AS TEXT 
     SIZE 12.43 BY .67
     FGCOLOR 12  NO-UNDO.

DEFINE VARIABLE fi-tot-qt-pedida AS DECIMAL FORMAT "-ZZ,ZZZ,ZZZ,ZZ9.9999" INITIAL 0 
      VIEW-AS TEXT 
     SIZE 12 BY .67
     FGCOLOR 12  NO-UNDO.

DEFINE VARIABLE fi-valor-un AS DECIMAL FORMAT ">>>,>>9.9999":U INITIAL 0 
     LABEL "Pre‡o" 
     VIEW-AS FILL-IN 
     SIZE 8.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-vlr-total AS DECIMAL FORMAT "-ZZZ,ZZZ,ZZZ,ZZ9.9999" INITIAL 0 
      VIEW-AS TEXT 
     SIZE 12.43 BY .67
     FGCOLOR 12  NO-UNDO.

DEFINE RECTANGLE RECT-5
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 68 BY 2.5.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 68 BY 1.42
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-ref-item FOR 
      tt-ref-item SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-ref-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-ref-item D-Dialog _FREEFORM
  QUERY br-ref-item NO-LOCK DISPLAY
      tt-ref-item.cod-refer   COLUMN-LABEL "Referˆncias"
      tt-ref-item.qtidade-atu COLUMN-LABEL "Qtde Estoque"
      tt-ref-item.qt-pedida   COLUMN-LABEL "Qtde Pedida"
      tt-ref-item.preco-un    FORMAT ">>>,>>9.99" COLUMN-LABEL "Preco Un"
      tt-ref-item.vl-tot-ref  COLUMN-LABEL "Total"
ENABLE
     tt-ref-item.qt-pedida
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 68 BY 10
         FONT 1.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     bt-exp-preco AT ROW 2.17 COL 65
     fi-it-codigo AT ROW 1.25 COL 10 COLON-ALIGNED
     fi-desc-item AT ROW 1.25 COL 21.43 COLON-ALIGNED NO-LABEL
     fi-cod-refer AT ROW 2.38 COL 10 COLON-ALIGNED
     fi-quantidade AT ROW 2.38 COL 31 COLON-ALIGNED NO-TAB-STOP 
     fi-valor-un AT ROW 2.38 COL 53.86 COLON-ALIGNED
     br-ref-item AT ROW 3.75 COL 2
     bt-exp-qtde AT ROW 2.17 COL 42
     bt-ok AT ROW 14.92 COL 3
     bt-cancela AT ROW 14.92 COL 14
     bt-ajuda AT ROW 14.92 COL 59
     fi-tot-estoq AT ROW 13.88 COL 9.72 COLON-ALIGNED NO-LABEL
     fi-tot-qt-pedida AT ROW 13.88 COL 22.14 COLON-ALIGNED NO-LABEL
     fi-vlr-total AT ROW 13.88 COL 43 COLON-ALIGNED NO-LABEL
     RECT-5 AT ROW 1 COL 2
     rt-buttom AT ROW 14.67 COL 2
     SPACE(0.85) SKIP(0.15)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Digita‡Æo R pida de Itens"
         DEFAULT-BUTTON bt-ok.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartDialog
   Allow: Basic,Browse,DB-Fields,Query,Smart
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB D-Dialog 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/d-dialog.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR DIALOG-BOX D-Dialog
   FRAME-NAME L-To-R                                                    */
/* BROWSE-TAB br-ref-item fi-valor-un D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN fi-desc-item IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-it-codigo IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-estoq IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qt-pedida IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-vlr-total IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-ref-item
/* Query rebuild information for BROWSE br-ref-item
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-ref-item NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-ref-item */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK DIALOG-BOX D-Dialog
/* Query rebuild information for DIALOG-BOX D-Dialog
     _Options          = "SHARE-LOCK"
     _Query            is NOT OPENED
*/  /* DIALOG-BOX D-Dialog */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL D-Dialog D-Dialog
ON WINDOW-CLOSE OF FRAME D-Dialog /* Digita‡Æo R pida de Itens */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-ref-item
&Scoped-define SELF-NAME br-ref-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-ref-item D-Dialog
ON ROW-DISPLAY OF br-ref-item IN FRAME D-Dialog
DO:
  ASSIGN tt-ref-item.vl-tot-ref = ROUND(tt-ref-item.qt-pedida * tt-ref-item.preco-un,2).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda D-Dialog
ON CHOOSE OF bt-ajuda IN FRAME D-Dialog /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO: /* Call Help Function (or a simple message). */
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancela
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancela D-Dialog
ON CHOOSE OF bt-cancela IN FRAME D-Dialog /* Cancelar */
DO:
  FOR EACH tt-ref-item.
      DELETE tt-ref-item.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-exp-preco
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exp-preco D-Dialog
ON CHOOSE OF bt-exp-preco IN FRAME D-Dialog /* Button 3 */
DO:
   FOR EACH tt-ref-item.
       ASSIGN tt-ref-item.preco-un = INPUT FRAME {&FRAME-NAME} fi-valor-un.
   END.
   {&OPEN-QUERY-br-ref-item}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-exp-qtde
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exp-qtde D-Dialog
ON CHOOSE OF bt-exp-qtde IN FRAME D-Dialog /* Button 2 */
DO:
  FOR EACH tt-ref-item.
      ASSIGN tt-ref-item.qt-pedida = IF INPUT FRAME {&FRAME-NAME} fi-quantidade <= tt-ref-item.qtidade-atu
                                     THEN INPUT FRAME {&FRAME-NAME} fi-quantidade
                                     ELSE tt-ref-item.qtidade-atu.
  END.
  {&OPEN-QUERY-br-ref-item}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-refer
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer D-Dialog
ON LEAVE OF fi-cod-refer IN FRAME D-Dialog /* Referˆncia */
DO:
    IF fi-quantidade:INPUT-VALUE <> 0 THEN DO.
       ASSIGN tt-ref-item.qt-pedida = fi-quantidade:INPUT-VALUE.
       DISP tt-ref-item.qt-pedida WITH BROWSE br-ref-item.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer D-Dialog
ON RETURN OF fi-cod-refer IN FRAME D-Dialog /* Referˆncia */
DO:
  APPLY 'entry' TO tt-ref-item.qt-pedida IN BROWSE br-ref-item.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-refer D-Dialog
ON VALUE-CHANGED OF fi-cod-refer IN FRAME D-Dialog /* Referˆncia */
DO:
  FIND FIRST tt-ref-item WHERE
       tt-ref-item.cod-refer BEGINS SELF:SCREEN-VALUE NO-LOCK NO-ERROR.
  IF AVAIL tt-ref-item THEN
     br-ref-item:QUERY:REPOSITION-TO-ROWID(ROWID(tt-ref-item)).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-tot-estoq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tot-estoq D-Dialog
ON LEAVE OF fi-tot-estoq IN FRAME D-Dialog
DO:
  APPLY 'entry' TO br-ref-item.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tot-estoq D-Dialog
ON VALUE-CHANGED OF fi-tot-estoq IN FRAME D-Dialog
DO:
  FIND FIRST tt-ref-item WHERE
       tt-ref-item.cod-refer BEGINS SELF:SCREEN-VALUE NO-LOCK NO-ERROR.
  IF AVAIL tt-ref-item THEN
     br-ref-item:QUERY:REPOSITION-TO-ROWID(ROWID(tt-ref-item)).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-tot-qt-pedida
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tot-qt-pedida D-Dialog
ON LEAVE OF fi-tot-qt-pedida IN FRAME D-Dialog
DO:
  APPLY 'entry' TO br-ref-item.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-tot-qt-pedida D-Dialog
ON VALUE-CHANGED OF fi-tot-qt-pedida IN FRAME D-Dialog
DO:
  FIND FIRST tt-ref-item WHERE
       tt-ref-item.cod-refer BEGINS SELF:SCREEN-VALUE NO-LOCK NO-ERROR.
  IF AVAIL tt-ref-item THEN
     br-ref-item:QUERY:REPOSITION-TO-ROWID(ROWID(tt-ref-item)).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-vlr-total
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-vlr-total D-Dialog
ON LEAVE OF fi-vlr-total IN FRAME D-Dialog
DO:
  APPLY 'entry' TO br-ref-item.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-vlr-total D-Dialog
ON VALUE-CHANGED OF fi-vlr-total IN FRAME D-Dialog
DO:
  FIND FIRST tt-ref-item WHERE
       tt-ref-item.cod-refer BEGINS SELF:SCREEN-VALUE NO-LOCK NO-ERROR.
  IF AVAIL tt-ref-item THEN
     br-ref-item:QUERY:REPOSITION-TO-ROWID(ROWID(tt-ref-item)).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

ON 'RETURN':U ANYWHERE DO:
    APPLY 'TAB' TO SELF.
    RETURN NO-APPLY.
END.

ON 'LEAVE':U OF tt-ref-item.qt-pedida IN BROWSE {&browse-name} DO:
    IF tt-ref-item.qt-pedida:INPUT-VALUE IN BROWSE {&browse-name} > tt-ref-item.qtidade-atu THEN DO.
       MESSAGE 'Quantidade Pedida maior que Dispon¡vel em Estoque...'
           VIEW-AS ALERT-BOX INFO BUTTONS OK.
       APPLY 'entry' TO SELF.
       RETURN NO-APPLY.
    END.
    ASSIGN fi-vlr-total = fi-vlr-total - tt-ref-item.vl-tot-ref
           fi-tot-qt-pedida = fi-tot-qt-pedida - tt-ref-item.qt-pedida   
           tt-ref-item.vl-tot-ref = tt-ref-item.qt-pedida:INPUT-VALUE IN BROWSE {&browse-name} *
                                       tt-ref-item.preco-un.
    DISP tt-ref-item.vl-tot-ref WITH BROWSE {&browse-name}.


    ASSIGN fi-vlr-total = fi-vlr-total + tt-ref-item.vl-tot-ref
           fi-tot-qt-pedida = fi-tot-qt-pedida + tt-ref-item.qt-pedida:INPUT-VALUE IN BROWSE {&browse-name}.

    DISP fi-tot-qt-pedida
         fi-vlr-total 
         WITH FRAME {&FRAME-NAME}.
END.

ON 'RETURN':U OF tt-ref-item.qt-pedida IN BROWSE {&browse-name} DO:
    APPLY 'entry' TO fi-cod-refer IN FRAME {&FRAME-NAME}.
    RETURN NO-APPLY.
END.

{src/adm/template/dialogmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects D-Dialog  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available D-Dialog  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI D-Dialog  _DEFAULT-DISABLE
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
  HIDE FRAME D-Dialog.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI D-Dialog  _DEFAULT-ENABLE
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
  DISPLAY fi-it-codigo fi-desc-item fi-cod-refer fi-quantidade fi-valor-un 
          fi-tot-estoq fi-tot-qt-pedida fi-vlr-total 
      WITH FRAME D-Dialog.
  ENABLE RECT-5 bt-exp-preco rt-buttom fi-cod-refer fi-quantidade fi-valor-un 
         br-ref-item bt-exp-qtde bt-ok bt-cancela bt-ajuda 
      WITH FRAME D-Dialog.
  VIEW FRAME D-Dialog.
  {&OPEN-BROWSERS-IN-QUERY-D-Dialog}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy D-Dialog 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize D-Dialog 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

    /* Code placed here will execute PRIOR to standard behavior. */

    /*{utp/ut9000.i "D99XX999" "9.99.99.999"} */
    
    /* Dispatch standard ADM method.                             */
    RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

    /* Code placed here will execute AFTER standard behavior.    */
    IF p-tp-preco = "1" THEN
       ASSIGN fi-valor-un:SENSITIVE IN FRAME {&FRAME-NAME} = YES
              bt-exp-preco:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
    ELSE
      ASSIGN  fi-valor-un:SENSITIVE IN FRAME {&FRAME-NAME} = NO
              bt-exp-preco:SENSITIVE IN FRAME {&FRAME-NAME} = NO. 

    ASSIGN fi-it-codigo:SCREEN-VALUE IN FRAME {&FRAME-NAME} = p-it-codigo.
    FIND ITEM WHERE
         ITEM.it-codigo = p-it-codigo NO-LOCK NO-ERROR.
    IF AVAIL ITEM THEN
       ASSIGN fi-desc-item:SCREEN-VALUE IN FRAME {&FRAME-NAME} = ITEM.desc-item.
    FOR EACH pp-it-container WHERE
             pp-it-container.nr-container = p-nr-container   AND 
             pp-it-container.it-comprado  = p-it-codigo /*ITEM.it-codigo*/.
        FIND tt-ref-item WHERE
             tt-ref-item.cod-refer = pp-it-container.ref-comprada NO-LOCK NO-ERROR.
        IF NOT AVAIL tt-ref-item THEN DO.
           CREATE tt-ref-item.
           ASSIGN tt-ref-item.cod-refer = pp-it-container.ref-comprada.
        END.  
        ASSIGN tt-ref-item.qtidade-atu = pp-it-container.qt-pedida - pp-it-container.qt-vendida.
        FIND preco-item WHERE
             preco-item.nr-tabpre = p-tab-preco AND
             preco-item.it-codigo = pp-it-container.it-comprado AND
             preco-item.cod-refer = pp-it-container.ref-comprada
             NO-LOCK NO-ERROR.

        IF AVAIL preco-item THEN
           ASSIGN tt-ref-item.preco-un = ROUND(preco-item.preco-venda * p-ind-finan,2).
        ELSE
           ASSIGN tt-ref-item.preco-un = ROUND(pp-it-container.preco-venda * p-ind-finan,2).
    END.

    FOR EACH tt-ref-item.
        ASSIGN fi-tot-estoq = fi-tot-estoq + tt-ref-item.qtidade-atu.

        IF tt-ref-item.qtidade-atu = 0 THEN
           DELETE tt-ref-item.
    END. 
    DISP fi-tot-estoq WITH FRAME {&FRAME-NAME}.
    {&OPEN-QUERY-br-ref-item}

    FIND FIRST tt-ref-item NO-LOCK NO-ERROR.
    IF AVAIL tt-ref-item THEN
       ASSIGN fi-cod-refer:SCREEN-VALUE IN FRAME {&FRAME-NAME} = tt-ref-item.cod-refer. 

    

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records D-Dialog  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-ref-item"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed D-Dialog 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
  
  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

