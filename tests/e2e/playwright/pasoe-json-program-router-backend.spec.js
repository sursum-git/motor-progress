const { test, expect, request } = require('@playwright/test');
const base = (process.env.SURSUM_JSON_PROGRAM_BASE_URL || '').replace(/\/+$/, '');
test.describe('PASOE backend JSON program router', () => {
  test.skip(!base, 'Set SURSUM_JSON_PROGRAM_BASE_URL after deploying the separate handler and echo route.');
  let api;
  test.beforeAll(async () => { api = await request.newContext({ ignoreHTTPSErrors: true }); });
  test.afterAll(async () => { if (api) await api.dispose(); });
  test('POST sends and returns the entire business JSON', async () => {
    const body = { pedido: 123, program: 'ordinary-data', parameters: { id: 7 }, items: [1, 2], success: false, texto: 'ação' };
    const response = await api.post(base + '/SursumPrograms/echo', { data: body });
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual(body);
  });
  test('GET preserves strings, UTF-8 and repeated keys', async () => {
    const response = await api.get(base + '/SursumPrograms/echo?pedido=00123&texto=a%C3%A7%C3%A3o&tag=a&tag=b');
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual({ pedido: '00123', texto: 'ação', tag: ['a', 'b'] });
  });
  test('unsupported route method returns 405 before validating body', async () => {
    const response = await api.patch(base + '/SursumPrograms/echo', { data: 'not-json' });
    expect(response.status()).toBe(405);
    expect(response.headers().allow).toContain('POST');
    expect((await response.json()).error.code).toBe('METHOD_NOT_ALLOWED');
  });
  test('unknown route returns 404', async () => {
    const response = await api.post(base + '/SursumPrograms/not-registered', { data: {} });
    expect(response.status()).toBe(404);
  });
  test('JSON array is not accepted as JsonObject input', async () => {
    const response = await api.post(base + '/SursumPrograms/echo', { data: [] });
    expect(response.status()).toBe(400);
  });
  test('invalid UTF-8 query is rejected', async () => {
    const response = await api.get(base + '/SursumPrograms/echo?texto=%C0%AF');
    expect(response.status()).toBe(400);
    expect((await response.json()).error.code).toBe('INVALID_QUERY_STRING');
  });
  test('percent escapes decode once and literal plus remains plus', async () => {
    const response = await api.get(base + '/SursumPrograms/echo?texto=%2526%2B+');
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual({ texto: '%26+ ' });
  });
  test('OPTIONS returns Allow with no body', async () => {
    const response = await api.fetch(base + '/SursumPrograms/echo', { method: 'OPTIONS' });
    expect(response.status()).toBe(204);
    expect(response.headers().allow).toContain('GET');
    expect(await response.text()).toBe('');
  });
});
