<?php
declare(strict_types=1);

function consumerAdminSecureRequest(array $server): bool
{
    if (in_array(strtolower((string) ($server['HTTPS'] ?? '')), ['on', '1'], true)) return true;
    // The inspected iol SSL vhost overwrites this header and proxies to 127.0.0.1:80.
    // Accept it only from the local proxy, never directly from a remote client.
    return in_array((string) ($server['REMOTE_ADDR'] ?? ''), ['127.0.0.1', '::1'], true)
        && ($server['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https';
}

function consumerAdminAllowed(?array $user): bool
{
    return ($user['source'] ?? '') === 'ldap'
        && strcasecmp((string) ($user['username'] ?? ''), 'tadeu.parreiras') === 0;
}

function consumerAdminCheckCsrf(string $expected, string $given): void
{
    if (strlen($expected) !== 64 || strlen($given) !== 64 || !hash_equals($expected, $given)) {
        throw new RuntimeException('Sessao de administracao invalida. Atualize a pagina.');
    }
}

function consumerAdminIdentifier(mixed $value): bool
{
    return is_string($value) && preg_match('/\A[A-Za-z0-9_.-]{1,128}\z/D', $value) === 1 && !in_array($value, ['.', '..'], true);
}

function consumerAdminPrepare(array $request): array
{
    $action = $request['action'] ?? '';
    $fields = match ($action) {
        'create', 'create-client', 'update' => ['action', 'id', 'queries', 'days', 'revision'],
        'rotate', 'credentials' => ['action', 'id', 'days', 'revision'],
        'revoke' => ['action', 'id', 'revision'],
        default => throw new InvalidArgumentException('Acao invalida.'),
    };
    if (array_diff(array_keys($request), $fields) || array_diff($fields, array_keys($request))) {
        throw new InvalidArgumentException('Campos invalidos.');
    }
    if (!consumerAdminIdentifier($request['id']) || $request['id'] === 'web-query-admin') {
        throw new InvalidArgumentException('Consumidor invalido ou protegido.');
    }
    if (!is_string($request['revision']) || preg_match('/\A[a-f0-9]{64}\z/D', $request['revision']) !== 1) {
        throw new InvalidArgumentException('Atualize a lista antes de alterar.');
    }
    if ($action !== 'revoke' && (!is_int($request['days']) || $request['days'] < 1 || $request['days'] > 365)) {
        throw new InvalidArgumentException('Validade deve ser de 1 a 365 dias.');
    }
    if (in_array($action, ['create', 'create-client', 'update'], true)) {
        $queries = $request['queries'];
        if (!is_array($queries) || !array_is_list($queries) || count($queries) < 1 || count($queries) > 1000
            || count(array_filter($queries, 'consumerAdminIdentifier')) !== count($queries)
            || count(array_unique($queries, SORT_STRING)) !== count($queries)) {
            throw new InvalidArgumentException('Escolha consultas validas e distintas.');
        }
    }
    $token = null;
    if (in_array($action, ['create', 'rotate', 'create-client', 'credentials'], true)) {
        $token = bin2hex(random_bytes(32));
        $request[in_array($action, ['create-client','credentials'],true) ? 'clientSecretSha256' : 'tokenSha256'] = hash('sha256', $token);
    }
    return ['payload' => $request, 'token' => $token];
}

// The generic proxy must never relay or log this administration route, even by aliases.
function consumerAdminProxyBlocked(string $target): bool
{
    $parts = parse_url($target);
    if (!is_array($parts) || strtolower((string) ($parts['host'] ?? '')) !== '192.168.0.111'
        || (int) ($parts['port'] ?? 0) !== 9911) return false;
    $path = rawurldecode((string) ($parts['path'] ?? ''));
    return preg_match('~(?:^|/)(?:consumers|token)(?:/|$|[;.])~i', $path) === 1;
}

function consumerAdminRequest(string $method, ?array $payload): array
{
    require_once __DIR__ . '/pasoe-consumer-auth.php';
    $target = 'https://192.168.0.111:9911/med/web/SursumDynamicQuery/consumers';
    $authorization = sursumQueryProxyAuthorization($target);
    if ($authorization === null) throw new RuntimeException('Credencial administrativa indisponivel.');
    $options = sursumQueryProxyTlsOptions($target);
    $ch = curl_init($target);
    if ($ch === false) throw new RuntimeException('Conexao indisponivel.');
    try {
        if (!curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST => $method, CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => 10, CURLOPT_TIMEOUT => 30,
            CURLOPT_HTTPHEADER => ['Accept: application/json', 'Content-Type: application/json', 'X-Sursum-Query-Token: ' . substr($authorization, 7)],
            CURLOPT_FOLLOWLOCATION => false,
        ]) || !curl_setopt_array($ch, $options)) throw new RuntimeException('Confianca TLS indisponivel.');
        if ($payload !== null) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload, JSON_THROW_ON_ERROR));
        $raw = curl_exec($ch);
        if ($raw === false) throw new RuntimeException('Nao foi possivel acessar a administracao no PASOE.');
        $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        $data = json_decode($raw, true, 32, JSON_THROW_ON_ERROR);
        if (!is_array($data)) throw new RuntimeException('Resposta administrativa invalida.');
        return ['status' => $status, 'data' => $data];
    } finally {
        curl_close($ch);
        $authorization = '';
    }
}
