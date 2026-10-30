<?php
declare(strict_types=1);
require_once __DIR__.'/consumer-query-gateway.php';

function consumerTokenPrepare(array $server, string $raw): array
{
    if (!consumerQueryHttps($server)) throw new ConsumerQueryError(426,'HTTPS_REQUIRED','Use HTTPS.');
    if (($server['PATH_INFO'] ?? '') !== '') throw new ConsumerQueryError(404,'ROUTE_NOT_FOUND','Rota inexistente.');
    if (($server['QUERY_STRING'] ?? '') !== '') throw new ConsumerQueryError(400,'invalid_request','Parametros somente no corpo.');
    if (($server['REQUEST_METHOD'] ?? '') !== 'POST') throw new ConsumerQueryError(405,'invalid_request','Use POST.');
    if (strtolower(trim(explode(';',(string)($server['CONTENT_TYPE'] ?? ''),2)[0])) !== 'application/x-www-form-urlencoded') {
        throw new ConsumerQueryError(415,'invalid_request','Use application/x-www-form-urlencoded.');
    }
    if (strlen($raw)>4096 || (int)($server['CONTENT_LENGTH'] ?? 0)>4096) throw new ConsumerQueryError(413,'invalid_request','Corpo muito grande.');
    $fields=[];
    foreach (explode('&',$raw) as $part) {
        $pair=explode('=',$part,2);
        $key=urldecode($pair[0]);
        if (count($pair)!==2 || !in_array($key,['grant_type','client_id','client_secret'],true) || array_key_exists($key,$fields)) {
            throw new ConsumerQueryError(400,'invalid_request','Campos invalidos.');
        }
        $fields[$key]=urldecode($pair[1]);
    }
    if (count($fields)!==3 || ($fields['grant_type'] ?? '')!=='client_credentials'
        || preg_match('/\A[A-Za-z0-9_.-]{1,128}\z/D',$fields['client_id'] ?? '')!==1
        || preg_match('/\A[a-f0-9]{64}\z/D',$fields['client_secret'] ?? '')!==1) {
        throw new ConsumerQueryError(400,'invalid_request','Credenciais ou grant invalidos.');
    }
    return ['body'=>json_encode($fields,JSON_THROW_ON_ERROR)];
}

function consumerTokenForward(array $request): array
{
    require_once __DIR__.'/pasoe-consumer-auth.php';
    // This fixed unauthenticated issuer validates the client itself. Never load the admin token.
    $target='https://192.168.0.111:9911/med/web/SursumDynamicQuery/token';
    $ch=curl_init($target);
    if ($ch===false) throw new ConsumerQueryError(503,'temporarily_unavailable','Emissao indisponivel.');
    $response='';
    try {
        if (!curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>$request['body'],
            CURLOPT_HTTPHEADER=>['Content-Type: application/json','Accept: application/json'],
            CURLOPT_FOLLOWLOCATION=>false,CURLOPT_CONNECTTIMEOUT=>10,CURLOPT_TIMEOUT=>30,
            CURLOPT_WRITEFUNCTION=>static function($handle,string $chunk)use(&$response):int{
                if(strlen($response)+strlen($chunk)>16384)return 0;
                $response.=$chunk;return strlen($chunk);
            }]) || !curl_setopt_array($ch,sursumQueryProxyTlsOptions($target))) {
            throw new ConsumerQueryError(503,'temporarily_unavailable','Emissao indisponivel.');
        }
        if(curl_exec($ch)===false) throw new ConsumerQueryError(502,'temporarily_unavailable','Emissao indisponivel.');
        $status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);
        $data=json_decode($response,true,16,JSON_THROW_ON_ERROR);
        if(!is_array($data) || !in_array($status,[200,400,401,409,429,503],true)) throw new RuntimeException('Invalid issuer response');
        if($status===200 && (preg_match('/\A[a-f0-9]{64}\z/D',(string)($data['access_token'] ?? ''))!==1
            || ($data['token_type'] ?? '')!=='Bearer' || ($data['expires_in'] ?? 0)!==900)) throw new RuntimeException('Invalid token response');
        if($status!==200 && !is_string($data['error'] ?? null)) throw new RuntimeException('Invalid issuer error');
        return ['status'=>$status,'data'=>$data];
    } catch(JsonException|RuntimeException $e) {
        if($e instanceof ConsumerQueryError)throw $e;
        throw new ConsumerQueryError(502,'temporarily_unavailable','Emissao indisponivel.');
    } finally {curl_close($ch);$request=[];}
}
