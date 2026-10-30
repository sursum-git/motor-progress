<?php
declare(strict_types=1);
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/query-consumers-admin-lib.php';
header('Cache-Control: no-store, private');
header('Pragma: no-cache');
header('X-Content-Type-Options: nosniff');
header('Content-Type: application/json; charset=utf-8');
function consumerAdminReply(int $status, array $data): never {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    exit;
}
if (!isAuthenticated()) consumerAdminReply(401, ['success'=>false,'error'=>['message'=>'Login obrigatorio.']]);
if (!consumerAdminAllowed($_SESSION['sursum_user'] ?? null)) consumerAdminReply(403, ['success'=>false,'error'=>['message'=>'Administracao restrita a tadeu.parreiras.']]);
if (!consumerAdminSecureRequest($_SERVER)) consumerAdminReply(426, ['success'=>false,'error'=>['message'=>'Abra a administracao por HTTPS.']]);
if (empty($_SESSION['query_consumer_csrf'])) $_SESSION['query_consumer_csrf'] = bin2hex(random_bytes(32));
$csrf = $_SESSION['query_consumer_csrf'];
session_write_close();
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
try {
    if ($method === 'GET') {
        $result = consumerAdminRequest('GET', null);
        if ($result['status'] === 200) $result['data']['csrf'] = $csrf;
        consumerAdminReply($result['status'], $result['data']);
    }
    if ($method !== 'POST') consumerAdminReply(405, ['success'=>false,'error'=>['message'=>'Metodo nao permitido.']]);
    try {
        consumerAdminCheckCsrf($csrf, (string) ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
    } catch (RuntimeException $error) {
        consumerAdminReply(403, ['success'=>false,'error'=>['message'=>$error->getMessage()]]);
    }
    if ((int) ($_SERVER['CONTENT_LENGTH'] ?? 0) > 65536) throw new InvalidArgumentException('Solicitacao muito grande.');
    $raw = file_get_contents('php://input', false, null, 0, 65537);
    if ($raw === false || strlen($raw) > 65536) throw new InvalidArgumentException('Solicitacao invalida.');
    $request = json_decode($raw, true, 32, JSON_THROW_ON_ERROR);
    if (!is_array($request) || array_is_list($request)) throw new InvalidArgumentException('JSON invalido.');
    $prepared = consumerAdminPrepare($request);
    $result = consumerAdminRequest('POST', $prepared['payload']);
    if ($result['status'] === 200 && ($result['data']['success'] ?? false) && $prepared['token'] !== null) {
        if (in_array($request['action'], ['create-client','credentials'],true)) {
            $result['data']['client_id'] = $request['id'];
            $result['data']['client_secret'] = $prepared['token'];
        } else $result['data']['token'] = $prepared['token'];
    }
    if ($result['status'] === 200 && ($result['data']['success'] ?? false)) {
        error_log('QUERY-CONSUMER-ADMIN user=tadeu.parreiras action=' . $request['action'] . ' consumer=' . $request['id']);
    }
    $prepared = null;
    consumerAdminReply($result['status'], $result['data']);
} catch (InvalidArgumentException|JsonException $error) {
    consumerAdminReply(400, ['success'=>false,'error'=>['message'=>$error->getMessage()]]);
} catch (RuntimeException $error) {
    consumerAdminReply(503, ['success'=>false,'error'=>['message'=>$error->getMessage()]]);
} catch (Throwable $error) {
    consumerAdminReply(503, ['success'=>false,'error'=>['message'=>'Administracao indisponivel.']]);
}
