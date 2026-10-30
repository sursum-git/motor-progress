<?php
declare(strict_types=1);
require_once __DIR__.'/auth.php';
requireSursumAuth();
require_once __DIR__.'/consumer-query-gateway.php';
require_once __DIR__.'/query-api-docs-lib.php';
header('Cache-Control: no-store, private');header('Pragma: no-cache');
header('Content-Type: application/json; charset=utf-8');header('X-Content-Type-Options: nosniff');
try{
    if(!consumerQueryHttps($_SERVER)){http_response_code(426);throw new RuntimeException('Use HTTPS.');}
    if(($_SERVER['REQUEST_METHOD']??'')!=='GET'){http_response_code(405);throw new RuntimeException('Use GET.');}
    $format=$_GET['format']??'openapi';
    if(!in_array($format,['openapi','postman'],true)){http_response_code(400);throw new RuntimeException('Formato invalido.');}
    $catalog=queryApiCatalog();
    $data=$format==='postman'?queryApiPostman($catalog):queryApiOpenApi($catalog);
    if(isset($_GET['download']))header('Content-Disposition: attachment; filename="sursum-med-'.($format==='postman'?'postman.collection':'openapi').'.json"');
    echo json_encode($data,JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
}catch(Throwable $e){if(http_response_code()<400)http_response_code(503);echo json_encode(['success'=>false,'error'=>['message'=>'Documentacao indisponivel.']],JSON_THROW_ON_ERROR);}
