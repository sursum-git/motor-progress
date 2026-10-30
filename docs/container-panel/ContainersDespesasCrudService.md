# Despesas: CRUD e manutenção rápida

Serviço preparado `ContainersDespesasCrudService.p`, sem endpoint nem alteração de frontend. Inventário rastreável: `docs/containers-despesas-crud-inventario.md`. A seleção de defaults e batch insert não estão habilitados nesta entrega.

## ABI e origem dos dados

INPUT HANDLEs na mesma ordem do fiscal central: `phContainer,phEmpresas,phItems,phPurchaseItems,phPurchases,phDefs,phLinks,phTaxBases,phRelations,phCalcs,phExpenses`; depois `phRuntime` confiável. INPUT JsonObject `poPolicy`, `poRequest`; OUTPUT JsonObject `poResponse`.

Correspondências: espec.pp-container,empresas,itens_container,itens_proc_compra,procs_compra,despesas,empresas_despesa,despesas_impostos,relacs_desp_calculada,calcs_imp_container,despesas_container. Runtime fornece `CollectCalculationInputs(masterLocked,OUTPUT JsonObject)`, `NextCalculoId(OUTPUT INTEGER)`, `NextDespesaId(OUTPUT INTEGER)` e opcional `LogRule(INPUT CHARACTER level,INPUT CHARACTER message)`. É compatível com `ContainersCabecalhoRuntime.p`. Sequências fixas espec.seq_calcs_imp_container e espec.seq_despesas_container; sem MAX.

Policy privado: `{usuario_id:integer,actor:{login:string,id?:string},despesa_distr_custo:integer}`. Identidade vem da autenticação; audit normaliza somente login/id. Despesa de distribuição vem da include `sursum-api/includes/parametros_ima.i`, por `buscarParametroIma('despesa_distr_custo')`, consulta direta NO-LOCK sem cache. Parâmetro vazio legado corresponde a0; tipo/ID inválido é erro de configuração. Nada disso é aceito no request do navegador.

Extensão de16/10: o ID privado validado0..int32 é repassado ao fiscal central. Quando houver movimentos gerenciados repetidos por despesa/item, o fiscal exige `ValidateDistributionExpense(INPUT HANDLE master, INPUT HANDLE expense, OUTPUT JsonObject proof)` no runtime confiável, com propriedade física da conta corrente. Não há upsert ou perda de histórico; o teste integrado preserva dois movimentos20/-5 com IDs distintos. Suite atual128 checks por cultura em12.8. A validação estrita também recusa parâmetro fracionário antes da conversão para INTEGER.

Empresa é derivada do prefixo1/5 do estabelecimento do mestre e mapping único empresas.cod_emp_ems2. Toda despesa precisa existir e ter vínculo único empresas_despesa na empresa derivada. Não é possível escolher outra empresa pelo cliente. Vínculo histórico inativo não é automaticamente excluído no CRUD individual; o filtro log_ativo=1 pertence à ação de defaults, que é separada.

## Requisição fechada

| Operação | Campos |
|---|---|
| create | operation,container_id,values |
| update | operation,container_id,id ou despesa_container_id,values |
| delete/get | operation,container_id,id ou despesa_container_id |
| batch_update | operation,container_id,rows:[{id ou despesa_container_id,values}] |
| batch_delete | operation,container_id,rows:[{id ou despesa_container_id}] |

Quando ambos os aliases estão presentes, precisam coincidir. IDs aceitam inteiro JSON positivo32bits ou string de dígitos. Create recusa PK externa e usa sequência real. Lote é homogêneo, de1a200linhas, com IDs sem repetição. Nomes são sensíveis a maiúsculas/minúsculas; campos extras, empresas/identidade/tabela/flags técnicos externos e lote com operação por linha são recusados.

Values individuais: `despesa_id,vl_prev,vl_base_imp,vl_negociado,log_manual,perc_calc`. No batch_update somente `vl_prev,vl_base_imp,log_manual`; despesa é preservada como no formulário rápido. Referências, distribuição, cálculo fiscal, memória, versão e item do container não são campos livres. Create gera despesa geral item_container_id=0; preserva defaults físicos para os demais atributos técnicos.

Boolean exige boolean JSON, valores exigem número JSON e arredondamento2casas do dicionário. Percentual está entre0e100. Strings culturais como "1,25" são rejeitadas. Objeto values vazio é erro. Despesa de distribuição protegida não pode ser alterada/excluída por esses comandos, inclusive lote.

## Regras por evento

| Origem | Sequência executada | Invalidação |
|---|---|---|
| Individual create | inserir → sincronizar impostos → calculadas | sempre |
| Individual update | alterar → sincronizar → calculadas | somente diferença numérica em vl_prev,vl_base_imp,perc_calc,vl_negociado |
| Individual delete | excluir → sincronizar → calculadas | sempre |
| batch_update | gravar conjunto → sincronizar | sempre; não executa calculadas |
| batch_delete | excluir conjunto | sempre; não chama fiscal nem coletor |

Invalidação grava log_versao_custo_desatualizada=true e DATETIME atual. Comparação dos quatro campos é numérica; 0 e0.0 não geram diferença artificial. Snapshot final é relido depois das regras.

Regra individual de manual/onChange: manual zera percentual; não manual zera previsto antes da composição fiscal, e percentual0 usa o default confirmado da definição. Valores novos nos campos derivados continuam recusados. Em update, o formulário completo pode enviar o valor numérico exato do before persistido sob lock: esse eco é ignorado antes de normalizar/recalcular. A exceção vale para vl_prev quando o modo final é automático e para perc_calc quando o modo final é manual, inclusive transições manual↔automático. Não usa o valor proposto arredondado nem snapshot externo; 10.004 não é eco de10.00. Create não tem a exceção e continua recusando previsto automático ou percentual manual não zero. Requisições parciais e zero explícito conservam o contrato anterior. Flag manual de despesa não calculada não é alterável, conforme readonly da origem. No lote, não se aplica essa normalização: valida que não manual tenha percentual persistido diferente de0, como onValidate multi_reg. Referência da despesa no lote é somente leitura. A unicidade da edição individual preserva o critério PHP container+despesa, incluindo linhas de item; não escolhe uma linha arbitrária entre duplicadas.

Correção final do formulário completo em16/10/2026: TDD reproduziu o422 ao salvar os seis editáveis de uma despesa automática sem alterar o previsto. Diagnóstico local12.8 passou182checks/cultura nesta suite (+54), incluindo ambos os modos/transições, porcentagem histórica manual, diferença fracionária, create sem bypass, manual readonly e rollback fiscal depois de aceitar o eco. O serviço fiscal existente continua determinando os valores finais; sua fórmula/política não mudou. A publicação continua subordinada à nova compilação coerente12.2 e validação PASOE da tarefa principal; nenhum negócio ou sequência real foi executado nesta correção.

IPI, impostos, custo não recuperável e percentual_custo são calculados **somente** por `ContainersImpostosService.r`; nenhum desses cálculos foi reescrito no CRUD. Cotações vêm do runtime/coletor central sob lock do mestre. O `.r` é resolvido primeiro em sursum-api/programs e depois pelo literal no PROPATH; ausência falha antes de gravar. O serviço fiscal recebe snapshot confirmado dos seis parâmetros, retorna committed=false/pendingChanges e nunca audit confirmado dentro da raiz. Custo e versões continuam rotinas separadas reutilizáveis; este serviço não gera versões nem reimplementa o núcleo de custo.

## Atomicidade, resultado e logs

Escrita recusa TRANSACTION ambiente: este serviço possui o commit raiz. Bloqueia mestre EXCLUSIVE-LOCK NO-WAIT, bloqueia/valida todas as linhas do lote em ordem de ID antes da primeira alteração e captura snapshots reais. Depois grava na ordem enviada, compõe fiscal e confirma. Falha em qualquer etapa desfaz as linhas e efeitos fiscais juntos. Somente após commit anexa audit e chama LogRule, que enfileira na classe existente ApiExecutionRepository/PasoeExecutionContext; wrapper faz flush fora da transação. Falha da fila depois do commit não transforma escrita confirmada em resultado de falha.

Resultado individual `data` é snapshot físico final do mesmo PK, ou null quando ausente. Update cujo alvo desapareceu por regra também inclui `removedByRule:true`; não inventa snapshot. Delete fiscal pode recriar a mesma despesa sob ID novo: data do ID removido é null e audit.changes contém delete do antigo e create do novo. Batch retorna snapshots sobreviventes em data[]. Get é NO-LOCK, limitado ao ID do container.

Audit: `version:1,source:'progress-transaction',resource:'container-despesas',operation,container_id,actor,warnings,master:{before,after},changes:[{resource,operation,recordId,before,after}]`. Individual inclui recordId=despesa_container_id alvo e before/after do alvo real (objeto vazio para ausência); nunca usa container como PK da despesa. Batch omite recordId global e mantém IDs físicos de todas as mudanças. Mudanças repetidas do fiscal e edição direta são coalescidas por recurso+ID, preservando primeiro before e último after. Não há reparação/reatribuição de sc_log histórico.

Erros têm success=false,error:{code,message,status}, sem data/audit confirmado. Not found404, lock/transação/persistência409, identidade401, configuração500 e regra/validação422. Nenhum dado parcial é declarado gravado.

## Evidência auxiliar e pendência separada

OpenEdge12.8 diagnóstico: serviço/teste/fiscal central compilaram sem erro;120verificações em AMERICAN e120 em EUROPEAN. Runner `CompileContainersDespesasCrudTests.p`. Logs privados `.runtime/container-despesas-crud-local/compile-containers-despesas-crud.log` e logs por cultura. Fixture usa tabelas dinâmicas UNDO reais com campos do dicionário, sem banco de negócio.

Cobertura: sequência, manual/percentual, protected despesa, empresa, aliases, tipos/cultura/round2, whitelist, IDs repetidos, alvo de outro container, lote vazio/objeto vazio, diferenças de eventos, stale condicional, get, composição fiscal real, delete/recreate com outroID, falha de cotações após alterações em duas linhas, falha da segunda etapa fiscal desfazendo insert/cálculo/imposto, identidade normalizada e falha da fila após commit. Locks entre sessões e sequências/triggers reais exigem validação final12.2/PASOE com registros novos autorizados; não foram exercitados contra dados de negócio.

A ação selecionar defaults permanece etapa separada: o legado sobrescreve todos os padrões ativos, marca os selecionados utilizados e calcula subset antes de sincronizar. Precisa extensão interna explícita do fiscal para subset (lista vazia possui fallback distinto); não foi substituída indevidamente por recalcular todas. Batch insert não tem evento de negócio comprovado e continua desabilitado.
