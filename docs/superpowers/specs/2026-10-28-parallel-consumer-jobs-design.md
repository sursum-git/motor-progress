# Jobs paralelos por consulta — sursum/MED

## Objetivo

Permitir que poucas consultas salvas, explicitamente habilitadas no seu JSON, executem exportações assíncronas grandes em partições independentes. A própria consulta declara como dividir o trabalho: por dias, cliente, código fiscal ou outra chave indexada aprovada. O job mestre mantém até dez partições ativas e agenda a próxima conforme uma termina.

Nenhuma consulta passa a executar em paralelo por padrão. O comportamento atual de `execution: "async"`, polling por `jobId`, download e webhook permanece igual para consultas sem essa configuração.

## Configuração da consulta

Cada definição elegível terá um bloco `asyncParallel`, validado no servidor e jamais aceito do corpo externo. A estratégia de quebra pertence ao JSON da consulta, não ao motor e nem ao request do consumidor:

```json
{
  "asyncParallel": {
    "enabled": true,
    "partition": {
      "strategy": "date-day",
      "source": "querystring",
      "startParameter": "dataInicial",
      "endParameter": "dataFinal",
      "indexedField": "ped-venda.dt-implant",
      "filterField": "ped-venda.dt-implant"
    },
    "maxWorkers": 10,
    "maxPartitions": 2000,
    "maxPartitionRecords": 100000,
    "maxPartitionBytes": 268435456,
    "maxResultBytes": 10737418240,
    "mergeOrder": ["data", "pedido", "item"]
  }
}
```

`maxPartitionRecords` impede que um único intervalo indexado materialize dados sem limite na memória do agente; `maxPartitionBytes` limita o JSON temporário da partição; `maxResultBytes` limita o NDJSON consolidado. Os três são definidos somente no JSON salvo. Atingir um teto falha o job com causa sanitizada e jamais gera download parcial.

O motor aceita estratégias fechadas e configuradas no JSON:

- `date-day`: gera uma partição por dia entre dois parâmetros declarados;
- `value-list`: uma partição por valor informado por um parâmetro de lista, por exemplo cliente ou código fiscal;
- `range`: faixas numéricas ou alfanuméricas consecutivas, definidas por limites e tamanho de faixa no JSON.

Cada estratégia informa `indexedField`, `filterField`, os parâmetros externos de entrada e regras de normalização do valor. O motor só aceita a configuração quando os parâmetros e a chave existem na definição, o campo está explicitamente marcado como indexado para aquela consulta e a ordenação final é determinística. O consumidor pede apenas `execution: "async"`; ele não escolhe quantidade de workers, campo, chave, SQL ou faixas internas.

## Execução

1. O job mestre valida permissão, materializa a definição e usa a estratégia declarada no JSON para gerar as partições.
2. O registro privado guarda o plano, estado de cada partição, tentativas, contagem e arquivos de resultado. No máximo `maxWorkers` partições ficam em execução.
3. Cada worker executa uma partição com os filtros fixados pelo plano interno. Uma falha recuperável é tratada por partição; uma falha definitiva encerra o job mestre sem publicar resultado parcial.
4. Ao terminar todas as partições, o processo de consolidação percorre os arquivos na `mergeOrder` e produz uma exportação única NDJSON compactada (`.ndjson.gz`) por streaming, sem carregar o conjunto inteiro na memória. Só então marca o job mestre como `completed`.
5. O webhook existente é disparado uma vez, apenas para o resultado consolidado do job mestre. Não há callback por dia salvo se uma evolução futura criar evento separado.

## Limites e formato

- Limite máximo inicial: 10 workers, 2.000 partições e a retenção atual de 24 horas.
- A exportação paralela não usa o limite de 64 MiB do JSON de consulta comum. Ela usa uma cota de armazenamento configurada, inicialmente 10 GiB por exportação, retenção de 24 horas e transmissão em streaming.
- O download por `jobId` informa o formato e transmite o arquivo `.ndjson.gz` sem materializá-lo na memória do PASOE ou do proxy.

## Modo de entrega do webhook

O corpo da requisição assíncrona pode conter `webhookDelivery`, restrito a `full` ou `manifest`; a omissão usa `manifest` para exportações paralelas e preserva `full` para o resultado JSON comum.

- `full`: o worker envia o arquivo completo como corpo da requisição, com `Content-Type: application/x-ndjson`, `Content-Encoding: gzip` e a mesma assinatura HMAC sobre os bytes compactados. É indicado somente quando o receptor aceita arquivos grandes e timeouts longos.
- `manifest`: o worker envia um JSON assinado pequeno com `jobId`, formato, tamanho, SHA-256, contagem de registros e `resultUrl`. O receptor usa seu próprio `client_id`/`client_secret` para obter token e baixar o arquivo por `jobId`; a URL não contém credencial nem capacidade secreta.

Os dois modos preservam as retentativas e a deduplicação por `X-Sursum-Webhook-Id`. O consumidor escolhe o modo por job, mas não pode alterar URL, chaves de quebra, cota, número de workers ou filtros internos.

## Segurança e consistência

- A configuração só pode ser criada por administrador junto da definição da consulta; não vem do consumidor nem do Swagger.
- A seleção por dia, cliente, código fiscal ou faixa usa somente parâmetros declarados e um campo indexado configurado. Não usa ROWID nem concatenação de filtros/SQL.
- A consolidação usa ordenação estável declarada pela consulta. Como os dados podem mudar durante uma exportação longa, ela não é snapshot transacional; essa condição aparece na documentação.
- Permissão do consumidor é revalidada antes de cada partição e da disponibilização final. Revogação encerra o job.

## API e documentação

O request mantém `execution: "async"` e pode acrescentar `webhookDelivery: "full" | "manifest"`. A resposta de status acrescenta, para jobs paralelos, `parallel: { enabled, totalPartitions, completedPartitions, runningPartitions, failedPartitions }` e `resultFormat`. Swagger e Postman mostram esses campos e um exemplo de consulta habilitada, quando ela for criada. As consultas atuais continuam aparecendo sem a opção.

## Aceite

Uma consulta marcada explicitamente como paralela usa a estratégia de quebra declarada no seu JSON, respeita o teto de dez workers, consolida em ordem determinística, entrega somente o resultado final por `jobId` e webhook, e recusa definições sem índice/parâmetros/ordenação válidos. Consultas não habilitadas preservam o processamento assíncrono atual.
