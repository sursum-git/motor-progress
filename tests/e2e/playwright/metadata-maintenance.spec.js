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
  selected: { clientId: 'cliente-a', environmentId: 'ambiente-a', companyId: 'empresa-a' }
};

test.beforeEach(async ({ page, request }) => {
  await request.post('/__reset');
  await page.addInitScript((config) => {
    localStorage.setItem('sursumContextV4', JSON.stringify(config));
  }, sampleConfig);
});

test('metadata maintenance creates and runs all-table job and saves manual metadata', async ({ page }) => {
  await page.goto('/metadata-maintenance.html');
  await expect(page.locator('#createJob')).toBeVisible();
  await expect(page.locator('#statusBox')).toContainText('Selecione um banco');

  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#createJob').click();
  await expect(page.locator('#jobGrid')).toContainText('Customer');
  await expect(page.locator('#jobGrid')).toContainText('Order');

  await page.locator('#runJob').click();
  await expect(page.locator('#statusBox')).toContainText('Fila concluida');
  await expect(page.locator('#jobSummary')).toContainText('Processadas: 2/2');

  await page.locator('#metadataTabs li').filter({ hasText: 'View-as manual' }).click();
  await page.locator('#viewAsTable').fill('Customer');
  await page.locator('#viewAsField').fill('Name');
  await page.locator('#viewAsValue').fill('view-as editor size 40 by 2');
  await page.locator('#saveViewAs').click();
  await expect(page.locator('#viewAsGrid')).toContainText('Name');
  await expect(page.locator('#viewAsGrid')).toContainText('manual');

  await page.locator('#metadataTabs li').filter({ hasText: 'Join manual' }).click();
  await page.locator('#leftTable').fill('Customer');
  await page.locator('#leftField').fill('CustNum');
  await page.locator('#rightTable').fill('Order');
  await page.locator('#rightField').fill('CustNum');
  await page.locator('#saveRelation').click();
  await expect(page.locator('#relationsGrid')).toContainText('Order');
  await expect(page.locator('#relationsGrid')).toContainText('manual');
});
