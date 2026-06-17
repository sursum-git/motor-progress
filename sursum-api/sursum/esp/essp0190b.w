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
{include/i-prgvrs.i ESSP0190B 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
DEF BUFFER empresa FOR mgadm.empresa.
DEF BUFFER unid-feder FOR mgadm.unid-feder.

/* Parameters Definitions ---                                           */

DEFINE TEMP-TABLE tt-pedidos NO-UNDO
       FIELD nr-pedcli   LIKE ped-venda.nr-pedcli
       FIELD nr-nota-fis LIKE nota-fiscal.nr-nota-fis
       FIELD cod-estabel LIKE nota-fiscal.cod-estabel
       FIELD serie       LIKE nota-fiscal.serie
       FIELD exportacao  AS LOG
       FIELD qt-faturada LIKE it-nota-fisc.qt-faturada
       FIELD vl-tot-item LIKE it-nota-fisc.vl-tot-item
       FIELD desc-pratic AS DEC.


DEFINE TEMP-TABLE tt-work NO-UNDO 
       FIELD nr-nota-fis  LIKE nota-fiscal.nr-nota-fis
       FIELD cod-estabel  LIKE nota-fiscal.cod-estabel
       FIELD serie        LIKE nota-fiscal.serie
       FIELD dt-emis-nota LIKE nota-fiscal.dt-emis-nota
       FIELD dt-saida     LIKE nota-fiscal.dt-saida
       FIELD nr-pedcli    LIKE ped-venda.nr-pedcli
       FIELD nr-pedrep    LIKE ped-venda.nr-pedrep
       FIELD nome-abrev   LIKE ped-venda.nome-abrev
       FIELD no-ab-reppri LIKE ped-venda.no-ab-reppri
       FIELD dt-implant   LIKE ped-venda.dt-implant
       FIELD dt-entrega   LIKE ped-venda.dt-entrega
       FIELD Sit          AS CHAR
       FIELD qtde         AS DEC
       FIELD desc-pratic  AS DEC
       FIELD valor        AS DEC
       FIELD preco-tab    LIKE preco-item.preco-venda
       FIELD prazo-medio  LIKE nota-fiscal.nr-praz-med.

DEF TEMP-TABLE tt-digita
    FIELD opcao  AS CHAR
    FIELD campo AS CHAR
    FIELD valor AS CHAR.

DEFINE BUFFER b-tt-work FOR tt-work.


&GLOBAL-DEFINE SORTBY-PHRASE BY IF opt-sort = 1 ~
                                THEN tt-work.nr-pedcli ~
                                ELSE IF opt-sort = 2 ~
                                     THEN tt-work.nr-nota-fis ~
                                     ELSE tt-work.nr-pedcli  

&GLOBAL-DEFINE SORTBY-IMPRESSAO BY IF opt-sort = 1 ~
                                   THEN b-tt-work.nr-pedcli ~
                                   ELSE IF opt-sort = 2 ~
                                        THEN b-tt-work.nr-nota-fis ~
                                        ELSE b-tt-work.nr-pedcli  

DEFINE INPUT PARAMETER TABLE FOR tt-pedidos.  
DEFINE INPUT PARAMETER p-it-codigo        AS CHAR.
DEFINE INPUT PARAMETER p-no-ab-reppri     LIKE ped-venda.no-ab-reppri.
DEFINE INPUT PARAMETER p-matriz           AS DEC.
DEFINE INPUT PARAMETER p-nome-abrev       AS CHAR.
DEFINE INPUT PARAMETER p-regiao           AS CHAR.
DEFINE INPUT PARAMETER p-nat-operacao     AS CHAR.
DEFINE INPUT PARAMETER p-cond-pagto       AS CHAR.
DEFINE INPUT PARAMETER p-tipo-consulta    AS CHAR.
DEFINE INPUT PARAMETER p-dt-faturar       AS CHAR.
DEFINE INPUT PARAMETER p-dt-faturadas-ini AS DATE.
DEFINE INPUT PARAMETER p-dt-faturadas-fin AS DATE.
DEFINE INPUT PARAMETER p-dt-vendido-ini   AS CHAR.
DEFINE INPUT PARAMETER p-dt-vendido-fin   AS CHAR.
DEFINE INPUT PARAMETER p-tipo-selecao     AS INT.
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
DEFINE INPUT PARAMETER p-und              AS CHAR.
DEFINE INPUT PARAMETER p-uf               AS CHAR.
DEFINE INPUT PARAMETER p-gera-duplicata   AS LOG.
DEFINE INPUT PARAMETER p-outros-fat       AS LOG.

/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-ped-venda   AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR gr-nota-fiscal AS ROWID NO-UNDO.

DEF VAR h-acomp      AS HANDLE NO-UNDO.
DEF VAR opt-sort     AS INT.
DEF VAR c-data       AS CHAR FORMAT "x(10)".
DEF VAR de-tot-qtd   AS DEC.
DEF VAR de-tot-vlr   AS DEC.
DEF VAR de-ger-res   AS DEC.
DEF VAR c-sit-ped    AS CHAR.
DEF VAR c-lote-refer AS CHAR.
DEF VAR c-regiao     AS CHAR.
DEF VAR c-selecao    AS CHAR.
DEF VAR i-prz        AS INT.
DEF VAR c-cond-pagto AS CHAR.
DEF VAR c-empresa    AS CHAR.
DEF VAR de-prazo     AS DEC.
DEF VAR i-qtd-nf     AS DEC.

 /* Variaveis da Rotina de Impress∆o */
DEFINE VAR l-ok         AS LOG.
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-ct         AS INT.
DEFINE VAR i-lin        AS INT.
DEFINE VAR i-pag        AS INT.

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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.nr-nota-fis tt-work.nr-pedcli tt-work.nome-abrev tt-work.no-ab-reppri tt-work.dt-emis-nota tt-work.dt-saida tt-work.dt-implant tt-work.dt-entrega tt-work.sit tt-work.qtde tt-work.valor tt-work.desc-pratic ((tt-work.valor + tt-work.desc-pratic) / tt-work.qtde) tt-work.preco-tab tt-work.prazo-medio   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define OPEN-QUERY-br-work RUN pi-total. OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK                                  ~{&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-work rt-buttom bt-detalhe-ped ~
bt-detalhe-nf bt-imprime bt-ok bt-cancela bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS fi-tot-qtd fi-tot-vlr fi-tot-desc ~
fi-pco-medio fi-prazo-medio 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

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

DEFINE BUTTON bt-detalhe-nf 
     IMAGE-UP FILE "image/img-detnf.bmp":U
     LABEL "Detalhe" 
     SIZE 18 BY 1.25 TOOLTIP "Detalhe da Nota Fiscal".

DEFINE BUTTON bt-detalhe-ped 
     IMAGE-UP FILE "image/img-detped.bmp":U
     LABEL "Detalhe" 
     SIZE 15 BY 1.25 TOOLTIP "Detalhe do Pedido".

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/img-pri.bmp":U
     LABEL "Impress∆o" 
     SIZE 13 BY 1.25 TOOLTIP "Imprime o Relat¢rio".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE VARIABLE fi-pco-medio AS DECIMAL FORMAT " ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-prazo-medio AS DECIMAL FORMAT " ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 8 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-desc AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 10 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-qtd AS DECIMAL FORMAT "    ZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE VARIABLE fi-tot-vlr AS DECIMAL FORMAT " ZZZ,ZZZ,ZZ9.99":U INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12 BY .88
     FGCOLOR 1  NO-UNDO.

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 122.43 BY 1.42
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
      tt-work.nr-nota-fis  COLUMN-LABEL "N.Fiscal"      WIDTH  6
      tt-work.nr-pedcli    COLUMN-LABEL "Ped Cli"       WIDTH  8
      tt-work.nome-abrev   COLUMN-LABEL "Cliente"       WIDTH 12
      tt-work.no-ab-reppri COLUMN-LABEL "Representante" WIDTH 12
      tt-work.dt-emis-nota COLUMN-LABEL "Dt.Emiss∆o"    WIDTH 8.5
      tt-work.dt-saida     COLUMN-LABEL "Data Saida"    WIDTH 8.5
      tt-work.dt-implant   COLUMN-LABEL "Dt.Implant"    WIDTH 10
      tt-work.dt-entrega   COLUMN-LABEL "Dt.Entrega"    WIDTH 10
      tt-work.sit          COLUMN-LABEL "Sit"           WIDTH  3
      tt-work.qtde         COLUMN-LABEL "Quantidade"    WIDTH 9
      tt-work.valor        COLUMN-LABEL "Valor"         WIDTH 10
      tt-work.desc-pratic  COLUMN-LABEL "Desc Pratic"   WIDTH 10
      ((tt-work.valor + tt-work.desc-pratic) /
       tt-work.qtde)       COLUMN-LABEL "Preáo MÇdio"
      tt-work.preco-tab    COLUMN-LABEL "Preco Tab"     WIDTH 10
      tt-work.prazo-medio  COLUMN-LABEL "Prazo MÇdio"   WIDTH 9
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 122.86 BY 11.92
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .46.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 1.72
     bt-detalhe-ped AT ROW 13.08 COL 2.57
     bt-detalhe-nf AT ROW 13.08 COL 18
     bt-imprime AT ROW 13.08 COL 36.43
     fi-tot-qtd AT ROW 13.08 COL 55.86 COLON-ALIGNED NO-LABEL NO-TAB-STOP 
     fi-tot-vlr AT ROW 13.13 COL 68.29 COLON-ALIGNED NO-LABEL
     fi-tot-desc AT ROW 13.13 COL 80.43 COLON-ALIGNED NO-LABEL WIDGET-ID 2
     fi-pco-medio AT ROW 13.13 COL 91 COLON-ALIGNED NO-LABEL
     fi-prazo-medio AT ROW 13.13 COL 110.57 COLON-ALIGNED NO-LABEL WIDGET-ID 4
     bt-ok AT ROW 14.75 COL 2.43
     bt-cancela AT ROW 14.75 COL 13.43
     bt-ajuda AT ROW 14.75 COL 112.86
     "Totais:" VIEW-AS TEXT
          SIZE 5 BY .88 AT ROW 13.04 COL 52.72
     rt-buttom AT ROW 14.54 COL 1.57
     SPACE(0.85) SKIP(0.24)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Detalha Pedidos - ESSP0190B"
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
/* BROWSE-TAB br-work TEXT-1 D-Dialog */
ASSIGN 
       FRAME D-Dialog:SCROLLABLE       = FALSE
       FRAME D-Dialog:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN fi-pco-medio IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-prazo-medio IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-desc IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-qtd IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-tot-vlr IN FRAME D-Dialog
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
RUN pi-total.
OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK
                                 ~{&SORTBY-PHRASE}.
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Detalha Pedidos - ESSP0190B */
DO:  
  /* Add Trigger to equate WINDOW-CLOSE to END-ERROR. */
  APPLY "END-ERROR":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON VALUE-CHANGED OF br-work IN FRAME D-Dialog
DO:
  ASSIGN bt-detalhe-ped:SENSITIVE IN FRAME {&FRAME-NAME} = YES
         bt-detalhe-nf:SENSITIVE IN FRAME {&FRAME-NAME}  = YES.
  IF tt-work.nr-pedcli = "" THEN
     ASSIGN bt-detalhe-ped:SENSITIVE IN FRAME {&FRAME-NAME} = NO.
  IF tt-work.nr-nota-fis = "" THEN
     ASSIGN bt-detalhe-nf:SENSITIVE IN FRAME {&FRAME-NAME} = NO.


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


&Scoped-define SELF-NAME bt-detalhe-nf
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-detalhe-nf D-Dialog
ON CHOOSE OF bt-detalhe-nf IN FRAME D-Dialog /* Detalhe */
DO:
  IF AVAIL tt-work THEN DO:
      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-work.cod-estabel AND
           nota-fiscal.serie       = tt-work.serie       AND
           nota-fiscal.nr-nota-fis = tt-work.nr-nota-fis NO-LOCK NO-ERROR.
     IF AVAIL nota-fiscal THEN DO:
        ASSIGN gr-nota-fiscal = ROWID(nota-fiscal).
        ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
        RUN ftp/ft0904.
        ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
     END.  
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-detalhe-ped
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-detalhe-ped D-Dialog
ON CHOOSE OF bt-detalhe-ped IN FRAME D-Dialog /* Detalhe */
DO:
  IF AVAIL tt-work THEN DO:
     FIND ped-venda WHERE
          ped-venda.nr-pedcli  = tt-work.nr-pedcli AND
          ped-venda.nome-abrev = tt-work.nome-abrev NO-LOCK NO-ERROR.
     ASSIGN gr-ped-venda = ROWID(ped-venda).
     ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
     RUN esp\espd4000.w (INPUT "Consultar").
     ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime D-Dialog
ON CHOOSE OF bt-imprime IN FRAME D-Dialog /* Impress∆o */
DO:
  RUN pi-imprime.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

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
  DISPLAY fi-tot-qtd fi-tot-vlr fi-tot-desc fi-pco-medio fi-prazo-medio 
      WITH FRAME D-Dialog.
  ENABLE br-work rt-buttom bt-detalhe-ped bt-detalhe-nf bt-imprime bt-ok 
         bt-cancela bt-ajuda 
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

  /* {utp/ut9000.i "ESSP0174A" "2.04.00.000"} */ 

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
  APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cabec-item D-Dialog 
PROCEDURE pi-cabec-item :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 PUT "Seq  Item    Referencia  Lote  Corte       Quantidade  Reservado" AT 19.
 PUT "---  ------  ----------  ----  ----------  ----------  ---------" AT 19.
 ASSIGN i-lin = i-lin + 2.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cond-pagto D-Dialog 
PROCEDURE pi-cond-pagto :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT PARAMETER p-ped-venda-cod-cond-pag LIKE ped-venda.cod-cond-pag.
DEFINE INPUT PARAMETER p-ped-venda-nr-pedido    LIKE ped-venda.nr-pedido.
DEFINE INPUT-OUTPUT PARAMETER p-cond-pagto      AS CHAR.
DEFINE INPUT PARAMETER p-exportacao  AS LOG.

  FIND cond-pagto WHERE
       cond-pagto.cod-cond-pag = p-ped-venda-cod-cond-pag NO-LOCK NO-ERROR.
  IF NOT AVAIL cond-pagto THEN DO: /* Rotina para Tabela COND-PED */
      ASSIGN i-ct        = 0
             i-prz       = 0.
      FOR EACH cond-ped WHERE
               cond-ped.nr-pedido = p-ped-venda-nr-pedido NO-LOCK.
          ASSIGN i-ct  = i-ct + 1.
          ASSIGN i-prz = i-prz + cond-ped.nr-dias-venc.
      END.
      IF i-ct = 0 THEN DO: /* N∆o Gera Duplicatas Lojas TEAR TEXTIL */
         ASSIGN p-cond-pagto = " N∆o Gera Duplicatas".
      END.
      ELSE DO: /* Condiá∆o de Pagamento Especial */
          ASSIGN i-prz = INT(i-prz / i-ct).
          IF i-prz <= 30 THEN
             ASSIGN p-cond-pagto = " De 01 AtÇ 30 Dias".
          ELSE
          IF i-prz <= 60 THEN
             ASSIGN p-cond-pagto = " De 31 AtÇ 60 Dias".
          ELSE
          IF i-prz <= 90 THEN
             ASSIGN p-cond-pagto = " De 61 AtÇ 90 Dias".
          ELSE
             ASSIGN p-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */
      END.
  END.
  ELSE DO:  /* Rotina da Tabela COND-PAGTO */
      IF p-ped-venda-cod-cond-pag = 1 OR       /* A Vista */
         p-ped-venda-cod-cond-pag = 2 OR       /* Antecipado */
         p-ped-venda-cod-cond-pag = 3 THEN DO: /* Contra Apresentaá∆o */
         CASE p-ped-venda-cod-cond-pag:
             WHEN 1 THEN
                 ASSIGN p-cond-pagto = " A Vista".
             WHEN 2 THEN
                 ASSIGN p-cond-pagto = " A Vista".
             WHEN 3 THEN
                 ASSIGN p-cond-pagto = " Contra Apresentaá∆o".
         END CASE.

      END.
      ELSE DO:
          IF cond-pagto.log-2 = NO THEN DO: /* Vendas N∆o VENDOR */
             ASSIGN i-prz = 0
                    i-ct  = 0.
             DO i-lin = 1 TO 12: /* Armazena Prazos e Calcula o Nß de Parcelas */
                IF cond-pagto.prazos[i-lin] <> 0 THEN
                   ASSIGN i-ct  = i-ct  + 1
                          i-prz = i-prz + cond-pagto.prazos[i-lin].
             END.

             ASSIGN i-prz = INT(i-prz / i-ct).

             IF i-prz <= 30 THEN
                ASSIGN p-cond-pagto = " De 01 AtÇ 30 Dias".
             ELSE
             IF i-prz <= 60 THEN
                ASSIGN p-cond-pagto = " De 31 AtÇ 60 Dias".
             ELSE
             IF i-prz <= 90 THEN
                ASSIGN p-cond-pagto = " De 61 AtÇ 90 Dias".
             ELSE
                ASSIGN p-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */

          END.
          ELSE DO: /* VENDOR */
              ASSIGN p-cond-pagto = "ˇVENDOR". /* 1¶ Posiá∆o Ç ALT 164 */
          END.
      END.
  END. /* KBO Condiá∆o de Pagto */
  IF p-exportacao = YES THEN /* Nota Fiscal de Exportaá∆o */
     ASSIGN p-cond-pagto = "ˇExportaá∆o". /* 1¶ Posiá∆o Ç ALT 164 */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cond-pg D-Dialog 
PROCEDURE pi-cond-pg :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

DEFINE INPUT PARAMETER p-cod-estabel  LIKE nota-fiscal.cod-estabel.
DEFINE INPUT PARAMETER p-serie        LIKE nota-fiscal.serie.
DEFINE INPUT PARAMETER p-nr-nota-fis  LIKE nota-fiscal.nr-nota-fis.
DEFINE INPUT PARAMETER p-cod-cond-pag LIKE nota-fiscal.cod-cond-pag.
DEFINE INPUT-OUTPUT PARAMETER p-cond-pagto AS CHAR.
DEFINE INPUT PARAMETER p-exportacao        AS LOG.

DEF VAR i-ct         AS INT.
DEF VAR i-cod-vencto AS INT.
DEF VAR i-prz        AS INT.

ASSIGN i-ct         = 0
       p-cond-pagto = ""
       i-cod-vencto = 0
       i-prz        = 0.
FOR EACH fat-duplic WHERE
         fat-duplic.cod-estabel = p-cod-estabel AND
         fat-duplic.serie       = p-serie       AND
         fat-duplic.nr-fatura   = p-nr-nota-fis NO-LOCK.
         ASSIGN i-prz        = i-prz + (fat-duplic.dt-vencimen - fat-duplic.dt-emissao)
                i-ct         = i-ct + 1
                i-cod-vencto = fat-duplic.cod-vencto.
END.
IF i-prz <> 0 OR i-cod-vencto = 2 OR i-cod-vencto = 9 THEN DO: /* i-cod-vencto 2=Vista  9=Contra Apresentaá∆o */
   IF i-cod-vencto = 2 THEN
      ASSIGN p-cond-pagto = " A Vista".
   ELSE
   IF i-cod-vencto = 9 THEN
      ASSIGN p-cond-pagto = " Contra Apresentaá∆o".
   ELSE DO:
      i-prz = INT(i-prz / i-ct).
      IF i-prz <= 30 THEN
         ASSIGN p-cond-pagto = " De 01 AtÇ 30 Dias".
      ELSE
      IF i-prz <= 60 THEN
         ASSIGN p-cond-pagto = " De 31 AtÇ 60 Dias".
      ELSE
      IF i-prz <= 90 THEN
         ASSIGN p-cond-pagto = " De 61 AtÇ 90 Dias".
      ELSE
         ASSIGN p-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */
   END.
END.
ELSE DO:
   FIND cond-pagto WHERE
        cond-pagto.cod-cond-pag = p-cod-cond-pag NO-LOCK NO-ERROR.
   IF AVAIL cond-pagto THEN DO:
       ASSIGN p-cond-pagto = cond-pagto.descricao.
      IF cond-pagto.log-2 THEN /* Faturamento Ç para VENDOR */
         ASSIGN p-cond-pagto = "ˇVendor". /* 1¶ Posiá∆o Ç ALT 164 */
   END.
END.

IF p-cond-pagto = "" THEN DO:
   IF AVAIL ped-venda THEN
      ASSIGN p-cond-pagto = "Outros Faturamento".
   ELSE
      ASSIGN p-cond-pagto = " Cupom Fiscal".
END.
IF p-exportacao = YES THEN /* Nota Fiscal de Exportaá∆o */
   ASSIGN p-cond-pagto = "ˇExportaá∆o". /* 1¶ Posiá∆o Ç ALT 164 */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cor D-Dialog 
PROCEDURE pi-cor :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF INPUT PARAMETER p-cor AS INT.

 tt-work.nr-pedcli:FGCOLOR IN BROWSE    {&browse-name} = p-cor.
 tt-work.nome-abrev:FGCOLOR IN BROWSE   {&browse-name} = p-cor.
 tt-work.no-ab-reppri:FGCOLOR IN BROWSE {&browse-name} = p-cor.
 tt-work.dt-implant:FGCOLOR IN BROWSE   {&browse-name} = p-cor.
 tt-work.dt-entrega:FGCOLOR IN BROWSE   {&browse-name} = p-cor.
 tt-work.sit:FGCOLOR IN BROWSE          {&browse-name} = p-cor.
 tt-work.qtd:FGCOLOR IN BROWSE          {&browse-name} = p-cor.
 tt-work.valor:FGCOLOR IN BROWSE        {&browse-name} = p-cor. 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-detalhe D-Dialog 
PROCEDURE pi-detalhe :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-nr-pedcli  AS CHAR.
 DEF VAR l-imp-cab-item AS LOG INITIAL YES.
 DEF VAR de-reservado AS DEC.
 DEF VAR de-tot-res   AS DEC.

 ASSIGN c-sit-ped = "1,2,4,5". /* Aberto, Atendido Parcial,Pendente,Suspendo */


 FIND ped-venda WHERE
      ped-venda.nr-pedcli = p-nr-pedcli NO-LOCK NO-ERROR.
 IF AVAIL ped-venda THEN DO:
    ASSIGN de-tot-res = 0.
    FOR EACH ped-item OF ped-venda WHERE
              LOOKUP(STRING(ped-item.cod-sit-item),c-sit-ped) > 0 AND 
              ped-item.it-codigo >= c-it-codigo-ini AND
              ped-item.it-codigo <= c-it-codigo-fin AND
              ped-item.cod-refer >= c-cod-refer-ini AND 
              ped-item.cod-refer <= c-cod-refer-fin NO-LOCK.



         RUN pi-ver-digita (INPUT "Item",
                            INPUT ped-item.it-codigo).
         IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

         RUN pi-ver-digita (INPUT "Referància",
                            INPUT ped-item.cod-refer).
         IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.
         /*
         RUN pi-ver-digita (INPUT "Corte_Comercial",
                            INPUT ped-item-ext.corte-comerc).
         IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.
         */
         FIND item WHERE
              item.it-codigo = ped-item.it-codigo NO-LOCK NO-ERROR.
         
         /* Criado por Anderson 23/11/2010 */
         /* Procura o deposito padrao da natureza*/
         IF c-cod-depos <> "TODOS" THEN DO:
             FIND FIRST natur-oper-deposito WHERE natur-oper-deposito.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
             IF (AVAIL natur-oper-deposito AND natur-oper-deposito.cod-depos <> c-cod-depos)OR 
                (NOT AVAIL natur-oper-deposito AND c-cod-depos <> "ARM") THEN NEXT.
         END.
         /* Fim Anderson */

         /* Comentado por Anderson 23/11/2010
         IF ITEM.deposito-pad <> c-cod-depos THEN NEXT.
         */
         IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
            (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.
         /*
         FIND ref-item-ext WHERE
              ref-item-ext.it-codigo = ped-item.it-codigo AND
              ref-item-ext.cod-refer = ped-item.cod-refer NO-LOCK NO-ERROR.
         IF AVAIL ref-item-ext THEN DO:
            IF (ref-item-ext.cod-obsoleto < c-cod-obsoleto-ini OR
                ref-item-ext.cod-obsoleto > c-cod-obsoleto-fin) THEN NEXT.

            RUN pi-ver-digita (INPUT "Codigo_Obsoleto",
                               INPUT ref-item-ext.cod-obsoleto).
            IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.
         END.

         IF c-tipo-acabamento = "E" AND SUBSTR(ped-item.cod-refer,7,1) <> '0' THEN NEXT.
         IF c-tipo-acabamento = "L" AND SUBSTR(ped-item.cod-refer,7,1)  = '0' THEN NEXT.
         */
         /*
         ASSIGN de-reservado = 0.
         FIND ped-item-res OF ped-item WHERE
              ped-item-res.faturado = NO NO-LOCK NO-ERROR.
         IF AVAIL ped-item-res THEN
            ASSIGN de-reservado = ped-item-res.qt-pedida.
         */
         IF i-lin > 62 THEN DO:
            RUN pi-imp-cabec.
            ASSIGN i-lin = 7
                   l-imp-cab-item = YES.
         END.
         IF l-imp-cab-item THEN
            RUN pi-cabec-item.
/*
         FIND corte-comerc WHERE
              corte-comerc.codigo = ped-item-ext.corte-comerc NO-LOCK NO-ERROR.
*/
         PUT ped-item.nr-sequencia FORMAT ">>9"      AT 19
             ped-item.it-codigo    FORMAT "x(6)"     AT 24
             ped-item.cod-refer    FORMAT "x(7)"     AT 32
 /*            SUBSTR(ped-item-ext.lote,1,2) FORMAT "x(2)"           AT 44
             SUBSTR(corte-comerc.descricao,1,9)      AT 50 */
             ped-item.qt-pedida FORMAT ">>>,>>9.99"  AT 62
             de-reservado       FORMAT ">>,>>9.99"   AT 74.

         ASSIGN i-lin      = i-lin + 1
                de-tot-res = de-tot-res + de-reservado
                de-ger-res = de-ger-res + de-reservado.

         ASSIGN l-imp-cab-item = NO.
      END.
      IF de-tot-res <> 0 THEN DO:
         PUT "---------" AT 74.
         ASSIGN i-lin = i-lin + 1.
         PUT de-tot-res  FORMAT ">>,>>9.99"   AT 74.
         ASSIGN i-lin = i-lin + 1.
      END.
 END.

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
     "DATA: "                                  AT  58
     STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  64
     "HORA: "                                  AT  85
     STRING(TIME,"hh:mm:ss")                   AT  91
     "PAG:"                                    AT 125
     i-pag FORMAT ">>"                         AT 130
     SKIP(1).

 CASE p-tipo-selecao:
     WHEN 1 THEN DO:
         PUT "ANALISE DA CARTEIRA A FATURAR NO PERIODO: " +  SUBSTR(p-dt-faturar,1,2) + "/"+ SUBSTR(p-dt-faturar,3,4) + 
             c-selecao FORMAT "x(100)" AT 25 SKIP(1).                                     
         PUT "Ped Cli  Ped. Repres. Cliente      Representante Sit Dt.Implant Dt.Entrega  QTD a Faturar  VLR a Faturar" AT 10.
         PUT " ------- ------------ ------------ ------------- --- ---------- ---------- -------------- --------------" AT 10.
     END.
     WHEN 2 THEN DO:
         PUT "ANALISE DO FATURAMENTO DE: " + STRING(p-dt-faturadas-ini, "99/99/9999") + " A " +  STRING(p-dt-faturadas-fin, "99/99/9999") +
             c-selecao FORMAT "x(100)" AT 25 SKIP(1).
         PUT "N.Fiscal Ped Cli Ped. Repres. Cliente      Representante  Dt.Implant Dt.Entrega   Qtde Vendida  Valor Vendido   Desc. Pratic P.MÇdio" AT 1.
         PUT "-------- ------- ------------ ------------ -------------- ---------- ---------- -------------- -------------- -------------- -------" AT 1.
     END.
     WHEN 3 THEN DO:
         PUT "ANALISE DAS VENDAS DE: " + SUBSTR(p-dt-vendido-ini,1,2) + "/"+ SUBSTR(p-dt-vendido-ini,3,4) + " A " +
                                         SUBSTR(p-dt-vendido-fin,1,2) + "/"+ SUBSTR(p-dt-vendido-fin,3,4) +
                                         c-selecao FORMAT "x(100)" AT 25 SKIP(1).
         PUT "Ped Cli  Ped. Repres. Cliente      Representante Sit Dt.Implant Dt.Entrega   Qtde Vendida  Valor Vendido" AT 10.
         PUT " ------- ------------ ------------ ------------- --- ---------- ---------- -------------- --------------" AT 10.
     END.
 END CASE.
 
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

 DEF VAR i-col AS INT INITIAL 0.

 IF p-tipo-selecao = 2 THEN
    ASSIGN i-col = 4.

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
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0190b.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.

 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-pag      =  1
           i-lin      = 99.
    FOR EACH b-tt-work WHERE NO-LOCK
              {&SORTBY-IMPRESSAO}.
        
        IF i-lin > 62 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
        IF p-tipo-selecao = 2 THEN
           PUT b-tt-work.nr-nota-fis  FORMAT "x(7)"    AT 01
               b-tt-work.nr-pedcli    FORMAT "x(6)"    AT 10   
               b-tt-work.nr-pedrep                     AT 19   
               b-tt-work.nome-abrev                    AT 31   
               b-tt-work.no-ab-reppri                  AT 44   
               b-tt-work.dt-emis-nota                  AT 59   
               b-tt-work.dt-saida                      AT 70   
               b-tt-work.qtde        FORMAT ">>>,>>>,>>9.99" AT  81   
               b-tt-work.valor       FORMAT ">>>,>>>,>>9.99" AT  96
               b-tt-work.desc-pratic FORMAT ">>>,>>>,>>9.99" AT 111
               (b-tt-work.valor + b-tt-work.desc-pratic) /
                b-tt-work.qtde       FORMAT ">>>9.99"        AT 126.
               
        ELSE
           PUT b-tt-work.nr-pedcli  FORMAT "x(6)"      AT 10
               b-tt-work.nr-pedrep                     AT 19
               b-tt-work.nome-abrev                    AT 32
               b-tt-work.no-ab-reppri                  AT 45
               b-tt-work.sit  FORMAT "x(3)"            AT 59
               b-tt-work.dt-implant                    AT 63
               b-tt-work.dt-entrega                    AT 74
               b-tt-work.qtde  FORMAT ">>>,>>>,>>9.99" AT 85
               b-tt-work.valor FORMAT ">>>,>>>,>>9.99" AT 100.

        ASSIGN i-lin = i-lin + 1.
        ACCUMULATE b-tt-work.qtde (TOTAL).
        ACCUMULATE b-tt-work.valor (TOTAL).
        ACCUMULATE b-tt-work.desc-pratic (TOTAL).

        IF p-tipo-selecao = 1 AND p-tipo-consulta = '1' THEN
           RUN pi-detalhe (INPUT b-tt-work.nr-pedcli).
    END.
    IF (ACCUM TOTAL b-tt-work.qtde)  <> 0 OR
       (ACCUM TOTAL b-tt-work.valor) <> 0 THEN DO:
       IF i-lin > 59 THEN DO:
          RUN pi-imp-cabec.
          ASSIGN i-lin = 7.
       END.
       PUT "" AT 1.
       IF p-tipo-selecao = 1 AND p-tipo-consulta = '1' THEN DO:
           PUT "--------- -------------- --------------" AT 74 SKIP.
           PUT "Total Geral.........:" AT 53.
           PUT de-ger-res                  FORMAT ">>,>>9.99"      AT 74.
           PUT ACCUM TOTAL b-tt-work.qtde  FORMAT ">>>,>>>,>>9.99" AT 84.
           PUT ACCUM TOTAL b-tt-work.valor FORMAT ">>>,>>>,>>9.99" AT 99.
       END.
       ELSE DO:
          PUT "-------------- -------------- --------------" AT (85 - i-col) SKIP.
          PUT "Total Geral.........:"              AT (63 - i-col).
          PUT ACCUM TOTAL b-tt-work.qtde  FORMAT ">>>,>>>,>>9.99" AT (85 - i-col).
          PUT ACCUM TOTAL b-tt-work.valor FORMAT ">>>,>>>,>>9.99" AT (100 - i-col).
          PUT ACCUM TOTAL b-tt-work.desc-pratic FORMAT ">>>,>>>,>>9.99" AT (115 - i-col).
       END.
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
  DEF VAR de-qtd  AS DEC.
  DEF VAR de-vlr  AS DEC.
  DEF VAR de-desc AS DEC.
  FOR EACH tt-pedidos.

      FIND nota-fiscal WHERE
           nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
           nota-fiscal.serie       = tt-pedidos.serie       AND
           nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.

      IF NOT AVAIL nota-fiscal THEN NEXT.

      RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(nota-fiscal.dt-emis-nota) +
                                          " Nota Fiscal: " + nota-fiscal.nr-nota-fis).

      IF nota-fiscal.nr-pedcli <> "" THEN DO:
         FIND ped-venda WHERE
              ped-venda.nome-abrev = nota-fiscal.nome-ab-cli AND
              ped-venda.nr-pedcli  = nota-fiscal.nr-pedcli NO-LOCK NO-ERROR.
         IF NOT AVAIL ped-venda THEN NEXT.
      END.
       
      FIND emitente WHERE
           emitente.nome-abrev = nota-fiscal.nome-ab-cli NO-LOCK NO-ERROR.
      IF NOT AVAIL emitente THEN NEXT.

      FIND natur-oper WHERE
           natur-oper.nat-operacao = nota-fiscal.nat-operacao NO-LOCK NO-ERROR.
      IF NOT AVAIL natur-oper THEN NEXT.

      IF p-gera-duplicata = NO AND p-outros-fat = NO THEN 
         IF natur-oper.cod-esp <> "DP" THEN NEXT. /* Ped. que Geraram Dupl */

      IF p-outros-fat AND p-gera-duplicata = NO THEN
         IF natur-oper.cod-esp = "DP" THEN NEXT. /* Ped. que Geraram Dupl */

      CASE p-tipo-consulta:
          WHEN '1' THEN DO: /* Item */
          END.
          WHEN '2' THEN    /* Representante */
              IF nota-fiscal.no-ab-reppri <> "" AND nota-fiscal.no-ab-reppri <> p-no-ab-reppri THEN
                 NEXT.
          WHEN '3' THEN  /* Grupo */
              /*IF emitente.nome-matriz <> p-matriz THEN NEXT */.
          WHEN '4' THEN  /* Cliente */
              IF nota-fiscal.nome-ab-cli <> p-nome-abrev THEN NEXT.
          WHEN '5' THEN DO: /* Regiao */
              IF p-uf <> "ZZ" AND emitente.estado <> p-uf THEN NEXT.
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
          WHEN '6' THEN DO: /* Natureza da Operaá∆o */
              IF nota-fiscal.nat-operacao <> p-nat-operacao THEN NEXT.
          END.
          WHEN '7' THEN DO: /* Condiá∆o de Pagamento */
              IF nota-fiscal.nr-pedcli <> "" THEN DO:
                 RUN pi-cond-pg (INPUT nota-fiscal.cod-estabel,
                                 INPUT nota-fiscal.serie,
                                 INPUT nota-fiscal.nr-nota-fis,
                                 INPUT nota-fiscal.cod-cond-pag,
                                 INPUT-OUTPUT c-cond-pagto,
                                 INPUT tt-pedidos.exportacao).

                 IF c-cond-pagto <> p-cond-pagto THEN NEXT.
              END.
          END.
      END CASE.

      ASSIGN de-qtd  = 0
             de-desc = 0
             de-vlr  = 0.
      FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
          IF p-tipo-consulta = '1'  AND it-nota-fisc.it-codigo <> p-it-codigo THEN NEXT.

          ASSIGN c-lote-refer = "1¶Q".  
          IF it-nota-fisc.cod-refer = '888' THEN
             ASSIGN c-lote-refer = "2¶Q".

          IF p-lote <> "" AND  c-lote-refer <> p-lote THEN NEXT.

          FIND item WHERE
               item.it-codigo = it-nota-fisc.it-codigo NO-LOCK NO-ERROR.
          IF NOT AVAIL ITEM THEN NEXT.

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
          
          IF nota-fiscal.nr-pedcli <> "" AND AVAIL ITEM THEN DO:
             /* Criado por Anderson 23/11/2010 */
             /* Procura o deposito padrao da natureza*/
             IF c-cod-depos <> "TODOS" THEN DO:
                 FIND FIRST natur-oper-deposito WHERE natur-oper-deposito.nat-operacao = nota-fiscal.nat-operacao NO-LOCK NO-ERROR.
                 IF (AVAIL natur-oper-deposito AND natur-oper-deposito.cod-depos <> c-cod-depos)OR 
                    (NOT AVAIL natur-oper-deposito AND c-cod-depos <> "ARM") THEN NEXT.
             END.
             /* Fim Anderson */

             /* Comentado por Anderson 23/11/2010
             IF it-nota-fisc.cod-refer <> "" AND  ITEM.deposito-pad <> c-cod-depos THEN NEXT.  /* tecido cru n∆o tem Referencia */
             */

             IF ITEM.un <> p-und THEN NEXT.
             IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
                (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.
          END.
          ELSE
             IF ITEM.un <> p-und THEN NEXT.

          IF c-tipo-acabamento = "E" AND SUBSTR(it-nota-fisc.cod-refer,7,1) <> '0' THEN NEXT.
          IF c-tipo-acabamento = "L" AND SUBSTR(it-nota-fisc.cod-refer,7,1)  = '0' THEN NEXT.
          
          ASSIGN de-qtd  = de-qtd  + it-nota-fisc.qt-faturada[1]
                 de-desc = de-desc + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10))
                 de-vlr  = de-vlr  + it-nota-fisc.vl-tot-item. 
      END.
      IF de-qtd + de-vlr = 0 THEN NEXT.

      FIND repres WHERE
           repres.nome-abrev = nota-fiscal.no-ab-reppri NO-LOCK NO-ERROR.
      IF NOT AVAIL repres THEN
         FIND repres WHERE
              repres.cod-rep = 1 NO-LOCK NO-ERROR.

      FIND tt-work WHERE
           tt-work.nr-nota-fis = nota-fiscal.nr-nota-fis NO-LOCK NO-ERROR.
      IF NOT AVAIL tt-work THEN DO:
         CREATE tt-work.
         ASSIGN tt-work.nr-nota-fis  = nota-fiscal.nr-nota-fis
                tt-work.cod-estabel  = tt-pedidos.cod-estabel
                tt-work.serie        = tt-pedidos.serie
                tt-work.nr-pedcli    = nota-fiscal.nr-pedcli
                tt-work.nome-abrev   = nota-fiscal.nome-ab-cli
                tt-work.no-ab-reppri = repres.nome-abrev
                tt-work.dt-emis-nota = nota-fiscal.dt-emis-nota
                tt-work.dt-saida     = nota-fiscal.dt-saida
                tt-work.qtde         = de-qtd  
                tt-work.desc-pratic  = de-desc
                tt-work.valor        = de-vlr
                tt-work.prazo-medio  = nota-fiscal.nr-praz-med
                tt-work.preco-tab    = IF AVAIL preco-item
                                       THEN preco-item.preco-venda
                                       ELSE 0.

         IF nota-fiscal.nr-pedcli <> "" THEN
            ASSIGN tt-work.nr-pedrep    = ped-venda.nr-pedrep.

      END.
  END.

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

     FIND emitente WHERE
          emitente.nome-abrev = ped-venda.nome-abrev NO-LOCK NO-ERROR.
     IF NOT AVAIL emitente THEN NEXT.

     FIND natur-oper WHERE
          natur-oper.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
     IF NOT AVAIL natur-oper THEN NEXT.

     CASE p-tipo-consulta:
         WHEN '2' THEN
             IF ped-venda.no-ab-reppri <> p-no-ab-reppri THEN NEXT.
         WHEN '3' THEN
             /*IF emitente.nome-matriz <> p-matriz THEN NEXT */.
         WHEN '4' THEN
             IF ped-venda.nome-abrev <> p-nome-abrev THEN NEXT.
         WHEN '5' THEN DO:
             IF p-uf <> "ZZ" AND emitente.estado <> p-uf THEN NEXT.
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
         WHEN '6' THEN
             IF ped-venda.nat-operacao <> p-nat-operacao THEN NEXT.
         WHEN '7' THEN DO:
             RUN pi-cond-pagto (INPUT ped-venda.cod-cond-pag,
                                INPUT ped-venda.nr-pedido,
                                INPUT-OUTPUT c-cond-pagto).
             IF c-cond-pagto <> p-cond-pagto THEN NEXT.
         END.
     END CASE.

     ASSIGN de-tot-qtd = 0
            de-tot-vlr = 0.
     FOR EACH ped-item OF ped-venda WHERE
              LOOKUP(STRING(ped-item.cod-sit-item),c-sit-ped) > 0 NO-LOCK.

         IF p-tipo-consulta = '1'  AND ped-item.it-codigo <> p-it-codigo THEN NEXT.

         IF p-uf <> "ZZ" THEN DO:
            /*
            FIND ped-item-ext WHERE 
                 ped-item-ext.nome-abrev   = ped-item.nome-abrev   AND
                 ped-item-ext.nr-pedcli    = ped-item.nr-pedcli    AND
                 ped-item-ext.nr-sequencia = ped-item.nr-sequencia AND
                 ped-item-ext.it-codigo    = ped-item.it-codigo    AND
                 ped-item-ext.cod-refer    = ped-item.cod-refer NO-LOCK NO-ERROR.
            IF AVAIL ped-item-ext AND SUBSTR(ped-item-ext.lote,1,2) <> p-lote THEN NEXT.
            */
         END.

         FIND item WHERE
              item.it-codigo = ped-item.it-codigo NO-LOCK NO-ERROR.
         IF AVAIL ITEM THEN DO:
            /* Criado por Anderson 23/11/2010 */
            /* Procura o deposito padrao da natureza*/
            IF c-cod-depos <> "TODOS" THEN DO:
                FIND FIRST natur-oper-deposito WHERE natur-oper-deposito.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
                IF (AVAIL natur-oper-deposito AND natur-oper-deposito.cod-depos <> c-cod-depos)OR 
                   (NOT AVAIL natur-oper-deposito AND c-cod-depos <> "ARM") THEN NEXT.
            END.
            /* Fim Anderson */
            /* Comentado por Anderson 23/11/2010 
            IF ITEM.deposito-pad <> c-cod-depos THEN NEXT. 
            */
            IF ITEM.un <> p-und THEN NEXT.
            IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
               (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.
         END.

         ASSIGN de-tot-qtd = de-tot-qtd + ped-item.qt-pedida
                de-tot-vlr = de-tot-vlr + (ped-item.qt-pedida * ped-item.vl-preuni).

     END.
     IF de-tot-qtd + de-tot-vlr = 0 THEN NEXT.
     /*
     FIND FIRST preco-item WHERE
                preco-item.nr-tabpre = "TAB A07" AND /* substituir pela tabela selecionada */  
                preco-item.it-codigo = ped-item.it-codigo NO-LOCK NO-ERROR.
     */
     FIND tt-work WHERE
          tt-work.nr-pedcli = ped-venda.nr-pedcli NO-LOCK NO-ERROR.
     IF NOT AVAIL tt-work THEN DO:
        CREATE tt-work.
        ASSIGN tt-work.nr-pedcli    = ped-venda.nr-pedcli
               tt-work.nr-pedrep    = ped-venda.nr-pedrep
               tt-work.nome-abrev   = ped-venda.nome-abrev
               tt-work.no-ab-reppri = ped-venda.no-ab-reppri
               tt-work.dt-implant   = ped-venda.dt-implant
               tt-work.dt-entrega   = ped-venda.dt-entrega
               tt-work.qtde         = de-tot-qtd
               tt-work.valor        = de-tot-vlr
               tt-work.preco-tab    = IF AVAIL preco-item
                                      THEN preco-item.preco-venda
                                      ELSE 0.
        CASE ped-venda.cod-sit-ped.
             WHEN 1 THEN ASSIGN tt-work.sit = 'ABE'.
             WHEN 2 THEN ASSIGN tt-work.sit = 'ATP'.
             WHEN 3 THEN ASSIGN tt-work.sit = 'ATT'.
             WHEN 4 THEN ASSIGN tt-work.sit = 'PEN'.
             WHEN 5 THEN ASSIGN tt-work.sit = 'SUS'.
             WHEN 6 THEN ASSIGN tt-work.sit = 'CAN'.
        END CASE.
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
 CASE p-tipo-consulta:
     WHEN '1' THEN
         ASSIGN c-selecao = "  ITEM: " + p-it-codigo.
     WHEN '2' THEN
         ASSIGN c-selecao = "  REPRESENTANTE: " + p-no-ab-reppri.
     WHEN '3' THEN
         /*ASSIGN c-selecao = "  GRUPO: " + p-matriz */.
     WHEN '4' THEN
         ASSIGN c-selecao = "  CLIENTE: " + p-nome-abrev.
     WHEN '5' THEN
         ASSIGN c-selecao = "  REGI«O: " + UPPER(p-regiao).
     WHEN '6' THEN
         ASSIGN c-selecao = "  NATUREZA DA OPERAÄ«O: " + p-nat-operacao.
     WHEN '7' THEN
         ASSIGN c-selecao = "  CONDIÄ«O PAGAMENTO: " + UPPER(p-cond-pagto).
 END CASE.

 ASSIGN opt-sort = p-tipo-selecao.

 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Calculando_Valores *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 tt-work.nr-nota-fis:VISIBLE IN BROWSE br-work  = NO.  
 tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = NO.    
 tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = NO.   
 tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = NO. 
 tt-work.dt-emis-nota:VISIBLE IN BROWSE br-work = NO. 
 tt-work.dt-saida:VISIBLE IN BROWSE br-work     = NO.     
 tt-work.dt-implant:VISIBLE IN BROWSE br-work   = NO.   
 tt-work.dt-entrega:VISIBLE IN BROWSE br-work   = NO.   
 tt-work.sit:VISIBLE IN BROWSE br-work          = NO.          
 tt-work.qtde:VISIBLE IN BROWSE br-work         = NO.         
 tt-work.valor:VISIBLE IN BROWSE br-work        = NO. 
 bt-detalhe-nf:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

 CASE p-tipo-selecao:
     WHEN 1 THEN DO:
         ASSIGN c-sit-ped = "1,2,4,5". /* Aberto, Atendido Parcial,Pendente,Suspendo */
         tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = YES.    
         tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-implant:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.dt-entrega:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.sit:VISIBLE IN BROWSE br-work          = YES.          
         tt-work.qtde:VISIBLE IN BROWSE br-work         = YES.         
         tt-work.valor:VISIBLE IN BROWSE br-work        = YES.        
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DA CARTEIRA A FATURAR NO PERIODO: " + 
                                                        SUBSTR(p-dt-faturar,1,2) + "/"+ SUBSTR(p-dt-faturar,3,4) + c-selecao.
         RUN pi-pedidos.
     END.
     WHEN 2 THEN DO:
         tt-work.nr-nota-fis:VISIBLE IN BROWSE br-work  = YES.  
         tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = YES.    
         tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-emis-nota:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-saida:VISIBLE IN BROWSE br-work     = YES.     
         tt-work.qtde:VISIBLE IN BROWSE br-work         = YES.         
         tt-work.valor:VISIBLE IN BROWSE br-work        = YES.        
         bt-detalhe-nf:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DO FATURAMENTO DE: " +
                                                        STRING(p-dt-faturadas-ini, "99/99/9999") + " A " + 
                                                        STRING(p-dt-faturadas-fin, "99/99/9999") + c-selecao.
         RUN pi-nota-fiscal.
         APPLY 'VALUE-CHANGED' to br-work.
     END.
     WHEN 3 THEN DO:
         ASSIGN c-sit-ped = "1,2,3,4,5". /* Aberto, Atendido Parcial,Atendito Total, Pendente,Suspendo */
         tt-work.nr-pedcli:VISIBLE IN BROWSE br-work    = YES.    
         tt-work.nome-abrev:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES. 
         tt-work.dt-implant:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.dt-entrega:VISIBLE IN BROWSE br-work   = YES.   
         tt-work.sit:VISIBLE IN BROWSE br-work          = YES.          
         tt-work.qtde:VISIBLE IN BROWSE br-work         = YES.         
         tt-work.valor:VISIBLE IN BROWSE br-work        = YES.        
         ASSIGN  br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE DAS VENDAS DE: " +
                                                        SUBSTR(p-dt-vendido-ini,1,2) + "/"+ SUBSTR(p-dt-vendido-ini,3,4) + " A " +
                                                        SUBSTR(p-dt-vendido-fin,1,2) + "/"+ SUBSTR(p-dt-vendido-fin,3,4) +
                                                        c-selecao.
         RUN pi-pedidos.
     END.
 END CASE.
 RUN pi-finalizar in h-acomp.
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.

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
 ASSIGN fi-tot-qtd  = 0
        fi-tot-desc = 0
        de-prazo    = 0
        i-qtd-nf    = 0
        fi-tot-vlr  = 0.
 FOR EACH tt-work NO-LOCK.
     ASSIGN fi-tot-qtd  = fi-tot-qtd  + tt-work.qtde  
            fi-tot-desc = fi-tot-desc + tt-work.desc-pratic
            fi-tot-vlr  = fi-tot-vlr  + tt-work.valor
            de-prazo    = de-prazo    + tt-work.prazo-medio
            i-qtd-nf    = i-qtd-nf    + 1.
 END.
 ASSIGN fi-pco-medio = (fi-tot-vlr + fi-tot-desc) / fi-tot-qtd
        fi-prazo-medio = de-prazo / i-qtd-nf.
 DISP fi-tot-qtd 
      fi-tot-vlr
      fi-tot-desc
      fi-pco-medio
      fi-prazo-medio
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

