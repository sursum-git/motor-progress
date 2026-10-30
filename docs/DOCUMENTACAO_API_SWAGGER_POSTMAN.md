# Consultas Sursum/MED — Swagger e Postman

Acesse a [documentação interativa](https://iol.imatextil.com.br/query-progress/query-api-docs.html) ou o menu **Consultas → Documentação da API (Swagger)**. O catálogo exige o login atual da ferramenta e é gerado das consultas salvas a cada abertura. A documentação não altera permissões.

Na seção **Autenticar consumidor**, informe `client_id` e `client_secret` gerados na página de tokens e clique em **Obter token**. O token tem validade de 900 segundos; a página solicita outro ao executar uma consulta após 870 segundos. Credenciais permanecem em memória enquanto a página estiver aberta. **Limpar credenciais e resultados** apaga a autenticação e o retorno visível. Também é possível colar um token existente em **Authorize**, sem prefixo `Bearer`; nesse caso a renovação é manual.

Expanda **POST /api/query.php**, clique em **Try it out**, escolha a consulta em **Examples**, altere os filtros no JSON e clique em **Execute**. **Server response** mostra status HTTP e corpo JSON retornado pelo PASOE. Todas as consultas usam essa mesma rota, diferenciadas pelo campo `code`; `parameters.querystring` continua dentro do JSON, apesar do nome. Preserve valores como referência `004` como texto.

As seis consultas atuais são:

| Código | Filtros |
| --- | --- |
| `controle-preco-por-pedido-container` | `nr_container` obrigatório |
| `moeda-precos-atuais-por-container` | `nr_container` obrigatório; `dt_referencia` opcional |
| `pp-container-por-container` | `nr-container` obrigatório |
| `pp-it-container-por-container` | `nr-container` obrigatório |
| `saldo-estoque-por-referencia` | `estabelecimento`, `deposito`, `item`, `referencia` opcionais; referência é `cod-refer` |
| `tabelas-preco-por-container` | `nr_container` obrigatório |

Nos exemplos de container, substitua `INFORME_O_CONTAINER` por um valor real. Os schemas descrevem os filtros e listam os campos de saída de cada consulta. O retorno real é exibido durante a execução.

## Importar no Postman

Baixe a [coleção Postman](https://iol.imatextil.com.br/query-progress/query-api-docs.php?format=postman&download=1) após o login, ou importe o arquivo `docs/api/sursum-med-postman.collection.json`. O [OpenAPI JSON](https://iol.imatextil.com.br/query-progress/query-api-docs.php?format=openapi&download=1) também pode ser importado. Os downloads da página refletem o catálogo publicado; os arquivos do repositório são uma cópia das seis consultas na data desta entrega.

1. No Postman, use **Import** e selecione a coleção.
2. Configure `client_id` e `client_secret` em um ambiente local, com valores privados. Selecione esse ambiente.
3. Abra uma requisição da pasta **Consultas**, ajuste **Body** e clique em **Send**.

A pasta solicita o token automaticamente, mantém um cache local de 870 segundos e o renova antes do vencimento. **Autenticação → Obter token** permite emissão explícita e substitui o cache após a rotação de segredo. Falha na emissão impede o envio da consulta. Os destinos são URLs literais no domínio externo; não existe seleção de outro PASOE. O token fica nas variáveis locais da coleção do Postman durante o uso. Não compartilhe exportações com segredos ou tokens preenchidos; os arquivos fornecidos vêm com esses campos vazios.

Execução usa exclusivamente `X-Sursum-Query-Token` do consumidor e os gateways públicos fixos de sursum-api/MED/9911. Um token sem permissão para o `code` recebe 403. Token vencido/revogado recebe 401. A administração de consumidores continua restrita a `tadeu.parreiras`, com login e CSRF. Esta entrega não altera ABL, handlers, configurações ou outros PASOEs.

Swagger UI 5.34.0 é servido localmente, com licença Apache-2.0 em `web/vendor/swagger-ui/LICENSE`, sem CDN nem validador externo. Os contratos são gerados por `web/query-api-docs-lib.php`, sem SQL, nomes de bancos, hashes ou credenciais administrativas.


## Paginação e resposta completa

A API externa aceita os parâmetros opcionais na raiz do JSON:

```json
{
  "code": "saldo-estoque-por-referencia",
  "paginate": true,
  "page": 2,
  "pageSize": 250,
  "parameters": {
    "querystring": {
      "estabelecimento": "502",
      "deposito": "ARM",
      "item": "130062",
      "referencia": "004"
    }
  }
}
```

`page` aceita inteiros de1a1000000; `pageSize` de1a1000. Texto, valores fracionários, booleanos e nulos são recusados nesses campos. Números JSON integrais como1.0 são normalizados. Omitidos, mantêm os valores efetivos da consulta salva, com o tamanho limitado a1000. A validação aplica-se a todos os clientes da API externa e também aos consumidores no PASOE sursum/MED. Erros de paginação retornam400; permissões porconsulta continuam vigentes.

Enquanto `hasMore` for verdadeiro, incremente `page` mantendo `pageSize` e os filtros. `recordsReturned` informa a quantidade retornada. A paginação usa deslocamento `(page-1)*pageSize`; não retorna total e não mantém snapshot. Mudanças nos dados e empates na ordenação podem deslocar registros entre chamadas. Processamentos posteriores como distinct/group continuam após a seleção da página, conforme o motor existente; não use apenas recordsReturned para decidir se terminou.

Para retornar todo o conjunto filtrado, informe **`"paginate": false`**. `page` e `pageSize` deixam de controlar a seleção; se enviados, ainda precisam ser valores válidos. O retorno contém `paginate:false`, `page:1`, `pageSize:null`, `recordsReturned` e `hasMore:false`. O limite de1000 é porpágina e não se aplica ao modo completo. Esse modo executa sincronicamente e mantém o processamento posterior da consulta. Permanecem os limites operacionais do gateway:120segundos e16MiB de resposta. Se ultrapassados, a chamada falha; não há promessa de conjunto completo acima desses limites.

Os exemplos por página no Swagger e Postman trazem paginate:true/page1/pageSize100. Os novos exemplos com sufixo cursor usam paginationMode:cursor, sem page. A pasta Consultas por cursor do Postman salva a continuação automaticamente. Consulte o [guia de cursor](PAGINACAO_CURSOR_CONSULTAS.md). Baixe e importe novamente a coleção para receber esta versão.

## Processamento assíncrono externo

Envie `execution:"async"` no POST de consulta para receber202/jobId. Acompanhe em `api/jobs.php?jobId=...` e baixe em `api/job-result.php?jobId=...`, sempre com token do mesmo consumidor e permissão atual. Swagger e Postman incluem os três passos; a pasta assíncrona captura job_id. Veja o [guia completo](consumer-async-api.md) para exemplos, limites e estados. Somente sursum/MED; administração preservada.
# Webhooks

O Swagger e a colecao Postman incluem a pasta/tag **Webhooks** com consultar, cadastrar/rotacionar e remover o destino da propria aplicacao para cada consulta autorizada. A colecao reutiliza a renovacao automatica de token e nunca exporta credenciais ou o segredo de assinatura preenchidos.

