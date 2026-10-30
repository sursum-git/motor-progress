<?php
declare(strict_types=1);
require __DIR__ . '/../../web/query-consumers-admin-lib.php';
$checks=0;
function ok(bool $value): void {global $checks; if(!$value)throw new RuntimeException('Check '.($checks+1).' failed');$checks++;}
function rejected(callable $fn): void {try{$fn();}catch(InvalidArgumentException|RuntimeException $e){ok(true);return;}throw new RuntimeException('Expected rejection');}
ok(consumerAdminAllowed(['username'=>'tadeu.parreiras','source'=>'ldap']));
foreach([null,[],['username'=>'outro','source'=>'ldap'],['username'=>'tadeu.parreiras.evil','source'=>'ldap'],['username'=>'DOMINIO\\tadeu.parreiras','source'=>'ldap'],['username'=>'tadeu.parreiras','source'=>'local']] as $user)ok(!consumerAdminAllowed($user));
ok(consumerAdminAllowed(['username'=>'TADEU.PARREIRAS','source'=>'ldap']));
ok(consumerAdminSecureRequest(['HTTPS'=>'on']));
ok(consumerAdminSecureRequest(['HTTPS'=>'1']));
ok(!consumerAdminSecureRequest([]));
ok(!consumerAdminSecureRequest(['HTTPS'=>'off']));
ok(!consumerAdminSecureRequest(['HTTP_X_FORWARDED_PROTO'=>'https']));
ok(consumerAdminSecureRequest(['REMOTE_ADDR'=>'127.0.0.1','HTTP_X_FORWARDED_PROTO'=>'https']));
ok(consumerAdminSecureRequest(['REMOTE_ADDR'=>'::1','HTTP_X_FORWARDED_PROTO'=>'https']));
ok(!consumerAdminSecureRequest(['REMOTE_ADDR'=>'192.168.0.50','HTTP_X_FORWARDED_PROTO'=>'https']));
ok(!consumerAdminSecureRequest(['REMOTE_ADDR'=>'127.0.0.1','HTTP_X_FORWARDED_PROTO'=>'http']));
ok(!consumerAdminSecureRequest(['REMOTE_ADDR'=>'127.0.0.1','HTTP_X_FORWARDED_PROTO'=>'https,http']));
ok(!consumerAdminSecureRequest(['REMOTE_ADDR'=>'127.0.0.1']));
$csrf=bin2hex(random_bytes(32));consumerAdminCheckCsrf($csrf,$csrf);ok(true);
foreach(['',str_repeat('a',64),$csrf.'x'] as $given)rejected(fn()=>consumerAdminCheckCsrf($csrf,$given));
rejected(fn()=>consumerAdminCheckCsrf('', ''));
$base=['action'=>'create','id'=>'parceiro','queries'=>['saldo-estoque-por-referencia'],'days'=>90,'revision'=>str_repeat('a',64)];
$a=consumerAdminPrepare($base);$b=consumerAdminPrepare($base);
ok(strlen($a['token'])===64 && ctype_xdigit($a['token']) && $a['token']!==$b['token']);
ok($a['payload']['tokenSha256']===hash('sha256',$a['token']));
ok(!str_contains(json_encode($a['payload']),$a['token']));
ok(!isset($a['payload']['role']) && !isset($a['payload']['active']));
foreach([['action'=>'erase'],['role'=>'admin'],['active'=>true],['tokenSha256'=>str_repeat('0',64)],['days'=>0],['days'=>366],['days'=>'90'],['queries'=>['*']],['queries'=>[]],['queries'=>['q','q']],['id'=>'../x'],['revision'=>'stale'],['id'=>'web-query-admin']] as $delta)rejected(fn()=>consumerAdminPrepare(array_replace($base,$delta)));
$update=consumerAdminPrepare(array_replace($base,['action'=>'update']));ok($update['token']===null&&!isset($update['payload']['tokenSha256']));
$rotation=consumerAdminPrepare(['action'=>'rotate','id'=>'parceiro','revision'=>$base['revision'],'days'=>30]);ok(strlen($rotation['token'])===64);
$revoke=consumerAdminPrepare(['action'=>'revoke','id'=>'parceiro','revision'=>$base['revision']]);ok($revoke['token']===null);
foreach(['http://192.168.0.111:9911/med/web/SursumDynamicQuery/consumers','https://192.168.0.111:9911/med/web/consumers','https://192.168.0.111:9911/med/web/SursumDynamicQuery/CONSUMERS','https://192.168.0.111:9911/med/web/SursumDynamicQuery/consumers/extra'] as $target)ok(consumerAdminProxyBlocked($target));
ok(!consumerAdminProxyBlocked('https://192.168.0.111:9911/med/web/SursumDynamicQuery/query'));
echo 'PASS '.$checks." consumer admin PHP checks\n";
