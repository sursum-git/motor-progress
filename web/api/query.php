<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/consumer-query-gateway.php';

// Deliberately independent of human login, service credentials and request-log-store.
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, private');
header('Pragma: no-cache');
header('X-Content-Type-Options: nosniff');
try {
    $raw = file_get_contents('php://input', false, null, 0, 65537);
    if ($raw === false) throw new ConsumerQueryError(400, 'INVALID_BODY', 'JSON invalido.');
    $request = consumerQueryPrepare($_SERVER, $raw);
    $raw = '';
    if ($request['preflight'] ?? false) {
        header('Allow: POST, OPTIONS');
        http_response_code(204);
        exit;
    }
    $result = consumerQueryForward($request);
    $request = [];
    http_response_code($result['status']);
    if ($result['status'] === 401) header('WWW-Authenticate: Bearer realm="sursum-query"');
    echo $result['body'];
} catch (ConsumerQueryError $error) {
    http_response_code($error->httpStatus);
    if ($error->httpStatus === 401) header('WWW-Authenticate: Bearer realm="sursum-query"');
    if ($error->httpStatus === 405) header('Allow: POST, OPTIONS');
    echo json_encode(['success' => false, 'error' => ['code' => $error->errorCode, 'message' => $error->getMessage()]], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $error) {
    http_response_code(503);
    echo '{"success":false,"error":{"code":"GATEWAY_UNAVAILABLE","message":"Servico de consultas indisponivel."}}';
}
