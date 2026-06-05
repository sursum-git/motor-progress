&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS C-Win 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i mala_direta 2.04.00.001}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Preprocessadores do Template de Relat¢rio                            */
/* Obs: Retirar o valor do preprocessador para as p†ginas que n∆o existirem  */

&GLOBAL-DEFINE PGLAY 
&GLOBAL-DEFINE PGSEL f-pg-sel
&GLOBAL-DEFINE PGPAR f-pg-par
&GLOBAL-DEFINE PGLOG f-pg-log

/* Parameters Definitions ---                                           */


/* Temporary Table Definitions ---  */

DEFINE NEW GLOBAL SHARED VARIABLE caminho       AS CHARACTER  NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE nome-arquivo  AS CHARACTER  NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE salvar-como   AS CHARACTER  NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE var-tg-partir AS LOG  NO-UNDO.

DEFINE VARIABLE qtclientes        AS INTEGER    NO-UNDO.
DEFINE VARIABLE i                 AS INTEGER    NO-UNDO.
DEFINE VARIABLE barra             AS INTEGER    NO-UNDO.
DEFINE VARIABLE ponto             AS INTEGER    NO-UNDO.


DEFINE VARIABLE se-for-pri       AS CHARACTER  NO-UNDO.
DEFINE VARIABLE se-for-ult       AS CHARACTER  NO-UNDO.
                                 
DEFINE VARIABLE breakby          AS CHARACTER  NO-UNDO.
DEFINE VARIABLE var-put          AS CHARACTER  NO-UNDO.
DEFINE VARIABLE var-qtby         AS INTEGER    NO-UNDO.
DEFINE VARIABLE var-qtsel        AS INTEGER    NO-UNDO.
DEFINE VARIABLE var-coluna       AS CHARACTER FORMAT "x(2000)" NO-UNDO.
DEFINE VARIABLE ordem            AS INTEGER    NO-UNDO.
DEF VAR i-ct AS INT.


DEFINE VARIABLE OKpressed        AS LOGICAL    NO-UNDO.

/* Variaveis usadas na Procedure pi-envia-email */
DEFINE VARIABLE email-enviado    AS LOGICAL    NO-UNDO.
DEFINE VARIABLE qt-email-enviado AS INTEGER    NO-UNDO.
DEFINE VARIABLE diretorio-html   AS CHARACTER  NO-UNDO.
DEFINE VARIABLE diretorio-imagem AS CHARACTER  NO-UNDO.
DEFINE VARIABLE nome-imagem      AS CHARACTER  NO-UNDO.
DEFINE VARIABLE index-barra      AS INTEGER     NO-UNDO.
def var h-acomp as handle no-undo.



/*DEF NEW GLOBAL SHARED VAR var-linha AS INT NO-UNDO.*/

define temp-table tt-param
    field destino     as integer
    field arq-destino as char
    field arq-entrada as char
    field todos       as integer
    field usuario     as char
    field data-exec   as date
    field hora-exec   as integer.

DEF NEW SHARED TEMP-TABLE tt-sel
    FIELD fi-data-ini      AS DATE
    FIELD fi-data-fim      AS DATE
    FIELD fi-cliente-ini   AS INT
    FIELD fi-cliente-fim   AS INT
    FIELD fi-repres-ini    AS INT
    FIELD fi-repres-fim    AS INT
    FIELD fi-cidade-ini    AS CHAR
    FIELD fi-cidade-fim    AS CHAR
    FIELD fi-estado-ini    AS CHAR
    FIELD fi-estado-fim    AS CHAR
    FIELD rs-estab         AS INT
    FIELD tg-repres-ima    AS LOG
    FIELD tg-suspenso      AS INT
    FIELD fi-ramo-ativ-ini AS INT
    FIELD fi-ramo-ativ-fim AS INT
    FIELD rs-email         AS INT
    FIELD tg-repres-dif    AS LOG.
   

DEF NEW SHARED TEMP-TABLE tt-conteudo
    FIELD cod-emitente   AS INT FORMAT ">>>>>9"
    FIELD nome-ab-cli    AS CHAR FORMAT "x(25)"          
    FIELD nome-emit      AS CHAR FORMAT "x(45)"          
    FIELD endereco       AS CHAR FORMAT "x(45)"          
    FIELD cidade         AS CHAR FORMAT "x(45)"          
    FIELD bairro         AS CHAR FORMAT "x(30)"          
    FIELD estado         AS CHAR FORMAT "X(2)" 
    FIELD CEP            AS CHAR FORMAT "x(20)"
    FIELD endereco-cob   AS CHAR FORMAT "x(45)"          
    FIELD cidade-cob     AS CHAR FORMAT "x(45)"          
    FIELD bairro-cob     AS CHAR FORMAT "x(30)"          
    FIELD estado-cob     AS CHAR FORMAT "X(2)"           
    FIELD CEP-cob        AS CHAR FORMAT "x(20)"
    FIELD email          AS CHAR FORMAT "x(60)" 
    FIELD ind-cre-cli    AS INT FORMAT "9"
    FIELD cod-ramo-ativ  AS INT FORMAT ">>>>>9"
    FIELD desc-ramo-ativ AS CHAR FORMAT "x(45)"
    FIELD telefone       AS CHAR FORMAT "x(40)"
    FIELD dt-ult-compra  AS DATE
    FIELD tot-venda      AS DEC
    FIELD cod-rep-ven    AS INT
    FIELD nom-rep-ven    AS CHAR FORMAT "x(45)"
    FIELD cod-rep-cad    AS INT
    FIELD nom-rep-cad    AS CHAR FORMAT "x(45)"
    FIELD cgc            AS CHAR FORMAT "x(45)".

DEF NEW SHARED TEMP-TABLE tt-colunas
    FIELD ordem  AS INT
    FIELD coluna AS CHAR.

DEF NEW SHARED TEMP-TABLE tt-disp-colunas
    FIELD ordem  AS INT
    FIELD coluna AS CHAR.

DEF NEW SHARED TEMP-TABLE tt-axi
    FIELD ordem  AS INT
    FIELD coluna AS CHAR.


EMPTY TEMP-TABLE tt-colunas.
EMPTY TEMP-TABLE tt-disp-colunas.

ASSIGN ordem = 0.

CREATE tt-colunas.        
ASSIGN tt-colunas.ordem  = 1
       tt-colunas.coluna = "cod-emitente".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 2              
       tt-colunas.coluna = "nome-ab-cli".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 3              
       tt-colunas.coluna = "nome-emit". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 4              
       tt-colunas.coluna = "endereco". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 5              
       tt-colunas.coluna = "bairro". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 6              
       tt-colunas.coluna = "cidade". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 7              
       tt-colunas.coluna = "estado". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 8              
       tt-colunas.coluna = "CEP".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 9              
       tt-colunas.coluna = "endereco-cob". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 10              
       tt-colunas.coluna = "bairro-cob". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 11              
       tt-colunas.coluna = "cidade-cob". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 12              
       tt-colunas.coluna = "estado-cob". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 13              
       tt-colunas.coluna = "CEP-cob". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 14              
       tt-colunas.coluna = "email". 
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 15
       tt-colunas.coluna = "cod-ramo-ativ".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 16
       tt-colunas.coluna = "desc-ramo-ativ".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 17
       tt-colunas.coluna = "telefone".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 18              
       tt-colunas.coluna = "dt-ult-compra".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 19                         
       tt-colunas.coluna = "tot-venda".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 20   
       tt-colunas.coluna = "cod-rep-ven".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 21   
       tt-colunas.coluna = "nom-rep-ven".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 22             
       tt-colunas.coluna = "cod-rep-cad".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 23   
       tt-colunas.coluna = "nom-rep-cad".
CREATE tt-colunas.                        
ASSIGN tt-colunas.ordem  = 24   
       tt-colunas.coluna = "cgc".   

/*
FOR EACH _file WHERE
        _file._file-name = "tt-conteudo" NO-LOCK.
   FOR EACH _field OF _file NO-LOCK.
       CREATE tt-colunas.
       ASSIGN tt-colunas.ordem = ordem + 1 
              tt-colunas.coluna = _field._field-name.
   END.
END.
ASSIGN ordem = 0.
*/
/* Transfer Definitions */

def var raw-param        as raw no-undo.

def temp-table tt-raw-digita
   field raw-digita      as raw.
                    
/* Local Variable Definitions ---                                       */

def var l-ok               as logical no-undo.
def var c-arq-digita       as char    no-undo.
def var c-terminal         as char    no-undo.
def var c-arq-term         as char    no-undo.

DEFINE SHARED VARIABLE  base AS CHARACTER.

/*{include/i-imdef.i} comentado dia 19/06/09 */

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-impor
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-import
&Scoped-define BROWSE-NAME br-colunas

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-colunas tt-disp-colunas

/* Definitions for BROWSE br-colunas                                    */
&Scoped-define FIELDS-IN-QUERY-br-colunas tt-colunas.coluna   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-colunas   
&Scoped-define SELF-NAME br-colunas
&Scoped-define QUERY-STRING-br-colunas FOR EACH tt-colunas SHARE-LOCK BY tt-colunas.ordem INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-colunas OPEN QUERY {&SELF-NAME} FOR EACH tt-colunas SHARE-LOCK BY tt-colunas.ordem INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-colunas tt-colunas
&Scoped-define FIRST-TABLE-IN-QUERY-br-colunas tt-colunas


/* Definitions for BROWSE br-disp-colunas                               */
&Scoped-define FIELDS-IN-QUERY-br-disp-colunas tt-disp-colunas.ordem tt-disp-colunas.coluna   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-disp-colunas   
&Scoped-define SELF-NAME br-disp-colunas
&Scoped-define QUERY-STRING-br-disp-colunas FOR EACH tt-disp-colunas  SHARE-LOCK BY tt-disp-colunas.ordem INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-disp-colunas OPEN QUERY {&SELF-NAME} FOR EACH tt-disp-colunas  SHARE-LOCK BY tt-disp-colunas.ordem INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-disp-colunas tt-disp-colunas
&Scoped-define FIRST-TABLE-IN-QUERY-br-disp-colunas tt-disp-colunas


/* Definitions for FRAME f-pg-par                                       */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-pg-par ~
    ~{&OPEN-QUERY-br-colunas}~
    ~{&OPEN-QUERY-br-disp-colunas}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS im-pg-par im-pg-sel im-pg-log bt-executar ~
bt-cancelar bt-ajuda 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-1 fi-remetente fi-assunto bt-imagem fi-imagem 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR C-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-executar 
     LABEL "Executar" 
     SIZE 10 BY 1.

DEFINE IMAGE im-pg-lay
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-log
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-par
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

DEFINE BUTTON bt-arquivo-destino 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-config-impr-destino 
     IMAGE-UP FILE "image\im-cfprt":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-imagem 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE VARIABLE c-arquivo-destino AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 500
     SIZE-PIXELS 308 BY 21 NO-UNDO.

DEFINE VARIABLE fi-assunto AS CHARACTER FORMAT "X(256)":U 
     LABEL "Assunto" 
     VIEW-AS FILL-IN 
     SIZE 40.57 BY .88 NO-UNDO.

DEFINE VARIABLE fi-imagem AS CHARACTER FORMAT "X(256)":U 
     LABEL "Imagem" 
     VIEW-AS FILL-IN 
     SIZE 35.72 BY .88 NO-UNDO.

DEFINE VARIABLE fi-remetente AS CHARACTER FORMAT "X(256)":U INITIAL "maladireta@imatextil.com.br" 
     LABEL "Remetente" 
     VIEW-AS FILL-IN 
     SIZE 40.57 BY .88 NO-UNDO.

DEFINE VARIABLE text-destino AS CHARACTER FORMAT "X(256)":U INITIAL " Destino" 
      VIEW-AS TEXT 
     SIZE 6.72 BY .63 NO-UNDO.

DEFINE VARIABLE rs-destino AS INTEGER INITIAL 2 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Arquivo", 2
     SIZE 9.72 BY 1.08 NO-UNDO.

DEFINE VARIABLE rs-tipo-arquivo AS INTEGER INITIAL 1 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Excel - .xls", 1,
"Texto - .txt", 2
     SIZE 28.29 BY 1 NO-UNDO.

DEFINE RECTANGLE RECT-11
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 51 BY 1.71.

DEFINE RECTANGLE RECT-13
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 51 BY 3.67.

DEFINE RECTANGLE RECT-7
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 51 BY 2.46.

DEFINE VARIABLE tg-enviar-email AS LOGICAL INITIAL no 
     LABEL "Enviar e-mail" 
     VIEW-AS TOGGLE-BOX
     SIZE 11.72 BY .83 NO-UNDO.

DEFINE VARIABLE tg-partir AS LOGICAL INITIAL no 
     LABEL "Separar por Representante" 
     VIEW-AS TOGGLE-BOX
     SIZE 21 BY .83 NO-UNDO.

DEFINE BUTTON bt-add 
     IMAGE-UP FILE "image/im-prox.bmp":U
     LABEL "bt-add" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-add-all 
     IMAGE-UP FILE "image/im-ff.bmp":U
     LABEL "bt-add-all" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-ant 
     IMAGE-UP FILE "image/im-acm1.bmp":U
     LABEL "bt-ant" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-arquivo-entrada 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-exc 
     IMAGE-UP FILE "image/im-pre.bmp":U
     LABEL "bt-exc" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-exc-all 
     IMAGE-UP FILE "image/im-rew.bmp":U
     LABEL "bt-exc-all" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-pri 
     IMAGE-UP FILE "image/im-up4.bmp":U
     LABEL "bt-pri" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-pro 
     IMAGE-UP FILE "image/im-abx1.bmp":U
     LABEL "bt-pro" 
     SIZE 3.57 BY 1.

DEFINE BUTTON bt-ult 
     IMAGE-UP FILE "image/im-down4.bmp":U
     LABEL "bt-ult" 
     SIZE 3.57 BY 1.

DEFINE VARIABLE c-arquivo-entrada AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 256
     SIZE 40 BY .88
     BGCOLOR 15  NO-UNDO.

DEFINE VARIABLE text-entrada AS CHARACTER FORMAT "X(256)":U INITIAL "Arquivo de Entrada" 
      VIEW-AS TEXT 
     SIZE 19 BY .63 NO-UNDO.

DEFINE RECTANGLE RECT-8
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 2.

DEFINE VARIABLE fi-cidade-fim AS CHARACTER FORMAT "X(256)":U INITIAL "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz" 
     VIEW-AS FILL-IN 
     SIZE 23 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cidade-ini AS CHARACTER FORMAT "X(256)":U 
     LABEL "Cidade" 
     VIEW-AS FILL-IN 
     SIZE 23 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cliente-fim AS INTEGER FORMAT ">>>>>9":U INITIAL 999999 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-cliente-ini AS INTEGER FORMAT ">>>>>9":U INITIAL 0 
     LABEL "Cliente" 
     VIEW-AS FILL-IN 
     SIZE 7 BY .88 NO-UNDO.

DEFINE VARIABLE fi-data-fim AS DATE FORMAT "99/99/9999":U INITIAL 12/31/10 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-data-ini AS DATE FORMAT "99/99/9999":U INITIAL 01/01/10 
     LABEL "Data" 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88
     FONT 1 NO-UNDO.

DEFINE VARIABLE fi-estado-fim AS CHARACTER FORMAT "X(2)":U INITIAL "zz" 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE VARIABLE fi-estado-ini AS CHARACTER FORMAT "X(2)":U 
     LABEL "Uf" 
     VIEW-AS FILL-IN 
     SIZE 4.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-ramo-ativ-fim AS INTEGER FORMAT ">>9":U INITIAL 999 
     VIEW-AS FILL-IN 
     SIZE 5 BY .88 NO-UNDO.

DEFINE VARIABLE fi-ramo-ativ-ini AS INTEGER FORMAT ">>9":U INITIAL 0 
     LABEL "Ramo Ativ" 
     VIEW-AS FILL-IN 
     SIZE 4.86 BY .88 NO-UNDO.

DEFINE VARIABLE fi-repres-fim AS INTEGER FORMAT ">>>>>>9":U INITIAL 9999999 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88 NO-UNDO.

DEFINE VARIABLE fi-repres-ini AS INTEGER FORMAT ">>>>>>9":U INITIAL 0 
     LABEL "Repres" 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88 NO-UNDO.

DEFINE IMAGE IMAGE-D-1
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-D-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-D-3
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-D-4
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-D-5
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-D-6
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-E-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-E-2
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-E-3
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-E-4
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-E-5
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-E-6
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE VARIABLE rs-email AS INTEGER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Todos", 1,
"Com e-mail", 2,
"Sem e-mail", 3
     SIZE 33 BY .46 NO-UNDO.

DEFINE VARIABLE rs-estab AS INTEGER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Todos", 1,
"Ima", 2,
"Med", 3
     SIZE 24.29 BY .67 NO-UNDO.

DEFINE RECTANGLE RECT-10
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 26 BY .79.

DEFINE RECTANGLE RECT-12
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 35 BY .88.

DEFINE RECTANGLE RECT-14
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 73 BY 1.42.

DEFINE VARIABLE tg-repres-dif AS LOGICAL INITIAL no 
     LABEL "Apenas Repres Diferentes" 
     VIEW-AS TOGGLE-BOX
     SIZE 22 BY .83 TOOLTIP "Apenas Repres da Venda Diferente do Cadastrado" NO-UNDO.

DEFINE VARIABLE tg-repres-ima AS LOGICAL INITIAL no 
     LABEL "Exceto Representante Ima" 
     VIEW-AS TOGGLE-BOX
     SIZE 21 BY .83
     FGCOLOR 4  NO-UNDO.

DEFINE VARIABLE tg-suspenso AS LOGICAL INITIAL yes 
     LABEL "Exceto Cliente Suspenso" 
     VIEW-AS TOGGLE-BOX
     SIZE 21 BY .83
     FGCOLOR 4  NO-UNDO.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-colunas FOR 
      tt-colunas SCROLLING.

DEFINE QUERY br-disp-colunas FOR 
      tt-disp-colunas SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-colunas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-colunas C-Win _FREEFORM
  QUERY br-colunas NO-LOCK DISPLAY
      tt-colunas.coluna FORMAT "x(30)"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS NO-COLUMN-SCROLLING SEPARATORS MULTIPLE SIZE 27 BY 10
         FONT 1 ROW-HEIGHT-CHARS .67 FIT-LAST-COLUMN.

DEFINE BROWSE br-disp-colunas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-disp-colunas C-Win _FREEFORM
  QUERY br-disp-colunas NO-LOCK DISPLAY
      tt-disp-colunas.ordem  FORMAT ">>9"
tt-disp-colunas.coluna FORMAT "x(30)"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-AUTO-VALIDATE NO-ROW-MARKERS NO-COLUMN-SCROLLING SEPARATORS MULTIPLE SIZE 26 BY 10
         FONT 1 ROW-HEIGHT-CHARS .67 FIT-LAST-COLUMN.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-import
     bt-executar AT ROW 14.54 COL 3 HELP
          "Dispara a execuá∆o do relat¢rio"
     bt-cancelar AT ROW 14.54 COL 14 HELP
          "Cancelar"
     bt-ajuda AT ROW 14.54 COL 70 HELP
          "Ajuda"
     RECT-6 AT ROW 13.75 COL 2.14
     RECT-1 AT ROW 14.29 COL 2
     rt-folder-right AT ROW 2.67 COL 80.43
     rt-folder AT ROW 2.5 COL 2
     rt-folder-left AT ROW 2.54 COL 2.14
     rt-folder-top AT ROW 2.54 COL 2.14
     im-pg-par AT ROW 1.5 COL 33.43
     im-pg-sel AT ROW 1.5 COL 17.72
     im-pg-lay AT ROW 1.5 COL 2
     im-pg-log AT ROW 1.5 COL 49.29 WIDGET-ID 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 81 BY 15
         DEFAULT-BUTTON bt-executar.

DEFINE FRAME f-pg-sel
     rs-estab AT ROW 1.54 COL 26.86 NO-LABEL
     fi-data-ini AT ROW 2.46 COL 22 COLON-ALIGNED
     fi-data-fim AT ROW 2.46 COL 42 COLON-ALIGNED NO-LABEL
     fi-repres-ini AT ROW 3.54 COL 24 COLON-ALIGNED
     fi-repres-fim AT ROW 3.54 COL 42 COLON-ALIGNED NO-LABEL
     fi-cliente-ini AT ROW 4.63 COL 25 COLON-ALIGNED
     fi-cliente-fim AT ROW 4.63 COL 42 COLON-ALIGNED NO-LABEL
     fi-ramo-ativ-ini AT ROW 5.71 COL 27.14 COLON-ALIGNED
     fi-ramo-ativ-fim AT ROW 5.71 COL 42 COLON-ALIGNED NO-LABEL
     fi-estado-ini AT ROW 6.75 COL 27.14 COLON-ALIGNED
     fi-estado-fim AT ROW 6.75 COL 42 COLON-ALIGNED NO-LABEL
     fi-cidade-ini AT ROW 7.75 COL 9 COLON-ALIGNED
     fi-cidade-fim AT ROW 7.75 COL 42 COLON-ALIGNED NO-LABEL
     rs-email AT ROW 9.04 COL 24.29 NO-LABEL WIDGET-ID 2
     tg-repres-ima AT ROW 10.25 COL 6
     tg-suspenso AT ROW 10.25 COL 30.14
     tg-repres-dif AT ROW 10.25 COL 52.57 WIDGET-ID 10
     "e-mail:" VIEW-AS TEXT
          SIZE 5 BY .54 AT ROW 9 COL 18 WIDGET-ID 6
     "Estab.:" VIEW-AS TEXT
          SIZE 5 BY .54 AT ROW 1.63 COL 21.14
     IMAGE-D-1 AT ROW 4.63 COL 40.14
     IMAGE-D-2 AT ROW 3.54 COL 40.14
     IMAGE-D-3 AT ROW 7.75 COL 40.14
     IMAGE-D-4 AT ROW 6.75 COL 40.14
     IMAGE-D-5 AT ROW 2.5 COL 40.14
     IMAGE-D-6 AT ROW 5.71 COL 40.14
     IMAGE-E-1 AT ROW 4.63 COL 35
     IMAGE-E-2 AT ROW 3.54 COL 35
     IMAGE-E-3 AT ROW 7.75 COL 35
     IMAGE-E-4 AT ROW 6.75 COL 35
     IMAGE-E-5 AT ROW 2.5 COL 35
     IMAGE-E-6 AT ROW 5.71 COL 35
     RECT-10 AT ROW 1.5 COL 26.14
     RECT-12 AT ROW 8.83 COL 23.29 WIDGET-ID 8
     RECT-14 AT ROW 9.96 COL 3 WIDGET-ID 12
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 2.85
         SIZE 76.86 BY 10.62
         FONT 1.

DEFINE FRAME f-pg-log
     rs-tipo-arquivo AT ROW 2.5 COL 15.57 NO-LABEL
     rs-destino AT ROW 4.5 COL 64 HELP
          "Destino de Impress∆o do Relat¢rio" NO-LABEL
     bt-config-impr-destino AT ROW 4.67 COL 64.14 HELP
          "Configuraá∆o da impressora"
     bt-arquivo-destino AT ROW 4.71 COL 59.14 HELP
          "Escolha do nome do arquivo"
     c-arquivo-destino AT Y 90 X 99 HELP
          "Nome do arquivo de destino do relat¢rio" NO-LABEL
     tg-partir AT ROW 5.79 COL 15.14
     tg-enviar-email AT ROW 7 COL 15.14 WIDGET-ID 10
     fi-remetente AT ROW 7.79 COL 20.57 COLON-ALIGNED WIDGET-ID 12
     fi-assunto AT ROW 8.83 COL 20.57 COLON-ALIGNED WIDGET-ID 2
     bt-imagem AT ROW 9.75 COL 59.14 HELP
          "Escolha do nome do arquivo" WIDGET-ID 6
     fi-imagem AT ROW 9.83 COL 20.57 COLON-ALIGNED WIDGET-ID 4
     text-destino AT ROW 4.04 COL 14.43 NO-LABEL
     "Tipo de arquivo" VIEW-AS TEXT
          SIZE 12 BY .54 AT ROW 1.79 COL 14.43
     RECT-11 AT ROW 2.04 COL 13.14
     RECT-7 AT ROW 4.33 COL 13.14
     RECT-13 AT ROW 7.33 COL 13.14 WIDGET-ID 8
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 76.29 BY 10.46
         FONT 1.

DEFINE FRAME f-pg-par
     br-colunas AT ROW 1.25 COL 5
     br-disp-colunas AT ROW 1.38 COL 43.14
     bt-add-all AT ROW 2.25 COL 36
     bt-pri AT ROW 2.25 COL 71
     bt-add AT ROW 3.25 COL 36
     bt-ant AT ROW 3.25 COL 71
     bt-exc AT ROW 4.5 COL 36
     bt-pro AT ROW 4.5 COL 71
     bt-exc-all AT ROW 5.5 COL 36
     bt-ult AT ROW 5.5 COL 71
     c-arquivo-entrada AT ROW 10.04 COL 17.29 HELP
          "Nome do arquivo de destino do relat¢rio" NO-LABEL
     bt-arquivo-entrada AT ROW 10.04 COL 57.14 HELP
          "Escolha do nome do arquivo"
     text-entrada AT ROW 9 COL 18.14 NO-LABEL
     RECT-8 AT ROW 9.33 COL 16
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 75 BY 10.38
         FONT 1.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-impor
   Allow: Basic,Browse,DB-Fields,Window,Query
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW C-Win ASSIGN
         HIDDEN             = YES
         TITLE              = "<insert window title>"
         HEIGHT             = 15
         WIDTH              = 81.14
         MAX-HEIGHT         = 29
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 29
         VIRTUAL-WIDTH      = 146.29
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB C-Win 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-impor.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW C-Win
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-import
   FRAME-NAME                                                           */
/* SETTINGS FOR IMAGE im-pg-lay IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE RECT-1 IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE RECT-6 IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-left IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-right IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-top IN FRAME f-import
   NO-ENABLE                                                            */
/* SETTINGS FOR FRAME f-pg-log
                                                                        */
/* SETTINGS FOR BUTTON bt-config-impr-destino IN FRAME f-pg-log
   NO-ENABLE                                                            */
ASSIGN 
       bt-config-impr-destino:HIDDEN IN FRAME f-pg-log           = TRUE.

/* SETTINGS FOR BUTTON bt-imagem IN FRAME f-pg-log
   NO-ENABLE 1                                                          */
/* SETTINGS FOR EDITOR c-arquivo-destino IN FRAME f-pg-log
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-assunto IN FRAME f-pg-log
   NO-ENABLE 1                                                          */
/* SETTINGS FOR FILL-IN fi-imagem IN FRAME f-pg-log
   NO-ENABLE 1                                                          */
/* SETTINGS FOR FILL-IN fi-remetente IN FRAME f-pg-log
   NO-ENABLE 1                                                          */
/* SETTINGS FOR RADIO-SET rs-destino IN FRAME f-pg-log
   NO-DISPLAY NO-ENABLE                                                 */
ASSIGN 
       rs-destino:HIDDEN IN FRAME f-pg-log           = TRUE.

/* SETTINGS FOR FILL-IN text-destino IN FRAME f-pg-log
   NO-DISPLAY NO-ENABLE ALIGN-L                                         */
ASSIGN 
       text-destino:PRIVATE-DATA IN FRAME f-pg-log     = 
                "Destino".

/* SETTINGS FOR FRAME f-pg-par
                                                                        */
/* BROWSE-TAB br-colunas RECT-8 f-pg-par */
/* BROWSE-TAB br-disp-colunas br-colunas f-pg-par */
/* SETTINGS FOR BUTTON bt-arquivo-entrada IN FRAME f-pg-par
   NO-ENABLE                                                            */
ASSIGN 
       bt-arquivo-entrada:HIDDEN IN FRAME f-pg-par           = TRUE.

/* SETTINGS FOR EDITOR c-arquivo-entrada IN FRAME f-pg-par
   NO-DISPLAY NO-ENABLE                                                 */
ASSIGN 
       c-arquivo-entrada:HIDDEN IN FRAME f-pg-par           = TRUE.

/* SETTINGS FOR RECTANGLE RECT-8 IN FRAME f-pg-par
   NO-ENABLE                                                            */
ASSIGN 
       RECT-8:HIDDEN IN FRAME f-pg-par           = TRUE.

/* SETTINGS FOR FILL-IN text-entrada IN FRAME f-pg-par
   NO-DISPLAY NO-ENABLE ALIGN-L                                         */
ASSIGN 
       text-entrada:HIDDEN IN FRAME f-pg-par           = TRUE
       text-entrada:PRIVATE-DATA IN FRAME f-pg-par     = 
                "Arquivo de Entrada".

/* SETTINGS FOR FRAME f-pg-sel
                                                                        */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
THEN C-Win:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-colunas
/* Query rebuild information for BROWSE br-colunas
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-colunas SHARE-LOCK BY tt-colunas.ordem INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-colunas */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-disp-colunas
/* Query rebuild information for BROWSE br-disp-colunas
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-disp-colunas  SHARE-LOCK BY tt-disp-colunas.ordem INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-disp-colunas */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-log
/* Query rebuild information for FRAME f-pg-log
     _Query            is NOT OPENED
*/  /* FRAME f-pg-log */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-sel
/* Query rebuild information for FRAME f-pg-sel
     _Query            is NOT OPENED
*/  /* FRAME f-pg-sel */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON END-ERROR OF C-Win /* <insert window title> */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON WINDOW-CLOSE OF C-Win /* <insert window title> */
DO:
  /* This event will close the window and terminate the procedure.  */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME bt-add
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-add C-Win
ON CHOOSE OF bt-add IN FRAME f-pg-par /* bt-add */
DO:
    ASSIGN ordem = 0.
    FOR EACH tt-disp-colunas BREAK BY tt-disp-colunas.ordem.
        ASSIGN ordem = tt-disp-colunas.ordem.
    END.
    ASSIGN var-qtsel = br-colunas:NUM-SELECTED-ROWS.
    ASSIGN ordem = ordem + 1.
    DO i-ct = 1 TO br-colunas:NUM-SELECTED-ROWS.
      IF br-colunas:FETCH-SELECTED-ROW(i-ct) THEN DO:
         CREATE tt-disp-colunas.
         ASSIGN tt-disp-colunas.ordem  = ordem + var-qtsel - i-ct
                tt-disp-colunas.coluna = tt-colunas.coluna.
         DELETE tt-colunas.
      END.
    END.
    
    {&OPEN-QUERY-br-disp-colunas}      
    {&OPEN-QUERY-br-colunas}
    
    IF AVAIL tt-colunas THEN
    br-colunas:SELECT-ROW (1).
    ELSE 
        /*REPOSITION br-disp-colunas BACKWARDS INPUT 1.*/
    br-disp-colunas:SELECT-ROW (1).

    

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-add-all
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-add-all C-Win
ON CHOOSE OF bt-add-all IN FRAME f-pg-par /* bt-add-all */
DO:
  FOR EACH tt-colunas NO-LOCK.
      CREATE tt-disp-colunas.
      ASSIGN ordem = ordem + 1
             tt-disp-colunas.ordem  = ordem
             tt-disp-colunas.coluna = tt-colunas.coluna.
  END.
  EMPTY TEMP-TABLE tt-colunas.
  {&OPEN-QUERY-br-disp-colunas}      
  {&OPEN-QUERY-br-colunas}
  
  br-disp-colunas:SELECT-ALL.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-import
&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda C-Win
ON CHOOSE OF bt-ajuda IN FRAME f-import /* Ajuda */
DO:
   {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME bt-ant
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ant C-Win
ON CHOOSE OF bt-ant IN FRAME f-pg-par /* bt-ant */
DO:
  EMPTY TEMP-TABLE tt-axi.
  DO i-ct = 1 TO br-disp-colunas:NUM-SELECTED-ROWS.
      IF br-disp-colunas:FETCH-SELECTED-ROW(i-ct) THEN DO:
         CREATE tt-axi.
         ASSIGN tt-axi.ordem  = tt-disp-colunas.ordem - 1 
                tt-axi.ordem  = tt-disp-colunas.ordem WHEN tt-disp-colunas.ordem = 1 
                tt-axi.coluna = tt-disp-colunas.coluna.
         DELETE tt-disp-colunas.
      END.
  END.
    
    FOR EACH tt-axi NO-LOCK BREAK BY tt-axi.ordem.
        FIND tt-disp-colunas WHERE tt-disp-colunas.ordem = tt-axi.ordem SHARE-LOCK NO-ERROR.
        IF AVAIL tt-disp-colunas THEN
            ASSIGN tt-disp-colunas.ordem  = tt-disp-colunas.ordem + 1.
        CREATE tt-disp-colunas.
        ASSIGN tt-disp-colunas.ordem  = tt-axi.ordem 
               tt-disp-colunas.coluna = tt-axi.coluna.
    END.

    {&OPEN-QUERY-br-disp-colunas}      
    {&OPEN-QUERY-br-colunas}
     /*br-disp-colunas:SELECT-ROW (1).*/
     FOR EACH tt-axi NO-LOCK.
        br-disp-colunas:SELECT-ROW (tt-axi.ordem).
    END.
    
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-log
&Scoped-define SELF-NAME bt-arquivo-destino
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-arquivo-destino C-Win
ON CHOOSE OF bt-arquivo-destino IN FRAME f-pg-log
DO:
    {include/i-imarq.i c-arquivo-destino f-pg-log}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME bt-arquivo-entrada
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-arquivo-entrada C-Win
ON CHOOSE OF bt-arquivo-entrada IN FRAME f-pg-par
DO:
    {include/i-imarq.i c-arquivo-entrada f-pg-par}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-import
&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar C-Win
ON CHOOSE OF bt-cancelar IN FRAME f-import /* Cancelar */
DO:
   apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-log
&Scoped-define SELF-NAME bt-config-impr-destino
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-config-impr-destino C-Win
ON CHOOSE OF bt-config-impr-destino IN FRAME f-pg-log
DO:
   {include/i-imimp.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME bt-exc
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exc C-Win
ON CHOOSE OF bt-exc IN FRAME f-pg-par /* bt-exc */
DO:
    DO i-ct = 1 TO br-disp-colunas:NUM-SELECTED-ROWS.
      IF br-disp-colunas:FETCH-SELECTED-ROW(i-ct) THEN DO:
         CREATE tt-colunas.
         ASSIGN tt-colunas.coluna = tt-disp-colunas.coluna.
         DELETE tt-disp-colunas.
      END.
    END.
    ASSIGN ordem = 0.
    FOR EACH tt-disp-colunas SHARE-LOCK BREAK BY tt-disp-colunas.ordem.
        ASSIGN ordem = ordem + 1
               tt-disp-colunas.ordem  = ordem.
    END.

    {&OPEN-QUERY-br-disp-colunas}      
    {&OPEN-QUERY-br-colunas}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-exc-all
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exc-all C-Win
ON CHOOSE OF bt-exc-all IN FRAME f-pg-par /* bt-exc-all */
DO:
  FOR EACH tt-disp-colunas NO-LOCK.
      CREATE tt-colunas.
      ASSIGN tt-colunas.coluna = tt-disp-colunas.coluna.
  END.
  EMPTY TEMP-TABLE tt-disp-colunas.
  ASSIGN ordem = 0.
  {&OPEN-QUERY-br-disp-colunas}      
  {&OPEN-QUERY-br-colunas}

  br-colunas:SELECT-ALL.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-import
&Scoped-define SELF-NAME bt-executar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-executar C-Win
ON CHOOSE OF bt-executar IN FRAME f-import /* Executar */
DO:
   do  on error undo, return no-apply:
       FIND tt-disp-colunas WHERE tt-disp-colunas.ordem = 1 NO-LOCK NO-ERROR.
       IF AVAIL tt-disp-colunas THEN
          run pi-executar.
       ELSE
           MESSAGE "Nenhuma Coluna Foi Selecionada"
               VIEW-AS ALERT-BOX ERROR BUTTONS OK.
   end.
   EMPTY TEMP-TABLE tt-conteudo.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-log
&Scoped-define SELF-NAME bt-imagem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imagem C-Win
ON CHOOSE OF bt-imagem IN FRAME f-pg-log
DO:
    SYSTEM-DIALOG GET-FILE diretorio-imagem
       TITLE      "Informe Arquivo Texto para Importar..."
       FILTERS    "Imagem (.gif,.jpg,.png)" "*.gif, *.jpg, *.png",
                  /*"Linguagem de Marcaá∆o de Hipertexto (.html,.htm,.*)" "*.html, *.htm",*/
                  "Todos programas" "*.*"
       MUST-EXIST
       USE-FILENAME
       UPDATE OKpressed.

   IF OKpressed = NO OR diretorio-imagem = '' THEN
      NEXT.
   ELSE DO:
      ASSIGN fi-imagem:SCREEN-VALUE IN FRAME f-pg-log = diretorio-imagem.
      
   END.
   
      
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-par
&Scoped-define SELF-NAME bt-pri
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-pri C-Win
ON CHOOSE OF bt-pri IN FRAME f-pg-par /* bt-pri */
DO:
  EMPTY TEMP-TABLE tt-axi.
  DO i-ct = 1 TO br-disp-colunas:NUM-SELECTED-ROWS.
      IF br-disp-colunas:FETCH-SELECTED-ROW(i-ct) THEN DO:
         CREATE tt-axi.
         ASSIGN tt-axi.ordem  = i-ct
                tt-axi.coluna = tt-disp-colunas.coluna
                ordem = i-ct.
         DELETE tt-disp-colunas.
      END.
  END.
    
    FOR EACH tt-disp-colunas SHARE-LOCK BREAK BY tt-disp-colunas.ordem.
        ASSIGN ordem = ordem + 1
               tt-disp-colunas.ordem  = ordem.
    END.
    FOR EACH tt-axi NO-LOCK.
        CREATE tt-disp-colunas.
        ASSIGN tt-disp-colunas.ordem  = tt-axi.ordem  
               tt-disp-colunas.coluna = tt-axi.coluna.
    END.
     

    {&OPEN-QUERY-br-disp-colunas}      
    {&OPEN-QUERY-br-colunas}
     br-disp-colunas:SELECT-ROW (1).
    /*FOR EACH tt-axi NO-LOCK.
        br-disp-colunas:SELECT-ROW (tt-axi.ordem).
    END.*/
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-pro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-pro C-Win
ON CHOOSE OF bt-pro IN FRAME f-pg-par /* bt-pro */
DO:
  ASSIGN ordem = 0.
  FOR EACH tt-disp-colunas BREAK BY tt-disp-colunas.ordem.
      ASSIGN ordem = tt-disp-colunas.ordem.
  END.
  ASSIGN var-qtsel = br-colunas:NUM-SELECTED-ROWS.
  
  EMPTY TEMP-TABLE tt-axi.

  DO i-ct = 1 TO br-disp-colunas:NUM-SELECTED-ROWS.
      IF br-disp-colunas:FETCH-SELECTED-ROW(i-ct) THEN DO:
         CREATE tt-axi.
         ASSIGN tt-axi.ordem  = tt-disp-colunas.ordem + 1
                tt-axi.coluna = tt-disp-colunas.coluna.
         DELETE tt-disp-colunas.
      END.
  END.
    
    FOR EACH tt-axi NO-LOCK BREAK BY tt-axi.ordem DESC.
        FIND tt-disp-colunas WHERE tt-disp-colunas.ordem = tt-axi.ordem SHARE-LOCK NO-ERROR.
        IF AVAIL tt-disp-colunas THEN
            ASSIGN tt-disp-colunas.ordem  = tt-disp-colunas.ordem - 1.
        CREATE tt-disp-colunas.
        ASSIGN tt-disp-colunas.ordem  = tt-axi.ordem 
               tt-disp-colunas.coluna = tt-axi.coluna.
    END.
    ASSIGN ordem = 0.
    FOR EACH tt-disp-colunas SHARE-LOCK BREAK BY tt-disp-colunas.ordem.
      ASSIGN ordem = ordem + 1
             tt-disp-colunas.ordem  = ordem.
    END.

    FOR EACH tt-disp-colunas.
        FIND tt-axi WHERE tt-axi.coluna = tt-disp-colunas.coluna NO-LOCK NO-ERROR.
        IF AVAIL tt-axi THEN
           ASSIGN tt-axi.ordem = tt-disp-colunas.ordem.

    END.

    {&OPEN-QUERY-br-disp-colunas}      
     /*br-disp-colunas:REFRESH().*/
    {&OPEN-QUERY-br-colunas}

    /*REPOSITION-TO-ROWID(tt-disp-colunas.coluna)*/
     /*br-disp-colunas:SELECT-ROW (1).*/
    FOR EACH tt-axi NO-LOCK BREAK BY tt-axi.ordem DESC.
       /* br-disp-colunas:REPOSITION-TO-ROW(tt-axi.ordem).*/
        br-disp-colunas:SELECT-ROW (tt-axi.ordem).   
        /*br-disp-colunas:SELECT-PREV-ROW ().*/
        
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ult
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ult C-Win
ON CHOOSE OF bt-ult IN FRAME f-pg-par /* bt-ult */
DO:
  EMPTY TEMP-TABLE tt-axi.

  DO i-ct = 1 TO br-disp-colunas:NUM-SELECTED-ROWS.
      IF br-disp-colunas:FETCH-SELECTED-ROW(i-ct) THEN DO:
         CREATE tt-axi.
         ASSIGN tt-axi.ordem  = i-ct
                tt-axi.coluna = tt-disp-colunas.coluna.
                
         DELETE tt-disp-colunas.
      END.
  END.
  ASSIGN ordem = 0.
  FOR EACH tt-disp-colunas SHARE-LOCK BREAK BY tt-disp-colunas.ordem.
      ASSIGN ordem = ordem + 1
             tt-disp-colunas.ordem  = ordem.
  END.
  FOR EACH tt-axi NO-LOCK.
      CREATE tt-disp-colunas.
      ASSIGN ordem = ordem + 1
             tt-disp-colunas.ordem  = ordem   
             tt-disp-colunas.coluna = tt-axi.coluna
             tt-axi.ordem  = ordem.
  END.

  {&OPEN-QUERY-br-disp-colunas}      
  {&OPEN-QUERY-br-colunas}
  
  br-disp-colunas:SELECT-ROW (1).
  /*FOR EACH tt-axi NO-LOCK.
      br-disp-colunas:SELECT-ROW (ordem).
  END.*/
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-sel
&Scoped-define SELF-NAME fi-cidade-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cidade-ini C-Win
ON LEAVE OF fi-cidade-ini IN FRAME f-pg-sel /* Cidade */
DO:
  IF SELF:SCREEN-VALUE = "" THEN
     ASSIGN fi-cidade-fim:SCREEN-VALUE IN FRAME f-pg-sel = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz".
  ELSE
     ASSIGN fi-cidade-fim:SCREEN-VALUE IN FRAME f-pg-sel = SELF:SCREEN-VALUE.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-cliente-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-cliente-ini C-Win
ON LEAVE OF fi-cliente-ini IN FRAME f-pg-sel /* Cliente */
DO:
  IF SELF:SCREEN-VALUE = "0" THEN
     ASSIGN fi-cliente-fim:SCREEN-VALUE IN FRAME f-pg-sel = "999999".
  ELSE
     ASSIGN fi-cliente-fim:SCREEN-VALUE IN FRAME f-pg-sel = SELF:SCREEN-VALUE.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-estado-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-estado-ini C-Win
ON LEAVE OF fi-estado-ini IN FRAME f-pg-sel /* Uf */
DO:
  IF SELF:SCREEN-VALUE = "" THEN
     ASSIGN fi-estado-fim:SCREEN-VALUE IN FRAME f-pg-sel = "zz".
  ELSE
     ASSIGN fi-estado-fim:SCREEN-VALUE IN FRAME f-pg-sel = SELF:SCREEN-VALUE.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-ramo-ativ-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-ramo-ativ-ini C-Win
ON LEAVE OF fi-ramo-ativ-ini IN FRAME f-pg-sel /* Ramo Ativ */
DO:
  IF SELF:SCREEN-VALUE = "0" THEN
     ASSIGN fi-ramo-ativ-fim:SCREEN-VALUE IN FRAME f-pg-sel = "999".
  ELSE
     ASSIGN fi-ramo-ativ-fim:SCREEN-VALUE IN FRAME f-pg-sel = SELF:SCREEN-VALUE.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi-repres-ini
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi-repres-ini C-Win
ON LEAVE OF fi-repres-ini IN FRAME f-pg-sel /* Repres */
DO:
  IF SELF:SCREEN-VALUE = "0" THEN
     ASSIGN fi-repres-fim:SCREEN-VALUE IN FRAME f-pg-sel = "9999999".
  ELSE
     ASSIGN fi-repres-fim:SCREEN-VALUE IN FRAME f-pg-sel = SELF:SCREEN-VALUE.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-import
&Scoped-define SELF-NAME im-pg-lay
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-lay C-Win
ON MOUSE-SELECT-CLICK OF im-pg-lay IN FRAME f-import
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-log
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-log C-Win
ON MOUSE-SELECT-CLICK OF im-pg-log IN FRAME f-import
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-par
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-par C-Win
ON MOUSE-SELECT-CLICK OF im-pg-par IN FRAME f-import
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-sel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-sel C-Win
ON MOUSE-SELECT-CLICK OF im-pg-sel IN FRAME f-import
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-log
&Scoped-define SELF-NAME rs-destino
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-destino C-Win
ON VALUE-CHANGED OF rs-destino IN FRAME f-pg-log
DO:
do  with frame f-pg-log:
    case self:screen-value:
        when "1" then do:
            assign c-arquivo-destino:sensitive     = no
                   bt-arquivo-destino:visible      = no
                   bt-config-impr-destino:visible  = yes.
        end.
        when "2" then do:
            assign c-arquivo-destino:sensitive     = yes
                   bt-arquivo-destino:visible      = yes
                   bt-config-impr-destino:visible  = no.
        end.
        when "3" then do:
            assign c-arquivo-destino:sensitive     = no
                   bt-arquivo-destino:visible      = no
                   bt-config-impr-destino:visible  = no.
        end.
    end case.
end.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-tipo-arquivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-tipo-arquivo C-Win
ON VALUE-CHANGED OF rs-tipo-arquivo IN FRAME f-pg-log
DO:
  IF INPUT FRAME f-pg-log rs-tipo-arquivo = 1 THEN DO:
     ENABLE c-arquivo-destino WITH FRAME f-pg-log.
  END.
  ELSE 
     DISABLE c-arquivo-destino WITH FRAME f-pg-log.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-enviar-email
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-enviar-email C-Win
ON VALUE-CHANGED OF tg-enviar-email IN FRAME f-pg-log /* Enviar e-mail */
DO:
  IF INPUT FRAME f-pg-log tg-enviar-email THEN DO:
       ENABLE {&list-1} WITH FRAME f-pg-log.
  END.
  ELSE 
      DISABLE {&list-1} WITH FRAME f-pg-log.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-partir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-partir C-Win
ON VALUE-CHANGED OF tg-partir IN FRAME f-pg-log /* Separar por Representante */
DO:
  IF INPUT FRAME f-pg-log tg-partir THEN DO:
       ENABLE c-arquivo-destino WITH FRAME f-pg-log.
  END.
  ELSE 
      IF INPUT FRAME f-pg-log rs-tipo-arquivo = 2 THEN
         DISABLE c-arquivo-destino WITH FRAME f-pg-log.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-import
&Scoped-define BROWSE-NAME br-colunas
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK C-Win 


/* ***************************  Main Block  *************************** */

/* Set CURRENT-WINDOW: this will parent dialog-boxes and frames.        */
ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME} 
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.

/* {utp/ut9000.i "mala_direta" "2.04.00.001"} */

/*:T inicializaá‰es do template de importaá∆o */
{include/i-imini.i}

/* The CLOSE event can be used from inside or outside the procedure to  */
/* terminate it.                                                        */
ON CLOSE OF THIS-PROCEDURE 
   RUN disable_UI.

{include/i-imlbl.i}

/* Best default for GUI applications is...                              */
PAUSE 0 BEFORE-HIDE.

/* Now enable the interface and wait for the exit condition.            */
/* (NOTE: handle ERROR and END-KEY so cleanup code will always fire.    */

MAIN-BLOCK:
DO  ON ERROR   UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK
    ON END-KEY UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK:
    
    /*ASSIGN fi-data-ini = date(MONTH(TODAY) - 3,01,YEAR(TODAY)).*/
    ASSIGN fi-data-fim = TODAY.

    RUN enable_UI.
  
    APPLY "VALUE-CHANGED" TO rs-tipo-arquivo IN FRAME f-pg-log.
    APPLY "VALUE-CHANGED" TO tg-partir IN FRAME f-pg-log.
    
    {include/i-immbl.i}

    /*{include/i-imvrf.i &programa=XX9999 &versao-layout=001}*/
    IF  NOT THIS-PROCEDURE:PERSISTENT THEN
        WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects C-Win  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available C-Win  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI C-Win  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
  THEN DELETE WIDGET C-Win.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI C-Win  _DEFAULT-ENABLE
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
  ENABLE im-pg-par im-pg-sel im-pg-log bt-executar bt-cancelar bt-ajuda 
      WITH FRAME f-import IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-import}
  DISPLAY rs-estab fi-data-ini fi-data-fim fi-repres-ini fi-repres-fim 
          fi-cliente-ini fi-cliente-fim fi-ramo-ativ-ini fi-ramo-ativ-fim 
          fi-estado-ini fi-estado-fim fi-cidade-ini fi-cidade-fim rs-email 
          tg-repres-ima tg-suspenso tg-repres-dif 
      WITH FRAME f-pg-sel IN WINDOW C-Win.
  ENABLE IMAGE-D-1 IMAGE-D-2 IMAGE-D-3 IMAGE-D-4 IMAGE-D-5 IMAGE-D-6 IMAGE-E-1 
         IMAGE-E-2 IMAGE-E-3 IMAGE-E-4 IMAGE-E-5 IMAGE-E-6 RECT-10 RECT-12 
         RECT-14 rs-estab fi-data-ini fi-data-fim fi-repres-ini fi-repres-fim 
         fi-cliente-ini fi-cliente-fim fi-ramo-ativ-ini fi-ramo-ativ-fim 
         fi-estado-ini fi-estado-fim fi-cidade-ini fi-cidade-fim rs-email 
         tg-repres-ima tg-suspenso tg-repres-dif 
      WITH FRAME f-pg-sel IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-sel}
  DISPLAY rs-tipo-arquivo c-arquivo-destino tg-partir tg-enviar-email 
          fi-remetente fi-assunto fi-imagem 
      WITH FRAME f-pg-log IN WINDOW C-Win.
  ENABLE RECT-11 RECT-7 RECT-13 rs-tipo-arquivo bt-arquivo-destino tg-partir 
         tg-enviar-email 
      WITH FRAME f-pg-log IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-log}
  ENABLE br-colunas br-disp-colunas bt-add-all bt-pri bt-add bt-ant bt-exc 
         bt-pro bt-exc-all bt-ult 
      WITH FRAME f-pg-par IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-par}
  VIEW C-Win.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit C-Win 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-conecta-bancos C-Win 
PROCEDURE pi-conecta-bancos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/*IF base = "ima-teste" OR base = "med-teste" THEN DO.
    /*IF NOT CONNECTED ("IMA") THEN 
       CONNECT -db ems204ima -ld ima -H 192.168.0.13 -S 40300 -N TCP.
    IF NOT CONNECTED ("MED") THEN
       CONNECT -db ems204med -ld med -H 192.168.0.13 -S 40500 -N TCP.*/
    IF NOT CONNECTED ("IMA") THEN 
       CONNECT -db ems204ima -ld ima -H 192.168.0.13 -S 30300 -N TCP.
    IF NOT CONNECTED ("MED") THEN
       CONNECT -db ems204med -ld med -H 192.168.0.13 -S 30400 -N TCP.
END.
ELSE DO.
    IF NOT CONNECTED ("IMA") THEN 
       CONNECT -db ems204ima -ld ima -H 192.168.0.3 -S 30100 -N TCP.
    IF NOT CONNECTED ("MED") THEN
       CONNECT -db ems204med -ld med -H 192.168.0.3 -S 32000 -N TCP.
END.*/
/* RUN esapi/connect.p (input no). Alterado connect.p por M·rcio em 21/11/2013 */
 RUN esapi/connect-ima-med.p.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-desconecta-bancos C-Win 
PROCEDURE pi-desconecta-bancos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    IF CONNECTED ("dbaux") THEN 
       DISCONNECT dbaux.
    IF CONNECTED ("dbaux") THEN
       DISCONNECT dbaux.
    

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-envia-email C-Win 
PROCEDURE pi-envia-email :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
ASSIGN diretorio-imagem = fi-imagem:SCREEN-VALUE IN FRAME f-pg-log.

REPEAT:
    IF INDEX(diretorio-imagem,"/",index-barra + 1) > 0 THEN
       ASSIGN index-barra = INDEX(diretorio-imagem,"/",index-barra + 1).
    ELSE 
       IF INDEX(diretorio-imagem,"\",index-barra + 1) > 0 THEN
          ASSIGN index-barra = INDEX(diretorio-imagem,"\",index-barra + 1).
       ELSE 
          LEAVE.
END.
      
ASSIGN nome-imagem = substring(diretorio-imagem,index-barra + 1,INDEX(diretorio-imagem,".",index-barra)).


ASSIGN qt-email-enviado = 0.

run utp/ut-acomp.p persistent set h-acomp.
{utp/ut-liter.i Enviando Email *}
run pi-inicializar in h-acomp (input RETURN-VALUE).

ASSIGN diretorio-html = session:TEMP-DIRECTORY + "email.html".
OUTPUT TO value(diretorio-html).

/* PUT UNFORMAT
'<HTML>                                                                                 ' skip
'<HEAD>                                                                                 ' skip
'     <TITLE>Convite GO Digital</TITLE>                                                 ' skip
'     <META http-equiv="Content-Type" Content="text/html; charset=utf-8">               ' skip
'</HEAD>                                                                                ' skip
'<BODY>                                                                                 ' skip
/*'<DIV STYLE="position: absolute; left: 0px; top:0px; width: 400px; height: 600px;">     ' SKIP
'<IMG SRC="cid:' nome-imagem '" HEIGHT=600 WIDTH=400 ALIGN=TOP BORDER=0>                ' skip
'    </DIV>                                                                             ' SKIP */
'<DIV> <center> <IMG SRC=http://www.imatextil.com.br/static/img/logo-share.png BORDER=0> <br> www.imatextil.com.br <center></DIV>' SKIP 
'</BODY>                                                                                ' skip
'</HTML>                                                                                '. */
                                                                                        
PUT UNFORMAT
'<HTML>                                                                                             ' skip
'<HEAD>                                                                                             ' skip
'     <TITLE>Nota para clientes</TITLE>                                                             ' skip
'     <META http-equiv="Content-Type" Content="text/html; charset=utf-8">                           ' skip
'</HEAD>                                                                                            ' skip
'<BODY>                                                                                             ' skip
'<DIV> <center> <IMG SRC="cid:' nome-imagem '" BORDER=0> <br> www.imatextil.com.br <center></DIV>   ' SKIP 
'</BODY>                                                                                            ' skip
'</HTML>                                                                                            '.

OUTPUT CLOSE.

FOR EACH tt-conteudo WHERE tt-conteudo.email <> "".

    RUN  pi-acompanhar IN  h-acomp (INPUT string(qt-email-enviado) + " Enviando email para:" + string(tt-conteudo.cod-emitente) + " - " + tt-conteudo.emai).
    RUN esapi/email-envia.p (INPUT INPUT FRAME f-pg-log fi-remetente ,  /* Remetente                */
                             INPUT tt-conteudo.email                 ,  /* Destinatario             */
                             INPUT ""                                ,  /* Com copia                */
                             INPUT ""                                ,  /* Com copia oculta         */
                             INPUT INPUT FRAME f-pg-log fi-assunto   ,  /* Assunto                  */
                             INPUT ""                                ,  /* Mensagem em txt          */
                             INPUT diretorio-html                    ,  /* Mensagen em arquivo html */
                             INPUT ""                                ,  /* Anexo                    */
                             INPUT INPUT FRAME f-pg-log fi-imagem    ,  /* Anexo embutido           */
                             OUTPUT email-enviado                       /* Confirmaá∆o de email     */).
    
    IF email-enviado THEN
       ASSIGN qt-email-enviado = qt-email-enviado + 1.     
END.

run pi-finalizar in h-acomp.

MESSAGE "Foram enviados " qt-email-enviado " emails"
    VIEW-AS ALERT-BOX INFO BUTTONS OK.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-executar C-Win 
PROCEDURE pi-executar :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    EMPTY TEMP-TABLE tt-sel.
    
    CREATE tt-sel.
    
    ASSIGN tt-sel.fi-data-ini      = INPUT FRAME f-pg-sel fi-data-ini
           tt-sel.fi-data-fim      = INPUT FRAME f-pg-sel fi-data-fim
           tt-sel.fi-cliente-ini   = INPUT FRAME f-pg-sel fi-cliente-ini
           tt-sel.fi-cliente-fim   = INPUT FRAME f-pg-sel fi-cliente-fim
           tt-sel.fi-repres-ini    = INPUT FRAME f-pg-sel fi-repres-ini
           tt-sel.fi-repres-fim    = INPUT FRAME f-pg-sel fi-repres-fim
           tt-sel.fi-cidade-ini    = INPUT FRAME f-pg-sel fi-cidade-ini
           tt-sel.fi-cidade-fim    = INPUT FRAME f-pg-sel fi-cidade-fim
           tt-sel.fi-estado-ini    = INPUT FRAME f-pg-sel fi-estado-ini
           tt-sel.fi-estado-fim    = INPUT FRAME f-pg-sel fi-estado-fim
           tt-sel.fi-ramo-ativ-ini = INPUT FRAME f-pg-sel fi-ramo-ativ-ini
           tt-sel.fi-ramo-ativ-fim = INPUT FRAME f-pg-sel fi-ramo-ativ-fim
           tt-sel.rs-email         = INPUT FRAME f-pg-sel rs-email
           tt-sel.rs-estab         = INPUT FRAME f-pg-sel rs-estab     
           tt-sel.tg-repres-ima    = INPUT FRAME f-pg-sel tg-repres-ima
           tt-sel.tg-repres-dif    = INPUT FRAME f-pg-sel tg-repres-dif 
           tt-sel.tg-suspenso      = IF INPUT FRAME f-pg-sel tg-suspenso THEN 4 ELSE 0
           var-tg-partir           = INPUT FRAME f-pg-log tg-partir.
           
   
   ASSIGN salvar-como = "".

   RUN pi-conecta-bancos.
   RUN esrp/mala_diretarp.p.
   RUN pi-desconecta-bancos.

   ASSIGN qtclientes = 0.    
   FOR EACH tt-conteudo NO-LOCK.
       ASSIGN qtclientes = qtclientes + 1.
   END.

   IF qtclientes <> 0 THEN DO:
    /* Define diretorio para salvar */
      ASSIGN caminho = SESSION:TEMP-DIRECTORY.
      ASSIGN SUBSTRING(caminho,3,1) = "\".
      DO i = 1 to LENGTH(caminho):
         IF SUBSTRING(caminho,i,1) = "\" OR SUBSTRING(caminho,i,1) = "/" THEN
            barra = i.
         IF SUBSTRING(caminho,i,1) = "." THEN
            ponto = i.
      END.
      ASSIGN nome-arquivo = SUBSTRING(caminho ,barra + 1 ,ponto - barra - 1)
             caminho = SUBSTRING(caminho ,1 ,barra).

      /* Imprimir relatorio */
      IF INPUT FRAME f-pg-log rs-tipo-arquivo = 1 THEN
         RUN esrp/mala_direta_xls.p.
      ELSE
         RUN esrp/mala_direta_txt.p.

      /* Mensagens de conclus∆o*/
      IF INPUT FRAME f-pg-log tg-enviar-email = NO THEN DO:
          IF (INPUT FRAME f-pg-log tg-partir) THEN
              MESSAGE "Foram encontrados " + string(qtclientes) + " clientes." SKIP(1)
                      'Os arquivos foram salvos em: "' + caminho + '"'
                      VIEW-AS ALERT-BOX INFO BUTTONS OK.
          ELSE 
              MESSAGE "Foram encontrados " + string(qtclientes) + " clientes." SKIP(1)
                      /*'O arquivo foi salvo em: "' + salvar-como + '"'*/
                      VIEW-AS ALERT-BOX INFO BUTTONS OK.
      END.

      /* Criar log */
      ASSIGN salvar-como = SUBSTRING(STRING(TIME,"HH:MM:SS"),1,2) + "h" + SUBSTRING(STRING(TIME,"HH:MM:SS"),4,2) + "m" + SUBSTRING(STRING(TIME,"HH:MM:SS"),7,2) + "s".
      ASSIGN salvar-como = caminho + "Config-MD-" + string(day(NOW)) + "-" + string(MONTH(NOW)) + "-" + string(YEAR(NOW))  + " " + salvar-como + ".txt".
      OUTPUT TO VALUE(salvar-como).
         PUT UNFORMAT "Data ini: "         INPUT FRAME f-pg-sel fi-data-ini             FORMAT "99/99/9999"    SKIP
                      "Data fim: "         INPUT FRAME f-pg-sel fi-data-fim             FORMAT "99/99/9999"    SKIP
                      "Cliente ini: "      TRIM(INPUT FRAME f-pg-sel fi-cliente-ini   )                        SKIP
                      "Cliente fim: "      TRIM(INPUT FRAME f-pg-sel fi-cliente-fim   )                        SKIP
                      "Repres ini: "       TRIM(INPUT FRAME f-pg-sel fi-repres-ini    )                        SKIP
                      "Repres fim: "       TRIM(INPUT FRAME f-pg-sel fi-repres-fim    )                        SKIP
                      "Cidade ini: "       TRIM(INPUT FRAME f-pg-sel fi-cidade-ini    )                        SKIP
                      "Cidade fim: "       TRIM(INPUT FRAME f-pg-sel fi-cidade-fim    )                        SKIP
                      "Estado ini: "       TRIM(INPUT FRAME f-pg-sel fi-estado-ini    )                        SKIP
                      "Estado fim: "       TRIM(INPUT FRAME f-pg-sel fi-estado-fim    )                        SKIP
                      "Ramo Ativ ini: "    TRIM(INPUT FRAME f-pg-sel fi-ramo-ativ-ini )                        SKIP
                      "Ramo Ativ fim: "    TRIM(INPUT FRAME f-pg-sel fi-ramo-ativ-fim )                        SKIP
                      "Estab: "            TRIM(INPUT FRAME f-pg-sel rs-estab         )                        SKIP
                      "Repres ima: "       TRIM(INPUT FRAME f-pg-sel tg-repres-ima    )                        SKIP
                      "Suspenso: "         TRIM(INPUT FRAME f-pg-sel tg-suspenso      )                        SKIP
                      "e-mail: "           IF (INPUT FRAME f-pg-sel rs-email = 1) THEN "Todos" ELSE IF (INPUT FRAME f-pg-sel rs-email = 2) THEN "Com e-mail" ELSE "Sem e-mail"  SKIP(1)
                      
                      "Tipo Arquivo: "     IF (INPUT FRAME f-pg-log rs-tipo-arquivo = 1) THEN "txt" ELSE "xls" SKIP
                      "Partir: "           TRIM(INPUT FRAME f-pg-log tg-partir        )                        SKIP
                      "Arquivo Destino: "  SUBSTRING(TRIM(INPUT FRAME f-pg-log c-arquivo-destino),1,LENGTH(TRIM(INPUT FRAME f-pg-log c-arquivo-destino)) - 3) IF (INPUT FRAME f-pg-log rs-tipo-arquivo = 1) THEN "txt" ELSE "xls"                     SKIP 
                      "Data: "             TODAY                                        FORMAT "99/99/9999" SKIP
                      "Hora: "             STRING(TIME,"HH:MM:SS")                                          SKIP
                      "Quantidade de clientes: " string(qtclientes)                                         SKIP(2)
                      "Campos"                                                                              SKIP
                      "--------------------------------------------------------------"                      SKIP.
             FOR EACH tt-disp-colunas NO-LOCK BREAK BY tt-disp-colunas.ordem.
                 PUT TRIM(tt-disp-colunas.coluna) " | ".
             END.
      OUTPUT CLOSE.
      IF INPUT FRAME f-pg-log tg-enviar-email THEN
         RUN pi-envia-email.

   END.
   ELSE DO:
        MESSAGE "Nenhum registro encontrado."
                VIEW-AS ALERT-BOX INFO BUTTONS OK.  
   END.                                                                                  
   
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-troca-pagina C-Win 
PROCEDURE pi-troca-pagina :
/*:T------------------------------------------------------------------------------
  Purpose: Gerencia a Troca de P†gina (folder)   
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

{include/i-imtrp.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records C-Win  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-disp-colunas"}
  {src/adm/template/snd-list.i "tt-colunas"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed C-Win 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
  /*
  run pi-trata-state (p-issuer-hdl, p-state).  comentado dia 19/06/09
  */
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

