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
{include/i-prgvrs.i ESSP0190C 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */
{utp/utapi011.i} /* Geraá∆o de Graficos */

/* Parameters Definitions ---                                           */
DEF BUFFER empresa FOR mgadm.empresa.

DEFINE TEMP-TABLE tt-resumo  NO-UNDO 
       FIELD cod-estabel   LIKE movadm.nota-fiscal.cod-estabel
       FIELD base          AS INT
       FIELD cod-rep       LIKE movadm.nota-fiscal.cod-rep
       FIELD vlr-fat       AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD devolucao     AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD liquidez      AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD fat-liq       AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD comissao      AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD comis-liq     AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD desconto      AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD desc-base-ir  AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD i-renda       AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD adiantamento  AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD emprestimo    AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD liquido       AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD vlr-nf        AS DEC FORMAT "->>>,>>>,>>9.99"
       FIELD marcar        AS CHAR.

DEFINE TEMP-TABLE tt-nfs   LIKE movadm.nota-fiscal
       FIELD qt-faturada   AS   DECIMAL
       FIELD comissao      AS   DECIMAL
       FIELD base          AS   INT
       INDEX indice1 IS PRIMARY cod-rep cod-estabel serie nr-nota-fis.

DEFINE TEMP-TABLE tt-calc-repres 
       FIELD cod-rep LIKE repres.cod-rep
       FIELD cod-pai LIKE repres.cod-rep.

DEFINE TEMP-TABLE tt-excessao
       FIELD perc-comis   LIKE repres.comis-direta
       FIELD vlr-fat      AS DECIMAL
       FIELD vlr-desconto AS DECIMAL.

DEFINE TEMP-TABLE tt-digita
       FIELD opcao AS CHAR
       FIELD campo AS CHAR
       FIELD valor AS CHAR.

DEFINE TEMP-TABLE tt-work NO-UNDO 
       FIELD cod-rep       LIKE movadm.nota-fiscal.cod-rep
       FIELD nome-rep      AS CHAR FORMAT "x(20)" 
       FIELD uf            LIKE repres.estado
       FIELD nome-pai      AS CHAR
       FIELD nivel         AS INT
       INDEX indice1 nome-pai nivel.

DEFINE TEMP-TABLE tt-meses NO-UNDO 
       FIELD mes        AS INTEGER
       FIELD c-mes      AS CHAR FORMAT "x(30)" 
       FIELD dt-ini-mes AS DATE
       FIELD dt-fin-mes AS DATE.

DEFINE TEMP-TABLE tt-mensal NO-UNDO 
       FIELD mes           AS INTEGER
       FIELD cod-rep       LIKE tt-work.cod-rep
       FIELD qtde          AS DECIMAL
       FIELD valor         AS DECIMAL.

DEFINE BUFFER b-tt-work   FOR tt-work.
DEFINE BUFFER b-tt-mensal FOR tt-mensal.


/* Local Variable Definitions ---                                       */
DEF NEW GLOBAL SHARED VAR gr-ped-venda   AS ROWID NO-UNDO.
DEF NEW GLOBAL SHARED VAR gr-nota-fiscal AS ROWID NO-UNDO.

DEF VAR c-meses AS CHAR INIT "Janeiro,Fevereiro,Maráo,Abril,Maio,Junho,Julho,Agosto,Setembro,Outubro,Novembro,Dezembro".
DEF VAR i-mes AS INT.
DEF VAR i-pos AS INT.
DEF VAR i-lastkey AS INT.

DEF VAR c-titulo     AS CHAR.
DEF VAR c-sub-tit    AS CHAR.
DEF VAR c-regiao     AS CHAR.
DEF VAR c-lote-refer AS CHAR.

DEF VAR h-acomp      AS HANDLE NO-UNDO.
DEF VAR h-query      AS HANDLE.
DEF VAR opt-sort     AS INT.
DEF VAR de-tot-qtd   AS DEC.
DEF VAR de-tot-vlr   AS DEC.
DEF VAR c-sit-ped    AS CHAR.
DEF VAR c-selecao    AS CHAR.
DEF VAR c-nr-pedcli  AS CHAR.
DEF VAR c-empresa    AS CHAR.
DEF VAR de-prazo     AS DEC.
DEF VAR i-qtd-nf     AS INT.
DEF VAR i-qt-sem     AS INT.

DEF VAR wh-mes AS WIDGET-HANDLE EXTENT 12.


 /* Variaveis da Rotina de Impress∆o */
DEFINE VAR l-ok         AS LOG.
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-ct         AS INT.
DEFINE VAR i-lin        AS INT.
DEFINE VAR i-pag        AS INT.

/* Variaveis para o Excel */
DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF VAR chworksheet AS COM-HANDLE NO-UNDO.
DEF VAR c-lin       AS CHAR FORMAT "x(500)".
DEF VAR arq-saida   AS CHAR FORMAT "x(50)".
DEF VAR i-col       AS INTEGER.
DEF VAR c-col       AS CHAR INIT "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z".

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
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.nome-rep tt-work.uf   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define QUERY-STRING-br-work FOR EACH tt-work NO-LOCK
&Scoped-define OPEN-QUERY-br-work OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for DIALOG-BOX D-Dialog                                  */
&Scoped-define OPEN-BROWSERS-IN-QUERY-D-Dialog ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-buttom br-work bt-grafico bt-excel bt-ok ~
bt-cancela bt-ajuda 

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
     SIZE 5.57 BY 1.25 TOOLTIP "Gerar Planilha".

DEFINE BUTTON bt-grafico 
     IMAGE-UP FILE "image/img-graf1.bmp":U
     LABEL "Impress∆o do Gr†fico de Valores" 
     SIZE 15 BY 1.25 TOOLTIP "Visualizaá∆o/Impress∆o do Grafico VALORES".

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "&OK" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE RECTANGLE rt-buttom
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 123.43 BY 1.42
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
      tt-work.nome-rep    COLUMN-LABEL "Nome"      WIDTH 15
      tt-work.uf          COLUMN-LABEL "UF"        WIDTH  4
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 123 BY 16.5
         FONT 1
         TITLE "" ROW-HEIGHT-CHARS .6.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME D-Dialog
     br-work AT ROW 1 COL 2
     bt-grafico AT ROW 18 COL 1.86 WIDGET-ID 20
     bt-excel AT ROW 18 COL 18 WIDGET-ID 22
     bt-ok AT ROW 19.63 COL 2.57
     bt-cancela AT ROW 19.63 COL 13.57
     bt-ajuda AT ROW 19.63 COL 112.72
     rt-buttom AT ROW 19.38 COL 1.57
     SPACE(0.85) SKIP(0.19)
    WITH VIEW-AS DIALOG-BOX KEEP-TAB-ORDER 
         SIDE-LABELS NO-UNDERLINE THREE-D  SCROLLABLE 
         FONT 1
         TITLE "Faturamento Anual- ESSP0190h"
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
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-work NO-LOCK.
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
ON WINDOW-CLOSE OF FRAME D-Dialog /* Faturamento Anual- ESSP0190h */
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
  FOR EACH tt-meses NO-LOCK.
      IF tt-work.nivel = 1 OR
         tt-work.nivel = 4 THEN DO.
          
         DO i-mes = 1 TO 12.
            IF VALID-HANDLE(wh-mes[i-mes]) THEN
               ASSIGN wh-mes[i-mes]:FGCOLOR = 15. 
         END.
         NEXT.
      END.

      FIND tt-mensal WHERE
           tt-mensal.mes = tt-meses.mes AND
           tt-mensal.cod-rep = tt-work.cod-rep NO-LOCK NO-ERROR.

      IF AVAIL tt-mensal AND
         VALID-HANDLE(wh-mes[tt-mensal.mes]) THEN DO.

         wh-mes[tt-mensal.mes]:SCREEN-VALUE = STRING(tt-mensal.valor).

      END.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work D-Dialog
ON VALUE-CHANGED OF br-work IN FRAME D-Dialog
DO:
   ASSIGN bt-grafico:SENSITIVE = YES.
   IF tt-work.nivel = 1 OR
      tt-work.nivel = 4 THEN 
      ASSIGN bt-grafico:SENSITIVE = NO.
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

    ASSIGN chworksheet:range("A1"):VALUE = "FATURAMENTO ANUAL POR REPRESENTANTE".

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

    ASSIGN chworksheet:range("A3"):VALUE = 'REPRESENTANTE'
           chworksheet:range("B3"):VALUE = 'UF'.

    ASSIGN i-col = 2.
    FOR EACH tt-meses.
        ASSIGN i-col = i-col + 1.
        chworksheet:range(ENTRY(i-col,c-col) + "3"):VALUE = tt-meses.c-mes. 
    END.

     /* Tamanho das Colunas */
     ASSIGN chWorkSheet:Columns("A"):ColumnWidth = 20
            chWorkSheet:Columns("B"):ColumnWidth = 5
            chWorkSheet:Columns("C:Z"):ColumnWidth = 15.

    chWorkSheet:Range("A3:L3"):SELECT().
    ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
           chExcelApp:SELECTION:FONT:SIZE               = 09
           chExcelApp:SELECTION:FONT:Bold               = TRUE 
           chExcelApp:SELECTION:FONT:ColorIndex         = 11.

    ASSIGN chworksheet:range("A:B"):NumberFormat        = "@".
    ASSIGN chworksheet:range("C:Z"):NumberFormat        = "###.###.##0,00".

    ASSIGN i-lin = 4.

    FOR EACH tt-work NO-LOCK.
        ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = tt-work.nome-rep
               chworksheet:range("B" + STRING(i-lin)):VALUE = tt-work.uf.

        ASSIGN i-col = 2.
        FOR EACH tt-meses NO-LOCK.

            // Despresa Representate pai e linha em branco
            IF tt-work.nivel = 1 OR
               tt-work.nivel = 4 THEN NEXT.


            FIND tt-mensal WHERE
                 tt-mensal.mes = tt-meses.mes AND
                 tt-mensal.cod-rep = tt-work.cod-rep NO-LOCK NO-ERROR.

            IF AVAIL tt-mensal THEN DO.
                ASSIGN i-col = i-col + 1.
                chworksheet:range(ENTRY(i-col,c-col) + STRING(i-lin)):VALUE = tt-mensal.valor. 
            END.
        END.
    
        ASSIGN i-lin = i-lin + 1.
    END.


    MESSAGE 'Planilha Gerada com Sucesso...'
        VIEW-AS ALERT-BOX INFO BUTTONS OK.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-grafico
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-grafico D-Dialog
ON CHOOSE OF bt-grafico IN FRAME D-Dialog /* Impress∆o do Gr†fico de Valores */
DO:
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
  RUN pi-grafico.
  ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK D-Dialog 


/* ***************************  Main Block  *************************** */

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
  ENABLE rt-buttom br-work bt-grafico bt-excel bt-ok bt-cancela bt-ajuda 
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

  /* {utp/ut9000.i "ESSP0190C" "2.04.00.000"} */ 

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  /* Busca Nome da Empresa */
  FIND FIRST param-global NO-LOCK NO-ERROR.
  FIND FIRST empresa
       WHERE empresa.ep-codigo = param-global.empresa-prin NO-LOCK NO-ERROR. 
  ASSIGN c-empresa = (IF AVAIL empresa THEN empresa.razao-social ELSE "").

  RUN pi-processa.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-abre-excel D-Dialog 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-gera-excel D-Dialog 
PROCEDURE pi-gera-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  /*
  RUN pi-excel-cabec (INPUT 1,
                      INPUT "Item").
  ASSIGN i-Lin    = 4.
  
  FOR EACH b-tt-work NO-LOCK.
      
      ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.cod-rep
             chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.nome-rep.

      /*
      ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.lote
             chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.und
             chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.qtd
             chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.vlr
             chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.
      IF i-tp-selecao = 2 THEN
         ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.qtd-devol
                chworksheet:range("I" + STRING(i-lin)):VALUE = b-tt-work.vlr-devol
                chworksheet:range("J" + STRING(i-lin)):VALUE = b-tt-work.rentabilidade
                chworksheet:range("K" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.
      ELSE
          ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.


      /*  Configura Tamanho da Fonte */
      ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
             chworksheet:Rows(c-lin):FONT:SIZE = 9.

      IF b-tt-work.uf <> "ZZ" THEN DO:
         ACCUMULATE b-tt-work.qtd (TOTAL).
         ACCUMULATE b-tt-work.vlr (TOTAL).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL).
         ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.cod-rep).
         ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.cod-rep).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL BY b-tt-work.cod-rep).
      END.
      ASSIGN i-Lin = i-Lin + 1.
      IF LAST-OF(b-tt-work.cod-rep) THEN DO:
         ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.cod-rep  b-tt-work.qtd)
                chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.cod-rep b-tt-work.vlr)
                chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.cod-rep b-tt-work.vlr-devol).
         /* Colorir a Linha / Negrito */
         chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
         chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:Bold           = TRUE.
         ASSIGN i-lin = i-lin + 1.
      END.
      */
  END.
  */
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
 DEF VAR i-point   AS INT INITIAL 1.
 DEF VAR i-numsets AS INT.
 DEF VAR de-work   AS DEC.
 DEF VAR h-utapi011 AS HANDLE NO-UNDO.

 EMPTY TEMP-TABLE tt-atributos.
 EMPTY TEMP-TABLE tt-sets.
 EMPTY TEMP-TABLE tt-points-2.
 EMPTY TEMP-TABLE tt-dados.
 EMPTY TEMP-TABLE tt-erros.

 /* Configuraá∆o Geral do Grafico */
 CREATE tt-atributos.
 ASSIGN tt-atributos.cod-versao-integracao = 3
        tt-atributos.graphtype             = 3
        tt-atributos.graphtitle            = "Faturamento Anual do Representante " + tt-work.nome-rep
        tt-atributos.lefttitle             = "Valores em Real (R$)"
        tt-atributos.lefttitlestyle        = 1
        tt-atributos.bottomtitle           = "Per°odo"
        tt-atributos.numgraph              = 1.
                                             
 /* Configuraá∆o das Variantes do Grafico */
 ASSIGN i-numsets = 1.
 CREATE tt-sets.
 ASSIGN tt-sets.NumSet     = i-numsets 
        tt-sets.NumGraph   = 1
        tt-sets.ColorSet   = 1
        tt-sets.legendText = tt-work.nome-rep.

 ASSIGN de-work = 0.
 FOR EACH b-tt-mensal WHERE
          b-tt-mensal.cod-rep = tt-work.cod-rep NO-LOCK
          BREAK BY b-tt-mensal.mes.
     IF FIRST-OF(b-tt-mensal.mes) THEN DO.
        FIND tt-meses WHERE
             tt-meses.mes = b-tt-mensal.mes NO-LOCK NO-ERROR.

         /* Valores do EIXO X (mes) */
         CREATE tt-points-2.
         ASSIGN tt-points-2.NumPoint  = i-point
                tt-points-2.NumGraph  = 1
                tt-points-2.labeltext = SUBSTRING(tt-meses.c-mes,1,3) + "/" +
                                        ENTRY(2,tt-meses.c-mes,"/").
     END.

     ASSIGN de-work = de-work + b-tt-mensal.valor.

     IF LAST-OF(b-tt-mensal.mes) THEN DO.
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
     "DATA: "                                  AT  58
     STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  64
     "HORA: "                                  AT  85
     STRING(TIME,"hh:mm:ss")                   AT  91
     "PAG:"                                    AT 125
     i-pag FORMAT ">>"                         AT 130
     SKIP(1).

     PUT "ANALISE DO FATURAMENTO DE: " + STRING(TODAY, "99/99/9999") + " A " +  STRING(TODAY, "99/99/9999") +
         c-selecao FORMAT "x(100)" AT 25 SKIP(1).
     PUT "N.Fiscal Ped Cli Ped. Repres. Cliente      Representante  Dt.Implant Dt.Entrega   Qtde Vendida  Valor Vendido   Desc. Pratic P.Medio" AT 1.
     PUT "-------- ------- ------------ ------------ -------------- ---------- ---------- -------------- -------------- -------------- -------" AT 1.

 
 ASSIGN i-pag = i-pag + 1.
                                                                            
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
   DEF VAR da-dt-ini AS DATE.
   DEF VAR c-periodo AS CHAR.
   DEF VAR i-mes AS INTEGER.
   DEF VAR c-dia AS CHAR.
   DEF VAR c-hierarquia AS CHAR FORMAT "x(20)".
   DEF VAR i-cod-pai LIKE repres.cod-rep.

   ASSIGN i-mes = 0.

   ASSIGN da-dt-ini = ADD-INTERVAL(TODAY,-11,"months").
   REPEAT WHILE da-dt-ini <= TODAY.
       ASSIGN i-mes = MONTH(da-dt-ini).
       FIND tt-meses WHERE
            tt-meses.mes = i-mes NO-ERROR.
       IF NOT AVAIL tt-meses THEN DO.
          ASSIGN c-periodo = STRING(MONTH(da-dt-ini),"99") + STRING(YEAR(da-dt-ini),"9999").

          CREATE tt-meses.
          ASSIGN tt-meses.mes = i-mes
                 tt-meses.c-mes = UPPER(ENTRY(i-mes,c-meses) + "/" + STRING(YEAR(da-dt-ini),"9999")).

          IF i-mes <> MONTH(TODAY) THEN DO.
             RUN esapi/ret-udm.p (INPUT c-periodo, OUTPUT c-dia).
             ASSIGN tt-meses.dt-ini-mes = DATE("01"  + c-periodo)
                    tt-meses.dt-fin-mes = DATE(c-dia + c-periodo).
          END.
          ELSE
              ASSIGN tt-meses.dt-ini-mes = ADD-INTERVAL(TODAY, - DAY(TODAY) + 1,"days")
                     tt-meses.dt-fin-mes = TODAY.
       END.
       ASSIGN da-dt-ini = ADD-INTERVAL(da-dt-ini,1,"months").
   END.

   DO i-ct = 1 TO EXTENT(wh-mes).
      IF VALID-HANDLE(wh-mes[i-ct]) THEN
         DELETE WIDGET wh-mes[i-ct].
   END.

  FOR EACH tt-meses.
      IF NOT VALID-HANDLE(wh-mes[tt-meses.mes]) THEN
         wh-mes[tt-meses.mes] = br-work:ADD-CALC-COLUMN("dec",
                                                         ">>>,>>>,>>>,>>9.99",
                                                         "",
                                                         tt-meses.c-mes) IN FRAME {&FRAME-NAME}.
  END.

  RUN esapi/connect-ima-med.p.


  FOR EACH tt-meses.
      EMPTY TEMP-TABLE tt-resumo.

      RUN esapi/escm002a.p (INPUT-OUTPUT TABLE tt-resumo,
                            INPUT-OUTPUT TABLE tt-calc-repres,
                            INPUT-OUTPUT TABLE tt-nfs,
                            INPUT-OUTPUT TABLE tt-digita,
                            INPUT "",
                            INPUT "ZZZZ",
                            INPUT tt-meses.dt-ini-mes,
                            INPUT tt-meses.dt-fin-mes,
                            INPUT "",
                            INPUT "ZZZZZZZZZZZZ",
                            INPUT "",
                            INPUT "ZZZZZZZZZZZZZZZZ", 
                            INPUT 0,
                            INPUT 99999,
                            INPUT "",
                            INPUT "ZZZZZZZZZZZZZZZZ").

      FOR EACH tt-resumo BREAK BY tt-resumo.cod-rep.
          ACCUMULATE tt-resumo.vlr-fat (TOTAL BY tt-resumo.cod-rep).

          IF FIRST-OF(tt-resumo.cod-rep) THEN DO.
             FIND cm-hierarquia WHERE
                  cm-hierarquia.cod-depend = tt-resumo.cod-rep NO-LOCK NO-ERROR.

             IF AVAIL cm-hierarquia THEN DO.
                FIND cm-ext-repres WHERE
                     cm-ext-repres.cod-rep = cm-hierarquia.cod-rep NO-LOCK NO-ERROR.

                FIND repres WHERE
                     repres.cod-rep = cm-ext-repres.cod-rep NO-LOCK NO-ERROR.

                IF cm-ext-repres.classe = 1 THEN
                   ASSIGN c-hierarquia = 'Gerencia GERAL ' + UPPER(repres.estado).
                ELSE IF cm-ext-repres.classe = 2 THEN
                   ASSIGN c-hierarquia = 'Gerencia LOJA'.

                ASSIGN i-cod-pai = repres.cod-rep.
             END.
             ELSE 
                ASSIGN c-hierarquia = 'INDEFINIDO'
                       i-cod-pai = 1.

             FIND tt-work WHERE
                  tt-work.nome-rep = c-hierarquia NO-LOCK NO-ERROR.
             IF NOT AVAIL tt-work THEN DO.
                CREATE tt-work.
                ASSIGN tt-work.nome-rep = c-hierarquia
                       tt-work.nome-pai = c-hierarquia
                       tt-work.nivel = 1.
             END.

             FIND repres WHERE
                  repres.cod-rep = tt-resumo.cod-rep NO-LOCK NO-ERROR.

             FIND tt-work WHERE
                  tt-work.cod-rep = tt-resumo.cod-rep NO-LOCK NO-ERROR.
             IF NOT AVAIL tt-work THEN DO:
                CREATE tt-work.
                ASSIGN tt-work.cod-rep = tt-resumo.cod-rep
                       tt-work.nome-rep = "   " + repres.nome-abrev
                       tt-work.uf = repres.estado
                       tt-work.nome-pai = c-hierarquia
                       tt-work.nivel = 2.
             END.

             FIND tt-mensal WHERE
                  tt-mensal.cod-rep = tt-resumo.cod-rep AND
                  tt-mensal.mes = tt-meses.mes NO-ERROR.
             IF NOT AVAIL tt-mensal THEN DO.
                CREATE tt-mensal.
                ASSIGN tt-mensal.cod-rep = tt-resumo.cod-rep
                       tt-mensal.mes = tt-meses.mes.
             END.
             ASSIGN tt-mensal.valor = tt-mensal.valor + ACCUM TOTAL BY tt-resumo.cod-rep tt-resumo.vlr-fat.


             FIND tt-work WHERE
                  tt-work.cod-rep = i-cod-pai  AND
                  tt-work.nome-rep = 'TOTAL' 
                  NO-LOCK NO-ERROR.
             IF NOT AVAIL tt-work THEN DO:
                CREATE tt-work.
                ASSIGN tt-work.cod-rep = i-cod-pai
                       tt-work.nome-rep = 'TOTAL'
                       tt-work.nome-pai = c-hierarquia
                       tt-work.nivel = 3.

                CREATE tt-work.
                ASSIGN tt-work.cod-rep = i-cod-pai
                       tt-work.nome-pai = c-hierarquia
                       tt-work.nivel = 4.
             END.

             FIND tt-mensal WHERE
                  tt-mensal.cod-rep = i-cod-pai  AND
                  tt-mensal.mes = tt-meses.mes NO-ERROR.
             IF NOT AVAIL tt-mensal THEN DO.
                CREATE tt-mensal.
                ASSIGN tt-mensal.cod-rep = i-cod-pai
                       tt-mensal.mes = tt-meses.mes.
             END.
             ASSIGN tt-mensal.valor = tt-mensal.valor + ACCUM TOTAL BY tt-resumo.cod-rep tt-resumo.vlr-fat.
             
          END.
      END.
  END.

  DISCONNECT dbaux.
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
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = NO.
 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
 {utp/ut-liter.i Calculando_Valores *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

 ASSIGN br-work:TITLE IN FRAME {&FRAME-NAME} = "ANALISE ANUAL DO FATURAMENTO POR REPRESENTANTE".

 FOR EACH cm-ext-repres WHERE
          cm-ext-repres.classe <= 2 NO-LOCK.

     FIND FIRST representante WHERE 
                representante.cdn_repr = cm-ext-repres.cod-rep AND
                representante.ind_sit_repres = 'Ativo' NO-LOCK NO-ERROR.

     IF NOT AVAIL representante THEN NEXT.

     FOR EACH cm-hierarquia WHERE
              cm-hierarquia.cod-rep = representante.cdn_rep NO-LOCK.

         CREATE tt-calc-repres.
         ASSIGN tt-calc-repres.cod-pai = cm-hierarquia.cod-depend
                tt-calc-repres.cod-rep = cm-hierarquia.cod-depend.
     END.
 END.

 RUN pi-nota-fiscal.

 RUN pi-finalizar in h-acomp.
 ASSIGN FRAME {&FRAME-NAME}:VISIBLE = YES.



 {&OPEN-QUERY-br-work}
 APPLY 'VALUE-CHANGED' TO br-work.

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

