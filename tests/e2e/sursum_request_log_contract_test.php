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
assertContains($endpoint, 'action=detail', 'endpoint detalhe documentado');
assertContains($endpoint, 'requestQueryJson', 'retorno requestQueryJson');
assertContains($endpoint, 'requestBodyJson', 'retorno requestBodyJson');
assertContains($endpoint, 'responseBodyJson', 'retorno responseBodyJson');

$page = (string) file_get_contents($root . '/web/request-log.html');
assertContains($page, 'request-log-store.php', 'pagina consulta endpoint');
assertContains($page, 'requestQueryJson', 'pagina exibe requestQueryJson');
assertContains($page, 'requestBodyJson', 'pagina exibe requestBodyJson');
assertContains($page, 'responseBodyJson', 'pagina exibe responseBodyJson');

$menu = (string) file_get_contents($root . '/web/menu-pages.json');
assertContains($menu, 'request-log.html', 'menu inclui log de requisicoes');

echo "Request log contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
