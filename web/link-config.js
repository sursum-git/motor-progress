(function () {
  const STORAGE_KEY = "sursumApiEndpoints";
  let config = null;
  let fileHandle = null;
  let currentClientId = "";
  let currentEnvironmentId = "";

  function init() {
    $("button").kendoButton();
    $("#configFile").kendoUpload({
      multiple: false,
      showFileList: true,
      validation: { allowedExtensions: [".json"] },
      select: function (event) {
        const file = event.files && event.files[0] ? event.files[0].rawFile : null;
        importSelectedFile(file);
      }
    });
    $("#clientCombo, #environmentCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: []
    });

    config = loadConfig();
    currentClientId = config.selected.clientId;
    currentEnvironmentId = config.selected.environmentId;

    $("#linksGrid").kendoGrid({
      dataSource: [],
      height: 360,
      sortable: true,
      resizable: true,
      selectable: "row",
      noRecords: { template: "Nenhum vinculo cadastrado." },
      columns: [
        { field: "clientName", title: "Cliente", width: 180 },
        { field: "environmentName", title: "Ambiente", width: 180 },
        { field: "pasoeBaseUrl", title: "URL base" },
        { title: "Acoes", width: 120, template: "<button class='k-button k-button-sm remove-link-row'>Remover</button>" }
      ]
    });

    $("#clientCombo").data("kendoComboBox").bind("change", onClientChanged);
    $("#environmentCombo").data("kendoComboBox").bind("change", onEnvironmentChanged);
    $("#saveLink").on("click", saveLink);
    $("#removeLink").on("click", removeCurrentLink);
    $("#linksGrid").on("click", ".remove-link-row", removeLinkRow);
    $("#linksGrid").on("click", "tbody tr", onLinkRowSelected);
    $("#openClientConfig").on("click", function () { window.location.href = "client-config.html"; });
    $("#openEnvironmentConfig").on("click", function () { window.location.href = "endpoint-config.html"; });
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
      environments: [{ id: "ambiente-local", clientId: "", name: "Local PASOE", pasoeBaseUrl: "http://localhost:8890/web/SursumDynamicQuery", authMode: "none", authorization: "", companyIdMode: "query", extraQueryParams: "" }],
      companies: [],
      physicalDatabases: [],
      aliases: [],
      selected: { clientId: "cliente-padrao", environmentId: "ambiente-local", companyId: "" }
    };
  }

  function currentClient() {
    return config.clients.find((item) => item.id === currentClientId) || config.clients[0] || null;
  }

  function currentEnvironment() {
    return config.environments.find((item) => item.id === currentEnvironmentId) || config.environments[0] || null;
  }

  function currentCompany() {
    return null;
  }

  function persist() {
    config.selected = {
      clientId: (currentClient() || {}).id || "",
      environmentId: (currentEnvironment() || {}).id || "",
      companyId: (currentCompany() || {}).id || ""
    };
    if (window.SursumContext && typeof SursumContext.setConfig === "function") {
      config = SursumContext.setConfig(config);
      currentClientId = config.selected.clientId;
      currentEnvironmentId = config.selected.environmentId;
      currentCompanyId = config.selected.companyId;
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config, null, 2));
  }

  function linkRows() {
    return (config.environments || []).filter((environment) => environment.clientId).map((environment) => {
      const client = (config.clients || []).find((item) => item.id === environment.clientId) || {};
      return {
        id: environment.id,
        clientId: environment.clientId,
        environmentId: environment.id,
        clientName: client.name || "",
        environmentName: environment.name || "",
        pasoeBaseUrl: environment.pasoeBaseUrl || ""
      };
    });
  }

  function refresh() {
    persist();
    const clientCombo = $("#clientCombo").data("kendoComboBox");
    const environmentCombo = $("#environmentCombo").data("kendoComboBox");

    clientCombo.setDataSource(new kendo.data.DataSource({ data: config.clients || [] }));
    clientCombo.value((currentClient() || {}).id || "");
    environmentCombo.setDataSource(new kendo.data.DataSource({ data: config.environments || [] }));
    environmentCombo.value((currentEnvironment() || {}).id || "");
    $("#linksGrid").data("kendoGrid").dataSource.data(linkRows());
    $("#filePreview").val(JSON.stringify(config, null, 2));
  }

  function onClientChanged() {
    currentClientId = $("#clientCombo").data("kendoComboBox").value() || (currentClient() || {}).id || "";
    refresh();
  }

  function onEnvironmentChanged() {
    currentEnvironmentId = $("#environmentCombo").data("kendoComboBox").value() || (currentEnvironment() || {}).id || "";
    const environment = currentEnvironment();
    if (environment && environment.clientId) {
      currentClientId = environment.clientId;
    }
    refresh();
  }

  function saveLink() {
    const client = currentClient();
    const environment = currentEnvironment();
    if (!client || !environment) {
      setStatus("Selecione cliente e ambiente.", "error");
      return;
    }
    environment.clientId = client.id;
    config.companies = (config.companies || []).map((item) => {
      return item.environmentId === environment.id ? { ...item, clientId: client.id } : item;
    });
    currentClientId = client.id;
    currentEnvironmentId = environment.id;
    refresh();
    setStatus("Vinculo cliente-ambiente salvo.", "ok");
  }

  function removeCurrentLink() {
    const environment = currentEnvironment();
    if (!environment) {
      setStatus("Nenhum ambiente selecionado.", "error");
      return;
    }
    removeLinkByEnvironment(environment.id);
  }

  function removeLinkRow(event) {
    const item = $("#linksGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) return;
    removeLinkByEnvironment(item.environmentId);
  }

  function onLinkRowSelected(event) {
    const item = $("#linksGrid").data("kendoGrid").dataItem($(event.currentTarget).closest("tr"));
    if (!item) {
      return;
    }
    currentClientId = item.clientId || currentClientId;
    currentEnvironmentId = item.environmentId || currentEnvironmentId;
    refresh();
  }

  function removeLinkByEnvironment(environmentId) {
    const environment = (config.environments || []).find((item) => item.id === environmentId);
    if (environment) {
      environment.clientId = "";
    }
    config.companies = (config.companies || []).map((item) => {
      return item.environmentId === environmentId ? { ...item, clientId: "" } : item;
    });
    refresh();
    setStatus("Vinculo removido.", "ok");
  }

  function importSelectedFile(file) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function () {
      try {
        config = normalizeConfig(JSON.parse(String(reader.result || "{}")));
        currentClientId = (config.selected || {}).clientId || (config.clients[0] || {}).id || "";
        currentEnvironmentId = (config.selected || {}).environmentId || (config.environments[0] || {}).id || "";
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

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
}());
