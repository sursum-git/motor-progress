(function () {
  const STORAGE_KEY = "sursumApiEndpoints";
  let config = null;
  let currentEnvironmentId = "";
  let currentCompanyId = "";
  let companyWindow = null;

  function init() {
    $("button").kendoButton();
    $("#endpointName, #endpointUrl, #endpointServidor, #endpointUsuario, #endpointSenha, #endpointArquivoPf, #endpointArquivoAlias, #companyName, #companyCode").kendoTextBox();
    $("#environmentCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: []
    });

    config = loadConfig();
    currentEnvironmentId = config.selected.environmentId;
    currentCompanyId = config.selected.companyId;

    companyWindow = $("#companyEditorWindow").kendoWindow({
      title: "Empresas do ambiente",
      width: "980px",
      modal: true,
      visible: false,
      actions: ["Maximize", "Close"],
      open: function () {
        refreshCompanyEditor();
      }
    }).data("kendoWindow");

    $("#endpointsGrid").kendoGrid({
      dataSource: [],
      height: 340,
      sortable: true,
      resizable: true,
      noRecords: { template: "Nenhum ambiente cadastrado." },
      columns: [
        { title: " ", width: 56, sortable: false, filterable: false, attributes: { class: "context-action-cell" }, template: "<button class='k-button k-button-sm open-companies' title='Contexto' aria-label='Contexto'>&#8942;</button>" },
        { field: "name", title: "Ambiente", width: 220 },
        { field: "servidor", title: "Servidor SSH", width: 150 },
        { field: "pasoeBaseUrl", title: "URL base" },
        { field: "authMode", title: "Auth", width: 110 },
        { field: "companyIdMode", title: "companyId via", width: 120 },
        { title: "Acoes", width: 120, template: "<button class='k-button k-button-sm remove-environment'>Remover</button>" }
      ]
    });
    $("#companiesGrid").kendoGrid({
      dataSource: [],
      height: 260,
      sortable: true,
      resizable: true,
      selectable: "row",
      noRecords: { template: "Nenhuma empresa cadastrada para este ambiente." },
      columns: [
        { field: "environmentName", title: "Ambiente", width: 180 },
        { field: "name", title: "Identificador interno" },
        { field: "code", title: "Valor companyId", width: 180 },
        { title: "Acoes", width: 120, template: "<button class='k-button k-button-sm remove-company-row'>Remover</button>" }
      ]
    });
    $("#openClientConfig").on("click", function () { window.location.href = "client-config.html"; });
    $("#openLinkConfig").on("click", function () { window.location.href = "link-config.html"; });
    $("#environmentCombo").data("kendoComboBox").bind("change", onEnvironmentChanged);
    $("#addEndpoint").on("click", addEnvironment);
    $("#addCompany").on("click", addCompany);
    $("#removeCompany").on("click", removeCurrentCompany);
    $("#endpointsGrid").on("click", ".open-companies", openCompanyEditorFromGrid);
    $("#endpointsGrid").on("click", ".remove-environment", removeEnvironment);
    $("#companiesGrid").on("click", ".remove-company-row", removeCompanyRow);
    $("#companiesGrid").on("click", "tbody tr", onCompanyRowSelected);
    window.addEventListener("sursum:context-changed", applyExternalConfig);

    refresh(false);
    if (window.SursumUiReady) window.SursumUiReady();
  }

  function loadConfig() {
    const candidates = [];
    if (window.SursumContext) {
      const context = typeof SursumContext.getConfig === "function"
        ? SursumContext.getConfig()
        : (typeof SursumContext.getContext === "function" ? SursumContext.getContext() : null);
      if (context) candidates.push(context);
    }
    ["sursumContextV4", "sursumContextV3", STORAGE_KEY].forEach((key) => {
      try {
        const parsed = JSON.parse(localStorage.getItem(key) || "null");
        if (parsed) candidates.push(parsed);
      } catch (_) {}
    });
    const best = candidates
      .map(normalizeConfig)
      .sort((left, right) => configScore(right) - configScore(left))[0];
    if (best) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(best, null, 2));
      return best;
    }
    return normalizeConfig(null);
  }

  function configScore(candidate) {
    if (!candidate) return 0;
    const environmentCount = Array.isArray(candidate.environments) ? candidate.environments.length : 0;
    const companyCount = Array.isArray(candidate.companies) ? candidate.companies.length : 0;
    const clientCount = Array.isArray(candidate.clients) ? candidate.clients.length : 0;
    const defaultOnly = environmentCount === 1 && candidate.environments[0] && candidate.environments[0].id === "ambiente-local";
    return environmentCount * 100 + companyCount * 10 + clientCount - (defaultOnly ? 1000 : 0);
  }

  function applyExternalConfig(event) {
    const payload = event && event.detail ? event.detail.config : null;
    if (!payload) return;
    const incoming = normalizeConfig(payload);
    if (config && configScore(incoming) < configScore(config)) return;
    config = incoming;
    currentEnvironmentId = (config.selected || {}).environmentId || (config.environments[0] || {}).id || "";
    currentCompanyId = (config.selected || {}).companyId || "";
    refresh(false);
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
      environments: [{
        id: "ambiente-local",
        name: "Local PASOE",
        pasoeBaseUrl: "http://localhost:8890/web/SursumDynamicQuery",
        authMode: "none",
        authorization: "",
        companyIdMode: "query",
        extraQueryParams: ""
      }],
      links: [],
      companies: [{
        id: "empresa-padrao",
        clientId: "cliente-padrao",
        environmentId: "ambiente-local",
        name: "Empresa padrao",
        code: "empresa-padrao"
      }],
      physicalDatabases: [],
      aliases: [],
      selected: {
        clientId: "cliente-padrao",
        environmentId: "ambiente-local",
        companyId: "empresa-padrao"
      }
    };
  }

  function currentEnvironment() {
    return config.environments.find((item) => item.id === currentEnvironmentId) || config.environments[0];
  }

  function companiesForCurrentEnvironment() {
    const environment = currentEnvironment();
    return (config.companies || [])
      .filter((item) => item.environmentId === (environment ? environment.id : ""))
      .map((item) => ({
        ...item,
        environmentName: environment ? environment.name : ""
      }));
  }

  function currentCompany() {
    const companies = companiesForCurrentEnvironment();
    return companies.find((item) => item.id === currentCompanyId) || companies[0] || null;
  }

  function persist() {
    config.selected = {
      clientId: String((config.selected || {}).clientId || ""),
      environmentId: (currentEnvironment() || {}).id || "",
      companyId: (currentCompany() || {}).id || ""
    };
    if (window.SursumContext && typeof SursumContext.setConfig === "function") {
      config = SursumContext.setConfig(config);
      currentEnvironmentId = config.selected.environmentId;
      currentCompanyId = config.selected.companyId;
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config, null, 2));
    setStatus("Salvando no SQLite...", "");
    return saveContextToSqlite(config);
  }

  function saveContextToSqlite(payload) {
    if (!window.jQuery) return $.Deferred().resolve().promise();
    return $.ajax({
      url: "context-store.php",
      method: "POST",
      data: JSON.stringify(payload),
      contentType: "application/json; charset=UTF-8",
      processData: false
    }).done(function (response) {
      if (response && response.success && response.data) {
        config = normalizeConfig(response.data);
        currentEnvironmentId = (config.selected || {}).environmentId || currentEnvironmentId;
        currentCompanyId = (config.selected || {}).companyId || currentCompanyId;
        localStorage.setItem(STORAGE_KEY, JSON.stringify(config, null, 2));
        refresh(false);
      }
      setStatus("Dados salvos no SQLite.", "ok");
    }).fail(function (xhr) {
      const response = xhr && xhr.responseJSON ? xhr.responseJSON : {};
      setStatus(response.error || "Falha ao salvar no SQLite.", "error");
    });
  }

  function refreshCompanyEditor() {
    const environment = currentEnvironment();
    const environmentCombo = $("#environmentCombo").data("kendoComboBox");
    if (environmentCombo) {
      environmentCombo.setDataSource(new kendo.data.DataSource({ data: config.environments || [] }));
      environmentCombo.value((environment || {}).id || "");
    }
    const company = currentCompany();
    $("#companyName").val(company ? company.name || "" : "");
    $("#companyCode").val(company ? company.code || "" : "");
    const grid = $("#companiesGrid").data("kendoGrid");
    if (grid) {
      grid.dataSource.data(companiesForCurrentEnvironment());
      grid.resize();
    }
    if (companyWindow && environment) {
      companyWindow.title("Empresas do ambiente - " + (environment.name || environment.id));
    }
  }

  function openCompanyEditorFromGrid(event) {
    event.preventDefault();
    event.stopPropagation();
    const item = $("#endpointsGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    currentEnvironmentId = item.id || "";
    currentCompanyId = "";
    refreshCompanyEditor();
    if (companyWindow) {
      companyWindow.title("Empresas do ambiente - " + (item.name || item.id));
      companyWindow.center().open();
    }
  }

  function refresh(shouldPersist = true) {
    if (shouldPersist) persist();
    const endpointsGrid = $("#endpointsGrid").data("kendoGrid");
    if (endpointsGrid) endpointsGrid.dataSource.data((config.environments || []).slice());
    refreshCompanyEditor();
  }

  function onEnvironmentChanged() {
    currentEnvironmentId = $("#environmentCombo").data("kendoComboBox").value() || (currentEnvironment() || {}).id || "";
    currentCompanyId = "";
    persist();
    refreshCompanyEditor();
  }

  function addEnvironment() {
    const name = String($("#endpointName").val() || "").trim() || "Endpoint PASOE";
    const url = String($("#endpointUrl").val() || "").trim().replace(/\/+$/, "");
    const servidor = String($("#endpointServidor").val() || "").trim();
    const usuario = String($("#endpointUsuario").val() || "").trim();
    const senha = String($("#endpointSenha").val() || "");
    const arquivoPf = String($("#endpointArquivoPf").val() || "").trim();
    const arquivoAlias = String($("#endpointArquivoAlias").val() || "").trim();
    if (!url) {
      setStatus("Informe a URL base do endpoint.", "error");
      return;
    }
    const clientId = String((config.selected || {}).clientId || (config.clients[0] || {}).id || "");
    const environmentId = slug(name) + "-" + Date.now();
    config.environments.push({
      id: environmentId,
      clientId,
      name,
      pasoeBaseUrl: url,
      authMode: "none",
      authorization: "",
      companyIdMode: "query",
      extraQueryParams: "",
      servidor,
      usuario,
      senha,
      arquivoPf,
      arquivoAlias
    });
    config.links = Array.isArray(config.links) ? config.links : [];
    if (clientId && !config.links.some((item) => item.clientId === clientId && item.environmentId === environmentId)) {
      config.links.push({
        id: "link-" + slug(clientId + "-" + environmentId),
        clientId,
        environmentId
      });
    }
    currentEnvironmentId = environmentId;
    config.selected = Object.assign({}, config.selected || {}, { clientId, environmentId, companyId: "" });
    $("#endpointName").val("");
    $("#endpointUrl").val("");
    $("#endpointServidor").val("");
    $("#endpointUsuario").val("");
    $("#endpointSenha").val("");
    $("#endpointArquivoPf").val("");
    $("#endpointArquivoAlias").val("");
    refresh();
  }

  function removeEnvironment(event) {
    const item = $("#endpointsGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    const rows = config.environments || [];
    if (!item || rows.length <= 1) {
      setStatus("Mantenha pelo menos um ambiente cadastrado.", "error");
      return;
    }
    config.companies = config.companies.filter((company) => company.environmentId !== item.id);
    config.environments = config.environments.filter((environment) => environment.id !== item.id);
    currentEnvironmentId = (config.environments[0] || {}).id || "";
    currentCompanyId = "";
    refresh();
    setStatus("Ambiente removido.", "ok");
  }

  function addCompany() {
    const environment = currentEnvironment();
    const name = String($("#companyName").val() || "").trim();
    const code = String($("#companyCode").val() || "").trim();
    if (!environment) {
      setStatus("Selecione um ambiente antes de cadastrar a empresa.", "error");
      return;
    }
    if (!code) {
      setStatus("Informe o valor do parametro companyId.", "error");
      return;
    }
    const existing = (config.companies || []).find((item) => {
      return item.environmentId === environment.id && String(item.code || "").toLowerCase() === code.toLowerCase();
    });
    if (existing) {
      existing.name = name || existing.name || ("companyId " + environment.name);
      existing.clientId = existing.clientId || "";
      currentCompanyId = existing.id;
      $("#companyName").val("");
      $("#companyCode").val("");
      refresh();
      setStatus("Empresa do ambiente atualizada.", "ok");
      return;
    }
    const company = {
      id: slug(name || code) + "-" + Date.now(),
      clientId: "",
      environmentId: environment.id,
      name: name || ("companyId " + environment.name),
      code: code
    };
    config.companies.push(company);
    currentCompanyId = company.id;
    $("#companyName").val("");
    $("#companyCode").val("");
    refresh();
    setStatus("Empresa cadastrada no ambiente.", "ok");
  }

  function removeCurrentCompany() {
    const company = currentCompany();
    if (!company) {
      setStatus("Nenhuma empresa selecionada.", "error");
      return;
    }
    removeCompanyById(company.id);
  }

  function removeCompanyRow(event) {
    const item = $("#companiesGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    removeCompanyById(item.id);
  }

  function onCompanyRowSelected(event) {
    const item = $("#companiesGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    currentCompanyId = item.id || "";
    refresh();
  }

  function removeCompanyById(companyId) {
    config.companies = (config.companies || []).filter((item) => item.id !== companyId);
    currentCompanyId = "";
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
})();
