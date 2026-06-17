(function () {
  const STORAGE_KEY = "sursumApiEndpoints";
  let config = null;
  let currentClientId = "";
  let currentEnvironmentId = "";
  let currentCompanyId = "";

  function init() {
    $("button").kendoButton();
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
      environments: [{ id: "ambiente-local", name: "Local PASOE", pasoeBaseUrl: "http://localhost:8890/web/SursumDynamicQuery", authMode: "none", authorization: "", companyIdMode: "query", extraQueryParams: "" }],
      links: [],
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
    return (config.links || []).map((link) => {
      const client = (config.clients || []).find((item) => item.id === link.clientId) || {};
      const environment = (config.environments || []).find((item) => item.id === link.environmentId) || {};
      return {
        id: link.id,
        clientId: link.clientId,
        environmentId: link.environmentId,
        clientName: client.name || "",
        environmentName: environment.name || "",
        pasoeBaseUrl: environment.pasoeBaseUrl || ""
      };
    });
  }

  function refresh() {
    const clientCombo = $("#clientCombo").data("kendoComboBox");
    const environmentCombo = $("#environmentCombo").data("kendoComboBox");

    clientCombo.setDataSource(new kendo.data.DataSource({ data: config.clients || [] }));
    clientCombo.value(currentClientId || ((currentClient() || {}).id || ""));
    environmentCombo.setDataSource(new kendo.data.DataSource({ data: config.environments || [] }));
    environmentCombo.value(currentEnvironmentId || ((currentEnvironment() || {}).id || ""));
    $("#linksGrid").data("kendoGrid").dataSource.data(linkRows());
  }

  function refreshAndPersist() {
    persist();
    refresh();
  }

  function onClientChanged() {
    currentClientId = $("#clientCombo").data("kendoComboBox").value() || (currentClient() || {}).id || "";
    refresh();
  }

  function onEnvironmentChanged() {
    currentEnvironmentId = $("#environmentCombo").data("kendoComboBox").value() || (currentEnvironment() || {}).id || "";
    refresh();
  }

  function saveLink() {
    currentClientId = $("#clientCombo").data("kendoComboBox").value() || currentClientId;
    currentEnvironmentId = $("#environmentCombo").data("kendoComboBox").value() || currentEnvironmentId;
    const client = currentClient();
    const environment = currentEnvironment();
    if (!client || !environment) {
      setStatus("Selecione cliente e ambiente.", "error");
      return;
    }
    config.links = (config.links || []).filter((item) => item.environmentId !== environment.id);
    config.links.push({
      id: "link-" + slug(client.id + "-" + environment.id),
      clientId: client.id,
      environmentId: environment.id
    });
    currentClientId = client.id;
    currentEnvironmentId = environment.id;
    refreshAndPersist();
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
    config.links = (config.links || []).filter((item) => item.environmentId !== environmentId);
    refreshAndPersist();
    setStatus("Vinculo removido.", "ok");
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
}());
