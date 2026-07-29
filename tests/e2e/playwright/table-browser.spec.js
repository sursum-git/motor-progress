const { test, expect } = require('@playwright/test');

const sampleConfig = {
  version: 4,
  clients: [{ id: 'cliente-a', name: 'Cliente A' }],
  environments: [{
    id: 'ambiente-a',
    clientId: 'cliente-a',
    name: 'Ambiente A',
    pasoeBaseUrl: 'http://127.0.0.1:18180/web/SursumDynamicQuery',
    companyIdMode: 'query'
  }],
  links: [{ id: 'link-a', clientId: 'cliente-a', environmentId: 'ambiente-a' }],
  paths: {},
  companies: [{
    id: 'empresa-a',
    clientId: 'cliente-a',
    environmentId: 'ambiente-a',
    name: 'Empresa A',
    code: '1',
    pathParam: 'empresa-a'
  }],
  physicalDatabases: [],
  aliases: [],
  selected: { clientId: 'cliente-a', environmentId: 'ambiente-a', companyId: 'empresa-a' }
};

test.beforeEach(async ({ page, request }) => {
  await request.post('/__reset');
  await page.addInitScript((config) => {
    localStorage.setItem('sursumContextV4', JSON.stringify(config));
  }, sampleConfig);
});

test('table browser updates metadata with selected include checkboxes', async ({ page, request }) => {
  await page.goto('/table-browser.html');
  await expect(page.locator('#refreshMetadata')).toBeVisible();
  await expect.poll(async () => {
    const payload = await (await request.get('/__requests')).json();
    return payload.requests.some((item) => item.path.includes('/metadata/database-catalog'));
  }).toBe(true);
  let payload = await (await request.get('/__requests')).json();
  expect(payload.requests.some((item) => item.path.includes('/metadata/sync'))).toBe(false);
  await expect(page.locator('#dbCombo')).toHaveValue('TODOS');
  await request.post('/__reset');

  for (const id of ['syncBanks', 'syncAliases', 'syncTables', 'syncFields', 'syncIndices', 'syncViewAs']) {
    await expect(page.locator(`#${id}`)).toBeChecked();
  }

  await page.locator('#refreshMetadata').click();
  await expect(page.locator('#statusBox')).toContainText('Metadados atualizados');

  payload = await (await request.get('/__requests')).json();
  const sync = payload.requests.find((item) => decodeURIComponent(item.path).includes('view-as'));
  expect(sync).toBeTruthy();
  expect(decodeURIComponent(sync.path)).toContain('include=banks,aliases,tables,fields,indices,view-as');
});

test('table browser opens available table selector from table search icon', async ({ page }) => {
  await page.goto('/table-browser.html');
  await expect(page.locator('#openTableSelector')).toBeVisible();

  await page.locator('#openTableSelector').click();

  await expect(page.locator('.k-window-title').filter({ hasText: 'Selecionar tabela' })).toBeVisible();
  await expect(page.locator('#tableSelectorGrid')).toContainText('Customer');
  await page.locator('#tableSelectorGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();

  await expect(page.locator('#tableName')).toHaveValue('Customer');
  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');
});

test('table browser searches typed table across all databases when database combo is blank', async ({ page }) => {
  const tableListRequests = [];
  await page.route('**/metadata/tables?**', async (route) => {
    const url = new URL(route.request().url());
    const database = url.searchParams.get('database') || '';
    const query = url.searchParams.get('q') || url.searchParams.get('filter') || '';
    tableListRequests.push({ database, query });
    if (database === 'TODOS' && query === 'Customer') {
      await route.fulfill({ json: { success: true, data: [{ name: 'Customer', label: 'Customer', database: 'DICTDB' }] } });
      return;
    }
    await route.fulfill({ json: { success: true, data: [] } });
  });

  await page.goto('/table-browser.html');
  await page.evaluate(() => {
    $("#dbCombo").data("kendoComboBox").value("");
  });
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();

  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');
  await expect.poll(async () => page.locator('.k-loading-mask:visible').count()).toBe(0);
  expect(tableListRequests).toContainEqual({ database: 'TODOS', query: 'Customer' });
});

test('table browser does not keep grid loading while auxiliary relation request is pending', async ({ page }) => {
  await page.route('**/relation-store.php**', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 4000));
    await route.fulfill({ json: { success: true, data: [] } });
  });

  await page.goto('/table-browser.html');
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();

  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');
  await expect.poll(async () => page.locator('.k-loading-mask:visible').count()).toBe(0);
});

test('grid loading cleanup removes masks from grids hidden during ajax stop', async ({ page }) => {
  await page.goto('/table-browser.html');
  await page.evaluate(() => {
    window.SursumGridLoading.visible(true);
    $("#fieldsGrid").hide();
    window.SursumGridLoading.visible(false);
    $("#fieldsGrid").show();
  });

  await expect.poll(async () => page.locator('#fieldsGrid .k-loading-mask:visible').count()).toBe(0);
});

test('table browser find metadata loads fields indexes view-as and refreshes joins by OF', async ({ page }) => {
  await page.goto('/table-browser.html');
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();

  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');
  await expect(page.locator('#fieldsGrid')).toContainText('FILL-IN');
  await expect(page.locator('#indexesGrid')).toContainText('CustNum');
  await page.locator('#metadataTabs li').filter({ hasText: 'Joins' }).click();
  await expect(page.locator('#joinsGrid')).not.toContainText('Order');

  await page.locator('#refreshCurrentJoins').click();
  await expect(page.locator('#joinsGrid')).toContainText('Order');
  await expect(page.locator('#statusBox')).toContainText('Joins OF atualizados');
});

test('table browser data tab keeps rows when order is inverted and formats dates as pt-BR', async ({ page, request }) => {
  await page.goto('/table-browser.html');
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();
  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');

  await page.locator('#metadataTabs li').filter({ hasText: 'Dados' }).click();
  await expect(page.locator('#openBrowseFilterBtn')).toContainText('Abrir filtros');
  await expect(page.locator('#browseNextBtn')).toContainText('Carregar mais registros');
  await expect(page.locator('label[for="browsePageSize"]')).toContainText('Novos registros');
  await expect(page.locator('label[for="browseGridPageSize"]')).toContainText('Registros por página');
  await page.locator('#browseFirstBtn').click();
  await expect(page.locator('#dataGrid')).toContainText('Cliente Asc');
  await expect(page.locator('#dataGrid')).toContainText('05/01/2026');

  await page.locator('#browseInvertBtn').click();
  await expect(page.locator('#dataGrid')).toContainText('Cliente Desc');
  await expect(page.locator('#dataGrid')).toContainText('29/07/2026');
  await expect(page.locator('#browseKeyInfo')).toContainText('CustNum DESC');

  const payload = await (await request.get('/__requests')).json();
  const browseRequests = payload.requests.filter((item) => item.path.endsWith('/table-browse'));
  expect(browseRequests.map((item) => item.body.direction)).toEqual(['ASC', 'DESC']);
});

test('table browser data tab appends more records and moves to last grid page', async ({ page }) => {
  const requestedPageSizes = [];
  await page.route(/\/table-browse(\?|$)/, async (route) => {
    const body = route.request().postDataJSON();
    requestedPageSizes.push(body.pageSize);
    const useCursor = !!body.cursor;
    const rows = useCursor
      ? Array.from({ length: 55 }, (_, index) => ({ CustNum: index + 51, Name: `Cliente Mais ${index + 51}` }))
      : Array.from({ length: 50 }, (_, index) => ({ CustNum: index + 1, Name: `Cliente Inicial ${index + 1}` }));
    await route.fulfill({
      json: {
        success: true,
        database: body.database || 'DICTDB',
        table: body.table || 'Customer',
        direction: body.direction || 'ASC',
        pageSize: body.pageSize || 50,
        recordsReturned: rows.length,
        hasMore: !useCursor,
        keyFields: [{ name: 'CustNum', type: 'integer', ascending: true }],
        fields: [
          { name: 'CustNum', type: 'integer' },
          { name: 'Name', type: 'character' }
        ],
        data: rows,
        nextCursor: { CustNum: rows[rows.length - 1].CustNum },
        strategy: 'KEYSET_CURSOR'
      }
    });
  });

  await page.goto('/table-browser.html');
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();
  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');

  await page.locator('#metadataTabs li').filter({ hasText: 'Dados' }).click();
  await page.evaluate(() => {
    $("#browsePageSize").data("kendoNumericTextBox").value(750);
    $("#browseGridPageSize").data("kendoNumericTextBox").value(25);
    $("#browseGridPageSize").data("kendoNumericTextBox").trigger("change");
  });
  await page.locator('#browseFirstBtn').click();
  await expect(page.locator('#dataGrid')).toContainText('Cliente Inicial 1');

  await page.locator('#browseNextBtn').click();
  await expect(page.locator('#dataGrid')).toContainText('Cliente Mais 101');
  await expect.poll(async () => page.evaluate(() => $("#dataGrid").data("kendoGrid").dataSource.data().length)).toBe(105);
  await expect.poll(async () => page.evaluate(() => $("#dataGrid").data("kendoGrid").dataSource.pageSize())).toBe(25);
  await expect.poll(async () => page.evaluate(() => $("#dataGrid").data("kendoGrid").dataSource.page())).toBe(5);
  expect(requestedPageSizes).toEqual([750, 750]);
});

test('table browser data tab can be maximized and restored', async ({ page }) => {
  await page.goto('/table-browser.html');
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();
  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');

  await page.locator('#metadataTabs li').filter({ hasText: 'Dados' }).click();
  await page.locator('#browseFirstBtn').click();
  await expect(page.locator('#dataGrid')).toContainText('Cliente Asc');

  await page.locator('#toggleDataMaximizeBtn').click();
  await expect(page.locator('#browseDataPanel')).toHaveClass(/is-maximized/);
  await expect(page.locator('#toggleDataMaximizeBtn')).toContainText('Fechar');
  await expect.poll(async () => page.locator('#browseDataPanel.is-maximized #dataGrid').boundingBox())
    .toMatchObject({ width: expect.any(Number), height: expect.any(Number) });

  await page.locator('#toggleDataMaximizeBtn').click();
  await expect(page.locator('#browseDataPanel')).not.toHaveClass(/is-maximized/);
  await expect(page.locator('#toggleDataMaximizeBtn')).toContainText('Maximizar');
});

test('table browser data tab sends filters configured in maximized filter window', async ({ page, request }) => {
  await page.goto('/table-browser.html');
  await page.locator('#tableName').fill('Customer');
  await page.locator('#findTableBtn').click();
  await expect(page.locator('#fieldsGrid')).toContainText('CustNum');

  await page.locator('#metadataTabs li').filter({ hasText: 'Dados' }).click();
  await page.locator('#openBrowseFilterBtn').click();
  await expect(page.locator('.k-window-title').filter({ hasText: 'Filtros da tabela corrente' })).toBeVisible();

  await page.evaluate(() => {
    $("#filterField").data("kendoDropDownList").value("Name");
    $("#filterOperator").data("kendoDropDownList").value("contains");
    $("#filterValue").val("Cliente");
    $("#filterValue").trigger("keyup");
  });
  await page.locator('#updateBrowseFilter').click();

  await expect(page.locator('#browseFilterGrid')).toContainText('Name');
  await expect(page.locator('#browseFilterGrid')).toContainText('Contem');
  await expect(page.locator('#browseFilterInfo')).toContainText('Filtros: 1 ativo');

  await page.locator('#browseFilterGrid tbody tr').filter({ hasText: 'Name' }).click();
  await expect.poll(async () => page.evaluate(() => $("#filterField").data("kendoDropDownList").value())).toBe("Name");
  await expect.poll(async () => page.evaluate(() => $("#filterOperator").data("kendoDropDownList").value())).toBe("contains");
  await expect(page.locator('#filterValue')).toHaveValue('Cliente');

  await page.locator('#filterValue').fill('Cliente Alterado');
  await page.locator('#updateBrowseFilter').click();

  await expect(page.locator('#browseFilterGrid')).toContainText('Cliente Alterado');
  await expect.poll(async () => page.evaluate(() => $("#browseFilterGrid").data("kendoGrid").dataSource.data().length)).toBe(1);
  const payload = await (await request.get('/__requests')).json();
  const browseRequests = payload.requests.filter((item) => item.path.endsWith('/table-browse'));
  const browseRequest = browseRequests[browseRequests.length - 1];
  expect(browseRequests).toHaveLength(2);
  expect(browseRequest.body.filters).toEqual([{ field: 'Name', operator: 'contains', value: 'Cliente Alterado' }]);
});
