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
