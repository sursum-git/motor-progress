<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$source = (string) file_get_contents($root . '/web/metadata-store.php');
$functions = substr($source, strpos($source, 'function metadataDb(): PDO'));
eval($functions);

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
initializeMetadataSchema($pdo);

saveViewAsRows($pdo, ['environmentId' => '', 'companyId' => '', 'database' => 'ems2cad', 'table' => 'wt-ped-venda'], [
    ['field' => 'nr-ped-venda', 'viewAs' => 'FILL-IN'],
], 'manual');
saveViewAsRows($pdo, ['environmentId' => '', 'companyId' => '', 'database' => 'emsfnd', 'table' => 'log_tab_estatis'], [
    ['field' => 'cod-log', 'viewAs' => 'FILL-IN'],
], 'manual');

$ems2cad = loadViewAsRows($pdo, ['database' => 'ems2cad', 'table' => '']);
assertSame(1, count($ems2cad), 'consulta ems2cad deve retornar apenas registros do banco ems2cad');
assertSame('ems2cad', $ems2cad[0]['database'] ?? '', 'registro retornado deve manter database ems2cad');
assertSame('wt-ped-venda', $ems2cad[0]['table'] ?? '', 'registro retornado deve ser da tabela wt-ped-venda');

$emsfnd = loadViewAsRows($pdo, ['database' => 'emsfnd', 'table' => '']);
assertSame(1, count($emsfnd), 'consulta emsfnd deve retornar apenas registros do banco emsfnd');
assertSame('emsfnd', $emsfnd[0]['database'] ?? '', 'registro retornado deve manter database emsfnd');
assertSame('log_tab_estatis', $emsfnd[0]['table'] ?? '', 'registro retornado deve ser da tabela log_tab_estatis');

$pdo->prepare(
    'INSERT INTO field_view_as
     (id, environment_id, company_id, database_name, table_name, field_name, view_as, source, raw_json, updated_at)
     VALUES ("legacy-emitente", "", "", "", "emitente", "cod-emitente", "FILL-IN", "PASOE", "{}", :updated_at)'
)->execute([':updated_at' => date(DATE_ATOM)]);

$ems2cadWithLegacy = loadViewAsRows($pdo, ['database' => 'ems2cad', 'table' => '', 'includeLegacy' => true]);
assertSame(2, count($ems2cadWithLegacy), 'consulta ems2cad com legado deve retornar banco selecionado e registros sem banco');
$tables = array_map(static function (array $row): string {
    return $row['table'] ?? '';
}, $ems2cadWithLegacy);
sort($tables);
assertSame(['emitente', 'wt-ped-venda'], $tables, 'consulta com legado nao deve retornar registros de outro banco');

echo "View-as database scope contract OK\n";

function assertSame($expected, $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ': esperado ' . var_export($expected, true) . ', obtido ' . var_export($actual, true));
    }
}
