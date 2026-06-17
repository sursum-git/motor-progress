<?php
declare(strict_types=1);

session_name('SURSUMWEB');
session_start();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

if (basename((string) ($_SERVER['SCRIPT_NAME'] ?? '')) === 'auth.php') {
try {
    $action = strtolower((string) ($_GET['action'] ?? 'status'));
    if ($action === 'status') {
        authJsonResponse([
            'success' => true,
            'authenticated' => isAuthenticated(),
            'user' => $_SESSION['sursum_user'] ?? null,
        ]);
    }

    if ($action === 'logout') {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], (bool) $params['secure'], (bool) $params['httponly']);
        }
        session_destroy();
        authJsonResponse(['success' => true]);
    }

    if ($action === 'login') {
        if (strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
            http_response_code(405);
            authJsonResponse(['success' => false, 'error' => 'Metodo nao suportado.']);
        }

        $payload = json_decode((string) file_get_contents('php://input'), true);
        if (!is_array($payload)) {
            throw new InvalidArgumentException('JSON invalido.');
        }

        $username = trim((string) ($payload['username'] ?? ''));
        $password = (string) ($payload['password'] ?? '');
        if ($username === '' || $password === '') {
            throw new InvalidArgumentException('Informe usuario e senha.');
        }

        $config = loadAuthConfig();
        $user = authenticate($username, $password, $config);
        session_regenerate_id(true);
        $_SESSION['sursum_user'] = $user;
        $_SESSION['sursum_auth_at'] = time();
        authJsonResponse(['success' => true, 'authenticated' => true, 'user' => $user]);
    }

    http_response_code(404);
    authJsonResponse(['success' => false, 'error' => 'Acao nao encontrada.']);
} catch (Throwable $error) {
    http_response_code(401);
    authJsonResponse(['success' => false, 'authenticated' => false, 'error' => $error->getMessage()]);
}

}

function isAuthenticated(): bool
{
    $user = $_SESSION['sursum_user'] ?? null;
    if (!is_array($user) || empty($user['username'])) {
        return false;
    }
    $config = loadAuthConfig();
    $hours = max(1, (int) ($config['sessionHours'] ?? 8));
    $authAt = (int) ($_SESSION['sursum_auth_at'] ?? 0);
    return $authAt > 0 && (time() - $authAt) <= ($hours * 3600);
}

function requireSursumAuth(): void
{
    if (!isAuthenticated()) {
        http_response_code(401);
        authJsonResponse(['success' => false, 'authenticated' => false, 'error' => 'Login obrigatorio.']);
    }
}

function loadAuthConfig(): array
{
    $file = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf' . DIRECTORY_SEPARATOR . 'auth.json';
    $defaults = [
        'mode' => 'ldap',
        'sessionHours' => 8,
        'ldap' => [
            'host' => '',
            'port' => 389,
            'useTls' => false,
            'baseDn' => '',
            'bindDn' => '',
            'bindPassword' => '',
            'userAttribute' => 'sAMAccountName',
            'domainPrefix' => '',
            'domainSuffix' => '',
            'requiredGroupDn' => '',
        ],
        'localUsers' => [],
    ];
    if (!is_file($file)) {
        return $defaults;
    }
    $loaded = json_decode((string) file_get_contents($file), true);
    if (!is_array($loaded)) {
        return $defaults;
    }
    return array_replace_recursive($defaults, $loaded);
}

function authenticate(string $username, string $password, array $config): array
{
    $mode = strtolower((string) ($config['mode'] ?? 'ldap'));
    if ($mode === 'local') {
        return authenticateLocal($username, $password, $config);
    }
    if ($mode === 'ldap-local') {
        try {
            return authenticateLdap($username, $password, $config);
        } catch (Throwable $error) {
            return authenticateLocal($username, $password, $config);
        }
    }
    return authenticateLdap($username, $password, $config);
}

function authenticateLocal(string $username, string $password, array $config): array
{
    foreach (($config['localUsers'] ?? []) as $user) {
        if (!is_array($user) || strcasecmp((string) ($user['username'] ?? ''), $username) !== 0) {
            continue;
        }
        $hash = (string) ($user['passwordHash'] ?? '');
        if ($hash !== '' && password_verify($password, $hash)) {
            return [
                'username' => (string) $user['username'],
                'displayName' => (string) ($user['displayName'] ?? $user['username']),
                'source' => 'local',
            ];
        }
    }
    throw new RuntimeException('Usuario ou senha invalidos.');
}

function authenticateLdap(string $username, string $password, array $config): array
{
    if (!function_exists('ldap_connect')) {
        throw new RuntimeException('Extensao LDAP do PHP nao esta habilitada.');
    }
    $ldap = $config['ldap'] ?? [];
    $host = trim((string) ($ldap['host'] ?? ''));
    $baseDn = trim((string) ($ldap['baseDn'] ?? ''));
    if ($host === '' || $baseDn === '') {
        throw new RuntimeException('LDAP nao configurado.');
    }

    $conn = ldap_connect($host, (int) ($ldap['port'] ?? 389));
    if (!$conn) {
        throw new RuntimeException('Nao foi possivel conectar no LDAP.');
    }
    ldap_set_option($conn, LDAP_OPT_PROTOCOL_VERSION, 3);
    ldap_set_option($conn, LDAP_OPT_REFERRALS, 0);
    if (!empty($ldap['useTls']) && !ldap_start_tls($conn)) {
        throw new RuntimeException('Nao foi possivel iniciar TLS no LDAP.');
    }

    $requiredGroup = trim((string) ($ldap['requiredGroupDn'] ?? ''));
    $bindDn = trim((string) ($ldap['bindDn'] ?? ''));
    $bindPassword = (string) ($ldap['bindPassword'] ?? '');
    if ($bindDn !== '') {
        if (!@ldap_bind($conn, $bindDn, $bindPassword)) {
            throw new RuntimeException('Bind tecnico LDAP falhou.');
        }
        $userDn = findUserDn($conn, $baseDn, $username, $ldap);
        if (!@ldap_bind($conn, $userDn, $password)) {
            throw new RuntimeException('Usuario ou senha invalidos.');
        }
    } else {
        $login = ldapLoginName($username, $ldap);
        if (!@ldap_bind($conn, $login, $password)) {
            throw new RuntimeException('Usuario ou senha invalidos.');
        }
        $userDn = $requiredGroup !== '' ? findUserDn($conn, $baseDn, $username, $ldap) : $login;
    }

    if ($requiredGroup !== '' && !userIsMemberOf($conn, $userDn, $requiredGroup)) {
        throw new RuntimeException('Usuario sem permissao para acessar o Sursum.');
    }

    return [
        'username' => $username,
        'displayName' => $username,
        'dn' => $userDn,
        'source' => 'ldap',
    ];
}

function findUserDn($conn, string $baseDn, string $username, array $ldap): string
{
    $attribute = preg_replace('/[^a-zA-Z0-9_.-]/', '', (string) ($ldap['userAttribute'] ?? 'sAMAccountName')) ?: 'sAMAccountName';
    $filter = sprintf('(&(%s=%s)(objectClass=person))', $attribute, ldap_escape($username, '', LDAP_ESCAPE_FILTER));
    $search = @ldap_search($conn, $baseDn, $filter, ['dn']);
    if (!$search) {
        throw new RuntimeException('Usuario nao encontrado no LDAP.');
    }
    $entries = ldap_get_entries($conn, $search);
    if (($entries['count'] ?? 0) < 1) {
        throw new RuntimeException('Usuario nao encontrado no LDAP.');
    }
    return (string) $entries[0]['dn'];
}

function userIsMemberOf($conn, string $userDn, string $groupDn): bool
{
    $filter = sprintf('(&(distinguishedName=%s)(memberOf=%s))', ldap_escape($userDn, '', LDAP_ESCAPE_FILTER), ldap_escape($groupDn, '', LDAP_ESCAPE_FILTER));
    $parts = explode(',', $userDn, 2);
    $base = $parts[1] ?? $userDn;
    $search = @ldap_search($conn, $base, $filter, ['dn']);
    if (!$search) {
        return false;
    }
    $entries = ldap_get_entries($conn, $search);
    return ($entries['count'] ?? 0) > 0;
}
function ldapLoginName(string $username, array $ldap): string
{
    $hasDomain = strpos($username, "@") !== false || strpos($username, "\\") !== false;
    if (!$hasDomain) {
        $prefix = (string) ($ldap["domainPrefix"] ?? "");
        if ($prefix !== "") {
            return $prefix . $username;
        }
    }
    $suffix = trim((string) ($ldap["domainSuffix"] ?? ""));
    if ($suffix !== "" && !$hasDomain) {
        return $username . $suffix;
    }
    return $username;
}

function authJsonResponse(array $payload): void
{
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    exit;
}
