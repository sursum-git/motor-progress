# Fronteira pública de manutenção e comandos ABL

Fontes preparados em16/10/2026. Esta entrega não afirma publicação: a compilação12.2 e a validação PASOE são conduzidas pela tarefa principal. Nenhum registro de negócio nem sequência real foi usado no diagnóstico local.

## Programas públicos e dependências

- `ContainersCabecalhoCrud.p`: recurso `containers`; delega CRUD ao serviço existente, com regras/exclusão/fiscal separados.
- `ContainersDespesasCrud.p`: recurso exato `container-despesas`; delega CRUD, batch_update e batch_delete ao serviço existente. Não habilita batch_create nem defaults.
- `ContainersProcessos.p`: somente os três comandos da tabela abaixo. Nenhuma abertura/get/read grava ou inicia processo.

Os wrappers verificam `X-Containers-Token` pelo SHA256 da configuração privada existente e exigem `X-Sursum-User` junto ao contexto real `PasoeExecutionContext:Current`. O login decodificado precisa corresponder ao usuário do contexto. Não há autoria de payload/query. `ContainersCabecalhoRuntime.LogRule` usa a classe real `ApiExecutionRepository`; somente a raiz confirmada enfileira o log. O handler existente possui o flush fora da transação.

`ContainerApiIdentity.i` reúne autenticação. `ContainerMaintenancePolicy.i` usa `parametros_ima.i` e `ContainerCustoBoundary.i` para consultar `despesa_distr_custo` diretamente NO-LOCK em cada chamada. Ausência/vazio mantém default legado0; valor fracionário, negativo ou acima de int32 falha. `tipo_versao_valida_nf` é lido diretamente com default explícito4,5; elementos devem ser IDs positivos distintos. Não há cache de API.

## Request fechado de processos

| resource | operation | Campos específicos além de container_id |
|---|---|---|
| versoes | gerar | tipo_versao_id,descricao,expected_latest_version_id |
| custos | fechar | versao_id,expected_latest_version_id,log_priorizar_custo_previsto |
| impostos | sincronizar | nenhum |

`request_id` string até128 é opcional nos três comandos. IDs são NUMBER JSON integrais int32 positivos; somente expected_latest_version_id de gerar aceita0. A preferência de fechamento exige BOOLEAN explícito. Descrição não vazia, até8000. Operações/recurso/chaves têm grafia exata. Campos extras, policy, actor, custos, valores calculados, callbacks, nomes de bancos/tabelas/programas e exclusão de versão são recusados. O browser não escolhe tipos de versão válidos NF nem empresa de distribuição.

## Composição e transação

`ContainersProcessosService.p` é o dono da transação raiz. Recusa transação ambiente, bloqueia mestre EXCLUSIVE NOWAIT, captura before físico, executa o serviço central com composição privada e verifica success/committed=false/pendingChanges. Falha do helper desfaz o ancestral e preserva seu erro, sem audit confirmado. Após o serviço, relê mestre sob lock e captura after. A resposta pública somente é montada após o commit raiz.

Geração usa os mesmos `ContainersVersionService`, `ContainersVersionRuntime`, coleta, calculador, fiscal e distribuição. O opt-in de distribuição é privado e a empresa permanece `container_company`. Uma distribuição pode produzir segunda versão pelo mesmo writer, sem terceira fotografia. `ContainersVersionRuntime.NextItemCustoId` usa `DYNAMIC-NEXT-VALUE("seq_item_custos","espec")` em produção; somente fixtures privadas podem fornecer contador TT. Não há MAX global nem sequência fornecida por HTTP.

Fechamento usa `ContainersItemCustoCloseService`, `ContainersItemCustoInputsService` e o calculador existente. O wrapper fornece os14buffers físicos fixos; o runtime de versões fornece apenas a sequência necessária. Login acima de30 é recusado nessa ação, pois excede o campo físico cod_usuario: nunca é truncado.

Sincronizar chama apenas `ContainersImpostosService` na operação sincronizar, incluindo o IPI central. Preserva o evento ativo `bl_sincronizar_impostos/index.php:5471,10425–10439`: não acrescenta atualização de despesas calculadas, alteração do flag stale ou timestamp do mestre. A invalidação de despesas CRUD continua no seu serviço próprio.

Conexões/25buffers do coletor são fixos, seguindo `ContainersCustoRead`. Geração recebe documentos MED e IMA para a captura física das notas. Fechamento lê estoque e notas MED/IMA pelos14buffers. MED usa a conexão existente `ems2med`. IMA usa `ems2ima` existente ou o alias privado temporário `ciw_container_ima`, broker fixo127.0.0.1:10030, leitura apenas. O alias temporário é liberado pelo wrapper; não há fallback de instância PASOE.

## Resposta e auditoria

Sucesso público: `success:true,data:{type:"message",message:"texto com IDs efetivos"}`. Geração lista todos IDs de versões criadas, incluindo eventual segunda fotografia; fechamento lista os IDs item_custos gravados. Sincronização informa a memória fiscal criada.

`audit={version:1,source:"progress-transaction",resource:"container_processes",operation:"gerar"|"fechar"|"sincronizar",recordId:container_id,container_id,before,after,changes,actor:{login}}`; request_id é preservado quando informado. before/after são snapshots completos do mestre sob lock, com hífen normalizado para underscore e nr-container convertido em container_id.

Cada change é `{resource,operation:create|update|delete,recordId,before,after}`. Os filhos são eventos efetivos de persistência, não um resumo do comando. VersionService passa a capturar os cinco tipos de filhos criados/excluídos, com seus dados físicos; tipos sem campo físico container_id recebem esse contexto confiável no snapshot de audit. As quatro PK compostas de versões são strings JSONarray com os campos na ordem dos índices físicos:

| resource | recordId |
|---|---|
| container_versions | versao_id numérico |
| item_container_custos | item_container_custo_id numérico |
| item_container_custo_despesas | [versao_id,despesa_id] |
| item_container_custo_nfs | [versao_id,documento,serie,estab,nat_operacao,cod_emitente] |
| item_container_custo_pgtos | [versao_id,num_id_tit_ap] |
| item_container_custo_descontos | [versao_id,desconto_importacao_id] |
| item_custos | item_custo_id numérico |
| despesas_container | despesa_container_id numérico |
| calcs_imp_container | calc_imp_container_id numérico |
| cta_corren_custo_distr | cta_corren_custo_distr_id numérico |
| containers | container_id numérico |

`ContainerTransactionAudit.i` coalesce efeitos do mesmo recurso/PK: guarda o primeiro before e compõe o after final. O delta estreito da distribuição não elimina campos do snapshot completo recém-criado. Tokens JSON inteiros de PK continuam inteiros. Os eventos intermediários de mestre são substituídos por no máximo um evento igual aos snapshots raiz, preservando alterações fiscais desde o before bloqueado. Falhas não retornam audit, efeitos parciais nem mensagem de confirmação.

## Evidência diagnóstica e limites

`.runtime/container-processes-local/command-regression.log`:61fontes compilados12.8 sem erro;30suites e2045checks em AMERICAN e2045 em EUROPEAN. Usa classes reais de contexto/log; somente o binding estático de im-param nas cópias locais de wrappers é substituído por TT para compilar sem banco. Os fontes de produção não têm esse override. Nenhum .r12.8 é publicável.

Suites novas: geração raiz23, fechamento raiz10, fiscal raiz11, request/policy25, merge de auditoria6, credencial pública3. Suites atualizadas: Version189 e Runtime14. Incluem rollback por erro fiscal e segunda sequência, ausência de audit/log em falha, after do mestre, autoria normalizada, contexto confiável de filhos, leitura de IMA sem cache e composição do delta de distribuição. Runners: `CompileContainersProcessosTests.p` e `CompileContainersPublicBoundaryTests.p`; executar com UTF-8 e OpenEdge.Net.pl no PROPATH12.2, com as classes reais e conexão espec para includes de produção.

Pendências de ambiente pertencem à tarefa principal: compilação12.2, publicação seletiva com manifesto/hash e validação PASOE `sursum-api/med`. Não foram exercitados concorrência entre sessões, gatilhos físicos nem negócio real nesta subtarefa. As limitações de consistência ERP já documentadas pelos coletores permanecem.
