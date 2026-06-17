# Plano de adaptacao no outro servidor

Este documento resume o contexto e propoe um plano de implementacao para continuar o projeto em outro servidor, com foco em:

- uso de `IWebHandler`
- registro operacional das requisicoes em tabela
- escolha da rota/aplicacao conforme a empresa informada
- autenticacao para bloquear acesso anonimo

## 1. Premissas confirmadas

### 1.1 Modelo atual TOTVS encontrado

Pelos arquivos analisados no ambiente atual, o modelo TOTVS existente funciona assim:

- existe uma camada HTTP/REST no Tomcat Windows
- essa camada expoe rotas como `/dts/datasul-rest/...`
- ela chama o backend ABL via `APSV`
- no Linux existe uma instancia PASOE
- dependendo do cliente, pode haver:
  - uma unica aplicacao
  - ou uma aplicacao por empresa

### 1.2 Conclusao arquitetural adotada para este plano

Para este trabalho, partir do principio de:

- `1` instancia PASOE
- `1` aplicacao ABL por empresa
- cada aplicacao com seu proprio `.pf`
- cada aplicacao com seu proprio programa de alias
- cada aplicacao expondo endpoints proprios via camada `WEB` com `IWebHandler`

Isso evita:

- reconnect de banco a cada requisicao
- troca dinamica de alias na mesma sessao
- uma instancia PASOE completa por empresa

## 2. Objetivo da adaptacao

Implementar uma API propria, sem depender do formato atual do TOTVS REST, permitindo:

- chamar programas ABL por HTTP
- escolher a empresa por parametro
- registrar operacao e estado da requisicao em tabela
- autenticar o acesso

## 2.1 Diretriz obrigatoria de reaproveitamento

A adaptacao deve aproveitar ao maximo o que ja existe hoje no ambiente atual.

Isso significa:

- reaproveitar a topologia atual de `1` instancia PASOE
- reaproveitar a ideia de `1` aplicacao por empresa, quando ja existir
- reaproveitar os arquivos `.pf` existentes como base de configuracao
- reaproveitar os programas de alias existentes como base de configuracao
- reaproveitar usuarios e validacoes ja existentes no ERP quando isso fizer sentido
- reaproveitar o modelo atual de roteamento por empresa/aplicacao quando ele ja estiver estabelecido
- reaproveitar logs, nomes de contexto e convencoes operacionais que ja sao conhecidas pela equipe

Nao e objetivo deste plano substituir toda a arquitetura atual sem necessidade.

O objetivo e:

- manter o que ja funciona
- reduzir dependencia do formato atual do TOTVS REST apenas onde houver ganho real
- introduzir `IWebHandler`, log operacional e autenticacao propria de forma incremental

## 2.2 Regra de implantacao

Antes de criar novas aplicacoes, novos `.pf` ou novos programas de alias, verificar:

- se a aplicacao equivalente ja existe
- se o `.pf` equivalente ja existe
- se o alias equivalente ja existe
- se a empresa ja esta publicada em algum contexto atual

Sempre preferir:

- adaptar configuracoes existentes

em vez de:

- recriar tudo do zero

## 2.3 Convencao obrigatoria para arquivos JSON

Todos os arquivos JSON de configuracao deste projeto devem ficar dentro da pasta:

```text
conf-web-handler
```

Essa pasta deve ficar dentro de `sursum-api`, e a pasta pai de `sursum-api` deve estar no `PROPATH`.

### Regra pratica

O caminho `conf-web-handler` deve ser colocado explicitamente nas leituras de configuracao.

Ou seja:

- a pasta pai de `sursum-api` deve estar no `PROPATH`
- a aplicacao deve procurar os JSONs em `conf-web-handler`
- esse caminho nao deve ficar implicito nem depender de acaso do diretório corrente

### Objetivo

Padronizar a localizacao de:

- mapeamento de empresas/aplicacoes
- configuracao de autenticacao
- configuracao de JWT
- listas de usuarios locais
- qualquer outro JSON operacional do `IWebHandler`

### Exemplo conceitual

Se a pasta pai for:

```text
/dados/minhaapi
```

entao a estrutura esperada sera:

```text
/dados/minhaapi/conf-web-handler
```

E `/dados/minhaapi` deve estar no `PROPATH`.

### Consequencia para a implementacao

Todos os componentes que lerem JSON devem assumir essa convencao como padrao do projeto.

Nao espalhar arquivos JSON:

- em `temp`
- em `webapps`
- em diretorios aleatorios da instancia

Sempre centralizar em:

```text
conf-web-handler
```

## 2.4 Convencao obrigatoria para fontes ABL

Todos os programas `.p`, classes `.cls` e pastas auxiliares da API devem ficar dentro da pasta:

```text
sursum-api
```

Essa pasta deve ficar dentro de uma pasta que esteja no `PROPATH`.

### Regra pratica

O caminho `sursum-api` deve ficar explicito nas referencias dos fontes.

Ou seja:

- a pasta pai deve estar no `PROPATH`
- os programas `.p` devem ser chamados usando o prefixo `sursum-api/`
- classes `.cls` devem ficar fisicamente abaixo de `sursum-api`, mas com nomes/pacotes ABL validos
- configuracoes JSON devem ficar abaixo de `conf-web-handler`
- `sursum-api` e caminho de fonte, nao namespace OOABL, porque o nome contem hifen
- nenhuma chamada deve depender implicitamente do diretório corrente

### Exemplo conceitual

Se a pasta pai for:

```text
/dados/minhaapi
```

entao a estrutura esperada sera:

```text
/dados/minhaapi/sursum-api
```

E `/dados/minhaapi` deve estar no `PROPATH`.

### Consequencia para a implementacao

Sempre que um fonte chamar outro programa, instanciar classe ou publicar handler, a referencia deve deixar claro que o componente pertence a `sursum-api`.

Isso evita ambiguidade com:

- programas legados de mesmo nome
- fontes de outras aplicacoes no mesmo `PROPATH`
- diferencas de diretório corrente entre batch, APSV e WEB handler

### Exemplo de referencia explicita para `.p`

```abl
RUN VALUE("sursum-api/MinhaRotina.p") NO-ERROR.
```

### Observacao sobre `.cls`

Como `sursum-api` tem hifen, ele nao deve ser usado como pacote de classe.

As classes devem ter nomes/pacotes ABL validos, mas os processos de compilacao, publicacao e organizacao operacional devem apontar para o arquivo dentro de `sursum-api`.

## 3. Estrategia geral

### 3.1 Camada HTTP

Usar `IWebHandler`, portanto usar o adapter `WEB`, nao o `REST` classico.

Exemplo de URL esperada:

```text
/web/MinhaApi/execute
```

ou, se a empresa for refletida no contexto:

```text
/EmpresaA/web/MinhaApi/execute
/EmpresaB/web/MinhaApi/execute
```

### 3.2 Roteamento por empresa

O roteamento nao deve tentar:

- conectar/desconectar banco por request
- reconfigurar aliases da mesma sessao

O roteamento deve:

- receber `companyId` ou `empresa`
- mapear isso para uma aplicacao PASOE ja preparada
- encaminhar a execucao para a aplicacao correta

Sempre que possivel, esse mapeamento deve ser derivado da configuracao ja existente no ambiente atual, e nao reinventado manualmente.

## 4. Modelo de publicacao por empresa

### 4.1 Estrutura recomendada

Para cada empresa:

- um `.pf`
- um programa de alias
- uma aplicacao no `openedge.properties`

Observacao:

- isso vale para empresas que realmente exigem contexto tecnico proprio
- se uma empresa ja estiver publicada e funcional no ambiente atual, a base deve ser a configuracao existente dela

Exemplo conceitual:

```text
[AppServer]
applications=empresa01,empresa05
```

```text
[AppServer.Agent.empresa01]
sessionStartupProc=/dados/minhaapi/alias/empresa01-alias.r

[AppServer.SessMgr.empresa01]
agentStartupParam=-T "${catalina.base}/temp" -pf /dados/minhaapi/pf/empresa01.pf
```

```text
[AppServer.Agent.empresa05]
sessionStartupProc=/dados/minhaapi/alias/empresa05-alias.r

[AppServer.SessMgr.empresa05]
agentStartupParam=-T "${catalina.base}/temp" -pf /dados/minhaapi/pf/empresa05.pf
```

### 4.2 Como a rota deve ser escolhida

Existem dois modelos possiveis.

#### Modelo A: endpoint ja separado por empresa

Exemplo:

```text
/empresa01/web/MinhaApi/execute
/empresa05/web/MinhaApi/execute
```

Vantagens:

- mais simples
- menos logica de roteamento
- mais facil para operacao

Desvantagem:

- o cliente precisa saber qual URL chamar

#### Modelo B: endpoint unico com mapeamento por parametro

Exemplo:

```json
{
  "companyId": "05",
  "program": "meuPrograma.p",
  "params": {
  }
}
```

Nesse modelo, uma camada frontal faz:

- ler `companyId`
- consultar mapeamento
- redirecionar para a aplicacao certa

Vantagens:

- contrato unico para o cliente

Desvantagens:

- precisa de roteador
- aumenta a responsabilidade da camada frontal

### 4.3 Recomendacao

Se o objetivo for simplicidade de implantacao, usar primeiro o `Modelo A`.

Se depois houver necessidade de esconder as URLs por empresa, criar um gateway/roteador proprio.

## 5. Plano para log de requisicoes em tabela

### 5.1 Objetivo do log

Precisamos saber:

- se a requisicao ocorreu
- em que momento iniciou
- se terminou
- se ficou presa
- em qual empresa/aplicacao rodou
- qual programa executou
- qual agent/PID atendeu
- em qual banco/contexto rodou

### 5.2 Tabela principal sugerida

Sugestao de campos:

- `request_id`
- `company_id`
- `application_name`
- `endpoint`
- `program_name`
- `request_status`
- `started_at`
- `last_heartbeat_at`
- `finished_at`
- `duration_ms`
- `pasoe_pid`
- `pasoe_agent`
- `pasoe_instance`
- `database_name`
- `db_transaction_ref`
- `user_name`
- `auth_type`
- `request_summary`
- `error_message`

### 5.3 Status sugeridos

- `RECEBIDA`
- `AUTENTICANDO`
- `AUTENTICADA`
- `EM_EXECUCAO`
- `CONCLUIDA`
- `ERRO`
- `TIMEOUT`
- `ABANDONADA`

### 5.4 Heartbeat

Se houver programas longos, atualizar periodicamente:

- `last_heartbeat_at`
- opcionalmente um campo `current_step`

Com isso, fica facil detectar requisicoes paradas.

### 5.5 Correlacao com PID e contexto do PASOE

Ja existe ideia semelhante no projeto atual:

- capturar `PASOE_PID`
- capturar `APPSERVER_PID`
- capturar `PASOE_AGENT_NAME`
- capturar `PASOE_INSTANCE`
- capturar `LDBNAME(1)`

Observacao:

- `PID` do agent e contexto do runtime sao viaveis de capturar
- um `id exato da transacao do banco` nao deve ser assumido como algo nativo e trivial
- se for necessario correlacionar transacao, usar um `db_transaction_ref` proprio e/ou correlacao com logs/VSTs

### 5.6 Fluxo de log recomendado

#### Ao entrar no handler

- gerar `request_id`
- inserir registro com `RECEBIDA`

#### Antes da autenticacao

- atualizar para `AUTENTICANDO`

#### Apos autenticacao

- atualizar para `AUTENTICADA`

#### Antes de executar o programa

- atualizar para `EM_EXECUCAO`
- gravar:
  - `company_id`
  - `application_name`
  - `program_name`
  - `pasoe_pid`
  - `pasoe_agent`
  - `database_name`

#### Durante execucao longa

- atualizar heartbeat

#### No sucesso

- atualizar para `CONCLUIDA`
- gravar `finished_at`
- gravar `duration_ms`

#### Em erro

- atualizar para `ERRO`
- gravar `error_message`

### 5.7 Cuidado importante

Nao gravar o log de controle dentro da mesma transacao de negocio se houver risco de rollback remover o proprio log.

Opcoes:

- tabela de monitoramento em transacao separada
- base separada para monitoramento
- gravacao antes e depois dos blocos de negocio

## 6. Plano para autenticacao

### 6.1 Requisitos

Bloquear acesso sem autenticacao e suportar ao menos duas estrategias:

- autenticacao configurada em JSON
- autenticacao validando usuario cadastrado no ERP

Tambem avaliar JWT como opcao futura ou principal.

### 6.2 Opcao 1: autenticacao por JSON

Criar arquivo JSON local, por exemplo:

```json
{
  "users": [
    {
      "username": "apiuser",
      "passwordHash": "<hash>",
      "roles": ["admin"],
      "companies": ["01", "05"],
      "enabled": true
    }
  ]
}
```

#### Recomendacao

Nao armazenar senha em Base64 puro.

Usar:

- `salt`
- `sha-256` ou superior
- idealmente `bcrypt` ou algoritmo equivalente, se viavel na stack adotada

Observacao:

- Base64 nao e criptografia; e apenas codificacao

### 6.3 Opcao 2: autenticacao validando usuario no ERP

Criar um servico ABL para:

- receber usuario/senha
- validar contra usuario cadastrado no ERP
- respeitar regras do ambiente

Vantagens:

- reaproveita identidade ja existente
- evita usuario duplicado fora do ERP
- aproveita o cadastro ja consolidado no ambiente atual

Desvantagens:

- acopla a autenticacao ao ERP
- depende de conhecer e suportar a regra real de senha

### 6.4 Sobre o modelo atual TOTVS

Hoje o TOTVS usa algo equivalente a:

- `Basic Authentication`
- credencial enviada como `usuario:senha` em Base64
- e no backend ha validacao comparando com usuario do sistema
- a senha persistida tem combinacao de codificacao/hash propria do produto

Nao ha necessidade de reproduzir isso exatamente.

### 6.5 Opcao 3: JWT

JWT e uma boa opcao se quisermos:

- autenticar uma vez
- emitir token com expiração
- evitar envio de usuario/senha em todas as chamadas
- separar autenticacao de autorizacao

#### Modelo recomendado com JWT

1. endpoint de login
2. valida usuario por JSON ou ERP
3. emite JWT assinado
4. chamadas seguintes usam:

```text
Authorization: Bearer <token>
```

5. handler valida assinatura e expiração
6. handler verifica se o usuario pode acessar a empresa pedida

### 6.6 Recomendacao de autenticacao

#### Fase 1

Implementar duas fontes de autenticacao:

- `json`
- `erp`

Com uma configuracao do tipo:

```json
{
  "authMode": "json"
}
```

ou:

```json
{
  "authMode": "erp"
}
```

#### Fase 2

Adicionar JWT em cima dessas fontes:

- login valida no `json` ou `erp`
- token JWT passa a ser o meio padrao de acesso

### 6.7 Autorizacao por empresa

Independentemente da autenticacao, sempre validar:

- se o usuario pode acessar a empresa informada

Isso deve ser checado antes de executar o programa.

## 7. Estrutura de configuracao sugerida

### 7.1 Arquivo de empresas/aplicacoes

Exemplo:

```json
{
  "companies": {
    "01": {
      "application": "empresa01",
      "endpointPath": "/empresa01/web/MinhaApi",
      "serverAlias": "totvs-prd-1"
    },
    "05": {
      "application": "empresa05",
      "endpointPath": "/empresa05/web/MinhaApi",
      "serverAlias": "totvs-prd-5"
    }
  }
}
```

Local esperado:

```text
conf-web-handler/companies.json
```

### 7.2 Arquivo de autenticacao

Exemplo:

```json
{
  "authMode": "json",
  "jwt": {
    "enabled": true,
    "issuer": "minhaapi",
    "expirationMinutes": 60
  },
  "users": [
    {
      "username": "apiadmin",
      "passwordHash": "<hash>",
      "roles": ["admin"],
      "companies": ["01", "05"],
      "enabled": true
    }
  ]
}
```

Local esperado:

```text
conf-web-handler/authentication.json
```

## 8. Componentes recomendados

### 8.1 Handler HTTP

Responsabilidades:

- ler request
- validar autenticacao
- validar autorizacao da empresa
- gerar `request_id`
- abrir registro de controle
- chamar o programa/servico ABL
- montar resposta JSON

### 8.2 Servico de autenticacao

Responsabilidades:

- autenticar por JSON
- autenticar por ERP
- validar JWT
- emitir JWT

### 8.3 Servico de autorizacao

Responsabilidades:

- verificar se o usuario pode acessar a empresa
- verificar papeis/permissoes

### 8.4 Servico de monitoramento de requisicao

Responsabilidades:

- inserir registro inicial
- atualizar heartbeat
- marcar sucesso
- marcar erro

### 8.5 Servico executor

Responsabilidades:

- chamar programas ABL de negocio
- receber empresa e contexto
- devolver payload padronizado

### 8.6 Estrutura inicial de pastas no repositorio

A estrutura base da adaptacao deve existir assim:

```text
sursum-api/
conf-web-handler/
```

Uso:

- `sursum-api/`: raiz dos fontes da API `IWebHandler`
- `sursum-api/sursum/`: classes OOABL do motor e utilitarios
- `sursum-api/rest/`: handlers/fachadas WEB
- `sursum-api/workers/`: workers CLIENT/PASOE e programas APSV auxiliares
- `sursum-api/runners/`: executores genericos por arquivo JSON
- `conf-web-handler/`: JSONs de empresas, autenticacao, JWT e configuracoes operacionais

A pasta pai de `sursum-api` e `conf-web-handler` deve estar no `PROPATH`.

No ambiente atual do projeto, isso significa manter a raiz do projeto no `PROPATH`.

## 9. Ordem recomendada de implementacao

### Fase 1: base tecnica

1. inventariar o que ja existe hoje por empresa
2. identificar aplicacoes, `.pf` e aliases ja existentes
3. adaptar as aplicacoes existentes ou criar apenas as faltantes
4. habilitar adapter `WEB`
5. publicar handler simples de teste

### Fase 2: log operacional

1. criar tabela de controle
2. gravar `RECEBIDA`
3. gravar `EM_EXECUCAO`
4. gravar `CONCLUIDA` e `ERRO`
5. incluir `PID`, agent e banco

### Fase 3: autenticacao

1. implementar `authMode=json`
2. bloquear chamadas anonimas
3. implementar autorizacao por empresa
4. implementar `authMode=erp`

### Fase 4: JWT

1. criar endpoint de login
2. emitir token
3. validar token no handler
4. remover dependencia de Basic Auth como meio principal

### Fase 5: endurecimento operacional

1. heartbeat
2. timeout operacional
3. tabela de eventos opcionais
4. dashboards/consultas de requisicoes presas

## 10. Decisoes recomendadas

### 10.1 Decisao de camada

Usar `IWebHandler` com adapter `WEB`.

### 10.2 Decisao de topologia

Usar `1` instancia PASOE e `1` aplicacao por empresa.

Mas, antes de criar qualquer nova aplicacao, verificar se a empresa ja esta atendida por uma aplicacao existente no ambiente atual.

### 10.3 Decisao de seguranca

Implementar autenticacao configuravel:

- `json`
- `erp`

E adotar JWT como alvo preferencial.

### 10.4 Decisao de log

Gravar controle em tabela com status, timestamps, empresa, programa, PID e contexto.

## 11. Resultado esperado

Ao final, o ambiente deve permitir:

- chamar endpoint HTTP proprio
- autenticar usuario
- validar acesso por empresa
- encaminhar para a aplicacao certa
- executar programa ABL
- registrar toda a trilha operacional da requisicao
