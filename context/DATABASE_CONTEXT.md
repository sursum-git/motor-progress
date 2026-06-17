# Contexto dos Bancos

## Bancos locais

Diretorio:

```text
D:\opencode\motor-progress\db
```

## sports2000

Banco:

```text
D:\opencode\motor-progress\db\sports2000
```

Nome logico no PASOE:

```text
DICTDB
```

Nome exibido pela API:

```text
sports2000
```

Uso:

- Validacao inicial do motor.
- Exemplos com `Customer`, `Order`, `Customer` + `Order`.
- Benchmarks de paginacao e contagem.

## ems2med

Banco:

```text
D:\opencode\motor-progress\db\ems2med
```

Nome logico no PASOE:

```text
ems2med
```

Criado a partir de:

```text
D:\opencode\motor-progress\ems2med.df
```

Areas exigidas pelo DF:

```text
dados
indices
```

Arquivo de areas:

```text
db/ems2med_areas.st
```

Validacao apos carga:

```text
tables=4147 sequences=253
```

## Observacoes sobre metadados

- `ems2med` possui muitas tabelas e campos.
- Busca de campos deve filtrar por `_File-Recid`; varrer `_Field` inteiro pode deixar a tela travada.
- Tabelas e campos do Progress podem conter hifen, exemplo:

```text
ped-venda
ped-item
nome-abrev
cod-sit-ped
vl-tot-ped
```

## Identidade de tabela

Como bancos diferentes podem ter tabelas com o mesmo nome, a identidade correta e:

```text
banco + tabela
```

Exemplo:

```text
ems2med.ped-venda
sports2000.Customer
```
