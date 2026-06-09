# Bootstrap para retomar o projeto em outro servidor

Este arquivo resume o minimo necessario para clonar o repositório e continuar o trabalho em outra instalacao do Codex.

## O que basta clonar

Depois de clonar o Git, o Codex conseguira recuperar o contexto principal a partir de:

- `.codex/context/project-state.md`
- `.codex/context/openedge-pasoe-operations.md`
- `.codex/context/api-contract-notes.md`
- `.codex/skills/sursum-openedge/SKILL.md`
- `docs/`
- `web/`

## O que precisa existir na nova maquina

- OpenEdge instalado
- binarios disponiveis em caminho equivalente ao configurado localmente
- PASOE disponivel
- acesso aos bancos locais necessarios para o seu fluxo
- runtime de navegador para abrir a UI web local

## O que nao e transportado pelo Git

- a instancia concreta de PASOE criada localmente
- bases de dados locais e seus arquivos fisicos
- `localStorage` do navegador com cliente/ambiente/empresa ja selecionados
- qualquer permissao especifica do Windows para temp/JNA

## Ordem recomendada de retomada

1. Clonar o repositorio.
2. Ler `.codex/context/project-state.md`.
3. Ler `.codex/context/openedge-pasoe-operations.md`.
4. Ajustar paths locais do novo servidor.
5. Recriar ou adaptar a instancia PASOE.
6. Confirmar os bancos realmente disponiveis no novo servidor.
7. Abrir `web/index.html`.
8. Configurar cliente/ambiente/empresa em `web/context-selector.html`.

## Ajustes locais que provavelmente serao necessarios

- trocar caminhos absolutos `D:\opencode\motor-progress` por caminhos locais equivalentes
- revisar `pasoe/sursum-pasoe-dev/conf/openedge.properties`
- revisar qualquer uso de `-1` nas conexoes de banco
- revisar `jvm.properties` e `catalinaopts.properties` para temp/JNA

## Bancos e papeis atuais

- `sports2000`: base menor e util para validacoes do motor
- `ems2cad`: base usada em partes da configuracao e metadata
- `ems2med`: base relevante para metadata e cargas `.d`
- `ems5`: base adicional conectada no PASOE local atual

## UI web: pontos principais

- `web/index.html` e a entrada principal
- `web/context-selector.html` define o contexto funcional
- o appbar do menu mostra `cliente / ambiente / empresa`
- paginas de consulta devem trabalhar principalmente com a selecao de empresa

## Observacao importante

Se o novo servidor tiver paths diferentes, o projeto continua retomavel, mas os comandos operacionais devem ser adaptados. O contexto do repositório foi escrito para preservar a arquitetura e o fluxo, nao para impor um unico caminho absoluto.
