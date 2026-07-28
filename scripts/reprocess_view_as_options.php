<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, "Uso apenas via CLI.\n");
    exit(2);
}

$options = cliOptions($argv);
$root = dirname(__DIR__);
$dbPath = (string) ($options['db'] ?? ($root . '/web/sursum-conf/sursum.sqlite'));
$companyCode = (string) ($options['company-code'] ?? '5');
$environmentId = (string) ($options['environment-id'] ?? '');
$batchSize = max(1, (int) ($options['batch-size'] ?? 50));
$onlyMissing = array_key_exists('only-missing', $options);
$limit = max(0, (int) ($options['limit'] ?? 0));
$directOnly = array_key_exists('direct-only', $options);
$includeOnly = array_key_exists('include-only', $options);
if ($directOnly && $includeOnly) {
    throw new InvalidArgumentException('Use apenas uma das opcoes: --direct-only ou --include-only.');
}

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec('PRAGMA busy_timeout = 30000');
ensureOptionsSchema($pdo);

[$company, $environment] = loadResolverContext($pdo, $companyCode, $environmentId);
$apiBase = resolveCompanyApiBase((string) $environment['pasoe_base_url'], (string) $company['path_param'], (string) $company['code']);
if ($apiBase === '') {
    throw new RuntimeException('Endpoint PASOE nao encontrado para a empresa informada.');
}

$rows = loadRowsToReprocess($pdo, $onlyMissing, $limit, $directOnly, $includeOnly);
$total = count($rows);
$processed = 0;
$withOptions = 0;
$errors = [];

echo "Reprocessando {$total} registro(s) de view-as via {$apiBase}\n";

foreach (array_chunk($rows, $batchSize) as $chunk) {
    $directRows = [];
    $includeRows = [];
    foreach ($chunk as $row) {
        if (extractViewAsInclude((string) $row['view_as']) !== '') {
            $includeRows[] = $row;
        } else {
            $directRows[] = $row;
        }
    }

    $chunkProcessed = 0;
    $chunkWithOptions = 0;
    $chunkErrors = [];

    foreach ($directRows as $row) {
        $listExpression = normalizeDirectListExpression((string) $row['view_as']);
        $optionRows = $listExpression !== '' ? parseOptionsExpression($listExpression, isSingleViewAsList((string) $row['view_as'], '')) : [];
        saveOptions($pdo, $row, $optionRows, 'LOCAL');
        $chunkProcessed++;
        if ($optionRows) {
            $chunkWithOptions++;
        }
    }

    if ($includeRows) {
        [$resolvedProcessed, $resolvedWithOptions, $resolvedErrors] = processChunk($pdo, $apiBase, $company, $environment, $includeRows);
        $chunkProcessed += $resolvedProcessed;
        $chunkWithOptions += $resolvedWithOptions;
        array_push($chunkErrors, ...$resolvedErrors);
    }

    $processed += $chunkProcessed;
    $withOptions += $chunkWithOptions;
    array_push($errors, ...$chunkErrors);
    echo "Processados {$processed}/{$total}; com opcoes {$withOptions}\n";
}

echo "Concluido. Processados={$processed}; com_opcoes={$withOptions}; erros=" . count($errors) . "\n";
foreach (array_slice($errors, 0, 20) as $error) {
    echo "ERRO: {$error}\n";
}
if (count($errors) > 20) {
    echo "ERRO: mais " . (count($errors) - 20) . " erro(s) omitido(s).\n";
}

function cliOptions(array $argv): array
{
    $options = [];
    foreach (array_slice($argv, 1) as $arg) {
        if (strpos($arg, '--') !== 0) {
            continue;
        }
        $arg = substr($arg, 2);
        if (strpos($arg, '=') === false) {
            $options[$arg] = true;
            continue;
        }
        [$key, $value] = explode('=', $arg, 2);
        $options[$key] = $value;
    }
    return $options;
}

function ensureOptionsSchema(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS field_view_as_options (
            id TEXT PRIMARY KEY,
            view_as_id TEXT NOT NULL,
            environment_id TEXT NOT NULL DEFAULT "",
            company_id TEXT NOT NULL DEFAULT "",
            database_name TEXT NOT NULL DEFAULT "",
            table_name TEXT NOT NULL,
            field_name TEXT NOT NULL,
            option_order INTEGER NOT NULL DEFAULT 0,
            label TEXT NOT NULL DEFAULT "",
            value TEXT NOT NULL DEFAULT "",
            source TEXT NOT NULL DEFAULT "manual",
            updated_at TEXT NOT NULL,
            UNIQUE(view_as_id, option_order)
        )'
    );
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_field_view_as_options_lookup ON field_view_as_options(environment_id, company_id, database_name, table_name, field_name)');
}

function loadResolverContext(PDO $pdo, string $companyCode, string $environmentId): array
{
    $stmt = $pdo->prepare(
        'SELECT c.*, e.id AS env_id, e.name AS env_name, e.pasoe_base_url, e.servidor, e.usuario, e.senha, e.arquivo_pf, e.arquivo_alias
         FROM companies c
         JOIN environments e ON e.id = c.environment_id
         WHERE c.code = :code
         LIMIT 1'
    );
    $stmt->execute([':code' => $companyCode]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        throw new RuntimeException('Empresa nao encontrada: ' . $companyCode);
    }
    if ($environmentId !== '' && $environmentId !== (string) $row['environment_id']) {
        $envStmt = $pdo->prepare('SELECT * FROM environments WHERE id = :id');
        $envStmt->execute([':id' => $environmentId]);
        $env = $envStmt->fetch(PDO::FETCH_ASSOC);
        if (!$env) {
            throw new RuntimeException('Ambiente nao encontrado: ' . $environmentId);
        }
    } else {
        $env = [
            'id' => (string) $row['env_id'],
            'name' => (string) $row['env_name'],
            'pasoe_base_url' => (string) $row['pasoe_base_url'],
            'servidor' => (string) $row['servidor'],
            'usuario' => (string) $row['usuario'],
            'senha' => (string) $row['senha'],
            'arquivo_pf' => (string) $row['arquivo_pf'],
            'arquivo_alias' => (string) $row['arquivo_alias'],
        ];
    }
    return [$row, $env];
}

function resolveCompanyApiBase(string $template, string $pathParam, string $code): string
{
    $value = trim($template);
    if ($value === '') {
        return '';
    }
    $token = $pathParam !== '' ? $pathParam : $code;
    return rtrim(str_replace('{empresa}', $token, $value), '/');
}

function loadRowsToReprocess(PDO $pdo, bool $onlyMissing, int $limit, bool $directOnly, bool $includeOnly): array
{
    $sql = 'SELECT f.*
            FROM field_view_as f
            WHERE trim(f.view_as) <> ""
              AND (
                lower(f.view_as) LIKE "%radio-buttons%"
                OR lower(f.view_as) LIKE "%list-item%"
                OR (f.view_as LIKE "%{%" AND lower(f.view_as) LIKE "%.i%")
              )';
    if ($directOnly) {
        $sql .= ' AND NOT (f.view_as LIKE "%{%" AND lower(f.view_as) LIKE "%.i%")';
    }
    if ($includeOnly) {
        $sql .= ' AND (f.view_as LIKE "%{%" AND lower(f.view_as) LIKE "%.i%")';
    }
    if ($onlyMissing) {
        $sql .= ' AND NOT EXISTS (SELECT 1 FROM field_view_as_options o WHERE o.view_as_id = f.id)';
    }
    $sql .= ' ORDER BY lower(f.database_name), lower(f.table_name), lower(f.field_name)';
    if ($limit > 0) {
        $sql .= ' LIMIT ' . $limit;
    }
    return $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
}

function postJson(string $url, array $payload): array
{
    $http_response_header = [];
    $body = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $context = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => "Content-Type: application/json; charset=utf-8\r\nAccept: application/json\r\n",
            'content' => $body,
            'timeout' => 120,
            'ignore_errors' => true,
        ],
        'ssl' => [
            'verify_peer' => false,
            'verify_peer_name' => false,
        ],
    ]);
    $response = file_get_contents($url, false, $context);
    $status = 'HTTP sem status';
    foreach ($http_response_header as $header) {
        if (stripos($header, 'HTTP/') === 0) {
            $status = $header;
            break;
        }
    }
    if ($response === false) {
        return ['success' => false, 'error' => 'Falha HTTP ao chamar ' . $url . ' (' . $status . ')'];
    }
    $decoded = json_decode($response, true);
    if (!is_array($decoded)) {
        return ['success' => false, 'error' => 'Resposta nao JSON (' . $status . '): ' . substr($response, 0, 300)];
    }
    if (!($decoded['success'] ?? false) && empty($decoded['error'])) {
        $decoded['error'] = 'Resposta sem detalhe (' . $status . '): ' . substr($response, 0, 300);
    }
    return $decoded;
}

function processChunk(PDO $pdo, string $apiBase, array $company, array $environment, array $chunk): array
{
    $response = resolveRows($apiBase, $company, $environment, $chunk);
    if (!($response['success'] ?? false)) {
        if (count($chunk) > 1) {
            $processed = 0;
            $withOptions = 0;
            $errors = [];
            foreach (array_chunk($chunk, max(1, intdiv(count($chunk), 2))) as $part) {
                [$partProcessed, $partWithOptions, $partErrors] = processChunk($pdo, $apiBase, $company, $environment, $part);
                $processed += $partProcessed;
                $withOptions += $partWithOptions;
                array_push($errors, ...$partErrors);
            }
            return [$processed, $withOptions, $errors];
        }
        $detail = json_encode($response['error'] ?? $response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if (trim((string) $detail, "\" \t\r\n") === '') {
            $detail = json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }
        return [0, 0, ['Lote iniciado em ' . ($chunk[0]['table_name'] ?? '') . '.' . ($chunk[0]['field_name'] ?? '') . ': ' . $detail]];
    }

    $processed = 0;
    $withOptions = 0;
    $errors = [];
    $data = is_array($response['data'] ?? null) ? $response['data'] : [];
    foreach ($chunk as $index => $storedRow) {
        $resolved = is_array($data[$index] ?? null) ? $data[$index] : [];
        $resolverError = trim((string) ($resolved['resolverError'] ?? ''));
        if ($resolverError !== '') {
            $errors[] = $storedRow['table_name'] . '.' . $storedRow['field_name'] . ': ' . $resolverError;
        }
        $listExpression = trim((string) ($resolved['listExpression'] ?? ''));
        $include = extractViewAsInclude((string) $storedRow['view_as']);
        $optionRows = $listExpression !== ''
            ? parseOptionsExpression($listExpression, isSingleViewAsList((string) $storedRow['view_as'], $include))
            : normalizeOptions($resolved['options'] ?? []);
        saveOptions($pdo, $storedRow, $optionRows, 'PASOE');
        $processed++;
        if ($optionRows) {
            $withOptions++;
        }
    }
    return [$processed, $withOptions, $errors];
}

function resolveRows(string $apiBase, array $company, array $environment, array $chunk): array
{
    $payloadRows = array_map(static function (array $row): array {
        return [
            'field' => (string) $row['field_name'],
            'viewAs' => (string) $row['view_as'],
        ];
    }, $chunk);
    return postJson($apiBase . '/metadata/view-as/resolve', [
        'companyId' => (string) $company['code'],
        'environment' => [
            'id' => (string) $environment['id'],
            'servidor' => (string) $environment['servidor'],
            'usuario' => (string) $environment['usuario'],
            'senha' => (string) $environment['senha'],
            'arquivoPf' => (string) $environment['arquivo_pf'],
            'arquivoAlias' => (string) $environment['arquivo_alias'],
        ],
        'rows' => $payloadRows,
    ]);
}

function normalizeOptions($options): array
{
    if (!is_array($options)) {
        return [];
    }
    $normalized = [];
    foreach ($options as $option) {
        if (!is_array($option)) {
            continue;
        }
        $label = trim((string) ($option['label'] ?? $option['text'] ?? ''));
        $value = trim((string) ($option['value'] ?? $label));
        if ($label !== '') {
            $normalized[] = ['label' => $label, 'value' => $value];
        }
    }
    return $normalized;
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
    if (stripos($text, 'toggle-box') !== false || stripos($text, 'editor') !== false) {
        return '';
    }
    if (preg_match('/^\{.*\}$/', $text) || $text === '?') {
        return '';
    }
    return $text;
}

function isSingleViewAsList(string $viewAs, string $include): bool
{
    if ($include !== '') {
        return true;
    }
    $lower = strtolower($viewAs);
    if (strpos($lower, 'list-item-pairs') !== false) {
        return false;
    }
    return strpos($lower, 'list-items') !== false || strpos($lower, 'list-item') !== false;
}

function parseOptionsExpression(string $listExpression, bool $singleItems = false): array
{
    $tokens = str_getcsv($listExpression);
    if ($singleItems) {
        return array_values(array_filter(array_map(static function ($token): array {
            $value = cleanOptionToken((string) $token);
            return $value === '' ? [] : ['label' => $value, 'value' => $value];
        }, $tokens)));
    }
    $options = [];
    for ($index = 0; $index < count($tokens); $index += 2) {
        $label = cleanOptionToken((string) ($tokens[$index] ?? ''));
        $value = cleanOptionToken((string) ($tokens[$index + 1] ?? $label));
        if ($label !== '') {
            $options[] = ['label' => $label, 'value' => $value];
        }
    }
    return $options;
}

function cleanOptionToken(string $value): string
{
    $text = trim(str_replace(['"', "'", '/'], '', $value));
    $text = preg_replace('/\s+(?:HORIZONTAL|VERTICAL|SIZE|FONT|FORMAT|NO-UNDO|HELP|TOOLTIP)\b.*$/i', '', $text) ?? $text;
    return trim($text);
}

function saveOptions(PDO $pdo, array $row, array $options, string $source): void
{
    $delete = $pdo->prepare('DELETE FROM field_view_as_options WHERE view_as_id = :view_as_id');
    $delete->execute([':view_as_id' => $row['id']]);
    if (!$options) {
        return;
    }
    $stmt = $pdo->prepare(
        'INSERT OR REPLACE INTO field_view_as_options
         (id, view_as_id, environment_id, company_id, database_name, table_name, field_name, option_order, label, value, source, updated_at)
         VALUES (:id, :view_as_id, "", "", :database_name, :table_name, :field_name, :option_order, :label, :value, :source, :updated_at)'
    );
    foreach ($options as $index => $option) {
        $stmt->execute([
            ':id' => sha1((string) $row['id'] . '|' . $index),
            ':view_as_id' => (string) $row['id'],
            ':database_name' => (string) $row['database_name'],
            ':table_name' => (string) $row['table_name'],
            ':field_name' => (string) $row['field_name'],
            ':option_order' => $index,
            ':label' => cleanOptionToken((string) $option['label']),
            ':value' => cleanOptionToken((string) $option['value']),
            ':source' => $source,
            ':updated_at' => date(DATE_ATOM),
        ]);
    }
}
