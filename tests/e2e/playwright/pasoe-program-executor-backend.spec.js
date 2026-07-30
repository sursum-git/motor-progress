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
