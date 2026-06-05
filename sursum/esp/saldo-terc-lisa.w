&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-livre 
/*:T *******************************************************************************
** Copyright TOTVS S.A. (2009)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da TOTVS, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i saldo-terc-lisa 9.99.99.999}

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
{util.i}
DEFINE TEMP-TABLE ttProduto
    FIELD linha             AS INTEGER
    FIELD produto           AS CHAR FORMAT 'x(20)'
    FIELD descricao         AS CHAR FORMAT 'x(100)'
    FIELD unidade           AS CHAR
    FIELD vlTotEntradaInf   AS DECIMAL
    FIELD vlTotEntradaCalc  AS DECIMAL
    FIELD vlTotSaidaInf     AS DECIMAL
    FIELD vlTotSaidaCalc    AS DECIMAL 
    FIELD vlSaldoInf        AS DECIMAL
    FIELD vlSaldoCalc       AS DECIMAL
    FIELD vlTotEntradaErp   AS DECIMAL
    FIELD vlTotSaidaErp     AS DECIMAL
    FIELD vlSaldoErp        AS DECIMAL
    FIELD vlDifErp          AS DECIMAL
    FIELD qtRegistros       AS INT
    INDEX primario IS PRIMARY linha
    INDEX index-prod produto .

DEFINE TEMP-TABLE ttProdRef
    FIELD linha             AS INTEGER
    FIELD produto           AS CHAR FORMAT 'x(20)'
    FIELD referencia        AS CHAR
    FIELD descricao         AS CHAR FORMAT 'x(100)'
    FIELD unidade           AS CHAR
    FIELD vlTotEntradaInf   AS DECIMAL
    FIELD vlTotEntradaCalc  AS DECIMAL
    FIELD vlTotSaidaInf     AS DECIMAL
    FIELD vlTotSaidaCalc    AS DECIMAL 
    FIELD vlSaldoInf        AS DECIMAL
    FIELD vlSaldoCalc       AS DECIMAL
    FIELD vlTotEntradaErp   AS DECIMAL
    FIELD vlTotSaidaErp     AS DECIMAL
    FIELD vlSaldoErp        AS DECIMAL
    FIELD vlDifErp          AS DECIMAL
    FIELD qtRegistros       AS INT
    INDEX primario IS PRIMARY linha
    INDEX index-prod-ref produto referencia .

DEFINE TEMP-TABLE ttLanc
    FIELD linha             AS INTEGER
    FIELD produto           AS CHAR FORMAT 'x(20)'
    FIELD referencia        AS CHAR
    FIELD descricao         AS CHAR FORMAT 'x(100)'
    FIELD unidade           AS CHAR
    FIELD documento         AS CHAR FORMAT 'x(12)'
    FIELD data              AS DATE
    FIELD vlEntrada         AS DECIMAL
    FIELD vlSaida           AS DECIMAL
    FIELD vlSaldo           AS DECIMAL
    FIELD tipo              AS CHAR
    //FIELD dtTrans           AS DATE
    FIELD vlEntradaERP      AS DECIMAL
    FIELD vlSaidaERP        AS DECIMAL
    FIELD sequencia         AS INT
    FIELD origem            AS CHAR
    FIELD cancelada         AS CHAR INIT 'NAO'
    INDEX primario  linha
    INDEX index-prod-ref-doc IS PRIMARY produto referencia documento data
    INDEX ind-tipo tipo
    INDEX ind-doc documento
     .

DEFINE VARIABLE prodIni AS CHARACTER   NO-UNDO INIT ''.
DEFINE VARIABLE prodFim AS CHARACTER   NO-UNDO INIT 'zzzzzzzzzzzz'.
DEFINE VARIABLE refIni  AS CHARACTER   NO-UNDO INIT ''.
DEFINE VARIABLE refFim  AS CHARACTER   NO-UNDO INIT 'zzzzzz'.

DEFINE VARIABLE h-acomp AS HANDLE      NO-UNDO.

DEFINE VARIABLE cArqExcel AS CHARACTER   NO-UNDO.

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
&Scoped-Define ENABLED-OBJECTS rt-button fiProduto fiReferencia fidtLimite ~
btGerarExcel 
&Scoped-Define DISPLAYED-OBJECTS fiProduto fiReferencia fidtLimite 

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
DEFINE BUTTON btGerarExcel 
     LABEL "Gerar Excel" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE fidtLimite AS DATE FORMAT "99/99/9999":U INITIAL 12/31/9999 
     LABEL "Dt.Limite" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fiProduto AS CHARACTER FORMAT "X(256)":U 
     LABEL "Produto" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fiReferencia AS CHARACTER FORMAT "X(4)":U 
     LABEL "Referància" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 89.72 BY 1.46
     BGCOLOR 7 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fiProduto AT ROW 4.75 COL 6 COLON-ALIGNED WIDGET-ID 2
     fiReferencia AT ROW 4.75 COL 29.14 COLON-ALIGNED WIDGET-ID 4
     fidtLimite AT ROW 4.75 COL 53 COLON-ALIGNED WIDGET-ID 8
     btGerarExcel AT ROW 4.79 COL 72 WIDGET-ID 6
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
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-livre ASSIGN
         HIDDEN             = YES
         TITLE              = "Saldo de Terceiros"
         HEIGHT             = 7.5
         WIDTH              = 89.43
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
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Saldo de Terceiros */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Saldo de Terceiros */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btGerarExcel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btGerarExcel w-livre
ON CHOOSE OF btGerarExcel IN FRAME f-cad /* Gerar Excel */
DO: 
    RUN utp/ut-acomp.p PERSIST SET h-acomp.

    RUN pi-inicializar IN h-acomp('Saldo de Terceiros - LISA').

    IF fiProduto:SCREEN-VALUE <> '' THEN
       ASSIGN prodIni = fiProduto:SCREEN-VALUE
              prodFim = fiProduto:SCREEN-VALUE .

    IF fiReferencia:SCREEN-VALUE <> '' THEN
       ASSIGN refIni = fiReferencia:SCREEN-VALUE
              refFim = fiReferencia:SCREEN-VALUE .

    RUN pi-acompanhar IN h-acomp('Buscando Remessas').
   
    //inclusao das notas fiscais de remessa IMA
    FOR EACH  saldo-terc NO-LOCK
        WHERE saldo-terc.cod-estabel        = '505'
        AND   saldo-terc.cod-emitente       = 38284
        AND   saldo-terc.nat-operacao       = '59207i'
        AND   saldo-terc.serie              = '2'
        AND  saldo-terc.dt-retorno         <= INPUT FRAME {&FRAME-NAME} fiDtLimite
        AND  saldo-terc.it-codigo          >= prodIni
        AND  saldo-terc.it-codigo          <= prodFim
        AND  saldo-terc.cod-refer          >= refIni
        AND  saldo-terc.cod-refer          <= refFim
        :
        FIND componente OF saldo-terc NO-LOCK NO-ERROR.
        IF AVAIL componente THEN DO:
           FIND ITEM OF saldo-terc NO-LOCK NO-ERROR.
           CREATE ttLanc.
           ASSIGN ttLanc.produto       = saldo-terc.it-codigo
                  ttLanc.descricao     = ITEM.desc-item
                  ttLanc.unidade       = ITEM.un
                  ttLanc.referencia    = saldo-terc.cod-refer
                  ttLanc.data          = saldo-terc.dt-retorno
                  ttLanc.documento     = saldo-terc.nro-docto
                  ttLanc.vlEntrada     = componente.quantidade
                  ttLanc.tipo          = 'remessa'
                  ttLanc.origem        = 'ima'
                  ttLanc.sequencia     = saldo-terc.sequencia.
        END.
    END.
    RUN pi-acompanhar IN h-acomp('Buscando Retornos').
    //inclusao das notas fiscais de retorno IMA
    FOR EACH  saldo-terc NO-LOCK
        WHERE saldo-terc.cod-estabel        = '505'
        AND   saldo-terc.cod-emitente       = 38284
        AND   saldo-terc.nat-operacao       = '59207i'
        AND   saldo-terc.serie              = '2' 
        AND  saldo-terc.it-codigo          >= prodIni
        AND  saldo-terc.it-codigo          <= prodFim
        AND  saldo-terc.cod-refer          >= refIni
        AND  saldo-terc.cod-refer          <= refFim:
    
        FOR EACH componente
            WHERE componente.serie-comp      = saldo-terc.serie-docto
            AND   componente.nro-comp        = saldo-terc.nro-docto
            AND   componente.nat-comp        = saldo-terc.nat-operacao
            AND   componente.it-codigo       = saldo-terc.it-codigo
            AND   componente.cod-refer       = saldo-terc.cod-refer
            AND   componente.seq-comp        = saldo-terc.sequencia
            AND   componente.cod-emitente    = saldo-terc.cod-emitente
            AND   componente.componente      = 2
            AND   componente.dt-retorno     <= INPUT FRAME {&FRAME-NAME} fiDtLimite :
            CREATE ttLanc.
            ASSIGN ttLanc.produto       = saldo-terc.it-codigo
                   ttLanc.descricao     = ITEM.desc-item
                   ttLanc.unidade       = ITEM.un
                   ttLanc.referencia    = saldo-terc.cod-refer
                   ttLanc.data          = componente.dt-retorno
                   ttLanc.documento     = componente.nro-docto
                   ttLanc.vlSaida       = componente.quantidade
                   ttLanc.tipo          = 'retorno'
                   ttLanc.origem        = 'ima'
                   ttLanc.sequencia     = saldo-terc.sequencia.
        END.                                      
    END.
      
    RUN pi-acompanhar IN h-acomp('Gerando Exportaá∆o CSV').

    IF CAN-FIND( FIRST ttLanc) THEN DO:
       {esp/exportarTabelacsv3fixo.i ttLanc " " " " "ttLancsaldotercLisa" }
    END.
    ELSE DO:
       RUN gravarTextoEmArquivo(SESSION:TEMP-DIRECTORY + 'ttLancSaldoTercLisa.csv',
                                 'Sem Dados a serem exportados' 
                                 ).
    END.




    RUN pi-acompanhar IN h-acomp('Gerando Excel').

    ASSIGN cArqExcel =  SEARCH('excel/saldo-terc-lisa.xlsx')  .
    IF cArqExcel <> ? THEN
       OS-COMMAND SILENT VALUE('start excel /t ' + cArqExcel).
    ELSE
       MESSAGE "Arquivo de Modelo n∆o encontrado"
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.

    RUN pi-finalizar IN h-acomp.



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
       RUN set-position IN h_p-exihel ( 1.17 , 74.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fiProduto:HANDLE IN FRAME f-cad , 'BEFORE':U ).
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
  DISPLAY fiProduto fiReferencia fidtLimite 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button fiProduto fiReferencia fidtLimite btGerarExcel 
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

  {utp/ut9000.i "saldo-terc-lisa" "9.99.99.999"}

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

