const { test, expect } = require('@playwright/test');

function contextPayload() {
  return {
    success: true,
    data: {
      version: 4,
      clients: [{ id: 'cliente-a', name: 'Cliente A' }],
      environments: [{
        id: 'ambiente-a',
        clientId: 'cliente-a',
        name: 'Ambiente A',
        pasoeBaseUrl: 'http://127.0.0.1:18180/{empresa}/web/SursumDynamicQuery',
        companyIdMode: 'query'
      }],
      links: [{ id: 'link-a', clientId: 'cliente-a', environmentId: 'ambiente-a' }],
      paths: {},
      companies: [{
        id: 'empresa-med',
        clientId: 'cliente-a',
        environmentId: 'ambiente-a',
        name: 'MED',
        code: '1',
        pathParam: 'med'
      }, {
        id: 'empresa-ima',
        clientId: 'cliente-a',
        environmentId: 'ambiente-a',
        name: 'IMA',
        code: '2',
        pathParam: 'ima'
      }],
      physicalDatabases: [],
      aliases: [],
      selected: { clientId: 'cliente-a', environmentId: 'ambiente-a', companyId: 'empresa-med' }
    }
  };
}

test.beforeEach(async ({ request }) => {
  await request.post('/__reset');
});

test('query wizard loads database combo from remote context PASOE endpoint', async ({ page, request }) => {
  await page.addInitScript(() => {
    localStorage.clear();
  });
  await page.route('**/context-store.php', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 300));
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');

  await expect.poll(async () => {
    const comboItems = await page.evaluate(() => {
      const combo = window.$('#databaseCombo').data('kendoComboBox');
      return combo ? combo.dataSource.data().map((item) => item.name) : [];
    });
    return comboItems;
  }).toContain('DICTDB');

  const payload = await (await request.get('/__requests')).json();
  expect(payload.requests.some((item) => item.path.includes('/metadata-pasoe.php') && item.path.includes('database-catalog'))).toBe(true);
  expect(payload.requests.some((item) => item.path.includes('/med/web/SursumDynamicQuery/metadata/database-catalog'))).toBe(false);
});

test('query wizard keeps selected IMA company and reloads databases through IMA endpoint', async ({ page, request }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');

  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#apiCompany').data('kendoComboBox');
    return combo ? combo.text() : '';
  })).toBe('MED');

  await request.post('/__reset');
  await page.evaluate(() => {
    const combo = window.$('#apiCompany').data('kendoComboBox');
    combo.value('empresa-ima');
    combo.trigger('change');
  });

  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#apiCompany').data('kendoComboBox');
    return {
      companyText: combo ? combo.text() : '',
      companyValue: combo ? combo.value() : '',
      selectedCompany: window.SursumContext.getCurrentCompany().id,
      apiBase: document.querySelector('#apiBaseUrl').value,
      databases: window.$('#databaseCombo').data('kendoComboBox').dataSource.data().map((item) => item.name)
    };
  })).toMatchObject({
    companyText: 'IMA',
    companyValue: 'empresa-ima',
    selectedCompany: 'empresa-ima',
    apiBase: 'http://127.0.0.1:18180/ima/web/SursumDynamicQuery',
    databases: expect.arrayContaining(['DICTDB'])
  });

  const payload = await (await request.get('/__requests')).json();
  expect(payload.requests.some((item) => item.path.includes('/metadata-pasoe.php') && item.path.includes('database-catalog'))).toBe(true);
  expect(payload.requests.some((item) => item.path.includes('/ima/web/SursumDynamicQuery/metadata/database-catalog'))).toBe(false);
});

test('query wizard shows table search window loading while first table fetch is running', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });
  await page.route('**/metadata-pasoe.php?**', async (route) => {
    const url = new URL(route.request().url());
    const path = url.searchParams.get('path') || '';
    if (path.startsWith('/metadata/tables?database=DICTDB')) {
      await new Promise((resolve) => setTimeout(resolve, 800));
    }
    await route.continue();
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');

  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
    localStorage.removeItem('sursumQueryWizardTableCache:http://127.0.0.1:18180/med/web/SursumDynamicQuery|empresa-med|DICTDB');
  });

  await page.locator('#openTableSearch').click();
  await expect(page.locator('.k-window-title').filter({ hasText: 'Buscar tabela em DICTDB' })).toBeVisible();
  await expect(page.locator('#tableSearchWindow .k-loading-mask')).toBeVisible();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await expect(page.locator('#tableSearchWindow .k-loading-mask')).toHaveCount(0);
});

test('query wizard keeps table cache until user forces refresh', async ({ page, request }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
    localStorage.setItem('sursumQueryWizardTableCache:http://127.0.0.1:18180/med/web/SursumDynamicQuery|empresa-med|DICTDB', JSON.stringify({
      savedAt: 1,
      rows: [{ name: 'CachedTable', label: 'Tabela em cache', dumpName: '', database: 'DICTDB' }]
    }));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await request.post('/__reset');

  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('CachedTable');
  let payload = await (await request.get('/__requests')).json();
  expect(payload.requests.some((item) => item.path.includes('/metadata/tables'))).toBe(false);

  await page.locator('#refreshTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  payload = await (await request.get('/__requests')).json();
  expect(payload.requests.some((item) => decodeURIComponent(item.path).includes('/metadata/tables'))).toBe(true);
});

test('query wizard shows loading while table fields and indexes are loaded', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });
  await page.route('**/metadata-pasoe.php?**', async (route) => {
    const url = new URL(route.request().url());
    const path = url.searchParams.get('path') || '';
    if (path.includes('/metadata/tables/Customer/fields')) {
      await new Promise((resolve) => setTimeout(resolve, 800));
    }
    await route.continue();
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });

  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();

  await expect(page.locator("[data-step-panel='2'] > .k-loading-mask")).toBeVisible();
  await expect(page.locator('#indexFilterTabs')).toContainText('CustNum');
  await expect(page.locator("[data-step-panel='2'] > .k-loading-mask")).toHaveCount(0);
});

test('query wizard step 3 keeps mobile pager and controls inside the viewport', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();
  await expect(page.locator('#indexFilterTabs')).toContainText('CustNum');
  await page.locator(".step-item[data-step='3']").click();

  const layout = await page.evaluate(() => {
    const info = document.querySelector('#dataGrid .k-pager-info').getBoundingClientRect();
    const firstButton = document.querySelector('#dataGrid .k-pager-first').getBoundingClientRect();
    const grid = document.querySelector('#dataGrid').getBoundingClientRect();
    const runButton = document.querySelector('#runQuery').getBoundingClientRect();
    return {
      scrollWidth: document.documentElement.scrollWidth,
      viewportWidth: window.innerWidth,
      infoTop: info.top,
      firstButtonBottom: firstButton.bottom,
      infoRight: info.right,
      gridRight: grid.right,
      runButtonRight: runButton.right
    };
  });

  expect(layout.scrollWidth).toBeLessThanOrEqual(layout.viewportWidth);
  expect(layout.infoTop).toBeGreaterThanOrEqual(layout.firstButtonBottom);
  expect(layout.infoRight).toBeLessThanOrEqual(layout.gridRight);
  expect(layout.runButtonRight).toBeLessThanOrEqual(layout.viewportWidth);
});

test('query wizard step 2 keeps index filters and tabs inside mobile viewport', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();
  await expect(page.locator('#indexFilterTabs')).toContainText('CustNum');

  const layout = await page.evaluate(() => {
    const panel = document.querySelector("[data-step-panel='2']").getBoundingClientRect();
    const nav = document.querySelector('#indexFilterTabs .manual-tab-nav').getBoundingClientRect();
    const item = document.querySelector('#indexFilterTabs .index-filter-item').getBoundingClientRect();
    const operator = document.querySelector('#indexFilterTabs .index-filter-operator').closest('span, input').getBoundingClientRect();
    const addButton = document.querySelector('#indexFilterTabs .add-index-filter').getBoundingClientRect();
    const windowEl = document.querySelector('#tableSearchWindow').closest('.k-window');
    const windowStyle = windowEl ? window.getComputedStyle(windowEl) : null;
    return {
      scrollWidth: document.documentElement.scrollWidth,
      viewportWidth: window.innerWidth,
      panelRight: panel.right,
      navRight: nav.right,
      itemRight: item.right,
      operatorRight: operator.right,
      addButtonRight: addButton.right,
      operatorWidget: document.querySelector('#indexFilterTabs .index-filter-operator.k-dropdownlist') !== null,
      searchWindowVisible: windowStyle && windowStyle.display !== 'none' && windowStyle.visibility !== 'hidden'
    };
  });

  expect(layout.scrollWidth).toBeLessThanOrEqual(layout.viewportWidth);
  expect(layout.navRight).toBeLessThanOrEqual(layout.panelRight);
  expect(layout.itemRight).toBeLessThanOrEqual(layout.panelRight);
  expect(layout.operatorRight).toBeLessThanOrEqual(layout.panelRight);
  expect(layout.addButtonRight).toBeLessThanOrEqual(layout.panelRight);
  expect(layout.operatorWidget).toBe(true);
  expect(layout.searchWindowVisible).toBe(false);
});

test('query wizard adds an index filter when Add is clicked', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();
  const firstFilter = page.locator('#indexFilterTabs .index-filter-item').first();
  await expect(firstFilter.locator('.index-filter-operator.k-dropdownlist')).toBeVisible();

  await firstFilter.locator('input.index-filter-value').fill('1');
  await firstFilter.locator('.add-index-filter').click();

  await expect(page.locator('#filtersGrid')).toContainText('CustNum');
  await expect(page.locator('#filtersGrid')).toContainText('1');
  await expect(page.locator('#footerStatus')).toContainText('Filtro adicionado');
});

test('query wizard adds integer index filter for espec pp-container nr-container', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('espec');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('espec');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('pp-container');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'pp-container' }).dblclick();
  await page.locator('#indexFilterTabs .manual-tab').filter({ hasText: 'nr-container' }).click();

  const containerFilter = page.locator('#indexFilterTabs .index-filter-item').filter({ hasText: 'nr-container' }).first();
  await expect(containerFilter.locator('.index-filter-operator.k-dropdownlist')).toBeVisible();
  await containerFilter.locator('input.index-filter-value').first().fill('1650');
  await containerFilter.locator('.add-index-filter').click();

  await expect(containerFilter.locator('.index-filter-error')).toBeEmpty();
  await expect(page.locator('#filtersGrid')).toContainText('nr-container');
  await expect(page.locator('#filtersGrid')).toContainText('1650');
  await expect(page.locator('#footerStatus')).toContainText('Filtro adicionado');
});

test('query wizard record form lists OF relations for pp-container without field list expressions', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('espec');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('espec');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('pp-container');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'pp-container' }).dblclick();
  await expect(page.locator('#indexFilterTabs')).toContainText('nr-container');
  await page.locator(".step-item[data-step='3']").click();
  await page.locator('#runQuery').click();
  await expect(page.locator('#dataGrid')).toContainText('Container E2E');
  await expect(page.locator('#dataGrid')).toContainText('7788 - Pedido exportacao');
  await expect(page.locator('#dataGrid')).toContainText('Sim');
  await page.locator('#dataGrid tbody tr').first().dblclick();

  await expect(page.locator('#recordWindow')).toBeVisible();
  await expect(page.locator('#recordForm .record-form-tab').first()).toContainText('Chave primaria');
  await expect(page.locator('#recordForm .record-form-panel').first()).toContainText('nr-container');
  await expect(page.locator('#recordForm .record-form-panel').first()).not.toContainText('nr-pedido');
  await expect(page.locator('#recordForm .record-form-tab').filter({ hasText: 'Chave primaria' })).toBeVisible();
  await expect(page.locator('#recordForm .record-form-tab').filter({ hasText: 'Numericos' })).toBeVisible();
  await expect(page.locator('#recordForm .record-form-tab').filter({ hasText: 'Logicos' })).toBeVisible();
  await expect(page.locator('#recordForm .record-form-tab').filter({ hasText: 'Texto' })).toBeVisible();
  await expect.poll(async () => page.evaluate(() => {
    return Array.from(document.querySelectorAll('#recordForm .record-form-panel.active .record-field')).every((field) => {
      const top = Math.round(field.getBoundingClientRect().top);
      const fieldsInSameRow = Array.from(document.querySelectorAll('#recordForm .record-form-panel.active .record-field'))
        .filter((candidate) => Math.round(candidate.getBoundingClientRect().top) === top);
      return fieldsInSameRow.length <= 2;
    });
  })).toBe(true);
  await expect(page.locator('#recordForm')).toContainText('nr-pedido');
  await expect.poll(async () => page.evaluate(() => {
    return Array.from(document.querySelectorAll('#recordForm input')).map((input) => input.value);
  })).toContain('7788 - Pedido exportacao');
  await expect.poll(async () => page.evaluate(() => {
    return Array.from(document.querySelectorAll('#recordForm input')).map((input) => input.value);
  })).toContain('Sim');
  await expect.poll(async () => page.evaluate(() => {
    const drop = window.$('#recordJoinTable').data('kendoDropDownList');
    if (!drop) return [];
    return drop.dataSource.data().map((item) => item.text);
  })).toEqual(expect.arrayContaining([
    expect.stringContaining('espec.pp-container-item'),
    expect.stringContaining('espec.pp-pedido')
  ]));
});

test('query wizard separates fetch amount from grid page size', async ({ page, request }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();
  await expect(page.locator('#indexFilterTabs')).toContainText('CustNum');
  await page.locator(".step-item[data-step='3']").click();
  await page.evaluate(() => {
    window.$('#queryPageSize').data('kendoNumericTextBox').value(500);
    window.$('#queryGridPageSize').data('kendoNumericTextBox').value(25);
  });
  await request.post('/__reset');
  await page.locator('#runQuery').click();

  await expect.poll(async () => page.evaluate(() => {
    const grid = window.$('#dataGrid').data('kendoGrid');
    return grid ? grid.dataSource.pageSize() : 0;
  })).toBe(25);

  const payload = await (await request.get('/__requests')).json();
  const queryRequest = payload.requests.find((item) => item.method === 'POST' && item.path.endsWith('/query'));
  expect(queryRequest.body.pageSize).toBe(500);
});

test('query wizard accepts a typed table without database when the table exists in only one database', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');

  await page.locator('#selectedTable').fill('Customer');
  await page.locator('#selectedTable').press('Enter');

  await expect(page.locator('#tableSelectedInfo')).toContainText('DICTDB.Customer');
  await expect(page.locator('#indexFilterTabs')).toContainText('CustNum');
  await expect(page.locator("[data-step-panel='2']")).toHaveClass(/is-active/);
});

test('query wizard requires database for a typed table found in more than one database', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });
  await page.route('**/metadata-pasoe.php?**', async (route) => {
    const url = new URL(route.request().url());
    const path = url.searchParams.get('path') || '';
    if (path === '/metadata/tables?database=espec') {
      await route.fulfill({
        status: 200,
        contentType: 'application/json; charset=utf-8',
        body: JSON.stringify({
          success: true,
          data: [
            { name: 'Customer', label: 'Customer', database: 'espec' },
            { name: 'pp-container', label: 'pp-container', database: 'espec' }
          ]
        })
      });
      return;
    }
    await route.continue();
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('espec');

  await page.locator('#selectedTable').fill('Customer');
  await page.locator('#selectedTable').press('Enter');

  await expect(page.locator('#footerStatus')).toContainText('Informe o banco');
  await expect(page.locator('#tableSelectedInfo')).toContainText('Selecione uma tabela');
});

test('query wizard shows an inline message when adding an empty index filter', async ({ page }) => {
  await page.addInitScript((payload) => {
    localStorage.clear();
    localStorage.setItem('sursumContextV4', JSON.stringify(payload.data));
  }, contextPayload());
  await page.route('**/context-store.php', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json; charset=utf-8',
      body: JSON.stringify(contextPayload())
    });
  });

  await page.goto('/query-wizard-3steps.html');
  await expect.poll(async () => page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    return combo ? combo.dataSource.data().map((item) => item.name) : [];
  })).toContain('DICTDB');
  await page.evaluate(() => {
    const combo = window.$('#databaseCombo').data('kendoComboBox');
    combo.value('DICTDB');
    combo.trigger('change');
  });
  await page.locator('#openTableSearch').click();
  await expect(page.locator('#tableSearchGrid')).toContainText('Customer');
  await page.locator('#tableSearchGrid tbody tr').filter({ hasText: 'Customer' }).dblclick();

  const firstFilter = page.locator('#indexFilterTabs .index-filter-item').first();
  await expect(firstFilter.locator('.index-filter-operator.k-dropdownlist')).toBeVisible();
  await firstFilter.locator('.add-index-filter').click();

  await expect(firstFilter.locator('.index-filter-error')).toContainText('Informe um valor valido');
  await expect(firstFilter).toHaveClass(/has-error/);
});
