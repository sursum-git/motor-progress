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
{include/i-prgvrs.i ESRE999 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

DEFINE VARIABLE cArquivo AS CHARACTER   NO-UNDO FORMAT 'X(200)'.
DEFINE VARIABLE cCaminho AS CHARACTER   NO-UNDO FORMAT 'x(100)'.
DEFINE VARIABLE cCaminhoCompl AS CHARACTER   NO-UNDO FORMAT 'x(100)'.
DEFINE TEMP-TABLE tt LIKE docum-est
       FIELD LOG_xml AS LOGICAL.
DEFINE VARIABLE lGerou AS LOGICAL     NO-UNDO.
{esp/util.i}

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
&Scoped-Define ENABLED-OBJECTS tgAno fiCaminho fidtIni fidtFim btexecutar ~
tgMes tgDia rt-button 
&Scoped-Define DISPLAYED-OBJECTS tgAno fiCaminho fidtIni fidtFim tgMes ~
tgDia 

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
DEFINE BUTTON btexecutar 
     LABEL "Gerar Xml" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE fiCaminho AS CHARACTER FORMAT "X(256)":U 
     LABEL "Caminho Exporta‡Æo XML" 
     VIEW-AS FILL-IN 
     SIZE 38 BY .88 NO-UNDO.

DEFINE VARIABLE fidtFim AS DATE FORMAT "99/99/9999":U 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88 NO-UNDO.

DEFINE VARIABLE fidtIni AS DATE FORMAT "99/99/9999":U 
     LABEL "Dt.Trans" 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88 NO-UNDO.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 81 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tgAno AS LOGICAL INITIAL no 
     LABEL "Ano" 
     VIEW-AS TOGGLE-BOX
     SIZE 6 BY .83 NO-UNDO.

DEFINE VARIABLE tgDia AS LOGICAL INITIAL no 
     LABEL "Dia" 
     VIEW-AS TOGGLE-BOX
     SIZE 6 BY .83 NO-UNDO.

DEFINE VARIABLE tgMes AS LOGICAL INITIAL no 
     LABEL "Mˆs" 
     VIEW-AS TOGGLE-BOX
     SIZE 6 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     tgAno AT ROW 6.75 COL 29 WIDGET-ID 14
     fiCaminho AT ROW 5.25 COL 27 COLON-ALIGNED WIDGET-ID 8
     fidtIni AT ROW 3.75 COL 27 COLON-ALIGNED WIDGET-ID 2
     fidtFim AT ROW 3.79 COL 52.86 COLON-ALIGNED WIDGET-ID 4
     btexecutar AT ROW 8.04 COL 28.72 WIDGET-ID 6
     tgMes AT ROW 6.75 COL 35.29 WIDGET-ID 16
     tgDia AT ROW 6.75 COL 41.43 WIDGET-ID 18
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
         TITLE              = "Exporta‡Æo de XMLs"
         HEIGHT             = 8.88
         WIDTH              = 81.57
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
   FRAME-NAME Custom                                                    */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Exporta‡Æo de XMLs */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Exporta‡Æo de XMLs */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btexecutar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btexecutar w-livre
ON CHOOSE OF btexecutar IN FRAME f-cad /* Gerar Xml */
DO:     
    EMPTY TEMP-TABLE tt.
    //OS-COMMAND SILENT VALUE('rd c:\temp\nfe_xml \s \q').
    //OS-DELETE VALUE('c:\temp\nfe_xml') RECURSIVE.
       
    //OS-COMMAND SILENT VALUE('mkdir c:\temp\nfe_xml').
    OS-COMMAND SILENT VALUE('mkdir \\pv1.ima.com.br\pv1\fiscal').
    OS-COMMAND SILENT VALUE('mkdir \\pv1.ima.com.br\pv1\fiscal\entradas').

    ASSIGN btExecutar:SENSITIVE = NO.
    ASSIGN fidtIni:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
    ASSIGN fiDtFim:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
    //ASSIGN cCaminho =  'c:\temp\nfe_xml\'.
    //ASSIGN cCaminho =  '\\pv1.ima.com.br\fiscal\fiscal\entradas\'.
    //ASSIGN cCaminho = fiCaminho:SCREEN-VALUE.
    //OS-DELETE VALUE(cCaminho) RECURSIVE.

    FOR EACH docum-est NO-LOCK
        WHERE docum-est.dt-trans >= INPUT FRAME {&frame-name} fiDtIni
        AND   docum-est.dt-trans <= INPUT FRAME {&frame-name} fiDtFim
        AND   docum-est.ce-atual = YES
        USE-INDEX dt-tp-estab BREAK BY   docum-est.cod-estabel BY docum-est.dt-trans :
        ASSIGN cCaminho = fiCaminho:SCREEN-VALUE.
        RUN incrValor(INPUT-OUTPUT cCaminho,docum-est.cod-estabel,"\").

        IF FIRST-OF(docum-est.cod-estabel) THEN DO:
           OS-CREATE-DIR VALUE(cCaminho).
        END.
        IF FIRST-OF(docum-est.dt-trans) THEN DO:
           IF INPUT FRAME {&frame-name} tgAno  THEN DO:
              RUN incrValor(INPUT-OUTPUT cCaminho,string(YEAR(docum-est.dt-trans),'9999'),"\").
              OS-CREATE-DIR VALUE(cCaminho).
           END.                             
           IF INPUT FRAME {&frame-name} tgMes  THEN DO:
              RUN incrValor(INPUT-OUTPUT cCaminho,string(MONTH(docum-est.dt-trans),'99'),"\").
              OS-CREATE-DIR VALUE(cCaminho).
           END.                             
           IF INPUT FRAME {&frame-name} tgDia  THEN DO:
              RUN incrValor(INPUT-OUTPUT cCaminho,string(DAY(docum-est.dt-trans),'99'),"\").
              OS-CREATE-DIR VALUE(cCaminho).      
              /*ASSIGN cCaminhoCompl = cCaminho + (docum-est.cod-estabel)  
              + "\" 
              + string(YEAR(docum-est.dt-trans),'9999') 
              + "\" 
              + string(MONTH(docum-est.dt-trans),'99') + "\" 
              + string(DAY(docum-est.dt-trans),'99')  .*/
              
              //OS-CREATE-DIR VALUE(cCaminho). 
           END.
        END.
       ASSIGN cArquivo = cCaminho. 
       RUN incrValor(INPUT-OUTPUT cArquivo,
                      string(docum-est.cod-emitente)        + "-" +  
                      docum-est.nro-docto                   + "-" + 
                      docum-est.serie-docto                 + "-" + 
                      docum-est.nat-operacao                + "-" + 
                      docum-est.cod-chave-aces-nf-eletro    + ".xml",
                      "\"). 
        
        /*ASSIGN cArquivo =  cCaminhoCompl   + "\" + docum-est.cod-estabel + "-" + string(year(docum-est.dt-trans)) + "-" +  string(MONTH(docum-est.dt-trans),'99') + "-" 
                    + string(DAY(docum-est.dt-trans),'99')  + "-" +
                      string(docum-est.cod-emitente) + docum-est.nro-docto + "-" + docum-est.serie-docto + "-" + docum-est.nat-operacao + "-" + docum-est.cod-chave-aces-nf-eletro + ".xml".
                      */


        FIND FIRST espec.dt-docum-est OF docum-est NO-LOCK NO-ERROR.
        IF docum-est.cod-observa = 3  /*devolucao cliente*/
            AND NOT AVAIL dt-docum-est THEN DO:
            FIND FIRST dt-docum-est
              WHERE dt-docum-est.cod-estabel  = docum-est.cod-estabel
              AND   dt-docum-est.cod-emitente = docum-est.cod-emitente
              AND   dt-docum-est.nro-docto    = docum-est.nro-docto
              AND   dt-docum-est.serie-docto  = docum-est.serie-docto
              AND   dt-docum-est.dt-emissao   = docum-est.dt-emissao
              AND   (dt-docum-est.nat-operacao = '1' OR dt-docum-est.nat-operacao = '') NO-LOCK NO-ERROR.
             
        END.
        IF AVAIL dt-docum-est THEN DO:
          /* MESSAGE cArquivo
               VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
           IF SEARCH(cArquivo) = ? THEN DO:
              COPY-LOB  dt-docum-est.arq-xml TO FILE cArquivo.
           END.                                               
           ASSIGN lGerou = YES.
        END.
        ELSE DO:
            ASSIGN lGerou = NO.
        END.
        CREATE tt.
        BUFFER-COPY docum-est TO tt.
        ASSIGN tt.log_xml = lGerou.
    END.
    
    OUTPUT TO c:\temp\nfe_xml.txt.
    FOR EACH tt:
        FIND FIRST emitente OF tt NO-LOCK NO-ERROR.
        FIND natur-oper OF tt NO-LOCK NO-ERROR.
        EXPORT DELIMITER "|" tt.cod-estabel 
                             tt.dt-trans 
                             tt.dt-emissao 
                             tt.cod-emitente 
                             emitente.nome-emit 
                             emitente.cgc 
                             emitente.cidade 
                             emitente.estado 
                             tt.nro-docto 
                             tt.serie-docto
                             tt.nat-operacao 
                             natur-oper.cod-cfop
                             IF tt.LOG_xml then "sim" ELSE "nÆo" .
    END.
    OUTPUT CLOSE.
    

    OS-COMMAND SILENT VALUE('start explorer ' + cCaminho).
    OS-COMMAND SILENT VALUE('start excel /N t:\especificos\excel\nfe_xml.xls').
    ASSIGN btExecutar:SENSITIVE = YES
           fidtIni:SENSITIVE = YES
            fiDtFim:SENSITIVE = YES.
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
       RUN set-position IN h_p-exihel ( 1.13 , 65.00 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fiCaminho:HANDLE IN FRAME f-cad , 'AFTER':U ).
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
  DISPLAY tgAno fiCaminho fidtIni fidtFim tgMes tgDia 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE tgAno fiCaminho fidtIni fidtFim btexecutar tgMes tgDia rt-button 
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

  {utp/ut9000.i "ESRE999" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .
  FIND FIRST im-param
      WHERE im-param.cod-param = 'caminho_exp_xml_entrada'
      NO-LOCK NO-ERROR.
  IF AVAIL im-param THEN DO:
     ASSIGN fiCaminho:SCREEN-VALUE IN FRAME {&FRAME-NAME} = im-param.val-param. 
  END.
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

