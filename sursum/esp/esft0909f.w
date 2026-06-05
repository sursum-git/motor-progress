&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
&Scoped-define WINDOW-NAME w-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS w-digita 
/*:T *******************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i ACT0020 2.06.00.000}
{include/i-license-manager.i CC0207 MCC}
/*------------------------------------------------------------------------

  File: 

  Description: from cntnrwin.w - ADM SmartWindow Template

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  History: 
          
------------------------------------------------------------------------*/
/*          This .W file was created with the Progress UIB.             */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */
DEF NEW GLOBAL SHARED VAR c-chave AS CHAR.

// TempTables para Leitura do XML
DEF TEMP-TABLE evento XML-NODE-NAME "Evento"
    FIELD versao      AS CHAR  XML-NODE-TYPE "attribute".

DEF TEMP-TABLE detEvento XML-NODE-NAME "DetEvento"
    FIELD xCorrecao      AS CHAR FORMAT "x(40)".

DEF TEMP-TABLE retEvento XML-NODE-NAME "DetEvento"
    FIELD versao         AS CHAR  XML-NODE-TYPE "attribute".

DEF TEMP-TABLE infEvento xml-node-name "InfEvento"
    FIELD id             AS CHAR FORMAT "x(40)"
    FIELD CNPJ           AS CHAR FORMAT "x(40)"
    FIELD chNFe          AS CHAR FORMAT "x(40)"
    FIELD dhEvento       AS CHAR FORMAT "x(40)"
    FIELD nSeqEvento     AS CHAR
    FIELD dhRegEvento    AS CHAR
    FIELD nProt          AS CHAR.

DEF DATASET dsNFe XML-NODE-NAME 'procEventoNFe' FOR evento,detEvento,retEvento,infEvento.


// TempTable Carta de Correá∆o
DEF TEMP-TABLE tt-cce
    FIELD ChaveDeAcesso   AS CHAR
    FIELD RazSocEmpresa   AS CHAR
    FIELD EnderecoEmpresa AS CHAR
    FIELD BairroEmpresa   AS CHAR
    FIELD CidadeEmpresa   AS CHAR
    FIELD EstadoEmpresa   AS CHAR
    FIELD EmailEmpresa    AS CHAR
    FIELD CepEmpresa      AS CHAR
    FIELD TelefoneEmpresa AS CHAR
    FIELD BcCode1281      AS CHAR
    FIELD CnpjEmpresa     AS CHAR
    FIELD InsEstEmpresa   AS CHAR
    FIELD SerieNota       AS CHAR
    FIELD NrNota          AS CHAR
    FIELD DtEmissao       AS CHAR
    FIELD DestNome        AS CHAR
    FIELD DestCgc         AS CHAR
    FIELD DestEndereco    AS CHAR
    FIELD DestBairro      AS CHAR
    FIELD DestCep         AS CHAR
    FIELD DestCidade      AS CHAR
    FIELD DestUf          AS CHAR
    FIELD DestFone        AS CHAR
    FIELD DestInsEstadual AS CHAR
    FIELD SeqCce          AS CHAR
    FIELD DtHrCce         AS CHAR
    FIELD ProtocoloCce    AS CHAR
    FIELD Narrativa       AS CHAR.

/* Local Variable Definitions ---                                       */

DEF VAR h-acomp      AS HANDLE NO-UNDO.
DEF VAR c-arq-tmp    AS CHAR.
DEF VAR c-leitor-pdf AS CHAR.
DEF VAR l-leitor-ok  AS LOG.

DEF VAR l-ok AS LOG.

DEF STREAM sInput.
DEF STREAM sOutput.

DEF VAR cLinha      AS CHAR NO-UNDO.
DEF VAR pcArq       AS CHAR.
DEF VAR pcArqPdf    AS CHAR.
DEF VAR c-mascara   AS CHAR.
DEF VAR chWordApp   AS COM-HANDLE NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Digitacao
&Scoped-define DB-AWARE no

&Scoped-define ADM-CONTAINER WINDOW

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-1 RECT-8 bt-arquivo-entrada ~
c-arquivo-entrada bt-ok bt-cancelar bt-ajuda 
&Scoped-Define DISPLAYED-OBJECTS c-arquivo-entrada 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR w-digita AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-arquivo-entrada 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-ok AUTO-GO 
     LABEL "OK" 
     SIZE 10 BY 1.

DEFINE VARIABLE c-arquivo-entrada AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 256
     SIZE 40 BY .88 TOOLTIP "Caminho/nome do arquivo XML a ser processado."
     BGCOLOR 15  NO-UNDO.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 80 BY 1.38
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-8
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 48.43 BY 2.21.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     bt-arquivo-entrada AT ROW 2.92 COL 58.14 HELP
          "Escolha do nome do arquivo"
     c-arquivo-entrada AT ROW 2.96 COL 17.57 HELP
          "Nome do arquivo XML a ser processado." NO-LABEL
     bt-ok AT ROW 6.46 COL 2.14
     bt-cancelar AT ROW 6.46 COL 13.14
     bt-ajuda AT ROW 6.46 COL 70.14
     "Arquivo XML a ser processado" VIEW-AS TEXT
          SIZE 21.43 BY .63 AT ROW 1.96 COL 17.57
     RECT-1 AT ROW 6.25 COL 1
     RECT-8 AT ROW 2.29 COL 15.57
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 80 BY 12.58
         FONT 1.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: Digitacao
   Allow: Basic,Browse,DB-Fields,Smart,Window,Query
   Container Links: 
   Add Fields to: Neither
   Design Page: 1
   Other Settings: COMPILE
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW w-digita ASSIGN
         HIDDEN             = YES
         TITLE              = "Geraá∆o de Danfe de CC-e para Word - ESFT0909f"
         HEIGHT             = 6.96
         WIDTH              = 80
         MAX-HEIGHT         = 22
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 22
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
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB w-digita 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-digit.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW w-digita
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME F-Main
   FRAME-NAME                                                           */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-digita)
THEN w-digita:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME w-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-digita w-digita
ON END-ERROR OF w-digita /* Geraá∆o de Danfe de CC-e para Word - ESFT0909f */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
  IF THIS-PROCEDURE:PERSISTENT THEN RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL w-digita w-digita
ON WINDOW-CLOSE OF w-digita /* Geraá∆o de Danfe de CC-e para Word - ESFT0909f */
DO:
  /* This ADM code must be left here in order for the SmartWindow
     and its descendents to terminate properly on exit. */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda w-digita
ON CHOOSE OF bt-ajuda IN FRAME F-Main /* Ajuda */
OR HELP OF FRAME {&FRAME-NAME}
DO:
  {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-arquivo-entrada
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-arquivo-entrada w-digita
ON CHOOSE OF bt-arquivo-entrada IN FRAME F-Main
DO:
   SYSTEM-DIALOG GET-FILE c-arquivo-entrada
       TITLE       "Escolha o arquivo a ser processado"
       INITIAL-DIR SESSION:TEMP-DIRECTORY
       FILTERS     "XML (*.xml)"   "*.xml"
       MUST-EXIST
       USE-FILENAME
       UPDATE l-ok.
     
   IF l-ok = TRUE THEN
      ASSIGN c-arquivo-entrada:SCREEN-VALUE = c-arquivo-entrada.
   ELSE DO:
      MESSAGE "Arquivo n∆o foi selecionado." VIEW-AS ALERT-BOX.
      APPLY 'entry' TO c-arquivo-entrada.
   END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar w-digita
ON CHOOSE OF bt-cancelar IN FRAME F-Main /* Cancelar */
DO:
  apply "close":U to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-ok
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ok w-digita
ON CHOOSE OF bt-ok IN FRAME F-Main /* OK */
DO:
/*    run pi-inicializar in h-acomp (input RETURN-VALUE).                        */
/*    run pi-acompanhar in h-acomp (input "Processando o arquivo. Aguarde...").  */
   ASSIGN INPUT FRAME {&FRAME-NAME} c-arquivo-entrada.

   IF INDEX(c-arquivo-entrada,"_CCe") = 0 THEN DO:
      MESSAGE "O arquivo selecionado n∆o Ç um XML de CC-e." SKIP
              "Selecione um arquivo XML de CC-e."
          VIEW-AS ALERT-BOX INFO BUTTONS OK.
      APPLY 'entry' TO c-arquivo-entrada IN FRAME {&FRAME-NAME}.
      RETURN NO-APPLY.
   END.

   IF SEARCH(c-arquivo-entrada) = ? THEN DO.
      MESSAGE 'Arquivo n∆o Encontrado'
          VIEW-AS ALERT-BOX ERROR BUTTONS OK.
      APPLY 'entry' TO c-arquivo-entrada IN FRAME {&FRAME-NAME}.
      RETURN NO-APPLY.
   END.

   ASSIGN c-arquivo-entrada = REPLACE(c-arquivo-entrada,"\","/").

   /*
   ASSIGN c-arq-tmp = SESSION:TEMP-DIRECTORY + ENTRY(NUM-ENTRIES(c-arquivo-entrada,"/"),c-arquivo-entrada,"/").
   OS-COPY VALUE(c-arquivo-entrada) VALUE(c-arq-tmp).

   OUTPUT TO VALUE(c-arq-tmp) APPEND.
     PUT UNFORMATTED "~n" .
   OUTPUT CLOSE .

   INPUT FROM VALUE(c-arq-tmp).
   REPEAT:
      CREATE tt-xml.
      IMPORT DELIMITER "%*#" tt-xml.
   END.
   INPUT CLOSE.

   FOR EACH tt-xml.

       IF tt-xml.c-linha = "" OR INDEX(tt-xml.c-linha,"<chNFe>") = 0 THEN NEXT.

       CREATE tt-cce.

       IF INDEX(tt-xml.c-linha,"<chNFe>") > 0 AND INDEX(tt-xml.c-linha,"</chNFe>") > 0 THEN DO.
          ASSIGN tt-cce.ChaveDeAcesso = SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<chNFe>") + 7,44)
                 tt-cce.BcCode1281    = tt-cce.ChaveDeAcesso.
       END.

       IF INDEX(tt-xml.c-linha,"<CNPJ>") > 0 AND INDEX(tt-xml.c-linha,"</CNPJ>") > 0 THEN DO:
          ASSIGN tt-cce.CnpjEmpresa = TRIM(SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<CNPJ>") + 6,14)).
          FIND ems2cad.empresa WHERE
               ems2cad.empresa.cgc = tt-cce.CnpjEmpresa NO-LOCK NO-ERROR.
          IF AVAIL ems2cad.empresa THEN
             ASSIGN tt-cce.RazSocEmpresa   = ems2cad.empresa.razao-social
                    tt-cce.EnderecoEmpresa = ems2cad.empresa.endereco
                    tt-cce.BairroEmpresa   = ems2cad.empresa.bairro
                    tt-cce.CidadeEmpresa   = ems2cad.empresa.cidade
                    tt-cce.EstadoEmpresa   = ems2cad.empresa.uf
                    tt-cce.EmailEmpresa    = ems2cad.empresa.e-mail
                    tt-cce.CepEmpresa      = ems2cad.empresa.cep
                    tt-cce.TelefoneEmpresa = ems2cad.empresa.telefone[1]
                    tt-cce.InsEstEmpresa   = ems2cad.empresa.inscr-estad.
       END.

       ASSIGN tt-cce.SerieNota = SUBSTR(tt-cce.ChaveDeAcesso,25,1).
       ASSIGN tt-cce.NrNota    = SUBSTR(tt-cce.ChaveDeAcesso,28,7).

       IF INDEX(tt-xml.c-linha,"<dhEvento>") > 0 AND INDEX(tt-xml.c-linha,"</dhEvento>") > 0 THEN
          ASSIGN tt-cce.DtEmissao = SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhEvento>") + 18,2) + "/" +
                                    SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhEvento>") + 15,2) + "/" +
                                    SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhEvento>") + 10,4).

       IF INDEX(tt-xml.c-linha,"<CNPJDest>") > 0 AND INDEX(tt-xml.c-linha,"</CNPJDest>") > 0 THEN DO:
          FIND emitente WHERE emitente.cgc = TRIM(SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<CNPJDest>") + 10,14)) NO-LOCK NO-ERROR.

          IF AVAIL emitente THEN DO:
             IF emitente.natureza = 1 THEN /* PF */
                ASSIGN c-mascara = "999.999.999-99".
             ELSE                          /* PJ */
                ASSIGN c-mascara = "99.999.999/9999-99".

             ASSIGN tt-cce.DestCgc         = TRIM(SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<CNPJDest>") + 10,14))
                    tt-cce.DestNome        = emitente.nome-emit
                    tt-cce.DestEndereco    = emitente.endereco
                    tt-cce.DestBairro      = emitente.bairro
                    tt-cce.DestCep         = emitente.cep
                    tt-cce.DestCidade      = emitente.cidade
                    tt-cce.DestUf          = emitente.estado
                    tt-cce.DestFone        = emitente.telefone[1]
                    tt-cce.DestInsEstadual = emitente.ins-estad.
          END.
       END.

       IF INDEX(tt-xml.c-linha,"<nSeqEvento>") > 0 AND INDEX(tt-xml.c-linha,"</nSeqEvento>") > 0 THEN
          ASSIGN tt-cce.SeqCce = SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<nSeqEvento>") + 12,1).

       IF INDEX(tt-xml.c-linha,"<dhRegEvento>") > 0 AND INDEX(tt-xml.c-linha,"</dhRegEvento>") > 0 THEN
          ASSIGN tt-cce.DtHrCce = SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhRegEvento>") + 21,2) + "/" +
                                  SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhRegEvento>") + 18,2) + "/" +
                                  SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhRegEvento>") + 13,4) + "  " +
                                  SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<dhRegEvento>") + 24,5).

       IF INDEX(tt-xml.c-linha,"<nProt>") > 0 AND INDEX(tt-xml.c-linha,"</nProt>") > 0 THEN
          ASSIGN tt-cce.ProtocoloCce = SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<nProt>") + 7,15).

       IF INDEX(tt-xml.c-linha,"<xCorrecao>") > 0 AND INDEX(tt-xml.c-linha,"</xCorrecao>") > 0 THEN
          ASSIGN tt-cce.Narrativa = SUBSTR(tt-xml.c-linha,INDEX(tt-xml.c-linha,"<xCorrecao>") + 11,INDEX(tt-xml.c-linha,"</xCorrecao>") - INDEX(tt-xml.c-linha,"<xCorrecao>") - 11).
   END.
   */

   RUN pi-ler-xml.

   FIND FIRST tt-cce NO-LOCK NO-ERROR.

   ASSIGN pcArq = SESSION:TEMP-DIRECTORY + "DANFE-CCe-" + tt-cce.NrNota + ".doc"
          pcArqPdf = SESSION:TEMP-DIRECTORY + "DANFE-CCe-" + tt-cce.NrNota + ".pdf".


   INPUT  STREAM sInput  FROM VALUE(SEARCH("layout\ccev1.rtf")).

   OUTPUT STREAM sOutput TO VALUE(pcArq) NO-CONVERT.
   FOR EACH tt-cce.
       IF tt-cce.RazSocEmpresa = '' THEN NEXT.

       REPEAT:
          IMPORT STREAM sInput UNFORMAT cLinha.

          IF INDEX(cLinha,"#":U) > 0 THEN
             ASSIGN cLinha = REPLACE(cLinha,"#ChaveDeAcesso":U,STRING(tt-cce.ChaveDeAcesso,"9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999"))
                    cLinha = REPLACE(cLinha,"#RazSocEmpresa":U,tt-cce.RazSocEmpresa)  
                    cLinha = REPLACE(cLinha,"#EnderecoEmpresa":U,tt-cce.EnderecoEmpresa)
                    cLinha = REPLACE(cLinha,"#BairroEmpresa":U,tt-cce.BairroEmpresa)
                    cLinha = REPLACE(cLinha,"#CidadeEmpresa":U,tt-cce.CidadeEmpresa)  
                    cLinha = REPLACE(cLinha,"#EstadoEmpresa":U,tt-cce.EstadoEmpresa)  
                    cLinha = REPLACE(cLinha,"#EmailEmpresa":U,tt-cce.EmailEmpresa)   
                    cLinha = REPLACE(cLinha,"#CepEmpresa":U,tt-cce.CepEmpresa)     
                    cLinha = REPLACE(cLinha,"#TelefoneEmpresa":U,tt-cce.TelefoneEmpresa)
                    cLinha = REPLACE(cLinha,"#BcCode1281":U,tt-cce.BcCode1281)
                    cLinha = REPLACE(cLinha,"#CnpjEmpresa":U,STRING(tt-cce.CnpjEmpresa,"99.999.999/9999-99"))    
                    cLinha = REPLACE(cLinha,"#InsEstEmpresa":U,tt-cce.InsEstEmpresa)  
                    cLinha = REPLACE(cLinha,"#SerieNota":U,tt-cce.SerieNota)      
                    cLinha = REPLACE(cLinha,"#NrNota":U,tt-cce.NrNota)        
                    cLinha = REPLACE(cLinha,"#DtEmissao":U,tt-cce.DtEmissao)      
                    cLinha = REPLACE(cLinha,"#DestNome":U,tt-cce.DestNome)       
                    cLinha = REPLACE(cLinha,"#DestCgc":U,STRING(tt-cce.DestCgc,c-mascara))        
                    cLinha = REPLACE(cLinha,"#DestEndereco":U,tt-cce.DestEndereco)   
                    cLinha = REPLACE(cLinha,"#DestBairro":U,tt-cce.DestBairro)     
                    cLinha = REPLACE(cLinha,"#DestCep":U,tt-cce.DestCep)        
                    cLinha = REPLACE(cLinha,"#DestCidade":U,tt-cce.DestCidade)     
                    cLinha = REPLACE(cLinha,"#DestUf":U,tt-cce.DestUf)         
                    cLinha = REPLACE(cLinha,"#DestFone":U,tt-cce.DestFone)       
                    cLinha = REPLACE(cLinha,"#DestInsEstadual":U,tt-cce.DestInsEstadual)
                    cLinha = REPLACE(cLinha,"#SeqCce":U,tt-cce.SeqCce)         
                    cLinha = REPLACE(cLinha,"#DtHrCce":U,tt-cce.DtHrCce)        
                    cLinha = REPLACE(cLinha,"#ProtocoloCce":U,tt-cce.ProtocoloCce)   
                    cLinha = REPLACE(cLinha,"#Narrativa":U,tt-cce.Narrativa).
          PUT STREAM sOutput UNFORMATTED cLinha SKIP.
       END.
   END.
   PUT STREAM sOutput "}}":U.

   INPUT  STREAM sInput  CLOSE.
   OUTPUT STREAM sOutput CLOSE.

   //EMPTY TEMP-TABLE tt-xml.
   EMPTY TEMP-TABLE tt-cce.

   CREATE 'Word.Application':U chWordApp.        /* Cria uma aplicaá∆o WORD */
   chWordApp:WindowState = 1.                    /* O estado 1 para o Word Ç maximizado (2=minimizado) */
   chWordApp:VISIBLE = NO.                       /* Apenas para n∆o mostrar que o word est† sendo utilizado em tela */
   chWordApp:Documents:ADD(pcArq).               /* Inclui arquivo */
   chWordApp:ActiveDocument:SaveAs(pcArq).       /* Salva o arquivo aberto no WORD com o nome final do arquivo */
   chWordApp:ActiveDocument:SaveAs(pcArqPdf,17). /* Salva o arquivo em formato PDF */
   /*
   chWordApp:PrintOut().                         /* Imprime o arquivo na impressora default */ 
   */
   chWordApp:ActiveDocument:CLOSE.               /* Fecha o arquivo do WORD */
   chWordApp:QUIT().                             /* Fechar o WORD */
   
   RELEASE OBJECT chWordApp.                     /* Elimina o endereáo utilizado para o WORD na m†quina */

   OS-DELETE VALUE(pcArq).                       /* Elimina o DOC e deixa somente o PDF */

   RUN utp/ut-utils.p PERSISTENT SET h-prog.

   IF l-leitor-ok THEN
      RUN EXECUTE IN h-prog (INPUT c-leitor-pdf, INPUT pcArqPdf).
   ELSE
      MESSAGE "N∆o h† leitor de PDF instalado neste computador." SKIP
              "Por isso o arquivo PDF gerado n∆o foi exibido."   SKIP
              "Entretanto, o arquivo" pcArqPdf "foi gerado com sucesso!"
          VIEW-AS ALERT-BOX INFO BUTTONS OK.

   DELETE PROCEDURE h-prog.

   APPLY "entry" TO c-arquivo-entrada IN FRAME {&FRAME-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK w-digita 


/* ***************************  Main Block  *************************** */

/* Include custom  Main Block code for SmartWindows. */
{src/adm/template/windowmn.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects w-digita  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/
  DEFINE VARIABLE adm-current-page  AS INTEGER NO-UNDO.

  RUN get-attribute IN THIS-PROCEDURE ('Current-Page':U).
  ASSIGN adm-current-page = INTEGER(RETURN-VALUE).

  /* Select a Startup page. */
  IF adm-current-page eq 0 
  THEN RUN select-page IN THIS-PROCEDURE ( 1 ).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available w-digita  _ADM-ROW-AVAILABLE
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI w-digita  _DEFAULT-DISABLE
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
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(w-digita)
  THEN DELETE WIDGET w-digita.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI w-digita  _DEFAULT-ENABLE
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
  DISPLAY c-arquivo-entrada 
      WITH FRAME F-Main IN WINDOW w-digita.
  ENABLE RECT-1 RECT-8 bt-arquivo-entrada c-arquivo-entrada bt-ok bt-cancelar 
         bt-ajuda 
      WITH FRAME F-Main IN WINDOW w-digita.
  {&OPEN-BROWSERS-IN-QUERY-F-Main}
  VIEW w-digita.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-destroy w-digita 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit w-digita 
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

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-initialize w-digita 
PROCEDURE local-initialize :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */

  //{utp/ut9000.i "ESFT0909f" "2.06.00.000"}

  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'initialize':U ) .

  IF c-chave <> '' THEN DO.  // Chamado do ft0909
     FIND fnd_usuar_univ WHERE
          fnd_usuar_univ.cod_usuario = c-seg-usuario NO-LOCK NO-ERROR.
    
     IF fnd_usuar_univ.cod_empresa = '1' THEN
         ASSIGN c-arquivo-entrada:SCREEN-VALUE  IN FRAME {&FRAME-NAME} = "\\192.168.0.30\ima\" + c-chave.
     ELSE
        ASSIGN c-arquivo-entrada:SCREEN-VALUE IN FRAME {&FRAME-NAME} = "\\192.168.0.30\med\" + c-chave.
  END.

  /* Valida existància do MS Word */
  CREATE "Word.Application":U chWordApp NO-ERROR.
  
  IF chWordApp = ? THEN DO:
     MESSAGE "Este computador n∆o tem MS-Word." SKIP
             "N∆o ser† poss°vel executar o programa!"
         VIEW-AS ALERT-BOX INFO BUTTONS OK.
     APPLY 'CHOOSE' TO bt-cancelar IN FRAME {&FRAME-NAME}.
  END.

  /* Verifica a Existencia dos Utilitarios Adobe Reader e Foxit Reader */
  LOAD "AcroExch.Document" BASE-KEY "HKEY_CLASSES_ROOT" NO-ERROR.
  IF ERROR-STATUS:NUM-MESSAGES = 0 THEN DO:
     USE "AcroExch.Document".
     GET-KEY-VALUE SECTION "shell\open\command" KEY DEFAULT VALUE c-leitor-pdf.
     UNLOAD "AcroExch.Document".
     ASSIGN l-leitor-ok = SEARCH(ENTRY(2,c-leitor-pdf,'"')) <> ?.
  END.
  IF NOT l-leitor-ok THEN DO:
     LOAD "FoxitReader.Document" BASE-KEY "HKEY_CLASSES_ROOT" NO-ERROR.
     IF ERROR-STATUS:NUM-MESSAGES = 0 THEN DO:
        USE "FoxitReader.Document".
        GET-KEY-VALUE SECTION "shell\open\command" KEY DEFAULT VALUE c-leitor-pdf.
        UNLOAD "FoxitReader.Document".
        ASSIGN l-leitor-ok = SEARCH(ENTRY(2,c-leitor-pdf,'"')) <> ?.
     END.
  END.
  IF l-leitor-ok THEN
     ASSIGN c-leitor-pdf = ENTRY(2,c-leitor-pdf,'"').
  ELSE
     ASSIGN c-leitor-pdf = "".

  /* Code placed here will execute AFTER standard behavior.    */

  run utp/ut-acomp.p persistent set h-acomp.
  
  {include/i-inifld.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-ler-xml w-digita 
PROCEDURE pi-ler-xml :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEF VAR vArqProc as char.
    DEF VAR retOK AS LOG NO-UNDO.
    
    ASSIGN vArqProc = INPUT FRAME {&FRAME-NAME} c-arquivo-entrada.
    
    DATASET dsNfe:EMPTY-DATASET NO-ERROR.
    
    ASSIGN retOK = DATASET dsNfe:READ-XML("file",
                                         vArqProc,
                                         "empty",
                                         ?,
                                         ?,
                                         ?,
                                         "ignore")
                                         NO-ERROR.
    
    IF retOK = NO THEN DO.
      MESSAGE "Erro ao procesar o arquivo" 
              QUOTER(vArqProc) VIEW-AS ALERT-BOX.
      RETURN 'ADM-ERROR'.
    END.
    
    EMPTY TEMP-TABLE tt-cce.
    CREATE tt-cce.
    
    FOR FIRST infEvento WHERE
              infEvento.CNPJ <> '' NO-LOCK.
    
        ASSIGN tt-cce.ChaveDeAcesso = infEvento.chNFe.
    
        ASSIGN tt-cce.BcCode1281 = tt-cce.ChaveDeAcesso
               tt-cce.SerieNota = SUBSTR(tt-cce.ChaveDeAcesso,25,1)
               tt-cce.NrNota    = SUBSTR(tt-cce.ChaveDeAcesso,28,7).
    
        ASSIGN tt-cce.DtEmissao = SUBSTR(infEvento.dhEvento,9,2) + "/" +
                                  SUBSTR(infEvento.dhEvento,6,2) + "/" +
                                  SUBSTR(infEvento.dhEvento,1,4).
    
        IF infEvento.CNPJ = '' THEN
           ASSIGN infEvento.CNPJ = SUBSTR(tt-cce.ChaveDeAcesso,7,14).
            

        FIND ems2cad.empresa WHERE
             ems2cad.empresa.cgc = infEvento.CNPJ NO-LOCK NO-ERROR.
        IF AVAIL ems2cad.empresa THEN
           ASSIGN tt-cce.RazSocEmpresa   = ems2cad.empresa.razao-social
                  tt-cce.EnderecoEmpresa = ems2cad.empresa.endereco
                  tt-cce.BairroEmpresa   = ems2cad.empresa.bairro
                  tt-cce.CidadeEmpresa   = ems2cad.empresa.cidade
                  tt-cce.EstadoEmpresa   = ems2cad.empresa.uf
                  tt-cce.EmailEmpresa    = ems2cad.empresa.e-mail
                  tt-cce.CepEmpresa      = ems2cad.empresa.cep
                  tt-cce.TelefoneEmpresa = ems2cad.empresa.telefone[1]
                  tt-cce.InsEstEmpresa   = ems2cad.empresa.inscr-estad.
    
    
        FIND emitente WHERE 
             emitente.cgc = infEvento.CNPJ NO-LOCK NO-ERROR.
    
        IF AVAIL emitente THEN DO:
           IF emitente.natureza = 1 THEN /* PF */
              ASSIGN c-mascara = "999.999.999-99".
           ELSE                          /* PJ */
              ASSIGN c-mascara = "99.999.999/9999-99".

           ASSIGN tt-cce.DestCgc         = emitente.cgc
                  tt-cce.DestNome        = emitente.nome-emit
                  tt-cce.DestEndereco    = emitente.endereco
                  tt-cce.DestBairro      = emitente.bairro
                  tt-cce.DestCep         = emitente.cep
                  tt-cce.DestCidade      = emitente.cidade
                  tt-cce.DestUf          = emitente.estado
                  tt-cce.DestFone        = emitente.telefone[1]
                  tt-cce.DestInsEstadual = emitente.ins-estad.
        END.
    
        ASSIGN tt-cce.SeqCce = infEvento.nSeqEvento
               tt-cce.ProtocoloCce = infEvento.nSeqEvento
               tt-cce.DtHrCce = SUBSTR(infEvento.dhRegEvento,9,2) + "/" +
                                SUBSTR(infEvento.dhRegEvento,6,2) + "/" +
                                SUBSTR(infEvento.dhRegEvento,1,4) + "  " +
                                SUBSTR(infEvento.dhRegEvento,12,5).
    END.
    
    
    FOR FIRST detEvento.
        ASSIGN tt-cce.Narrativa = detEvento.xCorrecao.
    END.
    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records w-digita  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* SEND-RECORDS does nothing because there are no External
     Tables specified for this Digitacao, and there are no
     tables specified in any contained Browse, Query, or Frame. */

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed w-digita 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

