<?php
declare(strict_types=1);

require __DIR__.'/../../web/consumer-webhook-gateway.php';

$checks=0;
function webhookCheck(bool $ok):void { global $checks; if(!$ok) throw new RuntimeException('webhook gateway check '.($checks+1)); $checks++; }
function webhookDenied(callable $call,int $status):void { try { $call(); } catch (ConsumerQueryError $error) { webhookCheck($error->httpStatus===$status); return; } throw new RuntimeException('expected rejection'); }

$token=str_repeat('a',64);
$server=['HTTPS'=>'on','REQUEST_METHOD'=>'GET','HTTP_X_SURSUM_QUERY_TOKEN'=>$token,'PATH_INFO'=>'','QUERY_STRING'=>'code=saldo-estoque-por-referencia'];

$get=consumerWebhookPrepare($server,'',['code'=>'saldo-estoque-por-referencia']);
webhookCheck($get['method']==='GET');
webhookCheck($get['token']===$token);
webhookCheck($get['path']==='/consumer-webhooks?code=saldo-estoque-por-referencia');

$putServer=array_replace($server,['REQUEST_METHOD'=>'PUT','QUERY_STRING'=>'','CONTENT_TYPE'=>'application/json']);
$put=consumerWebhookPrepare($putServer,'{"code":"saldo-estoque-por-referencia","url":"https://receiver.example/webhooks/stock"}',[]);
webhookCheck($put['method']==='PUT');
webhookCheck($put['path']==='/consumer-webhooks');
webhookCheck(json_decode($put['body'])->code==='saldo-estoque-por-referencia');

$deleteServer=array_replace($putServer,['REQUEST_METHOD'=>'DELETE']);
$delete=consumerWebhookPrepare($deleteServer,'{"code":"saldo-estoque-por-referencia"}',[]);
webhookCheck($delete['method']==='DELETE');

foreach([
    ['',[],426],
    ['GET',['code'=>'saldo-estoque-por-referencia','extra'=>'x'],400],
    ['GET',[],400],
    ['POST',[],405],
] as [$method,$query,$status]) {
    $candidate=$server;
    if($method!=='')$candidate['REQUEST_METHOD']=$method; else $candidate['HTTPS']='off';
    webhookDenied(fn()=>consumerWebhookPrepare($candidate,'',$query),$status);
}
foreach(['{}','{"code":"saldo-estoque-por-referencia"}','{"code":"saldo-estoque-por-referencia","url":"http://receiver.example/a"}','{"code":"saldo-estoque-por-referencia","url":"https://127.0.0.1/a"}','{"code":"saldo-estoque-por-referencia","url":"https://user:pass@receiver.example/a"}','{"code":"saldo-estoque-por-referencia","url":"https://receiver.example:444/a"}','{"code":"saldo-estoque-por-referencia","url":"https://receiver.example/a#fragment"}','{"code":"not/allowed","url":"https://receiver.example/a"}','{"code":"saldo-estoque-por-referencia","url":"https://receiver.example/a","target":"other"}'] as $body) webhookDenied(fn()=>consumerWebhookPrepare($putServer,$body,[]),400);
webhookDenied(fn()=>consumerWebhookPrepare(array_replace($putServer,['HTTP_X_SURSUM_QUERY_TOKEN'=>'Bearer '.$token]),'{"code":"q","url":"https://receiver.example/a"}',[]),401);
webhookDenied(fn()=>consumerWebhookPrepare(array_replace($putServer,['CONTENT_TYPE'=>'text/plain']),'{"code":"q","url":"https://receiver.example/a"}',[]),415);
webhookDenied(fn()=>consumerWebhookPrepare(array_replace($putServer,['PATH_INFO'=>'/other']),'{"code":"q","url":"https://receiver.example/a"}',[]),404);
webhookDenied(fn()=>consumerWebhookPrepare($putServer,str_repeat('x',65537),[]),413);

echo 'PASS '.$checks." consumer webhook gateway checks\n";
