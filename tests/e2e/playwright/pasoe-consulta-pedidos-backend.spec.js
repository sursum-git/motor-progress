const { test, expect, request } = require('@playwright/test');
const base = (process.env.SURSUM_JSON_PROGRAM_BASE_URL || '').replace(/\/+$/, '');
test.describe('Consulta de pedidos pela rota PASOE', () => {
  test.skip(!base, 'Defina SURSUM_JSON_PROGRAM_BASE_URL para executar no PASOE.');
  let api;
  test.beforeAll(async () => { api = await request.newContext({ ignoreHTTPSErrors: true, timeout: 180000 }); });
  test.afterAll(async () => { if (api) await api.dispose(); });
  const path = '/SursumPrograms/consulta-pedidos-venda';
  async function dynamicQuery(defaultBanco, table, fields, filters, pageSize = 50) {
    const response = await api.post(base + '/SursumDynamicQuery/query', {
      data: {
        execution: 'sync',
        page: 1,
        pageSize,
        defaultBanco,
        sources: [{ nome: table, alias: table, banco: defaultBanco, campos: fields.join(',') }],
        select: fields.map((field) => ({ sourceAlias: table, field, outputAlias: field })),
        filters
      }
    });
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success, JSON.stringify(body).slice(0, 500)).toBe(true);
    return body.data;
  }

  async function representativeWithOrders() {
    const users = await dynamicQuery('espec', 'user-web', ['Login', 'tp-usuario', 'nome-ab-cli'], [
      { sourceAlias: 'user-web', field: 'tp-usuario', operator: '=', value: '2' }
    ], 80);
    for (const user of users.filter((row) => row.Login)) {
      const response = await api.post(base + path, { data: {
        dtImplantIni: '2026-04-01',
        dtImplantFim: '2026-10-03',
        login: String(user.Login),
        represIni: '',
        represFim: 'zzzzzzzzzzzzz'
      }});
      expect(response.status()).toBe(200);
      const json = await response.json();
      expect(json.success, JSON.stringify(json)).toBe(true);
      if (json.total > 0) return { login: String(user.Login), nomeAbrev: String(user['nome-ab-cli'] || user.Login).trim() };
    }
    return null;
  }
  test('consulta real respeita os filtros e retorna tt-dados', async () => {
    const response = await api.post(base + path, { data: {
      dtImplantIni: '2026-04-01', dtImplantFim: '2026-09-24', nrPedidoIni: 252711, nrPedidoFim: 252711
    }});
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success, JSON.stringify(json)).toBe(true);
    expect(Array.isArray(json['tt-dados'])).toBe(true);
    expect(json.total).toBe(json['tt-dados'].length);
    for (const row of json['tt-dados']) {
      expect(row['nr-pedido']).toBe(252711);
      expect(row['dt-implant'] >= '2026-04-01' && row['dt-implant'] <= '2026-09-24').toBe(true);
    }
  });
  test('ignora bloqueioAprov vazio', async () => {
    const response = await api.post(base + path, { data: {
      dtImplantIni: '2026-09-12',
      dtImplantFim: '2026-10-02',
      nrPedidoIni: 0,
      nrPedidoFim: 9999999,
      estabIni: '5,505',
      estabFim: '5,505',
      bloqueioAprov: ''
    }});
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success, JSON.stringify(json)).toBe(true);
    expect(json.total).toBeGreaterThan(0);
    expect(Array.isArray(json['tt-dados'])).toBe(true);
  });
  test('ignora intervalo de cliente zerado', async () => {
    const seedResponse = await api.post(base + path, { data: {
      dtImplantIni: '2026-09-13',
      dtImplantFim: '2026-10-03',
      nrPedidoIni: 0,
      nrPedidoFim: 9999999,
      estabIni: '5,505',
      estabFim: '5,505'
    }});
    expect(seedResponse.status()).toBe(200);
    const seed = await seedResponse.json();
    expect(seed.success, JSON.stringify(seed)).toBe(true);
    expect(seed.total).toBeGreaterThan(0);
    const pedido = seed['tt-dados'][0]['nr-pedido'];

    const response = await api.post(base + path, { data: {
      dtImplantIni: '2026-09-13',
      dtImplantFim: '2026-10-03',
      nrPedidoIni: pedido,
      nrPedidoFim: pedido,
      estabIni: '5,505',
      estabFim: '5,505',
      clienteIni: '0',
      clienteFim: '0'
    }});
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success, JSON.stringify(json)).toBe(true);
    expect(json.total).toBeGreaterThan(0);
    expect(json['tt-dados'].some((row) => row['nr-pedido'] === pedido)).toBe(true);
  });
  test('usuario representante ve somente pedidos do seu representante principal', async () => {
    const rep = await representativeWithOrders();
    test.skip(!rep, 'Nao ha usuario representante com pedidos no periodo de teste.');

    const response = await api.post(base + path, { data: {
      dtImplantIni: '2026-04-01',
      dtImplantFim: '2026-10-03',
      login: rep.login,
      represIni: '',
      represFim: 'zzzzzzzzzzzzz'
    }});
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success, JSON.stringify(json)).toBe(true);
    expect(json.total).toBeGreaterThan(0);
    for (const row of json['tt-dados']) {
      expect(String(row['no-ab-reppri']).toUpperCase()).toBe(rep.nomeAbrev.toUpperCase());
    }
  });
  test('alimenta valores calculados para pedido cancelado', async () => {
    const response = await api.post(base + path, { data: {
      dtImplantIni: '2026-04-01',
      dtImplantFim: '2026-10-03',
      nrPedidoIni: 382460,
      nrPedidoFim: 382460
    }});
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success, JSON.stringify(json)).toBe(true);
    expect(json.total).toBe(1);
    const row = json['tt-dados'][0];
    expect(row['cod-sit-ped']).toBe(6);
    expect(Number(row['vl-liquido'])).toBeCloseTo(Number(row['vl-liq-ped']), 2);
    expect(Number(row['vl-desconto'])).toBeCloseTo(Number(row['val-desconto-total']), 2);
    expect(Number(row['vl-bruto'])).toBeCloseTo(Number(row['vl-liq-ped']) + Number(row['val-desconto-total']), 2);
  });
  for (const [name, data, error] of [
    ['intervalo de datas invertido', { dtImplantIni: '2026-09-24', dtImplantFim: '2026-04-01' }, 'dtImplantIni deve'],
    ['data inexistente', { dtImplantIni: '2026-02-30' }, 'Data invalida'],
    ['pedido sem o par', { nrPedidoIni: 252711 }, 'juntos'],
    ['pedido fracionario', { nrPedidoIni: 1.2, nrPedidoFim: 2 }, 'Pedido invalido'],
    ['filtro nulo', { dtImplantIni: null }, 'Filtro invalido']
  ]) test(name, async () => {
    const response = await api.post(base + path, { data });
    expect(response.status()).toBe(200);
    const json = await response.json();
    expect(json.success).toBe(false);
    expect(json.error).toContain(error);
    expect(json['tt-dados']).toEqual([]);
  });
});

