# Consumer client credentials implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Execução autorizada pelo pedido do usuário; implementação nesta sessão, revisão independente final.

**Goal:** obter automaticamente tokens de900segundos por client_id/client_secret, preservando autorização por consulta no MED.
**Architecture:** registro estável de consumidores com hash de segredo opcional; novo emissor ABL com store opaco separado e validação pela política atual; gateway PHP fixo e UI de gestão existente.
**Tech Stack:** OOABL OpenEdge12.2, PHP8.4, JavaScript/Kendo, Playwright.
**Spec:** docs/superpowers/specs/2026-10-27-consumer-client-credentials.md

## Global Constraints

- Somente sursum-api/MED/9911. Administração somente tadeu.parreiras/LDAP/CSRF.
- Tokens900segundos; permissões e revogação consultadas em cada execução; sem secrets em logs/recibos.
- Preservar consumidores legados e alterações concorrentes; sem commits/push solicitados.

## Review Focus

- Segredo nunca aceito como token nem como credencial administrativa.
- Revogação, expiração da autorização e rotação bloqueiam tokens já emitidos.
- Emissões concorrentes não perdem tokens nem alteram revision administrativa.
- Limites, store inválido e escrita falha devem negar acesso; erros de credencial uniformes.
- Rotas genéricas nunca registram segredo; domínio externo não aceita alvo/contexto/escopo arbitrário.

## Tasks

- [x] ABL RED/GREEN: tests/abl/query-consumers/ClientCredentialsTests.p; nova DynamicQueryClientCredentials.cls issue/authorize, extensão limitada de Policy/Registry e wrapper. Testar900s/fronteira, revogação/rotação/permissões/segredo inválido/admin/concurrency/limites/compatibilidade. Compilar e testar oficialmente12.2, quatro combinações de encoding/cultura.
- [x] PHP RED/GREEN: tests/security/consumer-token-gateway.test.php, web/consumer-token-gateway.php e web/api/token.php, administração create-client/credentials com hash exclusivamente. Transportar somente dados estritos para MED; bloquear token route no proxy genérico antes de logs. Regressões PHP/CLI e lint.
- [x] UI: criar cliente por padrão, migrar legados explicitamente, rotacionar segredo e limpar diálogo; exemplo Bash de obter token/consumir consulta. Browser testa gestão completa, exemplos e limpeza.
- [x] Publicação: preflight/backup/hash somente artefatos alterados, sem alterar registro do wrapper/demais instâncias; recarregar apenas MED ocioso. Validar token via domínio, consultas quatro filtros, obtenção automática de outro token e vencimento real900s; negativas401/403/admin/rotas/taxa. Limpar fixture sem tocar consumidores operacionais.
- [x] Revisão independente, documentação e contexto com recibos sem segredos; finalizar só após evidência real.

Ruling operacional: CIFS força0755. Store final em discoLinuxlocal configurado por accessTokenStore obrigatório, parent0700/store0640, semfallback. Final oficial129checks porcombinação,32UI/9migração, teste904sreal+revalidaçãoSDK apósrelocação; final-verification.json confirma limpeza e integridade. Ver documentação operacional para detalhes.
