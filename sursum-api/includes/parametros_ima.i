/* Funcoes de parametros IMA para programas ABL.
   Sem cache: cada chamada consulta espec.im-param NO-LOCK.
   Incluir apos as declaracoes e antes do corpo executavel do programa.
   Exemplo: cValor = buscarParametroIma("CODIGO_DO_PARAMETRO", "padrao").
*/
&IF DEFINED(SURSUM_PARAMETROS_IMA_INCLUIDA) = 0 &THEN
&GLOBAL-DEFINE SURSUM_PARAMETROS_IMA_INCLUIDA
&IF DEFINED(SURSUM_PARAMETROS_IMA_TABELA) = 0 &THEN
&SCOPED-DEFINE SURSUM_PARAMETROS_IMA_TABELA espec.im-param
&ENDIF

FUNCTION buscarParametroIma RETURNS CHARACTER
    (INPUT pcParametro AS CHARACTER, INPUT pcValorPadrao AS CHARACTER):
    DEFINE BUFFER bParametroIma FOR {&SURSUM_PARAMETROS_IMA_TABELA}.

    FOR FIRST bParametroIma NO-LOCK
        WHERE bParametroIma.cod-param = pcParametro:
        RETURN bParametroIma.val-param.
    END.
    RETURN pcValorPadrao.
END FUNCTION.




/* AUXILIARES PARAMETROS IMA - retorno CHARACTER, leitura sem cache. */
FUNCTION getMinutosVenctoPi RETURNS CHARACTER ():
    RETURN buscarParametroIma("PORTAL_MINUTOS_DESALOCAR_PI", "").
END FUNCTION.

FUNCTION getHabilitarBonusRepres RETURNS CHARACTER ():
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    cValor = buscarParametroIma("habilitar_bonus_comissao", "").
    IF LENGTH(cValor) = 0 THEN RETURN "0".
    RETURN cValor.
END FUNCTION.

FUNCTION getBase RETURNS CHARACTER ():
    RETURN buscarParametroIma("base", "").
END FUNCTION.

FUNCTION getMudancaMoeda RETURNS CHARACTER ():
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    cValor = buscarParametroIma("pv_mudar_moeda", "").
    IF LENGTH(cValor) = 0 THEN RETURN "0".
    RETURN cValor.
END FUNCTION.

FUNCTION getParamPrecoTbERP RETURNS CHARACTER ():
    RETURN buscarParametroIma("buscar_preco_tb_erp", "1").
END FUNCTION.

FUNCTION getPrecoTbLiquidaIma RETURNS CHARACTER ():
    RETURN buscarParametroIma("buscar_preco_tb_liquida_ima", "1").
END FUNCTION.

FUNCTION getParamGrupoAvalAdm RETURNS CHARACTER ():
    RETURN buscarParametroIma("grupo_aval_adm", "12").
END FUNCTION.

FUNCTION getPercRedTbRubi RETURNS CHARACTER ():
    RETURN buscarParametroIma("perc_reduc_tb_rubi", "50").
END FUNCTION.

FUNCTION getIdTbRubi RETURNS CHARACTER ():
    RETURN buscarParametroIma("tb_rubi_id", "2").
END FUNCTION.

FUNCTION getAutLogDb RETURNS CHARACTER ():
    /* Credencial deve estar configurada em im-param; sem senha padrao no fonte. */
    RETURN buscarParametroIma("aut_log_db", "").
END FUNCTION.

FUNCTION getUserLogDb RETURNS CHARACTER ():
    RETURN buscarParametroIma("user_log_db", "sa").
END FUNCTION.

FUNCTION credBdConsultas RETURNS CHARACTER ():
    /* Credencial deve estar configurada em im-param; sem senha padrao no fonte. */
    RETURN buscarParametroIma("cred_bd_consulta", "").
END FUNCTION.

FUNCTION getDirArqOutlet RETURNS CHARACTER ():
    RETURN buscarParametroIma("dir_arq_outlet", "").
END FUNCTION.

FUNCTION getCaminhoArqCampanha RETURNS CHARACTER ():
    RETURN buscarParametroIma("dir_arq_campanha", "/var/www/clients/client1/web2/web/iol_homolog/_lib/file/doc").
END FUNCTION.

FUNCTION getDirTmpBook RETURNS CHARACTER ():
    RETURN buscarParametroIma("dir_tmp_book", "/var/www/clients/client1/web2/web/tmp").
END FUNCTION.

FUNCTION getUrlServico RETURNS CHARACTER ():
    RETURN buscarParametroIma("url_api_totvs", "192.168.0.38:8180/api/").
END FUNCTION.

FUNCTION getUserApiTotvs RETURNS CHARACTER ():
    RETURN buscarParametroIma("usuario_api_totvs", "apitotvs").
END FUNCTION.

FUNCTION getSenhaApiTotvs RETURNS CHARACTER ():
    /* Credencial deve estar configurada em im-param; sem senha padrao no fonte. */
    RETURN buscarParametroIma("senha_api_totvs", "").
END FUNCTION.

FUNCTION getVersaoApiHomolog RETURNS CHARACTER ():
    RETURN buscarParametroIma("versao_api_homolog", "v99").
END FUNCTION.

FUNCTION getApiHistAvalPedVenda RETURNS CHARACTER ():
    RETURN buscarParametroIma("api_histAvalPedVenda", "pdp/v1/histAvalPedVenda").
END FUNCTION.

FUNCTION getApiValidIncItemContainer RETURNS CHARACTER ():
    RETURN buscarParametroIma("api_valid_inc_item_container", "cdp/v1/validarItemContainer").
END FUNCTION.

FUNCTION getAprovGerenciaPedWebPe RETURNS CHARACTER ():
    RETURN buscarParametroIma("aprovar_ger_ped_web_pe", "1").
END FUNCTION.

FUNCTION getAprovGerenciaPedWebPi RETURNS CHARACTER ():
    RETURN buscarParametroIma("aprovar_ger_ped_web_pi", "1").
END FUNCTION.

FUNCTION getConsiderarDepositoFechado RETURNS CHARACTER ():
    RETURN buscarParametroIma("considerar_deposito_fechado", "1").
END FUNCTION.

FUNCTION getEstabDepositoFechado RETURNS CHARACTER ():
    RETURN buscarParametroIma("cod_estab_deposito_fechado", "504").
END FUNCTION.

FUNCTION getCodDeposDepositoFechado RETURNS CHARACTER ():
    RETURN buscarParametroIma("cod_depos_deposito_fechado", "ter").
END FUNCTION.

FUNCTION getTiposVersaoValidNFMae RETURNS CHARACTER ():
    RETURN buscarParametroIma("tipo_versao_valida_nf", "4,5").
END FUNCTION.

FUNCTION getParamDistrCusto RETURNS CHARACTER ():
    RETURN buscarParametroIma("gerar_distr_custo", "0").
END FUNCTION.

FUNCTION getQtDiasCalcPrevChegadaPedImp RETURNS CHARACTER ():
    RETURN buscarParametroIma("qt_dias_calc_cheg_ped", "60").
END FUNCTION.

FUNCTION getListaNatOperNotaMae RETURNS CHARACTER ():
    RETURN buscarParametroIma("NAT-OPERACAO-IMP", "").
END FUNCTION.

FUNCTION getListaNatOperNotaCompl RETURNS CHARACTER ():
    RETURN buscarParametroIma("nat_operacao_nf_compl", "").
END FUNCTION.

FUNCTION getQtDiasBuscaDocManif RETURNS CHARACTER ():
    RETURN buscarParametroIma("qt_dias_busca_doc_manif", "90").
END FUNCTION.

FUNCTION getWSDLManifTSS RETURNS CHARACTER ():
    RETURN buscarParametroIma("wsdl_manif_tss", "http://192.168.0.30:8080/MANIFESTACAODESTINATARIO.apw?WSDL").
END FUNCTION.

FUNCTION getFuncaoManifTSS RETURNS CHARACTER ():
    RETURN buscarParametroIma("funcao_manif_tss", "BAIXARXMLDOCUMENTOS").
END FUNCTION.

FUNCTION getNumAmbienteTSS RETURNS CHARACTER ():
    RETURN buscarParametroIma("num_amb_tss", "1").
END FUNCTION.

FUNCTION getParamBuscarXmlTss RETURNS CHARACTER ():
    RETURN buscarParametroIma("buscar_xml_tss", "1").
END FUNCTION.

FUNCTION getSubDirAnexosXml RETURNS CHARACTER ():
    RETURN buscarParametroIma("subpastas_xml", ",lidos,Error,invalidos").
END FUNCTION.

FUNCTION getUrlBookPorDemanda RETURNS CHARACTER ():
    RETURN buscarParametroIma("url_book_demanda", "http://desenv.imatextil.com.br/sc94/app/imaonline/bl_gerar_book_por_demanda/bl_gerar_book_por_demanda.php").
END FUNCTION.

FUNCTION getTranspRedesp505 RETURNS CHARACTER ():
    RETURN buscarParametroIma("cod_transp_redesp_505", "661").
END FUNCTION.

FUNCTION getTranspRedesp5 RETURNS CHARACTER ():
    RETURN buscarParametroIma("cod_transp_redesp_5", "355").
END FUNCTION.

FUNCTION getNumModeloRegraFrete RETURNS CHARACTER ():
    RETURN buscarParametroIma("num_modelo_regra_frete", "1").
END FUNCTION.

FUNCTION getDirPV RETURNS CHARACTER ():
    RETURN buscarParametroIma("dir_pv", "iol").
END FUNCTION.

FUNCTION getFormaCalculoTipoFrete RETURNS CHARACTER ():
    RETURN buscarParametroIma("forma_calculo_tipo_frete", "codigo").
END FUNCTION.

FUNCTION getInstanciaMegaAPi RETURNS CHARACTER ():
    RETURN buscarParametroIma("instancia_mega_api", "").
END FUNCTION.

FUNCTION getTokenMegaAPi RETURNS CHARACTER ():
    /* Credencial deve estar configurada em im-param; sem senha padrao no fonte. */
    RETURN buscarParametroIma("token_mega_api", "").
END FUNCTION.

FUNCTION getHostMegaApi RETURNS CHARACTER ():
    RETURN buscarParametroIma("host_mega_api", "").
END FUNCTION.

/* Grupos do usuario devem ser fornecidos pelo backend autenticado.
   Mantem a regra de strstr(listaGrupos, "2") da biblioteca PHP. */
FUNCTION getMinutosVenctoPe RETURNS CHARACTER (INPUT pcGrupos AS CHARACTER):
    IF pcGrupos <> ? AND INDEX(pcGrupos, "2") > 0 THEN
        RETURN buscarParametroIma("PORTAL_MINUTOS_DESALOCAR_PE_LOJA", "").
    RETURN buscarParametroIma("PORTAL_MINUTOS_DESALOCAR_PE", "").
END FUNCTION.

FUNCTION getVlMinFreteCIFSudeste RETURNS CHARACTER (INPUT pcMoeda AS CHARACTER):
    DEFINE VARIABLE cMoeda AS CHARACTER CASE-SENSITIVE NO-UNDO.
    cMoeda = pcMoeda.
    IF cMoeda = "1" OR cMoeda = "real" THEN
        RETURN buscarParametroIma("vl_min_cif_sudeste", "1500").
    RETURN buscarParametroIma("vl_min_cif_sudeste_dolar", "300").
END FUNCTION.

FUNCTION getVlMinFreteCIF RETURNS CHARACTER (INPUT pcMoeda AS CHARACTER):
    DEFINE VARIABLE cMoeda AS CHARACTER CASE-SENSITIVE NO-UNDO.
    cMoeda = pcMoeda.
    IF cMoeda = "1" OR cMoeda = "real" THEN
        RETURN buscarParametroIma("vl_min_cif", "2500").
    RETURN buscarParametroIma("vl_min_cif_dolar", "600").
END FUNCTION.

FUNCTION getAprovGerenciaPedWeb RETURNS CHARACTER (INPUT pcTipoPed AS CHARACTER):
    DEFINE VARIABLE cTipoPed AS CHARACTER CASE-SENSITIVE NO-UNDO.
    cTipoPed = pcTipoPed.
    IF cTipoPed = "pe" THEN RETURN getAprovGerenciaPedWebPe().
    RETURN getAprovGerenciaPedWebPi().
END FUNCTION.

/* Raiz web explicita para o backend ABL; nao inferir pelo diretorio PASOE. */
FUNCTION getDirRaizWeb RETURNS CHARACTER ():
    RETURN buscarParametroIma("diretorio_raiz_web", "/var/www/clients/client1/web2/web").
END FUNCTION.

FUNCTION getDirAnexosEmail RETURNS CHARACTER (INPUT pcEstab AS CHARACTER):
    RETURN buscarParametroIma("dir_anexo_email_" + pcEstab, RIGHT-TRIM(getDirRaizWeb(), "/") + "/dfe").
END FUNCTION.

FUNCTION getDirRelAnexosEmail RETURNS CHARACTER (INPUT pcEstab AS CHARACTER):
    RETURN buscarParametroIma("dir_rel_anexo_email_" + pcEstab, "../../dfe").
END FUNCTION.

FUNCTION getCaixaNFe RETURNS CHARACTER (INPUT pcEstab AS CHARACTER):
    RETURN buscarParametroIma("caixa_nfe_" + pcEstab, "~{outlook.office365.com:993/imap/ssl~}INBOX").
END FUNCTION.

FUNCTION getUsuarioCaixaNFe RETURNS CHARACTER (INPUT pcEstab AS CHARACTER):
    RETURN buscarParametroIma("usr_caixa_nfe_" + pcEstab, "nfe.medtextil@imatextil.com.br").
END FUNCTION.

FUNCTION getSenhaCaixaNFe RETURNS CHARACTER (INPUT pcEstab AS CHARACTER):
    RETURN buscarParametroIma("senha_caixa_nfe_" + pcEstab, "").
END FUNCTION.

FUNCTION getDirArquivoCsvImpPreco RETURNS CHARACTER ():
    RETURN buscarParametroIma("dir_csv_imp_preco", RIGHT-TRIM(getDirRaizWeb(), "/") + "/" + getDirPV() + "/_lib/file/doc/item_preco").
END FUNCTION.

/* Colecao somente no backend; pode conter configuracao sensivel.
   Nao serializar indiscriminadamente em respostas de API ou logs. */
FUNCTION getParametros RETURNS Progress.Json.ObjectModel.JsonArray ():
    DEFINE BUFFER bListaParametrosIma FOR {&SURSUM_PARAMETROS_IMA_TABELA}.
    DEFINE VARIABLE jaResultado AS Progress.Json.ObjectModel.JsonArray NO-UNDO.
    DEFINE VARIABLE joParametro AS Progress.Json.ObjectModel.JsonObject NO-UNDO.
    jaResultado = NEW Progress.Json.ObjectModel.JsonArray().
    FOR EACH bListaParametrosIma NO-LOCK BY bListaParametrosIma.cod-param:
        joParametro = NEW Progress.Json.ObjectModel.JsonObject().
        IF bListaParametrosIma.cod-param = ? THEN joParametro:AddNull("cod-param").
        ELSE joParametro:Add("cod-param", bListaParametrosIma.cod-param).
        IF bListaParametrosIma.val-param = ? THEN joParametro:AddNull("val-param").
        ELSE joParametro:Add("val-param", bListaParametrosIma.val-param).
        jaResultado:Add(joParametro).
    END.
    RETURN jaResultado.
END FUNCTION.

FUNCTION limparVar RETURNS CHARACTER
    (INPUT pcValor AS CHARACTER, INPUT pcCaracteres AS CHARACTER, INPUT pcSeparador AS CHARACTER):
    DEFINE VARIABLE cResultado AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE cRestante AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE cParte AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    IF pcSeparador = ? OR LENGTH(pcSeparador) = 0 THEN
        UNDO, THROW NEW Progress.Lang.AppError("Separador nao pode ser vazio.", 0).
    IF pcCaracteres = ? THEN RETURN pcValor.
    cResultado = pcValor.
    cRestante = pcCaracteres.
    REPEAT:
        i = INDEX(cRestante, pcSeparador).
        IF i = 0 THEN cParte = cRestante.
        ELSE cParte = SUBSTRING(cRestante, 1, i - 1).
        IF LENGTH(cParte) > 0 THEN cResultado = REPLACE(cResultado, cParte, "").
        IF i = 0 THEN LEAVE.
        cRestante = SUBSTRING(cRestante, i + LENGTH(pcSeparador)).
    END.
    RETURN cResultado.
END FUNCTION.
&ENDIF
