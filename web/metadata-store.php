<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $pdo = metadataDb();
    [$payload, $status] = withSursumSqliteLock(static function () use ($pdo): array {
        initializeMetadataSchema($pdo);

        $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
        if ($method === 'GET') {
            $resource = text($_GET['resource'] ?? 'view-as');
            if ($resource === 'job') {
                return [['success' => true, 'data' => loadJob($pdo, text($_GET['id'] ?? ''))], 200];
            }
            return [['success' => true, 'data' => loadViewAsRows($pdo, requestScope())], 200];
        }

        if ($method === 'POST') {
            $requestPayload = json_decode((string) file_get_contents('php://input'), true);
            if (!is_array($requestPayload)) {
                throw new InvalidArgumentException('JSON invalido.');
            }
            $resource = text($requestPayload['resource'] ?? 'view-as');
            if ($resource === 'job') {
                return [handleJobPost($pdo, $requestPayload), 200];
            }
            return [handleViewAsPost($pdo, $requestPayload), 200];
        }

        return [['success' => false, 'error' => 'Metodo nao suportado.'], 405];
    });
    jsonOut($payload, $status);
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
    $pdo->setAttribute(PDO::ATTR_TIMEOUT, 30);
    $pdo->exec('PRAGMA foreign_keys = ON');
    $pdo->exec('PRAGMA busy_timeout = 30000');
    $pdo->exec('PRAGMA journal_mode = WAL');
    return $pdo;
}

function withSursumSqliteLock(callable $callback): array
{
    $lockPath = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf' . DIRECTORY_SEPARATOR . 'sursum.sqlite.lock';
    $handle = @fopen($lockPath, 'c');
    if ($handle === false) {
        $lockPath = rtrim(sys_get_temp_dir(), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . 'sursum-sqlite-' . sha1(__DIR__) . '.lock';
        $handle = @fopen($lockPath, 'c');
    }
    if ($handle === false) {
        throw new RuntimeException('Nao foi possivel abrir o lock do SQLite.');
    }

    try {
        if (!flock($handle, LOCK_EX)) {
            throw new RuntimeException('Nao foi possivel bloquear o SQLite.');
        }
        return $callback();
    } finally {
        flock($handle, LOCK_UN);
        fclose($handle);
    }
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
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_field_view_as_table_field ON field_view_as(table_name, field_name)');
    canonicalizeViewAsRows($pdo);
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS field_view_as_options (
            id TEXT PRIMARY KEY,
            view_as_id TEXT NOT NULL,
            environment_id TEXT NOT NULL DEFAULT "",
            company_id TEXT NOT NULL DEFAULT "",
            database_name TEXT NOT NULL DEFAULT "",
            table_name TEXT NOT NULL,
            field_name TEXT NOT NULL,
            option_order INTEGER NOT NULL DEFAULT 0,
            label TEXT NOT NULL DEFAULT "",
            value TEXT NOT NULL DEFAULT "",
            source TEXT NOT NULL DEFAULT "manual",
            updated_at TEXT NOT NULL,
            UNIQUE(view_as_id, option_order)
        )'
    );
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_field_view_as_options_lookup ON field_view_as_options(environment_id, company_id, database_name, table_name, field_name)');
    migrateViewAsOptionsFromRawJson($pdo);

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
    if ($action === 'import-csv') {
        importViewAsCsv($pdo, $payload);
        return ['success' => true, 'data' => loadViewAsRows($pdo, $scope)];
    }

    if ($action === 'list') {
        return ['success' => true, 'data' => loadViewAsRows($pdo, $scope)];
    }

    if ($scope['table'] === '') {
        throw new InvalidArgumentException('Tabela obrigatoria.');
    }

    $rows = [];
    if (isset($payload['rows']) && is_array($payload['rows'])) {
        $rows = $payload['rows'];
    } else {
        $rows[] = [
            'field' => $payload['field'] ?? '',
            'viewAs' => $payload['viewAs'] ?? '',
            'listExpression' => $payload['listExpression'] ?? '',
            'options' => is_array($payload['options'] ?? null) ? $payload['options'] : [],
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
        'includeLegacy' => text($source['includeLegacy'] ?? $source['include_legacy'] ?? '') === '1',
        'tableNames' => requestTableNames($source),
    ];
}

function requestTableNames(array $source): array
{
    $raw = $source['tableNames'] ?? $source['table_names'] ?? [];
    if (is_string($raw)) {
        $decoded = json_decode($raw, true);
        if (is_array($decoded)) {
            $raw = $decoded;
        } else {
            $raw = explode(',', $raw);
        }
    }
    if (!is_array($raw)) {
        return [];
    }
    $names = [];
    foreach ($raw as $name) {
        $text = text($name);
        if ($text !== '') {
            $names[strtolower($text)] = $text;
        }
    }
    return array_values($names);
}

function loadViewAsRows(PDO $pdo, array $scope): array
{
    $sql = 'SELECT * FROM field_view_as WHERE environment_id = "" AND company_id = ""';
    $params = [];
    if ($scope['database'] !== '') {
        $sql .= !empty($scope['includeLegacy'])
            ? ' AND (lower(database_name) = lower(:database_name) OR database_name = "")'
            : ' AND lower(database_name) = lower(:database_name)';
        $params[':database_name'] = $scope['database'];
    }
    if ($scope['table'] !== '') {
        $sql .= ' AND lower(table_name) = lower(:table_name)';
        $params[':table_name'] = $scope['table'];
    } elseif (!empty($scope['tableNames'])) {
        $tableNames = array_values(array_filter(array_map('text', $scope['tableNames'])));
        if ($tableNames) {
            $placeholders = [];
            foreach ($tableNames as $index => $tableName) {
                $placeholder = ':table_name_' . $index;
                $placeholders[] = $placeholder;
                $params[$placeholder] = strtolower($tableName);
            }
            $sql .= ' AND lower(table_name) IN (' . implode(',', $placeholders) . ')';
        }
    }
    $sql .= ' ORDER BY table_name, field_name';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $optionsByViewAs = loadViewAsOptions($pdo, array_map(static function (array $row): string {
        return (string) $row['id'];
    }, $rows));
    return array_map(static function (array $row) use ($optionsByViewAs): array {
        $raw = json_decode((string) ($row['raw_json'] ?? '{}'), true);
        if (!is_array($raw)) {
            $raw = [];
        }
        $options = $optionsByViewAs[(string) $row['id']] ?? [];
        $listExpression = $options ? viewAsListExpression($options) : text($raw['listExpression'] ?? '');
        return [
            'id' => $row['id'],
            'database' => $row['database_name'],
            'table' => $row['table_name'],
            'field' => $row['field_name'],
            'viewAs' => $row['view_as'],
            'listExpression' => $listExpression,
            'options' => $options,
            'source' => $row['source'],
            'updatedAt' => $row['updated_at'],
        ];
    }, $rows);
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
        $source = text($row['source'] ?? $defaultSource) ?: $defaultSource;
        $id = viewAsId($scope, $field);
        $stmt->execute([
            ':id' => $id,
            ':environment_id' => '',
            ':company_id' => '',
            ':database_name' => $scope['database'],
            ':table_name' => $scope['table'],
            ':field_name' => $field,
            ':view_as' => $viewAs,
            ':source' => $source,
            ':raw_json' => json_encode($row, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ':updated_at' => date(DATE_ATOM),
        ]);
        $hasOptionPayload = array_key_exists('options', $row) || array_key_exists('listExpression', $row);
        $options = text($row['listExpression'] ?? '') !== ''
            ? parseViewAsOptionsText((string) $row['listExpression'])
            : normalizeViewAsOptions($row['options'] ?? []);
        if ($hasOptionPayload || $options) {
            saveViewAsOptions($pdo, $scope, $id, $field, $options, $source);
        }
    }
}

function deleteViewAsRow(PDO $pdo, array $scope, string $field): void
{
    if ($field === '') {
        throw new InvalidArgumentException('Campo obrigatorio.');
    }
        $deleteOptions = $pdo->prepare(
            'DELETE FROM field_view_as_options
             WHERE lower(database_name) = lower(:database_name)
               AND lower(table_name) = lower(:table_name)
               AND lower(field_name) = lower(:field_name)'
        );
        $deleteOptions->execute([
            ':database_name' => $scope['database'],
            ':table_name' => $scope['table'],
            ':field_name' => $field,
        ]);
	    $stmt = $pdo->prepare(
	        'DELETE FROM field_view_as
	         WHERE lower(database_name) = lower(:database_name)
	           AND lower(table_name) = lower(:table_name)
	           AND lower(field_name) = lower(:field_name)'
	    );
	    $stmt->execute([
	        ':database_name' => $scope['database'],
	        ':table_name' => $scope['table'],
	        ':field_name' => $field,
	    ]);
}

function loadViewAsOptions(PDO $pdo, array $viewAsIds): array
{
    $viewAsIds = array_values(array_filter(array_unique($viewAsIds), static function (string $id): bool {
        return $id !== '';
    }));
    if (!$viewAsIds) {
        return [];
    }
    $placeholders = implode(',', array_fill(0, count($viewAsIds), '?'));
    $stmt = $pdo->prepare(
        'SELECT view_as_id, label, value
         FROM field_view_as_options
         WHERE view_as_id IN (' . $placeholders . ')
         ORDER BY view_as_id, option_order'
    );
    $stmt->execute($viewAsIds);
    $grouped = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $grouped[(string) $row['view_as_id']][] = [
            'label' => (string) $row['label'],
            'value' => (string) $row['value'],
        ];
    }
    return $grouped;
}

function saveViewAsOptions(PDO $pdo, array $scope, string $viewAsId, string $field, array $options, string $source): void
{
    $delete = $pdo->prepare('DELETE FROM field_view_as_options WHERE view_as_id = :view_as_id');
    $delete->execute([':view_as_id' => $viewAsId]);

    $stmt = $pdo->prepare(
        'INSERT OR REPLACE INTO field_view_as_options
         (id, view_as_id, environment_id, company_id, database_name, table_name, field_name, option_order, label, value, source, updated_at)
         VALUES (:id, :view_as_id, "", "", :database_name, :table_name, :field_name, :option_order, :label, :value, :source, :updated_at)'
    );
    foreach (array_values($options) as $index => $option) {
        $label = text($option['label'] ?? $option['text'] ?? '');
        $value = text($option['value'] ?? $label);
        if ($label === '') {
            continue;
        }
        $stmt->execute([
            ':id' => sha1($viewAsId . '|' . $index),
            ':view_as_id' => $viewAsId,
            ':database_name' => $scope['database'],
            ':table_name' => $scope['table'],
            ':field_name' => $field,
            ':option_order' => $index,
            ':label' => cleanViewAsOptionToken($label),
            ':value' => cleanViewAsOptionToken($value),
            ':source' => $source,
            ':updated_at' => date(DATE_ATOM),
        ]);
    }
}

function migrateViewAsOptionsFromRawJson(PDO $pdo): void
{
    $rows = $pdo->query(
        'SELECT id, database_name, table_name, field_name, source, raw_json
         FROM field_view_as
         WHERE raw_json <> "" AND raw_json <> "{}"'
    )->fetchAll(PDO::FETCH_ASSOC);
    $countStmt = $pdo->prepare('SELECT COUNT(*) FROM field_view_as_options WHERE view_as_id = :view_as_id');
    foreach ($rows as $row) {
        $countStmt->execute([':view_as_id' => $row['id']]);
        if ((int) $countStmt->fetchColumn() > 0) {
            continue;
        }
        $raw = json_decode((string) ($row['raw_json'] ?? '{}'), true);
        if (!is_array($raw)) {
            continue;
        }
        $options = text($raw['listExpression'] ?? '') !== ''
            ? parseViewAsOptionsText((string) $raw['listExpression'])
            : normalizeViewAsOptions($raw['options'] ?? []);
        if (!$options) {
            continue;
        }
        saveViewAsOptions($pdo, [
            'database' => text($row['database_name'] ?? ''),
            'table' => text($row['table_name'] ?? ''),
        ], (string) $row['id'], text($row['field_name'] ?? ''), $options, text($row['source'] ?? 'migration') ?: 'migration');
    }
}

function normalizeViewAsOptions($options): array
{
    if (!is_array($options)) {
        return [];
    }
    $normalized = [];
    foreach ($options as $option) {
        if (!is_array($option)) {
            continue;
        }
        $label = text($option['label'] ?? $option['text'] ?? '');
        $value = text($option['value'] ?? $label);
        if ($label !== '') {
            $normalized[] = ['label' => $label, 'value' => $value];
        }
    }
    return $normalized;
}

function parseViewAsOptionsText(string $listExpression): array
{
    $tokens = str_getcsv($listExpression);
    $options = [];
    for ($index = 0; $index < count($tokens); $index += 2) {
        $label = cleanViewAsOptionToken((string) ($tokens[$index] ?? ''));
        $value = cleanViewAsOptionToken((string) ($tokens[$index + 1] ?? $label));
        if ($label !== '') {
            $options[] = ['label' => $label, 'value' => $value];
        }
    }
    return $options;
}

function cleanViewAsOptionToken(string $value): string
{
    $text = text(str_replace(['"', "'", '/'], '', $value));
    $text = preg_replace('/\s+(?:HORIZONTAL|VERTICAL|SIZE|FONT|FORMAT|NO-UNDO|HELP|TOOLTIP)\b.*$/i', '', $text) ?? $text;
    return text($text);
}

function viewAsListExpression(array $options): string
{
    return implode(',', array_map(static function (array $option): string {
        $label = viewAsOptionToken((string) ($option['label'] ?? ''));
        $value = viewAsOptionToken((string) ($option['value'] ?? ''), false);
        return $label . ',' . $value;
    }, $options));
}

function viewAsOptionToken(string $value, bool $preferQuoted = true): string
{
    if ($preferQuoted || $value === '' || preg_match('/[,"\s]/', $value)) {
        return '"' . str_replace('"', '""', $value) . '"';
    }
    return $value;
}

function canonicalizeViewAsRows(PDO $pdo): void
{
    $count = (int) $pdo->query('SELECT COUNT(*) FROM field_view_as WHERE environment_id <> "" OR company_id <> ""')->fetchColumn();
    if ($count === 0) {
        return;
    }

    $rows = $pdo->query(
        'SELECT * FROM field_view_as
         ORDER BY lower(table_name), lower(field_name), updated_at'
    )->fetchAll(PDO::FETCH_ASSOC);

    $latest = [];
    foreach ($rows as $row) {
        $table = text($row['table_name'] ?? '');
        $field = text($row['field_name'] ?? '');
        if ($table === '' || $field === '') {
            continue;
        }
        $database = text($row['database_name'] ?? '');
        $latest[strtolower($database) . '|' . strtolower($table) . '|' . strtolower($field)] = $row;
    }

    $pdo->beginTransaction();
    try {
        $pdo->exec('DELETE FROM field_view_as');
        $stmt = $pdo->prepare(
            'INSERT OR REPLACE INTO field_view_as
             (id, environment_id, company_id, database_name, table_name, field_name, view_as, source, raw_json, updated_at)
             VALUES (:id, "", "", :database_name, :table_name, :field_name, :view_as, :source, :raw_json, :updated_at)'
        );
        foreach ($latest as $row) {
            $database = text($row['database_name'] ?? '');
            $table = text($row['table_name'] ?? '');
            $field = text($row['field_name'] ?? '');
            $stmt->execute([
                ':id' => viewAsId(['database' => $database, 'table' => $table], $field),
                ':database_name' => $database,
                ':table_name' => $table,
                ':field_name' => $field,
                ':view_as' => text($row['view_as'] ?? ''),
                ':source' => text($row['source'] ?? 'manual') ?: 'manual',
                ':raw_json' => text($row['raw_json'] ?? '{}') ?: '{}',
                ':updated_at' => text($row['updated_at'] ?? '') ?: date(DATE_ATOM),
            ]);
        }
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
}

function importViewAsCsv(PDO $pdo, array $payload): void
{
    $csv = (string) ($payload['csvText'] ?? $payload['csv'] ?? '');
    if (trim($csv) === '') {
        throw new InvalidArgumentException('Arquivo CSV vazio.');
    }

    $rows = parseViewAsCsv($csv);
    if (!$rows) {
        throw new InvalidArgumentException('Nenhum view-as valido encontrado no CSV.');
    }

	    $stmt = $pdo->prepare(
	        'INSERT OR REPLACE INTO field_view_as
	         (id, environment_id, company_id, database_name, table_name, field_name, view_as, source, raw_json, updated_at)
	         VALUES (:id, "", "", :database_name, :table_name, :field_name, :view_as, "CSV", :raw_json, :updated_at)'
	    );
    foreach ($rows as $row) {
        $stmt->execute([
            ':id' => viewAsId(['database' => text($payload['database'] ?? ''), 'table' => $row['table']], $row['field']),
            ':database_name' => text($payload['database'] ?? ''),
            ':table_name' => $row['table'],
            ':field_name' => $row['field'],
            ':view_as' => $row['viewAs'],
            ':raw_json' => json_encode($row, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ':updated_at' => date(DATE_ATOM),
        ]);
    }
}

function parseViewAsCsv(string $csv): array
{
    $csv = preg_replace('/^\xEF\xBB\xBF/', '', $csv) ?? $csv;
    $lines = preg_split('/\R/', $csv) ?: [];
    $lines = array_values(array_filter($lines, static function (string $line): bool {
        return trim($line) !== '';
    }));
    if (!$lines) {
        return [];
    }

    $delimiter = csvDelimiter($lines[0]);
    $header = array_map('normalizeCsvHeader', str_getcsv(array_shift($lines), $delimiter) ?: []);
    $tableIndex = findCsvColumn($header, ['tabela', 'table']);
    $fieldIndex = findCsvColumn($header, ['campo', 'field', 'banco']);
    $viewAsIndex = findCsvColumn($header, ['lista_de_opcoes', 'lista_opcoes', 'lista de opcoes', 'lista de opções', 'opcoes', 'opções', 'view_as', 'viewas', 'view-as']);
    if ($tableIndex < 0 || $fieldIndex < 0 || $viewAsIndex < 0) {
        throw new InvalidArgumentException('CSV deve conter as colunas tabela, campo e lista de opcoes.');
    }

    $rows = [];
    foreach ($lines as $line) {
        $cols = str_getcsv($line, $delimiter) ?: [];
        $table = text($cols[$tableIndex] ?? '');
        $field = text($cols[$fieldIndex] ?? '');
        $viewAs = text($cols[$viewAsIndex] ?? '');
        if ($table === '' || $field === '' || $viewAs === '') {
            continue;
        }
        $rows[] = ['table' => $table, 'field' => $field, 'viewAs' => $viewAs];
    }
    return $rows;
}

function csvDelimiter(string $headerLine): string
{
    return substr_count($headerLine, ';') > substr_count($headerLine, ',') ? ';' : ',';
}

function normalizeCsvHeader(string $value): string
{
    $value = strtolower(trim($value));
    $converted = @iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $value);
    if ($converted !== false) {
        $value = $converted;
    }
    $value = str_replace(['-', '/', '.'], '_', $value);
    return preg_replace('/\s+/', ' ', $value) ?? $value;
}

function findCsvColumn(array $header, array $names): int
{
    foreach ($header as $index => $name) {
        if (in_array($name, $names, true)) {
            return (int) $index;
        }
    }
    return -1;
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
    $stmt = $pdo->prepare(
        'UPDATE metadata_sync_items
         SET status = "error",
             message = :message,
             updated_at = :updated_at
         WHERE job_id = :job_id AND status = "running"'
    );
    $stmt->execute([
        ':message' => 'Finalizado sem retorno do processamento.',
        ':updated_at' => date(DATE_ATOM),
        ':job_id' => $jobId,
    ]);

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
    $failed = (int) ($row['failed'] ?? 0);
    $cancelled = (int) ($row['cancelled'] ?? 0);
    $pending = (int) ($row['pending'] ?? 0);
    $running = (int) ($row['running'] ?? 0);
    if ($running > 0) {
        $status = 'running';
    } elseif ($pending > 0) {
        $status = ($processed > 0 || $cancelled > 0) ? 'running' : 'pending';
    } elseif ($cancelled > 0 && $processed === 0) {
        $status = 'cancelled';
    } elseif ($failed > 0) {
        $status = 'done_with_errors';
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
        ':failed' => $failed,
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
        strtolower(text($scope['database'] ?? '')),
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
