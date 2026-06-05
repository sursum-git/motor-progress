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
{include/i-prgvrs.i esp998-v2 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.



/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
 
 
DEFINE VARIABLE hBoMsg   AS HANDLE      NO-UNDO. 
DEFINE VARIABLE lErro    AS LOGICAL     NO-UNDO.
DEFINE VARIABLE hAcomp   AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoTrans AS HANDLE      NO-UNDO.
{esp/util.i}
{esapi/getTitIntegr12.i}
{esbo/bomsg.i}
{utp/ut-glob.i}
DEFINE VARIABLE hServerBkp AS HANDLE      NO-UNDO.
DEFINE VARIABLE hServer    AS HANDLE      NO-UNDO.
DEFINE VARIABLE hAppServer AS HANDLE      NO-UNDO.

DEFINE TEMP-TABLE ttAux NO-UNDO LIKE ttTitNf .

DEFINE VARIABLE rowidCorrente AS ROWID       NO-UNDO.
DEFINE VARIABLE idCalculo     AS INTEGER     NO-UNDO INIT 303.
DEFINE VARIABLE idTrans       AS INT64       NO-UNDO .
DEFINE BUFFER bf FOR ttTItNf.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME BrTitulos

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttTitNf

/* Definitions for BROWSE BrTitulos                                     */
&Scoped-define FIELDS-IN-QUERY-BrTitulos cdn_cliente nom_abrev dat_emis_docto cod_estab cod_ser_docto cod_espec_docto cod_tit_acr cod_parcela val_origin_tit_acr percDesc vlIpi vlFrete VlTit logIntegrado cod_refer dat_transacao   
&Scoped-define ENABLED-FIELDS-IN-QUERY-BrTitulos   
&Scoped-define SELF-NAME BrTitulos
&Scoped-define QUERY-STRING-BrTitulos FOR EACH ttTitNf
&Scoped-define OPEN-QUERY-BrTitulos OPEN QUERY {&SELF-NAME} FOR EACH ttTitNf.
&Scoped-define TABLES-IN-QUERY-BrTitulos ttTitNf
&Scoped-define FIRST-TABLE-IN-QUERY-BrTitulos ttTitNf


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-BrTitulos}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS fiTotalInt edFormula fi_data_ini fi_data_fim ~
bt_atualizar BrTitulos fiTotalPend fiTotal rt-button RECT-1 
&Scoped-Define DISPLAYED-OBJECTS fiTotalInt edFormula fi_data_ini ~
fi_data_fim fiTotalPend fiTotal 

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
DEFINE BUTTON btIntegrar 
     LABEL "Integrar T¡tulos" 
     SIZE 15 BY 1.13.

DEFINE BUTTON btIntegrarCorrente 
     LABEL "Integrar T¡tulo Corrente" 
     SIZE 18.86 BY 1.13.

DEFINE BUTTON bt_atualizar 
     LABEL "Buscar T¡tulos" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE edFormula AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 112 BY 2.58 NO-UNDO.

DEFINE VARIABLE fiTotal AS DECIMAL FORMAT "->>>,>>9.99":U INITIAL 0 
     LABEL "Total" 
      VIEW-AS TEXT 
     SIZE 12.57 BY .63
     BGCOLOR 15 FGCOLOR 9 FONT 0 NO-UNDO.

DEFINE VARIABLE fiTotalInt AS DECIMAL FORMAT "->>>,>>9.99":U INITIAL 0 
     LABEL "Integrado" 
      VIEW-AS TEXT 
     SIZE 12.29 BY .63
     BGCOLOR 15 FGCOLOR 9 FONT 0 NO-UNDO.

DEFINE VARIABLE fiTotalPend AS DECIMAL FORMAT "->>>,>>9.99":U INITIAL 0 
     LABEL "Pendente" 
      VIEW-AS TEXT 
     SIZE 11.86 BY .63
     BGCOLOR 15 FGCOLOR 9 FONT 0 NO-UNDO.

DEFINE VARIABLE fi_data_fim AS DATE FORMAT "99/99/9999":U 
     LABEL "Data Final" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi_data_ini AS DATE FORMAT "99/99/9999":U 
     LABEL "Data Inicial" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 112 BY 2.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 113 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY BrTitulos FOR 
      ttTitNf SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE BrTitulos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS BrTitulos w-livre _FREEFORM
  QUERY BrTitulos DISPLAY
      cdn_cliente
nom_abrev
dat_emis_docto
cod_estab
cod_ser_docto
cod_espec_docto
cod_tit_acr
cod_parcela
val_origin_tit_acr
percDesc COLUMN-LABEL "Bkp"
vlIpi
vlFrete
VlTit
logIntegrado
cod_refer
dat_transacao
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 112 BY 13
         FONT 1 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fiTotalInt AT ROW 21 COL 42.72 COLON-ALIGNED WIDGET-ID 24
     btIntegrar AT ROW 20.75 COL 2 WIDGET-ID 12
     edFormula AT ROW 17.75 COL 2 NO-LABEL WIDGET-ID 10
     fi_data_ini AT ROW 3.33 COL 16 COLON-ALIGNED WIDGET-ID 4
     fi_data_fim AT ROW 3.33 COL 52.14 COLON-ALIGNED WIDGET-ID 6
     bt_atualizar AT ROW 3.25 COL 95.29 WIDGET-ID 2
     BrTitulos AT ROW 4.75 COL 2 WIDGET-ID 200
     btIntegrarCorrente AT ROW 20.75 COL 17.14 WIDGET-ID 14
     fiTotalPend AT ROW 21 COL 63 COLON-ALIGNED WIDGET-ID 26
     fiTotal AT ROW 21 COL 81.43 COLON-ALIGNED WIDGET-ID 28
     rt-button AT ROW 1 COL 1
     RECT-1 AT ROW 2.75 COL 2 WIDGET-ID 8
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 114.43 BY 21.79
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
         TITLE              = "Atualiza‡Æo dos t¡tutlos do BKP"
         HEIGHT             = 21.75
         WIDTH              = 113.57
         MAX-HEIGHT         = 35.5
         MAX-WIDTH          = 228.57
         VIRTUAL-HEIGHT     = 35.5
         VIRTUAL-WIDTH      = 228.57
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
/* BROWSE-TAB BrTitulos bt_atualizar f-cad */
ASSIGN 
       BrTitulos:NUM-LOCKED-COLUMNS IN FRAME f-cad     = 9.

/* SETTINGS FOR BUTTON btIntegrar IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON btIntegrarCorrente IN FRAME f-cad
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE BrTitulos
/* Query rebuild information for BROWSE BrTitulos
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttTitNf.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE BrTitulos */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Atualiza‡Æo dos t¡tutlos do BKP */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Atualiza‡Æo dos t¡tutlos do BKP */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME BrTitulos
&Scoped-define SELF-NAME BrTitulos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL BrTitulos w-livre
ON VALUE-CHANGED OF BrTitulos IN FRAME f-cad
DO:
    IF AVAIL ttTitNF THEN  DO:
       ASSIGN edFormula:SCREEN-VALUE            = ttTitNf.formula + CHR(13) + ttTitNf.des_observacao
              btIntegrarCorrente:SENSITIVE      = NOT ttTitNf.logIntegrado 
              rowidCorrente                     = ROWID(ttTitNf)
       .        
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btIntegrar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btIntegrar w-livre
ON CHOOSE OF btIntegrar IN FRAME f-cad /* Integrar T¡tulos */
DO:
  IF CAN-FIND( FIRST ttCli) THEN  DO:
     RUN integrarCliente.         
  END.
  RUN utp/ut-acomp.p PERSIST SET hAcomp.
  RUN pi-inicializar IN hAcomp('Integracao BKP').
  
  
  RUN esapi/getConexaoBkp(OUTPUT hServerBKP).
  
  
  
  FOR EACH ttTitNf WHERE ttTitNf.logIntegrado = NO:
      RUN pi-acompanhar IN hAcomp(ttTitNf.cod_tit_acr + "-" + ttTitNf.cod_parcela).
      EMPTY TEMP-TABLE ttAux.
      CREATE ttAux.
      BUFFER-COPY ttTitNf TO ttAux. 
      RUN esapi/integrarTit12.p ON SERVER hServerBkp(c-seg-usuario,INPUT-OUTPUT TABLE ttAux,INPUT-OUTPUT hBoMsg).
      //PAUSE 1.     
      
  END.
  
  RUN pi-finalizar IN hAcomp.
  
  IF hServerBkp:CONNECTED() THEN DO:
     hServerBkp:DISCONNECT().         
  END.
  APPLY 'choose' TO bt_atualizar .
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btIntegrarCorrente
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btIntegrarCorrente w-livre
ON CHOOSE OF btIntegrarCorrente IN FRAME f-cad /* Integrar T¡tulo Corrente */
DO:
  IF CAN-FIND( FIRST ttCli) THEN  DO:
    
     RUN integrarCliente.             
  END.
  ELSE DO:
/*       MESSAGE 'sem cliente para integrar'           */
/*           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK. */
  END.
  
  FIND bf WHERE ROWID(bf) = rowidCorrente NO-ERROR.
  IF AVAIL bf  THEN  DO:
 
     EMPTY TEMP-TABLE ttAux.
     CREATE ttAux.
     BUFFER-COPY bf TO ttAux.
     RUN esapi/getConexaoBkp(OUTPUT hServerBKP).    
     RUN esapi/integrarTit12.p 
     ON SERVER hServerBkp(c-seg-usuario,INPUT-OUTPUT TABLE ttAux,INPUT-OUTPUT hBoMsg).
  
     IF hServerBkp:CONNECTED() THEN DO:
        hServerBkp:DISCONNECT().         
     END.
     APPLY 'choose' TO bt_atualizar .      
  END.
  ELSE DO:
  MESSAGE 'NÇO ACHOU O REGISTRO'
      VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
  END. 
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt_atualizar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt_atualizar w-livre
ON CHOOSE OF bt_atualizar IN FRAME f-cad /* Buscar T¡tulos */
DO:
 
 
 ASSIGN bt_atualizar:LABEL = 'Processando'
         bt_atualizar:SENSITIVE = FALSE.
         
 RUN executar.        
 ASSIGN bt_atualizar:LABEL     = 'Atualizar'
         bt_atualizar:SENSITIVE = TRUE.  
   
   
  
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
       RUN set-position IN h_p-exihel ( 1.17 , 97.57 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             edFormula:HANDLE IN FRAME f-cad , 'AFTER':U ).
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
  DISPLAY fiTotalInt edFormula fi_data_ini fi_data_fim fiTotalPend fiTotal 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE fiTotalInt edFormula fi_data_ini fi_data_fim bt_atualizar BrTitulos 
         fiTotalPend fiTotal rt-button RECT-1 
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE executar w-livre 
PROCEDURE executar :
ASSIGN edFormula:SCREEN-VALUE IN FRAME {&frame-name} = ''.
  DEFINE VARIABLE dTotalPend AS DECIMAL     NO-UNDO.
  DEFINE VARIABLE dTotalInt  AS DECIMAL     NO-UNDO.
  DEFINE VARIABLE dTotal     AS DECIMAL     NO-UNDO.
  
  IF VALID-HANDLE(hboMsg) THEN  DO:
     DELETE procedure hBoMsg.
  END.
  IF VALID-HANDLE(hAppServer) THEN   DO:
     DELETE PROCEDURE hAppServer. 
  END.
  //RUN esbo/boMsg.p PERSIST SET hBoMsg.
  RUN esbo/boAppServer.p PERSIST SET hAppServer.
  RUN getHandleAppServerEmpresa IN hAppServer('5', OUTPUT hServer).
  
  
  IF hServer:CONNECTED() THEN  DO:
     RUN esapi/getTitIntegr12.p ON SERVER  hServer(
                             INPUT FRAME {&frame-name} fi_data_ini,
                             INPUT FRAME {&frame-name} fi_data_fim,
                             INPUT-OUTPUT hBoMsg,
                             OUTPUT TABLE ttTitNf
                         ).    
  
  END.
  ELSE DO:
      MESSAGE 'NÆo foi poss¡vel conectar no servidor da empresa 5'
      VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
      RETURN NO-APPLY.
  END.
  
  
  RUN esapi/getConexaoBkp.p(OUTPUT hServerBKP).                 
  IF hServerBKP:CONNECTED() THEN DO:
     RUN esapi/verifIntegrTit.p ON SERVER hServerBkp(INPUT-OUTPUT TABLE ttTitNF,
                                                     OUTPUT TABLE ttCli   
                                                     ).         
                                                     
  END.
  ELSE DO:
     MESSAGE 'NÆo foi Poss¡vel conectar a base BKP'
     VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
     RETURN NO-APPLY.    
  END.
  
  {esp/exportarTabelaCsv3.i ttCli  " " " " "ttcli"}
         
  {&open-query-brTitulos}
  APPLY 'VALUE-CHANGED' TO BROWSE brTitulos.
  
  
  IF VALID-HANDLE(hAppServer) THEN DO:
     RUN desconectarAppServer IN hAppServer.
     DELETE OBJECT hAppServer.        
   END.
    
   IF hServerBkp:CONNECTED() THEN DO:
      hServerBkp:DISCONNECT().         
   END.
   
   ASSIGN  btIntegrar:SENSITIVE = CAN-FIND( FIRST ttTitNf WHERE ttTitNf.logintegrado = NO).
   ASSIGN dTotal     = 0
          dTotalPend = 0
          dTotalInt  = 0.
   FOR EACH ttTitNf WHERE :
       IF ttTitNF.logIntegrado = NO THEN
          ASSIGN dTotalPend = dTotalPend + ttTitNf.vlTit.
       ELSE 
          ASSIGN dTotalInt  = dTotalInt  + ttTitNf.vlTit.
          
       ASSIGN dTotal = dTotal  + ttTitNF.vlTit .
   END.
   ASSIGN  fiTotal:SCREEN-VALUE IN FRAME {&frame-name} = STRING(dTotal)
           fiTotalPend:SCREEN-VALUE IN FRAME {&frame-name} = STRING(dTotalPend)
           fiTotalInt:SCREEN-VALUE IN FRAME {&frame-name} = STRING(dTotalInt)   
          .
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE integrarCliente w-livre 
PROCEDURE integrarCliente :
DEFINE VARIABLE logErro AS LOGICAL     NO-UNDO.
RUN utp/ut-acomp.p PERSIST SET hAcomp.
RUN pi-inicializar IN hAcomp('Integr.Cli BKP').
FOR EACH ttCli:

 
    RUN esbo/boMsg.p        PERSIST SET hBoMsg.
    RUN esbo/boTransacoes.p PERSIST SET hBoTrans.
    RUN gerarTransacao IN hBoTrans('esp998-v2.p',c-seg-usuario,idCalculo,
                               ttCli.codEmit,
                               OUTPUT idTrans). 
     
     
     RUN pi-acompanhar IN hAcomp('Integrando Cli:' + STRING(ttCli.codEmit)).
    
     RUN esapi/integrarClienteBkpManual.p(ttCli.codEmit,INPUT-OUTPUT hBoMsg).
     
     IF  VALID-HANDLE(hBoMsg) THEN DO:   
             
         /*RUN setTransacaoLogCalculo IN hBoMsg(idTrans).
         RUN gravarLogCalculo       IN hBoMsg(idCalculo).
         RUN getErro IN hBoMsg(OUTPUT logErro). */
     END.      
     ELSE DO:
        ASSIGN logErro = YES.
     END.
     
     RUN finalizarTransacao     IN hBoTrans(IF logErro THEN 2 ELSE 1).
    
     IF VALID-HANDLE(hboMsg) THEN  DO:
        DELETE PROCEDURE hBoMsg NO-ERROR.
     END.
     IF VALID-HANDLE(hBoTrans) THEN   DO:
        DELETE PROCEDURE hBoTrans NO-ERROR. 
     END.
 END.
 
 
 RUN pi-finalizar in hAcomp.

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

  {utp/ut9000.i "esp998-v2" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  ASSIGN fi_data_ini:SCREEN-VALUE = STRING(TODAY)
         fi_data_fim:SCREEN-VALUE = STRING(TODAY)
         .

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
  {src/adm/template/snd-list.i "ttTitNf"}

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

