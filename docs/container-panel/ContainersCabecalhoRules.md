# Provider concreto do cabeçalho

`ContainersCabecalhoRules.p` é procedure persistente interna, sem endpoint. O cabeçalho fornece o mestre EXCLUSIVE-LOCK dentro da sua transação raiz; o provider não confirma transações nem emite auditoria confirmada.

## ABI fixa

INPUT HANDLEs nesta ordem:

| Posição | Parâmetro | Tabela espec |
|---|---|---|
| 1 | phEmpresas | empresas |
| 2 | phItems | itens_container |
| 3 | phPurchaseItems | itens_proc_compra |
| 4 | phPurchases | procs_compra |
| 5 | phDefs | despesas |
| 6 | phLinks | empresas_despesa |
| 7 | phTaxBases | despesas_impostos |
| 8 | phRelations | relacs_desp_calculada |
| 9 | phCalcs | calcs_imp_container |
| 10 | phExpenses | despesas_container |
| 11 | phCommercial | pp-it-container |
| 12 | phPermissions | pp_container_permissao |
| 13 | phRepBalances | pp_container_saldo_repres |
| 14 | phNfs | nfs_container |
| 15 | phDiscountLedger | cta_corren_desconto |
| 16 | phAttachments | anexos_container |
| 17 | phVersions | versoes_item_custo_container |
| 18 | phPayments | pagtos_container |
| 19 | phSupplierLedger | cta_corren_fornec_imp |
| 20 | phItemCosts | item_container_custos |
| 21 | phRuntime | procedure confiável do wrapper |

Após os handles: INPUT JsonObject `poPolicy:{usuario_id:integer,actor:{login:string,id?:string},despesa_distr_custo?:integer}`, sempre da autenticação/parametrização privada. Não receber esse objeto do navegador. O mestre não é parâmetro do construtor; chega nos callbacks do cabeçalho. O ID opcional de distribuição aceita0..int32, somente número JSON integral; é repassado ao fiscal central para reconhecer exclusivamente movimentos gerenciados comprovados. Vem da include IMA sem cache.

Extensão de16/10: `ValidateDistributionExpense(INPUT HANDLE master, INPUT HANDLE expense, OUTPUT JsonObject proof)` encaminha ao runtime confiável. Prova física é `{confirmed:true,container_id,despesa_container_id,ledger_id}`, IDs numéricos positivos com correspondência exata. O fiscal valida o envelope e só permite duplicatas gerenciadas com contas correntes distintas e propriedade comprovada pelo runtime; não libera duplicatas comuns nem bases FIRST ambíguas. Callback ausente/falha causa rollback. Teste integrado:45 checks/cultura12.8.

Callbacks públicos do provider:

```text
GetCapabilities(OUTPUT JsonObject {contract:'container-rules-v1',onUpdate,beforeDelete})
OnUpdate(INPUT HANDLE master, INPUT JsonObject ctx, OUTPUT JsonObject result)
BeforeDelete(INPUT HANDLE master, INPUT JsonObject ctx, OUTPUT JsonObject result)
SetVersionDeleteTargets(INPUT HANDLE despesas, INPUT HANDLE nfs, INPUT HANDLE pgtos, INPUT HANDLE descontos)
```

`ctx={operation:'update'|'delete',container_id,actor,before}`. O ID/operation precisam coincidir com o mestre; TRANSACTION precisa estar ativo. O provider confirma o EXCLUSIVE-LOCK pelo ROWID do mestre. Resultado: `{success:true,changes:[{resource,operation,recordId,before,after}],warnings?:[string]}`; é somente material pendente até o commit do cabeçalho. Falha lança AppError para UNDO integral pelo caller.

## Runtime do wrapper

```text
CollectCalculationInputs(INPUT HANDLE masterLocked, OUTPUT JsonObject inputs)
NextCalculoId(OUTPUT INTEGER valueId)
NextDespesaId(OUTPUT INTEGER valueId)
LogRule(INPUT CHARACTER levelName, INPUT CHARACTER messageText)  /* opcional */
```

`CollectCalculationInputs` é chamado **dentro** da transação, após os novos valores do cabeçalho estarem no buffer bloqueado. Deve reler os dados de custo confirmados e retornar exatamente o contrato de `ContainersImpostosService.md`: `confirmed:true,source:'container-cost-collector',container_id,dolar_di,dolar_compra,container_snapshot` com os seis nomes físicos `vl-dolar-compra,vl_dolar_di,ordem_busca_dolar_compra,ordem_busca_dolar_di,cod_tipo_proj_dolar,vl_proj_dolar`. Não reutilizar cotação coletada antes do lock nem aceitar números do formulário. Parâmetros IMA usam include `sursum-api/includes/parametros_ima.i` e leitura direta NO-LOCK sem cache.

Sequências são callbacks internos fixos para `seq_calcs_imp_container` e `seq_despesas_container` no espec, por DYNAMIC-NEXT-VALUE; sem MAX. O provider delega esses callbacks ao runtime. Não é preciso sequência de movimento de fornecedor na exclusão aprovada, pois pagamentos precisam estar desvinculados antes dela.

Interface de log existente, verificada no canônico `sursum-api/sursum/ApiExecutionRepository.cls`: `logMessage(level,message)` enfileira em `PasoeExecutionContext:Current.queueLogMessage`; `flushLogMessages(context)` recusa TRANSACTION ativo. O callback LogRule do wrapper deve usar essa fila. O wrapper chama flush somente após retorno da transação raiz. Provider/fiscal nested não fazem flush nem anunciam commit. Não se replica a reparação ampla de sc_log do PHP.

## OnUpdate

Fonte de sequência ativa: `form_pp_container/form_pp_container_apl.php:9123–9124`. Coleta cotações uma vez sob lock e chama o serviço fiscal congelado, nesta ordem: `sincronizar` → `atualizar_despesas_calculadas`. Cada retorno precisa ser success, committed=false, pendingChanges presente e audit confirmado ausente. Qualquer falha impede a etapa seguinte e propaga erro para rollback da raiz, incluindo as alterações já feitas no mestre.

Eventos repetidos de mesmo recurso+ID são coalescidos: before da primeira alteração e after da última. Create seguido de update continua create. Avisos fiscais são strings controladas vindas do serviço e seguem para o cabeçalho, que só os expõe no audit após commit. Não se altera a matemática do serviço fiscal nem a marca de versão feita pelo cabeçalho.

## BeforeDelete

Decisão do usuário confirmada em16/10/2026: **bloquear até desvincular pagamentos e custos**. Antes de qualquer efeito, valida dependência comercial (`pp-it-container`), qualquer vínculo em `pagtos_container` e `item_container_custos` tanto por item alocado quanto por versão do container. Dependência comercial vem do PHP `:19708–19736`; os dois bloqueios adicionais são a decisão confirmada e evitam órfãos que o cascade PHP não cobre.

Com pagamentos desvinculados, a lista consultada por `buscarTitAssociadosContainer` (`:20525–20546`) está vazia. Assim, o ramo `gerarRateioFornecAntecipsContainer(...,true)` (`:11552–11696`) não percorre títulos nem cria estornos. O provider não inventa compensações de movimentos históricos órfãos: preserva `cta_corren_fornec_imp` e seus IDs. O saldo tipo5/ROUND2 do ramo legado só seria executável com título vinculado, condição agora bloqueada por decisão explícita.

Depois de todos os bloqueios, prepara snapshots completos e locks dos filhos antes de excluir qualquer linha. Cascade comprovado em PHP `:7644–8005`: permissões, saldo representante, itens, despesas, NFs, conta de desconto, anexos, cálculos fiscais e versões. Filtra sempre pelo ID exato do mestre; usa PK/ROWID planejados e EXCLUSIVE-LOCK NO-WAIT. `pp-it-container` não é removido porque sua existência bloqueia. Pagamentos/custos não são removidos. Arquivos externos de anexo não são apagados; somente o registro do vínculo. O mestre é removido exclusivamente pelo serviço raiz depois do callback.

Snapshots incluem todos os campos do buffer de cada filho e tipos DATE/DATETIME/DATETIME-TZ/INT64. Chaves compostas de permissões/saldo/NF são string JSON de objeto de componentes tipados, não concatenação ambígua. Não há SQL recebido do cliente nem consulta montada com conteúdo de texto persistido.

### Exclusão dos snapshots auxiliares de versões

Correção preparada em16/10/2026: o construtor original de20buffers permanece intacto. O setter interno `SetVersionDeleteTargets` recebe, na ordem, os quatro buffers físicos `espec.item_container_custo_despesas`, `espec.item_container_custo_nfs`, `espec.item_container_custo_pgtos`, `espec.item_container_custo_descontos`. O wrapper público do cabeçalho cria esses buffers fixos apenas na operação delete. Não existe parâmetro HTTP, rota nova ou escolha de tabela pelo navegador. Geração/atualização continuam usando a ABI existente.

Quando existem versões do container, todos os quatro alvos precisam estar disponíveis; ausência falha antes de qualquer exclusão. Quando não há versão própria, o construtor anterior continua utilizável sem o setter. O provider consulta somente versões do mestre bloqueado e passa seu ID físico ao planejador reutilizável `PlanDeleteFor`. Os quatro conjuntos auxiliares são bloqueados, fotografados e incluídos no mesmo plano antes das respectivas versões; todos os planos são concluídos antes da primeira chamada BUFFER-DELETE. Não ignora nem desabilita triggers. Falha de leitura/lock não equivale a conjunto vazio.

Audit dos auxiliares: operation=delete, before com todos os campos físicos mais container_id confiável do mestre, after vazio. recordId é STRING JSONarray seguindo o índice primário: despesas `[versao_id,despesa_id]`; NFs `[versao_id,documento,serie,estab,nat_operacao,cod_emitente]`; pagamentos `[versao_id,num_id_tit_ap]`; descontos `[versao_id,desconto_importacao_id]`. O envelope também contém os deletes físicos de `versoes_item_custo_container`. A allowlist do serviço raiz aceita esses quatro recursos somente na exclusão do container, com contexto de versão/container confirmado. A auditoria somente é exposta após o commit raiz.

Evidência diagnóstica12.8: suite Rules113checks por cultura (45 anteriores+68), incluindo dois históricos próprios e um alheio, todos os quatro tipos, oito snapshots auxiliares removidos, dezoito eventos efetivos no audit integrado, PKs completas e ordem antes das versões, rollback ancestral, alvos ausentes sem alterações e compatibilidade sem versões. Regressão completa61fontes/30suites em AMERICAN/EUROPEAN passou. Log privado `.runtime/container-processes-local/command-regression.log`. Nenhum registro ou sequência real foi acessado nesta correção. Compilação12.2, publicação do delta e validação PASOE pertencem à tarefa principal.

## Evidência preparada

`CompileContainersCabecalhoRulesTests.p` compila provider, teste, serviço fiscal congelado e serviço de cabeçalho, e executa AMERICAN/EUROPEAN. Fixtures usam tabelas dinâmicas UNDO com campos do dicionário, sem banco real. Verificam guardas comerciais/pagamentos/custos por item e versão, cascade com snapshots, rollback externo, preservação de ledger e mestre pelo provider, coleta de cotações durante a transação e integração fiscal real.

Fixture fiscal deliberadamente permite a mesma despesa ser imposto e calculada para comprovar sequência/coalescência: primeiro500, depois10; audit precisa ter before1/after10, sem dupla entrada. Falha da segunda etapa desfaz o cálculo inserido, a primeira atualização fiscal e a narrativa alterada pelo cabeçalho. Esses testes não substituem bloqueio concorrente entre sessões, sequências/triggers reais ou compilação12.2/PASOE. Nenhuma escrita de negócio real foi executada.

Resultado auxiliar12.8 final:40 verificações por cultura no provider e99 por cultura no cabeçalho, todos sem erro de compilação. Cenário adicional remove somente o .r fiscal do staging privado e comprova onUpdate=false antes de escrita; o provider procura primeiro sursum-api/programs/ContainersImpostosService.r, depois o literal ContainersImpostosService.r, nunca executa fonte .p nem compila implicitamente. A suíte também executa exclusão integrada pelo serviço real do cabeçalho e confirma nove snapshots de filhos no audit póscommit.
