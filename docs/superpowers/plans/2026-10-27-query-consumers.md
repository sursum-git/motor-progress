# Query consumers — Implementation Plan

**Goal:** restringir consumo externo a consultas salvas autorizadas por token.
**Architecture:** política ABL pura e wrapper seguro do handler atual; hashes em JSON operacional protegido; proxy PHP com credencial fora da raiz web; CLI de ciclo de vida.
**Tech Stack:** OpenEdge 12.2, PHP, Node.js.
**Spec:** ../specs/2026-10-27-query-consumers-design.md

## Restrições
- Checkout v2; preservar alterações existentes e não criar outro checkout sem necessidade.
- Sem DDL, token em Git, concessão humana ou modificação de SursumPrograms.
- Apenas sursum-api/med, HTTPS9911; compilação oficial .42/OE12.2.
- Configuração inválida nega acesso; nenhum fallback anônimo.

## Tarefas
- [x] 1. Testes ABL da política: matriz de autenticação/autorização, expiração/revogação, configuração inválida, payload/rota, comparação exata. Executar RED sem classe e GREEN com implementação.
- [x] 2. Criar DynamicQueryConsumerPolicy.cls e SecuredDynamicQueryWebHandler.cls; delegado somente após autenticação. Verificar wrapper sem token e consumidor administrativo negado antes da execução.
- [x] 3. CLI Node: provisionar/revogar/rotacionar, hashes apenas, escrita atômica e arquivo privado. Testes reais com diretório temporário.
- [x] 4. Proxy PHP: token server-side somente para sursum-api/MED/9911 DynamicQuery; manter login e destino permitido; teste de leitura do segredo/negação/configuração inválida sem credencial real.
- [x] 5. Revisão independente, testes locais e compilação/suítes 12.2. Corrigir achados antes de ativar.
- [x] 6. Deploy guardado: comparar fontes runtime, preservar baseline, instalar configuração/proxy/classes, mudar registro MED por último, recarregar somente MED ocioso. Smoke de consumidor/admin/negações no PASOE, retirar consumidor de teste, conferir UI e hashes.
- [x] 7. Documentar o uso, administração e evidências reais; não declarar validação oficial se bloqueada por acesso.

## Foco da revisão
- Desvio por rota semelhante, case, querystring, body com sources/override, ou OPTIONS com execução.
- Configuração inválida/parcial, hashes/ids duplicados e credenciais expiradas/inativas.
- Segredo em URL, logs, arquivos públicos, código, recibos ou erro.
- Proxy enviando token para destino indevido ou retirando a autenticação humana.
- Ativação sem token da interface, registros antigos bypassando wrapper, ou troca em outra instância.

## Resultado final

Concluído no alvo autorizado: compilador 12.2.12.0, seis entradas sem erro, 52 checks ABL em cada uma das quatro combinações de encoding/formato; cinco testes CLI, 21 verificações PASOE e 16 checks PHP no servidor publicado. Leitura pelo proxy completo e pin incorreto bloqueado antes HTTP. Nenhuma política registrada nas outras instâncias; IMA preservado. Consumidores efêmeros removidos e configuração restaurada por hash. Revisão independente encerrada sem achados pendentes. Uso e operação em docs/SEGURANCA_CONSULTAS_CONSUMIDORES.md.
