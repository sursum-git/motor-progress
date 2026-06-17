&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
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
{include/i-prgvrs.i XX9999 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

/*
data: 11/01/2024 - tadeu - acrescimo de filtros de estab, serie, nota e representante
*/
{esbo\esbo_fatur.i}
{esp/util.i}
//{utp\ut-acomp.i}


DEFINE VARIABLE hBoFatur        AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoAppServer    AS HANDLE      NO-UNDO.
DEFINE VARIABLE hServer         AS HANDLE      NO-UNDO.
DEFINE VARIABLE novoArquivo     AS CHARACTER   NO-UNDO.

DEFINE VARIABLE cmd AS CHARACTER   NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 rt-button tg12 fi-dt-ini fi-dt-fim ~
fi-estab-ini fi-estab-fim fi-serie-ini fi-serie-fim fi-nota-ini fi-nota-fim ~
fi-repres-ini fi-repres-fim bt-executar tgFat tgDev tgMeta 
&Scoped-Define DISPLAYED-OBJECTS tg12 fi-dt-ini fi-dt-fim fi-estab-ini ~
fi-estab-fim fi-serie-ini fi-serie-fim fi-nota-ini fi-nota-fim ~
fi-repres-ini fi-repres-fim tgFat tgDev tgMeta 

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
DEFINE BUTTON bt-executar 
     LABEL "Executar" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE fi-dt-fim AS DATE FORMAT "99/99/9999":U INITIAL 12/31/9999 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-dt-ini AS DATE FORMAT "99/99/9999":U INITIAL 01/01/001 
     LABEL "Data" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-estab-fim AS CHARACTER FORMAT "X(256)":U INITIAL "zzzz" 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-estab-ini AS CHARACTER FORMAT "X(256)":U 
     LABEL "Estab." 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-nota-fim AS CHARACTER FORMAT "X(256)":U INITIAL "zzzzzzzzzzzzzz" 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-nota-ini AS CHARACTER FORMAT "X(256)":U 
     LABEL "NF" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-repres-fim AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 9999999 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-repres-ini AS INTEGER FORMAT ">>>,>>>,>>9":U INITIAL 0 
     LABEL "Repres." 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-serie-fim AS CHARACTER FORMAT "X(256)":U INITIAL "zzzzz" 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fi-serie-ini AS CHARACTER FORMAT "X(256)":U 
     LABEL "S‚rie" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 69 BY 6.75.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 73 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tg12 AS LOGICAL INITIAL yes 
     LABEL "Proporcional" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.72 BY .83 NO-UNDO.

DEFINE VARIABLE tgDev AS LOGICAL INITIAL yes 
     LABEL "Devolu‡Æo" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.57 BY .83 NO-UNDO.

DEFINE VARIABLE tgFat AS LOGICAL INITIAL yes 
     LABEL "Faturamento" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.57 BY .83 NO-UNDO.

DEFINE VARIABLE tgMeta AS LOGICAL INITIAL yes 
     LABEL "Meta" 
     VIEW-AS TOGGLE-BOX
     SIZE 7.14 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     tg12 AT ROW 1.25 COL 2.43 WIDGET-ID 40
     fi-dt-ini AT ROW 3.29 COL 16.14 COLON-ALIGNED WIDGET-ID 2
     fi-dt-fim AT ROW 3.29 COL 40.14 COLON-ALIGNED WIDGET-ID 4
     fi-estab-ini AT ROW 4.42 COL 16.14 COLON-ALIGNED WIDGET-ID 14
     fi-estab-fim AT ROW 4.42 COL 40.14 COLON-ALIGNED WIDGET-ID 12
     fi-serie-ini AT ROW 5.54 COL 16.14 COLON-ALIGNED WIDGET-ID 18
     fi-serie-fim AT ROW 5.54 COL 40.14 COLON-ALIGNED WIDGET-ID 16
     fi-nota-ini AT ROW 6.67 COL 16.14 COLON-ALIGNED WIDGET-ID 26
     fi-nota-fim AT ROW 6.67 COL 40.14 COLON-ALIGNED WIDGET-ID 24
     fi-repres-ini AT ROW 7.79 COL 16.14 COLON-ALIGNED WIDGET-ID 32
     fi-repres-fim AT ROW 7.79 COL 40.14 COLON-ALIGNED WIDGET-ID 30
     bt-executar AT ROW 10.25 COL 4.86 WIDGET-ID 8
     tgFat AT ROW 10.38 COL 23 WIDGET-ID 34
     tgDev AT ROW 10.38 COL 34.86 WIDGET-ID 36
     tgMeta AT ROW 10.38 COL 46.57 WIDGET-ID 38
     RECT-1 AT ROW 2.75 COL 5 WIDGET-ID 28
     rt-button AT ROW 1 COL 1
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 14.04
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
         TITLE              = "Extra‡Æo de Dados - Faturamento"
         HEIGHT             = 11.08
         WIDTH              = 74.43
         MAX-HEIGHT         = 17
         MAX-WIDTH          = 90.14
         VIRTUAL-HEIGHT     = 17
         VIRTUAL-WIDTH      = 90.14
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
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Extra‡Æo de Dados - Faturamento */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Extra‡Æo de Dados - Faturamento */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-executar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-executar w-livre
ON CHOOSE OF bt-executar IN FRAME f-cad /* Executar */
DO:
    ASSIGN bt-executar:LABEL = "Aguarde...".
    ASSIGN bt-executar:SENSITIVE = no.

  RUN esbo/boAppServer.p PERSISTENT SET hBoAppserver.
  RUN getHandleAppServerEmpresa IN hBoAppServer('5', OUTPUT hServer).
  RUN esbo/esbo_fatur.p PERSISTENT SET hBoFatur ON SERVER hServer.
  RUN iniciarBos IN hBoFatur.
  RUN setIntervalDtEmisNota IN hBoFatur(INPUT FRAME {&frame-name} fi-dt-ini, 
                                        INPUT FRAME {&frame-name} fi-dt-fim).


  RUN setIntervalEstab      IN hBoFatur(fi-estab-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME},
                                        fi-estab-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}).
  RUN setIntervalSerie      IN hBoFatur(fi-serie-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME},
                                        fi-serie-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}).
  RUN setIntervalNota       IN hBoFatur(fi-nota-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME},
                                        fi-nota-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}).
  RUN setIntervalRepres     IN hBoFatur(int(fi-repres-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}),
                                        int(fi-repres-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME})).
    IF tg12:SCREEN-VALUE = 'yes' THEN
      RUN set12     IN hBoFatur(YES).  
    ELSE
      RUN set12     IN hBoFatur(NO).
  IF tgFat:SCREEN-VALUE  = 'yes' THEN
     RUN buscarFaturados       IN hBoFatur.

  IF tgDev:SCREEN-VALUE  = 'yes' THEN
     RUN buscarDevolucao       IN hBoFatur.

  IF tgMeta:SCREEN-VALUE = 'yes' THEN
     RUN buscarMetasRepres     IN hBoFatur.
     
  
   
  
  //RUN exportarTtFatur   IN hBoFatur(SESSION:TEMP-DIRECTORY + "fatur.txt"). 
  RUN retornarTtFatur IN hboFatur(OUTPUT TABLE tt-Fatur).
  {esp/exportarTabela2.i tt-fatur " " " " "fatur.txt" "|" " "}
  RUN finalizarBos      IN hBoFatur.
  RUN desconectarAppServer IN hBoAppServer.
  ASSIGN novoArquivo = SEARCH('excel/esp_fatur001.xltx')
         //novoArquivo = REPLACE(novoArquivo,'\\192.168.0.136\erp','t:')
         .
  //RUN esapi/criarVersaoModeloExcel.p('excel\esp_fatur001.xlsx',OUTPUT novoArquivo).
  IF SEARCH(novoArquivo) <> ? THEN  DO:
     ASSIGN cmd = "start " + novoArquivo.
            
     OUTPUT TO c:\temp\comando.txt.
       PUT UNFORM cmd.     
     OUTPUT close.
     
     OS-COMMAND SILENT VALUE (cmd ).    
  END.
  ELSE DO:
     MESSAGE 'Ocorreu um erro ao abrir o excel'
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
  END.
  

  ASSIGN bt-executar:LABEL = "Executar".
    ASSIGN bt-executar:SENSITIVE = YES.
  
  IF VALID-HANDLE(hBoAppServer) THEN
  DO:
    DELETE OBJECT hBoAppServer.
      
  END.
    
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
       RUN set-position IN h_p-exihel ( 1.13 , 57.57 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             tg12:HANDLE IN FRAME f-cad , 'BEFORE':U ).
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
  DISPLAY tg12 fi-dt-ini fi-dt-fim fi-estab-ini fi-estab-fim fi-serie-ini 
          fi-serie-fim fi-nota-ini fi-nota-fim fi-repres-ini fi-repres-fim tgFat 
          tgDev tgMeta 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE RECT-1 rt-button tg12 fi-dt-ini fi-dt-fim fi-estab-ini fi-estab-fim 
         fi-serie-ini fi-serie-fim fi-nota-ini fi-nota-fim fi-repres-ini 
         fi-repres-fim bt-executar tgFat tgDev tgMeta 
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

  {utp/ut9000.i "XX9999" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

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

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this w-livre, and there are no
     tables specified in any contained Browse, Query, or Frame. */

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

