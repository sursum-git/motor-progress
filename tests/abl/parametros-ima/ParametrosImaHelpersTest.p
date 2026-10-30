BLOCK-LEVEL ON ERROR UNDO, THROW.
DEFINE TEMP-TABLE ttParametroIma NO-UNDO
    FIELD cod-param AS CHARACTER FIELD val-param AS CHARACTER
    INDEX chave IS UNIQUE cod-param.
DEFINE VARIABLE iChecks AS INTEGER NO-UNDO.
DEFINE VARIABLE jaParams AS Progress.Json.ObjectModel.JsonArray NO-UNDO.
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA ttParametroIma
{sursum-api/includes/parametros_ima.i}
OUTPUT TO "parametros-helpers-tests.log".
DO ON ERROR UNDO, THROW:
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "base" ttParametroIma.val-param = "teste".
    RUN Check(getBase() = "teste", "getter consulta codigo original").
    ttParametroIma.val-param = "mudou".
    RUN Check(getBase() = "mudou", "getter nao usa cache").
    RUN Check(getVlMinFreteCIFSudeste("real") = "1500", "padrao CIW sudeste real").
    RUN Check(getVlMinFreteCIFSudeste("2") = "300", "padrao CIW sudeste dolar").
    RUN Check(getVlMinFreteCIF("1") = "2500", "CIF real").
    RUN Check(getVlMinFreteCIF("dolar") = "600", "CIF dolar").
    RUN Check(getHabilitarBonusRepres() = "0", "bonus ausente").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "habilitar_bonus_comissao" ttParametroIma.val-param = "".
    RUN Check(getHabilitarBonusRepres() = "0", "bonus vazio segue regra PHP").
    ttParametroIma.val-param = " ".
    RUN Check(ASC(getHabilitarBonusRepres()) = 32, "espaco em parametro preservado").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "PORTAL_MINUTOS_DESALOCAR_PE_LOJA" ttParametroIma.val-param = "15".
    RUN Check(getMinutosVenctoPe("1,2") = "15", "grupo loja explicito").
    RUN Check(getMinutosVenctoPe("1,3") = "", "outro grupo usa parametro normal").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "aprovar_ger_ped_web_pe" ttParametroIma.val-param = "PE".
    RUN Check(getAprovGerenciaPedWeb("pe") = "PE", "pedido PE").
    RUN Check(getAprovGerenciaPedWeb("pi") = "1", "pedido PI").
    CREATE ttParametroIma.
    ASSIGN ttParametroIma.cod-param = "caixa_nfe_504" ttParametroIma.val-param = "caixa-teste".
    RUN Check(getCaixaNFe("504") = "caixa-teste", "parametro por estabelecimento").
    RUN Check(getCaixaNFe("505") = "~{outlook.office365.com:993/imap/ssl~}INBOX", "fallback por estabelecimento").
    RUN Check(getSenhaApiTotvs() = "" AND getAutLogDb() = "" AND credBdConsultas() = "" AND getSenhaCaixaNFe("504") = "", "segredos sem default literal").
    RUN Check(getTiposVersaoValidNFMae() = "4,5", "getter exclusivo CIW").
    RUN Check(getTranspRedesp505() = "661", "getter adicional portal").
    RUN Check(limparVar("a-b.c", "-;.", ";") = "abc", "utilitario da biblioteca").
    RUN Check(limparVar("Aa", "a", ",") = "A", "substituicao diferencia maiusculas").
    RUN Check(limparVar("a-b.c", "-||.", "||") = "abc", "separador com varios caracteres").
    RUN Check(limparVar("a b", " ", ",") = "ab", "remove espacos").
    RUN Check(limparVar("a-b.c", "- .", " ") = "abc", "espaco como separador").
    RUN Check(getVlMinFreteCIF("REAL") = "600", "seletor de moeda igual ao PHP").
    RUN Check(getAprovGerenciaPedWeb("PE") = "1", "seletor de pedido igual ao PHP").
    jaParams = getParametros().
    RUN Check(jaParams:Length = 5, "lista parametros sem manter cache").
    DELETE OBJECT jaParams.
    PUT UNFORMATTED "PASS: " iChecks " verificacoes auxiliares" SKIP.
    CATCH e AS Progress.Lang.Error:
        PUT UNFORMATTED "FAIL: " e:GetMessage(1) SKIP.
    END CATCH.
END.
OUTPUT CLOSE.
QUIT.
PROCEDURE Check:
    DEFINE INPUT PARAMETER plOk AS LOGICAL NO-UNDO.
    DEFINE INPUT PARAMETER pcLabel AS CHARACTER NO-UNDO.
    IF plOk <> TRUE OR plOk = ? THEN UNDO, THROW NEW Progress.Lang.AppError(pcLabel, 0).
    iChecks = iChecks + 1.
END PROCEDURE.
