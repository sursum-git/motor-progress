BLOCK-LEVEL ON ERROR UNDO, THROW.
/* Derivada de esbo/boSaldo.p (08/2025), sem alterar o contrato original.
   1 selecionarItens: propriedades -> ttItensSaldoPV.
   2 preencherSaldos: fisico/programado e componentes -> ttSaldoPV/totais.
   3 filtrarSaldos: limites por origem -> itens e saldos sobreviventes.
   Esta especializacao usa ems2med + espec; nao troca conexoes por parametro.
   Defaults e regras confirmados nos helpers PHP IOL em20/10/2026.
   Nao se presume que todo estado <>4 consome estoque.
*/
{esbo/boSaldoPV.i}
DEFINE VARIABLE etapa AS INTEGER NO-UNDO.
DEFINE VARIABLE detalhar AS LOGICAL NO-UNDO.
DEFINE BUFFER f FOR ttFiltroSaldoPV.
DEFINE BUFFER sel FOR ttSelecaoSaldoPV.
DEFINE BUFFER bItem FOR ems2med.item.
DEFINE BUFFER bExt FOR espec.item-ext.
DEFINE BUFFER bEstoque FOR ems2med.saldo-estoq.
DEFINE BUFFER bProgramado FOR espec.pp-it-container.
DEFINE BUFFER bContainer FOR espec.pp-container.
DEFINE BUFFER bPermissao FOR espec.pp_container_permissao.
DEFINE BUFFER bLocal FOR espec.locais_estoq_portal.
DEFINE BUFFER bPreco FOR espec.controle_preco.
DEFINE BUFFER bLiquidacao FOR espec.liquida-ima.
DEFINE BUFFER bGrupo FOR espec.usuarios_grupos.
DEFINE VARIABLE temLiquidacao AS LOGICAL NO-UNDO.
DEFINE VARIABLE pesquisaLivre AS LOGICAL NO-UNDO.
DEFINE VARIABLE pesquisaSoCodigos AS LOGICAL NO-UNDO.
DEFINE TEMP-TABLE ttTermoItemPV NO-UNDO
    FIELD termo AS CHARACTER
    FIELD numerico AS LOGICAL
    INDEX chave IS PRIMARY UNIQUE termo.
DEFINE TEMP-TABLE ttLocalPV NO-UNDO
    FIELD estab AS CHARACTER
    FIELD deposito AS CHARACTER
    INDEX chave IS PRIMARY UNIQUE estab deposito.
DEFINE TEMP-TABLE ttLiquidacaoPV NO-UNDO
    FIELD item AS CHARACTER
    INDEX chave IS PRIMARY UNIQUE item.
DEFINE TEMP-TABLE ttTotalQuantidadePV NO-UNDO
    FIELD origem AS CHARACTER
    FIELD item AS CHARACTER
    FIELD minimo AS DECIMAL
    FIELD total AS DECIMAL
    FIELD aprovadas AS INTEGER
    INDEX chave IS PRIMARY UNIQUE origem item
    INDEX item item.

{sursum-api/includes/parametros_ima.i}
{esbo/termosPesquisaEstoque.i}

FUNCTION termoNumerico RETURNS LOGICAL (texto AS CHARACTER):
    RETURN termoBuscaNumerico(texto).
END FUNCTION.

FUNCTION contemComoLike RETURNS LOGICAL (texto AS CHARACTER, termo AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE c AS CHARACTER NO-UNDO.
    DEFINE VARIABLE padrao AS CHARACTER NO-UNDO INITIAL "*".
    IF texto = ? THEN RETURN FALSE.
    DO i = 1 TO LENGTH(termo):
        c = SUBSTRING(termo, i, 1).
        CASE c:
            WHEN "%" THEN padrao = padrao + "*".
            WHEN "_" THEN padrao = padrao + ".".
            WHEN "*" OR WHEN "." OR WHEN CHR(126) THEN padrao = padrao + CHR(126) + c.
            OTHERWISE padrao = padrao + c.
        END CASE.
    END.
    RETURN CAPS(texto) MATCHES CAPS(padrao + "*").
END FUNCTION.

FUNCTION pesquisaPermitida RETURNS LOGICAL (codigo AS CHARACTER, descricao AS CHARACTER):
    DEFINE BUFFER t FOR ttTermoItemPV.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE palavra AS CHARACTER NO-UNDO.
    DEFINE VARIABLE todas AS LOGICAL NO-UNDO.
    IF pesquisaLivre THEN RETURN TRUE.
    FOR EACH t:
        IF t.numerico THEN DO:
            IF codigo = t.termo THEN RETURN TRUE.
        END.
        ELSE DO:
            IF contemComoLike(descricao, t.termo) THEN RETURN TRUE.
            todas = TRUE.
            DO i = 1 TO NUM-ENTRIES(t.termo, " "):
                palavra = ENTRY(i, t.termo, " ").
                IF palavra <> "" AND NOT contemComoLike(descricao, palavra) THEN DO:
                    todas = FALSE.
                    LEAVE.
                END.
            END.
            IF todas THEN RETURN TRUE.
        END.
    END.
    RETURN FALSE.
END FUNCTION.

FUNCTION membro RETURNS LOGICAL
    (tipo AS CHARACTER, codigo AS CHARACTER, codigo2 AS CHARACTER, numero AS INTEGER):
    RETURN CAN-FIND(FIRST sel WHERE sel.tipo = tipo AND sel.codigo = codigo
        AND sel.codigo2 = codigo2 AND sel.numero = numero).
END FUNCTION.

FUNCTION referenciaPermitida RETURNS LOGICAL (referencia AS CHARACTER):
    RETURN NOT f.selecaoReferenciasAtiva OR membro("REF", referencia, "", 0).
END FUNCTION.

FUNCTION localPermitido RETURNS LOGICAL (estab AS CHARACTER, deposito AS CHARACTER):
    /* Estabelecimentos explicitos substituem os locais, como no PHP. */
    IF f.selecaoEstabsAtiva THEN RETURN membro("ESTAB", estab, "", 0).
    IF f.selecaoLocaisAtiva THEN RETURN membro("LOCAL", estab, deposito, 0).
    RETURN CAN-FIND(FIRST ttLocalPV WHERE ttLocalPV.estab = estab
        AND ttLocalPV.deposito = deposito).
END FUNCTION.

FUNCTION precoElegivel RETURNS LOGICAL (item AS CHARACTER):
    DEFINE VARIABLE tabela AS INTEGER NO-UNDO.
    IF f.usarSelecoesEspeciais THEN RETURN membro("PRECO", item, "", 0).
    tabela = IF f.tabelaPrecoFiltro > 0 THEN f.tabelaPrecoFiltro ELSE f.tabelaPreco.
    /* Compatibilidade literal: getPrecoTbERP retorna array inclusive log_achou=0;
       getExistPrecoItemRefTb testa is_array e portanto libera tabela1/ERP. */
    IF tabela = 1 AND buscarParametroIma("buscar_preco_tb_erp", "1") = "1" THEN RETURN TRUE.
    RETURN CAN-FIND(FIRST bPreco WHERE bPreco.it_codigo = item
        AND bPreco.tb_preco_id = tabela AND bPreco.dt_inicial <= TODAY
        AND bPreco.dt_final >= TODAY AND bPreco.log_vencido = NO).
END FUNCTION.

PROCEDURE iniciar:
    RUN limparResultados.
    EMPTY TEMP-TABLE ttFiltroSaldoPV.
    EMPTY TEMP-TABLE ttSelecaoSaldoPV.
END PROCEDURE.

PROCEDURE limparResultados:
    EMPTY TEMP-TABLE ttItensSaldoPV.
    EMPTY TEMP-TABLE ttSaldoPV.
    EMPTY TEMP-TABLE ttLocalPV.
    EMPTY TEMP-TABLE ttLiquidacaoPV.
    EMPTY TEMP-TABLE ttTotalQuantidadePV.
    EMPTY TEMP-TABLE ttTermoItemPV.
    ASSIGN pesquisaLivre = NO pesquisaSoCodigos = NO.
    ASSIGN etapa = 0 detalhar = NO temLiquidacao = NO.
END PROCEDURE.

PROCEDURE setParametros:
    DEFINE INPUT PARAMETER TABLE FOR ttFiltroSaldoPV.
    RUN limparResultados.
END PROCEDURE.

PROCEDURE setSelecoes:
    DEFINE INPUT PARAMETER TABLE FOR ttSelecaoSaldoPV.
    RUN limparResultados.
END PROCEDURE.

PROCEDURE validarEstados:
    DEFINE INPUT PARAMETER lista AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE valor AS INTEGER NO-UNDO.
    IF lista = "NENHUMA" THEN RETURN.
    IF lista = ? OR TRIM(lista) = "" THEN
        RETURN ERROR "Informar estados web explicitamente (ou NENHUMA).".
    DO i = 1 TO NUM-ENTRIES(lista):
        valor = INTEGER(ENTRY(i, lista)) NO-ERROR.
        IF ERROR-STATUS:ERROR OR valor = ? THEN RETURN ERROR "Estado web invalido.".
        IF valor < 1 OR STRING(valor) <> ENTRY(i, lista) THEN
            RETURN ERROR "Estados web devem ser inteiros positivos sem espacos.".
    END.
END PROCEDURE.

PROCEDURE validar:
    DEFINE VARIABLE quantidade AS INTEGER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    FOR EACH ttFiltroSaldoPV:
        quantidade = quantidade + 1.
    END.
    IF quantidade <> 1 THEN RETURN ERROR "ttFiltroSaldoPV exige exatamente uma linha.".
    FIND FIRST f.
    IF f.empresa = ? OR TRIM(f.empresa) = "" OR SUBSTRING(f.empresa, 1, 1) <> "5" THEN
        RETURN ERROR "boSaldoPV usa ems2med; informar empresa MED (prefixo 5).".
    IF f.buscarPE = ? OR f.buscarPI = ? OR f.exibirAmbosSaldos = ? OR f.considerarWeb = ?
    OR f.porReferencia = ? OR f.consultaReferencias = ? OR f.soLiquidacao = ? OR f.filtroTabelaPreco = ?
    OR f.selecaoItensAtiva = ? OR f.selecaoReferenciasAtiva = ?
    OR f.selecaoEstabsAtiva = ? OR f.selecaoLocaisAtiva = ?
    OR f.selecaoContainersAtiva = ? THEN RETURN ERROR "Indicadores obrigatorios invalidos.".
    IF f.usarSelecoesEspeciais = ? OR f.tipoUsuario = ? OR f.tipoUsuario < 0
    OR f.grupoEstoqueIni = ? OR f.grupoEstoqueFim = ?
    OR f.grupoEstoqueIni > f.grupoEstoqueFim OR f.tabelaPreco = ? OR f.tabelaPreco < 1
    OR f.tabelaPrecoFiltro = ? OR f.tabelaPrecoFiltro < 0 THEN
        RETURN ERROR "Parametros de grupos/tabela/tipo de usuario invalidos.".
    IF f.login = ? OR f.itemIni = ? OR f.itemFim = ? OR f.itemContem = ? OR f.pesquisaItem = ?
    OR f.familiaIni = ? OR f.familiaFim = ? OR f.unidade = ? THEN
        RETURN ERROR "Criterios texto desconhecidos; usar vazio para limite aberto.".
    /* Compatibilidade com chamadores que ainda enviam fim vazio. */
    IF f.itemFim = "" THEN f.itemFim = "zzzzzzzzzzzzzz".
    IF f.familiaFim = "" THEN f.familiaFim = "zzzzzzzzzzzzzz".
    IF (f.itemIni <> "" AND f.itemFim <> "" AND f.itemIni > f.itemFim)
    OR (f.familiaIni <> "" AND f.familiaFim <> "" AND f.familiaIni > f.familiaFim)
    OR (f.gramaturaIni <> ? AND f.gramaturaFim <> ? AND f.gramaturaIni > f.gramaturaFim)
    OR (f.pesoLiquidoIni <> ? AND f.pesoLiquidoFim <> ? AND f.pesoLiquidoIni > f.pesoLiquidoFim)
    THEN RETURN ERROR "Faixa de propriedades invertida.".
    IF f.minimoKG = ? OR f.minimoMT = ? OR f.minimoKG < 0 OR f.minimoMT < 0
    OR (f.maximoKG <> ? AND f.maximoKG < f.minimoKG)
    OR (f.maximoMT <> ? AND f.maximoMT < f.minimoMT)
    THEN RETURN ERROR "Limites de quantidade invalidos.".
    IF f.estabADefinir = ? OR LOOKUP(STRING(f.estabADefinir), "0,1,2") = 0
    OR f.containerADefinir = ? OR LOOKUP(STRING(f.containerADefinir), "0,1") = 0 THEN
        RETURN ERROR "Modo a definir invalido.".
    IF f.considerarWeb THEN DO:
        RUN validarEstados(f.situacoesCarrinho).
        RUN validarEstados(f.situacoesNaoIntegradas).
        IF f.situacoesCarrinho <> "NENHUMA" THEN DO i = 1 TO NUM-ENTRIES(f.situacoesCarrinho):
            IF LOOKUP(ENTRY(i, f.situacoesCarrinho), f.situacoesNaoIntegradas) > 0 THEN
                RETURN ERROR "Estado web nao pode ser carrinho e nao integrado ao mesmo tempo.".
        END.
    END.
    FOR EACH sel:
        IF LOOKUP(sel.tipo, "ITEM,REF,ESTAB,LOCAL,CONTAINER,LIQUIDACAO,PRECO,CONTAINER_A_DEFINIR") = 0
        OR sel.tipo = ? OR sel.codigo = ? OR sel.codigo2 = ? OR sel.numero = ? THEN
            RETURN ERROR "Selecao invalida.".
    END.
END PROCEDURE.

PROCEDURE selecionarItens:
    DEFINE VARIABLE pesquisaOriginal AS CHARACTER NO-UNDO.
    DEFINE VARIABLE pesquisaCorrigida AS CHARACTER NO-UNDO.
    DO ON ERROR UNDO, THROW:
        RUN validar.
        FIND FIRST f.
        pesquisaOriginal = f.pesquisaItem.
        RUN _selecionarItens(pesquisaOriginal).
        /* Apenas etapa1 vazia. Saldo/minimos nunca provocam outra selecao. */
        IF NOT CAN-FIND(FIRST ttItensSaldoPV) AND NOT pesquisaLivre
            AND NOT pesquisaSoCodigos THEN DO:
            RUN esbo/normalizarPesquisaEstoque.p(pesquisaOriginal, OUTPUT pesquisaCorrigida).
            IF NOT COMPARE(pesquisaCorrigida,"EQ",pesquisaOriginal,"RAW") THEN
                RUN _selecionarItens(pesquisaCorrigida).
        END.
        CATCH erro AS Progress.Lang.Error:
            RUN limparResultados.
            UNDO, THROW erro.
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE prepararPesquisa PRIVATE:
    DEFINE INPUT PARAMETER pesquisa AS CHARACTER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE texto AS CHARACTER NO-UNDO.
    ASSIGN pesquisaLivre = pesquisa = "" pesquisaSoCodigos = YES.
    DO i = 1 TO NUM-ENTRIES(pesquisa):
        texto = TRIM(REPLACE(ENTRY(i, pesquisa), "  ", " ")).
        IF texto = "" THEN DO:
            pesquisaLivre = YES.
            NEXT.
        END.
        IF NOT CAN-FIND(ttTermoItemPV WHERE ttTermoItemPV.termo = texto) THEN DO:
            CREATE ttTermoItemPV.
            ASSIGN ttTermoItemPV.termo = texto ttTermoItemPV.numerico = termoNumerico(texto).
            IF NOT ttTermoItemPV.numerico THEN pesquisaSoCodigos = NO.
        END.
    END.
    IF pesquisaLivre THEN pesquisaSoCodigos = NO.
END PROCEDURE.

PROCEDURE _selecionarItens PRIVATE:
    DEFINE INPUT PARAMETER pesquisa AS CHARACTER NO-UNDO.
    RUN limparResultados.
    RUN validar.
    FIND FIRST f.
    RUN prepararPesquisa(pesquisa).
    ASSIGN detalhar = f.porReferencia OR f.consultaReferencias OR f.minimoKG > 0 OR f.minimoMT > 0
        OR f.maximoKG <> ? OR f.maximoMT <> ?.
    /* Nao colocar faixas amplas de item no caminho por familia/grupo:
       o compilador escolheria codigo, mesmo sem item informado. */
    IF pesquisaSoCodigos THEN DO:
        FOR EACH ttTermoItemPV,
            EACH bItem NO-LOCK WHERE bItem.it-codigo = ttTermoItemPV.termo
                AND bItem.ge-codigo >= f.grupoEstoqueIni AND bItem.ge-codigo <= f.grupoEstoqueFim
                AND (f.unidade = "" OR bItem.un = f.unidade)
                AND (f.pesoLiquidoIni = ? OR bItem.peso-liquido >= f.pesoLiquidoIni)
                AND (f.pesoLiquidoFim = ? OR bItem.peso-liquido <= f.pesoLiquidoFim):
            RUN _adicionarItem.
        END.
    END.
    ELSE IF f.itemIni <> "" OR f.itemFim <> "zzzzzzzzzzzzzz" THEN DO:
        FOR EACH bItem NO-LOCK
                WHERE bItem.it-codigo >= f.itemIni AND bItem.it-codigo <= f.itemFim
                AND bItem.ge-codigo >= f.grupoEstoqueIni AND bItem.ge-codigo <= f.grupoEstoqueFim
                AND (f.unidade = "" OR bItem.un = f.unidade)
                AND (f.pesoLiquidoIni = ? OR bItem.peso-liquido >= f.pesoLiquidoIni)
                AND (f.pesoLiquidoFim = ? OR bItem.peso-liquido <= f.pesoLiquidoFim):
            RUN _adicionarItem.
        END.
    END.
    ELSE IF f.familiaIni <> "" OR f.familiaFim <> "zzzzzzzzzzzzzz" THEN DO:
        FOR EACH bItem NO-LOCK
                WHERE bItem.fm-codigo >= f.familiaIni AND bItem.fm-codigo <= f.familiaFim
                AND bItem.ge-codigo >= f.grupoEstoqueIni AND bItem.ge-codigo <= f.grupoEstoqueFim
                AND (f.unidade = "" OR bItem.un = f.unidade)
                AND (f.pesoLiquidoIni = ? OR bItem.peso-liquido >= f.pesoLiquidoIni)
                AND (f.pesoLiquidoFim = ? OR bItem.peso-liquido <= f.pesoLiquidoFim):
            RUN _adicionarItem.
        END.
    END.
    ELSE DO:
        FOR EACH bItem NO-LOCK
                WHERE bItem.ge-codigo >= f.grupoEstoqueIni AND bItem.ge-codigo <= f.grupoEstoqueFim
                AND (f.unidade = "" OR bItem.un = f.unidade)
                AND (f.pesoLiquidoIni = ? OR bItem.peso-liquido >= f.pesoLiquidoIni)
                AND (f.pesoLiquidoFim = ? OR bItem.peso-liquido <= f.pesoLiquidoFim):
            RUN _adicionarItem.
        END.
    END.
    etapa = 1.
END PROCEDURE.

PROCEDURE _adicionarItem PRIVATE:
    /* Validacao residual comum, inclusive os limites amplos de14z. */
    IF bItem.it-codigo < f.itemIni OR bItem.it-codigo > f.itemFim
    OR bItem.fm-codigo < f.familiaIni OR bItem.fm-codigo > f.familiaFim THEN RETURN.
    IF f.itemContem <> "" AND INDEX(bItem.it-codigo, f.itemContem) = 0 THEN RETURN.
    IF NOT pesquisaPermitida(bItem.it-codigo, bItem.desc-item) THEN RETURN.
    IF f.selecaoItensAtiva AND NOT membro("ITEM", bItem.it-codigo, "", 0) THEN RETURN.
    IF f.filtroTabelaPreco AND NOT precoElegivel(bItem.it-codigo) THEN RETURN.
    /* FOR FIRST permite ausencia sem silenciar falha de leitura/trigger. */
    FOR FIRST bExt NO-LOCK WHERE bExt.it-codigo = bItem.it-codigo:
    END.
    IF NOT AVAILABLE bExt THEN RETURN.
    IF f.gramaturaIni <> ? OR f.gramaturaFim <> ? THEN DO:
        IF bExt.gramatura = ? THEN RETURN.
        IF f.gramaturaIni <> ? AND bExt.gramatura < f.gramaturaIni THEN RETURN.
        IF f.gramaturaFim <> ? AND bExt.gramatura > f.gramaturaFim THEN RETURN.
    END.
    CREATE ttItensSaldoPV.
    ASSIGN ttItensSaldoPV.itCodigo = bItem.it-codigo
        ttItensSaldoPV.descItem = bItem.desc-item ttItensSaldoPV.familia = bItem.fm-codigo
        ttItensSaldoPV.unidade = bItem.un ttItensSaldoPV.pesoLiquido = bItem.peso-liquido
        ttItensSaldoPV.gramatura = bExt.gramatura.
END PROCEDURE.

PROCEDURE carregarLocais:
    EMPTY TEMP-TABLE ttLocalPV.
    /* getRegsLocaisPorEmpresa filtra apenas empresa. OR de pares nao duplica. */
    FOR EACH bLocal NO-LOCK WHERE bLocal.cod_empresa = f.empresa:
        IF NOT CAN-FIND(FIRST ttLocalPV WHERE ttLocalPV.estab = bLocal.cod_estab
            AND ttLocalPV.deposito = bLocal.cod_depos) THEN DO:
            CREATE ttLocalPV.
            ASSIGN ttLocalPV.estab = bLocal.cod_estab ttLocalPV.deposito = bLocal.cod_depos.
        END.
    END.
END PROCEDURE.

PROCEDURE carregarLiquidacao PRIVATE:
    EMPTY TEMP-TABLE ttLiquidacaoPV.
    IF NOT f.soLiquidacao OR f.usarSelecoesEspeciais THEN RETURN.
    IF buscarParametroIma("buscar_preco_tb_liquida_ima", "1") <> "0" THEN DO:
        FOR EACH bLiquidacao NO-LOCK WHERE bLiquidacao.dt-inicio <= TODAY
            AND (bLiquidacao.dt-final = ? OR bLiquidacao.dt-final >= TODAY):
            IF NOT CAN-FIND(ttLiquidacaoPV WHERE ttLiquidacaoPV.item = bLiquidacao.it-codigo) THEN DO:
                CREATE ttLiquidacaoPV.
                ttLiquidacaoPV.item = bLiquidacao.it-codigo.
            END.
        END.
    END.
    ELSE DO:
        FOR EACH bPreco NO-LOCK WHERE bPreco.tb_preco_id = f.tabelaPreco
            AND bPreco.tp_preco = 3 AND bPreco.dt_inicial <= TODAY
            AND bPreco.dt_final >= TODAY AND bPreco.log_vencido = NO:
            IF NOT CAN-FIND(ttLiquidacaoPV WHERE ttLiquidacaoPV.item = bPreco.it_codigo) THEN DO:
                CREATE ttLiquidacaoPV.
                ttLiquidacaoPV.item = bPreco.it_codigo.
            END.
        END.
    END.
    /* getFiltroLiquidaIma retorna filtro vazio quando nao encontra itens. */
    temLiquidacao = CAN-FIND(FIRST ttLiquidacaoPV).
END PROCEDURE.

PROCEDURE acumular:
    DEFINE INPUT PARAMETER origem AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER estab AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER container AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER item AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER referencia AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER linha AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER quantidade AS DECIMAL NO-UNDO.
    DEFINE INPUT PARAMETER vendida AS DECIMAL NO-UNDO.
    DEFINE BUFFER saldo FOR ttSaldoPV.
    FIND saldo WHERE saldo.origem = origem AND saldo.codEstab = estab
        AND saldo.nrContainer = container AND saldo.itCodigo = item
        AND saldo.codRefer = referencia AND saldo.linhaOrigem = linha NO-ERROR.
    IF NOT AVAILABLE saldo THEN DO:
        CREATE saldo.
        ASSIGN saldo.origem = origem saldo.codEstab = estab saldo.nrContainer = container
            saldo.itCodigo = item saldo.codRefer = referencia saldo.linhaOrigem = linha.
    END.
    IF origem = "PE" THEN saldo.qtFisica = saldo.qtFisica + quantidade.
    ELSE ASSIGN saldo.qtDisponibilizada = saldo.qtDisponibilizada + quantidade
        saldo.qtVendida = saldo.qtVendida + vendida.
END PROCEDURE.

PROCEDURE preencherSaldos:
    DO ON ERROR UNDO, THROW:
        RUN _preencherSaldos.
        CATCH erro AS Progress.Lang.Error:
            RUN limparResultados.
            UNDO, THROW erro.
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE _preencherSaldos PRIVATE:
    DEFINE VARIABLE referencia AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estab AS CHARACTER NO-UNDO.
    IF etapa <> 1 THEN RETURN ERROR "Executar selecionarItens antes de preencherSaldos.".
    FIND FIRST f.
    EMPTY TEMP-TABLE ttSaldoPV.
    RUN carregarLocais.
    RUN carregarLiquidacao.
    FOR EACH ttItensSaldoPV:
    IF (f.buscarPE OR (f.exibirAmbosSaldos AND NOT f.consultaReferencias)) AND f.containerADefinir <> 1 THEN DO:
            FOR EACH bEstoque NO-LOCK WHERE bEstoque.it-codigo = ttItensSaldoPV.itCodigo
                AND bEstoque.qtidade-atu > 0 AND bEstoque.cod-refer = bEstoque.lote:
                IF NOT referenciaPermitida(bEstoque.cod-refer) THEN NEXT.
                IF NOT localPermitido(bEstoque.cod-estabel, bEstoque.cod-depos) THEN NEXT.
                IF f.soLiquidacao AND f.usarSelecoesEspeciais
                    AND NOT membro("LIQUIDACAO", bEstoque.it-codigo, bEstoque.cod-refer, 0)
                    AND NOT membro("LIQUIDACAO", bEstoque.it-codigo, "*", 0) THEN NEXT.
                IF temLiquidacao AND NOT CAN-FIND(ttLiquidacaoPV WHERE ttLiquidacaoPV.item = bEstoque.it-codigo) THEN NEXT.
                referencia = IF detalhar THEN bEstoque.cod-refer ELSE "".
                RUN acumular("PE", bEstoque.cod-estabel, 0, bEstoque.it-codigo,
                    referencia, "", bEstoque.qtidade-atu, 0).
            END.
        END.
    IF f.buscarPI OR (f.exibirAmbosSaldos AND NOT f.consultaReferencias) THEN DO:
            FOR EACH bProgramado NO-LOCK WHERE bProgramado.it-codigo = ttItensSaldoPV.itCodigo,
                EACH bContainer NO-LOCK WHERE bContainer.nr-container = bProgramado.nr-container
                AND bContainer.situacao = 1:
                IF bProgramado.qt-pedida = ? OR bProgramado.perc-dsp-venda = ?
                OR bProgramado.qt-pedida * bProgramado.perc-dsp-venda / 100 <= 0 THEN NEXT.
                IF NOT referenciaPermitida(bProgramado.cod-refer) THEN NEXT.
                IF f.selecaoContainersAtiva AND NOT membro("CONTAINER", "", "", bContainer.nr-container) THEN NEXT.
                IF f.containerADefinir = 1 THEN DO:
                    IF f.usarSelecoesEspeciais THEN DO:
                        IF NOT membro("CONTAINER_A_DEFINIR", "", "", bContainer.nr-container) THEN NEXT.
                    END.
                    ELSE IF bContainer.log_rota_indefinida <> YES OR bContainer.num_origem <> 1 THEN NEXT.
                END.
                IF bContainer.exclusivo = ? THEN NEXT.
                IF bContainer.exclusivo AND f.representante <> ? AND f.representante > 0 THEN DO:
                    IF NOT CAN-FIND(FIRST bPermissao WHERE bPermissao.cod_repres = f.representante
                        AND bPermissao.nr_container = bContainer.nr-container) THEN NEXT.
                END.
                IF (f.tipoUsuario = 3 OR f.tipoUsuario = 4) AND f.login <> ""
                    AND bContainer.log-1 = YES AND f.containerADefinir <> 1
                    AND CAN-FIND(FIRST bGrupo WHERE bGrupo.login_usuario = f.login AND bGrupo.cod_grupo = 5) THEN NEXT.
                estab = bContainer.cod-estabel.
                IF estab = ? THEN NEXT.
                IF f.estabADefinir = 1 AND bContainer.log_rota_indefinida <> YES THEN NEXT.
                IF f.estabADefinir = 2 AND bContainer.log_rota_indefinida = YES THEN NEXT.
                IF f.selecaoEstabsAtiva AND NOT membro("ESTAB", estab, "", 0) THEN NEXT.
                referencia = IF detalhar OR f.estabADefinir <> 0 THEN bProgramado.cod-refer ELSE "".
                RUN acumular("PI", estab, IF detalhar OR f.estabADefinir <> 0 THEN bContainer.nr-container ELSE 0, bProgramado.it-codigo,
                    referencia, IF detalhar OR f.estabADefinir <> 0 THEN STRING(ROWID(bProgramado)) ELSE "",
                    bProgramado.qt-pedida * bProgramado.perc-dsp-venda / 100,
                    bProgramado.qt-vendida).
            END.
        END.
    END.
    FOR EACH ttSaldoPV:
        RUN preencherComponentes(ROWID(ttSaldoPV)).
    END.
    RUN atualizarTotais.
    etapa = 2.
END PROCEDURE.

PROCEDURE preencherComponentes:
    DEFINE INPUT PARAMETER linha AS ROWID NO-UNDO.
    DEFINE BUFFER saldo FOR ttSaldoPV.
    DEFINE BUFFER pedido FOR ems2med.ped-venda.
    DEFINE BUFFER itemPedido FOR ems2med.ped-item.
    DEFINE BUFFER nota FOR ems2med.nota-fiscal.
    DEFINE BUFFER itemNota FOR ems2med.it-nota-fisc.
    DEFINE BUFFER natureza FOR ems2med.natur-oper.
    DEFINE BUFFER pedidoWeb FOR espec.peds_web.
    DEFINE BUFFER itemWeb FOR espec.itens_ped_web.
    FIND saldo WHERE ROWID(saldo) = linha.
    IF saldo.origem = "PE" THEN DO:
        FOR EACH itemPedido NO-LOCK WHERE itemPedido.it-codigo = saldo.itCodigo
            AND (itemPedido.cod-sit-item = 1 OR itemPedido.cod-sit-item = 4)
            AND (saldo.codRefer = "" OR itemPedido.cod-refer = saldo.codRefer),
            EACH pedido NO-LOCK WHERE pedido.nome-abrev = itemPedido.nome-abrev
            AND pedido.nr-pedcli = itemPedido.nr-pedcli AND pedido.cod-estabel = saldo.codEstab
            AND pedido.tp-pedido = "PE":
            IF referenciaPermitida(itemPedido.cod-refer) THEN
                saldo.qtPedidos = saldo.qtPedidos + itemPedido.qt-pedida.
        END.
        FOR EACH itemNota NO-LOCK WHERE itemNota.it-codigo = saldo.itCodigo
            AND itemNota.cod-estabel = saldo.codEstab
            AND (saldo.codRefer = "" OR itemNota.cod-refer = saldo.codRefer),
            EACH nota NO-LOCK WHERE nota.cod-estabel = itemNota.cod-estabel
            AND nota.serie = itemNota.serie AND nota.nr-nota-fis = itemNota.nr-nota-fis
            AND nota.dt-cancela = ? AND nota.dt-confirma = ?:
            IF NOT referenciaPermitida(itemNota.cod-refer) THEN NEXT.
            IF CAN-FIND(FIRST natureza WHERE natureza.nat-vinculada = nota.nat-operacao
                AND natureza.nat-vinculada <> "") THEN NEXT.
            saldo.qtNFAberta = saldo.qtNFAberta + itemNota.qt-faturada[1].
        END.
    END.
    IF f.considerarWeb THEN DO:
        FOR EACH itemWeb NO-LOCK WHERE itemWeb.it_codigo = saldo.itCodigo
            AND (saldo.codRefer = "" OR itemWeb.cod_refer = saldo.codRefer),
            EACH pedidoWeb NO-LOCK WHERE pedidoWeb.ped_web_id = itemWeb.ped_web_id
            AND ((saldo.origem = "PE" AND pedidoWeb.nr_container = 0 AND pedidoWeb.cod_estabel = saldo.codEstab)
                OR (saldo.origem = "PI" AND ((saldo.nrContainer = 0 AND pedidoWeb.nr_container <> 0)
                    OR (saldo.nrContainer <> 0 AND pedidoWeb.nr_container = saldo.nrContainer)))):
            IF LOOKUP(STRING(pedidoWeb.ind_sit_ped_web), f.situacoesCarrinho) > 0 THEN DO:
                saldo.qtCarrinho = saldo.qtCarrinho + itemWeb.qt_pedida.
                IF pedidoWeb.login = f.login THEN
                    saldo.qtCarrinhoLogin = saldo.qtCarrinhoLogin + itemWeb.qt_pedida.
            END.
            ELSE IF LOOKUP(STRING(pedidoWeb.ind_sit_ped_web), f.situacoesNaoIntegradas) > 0 THEN
                saldo.qtNaoIntegrada = saldo.qtNaoIntegrada + itemWeb.qt_pedida.
        END.
    END.
    /* Uma unica formula por origem. Carrinho do login nao e somado de volta. */
    IF saldo.origem = "PE" THEN saldo.qtSaldoVenda = saldo.qtFisica - saldo.qtPedidos
        - saldo.qtNFAberta - saldo.qtCarrinho - saldo.qtNaoIntegrada.
    ELSE saldo.qtSaldoVenda = saldo.qtDisponibilizada - saldo.qtVendida
        - saldo.qtCarrinho - saldo.qtNaoIntegrada.
END PROCEDURE.

PROCEDURE atualizarTotais:
    DEFINE BUFFER itemSaldo FOR ttItensSaldoPV.
    FOR EACH itemSaldo:
        ASSIGN itemSaldo.qtFisicaPE = 0 itemSaldo.qtDisponivelPI = 0
            itemSaldo.qtSaldoPE = 0 itemSaldo.qtSaldoPI = 0.
    END.
    FOR EACH ttSaldoPV:
        FIND itemSaldo WHERE itemSaldo.itCodigo = ttSaldoPV.itCodigo.
        IF ttSaldoPV.origem = "PE" THEN ASSIGN
            itemSaldo.qtFisicaPE = itemSaldo.qtFisicaPE + ttSaldoPV.qtFisica
            itemSaldo.qtSaldoPE = itemSaldo.qtSaldoPE + (IF etapa = 3 AND NOT f.exibirAmbosSaldos AND NOT ttSaldoPV.aprovadoQuantidade THEN 0 ELSE ttSaldoPV.qtSaldoVenda).
        ELSE ASSIGN itemSaldo.qtDisponivelPI = itemSaldo.qtDisponivelPI + ttSaldoPV.qtDisponibilizada
            itemSaldo.qtSaldoPI = itemSaldo.qtSaldoPI + (IF etapa = 3 AND NOT f.exibirAmbosSaldos AND NOT ttSaldoPV.aprovadoQuantidade THEN 0 ELSE ttSaldoPV.qtSaldoVenda).
    END.
END PROCEDURE.

PROCEDURE filtrarSaldos:
    DO ON ERROR UNDO, THROW:
        RUN _filtrarSaldos.
        CATCH erro AS Progress.Lang.Error:
            RUN limparResultados.
            UNDO, THROW erro.
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE _filtrarSaldos PRIVATE:
    DEFINE BUFFER itemSaldo FOR ttItensSaldoPV.
    DEFINE VARIABLE minimo AS DECIMAL NO-UNDO.
    DEFINE VARIABLE maximo AS DECIMAL NO-UNDO.
    IF etapa <> 2 THEN RETURN ERROR "Executar preencherSaldos antes de filtrarSaldos.".
    FIND FIRST f.
    EMPTY TEMP-TABLE ttTotalQuantidadePV.
    FOR EACH ttSaldoPV:
        FIND itemSaldo WHERE itemSaldo.itCodigo = ttSaldoPV.itCodigo.
        ASSIGN minimo = 0 maximo = ?.
        CASE CAPS(itemSaldo.unidade):
            WHEN "KG" THEN ASSIGN minimo = f.minimoKG maximo = f.maximoKG.
            WHEN "M" OR WHEN "MT" THEN ASSIGN minimo = f.minimoMT maximo = f.maximoMT.
        END CASE.
        IF ttSaldoPV.qtSaldoVenda = ? THEN RETURN ERROR "Quantidade desconhecida no saldo.".
        /* filtrarPorQtRef nao soma referencias nem dispensa minimos por perfil.
           Minimo zero deixa passar saldos negativos, conforme o PHP. */
        IF f.consultaReferencias THEN DO:
            ttSaldoPV.aprovadoQuantidade = (minimo = 0 OR ttSaldoPV.qtSaldoVenda >= minimo)
                AND (maximo = ? OR ttSaldoPV.qtSaldoVenda <= maximo)
                AND ((ttSaldoPV.origem = "PE" AND f.buscarPE) OR (ttSaldoPV.origem = "PI" AND f.buscarPI)).
            IF NOT ttSaldoPV.aprovadoQuantidade THEN DELETE ttSaldoPV.
            ELSE ttSaldoPV.qtSaldoItem = ttSaldoPV.qtSaldoVenda.
            NEXT.
        END.
        ttSaldoPV.aprovadoQuantidade = (ttSaldoPV.qtSaldoVenda >= minimo OR f.tipoUsuario = 3 OR f.tipoUsuario = 4)
            AND (maximo = ? OR ttSaldoPV.qtSaldoVenda <= maximo)
            AND ((ttSaldoPV.origem = "PE" AND f.buscarPE) OR (ttSaldoPV.origem = "PI" AND f.buscarPI)).
        FIND ttTotalQuantidadePV WHERE ttTotalQuantidadePV.origem = ttSaldoPV.origem
            AND ttTotalQuantidadePV.item = ttSaldoPV.itCodigo NO-ERROR.
        IF NOT AVAILABLE ttTotalQuantidadePV THEN DO:
            CREATE ttTotalQuantidadePV.
            ASSIGN ttTotalQuantidadePV.origem = ttSaldoPV.origem ttTotalQuantidadePV.item = ttSaldoPV.itCodigo
                ttTotalQuantidadePV.minimo = minimo.
        END.
        IF ttSaldoPV.aprovadoQuantidade THEN ASSIGN
            ttTotalQuantidadePV.total = ttTotalQuantidadePV.total + ttSaldoPV.qtSaldoVenda
            ttTotalQuantidadePV.aprovadas = ttTotalQuantidadePV.aprovadas + 1.
    END.
    /* PHP mantem todas as linhas do item/origem com ao menos uma aprovada;
       qtSaldoItem repete o total legado, mas qtSaldoVenda preserva a linha real. */
    FOR EACH ttSaldoPV:
        IF f.consultaReferencias THEN NEXT.
        IF f.exibirAmbosSaldos THEN DO:
            /* Uma origem nao selecionada nunca torna o item elegivel. Uma vez
               elegivel, conservar ambas para exibir seus saldos reais. */
            IF NOT CAN-FIND(FIRST ttTotalQuantidadePV
                WHERE ttTotalQuantidadePV.item = ttSaldoPV.itCodigo
                AND ttTotalQuantidadePV.aprovadas > 0
                AND (ttTotalQuantidadePV.minimo = 0 OR ttTotalQuantidadePV.total > 0)) THEN DO:
                DELETE ttSaldoPV.
                NEXT.
            END.
            FIND ttTotalQuantidadePV WHERE ttTotalQuantidadePV.origem = ttSaldoPV.origem
                AND ttTotalQuantidadePV.item = ttSaldoPV.itCodigo.
            ttSaldoPV.qtSaldoItem = ttTotalQuantidadePV.total.
            NEXT.
        END.
        FIND ttTotalQuantidadePV WHERE ttTotalQuantidadePV.origem = ttSaldoPV.origem
            AND ttTotalQuantidadePV.item = ttSaldoPV.itCodigo.
        IF ttTotalQuantidadePV.aprovadas = 0 OR
            (ttTotalQuantidadePV.total <= 0 AND ttTotalQuantidadePV.minimo > 0) THEN DELETE ttSaldoPV.
        ELSE ttSaldoPV.qtSaldoItem = ttTotalQuantidadePV.total.
    END.
    FOR EACH itemSaldo:
        IF NOT CAN-FIND(FIRST ttSaldoPV WHERE ttSaldoPV.itCodigo = itemSaldo.itCodigo) THEN DELETE itemSaldo.
    END.
    etapa = 3.
    RUN atualizarTotais.
END PROCEDURE.

PROCEDURE exec:
    DO ON ERROR UNDO, THROW:
        RUN selecionarItens.
        RUN preencherSaldos.
        RUN filtrarSaldos.
        CATCH erro AS Progress.Lang.Error:
            RUN limparResultados.
            UNDO, THROW erro.
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE getTTItens:
    DEFINE OUTPUT PARAMETER TABLE FOR ttItensSaldoPV.
END PROCEDURE.
PROCEDURE getTTParametros:
    DEFINE OUTPUT PARAMETER TABLE FOR ttFiltroSaldoPV.
END PROCEDURE.
PROCEDURE getTTSaldo:
    DEFINE OUTPUT PARAMETER TABLE FOR ttSaldoPV.
END PROCEDURE.
PROCEDURE getEtapa:
    DEFINE OUTPUT PARAMETER numero AS INTEGER NO-UNDO.
    numero = etapa.
END PROCEDURE.
