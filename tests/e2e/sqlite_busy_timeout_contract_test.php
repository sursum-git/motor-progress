<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

foreach ([
    'web/metadata-store.php',
    'web/relation-store.php',
] as $relativePath) {
    $path = $root . DIRECTORY_SEPARATOR . $relativePath;
    $content = (string) file_get_contents($path);
    assertContains($content, 'PDO::ATTR_TIMEOUT', $relativePath . ' deve esperar locks do SQLite');
    assertContains($content, 'PRAGMA busy_timeout', $relativePath . ' deve configurar busy_timeout do SQLite');
    assertContains($content, 'flock(', $relativePath . ' deve serializar operacoes locais no SQLite');
}

$proxy = (string) file_get_contents($root . DIRECTORY_SEPARATOR . 'web/pasoe-proxy.php');
assertContains($proxy, 'busyTimeout(30000)', 'web/pasoe-proxy.php deve esperar locks do SQLite3');

echo "SQLite busy timeout contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
