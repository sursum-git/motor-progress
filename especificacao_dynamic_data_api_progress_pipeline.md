# Especificação para Codex — Dynamic Data API e Pipeline em Progress ABL

## Objetivo

Implementar uma primeira versão de uma **API dinâmica de consulta de dados em Progress OpenEdge ABL**, inicialmente para **uma única tabela por consulta**, usando metadados do próprio dicionário do Progress para montar:

- lista de tabelas disponíveis;
- metadados de campos;
- metadados de índices;
- configuração dinâmica de grid;
- configuração dinâmica de filtros;
- consulta paginada;
- retorno JSON;
- execução síncrona para consultas leves;
- estrutura inicial para execução assíncrona por `jobId`.

A solução deve evoluir futuramente para uma versão 2.0 com **pipeline configurável em árvore**, permitindo operações como `filter`, `select`, `map`, `distinct`, `group`, `aggregate`, `sort`, `limit` e `output`.

---

## Contexto técnico

O ambiente principal é **Progress OpenEdge ABL / Progress 4GL**.

Hoje já existe uma API que suporta a chamada de um programa único. A primeira versão deve aproveitar esse modelo, preferencialmente com um programa procedural persistente como fachada principal.

A solução deve ser compatível com um cenário onde existem **milhares de tabelas**, então não deve exigir cadastro manual de cada tabela/campo.

A primeira versão será usada por **usuário de TI**, não por usuário final comum. Portanto, pode trabalhar com nomes técnicos reais de tabelas/campos, mas precisa aplicar políticas globais de segurança, limite e auditoria.

---

## Princípios do projeto

1. Não cadastrar manualmente milhares de tabelas.
2. Ler metadados diretamente do dicionário do Progress.
3. Usar consulta dinâmica com `CREATE BUFFER`, `CREATE QUERY`, `QUERY-PREPARE`, `SET-BUFFERS`, `GET-FIRST`, `GET-NEXT`.
4. Executar somente leitura com `NO-LOCK`.
5. Nunca permitir alteração, criação ou exclusão de dados nesta fase.
6. Sempre aplicar paginação e limite máximo.
7. Validar se tabela e campos existem antes de consultar.
8. Bloquear tabelas/campos por políticas globais.
9. Retornar JSON tipado corretamente.
10. Registrar log de execução.
11. Preparar estrutura para consultas pesadas retornarem `jobId`.
12. Preparar a base para futura versão com pipeline em árvore.

---

## Escopo da versão 1.0

### Incluído

- Endpoint para listar tabelas.
- Endpoint para retornar metadados de uma tabela.
- Endpoint para executar consulta dinâmica em uma tabela.
- Suporte a filtros simples.
- Suporte a ordenação.
- Suporte a paginação.
- Suporte a seleção de campos.
- Retorno JSON.
- Políticas globais de bloqueio.
- Auditoria básica.
- Estrutura inicial de jobs assíncronos.

### Fora do escopo da versão 1.0

- Join entre tabelas.
- Includes de relacionamento.
- Pipeline completo.
- Edição de dados.
- Regras de negócio complexas.
- Usuário final comum.
- Interface visual completa.
- Permissão granular por consulta publicada.

---

## Arquitetura sugerida

```text
API existente
  ↓
api_dynamic_query.p persistente
  ↓
DynamicMetaService
  ↓
DynamicPolicyService
  ↓
DynamicQueryService
  ↓
DynamicJsonWriter
  ↓
DynamicJobService
```

### Programa principal

Criar ou adaptar um programa procedural persistente:

```text
api_dynamic_query.p
```

Responsabilidades:

- receber JSON da API;
- identificar a ação solicitada;
- chamar o serviço adequado;
- retornar JSON;
- registrar erros padronizados.

Procedures sugeridas:

```abl
PROCEDURE ListTables:
    DEFINE INPUT  PARAMETER pcRequestJson  AS LONGCHAR NO-UNDO.
    DEFINE OUTPUT PARAMETER pcResponseJson AS LONGCHAR NO-UNDO.
END PROCEDURE.

PROCEDURE GetTableMeta:
    DEFINE INPUT  PARAMETER pcRequestJson  AS LONGCHAR NO-UNDO.
    DEFINE OUTPUT PARAMETER pcResponseJson AS LONGCHAR NO-UNDO.
END PROCEDURE.

PROCEDURE ExecuteQuery:
    DEFINE INPUT  PARAMETER pcRequestJson  AS LONGCHAR NO-UNDO.
    DEFINE OUTPUT PARAMETER pcResponseJson AS LONGCHAR NO-UNDO.
END PROCEDURE.

PROCEDURE GetJobStatus:
    DEFINE INPUT  PARAMETER pcRequestJson  AS LONGCHAR NO-UNDO.
    DEFINE OUTPUT PARAMETER pcResponseJson AS LONGCHAR NO-UNDO.
END PROCEDURE.

PROCEDURE GetJobResult:
    DEFINE INPUT  PARAMETER pcRequestJson  AS LONGCHAR NO-UNDO.
    DEFINE OUTPUT PARAMETER pcResponseJson AS LONGCHAR NO-UNDO.
END PROCEDURE.
```

---

# Parte 1 — Metadados dinâmicos

## Endpoint: listar tabelas

### Entrada

```http
GET /api/dynamic/tables?search=emit
```

Ou, se a API atual trabalhar apenas por POST:

```json
{
  "action": "listTables",
  "search": "emit",
  "page": 1,
  "pageSize": 50
}
```

### Saída esperada

```json
{
  "success": true,
  "data": [
    {
      "name": "emitente",
      "dumpName": "emitente",
      "label": "Emitente",
      "description": "",
      "canQuery": true
    }
  ],
  "page": 1,
  "pageSize": 50,
  "hasMore": false
}
```

## Regras

- Listar apenas tabelas reais de aplicação.
- Bloquear tabelas internas do Progress, salvo se explicitamente liberadas.
- Aplicar filtro por nome, dump-name ou label.
- Aplicar paginação.
- Aplicar política global de bloqueio.

---

## Endpoint: metadados de uma tabela

### Entrada

```http
GET /api/dynamic/tables/emitente/meta
```

Ou:

```json
{
  "action": "getTableMeta",
  "table": "emitente"
}
```

### Saída esperada

```json
{
  "success": true,
  "table": {
    "name": "emitente",
    "dumpName": "emitente",
    "label": "Emitente",
    "canQuery": true
  },
  "fields": [
    {
      "name": "cod_emitente",
      "dumpName": "cod_emitente",
      "label": "Código",
      "dataType": "integer",
      "format": ">>>>>>9",
      "mandatory": true,
      "extent": 0,
      "indexed": true,
      "filterable": true,
      "sortable": true,
      "sensitive": false,
      "recommendedForGrid": true,
      "recommendedForFilter": true
    },
    {
      "name": "nome_emit",
      "dumpName": "nome_emit",
      "label": "Nome",
      "dataType": "character",
      "format": "x(60)",
      "mandatory": false,
      "extent": 0,
      "indexed": true,
      "filterable": true,
      "sortable": true,
      "sensitive": false,
      "recommendedForGrid": true,
      "recommendedForFilter": true
    }
  ],
  "indexes": [
    {
      "name": "idx_emitente",
      "unique": true,
      "primary": true,
      "fields": ["cod_emitente"]
    },
    {
      "name": "idx_nome",
      "unique": false,
      "primary": false,
      "fields": ["nome_emit"]
    }
  ],
  "grid": {
    "pageSize": 50,
    "maxPageSize": 500,
    "columns": ["cod_emitente", "nome_emit"]
  },
  "filterOperators": {
    "character": ["=", "begins", "contains"],
    "integer": ["=", ">", ">=", "<", "<="],
    "decimal": ["=", ">", ">=", "<", "<="],
    "date": ["=", ">", ">=", "<", "<="],
    "logical": ["="]
  }
}
```

---

## Metadados a ler do Progress

Usar o dicionário do Progress para obter:

- nome da tabela;
- dump-name da tabela, se disponível;
- label da tabela;
- descrição, se disponível;
- campos;
- tipo dos campos;
- formato;
- label;
- mandatory;
- extent;
- índices;
- campos dos índices;
- índice único;
- índice primário, se identificável.

Tabelas de dicionário normalmente envolvidas:

```text
_File
_Field
_Index
_Index-Field
```

A implementação deve verificar os nomes reais/campos disponíveis no ambiente antes de fechar o código, porque pode haver diferença de versão ou configuração.

---

# Parte 2 — Consulta dinâmica de uma tabela

## Endpoint: executar consulta

### Entrada

```json
{
  "action": "executeQuery",
  "table": "emitente",
  "fields": ["cod_emitente", "nome_emit", "cidade"],
  "filters": [
    {
      "field": "nome_emit",
      "operator": "begins",
      "value": "JOAO"
    }
  ],
  "orderBy": [
    {
      "field": "nome_emit",
      "direction": "asc"
    }
  ],
  "page": 1,
  "pageSize": 50,
  "execution": "auto"
}
```

### Saída síncrona

```json
{
  "success": true,
  "execution": "sync",
  "status": "completed",
  "page": 1,
  "pageSize": 50,
  "data": [
    {
      "cod_emitente": 10,
      "nome_emit": "JOAO DA SILVA",
      "cidade": "FORTALEZA"
    }
  ]
}
```

### Saída assíncrona

```json
{
  "success": true,
  "execution": "async",
  "status": "queued",
  "jobId": "JOB-20260603-000001"
}
```

---

## Regras de validação

Antes de executar:

1. Validar se a tabela existe.
2. Validar se a tabela não está bloqueada.
3. Validar se todos os campos existem.
4. Validar se campos solicitados não estão bloqueados.
5. Validar se filtros usam campos existentes.
6. Validar se operadores são permitidos para o tipo do campo.
7. Validar se ordenação usa campo existente.
8. Aplicar `pageSize` máximo global.
9. Aplicar `NO-LOCK` sempre.
10. Rejeitar qualquer tentativa de passar `WHERE` livre.
11. Rejeitar qualquer tentativa de passar trecho ABL livre.
12. Rejeitar qualquer campo com nome suspeito.
13. Registrar auditoria.

---

## Operadores suportados na versão 1.0

### Character

```text
=
<>
begins
contains
```

### Integer / Decimal

```text
=
<>
>
>=
<
<=
between
```

### Date / DateTime

```text
=
<>
>
>=
<
<=
between
```

### Logical

```text
=
```

---

## Como montar filtros

Não aceitar string livre de `WHERE`.

O JSON:

```json
{
  "field": "nome_emit",
  "operator": "begins",
  "value": "JOAO"
}
```

Deve virar internamente:

```abl
emitente.nome_emit BEGINS "JOAO"
```

O JSON:

```json
{
  "field": "cod_emitente",
  "operator": "=",
  "value": 10
}
```

Deve virar:

```abl
emitente.cod_emitente = 10
```

Os valores devem ser tratados conforme o tipo:

- character com aspas e escape;
- date convertido com segurança;
- decimal tratado com separador correto;
- logical convertido para `TRUE` ou `FALSE`;
- integer validado como número.

---

## Paginação

A primeira versão pode fazer paginação simples com descarte de registros até o offset.

Exemplo:

```text
page = 3
pageSize = 50
skip = 100
```

Para versão inicial, pode iterar até `skip` e começar a retornar depois.

Posteriormente, avaliar otimizações usando índices, `ROWID`, filtros obrigatórios ou chaves.

---

## Montagem da query dinâmica

Exemplo conceitual:

```abl
CREATE BUFFER hBuffer FOR TABLE cTable.
CREATE QUERY hQuery.

hQuery:SET-BUFFERS(hBuffer).

cQuery = "FOR EACH " + cTable + " NO-LOCK".

IF cWhere <> "" THEN
    cQuery = cQuery + " WHERE " + cWhere.

IF cOrderBy <> "" THEN
    cQuery = cQuery + " BY " + cOrderBy.

hQuery:QUERY-PREPARE(cQuery).
hQuery:QUERY-OPEN().
```

Ao iterar:

```abl
hQuery:GET-FIRST().

DO WHILE NOT hQuery:QUERY-OFF-END:
    /* montar JSON */
    hQuery:GET-NEXT().
END.
```

---

# Parte 3 — Políticas globais de segurança

Como existem milhares de tabelas, não usar cadastro por tabela na versão 1.0.

Criar configuração global.

## Configuração geral

Tabela sugerida:

```text
api_dynamic_config
- id
- default_page_size
- max_page_size
- max_sync_records
- allow_unindexed_filter
- allow_dictionary_tables
- force_async_without_filter
- force_async_unindexed_filter
- log_full_request
- active
```

## Regras de bloqueio

Tabela sugerida:

```text
api_block_rule
- id
- rule_type
- pattern
- reason
- active
```

Onde `rule_type` pode ser:

```text
table
field
```

Exemplos:

```text
table | _*          | Tabelas internas do Progress
field | *senha*     | Campo sensível
field | *password*  | Campo sensível
field | *token*     | Campo sensível
field | *secret*    | Campo sensível
field | *hash*      | Campo sensível
field | *api_key*   | Campo sensível
```

## Campos sensíveis

Quando campo for sensível:

- não retornar por padrão;
- marcar no metadado como `sensitive = true`;
- exigir permissão especial para retornar;
- opcionalmente mascarar.

Exemplo de retorno mascarado:

```json
{
  "cpf": "***.***.***-**"
}
```

Na primeira versão, pode simplesmente bloquear.

---

# Parte 4 — Jobs assíncronos

Consultas pesadas devem retornar um `jobId`.

## Quando usar async

Usar execução assíncrona quando:

- `execution = "async"`;
- tabela for muito grande;
- consulta vier sem filtro;
- filtro não usar índice e política exigir async;
- `pageSize` solicitado for alto;
- pipeline futuro possuir step pesado;
- exportação completa for solicitada.

## Tabela de job

Criar tabela:

```text
api_query_job
- job_id
- user_id
- status
- request_json
- request_hash
- result_location
- result_json
- result_file
- error_message
- created_at
- started_at
- finished_at
- expires_at
- total_records
- progress_percent
```

Status:

```text
queued
running
completed
failed
expired
cancelled
```

## Endpoint: status do job

Entrada:

```json
{
  "action": "getJobStatus",
  "jobId": "JOB-20260603-000001"
}
```

Saída:

```json
{
  "success": true,
  "jobId": "JOB-20260603-000001",
  "status": "running",
  "progress": 45
}
```

## Endpoint: resultado do job

Entrada:

```json
{
  "action": "getJobResult",
  "jobId": "JOB-20260603-000001"
}
```

Saída:

```json
{
  "success": true,
  "jobId": "JOB-20260603-000001",
  "status": "completed",
  "data": []
}
```

---

# Parte 5 — Auditoria

Registrar toda execução.

Tabela sugerida:

```text
api_dynamic_log
- id
- user_id
- action
- table_name
- request_json
- response_status
- error_message
- records_returned
- execution_mode
- job_id
- created_at
- elapsed_ms
```

Registrar:

- usuário;
- tabela consultada;
- campos solicitados;
- filtros;
- ordenação;
- quantidade de registros;
- tempo de execução;
- erro, se houver;
- se foi sync ou async.

---

# Parte 6 — Estrutura para versão 2.0: Pipeline em árvore

A versão 2.0 deve permitir construir pipelines por uma interface em árvore, não por diagrama livre estilo n8n.

## Motivo

Fluxos visuais livres ficam ruins quando crescem. A árvore é mais prática, mais fácil de editar, mais fácil de validar e mais adequada para consulta empresarial.

## Estrutura visual sugerida

```text
Pipeline: clientes_com_saldo
├── Fonte
│   └── Tabela: emitente
├── Campos
│   ├── cod_emitente
│   ├── nome_emit
│   └── cidade
├── Filtros
│   └── nome_emit BEGINS :nome
├── Transformações
│   └── Map: cliente_calcular_saldo
├── Reduções
│   └── Lista única por cidade
├── Ordenação
│   └── nome_emit ASC
└── Saída
    ├── Formato: JSON
    └── PageSize: 50
```

## Interface Kendo sugerida

Usar Kendo UI jQuery:

- `Kendo TreeView` para a árvore do pipeline;
- `Kendo Grid` para selecionar campos e preview dos dados;
- `Kendo Form` ou formulário customizado para editar propriedades;
- `Kendo Splitter` para layout;
- `Kendo TabStrip` para separar:
  - Metadados;
  - Pipeline;
  - JSON gerado;
  - Preview;
  - Logs.

---

# Parte 7 — Modelo JSON do pipeline futuro

Exemplo:

```json
{
  "name": "clientes_com_saldo",
  "source": {
    "type": "table",
    "table": "emitente",
    "fields": ["cod_emitente", "nome_emit", "cidade"]
  },
  "steps": [
    {
      "id": "filter_1",
      "type": "filter",
      "field": "nome_emit",
      "operator": "begins",
      "param": "nome"
    },
    {
      "id": "map_1",
      "type": "map",
      "name": "cliente_calcular_saldo"
    },
    {
      "id": "distinct_1",
      "type": "distinct",
      "fields": ["cidade"]
    },
    {
      "id": "sort_1",
      "type": "sort",
      "field": "cidade",
      "direction": "asc"
    }
  ],
  "output": {
    "type": "json",
    "pageSize": 50
  }
}
```

---

# Parte 8 — Funções de pipeline futuras

## `filter`

Filtra registros.

```json
{
  "type": "filter",
  "field": "cidade",
  "operator": "=",
  "value": "FORTALEZA"
}
```

## `select`

Seleciona campos.

```json
{
  "type": "select",
  "fields": ["cod_emitente", "nome_emit"]
}
```

## `map`

Transformação linha a linha.

Pode ser simples:

```json
{
  "type": "map",
  "operation": "uppercase",
  "field": "nome_emit",
  "as": "nome_maiusculo"
}
```

Ou customizada:

```json
{
  "type": "map",
  "name": "cliente_calcular_saldo"
}
```

O `map` customizado deve chamar programa/classe cadastrada internamente. O JSON nunca deve receber caminho físico de programa.

Correto:

```json
{
  "type": "map",
  "name": "cliente_calcular_saldo"
}
```

Errado:

```json
{
  "type": "map",
  "program": "/fontes/api/maps/cliente_saldo.p"
}
```

## `distinct`

Retorna lista única.

```json
{
  "type": "distinct",
  "fields": ["cidade"]
}
```

Ou:

```json
{
  "type": "distinct",
  "fields": ["cod_emitente", "cidade"]
}
```

## `group`

Agrupa registros.

```json
{
  "type": "group",
  "by": ["cod_emitente"]
}
```

## `aggregate`

Agrega valores.

```json
{
  "type": "aggregate",
  "groupBy": ["cod_emitente"],
  "calculations": [
    {
      "field": "valor_pedido",
      "function": "sum",
      "as": "total_pedidos"
    },
    {
      "field": "nr_pedido",
      "function": "count",
      "as": "qtde_pedidos"
    }
  ]
}
```

Funções suportadas futuramente:

```text
sum
count
countDistinct
avg
min
max
first
last
distinctList
concatList
```

## `sort`

Ordena resultado.

```json
{
  "type": "sort",
  "field": "nome_emit",
  "direction": "asc"
}
```

## `limit`

Limita registros.

```json
{
  "type": "limit",
  "count": 100
}
```

## `output`

Define saída.

```json
{
  "type": "output",
  "format": "json",
  "pageSize": 50
}
```

---

# Parte 9 — Diferença entre map e reduce

## Map

Transforma registro a registro.

Exemplo:

```text
cliente -> cliente com saldo_aberto
```

O número de registros normalmente permanece igual.

## Reduce / Aggregate / Distinct

Reduz vários registros em menos registros ou em um valor consolidado.

Exemplo:

```text
lista de pedidos -> total por cliente
lista de pedidos -> lista única de clientes
lista de cidades repetidas -> lista única de cidades
```

Na interface, evitar usar o termo técnico `reduce` para tudo. Preferir nomes claros:

```text
Lista única
Agrupar
Somar
Contar
Média
Mínimo
Máximo
Primeiro
Último
```

---

# Parte 10 — Implementação futura do distinct em Progress

Para `distinct`, usar preferencialmente temp-table auxiliar com índice único.

Exemplo conceitual:

```text
1. Criar temp-table dinâmica com os campos do distinct.
2. Criar índice único com estes campos.
3. Percorrer registros de entrada.
4. Tentar criar registro na temp-table de distinct.
5. Se já existir, ignorar.
6. Retornar temp-table final.
```

Alternativa simples:

```text
1. Concatenar campos em uma chave string.
2. Guardar chave em temp-table/hash auxiliar.
3. Ignorar duplicados.
```

A primeira abordagem é mais Progress raiz e mais segura com tipos.

---

# Parte 11 — Entregáveis esperados do Codex

Implementar nesta ordem:

## Etapa 1

- Criar estrutura do programa principal `api_dynamic_query.p`.
- Criar procedure `ListTables`.
- Ler tabelas do dicionário.
- Aplicar filtro de busca.
- Retornar JSON.

## Etapa 2

- Criar procedure `GetTableMeta`.
- Ler campos da tabela.
- Ler índices da tabela.
- Identificar campos indexados.
- Retornar JSON com metadados.

## Etapa 3

- Criar procedure `ExecuteQuery`.
- Validar tabela.
- Validar campos.
- Validar filtros.
- Montar query dinâmica.
- Executar com `NO-LOCK`.
- Aplicar paginação.
- Retornar JSON.

## Etapa 4

- Criar política global simples.
- Bloquear tabelas e campos por padrões.
- Criar função de identificação de campo sensível.
- Aplicar política nos metadados e na consulta.

## Etapa 5

- Criar auditoria.
- Registrar ações principais.
- Registrar erros.

## Etapa 6

- Criar estrutura inicial de job.
- Quando consulta for marcada como `async`, gravar job e retornar `jobId`.
- Criar procedures `GetJobStatus` e `GetJobResult`.
- A execução real em background pode ficar preparada para uma etapa posterior, caso o ambiente ainda não tenha worker.

## Etapa 7

- Criar documentação técnica.
- Criar exemplos JSON de entrada/saída.
- Criar testes manuais ou scripts de chamada.

---

# Parte 12 — Regras de qualidade

- Código deve ser modular.
- Não criar um programa gigante sem separação lógica.
- Comentar pontos de segurança.
- Tratar erro com retorno JSON padronizado.
- Nunca expor stack trace para o cliente.
- Não permitir `WHERE` livre.
- Não permitir ABL livre.
- Não permitir nome de programa vindo do JSON.
- Sempre validar tabela/campo contra o dicionário.
- Sempre usar `NO-LOCK`.
- Sempre aplicar limite de registros.
- Sempre registrar auditoria.

---

# Parte 13 — Formato padrão de erro

```json
{
  "success": false,
  "error": {
    "code": "INVALID_FIELD",
    "message": "Campo informado não existe ou não pode ser consultado.",
    "details": {
      "field": "senha_usuario"
    }
  }
}
```

Códigos sugeridos:

```text
INVALID_TABLE
BLOCKED_TABLE
INVALID_FIELD
BLOCKED_FIELD
INVALID_OPERATOR
INVALID_FILTER
PAGE_SIZE_EXCEEDED
QUERY_PREPARE_ERROR
QUERY_EXECUTION_ERROR
ASYNC_REQUIRED
JOB_NOT_FOUND
JOB_NOT_READY
INTERNAL_ERROR
```

---

# Parte 14 — Observações finais

A primeira versão deve ser tratada como um **Data Explorer técnico para Progress**, não como API pública final.

A evolução natural é separar dois modos:

```text
Modo Explorer/TI:
  dinâmico
  baseado no dicionário
  usado por TI
  sem cadastro por tabela

Modo Consulta Publicada:
  consulta cadastrada
  versionada
  permissionada
  usada por usuário final
  com parâmetros controlados
```

A versão 2.0 deve usar **árvore de pipeline**, não editor visual livre estilo n8n.

A árvore deve ser o editor principal. O JSON deve ser a representação interna. O grid deve servir para preview. O log deve servir para depuração.

