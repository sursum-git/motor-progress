# Roadmap - Consultas Salvas e Execucao Controlada

## Contexto

Este arquivo registra itens planejados para consultas salvas por codigo, execucao controlada por client e evolucoes assíncronas. Ele existe para manter o roadmap no contexto do projeto, nao apenas no historico de uma sessao.

## Implementacao imediata

- Armazenar consultas salvas por codigo em arquivos JSON.
- Usar `sursum-conf/query-store.json` como configuracao do store quando disponivel.
- Usar `sursum-api/querys` como pasta padrao dos arquivos `<codigo>.json`.
- Validar `code` aceitando somente letras, numeros, `_`, `-` e `.`.
- Criar `POST /web/SursumDynamicQuery/query-store` para salvar consultas com `code`, `status` e `query`.
- Permitir `status` inicial `draft` ou `ready`.
- Manter `POST /web/SursumDynamicQuery/query` aceitando consulta completa no body.
- Permitir `POST /web/SursumDynamicQuery/query` com `{ "code": "...", "parameters": { ... } }` para executar consulta salva.
- Adicionar no query builder a configuracao opcional `externalFilters`.
- Aplicar apenas parametros externos declarados em `externalFilters` quando a consulta for executada por codigo.
- Rejeitar parametros externos nao declarados.
- Rejeitar filtros externos obrigatorios ausentes.
- Consultas salvas sem `externalFilters` nao devem aceitar parametros externos adicionais.

## Contrato planejado de filtros externos

```json
{
  "externalFilters": [
    {
      "name": "pedido",
      "source": "querystring",
      "sourceAlias": "ped",
      "field": "nr-pedido",
      "operator": "=",
      "required": false
    },
    {
      "name": "estabelecimento",
      "source": "header",
      "sourceAlias": "ped",
      "field": "cod-estabel",
      "operator": "=",
      "required": true
    }
  ]
}
```

Origens previstas na primeira versao:

- `querystring`
- `header`
- `body`

## Seguranca por client e permissoes

Criar posteriormente tabelas Progress via `.df` para:

- cadastro de clients;
- tokens;
- IPs permitidos, aceitando `*`;
- endpoints permitidos;
- permissao para executar consulta completa;
- permissao para salvar consulta;
- permissao para executar consultas salvas especificas.

Criar controle de acesso por status da consulta:

- `draft`: consulta em andamento, liberada para teste conforme ambiente;
- `ready`: consulta pronta para execucao controlada.

Adicionar em `sursum-conf` configuracao dos ambientes que podem executar consultas `draft`.

## Webhook para jobs e workers

Para consultas executadas por workers ou em modo assíncrono, permitir que o client informe uma configuracao de webhook no momento da execucao por codigo ou, posteriormente, no cadastro/permissao do client.

Objetivos:

- Registrar no job a URL de callback do client.
- Notificar o client ao fim do processamento.
- Enviar informacoes adicionais sobre o ciclo do job, incluindo:
  - codigo da consulta salva;
  - identificador do job;
  - status final;
  - data/hora de inicio;
  - data/hora de fim;
  - duracao;
  - quantidade de registros, quando disponivel;
  - caminho ou identificador do resultado, quando aplicavel;
  - conteudo do resultado da consulta, quando disponivel e permitido pela politica de tamanho/seguranca;
  - erro tecnico, quando houver;
  - mensagem de negocio, quando houver.
- Prever tentativas de reenvio em caso de falha no webhook.
- Registrar historico das tentativas de callback.
- Proteger o webhook com assinatura ou token por client.
- Permitir configurar quais eventos disparam callback, por exemplo `completed`, `failed` e `cancelled`.

Exemplo futuro de payload de execucao:

```json
{
  "code": "pedidos-em-aberto",
  "parameters": {
    "querystring": {
      "pedido": "12345"
    }
  },
  "webhook": {
    "url": "https://cliente.example.com/sursum/callback",
    "events": ["completed", "failed"],
    "tokenRef": "client-default"
  }
}
```

Exemplo futuro de callback:

```json
{
  "code": "pedidos-em-aberto",
  "jobId": "...",
  "status": "completed",
  "startedAt": "2026-06-11T10:00:00-03:00",
  "finishedAt": "2026-06-11T10:01:12-03:00",
  "durationMs": 72000,
  "records": 150,
  "result": {
    "delivery": "file",
    "path": "output/jobs/...json",
    "data": [
      {"codigo": 12345, "status": "aberto"}
    ]
  },
  "error": null
}
```

## Backlog - auditoria de transacoes e notificacao

Reformular o registro de execucoes para ter uma auditoria propria de transacoes da API, independente do modo `sync` ou `async`.

Situacao atual:

- O modo `async` registra estado em `SursumQueryJob` e historico em `SursumQueryJobEvent`.
- O PID do worker pode ser registrado em `lockedByPid`.
- O contexto do PASOE pode incluir `requestId`, `pasoePid`, agente, host e usuario.
- A execucao `sync` nao possui tabela propria de transacao/auditoria.
- O campo `dbTransactionId` existe no contexto, mas ainda nao e preenchido por uma rotina real de correlacao transacional.

Melhoria planejada:

- Criar uma tabela de execucao/transacao unica para toda chamada relevante do backend, incluindo consultas comuns, consultas salvas, jobs async e workers.
- Registrar `executionId` ou `transactionId` proprio da API, sem assumir que exista um identificador nativo da transacao Progress.
- Registrar `requestId`, client, ambiente, empresa, endpoint, usuario, host, agente PASOE, PID, modo de execucao, inicio, fim, duracao, status e erro.
- Separar o log de auditoria da transacao de negocio, para evitar que um rollback remova o proprio registro de controle.
- Reformular a notificacao por webhook para usar essa tabela de execucao como fonte unica do estado enviado ao client.
- Registrar as tentativas de webhook em tabela propria, com status, payload resumido, erro, data/hora, proxima tentativa e quantidade de tentativas.
- Permitir que a mesma estrutura atenda notificacoes de `queued`, `running`, `completed`, `failed`, `cancelled` e eventos futuros.
- Expor endpoint de consulta de situacao baseado no mesmo contrato enviado ao webhook.

Resultado esperado:

- Toda execucao tera rastreabilidade mesmo quando for sincrona.
- O client podera receber webhook ou consultar o estado por endpoint com o mesmo payload.
- Erros de worker, schema ausente, falha de webhook e falha de consulta ficarao auditaveis.
- O PID passara a ser uma informacao de contexto da execucao, nao apenas um campo especifico da fila async.


## Endpoint de situacao de execucao

Criar um endpoint PASOE para que o client possa consultar a situacao de uma execucao quando o webhook nao for suficiente ou quando o caso de uso exigir polling/controladoria propria.

Objetivos:

- Permitir consulta por `jobId`.
- Retornar exatamente o mesmo contrato previsto para o webhook.
- Incluir dados de inicio, fim, duracao, status, erro e resultado.
- Incluir o conteudo do resultado da consulta quando disponivel e permitido.
- Aplicar as mesmas regras futuras de permissao por client, token, IP e consulta salva especifica.
- Permitir que o client recupere o estado final mesmo se o callback webhook falhar.

Endpoint sugerido:

```http
GET /web/SursumDynamicQuery/executions/{jobId}
```

Resposta sugerida: mesmo payload do callback webhook.

## Fora do escopo imediato

- Criar os `.df` de client/permissoes.
- Implementar autenticacao/autorizacao por token.
- Implementar callback webhook nos workers.
- Implementar endpoint PASOE de situacao da execucao com o mesmo retorno do webhook.
- Implementar politicas de retry e assinatura de callback.
- Implementar auditoria unica de execucoes/transacoes da API para modos `sync`, `async` e workers.
- Persistir tentativas de notificacao webhook e seus erros.
- Restringir `draft` por ambiente.

## Validacao planejada

- Salvar consulta com `code`, `status` e `externalFilters`.
- Verificar criacao de `sursum-api/querys/<code>.json`.
- Executar consulta por `code` sem parametros.
- Executar consulta por `code` com parametro permitido por `querystring`.
- Executar consulta por `code` com parametro permitido por `header`.
- Rejeitar parametro nao declarado em `externalFilters`.
- Rejeitar filtro obrigatorio ausente.
- Confirmar que consulta completa enviada no body continua funcionando.
- Compilar e validar no servidor `192.168.0.42`, pois o ambiente local pode nao ter compilador Progress.
