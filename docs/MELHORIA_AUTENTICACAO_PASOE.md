# Proposta de melhoria: autenticação e controle de acesso às APIs PASOE

**Data:** 28/09/2026  
**Status:** proposta para implementação futura  
**Projeto:** motor-progress — checkout `v2`  
**Ambiente padrão:** `sursum-api`, contexto `med`, servidor `192.168.0.111`, HTTPS `9911`

## 1. Objetivo e resultado esperado

Impedir a execução anônima das APIs e limitar o acesso aos usuários e sistemas autorizados, preservando o funcionamento das integrações existentes.

O acesso atualmente restrito à rede interna, conforme informado pelo responsável, reduz a exposição. A melhoria acrescenta identificação do consumidor, autorização por operação e rastreabilidade. Pertencer à rede interna deixará de ser suficiente para executar uma API.

Esta proposta recomenda aproveitar o login PHP existente e configurar autenticação HTTP Basic sobre HTTPS entre os servidores consumidores e o PASOE. OAuth2/JWT fica como evolução posterior, caso seja necessário reconhecer usuários individualmente no PASOE ou integrar mais sistemas.

Este documento não aplica configurações nem publica programas. Antes da execução futura, confirmar versões, consumidores, caminhos e configurações efetivas. A instância `sursum-api-teste` somente será utilizada mediante solicitação explícita do usuário.

## 2. Situação conhecida e limites do levantamento

| Componente | Evidência e implicação |
|---|---|
| Login PHP | `web/auth.php` mantém a sessão e disponibiliza `requireSursumAuth()`. Pode ser reutilizado. |
| Proxies PHP | `web/pasoe-proxy.php` e `web/metadata-pasoe.php` já chamam `requireSursumAuth()` e suportam envio de `Authorization` quando `auth_mode=header`. Isso não comprova autorização por operação nem cobertura de todos os endpoints PHP. |
| Credenciais de integração | O proxy consulta `auth_mode` e `authorization` no cadastro de ambientes. Revisar armazenamento, permissões de leitura, exportações e respostas da interface antes de reutilizar esses campos para segredos. |
| TLS do proxy | Existem opções de verificação de certificado e hostname. Confirmar seus valores efetivos no ambiente; a presença no código não significa que estejam habilitadas. |
| Roteador JSON | `JsonProgramWebHandler` e `JsonProgramRouter` executam programas cadastrados em `conf-web-handler/program-routes.json`. O catálogo relaciona método, rota e programa; não é um cadastro de usuários ou permissões. |
| Consulta de pedidos | Rota criada: `POST /med/web/SursumPrograms/consulta-pedidos-venda`. A validação de 25/09/2026 ocorreu na porta 9911. |
| Segurança e rede em produção | A configuração efetiva completa não foi auditada para esta proposta. O inventário de consumidores, regras de firewall, autenticação e certificados é uma etapa obrigatória da implementação. |

Referências internas: [roteador JSON](JSON_PROGRAM_ROUTER.md), [consulta de pedidos](CONSULTA_PEDIDOS_JSON.md), [contexto PASOE](../context/OPENEDGE_PASOE_CONTEXT.md).

## 3. Arquitetura proposta

```text
Usuário no navegador
    │ HTTPS + sessão autenticada
    ▼
PHP: valida sessão e permissão da operação
    │ HTTPS + credencial de serviço, mantida no servidor
    ▼
PASOE: autentica o consumidor e autoriza rota/método
    ▼
Handler → programa ABL → resposta JSON

Integração autorizada
    │ HTTPS + credencial própria + origem de rede permitida
    └──────────────────────────────► PASOE
```

O firewall restringirá os servidores de origem. A autenticação do PASOE identificará cada consumidor. O PHP verificará as permissões do usuário final antes de encaminhar a chamada.

Uma conta técnica compartilhada pelo PHP identifica a aplicação, não cada pessoa. A trilha por usuário será mantida no PHP e correlacionada com o PASOE. Se for necessário que o próprio PASOE autorize cada pessoa, adotar um modelo de identidade delegada, como OAuth2/JWT, em etapa específica.

A segurança deve ser aplicada antes da execução dos programas ABL. Não acrescentar login em cada `.p`. CORS, URLs pouco conhecidas, validação de campos JSON e restrição por IP não substituem autenticação.

## 4. Decisões e pré-requisitos

Preencher esta tabela antes da implantação:

| Decisão | Informação necessária | Responsável sugerido |
|---|---|---|
| Consumidores | Sistemas, rotas, métodos, contexto/empresa e responsáveis | Aplicação/integrações |
| Origens permitidas | IP efetivamente visto pelo PASOE, considerando NAT, proxies e servidores de contingência | Infraestrutura |
| Identidades técnicas | Uma conta por integração; separar consulta e alteração quando necessário | Aplicação/segurança |
| Provedor de contas | Contas gerenciadas localmente pelo mecanismo suportado no PASOE ou integração com diretório corporativo | Administração PASOE |
| Permissões | Operações permitidas por usuário, grupo e consumidor | Responsável de negócio |
| HTTPS | Nome DNS, certificado, cadeia emissora e renovação | Infraestrutura |
| Segredos | Local protegido, acesso mínimo, rotação e revogação | Infraestrutura/aplicação |
| Implantação | Janela, responsáveis, consumidores de verificação e critérios de reversão | Operação |
| Auditoria | Destino, retenção e acesso aos registros | Operação/segurança |

Não reutilizar contas administrativas, SSH ou contas pessoais como identidade técnica da API. Os nomes usados abaixo são propostas; não representam contas já criadas.

## 5. Configurações e alterações necessárias

### 5.1 PASOE: autenticação e autorização

Ponto inicial de inspeção:

```text
/dados/pasoe/sursum-api/webapps/med/WEB-INF/oeablSecurity.properties
```

Revisar também as configurações herdadas da aplicação ABL e da instância. O PASOE 12.2 permite configurar autenticação por aplicação web e suporta HTTP Basic e diferentes fontes de contas. Os valores e nomes de propriedades devem ser conferidos no README e nos arquivos da instalação 12.2.17 antes da edição. [Progress: habilitar autenticação ABL](https://docs.progress.com/bundle/pas-for-openedge-management-122/page/Enable-ABL-application-authentication.html).

Atividades:

1. Registrar o modelo de login, provedor de contas, regras de URL, papéis e configuração de identidade OpenEdge efetivamente usados.
2. Selecionar o provedor de contas e criar as identidades técnicas com permissões mínimas. Se adotado armazenamento local, escolher o mecanismo de proteção de senhas suportado pela instalação, evitando senhas em texto aberto.
3. Configurar HTTP Basic e HTTPS obrigatório. Basic codifica a credencial; a confidencialidade depende de TLS corretamente validado.
4. Exigir autenticação no prefixo de programas e definir autorização por rota e método. Confirmar se o mecanismo usado interpreta a URL completa ou o caminho relativo ao contexto; testar com `/med/web/SursumPrograms/consulta-pedidos-venda`.
5. Negar operações não concedidas explicitamente. Novas rotas devem exigir revisão de permissões antes de sua liberação.
6. Conferir a integração de identidade/domínio OpenEdge exigida pelo provedor escolhido e preservar a configuração funcional existente.
7. Verificar efeitos sobre as demais rotas de `med`. O modelo de login tem alcance de aplicação web; não presumir que uma alteração proteja exclusivamente uma rota.

O controle por papéis pode utilizar o Spring Security já integrado ao PASOE. A sintaxe final das regras depende da configuração encontrada; este documento não fornece um bloco de configuração para colar sem inspeção. [Progress: Spring Security](https://docs.progress.com/bundle/pas-for-openedge-management-122/page/Configure-Spring-Security.html).

Matriz inicial a aprovar:

| Identidade/papel proposto | Operação | Regra proposta |
|---|---|---|
| `svc_motor_consulta` / consulta | POST da consulta de pedidos | Permitido |
| `svc_motor_consulta` / consulta | Operações de alteração ou transferência | Negado |
| Conta específica de integração | Rotas e métodos do seu contrato | Permitidos explicitamente |
| Usuário PHP sem permissão | Consulta ou alteração protegida | Negado no PHP antes de chamar o PASOE |
| Anônimo | Rotas protegidas | Negado no PASOE |

Inventariar acessos alternativos, especialmente `/SursumDynamicQuery/program/execute`, consultas salvas e outros transports/endpoints capazes de executar a mesma operação. A proteção da rota nova não pode deixar um caminho anônimo equivalente ativo. Eventuais exceções devem ser documentadas, ter responsável e prazo de retirada.

Não armazenar credenciais em `program-routes.json`. Sua função continua sendo o mapeamento de execução.

### 5.2 PHP: sessão, permissões e credencial técnica

Reutilizar os mecanismos existentes, acrescentando os controles que faltarem:

- Confirmar que todos os endpoints PHP envolvidos exigem sessão válida, inclusive novos proxies para `/SursumPrograms/**`.
- Conferir permissão do usuário para operação e contexto/empresa antes de enviar a requisição. A conta técnica não concede automaticamente essas permissões à pessoa.
- Resolver a credencial de serviço apenas no servidor, usando secret store, variável protegida do serviço ou arquivo externo ao diretório público com ACL restrita.
- Revisar o campo atual `authorization`: nenhum segredo pode ser devolvido a telas, endpoints de configuração, exports ou logs. Se necessário, substituir o valor por uma referência ao segredo.
- Não aceitar do navegador credencial técnica, host ou URL de destino arbitrários. Destinos e operações encaminhados precisam estar em uma lista controlada.
- Não encaminhar automaticamente o `Authorization` fornecido pelo navegador. O proxy deve construir sua própria autenticação a partir do segredo autorizado.
- Habilitar verificação de cadeia e hostname TLS; instalar a CA interna quando necessário. Não utilizar desativação de TLS como solução de produção.
- Usar HTTPS também entre navegador e PHP. Revisar cookies de sessão e proteção CSRF nas operações com efeitos de negócio.
- Diferenciar falha da sessão do usuário de falha da conta técnica. Uma recusa do PASOE por credencial técnica deve gerar registro operacional, sem expor o segredo nem simular resultado vazio de consulta.

HTTP Basic deve ser enviado no cabeçalho; não usar senha em URL, query string, corpo de negócio ou JavaScript.

### 5.3 Rede e HTTPS

| Acesso | Tratamento proposto |
|---|---|
| PHP e integrações aprovadas → `192.168.0.111:9911` | Permitir somente origens cadastradas; autenticação continua obrigatória |
| Estações e demais origens → `9911` | Bloquear |
| Clientes de negócio → HTTP `9910` | Bloquear ou desabilitar após inventário e migração |
| Portas administrativas e outros conectores | Inventariar e preservar acesso administrativo controlado; verificar caminhos alternativos |

Preferir DNS interno cujo nome esteja coberto pelo certificado. Se o cliente usar endereço IP, o certificado deve conter esse IP no SAN. Garantir confiança na cadeia emissora no servidor PHP e nos consumidores autorizados.

A porta 9911 atende a instância, não somente o contexto `med`. Antes de restringi-la, inventariar também os consumidores de `ima` e de outros contextos. Validar persistência das regras após reinício e manter acesso administrativo para reversão.

### 5.4 Auditoria e operação

Registrar identificador da requisição, data/hora, usuário autenticado no PHP, identidade técnica no PASOE, contexto, rota, método, status e duração. Usar horários sincronizados e correlação entre as duas camadas.

O identificador do usuário deve vir da sessão no servidor. Um campo ou cabeçalho livre recebido do cliente não deve ser usado como identidade confiável para autorização. Caso encaminhado ao PASOE para auditoria, o PHP deve sobrescrevê-lo e o PASOE tratá-lo dentro do contrato do consumidor autenticado.

Não registrar `Authorization`, cookies de sessão, senhas ou o corpo completo das consultas por padrão. Definir retenção, acesso aos registros, alertas de falhas repetidas e procedimento para revogar uma conta comprometida.

Documentar rotação: criar/substituir segredo conforme o provedor, atualizar consumidores, validar, revogar a credencial antiga e confirmar que ela não funciona mais.

## 6. Sequência de implantação futura

| Etapa | Execução | Evidência de saída |
|---|---|---|
| 1. Inventário | Levantar consumidores, caminhos alternativos, configurações efetivas e permissões | Lista aprovada e matriz preenchida |
| 2. Preparação | Reservar janela, manter acesso administrativo, guardar backups restritos e preparar reversão | Backup identificável e procedimento revisado |
| 3. HTTPS e identidade | Preparar certificado/CA, contas e armazenamento protegido | TLS validado e contas disponíveis |
| 4. Consumidores | Ajustar PHP e integrações para autenticação, autorização e logs | Clientes preparados antes de fechar acesso |
| 5. PASOE | Aplicar regras no contexto planejado e recarregar conforme exigido pela instalação | Chamadas autorizadas funcionam e anônimas são recusadas |
| 6. Rede | Aplicar lista de origens permitidas e bloquear acesso HTTP alternativo | Testes de rede por origem aprovados |
| 7. Aceite | Executar a matriz abaixo e verificar logs e regressões | Evidências registradas e aceite do responsável |
| 8. Operação | Registrar configurações finais, responsáveis, rotação e monitoramento | Documentação operacional atualizada |

A execução ocorrerá na `sursum-api`, salvo determinação explícita diferente. Se houver necessidade de reinício, comunicar o impacto também sobre `ima`, pois pertence à mesma instância. Não mudar autenticação global ou outros contextos indiscriminadamente.

Durante a futura implementação, mudanças em fontes ABL exigirão compilação no OpenEdge 12.2 do `192.168.0.42`, publicação e validação pelo PASOE, conforme [skill do projeto](../skills/motor-progress-publicar-pasoe/SKILL.md). Mudanças apenas de configuração não geram novo `.r`, mas também exigem validação real após aplicação.

## 7. Testes e critérios de aceite

Executar a partir das origens indicadas; bloqueios de firewall não produzem necessariamente resposta HTTP.

| Caso | Resultado esperado |
|---|---|
| Origem permitida, sem autenticação | HTTP 401, sem execução ABL |
| Origem permitida, senha incorreta ou credencial revogada | HTTP 401, sem execução ABL |
| Identidade válida sem permissão para rota/método | HTTP 403 nas operações protegidas aplicáveis |
| Identidade válida com permissão | Retorno funcional esperado, preservando contrato JSON |
| Sessão PHP ausente ou expirada | Recusa no PHP, sem chamada ao PASOE |
| Usuário PHP autenticado sem permissão/contexto | Recusa no PHP, sem chamada ao PASOE |
| Chamada direta de estação não permitida | Conexão bloqueada, mesmo com credencial válida |
| Chamada pela porta 9910 | Acesso de negócio indisponível; nenhum bypass HTTP |
| Certificado inválido ou hostname divergente | Cliente recusa conexão |
| Tentativa por endpoint alternativo | Mesma operação não pode contornar os controles |
| Rotas legítimas existentes, inclusive outros contextos afetados pela rede | Funcionamento preservado para consumidores autorizados |
| Inspeção de navegador, endpoints de configuração e logs | Nenhuma exposição da credencial técnica |
| Correlação de auditoria | Chamada rastreável entre usuário PHP, conta técnica e operação |
| Rotação de credencial | Credencial nova funciona; antiga é recusada |

Usar preferencialmente a consulta de pedidos como teste funcional sem alteração de dados, com período e pedido delimitados. A contagem histórica de 10.660 registros não é critério fixo, pois os dados podem mudar. Não executar transferências reais apenas para testar permissões; usar recusa antes da execução ou um cenário expressamente autorizado.

A melhoria será considerada concluída quando os testes passarem, nenhum consumidor legítimo inventariado tiver sido interrompido e as configurações finais e a reversão estiverem documentadas.

## 8. Reversão

Disparadores: indisponibilidade de consumidores previstos, falha persistente de autenticação legítima, impacto inesperado em outro contexto ou evidência de autorização incorreta.

1. Identificar a camada responsável usando logs e o identificador da chamada.
2. Manter ou restringir a lista de origens conhecidas enquanto recupera o serviço.
3. Restaurar somente os arquivos e regras alterados nesta entrega, preservando alterações concorrentes.
4. Se necessário, restaurar a configuração anterior de segurança de `med` e recarregar apenas o componente/instância afetado conforme o procedimento operacional.
5. Validar os consumidores essenciais e registrar o período de reversão, a exposição remanescente e o ajuste pendente.

Não desabilitar o firewall inteiro, desligar a validação TLS ou liberar rotas globais como solução de contingência. Caso a restauração retorne temporariamente ao acesso anônimo anterior, manter restrição de rede e registrar essa condição explicitamente.

## 9. Evolução opcional: OAuth2/JWT

Avaliar em uma segunda etapa se houver necessidade de identidade individual no PASOE, mais consumidores ou centralização de permissões. A evolução exige provedor de identidade, registro de clientes, emissão de tokens compatíveis, validação de assinatura e expiração, claims exigidas, escopos e rotação de chaves.

O PASOE 12.2 suporta tokens JWT no modelo OAuth2, com requisitos próprios de integração. Não presumir compatibilidade automática com qualquer emissor; validar os tokens reais e sua representação em CLIENT-PRINCIPAL antes de migrar. [Progress: OAuth2 e JWT no PASOE 12.2](https://docs.progress.com/bundle/pas-for-openedge-management-122/page/Support-for-OAuth2-and-JWT-in-PAS-for-OpenEdge.html).

## 10. Checklist para retomar a melhoria

- [ ] Revalidar o ambiente e a versão instalada.
- [ ] Preencher consumidores, IPs de saída e responsáveis.
- [ ] Aprovar matriz de permissões e identificar endpoints alternativos.
- [ ] Escolher provedor de contas e mecanismo de segredos.
- [ ] Definir DNS, certificado e cadeia de confiança.
- [ ] Revisar o tratamento atual de `authorization` no cadastro e nas telas.
- [ ] Preparar janela, backups, scripts/configurações revisados e reversão.
- [ ] Implementar e validar autenticação, autorização e regras de rede.
- [ ] Executar os testes e anexar as evidências.
- [ ] Registrar responsáveis por contas, certificados, logs e rotação.
