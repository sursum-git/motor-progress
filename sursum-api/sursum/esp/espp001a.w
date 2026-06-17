&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS D-Dialog 
/*:T*******************************************************************************
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
DEF TEMP-TABLE tt-it-container LIKE pp-it-container
    FIELD preco-conv AS DECIMAL
    FIELD preco-tab AS DECIMAL
    FIELD marca AS LOGICAL.

DEF BUFFER b-tt-it-container FOR tt-it-container.

/* Parameters Definitions ---                                           */
//DEF INPUT PARAMETER p-nr-container LIKE pp-container.nr-container.
DEF VAR p-nr-container AS INT INIT 231821.

/* Local Variable Definitions ---                                       */
DEF VAR h-objeto         AS HANDLE.
DEF VAR hBoControlePreco AS HANDLE NO-UNDO.

DEF VAR de-vlReal AS DEC.
DEF VAR de-vlDolar AS DEC.

DEF VAR i-ControlePreco AS INT.
DEF VAR i-font AS INT.
DEF VAR i-cor  AS INT.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME D-Dialog
&Scoped-define BROWSE-NAME br-itens

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-it-container

/* Definitions for BROWSE br-itens                                      */
&Scoped-define FIELDS-IN-QUERY-br-itens tt-it-container.it-codigo tt-it-container.desc-item tt-it-container.cod-refer tt-it-container.preco-vd-dolar tt-it-container.preco-conv tt-it-container.preco-tab   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-itens   
&Scoped-define SELF-NAME br-itens
&Scoped-define QUERY-STRING-br-itens FOR EACH tt-it-container NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-itens OPEN QUERY {&SELF-NAME} FOR EACH tt-it-container NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-itens tt-it-container
&Scoped-define FIRST-TABLE-IN-QUERY-br-itens tt-it-container


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-itens}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom RECT-8 br-itens bt-marca ~
bt-desmarca bt-todos bt-nenhum bt-vencer bt-novo-preo bt-ok bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-nr-container fi-ptax 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-1 bt-marca bt-desmarca bt-todos bt-nenhum 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "&Ajuda" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-desmarca 
     IMAGE-UP FILE "image/im-cllps.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Desmarca Pedido"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-marca 
     IMAGE-UP FILE "image/im-expan.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Marca Pedido"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-nenhum 
     IMAGE-UP FILE "image/im-nenhum.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Desmarca TODOS os Pedidos"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-novo-preo 
     LABEL "Inserir Novo Pre‡o na Tabela" 
     SIZE 27 BY 1.25.

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&Sair" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-todos 
     IMAGE-UP FILE "image\im-ran_a.bmp":U
     LABEL "" 
     SIZE 5 BY 1.25 TOOLTIP "Marca TODOS os Pedidos"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-vencer 
     LABEL "Vencer Pre‡os" 
     SIZE 15 BY 1.25.

DEFINE VARIABLE fi-nr-container AS CHARACTER FORMAT "X(256)":U 
     LABEL "Container" 
     VIEW-AS FILL-IN 
     SIZE 8.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-ptax AS DECIMAL FORMAT ">>9.999999" INITIAL 0 
     LABEL "Ptax" 
     VIEW-AS FILL-IN 
     SIZE 8.29 BY .88.

DEFINE RECTANGLE RECT-8
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 93 BY 1.5.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 93 BY 1.42
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-itens FOR 
      tt-it-container SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-itens
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-itens D-Dialog _FREEFORM
  QUERY br-itens NO-LOCK DISPLAY
      tt-it-container.it-codigo    FORMAT "X(10)":U
      tt-it-container.desc-item    FORMAT "X(40)":U   WIDTH 40
      tt-it-container.cod-refer    
      tt-it-container.preco-vd-dolar                  COLUMN-LABEL "Pre‡o US$"   WIDTH 10
      tt-it-container.preco-conv                      COLUMN-LABEL "Pre‡o CONV"  WIDTH 10
      tt-it-container.preco-tab                       COLUMN-LABEL "Pre‡o TAB"   WIDTH 10
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 93 BY 11.75
         FONT 1
         TITLE "Itens do Container".


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     fi-nr-container AT ROW 1.5 COL 12 COLON-ALIGNED WIDGET-ID 2
     fi-ptax AT ROW 1.5 COL 38 COLON-ALIGNED WIDGET-ID 6
     br-itens AT ROW 3 COL 2 WIDGET-ID 200
     bt-marca AT ROW 15 COL 2 WIDGET-ID 32
     bt-desmarca AT ROW 15 COL 7 WIDGET-ID 28
     bt-todos AT ROW 15 COL 12 WIDGET-ID 38
     bt-nenhum AT ROW 15 COL 17 WIDGET-ID 36
     bt-vencer AT ROW 15 COL 27 WIDGET-ID 40
     bt-novo-preo AT ROW 15 COL 43 WIDGET-ID 44
     bt-ok AT ROW 16.63 COL 3
     bt-ajuda AT ROW 16.63 COL 84.14
     "Pre‡o convertido MAIOR que Pre‡o Vigente" VIEW-AS TEXT
          SIZE 38 BY .54 AT ROW 2 COL 54 WIDGET-ID 48
          FGCOLOR 2 FONT 6
     "Pre‡o convertido MENOR que Pre‡o Vigente" VIEW-AS TEXT
          SIZE 38 BY .54 AT ROW 1.38 COL 54 WIDGET-ID 46
          FGCOLOR 12 FONT 6
     rt-buttom AT ROW 16.38 COL 2
     RECT-8 AT ROW 1.25 COL 2 WIDGET-ID 8
     SPACE(1.13) SKIP(15.20)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Ajuste de Pre‡o PE dos Itens do Container - espp001a.w"
         DEFAULT-BUTTON bt-ok WIDGET-ID 100.


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
/* BROWSE-TAB br-itens fi-ptax D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR BUTTON bt-desmarca IN FRAME D-Dialog
   1                                                                    */
/* SETTINGS FOR BUTTON bt-marca IN FRAME D-Dialog
   1                                                                    */
/* SETTINGS FOR BUTTON bt-nenhum IN FRAME D-Dialog
   1                                                                    */
/* SETTINGS FOR BUTTON bt-todos IN FRAME D-Dialog
   1                                                                    */
/* SETTINGS FOR FILL-IN fi-nr-container IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-ptax IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-itens
/* Query rebuild information for BROWSE br-itens
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-it-container NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-itens */
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Ajuste de Pre‡o PE dos Itens do Container - espp001a.w */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-itens
&Scoped-define SELF-NAME br-itens
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-itens D-Dialog
ON ROW-DISPLAY OF br-itens IN FRAME D-Dialog /* Itens do Container */
DO:
    ASSIGN i-font = ?
           i-cor = ?.

    IF tt-it-container.preco-vd-dolar < tt-it-container.preco-tab THEN
       ASSIGN i-cor = 12.

    IF tt-it-container.preco-vd-dolar > tt-it-container.preco-tab THEN
       ASSIGN i-cor = 2.

    IF tt-it-container.marca THEN
       ASSIGN i-font = 6.

    ASSIGN tt-it-container.it-codigo:FONT IN BROWSE br-itens = i-font
           tt-it-container.desc-item:FONT IN BROWSE br-itens = i-font   
           tt-it-container.cod-refer:FONT IN BROWSE br-itens = i-font 
           tt-it-container.preco-vd-dolar:FONT IN BROWSE br-itens = i-font 
           tt-it-container.preco-conv:FONT IN BROWSE br-itens = i-font  
           tt-it-container.preco-tab:FONT IN BROWSE br-itens = i-font.   

    ASSIGN tt-it-container.it-codigo:FGCOLOR IN BROWSE br-itens = i-cor
           tt-it-container.desc-item:FGCOLOR IN BROWSE br-itens = i-cor   
           tt-it-container.cod-refer:FGCOLOR IN BROWSE br-itens = i-cor   
           tt-it-container.preco-vd-dolar:FGCOLOR IN BROWSE br-itens = i-cor 
           tt-it-container.preco-conv:FGCOLOR IN BROWSE br-itens = i-cor  
           tt-it-container.preco-tab:FGCOLOR IN BROWSE br-itens = i-cor.   

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


&Scoped-define SELF-NAME bt-desmarca
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-desmarca D-Dialog
ON CHOOSE OF bt-desmarca IN FRAME D-Dialog
DO:
  ASSIGN tt-it-container.marca = NO.
  br-itens:REFRESH().
  APPLY 'VALUE-CHANGED' TO br-itens IN FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-marca
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-marca D-Dialog
ON CHOOSE OF bt-marca IN FRAME D-Dialog
DO:
   ASSIGN tt-it-container.marca = YES.

   APPLY 'VALUE-CHANGED' TO br-itens.
   br-itens:REFRESH().
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-nenhum
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-nenhum D-Dialog
ON CHOOSE OF bt-nenhum IN FRAME D-Dialog
DO:
    FOR EACH b-tt-it-container NO-LOCK. 
        ASSIGN b-tt-it-container.marca = NO.
    END.
    {&OPEN-QUERY-br-itens}
    APPLY 'VALUE-CHANGED' TO br-itens.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-novo-preo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-novo-preo D-Dialog
ON CHOOSE OF bt-novo-preo IN FRAME D-Dialog /* Inserir Novo Pre‡o na Tabela */
DO:
    MESSAGE 'Confirma Pre‡o dos Itens Selecionados ? ' 
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE l-conf-preco AS LOGICAL.
    IF NOT l-conf-preco THEN RETURN NO-APPLY.

    FIND b-tt-it-container WHERE
         b-tt-it-container.marca = YES AND
         b-tt-it-container.preco-tab >= b-tt-it-container.preco-conv NO-ERROR.
    IF AVAIL b-tt-it-container THEN DO.
       MESSAGE 'Existem Itens Selecionados com' SKIP
               'Pre‡o Vigente maior que o Pre‡o Convertido...' SKIP(1)
               'Novo Pre‡o nao Permitido !!!' 
           VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Execu‡Æo nao Permitida !!!".

       RETURN NO-APPLY.
    END.

    FOR EACH b-tt-it-container WHERE 
             b-tt-it-container.marca = YES.

        RUN pi-novo-preco.

        ASSIGN b-tt-it-container.marca = NO
               b-tt-it-container.preco-tab = b-tt-it-container.preco-conv.
    END.

    MESSAGE 'Pre‡o dos Itens, Inseridos com Sucesso...' 
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

    {&OPEN-QUERY-br-itens}
    APPLY 'VALUE-CHANGED' TO br-itens.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-todos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-todos D-Dialog
ON CHOOSE OF bt-todos IN FRAME D-Dialog
DO:
   FOR EACH b-tt-it-container NO-LOCK. 
       ASSIGN b-tt-it-container.marca = YES.
   END.
   {&OPEN-QUERY-br-itens}

   APPLY 'VALUE-CHANGED' TO br-itens.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vencer
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vencer D-Dialog
ON CHOOSE OF bt-vencer IN FRAME D-Dialog /* Vencer Pre‡os */
DO:
    MESSAGE 'Confirma Vencer Pre‡o dos Itens Selecionados ? ' 
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE l-conf-venc AS LOGICAL.
    IF NOT l-conf-venc THEN RETURN NO-APPLY.

    /*
    FIND b-tt-it-container WHERE
         b-tt-it-container.marca = YES AND
         b-tt-it-container.preco-conv > b-tt-it-container.preco-tab NO-ERROR.
    IF AVAIL b-tt-it-container THEN DO.
       MESSAGE 'Existem Itens Selecionados com' SKIP
               'Pre‡o Convertido MAIOR que o Pre‡o Vigente...' SKIP(1)
               'Execu‡äa nao Permitida !!!' 
           VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Execu‡Æo nao Permitida !!!".

       RETURN NO-APPLY.
    END.
    */
    FOR EACH b-tt-it-container WHERE 
             b-tt-it-container.marca = YES.

        RUN pi-vencer-preco.

        ASSIGN b-tt-it-container.marca = NO
               b-tt-it-container.preco-tab = 0.
    END.

    MESSAGE 'Pre‡o dos Itens, Vencidos com Sucesso...' 
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

    {&OPEN-QUERY-br-itens}
    APPLY 'VALUE-CHANGED' TO br-itens.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

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
  DISPLAY fi-nr-container fi-ptax 
      WITH FRAME D-Dialog.
  ENABLE rt-buttom RECT-8 br-itens bt-marca bt-desmarca bt-todos bt-nenhum 
         bt-vencer bt-novo-preo bt-ok bt-ajuda 
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

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  ASSIGN rt-buttom:BGCOLOR IN FRAME {&FRAME-NAME} = 7.

  ASSIGN h-objeto = FRAME D-Dialog:FIRST-CHILD.
  ASSIGN h-objeto = h-objeto:FIRST-CHILD.
  DO WHILE VALID-HANDLE(h-objeto):
     IF h-objeto:TYPE = 'LITERAL' THEN DO.
        IF h-objeto:ROW >= 1 AND h-objeto:ROW <= 5 AND
           h-objeto:COL = 54  THEN
           ASSIGN h-objeto:FONT = 6.
     END.
     ASSIGN h-objeto = h-objeto:NEXT-SIBLING.
  END.

  FIND pp-container WHERE
       pp-container.nr-container = p-nr-container NO-LOCK NO-ERROR.

  ASSIGN fi-nr-container:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(pp-container.nr-container)
         fi-ptax:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(pp-container.ptax).

  FOR EACH pp-it-container OF pp-container NO-LOCK.
      CREATE tt-it-container.
      BUFFER-COPY pp-it-container TO tt-it-container.

      ASSIGN tt-it-container.preco-conv = pp-it-container.preco-vd-dolar * pp-container.ptax.

      RUN pi-busca-preco (INPUT  pp-it-container.it-codigo,
                          INPUT  pp-it-container.cod-refer,
                          INPUT  "PE", // Campanha
                          OUTPUT de-vlReal,  
                          OUTPUT de-vlDolar,
                          OUTPUT i-ControlePreco).

      ASSIGN tt-it-container.preco-tab = de-vlReal.
  END.

  {&OPEN-QUERY-br-itens}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-busca-preco D-Dialog 
PROCEDURE pi-busca-preco :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT  PARAMETER p-it-codigo AS CHAR.
    DEF INPUT  PARAMETER p-cod-refer AS CHAR.
    DEF INPUT  PARAMETER p-campanha  AS CHAR.
    DEF OUTPUT PARAMETER p-vlReal    AS DECIMAL NO-UNDO. 
    DEF OUTPUT PARAMETER p-vlDolar   AS DECIMAL NO-UNDO.
    DEF OUTPUT PARAMETER p-ControlePreco   AS INTEGER.

    DEF VAR i-prazo-medio AS INT INIT 0.

    DEF VAR h-boPrecosItemRef        AS HANDLE    NO-UNDO.
    DEF VAR i-tp-busca  AS INT.

    ASSIGN i-tp-busca = 1.  // PE

    RUN esbo/boPrecosItemRef.p PERSISTENT SET h-boPrecosItemRef.

    RUN iniciarBos      IN h-boPrecosItemRef.
    RUN limparTTPreco   IN h-boPrecosItemRef.
    RUN limparTTMsg     IN h-boPrecosItemRef.
    RUN setTbPreco      IN h-boPrecosItemRef (INPUT 1). 
    RUN setItem         IN h-boPrecosItemRef (INPUT p-it-codigo). 
    RUN setRef          IN h-boPrecosItemRef (INPUT p-cod-refer). 
//    RUN setNrContainer  IN h-boPrecosItemRef (INPUT ped-venda-ext.nr-container).
    RUN setTipoBusca    IN h-boPrecosItemRef (INPUT i-tp-busca). 
    RUN setPrazoMedio   IN h-boPrecosItemRef (INPUT i-prazo-medio).
//    RUN setDtRefer      IN h-boPrecosItemRef (INPUT ped-venda.dt-implant).

    RUN buscarPrecos    IN h-boPrecosItemRef.

    RUN getPrecoPrazo   IN h-boPrecosItemRef (INPUT  p-campanha,
                                              OUTPUT p-vlReal,
                                              OUTPUT p-vlDolar,
                                              OUTPUT p-ControlePreco).

    RUN finalizarBos IN h-boPrecosItemRef.
    IF VALID-HANDLE(h-boPrecosItemRef) THEN
       DELETE PROCEDURE h-boPrecosItemRef.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-novo-preco D-Dialog 
PROCEDURE pi-novo-preco :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF VAR de-vlReal  AS DEC.
    DEF VAR de-vlDolar AS DEC.
    
    RUN esbo/boControlePreco.p PERSISTENT SET hBoControlePreco.
    
    ASSIGN de-vlreal = b-tt-it-container.preco-conv
           de-vldolar = 0.
    
    
    RUN setTbPreco          IN hBoControlePreco(1).   // 1-pe, 2-pi, 3-outlet
    RUN setTpPreco          IN hBoControlePreco(1).   // 1-padrao 2-rubi                
    RUN setNivel            IN hBoControlePreco(1).   // 1-item, 2-referencia
    RUN setDtInicio         IN hBoControlePreco(TODAY).
    RUN setDtFinal          IN hBoControlePreco(12.31.9999).
    RUN setItem             IN hBoControlePreco (b-tt-it-container.it-codigo).
    RUN inserirPreco        IN hBoControlePreco (de-vlReal, 
                                                 de-vlDolar). 
    
    RUN finalizarBos IN hBoControlePreco.
    IF VALID-HANDLE(hBoControlePreco) THEN
       DELETE PROCEDURE hBoControlePreco.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-vencer-preco D-Dialog 
PROCEDURE pi-vencer-preco :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    RUN esbo/boControlePreco.p PERSISTENT SET hBoControlePreco.
    
    RUN setTbPreco          IN hBoControlePreco(1).   // 1-pe, 2-pi, 3-outlet
    RUN setTpPreco          IN hBoControlePreco(1).   // 1-padrao 2-rubi                
    RUN setNivel            IN hBoControlePreco(1).   // 1-item, 2-referencia
    RUN setItem             IN hBoControlePreco (b-tt-it-container.it-codigo).
    RUN vencerPreco         IN hBoControlePreco (TODAY + 1).

    RUN finalizarBos IN hBoControlePreco.
    IF VALID-HANDLE(hBoControlePreco) THEN
       DELETE PROCEDURE hBoControlePreco.

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
  {src/adm/template/snd-list.i "tt-it-container"}

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

