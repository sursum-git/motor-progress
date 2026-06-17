# conf-web-handler

Pasta padrao para JSONs operacionais da API `IWebHandler`.

Regra operacional:

- a pasta pai de `sursum-api` deve estar no `PROPATH`;
- componentes ABL devem procurar configuracoes em `conf-web-handler`;
- nao gravar estes JSONs em `temp`, `webapps` ou diretorios da instancia PASOE;
- arquivos com segredos reais nao devem ser versionados sem revisao de seguranca.

Arquivos previstos:

- `companies.json`: mapeamento de empresas para aplicacoes/endpoints.
- `authentication.json`: modo de autenticacao, JWT e usuarios locais quando aplicavel.
