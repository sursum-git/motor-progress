# Empresas: implantação e verificação

Programa `cd0090`, módulo `cadastros`, tela `ciw.empresas`, entidade API `empresas_progress`, fonte `motor_progress_empresas`.

O frontend é o original de `D:\opencode\construtor-pg`. Os JSONs ficam em `integrations/ciw-empresas`. Nenhum dado empresarial foi copiado para PostgreSQL. O PHP chama o programa ABL pela rota POST `/SursumPrograms/empresas`.

## Ambiente

- Compilador confirmado: OpenEdge 12.2.12, Windows 192.168.0.42.
- Publicação: `/mnt/datasul/ERP/sursum/sursum-api/programs/EmpresasCrud.{p,r}` e `EmpresasCrudService.{p,r}`.
- Catálogo mesclado: `/mnt/datasul/ERP/sursum/conf-web-handler/program-routes.json`. Rotas anteriores preservadas; backup e SHA-256 conferidos.
- PASOE: instância `sursum-api`, contexto `med`, banco lógico `espec`.
- Transporte desta instalação: túnel SSH com portas de loopback `127.0.0.1:19910 -> 127.0.0.1:9910`. O conector é da mesma instância. HTTPS 9911 não foi validado: certificado de teste sem identidade válida do host e timeout no acesso direto. Não se desativou a validação TLS.
- Autenticação entre PHP e API: cabeçalho `X-Empresas-Token`, gerado aleatoriamente; somente hash SHA-256 no arquivo `sursum-conf/empresas-api.json`. O segredo fica na configuração privada do backend e no arquivo local ignorado `empresas-connection.json`. Não fica no JSON da tela ou no corpo auditado pelo roteador.

Para reconectar o túnel, executar `tools/construtor-local/tunnel.ps1` e informar a credencial SSH na entrada protegida. Manter o terminal aberto. Não há senha SSH nos scripts.

## Schema confirmado

`PUB.empresas`: `empresa_id` INTEGER; `nome` CHARACTER, formato x(50); `cod_emp_ems2` e `cod_emp_ems5` INTEGER. Campos opcionais; padrão vazio para nome e zero para inteiros. Índice primário único `ind_empresa(empresa_id)`. Não há triggers de tabela/campo ou expressões de validação nesses campos. Dependências por `empresa_id`: `despesas_impostos`, `empresas_despesa`, `procs_compra`.

O ID é gerado pelo serviço e fica somente para leitura no formulário. O serviço verifica os vínculos antes de excluir, rejeita nomes maiores que 50 caracteres e valores fora de INTEGER, e usa transação com lock exclusivo sem espera. Não houve alteração de schema Progress.

## Evidências

- Compilação do serviço, wrapper e teste com `COMPILER:ERROR=no` no 12.2.
- 33 verificações CRUD em temp-table isolada: geração de ID, Unicode, campos opcionais, limites de texto/inteiro, ID imutável, campo/operação desconhecidos, registro ausente, alteração e exclusão.
- PHPUnit: 23 testes relacionados, 100 assertions aprovadas, incluindo contrato opt-in de erros Sursum, HTTP real de fixture, preservação das fontes genéricas e serialização pública do builder.
- Backend real aceitou o JSON e publicou a tela pelo fluxo de solicitação, liberação, locks, testes e aprovação.
- Consulta real pelo PHP e formulários de visualização/inclusão no Edge (sem salvar): duas empresas; quatro campos corretos; filtro e total corretos; ID somente leitura; HTTP 200; nenhum erro JavaScript. Capturas locais privadas: `empresas-consulta.png`, `empresas-formulario.png`, `empresas-inclusao.png`.
- Monitor após atualização oficial da entidade: 999 registros verificados, zero violações.
- Revisão de código apontou credencial no corpo auditado e falta de `success:false` nas recusas; correções recompiladas e republicadas com credencial rotacionada. Teste remoto posterior comprovou cabeçalho correto aceito, credencial ausente/incorreta recusada e `success:false`. PHP traduziu erro de registro ausente de HTTP 200 do Progress para HTTP 404. Segredo ausente da definição pública. Ledger registra os hashes, backup e evidências.

## Correções necessárias na instalação nova

O seed assinava associações de campos vazias em memória; o EntityManager agora é limpo após flush antes da assinatura. O JSON público do builder carregava `_module` como objeto ORM; a referência interna agora é removida junto com `_entity`, estabilizando a assinatura após recarregar o banco. A aplicação de configuração da entidade verifica o histórico antes de qualquer gravação ou sincronização física. O arquivamento de snapshots também verifica a assinatura anterior e assina o novo status. Os dois registros afetados desta integração foram reparados com o comando oficial de manutenção, motivo registrado, após diagnóstico da causa.

## Validação operacional autorizada — 15/10/2026

O usuário autorizou explicitamente criar, alterar e excluir registros novos identificados como teste no banco operacional `espec`, com remoção ao terminar. A revisão automática permitiu a execução após essa autorização.

- `verify-empresas.cjs`: inclusão pelo PHP com ID gerado, consulta/detalhe, filtro, alteração de nome com Unicode e códigos inteiros, rejeição de nome com 51 caracteres e inteiro fracionário (HTTP 422), registro ausente (HTTP 404), preservação da alteração anterior após falha e exclusão confirmada por consulta posterior HTTP 404.
- `verify-empresas-concurrency.cjs`: quatro requisições simultâneas diretamente ao PASOE, cada uma incluindo um registro novo marcado; quatro IDs distintos, sem conflito observado nesta execução. Todos foram removidos, com consulta posterior sem resíduo da marca de teste.
- Comparação dos quatro campos de todas as empresas preexistentes: preservados. Nenhuma empresa preexistente foi alterada ou excluída.
- Evidências locais privadas: `empresas-http-evidence.json` e `empresas-concurrency-evidence.json`, em `.runtime/construtor-pg`.

A validação não provocou deliberadamente contenção por lock em outra sessão; quatro inclusões simultâneas não constituem teste de carga. O transporte continua sendo o túnel SSH documentado acima.
## Exibição de inteiros — 15/10/2026

Corrigido o editor numérico comum em `src/crud-engine/CrudKendoFormRenderer.js`: campos `integer` usam formato `n0` junto com `decimals:0`; campos decimais mantêm `n2`, e moeda mantém `c2`. O JSON de empresas já declarava os três campos como inteiros; não foi necessário alterar seus tipos ou publicar nova API.

Teste real no Edge reproduziu a falha antes da correção e passou depois: códigos EMS2/EMS5 exibem `17` e `500`, enquanto campo decimal exibe `12,50`. Grid, filtro, visualização e abertura de inclusão continuaram funcionando, sem erros JavaScript. Nenhum registro foi salvo durante a verificação. A consulta tinha três empresas, incluindo um registro criado pelo usuário, que foi preservado.

## Usuário, agente e instância — 15/10/2026

Corrigida a propagação da identidade autenticada do construtor por headers do PHP e a captura da identidade real do runtime PASOE. Novas execuções registram usuário, agente por ASID e instância por CATALINA_BASE. Campos também publicados na consulta/detalhes do monitor. Exemplo validado: admin,agent-3,sursum-api,PID2118550. Nenhum registro antigo foi alterado. Ver `identidade-construtor-pasoe.md` para publicação e testes.
