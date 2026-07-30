<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$store = (string) file_get_contents($root . '/web/relation-store.php');
$maintenance = (string) file_get_contents($root . '/web/metadata-maintenance.js');
$wizard = (string) file_get_contents($root . '/web/query-wizard-3steps.js');
$formRenderer = (string) file_get_contents($root . '/web/record-form-renderer.js');
$relationPage = (string) file_get_contents($root . '/web/relation-maintenance.html');

assertContains($store, 'description_field', 'SQLite table_relations deve ter coluna description_field');
assertContains($store, "'descriptionField' =>", 'relation-store deve expor descriptionField no JSON');
assertContains($store, "['descriptionField']", 'relation-store deve aceitar descriptionField no POST');
assertContains($maintenance, '#descriptionField', 'manutencao manual deve ter input para campo de descricao');
assertContains($maintenance, 'descriptionField', 'manutencao manual deve salvar descriptionField');
assertContains($relationPage, 'descriptionField', 'pagina de join manual deve renderizar campo de descricao');
assertContains($wizard, 'foreignDescriptionField', 'wizard deve propagar campo de descricao da FK');
assertContains($wizard, 'loadForeignDescriptionValues', 'wizard deve buscar descricoes de FK sob demanda');
assertContains($formRenderer, 'descriptionValuesByField', 'formulario reutilizavel deve aceitar descricoes resolvidas');

echo "Relation description field contract OK\n";

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}
