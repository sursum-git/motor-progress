# Snapshot de custo para gerar versões

O usuário determinou que cálculos de custo e rotinas de versões sejam separados para reutilização. `ContainersCustoCalculator.p` concentra as fórmulas; `ContainersCustoReadService.p` concentra as leituras; `ContainersVersaoCostAdapter.p` adapta uma única coleta ao snapshot de geração. Nenhuma fórmula de média, câmbio, rateio ou realizado é copiada para o adapter, writer, formulário ou evento.

Evidência: `sources/scriptcase/containers/bl_item_custos/index.php:15949–15965` chama custo real/dólar com `tipoCusto=negociado`, `logBuscarCustoReal=true` e distribuição desabilitada. Comparativos também usa negociado, mas desabilita realizado, portanto seu resultado não é um snapshot de geração. O novo modo puro interno `gerar_versao` usa negociado, realizado ERP habilitado, distribuição zero e o ajuste truthy negociado−proforma na média dos itens. Os quatro modos públicos anteriores conservam seu comportamento.

`calculationBasis=current` permanece obrigatório nessa geração: o valor `version` da ABI pura anterior significa base histórica e recusa flag de versão desatualizada. Gerar uma versão nova pode justamente partir de uma versão anterior obsoleta.

## ABI interna

O adapter recebe os mesmos25INPUT HANDLE de `ContainersCustoReadService.p`, na ordem exata documentada em `ContainersCustoReadService.md`: container, itens, itens_proc, procs, empresas, empresas_despesa, despesas, despesas_container, cta_corren_custo_distr, descontos_importacao, motivos_desconto, cta_corren_desconto, hist_cotacoes_bc, item_container_custos, versoes_item_custo_container, nfs_container, ped-venda-ext, item-doc-est MED, docum-est MED, item-doc-est IMA, docum-est IMA, ped-venda MED, ped-item MED, ped-venda IMA, ped-item IMA.

Depois: `INPUT JsonObject poFinancial`, `INPUT JsonObject poPolicy`, `INPUT INTEGER piContainer`, `OUTPUT JsonObject poResponse`. Financial é o data confirmado do helper privado de totais vinculados, com source exata linked-payment-totals; origem da grade filtrada é recusada. Policy contém os três parâmetros internos habituais de custo; o adapter clona essa policy e acrescenta `calculation_profile="version"` e `capture_input=true`, sem alterar o objeto do caller. Não há request externo, conexão, token, HTTP ou escrita no adapter.

O coletor aceita esses dois campos somente na policy confiável interna. Perfil deve ser string exata version; capture deve ser boolean e true exige esse perfil. Perfilversion exige read/itens/real e recusa consulta vazia de cálculo. A ABI externa continua fechada e não aceita calculation_profile/capture_input no request. As quatro consultas normais nunca retornam input_snapshot.

O coletor roda uma única vez em real e só após sucesso completo devolve `input_snapshot`, clone profundo do JSON exato entregue ao núcleo, com modo gerar_versao/currencyreal/current. O adapter clona esse input, troca apenas currency para dolar e chama o núcleo puro. Clona novamente o input original e troca mode para rastro para calcular o médio mestre. São três execuções do mesmo núcleo no total: real dentro do coletor, dólar e Rastro no adapter. Não há segunda consulta aos buffers.

O médio mestre é distinto porque `bl_item_custos/index.php:15967` chama `buscarDolarMedio(container)` com default false, enquanto os itens ativam o ajuste truthy. Usar diretamente o médio dos itens no mestre mudaria a regra. A fixture de contraste obtém4.84615nos itens e4.8no mestre a partir dos mesmos insumos capturados, sem repetir fórmula.

## Resultado para o writer

Sucesso: `{success:true,data:{container_id,confirmed:true,source:"container-version-cost-snapshot",calculation_profile:"version",actual_complete,items_real,items_dolar,input_snapshot,master_average,calculation}}`.

- `items_real`: linhas do coletor, com cálculos centrais, chaves, código ERP, item de compra e quantidades.
- `items_dolar`: linhas produzidas pelo mesmo núcleo em dólar. O adapter valida os conjuntos e unicidade de item_container_id, associa por essa chave e normaliza ambas as listas por PK; o writer também deve usar a chave, nunca índice assumido.
- `input_snapshot.items`: insumos matemáticos por item, inclusive preço negociado e quantidades. Não é um snapshot de todos os campos físicos das tabelas.
- `master_average`: dolar_medio/cotacao_saldo/memory da chamada Rastro sobre os mesmos insumos.
- `calculation`: origem, memória dos itens, raw_erp, datas/cotação e avisos já produzidos pelo coletor, preservados.

confirmed significa coleta/cálculo concluído, separadamente de actual_complete. Ausência confirmada de NF/realizado mantém null nas duas moedas e actual_completefalse; o adapter não transforma desconhecido em0nem decide o que o writer pode gravar nesse caso. ERP ambíguo, item da NF não alocado, ausência de itens e contexto financeiro divergente continuam erros fechados sem snapshot parcial. Snapshot de despesas/NFs/pagamentos/descontos físicos e transação real de gravação pertencem ao writer/provider sob seus locks, sem recalcular custo.

O adapter só resolve caminhos fixos `.r` qualificados de coletor/núcleo, com nome `.r` literal no PROPATH como alternativa do runner isolado. Não compila `.p` em produção. Não possui rota pública. Não afirma snapshot distribuído dos bancos: os limites de NO-LOCK do coletor continuam documentados no serviço de leitura.

## Validação

`CompileContainersVersaoCostTests.p` compila núcleo, coletor, adapter e seus três testes e roda AMERICAN/EUROPEAN. A include de testes `ContainersCustoTestFixture.i` é compartilhada pelos testes do coletor/adapter para evitar cópia das fixtures. Todos usam temp-tables reais, sem negócio ou sequências reais. Casos incluem custo negociado4130/1070BRL e826/214USD, distribuição100desabilitada, dois itens/grupos ERP, nullreal em ambas as moedas, identidade financeira, flags internas recusadas no request e ausência de input_snapshot nas quatro consultas públicas. O JSON capturado reproduz dólar mesmo depois de alterar os buffers vivos.

Evidências locais12.8 em `.runtime/container-versao-cost-local/`:87verificações do núcleo,164do coletor e39do adapter por formato, seis fontes sem erro de compilação. A regressão do runtime fiscal também passou27por formato usando o novo núcleo. Esses .r são apenas diagnóstico e não podem ser publicados. Compilação12.2/.42 e publicação/validação PASOE sursum-api/med pertencem à tarefa principal.
