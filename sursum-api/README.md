# sursum-api

Pasta raiz dos fontes ABL da API `IWebHandler`.

Regra operacional:

- a pasta pai deste diretorio deve estar no `PROPATH`;
- chamadas de programas devem referenciar explicitamente `sursum-api/`;
- publicacoes de handlers e rotinas da API devem deixar claro que o fonte vem daqui;
- as pastas `sursum/`, `rest/`, `workers/` e `runners/` ficam abaixo desta pasta;
- JSONs operacionais ficam na pasta irma `conf-web-handler`;
- nao depender do diretorio corrente do processo PASOE, APSV ou batch.

Exemplo para programa `.p`:

```abl
RUN VALUE("sursum-api/MinhaRotina.p") NO-ERROR.
```

Observacao sobre classes `.cls`:

`sursum-api` e um caminho de organizacao de fonte, nao um namespace OOABL. Como o nome contem hifen, ele nao deve ser usado como pacote de classe. Classes devem manter nomes/pacotes ABL validos, e a publicacao/compilacao deve apontar explicitamente para o fonte dentro de `sursum-api`.
