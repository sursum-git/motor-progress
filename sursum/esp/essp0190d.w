&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
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
{include/i-prgvrs.i ESSP0190D 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

{utp/utapi011.i} /* Geraá∆o de Graficos */

/* ***************************  Definitions  ************************** */
DEF BUFFER empresa FOR mgadm.empresa.
DEF BUFFER unid-feder FOR mgadm.unid-feder.

/* Parameters Definitions ---                                           */

DEF TEMP-TABLE tt-pedidos NO-UNDO
    FIELD nr-pedcli   LIKE ped-venda.nr-pedcli
    FIELD nr-nota-fis LIKE nota-fiscal.nr-nota-fis
    FIELD cod-estabel LIKE nota-fiscal.cod-estabel
    FIELD serie       LIKE nota-fiscal.serie
    FIELD exportacao  AS LOG
    FIELD qt-faturada LIKE it-nota-fisc.qt-faturada
    FIELD vl-tot-item LIKE it-nota-fisc.vl-tot-item
    FIELD desc-pratic AS DEC.

DEFINE TEMP-TABLE tt-itens NO-UNDO 
       FIELD it-codigo    LIKE ped-item.it-codigo
       FIELD desc-item    LIKE item.desc-item
       INDEX indice1 it-codigo.

DEFINE TEMP-TABLE tt-work NO-UNDO 
       FIELD it-codigo    LIKE ped-item.it-codigo
       FIELD desc-item    LIKE item.desc-item
       FIELD lote         AS CHAR
       FIELD un           LIKE item.un
       FIELD qtd          AS DEC
       FIELD desc-pratic  AS DEC
       FIELD vlr          AS DEC
       FIELD pmedio       AS DEC
       INDEX indice1 it-codigo.

DEF TEMP-TABLE tt-repres
    FIELD col-qtd         AS   INTEGER
    FIELD col-vlr         AS   INTEGER
    FIELD nome-abrev      LIKE repres.nome-abrev.

DEFINE TEMP-TABLE tt-item-repres NO-UNDO 
       FIELD nome-abrev   LIKE repres.nome-abrev
       FIELD it-codigo    LIKE item.it-codigo
       FIELD qtde         AS DECIMAL
       FIELD valor        AS DECIMAL.

DEF TEMP-TABLE tt-digita
    FIELD opcao  AS CHAR
    FIELD campo AS CHAR
    FIELD valor AS CHAR.

DEFINE BUFFER b-tt-work FOR tt-work.
  
DEFINE INPUT PARAMETER TABLE FOR tt-pedidos.  
DEFINE INPUT PARAMETER p-dt-faturar       AS CHAR.
DEFINE INPUT PARAMETER p-dt-faturadas-ini AS DATE.
DEFINE INPUT PARAMETER p-dt-faturadas-fin AS DATE.
DEFINE INPUT PARAMETER p-dt-vendido-ini   AS CHAR.
DEFINE INPUT PARAMETER p-dt-vendido-fin   AS CHAR.
DEFINE INPUT PARAMETER p-tipo-selecao     AS INT.
DEFINE INPUT PARAMETER p-repres           AS CHAR.
DEFINE INPUT PARAMETER c-it-codigo-ini    LIKE ped-item.it-codigo.
DEFINE INPUT PARAMETER c-it-codigo-fin    LIKE ped-item.it-codigo.
DEFINE INPUT PARAMETER c-cod-refer-ini    LIKE ped-item.cod-refer.                              
DEFINE INPUT PARAMETER c-cod-refer-fin    LIKE ped-item.cod-refer.
DEFINE INPUT PARAMETER c-lotes            AS CHAR.
DEFINE INPUT PARAMETER c-corte-comerc-ini AS CHAR.
DEFINE INPUT PARAMETER c-corte-comerc-fin AS CHAR.
DEFINE INPUT PARAMETER i-ge-codigo-ini    LIKE grup-estoque.ge-codigo.
DEFINE INPUT PARAMETER i-ge-codigo-fin    LIKE grup-estoque.ge-codigo.
DEFINE INPUT PARAMETER c-cod-obsoleto-ini AS CHAR. 
DEFINE INPUT PARAMETER c-cod-obsoleto-fin AS CHAR.
DEFINE INPUT PARAMETER c-tipo-acabamento  AS CHAR.
DEFINE INPUT PARAMETER c-cod-depos        AS CHAR.
DEFINE INPUT PARAMETER TABLE FOR tt-digita.  
DEFINE INPUT PARAMETER p-lote             AS CHAR.
DEFINE INPUT PARAMETER p-tipo-consulta    AS CHAR.
DEFINE INPUT PARAMETER p-regiao           AS CHAR.

/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-ped-venda   AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR gr-nota-fiscal AS ROWID NO-UNDO.

DEF VAR h-acomp      AS HANDLE NO-UNDO.
DEF VAR h-query      AS HANDLE.
DEF VAR opt-sort     AS INT.
DEF VAR c-sit-ped    AS CHAR.
DEF VAR c-titulo     AS CHAR.
DEF VAR c-sub-tit    AS CHAR.
DEF VAR c-regiao     AS CHAR.
DEF VAR c-lote-refer AS CHAR.
DEF VAR c-empresa    AS CHAR.

DEF VAR i-ct         AS INT.
DEF VAR i-cor        AS INT.
DEF VAR wh-repres    AS WIDGET-HANDLE EXTENT 200.


 /* Variaveis da Rotina de Impress∆o */
DEFINE VAR l-ok         AS LOG.
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-lin        AS INT.
DEFINE VAR i-pag        AS INT.

/* Variaveis da Rotina de CLASSIFICAÄ«O POR COLUNAS DO BROWSE */
DEFINE VAR h-col       AS HANDLE.
DEFINE VAR i-col       AS INT.
DEFINE VAR sort-col    AS INT INIT 1.
DEFINE VAR order-col   AS INT INIT 1.
DEFINE VAR c-label     AS CHAR.
DEFINE VAR c-label-ori AS CHAR.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartDialog
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER DIALOG-BOX

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME D-Dialog
&Scoped-define BROWSE-NAME br-work

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-work

/* Definitions for BROWSE br-work                                       */
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.it-codigo tt-work.desc-item   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK {&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom br-work bt-grafico-qtd ~
bt-grafico-vlr bt-imprime-2 bt-excel bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-total-qtd-und fi-total-qtd-m ~
fi-total-qtd-kg fi-total-vlr-und fi-total-vlr-m fi-total-vlr-kg ~
fi-pmedio-und fi-pmedio-m fi-pmedio-kg 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-6 bt-excel 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define a dialog box                                                  */

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "&Ajuda" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-cancela AUTO-END-KEY 
     LABEL "&Cancelar" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/excel.bmp":U
     LABEL "Button 2" 
     SIZE 5 BY 1.21 TOOLTIP "Gerar Planilha".

DEFINE BUTTON bt-grafico-qtd 
     IMAGE-UP FILE "image/img-graf.bmp":U
     LABEL "Impress∆o do Grafico de Quantidades" 
     SIZE 15 BY 1.25 TOOLTIP "Visualizaá∆o/Impress∆o do Grafico QUANTIDADES".

DEFINE BUTTON bt-grafico-vlr 
     IMAGE-UP FILE "image/img-graf1.bmp":U
     LABEL "Impress∆o do Gr†fico de Valores" 
     SIZE 15 BY 1.25 TOOLTIP "Visualizaá∆o/Impress∆o do Grafico VALORES".

DEFINE BUTTON bt-imprime-2 
     IMAGE-UP FILE "image/im-pri.bmp":U
     LABEL "Impress∆o" 
     SIZE 4 BY 1.25 TOOLTIP "Imprime Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-pmedio-kg AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-pmedio-m AS DECIMAL FORMAT "->>>,>>>,>>9.99":R17 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-pmedio-und AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-qtd-kg AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-qtd-m AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-qtd-und AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr-kg AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr-m AS DECIMAL FORMAT "->>>,>>>,>>9.99":R17 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr-und AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88
     FGCOLOR 12 FONT 6 NO-UNDO.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 124.43 BY 1.42
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-work FOR 
      tt-work SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-work D-Dialog _FREEFORM
  QUERY br-work NO-LOCK DISPLAY
      tt-work.it-codigo          COLUMN-LABEL "Item"        WIDTH  6
      tt-work.desc-item          COLUMN-LABEL "Descriá∆o"   WIDTH 30
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 124.29 BY 11.92
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1.72
     bt-grafico-qtd AT ROW 13.08 COL 2.14
     bt-grafico-vlr AT ROW 13.08 COL 18
     bt-imprime-2 AT ROW 13.08 COL 33.72 WIDGET-ID 24
     bt-excel AT ROW 13.08 COL 38.29 WIDGET-ID 22
     fi-total-qtd-und AT ROW 14.5 COL 101.43 COLON-ALIGNED NO-LABEL
     fi-total-qtd-m AT ROW 14.54 COL 16.29 COLON-ALIGNED NO-LABEL
     fi-total-qtd-kg AT ROW 14.75 COL 58.14 COLON-ALIGNED NO-LABEL
     fi-total-vlr-und AT ROW 15.5 COL 101.43 COLON-ALIGNED NO-LABEL
     fi-total-vlr-m AT ROW 15.54 COL 16.29 COLON-ALIGNED NO-LABEL
     fi-total-vlr-kg AT ROW 15.75 COL 58.14 COLON-ALIGNED NO-LABEL
     fi-pmedio-und AT ROW 16.5 COL 101.43 COLON-ALIGNED NO-LABEL
     fi-pmedio-m AT ROW 16.54 COL 16.29 COLON-ALIGNED NO-LABEL
     fi-pmedio-kg AT ROW 16.75 COL 58.14 COLON-ALIGNED NO-LABEL
     bt-ok AT ROW 17.92 COL 2.57
     bt-cancela AT ROW 17.92 COL 13.57
     bt-ajuda AT ROW 17.92 COL 115.29
     "Total Qtd (Und):" VIEW-AS TEXT
          SIZE 11 BY .67 AT ROW 14.58 COL 92.29
          FGCOLOR 9 
     "Preáo Medio (Und):" VIEW-AS TEXT
          SIZE 13 BY .67 AT ROW 16.58 COL 90
          FGCOLOR 9 
     "Preáo Medio (Kg):" VIEW-AS TEXT
          SIZE 12 BY .67 AT ROW 16.83 COL 48
          FGCOLOR 9 
     "Total Valor (Und):" VIEW-AS TEXT
          SIZE 12 BY .67 AT ROW 15.54 COL 91.29
          FGCOLOR 9 
     "Preáo Medio (M):" VIEW-AS TEXT
          SIZE 12 BY .67 AT ROW 16.63 COL 6.29
          FGCOLOR 9 
     "Total Qtd (M):" VIEW-AS TEXT
          SIZE 9.72 BY .67 AT ROW 14.54 COL 8.57
          FGCOLOR 9 
     "Total Valor (Kg):" VIEW-AS TEXT
          SIZE 10.72 BY .67 AT ROW 15.79 COL 49
          FGCOLOR 9 
     "Total Qtd (Kg):" VIEW-AS TEXT
          SIZE 10 BY .67 AT ROW 14.83 COL 50
          FGCOLOR 9 
     "Total Valor (M):" VIEW-AS TEXT
          SIZE 10.29 BY .67 AT ROW 15.58 COL 7.57
          FGCOLOR 9 
     rt-buttom AT ROW 17.67 COL 1.57
     SPACE(0.01) SKIP(0.03)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Composiá∆o dos Itens por Representante - ESSP0190D"
         DEFAULT-BUTTON bt-ok.


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
   NOT-VISIBLE FRAME-NAME L-To-R                                        */
/* BROWSE-TAB br-work rt-buttom D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR BUTTON bt-excel IN FRAME D-Dialog
   6                                                                    */
/* SETTINGS FOR FILL-IN fi-pmedio-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-pmedio-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-pmedio-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-qtd-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-qtd-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-qtd-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr-kg IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr-m IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr-und IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK {&SORTBY-PHRASE}.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-work */
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Composiá∆o dos Itens por Representante - ESSP0190D */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON ROW-DISPLAY OF br-work IN FRAME D-Dialog
DO:
   FOR EACH tt-repres NO-LOCK.
       FIND tt-item-repres WHERE
            tt-item-repres.nome-abrev = tt-repres.nome-abrev AND
            tt-item-repres.it-codigo = tt-work.it-codigo NO-LOCK NO-ERROR.

       IF AVAIL tt-item-repres THEN DO.
          IF VALID-HANDLE(wh-repres[tt-repres.col-qtd]) THEN
             wh-repres[tt-repres.col-qtd]:SCREEN-VALUE = STRING(tt-item-repres.qtd).

          IF VALID-HANDLE(wh-repres[tt-repres.col-vlr]) THEN
             wh-repres[tt-repres.col-vlr]:SCREEN-VALUE = STRING(tt-item-repres.valor).
       END.
   END.
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


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel D-Dialog
ON CHOOSE OF bt-excel IN FRAME D-Dialog /* Button 2 */
DO:
   SESSION:SET-WAIT-STATE("general":U).



   OUTPUT TO VALUE(SESSION:TEMP-DIRECTORY + "essp0190.csv").

   PUT ";;".

   FOR EACH tt-repres.
       FIND repres WHERE
            repres.nome-abrev = tt-repres.nome-abrev NO-LOCK NO-ERROR.

       PUT UNFORMATTED 
           STRING(repres.cod-rep) + "-" + tt-repres.nome-abrev
           ";;".
   END.
   PUT "" SKIP.

   PUT "ITEM;DESCRIÄ«O;".

   FOR EACH tt-repres.
       PUT "Qtde;Valor;".
   END.
   PUT "" SKIP.

   FOR EACH b-tt-work NO-LOCK.
       PUT b-tt-work.it-codigo ";" 
           b-tt-work.desc-item ";".

       FOR EACH tt-repres NO-LOCK.
           FIND tt-item-repres WHERE
                tt-item-repres.nome-abrev = tt-repres.nome-abrev AND
                tt-item-repres.it-codigo = b-tt-work.it-codigo NO-LOCK NO-ERROR.
    
           IF AVAIL tt-item-repres THEN
              PUT UNFORMATTED 
                  STRING(tt-item-repres.qtd,">>>,>>9.99") ";"
                  STRING(tt-item-repres.valor,">>>,>>9.99") ";".
            ELSE
              PUT "0,00" ";"
                  "0,00" ";".
       END.
       PUT "" SKIP.
   END.

   OUTPUT CLOSE.
   SESSION:SET-WAIT-STATE("":U).


   MESSAGE 'Gerado Arquivo c:\temp\essp0190.csv' 
       VIEW-AS ALERT-BOX INFO BUTTONS OK.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-grafico-qtd
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-grafico-qtd D-Dialog
ON CHOOSE OF bt-grafico-qtd IN FRAME D-Dialog /* Impress∆o do Grafico de Quantidades */
DO:
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
  RUN pi-grafico (INPUT 1).
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-grafico-vlr
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-grafico-vlr D-Dialog
ON CHOOSE OF bt-grafico-vlr IN FRAME D-Dialog /* Impress∆o do Gr†fico de Valores */
DO:
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
  RUN pi-grafico (INPUT 2).
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime-2 D-Dialog
ON CHOOSE OF bt-imprime-2 IN FRAME D-Dialog /* Impress∆o */
DO:
  RUN pi-imprime.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

ASSIGN FRAME D-Dialog:TITLE = 'Detalha a Composiá∆o dos Itens Por REPRESENTANTES'.

ASSIGN h-query = br-work:QUERY.
br-work:NUM-LOCKED-COLUMNS = 2.

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
  DISPLAY fi-total-qtd-und fi-total-qtd-m fi-total-qtd-kg fi-total-vlr-und 
          fi-total-vlr-m fi-total-vlr-kg fi-pmedio-und fi-pmedio-m fi-pmedio-kg 
      WITH FRAME D-Dialog.
  ENABLE rt-buttom br-work bt-grafico-qtd bt-grafico-vlr bt-imprime-2 bt-excel 
         bt-ok bt-cancela bt-ajuda 
      WITH FRAME D-Dialog.
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

  /* {utp/ut9000.i "ESSP0190d" "2.04.00.000"} */ 

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  /* Busca Nome da Empresa */
  FIND FIRST param-global NO-LOCK NO-ERROR.
  FIND FIRST empresa
       WHERE empresa.ep-codigo = param-global.empresa-prin NO-LOCK NO-ERROR. 
  ASSIGN c-empresa = (IF AVAIL empresa THEN empresa.razao-social ELSE "").

  RUN pi-processa.

  {&OPEN-QUERY-br-work}
  APPLY 'ENTRY' TO br-work IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grafico D-Dialog 
PROCEDURE pi-grafico :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-tipo-grafico AS INT.

 DEF VAR i-point   AS INT INITIAL 1.
 DEF VAR i-numsets AS INT.
 DEF VAR de-work   AS DEC.
 DEF VAR c-desc    AS CHAR.

 EMPTY TEMP-TABLE tt-atributos.
 EMPTY TEMP-TABLE tt-sets.
 EMPTY TEMP-TABLE tt-points-2.
 EMPTY TEMP-TABLE tt-dados.
 EMPTY TEMP-TABLE tt-erros.

 IF p-tipo-grafico = 1 THEN
    ASSIGN c-desc = "Quantidade em METROS.".
 ELSE
    ASSIGN c-desc = "Valores em Real (R$).".


 /* Configuraá∆o Geral do Grafico */
 CREATE tt-atributos.
 ASSIGN tt-atributos.cod-versao-integracao = 3
        tt-atributos.graphtype             = 3
        tt-atributos.graphtitle            = c-titulo
        tt-atributos.lefttitle             = c-desc
        tt-atributos.lefttitlestyle        = 1
        tt-atributos.bottomtitle           = "I T E N S"
        tt-atributos.numgraph              = 1.
                                             
 /* Configuraá∆o das Variantes do Grafico */
 ASSIGN i-numsets = 1.
 CREATE tt-sets.
 ASSIGN tt-sets.NumSet     = i-numsets 
        tt-sets.NumGraph   = 1
        tt-sets.ColorSet   = 1
        tt-sets.legendText = "I T E N S".

 ASSIGN de-work = 0.
 FOR EACH b-tt-work NO-LOCK 
    BREAK BY b-tt-work.it-codigo
          BY b-tt-work.lote
          BY b-tt-work.un.

     IF p-tipo-grafico = 1 THEN
        ASSIGN de-work = de-work + b-tt-work.qtd.
     ELSE
        ASSIGN de-work = de-work + b-tt-work.vlr.

     IF LAST-OF(b-tt-work.it-codigo) THEN DO:
        /* Valores do EIXO X (ITENS) */
        CREATE tt-points-2.
        ASSIGN tt-points-2.NumPoint  = i-point
               tt-points-2.NumGraph  = 1
               tt-points-2.labeltext = b-tt-work.it-codigo.
        /* Valores do EIXO Y (QUANTIDADE / VALORES) */
        ASSIGN i-numsets = 1.
        CREATE tt-dados.
        ASSIGN tt-dados.NumPoint   = i-point
               tt-dados.NumSet     = i-numsets
               tt-dados.NumGraph   = 1
               tt-dados.graphdata  = de-work.

        ASSIGN i-numsets = i-numsets + 1 
               i-point   = i-point   + 1
               de-work   = 0.
     END.
 END.
 
 DEF VAR h-utapi011 AS HANDLE NO-UNDO.

 RUN utp/utapi011.p PERSISTENT SET h-utapi011.

 RUN pi-execute IN h-utapi011 (INPUT  TABLE tt-atributos,
                               INPUT  TABLE tt-points-2,
                               INPUT  TABLE tt-sets,
                               INPUT  TABLE tt-dados,
                               INPUT  TABLE tt-ylabels,
                               OUTPUT TABLE tt-erros).

 IF RETURN-VALUE = "NOK" THEN DO: 
    FOR EACH tt-erros: 
        DISP cod-erro desc-erro FORMAT "x(100)" WITH 1 COL WIDTH 500. 
    END.
 END.                  

 DELETE PROCEDURE h-utapi011.



END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-cabec D-Dialog 
PROCEDURE pi-imp-cabec :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 PUT c-empresa FORMAT "x(40)"                  AT   1
     "DATA: "                                  AT  45
     STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  51
     "HORA: "                                  AT  67
     STRING(TIME,"hh:mm:ss")                   AT  73
     "PAG:"                                    AT  95
     i-pag FORMAT ">>"                         AT 100
     SKIP(1).

 PUT c-titulo FORMAT "x(100)" AT 5.
 PUT SKIP(1).
 PUT "ITEM   DESCRIÄ«O                           LOTE UND     QUANTIDADE           VALOR    DESC. PRATIC PREÄO MêDIO    %"   AT 1.
 PUT "------ ----------------------------------- ---- --- -------------- --------------- --------------- ----------- ------" AT 1.
 
 ASSIGN i-pag = i-pag + 1.
                                                                            
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imprime D-Dialog 
PROCEDURE pi-imprime :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF VAR h-prog AS HANDLE NO-UNDO.
 DEF VAR i-ct   AS INT.

 RUN utp/ut-utils.p PERSISTENT SET h-prog.

 RUN esapi/saida-imp.p (OUTPUT i-saida,
                        OUTPUT c-saida,
                        OUTPUT i-num-copias,
                        OUTPUT l-ok).

 CASE i-saida:
     WHEN 1 THEN DO.
         OUTPUT TO PRINTER CONVERT TARGET "ibm850" PAGED PAGE-SIZE 62.
         PUT CONTROL "~033E~033(s18H".    
     END.
     WHEN 2 THEN
         OUTPUT TO VALUE(c-saida).
     WHEN 3 THEN DO.
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0190d.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.
 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-pag      =  1
           i-lin      = 99.
    FOR EACH b-tt-work NO-LOCK {&SORTBY-IMP-EXCEL}.
        
        IF i-lin > 62 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.

        PUT b-tt-work.it-codigo   FORMAT "x(6)"            AT  01
            b-tt-work.desc-item   FORMAT "x(35)"           AT  08   
            b-tt-work.lote        FORMAT "x(2)"            AT  44   
            b-tt-work.un          FORMAT "x(3)"            AT  49   
            b-tt-work.qtd         FORMAT ">>>,>>>,>>9.99"  AT  53   
            b-tt-work.vlr         FORMAT ">>>>,>>>,>>9.99" AT  68
            b-tt-work.desc-pratic FORMAT ">>>>,>>>,>>9.99" AT  84
            (b-tt-work.vlr + b-tt-work.desc-pratic) /
             b-tt-work.qtd        FORMAT ">>9.99"           AT 105.

        ASSIGN i-lin = i-lin + 1.
    END.
    IF i-lin <> 99 THEN DO:
        IF i-lin > 62 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
       PUT "--------------- ---------------"         AT 68.
       PUT "Total QTD (M):"                          AT  2
           fi-total-qtd-m   FORMAT ">>>,>>9.99"      AT 21
           "Total QTD (KG):"                         AT 36
           fi-total-qtd-kg  FORMAT ">>>,>>9.99"      AT 56
           "Total QTD (UND):"                        AT 71
           fi-total-qtd-und FORMAT ">>>,>>9.99"      AT 92.
       PUT "Total VLR (M):"                          AT  2
           fi-total-vlr-m   FORMAT ">>>,>>>,>>9.99"  AT 17
           "Total VLR (KG):"                         AT 36
           fi-total-vlr-kg  FORMAT ">>>,>>>,>>9.99"  AT 52
           "Total VLR (UND):"                        AT 71
           fi-total-vlr-und FORMAT ">>>,>>>,>>9.99"  AT 88.
       PUT "P.Medio (M):"                            AT  4
           fi-pmedio-m      FORMAT ">>>,>>9.99"      AT 21
           "P.Medio (KG):"                           AT 38
           fi-pmedio-kg     FORMAT ">>>,>>9.99"      AT 56
           "P.MÇdio (UND):"                          AT 73
           fi-pmedio-und    FORMAT ">>>,>>9.99"      AT 92.
    END.
    IF i-saida = 1 THEN DO:
       PAGE.
       PUT "" AT 1.
    END.
 END.
 IF i-saida = 3 THEN DO.
   RUN EXECUTE IN h-prog(INPUT "notepad.exe",
                         INPUT c-saida).
   DELETE PROCEDURE h-prog.
 END.
 OUTPUT CLOSE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-nota-fiscal D-Dialog 
PROCEDURE pi-nota-fiscal :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  ASSIGN i-ct = 0.
  FOR EACH tt-pedidos.
      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
           nota-fiscal.serie       = tt-pedidos.serie       AND
           nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.
      FIND tt-repres WHERE
           tt-repres.nome-abrev = nota-fiscal.no-ab-reppri NO-LOCK NO-ERROR.
      IF NOT AVAIL tt-repres THEN DO.
         CREATE tt-repres.
         ASSIGN tt-repres.nome-abrev = nota-fiscal.no-ab-reppri
                tt-repres.col-qtd = i-ct + 1
                tt-repres.col-vlr = i-ct + 2.

         ASSIGN i-ct = i-ct + 2.
      END.
  END.

  FOR EACH tt-repres.
      IF NOT VALID-HANDLE(wh-repres[tt-repres.col-qtd]) THEN 
         wh-repres[tt-repres.col-qtd] = br-work:ADD-CALC-COLUMN("dec",">>>,>>>,>>9.99","",tt-repres.nome-abrev + "!" + "Qtde")
                                        IN FRAME {&FRAME-NAME}.
      IF NOT VALID-HANDLE(wh-repres[tt-repres.col-vlr]) THEN 
         wh-repres[tt-repres.col-vlr] = br-work:ADD-CALC-COLUMN("dec",">>>,>>>,>>9.99","","Valor")
                                        IN FRAME {&FRAME-NAME}.
  END.

  ASSIGN i-cor = 7.
  DO i-ct = 3 TO br-work:NUM-COLUMNS IN FRAME {&FRAME-NAME}.
     ASSIGN h-col = br-work:GET-BROWSE-COLUMN(i-ct).

     IF i-ct MODULO 2 = 1 THEN 
        ASSIGN i-cor = IF i-cor = 7 THEN 8 ELSE 7.

     ASSIGN h-col:COLUMN-BGCOLOR = i-cor
            h-col:LABEL-BGCOLOR = i-cor.

  END.

  FOR EACH tt-pedidos NO-LOCK.

      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
           nota-fiscal.serie       = tt-pedidos.serie       AND
           nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.
      IF NOT AVAIL nota-fiscal THEN NEXT.

      RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(nota-fiscal.dt-emis-nota) +
                                          " Nota Fiscal: " + nota-fiscal.nr-nota-fis).

      FIND tt-repres WHERE
           tt-repres.nome-abrev = nota-fiscal.no-ab-reppri NO-LOCK NO-ERROR.

      FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
          FIND item WHERE
               item.it-codigo = it-nota-fisc.it-codigo NO-LOCK NO-ERROR.

          FIND tt-work WHERE
               tt-work.it-codigo = it-nota-fisc.it-codigo AND
               tt-work.lote      = c-lote-refer           AND
               tt-work.un        = ITEM.un NO-LOCK NO-ERROR.

          IF NOT AVAIL tt-work THEN DO:
             CREATE tt-work.
             ASSIGN tt-work.it-codigo = it-nota-fisc.it-codigo
                    tt-work.desc-item = ITEM.desc-item
                    tt-work.lote      = c-lote-refer
                    tt-work.un        = ITEM.un.
          END.
          ASSIGN tt-work.qtd = tt-work.qtd + it-nota-fisc.qt-faturada[1]
                 tt-work.vlr = tt-work.vlr + it-nota-fisc.vl-tot-item +
                               IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                               THEN it-nota-fisc.val-desconto-total 
                               ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)).

          FIND tt-itens WHERE
               tt-itens.it-codigo = it-nota-fisc.it-codigo  NO-LOCK NO-ERROR.
          IF NOT AVAIL tt-itens THEN DO:
             CREATE tt-itens.
             ASSIGN tt-itens.it-codigo = it-nota-fisc.it-codigo
                    tt-itens.desc-item = item.desc-item.
          END.

          FIND tt-item-repres WHERE
               tt-item-repres.it-codigo = it-nota-fisc.it-codigo AND
               tt-item-repres.nome-abrev = tt-repres.nome-abrev NO-ERROR.
          IF NOT AVAIL tt-item-repres THEN DO.
             CREATE tt-item-repres.
             ASSIGN tt-item-repres.it-codigo = it-nota-fisc.it-codigo 
                    tt-item-repres.nome-abrev = tt-repres.nome-abrev.
          END.

          ASSIGN tt-item-repres.qtde = tt-item-repres.qtde + it-nota-fisc.qt-faturada[1]
                 tt-item-repres.valor = tt-item-repres.valor + it-nota-fisc.vl-tot-item +
                                    IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                                    THEN it-nota-fisc.val-desconto-total 
                                    ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)).
      END.
  END.

  /*

  FOR EACH tt-pedidos.
      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
           nota-fiscal.serie       = tt-pedidos.serie       AND
           nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.
      IF NOT AVAIL nota-fiscal THEN NEXT.

       RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(nota-fiscal.dt-emis-nota) +
                                          " Nota Fiscal: " + nota-fiscal.nr-nota-fis).

      CASE p-tipo-consulta:
          WHEN "2" THEN
              IF nota-fiscal.no-ab-reppri <> p-repres THEN NEXT.
          WHEN "5" THEN DO:
              FIND emitente WHERE
                   emitente.nome-abrev = nota-fiscal.nome-ab-cli NO-LOCK NO-ERROR.
              ASSIGN c-regiao ="".
              IF emitente.pais = "BRASIL" THEN DO:
                 FIND unid-feder WHERE
                      unid-feder.pais = emitente.pais AND
                      unid-feder.estado = emitente.estado NO-LOCK NO-ERROR.
                 IF AVAIL unid-feder THEN
                    ASSIGN c-regiao = unid-feder.char-2.
              END.
              ELSE
                 ASSIGN c-regiao = "Exportaá∆o".

              IF c-regiao <> p-regiao THEN NEXT.
          END.
      END CASE.

      FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.

          ASSIGN c-lote-refer = "1¶Q".  
          IF it-nota-fisc.cod-refer = '888' THEN
             ASSIGN c-lote-refer = "2¶Q".

          FIND item WHERE
               item.it-codigo = it-nota-fisc.it-codigo NO-LOCK NO-ERROR.
          IF NOT AVAIL ITEM THEN NEXT.
          IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
             (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.

          IF it-nota-fisc.it-codigo < c-it-codigo-ini OR 
             it-nota-fisc.it-codigo > c-it-codigo-fin  THEN NEXT.
          RUN pi-ver-digita (INPUT "Item",
                             INPUT it-nota-fisc.it-codigo).
          IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

          IF it-nota-fisc.cod-refer < c-cod-refer-ini OR  
             it-nota-fisc.cod-refer > c-cod-refer-fin THEN NEXT.
          RUN pi-ver-digita (INPUT "Referància",
                             INPUT it-nota-fisc.cod-refer).
          IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

          IF it-nota-fisc.cod-refer <> "" AND  ITEM.deposito-pad <> c-cod-depos THEN NEXT.  /* tecido cru n∆o tem Referencia */
          FIND tt-work WHERE
               tt-work.it-codigo = it-nota-fisc.it-codigo AND
               tt-work.lote      = c-lote-refer           AND
               tt-work.un        = ITEM.un NO-LOCK NO-ERROR.

          IF NOT AVAIL tt-work THEN DO:
             CREATE tt-work.
             ASSIGN tt-work.it-codigo = it-nota-fisc.it-codigo
                    tt-work.desc-item = ITEM.desc-item
                    tt-work.lote      = c-lote-refer
                    tt-work.un        = ITEM.un.
          END.
          ASSIGN tt-work.qtd = tt-work.qtd + it-nota-fisc.qt-faturada[1]
                 tt-work.desc-pratic = tt-work.desc-pratic + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10))
                 tt-work.vlr = tt-work.vlr + it-nota-fisc.vl-tot-item.
          ASSIGN tt-work.pmedio = (tt-work.vlr + tt-work.desc-pratic) / tt-work.qtd.
      END.
  END.
  */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-pedidos D-Dialog 
PROCEDURE pi-pedidos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 FOR EACH tt-pedidos NO-LOCK.
     FIND ped-venda WHERE 
          ped-venda.nr-pedcli = tt-pedidos.nr-pedcli NO-LOCK NO-ERROR.
     IF NOT AVAIL ped-venda THEN NEXT.

      RUN pi-acompanhar IN h-acomp (INPUT "   Data: " + STRING(ped-venda.dt-implant) +
                                         " Pedido: " + ped-venda.nr-pedcli). 
     CASE p-tipo-consulta:
         WHEN "2" THEN
             IF ped-venda.no-ab-reppri <> p-repres THEN NEXT.
         WHEN "5" THEN DO:
             FIND emitente WHERE
                  emitente.nome-abrev = ped-venda.nome-abrev NO-LOCK NO-ERROR.
             ASSIGN c-regiao ="".
             IF emitente.pais = "BRASIL" THEN DO:
                FIND unid-feder WHERE
                     unid-feder.pais = emitente.pais AND
                     unid-feder.estado = emitente.estado NO-LOCK NO-ERROR.
                IF AVAIL unid-feder THEN
                   ASSIGN c-regiao = unid-feder.char-2.
             END.
             ELSE
                ASSIGN c-regiao = "Exportaá∆o".

             IF c-regiao <> p-regiao THEN NEXT.
         END.
     END CASE.

     FOR EACH ped-item OF ped-venda WHERE
              LOOKUP(STRING(ped-item.cod-sit-item),c-sit-ped) > 0 NO-LOCK.

         ASSIGN c-lote-refer = "1¶Q".  
         IF ped-item.cod-refer = '888' THEN
            ASSIGN c-lote-refer = "2¶Q".


         FIND ITEM WHERE
              ITEM.it-codigo = ped-item.it-codigo NO-LOCK NO-ERROR.

         FIND tt-work WHERE
              tt-work.it-codigo = ped-item.it-codigo AND
              tt-work.lote      = c-lote-refer       AND
              tt-work.un        = ITEM.un NO-LOCK NO-ERROR.

         IF NOT AVAIL tt-work THEN DO:
            CREATE tt-work.
            ASSIGN tt-work.it-codigo = ped-item.it-codigo
                   tt-work.desc-item = ITEM.desc-item
                   tt-work.lote      = c-lote-refer
                   tt-work.un        = ITEM.un.
         END.
         ASSIGN tt-work.qtd = tt-work.qtd + ped-item.qt-pedida
                tt-work.vlr = tt-work.vlr + (ped-item.qt-pedida * ped-item.vl-preuni).

     END.
 END.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-processa D-Dialog 
PROCEDURE pi-processa :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 ASSIGN opt-sort = p-tipo-selecao.

 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Calculando_Valores *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 ASSIGN c-sub-tit = "".
 ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DO FATURAMENTO DE: " +
                                                STRING(p-dt-faturadas-ini, "99/99/9999") + " A " + 
                                                STRING(p-dt-faturadas-fin, "99/99/9999").
 ASSIGN c-titulo = "COMPOSICAO DOS ITENS DO FATURAMENTO DE: " + STRING(p-dt-faturadas-ini, "99/99/9999") + " A " + 
                   STRING(p-dt-faturadas-fin, "99/99/9999") + c-sub-tit.

 RUN pi-nota-fiscal.

 RUN pi-finalizar in h-acomp.
 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-total D-Dialog 
PROCEDURE pi-total :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 ASSIGN fi-total-qtd-m   = 0
        fi-total-vlr-m   = 0
        fi-total-qtd-kg  = 0
        fi-total-vlr-kg  = 0
        fi-total-qtd-und = 0
        fi-total-vlr-und = 0.


 FOR EACH tt-work NO-LOCK.

     CASE tt-work.un:
         WHEN 'M' THEN
             ASSIGN fi-total-qtd-m = fi-total-qtd-m + tt-work.qtd
                    fi-total-vlr-m = fi-total-vlr-m + tt-work.vlr.
         WHEN 'KG' THEN
             ASSIGN fi-total-qtd-kg = fi-total-qtd-kg + tt-work.qtd
                    fi-total-vlr-kg = fi-total-vlr-kg + tt-work.vlr.
         WHEN 'UN' THEN
             ASSIGN fi-total-qtd-und = fi-total-qtd-und + tt-work.qtd
                    fi-total-vlr-und = fi-total-vlr-und + tt-work.vlr.
     END CASE.
 END.

 IF fi-total-vlr-m <> 0 THEN
    ASSIGN fi-pmedio-m   = fi-total-vlr-m   / fi-total-qtd-m.
 IF fi-total-vlr-kg <> 0 THEN
    ASSIGN fi-pmedio-kg  = fi-total-vlr-kg  / fi-total-qtd-kg.
 IF fi-total-vlr-und <> 0 THEN
    ASSIGN fi-pmedio-und = fi-total-vlr-und / fi-total-qtd-und.

 DISP fi-total-qtd-m 
      fi-total-vlr-m
      fi-pmedio-m
      fi-total-qtd-kg
      fi-total-vlr-kg
      fi-pmedio-kg
      fi-total-qtd-und
      fi-total-vlr-und
      fi-pmedio-und
      WITH FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-ver-digita D-Dialog 
PROCEDURE pi-ver-digita :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF INPUT PARAMETER p-campo AS CHAR.
 DEF INPUT PARAMETER p-valor AS CHAR.

 IF CAN-FIND(FIRST tt-digita WHERE
                   tt-digita.opcao = 'D'      AND
                   tt-digita.campo = p-campo) AND
    NOT CAN-FIND(FIRST tt-digita WHERE
                       tt-digita.opcao = 'D'      AND
                       tt-digita.campo = p-campo  AND
                       tt-digita.valor = p-valor) THEN RETURN 'ADM-ERROR'.
 ELSE
   IF CAN-FIND(FIRST tt-digita WHERE
                     tt-digita.opcao = 'E' AND
                     tt-digita.campo = p-campo AND
                     tt-digita.valor = p-valor) THEN RETURN 'ADM-ERROR'.
   ELSE
      RETURN 'OK'.


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
  {src/adm/template/snd-list.i "tt-work"}

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

