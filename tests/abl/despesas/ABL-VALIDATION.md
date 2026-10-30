Análise de origem e API de despesas
==================================

`scriptcase-analysis.json` registra as quatro aplicações publicadas, os campos,
limites, relações e linhas de evidência. A função PHP `localValidarValoresImposto`
não tem chamada no desktop/mobile analisado; suas regras de valor positivo/XOR
não foram aplicadas. `% Custo` e `Despesa Custo` possuem exigência bilateral ativa.

`DespesasCrud.p` autentica o header privado `X-Despesas-Token` pelo SHA-256 em
`sursum-conf/despesas-api.json` e fornece oito buffers fixos ao serviço. Nenhum
nome de tabela pode vir da requisição. `DespesasCrudService.p` recebe, nesta ordem:
despesas, empresas_despesa, empresas, relacs_desp_calculada, despesas_impostos,
despesas_proc_compra, despesas_container e item_container_custo_despesas; depois
INPUT JsonObject e OUTPUT JsonObject.

O corpo é plano: `resource`, `operation`, `id` nas operações de registro existente
e os campos editáveis. Recursos fechados: `despesas` e `empresas_despesa`.
GET/UPDATE/DELETE aceitam também o alias da chave primária enviado pelo cliente
PHP (`despesa_id` ou `empresa_despesa_id`), exclusivamente se for inteiro positivo
igual a id; divergência retorna DESPESAS_ID_IMMUTABLE422. O alias não é gravado,
nem removido da requisição. CREATE continua proibindo id e alias da chave.
Operações: read/get/create/update/delete/opcoes_despesas/opcoes_impostos/
opcoes_empresas/opcoes_custo. Read de vínculos admite despesa_id contextual;
opções admitem id/despesa_id para excluir a despesa atual. O serviço sempre
valida autorreferência, existência e classificação de custo/imposto ao gravar.

Retorno read/options usa data array; get/create/update usa data objeto; delete
retorna success true. Despesas contém as nove colunas e md_relacs_desp integer[].
Vínculos contêm as doze colunas e impostos integer[], empresa_nome,
descricao_despesa e eh_imposto boolean/null. Os três campos virtuais são readonly.
perc_custo também é readonly: create conserva o inicial0 e update preserva valor.
Empresa/despesa de um vínculo só podem reaparecer em update com os mesmos IDs.

Registro e seleções confirmam numa única transação. A sincronização preserva
relações mantidas, remove ausentes e insere novas. Até100 IDs positivos int32
distintos; [] limpa. O ID de relacs é calculado por ordenação explícita do campo,
pois seu índice primário não é único. Lock de uma despesa âncora serializa essa
alocação entre pais distintos da API. Chaves principais usam NOWAIT e índice único.
Exclusão de despesa bloqueia dependências operacionais, vínculos, bases inversas
e impostos associados; só limpa relações próprias após os bloqueios.
Troca de log_imposto também recusa retirar classificação de imposto referenciado
ou transformar em imposto uma despesa usada como custo; sem dependência, permite.

Verificação auxiliar local em 15/10/2026: OpenEdge12.8, três fontes compilados
com COMPILER:ERROR=no, `PASS: 156 verificacoes despesas e relacoes` em cada
formato numerico AMERICAN e EUROPEAN (312 verificacoes nos dois processos).
`DespesasCrudTest.p` usa exclusivamente temp-tables undoable. A fase vermelha
confirmou serviço ainda não implementado; a fase verde cobre rollback de pai,
exclusões e inserções de relações após falha tardia, chaves imutáveis, unique do
par, referências, opções, limites, Unicode, flags INTEGER, boolean e quatro
decimais. `CompileDespesasTest.p` compila wrapper/serviço/teste e executa a suíte.
O runner aceita `-param AMERICAN` ou `-param EUROPEAN`; somente o runner altera
SESSION:NUMERIC-FORMAT. O serviço lê NUMBER por GetDecimal e interpreta STRING
numérica validada em ASCII sem conversão dependente da cultura. A regressão
EUROPEAN falhou antes da correção (12.3456 virava123456) e passou depois.
Limpar um numérico opcional com null/string vazia grava0 conforme Scriptcase;
omitir preserva o valor. IDs, booleanos e coleções mantêm seus tipos estritos.

Precisão física confirmada pelo fluxo principal no12.2/espec:
despesas.perc_calculo2, empresas_despesa.vl_padrao2, percentual2 e
percentual_custo4. O serviço limita a escala por MINIMUM(limite Scriptcase,
buffer-field:DECIMALS) antes da atribuição; schema preservado. A regressão TT2
falhou antes da correção porque12.3456 era aceito e arredondado; passou depois
com recusa sem alterar registro, enquanto12.34 permanece exato. As146 verificações
anteriores com TT4 continuam passando, e percentual_custo conserva4casas.

Buffers de banco usam clonagem pelo buffer-handle recebido do wrapper, inclusive
no cálculo de maxID; TABLE-HANDLE serve somente a temp-tables e não deve ser
usado como origem para clonar buffer DB. O padrão é documentado em
[CREATE BUFFER](https://documentation.progress.com/output/ua/OpenEdge_latest/pdsoe/PLUGINS_ROOT/com.openedge.pdt.langref.help/rfi1424919708416.html).
`DespesasDbReadTest.p` cobre seis operações de leitura com buffers reais do banco
espec e registra somente êxito/contagem, sem imprimir registros. `CompileDespesas.p`
compila os quatro fontes e executa esse smoke quando espec está conectado.
Compilação local12.8 do smoke passou; execução DB fica com o fluxo principal12.2.

Logs auxiliares em `.runtime/despesas-abl-local/`; os .r12.8 locais foram removidos.
Esta evidência não substitui compilação12.2 no .42 nem publicação/validação real
em PASOE sursum-api/med, realizadas pelo fluxo principal. Nenhum dado de negócio,
SSH ou publicação foi executado por este subtrabalho.
