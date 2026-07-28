<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$uiReady = (string) file_get_contents($root . '/web/ui-ready.js');
assertContains($uiReady, 'kendo.culture("pt-BR")', 'ui-ready aplica culture pt-BR');

$htmlFiles = glob($root . '/web/*.html') ?: [];
foreach ($htmlFiles as $file) {
    $html = (string) file_get_contents($file);
    if (strpos($html, 'vendor/kendo/js/kendo.all.min.js') === false) {
        continue;
    }
    $name = basename($file);
    assertContains($html, 'vendor/kendo/js/cultures/kendo.culture.pt-BR.min.js', $name . ' carrega culture pt-BR');
    assertContains($html, 'vendor/kendo/js/messages/kendo.messages.pt-BR.min.js', $name . ' carrega mensagens pt-BR');
    assertOrder(
        $html,
        'vendor/kendo/js/kendo.all.min.js',
        'vendor/kendo/js/cultures/kendo.culture.pt-BR.min.js',
        $name . ' carrega culture apos kendo.all'
    );
    if (strpos($html, 'ui-ready.js') !== false) {
        assertOrder(
            $html,
            'vendor/kendo/js/messages/kendo.messages.pt-BR.min.js',
            'ui-ready.js',
            $name . ' carrega mensagens antes do ui-ready'
        );
    }
}

echo "Kendo pt-BR contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}

function assertOrder(string $content, string $first, string $second, string $label): void
{
    $firstPos = strpos($content, $first);
    $secondPos = strpos($content, $second);
    if ($firstPos === false || $secondPos === false || $firstPos >= $secondPos) {
        throw new RuntimeException($label . ': ordem invalida.');
    }
}
