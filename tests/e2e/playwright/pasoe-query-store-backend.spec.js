const { test, expect, request: playwrightRequest } = require("@playwright/test");

const pasoeBase = (process.env.SURSUM_PASOE_BASE_URL || "https://192.168.0.111:9911/med/web/SursumDynamicQuery").replace(/\/+$/, "");

function uniqueCode(prefix) {
  return prefix + "-" + Date.now() + "-" + Math.floor(Math.random() * 100000);
}

function sampleStoredQuery() {
  return {
    execution: "sync",
    page: 1,
    pageSize: 10,
    sources: [{ nome: "emitente", alias: "emitente", banco: "mgcad" }],
    select: [
      { sourceAlias: "emitente", field: "cod-emitente", outputAlias: "codigo" }
    ],
    filters: [],
    orderBy: [{ sourceAlias: "emitente", field: "cod-emitente", direction: "ASC" }],
    externalFilters: [
      { name: "pedido", source: "querystring", sourceAlias: "emitente", field: "cod-emitente", operator: "=", required: false },
      { name: "estabelecimento", source: "header", sourceAlias: "emitente", field: "cod-emitente", operator: "=", required: true }
    ]
  };
}

async function readJson(response) {
  const text = await response.text();
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error("Resposta nao e JSON valido: " + text.slice(0, 500));
  }
}

test.describe("PASOE backend query-store", () => {
  let pasoeRequest;

  test.beforeAll(async () => {
    pasoeRequest = await playwrightRequest.newContext({ ignoreHTTPSErrors: true });
  });

  test.afterAll(async () => {
    if (pasoeRequest) await pasoeRequest.dispose();
  });

  test("programas backend salvam consulta e executam por code com filtros externos permitidos", async () => {
    const code = uniqueCode("e2e-pasoe-query-store");
    const save = await pasoeRequest.post(pasoeBase + "/query-store", {
      data: { code, status: "ready", query: sampleStoredQuery() }
    });
    expect(save.status(), await save.text()).toBeLessThan(500);
    const saved = await readJson(save);
    expect(saved).toMatchObject({ success: true, code, status: "ready" });

    const run = await pasoeRequest.post(pasoeBase + "/query", {
      data: {
        code,
        parameters: {
          querystring: { pedido: "0" },
          headers: { estabelecimento: "0" }
        }
      }
    });
    expect(run.status(), await run.text()).toBeLessThan(500);
    const result = await readJson(run);
    expect(result.success, JSON.stringify(result)).toBe(true);
    expect(result.error).toBeFalsy();
  });

  test("programas backend rejeitam codigo invalido, parametro nao declarado e filtro obrigatorio ausente", async () => {
    const invalid = await pasoeRequest.post(pasoeBase + "/query-store", {
      data: { code: "../invasor", status: "ready", query: sampleStoredQuery() }
    });
    expect(await readJson(invalid)).toMatchObject({ success: false, error: { code: "INVALID_QUERY_CODE" } });

    const code = uniqueCode("e2e-pasoe-reject");
    const save = await pasoeRequest.post(pasoeBase + "/query-store", {
      data: { code, status: "draft", query: sampleStoredQuery() }
    });
    expect(await readJson(save)).toMatchObject({ success: true, code });

    const undeclared = await pasoeRequest.post(pasoeBase + "/query", {
      data: {
        code,
        parameters: {
          querystring: { invasor: "1" },
          headers: { estabelecimento: "0" }
        }
      }
    });
    expect(await readJson(undeclared)).toMatchObject({ success: false, error: { code: "EXTERNAL_FILTER_NOT_ALLOWED" } });

    const missingRequired = await pasoeRequest.post(pasoeBase + "/query", {
      data: { code, parameters: { querystring: { pedido: "0" } } }
    });
    expect(await readJson(missingRequired)).toMatchObject({ success: false, error: { code: "REQUIRED_EXTERNAL_FILTER_MISSING" } });
  });
});
