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
{include/i-prgvrs.i logCalc 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

DEFINE VARIABLE hBo AS HANDLE      NO-UNDO.
DEFINE TEMP-TABLE ttLog LIKE logs_calculo .
DEFINE TEMP-TABLE ttTrans    LIKE transacoes .
DEFINE TEMP-TABLE ttTransCor LIKE transacoes .


DEFINE VARIABLE hBoCalculos         AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoTransacoes       AS HANDLE      NO-UNDO.
DEFINE VARIABLE cListaCalc          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cSufixo             AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cListaIdTransacoes  AS CHARACTER   NO-UNDO.

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
&Scoped-define INTERNAL-TABLES ttLog ttTrans

/* Definitions for BROWSE BROWSE-2                                      */
&Scoped-define FIELDS-IN-QUERY-BROWSE-2 getDescTipo(ttlog.num_tipo ) ttlog.dt_hr_registro ttLog.descricao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BROWSE-2   
&Scoped-define SELF-NAME BROWSE-2
&Scoped-define QUERY-STRING-BROWSE-2 FOR EACH ttLog WHERE     ttlog.transacao_id = ttTrans.transacao_id
&Scoped-define OPEN-QUERY-BROWSE-2 OPEN QUERY {&SELF-NAME} FOR EACH ttLog WHERE     ttlog.transacao_id = ttTrans.transacao_id .
&Scoped-define TABLES-IN-QUERY-BROWSE-2 ttLog
&Scoped-define FIRST-TABLE-IN-QUERY-BROWSE-2 ttLog


/* Definitions for BROWSE brTransacoes                                  */
&Scoped-define FIELDS-IN-QUERY-brTransacoes ttTrans.transacao_id ttTrans.dt_hr_ini ttTrans.dt_hr_fim ttTrans.login getDescSit(ttTrans.ind_sit_transacao) ttTrans.cod_programa   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brTransacoes   
&Scoped-define SELF-NAME brTransacoes
&Scoped-define QUERY-STRING-brTransacoes FOR EACH ttTrans
&Scoped-define OPEN-QUERY-brTransacoes OPEN QUERY {&SELF-NAME} FOR EACH ttTrans.
&Scoped-define TABLES-IN-QUERY-brTransacoes ttTrans
&Scoped-define FIRST-TABLE-IN-QUERY-brTransacoes ttTrans


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-BROWSE-2}~
    ~{&OPEN-QUERY-brTransacoes}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-button btExec cbCalculo fiNrPedido ~
brTransacoes BROWSE-2 
&Scoped-Define DISPLAYED-OBJECTS cbCalculo fiNrPedido 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


/* ************************  Function Prototypes ********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD getDescSit w-livre 
FUNCTION getDescSit RETURNS CHARACTER
  (iSit AS INT )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD getDescTipo w-livre 
FUNCTION getDescTipo RETURNS CHARACTER
  (  numTipo AS INT  )  FORWARD.

/* _UIB-CODE-BLOCK-END */
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
DEFINE BUTTON btExec 
     LABEL "Buscar" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE cbCalculo AS CHARACTER FORMAT "X(256)":U 
     LABEL "C lculos" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     DROP-DOWN-LIST
     SIZE 34.43 BY 1 NO-UNDO.

DEFINE VARIABLE fiNrPedido AS CHARACTER FORMAT "X(25)":U 
     LABEL "Chave" 
     VIEW-AS FILL-IN 
     SIZE 16 BY .79 NO-UNDO.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 148 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY BROWSE-2 FOR 
      ttLog SCROLLING.

DEFINE QUERY brTransacoes FOR 
      ttTrans SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE BROWSE-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BROWSE-2 w-livre _FREEFORM
  QUERY BROWSE-2 DISPLAY
      getDescTipo(ttlog.num_tipo ) COLUMN-LABEL "Tipo"
ttlog.dt_hr_registro
ttLog.descricao
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 142.57 BY 13.5
         FONT 1
         TITLE "Logs" ROW-HEIGHT-CHARS .75 FIT-LAST-COLUMN.

DEFINE BROWSE brTransacoes
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brTransacoes w-livre _FREEFORM
  QUERY brTransacoes DISPLAY
      ttTrans.transacao_id COLUMN-LABEL "Transa‡Æo"
ttTrans.dt_hr_ini    COLUMN-LABEL "Dt.Hr.Ini"
ttTrans.dt_hr_fim    COLUMN-LABEL "Dt.Hr.Fim"
ttTrans.login        COLUMN-LABEL "Login"
getDescSit(ttTrans.ind_sit_transacao) COLUMN-LABEL "Situa‡Æo" FORMAT 'x(15)'
ttTrans.cod_programa COLUMN-LABEL "Programa" FORMAT 'x(50)'
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 142 BY 6.5
         FONT 1
         TITLE "Transacoes" FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     btExec AT ROW 3.33 COL 72.86 WIDGET-ID 4
     cbCalculo AT ROW 3.42 COL 10.57 COLON-ALIGNED WIDGET-ID 6
     fiNrPedido AT ROW 3.5 COL 51.43 COLON-ALIGNED WIDGET-ID 2
     brTransacoes AT ROW 5.25 COL 4 WIDGET-ID 300
     BROWSE-2 AT ROW 12.25 COL 3.43 WIDGET-ID 200
     rt-button AT ROW 1 COL 1
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 148.29 BY 24.79
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
         TITLE              = "Consulta Logs Calculos"
         HEIGHT             = 25.04
         WIDTH              = 148.72
         MAX-HEIGHT         = 40.5
         MAX-WIDTH          = 274.29
         VIRTUAL-HEIGHT     = 40.5
         VIRTUAL-WIDTH      = 274.29
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
   FRAME-NAME L-To-R                                                    */
/* BROWSE-TAB brTransacoes fiNrPedido f-cad */
/* BROWSE-TAB BROWSE-2 brTransacoes f-cad */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BROWSE-2
/* Query rebuild information for BROWSE BROWSE-2
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttLog WHERE
    ttlog.transacao_id = ttTrans.transacao_id .
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE BROWSE-2 */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brTransacoes
/* Query rebuild information for BROWSE brTransacoes
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttTrans.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE brTransacoes */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Consulta Logs Calculos */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Consulta Logs Calculos */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME brTransacoes
&Scoped-define SELF-NAME brTransacoes
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL brTransacoes w-livre
ON VALUE-CHANGED OF brTransacoes IN FRAME f-cad /* Transacoes */
DO:
  IF AVAIL ttTrans THEN
    {&OPEN-QUERY-BROWSE-2}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExec
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExec w-livre
ON CHOOSE OF btExec IN FRAME f-cad /* Buscar */
DO:
  EMPTY TEMP-TABLE ttLog.  
  RUN setCalculo IN hBo(INPUT FRAME {&FRAME-NAME} cbCalculo ).
  //RUN getLogsUltTransporChave IN hBo(fiNrPedido:SCREEN-VALUE, OUTPUT TABLE ttLog ).
  RUN getlogsPorChave IN hBo(fiNrPedido:SCREEN-VALUE, OUTPUT TABLE ttLog).
  RUN atuBrTrans.
  {&OPEN-QUERY-BRtransacoes}
  APPLY 'value-changed' TO BROWSE brTransacoes.
  
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbCalculo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbCalculo w-livre
ON VALUE-CHANGED OF cbCalculo IN FRAME f-cad /* C lculos */
DO:
  RUN setCalculo IN hBoCalculos(INPUT FRAME {&FRAME-NAME} cbCalculo).
  RUN getSufixo IN hBoCalculos(OUTPUT cSufixo).
  ASSIGN fiNrPedido:SCREEN-VALUE = cSufixo.
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
       RUN set-position IN h_p-exihel ( 1.08 , 132.72 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             btExec:HANDLE IN FRAME f-cad , 'BEFORE':U ).
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE atuBrTrans w-livre 
PROCEDURE atuBrTrans :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
EMPTY TEMP-TABLE ttTrans .
FOR EACH ttLog WHERE ttLog.transacao > 0 :
    FIND ttTrans
        WHERE ttTrans.transacao_id = ttLog.transacao_id
        NO-ERROR.
    IF NOT AVAIL ttTrans THEN DO:
       RUN getTtTransacaoCorrente IN hBoTransacoes(ttLog.transacao_Id, 
                                                   OUTPUT TABLE ttTransCor).
       FIND FIRST ttTransCor NO-ERROR.
       CREATE ttTrans.
       BUFFER-COPY ttTransCor TO ttTrans.
       EMPTY TEMP-TABLE ttTransCor.
    END.
END.







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
  DISPLAY cbCalculo fiNrPedido 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button btExec cbCalculo fiNrPedido brTransacoes BROWSE-2 
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
 IF VALID-HANDLE(hBoCalculos) THEN
    DELETE PROCEDURE hBoCalculos.
 IF VALID-HANDLE(hBoTransacoes) THEN
    DELETE PROCEDURE hBoTransacoes.
 IF VALID-HANDLE(hBo) THEN DO:
    RUN finalizarBos IN hBo.
    DELETE PROCEDURE hBo.
 END.
 


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

  {utp/ut9000.i "logCalc" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .
  RUN esbo/boCalculos.p PERSISTENT SET hBoCalculos.
  RUN esbo/boTransacoes.p PERSISTENT SET hBoTransacoes.
  RUN esbo/boLogsCalculos.p PERSISTENT SET hBo.
  RUN iniciarBos IN hBo.
  RUN getListaCb IN hBoCalculos(OUTPUT cListaCalc).
  ASSIGN cbCalculo:LIST-ITEM-PAIRS = cListaCalc .
  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.
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
  {src/adm/template/snd-list.i "ttTrans"}
  {src/adm/template/snd-list.i "ttLog"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

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

/* ************************  Function Implementations ***************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION getDescSit w-livre 
FUNCTION getDescSit RETURNS CHARACTER
  (iSit AS INT ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
  CASE iSit:
      WHEN 0 THEN DO:
          RETURN 'Iniciada'.
      END.
      WHEN 1 THEN DO:
          RETURN 'Conclu¡da'.
      END.
      WHEN 2 THEN DO:
          RETURN 'Cancelada'.
      END.
      WHEN 3 THEN DO:
          RETURN 'Erro Progress'.
      END.
  END CASE.
  
  RETURN "".   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION getDescTipo w-livre 
FUNCTION getDescTipo RETURNS CHARACTER
  (  numTipo AS INT  ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
DEFINE VARIABLE cRetorno AS CHARACTER   NO-UNDO.
CASE numTipo :
    WHEN 1 THEN
        ASSIGN cRetorno = "Aviso" .
    WHEN 2 THEN
        ASSIGN cRetorno = "Erro".
    WHEN 3 THEN
        ASSIGN cRetorno = "Log".
END CASE.

  RETURN cRetorno.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

