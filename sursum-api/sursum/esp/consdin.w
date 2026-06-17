&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS W-Win 
/*********************************************************************
* Copyright (C) 2000 by Progress Software Corporation. All rights    *
* reserved. Prior versions of this work may contain portions         *
* contributed by participants of Possenet.                           *
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



DEFINE VARIABLE hBoConsDin  AS HANDLE     NO-UNDO.
DEFINE VARIABLE hResult     AS HANDLE      NO-UNDO.
DEFINE VARIABLE hQuery      AS HANDLE      NO-UNDO.
DEFINE VARIABLE browseHdl   AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoArqIni   AS HANDLE      NO-UNDO.
DEFINE VARIABLE hServer     AS HANDLE      NO-UNDO.
DEFINE VARIABLE cArqIni     AS CHARACTER   NO-UNDO.

{esbo/bomsg.i}
{esbo/boArqIni.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartWindow
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS fiTabelas edCampos edCondicoes btExec ~
fitempo 
&Scoped-Define DISPLAYED-OBJECTS fiTabelas edCampos edCondicoes fitempo 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR W-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON btExec 
     LABEL "Executar" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE edCampos AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 106 BY 4 NO-UNDO.

DEFINE VARIABLE edCondicoes AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 106 BY 4 NO-UNDO.

DEFINE VARIABLE fiTabelas AS CHARACTER FORMAT "X(256)":U 
     LABEL "Tabelas" 
     VIEW-AS FILL-IN 
     SIZE 106 BY .79 NO-UNDO.

DEFINE VARIABLE fitempo AS CHARACTER FORMAT "X(256)":U 
     LABEL "Tempo em Milisegundos" 
      VIEW-AS TEXT 
     SIZE 12 BY .67
     FGCOLOR 12 FONT 1 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     fiTabelas AT ROW 2.17 COL 9 COLON-ALIGNED WIDGET-ID 4
     edCampos AT ROW 3.75 COL 11 NO-LABEL WIDGET-ID 8
     edCondicoes AT ROW 8.33 COL 11 NO-LABEL WIDGET-ID 10
     btExec AT ROW 12.83 COL 11 WIDGET-ID 2
     fitempo AT ROW 13 COL 42 COLON-ALIGNED WIDGET-ID 16
     "Campos:" VIEW-AS TEXT
          SIZE 6.29 BY .54 AT ROW 3.83 COL 4.72 WIDGET-ID 12
     "Condiá‰es:" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 8.38 COL 3 WIDGET-ID 14
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 126.14 BY 27.96
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
         TITLE              = "Consultas Dinamicas"
         HEIGHT             = 27.96
         WIDTH              = 126.14
         MAX-HEIGHT         = 42.38
         MAX-WIDTH          = 274.29
         VIRTUAL-HEIGHT     = 42.38
         VIRTUAL-WIDTH      = 274.29
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
   FRAME-NAME                                                           */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(W-Win)
THEN W-Win:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME W-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON END-ERROR OF W-Win /* Consultas Dinamicas */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL W-Win W-Win
ON WINDOW-CLOSE OF W-Win /* Consultas Dinamicas */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExec
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExec W-Win
ON CHOOSE OF btExec IN FRAME F-Main /* Executar */
DO:
  ASSIGN btExec:LABEL = "Processando..."
         btExec:SENSITIVE =  NO
         fiTempo:SCREEN-VALUE = 'calculando....'.
  ETIME(YES).
  RUN limparTTs IN hBoConsDin.
  RUN setDadosConsulta IN  hBoConsDin(INPUT fiTabelas:SCREEN-VALUE,
                                      INPUT edCampos:SCREEN-VALUE,
                                      INPUT edCondicoes:SCREEN-VALUE,
                                      '' ). //inner - somente na camada sql
  
  //verifica se tem erro nas definiá‰es passadas pela consulta
  RUN verificarErros.

  
  //executa consulta dinamica conforme as informaá‰es passadas e no formato informado
  RUN setNomeArqCsv IN hBoConsDin('c:\temp\result_' + STRING(TIME) + '.csv').
  RUN execConsulta IN hBoConsDin('csv').




  //retorna o handle da tabela temporaria para manipulaá∆o dos dados.
  RUN getHandleResult IN hBoConsDin(OUTPUT hResult).

  RUN exportarDados.
  ASSIGN fiTempo:SCREEN-VALUE = STRING(ETIME).
  ASSIGN btExec:LABEL = "Executar"
         btExec:SENSITIVE =  YES.
  


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
  DISPLAY fiTabelas edCampos edCondicoes fitempo 
      WITH FRAME F-Main IN WINDOW W-Win.
  ENABLE fiTabelas edCampos edCondicoes btExec fitempo 
      WITH FRAME F-Main IN WINDOW W-Win.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW W-Win.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE exportarDados W-Win 
PROCEDURE exportarDados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/*DEFINE VARIABLE colunaIni AS CHARACTER   NO-UNDO.
DEFINE VARIABLE linhaIni AS CHARACTER   NO-UNDO.*/


/*MESSAGE LIST-QUERY-ATTRS(btExec:HANDLE IN FRAME {&FRAME-NAME} )
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
*/
/*MESSAGE VALID-HANDLE(hResult)
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
/*CREATE QUERY hQuery.
hQuery:SET-BUFFERS(hResult). 
hQuery:QUERY-PREPARE("FOR EACH ttResult ").
hQuery:QUERY-OPEN.
OUTPUT TO value("c:\temp\resultado_" + STRING(TIME) + ".txt").
REPEAT:
  hQuery:GET-NEXT().
  IF hQuery:QUERY-OFF-END THEN LEAVE.
  DISPLAY 
    hResult:BUFFER-FIELD('val-param'):BUFFER-VALUE() .
END.

hQuery:QUERY-CLOSE().
DELETE OBJECT hQuery.
OUTPUT CLOSE.*/
/*CREATE BROWSE browseHdl
  ASSIGN 
    TITLE     = "Dynamic Browse"
    FRAME     = FRAME {&FRAME-NAME}:HANDLE
    QUERY     = hQuery
    X         = btExec:X 
    Y         = btExec:Y + 2 
    WIDTH     = 74
    DOWN      = 10
    VISIBLE   = YES
    READ-ONLY = NO
    SENSITIVE = TRUE.

 */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-create-objects W-Win 
PROCEDURE local-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  DEFINE VARIABLE cAppServer     AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE cServAppServer AS CHARACTER   NO-UNDO.
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'create-objects':U ) .
  RUN esbo/boArqIni.p PERSISTENT SET hBoArqIni.
  ASSIGN cArqIni =  SEARCH('consdin.ini').
  /*MESSAGE cArqIni
      VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
  IF cArqIni <> ? THEN DO:
     RUN setArquivoIni IN hBoArqIni(cArqIni).                                    
     RUN getDados IN hBoArqIni.                                                        
     RUN getVlChave IN hBoArqIni('appserver', OUTPUT cAppServer).                        
     IF cAppServer <> '' THEN DO:                                                      
         /*MESSAGE 'vou executar via appserver'                                          
             VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.                                 */
        RUN getVlChave IN hBoArqIni('servAppServer', OUTPUT cServAppServer).
        IF cServAppServer <> '' THEN DO:
           CREATE SERVER hServer.                                                         
           hServer:CONNECT("-AppService " + cAppServer + " -H " + cServAppServer) NO-ERROR.         
           IF NOT hServer:CONNECTED() THEN DO:
              MESSAGE 'O AppServer n∆o pode ser conectado e por isto o programa ser† rodado localmente'
                  VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
              RUN esbo/boConsDin.p PERSISTENT SET hBoConsDin.                                
           END.
           ELSE DO:
              RUN esbo/boConsDin.p PERSISTENT SET hBoConsDin ON SERVER hServer.              
           END.
             

        END.
        
     END.                                                                              
     ELSE DO:                                                                          
        RUN esbo/boConsDin.p PERSISTENT SET hBoConsDin.                                
     END.                                                                              
     
  END.
  ELSE DO:
     RUN esbo/boConsDin.p PERSISTENT SET hBoConsDin.                                
  END.
  
  RUN iniciarBos IN hBoConsDin.                                                     
  
  
  
  
  
  
  
  
  
  
  
  
  
  /* Code placed here will execute AFTER standard behavior.    */

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
   RUN finalizarBos IN hBoConsDin.  
   IF VALID-HANDLE(hboConsdin) THEN DO:
      RUN finalizarBos IN hBoConsDin. 
      DELETE PROCEDURE hBoConsDin.
   END.
     

   IF VALID-HANDLE(hBoArqIni) THEN DO:
      DELETE PROCEDURE hBoConsDin.
   END.

   IF VALID-HANDLE(hServer) THEN DO:
      hServer:DISCONNECT().
      DELETE OBJECT hServer.
   END.

   APPLY "CLOSE":U TO THIS-PROCEDURE.
   
   RETURN.
       
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

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this SmartWindow, and there are no
     tables specified in any contained Browse, Query, or Frame. */

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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE verificarErros W-Win 
PROCEDURE verificarErros :
RUN getTTmsg IN hBoConsDin('erro',OUTPUT TABLE ttMsg) . 
FOR EACH ttMsg.
    MESSAGE 'Erro:' ttmsg.cod SKIP
            'Descriá∆o:' ttmsg.descricao
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

