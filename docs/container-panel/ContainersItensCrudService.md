# Manutenção e alocação transacional de itens

Núcleo `ContainersItensCrudService.p`, preparado em17/10/2026. Não contém HTTP, conexão, sequência física, cálculo fiscal, câmbio ou fórmulas financeiras. O wrapper e o provider real pertencem à tarefa principal. Diagnóstico12.8 não é artefato publicável;12.2/PASOE continuam obrigatórios antes da conclusão da integração.

## ABI e dependências

INPUT HANDLEs, nesta ordem: `phMaster` (espec.pp-container), `phItems` (itens_container), `phPurchaseItems` (itens_proc_compra), `phPurchases` (procs_compra), `phDiscounts` (descontos_importacao), `phItemCosts` (item_container_custos), `phCommercial` (pp-it-container), `phRuntime` (procedure confiável). Depois INPUT JsonObject poPolicy, poRequest e OUTPUT JsonObject poResponse.

Policy privada: `{actor:{login:string},allow_nested?:boolean}`. Extras privados do wrapper, como usuario_id/despesa_distr_custo, são compatíveis com o serviço de despesas; nunca são extraídos do request público. Login não vazio até128; audit normaliza somente login. O provider financeiro real pode impor o comprimento físico menor do seu campo, sem truncamento no núcleo.

Provider obrigatório nas escritas:

```text
GetCapabilities(OUTPUT JsonObject {
  contract:'container-item-rules-v1',afterChange:true,nextItemId:true
})
NextItemId(OUTPUT INTEGER item_container_id)
AfterChange(INPUT HANDLE masterLocked,INPUT JsonObject ctx,OUTPUT JsonObject result)
LogRule(INPUT CHARACTER level,INPUT CHARACTER message) // opcional, após commit próprio
```

O núcleo verifica o contrato, as flags booleanas e os três entrypoints obrigatórios antes da primeira escrita. NextItemId é chamado somente em create, depois de referências/saldo/duplicidade validados. Produção resolve a sequência fixa no provider; testes usam contador TT. Não há MAX global, sequência escolhida pelo navegador ou idempotência silenciosa.

## Request fechado

O wrapper remove resource. O serviço aceita somente operation,container_id,id,item_container_id,values. Operações create/update/delete/get. container_id e aliases de PK aceitam número inteiro JSON em formato de dígitos ou string de dígitos, positivos int32; ambos aliases, se presentes, precisam coincidir. Create recusa PK externa. Delete/get recusam values.

Create exige values.item_proc_compra_id NUMBER integral positivo int32 e values.qt_alocada NUMBER positivo na escala física2. Trata-se de alocação de um item de processo de compra existente. A referência de compra não pode mudar em update; eco numérico igual ao persistido sob lock é aceito. container_id/item_container_id não são fields editáveis de values.

Os demais onze editáveis de create/update são:

| Campo | Regra |
|---|---|
| qt_alocada,qt_confirm_emb,qt_recbto_fisico | NUMBER, não negativos antes do arredondamento, ROUND2 |
| log_rec_doc_prazo_emb,log_calc_icms,log_calc_ipi | BOOLEAN JSON |
| observacao | STRING até4000caracteres |
| cod_tipo_calculo | NUMBER integral não negativo int32 |
| perc_custo,perc_icms,perc_ipi | NUMBER, ROUND2 conforme dicionário |

Não foi inventado limite100 para percentuais nem enum para cod_tipo_calculo: o dicionário não possui essa validação. Confirmada e recebida podem superar alocada; o tipo10 financeiro usa precisamente essa diferença. qt_disponivel, preco_liquida_ima, policy, actor, contexto e nomes de tabela/programa não são entradas livres. values vazio, tipos culturais em string, null e campos desconhecidos são recusados. Campos não enviados mantêm o valor físico/default; defaults de flags do dicionário são preservados no create.

## Alocação e locks

O serviço bloqueia o mestre EXCLUSIVE-LOCK NO-WAIT e resolve a linha própria pelo par item_container_id+container_id. Antes de alterar quantidade, bloqueia o item de compra EXCLUSIVE-LOCK NO-WAIT, valida seu processo e código ERP não vazio. Não exige empresa ou fornecedor do processo iguais aos do cabeçalho: a alocação entre fornecedores/empresas é preservada como no legado.

Create recusa outra linha do mesmo container+item_proc_compra_id com409. Create e incremento positivo de qt_alocada consultam novamente todas as alocações desse item de compra, inclusive em outros containers, sob o lock do item de compra. Aplicam a validação evidenciada: `ROUND2(nova) - ROUND2(anterior) <= ROUND2(comprada) - ROUND2(SUM(alocações globais))`. Quantidade persistida desconhecida/negativa e falha de leitura não viram saldo0. Redução e edição sem incremento positivo não repetem esse gate, permitindo corrigir sobrealocação histórica. Fonte: form_itens_container_apl.php:4541–4560.

As APIs que obedecem o mesmo lock do item de compra serializam a alocação entre containers. Registros existentes da soma usam SHARE-LOCK NOWAIT. Não se promete impedir insert de escritores externos que ignorem esse protocolo nem consistência serializável do legado. Concorrência real entre sessões não é comprovada por fixtures TT.

Delete verifica descontos por item_container_id, snapshots de custo por item_container_id e vínculo comercial pelo par físico nr-container+item_proc_compra_id, antes de qualquer mutação/efeito. Referências comerciais de outro container não bloqueiam nem são alteradas. Pagamentos/compensações são responsabilidade do provider reutilizável, conforme o evento legado.

## Efeitos e atomicidade

AfterChange recebe ctx construído pelo servidor: `{operation,container_id,before,after}`, com a linha antes sob lock e a linha já alterada/excluída. Executa dentro da mesma transação. Retorno fechado: `{success:true,changes:[...],warnings?:[string]}`; audit confirmado/políticas extras no retorno são recusados. Erro, success=false, contrato incorreto ou efeito sem propriedade causa UNDO da mutação e de todos os efeitos.

Recursos de changes: containers,itens_container,despesas_container,calcs_imp_container,cta_corren_fornec_imp. Cada evento tem resource,operation(create/update/delete),recordId numérico positivo,before/after objetos coerentes. Toda imagem não vazia precisa da PK física e container_id igual ao mestre. O provider confiável é responsável por acrescentar o contexto de um ledger global tipo4, depois de comprovar sua propriedade; o núcleo não inventa esse contexto.

Eventos containers são substituídos pela captura integral do mestre antes/depois. Eventos do item principal são substituídos pela captura física final após os efeitos, incluindo eventual IPI central, sem duplicar a linha. Outros efeitos repetidos são coalescidos preservando primeiro before e compondo último after, inclusive deltas estreitos e tokens JSON inteiros.

Create/delete e diferença efetiva em qt_alocada/qt_confirm_emb invalidam a versão do mestre e gravam dt_hr_ult_alt_versao_custo com horário do servidor. Outros campos preservam flag/timestamp, salvo alteração efetiva pelo próprio provider fiscal. Update sem diferença de quantidades continua executando o evento de negócio, sem inventar invalidação.

## Resposta e auditoria

Get retorna success/data da linha contextual NO-LOCK, sem efeitos/audit; o wrapper autentica o acesso. Escrita raiz retorna success:true,committed:true,data da linha física final; delete omite data.

Somente após commit próprio:

```text
audit={version:1,source:'progress-transaction',resource:'container-itens',operation,
 recordId:item_container_id,container_id,before,after,master:{before,after},
 changes,actor:{login},warnings}
```

changes contém uma única imagem principal e os efeitos filhos, em vez de usar entrada do navegador como anterior. Flags/data e autoria são capturadas da execução real. Erro retorna success:false,error:{code,message,status}, sem audit nem pendingChanges. Duplicidade/dependências/locks/transação são409; validação/saldo/regras422; ausência404; identidade401; configuração/capacidades/sequência503. Falha da fila opcional depois do commit não transforma escrita confirmada em falha.

Transação ambiente é recusada por padrão. Com allow_nested=true privado, o serviço participa e retorna committed:false,pendingChanges,pendingMaster,pendingItem,warnings; não retorna audit confirmado nem chama LogRule. O ancestral precisa verificar success e desfazer sua transação em caso de falha, assumindo o commit e o log confirmado.

## Evidência preparada

Runner `CompileContainersItensCrudTests.p`: serviço/teste compilados sem erro no12.8 e153checks por cultura AMERICAN/EUROPEAN. RED inicial demonstrou ausência do núcleo; testes usam schemas físicos projetados em `ContainersItensCrudFixture.i` com TT UNDO e precisão/defaults do dicionário. Cobre saldo de outros containers, sobrealocação, round2, duplicidade, FK, campos/tipos/IDs, confirmada maior, dependências, fornecedor/empresa diferentes, callbacks depois da mutação, rollback integral, escopo/audit/autoria, IPI final coalescido, stale/no-op, log após commit e transação privada aninhada.

`CompileContainersItensCompositionTests.p`: compila o núcleo, Runtime real da tarefa principal, financeiro real, helper central de pagamentos e teste;9checks/cultura12.8. Atualiza linha existente sem pagamentos, evitando qualquer sequência física do Runtime. A borda fiscal é controlada; demonstra composição real, policy privada filtrada pelo Runtime, IPI final e rollback da alteração/fiscal quando o financeiro falha depois. Não substitui prova com títulos/rateios reais nem os testes específicos do financeiro.

Logs privados em `.runtime/container-itens-crud-local/`. Nenhum registro de negócio, conexão de produção ou sequência real foi executado por esta subtarefa. Compilação12.2, revisão integrada, publicação e validação PASOE são da tarefa principal; não publicar .r12.8, runners ou fixtures.
