# Distribuição automática e simulação central

Estado em 16/10/2026: fontes preparadas e testes auxiliares OpenEdge12.8; sem publicação e sem escrita em banco real. A compilação12.2 e integração PASOE são responsabilidade do publicador. Retorno próprio, distribuição manual e estorno permanecem fora das operações habilitadas, até concluir seu inventário de elegibilidade. O usuário decidiu em16/10 usar **a empresa do container**; provider de produção injeta `container_company`, sem opção do navegador.

## ABI do serviço

`ContainersDistribuicaoService.p` recebe INPUT HANDLE nesta ordem:

1. `phContainer` — `pp-container`;
2. `phEmpresas` — `empresas`;
3. `phSituacoes` — `situacoes_container`;
4. `phItems` — `itens_container`;
5. `phPurchaseItems` — `itens_proc_compra`;
6. `phCompanyExpenses` — `empresas_despesa`;
7. `phExpenseDefs` — `despesas`;
8. `phLedger` — `cta_corren_custo_distr`;
9. `phVersionItems` — `item_container_custos`;
10. `phVersions` — `versoes_item_custo_container`;
11. `phExpenses` — `despesas_container`;
12. `phRuntime` — procedimento confiável, escolhido pelo wrapper.

Depois: INPUT JsonObject `poPolicy`, INPUT JsonObject `poRequest`, OUTPUT JsonObject `poResponse`. Buffers são fixos; não aceitar tabelas, consultas, nomes de campos, programas ou bancos do navegador. O serviço procura o `.r` do calculador primeiro em `sursum-api/programs/ContainersDistribuicaoCalculator.r`, depois no nome literal `ContainersDistribuicaoCalculator.r` para PROPATH explícito/TT. Não compila nem executa `.p` como fallback.

Policy privada:

```json
{"actor":{"login":"autenticado","id":"opaco opcional"},"company_policy":"container_company","gerar_distr_custo":true,"despesa_distr_custo":99,"allow_version":true,"allow_nested":true}
```

`company_policy` é obrigatório, exclusivamente `legacy_company_2` ou `container_company`, sem default. O modo2 preserva a fonte; o outro usa empresa derivada do prefixo1/5 de `cod-estabel` e vínculo único `cod_emp_ems2`. Essa opção nunca pertence ao request externo. Os parâmetros IMA vêm da include `sursum-api/includes/parametros_ima.i`, leitura direta NO-LOCK sem cache. `despesa_distr_custo` deve ser positivo confirmado. As flags privadas são booleanos JSON; ausência de `allow_nested` equivale a false. Identidade usada em escrita é normalizada somente para login/id.

Request fechado:

```json
{"operation":"simulate","container_id":123}
```

ou, exclusivamente pela composição interna de VersionService:

```json
{"operation":"version","container_id":123,"version_id":7,"item_mappings":[{"item_container_id":1,"item_container_custo_id":71}],"snapshot":{"confirmed":true,"container_id":123,"actual_complete":false}}
```

`version_check` aceita as mesmas chaves de `version`, calcula o mesmo plano e nunca altera registros. Os IDs internos são JSONnumber inteiros32 positivos. Mappings devem cobrir todos os itens atuais do container e todos os snapshots da versão alvo, sem duplicidade. Cada snapshot deve pertencer ao mesmo item e versão. O alvo deve ser a última versão **desse container**, conferida sob lock exclusivo do mestre. `snapshot` vem do adaptador central; seus custos gerais não são recalculados nem copiados aqui. Distribuição usa dados físicos coletados novamente sob esse lock.

Callbacks usados por `version`: `NextDistribuicaoId(OUTPUT INTEGER)` com sequência física fixa `seq_cta_corren_custo_distr`; `NextDespesaId(OUTPUT INTEGER)` com `seq_despesas_container`. Ambas as entradas são verificadas antes da primeira escrita. `LogRule(INPUT CHARACTER level, INPUT CHARACTER message)` é opcional, chamado somente após commit próprio, sem flush. Em composição, não há log confirmado nem callback de geração dentro deste serviço.

## Núcleo puro e plano

`ContainersDistribuicaoCalculator.p`: INPUT JsonObject / OUTPUT JsonObject. Não recebe handles e não usa SQL, HTTP, sessão ou escrita. Entrada fechada:

```json
{"confirmed":true,"source":"distribution-inputs-v1","container_id":123,"container_company_id":9,"company_policy":"legacy_company_2","global_enabled":true,"container_enabled":true,"status_enabled":true,"items":[{"item_container_id":1,"item_proc_compra_id":11,"ind_distr_custo":1,"qt_alocada":10,"qt_confirm_emb":5,"vl_base_tributacao":6,"vl_negociado":10,"previous_distribution":2}],"expenses":[{"despesa_container_id":1,"despesa_id":10,"item_container_id":0,"vl_prev":50,"vl_negociado":95}],"company_links":[{"empresa_id":2,"despesa_id":10,"log_custo":1}]}
```

Todos os valores matemáticos são JSONnumber confirmados, não strings formatadas. Unknown/null necessários produzem erro. Despesas físicas, itens e vínculos empresa/despesa duplicados são recusados; despesas exclusivas fora do conjunto também. Ausência de vínculo equivale à ausência de linha no INNER JOIN legado, com exclusão da despesa do pool; não se cria um vínculo fictício.

Fórmulas e referências estão em [inventário](../../docs/containers-distribuicao-inventario.md). `data.items` retorna por item:

- `snapshot_distribution`: delta bruto com dez casas de precisão no plano;
- `snapshot_persisted_distribution`: delta com ROUND2 para o campo físico;
- `ledger_amount`: ROUND2, ou zero na condição comprovada de parâmetro global desligado;
- `emit_entry`: ROUND2 do delta diferente de zero, antes do override global;
- `memory`: peso, base de quantidade, rateio geral, despesa exclusiva, histórico anterior e delta arredondado.

O dicionário de `item_container_custos.vl_custo_distribuido` e `cta_corren_custo_distr.vl_lancto` confirma DECIMALS2. Um teste TT comprovou que atribuição de0,0033333333 armazena0,00. Por decisão confirmada do responsável, o plano conserva o bruto; físico respeita2 casas, com warning `DISTRIBUTION_STORAGE_ROUNDING` contendo item, bruto e persistido. Não se modifica schema. Comparar o valor físico previsto ao anterior evita snapshots de update sem alteração material.

`requiredNewSnapshot` usa OR de `emit_entry` em todos os itens. Resíduo bruto cujo ROUND2 é zero não pede outra versão. Com parâmetro global desligado, o ramo legado ainda inclui movimento/despesa zero quando o delta arredondado original é nãozero; o snapshot registra o delta físico e a origem vem em `DISTRIBUTION_GLOBAL_DISABLED`.

## Atomicidade e composição

`version` bloqueia o mestre e valida **todos** os mappings e o plano antes de mutar. Bloqueia cada snapshot exclusivo; grava valor físico, conta corrente tipo3 e nova despesa gerenciada por movimento. Mantém o vínculo no campo da despesa `cta_corren_custo_distr_id`; não inventa backlink no ledger, cujo `despesa_container_id` permanece default0 conforme a fonte. A despesa recebe container/item explicitamente validados, corrigindo o lookup legado via item direto zero do ledger automático. O warning `DISTRIBUTION_CONTAINER_SCOPE_CORRECTION` identifica essa correção. Não há upsert que apague movimentos anteriores.

Falhas em qualquer sequência, validação ou escrita desfazem todas as alterações da unidade. Repetição de snapshot com distribuição material ou movimento anterior produz `DISTRIBUTION_ALREADY_APPLIED`. `version_check` só avalia; `simulate` lê NO-LOCK sem exigir transação nem ator de escrita. O serviço não lê valores financeiros fornecidos pelo navegador.

Sucesso: `success`, `committed`, `data:{container_id,version_id?,plan,requiredNewSnapshot,warnings}`, e `requiredNewSnapshot` também no topo para o runtime. Em nested `version`, `committed=false` e `pendingChanges` contém resource físico (`item_container_custos`, `cta_corren_custo_distr`, `despesas_container`), operation, recordId numérico, before e after. Não há audit confirmado. Commit próprio gera `audit` com a mesma fila e autoria, só depois do DO TRANSACTION. Simulação/check não retornam audit.

O **runtime de versão** é o único driver: primeira versão chama `version`; se houver efeito persistível, solicita no máximo uma versão adicional pelo mesmo VersionService (`allow_nested=true` privado). Nessa segunda etapa chama `version_check`; um delta persistível restante é `UNSTABLE_DISTRIBUTION`, com rollback do ancestral. Não fazer recursão nem duplicar persistência/cálculo geral neste serviço.

Limite de concorrência: NO-LOCK em preços, vínculos, configuração e histórico respeita o contrato de leitura solicitado. O lock do mestre serializa escritores do container que seguem esse protocolo; não impede alteração simultânea de cadastros globais por programas externos. A coleta estrita requer todos os campos declarados confirmados. Como na fonte, o runtime pode dispensar a consulta de distribuição quando ambas as flags combinadas não habilitam o processo, mantendo snapshots0 já persistidos pelo VersionService.

## Evidência auxiliar

- `CompileContainersDistribuicaoTests.p`: calculador55 checks por cultura AMERICAN/EUROPEAN em12.8;
- `CompileContainersDistribuicaoServiceTests.p`: serviço55 checks por cultura em12.8, incluindo atomicidade, rollback externo, falha na segunda sequência, último item zero, guard privado, mapeamento integral, conflito de versão, escala física2, residual bruto e estabilização em duas versões;
- `ContainersDistribuicaoRuntimeFixture.p` é double exclusivo de TT; nunca publicar.

Logs locais em `.runtime/container-distribuicao-local/`. Esses testes não substituem a compilação12.2 e a validação do fluxo completo no PASOE real.
