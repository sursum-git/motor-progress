# Estado Git e remoto

Atualizado em 2026-07-27.

## Repositorio remoto

Remote configurado:

```text
origin https://github.com/sursum-git/motor-progress.git
```

## Decisao de historico

O `master` remoto existente tinha historico independente do repositorio local. A comparacao mostrou que nao havia base comum entre `origin/master` e `master` local.

O estado local foi tratado como a versao canonica porque contem:

- estrutura atual `sursum-api/`;
- middleware PHP em `web/`;
- persistencia SQLite em `sursum-conf/` e `web/sursum-conf/`;
- testes de contrato em `tests/e2e/`;
- script de deploy `scripts/deploy_query_progress_192_168_0_39.sh`;
- exemplos `container-client.html` e `saved-query-client.html`;
- consulta salva `sursum-api/querys/pp-it-container-por-container.json`.

Por decisao operacional, o `master` remoto deve ser substituido pelo estado local usando push forcado controlado:

```bash
git push --force-with-lease origin master
```

## Credenciais

Esta maquina tinha `credential.helper=store` configurado globalmente. Para evitar uso de credencial antiga, comandos de push podem precisar desabilitar o helper na execucao:

```bash
git -c credential.helper= push --force-with-lease origin master
```

Tokens GitHub nao devem ser gravados em arquivos do projeto nem no remote URL.
