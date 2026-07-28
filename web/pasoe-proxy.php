<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
if (!in_array($method, ['GET', 'POST'], true)) {
    proxyJson(405, ['success' => false, 'error' => 'Metodo nao suportado pelo proxy PASOE.']);
}

$target = trim((string) ($_GET['target'] ?? ''));
if ($target === '') {
    proxyJson(400, ['success' => false, 'error' => 'Destino PASOE nao informado.']);
}

$parts = parse_url($target);
if (!is_array($parts) || !in_array(strtolower((string) ($parts['scheme'] ?? '')), ['http', 'https'], true) || empty($parts['host'])) {
    proxyJson(400, ['success' => false, 'error' => 'Destino PASOE invalido.']);
}

$match = findAllowedPasoeTarget($target);
if ($match === null) {
    proxyJson(403, ['success' => false, 'error' => 'Destino PASOE nao esta cadastrado no contexto.']);
}

$requestBody = $method === 'POST' ? (file_get_contents('php://input') ?: '') : '';
$logId = startRequestLog($method, $target, $requestBody);

$headers = ['Accept: application/json'];
if ($method === 'POST') {
    $contentType = trim((string) ($_SERVER['CONTENT_TYPE'] ?? 'application/json; charset=utf-8'));
    $headers[] = 'Content-Type: ' . ($contentType !== '' ? $contentType : 'application/json; charset=utf-8');
}
if (($match['auth_mode'] ?? '') === 'header' && trim((string) ($match['authorization'] ?? '')) !== '') {
    $headers[] = 'Authorization: ' . trim((string) $match['authorization']);
}

$ch = curl_init($target);
if ($ch === false) {
    $payload = ['success' => false, 'error' => 'Nao foi possivel iniciar cURL.'];
    finishRequestLog($logId, 500, json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '', 'Nao foi possivel iniciar cURL.');
    proxyJson(500, $payload);
}

$verifySsl = !isPrivateHost((string) $parts['host']);
curl_setopt_array($ch, [
    CURLOPT_CUSTOMREQUEST => $method,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HEADER => true,
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_CONNECTTIMEOUT => 10,
    CURLOPT_TIMEOUT => 120,
    CURLOPT_SSL_VERIFYPEER => $verifySsl,
    CURLOPT_SSL_VERIFYHOST => $verifySsl ? 2 : 0,
]);

if ($method === 'POST') {
    curl_setopt($ch, CURLOPT_POSTFIELDS, $requestBody);
}

$raw = curl_exec($ch);
if ($raw === false) {
    $message = curl_error($ch) ?: 'Falha de rede ao acessar PASOE.';
    curl_close($ch);
    $payload = ['success' => false, 'error' => $message];
    finishRequestLog($logId, 502, json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '', $message);
    proxyJson(502, $payload);
}

$status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
$headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$contentType = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
curl_close($ch);

$body = substr((string) $raw, $headerSize);
if ($status >= 400 && trim($body) === '') {
    $payload = [
        'success' => false,
        'error' => 'PASOE respondeu erro HTTP ' . $status . ' com corpo vazio.',
        'target' => $target,
    ];
    finishRequestLog($logId, $status, json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '', (string) $payload['error']);
    proxyJson($status, $payload);
}
if ($status >= 200 && $status < 300 && trim($body) === '') {
    $payload = [
        'success' => true,
        'data' => [],
        'warning' => 'PASOE respondeu HTTP ' . $status . ' com corpo vazio.',
        'target' => $target,
    ];
    finishRequestLog($logId, 200, json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '', '');
    proxyJson(200, $payload);
}
finishRequestLog($logId, $status > 0 ? $status : 502, $body, '');
http_response_code($status > 0 ? $status : 502);
header('Cache-Control: no-store');
header('Content-Type: ' . ($contentType !== '' ? $contentType : 'application/json; charset=utf-8'));
echo $body;
exit;

function requestLogDb(): PDO
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
    initializeRequestLogSchema($pdo);
    return $pdo;
}

function initializeRequestLogSchema(PDO $pdo): void
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
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_request_logs_started_at ON request_logs(started_at DESC)');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_request_logs_target ON request_logs(target)');
}

function startRequestLog(string $method, string $target, string $requestBody): string
{
    try {
        $pdo = requestLogDb();
        $id = sha1(implode('|', [$method, $target, microtime(true), random_int(1000, 999999)]));
        $GLOBALS['sursumRequestLogStartedAt'][$id] = microtime(true);
        $now = date(DATE_ATOM);
        $stmt = $pdo->prepare(
            'INSERT INTO request_logs
             (id, started_at, method, target, request_query_json, request_body_json, user_name, remote_addr, created_at)
             VALUES (:id, :started_at, :method, :target, :request_query_json, :request_body_json, :user_name, :remote_addr, :created_at)'
        );
        $stmt->execute([
            ':id' => $id,
            ':started_at' => $now,
            ':method' => $method,
            ':target' => $target,
            ':request_query_json' => json_encode($_GET, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?: '{}',
            ':request_body_json' => $requestBody,
            ':user_name' => currentRequestUser(),
            ':remote_addr' => (string) ($_SERVER['REMOTE_ADDR'] ?? ''),
            ':created_at' => $now,
        ]);
        return $id;
    } catch (Throwable $error) {
        return '';
    }
}

function finishRequestLog(string $id, int $status, string $responseBody, string $errorMessage): void
{
    if ($id === '') {
        return;
    }
    try {
        $pdo = requestLogDb();
        $finishedAt = date(DATE_ATOM);
        $startedAt = $GLOBALS['sursumRequestLogStartedAt'][$id] ?? null;
        $durationMs = is_float($startedAt) ? max(0, (int) round((microtime(true) - $startedAt) * 1000)) : 0;
        $stmt = $pdo->prepare(
            'UPDATE request_logs
             SET finished_at = :finished_at,
                 duration_ms = :duration_ms,
                 response_status = :response_status,
                 response_body_json = :response_body_json,
                 error_message = :error_message
             WHERE id = :id'
        );
        $stmt->execute([
            ':finished_at' => $finishedAt,
            ':duration_ms' => $durationMs,
            ':response_status' => $status,
            ':response_body_json' => $responseBody,
            ':error_message' => $errorMessage,
            ':id' => $id,
        ]);
    } catch (Throwable $error) {
        return;
    }
}

function currentRequestUser(): string
{
    $user = $_SESSION['sursum_user'] ?? $_SESSION['user'] ?? null;
    if (is_array($user)) {
        return (string) ($user['username'] ?? $user['user'] ?? $user['name'] ?? '');
    }
    return is_scalar($user) ? (string) $user : '';
}

function findAllowedPasoeTarget(string $target): ?array
{
    $dbFile = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf' . DIRECTORY_SEPARATOR . 'sursum.sqlite';
    if (!is_file($dbFile)) {
        return null;
    }

    $db = new SQLite3($dbFile, SQLITE3_OPEN_READONLY);
    $db->busyTimeout(30000);
    $envs = sqliteRows($db, 'SELECT id, pasoe_base_url, auth_mode, authorization FROM environments');
    $companies = sqliteRows($db, 'SELECT environment_id, name, code, path_param FROM companies');
    $db->close();

    foreach ($envs as $environment) {
        $base = trim((string) ($environment['pasoe_base_url'] ?? ''));
        if ($base === '') {
            continue;
        }

        $tokens = [''];
        foreach ($companies as $company) {
            if ((string) ($company['environment_id'] ?? '') !== (string) ($environment['id'] ?? '')) {
                continue;
            }
            $token = trim((string) ($company['path_param'] ?? ''));
            if ($token === '') {
                $token = trim((string) ($company['name'] ?? $company['code'] ?? ''));
            }
            if ($token !== '') {
                $tokens[] = rawurlencode($token);
            }
        }

        foreach (array_unique($tokens) as $token) {
            $resolved = str_ireplace('{empresa}', $token, $base);
            if (targetStartsWithBase($target, $resolved)) {
                return $environment;
            }
        }
    }

    return null;
}

function sqliteRows(SQLite3 $db, string $sql): array
{
    $rows = [];
    $result = $db->query($sql);
    if (!$result) {
        return $rows;
    }
    while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
        $rows[] = $row;
    }
    $result->finalize();
    return $rows;
}

function targetStartsWithBase(string $target, string $base): bool
{
    $normalizedTarget = rtrim($target, '/');
    $normalizedBase = rtrim($base, '/');
    return $normalizedTarget === $normalizedBase
        || str_starts_with($normalizedTarget, $normalizedBase . '/')
        || str_starts_with($normalizedTarget, $normalizedBase . '?');
}

function isPrivateHost(string $host): bool
{
    $ip = filter_var($host, FILTER_VALIDATE_IP);
    if ($ip === false) {
        return false;
    }
    return !filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE);
}

function proxyJson(int $status, array $payload): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
