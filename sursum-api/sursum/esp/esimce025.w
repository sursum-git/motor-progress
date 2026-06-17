&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-consim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-consim 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i esimce025 2.00.004.001}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-cod-estab-ini AS CHARACTER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-cod-estab-fim AS CHARACTER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-refer-ini     AS CHARACTER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-refer-fim     AS CHARACTER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-cod-depos-ini AS CHARACTER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-cod-depos-fim AS CHARACTER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-estab         AS INT         NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-frame         AS HANDLE      NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-outlet        AS INT         NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-ge-ini        AS INTEGER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-glb-ge-fim        AS INTEGER   NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-mostra-neg        AS LOG         NO-UNDO.  

DEF NEW GLOBAL SHARED VAR c-seg-usuario AS CHAR NO-UNDO.

DEF TEMP-TABLE tt-saldo-estoq
    FIELD  cod-estabel   LIKE movadm.saldo-estoq.cod-estabel 
    FIELD  empresa       LIKE mgadm.empresa.nome
    FIELD  it-codigo     LIKE movadm.saldo-estoq.it-codigo
    field  cod-depos     like movadm.saldo-estoq.cod-depos
    field  cod-refer     like movadm.saldo-estoq.cod-refer 
    FIELD  qt-disponivel like movadm.saldo-estoq.qtidade-atu
    field  qt-aloc-ped   like movadm.saldo-estoq.qt-aloc-ped 
    field  qt-alocada    like movadm.saldo-estoq.qt-alocada 
    field  qtidade-atu   like movadm.saldo-estoq.qtidade-atu
    field  qt-aloc-prod  LIKE movadm.saldo-estoq.qt-aloc-prod
    FIELD  qt-aloc-pi    LIKE movadm.saldo-estoq.qtidade-atu.

DEF TEMP-TABLE tt-resumo
    FIELD it-codigo  LIKE item.it-codigo
    FIELD cod-refer  LIKE saldo-estoq.cod-refer
    FIELD desc-item  LIKE item.desc-item
    FIELD categoria  AS CHAR FORMAT "x(30)"
    FIELD qt-pe      AS DECIMAL
    FIELD vl-pe      AS DECIMAL
    FIELD qt-outlet  AS DECIMAL
    FIELD vl-outlet  AS DECIMA
    INDEX indice1 it-codigo cod-refer.

/* Variaveis para o Excel */
DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF VAR chworksheet AS COM-HANDLE NO-UNDO.
DEF VAR c-lin       AS CHAR FORMAT "x(500)".
DEF VAR arq-saida   AS CHAR FORMAT "x(50)".


DEFINE VAR h-acomp      AS HANDLE NO-UNDO.
DEFINE VAR i-lin        AS INTEGER.
DEFINE VAR de-tot-qt-pe AS DECIMAL.
DEFINE VAR de-tot-vl-pe AS DECIMAL.
DEFINE VAR de-tot-qt-outlet AS DECIMAL.
DEFINE VAR de-tot-vl-outlet AS DECIMAL.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-consim
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS bt-atualizar bt-filtro bt-limp-filtro ~
bt-imprime rt-button 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-consim AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU mi-arquivo 
       MENU-ITEM mi-primeiro    LABEL "&Primeiro"      ACCELERATOR "CTRL-HOME"
       MENU-ITEM mi-anterior    LABEL "An&terior"      ACCELERATOR "CTRL-CURSOR-LEFT"
       MENU-ITEM mi-proximo     LABEL "Pr&¢ximo"       ACCELERATOR "CTRL-CURSOR-RIGHT"
       MENU-ITEM mi-ultimo      LABEL "&Èltimo"        ACCELERATOR "CTRL-END"
       MENU-ITEM mi-va-para     LABEL "&V† para"       ACCELERATOR "CTRL-T"
       MENU-ITEM mi-pesquisa    LABEL "Pes&quisa"      ACCELERATOR "CTRL-F5"
       RULE
       MENU-ITEM mi-consultas   LABEL "Co&nsultas"     ACCELERATOR "CTRL-L"
       MENU-ITEM mi-imprimir    LABEL "&Relat¢rios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU m_Ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-cadastro MENUBAR
       SUB-MENU  mi-arquivo     LABEL "&Arquivo"      
       SUB-MENU  m_Ajuda        LABEL "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_b01esimce025 AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-navega AS HANDLE NO-UNDO.
DEFINE VARIABLE h_q01esimce025 AS HANDLE NO-UNDO.
DEFINE VARIABLE h_v01esimce025 AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-atualizar 
     IMAGE-UP FILE "image\atualizar.bmp":U
     LABEL "bt-atualizar" 
     SIZE 4.29 BY 1.17 TOOLTIP "Atualizar".

DEFINE BUTTON bt-filtro 
     IMAGE-UP FILE "image/im-fil.bmp":U
     LABEL "Button 1" 
     SIZE 4.14 BY 1.21 TOOLTIP "Filtro".

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/excel.bmp":U
     LABEL "" 
     SIZE 4.29 BY 1.17 TOOLTIP "Imprime Estoque Dispon°vel".

DEFINE BUTTON bt-limp-filtro 
     IMAGE-UP FILE "image/im-fil-not.bmp":U
     LABEL "Button 2" 
     SIZE 4.14 BY 1.21 TOOLTIP "Limpar Filtro".

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.46
     BGCOLOR 7 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     bt-atualizar AT ROW 1.38 COL 44.72 WIDGET-ID 52
     bt-filtro AT ROW 1.33 COL 59.29 WIDGET-ID 48
     bt-limp-filtro AT ROW 1.33 COL 63.86 WIDGET-ID 50
     bt-imprime AT ROW 1.38 COL 49.86 WIDGET-ID 54
     rt-button AT ROW 1.21 COL 1.57
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 89.43 BY 20.04
         FONT 1 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-consim
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-consim ASSIGN
         HIDDEN             = YES
         TITLE              = "Consulta <Insira complemento>"
         COLUMN             = 26.43
         ROW                = 9.54
         HEIGHT             = 20.04
         WIDTH              = 89.43
         MAX-HEIGHT         = 28.21
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 28.21
         VIRTUAL-WIDTH      = 146.29
         RESIZE             = no
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU m-cadastro:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-consim 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-consim.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-consim
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-cad
   FRAME-NAME Custom                                                    */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-consim)
THEN w-consim:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-consim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-consim w-consim
ON END-ERROR OF w-consim /* Consulta <Insira complemento> */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-consim w-consim
ON WINDOW-CLOSE OF w-consim /* Consulta <Insira complemento> */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-atualizar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-atualizar w-consim
ON CHOOSE OF bt-atualizar IN FRAME f-cad /* bt-atualizar */
DO:
   RUN pi-atualiza-browse.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-filtro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-filtro w-consim
ON CHOOSE OF bt-filtro IN FRAME f-cad /* Button 1 */
DO:
  RUN esdlg/d01esimce025.w.
  RUN pi-atualiza-browse.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime w-consim
ON CHOOSE OF bt-imprime IN FRAME f-cad
DO:
     EMPTY TEMP-TABLE tt-resumo.
     EMPTY TEMP-TABLE tt-saldo-estoq.

     RUN pi-connect.

     RUN esrp/esimce025brp.p.
     
     IF CONNECTED('dbaux') THEN
        DISCONNECT dbaux.



     RUN utp/ut-acomp.p PERSISTENT SET h-acomp.

     {utp/ut-liter.i Verificando_Outlet_IMA *}
     RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

     FOR EACH tt-saldo-estoq WHERE 
              tt-saldo-estoq.qtidade-atu > 0 NO-LOCK.

         RUN pi-acompanhar IN h-acomp(INPUT 'Item: ' + tt-saldo-estoq.it-codigo + "   " +
                                            'Ref: ' + tt-saldo-estoq.cod-refer).

         FIND item WHERE
              item.it-codigo = tt-saldo-estoq.it-codigo NO-LOCK NO-ERROR.

         FIND grup-estoq OF ITEM NO-LOCK NO-ERROR.

         FIND tt-resumo WHERE
              tt-resumo.it-codigo = tt-saldo-estoq.it-codigo AND 
              tt-resumo.cod-refer = tt-saldo-estoq.cod-refer NO-LOCK NO-ERROR.
         IF NOT AVAIL tt-resumo THEN DO.
            CREATE tt-resumo.
            ASSIGN tt-resumo.it-codigo = tt-saldo-estoq.it-codigo
                   tt-resumo.cod-refer = tt-saldo-estoq.cod-refer
                   tt-resumo.categoria = grup-estoq.descricao
                   tt-resumo.desc-item = item.desc-item.
         END.
    
         FIND liquida-ima WHERE 
              liquida-ima.cod-estabel = tt-saldo-estoq.cod-estabel AND
              liquida-ima.it-codigo = tt-saldo-estoq.it-codigo AND
              liquida-ima.cod-refer = tt-saldo-estoq.cod-refer
              NO-LOCK NO-ERROR.
         IF AVAIL liquida-ima THEN
            ASSIGN tt-resumo.qt-outlet = tt-resumo.qt-outlet + tt-saldo-estoq.qt-disponivel.
         ELSE
            ASSIGN tt-resumo.qt-pe = tt-resumo.qt-pe + tt-saldo-estoq.qt-disponivel.
            
     END.

     RUN pi-abre-excel.
     IF chExcelApp = ? THEN DO:
        MESSAGE "O Aplicativo EXCEL n∆o foi encontrado. N∆o Ç possivel a execuá∆o do programa."
            VIEW-AS ALERT-BOX INFO BUTTONS OK.
        ASSIGN arq-saida = "".
        RETURN.
     END.
    
     /* Nomear Aba da Planilha */
     chWorkSheet = chExcelapp:Sheets:ITEM(1).
     chWorkSheet:NAME = 'Estoque'.
     chWorkSheet:TAB:ColorIndex = 19.
    
     /* Ativar a Planilha */
     chWorkSheet = chExcelapp:Sheets:ITEM(1).
     chWorkbook:Worksheets(1):activate.
     chExcelApp:ActiveWindow:Zoom = 100.
    
     ASSIGN chworksheet:range("A1"):VALUE = "ESTOQUE DISPON÷VEL PARA VENDAS EM " + STRING(TODAY,"99/99/9999") + " AS " + STRING(TIME,"HH:MM:SS").
    
     /* Configura Alinhamento Horizontal do Titulo da Planilha */
     ChWorkSheet:range("A1:K1"):SELECT().
     ChWorksheet:range("A1:K1"):Merge.
     Chworksheet:Range("A1:K1"):HorizontalAlignment =  3.
    
     /* Colorir Titulo da Planilha */
     chWorkSheet:Range("A1:L1"):FONT:ColorIndex     = 18. /* Avermelhado */
     chWorkSheet:Range("A1:L1"):Interior:ColorIndex = 2. /* Branco */
    
     /* Configura a Linha do Titulo da Planilha */
     ASSIGN chWorkSheet:Rows("1:1"):RowHeight = 25
            chWorkSheet:Rows("2:2"):RowHeight =  4
            chWorkSheet:Rows("1:1"):FONT:SIZE = 12
            chWorkSheet:Rows("1:1"):FONT:bold = TRUE.
    
     ASSIGN chworksheet:range("E3"):VALUE = 'PRONTA ENTREGA'.
     ChWorkSheet:range("E3:F3"):SELECT().
     ChWorksheet:range("E3:F3"):Merge.
     Chworksheet:Range("E3:F3"):HorizontalAlignment =  3.
    
     ASSIGN chworksheet:range("G3"):VALUE = 'OUTLET'.
     ChWorkSheet:range("G3:H3"):SELECT().
     ChWorksheet:range("G3:H3"):Merge.
     Chworksheet:Range("G3:H3"):HorizontalAlignment =  3.
    
     ASSIGN chworksheet:range("A4"):VALUE = 'ITEM'
            chworksheet:range("B4"):VALUE = 'DESCRIÄ«O'
            chworksheet:range("C4"):VALUE = 'REF' 
            chworksheet:range("D4"):VALUE = 'CATEGORIA'
            chworksheet:range("E4"):VALUE = '1a QUALIDADE'
            chworksheet:range("F4"):VALUE = '2a QUALIDADE'
            chworksheet:range("G4"):VALUE = '1a QUALIDADE'
            chworksheet:range("H4"):VALUE = '2a QUALIDADE'.
    
      /* Tamanho das Colunas */
      ASSIGN chWorkSheet:Columns("A"):ColumnWidth = 8
             chWorkSheet:Columns("B"):ColumnWidth = 35
             chWorkSheet:Columns("C"):ColumnWidth = 8
             chWorkSheet:Columns("D"):ColumnWidth = 25
             chWorkSheet:Columns("E"):ColumnWidth = 15
             chWorkSheet:Columns("F"):ColumnWidth = 15
             chWorkSheet:Columns("G"):ColumnWidth = 15
             chWorkSheet:Columns("H"):ColumnWidth = 15.
    
      /* Configura Cabeáalho das Colunas */
      chWorkSheet:Range("A3:L3"):SELECT().
      ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
             chExcelApp:SELECTION:FONT:SIZE               = 09
             chExcelApp:SELECTION:FONT:Bold               = TRUE 
             //chExcelApp:SELECTION:Interior:ColorIndex     = 2
             chExcelApp:SELECTION:FONT:ColorIndex         = 11.
    
     chWorkSheet:Range("A4:L4"):SELECT().
     ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
            chExcelApp:SELECTION:FONT:SIZE               = 09
            chExcelApp:SELECTION:FONT:Bold               = TRUE 
            //chExcelApp:SELECTION:Interior:ColorIndex     = 2
            chExcelApp:SELECTION:FONT:ColorIndex         = 11.
    
     ASSIGN chworksheet:range("A:D"):NumberFormat        = "@".
     ASSIGN chworksheet:range("E:H"):NumberFormat        = "###.###.##0,00"
            Chworksheet:range("F:H"):NumberFormat        = "###.###.##0,00".
    
     
     ASSIGN i-lin    = 5.
    
     ASSIGN de-tot-qt-pe = 0
            de-tot-vl-pe = 0
            de-tot-qt-outlet = 0
            de-tot-vl-outlet = 0.
    

     {utp/ut-liter.i Gerando_Planilha *}
     RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

     FOR EACH tt-resumo NO-LOCK.

         RUN pi-acompanhar IN h-acomp(INPUT 'Item: ' + tt-resumo.it-codigo + "   " +
                                            'Ref: ' + tt-resumo.cod-refer).


         IF var-glb-outlet = 1 THEN
             ASSIGN tt-resumo.qt-pe = 0
                    tt-resumo.vl-pe = 0.
         IF var-glb-outlet = 2 THEN
             ASSIGN tt-resumo.qt-outlet = 0
                    tt-resumo.vl-outlet = 0.
    
    
         ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = tt-resumo.it-codigo
                chworksheet:range("B" + STRING(i-lin)):VALUE = tt-resumo.desc-item
                chworksheet:range("C" + STRING(i-lin)):VALUE = tt-resumo.cod-refer
                chworksheet:range("D" + STRING(i-lin)):VALUE = tt-resumo.categoria.
    
         IF tt-resumo.cod-refer = '888' THEN
            ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = tt-resumo.qt-pe
                   chworksheet:range("H" + STRING(i-lin)):VALUE = tt-resumo.qt-outlet.
         ELSE
            ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = tt-resumo.qt-pe
                   chworksheet:range("G" + STRING(i-lin)):VALUE = tt-resumo.qt-outlet.
    
         ASSIGN de-tot-qt-pe = de-tot-qt-pe + tt-resumo.qt-pe
                de-tot-vl-pe = de-tot-vl-pe + tt-resumo.vl-pe
                de-tot-qt-outlet = de-tot-qt-outlet + tt-resumo.qt-outlet
                de-tot-vl-outlet = de-tot-vl-outlet + tt-resumo.vl-outlet.
    
         ASSIGN i-lin = i-lin + 1.

     END.
    
     ASSIGN i-lin = i-lin + 1.
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = 'TOTAIS'
            chworksheet:range("E" + STRING(i-lin)):VALUE = de-tot-qt-pe
            chworksheet:range("F" + STRING(i-lin)):VALUE = de-tot-vl-pe
            chworksheet:range("G" + STRING(i-lin)):VALUE = de-tot-qt-outlet
            chworksheet:range("H" + STRING(i-lin)):VALUE = de-tot-vl-outlet.

     RUN pi-finalizar in h-acomp.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-limp-filtro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-limp-filtro w-consim
ON CHOOSE OF bt-limp-filtro IN FRAME f-cad /* Button 2 */
DO:
  RUN pi-limpa-filtro.
  RUN pi-atualiza-browse.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-anterior
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-anterior w-consim
ON CHOOSE OF MENU-ITEM mi-anterior /* Anterior */
DO:
  RUN pi-anterior IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-arquivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-arquivo w-consim
ON MENU-DROP OF MENU mi-arquivo /* Arquivo */
DO:
  run pi-disable-menu.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-consim
ON CHOOSE OF MENU-ITEM mi-consultas /* Consultas */
DO:
  RUN pi-consulta IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-consim
ON CHOOSE OF MENU-ITEM mi-conteudo /* Conteudo */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  RUN pi-ajuda IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-consim
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relat¢rios */
DO:
  RUN pi-imprimir IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-pesquisa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-pesquisa w-consim
ON CHOOSE OF MENU-ITEM mi-pesquisa /* Pesquisa */
DO:
  RUN pi-pesquisa IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-primeiro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-primeiro w-consim
ON CHOOSE OF MENU-ITEM mi-primeiro /* Primeiro */
DO:
  RUN pi-primeiro IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-proximo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-proximo w-consim
ON CHOOSE OF MENU-ITEM mi-proximo /* Pr¢ximo */
DO:
  RUN pi-proximo IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-consim
ON CHOOSE OF MENU-ITEM mi-sair /* Sair */
DO:
  RUN pi-sair IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-consim
ON CHOOSE OF MENU-ITEM mi-sobre /* Sobre... */
DO:
  {include/sobre.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-ultimo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-ultimo w-consim
ON CHOOSE OF MENU-ITEM mi-ultimo /* Èltimo */
DO:
  RUN pi-ultimo IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-va-para
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-va-para w-consim
ON CHOOSE OF MENU-ITEM mi-va-para /* V† para */
DO:
  RUN pi-vapara IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-consim 


/* ***************************  Main Block  *************************** */
ASSIGN var-glb-cod-estab-ini = ""      
       var-glb-cod-estab-fim = "zzzzz" 
       var-glb-refer-ini     = ""
       var-glb-refer-fim     = "zzzzz"
       var-glb-cod-depos-ini = ""      
       var-glb-cod-depos-fim = "zzzzz" 
       var-glb-estab         = 9
       var-glb-outlet        = 3
       var-glb-ge-ini        = 50
       var-glb-ge-fim        = 60
       var-mostra-neg        = c-seg-usuario = 'apanzera'.


/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-consim  _ADM-CREATE-OBJECTS
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
             INPUT  'panel/p-navega.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 0,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-navega ).
       RUN set-position IN h_p-navega ( 1.33 , 2.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 24.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'panel/p-exihel.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 2,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-exihel ).
       RUN set-position IN h_p-exihel ( 1.33 , 73.57 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esvwr/v01esimce025.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Layout = ':U ,
             OUTPUT h_v01esimce025 ).
       RUN set-position IN h_v01esimce025 ( 2.79 , 1.86 ) NO-ERROR.
       /* Size in UIB:  ( 1.75 , 88.57 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esbrw/b01esimce025.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Layout = ':U ,
             OUTPUT h_b01esimce025 ).
       RUN set-position IN h_b01esimce025 ( 4.92 , 1.86 ) NO-ERROR.
       /* Size in UIB:  ( 16.00 , 87.86 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esqry/q01esimce025.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'ProgPesquisa = inzoom/z02in172.w,
                     ProgVaPara = IMgo/g01im025.w,
                     ProgIncMod = ,
                     Implantar = no':U ,
             OUTPUT h_q01esimce025 ).
       RUN set-position IN h_q01esimce025 ( 1.25 , 68.00 ) NO-ERROR.
       /* Size in UIB:  ( 1.75 , 8.00 ) */

       /* Links to SmartViewer h_v01esimce025. */
       RUN add-link IN adm-broker-hdl ( h_q01esimce025 , 'Record':U , h_v01esimce025 ).

       /* Links to SmartBrowser h_b01esimce025. */
       RUN add-link IN adm-broker-hdl ( h_q01esimce025 , 'Record':U , h_b01esimce025 ).

       /* Links to SmartQuery h_q01esimce025. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , h_q01esimce025 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'Navigation':U , h_q01esimce025 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'State':U , h_q01esimce025 ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-navega ,
             bt-filtro:HANDLE IN FRAME f-cad , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             h_p-navega , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_v01esimce025 ,
             h_p-exihel , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_b01esimce025 ,
             h_v01esimce025 , 'AFTER':U ).
    END. /* Page 0 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-consim  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-consim  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-consim)
  THEN DELETE WIDGET w-consim.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-consim  _DEFAULT-ENABLE
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
  ENABLE bt-atualizar bt-filtro bt-limp-filtro bt-imprime rt-button 
      WITH FRAME f-cad IN WINDOW w-consim.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-consim.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-consim 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-consim 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-consim 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  {include/win-size.i}

  run pi-before-initialize.

  {utp/ut9000.i "esimce025" "2.00.004.001"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  
  run pi-after-initialize.
  bt-imprime:LOAD-IMAGE("image/excel.bmp").
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-abre-excel w-consim 
PROCEDURE pi-abre-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 CREATE "Excel.Application" chExcelApp NO-ERROR.
 IF chExcelApp <> ? THEN /* Cria a Planilha */
    ASSIGN chExcelApp:VISIBLE     = TRUE  /* A Planilha Ficar† Visivel */
           chExcelApp:SheetsInNewWorkbook = 7 /* Nı PLANILHAS A SEREM CRIADAS */
           chWorkbook             = chExcelApp:Workbooks:ADD() /* Cria Planilha */
           chworksheet            = chExcelapp:sheets:ITEM(1).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-apaga-refer w-consim 
PROCEDURE pi-apaga-refer :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/*
ASSIGN fi-refer-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME} = ""
       fi-refer-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "zzzzzz"
       /*rs-estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "1"*/.

ASSIGN var-refer-ini = fi-refer-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       var-refer-fim = fi-refer-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       /*var-estab     = 1*/.
*/
ASSIGN var-glb-refer-ini     = ""      
       var-glb-refer-fim     = "zzzzz". 
       

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-atualiza-browse w-consim 
PROCEDURE pi-atualiza-browse :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/*ASSIGN var-cod-depos-ini = fi-cod-depos-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       var-cod-depos-fim = fi-cod-depos-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       var-refer-ini     = fi-refer-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       var-refer-fim     = fi-refer-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       var-estab         = int(rs-estab:SCREEN-VALUE IN FRAME {&FRAME-NAME}). /*INPUT FRAME {&FRAME-NAME} rs-estab.*/*/
  RUN local-open-query-cases IN h_b01esimce025.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-connect w-consim 
PROCEDURE pi-connect :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  RUN esapi\connect-ima-med.p. 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-limpa-filtro w-consim 
PROCEDURE pi-limpa-filtro :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
ASSIGN var-glb-refer-ini     = ""
       var-glb-refer-fim     = "zzzzz"
       var-glb-cod-depos-ini = ""      
       var-glb-cod-depos-fim = "zzzzz" 
       var-glb-estab         = 9.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-consim  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this w-consim, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-consim 
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

