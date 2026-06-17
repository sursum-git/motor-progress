(function () {
  let config = null;

  function init() {
    $("button").kendoButton();
    $("#clientCombo, #environmentCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: []
    });

    config = loadConfig();

    $("#clientCombo").data("kendoComboBox").bind("change", onClientChanged);
    $("#environmentCombo").data("kendoComboBox").bind("change", onEnvironmentChanged);
    $("#saveSelection").on("click", saveSelection);

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

  function environmentsForClient(clientId) {
    const linkedIds = new Set((config.links || [])
      .filter(function (link) {
        return link.clientId === clientId;
      })
      .map(function (link) {
        return link.environmentId;
      }));
    return (config.environments || []).filter(function (item) {
      return item.clientId === clientId || linkedIds.has(item.id);
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

    clientCombo.setDataSource(new kendo.data.DataSource({ data: config.clients || [] }));
    clientCombo.value(client ? client.id : "");

    const environments = environmentsForClient(client ? client.id : "");
    environmentCombo.setDataSource(new kendo.data.DataSource({ data: environments }));
    environmentCombo.value(environment ? environment.id : "");

    $("#selectedEndpoint").text(environment && environment.pasoeBaseUrl ? environment.pasoeBaseUrl : "-");
    $("#selectionSummary").text(buildSummary(client, environment));
  }

  function onClientChanged() {
    const clientId = $("#clientCombo").data("kendoComboBox").value();
    const environment = environmentsForClient(clientId)[0] || null;
    if (environment && window.SursumContext) {
      applyClientEnvironment(clientId, environment.id);
    }
    refresh();
  }

  function onEnvironmentChanged() {
    const client = currentClient() || (config.clients || [])[0] || null;
    const environmentId = $("#environmentCombo").data("kendoComboBox").value();
    if (client && environmentId && window.SursumContext) {
      applyClientEnvironment(client.id, environmentId);
    }
    refresh();
  }

  function saveSelection() {
    const clientId = $("#clientCombo").data("kendoComboBox").value();
    const environmentId = $("#environmentCombo").data("kendoComboBox").value();

    if (!clientId || !environmentId) {
      setStatus("Selecione cliente e ambiente.", "error");
      return;
    }

    applyClientEnvironment(clientId, environmentId);

    refresh();
    setStatus("Contexto salvo no localStorage.", "ok");
  }

  function applyClientEnvironment(clientId, environmentId) {
    if (!window.SursumContext) {
      return;
    }

    if (typeof window.SursumContext.setClientEnvironment === "function") {
      window.SursumContext.setClientEnvironment(clientId, environmentId);
      return;
    }

    if (typeof window.SursumContext.setSelection === "function") {
      const currentCompany = typeof window.SursumContext.getCurrentCompany === "function"
        ? window.SursumContext.getCurrentCompany()
        : null;
      window.SursumContext.setSelection(clientId, environmentId, currentCompany ? currentCompany.id : "");
    }
  }

  function buildSummary(client, environment) {
    if (!client || !environment) {
      return "Nenhum contexto definido.";
    }
    return "Cliente: " + client.name
      + " | Ambiente: " + environment.name
      + " | Endpoint: " + (environment.pasoeBaseUrl || "-");
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
}());
