(function () {
  'use strict';
  const base = 'https://iol.imatextil.com.br/query-progress';
  if (location.protocol !== 'https:') { location.replace(base + '/query-api-docs.html'); return; }
  const byId = id => document.getElementById(id);
  let spec, ui, credential = null, renewing = null, generation = 0;
  function status(message, error = false) {
    byId('authStatus').textContent = message;
    byId('authStatus').classList.toggle('error', error);
  }
  async function issueToken(current) {
    const response = await fetch(base + '/api/token.php', {
      method: 'POST', credentials: 'omit', cache: 'no-store', redirect: 'error',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: new URLSearchParams({grant_type: 'client_credentials', client_id: current.id, client_secret: current.secret})
    });
    if (!response.ok) throw new Error('Não foi possível obter o token (HTTP ' + response.status + '). Verifique a credencial e a validade da autorização.');
    const data = await response.json();
    if (!/^[a-f0-9]{64}$/.test(data.access_token) || data.expires_in !== 900) throw new Error('Resposta de autenticação inválida.');
    if (credential !== current) throw new Error('Autenticação cancelada.');
    current.token = data.access_token;
    current.expires = Date.now() + 870000;
    ui.preauthorizeApiKey('consumerToken', current.token);
    status('Consumidor autenticado. Token de 15 minutos; renovação automática ativa nesta página.');
    return current.token;
  }
  function tokenHeader(headers) { return Object.keys(headers).find(key => key.toLowerCase() === 'x-sursum-query-token'); }
  async function intercept(request) {
    const url = new URL(request.url);
    const postRoute=['/query-progress/api/token.php','/query-progress/api/query.php'].includes(url.pathname) && request.method.toUpperCase()==='POST' && !url.search;
    const jobRoute=['/query-progress/api/jobs.php','/query-progress/api/job-result.php'].includes(url.pathname) && request.method.toUpperCase()==='GET' && /^\?jobId=JOB-[0-9]{8}-[0-9]{6}-[0-9]{6}$/.test(url.search);
    if (url.origin !== new URL(base).origin || (!postRoute && !jobRoute) || url.hash || url.username || url.password) throw new Error('Execução permitida somente nas rotas públicas de sursum/MED.');
    request.credentials = 'omit'; request.redirect = 'error';
    // Keep consumer credentials separate from the authenticated catalog session.
    for (const key of Object.keys(request.headers)) if (!['accept', 'content-type', 'x-sursum-query-token'].includes(key.toLowerCase())) delete request.headers[key];
    if (!url.pathname.endsWith('/token.php')) {
      const header = tokenHeader(request.headers);
      if (credential && request.headers[header] !== credential.token) { credential = null; status('Usando token informado em Authorize. Renove-o quando vencer.'); }
      if (credential && credential.expires <= Date.now()) {
        const current = credential;
        if (!renewing) renewing = issueToken(current).finally(() => { renewing = null; });
        request.headers[header || 'X-Sursum-Query-Token'] = await renewing;
      }
    }
    return request;
  }
  function render() {
    byId('swagger-ui').replaceChildren();
    ui = SwaggerUIBundle({spec, dom_id: '#swagger-ui', validatorUrl: null, persistAuthorization: false,
      queryConfigEnabled: false, supportedSubmitMethods: ['post','get'], requestInterceptor: intercept,
      showMutatedRequest: false, defaultModelsExpandDepth: 0, displayRequestDuration: true,
      presets: [SwaggerUIBundle.presets.apis], layout: 'BaseLayout'});
  }
  function clear(renderAgain = true) {
    generation++; credential = null; renewing = null;
    byId('consumerAuth').reset();
    if (ui) ui.authActions.logout(['consumerToken']);
    if (renderAgain && spec) render();
    else byId('swagger-ui').replaceChildren();
    byId('obtainToken').disabled = !spec;
    status('Credenciais e resultados limpos.');
  }
  byId('clearCredentials').addEventListener('click', () => clear());
  byId('consumerAuth').addEventListener('submit', async event => {
    event.preventDefault();
    if (!ui) return;
    const current = {id: byId('clientId').value.trim(), secret: byId('clientSecret').value, token: '', expires: 0};
    clear(false); render();
    credential = current;
    const attempt = generation;
    byId('obtainToken').disabled = true; status('Obtendo token…');
    try { await issueToken(current); }
    catch (error) { if (generation === attempt) { credential = null; status(error.message, true); } }
    finally { if (generation === attempt) byId('obtainToken').disabled = false; }
  });
  async function init() {
    if (spec) return;
    byId('obtainToken').disabled = true;
    try {
      const response = await fetch('query-api-docs.php?format=openapi', {credentials: 'same-origin', cache: 'no-store'});
      if (!response.ok) throw new Error('Catálogo indisponível. Refaça o login ou tente novamente.');
      spec = await response.json(); render(); byId('obtainToken').disabled = false;
      byId('docsStatus').textContent = 'Catálogo atual carregado. Os exemplos preservam os zeros à esquerda dos filtros.';
    } catch (error) { byId('docsStatus').textContent = error.message; }
  }
  window.addEventListener('pagehide', () => clear(false));
  window.addEventListener('pageshow', event => { if (event.persisted && spec) render(); });
  if (window.SursumAuth && !window.SursumAuthPending) init();
  else window.addEventListener('sursum:auth-ready', init, {once: true});
})();
