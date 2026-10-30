# Saldo de estoque por referência

Consulta dinâmica salva: `saldo-estoque-por-referencia`.
Configuração: `sursum-api/querys/saldo-estoque-por-referencia.json`.

Usa `ems2med.saldo-estoq` e `ems2med.item`, com INNER JOIN por `it-codigo`, 17 campos na mesma ordem do SELECT solicitado, saldo atual maior que zero, grupos de estoque 50/60 e `saldo.lote = saldo.cod-refer`. Ordenação crescente por item e referência. Execução síncrona, página inicial 1, tamanho padrão de página 100. A API externa permite os campos opcionais `page` e `pageSize` (até 1.000 registros por página), ou `paginate: false` para retornar todo o conjunto filtrado, respeitando os limites operacionais. Veja [Swagger/Postman](DOCUMENTACAO_API_SWAGGER_POSTMAN.md).

## Filtros

Todos são opcionais, por igualdade, declarados em `externalFilters` com origem `querystring`:

| Parâmetro | Campo |
| --- | --- |
| estabelecimento | saldo.cod-estabel |
| deposito | saldo.cod-depos |
| item | saldo.it-codigo |
| referencia | saldo.cod-refer |

Omitir o parâmetro para não restringir pelo respectivo campo. Os valores são texto, preservando zeros à esquerda.

## Executar

De fora da rede interna, usar `POST https://iol.imatextil.com.br/query-progress/api/query.php` com `X-Sursum-Query-Token` e o mesmo JSON dos quatro filtros abaixo. Ver [consumo externo](CONSUMO_EXTERNO_CONSULTAS.md). Não requer login web para executar; o token deve autorizar esta consulta.

Para obter tokens automaticamente, usar [client_id/client_secret e renovação de15minutos](AUTENTICACAO_AUTOMATICA_CONSUMIDORES.md). O token obtido entra no mesmo cabeçalho; a consulta e os quatro filtros permanecem iguais. A página de tokens permite criar consumidores automáticos ou migrar explicitamente os manuais.

POST `https://192.168.0.111:9911/med/web/SursumDynamicQuery/query`

Desde 27/10/2026, esse endpoint em sursum-api/MED exige o cabeçalho `X-Sursum-Query-Token` de um consumidor autorizado. Ver [segurança e administração de consumidores](SEGURANCA_CONSULTAS_CONSUMIDORES.md). A interface web mantém o login e usa a credencial privada do proxy.

```json
{
  "code": "saldo-estoque-por-referencia",
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

Sem filtros: `{ "code": "saldo-estoque-por-referencia" }`.

## Compatibilidade e validação — 27/10/2026

O motor atual admite filtros planos unidos por AND e não oferece IN. Como os metadados reais confirmam `item.ge-codigo` INTEGER, a configuração representa IN (50,60) exatamente por `>= 50`, `<= 60` e exclusão dos inteiros 51 a 59. A comparação entre lote e referência usa uma segunda condição na lista `joins`, com ambos os lados no alias saldo; não adiciona outra fonte nem duplica registros.

Somente JSON foi adicionado; nenhum fonte ABL ou compilado foi alterado, portanto não há compilação de programas nesta entrega. Publicação feita pelo POST nativo `/query-store`, após confirmar que o código ainda não existia. O PASOE retornou sucesso e o caminho `sursum-api\querys\saldo-estoque-por-referencia.json`.

Validação real em sursum-api/med, HTTPS 9911: leitura inicial de 100 linhas, 17 campos, predicados fixos e ordenação; quatro filtros individualmente; combinação dos quatro; omissão de todos; item inexistente retornando zero; parâmetro não declarado rejeitado. O retorno existente do motor fornece números como texto localizado, tratado assim na conferência. Evidências locais em `temp/saldo-estoque-{publish-receipt,validation-summary}.json` e `temp/saldo-estoque-query-proof.json`; esses arquivos temporários não fazem parte da configuração distribuída.
