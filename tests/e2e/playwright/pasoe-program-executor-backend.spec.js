const { test, expect, request: playwrightRequest } = require("@playwright/test");

const pasoeBase = (process.env.SURSUM_PASOE_BASE_URL || "https://192.168.0.111:9911/med/web/SursumDynamicQuery").replace(/\/+$/, "");

async function readJson(response) {
  const text = await response.text();
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error("Resposta nao e JSON valido: " + text.slice(0, 500));
  }
}

test.describe("PASOE backend program executor", () => {
  let pasoeRequest;

  test.beforeAll(async () => {
    pasoeRequest = await playwrightRequest.newContext({ ignoreHTTPSErrors: true });
  });

  test.afterAll(async () => {
    if (pasoeRequest) await pasoeRequest.dispose();
  });

  test("executa programa cadastrado com parametros JsonObject e retorna JsonObject", async () => {
    const response = await pasoeRequest.post(pasoeBase + "/program/execute", {
      data: {
        program: "echo-json",
        parameters: {
          nr_container: 1650,
          texto: "teste"
        }
      }
    });
    expect(response.status(), await response.text()).toBeLessThan(500);
    expect(await readJson(response)).toMatchObject({
      success: true,
      program: "echo-json",
      parameters: {
        nr_container: 1650,
        texto: "teste"
      }
    });
  });

  test("rejeita programa nao cadastrado", async () => {
    const response = await pasoeRequest.post(pasoeBase + "/program/execute", {
      data: {
        program: "nao-cadastrado",
        parameters: {}
      }
    });
    expect(response.status(), await response.text()).toBeLessThan(500);
    expect(await readJson(response)).toMatchObject({
      success: false,
      error: { code: "PROGRAM_NOT_ALLOWED" }
    });
  });
});

// Requires the updated handler, policy class, and sample program-executor.json on PASOE.
test.describe('PASOE backend program executor methods', () => {
  let api;
  test.beforeAll(async () => { api = await playwrightRequest.newContext({ ignoreHTTPSErrors: true }); });
  test.afterAll(async () => { if (api) await api.dispose(); });
  test('GET decodes JSON parameters without executing a body', async () => {
    const response = await api.get(pasoeBase + '/program/execute', {
      params: { program: 'echo-json', parameters: JSON.stringify({ texto: 'ação & + ?', nested: { id: 7 } }) }
    });
    expect(response.status()).toBe(200);
    expect(await readJson(response)).toMatchObject({ success: true, parameters: { texto: 'ação & + ?', nested: { id: 7 } } });
  });
  for (const method of ['PUT', 'PATCH', 'DELETE']) {
    test(`${method} is rejected before running echo-json`, async () => {
      const response = await api.fetch(pasoeBase + '/program/execute', { method, data: { program: 'echo-json', parameters: {} } });
      expect(response.status()).toBe(405);
      expect(response.headers().allow).toContain('GET');
      expect(await readJson(response)).toMatchObject({ success: false, error: { code: 'METHOD_NOT_ALLOWED' } });
    });
  }
  test('GET to a legacy POST-only entry returns 405 before parsing invalid parameters', async () => {
    const response = await api.get(pasoeBase + '/program/execute', { params: { program: 'analise-json-object10', parameters: 'not-json' } });
    expect(response.status()).toBe(405);
    expect(response.headers().allow).toBe('POST,OPTIONS');
    expect(await readJson(response)).toMatchObject({ success: false, error: { code: 'METHOD_NOT_ALLOWED' } });
  });
});
