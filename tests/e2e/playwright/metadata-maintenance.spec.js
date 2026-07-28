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

test('metadata batch updates only the changed grid row while running', async ({ page }) => {
  await page.goto('/metadata-maintenance.html');
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#createJob').click();
  await expect(page.locator('#jobGrid')).toContainText('Customer');
  await expect(page.locator('#jobGrid')).toContainText('Order');

  await page.route('**/metadata-pasoe.php**', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify({ success: true, data: [] })
    });
  });

  await page.evaluate(() => {
    const widget = window.$('#parallelExecutions').data('kendoNumericTextBox');
    widget.value(1);
    widget.trigger('change');
    const grid = window.$('#jobGrid').data('kendoGrid');
    window.__jobGridTouches = [];
    grid.dataSource.data().forEach((model) => {
      const table = model.table || (typeof model.get === 'function' ? model.get('table') : '');
      const originalGet = model.get ? model.get.bind(model) : null;
      const originalSet = model.set ? model.set.bind(model) : null;
      if (originalGet) {
        model.get = function (field) {
          window.__jobGridTouches.push({ table, type: 'get', field });
          return originalGet(field);
        };
      }
      if (originalSet) {
        model.set = function (field, value) {
          window.__jobGridTouches.push({ table, type: 'set', field });
          return originalSet(field, value);
        };
      }
    });
  });

  await page.locator('#runJob').click();
  await page.waitForTimeout(300);
  const touchedTables = await page.evaluate(() => Array.from(new Set(window.__jobGridTouches.map((item) => item.table))));
  expect(touchedTables).toEqual(['Customer']);
});

test('metadata batch grid paginates large pending jobs', async ({ page, request }) => {
  const tables = Array.from({ length: 500 }, (_, index) => `table-${String(index + 1).padStart(3, '0')}`);
  await request.post('/metadata-store.php', {
    data: {
      resource: 'job',
      action: 'create',
      environmentId: 'ambiente-a',
      companyId: 'empresa-a',
      database: 'DICTDB',
      tables,
      includeRelations: false,
      includeViewAs: true,
      existingMetadataBehavior: 'skip'
    }
  });
  await page.addInitScript(() => {
    localStorage.setItem('sursumMetadataMaintenanceLastJob', 'job-1');
  });

  await page.goto('/metadata-maintenance.html');
  await expect(page.locator('#jobSummary')).toContainText('Processadas: 0/500');
  await expect(page.locator('#jobGrid')).toContainText('table-001');

  const renderedRows = await page.locator('#jobGrid .k-grid-content tbody tr').count();
  expect(renderedRows).toBeLessThanOrEqual(120);
});

test('metadata grids expose Excel export action', async ({ page }) => {
  await page.goto('/metadata-maintenance.html');
  await expect(page.locator('#jobGrid .k-grid-excel')).toBeVisible();
  await expect(page.locator('#jobGrid .k-grid-excel')).toContainText(/Excel/i);
  const downloadPromise = page.waitForEvent('download');
  await page.locator('#jobGrid .k-grid-excel').click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe('sursum-atualizacao-lote-metadados.xlsx');

  await page.goto('/view-as-maintenance.html');
  await expect(page.locator('#viewAsGrid .k-grid-excel')).toBeVisible();
});

test('metadata batch treats empty PASOE 200 field response as empty metadata', async ({ page }) => {
  await page.goto('/metadata-maintenance.html');
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
    window.$('#includeRelations').prop('checked', false);
  });
  await page.route('**/metadata-pasoe.php**', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify({
        success: true,
        data: [],
        warning: 'PASOE respondeu HTTP 200 com corpo vazio.'
      })
    });
  });

  await page.locator('#createJob').click();
  await page.locator('#runJob').click();
  await expect(page.locator('#statusBox')).toContainText('Fila concluida');
  await expect(page.locator('#jobSummary')).toContainText('Erros: 0');
});

test('metadata batch saves resolved view-as options without replacing the include', async ({ page, request }) => {
  await page.goto('/metadata-maintenance.html');
  await page.route('**/metadata-pasoe.php**', async (route) => {
    const path = new URL(route.request().url()).searchParams.get('path') || '';
    if (!path.includes('/metadata/tables/Customer/fields')) {
      return route.continue();
    }
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify({
        success: true,
        data: [{
          name: 'modalidade',
          viewAs: 'view-as radio-set radio-buttons {adinc/i03ad209.i 2}'
        }]
      })
    });
  });
  await page.route('**/metadata/view-as/resolve**', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify({
        success: true,
        data: [{
          field: 'modalidade',
          viewAs: 'view-as radio-set radio-buttons {adinc/i03ad209.i 2}',
          include: 'adinc/i03ad209.i',
          listExpression: '"Aberto",1,"Fechado",2',
          options: [
            { label: 'Aberto', value: '1' },
            { label: 'Fechado', value: '2' }
          ],
          source: 'PASOE'
        }]
      })
    });
  });
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
    window.$('#tableName').data('kendoComboBox').value('Customer');
    window.$('#onlyCurrentTable').prop('checked', true);
    window.$('#includeRelations').prop('checked', false);
  });

  await page.locator('#createJob').click();
  await page.locator('#runJob').click();
  await expect(page.locator('#statusBox')).toContainText('Fila concluida');

  const stored = await request.get('/metadata-store.php?resource=view-as&database=DICTDB&table=Customer');
  const payload = await stored.json();
  const modalidade = payload.data.find((row) => row.field === 'modalidade');
  expect(modalidade.viewAs).toBe('view-as radio-set radio-buttons {adinc/i03ad209.i 2}');
  expect(modalidade.listExpression).toBe('"Aberto",1,"Fechado",2');
  expect(modalidade.options).toEqual([
    { label: 'Aberto', value: '1' },
    { label: 'Fechado', value: '2' }
  ]);
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

test('view-as maintenance displays and edits option values', async ({ page, request }) => {
  await request.post('/metadata-store.php', {
    data: {
      resource: 'view-as',
      database: 'DICTDB',
      table: 'Customer',
      rows: [{
        field: 'Status',
        viewAs: 'view-as radio-set radio-buttons "Aberto",A,"Fechado",F',
        listExpression: '"Aberto",A,"Fechado",F',
        options: [
          { label: 'Aberto', value: 'A' },
          { label: 'Fechado', value: 'F' }
        ]
      }]
    }
  });
  await page.goto('/view-as-maintenance.html');
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
    window.$('#tableName').data('kendoComboBox').value('Customer');
    window.$('#tableName').data('kendoComboBox').trigger('change');
  });
  await expect(page.locator('#viewAsGrid')).toContainText('Aberto');

  await page.locator('#viewAsGrid .edit-view-as').first().click();
  await expect(page.locator('#viewAsOptions')).toHaveValue('"Aberto",A,"Fechado",F');
  await page.locator('#viewAsOptions').fill('"Pendente",P,"Finalizado",F');
  await page.locator('#saveViewAs').click();
  await expect(page.locator('#viewAsGrid')).toContainText('Pendente');

  const stored = await request.get('/metadata-store.php?resource=view-as&database=DICTDB&table=Customer');
  const payload = await stored.json();
  const status = payload.data.find((row) => row.field === 'Status');
  expect(status.viewAs).toBe('view-as radio-set radio-buttons "Aberto",A,"Fechado",F');
  expect(status.listExpression).toBe('"Pendente",P,"Finalizado",F');
  expect(status.options).toEqual([
    { label: 'Pendente', value: 'P' },
    { label: 'Finalizado', value: 'F' }
  ]);
});

test('view-as maintenance combines PASOE tables and local view-as tables without counting fields as tables', async ({ page, request }) => {
  await request.post('/metadata-store.php', {
    data: {
      resource: 'view-as',
      database: 'ems2cad',
      table: 'wt-ped-venda',
      rows: [{ field: 'nr-ped-venda', viewAs: 'FILL-IN' }]
    }
  });
  await page.route('**/metadata-pasoe.php**', async (route) => {
    const target = new URL(route.request().url()).searchParams.get('path') || '';
    if (target.includes('/metadata/tables')) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json; charset=utf-8',
        body: JSON.stringify({
          success: true,
          data: [
            { table: 'emitente', name: 'cod-emitente' },
            { table: 'emitente', name: 'nome-emit' },
            { table: 'wt-ped-venda', name: 'nr-ped-venda' }
          ]
        })
      });
    }
    return route.continue();
  });

  await page.goto('/view-as-maintenance.html');
  await page.evaluate(() => {
    const combo = window.$('#dbCombo').data('kendoComboBox');
    combo.value('ems2cad');
    combo.trigger('change');
  });

  await expect(page.locator('#resultSummary')).toContainText('1 registro');
  await expect(page.locator('#resultSummary')).toContainText('1 tabela');
  const tableNames = await page.evaluate(() => {
    const combo = window.$('#tableName').data('kendoComboBox');
    return combo.dataSource.data().map((item) => String(item));
  });
  expect(tableNames).toContain('emitente');
  expect(tableNames).toContain('wt-ped-venda');
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

test('index menu collapses after selecting a page and can be shown again', async ({ page }) => {
  await page.goto('/index.html');
  await expect(page.locator('#appSidebar')).toBeVisible();

  await page.getByText('Atualizacao em lote', { exact: true }).click();
  await expect(page.locator('#appShell')).toHaveClass(/menu-collapsed/);
  await expect(page.locator('#appSidebar')).not.toBeVisible();

  await page.locator('#toggleMenu').click();
  await expect(page.locator('#appShell')).not.toHaveClass(/menu-collapsed/);
  await expect(page.locator('#appSidebar')).toBeVisible();
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
