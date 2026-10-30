
Referencia de implementacao: workspace D:/opencode/conversao-sc.

## Consulta NF/devolucoes e API WP: publicada e validada — 20/10/2026

Usuario autorizou completar a BO original e ampliar include; preservar convencao tipo_nota. Trabalho CONCLUIDO e substitui o levantamento/bloqueios anteriores desta consulta. Fontes em integration-src/buscar-devolucoes/; copia canonica D:/opencode/motor-progress/v2/especificos/ems2/ima/ e publicada \\192.168.0.137\erp\especificos\ems2\ima\. BOs esbo/boConsNotaFiscal.p e esbo/boConsDevolucoes.p sao persistentes por setters; nenhuma recebe TT de filtros. Chamador esapi/consulta-notas/ConsultarNotasFiscais.p recebe INPUT TABLE ttFiltroDevolucoes e OUTPUT TABLE tt-NF, configura ambas por setters e agrega usando TTparcial, fecha handles em FINALLY. Adaptador BuscarDevolucoes.p mantido.

TT parametros definida em esapi/consulta-notas/ttFiltroDevolucoes.i, exatamente1linha: empresa IMA/MED e seis faixas inclusivas independentes de estabelecimentoCHAR, clienteINT, notaCHAR, pedidoCHAR nr-pedcli, representanteINT cod-rep e emissaoDATE. ?/texto vazio abre limite,0 e valor real, faixas invertidas erro. Include CANONICA esbo/boConsNotaFiscal.i agora21campos:14originais preservados + tipo-nota,cod-emitente,cod-rep,nf-original,nr-pedcli,preposto,dt-emis-nota. Snapshot references/esbo/boConsNotaFiscal.i de14campos e historico, nao usar na compilacao atual. Recompilar consumidores ao alterar TT; auditoria137 em esbo/esapi/http-api encontrou somente BOoriginal como consumidor, hash original inalterado antes substituicao.

BO NF completada: exec OUTPUT TT/getTTDados, setters existentes preservados (setNumeroPedido INT interno e setRepres CHAR nome), novos setters comuns de faixa nr-pedcli/cod-rep. Venda exclui canceladas/eletronica4, natureza receita diferente devolucao, pedido com ped-repre; corrigida escolha FIRSTpedido que descartava NF elegivel quando primeiro pedido nao tinha representante. Um registro por NF. Desconto conforme PHP: soma trecho char-2 itens em formato brasileiro independente da cultura. Devolucao preserva formula prioridade/negativos, origem por chave completa, motivos distintos. Preposto/comissao coletados em ConsultaNFContexto.i compartilhada, pelo pedido interno e representante principal. data da devolucao=dt-trans; dt-emis-nota=docum-est.dt-emissao.

Convencao REAL tipo_nota confirmada por contagens agregadas limitadas, sem exportar dados comerciais:100registros tipo20 negativos/com motivo e100tipo22 positivos/sem motivo. Antiga investigacao limitada a0..9 nao demonstrava tabela vazia e esta supersedida. tt-NF.tipo-nota copia esp-docto da origem, writer copia exatamente, sem inventar1/2 ou inferir pelo sinal.

API http-api/api_cons_nota_fiscal_wp.p, INPUT/OUTPUT JsonObject. POST /SursumPrograms/consulta-notas-fiscais-wp em sursum-api/med HTTPS9911. JSON raiz: login (aliases usuario,userName,requestUser), empresa, estabIni/Fim CHAR, clienteIni/Fim INT, nrNotaIni/Fim CHAR, nrPedidoIni/Fim CHAR cliente, represIni/Fim INT, dtEmisIni/Fim ISOYYYY-MM-DD; pagina/filtro opcionais. Tipagem estrita, sem arredondar fracionarios/expoentes; objetos internos desconhecidos nao alteram filtros. Como APIpedidosref: usuario tipo2 em espec.user-web força ambos limites pelo representante nome-ab-cli/fallbackLogin resolvido em ems2cad.repres; ausente/outros tipos preservam faixa. Login recebido nao e prova de autenticacao.

ConsultaNotasWpWriter.p separado/reutilizavel: espec.wp + espec.wp_nota_fiscal FISICA UNDERSCORES,18campos explicitos em transacao raiz unica. Recusa transacao externa, sucesso somente aposcommit; erro desfaz cabecalho/todosfilhosnovos, nunca apaga pesquisas anteriores. UUID codWp com verificacao existencia, indices reaisNAOUNICOS (nao alegar garantia DBunicidade). Original CHAR viraINT estrito; vazio=0, alpha/overflow erro rollback. Resposta {success:true,codWp,total,inserted}; erro semcodigoparcial. Pesquisa vazia grava cabecalho0filhos.

Oficial12.2.12/.42:12prod compilados SAVE schema real espec/ems2cad/ems2med. Workers IMA compilados com alias schemaMED; RCODE-INFO comprovou DB-REFERENCES ems2ima,espec para IMA e ems2med,espec para MED. Nao alegar validacao de banco/instanciaIMA. Seis suites em fixture sintetica exclusiva:55devolucoes+16integracaoBOs+30parser+21writer+7escopo+17APIreal=146checks em CADA cultura AMERICAN/EUROPEAN,13tabelaslimpas. APIreal exercita cadeia completa com duasBOs, escopotipo2 e rollback na segunda linha. Antigos7checks com chamador substituto NAO contam nesses146. Revisao independente final sem novos defeitos concretos.

Publicacao:21fontes/includes+12.r12.2,33artefatos em cada destino (ERP137 e canonical),66hashes conferidos; backup/mutacao condicionada aos hashes anteriores. Manifesto source->compiled->target privado. Rota aditiva mesclada: servidor23->24 rotas, checkout14->15, preservadas existentes. Router le registro por dispatch; sem restart, PROPATHglobal, schema ou troca de instancia. Nenhum fixture/DF/teste/.r12.8 publicado. Compartilhamento e compilador acessados por entrada protegida, sem persistir credenciais.

PASOE sursum-api/med9911:3requisicoes invalidas HTTP200 successfalse semcodWp (login ausente, cliente decimal, faixa invertida) e1pesquisa vazia marcada HTTP200 successtrue,total0,inserted0. Probe12.2 conectado direto ao DB confirmou commit do cabecalho espec.wp/tabela wp_nota_fiscal,0filhos. Cleanup privado comparou os6campos da imagem inteira antes de excluir somente esse cabecalho e confirmou ausencia final. Nenhuma NF/pedido/usuario de negocio criado ou alterado. Testes com linhas exercitados apenas no banco sintetico. Sem pendencias desta entrega em MED.

Evidencias privadas .runtime/consulta-nf-api-20261020/: official/ (compile-production.log, validation.log,6logsassertivas ecompile-runtime-check), source manifest em package/source-manifest.json, share-audit.json, publish-plan.json, publish-receipt.json,publish-backup/,rcode-references.log,pasoe-negative.json,pasoe-positive.json,runtime-header-before.json,runtime-check-inspect.json e runtime-check-cleanup.json. Ultimo contem success/actioncleanup apos comprovacao ausencia. runtime-control e guard pasoe-write-attempt preservados para NAO repetir mutacao. Utilitario privado RuntimeWpCheck.p foi compilado/executado somente no staging .42, nao publicado como rota. Documentacao READMEs atualizada.


## Instancia padrao — determinacao de 25/09/2026

Usar sempre a instancia sursum-api, contexto med, HTTPS 9911 (https://192.168.0.111:9911/med/web). Usar sursum-api-teste/9921 somente quando o usuario pedir explicitamente. Esta determinacao substitui as orientacoes anteriores deste documento que indicam a instancia de teste como padrao; registros de validacoes anteriores continuam historicos.

# Contexto OpenEdge, Compilacao e PASOE

Atualizado em 2026-09-25.

## Procedimento obrigatorio atual

Usar [motor-progress-publicar-pasoe](../skills/motor-progress-publicar-pasoe/SKILL.md) depois de alterar fontes ABL/OOABL ou configuracoes de runtime. A entrega inclui compilacao 12.2, publicacao no compartilhamento e validacao HTTP no PASOE; testes locais isolados nao encerram a tarefa. A regra foi explicitamente solicitada pelo usuario em 25/09/2026.

O alvo padrao de validacao desta entrega e `/dados/pasoe/sursum-api-teste`, contexto `med`, `https://192.168.0.111:9921/med/web`. Se for necessario reiniciar para carregar os compilados, usar apenas os scripts dessa instancia, aguardar prontidao e preservar as demais. A instancia `sursum-api`/9911 descrita abaixo permanece como referencia de outro ambiente, nao como destino alternativo automatico.

Confirmado: compilador Windows `192.168.0.42`/OpenEdge 12.2.12 e runtime Linux `192.168.0.111`/12.2.17. O Linux recusa compilacao de fontes por licenca (471). Usar o compilador Windows; o OpenEdge 12.8 local serve apenas para verificacoes auxiliares.

A pasta `\\192.168.0.137\erp\especificos\ems2\ima\http-api` tambem contem programas. No Linux ela corresponde a `/mnt/datasul/ERP/especificos/ems2/ima/http-api`. O roteador aceita esse prefixo relativo e resolve pela raiz ERP no PROPATH. Ver [roteador JSON](../docs/JSON_PROGRAM_ROUTER.md).

## Ambientes conhecidos

### Servidor web

Workspace Linux:

```text
/var/www/clients/client1/web7/web/motor-progress
```

URL base:

```text
http://php81.imatextil.com.br/motor-progress/
```

### PASOE runtime

Servidor:

```text
192.168.0.111
```

Instancia:

```text
sursum-api
```

Endpoint por empresa:

```text
https://192.168.0.111:9911/{empresa}/web/SursumDynamicQuery
```

Exemplo MED:

```text
https://192.168.0.111:9911/med/web/SursumDynamicQuery
```

Runtime Linux:

```text
/mnt/datasul/ERP/sursum
```

Share Windows equivalente:

```text
\\192.168.0.137\erp\sursum
```

Regra operacional: reiniciar somente a instancia alvo definida para a tarefa. O fluxo atual de validacao usa `sursum-api-teste`; `sursum-api` so deve ser alterada quando for o destino explicitamente solicitado. Nao mexer nas demais instancias PASOE.

Comandos historicos para o ambiente `sursum-api` (nao usar para a validacao atual em `sursum-api-teste`):

```bash
/usr/dlc12/servers/pasoe/bin/tcman.sh stop -I sursum-api
/usr/dlc12/servers/pasoe/bin/tcman.sh start -I sursum-api
```

### Host de compilacao Progress

Servidor Windows:

```text
192.168.0.42
```

Workspace:

```text
C:\opencode\motor-progress
```

OpenEdge:

```text
C:\Progress_12\OE\bin\_progres.exe
```

Banco de validacao:

```text
C:\opencode\motor-progress\db\sports2000
```

Comando padrao validado:

```powershell
Set-Location C:\opencode\motor-progress
& C:\Progress_12\OE\bin\_progres.exe -b -db C:\opencode\motor-progress\db\sports2000 -1 -ld DICTDB -p C:\opencode\motor-progress\temp\ValidateSursumCurrent.p
```

Verificar COMPILER:ERROR, ERROR-STATUS, logs e artefatos gerados nesta execucao. Exit code 0 e silencio no terminal, isoladamente, nao comprovam sucesso de compilacao.

## Publicacao de .r

Depois de alterar `.cls`, `.p`, `.w`, `.i` ou `.df`, copiar o fonte para `192.168.0.42`, compilar e publicar os `.r` gerados para o runtime.

Arquivos importantes publicados em duplicidade por causa do PROPATH:

```text
DynamicQueryWebHandler.cls/r
sursum-api/rest/DynamicQueryWebHandler.cls/r
rest/DynamicQueryWebHandler.cls/r
ViewAsIncludeResolver.p/r
sursum-api/sursum/ViewAsIncludeResolver.p/r
sursum-api/sursum/RunViewAsIncludeResolver.p/r
```

O handler nao tem package, entao `DynamicQueryWebHandler.cls/r` tambem precisa existir direto na raiz `sursum`.

## PROPATH relevante

Para o runtime e compilacao do resolvedor:

```text
sursum-api/sursum
sursum-api/rest
sursum-api/workers
sursum-api/runners
sursum-api/sursum/esp
ems2
raiz do workspace
OpenEdge.Net.pl
```

`ems2` e necessario para resolver includes como `cxinc/i01cx373.i`.

## View-as e erro Progress 471

O PASOE pode retornar:

```text
Esta versao de PROGRESS nao permite compilacao de programas fontes. (471)
```

Isso acontece quando uma chamada tenta compilar/expandir fonte em runtime. Para evitar esse caminho:

- `POST /metadata/view-as/resolve` tenta resolver via SSH quando o ambiente possui `servidor` e `usuario`.
- `RunViewAsIncludeResolver.p` executa no host onde ha compilador e PROPATH com `ems2`.
- O fallback local contem tratamento direto para `cxinc/i01cx373.i`, retornando `Ativo,Inativo`.
- `ViewAsIncludeResolver.p` tambem contem a entrada `cxinc/i01cx373.i`.

Validacao feita em 2026-06-17:

```json
{
  "field": "idi-situacao",
  "listExpression": "Ativo,Inativo",
  "options": [
    { "label": "Ativo", "value": "Ativo" },
    { "label": "Inativo", "value": "Inativo" }
  ]
}
```

## Diagnostico PASOE

Endpoint adicionado:

```text
GET /diagnostics/runtime?waitSeconds=:seconds&label=:label
```

Uso: verificar comportamento de agentes e concorrencia. Se quatro requisicoes simultaneas demorarem mais que uma a uma, investigar configuracao de agentes/sessoes do PASOE, nao apenas Java/Tomcat estar no ar.

## Local historico Windows

Contexto antigo ainda aparece em docs:

```text
D:\opencode\motor-progress
C:\Progress\OpenEdge
PASOE local sursumpasoedev em http://localhost:8890
```

Esses caminhos sao historicos de desenvolvimento local. Para o fluxo atual, priorizar `192.168.0.42` para compilacao e `192.168.0.111` para runtime PASOE.


## CIW: novos cadastros e prioridade do usuário —20/10/2026

Determinação vigente: converter outras aplicações e deixar permissões CIW por último. Substitui o gate histórico de1A; preservar autenticação/controles atuais. Não pedir novamente login tcassimiro para bloquear cadastros. Conta corrente fornecedor do menu Tarefas continua excluído. Regra documentada em integration-src/ciw-inventory/conversion-scope.json.

Publicados pelo Builder no frontend oficial, versão1.0.0: ciw.coloracoes/cd0094; ciw.situacoes-container/cd0095; ciw.tipos-versao-custo/cd0096; ciw.motivos-desconto/cd0097. Quatro formulários com CRUD/lote validado via runtime; consultas correspondentes parcialmente absorvidas, apresentação/filtros/navegação e conferência visual ainda pendentes. Navegador permanece no login humano; não houve substituição da sessão do usuário. Catálogo23telasCIW com definiçãoHTTP200; não equivale a262programas convertidos.

Nova API fechada POST /SursumPrograms/ciw-cadastros: serviço privado compartilhado CiwCadastroCrudService.p, CiwCadastroDefinition.p, wrapper CiwCadastrosCrud.p. Canonicos motor-progress/v2/sursum-api/programs; testes em tests/abl/ciw-cadastros. Metadata e hook de auditoria no construtor-pg, sem frontend paralelo/Kendo/schema. OpenEdge12.2/.42:5fontes sem erro,60checksTT por culturaAMERICAN/EUROPEAN;8checks de definição emUTF8/ISO8859-1. Publicado via111 no compartilhamento137; PASOE sursum-api/med. Erro16063 de JSON reproduzido e corrigido com FIX-CODEPAGE UTF8 antes da atribuição. Refresh oficial somente sessões med ociosas após delta p/r com backup/hash.

CRUD real4recursos: inclusão/lote misto/conflito/rollback posterior/campo extra recusado; apenas novos registros CODEx, todos removidos e dados anteriores preservados. Revisão independente1P2: batchAuditSnapshots aceitava sótipos_anexo e descartava snapshotsdosnovosrecursos. RED/GREEN confirmou correção fechada, sem relaxar vínculo entidade/fonte/rota/recurso. Segunda rodada real e consulta RO provaram28eventos/4recursos, estados antes/depois e ator da sessão apesar do header forjado no teste. PHP536testes/3206asserções PASS. Evidências privadas .runtime/ciw-cadastros-20261020/{real-crud-evidence.json,audit-evidence.json,publish/active-manifest.json}; não expor conteúdo de configuração técnica. Documento público D:/opencode/conversao-sc/docs/ciw-cadastros-validacao-2026-10-20.md e inventário atualizado.

Próxima ordem: Despesas×Impostos (PK física3campos, validar referências, não inventar ID), ParâmetrosIMA (PKtextualcod-param, camposlegados; consumo includeparametros_ima.i diretoNOLOCKsemcache), resolver origem de TiposValor/Empresas×Imposto; conferir TiposAnexo/logs/navegação e seguir fases do inventário. Duas tabelas tipos_valor/empresas_imposto declaradas nos formulários NÃO encontradas no dicionário espec/.111. Perfilprincipal especw usaDSNespec_w_pro, mesmo espec/111SQLbroker10112; ticontrole2 é auxiliar, não assumir origemSQL por biblioteca replicada. Catálogoticontrole não as encontrou; ODBC legado não conectou. Pergunta assíncrona ao usuário sobre uso dasduastelas pendente; não impede demais cadastros.

Sem novosgrantsdenegócio/alteraçãohumanadecontas/commit/push/reseed; preservados trabalhos concorrentes. Fase1A humana e integração de permissões continuam parciais, agora ao final. Não marcar fase1 inteira concluída nem repetir processos de autenticação já autorizados.


## CIW: Parametros IMA publicado e Despesas x Impostos absorvido —20/10/2026

Usuario reafirmou executar ambos com permissoes por ultimo. Entrega EFETIVA: Parâmetros IMA cd0098/ciw.parametros-ima1.0.0 publicado pelo Builder; Despesas×Impostos mantido pela colecao impostos de cd0093/ciw.empresas-despesa1.0.1 (Despesas→Empresas→Impostos que usam esta despesa na base). Reutiliza DespesasCrudService.p::SyncChildren, chavefisica despesa_id/imposto_id/empresa_id; referencia de imposto e despesas.log_imposto=1. Nao criar tabela impostos, IDartificial ou segundo writer. DiagnosticoRO real12vinculos,0semparent/empresa/base/imposto; todosalcancaveis pelo fluxo. Consulta globallegada e apresentacao/filtros/visualizacao continuam parcialmente absorvidos; nao alegar paridadevisual total.

Novo CiwParametrosService.p e delta CiwCadastrosCrud.p publicados p/r12.2 no137 via111, PASOE sursum-api/med, mesma rota/configtoken existente; manifesto/backup/hash em .runtime/ciw-keyed-20261020/active-manifest.json. Refresh oficial somente sessoesmedociosas. Campo codigo e aliasUI de PKtextualcod-param (readonlyOnEdit existente); row_stamp oculto SHA256estadofisicocompleto rejeita estadoobsoleto, grupoagrup_im_param_id preservado. Camposlegadosvalor/tipo1..5 (0legado) mantidos. ConsumopelasAPIs segueincludeparametros_ima.i diretaNOLOCKsemcache. Nao confundir editor administrativo com outro mecanismo de consumo.

Backend canonico: RuntimeCiwParametroAudit contrato fechado comIDtextual; pequeno hook emRuntimeApiEntityActionService. RuntimeTransactionService omite val_param/val-param do contexto e dos snapshots antes/depois/diff, inclusiveget, para nao copiar valorespotencialmentesecretos aojournal. Auditoria conservaidentidade/grupo/hash/ator. Novosmetadados B/integrations/ciw-parametros; testesbackend eABL em M/tests/abl/ciw-parametros. Nova sincronizacao porguards .runtime/ciw-keyed-20261020/canonical-manifest.json; syncantigo ciw-cadastros devefalhar porhash se tentado, nao sobrescrever o hooknovo. Preservar trabalhos concorrentes.

Provas: SSHinicialexpirou; usuario informourestabelecimento darede e oficial12.2/.42 concluiu4fontes semerro. Parametros71checks emCADA culturaAMERICAN/EUROPEAN eCPUTF8/ISO8859-1; despesas229checks/cultura comfixturesTTsomente. Diagnostico12.8 NAOpublicado. PHPcanonico542tests/3237assertions. Builderdraftvalidado epublicado; fonteAPI mesclada com5operacoes preservandoheadersmascarados server-side. Catálogo24telasCIWHTTP200, nao262convertidos.

PASOEreal pelobackend: parametroCODExnovo comapostrofo/acento, CRUD/get, conflitohash, chaveimutavel, limite500; novabase/novoimposto e2vinculosemempresasexistentes somentecomo referencia. Isolamentoentreempresas e rollbackconfirmados. TODOSosregistrostestadosCODExnovosremovidos; test-ownership.json vazio. AuditoriaRO confirmou3eventosparam+5vinculos, ator da sessaoapesarheaderforjado, valores ausentesdosjournals/contextos. Antigos4cadastros continuam lendo pelowrapper novo. Revisaoindependente semdefeitoconcreto. Evidencias privadas .runtime/ciw-keyed-20261020/{real-validation.json,impostos-coverage.json,compiled122/,publication-im-param.json}; nao exporconfiguracoes.

Documento publico D:/opencode/conversao-sc/docs/ciw-parametros-impostos-validacao-2026-10-20.md e inventarioatualizado. Conferenciavisualpendente (nao alterar sessao humana paraautoteste). Restantes: TiposValor/Empresas×Imposto precisam origem/schema; consultastiposAnexo/logs/navegacao e demaisfases. PermissoesCIW/humanotcassimiro ficam aoFINAL, semimpedirconversoes. Conta corrente fornecedor continuaexcluido. Semnovasconcessoesdenegocio/contashumanas/commit/push/reseed/schema/Kendo.


## API estoque JSON sem WP — concluída em21/10/2026

Pedido do usuário: adaptar o padrão http-api/api_cons_nota_fiscal_wp.p para receber filtros JSON, chamar o cliente da BO e devolver o resultado na própria chamada, sem persistir em WP; gravação futura em outro banco é responsabilidade do PHP.

Implementado integration-src/saldo-pv/http-api/api_cons_estoque.p e esapi/estoque/EstoqueJsonParser.p + EstoqueUsuarioEscopo.p. POST /SursumPrograms/consulta-estoque, INPUT/OUTPUT JsonObject. Filtros TT na raiz, selecoes array de tipo/codigo/codigo2/numero. Login obrigatório (aliases usuario/userName/requestUser consistentes); tipoUsuario/representante não recebidos: leitura NO-LOCK espec.user-web e ems2cad.repres para tipo2. Login não autentica; consumidor deve passá-lo da sessão autenticada. Demais filtros mantêm defaults da include, inclusive faixas item/família vazias até14z. Tipagem estrita, inteiros sem fração/expoente; null apenas nos seis limites decimais opcionais; parâmetros desconhecidos recusados. Null opcional teve regressão RED/GREEN e usa allowlist explícita, sem depender INITIAL do handle.

Chama esbo/clienteSaldoPV.p, que chama BO. Resposta integral {success,totalItens,totalSaldos,itens,saldos}, sem paginação; todos os campos TT com números e nulls nativos JSON. Falha {success:false,error,contadores0,itens:[],saldos:[]}; vazio válido success true. Sem codWp/inserted, writer ou gravação em wp/tabelas filhas. Normalização de oportunidade e validações continuam no cliente; complemento PHP sem filtros continua desconsiderado por decisão do usuário. Nenhuma alteração na BO original, boSaldoPV/include ou cliente publicado.

Oficial OpenEdge12.2/.42: três programas compilados SAVE contra schema real espec/ems2med/ems2cad;52checks JSON +105BO +62cliente em CADA cultura AMERICAN/EUROPEAN. Fixture isolada com rollback, nenhuma mutação de negócio em banco real. Revisão independente sem bloqueadores após incluir escopo tipo2, container exclusivo autorizado/recusado, aliases divergentes, nulls e desconhecidos após handle válido.

Publicação .137:6artefatos novos p/r em especificos/ems2/ima/{http-api,esapi/estoque}; checkout canônico motor-progress/v2 recebeu mesmos6 +5dependências de estoque já publicadas. Duas rotas mescladas (servidor/canonical) preservando catálogo,19hashes +5dependências conferidos. Sem restart, schema, PROPATH global ou autenticação alterados. PASOE REAL sursum-api/med HTTPS9911:13chamadas somente leitura com tasilpar, incluindo código/descrição, referência, mínimo, seleção ativa vazia, consulta vazia, aliases, null opcional e6erros. Item175182 PE50/PI18200; REF A01 PE-1/PI11200; mínimo2 referência3linhas. Descrição retornou mesmo array de itens que código, limitado ao mesmo item. Resolve a pendência anterior de consumidor/validação PASOE de boSaldoPV.

Contrato/exemplo docs/api-cons-estoque.md; fontes integration-src/saldo-pv, cópia canônica motor-progress/v2/especificos/ems2/ima. Evidências privadas .runtime/estoque-json-20261021/: official/verification.json e logs/XREF, publish-receipt.json +backup, pasoe-results.json, pasoe-additional.json, final-verification.json. Não expor payloads privados/credenciais. Persistência PHP no outro banco não implementada, pois pedido desta etapa é a API. Não generalizar os13casos para comparação exaustiva de todos os dados/preços do portal.


## De/para estoque — implantação parcial, ativação pendente22/10/2026

Usuário aprovou cadastro específico, BO/cliente/API somente (PHPlegado fora) e
segunda seleção APENAS quando etapa1 não encontra candidatos. Todas palavras
originais mapeadas são substituídas juntas uma vez, sem cadeia. Etapas2/3 de
saldo/minimo nunca acionam nova busca. Interface TT/JSON e formulas preservadas.
Regras iniciais previstas CAMBRAYA→CAMBRAIA, CAIMAN→CAYMAN, ELASTANO→ELAST..

Implementado em integration-src/saldo-pv: esbo/normalizarPesquisaEstoque.p,
termosPesquisaEstoque.i compartilhando validacao/gramatica numerica; delta na
boSaldoPV; sursum-api/programs/EstoqueTermosCrudService.p e recursofechado
estoque_termos no CiwCadastrosCrud.p; PHP RuntimeEstoqueTermoAudit +hookrestrito
no backendcanonico. CRUD chave textual normalizada imutável, ativo/destino,
concorrencia SHA256, transacaoraiz e imagens antes/depois; bloqueia numericos
inclusive1E3/2E-2 (achadoP2 reproduzidoRED/corrigidoGREEN). Revisao final sem
outro bloqueador.113BO+62cliente+52JSON+23CRUD em CADA cultura12.2/.42;
PHP660tests4292assertionsPASS sem cachewarning. Metadados preparados
metadata/estoque-termos-builder-draft.json: cd0190/iol.estoque-termos-busca,
entity estoque_termos_busca_progress, fonte existente motor_progress_ciw_cadastros.

SCHEMA REAL APLICADO: espec.estoque_termo_busca, termo_digitadoCHAR chaveunica,
termo_pesquisaCHAR,ativoLOG, area dados. Catalogo nao tinhaequivalentes. Primeira
tentativa semNEWOBJECTS aguardouexclusivo; somente proprioPID5412 comcomando e
creation1792699252892 validados foi encerrado. Guard schema-attempt.json remoto
preservado. Segunda tentativa prodict/load_df.p arquivo,,NEW OBJECTS concluida,
3camposrelidos; semforcecommit,nenhumrestart,nenhumobjetoexistentealterado.
NAO reaplicar schema; guard schema-online-attempt.json. DDLcanonico
motor-progress/v2/schema/espec/estoque_termo_busca.df.

PUBLICADOS18artefatos (9share137+9canonical): helper/include/BO emesbo,
service/wrapperCIW emsursum-api/programs; backups/hashguards,originalboSaldo.p
preservado. A compilacao real dos4p12.2PASS. Nao confundir publicar arquivo com
ativar AVM. PASOE sursum-api/med9911 ainda usa dispatcherantigo: probe get
estoque_termos retornaCIW_CADASTRO_RESOURCE_INVALID. SSHkeyroot@111 recusada.
Solicitada conta/chaveautorizada ou equipe executar recarga oficial SOMENTE
sessoesmedociosassursum-api. Semtentar senhadeoutroservidor,semfallbackinstancia.

PENDENTES OBRIGATORIOS: recarga/confirmar novo recurso; rodar import-screen.cjs
viaBuilderoficial (preflight barra antes de mutar fonte/entidade enquanto API
naoativa), registrar5operacoes e publicar tela; cadastrar3regras viaAPI/PHP com
auditoria; testesreaisdebusca/cadastro/concorrencia/auditoria comregistrosnovos
marcados ecleanup; atualizarhomecomlinkseconveniente sem mudarpermissoes; QAUI;
registrofinal. TelaAINDA NAOpublicada;3regrasAINDA NAOcadastradas; validacaoPASOE
do comportamentonovo AINDApendente. Nao repetir mutacoes/guards concluídos.

Docs docs/estoque-termos-busca.md e estoque-termos-execucao.md. Privado
.runtime/estoque-termos-20261022/: schema-inspect/reference/applied,official,
compiled122,fixture-source-manifest,php-full,publish-receipt,probe e
pending-verification.json. Compilador SSH session38126 e SMBsession45459
encerrados ao parar; credenciais nao persistidas. Prova de113checks reforcada
com candidatoELASTX que nao deve satisfazer pontoELAST.literal.


## De/para estoque CONCLUÍDO22/10/2026 — substitui pendência anterior

Acesso administrativo .111 fornecido nesta conversa, usado só em getpass; nenhuma
credencial persistida. Recarga oficial somente2sessões med IDLE na sursum-api,
mesmoPID3856625, semrestart/instânciaalternativa. Novo recurso estoque_termos ativo.
Tela cd0190/iol.estoque-termos-busca1.0.0 publicada viaBuilder versão60/aprovação59,
fonte **motor_progress_estoque_termos** exclusiva com5operações, MESMAAPI/token.
Motivo: fonteCIWcompartilhada temoperaçõescontextuais deoutrosrecursos eBuilder
exige seuscamposint naentidade; não alterarBuilder ou adicionar camposfalsos.
Foram removidos APENAS5acréscimospróprios dafonteantiga, demaisoperaçõespreservadas.
ClasseRuntimeEstoqueTermoAudit e testes ajustados a essa fonte exclusiva.

Regra confirmada: apenas etapa1vazia → todaspalavrasoriginais corrigidas juntas,
umaúnica segunda seleção. Saldo/minimos posteriores nunca reabrembusca. Semalterar
contratoJSON/TT, cálculos ou PHPlegado. Tabelaespec.estoque_termo_busca criadaonline
anteriormente, NAOreaplicar. Trêsregraslegítimas cadastradaseativas viaPHPadmin:
CAMBRAYA→CAMBRAIA,CAIMAN→CAYMAN,ELASTANO→ELAST.. Semproduto/saldo/WPmutado.

Validação REAL tasilpar:14consultasPASOE; CAMBRAYA vazio semdepara→mesmoitem/saldos
CAMBRAIA; CAIMAN idemCAYMAN. Duas/três palavraspositivas comprovadas com2aliases
temporáriosnovosSC-TESTE→FIO/BRANCO e CAMBRAYA, comparadosaCAMBRAIAFIOBRANCO noitem
175182. Aliasesremovidos porimagemexata eGET404. Não afirmar que CAYMANELAST. tem
produtoreal: nenhum dos3CAYMANconsultados continhaessaabreviação. Fixture12.2
comprovou3regrasaprovadas simultâneas e pontoliteral versusELASTX.

CRUD realPHP:1registroSC-TESTE incluídoinativo, alteradoativo, stampobsoletorecusado,
excluído eGET404. Trêseventosauditados comimagens/autoriaadminconferidosapóscleanup.
LogsdoRegistro/LogsExclusão nativos tambémconferidos comchavetextual. Para isso,
RuntimeEntityActionService ganhou escopotextual EXCLUSIVOiol.estoque-termos-busca,
tenant/tela/identidadeexata mantidos, p_hashcontinua restritopagamentos.2testes
RED→GREEN, backendfinal662tests4295assertionsPASS. Revisãoindependentefinal
nenhumdefeitoconcreto. Oficial12.2 anterior113BO+62cliente+52API+23CRUDpercultura
mantido; ABLnãoalterado após publicação18artefatos. Hashesreconferidos.

UIverificadanavegadorisolado semtrocar sessãodousuário:grade3regras, Ativodefault,
Digitadoimutáveledição; nenhumformuláriosalvo. Homeassinada recebeu1link em
CIW→Cadastros e parâmetros, permissõeshumanas intactas. URLlocal
http://127.0.0.1:8765/production/app.html?screenId=iol.estoque-termos-busca .
TodoCRUDdeteste removido(3registros), apenas3regrasdefinitivaspermanecem.

Evidências privadas .runtime/estoque-termos-20261022/: med-session-refresh.json,
publication-estoque-termos.json,initial-rules.json,crud-real.json,confirmed-audit.json,
native-record-log-scope.json,stock-real-results.json,stock-multiword-verification.json,
multiword-cleanup.json,source-cleanup.json,ui-verification.json/home-link-publication.json,
final-runtime-read.json,php-full-final.log e **final-verification.json**. Scan sem
tokenprivado nosarquivosgerados/fontes. NÃOrepetirschema/publicação/seeds/fixtures:
guardsdefinitivos existem. Contextoanteriorparcialé histórico; pendênciadestaentrega
nenhuma. NovaFonteAPI eLogsdechavetextual são decisõesprevalentessobreplanooriginal.
