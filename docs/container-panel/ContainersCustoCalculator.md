# Núcleo puro de custo do container

`ContainersCustoCalculator.p` recebe `INPUT JsonObject` e devolve `OUTPUT JsonObject`. Não conecta bancos, lê sessão, faz chamadas HTTP, usa sequências ou grava negócio. O chamador deve ler e autorizar todos os componentes no servidor; o navegador não é fonte confiável para estes valores. O núcleo não substitui o coletor Progress com buffers fixos.

Estado em 16/10/2026: testes executados em OpenEdge 12.8 local, **somente diagnóstico**. Os `.r` locais ficam em `.runtime/container-custo-local` e nunca devem ser publicados. Compilação 12.2/.42, sincronização canônica, publicação e validação PASOE pertencem à entrega de integração do responsável principal. Nenhuma publicação é comprovada por este documento.

## Contrato de entrada v1

Todos os objetos/listas indicados são obrigatórios; campos desconhecidos e diferenças de caixa são recusados. Valores numéricos devem ser JSON number, booleanos JSON boolean; `null`, números em string e separadores culturais são recusados em componentes matemáticos. `erp_real:null` é a exceção intencional: significa leitura confirmada sem registro ERP correspondente, não falha/consulta ainda não feita. Quantidades e preços negativos são recusados; descontos/distribuições/pagamentos podem ter sinal porque representam saldos/movimentos agregados.

```json
{
  "mode": "itens",
  "currency": "real",
  "calculationBasis": "current",
  "container": {
    "nr-container": 123,
    "ordem_busca_dolar_compra": "2,1",
    "ordem_busca_dolar_di": "4,1",
    "cod_tipo_proj_dolar": 1,
    "vl_proj_dolar": 0,
    "vl-dolar-compra": 5,
    "vl_dolar_di": 4.8,
    "log_versao_custo_desatualizada": false
  },
  "quotation": {"valor": 4.9, "data": "2026-10-16"},
  "payments": {"real": 1000, "dolar": 200},
  "discounts": {"credito_real": 0, "credito_dolar": 0, "total_real": 0, "total_dolar": 0},
  "expenses": {"tributado": 100, "proforma": 150, "negociado": 200},
  "items": [{
    "item_container_id": 1,
    "qt_alocada": 10,
    "qt_confirm_emb": 0,
    "qt_recbto_fisico": 0,
    "vl_base_tributacao": 100,
    "vl_custo_dolar": 90,
    "vl_negociado": 80,
    "despesa_item": {"tributado": 30, "proforma": 30, "negociado": 40},
    "distribuicao_real": 100,
    "desconto_real": 20,
    "desconto_dolar": 10,
    "erp_real": {"vl_custo": 1000, "vl_desp": 200, "perc_rateio": 0.6}
  }]
}
```

Esse exemplo é sintético, não representa registro consultado e não serve como default. `nr-container` e `item_container_id` são inteiros positivos int32; IDs repetidos no array são inválidos. O array admite 1..10000 itens. Zero itens ou dados ausentes geram erro, sem custo fictício zero.

| Objeto | Origem que o coletor deve confirmar |
|---|---|
| `container` | Campos físicos de `espec.pp-container`; contexto autenticado. `calculationBasis=version` exige fonte de versão confirmada e recusa flag obsoleta. `current` calcula dados atuais e apenas informa a obsolescência da versão salva. |
| `quotation` | Última cotação válida de `hist_cotacoes_bc`, por `getDadosUltCotacao`; data ISO real `YYYY-MM-DD`. Não há busca online aqui. |
| `payments` | Resultado de `buscarTotPagoContainer` nas duas moedas, títulos associados e valores financeiros; zero somente após consulta confirmada. |
| `discounts` | Agregados de `buscarDescontosCreditosUtiliz` e `buscarDescontosUtiliz`; separar crédito e desconto comum. |
| `expenses` | `getTotDespContainerRatItem` por base tributado/proforma/negociado; soma autorizada das despesas gerais que participam do rateio, separada das despesas vinculadas a cada item. |
| `items` | `itens_container` unido a `itens_proc_compra`; preços físicos preservados. `despesa_item` é o resultado de `getTotDespItemContainer` por base; `distribuicao_real` é `getTotalDistrParaItemContainer`; descontos são os do item. |
| `erp_real` | Linha ERP que corresponde ao código do item, com `vl_custo`, `vl_desp`, `perc_rateio` de `buscarCustoRealItens`. O coletor deve resolver cardinalidade/código; não escolher arbitrariamente uma linha entre vários resultados. |

`mode` aceita `itens`, `comparativos`, `resumo`, `rastro` e o perfil interno `gerar_versao`; `currency` aceita `real`, `dolar`. `calculationBasis` é metadado de proveniência e aceita `current`, `version`. O núcleo não valida no banco se a alegação do chamador é verdadeira; por isso ele é interno, atrás do coletor autorizado. Gerar uma nova versão usa `current`, pois `version` significa uma base histórica já salva e mantém a guarda contra versão obsoleta.

## Fórmulas e origens

Referências relativas a `sources/scriptcase/containers/`. Origem principal Itens: `grid_itens_container/grid_itens_container_grid.class.php:564`, `:15010`, `:15262`, `:20429`; Comparativos: `grid_itens_container_comparacao/grid_itens_container_comparacao_grid.class.php:579`, `:14499`, `:18578`.

| Cálculo | Regra portada |
|---|---|
| Totais em dólar | Por base, soma preço×confirmada; **se a soma confirmada global for zero**, usa soma preço×alocada. Tributado usa `vl_base_tributacao`, proforma usa `vl_custo_dolar`, negociado usa `vl_negociado` (`Itens:15010–15060`). |
| Base do item | Quantidade confirmada diferente de zero, senão alocada. Valor em dólar = preço×quantidade − desconto do item. Itens/Resumo usam preço tributado; Comparativos, negociado (`Itens:15355–15366`; `Comparativos:14592–14603`). |
| Dólar saldo | Prioridades compra com opção 3/médio ignorada, impedindo recursão. 1=última cotação (com projeção), 2=manual compra, 3=médio, 4=DI. Projeção2 soma valor;3 multiplica por `1+percentual/100`. Prioridades são validadas integralmente. Zero/1 tentam próxima; paridade 1 explícita na última opção é preservada com aviso (`Itens:buscarDolar`, equivalente ao inventário fiscal `S:11979–12082`). |
| Média de pagamentos | Se os dois totais pagos forem positivos: real/dólar; caso contrário zero. Se crédito/desconto real for zero, converte o componente dólar pela média de pagamentos positiva, senão pela cotação saldo (`Itens:20447–20535`). |
| Ajuste negociado | Soma à base tributada somente `max(total_negociado−total_proforma,0)`. A chamada efetiva de custo passa string não vazia (`proforma`/`negociado`) ao segundo argumento booleano de `buscarDolarMedio`; ambas ativam o ramo `logSaldoNeg==true`. O Rastro usa a chamada direta do painel com default false e não recebe esse ajuste; a origem consta em `memory.dolar_medio_adjustment_origin` (`Itens:15312–15316`, `:20539–20550`; `Comparativos:14549–14553`). |
| Dólar médio | Saldo dólar = base ajustada−crédito dólar−desconto dólar−pago dólar. Numerador = pago real+crédito real convertido+desconto real convertido+saldo positivo×cotação saldo. Se saldo negativo, aumenta denominador pelo módulo do saldo. Médio = round(numerador/denominador,5) (`Itens:20552–20616`). |
| Peso/rateio | Valor líquido do item/base global da modalidade, somente se valor item positivo. Despesa positiva: peso×despesa geral + distribuição assinada + despesa específica do item. Distribuição é negativa do total recebido pelo item. Sem despesa geral positiva, o legado aplica distribuição só ao campo `sem_distr_custo` (`Itens:15370–15393`). |
| Modos | Itens chama tributado/real ERP habilitado/distribuição desabilitada; Comparativos chama negociado/real ERP desabilitado/distribuição desabilitada. Resumo usa a intenção tributada com distribuição habilitada do default, moeda nomeada obrigatória e aviso de divergência de assinatura. |
| Geração de versão | Perfil interno `gerar_versao`: negociado, realizado ERP habilitado e distribuição desabilitada, preservando o ajuste truthy da média dos itens. Fonte `bl_item_custos/index.php:15949–15965`. O médio mestre é obtido separadamente pelo mesmo núcleo em Rastro/defaultfalse, como `:15967`; o adapter reutiliza os mesmos insumos capturados e não reconsulta bancos nem copia fórmula. |
| Conversão | Em dólar, mercadoria permanece em dólar e despesas são divididas pelo médio; em real, mercadoria é multiplicada pelo médio. Unitário previsto divide pela quantidade da própria linha (`Itens:15401–15423`). |
| Custo realizado | Mercadoria ERP = `(vl_custo−desconto_real_item)/fator`; despesa ERP=`vl_desp/fator`; desconto=`desconto_real_item/fator`; crédito=`credito_real_original×perc_rateio/fator`. Total=mercadoria+despesa−desconto+crédito. A **dupla subtração do desconto** é observada no legado e preservada, sem corrigi-la silenciosamente. Unitário real somente com total positivo e quantidade confirmada positiva (`Itens:15441–15472`). |
| Quantidade saldo | Recebida física não zero menos alocada; senão confirmada menos alocada (`Itens:15476–15480`). |

O PHP `buscarVlItemProcCompra(...,'proforma')` cita `vl_custo_real`, mas o dicionário de `itens_proc_compra` não possui esse campo. O contrato não o recebe nem inventa alias: os modos atuais usam preço de item tributado/negociado, e apenas o agregado proforma usa o campo existente `vl_custo_dolar`.

## Saída e divergências tratadas explicitamente

Sucesso: `{success:true,data:{mode,currency,calculationBasis,costType,dolar_medio,cotacao_saldo,dolar_compra,dolar_di,memory,items,totals,warnings}}`. `items` preserva os nomes de resultado do PHP (`vl_desp_prev`, `vl_merc_prev`, `vl_total_prev`, `vl_unit_prev`, versões `sem_distr_custo`, campos reais e `qt_saldo`); adiciona peso, quantidade-base e `actual_source`. `memory` contém bases, ajuste, média paga, descontos convertidos, saldo, numerador/denominador e tentativas ordenadas de cotação com valor/aceitação. Tudo é JSON estruturado; não retorna HTML legado.

Totais previstos são somas dos itens. Total realizado é `null` quando faltar registro ERP confirmado em qualquer item. Comparativos/Rastro retornam zero nos campos realizados e `actual_source=disabled_by_legacy_call`, pois a chamada de origem expressamente desabilita esse ramo; isso não afirma custo ERP de zero. Itens/Resumo com `erp_real:null` devolvem campos realizados `null`, `actual_source=confirmed_no_erp_record`, e `totals.actual_complete=false`.

A chamada do Resumo `buscarVlCustoTotalContainer($container,'','','real')` difere de sua assinatura `($containerId,$moeda)`. O núcleo recebe moeda nomeada, calcula os componentes tributados e devolve **previsto e realizado separados**, com aviso. Não decide pelo quarto argumento, não escolhe um total comercial como se a divergência estivesse resolvida e não calcula vendas/margens ausentes. O coletor/página deve mostrar o aviso e identificar a base; eventual total por situação comercial exige regra adicional confirmada.

Erros são `{success:false,error:{code,message,status:422}}`, sem `data` parcial. Códigos: `INVALID_REQUEST`, `ZERO_DENOMINATOR`, `MISSING_RATE`, `STALE_VERSION`. Quantidade-base zero, base global zero e denominador médio zero recusam cálculo. Dólar médio sem componentes positivos não recebe a paridade 1 fictícia do fallback PHP. Um valor explícito1 recebido permanece distinguível no rastro, com aviso da regra legada.

Valores são DECIMAL com10 casas nos componentes/resultados e arredondamento explícito10 na saída; dólar médio usa 5 casas. Não há máscara monetária, troca de separador ou conversão numérica via `STRING`. A data é validada por ano/mês/dia e serializada como DATE ISO, sem depender da cultura. Os retornos unitários são reinicializados por linha; o núcleo não reproduz vazamento de valor da linha anterior quando o PHP não entra no ramo de atribuição.

## Testes

`CompileContainersCustoTests.p` compila serviço/teste e executa a suíte em AMERICAN/EUROPEAN. O runner deve ser executado em staging isolado; não publicar os testes. Logs esperados: `compile-containers-custo.log`, `containers-custo-tests-AMERICAN.log`, `containers-custo-tests-EUROPEAN.log`. A evidência local atual tem87verificações em cada cultura, incluindo o perfil privado de geração; `CompileContainersVersaoCostTests.p` também roda as suítes integradas de coletor/adapter. A execução12.2 e a validação PASOE precisam ser registradas pela integração final.

Fixtures literais verificam: duas linhas e isolamento, quantidade global versus individual, preços tributado/negociado, custos realizados/ausentes, desconto duplo legado, despesas específicas, distribuição do Resumo, conversão real/dólar, cinco/dez casas exatas, DATE ISO, prioridade e projeção, paridade 1 rastreável, pagamentos/créditos/descontos, saldo negativo, ajuste negociado, versão obsoleta, zero divisor, nulos, strings culturais, booleano em string, IDs repetidos, campos desconhecidos/caixa e prioridade inválida após a primeira disponível. O RED inicial mostrou falta do cálculo; novos testes de lista de prioridades e campos com caixa diferente falharam antes do endurecimento. Os testes comparam números esperados calculados manualmente, sem reproduzir o calculador no teste.




## Atualização publicada em17/10/2026 — manutenção de itens

Modo privado `fiscal_inputs` reutiliza o núcleo de prioridades, projeções e média do rastro. Aceita itens vazios/quantidades zero; não calcula custo unitário ou ERP. Média sem divisor fica zero e segue prioridades configuradas, sem paridade1 inventada. Modos de custo preservam seus guards.116verificações12.2/cultura.
