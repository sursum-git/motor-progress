<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$source = (string) file_get_contents($root . '/web/metadata-pasoe.php');

assertContains($source, "'success' => true", 'metadata-pasoe trata HTTP 2xx vazio como sucesso');
assertContains($source, "'data' => []", 'metadata-pasoe retorna lista vazia no HTTP 2xx vazio');
assertNotContains($source, "'warning' => 'PASOE respondeu HTTP ' . \$status . ' com corpo vazio.'", 'metadata-pasoe nao deve transformar HTTP 2xx vazio em warning');

echo "Metadata PASOE empty body contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}

function assertNotContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) !== false) {
        throw new RuntimeException($label . ': trecho nao deve existir: ' . $needle);
    }
}
