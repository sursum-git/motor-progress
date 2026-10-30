<?php
declare(strict_types=1);
require_once dirname(__DIR__).'/consumer-token-gateway.php';
header('Cache-Control: no-store');
header('Pragma: no-cache');
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
try {
    $raw=file_get_contents('php://input',false,null,0,4097);
    if($raw===false)throw new ConsumerQueryError(400,'invalid_request','Corpo invalido.');
    $prepared=consumerTokenPrepare($_SERVER,$raw);$raw='';
    $result=consumerTokenForward($prepared);$prepared=[];
    http_response_code($result['status']);
    if($result['status']===429)header('Retry-After: 60');
    echo json_encode($result['data'],JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
} catch(ConsumerQueryError $e) {
    http_response_code($e->httpStatus);
    echo json_encode(['error'=>$e->errorCode],JSON_THROW_ON_ERROR);
} catch(Throwable $e) {
    http_response_code(503);echo '{"error":"temporarily_unavailable"}';
}
