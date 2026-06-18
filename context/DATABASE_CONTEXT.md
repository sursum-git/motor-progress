# Contexto dos Bancos e SQLite

Atualizado em 2026-06-18.

## Bancos Progress conhecidos

Ambiente historico local:

```text
D:\opencode\motor-progress\db
```

Host de compilacao atual:

```text
C:\opencode\motor-progress\db
```

Bancos relevantes:

- `sports2000`: validacao do motor e exemplos.
- `ems2med`: metadados reais, tabelas como `acordo`, `emitente`, `ped-venda`, `ped-item`.
- `ems2cad`: citado em configuracoes historicas.
- `ems5`: citado em configuracoes historicas.

No endpoint atual, a empresa e resolvida pelo path:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
```

## Identidade de tabela

Para consulta e joins:

```text
banco + tabela
```

Exemplos:

```text
ems2med.ped-venda
ems2med.acordo
sports2000.Customer
```

Para view-as manual/CSV:

```text
tabela + campo
```

View-as nao usa banco nem empresa na chave porque os bancos equivalentes por empresa devem compartilhar as mesmas opcoes.

## Observacoes de metadados Progress

- `ems2med` possui muitas tabelas e campos.
- Busca de campos deve filtrar por `_File-Recid`; varrer `_Field` inteiro pode travar a tela.
- Tabelas e campos podem conter hifen:

```text
ped-venda
ped-item
nome-abrev
cod-sit-ped
vl-tot-ped
```

- Relacoes `OF` podem ser demoradas e devem ser executadas por tabela ou por fila de lote.
- Tabela `emitente` tem muitas relacoes OF; retorno vazio indica problema a investigar.

## SQLite principal da UI

Arquivo:

```text
web/sursum-conf/sursum.sqlite
```

Tambem existe copia historica fora de `web`:

```text
sursum-conf/sursum.sqlite
```

O fluxo web atual usa `web/sursum-conf/sursum.sqlite`.

## Tabelas de contexto

Criadas por:

```text
web/context-store.php
```

Tabelas:

```text
config_meta
clients
environments
client_environment_links
companies
physical_databases
aliases
```

`environments` contem:

```text
id
name
pasoe_base_url
auth_mode
authorization
company_id_mode
extra_query_params
servidor
usuario
senha
arquivo_pf
arquivo_alias
```

`companies` contem:

```text
id
client_id
environment_id
name
code
path_param
```

## Tabelas de view-as e lote

Criadas por:

```text
web/metadata-store.php
```

Tabelas:

```text
field_view_as
metadata_sync_jobs
metadata_sync_items
```

`field_view_as`:

- chave canonica: `table_name + field_name`;
- `environment_id`, `company_id` e `database_name` ficam vazios no modelo canonico;
- fontes possiveis: `manual`, `CSV`, `PASOE`.

CSV de importacao:

```text
tabela,campo,lista de opcoes
```

Tambem aceita variacoes de cabecalho como `view_as`, `viewas`, `view-as`, `opcoes`.

## Tabelas de joins

Criadas por:

```text
web/relation-store.php
```

Tabela:

```text
table_relations
```

Chave:

```text
environment_id
company_id
database_name
left_database
left_table
left_field
right_database
right_table
right_field
```

Regra:

- `source=manual` preserva cadastro manual.
- Ao gravar relacoes automaticas (`OF`), o store nao deve sobrescrever relacao manual equivalente.

## Arquivos JSON historicos

Ainda podem existir arquivos em:

```text
web/sursum-conf/context.json
sursum-conf/context.json
sursum-conf/query-store.json
conf/metadata/*.json
```

Eles sao referencia, fallback ou migracao. O fluxo de manutencao de contexto, joins e view-as esta em SQLite.
