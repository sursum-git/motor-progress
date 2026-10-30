# Paginação por cursor — sursum/MED

A API externa aceita `paginationMode: "cursor"` nas consultas de linhas com chave única. O token do consumidor e sua permissão para o código são verificados em cada chamada.

Envie para `POST https://iol.imatextil.com.br/query-progress/api/query.php`, com `Content-Type: application/json` e `X-Sursum-Query-Token: SEU_TOKEN`:

```json
{
  "code": "saldo-estoque-por-referencia",
  "paginationMode": "cursor",
  "pageSize": 100,
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

Enquanto `hasMore` for verdadeiro, repita o corpo acrescentando `"cursor": "VALOR_DE_nextCursor"`. Mantenha código, filtros e `pageSize`. Ao terminar, `nextCursor` será nulo. `page` retorna nulo nesse modo; não envie `page` nem `paginate:false`. Tamanho permitido: 1 a 1.000 registros.

Cada cursor vence em 900 segundos. Um novo access token emitido com as mesmas credenciais pode continuar a navegação. Mudanças de consumidor, segredo, filtros, tamanho ou definição invalidam a continuação. Ao receber `CURSOR_EXPIRED` ou `CURSOR_INVALID` (HTTP400), reinicie sem cursor. Permissão revogada continua retornando HTTP403.

O motor preserva a ordenação e acrescenta as chaves únicas de todas as tabelas para desempatar. A próxima consulta aplica uma comparação lexicográfica no WHERE, sem ROWID, sem sessão aberta entre chamadas e sem descartar páginas anteriores. A eficiência depende dos índices e do plano de execução. Os dados são lidos a cada chamada: alterações durante a navegação podem mover registros.

As cinco consultas do catálogo web sem transformação possuem exemplos no Swagger e na pasta **Consultas por cursor** do Postman. A execução exige que a definição esteja publicada no motor e possua chave única válida. Na inspeção de 27/10/2026, `moeda-precos-atuais-por-container` e `pp-container-por-container` estavam no catálogo web, mas suas definições não estavam publicadas no armazenamento efetivo do PASOE; a concessão de permissão retornou `QUERY_NOT_FOUND`. Esta entrega não publica definições de negócio ausentes.

`tabelas-preco-por-container`, que usa `distinct`, permanece com paginação por página ou `paginate:false`; cursor retorna `CURSOR_UNSUPPORTED`. Novas consultas devem possuir chave única e operações compatíveis.

A definição publicada de `pp-it-container-por-container` também retornou `CURSOR_UNSUPPORTED`: não foi possível validar uma definição e uma chave compatíveis no runtime atual. Use os modos anteriores até revisar essa compatibilidade; a entrega não cria índices nem usa fallback por ROWID.

No Postman, repetir **Send** avança pela variável `cursor_<codigo>`. Ao terminar, ela recebe `__END__` e bloqueia novo envio; limpe a variável para reiniciar ou mudar filtros/consumidor. No Swagger, copie manualmente `nextCursor` para o campo `cursor` do próximo corpo.

Os modos anteriores continuam disponíveis: `page`/`pageSize` e `paginate:false`. A ativação é exclusiva do handler seguro no sursum/MED/9911. A assinatura usa HMAC-SHA256 com chave privada dedicada no servidor, fora da raiz pública.
