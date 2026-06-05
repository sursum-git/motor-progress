&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME w-relat
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-relat 
/*:T*******************************************************************************
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

/*:T Preprocessadores do Template de Relat¢rio                            */
/*:T Obs: Retirar o valor do preprocessador para as p†ginas que n∆o existirem  */

&GLOBAL-DEFINE PGSEL 
&GLOBAL-DEFINE PGCLA 
&GLOBAL-DEFINE PGPAR f-pg-par
&GLOBAL-DEFINE PGDIG f-pg-dig
&GLOBAL-DEFINE PGIMP f-pg-imp

&GLOBAL-DEFINE RTF   YES
  
/* Parameters Definitions ---                                           */

/* Temporary Table Definitions ---                                      */
DEFINE TEMP-TABLE tt-param NO-UNDO
    FIELD destino          AS INTEGER
    FIELD arquivo          AS CHAR format "x(35)"
    FIELD usuario          AS CHAR format "x(12)"
    FIELD data-exec        AS date
    FIELD hora-exec        AS INTEGER
    FIELD clASsifica       AS INTEGER
    FIELD desc-clASsifica  AS CHAR FORMAT  "x(40)"
    FIELD modelo-rtf       AS CHAR FORMAT  "x(35)"
    FIELD l-habilitaRtf    AS LOG
    FIELD i-nr-container   AS INT
    FIELD cod-estabel      AS CHAR
    FIELD it-codigo        AS CHAR
    FIELD preco            AS DEC.

define temp-table tt-digita no-undo
    FIELD ordem            AS INTEGER   FORMAT  ">>>>9"
    FIELD nr-pedcli        LIKE pp-ped-venda.nr-pedcli
    FIELD nome-abrev       LIKE ped-venda.nome-abrev
    FIELD it-codigo        LIKE pp-it-container.it-codigo
    FIELD tb-preco         LIKE ped-venda.nr-tabpre
    FIELD cond-pagto       LIKE ped-venda.cod-cond-pag
    FIELD vl-preuni        LIKE ped-item.vl-preuni
    FIELD vl-novo          AS DEC
    FIELD l-status         AS LOG FORMAT "Sim/N∆o" INIT "Sim" LABEL "Status".
   
    




/*define temp-table tt-digita no-undo
    FIELD ordem            AS INTEGER   FORMAT  ">>>>9"
    FIELD it-comprado      LIKE pp-it-container.it-comprado
    FIELD ref-comprada     LIKE pp-it-container.ref-comprada
    FIELD it-codigo        LIKE pp-it-container.it-codigo
    FIELD cod-refer        LIKE pp-it-container.cod-refer
    index id ordem.*/

define buffer b-tt-digita for tt-digita.

/* Transfer Definitions */

def var raw-param        as raw no-undo.

def temp-table tt-raw-digita
   field raw-digita      as raw.
                    
/* Local Variable Definitions ---                                       */

def var l-ok               as logical no-undo.
def var c-arq-digita       as char    no-undo.
def var c-terminal         as char    no-undo.
def var c-rtf              as char    no-undo.
def var c-modelo-default   as char    no-undo.
DEF VAR c-item AS CHAR NO-UNDO.
DEF VAR c-lista AS CHAR.
DEF VAR d-vr-novo AS DEC.
/*15/02/2005 - tech1007 - Variavel definida para tratar se o programa est† rodando no WebEnabler*/
DEFINE SHARED VARIABLE hWenController AS HANDLE NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-relat
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-pg-dig
&Scoped-define BROWSE-NAME br-digita

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-digita

/* Definitions for BROWSE br-digita                                     */
&Scoped-define FIELDS-IN-QUERY-br-digita tt-digita.it-codigo tt-digita.nr-pedcli tt-digita.nome-abrev tt-digita.tb-preco tt-digita.cond-pagto tt-digita.vl-preuni tt-digita.vl-novo tt-digita.l-status   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-digita tt-digita.tb-preco   tt-digita.vl-novo   tt-digita.l-status   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-digita tt-digita
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-digita tt-digita
&Scoped-define SELF-NAME br-digita
&Scoped-define QUERY-STRING-br-digita FOR EACH tt-digita
&Scoped-define OPEN-QUERY-br-digita OPEN QUERY br-digita FOR EACH tt-digita.
&Scoped-define TABLES-IN-QUERY-br-digita tt-digita
&Scoped-define FIRST-TABLE-IN-QUERY-br-digita tt-digita


/* Definitions for FRAME f-pg-dig                                       */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-pg-dig ~
    ~{&OPEN-QUERY-br-digita}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-digita bt-inserir bt-alterar 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-relat AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-alterar 
     LABEL "Alterar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-inserir 
     LABEL "Inserir" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-recuperar 
     LABEL "Recuperar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-retirar 
     LABEL "Retirar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-salvar 
     LABEL "Salvar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-arquivo 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-config-impr 
     IMAGE-UP FILE "image\im-cfprt":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-modelo-rtf 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE VARIABLE c-arquivo AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 256
     SIZE 40 BY .88
     BGCOLOR 15  NO-UNDO.

DEFINE VARIABLE c-modelo-rtf AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 256
     SIZE 40 BY .88
     BGCOLOR 15  NO-UNDO.

DEFINE VARIABLE text-destino AS CHARACTER FORMAT "X(256)":U INITIAL " Destino" 
      VIEW-AS TEXT 
     SIZE 8.57 BY .63 NO-UNDO.

DEFINE VARIABLE text-modelo-rtf AS CHARACTER FORMAT "X(256)":U INITIAL "Modelo:" 
      VIEW-AS TEXT 
     SIZE 10.86 BY .63 NO-UNDO.

DEFINE VARIABLE text-modo AS CHARACTER FORMAT "X(256)":U INITIAL "Execuá∆o" 
      VIEW-AS TEXT 
     SIZE 10.86 BY .63 NO-UNDO.

DEFINE VARIABLE text-rtf AS CHARACTER FORMAT "X(256)":U INITIAL "Rich Text Format(RTF)" 
      VIEW-AS TEXT 
     SIZE 20.86 BY .63 NO-UNDO.

DEFINE VARIABLE rs-destino AS INTEGER INITIAL 2 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Impressora", 1,
"Arquivo", 2,
"Terminal", 3
     SIZE 44 BY 1.08 NO-UNDO.

DEFINE VARIABLE rs-execucao AS INTEGER INITIAL 1 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "On-Line", 1,
"Batch", 2
     SIZE 27.72 BY .92 NO-UNDO.

DEFINE RECTANGLE RECT-7
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 2.79.

DEFINE RECTANGLE RECT-9
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 1.71.

DEFINE RECTANGLE rect-rtf
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 3.54.

DEFINE VARIABLE l-habilitaRtf AS LOGICAL INITIAL no 
     LABEL "RTF" 
     VIEW-AS TOGGLE-BOX
     SIZE 44 BY 1.08 NO-UNDO.

DEFINE BUTTON bt-processa 
     IMAGE-UP FILE "especificos/image/imt-pedidos.bmp":U
     IMAGE-INSENSITIVE FILE "especificos/image/ii-pedidos.bmp":U
     LABEL "Itens" 
     SIZE 15 BY 1 TOOLTIP "Seleciona Pedidos desse item do Container" DROP-TARGET.

DEFINE VARIABLE cb-item AS CHARACTER FORMAT "X(256)":U INITIAL "TODOS" 
     LABEL "Item" 
     VIEW-AS COMBO-BOX INNER-LINES 3
     DROP-DOWN-LIST
     SIZE 10 BY 1 NO-UNDO.

DEFINE VARIABLE fi-cod-estabel AS CHARACTER FORMAT "X(3)":U 
     LABEL "Estabelecimento" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-estab AS CHARACTER FORMAT "X(50)":U 
     VIEW-AS FILL-IN 
     SIZE 39.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-item AS CHARACTER FORMAT "X(50)":U 
     VIEW-AS FILL-IN 
     SIZE 38 BY .88 NO-UNDO.

DEFINE VARIABLE fi-nr-container AS INTEGER FORMAT ">>>,>>9":U INITIAL 0 
     LABEL "Container" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88 NO-UNDO.

DEFINE VARIABLE fi-preco AS DECIMAL FORMAT "-ZZ,ZZ9.99":U INITIAL 0 
     LABEL "Preáo" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88
     FONT 1 NO-UNDO.

DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Fechar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-executar 
     LABEL "Executar" 
     SIZE 10 BY 1.

DEFINE IMAGE im-pg-dig
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-imp
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-par
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 79 BY 1.42
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-6
     EDGE-PIXELS 0    
     SIZE 78.72 BY .13
     BGCOLOR 7 .

DEFINE RECTANGLE rt-folder
     EDGE-PIXELS 1 GRAPHIC-EDGE  NO-FILL   
     SIZE 79 BY 11.38
     FGCOLOR 0 .

DEFINE RECTANGLE rt-folder-left
     EDGE-PIXELS 0    
     SIZE .43 BY 11.21
     BGCOLOR 15 .

DEFINE RECTANGLE rt-folder-right
     EDGE-PIXELS 0    
     SIZE .43 BY 11.17
     BGCOLOR 7 .

DEFINE RECTANGLE rt-folder-top
     EDGE-PIXELS 0    
     SIZE 78.72 BY .13
     BGCOLOR 15 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-digita FOR 
      tt-digita SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-digita w-relat _FREEFORM
  QUERY br-digita DISPLAY
      tt-digita.it-codigo WIDTH 10
tt-digita.nr-pedcli      
tt-digita.nome-abrev
tt-digita.tb-preco
tt-digita.cond-pagto 
tt-digita.vl-preuni COLUMN-LABEL "VR atual" WIDTH 8
tt-digita.vl-novo   COLUMN-LABEL "VR Novo" WIDTH 7
tt-digita.l-status
ENABLE
    tt-digita.tb-preco
    tt-digita.vl-novo
    tt-digita.l-status
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH SEPARATORS SIZE 76.57 BY 9
         BGCOLOR 15 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-pg-imp
     rs-destino AT ROW 1.63 COL 3.29 HELP
          "Destino de Impress∆o do Relat¢rio" NO-LABEL
     bt-config-impr AT ROW 2.71 COL 43.29 HELP
          "Configuraá∆o da impressora"
     bt-arquivo AT ROW 2.71 COL 43.29 HELP
          "Escolha do nome do arquivo"
     c-arquivo AT ROW 2.75 COL 3.29 HELP
          "Nome do arquivo de destino do relat¢rio" NO-LABEL
     l-habilitaRtf AT ROW 4.83 COL 3.29
     c-modelo-rtf AT ROW 6.63 COL 3 HELP
          "Nome do arquivo de modelo do relat¢rio" NO-LABEL
     bt-modelo-rtf AT ROW 6.63 COL 43 HELP
          "Escolha do nome do arquivo"
     rs-execucao AT ROW 8.88 COL 2.86 HELP
          "Modo de Execuá∆o" NO-LABEL
     text-destino AT ROW 1.04 COL 3.86 NO-LABEL
     text-rtf AT ROW 4.17 COL 1.14 COLON-ALIGNED NO-LABEL
     text-modelo-rtf AT ROW 5.96 COL 1.14 COLON-ALIGNED NO-LABEL
     text-modo AT ROW 8.13 COL 1.14 COLON-ALIGNED NO-LABEL
     RECT-7 AT ROW 1.33 COL 2.14
     RECT-9 AT ROW 8.33 COL 2
     rect-rtf AT ROW 4.46 COL 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 73.72 BY 10.5.

DEFINE FRAME f-relat
     bt-executar AT ROW 14.54 COL 3 HELP
          "Dispara a execuá∆o do relat¢rio"
     bt-cancelar AT ROW 14.54 COL 14 HELP
          "Fechar"
     bt-ajuda AT ROW 14.54 COL 70 HELP
          "Ajuda"
     rt-folder-top AT ROW 2.54 COL 2.14
     rt-folder-left AT ROW 2.54 COL 2.14
     RECT-1 AT ROW 14.29 COL 2
     RECT-6 AT ROW 13.75 COL 2.14
     rt-folder AT ROW 2.5 COL 2
     rt-folder-right AT ROW 2.67 COL 80.43
     im-pg-dig AT ROW 1.5 COL 17.72
     im-pg-imp AT ROW 1.5 COL 33.43
     im-pg-par AT ROW 1.5 COL 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 80.72 BY 14.75
         DEFAULT-BUTTON bt-executar.

DEFINE FRAME f-pg-dig
     br-digita AT ROW 1 COL 1
     bt-inserir AT ROW 10 COL 1
     bt-alterar AT ROW 10 COL 16
     bt-retirar AT ROW 10 COL 31
     bt-salvar AT ROW 10 COL 46
     bt-recuperar AT ROW 10 COL 61
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3.31
         SIZE 76.86 BY 10.15.

DEFINE FRAME f-pg-par
     fi-cod-estabel AT ROW 1.5 COL 17 COLON-ALIGNED
     fi-desc-estab AT ROW 1.5 COL 27 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-nr-container AT ROW 2.5 COL 17 COLON-ALIGNED
     cb-item AT ROW 3.5 COL 17 COLON-ALIGNED
     fi-desc-item AT ROW 3.5 COL 27 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-preco AT ROW 4.38 COL 17 COLON-ALIGNED
     bt-processa AT ROW 5.25 COL 19
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 77.57 BY 10.79
         FONT 1.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-relat
   Allow: Basic,Browse,DB-Fields,Window,Query
   Add Fields to: Neither
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-relat ASSIGN
         HIDDEN             = YES
         TITLE              = "Substituiá∆o de Preáo por Item"
         HEIGHT             = 14.92
         WIDTH              = 80.72
         MAX-HEIGHT         = 22.33
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 22.33
         VIRTUAL-WIDTH      = 114.29
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-relat 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-relat.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-relat
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-pg-dig
   FRAME-NAME Custom                                                    */
/* BROWSE-TAB br-digita 1 f-pg-dig */
/* SETTINGS FOR BUTTON bt-recuperar IN FRAME f-pg-dig
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-retirar IN FRAME f-pg-dig
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-salvar IN FRAME f-pg-dig
   NO-ENABLE                                                            */
/* SETTINGS FOR FRAME f-pg-imp
                                                                        */
/* SETTINGS FOR EDITOR c-modelo-rtf IN FRAME f-pg-imp
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN text-destino IN FRAME f-pg-imp
   NO-DISPLAY NO-ENABLE ALIGN-L                                         */
ASSIGN 
       text-destino:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Destino".

ASSIGN 
       text-modelo-rtf:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Modelo:".

/* SETTINGS FOR FILL-IN text-modo IN FRAME f-pg-imp
   NO-DISPLAY NO-ENABLE                                                 */
ASSIGN 
       text-modo:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Execuá∆o".

ASSIGN 
       text-rtf:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Rich Text Format(RTF)".

/* SETTINGS FOR FRAME f-pg-par
                                                                        */
/* SETTINGS FOR BUTTON bt-processa IN FRAME f-pg-par
   NO-ENABLE                                                            */
ASSIGN 
       fi-desc-estab:READ-ONLY IN FRAME f-pg-par        = TRUE.

ASSIGN 
       fi-desc-item:READ-ONLY IN FRAME f-pg-par        = TRUE.

/* SETTINGS FOR FRAME f-relat
                                                                        */
/* SETTINGS FOR RECTANGLE RECT-1 IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE RECT-6 IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-left IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-right IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-top IN FRAME f-relat
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-relat)
THEN w-relat:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-digita
/* Query rebuild information for BROWSE br-digita
     _START_FREEFORM
OPEN QUERY br-digita FOR EACH tt-digita.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-digita */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-imp
/* Query rebuild information for FRAME f-pg-imp
     _Query            is NOT OPENED
*/  /* FRAME f-pg-imp */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-relat
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-relat w-relat
ON END-ERROR OF w-relat /* Substituiá∆o de Preáo por Item */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-relat w-relat
ON WINDOW-CLOSE OF w-relat /* Substituiá∆o de Preáo por Item */
DO:
  /* This event will close the window and terminate the procedure.  */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-digita
&Scoped-define SELF-NAME br-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON DEL OF br-digita IN FRAME f-pg-dig
DO:
   apply 'choose':U to bt-retirar in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON END-ERROR OF br-digita IN FRAME f-pg-dig
ANYWHERE 
DO:
    if  br-digita:new-row in frame f-pg-dig then do:
        if  avail tt-digita then
            delete tt-digita.
        if  br-digita:delete-current-row() in frame f-pg-dig then. 
    end.                                                               
    else do:
        get current br-digita.
        DISPLAY tt-digita.nr-pedcli      
                tt-digita.nome-abrev
                tt-digita.l-status
                with browse br-digita. 
    end.
    return no-apply.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON ENTER OF br-digita IN FRAME f-pg-dig
ANYWHERE
DO:
  apply 'tab':U to self.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON INS OF br-digita IN FRAME f-pg-dig
DO:
   apply 'choose':U to bt-inserir in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON OFF-END OF br-digita IN FRAME f-pg-dig
DO:
   apply 'entry':U to bt-inserir in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON OFF-HOME OF br-digita IN FRAME f-pg-dig
DO:
  apply 'entry':U to bt-recuperar in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita w-relat
ON ROW-LEAVE OF br-digita IN FRAME f-pg-dig
DO:
    /*:T ê aqui que a gravaá∆o da linha da temp-table Ç efetivada.
       PorÇm as validaá‰es dos registros devem ser feitas na procedure pi-executar,
       no local indicado pelo coment†rio */
    
    if br-digita:NEW-ROW in frame f-pg-dig then 
    do transaction on error undo, return no-apply:
        create tt-digita.
        assign input browse br-digita tt-digita.nr-pedcli      
               input browse br-digita tt-digita.nome-abrev     
               input browse br-digita tt-digita.l-status.
            br-digita:CREATE-RESULT-LIST-ENTRY() in frame f-pg-dig.
    end.
    else do transaction on error undo, return no-apply:
        assign input browse br-digita tt-digita.nr-pedcli      
               input browse br-digita tt-digita.nome-abrev     
               input browse br-digita tt-digita.l-status.      
               
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-relat
ON CHOOSE OF bt-ajuda IN FRAME f-relat /* Ajuda */
DO:
   {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-dig
&Scoped-define SELF-NAME bt-alterar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-alterar w-relat
ON CHOOSE OF bt-alterar IN FRAME f-pg-dig /* Alterar */
DO:
    ASSIGN bt-retirar:SENSITIVE IN FRAME f-pg-dig = YES.

   {&OPEN-QUERY-br-digita}

   apply "entry":U to tt-digita.tb-preco in browse br-digita. 
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME bt-arquivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-arquivo w-relat
ON CHOOSE OF bt-arquivo IN FRAME f-pg-imp
DO:
    {include/i-rparq.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-relat
ON CHOOSE OF bt-cancelar IN FRAME f-relat /* Fechar */
DO:
   apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME bt-config-impr
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-config-impr w-relat
ON CHOOSE OF bt-config-impr IN FRAME f-pg-imp
DO:
   {include/i-rpimp.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME bt-executar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-executar w-relat
ON CHOOSE OF bt-executar IN FRAME f-relat /* Executar */
DO:
     
  IF NUM-RESULTS("br-digita":u) > 0 THEN  DO:
       do  on error undo, return no-apply:
       run pi-executar.
       end.
  END.
  ELSE
      MESSAGE "N∆o h† dados para serem alterados.."
      VIEW-AS ALERT-BOX INFO BUTTONS OK.
      APPLY 'entry' TO fi-cod-estabel IN FRAME f-pg-par.
      RETURN NO-APPLY.
    
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME bt-modelo-rtf
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-modelo-rtf w-relat
ON CHOOSE OF bt-modelo-rtf IN FRAME f-pg-imp
DO:
    def var c-arq-conv  as char no-undo.
    def var l-ok as logical no-undo.

    assign c-modelo-rtf = replace(input frame {&frame-name} c-modelo-rtf, "/", "\").
    SYSTEM-DIALOG GET-FILE c-arq-conv
       FILTERS "*.rtf" "*.rtf",
               "*.*" "*.*"
       DEFAULT-EXTENSION "rtf"
       INITIAL-DIR "modelos" 
       MUST-EXIST
       USE-FILENAME
       UPDATE l-ok.
    if  l-ok = yes then
        assign c-modelo-rtf:screen-value in frame {&frame-name}  = replace(c-arq-conv, "\", "/"). 

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME bt-processa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-processa w-relat
ON CHOOSE OF bt-processa IN FRAME f-pg-par /* Itens */
DO:
  FOR EACH tt-digita:
      DELETE tt-digita.
  END. 
  
  FOR EACH pp-ped-venda WHERE
           pp-ped-venda.cod-estabel  = fi-cod-estabel:SCREEN-VALUE IN FRAME f-pg-par AND
           pp-ped-venda.nr-container = INPUT FRAME f-pg-par fi-nr-container.
      IF cb-item:SCREEN-VALUE <> "Todos" THEN DO:
         FOR EACH pp-ped-item WHERE 
           pp-ped-item.nr-pedcli = pp-ped-venda.nr-pedcli AND 
           pp-ped-item.it-codigo = cb-item:SCREEN-VALUE IN FRAME f-pg-par
           BREAK BY pp-ped-item.it-codigo.
             IF LAST-OF(pp-ped-item.it-codigo) THEN DO:
                CREATE tt-digita.
                ASSIGN tt-digita.nr-pedcli  = pp-ped-venda.nr-pedcli
                       tt-digita.nome-abrev = pp-ped-venda.nome-abrev
                       tt-digita.tb-preco   = pp-ped-venda.nr-tabpre
                       tt-digita.cond-pagto = pp-ped-venda.cod-cond-pag
                       tt-digita.it-codigo  = pp-ped-item.it-codigo
                       tt-digita.vl-preuni  = pp-ped-item.vl-preuni.
                IF pp-ped-venda.tp-preco <> 1 THEN DO:
                   FIND FIRST  preco-item WHERE 
                               preco-item.nr-tabpre = pp-ped-venda.nr-tabpre AND
                               preco-item.it-codigo = pp-ped-item.it-codigo
                               NO-LOCK NO-ERROR.
                   IF AVAIL preco-item THEN DO:
                      FIND cond-pagto  WHERE 
                           cond-pagto.cod-cond-pag = pp-ped-venda.cod-cond-pag 
                           NO-LOCK NO-ERROR.
                      FIND tab-finan WHERE
                           tab-finan.nr-tab-finan = cond-pagto.nr-tab-finan 
                           NO-LOCK NO-ERROR.
                      IF AVAIL tab-finan THEN DO:
                         ASSIGN tt-digita.vl-novo    = preco-item.preco-venda * tab-finan.tab-ind-fin[cond-pagto.nr-ind-finan].
                      END.
                   END.
                END.
                ELSE DO:
                   ASSIGN tt-digita.vl-novo = INPUT FRAME f-pg-par fi-preco.
                END.
                
             END.
         END.
      END.
      ELSE DO:
         FOR EACH pp-ped-item WHERE 
           pp-ped-item.nr-pedcli = pp-ped-venda.nr-pedcli 
           BREAK BY pp-ped-item.it-codigo.
             IF LAST-OF(pp-ped-item.it-codigo) THEN DO:
                
                CREATE tt-digita.
                ASSIGN tt-digita.nr-pedcli  = pp-ped-venda.nr-pedcli
                       tt-digita.nome-abrev = pp-ped-venda.nome-abrev
                       tt-digita.tb-preco   = pp-ped-venda.nr-tabpre
                       tt-digita.cond-pagto = pp-ped-venda.cod-cond-pag
                       tt-digita.it-codigo  = pp-ped-item.it-codigo
                       tt-digita.vl-preuni  = pp-ped-item.vl-preuni.
                IF pp-ped-venda.tp-preco <> 1 THEN DO:
                   FIND FIRST  preco-item WHERE 
                               preco-item.nr-tabpre = pp-ped-venda.nr-tabpre AND
                               preco-item.it-codigo = pp-ped-item.it-codigo
                               NO-LOCK NO-ERROR.
                   IF AVAIL preco-item THEN DO:
                      FIND cond-pagto  WHERE 
                           cond-pagto.cod-cond-pag = pp-ped-venda.cod-cond-pag 
                           NO-LOCK NO-ERROR.
                      FIND tab-finan WHERE
                           tab-finan.nr-tab-finan = cond-pagto.nr-tab-finan
                           NO-LOCK NO-ERROR.
                      IF AVAIL tab-finan THEN
                         ASSIGN tt-digita.vl-novo    = preco-item.preco-venda * tab-finan.tab-ind-fin[cond-pagto.nr-ind-finan].
                   END.
                END.
                ELSE DO:
                 ASSIGN tt-digita.vl-novo = pp-ped-item.vl-preuni.
                END.
             END.
         END.
      END.
  END.
  {&OPEN-QUERY-br-digita}

  /*FOR EACH pp-ped-venda WHERE 
           pp-ped-venda.cod-estabel  = fi-cod-estabel:SCREEN-VALUE IN FRAME f-pg-par AND
           pp-ped-venda.nr-container = fi-nr-container:SCREEN-VALUE IN FRAME f-pg-par AND
           pp-ped-venda.it-comprado  = fi-it-codigo:SCREEN-VALUE IN FRAME f-pg-par.
  END.
 FIND pp-container WHERE 
       pp-container.nr-container = INPUT FRAME f-pg-par fi-nr-container
       NO-LOCK NO-ERROR.
  IF AVAIL pp-container THEN DO:
     FOR EACH pp-it-container WHERE
              pp-it-container.nr-container = pp-container.nr-container NO-LOCK.
         FIND ref-item WHERE
              ref-item.it-codigo = pp-it-container.it-codigo AND 
              ref-item.cod-refer = pp-it-container.cod-refer NO-LOCK NO-ERROR.
         IF NOT AVAIL ref-item THEN DO:
            CREATE tt-digita.
            ASSIGN tt-digita.it-comprado  = pp-it-container.it-comprado
                   tt-digita.ref-comprada = pp-it-container.ref-comprada.
            FIND ITEM WHERE
                 ITEM.it-codigo = pp-it-container.it-codigo NO-LOCK NO-ERROR.
            IF AVAIL ITEM THEN
               ASSIGN tt-digita.it-codigo = pp-it-container.it-codigo.
         END.
     END.
  END.*/
  APPLY 'MOUSE-SELECT-CLICK' TO im-pg-dig IN FRAME f-relat.
  APPLY 'choose' TO bt-alterar IN FRAME f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-dig
&Scoped-define SELF-NAME bt-recuperar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-recuperar w-relat
ON CHOOSE OF bt-recuperar IN FRAME f-pg-dig /* Recuperar */
DO:
    {include/i-rprcd.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-retirar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-retirar w-relat
ON CHOOSE OF bt-retirar IN FRAME f-pg-dig /* Retirar */
DO:
    if  br-digita:num-selected-rows > 0 then do on error undo, return no-apply:
        get current br-digita.
        delete tt-digita.
        if  br-digita:delete-current-row() in frame f-pg-dig then.
    end.
    
    if num-results("br-digita":U) = 0 then
        assign bt-alterar:SENSITIVE in frame f-pg-dig = no
               bt-retirar:SENSITIVE in frame f-pg-dig = no
               bt-salvar:SENSITIVE in frame f-pg-dig  = no.

    {&OPEN-QUERY-br-digita}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-salvar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-salvar w-relat
ON CHOOSE OF bt-salvar IN FRAME f-pg-dig /* Salvar */
DO:
   {include/i-rpsvd.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME cb-item
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL cb-item w-relat
ON VALUE-CHANGED OF cb-item IN FRAME f-pg-par /* Item */
DO:
   IF INPUT FRAME f-pg-par cb-item <> "TODOS" THEN DO:
      FIND FIRST pp-it-container WHERE
                  pp-it-container.nr-container =  INPUT FRAME f-pg-par fi-nr-container AND
                  pp-it-container.it-comprado  =  cb-item:SCREEN-VALUE IN FRAME f-pg-par 
                   NO-LOCK NO-ERROR.
        IF AVAIL pp-it-container THEN DO:
           ASSIGN fi-desc-item:SCREEN-VALUE IN FRAME f-pg-par = pp-it-container.desc-item
                  fi-preco:SCREEN-VALUE IN FRAME f-pg-par = STRING( pp-it-container.preco-venda)
                  bt-processa:SENSITIVE IN FRAME {&FRAME-NAME} = YES
                  fi-preco:SENSITIVE = YES.
        END.
        ELSE DO:
           ASSIGN fi-desc-item:SCREEN-VALUE IN FRAME f-pg-par = "Item n∆o encontrado para esse container..".
           APPLY 'entry' TO cb-item.
           RETURN NO-APPLY.
        END.
   END.
   ELSE DO:
        ASSIGN fi-desc-item:SCREEN-VALUE IN FRAME f-pg-par = "Todos os itens do Container"
               fi-preco:SENSITIVE = NO
               fi-preco:SCREEN-VALUE IN FRAME f-pg-par ="0"
               bt-processa:SENSITIVE IN FRAME {&FRAME-NAME} = YES. 

   END.
   
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-estabel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-estabel w-relat
ON LEAVE OF fi-cod-estabel IN FRAME f-pg-par /* Estabelecimento */
DO:
  IF fi-cod-estabel:SCREEN-VALUE IN FRAME {&FRAME-NAME} <> " " THEN DO:
     FIND estabelec WHERE 
          estabelec.cod-estabel = fi-cod-estabel:SCREEN-VALUE IN FRAME {&FRAME-NAME} NO-LOCK NO-ERROR.
     IF AVAIL estabelec THEN
        ASSIGN fi-desc-estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} = estabelec.nome.
     ELSE DO:
        ASSIGN fi-desc-estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "Estabelecimento n∆o cadastrado...".
        APPLY 'entry' TO fi-cod-estabel IN FRAME {&FRAME-NAME}.
        RETURN NO-APPLY.
     END.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-nr-container
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nr-container w-relat
ON ENTRY OF fi-nr-container IN FRAME f-pg-par /* Container */
DO:
    ASSIGN bt-processa:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nr-container w-relat
ON LEAVE OF fi-nr-container IN FRAME f-pg-par /* Container */
DO:
  FIND pp-container WHERE 
       pp-container.nr-container = INPUT FRAME {&FRAME-NAME} fi-nr-container AND 
       pp-container.cod-estabel  = fi-cod-estabel:SCREEN-VALUE IN FRAME {&FRAME-NAME}
       NO-LOCK NO-ERROR.
  IF AVAIL pp-container AND pp-container.situacao = 3 THEN DO:
     MESSAGE "Container j† fechado..."
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     APPLY 'entry' TO fi-nr-container IN FRAME {&FRAME-NAME}.
     RETURN NO-APPLY.
  END.
  IF NOT AVAIL pp-container THEN DO:
     MESSAGE "Container n∆o existe para esse estabelecimento..."
     VIEW-AS ALERT-BOX INFO BUTTONS OK.
     APPLY 'entry' TO fi-cod-estabel IN FRAME {&FRAME-NAME}.
     RETURN NO-APPLY.
  END.
 /* ASSIGN bt-processa:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
  APPLY 'entry' TO bt-processa.
  RETURN NO-APPLY.*/
 ASSIGN c-lista = "TODOS".
 FOR EACH pp-it-container WHERE 
          pp-it-container.nr-container = INPUT FRAME f-pg-par fi-nr-container NO-LOCK
          BREAK BY pp-it-container.it-comprado :
     IF LAST-OF(pp-it-container.it-comprado) THEN
        ASSIGN c-lista = c-lista + ',' + pp-it-container.it-comprado.
 END.
 ASSIGN cb-item:LIST-ITEMS = c-lista.
 ASSIGN cb-item:SCREEN-VALUE IN FRAME f-pg-par = "TODOS".

 ASSIGN fi-desc-item:SCREEN-VALUE IN FRAME f-pg-par = "Todos os itens do Container"
        fi-preco:SENSITIVE = NO
        fi-preco:SCREEN-VALUE IN FRAME f-pg-par ="0"
        bt-processa:SENSITIVE IN FRAME {&FRAME-NAME} = YES. 
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-nr-container w-relat
ON MOUSE-SELECT-DBLCLICK OF fi-nr-container IN FRAME f-pg-par /* Container */
DO:
  {include/zoomvar.i &prog-zoom=eszoom\z02pp001.w
                     &campo=fi-nr-container
                     &campozoom=nr-container}
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-preco
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-preco w-relat
ON MOUSE-SELECT-DBLCLICK OF fi-preco IN FRAME f-pg-par /* Preáo */
DO:
    /*RUN especificos\esp\espp002b.p (OUTPUT c-item,
                                    fi-cod-estabel:SCREEN-VALUE IN FRAME f-pg-par,
                                    INPUT FRAME f-pg-par fi-nr-container).
    ASSIGN fi-it-codigo:SCREEN-VALUE IN FRAME f-pg-par = c-item.*/
    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME im-pg-dig
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-dig w-relat
ON MOUSE-SELECT-CLICK OF im-pg-dig IN FRAME f-relat
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-imp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-imp w-relat
ON MOUSE-SELECT-CLICK OF im-pg-imp IN FRAME f-relat
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-par
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-par w-relat
ON MOUSE-SELECT-CLICK OF im-pg-par IN FRAME f-relat
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME l-habilitaRtf
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL l-habilitaRtf w-relat
ON VALUE-CHANGED OF l-habilitaRtf IN FRAME f-pg-imp /* RTF */
DO:
    &IF "{&RTF}":U = "YES":U &THEN
    RUN pi-habilitaRtf.
    &endif
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-destino
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-destino w-relat
ON VALUE-CHANGED OF rs-destino IN FRAME f-pg-imp
DO:
/*Alterado 15/02/2005 - tech1007 - Evento alterado para correto funcionamento dos novos widgets
  utilizados para a funcionalidade de RTF*/
do  with frame f-pg-imp:
    case self:screen-value:
        when "1" then do:
            assign c-arquivo:sensitive    = no
                   bt-arquivo:visible     = no
                   bt-config-impr:visible = YES
                   /*Alterado 17/02/2005 - tech1007 - Realizado teste de preprocessador para
                     verificar se o RTF est† ativo*/
                   &IF "{&RTF}":U = "YES":U &THEN
                   l-habilitaRtf:sensitive  = NO
                   l-habilitaRtf:SCREEN-VALUE IN FRAME f-pg-imp = "No"
                   l-habilitaRtf = NO
                   &endif
                   /*Fim alteracao 17/02/2005*/
                   .
        end.
        when "2" then do:
            assign c-arquivo:sensitive     = yes
                   bt-arquivo:visible      = yes
                   bt-config-impr:visible  = NO
                   /*Alterado 17/02/2005 - tech1007 - Realizado teste de preprocessador para
                     verificar se o RTF est† ativo*/
                   &IF "{&RTF}":U = "YES":U &THEN
                   l-habilitaRtf:sensitive  = YES
                   &endif
                   /*Fim alteracao 17/02/2005*/
                   .
        end.
        when "3" then do:
            assign c-arquivo:sensitive     = no
                   bt-arquivo:visible      = no
                   bt-config-impr:visible  = no
                   /*Alterado 17/02/2005 - tech1007 - Realizado teste de preprocessador para
                     verificar se o RTF est† ativo*/
                   &IF "{&RTF}":U = "YES":U &THEN
                   l-habilitaRtf:sensitive  = YES
                   &endif
                   /*Fim alteracao 17/02/2005*/
                   .
            /*Alterado 15/02/2005 - tech1007 - Teste para funcionar corretamente no WebEnabler*/
            &IF "{&RTF}":U = "YES":U &THEN
            IF VALID-HANDLE(hWenController) THEN DO:
                ASSIGN l-habilitaRtf:sensitive  = NO
                       l-habilitaRtf:SCREEN-VALUE IN FRAME f-pg-imp = "No"
                       l-habilitaRtf = NO.
            END.
            &endif
            /*Fim alteracao 15/02/2005*/
        end.
    end case.
end.
&IF "{&RTF}":U = "YES":U &THEN
RUN pi-habilitaRtf.
&endif
/*Fim alteracao 15/02/2005*/
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-execucao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-execucao w-relat
ON VALUE-CHANGED OF rs-execucao IN FRAME f-pg-imp
DO:
   {include/i-rprse.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-dig
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-relat 


/* ***************************  Main Block  *************************** */

/* Set CURRENT-WINDOW: this will parent dialog-boxes and frames.        */
ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME} 
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.

{utp/ut9000.i "espp006" "2.04.00.001"}

/*:T inicializaá‰es do template de relat¢rio */
{include/i-rpini.i}

/* The CLOSE event can be used from inside or outside the procedure to  */
/* terminate it.                                                        */
ON CLOSE OF THIS-PROCEDURE 
   RUN disable_UI.

{include/i-rplbl.i}

/* Best default for GUI applications is...                              */
PAUSE 0 BEFORE-HIDE.

/* Now enable the interface and wait for the exit condition.            */
/* (NOTE: handle ERROR and END-KEY so cleanup code will always fire.    */
MAIN-BLOCK:
DO  ON ERROR   UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK
    ON END-KEY UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK:

    RUN enable_UI.
    

ON 'leave':U OF  tt-digita.tb-preco IN BROWSE br-digita DO:
    IF tt-digita.tb-preco:SCREEN-VALUE IN BROWSE br-digita <> " " THEN DO:
       FIND tb-preco WHERE 
            tb-preco.nr-tabpre = tt-digita.tb-preco:SCREEN-VALUE IN BROWSE br-digita
            NO-LOCK NO-ERROR.
       IF NOT AVAIL tb-preco THEN DO:
          MESSAGE "Tabela de Preáo n∆o Encontrada"
              VIEW-AS ALERT-BOX INFO BUTTONS OK.
          APPLY 'entry' TO tt-digita.tb-preco IN BROWSE br-digita.
          RETURN NO-APPLY.
       END.
       IF AVAIL tb-preco THEN DO:
          FIND FIRST  preco-item WHERE 
                               preco-item.nr-tabpre = tb-preco.nr-tabpre AND
                               preco-item.it-codigo = pp-ped-item.it-codigo
                               NO-LOCK NO-ERROR.
          IF NOT AVAIL preco-item THEN DO:
             MESSAGE "Esse item n∆o est† cadastrado na tabela de preáo"  tb-preco.nr-tabpre
                 VIEW-AS ALERT-BOX INFO BUTTONS OK.
             APPLY 'entry' TO tt-digita.tb-preco IN BROWSE br-digita.
             RETURN NO-APPLY.
          END.
          IF AVAIL preco-item THEN DO:
             FIND cond-pagto WHERE 
                  cond-pagto.cod-cond-pag = INPUT BROWSE br-digita tt-digita.cond-pagto
                  NO-LOCK NO-ERROR.
             FIND tab-finan WHERE
                  tab-finan.nr-tab-finan = cond-pagto.nr-tab-finan 
                  NO-LOCK NO-ERROR.
                  ASSIGN tt-digita.vl-novo:SCREEN-VALUE IN BROWSE br-digita = STRING(preco-item.preco-venda * tab-finan.tab-ind-fin[cond-pagto.nr-ind-finan]).
          END.
       END.
    END.
END.

    {include/i-rpmbl.i "im-pg-par"}
  
    IF  NOT THIS-PROCEDURE:PERSISTENT THEN
        WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-relat  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-relat  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-relat  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-relat)
  THEN DELETE WIDGET w-relat.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-relat  _DEFAULT-ENABLE
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
  ENABLE im-pg-dig im-pg-imp im-pg-par bt-executar bt-cancelar bt-ajuda 
      WITH FRAME f-relat IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-relat}
  DISPLAY rs-destino c-arquivo l-habilitaRtf c-modelo-rtf rs-execucao text-rtf 
          text-modelo-rtf 
      WITH FRAME f-pg-imp IN WINDOW w-relat.
  ENABLE RECT-7 RECT-9 rect-rtf rs-destino bt-config-impr bt-arquivo c-arquivo 
         l-habilitaRtf bt-modelo-rtf rs-execucao text-rtf text-modelo-rtf 
      WITH FRAME f-pg-imp IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-imp}
  DISPLAY fi-cod-estabel fi-desc-estab fi-nr-container cb-item fi-desc-item 
          fi-preco 
      WITH FRAME f-pg-par IN WINDOW w-relat.
  ENABLE fi-cod-estabel fi-desc-estab fi-nr-container cb-item fi-desc-item 
         fi-preco 
      WITH FRAME f-pg-par IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-par}
  ENABLE br-digita bt-inserir bt-alterar 
      WITH FRAME f-pg-dig IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-dig}
  VIEW w-relat.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-relat 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-executar w-relat 
PROCEDURE pi-executar :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
define var r-tt-digita as rowid no-undo.

do on error undo, return error on stop  undo, return error:
    {include/i-rpexa.i}
    
    if input frame f-pg-imp rs-destino = 2 and
       input frame f-pg-imp rs-execucao = 1 then do:
       run utp/ut-vlarq.p (input input frame f-pg-imp c-arquivo).
        
       if return-value = "NOK":U then do:
          run utp/ut-msgs.p (input "show":U, input 73, input "").
            
          apply "MOUSE-SELECT-CLICK":U to im-pg-imp in frame f-relat.
          apply "ENTRY":U to c-arquivo in frame f-pg-imp.
          return error.
       end.
    end.

    /*:T Coloque aqui as validaá‰es da p†gina de Digitaá∆o, lembrando que elas devem
       apresentar uma mensagem de erro cadastrada, posicionar nesta p†gina e colocar
       o focus no campo com problemas */
    /*browse br-digita:SET-REPOSITIONED-ROW (browse br-digita:DOWN, "ALWAYS":U).*/
    
    FOR EACH tt-digita NO-LOCK:
        ASSIGN r-tt-digita = ROWID(tt-digita).
        
        /*:T As demais validaá‰es devem ser feitas aqui */
      /*  IF tt-digita.it-codigo = ' ' THEN DO:
           MESSAGE 'Existem Itens n∆o Informados...'
               VIEW-AS ALERT-BOX ERROR BUTTONS OK.

           apply "MOUSE-SELECT-CLICK":U to im-pg-dig in frame f-relat.
           reposition br-digita to rowid r-tt-digita.
            
           apply "ENTRY":U to tt-digita.it-codigo in browse br-digita.
           RETURN ERROR.
        END.

        FIND ITEM WHERE
             ITEM.it-codigo = tt-digita.it-codigo NO-LOCK NO-ERROR.
        IF NOT AVAIL ITEM THEN DO.
           MESSAGE 'Item Informado n∆o est† Cadastrado no EMS...'
               VIEW-AS ALERT-BOX ERROR BUTTONS OK.

           apply "MOUSE-SELECT-CLICK":U to im-pg-dig in frame f-relat.
           reposition br-digita to rowid r-tt-digita.

           APPLY "ENTRY":U to tt-digita.it-codigo in browse br-digita.
           RETURN ERROR.
        END.

        FIND referencia WHERE
             referencia.cod-refer = tt-digita.cod-refer NO-LOCK NO-ERROR.
        IF NOT AVAIL referencia THEN DO.
            MESSAGE 'Referància Informada n∆o est† Cadastrada no EMS...'
                VIEW-AS ALERT-BOX ERROR BUTTONS OK.

            apply "MOUSE-SELECT-CLICK":U to im-pg-dig in frame f-relat.
            reposition br-digita to rowid r-tt-digita.

            APPLY "ENTRY":U to tt-digita.cod-refer in browse br-digita.
            RETURN ERROR.
        END.

        FIND ref-item WHERE
             ref-item.it-codigo = tt-digita.it-codigo AND
             ref-item.cod-refer = tt-digita.cod-refer NO-LOCK.
        IF NOT AVAIL ref-item THEN DO.
           MESSAGE 'Referància Informada n∆o est† Relacinada ao Item...'
                VIEW-AS ALERT-BOX ERROR BUTTONS OK.

           APPLY "MOUSE-SELECT-CLICK":U TO im-pg-dig IN FRAME f-relat.
           REPOSITION br-digita TO ROWID r-tt-digita.

           APPLY "ENTRY":U to tt-digita.cod-refer IN BROWSE br-digita.
           RETURN ERROR.
        END.*/
    END.
    
    /*:T Aqui s∆o gravados os campos da temp-table que ser† passada como parÉmetro
       para o programa RP.P */
    
    create tt-param.
    assign tt-param.usuario         = c-seg-usuario
           tt-param.destino         = input frame f-pg-imp rs-destino
           tt-param.data-exec       = today
           tt-param.hora-exec       = time.
    
    if tt-param.destino = 1 
    then assign tt-param.arquivo = "".
    else if  tt-param.destino = 2
         then assign tt-param.arquivo = input frame f-pg-imp c-arquivo.
         else assign tt-param.arquivo = session:temp-directory + c-programa-mg97 + ".tmp":U.

    /*:T Coloque aqui a/l¢gica de gravaá∆o dos demais campos que devem ser passados
       como parÉmetros para o programa RP.P, atravÇs da temp-table tt-param */
    
    ASSIGN tt-param.i-nr-container  = INPUT FRAME f-pg-par fi-nr-container
           tt-param.cod-estabel     = INPUT FRAME f-pg-par fi-cod-estabel
           tt-param.it-codigo       = INPUT FRAME f-pg-par cb-item
           tt-param.preco           = INPUT FRAME f-pg-par fi-preco.
    
    /*:T Executar do programa RP.P que ir† criar o relat¢rio */
    {include/i-rpexb.i}
    
    SESSION:SET-WAIT-STATE("general":U).
    
    {include/i-rprun.i esrp/espp006rp.p}
    
    {include/i-rpexc.i}
    
    SESSION:SET-WAIT-STATE("":U).
    
    {include/i-rptrm.i}
end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-troca-pagina w-relat 
PROCEDURE pi-troca-pagina :
/*:T------------------------------------------------------------------------------
  Purpose: Gerencia a Troca de P†gina (folder)   
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

{include/i-rptrp.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-relat  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-digita"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-relat 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
  
  run pi-trata-state (p-issuer-hdl, p-state).
  
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

