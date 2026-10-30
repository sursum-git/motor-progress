/* Unica implementacao; {&ERP} e macro de compilacao, nunca texto do usuario. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esapi/consulta-notas/BuscarDevolucoesParametros.i}

DEFINE BUFFER bDoc       FOR {&ERP}.docum-est.
DEFINE BUFFER bNatureza  FOR {&ERP}.natur-oper.
DEFINE BUFFER bDevol     FOR {&ERP}.devol-cli.
DEFINE BUFFER bNota      FOR {&ERP}.nota-fiscal.
DEFINE BUFFER bPedido    FOR {&ERP}.ped-venda.
DEFINE BUFFER bPedRep    FOR {&ERP}.ped-repre.
DEFINE BUFFER bMotDevol  FOR {&ERP}.devol-cli.
DEFINE BUFFER bRejeicao  FOR {&ERP}.cod-rejeicao.

DEFINE TEMP-TABLE ttMotivo NO-UNDO
    FIELD codigo    AS INTEGER
    FIELD descricao AS CHARACTER
    INDEX ix IS UNIQUE codigo descricao.

DEFINE VARIABLE iResto         AS INTEGER   NO-UNDO.
DEFINE VARIABLE dTaxa          AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE dDesconto      AS DECIMAL DECIMALS 10 NO-UNDO.
DEFINE VARIABLE cMotivos       AS CHARACTER NO-UNDO.

EMPTY TEMP-TABLE tt-NF.
IF pcEmpresa = ? OR pcEmpresa <> "{&EMPRESA}" THEN
    UNDO, THROW NEW Progress.Lang.AppError("Empresa incompativel com o programa", 1).

{esapi/consulta-notas/ConsultaNFFiltrosValidar.i}

DO ON ERROR UNDO, THROW:
    FOR EACH bDoc NO-LOCK
        WHERE (pcEstabelDe = "" OR bDoc.cod-estabel >= pcEstabelDe)
          AND (pcEstabelAte = "" OR bDoc.cod-estabel <= pcEstabelAte)
          AND (piClienteDe = ? OR bDoc.cod-emitente >= piClienteDe)
          AND (piClienteAte = ? OR bDoc.cod-emitente <= piClienteAte)
          AND (pcNotaDe = "" OR bDoc.nro-docto >= pcNotaDe)
          AND (pcNotaAte = "" OR bDoc.nro-docto <= pcNotaAte)
          AND (pdEmissaoDe = ? OR bDoc.dt-emissao >= pdEmissaoDe)
          AND (pdEmissaoAte = ? OR bDoc.dt-emissao <= pdEmissaoAte)
          &IF "{&EMPRESA}" = "IMA" &THEN
          AND bDoc.cod-estabel = "1"
          AND bDoc.cod-emitente <> 10535
          &ELSE
          AND bDoc.cod-emitente <> 1
          &ENDIF
          ,
        FIRST bNatureza NO-LOCK
        WHERE bNatureza.nat-operacao = bDoc.nat-operacao
          AND bNatureza.tipo-compra = 3
          AND bNatureza.tp-rec-desp = 1:

        /* Equivale ao TOP 1 do legado apos os filtros de pedido/representante.
           A chave da nota inclui estabelecimento para impedir venda de outra filial. */
        venda:
        FOR EACH bDevol NO-LOCK
            WHERE bDevol.cod-estabel  = bDoc.cod-estabel
              AND bDevol.cod-emitente = bDoc.cod-emitente
              AND bDevol.nro-docto    = bDoc.nro-docto
              AND bDevol.serie-docto  = bDoc.serie-docto
              AND bDevol.nat-operacao = bDoc.nat-operacao,
            EACH bNota NO-LOCK
            WHERE bNota.cod-estabel   = bDevol.cod-estabel
              AND bNota.nr-nota-fis   = bDevol.nr-nota-fis
              AND bNota.serie         = bDevol.serie
              AND bNota.cod-emitente  = bDevol.cod-emitente
              AND (pcPedidoDe = "" OR bNota.nr-pedcli >= pcPedidoDe)
              AND (pcPedidoAte = "" OR bNota.nr-pedcli <= pcPedidoAte)
              AND (piRepresentanteDe = ? OR bNota.cod-rep >= piRepresentanteDe)
              AND (piRepresentanteAte = ? OR bNota.cod-rep <= piRepresentanteAte),
            EACH bPedido NO-LOCK
            WHERE bPedido.nr-pedcli = bNota.nr-pedcli
              AND bPedido.nome-abrev = bNota.nome-ab-cli:

            IF NOT CAN-FIND(FIRST bPedRep WHERE bPedRep.nr-pedido = bPedido.nr-pedido) THEN NEXT venda.
            IF bPedido.cod-priori = ? OR bDoc.tot-valor = ? THEN
                UNDO, THROW NEW Progress.Lang.AppError("Valor ou prioridade desconhecido na devolucao", 1).

            ASSIGN iResto = (20 - bPedido.cod-priori) MODULO 10
                   dTaxa = iResto / 10
                   dDesconto = (bDoc.tot-valor * -1) / (1 - dTaxa) * dTaxa.
            RUN BuscarMotivos(OUTPUT cMotivos).

            CREATE tt-NF.
            ASSIGN tt-NF.cod-estabel = bDoc.cod-estabel
                   tt-NF.serie = bDoc.serie-docto
                   tt-NF.nf = bDoc.nro-docto
                   tt-NF.data = bDoc.dt-trans
                   tt-NF.nr-Pedido = bPedido.nr-pedido
                   tt-NF.nome-abrev = bNota.nome-ab-cli
                   tt-NF.nome-ab-reppri = bNota.no-ab-reppri
                   tt-NF.perc-comis = ?
                   tt-NF.cidade = bDoc.cidade
                   tt-NF.estado = bDoc.uf
                   tt-NF.vl-nota = bDoc.tot-valor * -1
                   tt-NF.vl-desconto = dDesconto
                   tt-NF.vl-bruto = (bDoc.tot-valor * -1) + dDesconto
                   tt-NF.descr-mot-dev = cMotivos.
            ASSIGN tt-NF.tipo-nota = bDoc.esp-docto
                   tt-NF.dt-emis-nota = bDoc.dt-emissao
                   tt-NF.nf-original = bNota.nr-nota-fis.
            RUN PreencherContextoNota.
            LEAVE venda.
        END.
    END.
    CATCH e AS Progress.Lang.Error:
        EMPTY TEMP-TABLE tt-NF.
        UNDO, THROW e.
    END CATCH.
END.

PROCEDURE BuscarMotivos:
    DEFINE OUTPUT PARAMETER pcDescricao AS CHARACTER NO-UNDO.
    EMPTY TEMP-TABLE ttMotivo.
    pcDescricao = "".
    FOR EACH bMotDevol NO-LOCK
        WHERE bMotDevol.cod-estabel = bDoc.cod-estabel
          AND bMotDevol.serie-docto = bDoc.serie-docto
          AND bMotDevol.nro-docto = bDoc.nro-docto
          AND bMotDevol.cod-emitente = bDoc.cod-emitente,
        EACH bRejeicao NO-LOCK
        WHERE bRejeicao.codigo-rejei = bMotDevol.codigo-rejei:
        IF CAN-FIND(FIRST ttMotivo WHERE ttMotivo.codigo = bRejeicao.codigo-rejei
                                      AND ttMotivo.descricao = bRejeicao.descricao) THEN NEXT.
        CREATE ttMotivo.
        ASSIGN ttMotivo.codigo = bRejeicao.codigo-rejei
               ttMotivo.descricao = bRejeicao.descricao.
    END.
    FOR EACH ttMotivo BY ttMotivo.codigo BY ttMotivo.descricao:
        pcDescricao = pcDescricao + TRIM(STRING(ttMotivo.codigo)) + " - " + ttMotivo.descricao + "|".
    END.
    pcDescricao = SUBSTRING(pcDescricao, 1, 200).
END PROCEDURE.

{esapi/consulta-notas/ConsultaNFContexto.i}
