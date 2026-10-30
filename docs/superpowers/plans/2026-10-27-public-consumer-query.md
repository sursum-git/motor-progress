# Public Consumer Query Implementation Plan

> Executar inline com superpowers:executing-plans; revisão independente final conforme requesting-code-review.

**Goal:** permitir execução externa de consultas autorizadas com token, somente sursum-api/MED/9911.
**Architecture:** gateway PHP fixo com validação estrita e TLS pin; autorização permanece no PASOE. Endpoint api/query.php separado dos proxies administrativos e do login humano.
**Tech Stack:** PHP/cURL/JSON; PASOE existente sem alteração ABL.
**Spec:** ../specs/2026-10-27-public-consumer-query-design.md (pedido direto aprovado pelo usuário).

## Restrições

- Preservar dirty tree, consumidores operacionais e políticas dos outros contextos/instâncias.
- Não usar a credencial administrativa do proxy no consumo externo; não encaminhar headers arbitrários, querystring, destinos ou caminhos do cliente.
- Não persistir tokens/senhas em arquivos, logs, recibos ou URLs. Segredos apenas memória/entrada oculta.
- Publicação somente dos PHP pertinentes no servidor web .39; PHP lint/testes substituem compilação ABL pois nenhum ABL será alterado. Validar o PASOE real via domínio.

## Tarefas

- [x] 1. Testes RED: HTTPS/trusted proxy, método/caminho/querystring, token exato, JSON e campos/limites. Implementar web/consumer-query-gateway.php e web/api/query.php; GREEN e PHP lint.
- [x] 2. Revisão independente do gateway: ausência de credencial de serviço, destino fixo, sem redirects/header passthrough/logs, limite de resposta e falhas TLS. Corrigir achados.
- [x] 3. Preflight com hashes e ausência de colisão de rota; publicar dois PHP por staging/rename, preservar arquivos existentes. Validar HTTPS público e POST com token real/quatro filtros, negativos de token/permissão/admin/override/rota. Confirmar nenhuma alteração ABL/handlers/política/instâncias e nenhum token nos logs.
- [x] 4. Documentar URL/curl externo/contrato e evidências; atualizar contexto, reconferir hashes e encerrar conexões de teste.

## Review focus

Troca acidental de token pelo serviço admin; destino/rota arbitrário; vazamento de token/headers ou erro de transporte; autoridade por cookie/HTTPS forjado; respostas parciais/redirects em falha; alteração de outros PASOEs.

Final GREEN:49checksPHP locais e nohelper efetivamente publicado;33verificacoesHTTPnodominioHTTPS (certificadovalidado), incluindo quatro filtroscombinados/isolados,401/403,admin401,override/metodos/caminhos eHTTPSforjado426. Revisaoindependente semP1/P2;2arquivosPHPporhash,nenhuma alteracao deABL/consumidores/handlers/outrosPASOEs/arquivosadministrativos. PHP lint pertinente concluido,semcompilacaoABL ourecarga poisABLinalterado. Recibos temp/public-consumer-query-20261027/{publication,verification,baseline}.json.
