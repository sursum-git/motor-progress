<?php
declare(strict_types=1);
require_once __DIR__ . '/../../web/pasoe-consumer-auth.php';
$dir = sys_get_temp_dir() . '/query-proxy-' . bin2hex(random_bytes(6));
mkdir($dir,0700); mkdir($dir.'/public',0700);
$file=$dir.'/token'; $token=bin2hex(random_bytes(32));
file_put_contents($file,$token."\n"); chmod($file,0600);
$checks=0;
function check(bool $ok): void { global $checks; if (!$ok) throw new RuntimeException('Teste de credencial do proxy falhou.'); $checks++; }
function denied(callable $fn): bool { try {$fn(); return false;} catch (RuntimeException $e) {return true;} }
try {
 check(str_contains(sursumQueryProxySecretFile('pasoe.token'), '/private/sursum-query-progress/'));
 check(!str_starts_with(str_replace('\\','/',sursumQueryProxySecretFile('pasoe.token')),str_replace('\\','/',realpath(__DIR__.'/../../web')).'/'));
 check(denied(fn()=>sursumQueryProxySecretFile('../token')));
 check(loadSursumQueryProxyToken($file,$dir.'/public')===$token);
 check(denied(fn()=>loadSursumQueryProxyToken($file.'.missing',$dir.'/public')));
 file_put_contents($file,'invalid'); check(denied(fn()=>loadSursumQueryProxyToken($file,$dir.'/public')));
 file_put_contents($dir.'/public/token',$token); chmod($dir.'/public/token',0600);
 check(denied(fn()=>loadSursumQueryProxyToken($dir.'/public/token',$dir.'/public')));
 check(sursumIsDynamicQueryTarget('https://192.168.0.111:9911/med/web/SursumDynamicQuery/query'));
 check(!sursumIsDynamicQueryTarget('https://host/med/web/SursumPrograms/ciw-cadastros'));
 check(!sursumIsDynamicQueryTarget('https://host/SursumDynamicQueryFake/query'));
 file_put_contents($file,$token);
 putenv('SURSUM_QUERY_PROXY_TOKEN_FILE='.$file); $_SERVER['DOCUMENT_ROOT']=$dir.'/public';
 check(sursumQueryProxyAuthorization('https://192.168.0.111:9911/med/web/SursumDynamicQuery/query')==='Bearer '.$token);
 check(denied(fn()=>sursumQueryProxyAuthorization('http://192.168.0.111:9911/med/web/SursumDynamicQuery/query')));
 check(sursumQueryProxyAuthorization('https://host/med/web/SursumPrograms/ciw-cadastros')===null);
 check(sursumQueryProxyAuthorization('https://192.168.0.111:9921/med/web/SursumDynamicQuery/query')===null);
 check(sursumQueryProxyAuthorization('https://192.168.0.111:9911/ima/web/SursumDynamicQuery/query')===null);
 check(sursumQueryProxyTlsOptions('https://192.168.0.111:9921/med/web/SursumDynamicQuery/query')===[]);
 check(sursumQueryProxyAuthorization('https://192.168.0.222:9911/med/web/SursumDynamicQuery/query')===null);
 $pin='sha256//'.base64_encode(random_bytes(32));
 file_put_contents($file.'.pin',$pin); chmod($file.'.pin',0600);
 putenv('SURSUM_QUERY_PROXY_PIN_FILE='.$file.'.pin');
 $tls=sursumQueryProxyTlsOptions('https://192.168.0.111:9911/med/web/SursumDynamicQuery/query');
 check($tls[CURLOPT_PINNEDPUBLICKEY]===$pin);
 file_put_contents($file.'.pin','invalid');
 check(denied(fn()=>sursumQueryProxyTlsOptions('https://192.168.0.111:9911/med/web/SursumDynamicQuery/query')));
 echo 'PASS '.$checks." proxy checks\n";
} finally {putenv('SURSUM_QUERY_PROXY_TOKEN_FILE');putenv('SURSUM_QUERY_PROXY_PIN_FILE');foreach([$file,$file.'.pin',$dir.'/public/token'] as $p)if(is_file($p))unlink($p);rmdir($dir.'/public');rmdir($dir);}
