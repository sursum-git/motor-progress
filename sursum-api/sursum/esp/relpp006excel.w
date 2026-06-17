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
/*{include/i-prgvrs.i XX9999 9.99.99.999}*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

DEF BUFFER moeda FOR mgcad.moeda.

DEFINE TEMP-TABLE tt
    FIELD nrContainer       LIKE pp-container.nr-container
    FIELD NomeFornec        LIKE pp-container.nome-ab-Forn
    FIELD dtCompra          LIKE pp-container.dt-compra
    FIELD dtPrevChegada     LIKE pp-container.dt-prev-chegada
    FIELD dtRecebimento     LIKE pp-container.dt-recebimento
    FIELD dtReg             AS DATE
    FIELD situacao          AS CHAR FORMAT 'x(20)'
    FIELD itCodigo          LIKE pp-it-container.it-codigo
    FIELD descItem          AS  CHAR FORMAT 'x(100)'
    FIELD codRefer          LIKE pp-it-container.cod-refer
    FIELD tipoReg           AS CHAR
    FIELD quantidade        AS DECIMAL FORMAT '>>>,>>>,>>>,>>9.99'
    FIELD sitPed            AS CHAR FORMAT 'x(20)'
    FIELD dtHrGeracao       AS CHAR FORMAT 'x(20)'
    FIELD codEmitente       AS INT
    FIELD nomeEmitente      AS CHAR FORMAT 'x(20)'
    FIELD nomeRepres        LIKE ped-venda.nome-abrev 
    FIELD sitContainer      AS CHAR FORMAT 'x(50)'
    FIELD tipoMostruario    AS CHAR FORMAT 'x(50)'
    FIELD precoUnitario     AS DECIMAL
    FIELD valorTotal        AS DECIMAL
    FIELD desconto          AS DECIMAL
    FIELD nrPedido          AS INT
    FIELD moeda             AS CHAR
    FIELD precoReal         AS DECIMAL
    FIELD precoDolar        AS DECIMAL.
        
DEFINE TEMP-TABLE ttContainer
    FIELD nrContainer       AS INT
    FIELD situacao          AS CHAR FORMAT 'x(50)'
    FIELD tipoMostruario    AS CHAR FORMAT 'x(50)'
    FIELD itCodigo          AS CHAR
    FIELD precoDolar        AS DECIMAL
    FIELD precoReal         AS DECIMAL.

DEFINE TEMP-TABLE ttPontos
    FIELD idPonto        AS INT
    FIELD descPonto      AS CHAR FORMAT 'x(100)'.
 


DEFINE VARIABLE dtGeracao AS DATETIME    NO-UNDO INIT NOW.
DEFINE VARIABLE cListaSituacao AS CHARACTER   NO-UNDO INIT '1'.
DEFINE VARIABLE cListaPedidos   AS CHARACTER   NO-UNDO FORMAT 'x(4000)'.
DEFINE VARIABLE cListaSitContainer AS CHARACTER   NO-UNDO INIT 'Aberto,Suspenso,Fechado'.

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
&Scoped-Define ENABLED-OBJECTS rt-button fiNrContainerIni fiNrContainerFim ~
lista_container tgAberto btExcel 
&Scoped-Define DISPLAYED-OBJECTS fiNrContainerIni fiNrContainerFim ~
lista_container tgAberto 

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
DEFINE BUTTON btExcel 
     LABEL "Excel" 
     SIZE 12 BY 1.25.

DEFINE VARIABLE fiNrContainerFim AS INTEGER FORMAT ">>>>>9":U INITIAL 999999 
     LABEL "AtÇ" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE fiNrContainerIni AS INTEGER FORMAT ">>>>>9":U INITIAL 0 
     LABEL "Container de" 
     VIEW-AS FILL-IN 
     SIZE 14 BY 1 NO-UNDO.

DEFINE VARIABLE lista_container AS CHARACTER FORMAT "X(256)":U 
     LABEL "Lista Container" 
     VIEW-AS FILL-IN 
     SIZE 37 BY .79 NO-UNDO.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 91.72 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tgAberto AS LOGICAL INITIAL yes 
     LABEL "Apenas Container's em Aberto" 
     VIEW-AS TOGGLE-BOX
     SIZE 50 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fiNrContainerIni AT ROW 3.5 COL 20 COLON-ALIGNED WIDGET-ID 4
     fiNrContainerFim AT ROW 3.5 COL 42 COLON-ALIGNED WIDGET-ID 6
     lista_container AT ROW 4.75 COL 20 COLON-ALIGNED WIDGET-ID 12
     tgAberto AT ROW 6 COL 22 WIDGET-ID 8
     btExcel AT ROW 6.83 COL 22 WIDGET-ID 2
     rt-button AT ROW 1 COL 1
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 91.86 BY 7.17
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
         TITLE              = "Relat¢rio de Programaá∆o de Vendas  - Excel"
         HEIGHT             = 7.17
         WIDTH              = 91.86
         MAX-HEIGHT         = 27.54
         MAX-WIDTH          = 195.14
         VIRTUAL-HEIGHT     = 27.54
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
   FRAME-NAME L-To-R                                                    */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Relat¢rio de Programaá∆o de Vendas  - Excel */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Relat¢rio de Programaá∆o de Vendas  - Excel */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btExcel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btExcel w-livre
ON CHOOSE OF btExcel IN FRAME f-cad /* Excel */
DO:
  EMPTY TEMP-TABLE tt.
  /*RUN buscarBDContainer.*/
  ASSIGN btExcel:LABEL IN FRAME {&FRAME-NAME} = 'Processando...'
         btExcel:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
  //RUN buscarRegSaldoPI(INPUT FRAME {&FRAME-NAME} fiNrContainerIni,INPUT FRAME {&FRAME-NAME} fiNrContainerFim).
  
  RUN buscarPedidosPI(INPUT FRAME {&FRAME-NAME} fiNrContainerIni,INPUT FRAME {&FRAME-NAME} fiNrContainerFim, OUTPUT cListaPedidos).
  RUN buscarRegPedidosPI(cListaPedidos).
  RUN gerarTxt.
  ASSIGN btExcel:LABEL IN FRAME {&FRAME-NAME} = 'Excel'
         btExcel:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
  OS-COMMAND SILENT 'START EXCEL /N T:\especificos\excel\RELPP006EXCEL.XLS'.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiNrContainerIni
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiNrContainerIni w-livre
ON LEAVE OF fiNrContainerIni IN FRAME f-cad /* Container de */
DO:
   ASSIGN fiNrContainerFim:SCREEN-VALUE = fiNrContainerIni:SCREEN-VALUE.
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


&Scoped-define SELF-NAME tgAberto
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgAberto w-livre
ON VALUE-CHANGED OF tgAberto IN FRAME f-cad /* Apenas Container's em Aberto */
DO:
  IF INPUT FRAME  {&frame-name} tgAberto  = YES THEN
     ASSIGN cListaSituacao = '1'.
  ELSE
     ASSIGN cListaSituacao = '1,2,3'.
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
       RUN set-position IN h_p-exihel ( 1.08 , 76.43 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fiNrContainerIni:HANDLE IN FRAME f-cad , 'BEFORE':U ).
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE buscarBDContainer w-livre 
PROCEDURE buscarBDContainer :
EMPTY TEMP-TABLE ttContainer.
/*INPUT FROM m:\ems206\esp\excel\BDContainer.csv. */
INPUT FROM 'I:\3-Planilhas\excel\BDContainer.csv'.
    DEFINE VARIABLE i AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cLinha AS CHARACTER   NO-UNDO FORMAT 'x(100)'.
    REPEAT:
        ASSIGN i = i + 1.
        IMPORT UNFORMAT cLinha.
        /*MESSAGE clinha
            VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
        IF SUBSTR(cLinha,1,1) <> 'C' AND NUM-ENTRIES(cLinha,";") >= 6  THEN DO:
           CREATE ttContainer.
           ASSIGN  ttContainer.nrContainer    = INT(ENTRY(1,cLinha,";"))
                   ttContainer.situacao       = ENTRY(2,cLinha,";") 
                   ttContainer.tipoMostruario = ENTRY(3,cLinha,";")
                   ttContainer.itCodigo       = ENTRY(4,cLinha,";")
                   ttContainer.precoDolar     = dec(ENTRY(5,cLinha,";"))
                   ttContainer.precoReal      = dec(ENTRY(6,cLinha,";")).
        END.
    END.    

    /*FOR EACH ttContainer:
        MESSAGE ttContainer.nrContainer SKIP
                ttContainer.itCodigo  
            VIEW-AS ALERT-BOX INFO BUTTONS OK.
    END.*/


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE buscarPedidosPI w-livre 
PROCEDURE buscarPedidosPI :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER iNrContainerIni AS INTEGER     NO-UNDO.
DEFINE INPUT  PARAMETER iNrContainerFim AS INTEGER     NO-UNDO.
DEFINE OUTPUT PARAMETER cListaPedidos   AS CHARACTER   NO-UNDO FORMAT 'x(4000)'.
IF lista_container:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "" THEN DO:
   FOR EACH ped-venda-ext NO-LOCK
        WHERE ped-venda-ext.nr-container >= iNrContainerIni
        AND ped-venda-ext.nr-container <= iNrContainerFim:
        IF INPUT FRAME {&FRAME-NAME} tgAberto  = YES THEN DO:
           FIND FIRST pp-container
               WHERE pp-container.nr-container = ped-venda-ext.nr-container
               AND   LOOKUP(STRING(pp-container.situacao),cListaSituacao,',') > 0
               NO-LOCK NO-ERROR.
           IF NOT AVAIL pp-container THEN NEXT.
        END.
        ASSIGN cListaPedidos = IF cListaPedidos = '' 
                               THEN STRING(ped-venda-ext.nr-pedido) ELSE cListaPedidos
                                + ',' 
                                + STRING(ped-venda-ext.nr-pedido).  
    END.
END.
ELSE DO:
     FOR EACH ped-venda-ext NO-LOCK
        WHERE LOOKUP (STRING(ped-venda-ext.nr-container), lista_container:SCREEN-VALUE IN FRAME {&FRAME-NAME},",") > 0 :
         MESSAGE ped-venda-ext.nr-container SKIP
             ped-venda-ext.nr-pedido
             VIEW-AS ALERT-BOX INFO BUTTONS OK.
        IF INPUT FRAME {&FRAME-NAME} tgAberto  = YES THEN DO:
           FIND FIRST pp-container
               WHERE pp-container.nr-container = ped-venda-ext.nr-container
               AND   LOOKUP(STRING(pp-container.situacao),cListaSituacao,',') > 0
               NO-LOCK NO-ERROR.
           IF NOT AVAIL pp-container THEN NEXT.
        END.
        ASSIGN cListaPedidos = IF cListaPedidos = '' 
                               THEN STRING(ped-venda-ext.nr-pedido) ELSE cListaPedidos
                                + ',' 
                                + STRING(ped-venda-ext.nr-pedido).  
    END.
END.




END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE buscarRegPedidosPI w-livre 
PROCEDURE buscarRegPedidosPI :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER cListaPedidos AS CHARACTER   NO-UNDO FORMAT 'x(4000)'.
OUTPUT TO c:\temp\ttcontainer.txt.
FOR EACH ttContainer:
    DISP ttContainer WITH WIDTH 550.
END.
OUTPUT CLOSE.
MESSAGE cListaPedidos
    VIEW-AS ALERT-BOX INFO BUTTONS OK.
OUTPUT TO value("c:\temp\PERFORMANCE.txt").
FOR EACH ped-venda NO-LOCK
    WHERE /*ped-venda.tp-pedido = 'pi'
    AND */ lookup(string(ped-venda.nr-pedido),cListaPedidos,',')> 0 USE-INDEX ch-pedseq:
    PUT 'inicio ped-venda:' ped-venda.nr-pedido NOW  SKIP.
    FIND FIRST ped-venda-ext
        WHERE ped-venda-ext.nr-pedido = ped-venda.nr-pedido
        NO-LOCK NO-ERROR.
    PUT 'apos ped-venda-ext:' NOW SKIP.
    FIND FIRST pp-container 
        WHERE pp-container.nr-container  = ped-venda-ext.nr-container
        AND   lookup(string(pp-container.situacao),cListaSituacao,',') > 0
        NO-LOCK NO-ERROR.
    PUT 'apos pp-container:' NOW SKIP.
    IF NOT AVAIL pp-container THEN NEXT.
    FIND FIRST emitente WHERE emitente.cod-emitente = ped-venda.cod-emitente NO-LOCK NO-ERROR.
    PUT 'apos emitente:' NOW SKIP.
    FIND FIRST moeda OF ped-venda NO-LOCK NO-ERROR.
    PUT 'apos moeda:' NOW SKIP.
    FOR EACH ped-item OF ped-venda NO-LOCK:
        PUT 'inicio ped-item:' ped-item.it-codigo NOW SKIP.
        FIND FIRST ttContainer
        WHERE ttContainer.nrContainer = ped-venda-ext.nr-container
        AND   ttContainer.itCodigo    = ped-item.it-codigo NO-ERROR.
  
        FIND FIRST pp-it-container WHERE
                   pp-it-container.it-codigo = ped-item.it-codigo AND
                   pp-it-container.cod-refer = ped-item.cod-refer AND
                   pp-it-container.nr-container = pp-container.nr-container NO-LOCK NO-ERROR.

        IF NOT AVAIL pp-it-container THEN NEXT.

        PUT 'inicio ped-item:' NOW  SKIP.
        FIND FIRST ITEM OF ped-item NO-LOCK NO-ERROR.
        CREATE  tt.
        ASSIGN  tt.nrContainer   =  IF AVAIL pp-container THEN pp-Container.nr-container     ELSE 0
                tt.NomeFornec    =  IF AVAIL pp-container THEN pp-container.nome-ab-forn     ELSE ''
                tt.dtCompra      =  IF AVAIL pp-container THEN pp-container.dt-compra        ELSE ?
                tt.dtPrevChegada =  IF AVAIL pp-container THEN pp-container.dt-prev-chegada  ELSE ?
                tt.dtRecebimento =  IF AVAIL pp-container THEN pp-container.dt-recebimento   ELSE ?
                tt.dtReg         =  ped-venda.dt-implant.
                IF AVAIL pp-container THEN 
                   ASSIGN tt.situacao      =  ENTRY(pp-container.situacao,cListaSitContainer,",").
        ASSIGN 
                tt.itCodigo      =  ped-item.it-codigo 
                tt.descItem      = IF AVAIL ITEM THEN ITEM.desc-item ELSE ''
                tt.codRefer      =  ped-item.cod-refer 
                tt.tipoReg       =  'venda'
                tt.quantidade    =  ped-item.qt-pedida * -1 .
        RUN retornarSitItem(ped-item.cod-sit-item,OUTPUT tt.sitPed).
        ASSIGN 
                tt.dtHrGeracao      =  string(dtGeracao,'99/99/9999 hh:mm:ss')
                tt.codEmitente      = ped-venda.cod-emitente
                tt.nomeRepres       = ped-venda.no-ab-reppri
                tt.nomeEmitente     = IF AVAIL emitente    THEN emitente.nome-abrev ELSE ''
                tt.sitContainer     = IF AVAIL ttContainer THEN ttContainer.situacao ELSE ''
                tt.tipoMostruario   = IF AVAIL ttContainer THEN ttContainer.tipoMostruario ELSE '' 
                tt.precoDolar       = IF AVAIL ttContainer THEN ttContainer.precoDolar ELSE 0
                tt.precoReal        = IF AVAIL ttContainer THEN ttContainer.precoReal  ELSE 0
                tt.precoUnitario    = ped-item.vl-preuni
                tt.desconto         = ped-item.val-desconto-total
                tt.valorTotal       = ped-item.vl-tot-it
                tt.nrPedido         = ped-venda.nr-pedido
                tt.moeda            = IF AVAIL moeda THEN moeda.descricao ELSE ''.
    END.
END.    
OUTPUT CLOSE.
/*
EMPTY TEMP-TABLE ttPontos.

FOR EACH pto-itiner NO-LOCK.
    FIND FIRST pto-contr OF pto-itiner NO-LOCK NO-ERROR.
    CREATE ttPontos.
    ASSIGN ttPontos.idPonto     = pto-itiner.cod-pto-contr
           ttPontos.descPonto   = pto-contr.descricao.
END.  

FOR EACH tt.
    ASSIGN plan_vendas.nr_container       = tt.nrContainer
        plan_vendas.dt_compra             = tt.dtCompra
        plan_vendas.dt_prev_chegada       = tt.dtPrevChegada
        plan_vendas.dt_recebimento        = tt.dtRecebimento
        plan_vendas.it_codigo             = tt.itCodigo
        plan_vendas.cod_refer             = tt.codRefer  
        plan_vendas.tipo_registro         = 2
        plan_vendas.quantidade            = tt.quantidade
        plan_vendas.cod_emitente          = tt.codEmitente 
        plan_vendas.nome_repres           = tt.nomeRepres 
        plan_vendas.tipo_mostruario       = tt.tipoMostruario
        plan_vendas.preco_dolar           = tt.precoDolar
        plan_vendas.preco_real            = tt.precoReal
        plan_vendas.preco_unitario        = tt.precoUnitario 
        plan_vendas.desconto              = tt.desconto
        plan_vendas.preco_total           = tt.valorTotal
        plan_vendas.nr_pedido             = tt.nrPedido
        plan_vendas.cod_versao            = NEXT-VALUE(sq_plan_vendas)
        plan_vendas.status_container      = tt.situacao
        /*plan_vendas.situacao_item         = tt.sitPed*/.

    IF tt.moeda = "real" THEN
        ASSIGN plan_vendas.moeda_pedido = 0.
    ELSE IF tt.moeda = "dolar compra" THEN
        ASSIGN plan_vendas.moeda_pedido = 1.
    ELSE IF tt.moeda = "ufir patrim" THEN
        ASSIGN plan_vendas.moeda_pedido = 2.
    ELSE IF tt.moeda = "dolar venda" THEN
        ASSIGN plan_vendas.moeda_pedido = 3.

    FIND FIRST ttPontos WHERE ttPontos.descPonto = tt.sitContainer.
    IF AVAIL ttPontos THEN
        plan_vendas.situacao_container = ttPontos.idPonto.
END.
*/
/*           
descItem                 
dtHrGeracao    
nomeEmitente   
*/          

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE buscarRegSaldoPI w-livre 
PROCEDURE buscarRegSaldoPI :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER iNrContainerIni AS INTEGER     NO-UNDO.
DEFINE INPUT  PARAMETER iNrContainerFim AS INTEGER     NO-UNDO.

FOR EACH pp-container 
    WHERE pp-container.nr-container >= INPUT FRAME  {&frame-name} fiNrContainerIni 
    AND   pp-container.nr-container <= INPUT FRAME  {&frame-name} fiNrContainerFim 
    AND   lookup(string(pp-container.situacao),cListaSituacao,',') > 0
    NO-LOCK:
    
    FOR EACH pp-it-container OF pp-container NO-LOCK:
        FIND FIRST ttContainer
        WHERE ttContainer.nrContainer = pp-container.nr-container
        AND   ttContainer.itCodigo    = pp-it-container.it-codigo
        NO-LOCK NO-ERROR.
        FIND FIRST ITEM NO-LOCK
            WHERE ITEM.it-codigo = pp-it-container.it-codigo NO-ERROR.
        CREATE tt.
        ASSIGN  tt.nrContainer      =  pp-Container.nr-container
                tt.NomeFornec       =  pp-container.nome-ab-forn
                tt.dtCompra         =  pp-container.dt-compra
                tt.dtPrevChegada    =  pp-container.dt-prev-chegada
                tt.dtRecebimento    =  pp-container.dt-recebimento
                tt.dtReg            =  pp-container.dt-compra
                tt.situacao         =  entry(pp-container.situacao,cListaSitContainer,',')
                tt.itCodigo         =  pp-it-container.it-codigo
                tt.codRefer         =  pp-it-container.cod-refer
                tt.tipoReg          =  'estoque'
                tt.quantidade       =  pp-it-container.qt-pedida
                tt.sitPed           =  ''
                tt.dtHrGeracao      = string(dtGeracao,'99/99/9999 hh:mm:ss')
                tt.descItem         = IF AVAIL ITEM THEN item.desc-item ELSE ''
                tt.sitContainer     = IF AVAIL ttContainer THEN ttContainer.situacao ELSE ''
                tt.tipoMostruario   = IF AVAIL ttContainer THEN ttContainer.tipoMostruario ELSE ''
                tt.precoReal        = IF AVAIL ttContainer THEN ttContainer.precoReal ELSE 0
                tt.precoDolar       = IF AVAIL ttContainer THEN ttContainer.precoDolar ELSE 0 .     
    END.
END.

/*
EMPTY TEMP-TABLE ttPontos.

FOR EACH pto-itiner NO-LOCK.
    FIND FIRST pto-contr OF pto-itiner NO-LOCK NO-ERROR.
    CREATE ttPontos.
    ASSIGN ttPontos.idPonto     = pto-itiner.cod-pto-contr
           ttPontos.descPonto   = pto-contr.descricao.
END.

FOR EACH tt.                              
    ASSIGN  
        plan_vendas.cod_versao              = NEXT-VALUE(sq_plan_vendas)
        plan_vendas.nr_container            = tt.nrContainer
        plan_vendas.dt_compra               = tt.dtCompra
        plan_vendas.dt_prev_chegada         = tt.dtPrevChegada
        plan_vendas.dt_recebimento          = tt.dtRecebimento
        plan_vendas.status_container        = tt.situacao
        plan_vendas.it_codigo               = tt.itCodigo
        plan_vendas.cod_refer               = tt.codRefer
        plan_vendas.tipo_registro           = 1
        plan_vendas.quantidade              = tt.quantidade
        plan_vendas.tipo_mostruario         = tt.tipoMostruario
        plan_vendas.preco_real              = tt.precoReal
        plan_vendas.preco_dolar             = tt.precoDolar
        plan_vendas.cod_emitente           = tt.codEmitente    
        plan_vendas.desconto               = tt.desconto              
        plan_vendas.nome_repres            = tt.nomeRepres
        plan_vendas.preco_total            = tt.valorTotal
        plan_vendas.preco_unitario         = tt.precoUnitario. 

    FIND FIRST ttPontos WHERE ttPontos.descPonto = tt.sitContainer.
    IF AVAIL ttPontos THEN
        plan_vendas.situacao_container = ttPontos.idPonto.
END.
*/
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
  DISPLAY fiNrContainerIni fiNrContainerFim lista_container tgAberto 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button fiNrContainerIni fiNrContainerFim lista_container tgAberto 
         btExcel 
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE gerarTXT w-livre 
PROCEDURE gerarTXT :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE lAchou AS LOGICAL     NO-UNDO.
OUTPUT TO VALUE (SESSION:TEMP-DIRECT + 'relpp006.txt').
    ASSIGN lAchou = NO.
    FOR EACH tt:
        EXPORT DELIMITER "|" tt.
        ASSIGN lAchou = YES.
    END.
    IF lAchou = NO THEN
      PUT "n∆o h† dados".
OUTPUT CLOSE.


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
  FIND FIRST pp-container 
      WHERE pp-container.situacao = 1 NO-LOCK NO-ERROR.
  IF AVAIL pp-container THEN
     ASSIGN fiNrContainerIni:SCREEN-VALUE = STRING(pp-container.nr-container).
  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE retornarSitItem w-livre 
PROCEDURE retornarSitItem :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER codSitItem AS INTEGER     NO-UNDO.
DEFINE OUTPUT PARAMETER cSituacao AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cListaSituacao AS CHARACTER   NO-UNDO FORMAT 'x(100)'.


ASSIGN cListaSituacao = {diinc/i03di149.i 3}.
/*MESSAGE codSitItem SKIP
    VIEW-AS ALERT-BOX INFO BUTTONS OK.*/


ASSIGN cSituacao = ENTRY(codSitItem,cListaSituacao,",").


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

