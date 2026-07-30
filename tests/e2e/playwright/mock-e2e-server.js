const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../../..');
const webRoot = path.join(root, 'web');
const store = new Map();
let relationRows = [];
let viewAsRows = [];
let metadataJobs = new Map();
const requests = [];
const PORT = Number(process.env.SURSUM_E2E_PORT || 18180);

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Accept, Origin'
  });
  res.end(body);
}

function error(code, message, details = '') {
  return { success: false, error: { code, message, details } };
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.setEncoding('utf8');
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => {
      if (!data) return resolve({});
      try { resolve(JSON.parse(data)); } catch (err) { reject(err); }
    });
    req.on('error', reject);
  });
}

function validCode(code) {
  return typeof code === 'string' && /^[A-Za-z0-9_.-]+$/.test(code);
}

function externalFilters(saved) {
  return Array.isArray(saved.externalFilters)
    ? saved.externalFilters
    : (saved.query && Array.isArray(saved.query.externalFilters) ? saved.query.externalFilters : []);
}

function bucket(parameters, source) {
  if (!parameters || typeof parameters !== 'object') return {};
  if (source === 'header') return parameters.header || parameters.headers || {};
  return parameters[source] || {};
}

function allParameterEntries(parameters) {
  const result = [];
  for (const source of ['querystring', 'header', 'headers', 'body']) {
    const normalized = source === 'headers' ? 'header' : source;
    const values = bucket(parameters, source);
    for (const name of Object.keys(values || {})) result.push({ source: normalized, name });
  }
  return result;
}

function applyParameters(saved, parameters) {
  const allowed = externalFilters(saved);
  const entries = allParameterEntries(parameters);
  if (entries.length && !allowed.length) {
    return error('EXTERNAL_FILTER_NOT_ALLOWED', 'Consulta salva nao aceita parametros externos', 'externalFilters ausente');
  }
  for (const entry of entries) {
    if (!allowed.some(f => (f.source === entry.source || (f.source === 'header' && entry.source === 'header')) && f.name === entry.name)) {
      return error('EXTERNAL_FILTER_NOT_ALLOWED', 'Parametro externo nao declarado em externalFilters', `${entry.source}.${entry.name}`);
    }
  }
  const runtimeFilters = [];
  for (const filter of allowed) {
    const source = filter.source === 'headers' ? 'header' : filter.source;
    const value = bucket(parameters, source)[filter.name];
    if ((value === undefined || value === null || value === '') && filter.required) {
      return error('REQUIRED_EXTERNAL_FILTER_MISSING', 'Filtro externo obrigatorio ausente', `${source}.${filter.name}`);
    }
    if (value !== undefined && value !== null && value !== '') {
      runtimeFilters.push({ sourceAlias: filter.sourceAlias, field: filter.field, operator: filter.operator || '=', value: String(value) });
    }
  }
  return { success: true, runtimeFilters };
}

function serveStatic(req, res, pathname) {
  const relative = pathname === '/' ? '/query-builder.html' : decodeURIComponent(pathname);
  const filePath = path.normalize(path.join(webRoot, relative));
  if (!filePath.startsWith(webRoot)) return sendJson(res, 403, error('FORBIDDEN', 'Forbidden'));
  fs.readFile(filePath, (err, data) => {
    if (err) return sendJson(res, 404, error('NOT_FOUND', 'Not found', relative));
    const ext = path.extname(filePath).toLowerCase();
    const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.png': 'image/png', '.svg': 'image/svg+xml' };
    res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
    res.end(data);
  });
}

async function handleApi(req, res, pathname, searchParams = new URL(req.url, `http://${req.headers.host}`).searchParams) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (req.method === 'OPTIONS') return sendJson(res, 200, { success: true });
  if (pathname === '/__health') return sendJson(res, 200, { ok: true });
  if (pathname === '/__requests') return sendJson(res, 200, { requests });
  if (pathname === '/__reset' && req.method === 'POST') { store.clear(); relationRows = []; viewAsRows = []; metadataJobs = new Map(); requests.length = 0; return sendJson(res, 200, { success: true }); }
  if (pathname === '/auth.php') return sendJson(res, 200, { authenticated: true, user: 'e2e' });
  if (pathname === '/context-store.php' && req.method === 'GET') {
    return sendJson(res, 200, {
      success: true,
      data: {
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
        physicalDatabases: [],
        aliases: [],
        selected: { clientId: 'cliente-a', environmentId: 'ambiente-a', companyId: 'empresa-a' }
      }
    });
  }
  if (pathname === '/relation-store.php' && req.method === 'GET') return sendJson(res, 200, { success: true, data: relationRows });
  if (pathname === '/relation-store.php' && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    relationRows = Array.isArray(body.relations) ? body.relations.map(item => Object.assign({ source: body.source || 'OF', updatedAt: '2026-06-12T17:00:00-03:00' }, item)) : [];
    return sendJson(res, 200, { success: true, data: relationRows });
  }
  if (pathname === '/metadata-store.php' && req.method === 'GET') {
    if (url.searchParams.get('resource') === 'job') {
      return sendJson(res, 200, { success: true, data: metadataJobs.get(url.searchParams.get('id')) || null });
    }
    const table = url.searchParams.get('table') || '';
    const data = table ? viewAsRows.filter(row => row.table === table) : viewAsRows;
    return sendJson(res, 200, { success: true, data });
  }
  if (pathname === '/metadata-store.php' && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    if (body.resource === 'job' && body.action === 'create') {
      const id = `job-${metadataJobs.size + 1}`;
      const job = {
        id,
        environmentId: body.environmentId || '',
        companyId: body.companyId || '',
        database: body.database || '',
        status: 'pending',
        totalTables: Array.isArray(body.tables) ? body.tables.length : 0,
        processedTables: 0,
        failedTables: 0,
        includeRelations: !!body.includeRelations,
        includeViewAs: !!body.includeViewAs,
        items: (body.tables || []).map(table => ({ table, status: 'pending', message: '', relationCount: 0, viewAsCount: 0 }))
      };
      metadataJobs.set(id, job);
      return sendJson(res, 200, { success: true, data: job });
    }
    if (body.resource === 'job' && body.action === 'item') {
      const job = metadataJobs.get(body.jobId);
      if (job) {
        const item = job.items.find(row => row.table === body.table);
        if (item) Object.assign(item, { status: body.status, message: body.message || '', relationCount: body.relationCount || 0, viewAsCount: body.viewAsCount || 0 });
        job.processedTables = job.items.filter(row => row.status === 'done' || row.status === 'error').length;
        job.failedTables = job.items.filter(row => row.status === 'error').length;
        job.status = 'running';
      }
      return sendJson(res, 200, { success: true, data: job || null });
    }
    if (body.resource === 'job' && body.action === 'reprocess-errors') {
      const job = metadataJobs.get(body.jobId);
      if (job) {
        for (const item of job.items) {
          if (item.status === 'error') {
            Object.assign(item, { status: 'pending', message: 'Aguardando reprocessamento', relationCount: 0, viewAsCount: 0 });
          }
        }
        job.processedTables = job.items.filter(row => row.status === 'done' || row.status === 'error').length;
        job.failedTables = job.items.filter(row => row.status === 'error').length;
        job.status = job.items.some(row => row.status === 'pending') ? 'pending' : 'done';
      }
      return sendJson(res, 200, { success: true, data: job || null });
    }
    if (body.resource === 'job' && body.action === 'finish') {
      const job = metadataJobs.get(body.jobId);
      if (job) job.status = job.failedTables ? 'done_with_errors' : 'done';
      return sendJson(res, 200, { success: true, data: job || null });
    }
    if (body.resource === 'view-as') {
      if (body.action === 'import-csv') {
        const imported = parseViewAsCsv(body.csvText || '');
        for (const row of imported) {
          viewAsRows = viewAsRows.filter(item => !(item.table.toLowerCase() === row.table.toLowerCase() && item.field.toLowerCase() === row.field.toLowerCase()));
          viewAsRows.push(Object.assign({ source: 'CSV', updatedAt: '2026-06-12T18:00:00-03:00' }, row));
        }
        return sendJson(res, 200, { success: true, data: viewAsRows });
      }
      const rows = Array.isArray(body.rows) ? body.rows : [{
        field: body.field,
        viewAs: body.viewAs,
        listExpression: body.listExpression || '',
        options: Array.isArray(body.options) ? body.options : [],
        source: body.source || 'manual'
      }];
      for (const row of rows) {
        viewAsRows = viewAsRows.filter(item => !(item.table === body.table && item.field === (row.field || row.name)));
        viewAsRows.push({
          table: body.table,
          field: row.field || row.name,
          viewAs: row.viewAs || row.view_as || '',
          listExpression: row.listExpression || '',
          options: Array.isArray(row.options) ? row.options : [],
          source: row.source || body.source || 'manual',
          updatedAt: '2026-06-12T18:00:00-03:00'
        });
      }
      return sendJson(res, 200, { success: true, data: viewAsRows });
    }
  }
  if (pathname === '/view-as-resolver.php' && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    return sendJson(res, 200, { success: true, data: Array.isArray(body.rows) ? body.rows : [], resolvedIncludes: {} });
  }
  if (pathname.endsWith('/metadata/view-as/resolve') && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    return sendJson(res, 200, { success: true, data: Array.isArray(body.rows) ? body.rows.map(row => Object.assign({ source: 'PASOE' }, row)) : [] });
  }
  if (pathname === '/metadata-pasoe.php') {
    requests.push({ method: req.method, path: req.url });
    const targetPath = url.searchParams.get('path') || '';
    const targetUrl = new URL(targetPath, `http://${req.headers.host}`);
    return handleApi(req, res, targetUrl.pathname, targetUrl.searchParams);
  }

  if (pathname.endsWith('/metadata/sync')) {
    requests.push({ method: req.method, path: req.url });
    return sendJson(res, 200, {
      success: true,
      steps: [
        { step: 'database-catalog', success: true },
        { step: 'tables', success: true },
        { step: 'fields', success: true }
      ]
    });
  }
  if (pathname.endsWith('/metadata/database-catalog')) {
    requests.push({ method: req.method, path: req.url });
    return sendJson(res, 200, { success: true, data: [
      { name: 'DICTDB', displayName: 'DICTDB' },
      { name: 'espec', displayName: 'espec' },
      { name: 'ems2med', displayName: 'ems2med' }
    ] });
  }
  if (pathname.endsWith('/metadata/tables')) {
    const database = String(searchParams.get('database') || '').toLowerCase();
    const data = database === 'espec'
      ? [{ name: 'pp-container', label: 'pp-container', database: 'espec' }]
      : database === 'ems2med'
        ? [{ table: 'ped-venda', description: 'Pedido venda', database: 'ems2med' }]
        : [{ name: 'Customer', label: 'Customer', database: 'DICTDB' }, { name: 'Order', label: 'Order', database: 'DICTDB' }];
    return sendJson(res, 200, { success: true, data });
  }
  if (pathname.includes('/metadata/tables/') && pathname.endsWith('/fields')) {
    const decodedPathname = decodeURIComponent(pathname);
    if (decodedPathname.includes('/metadata/tables/pp-container/fields')) {
      return sendJson(res, 200, { success: true, database: 'espec', table: 'pp-container', data: [
        { name: 'nr-container', type: 'integer', fieldType: 'integer', indices: 'indice1,ind_fornec', viewAs: 'FILL-IN' },
        { name: 'nr-pedido', type: 'integer', fieldType: 'integer', indices: 'nr-pedido', viewAs: 'COMBO-BOX', options: [
          { value: '7788', label: 'Pedido exportacao' }
        ] },
        { name: 'ativo', type: 'logical', fieldType: 'logical', viewAs: 'FILL-IN' },
        { name: 'descricao', type: 'character', indices: 'descricao' }
      ] });
    }
    if (decodedPathname.includes('/metadata/tables/pp-container-item/fields')) {
      return sendJson(res, 200, { success: true, database: 'espec', table: 'pp-container-item', data: [
        { name: 'nr-container', type: 'integer', fieldType: 'integer' },
        { name: 'item', type: 'integer', fieldType: 'integer' }
      ] });
    }
    if (decodedPathname.includes('/metadata/tables/pp-pedido/fields')) {
      return sendJson(res, 200, { success: true, database: 'espec', table: 'pp-pedido', data: [
        { name: 'nr-pedido', type: 'integer', fieldType: 'integer' },
        { name: 'cliente', type: 'character' }
      ] });
    }
    if (decodedPathname.includes('/metadata/tables/ped-venda/fields')) {
      return sendJson(res, 200, { success: true, database: 'ems2med', table: 'ped-venda', data: [
        { name: 'cod-estabel', type: 'character', fieldType: 'character', indices: 'ch-pedido' },
        { name: 'nr-pedcli', type: 'character', fieldType: 'character', indices: 'ch-pedido,nr-pedcli' },
        { name: 'nr-pedseq', type: 'integer', fieldType: 'integer', indices: 'ch-pedseq' },
        { name: 'cod-emitente', type: 'integer', fieldType: 'integer', indices: 'ch-pedido' }
      ] });
    }
    return sendJson(res, 200, { success: true, database: 'DICTDB', table: 'Customer', data: [
      { name: 'Name', indices: [{ name: 'NameIdx', unique: true }], fieldType: 'character' },
      { name: 'State', indices: 'StateIdx', fieldType: 'character' },
      { name: 'CustNum', indices: [{ name: 'CustNum', primary: true, unique: true }], viewAs: 'FILL-IN', fieldType: 'integer' },
      { name: 'Phone', extent: 2 }
    ] });
  }
  if (pathname.endsWith('/metadata/relations/of')) {
    const table = String(searchParams.get('table') || '');
    const database = String(searchParams.get('database') || '');
    if (table === 'pp-container') {
      return sendJson(res, 200, { success: true, data: [{
        leftDatabase: database || 'espec',
        leftTable: 'pp-container',
        leftField: 'nr-container',
        rightDatabase: database || 'espec',
        rightTable: 'pp-container-item',
        rightField: 'nr-container',
        type: 'INNER',
        fileName: 'espec__pp-container__espec__pp-container-item.json'
      }, {
        leftDatabase: database || 'espec',
        leftTable: 'pp-container',
        leftField: 'nr-pedido',
        rightDatabase: database || 'espec',
        rightTable: 'pp-pedido',
        rightField: 'nr-pedido',
        descriptionField: 'cliente',
        type: 'INNER',
        fileName: 'espec__pp-container__espec__pp-pedido.json'
      }] });
    }
    return sendJson(res, 200, { success: true, data: [{
      leftDatabase: 'DICTDB',
      leftTable: 'Customer',
      leftField: 'CustNum',
      rightDatabase: 'DICTDB',
      rightTable: 'Order',
      rightField: 'CustNum',
      type: 'INNER',
      fileName: 'dictdb__customer__dictdb__order.json'
    }] });
  }

  if (pathname.endsWith('/table-browse') && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    requests.push({ method: 'POST', path: pathname, body });
    const direction = String(body.direction || 'ASC').toUpperCase() === 'DESC' ? 'DESC' : 'ASC';
    const row = direction === 'DESC'
      ? { CustNum: 99, Name: 'Cliente Desc', BirthDate: '2026-07-29', LastUpdate: '2026-07-29T14:35:20' }
      : { CustNum: 1, Name: 'Cliente Asc', BirthDate: '2026-01-05', LastUpdate: '2026-01-05T08:10:11' };
    return sendJson(res, 200, {
      success: true,
      database: body.database || 'DICTDB',
      table: body.table || 'Customer',
      direction,
      pageSize: body.pageSize || 50,
      recordsReturned: 1,
      hasMore: false,
      keyFields: [{ name: 'CustNum', type: 'integer', ascending: direction !== 'DESC' }],
      fields: [
        { name: 'CustNum', type: 'integer' },
        { name: 'Name', type: 'character' },
        { name: 'BirthDate', type: 'date' },
        { name: 'LastUpdate', type: 'datetime' }
      ],
      data: [row],
      nextCursor: { CustNum: row.CustNum },
      strategy: 'KEYSET_CURSOR'
    });
  }

  if (pathname.endsWith('/query-store') && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    requests.push({ method: 'POST', path: pathname, body });
    if (!validCode(body.code)) return sendJson(res, 200, error('INVALID_QUERY_CODE', 'Codigo de consulta invalido', body.code || ''));
    const status = body.status || 'draft';
    if (!['draft', 'ready'].includes(status)) return sendJson(res, 200, error('INVALID_QUERY_STATUS', 'Status deve ser draft ou ready', status));
    if (!body.query || typeof body.query !== 'object' || Array.isArray(body.query)) return sendJson(res, 200, error('QUERY_REQUIRED', 'Campo query deve conter a consulta a salvar', body.code));
    const saved = { code: body.code, status, query: body.query, externalFilters: body.externalFilters || body.query.externalFilters || [], updatedAt: new Date().toISOString() };
    store.set(body.code, saved);
    return sendJson(res, 200, { success: true, code: body.code, status, path: `mock/${body.code}.json`, data: saved });
  }

  if (pathname.endsWith('/query') && req.method === 'POST') {
    let body;
    try { body = await readBody(req); } catch (err) { return sendJson(res, 200, error('INVALID_JSON', 'JSON invalido', err.message)); }
    requests.push({ method: 'POST', path: pathname, body });
    if (!body.code) {
      const firstSource = Array.isArray(body.sources) ? body.sources[0] || {} : {};
      if (firstSource.nome === 'pp-container') {
        return sendJson(res, 200, { success: true, data: [{ 'nr-container': 1650, 'nr-pedido': 7788, ativo: 'yes', descricao: 'Container E2E' }], recordsReturned: 1, directQuery: true });
      }
      if (firstSource.nome === 'pp-pedido') {
        return sendJson(res, 200, { success: true, data: [{ 'nr-pedido': 7788, cliente: 'Cliente E2E' }], recordsReturned: 1, directQuery: true });
      }
      return sendJson(res, 200, { success: true, data: [], directQuery: true });
    }
    if (!validCode(body.code)) return sendJson(res, 200, error('INVALID_QUERY_CODE', 'Codigo de consulta invalido', body.code));
    const saved = store.get(body.code);
    if (!saved) return sendJson(res, 200, error('QUERY_NOT_FOUND', 'Consulta salva nao encontrada', body.code));
    const applied = applyParameters(saved, body.parameters || {});
    if (!applied.success) return sendJson(res, 200, applied);
    return sendJson(res, 200, { success: true, code: body.code, status: saved.status, appliedFilters: applied.runtimeFilters, data: [{ codigo: 123, nome: 'Cliente E2E' }] });
  }

  return serveStatic(req, res, pathname);
}

function parseViewAsCsv(csvText) {
  const lines = String(csvText || '').split(/\r?\n/).filter(line => line.trim());
  if (lines.length < 2) return [];
  const delimiter = (lines[0].match(/;/g) || []).length > (lines[0].match(/,/g) || []).length ? ';' : ',';
  const header = parseCsvLine(lines.shift(), delimiter).map(name => name.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, ''));
  const tableIndex = header.findIndex(name => name === 'tabela' || name === 'table');
  const fieldIndex = header.findIndex(name => name === 'campo' || name === 'field' || name === 'banco');
  const listIndex = header.findIndex(name => ['lista de opcoes', 'lista_opcoes', 'view-as', 'view_as', 'viewas'].includes(name));
  return lines.map(line => parseCsvLine(line, delimiter))
    .map(cols => ({
      table: cols[tableIndex] || '',
      field: cols[fieldIndex] || '',
      viewAs: cols[listIndex] || ''
    }))
    .filter(row => row.table && row.field && row.viewAs);
}

function parseCsvLine(line, delimiter) {
  const result = [];
  let current = '';
  let quoted = false;
  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    if (char === '"' && line[i + 1] === '"') {
      current += '"';
      i += 1;
    } else if (char === '"') {
      quoted = !quoted;
    } else if (char === delimiter && !quoted) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current);
  return result.map(value => value.trim());
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  handleApi(req, res, url.pathname).catch(err => sendJson(res, 500, error('MOCK_ERROR', err.message)));
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Sursum E2E mock server listening on ${PORT}`);
});
