<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $pdo = metadataDb();
    initializeMetadataSchema($pdo);

    $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
    if ($method === 'GET') {
        $resource = text($_GET['resource'] ?? 'view-as');
        if ($resource === 'job') {
            jsonOut(['success' => true, 'data' => loadJob($pdo, text($_GET['id'] ?? ''))]);
        }
        jsonOut(['success' => true, 'data' => loadViewAsRows($pdo, requestScope())]);
    }

    if ($method === 'POST') {
        $payload = json_decode((string) file_get_contents('php://input'), true);
        if (!is_array($payload)) {
            throw new InvalidArgumentException('JSON invalido.');
        }
        $resource = text($payload['resource'] ?? 'view-as');
        if ($resource === 'job') {
            jsonOut(handleJobPost($pdo, $payload));
        }
        jsonOut(handleViewAsPost($pdo, $payload));
    }

    jsonOut(['success' => false, 'error' => 'Metodo nao suportado.'], 405);
} catch (Throwable $error) {
    jsonOut(['success' => false, 'error' => $error->getMessage()], 500);
}

function metadataDb(): PDO
{
    $baseDir = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf';
    if (!is_dir($baseDir) && !mkdir($baseDir, 0775, true) && !is_dir($baseDir)) {
        throw new RuntimeException('Nao foi possivel criar a pasta sursum-conf.');
    }
    $pdo = new PDO('sqlite:' . $baseDir . DIRECTORY_SEPARATOR . 'sursum.sqlite');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->exec('PRAGMA foreign_keys = ON');
    $pdo->exec('PRAGMA journal_mode = WAL');
    return $pdo;
}

function initializeMetadataSchema(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS field_view_as (
            id TEXT PRIMARY KEY,
            environment_id TEXT NOT NULL DEFAULT "",
            company_id TEXT NOT NULL DEFAULT "",
            database_name TEXT NOT NULL,
            table_name TEXT NOT NULL,
            field_name TEXT NOT NULL,
            view_as TEXT NOT NULL DEFAULT "",
            source TEXT NOT NULL DEFAULT "manual",
            raw_json TEXT NOT NULL DEFAULT "{}",
            updated_at TEXT NOT NULL,
            UNIQUE(environment_id, company_id, database_name, table_name, field_name)
        )'
    );
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_field_view_as_lookup ON field_view_as(environment_id, company_id, database_name, table_name)');

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS metadata_sync_jobs (
            id TEXT PRIMARY KEY,
            environment_id TEXT NOT NULL DEFAULT "",
            company_id TEXT NOT NULL DEFAULT "",
            database_name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "pending",
            total_tables INTEGER NOT NULL DEFAULT 0,
            processed_tables INTEGER NOT NULL DEFAULT 0,
            failed_tables INTEGER NOT NULL DEFAULT 0,
            include_relations INTEGER NOT NULL DEFAULT 1,
            include_view_as INTEGER NOT NULL DEFAULT 1,
            existing_metadata_behavior TEXT NOT NULL DEFAULT "skip",
            current_table TEXT NOT NULL DEFAULT "",
            message TEXT NOT NULL DEFAULT "",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )'
    );
    ensureColumn($pdo, 'metadata_sync_jobs', 'existing_metadata_behavior', 'TEXT NOT NULL DEFAULT "skip"');
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS metadata_sync_items (
            job_id TEXT NOT NULL,
            table_name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "pending",
            message TEXT NOT NULL DEFAULT "",
            relation_count INTEGER NOT NULL DEFAULT 0,
            view_as_count INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL,
            PRIMARY KEY(job_id, table_name)
        )'
    );
}

function ensureColumn(PDO $pdo, string $table, string $column, string $definition): void
{
    $stmt = $pdo->query('PRAGMA table_info(' . $table . ')');
    $columns = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    foreach ($columns as $row) {
        if (strcasecmp((string) ($row['name'] ?? ''), $column) === 0) {
            return;
        }
    }
    $pdo->exec('ALTER TABLE ' . $table . ' ADD COLUMN ' . $column . ' ' . $definition);
}

function normalizeExistingMetadataBehavior($value): string
{
    return text($value) === 'update' ? 'update' : 'skip';
}

function handleViewAsPost(PDO $pdo, array $payload): array
{
    $action = text($payload['action'] ?? 'save');
    $scope = requestScope($payload);
    if ($scope['database'] === '' || $scope['table'] === '') {
        throw new InvalidArgumentException('Banco e tabela sao obrigatorios.');
    }

    $rows = [];
    if (isset($payload['rows']) && is_array($payload['rows'])) {
        $rows = $payload['rows'];
    } else {
        $rows[] = [
            'field' => $payload['field'] ?? '',
            'viewAs' => $payload['viewAs'] ?? '',
            'source' => $payload['source'] ?? 'manual',
        ];
    }

    if ($action === 'delete') {
        deleteViewAsRow($pdo, $scope, text($payload['field'] ?? ''));
        return ['success' => true, 'data' => loadViewAsRows($pdo, $scope)];
    }

    saveViewAsRows($pdo, $scope, $rows, text($payload['source'] ?? 'manual') ?: 'manual');
    return ['success' => true, 'data' => loadViewAsRows($pdo, $scope)];
}

function handleJobPost(PDO $pdo, array $payload): array
{
    $action = text($payload['action'] ?? '');
    if ($action === 'create') {
        $scope = requestScope($payload);
        $tables = array_values(array_filter(array_map('text', is_array($payload['tables'] ?? null) ? $payload['tables'] : [])));
        if ($scope['database'] === '' || !$tables) {
            throw new InvalidArgumentException('Banco e lista de tabelas sao obrigatorios.');
        }
        $id = sha1(implode('|', [$scope['environmentId'], $scope['companyId'], $scope['database'], microtime(true), random_int(1000, 999999)]));
        $now = date(DATE_ATOM);
        $existingBehavior = normalizeExistingMetadataBehavior($payload['existingMetadataBehavior'] ?? 'skip');
        $stmt = $pdo->prepare(
            'INSERT INTO metadata_sync_jobs
             (id, environment_id, company_id, database_name, status, total_tables, include_relations, include_view_as, existing_metadata_behavior, created_at, updated_at)
             VALUES (:id, :environment_id, :company_id, :database_name, "pending", :total_tables, :include_relations, :include_view_as, :existing_metadata_behavior, :created_at, :updated_at)'
        );
        $stmt->execute([
            ':id' => $id,
            ':environment_id' => $scope['environmentId'],
            ':company_id' => $scope['companyId'],
            ':database_name' => $scope['database'],
            ':total_tables' => count($tables),
            ':include_relations' => !empty($payload['includeRelations']) ? 1 : 0,
            ':include_view_as' => !empty($payload['includeViewAs']) ? 1 : 0,
            ':existing_metadata_behavior' => $existingBehavior,
            ':created_at' => $now,
            ':updated_at' => $now,
        ]);
        $insertItem = $pdo->prepare('INSERT INTO metadata_sync_items(job_id, table_name, updated_at) VALUES(:job_id, :table_name, :updated_at)');
        foreach ($tables as $table) {
            $insertItem->execute([':job_id' => $id, ':table_name' => $table, ':updated_at' => $now]);
        }
        return ['success' => true, 'data' => loadJob($pdo, $id)];
    }

    if ($action === 'item') {
        updateJobItem($pdo, $payload);
        return ['success' => true, 'data' => loadJob($pdo, text($payload['jobId'] ?? ''))];
    }

    if ($action === 'cancel') {
        cancelJobItems($pdo, $payload);
        return ['success' => true, 'data' => loadJob($pdo, text($payload['jobId'] ?? ''))];
    }

    if ($action === 'reprocess-errors') {
        reprocessJobErrors($pdo, $payload);
        return ['success' => true, 'data' => loadJob($pdo, text($payload['jobId'] ?? ''))];
    }

    if ($action === 'finish') {
        finishJob($pdo, text($payload['jobId'] ?? ''));
        return ['success' => true, 'data' => loadJob($pdo, text($payload['jobId'] ?? ''))];
    }

    throw new InvalidArgumentException('Acao de job invalida.');
}

function requestScope(?array $payload = null): array
{
    $source = $payload ?? $_GET;
    return [
        'environmentId' => text($source['environmentId'] ?? $source['environment_id'] ?? ''),
        'companyId' => text($source['companyId'] ?? $source['company_id'] ?? ''),
        'database' => text($source['database'] ?? $source['databaseName'] ?? ''),
        'table' => text($source['table'] ?? ''),
    ];
}

function loadViewAsRows(PDO $pdo, array $scope): array
{
    if ($scope['database'] === '') {
        return [];
    }
    $sql = 'SELECT * FROM field_view_as WHERE environment_id = :environment_id AND company_id = :company_id AND database_name = :database_name';
    $params = [
        ':environment_id' => $scope['environmentId'],
        ':company_id' => $scope['companyId'],
        ':database_name' => $scope['database'],
    ];
    if ($scope['table'] !== '') {
        $sql .= ' AND lower(table_name) = lower(:table_name)';
        $params[':table_name'] = $scope['table'];
    }
    $sql .= ' ORDER BY table_name, field_name';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return array_map(static function (array $row): array {
        return [
            'id' => $row['id'],
            'database' => $row['database_name'],
            'table' => $row['table_name'],
            'field' => $row['field_name'],
            'viewAs' => $row['view_as'],
            'source' => $row['source'],
            'updatedAt' => $row['updated_at'],
        ];
    }, $stmt->fetchAll(PDO::FETCH_ASSOC));
}

function saveViewAsRows(PDO $pdo, array $scope, array $rows, string $defaultSource): void
{
    $stmt = $pdo->prepare(
        'INSERT OR REPLACE INTO field_view_as
         (id, environment_id, company_id, database_name, table_name, field_name, view_as, source, raw_json, updated_at)
         VALUES (:id, :environment_id, :company_id, :database_name, :table_name, :field_name, :view_as, :source, :raw_json, :updated_at)'
    );
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $field = text($row['field'] ?? $row['name'] ?? '');
        $viewAs = text($row['viewAs'] ?? $row['view_as'] ?? '');
        if ($field === '') {
            continue;
        }
        $stmt->execute([
            ':id' => viewAsId($scope, $field),
            ':environment_id' => $scope['environmentId'],
            ':company_id' => $scope['companyId'],
            ':database_name' => $scope['database'],
            ':table_name' => $scope['table'],
            ':field_name' => $field,
            ':view_as' => $viewAs,
            ':source' => text($row['source'] ?? $defaultSource) ?: $defaultSource,
            ':raw_json' => json_encode($row, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ':updated_at' => date(DATE_ATOM),
        ]);
    }
}

function deleteViewAsRow(PDO $pdo, array $scope, string $field): void
{
    if ($field === '') {
        throw new InvalidArgumentException('Campo obrigatorio.');
    }
    $stmt = $pdo->prepare(
        'DELETE FROM field_view_as
         WHERE environment_id = :environment_id AND company_id = :company_id
           AND database_name = :database_name AND lower(table_name) = lower(:table_name)
           AND lower(field_name) = lower(:field_name)'
    );
    $stmt->execute([
        ':environment_id' => $scope['environmentId'],
        ':company_id' => $scope['companyId'],
        ':database_name' => $scope['database'],
        ':table_name' => $scope['table'],
        ':field_name' => $field,
    ]);
}

function updateJobItem(PDO $pdo, array $payload): void
{
    $jobId = text($payload['jobId'] ?? '');
    $table = text($payload['table'] ?? '');
    $status = text($payload['status'] ?? 'done');
    if ($jobId === '' || $table === '') {
        throw new InvalidArgumentException('Job e tabela sao obrigatorios.');
    }
    $stmt = $pdo->prepare(
        'UPDATE metadata_sync_items
         SET status = :status, message = :message, relation_count = :relation_count, view_as_count = :view_as_count, updated_at = :updated_at
         WHERE job_id = :job_id AND table_name = :table_name'
    );
    $stmt->execute([
        ':status' => in_array($status, ['pending', 'running', 'done', 'error', 'cancelled'], true) ? $status : 'done',
        ':message' => text($payload['message'] ?? ''),
        ':relation_count' => (int) ($payload['relationCount'] ?? 0),
        ':view_as_count' => (int) ($payload['viewAsCount'] ?? 0),
        ':updated_at' => date(DATE_ATOM),
        ':job_id' => $jobId,
        ':table_name' => $table,
    ]);
    refreshJobCounters($pdo, $jobId);
}

function cancelJobItems(PDO $pdo, array $payload): void
{
    $jobId = text($payload['jobId'] ?? '');
    $table = text($payload['table'] ?? '');
    if ($jobId === '') {
        throw new InvalidArgumentException('Job obrigatorio.');
    }

    if ($table !== '') {
        $stmt = $pdo->prepare(
            'UPDATE metadata_sync_items
             SET status = "cancelled", message = :message, updated_at = :updated_at
             WHERE job_id = :job_id AND table_name = :table_name AND status = "pending"'
        );
        $stmt->execute([
            ':message' => 'Cancelado pelo usuario',
            ':updated_at' => date(DATE_ATOM),
            ':job_id' => $jobId,
            ':table_name' => $table,
        ]);
    } else {
        $stmt = $pdo->prepare(
            'UPDATE metadata_sync_items
             SET status = "cancelled", message = :message, updated_at = :updated_at
             WHERE job_id = :job_id AND status = "pending"'
        );
        $stmt->execute([
            ':message' => 'Cancelado pelo usuario',
            ':updated_at' => date(DATE_ATOM),
            ':job_id' => $jobId,
        ]);
    }

    refreshJobCounters($pdo, $jobId);
}

function reprocessJobErrors(PDO $pdo, array $payload): void
{
    $jobId = text($payload['jobId'] ?? '');
    if ($jobId === '') {
        throw new InvalidArgumentException('Job obrigatorio.');
    }

    $stmt = $pdo->prepare(
        'UPDATE metadata_sync_items
         SET status = "pending",
             message = :message,
             relation_count = 0,
             view_as_count = 0,
             updated_at = :updated_at
         WHERE job_id = :job_id AND status = "error"'
    );
    $stmt->execute([
        ':message' => 'Aguardando reprocessamento',
        ':updated_at' => date(DATE_ATOM),
        ':job_id' => $jobId,
    ]);

    refreshJobCounters($pdo, $jobId);
}

function finishJob(PDO $pdo, string $jobId): void
{
    if ($jobId === '') {
        throw new InvalidArgumentException('Job obrigatorio.');
    }
    refreshJobCounters($pdo, $jobId);
    $job = loadJob($pdo, $jobId);
    $status = ((int) ($job['failedTables'] ?? 0)) > 0 ? 'done_with_errors' : 'done';
    if ((int) ($job['cancelledTables'] ?? 0) > 0 && (int) ($job['processedTables'] ?? 0) === 0) {
        $status = 'cancelled';
    }
    $stmt = $pdo->prepare('UPDATE metadata_sync_jobs SET status = :status, current_table = "", updated_at = :updated_at WHERE id = :id');
    $stmt->execute([':status' => $status, ':updated_at' => date(DATE_ATOM), ':id' => $jobId]);
}

function refreshJobCounters(PDO $pdo, string $jobId): void
{
    $stmt = $pdo->prepare(
        'SELECT
            SUM(CASE WHEN status IN ("done", "error") THEN 1 ELSE 0 END) AS processed,
            SUM(CASE WHEN status = "error" THEN 1 ELSE 0 END) AS failed,
            SUM(CASE WHEN status = "cancelled" THEN 1 ELSE 0 END) AS cancelled,
            SUM(CASE WHEN status = "pending" THEN 1 ELSE 0 END) AS pending,
            SUM(CASE WHEN status = "running" THEN 1 ELSE 0 END) AS running,
            MAX(CASE WHEN status = "running" THEN table_name ELSE "" END) AS current_table
         FROM metadata_sync_items WHERE job_id = :job_id'
    );
    $stmt->execute([':job_id' => $jobId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $processed = (int) ($row['processed'] ?? 0);
    $cancelled = (int) ($row['cancelled'] ?? 0);
    $pending = (int) ($row['pending'] ?? 0);
    $running = (int) ($row['running'] ?? 0);
    if ($running > 0) {
        $status = 'running';
    } elseif ($pending > 0) {
        $status = ($processed > 0 || $cancelled > 0) ? 'running' : 'pending';
    } elseif ($cancelled > 0 && $processed === 0) {
        $status = 'cancelled';
    } else {
        $status = 'done';
    }
    $update = $pdo->prepare(
        'UPDATE metadata_sync_jobs
         SET status = :status, processed_tables = :processed, failed_tables = :failed, current_table = :current_table, updated_at = :updated_at
         WHERE id = :id'
    );
    $update->execute([
        ':status' => $status,
        ':processed' => $processed,
        ':failed' => (int) ($row['failed'] ?? 0),
        ':current_table' => text($row['current_table'] ?? ''),
        ':updated_at' => date(DATE_ATOM),
        ':id' => $jobId,
    ]);
}

function loadJob(PDO $pdo, string $id): ?array
{
    if ($id === '') {
        return null;
    }
    $stmt = $pdo->prepare('SELECT * FROM metadata_sync_jobs WHERE id = :id');
    $stmt->execute([':id' => $id]);
    $job = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$job) {
        return null;
    }
    $cancelled = $pdo->prepare('SELECT COUNT(*) FROM metadata_sync_items WHERE job_id = :job_id AND status = "cancelled"');
    $cancelled->execute([':job_id' => $id]);
    $items = $pdo->prepare('SELECT table_name, status, message, relation_count, view_as_count, updated_at FROM metadata_sync_items WHERE job_id = :job_id ORDER BY rowid');
    $items->execute([':job_id' => $id]);
    return [
        'id' => $job['id'],
        'environmentId' => $job['environment_id'],
        'companyId' => $job['company_id'],
        'database' => $job['database_name'],
        'status' => $job['status'],
        'totalTables' => (int) $job['total_tables'],
        'processedTables' => (int) $job['processed_tables'],
        'failedTables' => (int) $job['failed_tables'],
        'cancelledTables' => (int) $cancelled->fetchColumn(),
        'includeRelations' => (bool) $job['include_relations'],
        'includeViewAs' => (bool) $job['include_view_as'],
        'existingMetadataBehavior' => normalizeExistingMetadataBehavior($job['existing_metadata_behavior'] ?? 'skip'),
        'currentTable' => $job['current_table'],
        'message' => $job['message'],
        'createdAt' => $job['created_at'],
        'updatedAt' => $job['updated_at'],
        'items' => array_map(static function (array $row): array {
            return [
                'table' => $row['table_name'],
                'status' => $row['status'],
                'message' => $row['message'],
                'relationCount' => (int) $row['relation_count'],
                'viewAsCount' => (int) $row['view_as_count'],
                'updatedAt' => $row['updated_at'],
            ];
        }, $items->fetchAll(PDO::FETCH_ASSOC)),
    ];
}

function viewAsId(array $scope, string $field): string
{
    return sha1(implode('|', [
        $scope['environmentId'],
        $scope['companyId'],
        $scope['database'],
        strtolower($scope['table']),
        strtolower($field),
    ]));
}

function text($value): string
{
    return trim((string) ($value ?? ''));
}

function jsonOut(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
