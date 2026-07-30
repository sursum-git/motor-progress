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
