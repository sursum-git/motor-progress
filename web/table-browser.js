(function () {
  const API_URL_KEY = "sursumApiBaseUrl";
  const DEFAULT_API = "http://localhost:8890/web/SursumDynamicQuery";
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  const ENDPOINTS_FILE_NAME = "sursum-endpoints.json";
  const TODOS_DATABASE = "TODOS";
  const HELP_TEXT = "Selecione o banco (ou TODOS) e informe o nome da tabela para carregar os campos, os índices e as relações conhecidas a partir dos arquivos JSON.";

  const state = {
    apiBase: DEFAULT_API,
    endpointConfig: { version: 2, companies: [] },
    companies: [],
    endpoints: [],
    databases: [],
    allDatabases: [{ name: TODOS_DATABASE }],
    tables: [],
    fields: [],
    indexes: [],
    joins: [],
    currentTable: "",
    currentDatabase: "",
    selectedTableRows: []
  };
  let addCompanyWindow = null;
  let addCompanyValidator = null;
  let endpointFileHandle = null;

  $(init);

  function init() {
    $("button").kendoButton();

    loadEndpointConfig()
      .then(function (config) {
        state.endpointConfig = config;
        initializeTableBrowserUi();
        loadMetadata(true);
      })
      .catch(function (error) {
        setStatus("Falha ao carregar endpoints do JSON. Usando dados locais. " + error.message, "error");
        state.endpointConfig = normalizeEndpointConfig(null);
        initializeTableBrowserUi();
        loadMetadata(true);
      });
  }

  function initializeTableBrowserUi() {
    state.companies = state.endpointConfig.companies;
    state.endpoints = endpointsForSelectedCompany();

    $("#apiCompany").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: state.companies,
      change: onApiCompanyChanged
    });
    refreshEndpointCombo(localStorage.getItem(SELECTED_ENDPOINT_KEY));

    $("#dbCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "name",
      filter: "contains",
      dataSource: state.allDatabases
    });
    $("#dbCombo").data("kendoComboBox").value(TODOS_DATABASE);
    $("#tableName").kendoTextBox();

    $("#dbCombo").on("change", onDatabaseChanged);
    $("#tableName").on("keydown", onTableNameKeydown);
    $("#findTableBtn").on("click", onFindTable);
    $("#refreshMetadata").on("click", function () {
      loadMetadata(true, function () {
        setStatus("Metadados atualizados com sucesso.", "ok");
      });
    });
    $("#clearBtn").on("click", clearGrids);
    $("#addCompanyBtn").on("click", openAddCompanyWindow);
    $("#openContextSelector").on("click", function () {
      window.location.href = "context-selector.html";
    });
    $("#openEndpointConfig").on("click", function () {
      window.location.href = "endpoint-config.html";
    });
    $("#saveEndpointFile").on("click", onSaveEndpointFile);

    initTab();
    initGrids();
    initSelectionWindow();
    initAddCompanyWindow();
    initMetadataHelp();
  }

  function initTab() {
    $("#metadataTabs").kendoTabStrip({
      animation: false
    });
    const tabStrip = $("#metadataTabs").data("kendoTabStrip");
    if (tabStrip) {
      tabStrip.select(0);
    }
  }

  function initGrids() {
    $("#fieldsGrid").kendoGrid({
      dataSource: [],
      height: 500,
      sortable: true,
      filterable: true,
      noRecords: { template: "Informe uma tabela para listar campos." },
      columns: [
        { field: "name", title: "Campo", width: 190 },
        { field: "type", title: "Tipo", width: 140 },
        { field: "label", title: "Label", width: 250 },
        { field: "mandatory", title: "Obrig.", width: 85 },
        { field: "extent", title: "Extent", width: 90 },
        { field: "format", title: "Formato", width: 110 },
        { field: "listExpression", title: "listExpression", width: 180 },
        { field: "viewAs", title: "viewAs", width: 240 },
        { field: "optionsSummary", title: "Lista de opções", width: 260 },
        { field: "indices", title: "Índices", width: 220 }
      ]
    });

    $("#indexesGrid").kendoGrid({
      dataSource: [],
      height: 500,
      sortable: true,
      filterable: true,
      noRecords: { template: "Carregue uma tabela para listar índices." },
      columns: [
        { field: "name", title: "Índice", width: 210 },
        { field: "database", title: "Banco", width: 120 },
        { field: "active", title: "Ativo", width: 90 },
        { field: "unique", title: "Único", width: 90 },
        { field: "primary", title: "Prim.", width: 90 },
        { field: "wordIndex", title: "Word idx", width: 110 },
        { field: "wordIndexNumber", title: "Word", width: 90 },
        { field: "fieldsSummary", title: "Campos" }
      ]
    });

    $("#joinsGrid").kendoGrid({
      dataSource: [],
      height: 500,
      sortable: true,
      filterable: true,
      noRecords: { template: "Sem relações encontradas no arquivo JSON para esta tabela." },
      columns: [
        { field: "relationStatus", title: "Status", width: 160 },
        { field: "source", title: "Origem", width: 120 },
        { field: "type", title: "Tipo", width: 110 },
        { field: "localDatabase", title: "Banco", width: 130 },
        { field: "localTable", title: "Tabela local", width: 200 },
        { field: "localField", title: "Campo local", width: 170 },
        { field: "foreignDatabase", title: "Banco estrangeiro", width: 170 },
        { field: "foreignTable", title: "Tabela relacionada", width: 220 },
        { field: "foreignField", title: "Campo relacionado", width: 190 },
        { field: "relationPath", title: "Arquivo", width: 220 },
        { field: "raw", title: "Observação", width: 180 }
      ]
    });

    $("#tableSelectorGrid").kendoGrid({
      dataSource: [],
      height: 240,
      sortable: true,
      filterable: true,
      selectable: "row",
      noRecords: { template: "Nenhuma tabela para escolha." },
      columns: [
        { field: "name", title: "Tabela", width: 170 },
        { field: "database", title: "Banco", width: 150 },
        { field: "label", title: "Label", width: 240 },
        { field: "dumpName", title: "Dump-name", width: 180 }
      ]
    });
  }

  function initSelectionWindow() {
    const selectionWindow = $("#tableSelectorWindow").kendoWindow({
      title: "Selecionar tabela",
      width: "720px",
      height: "460px",
      modal: true,
      visible: false
    }).data("kendoWindow");

    $("#applyTableSelection").off("click").on("click", function () {
      const selectedRow = getSelectedTableCandidate();
      if (!selectedRow) {
        setStatus("Selecione uma das opções.", "error");
        return;
      }
      selectionWindow.close();
      loadSelectedTable(selectedRow);
    });

    $("#cancelTableSelection").off("click").on("click", function () {
      selectionWindow.close();
    });

    $("#tableSelectorGrid").on("dblclick", "tbody tr", function () {
      const grid = $("#tableSelectorGrid").data("kendoGrid");
      const dataItem = grid.dataItem($(this));
      if (!dataItem) return;
      selectionWindow.close();
      loadSelectedTable(dataItem);
    });
  }

  function initMetadataHelp() {
    const helpIcon = $("#metadataHelp");
    if (!helpIcon.length || helpIcon.data("kendoTooltip")) {
      return;
    }

    helpIcon.kendoTooltip({
      content: HELP_TEXT,
      position: "top",
      width: 320,
      showOn: "mouseenter"
    });
  }

  function loadEndpointConfig() {
    return loadEndpointConfigFromFile()
      .catch(function () {
        if (window.SursumContext && typeof SursumContext.getLegacyConfig === "function") {
          return SursumContext.getLegacyConfig();
        }
        return loadEndpointConfigFromStorage();
      })
      .catch(function () {
        return loadEndpointConfigFromStorage();
      })
      .then(function (config) {
        state.endpointConfig = normalizeEndpointConfig(config);
        localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(state.endpointConfig, null, 2));
        return state.endpointConfig;
      });
  }

  function loadEndpointConfigFromFile() {
    return $.ajax({
      url: ENDPOINTS_FILE_NAME,
      dataType: "json",
      cache: false,
      timeout: 2500
    }).then(function (response) {
      const config = normalizeEndpointConfig(response);
      if (!Array.isArray(config.companies) || !config.companies.length) {
        throw new Error("Arquivo vazio ou invalido.");
      }
      return config;
    });
  }

  function loadEndpointConfigFromStorage() {
    let raw = null;
    try {
      raw = JSON.parse(localStorage.getItem(ENDPOINTS_KEY) || "null");
    } catch (_) {}

    return Promise.resolve(normalizeEndpointConfig(raw));
  }

  function normalizeEndpointConfig(raw) {
    if (raw && Array.isArray(raw.companies)) {
      return {
        version: 2,
        companies: normalizeCompanies(raw.companies)
      };
    }

    const endpoints = Array.isArray(raw) ? raw : (raw && Array.isArray(raw.endpoints) ? raw.endpoints : []);
    return {
      version: 2,
      companies: normalizeCompanies([{
        id: "empresa-padrao",
        name: "Empresa padrao",
        isDefault: true,
        endpoints: endpoints.length ? endpoints : [{ id: "local-pasoe", name: "Local PASOE", url: DEFAULT_API, isDefault: true }]
      }])
    };
  }

  function normalizeCompanies(companies) {
    const list = (Array.isArray(companies) ? companies : []).map((company, index) => {
      const companyId = company.id || "empresa-" + index;
      const endpoints = (company.endpoints || []).map((endpoint, endpointIndex) => ({
        ...endpoint,
        companyId,
        id: endpoint.id || "endpoint-" + endpointIndex + "-" + Math.floor(Math.random() * 1e8),
        url: String(endpoint.url || "").replace(/\/+$/, "")
      }));
      if (endpoints.length && !endpoints.some((endpoint) => endpoint.isDefault)) {
        endpoints[0].isDefault = true;
      }
      return {
        id: companyId,
        name: company.name || "Empresa",
        isDefault: !!company.isDefault,
        endpoints
      };
    });

    if (!list.some((company) => company.isDefault) && list[0]) {
      list[0].isDefault = true;
    }
    return list;
  }

  function contextEndpointConfig() {
    if (window.SursumContext && typeof window.SursumContext.getConfig === "function") {
      return window.SursumContext.getConfig();
    }
    return null;
  }

  function companiesForSelection() {
    const config = contextEndpointConfig();
    const environment = currentEnvironment();
    if (config && environment && Array.isArray(config.companies)) {
      return config.companies.filter((item) => item.environmentId === environment.id);
    }
    return state.companies || [];
  }

  function currentClient() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentClient === "function") {
      const client = window.SursumContext.getCurrentClient();
      if (client) {
        return client;
      }
    }

    const config = contextEndpointConfig();
    if (config && Array.isArray(config.clients) && config.clients.length) {
      const selectedId = (config.selected || {}).clientId;
      return config.clients.find((item) => item.id === selectedId) || config.clients[0] || null;
    }

    const selectedId = localStorage.getItem(SELECTED_COMPANY_KEY);
    return (state.companies || []).find((item) => item.id === selectedId) || (state.companies || [])[0] || null;
  }

  function currentEnvironment() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentEnvironment === "function") {
      const environment = window.SursumContext.getCurrentEnvironment();
      if (environment) {
        return environment;
      }
    }

    const selectedId = localStorage.getItem(SELECTED_ENDPOINT_KEY);
    return (state.endpoints || []).find((item) => item.id === selectedId) || (state.endpoints || [])[0] || null;
  }

  function endpointUrl(endpoint) {
    if (!endpoint) {
      return DEFAULT_API;
    }
    return endpoint.pasoeBaseUrl || endpoint.url || DEFAULT_API;
  }

  function companyForEnvironment(environmentId, clientId) {
    const config = contextEndpointConfig();
    if (!config || !Array.isArray(config.companies)) {
      return null;
    }

    const companies = config.companies || [];
    const exact = companies.find((item) => item.environmentId === environmentId && (!clientId || item.clientId === clientId));
    if (exact) {
      return exact;
    }

    if (!environmentId) {
      return companies.find((item) => !clientId || item.clientId === clientId) || companies[0] || null;
    }

    return null;
  }
  function updateContextSummary() {
    const client = currentClient();
    const environment = currentEnvironment();
    const target = $("#contextSummary");
    if (!target.length) return;
    if (!client || !environment) {
      target.text("Selecione o contexto na pagina inicial.");
      return;
    }
    target.text((client.name || client.id) + " / " + (environment.name || environment.id));
  }

  function selectedCompany() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentCompany === "function") {
      const company = window.SursumContext.getCurrentCompany();
      if (company) {
        return company;
      }
    }
    const companies = companiesForSelection();
    const selectedId = localStorage.getItem(SELECTED_COMPANY_KEY);
    return companies.find((item) => item.id === selectedId) || companies[0] || null;
  }

  function endpointsForSelectedCompany() {
    const environment = currentEnvironment();
    return environment ? [environment] : [];
  }

  function refreshEndpointCombo(selectedId) {
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    const companies = companiesForSelection();
    const selected = selectedCompany() || companies[0] || null;

    state.companies = companies;

    if (companyCombo) {
      companyCombo.setDataSource(new kendo.data.DataSource({ data: companies }));
      if (selected && selected.id) {
        companyCombo.value(selected.id);
      }
    }

    state.endpoints = endpointsForSelectedCompany();
    if (selected && selected.id) {
      localStorage.setItem(SELECTED_COMPANY_KEY, selected.id);
    }
    applySelectedEndpoint(selectedId);
    updateContextSummary();
  }

  function onApiCompanyChanged() {
    const companyId = this.value();
    const client = currentClient();
    const environment = currentEnvironment();
    if (companyId) {
      localStorage.setItem(SELECTED_COMPANY_KEY, companyId);
    }
    if (client && environment && window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(client.id, environment.id, companyId || "");
    }
    refreshEndpointCombo(localStorage.getItem(SELECTED_ENDPOINT_KEY));
  }

  function applySelectedEndpoint(explicitId) {
    const endpointId = typeof explicitId === "string" ? explicitId : localStorage.getItem(SELECTED_ENDPOINT_KEY);
    const endpoint = currentEnvironment()
      || (state.endpoints || []).find((item) => item.id === endpointId)
      || (state.endpoints || [])[0]
      || null;

    if (!endpoint) {
      updateContextSummary();
      return;
    }

    state.apiBase = endpointUrl(endpoint);
    $("#apiBaseUrl").val(state.apiBase);
    localStorage.setItem(API_URL_KEY, state.apiBase);
    localStorage.setItem(SELECTED_ENDPOINT_KEY, endpoint.id || "");

    const client = currentClient();
    const clientId = endpoint.clientId || (client && client.id) || "";
    const configuredCompany = companyForEnvironment(endpoint.id, clientId);
    const currentCompanySelection = selectedCompany();
    const preferredCompany = currentCompanySelection && currentCompanySelection.environmentId === endpoint.id
      ? currentCompanySelection
      : configuredCompany;

    if (window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(clientId, endpoint.id || "", preferredCompany ? preferredCompany.id : "");
      const selectedCompany = typeof window.SursumContext.getCurrentCompany === "function"
        ? window.SursumContext.getCurrentCompany()
        : preferredCompany;
      const company = selectedCompany && selectedCompany.environmentId === endpoint.id ? selectedCompany : preferredCompany;
      if (company && company.id) {
        localStorage.setItem(SELECTED_COMPANY_KEY, company.id);
      }
    } else if (endpoint.companyId) {
      localStorage.setItem(SELECTED_COMPANY_KEY, endpoint.companyId);
    }
    updateContextSummary();
  }

  function initAddCompanyWindow() {
    $("#newCompanyName").kendoTextBox();
    $("#newCompanyEndpointName").kendoTextBox();
    $("#newCompanyEndpointUrl").kendoTextBox();
    addCompanyValidator = $("#addCompanyForm").kendoValidator({
      rules: {
        endpointurl: function (input) {
          if (!input.is("[data-endpointurl]")) return true;
          const value = String(input.val() || "").trim();
          if (!value) return false;
          try {
            const url = new URL(value);
            return !!url.protocol && !!url.host;
          } catch (_) {
            return false;
          }
        }
      },
      messages: {
        required: "Campo obrigatório.",
        endpointurl: "Informe uma URL válida, por exemplo: http://localhost:8890/web/SursumDynamicQuery."
      }
    }).data("kendoValidator");

    addCompanyWindow = $("#addCompanyWindow").kendoWindow({
      title: "Nova empresa",
      width: "560px",
      modal: true,
      visible: false,
      close: function () {
        $("#addCompanyForm")[0].reset();
      }
    }).data("kendoWindow");

    $("#confirmAddCompany").off("click").on("click", function () {
      addCompanyFromBrowserForm();
    });

    $("#cancelAddCompany").off("click").on("click", function () {
      addCompanyWindow && addCompanyWindow.close();
    });
  }

  function openAddCompanyWindow() {
    if (!addCompanyWindow) {
      return;
    }

    $("#newCompanyName").val("");
    $("#newCompanyEndpointName").val("Local PASOE");
    $("#newCompanyEndpointUrl").val(state.apiBase || DEFAULT_API);
    if (addCompanyValidator) {
      addCompanyValidator.hideMessages();
    }
    $("#addCompanyForm").find(".k-invalid").removeClass("k-invalid");
    addCompanyWindow.center().open();
  }

  function addCompanyFromBrowserForm() {
    if (!addCompanyValidator || !addCompanyValidator.validate()) {
      setStatus("Corrija os campos em vermelho antes de salvar.", "error");
      return;
    }

    const companyName = String($("#newCompanyName").val() || "").trim();
    if (!companyName) {
      setStatus("Informe o nome da empresa.", "error");
      return;
    }

    const endpointName = String($("#newCompanyEndpointName").val() || "Endpoint PASOE").trim();
    const endpointUrl = String($("#newCompanyEndpointUrl").val() || "").trim().replace(/\/+$/, "");
    if (!endpointUrl) {
      setStatus("Informe a URL do endpoint.", "error");
      return;
    }

    const normalized = normalizeEndpointConfig(state.endpointConfig);
    if (normalized.companies.some((company) => String(company.name || "").toLowerCase() === companyName.toLowerCase())) {
      setStatus("Já existe uma empresa com esse nome.", "error");
      return;
    }

    const companyId = slugify(companyName) + "-" + Date.now();
    const endpointId = "endpoint-" + Date.now();

    const company = {
      id: companyId,
      name: companyName,
      isDefault: !normalized.companies.length,
      endpoints: [{
        id: endpointId,
        name: endpointName,
        url: endpointUrl,
        isDefault: true
      }]
    };

    normalized.companies.push(company);
    state.endpointConfig = normalizeEndpointConfig(normalized);
    state.companies = state.endpointConfig.companies;
    persistEndpointConfig()
      .then(() => {
        localStorage.setItem(SELECTED_COMPANY_KEY, companyId);
        refreshEndpointCombo();
        addCompanyWindow && addCompanyWindow.close();
        setStatus("Empresa adicionada: " + companyName, "ok");
      })
      .catch((error) => {
        setStatus("Erro ao salvar arquivo JSON dos endpoints: " + error.message, "error");
      });
  }

  function onSaveEndpointFile() {
    persistEndpointConfig()
      .then(function () {
        setStatus("Arquivo JSON dos endpoints salvo com sucesso.", "ok");
      })
      .catch(function (error) {
        setStatus("Falha ao salvar JSON: " + error.message, "error");
      });
  }

  function persistEndpointConfig() {
    state.endpointConfig = normalizeEndpointConfig(state.endpointConfig);
    const payload = JSON.stringify(state.endpointConfig, null, 2);
    localStorage.setItem(ENDPOINTS_KEY, payload);
    return saveEndpointConfigFile(payload);
  }

  function saveEndpointConfigFile(payload) {
    if (window.showSaveFilePicker) {
      return saveEndpointConfigWithPicker(payload);
    }

    downloadEndpointConfigFile(payload);
    return Promise.resolve();
  }

  function saveEndpointConfigWithPicker(payload) {
    return window.showSaveFilePicker({
      suggestedName: ENDPOINTS_FILE_NAME,
      types: [{
        description: "Arquivos JSON",
        accept: {
          "application/json": [".json"]
        }
      }]
    })
      .then(function (handle) {
        endpointFileHandle = handle;
        return endpointFileHandle.createWritable();
      })
      .then(function (writer) {
        return writer.write(payload).then(function () {
          return writer.close();
        });
      })
      .then(function () {
        return Promise.resolve();
      })
      .catch(function (error) {
        if (error && error.name === "AbortError") {
          return Promise.resolve();
        }
        downloadEndpointConfigFile(payload);
        return Promise.resolve();
      });
  }

  function downloadEndpointConfigFile(payload) {
    const blob = new Blob([payload], {
      type: "application/json;charset=utf-8"
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = ENDPOINTS_FILE_NAME;
    anchor.click();
    URL.revokeObjectURL(url);
  }

  function slugify(value) {
    return String(value || "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      || "empresa";
  }

  function onDatabaseChanged() {
    const db = selectedDatabase();
    if (!db) {
      return;
    }

    clearGrids();

    loadTablesForDatabase(db, function () {
      const msg = db === TODOS_DATABASE
        ? "Base selecionada: todos os bancos."
        : `Base selecionada: ${db}.`;
      setStatus(msg, "ok");
    });
  }

  function onTableNameKeydown(event) {
    if (event.key === "Enter") {
      onFindTable();
    }
  }

  function onFindTable() {
    const typed = String($("#tableName").val() || "").trim();
    if (!typed) {
      setStatus("Informe o nome da tabela.", "error");
      return;
    }

    const database = selectedDatabase();
    const typedLower = typed.toLowerCase();

    const candidates = state.tables.filter((row) => {
      const sameName = String(row.name || "").toLowerCase() === typedLower;
      const inDatabase = database === TODOS_DATABASE || !row.database || row.database === database;
      return sameName && inDatabase;
    });

    if (!candidates.length) {
      setStatus(`Tabela não encontrada: ${typed}` + (database === TODOS_DATABASE ? "" : ` em ${database}`), "error");
      return;
    }

    if (candidates.length === 1) {
      loadSelectedTable(candidates[0]);
      return;
    }

    state.selectedTableRows = candidates.slice();
    const grid = $("#tableSelectorGrid").data("kendoGrid");
    grid.dataSource.data(state.selectedTableRows);
    const selectionWindow = $("#tableSelectorWindow").data("kendoWindow");
    selectionWindow.center().open();
  }

  function loadMetadata(forceReload, done) {
    loadDatabases(function () {
      if (forceReload) {
        setStatus("Carregando metadados da base selecionada...", "");
      }
      loadTablesForDatabase(selectedDatabase(), done);
    });
  }

  function loadDatabases(done) {
    const url = `${state.apiBase}/metadata/databases`;

    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }

        const rows = Array.isArray(response.data) ? response.data : [];
        state.databases = rows.map((item) => ({
          name: item.name || item.logicalName || item.displayName || "",
          logicalName: item.logicalName || item.name || ""
        }));

        state.allDatabases = [{ name: TODOS_DATABASE }].concat(state.databases);
        refreshDatabaseCombo();

        if (typeof done === "function") {
          done();
        }
      })
      .fail(function () {
        state.databases = [];
        state.allDatabases = [{ name: TODOS_DATABASE }];
        refreshDatabaseCombo();
        setStatus("Falha ao carregar lista de bancos.", "error");
        if (typeof done === "function") {
          done();
        }
      });
  }

  function loadTablesForDatabase(database, done) {
    const db = database === TODOS_DATABASE ? TODOS_DATABASE : database;
    const url = `${state.apiBase}/metadata/tables?database=${encodeURIComponent(db)}`;

    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }

        state.tables = Array.isArray(response.data) ? response.data : [];

        if (typeof done === "function") {
          done();
        }
      })
      .fail(function () {
        state.tables = [];
        if (typeof done === "function") {
          done();
        }
      });
  }

  function refreshDatabaseCombo() {
    const combo = $("#dbCombo").data("kendoComboBox");
    if (!combo) return;

    combo.setDataSource(new kendo.data.DataSource({ data: state.allDatabases }));
    const current = selectedDatabase();
    combo.value(current || TODOS_DATABASE);
  }

  function selectedDatabase() {
    const combo = $("#dbCombo").data("kendoComboBox");
    return combo ? combo.value() : TODOS_DATABASE;
  }

  function getSelectedTableCandidate() {
    const grid = $("#tableSelectorGrid").data("kendoGrid");
    const selected = grid.select();
    if (!selected || !selected.length) return null;
    return grid.dataItem(selected);
  }

  function loadSelectedTable(item) {
    if (!item || !item.name) {
      setStatus("Seleção de tabela inválida.", "error");
      return;
    }

    const table = item.name;
    const dbFromSelection = item.database || selectedDatabase();
    const finalDatabase = dbFromSelection === TODOS_DATABASE ? null : dbFromSelection;
    const params = finalDatabase ? `?database=${encodeURIComponent(finalDatabase)}` : "";
    const url = `${state.apiBase}/metadata/tables/${encodeURIComponent(table)}/fields${params}`;

    setStatus(`Carregando metadados de ${table}${finalDatabase ? ` (${finalDatabase})` : ""}...`, "");

    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }

        state.currentTable = table;
        state.currentDatabase = response.database || finalDatabase || "";
        state.fields = Array.isArray(response.fields) ? response.fields : [];
        state.indexes = Array.isArray(response.indices) ? response.indices : [];

        renderFieldGrid();
        renderIndexGrid();
        $("#resultSummary").text(`Tabela selecionada: ${state.currentDatabase}.${state.currentTable}`);

        loadJoins(state.currentTable, state.currentDatabase)
          .done(function (joins) {
            state.joins = Array.isArray(joins) ? joins : [];
            renderJoinGrid();
            setStatus(
              `Carregamento concluído: ${state.fields.length} campos, ${state.indexes.length} índices, ${state.joins.length} relações.`,
              "ok"
            );
          });
      })
      .fail(function (xhr) {
        setStatus(`Falha ao carregar tabela: ${xhr.status} ${xhr.statusText}`, "error");
      });
  }

  function loadJoins(table, database) {
    return loadJoinsByRelationFiles(table, database);
  }

  function loadJoinsByRelationFiles(table, database) {
    const dbFilter = database ? `&database=${encodeURIComponent(database)}` : "";
    const url = `${state.apiBase}/metadata/relations?table=${encodeURIComponent(table)}${dbFilter}`;
    const deferred = $.Deferred();

    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false || !Array.isArray(response.data)) {
          deferred.resolve([]);
          return;
        }

        const rows = response.data
          .map((item) => mapRelationFileItemToGrid(item, table, database))
          .filter(Boolean);
        deferred.resolve(rows);
      })
      .fail(function () {
        deferred.resolve([]);
      });

    return deferred.promise();
  }

  function mapRelationFileItemToGrid(item, localTable, localDatabase) {
    if (!item) return null;

    const localMatchesLeft = sameName(item.leftTable, localTable);
    const localMatchesRight = sameName(item.rightTable, localTable);

    if (!localMatchesLeft && !localMatchesRight) {
      return null;
    }

    if (localMatchesLeft) {
      return {
        relationStatus: "Encontrada",
        source: "Arquivo JSON",
        raw: item.raw || "",
        type: item.type || "INNER",
        localDatabase: item.leftDatabase || localDatabase || "",
        localTable,
        localField: item.leftField || "",
        foreignDatabase: item.rightDatabase || localDatabase || "",
        foreignTable: item.rightTable || "",
        foreignField: item.rightField || "",
        relationPath: item.path || item.fileName || "",
        fields: Array.isArray(item.fields) ? item.fields : []
      };
    }

    return {
      relationStatus: "Encontrada",
      source: "Arquivo JSON",
      raw: item.raw || "",
      type: item.type || "INNER",
      localDatabase: item.rightDatabase || localDatabase || "",
      localTable,
      localField: item.rightField || "",
      foreignDatabase: item.leftDatabase || localDatabase || "",
      foreignTable: item.leftTable || "",
      foreignField: item.leftField || "",
      relationPath: item.path || item.fileName || "",
      fields: Array.isArray(item.fields) ? item.fields : []
    };
  }

  function renderFieldGrid() {
    const grid = $("#fieldsGrid").data("kendoGrid");
    if (!grid) return;

    const rows = state.fields.map((field) => ({
      name: field.name || "",
      type: field.type || "",
      label: field.label || "",
      mandatory: !!field.mandatory,
      extent: field.extent,
      format: field.format || "",
      listExpression: field.listExpression || "",
      viewAs: field.viewAs || "",
      optionsSummary: formatFieldOptions(field.options || []),
      indices: Array.isArray(field.indices) ? field.indices.join(", ") : (field.indices || "")
    }));

    grid.dataSource.data(rows);
  }

  function formatFieldOptions(options) {
    if (!Array.isArray(options) || !options.length) {
      return "";
    }

    return options
      .map((option) => {
        if (!option) return "";
        if (typeof option === "string") {
          return option;
        }
        const value = option.value !== undefined ? String(option.value) : "";
        const label = option.label !== undefined ? String(option.label) : "";
        if (value && label) {
          return `${label} (${value})`;
        }
        return label || value;
      })
      .filter(Boolean)
      .join(", ");
  }

  function renderIndexGrid() {
    const grid = $("#indexesGrid").data("kendoGrid");
    if (!grid) return;

    const rows = (state.indexes || []).map((item) => ({
      name: item.name || "",
      database: state.currentDatabase || "",
      active: !!item.active,
      unique: !!item.unique,
      primary: !!item.primary,
      wordIndex: !!item.wordIndex,
      wordIndexNumber: item.wordIndexNumber || 0,
      fieldsSummary: formatIndexFields(item.fields || [])
    }));

    grid.dataSource.data(rows);
  }

  function renderJoinGrid() {
    const grid = $("#joinsGrid").data("kendoGrid");
    if (!grid) return;

    const rows = (state.joins || []).map((item) => ({
      relationStatus: item.relationStatus || "",
      source: item.source || "",
      type: item.type || "",
      localDatabase: item.localDatabase || "",
      localTable: item.localTable || "",
      localField: item.localField || "",
      foreignDatabase: item.foreignDatabase || "",
      foreignTable: item.foreignTable || "",
      foreignField: item.foreignField || "",
      relationPath: item.relationPath || "",
      raw: item.raw || ""
    }));

    grid.dataSource.data(rows);
  }

  function sameName(a, b) {
    return String(a || "").toLowerCase() === String(b || "").toLowerCase();
  }

  function formatIndexFields(fields) {
    if (!Array.isArray(fields)) return "";
    return fields
      .map((item) => (item && item.name ? item.name : ""))
      .filter(Boolean)
      .join(", ");
  }

  function clearGrids() {
    state.currentTable = "";
    state.currentDatabase = "";
    state.fields = [];
    state.indexes = [];
    state.joins = [];

    $("#fieldsGrid").data("kendoGrid").dataSource.data([]);
    $("#indexesGrid").data("kendoGrid").dataSource.data([]);
    $("#joinsGrid").data("kendoGrid").dataSource.data([]);
    $("#resultSummary").text("Selecione banco e tabela para carregar os metadados.");
    setStatus("Pronto.", "");
  }

  function apiError(response) {
    if (!response || !response.error) {
      return "erro desconhecido";
    }
    if (response.error.message) {
      return response.error.message;
    }
    if (response.error.code) {
      return response.error.code;
    }
    return "erro do servidor";
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "");
    $("#statusBox").text(message);
  }
})();
