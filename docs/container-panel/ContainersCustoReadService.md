# Coletor somente leitura de custo — calc_v1

`ContainersCustoReadService.p` coleta dados reais por buffers fixos e chama `ContainersCustoCalculator.p`. Não recebe tabelas/campos/conexões do cliente e não escreve negócio, logs ou sequências. Todas as consultas persistidas usam `NO-LOCK`. Não há alegação de snapshot transacional único entre bancos: dados podem mudar entre consultas; alterações de negócio continuam separadas deste serviço.

## ABI interna fechada

Parâmetros `INPUT HANDLE`, nesta ordem:

1. `phContainer` — espec.pp-container
2. `phItens` — espec.itens_container
3. `phItensProc` — espec.itens_proc_compra
4. `phProcs` — espec.procs_compra
5. `phEmpresas` — espec.empresas
6. `phEmpDesp` — espec.empresas_despesa
7. `phDespesas` — espec.despesas
8. `phDespContainer` — espec.despesas_container
9. `phDistr` — espec.cta_corren_custo_distr
10. `phDescontos` — espec.descontos_importacao
11. `phMotivos` — espec.motivos_desconto
12. `phCtaDesc` — espec.cta_corren_desconto
13. `phCotacoes` — espec.hist_cotacoes_bc
14. `phItemCustos` — espec.item_container_custos
15. `phVersoes` — espec.versoes_item_custo_container
16. `phNfs` — espec.nfs_container
17. `phPedVendaExt` — espec.ped-venda-ext
18. `phItemDocMed` — ems2med.item-doc-est
19. `phDocMed` — ems2med.docum-est
20. `phItemDocIma` — ems2ima.item-doc-est
21. `phDocIma` — ems2ima.docum-est
22. `phPedVendaMed` — ems2med.ped-venda
23. `phPedItemMed` — ems2med.ped-item
24. `phPedVendaIma` — ems2ima.ped-venda
25. `phPedItemIma` — ems2ima.ped-item

Depois: `INPUT JsonObject poFinancial`, `INPUT JsonObject poPolicy`, `INPUT JsonObject poRequest`, `OUTPUT JsonObject poResponse`.

O wrapper autenticado define os buffers e as conexões, de forma fixa. O coletor deriva a empresa pelo primeiro dígito de `pp-container.cod-estabel`, encontra `empresas.cod_emp_ems2` e escolhe exclusivamente MED para5 ou IMA para1. Falta de conexão exigida retorna `COST_CONFIGURATION`/503; não tenta outra base. Itens/Resumo exigem os dois buffers documentais do ERP escolhido mesmo se não houver NF vinculada; Rastro/Comparativos não fazem consulta de realizado. Resumo também exige os buffers de venda do ERP escolhido e `ped-venda-ext`.

`poFinancial` é **o objeto `data` confirmado** de `ContainersPagamentoTotalsService.p`, não a lista filtrada da grade Pagtos:

```json
{"container_id":123,"payments":{"real":1000,"dolar":200},"confirmed":true,"source":"linked-payment-totals"}
```

O helper financeiro privado recebe `phContainer,phPagtos,phTitAp,phValTitAp,poPolicyFinanceiro,piContainer,OUTPUT poResponse`. Segue os IDs de `pagtos_container` e a regra de moeda, sem filtros de empresa/fornecedor/data/estorno aplicados pela grade. Ambiguidade ou valor desconhecido são erros do helper; o wrapper deve propagá-los antes de chamar este coletor. Não somar a grade filtrada para compor o custo.

`poPolicy` contém somente estes valores internos, consultados pelo wrapper com a include sem cache:

```json
{"naturezas_nota_mae":"3102,3103","cod_despesa_pis":2,"cod_despesa_cofins":3}
```

Origem: `sursum-api/includes/parametros_ima.i`, `getListaNatOperNotaMae()` (consulta `nat_operacao_nf_mae`) e `buscarParametroIma("cod_despesa_pis","")`/`buscarParametroIma("cod_despesa_cofins","")`. A include faz leitura direta `NO-LOCK` de espec.im-param, sem cache. IDs devem ser validados pelo wrapper; zero/ausente não autoriza inferir imposto recuperável. Quando existe tributo positivo na NF, o coletor exige ID e vínculo empresa/despesa válidos. Não há leitura de parâmetro no navegador nem cache no coletor.

## Requisição externa e resultado

Entrada permitida: `{operation:"read"|"get",resource:"itens"|"resumo"|"comparativos"|"rastro",container_id,id?,moeda?:"real"|"dolar"}`. Moeda inicial explícita do serviço é real. `id` é inteiro positivo, permitido somente em `get` e obrigatório nesse caso. É sempre filtrado dentro do container autorizado; não há detalhe global por ID. Campos extras, caixa diferente, operações de escrita e dados financeiros externos são recusados.

Sucesso `read`: `{success:true,data:[...],calculation:{source:"calc_v1",financial_source,memory,raw_erp,warnings,ultima_versao_id,versao_desatualizada}}`. `get` retorna um objeto em `data`. Erro: `{success:false,error:{code,message,status}}`, sem resultado parcial. Códigos do coletor: `INVALID_REQUEST`, `NOT_FOUND`, `COST_CONFIGURATION`, `FINANCIAL_CONTEXT_MISMATCH`, `COST_DATA_INCOMPLETE`, `COST_AMBIGUOUS_DATA`, `COST_POLICY_INVALID`, `ZERO_DENOMINATOR`; erros do núcleo são propagados integralmente.

| Recurso | Chave e campos principais |
|---|---|
| Itens | `item_container_id`; todos os campos do núcleo e `container_id,descricao,codigo_erp,item_proc_compra_id,proc_compra_id,qt_alocada,qt_confirm_emb,qt_recbto_fisico,dolar_medio,moeda,ultima_versao_id,versao_desatualizada,vl_unit_prev_versao,vl_unit_real_versao`. |
| Comparativos | Mesma estrutura de Itens, cálculo atual negociado com custo ERP desabilitado conforme chamada legada. Última versão é max(versao_id) **do container**, e snapshot do item é procurado nessa versão. Ausência é `null`; não substitui cálculo atual nem inventa snapshot. |
| Resumo | Uma linha com PK `container_id`; `moeda,vl_total_prev,vl_total_real,actual_complete,dolar_medio,cotacao_saldo,vl_saldo_dolar,pagamentos_real,pagamentos_dolar,vendas_prev_real,vendas_realizadas_real,cotacao_venda`. Custos seguem moeda pedida; campos explicitamente `_real` de vendas/pagamentos continuam em real. O aviso de assinatura divergente do PHP permanece em `calculation.warnings`; previsto e realizado não são confundidos. |
| Rastro | Linhas com PK `rastro_id`, `container_id,etapa,valor,origem`. Componentes: bases tributado/proforma/negociado, ajuste, base médio, média de pagamentos, descontos/créditos convertidos, saldo, numerador, denominador e médio. Tentativas detalhadas de prioridade estão em `calculation.memory`. |

O Rastro do painel corresponde à chamada direta `buscarDolarMedio(container)` com `logSaldoNeg=false`. Itens/Comparativos/Resumo usam o ajuste positivo negociado–proforma observado nas chamadas de custo com string não vazia no parâmetro booleano. O núcleo registra essa diferença em `dolar_medio_adjustment_origin`.

Reutilização privada para geração de versões: a policy interna pode definir `calculation_profile="version"` e `capture_input=true`, ambos tipados e jamais aceitos no request externo. Exige coleta read/itens/real. O coletor seleciona modo puro gerar_versao (negociado/ERP habilitado/distribuição desabilitada) e, somente após sucesso integral, acrescenta input_snapshot como clone profundo dos insumos exatos do núcleo. As quatro consultas normais não o exportam. ContainersVersaoCostAdapter reutiliza esse input para dólar e médio mestre Rastro, sem segunda coleta ou fórmula duplicada. Nenhuma assinatura de buffers/request/read/get existente foi alterada.

Todas as linhas reais dos quatro recursos também contêm `calculation_source="calc_v1"`, `calculation_warning` (avisos unidos com quebra de linha, limitados a4000caracteres), `quotation_date`, `quotation_latest_date` e `quotation_warning` (código ou null). O cliente genérico com itemsPath=data pode descartar metadados irmãos; esses campos permitem mostrar procedência/datas/avisos na grade/formulário nativos. O objeto calculation completo permanece no resultado.

Container válido sem itens retorna read[] em Itens/Comparativos e get404; não inventa linha nem calculation confirmado. Resumo/Rastro retornam COST_DATA_INCOMPLETE422 específico por ausência de itens, antes de chamar o núcleo. O coletor valida pai, empresa e contexto financeiro antes desse tratamento; consulta vazia não depende de buffer ERP documental.

## Coleta e reconciliação

Despesas gerais/específicas seguem vínculos empresa/despesa e `log_custo=1`, com `item_container_id=0` para gerais. Descontos comuns exigem motivo com `log_considerar_custo=true` e `log_credito=false`; créditos vêm de `cta_corren_desconto` e valor utilizado×cotação do desconto. Distribuição soma movimentos tipo4 por item. Quantidades, preços e referências ausentes retornam erro. Consulta sem registros de desconto/despesa/distribuição confirmada permite soma zero; isso é distinto de buffer indisponível ou valor desconhecido.

Cotação consulta série1 e usa data mais recente entre registros válidos (`log_ok` ou `log_manual`) e valor não zero; valores divergentes na mesma última data retornam ambiguidade. Não faz busca online. Essa seleção evita reproduzir a subconsulta PHP que pode ocultar uma cotação válida anterior quando a última data contém somente registro inválido; a data/valor usados estão explícitos na memória para validação real.

NF exige documento/serie/natureza/emitente e estabelecimento do ERP escolhido; não concatena chaves. O cabeçalho deve existir univocamente; vínculo repetido, documento sem itens ou referência de outra empresa retornam erro. As strings persistidas são escapadas para literal ABL, inclusive apóstrofo, aspas, tilde e controles; não entram como expressão de consulta.

As extents `preco-total[1]` e `despesas[1]` do item de NF são usados conforme `pro_element(...,1,1)` do PHP. NF mãe é pertinência exata na lista de naturezas (cada entrada pode estar entre apóstrofos). Por item de NF mãe, despesa ajustada = despesa original−PIS−COFINS+parcela PIS custo+parcela COFINS custo; parcela = tributo/alíquota×percentual_custo do vínculo empresa/despesa. Tributo zero não exige divisão; tributo não zero com alíquota zero retorna erro. Notas de outra natureza agregam mercadoria como despesa, conforme fórmula observada.

Agregação correta, autorizada no planejamento desta conversão: soma todas as linhas por item ERP; total de mercadoria das mães é denominador; fração do item = mercadoria mãe do item/total mães; custo pago do item = total pago real×fração; despesa = despesas mães ajustadas+mercadorias das outras naturezas. Corrige os defeitos de `strpos` na posição zero, emissão do último grupo antes de acumulá-lo e fração100 no caso de linha única. O aviso `calc_v1` acompanha o resultado. `raw_erp` traz chaves da NF, item, pertinência, mercadoria, despesa original, PIS/COFINS originais/parcelas custo e despesa ajustada. Não modifica registro fiscal algum. A dupla subtração de desconto e os sinais de crédito da fórmula posterior do núcleo continuam preservados e documentados.

No realizado, códigos ERP repetidos entre itens do container são recusados com COST_AMBIGUOUS_DATA, pois o agregado por código não pode ser atribuído inteiro a cada ocorrência. Item da NF sem correspondência em item alocado é COST_DATA_INCOMPLETE; não entra no denominador para depois desaparecer da saída com actual_complete=true. Nenhum rateio por ocorrência foi inventado. Comparativos/Rastro continuam sem consultar realizado ERP.

A dependência do núcleo resolve primeiro o caminho fixo `sursum-api/programs/ContainersCustoCalculator.r`; se ausente, busca somente o nome fixo `ContainersCustoCalculator.r` no PROPATH explícito/runner TT. Ausência retorna COST_CONFIGURATION503. Não executa fonte.p para compilação em produção nem usa caminhos vindos da requisição. Um probe12.8 em layout semelhante ao PASOE, com o .r apenas em programs e sem programs no PROPATH, retornou sucesso1070; ao retirar somente a cópia local do calculador retornou COST_CONFIGURATION.

Vendas do Resumo unem `ped-venda-ext`, `ped-venda` por pedido/estabelecimento, e `ped-item` por cliente/pedido cliente; excluem situação6. Valor é quantidade×preço; desconto é valor×`((20−cod-priori) modulo10)/10`; o Resumo legado **soma** valor+desconto, e o coletor preserva isso. Situações1/2/4/7 são previstas,3 realizadas; moeda0 é real e3 dólar. Dólar venda usa valor explícito do mestre ou cotação coletada; sem valor confirmado não inventa paridade. Moeda desconhecida/referência ambígua é erro.

## Evidência preparada

`CompileContainersCustoReadTests.p` compila os dois serviços e os testes, e roda ambas as suítes em AMERICAN/EUROPEAN. Após o perfil interno de geração, diagnóstico local OpenEdge12.8: **87 checks do núcleo +164 do coletor por cultura**, sem erros de compilação, no runner integrado CompileContainersVersaoCostTests.p e staging `.runtime/container-versao-cost-local/`. A include ContainersCustoTestFixture.i compartilha as fixtures entre testes do coletor/adapter e precisa acompanhar os testes ao estágio de compilação. Nenhum `.r`12.8 deve ser publicado. A compilação12.2 e os dados reais/PASOE são responsabilidade da integração final e devem ser registrados separadamente.

Os testes usam temp-tables reais:1NF, múltiplas linhas/itens, último grupo, nota não mãe, substituição PIS/COFINS, ausência de conexão sem fallback, contexto financeiro, campos externos, empresa ambígua, preço desconhecido, aliquota zero, nota duplicada, snapshot de versão de outro container, consulta get isolada e chaves armazenadas com apóstrofo/tilde/aspas. Não houve escrita em banco de negócio.

GET aceita alias PK somente em detalhe: itens/comparativos usam item_container_id igual a id; rastro usa rastro_id igual a id; resumo exige id igual a container_id. Read recusa aliases. Nomes são sensíveis a maiúsculas/minúsculas.

A origem estruturada calculation.quotation_selection informa source, latest_record_date (máxima data bruta da série1), selected_date, selected_value, skipped_invalid_latest e warning. Quando a última data é inválida, warning.code=LATEST_QUOTATION_INVALID_SKIPPED e origin=calc_v1.latest-valid; warnings também recebe mensagem textual compatível. Ambiguidade só é erro na última data válida, nunca numa data anterior superada. Testes usam datas reais distintas no fixture e cobrem ambas as situações.

## Cotações fiscais —17/10/2026

O recurso adicional `cotacoes-fiscais` aceita somente `{operation:"read",resource:"cotacoes-fiscais",container_id,moeda?:"real"}`. A fronteira pública e o coletor rejeitam get, dólar, aliases de detalhe, políticas e flags do navegador. Mantém os25handles fixos, autoria/autenticação existentes e o contexto financeiro confirmado do mesmo container. Não consulta realizado ERP nem vendas; não executa processos ou grava dados.

Usa o mesmo `ContainersCustoCalculator.p`, no modo `fiscal_inputs`, conservando coleta de pagamentos/créditos, preços/quantidades atuais, despesas gerais e cotação válida. Zero itens do próprio container ou quantidades zeradas chegam ao núcleo sem item fictício e sem retorno antecipado de grade vazia. A saída mantém as12etapas do rastro e `calculation.memory`, inclusive compra_attempts/di_attempts/saldo_attempts. Esse contrato confirma cotações, não custos unitários. Os recursos anteriores preservam seus critérios de itens/base e não selecionam esse modo.

Após remover o último item, uma despesa individual antiga pode existir até a sincronização fiscal seguinte: somente neste recurso, sua ausência no conjunto de itens não bloqueia a consulta nem alimenta agregados de cotação. Nenhuma despesa é apagada, substituída ou atribuída a um item artificial; custos/rastro/versões continuam recusando referência individual órfã.

TDD: RED no novo recurso antes da extensão; GREEN diagnóstico12.8 com204checks do coletor,57da fronteira e116do núcleo por cultura AMERICAN/EUROPEAN. Equivalência das três listas de tentativas com rastro normal inclui prioridade do dólar médio e pagamentos não proporcionais à taxa fixa. Cobertos zero itens próprios com item de outro container, despesa antiga, zero pagamentos, zero quantidade, ausência dos handles ERP/vendas, escopo e negativas de contrato. Evidências `.runtime/container-items-20261017/fiscal-quotes-local/` e manifesto `fiscal-quotes-source-manifest.json` no diretório pai. Compilação12.2/PASOE real permanece responsabilidade do lote coordenado; nenhum `.r`12.8 é publicável.


## Atualização publicada em17/10/2026 — manutenção de itens

Perfil fiscal `cotacoes-fiscais` aceita ausência de itens e não exige custo unitário/ERP/vendas; despesas específicas órfãs não entram nessa coleta de cotações, preservando as validações nos perfis normais. Mesmas fórmulas no Calculator, sem duplicação. Coletor204verificações12.2/cultura.
