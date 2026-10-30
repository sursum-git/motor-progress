# Consumir consultas pelo domínio externo

Endpoint publicado: **POST https://iol.imatextil.com.br/query-progress/api/query.php**.

Para renovação sem troca manual de tokens, usar [autenticação automática por client_id/client_secret](AUTENTICACAO_AUTOMATICA_CONSUMIDORES.md): a rota `api/token.php` emite tokens de15minutos, consumidos no mesmo cabeçalho abaixo. Consumidores de token manual existentes continuam compatíveis até migração explícita na página.

Usar o token do consumidor gerado em [Consumidores e tokens](https://iol.imatextil.com.br/query-progress/index.html?page=query-consumers.html). O consumidor precisa ter permissão para o código da consulta. A chamada de integração não exige sessão LDAP ou cookies; o token é validado pelo PASOE a cada execução.

Ao criar ou rotacionar um token, a página também apresenta um exemplo **curl para Bash**, já preenchido com o novo token, esta URL externa e os quatro filtros da consulta de saldo. Use **Copiar curl** e ajuste os valores dos filtros antes do consumo. Fechar o diálogo limpa o token e o exemplo da tela; a permissão para a consulta deve ser escolhida no cadastro do consumidor.

## Saldo de estoque com os quatro filtros

```bash
curl --request POST \
  'https://iol.imatextil.com.br/query-progress/api/query.php' \
  --header 'Content-Type: application/json' \
  --header 'X-Sursum-Query-Token: SEU_TOKEN_GERADO' \
  --data '{
    "code": "saldo-estoque-por-referencia",
    "parameters": {
      "querystring": {
        "estabelecimento": "502",
        "deposito": "ARM",
        "item": "130062",
        "referencia": "004"
      }
    }
  }'
```

Substituir apenas `SEU_TOKEN_GERADO` pelo token privado da integração. Não colocar tokens na URL. Referência corresponde a `saldo.cod-refer`. Os quatro valores são texto para preservar zeros à esquerda; os filtros são opcionais e podem ser omitidos do objeto `parameters.querystring`.

O nome `querystring` acima pertence ao JSON do motor: não acrescentar esses parâmetros à URL externa. O corpo admite `code`, `parameters` e os campos opcionais `paginate`, `page` e `pageSize`, com os filtros declarados na definição salva. `page` começa em 1 (máximo 1.000.000) e `pageSize` aceita de 1 a 1.000 registros; valores omitidos preservam a configuração salva, com o teto por página. Para navegar, incremente `page` enquanto `hasMore` for verdadeiro, mantendo filtros e tamanho. `paginate: false` retorna o conjunto filtrado completo, com `pageSize: null` e `hasMore: false`; nesse modo o teto por página não se aplica, mas continuam os limites de tempo e tamanho da resposta. Veja os exemplos no [guia Swagger/Postman](DOCUMENTACAO_API_SWAGGER_POSTMAN.md). Não há credenciais de banco no cliente.

Também é possível enviar `paginationMode: "cursor"` e continuar com `nextCursor`, mantendo os filtros e `pageSize`. Não envie `page` nesse modo. Veja o [contrato de cursor](PAGINACAO_CURSOR_CONSULTAS.md), incluindo expiração, consultas compatíveis e reinício da navegação.

## Segurança e limites

O gateway possui destino fixo **sursum-api/MED/HTTPS9911**. Não recebe `target`, contexto, ambiente, SQL livre ou rota administrativa. Não usa a credencial administrativa interna do site: encaminha exclusivamente o token do consumidor no cabeçalho. O cliente acessa somente o HTTPS do domínio; a conexão até o PASOE ocorre pelo servidor web, com pin da chave pública TLS.

| Situação | HTTP |
| --- | --- |
| Token ausente, incorreto, expirado ou revogado | 401 |
| Consulta sem permissão para o consumidor | 403 |
| JSON inválido ou propriedades extras | 400 |
| Rota adicional, como `/query.php/consumers` | 404 |
| Método diferente de POST/OPTIONS | 405 |
| JSON maior que 64 KiB | 413 |
| Content-Type diferente de application/json | 415 |
| HTTP sem TLS | 426 |
| Falha de conexão, TLS ou resposta excedendo 16 MiB | 502/503 |
| Tempo de conexão/execução excedido | 504 |

OPTIONS retorna 204 sem executar dados. A execução tem timeout de120s, conexão de10s e não segue redirecionamentos. Respostas não são armazenadas em cache. O gateway não registra token, corpo ou resposta no registrador genérico de requisições. O PASOE mantém a auditoria existente com a identidade do consumidor.

A administração continua exigindo login LDAP de `tadeu.parreiras` e CSRF para alterações. O token de uma integração não permite acessar a página administrativa, salvar consultas ou usar o proxy interno sem login. Os demais PASOEs e o contexto IMA mantêm seu comportamento anterior.

## Validação da publicação — 27/10/2026

Passaram **33 verificações HTTP pelo domínio HTTPS** e **49 checks PHP no servidor publicado**, além de lint dos dois PHP e regressões locais do proxy/administração. A consulta retornou dados com os quatro filtros combinados e cada filtro isoladamente; item inexistente retornou vazio. Token inválido retornou401 e outro código não autorizado403, comprovando que o gateway não substitui a credencial do consumidor pela administrativa.

Também foram recusados SQL/definição livre, propriedades de override, caminhos administrativos, destino/IMA informados pelo cliente, métodos e content-type inválidos, JSON grande e HTTP com X-Forwarded-Proto forjado. Três endpoints administrativos mantiveram401 mesmo recebendo token de consumidor.

Nenhum fonte ABL, compilado, handler, configuração de servidor ou consumidor operacional foi alterado. Publicados somente `web/consumer-query-gateway.php` e `web/api/query.php`; a validação executou o PASOE real pela rota externa, sem recarga/reinício. Hashes dos arquivos protegidos do site, política dos consumidores e configurações de todos os PASOEs foram reconferidos. Recibos privados ignorados em `temp/public-consumer-query-20261027/{publication,verification,baseline}.json`. Não contêm tokens em texto aberto.

## Assíncrono —28/10/2026

A rota externa também aceita `execution:"async"`, exclusivamente no sursum/MED. Acompanhamento e download autenticados em `api/jobs.php` e `api/job-result.php`. Consulte o [guia assíncrono](consumer-async-api.md). Não use os endpoints administrativos para integração do consumidor.
# Webhooks por consulta

Uma aplicacao autenticada com `client_id` e `client_secret` pode manter um webhook diferente para cada consulta que estiver autorizada a executar. O token de 15 minutos obtido em `/api/token.php` identifica o consumidor; nao existe parametro para informar ou alterar o webhook de outro cliente.

Use `GET /api/webhook.php?code=saldo-estoque-por-referencia` para consultar o destino, `PUT /api/webhook.php` com `{"code":"saldo-estoque-por-referencia","url":"https://integracao.example.com/webhooks/estoque"}` para criar ou rotacionar, e `DELETE /api/webhook.php` com o `code` para remover. A resposta do `PUT` devolve `webhook_secret` uma unica vez. Guarde-o fora do codigo-fonte.

Quando um job assincrono concluir, o receptor recebera o JSON completo do resultado e os cabecalhos `X-Sursum-Webhook-Event: query.completed`, `X-Sursum-Webhook-Id`, `X-Sursum-Webhook-Timestamp` e `X-Sursum-Webhook-Signature`. A assinatura e `v1=` seguido de HMAC-SHA-256 de `timestamp.raw-body`, usando o segredo entregue no cadastro. O receptor deve deduplicar por `X-Sursum-Webhook-Id` e responder `2xx` somente depois de persistir o resultado. O polling por `jobId` continua disponivel como alternativa.

