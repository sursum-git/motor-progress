# Custo unitário final reutilizável

`ContainersItemCustoCalculator.p` é o único núcleo puro para simulação e fechamento do custo unitário. ABI: INPUT JsonObject `poInput`, OUTPUT JsonObject `poOutput`. Não consulta DB, HTTP, sessão, relógio nem parâmetros; as temp-tables internas NO-UNDO só detectam duplicidade de IDs. Não gera versão nem escreve item_custos.

Origem rastreável: `docs/containers-item-custo-unitario-inventario.md`; cálculo efetivo `cons_itens_container_simul_calc/cons_itens_container_simul_calc_grid.class.php:13301–13504`, chamado por linha em4011; matemática idêntica no writer `bl_item_custos_gravacao/index.php:8582–8788`, que deve passar a reutilizar este núcleo. O gate inseguro de sessão e os fallbacks0 do writer4929–5002 não são reproduzidos. A geração/snapshot/fechamento de versões permanece em serviços separados que chamam as rotinas centrais.

## Entrada fechada e confirmada

```json
{
  "confirmed": true,
  "source": "item-cost-inputs-v1",
  "container_id": 123,
  "policy": {
    "log_liberar_custo_realizado": true,
    "log_priorizar_custo_previsto": false,
    "tipo_versao_valida_nf": [4, 5]
  },
  "version": {
    "versao_id": 7,
    "tipo_versao_id": 2,
    "log_versao_custo_desatualizada": false
  },
  "nfs": [
    {"documento":"NF1","serie":"A","estab":"501","nat_operacao":"3102","cod_emitente":10,"dt_emis_nota":"2026-10-01"}
  ],
  "items": [
    {
      "item_container_id": 1,
      "item_proc_compra_id": 11,
      "it_codigo": "ERP1",
      "previous_cost": {"item_custo_id":3,"vl_unit_novo":10},
      "version_cost": {
        "item_container_custo_id":8,"versao_id":7,"item_container_id":1,
        "vl_unit_prev":20,"vl_unit_realiz":30,
        "qt_alocada":100,"qt_confirm_emb":80,"qt_recebto_fisico":0
      },
      "stock": {"ima":50,"med":70},
      "movimentos_med": [
        {"dt_trans":"2026-09-01","tipo_trans":1,"quantidade":100},
        {"dt_trans":"2026-09-02","tipo_trans":2,"quantidade":20}
      ],
      "etiquetas": [
        {"nr_container":123,"situacao":3,"quantidade":20},
        {"nr_container":999,"situacao":4,"quantidade":30}
      ]
    }
  ]
}
```

O coletor interno confirma o conjunto completo atual, a versão mais recente do container, custo anterior selecionado pela regra de origem, estoques IMA/MED e vínculos/datas ERP. Falha de conexão, referência ambígua ou leitura recusada não vira array vazio/zero. Ausência legítima de custo anterior é `previous_cost:null`; ausência de snapshot é `version_cost:null` e sempre bloqueia. Itens devem cobrir o conjunto real completo, não somente uma página/seleção; o writer compara esse conjunto com o banco sob seu protocolo de locks.

Todos os campos indicados precisam existir; null só é permitido nos casos explícitos. IDs são números integrais32bits positivos; códigos inteiros de situação/tipo são tipados. Booleanos são boolean JSON e números são números JSON, sem strings culturais. Nomes são sensíveis a maiúsculas/minúsculas. Campos extras, incluindo qt_erros de sessão, são recusados. Date é string ISO YYYY-MM-DD com validação de existência e round-trip do ano/mês/dia, sem expansão silenciosa pelo runtime.

Componentes não utilizados podem ser null, preservando ausência: qt_recebto_fisico sempre é apenas memória; qt_alocada só é exigida quando qt_confirm_emb=0; realizado só quando liberado e não priorizado previsto; previsto só quando selecionado ou fallback de realizado0. Quando presentes com valor não null, continuam sujeitos ao tipo numérico. Não substituir null usado por0. Qt confirmada é sempre necessária porque escolhe o ramo.

## Fórmula e diferenças explícitas

Estoque bruto=IMA+MED. Havendo mãe (natureza começa por3), soma etiquetas situação3/4 do próprio container e demais, diferença=bruto−próprio−outros; estoque ajustado=max(bruto−próprio,0). Sem mãe, não subtrai etiquetas/clampa e as quantidades de análise são0, conforme ramo de origem.

Quantidade do container é confirmada se diferente de0, senão alocada; quantidade NF é confirmada ou0. Unitário do container é previsto quando priorizado ou realizado não liberado; senão usa realizado não zero, com fallback explícito para previsto quando realizado0.

Valor container=quantidadeContainer×unitárioContainer; valor estoque=estoqueAjustado×unitárioAnterior; total=soma dos dois; ponderação=quantidadeContainer+estoqueAjustado. Se total>0 e ponderação>0, novo unitário=ROUND(total/ponderação,2); senão0 com aviso de ramo matemático explícito. Não há divisão por zero. Depois, ausência de movimento MED anterior substitui o resultado diretamente pelo unitárioContainer, **sem ROUND2**. Cálculos/saída mantêm até10casas onde o PHP não arredonda.

Movimento anterior e saldo histórico usam somente MED, data estritamente menor que a data mãe: tipo1 soma, demais tipos subtraem. Data igual não é anterior. Sem mãe usa o default legado2001-01-01 com aviso de origem. Múltiplas mães com datas diferentes são erro; datas iguais são equivalentes e geram aviso. Pertinência do tipo da versão à lista NF é exata, corrigindo strpos da primeira posição/substrings. Parâmetro tipo_versao_valida_nf pertence à include IMA direta, sem cache; o núcleo recebe lista numérica interna já confirmada.

Custo anterior ausente só é erro financeiro quando há movimento anterior e saldo histórico positivo. Fora dessa condição, o ramo comprovado usa anterior0/IDorigem0 e registra aviso/memória. Isso representa ausência confirmada permitida pela regra, nunca erro de DB convertido em0.

## Resultado e gate do conjunto

Sucesso: `success:true,data:{source:'container-item-cost-v1',container_id,versao_id,items,warnings}`. Cada item retorna IDs e campos legados:

```text
container_id,item_container_id,item_proc_compra_id,it_codigo,
qt_saldo_estoq,qt_diferenca,qt_etiquetas_container,qt_restante,qt_container,
vl_unit_container,vl_tot_container,vl_unit_atual,vl_total,qt_total,vl_unit_novo,
item_custo_id_orig,item_container_custo_id,qt_nota_mae,qt_saldo_estoq_atu,memory
```

Memory contém source, reference_date, has_mother_nf, prior_movement_med, prior_balance_med, prior_cost_missing, stock_ima/med, stock_value, unit_container_origin, quantity_origin, qt_recebto_fisico_unused (null preservado) e unit_result_origin. As origens distinguem média ponderada/ROUND2 do override sem movimento e do ramo explícito0. O exemplo acima resulta em18.89: estoque bruto120, ajustado100, container80×30 e estoque100×10, total3400/180.

Avisos estruturados: `{code,message,origin:'container-item-cost-v1',item_container_id?}`. Códigos: MOTHER_DATE_LEGACY_DEFAULT, MULTIPLE_MOTHER_SAME_DATE, PREVIOUS_COST_ABSENCE_ALLOWED, MOTHER_STOCK_CLAMPED e LEGACY_NONPOSITIVE_RESULT.

Falha: `success:false,error:{code:'ITEM_COST_VALIDATION',status:422,message,error_count,global_errors,items:[{index,item_container_id?,errors}]}`. Não contém data nem resultado parcial gravável. Erros são agregados de TODOS os itens, inclusive o último, com múltiplos diagnósticos semânticos quando possível. Falha estrutural de um item não impede validar os demais. Versão stale, código ERP vazio, snapshot ausente/trocado, custo anterior exigido ausente e IDs repetidos bloqueiam. IDs de snapshot de custo não podem ser reutilizados por itens diferentes. Ausência de itens/contexto também bloqueia.

Simulador e writer chamam essa mesma rotina. Writer não consulta contador de erro de sessão, não substitui falha por0 e não inicia gravação até todo o conjunto passar; então revalida referências/versão/inputs de leitura conforme a transação real. IDs, datas de gravação, autoria, sequências, associação ao item_custos, snapshots e log pertencem ao writer central separado.

## Evidência preparada

Diagnóstico OpenEdge12.8:71verificações em AMERICAN e71 em EUROPEAN; serviço/teste compilaram sem erros. Runner `CompileContainersItemCustoTests.p`, logs privados `.runtime/container-item-custo-local/compile-containers-item-custo.log` e logs por cultura. Nenhum DB/SQL/HTTP/escrita de negócio foi usado. RED inicial293 por núcleo ausente; RED adicional para null de componente não utilizado e snapshot duplicado antes das respectivas implementações.

Testes incluem fórmula ponderada e ROUND2, prioridades/liberação/fallback, precisão30.1234567891 sem movimento, corte de data estrito, saldo anterior zero/positivo sem custo, default2001, membresiaNF primeira posição e substring14, mães com datas iguais/diferentes, estoque/etiquetas/clamp, quantidade confirmada/alocada, ramo matemático0 com aviso, null usado versus não usado, cultura/tipos/datas, stale/ownership/duplicidade, entrada imutável e conjunto multi-item via temp-table real. Compilação12.2 e integração com coletor/fechamento/PASOE continuam na tarefa principal; não há publicação implícita deste núcleo.
