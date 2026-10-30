const { test, expect, request } = require('@playwright/test');

const base = (process.env.SURSUM_JSON_PROGRAM_BASE_URL || '').replace(/\/+$/, '');
const decimalValue = (value) => Number(String(value).replace(',', '.'));


test.describe('Consulta de pedidos gravando wp via PASOE', () => {
  test.skip(!base, 'Defina SURSUM_JSON_PROGRAM_BASE_URL para executar no PASOE.');

  let api;

  test.beforeAll(async () => {
    api = await request.newContext({ ignoreHTTPSErrors: true, timeout: 180000 });
  });

  test.afterAll(async () => {
    if (api) await api.dispose();
  });

  test('cria wp e wp_ped_venda para a consulta executada', async () => {
    const pagina = 'codex-consulta-pedidos-wp';
    const filtro = `codex-${Date.now()}`;
    const seedResponse = await api.post(base + '/SursumPrograms/consulta-pedidos-venda', {
      data: { dtImplantIni: '2026-04-01', dtImplantFim: '2026-09-24' }
    });
    expect(seedResponse.status()).toBe(200);
    const seed = await seedResponse.json();
    expect(seed.success, JSON.stringify(seed)).toBe(true);
    expect(seed.total).toBeGreaterThan(0);
    const pedido = seed['tt-dados'][0]['nr-pedido'];

    const response = await api.post(base + '/SursumPrograms/consulta-pedidos-venda-wp', {
      data: {
        dtImplantIni: '2026-04-01',
        dtImplantFim: '2026-09-24',
        nrPedidoIni: pedido,
        nrPedidoFim: pedido,
        login: 'codex',
        pagina,
        filtro
      }
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success, JSON.stringify(body)).toBe(true);
    expect(String(body.codWp || '')).toMatch(/^\d+(\.\d+)?$/);
    expect(body.total).toBeGreaterThan(0);
    expect(body.inserted).toBe(body.total);
    expect(typeof body.wpPedVendaInsertMs).toBe('number');
    expect(body.wpPedVendaInsertMs).toBeGreaterThanOrEqual(0);
    expect(body.timing).toBeTruthy();
    expect(typeof body.timing.wpPedVendaInsertMs).toBe('number');
    expect(body.timing.wpPedVendaInsertMs).toBeGreaterThanOrEqual(0);
    expect(body.wpPedVendaBatchSize).toBeUndefined();
    expect(body.wpPedVendaBatches).toBeUndefined();
    expect(body.timing.wpPedVendaBatchSize).toBeUndefined();
    expect(body.timing.wpPedVendaBatches).toBeUndefined();

    const wp = await dynamicQuery('espec', 'wp', ['cod_wp', 'login', 'pagina', 'filtro'], [
      { sourceAlias: 'wp', field: 'cod_wp', operator: '=', value: String(body.codWp) }
    ]);
    expect(wp).toHaveLength(1);
    expect(wp[0].login).toBe('codex');
    expect(wp[0].pagina).toBe(pagina);
    expect(wp[0].filtro).toBe(filtro);

    const itens = await dynamicQuery('espec', 'wp_ped_venda', ['cod_wp', 'nr_pedcli', 'cod_estabel'], [
      { sourceAlias: 'wp_ped_venda', field: 'cod_wp', operator: '=', value: String(body.codWp) }
    ], 200);
    expect(itens).toHaveLength(body.inserted);
    for (const item of itens) {
      expect(String(item.cod_wp)).toBe(String(body.codWp));
      expect(Number(item.cod_estabel)).not.toBe(0);
    }
  });

  test('usuario representante grava somente pedidos do seu representante principal na wp_ped_venda', async () => {
    const rep = await representativeWithOrders();
    test.skip(!rep, 'Nao ha usuario representante com pedidos no periodo de teste.');

    const response = await api.post(base + '/SursumPrograms/consulta-pedidos-venda-wp', {
      data: {
        dtImplantIni: '2026-04-01',
        dtImplantFim: '2026-10-03',
        login: rep.login,
        pagina: 'codex-representante-wp',
        filtro: `codex-representante-${Date.now()}`,
        represIni: '',
        represFim: 'zzzzzzzzzzzzz'
      }
    });
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success, JSON.stringify(body)).toBe(true);
    expect(body.inserted).toBeGreaterThan(0);

    const itens = await dynamicQuery('espec', 'wp_ped_venda', ['cod_wp', 'no_ab_reppri'], [
      { sourceAlias: 'wp_ped_venda', field: 'cod_wp', operator: '=', value: String(body.codWp) }
    ], Math.max(body.inserted, 20));
    expect(itens).toHaveLength(body.inserted);
    for (const item of itens) {
      expect(String(item.no_ab_reppri).toUpperCase()).toBe(rep.nomeAbrev.toUpperCase());
    }
  });
  test('grava valores calculados de pedido cancelado na wp_ped_venda', async () => {
    const sourceResponse = await api.post(base + '/SursumPrograms/consulta-pedidos-venda', {
      data: {
        dtImplantIni: '2026-04-01',
        dtImplantFim: '2026-10-03',
        nrPedidoIni: 382460,
        nrPedidoFim: 382460
      }
    });
    expect(sourceResponse.status()).toBe(200);
    const sourceBody = await sourceResponse.json();
    expect(sourceBody.success, JSON.stringify(sourceBody)).toBe(true);
    expect(sourceBody.total).toBe(1);
    const source = sourceBody['tt-dados'][0];

    const response = await api.post(base + '/SursumPrograms/consulta-pedidos-venda-wp', {
      data: {
        dtImplantIni: '2026-04-01',
        dtImplantFim: '2026-10-03',
        nrPedidoIni: 382460,
        nrPedidoFim: 382460,
        login: 'codex',
        pagina: 'consulta-pedidos-venda-wp',
        filtro: `codex-cancelado-${Date.now()}`
      }
    });
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success, JSON.stringify(body)).toBe(true);
    expect(body.inserted).toBe(1);

    const itens = await dynamicQuery('espec', 'wp_ped_venda', ['cod_wp', 'nr_pedcli', 'vl_liquido', 'vl_desconto', 'vl_bruto'], [
      { sourceAlias: 'wp_ped_venda', field: 'cod_wp', operator: '=', value: String(body.codWp) }
    ], 10);
    expect(itens).toHaveLength(1);
    expect(String(itens[0].nr_pedcli)).toBe(String(source['nr-pedcli']));
    expect(decimalValue(itens[0].vl_liquido)).toBeCloseTo(Number(source['vl-liquido']), 2);
    expect(decimalValue(itens[0].vl_desconto)).toBeCloseTo(Number(source['vl-desconto']), 2);
    expect(decimalValue(itens[0].vl_bruto)).toBeCloseTo(Number(source['vl-bruto']), 2);
  });


  async function representativeWithOrders() {
    const users = await dynamicQuery('espec', 'user-web', ['Login', 'tp-usuario', 'nome-ab-cli'], [
      { sourceAlias: 'user-web', field: 'tp-usuario', operator: '=', value: '2' }
    ], 80);
    for (const user of users.filter((row) => row.Login)) {
      const response = await api.post(base + '/SursumPrograms/consulta-pedidos-venda', { data: {
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
  async function dynamicQuery(defaultBanco, table, fields, filters, pageSize = 20) {
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
});








