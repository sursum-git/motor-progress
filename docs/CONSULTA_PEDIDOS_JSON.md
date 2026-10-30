# Consulta de pedidos de venda via JsonObject

Fonte: `especificos/ems2/ima/http-api/api_cons_ped_venda.p`.
Publicado em `\\192.168.0.137\erp\especificos\ems2\ima\http-api\api_cons_ped_venda.p` e `.r` (equivalente a `T:\especificos\ems2\ima\http-api\`).

## Chamada

`POST https://192.168.0.111:9911/med/web/SursumPrograms/consulta-pedidos-venda`

Content-Type: `application/json`.

```json
{
  "dtImplantIni": "2026-04-01",
  "dtImplantFim": "2026-09-24",
  "nrPedidoIni": 252711,
  "nrPedidoFim": 252711
}
```

As datas usam YYYY-MM-DD. Quando omitidas, os padroes sao 2026-04-01 e 2026-09-24, respectivamente. O intervalo de pedido e opcional; informar os dois limites juntos. Somente as tags de filtro na raiz sao aplicadas. As propriedades reconhecidas estao na tabela abaixo; outras propriedades sao analisadas, mas nao viram filtros da BO.

O programa serializa o JsonObject recebido e usa `esapi/analiseJsonObject10.p` (nome real publicado, sem o r de analisar), extraindo os filtros das tags retornadas pelo analisador. Inicia `esbo/boConsPedVenda2.p` com `PERSISTENT SET hBo`, chama iniciarBo, limparContexto, os filtros, exec, getTTDados e finalizarBo. A definicao da tabela vem de `esbo/boConsPedVenda2.i`; o include `esp/util.i` foi mantido conforme solicitado. A BO existente nao foi alterada.


## Filtros completos da BO (ampliacao em 28/09/2026)

Todos os dez setters de filtros existentes em `boConsPedVenda2.p` estao expostos. Os filtros novos sao opcionais; quando omitidos, seu setter nao e chamado e o padrao da BO e preservado.

| Propriedade JSON | Tipo | Setter / comportamento |
|---|---|---|
| `dtImplantIni`, `dtImplantFim` | Texto `YYYY-MM-DD` | `setIntervalDtImplant`; padroes 2026-04-01 e 2026-09-24 |
| `nrPedidoIni`, `nrPedidoFim` | Inteiro nao negativo | `setIntervalNrPedido`; informar os dois juntos |
| `estabIni`, `estabFim` | Texto | `setIntervalEstab`; informar os dois juntos; preserva zeros iniciais |
| `clienteIni`, `clienteFim` | Inteiro nao negativo | `setIntervalCliente`; informar os dois juntos |
| `represIni`, `represFim` | Texto | `setIntervalRepres`; informar os dois juntos; usa o identificador/nome abreviado esperado pela BO |
| `somenteClubeIma` | Booleano JSON `true`/`false` | `setSomenteClubeIma`; true restringe ao Clube IMA; false inclui ambos, nao significa somente nao participantes |
| `sitPed` | Texto com codigos separados por virgula | `setSitPed`; exemplo `"1,2,3"` |
| `sitAval` | Texto com codigos separados por virgula | `setSitAval`; exemplo `"1,2,3"` |
| `sitPreco` | Texto com codigos separados por virgula | `setSitPreco`; exemplo `"1,2,3"` |
| `bloqueioAprov` | Texto `"YES"`, `"NO"` ou `"YES,NO"` | `setBloqueioAprov`; filtra o campo `l-nao-aprovar`, conforme a BO |

Os intervalos sao inclusivos e o limite inicial nao pode superar o final. Clientes e pedidos aceitam tambem texto numerico inteiro, mantendo a compatibilidade anterior. Estabelecimento, representante e listas exigem texto; Clube IMA exige booleano real, nao `"true"`/`"false"`.

As listas removem espacos ao redor dos itens e duplicatas. Codigos de situacao devem ser inteiros nao negativos; nao se cria uma enumeracao nova diferente da BO. A omissao conserva a lista padrao da BO (atualmente `1,2,3,4,5,6` para situacoes e `YES,NO` para bloqueio). Uma lista vazia (`""`) e repassada como vazia e nao seleciona registros, conforme o uso de LOOKUP na BO. Nao enviar arrays JSON nesses campos. Valores nulos, objetos e listas malformadas sao rejeitados.

Exemplo de todos os filtros (substituir estabelecimento, cliente e representante por valores reais):

```json
{
  "dtImplantIni": "2026-04-01",
  "dtImplantFim": "2026-09-24",
  "nrPedidoIni": 252711,
  "nrPedidoFim": 252711,
  "estabIni": "001",
  "estabFim": "001",
  "clienteIni": 100,
  "clienteFim": 200,
  "represIni": "A",
  "represFim": "ZZZZZZZZZZZZZ",
  "somenteClubeIma": false,
  "sitPed": "1,2,3,4,5,6",
  "sitAval": "1,2,3,4,5,6",
  "sitPreco": "1,2,3,4,5,6",
  "bloqueioAprov": "YES,NO"
}
```

A ampliacao mantem a mesma rota, o mesmo formato de resposta e a BO existente. Na revisao de 28/09/2026, ainda nao havia setter publico de containers nas copias inspecionadas. O suporte atual a containers esta descrito abaixo.

## Lista de containers (29/09/2026)

Enviar `lista_containers` como texto com numeros inteiros nao negativos separados por virgula:

```json
{
  "dtImplantIni": "2026-04-01",
  "dtImplantFim": "2026-09-24",
  "lista_containers": "1650,1651,1652"
}
```

Os numeros sao exemplos; usar containers do ambiente. O filtro combina com datas, pedido, cliente e demais parametros existentes. As datas continuam com os padroes documentados quando omitidas.

- Campo omitido, vazio ou apenas com espacos: nao chama o setter de containers e preserva a consulta pelos demais filtros.
- Campo preenchido: usa `REPEAT` e `ENTRY` para percorrer a lista, valida cada numero, cria os registros de `tt-containers` e chama `RUN setTTContainer IN hBo (INPUT TABLE tt-containers)` depois de `limparContexto` e antes de `exec`.
- Espacos ao redor dos numeros sao aceitos; numeros repetidos geram um unico registro na temp-table, evitando pedidos duplicados.
- Itens vazios no meio da lista, valores nao numericos, negativos, fracionarios ou fora do limite INTEGER sao rejeitados antes da execucao da BO. A propriedade deve ser texto, nao array, numero ou null.
- Se nenhum container informado tiver pedidos que atendam aos filtros, o retorno e uma lista vazia; nao volta para a consulta geral.

A BO publicada inspecionada em 29/09/2026 possui `setTTContainer` com `DEFINE INPUT PARAMETER TABLE FOR tt-containers`. Nessa versao, `tt-containers` esta declarada no corpo da BO, com campo `nr-container AS INTEGER` e indice primario `nr-container`; a include `esbo/boConsPedVenda2.i` contem `tt-dados`. O wrapper usa o mesmo esquema da tabela de entrada. A BO e a include nao foram modificadas nesta entrega.

## Retorno

```json
{"success":true,"total":0,"tt-dados":[]}
```

Cada linha preserva os 19 nomes de campos da tabela da BO e acrescenta os 11 campos do contrato PHP descrito abaixo. Os valores monetarios passam a refletir os campos persistidos do pedido. Erros de filtro ou execucao retornam `success: false`, `error` e `tt-dados: []`. O roteador retorna HTTP 200 quando o programa devolve esse objeto; o consumidor deve conferir `success`.

## Publicacao e verificacao em 25/09/2026

- Compilador: OpenEdge 12.2.12 no 192.168.0.42; `COMPILER_ERROR=no`. Dependencias de includes copiadas do compartilhamento para staging isolado.
- Fonte e r-code publicados na pasta http-api; hashes verificados apos transferencia.
- Catalogo `sursum/conf-web-handler/program-routes.json` mesclado, preservando GET/POST do echo.
- Registrado JsonProgramWebHandler apenas no contexto med da instancia sursum-api, preservando DynamicQueryWebHandler como handler padrao.
- Acrescentada `/mnt/datasul/ERP` apenas ao PROPATH de `[AppServer.Agent.med]`, para resolver o caminho relativo do programa no catalogo. PROPATH global e contexto ima preservados.
- A instancia sursum-api estava parada e foi iniciada por seu startup.sh. A instancia sursum-api-teste nao foi alterada.
- Backup remoto dos arquivos preexistentes alterados: `/tmp/sursum-consulta-pedidos-20260925`.
- Teste HTTP com o intervalo completo, sem filtro de pedido: HTTP 200, success=true, total=10660; todos os registros dentro do intervalo solicitado e os 19 campos presentes.
- Suite `tests/e2e/playwright/pasoe-consulta-pedidos-backend.spec.js`: 6/6 passaram (consulta real e cinco entradas invalidas).
- Suite `tests/e2e/playwright/pasoe-json-program-router-backend.spec.js`: 8/8 passaram no mesmo endpoint base.

A determinacao atual do usuario e sempre usar sursum-api/9911; sursum-api-teste/9921 somente mediante pedido explicito.

## Validacao da ampliacao em 28/09/2026

- BO publicada inspecionada novamente; 10 setters identificados e 10 chamadas correspondentes no wrapper, sem omissoes.
- Compilacao do wrapper no OpenEdge 12.2.12: `COMPILER_ERROR=no`.
- Fonte e r-code publicados na mesma pasta http-api, com verificacao de hashes e preservacao dos arquivos anteriores. A BO, o catalogo de rotas e a configuracao da instancia nao foram alterados nesta ampliacao.
- Backup anterior a ampliacao: `/tmp/sursum-pedidos-filtros-20260928`; revisao intermediaria: `/tmp/sursum-pedidos-filtros-20260928-fix1`.
- Validacao pela rota `https://192.168.0.111:9911/med/web/SursumPrograms/consulta-pedidos-venda`: 21/21 testes passaram (6 anteriores e 15 novos).
- Os novos testes selecionam um pedido existente na consulta, verificam os filtros positivos e excludentes, a particao dos resultados por bloqueio e situacao de preco, a opcao Clube IMA e os erros de tipo, intervalo e lista. Nao dependem de o pedido ilustrativo 252711 conter dados.
- A primeira validacao detectou zeros acrescentados indevidamente aos codigos das listas; a normalizacao foi corrigida, recompilada e republicada antes da execucao final aprovada.
- Nao foi necessario reiniciar a instancia; os testes negativos e positivos confirmaram o comportamento do novo compilado. `sursum-api-teste` nao foi utilizada.

## Validacao de lista_containers em 29/09/2026

- Wrapper compilado no OpenEdge 12.2.12: `COMPILER_ERROR=no`.
- Fonte e `.r` publicados em `especificos/ems2/ima/http-api`, com verificacao de hashes e backup em `/tmp/sursum-pedidos-containers-20260929`.
- BO e include preservadas. A chamada usa `setTTContainer(INPUT TABLE tt-containers)` confirmado no fonte atual.
- Validacao real em `https://192.168.0.111:9911/med/web/SursumPrograms/consulta-pedidos-venda`: **34/34 testes passaram**, sendo 13 de containers e 21 dos filtros anteriores.
- Os testes selecionam dois containers reais da consulta base e comparam os registros retornados, incluindo combinacao com pedido/cliente, duplicatas, campo vazio e container sem correspondencias.
- Publicacao carregada sem reinicio da instancia; nenhuma utilizacao da `sursum-api-teste`.

## Consumo por criarPesqPedVenda (29/09/2026)

O objeto raiz permanece `success`, `total`, `tt-dados`. Entregar **somente o array `tt-dados`** para `criarPesqPedVenda`, depois de verificar `success`. A funcao `apagarPesqPedVenda` foi desconsiderada conforme solicitado.

```php
// $jsonRetorno: corpo HTTP retornado pela rota; $codWp: pesquisa criada no PHP.
$resposta = json_decode($jsonRetorno, true, 512, JSON_THROW_ON_ERROR);
if (($resposta['success'] ?? false) !== true) {
    throw new RuntimeException($resposta['error'] ?? 'Falha na consulta de pedidos');
}
if (!isset($resposta['tt-dados']) || !is_array($resposta['tt-dados'])) {
    throw new RuntimeException('Resposta sem a lista tt-dados');
}
$aWpPedVenda = $resposta['tt-dados'];
criarPesqPedVenda($aWpPedVenda, $codWp);
```

Campos usados pela funcao PHP:

| Chaves JSON | Origem / tipo |
|---|---|
| `cod-estabel`, `nome-abrev`, `dt-implant`, `cod-sit-ped`, `tp-pedido`, `cod-sit-aval`, `cod-emitente`, `nr-container` | Campos ja retornados pela BO; data no formato ISO `YYYY-MM-DD` |
| `nr-pedcli`, `no-ab-reppri` | `mgdis.ped-venda`, texto; `nr-pedcli` e o pedido do cliente, nao uma conversao de `nr-pedido` |
| `cod-sit-preco`, `cod-priori`, `mo-codigo` | `mgdis.ped-venda`, inteiros |
| `vl-liq-ped`, `val-desconto-total` | `mgdis.ped-venda`, numeros JSON sem separador de milhar ou formatacao monetaria |
| `completo` | `mgdis.ped-venda`, booleano JSON |
| `preposto`, `origem`, `l-nao-aprovar` | `espec.ped-venda-ext`, respectivamente texto, inteiro e booleano JSON |

O wrapper complementa cada linha por `cod-estabel` + `nr-pedido`, em leitura `NO-LOCK`, nos bancos/aliases da sessao. A BO e sua include permanecem intactas. Se o registro deixar de existir entre a consulta e a montagem do JSON, a API retorna erro, sem entregar linhas incompletas. Valores desconhecidos do Progress podem ser representados por `null`; nao sao inventados valores substitutos.

A rotina `_calcValoresPedido` da BO inspecionada ainda esta marcada como TODO. Por isso a API usa `ped-venda.vl-liq-ped` e `ped-venda.val-desconto-total`; tambem atualiza os nomes anteriores `vl-liquido`, `vl-desconto` e `vl-bruto` para os mesmos valores, sendo o bruto a soma do liquido com o desconto, conforme o calculo PHP fornecido.

`codWp` continua sendo definido pelo PHP. Os campos comentados `nome_abrev_repres` e `perc_repres` nao fazem parte desse contrato. Na funcao fornecida, a linha `$percComis = tratarNumero($percComis);` usa uma variavel sem inicializacao, embora sua utilizacao no insert esteja comentada. Remover essa linha enquanto a comissao nao for utilizada, ou inicializar a variavel com uma origem valida antes de usa-la; a adaptacao JSON nao corrige essa linha PHP.

A conversao em array foi validada sem executar `sc_exec_sql`. O tratamento de booleanos no SQL continua a cargo de `convertArrayEmInsert`, cuja implementacao nao foi fornecida.

## Validacao do contrato PHP em 29/09/2026

- Compilacao do wrapper no OpenEdge 12.2.12 (192.168.0.42): `COMPILER_ERROR=no`.
- Fonte e `.r` publicados na pasta http-api do compartilhamento ERP, com hashes conferidos. Backup anterior a alteracao: `/tmp/sursum-pedidos-php-20260929`; revisao intermediaria: `/tmp/sursum-pedidos-php-20260929-fix1`.
- Validacao pela rota real da instancia **sursum-api**, contexto **med**, porta **9911**: **34 testes de regressao aprovados**, mais **3 testes do contrato PHP aprovados** na versao final dos testes.
- O novo teste falhou antes da implementacao pela ausencia de `nr-pedcli`. Depois da publicacao, verificou todas as chaves consumidas pelo PHP, tipos JSON, datas e consistencia dos valores em todas as linhas do periodo; comparou amostras com consultas independentes ao ERP; executou `json_decode(..., true)` e o calculo do bruto usando PHP 8.4.3.
- A consulta independente usa campos explicitos e normaliza apenas para comparacao os numeros/textos do motor generico (por exemplo, `60,16` e `yes`). O retorno da API usa `60.16` e `true` nativos no JSON.
- Nenhuma funcao de insercao/exclusao de pesquisa foi executada. A BO/include e a rota existente foram preservadas; nao foi necessario reiniciar a instancia.
