<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $pdo = relationDb();
    initializeRelationSchema($pdo);

    $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
    if ($method === 'GET') {
        jsonOut(['success' => true, 'data' => loadRelations($pdo, requestScope())]);
    }

    if ($method === 'POST') {
        $payload = json_decode((string) file_get_contents('php://input'), true);
        if (!is_array($payload)) {
            throw new InvalidArgumentException('JSON invalido.');
        }
        $scope = requestScope($payload);
        $action = text($payload['action'] ?? 'save');
        if ($action === 'delete') {
            deleteRelation($pdo, $scope, text($payload['id'] ?? ''));
            jsonOut(['success' => true, 'data' => loadRelations($pdo, $scope)]);
        }
        $relations = $payload['relations'] ?? $payload['data'] ?? [];
        if (!is_array($relations)) {
            throw new InvalidArgumentException('Campo relations deve ser uma lista.');
        }
        $source = text($payload['source'] ?? 'manual') ?: 'manual';
        $replaceId = text($payload['replaceId'] ?? '');
        saveRelations($pdo, $scope, $relations, $source, strcasecmp($source, 'manual') !== 0, $replaceId);
        jsonOut(['success' => true, 'data' => loadRelations($pdo, $scope)]);
    }

    jsonOut(['success' => false, 'error' => 'Metodo nao suportado.'], 405);
} catch (Throwable $error) {
    jsonOut(['success' => false, 'error' => $error->getMessage()], 500);
}

function relationDb(): PDO
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

function initializeRelationSchema(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS table_relations (
            id TEXT PRIMARY KEY,
            environment_id TEXT NOT NULL DEFAULT "",
            company_id TEXT NOT NULL DEFAULT "",
            database_name TEXT NOT NULL,
            left_database TEXT NOT NULL,
            left_table TEXT NOT NULL,
            left_field TEXT NOT NULL DEFAULT "",
            right_database TEXT NOT NULL,
            right_table TEXT NOT NULL,
            right_field TEXT NOT NULL DEFAULT "",
            relation_type TEXT NOT NULL DEFAULT "INNER",
            source TEXT NOT NULL DEFAULT "manual",
            fields_json TEXT NOT NULL DEFAULT "[]",
            raw_json TEXT NOT NULL DEFAULT "{}",
            updated_at TEXT NOT NULL,
            UNIQUE(environment_id, company_id, database_name, left_database, left_table, left_field, right_database, right_table, right_field)
        )'
    );
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_table_relations_lookup ON table_relations(environment_id, company_id, database_name, left_table, right_table)');
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

function loadRelations(PDO $pdo, array $scope): array
{
    if ($scope['database'] === '' || $scope['table'] === '') {
        return [];
    }

    $stmt = $pdo->prepare(
        'SELECT * FROM table_relations
         WHERE environment_id = :environment_id
           AND company_id = :company_id
           AND database_name = :database_name
           AND ((lower(left_table) = lower(:table_name)) OR (lower(right_table) = lower(:table_name)))
         ORDER BY left_table, right_table, left_field, right_field'
    );
    $stmt->execute([
        ':environment_id' => $scope['environmentId'],
        ':company_id' => $scope['companyId'],
        ':database_name' => $scope['database'],
        ':table_name' => $scope['table'],
    ]);

    return array_map(static function (array $row): array {
        return [
            'id' => $row['id'],
            'database' => $row['database_name'],
            'leftDatabase' => $row['left_database'],
            'leftTable' => $row['left_table'],
            'leftField' => $row['left_field'],
            'rightDatabase' => $row['right_database'],
            'rightTable' => $row['right_table'],
            'rightField' => $row['right_field'],
            'type' => $row['relation_type'],
            'source' => $row['source'],
            'fields' => json_decode($row['fields_json'], true) ?: [],
            'updatedAt' => $row['updated_at'],
        ];
    }, $stmt->fetchAll(PDO::FETCH_ASSOC));
}

function saveRelations(PDO $pdo, array $scope, array $relations, string $source, bool $replaceExisting = true, string $replaceId = ''): void
{
    if ($scope['database'] === '' || $scope['table'] === '') {
        throw new InvalidArgumentException('Banco e tabela sao obrigatorios.');
    }

    $pdo->beginTransaction();
    try {
        if ($replaceId !== '') {
            deleteRelation($pdo, $scope, $replaceId);
        }
        if ($replaceExisting) {
            $delete = $pdo->prepare(
                'DELETE FROM table_relations
                 WHERE environment_id = :environment_id
                   AND company_id = :company_id
                   AND database_name = :database_name
                   AND ((lower(left_table) = lower(:table_name)) OR (lower(right_table) = lower(:table_name)))
                   AND source = :source'
            );
            $delete->execute([
                ':environment_id' => $scope['environmentId'],
                ':company_id' => $scope['companyId'],
                ':database_name' => $scope['database'],
                ':table_name' => $scope['table'],
                ':source' => $source,
            ]);
        }

        $insert = $pdo->prepare(
            'INSERT OR REPLACE INTO table_relations
             (id, environment_id, company_id, database_name, left_database, left_table, left_field, right_database, right_table, right_field, relation_type, source, fields_json, raw_json, updated_at)
             VALUES (:id, :environment_id, :company_id, :database_name, :left_database, :left_table, :left_field, :right_database, :right_table, :right_field, :relation_type, :source, :fields_json, :raw_json, :updated_at)'
        );
        $manualLookup = null;
        if (strcasecmp($source, 'manual') !== 0) {
            $manualLookup = $pdo->prepare(
                'SELECT 1 FROM table_relations
                 WHERE environment_id = :environment_id
                   AND company_id = :company_id
                   AND database_name = :database_name
                   AND lower(left_database) = lower(:left_database)
                   AND lower(left_table) = lower(:left_table)
                   AND lower(left_field) = lower(:left_field)
                   AND lower(right_database) = lower(:right_database)
                   AND lower(right_table) = lower(:right_table)
                   AND lower(right_field) = lower(:right_field)
                   AND source = "manual"
                 LIMIT 1'
            );
        }
        foreach ($relations as $relation) {
            if (!is_array($relation)) {
                continue;
            }
            $leftTable = text($relation['leftTable'] ?? $relation['left'] ?? '');
            $rightTable = text($relation['rightTable'] ?? $relation['right'] ?? '');
            if ($leftTable === '' || $rightTable === '') {
                continue;
            }
            $leftDatabase = text($relation['leftDatabase'] ?? $relation['database'] ?? $scope['database']);
            $rightDatabase = text($relation['rightDatabase'] ?? $relation['database'] ?? $scope['database']);
            $leftField = text($relation['leftField'] ?? '');
            $rightField = text($relation['rightField'] ?? '');
            $fields = is_array($relation['fields'] ?? null) ? $relation['fields'] : [];
            if (($leftField === '' || $rightField === '') && count($fields) === 1 && is_array($fields[0])) {
                $leftField = text($fields[0]['leftField'] ?? $fields[0]['name'] ?? $leftField);
                $rightField = text($fields[0]['rightField'] ?? $fields[0]['name'] ?? $rightField);
            }
            if ($manualLookup && manualRelationExists($manualLookup, $scope, $leftDatabase, $leftTable, $leftField, $rightDatabase, $rightTable, $rightField)) {
                continue;
            }
            $insert->execute([
                ':id' => relationId($scope, $leftDatabase, $leftTable, $leftField, $rightDatabase, $rightTable, $rightField),
                ':environment_id' => $scope['environmentId'],
                ':company_id' => $scope['companyId'],
                ':database_name' => $scope['database'],
                ':left_database' => $leftDatabase,
                ':left_table' => $leftTable,
                ':left_field' => $leftField,
                ':right_database' => $rightDatabase,
                ':right_table' => $rightTable,
                ':right_field' => $rightField,
                ':relation_type' => text($relation['type'] ?? 'INNER') ?: 'INNER',
                ':source' => $source,
                ':fields_json' => json_encode($fields, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                ':raw_json' => json_encode($relation, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                ':updated_at' => date(DATE_ATOM),
            ]);
        }
        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
}

function deleteRelation(PDO $pdo, array $scope, string $id): void
{
    if ($id === '') {
        throw new InvalidArgumentException('Join obrigatorio.');
    }
    $stmt = $pdo->prepare(
        'DELETE FROM table_relations
         WHERE id = :id
           AND environment_id = :environment_id
           AND company_id = :company_id
           AND database_name = :database_name'
    );
    $stmt->execute([
        ':id' => $id,
        ':environment_id' => $scope['environmentId'],
        ':company_id' => $scope['companyId'],
        ':database_name' => $scope['database'],
    ]);
}

function manualRelationExists(PDOStatement $stmt, array $scope, string $leftDatabase, string $leftTable, string $leftField, string $rightDatabase, string $rightTable, string $rightField): bool
{
    $stmt->execute([
        ':environment_id' => $scope['environmentId'],
        ':company_id' => $scope['companyId'],
        ':database_name' => $scope['database'],
        ':left_database' => $leftDatabase,
        ':left_table' => $leftTable,
        ':left_field' => $leftField,
        ':right_database' => $rightDatabase,
        ':right_table' => $rightTable,
        ':right_field' => $rightField,
    ]);
    return (bool) $stmt->fetchColumn();
}

function relationId(array $scope, string $leftDatabase, string $leftTable, string $leftField, string $rightDatabase, string $rightTable, string $rightField): string
{
    return sha1(implode('|', [
        $scope['environmentId'],
        $scope['companyId'],
        $scope['database'],
        strtolower($leftDatabase),
        strtolower($leftTable),
        strtolower($leftField),
        strtolower($rightDatabase),
        strtolower($rightTable),
        strtolower($rightField),
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
