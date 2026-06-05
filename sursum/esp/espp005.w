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
{include/i-prgvrs.i espp005 2.04.00.001}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */
DEF NEW GLOBAL SHARED VAR i-sit-container AS INT NO-UNDO.
DEF NEW GLOBAL SHARED VAR h-espp005 AS HANDLE NO-UNDO.
/* Local Variable Definitions ---                                       */

DEF TEMP-TABLE tt-it-container LIKE pp-it-container
    INDEX indice1 it-comprado ref-comprada.

DEF TEMP-TABLE tt-refer LIKE pp-it-container.

DEF VAR de-tot-qtde AS DEC.
DEF VAR de-tot-rateio AS DEC.
DEF VAR de-dif AS DEC.
DEF VAR sit-receb AS LOG INIT NO.


DEF TEMP-TABLE tt-pack-list
    FIELD it-codigo   AS CHAR
    FIELD cod-refer   AS CHAR
    FIELD quantidade  AS DECIMAL
    FIELD roll        AS INT
    FIELD mtr         AS DECIMAL
    FIELD estab      AS INT
    FIELD matric     AS INT
    FIELD nome       AS CHAR
    FIELD setor      AS CHAR
    FIELD dt-admis   AS CHAR
    FIELD limite     AS DEC
    FIELD sld-disp   AS DEC
    FIELD so-pode    AS CHAR
    FIELD vlr-compra AS DEC
    FIELD prazo      AS INT
    FIELD parcela    AS DEC
    FIELD a-vista    AS DEC
    FIELD parc-unica AS DEC
    FIELD parcelado  AS DEC.


DEF VAR c-arq-conv  as char no-undo.
DEF VAR l-ok as logical no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-consim
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME br-it-container

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-it-container tt-refer

/* Definitions for BROWSE br-it-container                               */
&Scoped-define FIELDS-IN-QUERY-br-it-container tt-it-container.it-codigo tt-it-container.desc-item tt-it-container.preco-compra tt-it-container.class-fiscal   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-it-container tt-it-container.preco-compra   tt-it-container.class-fiscal   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-it-container tt-it-container
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-it-container tt-it-container
&Scoped-define SELF-NAME br-it-container
&Scoped-define QUERY-STRING-br-it-container FOR EACH tt-it-container SHARE-LOCK                               BY tt-it-container.it-codigo                               BY tt-it-container.cod-refer
&Scoped-define OPEN-QUERY-br-it-container OPEN QUERY {&self-name} FOR EACH tt-it-container SHARE-LOCK                               BY tt-it-container.it-codigo                               BY tt-it-container.cod-refer.
&Scoped-define TABLES-IN-QUERY-br-it-container tt-it-container
&Scoped-define FIRST-TABLE-IN-QUERY-br-it-container tt-it-container


/* Definitions for BROWSE br-referencias                                */
&Scoped-define FIELDS-IN-QUERY-br-referencias tt-refer.cod-refer tt-refer.qt-pedida tt-refer.qt-recebida   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-referencias tt-refer.qt-recebida   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-referencias tt-refer
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-referencias tt-refer
&Scoped-define SELF-NAME br-referencias
&Scoped-define OPEN-QUERY-br-referencias RUN pi-totais. OPEN QUERY {&SELF-NAME} FOR EACH tt-refer WHERE                                  tt-refer.it-codigo = tt-it-container.it-codigo                                  NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-referencias tt-refer
&Scoped-define FIRST-TABLE-IN-QUERY-br-referencias tt-refer


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-br-it-container}~
    ~{&OPEN-QUERY-br-referencias}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-referencias ed-narrativa fi-vlr-despesas ~
fi-vlr-frete fi-vlr-seguro bt-param br-it-container RECT-4 RECT-5 rt-button 
&Scoped-Define DISPLAYED-OBJECTS ed-narrativa fi-vlr-total fi-vlr-despesas ~
fi-vlr-frete fi-vlr-seguro fi-qt-receb fi-qtd-item 

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
       MENU-ITEM mi-ultimo      LABEL "&éltimo"        ACCELERATOR "CTRL-END"
       MENU-ITEM mi-va-para     LABEL "&V  para"       ACCELERATOR "CTRL-T"
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
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-navega AS HANDLE NO-UNDO.
DEFINE VARIABLE h_q01pp001 AS HANDLE NO-UNDO.
DEFINE VARIABLE h_v04pp001 AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-confirma 
     IMAGE-UP FILE "image/im-ok.bmp":U
     LABEL "Button 17" 
     SIZE 13 BY 1.13 TOOLTIP "Confima‡Æo da importa‡Æo do excel.".

DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/im-excel.bmp":U NO-FOCUS FLAT-BUTTON
     LABEL "Button 2" 
     SIZE 13 BY 1.13 TOOLTIP "Importa‡Æo do arquivo excel".

DEFINE BUTTON bt-fecha 
     IMAGE-UP FILE "image/im-fcontainer.bmp":U
     LABEL "Button 1" 
     SIZE 6 BY 1.21 TOOLTIP "Salva Dados e Fecha o Container".

DEFINE BUTTON bt-param 
     IMAGE-UP FILE "image/im-fil.bmp":U
     LABEL "Button 1" 
     SIZE 4 BY 1.21.

DEFINE VARIABLE ed-narrativa AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 85 SCROLLBAR-VERTICAL
     SIZE 57 BY 1.46 NO-UNDO.

DEFINE VARIABLE fi-qt-receb AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-qtd-item AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-vlr-despesas AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-vlr-frete AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-vlr-seguro AS DECIMAL FORMAT ">>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-vlr-total AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FONT 6 NO-UNDO.

DEFINE RECTANGLE RECT-4
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 57 BY 2.75
     BGCOLOR 10 .

DEFINE RECTANGLE RECT-5
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 30 BY 2.75
     BGCOLOR 10 .

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-it-container FOR 
      tt-it-container SCROLLING.

DEFINE QUERY br-referencias FOR 
      tt-refer SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-it-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-it-container w-consim _FREEFORM
  QUERY br-it-container DISPLAY
      tt-it-container.it-codigo  WIDTH 8  FORMAT "x(8)" 
    tt-it-container.desc-item    WIDTH 25 FORMAT "x(25)" 
    tt-it-container.preco-compra WIDTH 10 COLUMN-LABEL "Pre‡o"
    tt-it-container.class-fiscal WIDTH 9  COLUMN-LABEL "Class.Fiscal"
ENABLE
    tt-it-container.preco-compra
    tt-it-container.class-fiscal
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 57 BY 7.5
         FONT 1
         TITLE "Itens do Container" ROW-HEIGHT-CHARS .63.

DEFINE BROWSE br-referencias
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-referencias w-consim _FREEFORM
  QUERY br-referencias NO-LOCK DISPLAY
      tt-refer.cod-refer      FORMAT "x(8)"  WIDTH 5    COLUMN-LABEL "Refer"
      tt-refer.qt-pedida                     WIDTH 10   
      tt-refer.qt-recebida                   WIDTH 10
ENABLE
   tt-refer.qt-recebida
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 30 BY 9.71
         FONT 1
         TITLE "Referˆncias" ROW-HEIGHT-CHARS .63.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     bt-excel AT ROW 17.79 COL 87.86 RIGHT-ALIGNED WIDGET-ID 4
     bt-confirma AT ROW 17.79 COL 61.72 WIDGET-ID 6
     bt-fecha AT ROW 1.38 COL 52
     br-referencias AT ROW 7.79 COL 60
     ed-narrativa AT ROW 16 COL 2 NO-LABEL
     fi-vlr-total AT ROW 18.08 COL 19 COLON-ALIGNED NO-LABEL
     fi-vlr-despesas AT ROW 19.08 COL 19 COLON-ALIGNED NO-LABEL
     fi-vlr-frete AT ROW 18.08 COL 43 COLON-ALIGNED NO-LABEL
     fi-vlr-seguro AT ROW 19.08 COL 43 COLON-ALIGNED NO-LABEL
     fi-qt-receb AT ROW 19.08 COL 73.72 COLON-ALIGNED NO-LABEL
     fi-qtd-item AT ROW 19.08 COL 59.57 COLON-ALIGNED NO-LABEL
     bt-param AT ROW 1.33 COL 45.57
     br-it-container AT ROW 7.79 COL 2
     " Narrativa" VIEW-AS TEXT
          SIZE 57 BY .54 AT ROW 15.38 COL 2
          BGCOLOR 1 FGCOLOR 15 FONT 6
     "Outras:" VIEW-AS TEXT
          SIZE 6 BY .75 AT ROW 19.17 COL 14.57
          BGCOLOR 10 FGCOLOR 0 FONT 6
     "Valor Total:" VIEW-AS TEXT
          SIZE 9.29 BY .75 AT ROW 18.17 COL 11
          BGCOLOR 10 FGCOLOR 0 FONT 6
     " Valores" VIEW-AS TEXT
          SIZE 6.72 BY .58 AT ROW 17.58 COL 3.29
          BGCOLOR 10 FGCOLOR 12 FONT 6
     "Frete:" VIEW-AS TEXT
          SIZE 4.86 BY .75 AT ROW 18.17 COL 39.72
          BGCOLOR 10 FGCOLOR 0 FONT 6
     "Seguro:" VIEW-AS TEXT
          SIZE 6.86 BY .75 AT ROW 19.17 COL 38.14
          BGCOLOR 10 FGCOLOR 0 FONT 6
     RECT-4 AT ROW 17.5 COL 2
     RECT-5 AT ROW 17.5 COL 60
     rt-button AT ROW 1.21 COL 1.57
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 89.29 BY 19.42
         FONT 1.


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
         TITLE              = "Fechamento de Containers - ESPP005.W"
         HEIGHT             = 19.42
         WIDTH              = 89.29
         MAX-HEIGHT         = 21.13
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 21.13
         VIRTUAL-WIDTH      = 114.29
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
/* BROWSE-TAB br-referencias bt-fecha f-cad */
/* BROWSE-TAB br-it-container bt-param f-cad */
/* SETTINGS FOR BUTTON bt-confirma IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-excel IN FRAME f-cad
   NO-ENABLE ALIGN-R                                                    */
/* SETTINGS FOR BUTTON bt-fecha IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-qt-receb IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-qtd-item IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-vlr-total IN FRAME f-cad
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-consim)
THEN w-consim:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-it-container
/* Query rebuild information for BROWSE br-it-container
     _START_FREEFORM
OPEN QUERY {&self-name} FOR EACH tt-it-container SHARE-LOCK
                              BY tt-it-container.it-codigo
                              BY tt-it-container.cod-refer.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-it-container */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-referencias
/* Query rebuild information for BROWSE br-referencias
     _START_FREEFORM
RUN pi-totais.
OPEN QUERY {&SELF-NAME} FOR EACH tt-refer WHERE
                                 tt-refer.it-codigo = tt-it-container.it-codigo
                                 NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-referencias */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-consim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-consim w-consim
ON END-ERROR OF w-consim /* Fechamento de Containers - ESPP005.W */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-consim w-consim
ON WINDOW-CLOSE OF w-consim /* Fechamento de Containers - ESPP005.W */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-it-container
&Scoped-define SELF-NAME br-it-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-it-container w-consim
ON ENTRY OF br-it-container IN FRAME f-cad /* Itens do Container */
DO:
  ASSIGN tt-it-container.preco-compra:READ-ONLY IN BROWSE br-it-container = NO
         tt-it-container.class-fiscal:READ-ONLY IN BROWSE br-it-container = NO.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-it-container w-consim
ON ROW-LEAVE OF br-it-container IN FRAME f-cad /* Itens do Container */
DO:
  ASSIGN fi-vlr-total = fi-vlr-total + 
                            (INPUT BROWSE br-it-container tt-it-container.preco-compra ) -
                            (tt-it-container.preco-compra).      
        
  ASSIGN INPUT BROWSE br-it-container tt-it-container.preco-compra.

  DISP fi-vlr-total
       WITH FRAME {&FRAME-NAME}.
  
  IF NUM-RESULTS("br-it-container") = br-it-container:FOCUSED-ROW THEN DO.
     APPLY 'entry' TO bt-fecha.
     RETURN NO-APPLY.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-it-container w-consim
ON VALUE-CHANGED OF br-it-container IN FRAME f-cad /* Itens do Container */
DO:
  {&OPEN-QUERY-br-referencias}     
  ASSIGN ed-narrativa:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "".
  IF AVAIL tt-it-container THEN
     ASSIGN ed-narrativa:SCREEN-VALUE IN FRAME {&FRAME-NAME} = tt-it-container.narrativa.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-referencias
&Scoped-define SELF-NAME br-referencias
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-referencias w-consim
ON ROW-LEAVE OF br-referencias IN FRAME f-cad /* Referˆncias */
DO:
  ASSIGN fi-qt-receb = fi-qt-receb + 
                       INPUT BROWSE br-referencias tt-refer.qt-recebida -
                       tt-refer.qt-recebida.

  ASSIGN INPUT BROWSE br-referencias tt-refer.qt-recebida.

  DISP fi-qt-receb
       WITH FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-confirma
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-confirma w-consim
ON CHOOSE OF bt-confirma IN FRAME f-cad /* Button 17 */
DO:
  IF AVAIL tt-refer THEN DO.
      FOR EACH tt-refer NO-LOCK.
          FIND bc-etiqueta WHERE
               bc-etiqueta.num-pedido = tt-refer.nr-container AND
               bc-etiqueta.it-codigo = tt-refer.it-codigo AND    
               bc-etiqueta.referencia = tt-refer.cod-refer AND   
               bc-etiqueta.lote = tt-refer.cod-refer             
               SHARE-LOCK.
          IF NOT AVAIL bc-etiqueta THEN DO.
             ASSIGN bc-etiqueta.num-pedido = tt-refer.nr-container 
                    bc-etiqueta.it-codigo = tt-refer.it-codigo 
                    bc-etiqueta.referencia = tt-refer.cod-refer 
                    bc-etiqueta.lote = tt-refer.cod-refer.
                    bc-etiqueta.qt-item = tt-refer.qt-recebida.
          END.
       END.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel w-consim
ON CHOOSE OF bt-excel IN FRAME f-cad /* Button 2 */
DO:
        SYSTEM-DIALOG GET-FILE c-arq-conv
         FILTERS "*.xls" "*.xls",
                 "*.*" "*.*"
         DEFAULT-EXTENSION "xls"
         INITIAL-DIR "c:\desktop" 
         MUST-EXIST
         USE-FILENAME
         UPDATE l-ok.
      if  l-ok = yes then
          RUN pi-load-excel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-fecha
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-fecha w-consim
ON CHOOSE OF bt-fecha IN FRAME f-cad /* Button 1 */
DO:
    RUN esp/espp009.p.

    /*
    FIND param-re WHERE
         param-re.usuario = c-seg-usuario NO-LOCK NO-ERROR.
    IF NOT AVAIL param-re THEN DO:
       MESSAGE "Usu rio nÆo Cadastrado no Recebimento..."
           VIEW-AS ALERT-BOX INFO BUTTONS OK.
       RETURN NO-APPLY.
    END.
    IF AVAIL param-re AND 
       param-re.baixa-estoq = NO THEN DO:
       MESSAGE "Usu rio nÆo atualiza estoque autom ticamente..."
            VIEW-AS ALERT-BOX INFO BUTTONS OK.
       RETURN NO-APPLY.
    END.
    FIND para-fat NO-LOCK NO-ERROR.

    FIND ser-estab WHERE
         ser-estab.cod-estabel = STRING(i-ep-codigo-usuario)   AND
         ser-estab.serie       = para-fat.serie-pad 
         NO-LOCK NO-ERROR.
    IF AVAIL ser-estab THEN DO:
       /*
       /*IF (ser-estab.dt-ult-fat + ser-estab.nr-dias-abe) < TODAY THEN DO:*/
       IF (ser-estab.dt-prox-fat) < TODAY THEN DO:
           MESSAGE "Data do faturamento menor que o dia de hoje..."  
               VIEW-AS ALERT-BOX INFO BUTTONS OK.
           RETURN NO-APPLY.
       END.
       IF (ser-estab.dt-prox-fat) > TODAY THEN DO:
           MESSAGE "Data do faturamento maior que o dia de hoje..."
               VIEW-AS ALERT-BOX INFO BUTTONS OK.
           RETURN NO-APPLY.
       END.
       */
        IF (ser-estab.dt-prox-fat) < TODAY THEN DO:
            MESSAGE "Data do faturamento menor que o dia de hoje..."  
                VIEW-AS ALERT-BOX INFO BUTTONS OK.
            RETURN NO-APPLY.
        END.
        IF (ser-estab.dt-ult-fat) > TODAY THEN DO:
            MESSAGE "Data do faturamento maior que o dia de hoje..."
                VIEW-AS ALERT-BOX INFO BUTTONS OK.
            RETURN NO-APPLY.
        END.


    END.

    FIND docum-est WHERE
         docum-est.declaracao-import = STRING(pp-container.nr-container)
         NO-LOCK NO-ERROR.
    IF AVAIL docum-est AND docum-est.ce-atual = YES THEN DO:
       ASSIGN sit-receb = YES.

       RUN esp/message2.p (INPUT "Fechamento de Container", 
                           INPUT "Recebimento feito pelo RE1001. Deseja Fechar o Container ?").

       IF RETURN-VALUE = 'YES' THEN                                                           
          RUN pi-fecha-container IN h_v04pp001 (INPUT sit-receb).
    END.
    ELSE DO:

       FIND CURRENT pp-container NO-ERROR.
       ASSIGN pp-container.vlr-despesas = INPUT FRAME {&FRAME-NAME} fi-vlr-despesas  
              pp-container.vlr-frete = INPUT FRAME {&FRAME-NAME} fi-vlr-frete  
              pp-container.vlr-seguro = INPUT FRAME {&FRAME-NAME} fi-vlr-seguro.

       FOR EACH tt-refer EXCLUSIVE-LOCK.                                                                     
           ASSIGN de-tot-qtde = de-tot-qtde + tt-refer.qt-recebida.                           
       END.                                                                                   
       IF de-tot-qtde = 0 THEN DO.
          MESSAGE "NÆo existem Quantidades Recebidas..." 
              VIEW-AS ALERT-BOX INFO BUTTONS OK.
          RETURN NO-APPLY.
       END.                                                                                   
                                                                                               
       FOR EACH tt-it-container NO-LOCK. 
           FOR EACH tt-refer WHERE tt-refer.it-codigo = tt-it-container.it-codigo.                   

               FIND FIRST pp-it-container WHERE                                                     
                          pp-it-container.nr-container = tt-refer.nr-container AND
                          pp-it-container.it-codigo = tt-refer.it-codigo AND
                          pp-it-container.cod-refer = tt-refer.cod-refer
                          EXCLUSIVE-LOCK NO-ERROR. 

               IF AVAIL pp-it-container THEN DO:
                  ASSIGN pp-it-container.preco-compra = tt-it-container.preco-compra             
                         pp-it-container.class-fiscal = tt-it-container.class-fiscal             
                         /*pp-it-container.narrativa = tt-it-container.narrativa*/
                         pp-it-container.qt-recebida = tt-refer.qt-recebida. 

                  ASSIGN tt-refer.narrativa = tt-it-container.narrativa.
                  
                  /*IF pp-container.cod-estabel = "1" THEN DO:*/
                      /*IF NOT pp-it-container.narrativa MATCHES "* REF: *" THEN DO:*/
                          ASSIGN tt-refer.narrativa = tt-refer.narrativa + " REF: " + pp-it-container.cod-refer. /* Adiciona Referencia do item*/
                          
                          FIND FIRST ITEM     WHERE ITEM.it-codigo     = pp-it-container.it-codigo NO-LOCK NO-ERROR.
                          FIND FIRST item-ext WHERE item-ext.it-codigo = ITEM.it-codigo            NO-LOCK NO-ERROR. 
                          
                          IF AVAIL item-ext AND item-ext.gramatura > 0 THEN /* Adiciona Gramatura do item*/
                             ASSIGN tt-refer.narrativa = tt-refer.narrativa + "  G/M: " + STRING(item-ext.gramatura).
                          IF ITEM.cod-imagem <> "" THEN /* Adiciona Regra de lavagem do item*/
                             ASSIGN tt-refer.narrativa = tt-refer.narrativa + "  RL: " + ITEM.cod-imagem. 
                      /*END.*/
                /*  END.*/

                  ASSIGN pp-it-container.narrativa = tt-refer.narrativa.
                  
               END.
           END.                                                                               
       END.                             
                                                                                               
       RUN esp/message2.p (INPUT "Fechamento de Container",                                   
                           INPUT "Deseja Criar Recebimento Fiscal e Fechar o Container ?").   

       IF RETURN-VALUE = 'YES' THEN                                                           
          RUN pi-fecha-container IN h_v04pp001(INPUT NO). 
    END.
    */
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-param
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-param w-consim
ON CHOOSE OF bt-param IN FRAME f-cad /* Button 1 */
DO:
   RUN esp/espp003a.p.
   RUN adm-open-query-cases IN h_q01pp001.
   RUN pi-primeiro IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME ed-narrativa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL ed-narrativa w-consim
ON LEAVE OF ed-narrativa IN FRAME f-cad
DO:
  ASSIGN tt-it-container.narrativa = SELF:SCREEN-VALUE.   
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
ON CHOOSE OF MENU-ITEM mi-ultimo /* éltimo */
DO:
  RUN pi-ultimo IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-va-para
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-va-para w-consim
ON CHOOSE OF MENU-ITEM mi-va-para /* V  para */
DO:
  RUN pi-vapara IN h_p-navega.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-it-container
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-consim 


/* ***************************  Main Block  *************************** */

ON 'leave':U OF tt-it-container.class-fiscal IN BROWSE br-it-container DO:
   FIND classif-fisc WHERE
        classif-fisc.class-fiscal = INPUT BROWSE br-it-container tt-it-container.class-fiscal
        NO-LOCK NO-ERROR.
   IF NOT AVAIL classif-fisc THEN DO.
      MESSAGE 'Classifica‡Æo Fiscal NÆo Cadastrada...'
          VIEW-AS ALERT-BOX ERROR BUTTONS OK.
      APPLY 'ENTRY' TO SELF.
      RETURN NO-APPLY.
   END.
END.
                    
                    
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
             INPUT  'esvwr/v04pp001.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Layout = ':U ,
             OUTPUT h_v04pp001 ).
       RUN set-position IN h_v04pp001 ( 2.75 , 2.00 ) NO-ERROR.
       /* Size in UIB:  ( 4.92 , 88.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esqry/q01pp001.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'ProgPesquisa = eszoom\z01pp001.w,
                     ProgVaPara = esgo\g01pp001.w,
                     ProgIncMod = ,
                     Implantar = no':U ,
             OUTPUT h_q01pp001 ).
       RUN set-position IN h_q01pp001 ( 1.50 , 27.00 ) NO-ERROR.
       /* Size in UIB:  ( 1.00 , 10.00 ) */

       /* Links to SmartViewer h_v04pp001. */
       RUN add-link IN adm-broker-hdl ( h_q01pp001 , 'Record':U , h_v04pp001 ).

       /* Links to SmartQuery h_q01pp001. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , h_q01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'Navigation':U , h_q01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'State':U , h_q01pp001 ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-navega ,
             bt-fecha:HANDLE IN FRAME f-cad , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             h_p-navega , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_v04pp001 ,
             h_p-exihel , 'AFTER':U ).
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
  DISPLAY ed-narrativa fi-vlr-total fi-vlr-despesas fi-vlr-frete fi-vlr-seguro 
          fi-qt-receb fi-qtd-item 
      WITH FRAME f-cad IN WINDOW w-consim.
  ENABLE br-referencias ed-narrativa fi-vlr-despesas fi-vlr-frete fi-vlr-seguro 
         bt-param br-it-container RECT-4 RECT-5 rt-button 
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

  {utp/ut9000.i "ESPP005" "2.04.00.001"}

  ASSIGN i-sit-container = 1.

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-load-excel w-consim 
PROCEDURE pi-load-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF var chWorksheet AS COM-HANDLE NO-UNDO.
DEF VAR i-Lin       AS INT.
DEF VAR c-comando   AS CHAR.

DEF VAR de-valor-cel   AS DECIMAL NO-UNDO.
DEF VAR de-tot-vlr-cel   AS DECIMAL NO-UNDO.
DEF VAR c-controle     AS CHAR NO-UNDO.
DEF VAR i-it-codigo    AS INTEGER NO-UNDO.
DEF VAR c-cod-refer    AS CHAR NO-UNDO.
DEF VAR l-item         AS LOGICAL INITIAL YES.
DEF VAR c-cod-emit     AS CHAR.
DEF VAR c-pais         AS CHAR.
DEF VAR i-cod-fornec   AS INTEGER NO-UNDO.
DEF VAR i-roll         AS INTEGER NO-UNDO.


FOR EACH tt-pack-list NO-LOCK.
    DELETE tt-pack-list.
END.

/*MESSAGE c-arq-conv
    VIEW-AS ALERT-BOX INFO BUTTONS OK.*/



/* Inicializa»’o da Planilha */
CREATE "Excel.Application" chExcelApp NO-ERROR.
IF chExcelApp <> ? THEN /* Cria a Planilha */
   ASSIGN chExcelApp:SheetsInNewWorkbook = 1 /* Nõ PLANILHAS A SEREM CRIADAS */
          chExcelApp:VISIBLE = FALSE  /* A Planilha n’o Ficarÿ Visivel */
          /*chWorkbook         = chExcelApp:Workbooks:OPEN("T:\janete\Lojinha\venda_loja_funcionario.xls") */
          chWorkbook         = chExcelApp:Workbooks:OPEN(c-arq-conv)
          chWorksheet        = chExcelapp:Sheets:ITEM(1).
ELSE DO:
   MESSAGE "O Aplicativo EXCEL n’o foi encontrado. N’o foi poss­vel executar o programa."
       VIEW-AS ALERT-BOX INFO BUTTONS OK.
   RETURN.
END.

/* Atualiza a Temp-Table */
chWorkbook:Worksheets(1):activate.
ASSIGN i-Lin = 10.
REPEAT:
   

       
       IF l-item = YES THEN DO.
          ASSIGN i-cod-fornec =  INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE).
          ASSIGN i-Lin = i-Lin + 9.
          ASSIGN i-it-codigo = INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE)
                 c-cod-refer = chWorksheet:range("B" + STRING(i-Lin + 2)):VALUE.
              /* MESSAGE i-cod-fornec
        VIEW-AS ALERT-BOX INFO BUTTONS OK. */
          IF chWorksheet:range("B" + STRING(i-Lin)):VALUE = ? THEN LEAVE.
          /*
          FIND tt-pack-list WHERE 
               tt-pack-list.it-codigo = STRING(i-it-codigo) NO-LOCK NO-ERROR.
          IF NOT AVAIL tt-pack-list THEN DO.
             /* MESSAGE i-it-codigo
                 VIEW-AS ALERT-BOX INFO BUTTONS OK. */
             CREATE tt-pack-list.
             ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                    de-valor-cel = 0.
          END.
          */
          ASSIGN l-item = NO.
          ASSIGN i-Lin = i-Lin + 3
                 de-valor-cel = 0.
       END.
       ELSE DO.

             /*   MESSAGE i-Lin
                       chWorksheet:range("B" + STRING(i-Lin)):VALUE
                       chWorksheet:range("D" + STRING(i-Lin)):VALUE
                       chWorksheet:range("F" + STRING(i-Lin)):VALUE
                       chWorksheet:range("H" + STRING(i-Lin)):VALUE
                       chWorksheet:range("J" + STRING(i-Lin)):VALUE
                  VIEW-AS ALERT-BOX INFO BUTTONS OK.   */
            
            
            IF chWorksheet:range("A" + STRING(i-Lin)):VALUE <> "TOTAL" AND
               chWorksheet:range("A" + STRING(i-Lin)):VALUE <> "TOTAL GERAL" THEN DO.
               IF chWorksheet:range("A" + STRING(i-Lin)):VALUE <> ? THEN DO.
                  ASSIGN i-roll = INTEGER(chWorksheet:range("A" + STRING(i-Lin)):VALUE).
                  FIND tt-pack-list WHERE 
                       tt-pack-list.it-codigo = STRING(i-it-codigo) AND
                       tt-pack-list.cod-refer = STRING(c-cod-refer) AND
                       tt-pack-list.roll =  i-roll NO-LOCK NO-ERROR.
                  IF NOT AVAIL tt-pack-list THEN DO.
                     CREATE tt-pack-list.
                     ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                            tt-pack-list.cod-refer = STRING(c-cod-refer).
                     ASSIGN tt-pack-list.roll = INTEGER (chWorksheet:range("A" + STRING(i-Lin)):VALUE).
                  END.
                  ASSIGN tt-pack-list.mtr = INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE).
               END.
               IF chWorksheet:range("C" + STRING(i-Lin)):VALUE <> ? THEN DO.
                  FIND tt-pack-list WHERE 
                       tt-pack-list.it-codigo = STRING(i-it-codigo) AND
                       tt-pack-list.cod-refer = STRING(c-cod-refer) AND
                       tt-pack-list.roll =  i-roll NO-LOCK NO-ERROR.
                  IF NOT AVAIL tt-pack-list THEN DO.
                     CREATE tt-pack-list.
                     ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                            tt-pack-list.cod-refer = STRING(c-cod-refer).
                     ASSIGN tt-pack-list.roll = INTEGER (chWorksheet:range("C" + STRING(i-Lin)):VALUE).
                  END.
                  ASSIGN tt-pack-list.mtr = INTEGER (chWorksheet:range("D" + STRING(i-Lin)):VALUE).
               END.
               IF chWorksheet:range("E" + STRING(i-Lin)):VALUE <> ? THEN DO.
                  FIND tt-pack-list WHERE 
                       tt-pack-list.it-codigo = STRING(i-it-codigo) AND
                       tt-pack-list.cod-refer = STRING(c-cod-refer) AND
                       tt-pack-list.roll =  i-roll NO-LOCK NO-ERROR.
                  IF NOT AVAIL tt-pack-list THEN DO.
                     CREATE tt-pack-list.
                     ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                            tt-pack-list.cod-refer = STRING(c-cod-refer).
                     ASSIGN tt-pack-list.roll = INTEGER (chWorksheet:range("E" + STRING(i-Lin)):VALUE).
                  END.
                  ASSIGN tt-pack-list.mtr = INTEGER (chWorksheet:range("F" + STRING(i-Lin)):VALUE).
               END.
               IF chWorksheet:range("G" + STRING(i-Lin)):VALUE <> ? THEN DO.
                  FIND tt-pack-list WHERE 
                       tt-pack-list.it-codigo = STRING(i-it-codigo) AND
                       tt-pack-list.cod-refer = STRING(c-cod-refer) AND
                       tt-pack-list.roll =  i-roll NO-LOCK NO-ERROR.
                  IF NOT AVAIL tt-pack-list THEN DO.
                     CREATE tt-pack-list.
                     ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                            tt-pack-list.cod-refer = STRING(c-cod-refer).
                     ASSIGN tt-pack-list.roll = INTEGER (chWorksheet:range("G" + STRING(i-Lin)):VALUE).
                  END.
                  ASSIGN tt-pack-list.mtr = INTEGER (chWorksheet:range("H" + STRING(i-Lin)):VALUE).
               END.
               IF chWorksheet:range("I" + STRING(i-Lin)):VALUE <> ? THEN DO.
                  FIND tt-pack-list WHERE 
                       tt-pack-list.it-codigo = STRING(i-it-codigo) AND
                       tt-pack-list.cod-refer = STRING(c-cod-refer) AND
                       tt-pack-list.roll =  i-roll NO-LOCK NO-ERROR.
                  IF NOT AVAIL tt-pack-list THEN DO.
                     CREATE tt-pack-list.
                     ASSIGN tt-pack-list.it-codigo = STRING(i-it-codigo)
                            tt-pack-list.cod-refer = STRING(c-cod-refer).
                     ASSIGN tt-pack-list.roll = INTEGER (chWorksheet:range("I" + STRING(i-Lin)):VALUE).
                  END.
                  ASSIGN tt-pack-list.mtr = INTEGER (chWorksheet:range("J" + STRING(i-Lin)):VALUE).
               END.
            /*
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("A" + STRING(i-Lin)):VALUE = ? THEN 0 ELSE  INTEGER (chWorksheet:range("A" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("C" + STRING(i-Lin)):VALUE = ? THEN 0 ELSE  INTEGER (chWorksheet:range("C" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("E" + STRING(i-Lin)):VALUE = ? THEN 0 ELSE  INTEGER (chWorksheet:range("E" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("G" + STRING(i-Lin)):VALUE = ? THEN 0 ELSE  INTEGER (chWorksheet:range("G" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("I" + STRING(i-Lin)):VALUE = ? THEN 0 ELSE  INTEGER (chWorksheet:range("I" + STRING(i-Lin)):VALUE). */

            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("B" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("B" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("D" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("D" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("F" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("F" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("H" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("H" + STRING(i-Lin)):VALUE).
            ASSIGN de-valor-cel =  de-valor-cel + IF chWorksheet:range("J" + STRING(i-Lin)):VALUE = ? THEN 0.00 ELSE  INTEGER (chWorksheet:range("J" + STRING(i-Lin)):VALUE).
            
            END.
                      /*     MESSAGE de-valor-cel
                                VIEW-AS ALERT-BOX INFO BUTTONS OK.  */
       END.

       ASSIGN c-controle = IF chWorksheet:range("A" + STRING(i-Lin)):VALUE = "?" THEN "0.00" ELSE  chWorksheet:range("A" + STRING(i-Lin)):VALUE.

       IF c-controle = "TOTAL" THEN DO.
          /* ASSIGN tt-pack-list.quantidade = decimal(de-valor-cel). */
          ASSIGN i-Lin = i-Lin + 10.
          ASSIGN de-tot-vlr-cel = de-tot-vlr-cel + de-valor-cel.
          l-item = YES.
        /*   MESSAGE c-controle 
              VIEW-AS ALERT-BOX INFO BUTTONS OK. */

       END.

       IF c-controle = "TOTAL GERAL" THEN DO.
          chExcelApp:DisplayAlerts = FALSE. 
          chWorkBook:CLOSE().
       END.

   ASSIGN i-Lin = i-Lin + 1.
END.

/* Fecha Planilha */
chExcelApp:DisplayAlerts = FALSE. 
chWorkBook:CLOSE().

FOR EACH tt-pack-list NO-LOCK.
    DISP tt-pack-list.it-codigo
         tt-pack-list.roll
         tt-pack-list.mtr.
    
    FIND tt-it-container WHERE
         tt-it-container.it-codigo = tt-pack-list.it-codigo NO-LOCK NO-ERROR.
         IF AVAIL tt-it-container THEN DO.
            FIND tt-refer WHERE
                 tt-refer.nr-container = tt-it-container.nr-container AND
                 tt-refer.it-codigo    = tt-it-container.it-codigo AND
                 tt-refer.cod-refer    = tt-pack-list.cod-refer  SHARE-LOCK NO-ERROR.
            IF AVAIL tt-refer THEN DO.
               ASSIGN tt-refer.qt-recebida = tt-pack-list.mtr.
            END.
            ELSE DO.
               CREATE tt-refer.
               ASSIGN tt-refer.nr-container = tt-it-container.nr-container
                      tt-refer.it-codigo = tt-it-container.it-codigo
                      tt-refer.cod-refer = tt-it-container.cod-refer.
               ASSIGN tt-refer.qt-recebida = tt-pack-list.mtr.

            END.

         END.
         
END.

FIND FIRST tt-pack-list NO-LOCK NO-ERROR.
IF AVAIL tt-pack-list THEN
   ASSIGN bt-confirma:SENSITIVE IN FRAME {&FRAME-NAME} = YES.


    {&OPEN-QUERY-br-it-container}
    {&OPEN-QUERY-br-referencias}

/* 
FOR EACH tt-pack-list.
    DISP tt-pack-list.vlr-compra FORMAT ">>>>>>>9.9999999999999"
         tt-pack-list.vlr-compra > 0
         DEC(STRING(tt-pack-list.vlr-compra)) > 0.
    DISP tt-pack-list 
         WITH SIDE-LABELS 1 COLUMN.
END.
 
 */




END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-popula-browse w-consim 
PROCEDURE pi-popula-browse :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER p-row-container AS ROWID.
    
    EMPTY TEMP-TABLE tt-it-container.
    EMPTY TEMP-TABLE tt-refer.

    FIND pp-container WHERE 
         ROWID(pp-container) = p-row-container NO-LOCK NO-ERROR.

    ASSIGN bt-fecha:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
    IF pp-container.situacao = 1 THEN
       ASSIGN bt-fecha:SENSITIVE IN FRAME {&FRAME-NAME} = YES.    

    ASSIGN fi-vlr-despesas = 0
           fi-vlr-total    = 0
           fi-vlr-seguro   = 0
           fi-vlr-frete    = 0.

    FOR EACH pp-it-container OF pp-container NO-LOCK
        BREAK BY pp-it-container.it-codigo.
        IF FIRST-OF(pp-it-container.it-codigo) THEN DO.
           CREATE tt-it-container.
           BUFFER-COPY pp-it-container TO tt-it-container.
           
           ASSIGN tt-it-container.narrativa = SUBSTRING(tt-it-container.narrativa,1,INDEX(tt-it-container.narrativa,"ref:") - 1).
           
           FIND ITEM WHERE
                item.it-codigo = pp-it-container.it-codigo
                NO-LOCK NO-ERROR.
           IF AVAIL ITEM THEN
              ASSIGN tt-it-container.desc-item = ITEM.desc-item.

           IF tt-it-container.class-fiscal = '' THEN
              ASSIGN tt-it-container.class-fiscal = ITEM.class-fiscal.

           ASSIGN fi-vlr-total = fi-vlr-total + pp-it-container.preco-compra.
        END.

        CREATE tt-refer.
        BUFFER-COPY pp-it-container TO tt-refer.

        IF tt-refer.qt-recebida = 0 THEN DO.
           FOR EACH bc-etiqueta WHERE 
                    bc-etiqueta.num-pedido = tt-refer.nr-container AND
                    bc-etiqueta.it-codigo = tt-refer.it-codigo AND
                    bc-etiqueta.referencia = tt-refer.cod-refer AND
                    bc-etiqueta.lote = tt-refer.cod-refer
                    NO-LOCK.
               ASSIGN tt-refer.qt-recebida = tt-refer.qt-recebida + bc-etiqueta.qt-item.
           END.
        END.

        IF pp-it-container.it-codigo = '' THEN
           ASSIGN bt-fecha:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
    END.

    {&OPEN-QUERY-br-it-container}

    ASSIGN tt-it-container.preco-compra:READ-ONLY IN BROWSE br-it-container = YES
           tt-it-container.class-fiscal:READ-ONLY IN BROWSE br-it-container = YES.

    ASSIGN fi-vlr-despesas = pp-container.vlr-despesas
           fi-vlr-frete = pp-container.vlr-frete
           fi-vlr-seguro = pp-container.vlr-seguro.

    DISP fi-vlr-total
         fi-vlr-despesas
         fi-vlr-frete
         fi-vlr-seguro
         WITH FRAME {&FRAME-NAME}.

    APPLY 'VALUE-CHANGED' TO br-it-container.
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-totais w-consim 
PROCEDURE pi-totais :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    ASSIGN fi-qtd-item = 0
           fi-qt-receb = 0.
    FOR EACH tt-refer WHERE
             tt-refer.it-codigo = tt-it-container.it-codigo
             NO-LOCK.
        ASSIGN fi-qtd-item = fi-qtd-item + tt-refer.qt-pedida
               fi-qt-receb = fi-qt-receb + tt-refer.qt-recebida.
    END.
    DISP fi-qtd-item
         fi-qt-receb
         WITH FRAME {&FRAME-NAME}.

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

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-refer"}
  {src/adm/template/snd-list.i "tt-it-container"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

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

  RUN pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

