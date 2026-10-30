# Reposição contínua do worker paralelo

## Intenção

Reduzir o tempo ocioso entre lotes da exportação paralela de `movimentacoes-estoque`, mantendo um limite noturno de oito partições ou diurno de quatro no PASOE Sursum/MED. O ganho vem de repor a fila no mesmo ciclo do worker local, sem abrir workers ou endpoints públicos adicionais.

## Decisão aprovada

- A definição JSON declara uma grade de concorrência no fuso `America/Sao_Paulo`: das 20:00 (inclusivo) até 05:00 (exclusivo), `maxWorkers: 8`; no restante do dia, `maxWorkers: 4`.
- A grade é resolvida uma única vez ao enfileirar. O limite resolvido é gravado no plano e no metadado do job; uma execução iniciada à noite conserva oito workers após 05:00.
- O worker privado no gateway executa rodadas limitadas de dreno: enquanto houver trabalho, inicia a próxima rodada no mesmo ciclo; quando uma rodada não processa item algum, encerra normalmente.
- O PASOE continua sendo a única autoridade para leases e aplica `maxWorkers`; o PHP não escolhe job, data ou partição.

## Limites e não objetivos

- Cada execução do worker terá um teto fixo de rodadas para não monopolizar o processo local, mesmo com fila longa.
- Não serão expostos endpoints de worker nem haverá mudança fora de Sursum/MED.
- O job já criado conserva o snapshot de `maxWorkers: 2`. Aumentar um job existente exigiria uma migração explícita do plano e fica fora desta alteração; novos jobs recebem quatro ou oito conforme o horário do enfileiramento.

## Verificação

- Teste de lógica do worker: uma rodada vazia encerra; rodadas com trabalho continuam apenas até o teto.
- Validação PHP local e publicação privada no gateway.
- Enfileirar execuções curtas com relógio controlado e confirmar no plano MED os snapshots de 4 e 8 workers, sem exceder cada teto, consolidação e download.
- Atualizar Swagger/Postman para indicar a grade e que o valor é capturado no enfileiramento.
