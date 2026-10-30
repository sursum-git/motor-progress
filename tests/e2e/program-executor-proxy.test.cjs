const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { spawn, execFileSync } = require('node:child_process');
const { once } = require('node:events');
// Use node:http rather than experimental fetch on older Node installations.
function fetch(url, options = {}) {
  return new Promise((resolve, reject) => {
    if (options.body) options.headers = { ...options.headers, "Content-Length": Buffer.byteLength(options.body) };
    const req = http.request(url, options, res => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', chunk => { body += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, ok: res.statusCode < 400, headers: new Map(Object.entries(res.headers)), text: async () => body }));
      res.on('error', reject);
    });
    req.on('error', reject);
    req.end(options.body);
  });
}
const root = path.resolve(__dirname, '../..');
const php = process.env.PHP_BINARY || 'php';
const phpArgs = process.env.PHP_TEST_SQLITE_EXTENSION ? ['-d', 'extension=sqlite3'] : [];

test('real PHP proxies preserve HTTP methods, JSON bodies, GET parameters and 405 Allow', async () => {
  const received = [];
  const upstream = http.createServer(async (req, res) => {
    let body = '';
    for await (const chunk of req) body += chunk;
    received.push({ method: req.method, url: req.url, body });
    if (req.url.includes('denied')) {
      res.writeHead(405, { 'Content-Type': 'application/json', Allow: 'POST,OPTIONS' });
      res.end(JSON.stringify({ success: false, error: { code: 'METHOD_NOT_ALLOWED' } }));
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(received.at(-1)));
    }
  });
  upstream.listen(0, '127.0.0.1');
  await once(upstream, 'listening');
  const base = `http://127.0.0.1:${upstream.address().port}/api`;
  const tmpRoot = path.join(root, 'temp');
  fs.mkdirSync(tmpRoot, { recursive: true });
  const fixture = fs.mkdtempSync(path.join(tmpRoot, 'proxy-methods-'));
  fs.mkdirSync(path.join(fixture, 'sursum-conf'));
  fs.mkdirSync(path.join(fixture, 'sessions'));
  fs.copyFileSync(path.join(root, 'web/auth.php'), path.join(fixture, 'auth.php'));
  for (const [src, dest] of [['web/pasoe-proxy.php', 'web-proxy.php'], ['pasoe-proxy.php', 'root-proxy.php']]) {
    const content = process.env.TEST_BASELINE ? execFileSync('git', ['show', `HEAD:${src}`], { cwd: root }) : fs.readFileSync(path.join(root, src));
    fs.writeFileSync(path.join(fixture, dest), content);
  }
  // Authenticate only inside this isolated fixture; actual proxy and auth code run unchanged.
  fs.writeFileSync(path.join(fixture, 'router.php'), `<?php
  require __DIR__ . '/auth.php';
  $_SESSION['sursum_user'] = ['username' => 'proxy-test'];
  $_SESSION['sursum_auth_at'] = time();
  $file = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
  if ($file === '/web-proxy.php' || $file === '/root-proxy.php') { require __DIR__ . $file; }
  else { echo 'ready'; }
  `);
  execFileSync(php, [...phpArgs, '-r', `
    $db = new PDO('sqlite:${path.join(fixture, 'sursum-conf/sursum.sqlite').replaceAll('\\', '/')}');
    $db->exec('CREATE TABLE environments (id TEXT, pasoe_base_url TEXT, auth_mode TEXT, authorization TEXT)');
    $db->exec('CREATE TABLE companies (environment_id TEXT, name TEXT, code TEXT, path_param TEXT)');
    $stmt=$db->prepare('INSERT INTO environments VALUES (?, ?, ?, ?)');
    $stmt->execute(['test','${base}','none','']);
  `]);
  const reserve = http.createServer().listen(0, '127.0.0.1');
  await once(reserve, 'listening');
  const port = reserve.address().port;
  await new Promise(resolve => reserve.close(resolve));
  const child = spawn(php, [...phpArgs, '-d', `session.save_path=${path.join(fixture, 'sessions')}`, '-S', `127.0.0.1:${port}`, 'router.php'], { cwd: fixture, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  let stderr = '';
  child.stderr.on('data', chunk => { stderr += chunk; });
  try {
    let ready = false;
    for (let i = 0; i < 100; i++) {
      try { const res = await fetch(`http://127.0.0.1:${port}/health`); if (res.ok) { ready = true; break; } } catch {}
      await new Promise(resolve => setTimeout(resolve, 50));
    }
    assert.ok(ready, stderr);
    for (const proxy of ['web-proxy.php', 'root-proxy.php']) {
      for (const method of ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']) {
        const target = base + '/program/execute?program=echo-json&parameters=' + encodeURIComponent('{"text":"ação & + ?"}');
        const body = JSON.stringify({ program: 'echo-json', parameters: { text: 'ação & + ?', id: 7 } });
        const options = { method, headers: { 'Content-Type': 'application/json' } };
        if (method !== 'GET') options.body = body;
        const res = await fetch(`http://127.0.0.1:${port}/${proxy}?target=${encodeURIComponent(target)}`, options);
        const text = await res.text();
        assert.equal(res.status, 200, `${proxy} ${method}: ${text}`);
        const actual = JSON.parse(text);
        assert.equal(actual.method, method);
        assert.equal(actual.body, method === 'GET' ? '' : body);
        assert.equal(new URL(actual.url, base).searchParams.get('parameters'), '{"text":"ação & + ?"}');
      }
      const denied = await fetch(`http://127.0.0.1:${port}/${proxy}?target=${encodeURIComponent(base + '/denied')}`);
      assert.equal(denied.status, 405);
      assert.equal(denied.headers.get('allow'), 'POST,OPTIONS');
      const before = received.length;
      const blocked = await fetch(`http://127.0.0.1:${port}/${proxy}?target=${encodeURIComponent(base.replace('/api', '/unregistered'))}`, { method: 'DELETE' });
      assert.equal(blocked.status, 403);
      assert.equal(received.length, before, 'unregistered target must never be called');
    }
  } catch (error) { console.error(stderr); throw error; } finally {
    child.kill();
    await once(child, 'exit');
    await new Promise(resolve => upstream.close(resolve));
  }
});
