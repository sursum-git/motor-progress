BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE TEMP-TABLE ttParametroIma NO-UNDO
    FIELD cod-param AS CHARACTER
    FIELD val-param AS CHARACTER
    INDEX chave IS UNIQUE cod-param.
DEFINE VARIABLE iChecks AS INTEGER NO-UNDO.
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA ttParametroIma
{sursum-api/includes/parametros_ima.i}
{sursum-api/includes/parametros_ima.i}
OUTPUT TO "parametros-tests.log".
DO ON ERROR UNDO, THROW:
    RUN Check(buscarParametroIma("ausente", "padrao") = "padrao", "parametro ausente usa padrao").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "exemplo" ttParametroIma.val-param = "Acentuação".
    RUN Check(buscarParametroIma("exemplo", "") = "Acentuação", "consulta valor Unicode").
    ttParametroIma.val-param = "alterado".
    RUN Check(buscarParametroIma("exemplo", "") = "alterado", "alteracao visivel imediatamente sem cache").
    ttParametroIma.val-param = "".
    RUN Check(buscarParametroIma("exemplo", "padrao") = "", "vazio existente preservado").
    ttParametroIma.val-param = ?.
    RUN Check(buscarParametroIma("exemplo", "padrao") = ?, "desconhecido existente preservado").
    DELETE ttParametroIma.
    RUN Check(buscarParametroIma("exemplo", "removido") = "removido", "exclusao visivel sem cache").
    RUN Check(buscarParametroIma("ausente", "outro") = "outro", "padrao determinado pelo chamador").
    RUN Check(buscarParametroIma("", "vazio") = "vazio", "chave vazia").
    RUN Check(buscarParametroIma(?, "desconhecido") = "desconhecido", "chave desconhecida").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "" ttParametroIma.val-param = "chave vazia existente".
    VALIDATE ttParametroIma.
    RUN Check(buscarParametroIma("", "padrao") = "chave vazia existente", "chave vazia existente consultada").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = ? ttParametroIma.val-param = "chave desconhecida existente".
    VALIDATE ttParametroIma.
    RUN Check(buscarParametroIma(?, "padrao") = "chave desconhecida existente", "chave desconhecida existente consultada").
    PUT UNFORMATTED "PASS: " iChecks " verificacoes parametros sem cache" SKIP.
    CATCH e AS Progress.Lang.Error:
        PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
    END CATCH.
END.
OUTPUT CLOSE.
QUIT.
PROCEDURE Check:
    DEFINE INPUT PARAMETER plOk AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
    IF plOk <> TRUE OR plOk = ? THEN
        UNDO, THROW NEW Progress.Lang.AppError(pcLabel, 0).
    iChecks = iChecks + 1.
END PROCEDURE.
