&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
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

&GLOBAL-DEFINE PGSEL f-pg-sel
&GLOBAL-DEFINE PGCLA 
&GLOBAL-DEFINE PGPAR 
&GLOBAL-DEFINE PGDIG 
&GLOBAL-DEFINE PGIMP f-pg-imp

&GLOBAL-DEFINE RTF   YES
  
/* Parameters Definitions ---                                           */

/* Temporary Table Definitions ---                                      */
DEFINE TEMP-TABLE tt-param
    FIELD destino              AS INTEGER
    FIELD arquivo              AS CHAR
    FIELD usuario              AS CHAR
    FIELD data-exec            AS DATE
    FIELD hora-exec            AS INTEGER
    FIELD cod-estabel          AS CHAR
    FIELD da-dt-emis-nota-ini  LIKE nota-fiscal.dt-emis-nota
    FIELD da-dt-emis-nota-fim  LIKE nota-fiscal.dt-emis-nota
    FIELD c-nome-transp-ini    LIKE nota-fiscal.nome-transp
    FIELD c-nome-transp-fim    LIKE nota-fiscal.nome-transp
    FIELD c-estado-ini         LIKE nota-fiscal.estado
    FIELD c-estado-fim         LIKE nota-fiscal.estado
    FIELD c-cidade-ini         LIKE nota-fiscal.cidade
    FIELD c-cidade-fim         LIKE nota-fiscal.cidade
    FIELD c-bairro-ini         LIKE nota-fiscal.bairro
    FIELD c-bairro-fim         LIKE nota-fiscal.bairro
    FIELD rs-tipo              AS INT.

DEFINE temp-table tt-digita no-undo
    field ordem            as integer   format ">>>>9"
    field exemplo          as character format "x(30)"
    index id ordem.

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

/*15/02/2005 - tech1007 - Variavel definida para tratar se o programa est† rodando no WebEnabler*/
DEFINE SHARED VARIABLE hWenController AS HANDLE NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-relat
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-pg-imp

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rect-rtf RECT-7 RECT-9 rs-destino bt-arquivo ~
bt-config-impr c-arquivo l-habilitaRtf bt-modelo-rtf rs-execucao text-rtf ~
text-modelo-rtf 
&Scoped-Define DISPLAYED-OBJECTS rs-destino c-arquivo l-habilitaRtf ~
c-modelo-rtf rs-execucao text-rtf text-modelo-rtf 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-relat AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
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
"Terminal", 3,
"Excel", 4
     SIZE 40.72 BY 1.08 NO-UNDO.

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

DEFINE VARIABLE fi-bairro-fin AS CHARACTER FORMAT "x(25)" INITIAL "ZZZZZZZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 19 BY .88 TOOLTIP "Representante final." NO-UNDO.

DEFINE VARIABLE fi-bairro-ini AS CHARACTER FORMAT "x(16)" 
     LABEL "Bairro" 
     VIEW-AS FILL-IN 
     SIZE 19 BY .88 TOOLTIP "Representante inicial." NO-UNDO.

DEFINE VARIABLE fi-cidade-fim AS CHARACTER FORMAT "x(25)" INITIAL "ZZZZZZZZZZZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 19 BY .88 TOOLTIP "Representante final." NO-UNDO.

DEFINE VARIABLE fi-cidadei-ini AS CHARACTER FORMAT "x(16)" 
     LABEL "Cidade" 
     VIEW-AS FILL-IN 
     SIZE 19 BY .88 TOOLTIP "Representante inicial." NO-UNDO.

DEFINE VARIABLE fi-cod-estabel AS CHARACTER FORMAT "X(3)":U 
     LABEL "Estabelecimento" 
     VIEW-AS FILL-IN 
     SIZE 4 BY .88 NO-UNDO.

DEFINE VARIABLE fi-desc-estab AS CHARACTER FORMAT "X(50)":U 
     VIEW-AS FILL-IN 
     SIZE 36.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-emis-fin AS DATE FORMAT "99/99/9999":U INITIAL 12/31/9999 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-dt-emis-ini AS DATE FORMAT "99/99/9999":U INITIAL 01/01/001 
     LABEL "Dt Emiss∆o" 
     VIEW-AS FILL-IN 
     SIZE 11 BY .88 NO-UNDO.

DEFINE VARIABLE fi-estado-fin AS CHARACTER FORMAT "X(15)":U INITIAL "ZZ" 
     VIEW-AS FILL-IN 
     SIZE 4.14 BY .88 NO-UNDO.

DEFINE VARIABLE fi-estado-ini AS CHARACTER FORMAT "X(15)":U 
     LABEL "UF" 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE VARIABLE fi-nome-transp-fin AS CHARACTER FORMAT "X(15)":U INITIAL "ZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE VARIABLE fi-nome-transp-ini AS CHARACTER FORMAT "X(15)":U 
     LABEL "Transportadora" 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-3
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-4
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-5
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-6
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-96
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-97
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-98
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-99
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE VARIABLE rs-tipo AS INTEGER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Todos", 1,
"FOB", 2,
"CIF", 3
     SIZE 32 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-53
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 48 BY 1.75.

DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Fechar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-executar 
     LABEL "Executar" 
     SIZE 10 BY 1.

DEFINE IMAGE im-pg-imp
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-sel
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


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-relat
     bt-executar AT ROW 14.54 COL 3 HELP
          "Dispara a execuá∆o do relat¢rio"
     bt-cancelar AT ROW 14.54 COL 14 HELP
          "Fechar"
     bt-ajuda AT ROW 14.54 COL 70 HELP
          "Ajuda"
     RECT-1 AT ROW 14.29 COL 2
     RECT-6 AT ROW 13.75 COL 2.14
     rt-folder-top AT ROW 2.54 COL 2.14
     rt-folder-right AT ROW 2.67 COL 80.43
     rt-folder-left AT ROW 2.54 COL 2.14
     rt-folder AT ROW 2.5 COL 2
     im-pg-imp AT ROW 1.5 COL 17.72
     im-pg-sel AT ROW 1.5 COL 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 81 BY 15
         DEFAULT-BUTTON bt-executar WIDGET-ID 100.

DEFINE FRAME f-pg-imp
     rs-destino AT ROW 1.63 COL 3.29 HELP
          "Destino de Impress∆o do Relat¢rio" NO-LABEL
     bt-arquivo AT ROW 2.71 COL 43.29 HELP
          "Escolha do nome do arquivo"
     bt-config-impr AT ROW 2.71 COL 43.29 HELP
          "Configuraá∆o da impressora"
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
     rect-rtf AT ROW 4.46 COL 2
     RECT-7 AT ROW 1.33 COL 2.14
     RECT-9 AT ROW 8.33 COL 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 73.72 BY 10.5
         FONT 1 WIDGET-ID 100.

DEFINE FRAME f-pg-sel
     fi-cod-estabel AT ROW 1.5 COL 18 COLON-ALIGNED WIDGET-ID 2
     fi-desc-estab AT ROW 1.5 COL 22.43 COLON-ALIGNED NO-LABEL WIDGET-ID 4 NO-TAB-STOP 
     fi-dt-emis-ini AT ROW 2.5 COL 18 COLON-ALIGNED WIDGET-ID 74
     fi-dt-emis-fin AT ROW 2.5 COL 48 COLON-ALIGNED NO-LABEL WIDGET-ID 76
     fi-nome-transp-ini AT ROW 3.5 COL 18 COLON-ALIGNED
     fi-nome-transp-fin AT ROW 3.5 COL 47.86 COLON-ALIGNED NO-LABEL
     fi-estado-ini AT ROW 4.5 COL 18 COLON-ALIGNED WIDGET-ID 30
     fi-estado-fin AT ROW 4.5 COL 47.86 COLON-ALIGNED NO-LABEL WIDGET-ID 28
     fi-cidadei-ini AT ROW 5.5 COL 18 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" WIDGET-ID 46
     fi-cidade-fim AT ROW 5.5 COL 48 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" NO-LABEL WIDGET-ID 44
     fi-bairro-ini AT ROW 6.5 COL 18 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" WIDGET-ID 64
     fi-bairro-fin AT ROW 6.5 COL 48 COLON-ALIGNED HELP
          "Codigo do ÷tem no EMS" NO-LABEL WIDGET-ID 62
     rs-tipo AT ROW 8.75 COL 25 NO-LABEL WIDGET-ID 70
     " Tipo" VIEW-AS TEXT
          SIZE 5.29 BY .54 AT ROW 8 COL 21.72 WIDGET-ID 58
     IMAGE-1 AT ROW 3.5 COL 39.86
     IMAGE-2 AT ROW 3.5 COL 46.43
     IMAGE-3 AT ROW 2.5 COL 39.86 WIDGET-ID 8
     IMAGE-4 AT ROW 2.5 COL 46.43 WIDGET-ID 10
     IMAGE-5 AT ROW 4.5 COL 39.86 WIDGET-ID 32
     IMAGE-6 AT ROW 4.5 COL 46.43 WIDGET-ID 34
     RECT-53 AT ROW 8.25 COL 20 WIDGET-ID 40
     IMAGE-96 AT ROW 5.5 COL 40 WIDGET-ID 48
     IMAGE-97 AT ROW 5.5 COL 46.57 WIDGET-ID 50
     IMAGE-98 AT ROW 6.5 COL 40 WIDGET-ID 66
     IMAGE-99 AT ROW 6.5 COL 46.57 WIDGET-ID 68
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 2.85
         SIZE 76.86 BY 10.62
         FONT 1 WIDGET-ID 100.


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
         TITLE              = "Frete Por Cidade - ESFT007.W"
         HEIGHT             = 15
         WIDTH              = 81.14
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
/* SETTINGS FOR FRAME f-pg-imp
   FRAME-NAME                                                           */
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

/* SETTINGS FOR FRAME f-pg-sel
                                                                        */
ASSIGN 
       fi-desc-estab:READ-ONLY IN FRAME f-pg-sel        = TRUE.

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

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-imp
/* Query rebuild information for FRAME f-pg-imp
     _Query            is NOT OPENED
*/  /* FRAME f-pg-imp */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-sel
/* Query rebuild information for FRAME f-pg-sel
     _Query            is NOT OPENED
*/  /* FRAME f-pg-sel */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-relat
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-relat w-relat
ON END-ERROR OF w-relat /* Frete Por Cidade - ESFT007.W */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-relat w-relat
ON WINDOW-CLOSE OF w-relat /* Frete Por Cidade - ESFT007.W */
DO:
  /* This event will close the window and terminate the procedure.  */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
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
   do  on error undo, return no-apply:
       run pi-executar.
   end.
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


&Scoped-define FRAME-NAME f-pg-sel
&Scoped-define SELF-NAME fi-bairro-fin
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-bairro-fin w-relat
ON LEAVE OF fi-bairro-fin IN FRAME f-pg-sel
DO:
  IF SELF:SCREEN-VALUE <> '' THEN DO.
     FIND repres WHERE 
          repres.nome-abrev = SELF:SCREEN-VALUE
          NO-LOCK NO-ERROR.
     IF NOT AVAIL repres THEN
        FIND repres WHERE 
             STRING(repres.cod-rep) = SELF:SCREEN-VALUE
             NO-LOCK NO-ERROR.

     IF AVAIL repres THEN
        ASSIGN fi-no-ab-reppri-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME} = repres.nome-abrev.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-bairro-fin w-relat
ON MOUSE-SELECT-DBLCLICK OF fi-bairro-fin IN FRAME f-pg-sel
DO:
  {include/zoomvar.i &prog-zoom = adzoom/z01ad229.w
                     &campo     = fi-no-ab-reppri-fim
                     &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-bairro-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-bairro-ini w-relat
ON LEAVE OF fi-bairro-ini IN FRAME f-pg-sel /* Bairro */
DO:
   IF SELF:SCREEN-VALUE <> '' THEN DO.
      FIND repres WHERE 
           repres.nome-abrev = SELF:SCREEN-VALUE
           NO-LOCK NO-ERROR.
       IF NOT AVAIL repres THEN
          FIND repres WHERE 
               STRING(repres.cod-rep) = SELF:SCREEN-VALUE
               NO-LOCK NO-ERROR.
    
       IF AVAIL repres THEN
          ASSIGN fi-no-ab-reppri-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME} = repres.nome-abrev.
    
       ASSIGN fi-no-ab-reppri-fim:SCREEN-VALUE = SELF:SCREEN-VALUE.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-bairro-ini w-relat
ON MOUSE-SELECT-DBLCLICK OF fi-bairro-ini IN FRAME f-pg-sel /* Bairro */
DO:
  {include/zoomvar.i &prog-zoom = adzoom/z01ad229.w
                     &campo     = fi-no-ab-reppri-ini
                     &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cidade-fim
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cidade-fim w-relat
ON LEAVE OF fi-cidade-fim IN FRAME f-pg-sel
DO:
  IF SELF:SCREEN-VALUE <> '' THEN DO.
     FIND repres WHERE 
          repres.nome-abrev = SELF:SCREEN-VALUE
          NO-LOCK NO-ERROR.
     IF NOT AVAIL repres THEN
        FIND repres WHERE 
             STRING(repres.cod-rep) = SELF:SCREEN-VALUE
             NO-LOCK NO-ERROR.

     IF AVAIL repres THEN
        ASSIGN fi-no-ab-reppri-fim:SCREEN-VALUE IN FRAME {&FRAME-NAME} = repres.nome-abrev.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cidade-fim w-relat
ON MOUSE-SELECT-DBLCLICK OF fi-cidade-fim IN FRAME f-pg-sel
DO:
  {include/zoomvar.i &prog-zoom = adzoom/z01ad229.w
                     &campo     = fi-no-ab-reppri-fim
                     &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cidadei-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cidadei-ini w-relat
ON LEAVE OF fi-cidadei-ini IN FRAME f-pg-sel /* Cidade */
DO:
   IF SELF:SCREEN-VALUE <> '' THEN DO.
      FIND repres WHERE 
           repres.nome-abrev = SELF:SCREEN-VALUE
           NO-LOCK NO-ERROR.
       IF NOT AVAIL repres THEN
          FIND repres WHERE 
               STRING(repres.cod-rep) = SELF:SCREEN-VALUE
               NO-LOCK NO-ERROR.
    
       IF AVAIL repres THEN
          ASSIGN fi-no-ab-reppri-ini:SCREEN-VALUE IN FRAME {&FRAME-NAME} = repres.nome-abrev.
    
       ASSIGN fi-no-ab-reppri-fim:SCREEN-VALUE = SELF:SCREEN-VALUE.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cidadei-ini w-relat
ON MOUSE-SELECT-DBLCLICK OF fi-cidadei-ini IN FRAME f-pg-sel /* Cidade */
DO:
  {include/zoomvar.i &prog-zoom = adzoom/z01ad229.w
                     &campo     = fi-no-ab-reppri-ini
                     &campozoom = nome-abrev}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cod-estabel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cod-estabel w-relat
ON LEAVE OF fi-cod-estabel IN FRAME f-pg-sel /* Estabelecimento */
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


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME im-pg-imp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-imp w-relat
ON MOUSE-SELECT-CLICK OF im-pg-imp IN FRAME f-relat
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-sel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-sel w-relat
ON MOUSE-SELECT-CLICK OF im-pg-sel IN FRAME f-relat
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


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-relat 


/* ***************************  Main Block  *************************** */

/* Set CURRENT-WINDOW: this will parent dialog-boxes and frames.        */
ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME} 
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.

/*{utp/ut9000.i "XX9999" "9.99.99.999"}*/

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
    
    FIND FIRST para-ped NO-LOCK NO-ERROR.
    ASSIGN fi-cod-estabel:SCREEN-VALUE IN FRAME f-pg-sel = para-ped.estab-pad.

    ASSIGN rs-destino:SCREEN-VALUE IN FRAME f-pg-imp = '4'.

    {include/i-rpmbl.i}
  
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
  ENABLE im-pg-imp im-pg-sel bt-executar bt-cancelar bt-ajuda 
      WITH FRAME f-relat IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-relat}
  DISPLAY fi-cod-estabel fi-desc-estab fi-dt-emis-ini fi-dt-emis-fin 
          fi-nome-transp-ini fi-nome-transp-fin fi-estado-ini fi-estado-fin 
          fi-cidadei-ini fi-cidade-fim fi-bairro-ini fi-bairro-fin rs-tipo 
      WITH FRAME f-pg-sel IN WINDOW w-relat.
  ENABLE IMAGE-1 IMAGE-2 IMAGE-3 IMAGE-4 IMAGE-5 IMAGE-6 RECT-53 IMAGE-96 
         IMAGE-97 IMAGE-98 IMAGE-99 fi-cod-estabel fi-desc-estab fi-dt-emis-ini 
         fi-dt-emis-fin fi-nome-transp-ini fi-nome-transp-fin fi-estado-ini 
         fi-estado-fin fi-cidadei-ini fi-cidade-fim fi-bairro-ini fi-bairro-fin 
         rs-tipo 
      WITH FRAME f-pg-sel IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-sel}
  DISPLAY rs-destino c-arquivo l-habilitaRtf c-modelo-rtf rs-execucao text-rtf 
          text-modelo-rtf 
      WITH FRAME f-pg-imp IN WINDOW w-relat.
  ENABLE rect-rtf RECT-7 RECT-9 rs-destino bt-arquivo bt-config-impr c-arquivo 
         l-habilitaRtf bt-modelo-rtf rs-execucao text-rtf text-modelo-rtf 
      WITH FRAME f-pg-imp IN WINDOW w-relat.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-imp}
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
    /*14/02/2005 - tech1007 - Alterada condicao para n∆o considerar mai o RTF como destino*/
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

    /*14/02/2005 - tech1007 - Teste efetuado para nao permitir modelo em branco*/
    &IF "{&RTF}":U = "YES":U &THEN
    IF ( INPUT FRAME f-pg-imp c-modelo-rtf = "" AND
         INPUT FRAME f-pg-imp l-habilitaRtf = "Yes" ) OR
       ( SEARCH(INPUT FRAME f-pg-imp c-modelo-rtf) = ? AND
         input frame f-pg-imp rs-execucao = 1 AND
         INPUT FRAME f-pg-imp l-habilitaRtf = "Yes" )
         THEN DO:
        run utp/ut-msgs.p (input "show":U, input 73, input "").        
        apply "MOUSE-SELECT-CLICK":U to im-pg-imp in frame f-relat.
        /*30/12/2004 - tech1007 - Evento removido pois causa problemas no WebEnabler*/
        /*apply "CHOOSE":U to bt-modelo-rtf in frame f-pg-imp.*/
        return error.
    END.
    &endif
    /*Fim teste Modelo*/
    
    /*:T Coloque aqui as validaá‰es da p†gina de Digitaá∆o, lembrando que elas devem
       apresentar uma mensagem de erro cadastrada, posicionar nesta p†gina e colocar
       o focus no campo com problemas */
    /*browse br-digita:SET-REPOSITIONED-ROW (browse br-digita:DOWN, "ALWAYS":U).*/
    
    
    /*:T Coloque aqui as validaá‰es das outras p†ginas, lembrando que elas devem 
       apresentar uma mensagem de erro cadastrada, posicionar na p†gina com 
       problemas e colocar o focus no campo com problemas */
    
    
    
    /*:T Aqui s∆o gravados os campos da temp-table que ser† passada como parÉmetro
       para o programa RP.P */
    
    create tt-param.
    assign tt-param.usuario         = c-seg-usuario
           tt-param.destino         = input frame f-pg-imp rs-destino
           tt-param.data-exec       = today
           tt-param.hora-exec       = time
           &IF "{&RTF}":U = "YES":U &THEN
           tt-param.modelo-rtf      = INPUT FRAME f-pg-imp c-modelo-rtf
           /*Alterado 14/02/2005 - tech1007 - Armazena a informaá∆o se o RTF est† habilitado ou n∆o*/
           tt-param.l-habilitaRtf     = INPUT FRAME f-pg-imp l-habilitaRtf
           /*Fim alteracao 14/02/2005*/ 
           &endif
           .
    
    /*Alterado 14/02/2005 - tech1007 - Alterado o teste para verificar se a opá∆o de RTF est† selecionada*/
    if tt-param.destino = 1 
    then assign tt-param.arquivo = "".
    else if  tt-param.destino = 2
         then assign tt-param.arquivo = input frame f-pg-imp c-arquivo.
         else assign tt-param.arquivo = session:temp-directory + c-programa-mg97 + ".tmp":U.
    /*Fim alteracao 14/02/2005*/

    /*:T Coloque aqui a/l¢gica de gravaá∆o dos demais campos que devem ser passados
       como parÉmetros para o programa RP.P, atravÇs da temp-table tt-param */
    
    ASSIGN tt-param.cod-estabel         = INPUT FRAME f-pg-sel fi-cod-estabel
           tt-param.c-cod-estabel-fim   = INPUT FRAME f-pg-sel c-cod-estabel-fim
           tt-param.c-cod-estabel-fim   = INPUT FRAME f-pg-sel c-cod-estabel-fim
           tt-param.da-dt-emis-nota-ini = INPUT FRAME f-pg-sel da-dt-emis-nota-ini
           tt-param.da-dt-emis-nota-fim = INPUT FRAME f-pg-sel da-dt-emis-nota-fim
           tt-param.c-nome-transp-ini   = INPUT FRAME f-pg-sel c-nome-transp-ini
           tt-param.c-nome-transp-fim   = INPUT FRAME f-pg-sel c-nome-transp-fim
           tt-param.c-estado-ini        = INPUT FRAME f-pg-sel c-estado-ini
           tt-param.c-estado-fim        = INPUT FRAME f-pg-sel c-estado-fim
           tt-param.c-cidade-ini        = INPUT FRAME f-pg-sel c-cidade-ini
           tt-param.c-cidade-fim        = INPUT FRAME f-pg-sel c-cidade-fim
           tt-param.c-bairro-ini        = INPUT FRAME f-pg-sel c-bairro-ini
           tt-param.c-bairro-fim        = INPUT FRAME f-pg-sel c-bairro-fim
           tt-param.rs-tipo             = INPUT FRAME f-pg-sel rs-tipo.         
    
    
    /*:T Executar do programa RP.P que ir† criar o relat¢rio */
    {include/i-rpexb.i}
    
    SESSION:SET-WAIT-STATE("general":U).
    
    {include/i-rprun.i esrp/esft007rp.p}
    
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

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this w-relat, and there are no
     tables specified in any contained Browse, Query, or Frame. */

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

