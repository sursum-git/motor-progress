<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

// Detalhe de uma requisicao: request-log-store.php?action=detail&id=<id>
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $pdo = requestLogStoreDb();
    initializeRequestLogStoreSchema($pdo);
    $action = trim((string) ($_GET['action'] ?? 'list'));
    if ($action === 'detail') {
        jsonOut(['success' => true, 'data' => loadRequestLogDetail($pdo, trim((string) ($_GET['id'] ?? '')))]);
    }
    jsonOut(['success' => true, 'data' => loadRequestLogList($pdo)]);
} catch (Throwable $error) {
    jsonOut(['success' => false, 'error' => $error->getMessage()], 500);
}

function requestLogStoreDb(): PDO
{
    $baseDir = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf';
    if (!is_dir($baseDir) && !mkdir($baseDir, 0775, true) && !is_dir($baseDir)) {
        throw new RuntimeException('Nao foi possivel criar a pasta sursum-conf.');
    }
    $pdo = new PDO('sqlite:' . $baseDir . DIRECTORY_SEPARATOR . 'sursum.sqlite');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_TIMEOUT, 30);
    $pdo->exec('PRAGMA busy_timeout = 30000');
    $pdo->exec('PRAGMA journal_mode = WAL');
    return $pdo;
}

function initializeRequestLogStoreSchema(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS request_logs (
            id TEXT PRIMARY KEY,
            started_at TEXT NOT NULL,
            finished_at TEXT NOT NULL DEFAULT "",
            duration_ms INTEGER NOT NULL DEFAULT 0,
            method TEXT NOT NULL,
            target TEXT NOT NULL,
            request_query_json TEXT NOT NULL DEFAULT "{}",
            request_body_json TEXT NOT NULL DEFAULT "",
            response_status INTEGER NOT NULL DEFAULT 0,
            response_body_json TEXT NOT NULL DEFAULT "",
            error_message TEXT NOT NULL DEFAULT "",
            user_name TEXT NOT NULL DEFAULT "",
            remote_addr TEXT NOT NULL DEFAULT "",
            created_at TEXT NOT NULL
        )'
    );
}

function loadRequestLogList(PDO $pdo): array
{
    $limit = max(1, min(500, (int) ($_GET['limit'] ?? 100)));
    $status = trim((string) ($_GET['status'] ?? ''));
    $search = trim((string) ($_GET['search'] ?? ''));
    $where = [];
    $params = [];
    if ($status !== '') {
        $where[] = 'response_status = :status';
        $params[':status'] = (int) $status;
    }
    if ($search !== '') {
        $where[] = '(target LIKE :search OR request_body_json LIKE :search OR response_body_json LIKE :search OR error_message LIKE :search)';
        $params[':search'] = '%' . $search . '%';
    }
    $sql = 'SELECT id, started_at, finished_at, duration_ms, method, target, response_status, error_message, user_name, remote_addr
            FROM request_logs';
    if ($where) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY started_at DESC LIMIT :limit';
    $stmt = $pdo->prepare($sql);
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value, is_int($value) ? PDO::PARAM_INT : PDO::PARAM_STR);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->execute();
    return array_map('mapRequestLogSummary', $stmt->fetchAll(PDO::FETCH_ASSOC));
}

function loadRequestLogDetail(PDO $pdo, string $id): array
{
    if ($id === '') {
        throw new InvalidArgumentException('Id obrigatorio.');
    }
    $stmt = $pdo->prepare('SELECT * FROM request_logs WHERE id = :id');
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        throw new RuntimeException('Registro nao encontrado.');
    }
    return mapRequestLogDetail($row);
}

function mapRequestLogSummary(array $row): array
{
    return [
        'id' => (string) $row['id'],
        'startedAt' => (string) $row['started_at'],
        'finishedAt' => (string) $row['finished_at'],
        'durationMs' => (int) $row['duration_ms'],
        'method' => (string) $row['method'],
        'target' => (string) $row['target'],
        'responseStatus' => (int) $row['response_status'],
        'errorMessage' => (string) $row['error_message'],
        'userName' => (string) $row['user_name'],
        'remoteAddr' => (string) $row['remote_addr'],
    ];
}

function mapRequestLogDetail(array $row): array
{
    $summary = mapRequestLogSummary($row);
    $summary['requestQueryJson'] = (string) $row['request_query_json'];
    $summary['requestBodyJson'] = (string) $row['request_body_json'];
    $summary['responseBodyJson'] = (string) $row['response_body_json'];
    return $summary;
}

function jsonOut(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    exit;
}
