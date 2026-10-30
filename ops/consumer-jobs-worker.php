<?php
declare(strict_types=1);
// Install outside DocumentRoot in private/sursum-query-worker. Never serve or invoke from HTTP.
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
$public=dirname(__DIR__,2).'/web/query-progress';
// CLI has no web-server DocumentRoot; use the actual public root, independent of cron cwd.
$_SERVER['DOCUMENT_ROOT']=dirname($public);
require $public.'/pasoe-consumer-auth.php';
require __DIR__.'/consumer-jobs-worker-lib.php';
function workerPasoe(string $path,array $payload=[]):array{
    $target='https://192.168.0.111:9911/med/web/SursumDynamicQuery'.$path;$auth=sursumQueryProxyAuthorization($target);if($auth===null)throw new RuntimeException('worker authorization unavailable');$ch=curl_init($target);if($ch===false)throw new RuntimeException('worker transport unavailable');
    try{curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>json_encode($payload,JSON_THROW_ON_ERROR),CURLOPT_RETURNTRANSFER=>true,CURLOPT_CONNECTTIMEOUT=>10,CURLOPT_TIMEOUT=>900,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_HTTPHEADER=>['Content-Type: application/json','X-Sursum-Query-Token: '.substr($auth,7)]]);curl_setopt_array($ch,sursumQueryProxyTlsOptions($target));$body=curl_exec($ch);if($body===false)throw new RuntimeException('worker upstream unavailable');return [(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE),(string)$body];}finally{$auth='';curl_close($ch);}
}
function workerPasoeDownload(string $path,string $file):void{
    $target='https://192.168.0.111:9911/med/web/SursumDynamicQuery'.$path;$auth=sursumQueryProxyAuthorization($target);if($auth===null)throw new RuntimeException('worker authorization unavailable');$out=fopen($file,'xb');if($out===false)throw new RuntimeException('temporary artifact unavailable');$ch=curl_init($target);if($ch===false){fclose($out);throw new RuntimeException('worker transport unavailable');}
    try{curl_setopt_array($ch,[CURLOPT_HTTPGET=>true,CURLOPT_FILE=>$out,CURLOPT_CONNECTTIMEOUT=>10,CURLOPT_TIMEOUT=>900,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_HTTPHEADER=>['X-Sursum-Query-Token: '.substr($auth,7)]]);curl_setopt_array($ch,sursumQueryProxyTlsOptions($target));if(curl_exec($ch)===false||(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE)!==200)throw new RuntimeException('artifact download unavailable');}finally{$auth='';curl_close($ch);fclose($out);}
}
function workerWebhookDestination(string $host):string{
    $approvedPrivate=['iol.imatextil.com.br'=>['192.168.0.39']];
    $host=strtolower($host);$ips=gethostbynamel($host)?:[];
    foreach($ips as $candidate){
        $l=ip2long($candidate);if($l===false)continue;$private=false;
        foreach([['10.0.0.0','255.0.0.0'],['127.0.0.0','255.0.0.0'],['169.254.0.0','255.255.0.0'],['172.16.0.0','255.240.0.0'],['192.168.0.0','255.255.0.0'],['100.64.0.0','255.192.0.0'],['224.0.0.0','240.0.0.0']] as [$net,$mask])if(($l&ip2long($mask))===(ip2long($net)&ip2long($mask)))$private=true;
        if(!$private||in_array($candidate,$approvedPrivate[$host]??[],true))return $candidate;
    }
    throw new RuntimeException('private destination');
}
function workerWebhookRetry(array $task):bool{
    $parts=parse_url((string)$task['url']);if(!is_array($parts)||strtolower((string)($parts['scheme']??''))!=='https'||isset($parts['user'],$parts['pass'],$parts['fragment'])||isset($parts['port'])&&(int)$parts['port']!==443)throw new RuntimeException('invalid destination');$host=(string)($parts['host']??'');if($host===''||filter_var($host,FILTER_VALIDATE_IP)!==false)throw new RuntimeException('invalid destination');$ip=workerWebhookDestination($host);
    $timestamp=(string)time();$headers=['User-Agent: Sursum-MED-Webhook/1.0','X-Sursum-Webhook-Event: query.completed','X-Sursum-Webhook-Id: '.$task['jobId'],'X-Sursum-Webhook-Timestamp: '.$timestamp];$upload=null;$temporary='';
    try{if(isset($task['artifactPath'])){$temporary=tempnam(sys_get_temp_dir(),'sursum-webhook-');if($temporary===false)throw new RuntimeException('temporary artifact unavailable');unlink($temporary);workerPasoeDownload((string)$task['artifactPath'],$temporary);$hash=hash_init('sha256',HASH_HMAC,(string)$task['secret']);hash_update($hash,$timestamp.'.');$in=fopen($temporary,'rb');if($in===false)throw new RuntimeException('artifact open unavailable');hash_update_stream($hash,$in);rewind($in);$headers[]='X-Sursum-Webhook-Signature: v1='.hash_final($hash);$headers[]='Content-Type: '.($task['contentType']??'application/x-ndjson');$headers[]='Content-Encoding: '.($task['contentEncoding']??'gzip');$upload=$in;}else{$body=json_encode($task['payload'],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);$headers[]='Content-Type: application/json; charset=utf-8';$headers[]='X-Sursum-Webhook-Signature: v1='.hash_hmac('sha256',$timestamp.'.'.$body,(string)$task['secret']);}
    $ch=curl_init((string)$task['url']);if($ch===false)return true;try{$options=[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_CONNECTTIMEOUT=>10,CURLOPT_TIMEOUT=>900,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_SSL_VERIFYPEER=>true,CURLOPT_SSL_VERIFYHOST=>2,CURLOPT_RESOLVE=>[$host.':443:'.$ip],CURLOPT_HTTPHEADER=>$headers];if($upload!==null){$options[CURLOPT_UPLOAD]=true;$options[CURLOPT_INFILE]=$upload;$options[CURLOPT_INFILESIZE]=filesize($temporary);}else{$options[CURLOPT_POSTFIELDS]=$body;}curl_setopt_array($ch,$options);$ok=curl_exec($ch)!==false;$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);return !$ok||$status===408||$status===429||$status>=500;}finally{curl_close($ch);if(is_resource($upload))fclose($upload);}}
    finally{if($temporary!==''&&is_file($temporary))unlink($temporary);}
}
function workerDrainBatch(string $target,string $authorization):int{
    $multi=curl_multi_init();if($multi===false)throw new RuntimeException('worker transport unavailable');$handles=[];
    try{
        /* PASOE leases, not this fan-out, enforce each saved query's worker ceiling. */
        for($n=0;$n<10;$n++){
            $ch=curl_init($target);if($ch===false)throw new RuntimeException('worker transport unavailable');
            curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>'{}',CURLOPT_RETURNTRANSFER=>true,CURLOPT_CONNECTTIMEOUT=>10,CURLOPT_TIMEOUT=>900,CURLOPT_FOLLOWLOCATION=>false,CURLOPT_HTTPHEADER=>['Content-Type: application/json','X-Sursum-Query-Token: '.$authorization]]);
            if(!curl_setopt_array($ch,sursumQueryProxyTlsOptions($target)))throw new RuntimeException('worker tls unavailable');
            curl_multi_add_handle($multi,$ch);$handles[]=$ch;
        }
        $running=null;do{$status=curl_multi_exec($multi,$running);if($running>0)curl_multi_select($multi,1.0);}while($running>0&&$status===CURLM_OK);
        $processed=0;foreach($handles as $ch){$body=(string)curl_multi_getcontent($ch);$status=(int)curl_getinfo($ch,CURLINFO_RESPONSE_CODE);$data=json_decode($body,true,16,JSON_THROW_ON_ERROR);if($status!==200||($data['success']??false)!==true)throw new RuntimeException('consumer worker failed');$processed+=(int)($data['processed']??0);}
        return $processed;
    }finally{foreach($handles as $ch){curl_multi_remove_handle($multi,$ch);curl_close($ch);}curl_multi_close($multi);}
}
$lock=fopen(__DIR__.'/consumer-jobs-worker.lock','c');
if($lock===false||!flock($lock,LOCK_EX|LOCK_NB))exit(0);
$target='https://192.168.0.111:9911/med/web/SursumDynamicQuery/consumer-jobs/drain';
try{
    $processed=workerRunDrainRounds(static function()use($target):int{
        $authorization=sursumQueryProxyAuthorization($target);if($authorization===null)throw new RuntimeException('worker authorization unavailable');
        try{return workerDrainBatch($target,substr($authorization,7));}finally{$authorization='';}
    });
    $deliveries=0;for($n=0;$n<10;$n++){
        [$deliveryStatus,$deliveryBody]=workerPasoe('/consumer-webhooks/drain');if($deliveryStatus===204)break;$task=json_decode($deliveryBody,true,64,JSON_THROW_ON_ERROR);if($deliveryStatus!==200||($task['success']??false)!==true)throw new RuntimeException('webhook claim failed');try{$retry=workerWebhookRetry($task);}catch(Throwable $error){$retry=true;}workerPasoe('/consumer-webhooks/complete',['jobId'=>$task['jobId'],'lease'=>$task['lease'],'retry'=>$retry]);$deliveries++;
    }
    $health=['success'=>true,'checkedAt'=>gmdate('c'),'processed'=>$processed,'webhooks'=>$deliveries];
    file_put_contents(__DIR__.'/worker-health.json.tmp',json_encode($health,JSON_THROW_ON_ERROR));chmod(__DIR__.'/worker-health.json.tmp',0640);rename(__DIR__.'/worker-health.json.tmp',__DIR__.'/worker-health.json');
    echo 'consumer-worker processed='.$processed.' webhooks='.$deliveries.PHP_EOL;
}catch(Throwable $error){fwrite(STDERR,"consumer-worker unavailable\n");exit(1);
}finally{flock($lock,LOCK_UN);fclose($lock);}

