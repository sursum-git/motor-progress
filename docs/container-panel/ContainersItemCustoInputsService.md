# Coleta física do fechamento unitário

## Atualização coordenada12.2 —16/10/2026

Os registros12.8/RED abaixo são históricos. Lote coerente `.runtime/container-panel-coherent-compiled-20261016-v2/` compilou52fontes12.2 sem erro;24suites e1962checks por cultura passaram. Composição34 e MissingActual7 passaram após correção separada do coletor: histórico opcional unknown fica JSONnull, sem mudar D() nos obrigatórios. Inputs/Close175, Context11 e Runtime12 também passaram no12.2. Apenas a correção do coletor de leitura foi publicada/validada no PASOE; helpers de escrita continuam privados, sem rota, sequência ou negócio real executado. Ver memória de retomada para manifests atuais.


Preparado em16/10/2026. Serviço privado, sem rota pública e sem escrita de negócio. Entrega o contrato existente de ContainersItemCustoCalculator.p; não repete sua matemática. Simulação chama coletor e calculador. O writer central faz a mesma composição dentro da transação. Não consulta qt_erros de sessão.

## ABI fixa

INPUT HANDLEs na ordem:

1. phMaster — espec.pp-container;
2. phItems — espec.itens_container;
3. phPurchaseItems — espec.itens_proc_compra;
4. phVersions — espec.versoes_item_custo_container;
5. phVersionItems — espec.item_container_custos;
6. phItemCosts — espec.item_custos;
7. phNfs — espec.nfs_container;
8. phLocations — espec.locais_estoq_portal;
9. phLabels — espec.ob-etiqueta;
10. phStockIma — ems2ima.saldo-estoq;
11. phStockMed — ems2med.saldo-estoq;
12. phMovementsMed — ems2med.movto-estoq;
13. phInvoicesIma — ems2ima.nota-fiscal;
14. phInvoicesMed — ems2med.nota-fiscal.

Depois: INPUT LOGICAL plForWrite, INPUT JsonObject poPolicy, INPUT JsonObject poRequest, OUTPUT JsonObject poResponse. Booleano é interno ao driver; nunca é extraído do navegador. DB/tabela/campo, SQL e políticas não pertencem ao request.

Policy fechada: {"tipo_versao_valida_nf":[4,5]}. Lista vem da include Progress de parâmetros IMA, leitura direta NO-LOCK sem cache; PHP usa buscarParametroIma('tipo_versao_valida_nf','4,5'). Coletor não faz parsing textual nem escolhe defaults por falha de conexão. Elementos NUMBER inteiros positivos; rotina pura valida pertinência exata e duplicidades.

Request fechado: {"container_id":123,"versao_id":7,"log_priorizar_custo_previsto":false}. IDs NUMBER integrais32 positivos, flags BOOLEAN. Versão precisa ser a última do container e estar completa2. Flags stale/liberação do realizado vêm do mestre, sem override no request.

## Seleção física e ausência

- Todos os itens atuais em ordem item_container_id; código ERP do pedido atual. Código do snapshot deve coincidir, evitando versão antiga após correção cadastral.
- Snapshot da versão/item exatos. Par repetido é erro; ausência permanece version_cost:null para diagnóstico agregado do calculador. Snapshot extra/estrangeiro é erro. Componentes não usados mantêm null.
- Custo anterior: maior item_custo_id elegível entre tipo diferente de2 e tipo2 ligado por snapshot→versão a outro container. Tipo2 do próprio container é excluído, inclusive no refechamento. Versão maior alheia não altera a última local. Ausência comprovada vira previous_cost:null; calculador decide o ramo financeiro permitido.
- Mãe: nfs_container com natureza começando por3. Estab exatamente'1' usa nota-fiscal IMA, demais MED. Chave cod-estabel/serie/nr-nota-fis; cod_emitente é origem, não parte dessa PK. Vínculo sem nota ERP/data conhecida ou lookup ambíguo bloqueia; não é ausência de mãe. Não usar docum-est para a data.
- Sem mãe, corte de leitura de movimentos2001-01-01, default explícito do helper. Com mãe, data confirmada. Todas as mães seguem no input: único calculador recusa datas divergentes, sem escolher silenciosamente uma para gravar. Filtro físico dt-trans<corte limita leitura, não calcula saldo/unitário.
- Movimentos somente MED, item/corte estrito, todos estabelecimentos/depósitos, ordem nr-trans. Movimento futuro irrelevante não vira erro financeiro.
- Estoque IMA soma item com cod-estabel='1'. MED usa pares de locais_estoq_portal cod_empresa='5'; pares repetidos não multiplicam soma. Sem locais, MED não recebe filtro extra: variável de prefixo5 no PHP não entra na SQL efetiva. Ausência comprovada de saldo é soma0; falha de leitura não é0.
- Etiquetas espec.ob-etiqueta do item, situação3/4, quantidade diferente de0. Grupos/estabelecimentos são entregues; somas/análise próprio/outros ficam no calculador.

Fontes: docs/containers-item-custo-unitario-inventario.md e cons_itens_container_simul_calc/index.php:9818–9831,10320–10387,12938–12969,17293–17310,17708–17745. Sete dicionários adicionais em schema/espec,ems2ima,ems2med.

## Locks e consistência

plForWrite=false lê NO-LOCK sem iniciar transação. true exige transação ativa, mestre EXCLUSIVE-LOCK NOWAIT, referências/ERP SHARE-LOCK NOWAIT e snapshots alvo EXCLUSIVE-LOCK NOWAIT. Não libera buffers antes do efeito. Driver raiz é responsável pelo ciclo e UNDO de falhas.

Retenção transacional segue [OpenEdge12.2](https://docs.progress.com/bundle/openedge-develop-abl-applications-122/page/Making-sure-you-release-record-locks.html). Locks cobrem registros existentes lidos; não impedem inserts externos e não serializam outro container do mesmo código ERP. Não se promete snapshot serializável do ERP. Captura única registra instante, modo e essa limitação.

## Saída

Sucesso: {success:true,data:{input:<contrato puro item-cost-inputs-v1>,provenance:{source:'item-cost-physical-collector-v1',container_id,versao_id,collected_at,collection_count:1,lock_mode,erp_consistency}}}. confirmed significa origem coletada, não aprovação financeira; o calculador ainda valida todo o conjunto.

Falha: {success:false,error:{code,message,status}}, sem data parcial gravável. ITEM_COST_CONTAINER_NOT_FOUND404; ITEM_COST_VERSION_CONFLICT/ITEM_COST_BUSY409; ITEM_COST_INPUT_INCOMPLETE,ITEM_COST_INPUT_AMBIGUOUS,ITEM_COST_VERSION_INCOMPLETE e demais validações422.

ContainersItemCustoPhysical.i só reúne JSON/query/escape, sem fórmula. Aspas/apóstrofo/tilde/controles são dados persistidos, sem SQL livre. Wrapper autenticado futuro fornece14buffers/conexão IMA fixa; navegador nunca escolhe conexão.
