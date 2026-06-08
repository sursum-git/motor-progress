(function () {
  const STORAGE_KEY = "sursumCurrentQueryJson";
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  let endpointConfig = { version: 2, companies: [] };
  let endpoints = [];
  let optionLabelMaps = {};

  const simpleSample = {
    execution: "sync",
    sources: [{ nome: "Customer", alias: "customer", campos: "CustNum,Name" }],
    select: [
      { sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" },
      { sourceAlias: "customer", field: "Name", outputAlias: "nome" }
    ],
    orderBy: [{ sourceAlias: "customer", field: "CustNum", direction: "ASC" }],
    page: 1,
    pageSize: 500
  };

  function init() {
    $("button").kendoButton();
    endpointConfig = loadEndpointConfig();
    if (window.SursumContext && typeof SursumContext.setLegacySelection === "function") {
      syncContextSelection();
    }
    $("#apiCompany").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: endpointConfig.companies,
      change: onCompanyChanged
    });
    refreshEndpointCombos();
    $("#resultGrid").kendoGrid({
      dataSource: [],
      height: 620,
      sortable: true,
      filterable: true,
      resizable: true,
      pageable: { pageSize: 25, pageSizes: [25, 50, 100, 500] }
    });

    $("#queryFile").on("change", onFileSelected);
    $("#openContextSelector").on("click", function () { window.location.href = "context-selector.html"; });
    $("#openEndpointConfig").on("click", function () { window.location.href = "endpoint-config.html"; });
    $("#loadFromDesigner").on("click", loadFromDesigner);
    $("#loadSimpleSample").on("click", loadSimpleSample);
    $("#runQuery").on("click", runQuery);

    if (!loadFromDesigner()) loadSimpleSample();
  }

  function loadEndpointConfig() {
    if (window.SursumContext && typeof SursumContext.getLegacyConfig === "function") {
      const legacy = SursumContext.getLegacyConfig();
      if (legacy) {
        const config = normalizeEndpointConfig(legacy);
        localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(config, null, 2));
        syncContextSelectionFromLegacy(config);
        return config;
      }
    }

    let raw = null;
    try { raw = JSON.parse(localStorage.getItem(ENDPOINTS_KEY) || "null"); } catch (_) {}
    const config = normalizeEndpointConfig(raw);
    localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(config, null, 2));
    syncContextSelectionFromLegacy(config);
    return config;
  }

  function normalizeEndpointConfig(raw) {
    if (raw && Array.isArray(raw.companies)) return { version: 2, companies: normalizeCompanies(raw.companies) };
    const list = Array.isArray(raw) ? raw : (raw && Array.isArray(raw.endpoints) ? raw.endpoints : []);
    return {
      version: 2,
      companies: normalizeCompanies([{
        id: "empresa-padrao",
        name: "Empresa padrao",
        isDefault: true,
        endpoints: list.length ? list : [{ id: "local-pasoe", name: "Local PASOE", url: "http://localhost:8890/web/SursumDynamicQuery", isDefault: true }]
      }])
    };
  }

  function normalizeCompanies(companies) {
    const normalized = companies.map((company, index) => {
      const companyId = company.id || "empresa-" + index;
      const companyEndpoints = (company.endpoints || []).map((endpoint) => ({ ...endpoint, companyId, url: String(endpoint.url || "").replace(/\/+$/, "") }));
      if (companyEndpoints.length && !companyEndpoints.some((endpoint) => endpoint.isDefault)) companyEndpoints[0].isDefault = true;
      return { id: companyId, name: company.name || "Empresa", isDefault: !!company.isDefault, endpoints: companyEndpoints };
    });
    if (!normalized.some((company) => company.isDefault) && normalized[0]) normalized[0].isDefault = true;
    return normalized;
  }

  function selectedCompany() {
    if (window.SursumContext && typeof SursumContext.getCurrentCompany === "function") {
      return SursumContext.getCurrentCompany();
    }
    const selectedId = localStorage.getItem(SELECTED_COMPANY_KEY);
    const companies = companiesForCurrentEnvironment();
    return companies.find((company) => company.id === selectedId) || companies.find((company) => company.isDefault) || companies[0];
  }

  function companiesForCurrentEnvironment() {
    const environment = window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function"
      ? SursumContext.getCurrentEnvironment()
      : null;
    if (environment && Array.isArray(endpointConfig.companies)) {
      return endpointConfig.companies.filter((company) => company.environmentId === environment.id);
    }
    return endpointConfig.companies || [];
  }

  function endpointsForSelectedCompany() {
    if (window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function") {
      const environment = SursumContext.getCurrentEnvironment();
      return environment ? [environment] : [];
    }
    const company = selectedCompany();
    return company ? company.endpoints || [] : [];
  }

  function refreshEndpointCombos() {
    const company = selectedCompany();
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    companyCombo.setDataSource(new kendo.data.DataSource({ data: companiesForCurrentEnvironment() }));
    companyCombo.value(company ? company.id : "");
    endpoints = endpointsForSelectedCompany();
    applyEndpoint();
    updateContextSummary();
  }

  function onCompanyChanged() {
    const combo = $("#apiCompany").data("kendoComboBox");
    const companyId = combo ? combo.value() : "";
    if (companyId) localStorage.setItem(SELECTED_COMPANY_KEY, companyId);
    if (window.SursumContext && typeof SursumContext.setSelection === "function") {
      const environment = typeof SursumContext.getCurrentEnvironment === "function" ? SursumContext.getCurrentEnvironment() : null;
      const client = typeof SursumContext.getCurrentClient === "function" ? SursumContext.getCurrentClient() : null;
      SursumContext.setSelection((client || {}).id || "", (environment || {}).id || "", companyId || "");
    }
    refreshEndpointCombos();
  }

  function applyEndpoint() {
    const endpoint = (window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function"
      ? SursumContext.getCurrentEnvironment()
      : null) || endpoints[0];
    if (!endpoint) return;
    if (endpoint.companyId) localStorage.setItem(SELECTED_COMPANY_KEY, endpoint.companyId);
    $("#apiUrl").val(String(endpoint.pasoeBaseUrl || endpoint.url || "").replace(/\/+$/, "") + "/query");
    localStorage.setItem(SELECTED_ENDPOINT_KEY, endpoint.id);
    localStorage.setItem("sursumApiBaseUrl", endpoint.pasoeBaseUrl || endpoint.url || "");
    if (window.SursumContext && typeof SursumContext.setSelection === "function") {
      const client = typeof SursumContext.getCurrentClient === "function" ? SursumContext.getCurrentClient() : null;
      SursumContext.setSelection((client || {}).id || "", endpoint.id || "", selectedCompany() && selectedCompany().id || "");
    } else if (window.SursumContext && typeof SursumContext.setLegacySelection === "function") {
      SursumContext.setLegacySelection(endpoint.companyId || selectedCompany() && selectedCompany().id || "", endpoint.id || "");
    }
  }

  function updateContextSummary() {
    if (!window.SursumContext) return;
    const client = typeof SursumContext.getCurrentClient === "function" ? SursumContext.getCurrentClient() : null;
    const environment = typeof SursumContext.getCurrentEnvironment === "function" ? SursumContext.getCurrentEnvironment() : null;
    $("#contextSummary").text(client && environment
      ? ((client.name || client.id) + " / " + (environment.name || environment.id))
      : "Selecione o contexto na pagina inicial.");
  }

  function syncContextSelection() {
    if (!window.SursumContext) return;
    if (typeof SursumContext.getCurrentCompany === "function") {
      const company = SursumContext.getCurrentCompany();
      if (company) localStorage.setItem(SELECTED_COMPANY_KEY, company.id);
    }
    if (typeof SursumContext.getCurrentEnvironment === "function") {
      const environment = SursumContext.getCurrentEnvironment();
      if (environment) localStorage.setItem(SELECTED_ENDPOINT_KEY, environment.id);
    }
  }

  function syncContextSelectionFromLegacy(config) {
    if (!window.SursumContext || typeof SursumContext.applyLegacyConfig !== "function") return;
    SursumContext.applyLegacyConfig(config || {});
  }

  function loadFromDesigner() {
    const json = localStorage.getItem(STORAGE_KEY);
    if (!json) {
      setStatus("Nenhuma consulta encontrada no designer.", "error");
      return false;
    }
    $("#fileName").text("designer/localStorage");
    $("#fileSize").text(formatBytes(json.length));
    $("#jsonPreview").val(formatJson(json));
    validatePreview();
    setStatus("Consulta do designer carregada. Execute para chamar o PASOE.", "ok");
    return true;
  }

  function onFileSelected(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) return;
    $("#fileName").text(file.name);
    $("#fileSize").text(formatBytes(file.size));
    $("#parseStatus").text("lendo arquivo...");
    const reader = new FileReader();
    reader.onload = function () {
      const text = String(reader.result || "");
      $("#jsonPreview").val(formatJson(text));
      localStorage.setItem(STORAGE_KEY, $("#jsonPreview").val());
      validatePreview();
    };
    reader.onerror = function () {
      setStatus("Nao foi possivel ler o arquivo.", "error");
      $("#parseStatus").text("erro de leitura");
    };
    reader.readAsText(file, "utf-8");
  }

  function loadSimpleSample() {
    const json = JSON.stringify(simpleSample, null, 2);
    $("#fileName").text("customer-simple.json");
    $("#fileSize").text("amostra interna");
    $("#jsonPreview").val(json);
    localStorage.setItem(STORAGE_KEY, json);
    validatePreview();
    setStatus("Amostra carregada. Execute para chamar o PASOE.", "ok");
  }

  function validatePreview() {
    try {
      JSON.parse($("#jsonPreview").val());
      $("#parseStatus").text("JSON valido");
      return true;
    } catch (error) {
      $("#parseStatus").text("JSON invalido: " + error.message);
      return false;
    }
  }

  function runQuery() {
    if (!validatePreview()) {
      setStatus("Corrija o JSON antes de executar.", "error");
      return;
    }
    const payload = $("#jsonPreview").val();
    let request = {};
    try { request = JSON.parse(payload); } catch (_) {}
    localStorage.setItem(STORAGE_KEY, payload);
    setStatus("Carregando opcoes de campos e enviando JSON para a API do PASOE...", "");
    loadOptionMaps(request).always(function () {
      $.ajax({
        url: $("#apiUrl").val(),
        method: "POST",
        contentType: "application/json",
        dataType: "json",
        data: payload
      }).done(renderResponse).fail(function (xhr) {
        $("#statSuccess").text("false");
        $("#statRecords").text("0");
        $("#statHasMore").text("-");
        updateGrid([{ erro: "Falha HTTP", status: xhr.status, detalhe: xhr.statusText || xhr.responseText }]);
        setStatus("Falha HTTP: " + xhr.status + " " + xhr.statusText, "error");
      });
    });
  }

  function renderResponse(response) {
    $("#statSuccess").text(String(!!response.success));
    $("#statRecords").text(String(response.recordsReturned || (response.data ? response.data.length : 0)));
    $("#statHasMore").text(String(response.hasMore === undefined ? "-" : response.hasMore));
    if (!response.success) {
      const error = response.error || {};
      updateGrid([{ code: error.code || "ERROR", message: error.message || "Erro sem mensagem", details: error.details || "" }]);
      setStatus("Erro da API: " + (error.message || "falha desconhecida"), "error");
      return;
    }
    const rows = Array.isArray(response.data) ? applyOptionLabels(response.data) : [];
    updateGrid(rows.length ? rows : [{ mensagem: "Consulta executada sem linhas em data." }]);
    setStatus("Consulta concluida. Registros: " + (response.recordsReturned || rows.length), "ok");
  }

  function loadOptionMaps(request) {
    optionLabelMaps = {};
    const sources = Array.isArray(request.sources) ? request.sources : sourcesFromPipeline(request.pipeline);
    const select = Array.isArray(request.select) ? request.select : selectFromPipeline(request.pipeline);
    if (!sources.length) return $.Deferred().resolve().promise();

    const calls = sources.map(function (source) {
      if (!source.nome || !source.banco) return $.Deferred().resolve().promise();
      return $.getJSON(apiBaseFromQueryUrl() + "/metadata/tables/" + encodeURIComponent(source.nome) + "/fields?database=" + encodeURIComponent(source.banco))
        .done(function (response) {
          const fields = response.fields || response.data || [];
          registerOptionMapsForSource(source, fields, select);
        });
    });
    return $.when.apply($, calls);
  }

  function registerOptionMapsForSource(source, fields, select) {
    const byName = {};
    fields.forEach(function (field) { byName[String(field.name || "").toLowerCase()] = field; });
    const selected = select.length ? select.filter(function (item) { return item.sourceAlias === source.alias; }) : fields.map(function (field) {
      return { field: field.name, outputAlias: field.name };
    });
    selected.forEach(function (item) {
      const field = byName[String(item.field || "").toLowerCase()];
      if (!field || !Array.isArray(field.options) || !field.options.length) return;
      const output = item.outputAlias || item.field;
      optionLabelMaps[output] = {};
      field.options.forEach(function (option) {
        optionLabelMaps[output][String(option.value)] = option.label;
      });
    });
  }

  function applyOptionLabels(rows) {
    return rows.map(function (row) {
      const copy = { ...row };
      Object.keys(copy).forEach(function (field) {
        const map = optionLabelMaps[field];
        const value = copy[field];
        if (map && Object.prototype.hasOwnProperty.call(map, String(value))) copy[field] = map[String(value)];
      });
      return copy;
    });
  }

  function apiBaseFromQueryUrl() {
    return String($("#apiUrl").val() || "").replace(/\/query\/?$/, "").replace(/\/+$/, "");
  }

  function sourcesFromPipeline(pipeline) {
    if (!Array.isArray(pipeline)) return [];
    return pipeline.filter(function (step) { return step.type === "source"; }).map(function (step) {
      try { return JSON.parse(step.payload || "{}"); } catch (_) { return {}; }
    });
  }

  function selectFromPipeline(pipeline) {
    if (!Array.isArray(pipeline)) return [];
    const rows = [];
    pipeline.filter(function (step) { return step.type === "select"; }).forEach(function (step) {
      try {
        const payload = JSON.parse(step.payload || "{}");
        (payload.fields || []).forEach(function (field) { rows.push(field); });
      } catch (_) {}
    });
    return rows;
  }

  function updateGrid(rows) {
    const grid = $("#resultGrid").data("kendoGrid");
    const first = rows[0] || {};
    const columns = Object.keys(first).map((field) => ({ field, title: field, width: 160 }));
    grid.setOptions({ columns: columns.length ? columns : [{ field: "mensagem", title: "Mensagem" }] });
    grid.dataSource.data(rows);
  }

  function formatJson(text) {
    try { return JSON.stringify(JSON.parse(text), null, 2); } catch (_) { return text; }
  }

  function formatBytes(size) {
    if (size < 1024) return size + " bytes";
    if (size < 1024 * 1024) return (size / 1024).toFixed(1) + " KB";
    return (size / 1024 / 1024).toFixed(1) + " MB";
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
})();
