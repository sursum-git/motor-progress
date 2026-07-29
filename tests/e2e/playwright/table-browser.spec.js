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
