<?php
declare(strict_types=1);

function sursumQueryProxySecretFile(string $name): string
{
    if (!in_array($name, ['pasoe.token', 'pasoe.pubkey-pin'], true)) {
        throw new RuntimeException('Arquivo privado invalido.');
    }
    // ISPConfig permits this private folder in open_basedir; it is outside DocumentRoot.
    return dirname(__DIR__, 2) . '/private/sursum-query-progress/' . $name;
}

function sursumIsDynamicQueryTarget(string $target): bool
{
    $path = (string) (parse_url($target, PHP_URL_PATH) ?? '');
    return preg_match('~(?:^|/)SursumDynamicQuery(?:/|$)~D', $path) === 1;
}

// This policy is activated only for sursum-api/MED; other PASOEs keep their existing behavior.
function sursumIsSecuredQueryTarget(string $target): bool
{
    $parts = parse_url($target);
    return is_array($parts)
        && strtolower((string) ($parts['host'] ?? '')) === '192.168.0.111'
        && (int) ($parts['port'] ?? 0) === 9911
        && preg_match('~\A/med/web/SursumDynamicQuery(?:/|$)~D', (string) ($parts['path'] ?? '')) === 1;
}

function sursumReadPrivateValue(string $file, string $documentRoot): string
{
    $resolved = realpath($file);
    $public = realpath($documentRoot);
    if ($resolved === false || $public === false || !is_file($resolved) || !is_readable($resolved)) {
        throw new RuntimeException('Credencial do proxy indisponivel.');
    }
    $privatePath = str_replace('\\', '/', $resolved);
    $publicPath = rtrim(str_replace('\\', '/', $public), '/') . '/';
    if (PHP_OS_FAMILY === 'Windows') {
        $privatePath = strtolower($privatePath);
        $publicPath = strtolower($publicPath);
    }
    if (str_starts_with($privatePath, $publicPath) || filesize($resolved) > 128) {
        throw new RuntimeException('Credencial do proxy indisponivel.');
    }
    if (PHP_OS_FAMILY !== 'Windows' && (fileperms($resolved) & 0007) !== 0) {
        throw new RuntimeException('Credencial do proxy indisponivel.');
    }
    $token = trim((string) file_get_contents($resolved));
    return $token;
}

function sursumQueryProxyAuthorization(string $target): ?string
{
    if (!sursumIsSecuredQueryTarget($target)) {
        return null;
    }
    if (strtolower((string) parse_url($target, PHP_URL_SCHEME)) !== 'https') {
        throw new RuntimeException('Credencial do proxy exige HTTPS.');
    }
    $file = trim((string) getenv('SURSUM_QUERY_PROXY_TOKEN_FILE'));
    if ($file === '') {
        $file = sursumQueryProxySecretFile('pasoe.token');
    }
    $publicRoot = (string) ($_SERVER['DOCUMENT_ROOT'] ?? dirname(__DIR__));
    return 'Bearer ' . loadSursumQueryProxyToken($file, $publicRoot);
}

function loadSursumQueryProxyToken(string $file, string $documentRoot): string
{
    $token = sursumReadPrivateValue($file, $documentRoot);
    if (preg_match('/\A[a-f0-9]{64}\z/D', $token) !== 1) {
        throw new RuntimeException('Credencial do proxy indisponivel.');
    }
    return $token;
}

function sursumQueryProxyTlsOptions(string $target): array
{
    if (!sursumIsSecuredQueryTarget($target)) {
        return [];
    }
    if (strtolower((string) parse_url($target, PHP_URL_SCHEME)) !== 'https' || !defined('CURLOPT_PINNEDPUBLICKEY')) {
        throw new RuntimeException('Confianca TLS do proxy indisponivel.');
    }
    $file = trim((string) getenv('SURSUM_QUERY_PROXY_PIN_FILE'));
    if ($file === '') {
        $file = sursumQueryProxySecretFile('pasoe.pubkey-pin');
    }
    $pin = sursumReadPrivateValue($file, (string) ($_SERVER['DOCUMENT_ROOT'] ?? dirname(__DIR__)));
    if (preg_match('~\Asha256//[A-Za-z0-9+/]{43}=\z~D', $pin) !== 1) {
        throw new RuntimeException('Confianca TLS do proxy indisponivel.');
    }
    // The current PASOE test certificate has no hostname SAN. Trust its exact
    // public key, obtained through authenticated SSH, instead of accepting any
    // self-signed certificate on a private IP. A key mismatch aborts TLS before HTTP.
    return [CURLOPT_PINNEDPUBLICKEY => $pin, CURLOPT_SSL_VERIFYPEER => false, CURLOPT_SSL_VERIFYHOST => 0];
}
