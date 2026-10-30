<?php
declare(strict_types=1);

final class ConsumerQueryError extends RuntimeException
{
    public function __construct(public readonly int $httpStatus, public readonly string $errorCode, string $message)
    {
        parent::__construct($message);
    }
}

function consumerQueryHttps(array $server): bool
{
    if (in_array(strtolower((string) ($server['HTTPS'] ?? '')), ['on', '1'], true)) return true;
    // Existing SSL vhost sets this header and proxies through loopback only.
    return in_array((string) ($server['REMOTE_ADDR'] ?? ''), ['127.0.0.1', '::1'], true)
        && ($server['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https';
}

function consumerQueryPrepare(array $server, string $raw): array
{
    if (!consumerQueryHttps($server)) throw new ConsumerQueryError(426, 'HTTPS_REQUIRED', 'Use HTTPS para consumir a consulta.');
    if (($server['PATH_INFO'] ?? '') !== '') throw new ConsumerQueryError(404, 'ROUTE_NOT_FOUND', 'Rota nao encontrada.');
    if (($server['QUERY_STRING'] ?? '') !== '') throw new ConsumerQueryError(400, 'URL_PARAMETERS_NOT_ALLOWED', 'Informe o token no cabecalho e os filtros no JSON.');
    $method = strtoupper((string) ($server['REQUEST_METHOD'] ?? 'GET'));
    if ($method === 'OPTIONS') return ['preflight' => true];
    if ($method !== 'POST') throw new ConsumerQueryError(405, 'METHOD_NOT_ALLOWED', 'Use POST para executar uma consulta salva.');
    $token = (string) ($server['HTTP_X_SURSUM_QUERY_TOKEN'] ?? '');
    if (preg_match('/\A[a-fA-F0-9]{64}\z/D', $token) !== 1) throw new ConsumerQueryError(401, 'AUTH_REQUIRED', 'Credencial ausente ou invalida.');
    if (strtolower(trim(explode(';', (string) ($server['CONTENT_TYPE'] ?? ''), 2)[0])) !== 'application/json') {
        throw new ConsumerQueryError(415, 'JSON_REQUIRED', 'Use Content-Type: application/json.');
    }
    if (strlen($raw) > 65536 || (int) ($server['CONTENT_LENGTH'] ?? 0) > 65536) throw new ConsumerQueryError(413, 'REQUEST_TOO_LARGE', 'O JSON deve ter no maximo 64 KiB.');
    try {
        $request = json_decode($raw, false, 32, JSON_THROW_ON_ERROR | JSON_BIGINT_AS_STRING);
        if (!$request instanceof stdClass || !isset($request->code) || !is_string($request->code)
            || preg_match('/\A[A-Za-z0-9_.-]{1,128}\z/D', $request->code) !== 1 || in_array($request->code, ['.', '..'], true)
            || array_diff(array_keys(get_object_vars($request)), ['code', 'parameters', 'page', 'pageSize', 'paginate', 'paginationMode', 'cursor', 'execution','webhookDelivery'])
            || (property_exists($request, 'parameters') && !$request->parameters instanceof stdClass)) {
            throw new ConsumerQueryError(400, 'INVALID_CONSUMER_REQUEST', 'Campos externos da consulta salva invalidos.');
        }
        $mode = $request->paginationMode ?? 'offset';
        if (property_exists($request, 'execution') && (!is_string($request->execution) || !in_array($request->execution, ['sync','async'], true)
            || ($request->execution === 'async' && $mode === 'cursor'))) {
            throw new ConsumerQueryError(400, 'INVALID_EXECUTION', 'execution deve ser sync ou async. Async nao aceita cursor.');
        }
        if (property_exists($request,'webhookDelivery') && (!is_string($request->webhookDelivery) || !in_array($request->webhookDelivery,['full','manifest'],true)
            || ($request->execution ?? 'sync') !== 'async')) throw new ConsumerQueryError(400,'INVALID_EXECUTION','webhookDelivery exige execution: async e valor full ou manifest.');
        if ((property_exists($request, 'paginationMode') && !is_string($request->paginationMode)) || !in_array($mode, ['offset', 'cursor'], true)
            || ($mode === 'cursor' && (property_exists($request, 'page') || ($request->paginate ?? true) === false))
            || (property_exists($request, 'cursor') && ($mode !== 'cursor' || !is_string($request->cursor) || strlen($request->cursor) > 16384
                || ($request->cursor !== '' && (preg_match('/\Av1\.([a-f0-9]+)\.[a-f0-9]{64}\z/D', $request->cursor, $cursorParts) !== 1
                    || strlen($cursorParts[1]) > 16000 || strlen($cursorParts[1]) % 2 !== 0))))) {
            throw new ConsumerQueryError(400, 'INVALID_PAGINATION', 'Modo ou cursor invalido. Cursor nao aceita page nem paginate:false.');
        }
        if (property_exists($request, 'paginate') && !is_bool($request->paginate)) throw new ConsumerQueryError(400, 'INVALID_PAGINATION', 'paginate deve ser booleano: true ou false.');
        foreach (['page' => 1000000, 'pageSize' => 1000] as $field => $maximum) {
            if (!property_exists($request, $field)) continue;
            $value = $request->$field;
            if ((!is_int($value) && !is_float($value)) || !is_finite((float) $value)
                || $value < 1 || $value > $maximum || floor((float) $value) !== (float) $value) {
                throw new ConsumerQueryError(400, 'INVALID_PAGINATION', $field . ' deve ser inteiro entre 1 e ' . $maximum . '.');
            }
            $request->$field = (int) $value;
        }
        $body = json_encode($request, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    } catch (JsonException $error) {
        throw new ConsumerQueryError(400, 'INVALID_JSON', 'JSON UTF-8 invalido.');
    }
    if (strlen($body) > 65536) throw new ConsumerQueryError(413, 'REQUEST_TOO_LARGE', 'O JSON deve ter no maximo 64 KiB.');
    return ['token' => $token, 'body' => $body];
}

function consumerQueryHeaders(string $token): array
{
    if (preg_match('/\A[a-fA-F0-9]{64}\z/D', $token) !== 1) throw new ConsumerQueryError(401, 'AUTH_REQUIRED', 'Credencial ausente ou invalida.');
    return ['Accept: application/json', 'Content-Type: application/json; charset=utf-8', 'X-Sursum-Query-Token: ' . $token];
}

function consumerQueryAppend(string &$response, string $chunk, int $maximum = 16777216): int
{
    if (strlen($response) + strlen($chunk) > $maximum) return 0;
    $response .= $chunk;
    return strlen($chunk);
}

function consumerQueryForward(array $request): array
{
    require_once __DIR__ . '/pasoe-consumer-auth.php';
    // No caller-selected URL, context or path. Never load the proxy service credential here.
    $path = $request['path'] ?? '/query';
    $method=$request['method'] ?? ($path === '/query' ? 'POST' : 'GET');
    $isJob=preg_match('~\A/consumer-jobs/JOB-[0-9]{8}-[0-9]{6}-[0-9]{6}(?:/result)?\z~D', $path)===1;
    $isWebhook=$path==='/consumer-webhooks' || preg_match('~\A/consumer-webhooks\?code=[A-Za-z0-9_.-]{1,128}\z~D',$path)===1;
    if (($path==='/query' && $method!=='POST') || ($isJob && $method!=='GET') || ($isWebhook && !in_array($method,['GET','PUT','DELETE'],true)) || (!$isJob && !$isWebhook && $path!=='/query')) throw new ConsumerQueryError(400, 'INVALID_ROUTE', 'Rota invalida.');
    $target = 'https://192.168.0.111:9911/med/web/SursumDynamicQuery' . $path;
    $maximum = str_ends_with($path, '/result') ? 67108864 : 16777216;
    $tlsOptions = sursumQueryProxyTlsOptions($target);
    $ch = curl_init($target);
    if ($ch === false) throw new ConsumerQueryError(503, 'GATEWAY_UNAVAILABLE', 'Servico de consultas indisponivel.');
    $response = '';
    try {
        if (!curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_HTTPHEADER => consumerQueryHeaders($request['token']),
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_TIMEOUT => 120,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_WRITEFUNCTION => static function ($handle, string $chunk) use (&$response, $maximum): int {
                return consumerQueryAppend($response, $chunk, $maximum);
            },
        ]) || !curl_setopt_array($ch, $tlsOptions)) {
            throw new ConsumerQueryError(503, 'GATEWAY_UNAVAILABLE', 'Servico de consultas indisponivel.');
        }
        if (in_array($method,['POST','PUT','DELETE'],true)) curl_setopt($ch, CURLOPT_POSTFIELDS, $request['body'] ?? '');
        if (curl_exec($ch) === false) {
            throw new ConsumerQueryError(curl_errno($ch) === CURLE_OPERATION_TIMEDOUT ? 504 : 502, 'UPSTREAM_UNAVAILABLE', 'Nao foi possivel concluir a consulta.');
        }
        $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        if (($status<200 || $status>299) && ($status<400 || $status>599)) throw new ConsumerQueryError(502, 'INVALID_UPSTREAM_RESPONSE', 'Resposta de consulta indisponivel.');
        if ($status===204) return ['status'=>$status,'body'=>''];
        try {
            $decoded = json_decode($response, false, 64, JSON_THROW_ON_ERROR);
        } catch (JsonException $error) {
            throw new ConsumerQueryError(502, 'INVALID_UPSTREAM_RESPONSE', 'Resposta de consulta indisponivel.');
        }
        if (!$decoded instanceof stdClass || !isset($decoded->success) || !is_bool($decoded->success)) {
            throw new ConsumerQueryError(502, 'INVALID_UPSTREAM_RESPONSE', 'Resposta de consulta indisponivel.');
        }
        return ['status' => $status, 'body' => $response];
    } finally {
        curl_close($ch);
        $request = [];
    }
}
