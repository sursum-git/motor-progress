<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, "Uso apenas via CLI.\n");
    exit(2);
}

$options = cliOptions($argv);
$dbPath = (string) ($options['db'] ?? dirname(__DIR__) . '/web/sursum-conf/sursum.sqlite');
$apply = array_key_exists('apply', $options);

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec('PRAGMA busy_timeout = 30000');

ensureIndexes($pdo);
$candidates = loadCandidates($pdo);

$resolved = [];
$unresolved = [];
foreach ($candidates as $row) {
    $database = inferDatabase($pdo, $row);
    if ($database === '') {
        $unresolved[] = $row;
        continue;
    }
    $row['resolved_database'] = $database;
    $resolved[] = $row;
}

echo "Registros field_view_as com database vazio: " . count($candidates) . "\n";
echo "Resolvidos: " . count($resolved) . "\n";
echo "Nao resolvidos: " . count($unresolved) . "\n";

if (!$apply) {
    echo "Modo dry-run. Use --apply para gravar.\n";
    printSamples($unresolved);
    exit(0);
}

$pdo->beginTransaction();
try {
    foreach ($resolved as $row) {
        updateViewAsRow($pdo, $row);
    }
    $pdo->commit();
} catch (Throwable $error) {
    $pdo->rollBack();
    throw $error;
}

echo "Atualizados: " . count($resolved) . "\n";
printSamples($unresolved);

function cliOptions(array $argv): array
{
    $options = [];
    foreach (array_slice($argv, 1) as $arg) {
        if (strpos($arg, '--') !== 0) {
            continue;
        }
        $arg = substr($arg, 2);
        if (strpos($arg, '=') === false) {
            $options[$arg] = true;
            continue;
        }
        [$key, $value] = explode('=', $arg, 2);
        $options[$key] = $value;
    }
    return $options;
}

function ensureIndexes(PDO $pdo): void
{
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_fix_view_as_table ON field_view_as(table_name)');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_fix_options_view_as ON field_view_as_options(view_as_id)');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_fix_rel_left ON table_relations(left_table, database_name)');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_fix_rel_right ON table_relations(right_table, database_name)');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_fix_items_table ON metadata_sync_items(table_name, job_id)');
}

function loadCandidates(PDO $pdo): array
{
    return $pdo->query(
        'SELECT id, table_name, field_name, view_as, source, raw_json, updated_at
         FROM field_view_as
         WHERE database_name IS NULL OR trim(database_name) = ""
         ORDER BY updated_at, lower(table_name), lower(field_name)'
    )->fetchAll(PDO::FETCH_ASSOC);
}

function inferDatabase(PDO $pdo, array $row): string
{
    $database = inferDatabaseFromJobWindow($pdo, $row);
    if ($database !== '') {
        return $database;
    }

    $database = inferDatabaseFromRelations($pdo, (string) $row['table_name']);
    if ($database !== '') {
        return $database;
    }

    return inferDatabaseFromJobs($pdo, (string) $row['table_name']);
}

function inferDatabaseFromJobWindow(PDO $pdo, array $row): string
{
    $stmt = $pdo->prepare(
        'SELECT DISTINCT j.database_name
         FROM metadata_sync_items i
         JOIN metadata_sync_jobs j ON j.id = i.job_id
         WHERE lower(i.table_name) = lower(:table_name)
           AND j.database_name <> ""
           AND j.created_at <= :updated_at
           AND j.updated_at >= :updated_at'
    );
    $stmt->execute([
        ':table_name' => (string) $row['table_name'],
        ':updated_at' => (string) $row['updated_at'],
    ]);
    return singleDatabase($stmt->fetchAll(PDO::FETCH_COLUMN));
}

function inferDatabaseFromRelations(PDO $pdo, string $table): string
{
    $stmt = $pdo->prepare(
        'SELECT DISTINCT database_name
         FROM (
             SELECT database_name FROM table_relations WHERE lower(left_table) = lower(:table_name) AND database_name <> ""
             UNION
             SELECT database_name FROM table_relations WHERE lower(right_table) = lower(:table_name) AND database_name <> ""
         )'
    );
    $stmt->execute([':table_name' => $table]);
    return singleDatabase($stmt->fetchAll(PDO::FETCH_COLUMN));
}

function inferDatabaseFromJobs(PDO $pdo, string $table): string
{
    $stmt = $pdo->prepare(
        'SELECT DISTINCT j.database_name
         FROM metadata_sync_items i
         JOIN metadata_sync_jobs j ON j.id = i.job_id
         WHERE lower(i.table_name) = lower(:table_name)
           AND j.database_name <> ""'
    );
    $stmt->execute([':table_name' => $table]);
    return singleDatabase($stmt->fetchAll(PDO::FETCH_COLUMN));
}

function singleDatabase(array $databases): string
{
    $unique = [];
    foreach ($databases as $database) {
        $database = trim((string) $database);
        if ($database !== '') {
            $unique[strtolower($database)] = $database;
        }
    }
    return count($unique) === 1 ? (string) reset($unique) : '';
}

function updateViewAsRow(PDO $pdo, array $row): void
{
    $oldId = (string) $row['id'];
    $database = (string) $row['resolved_database'];
    $table = (string) $row['table_name'];
    $field = (string) $row['field_name'];
    $newId = viewAsId($database, $table, $field);

    if ($newId !== $oldId) {
        $deleteConflictOptions = $pdo->prepare('DELETE FROM field_view_as_options WHERE view_as_id = :view_as_id');
        $deleteConflictOptions->execute([':view_as_id' => $newId]);
        $deleteConflict = $pdo->prepare('DELETE FROM field_view_as WHERE id = :id');
        $deleteConflict->execute([':id' => $newId]);
    }

    $updateRow = $pdo->prepare(
        'UPDATE field_view_as
         SET id = :new_id,
             database_name = :database_name
         WHERE id = :old_id'
    );
    $updateRow->execute([
        ':new_id' => $newId,
        ':database_name' => $database,
        ':old_id' => $oldId,
    ]);

    $options = $pdo->prepare(
        'SELECT option_order
         FROM field_view_as_options
         WHERE view_as_id = :old_id
         ORDER BY option_order'
    );
    $options->execute([':old_id' => $oldId]);
    $orders = $options->fetchAll(PDO::FETCH_COLUMN);

    $updateOption = $pdo->prepare(
        'UPDATE field_view_as_options
         SET id = :id,
             view_as_id = :new_id,
             database_name = :database_name
         WHERE view_as_id = :old_id
           AND option_order = :option_order'
    );
    foreach ($orders as $order) {
        $index = (int) $order;
        $updateOption->execute([
            ':id' => sha1($newId . '|' . $index),
            ':new_id' => $newId,
            ':database_name' => $database,
            ':old_id' => $oldId,
            ':option_order' => $index,
        ]);
    }
}

function viewAsId(string $database, string $table, string $field): string
{
    return sha1(implode('|', [
        strtolower(trim($database)),
        strtolower(trim($table)),
        strtolower(trim($field)),
    ]));
}

function printSamples(array $rows): void
{
    if (!$rows) {
        return;
    }
    echo "Amostra nao resolvida:\n";
    foreach (array_slice($rows, 0, 30) as $row) {
        echo (string) $row['table_name'] . "\t" . (string) $row['field_name'] . "\t" . (string) $row['updated_at'] . "\n";
    }
}
