&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          ems2cad          PROGRESS
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW
&Scoped-define FRAME-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS D-Dialog 
/*:T*******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i D99XX999 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
DEF BUFFER cidade FOR mgind.cidade.
DEF BUFFER unid-feder FOR mgadm.unid-feder.
DEF BUFFER b-emitente FOR emitente.
DEF BUFFER b-unid-feder FOR mgcad.unid-feder.

/* Temp Table Definitions ---                                       */
DEF TEMP-TABLE tt-destino
    FIELD tp-export     AS   INTEGER
    FIELD cod-emitente  LIKE emitente.cod-emitente
    FIELD nome-emitente LIKE emitente.nome-emit
    FIELD cidade        LIKE cidade.cidade
    FIELD estado        LIKE unid-feder.estado
    FIELD no-estado     LIKE unid-feder.no-estado
    FIELD visualiza     AS   LOGICAL INIT YES
    INDEX indice1 cod-emitente.
    
/* Global Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-transporte  AS ROWID NO-UNDO.

DEF NEW GLOBAL SHARED VAR wh-campo-conteudo AS WIDGET-HANDLE.
DEF NEW GLOBAL SHARED VAR wh-window         AS HANDLE NO-UNDO.
DEF NEW GLOBAL SHARED VAR wh-pesquisa       AS WIDGET-HANDLE.
DEF NEW GLOBAL SHARED VAR l-implanta        AS LOGICAL INIT NO.
DEF NEW GLOBAL SHARED VAR adm-broker-hdl    AS HANDLE NO-UNDO.

/* Local Variable Definitions ---                                       */
DEF VAR i-ct        AS INTEGER.
DEF VAR i-cod-emit  LIKE emitente.cod-emit.
DEF VAR h-acomp     AS HANDLE  NO-UNDO.

DEF VAR c-cidade-ini   AS CHAR.
DEF VAR c-cidade-fin   AS CHAR.
DEF VAR c-uf-ini       AS CHAR.
DEF VAR c-uf-fin       AS CHAR.
DEF VAR c-regiao-ini   AS CHAR.
DEF VAR c-regiao-fin   AS CHAR.
DEF VAR c-cep-ini      AS CHAR.
DEF VAR c-cep-fin      AS CHAR.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME D-Dialog
&Scoped-define BROWSE-NAME br-destino

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-destino emitente b-unid-feder

/* Definitions for BROWSE br-destino                                    */
&Scoped-define FIELDS-IN-QUERY-br-destino tt-destino.cod-emitente tt-destino.nome-emitente tt-destino.cidade tt-destino.estado   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-destino   
&Scoped-define SELF-NAME br-destino
&Scoped-define QUERY-STRING-br-destino FOR EACH tt-destino NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-destino OPEN QUERY {&SELF-NAME} FOR EACH tt-destino NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-destino tt-destino
&Scoped-define FIRST-TABLE-IN-QUERY-br-destino tt-destino


/* Definitions for BROWSE br-origem                                     */
&Scoped-define FIELDS-IN-QUERY-br-origem emitente.cod-emitente emitente.nome-emit emitente.cidade emitente.estado   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-origem   
&Scoped-define SELF-NAME br-origem
&Scoped-define QUERY-STRING-br-origem FOR EACH emitente WHERE                                  (emitente.identific <> 2 AND                                   emitente.cidade    >= c-cidade-ini AND                                   emitente.cidade    <= c-cidade-fin AND                                   emitente.estado    >= c-uf-ini AND                                   emitente.estado    <= c-uf-fin AND                                   emitente.cep       >= c-cep-ini AND                                   emitente.cep       <= c-cep-fin) OR rs-tp-export = 1 NO-LOCK, ~
                                   FIRST b-unid-feder WHERE                                   (b-unid-feder.estado = emitente.estado AND                                    b-unid-feder.char-2 >= c-regiao-ini AND                                    b-unid-feder.char-2 <= c-regiao-fin) OR rs-tp-export = 1                                 NO-LOCK INDEXED-REPOSITION
&Scoped-define OPEN-QUERY-br-origem OPEN QUERY {&SELF-NAME} FOR EACH emitente WHERE                                  (emitente.identific <> 2 AND                                   emitente.cidade    >= c-cidade-ini AND                                   emitente.cidade    <= c-cidade-fin AND                                   emitente.estado    >= c-uf-ini AND                                   emitente.estado    <= c-uf-fin AND                                   emitente.cep       >= c-cep-ini AND                                   emitente.cep       <= c-cep-fin) OR rs-tp-export = 1 NO-LOCK, ~
                                   FIRST b-unid-feder WHERE                                   (b-unid-feder.estado = emitente.estado AND                                    b-unid-feder.char-2 >= c-regiao-ini AND                                    b-unid-feder.char-2 <= c-regiao-fin) OR rs-tp-export = 1                                 NO-LOCK INDEXED-REPOSITION.
&Scoped-define TABLES-IN-QUERY-br-origem emitente b-unid-feder
&Scoped-define FIRST-TABLE-IN-QUERY-br-origem emitente
&Scoped-define SECOND-TABLE-IN-QUERY-br-origem b-unid-feder


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-destino}~
    ~{&OPEN-QUERY-br-origem}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom RECT-1 IMAGE-1 IMAGE-2 ~
rs-tp-export bt-filtro br-origem br-destino bt-add bt-add-all FILL-IN-1 ~
bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-cod-transp fi-nome-transp rs-tp-export ~
fi-filtro-ini fi-filtro-fin FILL-IN-1 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-add 
     IMAGE-UP FILE "adeicon\next-au":U
     LABEL "" 
     SIZE 6 BY 1.38.

DEFINE BUTTON bt-add-all 
     IMAGE-UP FILE "image/add-all.bmp":U
     LABEL "" 
     SIZE 6 BY 1.38.

DEFINE BUTTON bt-ajuda 
     LABEL "&Ajuda" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-cancela AUTO-END-KEY 
     LABEL "&Cancelar" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-filtro 
     IMAGE-UP FILE "image/im-sav.bmp":U
     LABEL "OK" 
     SIZE 4.86 BY 1.04 TOOLTIP "Processo Dados".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-cod-transp AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 0 
     LABEL "Codgo" 
     VIEW-AS FILL-IN 
     SIZE 6.72 BY .88 NO-UNDO.

DEFINE VARIABLE fi-filtro-fin AS CHARACTER FORMAT "X(256)":U INITIAL "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" 
     VIEW-AS FILL-IN 
     SIZE 34 BY .88 NO-UNDO.

DEFINE VARIABLE fi-filtro-ini AS CHARACTER FORMAT "X(256)":U 
     LABEL "Filtro" 
     VIEW-AS FILL-IN 
     SIZE 34 BY .88 NO-UNDO.

DEFINE VARIABLE fi-nome-transp AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 34.72 BY .88 NO-UNDO.

DEFINE VARIABLE FILL-IN-1 AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 2 BY .5
     BGCOLOR 12  NO-UNDO.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE VARIABLE rs-tp-export AS INTEGER INITIAL 1 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Todos os Cliente", 1,
"Cidade", 2,
"Estado", 3,
"RegiÆo", 4,
"Faixa de CEP", 5
     SIZE 71 BY .71 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 108 BY 20.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 108 BY 1.5
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-destino FOR 
      tt-destino SCROLLING.

DEFINE QUERY br-origem FOR 
      emitente, 
      b-unid-feder SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-destino
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-destino D-Dialog _FREEFORM
  QUERY br-destino NO-LOCK DISPLAY
      tt-destino.cod-emitente  FORMAT ">>>,>>9"
      tt-destino.nome-emitente FORMAT "x(30)"   WIDTH 20 
      tt-destino.cidade        FORMAT "x(20)"
      tt-destino.estado        FORMAT "x(5)"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 48.43 BY 15
         FONT 1
         TITLE "Clientes da Transportadora" ROW-HEIGHT-CHARS .67.

DEFINE BROWSE br-origem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-origem D-Dialog _FREEFORM
  QUERY br-origem NO-LOCK DISPLAY
      emitente.cod-emitente  FORMAT ">>>,>>9"
      emitente.nome-emit     FORMAT "x(30)"  WIDTH 20
      emitente.cidade        FORMAT "x(20)"
      emitente.estado        FORMAT "x(5)"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS MULTIPLE SIZE 49 BY 15.25
         FONT 1
         TITLE "Clientes Dispon¡veis" ROW-HEIGHT-CHARS .67.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     fi-cod-transp AT ROW 1.5 COL 16 COLON-ALIGNED WIDGET-ID 10
     fi-nome-transp AT ROW 1.5 COL 23 COLON-ALIGNED NO-LABEL WIDGET-ID 12
     rs-tp-export AT ROW 2.79 COL 18 NO-LABEL WIDGET-ID 2
     bt-filtro AT ROW 3.46 COL 96 WIDGET-ID 44
     fi-filtro-ini AT ROW 3.54 COL 16 COLON-ALIGNED WIDGET-ID 26
     fi-filtro-fin AT ROW 3.54 COL 57.72 COLON-ALIGNED NO-LABEL WIDGET-ID 36
     br-origem AT ROW 4.75 COL 3 WIDGET-ID 200
     br-destino AT ROW 5 COL 59.57 WIDGET-ID 300
     bt-add AT ROW 9.88 COL 52.72 WIDGET-ID 18
     bt-add-all AT ROW 11.46 COL 52.72 WIDGET-ID 20
     FILL-IN-1 AT ROW 20.38 COL 1.14 COLON-ALIGNED NO-LABEL WIDGET-ID 32
     bt-ok AT ROW 21.75 COL 3
     bt-cancela AT ROW 21.75 COL 14
     bt-ajuda AT ROW 21.75 COL 99
     "Cliente j  Relacionado" VIEW-AS TEXT
          SIZE 19.29 BY .67 AT ROW 20.29 COL 5.43 WIDGET-ID 34
          BGCOLOR 8 FONT 6
     rt-buttom AT ROW 21.5 COL 2
     RECT-1 AT ROW 1.25 COL 2 WIDGET-ID 6
     IMAGE-1 AT ROW 3.54 COL 52.72 WIDGET-ID 38
     IMAGE-2 AT ROW 3.58 COL 56.29 WIDGET-ID 40
     SPACE(51.56) SKIP(18.74)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Atualiza Transportadora dos Clientes - escd0402.w"
         DEFAULT-BUTTON bt-ok WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartDialog
   Allow: Basic,Browse,DB-Fields,Query,Smart
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB D-Dialog 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/d-dialog.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR DIALOG-BOX D-Dialog
   FRAME-NAME L-To-R                                                    */
/* BROWSE-TAB br-origem fi-filtro-fin D-Dialog */
/* BROWSE-TAB br-destino br-origem D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN fi-cod-transp IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-filtro-fin IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-filtro-ini IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-nome-transp IN FRAME D-Dialog
   NO-ENABLE                                                            */
ASSIGN 
       FILL-IN-1:READ-ONLY IN FRAME D-Dialog        = TRUE.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-destino
/* Query rebuild information for BROWSE br-destino
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-destino NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-destino */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-origem
/* Query rebuild information for BROWSE br-origem
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH emitente WHERE
                                 (emitente.identific <> 2 AND
                                  emitente.cidade    >= c-cidade-ini AND
                                  emitente.cidade    <= c-cidade-fin AND
                                  emitente.estado    >= c-uf-ini AND
                                  emitente.estado    <= c-uf-fin AND
                                  emitente.cep       >= c-cep-ini AND
                                  emitente.cep       <= c-cep-fin) OR rs-tp-export = 1 NO-LOCK,
                            FIRST b-unid-feder WHERE
                                  (b-unid-feder.estado = emitente.estado AND
                                   b-unid-feder.char-2 >= c-regiao-ini AND
                                   b-unid-feder.char-2 <= c-regiao-fin) OR rs-tp-export = 1
                                NO-LOCK INDEXED-REPOSITION.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-origem */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK DIALOG-BOX D-Dialog
/* Query rebuild information for DIALOG-BOX D-Dialog
     _Options          = "SHARE-LOCK"
     _Query            is NOT OPENED
*/  /* DIALOG-BOX D-Dialog */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME D-Dialog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL D-Dialog D-Dialog
ON WINDOW-CLOSE OF FRAME D-Dialog /* Atualiza Transportadora dos Clientes - escd0402.w */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-origem
&Scoped-define SELF-NAME br-origem
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-origem D-Dialog
ON ROW-DISPLAY OF br-origem IN FRAME D-Dialog /* Clientes Dispon¡veis */
DO:
   FIND tt-destino WHERE
        tt-destino.cod-emit = emitente.cod-emit NO-LOCK NO-ERROR.
   IF AVAIL tt-destino THEN
      ASSIGN emitente.cod-emitente:FGCOLOR IN BROWSE br-origem = 12
             emitente.nome-emit:FGCOLOR IN BROWSE br-origem = 12       
             emitente.cidade:FGCOLOR IN BROWSE br-origem = 12          
             emitente.estado:FGCOLOR IN BROWSE br-origem = 12.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-origem D-Dialog
ON VALUE-CHANGED OF br-origem IN FRAME D-Dialog /* Clientes Dispon¡veis */
DO:
    ASSIGN bt-add:SENSITIVE = YES
           bt-add-all:SENSITIVE = YES.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-add
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-add D-Dialog
ON CHOOSE OF bt-add IN FRAME D-Dialog
DO:
  DO i-ct = 1 TO br-origem:NUM-SELECTED-ROWS.

     br-origem:FETCH-SELECTED-ROW(i-ct).

     FIND tt-destino WHERE
          tt-destino.cod-emitente = emitente.cod-emitente NO-ERROR.
     IF NOT AVAIL tt-destino THEN DO.
        CREATE tt-destino.
        ASSIGN tt-destino.cod-emitente  = emitente.cod-emitente   
               tt-destino.nome-emitente = emitente.nome-emit       
               tt-destino.cidade        = emitente.cidade            
               tt-destino.estado        = emitente.estado.
     END.                  
  END.                     

  {&OPEN-QUERY-br-destino}

  br-origem:REFRESH().
  APPLY 'VALUE-CHANGED' TO br-origem.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-add-all
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-add-all D-Dialog
ON CHOOSE OF bt-add-all IN FRAME D-Dialog
DO:
  FOR EACH b-emitente WHERE
           b-emitente.identific <> 2 AND
           (b-emitente.cidade >= c-cidade-ini  AND
            b-emitente.cidade <= c-cidade-fin  AND
            b-emitente.estado >= c-uf-ini AND
            b-emitente.estado <= c-uf-fin AND
            b-emitente.cep    >= c-cep-ini AND
            b-emitente.cep    <= c-cep-fin) OR rs-tp-export = 1 NO-LOCK,
      FIRST b-unid-feder WHERE
            b-unid-feder.estado = b-emitente.estado AND
            (b-unid-feder.char-2 >= c-regiao-ini AND
             b-unid-feder.char-2 <= c-regiao-fin) OR rs-tp-export = 1 
      NO-LOCK.

      FIND tt-destino WHERE
           tt-destino.cod-emitente = b-emitente.cod-emitente NO-ERROR.
      IF NOT AVAIL tt-destino THEN DO.
         CREATE tt-destino.
         ASSIGN tt-destino.cod-emitente  = b-emitente.cod-emitente   
                tt-destino.nome-emitente = b-emitente.nome-emit       
                tt-destino.cidade        = b-emitente.cidade            
                tt-destino.estado        = b-emitente.estado.
      END.
  END.

  {&OPEN-QUERY-br-destino}
  br-origem:REFRESH().

  APPLY 'VALUE-CHANGED' TO br-origem.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda D-Dialog
ON CHOOSE OF bt-ajuda IN FRAME D-Dialog /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO: /* Call Help Function (or a simple message). */
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-filtro
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-filtro D-Dialog
ON CHOOSE OF bt-filtro IN FRAME D-Dialog /* OK */
DO:
    ASSIGN INPUT FRAME {&FRAME-NAME} rs-tp-export fi-filtro-ini fi-filtro-fin.

    ASSIGN c-cidade-ini = ''      
           c-cidade-fin = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'      
           c-uf-ini     = ''      
           c-uf-fin     = 'ZZ'      
           c-regiao-ini = '' 
           c-regiao-fin = 'ZZZZZZZZZZZZZZZ' 
           c-cep-ini    = ''
           c-cep-fin    = 'ZZZZZZZZ'. 

    CASE rs-tp-export.
       WHEN 2 THEN DO.
           ASSIGN c-cidade-ini = fi-filtro-ini
                  c-cidade-fin = fi-filtro-fin.      
       END.
       WHEN 3 THEN DO.
           ASSIGN c-uf-ini = fi-filtro-ini
                  c-uf-fin = fi-filtro-fin.      
       END.
       WHEN 4 THEN DO.
           ASSIGN c-regiao-ini = fi-filtro-ini
                  c-regiao-fin = fi-filtro-fin.
       END.
       WHEN 5 THEN DO.
           ASSIGN c-cep-ini = fi-filtro-ini
                  c-cep-fin = fi-filtro-fin.
       END.
    END CASE.

   {&OPEN-QUERY-br-origem}
   APPLY 'VALUE-CHANGED' TO br-origem.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok D-Dialog
ON CHOOSE OF bt-ok IN FRAME D-Dialog /* OK */
DO:
   IF SESSION:SET-WAIT-STATE("general":U) THEN.

   FOR EACH tt-destino.
       FIND emitente WHERE
            emitente.cod-emit = tt-destino.cod-emit SHARE-LOCK NO-ERROR.
       IF AVAIL emitente THEN
          ASSIGN emitente.cod-trans = transporte.cod-transp.
   END.

   IF SESSION:SET-WAIT-STATE("") THEN.

   MESSAGE 'OK, Clientes Relacionados … Transportadora...'
       VIEW-AS ALERT-BOX INFO BUTTONS OK.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-tp-export
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-tp-export D-Dialog
ON VALUE-CHANGED OF rs-tp-export IN FRAME D-Dialog
DO:
  ASSIGN fi-filtro-ini:SENSITIVE = YES
         fi-filtro-fin:SENSITIVE = YES.

  ASSIGN fi-filtro-ini:SCREEN-VALUE = ''
         fi-filtro-fin:SCREEN-VALUE = ''.

  CASE SELF:SCREEN-VALUE.
      WHEN '1' THEN
          ASSIGN fi-filtro-ini:SENSITIVE = NO
                 fi-filtro-fin:SENSITIVE = NO
                 fi-filtro-ini:WIDTH     = 34
                 fi-filtro-fin:WIDTH     = 34
                 fi-filtro-ini:SCREEN-VALUE = ''
                 fi-filtro-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'.
      WHEN '2' THEN 
          ASSIGN fi-filtro-ini:WIDTH  = 34
                 fi-filtro-fin:WIDTH  = 34
                 fi-filtro-ini:FORMAT = "x(30)"
                 fi-filtro-fin:FORMAT = "x(30)"
                 fi-filtro-ini:SCREEN-VALUE = ''
                 fi-filtro-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'.
      WHEN '3' THEN 
          ASSIGN fi-filtro-ini:WIDTH  = 4
                 fi-filtro-fin:WIDTH  = 4
                 fi-filtro-ini:FORMAT = "x(2)"
                 fi-filtro-fin:FORMAT = "x(2)"
                 fi-filtro-ini:SCREEN-VALUE = ''
                 fi-filtro-fin:SCREEN-VALUE = 'ZZ'.
      WHEN '4' THEN 
          ASSIGN fi-filtro-ini:WIDTH  = 22
                 fi-filtro-fin:WIDTH  = 22
                 fi-filtro-ini:FORMAT = "x(20)"
                 fi-filtro-fin:FORMAT = "x(20)"
                 fi-filtro-ini:SCREEN-VALUE = ''
                 fi-filtro-fin:SCREEN-VALUE = 'ZZZZZZZZZZZZZZZZZZZZZZ'.
      WHEN '5' THEN 
          ASSIGN fi-filtro-ini:WIDTH  = 10
                 fi-filtro-fin:WIDTH  = 10
                 fi-filtro-ini:FORMAT = "99.999-999"
                 fi-filtro-fin:FORMAT = "99.999-999"
                 fi-filtro-ini:SCREEN-VALUE = '00000000'
                 fi-filtro-fin:SCREEN-VALUE = '99999999'.
  END CASE.


  APPLY 'ENTRY' TO fi-filtro-ini.
  RETURN NO-APPLY.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-destino
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */
fi-filtro-ini:LOAD-MOUSE-POINTER("image/lupa.cur").
fi-filtro-fin:LOAD-MOUSE-POINTER("image/lupa.cur").

{src/adm/template/dialogmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects D-Dialog  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available D-Dialog  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI D-Dialog  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Hide all frames. */
  HIDE FRAME D-Dialog.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI D-Dialog  _DEFAULT-ENABLE
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
  DISPLAY fi-cod-transp fi-nome-transp rs-tp-export fi-filtro-ini fi-filtro-fin 
          FILL-IN-1 
      WITH FRAME D-Dialog.
  ENABLE rt-buttom RECT-1 IMAGE-1 IMAGE-2 rs-tp-export bt-filtro br-origem 
         br-destino bt-add bt-add-all FILL-IN-1 bt-ok bt-cancela bt-ajuda 
      WITH FRAME D-Dialog.
  VIEW FRAME D-Dialog.
  {&OPEN-BROWSERS-IN-QUERY-D-Dialog}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy D-Dialog 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize D-Dialog 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/
  /* Code placed here will execute PRIOR to standard behavior. */

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
  RUN pi-inicializar IN h-acomp (INPUT "Processando..").
  
  FIND FIRST para-ped NO-LOCK NO-ERROR.
  
  FIND transporte WHERE
       ROWID(transporte) = gr-transporte NO-LOCK NO-ERROR.

 FOR EACH emitente WHERE
          emitente.cod-transp = transporte.cod-transp NO-LOCK.

     RUN pi-acompanhar IN h-acomp (INPUT "Clientes MED da Transp: " + STRING(emitente.cod-emit)).

     CREATE tt-destino.
     ASSIGN tt-destino.cod-emitente  = emitente.cod-emit
            tt-destino.nome-emitente = emitente.nome-emit
            tt-destino.cidade        = emitente.cidade
            tt-destino.estado        = emitente.estado.    
  END.

  RUN pi-finalizar in h-acomp.

  {&OPEN-QUERY-br-origem}
  {&OPEN-QUERY-br-destino}

  IF AVAIL transporte THEN
     ASSIGN fi-cod-transp:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(transporte.cod-transp)
            fi-nome-transp:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(transporte.nome).


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records D-Dialog  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "emitente"}
  {src/adm/template/snd-list.i "b-unid-feder"}
  {src/adm/template/snd-list.i "tt-destino"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed D-Dialog 
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

