<?php
declare(strict_types=1);
require_once __DIR__.'/consumer-query-gateway.php';
function consumerJobsPrepare(array $server,array $query,bool $download):array
{
    if(!consumerQueryHttps($server))throw new ConsumerQueryError(426,'HTTPS_REQUIRED','Use HTTPS.');
    if(($server['PATH_INFO']??'')!=='')throw new ConsumerQueryError(404,'ROUTE_NOT_FOUND','Rota nao encontrada.');
    if(($server['REQUEST_METHOD']??'GET')==='OPTIONS')return ['preflight'=>true];
    if(($server['REQUEST_METHOD']??'GET')!=='GET')throw new ConsumerQueryError(405,'METHOD_NOT_ALLOWED','Use GET.');
    $id=$query['jobId']??null;
    if(count($query)!==1||!is_string($id)||preg_match('/\AJOB-[0-9]{8}-[0-9]{6}-[0-9]{6}\z/D',$id)!==1
        ||($server['QUERY_STRING']??'')!=='jobId='.$id)throw new ConsumerQueryError(400,'INVALID_JOB_ID','Informe somente jobId valido.');
    $token=$server['HTTP_X_SURSUM_QUERY_TOKEN']??'';
    consumerQueryHeaders($token);
    return ['token'=>$token,'path'=>'/consumer-jobs/'.$id.($download?'/result':''),'jobId'=>$id];
}
function consumerJobsRespond(bool $download):void
{
    header('Cache-Control: no-store, private');header('Pragma: no-cache');header('X-Content-Type-Options: nosniff');
    try{
        $request=consumerJobsPrepare($_SERVER,$_GET,$download);
        if($request['preflight']??false){header('Content-Type: application/json; charset=utf-8');header('Allow: GET, OPTIONS');http_response_code(204);return;}
        if($download){consumerJobsStream($request);return;}
        header('Content-Type: application/json; charset=utf-8');
        $result=consumerQueryForward($request);http_response_code($result['status']);
        if($result['status']===401)header('WWW-Authenticate: Bearer realm="sursum-query"');
        if($result['status']===200&&$download)header('Content-Disposition: attachment; filename="'.$request['jobId'].'.json"');
        echo $result['body'];
    }catch(ConsumerQueryError $e){http_response_code($e->httpStatus);if($e->httpStatus===401)header('WWW-Authenticate: Bearer realm="sursum-query"');if($e->httpStatus===405)header('Allow: GET, OPTIONS');echo json_encode(['success'=>false,'error'=>['code'=>$e->errorCode,'message'=>$e->getMessage()]],JSON_THROW_ON_ERROR);
    }catch(Throwable $e){http_response_code(503);echo '{"success":false,"error":{"code":"GATEWAY_UNAVAILABLE","message":"Servico de jobs indisponivel."}}';}
}

function consumerJobsStream(array $request):void
{
    require_once __DIR__.'/pasoe-consumer-auth.php';
    $target='https://192.168.0.111:9911/med/web/SursumDynamicQuery'.$request['path'];
    $ch=curl_init($target);if($ch===false)throw new ConsumerQueryError(503,'GATEWAY_UNAVAILABLE','Servico de jobs indisponivel.');
    $status=502;$headers=[];$started=false;
    try{
        $ok=curl_setopt_array($ch,[CURLOPT_CUSTOMREQUEST=>'GET',CURLOPT_HTTPHEADER=>consumerQueryHeaders($request['token']),CURLOPT_CONNECTTIMEOUT=>10,CURLOPT_TIMEOUT=>900,CURLOPT_FOLLOWLOCATION=>false,
            CURLOPT_HEADERFUNCTION=>static function($handle,string $line)use(&$status,&$headers):int{if(preg_match('~^HTTP/\S+\s+(\d{3})~',$line,$m)){$status=(int)$m[1];$headers=[];}elseif(($p=strpos($line,':'))!==false){$headers[strtolower(trim(substr($line,0,$p)))]=trim(substr($line,$p+1));}return strlen($line);},
            CURLOPT_WRITEFUNCTION=>static function($handle,string $chunk)use(&$started,&$status,&$headers):int{if(!$started){http_response_code($status);foreach(['content-type','content-encoding','content-disposition','content-length','x-sursum-result-sha256'] as $name)if(isset($headers[$name]))header(ucwords($name,'-').': '.$headers[$name]);if($status===401)header('WWW-Authenticate: Bearer realm="sursum-query"');$started=true;}echo $chunk;flush();return strlen($chunk);}
        ])&&curl_setopt_array($ch,sursumQueryProxyTlsOptions($target));
        if(!$ok||curl_exec($ch)===false){if(!$started)throw new ConsumerQueryError(curl_errno($ch)===CURLE_OPERATION_TIMEDOUT?504:502,'UPSTREAM_UNAVAILABLE','Nao foi possivel baixar o resultado.');return;}
        if(!$started){http_response_code($status);header('Content-Type: application/json; charset=utf-8');}
    }finally{curl_close($ch);}
}
