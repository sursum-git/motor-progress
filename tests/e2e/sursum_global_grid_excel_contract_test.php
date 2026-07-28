<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$uiReady = (string) file_get_contents($root . '/web/ui-ready.js');
assertContains($uiReady, 'bindGridExcelDefaults', 'ui-ready aplica exportacao Excel global nos grids');
assertContains($uiReady, 'window.jQuery.fn.kendoGrid', 'ui-ready intercepta criacao do Kendo Grid');
assertContains($uiReady, 'ensureGridExcelToolbar', 'ui-ready adiciona botao Excel no toolbar');

$htmlFiles = glob($root . '/web/*.html') ?: [];
foreach ($htmlFiles as $file) {
    $content = (string) file_get_contents($file);
    if (strpos($content, 'vendor/kendo/js/kendo.all.min.js') === false) {
        continue;
    }
    $label = basename($file);
    assertContains($content, 'vendor/kendo/examples/content/shared/js/jszip.min.js', $label . ' carrega JSZip para exportacao Excel');
    assertBefore(
        $content,
        'vendor/kendo/examples/content/shared/js/jszip.min.js',
        'vendor/kendo/js/kendo.all.min.js',
        $label . ' carrega JSZip antes do Kendo'
    );
}

echo "Global grid Excel contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}

function assertBefore(string $content, string $first, string $second, string $label): void
{
    $firstPosition = strpos($content, $first);
    $secondPosition = strpos($content, $second);
    if ($firstPosition === false || $secondPosition === false || $firstPosition > $secondPosition) {
        throw new RuntimeException($label . ': ordem invalida');
    }
}
