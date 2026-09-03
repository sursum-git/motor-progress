<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$catalogPath = $root . '/sursum-conf/runtime-screens.json';

if (!is_file($catalogPath)) {
    throw new RuntimeException('Catalogo runtime nao encontrado: ' . $catalogPath);
}

$catalog = json_decode((string) file_get_contents($catalogPath), true);
if (!is_array($catalog)) {
    throw new RuntimeException('Catalogo runtime deve ser JSON object.');
}

assertSameValue('1.0', $catalog['schemaVersion'] ?? null, 'schemaVersion do catalogo');

$screen = $catalog['screens']['cadastros.customer'] ?? null;
if (!is_array($screen)) {
    throw new RuntimeException('Tela cadastros.customer nao configurada.');
}

$definition = $screen['definition'] ?? null;
if (!is_array($definition)) {
    throw new RuntimeException('definition de cadastros.customer deve ser objeto.');
}

assertSameValue('1.0', $definition['schemaVersion'] ?? null, 'schemaVersion da tela');
assertSameValue('crud', $definition['pageType'] ?? null, 'pageType da tela');
assertSameValue('cadastros.customer', $definition['screenId'] ?? null, 'screenId da tela');
assertSameValue('customer', $definition['crud']['idField'] ?? null, 'idField CRUD');
assertNoKeyRecursive($definition, 'url', 'definition cadastros.customer');

foreach (['read', 'get', 'create', 'update', 'delete'] as $endpointId) {
    $api = $definition['api'][$endpointId] ?? null;
    if (!is_array($api)) {
        throw new RuntimeException('api.' . $endpointId . ' nao configurado na definition.');
    }
    assertSameValue($endpointId, $api['endpointId'] ?? null, 'endpointId api.' . $endpointId);
    assertSameValue('POST', $api['method'] ?? null, 'method api.' . $endpointId);

    $endpoint = $screen['endpoints'][$endpointId] ?? null;
    if (!is_array($endpoint)) {
        throw new RuntimeException('Endpoint runtime ausente: ' . $endpointId);
    }
    assertSameValue('POST', $endpoint['method'] ?? null, 'method endpoint ' . $endpointId);
}

assertSameValue('query', $screen['endpoints']['read']['type'] ?? null, 'read usa query');
assertSameValue('query', $screen['endpoints']['get']['type'] ?? null, 'get usa query');
foreach (['create', 'update', 'delete'] as $endpointId) {
    assertSameValue('program', $screen['endpoints'][$endpointId]['type'] ?? null, $endpointId . ' usa program');
    assertSameValue('echo-json', $screen['endpoints'][$endpointId]['program'] ?? null, $endpointId . ' program code');
}

$handler = (string) file_get_contents($root . '/sursum-api/rest/DynamicQueryWebHandler.cls');
assertContains($handler, 'handleRuntimeScreenDefinition', 'handler expoe definicao runtime');
assertContains($handler, 'handleRuntimeScreenEndpoint', 'handler expoe endpoint runtime');
assertContains($handler, 'RuntimeScreenService', 'handler delega para RuntimeScreenService');

echo "Runtime screens contract OK\n";

function assertSameValue($expected, $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ': esperado ' . var_export($expected, true) . ', recebido ' . var_export($actual, true));
    }
}

function assertNoKeyRecursive(array $value, string $forbiddenKey, string $label): void
{
    foreach ($value as $key => $item) {
        if ($key === $forbiddenKey) {
            throw new RuntimeException($label . ': chave proibida encontrada: ' . $forbiddenKey);
        }
        if (is_array($item)) {
            assertNoKeyRecursive($item, $forbiddenKey, $label . '.' . (string) $key);
        }
    }
}

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
