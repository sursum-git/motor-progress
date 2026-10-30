# Roteador independente de programas JSON

`JsonProgramWebHandler` recebe a requisição HTTP e usa `JsonProgramRouter` para localizar e executar o `.p` cadastrado em `conf-web-handler/program-routes.json`. Esse fluxo é independente do motor de consultas e do endpoint antigo `/SursumDynamicQuery/program/execute`.

## Cadastro de rotas

```json
{
  "routes": [
    {
      "route": "/SursumPrograms/pedidos",
      "method": "POST",
      "program": "sursum-api/programs/ConsultarPedidos.p"
    }
  ]
}
```

Cada registro relaciona **rota + método HTTP + programa**. Para aceitar outro método, adicione outro registro; ele pode apontar para o mesmo `.p` ou para outro. Os métodos aceitos são GET, POST, PUT, PATCH e DELETE.

A rota corresponde ao `PATH_INFO` do transporte WEB, sem host, aplicação ou prefixo `/web`. No exemplo, a URL é `https://servidor:porta/med/web/SursumPrograms/pedidos`. Rotas são literais, sensíveis a maiúsculas e minúsculas, sem placeholders ou barra final implícita.

O caminho do programa é relativo ao PROPATH e começa por `sursum-api/` ou `especificos/ems2/ima/http-api/`. Não aceita caminhos absolutos ou travessia `..`. O cadastro referencia `.p`; o roteador prefere o `.r` correspondente quando disponível, permitindo publicar apenas os compilados.

O catálogo é lido a cada requisição. Cadastro ausente, inválido ou com o mesmo par rota/método duplicado bloqueia a execução.

## Entrada e saída

Uma chamada POST, PUT, PATCH ou DELETE envia o objeto de negócio diretamente:

```http
POST /med/web/SursumPrograms/pedidos
Content-Type: application/json

{"pedido":123,"incluirItens":true}
```

O `.p` recebe exatamente esse objeto. Não há envelope obrigatório `program` ou `parameters` nem definição de campos de negócio no cadastro de rotas.

```abl
USING Progress.Json.ObjectModel.JsonObject.

DEFINE INPUT PARAMETER poRequest AS JsonObject NO-UNDO.
DEFINE OUTPUT PARAMETER poResponse AS JsonObject NO-UNDO.

/* A validacao e o processamento dos dados pertencem a este programa. */
poResponse = NEW JsonObject().
poResponse:Add("pedidoRecebido", poRequest:GetInteger("pedido")).
```

O `JsonObject` de saída vira o corpo da resposta sem acrescentar campos. O roteador não interpreta propriedades de negócio como `success`. O exemplo `sursum-api/programs/JsonEcho.p` devolve o próprio objeto recebido e já está cadastrado para GET e POST em `/SursumPrograms/echo`.

Para GET, os campos da query string formam o objeto de entrada:

```text
GET /med/web/SursumPrograms/echo?pedido=00123&tag=a&tag=b
```

```json
{"pedido":"00123","tag":["a","b"]}
```

Valores de query string permanecem textos; chaves repetidas viram arrays. A conversão para tipos de negócio cabe ao `.p`. A query string usa UTF-8 e é decodificada uma vez. GET não utiliza corpo; nos outros métodos a query string não é mesclada ao JSON. Corpo vazio nos métodos com corpo entrega `{}`.

## Respostas do roteador

| Situação | HTTP |
|---|---:|
| Programa executado e `JsonObject` retornado | 200 |
| OPTIONS de rota cadastrada, sem executar `.p` | 204 |
| Corpo inválido ou não objeto / query string inválida | 400 |
| Rota não cadastrada | 404 |
| Método não permitido para a rota | 405, com `Allow` |
| Configuração inválida, programa ausente, falha de execução ou saída ausente | 500 |

As falhas do roteador retornam `{"error":{"code":"...","message":"..."}}`. Método e rota são verificados antes de interpretar a entrada ou executar qualquer programa.

## Registro separado no PASOE

O alvo desta implementação é OpenEdge 12.2. O roteador usa operações nativas ABL para decodificar a query string, sem depender de `OpenEdge.Net.UriEncoder` (introduzido no 12.5). Escapes inválidos, bytes nulos e sequências UTF-8 inválidas retornam 400 antes de executar o programa. O handler utiliza as classes WebResponse/WebResponseWriter disponíveis no 12.2. Compile os fontes com o OpenEdge do ambiente de destino; os `.r` produzidos localmente no 12.8 não são os artefatos de publicação para 12.2.

Arquivos para compilar/publicar:

- `sursum-api/rest/JsonProgramWebHandler.cls`
- `sursum-api/sursum/JsonProgramRouter.cls`
- Os `.p` cadastrados, incluindo `sursum-api/programs/JsonEcho.p` no exemplo.

Coloque `sursum-api/rest`, `sursum-api/sursum`, a raiz do projeto e `OpenEdge.Net.pl` no PROPATH. A raiz permite localizar tanto `conf-web-handler/program-routes.json` quanto os programas. Preserve a estrutura relativa dos programas ao publicar `.r`.

O arquivo `conf/pasoe/JsonProgramWebHandler.handlers.example` contém um fragmento de configuração para OpenEdge 12.2 ou superior. Mescle a entrada de `handlers` em `WEB-INF/adapters/web/ROOT/ROOT.handlers` da aplicação desejada; preserve os registros existentes. O padrão `/SursumPrograms/{route:.*}` encaminha esse prefixo ao novo handler. As rotas internas nesse prefixo passam a ser administradas pelo catálogo do projeto.

Esse registro usa o formato de handlers documentado pela [Progress](https://docs.progress.com/bundle/pas-for-openedge-management-122/page/Deploy-web-handler-services.html). Mantenha as regras de autenticação da aplicação PASOE para esse prefixo. Recarregue o mapeamento de handlers conforme o procedimento operacional da instância.

O destino informado para esta entrega é `\\192.168.0.137\erp\sursum`, com PASOE no `192.168.0.111`, contexto `med`. Preserve os handlers e rotas existentes durante a publicação. A compilação local não publica a nova rota automaticamente.

## Compatibilidade e publicação validada

Em 25/09/2026, os três fontes foram compilados sem erros no OpenEdge 12.2.12 do servidor de compilação. A suíte ABL passou nas sessões padrão e UTF-8, incluindo acentos, caracteres suplementares (UTF-8), percent-encoding e erros de entrada. O runtime do servidor PASOE é 12.2.17. Para preservar todo o repertório Unicode nos parâmetros GET, use `-cpinternal UTF-8`; sessões com outra codepage ficam limitadas aos caracteres nela representáveis.

Os fontes das duas classes e os `.r` gerados no 12.2 foram publicados diretamente na raiz `\\192.168.0.137\erp\sursum`, já presente no PROPATH. O exemplo permanece em `sursum-api/programs/JsonEcho.p` e `.r`, e o cadastro em `conf-web-handler/program-routes.json`. O mapeamento foi registrado em `sursum-api-teste/webapps/med/WEB-INF/adapters/web/ROOT/ROOT.handlers`, preservando o handler padrão.

A validação HTTP final passou em **8/8 casos**, pelo endpoint `https://192.168.0.111:9921/med/web/SursumPrograms/echo`: POST com JSON integral e acentos, GET com acentos e chaves repetidas, 405, 404, 400 para array e UTF-8 inválido, decodificação única e OPTIONS 204. A suíte ABL no compilador 12.2 passou em 48 verificações na sessão padrão e 49 em UTF-8, incluindo execução de um `.r` em `especificos/ems2/ima/http-api/` e bloqueio de caminhos fora dessa pasta.

O handler preserva os bytes UTF-8 do corpo recebido e escreve a resposta como MEMPTR, evitando a conversão pela codepage do stream WebSpeed. A sobrecarga usada de [WebResponseWriter.Write](https://documentation.progress.com/output/oehttpclient/oe122/OpenEdge.Web.WebResponseWriter.html) está disponível no OpenEdge 12.2.

## Programas na pasta http-api

Para um programa em \\192.168.0.137\erp\especificos\ems2\ima\http-api, cadastre o caminho relativo à raiz ERP:

```json
{
  "route": "/SursumPrograms/minha-operacao",
  "method": "POST",
  "program": "especificos/ems2/ima/http-api/MeuPrograma.p"
}
```

O nome acima é ilustrativo. No PASOE Linux, a raiz `/mnt/datasul/ERP` precisa estar no PROPATH, como já está na instância de teste. O roteador busca o `.r` correspondente antes do `.p`. O programa deve receber INPUT JsonObject e devolver OUTPUT JsonObject. Não use o caminho UNC no JSON nem altere a assinatura dos programas existentes sem verificá-la.

## Testes locais

Sem conexão a banco:

```powershell
$env:DLC = 'C:\Progress\OpenEdge'
& "$env:DLC\bin\_progres.exe" -b -p tests/abl/RunJsonProgramRouterTests.p
```

Confira `temp/compile-json-router.txt` sem erros e `temp/json-router-test.txt` terminando em `PASS: all JSON route cases`. Os testes executam programas de teste isolados sob `temp/json-router-fixture`, incluindo execução apenas por `.r`, erros, bloqueios de método, UTF-8, JSON direto e recarga do cadastro.

Após publicar o exemplo no PASOE, o teste HTTP pode ser habilitado explicitamente:

```powershell
$env:SURSUM_JSON_PROGRAM_BASE_URL = 'https://servidor:porta/med/web'
npx playwright test tests/e2e/playwright/pasoe-json-program-router-backend.spec.js
```

Sem essa variável, os testes HTTP são ignorados. Eles não configuram nem publicam o servidor.
