&ANALYZE-SUSPEND _VERSION-NUMBER AB_v10r12 GUI ADM2
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME gDialog
{adecomm/appserv.i}
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS gDialog 
/*------------------------------------------------------------------------

  File: 

  Description: from cntnrdlg.w - ADM2 SmartDialog Template

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

{src/adm2/widgetprto.i}
{esbo/boMetaDados.i}
{util.i}
DEFINE TEMP-TABLE ttCamposAux LIKE ttCampos.
DEFINE INPUT  PARAMETER pTabelaPrinc AS CHARACTER   NO-UNDO.
DEFINE INPUT PARAMETER TABLE FOR ttCampos .

DEFINE VARIABLE hBo         AS HANDLE      NO-UNDO.
DEFINE VARIABLE cTbSel      AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cBancoSel   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cAcao       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cAcaoForm   AS CHARACTER   NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

&Scoped-define ADM-SUPPORTED-LINKS Data-Target,Data-Source,Page-Target,Update-Source,Update-Target

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME gDialog
&Scoped-define BROWSE-NAME brRelacs

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES ttRelacs

/* Definitions for BROWSE brRelacs                                      */
&Scoped-define FIELDS-IN-QUERY-brRelacs   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brRelacs   
&Scoped-define SELF-NAME brRelacs
&Scoped-define QUERY-STRING-brRelacs FOR EACH ttRelacs. IF NUM-RESULTS('brRelacs') = 0 THEN    ASSIGN btCriar:SENSITIVE = TRUE           btAlterar:SENSITIVE = FALSE           btExcluir:SENSITIVE = FALSE  . ELSE    ASSIGN btCriar:SENSITIVE   = TRUE           btAlterar:SENSITIVE = TRUE           btExcluir:SENSITIVE  = TRUE
&Scoped-define OPEN-QUERY-brRelacs OPEN QUERY {&SELF-NAME} FOR EACH ttRelacs. IF NUM-RESULTS('brRelacs') = 0 THEN    ASSIGN btCriar:SENSITIVE = TRUE           btAlterar:SENSITIVE = FALSE           btExcluir:SENSITIVE = FALSE  . ELSE    ASSIGN btCriar:SENSITIVE   = TRUE           btAlterar:SENSITIVE = TRUE           btExcluir:SENSITIVE  = TRUE .
&Scoped-define TABLES-IN-QUERY-brRelacs ttRelacs
&Scoped-define FIRST-TABLE-IN-QUERY-brRelacs ttRelacs


/* Definitions for DIALOG-BOX gDialog                                   */
&Scoped-define OPEN-BROWSERS-IN-QUERY-gDialog ~
    ~{&OPEN-QUERY-brRelacs}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-8 RECT-9 RECT-12 btBuscarCps brRelacs ~
Btn_OK Btn_Cancel 
&Scoped-Define DISPLAYED-OBJECTS fiTbOri fiTbDestino cbFuncao02 cbFuncao01 ~
cbCpsTb02 cbCpsTb01 fiIni01 fiIni02 fiFim01 fiFim02 edTransf01 edTransf02 

/* Custom List Definitions                                              */
/* btsBrowse,objsFormRelac,condFuncao01,condFuncao02,condFuncao03,List-6 */
&Scoped-define btsBrowse btAlterar btCriar btExcluir 
&Scoped-define objsFormRelac cbFuncao02 cbFuncao01 cbCpsTb02 cbCpsTb01 ~
fiIni01 fiIni02 fiFim01 fiFim02 edTransf01 edTransf02 btConfirmar ~
btCancelar 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON btAlterar  NO-FOCUS
     LABEL "Alterar Rela‡Æo" 
     SIZE 16.8 BY 1.14.

DEFINE BUTTON btBuscarCps 
     LABEL "..." 
     SIZE 6 BY 1.14.

DEFINE BUTTON btCancelar 
     LABEL "Cancelar" 
     SIZE 12.8 BY 1.14.

DEFINE BUTTON btConfirmar 
     LABEL "Confirmar" 
     SIZE 12 BY 1.14.

DEFINE BUTTON btCriar  NO-FOCUS
     LABEL "Criar Rela‡Æo" 
     SIZE 16.8 BY 1.14.

DEFINE BUTTON btExcluir 
     LABEL "Excluir Rela‡Æo" 
     SIZE 16.8 BY 1.14.

DEFINE BUTTON Btn_Cancel AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 15 BY 1.14.

DEFINE BUTTON Btn_OK AUTO-GO 
     LABEL "Salvar" 
     SIZE 15 BY 1.14 TOOLTIP "Salva as Relações".

DEFINE VARIABLE cbCpsTb01 AS CHARACTER 
     LABEL "Campo Origem" 
     VIEW-AS COMBO-BOX SORT INNER-LINES 5
     LIST-ITEMS "Item 1" 
     DROP-DOWN AUTO-COMPLETION
     SIZE 33.8 BY 1 NO-UNDO.

DEFINE VARIABLE cbCpsTb02 AS CHARACTER 
     LABEL "Campo Destino" 
     VIEW-AS COMBO-BOX SORT INNER-LINES 5
     LIST-ITEMS "Item 1" 
     DROP-DOWN AUTO-COMPLETION
     SIZE 33.8 BY 1 NO-UNDO.

DEFINE VARIABLE cbFuncao01 AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 0 
     LABEL "Fun‡Æo" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nenhuma",0,
                     "Conv.P/Inteiro",1,
                     "Conv.p/Data",2,
                     "Conv.P/String",3,
                     "Conv.P/Decimal",4,
                     "Conv.P/Dt.Hora",5,
                     "Substring",6,
                     "Livre",7
     DROP-DOWN-LIST
     SIZE 33.8 BY 1 NO-UNDO.

DEFINE VARIABLE cbFuncao02 AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 0 
     LABEL "Fun‡Æo" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Nenhuma",0,
                     "Conv.P/Inteiro",1,
                     "Conv.p/Data",2,
                     "Conv.P/String",3,
                     "Conv.P/Decimal",4,
                     "Conv.P/Dt.Hora",5,
                     "Substring",6,
                     "Livre",7
     DROP-DOWN-LIST
     SIZE 33.8 BY 1 NO-UNDO.

DEFINE VARIABLE edTransf01 AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 52 BY 3.38 NO-UNDO.

DEFINE VARIABLE edTransf02 AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 52 BY 3.38 NO-UNDO.

DEFINE VARIABLE fiFim01 AS INTEGER FORMAT ">>9":U INITIAL 0 
     LABEL "Fim" 
     VIEW-AS FILL-IN 
     SIZE 7 BY 1 TOOLTIP "Quantidade de Caractres ou zero para ir até o tamanho final" NO-UNDO.

DEFINE VARIABLE fiFim02 AS INTEGER FORMAT ">>9":U INITIAL 0 
     LABEL "Fim" 
     VIEW-AS FILL-IN 
     SIZE 7 BY 1 TOOLTIP "Quantidade de Caractres ou zero para ir até o tamanho final" NO-UNDO.

DEFINE VARIABLE fiIni01 AS INTEGER FORMAT ">>9":U INITIAL 0 
     LABEL "Ini." 
     VIEW-AS FILL-IN 
     SIZE 7 BY 1 NO-UNDO.

DEFINE VARIABLE fiIni02 AS INTEGER FORMAT ">>9":U INITIAL 0 
     LABEL "Ini." 
     VIEW-AS FILL-IN 
     SIZE 7 BY 1 NO-UNDO.

DEFINE VARIABLE fiTbDestino AS CHARACTER FORMAT "X(50)":U 
     LABEL "Destino" 
     VIEW-AS FILL-IN 
     SIZE 40 BY 1
     FGCOLOR 9 FONT 6 NO-UNDO.

DEFINE VARIABLE fiTbOri AS CHARACTER FORMAT "X(50)":U 
     LABEL "Origem" 
     VIEW-AS FILL-IN 
     SIZE 40 BY 1
     FGCOLOR 9 FONT 6 NO-UNDO.

DEFINE RECTANGLE RECT-12
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 112 BY 1.81.

DEFINE RECTANGLE RECT-8
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 111 BY 1.67
     BGCOLOR 8 FGCOLOR 15 .

DEFINE RECTANGLE RECT-9
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 110 BY 11.19.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY brRelacs FOR 
      ttRelacs SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE brRelacs
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brRelacs gDialog _FREEFORM
  QUERY brRelacs DISPLAY
      
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 112 BY 9.14 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME gDialog
     btAlterar AT ROW 12.91 COL 20 WIDGET-ID 62
     btCriar AT ROW 12.91 COL 3 WIDGET-ID 8
     btBuscarCps AT ROW 1.52 COL 108.2 WIDGET-ID 20
     fiTbOri AT ROW 1.62 COL 11.8 COLON-ALIGNED WIDGET-ID 16
     fiTbDestino AT ROW 1.62 COL 64.4 COLON-ALIGNED WIDGET-ID 18
     brRelacs AT ROW 3.48 COL 3 WIDGET-ID 200
     btExcluir AT ROW 12.91 COL 36.8 WIDGET-ID 14
     cbFuncao02 AT ROW 15.29 COL 77 COLON-ALIGNED WIDGET-ID 50
     cbFuncao01 AT ROW 15.38 COL 21 COLON-ALIGNED WIDGET-ID 44
     cbCpsTb02 AT ROW 16.43 COL 77 COLON-ALIGNED WIDGET-ID 40
     cbCpsTb01 AT ROW 16.48 COL 21 COLON-ALIGNED WIDGET-ID 38
     fiIni01 AT ROW 17.91 COL 20.4 COLON-ALIGNED WIDGET-ID 46
     fiIni02 AT ROW 17.91 COL 77 COLON-ALIGNED WIDGET-ID 56
     fiFim01 AT ROW 17.95 COL 47.8 COLON-ALIGNED WIDGET-ID 48
     fiFim02 AT ROW 17.95 COL 103.4 COLON-ALIGNED WIDGET-ID 54
     edTransf01 AT ROW 20.05 COL 5 NO-LABEL WIDGET-ID 34
     edTransf02 AT ROW 20.05 COL 61 NO-LABEL WIDGET-ID 58
     btConfirmar AT ROW 24.33 COL 6 WIDGET-ID 30
     btCancelar AT ROW 24.33 COL 18 WIDGET-ID 32
     Btn_OK AT ROW 28.38 COL 4
     Btn_Cancel AT ROW 28.38 COL 19.2
     "Resultado" VIEW-AS TEXT
          SIZE 15 BY .62 AT ROW 19.33 COL 61.4 WIDGET-ID 60
          FGCOLOR 9 FONT 6
     "Resultado" VIEW-AS TEXT
          SIZE 15 BY .62 AT ROW 19.33 COL 5.2 WIDGET-ID 52
          FGCOLOR 9 FONT 6
     "Rela‡Æo" VIEW-AS TEXT
          SIZE 9.2 BY .62 AT ROW 14.33 COL 6 WIDGET-ID 28
     RECT-8 AT ROW 28.14 COL 3 WIDGET-ID 2
     RECT-9 AT ROW 14.57 COL 4 WIDGET-ID 26
     RECT-12 AT ROW 1.19 COL 3 WIDGET-ID 36
     SPACE(0.39) SKIP(27.42)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         TITLE "Incluir Rela‡äes Entre Tabelas"
         DEFAULT-BUTTON Btn_OK CANCEL-BUTTON Btn_Cancel WIDGET-ID 100
         CONTEXT-HELP.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartDialog
   Allow: Basic,Browse,DB-Fields,Query,Smart
   Container Links: Data-Target,Data-Source,Page-Target,Update-Source,Update-Target
   Other Settings: COMPILE APPSERVER
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB gDialog 
/* ************************* Included-Libraries *********************** */

{src/adm2/containr.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR DIALOG-BOX gDialog
   FRAME-NAME                                                           */
/* BROWSE-TAB brRelacs fiTbDestino gDialog */
ASSIGN 
       FRAME gDialog:SCROLLABLE       = FALSE.

/* SETTINGS FOR BUTTON btAlterar IN FRAME gDialog
   NO-ENABLE 1                                                          */
/* SETTINGS FOR BUTTON btCancelar IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR BUTTON btConfirmar IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR BUTTON btCriar IN FRAME gDialog
   NO-ENABLE 1                                                          */
/* SETTINGS FOR BUTTON btExcluir IN FRAME gDialog
   NO-ENABLE 1                                                          */
/* SETTINGS FOR COMBO-BOX cbCpsTb01 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR COMBO-BOX cbCpsTb02 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR COMBO-BOX cbFuncao01 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR COMBO-BOX cbFuncao02 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR EDITOR edTransf01 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR EDITOR edTransf02 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR FILL-IN fiFim01 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR FILL-IN fiFim02 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR FILL-IN fiIni01 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR FILL-IN fiIni02 IN FRAME gDialog
   NO-ENABLE 2                                                          */
/* SETTINGS FOR FILL-IN fiTbDestino IN FRAME gDialog
   NO-ENABLE                                                            */
ASSIGN 
       fiTbDestino:READ-ONLY IN FRAME gDialog        = TRUE.

/* SETTINGS FOR FILL-IN fiTbOri IN FRAME gDialog
   NO-ENABLE                                                            */
ASSIGN 
       fiTbOri:READ-ONLY IN FRAME gDialog        = TRUE.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brRelacs
/* Query rebuild information for BROWSE brRelacs
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH ttRelacs.
IF NUM-RESULTS('brRelacs') = 0 THEN
   ASSIGN btCriar:SENSITIVE = TRUE
          btAlterar:SENSITIVE = FALSE
          btExcluir:SENSITIVE = FALSE  .
ELSE
   ASSIGN btCriar:SENSITIVE   = TRUE
          btAlterar:SENSITIVE = TRUE
          btExcluir:SENSITIVE  = TRUE .
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE brRelacs */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK DIALOG-BOX gDialog
/* Query rebuild information for DIALOG-BOX gDialog
     _Options          = "SHARE-LOCK"
     _Query            is NOT OPENED
*/  /* DIALOG-BOX gDialog */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME gDialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL gDialog gDialog
ON WINDOW-CLOSE OF FRAME gDialog /* Incluir Rela‡äes Entre Tabelas */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btBuscarCps
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btBuscarCps gDialog
ON CHOOSE OF btBuscarCps IN FRAME gDialog /* ... */
DO:
   REPEAT:
    RUN db/sursum79.w(OUTPUT cBancoSel,OUTPUT ctbSel,OUTPUT cAcao).
    IF cAcao = 'ok' AND cTbSel  = pTabelaPrinc THEN
       MESSAGE 'A Tabela de Destino não poder ser igual a tabela de destino'
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
    ELSE LEAVE.
  END.
  

  IF cAcao = 'ok' THEN DO:
     ASSIGN fiTbDestino:SCREEN-VALUE IN FRAME {&FRAME-NAME} = upper(cTbSel).
     EMPTY TEMP-TABLE ttCamposAux.
     RUN limparFiltros IN hBo.
     RUN setBanco IN hBo(cBancoSel).
     RUN setTabela IN hBo(cTbSel).
     RUN limparTTCampos IN hBo.
     RUN getCpsTb IN hBo.
     RUN getTTCps IN hBo(OUTPUT TABLE ttCamposAux).
     RUN preencherCpstb(TEMP-TABLE ttCamposAux:DEFAULT-BUFFER-HANDLE,'destino').
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btCriar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btCriar gDialog
ON CHOOSE OF btCriar IN FRAME gDialog /* Criar Rela‡Æo */
DO:
  ASSIGN cAcaoForm = 'criar'.
  ENABLE {&objsFormRelac} WITH FRAME {&FRAME-NAME} .
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExcluir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExcluir gDialog
ON CHOOSE OF btExcluir IN FRAME gDialog /* Excluir Rela‡Æo */
DO:
  ASSIGN cAcaoForm = 'alterar'.
  ENABLE {&objsFormRelac} WITH FRAME {&FRAME-NAME} .
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbCpsTb01
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbCpsTb01 gDialog
ON VALUE-CHANGED OF cbCpsTb01 IN FRAME gDialog /* Campo Origem */
DO:
  ASSIGN btCriar:SENSITIVE =  cbCpsTb01:SCREEN-VALUE <> '' AND
                              cbCpsTb02:SCREEN-VALUE <> ''.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbCpsTb02
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbCpsTb02 gDialog
ON VALUE-CHANGED OF cbCpsTb02 IN FRAME gDialog /* Campo Destino */
DO:
  ASSIGN btCriar:SENSITIVE =  cbCpsTb01:SCREEN-VALUE <> '' AND
                              cbCpsTb02:SCREEN-VALUE <> ''.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbFuncao01
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbFuncao01 gDialog
ON VALUE-CHANGED OF cbFuncao01 IN FRAME gDialog /* Fun‡Æo */
DO:
  IF SELF:SCREEN-VALUE = '6' THEN
     ASSIGN fiIni01:SENSITIVE = TRUE
            fiFim01:SENSITIVE = TRUE.
  ELSE DO:
     ASSIGN fiIni01:SENSITIVE = FALSE
            fiFim01:SENSITIVE = FALSE
            fiIni01:SCREEN-VALUE  = '0'
            fiFim01:SCREEN-VALUE = '0'.
  END.
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME cbFuncao02
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cbFuncao02 gDialog
ON VALUE-CHANGED OF cbFuncao02 IN FRAME gDialog /* Fun‡Æo */
DO:
  IF cbFuncao02:SCREEN-VALUE = '6' THEN
     ASSIGN fiIni02:SENSITIVE = TRUE
            fiFim02:SENSITIVE = TRUE.
  ELSE DO:
     ASSIGN fiIni02:SENSITIVE = FALSE
            fiFim02:SENSITIVE = FALSE
            fiIni02:SCREEN-VALUE  = '0'
            fiFim02:SCREEN-VALUE = '0'.
  END.
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME brRelacs
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK gDialog 


/* ***************************  Main Block  *************************** */

{src/adm2/dialogmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects gDialog  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI gDialog  _DEFAULT-DISABLE
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
  HIDE FRAME gDialog.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI gDialog  _DEFAULT-ENABLE
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
  DISPLAY fiTbOri fiTbDestino cbFuncao02 cbFuncao01 cbCpsTb02 cbCpsTb01 fiIni01 
          fiIni02 fiFim01 fiFim02 edTransf01 edTransf02 
      WITH FRAME gDialog.
  ENABLE RECT-8 RECT-9 RECT-12 btBuscarCps brRelacs Btn_OK Btn_Cancel 
      WITH FRAME gDialog.
  {&OPEN-BROWSERS-IN-QUERY-gDialog}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE initializeObject gDialog 
PROCEDURE initializeObject :
/*------------------------------------------------------------------------------
  Purpose:     Super Override
  Parameters:  
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  RUN SUPER.

  ASSIGN fiTbOri:SCREEN-VALUE IN FRAME {&FRAME-NAME} = UPPER(pTabelaPrinc).

  RUN preencherCpstb(TEMP-TABLE ttCampos:DEFAULT-BUFFER-HANDLE,'origem') .

  /* Code placed here will execute AFTER standard behavior.    */
  //ASSIGN btCriar:SENSITIVE = NO .

  RUN esbo/boMetaDados.p PERSISTENT SET hBo .
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE preencherCpsTb gDialog 
PROCEDURE preencherCpsTb :
DEFINE INPUT  PARAMETER phTT     AS HANDLE NO-UNDO.
DEFINE INPUT  PARAMETER destino  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cLista           AS CHARACTER   NO-UNDO.
RUN extrairListaCpsTb( phTT,
                      'nome',
                      '',
                      OUTPUT cLista ).      

CASE destino:
    WHEN 'origem' THEN
        ASSIGN cbCpsTb01:LIST-ITEMS IN FRAME {&FRAME-NAME} = cLista .
    WHEN 'destino' THEN
        ASSIGN cbCpsTb02:LIST-ITEMS IN FRAME {&FRAME-NAME} = cLista .

END CASE.





END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

