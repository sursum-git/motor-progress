(function () {
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  let config = { version: 2, companies: [] };
  let currentCompanyId = "";
  let fileHandle = null;

  function init() {
    $("button").kendoButton();
    config = loadConfig();
    currentCompanyId = localStorage.getItem(SELECTED_COMPANY_KEY) || defaultCompany().id;

    $("#companyCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: config.companies,
      change: function () {
        currentCompanyId = this.value() || defaultCompany().id;
        localStorage.setItem(SELECTED_COMPANY_KEY, currentCompanyId);
        refresh();
      }
    });
    $("#companyName").kendoTextBox();
    $("#endpointName").kendoTextBox();
    $("#endpointUrl").kendoTextBox();
    $("#endpointsGrid").kendoGrid({
      dataSource: endpointsForCurrentCompany(),
      height: 360,
      sortable: true,
      resizable: true,
      noRecords: { template: "Nenhum endpoint cadastrado para esta empresa." },
      columns: [
        { field: "companyName", title: "Empresa", width: 180 },
        { field: "name", title: "Ambiente/PASOE", width: 220 },
        { field: "url", title: "URL base" },
        { field: "isDefault", title: "Padrao", width: 90 },
        { title: "Acoes", width: 190, template: "<button class='k-button k-button-sm set-default'>Padrao</button> <button class='k-button k-button-sm remove-endpoint'>Remover</button>" }
      ]
    });

    $("#addCompany").on("click", addCompany);
    $("#removeCompany").on("click", removeCompany);
    $("#addEndpoint").on("click", addEndpoint);
    $("#exportFile").on("click", downloadFile);
    $("#saveWithPicker").on("click", saveWithPicker);
    $("#backToBuilder").on("click", function () { window.location.href = "query-builder.html"; });
    $("#configFile").on("change", importFile);
    $("#endpointsGrid").on("click", ".remove-endpoint", removeEndpoint);
    $("#endpointsGrid").on("click", ".set-default", setDefaultEndpoint);
    refresh();
  }

  function loadConfig() {
    let raw = null;
    try { raw = JSON.parse(localStorage.getItem(ENDPOINTS_KEY) || "null"); } catch (_) {}
    return normalizeConfig(raw);
  }

  function normalizeConfig(raw) {
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
        endpoints: endpoints.length ? endpoints : [{ id: "local-pasoe", name: "Local PASOE", url: "http://localhost:8890/web/SursumDynamicQuery", isDefault: true }]
      }])
    };
  }

  function normalizeCompanies(companies) {
    const list = companies.map((company, companyIndex) => {
      const companyId = company.id || slug(company.name || "empresa") + "-" + companyIndex;
      const endpoints = (company.endpoints || []).map((endpoint, endpointIndex) => ({
        id: endpoint.id || slug(endpoint.name || "endpoint") + "-" + Date.now() + "-" + endpointIndex,
        name: endpoint.name || "Endpoint PASOE",
        url: String(endpoint.url || "").replace(/\/+$/, ""),
        isDefault: !!endpoint.isDefault,
        companyId
      }));
      return {
        id: companyId,
        name: company.name || "Empresa",
        isDefault: !!company.isDefault,
        endpoints: ensureDefaultEndpoint(endpoints)
      };
    });
    if (!list.some((company) => company.isDefault) && list[0]) list[0].isDefault = true;
    return list;
  }

  function ensureDefaultEndpoint(endpoints) {
    if (!endpoints.length) return [];
    if (!endpoints.some((endpoint) => endpoint.isDefault)) endpoints[0].isDefault = true;
    return endpoints;
  }

  function defaultCompany() {
    return config.companies.find((company) => company.isDefault) || config.companies[0];
  }

  function currentCompany() {
    return config.companies.find((company) => company.id === currentCompanyId) || defaultCompany();
  }

  function endpointsForCurrentCompany() {
    const company = currentCompany();
    return (company ? company.endpoints : []).map((endpoint) => ({ ...endpoint, companyName: company.name }));
  }

  function persist() {
    config = normalizeConfig(config);
    localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(config, null, 2));
    const company = currentCompany() || defaultCompany();
    if (!company) return;
    const endpoint = company.endpoints.find((item) => item.isDefault) || company.endpoints[0];
    localStorage.setItem(SELECTED_COMPANY_KEY, company.id);
    if (endpoint) {
      localStorage.setItem(SELECTED_ENDPOINT_KEY, endpoint.id);
      localStorage.setItem("sursumApiBaseUrl", endpoint.url);
    }
  }

  function refresh() {
    persist();
    const companyCombo = $("#companyCombo").data("kendoComboBox");
    companyCombo.setDataSource(new kendo.data.DataSource({ data: config.companies }));
    companyCombo.value(currentCompany().id);
    $("#endpointsGrid").data("kendoGrid").dataSource.data(endpointsForCurrentCompany());
    $("#filePreview").val(JSON.stringify(config, null, 2));
  }

  function addCompany() {
    const name = String($("#companyName").val() || "").trim();
    if (!name) {
      setStatus("Informe o nome da empresa.", "error");
      return;
    }
    const company = { id: slug(name) + "-" + Date.now(), name, isDefault: config.companies.length === 0, endpoints: [] };
    config.companies.push(company);
    currentCompanyId = company.id;
    $("#companyName").val("");
    refresh();
    setStatus("Empresa adicionada: " + name, "ok");
  }

  function removeCompany() {
    if (config.companies.length <= 1) {
      setStatus("Mantenha pelo menos uma empresa cadastrada.", "error");
      return;
    }
    const company = currentCompany();
    config.companies = config.companies.filter((item) => item.id !== company.id);
    currentCompanyId = defaultCompany().id;
    refresh();
    setStatus("Empresa removida.", "ok");
  }

  function addEndpoint() {
    const company = currentCompany();
    const name = String($("#endpointName").val() || "").trim() || "Endpoint PASOE";
    const url = String($("#endpointUrl").val() || "").trim().replace(/\/+$/, "");
    if (!url) {
      setStatus("Informe a URL base do endpoint.", "error");
      return;
    }
    company.endpoints.push({ id: slug(name) + "-" + Date.now(), name, url, isDefault: company.endpoints.length === 0, companyId: company.id });
    $("#endpointName").val("");
    $("#endpointUrl").val("");
    refresh();
    setStatus("Endpoint adicionado para " + company.name + ".", "ok");
  }

  function gridItem(event) {
    const grid = $("#endpointsGrid").data("kendoGrid");
    return grid.dataItem($(event.currentTarget).closest("tr"));
  }

  function removeEndpoint(event) {
    const item = gridItem(event);
    const company = currentCompany();
    if (!item || company.endpoints.length <= 1) {
      setStatus("Mantenha pelo menos um endpoint para esta empresa.", "error");
      return;
    }
    company.endpoints = company.endpoints.filter((endpoint) => endpoint.id !== item.id);
    refresh();
    setStatus("Endpoint removido.", "ok");
  }

  function setDefaultEndpoint(event) {
    const item = gridItem(event);
    const company = currentCompany();
    if (!item) return;
    company.endpoints = company.endpoints.map((endpoint) => ({ ...endpoint, isDefault: endpoint.id === item.id }));
    config.companies = config.companies.map((candidate) => ({ ...candidate, isDefault: candidate.id === company.id }));
    refresh();
    setStatus("Endpoint padrao atualizado para " + company.name + ": " + item.name, "ok");
  }

  function importFile(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function () {
      try {
        config = normalizeConfig(JSON.parse(String(reader.result || "{}")));
        currentCompanyId = defaultCompany().id;
        refresh();
        setStatus("Arquivo importado e sincronizado com o fallback local.", "ok");
      } catch (error) {
        setStatus("Arquivo JSON invalido: " + error.message, "error");
      }
    };
    reader.readAsText(file, "utf-8");
  }

  function downloadFile() {
    refresh();
    const blob = new Blob([$("#filePreview").val()], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "sursum-endpoints.json";
    link.click();
    URL.revokeObjectURL(url);
    setStatus("Arquivo JSON gerado para download.", "ok");
  }

  async function saveWithPicker() {
    refresh();
    if (!window.showSaveFilePicker) {
      downloadFile();
      setStatus("Este navegador nao permite gravacao direta. Foi gerado download como fallback.", "ok");
      return;
    }
    try {
      fileHandle = fileHandle || await window.showSaveFilePicker({
        suggestedName: "sursum-endpoints.json",
        types: [{ description: "JSON", accept: { "application/json": [".json"] } }]
      });
      const writable = await fileHandle.createWritable();
      await writable.write($("#filePreview").val());
      await writable.close();
      setStatus("Arquivo salvo diretamente pelo navegador.", "ok");
    } catch (error) {
      setStatus("Gravacao cancelada ou bloqueada: " + error.message, "error");
    }
  }

  function slug(value) {
    return String(value || "item").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "item";
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
})();
