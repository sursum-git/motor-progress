const { test, expect, request } = require('@playwright/test');

const apiBase = 'http://127.0.0.1:18180/web/SursumDynamicQuery';

const sampleQuery = {
  execution: 'sync',
  page: 1,
  pageSize: 25,
  sources: [{ nome: 'Customer', alias: 'customer', banco: 'DICTDB' }],
  select: [{ sourceAlias: 'customer', field: 'CustNum', outputAlias: 'codigo' }],
  filters: [],
  orderBy: [],
  externalFilters: [
    { name: 'pedido', source: 'querystring', sourceAlias: 'customer', field: 'CustNum', operator: '=', required: false },
    { name: 'estabelecimento', source: 'header', sourceAlias: 'customer', field: 'State', operator: '=', required: true }
  ]
};

async function resetMock() {
  const ctx = await request.newContext();
  await ctx.post('http://127.0.0.1:18180/__reset');
  await ctx.dispose();
}

test.beforeEach(async () => {
  await resetMock();
});

test('backend mock stores a query and executes it with allowed external filters', async ({ request }) => {
  const save = await request.post(`${apiBase}/query-store`, {
    data: { code: 'pedidos-em-aberto', status: 'ready', query: sampleQuery }
  });
  await expect(save).toBeOK();
  const saved = await save.json();
  expect(saved).toMatchObject({ success: true, code: 'pedidos-em-aberto', status: 'ready' });

  const run = await request.post(`${apiBase}/query`, {
    data: {
      code: 'pedidos-em-aberto',
      parameters: {
        querystring: { pedido: '123' },
        headers: { estabelecimento: 'SP' }
      }
    }
  });
  const result = await run.json();
  expect(result.success).toBe(true);
  expect(result.appliedFilters).toEqual([
    { sourceAlias: 'customer', field: 'CustNum', operator: '=', value: '123' },
    { sourceAlias: 'customer', field: 'State', operator: '=', value: 'SP' }
  ]);
  expect(result.data[0]).toMatchObject({ codigo: 123 });
});

test('backend mock rejects undeclared and missing required external filters', async ({ request }) => {
  await request.post(`${apiBase}/query-store`, { data: { code: 'clientes', status: 'draft', query: sampleQuery } });

  const undeclared = await request.post(`${apiBase}/query`, {
    data: { code: 'clientes', parameters: { querystring: { invasor: '1' }, headers: { estabelecimento: 'SP' } } }
  });
  expect(await undeclared.json()).toMatchObject({ success: false, error: { code: 'EXTERNAL_FILTER_NOT_ALLOWED' } });

  const missing = await request.post(`${apiBase}/query`, {
    data: { code: 'clientes', parameters: { querystring: { pedido: '123' } } }
  });
  expect(await missing.json()).toMatchObject({ success: false, error: { code: 'REQUIRED_EXTERNAL_FILTER_MISSING' } });
});

test('frontend builder posts code, status and query JSON to PASOE query-store', async ({ page, request }) => {
  await page.goto('/query-builder.html?new=1');
  await page.evaluate(({ apiBase, sampleQuery }) => {
    localStorage.setItem('sursumApiBaseUrl', apiBase);
    localStorage.setItem('sursumCurrentQueryJson', JSON.stringify(sampleQuery, null, 2));
  }, { apiBase, sampleQuery });
  await page.goto('/query-builder.html');
  await page.locator('#apiBaseUrl').evaluate((input, value) => { input.value = value; }, apiBase);
  await page.fill('#queryName', 'Pedidos em aberto');
  await page.fill('#queryCode', 'pedidos-em-aberto');
  await page.locator('#queryStoreStatus').evaluate((input) => { input.value = 'ready'; });
  await page.evaluate(() => {
    const widget = window.$('#queryStoreStatus').data('kendoDropDownList');
    if (widget) widget.value('ready');
  });

  await page.click('#saveQueryBackend');
  await expect(page.locator('#statusBox')).toContainText('Consulta salva no PASOE como pedidos-em-aberto');

  const calls = await (await request.get('http://127.0.0.1:18180/__requests')).json();
  const saveCall = calls.requests.find((item) => item.path.endsWith('/query-store'));
  expect(saveCall).toBeTruthy();
  expect(saveCall.body.code).toBe('pedidos-em-aberto');
  expect(saveCall.body.status).toBe('ready');
  expect(saveCall.body.query.externalFilters).toHaveLength(2);
});


test("frontend builder expands extent fields as selectable indexed fields", async ({ page }) => {
  await page.goto("/query-builder.html?new=1");
  await page.evaluate((apiBase) => { localStorage.setItem("sursumApiBaseUrl", apiBase); }, apiBase);
  await page.goto("/query-builder.html");
  await page.locator("#apiBaseUrl").evaluate((input, value) => { input.value = value; }, apiBase);
  await page.click("#loadMetadata");
  await expect(page.locator("#statusBox")).toContainText("Lista de tabelas carregada");
  await page.evaluate(() => {
    const db = window.$("#sourceDatabase").data("kendoComboBox");
    if (db) db.value("DICTDB");
    window.$("#sourceTable").val("Customer");
  });
  await page.evaluate(() => document.querySelector("#loadTable").click());
  await expect(page.locator("#statusBox")).toContainText("Campos carregados");

  const names = await page.evaluate(() => window.$("#selectField").data("kendoComboBox").dataSource.data().map((item) => item.name));
  expect(names).toContain("Phone[1]");
  expect(names).toContain("Phone[2]");
});

test("frontend builder loads metadata through PHP proxy for cross-origin PASOE", async ({ page }) => {
  const remoteConfig = {
    version: 4,
    clients: [{ id: "cliente-a", name: "Cliente A" }],
    environments: [{
      id: "ambiente-a",
      clientId: "cliente-a",
      name: "Ambiente A",
      pasoeBaseUrl: "http://pasoe.internal/web/SursumDynamicQuery",
      companyIdMode: "query"
    }],
    links: [{ id: "link-a", clientId: "cliente-a", environmentId: "ambiente-a" }],
    paths: {},
    companies: [{
      id: "empresa-a",
      clientId: "cliente-a",
      environmentId: "ambiente-a",
      name: "Empresa A",
      code: "1",
      pathParam: "empresa-a"
    }],
    physicalDatabases: [],
    aliases: [],
    selected: { clientId: "cliente-a", environmentId: "ambiente-a", companyId: "empresa-a" }
  };
  const proxiedTargets = [];

  await page.route("**/context-store.php", async (route) => {
    await route.fulfill({ json: { success: true, data: remoteConfig } });
  });
  await page.route("**/pasoe-proxy.php?target=*", async (route) => {
    const target = new URL(route.request().url()).searchParams.get("target") || "";
    proxiedTargets.push(target);
    if (target.includes("/metadata/database-catalog")) {
      await route.fulfill({ json: { success: true, data: [{ name: "DICTDB", displayName: "DICTDB" }] } });
      return;
    }
    if (target.includes("/metadata/tables")) {
      await route.fulfill({ json: { success: true, data: [{ name: "Customer", label: "Customer", database: "DICTDB" }] } });
      return;
    }
    await route.fulfill({ json: { success: true, data: [] } });
  });

  await page.goto("/index.html?page=query-builder.html");
  const frame = page.frameLocator("#contentFrame");
  await frame.locator("#loadMetadata").click();

  await expect(frame.locator("#statusBox")).toContainText("Lista de tabelas carregada");
  expect(proxiedTargets.some((target) => target.includes("/metadata/database-catalog"))).toBe(true);
  expect(proxiedTargets.some((target) => target.includes("/metadata/tables"))).toBe(true);
});

test("frontend builder renders query name, code and pipeline version as Kendo text boxes", async ({ page }) => {
  await page.goto("/query-builder.html?new=1");

  await expect(page.locator("#queryName").locator("xpath=ancestor::*[contains(@class, 'k-input')]").first()).toBeVisible();
  await expect(page.locator("#queryCode").locator("xpath=ancestor::*[contains(@class, 'k-input')]").first()).toBeVisible();
  await expect(page.locator("#pipelineVersion").locator("xpath=ancestor::*[contains(@class, 'k-input')]").first()).toBeVisible();
});

test("frontend builder keeps endpoint actions inside the card on narrow viewports", async ({ page }) => {
  await page.setViewportSize({ width: 760, height: 820 });
  await page.goto("/index.html?page=query-builder.html");
  const root = page.frameLocator("#contentFrame");

  const layout = await root.locator(".endpoint-card").evaluate((card) => {
    const actions = card.querySelector(".action-row");
    const cardRect = card.getBoundingClientRect();
    const actionRect = actions.getBoundingClientRect();
    const actionStyle = getComputedStyle(actions);
    return {
      cardClientWidth: card.clientWidth,
      cardScrollWidth: card.scrollWidth,
      actionClientWidth: actions.clientWidth,
      actionScrollWidth: actions.scrollWidth,
      actionRight: actionRect.right,
      cardRight: cardRect.right,
      actionLeft: actionRect.left,
      cardLeft: cardRect.left,
      actionFlexWrap: actionStyle.flexWrap,
      actionGridColumnStart: actionStyle.gridColumnStart,
      actionGridColumnEnd: actionStyle.gridColumnEnd
    };
  });

  expect(layout.cardScrollWidth).toBeLessThanOrEqual(layout.cardClientWidth);
  expect(layout.actionScrollWidth).toBeLessThanOrEqual(layout.actionClientWidth);
  expect(layout.actionLeft).toBeGreaterThanOrEqual(layout.cardLeft);
  expect(layout.actionRight).toBeLessThanOrEqual(layout.cardRight);
  expect(layout.actionFlexWrap).toBe("wrap");
  expect(layout.actionGridColumnStart).toBe("1");
  expect(layout.actionGridColumnEnd).toBe("-1");
});
