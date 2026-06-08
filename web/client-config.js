(function () {
  const STORAGE_KEY = "sursumApiEndpoints";
  let config = null;
  let fileHandle = null;
  let currentClientId = "";

  function init() {
    $("button").kendoButton();
    $("#clientName").kendoTextBox();
    $("#configFile").kendoUpload({
      multiple: false,
      showFileList: true,
      validation: { allowedExtensions: [".json"] },
      select: function (event) {
        const file = event.files && event.files[0] ? event.files[0].rawFile : null;
        importSelectedFile(file);
      }
    });
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
        { field: "environmentCount", title: "Ambientes", width: 140 },
        { field: "companyCount", title: "CompanyId", width: 140 },
        { title: "Acoes", width: 120, template: "<button class='k-button k-button-sm remove-client-row'>Remover</button>" }
      ]
    });

    $("#clientCombo").data("kendoComboBox").bind("change", onClientChanged);
    $("#addClient").on("click", addClient);
    $("#removeClient").on("click", removeCurrentClient);
    $("#clientsGrid").on("click", ".remove-client-row", removeClientRow);
    $("#openEnvironmentConfig").on("click", function () { window.location.href = "endpoint-config.html"; });
    $("#openLinkConfig").on("click", function () { window.location.href = "link-config.html"; });
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
      environments: [],
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
    const environment = (config.environments || []).find((item) => item.clientId === (current ? current.id : ""));
    const company = (config.companies || []).find((item) => item.clientId === (current ? current.id : "") && (!environment || item.environmentId === environment.id));
    config.selected = {
      clientId: current ? current.id : "",
      environmentId: environment ? environment.id : "",
      companyId: company ? company.id : ""
    };
    if (window.SursumContext && typeof SursumContext.setConfig === "function") {
      config = SursumContext.setConfig(config);
      currentClientId = config.selected.clientId;
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config, null, 2));
  }

  function clientsWithCounts() {
    return (config.clients || []).map((client) => ({
      id: client.id,
      name: client.name,
      environmentCount: (config.environments || []).filter((item) => item.clientId === client.id).length,
      companyCount: (config.companies || []).filter((item) => item.clientId === client.id).length
    }));
  }

  function refresh() {
    persist();
    const clientCombo = $("#clientCombo").data("kendoComboBox");
    clientCombo.setDataSource(new kendo.data.DataSource({ data: config.clients }));
    clientCombo.value((currentClient() || {}).id || "");
    $("#clientsGrid").data("kendoGrid").dataSource.data(clientsWithCounts());
    $("#filePreview").val(JSON.stringify(config, null, 2));
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
    config.companies = config.companies.filter((item) => item.clientId !== clientId);
    config.environments = config.environments.map((item) => item.clientId === clientId ? { ...item, clientId: "" } : item);
    config.clients = config.clients.filter((item) => item.id !== clientId);
    currentClientId = (config.clients[0] || {}).id || "";
    refresh();
    setStatus("Cliente removido.", "ok");
  }

  function importSelectedFile(file) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function () {
      try {
        config = normalizeConfig(JSON.parse(String(reader.result || "{}")));
        currentClientId = (config.selected || {}).clientId || (config.clients[0] || {}).id || "";
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
}());
