BLOCK-LEVEL ON ERROR UNDO,THROW.
{esapi/consulta-notas/ttFiltroDevolucoes.i}
{esbo/boConsNotaFiscal.i}
DEFINE INPUT PARAMETER TABLE FOR ttFiltroDevolucoes.
DEFINE OUTPUT PARAMETER TABLE FOR tt-NF.
DEFINE TEMP-TABLE ttParcial LIKE tt-NF.
DEFINE BUFFER bOutroFiltro FOR ttFiltroDevolucoes.
DEFINE VARIABLE hNotas AS HANDLE NO-UNDO.
DEFINE VARIABLE hDevol AS HANDLE NO-UNDO.
EMPTY TEMP-TABLE tt-NF.
{esapi/consulta-notas/BuscarDevolucoesValidarFiltro.i}
DO ON ERROR UNDO,THROW:
    RUN esbo/boConsNotaFiscal.p PERSISTENT SET hNotas.
    RUN esbo/boConsDevolucoes.p PERSISTENT SET hDevol.
    RUN Configurar(hNotas).
    RUN Configurar(hDevol).
    RUN exec IN hNotas(OUTPUT TABLE ttParcial).
    RUN Acrescentar.
    RUN exec IN hDevol(OUTPUT TABLE ttParcial).
    RUN Acrescentar.
    CATCH e AS Progress.Lang.Error:
        EMPTY TEMP-TABLE tt-NF. UNDO,THROW e.
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hNotas) THEN RUN finalizarBo IN hNotas.
        IF VALID-HANDLE(hDevol) THEN RUN finalizarBo IN hDevol.
    END FINALLY.
END.
PROCEDURE Configurar:
    DEFINE INPUT PARAMETER phBo AS HANDLE NO-UNDO.
    RUN iniciarBo IN phBo.
    RUN setEmpresa IN phBo(ttFiltroDevolucoes.empresa).
    RUN setFaixaEstab IN phBo(ttFiltroDevolucoes.estabel-de,ttFiltroDevolucoes.estabel-ate).
    RUN setIntervalCliente IN phBo(ttFiltroDevolucoes.cliente-de,ttFiltroDevolucoes.cliente-ate).
    RUN setIntervalNotaFiscal IN phBo(ttFiltroDevolucoes.nota-de,ttFiltroDevolucoes.nota-ate).
    RUN setIntervalPedido IN phBo(ttFiltroDevolucoes.pedido-de,ttFiltroDevolucoes.pedido-ate).
    RUN setIntervalCodRepres IN phBo(ttFiltroDevolucoes.representante-de,ttFiltroDevolucoes.representante-ate).
    RUN setIntervalDtEmis IN phBo(ttFiltroDevolucoes.emissao-de,ttFiltroDevolucoes.emissao-ate).
END PROCEDURE.
PROCEDURE Acrescentar:
    FOR EACH ttParcial:
        CREATE tt-NF.
        BUFFER-COPY ttParcial TO tt-NF.
    END.
END PROCEDURE.
