<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$handlerPath = $root . '/sursum-api/rest/DynamicQueryWebHandler.cls';
$handler = (string) file_get_contents($handlerPath);

assertNotContains(
    $handler,
    '+ " -1 -ld DICTDB -param',
    'Resolvedor SSH com arquivo PF nao deve forcar -1 -ld DICTDB fora do fallback sports2000.'
);
assertContains(
    $handler,
    'ELSE "-db " + THIS-OBJECT:psQuote("C:\opencode\motor-progress\db\sports2000")',
    'Fallback sem PF deve continuar usando sports2000.'
);
assertContains(
    $handler,
    'GUID(GENERATE-UUID)',
    'Resolvedor SSH deve gerar nomes temporarios com UUID para evitar colisao entre agentes PASOE.'
);
assertNotContains(
    $handler,
    'STRING(RANDOM(1000, 999999))',
    'Resolvedor SSH nao deve usar TIME + RANDOM como unicidade de arquivos temporarios.'
);

echo "View-as resolver contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ' Trecho nao encontrado: ' . $needle);
    }
}

function assertNotContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) !== false) {
        throw new RuntimeException($label . ' Trecho indevido encontrado: ' . $needle);
    }
}
