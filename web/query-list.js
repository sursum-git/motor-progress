(function () {
  const LIBRARY_KEY = "sursumSavedQueries";
  const CURRENT_KEY = "sursumCurrentQueryJson";
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  let endpointConfig = { version: 2, companies: [] };

  function init() {
    $("button").kendoButton();
    endpointConfig = loadEndpointConfig();
    $("#companyFilter").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: [{ id: "TODAS", name: "Todas as empresas" }].concat(endpointConfig.companies),
      change: function () {
        const value = this.value() || "TODAS";
        if (value !== "TODAS") localStorage.setItem(SELECTED_COMPANY_KEY, value);
        refreshGrid();
      }
    });
    $("#companyFilter").data("kendoComboBox").value(localStorage.getItem(SELECTED_COMPANY_KEY) || "TODAS");
    $("#searchQuery").kendoTextBox();
    $("#queriesGrid").kendoGrid({
      dataSource: {
        data: loadQueries(),
        schema: { model: { id: "id" } },
        sort: { field: "updatedAt", dir: "desc" }
      },
      height: 620,
      sortable: true,
      filterable: true,
      resizable: true,
      pageable: { pageSize: 20, pageSizes: [20, 50, 100] },
      noRecords: { template: "Nenhuma consulta salva. Clique em Novo para criar a primeira." },
      columns: [
        { field: "name", title: "Consulta", width: 260 },
        { field: "companyName", title: "Empresa", width: 180 },
        { field: "sourcesText", title: "Fontes" },
        { field: "mode", title: "Modo", width: 110 },
        { field: "execution", title: "Execucao", width: 110 },
        { field: "pageSize", title: "Page size", width: 110 },
        { field: "suggestedPath", title: "Arquivo sugerido", width: 260 },
        { field: "updatedAtText", title: "Atualizada em", width: 180 },
        { title: "Acoes", width: 260, template: actionTemplate }
      ]
    });

    $("#newQuery").on("click", newQuery);
    $("#refreshQueries").on("click", refreshGrid);
    $("#searchQuery").on("input", applySearch);
    $("#queriesGrid").on("click", ".edit-query", editQuery);
    $("#queriesGrid").on("click", ".run-query", runQuery);
    $("#queriesGrid").on("click", ".delete-query", deleteQuery);

    setStatus(loadQueries().length + " consulta(s) encontrada(s).", "ok");
  }

  function actionTemplate() {
    return [
      "<button class='k-button k-button-sm edit-query'>Alterar</button>",
      "<button class='k-button k-button-sm run-query'>Resultado</button>",
      "<button class='k-button k-button-sm delete-query'>Excluir</button>"
    ].join(" ");
  }

  function loadQueries() {
    try {
      return JSON.parse(localStorage.getItem(LIBRARY_KEY) || "[]").map(enrichQuery);
    } catch (_) {
      return [];
    }
  }

  function loadEndpointConfig() {
    let raw = null;
    try { raw = JSON.parse(localStorage.getItem(ENDPOINTS_KEY) || "null"); } catch (_) {}
    if (raw && Array.isArray(raw.companies)) return { version: 2, companies: raw.companies };
    const endpoints = Array.isArray(raw) ? raw : (raw && Array.isArray(raw.endpoints) ? raw.endpoints : []);
    return {
      version: 2,
      companies: [{
        id: "empresa-padrao",
        name: "Empresa padrao",
        isDefault: true,
        endpoints
      }]
    };
  }

  function saveQueries(items) {
    localStorage.setItem(LIBRARY_KEY, JSON.stringify(items.map(stripQuery), null, 2));
  }

  function enrichQuery(item) {
    let request = {};
    try { request = JSON.parse(item.json || "{}"); } catch (_) {}
    const sources = Array.isArray(request.sources) ? request.sources : pipelineSources(request.pipeline);
    return {
      ...item,
      companyId: item.companyId || "empresa-padrao",
      companyName: item.companyName || "Empresa padrao",
      suggestedPath: item.suggestedPath || ("queries/" + slugForPath(item.companyName || "Empresa padrao") + "/" + slugForPath(item.name || "consulta") + ".json"),
      mode: Array.isArray(request.pipeline) && request.pipeline.length ? "pipeline" : "object",
      execution: request.execution || "sync",
      pageSize: request.pageSize || "",
      sourcesText: sources.map((source) => [source.banco, source.nome || source.table].filter(Boolean).join(".")).join(", "),
      updatedAtText: item.updatedAt ? new Date(item.updatedAt).toLocaleString("pt-BR") : ""
    };
  }

  function stripQuery(item) {
    return {
      id: item.id,
      name: item.name,
      companyId: item.companyId || "empresa-padrao",
      companyName: item.companyName || "Empresa padrao",
      suggestedPath: item.suggestedPath || ("queries/" + slugForPath(item.companyName || "Empresa padrao") + "/" + slugForPath(item.name || "consulta") + ".json"),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      json: item.json
    };
  }

  function pipelineSources(pipeline) {
    if (!Array.isArray(pipeline)) return [];
    return pipeline
      .filter((step) => step.type === "source")
      .map((step) => {
        try { return typeof step.payload === "string" ? JSON.parse(step.payload) : step.payload; } catch (_) { return {}; }
      });
  }

  function gridItem(event) {
    const grid = $("#queriesGrid").data("kendoGrid");
    return grid.dataItem($(event.currentTarget).closest("tr"));
  }

  function newQuery() {
    localStorage.removeItem(CURRENT_KEY);
    const companyId = selectedCompanyFilter();
    if (companyId !== "TODAS") localStorage.setItem(SELECTED_COMPANY_KEY, companyId);
    window.location.href = "query-builder.html?new=1";
  }

  function editQuery(event) {
    const item = gridItem(event);
    if (!item) return;
    localStorage.setItem(CURRENT_KEY, item.json || "{}");
    localStorage.setItem(SELECTED_COMPANY_KEY, item.companyId || "empresa-padrao");
    window.location.href = "query-builder.html?id=" + encodeURIComponent(item.id);
  }

  function runQuery(event) {
    const item = gridItem(event);
    if (!item) return;
    localStorage.setItem(CURRENT_KEY, item.json || "{}");
    localStorage.setItem(SELECTED_COMPANY_KEY, item.companyId || "empresa-padrao");
    window.location.href = "query-result.html";
  }

  function deleteQuery(event) {
    const item = gridItem(event);
    if (!item) return;
    if (!confirm("Excluir a consulta '" + item.name + "'?")) return;
    saveQueries(loadQueries().filter((query) => query.id !== item.id));
    refreshGrid();
    setStatus("Consulta excluida.", "ok");
  }

  function refreshGrid() {
    const grid = $("#queriesGrid").data("kendoGrid");
    grid.dataSource.data(loadQueries());
    applySearch();
  }

  function applySearch() {
    const text = String($("#searchQuery").val() || "").trim();
    const companyId = selectedCompanyFilter();
    const grid = $("#queriesGrid").data("kendoGrid");
    const filters = [];
    if (companyId !== "TODAS") filters.push({ field: "companyId", operator: "eq", value: companyId });
    if (!text) {
      if (filters.length) {
        grid.dataSource.filter({ logic: "and", filters });
        return;
      }
      grid.dataSource.filter({});
      return;
    }
    filters.push({
      logic: "or",
      filters: [
        { field: "name", operator: "contains", value: text },
        { field: "companyName", operator: "contains", value: text },
        { field: "sourcesText", operator: "contains", value: text },
        { field: "suggestedPath", operator: "contains", value: text },
        { field: "mode", operator: "contains", value: text },
        { field: "execution", operator: "contains", value: text }
      ]
    });
    grid.dataSource.filter({ logic: "and", filters });
  }

  function selectedCompanyFilter() {
    const combo = $("#companyFilter").data("kendoComboBox");
    return combo ? (combo.value() || "TODAS") : "TODAS";
  }

  function slugForPath(value) {
    return String(value || "item").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "item";
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
})();
