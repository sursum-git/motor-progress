const { test, expect } = require('@playwright/test');

const sampleConfig = {
  version: 4,
  clients: [
    { id: 'cliente-a', name: 'Cliente A' },
    { id: 'cliente-b', name: 'Cliente B' }
  ],
  environments: [
    {
      id: 'ambiente-a',
      clientId: 'cliente-a',
      name: 'Ambiente A',
      pasoeBaseUrl: 'http://pasoe-a/web/SursumDynamicQuery'
    },
    {
      id: 'ambiente-b',
      clientId: 'cliente-b',
      name: 'Ambiente B',
      pasoeBaseUrl: 'http://pasoe-b/{empresa}/web/SursumDynamicQuery'
    }
  ],
  links: [
    { id: 'link-a', clientId: 'cliente-a', environmentId: 'ambiente-a' },
    { id: 'link-b', clientId: 'cliente-b', environmentId: 'ambiente-b' }
  ],
  paths: {},
  companies: [
    { id: 'empresa-a', clientId: 'cliente-a', environmentId: 'ambiente-a', name: 'Empresa A', code: '1', pathParam: 'empa' },
    { id: 'empresa-b', clientId: 'cliente-b', environmentId: 'ambiente-b', name: 'Empresa B', code: '2', pathParam: 'empb' }
  ],
  physicalDatabases: [],
  aliases: [],
  selected: { clientId: 'cliente-a', environmentId: 'ambiente-a', companyId: '' }
};

test('client grid environment button opens client environment window filtered by row', async ({ page }) => {
  await page.addInitScript((config) => {
    localStorage.setItem('sursumContextV4', JSON.stringify(config));
    localStorage.setItem('sursumApiEndpoints', JSON.stringify(config));
  }, sampleConfig);

  await page.goto('/client-config.html');
  await expect(page.locator('#clientsGrid')).toContainText('Cliente B');
  await expect(page.locator('.k-window-title').filter({ hasText: 'Ambientes do cliente' })).toBeHidden();

  const clienteBRow = page.locator('#clientsGrid tbody tr').filter({ hasText: 'Cliente B' });
  await clienteBRow.locator('.open-environments').click();

  await expect(page.locator('.k-window-title').filter({ hasText: 'Ambientes do cliente - Cliente B' })).toBeVisible();
  await expect(page.locator('#environmentEditorPanel')).toBeVisible();
  await expect(page.locator('#environmentPanelSummary')).toContainText('Cliente selecionado: Cliente B');
  await expect(page.locator('#environmentsGrid')).toContainText('Ambiente B');
  await expect(page.locator('#environmentsGrid')).not.toContainText('Ambiente A');

  await page.locator('#newEnvironment').click();
  await expect(page.locator('.k-window-title').filter({ hasText: 'Novo ambiente' })).toBeVisible();
  await page.locator('#environmentFormName').fill('Ambiente B Novo');
  await page.locator('#environmentFormUrl').fill('http://pasoe-b-novo/{empresa}/web/SursumDynamicQuery');
  await page.locator('#saveEnvironment').click();
  await expect(page.locator('#environmentsGrid')).toContainText('Ambiente B Novo');

  const novoAmbienteRow = page.locator('#environmentsGrid tbody tr').filter({ hasText: 'Ambiente B Novo' });
  await novoAmbienteRow.locator('.edit-environment-row').click();
  await expect(page.locator('.k-window-title').filter({ hasText: 'Alterar ambiente - Ambiente B Novo' })).toBeVisible();
  await page.locator('#environmentFormName').fill('Ambiente B Alterado');
  await page.locator('#environmentFormUrl').fill('http://pasoe-b-alterado/{empresa}/web/SursumDynamicQuery');
  await page.locator('#saveEnvironment').click();
  await expect(page.locator('#environmentsGrid')).toContainText('Ambiente B Alterado');
  await expect(page.locator('#environmentsGrid')).not.toContainText('Ambiente B Novo');

  const ambienteBRow = page.locator('#environmentsGrid tbody tr').filter({ hasText: 'http://pasoe-b/{empresa}/web/SursumDynamicQuery' });
  await ambienteBRow.locator('.open-companies').click();

  await expect(page.locator('.k-window-title').filter({ hasText: 'Empresas do ambiente - Ambiente B' })).toBeVisible();
  await expect(page.locator('#companyEditorPanel')).toBeVisible();
  await expect(page.locator('#companyPanelSummary')).toContainText('Ambiente selecionado: Ambiente B');
  await expect(page.locator('#companiesGrid')).toContainText('Empresa B');
  await expect(page.locator('#companiesGrid')).toContainText('2');
  await expect(page.locator('#companiesGrid')).toContainText('empb');
  await expect(page.locator('#companiesGrid')).not.toContainText('Empresa A');

  const resolved = await page.evaluate(() => window.SursumContext.resolveApiBase(
    window.SursumContext.getCurrentEnvironment(),
    window.SursumContext.getCurrentCompany()
  ));
  expect(resolved).toBe('http://pasoe-b/empb/web/SursumDynamicQuery');

  const requestConfig = await page.evaluate(() => window.SursumContext.getRequestConfig(
    'http://pasoe-b/empb/web/SursumDynamicQuery/query'
  ));
  expect(requestConfig.url).toBe('http://pasoe-b/empb/web/SursumDynamicQuery/query?companyId=2');
});
