<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

if (strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET')) !== 'GET') {
    jsonOut(405, ['success' => false, 'error' => 'Metodo nao suportado.']);
}

try {
    $environmentId = text($_GET['environmentId'] ?? $_GET['environment_id'] ?? '');
    $companyId = text($_GET['companyId'] ?? $_GET['company_id'] ?? '');
    $path = text($_GET['path'] ?? '');
    if ($environmentId === '' || $companyId === '' || $path === '') {
        throw new InvalidArgumentException('Ambiente, empresa e path sao obrigatorios.');
    }
    if (!str_starts_with($path, '/metadata/')) {
        throw new InvalidArgumentException('Path de metadados invalido.');
    }

    [$environment, $company] = loadEnvironmentCompany($environmentId, $companyId);
    $target = buildPasoeUrl($environment, $company, $path, $_GET);
    proxyPasoe($target, $environment);
} catch (Throwable $error) {
    jsonOut(500, ['success' => false, 'error' => $error->getMessage()]);
}

function loadEnvironmentCompany(string $environmentId, string $companyId): array
{
    $dbFile = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf' . DIRECTORY_SEPARATOR . 'sursum.sqlite';
    if (!is_file($dbFile)) {
        throw new RuntimeException('Contexto SQLite nao encontrado.');
    }
    $pdo = new PDO('sqlite:' . $dbFile);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_TIMEOUT, 30);
    $pdo->exec('PRAGMA busy_timeout = 30000');

    $envStmt = $pdo->prepare('SELECT * FROM environments WHERE id = :id');
    $envStmt->execute([':id' => $environmentId]);
    $environment = $envStmt->fetch(PDO::FETCH_ASSOC);
    if (!$environment) {
        throw new RuntimeException('Ambiente nao encontrado no SQLite.');
    }

    $companyStmt = $pdo->prepare('SELECT * FROM companies WHERE id = :id AND environment_id = :environment_id');
    $companyStmt->execute([':id' => $companyId, ':environment_id' => $environmentId]);
    $company = $companyStmt->fetch(PDO::FETCH_ASSOC);
    if (!$company) {
        throw new RuntimeException('Empresa nao encontrada no SQLite.');
    }

    return [$environment, $company];
}

function buildPasoeUrl(array $environment, array $company, string $path, array $query): string
{
    $base = rtrim((string) ($environment['pasoe_base_url'] ?? ''), '/');
    if ($base === '') {
        throw new RuntimeException('Endpoint PASOE do ambiente esta vazio.');
    }
    $token = rawurlencode(text($company['path_param'] ?? '') ?: text($company['name'] ?? $company['code'] ?? ''));
    $base = str_ireplace('{empresa}', $token, $base);

    $parts = parse_url($path);
    $route = '/' . ltrim((string) ($parts['path'] ?? $path), '/');
    parse_str((string) ($parts['query'] ?? ''), $params);
    foreach (['database', 'banco', 'table', 'tabela', 'include', 'q', 'filter'] as $key) {
        if (isset($query[$key]) && text($query[$key]) !== '' && !isset($params[$key])) {
            $params[$key] = text($query[$key]);
        }
    }
    if (($environment['company_id_mode'] ?? '') === 'query' && text($company['code'] ?? '') !== '' && !isset($params['companyId'])) {
        $params['companyId'] = text($company['code']);
    }

    $url = $base . $route;
    if ($params) {
        $url .= '?' . http_build_query($params);
    }
    return $url;
}

function proxyPasoe(string $target, array $environment): never
{
    $parts = parse_url($target);
    if (!is_array($parts) || !in_array(strtolower((string) ($parts['scheme'] ?? '')), ['http', 'https'], true) || empty($parts['host'])) {
        throw new RuntimeException('URL PASOE resolvida invalida.');
    }

    $headers = ['Accept: application/json'];
    if (($environment['auth_mode'] ?? '') === 'header' && text($environment['authorization'] ?? '') !== '') {
        $headers[] = 'Authorization: ' . text($environment['authorization']);
    }

    $ch = curl_init($target);
    if ($ch === false) {
        throw new RuntimeException('Nao foi possivel iniciar cURL.');
    }
    $verifySsl = !isPrivateHost((string) $parts['host']);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HEADER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 180,
        CURLOPT_SSL_VERIFYPEER => $verifySsl,
        CURLOPT_SSL_VERIFYHOST => $verifySsl ? 2 : 0,
    ]);

    $raw = curl_exec($ch);
    if ($raw === false) {
        $message = curl_error($ch) ?: 'Falha de rede ao acessar PASOE.';
        curl_close($ch);
        jsonOut(502, ['success' => false, 'error' => $message, 'target' => $target]);
    }
    $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    $headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $contentType = (string) curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    curl_close($ch);

    $body = substr((string) $raw, $headerSize);
    if ($status >= 400 && trim($body) === '') {
        jsonOut($status, [
            'success' => false,
            'error' => 'PASOE respondeu erro HTTP ' . $status . ' com corpo vazio.',
            'target' => $target,
        ]);
    }
    if ($status >= 200 && $status < 300 && trim($body) === '') {
        jsonOut(200, [
            'success' => true,
            'data' => [],
            'target' => $target,
        ]);
    }

    http_response_code($status > 0 ? $status : 502);
    header('Cache-Control: no-store');
    header('Content-Type: ' . ($contentType !== '' ? $contentType : 'application/json; charset=utf-8'));
    echo $body;
    exit;
}

function isPrivateHost(string $host): bool
{
    $ip = filter_var($host, FILTER_VALIDATE_IP);
    if ($ip === false) {
        return false;
    }
    return !filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE);
}

function text($value): string
{
    return trim((string) ($value ?? ''));
}

function jsonOut(int $status, array $payload): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
