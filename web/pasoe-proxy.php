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
    proxyJson(500, ['success' => false, 'error' => 'Nao foi possivel iniciar cURL.']);
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
    curl_setopt($ch, CURLOPT_POSTFIELDS, file_get_contents('php://input') ?: '');
}

$raw = curl_exec($ch);
if ($raw === false) {
    $message = curl_error($ch) ?: 'Falha de rede ao acessar PASOE.';
    curl_close($ch);
    proxyJson(502, ['success' => false, 'error' => $message]);
}

$status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
$headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$contentType = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
curl_close($ch);

$body = substr((string) $raw, $headerSize);
if ($status >= 400 && trim($body) === '') {
    proxyJson($status, [
        'success' => false,
        'error' => 'PASOE respondeu erro HTTP ' . $status . ' com corpo vazio.',
        'target' => $target,
    ]);
}
if ($status >= 200 && $status < 300 && trim($body) === '') {
    proxyJson(200, [
        'success' => true,
        'data' => [],
        'warning' => 'PASOE respondeu HTTP ' . $status . ' com corpo vazio.',
        'target' => $target,
    ]);
}
http_response_code($status > 0 ? $status : 502);
header('Cache-Control: no-store');
header('Content-Type: ' . ($contentType !== '' ? $contentType : 'application/json; charset=utf-8'));
echo $body;
exit;

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
