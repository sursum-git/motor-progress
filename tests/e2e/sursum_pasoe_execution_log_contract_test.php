<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$schema = readFileRequired($root . '/db/sursum_api_execution.df');
assertContains($schema, 'ADD TABLE "sursum_req_pasoe"', 'schema cria sursum_req_pasoe');
assertContains($schema, 'ADD TABLE "sursum_req_pasoe_evento"', 'schema cria sursum_req_pasoe_evento');
foreach ([
    '"id_execucao"',
    '"id_requisicao"',
    '"status_execucao"',
    '"tipo_execucao"',
    '"codigo_acao"',
    '"nome_programa"',
    '"id_tarefa"',
    '"data_hora_inicio"',
    '"dt_hr_ult_sinal"',
    '"data_hora_fim"',
    '"duracao_ms"',
    '"pid_pasoe"',
    '"agente_pasoe"',
    '"ref_trans_banco"',
    '"nome_usuario"',
    '"dt_hr_solic_interrupcao"',
    '"usuario_solic_interrupcao"',
    '"dados_retorno_json"',
    '"dados_envio_json"',
    '"id_sessao_requisitante"',
    '"navegador_requisitante"',
    '"ip_requisitante"',
] as $field) {
    assertContains($schema, $field, 'campo de schema ' . $field);
}

$repository = readFileRequired($root . '/sursum-api/sursum/ApiExecutionRepository.cls');
foreach ([
    'METHOD PUBLIC JsonObject startExecution',
    'METHOD PUBLIC JsonObject heartbeat',
    'METHOD PUBLIC JsonObject finishExecution',
    'METHOD PUBLIC JsonObject failExecution',
    'METHOD PUBLIC JsonObject requestKill',
    'METHOD PUBLIC JsonObject listExecutions',
    'METHOD PUBLIC JsonObject getExecution',
    'METHOD PUBLIC JsonObject listExecutionEvents',
    'METHOD PUBLIC JsonObject updateExecutionPayloads',
    'espec.sursum_req_pasoe',
    'espec.sursum_req_pasoe_evento',
    'poContext:getPasoePid()',
    'poContext:getPasoeAgent()',
    'setLongcharField(hExecution, "dados_retorno_json"',
    'setLongcharField(hExecution, "dados_envio_json"',
] as $needle) {
    assertContains($repository, $needle, 'repositorio contem ' . $needle);
}

$context = readFileRequired($root . '/sursum-api/sursum/PasoeExecutionContext.cls');
foreach ([
    'METHOD PUBLIC VOID setCurrentUser',
    'cCurrentUser = THIS-OBJECT:coalesce(pcUserName, cCurrentUser)',
] as $needle) {
    assertContains($context, $needle, 'contexto permite usuario informado: ' . $needle);
}

$handler = readFileRequired($root . '/sursum-api/rest/DynamicQueryWebHandler.cls');
foreach ([
    '*/executions/*/kill-request',
    '*/executions/*/cancel',
    '*/executions/*',
    '*/executions',
    'handleListExecutions',
    'handleGetExecution',
    'handleListExecutionEvents',
    'INDEX(cPath, "/events")',
    'handleKillRequest',
    'handleCancelExecution',
    'handleActionExecute',
    'ApiExecutionRepository',
    'startExecution',
    'finishExecution',
    'failExecution',
    'applyCallerUser',
    'X-Sursum-User',
    'JSESSIONID',
    'HTTP_X_FORWARDED_FOR',
    'HTTP_USER_AGENT',
    'getRequesterIp',
    'applyRequestMetadata',
] as $needle) {
    assertContains($handler, $needle, 'webhandler contem ' . $needle);
}

$jsonProgramHandler = readFileRequired($root . '/sursum-api/rest/JsonProgramWebHandler.cls');
foreach ([
    'ApiExecutionRepository',
    'PasoeExecutionContext',
    'startExecution',
    'finishExecution',
    'failExecution',
    'applyCallerUser',
    'X-Sursum-User',
    'JSESSIONID',
    'HTTP_X_FORWARDED_FOR',
    'HTTP_USER_AGENT',
    'getRequesterIp',
    'applyRequestMetadata',
    'JsonProgramRouter',
    'applyRequestMetadata',
    'updateExecutionPayloads',] as $needle) {
    assertContains($jsonProgramHandler, $needle, 'json program handler registra execucao: ' . $needle);
}

$jobDf = readFileRequired($root . '/db/sursum_async_queue.df');
assertContains($jobDf, '"executionId"', 'fila async contem executionId');

$jobRepo = readFileRequired($root . '/sursum-api/sursum/DynamicQueryJobRepository.cls');
assertContains($jobRepo, 'executionId', 'repositorio de job propaga executionId');

echo "PASOE execution log contract OK\n";

function readFileRequired(string $path): string
{
    $content = @file_get_contents($path);
    if ($content === false) {
        throw new RuntimeException('Arquivo obrigatorio nao encontrado: ' . $path);
    }
    return $content;
}

function assertContains(string $content, string $needle, string $label): void
{
    if (strpos($content, $needle) === false) {
        throw new RuntimeException($label . ': trecho nao encontrado: ' . $needle);
    }
}








