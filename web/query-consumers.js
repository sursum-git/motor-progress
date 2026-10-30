(function () {
  'use strict';
  if (location.protocol === 'http:') {
    const secure = new URL(location.href); secure.protocol = 'https:';
    if (secure.port === '80') secure.port = '';
    // Leave an HTTP parent frame too, so session cookies remain on the HTTPS site.
    if (window.top !== window) window.top.location.href = secure.href;
    else location.replace(secure.href);
    return;
  }
  const byId = id => document.getElementById(id);
  let grid, picker, csrf = '', revision = '', editing = false, pendingAction = null, busy = false;
  const status = (message, error = false) => { byId('status').textContent = message; byId('status').classList.toggle('error', error); };
  const selected = () => grid && grid.dataItem(grid.select());
  const updateActions = () => {
    const row = selected(), disabled = busy || !row || row.protected;
    ['edit', 'rotate', 'revoke'].forEach(id => { byId(id).disabled = disabled || (id === 'revoke' && !row?.active); });
    byId('enableCredentials').disabled = disabled || !!row?.clientCredentials;
    byId('rotate').textContent = row?.clientCredentials ? 'Rotacionar segredo' : 'Rotacionar token';
  };
  function setBusy(value) {
    busy = value;
    ['refresh', 'new', 'saveConsumer', 'confirmAction', 'cancelEdit', 'cancelConfirm'].forEach(id => { byId(id).disabled = value; });
    updateActions();
  }
  async function api(payload) {
    const response = await fetch('query-consumers-admin.php', {
      method: payload ? 'POST' : 'GET', credentials: 'same-origin', cache: 'no-store',
      headers: payload ? {'Content-Type': 'application/json', 'X-CSRF-Token': csrf} : {},
      body: payload ? JSON.stringify(payload) : undefined
    });
    const result = await response.json();
    if (!response.ok || !result.success) {
      const message = result.error?.message || 'Não foi possível administrar os consumidores.';
      if (response.status === 409) status('A configuração mudou. Clique em Atualizar e confira os dados antes de tentar novamente.', true);
      throw new Error(message);
    }
    return result;
  }
  function applyList(result) {
    revision = result.revision;
    grid.dataSource.data(result.data || []);
    grid.clearSelection(); updateActions();
  }
  async function refresh() {
    setBusy(true);
    try {
      const result = await api(); csrf = result.csrf; applyList(result);
      byId('adminPanel').hidden = false;
      status('Consumidores do sursum-api / MED. Alterações entram em vigor imediatamente.');
    } catch (error) { status(error.message, true); }
    finally { setBusy(false); }
  }
  async function openEditor(isEdit) {
    if (busy) return;
    const row = isEdit ? selected() : null;
    if (isEdit && (!row || row.protected)) return;
    editing = isEdit;
    byId('clientModeHint').hidden = isEdit;
    byId('consumerId').value = row?.id || ''; byId('consumerId').readOnly = isEdit;
    byId('consumerDays').value = row ? Math.max(1, Math.min(365, Math.ceil((row.expiresAtEpoch * 1000 - Date.now()) / 86400000))) : 90;
    byId('formError').textContent = '';
    byId('editorTitle').textContent = isEdit ? 'Editar permissões e validade' : 'Novo consumidor';
    setBusy(true);
    try {
      const response = await fetch('saved-query-store.php?action=list', {credentials:'same-origin', cache:'no-store'});
      const catalog = await response.json();
      if (!response.ok || !catalog.success || !Array.isArray(catalog.data)) throw new Error('Não foi possível carregar as consultas salvas.');
      const codes = [...new Set(catalog.data.map(item => item.code).concat(row?.queries || []))].sort();
      picker.setDataSource(codes.map(code => ({code})));
      picker.value(row?.queries || []);
      byId('editor').showModal();
    } catch(error) { status(error.message, true); }
    finally { setBusy(false); }
  }
  function showToken(token) {
    byId('issuedToken').value = token;
    const body = JSON.stringify({
      code: 'saldo-estoque-por-referencia',
      parameters: {querystring: {estabelecimento: '502', deposito: 'ARM', item: '130062', referencia: '004'}}
    }, null, 2);
    byId('issuedCurl').value = [
      "curl --request POST 'https://iol.imatextil.com.br/query-progress/api/query.php' \\",
      "  --header 'Content-Type: application/json' \\",
      `  --header 'X-Sursum-Query-Token: ${token}' \\`,
      `  --data '${body}'`
    ].join('\n');
    byId('copyStatus').textContent = '';
    byId('tokenDialog').showModal();
  }
  function clearToken() {
    byId('issuedToken').value = ''; byId('issuedCurl').value = ''; byId('copyStatus').textContent = '';
    ['issuedClientId', 'issuedClientSecret', 'issuedCredentialCurl'].forEach(id => { byId(id).value = ''; });
    byId('credentialCopyStatus').textContent = '';
  }
  function showCredential(id, secret) {
    byId('issuedClientId').value = id; byId('issuedClientSecret').value = secret;
    byId('issuedCredentialCurl').value = [
      '# Bash com curl e jq. Guarde a credencial em cofre na integração.',
      'TOKEN=$(curl --silent --show-error --fail \\',
      "  'https://iol.imatextil.com.br/query-progress/api/token.php' \\",
      "  --data-urlencode 'grant_type=client_credentials' \\",
      `  --data-urlencode 'client_id=${id}' \\`,
      `  --data-urlencode 'client_secret=${secret}' | jq -er '.access_token') || exit 1`,
      'curl --request POST --fail-with-body \\',
      "  'https://iol.imatextil.com.br/query-progress/api/query.php' \\",
      "  --header 'Content-Type: application/json' \\",
      '  --header "X-Sursum-Query-Token: $TOKEN" \\',
      '  --data \'{"code":"saldo-estoque-por-referencia","parameters":{"querystring":{"estabelecimento":"502","deposito":"ARM","item":"130062","referencia":"004"}}}\'',
      'unset TOKEN'
    ].join('\n');
    byId('credentialCopyStatus').textContent = ''; byId('credentialDialog').showModal();
  }
  async function copyIssued(field, label, statusId = 'copyStatus') {
    const element = byId(field), value = element.value;
    if (!value) return;
    try {
      await navigator.clipboard.writeText(value);
      if (element.value === value) byId(statusId).textContent = `${label} copiado.`;
    } catch (error) {
      if (element.value !== value) return;
      element.focus(); element.select();
      byId(statusId).textContent = `Use Ctrl+C para copiar o ${label.toLowerCase()} selecionado.`;
    }
  }
  async function mutate(payload, dialogId, errorId) {
    setBusy(true); byId(errorId).textContent = '';
    try {
      const result = await api({...payload, revision});
      applyList(result); byId(dialogId).close();
      status('Alteração aplicada no sursum-api / MED.');
      if (result.token) { showToken(result.token); delete result.token; }
      if (result.client_secret) { showCredential(result.client_id, result.client_secret); delete result.client_secret; }
    } catch (error) { byId(errorId).textContent = error.message; }
    finally { setBusy(false); }
  }
  function confirmAction(action) {
    const row = selected(); if (busy || !row || row.protected) return;
    if (action === 'rotate' && row.clientCredentials) action = 'credentials';
    pendingAction = {action, id: row.id};
    byId('confirmationTitle').textContent = action === 'credentials' ? (row.clientCredentials ? 'Rotacionar segredo' : 'Ativar renovação automática') : action === 'rotate' ? 'Rotacionar token' : 'Revogar acesso';
    byId('confirmationText').textContent = action === 'credentials'
      ? `A credencial atual e os tokens de ${row.id} serão invalidados imediatamente. O novo segredo permitirá obter tokens de 15 minutos. As consultas serão preservadas e a autorização será reativada.`
      : action === 'rotate'
      ? `O token atual de ${row.id} será invalidado imediatamente. A rotação também reativa o consumidor e preserva suas consultas.`
      : `O consumidor ${row.id} perderá o acesso imediatamente. Uma nova rotação poderá reativá-lo.`;
    byId('rotationDaysLabel').hidden = action === 'revoke';
    byId('rotationDays').required = action !== 'revoke'; byId('rotationDays').value = 90;
    byId('confirmationError').textContent = ''; byId('confirmDialog').showModal();
  }
  function init() {
    if (grid) return;
    if (window.SursumAuth?.user?.source !== 'ldap' || String(window.SursumAuth?.user?.username || '').toLowerCase() !== 'tadeu.parreiras') {
      status('Administração restrita ao usuário tadeu.parreiras.', true); return;
    }
    kendo.culture('pt-BR');
    grid = $('#consumersGrid').kendoGrid({
      dataSource: {data: [], pageSize: 20}, selectable: 'row', sortable: true, pageable: true,
      scrollable: true, resizable: true, change: updateActions,
      columns: [
        {field:'id', title:'Consumidor', width:210},
        {field:'role', title:'Perfil', width:110, template: row => row.protected ? 'Admin · protegido' : 'Integração'},
        {title:'Autenticação', width:180, template: row => row.protected ? 'Serviço protegido' : row.clientCredentials ? 'Automática · token 15 min' : 'Token manual'},
        {title:'Situação', width:115, template: row => !row.active ? '<span class="pill off">Revogado</span>' : row.expired ? '<span class="pill expired">Expirado</span>' : '<span class="pill">Ativo</span>'},
        {field:'expiresAtEpoch', title:'Validade', width:170, template: row => kendo.toString(new Date(row.expiresAtEpoch * 1000), 'dd/MM/yyyy HH:mm')},
        {title:'Consultas permitidas', template: row => '<span class="query-list">' + kendo.htmlEncode(row.protected ? 'Administração técnica' : row.queries.join(', ')) + '</span>'}
      ], noRecords: {template:'Nenhum consumidor cadastrado.'}
    }).data('kendoGrid');
    picker = $('#consumerQueries').kendoMultiSelect({dataTextField:'code', dataValueField:'code', placeholder:'Selecione as consultas...', filter:'contains', autoClose:false, popup:{appendTo:$('#editor')}}).data('kendoMultiSelect');
    byId('refresh').onclick = refresh; byId('new').onclick = () => openEditor(false); byId('edit').onclick = () => openEditor(true);
    byId('rotate').onclick = () => confirmAction('rotate'); byId('revoke').onclick = () => confirmAction('revoke');
    byId('enableCredentials').onclick = () => confirmAction('credentials');
    byId('cancelEdit').onclick = () => byId('editor').close(); byId('cancelConfirm').onclick = () => byId('confirmDialog').close();
    byId('consumerForm').onsubmit = event => { event.preventDefault(); mutate({action:editing ? 'update' : 'create-client', id:byId('consumerId').value.trim(), days:Number(byId('consumerDays').value), queries:picker.value()}, 'editor', 'formError'); };
    byId('confirmationForm').onsubmit = event => { event.preventDefault(); if (!pendingAction) return; mutate({...pendingAction, ...(pendingAction.action !== 'revoke' ? {days:Number(byId('rotationDays').value)} : {})}, 'confirmDialog', 'confirmationError'); };
    byId('copyToken').onclick = () => copyIssued('issuedToken', 'Token');
    byId('copyCurl').onclick = () => copyIssued('issuedCurl', 'Curl');
    byId('closeToken').onclick = () => { clearToken(); byId('tokenDialog').close(); };
    byId('tokenDialog').addEventListener('cancel', clearToken);
    byId('tokenDialog').addEventListener('close', clearToken);
    byId('copyClientSecret').onclick = () => copyIssued('issuedClientSecret', 'Segredo', 'credentialCopyStatus');
    byId('copyCredentialCurl').onclick = () => copyIssued('issuedCredentialCurl', 'Exemplo', 'credentialCopyStatus');
    byId('closeCredential').onclick = () => { clearToken(); byId('credentialDialog').close(); };
    byId('credentialDialog').addEventListener('cancel', clearToken);
    byId('credentialDialog').addEventListener('close', clearToken);
    window.addEventListener('pagehide', clearToken);
    refresh();
  }
  window.addEventListener('sursum:auth-ready', init);
  if (window.SursumAuth) init();
})();
