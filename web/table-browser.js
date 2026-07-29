(function () {
  const API_URL_KEY = "sursumApiBaseUrl";
  const DEFAULT_API = "http://localhost:8890/web/SursumDynamicQuery";
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  const QUERY_COMPANY_KEY = "sursumQueryCompanyId";
  const ENDPOINTS_FILE_NAME = "sursum-endpoints.json";
  const PASOE_PROXY = "pasoe-proxy.php";
  const TODOS_DATABASE = "TODOS";
  const HELP_TEXT = "Selecione o banco (ou TODOS) e informe o nome da tabela para carregar campos, índices e relações salvas no SQLite.";

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
    selectedTableRows: [],
    browseCursor: null,
    browseHasMore: false
  };
  let addCompanyWindow = null;
  let addCompanyValidator = null;
  let endpointFileHandle = null;
  let uiReady = false;

  $(init);

  function init() {
    $("button").kendoButton();
    window.addEventListener("sursum:context-changed", onSursumContextChanged);

    loadEndpointConfig()
      .then(function (config) {
        state.endpointConfig = config;
        initializeTableBrowserUi();
        loadDatabasesWhenEndpointReady();
        setTimeout(loadDatabasesWhenEndpointReady, 750);
      })
      .catch(function (error) {
        setStatus("Falha ao carregar endpoints do JSON. Usando dados locais. " + error.message, "error");
        state.endpointConfig = normalizeEndpointConfig(null);
        initializeTableBrowserUi();
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
    $("#openTableSelector").on("click", openTableSelectorFromButton);
    $("#findTableBtn").on("click", onFindTable);
    $("#refreshMetadata").on("click", function () {
      syncMetadata();
    });
    $("#refreshCurrentJoins").on("click", refreshCurrentTableJoinsOf);
    $("#clearBtn").on("click", clearGrids);
    initBrowseControls();
    initTab();
    initGrids();
    initSelectionWindow();
    initAddCompanyWindow();
    initMetadataHelp();
    uiReady = true;
    if (window.SursumUiReady) window.SursumUiReady();
  }

  function onSursumContextChanged() {
    if (!uiReady) {
      return;
    }
    loadDatabasesWhenEndpointReady();
  }

  function loadDatabasesWhenEndpointReady() {
    syncEndpointStateFromContext();
    if (!state.apiBase || state.apiBase === DEFAULT_API) {
      setStatus("Pronto.", "");
      return;
    }
    loadDatabases(false, function (success) {
      if (success) {
        setStatus("Lista de bancos carregada.", "ok");
      }
    });
  }

  function syncEndpointStateFromContext() {
    if (!window.SursumContext || typeof SursumContext.getLegacyConfig !== "function") {
      return;
    }
    state.endpointConfig = normalizeEndpointConfig(SursumContext.getLegacyConfig());
    state.companies = state.endpointConfig.companies;
    state.endpoints = endpointsForSelectedCompany();
    refreshEndpointCombo(localStorage.getItem(SELECTED_ENDPOINT_KEY));
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
      noRecords: { template: "Sem relações cadastradas no SQLite para esta tabela." },
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
        { field: "relationPath", title: "Atualizado em", width: 220 },
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

    $("#dataGrid").kendoGrid({
      dataSource: [],
      height: 500,
      sortable: true,
      filterable: true,
      resizable: true,
      noRecords: { template: "Carregue uma tabela e clique em carregar primeiros." },
      columns: []
    });
  }

  function initBrowseControls() {
    $("#browsePageSize").kendoNumericTextBox({
      min: 1,
      max: 500,
      step: 25,
      decimals: 0,
      format: "n0",
      value: 50
    });
    $("#browseDirection").kendoDropDownList({
      dataSource: [
        { text: "Crescente", value: "ASC" },
        { text: "Decrescente", value: "DESC" }
      ],
      dataTextField: "text",
      dataValueField: "value",
      value: "ASC"
    });
    $("#browseFields").kendoMultiSelect({
      dataTextField: "text",
      dataValueField: "value",
      autoClose: false,
      placeholder: "Campos padrão"
    });
    $("#browseFirstBtn").on("click", function () {
      loadBrowsePage(false);
    });
    $("#browseNextBtn").on("click", function () {
      loadBrowsePage(true);
    });
    $("#browseInvertBtn").on("click", invertBrowseDirection);
    updateBrowseState();
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
    return Promise.resolve()
      .then(function () {
        if (window.SursumContext && typeof SursumContext.getLegacyConfig === "function") {
          return SursumContext.getLegacyConfig();
        }
        return loadEndpointConfigFromFile().catch(loadEndpointConfigFromStorage);
      })
      .then(function (config) {
        state.endpointConfig = normalizeEndpointConfig(config);
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
    if (window.SursumContext && typeof window.SursumContext.resolveApiBase === "function") {
      return window.SursumContext.resolveApiBase(endpoint, selectedCompany()) || DEFAULT_API;
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
    return;
  }

  function selectedCompany() {
    const companies = companiesForSelection();
    const selectedId = localStorage.getItem(QUERY_COMPANY_KEY) || localStorage.getItem(SELECTED_COMPANY_KEY);
    const selected = companies.find((item) => item.id === selectedId);
    if (selected) return selected;
    if (window.SursumContext && typeof window.SursumContext.getCurrentCompany === "function") {
      const company = window.SursumContext.getCurrentCompany();
      if (company && companies.some((item) => item.id === company.id)) return company;
    }
    return companies[0] || null;
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
      localStorage.setItem(QUERY_COMPANY_KEY, selected.id);
    }
    applySelectedEndpoint(selectedId);
    updateContextSummary();
  }

  function onApiCompanyChanged() {
    const companyId = this.value();
    const client = currentClient();
    const environment = currentEnvironment();
    if (companyId) {
      localStorage.setItem(QUERY_COMPANY_KEY, companyId);
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

    const company = preferredCompany || currentCompanySelection || configuredCompany;
    if (company && company.id && !localStorage.getItem(QUERY_COMPANY_KEY)) {
      localStorage.setItem(QUERY_COMPANY_KEY, company.id);
    } else if (endpoint.companyId && !localStorage.getItem(QUERY_COMPANY_KEY)) {
      localStorage.setItem(QUERY_COMPANY_KEY, endpoint.companyId);
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
    if (window.SursumContext && typeof SursumContext.applyLegacyConfig === "function") {
      SursumContext.applyLegacyConfig(state.endpointConfig);
      return Promise.resolve();
    }
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

    ensureTablesLoaded(function () {
      findTableFromLoadedList(typed);
    });
  }

  function findTableFromLoadedList(typed) {
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
    showTableSelector(state.selectedTableRows, "Foram encontradas várias tabelas com esse nome. Selecione a desejada:");
  }

  function openTableSelectorFromButton(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    ensureTablesLoaded(openTableSelectorFromLoadedList);
  }

  function openTableSelectorFromLoadedList() {
    const typed = String($("#tableName").val() || "").trim().toLowerCase();
    const database = selectedDatabase();
    let rows = state.tables.filter((row) => database === TODOS_DATABASE || !row.database || row.database === database);

    if (typed) {
      rows = rows.filter((row) => {
        const name = String(row.name || "").toLowerCase();
        const label = String(row.label || "").toLowerCase();
        const dumpName = String(row.dumpName || "").toLowerCase();
        return name.includes(typed) || label.includes(typed) || dumpName.includes(typed);
      });
    }

    if (!rows.length) {
      setStatus(typed ? `Nenhuma tabela encontrada contendo: ${typed}` : "Nenhuma tabela disponível para seleção.", "error");
      return;
    }

    showTableSelector(rows, typed ? "Selecione uma das tabelas filtradas:" : "Selecione uma tabela disponível:");
  }

  function ensureTablesLoaded(done) {
    if (state.tables.length) {
      if (typeof done === "function") done();
      return;
    }

    setStatus("Carregando lista de tabelas...", "");
    loadTablesForDatabase(selectedDatabase(), function () {
      if (!state.tables.length) {
        setStatus("Nenhuma tabela disponível. Atualize os metadados ou verifique o endpoint.", "error");
        return;
      }
      if (typeof done === "function") done();
    });
  }

  function showTableSelector(rows, message) {
    state.selectedTableRows = rows.slice();
    $("#tableSelectorMessage").text(message || "Selecione uma tabela disponível:");
    const grid = $("#tableSelectorGrid").data("kendoGrid");
    grid.dataSource.data(state.selectedTableRows);
    const selectionWindow = $("#tableSelectorWindow").data("kendoWindow");
    selectionWindow.center().open();
  }

  function loadMetadata(forceReload, done) {
    if (forceReload) {
      syncMetadata(done);
      return;
    }
    loadDatabases(false, function () {
      loadTablesForDatabase(selectedDatabase(), done);
    });
  }

  function syncMetadata(done) {
    const url = buildMetadataSyncUrl();
    const include = selectedSyncIncludes();
    setRefreshMetadataBusy(true);
    setStatus(`Atualizando metadados (${include.join(", ")})...`, "");
    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false) {
          setStatus("Falha ao sincronizar metadados: " + apiError(response), "error");
          if (typeof done === "function") {
            done(null);
          }
          return;
        }
        loadDatabases(false, function () {
          loadTablesForDatabase(selectedDatabase(), function () {
            const count = response && Array.isArray(response.steps) ? response.steps.length : 0;
            setStatus(`Metadados atualizados. Etapas executadas: ${count}.`, "ok");
            if (typeof done === "function") {
              done(response);
            }
            setRefreshMetadataBusy(false);
          });
        });
      })
      .fail(function (xhr) {
        setStatus("Falha ao sincronizar metadados: " + ajaxErrorMessage(xhr), "error");
        if (typeof done === "function") {
          done(null);
        }
        setRefreshMetadataBusy(false);
      });
  }

  function setRefreshMetadataBusy(isBusy) {
    const button = $("#refreshMetadata").data("kendoButton");
    if (button) {
      button.enable(!isBusy);
      button.element.find(".k-button-text").text(isBusy ? "Atualizando..." : "Atualizar metadados");
      if (!button.element.find(".k-button-text").length) {
        button.element.text(isBusy ? "Atualizando..." : "Atualizar metadados");
      }
    } else {
      $("#refreshMetadata").prop("disabled", !!isBusy).text(isBusy ? "Atualizando..." : "Atualizar metadados");
    }
  }

  function ajaxErrorMessage(xhr) {
    if (!xhr) {
      return "erro desconhecido";
    }
    if (xhr.responseJSON) {
      return apiError(xhr.responseJSON);
    }
    const body = String(xhr.responseText || "").trim();
    const status = [xhr.status, xhr.statusText].filter(Boolean).join(" ");
    if (body) {
      return (status ? status + " - " : "") + body.slice(0, 300);
    }
    if (!xhr.status || xhr.status === 0 || xhr.statusText === "error") {
      return "erro de rede ao acessar o PASOE. Verifique se o endpoint esta acessivel pelo servidor web, se o certificado HTTPS interno e valido e se o PASOE esta respondendo.";
    }
    return status || "erro desconhecido";
  }

  function pasoeUrl(path, options) {
    const base = String(state.apiBase || "").replace(/\/+$/, "");
    const suffix = String(path || "").replace(/^\/+/, "");
    let target = base + "/" + suffix;
    if (window.SursumContext && typeof window.SursumContext.getRequestConfig === "function") {
      const request = window.SursumContext.getRequestConfig(target, options || {});
      target = request && request.url ? request.url : target;
    }
    return shouldUsePasoeProxy(target) ? PASOE_PROXY + "?target=" + encodeURIComponent(target) : target;
  }

  function shouldUsePasoeProxy(url) {
    try {
      const parsed = new URL(url, window.location.href);
      return /^https?:$/.test(parsed.protocol) && parsed.origin !== window.location.origin;
    } catch (error) {
      return false;
    }
  }

  function buildMetadataSyncUrl() {
    const include = selectedSyncIncludes();
    const params = [`include=${encodeURIComponent(include.join(","))}`];
    const database = selectedDatabase();
    const table = String($("#tableName").val() || "").trim();
    if (database && database !== TODOS_DATABASE) {
      params.push(`database=${encodeURIComponent(database)}`);
    }
    if (table) {
      params.push(`table=${encodeURIComponent(table)}`);
    }
    return pasoeUrl(`/metadata/sync?${params.join("&")}`);
  }

  function selectedSyncIncludes() {
    const options = [];
    if ($("#syncBanks").is(":checked")) options.push("banks");
    if ($("#syncAliases").is(":checked")) options.push("aliases");
    if ($("#syncTables").is(":checked")) options.push("tables");
    if ($("#syncFields").is(":checked")) options.push("fields");
    if ($("#syncIndices").is(":checked")) options.push("indices");
    if ($("#syncViewAs").is(":checked")) options.push("view-as");
    return options.length ? options : ["banks", "aliases", "tables"];
  }

  function loadDatabases(forceReload, done) {
    if (typeof forceReload === "function") {
      done = forceReload;
      forceReload = false;
    }
    const url = pasoeUrl(forceReload ? "/metadata/databases/sync" : "/metadata/database-catalog");

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
          done(true);
        }
      })
      .fail(function (xhr) {
        state.databases = [];
        state.allDatabases = [{ name: TODOS_DATABASE }];
        refreshDatabaseCombo();
        setStatus("Falha ao carregar lista de bancos em " + state.apiBase + ": " + ajaxErrorMessage(xhr), "error");
        if (typeof done === "function") {
          done(false);
        }
      });
  }

  function loadTablesForDatabase(database, done) {
    const db = database === TODOS_DATABASE ? TODOS_DATABASE : database;
    const url = pasoeUrl(`/metadata/tables?database=${encodeURIComponent(db)}`);

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
    const url = pasoeUrl(`/metadata/tables/${encodeURIComponent(table)}/fields${params}`);

    $("#tableName").val(table);
    setStatus(`Carregando metadados de ${table}${finalDatabase ? ` (${finalDatabase})` : ""}...`, "");

    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }

        state.currentTable = table;
        state.currentDatabase = response.database || finalDatabase || "";
        const baseFields = fieldsFromMetadataResponse(response);
        state.indexes = indexesFromMetadataResponse(response, baseFields);
        state.browseCursor = null;
        state.browseHasMore = false;

        loadViewAsOverrides(table, state.currentDatabase)
          .then(function (overrides) {
            state.fields = applyViewAsOverrides(baseFields, overrides);
            renderFieldGrid();
            renderIndexGrid();
            refreshBrowseFieldSelector();
            clearBrowseGrid();
            $("#resultSummary").text(`Tabela selecionada: ${state.currentDatabase}.${state.currentTable}`);
            return loadJoins(state.currentTable, state.currentDatabase);
          })
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
        setStatus("Falha ao carregar tabela: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function loadJoins(table, database) {
    return loadJoinsFromSqlite(table, database);
  }

  function loadViewAsOverrides(table, database) {
    const deferred = $.Deferred();
    $.getJSON(metadataStoreUrl(table, database))
      .done(function (response) {
        deferred.resolve(response && response.success && Array.isArray(response.data) ? response.data : []);
      })
      .fail(function () {
        deferred.resolve([]);
      });
    return deferred.promise();
  }

  function applyViewAsOverrides(fields, overrides) {
    const byField = {};
    (Array.isArray(overrides) ? overrides : []).forEach(function (row) {
      const field = String(row.field || row.name || "").toLowerCase();
      if (field) byField[field] = row.viewAs || row.view_as || "";
    });
    return (fields || []).map(function (field) {
      const key = String(field.name || "").toLowerCase();
      if (!Object.prototype.hasOwnProperty.call(byField, key)) return field;
      return Object.assign({}, field, { viewAs: byField[key], viewAS: byField[key], view_as: byField[key] });
    });
  }

  function metadataStoreUrl(table, database) {
    const scope = relationScope(table, database);
    return "metadata-store.php?resource=view-as"
      + "&environmentId=" + encodeURIComponent(scope.environmentId)
      + "&companyId=" + encodeURIComponent(scope.companyId)
      + "&database=" + encodeURIComponent(scope.database)
      + "&table=" + encodeURIComponent(scope.table);
  }

  function loadJoinsFromSqlite(table, database) {
    const deferred = $.Deferred();
    const url = relationStoreUrl(table, database);

    $.getJSON(url)
      .done(function (response) {
        if (!response || response.success === false || !Array.isArray(response.data)) {
          deferred.resolve([]);
          return;
        }

        const rows = response.data
          .map((item) => mapRelationItemToGrid(item, table, database))
          .filter(Boolean);
        deferred.resolve(rows);
      })
      .fail(function () {
        deferred.resolve([]);
      });

    return deferred.promise();
  }

  function refreshCurrentTableJoinsOf() {
    if (!state.currentTable || !state.currentDatabase) {
      setStatus("Carregue uma tabela antes de atualizar joins OF.", "error");
      return;
    }

    setRefreshCurrentJoinsBusy(true);
    setStatus(`Atualizando joins OF de ${state.currentDatabase}.${state.currentTable}...`, "");
    $.getJSON(pasoeUrl(`/metadata/relations/of?table=${encodeURIComponent(state.currentTable)}&database=${encodeURIComponent(state.currentDatabase)}`))
      .done(function (response) {
        if (!response || response.success === false || !Array.isArray(response.data)) {
          setStatus("Falha ao atualizar joins OF: " + apiError(response), "error");
          return;
        }
        saveJoinsToSqlite(state.currentTable, state.currentDatabase, response.data)
          .done(function (saved) {
            const rows = ((saved && saved.data) || response.data)
              .map((item) => mapRelationItemToGrid(item, state.currentTable, state.currentDatabase))
              .filter(Boolean);
            state.joins = rows;
            renderJoinGrid();
            setStatus(`Joins OF atualizados: ${rows.length} relações.`, "ok");
          })
          .fail(function (xhr) {
            setStatus("Falha ao gravar joins no SQLite: " + ajaxErrorMessage(xhr), "error");
          });
      })
      .fail(function (xhr) {
        setStatus("Falha ao atualizar joins OF: " + ajaxErrorMessage(xhr), "error");
      })
      .always(function () {
        setRefreshCurrentJoinsBusy(false);
      });
  }

  function saveJoinsToSqlite(table, database, relations) {
    return $.ajax({
      url: "relation-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(relationScope(table, database), {
        source: "OF",
        relations
      }))
    });
  }

  function relationStoreUrl(table, database) {
    const scope = relationScope(table, database);
    return "relation-store.php?"
      + "environmentId=" + encodeURIComponent(scope.environmentId)
      + "&companyId=" + encodeURIComponent(scope.companyId)
      + "&database=" + encodeURIComponent(scope.database)
      + "&table=" + encodeURIComponent(scope.table);
  }

  function relationScope(table, database) {
    const environment = window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function"
      ? SursumContext.getCurrentEnvironment()
      : null;
    const company = window.SursumContext && typeof SursumContext.getCurrentCompany === "function"
      ? SursumContext.getCurrentCompany()
      : null;
    return {
      environmentId: environment && environment.id ? environment.id : "",
      companyId: company && company.id ? company.id : "",
      database: database || "",
      table: table || ""
    };
  }

  function setRefreshCurrentJoinsBusy(isBusy) {
    const button = $("#refreshCurrentJoins").data("kendoButton");
    if (button) {
      button.enable(!isBusy);
      button.element.find(".k-button-text").text(isBusy ? "Atualizando..." : "Atualizar joins OF");
    } else {
      $("#refreshCurrentJoins").prop("disabled", !!isBusy).text(isBusy ? "Atualizando..." : "Atualizar joins OF");
    }
  }

  function mapRelationItemToGrid(item, localTable, localDatabase) {
    if (!item) return null;

    const localMatchesLeft = sameName(item.leftTable, localTable);
    const localMatchesRight = sameName(item.rightTable, localTable);

    if (!localMatchesLeft && !localMatchesRight) {
      return null;
    }

    if (localMatchesLeft) {
      return {
        relationStatus: "Encontrada",
        source: item.source || "SQLite",
        raw: item.raw || "",
        type: item.type || "INNER",
        localDatabase: item.leftDatabase || localDatabase || "",
        localTable,
        localField: item.leftField || "",
        foreignDatabase: item.rightDatabase || localDatabase || "",
        foreignTable: item.rightTable || "",
        foreignField: item.rightField || "",
        relationPath: item.updatedAt || item.path || item.fileName || "",
        fields: Array.isArray(item.fields) ? item.fields : []
      };
    }

    return {
      relationStatus: "Encontrada",
      source: item.source || "SQLite",
      raw: item.raw || "",
      type: item.type || "INNER",
      localDatabase: item.rightDatabase || localDatabase || "",
      localTable,
      localField: item.rightField || "",
      foreignDatabase: item.leftDatabase || localDatabase || "",
      foreignTable: item.leftTable || "",
      foreignField: item.leftField || "",
      relationPath: item.updatedAt || item.path || item.fileName || "",
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
      viewAs: field.viewAs || field.viewAS || field.view_as || field.view || "",
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

  function refreshBrowseFieldSelector() {
    const multi = $("#browseFields").data("kendoMultiSelect");
    if (!multi) return;

    const options = [];
    (state.fields || []).forEach((field) => {
      const name = field.name || "";
      if (!name) return;
      const extent = Number(field.extent || 0);
      if (extent > 0) {
        for (let index = 1; index <= extent; index += 1) {
          options.push({
            value: `${name}[${index}]`,
            text: `${name}[${index}]`
          });
        }
        return;
      }
      options.push({
        value: name,
        text: name
      });
    });

    multi.setDataSource(new kendo.data.DataSource({ data: options }));
    multi.value(options.slice(0, 12).map((item) => item.value));
  }

  function selectedBrowseFields() {
    const multi = $("#browseFields").data("kendoMultiSelect");
    const values = multi ? multi.value() : [];
    return Array.isArray(values) ? values : [];
  }

  function browsePageSize() {
    const numeric = $("#browsePageSize").data("kendoNumericTextBox");
    const value = numeric ? Number(numeric.value()) : 50;
    if (!Number.isFinite(value) || value < 1) return 50;
    return Math.min(500, Math.floor(value));
  }

  function browseDirection() {
    const combo = $("#browseDirection").data("kendoDropDownList");
    return combo ? combo.value() || "ASC" : "ASC";
  }

  function setBrowseDirection(direction) {
    const combo = $("#browseDirection").data("kendoDropDownList");
    if (combo) {
      combo.value(direction);
    }
  }

  function invertBrowseDirection() {
    const next = browseDirection() === "ASC" ? "DESC" : "ASC";
    setBrowseDirection(next);
    state.browseCursor = null;
    state.browseHasMore = false;
    clearBrowseGrid();
    loadBrowsePage(false);
  }

  function loadBrowsePage(useCursor) {
    if (!state.currentTable || !state.currentDatabase) {
      setStatus("Carregue uma tabela antes de navegar pelos dados.", "error");
      return;
    }
    if (useCursor && !state.browseCursor) {
      setStatus("Nao ha cursor para carregar a proxima pagina.", "error");
      return;
    }

    const payload = {
      database: state.currentDatabase,
      table: state.currentTable,
      pageSize: browsePageSize(),
      direction: browseDirection(),
      fields: selectedBrowseFields()
    };
    if (useCursor) {
      payload.cursor = state.browseCursor;
    }

    setStatus(`Carregando dados de ${state.currentDatabase}.${state.currentTable}...`, "");
    $.ajax({
      url: pasoeUrl("/table-browse"),
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(payload)
    })
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        state.browseCursor = response.nextCursor || null;
        state.browseHasMore = !!response.hasMore;
        renderBrowseResponse(response);
        setStatus(`Dados carregados: ${response.recordsReturned || 0} registros.`, "ok");
      })
      .fail(function (xhr) {
        setStatus("Falha ao carregar dados: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function renderBrowseResponse(response) {
    const grid = $("#dataGrid").data("kendoGrid");
    if (!grid) return;

    const rows = Array.isArray(response.data) ? response.data : [];
    const fieldDefs = Array.isArray(response.fields) && response.fields.length
      ? response.fields.filter((item) => item && item.name)
      : Object.keys(rows[0] || {});
    const fields = fieldDefs.map((item) => typeof item === "string" ? item : item.name);
    const fieldTypes = fieldDefs.reduce((acc, item) => {
      if (item && typeof item === "object" && item.name) {
        acc[item.name] = String(item.type || "").toLowerCase();
      }
      return acc;
    }, {});
    const formattedRows = rows.map((row) => formatBrowseRow(row, fieldTypes));
    const columns = fields.map((field) => browseColumn(field, fieldTypes[field]));

    grid.setOptions({ columns });
    grid.dataSource.data(formattedRows);
    renderBrowseSummary(response);
    updateBrowseState();
  }

  function formatBrowseRow(row, fieldTypes) {
    const out = Object.assign({}, row);
    Object.keys(fieldTypes).forEach((field) => {
      if (fieldTypes[field] === "date" || fieldTypes[field] === "datetime" || fieldTypes[field] === "datetime-tz") {
        out[field] = parseBrowseDateValue(row[field], fieldTypes[field]);
      }
    });
    return out;
  }

  function browseColumn(field, type) {
    const column = { field, title: field, width: 160 };
    if (type === "date") {
      column.format = "{0:dd/MM/yyyy}";
    } else if (type === "datetime" || type === "datetime-tz") {
      column.format = "{0:dd/MM/yyyy HH:mm:ss}";
      column.width = 190;
    }
    return column;
  }

  function parseBrowseDateValue(value, type) {
    if (value === null || value === undefined || value === "") return value;
    if (value instanceof Date) return value;
    const text = String(value).trim();
    let match = text.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2})(?::(\d{2}))?)?/);
    if (match) {
      return new Date(
        Number(match[1]),
        Number(match[2]) - 1,
        Number(match[3]),
        Number(match[4] || 0),
        Number(match[5] || 0),
        Number(match[6] || 0)
      );
    }
    match = text.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?/);
    if (match) {
      const first = Number(match[1]);
      const second = Number(match[2]);
      const month = first > 12 ? second : first;
      const day = first > 12 ? first : second;
      return new Date(
        Number(match[3]),
        month - 1,
        day,
        Number(match[4] || 0),
        Number(match[5] || 0),
        Number(match[6] || 0)
      );
    }
    if (type === "datetime-tz") {
      const parsed = new Date(text);
      if (!Number.isNaN(parsed.getTime())) return parsed;
    }
    return value;
  }

  function renderBrowseSummary(response) {
    const keyFields = Array.isArray(response.keyFields) ? response.keyFields : [];
    const keyText = keyFields.length
      ? keyFields.map((item) => `${item.name} ${item.ascending === false ? "DESC" : "ASC"}`).join(", ")
      : "-";
    $("#browseKeyInfo").text(`Chave: ${keyText}`);
    $("#browseMoreInfo").text(response.hasMore ? "Ha mais registros." : "Fim da navegacao atual.");
  }

  function clearBrowseGrid() {
    const grid = $("#dataGrid").data("kendoGrid");
    if (grid) {
      grid.setOptions({ columns: [] });
      grid.dataSource.data([]);
    }
    $("#browseKeyInfo").text("Chave: -");
    $("#browseMoreInfo").text("Sem dados carregados.");
    updateBrowseState();
  }

  function updateBrowseState() {
    const hasTable = !!state.currentTable && !!state.currentDatabase;
    const nextButton = $("#browseNextBtn").data("kendoButton");
    const firstButton = $("#browseFirstBtn").data("kendoButton");
    const invertButton = $("#browseInvertBtn").data("kendoButton");
    if (firstButton) firstButton.enable(hasTable);
    if (invertButton) invertButton.enable(hasTable);
    if (nextButton) nextButton.enable(hasTable && !!state.browseCursor && state.browseHasMore);
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

  function fieldsFromMetadataResponse(response) {
    if (!response) return [];
    if (Array.isArray(response.fields)) return response.fields;
    if (Array.isArray(response.data)) return response.data;
    if (response.data && Array.isArray(response.data.fields)) return response.data.fields;
    return [];
  }

  function indexesFromMetadataResponse(response, fields) {
    if (response) {
      if (Array.isArray(response.indices)) return response.indices;
      if (Array.isArray(response.indexes)) return response.indexes;
      if (response.data && Array.isArray(response.data.indices)) return response.data.indices;
      if (response.data && Array.isArray(response.data.indexes)) return response.data.indexes;
    }
    return indexesFromFields(fields || []);
  }

  function indexesFromFields(fields) {
    const byName = new Map();
    fields.forEach((field) => {
      splitIndexNames(field.indices || field.indexes || field.index).forEach((name) => {
        if (!byName.has(name)) {
          byName.set(name, {
            name,
            active: true,
            unique: false,
            primary: false,
            wordIndex: false,
            wordIndexNumber: 0,
            fields: []
          });
        }
        byName.get(name).fields.push({ name: field.name || "" });
      });
    });
    return Array.from(byName.values());
  }

  function splitIndexNames(value) {
    if (Array.isArray(value)) {
      return value.map((item) => String(item && item.name ? item.name : item)).filter(Boolean);
    }
    return String(value || "")
      .split(/[;,]/)
      .map((item) => item.trim())
      .filter(Boolean);
  }

  function clearGrids() {
    state.currentTable = "";
    state.currentDatabase = "";
    state.fields = [];
    state.indexes = [];
    state.joins = [];
    state.browseCursor = null;
    state.browseHasMore = false;

    $("#fieldsGrid").data("kendoGrid").dataSource.data([]);
    $("#indexesGrid").data("kendoGrid").dataSource.data([]);
    $("#joinsGrid").data("kendoGrid").dataSource.data([]);
    refreshBrowseFieldSelector();
    clearBrowseGrid();
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
