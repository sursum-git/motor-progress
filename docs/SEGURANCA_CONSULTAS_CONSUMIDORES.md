# Segurança das consultas por consumidor

Política ativada em 27/10/2026 **somente no PASOE sursum-api, contexto MED, HTTPS 9911**. O contexto IMA, a instância de teste e os demais PASOEs mantêm a política anterior. As rotas independentes `SursumPrograms` e `CiwAuthentication` preservam seus handlers e sua autenticação própria.

## Consumir a consulta

**Acesso externo disponível:** `POST https://iol.imatextil.com.br/query-progress/api/query.php`, com o mesmo cabeçalho de consumidor e JSON abaixo, sem sessão LDAP. Ver [exemplo completo de consumo externo](CONSUMO_EXTERNO_CONSULTAS.md). Essa rota tem destino fixo sursum-api/MED/9911 e não expõe administração nem utiliza o token administrativo do proxy.

Endpoint: `POST https://192.168.0.111:9911/med/web/SursumDynamicQuery/query`.

Enviar `Content-Type: application/json` e `X-Sursum-Query-Token: <token>`. Este é o cabeçalho validado no adaptador PASOE instalado; o adaptador não encaminhou o cabeçalho Authorization nos testes reais. Nunca enviar o token na URL ou no JSON.

```json
{
  "code": "saldo-estoque-por-referencia",
  "parameters": {
    "querystring": {
      "estabelecimento": "502",
      "deposito": "ARM",
      "item": "130062",
      "referencia": "004"
    }
  }
}
```

Os quatro filtros são opcionais; referência corresponde a `saldo.cod-refer`. O consumidor `estoque-integracao` foi provisionado com validade de 90 dias e permissão exclusivamente para `saldo-estoque-por-referencia`. Seu token está no servidor PASOE em `/dados/pasoe/sursum-api/conf/consumer-secrets/estoque-integracao.token`, acessível somente ao administrador. Transferir a credencial ao consumidor por canal privado e armazená-la em cofre; não incorporá-la ao frontend.

A interface continua em [Query Progress](http://iol.imatextil.com.br/query-progress/), com login obrigatório. O proxy usa uma credencial administrativa do serviço guardada fora da raiz pública, sem enviá-la ao navegador. Esse perfil conserva os recursos administrativos da ferramenta interna para seus operadores autenticados; a permissão por consulta descrita aqui rege os consumidores de integração.

## Regras aplicadas

| Situação | Resposta |
| --- | --- |
| Token ausente, incorreto, expirado ou revogado | HTTP 401 |
| Consumidor solicita outro código, consulta livre ou endpoint administrativo | HTTP 403 |
| Consumidor tenta sobrescrever a definição salva com propriedades extras | HTTP 400 |
| Configuração ausente ou inválida | HTTP 503, sem acesso anônimo |
| OPTIONS | HTTP 204, sem executar consulta |

Consumidores executam somente consultas salvas pelo código exato autorizado, com parâmetros declarados na configuração da consulta. Cadastro de consultas, metadados, configuração, jobs, execução de programas e auditoria do handler dinâmico exigem perfil `admin`. Esse perfil é privilegiado e não deve ser fornecido a integrações comuns. A identidade de auditoria é derivada do token (`consumer:<id>`), sem confiar em `X-Sursum-User` enviado pelo consumidor.

## Administrar credenciais

**Autenticação automática:** novos consumidores usam `client_id`/`client_secret` para obter tokens de15minutos em `api/token.php`. A página gerencia criação, migração explícita de legados, rotação do segredo e revogação. Permissões e autorização vigente são conferidas em cada uso; a emissão não estende a autorização. Ver [contrato, exemplos e cliente com renovação automática](AUTENTICACAO_AUTOMATICA_CONSUMIDORES.md). As instruções de token manual/CLI abaixo continuam disponíveis para consumidores legados.

A administração web está em [Consumidores e tokens](https://iol.imatextil.com.br/query-progress/query-consumers.html), também no menu **Configuração**. Entrar pelo LDAP com `tadeu.parreiras`; outros usuários autenticados recebem acesso negado. A página exige HTTPS e opera somente em sursum-api/MED/9911, sem seletor de outro PASOE.

Use **Novo consumidor** para escolher identificador, consultas e validade da autorização de 1 a 365 dias. A criação exibe `client_id` e `client_secret` uma única vez, com botões para copiar o segredo e o exemplo. Selecione uma integração para **Editar permissões**, **Rotacionar segredo** ou **Revogar acesso**. Consumidores manuais existentes mostram **Rotacionar token** e **Ativar renovação automática**; a migração é explícita. Fechar limpa os campos sensíveis. Edição preserva a credencial e o estado de revogação; rotação invalida a credencial anterior e reativa o consumidor, preservando suas consultas. A credencial de serviço e todos os perfis admin são protegidos contra alterações na tela. A interface cria apenas consumidores de integração.

As operações administrativas verificam a sessão LDAP no servidor e usam proteção CSRF. Não passam pelo registrador genérico de requisições: os logs administrativos registram usuário, ação e identificador, sem token. A listagem omite também os hashes. Atualizações concorrentes são rejeitadas para que o operador atualize a lista antes de tentar novamente; o mesmo bloqueio é compartilhado com a CLI.

Na emissão e rotação, **Copiar curl** fornece o comando Bash para a URL externa, usando exclusivamente o novo token do consumidor e os filtros estabelecimento, depósito, item e referência (cod-refer) de `saldo-estoque-por-referencia`. Os valores apresentados são exemplos editáveis no comando copiado. O exemplo não concede permissões e contém a mesma credencial sensível do campo de token; ambos são limpos ao fechar, pressionar Escape ou sair da página, sem armazenamento no navegador.

A configuração operacional fica em `/mnt/datasul/ERP/sursum/sursum-conf/query-consumers.json` (share `\\192.168.0.137\erp\sursum\sursum-conf\query-consumers.json`). Contém somente SHA-256 dos tokens, identificadores, perfil, ativação, validade UTC e códigos permitidos. O exemplo versionado não contém consumidores reais.

Usar Node.js atual e `scripts/query-consumers.cjs` em estação administrativa confiável com acesso de escrita ao arquivo. Exemplo PowerShell, a partir da raiz de `v2`:

```powershell
$policyFile = '\\192.168.0.137\erp\sursum\sursum-conf\query-consumers.json'
node scripts/query-consumers.cjs $policyFile list
node scripts/query-consumers.cjs $policyFile create --id parceiro-estoque --queries saldo-estoque-por-referencia --days 90
node scripts/query-consumers.cjs $policyFile rotate --id parceiro-estoque --days 90
node scripts/query-consumers.cjs $policyFile revoke --id parceiro-estoque
```

Criação e rotação mostram o token uma única vez: executar sem gravação de terminal ou logs compartilhados. Rotação invalida imediatamente o token anterior; revogação também é imediata, sem reiniciar o PASOE. A CLI usa bloqueio exclusivo e substituição atômica. Preservar as permissões privadas do arquivo operacional. Não substituir a configuração real pelo exemplo vazio.

O serviço web usa `/var/www/clients/client1/web7/private/sursum-query-progress/pasoe.token` e `pasoe.pubkey-pin` no servidor 192.168.0.39. A pasta fica fora de DocumentRoot e dentro do open_basedir permitido pelo PHP. Diretório 0750 e arquivos 0640, root:www-data, com ACL nomeada permitindo ao usuário da aplicação `web7` somente travessia/leitura, sem escrita ou acesso para outros. Os arquivos foram relocados de `/etc/sursum-query-progress`, preservando o token e o pin; as cópias antigas desses dois arquivos foram removidas. Ao rotacionar `web-query-admin` por administração confiável, instalar o novo token no arquivo privado atual. Os overrides `SURSUM_QUERY_PROXY_TOKEN_FILE` e `SURSUM_QUERY_PROXY_PIN_FILE` continuam disponíveis. O proxy restringe a credencial ao host 192.168.0.111, porta 9911 e caminho `/med/web/SursumDynamicQuery`. Outros destinos conservam seu fluxo anterior.

O certificado atual do PASOE é autoassinado e não contém SAN. O proxy confia exclusivamente no pin SHA-256 da chave pública obtida por SSH autenticado; um pin divergente bloqueia a conexão antes de qualquer resposta HTTP. Uma troca de chave do certificado exige atualização administrativa desse pin. Integrações devem configurar sua confiança TLS; não desativar a validação genericamente.

## Implantação e evidências

Compilação oficial no OpenEdge 12.2 do servidor 192.168.0.42; publicação por hashes e backup no share operacional. O handler seguro foi registrado somente em MED da instância sursum-api, com recarga das sessões MED ociosas, sem reinício geral. Os arquivos ABL compartilhados incluem hooks de auditoria no handler base; a política só é aplicada quando o wrapper seguro está registrado.

Foram exercitados 52 checks ABL em cada combinação UTF-8/ISO8859-1 e AMERICAN/EUROPEAN, incluindo expiração UTC, cabeçalhos, configuração inválida e autorizações. A CLI tem cinco testes de subprocesso e o proxy tem 16 verificações, incluindo isolamento dos outros PASOEs. Os recibos privados ficam em `temp/query-consumers-20261027/`: `publication.json`, `pasoe-verification.json`, `web-verification.json` e logs da compilação. Não contêm tokens em texto aberto.

### Administração web — validação complementar de 27/10/2026

Compilador oficial 12.2.12, seis entradas sem erro e **34 checks de administração mais 52 de autorização em cada uma das quatro combinações** de encoding/formato numérico. Passaram 18 verificações administrativas no PASOE real e 20 no navegador com login LDAP verdadeiro de tadeu.parreiras: seleção de consulta no diálogo, emissão e uso do token, edição, rotação invalidando o anterior, revogação, proteção de admin, CSRF, negação pelo proxy genérico, limpeza do token e abertura pelo menu. O proxy normal também foi exercitado no navegador com a credencial privada.

No servidor publicado passaram 49 checks PHP de administração e 19 do helper de token/pin. Uma sessão técnica autenticada de outro usuário foi negada; nenhum usuário LDAP foi impersonado. Os consumidores de teste foram revogados/removidos e os bytes da configuração operacional foram restaurados. Oito artefatos ABL e oito arquivos web foram conferidos por hash. Registros do handler e configurações das demais instâncias permaneceram inalterados; somente sessões MED ociosas foram recarregadas.

Recibos privados em `temp/query-consumers-ui-20261027/`: `final-verification.json`, `publication.json`, `pasoe-verification.json`, `web-verification.json`, `browser-verification.json`, `official-*.log` e capturas `ui-list.jpg`, `ui-menu.jpg`, `ui-revoked.jpg`. A compilação local 12.8 foi apenas diagnóstico. A resolução do catálogo conserva compatibilidade com os separadores literais usados pelo handler legado, sem mudar seu PROPATH.
A entrega de webhooks bloqueia IPs privados por padrão. Exceção operacional aprovada: somente `iol.imatextil.com.br` pode resolver para `192.168.0.39`; a entrega continua restrita a HTTPS, sem redirecionamento, com HMAC obrigatório. Nenhum outro host ou IP privado é permitido.

