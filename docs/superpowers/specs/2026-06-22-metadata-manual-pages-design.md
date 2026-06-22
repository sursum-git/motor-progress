# Separacao das manutencoes manuais de metadados

## Objetivo

Separar a atualizacao em lote, o cadastro manual de view-as e o cadastro manual de joins em paginas distintas. A pagina `metadata-maintenance.html` deve ficar focada na fila e execucao em lote. As manutencoes manuais devem ser acessadas por entradas proprias no menu.

## Paginas

- `metadata-maintenance.html`: apenas atualizacao em lote, filtros de empresa/banco/tabela, criacao e execucao da fila.
- `view-as-maintenance.html`: grid de view-as manual, inclusao, alteracao, exclusao e importacao CSV.
- `relation-maintenance.html`: grid de joins manuais, inclusao, alteracao e exclusao.

## Navegacao

O arquivo `web/menu-pages.json` deve trocar a descricao da pagina de metadados para atualizacao em lote e adicionar entradas separadas para view-as manual e join manual. As novas paginas devem carregar dentro do `index.html` como as demais paginas do sistema.

## Comportamento

As novas paginas devem manter o mesmo contexto de empresa, banco e tabela usado hoje. A tabela continua opcional para listar todos os registros do recurso manual; quando informada, filtra o grid e preenche o formulario de inclusao.

View-as manual continua salvo no SQLite por `tabela + campo`, sem depender de banco/empresa. Join manual continua salvo pelo contrato atual de `relation-store.php`, preservando `source = manual`.

## Interface

Cada pagina deve ter header, filtros, toolbar e grid proprios, sem abas. Inclusao e alteracao continuam em janela modal Kendo. Exclusao fica na linha do grid.

## Reaproveitamento

A primeira implementacao pode reutilizar as funcoes existentes de `metadata-maintenance.js`, desde que o codigo fique condicionado aos elementos presentes na pagina. Depois, se o arquivo ficar dificil de manter, a separacao fisica dos JS pode ser feita em um refactor posterior.

## Verificacao

Validar sintaxe JavaScript com `node --check` e verificar por Playwright/curl que:

- a pagina de lote nao mostra mais as abas manuais;
- as novas paginas abrem pelo menu;
- os botoes principais sao renderizados;
- grids e janelas Kendo inicializam sem erro de JavaScript.
