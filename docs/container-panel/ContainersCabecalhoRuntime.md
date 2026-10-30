# Callbacks privados do cabeçalho

`ContainersCabecalhoRuntime.p` é um procedimento persistente interno. O wrapper público cria esse runtime, passa seu handle ao provider `ContainersCabecalhoRules.p` e o exclui no FINALLY. Não há rota pública deste arquivo. Não aceita usuário, execução, sequências, tabelas, bancos, campos ou SQL do navegador.

ABI de criação: `RUN VALUE(cRuntimeR) PERSISTENT SET hRuntime(INPUT ?)` em produção. O único parâmetro é `INPUT HANDLE phCostReader`: produção usa unknown; somente testes/invocadores internos confiáveis podem fornecer um procedimento com `ReadContainerCost(INPUT JsonObject,OUTPUT JsonObject)`. Esse adaptador não é extraído da requisição pública. O wrapper resolve o `.r` do runtime por caminho fixo, sem executar fonte.p.

Por determinação explícita do usuário, cálculo de custo e rotinas de versão são separados e reutilizáveis. A ABI `ContainersCustoCalculator.p(INPUT JsonObject,OUTPUT JsonObject)` concentra a matemática; `ContainersCustoReadService.p` concentra a coleta pelos25buffers fixos documentados; `ContainersCustoRead.p` concentra autenticação/conexões/includes. Este runtime chama essa mesma cadeia e apenas adapta o resultado ao contrato fiscal; não reimplementa médias, prioridades, rateios ou fórmulas de custo. Persistência de versões pertence à rotina de versões separada, que deve reutilizar a coleta/núcleo, sem copiar suas fórmulas para telas ou eventos.

Callbacks mantidos exatamente como o provider espera:

- `NextCalculoId(OUTPUT INTEGER)`: `DYNAMIC-NEXT-VALUE("seq_calcs_imp_container","espec")`.
- `NextDespesaId(OUTPUT INTEGER)`: `DYNAMIC-NEXT-VALUE("seq_despesas_container","espec")`.
- `LogRule(INPUT CHARACTER levelName,INPUT CHARACTER messageText)`: usa `ApiExecutionRepository:logMessage` e `PasoeExecutionContext:Current`. Só enfileira; nunca chama flush, inventa executionId ou cria contexto. Sem contexto corrente não faz nada. Instância do logger é excluída no próprio callback.
- `CollectCalculationInputs(INPUT HANDLE master,OUTPUT JsonObject inputs)`: exige transação ativa, mestre disponível com ID positivo e confirma EXCLUSIVE-LOCK NOWAIT. Não libera o lock pertencente ao caller.

Os dois callbacks de sequência também exigem transação ativa antes de obter um número; não usam MAX global. Números consumidos não são revertidos por UNDO, como nas sequências reais. Os testes não chamam NEXT-VALUE de banco real: verificam a guarda fora de transação.

A coleta cria internamente `{operation:"read",resource:"rastro",container_id:<mestre>,moeda:"real"}` e executa somente `sursum-api/programs/ContainersCustoRead.r`, no WEB-CONTEXT autenticado da chamada original, sem HTTP. O wrapper readonly existente reaplica sua autenticação e usa include Progress de parâmetros IMA diretamente NO-LOCK, sem cache. Qualquer falha do cálculo é propagada para abortar a transação externa; não vira cotação default ou confirmação parcial.

Rastro é necessário para equivalência fiscal. No PHP `bl_sincronizar_impostos/index.php:12058`, `buscarDolar` chama `buscarDolarMedio(containerId)` com `logSaldoNeg=false` por default. Comparativos ativa ajuste positivo negociado−proforma pela chamada truthy da grade e alteraria a prioridade3/médio. Teste com base tributada1000, proforma900, negociado1200, pago200USD/800BRL e cotação de saldo5 resulta médio fiscal4.8; Comparativos daria4.84615. O teste usa o núcleo puro real, sem copiar sua fórmula para o runtime.

O resultado interno é exatamente `{confirmed:true,source:"container-cost-collector",container_id,dolar_compra,dolar_di,container_snapshot}`. As duas cotações vêm do último `value` de `calculation.memory.compra_attempts`/`di_attempts`, exigindo JSON number positivo. Não escolhe uma tentativa anterior quando a última for zero. Paridade1 explícita da última tentativa é preservada conforme o núcleo; não é fallback inventado. Exige `calculation.source=calc_v1`, origem financeira `linked-payment-totals` e todas as linhas vinculadas ao mesmo container.

Snapshot contém somente os seis campos físicos exigidos pelo fiscal, com nomes originais: `vl-dolar-compra`, `vl_dolar_di`, `ordem_busca_dolar_compra`, `ordem_busca_dolar_di`, `cod_tipo_proj_dolar`, `vl_proj_dolar`. Captura antes da coleta, compara novamente depois e recusa mudança de campo/identidade. O serviço fiscal revalida esse snapshot e lê quantidades/preços/configurações sob seus próprios locks na mesma transação externa. Como o coletor readonly usa NO-LOCK, isso não constitui snapshot global ou transação distribuída sobre os bancos financeiros/ERP; a confirmação se refere à coleta executada e ao contexto do mestre.

`CompileContainersCabecalhoRuntimeTests.p` compila runtime, teste e núcleo puro e executa AMERICAN/EUROPEAN. Diagnóstico local12.8:27verificações passaram em cada formato, com COMPILER:ERROR=no nos três fontes. Usa somente stubs das duas classes de log em `.runtime/container-cabecalho-runtime-local/`, sem tocar classes canônicas; esses stubs e artefatos12.8 nunca devem ser publicados. A compilação12.2 do root usa as classes reais, e publicação/validação PASOE sursum-api/med continuam com a tarefa principal. Testes executam apenas temp-tables, não consomem sequências reais nem persistem logs/negócios.

## Callback físico de distribuição (16/10/2026)

ValidateDistributionExpense(INPUT HANDLE master,INPUT HANDLE expense,OUTPUT JsonObject proof) é callback privado do mesmo runtime. Requer transação raiz ativa, confirma EXCLUSIVE-LOCK NOWAIT no mestre e despesa, depois lê somente espec.cta_corren_custo_distr, espec.itens_container, espec.item_container_custos e espec.versoes_item_custo_container com SHARE-LOCK NOWAIT. Nenhum nome físico/query é recebido pelo JSON.

A prova valida PKs físicas INTEGER positivas, parent da despesa e do item alvo, vl_prev exatamente igual a ledger.vl_lancto e backlink ledger.despesa_container_id igual0 ou à própria despesa. Tipo4 exige item direto exato e custo_id0; tipo3 exige item direto0, custo positivo, custo.item_container_id igual ao alvo e custo→versão→container igual ao mestre. Outros tipos, vínculos mistos, órfãos ou owners divergentes falham. O backlink0 é preservado conforme fonte; não se inventa vínculo reverso. Sucesso devolve exatamente {confirmed:true,container_id,despesa_container_id,ledger_id}.

Cada prova de produção cria seus próprios quatro buffers dinâmicos em CREATE WIDGET-POOL privado do procedimento persistente. Não libera nem reusa esses buffers durante a transação, preservando os registros de prova bloqueados até o efeito fiscal. O driver DEVE excluir este runtime somente depois do commit/UNDO da transação raiz, no FINALLY externo. DELETE PROCEDURE destrói o pool e seus buffers. Uma fixture auxiliar comprovou VALID-HANDLEbefore=yes/after=no em .runtime/container-cabecalho-runtime-local/pool-proof.log. Nenhuma conexão extra é aberta.

O único handle privado de criação continua phCostReader. Somente fixtures/drivers internos confiáveis podem fornecer DistributionBuffers(OUTPUT HANDLE ledger,OUTPUT HANDLE item,OUTPUT HANDLE cost,OUTPUT HANDLE version) nesse procedimento, usando TT com os mesmos campos físicos. Produção usa phCostReader=? e nomes de tabela fixos acima. Não há nova entrada browser, política escolhida pelo cliente ou alteração da ABI20buffers do Rules.

TDD auxiliar12.8:45verificações/cultura AMERICAN/EUROPEAN, incluindo14contraprovas iniciais e4guardas adicionais. Tipos3/4 válidos, PKs exatas, pai/item/versão estrangeiros, movimento diferente, vínculos mistos, valor divergente/unknown, backlink contraditório e ausência de transação foram cobertos. As27verificações anteriores de cotação/log permanecem. Runners e stubs locais continuam isolados; não publicar .r12.8 nem classes fixture. A compilação12.2 com classes/schema reais e a validação de concorrência entre sessões permanecem do root.


## Atualização publicada em17/10/2026 — manutenção de itens

A coleta de cotações foi publicada usando `resource=cotacoes-fiscais`, em lugar de `rastro`, mantendo o mesmo contrato/snapshot e última tentativa retornada. Isso evita exigir custo unitário/itens para o recálculo fiscal. Testes12.2:47verificações/cultura; lote completo73fontes/36suítes/2502verificações por cultura.
