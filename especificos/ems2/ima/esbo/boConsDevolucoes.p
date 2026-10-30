/*************************************************************************
Programa: boConsDevolucoes.p
Objetivo: BO persistente para consultar devolucoes de vendas.
Contrato: filtros por procedimentos; retorno em tt-NF.
Estrutura: iniciarBo, limparContexto, exec e finalizarBo, como boConsNotaFiscal.
**************************************************************************/
BLOCK-LEVEL ON ERROR UNDO, THROW.

{esbo/boConsNotaFiscal.i}

DEFINE VARIABLE cEmpresa           AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabelDe         AS CHARACTER NO-UNDO.
DEFINE VARIABLE cEstabelAte        AS CHARACTER NO-UNDO.
DEFINE VARIABLE iClienteDe         AS INTEGER   NO-UNDO.
DEFINE VARIABLE iClienteAte        AS INTEGER   NO-UNDO.
DEFINE VARIABLE cNotaDe            AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNotaAte           AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPedidoDe          AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPedidoAte         AS CHARACTER NO-UNDO.
DEFINE VARIABLE iRepresentanteDe   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iRepresentanteAte  AS INTEGER   NO-UNDO.
DEFINE VARIABLE dtEmissaoDe        AS DATE      NO-UNDO.
DEFINE VARIABLE dtEmissaoAte       AS DATE      NO-UNDO.

RUN limparContexto.

PROCEDURE iniciarBo:
    RUN limparContexto.
END PROCEDURE.

PROCEDURE limparContexto:
    ASSIGN cEmpresa = ""
           cEstabelDe = "" cEstabelAte = ""
           iClienteDe = ? iClienteAte = ?
           cNotaDe = "" cNotaAte = ""
           cPedidoDe = "" cPedidoAte = ""
           iRepresentanteDe = ? iRepresentanteAte = ?
           dtEmissaoDe = ? dtEmissaoAte = ?.
    EMPTY TEMP-TABLE tt-NF.
END PROCEDURE.

PROCEDURE setEmpresa:
    DEFINE INPUT PARAMETER pcValor AS CHARACTER NO-UNDO.
    cEmpresa = pcValor.
END PROCEDURE.

/* Como no BO de nota fiscal, este procedimento recebe um estabelecimento. */
PROCEDURE setIntervalEstab:
    DEFINE INPUT PARAMETER pcValor AS CHARACTER NO-UNDO.
    RUN setFaixaEstab(pcValor, pcValor).
END PROCEDURE.

PROCEDURE setFaixaEstab:
    DEFINE INPUT PARAMETER pcDe  AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcAte AS CHARACTER NO-UNDO.
    ASSIGN cEstabelDe = pcDe cEstabelAte = pcAte.
END PROCEDURE.

PROCEDURE setCliente:
    DEFINE INPUT PARAMETER piValor AS INTEGER NO-UNDO.
    RUN setIntervalCliente(piValor, piValor).
END PROCEDURE.

PROCEDURE setIntervalCliente:
    DEFINE INPUT PARAMETER piDe  AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER piAte AS INTEGER NO-UNDO.
    ASSIGN iClienteDe = piDe iClienteAte = piAte.
END PROCEDURE.

PROCEDURE setNumeroPedido:
    DEFINE INPUT PARAMETER pcValor AS CHARACTER NO-UNDO.
    RUN setIntervalPedido(pcValor, pcValor).
END PROCEDURE.

PROCEDURE setIntervalPedido:
    DEFINE INPUT PARAMETER pcDe  AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcAte AS CHARACTER NO-UNDO.
    ASSIGN cPedidoDe = pcDe cPedidoAte = pcAte.
END PROCEDURE.

PROCEDURE setNotaFiscal:
    DEFINE INPUT PARAMETER pcValor AS CHARACTER NO-UNDO.
    RUN setIntervalNotaFiscal(pcValor, pcValor).
END PROCEDURE.

PROCEDURE setIntervalNotaFiscal:
    DEFINE INPUT PARAMETER pcDe  AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcAte AS CHARACTER NO-UNDO.
    ASSIGN cNotaDe = pcDe cNotaAte = pcAte.
END PROCEDURE.

PROCEDURE setRepres:
    DEFINE INPUT PARAMETER piValor AS INTEGER NO-UNDO.
    RUN setIntervalRepres(piValor, piValor).
END PROCEDURE.

PROCEDURE setIntervalRepres:
    DEFINE INPUT PARAMETER piDe  AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER piAte AS INTEGER NO-UNDO.
    ASSIGN iRepresentanteDe = piDe iRepresentanteAte = piAte.
END PROCEDURE.

PROCEDURE setIntervalCodRepres:
    DEFINE INPUT PARAMETER piDe AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER piAte AS INTEGER NO-UNDO.
    RUN setIntervalRepres(piDe,piAte).
END PROCEDURE.

PROCEDURE setIntervalDtEmis:
    DEFINE INPUT PARAMETER pdDe  AS DATE NO-UNDO.
    DEFINE INPUT PARAMETER pdAte AS DATE NO-UNDO.
    ASSIGN dtEmissaoDe = pdDe dtEmissaoAte = pdAte.
END PROCEDURE.

PROCEDURE exec:
    DEFINE OUTPUT PARAMETER TABLE FOR tt-NF.

    EMPTY TEMP-TABLE tt-NF.
    CASE cEmpresa:
        WHEN "IMA" THEN
            RUN esapi/consulta-notas/BuscarDevolucoesIMA.p (
                cEmpresa, cEstabelDe, cEstabelAte, iClienteDe, iClienteAte,
                cNotaDe, cNotaAte, cPedidoDe, cPedidoAte,
                iRepresentanteDe, iRepresentanteAte, dtEmissaoDe, dtEmissaoAte,
                OUTPUT TABLE tt-NF).
        WHEN "MED" THEN
            RUN esapi/consulta-notas/BuscarDevolucoesMED.p (
                cEmpresa, cEstabelDe, cEstabelAte, iClienteDe, iClienteAte,
                cNotaDe, cNotaAte, cPedidoDe, cPedidoAte,
                iRepresentanteDe, iRepresentanteAte, dtEmissaoDe, dtEmissaoAte,
                OUTPUT TABLE tt-NF).
        OTHERWISE UNDO, THROW NEW Progress.Lang.AppError("Empresa deve ser IMA ou MED", 1).
    END CASE.

    CATCH e AS Progress.Lang.Error:
        EMPTY TEMP-TABLE tt-NF.
        UNDO, THROW e.
    END CATCH.
END PROCEDURE.

PROCEDURE finalizarBo:
    RUN limparContexto.
    DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.
