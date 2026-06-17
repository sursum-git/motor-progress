(function () {
  const STORAGE_KEY = "sursumApiEndpoints";
  let config = null;
  let currentClientId = "";
  let currentEnvironmentId = "";
  let environmentWindow = null;
  let environmentFormWindow = null;
  let companyWindow = null;
  let editingEnvironmentId = "";

  function init() {
    removeLegacyJsonPreviewUi();
    $("button").kendoButton();
    $("#clientName, #environmentFormName, #environmentFormUrl, #environmentFormServidor, #environmentFormUsuario, #environmentFormSenha, #environmentFormArquivoPf, #environmentFormArquivoAlias, #companyName, #companyCode, #companyPathParam").kendoTextBox();
    $("#clientCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: []
    });

    config = loadConfig();
    currentClientId = config.selected.clientId;

    $("#clientsGrid").kendoGrid({
      dataSource: [],
      height: 360,
      sortable: true,
      resizable: true,
      noRecords: { template: "Nenhum cliente cadastrado." },
      columns: [
        { field: "name", title: "Cliente" },
        { field: "environmentCount", title: "Ambientes", width: 190, template: "<button type='button' class='k-button k-button-sm open-environments'>Ambientes (#= environmentCount #)</button>" },
        { title: "Acoes", width: 120, template: "<button class='k-button k-button-sm remove-client-row'>Remover</button>" }
      ]
    });
    $("#environmentsGrid").kendoGrid({
      dataSource: [],
      height: 300,
      sortable: true,
      resizable: true,
      noRecords: { template: "Nenhum ambiente cadastrado para este cliente." },
      columns: [
        { field: "name", title: "Ambiente", width: 220 },
        { field: "pasoeBaseUrl", title: "URL base" },
        { field: "servidor", title: "Servidor SSH", width: 160 },
        { field: "companyCount", title: "Empresas", width: 180, template: "<button type='button' class='k-button k-button-sm open-companies'>Empresas (#= companyCount #)</button>" },
        { title: "Acoes", width: 190, template: "<button class='k-button k-button-sm edit-environment-row'>Alterar</button> <button class='k-button k-button-sm remove-environment-row'>Remover</button>" }
      ]
    });
    $("#companiesGrid").kendoGrid({
      dataSource: [],
      height: 220,
      sortable: true,
      resizable: true,
      noRecords: { template: "Nenhuma empresa cadastrada para este ambiente." },
      columns: [
        { field: "name", title: "Empresa", width: 240 },
        { field: "code", title: "Codigo", width: 120 },
        { field: "pathParam", title: "Path param", width: 180 },
        { title: "Acoes", width: 120, template: "<button class='k-button k-button-sm remove-company-row'>Remover</button>" }
      ]
    });
    environmentWindow = $("#environmentEditorPanel").kendoWindow({
      title: "Ambientes do cliente",
      modal: true,
      visible: false,
      width: "860px",
      maxWidth: "96vw",
      actions: ["Close"],
      open: function () {
        const grid = $("#environmentsGrid").data("kendoGrid");
        if (grid) grid.resize();
      }
    }).data("kendoWindow");
    environmentFormWindow = $("#environmentFormPanel").kendoWindow({
      title: "Ambiente",
      modal: true,
      visible: false,
      width: "720px",
      maxWidth: "96vw",
      actions: ["Close"],
      open: function () {
        setTimeout(function () { $("#environmentFormName").focus(); }, 0);
      },
      close: function () {
        editingEnvironmentId = "";
      }
    }).data("kendoWindow");
    companyWindow = $("#companyEditorPanel").kendoWindow({
      title: "Empresas do ambiente",
      modal: true,
      visible: false,
      width: "760px",
      maxWidth: "96vw",
      actions: ["Close"],
      open: function () {
        const grid = $("#companiesGrid").data("kendoGrid");
        if (grid) grid.resize();
        setTimeout(function () { $("#companyName").focus(); }, 0);
      }
    }).data("kendoWindow");

    $("#clientCombo").data("kendoComboBox").bind("change", onClientChanged);
    $("#addClient").on("click", addClient);
    $("#removeClient").on("click", removeCurrentClient);
    $("#clientsGrid").on("click", ".remove-client-row", removeClientRow);
    $("#clientsGrid").on("click", ".open-environments", openEnvironmentEditorFromGrid);
    $("#newEnvironment").on("click", openNewEnvironmentForm);
    $("#saveEnvironment").on("click", saveEnvironmentForm);
    $("#cancelEnvironmentForm").on("click", closeEnvironmentForm);
    $("#environmentsGrid").on("click", ".edit-environment-row", openEnvironmentFormFromGrid);
    $("#environmentsGrid").on("click", ".remove-environment-row", removeEnvironmentRow);
    $("#environmentsGrid").on("click", ".open-companies", openCompanyEditorFromGrid);
    $("#environmentsGrid").on("click", "tbody tr", selectEnvironmentRow);
    $("#addCompany").on("click", addCompanyForCurrentEnvironment);
    $("#companiesGrid").on("click", ".remove-company-row", removeCompanyRow);

    refresh();
    if (window.SursumUiReady) window.SursumUiReady();
  }

  function removeLegacyJsonPreviewUi() {
    $("#jsonPreviewWindow, #filePreview, #openJsonPreview, #configFile, #exportFile, #saveWithPicker").remove();
    $("h2, span, label").filter(function () {
      return /preview|arquivo json/i.test($(this).text() || "");
    }).closest(".panel-title, .endpoint-field, label").remove();
  }

  function loadConfig() {
    if (window.SursumContext) {
      const context = typeof SursumContext.getConfig === "function"
        ? SursumContext.getConfig()
        : (typeof SursumContext.getContext === "function" ? SursumContext.getContext() : null);
      if (context) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(context, null, 2));
        return normalizeConfig(context);
      }
    }
    let raw = null;
    try { raw = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null"); } catch (_) {}
    return normalizeConfig(raw);
  }

  function normalizeConfig(raw) {
    if (raw && raw.version === 4 && Array.isArray(raw.clients)) {
      return {
        version: 4,
        clients: Array.isArray(raw.clients) ? raw.clients.slice() : [],
        environments: Array.isArray(raw.environments) ? raw.environments.slice() : [],
        links: Array.isArray(raw.links) ? raw.links.slice() : [],
        paths: raw.paths || {},
        companies: Array.isArray(raw.companies) ? raw.companies.slice() : [],
        physicalDatabases: Array.isArray(raw.physicalDatabases) ? raw.physicalDatabases.slice() : [],
        aliases: Array.isArray(raw.aliases) ? raw.aliases.slice() : [],
        selected: raw.selected || {}
      };
    }
    return {
      version: 4,
      clients: [{ id: "cliente-padrao", name: "Cliente padrao" }],
      paths: {
        metadataRoot: "sursum-conf/metadata",
        relationsRoot: "sursum-conf/relations",
        pasoeRoot: "sursum-conf/pasoe",
        databaseCatalog: "sursum-conf/metadata/database-catalog.json",
        aliasesFile: "sursum-conf/pasoe/datasul-prod-aliases.p"
      },
      environments: [],
      links: [],
      companies: [],
      physicalDatabases: [],
      aliases: [],
      selected: { clientId: "cliente-padrao", environmentId: "", companyId: "" }
    };
  }

  function currentClient() {
    return config.clients.find((item) => item.id === currentClientId) || config.clients[0] || null;
  }

  function persist() {
    const current = currentClient();
    config.selected = Object.assign({}, config.selected || {}, {
      clientId: current ? current.id : ""
    });
    if (window.SursumContext && typeof SursumContext.setConfig === "function") {
      config = SursumContext.setConfig(config);
      currentClientId = config.selected.clientId;
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config, null, 2));
  }

  function clientRows() {
    return (config.clients || []).map((client) => ({
      id: client.id,
      name: client.name,
      environmentCount: environmentsForClient(client.id).length
    }));
  }

  function refresh() {
    persist();
    const clientCombo = $("#clientCombo").data("kendoComboBox");
    clientCombo.setDataSource(new kendo.data.DataSource({ data: config.clients }));
    clientCombo.value((currentClient() || {}).id || "");
    $("#clientsGrid").data("kendoGrid").dataSource.data(clientRows());
    refreshEnvironmentEditor();
  }

  function onClientChanged() {
    currentClientId = $("#clientCombo").data("kendoComboBox").value() || (currentClient() || {}).id || "";
    refresh();
  }

  function addClient() {
    const name = String($("#clientName").val() || "").trim();
    if (!name) {
      setStatus("Informe o nome do cliente.", "error");
      return;
    }
    const clientId = slug(name) + "-" + Date.now();
    config.clients.push({ id: clientId, name });
    currentClientId = clientId;
    $("#clientName").val("");
    refresh();
    setStatus("Cliente adicionado.", "ok");
  }

  function removeCurrentClient() {
    const client = currentClient();
    if (!client) {
      setStatus("Nenhum cliente selecionado.", "error");
      return;
    }
    removeClientById(client.id);
  }

  function removeClientRow(event) {
    const item = $("#clientsGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    removeClientById(item.id);
  }

  function removeClientById(clientId) {
    if ((config.clients || []).length <= 1) {
      setStatus("Mantenha pelo menos um cliente cadastrado.", "error");
      return;
    }
    const environmentIds = new Set(environmentsForClient(clientId).map((item) => item.id));
    config.links = (config.links || []).filter((item) => item.clientId !== clientId);
    config.environments = (config.environments || []).filter((environment) => {
      if (environment.clientId === clientId) return false;
      if (!environmentIds.has(environment.id)) return true;
      return (config.links || []).some((link) => link.environmentId === environment.id);
    });
    config.companies = (config.companies || []).filter((company) => !environmentIds.has(company.environmentId));
    config.clients = config.clients.filter((item) => item.id !== clientId);
    currentClientId = (config.clients[0] || {}).id || "";
    refresh();
    setStatus("Cliente removido.", "ok");
  }

  function environmentsForClient(clientId) {
    const linkedIds = new Set((config.links || [])
      .filter((link) => link.clientId === clientId)
      .map((link) => link.environmentId));
    return (config.environments || []).filter((environment) => environment.clientId === clientId || linkedIds.has(environment.id))
      .map((environment) => Object.assign({}, environment, { companyCount: companiesForEnvironment(environment.id).length }));
  }

  function currentEnvironment() {
    const client = currentClient();
    const rows = client ? environmentsForClient(client.id) : [];
    return rows.find((item) => item.id === currentEnvironmentId) || rows[0] || null;
  }

  function companiesForEnvironment(environmentId) {
    return (config.companies || []).filter((company) => company.environmentId === environmentId);
  }

  function openEnvironmentEditorFromGrid(event) {
    event.preventDefault();
    event.stopPropagation();
    const grid = $("#clientsGrid").data("kendoGrid");
    const item = grid ? grid.dataItem($(event.currentTarget).closest("tr")) : null;
    if (!item || !item.id) {
      setStatus("Cliente da linha nao encontrado.", "error");
      return;
    }
    const client = (config.clients || []).find((candidate) => candidate.id === item.id);
    if (!client) {
      setStatus("Cliente da linha nao encontrado.", "error");
      return;
    }
    currentClientId = client.id;
    const combo = $("#clientCombo").data("kendoComboBox");
    if (combo) {
      combo.value(currentClientId);
    }
    currentEnvironmentId = "";
    refreshEnvironmentEditor();
    persist();
    showEnvironmentEditor(client);
  }

  function refreshEnvironmentEditor() {
    const grid = $("#environmentsGrid").data("kendoGrid");
    const companyGrid = $("#companiesGrid").data("kendoGrid");
    if (!grid || !companyGrid) return;
    const client = currentClient();
    const rows = client ? environmentsForClient(client.id) : [];
    if (!rows.some((item) => item.id === currentEnvironmentId)) {
      currentEnvironmentId = rows[0] ? rows[0].id : "";
    }
    const environment = currentEnvironment();
    const companyRows = environment ? companiesForEnvironment(environment.id) : [];
    const selectedCompanyId = companyRows.some((company) => company.id === ((config.selected || {}).companyId))
      ? (config.selected || {}).companyId
      : (companyRows[0] ? companyRows[0].id : "");
    if (client && environment) {
      config.selected = Object.assign({}, config.selected || {}, {
        clientId: client.id,
        environmentId: environment.id,
        companyId: selectedCompanyId
      });
    }
    grid.dataSource.data(rows);
    companyGrid.dataSource.data(companyRows);
    $("#environmentPanelSummary").text(client
      ? "Cliente selecionado: " + (client.name || client.id)
      : "Selecione um cliente para manter os ambientes.");
    $("#companyPanelSummary").text(environment
      ? "Ambiente selecionado: " + (environment.name || environment.id) + ". Use {empresa} na URL base para substituir pelo path param."
      : "Selecione um ambiente para manter as empresas.");
  }

  function showEnvironmentEditor(client) {
    if (environmentWindow) {
      environmentWindow.title("Ambientes do cliente - " + (client.name || client.id));
      environmentWindow.center().open();
      environmentWindow.maximize();
      const grid = $("#environmentsGrid").data("kendoGrid");
      if (grid) grid.resize();
    }
    setStatus("Janela de ambientes aberta para " + (client.name || client.id) + ".", "ok");
  }

  function openNewEnvironmentForm(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    const client = currentClient();
    if (!client) {
      setStatus("Selecione um cliente antes de cadastrar ambiente.", "error");
      return;
    }
    editingEnvironmentId = "";
    $("#environmentFormTitle").text("Novo ambiente");
    $("#environmentFormSummary").text("Cliente: " + (client.name || client.id));
    $("#environmentFormName").val("");
    $("#environmentFormUrl").val("");
    $("#environmentFormServidor").val("");
    $("#environmentFormUsuario").val("");
    $("#environmentFormSenha").val("");
    $("#environmentFormArquivoPf").val("");
    $("#environmentFormArquivoAlias").val("");
    showEnvironmentForm("Novo ambiente");
  }

  function openEnvironmentFormFromGrid(event) {
    event.preventDefault();
    event.stopPropagation();
    const grid = $("#environmentsGrid").data("kendoGrid");
    const item = grid ? grid.dataItem($(event.currentTarget).closest("tr")) : null;
    if (!item || !item.id) {
      setStatus("Ambiente da linha nao encontrado.", "error");
      return;
    }
    currentEnvironmentId = item.id;
    editingEnvironmentId = item.id;
    $("#environmentFormTitle").text("Alterar ambiente");
    $("#environmentFormSummary").text("Cliente: " + ((currentClient() || {}).name || currentClientId));
    $("#environmentFormName").val(item.name || "");
    $("#environmentFormUrl").val(item.pasoeBaseUrl || "");
    $("#environmentFormServidor").val(item.servidor || "");
    $("#environmentFormUsuario").val(item.usuario || "");
    $("#environmentFormSenha").val(item.senha || "");
    $("#environmentFormArquivoPf").val(item.arquivoPf || item.arquivo_pf || "");
    $("#environmentFormArquivoAlias").val(item.arquivoAlias || item.arquivo_alias || "");
    showEnvironmentForm("Alterar ambiente - " + (item.name || item.id));
  }

  function showEnvironmentForm(title) {
    if (!environmentFormWindow) return;
    environmentFormWindow.title(title);
    environmentFormWindow.center().open();
    environmentFormWindow.maximize();
  }

  function closeEnvironmentForm(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    if (environmentFormWindow) environmentFormWindow.close();
  }

  function saveEnvironmentForm(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    const client = currentClient();
    const name = String($("#environmentFormName").val() || "").trim() || "Endpoint PASOE";
    const url = String($("#environmentFormUrl").val() || "").trim().replace(/\/+$/, "");
    const compilerProps = {
      servidor: String($("#environmentFormServidor").val() || "").trim(),
      usuario: String($("#environmentFormUsuario").val() || "").trim(),
      senha: String($("#environmentFormSenha").val() || "").trim(),
      arquivoPf: String($("#environmentFormArquivoPf").val() || "").trim(),
      arquivoAlias: String($("#environmentFormArquivoAlias").val() || "").trim()
    };
    if (!client) {
      setStatus("Selecione um cliente antes de cadastrar ambiente.", "error");
      return;
    }
    if (!url) {
      setStatus("Informe a URL base do endpoint.", "error");
      return;
    }

    config.environments = config.environments || [];
    config.links = config.links || [];
    let environmentId = editingEnvironmentId;
    const existing = environmentId
      ? config.environments.find((environment) => environment.id === environmentId)
      : null;
    if (existing) {
      existing.clientId = existing.clientId || client.id;
      existing.name = name;
      existing.pasoeBaseUrl = url;
      Object.assign(existing, compilerProps);
    } else {
      environmentId = slug(name) + "-" + Date.now();
      config.environments.push({
        id: environmentId,
        clientId: client.id,
        name,
        pasoeBaseUrl: url,
        servidor: compilerProps.servidor,
        usuario: compilerProps.usuario,
        senha: compilerProps.senha,
        arquivoPf: compilerProps.arquivoPf,
        arquivoAlias: compilerProps.arquivoAlias,
        authMode: "none",
        authorization: "",
        companyIdMode: "query",
        extraQueryParams: ""
      });
      if (!config.links.some((link) => link.clientId === client.id && link.environmentId === environmentId)) {
        config.links.push({
          id: "link-" + slug(client.id + "-" + environmentId),
          clientId: client.id,
          environmentId
        });
      }
    }
    config.selected = Object.assign({}, config.selected || {}, {
      clientId: client.id,
      environmentId,
      companyId: ""
    });
    currentEnvironmentId = environmentId;
    closeEnvironmentForm();
    refresh();
    setStatus(existing ? "Ambiente alterado." : "Ambiente cadastrado para o cliente.", "ok");
  }

  function selectEnvironmentRow(event) {
    if ($(event.target).closest(".edit-environment-row, .remove-environment-row, .open-companies").length) return;
    const item = $("#environmentsGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    currentEnvironmentId = item.id;
    refreshEnvironmentEditor();
    persist();
  }

  function openCompanyEditorFromGrid(event) {
    event.preventDefault();
    event.stopPropagation();
    const item = $("#environmentsGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) {
      setStatus("Ambiente da linha nao encontrado.", "error");
      return;
    }
    currentEnvironmentId = item.id;
    refreshEnvironmentEditor();
    persist();
    showCompanyEditor(item);
  }

  function showCompanyEditor(environment) {
    if (companyWindow) {
      companyWindow.title("Empresas do ambiente - " + (environment.name || environment.id));
      companyWindow.center().open();
      companyWindow.maximize();
      const grid = $("#companiesGrid").data("kendoGrid");
      if (grid) grid.resize();
    }
    setStatus("Janela de empresas aberta para " + (environment.name || environment.id) + ".", "ok");
  }

  function removeEnvironmentRow(event) {
    event.preventDefault();
    event.stopPropagation();
    const item = $("#environmentsGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    removeEnvironmentById(item.id);
  }

  function removeEnvironmentById(environmentId) {
    config.links = (config.links || []).filter((link) => link.environmentId !== environmentId);
    config.companies = (config.companies || []).filter((company) => company.environmentId !== environmentId);
    config.environments = (config.environments || []).filter((environment) => environment.id !== environmentId);
    if ((config.selected || {}).environmentId === environmentId) {
      config.selected = Object.assign({}, config.selected || {}, { environmentId: "", companyId: "" });
    }
    refresh();
    setStatus("Ambiente removido do cliente.", "ok");
  }

  function addCompanyForCurrentEnvironment() {
    const client = currentClient();
    const environment = currentEnvironment();
    const name = String($("#companyName").val() || "").trim();
    const code = String($("#companyCode").val() || "").trim();
    const pathParam = String($("#companyPathParam").val() || "").trim() || slug(name);
    if (!client || !environment) {
      setStatus("Selecione um ambiente antes de cadastrar empresa.", "error");
      return;
    }
    if (!name) {
      setStatus("Informe o nome da empresa.", "error");
      return;
    }
    const companyId = slug(pathParam || code || name) + "-" + Date.now();
    config.companies = config.companies || [];
    config.companies.push({
      id: companyId,
      clientId: client.id,
      environmentId: environment.id,
      name,
      code,
      pathParam
    });
    config.selected = Object.assign({}, config.selected || {}, {
      clientId: client.id,
      environmentId: environment.id,
      companyId
    });
    $("#companyName").val("");
    $("#companyCode").val("");
    $("#companyPathParam").val("");
    refresh();
    setStatus("Empresa cadastrada para o ambiente.", "ok");
  }

  function removeCompanyRow(event) {
    event.preventDefault();
    event.stopPropagation();
    const item = $("#companiesGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    config.companies = (config.companies || []).filter((company) => company.id !== item.id);
    if ((config.selected || {}).companyId === item.id) {
      config.selected = Object.assign({}, config.selected || {}, { companyId: "" });
    }
    refresh();
    setStatus("Empresa removida do ambiente.", "ok");
  }

  function slug(value) {
    return String(value || "item").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "item";
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
}());
