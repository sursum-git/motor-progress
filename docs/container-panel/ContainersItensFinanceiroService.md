# Financeiro privado do ciclo dos itens

`ContainersItensFinanceiroService.p` participa da transação do CRUD dos itens. Não abre rota, não confirma transação, não publica auditoria e não converte moedas. A sequência e os valores dos títulos vêm exclusivamente dos callbacks privados do runtime.

## ABI

Ordem dos parâmetros INPUT: `phItems`, `phPurchaseItems`, `phPurchases`, `phLedger`, `phOrderPayments`, `phContainerPayments`, `phAllContainers`, `phRuntime`, `poPolicy`, `poContext`; OUTPUT `poResponse`.

| Buffer | Tabela e campos físicos utilizados |
|---|---|
| phItems | itens_container: item_container_id, container_id, item_proc_compra_id, qt_alocada, qt_confirm_emb |
| phPurchaseItems | itens_proc_compra: item_proc_compra_id, proc_compra_id, qt_comprada, vl_custo_dolar, vl_negociado |
| phPurchases | procs_compra: proc_compra_id, fornecedor_id, log_considerar_previsao |
| phLedger | cta_corren_fornec_imp: cta_corren_fornec_imp_id, fornecedor_id, data, historico, cod_tipo_movto, vl_lancto, cod_acao, login, data_hora, num_id_tit_ap, item_proc_compra_id, item_container_id, transacao_id |
| phOrderPayments | pagtos_proc_compra: num_id_tit_ap, proc_compra_id; PK única composta |
| phContainerPayments | pagtos_container: num_id_tit_ap, container_id |
| phAllContainers | pp-container: nr-container; fornecedor do mestre não restringe fornecedores dos pedidos |

Policy interna fechada: `{actor:{login:string}}`, login autenticado entre1e128caracteres; FORMAT do dicionário não limita armazenamento. Contexto fechado: `{operation:'create'|'update'|'delete',container_id:integer,before:object,after:object}`. O lado ausente usa `{}`; aceita também `null` para compatibilidade interna. Os snapshots presentes contêm ao menos item_container_id, container_id, item_proc_compra_id, qt_alocada e qt_confirm_emb. Pai e item do pedido são imutáveis na atualização. Na criação/atualização, o estado after deve corresponder ao buffer atual; na exclusão, o item já deve ter sido removido na transação chamadora.

Callbacks do procedimento persistente confiável `phRuntime`:

```abl
NextLedgerId(OUTPUT INTEGER).
CollectContainerPayments(INPUT masterBuffer AS HANDLE, OUTPUT rows AS JsonArray).
CollectOrderPayments(INPUT purchaseBuffer AS HANDLE, OUTPUT rows AS JsonArray).
```

Cada array contém exatamente uma linha `{num_id_tit_ap:integer,vl_dolar:number,vl_real:number}` por título fisicamente ligado ao dono. Ausência, duplicidade, título extra ou valor desconhecido falham antes da persistência. Os valores devem vir do helper central de pagamentos; não existe fórmula cambial neste serviço.

Retorno: `{success:true,changes:[{resource:'cta_corren_fornec_imp',operation:'create',recordId:integer,before:{},after:object}],warnings:[]}`. `after` contém os 13 campos físicos e `container_id` sintético da operação de origem. O campo sintético não é gravado no ledger. Tipo4 mantém item_container_id=0, inclusive quando rateia outro item do pedido fora do container. transacao_id permanece0, conforme default legado aprovado. O chamador compõe os eventos e só confirma auditoria após seu próprio commit. Falhas são propagadas por THROW e exigem UNDO do chamador.

## Regras portadas e evidência

Fonte principal `sources/scriptcase/containers/form_itens_container/form_itens_container_apl.php`:

- Criação dos 13 campos do ledger e supressão de valor zero:7112–7161. Sequência de produção é responsabilidade de NextLedgerId.
- Criação de alocação: estorno dos grupos tipo4 dos títulos vinculados ao container (7197–7215,7345–7393), ação1, seguido de rateio tipo5 (7898–8027). A existência de tipo4 é a evidência de pagamento do pedido usada por verifTitPedImp7180–7193.
- Tipo5: peso proforma; denominador usa soma embarcada quando diferente de zero e soma alocada caso contrário; numerador de cada item recorre à alocada quando seu valor embarcado é zero (11410–11460). `ROUND(alvo + saldo5,2)` gera lançamento negativo, ação1 se delta positivo e ação3 caso contrário. Denominador zero segue o ramo explícito de alvo zero do legado.
- UPDATE também sincroniza diferença tipo10 (11984–12060): `ROUND((confirmada-alocada)*negociado-saldo10,2)`, ação2, título0. Se confirmada zera ou iguala alocada, preserva tipo10 anterior e emite aviso. Mais de um grupo anterior é ambíguo e falha.
- DELETE: rateio5 dos remanescentes; grupos5 do item removido geram tipo6 com sinal inverso e ação3 (7292–7343); pedido habilitado re-rateia títulos elegíveis em tipo4 por quantidade comprada vezes negociado (7686–7815). Peso total zero falha antes de obter IDs.
- Título ligado a container com itens bloqueia re-rateio do pedido (9055–9067). Mais de um dono de título falha explicitamente. Fornecedor diferente do mestre é permitido, conforme ramo expresso7983–7988.

Não implementa manutenção global de pedido, previsão tipo3, fórmulas de custos, versões ou sincronização fiscal.

## Transação e consistência

Exige TRANSACTION ativo. O chamador mantém mestre/item bloqueados. O serviço obtém mestre EXCLUSIVE NOWAIT, pedidos EXCLUSIVE em ordem de PK, itens do pedido SHARE em ordem de PK e ledger relevante EXCLUSIVE em ordem de PK. Referências são descobertas NO-LOCK e os valores financeiros são relidos sob bloqueio antes do plano. Links de títulos e conjuntos de itens são lidos SHARE NOWAIT. Não libera locks antes do efeito; a transação raiz pertence ao chamador.

Todos os deltas são planejados e validados antes de chamar NextLedgerId. As linhas virtuais de planejamento têm a mesma precisão de centavos da tabela para preservar a leitura dos saldos entre fases. Ledger físico vl_lancto é DECIMALS2. Não há serialização de novos inserts externos nos conjuntos consultados; a consistência depende também de outros escritores respeitarem os mesmos bloqueios dos pedidos/itens. Os testes TT não demonstram concorrência real do ERP.

## Verificação

Runner `CompileContainersItensFinanceiroTests.p`, fixture `ContainersItensFinanceiroFixture.i`, testes `ContainersItensFinanceiroTest.p`. OpenEdge12.8 auxiliar, UTF-8, AMERICAN e EUROPEAN:40 verificações por cultura. Casos: tipos4/5/6/10, fornecedores diferentes, ausência de delta, ramo legado tipo10 mantido, flag de previsão, elegibilidade, ambiguidade de título, zero peso, arredondamento/sinal, callback incompleto/duplicado/null, contexto, login128 preservado/129 rejeitado, sequência colidente e rollback após primeiro lançamento. Somente TT e sequência double; nenhuma sequência ou linha de negócio real foi usada. Compilação12.2/publicação são responsabilidade do root.
