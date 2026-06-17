&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
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
{include/i-prgvrs.i ESSP0190 2.04.00.000}

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

DEF BUFFER empresa FOR mgadm.empresa.
DEF BUFFER unid-feder FOR mgadm.unid-feder.

{utp/utapi011.i} /* Geraá∆o de Graficos */


DEF NEW GLOBAL SHARED VAR essp0190-aberto AS LOG NO-UNDO.

/* ***************************  Definitions  ************************** */
/* IMA */
/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
DEF TEMP-TABLE tt-work      NO-UNDO
    FIELD visualiza         AS LOG
    FIELD seq-item          AS INT
    FIELD seq-repres        AS INT
    FIELD seq-grupo         AS INT
    FIELD seq-cliente       AS INT
    FIELD seq-regiao        AS INT
    FIELD seq-uf            AS INT
    FIELD seq-nat-oper      AS INT
    FIELD seq-cond-pg       AS INT
    FIELD it-codigo         LIKE ped-item.it-codigo
    FIELD desc-item         LIKE ITEM.desc-item
    FIELD classif           LIKE fam-comerc.descricao
    FIELD acabamento        AS   CHAR FORMAT "x(30)"
    FIELD no-ab-reppri      LIKE ped-venda.no-ab-reppri
    FIELD cod-rep           LIKE repres.cod-rep
    FIELD matriz            LIKE it-nota-fisc.aliquota-icm
    FIELD nome-abrev        LIKE ped-venda.nome-abrev
    FIELD cod-emit          LIKE emitente.cod-emit
    FIELD regiao            AS CHAR FORMAT "x(20)"
    FIELD nat-operacao      LIKE natur-oper.nat-operacao
    FIELD aliq-icms         LIKE natur-oper.aliquota-icm
    FIELD vl-icms           LIKE it-nota-fisc.vl-icms-it
    FIELD desc-pratic       AS DEC
    FIELD cond-pagto        AS CHAR
    FIELD uf                AS CHAR
    FIELD lote              AS CHAR
    FIELD Und               AS CHAR
    FIELD qtd               AS DEC
    FIELD qtd-devol         AS DEC
    FIELD vlr               AS DEC
    FIELD vlr-devol         AS DEC
    FIELD vlr-custo         AS DEC
    FIELD preco-medio       AS DEC
    FIELD prazo-medio       AS DEC
    FIELD rentabilidade     AS DEC
    FIELD perc-sobr-total   AS DEC
    INDEX indice1 it-codigo    und lote 
    INDEX indice2 no-ab-reppri und lote 
    INDEX indice3 matriz       und lote 
    INDEX indice4 nome-abrev   und lote 
    INDEX indice5 regiao       und lote uf
    INDEX indice6 nat-operacao und lote 
    INDEX indice7 cond-pagto   und lote.

DEF TEMP-TABLE tt-pedidos NO-UNDO
    FIELD nr-pedcli   LIKE ped-venda.nr-pedcli
    FIELD nr-nota-fis LIKE nota-fiscal.nr-nota-fis
    FIELD cod-estabel LIKE nota-fiscal.cod-estabel
    FIELD serie       LIKE nota-fiscal.serie
    FIELD exportacao  AS LOG
    FIELD qt-faturada LIKE it-nota-fisc.qt-faturada
    FIELD vl-tot-item LIKE it-nota-fisc.vl-tot-item
    FIELD desc-pratic AS DEC.

DEF TEMP-TABLE tt-prazo NO-UNDO
    FIELD nr-nota-fis LIKE nota-fiscal.nr-nota-fis
    FIELD tipo        AS CHAR 
    FIELD uf          AS CHAR
    FIELD lote        AS CHAR
    FIELD und         AS CHAR
    FIELD cod-tipo    AS CHAR FORMAT "x(1)"
    FIELD praz-medio  AS DEC 
    INDEX indice1 nr-nota-fis tipo lote und.

DEF TEMP-TABLE tt-devolucao NO-UNDO
    FIELD serie-docto  LIKE docum-est.serie-docto
    FIELD nro-docto    LIKE docum-est.nro-docto
    FIELD cod-emitente LIKE docum-est.cod-emitente
    FIELD nat-operacao LIKE docum-est.nat-operacao
    FIELD qtd-devol    AS DEC 
    FIELD vlr-devol    AS DEC.

DEF TEMP-TABLE tt-resumo
    FIELD nome-rep  LIKE repres.nome
    FIELD uf        LIKE repres.estado
    FIELD qt-pe     AS DECIMAL
    FIELD vl-pe     AS DECIMAL
    FIELD qt-outlet AS DECIMAL
    FIELD vl-outlet AS DECIMAL.

DEF TEMP-TABLE tt-res-cli
    FIELD cod-emit   LIKE emitente.cod-emit
    FIELD nome-emit  LIKE emitente.nome-emit
    FIELD nome-rep   LIKE repres.nome
    FIELD quantidade AS DECIMAL
    FIELD valor      AS DECIMAL
    FIELD qtd-devol  AS DECIMAL
    FIELD vlr-devol  AS DECIMAL
    FIELD imprime    AS LOGICAL INIT NO.

DEF TEMP-TABLE tt-digita
    FIELD opcao  AS CHAR
    FIELD campo AS CHAR
    FIELD valor AS CHAR.

DEF BUFFER b-tt-res-cli FOR tt-res-cli.

&GLOBAL-DEFINE SORTBY-PHRASE BY IF opt-sort = 1 ~
                                THEN tt-work.it-codigo + tt-work.uf + tt-work.lote + tt-work.und ~
                                ELSE IF opt-sort = 2 ~
                                     THEN tt-work.no-ab-reppri + tt-work.uf + tt-work.lote + tt-work.und ~
                                    ELSE IF opt-sort = 3 ~
                                         THEN STRING(tt-work.matriz) + tt-work.uf + tt-work.lote + tt-work.und ~
                                        ELSE IF opt-sort = 4 ~
                                             THEN tt-work.nome-abrev + tt-work.uf + tt-work.lote + tt-work.und ~
                                            ELSE IF opt-sort = 5 ~
                                                 THEN tt-work.regiao + tt-work.uf + tt-work.lote + tt-work.und ~
                                                ELSE IF opt-sort = 6 ~
                                                     THEN tt-work.nat-operacao + tt-work.uf + tt-work.lote ~
                                                     ELSE tt-work.cond-pagto + tt-work.uf + tt-work.lote 


&GLOBAL-DEFINE SORTBY-IMPRESSAO BY IF opt-sort = 1 ~
                                   THEN b-tt-work.it-codigo + b-tt-work.uf + b-tt-work.lote + b-tt-work.und ~
                                   ELSE IF opt-sort = 2 ~
                                        THEN b-tt-work.no-ab-reppri + b-tt-work.uf + b-tt-work.lote + b-tt-work.und ~
                                       ELSE IF opt-sort = 3 ~
                                            THEN STRING(b-tt-work.matriz) + b-tt-work.uf + b-tt-work.lote + b-tt-work.und ~
                                           ELSE IF opt-sort = 4 ~
                                                THEN b-tt-work.nome-abrev + b-tt-work.uf + b-tt-work.lote + b-tt-work.und ~
                                               ELSE IF opt-sort = 5 ~
                                                    THEN b-tt-work.regiao + b-tt-work.uf + b-tt-work.lote + b-tt-work.und ~
                                                   ELSE IF opt-sort = 6 ~
                                                        THEN b-tt-work.nat-operacao + b-tt-work.uf + b-tt-work.lote ~
                                                          ELSE b-tt-work.cond-pagto + b-tt-work.uf + b-tt-work.lote 

DEF BUFFER b-tt-work FOR tt-work.                                                         
DEF VAR h-acomp   AS HANDLE.
DEF VAR h-query   AS HANDLE. 
DEF VAR c-empresa AS CHAR.

/* Global Variable Definitions ---                                       */
DEF VAR i-cod-vencto      LIKE fat-duplic.cod-vencto.
DEF VAR c-sit-ped         AS CHAR.
DEF VAR da-dt-implant-ini AS DATE.
DEF VAR da-dt-implant-fin AS DATE.
DEF VAR c-dia             AS CHAR.
DEF VAR c-lotes           AS CHAR.
DEF VAR c-lote-refer      AS CHAR.
DEF VAR c-uf              AS CHAR.
DEF VAR c-regiao          AS CHAR FORMAT "x(20)".
DEF VAR c-cond-pagto      AS CHAR.
DEF VAR c-regiao-uf       AS CHAR.
DEF VAR c-codigo          AS CHAR.
DEF VAR c-titulo          AS CHAR.
DEF VAR c-selecao         AS CHAR.
DEF VAR opt-sort          AS INT.
DEF VAR de-qtd-metro      AS DEC.
DEF VAR de-vlr-icms       AS DEC.
DEF VAR de-vlr-metro      AS DEC.
DEF VAR de-vlr-devol      AS DEC.
DEF VAR de-vlr-custo      AS DEC.
DEF VAR de-qtd-kg         AS DEC.
DEF VAR de-vlr-kg         AS DEC.
DEF VAR de-qtd-und        AS DEC.
DEF VAR de-vlr-und        AS DEC.
DEF VAR i-prz             AS INT.
DEF VAR de-qtd            AS DEC.
DEF VAR de-vlr            AS DEC.
DEF VAR de-desc           AS DEC.
DEF VAR de-prazo          AS DEC.
DEF VAR i-qtd-nf          AS INT.
DEF VAR l-func            AS LOG.
DEF VAR l-cfiscal         AS LOG.
DEF VAR l-soma-prazo      AS LOG.
DEF VAR i-cod-rep         AS INT.
DEF VAR c-nome-rep        AS CHAR.
DEF VAR de-desc-und       AS DEC.
DEF VAR de-desc-metro     AS DEC.
DEF VAR de-desc-kg        AS DEC.
DEF VAR i-tot-etq         AS INTEGER.       
DEF VAR i-prazo-medio     LIKE cond-pagto.qtd-dias-prazo-medio.
DEF VAR de-tot-prazo      LIKE cond-ped.nr-dias-venc.
DEF VAR c-tb-preco-pad    LIKE preco-item.nr-tabpre.
DEF VAR de-vl-pre-tab     LIKE it-nota-fisc.vl-preuni.
DEF VAR de-ind-finan      AS DEC.
DEF VAR i-opcao           AS INT.
DEF VAR hBoOpcaoLista     AS HANDLE.
DEF VAR c-acabamento      AS CHAR.


 /* Variaveis da Rotina de Impress∆o */
DEFINE VAR i-saida      AS INT.
DEFINE VAR c-saida      AS CHAR.
DEFINE VAR i-num-copias AS INT.
DEFINE VAR i-Lin        AS INT.
DEFINE VAR i-pag        AS INT.
DEFINE VAR i-ct         AS INT.

/* Variaveis para o Excel */
DEF VAR chExcelApp  AS COM-HANDLE NO-UNDO.
DEF VAR chWorkbook  AS COM-HANDLE NO-UNDO.
DEF VAR chworksheet AS COM-HANDLE NO-UNDO.
DEF VAR i-qtd-plan   AS INTEGER.
DEF VAR c-lin       AS CHAR FORMAT "x(500)".
DEF VAR arq-saida   AS CHAR FORMAT "x(50)".


/* Variavies de ParÉmetros */
DEFINE VAR i-tp-selecao        AS INT INIT 2.
DEFINE VAR c-dt-faturar        AS CHAR.                                  
DEFINE VAR c-dt-faturadas-ini  AS DATE.
DEFINE VAR c-dt-faturadas-fin  AS DATE.
DEFINE VAR c-dt-vendido-ini    AS CHAR.
DEFINE VAR c-dt-vendido-fin    AS CHAR.
DEFINE VAR c-cod-estabel-ini   LIKE estabelec.cod-estabel     INIT "1".
DEFINE VAR c-cod-estabel-fin   LIKE estabelec.cod-estabel     INIT "1".
DEFINE VAR c-nr-pedcli-ini     LIKE ped-venda.nr-pedcli       INIT "".
DEFINE VAR c-nr-pedcli-fin     LIKE ped-venda.nr-pedcli       INIT "ZZZZZZZZ".
DEFINE VAR c-it-codigo-ini     LIKE ped-item.it-codigo        INIT "".
DEFINE VAR c-it-codigo-fin     LIKE ped-item.it-codigo        INIT "ZZZZZZZZZZZZZZZZ".
DEFINE VAR c-cod-refer-ini     LIKE ped-item.cod-refer.                              
DEFINE VAR c-cod-refer-fin     LIKE ped-item.cod-refer        INIT "ZZZZZZZZZZ".
DEFINE VAR c-nome-abrev-ini    LIKE ped-venda.nome-abrev. 
DEFINE VAR c-nome-abrev-fin    LIKE ped-venda.nome-abrev      INIT "ZZZZZZZZZZZZ".
DEFINE VAR c-no-ab-reppri-ini  LIKE ped-venda.no-ab-reppri. 
DEFINE VAR c-no-ab-reppri-fin  LIKE ped-venda.no-ab-reppri    INIT 'ZZZZZZZZZZZZ'.
DEFINE VAR c-fm-cod-com-ini    LIKE ITEM.fm-cod-com.
DEFINE VAR c-fm-cod-com-fin    LIKE ITEM.fm-cod-com           INIT "ZZZZZ".
DEFINE VAR i-ge-codigo-ini     LIKE grup-estoque.ge-codigo    INIT 0.
DEFINE VAR i-ge-codigo-fin     LIKE grup-estoque.ge-codigo    INIT 99.
DEFINE VAR c-matriz-ini        LIKE emitente.nome-matriz.
DEFINE VAR c-matriz-fin        LIKE emitente.nome-matriz      INIT "ZZZZZZZZZZZZ".
DEFINE VAR c-tp-pedido         AS CHAR INITIAL "Todos".
DEFINE VAR i-tb_preco_id       AS INTEGER INIT 9.
DEFINE VAR l-lote-todos        AS LOG INIT YES.
DEFINE VAR l-lote-rp           AS LOG INIT YES.
DEFINE VAR l-lote-rd           AS LOG INIT YES.
DEFINE VAR i-outlet            AS INTEGER INIT 3.
DEFINE VAR c-tipo-acabamento   AS CHAR INIT "A".
DEFINE VAR c-tipo-mercado      AS CHAR INIT "T".
DEFINE VAR l-faturamento       AS LOG  INIT YES.
DEFINE VAR l-entre-estab       AS LOG  INIT NO.
DEFINE VAR l-outros-fat        AS LOG  INIT NO.
DEFINE VAR l-pilotagem         AS LOG  INIT YES.
DEFINE VAR c-cod-depos         AS CHAR INIT "TODOS".
DEFINE VAR l-ok                AS LOG.

DEFINE VAR c-corte-comerc-ini  AS CHAR.
DEFINE VAR c-corte-comerc-fin  AS CHAR INIT "ZZ".
DEFINE VAR de-tot-qt-pe AS DECIMAL.
DEFINE VAR de-tot-vl-pe AS DECIMAL.
DEFINE VAR de-tot-qt-outlet AS DECIMAL.
DEFINE VAR de-tot-vl-outlet AS DECIMAL.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-livre
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-cad
&Scoped-define BROWSE-NAME br-work

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-work

/* Definitions for BROWSE br-work                                       */
&Scoped-define FIELDS-IN-QUERY-br-work tt-work.it-codigo tt-work.desc-item tt-work.classif tt-work.acabamento tt-work.no-ab-reppri tt-work.cod-rep tt-work.matriz tt-work.nome-abrev tt-work.cod-emit tt-work.regiao tt-work.uf tt-work.nat-operacao tt-work.aliq-icms tt-work.cond-pagto tt-work.lote tt-work.und tt-work.qtd tt-work.vlr tt-work.preco-medio tt-work.prazo-medio tt-work.qtd-devol tt-work.vlr-devol tt-work.vl-icms tt-work.perc-sobr-total tt-work.rentabilidade   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-work   
&Scoped-define SELF-NAME br-work
&Scoped-define QUERY-STRING-br-work FOR EACH tt-work  WHERE                                  tt-work.visualiza = YES NO-LOCK                                  ~{&SORTBY-PHRASE}
&Scoped-define OPEN-QUERY-br-work OPEN QUERY {&SELF-NAME} FOR EACH tt-work  WHERE                                  tt-work.visualiza = YES NO-LOCK                                  ~{&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br-work tt-work
&Scoped-define FIRST-TABLE-IN-QUERY-br-work tt-work


/* Definitions for FRAME f-cad                                          */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-cad ~
    ~{&OPEN-QUERY-br-work}

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-54 RECT-55 rt-button rs-sit-credito ~
br-work bt-param bt-vapara bt-vendas bt-devolucao bt-vendas-tot bt-totais ~
bt-Grafico-qtd bt-Grafico-vlr bt-repres bt-exporta bt-excel bt-imprime ~
fi-tx-dev fi-lbl-prazo fi-tx-tot-pecas fi-tx-icms 
&Scoped-Define DISPLAYED-OBJECTS rs-sit-credito fi-total-qtd-m ~
fi-total-qtd-kg fi-total-qtd-und fi-total-vlr fi-total-vlr-m ~
fi-total-vlr-kg fi-total-vlr-und fi-total-devol fi-pmedio-m fi-pmedio-kg ~
fi-pmedio-und fi-prazo-medio fi-total-icms fi-tx-dev fi-lbl-prazo ~
fi-tx-tot-pecas fi-tx-icms 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */
&Scoped-define List-4 bt-vendas bt-vendas-tot 
&Scoped-define List-6 bt-vendas-tot bt-totais bt-Grafico-qtd bt-Grafico-vlr ~
bt-repres bt-exporta bt-excel 

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


/* ************************  Function Prototypes ********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD fn-cupom-fiscal w-livre 
FUNCTION fn-cupom-fiscal RETURNS LOGICAL
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD fn-func w-livre 
FUNCTION fn-func RETURNS LOGICAL
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION-FORWARD fn-tipo-grafico w-livre 
FUNCTION fn-tipo-grafico RETURNS CHARACTER
  ( /* parameter-definitions */ )  FORWARD.

/* _UIB-CODE-BLOCK-END */
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
DEFINE BUTTON bt-devolucao 
     IMAGE-UP FILE "image/im-desc.bmp":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Detalhar Devoluá‰es"
     BGCOLOR 8 .

DEFINE BUTTON bt-excel 
     IMAGE-UP FILE "image/excel.bmp":U
     LABEL "Button 2" 
     SIZE 5 BY 1.21 TOOLTIP "Gerar Planilha".

DEFINE BUTTON bt-exporta 
     IMAGE-UP FILE "image/terca.bmp":U
     LABEL "bt excel" 
     SIZE 5 BY 1.21 TOOLTIP "Exporta Massa de Dados para EXCEL".

DEFINE BUTTON bt-Grafico-qtd 
     IMAGE-UP FILE "image/im-grf.bmp":U
     LABEL "Grafico" 
     SIZE 5 BY 1.21 TOOLTIP "Visualizar o Grafico de Metros".

DEFINE BUTTON bt-Grafico-vlr 
     IMAGE-UP FILE "image/im-grfcp.bmp":U
     LABEL "Grafico" 
     SIZE 5 BY 1.21 TOOLTIP "Visualizar o Grafico de Valores".

DEFINE BUTTON bt-imprime 
     IMAGE-UP FILE "image/im-pri.bmp":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Imprimir Informaá‰es do Browse.".

DEFINE BUTTON bt-param 
     IMAGE-UP FILE "image/im-fil.bmp":U
     LABEL "Button 3" 
     SIZE 5 BY 1.21 TOOLTIP "ParÉmetros".

DEFINE BUTTON bt-repres 
     IMAGE-UP FILE "image/im-forne.bmp":U
     LABEL "bt excel" 
     SIZE 5 BY 1.21 TOOLTIP "Consultas Diversas por Representante".

DEFINE BUTTON bt-totais AUTO-GO 
     IMAGE-UP FILE "image/im-total.bmp":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Totalizador por (Item, Representante, Grupos, Clientes, Regiao, etc)"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-vapara AUTO-GO 
     IMAGE-UP FILE "image/im-vapra.bmp":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Posicionar no Item/Representante/Grupos/Cliente/Regi∆o/Natureza Operaá∆o/Vencto"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-vendas AUTO-GO 
     IMAGE-UP FILE "image/mab-eqpto":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Detalhar Vendas/Faturamento do (Item ... Vencimento) Posicionado"
     BGCOLOR 8 FONT 10.

DEFINE BUTTON bt-vendas-tot AUTO-GO 
     IMAGE-UP FILE "image/im-vendas-tot.gif":U
     LABEL "" 
     SIZE 5 BY 1.21 TOOLTIP "Detalhar Vendas de Todos os Pedidos"
     BGCOLOR 8 FONT 10.

DEFINE VARIABLE fi-lbl-prazo AS CHARACTER FORMAT "X(256)":U INITIAL "Prz MÇdio Geral:" 
      VIEW-AS TEXT 
     SIZE 14 BY .54
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-pmedio-kg AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12.29 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-pmedio-m AS DECIMAL FORMAT "->>>,>>>,>>9.99":R17 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14.43 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-pmedio-und AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12.72 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-prazo-medio AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88
     BGCOLOR 15 FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-qt-pecas AS INTEGER FORMAT ">,>>>,>>9" INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 9 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-devol AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-icms AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88
     BGCOLOR 15 FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-qtd-kg AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13.86 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-qtd-m AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14.43 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-qtd-und AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12.72 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr AS DECIMAL FORMAT "->>>,>>>,>>9.99":R18 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 15 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr-kg AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 13.86 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr-m AS DECIMAL FORMAT "->>>,>>>,>>9.99":R17 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 14.43 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-total-vlr-und AS DECIMAL FORMAT "->>>,>>>,>>9.99":R16 INITIAL 0 
     VIEW-AS FILL-IN 
     SIZE 12.72 BY .88
     FGCOLOR 1 FONT 6 NO-UNDO.

DEFINE VARIABLE fi-tx-dev AS CHARACTER FORMAT "X(256)":U INITIAL "Vlr Devoluá‰es:" 
      VIEW-AS TEXT 
     SIZE 13 BY .54
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-tx-icms AS CHARACTER FORMAT "X(256)":U INITIAL "Total ICMS:" 
      VIEW-AS TEXT 
     SIZE 10 BY .54
     FONT 6 NO-UNDO.

DEFINE VARIABLE fi-tx-tot-pecas AS CHARACTER FORMAT "X(256)":U INITIAL "Total de Peáas" 
      VIEW-AS TEXT 
     SIZE 12.29 BY .54
     FONT 6 NO-UNDO.

DEFINE VARIABLE rs-sit-credito AS INTEGER 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Item", 1,
"Representante", 2,
"Clientes", 4,
"Regi∆o", 5,
"Vencimento", 7
     SIZE 104.86 BY 1.08
     FGCOLOR 9 FONT 6 NO-UNDO.

DEFINE RECTANGLE RECT-54
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 6.43 BY 18.5
     BGCOLOR 8 .

DEFINE RECTANGLE RECT-55
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 116.29 BY 4.08.

DEFINE RECTANGLE rt-button
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 124 BY 1.46
     BGCOLOR 7 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-work FOR 
      tt-work SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-work w-livre _FREEFORM
  QUERY br-work NO-LOCK DISPLAY
      tt-work.it-codigo       COLUMN-LABEL "Item"                 FORMAT "x(12)"              WIDTH 08
      tt-work.desc-item       COLUMN-LABEL "Descriá∆o"            FORMAT "x(35)"              WIDTH 25
      tt-work.classif         COLUMN-LABEL "Classificaá∆o"        FORMAT "x(15)"              WIDTH 15
      tt-work.acabamento      COLUMN-LABEL "2a Classific."        FORMAT "x(15)"              WIDTH 15  
      tt-work.no-ab-reppri    COLUMN-LABEL "Representante"        FORMAT "x(12)"              WIDTH 26 
      tt-work.cod-rep         COLUMN-LABEL "Cod.Rep"              FORMAT ">>>>9"              WIDTH 06.5
      tt-work.matriz          COLUMN-LABEL "Aliquota ICM  "       FORMAT ">>9.99"             WIDTH 12.5
      tt-work.nome-abrev      COLUMN-LABEL "Cliente"              FORMAT "x(30)"              WIDTH 26
      tt-work.cod-emit        COLUMN-LABEL "Codigo"               FORMAT ">>>>>9"             WIDTH 06.5
      tt-work.regiao          COLUMN-LABEL "Regi∆o"               FORMAT "x(20)"              WIDTH 30 
      tt-work.uf              COLUMN-LABEL "UF"                   FORMAT "x(02)"              WIDTH 03 
      tt-work.nat-operacao    COLUMN-LABEL "Natureza da Operaá∆o" FORMAT "x(16)"              WIDTH 26.4
      tt-work.aliq-icms       COLUMN-LABEL "Aliquota"             FORMAT ">>9.99"             WIDTH 06
      tt-work.cond-pagto      COLUMN-LABEL "Condiá∆o Pagamento"   FORMAT "x(27)"              WIDTH 33.5
      tt-work.lote            COLUMN-LABEL "Lote"                 FORMAT "x(04)"              WIDTH 04
      tt-work.und             COLUMN-LABEL "Und"                  FORMAT "x(03)"              WIDTH 03
      tt-work.qtd             COLUMN-LABEL "Quantidade"           FORMAT ">>>,>>>,>>9.99"     WIDTH 11
      tt-work.vlr             COLUMN-LABEL "Valor"                FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 11
      tt-work.preco-medio     COLUMN-LABEL "Pre Medio"            FORMAT ">,>>9.99"           WIDTH 08 
      tt-work.prazo-medio     COLUMN-LABEL "Prz Medio"            FORMAT ">>9.99"             WIDTH 08 
      tt-work.qtd-devol       COLUMN-LABEL "Qtd Devol"            FORMAT ">>>,>>>,>>9.99"     WIDTH 12
      tt-work.vlr-devol       COLUMN-LABEL "Vlr Devol"            FORMAT ">>>,>>>,>>9.99"     WIDTH 12
      tt-work.vl-icms         COLUMN-LABEL "Valor ICMS"           FORMAT ">>>,>>>,>>>,>>9.99" WIDTH 12
      tt-work.perc-sobr-total COLUMN-LABEL "% "                   FORMAT ">>>9.99"            WIDTH 05
      tt-work.rentabilidade   COLUMN-LABEL "Rentabilidade %"      FORMAT "->,>>9.99"          WIDTH 12
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 116 BY 14.29
         FONT 1
         TITLE "Carteira de Pedidos e Faturamento" ROW-HEIGHT-CHARS .57.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-cad
     rs-sit-credito AT ROW 1.21 COL 3.14 NO-LABEL
     br-work AT ROW 2.71 COL 2
     bt-param AT ROW 2.96 COL 119.72
     bt-vapara AT ROW 4.25 COL 119.86
     bt-vendas AT ROW 5.67 COL 119.86
     bt-devolucao AT ROW 6.92 COL 120
     bt-vendas-tot AT ROW 8.17 COL 119.86
     bt-totais AT ROW 9.42 COL 120
     bt-Grafico-qtd AT ROW 11.38 COL 119.86
     bt-Grafico-vlr AT ROW 12.67 COL 119.86
     bt-repres AT ROW 15 COL 120 WIDGET-ID 24
     bt-exporta AT ROW 17.21 COL 120 WIDGET-ID 22
     fi-total-qtd-m AT ROW 17.46 COL 14.57 COLON-ALIGNED NO-LABEL
     fi-total-qtd-kg AT ROW 17.46 COL 44.14 COLON-ALIGNED NO-LABEL
     fi-total-qtd-und AT ROW 17.46 COL 71.86 COLON-ALIGNED NO-LABEL
     fi-total-vlr AT ROW 17.46 COL 99.72 COLON-ALIGNED NO-LABEL
     fi-total-vlr-m AT ROW 18.38 COL 14.57 COLON-ALIGNED NO-LABEL
     fi-total-vlr-kg AT ROW 18.38 COL 44.14 COLON-ALIGNED NO-LABEL
     fi-total-vlr-und AT ROW 18.38 COL 71.86 COLON-ALIGNED NO-LABEL
     fi-total-devol AT ROW 18.46 COL 99.72 COLON-ALIGNED NO-LABEL
     bt-excel AT ROW 18.5 COL 119.86
     bt-imprime AT ROW 19.79 COL 119.86
     fi-pmedio-m AT ROW 20.17 COL 14.43 COLON-ALIGNED NO-LABEL
     fi-pmedio-kg AT ROW 20.17 COL 44 COLON-ALIGNED NO-LABEL
     fi-pmedio-und AT ROW 20.17 COL 71.86 COLON-ALIGNED NO-LABEL
     fi-prazo-medio AT ROW 20.17 COL 99.72 COLON-ALIGNED NO-LABEL WIDGET-ID 12
     fi-total-icms AT ROW 20.17 COL 99.72 COLON-ALIGNED NO-LABEL
     fi-qt-pecas AT ROW 20.17 COL 99.72 COLON-ALIGNED NO-LABEL WIDGET-ID 16
     fi-tx-dev AT ROW 18.58 COL 86.14 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     fi-lbl-prazo AT ROW 20.33 COL 85 COLON-ALIGNED NO-LABEL WIDGET-ID 10
     fi-tx-tot-pecas AT ROW 20.38 COL 87 COLON-ALIGNED NO-LABEL WIDGET-ID 20
     fi-tx-icms AT ROW 20.38 COL 89.29 COLON-ALIGNED NO-LABEL WIDGET-ID 8
     "Preáo Medio (Un):" VIEW-AS TEXT
          SIZE 15 BY .67 AT ROW 20.25 COL 58.57
          FONT 6
     "Total Qtd (Un):" VIEW-AS TEXT
          SIZE 12.57 BY .67 AT ROW 17.63 COL 61
          FONT 6
     "Total Geral Valor:" VIEW-AS TEXT
          SIZE 14.57 BY .5 AT ROW 17.63 COL 87
          FONT 6
     "Total Qtd (M):" VIEW-AS TEXT
          SIZE 11.43 BY .67 AT ROW 17.58 COL 4.86
          FONT 6
     "Total Qtd (Kg):" VIEW-AS TEXT
          SIZE 11.86 BY .67 AT ROW 17.63 COL 33.43
          FONT 6
     "Preáo Medio (Kg):" VIEW-AS TEXT
          SIZE 14.43 BY .67 AT ROW 20.25 COL 31.14
          FONT 6
     "Total Valor (M):" VIEW-AS TEXT
          SIZE 13 BY .67 AT ROW 18.46 COL 3.57
          FONT 6
     "Preáo Medio (M):" VIEW-AS TEXT
          SIZE 14.43 BY .67 AT ROW 20.25 COL 2.14
          FONT 6
     "Total Valor (Kg):" VIEW-AS TEXT
          SIZE 13.14 BY .67 AT ROW 18.5 COL 32.14
          FONT 6
     "Total Valor (Un):" VIEW-AS TEXT
          SIZE 13.72 BY .67 AT ROW 18.5 COL 60
          FONT 6
     RECT-54 AT ROW 2.75 COL 119
     RECT-55 AT ROW 17.25 COL 1.72
     rt-button AT ROW 1 COL 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 126.43 BY 20.63
         FONT 1.


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
         TITLE              = "Administraá∆o da Carteira e do Faturamento"
         COLUMN             = 23.43
         ROW                = 6.71
         HEIGHT             = 20.38
         WIDTH              = 125.72
         MAX-HEIGHT         = 28.13
         MAX-WIDTH          = 146.29
         VIRTUAL-HEIGHT     = 28.13
         VIRTUAL-WIDTH      = 146.29
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
/* BROWSE-TAB br-work rs-sit-credito f-cad */
/* SETTINGS FOR BUTTON bt-excel IN FRAME f-cad
   6                                                                    */
/* SETTINGS FOR BUTTON bt-exporta IN FRAME f-cad
   6                                                                    */
/* SETTINGS FOR BUTTON bt-Grafico-qtd IN FRAME f-cad
   6                                                                    */
/* SETTINGS FOR BUTTON bt-Grafico-vlr IN FRAME f-cad
   6                                                                    */
/* SETTINGS FOR BUTTON bt-repres IN FRAME f-cad
   6                                                                    */
/* SETTINGS FOR BUTTON bt-totais IN FRAME f-cad
   6                                                                    */
/* SETTINGS FOR BUTTON bt-vendas IN FRAME f-cad
   4                                                                    */
/* SETTINGS FOR BUTTON bt-vendas-tot IN FRAME f-cad
   4 6                                                                  */
/* SETTINGS FOR FILL-IN fi-pmedio-kg IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-pmedio-m IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-pmedio-und IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-prazo-medio IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-qt-pecas IN FRAME f-cad
   NO-DISPLAY NO-ENABLE                                                 */
ASSIGN 
       fi-qt-pecas:HIDDEN IN FRAME f-cad           = TRUE.

/* SETTINGS FOR FILL-IN fi-total-devol IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-icms IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-qtd-kg IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-qtd-m IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-qtd-und IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr-kg IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr-m IN FRAME f-cad
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN fi-total-vlr-und IN FRAME f-cad
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-livre)
THEN w-livre:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-work
/* Query rebuild information for BROWSE br-work
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-work  WHERE
                                 tt-work.visualiza = YES NO-LOCK
                                 ~{&SORTBY-PHRASE}.
     _END_FREEFORM
     _Options          = "NO-LOCK INDEXED-REPOSITION"
     _Query            is OPENED
*/  /* BROWSE br-work */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-livre
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON END-ERROR OF w-livre /* Administraá∆o da Carteira e do Faturamento */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-livre w-livre
ON WINDOW-CLOSE OF w-livre /* Administraá∆o da Carteira e do Faturamento */
DO:
  /* This ADM code must be left here in order for the SmartWindow
  and its descendents to terminate properly on exit. */
  ASSIGN essp0190-aberto = NO.
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-work
&Scoped-define SELF-NAME br-work
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work w-livre
ON ROW-DISPLAY OF br-work IN FRAME f-cad /* Carteira de Pedidos e Faturamento */
DO:
  /* ITEM */
  IF tt-work.it-codigo <> "" AND tt-work.uf = "ZZ" THEN DO:
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15.
     tt-work.it-codigo:FGCOLOR IN BROWSE br-work    = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.und:FGCOLOR IN BROWSE br-work          = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.it-codigo <> "" AND tt-work.seq-item <> 1 THEN DO:
     tt-work.it-codigo:FGCOLOR IN BROWSE br-work = 15.
     tt-work.desc-item:FGCOLOR IN BROWSE br-work = 15.
  END.

  /* REPRESENTANTE */
  IF tt-work.no-ab-reppri <> "" AND tt-work.uf = "ZZ" THEN DO:
     tt-work.cod-rep:FGCOLOR IN BROWSE br-work      = 15.
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15.
     tt-work.no-ab-reppri:FGCOLOR IN BROWSE br-work = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.und:FGCOLOR IN BROWSE br-work          = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.no-ab-reppri <> "" AND tt-work.seq-repres <> 1 THEN
     tt-work.no-ab-reppri:FGCOLOR IN BROWSE br-work = 15.
  /* GRUPO OU MATRIZ */
  IF tt-work.matriz <> 0 AND tt-work.uf = "ZZ" THEN DO:
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15.
     tt-work.it-codigo:FGCOLOR IN BROWSE br-work    = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.und:FGCOLOR IN BROWSE br-work          = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.matriz <> 0 AND tt-work.seq-grupo <> 1 THEN DO:
     tt-work.matriz:FGCOLOR IN BROWSE br-work = 15.
  END.

  /* CLIENTE */
  IF tt-work.nome-abrev <> "" AND tt-work.uf = "ZZ" THEN DO:
     tt-work.cod-emit:FGCOLOR IN BROWSE br-work     = 15.
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15.
     tt-work.nome-abrev:FGCOLOR IN BROWSE br-work   = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.und:FGCOLOR IN BROWSE br-work          = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.nome-abrev <> "" AND tt-work.seq-cliente <> 1 THEN DO:
     tt-work.nome-abrev:FGCOLOR IN BROWSE br-work = 15.
  END.

  /* REGIAO */
  IF tt-work.regiao <> "" AND tt-work.uf = "ZZ" THEN DO:
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15. 
     tt-work.regiao:FGCOLOR IN BROWSE br-work       = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.regiao <> "" AND tt-work.seq-regiao <> 1 THEN
     tt-work.regiao:FGCOLOR IN BROWSE br-work = 15.
  IF tt-work.regiao <> "" AND tt-work.seq-uf <> 1 THEN
     tt-work.uf:FGCOLOR IN BROWSE br-work = 15.   

  /* NATUREZA OPERAÄ«O */
  IF tt-work.nat-operacao <> "" AND tt-work.uf = "ZZ" THEN DO:
     tt-work.aliq-icms:FGCOLOR IN BROWSE br-work    = 15.
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15.
     tt-work.nome-abrev:FGCOLOR IN BROWSE br-work   = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.und:FGCOLOR IN BROWSE br-work          = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.vl-icms:FONT IN BROWSE br-work         =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.nat-operacao <> "" AND tt-work.seq-nat-oper <> 1 THEN DO:
     tt-work.nat-operacao:FGCOLOR IN BROWSE br-work = 15.
  END.

  /* CONDIÄ«O DE PAGAMENTO */
  IF tt-work.cond-pagto <> "" AND tt-work.uf = "ZZ" THEN DO:
     tt-work.uf:FGCOLOR IN BROWSE br-work           = 15.
     tt-work.cond-pagto:FGCOLOR IN BROWSE br-work   = 15.
     tt-work.lote:FGCOLOR IN BROWSE br-work         = 15.
     tt-work.und:FGCOLOR IN BROWSE br-work          = 15.
     tt-work.qtd:FONT IN BROWSE br-work             =  6.
     tt-work.vlr:FONT IN BROWSE br-work             =  6.
     tt-work.preco-medio:FONT IN BROWSE br-work     =  6.
     tt-work.prazo-medio:FONT IN BROWSE br-work     =  6.
     tt-work.rentabilidade:FONT IN BROWSE br-work   =  6.
     tt-work.perc-sobr-total:FONT IN BROWSE br-work =  6. 
     tt-work.qtd-devol:FONT IN BROWSE br-work       =  6.
     tt-work.vlr-devol:FONT IN BROWSE br-work       =  6.
     RUN pi-cor (INPUT 1).
  END.
  IF tt-work.cond-pagto <> "" AND tt-work.seq-cond-pg <> 1 THEN DO:
     tt-work.cond-pagto:FGCOLOR IN BROWSE br-work = 15.
  END.

  IF tt-work.qtd-devol = 0 THEN 
     tt-work.qtd-devol:FGCOLOR IN BROWSE br-work = 15.
  IF tt-work.vlr-devol = 0 THEN 
     tt-work.vlr-devol:FGCOLOR IN BROWSE br-work = 15.
  IF tt-work.qtd-devol <> 0 THEN
     tt-work.qtd-devol:FGCOLOR IN BROWSE br-work = 4.
  IF tt-work.vlr-devol <> 0 THEN
     tt-work.vlr-devol:FGCOLOR IN BROWSE br-work = 4.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-work w-livre
ON VALUE-CHANGED OF br-work IN FRAME f-cad /* Carteira de Pedidos e Faturamento */
DO:
    /*
  IF tt-work.uf = "ZZ" THEN
     APPLY "CURSOR-DOWN" TO SELF.
     */
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-devolucao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-devolucao w-livre
ON CHOOSE OF bt-devolucao IN FRAME f-cad
DO:
    IF CAN-FIND(FIRST tt-devolucao) THEN
       RUN esp/essp0190f.w (INPUT TABLE tt-devolucao,
                            INPUT c-dt-faturadas-ini,
                            INPUT c-dt-faturadas-fin).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-excel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-excel w-livre
ON CHOOSE OF bt-excel IN FRAME f-cad /* Button 2 */
DO:
   RUN esdlg/d02essp0190.w (OUTPUT arq-saida,
                            INPUT i-tp-selecao,
                            INPUT c-dt-faturar,
                            INPUT c-dt-faturadas-ini,
                            INPUT c-dt-faturadas-fin,
                            INPUT c-dt-vendido-ini,
                            INPUT c-dt-vendido-fin).
   IF arq-saida <> "" THEN DO:
      RUN pi-gera-excel.
      MESSAGE "O arquivo foi gerado em " TRIM(arq-saida) + "." SKIP 
              "Para acess†-lo,  abra-o atravÇs do Excel."
          VIEW-AS ALERT-BOX INFO BUTTONS OK. 
   END.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-exporta
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-exporta w-livre
ON CHOOSE OF bt-exporta IN FRAME f-cad /* bt excel */
DO:
   SESSION:SET-WAIT-STATE("general":U).
    
   ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0190.csv".
   OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
   
   PUT "Pedido;Cliente;UF;Representante;Item;Descriá∆o;Categoria;Quantidade;Preáo Un;Preáo TAB;Valor Total;Desconto;Prazo MÇdio"
       SKIP.

   FOR EACH tt-pedidos.
       FIND nota-fiscal WHERE
            nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
            nota-fiscal.serie = tt-pedidos.serie AND
            nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.

       FIND cond-pagto WHERE
            cond-pagto.cod-cond-pag = nota-fiscal.cod-cond-pag NO-LOCK NO-ERROR.

       IF AVAIL cond-pagto THEN 
          ASSIGN i-prazo-medio = cond-pagto.qtd-dias-prazo-medio.
       ELSE DO.
          ASSIGN de-tot-prazo = 0
                 i-ct = 0.
          FOR EACH cond-ped WHERE
                   cond-ped.nr-pedido = INTEGER(nota-fiscal.nr-pedcli) NO-LOCK.
              ASSIGN de-tot-prazo = de-tot-prazo + cond-ped.nr-dias-venc.
              ASSIGN i-ct = i-ct + 1.
          END.
          ASSIGN i-prazo-medio = de-tot-prazo / i-ct.
       END.
       IF i-prazo-medio = ? THEN
          ASSIGN i-prazo-medio = 1.

       ASSIGN de-ind-finan = 1.
       FIND FIRST tab-finan WHERE 
                  tab-finan.dt-ini-val <= nota-fiscal.dt-emis AND 
                  tab-finan.dt-fim-val >= nota-fiscal.dt-emis NO-LOCK NO-ERROR.
       /*
       DO i-ct = 1 TO EXTENT(tab-finan.tab-dia-fin).
          IF tab-finan.tab-dia-fin[i-ct] >= i-prazo-medio THEN
             LEAVE. 
       END.

       IF i-ct > EXTENT(tab-finan.tab-ind-fin) THEN
          ASSIGN i-ct = EXTENT(tab-finan.tab-ind-fin).

       ASSIGN de-ind-finan = tab-finan.tab-ind-fin[i-ct].
       */

       ASSIGN de-ind-finan = 1.
       FIND FIRST tab-finan-indice OF tab-finan WHERE 
                  tab-finan-indice.tab-dia-fin >= i-prazo-medio NO-LOCK NO-ERROR.
       IF AVAIL tab-finan-indice THEN
          ASSIGN de-ind-finan = tab-finan-indice.tab-ind-fin.
    
       ASSIGN c-tb-preco-pad = ''.
       FIND emitente WHERE
            emitente.cod-emit = nota-fiscal.cod-emit NO-LOCK NO-ERROR.
       IF nota-fiscal.cod-estabel = "1" THEN DO.
          FIND unid-feder WHERE 
               unid-feder.estado = emitente.estado NO-LOCK NO-ERROR.
          IF unid-feder.char-2 = 'SUL' OR
             (unid-feder.char-2 = 'SUDESTE' AND unid-feder.estado <> "ES") THEN
             FIND im-param WHERE
                  im-param.cod-param = "TABELA_IMA12" NO-LOCK NO-ERROR.
          ELSE
             FIND im-param WHERE
                  im-param.cod-param = "TABELA_IMA07" NO-LOCK NO-ERROR.
       END.
       ELSE
          FIND im-param WHERE
               im-param.cod-param = "TABELA_MED" NO-LOCK NO-ERROR.

       IF AVAIL im-param THEN
          ASSIGN c-tb-preco-pad = im-param.val-param.

       FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
           FIND item WHERE
                item.it-codigo = it-nota-fisc.it-codigo NO-LOCK NO-ERROR.

           FIND fam-comerc WHERE
                fam-comerc.fm-cod-com = item.fm-cod-com NO-LOCK NO-ERROR.

           ASSIGN de-vl-pre-tab = 0.
           IF c-tb-preco-pad <> '' THEN DO.
              FIND preco-item WHERE
                   preco-item.nr-tabpre = c-tb-preco-pad AND
                   preco-item.it-codigo = it-nota-fisc.it-codigo AND
                   preco-item.cod-refer = it-nota-fisc.cod-refer AND
                   preco-item.cod-unid-med = item.un
                   NO-LOCK NO-ERROR.
    
               IF AVAIL preco-item THEN
                  ASSIGN de-vl-pre-tab = (preco-item.preco-venda * de-ind-finan).
           END.

           PUT UNFORMATTED
               nota-fiscal.nr-pedcli       ";"
               nota-fiscal.nome-ab-cli     ";"
               nota-fiscal.estado          ";"
               nota-fiscal.no-ab-reppri    ";"
               it-nota-fisc.it-codigo      ";"
               item.desc-item              ";"
               fam-comerc.descricao        ";"
               it-nota-fisc.qt-faturada[1] ";"
               it-nota-fisc.vl-preuni      ";"
               de-vl-pre-tab               ";"
               it-nota-fisc.vl-tot-item    ";"
               IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                  THEN it-nota-fisc.val-desconto-total 
                  ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) ";"
               i-prazo-medio ";"
               SKIP.
       END.
   END.
   OUTPUT CLOSE.

   SESSION:SET-WAIT-STATE("":U).

   MESSAGE 'Gerado o Arquivo ' + c-saida 
       VIEW-AS ALERT-BOX INFO BUTTONS OK.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-Grafico-qtd
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-Grafico-qtd w-livre
ON CHOOSE OF bt-Grafico-qtd IN FRAME f-cad /* Grafico */
DO:
  RUN pi-grafico-qtd.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-Grafico-vlr
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-Grafico-vlr w-livre
ON CHOOSE OF bt-Grafico-vlr IN FRAME f-cad /* Grafico */
DO:
  RUN pi-grafico-vlr.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-imprime
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-imprime w-livre
ON CHOOSE OF bt-imprime IN FRAME f-cad
DO:
  RUN pi-imprime.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-param
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-param w-livre
ON CHOOSE OF bt-param IN FRAME f-cad /* Button 3 */
DO:
  ASSIGN w-livre:SENSITIVE = NO.
  ASSIGN l-faturamento  = YES
         l-entre-estab  = NO
         l-outros-fat   = NO
         l-pilotagem = YES.

  RUN esp/essp0190a.w (INPUT-OUTPUT TABLE tt-digita,
                       INPUT-OUTPUT i-tp-selecao,
                       INPUT-OUTPUT c-dt-faturar,   
                       INPUT-OUTPUT c-dt-faturadas-ini,
                       INPUT-OUTPUT c-dt-faturadas-fin,   
                       INPUT-OUTPUT c-dt-vendido-ini,
                       INPUT-OUTPUT c-dt-vendido-fin,
                       INPUT-OUTPUT c-cod-estabel-ini,
                       INPUT-OUTPUT c-cod-estabel-fin,
                       INPUT-OUTPUT c-nr-pedcli-ini,   
                       INPUT-OUTPUT c-nr-pedcli-fin,   
                       INPUT-OUTPUT c-it-codigo-ini,   
                       INPUT-OUTPUT c-it-codigo-fin,   
                       INPUT-OUTPUT c-cod-refer-ini,   
                       INPUT-OUTPUT c-cod-refer-fin,   
                       INPUT-OUTPUT c-nome-abrev-ini,
                       INPUT-OUTPUT c-nome-abrev-fin,
                       INPUT-OUTPUT c-no-ab-reppri-ini,
                       INPUT-OUTPUT c-no-ab-reppri-fin,
                       INPUT-OUTPUT c-fm-cod-com-ini,
                       INPUT-OUTPUT c-fm-cod-com-fin,
                       INPUT-OUTPUT i-ge-codigo-ini,   
                       INPUT-OUTPUT i-ge-codigo-fin,   
                       INPUT-OUTPUT c-matriz-ini,
                       INPUT-OUTPUT c-matriz-fin,
                       INPUT-OUTPUT c-tp-pedido,   
                       INPUT-OUTPUT i-tb_preco_id,
                       INPUT-OUTPUT l-lote-rp,                    
                       INPUT-OUTPUT l-lote-rd,
                       INPUT-OUTPUT i-outlet,
                       INPUT-OUTPUT c-tipo-acabamento,       
                       INPUT-OUTPUT c-tipo-mercado,         
                       INPUT-OUTPUT l-faturamento,
                       INPUT-OUTPUT l-entre-estab,
                       INPUT-OUTPUT l-outros-fat,
                       INPUT-OUTPUT l-pilotagem,
                       INPUT-OUTPUT l-ok). 
  IF l-ok THEN DO.
     ASSIGN c-cod-depos = 'TODOS'
            l-lote-todos = l-lote-rp = YES AND l-lote-rd = YES.

     RUN pi-processa.
  END.

  ASSIGN w-livre:SENSITIVE = YES.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-repres
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-repres w-livre
ON CHOOSE OF bt-repres IN FRAME f-cad /* bt excel */
DO:
   RUN esp/essp0190i.p (OUTPUT i-opcao).
   CASE i-opcao.
       WHEN 1 THEN // Cen†rio ANUAL (£ltimos 12 meses) das Vendas por Representante
            RUN esp/essp0190h.p.
       WHEN 2 THEN // Cen†rio SEMANAL das Vendas por Representante
            RUN esp/essp0190g.w (INPUT TABLE tt-pedidos, 
                                   INPUT c-dt-faturar,     
                                   INPUT c-dt-faturadas-ini,
                                   INPUT c-dt-faturadas-fin,
                                   INPUT c-dt-vendido-ini, 
                                   INPUT c-dt-vendido-fin, 
                                   INPUT i-tp-selecao).    
       WHEN 3 THEN // Resumo das Vendas por Representante (EXCEL)
           RUN pi-vendas-periodo.
       WHEN 4 THEN // Composiá∆o dos Itens Vendidos por Representante
           RUN esp/essp0190d.w (INPUT TABLE tt-pedidos,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin,
                                INPUT i-tp-selecao,
                                INPUT tt-work.no-ab-reppri,
                                INPUT c-it-codigo-ini,
                                INPUT c-it-codigo-fin,
                                INPUT c-cod-refer-ini,
                                INPUT c-cod-refer-fin,
                                INPUT c-lotes,
                                INPUT c-corte-comerc-ini,
                                INPUT c-corte-comerc-fin,
                                INPUT i-ge-codigo-ini,
                                INPUT i-ge-codigo-fin,
                                INPUT c-fm-cod-com-ini,
                                INPUT c-fm-cod-com-fin,
                                INPUT c-tipo-acabamento,
                                INPUT c-cod-depos,
                                INPUT TABLE tt-digita,
                                INPUT tt-work.lote,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT tt-work.regiao).
       WHEN 5 THEN // Curva ABC de Cliente por Representante
           RUN pi-curva-abc-cli.
   END CASE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-totais
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-totais w-livre
ON CHOOSE OF bt-totais IN FRAME f-cad
DO:  
  CASE rs-sit-credito:SCREEN-VALUE:
      WHEN "1" THEN
          RUN esp/essp0190E.w (INPUT TABLE tt-work,
                               INPUT rs-sit-credito:SCREEN-VALUE,
                               INPUT i-tp-selecao,
                               INPUT c-dt-faturar,
                               INPUT c-dt-faturadas-ini,
                               INPUT c-dt-faturadas-fin,
                               INPUT c-dt-vendido-ini,
                               INPUT c-dt-vendido-fin).
      WHEN "2" THEN
          RUN esp/essp0190E1.w (INPUT TABLE tt-work,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT i-tp-selecao,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin).
      WHEN "3" THEN
          RUN esp/essp0190E2.w (INPUT TABLE tt-work,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT i-tp-selecao,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin).
      WHEN "4" THEN
          RUN esp/essp0190E3.w (INPUT TABLE tt-work,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT i-tp-selecao,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin).
      WHEN "5" THEN
          RUN esp/essp0190E4.w (INPUT TABLE tt-work,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT i-tp-selecao,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin).
      WHEN "6" THEN
          RUN esp/essp0190E5.w (INPUT TABLE tt-work,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT i-tp-selecao,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin).
      WHEN "7" THEN
          RUN esp/essp0190E6.w (INPUT TABLE tt-work,
                                INPUT rs-sit-credito:SCREEN-VALUE,
                                INPUT i-tp-selecao,
                                INPUT c-dt-faturar,
                                INPUT c-dt-faturadas-ini,
                                INPUT c-dt-faturadas-fin,
                                INPUT c-dt-vendido-ini,
                                INPUT c-dt-vendido-fin).
  END CASE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vapara
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vapara w-livre
ON CHOOSE OF bt-vapara IN FRAME f-cad
DO:
   RUN esdlg/d01essp0190.w (OUTPUT c-codigo).

   IF c-codigo <> "" THEN DO:

      CASE rs-sit-credito:SCREEN-VALUE:
          WHEN '1' THEN
              FIND FIRST tt-work WHERE
                   tt-work.it-codigo = c-codigo NO-LOCK NO-ERROR.
          WHEN '2' THEN
              FIND FIRST tt-work WHERE
                   tt-work.no-ab-reppri = c-codigo NO-LOCK NO-ERROR.
          WHEN '3' THEN
              FIND FIRST tt-work WHERE
                   tt-work.matriz = dec(c-codigo) NO-LOCK NO-ERROR.
          WHEN '4' THEN
              FIND FIRST tt-work WHERE
                   tt-work.nome-abrev = c-codigo NO-LOCK NO-ERROR.
          WHEN '5' THEN
              FIND FIRST tt-work WHERE
                   tt-work.regiao = c-codigo NO-LOCK NO-ERROR.
          WHEN '6' THEN
              FIND FIRST tt-work WHERE
                   tt-work.nat-operacao = c-codigo NO-LOCK NO-ERROR.
          WHEN '7' THEN
              FIND FIRST tt-work WHERE
                   SUBSTR(tt-work.cond-pagto, 2, LENGTH(c-codigo)) = c-codigo NO-LOCK NO-ERROR.
      END CASE.
      IF NOT AVAIL tt-work THEN DO.
         MESSAGE "C¢digo n∆o est† contido na seleá∆o!"
             VIEW-AS ALERT-BOX INFO BUTTONS OK.
         RETURN NO-APPLY.
      END.

      h-query:REPOSITION-TO-ROWID(ROWID(tt-work)) NO-ERROR. 
      APPLY 'VALUE-CHANGED' TO br-work.
      
   END.
   
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vendas
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vendas w-livre
ON CHOOSE OF bt-vendas IN FRAME f-cad
DO:
   IF AVAIL tt-pedidos THEN
      RUN esp/essp0190b.w (INPUT TABLE tt-pedidos,
                           INPUT tt-work.it-codigo,
                           INPUT tt-work.no-ab-reppri,
                           INPUT tt-work.matriz,
                           INPUT tt-work.nome-abrev,
                           INPUT tt-work.regiao,
                           INPUT tt-work.nat-operacao,
                           INPUT tt-work.cond-pagto,
                           INPUT rs-sit-credito:SCREEN-VALUE,
                           INPUT c-dt-faturar,
                           INPUT c-dt-faturadas-ini,
                           INPUT c-dt-faturadas-fin,
                           INPUT c-dt-vendido-ini,
                           INPUT c-dt-vendido-fin,
                           INPUT i-tp-selecao,
                           INPUT c-it-codigo-ini,
                           INPUT c-it-codigo-fin,
                           INPUT c-cod-refer-ini,
                           INPUT c-cod-refer-fin,
                           INPUT c-lotes,
                           INPUT c-corte-comerc-ini,
                           INPUT c-corte-comerc-fin,
                           INPUT i-ge-codigo-ini,
                           INPUT i-ge-codigo-fin,
                           INPUT c-fm-cod-com-ini,
                           INPUT c-fm-cod-com-fin,
                           INPUT c-tipo-acabamento,
                           INPUT c-cod-depos,
                           INPUT TABLE tt-digita,
                           INPUT tt-work.lote,
                           INPUT tt-work.und,
                           INPUT tt-work.uf,
                           INPUT l-faturamento,
                           INPUT l-outros-fat).
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-vendas-tot
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-vendas-tot w-livre
ON CHOOSE OF bt-vendas-tot IN FRAME f-cad
DO:
  IF AVAIL tt-pedidos THEN
     RUN esp/essp0190c.w (INPUT TABLE tt-pedidos,
                          INPUT c-dt-faturar,
                          INPUT c-dt-faturadas-ini,
                          INPUT c-dt-faturadas-fin,
                          INPUT c-dt-vendido-ini,
                          INPUT c-dt-vendido-fin,
                          INPUT i-tp-selecao).
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


&Scoped-define SELF-NAME rs-sit-credito
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-sit-credito w-livre
ON VALUE-CHANGED OF rs-sit-credito IN FRAME f-cad
DO:
   /* Esconde campos do Browse */
   tt-work.it-codigo:VISIBLE IN BROWSE     br-work = NO.
   tt-work.desc-item:VISIBLE IN BROWSE     br-work = NO.
   tt-work.no-ab-reppri:VISIBLE IN BROWSE  br-work = NO.
   tt-work.cod-rep:VISIBLE IN BROWSE       br-work = NO.
   tt-work.matriz:VISIBLE IN BROWSE        br-work = NO.         
   tt-work.nome-abrev:VISIBLE IN BROWSE    br-work = NO.
   tt-work.cod-emit:VISIBLE IN BROWSE      br-work = NO.
   tt-work.regiao:VISIBLE IN BROWSE        br-work = NO.         
   tt-work.uf:VISIBLE IN BROWSE            br-work = NO.         
   tt-work.nat-operacao:VISIBLE IN BROWSE  br-work = NO. 
   tt-work.aliq-icms:VISIBLE IN BROWSE     br-work = NO.
   tt-work.vl-icms:VISIBLE IN BROWSE       br-work = NO.
   tt-work.cond-pagto:VISIBLE IN BROWSE    br-work = NO. 
   tt-work.rentabilidade:VISIBLE IN BROWSE br-work = NO.

   /*
   tt-work.qtd-devol:VISIBLE IN BROWSE     br-work = NO.
   tt-work.vlr-devol:VISIBLE IN BROWSE     br-work = NO.
   */

   fi-total-icms:VISIBLE IN FRAME {&FRAME-NAME} = NO.
   fi-prazo-medio:VISIBLE IN FRAME {&FRAME-NAME} = NO.
   fi-lbl-prazo:VISIBLE IN FRAME {&FRAME-NAME}   = NO.
   fi-tx-dev:VISIBLE IN FRAME {&FRAME-NAME} = NO.
   fi-tx-icms:VISIBLE IN FRAME {&FRAME-NAME} = NO.
   fi-tx-tot-pecas:VISIBLE IN FRAME {&FRAME-NAME} = NO.
   fi-qt-pecas:VISIBLE IN FRAME {&FRAME-NAME} = NO.

  /*TEXT-12:VISIBLE IN FRAME {&FRAME-NAME} = NO. */

   ASSIGN bt-repres:SENSITIVE IN FRAME {&FRAME-NAME} = NO.

   ASSIGN opt-sort         = SELF:INPUT-VALUE
          de-prazo         = 0        i-qtd-nf         = 0      fi-prazo-medio   = 0
          fi-total-vlr     = 0        fi-total-icms    = 0      fi-total-devol   = 0
          fi-total-qtd-m   = 0        fi-total-vlr-m   = 0      fi-total-qtd-kg  = 0
          fi-total-vlr-kg  = 0        fi-total-qtd-und = 0      fi-total-vlr-und = 0
          fi-pmedio-und    = 0        fi-pmedio-kg     = 0      fi-pmedio-m      = 0.

   CASE i-tp-selecao:
       WHEN 1 THEN
           ASSIGN c-titulo = "CARTEIRA A FATURAR NO PERIODO: " +             
                             SUBSTR(c-dt-faturar,1,2) + "/"+ SUBSTR(c-dt-faturar,3,4)
                  br-work:TITLE IN FRAME {&FRAME-NAME} = c-titulo.
       WHEN 2 THEN DO:
           ASSIGN c-titulo = "FATURAMENTO NO PERIODO DE: " +                                                   
                             STRING(c-dt-faturadas-ini, "99/99/9999") + " A " + STRING(c-dt-faturadas-fin, "99/99/9999") 
                  br-work:TITLE IN FRAME {&FRAME-NAME} = c-titulo.
       END.
       WHEN 3 THEN
           ASSIGN c-titulo = "VENDAS DE: " +                                                
                             SUBSTR(c-dt-vendido-ini,1,2) + "/"+ SUBSTR(c-dt-vendido-ini,3,4) + " A " + 
                             SUBSTR(c-dt-vendido-fin,1,2) + "/"+ SUBSTR(c-dt-vendido-fin,3,4)          
                  br-work:TITLE IN FRAME {&FRAME-NAME} = c-titulo.
   END CASE.

   FOR EACH tt-work.
       ASSIGN tt-work.visualiza = NO.
   END.

   tt-work.qtd-devol:VISIBLE IN BROWSE br-work = YES.
   tt-work.vlr-devol:VISIBLE IN BROWSE br-work = YES.

   CASE SELF:SCREEN-VALUE:
       WHEN "1" THEN DO.
           tt-work.it-codigo:VISIBLE IN BROWSE br-work = YES.
           tt-work.desc-item:VISIBLE IN BROWSE br-work = YES.

           fi-tx-tot-pecas:VISIBLE IN FRAME {&FRAME-NAME} = YES.
           fi-qt-pecas:VISIBLE IN FRAME {&FRAME-NAME} = YES.
           FOR EACH tt-work WHERE
                    tt-work.it-codigo <> ""
               BREAK BY tt-work.it-codigo
                     BY tt-work.uf
                     BY tt-work.lote.

               ASSIGN tt-work.visualiza   = YES.

               IF tt-work.uf <> "ZZ" THEN
                 ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                        fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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

               IF FIRST-OF(tt-work.it-codigo) THEN
                  ASSIGN tt-work.seq-item = 1.
           END.
           ASSIGN fi-qt-pecas = i-tot-etq.
           DISP fi-qt-pecas
                WITH FRAME {&FRAME-NAME}.
       END.
       WHEN "2" THEN DO.

           tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work = YES.
           tt-work.cod-rep:VISIBLE IN BROWSE br-work      = YES.
           ASSIGN bt-repres:SENSITIVE IN FRAME {&FRAME-NAME} = YES.
           FOR EACH tt-work WHERE
                    tt-work.no-ab-reppri <> ""
               BREAK BY tt-work.no-ab-reppri
                     BY tt-work.uf
                     BY tt-work.lote
                     BY tt-work.und.

               ASSIGN tt-work.visualiza = YES.

               IF tt-work.uf <> "ZZ" THEN
                  ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                         fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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

               IF FIRST-OF(tt-work.no-ab-reppri) THEN
                  ASSIGN tt-work.seq-repres = 1.

           END.
       END.
       WHEN "3" THEN DO.
           tt-work.matriz:VISIBLE IN BROWSE br-work = YES.
           FOR EACH tt-work WHERE
                    tt-work.matriz <> 0
               BREAK BY dec(tt-work.matriz)
                     BY tt-work.uf
                     BY tt-work.lote.

               ASSIGN tt-work.visualiza = YES.

               IF tt-work.uf <> "ZZ" THEN
                  ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                         fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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

               IF FIRST-OF(dec(tt-work.matriz)) THEN
                  ASSIGN tt-work.seq-grupo = 1.
           END.
       END.
       WHEN "4" THEN DO.
           tt-work.nome-abrev:VISIBLE IN BROWSE br-work = YES.
           tt-work.cod-emit:VISIBLE IN BROWSE br-work   = YES.
           FOR EACH tt-work WHERE
                    tt-work.nome-abrev <> ""
               BREAK BY tt-work.nome-abrev
                     BY tt-work.uf
                     BY tt-work.lote.

               ASSIGN tt-work.visualiza = YES.

               IF tt-work.uf <> "ZZ" THEN
                  ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                         fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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

               IF FIRST-OF(tt-work.nome-abrev) THEN
                  ASSIGN tt-work.seq-cliente = 1.
           END.
       END.
       WHEN "5" THEN DO.
           tt-work.regiao:VISIBLE IN BROWSE br-work = YES.
           tt-work.uf:VISIBLE IN BROWSE br-work     = YES.
           FOR EACH tt-work WHERE
                    tt-work.regiao <> "".
               ASSIGN tt-work.seq-regiao = 0
                      tt-work.seq-uf     = 0.
           END.
           FOR EACH tt-work WHERE
                    tt-work.regiao <> ""
               BREAK BY tt-work.regiao
                     BY tt-work.uf
                     BY tt-work.lote
                     BY tt-work.und.

               ASSIGN tt-work.visualiza  = YES.

               IF tt-work.uf <> "ZZ" THEN
                  ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                         fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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

               IF FIRST-OF(tt-work.regiao) THEN
                  ASSIGN tt-work.seq-regiao = 1.
               IF FIRST-OF(tt-work.uf) AND tt-work.uf <> "ZZ" THEN
                  ASSIGN tt-work.seq-uf = 1.
           END.
       END.
       WHEN "6" THEN DO.
           IF i-tp-selecao = 2 THEN DO:
              tt-work.aliq-icms:VISIBLE IN BROWSE br-work    = YES.
              tt-work.vl-icms:VISIBLE IN BROWSE br-work      = YES.
           END.
           tt-work.nat-operacao:VISIBLE IN BROWSE br-work = YES.
           fi-tx-icms:VISIBLE IN FRAME {&FRAME-NAME} = YES.
           fi-total-icms:VISIBLE IN FRAME {&FRAME-NAME}  = YES.

           FOR EACH tt-work WHERE
                    tt-work.nat-operacao <> ""
               BREAK BY tt-work.nat-operacao
                     BY tt-work.uf
                     BY tt-work.lote.

               ASSIGN tt-work.visualiza = YES.

               IF tt-work.uf <> "ZZ" THEN
                  ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                         fi-total-icms  = fi-total-icms  + tt-work.vl-icms
                         fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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

               IF FIRST-OF(tt-work.nat-operacao) THEN
                  ASSIGN tt-work.seq-nat-oper = 1.

           END.
           IF i-tp-selecao = 2 THEN
              DISP fi-total-icms
                   WITH FRAME {&FRAME-NAME}.
       END.
       WHEN "7" THEN DO.
           tt-work.cond-pagto:VISIBLE IN BROWSE br-work = YES.
           tt-work.rentabilidade:VISIBLE IN BROWSE br-work = YES.
           IF i-tp-selecao = 2 THEN DO:
              fi-prazo-medio:VISIBLE IN FRAME {&FRAME-NAME} = YES.
              fi-lbl-prazo:VISIBLE IN FRAME {&FRAME-NAME}   = YES.
              FOR EACH tt-prazo NO-LOCK
                  BREAK BY tt-prazo.nr-nota-fis.
                  IF FIRST-OF(tt-prazo.nr-nota-fis) THEN DO:
                     ASSIGN de-prazo = de-prazo + tt-prazo.praz-medio
                            i-qtd-nf = i-qtd-nf + 1.
                  END.
              END. 
              ASSIGN fi-prazo-medio  = de-prazo / i-qtd-nf.
              DISP fi-prazo-medio
                   WITH FRAME {&FRAME-NAME}.
           END.
           FOR EACH tt-work WHERE
                    tt-work.cond-pagto <> ""
               BREAK BY tt-work.cond-pagto
                     BY tt-work.uf
                     BY tt-work.lote.

               ASSIGN tt-work.visualiza = YES.

               IF tt-work.uf <> "ZZ" THEN
                  ASSIGN fi-total-vlr   = fi-total-vlr   + tt-work.vlr
                         fi-total-devol = fi-total-devol + tt-work.vlr-devol.
               ELSE DO:
                   CASE tt-work.und:
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
               IF FIRST-OF(tt-work.cond-pagto) THEN
                  ASSIGN tt-work.seq-cond-pg = 1.
           END.
           DISP fi-lbl-prazo
                fi-prazo-medio
                WITH FRAME {&FRAME-NAME}.
       END.
   END CASE.

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
        fi-total-vlr
        fi-pmedio-und
        WITH FRAME {&FRAME-NAME}.

   IF i-tp-selecao = 2 THEN DO.
      ASSIGN fi-tx-dev:VISIBLE IN FRAME {&FRAME-NAME} = YES.

      DISP fi-total-devol
           WITH FRAME {&FRAME-NAME}.
   END.

   {&OPEN-QUERY-br-work} 
   APPLY 'ENTRY' TO br-work IN FRAME {&FRAME-NAME}.
   APPLY 'value-changed' TO br-work IN FRAME {&FRAME-NAME}.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-livre 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

ASSIGN h-query  = br-work:QUERY.

STATUS INPUT OFF. /* Desliga Mensagem no RodapÇ da Tela */

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
       RUN set-position IN h_p-exihel ( 1.13 , 109.14 ) NO-ERROR.
       /* Size in UIB:  ( 1.25 , 16.00 ) */

       /* Links to SmartPanel h_p-exihel. */
       RUN add-link IN adm-broker-hdl ( h_p-exihel , 'State':U , THIS-PROCEDURE ).

       /* Adjust the tab order of the smart objects. */
       RUN adjust-tab-order IN adm-broker-hdl ( h_p-exihel ,
             rs-sit-credito:HANDLE IN FRAME f-cad , 'BEFORE':U ).
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
  DISPLAY rs-sit-credito fi-total-qtd-m fi-total-qtd-kg fi-total-qtd-und 
          fi-total-vlr fi-total-vlr-m fi-total-vlr-kg fi-total-vlr-und 
          fi-total-devol fi-pmedio-m fi-pmedio-kg fi-pmedio-und fi-prazo-medio 
          fi-total-icms fi-tx-dev fi-lbl-prazo fi-tx-tot-pecas fi-tx-icms 
      WITH FRAME f-cad IN WINDOW w-livre.
  ENABLE RECT-54 RECT-55 rt-button rs-sit-credito br-work bt-param bt-vapara 
         bt-vendas bt-devolucao bt-vendas-tot bt-totais bt-Grafico-qtd 
         bt-Grafico-vlr bt-repres bt-exporta bt-excel bt-imprime fi-tx-dev 
         fi-lbl-prazo fi-tx-tot-pecas fi-tx-icms 
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
  ASSIGN essp0190-aberto = NO.
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
  /*
  IF essp0190-aberto THEN DO:
       MESSAGE "Erro ao abrir o programa" SKIP
               "O programa ESSP0190 j† est† aberto"
           VIEW-AS ALERT-BOX ERROR BUTTONS OK.
       apply "close":U to this-procedure.
       RETURN NO-APPLY.
  END.
  ELSE
       ASSIGN essp0190-aberto = YES.
  */ 
    
  /* Code placed here will execute PRIOR to standard behavior. */
  run pi-before-initialize.

  {include/win-size.i}

  {utp/ut9000.i "ESSP0190" "2.04.00.000"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  /* Code placed here will execute AFTER standard behavior.    */

  run pi-after-initialize.


  // seta o BO de acabamento
  RUN esbo/BoOpcaoLista.p PERSISTENT SET hBoOpcaoLista.
  RUN setLista IN hBoOpcaoLista (7).

  /* Busca Nome da Empresa */
  FIND FIRST param-global NO-LOCK NO-ERROR.
  FIND FIRST empresa
       WHERE empresa.ep-codigo = param-global.empresa-prin NO-LOCK NO-ERROR. 
  ASSIGN c-empresa = (IF AVAIL empresa THEN empresa.razao-social ELSE "").

  FIND usu-gr-cli WHERE
       usu-gr-cli.cod-usuario = c-seg-usuario NO-LOCK NO-ERROR.

  ASSIGN c-dt-faturar       = STRING(MONTH(TODAY),'99') + STRING(YEAR(TODAY),'9999')
         c-dt-faturadas-ini = DATE("01" + STRING(MONTH(TODAY), "99") + STRING(YEAR(TODAY), "9999"))
         c-dt-faturadas-fin = TODAY
         c-dt-vendido-ini   = STRING(MONTH(TODAY),"99") + STRING(YEAR(TODAY),"9999")
         c-dt-vendido-fin   = STRING(MONTH(TODAY),"99") + STRING(YEAR(TODAY),"9999").

  APPLY 'choose' TO bt-param.

  APPLY 'entry' TO br-work.
  RETURN NO-APPLY.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-a-faturar w-livre 
PROCEDURE pi-a-faturar :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 ASSIGN c-sit-ped = "1,2,4,5". /* Aberto, Atendido Parcial,Pendente,Suspendo */

 FOR EACH ped-venda WHERE
          LOOKUP(STRING(ped-venda.cod-sit-ped),c-sit-ped) > 0 AND
          ped-venda.nr-pedcli    >= c-nr-pedcli-ini    AND
          ped-venda.nr-pedcli    <= c-nr-pedcli-fin    AND
          ped-venda.dt-entrega   <= da-dt-implant-fin  AND
          ped-venda.nome-abrev   >= c-nome-abrev-ini   AND
          ped-venda.nome-abrev   <= c-nome-abrev-fin   AND
          ped-venda.no-ab-reppri >= c-no-ab-reppri-ini AND
          ped-venda.no-ab-reppri <= c-no-ab-reppri-fin NO-LOCK.

     RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(ped-venda.dt-implant) +
                                         " Pedido: " + ped-venda.nr-pedcli).


     IF ped-venda.cod-estabel < c-cod-estabel-ini OR 
        ped-venda.cod-estabel > c-cod-estabel-fin THEN NEXT.

     /* Criado por Anderson 23/11/2010 */
     /* Procura o deposito padrao da natureza*/
     IF c-cod-depos <> "TODOS" THEN DO:
         FIND FIRST natur-oper-deposito WHERE natur-oper-deposito.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
         IF (AVAIL natur-oper-deposito AND natur-oper-deposito.cod-depos <> c-cod-depos)OR 
            (NOT AVAIL natur-oper-deposito AND c-cod-depos <> "ARM") THEN NEXT.
     END.
     /* Fim Anderson */


     FIND natur-oper WHERE
          natur-oper.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
     IF NOT AVAIL natur-oper THEN NEXT.

     IF l-faturamento AND l-entre-estab = NO THEN DO:
        IF natur-oper.cod-esp <> "DP" THEN NEXT. /* Somente Pedidos que Geraram Duplicatas */
     END.

     IF l-entre-estab AND l-faturamento = NO THEN DO:
        IF natur-oper.cod-esp = "DP" THEN NEXT. /* Somente Pedidos que N∆o Geraram Duplicatas */
     END.

     RUN pi-ver-digita (INPUT "Pedido_de_Venda",                                                             
                        INPUT ped-venda.nr-pedcli).                                                          
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.                                                                

     RUN pi-ver-digita (INPUT "Cliente",
                        INPUT ped-venda.nome-abrev).
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

     RUN pi-ver-digita (INPUT "Representante",
                        INPUT ped-venda.no-ab-reppri).
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

     FIND emitente WHERE
          emitente.nome-abrev = ped-venda.nome-abrev NO-LOCK NO-ERROR.
     IF emitente.nome-matriz < c-matriz-ini OR
        emitente.nome-matriz > c-matriz-fin THEN NEXT.

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

     /* Condiá∆o de Pagamento */
     FIND cond-pagto WHERE
          cond-pagto.cod-cond-pag = ped-venda.cod-cond-pag NO-LOCK NO-ERROR.

     IF NOT AVAIL cond-pagto THEN DO: /* Rotina para Tabela COND-PED */
         ASSIGN i-ct        = 0
                i-prz       = 0.
         FOR EACH cond-ped WHERE
                  cond-ped.nr-pedido = ped-venda.nr-pedido NO-LOCK.
             ASSIGN i-ct  = i-ct + 1.
             ASSIGN i-prz = i-prz + cond-ped.nr-dias-venc.
         END.
         IF i-ct = 0 THEN DO: /* N∆o Gera Duplicatas Lojas TEAR TEXTIL */
            ASSIGN c-cond-pagto = " N∆o Gera Duplicatas".
         END.
         ELSE DO: /* Condiá∆o de Pagamento Especial */
             ASSIGN i-prz = INT(i-prz / i-ct).
             IF i-prz <= 30 THEN
                ASSIGN c-cond-pagto = " De 01 AtÇ 30 Dias".
             ELSE
             IF i-prz <= 60 THEN
                ASSIGN c-cond-pagto = " De 31 AtÇ 60 Dias".
             ELSE
             IF i-prz <= 90 THEN
                ASSIGN c-cond-pagto = " De 61 AtÇ 90 Dias".
             ELSE
                ASSIGN c-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */
         END.
     END.
     ELSE DO:  /* Rotina da Tabela COND-PAGTO */
         IF ped-venda.cod-cond-pag = 1 OR       /* A Vista */
            ped-venda.cod-cond-pag = 2 OR       /* Antecipado */
            ped-venda.cod-cond-pag = 3 THEN DO: /* Contra Apresentaá∆o */
            CASE ped-venda.cod-cond-pag:
                WHEN 1 THEN
                    ASSIGN c-cond-pagto = " A Vista".
                WHEN 2 THEN
                    ASSIGN c-cond-pagto = " A Vista".
                WHEN 3 THEN
                    ASSIGN c-cond-pagto = " Contra Apresentaá∆o".
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
                   ASSIGN c-cond-pagto = " De 01 AtÇ 30 Dias".
                ELSE
                IF i-prz <= 60 THEN
                   ASSIGN c-cond-pagto = " De 31 AtÇ 60 Dias".
                ELSE
                IF i-prz <= 90 THEN
                   ASSIGN c-cond-pagto = " De 61 AtÇ 90 Dias".
                ELSE
                   ASSIGN c-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */
    
             END.
             ELSE DO: /* VENDOR */
                 ASSIGN c-cond-pagto = "ˇVENDOR". /* 1¶ Posiá∆o Ç ALT 164 */
             END.
         END.
     END. /* KBO Condiá∆o de Pagamento */

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
         FIND item WHERE
              item.it-codigo = ped-item.it-codigo NO-LOCK NO-ERROR.

         IF (c-tipo-mercado = "0" AND item.codigo-orig <> 0) OR
            (c-tipo-mercado = "1" AND item.codigo-orig <> 1) OR
            (c-tipo-mercado = "2" AND item.codigo-orig <> 2) THEN NEXT.
         /* Comentado por Anderson 23/11/2010 
         IF ped-item.cod-refer <> "" AND ITEM.deposito-pad <> c-cod-depos THEN NEXT. 
         */
         /* Tecido Cru N∆o Tem Referencia */
         IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
            (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.

         ASSIGN c-lote-refer = "1¶Q".  
         IF ped-item.cod-refer = '888' THEN
            ASSIGN c-lote-refer = "2¶Q".
           
         
         IF c-tipo-acabamento = "E" AND SUBSTR(it-nota-fisc.it-codigo,3,1) <> '0' THEN NEXT.
         IF c-tipo-acabamento = "L" AND SUBSTR(it-nota-fisc.it-codigo,3,1)  = '0' THEN NEXT.
         
         
         RUN pi-grava-movto (INPUT "1",
                             INPUT ped-item.it-codigo,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT item.desc-item,
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).
         FIND repres WHERE
              repres.nome-abrev = ped-venda.no-ab-reppri NO-LOCK NO-ERROR.
         RUN pi-grava-movto (INPUT "2",
                             INPUT ped-venda.no-ab-reppri,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT repres.cod-rep,
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "3",
                             INPUT emitente.nome-matriz,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT "",
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "4",
                             INPUT ped-venda.nome-abrev,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT STRING(ped-venda.cod-emitente),
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "5",
                             INPUT c-regiao,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT emitente.estado,
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         FIND natur-oper WHERE
              natur-oper.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
         RUN pi-grava-movto (INPUT "6",
                             INPUT ped-venda.nat-operacao,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT STRING(natur-oper.aliquota-icm),
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "7",
                             INPUT c-cond-pagto,
                             INPUT item.un,
                             INPUT c-lote-refer,
                             INPUT "",
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).
     END.
 END. /* KBO Ped-venda */
 RUN pi-tot-browse.

 APPLY "VALUE-CHANGED" TO rs-sit-credito IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-abre-excel w-livre 
PROCEDURE pi-abre-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 IF i-qtd-plan = 0 THEN
    ASSIGN i-qtd-plan = 7.

 CREATE "Excel.Application" chExcelApp NO-ERROR.
 IF chExcelApp <> ? THEN /* Cria a Planilha */
    ASSIGN chExcelApp:VISIBLE     = TRUE  /* A Planilha Ficar† Visivel */
           chExcelApp:SheetsInNewWorkbook = i-qtd-plan /* Nı PLANILHAS A SEREM CRIADAS */
           chWorkbook             = chExcelApp:Workbooks:ADD() /* Cria Planilha */
           chworksheet            = chExcelapp:sheets:ITEM(1).

 ASSIGN i-qtd-plan = 0.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-coluna-excel w-livre 
PROCEDURE pi-coluna-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-nr-plan AS INT.
 DEFINE INPUT PARAMETER p-tam-a   AS INT.
 DEFINE INPUT PARAMETER p-tam-b   AS INT.
 DEFINE INPUT PARAMETER p-tam-c   AS INT.
 DEFINE INPUT PARAMETER p-tam-d   AS INT.
 DEFINE INPUT PARAMETER p-tam-e   AS INT.
 DEFINE INPUT PARAMETER p-tam-f   AS INT.
 DEFINE INPUT PARAMETER p-tam-g   AS INT.
 DEFINE INPUT PARAMETER p-tam-h   AS INT.
 DEFINE INPUT PARAMETER p-tam-i   AS INT.
 DEFINE INPUT PARAMETER p-tam-j   AS INT.
 DEFINE INPUT PARAMETER p-tam-k   AS INT.
 DEFINE INPUT PARAMETER p-tam-l   AS INT.
 DEFINE INPUT PARAMETER p-tam-m   AS INT.
 DEFINE INPUT PARAMETER p-col-a   AS CHAR.
 DEFINE INPUT PARAMETER p-col-b   AS CHAR.
 DEFINE INPUT PARAMETER p-col-c   AS CHAR.
 DEFINE INPUT PARAMETER p-col-d   AS CHAR.
 DEFINE INPUT PARAMETER p-col-e   AS CHAR.
 DEFINE INPUT PARAMETER p-col-f   AS CHAR.
 DEFINE INPUT PARAMETER p-col-g   AS CHAR.
 DEFINE INPUT PARAMETER p-col-h   AS CHAR.
 DEFINE INPUT PARAMETER p-col-i   AS CHAR.
 DEFINE INPUT PARAMETER p-col-j   AS CHAR.
 DEFINE INPUT PARAMETER p-col-k   AS CHAR.
 DEFINE INPUT PARAMETER p-col-l   AS CHAR.
 DEFINE INPUT PARAMETER p-col-m   AS CHAR.

 IF p-nr-plan = 1 THEN DO:
    ASSIGN chworksheet:range("A3"):VALUE = p-col-a
           chworksheet:range("B3"):VALUE = p-col-b    
           chworksheet:range("C3"):VALUE = p-col-c  
           chworksheet:range("D3"):VALUE = p-col-d
           chworksheet:range("E3"):VALUE = p-col-e     
           chworksheet:range("F3"):VALUE = p-col-f 
           chworksheet:range("G3"):VALUE = p-col-g  
           chworksheet:range("H3"):VALUE = p-col-h   
           chworksheet:range("I3"):VALUE = p-col-i
           chworksheet:range("J3"):VALUE = p-col-j
           chworksheet:range("K3"):VALUE = p-col-k
           chworksheet:range("L3"):VALUE = p-col-l
           chworksheet:range("M3"):VALUE = p-col-m.

     /* Tamanho das Colunas */
     ASSIGN chWorkSheet:Columns("A"):ColumnWidth = p-tam-a
            chWorkSheet:Columns("B"):ColumnWidth = p-tam-b
            chWorkSheet:Columns("C"):ColumnWidth = p-tam-c
            chWorkSheet:Columns("D"):ColumnWidth = p-tam-d
            chWorkSheet:Columns("E"):ColumnWidth = p-tam-e
            chWorkSheet:Columns("F"):ColumnWidth = p-tam-f
            chWorkSheet:Columns("G"):ColumnWidth = p-tam-g
            chWorkSheet:Columns("H"):ColumnWidth = p-tam-h
            chWorkSheet:Columns("I"):ColumnWidth = p-tam-i
            chWorkSheet:Columns("J"):ColumnWidth = p-tam-j
            chWorkSheet:Columns("K"):ColumnWidth = p-tam-k
            chWorkSheet:Columns("L"):ColumnWidth = p-tam-l
            chWorkSheet:Columns("M"):ColumnWidth = p-tam-m.
 END.
 ELSE DO:
     ASSIGN chworksheet:range("A3"):VALUE = p-col-a
            chworksheet:range("B3"):VALUE = p-col-b    
            chworksheet:range("C3"):VALUE = p-col-c  
            chworksheet:range("D3"):VALUE = p-col-d
            chworksheet:range("E3"):VALUE = p-col-e     
            chworksheet:range("F3"):VALUE = p-col-f 
            chworksheet:range("G3"):VALUE = p-col-g  
            chworksheet:range("H3"):VALUE = p-col-h  
            chworksheet:range("I3"):VALUE = p-col-i  
            chworksheet:range("J3"):VALUE = p-col-j
            chworksheet:range("K3"):VALUE = p-col-k.  

      /* Tamanho das Colunas */
      ASSIGN chWorkSheet:Columns("A"):ColumnWidth = p-tam-a
             chWorkSheet:Columns("B"):ColumnWidth = p-tam-b
             chWorkSheet:Columns("C"):ColumnWidth = p-tam-c
             chWorkSheet:Columns("D"):ColumnWidth = p-tam-d
             chWorkSheet:Columns("E"):ColumnWidth = p-tam-e
             chWorkSheet:Columns("F"):ColumnWidth = p-tam-f
             chWorkSheet:Columns("G"):ColumnWidth = p-tam-g
             chWorkSheet:Columns("H"):ColumnWidth = p-tam-h
             chWorkSheet:Columns("I"):ColumnWidth = p-tam-i
             chWorkSheet:Columns("J"):ColumnWidth = p-tam-j
             chWorkSheet:Columns("K"):ColumnWidth = p-tam-k.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-cor w-livre 
PROCEDURE pi-cor :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    DEF INPUT PARAMETER p-cor AS INT.
    
    tt-work.und:FGCOLOR IN BROWSE {&browse-name}             = p-cor.
    tt-work.qtd:FGCOLOR IN BROWSE {&browse-name}             = p-cor.
    tt-work.vlr:FGCOLOR IN BROWSE {&browse-name}             = p-cor.
    tt-work.vl-icms:FGCOLOR IN BROWSE {&browse-name}         = p-cor.
    tt-work.preco-medio:FGCOLOR IN BROWSE {&browse-name}     = p-cor.
    tt-work.prazo-medio:FGCOLOR IN BROWSE {&browse-name}     = p-cor.
    tt-work.rentabilidade:FGCOLOR IN BROWSE {&browse-name}   = p-cor.
    tt-work.perc-sobr-total:FGCOLOR IN BROWSE {&browse-name} = p-cor. 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-curva-abc-cli w-livre 
PROCEDURE pi-curva-abc-cli :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
   DEF VAR de-tot-quantidade  AS DECIMAL.
   DEF VAR de-tot-valor       AS DECIMAL.
   DEF VAR de-tot-qtd-devol   AS DECIMAL. 
   DEF VAR de-tot-vlr-devol   AS DECIMAL. 
   DEF VAR i-plan             AS INTEGER.

   EMPTY TEMP-TABLE tt-res-cli.
   FOR EACH tt-pedidos NO-LOCK.
       FIND nota-fiscal WHERE
            nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
            nota-fiscal.serie = tt-pedidos.serie AND
            nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.

       FIND emitente WHERE
            emitente.nome-abrev = nota-fiscal.nome-ab-cli NO-LOCK NO-ERROR.

       FIND repres WHERE
            repres.cod-rep = nota-fiscal.cod-rep NO-LOCK NO-ERROR.

       FIND tt-res-cli WHERE
            tt-res-cli.cod-emit = emitente.cod-emit NO-LOCK NO-ERROR.
       IF NOT AVAIL tt-res-cli THEN DO.
          CREATE tt-res-cli.
          ASSIGN tt-res-cli.cod-emit = emitente.cod-emit
                 tt-res-cli.nome-emit = emitente.nome-emit
                 tt-res-cli.nome-rep = repres.nome-abrev.
       END.

       FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
           FIND ped-item-ext WHERE
                ped-item-ext.cod-estabel = nota-fiscal.cod-estabel AND
                ped-item-ext.nr-pedcli = nota-fiscal.nr-pedcli AND
                ped-item-ext.nome-abrev = nota-fiscal.nome-ab-cli AND
                ped-item-ext.nr-sequencia = it-nota-fisc.nr-seq-ped
                NO-LOCK NO-ERROR.
           IF AVAIL ped-item-ext THEN DO.
              ASSIGN tt-res-cli.quantidade = tt-res-cli.quantidade + it-nota-fisc.qt-faturada[1]
                     tt-res-cli.valor = tt-res-cli.valor + it-nota-fisc.vl-tot-item +   
                                        IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                                        THEN it-nota-fisc.val-desconto-total 
                                        ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)). 
           END.
       END.
   END.

   FOR EACH tt-devolucao NO-LOCK.

       FIND emitente WHERE
            emitente.cod-emit = tt-devolucao.cod-emit NO-LOCK NO-ERROR.

       FIND repres WHERE
            repres.cod-rep = emitente.cod-rep NO-LOCK NO-ERROR.

       FIND tt-res-cli WHERE
            tt-res-cli.cod-emit = emitente.cod-emit NO-LOCK NO-ERROR.
       IF NOT AVAIL tt-res-cli THEN DO.
          CREATE tt-res-cli.
          ASSIGN tt-res-cli.cod-emit = emitente.cod-emit
                 tt-res-cli.nome-emit = emitente.nome-emit
                 tt-res-cli.nome-rep = repres.nome-abrev.
       END.
       ASSIGN tt-res-cli.qtd-devol = tt-res-cli.qtd-devol + tt-devolucao.qtd-devol
              tt-res-cli.vlr-devol = tt-res-cli.vlr-devol + tt-devolucao.vlr-devol.
   END.

   ASSIGN i-qtd-plan = 0.
   FOR EACH tt-res-cli BREAK BY tt-res-cli.nome-rep.
       IF FIRST-OF(tt-res-cli.nome-rep) THEN 
          ASSIGN i-qtd-plan = i-qtd-plan + 1.
   END.


   RUN pi-abre-excel.
   IF chExcelApp = ? THEN DO:
      MESSAGE "O Aplicativo EXCEL n∆o foi encontrado. N∆o Ç possivel a execuá∆o do programa."
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
      ASSIGN arq-saida = "".
      RETURN.
   END.

   ASSIGN i-plan = 0.
   FOR EACH tt-res-cli BREAK BY tt-res-cli.nome-rep.
       IF FIRST-OF(tt-res-cli.nome-rep) THEN DO.
          ASSIGN i-plan = i-plan + 1.

          /* Nomear Aba da Planilha */
          chWorkSheet = chExcelapp:Sheets:ITEM(i-plan).
          chWorkSheet:NAME = tt-res-cli.nome-rep.
          chWorkSheet:TAB:ColorIndex = 19.
          
          /* Ativar a Planilha */
          chWorkSheet = chExcelapp:Sheets:ITEM(i-plan).
          chWorkbook:Worksheets(i-plan):activate.
          chExcelApp:ActiveWindow:Zoom = 100.
          
          ASSIGN chworksheet:range("A1"):VALUE = "CURVA ABC DE CLIENTES DO REPRESENTANTE " + tt-res-cli.nome-rep + "     PER÷ODO " + STRING(da-dt-implant-ini,"99/99/9999") + " A " + STRING(da-dt-implant-fin,"99/99/9999"). 

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
          
          ASSIGN chworksheet:range("A3"):VALUE = 'C‡DIGO'
                 chworksheet:range("B3"):VALUE = 'NOME'
                 chworksheet:range("C3"):VALUE = 'QUANTIDADE' 
                 chworksheet:range("D3"):VALUE = 'VALOR'
                 chworksheet:range("E3"):VALUE = 'QTDE DEVOLVIDA'
                 chworksheet:range("F3"):VALUE = 'VALOR DEVOLVIDO'.
        
          /* Tamanho das Colunas */
          ASSIGN chWorkSheet:Columns("A"):ColumnWidth = 8
                 chWorkSheet:Columns("B"):ColumnWidth = 40
                 chWorkSheet:Columns("C"):ColumnWidth = 15
                 chWorkSheet:Columns("D"):ColumnWidth = 15
                 chWorkSheet:Columns("E"):ColumnWidth = 15
                 chWorkSheet:Columns("F"):ColumnWidth = 15.
    
          /* Configura Cabeáalho das Colunas */
          chWorkSheet:Range("A3:L3"):SELECT().
          ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
                 chExcelApp:SELECTION:FONT:SIZE               = 09
                 chExcelApp:SELECTION:FONT:Bold               = TRUE 
                 chExcelApp:SELECTION:FONT:ColorIndex         = 11.
    
          ASSIGN chworksheet:range("A:A"):NumberFormat        = "###.##0"
                 chworksheet:range("B:B"):NumberFormat        = "@"
                 chworksheet:range("C:F"):NumberFormat        = "###.###.##0,00"
                 chworksheet:range("A:A"):HorizontalAlignment = 4  /* Alinhamento a Direita */
                 chworksheet:range("C:F"):HorizontalAlignment = 4. /* Alinhamento a Direita */
    
          ASSIGN i-lin = 5.
    
          ASSIGN de-tot-qt-pe = 0
                 de-tot-vl-pe = 0
                 de-tot-quantidade = 0
                 de-tot-valor = 0
                 de-tot-qtd-devol = 0
                 de-tot-vlr-devol = 0.

          FOR EACH b-tt-res-cli WHERE
                   b-tt-res-cli.nome-rep = tt-res-cli.nome-rep
                   BY b-tt-res-cli.valor DESCENDING.
              ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-res-cli.cod-emit
                     chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-res-cli.nome-emit
                     chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-res-cli.quantidade
                     chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-res-cli.valor
                     chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-res-cli.qtd-devol
                     chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-res-cli.vlr-devol.
               
              ASSIGN de-tot-quantidade = de-tot-quantidade + b-tt-res-cli.quantidade
                     de-tot-valor = de-tot-valor + b-tt-res-cli.valor
                     de-tot-qtd-devol = de-tot-qtd-devol + b-tt-res-cli.qtd-devol
                     de-tot-vlr-devol = de-tot-vlr-devol + b-tt-res-cli.vlr-devol.
        
              ASSIGN i-lin = i-lin + 1.
          END.
        
           
          ASSIGN i-lin = i-lin + 1.
          ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = 'TOTAIS'
                 chworksheet:range("C" + STRING(i-lin)):VALUE = de-tot-quantidade
                 chworksheet:range("D" + STRING(i-lin)):VALUE = de-tot-valor
                 chworksheet:range("E" + STRING(i-lin)):VALUE = de-tot-qtd-devol
                 chworksheet:range("F" + STRING(i-lin)):VALUE = de-tot-vlr-devol.
       END.
   END.
   
   MESSAGE 'Dados Gerados com Sucesso..'
       VIEW-AS ALERT-BOX INFO BUTTONS OK.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-devolucao w-livre 
PROCEDURE pi-devolucao :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF VAR c-natureza     AS CHAR.
 DEF VAR de-fator       AS DEC.
 DEF VAR de-vl-desconto LIKE ped-item.val-desconto-total.
 DEF VAR l-erro-item    AS LOG.

 IF c-cod-depos = "ARM" OR c-cod-depos = "TODOS" THEN DO:
    
    FOR EACH docum-est WHERE
             docum-est.cod-estabel >= c-cod-estabel-ini AND
             docum-est.cod-estabel <= c-cod-estabel-fin AND
             docum-est.dt-trans >= da-dt-implant-ini    AND
             docum-est.dt-trans <= da-dt-implant-fin  NO-LOCK.
    
        FIND natur-oper WHERE
             natur-oper.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
        IF NOT AVAIL natur-oper THEN NEXT.
        IF natur-oper.tipo-compra <> 3 THEN NEXT. /* Devoluá∆o de Cliente */
    
        FIND emitente WHERE
             emitente.cod-emit = docum-est.cod-emitente NO-LOCK NO-ERROR.
        IF NOT AVAIL emitente THEN NEXT.
        IF emitente.nome-abrev < c-nome-abrev-ini OR
           emitente.nome-abrev > c-nome-abrev-fin  THEN NEXT.
        RUN pi-ver-digita (INPUT "Cliente",
                           INPUT emitente.nome-abrev).
        IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.


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
    
        FOR EACH item-doc-est OF docum-est NO-LOCK.
    
            RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(docum-est.dt-trans) +
                                                 " Nota Fiscal: " + item-doc-est.nro-docto).
    
            IF item-doc-est.it-codigo < c-it-codigo-ini OR
               item-doc-est.it-codigo > c-it-codigo-fin THEN NEXT.
    
            IF item-doc-est.cod-refer < c-cod-refer-ini OR  
               item-doc-est.cod-refer > c-cod-refer-fin THEN NEXT.
    
            IF l-lote-todos = NO THEN DO:
               IF l-lote-rp = YES AND item-doc-est.cod-refer = '888' THEN NEXT. 
               IF l-lote-rd = YES AND item-doc-est.cod-refer <> '888' THEN NEXT.
            END.
    
            IF c-tipo-acabamento = "E" AND SUBSTR(item-doc-est.it-codigo,3,1) <> '0' THEN NEXT.
            IF c-tipo-acabamento = "L" AND SUBSTR(item-doc-est.it-codigo,3,1)  = '0' THEN NEXT.
    
    
            /* Pegar o Lote do Item */
            FIND rat-lote WHERE
                 rat-lote.serie-docto  = docum-est.serie-docto  AND
                 rat-lote.nro-docto    = docum-est.nro-docto    AND 
                 rat-lote.cod-emitente = docum-est.cod-emitente AND
                 rat-lote.nat-operacao = docum-est.nat-operacao AND
                 rat-lote.sequencia    = item-doc-est.sequencia AND
                 rat-lote.lote         = '888' NO-LOCK NO-ERROR.
    
            FIND item WHERE
                 item.it-codigo = item-doc-est.it-codigo NO-LOCK NO-ERROR.
            IF NOT AVAIL ITEM THEN NEXT.
    
            IF (c-tipo-mercado = "0" AND item.codigo-orig <> 0) OR
               (c-tipo-mercado = "1" AND item.codigo-orig <> 1) OR
               (c-tipo-mercado = "2" AND item.codigo-orig <> 2) THEN NEXT.
                
            ASSIGN i-ct           = 0       c-cond-pagto   = ""
                   i-cod-vencto   = 0       de-vl-desconto = 0
                   c-natureza     = "Sem NF de Origem"
                   i-prz          = 0.

            FIND nota-fiscal WHERE
                 nota-fiscal.cod-estabel  = docum-est.cod-estabel   AND
                 nota-fiscal.serie        = item-doc-est.serie-comp AND
                 nota-fiscal.nr-nota-fis  = item-doc-est.nro-comp   NO-LOCK NO-ERROR.
    
            ASSIGN l-erro-item = NO.
            IF AVAIL nota-fiscal THEN DO:
               FIND ped-venda WHERE
                    ped-venda.nome-abrev = nota-fiscal.nome-ab-cli AND
                    ped-venda.nr-pedcli = nota-fiscal.nr-pedcli NO-LOCK NO-ERROR.
               IF NOT AVAIL ped-venda THEN NEXT.


               FIND repres WHERE
                    repres.cod-rep = nota-fiscal.cod-rep NO-LOCK NO-ERROR.
               IF NOT AVAIL repres THEN NEXT.
               IF repres.nome-abrev < c-no-ab-reppri-ini OR
                  repres.nome-abrev > c-no-ab-reppri-fin THEN NEXT.
               RUN pi-ver-digita (INPUT "Representante",
                                  INPUT nota-fiscal.no-ab-reppri).
               IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

               FIND it-nota-fisc OF nota-fiscal WHERE 
                    it-nota-fisc.nr-seq-fat = item-doc-est.seq-comp NO-LOCK NO-ERROR.
               IF i-outlet <> 3 THEN DO.
                  RUN pi-ver-liquida (INPUT "D").
                  IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.
               END.

               IF l-faturamento = YES OR l-pilotagem = YES THEN DO: /* Faturamento */
                  FIND estabelec WHERE
                       estabelec.cgc = nota-fiscal.cgc NO-LOCK NO-ERROR.
                  IF AVAIL estabelec THEN NEXT.
               END.
    
               IF l-entre-estab = YES THEN DO: /* Vendas Entre Estabelecimento */
                  FIND estabelec WHERE
                       estabelec.cgc = nota-fiscal.cgc NO-LOCK NO-ERROR.
                  IF NOT AVAIL estabelec THEN NEXT.
               END.
    
               ASSIGN c-natureza = nota-fiscal.nat-operacao.
               FOR EACH fat-duplic WHERE
                        fat-duplic.cod-estabel = nota-fiscal.cod-estabel AND
                        fat-duplic.serie       = nota-fiscal.serie       AND
                        fat-duplic.nr-fatura   = nota-fiscal.nr-nota-fis NO-LOCK.
                   ASSIGN i-prz        = i-prz + (fat-duplic.dt-vencimen - fat-duplic.dt-emissao)
                          i-ct         = i-ct + 1
                          i-cod-vencto = fat-duplic.cod-vencto.
               END.
               IF i-prz <> 0 OR i-cod-vencto = 2 OR i-cod-vencto = 9 THEN DO: 
                  IF i-cod-vencto = 2 THEN
                     ASSIGN c-cond-pagto = " A Vista".
                  ELSE
                  IF i-cod-vencto = 9 THEN
                     ASSIGN c-cond-pagto = " Contra Apresentaá∆o".
                  ELSE DO:
                     i-prz = INT(i-prz / i-ct).
                     IF i-prz <= 30 THEN
                        ASSIGN c-cond-pagto = " De 01 AtÇ 30 Dias".
                     ELSE
                     IF i-prz <= 60 THEN
                        ASSIGN c-cond-pagto = " De 31 AtÇ 60 Dias".
                     ELSE
                     IF i-prz <= 90 THEN
                        ASSIGN c-cond-pagto = " De 61 AtÇ 90 Dias".
                     ELSE
                        ASSIGN c-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Pos Ç ALT 164 */
                  END.
               END.
               ELSE DO:
                  FIND cond-pagto WHERE
                       cond-pagto.cod-cond-pag = nota-fiscal.cod-cond-pag NO-LOCK NO-ERROR.
                  IF AVAIL cond-pagto THEN DO:
                     ASSIGN c-cond-pagto = cond-pagto.descricao.
                     IF cond-pagto.log-2 THEN /* Fat Ç para VENDOR */
                        ASSIGN c-cond-pagto = "ˇVendor". /* 1¶ Pos Ç ALT 164 */
                  END.
               END.
               IF c-cond-pagto = "" THEN
                  ASSIGN c-cond-pagto = " Cupom Fiscal".
              
               IF c-regiao = "Exportaá∆o" THEN
                  ASSIGN c-cond-pagto = "ˇExportaá∆o". /* 1¶ Pos Ç ALT 164 */

               FOR EACH it-nota-fisc OF nota-fiscal WHERE 
                        it-nota-fisc.nr-seq-fat = item-doc-est.seq-comp NO-LOCK.

                   /* Calcula Devoluá∆o do Desconto Proporcial Ö NF Devolvida */
                   ASSIGN de-fator = (item-doc-est.preco-total[1] / (it-nota-fisc.vl-preuni * it-nota-fisc.qt-faturada[1])).
    
                   FIND ped-venda WHERE
                        ped-venda.nome-abrev = nota-fiscal.nome-ab-cli AND
                        ped-venda.nr-pedcli = nota-fiscal.nr-pedcli NO-LOCK NO-ERROR.
    
                   FIND ped-venda-ext WHERE
                        ped-venda-ext.cod-estabel = ped-venda.cod-estabel AND
                        ped-venda-ext.nr-pedido = ped-venda.nr-pedido NO-LOCK NO-ERROR.
                   IF AVAIL ped-venda-ext THEN DO.
                      IF i-tb_preco_id <> 9 AND
                         ped-venda-ext.tb_preco_id <> i-tb_preco_id THEN 
                         ASSIGN l-erro-item = YES.
                   END.

                   ASSIGN de-vl-desconto = 0.
                   FIND ped-item OF ped-venda WHERE
                        ped-item.nr-sequencia = it-nota-fisc.nr-seq-ped NO-LOCK NO-ERROR.
    
                   IF AVAIL ped-item AND
                      ped-item.val-desconto-total > 0 THEN
                      ASSIGN de-vl-desconto = de-vl-desconto + ped-item.val-desconto-total.
    
                   ASSIGN de-vl-desconto = (de-vl-desconto * de-fator).

                   FIND ped-item-ext WHERE
                        ped-item-ext.cod-estabel = ped-venda.cod-estabel AND
                        ped-item-ext.nr-pedcli = ped-venda.nr-pedcli AND
                        ped-item-ext.nome-abrev = ped-venda.nome-abrev AND
                        ped-item-ext.nr-sequencia = it-nota-fisc.nr-seq-ped NO-LOCK NO-ERROR.

                   IF AVAIL ped-item-ext THEN DO.
                       IF NOT l-faturamento AND l-pilotagem AND
                          NOT ped-item-ext.retirar-corte THEN
                          ASSIGN l-erro-item = YES.
    
                       IF l-faturamento AND NOT l-pilotagem AND 
                          ped-item-ext.retirar-corte THEN 
                          ASSIGN l-erro-item = YES.
                   END.
               END.
            END.
            IF l-erro-item THEN NEXT.

            IF c-cond-pagto = "" THEN 
               ASSIGN c-cond-pagto = "ˇSem NF de Origem". /* 1¶ Pos Ç ALT 164 */
    
            ASSIGN c-lote-refer = "1¶Q".  
            IF AVAIL rat-lote THEN
               ASSIGN c-lote-refer = "2¶Q".
    
            RUN pi-grava-devol (INPUT "1",
                                INPUT item-doc-est.it-codigo,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT item.desc-item,
                                INPUT item-doc-est.quantidade,
                                INPUT item-doc-est.preco-total[1] + de-vl-desconto,
                                INPUT docum-est.serie-docto,
                                INPUT docum-est.nro-docto,
                                INPUT docum-est.cod-emitente,
                                INPUT docum-est.nat-operacao).
    
            RUN pi-grava-devol (INPUT "2",
                                INPUT repres.nome-abrev,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT repres.cod-rep,
                                INPUT item-doc-est.quantidade,
                                INPUT item-doc-est.preco-total[1] + de-vl-desconto,
                                INPUT docum-est.serie-docto,
                                INPUT docum-est.nro-docto,
                                INPUT docum-est.cod-emitente,
                                INPUT docum-est.nat-operacao).
            
            RUN pi-grava-devol (INPUT "4",
                                INPUT emitente.nome-abrev,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT STRING(emitente.cod-emitente),
                                INPUT item-doc-est.quantidade,   
                                INPUT item-doc-est.preco-total[1] + de-vl-desconto,
                                INPUT docum-est.serie-docto,
                                INPUT docum-est.nro-docto,
                                INPUT docum-est.cod-emitente,
                                INPUT docum-est.nat-operacao).
    
            RUN pi-grava-devol (INPUT "5",
                                INPUT c-regiao,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT emitente.estado,
                                INPUT item-doc-est.quantidade,     
                                INPUT item-doc-est.preco-total[1] + de-vl-desconto,
                                INPUT docum-est.serie-docto,
                                INPUT docum-est.nro-docto,
                                INPUT docum-est.cod-emitente,
                                INPUT docum-est.nat-operacao).
    
            RUN pi-grava-devol (INPUT "7",
                                INPUT c-cond-pagto,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT "",
                                INPUT item-doc-est.quantidade,   
                                INPUT item-doc-est.preco-total[1] + de-vl-desconto,
                                INPUT docum-est.serie-docto,
                                INPUT docum-est.nro-docto,
                                INPUT docum-est.cod-emitente,
                                INPUT docum-est.nat-operacao).
        END.
    END.    
 END.
 /* Fim Anderson */
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-cabec w-livre 
PROCEDURE pi-excel-cabec :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-nr-plan AS INT.
 DEFINE INPUT PARAMETER p-nome AS CHAR.

 /* Nomear Aba da Planilha */
 chWorkSheet = chExcelapp:Sheets:ITEM(p-nr-plan).
 chWorkSheet:NAME = p-nome.
 chWorkSheet:TAB:ColorIndex = 19.

 /* Ativar a Planilha */
 chWorkSheet = chExcelapp:Sheets:ITEM(p-nr-plan).
 chWorkbook:Worksheets(p-nr-plan):activate.
 chExcelApp:ActiveWindow:Zoom = 100.

 ASSIGN chworksheet:range("A1"):VALUE = c-titulo + " POR " + UPPER(p-nome).

 /* Configura Alinhamento Horizontal do Titulo da Planilha */
 IF p-nr-plan = 1 THEN DO: 
    ChWorkSheet:range("A1:L1"):SELECT().
    ChWorksheet:range("A1:L1"):Merge.
    Chworksheet:Range("A1:L1"):HorizontalAlignment =  3.
 END.
 ELSE DO:
     ChWorkSheet:range("A1:K1"):SELECT().
     ChWorksheet:range("A1:K1"):Merge.
     Chworksheet:Range("A1:K1"):HorizontalAlignment =  3.
 END.
 /* Colorir Titulo da Planilha */
 chWorkSheet:Range("A1:L1"):FONT:ColorIndex     = 18. /* Avermelhado */
 chWorkSheet:Range("A1:L1"):Interior:ColorIndex = 2. /* Branco */

 /* Configura a Linha do Titulo da Planilha */
 ASSIGN chWorkSheet:Rows("1:1"):RowHeight = 25
        chWorkSheet:Rows("2:2"):RowHeight =  4
        chWorkSheet:Rows("1:1"):FONT:SIZE = 12
        chWorkSheet:Rows("1:1"):FONT:bold = TRUE.

 CASE p-nr-plan.
     WHEN 1 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan,
                                 INPUT 6,      INPUT 25,          INPUT 20,              INPUT 20,              INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 13,              INPUT 13,              INPUT 8,         INPUT 6,
                                 INPUT "ITEM", INPUT "DESCRIÄ«O", INPUT "CLASSIFICAÄ«O", INPUT "2a CLASSIFIC.", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT "QTD DEVOLUÄ«O", INPUT "VLR DEVOLUÄ«O", INPUT "RENTAB.", INPUT " % ").

            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:E"):NumberFormat        = "@".
            ASSIGN chworksheet:range("F:J"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("E:L"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan,
                                  INPUT 6,      INPUT 25,          INPUT 20,              INPUT 20,              INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,   
                                  INPUT "ITEM", INPUT "DESCRIÄ«O", INPUT "CLASSIFICAÄ«O", INPUT "2a CLASSIFIC.", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:F"):NumberFormat        = "@".
             ASSIGN chworksheet:range("G:J"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("F:K"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
     WHEN 2 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan,
                                 INPUT 18,              INPUT 7,         INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,       INPUT 8,         INPUT 13,              INPUT 13,              INPUT 8,         INPUT 6,     INPUT 0,     INPUT 0,
                                 INPUT "REPRESENTANTE", INPUT "COD.REP", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR",  INPUT "P.MEDIO", INPUT "QTD DEVOLUÄ«O", INPUT "VLR DEVOLUÄ«O", INPUT "RENTAB.", INPUT " % ", INPUT "",    INPUT "").
            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:A"):NumberFormat        = "@"
                   chworksheet:range("B:B"):NumberFormat        = "###.###.##0"
                   Chworksheet:range("B:B"):HorizontalAlignment = 4 /* Alinhamento a Direita */
                   chworksheet:range("C:D"):NumberFormat        = "@"
                   chworksheet:range("E:K"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("E:K"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan,
                                  INPUT 18,              INPUT 7,         INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0, 
                                  INPUT "REPRESENTANTE", INPUT "COD.REP", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "", INPUT "", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:A"):NumberFormat        = "@"
                    chworksheet:range("B:B"):NumberFormat        = "###.###.##0"
                    Chworksheet:range("B:B"):HorizontalAlignment = 4 /* Alinhamento a Direita */
                    chworksheet:range("C:D"):NumberFormat        = "@"
                    chworksheet:range("E:J"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("E:J"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
     WHEN 3 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan,
                                 INPUT 25,              INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 13,              INPUT 13,              INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0,
                                 INPUT "GRUPO CLIENTE", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MêDIO", INPUT "QTD DEVOLUÄ«O", INPUT "VLR DEVOLUÄ«O", INPUT "RENTAB.", INPUT " % ", INPUT "", INPUT "", INPUT "").
            /* Configura as Colunas da Planilha */
            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:C"):NumberFormat        = "@"
                   chworksheet:range("D:J"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("D:J"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan,
                                  INPUT 25,              INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0,  INPUT 0, 
                                  INPUT "GRUPO CLIENTE", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "", INPUT "", INPUT "", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:C"):NumberFormat        = "@"
                    chworksheet:range("D:G"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("D:G"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
     WHEN 4 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan,
                                 INPUT 18,        INPUT 7,         INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 15,              INPUT 15,              INPUT 8,          INPUT 6,    INPUT 0,  INPUT 0,
                                 INPUT "CLIENTE", INPUT "COD.CLI", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT "QTD DEVOLUÄ«O", INPUT "VLR DEVOLUÄ«O", INPUT "RENTAB.", INPUT " % ", INPUT "", INPUT "").
            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:A"):NumberFormat        = "@"
                   chworksheet:range("B:B"):NumberFormat        = "###.###.##0"
                   Chworksheet:range("B:B"):HorizontalAlignment = 4 /* Alinhamento a Direita */
                   chworksheet:range("C:D"):NumberFormat        = "@"
                   chworksheet:range("E:K"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("E:K"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan,
                                  INPUT 18,        INPUT 7,         INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0, INPUT 0, 
                                  INPUT "CLIENTE", INPUT "COD.CLI", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "", INPUT "", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:A"):NumberFormat        = "@"
                    chworksheet:range("B:B"):NumberFormat        = "###.###.##0"
                    Chworksheet:range("B:B"):HorizontalAlignment = 4 /* Alinhamento a Direita */
                    chworksheet:range("C:D"):NumberFormat        = "@"
                    chworksheet:range("E:H"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("E:H"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
     WHEN 5 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan, 
                                 INPUT 18,       INPUT 3,    INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 8,         INPUT 6,     INPUT 0, INPUT 0,  INPUT 0,  INPUT 0,
                                 INPUT "REGI«O", INPUT "UF", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT "RENTAB.", INPUT " % ", INPUT "",INPUT "", INPUT "", INPUT "").
            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:D"):NumberFormat        = "@"
                   chworksheet:range("E:I"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("E:I"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan, 
                                  INPUT 18,       INPUT 3,    INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0, 
                                  INPUT "REGI«O", INPUT "UF", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "", INPUT "", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:D"):NumberFormat        = "@"
                    chworksheet:range("E:H"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("E:H"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
     WHEN 6 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan, 
                                 INPUT 18,         INPUT 8,          INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 10,           INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0,  INPUT 0,
                                 INPUT "NATUREZA", INPUT "ALIQUOTA", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT "VALOR ICMS", INPUT " % ", INPUT "", INPUT "", INPUT "", INPUT "").
            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:A"):NumberFormat        = "@"
                   chworksheet:range("B:B"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("B:B"):HorizontalAlignment = 4 /* Alinhamento a Direita */
                   chworksheet:range("C:D"):NumberFormat        = "@"
                   chworksheet:range("E:I"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("E:I"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan, 
                                  INPUT 18,         INPUT 8,          INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0, 
                                  INPUT "NATUREZA", INPUT "ALIQUOTA", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "", INPUT "", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:A"):NumberFormat        = "@"
                    chworksheet:range("B:B"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("B:B"):HorizontalAlignment = 4 /* Alinhamento a Direita */
                    chworksheet:range("C:D"):NumberFormat        = "@"
                    chworksheet:range("E:H"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("E:H"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
     WHEN 7 THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            RUN pi-coluna-excel (INPUT p-nr-plan,    
                                 INPUT 25,           INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0,  INPUT 0, INPUT 0,
                                 INPUT "VENCIMENTO", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT "RENTAB.", INPUT " % ", INPUT "", INPUT "", INPUT "", INPUT "", INPUT "").
            /* Configura as Colunas da Planilha */
            ASSIGN chworksheet:range("A:C"):NumberFormat        = "@"
                   chworksheet:range("D:H"):NumberFormat        = "###.###.##0,00"
                   Chworksheet:range("E:H"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
         ELSE DO:
             RUN pi-coluna-excel (INPUT p-nr-plan, 
                                  INPUT 25,           INPUT 4,      INPUT 3,     INPUT 12,           INPUT 12,      INPUT 8,         INPUT 6,     INPUT 0,  INPUT 0,  INPUT 0,  INPUT 0, 
                                  INPUT "VENCIMENTO", INPUT "LOTE", INPUT "UND", INPUT "QUANTIDADE", INPUT "VALOR", INPUT "P.MEDIO", INPUT " % ", INPUT "", INPUT "", INPUT "", INPUT "").
             /* Configura as Colunas da Planilha */
             ASSIGN chworksheet:range("A:C"):NumberFormat        = "@"
                    chworksheet:range("D:H"):NumberFormat        = "###.###.##0,00"
                    Chworksheet:range("E:G"):HorizontalAlignment = 4. /* Alinhamento a Direita */
         END.
     END.
 END CASE.


 /* Configura Cabeáalho das Colunas */
 chWorkSheet:Range("A3:L3"):SELECT().
 ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
        chExcelApp:SELECTION:FONT:SIZE               = 09
        chExcelApp:SELECTION:FONT:Bold               = TRUE 
        chExcelApp:SELECTION:Interior:ColorIndex     = 2
        chExcelApp:SELECTION:FONT:ColorIndex         = 11.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-clientes w-livre 
PROCEDURE pi-excel-clientes :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 RUN pi-excel-cabec (INPUT 4,
                    INPUT "Clientes").
 ASSIGN i-Lin    = 4.

 FOR EACH b-tt-work  WHERE                       
          b-tt-work.nome-abrev <> "" AND 
          b-tt-work.uf        <> "ZZ" NO-LOCK
    BREAK BY b-tt-work.nome-abrev 
          BY b-tt-work.lote
          BY b-tt-work.und.

     IF FIRST-OF(b-tt-work.nome-abrev) THEN
        ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.nome-abrev
               chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.cod-emit.

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

     ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
            chworksheet:Rows(c-lin):FONT:SIZE = 9.

     IF b-tt-work.uf <> "ZZ" THEN DO:
        ACCUMULATE b-tt-work.qtd (TOTAL).
        ACCUMULATE b-tt-work.vlr (TOTAL). 
        ACCUMULATE b-tt-work.vlr-devol (TOTAL). 
        ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.nome-abrev).
        ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.nome-abrev).
        ACCUMULATE b-tt-work.vlr-devol (TOTAL BY b-tt-work.nome-abrev).
     END.
     ASSIGN i-Lin = i-Lin + 1.
     IF LAST-OF(b-tt-work.nome-abrev) THEN DO:
        ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.nome-abrev b-tt-work.qtd)
               chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.nome-abrev b-tt-work.vlr)
               chworksheet:range("G" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.nome-abrev b-tt-work.vlr) / (ACCUM TOTAL BY b-tt-work.nome-abrev b-tt-work.qtd)
               chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.nome-abrev b-tt-work.vlr-devol).
        chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
        chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:Bold           = TRUE.
        ASSIGN i-lin = i-lin + 1.
     END.

 END.

 IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL"
            chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd)
            chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr)
            chworksheet:range("G" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr) / (ACCUM TOTAL b-tt-work.qtd)
            chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr-devol).

    chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):Interior:ColorIndex = 14.
    chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:ColorIndex     =  2.
    chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:Bold           = TRUE.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-grupos w-livre 
PROCEDURE pi-excel-grupos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 RUN pi-excel-cabec (INPUT 3,
                     INPUT "Grupos").
 ASSIGN i-Lin    = 4.

 FOR EACH b-tt-work  WHERE                       
          b-tt-work.matriz <> 0 AND 
          b-tt-work.uf        <> "ZZ" NO-LOCK
    BREAK BY b-tt-work.matriz 
          BY b-tt-work.lote
          BY b-tt-work.und.

     IF FIRST-OF(b-tt-work.matriz) THEN
        ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.matriz.

     ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.lote
            chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.und
            chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.qtd
            chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.vlr
            chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.
     IF i-tp-selecao = 2 THEN
        ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.qtd-devol
               chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.vlr-devol
               chworksheet:range("I" + STRING(i-lin)):VALUE = b-tt-work.rentabilidade
               chworksheet:range("J" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.
     ELSE
         ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.

     ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
            chworksheet:Rows(c-lin):FONT:SIZE = 9.

     IF b-tt-work.uf <> "ZZ" THEN DO:
        ACCUMULATE b-tt-work.qtd (TOTAL).
        ACCUMULATE b-tt-work.vlr (TOTAL). 
        ACCUMULATE b-tt-work.vlr-devol (TOTAL). 
        ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.matriz).
        ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.matriz).
        ACCUMULATE b-tt-work.vlr-devol (TOTAL BY b-tt-work.matriz).
     END.
     ASSIGN i-Lin = i-Lin + 1.
     IF LAST-OF(b-tt-work.matriz) THEN DO:
        ASSIGN chworksheet:range("D" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.matriz b-tt-work.qtd)
               chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.matriz b-tt-work.vlr)
               chworksheet:range("H" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.matriz b-tt-work.vlr-devol).
        chWorkSheet:Range("D" + STRING(i-lin) + ":H" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
        chWorkSheet:Range("D" + STRING(i-lin) + ":H" + STRING(i-lin)):FONT:Bold           = TRUE.
        ASSIGN i-lin = i-lin + 1.
     END.

 END.

 IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL"
            chworksheet:range("D" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd)
            chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr)
            chworksheet:range("H" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr-devol)

    chWorkSheet:Range("A" + STRING(i-lin) + ":H" + STRING(i-lin)):Interior:ColorIndex = 14.
    chWorkSheet:Range("A" + STRING(i-lin) + ":H" + STRING(i-lin)):FONT:ColorIndex     =  2.
    chWorkSheet:Range("A" + STRING(i-lin) + ":H" + STRING(i-lin)):FONT:Bold           = TRUE.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-item w-livre 
PROCEDURE pi-excel-item :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  
  RUN pi-excel-cabec (INPUT 1,
                      INPUT "Item").
                      
  ASSIGN i-Lin    = 4.
  
  FOR EACH b-tt-work  WHERE                       
           b-tt-work.it-codigo <> "" AND 
           b-tt-work.uf        <> "ZZ" NO-LOCK
     BREAK BY b-tt-work.it-codigo 
           BY b-tt-work.lote
           BY b-tt-work.und.
      
      IF FIRST-OF(b-tt-work.it-codigo) THEN
         ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.it-codigo
                chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.desc-item
                chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.classif
                chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.acabamento.

      ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.lote
             chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.und
             chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.qtd
             chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.vlr
             chworksheet:range("I" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.

      ASSIGN chworksheet:range("J" + STRING(i-lin)):VALUE = b-tt-work.qtd-devol
             chworksheet:range("K" + STRING(i-lin)):VALUE = b-tt-work.vlr-devol
             chworksheet:range("L" + STRING(i-lin)):VALUE = b-tt-work.rentabilidade
             chworksheet:range("M" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.

      ASSIGN chworksheet:range("N" + STRING(i-lin)):VALUE = b-tt-work.no-ab-reppri.

      /*  Configura Tamanho da Fonte */
      ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
             chworksheet:Rows(c-lin):FONT:SIZE = 9.

      IF b-tt-work.uf <> "ZZ" THEN DO:
         ACCUMULATE b-tt-work.qtd (TOTAL).
         ACCUMULATE b-tt-work.vlr (TOTAL).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL).
         ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.it-codigo).
         ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.it-codigo).
         ACCUMULATE b-tt-work.qtd-devol (TOTAL BY b-tt-work.it-codigo).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL BY b-tt-work.it-codigo).
      END.
      ASSIGN i-Lin = i-Lin + 1.
      IF LAST-OF(b-tt-work.it-codigo) THEN DO:
         
         ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo  b-tt-work.qtd)
                chworksheet:range("H" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo b-tt-work.vlr)
                chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo b-tt-work.vlr) / (ACCUM TOTAL BY b-tt-work.it-codigo  b-tt-work.qtd)
                chworksheet:range("J" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo b-tt-work.qtd-devol)
                chworksheet:range("K" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.it-codigo b-tt-work.vlr-devol).
         /* Colorir a Linha / Negrito */
         chWorkSheet:Range("G" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
         chWorkSheet:Range("G" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:Bold           = TRUE.
         ASSIGN i-lin = i-lin + 1.
         
      END.
  END.
  
  IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL"
            chworksheet:range("G" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd)
            chworksheet:range("H" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr)
            chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr) / (ACCUM TOTAL b-tt-work.qtd)
            chworksheet:range("J" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd-devol)
            chworksheet:range("K" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr-devol).

      /* Colorir a Linha / Negrito */
     chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):Interior:ColorIndex = 14.
     chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:ColorIndex     =  2.
     chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:Bold           = TRUE.
  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-natureza w-livre 
PROCEDURE pi-excel-natureza :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 RUN pi-excel-cabec (INPUT 6,
                     INPUT "Natureza").
 ASSIGN i-Lin    = 4.

 FOR EACH b-tt-work  WHERE                       
          b-tt-work.nat-operacao <> "" AND 
          b-tt-work.uf        <> "ZZ" NO-LOCK
    BREAK BY b-tt-work.nat-operacao 
          BY b-tt-work.lote
          BY b-tt-work.und.

     IF FIRST-OF(b-tt-work.nat-operacao) THEN
        ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.nat-operacao.

     ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.aliq-icms
            chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.lote
            chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.und
            chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.qtd
            chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.vlr
            chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.
     IF i-tp-selecao = 2 THEN
        ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.vl-icms
               chworksheet:range("I" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.
     ELSE
         ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.

     ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
            chworksheet:Rows(c-lin):FONT:SIZE = 9.

     IF b-tt-work.uf <> "ZZ" THEN DO:
        ACCUMULATE b-tt-work.qtd (TOTAL).
        ACCUMULATE b-tt-work.vlr (TOTAL). 
        ACCUMULATE b-tt-work.vl-icms (TOTAL).
        ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.nat-operacao).
        ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.nat-operacao).
     END.
     ASSIGN i-Lin = i-Lin + 1.
     IF LAST-OF(b-tt-work.nat-operacao) THEN DO:
        ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.nat-operacao b-tt-work.qtd).
        ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.nat-operacao b-tt-work.vlr).
        chWorkSheet:Range("E" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
        chWorkSheet:Range("E" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:Bold           = TRUE.
        ASSIGN i-lin = i-lin + 1.
     END.

 END.

 IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL".
     ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd).
     ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr).
     ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vl-icms).
    chWorkSheet:Range("A" + STRING(i-lin) + ":I" + STRING(i-lin)):Interior:ColorIndex = 14.
    chWorkSheet:Range("A" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:ColorIndex     =  2.
    chWorkSheet:Range("A" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:Bold           = TRUE.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-regiao w-livre 
PROCEDURE pi-excel-regiao :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 RUN pi-excel-cabec (INPUT 5,
                     INPUT "Regiao").

 ASSIGN i-Lin = 4.

 FOR EACH b-tt-work  WHERE                       
          b-tt-work.regiao <> "" AND 
          b-tt-work.uf        <> "ZZ" NO-LOCK
    BREAK BY b-tt-work.regiao 
          BY b-tt-work.uf
          BY b-tt-work.lote
          BY b-tt-work.und.

     IF FIRST-OF(b-tt-work.regiao) THEN
        ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.regiao.

     ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.uf
            chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.lote
            chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.und
            chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.qtd
            chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.vlr
            chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.preco-medio.
     IF i-tp-selecao = 2 THEN
        ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.rentabilidade
               chworksheet:range("I" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.
     ELSE
         ASSIGN chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.

     ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
            chworksheet:Rows(c-lin):FONT:SIZE = 9.

     IF b-tt-work.uf <> "ZZ" THEN DO:
        ACCUMULATE b-tt-work.qtd (TOTAL).
        ACCUMULATE b-tt-work.vlr (TOTAL). 
        ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.regiao).
        ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.regiao).
     END.
     ASSIGN i-Lin = i-Lin + 1.
     IF LAST-OF(b-tt-work.regiao) THEN DO:
        ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.regiao b-tt-work.qtd).
        ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.regiao b-tt-work.vlr).
        ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.regiao b-tt-work.vlr) / (ACCUM TOTAL BY b-tt-work.regiao b-tt-work.qtd).           

        chWorkSheet:Range("E" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
        chWorkSheet:Range("E" + STRING(i-lin) + ":F" + STRING(i-lin)):FONT:Bold           = TRUE.
        ASSIGN i-lin = i-lin + 1.
     END.

 END.

 IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL".
     ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd).
     ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr).
     ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr) / (ACCUM TOTAL b-tt-work.qtd).

     chWorkSheet:Range("A" + STRING(i-lin) + ":I" + STRING(i-lin)):Interior:ColorIndex = 14.
     chWorkSheet:Range("A" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:ColorIndex     =  2.
     chWorkSheet:Range("A" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:Bold           = TRUE.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-repres w-livre 
PROCEDURE pi-excel-repres :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  RUN pi-excel-cabec (INPUT 2,
                      INPUT "Representante").
  ASSIGN i-Lin    = 4.

  FOR EACH b-tt-work  WHERE                       
           b-tt-work.no-ab-reppri <> "" AND 
           b-tt-work.uf        <> "ZZ" NO-LOCK
     BREAK BY b-tt-work.no-ab-reppri 
           BY b-tt-work.lote
           BY b-tt-work.und.
      
      IF FIRST-OF(b-tt-work.no-ab-reppri) THEN
         ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.no-ab-reppri
                chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.cod-rep.

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

      ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
             chworksheet:Rows(c-lin):FONT:SIZE = 9.

      IF b-tt-work.uf <> "ZZ" THEN DO:
         ACCUMULATE b-tt-work.qtd (TOTAL).
         ACCUMULATE b-tt-work.vlr (TOTAL). 
         ACCUMULATE b-tt-work.vlr-devol (TOTAL). 
         ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.no-ab-reppri).
         ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.no-ab-reppri).
         ACCUMULATE b-tt-work.vlr-devol (TOTAL BY b-tt-work.no-ab-reppri).
      END.
      ASSIGN i-Lin = i-Lin + 1.
      IF LAST-OF(b-tt-work.no-ab-reppri) THEN DO:
         ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.no-ab-reppri b-tt-work.qtd)
                chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.no-ab-reppri b-tt-work.vlr)
                chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.no-ab-reppri b-tt-work.vlr-devol).
         chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
         chWorkSheet:Range("E" + STRING(i-lin) + ":I" + STRING(i-lin)):FONT:Bold           = TRUE.
         ASSIGN i-lin = i-lin + 1.
      END.
  END.
  IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
      ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL"
             chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd)
             chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr)
             chworksheet:range("I" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr-devol).
     chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):Interior:ColorIndex = 14.
     chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:ColorIndex     =  2.
     chWorkSheet:Range("A" + STRING(i-lin) + ":K" + STRING(i-lin)):FONT:Bold           = TRUE.
  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-excel-vencto w-livre 
PROCEDURE pi-excel-vencto :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 RUN pi-excel-cabec (INPUT 7,
                     INPUT "Vencimento").
 ASSIGN i-Lin    = 4.

 FOR EACH b-tt-work  WHERE                       
          b-tt-work.cond-pagto <> "" AND 
          b-tt-work.uf        <> "ZZ" NO-LOCK
    BREAK BY b-tt-work.cond-pagto 
          BY b-tt-work.lote
          BY b-tt-work.und.

     IF FIRST-OF(b-tt-work.cond-pagto) THEN
        ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = b-tt-work.cond-pagto.

     ASSIGN chworksheet:range("B" + STRING(i-lin)):VALUE = b-tt-work.lote
            chworksheet:range("C" + STRING(i-lin)):VALUE = b-tt-work.und
            chworksheet:range("D" + STRING(i-lin)):VALUE = b-tt-work.qtd
            chworksheet:range("E" + STRING(i-lin)):VALUE = b-tt-work.vlr
            chworksheet:range("F" + STRING(i-lin)):VALUE = b-tt-work.preco-medio. 
     IF i-tp-selecao = 2 THEN
        ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.rentabilidade
               chworksheet:range("H" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.
     ELSE
         ASSIGN chworksheet:range("G" + STRING(i-lin)):VALUE = b-tt-work.perc-sobr-total.

     ASSIGN c-lin = STRING(i-lin) + ":" + STRING(i-lin)
            chworksheet:Rows(c-lin):FONT:SIZE = 9.

     IF b-tt-work.uf <> "ZZ" THEN DO:
        ACCUMULATE b-tt-work.qtd (TOTAL).
        ACCUMULATE b-tt-work.vlr (TOTAL). 
        ACCUMULATE b-tt-work.qtd (TOTAL BY b-tt-work.cond-pagto).
        ACCUMULATE b-tt-work.vlr (TOTAL BY b-tt-work.cond-pagto).
     END.
     ASSIGN i-Lin = i-Lin + 1.
     IF LAST-OF(b-tt-work.cond-pagto) THEN DO:
        ASSIGN chworksheet:range("D" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.cond-pagto b-tt-work.qtd).
        ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.cond-pagto b-tt-work.vlr).
        ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL BY b-tt-work.cond-pagto b-tt-work.vlr) / (ACCUM TOTAL BY b-tt-work.cond-pagto b-tt-work.qtd).

        chWorkSheet:Range("D" + STRING(i-lin) + ":E" + STRING(i-lin)):FONT:ColorIndex     = 3. /* Red */
        chWorkSheet:Range("D" + STRING(i-lin) + ":E" + STRING(i-lin)):FONT:Bold           = TRUE.
        ASSIGN i-lin = i-lin + 1.
     END.

 END.

 IF (ACCUM TOTAL b-tt-work.qtd) <> 0 THEN DO:
     ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = "TOTAL GERAL".
     ASSIGN chworksheet:range("D" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.qtd).
     ASSIGN chworksheet:range("E" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr).
     ASSIGN chworksheet:range("F" + STRING(i-lin)):VALUE = (ACCUM TOTAL b-tt-work.vlr) / (ACCUM TOTAL b-tt-work.qtd).

     chWorkSheet:Range("A" + STRING(i-lin) + ":H" + STRING(i-lin)):Interior:ColorIndex = 14.
     chWorkSheet:Range("A" + STRING(i-lin) + ":H" + STRING(i-lin)):FONT:ColorIndex     =  2.
     chWorkSheet:Range("A" + STRING(i-lin) + ":H" + STRING(i-lin)):FONT:Bold           = TRUE.
 END.
 

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-faturados w-livre 
PROCEDURE pi-faturados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 ASSIGN i-tot-etq = 0.
 FOR EACH nota-fiscal USE-INDEX ch-distancia WHERE
          nota-fiscal.cod-estabel  >= c-cod-estabel-ini AND
          nota-fiscal.cod-estabel  <= c-cod-estabel-fin AND
          nota-fiscal.dt-emis-nota >= da-dt-implant-ini AND 
          nota-fiscal.dt-emis-nota <= da-dt-implant-fin AND
          nota-fiscal.dt-cancela    = ? NO-LOCK. 

     RUN pi-acompanhar IN h-acomp (INPUT "Data: "    + STRING(nota-fiscal.dt-emis-nota) +
                                         " NF: " + nota-fiscal.nr-nota-fis).

     IF nota-fiscal.idi-sit-nf-eletro = 4 THEN NEXT.  // uso denegado
     
     FIND ped-venda WHERE
          ped-venda.nr-pedcli  = nota-fiscal.nr-pedcli  AND
          ped-venda.nome-abrev = nota-fiscal.nome-ab-cl NO-LOCK NO-ERROR.
     
     FIND ped-venda-ext WHERE
          ped-venda-ext.cod-estabel = ped-venda.cod-estabel AND
          ped-venda-ext.nr-pedido = ped-venda.nr-pedido NO-LOCK NO-ERROR.

     IF c-tp-pedido <> 'Todos' THEN DO.
        IF NOT AVAIL ped-venda-ext OR
           ped-venda-ext.tp-pedido <> c-tp-pedido THEN NEXT.
     END.

     IF AVAIL ped-venda-ext THEN DO.
        IF i-tb_preco_id <> 9 AND
           ped-venda-ext.tb_preco_id <> i-tb_preco_id THEN NEXT.
     END.

     FIND natur-oper WHERE
          natur-oper.nat-operacao = nota-fiscal.nat-operacao NO-LOCK NO-ERROR.
     IF NOT AVAIL natur-oper THEN NEXT.
     IF natur-oper.tipo = 1 THEN NEXT. /* Movto de Entr */

     IF l-faturamento OR l-pilotagem THEN DO.
        IF natur-oper.cod-esp <> "DP" THEN NEXT. /* Ped. que Geraram Dupl */
        IF NOT AVAIL ped-venda THEN NEXT. 
     END.

     IF l-outros-fat AND natur-oper.cod-esp = "DP" THEN NEXT. /* Ped. que Geraram Dupl */

     IF l-faturamento = YES OR l-pilotagem THEN DO:
        FIND estabelec WHERE
             estabelec.cgc = nota-fiscal.cgc NO-LOCK NO-ERROR.
        IF AVAIL estabelec THEN NEXT.
     END.

     IF l-entre-estab = YES THEN DO:
        FIND estabelec WHERE
             estabelec.cgc = nota-fiscal.cgc NO-LOCK NO-ERROR.
        IF NOT AVAIL estabelec THEN NEXT.
     END.

     IF nota-fiscal.nome-abrev-tri <> "" AND 
        nota-fiscal.nome-abrev-tri = nota-fiscal.nome-ab-cli THEN NEXT. /* Nota fiscal Triangular */

     IF nota-fiscal.nr-pedcli <> "" THEN DO:
        IF ped-venda.nr-pedcli < c-nr-pedcli-ini OR
           ped-venda.nr-pedcli > c-nr-pedcli-fin  THEN NEXT.
        RUN pi-ver-digita (INPUT "Pedido_de_Venda",                                                             
                           INPUT ped-venda.nr-pedcli).                                                          
        IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.                                                                
     END.

     IF nota-fiscal.nome-ab-cli  < c-nome-abrev-ini OR
        nota-fiscal.nome-ab-cli  > c-nome-abrev-fin  THEN NEXT.
     RUN pi-ver-digita (INPUT "Cliente",
                        INPUT nota-fiscal.nome-ab-cli).
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

     IF nota-fiscal.no-ab-reppri < c-no-ab-reppri-ini OR
        nota-fiscal.no-ab-reppri > c-no-ab-reppri-fin THEN NEXT.
     RUN pi-ver-digita (INPUT "Representante",
                        INPUT nota-fiscal.no-ab-reppri).
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

     FIND emitente WHERE
          emitente.nome-abrev = nota-fiscal.nome-ab-cli NO-LOCK NO-ERROR.
     IF emitente.nome-matriz < c-matriz-ini OR
        emitente.nome-matriz > c-matriz-fin THEN NEXT.

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

     ASSIGN i-ct         = 0
            c-cond-pagto = ""
            i-cod-vencto = 0
            i-prz        = 0.

     FOR EACH fat-duplic WHERE
              fat-duplic.cod-estabel = nota-fiscal.cod-estabel AND
              fat-duplic.serie       = nota-fiscal.serie       AND
              fat-duplic.nr-fatura   = nota-fiscal.nr-nota-fis NO-LOCK.
              ASSIGN i-prz        = i-prz + (fat-duplic.dt-vencimen - fat-duplic.dt-emissao)
                     i-ct         = i-ct + 1
                     i-cod-vencto = fat-duplic.cod-vencto.
     END.
     IF i-prz <> 0 OR i-cod-vencto = 2 OR i-cod-vencto = 9 THEN DO: 
        IF i-cod-vencto = 2 THEN
           ASSIGN c-cond-pagto = " A Vista".
        ELSE
        IF i-cod-vencto = 9 THEN
           ASSIGN c-cond-pagto = " Contra Apresentaá∆o".
        ELSE DO:
           i-prz = INT(i-prz / i-ct).
           IF i-prz <= 30 THEN
              ASSIGN c-cond-pagto = " De 01 AtÇ 30 Dias".
           ELSE
           IF i-prz <= 60 THEN
              ASSIGN c-cond-pagto = " De 31 AtÇ 60 Dias".
           ELSE
           IF i-prz <= 90 THEN
              ASSIGN c-cond-pagto = " De 61 AtÇ 90 Dias".
           ELSE
              ASSIGN c-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Pos ALT 164 */
        END.
     END.
     ELSE DO:
        FIND cond-pagto WHERE
             cond-pagto.cod-cond-pag = nota-fiscal.cod-cond-pag NO-LOCK NO-ERROR.
        IF AVAIL cond-pagto THEN DO:
           ASSIGN c-cond-pagto = cond-pagto.descricao.
           IF cond-pagto.log-2 THEN /* Fat VENDOR */
              ASSIGN c-cond-pagto = "ˇVendor". /* 1¶ Pos ALT 164 */
        END.
     END.
     IF c-cond-pagto = "" THEN DO:
         IF l-outros-fat THEN
            ASSIGN c-cond-pagto = "Outros Faturamento".
         ELSE
            ASSIGN c-cond-pagto = " Cupom Fiscal".
     END.
     IF c-regiao = "Exportaá∆o" THEN
        ASSIGN c-cond-pagto = "ˇExportaá∆o". /* 1¶ Pos ALT 164 */

     ASSIGN de-qtd   = 0
            de-desc  = 0
            de-vlr   = 0.

     FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.

         IF l-lote-todos = NO THEN DO:
            IF l-lote-rp = YES AND it-nota-fisc.cod-refer = '888' THEN NEXT. 
            IF l-lote-rd = YES AND it-nota-fisc.cod-refer <> '888' THEN NEXT.
         END.

         FIND item WHERE
              item.it-codigo = it-nota-fisc.it-codigo NO-LOCK NO-ERROR.
         IF NOT AVAIL ITEM THEN NEXT.

         IF (c-tipo-mercado = "0" AND item.codigo-orig <> 0) OR
            (c-tipo-mercado = "1" AND item.codigo-orig <> 1) OR
            (c-tipo-mercado = "2" AND item.codigo-orig <> 2) THEN NEXT.
         
         FIND ped-item-ext WHERE
              ped-item-ext.cod-estabel = ped-venda.cod-estabel AND
              ped-item-ext.nr-pedcli = ped-venda.nr-pedcli AND
              ped-item-ext.nome-abrev = ped-venda.nome-abrev AND
              ped-item-ext.nr-sequencia = it-nota-fisc.nr-seq-ped NO-LOCK NO-ERROR.

         IF AVAIL ped-item-ext THEN DO.
             IF NOT l-faturamento AND l-pilotagem AND
                NOT ped-item-ext.retirar-corte THEN NEXT.
    
             IF l-faturamento AND NOT l-pilotagem AND 
                ped-item-ext.retirar-corte THEN NEXT.
         END.
         /* Tecido Cru N∆o Tem Referencia */
         IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
            (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.

         IF NOT l-outros-fat AND 
            (it-nota-fisc.it-codigo < c-it-codigo-ini) OR 
            (it-nota-fisc.it-codigo > c-it-codigo-fin)  THEN NEXT.
         RUN pi-ver-digita (INPUT "Item",
                            INPUT it-nota-fisc.it-codigo).
         IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

         IF nota-fiscal.nr-pedcli <> "" THEN DO:
             IF it-nota-fisc.cod-refer < c-cod-refer-ini OR  
                it-nota-fisc.cod-refer > c-cod-refer-fin THEN NEXT.
            RUN pi-ver-digita (INPUT "Referància",
                               INPUT it-nota-fisc.cod-refer).
            IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

            IF i-outlet <> 3 THEN DO.
               RUN pi-ver-liquida (INPUT "F").
               IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.
            END.

            IF c-tipo-acabamento = "E" AND SUBSTR(it-nota-fisc.it-codigo,3,1) <> '0' THEN NEXT.
            IF c-tipo-acabamento = "L" AND SUBSTR(it-nota-fisc.it-codigo,3,1)  = '0' THEN NEXT.
            

            ASSIGN c-lote-refer = "1¶Q".  
            IF it-nota-fisc.cod-refer = '888' THEN
               ASSIGN c-lote-refer = "2¶Q".

            ASSIGN de-vlr-custo = 0.
            FIND pr-it-per WHERE                                    
                 pr-it-per.it-codigo   = it-nota-fisc.it-codigo AND 
                 pr-it-per.cod-estabel = nota-fiscal.cod-estabel AND
                 pr-it-per.periodo     = da-dt-implant-fin  NO-LOCK NO-ERROR.
            IF NOT AVAIL pr-it-per THEN
               FIND FIRST pr-it-per WHERE
                          pr-it-per.it-codigo   = it-nota-fisc.it-codigo AND  
                          pr-it-per.cod-estabel = nota-fiscal.cod-estabel  NO-LOCK NO-ERROR.
            IF AVAIL pr-it-per THEN
               ASSIGN de-vlr-custo = pr-it-per.val-unit-ggf-m[1] +  
                                     pr-it-per.val-unit-mat-m[1] + 
                                     pr-it-per.val-unit-mob-m[1].  

            RUN pi-grava-movto (INPUT "1",
                                INPUT it-nota-fisc.it-codigo,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT item.desc-item,
                                INPUT it-nota-fisc.qt-faturada[1],
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-pedcli).

            FIND repres WHERE
                 repres.nome-abrev = nota-fiscal.no-ab-reppri NO-LOCK NO-ERROR.
            IF NOT AVAIL repres THEN
               FIND repres WHERE
                    repres.cod-rep = 1 NO-LOCK NO-ERROR.

            RUN pi-grava-movto (INPUT "2",
                                INPUT repres.nome-abrev,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT repres.cod-rep,
                                INPUT it-nota-fisc.qt-faturada[1],
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-pedcli).  


            RUN pi-grava-movto (INPUT "4",
                                INPUT nota-fiscal.nome-ab-cli,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT STRING(emitente.cod-emitente),
                                INPUT it-nota-fisc.qt-faturada[1],  
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-pedcli).    

            RUN pi-grava-movto (INPUT "5",
                                INPUT c-regiao,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT emitente.estado,
                                INPUT it-nota-fisc.qt-faturada[1],  
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-pedcli).

            RUN pi-grava-movto (INPUT "7",
                                INPUT c-cond-pagto,
                                INPUT ITEM.un,
                                INPUT c-lote-refer,
                                INPUT "",
                                INPUT it-nota-fisc.qt-faturada[1],
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-pedcli).

         END.
         ELSE DO:
            RUN pi-grava-movto (INPUT "1",
                                INPUT it-nota-fisc.it-codigo,
                                INPUT ITEM.un,
                                INPUT "",
                                INPUT item.desc-item,
                                INPUT it-nota-fisc.qt-faturada[1],
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-nota-fis).

            FIND repres WHERE
                 repres.nome-abrev = nota-fiscal.no-ab-reppri NO-LOCK NO-ERROR.
            IF NOT AVAIL repres THEN
               FIND repres WHERE
                    repres.cod-rep = 1 NO-LOCK NO-ERROR.

            RUN pi-grava-movto (INPUT "2",
                                INPUT repres.nome-abrev,
                                INPUT ITEM.un,
                                INPUT "",
                                INPUT repres.cod-rep,
                                INPUT it-nota-fisc.qt-faturada[1],
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-nota-fis).  

            RUN pi-grava-movto (INPUT "4",
                                INPUT nota-fiscal.nome-ab-cli,
                                INPUT ITEM.un,
                                INPUT "",
                                INPUT STRING(emitente.cod-emitente),
                                INPUT it-nota-fisc.qt-faturada[1],  
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-nota-fis).    

            RUN pi-grava-movto (INPUT "5",
                                INPUT c-regiao,
                                INPUT ITEM.un,
                                INPUT "",
                                INPUT emitente.estado,
                                INPUT it-nota-fisc.qt-faturada[1],  
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-nota-fis).

            RUN pi-grava-movto (INPUT "7",
                                INPUT c-cond-pagto,
                                INPUT ITEM.un,
                                INPUT "",
                                INPUT "",
                                INPUT it-nota-fisc.qt-faturada[1],
                                INPUT it-nota-fisc.vl-tot-item + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)),
                                INPUT nota-fiscal.nr-nota-fis).
         END.
         ASSIGN de-qtd       = de-qtd  + it-nota-fisc.qt-faturada[1]
                de-vlr       = de-vlr  + it-nota-fisc.vl-tot-item  
                de-desc      = de-desc + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10))
                de-vlr-custo = 0.
     END.
     IF de-vlr > 0 THEN DO:
        FIND tt-pedidos WHERE
             tt-pedidos.cod-estabel = nota-fiscal.cod-estabel AND
             tt-pedidos.serie       = nota-fiscal.cod-estabel AND
             tt-pedidos.nr-nota-fis = nota-fiscal.nr-nota-fis NO-LOCK NO-ERROR.
        IF NOT AVAIL tt-pedidos THEN DO:
           CREATE tt-pedidos.
           ASSIGN tt-pedidos.cod-estabel = nota-fiscal.cod-estabel
                  tt-pedidos.serie       = nota-fiscal.serie
                  tt-pedidos.nr-nota-fis = nota-fiscal.nr-nota-fis
                  tt-pedidos.qt-faturada = de-qtd
                  tt-pedidos.desc-pratic = de-desc
                  tt-pedidos.vl-tot-item = de-vlr.
           IF c-regiao = "Exportaá∆o" THEN
              ASSIGN tt-pedidos.exportacao = YES.
        END.
        RUN pi-tot-etq.
     END.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-gera-excel w-livre 
PROCEDURE pi-gera-excel :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    
  RUN pi-abre-excel.
  IF chExcelApp = ? THEN DO:
     MESSAGE "O Aplicativo EXCEL n∆o foi encontrado. N∆o Ç possivel a execuá∆o do programa."
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     ASSIGN arq-saida = "".
     RETURN.
  END.

  RUN pi-monta-planilha.

  /* Posiciona o Foco no Inicio da Planilha */
  chExcelApp:Range("A1"):SELECT.
  chExcelApp:Range("A:A"):EntireColumn:AutoFit.

  /* Posiciona na Planilha 1, Salva e Fecha */
  chWorkSheet = chExcelapp:Sheets:ITEM(1).
  chWorkbook:Worksheets(1):activate.

 /* ASSIGN arq-saida = "C:\TEMP\LIXO.XLS". */

  /* Salva e Fecha Planilha */
  OS-DELETE VALUE(arq-saida).

  /* chWorkBook:SaveAs(arq-saida,39,,,,,,,TRUE). /* Salva em formato mais Antigo EXCEL97 */ */
  chWorkBook:SaveAs(arq-saida,,,,,,,).  /* Salva na Vers∆o da planilha da ESTAÄ«O */
  chWorkBook:CLOSE().
  chExcelApp:QUIT().
  RELEASE OBJECT chExcelApp. 
  RELEASE OBJECT chworkBook.
  RELEASE OBJECT chworksheet.
    


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grafico-qtd w-livre 
PROCEDURE pi-grafico-qtd :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 DEF VAR i-point   AS INT INITIAL 1.
 DEF VAR i-numsets AS INT.
 DEF VAR de-work   AS DEC.

 EMPTY TEMP-TABLE tt-atributos.
 EMPTY TEMP-TABLE tt-sets.
 EMPTY TEMP-TABLE tt-points-2.
 EMPTY TEMP-TABLE tt-dados.
 EMPTY TEMP-TABLE tt-erros.

 /* Configuraá∆o Geral do Grafico */
 CREATE tt-atributos.
 ASSIGN tt-atributos.cod-versao-integracao = 3
        tt-atributos.graphtype             = 3
        tt-atributos.graphtitle            = c-Titulo 
        tt-atributos.lefttitle             = 'Quantidade em METROS.'
        tt-atributos.lefttitlestyle        = 2
        tt-atributos.bottomtitle           = fn-tipo-grafico()
        tt-atributos.numgraph              = 1.

 CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
     WHEN '1' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "ITENS".

         FOR EACH b-tt-work WHERE
                  b-tt-work.it-codigo <> ""   AND
                  b-tt-work.uf        <> "ZZ" 
             BREAK BY b-tt-work.it-codigo
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.it-codigo) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.it-codigo.

                /* Valores do EIXO Y (QUANTIDADE) */
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
     END.
     WHEN '2' THEN DO: 
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "REPRESENTANTES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.no-ab-reppri <> ""   AND
                  b-tt-work.uf           <> "ZZ" 
             BREAK BY b-tt-work.no-ab-reppri
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.no-ab-reppri) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.no-ab-reppri.

                /* Valores do EIXO Y (QUANTIDADE) */
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
     END.
     WHEN '3' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "GRUPOS DE CLIENTES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.matriz <> 0   AND
                  b-tt-work.uf     <> "ZZ" 
             BREAK BY b-tt-work.matriz
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.matriz) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = STRING(b-tt-work.matriz).

                /* Valores do EIXO Y (QUANTIDADE) */
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
     END.
     WHEN '4' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "CLIENTES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.nome-abrev <> ""   AND
                  b-tt-work.uf         <> "ZZ" 
             BREAK BY b-tt-work.nome-abrev
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.nome-abrev) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.nome-abrev.

                /* Valores do EIXO Y (QUANTIDADE) */
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
     END.
     WHEN '5' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "REGIÂES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.regiao <> ""   AND
                  b-tt-work.uf     <> "ZZ" 
             BREAK BY b-tt-work.regiao
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.regiao) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.regiao.

                /* Valores do EIXO Y (QUANTIDADE) */
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

     END.
     WHEN '6' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "NATUREZA DA OPERAÄ«O".

         FOR EACH b-tt-work WHERE
                  b-tt-work.nat-operacao <> ""   AND
                  b-tt-work.uf           <> "ZZ" 
             BREAK BY b-tt-work.nat-operacao
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.nat-operacao) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.nat-operacao.

                /* Valores do EIXO Y (QUANTIDADE) */
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
     END.
     WHEN '7' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "CONDIÄÂES DE PAGAMENTO".

         FOR EACH b-tt-work WHERE
                  b-tt-work.cond-pagto <> ""   AND
                  b-tt-work.uf         <> "ZZ" 
             BREAK BY b-tt-work.cond-pagto
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.qtd.

             IF LAST-OF(b-tt-work.cond-pagto) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.cond-pagto.

                /* Valores do EIXO Y (QUANTIDADE) */
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

     END.
 END CASE.

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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grafico-vlr w-livre 
PROCEDURE pi-grafico-vlr :
/*---------------------------------------------------F---------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF VAR i-point   AS INT INITIAL 1.
 DEF VAR i-numsets AS INT.
 DEF VAR de-work   AS DEC.

 EMPTY TEMP-TABLE tt-atributos.
 EMPTY TEMP-TABLE tt-sets.
 EMPTY TEMP-TABLE tt-points-2.
 EMPTY TEMP-TABLE tt-dados.
 EMPTY TEMP-TABLE tt-erros.

 /* Configuraá∆o Geral do Grafico */
 CREATE tt-atributos.
 ASSIGN tt-atributos.cod-versao-integracao = 3
        tt-atributos.graphtype             = 3
        tt-atributos.graphtitle            = c-Titulo 
        tt-atributos.lefttitle             = 'Valores em Real (R$).'
        tt-atributos.lefttitlestyle        = 1
        tt-atributos.bottomtitle           = fn-tipo-grafico()
        tt-atributos.numgraph              = 1.

 CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
     WHEN '1' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "ITENS".

         FOR EACH b-tt-work WHERE
                  b-tt-work.it-codigo <> ""   AND
                  b-tt-work.uf        <> "ZZ" AND
                  b-tt-work.und        = "M"
             BREAK BY b-tt-work.it-codigo
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.it-codigo) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.it-codigo.

                /* Valores do EIXO Y (Valor) */
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
     END.
     WHEN '2' THEN DO: 
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "REPRESENTANTES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.no-ab-reppri <> ""   AND
                  b-tt-work.uf           <> "ZZ" AND
                  b-tt-work.und           = "M"
             BREAK BY b-tt-work.no-ab-reppri
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.no-ab-reppri) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.no-ab-reppri.

                /* Valores do EIXO Y (Valor) */
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
     END.
     WHEN '3' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "GRUPOS DE CLIENTES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.matriz <> 0   AND
                  b-tt-work.uf     <> "ZZ" AND
                  b-tt-work.und     = "M"
             BREAK BY b-tt-work.matriz
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.matriz) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = STRING(b-tt-work.matriz).

                /* Valores do EIXO Y (Valor) */
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
     END.
     WHEN '4' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "CLIENTES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.nome-abrev <> ""   AND
                  b-tt-work.uf         <> "ZZ" AND
                  b-tt-work.und         = "M"
             BREAK BY b-tt-work.nome-abrev
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.nome-abrev) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.nome-abrev.

                /* Valores do EIXO Y (Valor) */
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
     END.
     WHEN '5' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "REGIÂES".

         FOR EACH b-tt-work WHERE
                  b-tt-work.regiao <> ""   AND
                  b-tt-work.uf     <> "ZZ" AND
                  b-tt-work.und     = "M"
             BREAK BY b-tt-work.regiao
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.regiao) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.regiao.

                /* Valores do EIXO Y (Valor) */
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

     END.
     WHEN '6' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "NATUREZA DA OPERAÄ«O".

         FOR EACH b-tt-work WHERE
                  b-tt-work.nat-operacao <> ""   AND
                  b-tt-work.uf           <> "ZZ" AND
                  b-tt-work.und           = "M"
             BREAK BY b-tt-work.nat-operacao
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.nat-operacao) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.nat-operacao.

                /* Valores do EIXO Y (Valor) */
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
     END.
     WHEN '7' THEN DO:
         /* Configuraá∆o das Variantes do Grafico */
         ASSIGN i-numsets = 1.
         CREATE tt-sets.
         ASSIGN tt-sets.NumSet     = i-numsets 
                tt-sets.NumGraph   = 1
                tt-sets.ColorSet   = 1
                tt-sets.legendText = "CONDIÄÂES DE PAGAMENTO".

         FOR EACH b-tt-work WHERE
                  b-tt-work.cond-pagto <> ""   AND
                  b-tt-work.uf         <> "ZZ" AND
                  b-tt-work.und         = "M"
             BREAK BY b-tt-work.cond-pagto
                   BY b-tt-work.uf
                   BY b-tt-work.lote
                   BY b-tt-work.und.

             ASSIGN de-work = de-work + b-tt-work.vlr.

             IF LAST-OF(b-tt-work.cond-pagto) THEN DO:
                /* Valores do EIXO X (ITENS) */
                CREATE tt-points-2.
                ASSIGN tt-points-2.NumPoint  = i-point
                       tt-points-2.NumGraph  = 1
                       tt-points-2.labeltext = b-tt-work.cond-pagto.

                /* Valores do EIXO Y (Valor) */
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

     END.
 END CASE.

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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grava-devol w-livre 
PROCEDURE pi-grava-devol :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEFINE INPUT PARAMETER p-tipo         AS CHAR.
    DEFINE INPUT PARAMETER p-codigo       AS CHAR.
    DEFINE INPUT PARAMETER p-und          AS CHAR.
    DEFINE INPUT PARAMETER p-lote         AS CHAR.
    DEFINE INPUT PARAMETER p-desc         AS CHAR.
    DEFINE INPUT PARAMETER p-qtd          AS DEC.
    DEFINE INPUT PARAMETER p-vlr          AS DEC.
    DEFINE INPUT PARAMETER p-serie-docto  LIKE docum-est.serie-docto.
    DEFINE INPUT PARAMETER p-nro-docto    LIKE docum-est.nro-docto.
    DEFINE INPUT PARAMETER p-cod-emitente LIKE docum-est.cod-emitente.
    DEFINE INPUT PARAMETER p-nat-operacao LIKE docum-est.nat-operacao.
    
    CASE p-tipo:
        WHEN "1" THEN
            FIND tt-work WHERE
                 tt-work.it-codigo = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
                 NO-ERROR.
        WHEN "2" THEN
            FIND tt-work WHERE
                 tt-work.no-ab-reppri = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
                  NO-ERROR.
        WHEN "3" THEN
            FIND tt-work WHERE
                 tt-work.matriz = DEC(p-codigo) AND tt-work.und = p-und AND tt-work.lote = p-lote
                  NO-ERROR.
        WHEN "4" THEN
            FIND tt-work WHERE
                 tt-work.nome-abrev = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
                 NO-ERROR.
        WHEN "5" THEN
            FIND tt-work WHERE
                 tt-work.regiao = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote AND tt-work.uf = p-desc
                 NO-ERROR.
        WHEN "6" THEN
            FIND tt-work WHERE
                 tt-work.nat-operacao = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
                 NO-ERROR.
        WHEN "7" THEN
            FIND tt-work WHERE
                 tt-work.cond-pagto = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
                 NO-ERROR.
    END CASE.
    
    IF NOT AVAIL tt-work THEN DO:
       CREATE tt-work.
    
       CASE p-tipo:
           WHEN "1" THEN DO:
               ASSIGN  tt-work.it-codigo = p-codigo
                       tt-work.desc-item = p-desc.
           END.
           WHEN "2" THEN                    
               ASSIGN  tt-work.no-ab-reppri = p-codigo
                       tt-work.cod-rep      = INT(p-desc).
           WHEN "3" THEN                         
               ASSIGN  tt-work.matriz = DEC(p-codigo).
           WHEN "4" THEN
               ASSIGN  tt-work.nome-abrev = p-codigo
                       tt-work.cod-emit   = INT(p-desc).
           WHEN "5" THEN 
               ASSIGN  tt-work.regiao = p-codigo
                       tt-work.uf     = p-desc.
           WHEN "6" THEN
               ASSIGN  tt-work.nat-operacao = p-codigo
                       tt-work.aliq-icms    = DEC(p-desc).
           WHEN "7" THEN
               ASSIGN  tt-work.cond-pagto = p-codigo.
       END CASE.
       ASSIGN tt-work.und       = p-und
              tt-work.lote      = p-lote.
    END.
    ASSIGN tt-work.qtd-devol = tt-work.qtd-devol + p-qtd
           tt-work.vlr-devol = tt-work.vlr-devol + p-vlr.
    
    IF p-tipo = '1' THEN DO.
       FIND ITEM WHERE
            ITEM.it-codigo = tt-work.it-codigo NO-LOCK NO-ERROR.

       FIND fam-comerc WHERE
            fam-comerc.fm-cod-com = item.fm-cod-com NO-LOCK NO-ERROR.
       ASSIGN tt-work.classif = fam-comerc.descricao.


       FIND tt-devolucao WHERE
            tt-devolucao.serie-docto = p-serie-docto   AND
            tt-devolucao.nro-docto   = p-nro-docto     AND
            tt-devolucao.cod-emitente = p-cod-emitente AND
            tt-devolucao.nat-operacao = p-nat-operacao NO-ERROR.
       IF NOT AVAIL tt-devolucao THEN DO:
          CREATE tt-devolucao.
          ASSIGN tt-devolucao.serie-docto  = p-serie-docto
                 tt-devolucao.nro-docto    = p-nro-docto
                 tt-devolucao.cod-emitente = p-cod-emitente
                 tt-devolucao.nat-operacao = p-nat-operacao.
       END.
       ASSIGN tt-devolucao.qtd-devol = tt-devolucao.qtd-devol + p-qtd
              tt-devolucao.vlr-devol = tt-devolucao.vlr-devol + p-vlr.
    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grava-movto w-livre 
PROCEDURE pi-grava-movto :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE INPUT PARAMETER p-tipo      AS CHAR.
DEFINE INPUT PARAMETER p-codigo    AS CHAR.
DEFINE INPUT PARAMETER p-und       AS CHAR.
DEFINE INPUT PARAMETER p-lote      AS CHAR.
DEFINE INPUT PARAMETER p-desc      AS CHAR.
DEFINE INPUT PARAMETER p-qtd       AS DEC.
DEFINE INPUT PARAMETER p-vlr       AS DEC.
DEFINE INPUT PARAMETER p-nr-pedcli AS CHAR.

IF p-qtd = 0 THEN
   RETURN.

CASE p-tipo:
    WHEN "1" THEN
        FIND tt-work WHERE
             tt-work.it-codigo = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
             USE-INDEX indice1 NO-ERROR.
    WHEN "2" THEN
        FIND tt-work WHERE
             tt-work.no-ab-reppri = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
             USE-INDEX indice2  NO-ERROR.
    WHEN "3" THEN
        FIND tt-work WHERE
             tt-work.matriz = DEC(p-codigo) AND tt-work.und = p-und AND tt-work.lote = p-lote
             USE-INDEX indice3 NO-ERROR.
    WHEN "4" THEN
        FIND tt-work WHERE
             tt-work.nome-abrev = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
             USE-INDEX indice4 NO-ERROR.
    WHEN "5" THEN
        FIND tt-work WHERE
             tt-work.regiao = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote AND tt-work.uf = p-desc
             USE-INDEX indice5 NO-ERROR.
    WHEN "6" THEN
        FIND tt-work WHERE
             tt-work.nat-operacao = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
             USE-INDEX indice6 NO-ERROR.
    WHEN "7" THEN
        FIND tt-work WHERE
             tt-work.cond-pagto = p-codigo AND tt-work.und = p-und AND tt-work.lote = p-lote
             USE-INDEX indice7 NO-ERROR.
END CASE.

IF NOT AVAIL tt-work THEN DO:
   CREATE tt-work.

   CASE p-tipo:
       WHEN "1" THEN DO:
           ASSIGN  tt-work.it-codigo = p-codigo
                   tt-work.desc-item = p-desc.
       END.
       WHEN "2" THEN                    
           ASSIGN  tt-work.no-ab-reppri = p-codigo
                   tt-work.cod-rep      = INT(p-desc).
       WHEN "3" THEN                         
           ASSIGN  tt-work.matriz = DEC(p-codigo).
       WHEN "4" THEN
           ASSIGN  tt-work.nome-abrev = p-codigo
                   tt-work.cod-emit   = INT(p-desc).
       WHEN "5" THEN 
           ASSIGN  tt-work.regiao = p-codigo
                   tt-work.uf     = p-desc.
       WHEN "6" THEN
           ASSIGN  tt-work.nat-operacao = p-codigo
                   tt-work.aliq-icms    = DEC(p-desc).
       WHEN "7" THEN
           ASSIGN  tt-work.cond-pagto = p-codigo.
   END CASE.
   ASSIGN tt-work.und       = p-und
          tt-work.lote      = p-lote.
END.

ASSIGN tt-work.vlr-custo = tt-work.vlr-custo + (de-vlr-custo * p-qtd).

IF p-tipo = '1' THEN DO.

   FIND ITEM WHERE
        ITEM.it-codigo = tt-work.it-codigo NO-LOCK NO-ERROR.

   FIND fam-comerc WHERE
        fam-comerc.fm-cod-com = item.fm-cod-com NO-LOCK NO-ERROR.
   ASSIGN tt-work.classif = fam-comerc.descricao.

   FIND item-ext WHERE
        item-ext.it-codigo = item.it-codigo NO-LOCK NO-ERROR.
    
   RUN setOpcao IN hBoOpcaoLista (item-ext.num_familia_ger).
   RUN getDescrOpcao IN  hBoOpcaoLista (OUTPUT c-acabamento).
   ASSIGN tt-work.acabamento = c-acabamento.
    
END.


IF i-tp-selecao <> 2 THEN /* Faturados (Nota-Fiscal) */
   ASSIGN tt-work.qtd = tt-work.qtd + p-qtd
          tt-work.vlr = tt-work.vlr + (p-qtd * p-vlr).
ELSE DO:
   ASSIGN tt-work.qtd         = tt-work.qtd         + p-qtd
          tt-work.vlr         = tt-work.vlr         + p-vlr
          tt-work.desc-pratic = tt-work.desc-pratic + IF dec(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 THEN it-nota-fisc.val-desconto-total ELSE dec(SUBSTR(it-nota-fisc.char-2,1500,10)) 
          tt-work.vl-icms     = tt-work.vl-icms     + de-vlr-icms.
   ASSIGN c-uf = "ZZ".
   IF p-tipo = '5' THEN
      ASSIGN c-uf = p-desc.
   IF p-tipo = '6' THEN
      ASSIGN c-uf = p-desc.
   RUN pi-grava-prazo (INPUT nota-fiscal.nr-nota-fis,
                       INPUT nota-fiscal.nr-praz-med,
                       INPUT p-codigo,
                       INPUT p-lote,
                       INPUT ITEM.un,
                       INPUT p-tipo,
                       INPUT c-uf).
END.

IF i-tp-selecao <> 2  THEN DO: 
   FIND tt-pedidos WHERE
        tt-pedidos.nr-pedcli = p-nr-pedcli NO-ERROR.
   IF NOT AVAIL tt-pedidos THEN DO:
      CREATE tt-pedidos.
      ASSIGN tt-pedidos.nr-pedcli = p-nr-pedcli.
   END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-grava-prazo w-livre 
PROCEDURE pi-grava-prazo :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-nr-nota-fis LIKE nota-fiscal.nr-nota-fis.
 DEFINE INPUT PARAMETER p-nr-praz-med LIKE nota-fiscal.nr-praz-med.
 DEFINE INPUT PARAMETER p-tipo     AS CHAR.
 DEFINE INPUT PARAMETER p-lote     AS CHAR.
 DEFINE INPUT PARAMETER p-und      AS CHAR.
 DEFINE INPUT PARAMETER p-cod-tipo AS CHAR.
 DEFINE INPUT PARAMETER p-uf       AS CHAR.

 FIND tt-prazo WHERE
      tt-prazo.nr-nota-fis = p-nr-nota-fis AND 
      tt-prazo.cod-tipo    = p-cod-tipo    AND 
      tt-prazo.uf          = p-uf          AND
      tt-prazo.tipo        = p-tipo        AND
      tt-prazo.lote        = p-lote        AND
      tt-prazo.und         = p-und NO-ERROR.
 IF NOT AVAIL tt-prazo THEN DO:
      CREATE tt-prazo.
      ASSIGN tt-prazo.nr-nota-fis = p-nr-nota-fis
             tt-prazo.cod-tipo    = p-cod-tipo
             tt-prazo.uf          = p-uf
             tt-prazo.tipo        = p-tipo
             tt-prazo.lote        = p-lote
             tt-prazo.und         = p-und
             tt-prazo.praz-medio  = p-nr-praz-med.
 END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-cabec w-livre 
PROCEDURE pi-imp-cabec :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 IF i-tp-selecao <> 2 THEN DO:
    PUT c-empresa  FORMAT "x(40)"                 AT   1
        "DATA: "                                  AT  50
        STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  56
        "HORA: "                                  AT  71
        STRING(TIME,"hh:mm:ss")                   AT  77
        "PAG:"                                    AT 103
        i-pag FORMAT ">>"                         AT 108
        SKIP(1).
    CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
        WHEN '1' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "CODIGO DESCRIÄ«O                      LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------ ------------------------------ ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
        WHEN '2' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "CODIGO REPRESENTANTE                  LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------ ------------------------------ ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
        WHEN '3' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "GRUPO CLIENTE                  LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------------------------------ ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
        WHEN '4' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "CODIGO CLIENTE                        LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------ ------------------------------ ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
        WHEN '5' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "REGI«O                         UF LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------------------------------ -- ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
        WHEN '6' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "NATUREZA OPERAÄ«O              ALIQUOTA LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------------------------------ -------- ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
        WHEN '7' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 40 SKIP(1).
            PUT "VENCIMENTO                     LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO    %"   AT 1.
            PUT "------------------------------ ---- --- -------------- --------------- ----------- ------" AT 1.
        END.
    END CASE.
 END.
 ELSE DO:
    PUT c-empresa  FORMAT "x(40)"                 AT   1
        "DATA: "                                  AT  69
        STRING(TODAY,"99/99/9999") FORMAT "X(10)" AT  75
        "HORA: "                                  AT  95
        STRING(TIME,"hh:mm:ss")                   AT 101
        "PAG:"                                    AT 132
        i-pag FORMAT ">>>"                        AT 136
        SKIP(1).
    CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
        WHEN '1' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "CODIGO DESCRIÄ«O                      LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %"   AT 1.
            PUT "------ ------------------------------ ---- --- -------------- --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
        WHEN '2' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "CODIGO REPRESENTANTE                  LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %"   AT 1.
            PUT "------ ------------------------------ ---- --- -------------- --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
        WHEN '3' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "GRUPO CLIENTE                         LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %"   AT 1.
            PUT "------------------------------------- ---- --- -------------- --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
        WHEN '4' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "CODIGO CLIENTE                        LOTE UND     QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %"   AT 1.
            PUT "------ ------------------------------ ---- --- -------------- --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
        WHEN '5' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "REGI«O                         UF LOTE UND         QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %"   AT 1.
            PUT "------ ----------------------- -- ---  --- ------------------ --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
        WHEN '6' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "NATUREZA OPERAÄ«O           ALIQUOTA LOTE UND      QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %"   AT 1.
            PUT "--------------------------- -------- ---- --- --------------- --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
        WHEN '7' THEN DO:
            PUT c-titulo FORMAT "x(100)" AT 46 SKIP(1).
            PUT "VENCIMENTO                     LOTE UND      QUANTIDADE           VALOR PREÄO MêDIO QTD DEVOLUÄ«O VLR DEVOLUÄ«O RENTABILIDADE    %" AT 1.
            PUT "------------------------------ ---- ---  -------------- --------------- ----------- ------------- ------------- ------------- ------" AT 1.
        END.
    END CASE.
 END.
 
 ASSIGN i-pag = i-pag + 1.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-lin-tot w-livre 
PROCEDURE pi-imp-lin-tot :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-und   AS CHAR.
 DEFINE INPUT PARAMETER p-col01 AS INT.
 DEFINE INPUT PARAMETER p-col02 AS INT.
 DEFINE INPUT PARAMETER p-col03 AS INT.
 DEFINE INPUT PARAMETER p-col04 AS INT.
 DEFINE INPUT PARAMETER p-qtd   AS DEC.
 DEFINE INPUT PARAMETER p-vlr   AS DEC.

 PUT p-und         FORMAT "x(3)"            AT p-col01      
     p-qtd         FORMAT ">>>,>>>,>>9.99"  AT p-col02     
     p-vlr         FORMAT ">>>>,>>>,>>9.99" AT p-col03     
     p-vlr / p-qtd FORMAT ">>>,>>9.99"      AT p-col04.

 IF p-und = 'M' AND i-tp-selecao = 2 THEN
    IF rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME} <> "7" THEN
       PUT "TOTAL DEVOLUÄ«O" FORMAT "X(15)"         AT  91
           de-vlr-devol      FORMAT ">,>>>,>>9.99"  AT 106.
    ELSE
        PUT "TOTAL DEVOLUÄ«O" FORMAT "X(15)"         AT  85
            de-vlr-devol      FORMAT ">,>>>,>>9.99"  AT 100.


END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-linha w-livre 
PROCEDURE pi-imp-linha :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEFINE INPUT PARAMETER p-col03 AS INT.
 DEFINE INPUT PARAMETER p-col04 AS INT.
 DEFINE INPUT PARAMETER p-col05 AS INT.
 DEFINE INPUT PARAMETER p-col06 AS INT.
 DEFINE INPUT PARAMETER p-col07 AS INT.
 DEFINE INPUT PARAMETER p-col08 AS INT.
 DEFINE INPUT PARAMETER p-col09 AS INT.
 DEFINE INPUT PARAMETER p-col10 AS INT.
 DEFINE INPUT PARAMETER p-col11 AS INT.

 PUT b-tt-work.lote            FORMAT "x(4)"            AT p-col03
     b-tt-work.und             FORMAT "x(3)"            AT p-col04
     b-tt-work.qtd             FORMAT ">>>,>>>,>>9.99"  AT p-col05
     b-tt-work.vlr             FORMAT ">>>>,>>>,>>9.99" AT p-col06
     b-tt-work.preco-medio     FORMAT ">>>,>>9.99"      AT p-col07.
 IF i-tp-selecao = 2 THEN
    PUT b-tt-work.qtd-devol FORMAT ">>,>>>,>>9.99" AT p-col08
        b-tt-work.vlr-devol FORMAT ">>,>>>,>>9.99" AT p-col09.


 IF p-col08 <> 0 AND b-tt-work.uf <> "ZZ" THEN
    IF rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "6" AND i-tp-selecao = 2 THEN
       PUT b-tt-work.vl-icms FORMAT ">>,>>>,>>9.99" AT 93.
    ELSE
       PUT b-tt-work.rentabilidade   FORMAT "->>9.99" AT p-col10.

 IF b-tt-work.uf <> "ZZ" THEN
    PUT b-tt-work.perc-sobr-total FORMAT ">>9.99" AT p-col11.
 ELSE DO:
    PUT "" AT 1 SKIP.
    ASSIGN i-lin = i-lin + 1.
 END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imp-total w-livre 
PROCEDURE pi-imp-total :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 PUT "TOTAL GERAL" AT 10.
 CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
     WHEN '1' THEN DO:
         IF de-qtd-kg <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "KG", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-kg, INPUT de-vlr-kg).

         IF de-qtd-und <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "UN", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-und, INPUT de-vlr-und).

         IF de-qtd-metro <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "M", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-metro, INPUT de-vlr-metro).

     END.
     WHEN '2' THEN DO:
         IF de-qtd-kg <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "KG", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-kg, INPUT de-vlr-kg).

         IF de-qtd-und <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "UN", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-und, INPUT de-vlr-und).

         IF de-qtd-metro <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "M", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-metro, INPUT de-vlr-metro).
     END.
     WHEN '3' THEN DO:
         IF de-qtd-kg <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "KG", INPUT 37, INPUT 41, INPUT 56, INPUT 73, INPUT de-qtd-kg, INPUT de-vlr-kg).

         IF de-qtd-und <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "UN", INPUT 37, INPUT 41, INPUT 56, INPUT 73, INPUT de-qtd-und, INPUT de-vlr-und).

         IF de-qtd-metro <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "M", INPUT 37, INPUT 41, INPUT 56, INPUT 73, INPUT de-qtd-metro, INPUT de-vlr-metro).
     END.
     WHEN '4' THEN DO:
         IF de-qtd-kg <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "KG", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-kg, INPUT de-vlr-kg).

         IF de-qtd-und <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "UN", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-und, INPUT de-vlr-und).

         IF de-qtd-metro <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "M", INPUT 44, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-metro, INPUT de-vlr-metro).
     END.
     WHEN '5' THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            IF de-qtd-kg <> 0 THEN
               RUN pi-imp-lin-tot (INPUT "KG", INPUT 40, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-kg, INPUT de-vlr-kg).

            IF de-qtd-und <> 0 THEN
               RUN pi-imp-lin-tot (INPUT "UN", INPUT 40, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-und, INPUT de-vlr-und).

            IF de-qtd-metro <> 0 THEN
               RUN pi-imp-lin-tot (INPUT "M", INPUT 40, INPUT 48, INPUT 63, INPUT 80, INPUT de-qtd-metro, INPUT de-vlr-metro).
         END.
         ELSE DO:
             IF de-qtd-kg <> 0 THEN
                RUN pi-imp-lin-tot (INPUT "KG", INPUT 40, INPUT 44, INPUT 59, INPUT 76, INPUT de-qtd-kg, INPUT de-vlr-kg).

             IF de-qtd-und <> 0 THEN
                RUN pi-imp-lin-tot (INPUT "UN", INPUT 40, INPUT 44, INPUT 59, INPUT 76, INPUT de-qtd-und, INPUT de-vlr-und).

             IF de-qtd-metro <> 0 THEN
                RUN pi-imp-lin-tot (INPUT "M", INPUT 40, INPUT 44, INPUT 59, INPUT 76, INPUT de-qtd-metro, INPUT de-vlr-metro).
         END.
     END.
     WHEN '6' THEN DO:
         IF de-qtd-kg <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "KG", INPUT 46, INPUT 50, INPUT 65, INPUT 82, INPUT de-qtd-kg, INPUT de-vlr-kg).

         IF de-qtd-und <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "UN", INPUT 46, INPUT 50, INPUT 65, INPUT 82, INPUT de-qtd-und, INPUT de-vlr-und).

         IF de-qtd-metro <> 0 THEN
            RUN pi-imp-lin-tot (INPUT "M", INPUT 46, INPUT 50, INPUT 65, INPUT 82, INPUT de-qtd-metro, INPUT de-vlr-metro).
         IF i-tp-selecao = 2 THEN
            PUT de-vlr-icms FORMAT ">>,>>>,>>9.99" AT 93.

     END.
     WHEN '7' THEN DO:
         IF i-tp-selecao = 2 THEN DO:
            IF de-qtd-kg <> 0 THEN
               RUN pi-imp-lin-tot (INPUT "KG", INPUT 37, INPUT 42, INPUT 58, INPUT 73, INPUT de-qtd-kg, INPUT de-vlr-kg).

            IF de-qtd-und <> 0 THEN
               RUN pi-imp-lin-tot (INPUT "UN", INPUT 37, INPUT 42, INPUT 58, INPUT 73, INPUT de-qtd-und, INPUT de-vlr-und).

            IF de-qtd-metro <> 0 THEN
               RUN pi-imp-lin-tot (INPUT "M", INPUT 37, INPUT 42, INPUT 58, INPUT 73, INPUT de-qtd-metro, INPUT de-vlr-metro).
         END.
         ELSE DO:
             IF de-qtd-kg <> 0 THEN
                RUN pi-imp-lin-tot (INPUT "KG", INPUT 37, INPUT 41, INPUT 56, INPUT 73, INPUT de-qtd-kg, INPUT de-vlr-kg).

             IF de-qtd-und <> 0 THEN
                RUN pi-imp-lin-tot (INPUT "UN", INPUT 37, INPUT 41, INPUT 56, INPUT 73, INPUT de-qtd-und, INPUT de-vlr-und).

             IF de-qtd-metro <> 0 THEN
                RUN pi-imp-lin-tot (INPUT "M", INPUT 37, INPUT 41, INPUT 56, INPUT 73, INPUT de-qtd-metro, INPUT de-vlr-metro).
         END.
     END.
 END CASE.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-imprime w-livre 
PROCEDURE pi-imprime :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF VAR h-prog AS HANDLE NO-UNDO.
 DEF VAR i-ct   AS INT.

 DEF VAR i-col AS INT INITIAL 0.

 IF i-tp-selecao = 2 THEN
    ASSIGN i-col = 4.

 RUN utp/ut-utils.p PERSISTENT SET h-prog.

 RUN esapi/saida-imp.p (OUTPUT i-saida,
                        OUTPUT c-saida,
                        OUTPUT i-num-copias,
                        OUTPUT l-ok).

 CASE i-saida:
     WHEN 1 THEN DO.
         OUTPUT TO VALUE(c-saida) CONVERT TARGET "ibm850" PAGED PAGE-SIZE 61.
         PUT CONTROL "~033E~033(s18H".    
     END.
     WHEN 2 THEN
         OUTPUT TO VALUE(c-saida).
     WHEN 3 THEN DO.
         ASSIGN c-saida = SESSION:TEMP-DIRECTORY + "essp0190b.tmp".
         OUTPUT TO VALUE(c-saida) CONVERT SOURCE "ibm850".
     END.
 END CASE.


 ASSIGN de-qtd-kg    = 0
        de-vlr-kg    = 0
        de-qtd-und   = 0
        de-vlr-devol = 0
        de-vlr-und   = 0
        de-qtd-metro = 0
        de-vlr-metro = 0
        de-vlr-icms  = 0.
 DO i-ct = 1 TO i-num-copias.
    ASSIGN i-pag      =  1
           i-lin      = 99.
    FOR EACH b-tt-work WHERE NO-LOCK
              {&SORTBY-IMPRESSAO}.
        
        IF i-lin > 61 THEN DO:
           RUN pi-imp-cabec.
           ASSIGN i-lin = 7.
        END.
        
        CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
            WHEN '1' THEN DO:
                IF b-tt-work.it-codigo = "" THEN NEXT.
                IF b-tt-work.uf <> "ZZ" AND b-tt-work.seq-item = 1 THEN
                   PUT b-tt-work.it-codigo FORMAT "x(6)"  AT 01
                       b-tt-work.desc-item FORMAT "x(30)" AT 08.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                    RUN pi-imp-linha (INPUT 39,
                                      INPUT 44,
                                      INPUT 48,
                                      INPUT 63,
                                      INPUT 80,
                                      INPUT 00,
                                      INPUT 00,
                                      INPUT 00,
                                      INPUT 91).
                ELSE
                    RUN pi-imp-linha (INPUT  39,
                                      INPUT  44,
                                      INPUT  48,
                                      INPUT  63,
                                      INPUT  80,
                                      INPUT  91,
                                      INPUT 105,
                                      INPUT 125,
                                      INPUT 133).
            END.
            WHEN '2' THEN DO:
                IF b-tt-work.no-ab-reppri = "" THEN NEXT.
                IF b-tt-work.uf <> "ZZ" THEN DO: 
                   IF b-tt-work.seq-repres = 1 THEN
                      PUT b-tt-work.cod-rep      FORMAT ">>>>>9" AT 01
                          b-tt-work.no-ab-reppri FORMAT "x(30)"  AT 08.
                END.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                   RUN pi-imp-linha (INPUT 39,
                                     INPUT 44,
                                     INPUT 48,
                                     INPUT 63,
                                     INPUT 80,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 91).
                ELSE
                    RUN pi-imp-linha (INPUT  39,
                                      INPUT  44,
                                      INPUT  48,
                                      INPUT  63,
                                      INPUT  80,
                                      INPUT  91,
                                      INPUT 105,
                                      INPUT 125,
                                      INPUT 133).
            END.
            WHEN '3' THEN DO:
                IF b-tt-work.matriz = 0 THEN NEXT.
                IF b-tt-work.uf <> "ZZ" AND b-tt-work.seq-grupo = 1 THEN
                   PUT b-tt-work.matriz FORMAT ">>9.99" AT 01.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                   RUN pi-imp-linha (INPUT 32,
                                     INPUT 37,
                                     INPUT 41,
                                     INPUT 56,
                                     INPUT 73,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 84).
                ELSE
                    RUN pi-imp-linha (INPUT  39,
                                      INPUT  44,
                                      INPUT  48,
                                      INPUT  63,
                                      INPUT  80,
                                      INPUT  91,
                                      INPUT 105,
                                      INPUT 125,
                                      INPUT 133).
            END.
            WHEN '4' THEN DO:
                IF b-tt-work.nome-abrev = "" THEN NEXT.
                IF b-tt-work.uf <> "ZZ" AND b-tt-work.seq-cliente = 1 THEN
                   PUT b-tt-work.cod-emit     FORMAT ">>>>>9"  AT 01
                       b-tt-work.nome-abrev   FORMAT "x(30)"   AT 08.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                   RUN pi-imp-linha (INPUT 39,
                                     INPUT 44,
                                     INPUT 48,
                                     INPUT 63,
                                     INPUT 80,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 91).
                ELSE
                    RUN pi-imp-linha (INPUT  39,
                                      INPUT  44,
                                      INPUT  48,
                                      INPUT  63,
                                      INPUT  80,
                                      INPUT  91,
                                      INPUT 105,
                                      INPUT 125,
                                      INPUT 133).
            END.
            WHEN '5' THEN DO:
                IF b-tt-work.regiao = "" THEN NEXT.
                IF b-tt-work.uf <> "ZZ" THEN DO: /* Totalizador */
                   IF b-tt-work.seq-regiao = 1 THEN
                      PUT b-tt-work.regiao FORMAT "x(30)"  AT 01.

                   PUT b-tt-work.uf FORMAT "x(2)"   AT 32.
                END.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                   RUN pi-imp-linha (INPUT 35,
                                     INPUT 40,
                                     INPUT 44,
                                     INPUT 59,
                                     INPUT 76,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 87).
                ELSE
                    RUN pi-imp-linha (INPUT 35,
                                      INPUT 40,
                                      INPUT 48,
                                      INPUT 63,
                                      INPUT 80,
                                      INPUT 91,
                                      INPUT 105,
                                      INPUT 125,
                                      INPUT 133).
            END.
            WHEN '6' THEN DO:
                IF b-tt-work.nat-operacao = "" THEN NEXT.
                IF b-tt-work.uf <> "ZZ" AND b-tt-work.seq-nat-oper = 1  THEN
                   PUT b-tt-work.nat-operacao FORMAT "x(30)"   AT 01
                       b-tt-work.aliq-icms    FORMAT ">>9.99"  AT 31.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                   RUN pi-imp-linha (INPUT 40,
                                     INPUT 46,
                                     INPUT 50,
                                     INPUT 65,
                                     INPUT 82,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 93).
                ELSE
                    RUN pi-imp-linha (INPUT 38,
                                      INPUT 43,
                                      INPUT 48,
                                      INPUT 63,
                                      INPUT 80,
                                      INPUT 91,
                                      INPUT 105,
                                      INPUT 125,
                                      INPUT 133).
            END.
            WHEN '7' THEN DO:
                IF b-tt-work.cond-pagto = "" THEN NEXT.
                IF b-tt-work.uf <> "ZZ" AND b-tt-work.seq-cond-pg = 1 THEN
                   PUT b-tt-work.cond-pagto FORMAT "x(30)"   AT 01.
                IF i-tp-selecao <> 2 THEN /* Faturados (TEM RENTABILIDADE) */
                   RUN pi-imp-linha (INPUT 32,
                                     INPUT 37,
                                     INPUT 41,
                                     INPUT 56,
                                     INPUT 73,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 00,
                                     INPUT 84).
                ELSE
                    RUN pi-imp-linha (INPUT 32,
                                      INPUT 37,
                                      INPUT 42,
                                      INPUT 58,
                                      INPUT 74,
                                      INPUT 85,
                                      INPUT 99,
                                      INPUT 119,
                                      INPUT 127).
            END.
        END CASE.
        ASSIGN i-lin = i-lin + 1.

        IF b-tt-work.uf <> "ZZ" THEN DO: /* Acumula Somente Registro Sem TOTALIZADORES */
           CASE b-tt-work.und:
               WHEN 'KG' THEN
                   ASSIGN de-qtd-kg = de-qtd-kg + b-tt-work.qtd
                          de-vlr-kg = de-vlr-kg + b-tt-work.vlr.
               WHEN 'UN' THEN
                   ASSIGN de-qtd-und = de-qtd-und + b-tt-work.qtd
                          de-vlr-und = de-vlr-und + b-tt-work.vlr.
               WHEN 'M' THEN
                   ASSIGN de-qtd-metro = de-qtd-metro + b-tt-work.qtd
                          de-vlr-metro = de-vlr-metro + b-tt-work.vlr.
           END CASE.
           ASSIGN de-vlr-icms  = de-vlr-icms  + b-tt-work.vl-icms
                  de-vlr-devol = de-vlr-devol + b-tt-work.vlr-devol.
        END.
    END.
    IF de-qtd-kg + de-qtd-und + de-qtd-metro <> 0 THEN
       RUN pi-imp-total.
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-monta-planilha w-livre 
PROCEDURE pi-monta-planilha :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  RUN pi-excel-item.
  RUN pi-excel-repres.
  RUN pi-excel-grupos.
  RUN pi-excel-clientes.
  RUN pi-excel-regiao.
  RUN pi-excel-vencto.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-poe-prazo w-livre 
PROCEDURE pi-poe-prazo :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 DEF VAR c-quebra       AS CHAR.
 DEF VAR c-cod-tipo-ant AS CHAR.
 DEF VAR c-tipo-ant     AS CHAR.
 DEF VAR c-uf-ant       AS CHAR.
 DEF VAR c-lote-ant     AS CHAR.
 DEF VAR c-und-ant      AS CHAR.

 ASSIGN de-prazo = 0
        i-qtd-nf = 0.
 FOR EACH tt-prazo NO-LOCK
       BY tt-prazo.cod-tipo
       BY tt-prazo.uf
       BY tt-prazo.tipo
       BY tt-prazo.lote
       BY tt-prazo.und.

     IF c-quebra <> "" AND c-quebra <> tt-prazo.cod-tipo + tt-prazo.uf + tt-prazo.tipo + tt-prazo.lote + tt-prazo.und THEN DO: 
        CASE SUBSTR(c-quebra,1,1):
            WHEN "1" THEN
                FIND tt-work WHERE
                     tt-work.it-codigo = c-tipo-ant AND tt-work.und = c-und-ant AND tt-work.lote = c-lote-ant NO-ERROR.
            WHEN "2" THEN
                FIND tt-work WHERE
                     tt-work.no-ab-reppri = c-tipo-ant AND tt-work.und = c-und-ant AND tt-work.lote = c-lote-ant NO-ERROR.
            WHEN "3" THEN
                FIND tt-work WHERE
                     tt-work.matriz = DEC(c-tipo-ant) AND tt-work.und = c-und-ant AND tt-work.lote = c-lote-ant NO-ERROR.
            WHEN "4" THEN DO.
                FIND tt-work WHERE
                     tt-work.nome-abrev = c-tipo-ant AND tt-work.und = c-und-ant AND tt-work.lote = c-lote-ant NO-ERROR.
            END.
            WHEN "5" THEN
                FIND FIRST tt-work WHERE
                           tt-work.regiao = c-tipo-ant AND tt-work.uf = c-uf-ant  AND tt-work.und = c-und-ant AND tt-work.lote = c-lote-ant NO-ERROR.
            WHEN "6" THEN
                FIND tt-work WHERE
                     tt-work.nat-operacao = c-tipo-ant AND tt-work.und = c-und-ant AND tt-work.lote = c-lote-ant NO-ERROR.
            WHEN "7" THEN
                FIND FIRST tt-work WHERE
                          tt-work.cond-pagto = c-tipo-ant AND tt-work.lote = c-lote-ant AND tt-work.und = c-und-ant NO-ERROR.
                     
        END CASE.
        IF AVAIL tt-work THEN DO.
           ASSIGN tt-work.prazo-medio = de-prazo / i-qtd-nf.
        END.
        ASSIGN de-prazo = 0
               i-qtd-nf = 0.
     END. 
     ASSIGN c-quebra       = tt-prazo.cod-tipo + tt-prazo.uf +  tt-prazo.tipo + tt-prazo.lote + tt-prazo.und
            c-cod-tipo-ant = tt-prazo.cod-tipo
            c-uf-ant       = tt-prazo.uf
            c-tipo-ant     = tt-prazo.tipo
            c-lote-ant     = tt-prazo.lote
            c-und-ant      = tt-prazo.und
            de-prazo       = de-prazo + tt-prazo.praz-medio.
            i-qtd-nf       = i-qtd-nf + 1.
 END.
 IF de-prazo > 0 THEN DO:
    FIND FIRST tt-work WHERE
               tt-work.cond-pagto = c-tipo-ant AND 
               tt-work.lote = c-lote-ant       AND 
               tt-work.und = c-und-ant NO-ERROR.
    IF AVAIL tt-work THEN DO.
       ASSIGN tt-work.prazo-medio = de-prazo / i-qtd-nf.
    END.
 END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-processa w-livre 
PROCEDURE pi-processa :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

 /* Esconde campos do Browse */
 tt-work.it-codigo:VISIBLE IN BROWSE br-work     = NO.      
 tt-work.no-ab-reppri:VISIBLE IN BROWSE br-work  = NO.   
 tt-work.matriz:VISIBLE IN BROWSE br-work        = NO.         
 tt-work.nome-abrev:VISIBLE IN BROWSE br-work    = NO.     
 tt-work.regiao:VISIBLE IN BROWSE br-work        = NO.         
 tt-work.nat-operacao:VISIBLE IN BROWSE br-work  = NO.   
 tt-work.cond-pagto:VISIBLE IN BROWSE br-work    = NO.
 tt-work.rentabilidade:VISIBLE IN BROWSE br-work = NO.
 tt-work.qtd-devol:VISIBLE IN BROWSE br-work     = NO.
 tt-work.vlr-devol:VISIBLE IN BROWSE br-work     = NO.
 tt-work.vl-icms:VISIBLE IN BROWSE br-work       = NO.

 ASSIGN fi-total-icms:SENSITIVE IN FRAME {&FRAME-NAME}  = NO
        fi-total-devol:SENSITIVE IN FRAME {&FRAME-NAME} = NO
        fi-prazo-medio:SENSITIVE IN FRAME {&FRAME-NAME} = NO
        fi-lbl-prazo:SENSITIVE IN FRAME {&FRAME-NAME}   = NO
        bt-devolucao:SENSITIVE IN FRAME {&FRAME-NAME}   = NO.


 fi-prazo-medio:VISIBLE IN FRAME {&FRAME-NAME} = NO.
 fi-lbl-prazo:VISIBLE IN FRAME {&FRAME-NAME}   = NO.

 EMPTY TEMP-TABLE tt-work.
 EMPTY TEMP-TABLE tt-pedidos.
 EMPTY TEMP-TABLE tt-devolucao.
 EMPTY TEMP-TABLE tt-prazo.

 {&OPEN-QUERY-br-work}

 RUN utp/ut-acomp.p PERSISTENT SET h-acomp.

 {utp/ut-liter.i Gerando_Analise *}
 RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).


 CASE i-tp-selecao:
     WHEN 1 THEN DO:  /* A Faturar */
         RUN esapi/ret-udm.p (INPUT c-dt-faturar, OUTPUT c-dia).
         ASSIGN da-dt-implant-ini = DATE("01"  + SUBSTR(c-dt-faturar,1,2) + SUBSTR(c-dt-faturar,3,4))
                da-dt-implant-fin = DATE(c-dia + SUBSTR(c-dt-faturar,1,2) + SUBSTR(c-dt-faturar,3,4)).
         RUN pi-a-faturar.
     END.
     WHEN 2 THEN DO:  /* Faturados */
         ASSIGN da-dt-implant-ini = c-dt-faturadas-ini
                da-dt-implant-fin = c-dt-faturadas-fin.

         RUN pi-faturados.
         RUN pi-poe-prazo.
         RUN pi-devolucao.
         
         IF AVAIL tt-devolucao THEN
            ASSIGN bt-devolucao:SENSITIVE IN FRAME {&FRAME-NAME}  = YES.

         RUN pi-tot-browse.
         APPLY "VALUE-CHANGED" TO rs-sit-credito IN FRAME {&FRAME-NAME}.
     END.
     WHEN 3 THEN DO:  /* Vendidos */
         RUN esapi/ret-udm.p (INPUT c-dt-vendido-fin, OUTPUT c-dia).
         ASSIGN da-dt-implant-ini = DATE("01"  + SUBSTR(c-dt-vendido-ini,1,2) + SUBSTR(c-dt-vendido-ini,3,4))
                da-dt-implant-fin = DATE(c-dia + SUBSTR(c-dt-vendido-fin,1,2) + SUBSTR(c-dt-vendido-fin,3,4)).
         RUN pi-vendidos.
     END.
 END CASE.

 FOR EACH tt-work WHERE
          tt-work.uf <> "ZZ". /* Totalizadores */
     IF tt-work.vlr > 0 THEN
        ASSIGN tt-work.preco-medio = ROUND(tt-work.vlr / tt-work.qtd, 2).
   /*  IF i-tp-selecao = 2 AND tt-work.vlr-custo > 0 THEN
        ASSIGN tt-work.rentabilidade = 100 - (ROUND(tt-work.vlr-custo / tt-work.vlr, 2) * 100). */
                                                    
 END.

 RUN pi-finalizar in h-acomp.

 {&OPEN-QUERY-br-work}
 APPLY 'value-changed' TO br-work IN FRAME {&FRAME-NAME}.
 APPLY 'entry' TO br-work IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-retorna-dados w-livre 
PROCEDURE pi-retorna-dados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT  PARAMETER p-tp-selecao        AS INT.
    DEF INPUT  PARAMETER p-cod-estabel       LIKE estabelec.cod-estabel.
    DEF INPUT  PARAMETER p-dt-faturar        AS DATE.
    DEF INPUT  PARAMETER p-dt-faturadas-ini  AS DATE.
    DEF INPUT  PARAMETER p-dt-faturadas-fin  AS DATE.                                                         
    DEF INPUT  PARAMETER p-dt-vendido-ini    AS DATE.                                                         
    DEF INPUT  PARAMETER p-dt-vendido-fin    AS DATE.                                                         
    DEF INPUT  PARAMETER p-it-codigo-ini     LIKE ped-item.it-codigo.
    DEF INPUT  PARAMETER p-it-codigo-fin     LIKE ped-item.it-codigo.
    DEF INPUT  PARAMETER p-cod-refer-ini     LIKE ped-item.cod-refer.                                         
    DEF INPUT  PARAMETER p-cod-refer-fin     LIKE ped-item.cod-refer.
    DEF INPUT  PARAMETER p-nome-abrev-ini    LIKE ped-venda.nome-abrev.
    DEF INPUT  PARAMETER p-nome-abrev-fin    LIKE ped-venda.nome-abrev.
    DEF INPUT  PARAMETER p-no-ab-reppri-ini  LIKE ped-venda.no-ab-reppri.
    DEF INPUT  PARAMETER p-no-ab-reppri-fin  LIKE ped-venda.no-ab-reppri.
    DEF OUTPUT PARAMETER TABLE FOR tt-work. 

    ASSIGN i-tp-selecao       = p-tp-selecao
           c-dt-faturar       = STRING(p-dt-faturar)
           c-dt-faturadas-ini = p-dt-faturadas-ini 
           c-dt-faturadas-fin = p-dt-faturadas-fin 
           c-dt-vendido-ini   = STRING(p-dt-vendido-ini)
           c-dt-vendido-fin   = STRING(p-dt-vendido-fin)
           c-cod-estabel-ini  = p-cod-estabel
           c-cod-estabel-fin  = p-cod-estabel
           c-nr-pedcli-ini    = ""
           c-nr-pedcli-fin    = "ZZZZZZZZ"
           c-it-codigo-ini    = p-it-codigo-ini
           c-it-codigo-fin    = p-it-codigo-fin
           c-cod-refer-ini    = p-cod-refer-ini
           c-cod-refer-fin    = p-cod-refer-fin
           c-nome-abrev-ini   = p-nome-abrev-ini
           c-nome-abrev-fin   = p-nome-abrev-fin
           c-no-ab-reppri-ini = p-no-ab-reppri-ini
           c-no-ab-reppri-fin = p-no-ab-reppri-fin
           c-fm-cod-com-ini = ""
           c-fm-cod-com-fin = "ZZZZ"
           c-corte-comerc-ini = ""
           c-corte-comerc-fin = "ZZZZ"
           i-ge-codigo-ini    = 0
           i-ge-codigo-fin    = 99  
           c-matriz-ini       = ""
           c-matriz-fin       = "ZZZZZZZZZZZZ"
           c-tp-pedido        = "Todos"
           l-lote-todos       = YES
           l-lote-rp          = NO
           l-lote-rd          = NO
           c-tipo-acabamento  = "A"
           c-tipo-mercado     = "T"
           l-faturamento   = YES
           l-entre-estab    = NO
           l-outros-fat       = NO
           c-cod-depos        = "TODOS".

    ASSIGN da-dt-implant-ini = c-dt-faturadas-ini
           da-dt-implant-fin = c-dt-faturadas-fin.

    RUN utp/ut-acomp.p PERSISTENT SET h-acomp.

    {utp/ut-liter.i Gerando_Analise *}
    RUN pi-inicializar IN h-acomp (INPUT RETURN-VALUE).

    RUN pi-faturados.
    RUN pi-poe-prazo.
    RUN pi-devolucao.

    RUN pi-finalizar in h-acomp.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-tot-browse w-livre 
PROCEDURE pi-tot-browse :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/* Calcula Medias */
DEF VAR de-tot-vlr        AS DEC.
DEF VAR de-qtd-reg-metro  AS DEC.
DEF VAR de-vlr-reg-metro  AS DEC.
DEF VAR de-qtd-dev-metro  AS DEC.
DEF VAR de-vlr-dev-metro  AS DEC.
DEF VAR de-perc-metro     AS DEC.
DEF VAR de-qtd-reg-kg     AS DEC.
DEF VAR de-vlr-reg-kg     AS DEC.
DEF VAR de-qtd-dev-kg     AS DEC.
DEF VAR de-vlr-dev-kg     AS DEC.
DEF VAR de-perc-kg        AS DEC.
DEF VAR de-qtd-reg-und    AS DEC.
DEF VAR de-vlr-reg-und    AS DEC.
DEF VAR de-qtd-dev-und    AS DEC.
DEF VAR de-vlr-dev-und    AS DEC.
DEF VAR de-perc-und       AS DEC.
DEF VAR de-vl-icms        AS DEC.
DEF VAR de-qtd-reg-m2     AS DEC.
DEF VAR de-vlr-reg-m2     AS DEC.
DEF VAR de-qtd-dev-m2     AS DEC.
DEF VAR de-vlr-dev-m2     AS DEC.
DEF VAR de-perc-m2        AS DEC.

{esinc/essp0190a.i "b-tt-work.it-codigo <> ''"}.
{esinc/essp0190a.i "b-tt-work.no-ab-reppri <> ''"}.
{esinc/essp0190a.i "b-tt-work.matriz <> 0"}. 
{esinc/essp0190a.i "b-tt-work.nome-abrev <> ''"}.
{esinc/essp0190a.i "b-tt-work.regiao <> ''"}.
{esinc/essp0190a.i "b-tt-work.nat-operacao <> ''"}.
{esinc/essp0190a.i "b-tt-work.cond-pagto <> ''"}.
  

{esinc/essp0190.i "1" "b-tt-work.it-codigo <> ''" "b-tt-work.it-codigo" "b-tt-work.und"}.
{esinc/essp0190.i "2" "b-tt-work.no-ab-reppri <> ''" "b-tt-work.no-ab-reppri" "b-tt-work.und"}.
{esinc/essp0190.i "3" "b-tt-work.matriz <> 0"  "b-tt-work.matriz" "b-tt-work.und"}. 
{esinc/essp0190.i "4" "b-tt-work.nome-abrev <> ''" "b-tt-work.nome-abrev" "b-tt-work.und"}.
{esinc/essp0190.i "5" "b-tt-work.regiao <> ''"  "b-tt-work.regiao" "b-tt-work.und"}. 
{esinc/essp0190.i "6" "b-tt-work.nat-operacao <> ''" "b-tt-work.nat-operacao" "b-tt-work.und"}.
{esinc/essp0190.i "7" "b-tt-work.cond-pagto <> '' and b-tt-work.vlr > 0"  "b-tt-work.cond-pagto" "b-tt-work.und"}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-tot-etq w-livre 
PROCEDURE pi-tot-etq :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    FOR EACH ped-item-res WHERE
             ped-item-res.cod-estabel = nota-fiscal.cod-estabel AND
             ped-item-res.serie       = nota-fiscal.serie AND
             ped-item-res.nr-nota-fis = INT(nota-fiscal.nr-nota-fis) AND
             ped-item-res.faturado    = YES NO-LOCK.
        FOR EACH ped-item-rom WHERE
                 ped-item-rom.nome-abrev   = ped-item-res.nome-abrev AND
                 ped-item-rom.nr-pedcli    = ped-item-res.nr-pedcli  AND
                 ped-item-rom.nr-sequencia = ped-item-res.nr-sequencia NO-LOCK.
            ASSIGN i-tot-etq = i-tot-etq + 1.
        END.
    END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-vendas-periodo w-livre 
PROCEDURE pi-vendas-periodo :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
   RUN pi-abre-excel.
   IF chExcelApp = ? THEN DO:
      MESSAGE "O Aplicativo EXCEL n∆o foi encontrado. N∆o Ç possivel a execuá∆o do programa."
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
      ASSIGN arq-saida = "".
      RETURN.
   END.
  
   /* Nomear Aba da Planilha */
   chWorkSheet = chExcelapp:Sheets:ITEM(1).
   chWorkSheet:NAME = 'Representantes'.
   chWorkSheet:TAB:ColorIndex = 19.
  
   /* Ativar a Planilha */
   chWorkSheet = chExcelapp:Sheets:ITEM(1).
   chWorkbook:Worksheets(1):activate.
   chExcelApp:ActiveWindow:Zoom = 100.
  
   ASSIGN chworksheet:range("A1"):VALUE = "VENDAS NO PER÷ODO POR REPRESENTANTE".
  
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
  
   ASSIGN chworksheet:range("C3"):VALUE = 'PRONTA ENTREGA'.
   ChWorkSheet:range("C3:D3"):SELECT().
   ChWorksheet:range("C3:D3"):Merge.
   Chworksheet:Range("C3:D3"):HorizontalAlignment =  3.

   ASSIGN chworksheet:range("E3"):VALUE = 'OUTLET'.
   ChWorkSheet:range("E3:F3"):SELECT().
   ChWorksheet:range("E3:F3"):Merge.
   Chworksheet:Range("E3:F3"):HorizontalAlignment =  3.

   ASSIGN chworksheet:range("A4"):VALUE = 'REPRESENTANTE'
          chworksheet:range("B4"):VALUE = 'UF'
          chworksheet:range("C4"):VALUE = 'QUANTIDADE' 
          chworksheet:range("D4"):VALUE = 'VALOR'
          chworksheet:range("E4"):VALUE = 'QUANTIDADE'
          chworksheet:range("F4"):VALUE = 'VALOR'.

    /* Tamanho das Colunas */
    ASSIGN chWorkSheet:Columns("A"):ColumnWidth = 40
           chWorkSheet:Columns("B"):ColumnWidth = 5
           chWorkSheet:Columns("C"):ColumnWidth = 15
           chWorkSheet:Columns("D"):ColumnWidth = 15
           chWorkSheet:Columns("E"):ColumnWidth = 15
           chWorkSheet:Columns("F"):ColumnWidth = 15.

    /* Configura Cabeáalho das Colunas */
    chWorkSheet:Range("A3:L3"):SELECT().
    ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
           chExcelApp:SELECTION:FONT:SIZE               = 09
           chExcelApp:SELECTION:FONT:Bold               = TRUE 
           //chExcelApp:SELECTION:Interior:ColorIndex     = 2
           chExcelApp:SELECTION:FONT:ColorIndex         = 11.

   chWorkSheet:Range("A4:L4"):SELECT().
   ASSIGN chExcelApp:SELECTION:FONT:NAME               = "Consolas"
          chExcelApp:SELECTION:FONT:SIZE               = 09
          chExcelApp:SELECTION:FONT:Bold               = TRUE 
          //chExcelApp:SELECTION:Interior:ColorIndex     = 2
          chExcelApp:SELECTION:FONT:ColorIndex         = 11.

   ASSIGN chworksheet:range("A:B"):NumberFormat        = "@".
   ASSIGN chworksheet:range("C:F"):NumberFormat        = "###.###.##0,00"
          Chworksheet:range("C:F"):HorizontalAlignment = 4. /* Alinhamento a Direita */

   EMPTY TEMP-TABLE tt-resumo.
   FOR EACH tt-pedidos NO-LOCK.
       FIND nota-fiscal WHERE
            nota-fiscal.cod-estabel = tt-pedidos.cod-estabel AND
            nota-fiscal.serie = tt-pedidos.serie AND
            nota-fiscal.nr-nota-fis = tt-pedidos.nr-nota-fis NO-LOCK NO-ERROR.

       FIND repres WHERE
            repres.cod-rep = nota-fiscal.cod-rep NO-LOCK NO-ERROR.

       FIND tt-resumo WHERE
            tt-resumo.nome-rep = repres.nome-abrev NO-LOCK NO-ERROR.
       IF NOT AVAIL tt-resumo THEN DO.
          CREATE tt-resumo.
          ASSIGN tt-resumo.nome-rep = repres.nome-abrev
                 tt-resumo.uf       = repres.estado.
       END.

       FOR EACH it-nota-fisc OF nota-fiscal NO-LOCK.
           FIND ped-item-ext WHERE
                ped-item-ext.cod-estabel = nota-fiscal.cod-estabel AND
                ped-item-ext.nr-pedcli = nota-fiscal.nr-pedcli AND
                ped-item-ext.nome-abrev = nota-fiscal.nome-ab-cli AND
                ped-item-ext.nr-sequencia = it-nota-fisc.nr-seq-ped
                NO-LOCK NO-ERROR.
           IF AVAIL ped-item-ext THEN DO.
              IF ped-item-ext.liquida-ima = YES THEN 
                 ASSIGN tt-resumo.qt-outlet = tt-resumo.qt-outlet + it-nota-fisc.qt-faturada[1]
                        tt-resumo.vl-outlet = tt-resumo.vl-outlet + it-nota-fisc.vl-tot-item +   
                                              IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                                                 THEN it-nota-fisc.val-desconto-total 
                                                 ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)). 

              ELSE
                 ASSIGN tt-resumo.qt-pe = tt-resumo.qt-pe + it-nota-fisc.qt-faturada[1]
                        tt-resumo.vl-pe = tt-resumo.vl-pe + it-nota-fisc.vl-tot-item +   
                                                      IF DEC(SUBSTR(it-nota-fisc.char-2,1500,10)) = 0 
                                                         THEN it-nota-fisc.val-desconto-total 
                                                         ELSE DEC(SUBSTR(it-nota-fisc.char-2,1500,10)). 
           END.
       END.
   END.

   ASSIGN i-lin    = 5.

   ASSIGN de-tot-qt-pe = 0
          de-tot-vl-pe = 0
          de-tot-qt-outlet = 0
          de-tot-vl-outlet = 0.

   FOR EACH tt-resumo.
       IF i-outlet = 1 THEN
           ASSIGN tt-resumo.qt-pe = 0
                  tt-resumo.vl-pe = 0.
       IF i-outlet = 2 THEN
           ASSIGN tt-resumo.qt-outlet = 0
                  tt-resumo.vl-outlet = 0.
                         

       ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = tt-resumo.nome-rep
              chworksheet:range("B" + STRING(i-lin)):VALUE = tt-resumo.uf.

       ASSIGN chworksheet:range("C" + STRING(i-lin)):VALUE = tt-resumo.qt-pe
              chworksheet:range("D" + STRING(i-lin)):VALUE = tt-resumo.vl-pe
              chworksheet:range("E" + STRING(i-lin)):VALUE = tt-resumo.qt-outlet
              chworksheet:range("F" + STRING(i-lin)):VALUE = tt-resumo.vl-outlet.
       
       ASSIGN de-tot-qt-pe = de-tot-qt-pe + tt-resumo.qt-pe
              de-tot-vl-pe = de-tot-vl-pe + tt-resumo.vl-pe
              de-tot-qt-outlet = de-tot-qt-outlet + tt-resumo.qt-outlet
              de-tot-vl-outlet = de-tot-vl-outlet + tt-resumo.vl-outlet.

       ASSIGN i-lin = i-lin + 1.
   END.

   ASSIGN i-lin = i-lin + 1.
   ASSIGN chworksheet:range("A" + STRING(i-lin)):VALUE = 'TOTAIS'
          chworksheet:range("C" + STRING(i-lin)):VALUE = de-tot-qt-pe
          chworksheet:range("D" + STRING(i-lin)):VALUE = de-tot-vl-pe
          chworksheet:range("E" + STRING(i-lin)):VALUE = de-tot-qt-outlet
          chworksheet:range("F" + STRING(i-lin)):VALUE = de-tot-vl-outlet.

   MESSAGE 'Dados Gerados com Sucesso..'
       VIEW-AS ALERT-BOX INFO BUTTONS OK.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-vendidos w-livre 
PROCEDURE pi-vendidos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
 ASSIGN c-sit-ped = "1,2,3,4,5". /* Aberto, Atendido Parcial,Atendito Total, Pendente,Suspendo */

 FOR EACH ped-venda WHERE
          ped-venda.dt-entrega   >= da-dt-implant-ini  AND
          ped-venda.dt-entrega   <= da-dt-implant-fin  AND
          LOOKUP(STRING(ped-venda.cod-sit-ped),c-sit-ped) > 0 AND 
          ped-venda.cod-estabel  >= c-cod-estabel-ini  AND
          ped-venda.cod-estabel  <= c-cod-estabel-fin  AND
          ped-venda.nome-abrev   >= c-nome-abrev-ini   AND
          ped-venda.nome-abrev   <= c-nome-abrev-fin   AND
          ped-venda.nr-pedcli    >= c-nr-pedcli-ini    AND
          ped-venda.nr-pedcli    <= c-nr-pedcli-fin    AND
          ped-venda.no-ab-reppri >= c-no-ab-reppri-ini AND
          ped-venda.no-ab-reppri <= c-no-ab-reppri-fin NO-LOCK
          USE-INDEX ch-pre-fat.

     RUN pi-acompanhar IN h-acomp (INPUT "Data:: " + STRING(ped-venda.dt-entrega) +
                                         " Pedido: " + ped-venda.nr-pedcli).

     /* Criado por Anderson 23/11/2010 */
     /* Procura o deposito padrao da natureza*/
     IF c-cod-depos <> "TODOS" THEN DO:
         FIND FIRST natur-oper-deposito WHERE natur-oper-deposito.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
         IF (AVAIL natur-oper-deposito AND natur-oper-deposito.cod-depos <> c-cod-depos)OR 
            (NOT AVAIL natur-oper-deposito AND c-cod-depos <> "ARM") THEN NEXT.
     END.
     /* Fim Anderson */

     /*
     IF c-tp-pedido <> 'Todos' THEN DO.
        FIND ped-venda-ext WHERE
             ped-venda-ext.nr-pedido = ped-venda.nr-pedido NO-LOCK NO-ERROR.
        IF NOT AVAIL ped-venda-ext OR
           ped-venda-ext.tp-pedido <> c-tp-pedido THEN NEXT.
     END.
     */
     FIND natur-oper WHERE
          natur-oper.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
     IF NOT AVAIL natur-oper THEN NEXT.

     IF l-faturamento AND l-entre-estab = NO THEN DO:
        IF natur-oper.cod-esp <> "DP" THEN NEXT. /* Somente Pedidos que Geraram Duplicatas */
     END.

     IF l-entre-estab AND l-faturamento = NO THEN DO:
        IF natur-oper.cod-esp = "DP" THEN NEXT. /* Somente Pedidos que N∆o Geraram Duplicatas */
     END.


     RUN pi-ver-digita (INPUT "Pedido_de_Venda",                                                             
                        INPUT ped-venda.nr-pedcli).                                                          
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.                                                                

     RUN pi-ver-digita (INPUT "Cliente",
                        INPUT ped-venda.nome-abrev).
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

     RUN pi-ver-digita (INPUT "Representante",
                        INPUT ped-venda.no-ab-reppri).
     IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.

     FIND emitente WHERE
          emitente.nome-abrev = ped-venda.nome-abrev NO-LOCK NO-ERROR.
     IF emitente.nome-matriz < c-matriz-ini OR
        emitente.nome-matriz > c-matriz-fin THEN NEXT.

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

     /* Condiá∆o de Pagamento */
     FIND cond-pagto WHERE
          cond-pagto.cod-cond-pag = ped-venda.cod-cond-pag NO-LOCK NO-ERROR.

     IF NOT AVAIL cond-pagto THEN DO: /* Rotina para Tabela COND-PED */
         ASSIGN i-ct        = 0
                i-prz       = 0.
         FOR EACH cond-ped WHERE
                  cond-ped.nr-pedido = ped-venda.nr-pedido NO-LOCK.
             ASSIGN i-ct  = i-ct + 1.
             ASSIGN i-prz = i-prz + cond-ped.nr-dias-venc.
         END.
         IF i-ct = 0 THEN DO: /* N∆o Gera Duplicatas Lojas TEAR TEXTIL */
            ASSIGN c-cond-pagto = " N∆o Gera Duplicatas".
         END.
         ELSE DO: /* Condiá∆o de Pagamento Especial */
             ASSIGN i-prz = INT(i-prz / i-ct).
             IF i-prz <= 30 THEN
                ASSIGN c-cond-pagto = " De 01 AtÇ 30 Dias".
             ELSE
             IF i-prz <= 60 THEN
                ASSIGN c-cond-pagto = " De 31 AtÇ 60 Dias".
             ELSE
             IF i-prz <= 90 THEN
                ASSIGN c-cond-pagto = " De 61 AtÇ 90 Dias".
             ELSE
                ASSIGN c-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */
         END.
     END.
     ELSE DO:  /* Rotina da Tabela COND-PAGTO */
         IF ped-venda.cod-cond-pag = 1 OR       /* A Vista */
            ped-venda.cod-cond-pag = 2 OR       /* Antecipado */
            ped-venda.cod-cond-pag = 3 THEN DO: /* Contra Apresentaá∆o */
            CASE ped-venda.cod-cond-pag:
                WHEN 1 THEN
                    ASSIGN c-cond-pagto = " A Vista".
                WHEN 2 THEN
                    ASSIGN c-cond-pagto = " A Vista".
                WHEN 3 THEN
                    ASSIGN c-cond-pagto = " Contra Apresentaá∆o".
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
                   ASSIGN c-cond-pagto = " De 01 AtÇ 30 Dias".
                ELSE
                IF i-prz <= 60 THEN
                   ASSIGN c-cond-pagto = " De 31 AtÇ 60 Dias".
                ELSE
                IF i-prz <= 90 THEN
                   ASSIGN c-cond-pagto = " De 61 AtÇ 90 Dias".
                ELSE
                   ASSIGN c-cond-pagto = "ˇAcima de 90 Dias". /* 1¶ Posiá∆o Ç ALT 164 */
    
             END.
             ELSE DO: /* VENDOR */
                 ASSIGN c-cond-pagto = "ˇVENDOR". /* 1¶ Posiá∆o Ç ALT 164 */
             END.
         END.
     END. /* KBO Condiá∆o de Pagamento */

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
         IF NOT AVAIL ITEM THEN NEXT.

         IF (c-tipo-mercado = "0" AND item.codigo-orig <> 0) OR
            (c-tipo-mercado = "1" AND item.codigo-orig <> 1) OR
            (c-tipo-mercado = "2" AND item.codigo-orig <> 2) THEN NEXT.
         
         /* Comentado por Anderson 23/11/2010   
         IF ped-item.cod-refer <> "" AND ITEM.deposito-pad <> c-cod-depos THEN NEXT.
         */

         /* Tecido Cru N∆o Tem Referencia */
         IF (ITEM.ge-codigo < i-ge-codigo-ini) OR
            (ITEM.ge-codigo > i-ge-codigo-fin) THEN NEXT.


         ASSIGN c-lote-refer = "1¶Q".  
         IF ped-item.cod-refer = '888' THEN
            ASSIGN c-lote-refer = "2¶Q".

         /*
         FIND ref-item-ext WHERE
              ref-item-ext.it-codigo = ped-item.it-codigo AND
              ref-item-ext.cod-refer = ped-item.cod-refer NO-LOCK NO-ERROR.
         IF AVAIL ref-item-ext THEN DO:
            IF (ref-item-ext.fm-cod-com < c-fm-cod-com-ini OR
                ref-item-ext.fm-cod-com > c-fm-cod-com-fin) THEN NEXT.

            RUN pi-ver-digita (INPUT "Codigo_Obsoleto",
                               INPUT ref-item-ext.fm-cod-com).
            IF RETURN-VALUE = 'ADM-ERROR' THEN NEXT.
         END.
         */
         IF c-tipo-acabamento = "E" AND SUBSTR(it-nota-fisc.it-codigo,3,1) <> '0' THEN NEXT.
         IF c-tipo-acabamento = "L" AND SUBSTR(it-nota-fisc.it-codigo,3,1)  = '0' THEN NEXT.
         
         RUN pi-grava-movto (INPUT "1",
                             INPUT ped-item.it-codigo,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT item.desc-item,
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         FIND repres WHERE
              repres.nome-abrev = ped-venda.no-ab-reppri NO-LOCK NO-ERROR.
         RUN pi-grava-movto (INPUT "2",
                             INPUT ped-venda.no-ab-reppri,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT repres.cod-rep,
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "3",
                             INPUT emitente.nome-matriz,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT "",
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "4",
                             INPUT ped-venda.nome-abrev,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT STRING(ped-venda.cod-emitente),
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "5",
                             INPUT c-regiao,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT emitente.estado,
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         FIND natur-oper WHERE
              natur-oper.nat-operacao = ped-venda.nat-operacao NO-LOCK NO-ERROR.
         RUN pi-grava-movto (INPUT "6",
                             INPUT ped-venda.nat-operacao,
                             INPUT ITEM.un,
                             INPUT c-lote-refer,
                             INPUT STRING(natur-oper.aliquota-icm),
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

         RUN pi-grava-movto (INPUT "7",
                             INPUT c-cond-pagto,
                             INPUT item.un,
                             INPUT c-lote-refer,
                             INPUT "",
                             INPUT ped-item.qt-pedida,
                             INPUT ped-item.vl-preuni,
                             INPUT ped-venda.nr-pedcli).

     END.
 END. /* KBO Ped-venda */
 RUN pi-tot-browse.

 APPLY "VALUE-CHANGED" TO rs-sit-credito IN FRAME {&FRAME-NAME}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-ver-digita w-livre 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-ver-liquida w-livre 
PROCEDURE pi-ver-liquida :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF INPUT PARAMETER p-processa AS CHAR.
    CASE p-processa.
       WHEN 'F' THEN DO.   // Faturados
           FIND ped-item-ext WHERE
                ped-item-ext.cod-estabel = nota-fiscal.cod-estabel AND
                ped-item-ext.nr-pedcli = nota-fiscal.nr-pedcli AND
                ped-item-ext.nome-abrev = nota-fiscal.nome-ab-cli AND
                ped-item-ext.nr-sequencia = it-nota-fisc.nr-seq-ped
                NO-LOCK NO-ERROR.
           IF AVAIL ped-item-ext THEN DO.
              IF i-outlet = 1 AND 
                 (ped-item-ext.liquida-ima = NO OR ped-item-ext.num-id-liquida-ima = '') THEN RETURN 'ADM-ERROR'. 
              IF i-outlet = 2 AND 
                 (ped-item-ext.liquida-ima = YES OR ped-item-ext.num-id-liquida-ima <> '') THEN RETURN 'ADM-ERROR'.
           END.
        END.
        WHEN 'D' THEN DO.   // Devolvidos
           FIND ped-item-ext WHERE
                ped-item-ext.cod-estabel = nota-fiscal.cod-estabel AND
                ped-item-ext.nr-pedcli = nota-fiscal.nr-pedcli AND
                ped-item-ext.nome-abrev = nota-fiscal.nome-ab-cli AND
                ped-item-ext.nr-sequencia = it-nota-fisc.nr-seq-ped
                NO-LOCK NO-ERROR.
           IF AVAIL ped-item-ext THEN DO.
              IF i-outlet = 1 AND 
                 (ped-item-ext.liquida-ima = NO OR ped-item-ext.num-id-liquida-ima = '') THEN RETURN 'ADM-ERROR'. 

              IF i-outlet = 2 AND 
                 (ped-item-ext.liquida-ima = YES OR ped-item-ext.num-id-liquida-ima <> '') THEN RETURN 'ADM-ERROR'.
           END.
        END.
    END CASE.

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

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-work"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

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

/* ************************  Function Implementations ***************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION fn-cupom-fiscal w-livre 
FUNCTION fn-cupom-fiscal RETURNS LOGICAL
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
 IF SUBSTR(natur-oper.char-2, 76, 2) = '60' THEN
    RETURN TRUE.
 ELSE
    RETURN FALSE.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION fn-func w-livre 
FUNCTION fn-func RETURNS LOGICAL
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
 IF ped-venda.nat-operacao = '511CFP' OR ped-venda.nat-operacao = '512CFT' THEN
    RETURN TRUE.
 ELSE
    RETURN FALSE.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _FUNCTION fn-tipo-grafico w-livre 
FUNCTION fn-tipo-grafico RETURNS CHARACTER
  ( /* parameter-definitions */ ) :
/*------------------------------------------------------------------------------
  Purpose:  
    Notes:  
------------------------------------------------------------------------------*/
 DEF VAR p-selecao AS CHAR.
 CASE rs-sit-credito:SCREEN-VALUE IN FRAME {&FRAME-NAME}:
     WHEN '1' THEN
         ASSIGN p-selecao = 'ITENS'.
     WHEN '2' THEN 
         ASSIGN p-selecao = 'REPRESENTANTES'.
     WHEN '3' THEN 
         ASSIGN p-selecao = 'GRUPO DE CLIENTES'.
     WHEN '4' THEN 
         ASSIGN p-selecao = 'CLIENTES'.
     WHEN '5' THEN
         ASSIGN p-selecao = 'REGIÂES'.
     WHEN '6' THEN
         ASSIGN p-selecao = 'NATUREZA OPERAÄ«O'.
     WHEN '7' THEN
         ASSIGN p-selecao = 'PRAZOS'.
 END CASE.


 RETURN p-selecao.   /* Function return value. */

END FUNCTION.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

