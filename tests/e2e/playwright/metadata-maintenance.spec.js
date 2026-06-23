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

test('metadata maintenance creates and runs all-table job without manual tabs', async ({ page }) => {
  await page.goto('/metadata-maintenance.html');
  await expect(page.locator('#createJob')).toBeVisible();
  await expect(page.locator('#metadataTabs')).toHaveCount(0);
  await expect(page.locator('#viewAsGrid')).toHaveCount(0);
  await expect(page.locator('#relationsGrid')).toHaveCount(0);
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
});

test('metadata batch keeps grid controls interactive while requests are running', async ({ page }) => {
  await page.goto('/metadata-maintenance.html');
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#createJob').click();
  await expect(page.locator('#jobGrid')).toContainText('Customer');

  await page.route('**/metadata-pasoe.php**', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify({ success: true, data: [] })
    });
  });

  await page.evaluate(() => {
    const widget = window.$('#parallelExecutions').data('kendoNumericTextBox');
    widget.value(2);
    widget.trigger('change');
  });
  await page.locator('#runJob').click();
  await expect(page.locator('body')).toHaveClass(/sursum-silent-grid-ajax/);
  await page.waitForTimeout(150);
  await expect(page.locator('#jobGrid .k-loading-mask')).toHaveCount(0);
  await expect(page.locator('#pauseJob')).toBeEnabled();
});

test('view-as maintenance saves manual view-as and imports CSV', async ({ page }) => {
  await page.goto('/view-as-maintenance.html');
  await expect(page.locator('#addViewAs')).toBeVisible();
  await expect(page.locator('#viewAsGrid')).toBeVisible();
  await expect(page.locator('#metadataTabs')).toHaveCount(0);

  await page.locator('#addViewAs').click();
  await expect(page.locator('#viewAsWindow')).toBeVisible();
  await page.locator('#viewAsTable').fill('Customer');
  await page.locator('#viewAsField').fill('Name');
  await page.locator('#viewAsValue').fill('view-as editor size 40 by 2');
  await page.locator('#saveViewAs').click();
  await expect(page.locator('#viewAsGrid')).toContainText('Name');
  await expect(page.locator('#viewAsGrid')).toContainText('manual');
  await expect(page.locator('#viewAsGrid')).toContainText('12/06/2026 18:00:00');

  await page.locator('#viewAsCsvFile').setInputFiles({
    name: 'view-as.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from('tabela,campo,lista de opcoes\nOrder,Status,"Aberto,A,Fechado,F"\n')
  });
  await expect(page.locator('#statusBox')).toContainText('CSV de view-as importado');
  await expect(page.locator('#viewAsGrid')).toContainText('Order');
  await expect(page.locator('#viewAsGrid')).toContainText('CSV');
});

test('relation maintenance saves manual join', async ({ page }) => {
  await page.goto('/relation-maintenance.html');
  await expect(page.locator('#addRelation')).toBeVisible();
  await expect(page.locator('#relationsGrid')).toBeVisible();
  await expect(page.locator('#metadataTabs')).toHaveCount(0);
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#addRelation').click();
  await expect(page.locator('#relationWindow')).toBeVisible();
  await page.locator('#leftTable').fill('Customer');
  await page.locator('#leftField').fill('CustNum');
  await page.locator('#rightTable').fill('Order');
  await page.locator('#rightField').fill('CustNum');
  await page.locator('#saveRelation').click();
  await expect(page.locator('#relationsGrid')).toContainText('Order');
  await expect(page.locator('#relationsGrid')).toContainText('manual');
});

test('metadata menu exposes batch, view-as and join pages separately', async ({ page }) => {
  await page.goto('/index.html');
  await expect(page.locator('#menuTree')).toContainText('Atualizacao em lote');
  await expect(page.locator('#menuTree')).toContainText('View-as manual');
  await expect(page.locator('#menuTree')).toContainText('Join manual');
});

test('metadata maintenance reprocesses all error job items', async ({ page, request }) => {
  await page.goto('/metadata-maintenance.html');
  await expect(page.locator('#reprocessAllJob')).toBeVisible();

  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#createJob').click();
  await expect(page.locator('#jobGrid')).toContainText('Customer');

  await request.post('/metadata-store.php', {
    data: {
      resource: 'job',
      action: 'item',
      jobId: 'job-1',
      table: 'Customer',
      status: 'error',
      message: 'Falha simulada',
      relationCount: 0,
      viewAsCount: 0
    }
  });

  await page.reload();
  await expect(page.locator('#jobGrid')).toContainText('Falha simulada');
  await page.locator('#reprocessAllJob').click();
  await expect(page.locator('#statusBox')).toContainText('Fila concluida');
  await expect(page.locator('#jobSummary')).toContainText('Erros: 0');
});
