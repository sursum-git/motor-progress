<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
requireSursumAuth();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $action = trim((string) ($_GET['action'] ?? 'list'));
    if ($action === 'detail') {
        jsonOut(['success' => true, 'data' => loadSavedQueryDetail(queryCode())]);
    }
    jsonOut(['success' => true, 'data' => loadSavedQueryList()]);
} catch (Throwable $error) {
    jsonOut(['success' => false, 'error' => $error->getMessage()], 500);
}

function queryCode(): string
{
    $code = trim((string) ($_GET['code'] ?? ''));
    if ($code === '') {
        throw new InvalidArgumentException('Codigo da consulta obrigatorio.');
    }
    if (!preg_match('/^[A-Za-z0-9_.-]+$/', $code)) {
        throw new InvalidArgumentException('Codigo da consulta invalido.');
    }
    return $code;
}

function savedQueryDirectories(): array
{
    return array_values(array_unique([
        dirname(__DIR__) . DIRECTORY_SEPARATOR . 'sursum-api' . DIRECTORY_SEPARATOR . 'querys',
        __DIR__ . DIRECTORY_SEPARATOR . 'sursum-querys',
    ]));
}

function savedQueryPath(string $code): string
{
    foreach (savedQueryDirectories() as $directory) {
        $path = $directory . DIRECTORY_SEPARATOR . $code . '.json';
        if (is_file($path)) {
            return $path;
        }
    }
    throw new RuntimeException('Consulta salva nao encontrada: ' . $code);
}

function loadSavedQueryList(): array
{
    $items = [];
    foreach (savedQueryDirectories() as $directory) {
        if (!is_dir($directory)) {
            continue;
        }
        foreach (glob($directory . DIRECTORY_SEPARATOR . '*.json') ?: [] as $path) {
            $code = basename($path, '.json');
            if (isset($items[$code])) {
                continue;
            }
            $data = readSavedQueryFile($path);
            $items[$code] = mapSavedQuerySummary($code, $data, $path);
        }
    }
    ksort($items, SORT_NATURAL | SORT_FLAG_CASE);
    return array_values($items);
}

function loadSavedQueryDetail(string $code): array
{
    $path = savedQueryPath($code);
    $data = readSavedQueryFile($path);
    $summary = mapSavedQuerySummary($code, $data, $path);
    $summary['query'] = $data['query'] ?? $data;
    $summary['externalFilters'] = normalizeExternalFilters($data);
    return $summary;
}

function readSavedQueryFile(string $path): array
{
    $raw = file_get_contents($path);
    if ($raw === false) {
        throw new RuntimeException('Nao foi possivel ler a consulta salva: ' . basename($path));
    }
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        throw new RuntimeException('JSON invalido na consulta salva: ' . basename($path));
    }
    return $data;
}

function mapSavedQuerySummary(string $code, array $data, string $path): array
{
    $query = is_array($data['query'] ?? null) ? $data['query'] : $data;
    $sources = is_array($query['sources'] ?? null) ? $query['sources'] : [];
    return [
        'code' => $data['code'] ?? $code,
        'name' => $data['name'] ?? $data['description'] ?? $code,
        'status' => $data['status'] ?? 'ready',
        'sourceCount' => count($sources),
        'externalFilterCount' => count(normalizeExternalFilters($data)),
        'path' => basename($path),
        'updatedAt' => filemtime($path) ? date(DATE_ATOM, (int) filemtime($path)) : '',
    ];
}

function normalizeExternalFilters(array $data): array
{
    $filters = [];
    if (is_array($data['externalFilters'] ?? null)) {
        $filters = $data['externalFilters'];
    } elseif (is_array($data['query']['externalFilters'] ?? null)) {
        $filters = $data['query']['externalFilters'];
    }
    return array_values(array_map(static function (array $filter): array {
        return [
            'name' => (string) ($filter['name'] ?? ''),
            'source' => (string) ($filter['source'] ?? 'querystring'),
            'sourceAlias' => (string) ($filter['sourceAlias'] ?? ''),
            'field' => (string) ($filter['field'] ?? ''),
            'operator' => (string) ($filter['operator'] ?? '='),
            'required' => (bool) ($filter['required'] ?? false),
        ];
    }, array_filter($filters, 'is_array')));
}

function jsonOut(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    exit;
}
