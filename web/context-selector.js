(function () {
  let config = null;

  function init() {
    $("button").kendoButton();
    $("#clientCombo, #environmentCombo, #selectedEndpoint").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: []
    });
    $("#selectedEndpoint").data("kendoComboBox").readonly(true);

    config = loadConfig();

    $("#clientCombo").data("kendoComboBox").bind("change", onClientChanged);
    $("#environmentCombo").data("kendoComboBox").bind("change", onEnvironmentChanged);
    $("#saveSelection").on("click", saveSelection);
    $("#openEndpointConfig").on("click", function () { window.location.href = "endpoint-config.html"; });
    $("#openBuilder").on("click", function () { window.location.href = "query-builder.html"; });

    refresh();
  }

  function loadConfig() {
    if (window.SursumContext && typeof window.SursumContext.getConfig === "function") {
      return window.SursumContext.getConfig();
    }
    return {
      clients: [],
      environments: [],
      companies: [],
      selected: {}
    };
  }

  function currentClient() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentClient === "function") {
      return window.SursumContext.getCurrentClient();
    }
    return null;
  }

  function currentEnvironment() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentEnvironment === "function") {
      return window.SursumContext.getCurrentEnvironment();
    }
    return null;
  }

  function companiesForEnvironment(environmentId) {
    if (window.SursumContext && typeof window.SursumContext.getCompaniesForEnvironment === "function") {
      return window.SursumContext.getCompaniesForEnvironment(environmentId) || [];
    }
    return (config.companies || []).filter(function (item) {
      return item.environmentId === environmentId;
    });
  }

  function environmentsForClient(clientId) {
    return (config.environments || []).filter(function (item) {
      return item.clientId === clientId;
    });
  }

  function refresh() {
    config = loadConfig();
    const client = currentClient() || (config.clients || [])[0] || null;
    const environment = currentEnvironment()
      || (client ? environmentsForClient(client.id)[0] : null)
      || (config.environments || [])[0]
      || null;

    const clientCombo = $("#clientCombo").data("kendoComboBox");
    const environmentCombo = $("#environmentCombo").data("kendoComboBox");
    const endpointCombo = $("#selectedEndpoint").data("kendoComboBox");

    clientCombo.setDataSource(new kendo.data.DataSource({ data: config.clients || [] }));
    clientCombo.value(client ? client.id : "");

    const environments = environmentsForClient(client ? client.id : "");
    environmentCombo.setDataSource(new kendo.data.DataSource({ data: environments }));
    environmentCombo.value(environment ? environment.id : "");

    endpointCombo.setDataSource(new kendo.data.DataSource({
      data: environment ? [{ id: environment.id, name: environment.pasoeBaseUrl || "" }] : []
    }));
    endpointCombo.value(environment ? environment.id : "");

    const companies = companiesForEnvironment(environment ? environment.id : "");
    const company = companies[0] || null;
    $("#selectionSummary").text(buildSummary(client, environment, company));
  }

  function onClientChanged() {
    const clientId = $("#clientCombo").data("kendoComboBox").value();
    const environment = environmentsForClient(clientId)[0] || null;
    if (environment && window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      const company = companiesForEnvironment(environment.id)[0] || null;
      window.SursumContext.setSelection(clientId, environment.id, company ? company.id : "");
    }
    refresh();
  }

  function onEnvironmentChanged() {
    const client = currentClient() || (config.clients || [])[0] || null;
    const environmentId = $("#environmentCombo").data("kendoComboBox").value();
    const company = companiesForEnvironment(environmentId)[0] || null;
    if (client && environmentId && window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(client.id, environmentId, company ? company.id : "");
    }
    refresh();
  }

  function saveSelection() {
    const clientId = $("#clientCombo").data("kendoComboBox").value();
    const environmentId = $("#environmentCombo").data("kendoComboBox").value();
    const company = companiesForEnvironment(environmentId)[0] || null;

    if (!clientId || !environmentId) {
      setStatus("Selecione cliente e ambiente.", "error");
      return;
    }

    if (window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(clientId, environmentId, company ? company.id : "");
    }

    refresh();
    setStatus("Contexto salvo no localStorage.", "ok");
  }

  function buildSummary(client, environment, company) {
    if (!client || !environment) {
      return "Nenhum contexto definido.";
    }
    return "Cliente: " + client.name
      + " | Ambiente: " + environment.name
      + " | Endpoint: " + (environment.pasoeBaseUrl || "-")
      + " | Empresa padrao: " + (company ? (company.name + " (" + company.code + ")") : "nao definida");
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
}());
