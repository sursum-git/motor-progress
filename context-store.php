<?php
declare(strict_types=1);

require_once __DIR__ . "/auth.php";
requireSursumAuth();

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

try {
    $baseDir = __DIR__ . DIRECTORY_SEPARATOR . 'sursum-conf';
    if (!is_dir($baseDir) && !mkdir($baseDir, 0775, true) && !is_dir($baseDir)) {
        throw new RuntimeException('Nao foi possivel criar a pasta sursum-conf.');
    }

    $dbFile = $baseDir . DIRECTORY_SEPARATOR . 'sursum.sqlite';
    $pdo = new PDO('sqlite:' . $dbFile);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->exec('PRAGMA foreign_keys = ON');
    $pdo->exec('PRAGMA journal_mode = WAL');
    initializeSchema($pdo);

    $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    if ($method === 'GET') {
        jsonResponse(['success' => true, 'data' => loadContext($pdo, $baseDir)]);
    }

    if ($method === 'POST') {
        $raw = file_get_contents('php://input') ?: '';
        $payload = json_decode($raw, true);
        if (!is_array($payload)) {
            throw new InvalidArgumentException('JSON invalido.');
        }
        $context = isset($payload['data']) && is_array($payload['data']) ? $payload['data'] : $payload;
        saveContext($pdo, $context);
        jsonResponse(['success' => true, 'data' => loadContext($pdo, $baseDir)]);
    }

    http_response_code(405);
    jsonResponse(['success' => false, 'error' => 'Metodo nao suportado.']);
} catch (Throwable $error) {
    http_response_code(500);
    jsonResponse(['success' => false, 'error' => $error->getMessage()]);
}

function initializeSchema(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS config_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS clients (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
        )'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS environments (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            pasoe_base_url TEXT NOT NULL,
            auth_mode TEXT NOT NULL DEFAULT "none",
            authorization TEXT NOT NULL DEFAULT "",
            company_id_mode TEXT NOT NULL DEFAULT "query",
            extra_query_params TEXT NOT NULL DEFAULT "",
            servidor TEXT NOT NULL DEFAULT "",
            usuario TEXT NOT NULL DEFAULT "",
            senha TEXT NOT NULL DEFAULT "",
            arquivo_pf TEXT NOT NULL DEFAULT "",
            arquivo_alias TEXT NOT NULL DEFAULT ""
        )'
    );
    ensureColumn($pdo, 'environments', 'servidor', 'TEXT NOT NULL DEFAULT ""');
    ensureColumn($pdo, 'environments', 'usuario', 'TEXT NOT NULL DEFAULT ""');
    ensureColumn($pdo, 'environments', 'senha', 'TEXT NOT NULL DEFAULT ""');
    ensureColumn($pdo, 'environments', 'arquivo_pf', 'TEXT NOT NULL DEFAULT ""');
    ensureColumn($pdo, 'environments', 'arquivo_alias', 'TEXT NOT NULL DEFAULT ""');
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS client_environment_links (
            id TEXT PRIMARY KEY,
            client_id TEXT NOT NULL,
            environment_id TEXT NOT NULL,
            UNIQUE(client_id, environment_id),
            FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE CASCADE,
            FOREIGN KEY(environment_id) REFERENCES environments(id) ON DELETE CASCADE
        )'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS companies (
            id TEXT PRIMARY KEY,
            client_id TEXT NOT NULL DEFAULT "",
            environment_id TEXT NOT NULL,
            name TEXT NOT NULL,
            code TEXT NOT NULL,
            path_param TEXT NOT NULL DEFAULT "",
            FOREIGN KEY(environment_id) REFERENCES environments(id) ON DELETE CASCADE
        )'
    );
    ensureColumn($pdo, 'companies', 'path_param', 'TEXT NOT NULL DEFAULT ""');
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS physical_databases (
            id TEXT PRIMARY KEY,
            physical_name TEXT NOT NULL,
            shared INTEGER NOT NULL DEFAULT 0,
            owner_company_ids TEXT NOT NULL DEFAULT "[]",
            alias_map TEXT NOT NULL DEFAULT "[]",
            status TEXT NOT NULL DEFAULT "active"
        )'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS aliases (
            alias TEXT PRIMARY KEY,
            physical_id TEXT NOT NULL DEFAULT "",
            status TEXT NOT NULL DEFAULT "active"
        )'
    );
}

function loadContext(PDO $pdo, string $baseDir): array
{
    if ((int) $pdo->query('SELECT COUNT(*) FROM clients')->fetchColumn() === 0) {
        $jsonFile = $baseDir . DIRECTORY_SEPARATOR . 'context.json';
        if (is_file($jsonFile)) {
            $context = json_decode((string) file_get_contents($jsonFile), true);
            if (is_array($context)) {
                saveContext($pdo, $context);
            }
        }
    }

    return [
        'version' => 4,
        'paths' => loadPaths($pdo),
        'clients' => fetchAll($pdo, 'SELECT id, name FROM clients ORDER BY name'),
        'environments' => array_map(static function (array $row): array {
            return [
                'id' => $row['id'],
                'name' => $row['name'],
                'pasoeBaseUrl' => $row['pasoe_base_url'],
                'authMode' => $row['auth_mode'],
                'authorization' => $row['authorization'],
                'companyIdMode' => $row['company_id_mode'],
                'extraQueryParams' => $row['extra_query_params'],
                'servidor' => $row['servidor'],
                'usuario' => $row['usuario'],
                'senha' => $row['senha'],
                'arquivoPf' => $row['arquivo_pf'],
                'arquivoAlias' => $row['arquivo_alias'],
            ];
        }, fetchAll($pdo, 'SELECT * FROM environments ORDER BY name')),
        'links' => fetchAll($pdo, 'SELECT id, client_id AS clientId, environment_id AS environmentId FROM client_environment_links ORDER BY id'),
        'companies' => fetchAll($pdo, 'SELECT id, client_id AS clientId, environment_id AS environmentId, name, code, path_param AS pathParam FROM companies ORDER BY name'),
        'physicalDatabases' => array_map(static function (array $row): array {
            return [
                'id' => $row['id'],
                'physicalName' => $row['physical_name'],
                'shared' => (bool) $row['shared'],
                'ownerCompanyIds' => json_decode($row['owner_company_ids'], true) ?: [],
                'aliasMap' => json_decode($row['alias_map'], true) ?: [],
                'status' => $row['status'],
            ];
        }, fetchAll($pdo, 'SELECT * FROM physical_databases ORDER BY physical_name')),
        'aliases' => fetchAll($pdo, 'SELECT physical_id AS physicalId, alias, status FROM aliases ORDER BY alias'),
        'selected' => loadSelected($pdo),
    ];
}

function saveContext(PDO $pdo, array $context): void
{
    $pdo->beginTransaction();
    try {
        foreach (['aliases', 'physical_databases', 'companies', 'client_environment_links', 'environments', 'clients'] as $table) {
            $pdo->exec('DELETE FROM ' . $table);
        }

        saveMeta($pdo, 'version', (string) ($context['version'] ?? 4));
        foreach (($context['paths'] ?? []) as $key => $value) {
            saveMeta($pdo, 'path.' . $key, (string) $value);
        }
        foreach (($context['selected'] ?? []) as $key => $value) {
            saveMeta($pdo, 'selected.' . $key, (string) $value);
        }

        $stmt = $pdo->prepare('INSERT INTO clients (id, name) VALUES (:id, :name)');
        foreach (($context['clients'] ?? []) as $item) {
            $stmt->execute([':id' => text($item['id'] ?? ''), ':name' => text($item['name'] ?? $item['id'] ?? '')]);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO environments
             (id, name, pasoe_base_url, auth_mode, authorization, company_id_mode, extra_query_params, servidor, usuario, senha, arquivo_pf, arquivo_alias)
             VALUES (:id, :name, :url, :auth_mode, :authorization, :company_id_mode, :extra_query_params, :servidor, :usuario, :senha, :arquivo_pf, :arquivo_alias)'
        );
        foreach (($context['environments'] ?? []) as $item) {
            $stmt->execute([
                ':id' => text($item['id'] ?? ''),
                ':name' => text($item['name'] ?? $item['id'] ?? ''),
                ':url' => rtrim(text($item['pasoeBaseUrl'] ?? $item['baseUrl'] ?? $item['url'] ?? ''), '/'),
                ':auth_mode' => text($item['authMode'] ?? 'none'),
                ':authorization' => text($item['authorization'] ?? ''),
                ':company_id_mode' => text($item['companyIdMode'] ?? 'query'),
                ':extra_query_params' => text($item['extraQueryParams'] ?? ''),
                ':servidor' => text($item['servidor'] ?? ''),
                ':usuario' => text($item['usuario'] ?? ''),
                ':senha' => text($item['senha'] ?? ''),
                ':arquivo_pf' => text($item['arquivoPf'] ?? $item['arquivo_pf'] ?? ''),
                ':arquivo_alias' => text($item['arquivoAlias'] ?? $item['arquivo_alias'] ?? ''),
            ]);
        }

        $links = $context['links'] ?? legacyLinksFromEnvironments($context['environments'] ?? []);
        $stmt = $pdo->prepare('INSERT OR IGNORE INTO client_environment_links (id, client_id, environment_id) VALUES (:id, :client_id, :environment_id)');
        foreach ($links as $item) {
            $clientId = text($item['clientId'] ?? '');
            $environmentId = text($item['environmentId'] ?? $item['envId'] ?? '');
            if ($clientId === '' || $environmentId === '') {
                continue;
            }
            $stmt->execute([
                ':id' => text($item['id'] ?? ('link-' . slug($clientId . '-' . $environmentId))),
                ':client_id' => $clientId,
                ':environment_id' => $environmentId,
            ]);
        }

        $stmt = $pdo->prepare('INSERT INTO companies (id, client_id, environment_id, name, code, path_param) VALUES (:id, :client_id, :environment_id, :name, :code, :path_param)');
        foreach (($context['companies'] ?? []) as $item) {
            $name = text($item['name'] ?? $item['id'] ?? '');
            $code = text($item['code'] ?? '');
            $stmt->execute([
                ':id' => text($item['id'] ?? ''),
                ':client_id' => text($item['clientId'] ?? ''),
                ':environment_id' => text($item['environmentId'] ?? $item['envId'] ?? ''),
                ':name' => $name,
                ':code' => $code,
                ':path_param' => text($item['pathParam'] ?? $item['path_param'] ?? $item['urlCode'] ?? '') ?: slug($name),
            ]);
        }

        $stmt = $pdo->prepare('INSERT INTO physical_databases (id, physical_name, shared, owner_company_ids, alias_map, status) VALUES (:id, :physical_name, :shared, :owners, :aliases, :status)');
        foreach (($context['physicalDatabases'] ?? []) as $item) {
            $stmt->execute([
                ':id' => text($item['id'] ?? ''),
                ':physical_name' => text($item['physicalName'] ?? $item['name'] ?? $item['id'] ?? ''),
                ':shared' => !empty($item['shared']) ? 1 : 0,
                ':owners' => json_encode(array_values($item['ownerCompanyIds'] ?? []), JSON_UNESCAPED_SLASHES),
                ':aliases' => json_encode(array_values($item['aliasMap'] ?? $item['aliases'] ?? []), JSON_UNESCAPED_SLASHES),
                ':status' => text($item['status'] ?? 'active'),
            ]);
        }

        $stmt = $pdo->prepare('INSERT INTO aliases (physical_id, alias, status) VALUES (:physical_id, :alias, :status)');
        foreach (($context['aliases'] ?? []) as $item) {
            $stmt->execute([
                ':physical_id' => text($item['physicalId'] ?? ''),
                ':alias' => text($item['alias'] ?? $item['name'] ?? ''),
                ':status' => text($item['status'] ?? 'active'),
            ]);
        }

        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        throw $error;
    }
}

function loadPaths(PDO $pdo): array
{
    $defaults = [
        'metadataRoot' => 'sursum-conf/metadata',
        'relationsRoot' => 'sursum-conf/relations',
        'pasoeRoot' => 'sursum-conf/pasoe',
        'databaseCatalog' => 'sursum-conf/metadata/database-catalog.json',
        'aliasesFile' => 'sursum-conf/pasoe/datasul-prod-aliases.p',
    ];
    foreach (fetchAll($pdo, 'SELECT key, value FROM config_meta WHERE key LIKE "path.%"') as $row) {
        $defaults[substr($row['key'], 5)] = $row['value'];
    }
    return $defaults;
}

function ensureColumn(PDO $pdo, string $table, string $column, string $definition): void
{
    foreach (fetchAll($pdo, 'PRAGMA table_info(' . $table . ')') as $row) {
        if (($row['name'] ?? '') === $column) {
            return;
        }
    }
    $pdo->exec('ALTER TABLE ' . $table . ' ADD COLUMN ' . $column . ' ' . $definition);
}

function loadSelected(PDO $pdo): array
{
    $selected = ['clientId' => '', 'environmentId' => '', 'companyId' => ''];
    foreach (fetchAll($pdo, 'SELECT key, value FROM config_meta WHERE key LIKE "selected.%"') as $row) {
        $selected[substr($row['key'], 9)] = $row['value'];
    }
    return $selected;
}

function saveMeta(PDO $pdo, string $key, string $value): void
{
    $stmt = $pdo->prepare('INSERT INTO config_meta (key, value) VALUES (:key, :value) ON CONFLICT(key) DO UPDATE SET value = excluded.value');
    $stmt->execute([':key' => $key, ':value' => $value]);
}

function fetchAll(PDO $pdo, string $sql): array
{
    return $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
}

function legacyLinksFromEnvironments(array $environments): array
{
    $links = [];
    foreach ($environments as $environment) {
        if (!empty($environment['clientId']) && !empty($environment['id'])) {
            $links[] = ['clientId' => $environment['clientId'], 'environmentId' => $environment['id']];
        }
    }
    return $links;
}

function text($value): string
{
    return trim((string) ($value ?? ''));
}

function slug(string $value): string
{
    $slug = strtolower((string) preg_replace('/[^a-zA-Z0-9]+/', '-', $value));
    $slug = trim((string) preg_replace('/-+/', '-', $slug), '-');
    return $slug !== '' ? $slug : 'item';
}

function jsonResponse(array $payload): never
{
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
    exit;
}
