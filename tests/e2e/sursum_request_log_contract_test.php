<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$proxy = (string) file_get_contents($root . '/web/pasoe-proxy.php');
assertContains($proxy, 'CREATE TABLE IF NOT EXISTS request_logs', 'schema request_logs no proxy');
assertContains($proxy, 'startRequestLog', 'registro de inicio');
assertContains($proxy, 'finishRequestLog', 'registro de fim');
assertContains($proxy, 'request_body_json', 'corpo enviado gravado');
assertContains($proxy, 'response_body_json', 'corpo retornado gravado');
assertContains($proxy, 'started_at', 'data/hora inicio');
assertContains($proxy, 'finished_at', 'data/hora fim');

$endpoint = (string) file_get_contents($root . '/web/request-log-store.php');
assertContains($endpoint, 'request_logs', 'endpoint consulta request_logs');
assertContains($endpoint, 'startDate', 'endpoint aceita data inicial');
assertContains($endpoint, 'endDate', 'endpoint aceita data final');
assertContains($endpoint, 'action=detail', 'endpoint detalhe documentado');
assertContains($endpoint, 'requestQueryJson', 'retorno requestQueryJson');
assertContains($endpoint, 'requestBodyJson', 'retorno requestBodyJson');
assertContains($endpoint, 'responseBodyJson', 'retorno responseBodyJson');

$page = (string) file_get_contents($root . '/web/request-log.html');
assertContains($page, 'request-log-store.php', 'pagina consulta endpoint');
assertContains($page, 'startDateInput', 'pagina tem data inicial');
assertContains($page, 'endDateInput', 'pagina tem data final');
assertContains($page, 'setDefaultPeriod', 'pagina inicializa periodo padrao');
assertContains($page, 'today.setDate(today.getDate() - 30)', 'periodo padrao inicia 30 dias atras');
assertNotContains($page, 'ready.then(loadList)', 'pagina nao carrega logs automaticamente');
assertContains($page, 'kendoDatePicker', 'pagina usa datepicker para filtros de periodo');
assertContains($page, 'filterable: true', 'grid tem filtros por coluna');
assertContains($page, 'groupable: true', 'grid tem agrupamento');
assertContains($page, 'dd/MM/yyyy HH:mm:ss', 'grid formata data/hora no padrao brasileiro');
assertContains($page, 'requestQueryJson', 'pagina exibe requestQueryJson');
assertContains($page, 'requestBodyJson', 'pagina exibe requestBodyJson');
assertContains($page, 'responseBodyJson', 'pagina exibe responseBodyJson');

$menu = (string) file_get_contents($root . '/web/menu-pages.json');
assertContains($menu, 'request-log.html', 'menu inclui log de requisicoes');

$metadataStore = (string) file_get_contents($root . '/web/metadata-store.php');
assertContains($metadataStore, '@fopen($lockPath, \'c\')', 'lock SQLite nao emite warning HTML');
assertContains($metadataStore, 'sys_get_temp_dir()', 'lock SQLite tem fallback em diretorio temporario');
assertContains($metadataStore, 'sha1(__DIR__)', 'lock temporario e especifico da instalacao');

echo "Request log contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}

function assertNotContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) !== false) {
        throw new RuntimeException($label . ': trecho encontrado indevidamente: ' . $needle);
    }
}
