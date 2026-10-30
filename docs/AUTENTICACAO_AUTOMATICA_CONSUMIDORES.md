# Tokens automáticos de consumidores — sursum/MED

Fluxo `client_credentials` exclusivo do PASOE **sursum-api/MED/HTTPS9911**, exposto pelo domínio HTTPS do site. Cada integração mantém seu `client_id` e `client_secret` no cofre do seu servidor e obtém tokens opacos de **900 segundos (15 minutos)**. Não há refresh token nem acesso administrativo por essa credencial.

## Provisionamento e gestão

Abrir [Consumidores e tokens](https://iol.imatextil.com.br/query-progress/index.html?page=query-consumers.html), autenticando no LDAP como `tadeu.parreiras`.

- **Novo consumidor:** informar identificador, validade da autorização em dias e consultas permitidas. Novos consumidores usam autenticação automática. Guardar o `client_secret`, exibido uma única vez. O `client_id` é o identificador escolhido.
- **Ativar renovação automática:** migra explicitamente um consumidor de token manual. Invalida o token manual imediatamente e preserva suas consultas. Nenhum consumidor operacional é migrado automaticamente na publicação.
- **Rotacionar segredo:** emite outro segredo e invalida imediatamente o segredo anterior e todos os tokens de acesso ligados a ele; preserva consultas e reativa a autorização pelo prazo escolhido. Coordenar a troca da credencial com a integração.
- **Editar permissões:** altera consultas/validade sem trocar o segredo. A lista atual é verificada em cada execução, inclusive de tokens emitidos anteriormente.
- **Revogar acesso:** impede emissão e uso dos tokens já emitidos. Não reativa por simples edição; uma rotação administrativa pode reativar.

Há duas validades: o token dura15minutos; a autorização do consumidor dura o número de dias definido pelo administrador. A integração renova tokens automaticamente enquanto a autorização estiver ativa e vigente. O vencimento/revogação dessa autorização exige revisão administrativa; obter tokens não prorroga o acesso concedido.

O diálogo apresenta **Copiar segredo** e **Copiar exemplo**, com Bash/curl/jq para obter token e executar a consulta de saldo com quatro filtros. Fechar, Escape ou sair da página limpa os campos e o exemplo. O segredo deve permanecer no backend/cofre da integração, sem frontend público, URL, logs ou histórico compartilhado de comandos.

## Obter um token

**POST https://iol.imatextil.com.br/query-progress/api/token.php**

Content-Type: `application/x-www-form-urlencoded`. Enviar exatamente `grant_type`, `client_id`, `client_secret` no corpo, sem parâmetros na URL. Neste gateway a autenticação de cliente é pelo corpo form; não enviar HTTP Basic nem JSON diretamente à rota pública.

Exemplo Bash (variáveis preenchidas pelo cofre):

```bash
TOKEN=$(curl --silent --show-error --fail \
  'https://iol.imatextil.com.br/query-progress/api/token.php' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=$SURSUM_CLIENT_ID" \
  --data-urlencode "client_secret=$SURSUM_CLIENT_SECRET" |
  jq -er '.access_token') || exit 1
```

Resposta de sucesso:

```json
{"access_token":"TOKEN_OPACO_DE_64_CARACTERES_HEXADECIMAIS","token_type":"Bearer","expires_in":900}
```

O valor é sensível e muda em cada emissão. O `client_secret` não serve para executar consultas. A emissão não aceita `scope`, consultas, SQL, destino, contexto ou campos adicionais; as permissões vêm do cadastro.

## Executar a consulta

```bash
curl --request POST --fail-with-body \
  'https://iol.imatextil.com.br/query-progress/api/query.php' \
  --header 'Content-Type: application/json' \
  --header "X-Sursum-Query-Token: $TOKEN" \
  --data '{"code":"saldo-estoque-por-referencia","parameters":{"querystring":{"estabelecimento":"502","deposito":"ARM","item":"130062","referencia":"004"}}}'
unset TOKEN
```

Referência corresponde a `cod-refer`. Manter os valores como texto para preservar zeros iniciais. O cabeçalho de consulta continua **X-Sursum-Query-Token**, pois é o transporte validado no adaptador PASOE instalado. `token_type=Bearer` expressa a natureza da credencial; não implica mudar para Authorization nesse adaptador.

## Renovação no sistema consumidor

O exemplo executável [consumer_client_credentials.py](../examples/consumer_client_credentials.py) usa somente a biblioteca padrão Python3.10+. Configure `SURSUM_CLIENT_ID` e `SURSUM_CLIENT_SECRET` pelo cofre e execute `python examples/consumer_client_credentials.py`. Para integrações contínuas, reutilize a mesma instância `ConsumerClient` e chame `query(code, filters)`.

O cliente mantém o token somente em memória, reutiliza até870segundos e solicita outro com30segundos de margem. Uma trava evita emissões simultâneas no mesmo processo. Se uma consulta receber401, descarta o token e tenta obter outro uma única vez.403 não provoca renovação nem repetição. Certificados HTTPS são validados e redirects recusados. Falhas persistentes, autorização expirada/revogada ou429 devem interromper a operação e ser tratadas pela integração, sem loops de autenticação.

Tokens ainda válidos coexistem; obter outro não invalida os anteriores. Existem limites de300tentativas/minuto no emissor,20tokens ativos por consumidor e8192tokens globais. Reutilize tokens; não solicite um a cada consulta.429 informa Retry-After60;409 indica emissão concorrente ocupada e permite uma nova tentativa com espera curta e limitada.

## Contratos e armazenamento

Emissão:200 com token;400 grant/campos inválidos;401 credencial inválida, inexistente, revogada ou autorização vencida;409 lock ocupado;429 limite;503 configuração/escrita indisponível. Gateway:404 sufixo de rota,405 método,413 corpo maior4096bytes,415 content-type,426 semHTTPS,502 erro de transporte. As respostas de emissão são JSON OAuth (`error` textual nas falhas), com no-store/no-cache.

Consulta mantém o JSON do motor e HTTP401 para token vencido/inválido/revogado,403 para consulta/endpoint não autorizado. Autorização de cliente exige perfilconsumer e hash de segredo; nunca pode criar um token administrativo. Administração LDAP/CSRF e credencial técnica do proxy continuam separadas.

Configuração estável: `/mnt/datasul/ERP/sursum/sursum-conf/query-consumers.json`, com `clientSecretSha256` opcional por consumidor. O campo existente `tokenSha256` é ignorado para autenticação legada quando há segredo de cliente. O campo raiz obrigatório `accessTokenStore` aponta para **`/dados/pasoe/sursum-api/conf/consumer-secrets/query-access-tokens.json`**, em disco local Linux: pasta0700root e arquivo0640root. Contém somente hashes de tokens/geração de credencial/identificador/expiração e contador de tentativas, sem segredos em texto aberto. Não guardar o store no compartilhamento CIFS, pois ele força permissões de leitura mais amplas. Emissão usa lock e substituição atômica no store privado, poda expirados e não muda a revisão administrativa. Store configurado ausente começa vazio; configuração de caminho ausente/inválida ou store corrompido bloqueia emissão/autorização, sem fallback para o compartilhamento.

Não publicar nem expor esses JSONs no site. Não editar store de tokens como forma de estender validade. CLI confiável existente continua administrando tokens manuais; `rotate` pela CLI migra explicitamente de volta para token manual e invalida a credencial automática. Para rotação do segredo automático, usar a página administrativa.

## Verificação da entrega — 27/10/2026

Compilação oficial OpenEdge12.2.12:8entradas e129checks (38emissão/credenciais,39registro administrativo,52política) em cada combinação UTF-8/ISO8859-1 × AMERICAN/EUROPEAN, sem bancos conectados. Incluem expiração na fronteira900s, ativação/validade/permissões, rotação, locks, limites, store corrompido e configuração obrigatória de caminho privado absoluto. PHP publicado:21checks do gateway de token,49do gateway de consulta e49da administração; lint aprovado. CLI6casos e clientePython3casos aprovados.

No PASOE real e domínio HTTPS: geração e nova obtenção de tokens, consulta com quatro filtros, coexistência e emissão concorrente, edição de permissões com efeito imediato em token emitido, revogação e rotação do segredo. Migração explícita pela tela de um consumidor manual preservou consultas e invalidou o token anterior.13negativas externas confirmaram filtros de método/corpo/campos/rota e HTTPS; administrativos continuam restritos a LDAP/CSRF. Hashes dos8artefatosABL/7web publicados e dos arquivos protegidos foram reconferidos, configurações dos outros contextos/instâncias preservadas. Recarga somenteMEDocioso, mesmoPID do agente; sem alterações de schema ou registros de negócio.

Teste de vencimento real concluído: após904segundos, o token antigo recebeu401 e o clientePython obteve automaticamente outro token e executou a consulta com200. Antes do vencimento, duas consultas compartilharam uma única emissão em memória; ao final houve exatamente duas emissões. Navegador com LDAPreal concluiu32checks, e a migração legada9checks. Recibos privados ignorados em `temp/client-credentials-20261027/`: expiry-verification.json, publication.json, official-*.log, browser-verification.json, legacy-verification.json, external-negatives.json e web-tests.json. Nenhum contém tokens ou segredos em texto aberto.

A conferência de permissões identificou que CIFS força0755 no sidecar inicial. O store foi transferido para o caminho local Linux acima e o emissor passou a exigir configuração explícita, sem fallback. O teste real de904s precede essa alteração física; após a mudança, a gestão e a renovação automática foram novamente exercitadas contra o store privado, mantendo a mesma regra de900s. Os recibos distinguem as duas etapas (`expiry-verification.json` e `private-storage-renewal-verification.json`).
