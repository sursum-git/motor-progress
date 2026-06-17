&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-livre 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i esce500 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

{esbo/boSaldo.i}

DEFINE VARIABLE hboSaldo AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoParam AS HANDLE      NO-UNDO.

DEFINE VARIABLE qtMinKG  AS DECIMAL     NO-UNDO.
DEFINE VARIABLE qtMinMt  AS DECIMAL     NO-UNDO.
DEFINE VARIABLE qtMinima AS DECIMAL     NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME BROWSE-2

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttSaldo ttPedidosEmAberto

/* Definitions for BROWSE BROWSE-2                                      */
&Scoped-define FIELDS-IN-QUERY-BROWSE-2 ttSaldo.codRefer ttSaldo.qtSaldoPE ttSaldo.qtDeposFechado ttSaldo.qtSaldoPI ttSaldo.qtSaldoPISemPerc ttSaldo.qtPedidaPE ttSaldo.qtPedidaPI ttSaldo.qtCarrinhoPE ttSaldo.qtCarrinhoLoginPE ttSaldo.qtCarrinhoPI ttSaldo.qtCarrinhoLoginPI   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BROWSE-2   
&Scoped-define SELF-NAME BROWSE-2
&Scoped-define QUERY-STRING-BROWSE-2 FOR EACH ttSaldo
&Scoped-define OPEN-QUERY-BROWSE-2 OPEN QUERY {&SELF-NAME} FOR EACH ttSaldo.
&Scoped-define TABLES-IN-QUERY-BROWSE-2 ttSaldo
&Scoped-define FIRST-TABLE-IN-QUERY-BROWSE-2 ttSaldo


/* Definitions for BROWSE BROWSE-3                                      */
&Scoped-define FIELDS-IN-QUERY-BROWSE-3   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BROWSE-3   
&Scoped-define SELF-NAME BROWSE-3
&Scoped-define QUERY-STRING-BROWSE-3 FOR EACH ttPedidosEmAberto
&Scoped-define OPEN-QUERY-BROWSE-3 OPEN QUERY {&SELF-NAME} FOR EACH ttPedidosEmAberto.
&Scoped-define TABLES-IN-QUERY-BROWSE-3 ttPedidosEmAberto
&Scoped-define FIRST-TABLE-IN-QUERY-BROWSE-3 ttPedidosEmAberto


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-BROWSE-2}~
    ~{&OPEN-QUERY-BROWSE-3}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS tgItem fiItem tgPE fiRefer tgPI fiQtIni ~
fiQtFim tgnegativo fiDescItem btPesq BROWSE-2 BROWSE-3 tgQtMinBook ~
rt-button RECT-1 
&Scoped-Define DISPLAYED-OBJECTS tgItem fiItem tgPE fiRefer tgPI fiQtIni ~
fiQtFim tgnegativo fiDescItem tgQtMinBook 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-livre AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU mi-programa 
       MENU-ITEM mi-consultas   LABEL "Co&nsultas"     ACCELERATOR "CTRL-L"
       MENU-ITEM mi-imprimir    LABEL "&Relat¢rios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU m_Ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-livre MENUBAR
       SUB-MENU  mi-programa    LABEL "&Nome-do-Programa"
       SUB-MENU  m_Ajuda        LABEL "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btPesq 
     LABEL "Pesquisar" 
     SIZE 10.72 BY 1.13.

DEFINE VARIABLE fiDescItem AS CHARACTER FORMAT "X(50)":U 
     VIEW-AS FILL-IN 
     SIZE 43.14 BY .88 NO-UNDO.

DEFINE VARIABLE fiItem AS CHARACTER FORMAT "X(20)":U 
     LABEL "Item" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fiQtFim AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 99999 
     LABEL "Qt.Fim" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fiQtIni AS DECIMAL FORMAT "->>,>>9.99":U INITIAL 0 
     LABEL "Qt.Ini" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fiRefer AS CHARACTER FORMAT "X(8)":U 
     LABEL "Referˆncia" 
     VIEW-AS FILL-IN 
     SIZE 6 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 88 BY 4.5.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 89.72 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tgItem AS LOGICAL INITIAL no 
     LABEL "Saldo por Item" 
     VIEW-AS TOGGLE-BOX
     SIZE 12.43 BY .83 NO-UNDO.

DEFINE VARIABLE tgnegativo AS LOGICAL INITIAL no 
     LABEL "Considera Saldo Negativo?" 
     VIEW-AS TOGGLE-BOX
     SIZE 20 BY .83 NO-UNDO.

DEFINE VARIABLE tgPE AS LOGICAL INITIAL yes 
     LABEL "Estoque" 
     VIEW-AS TOGGLE-BOX
     SIZE 9 BY .83 NO-UNDO.

DEFINE VARIABLE tgPI AS LOGICAL INITIAL yes 
     LABEL "Programado" 
     VIEW-AS TOGGLE-BOX
     SIZE 10.86 BY .83 NO-UNDO.

DEFINE VARIABLE tgQtMinBook AS LOGICAL INITIAL no 
     LABEL "Qt.Min.Book" 
     VIEW-AS TOGGLE-BOX
     SIZE 14.57 BY .83 NO-UNDO.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY BROWSE-2 FOR 
      ttSaldo SCROLLING.

DEFINE QUERY BROWSE-3 FOR 
      ttPedidosEmAberto SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE BROWSE-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BROWSE-2 w-livre _FREEFORM
  QUERY BROWSE-2 DISPLAY
      ttSaldo.codRefer          
ttSaldo.qtSaldoPE         
ttSaldo.qtDeposFechado    
ttSaldo.qtSaldoPI         
ttSaldo.qtSaldoPISemPerc  
ttSaldo.qtPedidaPE        
ttSaldo.qtPedidaPI        
ttSaldo.qtCarrinhoPE      
ttSaldo.qtCarrinhoLoginPE 
ttSaldo.qtCarrinhoPI      
ttSaldo.qtCarrinhoLoginPI
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 88 BY 4.5
         FONT 1 FIT-LAST-COLUMN.

DEFINE BROWSE BROWSE-3
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BROWSE-3 w-livre _FREEFORM
  QUERY BROWSE-3 DISPLAY
      
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 88 BY 5
         FONT 1 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     tgItem AT ROW 3.96 COL 6.57 WIDGET-ID 6 NO-TAB-STOP 
     fiItem AT ROW 4.96 COL 4.57 COLON-ALIGNED WIDGET-ID 2
     tgPE AT ROW 4 COL 23 WIDGET-ID 16 NO-TAB-STOP 
     fiRefer AT ROW 4.92 COL 79.14 COLON-ALIGNED WIDGET-ID 4
     tgPI AT ROW 4 COL 32.14 WIDGET-ID 18 NO-TAB-STOP 
     fiQtIni AT ROW 6 COL 4.57 COLON-ALIGNED WIDGET-ID 20
     fiQtFim AT ROW 6 COL 20.43 COLON-ALIGNED WIDGET-ID 22
     tgnegativo AT ROW 6.04 COL 34.72 WIDGET-ID 8
     fiDescItem AT ROW 4.96 COL 14.86 COLON-ALIGNED NO-LABEL WIDGET-ID 14 NO-TAB-STOP 
     btPesq AT ROW 5.92 COL 76.72 WIDGET-ID 10
     BROWSE-2 AT ROW 7.75 COL 2 WIDGET-ID 200
     BROWSE-3 AT ROW 12.5 COL 2 WIDGET-ID 300
     tgQtMinBook AT ROW 6.04 COL 57 WIDGET-ID 24 NO-TAB-STOP 
     rt-button AT ROW 1 COL 1
     RECT-1 AT ROW 3 COL 2 WIDGET-ID 12
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 94.29 BY 18.29
         FONT 1 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-livre
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-livre ASSIGN
         HIDDEN             = YES
         TITLE              = "Pesquisa Detalhada de Saldo"
         HEIGHT             = 18.29
         WIDTH              = 94.29
         MAX-HEIGHT         = 27.5
         MAX-WIDTH          = 195.14
         VIRTUAL-HEIGHT     = 27.5
         VIRTUAL-WIDTH      = 195.14
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU m-livre:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-livre 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-livre.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-livre
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-cad
   FRAME-NAME Custom                                                    */
/* BROWSE-TAB BROWSE-2 btPesq f-cad */
/* BROWSE-TAB BROWSE-3 BROWSE-2 f-cad */
ASSIGN 
       BROWSE-2:NUM-LOCKED-COLUMNS IN FRAME f-cad     = 1.

ASSIGN 
       fiDescItem:READ-ONLY IN FRAME f-cad        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BROWSE-2
/* Query rebuild information for BROWSE BROWSE-2
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttSaldo.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE BROWSE-2 */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BROWSE-3
/* Query rebuild information for BROWSE BROWSE-3
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttPedidosEmAberto.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE BROWSE-3 */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Pesquisa Detalhada de Saldo */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Pesquisa Detalhada de Saldo */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btPesq
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btPesq w-livre
ON CHOOSE OF btPesq IN FRAME f-cad /* Pesquisar */
DO:
  
  EMPTY TEMP-TABLE ttSaldo.
  RUN getSaldoItemRef IN hBoSaldo(INPUT FRAME {&frame-name} tgItem,
                                  INPUT FRAME {&frame-name} tgPE,
                                  INPUT FRAME {&frame-name} tgPI,
                                  INPUT FRAME {&frame-name} tgNegativo,
                                  INPUT FRAME {&FRAME-NAME} fiItem,
                                  INPUT FRAME {&FRAME-NAME} fiRefer,
                                  INPUT FRAME {&FRAME-NAME} fiQtIni,
                                  INPUT FRAME {&FRAME-NAME} fiQtFim).
  RUN getTTSaldo IN HboSaldo(OUTPUT TABLE ttSaldo).
  {&open-query-browse-2}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiItem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiItem w-livre
ON LEAVE OF fiItem IN FRAME f-cad /* Item */
DO:
  {include/leave.i &tabela=ITEM
                    &atributo-ref=desc-item
                    &variavel-ref=fiDescItem
                    &where="item.it-codigo = input frame {&frame-name} fiItem"}
                    
  RUN setQtMinBook.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiQtFim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiQtFim w-livre
ON LEAVE OF fiQtFim IN FRAME f-cad /* Qt.Fim */
DO:
  {include/leave.i &tabela=ITEM
                    &atributo-ref=desc-item
                    &variavel-ref=fiDescItem
                    &where="item.it-codigo = input frame {&frame-name} fiItem"}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiQtIni
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiQtIni w-livre
ON LEAVE OF fiQtIni IN FRAME f-cad /* Qt.Ini */
DO:
  {include/leave.i &tabela=ITEM
                    &atributo-ref=desc-item
                    &variavel-ref=fiDescItem
                    &where="item.it-codigo = input frame {&frame-name} fiItem"}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-livre
ON CHOOSE OF MENU-ITEM mi-consultas /* Consultas */
DO:
  RUN pi-consulta IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-livre
ON CHOOSE OF MENU-ITEM mi-conteudo /* Conteudo */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  RUN pi-ajuda IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-livre
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relat¢rios */
DO:
  RUN pi-imprimir IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-programa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-programa w-livre
ON MENU-DROP OF MENU mi-programa /* Nome-do-Programa */
DO:
  run pi-disable-menu.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-livre
ON CHOOSE OF MENU-ITEM mi-sair /* Sair */
DO:
  RUN pi-sair IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-livre
ON CHOOSE OF MENU-ITEM mi-sobre /* Sobre... */
DO:
  {include/sobre.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tgItem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgItem w-livre
ON VALUE-CHANGED OF tgItem IN FRAME f-cad /* Saldo por Item */
DO:
  RUN tratarObj.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tgPE
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgPE w-livre
ON VALUE-CHANGED OF tgPE IN FRAME f-cad /* Estoque */
DO:
  RUN tratarObj.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tgPI
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgPI w-livre
ON VALUE-CHANGED OF tgPI IN FRAME f-cad /* Programado */
DO:
  RUN tratarObj.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tgQtMinBook
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgQtMinBook w-livre
ON VALUE-CHANGED OF tgQtMinBook IN FRAME f-cad /* Qt.Min.Book */
DO:
  RUN tratarObj.
  RUN setQtMinBook.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME BROWSE-2
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-livre 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-livre  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE adm-current-page  AS INTEGER NO-UNDO.

  RUN get-attribute IN THIS-PROCEDURE ('Current-Page':U).
  ASSIGN adm-current-page = INTEGER(RETURN-VALUE).

  CASE adm-current-page: 

    WHEN 0 THEN DO:
       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-exihel.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 2,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-exihel ).
       RUN set-position IN h_p-exihel ( 1.17 , 74.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             BROWSE-3:HANDLE IN FRAME f-cad , 'AFTER':U ).
    END. /* Page 0 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-livre  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-livre  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
  THEN DELETE WIDGET w-livre.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-livre  _DEFAULT-ENABLE
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
  DISPLAY tgItem fiItem tgPE fiRefer tgPI fiQtIni fiQtFim tgnegativo fiDescItem 
          tgQtMinBook 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE tgItem fiItem tgPE fiRefer tgPI fiQtIni fiQtFim tgnegativo fiDescItem 
         btPesq BROWSE-2 BROWSE-3 tgQtMinBook rt-button RECT-1 
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-livre 
PROCEDURE local-destroy :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'destroy':U ) .
  {include/i-logfin.i}

  IF VALID-HANDLE(hBoSaldo) THEN DO:
     RUN finalizarBos IN hBoSaldo.
     DELETE PROCEDURE hboSaldo.
  END.
     
  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-livre 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-livre 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  run pi-before-initialize.

  {include/win-size.i}

  {utp/ut9000.i "esce500" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.
  RUN esbo/boSaldo.p PERSIST SET hBoSaldo.
  RUN iniciarBos IN hBoSaldo.

  RUN tratarObj.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-livre  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "ttPedidosEmAberto"}
  {src/adm/template/snd-list.i "ttSaldo"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE setQtMinBook w-livre 
PROCEDURE setQtMinBook :
IF INPUT FRAME  {&FRAME-NAME} tgQtMinBook THEN DO:
       RUN esbo/BoConsParam.p PERSIST SET hBoParam .                                         
       RUN getQtMinKgBook IN hBoParam(OUTPUT qtMinKg).                                       
       RUN getQtMinMtBook IN hBoParam(OUTPUT qtMinMt).                                       

       IF VALID-HANDLE(hBoParam) THEN                                                        
          DELETE PROCEDURE hBoParam.                                                         
                                                                                             
       FIND ITEM NO-LOCK                                                                     
           WHERE ITEM.it-codigo = fiItem:SCREEN-VALUE IN FRAME {&FRAME-NAME} NO-ERROR.       
       IF AVAIL ITEM THEN DO:  
          IF ITEM.un = 'kg' THEN                                                             
             ASSIGN qtMinima = qtMinKg.                                                      
          IF ITEM.un = 'mt' OR ITEM.un  = 'm' THEN                                          
             ASSIGN qtMinima = qtMinMt.                                                      
                                                                                             
       END.
       ASSIGN  fiQtIni:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               fiQtIni:SCREEN-VALUE IN FRAME {&FRAME-NAME}  = STRING(qtMinima).
    END.
    ELSE DO:
        ASSIGN  fiQtIni:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                fiQtIni:SCREEN-VALUE IN FRAME {&FRAME-NAME}  = '0'.
    END.                                                      


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-livre 
PROCEDURE state-changed :
/*:T -----------------------------------------------------------
  Purpose:     Manuseia trocas de estado dos SmartObjects
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.

  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE tratarObj w-livre 
PROCEDURE tratarObj :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
IF INPUT FRAME  {&frame-name} tgItem THEN DO:
   ASSIGN fiRefer:SENSITIVE IN FRAME {&FRAME-NAME}      = NO
          tgNegativo:SENSITIVE IN FRAME {&FRAME-NAME}   = YES.
END.
ELSE DO:
   ASSIGN fiRefer:SENSITIVE IN FRAME {&FRAME-NAME}      = YES
          tgNegativo:SENSITIVE IN FRAME {&FRAME-NAME}   = NO.
END.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

