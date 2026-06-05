&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-livre 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i ESFT098 9.99.99.999}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */

DEFINE VARIABLE cCaminhoXML      AS CHARACTER FORMAT 'X(200)'  NO-UNDO.
DEFINE VARIABLE lSemParam        AS LOGICAL     NO-UNDO.
DEFINE VARIABLE lXmlExiste       AS LOGICAL     NO-UNDO.
DEFINE VARIABLE vlIcms           AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlIcmsOu         AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlIcmsNt         AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlIPI            AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlIPIOu          AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlIPINt          AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlDespesas       AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlPIs            AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlCofins         AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlPIsNota        AS DECIMAL     NO-UNDO.
DEFINE VARIABLE vlCofinsNota     AS DECIMAL     NO-UNDO.
DEFINE VARIABLE iPosicaoPIS      AS INTEGER     NO-UNDO.
DEFINE VARIABLE iPosicaoCOFINS   AS INTEGER     NO-UNDO.
DEFINE VARIABLE iQtPosicaoPIS    AS INTEGER     NO-UNDO.
DEFINE VARIABLE iQtPosicaoCOFINS AS INTEGER     NO-UNDO.
DEFINE VARIABLE dPercPIS         AS DECIMAL     NO-UNDO.
DEFINE VARIABLE dPercCOFINS      AS DECIMAL     NO-UNDO.
DEFINE VARIABLE dBaseCalc        AS DECIMAL     NO-UNDO.
DEFINE VARIABLE dTotBaseCalc     AS DECIMAL     NO-UNDO.
DEFINE VARIABLE iSinal           AS INTEGER     NO-UNDO.
DEFINE VARIABLE cArquivoXml      AS CHARACTER FORMAT 'x(200)'   NO-UNDO.
DEFINE VARIABLE cNotaRef         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE daDataRef        AS DATE  NO-UNDO.
DEFINE VARIABLE cChaveRef        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cSerieRef        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iEmitenteRef     AS INTEGER     NO-UNDO.
DEFINE VARIABLE cDescEmitRef     AS CHARACTER   NO-UNDO FORMAT 'x(30)'.
DEFINE VARIABLE cNatOPeracao     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE vlBaseCalcIcms   AS DECIMAL     NO-UNDO.
DEFINE TEMP-TABLE tt
      FIELD cod-estabel                 LIKE nota-fiscal.cod-estabel
      FIELD nr-nota-fis                 LIKE nota-fiscal.nr-nota-fis
      FIELD serie                       LIKE nota-fiscal.serie
      FIELD especie                     AS CHAR
      FIELD cod-emitente                LIKE nota-fiscal.cod-emitente
      FIELD nome-abrev                  LIKE emitente.nome-abrev
      FIELD dt-emis-nota                LIKE nota-fiscal.dt-emis-nota
      FIELD nat-operacao                LIKE nota-fiscal.nat-operacao
      FIELD cod-cfop                    LIKE natur-oper.cod-cfop
      FIELD nr-pedcli                   LIKE nota-fiscal.nr-pedcli
      FIELD cgc                         LIKE emitente.cgc
      FIELD cidade                      LIKE emitente.cidade
      FIELD estado                      LIKE emitente.estado
      FIELD log-nf-cancel               AS CHAR
      FIELD des-idi-sit-nf-eletro        AS CHAR
      FIELD cod-chave-aces-nf-eletro     LIKE nota-fiscal.cod-chave-aces-nf-eletro
      FIELD des-idi-forma-emis-nf-eletro AS CHAR
      FIELD vl-tot-nota                 LIKE nota-fiscal.vl-tot-nota
      FIELD vl-mercadoria               LIKE nota-fiscal.vl-mercad
      FIELD vl-seguro                   LIKE nota-fiscal.vl-seguro
      FIELD vl-embalagem                LIKE nota-fiscal.vl-embalagem
      FIELD vl-frete                    LIKE nota-fiscal.vl-frete
      FIELD vl-icms                     AS DECIMAL
      FIELD vl-icms-ou                  AS DECIMAL
      FIELD vl-icms-nt                  AS DECIMAL
      FIELD vl-ipi                      AS DECIMAL
      FIELD vl-ipi-ou                   AS DECIMAL
      FIELD vl-ipi-nt                   AS DECIMAL
      /*FIELD vl-despesas                 AS DECIMAL*/
      FIELD vl-base-pis-cofins          AS DECIMAL
      /*FIELD perc-pis                    AS DECIMAL*/
      FIELD vl-pis                      AS DECIMAL
      /*FIELD perc-cofins                 AS DECIMAL*/
      FIELD vl-cofins                   AS DECIMAL
      FIELD log-xml-existe              AS CHAR
      FIELD log-gera-dp                 AS CHAR
      FIELD notaref                     AS CHAR
      FIELD serieRef                    AS CHAR
      FIELD emitenteRef                 AS INT
      FIELD descEmitRef                 AS CHAR
      FIELD dataref                     AS CHAR FORMAT 'x(12)'
      FIELD chaveREF                    AS CHAR 
      FIELD vlBaseICMS                  LIKE it-nota-fisc.vl-bicms-it.

DEFINE TEMP-TABLE ttEstab
        FIELD codEstabel AS CHAR.

{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS rt-button RECT-1 RECT-3 RECT-2 fi_estab ~
fiarquivo fi_serie_ini fi_serie_fim fi_nf_ini fi_nf_fim fi_nat_operacao_ini ~
fi_nat_operacao_fim fi_cliente_ini fi_cliente_fim dt_emissao_ini ~
dt_emissao_fim tg_canceladas tg_devolucoes tg_dp_sim tg_dp_nao tg_entradas ~
tg_saidas tg_xml_encontrado tg_xml_nao_encontrado bt_executar 
&Scoped-Define DISPLAYED-OBJECTS fi_estab fiarquivo fi_serie_ini ~
fi_serie_fim fi_nf_ini fi_nf_fim fi_nat_operacao_ini fi_nat_operacao_fim ~
fi_cliente_ini fi_cliente_fim dt_emissao_ini dt_emissao_fim tg_canceladas ~
tg_devolucoes tg_dp_sim tg_dp_nao tg_entradas tg_saidas tg_xml_encontrado ~
tg_xml_nao_encontrado 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-livre AS WIDGET-HANDLE NO-UNDO.

/* Menu Definitions                                                     */
DEFINE SUB-MENU mi-programa 
       MENU-ITEM mi-consultas   LABEL "Co&nsultas"     ACCELERATOR "CTRL-L"
       MENU-ITEM mi-imprimir    LABEL "&Relat¢rios"    ACCELERATOR "CTRL-P"
       RULE
       MENU-ITEM mi-sair        LABEL "&Sair"          ACCELERATOR "CTRL-X".

DEFINE SUB-MENU m_Ajuda 
       MENU-ITEM mi-conteudo    LABEL "&Conteudo"     
       MENU-ITEM mi-sobre       LABEL "&Sobre..."     .

DEFINE MENU m-livre MENUBAR
       SUB-MENU  mi-programa    LABEL "&Nome-do-Programa"
       SUB-MENU  m_Ajuda        LABEL "&Ajuda"        .


/* Definitions of handles for SmartObjects                              */
DEFINE VARIABLE h_p-exihel AS HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt_executar 
     LABEL "Executar" 
     SIZE 15 BY 1.13.

DEFINE VARIABLE dt_emissao_fim AS DATE FORMAT "99/99/9999":U INITIAL 12/31/9999 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE dt_emissao_ini AS DATE FORMAT "99/99/9999":U 
     LABEL "Dt.Emissao De" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fiarquivo AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 53.57 BY 1 NO-UNDO.

DEFINE VARIABLE fi_cliente_fim AS INTEGER FORMAT ">,>>>,>>9":U INITIAL 999999 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_cliente_ini AS INTEGER FORMAT ">,>>>,>>9":U INITIAL 0 
     LABEL "Cliente De" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_estab AS CHARACTER FORMAT "X(3)":U 
     LABEL "Estab" 
     VIEW-AS FILL-IN 
     SIZE 7.86 BY 1 NO-UNDO.

DEFINE VARIABLE fi_nat_operacao_fim AS CHARACTER FORMAT "X(12)":U INITIAL "zzzzzzzzzz" 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_nat_operacao_ini AS CHARACTER FORMAT "X(12)":U 
     LABEL "Natureza de Opera‡Æo De" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_nf_fim AS CHARACTER FORMAT "X(12)":U INITIAL "9999999" 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_nf_ini AS CHARACTER FORMAT "X(12)":U 
     LABEL "NF De" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_serie_fim AS CHARACTER FORMAT "X(5)":U INITIAL "zzz" 
     LABEL "At‚" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE VARIABLE fi_serie_ini AS CHARACTER FORMAT "X(5)":U 
     LABEL "S‚rie" 
     VIEW-AS FILL-IN 
     SIZE 26 BY 1 NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 32 BY 1.5.

DEFINE RECTANGLE RECT-2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 62 BY 1.5.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 32 BY 1.5.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 89.72 BY 1.46
     BGCOLOR 7 .

DEFINE VARIABLE tg_canceladas AS LOGICAL INITIAL yes 
     LABEL "Canceladas" 
     VIEW-AS TOGGLE-BOX
     SIZE 13 BY .83 NO-UNDO.

DEFINE VARIABLE tg_devolucoes AS LOGICAL INITIAL yes 
     LABEL "Devolu‡äes" 
     VIEW-AS TOGGLE-BOX
     SIZE 13 BY .83 NO-UNDO.

DEFINE VARIABLE tg_dp_nao AS LOGICAL INITIAL yes 
     LABEL "NÆo" 
     VIEW-AS TOGGLE-BOX
     SIZE 7.57 BY .83 NO-UNDO.

DEFINE VARIABLE tg_dp_sim AS LOGICAL INITIAL yes 
     LABEL "Sim" 
     VIEW-AS TOGGLE-BOX
     SIZE 13 BY .83 NO-UNDO.

DEFINE VARIABLE tg_entradas AS LOGICAL INITIAL yes 
     LABEL "Entradas" 
     VIEW-AS TOGGLE-BOX
     SIZE 13 BY .83 NO-UNDO.

DEFINE VARIABLE tg_saidas AS LOGICAL INITIAL yes 
     LABEL "Sa¡das" 
     VIEW-AS TOGGLE-BOX
     SIZE 7.57 BY .83 NO-UNDO.

DEFINE VARIABLE tg_xml_encontrado AS LOGICAL INITIAL yes 
     LABEL "Encontrado" 
     VIEW-AS TOGGLE-BOX
     SIZE 13 BY .83 NO-UNDO.

DEFINE VARIABLE tg_xml_nao_encontrado AS LOGICAL INITIAL yes 
     LABEL "NÆo Encontrado" 
     VIEW-AS TOGGLE-BOX
     SIZE 14.57 BY .83 NO-UNDO.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     fi_estab AT ROW 3.75 COL 18.14 COLON-ALIGNED WIDGET-ID 2
     fiarquivo AT ROW 3.75 COL 26.43 COLON-ALIGNED NO-LABEL WIDGET-ID 60
     fi_serie_ini AT ROW 5.04 COL 18.14 COLON-ALIGNED WIDGET-ID 6
     fi_serie_fim AT ROW 5.04 COL 54.14 COLON-ALIGNED WIDGET-ID 8
     fi_nf_ini AT ROW 6.38 COL 18.14 COLON-ALIGNED WIDGET-ID 10
     fi_nf_fim AT ROW 6.38 COL 54.14 COLON-ALIGNED WIDGET-ID 12
     fi_nat_operacao_ini AT ROW 7.67 COL 18.29 COLON-ALIGNED WIDGET-ID 14
     fi_nat_operacao_fim AT ROW 7.67 COL 54.14 COLON-ALIGNED WIDGET-ID 16
     fi_cliente_ini AT ROW 9.04 COL 18.29 COLON-ALIGNED WIDGET-ID 18
     fi_cliente_fim AT ROW 9.04 COL 54.29 COLON-ALIGNED WIDGET-ID 20
     dt_emissao_ini AT ROW 10.42 COL 18 COLON-ALIGNED WIDGET-ID 22
     dt_emissao_fim AT ROW 10.42 COL 54 COLON-ALIGNED WIDGET-ID 24
     tg_canceladas AT ROW 11.58 COL 20 WIDGET-ID 26
     tg_devolucoes AT ROW 11.67 COL 35 WIDGET-ID 58
     tg_dp_sim AT ROW 13.21 COL 62.43 WIDGET-ID 54
     tg_dp_nao AT ROW 13.21 COL 76.43 WIDGET-ID 56
     tg_entradas AT ROW 13.25 COL 29.43 WIDGET-ID 32
     tg_saidas AT ROW 13.25 COL 43.43 WIDGET-ID 34
     tg_xml_encontrado AT ROW 15.29 COL 29.43 WIDGET-ID 44
     tg_xml_nao_encontrado AT ROW 15.29 COL 43.43 WIDGET-ID 46
     bt_executar AT ROW 16.5 COL 20 WIDGET-ID 36
     "Gera Duplicatas?" VIEW-AS TEXT
          SIZE 23 BY .54 AT ROW 12.58 COL 54 WIDGET-ID 52
          FONT 0
     "XML" VIEW-AS TEXT
          SIZE 3 BY .54 AT ROW 14.67 COL 21 WIDGET-ID 42
          FONT 0
     "Tipos de Nota a serem considerados" VIEW-AS TEXT
          SIZE 27 BY .54 AT ROW 12.63 COL 21 WIDGET-ID 30
          FONT 0
     rt-button AT ROW 1 COL 1
     RECT-1 AT ROW 12.79 COL 20 WIDGET-ID 28
     RECT-3 AT ROW 12.75 COL 53 WIDGET-ID 50
     RECT-2 AT ROW 14.83 COL 20 WIDGET-ID 40
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 89.72 BY 17.04
         FONT 1 WIDGET-ID 100.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-livre
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-livre ASSIGN
         HIDDEN             = YES
         TITLE              = "Listagem de Faturamento"
         HEIGHT             = 17.04
         WIDTH              = 89.72
         MAX-HEIGHT         = 27.5
         MAX-WIDTH          = 195.14
         VIRTUAL-HEIGHT     = 27.5
         VIRTUAL-WIDTH      = 195.14
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.

ASSIGN {&WINDOW-NAME}:MENUBAR    = MENU m-livre:HANDLE.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-livre 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-livre.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-livre
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-cad
   FRAME-NAME L-To-R                                                    */
ASSIGN 
       fiarquivo:READ-ONLY IN FRAME f-cad        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Listagem de Faturamento */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Listagem de Faturamento */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt_executar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt_executar w-livre
ON CHOOSE OF bt_executar IN FRAME f-cad /* Executar */
DO:
  ASSIGN bt_executar:LABEL = 'Executando...'
         bt_executar:SENSITIVE = NO.
  IF INPUT FRAME {&FRAME-NAME} tg_dp_sim  = NO AND INPUT FRAME {&FRAME-NAME} tg_dp_nao     = NO THEN DO:
     MESSAGE ' necess rio selecionar ao menos uma situa‡Æo de gera‡Æo de duplicatas.'
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     ASSIGN bt_executar:LABEL = 'Executar'
         bt_executar:SENSITIVE = YES.
     RETURN NO-APPLY.
  END.
  IF INPUT FRAME {&FRAME-NAME} tg_entradas  = NO AND INPUT FRAME {&FRAME-NAME} tg_saidas     = NO THEN DO:
     MESSAGE ' necess rio selecionar ao menos um tipo de nota.'
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     ASSIGN bt_executar:LABEL = 'Executar'
         bt_executar:SENSITIVE = YES.
     RETURN NO-APPLY.
  END.
  IF INPUT FRAME {&FRAME-NAME} tg_xml_encontrado  = NO AND INPUT FRAME {&FRAME-NAME} tg_xml_nao_encontrado     = NO THEN DO:
     MESSAGE ' necess rio selecionar ao menos um situa‡Æo para o XML.'
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     ASSIGN bt_executar:LABEL = 'Executar'
         bt_executar:SENSITIVE = YES.
     RETURN NO-APPLY.
  END.
  FIND FIRST im-param
      WHERE im-param.cod-param = 'pasta_xml_' +  fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} NO-LOCK NO-ERROR.
  IF AVAIL im-param THEN
     ASSIGN cCaminhoXML = im-param.val-param
            lSemParam   = NO.
  ELSE DO:
      ASSIGN lSemParam = YES.
      MESSAGE 'O parametro ' 'pasta_xml_' fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} ' nÆo foi encontrado ' SKIP
              'Por este motivo a verifica‡Æo do xml nÆo ser  executada' SKIP
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
  END.
  EMPTY TEMP-TABLE tt.
  OUTPUT TO c:\temp\logesft998.txt.
  
 
  FOR EACH nota-fiscal NO-LOCK
      WHERE nota-fiscal.cod-estabel     = fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.serie           >= fi_serie_ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.serie           <= fi_serie_fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.nr-nota-fis     >= fi_nf_ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.nr-nota-fis     <= fi_nf_fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.nat-operacao    >= fi_nat_operacao_ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.nat-operacao    <= fi_nat_operacao_fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
      AND   nota-fiscal.cod-emitente    >= INPUT FRAME {&frame-name} fi_cliente_ini
      AND   nota-fiscal.cod-emitente    <= INPUT FRAME  {&frame-name} fi_cliente_fim
      AND   nota-fiscal.dt-emis-nota    >= INPUT FRAME  {&FRAME-NAME} dt_emissao_ini
      AND   nota-fiscal.dt-emis-nota    <= INPUT FRAME {&FRAME-NAME}  dt_emissao_fim.
      
      RUN esapi/retornarNFDadosRefer.p(nota-fiscal.cod-estabel,
                                      nota-fiscal.nr-nota-fis,
                                      nota-fiscal.serie,
                                      nota-fiscal.nat-operacao,
                                      nota-fiscal.cod-emitente,
                                      OUTPUT  cNotaRef,
                                      OUTPUT daDataRef,
                                      OUTPUT cChaveRef,
                                      OUTPUT cSerieRef,
                                      OUTPUT iEmitenteRef,
                                      OUTPUT cDescEmitRef   ).

      FIND FIRST doc-fiscal 
          WHERE doc-fiscal.cod-estabel  = nota-fiscal.cod-estabel
          AND   doc-fiscal.serie        = nota-fiscal.serie
          AND   doc-fiscal.nr-doc-fis   = nota-fiscal.nr-nota-fis
          AND   doc-fiscal.nat-operacao = nota-fiscal.nat-operacao
          NO-LOCK NO-ERROR.

      FIND FIRST fat-duplic 
          WHERE fat-duplic.cod-estabel = nota-fiscal.cod-estabel
          AND   fat-duplic.serie       = nota-fiscal.serie
          AND   fat-duplic.nr-fatura   = nota-fiscal.nr-fatura NO-LOCK NO-ERROR.
      IF INPUT FRAME {&FRAME-NAME} tg_dp_sim = NO  AND AVAIL fat-duplic  THEN NEXT.
      IF INPUT FRAME {&FRAME-NAME} tg_dp_nao = NO  AND NOT AVAIL fat-duplic  THEN NEXT.

      PUT "nota fiscal:" nota-fiscal.nr-nota-fis nota-fiscal.dt-emis-nota SKIP .
      ASSIGN vlIcms   = 0
             vlIcmsOu = 0
             vlIcmsNt = 0
             vlIPi    = 0
             vlIPiOu  = 0
             vlIPiNt  = 0
             vlPis    = 0
             vlCofins = 0
             dTotBaseCalc  = 0
            vlBaseCalcIcms = 0 .


      IF nota-fiscal.esp-docto       = 21 OR nota-fiscal.esp-docto = 20 THEN DO:
          ASSIGN iPosicaoPIS         = 76
                  iQtPosicaoPIS      = 5
                  iPosicaoCOFINS     = 81
                  iQtPosicaoCOFINS   = 5
                  iSinal             = -1.


      END.
      ELSE DO:
          ASSIGN iPosicaoPIS            = 76
                    iQtPosicaoPIS       = 6
                    iPosicaoCOFINS      = 82
                    iQtPosicaoCOFINS    = 6
                    iSinal              = 1.
      END.
         
      IF INPUT FRAME {&FRAME-NAME} tg_canceladas = NO  AND nota-fiscal.dt-cancel <> ?  THEN NEXT.
      IF INPUT FRAME {&FRAME-NAME} tg_entradas   = NO  AND nota-fiscal.esp-docto = 21  THEN NEXT.
      IF INPUT FRAME {&FRAME-NAME} tg_saidas     = NO  AND nota-fiscal.esp-docto = 22  THEN NEXT.
      IF INPUT FRAME {&FRAME-NAME} tg_devolucoes = NO  AND nota-fiscal.esp-docto = 20  THEN NEXT.

      FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
          ASSIGN vlIcms         = vlIcms         + it-nota-fisc.vl-icms-it
                 vlIcmsOu       = vlIcmsOu       + it-nota-fisc.vl-icmsou-it
                 vlIcmsNt       = vlIcmsNt       + it-nota-fisc.vl-icmsnt-it
                 vlIpi          = vlIpi          + it-nota-fisc.vl-ipi-it
                 vlIpiNt        = vlIpiNt        + it-nota-fisc.vl-ipint-it
                 vlIpiOu        = vlIpiOu        + it-nota-fisc.vl-ipiou-it
                 vlBaseCalcIcms = vlBaseCalcIcms + it-nota-fisc.vl-bicms-it.   
                
          FIND FIRST it-doc-fisc OF doc-fiscal 
              WHERE it-doc-fisc.it-codigo = it-nota-fisc.it-codigo
              AND   it-doc-fisc.nr-seq-doc = it-nota-fisc.nr-seq-fat
              NO-LOCK NO-ERROR.
          
          FIND FIRST docum-est 
               WHERE docum-est.serie-docto  = nota-fiscal.serie
               AND   docum-est.nro-docto    = nota-fiscal.nr-nota-fis
               AND   docum-est.cod-emitente = nota-fiscal.cod-emitente
               AND   docum-est.nat-operacao = nota-fiscal.nat-operacao
               NO-LOCK NO-ERROR.

          FIND FIRST item-doc-est OF docum-est 
               WHERE item-doc-est.it-codigo = it-nota-fisc.it-codigo 
               AND   item-doc-est.cod-refer = it-nota-fisc.cod-refer
               NO-LOCK NO-ERROR.
           
          IF nota-fiscal.esp-docto     = 21 OR nota-fiscal.esp-docto = 20 THEN DO:
             ASSIGN dBaseCalc          = IF AVAIL item-doc-est THEN item-doc-est.val-base-calc-cofins ELSE 0 .
          END.
          ELSE DO:
             ASSIGN dBaseCalc           = it-nota-fisc.vl-tot-item .
          END.
          IF AVAIL it-doc-fisc AND nota-fiscal.esp-docto     <> 21 OR nota-fiscal.esp-docto <> 20 THEN DO:
             ASSIGN vlPis           = vlPis         + it-doc-fisc.val-pis
                    vlCofins        = vlCofins      + it-doc-fisc.val-cofins
                    dTotBaseCalc    = dTotBaseCalc  + it-doc-fisc.val-base-calc-cofins .
          END.
          ELSE DO:
              ASSIGN dPercPis       = dec(substr(it-nota-fisc.char-2,iPosicaoPIS,iQtPosicaoPIS))
                     dPercCofins    = dec(substr(it-nota-fisc.char-2,iPosicaoCOFINS,iQtPosicaoCOFINS))
                     vlPisNota      = dBaseCalc * dPercPis    / 100
                     vlCofinsNota   = dBaseCalc * dPercCofins / 100
                     vlPis           = vlPis         +  vlPisNota
                     vlCofins        = vlCofins      + vlCofinsNota
                     dTotBaseCalc    = dTotBaseCalc  + dBaseCalc .
          END.
      END.

      IF lSemParam = NO THEN DO:
         ASSIGN cArquivoXml = cCaminhoXML + "\" + STRING(i-ep-codigo-usuario) + "00" + nota-fiscal.serie +
                               nota-fiscal.nr-nota-fis + ".xml".
         /*MESSAGE cArquivoXml
             VIEW-AS ALERT-BOX INFO BUTTONS OK.*/
         FILE-INFO:FILE-NAME = cArquivoXml.
         ASSIGN lXmlExiste = FILE-INFO:FULL-PATHNAME <> ?.
      END.
/*       MESSAGE iSinal SKIP                    */
/*                nota-fiscal.esp-docto SKIP    */
/*           VIEW-AS ALERT-BOX INFO BUTTONS OK. */

      FIND emitente OF nota-fiscal NO-LOCK NO-ERROR.
      FIND natur-oper OF nota-fiscal NO-LOCK NO-ERROR.
      CREATE tt.
      ASSIGN  tt.vl-base-pis-cofins             =   dTotBaseCalc * iSinal
              tt.cod-estabel                    =   nota-fiscal.cod-estabel             
              tt.nr-nota-fis                    =   nota-fiscal.nr-nota-fis
              tt.serie                          =   nota-fiscal.serie
              tt.especie                        =   {ininc/i03in218.i 4 nota-fiscal.esp-docto} 
              tt.cod-emitente                   =   nota-fiscal.cod-emitente
              tt.nome-abrev                     =   IF AVAIL emitente THEN emitente.nome-abrev ELSE ''
              tt.dt-emis-nota                   =   nota-fiscal.dt-emis-nota
              tt.nat-operacao                   =   nota-fiscal.nat-operacao
              tt.cod-cfop                       =   IF AVAIL natur-oper THEN  natur-oper.cod-cfop ELSE ''
              tt.nr-pedcli                      =   nota-fiscal.nr-pedcli
              tt.cgc                            =   IF AVAIL emitente THEN emitente.cgc ELSE ''
              tt.cgc                            =  "'" + tt.cgc
              tt.cidade                         =   IF AVAIL emitente THEN emitente.cidade ELSE ''
              tt.estado                         =   IF AVAIL emitente THEN emitente.estado ELSE ''
              tt.log-nf-cancel                  =  IF nota-fiscal.dt-cancel <> ?  THEN "Sim" ELSE "NÆo"
              tt.des-idi-sit-nf-eletro          =  IF nota-fiscal.idi-sit-nf-eletro <> 0 THEN {diinc/i01di135.i 4 nota-fiscal.idi-sit-nf-eletro} ELSE "NÆo Informado"
              tt.cod-chave-aces-nf-eletro       =   "'" + nota-fiscal.cod-chave-aces-nf-eletro 
              tt.des-idi-forma-emis-nf-eletro   =   IF nota-fiscal.idi-forma-emis-nf-eletro <> 0 THEN {diinc/i02di135.i 4 nota-fiscal.idi-forma-emis-nf-eletro} 
                                                    ELSE "NÆo Informado"
              tt.log-xml-existe                 =  IF  lXMLExiste THEN "Sim" ELSE "NÆo"
              tt.vl-tot-nota                    = nota-fiscal.vl-tot-nota       * iSinal             
              tt.vl-mercadoria                  = nota-fiscal.vl-mercad         * iSinal 
              tt.vl-seguro                      = nota-fiscal.vl-seguro         * iSinal 
              tt.vl-embalagem                   = nota-fiscal.vl-embalagem      * iSinal 
              tt.vl-frete                       = nota-fiscal.vl-frete          * iSinal 
              tt.vl-icms                        = vlIcms   * iSinal 
              tt.vlBaseIcms                     = vlBaseCalcIcms * iSinal
              tt.vl-icms-ou                     = vlIcmsOu * iSinal 
              tt.vl-icms-nt                     = vlIcmsNt * iSinal 
              tt.vl-ipi                         = vlIPi    * iSinal 
              tt.vl-ipi-ou                      = vlIPiOu  * iSinal 
              tt.vl-ipi-nt                      = vlIpiNt  * iSinal 
              /*tt.vl-despesas                    = vlDespesas*/
              /*tt.perc-Pis                       = dPercPis*/
              /*tt.perc-Cofins                    = dPercCofins*/
              tt.vl-pis                         = vlPis    * iSinal 
              tt.vl-cofins                      = vlCofins * iSinal 
              tt.log-gera-dp                    = IF AVAIL fat-duplic THEN "Sim" ELSE "NÆo"
              tt.emitenteRef                    = iEmitenteRef
              tt.descEmitRef                    = cDescEmitRef
              tt.notaref                        = cNotaref
              tt.serieRef                       = cSerieRef
              tt.dataRef                        = IF daDataref <> ? THEN string(daDataref,'99/99/9999') ELSE ''
              tt.chaveref                       = "'" + cChaveRef. 
     
  END.
 

  IF INPUT FRAME {&FRAME-NAME} tg_devolucoes = YES THEN DO:

      FOR EACH docum-est NO-LOCK
          WHERE docum-est.cod-estabel       = fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.serie-docto       >= fi_serie_ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.serie-docto       <= fi_serie_fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.nro-docto         >= fi_nf_ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.nro-docto         <= fi_nf_fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.nat-operacao      >= fi_nat_operacao_ini:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.nat-operacao      <= fi_nat_operacao_fim:SCREEN-VALUE IN FRAME {&FRAME-NAME}
          AND   docum-est.cod-emitente      >= INPUT FRAME {&frame-name} fi_cliente_ini
          AND   docum-est.cod-emitente      <= INPUT FRAME  {&frame-name} fi_cliente_fim
          AND   docum-est.dt-trans          >= INPUT FRAME  {&FRAME-NAME} dt_emissao_ini
          AND   docum-est.dt-trans          <= INPUT FRAME {&FRAME-NAME}  dt_emissao_fim .
         
          FIND FIRST emitente OF docum-est NO-LOCK NO-ERROR.
            
          RUN esapi/retornarNFDadosRefer.p(docum-est.cod-estabel,
                                      docum-est.nro-docto,
                                      docum-est.serie-docto,
                                      docum-est.nat-operacao,
                                      docum-est.cod-emitente,
                                      OUTPUT  cNotaRef,
                                      OUTPUT daDataRef,
                                      OUTPUT cChaveRef,
                                      OUTPUT cSerieRef,
                                      OUTPUT iEmitenteRef,
                                      OUTPUT cDescEmitRef   ).

          FIND FIRST natur-oper
              WHERE natur-oper.nat-operacao = docum-est.nat-operacao
              AND   natur-oper.especie-doc= 'NFD' NO-LOCK NO-ERROR.
          IF NOT AVAIL natur-oper THEN NEXT.
          ASSIGN dTotBAseCAlc = 0
                 vlIcms       = 0
                 vlICmsOu     = 0
                 vlICmsNT     = 0
                 vlPis        = 0
                 vlCOfins     = 0
                 vlBaseCalcIcms = 0.
    
    
          FOR EACH item-doc-est OF docum-est NO-LOCK:
              ASSIGN dTotBaseCAlc = dTotBAseCAlc + item-doc-est.val-base-calc-cofins
                     vlICms       = vlICMS + item-doc-est.valor-icm[1]
                     vlIcmsOu     = vlICMSOu + item-doc-est.icm-outras[1]
                     vlIcmsNt     = vlICMSNT + item-doc-est.icm-ntrib[1] 
                     vlPIS        = vlPIS    + item-doc-est.valor-pis
                     vlCOFINS     = vlCOFINS + item-doc-est.val-cofins
                     vlBaseCalcIcms = vlBaseCalcIcms  + item-doc-est.base-icm[1].
          END.
          FIND FIRST natur-oper OF docum-est NO-LOCK NO-ERROR.
    
          FIND FIRST tt
              WHERE tt.cod-estabel  = docum-est.cod-estabel
              AND   tt.serie        = docum-est.serie
              AND   tt.cod-emitente = docum-est.cod-emitente
              AND   tt.nat-operacao  = docum-est.nat-operacao
              AND   tt.nr-nota-fis  = docum-est.nro-docto
              NO-LOCK NO-ERROR.
          IF NOT AVAIL tt THEN DO:
             CREATE tt.
             ASSIGN  tt.vl-base-pis-cofins          =   dTotBaseCalc * -1
                  tt.cod-estabel                    =   docum-est.cod-estabel             
                  tt.nr-nota-fis                    =   docum-est.nro-docto
                  tt.serie                          =   docum-est.serie-docto
                  tt.especie                        =   'NFD'
                  tt.cod-emitente                   =   docum-est.cod-emitente
                  tt.nome-abrev                     =   IF AVAIL emitente THEN emitente.nome-abrev ELSE ''
                  tt.dt-emis-nota                   =   docum-est.dt-trans
                  tt.nat-operacao                   =   docum-est.nat-operacao
                  tt.cod-cfop                       =   IF AVAIL natur-oper THEN  natur-oper.cod-cfop ELSE ''
                  tt.nr-pedcli                      =   ''
                  tt.cgc                            =   IF AVAIL emitente THEN emitente.cgc ELSE ''
                  tt.cgc                            =  "'" + tt.cgc
                  tt.cidade                         =   IF AVAIL emitente THEN emitente.cidade ELSE ''
                  tt.estado                         =   IF AVAIL emitente THEN emitente.estado ELSE ''
                  tt.des-idi-sit-nf-eletro          =  ''
                  tt.cod-chave-aces-nf-eletro       =   "'" + docum-est.cod-chave-aces-nf-eletro
                  tt.vl-tot-nota                    = docum-est.tot-valor      * -1        
                  tt.vl-mercadoria                  = docum-est.valor-mercad   * -1
                  tt.vl-seguro                      = docum-est.valor-seguro   * -1
                  tt.vl-embalagem                   = docum-est.valor-seguro   * -1
                  tt.vl-frete                       = docum-est.valor-frete    * -1
                  tt.vl-icms                        = vlIcms                   * -1
                  tt.vlBaseIcms                     = vlBaseCalcIcms           * -1
                  tt.vl-icms-ou                     = vlIcmsOu                 * -1
                  tt.vl-icms-nt                     = vlIcmsNt                 * -1
                  tt.vl-pis                         = vlPis                    * -1
                  tt.vl-cofins                      = vlCofins                 * -1
                  tt.emitenteRef                    = iEmitenteRef
                  tt.descEmitRef                    = cDescEmitRef  
                  tt.notaref                        = cNotaref
                  tt.serieRef                       = cSerieRef    
                  tt.dataRef                        = IF daDataref <> ? THEN string(daDataref,'99/99/9999') ELSE ''
                  tt.chaveref                       = "'" + cChaveRef.  
    
          END.
      END.
  END.
  
  OUTPUT CLOSE.

  OUTPUT TO value('c:\temp\esft998.txt').
  FOR EACH tt:
      EXPORT DELIMITER ";" tt.
  END.
  OUTPUT CLOSE.
  OS-COMMAND SILENT VALUE('start t:\especificos\excel\nfs_saida.xltx').
  ASSIGN bt_executar:LABEL = 'Executar'
         bt_executar:SENSITIVE = YES.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fi_estab
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fi_estab w-livre
ON LEAVE OF fi_estab IN FRAME f-cad /* Estab */
DO:
  FIND FIRST im-param NO-LOCK
      WHERE im-param.cod-param = 'pasta_xml_' +  fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} NO-ERROR.
  IF AVAIL im-param THEN DO:
     ASSIGN fiArquivo:SCREEN-VALUE = im-param.val-param + "( parametro pasta_xml_" + fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME} + ")".
  END.
  ELSE DO:
     ASSIGN fiArquivo:SCREEN-VALUE = 'NÆo foi encontrado o parametro: pasta_xml_' + fi_estab:SCREEN-VALUE IN FRAME {&FRAME-NAME}.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-consultas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-consultas w-livre
ON CHOOSE OF MENU-ITEM mi-consultas /* Consultas */
DO:
  RUN pi-consulta IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-conteudo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-conteudo w-livre
ON CHOOSE OF MENU-ITEM mi-conteudo /* Conteudo */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  RUN pi-ajuda IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-imprimir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-imprimir w-livre
ON CHOOSE OF MENU-ITEM mi-imprimir /* Relat¢rios */
DO:
  RUN pi-imprimir IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-programa
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-programa w-livre
ON MENU-DROP OF MENU mi-programa /* Nome-do-Programa */
DO:
  run pi-disable-menu.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sair
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sair w-livre
ON CHOOSE OF MENU-ITEM mi-sair /* Sair */
DO:
  RUN pi-sair IN h_p-exihel.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME mi-sobre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL mi-sobre w-livre
ON CHOOSE OF MENU-ITEM mi-sobre /* Sobre... */
DO:
  {include/sobre.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-livre 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-livre  _ADM-CREATE-OBJECTS
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
             INPUT  'panel/p-exihel.w':U ,
             INPUT  FRAME f-cad:HANDLE ,
             INPUT  'Edge-Pixels = 2,
                     SmartPanelType = NAV-ICON,
                     Right-to-Left = First-On-Left':U ,
             OUTPUT h_p-exihel ).
       RUN set-position IN h_p-exihel ( 1.17 , 74.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             fi_estab:HANDLE IN FRAME f-cad , 'BEFORE':U ).
    END. /* Page 0 */

  END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-livre  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-livre  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
  THEN DELETE WIDGET w-livre.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-livre  _DEFAULT-ENABLE
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
  DISPLAY fi_estab fiarquivo fi_serie_ini fi_serie_fim fi_nf_ini fi_nf_fim 
          fi_nat_operacao_ini fi_nat_operacao_fim fi_cliente_ini fi_cliente_fim 
          dt_emissao_ini dt_emissao_fim tg_canceladas tg_devolucoes tg_dp_sim 
          tg_dp_nao tg_entradas tg_saidas tg_xml_encontrado 
          tg_xml_nao_encontrado 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE rt-button RECT-1 RECT-3 RECT-2 fi_estab fiarquivo fi_serie_ini 
         fi_serie_fim fi_nf_ini fi_nf_fim fi_nat_operacao_ini 
         fi_nat_operacao_fim fi_cliente_ini fi_cliente_fim dt_emissao_ini 
         dt_emissao_fim tg_canceladas tg_devolucoes tg_dp_sim tg_dp_nao 
         tg_entradas tg_saidas tg_xml_encontrado tg_xml_nao_encontrado 
         bt_executar 
      WITH FRAME f-cad IN WINDOW w-livre.
  {&OPEN-BROWSERS-IN-QUERY-f-cad}
  VIEW w-livre.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-livre 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-livre 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-livre 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  run pi-before-initialize.

  {include/win-size.i}

  {utp/ut9000.i "ESFT998" "9.99.99.999"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-livre  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this w-livre, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-livre 
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

