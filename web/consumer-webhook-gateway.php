<?php
declare(strict_types=1);

require_once __DIR__.'/consumer-query-gateway.php';

function consumerWebhookIdentifier(mixed $value): bool
{
    return is_string($value) && preg_match('/\A[A-Za-z0-9_.-]{1,128}\z/D', $value) === 1 && !in_array($value, ['.', '..'], true);
}

function consumerWebhookUrl(mixed $value): bool
{
    if (!is_string($value) || strlen($value) < 12 || strlen($value) > 2048 || preg_match('/[\x00-\x20\x7f]/D', $value)) return false;
    $parts=parse_url($value);
    if (!is_array($parts) || strtolower((string)($parts['scheme']??''))!=='https' || !isset($parts['host'])
        || isset($parts['user']) || isset($parts['pass']) || isset($parts['fragment'])) return false;
    if (isset($parts['port']) && (int)$parts['port']!==443) return false;
    $host=(string)$parts['host'];
    if (filter_var($host,FILTER_VALIDATE_IP)!==false || strlen($host)>253 || !str_contains($host,'.')) return false;
    foreach(explode('.',$host) as $label) if (preg_match('/\A[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\z/D',$label)!==1) return false;
    return true;
}

function consumerWebhookPrepare(array $server,string $raw,array $query): array
{
    if (!consumerQueryHttps($server)) throw new ConsumerQueryError(426,'HTTPS_REQUIRED','Use HTTPS para administrar o webhook.');
    if (($server['PATH_INFO']??'')!=='') throw new ConsumerQueryError(404,'ROUTE_NOT_FOUND','Rota nao encontrada.');
    $method=strtoupper((string)($server['REQUEST_METHOD']??'GET'));
    if ($method==='OPTIONS') return ['preflight'=>true];
    $token=(string)($server['HTTP_X_SURSUM_QUERY_TOKEN']??'');
    if (preg_match('/\A[a-fA-F0-9]{64}\z/D',$token)!==1) throw new ConsumerQueryError(401,'AUTH_REQUIRED','Credencial ausente ou invalida.');
    if (!in_array($method,['GET','PUT','DELETE'],true)) throw new ConsumerQueryError(405,'METHOD_NOT_ALLOWED','Use GET, PUT ou DELETE.');
    if (strlen($raw)>65536 || (int)($server['CONTENT_LENGTH']??0)>65536) throw new ConsumerQueryError(413,'REQUEST_TOO_LARGE','O JSON deve ter no maximo 64 KiB.');
    if ($method==='GET') {
        $code=$query['code']??null;
        if (count($query)!==1 || !consumerWebhookIdentifier($code) || $raw!=='' || ($server['QUERY_STRING']??'')!=='code='.$code) {
            throw new ConsumerQueryError(400,'INVALID_WEBHOOK_REQUEST','Informe somente code valido.');
        }
        return ['token'=>$token,'method'=>$method,'path'=>'/consumer-webhooks?code='.$code,'code'=>$code];
    }
    if (strtolower(trim(explode(';',(string)($server['CONTENT_TYPE']??''),2)[0]))!=='application/json') {
        throw new ConsumerQueryError(415,'JSON_REQUIRED','Use Content-Type: application/json.');
    }
    if (($server['QUERY_STRING']??'')!=='' || $query!==[]) throw new ConsumerQueryError(400,'URL_PARAMETERS_NOT_ALLOWED','Informe code no JSON.');
    try {
        $request=json_decode($raw,false,16,JSON_THROW_ON_ERROR|JSON_BIGINT_AS_STRING);
    } catch (JsonException $error) {
        throw new ConsumerQueryError(400,'INVALID_JSON','JSON UTF-8 invalido.');
    }
    if (!$request instanceof stdClass || !consumerWebhookIdentifier($request->code??null)) {
        throw new ConsumerQueryError(400,'INVALID_WEBHOOK_REQUEST','Informe code valido.');
    }
    $fields=array_keys(get_object_vars($request));
    if ($method==='PUT') {
        if ($fields!==['code','url'] || !consumerWebhookUrl($request->url??null)) throw new ConsumerQueryError(400,'INVALID_WEBHOOK_REQUEST','Informe somente code e URL HTTPS valida.');
    } elseif ($fields!==['code']) {
        throw new ConsumerQueryError(400,'INVALID_WEBHOOK_REQUEST','Informe somente code.');
    }
    $body=json_encode($request,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
    return ['token'=>$token,'method'=>$method,'path'=>'/consumer-webhooks','body'=>$body,'code'=>$request->code];
}

function consumerWebhookRespond(): void
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store, private'); header('Pragma: no-cache'); header('X-Content-Type-Options: nosniff');
    try {
        $request=consumerWebhookPrepare($_SERVER,(string)file_get_contents('php://input'),$_GET);
        if ($request['preflight']??false) { header('Allow: GET, PUT, DELETE, OPTIONS'); http_response_code(204); return; }
        $result=consumerQueryForward($request); http_response_code($result['status']);
        if ($result['status']===401) header('WWW-Authenticate: Bearer realm="sursum-query"');
        if ($result['body']!=='') echo $result['body'];
    } catch (ConsumerQueryError $error) {
        http_response_code($error->httpStatus);
        if ($error->httpStatus===401) header('WWW-Authenticate: Bearer realm="sursum-query"');
        if ($error->httpStatus===405) header('Allow: GET, PUT, DELETE, OPTIONS');
        echo json_encode(['success'=>false,'error'=>['code'=>$error->errorCode,'message'=>$error->getMessage()]],JSON_THROW_ON_ERROR);
    } catch (Throwable $error) {
        http_response_code(503); echo '{"success":false,"error":{"code":"GATEWAY_UNAVAILABLE","message":"Servico de webhooks indisponivel."}}';
    }
}
