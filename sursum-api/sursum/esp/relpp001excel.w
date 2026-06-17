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


{esp/relpp001Excel.i  }
{esp/util.i}        
DEFINE TEMP-TABLE ttPrecoMedio NO-UNDO
       FIELD itCodigo       LIKE tt.itCodigo
       FIELD nrContainer    LIKE tt.nrContainer 
       FIELD moeda          LIKE tt.moeda
       FIELD preco          AS DECIMAL
       INDEX ind-item-container itCodigo nrContainer moeda . 

DEFINE TEMP-TABLE ttContainerQt  NO-UNDO
    FIELD nrContainer AS INT
    FIELD qtVendida   AS DECIMAL.

DEFINE TEMP-TABLE ttContainer   NO-UNDO
    FIELD nrContainer       AS INT
    FIELD situacao          AS CHAR FORMAT 'x(50)'
    FIELD tipoMostruario    AS CHAR FORMAT 'x(50)'
    FIELD itCodigo          AS CHAR
    FIELD precoDolar        AS DECIMAL
    FIELD precoReal         AS DECIMAL.

DEFINE TEMP-TABLE ttPontos
    FIELD idPonto        AS INT
    FIELD descPonto      AS CHAR FORMAT 'x(100)'.
 
DEFINE TEMP-TABLE ttItemContainer  NO-UNDO
    FIELD tipoMostruario     AS INT
    FIELD descTipoMostruario AS CHAR
    FIELD logCambioFinal     AS LOGICAL  .

DEFINE TEMP-TABLE ttVlsItemRefContainer NO-UNDO
    FIELD nrContainer           AS INT                          COLUMN-LABEL "CONTAINER"
    FIELD tipoMostruario        AS INT                          COLUMN-LABEL "TIPO MOSTRUARIO"
    FIELD dtPrevChegada         AS DATE                         COLUMN-LABEL "DT.PREV.CHEGADA"
    FIELD dtPrevChegadaLoja     AS DATE                         COLUMN-LABEL "DT.PREV.CHEGADA LOJA"
    FIELD descTipoMostruario    AS CHAR                         COLUMN-LABEL "DESCRICAO TIPO MOSTRUARIO"
    FIELD itCodigo              AS CHAR                         COLUMN-LABEL "ITEM"
    FIELD descItem              AS CHAR                         COLUMN-LABEL "DESCRIÄ«O ITEM"
    FIELD un                    AS CHAR                         COLUMN-LABEL "U.M."
    FIELD codRefer              AS CHAR                         COLUMN-LABEL "REFERENCIA"
    FIELD vlPrecoMedioDolar     AS DECIMAL                      COLUMN-LABEL "Preáo MÇdio Dolar"
    FIELD vlPrecoMedioReal      AS DECIMAL                      COLUMN-LABEL "Preáo MÇdio Real"    
    FIELD vlPrecoEmDolar        AS DECIMAL                      COLUMN-LABEL "PREÄO DOLAR TB.90"
    FIELD vlPrecoEmReal         AS DECIMAL                      COLUMN-LABEL "PREÄO REAL TB.90"    
    FIELD qtProgramada          AS DECIMAL                      COLUMN-LABEL "QT.COMPRADA"
    FIELD vlProgramado          AS DECIMAL                      COLUMN-LABEL "VL. COMPRADO TB.90"
    FIELD qtVendidoReal         AS DECIMAL                      COLUMN-LABEL "QT.VENDIDO REAL"
    FIELD vlVendidoReal         AS DECIMAL                      COLUMN-LABEL "VL.VENDIDO REAL"
    FIELD qtVendidoDolar        AS DECIMAL                      COLUMN-LABEL "QT.VENDIDO DOLAR"
    FIELD vlVendidoDolar        AS DECIMAL                      COLUMN-LABEL "VL.VENDIDO DOLAR"
    FIELD qtTotalVendido        AS DECIMAL                      COLUMN-LABEL "QT. TOTAL VENDIDO"
    FIELD qtSaldo               AS DECIMAL                      COLUMN-LABEL "QT.SALDO"
    FIELD vlPorcentagem         AS DECIMAL                      COLUMN-LABEL "PORCENTAGEM"
    FIELD logCambioFinal        AS LOGICAL FORMAT "Sim/N∆o"     COLUMN-LABEL "CAMBIO FINAL PAGO"
    FIELD vlConvDolarReal       AS DECIMAL                      COLUMN-LABEL "VL.VEND. CONV. DOLAR-REAL"    
    FIELD vltotalReal           AS DECIMAL                      COLUMN-LABEL "VL.TOT.VEND.REAL"
    FIELD vlPercPorValor        AS DECIMAL                      COLUMN-LABEL "PERC.POR VALOR"
    
    
    
    
    
    INDEX ind-pri AS PRIMARY nrContainer itCodigo CodRefer .

/*DEFINE TEMP-TABLE ttVlsItemContainer NO-UNDO
    FIELD nrContainer           AS INT
    FIELD tipoMostruario        AS INT
    FIELD descTipoMostruario    AS CHAR
    FIELD itCodigo              AS CHAR
    FIELD descItem              AS CHAR
    FIELD vlPrecoMedioReal      AS DECIMAL
    FIELD vlPrecoMedioDolar     AS DECIMAL
    FIELD vlPrecoEmReal         AS DECIMAL
    FIELD vlPrecoEmDolar        AS DECIMAL
    FIELD qtProgramada          AS DECIMAL
    FIELD qtVendidoReal         AS DECIMAL
    FIELD vlVendidoReal         AS DECIMAL
    FIELD qtVendidoDolar        AS DECIMAL
    FIELD vlVendidoDolar        AS DECIMAL
    FIELD vlConvDolarReal       AS DECIMAL
    FIELD vltotalReal           AS DECIMAL
    FIELD qtTotalVendido        AS DECIMAL    
    FIELD qtSaldo               AS DECIMAL
    FIELD vlPorcentagem         AS DECIMAL 
    FIELD logCambioFinal        AS LOGICAL FORMAT "Sim/N∆o" 
    FIELD dtPrevChegada         AS DATE
    INDEX ind-pri AS PRIMARY nrContainer itCodigo .*/

/*DEFINE TEMP-TABLE ttVlsContainer NO-UNDO
    FIELD nrContainer           AS INT
    FIELD tipoMostruario        AS INT
    FIELD descTipoMostruario    AS CHAR
    FIELD itCodigo              AS CHAR
    FIELD descItem              AS CHAR
    FIELD codRefer              AS CHAR
    FIELD vlPrecoMedioReal      AS DECIMAL
    FIELD vlPrecoMedioDolar     AS DECIMAL
    FIELD vlPrecoEmReal         AS DECIMAL
    FIELD vlPrecoEmDolar        AS DECIMAL
    FIELD qtProgramada          AS DECIMAL
    FIELD qtVendidoReal         AS DECIMAL
    FIELD vlVendidoReal         AS DECIMAL
    FIELD qtVendidoDolar        AS DECIMAL
    FIELD vlVendidoDolar        AS DECIMAL
    FIELD vlConvDolarReal       AS DECIMAL
    FIELD vltotalReal           AS DECIMAL
    FIELD qtTotalVendido        AS DECIMAL    
    FIELD qtSaldo               AS DECIMAL
    FIELD vlPorcentagem         AS DECIMAL 
    FIELD logCambioFinal        AS LOGICAL FORMAT "Sim/N∆o" 
    FIELD dtPrevChegada         AS DATE
    INDEX ind-pri AS PRIMARY nrContainer .
  */



DEFINE VARIABLE dtGeracao           AS DATETIME    NO-UNDO INIT NOW.
DEFINE VARIABLE cListaSituacao      AS CHARACTER   NO-UNDO INIT '1'.
DEFINE VARIABLE cListaPedidos       AS CHARACTER   NO-UNDO FORMAT 'x(4000)'.
DEFINE VARIABLE cListaSitContainer  AS CHARACTER   NO-UNDO INIT 'Aberto,Suspenso,Fechado'.

DEFINE VARIABLE  cModelo            AS CHARACTER   NO-UNDO.

DEFINE VARIABLE hBoPrecosItemRef    AS HANDLE      NO-UNDO.
DEFINE VARIABLE hBoCondPagtoPed     AS HANDLE      NO-UNDO.

DEFINE VARIABLE dCotacaoDolar       AS DECIMAL     NO-UNDO.

DEFINE VARIABLE hBo AS HANDLE      NO-UNDO.

DEFINE VARIABLE h-acomp AS HANDLE      NO-UNDO.

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
&Scoped-Define ENABLED-OBJECTS rt-button RECT-1 fiNrContainerIni ~
fiNrContainerFim tgAberto tgFechado tgSuspenso btExcel 
&Scoped-Define DISPLAYED-OBJECTS fiNrContainerIni fiNrContainerFim tgAberto ~
tgFechado tgSuspenso 

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

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 39 BY 1.75.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 67 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tgAberto AS LOGICAL INITIAL yes 
     LABEL "Aberto" 
     VIEW-AS TOGGLE-BOX
     SIZE 8 BY .83 NO-UNDO.

DEFINE VARIABLE tgFechado AS LOGICAL INITIAL no 
     LABEL "Fechado" 
     VIEW-AS TOGGLE-BOX
     SIZE 10.14 BY .83 NO-UNDO.

DEFINE VARIABLE tgSuspenso AS LOGICAL INITIAL no 
     LABEL "Suspenso" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.57 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fiNrContainerIni AT ROW 3.5 COL 20 COLON-ALIGNED WIDGET-ID 4
     fiNrContainerFim AT ROW 3.5 COL 42 COLON-ALIGNED WIDGET-ID 6
     tgAberto AT ROW 5.42 COL 23.43 WIDGET-ID 8
     tgFechado AT ROW 5.42 COL 31.29 WIDGET-ID 10
     tgSuspenso AT ROW 5.42 COL 40.86 WIDGET-ID 12
     btExcel AT ROW 7.33 COL 20.57 WIDGET-ID 2
     "Cancelado" VIEW-AS TEXT
          SIZE 8 BY .54 AT ROW 4.54 COL 21 WIDGET-ID 16
     rt-button AT ROW 1 COL 1
     RECT-1 AT ROW 4.96 COL 20 WIDGET-ID 14
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 67.57 BY 7.92
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
         HEIGHT             = 7.92
         WIDTH              = 67.57
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
  RUN utp/ut-acomp.p PERSIST SET h-acomp.
  RUN pi-inicializar IN h-acomp('VENDAS PI').
  RUN pi-acompanhar IN h-acomp('Buscando dados Arquivo XLS Container').
  EMPTY TEMP-TABLE tt.
  RUN buscarBDContainer.
  
  ASSIGN btExcel:LABEL IN FRAME {&FRAME-NAME} = 'Processando...'
         btExcel:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
 
  //RUN buscarPedidosPI(INPUT FRAME {&FRAME-NAME} fiNrContainerIni,INPUT FRAME {&FRAME-NAME} fiNrContainerFim, OUTPUT cListaPedidos).  
  //RUN buscarRegPedidosPI(cListaPedidos).
  RUN pi-acompanhar IN h-acomp('Buscando Pedidos PI').
  RUN esbo/boDadosVendasPI.p PERSIST SET hBo.
  RUN iniciar   IN hBo.
  RUN setIntervalContainer IN hBo(INPUT FRAME {&FRAME-NAME} fiNrContainerIni,INPUT FRAME {&FRAME-NAME} fiNrContainerFim).
  IF tgAberto:SCREEN-VALUE = 'yes' THEN  DO:
    RUN setSituacao IN hBo(1).      
  END.
  IF tgSuspenso:SCREEN-VALUE = 'yes'  THEN  DO:
    RUN setSituacao IN hBo(2).      
  END.
  IF tgFechado:SCREEN-VALUE = 'yes'  THEN  DO:
    RUN setSituacao IN hBo(3).      
  END. 
  RUN executar IN hBo.
  RUN getTT IN hbo(OUTPUT TABLE tt ).    
  RUN finalizar IN hBo.
  RUN pi-acompanhar IN h-acomp('Buscando Saldo PI').       
  RUN buscarRegSaldoPI(INPUT FRAME {&FRAME-NAME} fiNrContainerIni,INPUT FRAME {&FRAME-NAME} fiNrContainerFim).  
  RUN preencherTTBdContainer.
  RUN pi-acompanhar IN h-acomp('Calculando Preáo MÇdio').
  RUN calcularPrecoMedio.
  RUN pi-acompanhar IN h-acomp('Calculando Valores Por item/ref').
  RUN getTtVlsItemRef.
  RUN pi-acompanhar IN h-acomp('Gerando TXT').
  RUN gerarTxt.
  ASSIGN btExcel:LABEL IN FRAME {&FRAME-NAME} = 'Excel'
         btExcel:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
  ASSIGN cModelo = SEARCH('excel\relpp001excel.xltx').
  //OS-COMMAND SILENT VALUE( 'START EXCEL /t ' + cModelo) .
  RUN esapi/abrirExcel.p(cModelo).
  
  RUN pi-finalizar IN h-acomp.
  
  
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fiNrContainerFim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fiNrContainerFim w-livre
ON ENTRY OF fiNrContainerFim IN FRAME f-cad /* AtÇ */
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
ON VALUE-CHANGED OF tgAberto IN FRAME f-cad /* Aberto */
DO:
  IF INPUT FRAME  {&frame-name} tgAberto  = YES THEN
     ASSIGN cListaSituacao = '1'.
  ELSE
     ASSIGN cListaSituacao = '1,2,3'.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tgFechado
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgFechado w-livre
ON VALUE-CHANGED OF tgFechado IN FRAME f-cad /* Fechado */
DO:
  IF INPUT FRAME  {&frame-name} tgAberto  = YES THEN
     ASSIGN cListaSituacao = '1'.
  ELSE
     ASSIGN cListaSituacao = '1,2,3'.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tgSuspenso
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tgSuspenso w-livre
ON VALUE-CHANGED OF tgSuspenso IN FRAME f-cad /* Suspenso */
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
       RUN set-position IN h_p-exihel ( 1.13 , 52.00 ) NO-ERROR.
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
DEFINE VARIABLE cBdContainer AS CHARACTER  FORMAT 'x(100)' NO-UNDO INIT 'I:\3-Planilhas\excel\BDContainer.csv'.
DEFINE VARIABLE i AS INTEGER     NO-UNDO.
DEFINE VARIABLE cLinha AS CHARACTER   NO-UNDO FORMAT 'x(100)'.
EMPTY TEMP-TABLE ttContainer.
/*INPUT FROM m:\ems206\esp\excel\BDContainer.csv. */
IF SEARCH(cBdContainer) <> ? THEN DO:
   INPUT FROM VALUE(cBdContainer).
        
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
FOR EACH ped-venda-ext NO-LOCK
    WHERE ped-venda-ext.nr-container >= iNrContainerIni
    AND   ped-venda-ext.nr-container <= iNrContainerFim:
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

DEFINE VARIABLE iPrazoMedio         AS INTEGER     NO-UNDO.
DEFINE INPUT  PARAMETER cListaPedidos AS CHARACTER   NO-UNDO FORMAT 'x(4000)'.
OUTPUT TO c:\temp\ttcontainer.txt.
FOR EACH ttContainer:
    DISP ttContainer WITH WIDTH 550.
END.
OUTPUT CLOSE.

OUTPUT TO value("c:\temp\PERFORMANCE.txt").
FOR EACH ped-venda NO-LOCK
    WHERE 
    /*ped-venda.tp-pedido = 'pi'
    AND   */
    lookup(string(ped-venda.nr-pedido),cListaPedidos,',')> 0:
    
    /*MESSAGE 'antes clc. prazo medio'
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/

    //calcula prazo MÇdio do Pedido

    RUN getPrazoMedioPedido IN hBoCondPagtoPed(ROWID(ped-venda), OUTPUT iPrazoMedio).

   /* IF ped-venda.nr-pedido = 278574 THEN
       MESSAGE iPrazoMedio
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    /*MESSAGE 'depois calc prazo medio'
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
    
    PUT 'inicio ped-venda:' ped-venda.nr-pedido " - " NOW  SKIP.
    FIND FIRST ped-venda-ext
        WHERE ped-venda-ext.nr-pedido = ped-venda.nr-pedido
        AND ped-venda-ext.nr-container <> 0 NO-LOCK NO-ERROR.
    
    PUT 'apos ped-venda-ext:' NOW SKIP.
    FIND FIRST pp-container 
        WHERE pp-container.nr-container  = ped-venda-ext.nr-container
        AND   lookup(string(pp-container.situacao),cListaSituacao,',') > 0
        NO-LOCK NO-ERROR.
    PUT 'apos pp-container:' NOW SKIP.
    IF NOT AVAIL pp-container THEN DO: 
       PUT "container:"  ped-venda-ext.nr-container " para situaá‰es:" cListaSituacao
           "n∆o encontrados" SKIP.

       NEXT.

    END.
    FIND FIRST emitente WHERE emitente.cod-emitente = ped-venda.cod-emitente NO-LOCK NO-ERROR.
    PUT 'apos emitente:' NOW SKIP.
    FIND FIRST moeda OF ped-venda NO-LOCK NO-ERROR.
    PUT 'apos moeda:' NOW SKIP.
    FOR EACH ped-item OF ped-venda NO-LOCK:
        PUT 'inicio ped-item:' ped-item.it-codigo NOW SKIP.
        FIND FIRST ttContainer
        WHERE ttContainer.nrContainer = ped-venda-ext.nr-container
        AND   ttContainer.itCodigo    = ped-item.it-codigo NO-ERROR.
        PUT 'inicio ped-item:' NOW  SKIP.
        FIND FIRST ITEM OF ped-item NO-LOCK NO-ERROR.

        CREATE  tt.
        ASSIGN  tt.nrContainer          =  IF AVAIL pp-container THEN pp-Container.nr-container     ELSE 0
                tt.NomeFornec           =  IF AVAIL pp-container THEN pp-container.nome-ab-forn     ELSE ''
                tt.dtCompra             =  IF AVAIL pp-container THEN pp-container.dt-compra        ELSE ?
                tt.dtPrevChegada        =  IF AVAIL pp-container THEN pp-container.dt-prev-chegada  ELSE ?
                tt.dtPrevChegadaLoja    =  IF AVAIL pp-container THEN pp-container.dt_prev_chegada_loja  ELSE ?
                tt.dtRecebimento        =  IF AVAIL pp-container THEN pp-container.dt-recebimento   ELSE ?
                tt.dtReg                =  ped-venda.dt-implant.
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
                tt.moeda            = IF AVAIL moeda THEN moeda.descricao ELSE ''
                tt.precoOutlet      = 0
                tt.idOutlet         = 0.
        //chama a api de busca do preáo
        RUN esapi\getPrecoPrazoItemRef.p( INPUT ped-venda-ext.tb_preco_id, //tabela de preco
                                          INPUT TODAY, //data referencia
                                          INPUT ped-item.it-codigo, //item
                                          INPUT ped-item.cod-refer, //referencia
                                          INPUT ped-venda-ext.nr-container, //container
                                          INPUT 2, //PI
                                          INPUT iPrazoMedio, //prazo medio
                                          INPUT emitente.estado, //estado do cliente
                                          //INPUT hBoPrecosItemRef, // handle da BO para melhor performance
                                          OUTPUT tt.precoReal, //preáo em real 
                                          OUTPUT tt.precoDolar, //preáo em dolar
                                          OUTPUT tt.precoId,
                                          OUTPUT tt.precoOutlet,
                                          OUTPUT tt.idOutlet).

        ASSIGN tt.valorTotal        = ped-item.vl-preuni * tt.quantidade . 




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
    AND   (
            (pp-container.situacao = 1 AND INPUT FRAME  {&frame-name} tgAberto = YES) OR
            (pp-container.situacao = 2 AND INPUT FRAME  {&frame-name} tgSuspenso = YES) OR
            (pp-container.situacao = 3 AND INPUT FRAME  {&frame-name} tgFechado = YES)             
           ) 
    NO-LOCK:    
    FOR EACH pp-it-container OF pp-container NO-LOCK:
        FIND FIRST ttContainer
        WHERE ttContainer.nrContainer = pp-container.nr-container
        AND   ttContainer.itCodigo    = pp-it-container.it-codigo
        NO-LOCK NO-ERROR.
        FOR FIRST ITEM fields(it-codigo desc-item) NO-LOCK
            WHERE ITEM.it-codigo = pp-it-container.it-codigo.
        END.            
        
        CREATE tt.
        ASSIGN  tt.nrContainer      =  pp-Container.nr-container
                tt.NomeFornec       =  pp-container.nome-ab-forn
                tt.dtCompra         =  pp-container.dt-compra
                tt.dtPrevChegada    =  pp-container.dt-prev-chegada
                tt.dtPrevChegadaLoja =  pp-container.dt_prev_chegada_loja
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

        //chama a api de busca do preáo
        RUN esapi\getPrecoPrazoItemRef.p( INPUT 1, //tabela de preco
                                          INPUT TODAY, //data referencia
                                          INPUT pp-it-container.it-codigo, //item
                                          INPUT pp-it-container.cod-refer, //referencia
                                          INPUT pp-container.nr-container, //container
                                          INPUT 2, //PI
                                          INPUT 90, //prazo medio
                                          INPUT 'ES', //estado do cliente
                                          OUTPUT tt.preco90Real,  //preáo em real 
                                          OUTPUT tt.preco90Dolar, //preáo em dolar
                                          OUTPUT tt.preco90Id,
                                          OUTPUT tt.precoOutlet,
                                          OUTPUT tt.idOutlet).
        /*MESSAGE 'qt:' tt.quantidade SKIP
                'preco real:' tt.preco90real SKIP
                 'preco dolar:' tt.preco90Dolar
            VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/
       
        ASSIGN tt.valorTotal        =  IF tt.preco90Real > 0 THEN  tt.quantidade * tt.preco90Real
                                        ELSE tt.quantidade * tt.preco90Dolar. 

      /* MESSAGE 'vl.total' tt.valorTotal SKIP
               'quant.' tt.quantidade SKIP
               'preco real:' tt.preco90Real SKIP
               'preco dolar:' tt.preco90Dolar
             
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/

    END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE calcularPrecoMedio w-livre 
PROCEDURE calcularPrecoMedio :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE iCont   AS INTEGER     NO-UNDO.
DEFINE VARIABLE dTotal  AS DECIMAL     NO-UNDO.
FOR EACH tt WHERE tt.tiporeg = 'venda':
    FIND ttPrecoMedio 
        WHERE ttPrecoMedio.itCodigo    = tt.itCodigo
        AND   ttPrecoMedio.nrContainer = tt.nrContainer
        AND   ttPrecoMedio.moeda       = tt.moeda
        NO-LOCK NO-ERROR.
    IF NOT AVAIL ttPrecoMedio THEN DO:
       CREATE ttPrecoMedio.
       ASSIGN ttPrecoMedio.itCodigo    = tt.itCodigo
              ttPrecoMedio.nrContainer = tt.nrContainer 
              ttPrecoMedio.moeda       = tt.moeda .
    END.
END.


FOR EACH ttPrecoMedio:
    ASSIGN iCont    = 0
           dTotal   = 0 .
    FOR EACH tt
        WHERE tt.itCodigo       = ttPrecoMedio.itCodigo
        AND   tt.nrContainer    = ttPrecoMedio.nrContainer
        AND   tt.moeda          = ttPrecoMedio.moeda .

        ASSIGN iCont  = iCont  + tt.quantidade 
               dTotal = dTotal + (tt.precoUnitario * tt.quantidade).
    END.
    ASSIGN ttPrecoMedio.preco = dTotal / iCont .  
END.

FOR EACH tt:
    FIND FIRST ttPrecoMedio
        WHERE ttPrecoMedio.itCodigo = tt.itCodigo
        AND   ttPrecoMedio.nrContainer = tt.nrContainer
        AND  ttPrecoMedio.moeda = 'real' NO-ERROR.
    IF AVAIL ttPrecoMedio THEN
       ASSIGN tt.precoMedioReal = ttPrecoMedio.preco . 

    FIND FIRST ttPrecoMedio
        WHERE ttPrecoMedio.itCodigo = tt.itCodigo
        AND   ttPrecoMedio.nrContainer = tt.nrContainer
        AND  ttPrecoMedio.moeda = 'dolar venda' NO-ERROR.
    IF AVAIL ttPrecoMedio THEN
       ASSIGN tt.precoMedioDolar = ttPrecoMedio.preco . 


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
  DISPLAY fiNrContainerIni fiNrContainerFim tgAberto tgFechado tgSuspenso 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button RECT-1 fiNrContainerIni fiNrContainerFim tgAberto tgFechado 
         tgSuspenso btExcel 
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
//{esp/exportarTabelaTemporaria.i tt " " " " "relpp001.txt" "|" }
OUTPUT TO VALUE (SESSION:TEMP-DIRECT + 'relpp001.txt').
    FOR EACH tt:
        EXPORT DELIMITER "|" tt.
    END.
    FIND FIRST tt NO-ERROR.
    IF NOT AVAIL tt THEN DO:
       PUT " N∆o h† dados   ".
    END.
OUTPUT CLOSE.

{esp/exportarTabelaTemporaria.i ttPrecoMedio " " " " "relpp001_precoMedio.txt" "|" }

OUTPUT TO VALUE (SESSION:TEMP-DIRECT + 'relpp001_precoMedio.txt').
    FOR EACH ttPrecoMedio:
        EXPORT DELIMITER "|" ttPrecoMedio.
    END.
    FIND FIRST ttPrecoMedio NO-ERROR.
    IF NOT AVAIL ttPrecoMedio THEN DO:
       PUT " N∆o h† dados   ".
    END.
OUTPUT CLOSE.



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getCotacaoDolar w-livre 
PROCEDURE getCotacaoDolar :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE OUTPUT PARAMETER dCotacao AS DECIMAL     NO-UNDO.
DEFINE VARIABLE iCont AS INTEGER     NO-UNDO.

REPEAT:
    FIND LAST hist_cotacoes_bc NO-LOCK
        WHERE data = TODAY + iCont
        AND serie = 1 NO-ERROR.
    IF AVAIL hist_cotacoes_bc THEN DO:
       ASSIGN dCotacao = hist_cotacoes_bc.valor .
       LEAVE.
    END.
    ELSE DO:
       ASSIGN iCont = iCont + 1 .
    END.
    IF iCont = 10 THEN LEAVE.
END.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getRegItensContainer w-livre 
PROCEDURE getRegItensContainer :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER pItem           AS CHARACTER   NO-UNDO.
DEFINE INPUT  PARAMETER pNrContainer    AS INTEGER     NO-UNDO.
     
EMPTY TEMP-TABLE ttItemContainer.
FOR EACH itens_container
    WHERE itens_container.container_id = pNrContainer,
    EACH itens_proc_compra OF itens_container
    WHERE itens_proc_compra.codigo_erp = pItem.
    FIND pp-container  
        WHERE pp-container.nr-container = itens_container.container_id
        NO-LOCK NO-ERROR.
    FIND formatos_amostra OF itens_proc_compra
        NO-LOCK NO-ERROR.
    CREATE ttItemContainer.
    ASSIGN ttItemContainer.tipoMostruario        = itens_proc_compra.formato_amostra_id 
           ttItemContainer.descTipoMostruario    =  IF AVAIL formatos_amostra THEN formatos_amostra.descricao ELSE ''
           ttItemContainer.logCambioFinal        =  IF AVAIL pp-container THEN pp-container.log_pagto_final ELSE  NO.
END.

FIND FIRST ttItemContainer NO-ERROR.
IF NOT AVAIL ttItemContainer THEN DO:
    //caso n∆o tenha achado cria um registro em branco.
   CREATE ttItemContainer.
END.




END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE getTtVlsItemRef w-livre 
PROCEDURE getTtVlsItemRef :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE iTipoMostruario     AS INTEGER     NO-UNDO.
DEFINE VARIABLE qtVendReal          AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlVendReal          AS DECIMAL     NO-UNDO.
DEFINE VARIABLE qtVendDolar         AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlVendDolar         AS DECIMAL     NO-UNDO.
DEFINE VARIABLE qtSaldo             AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlPorcentagem       AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlTotalQtVendida    AS DECIMAL     NO-UNDO.


EMPTY TEMP-TABLE ttVlsItemRefContainer.

DEFINE BUFFER bf FOR tt.
/*total vendido*/
OUTPUT TO c:\temp\totalvendido.txt.
FOR EACH tt
    WHERE tt.tipoReg = 'venda'
    AND tt.sitped <> 'cancelado'
    BREAK BY tt.nrContainer.
    ASSIGN vlTotalQtVendida = vlTotalQtVendida + tt.Quantidade.
    DISP tt.nrPedido tt.itCodigo tt.codrefer tt.quantidade FORMAT '->>>,>>>,>>>.99' .
    IF LAST-OF(tt.nrContainer) THEN DO:
       CREATE ttContainerQt.
       ASSIGN ttContainerQt.nrContainer = tt.nrContainer
              ttContainerQT.qtVendida   = vlTotalQtVendida .
       ASSIGN vlTotalQtVendida = 0.
    END.
END.

OUTPUT CLOSE.


FOR EACH tt WHERE tt.tipoReg = 'estoque' :    
    RUN getRegItensContainer( INPUT tt.itCodigo, 
                               INPUT tt.nrContainer).
    FIND FIRST ttItemContainer NO-ERROR.

     //vendas em real
     ASSIGN qtVendReal = 0
            vlVendReal = 0.
     FOR EACH bf 
         WHERE  bf.moeda   = 'real'
         AND    bf.tipoReg = 'venda'
         AND    bf.nrContainer = tt.nrContainer
         AND    bf.itCodigo    = tt.itCodigo
         AND    bf.codrefer    = tt.codRefer
         AND    bf.sitped      <> 'cancelado'.
         ASSIGN qtVendReal = qtVendReal + bf.quantidade
                vlVendReal = vlVendReal + (bf.quantidade * tt.precoMedioReal ).
     END.

     //vendas em real
     ASSIGN qtVendDolar = 0
            vlVendDolar = 0.
     FOR EACH bf 
         WHERE  bf.moeda   = 'dolar venda'
         AND    bf.tipoReg = 'venda'
         AND    bf.nrContainer = tt.nrContainer
         AND    bf.itCodigo    = tt.itCodigo
         AND    bf.codrefer    = tt.codRefer
         AND    bf.sitped      <> 'cancelado'.
         ASSIGN qtVendDolar = qtVendDolar + bf.quantidade
                vlVendDolar = vlVendDolar + (bf.quantidade * tt.precoMedioDolar ).
     END.
     FIND ttContainerQt
         WHERE ttContainerQt.nrContainer = tt.nrContainer
         NO-ERROR.
     IF AVAIL ttContainerQt THEN
        ASSIGN vlTotalQtVendida = ttContainerQt.qtVendida.
     ELSE
        ASSIGN vltotalQtVendida = 0.

    

     IF vlTotalQtVendida <> 0 THEN
        ASSIGN vlPorcentagem = (qtVendReal + qtVendDolar) / vlTotalQtVendida  .
     ELSE 
       ASSIGN vlPorcentagem = 0.

     /*MESSAGE tt.itCodigo SKIP
            tt.codRefer SKIP
             qtVendReal SKIP
            qtVendDolar SKIP
         vlTotalQtVendida SKIP
         vlPorcentagem SKIP
         VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.*/

     RUN inserirTtVlsItemRef(
            tt.nrContainer ,
            ttItemContainer.tipoMostruario,
            ttItemContainer.descTipoMostruario,
            tt.itCodigo,
            tt.descItem,
            tt.codRefer,
            tt.PrecoMedioReal,
            tt.PrecoMedioDolar,
            tt.Preco90Real,
            tt.preco90Dolar,
            tt.quantidade,
            qtVendReal,
            vlVendReal,
            qtVendDolar,
            vlVendDolar,
            vlPorcentagem,
            ttItemContainer.logCambioFinal,
            tt.dtPrevChegada,
            tt.dtPrevChegadaLoja,
            vlVendDolar * dCotacaoDolar
          ).


END.

  


OUTPUT TO c:\temp\planilha-simone.txt.
FOR EACH ttVlsItemRefContainer.
    EXPORT DELIMITER "|" 
        ttVlsItemRefContainer.nrContainer
        ttVlsItemRefContainer.desctipoMostruario
        ttVlsItemRefContainer.dtPrevChegada
        ttVlsItemRefContainer.dtPrevChegadaLoja
        ttVlsItemRefContainer.itCodigo
        ttVlsItemRefContainer.descItem
        ttVlsItemRefContainer.un
        ttVlsItemRefContainer.codRefer
        ttVlsItemRefContainer.vlprecoMedioDolar
        ttVlsItemRefContainer.vlprecoMedioReal 
        round(ttVlsItemRefContainer.vlPrecoEmReal,2)
        round(ttVlsItemRefContainer.vlPrecoEmDolar,2)
        ttVlsItemRefContainer.qtProgramada
        ttVlsItemRefContainer.vlProgramado
        ttVlsItemRefContainer.qtVendidoReal
        ttVlsItemRefContainer.vlVendidoReal
        ttVlsItemRefContainer.qtVendidoDolar
        ttVlsItemRefContainer.vlVendidoDolar
        ttVlsItemRefContainer.qtTotalVendido    
        ttVlsItemRefContainer.qtSaldo           
        ttVlsItemRefContainer.vlPorcentagem   
        IF ttVlsItemRefContainer.logCambioFinal THEN "SIM" ELSE "NAO"
        ttVlsItemRefContainer.vlConvDolarReal 
        ttVlsItemRefContainer.vlTotalReal     
        .
        
END.

FIND FIRST ttVlsItemRefContainer NO-ERROR.
IF NOT AVAIL ttVlsItemRefContainer THEN
   PUT 'N∆o h† Dados' SKIP.

OUTPUT CLOSE.
          



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE inserirTtVlsItemRef w-livre 
PROCEDURE inserirTtVlsItemRef :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT  PARAMETER pNrContainer            LIKE ttVlsItemRefContainer.nrContainer           NO-UNDO.
DEFINE INPUT  PARAMETER pTipoMostruario         LIKE ttVlsItemRefContainer.tipoMostruario        NO-UNDO.
DEFINE INPUT  PARAMETER pDescTipoMostruario     LIKE ttVlsItemRefContainer.descTipoMostruario    NO-UNDO.
DEFINE INPUT  PARAMETER pItCodigo               LIKE ttVlsItemRefContainer.itCodigo              NO-UNDO.
DEFINE INPUT  PARAMETER pDescItem               LIKE ttVlsItemRefContainer.descItem              NO-UNDO.
DEFINE INPUT  PARAMETER pCodRefer               LIKE ttVlsItemRefContainer.codRefer              NO-UNDO.
DEFINE INPUT  PARAMETER pVlPrecoMedioReal       LIKE ttVlsItemRefContainer.vlPrecoMedioReal      NO-UNDO.
DEFINE INPUT  PARAMETER pVlPrecoMedioDolar      LIKE ttVlsItemRefContainer.vlPrecoMedioDolar     NO-UNDO.
DEFINE INPUT  PARAMETER pVlPrecoEmReal          LIKE ttVlsItemRefContainer.vlPrecoEmReal         NO-UNDO.
DEFINE INPUT  PARAMETER pVlPrecoEmDolar         LIKE ttVlsItemRefContainer.vlPrecoEmDolar        NO-UNDO.
DEFINE INPUT  PARAMETER pQtProgramada           LIKE ttVlsItemRefContainer.qtProgramada          NO-UNDO.
DEFINE INPUT  PARAMETER pQtVendidoReal          LIKE ttVlsItemRefContainer.qtVendidoReal         NO-UNDO.
DEFINE INPUT  PARAMETER pVlVendidoReal          LIKE ttVlsItemRefContainer.vlVendidoReal         NO-UNDO.
DEFINE INPUT  PARAMETER pQtVendidoDolar         LIKE ttVlsItemRefContainer.qtVendidoDolar        NO-UNDO.
DEFINE INPUT  PARAMETER pVlVendidoDolar         LIKE ttVlsItemRefContainer.vlVendidoDolar        NO-UNDO.
DEFINE INPUT  PARAMETER pvlPorcentagem          LIKE ttVlsItemRefContainer.vlPorcentagem         NO-UNDO.
DEFINE INPUT  PARAMETER pLogCambioFinal         LIKE ttVlsItemRefContainer.logCambioFinal        NO-UNDO.
DEFINE INPUT  PARAMETER pDtPrevChegada          AS DATE        NO-UNDO.
DEFINE INPUT  PARAMETER pDtPrevChegadaLoja      AS DATE        NO-UNDO.
DEFINE INPUT  PARAMETER pVlConvDolarReal        AS DECIMAL     NO-UNDO.

CREATE ttVlsItemRefContainer.
ASSIGN ttVlsItemRefContainer.nrContainer          = pNrContainer           
       ttVlsItemRefContainer.tipoMostruario       = pTipoMostruario        
       ttVlsItemRefContainer.descTipoMostruario   = pDescTipoMostruario    
       ttVlsItemRefContainer.itCodigo             = pItCodigo              
       ttVlsItemRefContainer.descItem             = pDescItem              
       ttVlsItemRefContainer.codRefer             = pCodRefer                       
       ttVlsItemRefContainer.vlPrecoMedioReal     = pVlPrecoMedioReal            
       ttVlsItemRefContainer.vlPrecoMedioDolar    = pVlPrecoMedioDolar       
       ttVlsItemRefContainer.vlPrecoEmReal        = pVlPrecoEmReal                     
       ttVlsItemRefContainer.vlPrecoEmDolar       = pVlPrecoEmDolar                    
       ttVlsItemRefContainer.qtProgramada         = pQtProgramada                      
       ttVlsItemRefContainer.qtVendidoReal        = pqtVendidoReal  * -1  
       ttVlsItemRefContainer.vlVendidoReal        = pVlVendidoReal  * -1           
       ttVlsItemRefContainer.qtVendidoDolar       = pQtVendidoDolar * -1          
       ttVlsItemRefContainer.vlVendidoDolar       = pVlVendidoDolar * -1          
       ttVlsItemRefContainer.qtSaldo              = ttVlsItemRefContainer.qtProgramada - ttVlsItemRefContainer.qtVendidoReal - ttVlsItemRefContainer.qtVendidoDolar                     
       ttVlsItemRefContainer.vlPorcentagem        = pvlPorcentagem               
       ttVlsItemRefContainer.logCambioFinal       = pLogCambioFinal
       ttVlsItemRefContainer.qtTotalVendido       = (qtVendidoReal + qtVendidoDolar) 
       ttVlsItemRefContainer.dtPrevChegada        = pDtPrevChegada
       ttVlsItemRefContainer.dtPrevChegadaLoja    = pDtPrevChegadaLoja
       ttVlsItemRefContainer.vlConvDolarReal      = pVlConvDolarReal * -1
       ttVlsItemRefContainer.vlTotalReal          = (pVlConvDolarReal +  pVlVendidoReal ) * -1
       .
       IF vlPrecoEmDolar <> 0 THEN DO:
           ASSIGN ttVlsItemRefContainer.vlProgramado = ttVlsItemRefContainer.qtProgramada * ttVlsItemRefContainer.vlPrecoEmDolar * dCotacaoDolar .
       END.
       ELSE DO:
           ASSIGN ttVlsItemRefContainer.vlProgramado = ttVlsItemRefContainer.qtProgramada * ttVlsItemRefContainer.vlPrecoEmReal .
       END.
       FIND ITEM
           WHERE ITEM.it-codigo = ttVlsItemRefContainer.itCodigo
           NO-LOCK NO-ERROR.
       ASSIGN ttVlsItemRefContainer.un = ITEM.un .

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
  IF VALID-HANDLE(hBoCondPagtoPed) THEN
     DELETE PROCEDURE hBoCondPagtoPed.
  IF VALID-HANDLE(hBoPrecosItemRef) THEN
     DELETE PROCEDURE hBoPrecosItemRef.
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

  {utp/ut9000.i "relpp001excel" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .
  /*FIND FIRST pp-container 
      WHERE pp-container.situacao = 1 NO-LOCK NO-ERROR.
  IF AVAIL pp-container THEN
     ASSIGN fiNrContainerIni:SCREEN-VALUE = STRING(pp-container.nr-container).  */
  /* Code placed here will execute AFTER standard behavior.    */
  RUN esbo/boPrecosItemRef.p PERSISTENT SET hBoPrecosItemRef.
  RUN iniciarBos IN hBoPrecosItemRef.

  RUN esbo/boCondPagtoPed.p PERSISTENT SET hBoCondPagtoPed.

 RUN getCotacaoDolar(OUTPUT dCotacaoDolar).


  run pi-after-initialize.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE preencherTTBdContainer w-livre 
PROCEDURE preencherTTBdContainer :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
FOR EACH tt:
    FIND FIRST ttContainer
    WHERE ttContainer.nrContainer = tt.nrContainer  NO-ERROR.
    ASSIGN tt.sitContainer     = IF AVAIL ttContainer THEN ttContainer.situacao ELSE ''
           tt.tipoMostruario   = IF AVAIL ttContainer THEN ttContainer.tipoMostruario ELSE '' 
           tt.precoDolar       = IF AVAIL ttContainer THEN ttContainer.precoDolar ELSE 0
           tt.precoReal        = IF AVAIL ttContainer THEN ttContainer.precoReal  ELSE 0.


END.
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

