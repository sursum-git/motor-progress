<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$pagePath = $root . '/web/json-object-analyzer.html';
if (!is_file($pagePath)) {
    throw new RuntimeException('Pagina do analisador JSON nao existe: web/json-object-analyzer.html');
}

$page = (string) file_get_contents($pagePath);
assertContains($page, 'jsonInput', 'textarea de entrada JSON');
assertContains($page, 'fileInput', 'entrada de arquivo JSON');
assertContains($page, 'Abrir JSON', 'botao para carregar arquivo JSON');
assertContains($page, 'readAsText(file, "UTF-8")', 'leitura de arquivo em UTF-8');
assertContains($page, 'niveis-profundos-voltas-arrays', 'JSON padrao com varios niveis e arrays');
assertContains($page, '"pedidos": [', 'JSON padrao contem array de pedidos');
assertContains($page, '"itens": [', 'JSON padrao contem array de itens');
assertContains($page, '"enderecos": [', 'JSON padrao contem array profundo de enderecos');
assertContains($page, '"acoes": [', 'JSON padrao contem array de valores');
assertContains($page, 'analise-json-object10', 'programa fixo da versao 10');
assertContains($page, 'jsonText', 'envio do JSON no parametro jsonText');
assertContains($page, 'targetCodepage: "ISO8859-1"', 'charset alvo enviado ao Progress');
assertContains($page, 'jsonTextForProgress(parseJsonInput())', 'jsonText enviado com escape unicode para Progress');
assertContains($page, 'replace(/[^\\x00-\\x7F]/g', 'escape de caracteres nao ASCII');
assertContains($page, 'escapeUnicodeOutput: true', 'saida textual segura em ASCII no PASOE');
assertContains($page, 'decodeUnicodeEscapes', 'decodificacao unicode antes do grid');
assertContains($page, 'Cliente São José', 'JSON padrao contem acentuacao');
assertContains($page, 'pasoe-proxy.php?target=', 'execucao via proxy PHP');
assertContains($page, '/program/execute', 'endpoint de executor de programas');
assertContains($page, 'kendoGrid', 'resultado em grid Kendo');
assertContains($page, 'toolbar: ["excel"]', 'exportacao Excel no grid');
assertContains($page, 'sursum-analise-json-object.xlsx', 'nome do Excel');
assertContains($page, 'field: "nivel"', 'coluna nivel');
assertContains($page, 'field: "caminho"', 'coluna caminho');
assertContains($page, 'field: "tipo"', 'coluna tipo');
assertContains($page, 'field: "valor"', 'coluna valor');
assertContains($page, 'pageSizes: [50, 100, 200, 500]', 'paginacao do grid');
assertContains($page, 'kendo.culture("pt-BR")', 'culture pt-BR');

$config = json_decode((string) file_get_contents($root . '/sursum-conf/program-executor.json'), true);
if (!is_array($config)) {
    throw new RuntimeException('program-executor.json invalido.');
}

$programPath = $config['programs']['analise-json-object10'] ?? null;
if ($programPath !== 'esapi/analiseJsonObject10.p') {
    throw new RuntimeException('Programa analise-json-object10 deve apontar para esapi/analiseJsonObject10.p');
}

$menu = (string) file_get_contents($root . '/web/menu-pages.json');
assertContains($menu, 'json-object-analyzer.html', 'menu inclui analisador JSON object');

echo "Json object analyzer contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
