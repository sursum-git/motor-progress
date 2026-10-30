# Executor de programas Progress: métodos HTTP

O endpoint `/web/SursumDynamicQuery/program/execute` executa programas cadastrados em `sursum-conf/program-executor.json`. Cada `.p` recebe um `INPUT JsonObject` e devolve um `OUTPUT JsonObject`.

## Cadastro

```json
{
  "programs": {
    "echo-json": {
      "path": "sursum-api/programs/EchoJsonProgram.p",
      "methods": ["GET", "POST"]
    },
    "legado": "esapi/programaLegado.p"
  }
}
```

- `methods` aceita GET, POST, PUT, PATCH e DELETE. A lista é obrigatória e não pode ser vazia nos cadastros em objeto.
- Cada item deve conter um único método. Métodos são normalizados para maiúsculas.
- Um cadastro antigo em formato string continua permitindo somente POST.
- Cadastro inválido retorna `PROGRAM_CONFIG_INVALID`. Programa desconhecido retorna `PROGRAM_NOT_ALLOWED`.
- Método bloqueado retorna HTTP **405**, erro `METHOD_NOT_ALLOWED` e cabeçalho `Allow`; o programa não é executado.
- OPTIONS continua sendo tratado pelo handler e não executa programas.
- Cadastre GET apenas para operações de consulta, pois URLs podem ser repetidas por navegadores e intermediários.

## Requisições

GET recebe `program` e `parameters` na query string; `parameters` é um objeto JSON codificado para URL. Exemplo:

```text
/program/execute?program=echo-json&parameters=%7B%22id%22%3A7%7D
```

POST, PUT, PATCH e DELETE recebem o mesmo envelope no corpo, com `Content-Type: application/json`:

```json
{
  "program": "echo-json",
  "parameters": { "id": 7 }
}
```

O método HTTP real da chamada determina a validação. Um campo `method` dentro do JSON não altera o método HTTP. `parameters` omitido equivale a `{}`.

A tela `web/program-executor-client.html` possui um seletor de método, inicialmente POST. Também aceita `?method=GET&program=echo-json`. O servidor aplica a lista de métodos do cadastro independentemente da escolha na tela.

## Publicação

Publicar a configuração JSON e compilar `ProgramExecutionPolicy.cls` junto com `DynamicQueryWebHandler.cls`. Manter sincronizadas a cópia raiz e `sursum-api/rest/DynamicQueryWebHandler.cls` e publicar os `.r` nos caminhos do PROPATH usados pelo PASOE. Publicar também a tela e o proxy PHP; existe uma versão do proxy na raiz e outra em `web/`.

Seguir o fluxo operacional do projeto: compilação no host `192.168.0.42` e runtime PASOE em `192.168.0.111`. Compilação local não substitui a validação no ambiente publicado.

## Testes

```powershell
npx playwright test tests/e2e/playwright/program-executor-client.spec.js
node --test tests/e2e/program-executor-proxy.test.cjs
& 'C:\Progress\OpenEdge\bin\_progres.exe' -b -p tests/abl/RunProgramExecutionPolicyTests.p
```

O teste do proxy usa servidores locais e uma cópia isolada dos arquivos PHP em `temp/`; requer PHP com cURL, PDO SQLite e SQLite3. Se SQLite3 estiver instalado, mas desabilitado no PHP local, definir `$env:PHP_TEST_SQLITE_EXTENSION='1'` para habilitá-lo apenas nos processos de teste. `PHP_BINARY` permite escolher o executável PHP.

No teste ABL, verificar `temp/compile-policy.txt` sem erros e `temp/program-policy-test.txt` terminando em `PASS: all program policy cases`.

Após publicar, executar `tests/e2e/playwright/pasoe-program-executor-backend.spec.js` com `SURSUM_PASOE_BASE_URL` apontando para o ambiente de teste. Esse teste usa o cadastro de exemplo (`echo-json` com GET/POST) e verifica GET, compatibilidade POST e rejeições HTTP 405.
