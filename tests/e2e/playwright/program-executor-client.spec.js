const { test, expect } = require('@playwright/test');

test.beforeEach(async ({ request }) => {
  await request.post('/__reset');
});

test('program executor client posts JsonObject parameters to PASOE program executor', async ({ page }) => {
  const calls = [];
  await page.route('**/pasoe-proxy.php?target=*', async (route) => {
    const url = new URL(route.request().url());
    const target = decodeURIComponent(url.searchParams.get('target') || '');
    if (!target.endsWith('/program/execute')) {
      await route.continue();
      return;
    }
    calls.push({
      target,
      body: route.request().postDataJSON()
    });
    await route.fulfill({
      json: {
        success: true,
        program: 'echo-json',
        parameters: route.request().postDataJSON().parameters
      }
    });
  });

  await page.goto('/program-executor-client.html');
  await page.locator('#programInput').fill('echo-json');
  await page.locator('#parametersInput').fill(JSON.stringify({ nr_container: 1650, texto: 'teste' }, null, 2));
  await page.locator('#runButton').click();

  await expect(page.locator('#statusBox')).toContainText('Programa executado');
  await expect(page.locator('#requestBox')).toContainText('"program": "echo-json"');
  await expect(page.locator('#responseBox')).toContainText('"nr_container": 1650');
  expect(calls).toHaveLength(1);
  expect(calls[0].target).toContain('/program/execute');
  expect(calls[0].body).toEqual({
    program: 'echo-json',
    parameters: {
      nr_container: 1650,
      texto: 'teste'
    }
  });
});

test('main menu includes the manual Progress program executor example', async ({ page }) => {
  await page.goto('/index.html');

  await expect(page.locator('#menuTree')).toContainText('Executor de programas Progress');
  await page.locator('#menuTree').getByText('Executor de programas Progress').click();
  await expect(page.locator('#currentTitle')).toContainText('Executor de programas Progress');
});

for (const method of ['GET', 'PUT', 'PATCH', 'DELETE']) {
  test(`program executor sends parameters using ${method}`, async ({ page }) => {
    const calls = [];
    await page.route('**/pasoe-proxy.php?target=*', async route => {
      calls.push(route.request());
      await route.fulfill({ json: { success: true } });
    });
    await page.goto(`/program-executor-client.html?method=${method}`);
    await page.locator('#parametersInput').fill(JSON.stringify({ texto: 'ação & + ?', nested: { id: 7 } }));
    await page.locator('#runButton').click();
    await expect(page.locator('#statusBox')).toContainText('Programa executado');
    expect(calls).toHaveLength(1);
    expect(calls[0].method()).toBe(method);
    if (method === 'GET') {
      const target = new URL(new URL(calls[0].url()).searchParams.get('target'));
      expect(target.searchParams.get('program')).toBe('echo-json');
      expect(JSON.parse(target.searchParams.get('parameters'))).toEqual({ texto: 'ação & + ?', nested: { id: 7 } });
      expect(calls[0].postData()).toBeNull();
    } else {
      expect(calls[0].postDataJSON()).toEqual({ program: 'echo-json', parameters: { texto: 'ação & + ?', nested: { id: 7 } } });
    }
  });
}

for (const method of ['PUT', 'PATCH', 'DELETE']) {
  test(`program executor selection sends ${method} and reports rejection`, async ({ page }) => {
    let actualMethod;
    await page.route('**/pasoe-proxy.php?target=*', async route => {
      actualMethod = route.request().method();
      await route.fulfill({ status: 405, headers: { Allow: 'POST' }, json: { success: false, error: { code: 'METHOD_NOT_ALLOWED' } } });
    });
    await page.goto('/program-executor-client.html');
    await page.locator('#methodInput').selectOption(method);
    await page.locator('#runButton').click();
    await expect(page.locator('#statusBox')).toContainText('HTTP 405');
    expect(actualMethod).toBe(method);
    await expect(page.locator('#responseBox')).toContainText('METHOD_NOT_ALLOWED');
  });
}
