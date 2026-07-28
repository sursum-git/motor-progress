<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$script = (string) file_get_contents($root . '/web/metadata-maintenance.js');
$style = (string) file_get_contents($root . '/web/metadata-maintenance.css');

assertContains($script, 'viewAsTables', 'combo deve incorporar tabelas existentes no view-as');
assertContains($script, 'tableNameFromMetadataItem', 'lista de tabelas deve preferir table/tableName antes de name');
assertContains($script, 'uniqueTableNames', 'lista de tabelas deve ser deduplicada');
assertContains($script, 'combinedTableNames', 'combo deve unir PASOE e view-as local');
assertContains($script, 'pageSize: 100', 'viewAsGrid deve ser paginado');
assertContains($script, 'updateViewAsSummary', 'resumo deve diferenciar registros e tabelas');
assertContains($script, 'metadata-grid-loading', 'grid deve alternar classe de carregamento');
assertContains($style, '.metadata-grid-loading::after', 'CSS deve exibir indicador visual de carregamento');
assertContains($style, 'metadata-grid-spin', 'indicador visual deve ter animacao');

echo "View-as maintenance contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
