<?php
declare(strict_types=1);

$root = dirname(__DIR__, 2);

$schema = readFileRequired($root . '/db/sursum_api_execution.df');
assertContains($schema, 'ADD TABLE "SursumApiExecution"', 'schema cria SursumApiExecution');
assertContains($schema, 'ADD TABLE "SursumApiExecutionEvent"', 'schema cria SursumApiExecutionEvent');
foreach ([
    '"executionId"',
    '"requestId"',
    '"executionStatus"',
    '"executionType"',
    '"actionCode"',
    '"programName"',
    '"jobId"',
    '"startedAt"',
    '"lastHeartbeatAt"',
    '"finishedAt"',
    '"durationMs"',
    '"pasoePid"',
    '"pasoeAgent"',
    '"dbTransactionRef"',
    '"killRequestedAt"',
    '"killRequestedBy"',
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
    'SursumApiExecution',
    'SursumApiExecutionEvent',
    'poContext:getPasoePid()',
    'poContext:getPasoeAgent()',
] as $needle) {
    assertContains($repository, $needle, 'repositorio contem ' . $needle);
}

$handler = readFileRequired($root . '/sursum-api/rest/DynamicQueryWebHandler.cls');
foreach ([
    '*/executions/*/kill-request',
    '*/executions/*/cancel',
    '*/executions/*',
    '*/executions',
    'handleListExecutions',
    'handleGetExecution',
    'handleKillRequest',
    'handleCancelExecution',
    'handleActionExecute',
    'ApiExecutionRepository',
    'startExecution',
    'finishExecution',
    'failExecution',
] as $needle) {
    assertContains($handler, $needle, 'webhandler contem ' . $needle);
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
