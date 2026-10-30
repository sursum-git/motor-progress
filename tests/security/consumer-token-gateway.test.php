<?php
declare(strict_types=1);
require __DIR__.'/../../web/consumer-token-gateway.php';
require __DIR__.'/../../web/query-consumers-admin-lib.php';
$checks=0;
function tokenCheck(bool $ok):void{global $checks;if(!$ok)throw new RuntimeException('Token check '.($checks+1).' failed');$checks++;}
function tokenDeny(callable $fn,int $status):void{try{$fn();}catch(ConsumerQueryError $e){tokenCheck($e->httpStatus===$status);return;}throw new RuntimeException('Expected '.$status);}
$server=['HTTPS'=>'on','REQUEST_METHOD'=>'POST','CONTENT_TYPE'=>'application/x-www-form-urlencoded'];
$body=http_build_query(['grant_type'=>'client_credentials','client_id'=>'partner','client_secret'=>str_repeat('a',64)]);
$request=consumerTokenPrepare($server,$body);
tokenCheck(json_decode($request['body'],true)===['grant_type'=>'client_credentials','client_id'=>'partner','client_secret'=>str_repeat('a',64)]);
foreach(['GET','PUT','DELETE'] as $method)tokenDeny(fn()=>consumerTokenPrepare(array_replace($server,['REQUEST_METHOD'=>$method]),$body),405);
tokenDeny(fn()=>consumerTokenPrepare(array_replace($server,['HTTPS'=>'off']),$body),426);
tokenDeny(fn()=>consumerTokenPrepare(array_replace($server,['PATH_INFO'=>'/consumers']),$body),404);
tokenDeny(fn()=>consumerTokenPrepare(array_replace($server,['QUERY_STRING'=>'client_secret=abc']),$body),400);
tokenDeny(fn()=>consumerTokenPrepare(array_replace($server,['CONTENT_TYPE'=>'application/json']),$body),415);
foreach(['','grant_type=password&client_id=partner&client_secret='.str_repeat('a',64),$body.'&scope=admin',$body.'&target=https://evil',$body.'&client_id=other',$body.'&client_secret[]=x'] as $bad)tokenDeny(fn()=>consumerTokenPrepare($server,$bad),400);
tokenDeny(fn()=>consumerTokenPrepare($server,str_repeat('a',4097)),413);
$prepared=consumerAdminPrepare(['action'=>'create-client','id'=>'partner','queries'=>['saldo-estoque-por-referencia'],'days'=>90,'revision'=>str_repeat('a',64)]);
tokenCheck(strlen($prepared['token'])===64 && $prepared['payload']['clientSecretSha256']===hash('sha256',$prepared['token']));
tokenCheck(!isset($prepared['payload']['tokenSha256']) && !isset($prepared['payload']['client_secret']));
$rotated=consumerAdminPrepare(['action'=>'credentials','id'=>'partner','days'=>90,'revision'=>str_repeat('a',64)]);
tokenCheck($rotated['token']!==$prepared['token'] && isset($rotated['payload']['clientSecretSha256']));
tokenCheck(consumerAdminProxyBlocked('https://192.168.0.111:9911/med/web/SursumDynamicQuery/token'));
tokenCheck(consumerAdminProxyBlocked('https://192.168.0.111:9911/med/web/SursumDynamicQuery/%74oken'));
tokenCheck(!consumerAdminProxyBlocked('https://192.168.0.111:9911/med/web/SursumDynamicQuery/query'));
echo 'PASS '.$checks." token gateway checks\n";
