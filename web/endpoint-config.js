(function () {
  const STORAGE_KEY = "sursumApiEndpoints";
  let config = null;
  let fileHandle = null;
  let currentEnvironmentId = "";
  let currentCompanyId = "";

  function init() {
    $("button").kendoButton();
    $("#endpointName, #endpointUrl, #companyName, #companyCode").kendoTextBox();
    $("#configFile").kendoUpload({
      multiple: false,
      showFileList: true,
      validation: {
        allowedExtensions: [".json"]
      },
      select: function (event) {
        const file = event.files && event.files[0] ? event.files[0].rawFile : null;
        importSelectedFile(file);
      }
    });
    $("#environmentCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: []
    });

    config = loadConfig();
    currentEnvironmentId = config.selected.environmentId;
    currentCompanyId = config.selected.companyId;

    $("#endpointsGrid").kendoGrid({
      dataSource: [],
      height: 340,
      sortable: true,
      resizable: true,
      noRecords: { template: "Nenhum ambiente cadastrado." },
      columns: [
        { field: "name", title: "Ambiente", width: 220 },
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
    $("#endpointsGrid").on("click", ".remove-environment", removeEnvironment);
    $("#companiesGrid").on("click", ".remove-company-row", removeCompanyRow);
    $("#companiesGrid").on("click", "tbody tr", onCompanyRowSelected);
    $("#exportFile").on("click", downloadFile);
    $("#saveWithPicker").on("click", saveWithPicker);

    refresh();
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
        companies: Array.isArray(raw.companies) ? raw.companies.slice() : [],
        physicalDatabases: Array.isArray(raw.physicalDatabases) ? raw.physicalDatabases.slice() : [],
        aliases: Array.isArray(raw.aliases) ? raw.aliases.slice() : [],
        selected: raw.selected || {}
      };
    }
    return {
      version: 4,
      clients: [{ id: "cliente-padrao", name: "Cliente padrao" }],
      environments: [{
        id: "ambiente-local",
        clientId: "",
        name: "Local PASOE",
        pasoeBaseUrl: "http://localhost:8890/web/SursumDynamicQuery",
        authMode: "none",
        authorization: "",
        companyIdMode: "query",
        extraQueryParams: ""
      }],
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
  }

  function refresh() {
    persist();
    const environmentCombo = $("#environmentCombo").data("kendoComboBox");
    environmentCombo.setDataSource(new kendo.data.DataSource({ data: config.environments || [] }));
    environmentCombo.value((currentEnvironment() || {}).id || "");
    const company = currentCompany();
    $("#companyName").val(company ? company.name || "" : "");
    $("#companyCode").val(company ? company.code || "" : "");
    $("#endpointsGrid").data("kendoGrid").dataSource.data(config.environments || []);
    $("#companiesGrid").data("kendoGrid").dataSource.data(companiesForCurrentEnvironment());
    $("#filePreview").val(JSON.stringify(config, null, 2));
  }

  function onEnvironmentChanged() {
    currentEnvironmentId = $("#environmentCombo").data("kendoComboBox").value() || (currentEnvironment() || {}).id || "";
    currentCompanyId = "";
    refresh();
  }

  function addEnvironment() {
    const name = String($("#endpointName").val() || "").trim() || "Endpoint PASOE";
    const url = String($("#endpointUrl").val() || "").trim().replace(/\/+$/, "");
    if (!url) {
      setStatus("Informe a URL base do endpoint.", "error");
      return;
    }
    const environmentId = slug(name) + "-" + Date.now();
    config.environments.push({
      id: environmentId,
      clientId: "",
      name,
      pasoeBaseUrl: url,
      authMode: "none",
      authorization: "",
      companyIdMode: "query",
      extraQueryParams: ""
    });
    currentEnvironmentId = environmentId;
    $("#endpointName").val("");
    $("#endpointUrl").val("");
    refresh();
    setStatus("Ambiente adicionado.", "ok");
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
      existing.clientId = environment.clientId || "";
      currentCompanyId = existing.id;
      $("#companyName").val("");
      $("#companyCode").val("");
      refresh();
      setStatus("Empresa do ambiente atualizada.", "ok");
      return;
    }
    const company = {
      id: slug(name || code) + "-" + Date.now(),
      clientId: environment.clientId || "",
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

  function importSelectedFile(file) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function () {
      try {
        config = normalizeConfig(JSON.parse(String(reader.result || "{}")));
        currentEnvironmentId = (config.selected || {}).environmentId || (config.environments[0] || {}).id || "";
        currentCompanyId = (config.selected || {}).companyId || "";
        refresh();
        setStatus("Arquivo importado.", "ok");
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
      setStatus("Sem acesso ao picker do navegador. Foi gerado download como fallback.", "ok");
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
