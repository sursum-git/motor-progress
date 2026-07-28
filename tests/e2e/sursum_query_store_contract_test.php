<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

assertFileContains($root . "/docs/ROADMAP_CONSULTAS_SALVAS.md", [
    "Webhook para jobs e workers",
    "startedAt",
    "finishedAt",
    "externalFilters",
]);

$config = json_decode((string) file_get_contents($root . "/sursum-conf/query-store.json"), true);
assertSameValue("sursum-api/querys", $config["paths"]["queryStoreRoot"] ?? null, "queryStoreRoot padrao");

$queryBuilder = (string) file_get_contents($root . "/web/query-builder.js");
assertContains($queryBuilder, "externalFilters: []", "estado externalFilters");
assertContains($queryBuilder, "#externalFiltersGrid", "grid externalFilters");
assertContains($queryBuilder, "request.externalFilters = state.externalFilters.map(cleanObject)", "serializacao externalFilters");
assertContains($queryBuilder, "Parametro externo deve usar apenas letras, numeros, _, - ou .", "validacao de nome externo");
assertContains($queryBuilder, "#saveQueryBackend", "evento salvar no PASOE");
assertContains($queryBuilder, 'apiBase() + "/query-store"', "endpoint query-store frontend");
assertContains($queryBuilder, "JSON.stringify({ code, status, query: request })", "payload query-store frontend");

$queryBuilderHtml = (string) file_get_contents($root . "/web/query-builder.html");
assertContains($queryBuilderHtml, "Filtros externos permitidos", "secao filtros externos");
assertContains($queryBuilderHtml, "externalFilterSource", "origem filtros externos");
assertContains($queryBuilderHtml, "queryCode", "campo codigo query-store");
assertContains($queryBuilderHtml, "queryStoreStatus", "campo status query-store");
assertContains($queryBuilderHtml, "saveQueryBackend", "botao salvar no PASOE");

$handler = (string) file_get_contents($root . "/sursum-api/rest/DynamicQueryWebHandler.cls");
assertContains($handler, "handleSaveQueryStore", "rota salvar query-store");
assertContains($handler, "handlePostStoredQuery", "execucao por codigo");
assertContains($handler, "readQueryStoreConfig", "configuracao query-store");
assertContains($handler, "EXTERNAL_FILTER_NOT_ALLOWED", "bloqueio parametro nao declarado");
assertContains($handler, "REQUIRED_EXTERNAL_FILTER_MISSING", "bloqueio obrigatorio ausente");

if (!is_dir($root . "/sursum-api/querys")) {
    throw new RuntimeException("Diretorio sursum-api/querys nao existe.");
}

$containerSavedQueryPath = $root . "/sursum-api/querys/pp-it-container-por-container.json";
assertFileContains($containerSavedQueryPath, [
    '"code": "pp-it-container-por-container"',
    '"defaultBanco": "espec"',
    '"nome": "pp-it-container"',
    '"name": "nr-container"',
    '"source": "querystring"',
]);

$controlePrecoSavedQueryPath = $root . "/sursum-api/querys/controle-preco-por-pedido-container.json";
assertFileContains($controlePrecoSavedQueryPath, [
    '"code": "controle-preco-por-pedido-container"',
    '"defaultBanco": "espec"',
    '"nome": "controle_preco"',
    '"field": "nr_container"',
    '"name": "pedido"',
    '"name": "container"',
]);

$containerClient = (string) file_get_contents($root . "/web/container-client.html");
assertContains($containerClient, 'const DEFAULT_QUERY_ID = "pp-it-container-por-container"', "queryId padrao container");
assertContains($containerClient, 'code: queryId', "execucao por code no client container");
assertContains($containerClient, 'querystring: { "nr-container": container }', "parametro querystring container");

$savedQueryClient = (string) file_get_contents($root . "/web/saved-query-client.html");
assertContains($savedQueryClient, 'function collectQuerystringParameters', "coleta parametros querystring");
assertContains($savedQueryClient, 'code: queryId', "execucao por code no client generico");
assertContains($savedQueryClient, 'parameters: { querystring: parameters }', "parametros querystring no client generico");
assertContains($savedQueryClient, 'pasoe-proxy.php?target=', "proxy PASOE no client generico");

echo "Query store contract OK
";

function assertFileContains(string $path, array $needles): void
{
    if (!is_file($path)) {
        throw new RuntimeException("Arquivo esperado nao existe: " . $path);
    }
    $content = (string) file_get_contents($path);
    foreach ($needles as $needle) {
        assertContains($content, $needle, $path);
    }
}

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ": trecho nao encontrado: " . $needle);
    }
}

function assertSameValue($expected, $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ": esperado " . var_export($expected, true) . ", recebido " . var_export($actual, true));
    }
}
