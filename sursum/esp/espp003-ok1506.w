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
{include/i-prgvrs.i XX9999 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */
DEF NEW GLOBAL SHARED VAR i-sit-container AS INT NO-UNDO.

/* Local Variable Definitions ---                                       */

DEFINE TEMP-TABLE tt-it-container NO-UNDO LIKE pp-it-container
       FIELD cod-estabel LIKE pp-container.cod-estabel
       INDEX ch-item it-codigo cod-refer.
    
/* Temp-Table and Buffer definitions                                    */
DEFINE TEMP-TABLE tt-etiqueta NO-UNDO LIKE ob-etiqueta.

DEF TEMP-TABLE tt-etq
    FIELD num-rolo-imp AS INTEGER
    FIELD quantidade AS DECIMAL.

DEF TEMP-TABLE tt-erro NO-UNDO
    FIELD i-sequen AS INT             
    FIELD cd-erro  AS INT
    FIELD mensagem AS CHAR FORMAT "x(255)".

DEF BUFFER bf-tt-etiqueta      FOR tt-etiqueta.

DEF VAR c-desc-item LIKE ITEM.desc-item.
DEF VAR r-rowid AS ROWID                  NO-UNDO.
DEF VAR i-ct    AS INT.
DEF VAR i-row   AS INT.
DEF VAR i-etq   LIKE bc-param-ext.param-inteiro.
DEF VAR l-new-record AS LOG.
DEF VAR l-reimp-etq AS LOG INIT YES.
DEF VAR c-cod-chave-param-ext  LIKE bc-param-ext.cod-chave-param-ext.
DEF VAR c-cod-estab AS CHAR.

DEF VAR i-tp-embal AS INT.

{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-consim
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME br-etiquetas

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-etiqueta tt-it-container

/* Definitions for BROWSE br-etiquetas                                  */
&Scoped-define FIELDS-IN-QUERY-br-etiquetas tt-etiqueta.num-etiqueta tt-etiqueta.num-rolo-imp tt-etiqueta.quantidade   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-etiquetas tt-etiqueta.num-rolo-imp   tt-etiqueta.quantidade   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-etiquetas tt-etiqueta
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-etiquetas tt-etiqueta
&Scoped-define SELF-NAME br-etiquetas
&Scoped-define OPEN-QUERY-br-etiquetas RUN pi-soma. OPEN QUERY {&SELF-NAME} FOR EACH tt-etiqueta USE-INDEX sequencia.
&Scoped-define TABLES-IN-QUERY-br-etiquetas tt-etiqueta
&Scoped-define FIRST-TABLE-IN-QUERY-br-etiquetas tt-etiqueta


/* Definitions for BROWSE br-it-container                               */
&Scoped-define FIELDS-IN-QUERY-br-it-container tt-it-container.it-codigo fn-desc-item() @ c-desc-item tt-it-container.cod-refer tt-it-container.qt-pedida   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-it-container   
&Scoped-define SELF-NAME br-it-container
&Scoped-define QUERY-STRING-br-it-container FOR EACH tt-it-container NO-LOCK
&Scoped-define OPEN-QUERY-br-it-container OPEN QUERY br-it-container FOR EACH tt-it-container NO-LOCK.
&Scoped-define TABLES-IN-QUERY-br-it-container tt-it-container
&Scoped-define FIRST-TABLE-IN-QUERY-br-it-container tt-it-container


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-br-etiquetas}~
    ~{&OPEN-QUERY-br-it-container}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-12 RECT-5 rt-button bt-param ~
br-it-container br-etiquetas 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-copias fi-tot-qtde 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


/* ************************  Function Prototypes ********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD fn-desc-item w-consim 
FUNCTION fn-desc-item RETURNS CHARACTER
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
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
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.
DEFINE VARIABLE h_p-navega AS HANDLE NO-UNDO.
DEFINE VARIABLE h_q01pp001 AS HANDLE NO-UNDO.
DEFINE VARIABLE h_v03pp001 AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-all 
     IMAGE-UP FILE "image/im-ran_a.bmp":U
     LABEL "" 
     SIZE 4 BY 1.13 TOOLTIP "Seleciona TODAS".

DEFINE BUTTON bt-del 
     IMAGE-UP FILE "image/im-era.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-era.bmp":U
     LABEL "bt inclui 2" 
     SIZE 4 BY 1.13 TOOLTIP "Elimina Etiqueta".

DEFINE BUTTON bt-mod 
     IMAGE-UP FILE "image/im-mod.bmp":U
     IMAGE-INSENSITIVE FILE "image/ii-mod.bmp":U
     LABEL "bt inclui 2" 
     SIZE 4 BY 1.13 TOOLTIP "Modifica".

DEFINE BUTTON bt-out 
     IMAGE-UP FILE "image/im-nenhum.bmp":U
     LABEL "" 
     SIZE 4 BY 1.13 TOOLTIP "De SelecionaTODAS".

DEFINE BUTTON bt-param 
     IMAGE-UP FILE "image/im-fil.bmp":U
     LABEL "Button 1" 
     SIZE 4 BY 1.21.

DEFINE BUTTON bt-pck-list 
     IMAGE-UP FILE "image/entrada.bmp":U
     LABEL "" 
     SIZE 4 BY 1.21 TOOLTIP "Importa Packing List".

DEFINE BUTTON bt-pri 
     IMAGE-UP FILE "image/im-pri.bmp":U
     LABEL "" 
     SIZE 4 BY 1.13 TOOLTIP "Imprimir Etiquetas".

DEFINE BUTTON bt-sav 
     IMAGE-UP FILE "image/im-cq.bmp":U
     LABEL "" 
     SIZE 4 BY 1.21 TOOLTIP "Cria Etiquetas".

DEFINE VARIABLE fi-tot-copias AS INTEGER FORMAT ">>>>>>9":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 6 BY .88 NO-UNDO.

DEFINE VARIABLE fi-tot-qtde AS DECIMAL FORMAT ">>>,>>9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-12
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 24 BY 1.75
     BGCOLOR 8 .

DEFINE RECTANGLE RECT-5
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 6 BY 12.25
     BGCOLOR 8 .

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 88.57 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-etiquetas FOR 
      tt-etiqueta SCROLLING.

DEFINE QUERY br-it-container FOR 
      tt-it-container SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-etiquetas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-etiquetas w-consim _FREEFORM
  QUERY br-etiquetas DISPLAY
      tt-etiqueta.num-etiqueta   COLUMN-LABEL "Etiqueta" WIDTH 10
   tt-etiqueta.num-rolo-imp   COLUMN-LABEL "Rolo Imp" 
   tt-etiqueta.quantidade        COLUMN-LABEL "Qtde" FORMAT '>>9.99' WIDTH 5
ENABLE 
   tt-etiqueta.num-rolo-imp 
   tt-etiqueta.quantidade
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS MULTIPLE SIZE 24 BY 10.42
         FONT 1
         TITLE "Etiquetas de um Item" ROW-HEIGHT-CHARS .71.

DEFINE BROWSE br-it-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-it-container w-consim _FREEFORM
  QUERY br-it-container NO-LOCK DISPLAY
      tt-it-container.it-codigo FORMAT "x(8)"  WIDTH 7
 fn-desc-item() @ c-desc-item   FORMAT "x(25)" WIDTH 26
 tt-it-container.cod-refer      
 tt-it-container.qt-pedida
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 57 BY 12.33
         FONT 1
         TITLE "Itens do Container" ROW-HEIGHT-CHARS .58.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     bt-param AT ROW 1.33 COL 39
     br-it-container AT ROW 5.42 COL 2
     br-etiquetas AT ROW 5.5 COL 60
     bt-pck-list AT ROW 5.75 COL 85 WIDGET-ID 2
     bt-mod AT ROW 7 COL 85
     bt-del AT ROW 8.25 COL 85
     bt-sav AT ROW 11.33 COL 85
     bt-all AT ROW 13.83 COL 85
     bt-out AT ROW 15.08 COL 85
     bt-pri AT ROW 16.33 COL 85
     fi-tot-copias AT ROW 16.71 COL 61.29 COLON-ALIGNED NO-LABEL
     fi-tot-qtde AT ROW 16.71 COL 71 COLON-ALIGNED NO-LABEL
     "Total Metros" VIEW-AS TEXT
          SIZE 10 BY .54 AT ROW 16.13 COL 73
          BGCOLOR 8 
     "Qt Etiquetas" VIEW-AS TEXT
          SIZE 9 BY .54 AT ROW 16.13 COL 61
          BGCOLOR 8 
     RECT-12 AT ROW 16 COL 59.86
     RECT-5 AT ROW 5.5 COL 84
     rt-button AT ROW 1.21 COL 1.57
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 90 BY 17.08
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
         TITLE              = "Gera Etiquetas no Recebimento - ESPP003.W"
         HEIGHT             = 17.08
         WIDTH              = 90
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
   FRAME-NAME L-To-R                                                    */
/* BROWSE-TAB br-it-container bt-param f-cad */
/* BROWSE-TAB br-etiquetas br-it-container f-cad */
/* SETTINGS FOR BUTTON bt-all IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-del IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-mod IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-out IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-pck-list IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-pri IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-sav IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-copias IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtde IN FRAME f-cad
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-consim)
THEN w-consim:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-etiquetas
/* Query rebuild information for BROWSE br-etiquetas
     _START_FREEFORM
RUN pi-soma.
OPEN QUERY {&SELF-NAME} FOR EACH tt-etiqueta USE-INDEX sequencia.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-etiquetas */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-it-container
/* Query rebuild information for BROWSE br-it-container
     _START_FREEFORM
OPEN QUERY br-it-container FOR EACH tt-it-container NO-LOCK.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-it-container */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-consim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-consim w-consim
ON END-ERROR OF w-consim /* Gera Etiquetas no Recebimento - ESPP003.W */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-consim w-consim
ON WINDOW-CLOSE OF w-consim /* Gera Etiquetas no Recebimento - ESPP003.W */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-etiquetas
&Scoped-define SELF-NAME br-etiquetas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-etiquetas w-consim
ON ROW-ENTRY OF br-etiquetas IN FRAME f-cad /* Etiquetas de um Item */
DO:
   IF AVAIL tt-etiqueta AND
      tt-etiqueta.situacao >= 2 THEN DO.
      APPLY 'END-ERROR' TO br-etiquetas.
      RETURN NO-APPLY.
   END.
   
   IF br-etiquetas:NEW-ROW IN FRAME {&FRAME-NAME} THEN DO.
      ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-sav:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
   END.
   APPLY "entry":U TO tt-etiqueta.num-rolo-imp IN BROWSE br-etiquetas. 
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-etiquetas w-consim
ON VALUE-CHANGED OF br-etiquetas IN FRAME f-cad /* Etiquetas de um Item */
DO:
   ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = NO
          bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

   IF AVAIL tt-etiqueta THEN DO.
      ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = YES
             bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = YES
             bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = YES
             bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = YES
             bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = YES
             bt-sav:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
     
      IF tt-etiqueta.situacao >= 2 THEN
         ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-it-container
&Scoped-define SELF-NAME br-it-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-it-container w-consim
ON VALUE-CHANGED OF br-it-container IN FRAME f-cad /* Itens do Container */
DO:
   ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = YES
          bt-sav:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

   FIND FIRST item WHERE
              item.it-codigo = tt-it-container.it-codigo NO-LOCK NO-ERROR.

   IF NOT AVAIL item THEN
      ASSIGN bt-inc:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = NO
             bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

   EMPTY TEMP-TABLE tt-etiqueta.
   FOR EACH bc-etiqueta WHERE 
            bc-etiqueta.num-pedido = tt-it-container.nr-container AND
            bc-etiqueta.it-codigo = tt-it-container.it-codigo AND
            bc-etiqueta.referencia = tt-it-container.cod-refer AND
            bc-etiqueta.lote = tt-it-container.cod-refer
            NO-LOCK.

       CREATE tt-etiqueta.
       BUFFER-COPY bc-etiqueta TO tt-etiqueta
            ASSIGN tt-etiqueta.qt-copias = 1.
   END.
   {&OPEN-QUERY-br-etiquetas}

   APPLY 'value-changed' TO br-etiquetas.
   APPLY 'entry' TO bt-inc.
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-all
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-all w-consim
ON CHOOSE OF bt-all IN FRAME f-cad
DO:
   br-etiquetas:SELECT-ALL().
   ASSIGN bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = YES.

   FIND FIRST tt-etiqueta WHERE
              tt-etiqueta.cod-estado >= 2 NO-LOCK NO-ERROR.

   IF AVAIL tt-etiqueta THEN DO.
      MESSAGE 'No Intervalo Selecionado, existem Etiquetas j† Impressas...' SKIP(1)
              'Deseja Re-imprimir essas Etiquetas ?'
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
            TITLE "" UPDATE l-choice AS LOGICAL.
      ASSIGN l-reimp-etq = l-choice.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-all w-consim
ON RETURN OF bt-all IN FRAME f-cad
DO:
  APPLY 'choose' TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-del
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-del w-consim
ON CHOOSE OF bt-del IN FRAME f-cad /* bt inclui 2 */
DO:
   DO i-row = 1 TO br-etiquetas:NUM-SELECTED-ROWS.
      IF br-etiquetas:FETCH-SELECTED-ROW(i-row) THEN DO.

         DELETE tt-etiqueta.
         IF br-etiquetas:DELETE-CURRENT-ROW() IN FRAME {&FRAME-NAME} THEN. 

         ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = NO
                bt-sav:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
        
         IF CAN-FIND(FIRST tt-etiqueta) THEN 
            ASSIGN bt-mod:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                   bt-del:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                   bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                   bt-all:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                   bt-out:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                   bt-sav:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
        
         RUN pi-soma.
      END.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-mod
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-mod w-consim
ON CHOOSE OF bt-mod IN FRAME f-cad /* bt inclui 2 */
DO:
   APPLY "entry":U TO tt-etiqueta.qt-item IN BROWSE br-etiquetas. 
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-out
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-out w-consim
ON CHOOSE OF bt-out IN FRAME f-cad
DO:
   br-etiquetas:DESELECT-ROWS().
   ASSIGN bt-pri:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-out w-consim
ON RETURN OF bt-out IN FRAME f-cad
DO:
  APPLY 'choose' TO SELF.
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


&Scoped-define SELF-NAME bt-pck-list
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-pck-list w-consim
ON CHOOSE OF bt-pck-list IN FRAME f-cad
DO:
   EMPTY TEMP-TABLE tt-etq.
   FOR EACH tt-etiqueta.
       CREATE tt-etq.
       ASSIGN tt-etq.num-rolo-imp = tt-etiqueta.num-rolo-imp
              tt-etq.quantidade = tt-etiqueta.qt-item.
   END.

   RUN esp/espp003b.p (INPUT-OUTPUT TABLE tt-etq).
   FIND FIRST tt-etq NO-LOCK NO-ERROR.
   IF NOT AVAIL tt-etq THEN RETURN NO-APPLY.

   FOR EACH tt-etq.
       FIND tt-etiqueta WHERE 
            tt-etiqueta.num-rolo-imp = tt-etq.num-rolo-imp NO-LOCK NO-ERROR.
       IF NOT AVAIL tt-etiqueta THEN DO.
          CREATE tt-etiqueta.
          ASSIGN tt-etiqueta.num-pedido = tt-it-container.nr-container
                 tt-etiqueta.cod-estabel = tt-it-container.cod-estabel.
    
          ASSIGN tt-etiqueta.num-rolo-imp = tt-etq.num-rolo-imp
                 tt-etiqueta.qt-item = tt-etq.quantidade.
       END.
   END.

   FOR EACH tt-etiqueta.
       FIND tt-etq WHERE 
            tt-etq.num-rolo-imp = tt-etiqueta.num-rolo-imp NO-LOCK NO-ERROR.
       IF NOT AVAIL tt-etiqueta THEN
          DELETE tt-etiqueta.
   END.
   {&OPEN-QUERY-br-etiquetas}

   RUN pi-soma.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-pri
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-pri w-consim
ON CHOOSE OF bt-pri IN FRAME f-cad
DO:
   SESSION:SET-WAIT-STATE("general").

   DO i-row = 1 TO br-etiquetas:NUM-SELECTED-ROWS.
      IF br-etiquetas:FETCH-SELECTED-ROW(i-row) THEN DO.
         IF (tt-etiqueta.cod-estado >= 2 AND l-reimp-etq = NO) THEN NEXT.

         FIND bc-etiqueta WHERE
              bc-etiqueta.progressivo = tt-etiqueta.progressivo 
              USE-INDEX ch-progressivo NO-ERROR.

         IF NOT AVAIL bc-etiqueta THEN NEXT.

         FOR EACH tt-erro:
             DELETE tt-erro.
         END.
          
         RUN bcp/bcx2000.p (INPUT ROWID(bc-etiqueta),
                            INPUT "IMA0001Q",
                            INPUT-OUTPUT TABLE tt-erro).
          
         FIND FIRST tt-erro NO-LOCK NO-ERROR.
         IF AVAIL tt-erro THEN DO:
            MESSAGE 'Ocorreram erros na impress∆o da etiqueta.' SKIP
                    'Verifique os erros antes de imprimir.' SKIP
                    tt-erro.cd-erro ' - ' tt-erro.mensagem '.' VIEW-AS ALERT-BOX ERROR TITLE "Erro".
            RETURN NO-APPLY.
         END.
         ELSE
            IF tt-etiqueta.cod-estado = 1 THEN
               ASSIGN bc-etiqueta.cod-estado = 2.
      END.
   END.
   SESSION:SET-WAIT-STATE("").

   APPLY 'VALUE-CHANGED' TO br-it-container.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-sav
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-sav w-consim
ON CHOOSE OF bt-sav IN FRAME f-cad
DO:
    IF pp-container.cod-depos = '' THEN DO.
       MESSAGE 'Dep¢sito de Descarga do Container, n∆o foi Informado' SKIP
               'Verifique programa espp001'
           VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
       RETURN NO-APPLY.
    END.

    IF INPUT FRAME {&FRAME-NAME} fi-tot-qtde > tt-it-container.qt-pedida THEN DO:
       MESSAGE "Metragem Total Ç Superior Ö Quantidade do Item..." SKIP(1) 
               "Confirma Efetivaá∆o?" UPDATE l-resp AS LOGICAL
                VIEW-AS ALERT-BOX ERROR BUTTONS YES-NO TITLE "Erro".
       IF NOT l-resp THEN 
          RETURN NO-APPLY.
    END.

    SESSION:SET-WAIT-STATE("general").




    FOR EACH tt-etiqueta WHERE
             tt-etiqueta.progressivo = '' NO-LOCK.
        FIND item WHERE
             item.it-codigo = tt-it-container.it-codigo NO-LOCK NO-ERROR.
        IF NOT AVAIL item THEN DO:
           MESSAGE "Item n∆o Cadastrado..." VIEW-AS ALERT-BOX ERROR TITLE "Erro".
           RETURN NO-APPLY.
        END.

        FIND ref-item WHERE
             ref-item.it-codigo = tt-it-container.it-codigo AND
             ref-item.cod-refer = tt-it-container.cod-refer NO-LOCK NO-ERROR.
        IF NOT AVAIL ref-item THEN DO:
           MESSAGE "A referància n∆o relacionada ao Item..." 
                    VIEW-AS ALERT-BOX ERROR TITLE "Erro".
           RETURN NO-APPLY.
        END.

        IF i-ep-codigo-usuario = '5' THEN
           ASSIGN c-cod-chave-param-ext = "MED0001Q".
        ELSE
           ASSIGN c-cod-chave-param-ext = "IMA0001Q".

        DO i-ct = 1 TO tt-etiqueta.qt-copias:
           FIND bc-param-ext WHERE
                bc-param-ext.cod-chave-param-ext    = c-cod-chave-param-ext AND
                bc-param-ext.cod-entidade-param-ext = 'bc-tipo-trans' AND
                bc-param-ext.cod-param-ext          = ("NR-SEQ-ETIQ" + "-" + TRIM(tt-it-container.cod-estabel))
                SHARE-LOCK NO-ERROR.
           IF AVAIL bc-param-ext THEN DO:
              ASSIGN i-etq = bc-param-ext.param-inteiro + 1
                     bc-param-ext.param-inteiro = i-etq.
              FIND CURRENT bc-param-ext NO-LOCK NO-ERROR.
           END.

           CREATE bc-etiqueta.
           ASSIGN bc-etiqueta.progressivo   = STRING(i-ep-codigo-usuario,"9") + TRIM(STRING(tt-it-container.cod-estabel,"x(03)")) + STRING(i-etq,"999999999")
                  bc-etiqueta.num-pedido    = tt-etiqueta.num-pedido
                  bc-etiqueta.cod-estabel   = tt-etiqueta.cod-estabel
                  bc-etiqueta.cod-estado    = 1
                  bc-etiqueta.cd-trans      = c-cod-chave-param-ext
                  bc-etiqueta.qt-un-1       = tt-etiqueta.qt-item
                  bc-etiqueta.qt-item       = tt-etiqueta.qt-item
                  bc-etiqueta.un            = ""
                  bc-etiqueta.nr-nota-fis   = ""
                  bc-etiqueta.dt-criacao    = TODAY
                  bc-etiqueta.hr-criacao    = STRING(TIME,"HH:MM:SS")
                  bc-etiqueta.usuar-criacao = c-seg-usuario
                  bc-etiqueta.it-codigo     = tt-it-container.it-codigo
                  bc-etiqueta.referencia    = tt-it-container.cod-refer
                  bc-etiqueta.lote          = tt-it-container.cod-refer
                  bc-etiqueta.cod-layout    = 1
                  bc-etiqueta.num-versao    = 1
                  bc-etiqueta.log-datasul   = NO
                  bc-etiqueta.int-2         = tt-etiqueta.int-2.


           /* Cria Etiqueta Nova Logistica */
           FIND ITEM WHERE
                ITEM.it-codigo = bc-etiqueta.it-codigo NO-LOCK NO-ERROR.

           ASSIGN i-tp-embal = 1.

           FIND corte-comerc WHERE
                corte-comerc.compr-min <= bc-etiqueta.qt-item AND
                corte-comerc.compr-max >= bc-etiqueta.qt-item AND
                corte-comerc.tp-embalag = i-tp-embal AND 
                corte-comerc.un = item.un NO-LOCK NO-ERROR.

           ASSIGN c-cod-estab = bc-etiqueta.cod-estabel.
           FIND FIRST usuar-depos WHERE
                      usuar-depos.cod-depos = pp-container.cod-depos NO-LOCK NO-ERROR.
           IF AVAIL usuar-depos THEN
              ASSIGN c-cod-estab = usuar-depos.cod-estab.
            
            CREATE ob-etiqueta.
            ASSIGN ob-etiqueta.cod-estabel     = c-cod-estab
                   ob-etiqueta.dt-emissao      = TODAY
                   ob-etiqueta.hr-emissao      = STRING(TIME,"HH:MM")
                   ob-etiqueta.acondic         = ""
                   ob-etiqueta.it-codigo       = bc-etiqueta.it-codigo
                   ob-etiqueta.cod-refer       = bc-etiqueta.referencia
                   ob-etiqueta.nr-lote         = IF bc-etiqueta.lote = '888'
                                                 THEN 'RD' ELSE 'RP'
                   ob-etiqueta.cod-qualid      = IF bc-etiqueta.lote = '888'
                                                 THEN 'D' ELSE 'B'
                   ob-etiqueta.corte-comerc    = IF AVAIL corte-comerc
                                                 THEN corte-comerc.codigo
                                                 ELSE ''
                   ob-etiqueta.quantidade      = bc-etiqueta.qt-item
                   ob-etiqueta.localizacao     = ''
                   ob-etiqueta.situacao        = 3
                   ob-etiqueta.cod-depos       = pp-container.cod-depos
                   ob-etiqueta.num-etiqueta    = IF bc-etiqueta.cod-estabel = '1' 
                                                 THEN NEXT-VALUE(seq-etq-estoq-ima)
                                                 ELSE NEXT-VALUE(seq-etq-estoq-med)
                  ob-etiqueta.progressivo     = bc-etiqueta.progressivo
                  ob-etiqueta.nr-container    = tt-it-container.nr-container
                  ob-etiqueta.ob-origem       = STRING(tt-etiqueta.num-pedido).
        END.
    END.
    SESSION:SET-WAIT-STATE("").

    APPLY 'VALUE-CHANGED' TO br-it-container.
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


&Scoped-define BROWSE-NAME br-etiquetas
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-consim 


/* ***************************  Main Block  *************************** */
ON 'return':U OF br-etiquetas ANYWHERE DO:
   APPLY 'tab':U TO SELF.
   RETURN NO-APPLY.
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
             INPUT  'esvwr/v03pp001.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Layout = ':U ,
             OUTPUT h_v03pp001 ).
       RUN set-position IN h_v03pp001 ( 2.75 , 2.00 ) NO-ERROR.
       /* Size in UIB:  ( 2.50 , 88.00 ) */

       RUN init-object IN THIS-PROCEDURE (
             INPUT  'esqry/q01pp001.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'ProgPesquisa = eszoom/z01pp001.w,
                     ProgVaPara = esgo/g01pp001.w,
                     ProgIncMod = ,
                     Implantar = no':U ,
             OUTPUT h_q01pp001 ).
       RUN set-position IN h_q01pp001 ( 1.25 , 66.00 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 7.72 ) */

       /* Links to SmartViewer h_v03pp001. */
       RUN add-link IN adm-broker-hdl ( h_q01pp001 , 'Record':U , h_v03pp001 ).

       /* Links to SmartQuery h_q01pp001. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , h_q01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'Navigation':U , h_q01pp001 ).
       RUN add-link IN adm-broker-hdl ( h_p-navega , 'State':U , h_q01pp001 ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-navega ,
             bt-param:HANDLE IN FRAME f-cad , 'BEFORE':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             bt-param:HANDLE IN FRAME f-cad , 'AFTER':U ).
       RUN adjust-tab-order IN adm-broker-hdl ( h_v03pp001 ,
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
  DISPLAY fi-tot-copias fi-tot-qtde 
      WITH FRAME f-cad IN WINDOW w-consim.
  ENABLE RECT-12 RECT-5 rt-button bt-param br-it-container br-etiquetas 
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

  /*{utp/ut9000.i "espp003" "2.04.00.001"}*/

  ASSIGN i-sit-container = 1.

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.
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
    FIND pp-container WHERE 
         ROWID(pp-container) = p-row-container NO-LOCK NO-ERROR.

    EMPTY TEMP-TABLE tt-it-container.
    FOR EACH pp-it-container OF pp-container.
        CREATE tt-it-container.
        BUFFER-COPY pp-it-container TO tt-it-container
             ASSIGN tt-it-container.cod-estabel = pp-container.cod-estabel.
    END.
    {&OPEN-QUERY-br-it-container}
    
    APPLY 'value-changed' TO br-it-container IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-soma w-consim 
PROCEDURE pi-soma :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    ASSIGN fi-tot-copias = 0
           fi-tot-qtde = 0.
    FOR EACH bf-tt-etiqueta.
        ASSIGN fi-tot-copias = fi-tot-copias + bf-tt-etiqueta.qt-copias
               fi-tot-qtde = fi-tot-qtde + (bf-tt-etiqueta.qt-copias * bf-tt-etiqueta.qt-item).
    END.
    DISP fi-tot-copias
         fi-tot-qtde
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
  {src/adm/template/snd-list.i "tt-it-container"}
  {src/adm/template/snd-list.i "tt-etiqueta"}

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

  run pi-trata-state (p-issuer-hdl, p-state).
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

/* ************************  Function Implementations ***************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION fn-desc-item w-consim 
FUNCTION fn-desc-item RETURNS CHARACTER
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
  FIND FIRST item WHERE
             item.it-codigo = tt-it-container.it-codigo NO-LOCK NO-ERROR.

  IF AVAIL item THEN
     RETURN item.desc-item.   
  ELSE
     RETURN "N∆o Cadastrado".

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

