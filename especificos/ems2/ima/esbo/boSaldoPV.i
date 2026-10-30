/* Contrato proprio da boSaldoPV. Nao altera esbo/boSaldo.i. */
DEFINE TEMP-TABLE ttFiltroSaldoPV NO-UNDO
    FIELD empresa               AS CHARACTER INITIAL "5"
    FIELD login                 AS CHARACTER
    FIELD itemIni               AS CHARACTER
    FIELD itemFim               AS CHARACTER INITIAL "zzzzzzzzzzzzzz"
    FIELD itemContem            AS CHARACTER
    /* Sintaxe do campo Item da pagina: codigos ou termos da descricao. */
    FIELD pesquisaItem          AS CHARACTER
    FIELD familiaIni            AS CHARACTER
    FIELD familiaFim            AS CHARACTER INITIAL "zzzzzzzzzzzzzz"
    FIELD unidade               AS CHARACTER
    FIELD grupoEstoqueIni       AS INTEGER INITIAL 50
    FIELD grupoEstoqueFim       AS INTEGER INITIAL 60
    FIELD gramaturaIni          AS DECIMAL INITIAL ?
    FIELD gramaturaFim          AS DECIMAL INITIAL ?
    FIELD pesoLiquidoIni        AS DECIMAL INITIAL ?
    FIELD pesoLiquidoFim        AS DECIMAL INITIAL ?
    FIELD buscarPE              AS LOGICAL INITIAL YES
    FIELD buscarPI              AS LOGICAL INITIAL YES
    /* PE/PI selecionados filtram itens; ambos os saldos sao exibidos. */
    FIELD exibirAmbosSaldos      AS LOGICAL INITIAL YES
    FIELD minimoKG              AS DECIMAL INITIAL 0
    FIELD minimoMT              AS DECIMAL INITIAL 0
    FIELD maximoKG              AS DECIMAL INITIAL ?
    FIELD maximoMT              AS DECIMAL INITIAL ?
    FIELD porReferencia         AS LOGICAL INITIAL NO
    /* Fluxo bl_estoque: filtrar cada referencia, inclusive para tipos 3/4. */
    FIELD consultaReferencias   AS LOGICAL INITIAL NO
    FIELD considerarWeb         AS LOGICAL INITIAL YES
    /* Defaults comprovados no PHP IOL: getSitsQtCarrinho/getSitsQtNaoIntegrada. */
    FIELD situacoesCarrinho     AS CHARACTER INITIAL "1,8,9"
    FIELD situacoesNaoIntegradas AS CHARACTER INITIAL "2,5"
    FIELD representante         AS INTEGER INITIAL 0
    FIELD tipoUsuario           AS INTEGER INITIAL 0
    FIELD selecaoItensAtiva     AS LOGICAL INITIAL NO
    FIELD selecaoReferenciasAtiva AS LOGICAL INITIAL NO
    FIELD selecaoEstabsAtiva    AS LOGICAL INITIAL NO
    FIELD selecaoLocaisAtiva    AS LOGICAL INITIAL NO
    FIELD selecaoContainersAtiva AS LOGICAL INITIAL NO
    /* Filtros especiais recebem conjuntos resolvidos em ttSelecaoSaldoPV. */
    FIELD soLiquidacao          AS LOGICAL INITIAL NO
    FIELD filtroTabelaPreco    AS LOGICAL INITIAL NO
    FIELD tabelaPreco           AS INTEGER INITIAL 1
    FIELD tabelaPrecoFiltro     AS INTEGER INITIAL 0
    FIELD usarSelecoesEspeciais AS LOGICAL INITIAL NO
    FIELD estabADefinir         AS INTEGER INITIAL 0
    FIELD containerADefinir     AS INTEGER INITIAL 0.

/* Tipos: ITEM, REF, ESTAB, LOCAL (codigo=estab,codigo2=depos),
   CONTAINER (numero), LIQUIDACAO (item/ref), PRECO (item),
   CONTAINER_A_DEFINIR (numero). Lista ativa vazia significa nenhum. */
DEFINE TEMP-TABLE ttSelecaoSaldoPV NO-UNDO
    FIELD tipo    AS CHARACTER
    FIELD codigo  AS CHARACTER
    FIELD codigo2 AS CHARACTER
    FIELD numero  AS INTEGER
    INDEX chave IS PRIMARY UNIQUE tipo codigo codigo2 numero.

/* Etapa 1: candidatos. Etapa 2: totais. Etapa 3: somente sobreviventes. */
DEFINE TEMP-TABLE ttItensSaldoPV NO-UNDO
    FIELD itCodigo      AS CHARACTER
    FIELD descItem      AS CHARACTER
    FIELD familia       AS CHARACTER
    FIELD unidade       AS CHARACTER
    FIELD gramatura     AS DECIMAL INITIAL ?
    FIELD pesoLiquido   AS DECIMAL INITIAL ?
    FIELD qtFisicaPE    AS DECIMAL
    FIELD qtDisponivelPI AS DECIMAL
    FIELD qtSaldoPE     AS DECIMAL
    FIELD qtSaldoPI     AS DECIMAL
    INDEX chave IS PRIMARY UNIQUE itCodigo.

DEFINE TEMP-TABLE ttSaldoPV NO-UNDO
    FIELD origem           AS CHARACTER
    FIELD codEstab         AS CHARACTER
    FIELD nrContainer      AS INTEGER
    FIELD itCodigo         AS CHARACTER
    FIELD codRefer         AS CHARACTER
    FIELD linhaOrigem      AS CHARACTER
    FIELD qtFisica         AS DECIMAL
    FIELD qtDisponibilizada AS DECIMAL
    FIELD qtVendida        AS DECIMAL
    FIELD qtPedidos        AS DECIMAL
    FIELD qtNFAberta        AS DECIMAL
    FIELD qtCarrinho        AS DECIMAL
    FIELD qtCarrinhoLogin   AS DECIMAL
    FIELD qtNaoIntegrada    AS DECIMAL
    FIELD qtSaldoVenda      AS DECIMAL
    FIELD qtSaldoItem       AS DECIMAL
    FIELD aprovadoQuantidade AS LOGICAL INITIAL YES
    INDEX chave IS PRIMARY UNIQUE origem codEstab nrContainer itCodigo codRefer linhaOrigem
    INDEX item itCodigo.
