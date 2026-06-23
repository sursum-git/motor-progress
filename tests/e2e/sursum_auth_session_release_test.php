<?php
declare(strict_types=1);

$_SERVER['SCRIPT_NAME'] = __FILE__;

$sessionDir = sys_get_temp_dir() . '/sursum-session-release-test';
if (!is_dir($sessionDir) && !mkdir($sessionDir, 0775, true) && !is_dir($sessionDir)) {
    fail('Nao foi possivel criar diretorio temporario de sessao.');
}
session_save_path($sessionDir);

require __DIR__ . '/../../web/auth.php';

if (session_status() !== PHP_SESSION_ACTIVE) {
    fail('Sessao deveria iniciar ativa ao carregar auth.php.');
}

$_SESSION['sursum_user'] = [
    'username' => 'session-release-test',
    'displayName' => 'Session Release Test',
    'source' => 'test',
];
$_SESSION['sursum_auth_at'] = time();

requireSursumAuth();

if (session_status() !== PHP_SESSION_NONE) {
    fail('requireSursumAuth deve liberar a sessao para permitir requests paralelos.');
}

echo "Auth session release OK\n";

function fail(string $message): never
{
    fwrite(STDERR, "FAIL: " . $message . "\n");
    exit(1);
}
