<?php
declare(strict_types=1);

$baseUrl = rtrim((string) getenv('SURSUM_E2E_BASE_URL'), '/') ?: 'http://127.0.0.1:18082';
$username = (string) getenv('SURSUM_E2E_USER');
$password = (string) getenv('SURSUM_E2E_PASSWORD');

if ($username === '' || $password === '') {
    fwrite(STDERR, "Defina SURSUM_E2E_USER e SURSUM_E2E_PASSWORD.\n");
    exit(2);
}

$cookieFile = tempnam(sys_get_temp_dir(), 'sursum-e2e-cookie-');
$backup = null;

try {
    $status = request('GET', $baseUrl . '/auth.php?action=status', null, $cookieFile);
    assertStatus($status, 200, 'status anonimo');
    assertSame(false, $status['json']['authenticated'] ?? null, 'status anonimo deve ser nao autenticado');

    $blocked = request('GET', $baseUrl . '/context-store.php', null, $cookieFile);
    assertStatus($blocked, 401, 'context-store sem login');

    $badLogin = request('POST', $baseUrl . '/auth.php?action=login', [
        'username' => $username,
        'password' => '__senha_invalida__',
    ], $cookieFile);
    assertStatus($badLogin, 401, 'login invalido');

    $login = request('POST', $baseUrl . '/auth.php?action=login', [
        'username' => $username,
        'password' => $password,
    ], $cookieFile);
    assertStatus($login, 200, 'login valido');
    assertSame(true, $login['json']['authenticated'] ?? null, 'login valido deve autenticar');

    $authStatus = request('GET', $baseUrl . '/auth.php?action=status', null, $cookieFile);
    assertStatus($authStatus, 200, 'status autenticado');
    assertSame(true, $authStatus['json']['authenticated'] ?? null, 'status autenticado');

    $context = request('GET', $baseUrl . '/context-store.php', null, $cookieFile);
    assertStatus($context, 200, 'context-store autenticado');
    assertSame(true, $context['json']['success'] ?? null, 'context-store deve retornar sucesso');
    $backup = $context['json']['data'] ?? null;
    if (!is_array($backup)) {
        throw new RuntimeException('Contexto retornado nao e objeto.');
    }

    $updated = $backup;
    $suffix = (string) time();
    $updated['clients'][] = ['id' => 'e2e-cliente-' . $suffix, 'name' => 'E2E Cliente ' . $suffix];
    $updated['environments'][] = [
        'id' => 'e2e-ambiente-' . $suffix,
        'name' => 'E2E Ambiente ' . $suffix,
        'pasoeBaseUrl' => 'http://127.0.0.1:8890/web/SursumDynamicQuery',
        'authMode' => 'none',
        'authorization' => '',
        'companyIdMode' => 'query',
        'extraQueryParams' => '',
    ];
    $updated['links'][] = [
        'id' => 'link-e2e-' . $suffix,
        'clientId' => 'e2e-cliente-' . $suffix,
        'environmentId' => 'e2e-ambiente-' . $suffix,
    ];
    $updated['selected'] = [
        'clientId' => 'e2e-cliente-' . $suffix,
        'environmentId' => 'e2e-ambiente-' . $suffix,
        'companyId' => '',
    ];

    $post = request('POST', $baseUrl . '/context-store.php', $updated, $cookieFile);
    assertStatus($post, 200, 'context-store POST');
    assertSame(true, $post['json']['success'] ?? null, 'context-store POST deve retornar sucesso');

    $readBack = request('GET', $baseUrl . '/context-store.php', null, $cookieFile);
    assertStatus($readBack, 200, 'context-store GET apos POST');
    $clientIds = array_column($readBack['json']['data']['clients'] ?? [], 'id');
    if (!in_array('e2e-cliente-' . $suffix, $clientIds, true)) {
        throw new RuntimeException('Cliente E2E nao foi persistido no SQLite.');
    }

    request('POST', $baseUrl . '/context-store.php', $backup, $cookieFile);

    $logout = request('GET', $baseUrl . '/auth.php?action=logout', null, $cookieFile);
    assertStatus($logout, 200, 'logout');

    $blockedAfterLogout = request('GET', $baseUrl . '/context-store.php', null, $cookieFile);
    assertStatus($blockedAfterLogout, 401, 'context-store apos logout');

    echo "E2E OK\n";
} catch (Throwable $error) {
    if (is_array($backup)) {
        try {
            request('POST', $baseUrl . '/context-store.php', $backup, $cookieFile);
        } catch (Throwable $ignored) {
        }
    }
    fwrite(STDERR, "E2E FAIL: " . $error->getMessage() . "\n");
    exit(1);
} finally {
    if (is_file($cookieFile)) {
        unlink($cookieFile);
    }
}

function request(string $method, string $url, ?array $payload, string $cookieFile): array
{
    $ch = curl_init($url);
    $headers = ['Accept: application/json'];
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HEADER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_COOKIEJAR => $cookieFile,
        CURLOPT_COOKIEFILE => $cookieFile,
    ]);
    if ($payload !== null) {
        $headers[] = 'Content-Type: application/json';
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    $raw = curl_exec($ch);
    if ($raw === false) {
        $message = curl_error($ch);
        curl_close($ch);
        throw new RuntimeException('Erro HTTP: ' . $message);
    }
    $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    $headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    curl_close($ch);
    $body = substr((string) $raw, $headerSize);
    $json = json_decode($body, true);
    return ['status' => $status, 'body' => $body, 'json' => is_array($json) ? $json : null];
}

function assertStatus(array $response, int $expected, string $label): void
{
    if ($response['status'] !== $expected) {
        throw new RuntimeException($label . ': HTTP esperado ' . $expected . ', recebido ' . $response['status'] . '. Body: ' . $response['body']);
    }
}

function assertSame($expected, $actual, string $label): void
{
    if ($expected !== $actual) {
        throw new RuntimeException($label . ': valor inesperado.');
    }
}
