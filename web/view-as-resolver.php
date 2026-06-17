<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $payload = json_decode((string) file_get_contents('php://input'), true);
    if (!is_array($payload)) {
        throw new InvalidArgumentException('JSON invalido.');
    }

    $rows = is_array($payload['rows'] ?? null) ? $payload['rows'] : [];
    $includes = [];
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $include = extractViewAsInclude((string) ($row['viewAs'] ?? $row['view_as'] ?? ''));
        if ($include !== '') {
            $includes[$include] = true;
        }
    }

    $resolved = $includes ? resolveIncludesViaCompiler(array_keys($includes), (string) ($payload['environmentId'] ?? $payload['environment_id'] ?? '')) : [];
    $data = [];
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $viewAs = (string) ($row['viewAs'] ?? $row['view_as'] ?? '');
        $include = extractViewAsInclude($viewAs);
        $list = $include !== '' ? (string) ($resolved[$include]['listExpression'] ?? '') : normalizeDirectListExpression($viewAs);
        $row['listExpression'] = $list;
        $row['options'] = parseOptions($list, $include !== '');
        $row['source'] = (string) ($row['source'] ?? 'COMPILER');
        if ($include !== '') {
            $row['include'] = $include;
            $row['resolverError'] = (string) ($resolved[$include]['error'] ?? '');
        }
        $data[] = $row;
    }

    jsonOut(['success' => true, 'data' => $data, 'resolvedIncludes' => $resolved]);
} catch (Throwable $error) {
    jsonOut(['success' => false, 'error' => $error->getMessage()], 500);
}

function resolveIncludesViaCompiler(array $includes, string $environmentId): array
{
    $cfg = compilerConfig($environmentId);
    $job = 'viewas_' . bin2hex(random_bytes(8));
    $localIn = sys_get_temp_dir() . DIRECTORY_SEPARATOR . $job . '.in';
    $localOut = sys_get_temp_dir() . DIRECTORY_SEPARATOR . $job . '.out';
    $localPs = sys_get_temp_dir() . DIRECTORY_SEPARATOR . $job . '.ps1';
    $remoteIn = $cfg['remoteTemp'] . '/' . $job . '.in';
    $remoteOut = $cfg['remoteTemp'] . '/' . $job . '.out';
    $remotePs = $cfg['remoteTemp'] . '/' . $job . '.ps1';
    file_put_contents($localIn, implode("\n", $includes) . "\n");
    file_put_contents($localPs, buildResolverScript($cfg, $remoteIn, $remoteOut));

    try {
        runCommand([
            'sshpass', '-p', $cfg['password'], 'scp',
            $localIn,
            $cfg['user'] . '@' . $cfg['host'] . ':' . $remoteIn,
        ]);
        runCommand([
            'sshpass', '-p', $cfg['password'], 'scp',
            $localPs,
            $cfg['user'] . '@' . $cfg['host'] . ':' . $remotePs,
        ]);

        $compilerOutput = runCommand([
            'sshpass', '-p', $cfg['password'], 'ssh',
            $cfg['user'] . '@' . $cfg['host'],
            'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $remotePs,
        ]);

        try {
            runCommand([
                'sshpass', '-p', $cfg['password'], 'scp',
                $cfg['user'] . '@' . $cfg['host'] . ':' . $remoteOut,
                $localOut,
            ]);
        } catch (Throwable $error) {
            $detail = trim(convertText($compilerOutput));
            if ($detail === '') {
                $detail = $error->getMessage();
            }
            throw new RuntimeException('Resolvedor de includes nao gerou saida. Detalhe: ' . $detail);
        }

        return parseResolverOutput((string) file_get_contents($localOut));
    } finally {
        @unlink($localIn);
        @unlink($localOut);
        @unlink($localPs);
        $cleanup = sprintf(
            'Remove-Item -Force %s,%s,%s -ErrorAction SilentlyContinue',
            psQuote($remoteIn),
            psQuote($remoteOut),
            psQuote($remotePs)
        );
        @runCommand([
            'sshpass', '-p', $cfg['password'], 'ssh',
            $cfg['user'] . '@' . $cfg['host'],
            'powershell', '-NoProfile', '-Command', $cleanup,
        ], false);
    }
}

function buildResolverScript(array $cfg, string $remoteIn, string $remoteOut): string
{
    return implode("\r\n", [
        'Set-Location ' . psQuote($cfg['remoteWorkspace']),
        '& ' . psQuote($cfg['compiler'])
            . ' -b'
            . ($cfg['arquivoPf'] !== '' ? ' -pf ' . psQuote($cfg['arquivoPf']) : ' -db ' . psQuote($cfg['database']))
            . ' -1 -ld DICTDB'
            . ' -param ' . psQuote($remoteIn . '|' . $remoteOut . '|' . $cfg['arquivoAlias'])
            . ' -p ' . psQuote($cfg['resolverProgram']),
        '',
    ]);
}

function compilerConfig(string $environmentId = ''): array
{
    $cfg = [
        'host' => '192.168.0.42',
        'user' => 'tadeu.parreiras',
        'password' => '0715943',
        'remoteWorkspace' => 'C:\\opencode\\motor-progress',
        'remoteTemp' => 'C:/opencode/motor-progress/temp',
        'compiler' => 'C:\\Progress_12\\OE\\bin\\_progres.exe',
        'database' => 'C:\\opencode\\motor-progress\\db\\sports2000',
        'resolverProgram' => 'C:\\opencode\\motor-progress\\sursum-api\\sursum\\RunViewAsIncludeResolver.p',
        'arquivoPf' => '',
        'arquivoAlias' => '',
    ];
    if ($environmentId === '') {
        return $cfg;
    }

    $dbFile = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf' . DIRECTORY_SEPARATOR . 'sursum.sqlite';
    if (!is_file($dbFile)) {
        return $cfg;
    }

    $pdo = new PDO('sqlite:' . $dbFile);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $pdo->prepare('SELECT servidor, usuario, senha, arquivo_pf, arquivo_alias FROM environments WHERE id = :id');
    $stmt->execute([':id' => $environmentId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        return $cfg;
    }

    $cfg['host'] = textOrDefault($row['servidor'] ?? '', $cfg['host']);
    $cfg['user'] = textOrDefault($row['usuario'] ?? '', $cfg['user']);
    $cfg['password'] = textOrDefault($row['senha'] ?? '', $cfg['password']);
    $cfg['arquivoPf'] = trim((string) ($row['arquivo_pf'] ?? ''));
    $cfg['arquivoAlias'] = trim((string) ($row['arquivo_alias'] ?? ''));
    return $cfg;
}

function textOrDefault($value, string $default): string
{
    $text = trim((string) ($value ?? ''));
    return $text === '' ? $default : $text;
}

function parseResolverOutput(string $output): array
{
    $resolved = [];
    foreach (preg_split('/\R/', $output) ?: [] as $line) {
        if ($line === '') {
            continue;
        }
        $parts = explode("\x01", $line, 3);
        $include = trim((string) ($parts[0] ?? ''));
        if ($include === '') {
            continue;
        }
        $error = convertText((string) ($parts[1] ?? ''));
        $list = convertText((string) ($parts[2] ?? ''));
        $resolved[$include] = [
            'listExpression' => $list,
            'error' => $error,
        ];
    }
    return $resolved;
}

function extractViewAsInclude(string $viewAs): string
{
    if (!preg_match('/\{\s*([^}\s]+\.i)\s+[^}]*\}/i', $viewAs, $match)) {
        return '';
    }
    return str_replace('\\', '/', strtolower(trim($match[1]))) . ' 3';
}

function normalizeDirectListExpression(string $viewAs): string
{
    $text = trim($viewAs);
    if ($text === '') {
        return '';
    }
    $lower = strtolower($text);
    foreach (['radio-buttons', 'list-item-pairs', 'list-items', 'list-item'] as $needle) {
        $pos = strpos($lower, $needle);
        if ($pos !== false) {
            $text = trim(substr($text, $pos + strlen($needle)));
            break;
        }
    }
    if (strpos(strtolower($text), 'toggle-box') !== false || strpos(strtolower($text), 'editor') !== false) {
        return '';
    }
    return preg_match('/^\{.*\}$/', $text) ? '' : $text;
}

function parseOptions(string $list, bool $singleItems = false): array
{
    $tokens = array_values(array_filter(array_map('cleanToken', str_getcsv($list)), static function (string $value): bool {
        return $value !== '';
    }));
    $count = count($tokens);
    if ($count === 0) {
        return [];
    }
    if ($singleItems || $count % 2 !== 0) {
        return array_map(static function (string $value): array {
            return ['label' => $value, 'value' => $value];
        }, $tokens);
    }
    $options = [];
    for ($i = 0; $i < $count; $i += 2) {
        $options[] = ['label' => $tokens[$i], 'value' => $tokens[$i + 1]];
    }
    return $options;
}

function cleanToken(string $value): string
{
    return trim(str_replace(['"', "'", '/'], '', $value));
}

function convertText(string $value): string
{
    if ($value === '') {
        return '';
    }
    $converted = @iconv('Windows-1252', 'UTF-8//IGNORE', $value);
    return $converted === false ? $value : $converted;
}

function runCommand(array $command, bool $throw = true): string
{
    $cmd = implode(' ', array_map('escapeshellarg', $command));
    $descriptor = [
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];
    $process = proc_open($cmd, $descriptor, $pipes);
    if (!is_resource($process)) {
        throw new RuntimeException('Nao foi possivel iniciar comando SSH.');
    }
    $stdout = stream_get_contents($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $code = proc_close($process);
    if ($throw && $code !== 0) {
        throw new RuntimeException(trim($stderr . "\n" . $stdout) ?: 'Falha ao executar comando SSH.');
    }
    return $stdout;
}

function psQuote(string $value): string
{
    return "'" . str_replace("'", "''", $value) . "'";
}

function jsonOut(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
