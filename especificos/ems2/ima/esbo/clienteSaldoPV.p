BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Cliente da boSaldoPV: recebe criterios tipados, devolve resultados e status.
   Nao reproduz consultas complementares do PHP sem os filtros originais. */
{esbo/boSaldoPV.i}
DEFINE INPUT PARAMETER TABLE FOR ttFiltroSaldoPV.
DEFINE INPUT PARAMETER TABLE FOR ttSelecaoSaldoPV.
DEFINE OUTPUT PARAMETER TABLE FOR ttItensSaldoPV.
DEFINE OUTPUT PARAMETER TABLE FOR ttSaldoPV.
DEFINE OUTPUT PARAMETER sucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER mensagem AS CHARACTER NO-UNDO.

/* Copia local preserva entrada inclusive em chamadas BY-REFERENCE. */
DEFINE TEMP-TABLE ttFiltroExecSaldoPV NO-UNDO LIKE ttFiltroSaldoPV.
DEFINE VARIABLE hBo AS HANDLE NO-UNDO.
DEFINE VARIABLE quantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE i AS INTEGER NO-UNDO.
EMPTY TEMP-TABLE ttItensSaldoPV.
EMPTY TEMP-TABLE ttSaldoPV.
ASSIGN sucesso = NO mensagem = "".
FOR EACH ttFiltroSaldoPV:
    quantidade = quantidade + 1.
END.
IF quantidade <> 1 THEN DO:
    mensagem = "Informar exatamente uma linha em ttFiltroSaldoPV.".
    RETURN.
END.
FIND FIRST ttFiltroSaldoPV.
IF ttFiltroSaldoPV.buscarPE = NO AND ttFiltroSaldoPV.buscarPI = NO THEN DO:
    mensagem = "Selecionar ao menos uma origem: PE ou PI.".
    RETURN.
END.
IF ttFiltroSaldoPV.soLiquidacao = YES AND ttFiltroSaldoPV.buscarPE = NO THEN DO:
    mensagem = "Oportunidade de estoque exige a origem PE selecionada.".
    RETURN.
END.
CREATE ttFiltroExecSaldoPV.
BUFFER-COPY ttFiltroSaldoPV TO ttFiltroExecSaldoPV.
/* Regra do cliente PHP anterior ao helper: oportunidade decide por PE.
   exibirAmbosSaldos continua regendo a exibicao, com os filtros recebidos. */
IF ttFiltroExecSaldoPV.soLiquidacao = YES THEN ASSIGN
    ttFiltroExecSaldoPV.buscarPI = NO
    ttFiltroExecSaldoPV.tabelaPreco = 1.

DO ON ERROR UNDO, THROW:
    RUN esbo/boSaldoPV.p PERSISTENT SET hBo.
    RUN setParametros IN hBo(INPUT TABLE ttFiltroExecSaldoPV).
    RUN setSelecoes IN hBo(INPUT TABLE ttSelecaoSaldoPV).
    RUN exec IN hBo NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        mensagem = RETURN-VALUE.
        DO i = 1 TO ERROR-STATUS:NUM-MESSAGES:
            mensagem = mensagem + (IF mensagem = "" THEN "" ELSE " ") + ERROR-STATUS:GET-MESSAGE(i).
        END.
        IF mensagem = "" OR mensagem = ? THEN mensagem = "Falha ao executar a consulta de estoque.".
        RETURN.
    END.
    RUN getTTItens IN hBo(OUTPUT TABLE ttItensSaldoPV).
    RUN getTTSaldo IN hBo(OUTPUT TABLE ttSaldoPV).
    sucesso = YES.
    CATCH erro AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttItensSaldoPV.
        EMPTY TEMP-TABLE ttSaldoPV.
        ASSIGN sucesso = NO mensagem = "".
        DO i = 1 TO erro:NumMessages:
            mensagem = mensagem + (IF mensagem = "" THEN "" ELSE " ") + erro:GetMessage(i).
        END.
        IF mensagem = "" THEN mensagem = "Falha ao chamar a boSaldoPV.".
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hBo) THEN DELETE PROCEDURE hBo.
    END FINALLY.
END.
