const { test, expect } = require('@playwright/test');

const apiBase = 'http://127.0.0.1:18180/web/SursumDynamicQuery';

const sampleQuery = {
  execution: 'sync',
  page: 1,
  pageSize: 25,
  sources: [{ nome: 'Customer', alias: 'customer', banco: 'DICTDB' }],
  select: [{ sourceAlias: 'customer', field: 'CustNum', outputAlias: 'codigo' }],
  filters: [],
  orderBy: [],
  externalFilters: [
    { name: 'pedido', source: 'querystring', sourceAlias: 'customer', field: 'CustNum', operator: '=', required: false }
  ]
};

test.beforeEach(async ({ request }) => {
  await request.post('http://127.0.0.1:18180/__reset');
});

test('direct dynamic query keeps response contract and records PASOE execution metadata', async ({ request }) => {
  const run = await request.post(`${apiBase}/query`, {
    data: {
      execution: 'sync',
      page: 1,
      pageSize: 10,
      sources: [{ nome: 'pp-container', alias: 'pc', banco: 'espec' }],
      select: [{ sourceAlias: 'pc', field: 'nr-container' }]
    }
  });
  const result = await run.json();

  expect(result).toMatchObject({
    success: true,
    directQuery: true,
    recordsReturned: 1
  });
  expect(result.executionId).toMatch(/^EXE-/);

  const detail = await (await request.get(`${apiBase}/executions/${result.executionId}`)).json();
  expect(detail).toMatchObject({
    success: true,
    executionId: result.executionId,
    executionType: 'query',
    status: 'completed',
    pasoePid: 'mock-pid-18180',
    pasoeAgent: 'mock-agent'
  });
});

test('saved dynamic query still applies external filters and is listed in execution log', async ({ request }) => {
  const save = await request.post(`${apiBase}/query-store`, {
    data: { code: 'clientes-com-filtro', status: 'ready', query: sampleQuery }
  });
  await expect(save).toBeOK();

  const run = await request.post(`${apiBase}/query`, {
    data: {
      code: 'clientes-com-filtro',
      parameters: { querystring: { pedido: '123' } }
    }
  });
  const result = await run.json();

  expect(result).toMatchObject({
    success: true,
    code: 'clientes-com-filtro',
    appliedFilters: [{ sourceAlias: 'customer', field: 'CustNum', operator: '=', value: '123' }]
  });
  expect(result.executionId).toMatch(/^EXE-/);

  const list = await (await request.get(`${apiBase}/executions?status=completed`)).json();
  expect(list.success).toBe(true);
  expect(list.data.some((item) => item.executionId === result.executionId && item.queryCode === 'clientes-com-filtro')).toBe(true);
});

test('async dynamic query keeps job status linked to execution metadata', async ({ request }) => {
  const run = await request.post(`${apiBase}/query`, {
    data: {
      execution: 'async',
      page: 1,
      pageSize: 10000,
      sources: [{ nome: 'Customer', alias: 'customer', banco: 'DICTDB' }],
      select: [{ sourceAlias: 'customer', field: 'CustNum' }],
      filters: [],
      orderBy: []
    }
  });
  const result = await run.json();

  expect(result).toMatchObject({
    success: true,
    execution: 'async',
    status: 'queued'
  });
  expect(result.jobId).toMatch(/^JOB-/);
  expect(result.executionId).toMatch(/^EXE-/);

  const job = await (await request.get(`${apiBase}/jobs/${result.jobId}`)).json();
  expect(job).toMatchObject({
    success: true,
    jobId: result.jobId,
    executionId: result.executionId,
    status: 'queued'
  });

  const detail = await (await request.get(`${apiBase}/executions/${result.executionId}`)).json();
  expect(detail).toMatchObject({
    success: true,
    executionId: result.executionId,
    jobId: result.jobId,
    status: 'queued'
  });
});

test('program executor returns original payload and records kill request audit state', async ({ request }) => {
  const run = await request.post(`${apiBase}/program/execute`, {
    data: {
      program: 'echo-json',
      parameters: { nr_container: 1650, texto: 'teste' }
    }
  });
  const result = await run.json();

  expect(result).toMatchObject({
    success: true,
    program: 'echo-json',
    parameters: { nr_container: 1650, texto: 'teste' }
  });
  expect(result.executionId).toMatch(/^EXE-/);

  const kill = await request.post(`${apiBase}/executions/${result.executionId}/kill-request`, {
    data: { requestedBy: 'admin-e2e', reason: 'teste de auditoria' }
  });
  const killed = await kill.json();
  expect(killed).toMatchObject({
    success: true,
    executionId: result.executionId,
    status: 'killRequested',
    killRequestedBy: 'admin-e2e',
    killReason: 'teste de auditoria'
  });
});
