# Motor IOL selecionável: 12.2 / 12.8

Pedido aprovado em 19/10/2026: preparar agregações no OpenEdge 12.8 e selecionar o caminho pelo parâmetro IMA, mantendo o runtime atual em 12.2.

## Parâmetro

| Campo de `espec.im-param` | Valor cadastrado |
| --- | --- |
| `cod-param` | `iol_gerencial_engine` |
| `val-param` | `12.2` |
| `tp-param` | `0` |
| `agrup_im_param_id` | `0` |

Valores aceitos: `12.2` e `12.8`. Quando o registro não existe, o padrão é `12.2`. Registro existente vazio, desconhecido ou com valor diferente dos aceitos causa erro de configuração; não há fallback silencioso. A include `sursum-api/includes/parametros_ima.i` consulta o registro diretamente `NO-LOCK`, sem cache, em cada chamada autenticada. O cliente HTTP não escolhe o motor.

`InstallIolEngineParameter.p` cadastra somente esse registro, se ausente, com confirmação explícita `-param install-iol-engine-12.2`. É utilitário de implantação, sem rota HTTP. Nunca sobrescreve valor, tipo ou grupo já existentes; um valor existente diferente de `12.2` interrompe a instalação preservando-o. O log confirma criação ou existência. Não rodar o instalador em uma instância já ativada em 12.8.

## Implementação

O wrapper permanece compatível com 12.2 e usa `IolGerencialEnginePolicy.p`. A política exige runtime pelo menos 12.8, ausência da restrição `AGGREGATE` no banco e presença do `.r` específico antes de selecionar 12.8. Configuração inválida ou ambiente incompatível retornam erro de domínio `IOL_ENGINE_INVALID` / `IOL_ENGINE_UNAVAILABLE`, status 503. O log do agente inclui `IOL_ENGINE` e a versão selecionada, sem dados comerciais ou credenciais.

`IolGerencialAggregate128.p` implementa `TOTAL` das metas mensal/quinzenal em `espec.metas_repres` e `COUNT` de pedidos pendentes em `espec.peds_web`. O total rejeita valores desconhecidos antes da soma, conservando a regra do coletor atual. Preserva competência, acesso geral, representantes e nomes do escopo autenticado. Casos sem linhas retornam zero.

O restante da coleta continua no mesmo `IolGerencialCollector.p`: faturamento com transações válidas, calendário, pedidos com junções, vendedores, notas, devoluções e descontos. O calculador e as fórmulas são os mesmos. Não duplicamos o coletor completo nem prometemos que todas as consultas passarão a usar agregação. `AGGREGATE` suporta uma agregação sobre uma tabela por instrução. [Referência Progress](https://docs.progress.com/bundle/abl-reference/page/AGGREGATE-statement.html).

O caminho 12.2 mantém uma leitura conjunta de metas mensal/quinzenal para perfis restritos. A coleta unificada de resumo e vendedores permanece, sem mudança do frontend ou dos contratos de dados.

## Migração e ativação

1. Migrar runtime/PASOE e bancos para ambiente compatível com 12.8; conferir licenciamento e compatibilidade do ERP no processo de migração.
2. Em compilador 12.8 licenciado conectado ao **schema real**, executar `CompileIolGerencial128.p` com o fonte `IolGerencialAggregate128.p` no staging. Conferir `compile-iol128.log`, `COMPILER:ERROR` e mensagens. Não usar o `.r` gerado pelos testes com schema de fixture.
3. Publicar o `.r` validado no lote ativo `sursum-api/programs/iol-gerencial-20261019-v5/IolGerencialAggregate128.r`, com backup/hash e validação no PASOE migrado. O lote publicado só contém o **fonte** desse módulo; não publica executável 12.8 no runtime 12.2.
4. Alterar `val-param` para `12.8`, validar como `tasilpar`, comparar resultados e medir desempenho real. Para selecionar novamente a coleta atual, usar `12.2`.

Alterar o parâmetro sozinho antes da migração/implantação do módulo gera erro explícito; não executa código incompatível. O parâmetro é lido por requisição, portanto não exige reiniciar para trocar seu valor. A recarga de artefatos continua seguindo o procedimento do PASOE.

## Validação disponível

Teste local em OpenEdge 12.8, banco isolado com schema de fixture: 14 verificações da política, 11 de agregação, 14 de identidade/coleta, 20 do calculador, fronteira sem autenticação, três comparações do snapshot completo (vendedor, gerente/hierarquia3 e geral) e cinco verificações do instalador por cultura `AMERICAN` / `EUROPEAN`. Teste adicional rejeita instalação sem confirmação. Registros de teste são desfeitos por rollback. O banco local não se conecta ao ERP.

Runner: `node tools/construtor-local/test-iol-local128.cjs`. Evidência privada: `.runtime/iol-engine-20261019/local128full/verification.json`. Isso confirma comportamento local, não comparação de desempenho nem execução 12.8 no PASOE real.

## Estado de implantação

**Publicado e validado em 19/10/2026, `sursum-api/med`.** O acesso de rede foi restabelecido durante a entrega. Dez fontes compatíveis foram compilados sem erros no OpenEdge 12.2 do `.42`; 14 verificações de política, 14 de identidade/coleta, 20 do calculador e fronteira401 passaram por cultura AMERICAN/EUROPEAN. O instalador criou o registro real `iol_gerencial_engine = 12.2`, sem sobrescrever registros existentes.

Lote ativo `iol-gerencial-20261019-v5`: 13 artefatos, dos quais cinco `.r` compatíveis com 12.2. O `.r` de agregações12.8 não foi publicado. Troca atômica somente da rota IOL, preservando o catálogo concorrente e conferindo os hashes de v4 e v5; sem reinício. Manifesto privado `.runtime/iol-engine-20261019/publish/active-manifest-v5.json`; backup remoto `/tmp/codex-iol-engine-20261019/backup-20261019T122121Z`.

API real validada como `tasilpar`: resumo1/vendedores6, compatibilidade dos recursos separados e cinco negativas (token, identidade, escrita e duas tentativas de informar motor/identidade pelo corpo). Recibos privados `pasoe-verification.json`, `compiled122/iol-engine-parameter-install.log` e `runtime-inspection.json` sob `.runtime/iol-engine-20261019/`.

Inspeção final confirmou rota v5, banco de produção `dbprod_IMA_espec` na porta10012, logs `IOL_ENGINE` com `engine=12.2 runtime=12.2` e ausência de `IolGerencialAggregate128.r`. A instalação do servidor segue OpenEdge12.2.17. Não houve reinício, mudança de autenticação ou escrita comercial.

O hash da resposta coletada antes da publicação diferiu do recebido depois; não usamos isso como prova de paridade. Foi feita uma comparação direta v4→v5→v4 na base real, somente leitura, com escopo IMA de `tasilpar`: três rodadas com snapshot completo igual e legado estável. Evidências `compile-iol-live.log` e `iol-engine-live-comparison.log`. A causa específica da variação entre respostas HTTP não foi identificada; a paridade direta dos coletores passou. Nenhuma fórmula foi alterada.

Revisão independente somente de leitura concluída, sem defeito funcional confirmado no estado revisado. Posteriormente, a paridade local foi ampliada para gerente/hierarquia3 e geral, e o teste de restrições com espaço após a vírgula reproduziu RED e passou após normalização. Fontes canônicos sincronizados com hashes e backup; nenhum frontend, Kendo, permissão ou autenticação alterado.

## Avaliação da solução

O usuário destacou estabilidade, centralização das conexões/licenciamento pelo PASOE e auditoria de chamadas como benefícios da API. A auditoria de execução já foi comprovada no sistema. Estabilidade sob carga e economia contratual de licenças não foram quantificadas neste benchmark e dependem do ambiente e do contrato Progress. A comparação de 17/10 mostrou empate prático na mediana; tempo de resposta é apenas um dos critérios da decisão.

Validacao complementar em19/10/2026: o modulo IolGerencialAggregate128.p tambem compilou no OpenEdge12.8 local conectado ao schema REAL de espec (192.168.0.111:10012), sem erros e sem executar agregacoes no banco12.2. Artefato e hashes privados em .runtime/iol-engine-20261019/compiled128-real-schema/verification.json. Esse.r NAO foi publicado no PASOE12.2. Manter a validacao no PASOE migrado e recompilar quando o schema/ambiente da migracao exigir. A selecao ativa permanece12.2.
