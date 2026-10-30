# Fechamento unitário transacional

## Atualização coordenada12.2 —16/10/2026

Os registros12.8/RED abaixo são históricos. Lote coerente `.runtime/container-panel-coherent-compiled-20261016-v2/` compilou52fontes12.2 sem erro;24suites e1962checks por cultura passaram. Composição34 e MissingActual7 passaram após correção separada do coletor: histórico opcional unknown fica JSONnull, sem mudar D() nos obrigatórios. Inputs/Close175, Context11 e Runtime12 também passaram no12.2. Apenas a correção do coletor de leitura foi publicada/validada no PASOE; helpers de escrita continuam privados, sem rota, sequência ou negócio real executado. Ver memória de retomada para manifests atuais.


Preparado em16/10/2026, sem publicação/escrita real. Rotinas separadas: InputsService coleta; ContainersItemCustoCalculator.p calcula; CloseService persiste. Writer não copia fórmulas. Núcleo existente intacto SHA256 3B40DE7A2F7C28D47B1144E4BE962F76865FBA7EBED91C9517918182F7B57C18.

## ABI e callback

INPUT14handles na ordem do coletor: phMaster,phItems,phPurchaseItems,phVersions,phVersionItems,phItemCosts,phNfs,phLocations,phLabels,phStockIma,phStockMed,phMovementsMed,phInvoicesIma,phInvoicesMed. Depois INPUT HANDLE phRuntime, INPUT JsonObject poPolicy, INPUT JsonObject poRequest, OUTPUT JsonObject poResponse.

Policy privada fechada: {"actor":"login autenticado","tipo_versao_valida_nf":[4,5],"allow_nested":true}. allow_nested opcional/defaultfalse. actor string não vazia até30caracteres, campo físico cod_usuario. Wrapper obtém autoria/parâmetro IMA sem cache; cliente não fornece policy.

Request fechado: {"operation":"fechar","container_id":123,"versao_id":7,"expected_latest_version_id":7,"log_priorizar_custo_previsto":false,"request_id":"rastreio opcional"}.

IDs NUMBER inteiros32 positivos. Versão alvo deve ser última esperada local, completa2. Nova versão entre UI/comando causa conflito. Preferência é BOOLEAN explícito. request_id string até128 correlaciona audit; não promete idempotência persistida. qt_erros, actor, custos/quantidades e nomes de programa/tabela são recusados.

phRuntime confiável fornece NextItemCustoId(OUTPUT INTEGER), futura implementação concreta via DYNAMIC-NEXT-VALUE('seq_item_custos','espec'), sem MAX global. Testes usam contador NO-UNDO, nunca sequência real. LogRule(INPUT CHARACTER level,INPUT CHARACTER message) opcional, só após commit próprio, sem flush. Futuro VersionRuntime: CloseItemCosts(INPUT HANDLE masterLocked,INPUT HANDLE versionLocked,INPUT JsonObject request,OUTPUT JsonObject result) delega a este writer sem repetir matemática. Essa integração ainda não foi implementada nestes arquivos.

## Transação

1. Valida request, autoria, composição, caminhos compilados e callback.
2. DO TRANSACTION; mestre EXCLUSIVE NOWAIT, versão alvo do mesmo container EXCLUSIVE NOWAIT.
3. Coletor1x em fechamento e calculador central1x. Erros de todos os itens permanecem estruturados; nenhum parcial vira0.
4. Confere conjunto calculado contra itens atuais/snapshots exatos, prepara before de cada vínculo. Não consome ID antes do gate integral.
5. Ordena por item_container_id, obtém ID, inclui item_custos e religa snapshot, com guard versão/item e before bloqueado.
6. Falha de sequência/validação/persistência desfaz todos os inserts/vínculos. ID consumido não é revertido; isso não confirma linha.

Refechamento preserva legado: outro custo e novo vínculo, auditando ID anterior/novo. Não exclui históricos nem inventa bloqueio de já fechado. Não altera ind_sit_versao: completo2 pertence à geração.

Grava15campos de bl_item_custos_gravacao/index.php:8790–8847: item_custo_id,dt_hr_custo,vl_unit_novo,dt_referencia,cod_tipo_custo=2,it_codigo,qt_estoque,qt_estoque_selecionado,qt_nf_mae,qt_etiq_container,vl_unit_anterior,cod_situacao=2,vl_unit_container,qt_container,cod_usuario. Timestamp único do servidor e DATE correspondente. Restante fica nos defaults físicos. UPDATE vínculo segue8371–8380 com guards adicionais.

Unitários/quantidades físicos em item_custos têm DECIMALS2. Núcleo mantém ramo sem ROUND2 quando não há movimento:30.12345 calculado permanece distinto de30.12 armazenado. Saída separa calculation/persisted; toda diferença numérica mapeada gera ITEM_COST_STORAGE_ROUNDING com campo/calculado/persistido. Não modifica schema/núcleo para esconder diferença.

## Saída e auditoria

Sucesso: {success:true,committed,data:{source:'container-item-cost-close-v1',container_id,versao_id,items:[{item_container_id,item_container_custo_id,item_custo_id,persisted:<15campos>}],calculation:<data do núcleo>,provenance,warnings}}.

Commit próprio: audit.source='progress-transaction', duas changes por item: create item_custos e update item_container_custos, com resource/operation/recordId/before/after. Audit só após DO TRANSACTION. Buffers liberados após commit/UNDO próprio.

Transação externa autorizada: committed=false, pendingChanges e auditPending.source='progress-transaction-pending'; sem audit/log confirmado/liberação antecipada. Ancestral precisa verificar success e UNDO sua transação quando false. Não continuar e confirmar após falha aninhada.

Erros coletor/núcleo preservados, inclusive ITEM_COST_VALIDATION com global_errors/items/contagem agregada. Erros próprios usam error{code,message,status}, sem data parcial persistida.

Programas resolvidos apenas .r: sursum-api/programs/... e literal .r no PROPATH explícito de testes. Sem fallback .p em produção, SQL escolhido pelo cliente ou execução PHP legado.

## Evidência auxiliar e pendências

CompileContainersItemCustoCloseTests.p:175verificações em AMERICAN e175 em EUROPEAN no12.8 auxiliar; todos compiladores sem erro. TT undoable com tipos/decimais físicos; provider sequência/log só fixture. RED293 por serviços ausentes; RED específico: ponteiro unknown antes da sequência e movimento futuro irrelevante fora da leitura.

Cobre duas linhas; última inválida sem IDs; refechamento/histórico; audit antes/depois; segunda sequência falha após primeiro insert/link; nested/UNDO ancestral; MAX anterior não2/tipo2 outro container; exclusão do próprio; latest local; mães/default/datas divergentes; nota órfã/banco; locais MED/vazio; IMA1; stale/unknown; conjuntos vazios/extras/duplicados/missing; null não usado; precisão5→2; máximo global alheio; colisão de ID; quoting persistido; request fechado; liberação standalone.

Logs: .runtime/container-item-close-local/compile-containers-item-close.log e containers-item-close-tests-{AMERICAN,EUROPEAN}.log. Zero sequência/negócio real. Obrigatórios12.2, runtime/VersionService, concorrência entre sessões, conexões/triggers e PASOE continuam na tarefa principal. Locks existentes não impedem inserts externos nem serializam containers do mesmo item. Não publicar .r12.8/fixtures.

Execução local reproduzível: C:/Progress/OpenEdge/bin/_progres.exe -b -cpinternal UTF-8 -cpstream UTF-8 -p CompileContainersItemCustoCloseTests.p, cwd .runtime/container-item-close-local. Regressão separada do núcleo existente via CompileContainersItemCustoTests.p também passou71/cultura com os mesmos parâmetrosUTF-8. Sem esses parâmetros, a fixture antiga do núcleo usa LONGCHAR no codepage defaultISO8859-1 e ObjectModelParser recusa antes de calcular; não é regressão do novo writer. Não foi alterado nenhum fonte compartilhado para contornar ambiente.

Revisões independentes somente leitura pelos agentes de metadados e regras: sem achado material no escopo aprovado, conferidas elegibilidade do custo anterior,15campos, parent/context, transação e precisão. Isso não substitui12.2/PASOE/concorrência real.
