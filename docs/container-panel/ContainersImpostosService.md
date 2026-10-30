# Serviço fiscal transacional do container

Fonte preparado em16/10/2026: `ContainersImpostosService.p`. Implementa ações explícitas `sincronizar` e `atualizar_despesas_calculadas`; não deve ser chamado ao abrir, pré-carregar ou atualizar uma aba de leitura. Compilação/publicação/validação real12.2/PASOE pertencem à tarefa principal. Nenhuma escrita de negócio real foi feita por estes testes.

## ABI e entrada confiável

INPUT HANDLEs, na ordem: `phContainer,phEmpresas,phItems,phPurchaseItems,phPurchases,phDefs,phLinks,phTaxBases,phRelations,phCalcs,phExpenses,phIdProvider`.

Correspondência fixa dos11buffers: `espec.pp-container,empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container`. Somente o wrapper autenticado fornece esses handles; o JSON externo não escolhe tabela, campos ou banco.

Depois dos handles: INPUT JsonObject `poPolicy`; INPUT JsonObject `poCalculationInputs`; INPUT JsonObject `poRequest`; OUTPUT JsonObject `poResponse`.

`phIdProvider` é um procedimento confiável do wrapper (por exemplo THIS-PROCEDURE) com procedimentos internos `NextCalculoId(OUTPUT INTEGER)` e `NextDespesaId(OUTPUT INTEGER)`. O wrapper deve obter diretamente `DYNAMIC-NEXT-VALUE` de `seq_calcs_imp_container` e `seq_despesas_container` no banco espec. Não usar MAX global. Sequências podem consumir números em tentativas desfeitas; isso não é confirmação de uma linha. O callback opcional `LogRule(INPUT CHARACTER level,INPUT CHARACTER message)` pode usar a classe real ApiExecutionRepository no wrapper; o serviço não depende dessa classe para compilar. Não aceitar nome de callback, sequência ou tabela do cliente.

`poPolicy` interno: `{"usuario_id":7,"actor":"usuario autenticado","despesa_distr_custo":0}`. Autoria vem do contexto de execução do backend, não do formulário. Usuário inteiro0–2147483647; actor não vazio até160caracteres.

`poCalculationInputs` interno:

```json
{
  "confirmed":true,"container_id":71,"source":"container-cost-collector",
  "dolar_di":5,"dolar_compra":4,
  "container_snapshot":{
    "vl-dolar-compra":4,"vl_dolar_di":5,
    "ordem_busca_dolar_compra":"2","ordem_busca_dolar_di":"4",
    "cod_tipo_proj_dolar":1,"vl_proj_dolar":0
  }
}
```

As duas cotações precisam ser números positivos confirmados pelo coletor; paridade1 pode ser explícita, não é assumida em falta de dado. Os seis parâmetros físicos são comparados sob lock do pai; divergência gera `CONTAINER_INPUT_STALE`412. Quantidades, preços, vínculos e bases são relidos dos buffers sob locks, não recebidos do navegador.

O wrapper deve coletar os componentes dentro da seção protegida pelo lock do mestre quando houver concorrência. O snapshot de seis campos protege parâmetros de cabeçalho, não é um snapshot completo de pagamentos/descontos/preços que podem influenciar o dólar médio. Novos escritores de filhos precisam respeitar o mesmo lock do mestre; não há garantia de gap lock contra um escritor legado que ignore esse protocolo.

Parâmetros IMA usados pelo coletor/wrapper continuam na include `sursum-api/includes/parametros_ima.i`, leitura direta NO-LOCK de espec.im-param por chamada, sem cache. O serviço fiscal não introduz consulta paralela nem cache de parâmetros.

Request externo fechado: `{"operation":"sincronizar","container_id":71}` ou `operation=atualizar_despesas_calculadas`. Recusa campos extras, operações de leitura, contexto inválido e dados matemáticos desconhecidos necessários ao cálculo. O frontend não fornece percentuais, valores fiscais, identidade de auditoria, cotações, sequências ou memória.

## Ordem e atomicidade

Uma transação real envolve planejamento e persistência:

1. Pai EXCLUSIVE-LOCK NO-WAIT por nr-container.
2. Empresa derivada do primeiro caractere de cod-estabel, mapping único por cod_emp_ems2, SHARE-LOCK NO-WAIT.
3. Itens do container por PK, depois itens do pedido e processos de compra por respectivas PKs, SHARE-LOCK NO-WAIT. O JOIN de existência com procs_compra é preservado.
4. Cadastros de despesas, vínculos da empresa, bases fiscais e relações calculadas em ordem estável, SHARE-LOCK NO-WAIT.
5. Despesas existentes do container por PK, EXCLUSIVE-LOCK NO-WAIT. Combinação container/despesa/item duplicada é recusada; o dicionário não possui índice único dessa combinação.
6. Plano em temp-tables internas NO-UNDO; só depois criar cálculo e gravar despesas. Todas as tabelas persistentes/fixtures transacionais usam undo real. Falha desfaz INSERT de cálculo, UPDATE e INSERT de despesas juntos.

IDs são obtidos nos callbacks dentro da transação, sem pesquisar o maior ID. Snapshot anterior vem dos registros bloqueados, nunca do request. Snapshots posteriores são gerados depois de BUFFER-VALIDATE. Campos não alterados pelo PHP são preservados em updates.

Quando executado sozinho, `success:true`/`data.committed:true` e `audit.source=progress-transaction` só são anexados depois de encerrar o DO TRANSACTION. Auditoria contém `children` com recurso, operação, recordId, before e after para cálculo e cada despesa gravada, além de autoria e avisos.

Quando já existe TRANSACTION externa, o serviço devolve `data.committed:false`, `pendingChanges` e `auditPending.source=progress-transaction-pending`; **não** devolve audit confirmado. O caller precisa confirmar sua própria transação e então materializar auditoria. Se retornar success:false, o caller deve desfazer a transação externa inteira e parar as regras seguintes. Os testes exercitam esse contrato, inclusive rollback de mutação anterior do cabeçalho. O callback de log de confirmação não é chamado em execução nested ou falha.

## Regras portadas

Evidências relativas a `sources/scriptcase/containers/bl_sincronizar_impostos/index.php`; inventário detalhado em `docs/containers-painel-regras-inventario.md`.

- `sincronizar`: cria cálculo, impostos gerais (`log_imposto=1`, `log_calc_por_item=0`), parcelas não recuperáveis e IPI por item. Não executa automaticamente despesas calculadas, porque o menu não as chama (`:10431–10436`).
- Totais de mercadoria usam soma preço×confirmada global por base; se essa soma inteira for zero, usam soma preço×alocada global. Tributado=vl_base_tributacao, proforma=vl_custo_dolar, negociado=vl_negociado, diferença positiva tributado−negociado por preço (`:8519–8569`).
- Imposto geral soma as despesas referidas em despesas_impostos da empresa: soma vl_base_imp se soma diferente de zero, senão soma vl_prev. A mesma soma de despesas alimenta as três modalidades. Mercadorias das três bases usam dólar DI; negociado recebe a diferença tributado−negociado (`:10226–10297`).
- Dependências entre impostos são resolvidas topologicamente, com ordem/ID estáveis para empates; ciclos são recusados. O legado não ordenava a consulta. Custos não recuperáveis usam valor/percentual×percentual_custo nas três modalidades; percentual zero falha, não divide. Todos os vínculos são percorridos, corrigindo o overwrite do array de origem do PHP (`:10302–10355`). Destino repetido/ausente e ciclos de custo são recusados.
- A despesa IPI é identificada por ind_imposto=3, com vínculo à empresa. Mais de uma definição IPI global é ambígua e falha. Tributado usa DI; proforma/negociado usam compra. Bases de despesas são arredondadas2casas; o rateio por item e modalidade e o IPI final são arredondados2casas (`:10682–10755`). Divisor zero é recusado. IPI só é sincronizado quando a soma das três modalidades é positiva; zero/desabilitado mantém a despesa anterior e gera aviso em data e auditoria. A gravação mantém perc_calc=0 como o retorno externo do legado (`:10633`, `:10671`).
- `atualizar_despesas_calculadas`: seleciona despesas existentes não manuais e cuja definição é calculada. Soma relações relacs_desp_calculada, usando previsto quando negociado da base é zero; inclui mercadorias se configurado, acrescentando diferença tributado−negociado ao negociado. As quatro bases usam dólar compra explicitamente, como aCotacao de `:9774–9777`. Aplica perc_calculo/100, resolve dependências topologicamente e não cria calcs_imp_container.
- Upsert corresponde à combinação container/despesa/item. Grava vl_prev,vl_proforma,vl_negociado,calc_imp_container_id,cta_corren_custo_distr_id=0,perc_calc,memoria_calculo. INSERT determina log_manual pelo percentual zero/não zero; UPDATE preserva log_manual e os demais atributos físicos (`:9650–9672`, `:9927–9942`). Não marca versão por si: o caller deve executar a regra de invalidação quando seu evento a exigir.

Memória nova é JSON estruturado em texto, sem HTML executável. Campos tributados/proforma/negociados e percentuais de cada etapa ficam registrados. A compatibilidade de apresentação das memórias legadas/novas pertence às consultas nativas.

## Ambiguidades recusadas

Quando um caminho PHP lê `[0]` sem item/ordem definida (base do IPI, base de despesa calculada e origem do custo não recuperável), o serviço recusa mais de uma linha para a mesma despesa em vez de escolher um item arbitrário. Isso é distinto da base dos impostos gerais, cuja SQL original usa SUM e soma todas as linhas. Unknown em componentes matemáticos usados é erro; percentuais desconhecidos de definições não usadas e IPI desabilitado não bloqueiam cálculo de outros itens.

Principais erros: `CONTAINER_BUSY`409; `CONTAINER_INPUT_STALE`412; `CONTAINER_TAX_CONFIG`, `CONTAINER_TAX_CYCLE`, `CONTAINER_ZERO_DENOMINATOR`, `CONTAINER_EXPENSE_AMBIGUOUS`, `CONTAINER_VALUE_UNKNOWN`422; falha de persistência409. Falhas nunca retornam audit confirmado ou totais parciais como gravados.

## Evidência auxiliar local

OpenEdge12.8 diagnóstico: serviço e teste compilaram com `COMPILER:ERROR=no`;73verificações passaram em cada formato AMERICAN/EUROPEAN. RED inicial observado por serviço ausente293 antes de implementar. Arquivos `ContainersImpostosTest.p` e `CompileContainersImpostosTests.p`; evidências `.runtime/container-impostos-local/`. Não publicar os `.r`12.8.

Fixtures fiscais incluem duas linhas, três modalidades, impostos dependentes em ordem invertida, dois custos não recuperáveis, IPI254/163/122.67, preservação de555com aviso, despesa calculada610/489/608, manual em INSERT/UPDATE, sequência abaixo de um MAX global alheio, snapshots, falha após update+insert+cálculo, rollback integral, execução nested e rollback do cabeçalho pelo caller, ciclos fiscais/calculados, duplicidade, divisores zero, parâmetro interno stale e request fechado. Locks entre sessões, triggers reais, sequências reais e armazenamento SQL precisam da compilação12.2 e validação PASOE da tarefa principal com registros novos autorizados e limpeza.

## Distribuição gerenciada e duplicidades legítimas (16/10/2026)

O legado sempre insere uma nova despesa para cada movimento do ledger, inclusive retorno negativo. Evidência: sources/scriptcase/containers/bl_distribuir_custo_contr/index.php:9956,10014–10043; bl_item_custos/index.php:16087–16094; retorno em bl_distribuir_custo_contr/index.php:5480–5501. Não existe upsert por despesa/item nesse fluxo. O ledger não recebe obrigatoriamente despesa_container_id de volta.

O parâmetro privado opcional despesa_distr_custo aceita somente NUMBER inteiro0–2147483647; ausente/0 desabilita a exceção. O wrapper obtém o valor pela include parametros_ima.i diretamente NO-LOCK sem cache e o encaminha nos dois callers fiscais (cabeçalho e despesas). Não é campo da requisição pública.

ABI11buffers permanece intacta. O provider acrescenta ValidateDistributionExpense(INPUT HANDLE master,INPUT HANDLE expense,OUTPUT JsonObject proof). Sucesso fechado: {confirmed:true,container_id:INTEGERpositivo,despesa_container_id:INTEGERpositivo,ledger_id:INTEGERpositivo}. As quatro propriedades são obrigatórias, com tipos estritos e valores exatos do registro bloqueado. Ausência, falha, propriedade extra, confirmedfalse, identificador fracionário/string ou contexto divergente causa CONTAINER_DISTRIBUTION_INVALID422 antes de qualquer escrita persistente.

LoadState permite repetição da combinação despesa/item apenas para despesa_id igual ao parâmetro privado positivo e quando todas as linhas dessa combinação têm prova confirmada; cada cta_corren_custo_distr_id deve ser positivo e distinto de todos os outros movimentos gerenciados do container. A mera FK preenchida não é prova. O runtime deve validar o ledger e o dono conforme seu contrato próprio. Linhas gerenciadas são preservadas integralmente: não são consolidadas, removidas nem atualizadas por UpsertPlan. Mesmo um único destino gerenciado é recusado caso uma configuração fiscal tente sobrescrevê-lo.

TaxPlan mantém SUM(vl_base_imp), usando-o quando diferente de zero, senão SUM(vl_prev), exatamente como no legado. UniqueExpense continua recusando mais de uma linha nas bases IPI/despesa calculada/custo não recuperável; a exceção de distribuição não torna FIRST determinístico. UpsertPlan também conta os destinos explicitamente e recusa ambiguidade.

TDD auxiliar12.8 atualizado:128verificações em cada cultura AMERICAN/EUROPEAN. RED reproduziu a recusa original de duas despesas legítimas (CONTAINER_EXPENSE_AMBIGUOUS). GREEN cobre valores10+15, base explícita2+3, preservação dos dois ledgers, policy ausente/inválida, ledger repetido/zero/órfão, retorno JSON adulterado, ambiguidades IPI/calculada, bloqueio de upsert e protocolo nested com UNDO integral. Logs em .runtime/container-impostos-local/. Compilação12.2 e validação entre sessões/ERP real ainda pertencem ao root; nenhum negócio real foi escrito.
