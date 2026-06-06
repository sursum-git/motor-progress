(function () {
  const STORAGE_KEY = "sursumCurrentQueryJson";
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  let endpointConfig = { version: 2, companies: [] };
  let endpoints = [];

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
    $("#apiCompany").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: endpointConfig.companies,
      change: onCompanyChanged
    });
    endpoints = endpointsForSelectedCompany();
    $("#apiEndpoint").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: endpoints,
      change: applyEndpoint
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
    $("#openEndpointConfig").on("click", function () { window.location.href = "endpoint-config.html"; });
    $("#loadFromDesigner").on("click", loadFromDesigner);
    $("#loadSimpleSample").on("click", loadSimpleSample);
    $("#runQuery").on("click", runQuery);

    if (!loadFromDesigner()) loadSimpleSample();
  }

  function loadEndpointConfig() {
    let raw = null;
    try { raw = JSON.parse(localStorage.getItem(ENDPOINTS_KEY) || "null"); } catch (_) {}
    const config = normalizeEndpointConfig(raw);
    localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(config, null, 2));
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
    const selectedId = localStorage.getItem(SELECTED_COMPANY_KEY);
    return endpointConfig.companies.find((company) => company.id === selectedId) || endpointConfig.companies.find((company) => company.isDefault) || endpointConfig.companies[0];
  }

  function endpointsForSelectedCompany() {
    const company = selectedCompany();
    return company ? company.endpoints || [] : [];
  }

  function refreshEndpointCombos() {
    const company = selectedCompany();
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    companyCombo.setDataSource(new kendo.data.DataSource({ data: endpointConfig.companies }));
    companyCombo.value(company ? company.id : "");
    endpoints = endpointsForSelectedCompany();
    const endpointCombo = $("#apiEndpoint").data("kendoComboBox");
    endpointCombo.setDataSource(new kendo.data.DataSource({ data: endpoints }));
    const preferred = localStorage.getItem(SELECTED_ENDPOINT_KEY);
    const endpoint = endpoints.find((item) => item.id === preferred) || endpoints.find((item) => item.isDefault) || endpoints[0];
    endpointCombo.value(endpoint ? endpoint.id : "");
    applyEndpoint();
  }

  function onCompanyChanged() {
    const combo = $("#apiCompany").data("kendoComboBox");
    if (combo && combo.value()) localStorage.setItem(SELECTED_COMPANY_KEY, combo.value());
    refreshEndpointCombos();
  }

  function applyEndpoint() {
    const combo = $("#apiEndpoint").data("kendoComboBox");
    const id = combo ? combo.value() : "";
    const endpoint = endpoints.find((item) => item.id === id) || endpoints[0];
    if (!endpoint) return;
    if (endpoint.companyId) localStorage.setItem(SELECTED_COMPANY_KEY, endpoint.companyId);
    $("#apiUrl").val(String(endpoint.url || "").replace(/\/+$/, "") + "/query");
    localStorage.setItem(SELECTED_ENDPOINT_KEY, endpoint.id);
    localStorage.setItem("sursumApiBaseUrl", endpoint.url || "");
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
    localStorage.setItem(STORAGE_KEY, payload);
    setStatus("Enviando JSON para a API do PASOE...", "");
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
    const rows = Array.isArray(response.data) ? response.data : [];
    updateGrid(rows.length ? rows : [{ mensagem: "Consulta executada sem linhas em data." }]);
    setStatus("Consulta concluida. Registros: " + (response.recordsReturned || rows.length), "ok");
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
