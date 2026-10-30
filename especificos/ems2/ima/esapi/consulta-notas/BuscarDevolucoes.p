/* Adaptador do chamador: traduz sua TT em procedimentos da BO. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
{esapi/consulta-notas/ttFiltroDevolucoes.i}
{esbo/boConsNotaFiscal.i}
DEFINE INPUT PARAMETER TABLE FOR ttFiltroDevolucoes.
DEFINE OUTPUT PARAMETER TABLE FOR tt-NF.
DEFINE BUFFER bOutroFiltro FOR ttFiltroDevolucoes.
DEFINE VARIABLE hBo AS HANDLE NO-UNDO.

EMPTY TEMP-TABLE tt-NF.
{esapi/consulta-notas/BuscarDevolucoesValidarFiltro.i}

DO ON ERROR UNDO, THROW:
    RUN esbo/boConsDevolucoes.p PERSISTENT SET hBo.
    RUN iniciarBo IN hBo.
    RUN setEmpresa IN hBo(ttFiltroDevolucoes.empresa).
    RUN setFaixaEstab IN hBo(ttFiltroDevolucoes.estabel-de, ttFiltroDevolucoes.estabel-ate).
    RUN setIntervalCliente IN hBo(ttFiltroDevolucoes.cliente-de, ttFiltroDevolucoes.cliente-ate).
    RUN setIntervalNotaFiscal IN hBo(ttFiltroDevolucoes.nota-de, ttFiltroDevolucoes.nota-ate).
    RUN setIntervalPedido IN hBo(ttFiltroDevolucoes.pedido-de, ttFiltroDevolucoes.pedido-ate).
    RUN setIntervalRepres IN hBo(ttFiltroDevolucoes.representante-de, ttFiltroDevolucoes.representante-ate).
    RUN setIntervalDtEmis IN hBo(ttFiltroDevolucoes.emissao-de, ttFiltroDevolucoes.emissao-ate).
    RUN exec IN hBo(OUTPUT TABLE tt-NF).
    FINALLY:
        IF VALID-HANDLE(hBo) THEN RUN finalizarBo IN hBo.
    END FINALLY.
END.
