<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$source = (string) file_get_contents($root . '/web/metadata-store.php');
$functions = substr($source, strpos($source, 'function metadataDb(): PDO'));
eval($functions);

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
initializeMetadataSchema($pdo);

assertSame('adinc/i03ad209.i 2', extractViewAsInclude('view-as radio-set radio-buttons {adinc/i03ad209.i 2}'), 'include deve preservar argumento 2');
assertSame('adinc/i01ad270.i 02', extractViewAsInclude('view-as radio-set radio-buttons {adinc/i01ad270.i 02}'), 'include deve preservar argumento 02');
assertSame('adinc/i03ad209.i 2', extractViewAsInclude('view-as radio-set radio-buttons {adinc\\i03ad209.i 2}'), 'include deve normalizar barras sem alterar argumento');

saveViewAsRows($pdo, ['environmentId' => '', 'companyId' => '', 'database' => 'ems2cad', 'table' => 'acum-cb'], [[
    'field' => 'modalidade',
    'viewAs' => 'view-as radio-set radio-buttons {adinc/i03ad209.i 2}',
    'listExpression' => '"Aberto",1,"Fechado",2',
    'options' => [
        ['label' => 'Aberto', 'value' => '1'],
        ['label' => 'Fechado', 'value' => '2'],
    ],
]], 'PASOE');

$rows = loadViewAsRows($pdo, ['database' => 'ems2cad', 'table' => 'acum-cb']);
assertSame(1, count($rows), 'deve carregar um view-as salvo');
assertSame('view-as radio-set radio-buttons {adinc/i03ad209.i 2}', $rows[0]['viewAs'], 'view_as original deve preservar include');
assertSame('"Aberto",1,"Fechado",2', $rows[0]['listExpression'], 'expressao de lista deve vir da tabela de opcoes');
assertSame([
    ['label' => 'Aberto', 'value' => '1'],
    ['label' => 'Fechado', 'value' => '2'],
], $rows[0]['options'], 'opcoes devem ser carregadas da tabela separada');

$optionCount = (int) $pdo->query('SELECT COUNT(*) FROM field_view_as_options')->fetchColumn();
assertSame(2, $optionCount, 'deve gravar uma linha por opcao');

saveViewAsRows($pdo, ['environmentId' => '', 'companyId' => '', 'database' => 'ems2cad', 'table' => 'acum-cb'], [[
    'field' => 'modalidade',
    'viewAs' => 'view-as radio-set radio-buttons {adinc/i03ad209.i 2}',
    'listExpression' => '"Pendente",P,"Finalizado",F',
    'options' => [
        ['label' => 'Pendente', 'value' => 'P'],
        ['label' => 'Finalizado', 'value' => 'F'],
    ],
]], 'manual');

$updated = loadViewAsRows($pdo, ['database' => 'ems2cad', 'table' => 'acum-cb']);
assertSame('view-as radio-set radio-buttons {adinc/i03ad209.i 2}', $updated[0]['viewAs'], 'edicao de opcoes nao deve alterar view_as');
assertSame('"Pendente",P,"Finalizado",F', $updated[0]['listExpression'], 'edicao deve atualizar expressao da tabela de opcoes');
assertSame([
    ['label' => 'Pendente', 'value' => 'P'],
    ['label' => 'Finalizado', 'value' => 'F'],
], $updated[0]['options'], 'opcoes editadas devem substituir as anteriores');

deleteViewAsRow($pdo, ['database' => 'ems2cad', 'table' => 'acum-cb'], 'modalidade');
assertSame(0, (int) $pdo->query('SELECT COUNT(*) FROM field_view_as')->fetchColumn(), 'delete deve remover view-as');
assertSame(0, (int) $pdo->query('SELECT COUNT(*) FROM field_view_as_options')->fetchColumn(), 'delete deve remover opcoes');

$pdo->prepare(
    'INSERT INTO field_view_as
     (id, environment_id, company_id, database_name, table_name, field_name, view_as, source, raw_json, updated_at)
     VALUES ("direct-list", "", "", "ems5", "gg-inscricao", "ind-tp-propriedade", :view_as, "PASOE", "{}", :updated_at)'
)->execute([
    ':view_as' => 'VIEW-AS RADIO-SET RADIO-BUTTONS "Proprietario", 1, "Arrendatario", 2, "Outros", 3 VERTICAL SIZE 10 BY 1',
    ':updated_at' => date(DATE_ATOM),
]);

$directRows = loadViewAsRows($pdo, ['database' => 'ems5', 'table' => 'gg-inscricao']);
assertSame(1, count($directRows), 'deve carregar view-as direto sem tabela de opcoes');
assertSame('"Proprietario",1,"Arrendatario",2,"Outros",3', $directRows[0]['listExpression'], 'view-as direto deve gerar expressao de lista no retorno');
assertSame([
    ['label' => 'Proprietario', 'value' => '1'],
    ['label' => 'Arrendatario', 'value' => '2'],
    ['label' => 'Outros', 'value' => '3'],
], $directRows[0]['options'], 'view-as direto deve gerar opcoes no retorno');

echo "View-as options table contract OK\n";

function assertSame($expected, $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ': esperado ' . var_export($expected, true) . ', obtido ' . var_export($actual, true));
    }
}
