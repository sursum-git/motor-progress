<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$store = (string) file_get_contents($root . '/web/saved-query-store.php');
assertContains($store, 'function savedQueryDirectories', 'diretorios de consultas salvas');
assertContains($store, 'sursum-api', 'le querys do repositorio local');
assertContains($store, 'sursum-querys', 'le querys publicadas no web');
assertContains($store, 'externalFilters', 'retorna externalFilters');
assertContains($store, 'action', 'suporta detalhe');

$page = (string) file_get_contents($root . '/web/saved-query-runner.html');
assertContains($page, 'kendoComboBox', 'combo kendo de consultas');
assertContains($page, 'saved-query-store.php', 'endpoint de consultas salvas');
assertContains($page, 'externalFilters', 'campos por externalFilters');
assertContains($page, 'parameters', 'montagem de parametros');
assertContains($page, 'pasoe-proxy.php?target=', 'execucao via proxy PHP');
assertContains($page, 'kendoGrid', 'retorno em grid kendo');
assertContains($page, 'scrollable: true', 'grid com rolagem interna sem expandir pagina');
assertContains($page, 'height: "100%"', 'grid ocupa a area fixa disponivel');
assertContains($page, 'height: 100vh', 'pagina limitada a altura da viewport');
assertContains($page, 'overflow: hidden', 'container bloqueia crescimento da pagina');
assertContains($page, 'grid-shell', 'grid fica dentro de shell com altura controlada');
assertContains($page, 'pageSize: 50', 'datasource pagina 50 registros por padrao');
assertContains($page, 'pageSizes: [50, 100, 200, 500]', 'opcoes de paginacao a partir de 50 registros');
assertContains($page, 'kendo.culture("pt-BR")', 'grid usa culture pt-BR');
assertContains($page, 'maximizeGridButton', 'botao para maximizar a div do grid');
assertContains($page, 'grid-maximized', 'classe de maximizacao do grid');
assertContains($page, 'toggleGridMaximized', 'acao de maximizar/restaurar grid');
assertContains($page, 'columnMenu', 'congelamento fica no menu da coluna do grid');
assertContains($page, 'lockable: true', 'colunas permitem congelar pelo menu da coluna');
assertNotContains($page, 'freezeColumnCombo', 'sem combo externo para congelar coluna');
assertNotContains($page, 'freezeColumnButton', 'sem botao externo para congelar coluna');
assertNotContains($page, 'unfreezeColumnButton', 'sem botao externo para liberar coluna');

$menu = (string) file_get_contents($root . '/web/menu-pages.json');
assertContains($menu, 'saved-query-runner.html', 'menu inclui executor de consultas salvas');

$deploy = (string) file_get_contents($root . '/scripts/deploy_query_progress_192_168_0_39.sh');
assertContains($deploy, 'sursum-api/querys', 'deploy copia consultas salvas');
assertContains($deploy, 'sursum-querys', 'deploy publica consultas salvas para o PHP');
assertContains($deploy, 'Require all denied', 'deploy bloqueia acesso HTTP direto aos JSONs publicados');

$containerQuery = $root . '/sursum-api/querys/pp-it-container-por-container.json';
$controlePrecoQuery = $root . '/sursum-api/querys/controle-preco-por-pedido-container.json';
if (!is_file($containerQuery) || !is_file($controlePrecoQuery)) {
    throw new RuntimeException('Consultas salvas esperadas nao encontradas em sursum-api/querys.');
}

echo "Saved query runner contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}

function assertNotContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) !== false) {
        throw new RuntimeException($label . ': trecho nao deveria existir: ' . $needle);
    }
}
