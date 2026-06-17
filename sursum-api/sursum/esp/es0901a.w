&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-window 
/*:T *******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i es0901a 9.99.99.999}

/* Chamada a include do gerenciador de licenáas. Necessario alterar os parametros */
/*                                                                                */
/* <programa>:  Informar qual o nome do programa.                                 */
/* <m¢dulo>:  Informar qual o m¢dulo a qual o programa pertence.                  */

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i <programa> <m¢dulo>}
&ENDIF

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

DEFINE INPUT  PARAMETER pModeloNegocioId AS INTEGER     NO-UNDO.

{esbo/boEsrn03.i RowObject}

DEFINE VARIABLE hBo AS HANDLE      NO-UNDO.
DEFINE TEMP-TABLE ttReg LIKE RowObject .
DEFINE VARIABLE cAcaoCorrente AS CHARACTER   NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE JanelaDetalhe
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME brItens

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES RowObject

/* Definitions for BROWSE brItens                                       */
&Scoped-define FIELDS-IN-QUERY-brItens RowObject.chave   
&Scoped-define ENABLED-FIELDS-IN-QUERY-brItens   
&Scoped-define SELF-NAME brItens
&Scoped-define QUERY-STRING-brItens FOR EACH RowObject
&Scoped-define OPEN-QUERY-brItens OPEN QUERY {&SELF-NAME} FOR EACH RowObject .
&Scoped-define TABLES-IN-QUERY-brItens RowObject
&Scoped-define FIRST-TABLE-IN-QUERY-brItens RowObject


/* Definitions for FRAME F-Main                                         */
&Scoped-define OPEN-BROWSERS-IN-QUERY-F-Main ~
    ~{&OPEN-QUERY-brItens}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 RECT-11 RECT-12 RECT-14 RECT-15 ~
brItens btIncluir btAlterar btExcluir cbTipoItem fiChave cbTipoComparativo ~
fiPrioridade cbTipoDadoValido edDadoValido tgObrigatorio btConfirmar ~
btCancelar btLiberar BtInutilizar bt-ok bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS cbTipoItem fiChave cbTipoComparativo ~
fiPrioridade cbTipoDadoValido edDadoValido tgObrigatorio 

/* Custom List Definitions                                              */
/* BotoesAcoes,BotoesConfirm,CpsForm,ObjsForm,BotoesAcoesCompl,List-6   */
&Scoped-define BotoesAcoes btIncluir btAlterar btExcluir 
&Scoped-define BotoesConfirm btConfirmar btCancelar 
&Scoped-define CpsForm cbTipoItem fiChave cbTipoComparativo fiPrioridade ~
cbTipoDadoValido 
&Scoped-define ObjsForm btIncluir btAlterar btExcluir cbTipoItem fiChave ~
cbTipoComparativo fiPrioridade cbTipoDadoValido btConfirmar btCancelar ~
btLiberar BtInutilizar 
&Scoped-define BotoesAcoesCompl btLiberar BtInutilizar 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-window AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "Sair" 
     SIZE 10 BY 1.

DEFINE BUTTON btAlterar 
     LABEL "Alterar" 
     SIZE 8.43 BY 1.13.

DEFINE BUTTON btCancelar 
     LABEL "Cancelar" 
     SIZE 8.43 BY 1.13.

DEFINE BUTTON btConfirmar 
     LABEL "Confirmar" 
     SIZE 8.43 BY 1.13.

DEFINE BUTTON btExcluir 
     LABEL "Excluir" 
     SIZE 8.43 BY 1.13.

DEFINE BUTTON btIncluir 
     LABEL "Incluir" 
     SIZE 8.43 BY 1.13.

DEFINE BUTTON BtInutilizar 
     LABEL "Inutilizar" 
     SIZE 8.43 BY 1.13.

DEFINE BUTTON btLiberar 
     LABEL "Liberar" 
     SIZE 8.43 BY 1.13.

DEFINE VARIABLE cbTipoComparativo AS INTEGER FORMAT ">9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Igual",1,
                     "Menor Igual",2,
                     "Maior Igual",3,
                     "Contido",4
     DROP-DOWN-LIST
     SIZE 23.43 BY 1 NO-UNDO.

DEFINE VARIABLE cbTipoDadoValido AS INTEGER FORMAT ">9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Lista Simples",1,
                     "Lista Composta",2,
                     "Programa",3
     DROP-DOWN-LIST
     SIZE 23.43 BY 1 NO-UNDO.

DEFINE VARIABLE cbTipoItem AS INTEGER FORMAT ">9":U INITIAL 1 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Entrada",1,
                     "Sa°da",2
     DROP-DOWN-LIST
     SIZE 23.43 BY .88 NO-UNDO.

DEFINE VARIABLE edDadoValido AS CHARACTER 
     VIEW-AS EDITOR
     SIZE 34 BY 2.5 NO-UNDO.

DEFINE VARIABLE fiChave AS CHARACTER FORMAT "X(50)":U 
     VIEW-AS FILL-IN 
     SIZE 24 BY .79 NO-UNDO.

DEFINE VARIABLE fiPrioridade AS INTEGER FORMAT ">>>,>>9":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11.72 BY .79 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 97 BY 1.38
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-11
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 37 BY 16.96.

DEFINE RECTANGLE RECT-12
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 36.72 BY 1.5
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-14
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 36.72 BY 1.5
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-15
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 56.86 BY 1.5.

DEFINE VARIABLE tgObrigatorio AS LOGICAL INITIAL no 
     LABEL "Obrigat¢rio?" 
     VIEW-AS TOGGLE-BOX
     SIZE 18.86 BY .83
     FONT 0 NO-UNDO.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY brItens FOR 
      RowObject SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE brItens
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS brItens w-window _FREEFORM
  QUERY brItens DISPLAY
      RowObject.chave
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 57.29 BY 15.21
         FONT 1.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     brItens AT ROW 1.54 COL 2.86 WIDGET-ID 200
     btIncluir AT ROW 1.71 COL 63 WIDGET-ID 28
     btAlterar AT ROW 1.71 COL 71.29 WIDGET-ID 26
     btExcluir AT ROW 1.71 COL 79.72 WIDGET-ID 30
     cbTipoItem AT ROW 3.71 COL 62.43 COLON-ALIGNED NO-LABEL WIDGET-ID 48
     fiChave AT ROW 5.46 COL 62.29 COLON-ALIGNED NO-LABEL WIDGET-ID 2
     cbTipoComparativo AT ROW 7.13 COL 62.43 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     fiPrioridade AT ROW 9 COL 62.29 COLON-ALIGNED NO-LABEL WIDGET-ID 12
     cbTipoDadoValido AT ROW 10.79 COL 62.43 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     edDadoValido AT ROW 13.08 COL 64 NO-LABEL WIDGET-ID 42
     tgObrigatorio AT ROW 15.79 COL 64.14 WIDGET-ID 46
     btConfirmar AT ROW 17 COL 63 WIDGET-ID 16
     btCancelar AT ROW 17 COL 71.29 WIDGET-ID 18
     btLiberar AT ROW 17.13 COL 3.43 WIDGET-ID 36
     BtInutilizar AT ROW 17.13 COL 11.72 WIDGET-ID 38
     bt-ok AT ROW 18.88 COL 3
     bt-cancelar AT ROW 18.88 COL 14
     bt-ajuda AT ROW 18.88 COL 88.14
     "Tipo ITem" VIEW-AS TEXT
          SIZE 16.72 BY .54 AT ROW 3.08 COL 64.29 WIDGET-ID 50
          FONT 0
     "Lista Ou C¢digo Programa" VIEW-AS TEXT
          SIZE 31.72 BY .92 TOOLTIP "Preencha o valor conforme o Tipo de Dado V†lido" AT ROW 12.04 COL 64.29 WIDGET-ID 44
          FONT 0
     "Tp.Comparativo" VIEW-AS TEXT
          SIZE 16.72 BY .54 AT ROW 6.5 COL 64.29 WIDGET-ID 10
          FONT 0
     "Chave" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 4.79 COL 64.29 WIDGET-ID 6
          FONT 0
     "Prioridade" VIEW-AS TEXT
          SIZE 14.72 BY .54 AT ROW 8.33 COL 64.29 WIDGET-ID 14
          FONT 0
     "Tp. Dados Validos" VIEW-AS TEXT
          SIZE 24.72 BY .54 AT ROW 10.17 COL 64.29 WIDGET-ID 34
          FONT 0
     RECT-1 AT ROW 18.67 COL 2
     RECT-11 AT ROW 1.54 COL 62 WIDGET-ID 4
     RECT-12 AT ROW 16.83 COL 62.14 WIDGET-ID 20
     RECT-14 AT ROW 1.5 COL 62.14 WIDGET-ID 24
     RECT-15 AT ROW 16.92 COL 3.14 WIDGET-ID 40
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 98.43 BY 19.17
         FONT 1 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: JanelaDetalhe
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-window ASSIGN
         HIDDEN             = YES
         TITLE              = "Itens do Modelo de Neg¢cio"
         HEIGHT             = 19.17
         WIDTH              = 98.43
         MAX-HEIGHT         = 41.33
         MAX-WIDTH          = 274.29
         VIRTUAL-HEIGHT     = 41.33
         VIRTUAL-WIDTH      = 274.29
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-window 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-window.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-window
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
/* BROWSE-TAB brItens RECT-15 F-Main */
/* SETTINGS FOR BUTTON bt-cancelar IN FRAME F-Main
   NO-ENABLE                                                            */
ASSIGN 
       bt-cancelar:HIDDEN IN FRAME F-Main           = TRUE.

/* SETTINGS FOR BUTTON btAlterar IN FRAME F-Main
   1 4                                                                  */
/* SETTINGS FOR BUTTON btCancelar IN FRAME F-Main
   2 4                                                                  */
/* SETTINGS FOR BUTTON btConfirmar IN FRAME F-Main
   2 4                                                                  */
/* SETTINGS FOR BUTTON btExcluir IN FRAME F-Main
   1 4                                                                  */
/* SETTINGS FOR BUTTON btIncluir IN FRAME F-Main
   1 4                                                                  */
/* SETTINGS FOR BUTTON BtInutilizar IN FRAME F-Main
   4 5                                                                  */
/* SETTINGS FOR BUTTON btLiberar IN FRAME F-Main
   4 5                                                                  */
/* SETTINGS FOR COMBO-BOX cbTipoComparativo IN FRAME F-Main
   3 4                                                                  */
/* SETTINGS FOR COMBO-BOX cbTipoDadoValido IN FRAME F-Main
   3 4                                                                  */
/* SETTINGS FOR COMBO-BOX cbTipoItem IN FRAME F-Main
   3 4                                                                  */
/* SETTINGS FOR FILL-IN fiChave IN FRAME F-Main
   3 4                                                                  */
/* SETTINGS FOR FILL-IN fiPrioridade IN FRAME F-Main
   3 4                                                                  */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
THEN w-window:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE brItens
/* Query rebuild information for BROWSE brItens
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH RowObject .
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE brItens */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-window
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON END-ERROR OF w-window /* Itens do Modelo de Neg¢cio */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-window w-window
ON WINDOW-CLOSE OF w-window /* Itens do Modelo de Neg¢cio */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-window
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-window
ON CHOOSE OF bt-cancelar IN FRAME F-Main /* Cancelar */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-window
ON CHOOSE OF bt-ok IN FRAME F-Main /* Sair */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btAlterar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btAlterar w-window
ON CHOOSE OF btAlterar IN FRAME F-Main /* Alterar */
DO:
  ENABLE {&botoesConfirm} WITH FRAME {&FRAME-NAME} .
  //RUN tratarBotoes('incluir').
  DISABLE {&botoesForm} WITH FRAME {&FRAME-NAME}.
  ENABLE {&cpsForm}    WITH FRAME {&FRAME-NAME} .
  ASSIGN cAcaoCorrente = 'alterar'.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btCancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btCancelar w-window
ON CHOOSE OF btCancelar IN FRAME F-Main /* Cancelar */
DO:
  RUN tratarBotoesForm.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btConfirmar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btConfirmar w-window
ON CHOOSE OF btConfirmar IN FRAME F-Main /* Confirmar */
DO:
  RUN tratarBotoesForm.
  RUN incluirItensModelo.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExcluir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExcluir w-window
ON CHOOSE OF btExcluir IN FRAME F-Main /* Excluir */
DO:
  MESSAGE "Confirma Exclus∆o do Registro" 
      VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO  
      SET  lExcluir AS LOGICAL.

  IF lExcluir THEN DO:
     RUN excluirRegistro.
     {&openquery-brItens}
     APPLY 'value-changed' TO BROWSE brItens.
  END.


END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btIncluir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btIncluir w-window
ON CHOOSE OF btIncluir IN FRAME F-Main /* Incluir */
DO:
  ENABLE {&botoesConfirm} WITH FRAME {&FRAME-NAME} .
  //RUN tratarBotoes('incluir').
  DISABLE {&botoesForm} WITH FRAME {&FRAME-NAME}.
  ENABLE {&cpsForm}    WITH FRAME {&FRAME-NAME} .
  ASSIGN cAcaoCorrente = 'incluir'.


END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME brItens
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-window 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-window  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-window  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE atuBrowser w-window 
PROCEDURE atuBrowser :
DEFINE VARIABLE qtReg AS INTEGER     NO-UNDO.
RUN setConstraintModelo   IN hbo(pModeloNegocioId).
RUN openQueryStatic       IN hBo("modelo").
RUN getFirst              IN hBo.
IF RETURN-VALUE <> 'nok' THEN DO:
 RUN getRecord          IN hBo(TABLE ttReg).
 FIND FIRST ttReg NO-ERROR.
 RUN getBatchRecords    IN hBo(INPUT ttReg.r-rowid,
                               INPUT NO,
                               INPUT 99999,
                               OUTPUT qtReg,
                               OUTPUT TABLE rowObject).
END.
{&openquery-BrItens}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE criarTtReg w-window 
PROCEDURE criarTtReg :
EMPTY TEMP-TABLE ttReg.
CREATE ttReg.
ASSIGN ttReg.modelo_negocio_id     = pModeloNegocioId
       ttReg.chave                 = fiChave:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       ttReg.num_comparativo       = INTEGER(cbTipoComparativo:SCREEN-VALUE IN FRAME {&FRAME-NAME})
       ttReg.num_prioridade        = INTEGER(fiPrioridade:SCREEN-VALUE IN FRAME {&FRAME-NAME})
       ttReg.LOG_obrigatorio       = LOGICAL(tgObrigatorio:SCREEN-VALUE IN FRAME {&FRAME-NAME})
       ttReg.num_tipo_dado_valido  = INT(cbTipoDAdoValido:screen-value IN FRAME {&FRAME-NAME})
       ttReg.num_tipo_item         = INT(cbTipoItem:SCREEN-VALUE IN FRAME {&FRAME-NAME})
       .
IF ttReg.num_tipo_dado_valido <> 3 THEN // diferente de programa
   ASSIGN ttReg.lista   = edDadoValido:SCREEN-VALUE IN FRAME {&FRAME-NAME} .


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-window  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-window)
  THEN DELETE WIDGET w-window.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-window  _DEFAULT-ENABLE
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
  DISPLAY cbTipoItem fiChave cbTipoComparativo fiPrioridade cbTipoDadoValido 
          edDadoValido tgObrigatorio 
      WITH FRAME F-Main IN WINDOW w-window.
  ENABLE RECT-1 RECT-11 RECT-12 RECT-14 RECT-15 brItens btIncluir btAlterar 
         btExcluir cbTipoItem fiChave cbTipoComparativo fiPrioridade 
         cbTipoDadoValido edDadoValido tgObrigatorio btConfirmar btCancelar 
         btLiberar BtInutilizar bt-ok bt-ajuda 
      WITH FRAME F-Main IN WINDOW w-window.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW w-window.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE incluirItensModelo w-window 
PROCEDURE incluirItensModelo :
RUN criarTtReg.

RUN emptyRowErrors  IN hBo.
RUN setRecord       IN hBo(TABLE RowObject).
RUN createRecord    IN hBo.





END PROCEDURE.


/*Order Field Name                       Data Type   Flags
----- -------------------------------- ----------- -----
   10 item_modelo_negocio_id           inte        i
   20 modelo_negocio_id                inte        i
   30 chave                            char        i
   40 num_comparativo                  inte
   50 num_prioridade                   inte
   60 log_obrigatorio                  logi
   70 num_tipo_dado                    inte
   80 log_calculado                    logi
   90 cod_prog_calc                    char

*/

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-window 
PROCEDURE local-destroy :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  
  IF VALID-HANDLE(hBo) THEN DO:
     DELETE PROCEDURE hBo.
  END.
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'destroy':U ) .
  {include/i-logfin.i}

  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-window 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/
    DEFINE VARIABLE qtReg AS INTEGER     NO-UNDO.
  /* Code placed here will execute PRIOR to standard behavior. */
  {include/win-size.i}
  
  {utp/ut9000.i "es0901a" "2.06.00.001"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  RUN esbo/boEsrn03.p PERSIST SET hBo .

  RUN atuBrowser.

  RUN tratarBrowserVazio.

  /* Code placed here will execute AFTER standard behavior.    */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-window  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "RowObject"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-window 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE tratarBotoes w-window 
PROCEDURE tratarBotoes :
DEFINE INPUT  PARAMETER pBtAtual AS CHARACTER   NO-UNDO.

CASE pBtAtual:
    WHEN 'incluir' THEN DO:
        ASSIGN btAlterar:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               btExcluir:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               .
    END.
    WHEN 'alterar' THEN DO:
        ASSIGN btIncluir:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               btExcluir:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               .
    END.
    WHEN 'excluir' THEN DO:
        ASSIGN btAlterar:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               btIncluir:SENSITIVE IN FRAME {&FRAME-NAME} = NO
               .
    END.

END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE tratarBotoesForm w-window 
PROCEDURE tratarBotoesForm :
ENABLE  {&botoesAcoes}   WITH FRAME {&FRAME-NAME}.
  DISABLE {&botoesConfirm} WITH FRAME {&FRAME-NAME}.
  RUN tratarBrowserVazio. 


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE tratarBrowserVazio w-window 
PROCEDURE tratarBrowserVazio :
IF NUM-RESULTS("brItens") = 0 THEN DO:

     DISABLE {&objsform}  WITH FRAME {&FRAME-NAME}.
     ASSIGN btIncluir:SENSITIVE IN FRAME {&FRAME-NAME} = YES.

  END.
  ELSE DO:

     ENABLE  {&objsform}        WITH FRAME {&FRAME-NAME}.
     DISABLE {&botoesConfirm}   WITH FRAME {&FRAME-NAME}.

  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

