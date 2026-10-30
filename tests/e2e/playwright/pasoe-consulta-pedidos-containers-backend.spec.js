const { test, expect, request } = require('@playwright/test');
const base = (process.env.SURSUM_JSON_PROGRAM_BASE_URL || '').replace(/\/+$/, '');
const path = '/SursumPrograms/consulta-pedidos-venda';
const period = { dtImplantIni: '2026-04-01', dtImplantFim: '2026-09-24' };
const sorted = rows => rows.map(row => JSON.stringify(row)).sort();
test.describe('Lista de containers via rota PASOE', () => {
  test.skip(!base, 'Informe SURSUM_JSON_PROGRAM_BASE_URL para validar no PASOE');
  let api, baseline, containers;
  async function call(filters = {}) {
    const response = await api.post(base + path, { data: { ...period, ...filters } });
    expect(response.status()).toBe(200);
    return response.json();
  }
  test.beforeAll(async () => {
    api = await request.newContext({ ignoreHTTPSErrors: true, timeout: 180000 });
    const result = await call();
    expect(result.success).toBe(true);
    baseline = result['tt-dados'];
    containers = [...new Set(baseline.map(row => row['nr-container']).filter(n => Number.isInteger(n) && n > 0))].slice(0, 2);
    expect(containers.length, 'O cenario precisa de dois containers reais para comprovar a lista').toBe(2);
  });
  test.afterAll(async () => { if (api) await api.dispose(); });
  test('lista separada por virgula retorna somente os containers informados', async () => {
    const result = await call({ lista_containers: containers.join(',') });
    expect(result.success).toBe(true);
    const expected = baseline.filter(row => containers.includes(row['nr-container']));
    expect(expected.length).toBeGreaterThan(0);
    expect(result.total).toBe(expected.length);
    expect(sorted(result['tt-dados'])).toEqual(sorted(expected));
  });
  test('combina containers com os demais filtros', async () => {
    const row = baseline.find(r => r['nr-container'] === containers[0]);
    const result = await call({ lista_containers: containers.join(','), nrPedidoIni: row['nr-pedido'], nrPedidoFim: row['nr-pedido'], clienteIni: row['cod-emitente'], clienteFim: row['cod-emitente'] });
    expect(result.success).toBe(true);
    const expected = baseline.filter(r => containers.includes(r['nr-container']) && r['nr-pedido'] === row['nr-pedido'] && r['cod-emitente'] === row['cod-emitente']);
    expect(expected.length).toBeGreaterThan(0);
    expect(sorted(result['tt-dados'])).toEqual(sorted(expected));
  });
  test('espacos e containers repetidos nao duplicam registros', async () => {
    const result = await call({ lista_containers: ` ${containers[0]}, ${containers[1]}, ${containers[0]} ` });
    expect(result.success).toBe(true);
    expect(sorted(result['tt-dados'])).toEqual(sorted(baseline.filter(row => containers.includes(row['nr-container']))));
  });
  test('lista em branco preserva a consulta sem filtro de container', async () => {
    for (const value of ['', '   ']) {
      const result = await call({ lista_containers: value });
      expect(result.success).toBe(true);
      expect(sorted(result['tt-dados'])).toEqual(sorted(baseline));
    }
  });
  test('container sem resultados nao volta para a consulta geral', async () => {
    let absent = 2147483647;
    const present = new Set(baseline.map(row => row['nr-container']));
    while (present.has(absent)) absent--;
    const result = await call({ lista_containers: String(absent) });
    expect(result.success).toBe(true);
    expect(result.total).toBe(0);
    expect(result['tt-dados']).toEqual([]);
  });
  for (const [name, value] of [
    ['item nao numerico', '1,abc'], ['item vazio', '1,,2'],
    ['numero negativo', '-1'], ['numero fracionario', '1.5'],
    ['numero fora do limite', '2147483648'], ['array', [1, 2]],
    ['null', null], ['numero no lugar de texto', 1]
  ]) test(`rejeita ${name}`, async () => {
    const result = await call({ lista_containers: value });
    expect(result.success).toBe(false);
    expect(result.error).toContain('lista_containers');
    expect(result['tt-dados']).toEqual([]);
  });
});
