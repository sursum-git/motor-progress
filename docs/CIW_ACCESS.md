# Autorização CIW, fase1A

`POST /SursumPrograms/ciw-access` recebe apenas `operation=authorize`,
`resource=cadastros.coloracoes` e `action` (`read`, `get`, `create`, `update`,
`delete`, `export`, `print`). A operação verifica permissão e nunca executa a
ação de negócio. Permissão do construtor continua obrigatória nos endpoints
de negócio futuros.

`CiwAccessRead.p` obtém token e identidade de CGI e lê configuração privada
fixa `sursum-conf/ciw-access.json`. `CiwAccessBoundary.p` valida o contrato e
produz policy/identidade privadas; o mesmo código é exercitado nos testes.
`CiwAccessService.p` resolve identidade e grants usando três handles privados.
Nenhuma tabela, aplicação ou identidade é escolhida pelo JSON do cliente.

O transporte PHP deve usar `X-CiwAccess-Token` privado, e sobrescrever os
headers `X-Sursum-User`, `X-Session-Id`, `X-Sursum-Auth-Source` com valores da
sessão ativa. O token autentica esse transporte: headers enviados diretamente
por um browser não estabelecem uma sessão. Não compartilhar o token com clientes.

Configuração real contém somente `tokenSha256` e `allowedAuthProviders`.
Sem provedor confirmado, a lista é vazia e todos os usuários são negados.
Não autorizar `local` ou `admin` para fabricar um teste positivo. Credencial
privada local fica em `.runtime/ciw-access-20261016/connection.json`.

Aplicações e flags, erros e DTO estão em `contract.json`. Login é comparado
sem distinção de caixa, com tamanho exato; mais de uma correspondência nega.
Aplicação, ação, provedor e flags usam comparação exata. Apenas `ativo=TRUE`
e flag `Y` autorizam. Concessões de cada flag são unidas entre grupos do usuário;
acesso e flag específica precisam estar concedidos. `priv_admin` não tem bypass.
Valores desconhecidos de atributos opcionais retornam JSON null.

Cada chamada relê permissões `NO-LOCK`, sem cache, gravação ou sequência.
Uma decisão não serializa revogações concorrentes; writers futuros devem
revalidar na própria entrada. ID IMA retornado é legado, sem inferência de ID PG.

Compilação/testes exigem OpenEdge12.2 no `.42`. Publicação em sursum-api/med
inclui seis `.p/.r`, configuração privada e uma rota mesclada, ativada por último.
Não publicar testes. Caso positivo real depende de sessão do provedor IMA
confirmado; casos negativos e TT não substituem essa prova.

O roteador existente retorna HTTP200 quando executa um programa e serializa
seu envelope, inclusive recusas `success=false`. Os códigos401/403/400/500
do domínio ficam em `error.status`; erros do próprio roteador, como array
no corpo, usam o status HTTP correspondente. Consumidores devem conferir
o envelope, conforme contrato `sursum-programs` existente.
