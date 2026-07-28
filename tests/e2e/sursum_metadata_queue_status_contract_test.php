<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);
$source = (string) file_get_contents($root . '/web/metadata-store.php');
$functions = substr($source, strpos($source, 'function metadataDb(): PDO'));
eval($functions);

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
initializeMetadataSchema($pdo);

$now = date(DATE_ATOM);
$pdo->prepare(
    'INSERT INTO metadata_sync_jobs
     (id, database_name, status, total_tables, include_relations, include_view_as, created_at, updated_at)
     VALUES ("job-running", "ems2med", "running", 2, 1, 1, :created_at, :updated_at)'
)->execute([':created_at' => $now, ':updated_at' => $now]);
$pdo->exec(
    'INSERT INTO metadata_sync_items(job_id, table_name, status, message, updated_at) VALUES
     ("job-running", "Customer", "done", "ok", "' . $now . '"),
     ("job-running", "Order", "running", "Processando", "' . $now . '")'
);

finishJob($pdo, 'job-running');

$runningCount = (int) $pdo->query('SELECT COUNT(*) FROM metadata_sync_items WHERE job_id = "job-running" AND status = "running"')->fetchColumn();
assertSameInt(0, $runningCount, 'finishJob deve retirar itens presos em running');

$status = (string) $pdo->query('SELECT status FROM metadata_sync_jobs WHERE id = "job-running"')->fetchColumn();
assertSameString('done_with_errors', $status, 'fila com item running finalizado como erro deve terminar done_with_errors');

$pdo->prepare(
    'INSERT INTO metadata_sync_jobs
     (id, database_name, status, total_tables, include_relations, include_view_as, created_at, updated_at)
     VALUES ("job-error", "ems2med", "running", 1, 1, 1, :created_at, :updated_at)'
)->execute([':created_at' => $now, ':updated_at' => $now]);
$pdo->exec('INSERT INTO metadata_sync_items(job_id, table_name, status, message, updated_at) VALUES ("job-error", "Item", "error", "falha", "' . $now . '")');

refreshJobCounters($pdo, 'job-error');

$status = (string) $pdo->query('SELECT status FROM metadata_sync_jobs WHERE id = "job-error"')->fetchColumn();
assertSameString('done_with_errors', $status, 'refreshJobCounters deve preservar done_with_errors quando nao ha pendentes/running');

echo "Metadata queue status contract OK\n";

function assertSameInt(int $expected, int $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ': esperado ' . $expected . ', obtido ' . $actual);
    }
}

function assertSameString(string $expected, string $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ': esperado ' . $expected . ', obtido ' . $actual);
    }
}
