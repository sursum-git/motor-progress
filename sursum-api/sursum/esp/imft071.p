/*****************************************************************************
**
**       Programa: imft071.p
**
**       Data....: 30/06/05
**
**       Autor...: DATASUL S.A.
**
**       Objetivo: Relaá∆o de Custos de Frete por Cidade
**
**       Vers∆o..: 1.00.000 - super
**
**       OBS.....: Este fonte foi gerado pelo Data Viewer
**
         
##############################################################################         
         Modificado por Anderson Fagner Dias Silva na data de 18/07/2008
##############################################################################
         
*******************************************************************************/

define variable c-prog-gerado as character no-undo initial "IMFT071".

def new global shared var c-arquivo-log    as char  format "x(60)"no-undo.
def new global shared var c-prg-vrs as char no-undo.
def new global shared var c-prg-obj as char no-undo.

run grapi/gr2002.p (input c-prog-gerado, input "2.00.00.000").

/****************** Definiá∆o de Tabelas Tempor†rias do Relat¢rio **********************/

def temp-table tt-raw-digita
    field raw-digita as raw.

define temp-table tt-param
    field destino              as integer
    field arquivo              as char
    field usuario              as char
    field data-exec            as date
    field hora-exec            as integer
    field parametro            as logical
    field formato              as integer
    field v_num_tip_aces_usuar as integer
    field ep-codigo            as integer
    field c-cod-estabel-ini like nota-fiscal.cod-estabel
    field c-cod-estabel-fim like nota-fiscal.cod-estabel
    field da-dt-emis-nota-ini like nota-fiscal.dt-emis-nota
    field da-dt-emis-nota-fim like nota-fiscal.dt-emis-nota
    field c-nome-transp-ini like nota-fiscal.nome-transp
    field c-nome-transp-fim like nota-fiscal.nome-transp
    field c-estado-ini like nota-fiscal.estado
    field c-estado-fim like nota-fiscal.estado
    field c-cidade-ini like nota-fiscal.cidade
    field c-cidade-fim like nota-fiscal.cidade
    field c-bairro-ini like nota-fiscal.bairro
    field c-bairro-fim like nota-fiscal.bairro
    FIELD rs-tipo AS INT
    .


/****************** INCLUDE COM VARIµVEIS GLOBAIS *********************/

def new global shared var i-ep-codigo-usuario  like empresa.ep-codigo no-undo.
def new Global shared var l-implanta           as logical    init no.
def new Global shared var c-seg-usuario        as char format "x(12)" no-undo.
def new global shared var i-num-ped-exec-rpw  as integer no-undo.   
def new global shared var i-pais-impto-usuario as integer format ">>9" no-undo.
def new global shared var l-rpc as logical no-undo.
def new global shared var r-registro-atual as rowid no-undo.
def new global shared var c-arquivo-log    as char  format "x(60)"no-undo.
def new global shared var i-num-ped as integer no-undo.         
def new global shared var v_cdn_empres_usuar   like empresa.ep-codigo        no-undo.
def new global shared var v_cod_usuar_corren   like usuar_mestre.cod_usuario no-undo.
def new global shared var h_prog_segur_estab     as handle                   no-undo.
def new global shared var v_cod_grp_usuar_lst    as char                     no-undo.
def new global shared var v_num_tip_aces_usuar   as int                      no-undo.
def new global shared var rw-log-exec            as rowid                    no-undo.


/****************** FIM INCLUDE COM VARIµVEIS GLOBAIS *********************/
/****************** Definiáao de ParÉmetros do Relat¢rio *********************/ 

/****************** Definiáao de Vari†veis de Seleá∆o do Relat¢rio *********************/ 

def new shared var c-cod-estabel-ini like nota-fiscal.cod-estabel format "X(3)" initial "" no-undo.
def new shared var c-cod-estabel-fim like nota-fiscal.cod-estabel format "X(3)" initial "ZZZ" no-undo.
def new shared var da-dt-emis-nota-ini like nota-fiscal.dt-emis-nota format "99/99/9999" initial "01/01/1800" no-undo.
def new shared var da-dt-emis-nota-fim like nota-fiscal.dt-emis-nota format "99/99/9999" initial "12/31/9999" no-undo.
def new shared var c-nome-transp-ini like nota-fiscal.nome-transp format "x(12)" initial "" no-undo.
def new shared var c-nome-transp-fim like nota-fiscal.nome-transp format "x(12)" initial "ZZZZZZZZZZZZ" no-undo.
def new shared var c-estado-ini like nota-fiscal.estado format "x(04)" initial "" no-undo.
def new shared var c-estado-fim like nota-fiscal.estado format "x(04)" initial "ZZZZ" no-undo.
def new shared var c-cidade-ini like nota-fiscal.cidade format "x(20)" initial "" no-undo.
def new shared var c-cidade-fim like nota-fiscal.cidade format "x(20)" initial "ZZZZZZZZZZZZZZZZZZZZZZZZZ" no-undo.
def new shared var c-bairro-ini like nota-fiscal.bairro format "x(20)" initial "" no-undo.
def new shared var c-bairro-fim like nota-fiscal.bairro format "x(20)" initial "ZZZZZZZZZZZZZZZZZZZZZZZZZ" no-undo.


/****************** Definiáao de Vari†veis p/ Campos Virtuais do Relat¢rio *******************/ 

/****************** Definiáao de Vari†veis Campo do Layout do Relat¢rio **********************/ 
DEF NEW SHARED VAR ciffob     AS CHAR FORMAT "x(3)".
/****************** Definiáao de Vari†veis do Relat¢rio N∆o Pedidas em Tela ******************/ 
DEF NEW SHARED VAR tipo-ini   AS CHAR FORMAT "x(10)".
DEF NEW SHARED VAR tipo-fim   AS CHAR FORMAT "x(10)".

/****************** Definiáao de Vari†veis de Total do Relat¢rio *****************************/ 
DEF NEW SHARED VAR tt-merc-fat   AS INTEGER FORMAT ">>>,>>>,>>>,>>9.99".
DEF NEW SHARED VAR tt-peso-bruto AS INTEGER FORMAT ">>>,>>>,>>9.999".
DEF NEW SHARED VAR tt-qt-vol     AS INTEGER FORMAT ">>>,>>>,>>9".

/****************** Definiáao de Vari†veis dos Calculos do Relat¢rio *************************/ 

def input param raw-param as raw no-undo.
def input param table for tt-raw-digita.

/***************** Definiáao de Vari†veis de Processamento do Relat¢rio *********************/

def var h-acomp              as handle no-undo.
def var v-cod-destino-impres as char   no-undo.
def var v-num-reg-lidos      as int    no-undo.
def var v-num-point          as int    no-undo.
def var v-num-set            as int    no-undo.
def var v-num-linha          as int    no-undo.

/****************** Definiáao de Forms do Relat¢rio 132 Colunas ***************************************/ 

form nota-fiscal.cod-estabel     column-label "Es"              format "X(1)"               at 001
     nota-fiscal.estado          column-label "UF"              format "x(2)"               at 004
     nota-fiscal.cidade          column-label "Cidade"          format "x(22)"              at 007
     nota-fiscal.bairro          column-label "Bairro"          format "x(20)"              at 030
     nota-fiscal.nome-transp     column-label "Transp"          format "x(12)"              at 051
  /* nota-fiscal.cidade-cif      column-label "C/F"             format "x(3)"               at 064*/
     ciffob                      column-label "C/F"             format "x(3)"               at 064
     nota-fiscal.vl-merc-tot-fat column-label "Vl Tot Merc Fat" format "->>,>>>,>>9.99"     at 068
     nota-fiscal.nr-nota-fis     column-label "Nt Fisc"         format "x(7)"               at 084
     nota-fiscal.serie           column-label "S"               format "x(1)"               at 092
     nota-fiscal.peso-bru-tot    column-label "Peso Bruto"      format ">>,>>>,>>9.999"     at 094
     nota-embal.qt-volumes       column-label "Vol"             format ">>>9"               at 109
     nota-embal.sigla-emb        column-label "Sig"             format "xx"                 at 114
     nota-fiscal.nome-ab-cli     column-label "Cliente"         format "x(15)"              at 118
   /*  tt-merc-fat                 label ""                format "->>,>>>,>>9.99" at 067
     tt-peso-bruto               label ""                format ">>>,>>9.999"    at 091
     tt-qt-vol                   label ""                format ">>9"            at 103
   */
     with down width 132 no-box stream-io frame f-relat-09-132.

create tt-param.
raw-transfer raw-param to tt-param.

def temp-table tt-editor no-undo
    field linha      as integer
    field conteudo   as character format "x(80)"
    index editor-id is primary unique linha.


def var rw-log-exec                            as rowid no-undo.
def var c-erro-rpc as character format "x(60)" initial " " no-undo.
def var c-erro-aux as character format "x(60)" initial " " no-undo.
def var c-ret-temp as char no-undo.
def var h-servid-rpc as handle no-undo.     
define var c-empresa       as character format "x(40)"      no-undo.
define var c-titulo-relat  as character format "x(50)"      no-undo.
define var i-numper-x      as integer   format "ZZ"         no-undo.
define var da-iniper-x     as date      format "99/99/9999" no-undo.
define var da-fimper-x     as date      format "99/99/9999" no-undo.
define var i-page-size-rel as integer                       no-undo.
define var c-programa      as character format "x(08)"      no-undo.
define var c-versao        as character format "x(04)"      no-undo.
define var c-revisao       as character format "999"        no-undo.

define new shared var c-impressora   as character                      no-undo.
define new shared var c-layout       as character                      no-undo.
define new shared var v_num_count     as integer                       no-undo.
define new shared var c-arq-control   as character                     no-undo.
define new shared var c-sistema       as character format "x(25)"      no-undo.
define new shared var c-rodape        as character                     no-undo.

define new shared buffer b_ped_exec_style for ped_exec.
define new shared buffer b_servid_exec_style for servid_exec.

define new shared stream str-rp.

assign c-programa     = "imft071"
       c-versao       = "2.00"
       c-revisao      = ".00.000"
       c-titulo-relat = "Relaá∆o de Custos de Frete por Cidade"
       c-sistema      = "".

if  tt-param.formato = 2 then do:


form header
    fill("-", 132) format "x(132)" skip
    c-empresa c-titulo-relat at 50
    "Folha:" at 122 page-number(str-rp) at 128 format ">>>>9" skip
    fill("-", 112) format "x(110)" today format "99/99/9999"
    "-" string(time, "HH:MM:SS") skip(1)
    with stream-io width 132 no-labels no-box page-top frame f-cabec.

form header
    fill("-", 132) format "x(132)" skip
    c-empresa c-titulo-relat at 50
    "Folha:" at 122 page-number(str-rp) at 128 format ">>>>9" skip
    "Periodo:" i-numper-x at 08 "-"
    da-iniper-x at 14 "to" da-fimper-x
    fill("-", 74) format "x(72)" today format "99/99/9999"
    "-" string(time, "HH:MM:SS") skip(1)
    with stream-io width 132 no-labels no-box page-top frame f-cabper.

run grapi/gr2004.p.

form header
    c-rodape format "x(132)"
    with stream-io width 132 no-labels no-box page-bottom frame f-rodape.


end. /* tt-param.formato = 2 */


run grapi/gr2009.p (input tt-param.destino,
                    input tt-param.arquivo,
                    input tt-param.usuario,
                    input no).

    assign i-ep-codigo-usuario = tt-param.ep-codigo
           v_cdn_empres_usuar  = i-ep-codigo-usuario.

    assign c-cod-estabel-ini = tt-param.c-cod-estabel-ini
           c-cod-estabel-fim = tt-param.c-cod-estabel-fim
           c-cod-estabel-fim = tt-param.c-cod-estabel-fim
           da-dt-emis-nota-ini = tt-param.da-dt-emis-nota-ini
           da-dt-emis-nota-fim = tt-param.da-dt-emis-nota-fim
           c-nome-transp-ini = tt-param.c-nome-transp-ini
           c-nome-transp-fim = tt-param.c-nome-transp-fim
           c-estado-ini = tt-param.c-estado-ini
           c-estado-fim = tt-param.c-estado-fim
           c-cidade-ini = tt-param.c-cidade-ini
           c-cidade-fim = tt-param.c-cidade-fim
           c-bairro-ini = tt-param.c-bairro-ini
           c-bairro-fim = tt-param.c-bairro-fim
           .
    IF (tt-param.rs-tipo = 1) THEN DO:
        ASSIGN tipo-ini = ""
               tipo-fim = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz".
    END.
    ELSE DO:
         IF (tt-param.rs-tipo = 2) THEN DO:
            ASSIGN tipo-ini = ""
                   tipo-fim = "".
         END.
         ELSE DO:
             IF (tt-param.rs-tipo = 3) THEN DO:
                ASSIGN tipo-ini = "a"
                       tipo-fim = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz".
             END.
         END.
    END.




find first empresa no-lock
    where empresa.ep-codigo = i-ep-codigo-usuario no-error.
if  avail empresa
then
    assign c-empresa = empresa.razao-social.
else
    assign c-empresa = "".

/* for each e disp */

def var l-imprime as logical no-undo.

assign l-imprime = no.
if  tt-param.destino = 1 then
    assign v-cod-destino-impres = "Impressora".
else
    if  tt-param.destino = 2 then
        assign v-cod-destino-impres = "Arquivo".
    else
        assign v-cod-destino-impres = "Terminal".


run utp/ut-acomp.p persistent set h-acomp.

run pi-inicializar in h-acomp(input "Acompanhamento Relat¢rio").

assign v-num-reg-lidos = 0.

/* gr9020a.p */

for each nota-fiscal no-lock
         where nota-fiscal.cidade >= c-cidade-ini and 
               nota-fiscal.cidade <= c-cidade-fim and
               nota-fiscal.bairro >= c-bairro-ini and 
               nota-fiscal.bairro <= c-bairro-fim and
               nota-fiscal.cidade-cif >= tipo-ini AND
               nota-fiscal.cidade-cif <= tipo-fim AND
               nota-fiscal.cod-estabel >= c-cod-estabel-ini and 
               nota-fiscal.cod-estabel <= c-cod-estabel-fim and
               nota-fiscal.dt-emis-nota >= da-dt-emis-nota-ini and 
               nota-fiscal.dt-emis-nota <= da-dt-emis-nota-fim and
               nota-fiscal.estado >= c-estado-ini and 
               nota-fiscal.estado <= c-estado-fim and
               nota-fiscal.nome-transp >= c-nome-transp-ini and 
               nota-fiscal.nome-transp <= c-nome-transp-fim AND
               nota-fiscal.cidade-cif >= tipo-ini AND
               nota-fiscal.cidade-cif <= tipo-fim AND
               nota-fiscal.dt-cancela = ?,
    each nota-embal no-lock
         where nota-embal.cod-estabel = nota-fiscal.cod-estabel and
               nota-embal.serie = nota-fiscal.serie and
               nota-embal.nr-nota-fis = nota-fiscal.nr-nota-fis and
               nota-fiscal.desc-cancela  <> ?
    break by nota-fiscal.estado
          by nota-fiscal.cidade
          by nota-fiscal.nome-transp
          by nota-fiscal.dt-emis-nota:

    assign v-num-reg-lidos = v-num-reg-lidos + 1.
    run pi-acompanhar in h-acomp(input string(v-num-reg-lidos)).

    /***  C‡DIGO PARA SA÷DA EM 132 COLUNAS ***/

    if  tt-param.formato = 2 then do:

        view stream str-rp frame f-cabec.
        view stream str-rp frame f-rodape.
        assign l-imprime     = yes
               tt-merc-fat   = tt-merc-fat + nota-fiscal.vl-merc-tot-fat
               tt-peso-bruto = tt-peso-bruto + nota-fiscal.peso-bru-tot
               tt-qt-vol     = tt-qt-vol + nota-embal.qt-volumes.  

        IF(nota-fiscal.cidade-cif <> "") THEN DO:
            ASSIGN ciffob = "CIF".
        END.
        ELSE DO:    
            ASSIGN ciffob = "FOB".
        END.

        display stream str-rp nota-fiscal.cod-estabel
            nota-fiscal.estado
            nota-fiscal.cidade
            nota-fiscal.bairro
            nota-fiscal.nome-transp
            ciffob
            nota-fiscal.vl-merc-tot-fat
            nota-fiscal.nr-nota-fis
            nota-fiscal.serie
            nota-fiscal.peso-bru-tot
            nota-embal.qt-volumes
            nota-embal.sigla-emb
            nota-fiscal.nome-ab-cli
            with stream-io frame f-relat-09-132.
            down stream str-rp with frame f-relat-09-132. 
      
                
    end.
 
end.

PUT stream str-rp
        "---------------" AT 68
        "---------------" AT 92
        "------"          AT 108
        SKIP
        "Total Geral"     AT 46
        tt-merc-fat       AT 65
        tt-peso-bruto     AT 092
        STRING(tt-qt-vol) AT 110.


if  l-imprime = no then do:
    if  tt-param.formato = 2 then do:
        view stream str-rp frame f-cabec.
        view stream str-rp frame f-rodape.
    end.
    disp stream str-rp " " with stream-io frame f-nulo.
end.

if  tt-param.destino <> 1 then

    page stream str-rp.

else do:

    if   tt-param.parametro = yes then

         page stream str-rp.

end.

if  tt-param.parametro then do:

    

   disp stream str-rp "SELEÄ«O" skip(01) with stream-io frame f-imp-sel.
   disp stream str-rp 
      c-cod-estabel-ini colon 20 "|< >|"   at 44 c-cod-estabel-fim no-label
      da-dt-emis-nota-ini colon 20 "|< >|"   at 44 da-dt-emis-nota-fim no-label
      c-nome-transp-ini colon 20 "|< >|"   at 44 c-nome-transp-fim no-label
      c-estado-ini colon 20 "|< >|"   at 44 c-estado-fim no-label
      c-cidade-ini colon 20 "|< >|"   at 44 c-cidade-fim no-label
      c-bairro-ini colon 20 "|< >|"   at 44 c-bairro-fim no-label  
       with stream-io side-labels overlay row 030 frame f-imp-sel.

   put stream str-rp unformatted skip(1) "IMPRESS«O" skip(1).

   put stream str-rp unformatted skip "    " "Destino : " v-cod-destino-impres " - " tt-param.arquivo format "x(40)".
   put stream str-rp unformatted skip "    " "Execuá∆o: " if i-num-ped-exec-rpw = 0 then "On-Line" else "Batch".
   put stream str-rp unformatted skip "    " "Formato : " if tt-param.formato = 1 then "80 colunas" else "132 colunas".
   put stream str-rp unformatted skip "    " "Usu†rio : " tt-param.usuario.

end.

    output stream str-rp close.

IF VALID-HANDLE(h-acomp) THEN /*gr9030g*/
    RUN pi-finalizar IN h-acomp NO-ERROR.

procedure pi-print-editor:

    def input param c-editor    as char    no-undo.
    def input param i-len       as integer no-undo.

    def var i-linha  as integer no-undo.
    def var i-aux    as integer no-undo.
    def var c-aux    as char    no-undo.
    def var c-ret    as char    no-undo.

    for each tt-editor:
        delete tt-editor.
    end.

    assign c-ret = chr(255) + chr(255).

    do  while c-editor <> "":
        if  c-editor <> "" then do:
            assign i-aux = index(c-editor, chr(10)).
            if  i-aux > i-len or (i-aux = 0 and length(c-editor) > i-len) then
                assign i-aux = r-index(c-editor, " ", i-len + 1).
            if  i-aux = 0 then
                assign c-aux = substr(c-editor, 1, i-len)
                       c-editor = substr(c-editor, i-len + 1).
            else
                assign c-aux = substr(c-editor, 1, i-aux - 1)
                       c-editor = substr(c-editor, i-aux + 1).
            if  i-len = 0 then
                assign entry(1, c-ret, chr(255)) = c-aux.
            else do:
                assign i-linha = i-linha + 1.
                create tt-editor.
                assign tt-editor.linha    = i-linha
                       tt-editor.conteudo = c-aux.
            end.
        end.
        if  i-len = 0 then
            return c-ret.
    end.
    return c-ret.
end procedure.

return 'OK'.

/* fim do programa */
