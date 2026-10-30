# ContainersVersionService — ABI interna v1

Fonte interno implementado por TDD, sem endpoint, GUI, publicação ou escrita em banco real nesta etapa. Diagnóstico local OpenEdge12.8: **143 checks em AMERICAN e EUROPEAN**, três fontes com `COMPILER:ERROR=no`. Compilação/TT12.2 e integração PASOE serão coordenadas pelo responsável principal; .r diagnóstico12.8 não é artefato publicável. Runner `CompileContainersVersionTests.p` e testes/provider/include `ContainersVersionTest.p`, `ContainersVersionFixture.p`, `ContainersVersionTestTables.i` nunca devem ser publicados como programas de negócio.

Assinatura: handles fixos de buffers `master,types,versions,items,expenses,nfs,payments,discounts`, handle de procedimento persistente confiável `runtime`, JsonObject `policy`, JsonObject `request`, OUTPUT JsonObject `response`. Nenhum nome de tabela, campo, callback ou caminho é escolhido por JSON externo.

`request` fechado:

- `gerar`: operation,container_id,tipo_versao_id,descricao,expected_latest_version_id,request_id opcional de rastreio.
- `consultar`: operation,container_id,versao_id opcional (sem ID lista versões do container).
- `excluir_incompleta`: operation,container_id,versao_id,expected_latest_version_id,request_id opcional.

IDs positivos int32; expected_latest admite zero para ausência. `policy.actor` contém login e ID opaco opcional, oriundos de autenticação. Capacidades de execução são aprovadas pelo wrapper; serviço exige ator nas mutações e contexto pai existente. HTTP futuro deve impor permissão antes de chamá-lo.

Callbacks fixos aprovados, executados dentro da transação raiz do serviço:

```text
NextVersionId(OUTPUT INTEGER)
NextVersionItemId(OUTPUT INTEGER)
PrepareVersionFiscal(INPUT master HANDLE, OUTPUT JSON {success,changes,warnings})
CollectVersionSnapshot(INPUT master HANDLE, OUTPUT JSON {
  confirmed:true,container_id,actual_complete,
  cost:<ContainersVersaoCostAdapter.data>,
  header:{snapshot físico autorizado},
  expenses:[...],nfs:[...],payments:[...],discounts:[...]
})
```

Fiscal delega ao serviço/regras centralizados. Cost contém items_real/items_dolar pareados por item_container_id, input_snapshot.items e master_average. Nenhuma fórmula é reimplementada neste serviço. As demais listas são snapshots físicos, não entrada do navegador. O provider deve coletá-las coerentemente com o instante da coleta de custo; não alega que todos os filhos têm lock só por segurar o mestre.

`gerar` exige transação raiz própria por padrão, lock exclusivo NO-WAIT no mestre e comparação da última versão **desse container**. Composição interna exige `policy.allow_nested=true` booleano; retorna committed=false, pendingChanges e pendingMaster, sem audit confirmado. O ancestral é responsável por UNDO integral se qualquer etapa falhar. Captura sequência em variável por callback, cria cabeçalho situação1, persiste filhos, valida os buffers e só então situação2 e stale=false. A auditoria raiz inclui master.before/after para registrar a limpeza de stale. Falha desfaz mestre, efeitos fiscais e filhos. Números de sequência consumidos não são revertidos.

`header` é fechado e exige os campos `vl_dolar_compra,vl_desconto_utiliz_dolar,vl_desconto_utiliz_real,vl_dolar_di,log_gerar_saldo_a_pagar,log_gerar_distr_custo,situacao_container_id,desc_sit_container,cod_tipo_cotacao,vl_cotacao,data_ref_cotacao,perc_fixo_container,hist_dolar`. `vl_dolar_medio` vem exclusivamente de `cost.master_average.dolar_medio`; IDs/ator/situação são definidos no serviço. Dados não confirmados podem ser null explícito quando físicos permitirem; as duas flags precisam ser booleanos conhecidos. O callback não substitui esses campos por defaults fictícios.

Filhos físicos fechados, sem `versao_id` recebido (sempre definido pelo serviço): despesas=`despesa_id,vl_prev,vl_negociado,vl_proforma,vl_base_imp,calc_imp_container_id,log_custo`; NFs=`documento,serie,estab,nat_operacao,cod_emitente,vl_mercadoria,vl_despesa`; pagamentos=`num_id_tit_ap,vl_real,vl_dolar`; descontos=`desconto_importacao_id,vl_autoriz_real,vl_autoriz_dolar,log_custo`. `estab` compõe a PK física de NFs. Objetos incompletos/extra/sem chave válida são recusados; duplicatas de PK fazem rollback. Itens são mapeados por `item_container_id` entre BRL, USD e input_snapshot; não pela posição do array. A memória de cálculo do item registra fonte, completude e resultados centrais reutilizados.

Realizado desconhecido permanece JSON null/ABL ?, com origem/aviso. `actual_complete=false` não bloqueia por si só a geração; nunca coagir para zero. Fechamento unitário está fora do contrato. Exclusão só permite situação1, não utilizada, e remove os filhos do mesmo versao_id; situação2 é preservada.

Não utilizada exige `item_custo_id=0` conhecido em todos os itens. ID positivo **ou desconhecido** impede a exclusão. Filhos de outra versão/container são preservados. Consulta sem versao_id retorna `data` array de cabeçalhos; com ID retorna `data` cabeçalho e `snapshot` com header/itens/despesas/NFs/pagamentos/descontos persistidos. Mutações retornam data/snapshot/audit somente após commit; exclusão retorna data vazio e snapshot anterior. Erro contém success=false/error e nenhum audit confirmado.

Distribuição permanece bloqueada por padrão: `log_gerar_distr_custo=true` retorna `VERSION_DISTRIBUTION_UNSUPPORTED` sem `policy.enable_distribution=true` booleano **e** GetStatus do provider confirmado/distribution_enabled=true. O hook privado recebe os IDs físicos persistidos em item_mappings; aceita somente efeitos pendentes sem audit/commit e agrega mudanças ao audit raiz. Falha do callback desfaz versão, filhos e efeitos fiscais. O cálculo e a composição limitada ficam no serviço central/runtime, sem fórmula no writer. A ativação produtiva depende de concluir e revisar o driver privado, ainda WIP no checkpoint.

Os testes cobrem callback fiscal/coleta falhando após mutação, auditoria inválida, confirmação/flags null, distribuição bloqueada, filho inválido/duplicado, moedas em ordem inversa, uso desconhecido, contexto de outro container, guard otimista e transação ambiente. Não comprovam concorrência real entre sessões, triggers físicos ou precisão de escrita no banco; essas validações dependem da etapa12.2/PASOE.

Não há tabela nova de idempotência. expected_latest evita repetição otimista com a mesma expectativa, mas request_id só rastreia; retry sem resposta após commit precisa consultar a última versão antes de decidir nova ação. Não prometer deduplicação persistida por request_id/fingerprint.

Checkpoint 16/10/2026: baseline167 preservado em `.runtime/container-version-baseline167`; hook GREEN186 checks por cultura no diagnóstico local12.8 (`.runtime/container-version-local`). Driver de duas fotografias validado em Composition34/cultura com serviços reais sobre TT. RED do hook e da composição estão nos stagings. Não substitui compilação12.2/PASOE; não houve publicação nem escrita real. Falta corrigir leitura histórica de realizado null no Collector (regressão separada RED); consultar `ContainersVersionRuntime.md` antes de ativar opt-in.
