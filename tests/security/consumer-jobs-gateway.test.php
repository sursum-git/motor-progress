<?php
declare(strict_types=1);
require __DIR__.'/../../web/consumer-jobs-gateway.php';
$n=0;function ok(bool $v):void{global $n;if(!$v)throw new RuntimeException('jobs check '.($n+1));$n++;}
function denied(callable $f,int $code):void{try{$f();}catch(ConsumerQueryError $e){ok($e->httpStatus===$code);return;}throw new RuntimeException('expected rejection');}
$s=['HTTPS'=>'on','REQUEST_METHOD'=>'GET','HTTP_X_SURSUM_QUERY_TOKEN'=>str_repeat('a',64),'QUERY_STRING'=>'jobId=JOB-20261028-000001-123456','PATH_INFO'=>''];
$q=['jobId'=>'JOB-20261028-000001-123456'];
ok(consumerJobsPrepare($s,$q,false)['path']==='/consumer-jobs/'.$q['jobId']);
ok(consumerJobsPrepare($s,$q,true)['path']==='/consumer-jobs/'.$q['jobId'].'/result');
foreach(['../consumers','JOB-X/../../metadata','x','JOB-20261028-000001-123456?target=ima'] as $id)denied(fn()=>consumerJobsPrepare($s,['jobId'=>$id],false),400);
denied(fn()=>consumerJobsPrepare($s,$q+['target'=>'ima'],false),400);
denied(fn()=>consumerJobsPrepare(array_replace($s,['REQUEST_METHOD'=>'POST']),$q,false),405);
denied(fn()=>consumerJobsPrepare(array_replace($s,['HTTP_X_SURSUM_QUERY_TOKEN'=>'']),$q,false),401);
denied(fn()=>consumerJobsPrepare(array_replace($s,['PATH_INFO'=>'/consumers']),$q,false),404);
denied(fn()=>consumerJobsPrepare(array_replace($s,['HTTPS'=>'off']),$q,false),426);
echo 'PASS '.$n." consumer job gateway checks\n";
