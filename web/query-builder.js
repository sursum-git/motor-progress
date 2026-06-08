(function () {
  const STORAGE_KEY = "sursumCurrentQueryJson";
  const LIBRARY_KEY = "sursumSavedQueries";
  const API_URL_KEY = "sursumApiBaseUrl";
  const DEFAULT_API = "http://localhost:8890/web/SursumDynamicQuery";
  const ENDPOINTS_KEY = "sursumApiEndpoints";
  const SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  const MAX_STEP = 8;
  const state = {
    currentQueryId: "",
    currentStep: 1,
    initializing: true,
    endpointConfig: { version: 2, companies: [] },
    companies: [],
    endpoints: [],
    databases: [],
    metadataDatabases: [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }],
    tables: [],
    tableRows: [],
    tableSearchCache: {},
    fields: [],
    sources: [],
    joins: [],
    select: [],
    filters: [],
    orderBy: [],
    pipeline: []
  };

  window.pipelineSummary = function (item) {
    let payload = {};
    try { payload = JSON.parse(item.payload || "{}"); } catch (_) {}
    if (item.type === "aggregate") return (payload.op || "sum") + "(" + (payload.field || "*") + ") -> " + (payload.as || "");
    if (item.type === "group" || item.type === "distinct") return "campos: " + (payload.fields || []).join(", ");
    if (item.type === "map") return "map: " + (payload.fields || []).map((f) => (f.from || "") + " -> " + (f.to || "")).join(", ");
    if (item.type === "calculated") return (payload.name || payload.as || "") + " = " + (payload.expression || "");
    if (item.type === "output") return "formato: " + (payload.format || "json");
    if (item.type === "limit") return "pagina " + (payload.page || 1) + ", tamanho " + (payload.pageSize || 500);
    return JSON.stringify(payload);
  };

  function initWidgets() {
    state.endpointConfig = loadEndpointConfig();
    state.companies = state.endpointConfig.companies;
    state.endpoints = endpointsForSelectedCompany();
    $("#execution").kendoDropDownList({ dataSource: ["sync", "async", "auto"], value: "sync" });
    $("#requestMode").kendoDropDownList({
      dataSource: [
        { text: "Objeto estruturado", value: "object" },
        { text: "Pipeline", value: "pipeline" }
      ],
      dataTextField: "text",
      dataValueField: "value",
      value: "object",
      change: onRequestModeChanged
    });
    $("#filterOperator").kendoDropDownList({ dataSource: ["=", "<>", ">", ">=", "<", "<=", "between", "begins", "contains"], value: ">=" });
    $("#orderDirection").kendoDropDownList({ dataSource: ["ASC", "DESC"], value: "ASC" });
    $("#relationType").kendoDropDownList({ dataSource: ["INNER", "LEFT"], value: "INNER" });
    $("#stepType").kendoDropDownList({
      dataSource: ["source", "join", "select", "filter", "sort", "limit", "map", "distinct", "group", "aggregate", "calculated", "output"],
      value: "map",
      change: onPipelineStepTypeChanged
    });
    $("#pipelineOperation").kendoDropDownList({ dataSource: ["sum", "count", "min", "max", "avg"], value: "sum", change: buildVisualStepPayload });
    $("#pipelineField").kendoComboBox({ dataTextField: "name", dataValueField: "name", filter: "contains", dataSource: state.fields, change: buildVisualStepPayload });
    $("#pipelineAlias").kendoTextBox();
    $("#pipelineFields").kendoTextBox();
    $("#pipelineExpression").kendoTextBox();
    $("#pipelineOutputFormat").kendoDropDownList({ dataSource: ["json"], value: "json", change: buildVisualStepPayload });

    $("button").kendoButton();
    $("#pageHelpToggle").kendoTooltip({
      content: function () { return $("#pageHelpToggle").data("help"); },
      position: "right",
      width: 420
    });
    $("#apiCompany").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      filter: "contains",
      dataSource: state.companies,
      change: onApiCompanyChanged
    });
    refreshEndpointCombo(localStorage.getItem(SELECTED_ENDPOINT_KEY));
    ["#sourceDatabase", "#relationLeftDatabase", "#relationRightDatabase"].forEach((selector) => {
      $(selector).kendoComboBox({
        dataTextField: "name",
        dataValueField: "name",
        filter: "contains",
        dataSource: state.databases,
        change: selector === "#sourceDatabase" ? onSourceDatabaseChanged : undefined
      });
    });
    ["#selectionSource", "#filterSelectionSource", "#orderSelectionSource"].forEach((selector) => {
      $(selector).kendoComboBox({
        dataTextField: "displayName",
        dataValueField: "alias",
        filter: "contains",
        dataSource: [],
        change: onSelectionSourceChanged
      });
    });
    $("#page").kendoNumericTextBox({ min: 1, format: "n0", decimals: 0, value: 1 });
    $("#pageSize").kendoNumericTextBox({ min: 1, max: 10000, format: "n0", decimals: 0, value: 500 });

    $("#sourceTable").kendoTextBox();
    $("#tableSearchText").kendoTextBox();
    ["#selectField", "#filterField", "#orderField", "#relationLeftField", "#relationRightField"].forEach((selector) => {
      $(selector).kendoComboBox({ dataTextField: "name", dataValueField: "name", filter: "contains", dataSource: state.fields });
    });
    ["#relationLeftTable", "#relationRightTable"].forEach((selector) => {
      $(selector).kendoComboBox({
        dataTextField: "displayName",
        dataValueField: "nome",
        filter: "contains",
        dataSource: [],
        change: onRelationSourceChanged
      });
    });

    createGrid("#sourcesGrid", state.sources, [
      { field: "banco", title: "Banco", width: 110 },
      { field: "nome", title: "Tabela" },
      { field: "alias", title: "Alias" },
      removeColumn("sources")
    ]);
    createGrid("#joinsGrid", state.joins, [
      { field: "type", title: "Tipo", width: 90 },
      { field: "leftAlias", title: "Alias esq." },
      { field: "leftDatabase", title: "Banco esq.", width: 120 },
      { field: "leftField", title: "Campo esq." },
      { field: "rightAlias", title: "Alias dir." },
      { field: "rightDatabase", title: "Banco dir.", width: 120 },
      { field: "rightField", title: "Campo dir." },
      removeColumn("joins")
    ]);
    createGrid("#selectGrid", state.select, [
      { field: "sourceAlias", title: "Alias" },
      { field: "field", title: "Campo" },
      { field: "outputAlias", title: "Saida" },
      removeColumn("select")
    ]);
    createGrid("#filtersGrid", state.filters, [
      { field: "sourceAlias", title: "Alias" },
      { field: "field", title: "Campo" },
      { field: "operator", title: "Op." },
      { field: "value", title: "Valor" },
      removeColumn("filters")
    ]);
    createGrid("#ordersGrid", state.orderBy, [
      { field: "sourceAlias", title: "Alias" },
      { field: "field", title: "Campo" },
      { field: "direction", title: "Direcao" },
      removeColumn("orderBy")
    ]);
    createGrid("#pipelineGrid", state.pipeline, [
      { field: "type", title: "Step", width: 120 },
      { title: "Resumo", template: "#= pipelineSummary(data) #" },
      { field: "payload", title: "Payload tecnico", width: 360 },
      removeColumn("pipeline")
    ]);
    $("#tableSearchWindow").kendoWindow({
      title: "Buscar tabela",
      width: "780px",
      height: "560px",
      modal: true,
      visible: false
    });
    $("#tableSearchGrid").kendoGrid({
      dataSource: [],
      height: 420,
      sortable: true,
      filterable: true,
      selectable: "row",
      noRecords: { template: "Nenhuma tabela encontrada para o banco selecionado." },
      columns: [
        { field: "name", title: "Codigo da tabela", width: 180 },
        { field: "label", title: "Descricao" },
        { field: "dumpName", title: "Dump-name", width: 180 },
        { field: "database", title: "Banco", width: 150 }
      ]
    });
    onPipelineStepTypeChanged();
  }

  function createGrid(selector, data, columns) {
    $(selector).kendoGrid({
      dataSource: { data, schema: { model: { id: "__id" } } },
      height: 220,
      sortable: true,
      noRecords: { template: "Nenhum item adicionado." },
      columns
    });
  }

  function removeColumn(collection) {
    return { title: " ", width: 96, template: `<button class='k-button k-button-sm remove-row' data-collection='${collection}'>Remover</button>` };
  }

  function bindEvents() {
    $(document).on("click", ".remove-row", function () {
      const collection = $(this).data("collection");
      const grid = $(this).closest(".k-grid").data("kendoGrid");
      const item = grid.dataItem($(this).closest("tr"));
      state[collection] = state[collection].filter((x) => x.__id !== item.__id);
      refreshAll();
    });

    $("#loadMetadata").on("click", function () {
      loadDatabases(function () { loadMetadata(true); });
    });
    $("#loadTable").on("click", loadTypedTable);
    $("#sourceTable").on("blur", validateTypedTableOnBlur);
    $("#searchTable").on("click", openTableSearch);
    $("#applyTableSearch").on("click", applyTableSearch);
    $("#reloadTableSearch").on("click", reloadTableSearch);
    $("#tableSearchGrid").on("dblclick", "tbody tr", selectTableFromSearch);
    $("#addSource").on("click", addSource);
    $("#clearSources").on("click", function () { state.sources = []; refreshAll(); });
    $("#addSelect").on("click", () => addSelectField(inputValue("#selectField", "CustNum")));
    $("#addFilter").on("click", addFilter);
    $("#addOrder").on("click", addOrder);
    $("#saveRelation").on("click", saveRelation);
    $("#loadRelation").on("click", loadRelation);
    $("#addRelationAsJoin").on("click", addRelationAsJoin);
    $("#addStep").on("click", addStep);
    $("#previewStepPayload").on("click", buildVisualStepPayload);
    $("#pipelineAlias, #pipelineFields, #pipelineExpression").on("input", buildVisualStepPayload);
    $("#addPipelineFromForm").on("click", function () { regeneratePipelineBase(true); });
    $("#clearPipeline").on("click", function () { state.pipeline = []; refreshAll(); });
    $("#buildJson").on("click", refreshJson);
    $("#copyJson").on("click", copyJson);
    $("#downloadJson").on("click", downloadJson);
    $("#openResultPage").on("click", openResultPage);
    $("#saveQuery").on("click", saveCurrentQuery);
    $("#saveQueryAs").on("click", saveCurrentQueryAs);
    $("#openContextSelector").on("click", function () { window.location.href = "context-selector.html"; });
    $("#openEndpointConfig").on("click", function () { window.location.href = "endpoint-config.html"; });
    $("#openDatabaseAliasConfig").on("click", function () { window.location.href = "database-alias-config.html"; });
    $("#openMetadataStorageConfig").on("click", function () { window.location.href = "metadata-storage-config.html"; });
    $("#openFieldMetadataConfig").on("click", function () { window.location.href = "field-metadata-config.html"; });
    $("#openMetadataSyncWizard").on("click", function () { window.location.href = "metadata-sync-wizard.html"; });
    $("#openLogicBuilder").on("click", function () { window.location.href = "logic-list.html"; });
    $("#pageHelpToggle").on("dblclick", copyPageHelp);
    $("#backToQueryList").on("click", function () { window.location.href = "query-list.html"; });
    $("#prevStep").on("click", function () { showStep(state.currentStep - 1); });
    $("#nextStep").on("click", nextStep);
    $(".wizard-step").on("click", function () { showStep(Number($(this).data("step"))); });
    $("#loadCustomerSample").on("click", loadCustomerSample);
    $("#loadAdvancedSample").on("click", loadAdvancedSample);
  }

  function showStep(step) {
    const next = Math.max(1, Math.min(MAX_STEP, step || 1));
    state.currentStep = next;
    $(".wizard-step").removeClass("is-active");
    $(".wizard-step[data-step='" + next + "']").addClass("is-active");
    $(".wizard-panel").removeClass("is-active");
    $(".wizard-panel[data-step-panel='" + next + "']").addClass("is-active");
    $("#prevStep").prop("disabled", next === 1);
    $("#nextStep").prop("disabled", next === MAX_STEP);
    if (next === 7) ensurePipelineBase();
    refreshJson();
  }

  function onRequestModeChanged() {
    if (dropdownValue("#requestMode") === "pipeline") {
      ensurePipelineBase();
      setStatus("Modo pipeline ativado. A base foi gerada automaticamente a partir da consulta.", "ok");
    }
    refreshJson();
  }

  function nextStep() {
    if (state.currentStep === 1) {
      loadMetadataForStepTwo();
      return;
    }
    if (state.currentStep === 2) {
      loadFieldsForStepThree();
      return;
    }
    showStep(state.currentStep + 1);
  }

  function loadMetadataForStepTwo() {
    setStatus("Preparando tabelas e campos para a etapa 2...", "");
    const afterTables = function () {
      const table = inputValue("#sourceTable", "");
      if (table) {
        loadFields(table, function () { showStep(2); });
      } else {
        showStep(2);
      }
    };

    if (state.tables && state.tables.length) {
      afterTables();
      return;
    }
    loadMetadata(true, afterTables);
  }

  function loadFieldsForStepThree() {
    const source = selectedStepThreeSource();
    if (!source) {
      setStatus("Adicione ao menos uma fonte antes de ir para a etapa 3.", "error");
      return;
    }
    refreshSelectionSourceCombo();
    loadFieldsForSource(source, function () { showStep(3); });
  }

  function loadDatabases(done) {
    setMetadataProgress("Buscando bancos conectados no PASOE...", 10);
    $.getJSON(apiBase() + "/metadata/databases")
      .done(function (response) {
        if (!response.success) throw new Error(apiError(response));
        state.databases = response.data && response.data.length ? response.data : [];
        state.metadataDatabases = [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }].concat(state.databases);
        refreshDatabaseCombos();
        if (typeof done === "function") done();
      })
      .fail(function () {
        state.databases = [];
        state.metadataDatabases = [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }].concat(state.databases);
        if (typeof done === "function") done();
      });
  }

  function loadMetadata(incremental, done) {
    setMetadataProgress((incremental ? "Atualizando alteracoes de metadados" : "Fazendo carga inicial de metadados") + " de todos os bancos conhecidos...", 35);
    setStatus("Carregando lista de tabelas de todos os bancos conhecidos pelo PASOE...", "");
    $.getJSON(apiBase() + "/metadata/tables?database=" + encodeURIComponent(selectedDatabase()) + "&mode=" + (incremental ? "changed" : "initial"))
      .done(function (response) {
        if (!response.success) throw new Error(apiError(response));
        state.tableRows = response.data || [];
        state.tableSearchCache = {};
        state.tables = uniqueTables(state.tableRows);
        state.databases = uniqueDatabases(state.tableRows);
        const dbCombo = $("#sourceDatabase").data("kendoComboBox");
        dbCombo.setDataSource(new kendo.data.DataSource({ data: state.databases }));
        dbCombo.value(dbCombo.value() || firstRealDatabase());
        refreshDatabaseCombos();
        saveMetadataCacheMarker(selectedDatabase(), response);
        setMetadataProgress("Lista de tabelas pronta. Tabelas: " + state.tables.length + ". Bancos: " + state.databases.length, 100);
        setStatus("Lista de tabelas carregada. Selecione uma tabela na etapa 2 para carregar bancos e campos.", "ok");
        if (typeof done === "function") done();
      })
      .fail(function (xhr) { setStatus("Falha ao carregar metadados: " + xhr.status + " " + xhr.statusText, "error"); });
  }

  function loadFields(table, done) {
    if (!table) return;
    if (!sourceDatabase()) refreshSourceDatabasesForTable(table);
    if (!sourceDatabase()) {
      setStatus("Selecione uma tabela com banco disponivel antes de carregar campos.", "error");
      return;
    }
    setStatus("Carregando campos de " + sourceDatabase() + "." + table + "...", "");
    $.getJSON(apiBase() + "/metadata/tables/" + encodeURIComponent(table) + "/fields?database=" + encodeURIComponent(sourceDatabase()))
      .done(function (response) {
        if (!response.success) throw new Error(apiError(response));
        state.fields = response.fields || response.data || [];
        refreshFieldWidgets();
        setStatus("Campos carregados para " + sourceDatabase() + "." + table + ": " + state.fields.length, "ok");
        if (typeof done === "function") done();
      })
      .fail(function (xhr) { setStatus("Falha ao carregar campos: " + xhr.status + " " + xhr.statusText, "error"); });
  }

  function loadFieldsForSource(source, done) {
    if (!source || !source.nome) return;
    if (!source.banco) {
      setStatus("A fonte " + (source.alias || source.nome) + " nao possui banco informado.", "error");
      return;
    }
    setStatus("Carregando campos de " + source.banco + "." + source.nome + "...", "");
    $.getJSON(apiBase() + "/metadata/tables/" + encodeURIComponent(source.nome) + "/fields?database=" + encodeURIComponent(source.banco))
      .done(function (response) {
        if (!response.success) throw new Error(apiError(response));
        state.fields = response.fields || response.data || [];
        refreshFieldWidgets();
        applyStepThreeSource(source);
        setStatus("Campos carregados para " + source.banco + "." + source.nome + ": " + state.fields.length, "ok");
        if (typeof done === "function") done();
      })
      .fail(function (xhr) { setStatus("Falha ao carregar campos: " + xhr.status + " " + xhr.statusText, "error"); });
  }

  function loadTypedTable() {
    const table = inputValue("#sourceTable", "");
    if (!table) {
      setStatus("Informe a tabela antes de carregar.", "error");
      return;
    }
    if (!tableExistsForSourceDatabase(table)) {
      setStatus("Tabela nao encontrada no banco " + sourceDatabase() + ": " + table, "error");
      return;
    }
    onSourceTableChanged({ name: table, database: sourceDatabase() });
  }

  function validateTypedTableOnBlur() {
    const table = inputValue("#sourceTable", "");
    if (!table) return;
    if (!sourceDatabase()) {
      setStatus("Selecione o banco da fonte antes de validar a tabela.", "error");
      return;
    }
    if (!tableExistsForSourceDatabase(table)) {
      state.fields = [];
      refreshFieldWidgets();
      setStatus("Tabela nao encontrada no banco " + sourceDatabase() + ": " + table, "error");
      return;
    }
    onSourceTableChanged({ name: canonicalTableName(table), database: sourceDatabase() });
  }

  function tableExistsForSourceDatabase(table) {
    const database = sourceDatabase();
    return (state.tableRows || []).some((row) =>
      String(row.database || "").toLowerCase() === String(database || "").toLowerCase() &&
      String(row.name || "").toLowerCase() === String(table || "").toLowerCase()
    );
  }

  function canonicalTableName(table) {
    const database = sourceDatabase();
    const row = (state.tableRows || []).find((item) =>
      String(item.database || "").toLowerCase() === String(database || "").toLowerCase() &&
      String(item.name || "").toLowerCase() === String(table || "").toLowerCase()
    );
    return row ? row.name : table;
  }

  function onSourceTableChanged(selectedItem) {
    const item = selectedItem && selectedItem.name ? selectedItem : null;
    const table = item && item.name ? item.name : inputValue("#sourceTable", "Customer");
    if (item && item.database) $("#sourceDatabase").data("kendoComboBox").value(item.database);
    setComboValue("#relationLeftTable", table);
    $("#relationLeftDatabase").data("kendoComboBox").value(sourceDatabase());
    if (sourceDatabase()) loadFields(table);
  }

  function onSourceDatabaseChanged() {
    const table = inputValue("#sourceTable", "");
    if (table) loadFields(table);
  }

  function refreshSourceDatabasesForTable(table) {
    const databases = databasesForTable(table);
    const combo = $("#sourceDatabase").data("kendoComboBox");
    combo.setDataSource(new kendo.data.DataSource({ data: databases }));
    combo.dataSource.read();
    const current = combo.value();
    const selected = databases.find((db) => db.name === current) || databases[0];
    combo.value(selected ? selected.name : "");
    combo.refresh();
  }

  function databasesForTable(table) {
    const seen = {};
    return (state.tableRows || [])
      .filter((row) => String(row.name || "").toLowerCase() === String(table || "").toLowerCase())
      .map((row) => row.database || row.banco || "")
      .filter((name) => name && !seen[name] && (seen[name] = true))
      .map((name) => ({ name, logicalName: name, displayName: name }));
  }

  function uniqueTables(rows) {
    const seen = {};
    return (rows || [])
      .filter((row) => row && row.name && !seen[String(row.name).toLowerCase()] && (seen[String(row.name).toLowerCase()] = true))
      .map((row) => ({
        name: row.name,
        displayName: row.name,
        label: row.label || "",
        dumpName: row.dumpName || "",
        lastUpdate: row.lastUpdate || ""
      }));
  }

  function uniqueDatabases(rows) {
    const seen = {};
    return (rows || [])
      .map((row) => row.database || row.banco || "")
      .filter((name) => name && !seen[name] && (seen[name] = true))
      .map((name) => ({ name, logicalName: name, displayName: name }));
  }

  function openTableSearch() {
    const database = sourceDatabase();
    if (!database) {
      setStatus("Selecione o banco da fonte antes de buscar tabelas.", "error");
      return;
    }
    ensureTableSearchCache(database, false);
    applyTableSearch();
    $("#tableSearchWindow").data("kendoWindow").center().open();
  }

  function reloadTableSearch() {
    const database = sourceDatabase();
    if (!database) {
      setStatus("Selecione o banco da fonte antes de recarregar tabelas.", "error");
      return;
    }
    ensureTableSearchCache(database, true);
    applyTableSearch();
    setStatus("Busca de tabelas recarregada para " + database + ".", "ok");
  }

  function ensureTableSearchCache(database, forceReload) {
    if (!forceReload && state.tableSearchCache[database]) return;
    state.tableSearchCache[database] = (state.tableRows || [])
      .filter((row) => row.database === database)
      .map((row) => ({
        name: row.name || "",
        label: row.label || "",
        dumpName: row.dumpName || "",
        database: row.database || ""
      }));
  }

  function applyTableSearch() {
    const database = sourceDatabase();
    const text = String($("#tableSearchText").val() || "").toLowerCase();
    ensureTableSearchCache(database, false);
    const rows = (state.tableSearchCache[database] || [])
      .filter((row) => {
        if (!text) return true;
        return String(row.name || "").toLowerCase().includes(text) ||
          String(row.label || "").toLowerCase().includes(text) ||
          String(row.dumpName || "").toLowerCase().includes(text);
      });
    $("#tableSearchGrid").data("kendoGrid").dataSource.data(rows);
  }

  function selectTableFromSearch() {
    const grid = $("#tableSearchGrid").data("kendoGrid");
    const item = grid.dataItem($(this));
    if (!item) return;
    $("#sourceDatabase").data("kendoComboBox").value(item.database || sourceDatabase());
    $("#sourceTable").val(item.name || "");
    if (!$("#sourceAlias").val()) $("#sourceAlias").val(String(item.name || "").charAt(0).toLowerCase() + String(item.name || "").slice(1));
    $("#tableSearchWindow").data("kendoWindow").close();
    onSourceTableChanged(item);
  }

  function refreshFieldWidgets() {
    ["#selectField", "#filterField", "#orderField", "#relationLeftField", "#relationRightField"].forEach((selector) => {
      const combo = $(selector).data("kendoComboBox");
      if (combo) combo.setDataSource(new kendo.data.DataSource({ data: state.fields }));
    });
    const pipelineField = $("#pipelineField").data("kendoComboBox");
    if (pipelineField) pipelineField.setDataSource(new kendo.data.DataSource({ data: state.fields }));
  }

  function refreshRelationSourceCombos() {
    const rows = (state.sources || []).map((source) => ({
      ...source,
      displayName: (source.alias || source.nome) + " - " + (source.banco || "") + "." + (source.nome || "")
    }));
    ["#relationLeftTable", "#relationRightTable"].forEach((selector) => {
      const combo = $(selector).data("kendoComboBox");
      if (!combo) return;
      const current = combo.value();
      combo.setDataSource(new kendo.data.DataSource({ data: rows }));
      combo.dataSource.read();
      combo.value(rows.some((source) => source.nome === current) ? current : (rows[0] ? rows[0].nome : ""));
      combo.refresh();
    });
    applyRelationSourceSide("left");
    applyRelationSourceSide("right");
  }

  function onRelationSourceChanged(e) {
    const id = e && e.sender && e.sender.element ? e.sender.element.attr("id") : "";
    applyRelationSourceSide(id === "relationRightTable" ? "right" : "left");
  }

  function applyRelationSourceSide(side) {
    const tableSelector = side === "right" ? "#relationRightTable" : "#relationLeftTable";
    const dbSelector = side === "right" ? "#relationRightDatabase" : "#relationLeftDatabase";
    const table = inputValue(tableSelector, "");
    const source = (state.sources || []).find((item) => item.nome === table);
    if (!source) return;
    const dbCombo = $(dbSelector).data("kendoComboBox");
    if (dbCombo) dbCombo.value(source.banco || "");
  }

  function refreshSelectionSourceCombo() {
    const rows = (state.sources || []).map((source) => ({
      ...source,
      displayName: (source.alias || source.nome) + " - " + (source.banco || "") + "." + (source.nome || "")
    }));
    ["#selectionSource", "#filterSelectionSource", "#orderSelectionSource"].forEach((selector) => {
      const combo = $(selector).data("kendoComboBox");
      if (!combo) return;
      const current = combo.value();
      combo.setDataSource(new kendo.data.DataSource({ data: rows }));
      combo.dataSource.read();
      const selected = rows.find((source) => source.alias === current) || rows[0];
      combo.value(selected ? selected.alias : "");
      combo.refresh();
    });
    $("#selectionSourceRow, #filterSourceRow, #orderSourceRow").toggle(rows.length > 1);
    const selected = selectedStepThreeSource();
    if (selected) applyStepThreeSource(selected);
  }

  function selectedStepThreeSource() {
    const combo = $("#selectionSource").data("kendoComboBox");
    const alias = combo ? combo.value() : "";
    return (state.sources || []).find((source) => source.alias === alias) || (state.sources || [])[0] || null;
  }

  function onSelectionSourceChanged() {
    const source = selectedStepThreeSource();
    if (!source) return;
    loadFieldsForSource(source);
  }

  function applyStepThreeSource(source) {
    if (!source) return;
    $("#selectAlias").val(source.alias || "");
    $("#filterAlias").val(source.alias || "");
    $("#orderAlias").val(source.alias || "");
  }

  function addSource() {
    const table = inputValue("#sourceTable", "Customer");
    const alias = inputValue("#sourceAlias", table.charAt(0).toLowerCase() + table.slice(1));
    const existingSources = state.sources.slice();
    const newSource = { nome: canonicalTableName(table), alias, banco: sourceDatabase() };
    if (!sourceDatabase()) {
      setStatus("Selecione o banco da fonte antes de adicionar a tabela.", "error");
      return;
    }
    if (!tableExistsForSourceDatabase(table)) {
      setStatus("Tabela nao encontrada no banco " + sourceDatabase() + ": " + table, "error");
      return;
    }
    addItem("sources", newSource);
    autoLoadJoinsForSource(newSource, existingSources);
  }

  function addSelectField(fieldName) {
    addItem("select", {
      sourceAlias: inputValue("#selectAlias", inputValue("#sourceAlias", "customer")),
      field: fieldName,
      outputAlias: inputValue("#selectOutput", fieldName)
    });
  }

  function addFilter() {
    addItem("filters", {
      sourceAlias: inputValue("#filterAlias", inputValue("#sourceAlias", "customer")),
      field: inputValue("#filterField", "CustNum"),
      operator: dropdownValue("#filterOperator"),
      value: inputValue("#filterValue", "1")
    });
  }

  function addOrder() {
    addItem("orderBy", {
      sourceAlias: inputValue("#orderAlias", inputValue("#sourceAlias", "customer")),
      field: inputValue("#orderField", "CustNum"),
      direction: dropdownValue("#orderDirection")
    });
  }

  function saveRelation() {
    const relation = buildRelation();
    const validation = validateRelation(relation);
    if (validation) {
      setStatus(validation, "error");
      return;
    }
    $("#relationPreview").val(JSON.stringify(relation, null, 2));
    setStatus("Salvando relacao...", "");
    $.ajax({
      url: apiBase() + "/metadata/relations",
      method: "POST",
      contentType: "application/json",
      dataType: "json",
      data: JSON.stringify(relation)
    }).done(function (response) {
      if (!response.success) {
        setStatus("Erro ao salvar relacao: " + apiError(response), "error");
        return;
      }
      $("#relationPreview").val(JSON.stringify(response.relation || relation, null, 2));
      setStatus("Relacao salva em " + response.path, "ok");
    }).fail(function (xhr) { setStatus("Falha HTTP ao salvar relacao: " + xhr.status + " " + xhr.statusText, "error"); });
  }

  function loadRelation() {
    const left = inputValue("#relationLeftTable", "Customer");
    const right = inputValue("#relationRightTable", "Order");
    setStatus("Buscando relacao " + relationLeftDatabase() + "." + left + " x " + relationRightDatabase() + "." + right + "...", "");
    $.getJSON(apiBase() + "/metadata/relations/" + encodeURIComponent(left) + "/" + encodeURIComponent(right) + "?leftDatabase=" + encodeURIComponent(relationLeftDatabase()) + "&rightDatabase=" + encodeURIComponent(relationRightDatabase()))
      .done(function (response) {
        if (!response.success) {
          setStatus("Relacao nao encontrada: " + apiError(response), "error");
          return;
        }
        const relation = response.relation || response;
        applyRelationToForm(relation);
        $("#relationPreview").val(JSON.stringify(relation, null, 2));
        setStatus("Relacao carregada.", "ok");
      })
      .fail(function (xhr) { setStatus("Falha HTTP ao buscar relacao: " + xhr.status + " " + xhr.statusText, "error"); });
  }

  function buildRelation() {
    return {
      leftTable: inputValue("#relationLeftTable", "Customer"),
      leftField: inputValue("#relationLeftField", "CustNum"),
      leftDatabase: relationLeftDatabase(),
      rightTable: inputValue("#relationRightTable", "Order"),
      rightField: inputValue("#relationRightField", "CustNum"),
      rightDatabase: relationRightDatabase(),
      type: dropdownValue("#relationType") || "INNER"
    };
  }

  function applyRelationToForm(relation) {
    setComboValue("#relationLeftTable", relation.leftTable || relation.left || "");
    $("#relationLeftField").val(relation.leftField || "");
    $("#relationLeftDatabase").data("kendoComboBox").value(relation.leftDatabase || relation.database || selectedDatabase());
    setComboValue("#relationRightTable", relation.rightTable || relation.right || "");
    $("#relationRightField").val(relation.rightField || "");
    $("#relationRightDatabase").data("kendoComboBox").value(relation.rightDatabase || relation.database || selectedDatabase());
    const relType = $("#relationType").data("kendoDropDownList");
    if (relType) relType.value(relation.type || "INNER");
  }

  function addRelationAsJoin() {
    let relation = buildRelation();
    try {
      const preview = JSON.parse($("#relationPreview").val() || "{}");
      if (preview.leftTable || preview.rightTable) relation = preview;
    } catch (_) {}

    const validation = validateRelation(relation);
    if (validation) {
      setStatus(validation, "error");
      return;
    }

    addJoinFromRelation(relation, false);
  }

  function autoLoadJoinsForSource(newSource, existingSources) {
    if (!newSource || !existingSources || !existingSources.length) return;
    let found = 0;
    let completed = 0;
    const total = existingSources.length;
    setStatus("Buscando relacoes salvas para " + (newSource.banco || "") + "." + newSource.nome + "...", "");

    existingSources.forEach((source) => {
      tryLoadRelationForSources(source, newSource, function (added) {
        if (added) found += 1;
        completed += 1;
        if (completed === total) {
          if (found > 0) setStatus("Joins automaticos adicionados: " + found + ".", "ok");
          else setStatus("Fonte adicionada. Nenhuma relacao salva encontrada para joins automaticos.", "ok");
        }
      });
    });
  }

  function tryLoadRelationForSources(leftSource, rightSource, done) {
    fetchSavedRelation(leftSource, rightSource)
      .done(function (response) {
        if (response && response.success && addJoinFromRelation(response.relation || response, true)) {
          done(true);
          return;
        }
        fetchSavedRelation(rightSource, leftSource)
          .done(function (reverseResponse) {
            done(!!(reverseResponse && reverseResponse.success && addJoinFromRelation(reverseResponse.relation || reverseResponse, true)));
          })
          .fail(function () { done(false); });
      })
      .fail(function () {
        fetchSavedRelation(rightSource, leftSource)
          .done(function (reverseResponse) {
            done(!!(reverseResponse && reverseResponse.success && addJoinFromRelation(reverseResponse.relation || reverseResponse, true)));
          })
          .fail(function () { done(false); });
      });
  }

  function fetchSavedRelation(leftSource, rightSource) {
    return $.getJSON(apiBase() + "/metadata/relations/" + encodeURIComponent(leftSource.nome) + "/" + encodeURIComponent(rightSource.nome) +
      "?leftDatabase=" + encodeURIComponent(leftSource.banco || "") +
      "&rightDatabase=" + encodeURIComponent(rightSource.banco || ""));
  }

  function addJoinFromRelation(relation, silent) {
    const validation = validateRelation(relation);
    if (validation) {
      if (!silent) setStatus(validation, "error");
      return false;
    }

    const leftAlias = aliasForTable(relation.leftTable || relation.left);
    const rightAlias = aliasForTable(relation.rightTable || relation.right);
    state.joins.push({
      __id: newId(),
      type: relation.type || "INNER",
      leftAlias,
      leftDatabase: relation.leftDatabase || relation.database || selectedDatabase(),
      leftField: relation.leftField,
      rightAlias,
      rightDatabase: relation.rightDatabase || relation.database || selectedDatabase(),
      rightField: relation.rightField
    });
    refreshAll();
    return true;
  }

  function validateRelation(relation) {
    const leftTable = relation.leftTable || relation.left || "";
    const rightTable = relation.rightTable || relation.right || "";
    const leftDatabase = relation.leftDatabase || relation.database || selectedDatabase();
    const rightDatabase = relation.rightDatabase || relation.database || selectedDatabase();
    const leftKey = relationKey(leftDatabase, leftTable);
    const rightKey = relationKey(rightDatabase, rightTable);
    if (!leftTable || !rightTable) return "Informe as tabelas esquerda e direita da relacao.";
    if (leftKey === rightKey) return "A relacao nao pode usar a mesma tabela no lado esquerdo e direito.";
    if (!relation.leftField || !relation.rightField) return "Informe os campos esquerdo e direito da relacao.";
    const duplicate = (state.joins || []).some((join) => {
      const joinLeft = relationKey(join.leftDatabase, tableForAlias(join.leftAlias));
      const joinRight = relationKey(join.rightDatabase, tableForAlias(join.rightAlias));
      return (joinLeft === leftKey && joinRight === rightKey && join.leftField === relation.leftField && join.rightField === relation.rightField) ||
        (joinLeft === rightKey && joinRight === leftKey && join.leftField === relation.rightField && join.rightField === relation.leftField);
    });
    return duplicate ? "Esta relacao ja foi adicionada." : "";
  }

  function relationKey(database, table) {
    return String(database || "").toLowerCase() + "." + String(table || "").toLowerCase();
  }

  function tableForAlias(alias) {
    const source = (state.sources || []).find((item) => item.alias === alias || item.nome === alias);
    return source ? source.nome : alias;
  }

  function aliasForTable(table) {
    const source = state.sources.find((item) => item.nome.toLowerCase() === String(table || "").toLowerCase());
    return source ? source.alias : String(table || "").charAt(0).toLowerCase() + String(table || "").slice(1);
  }

  function addStep() {
    buildVisualStepPayload();
    addItem("pipeline", { type: dropdownValue("#stepType"), payload: inputValue("#stepPayload", "{}") });
  }

  function addItem(collection, item) {
    item.__id = newId();
    state[collection].push(item);
    refreshAll();
  }

  function refreshAll() {
    refreshSelectionSourceCombo();
    refreshRelationSourceCombos();
    refreshGrid("#sourcesGrid", state.sources);
    refreshGrid("#joinsGrid", state.joins);
    refreshGrid("#selectGrid", state.select);
    refreshGrid("#filtersGrid", state.filters);
    refreshGrid("#ordersGrid", state.orderBy);
    refreshGrid("#pipelineGrid", state.pipeline);
    refreshPipelineFlow();
    refreshJson();
  }

  function refreshGrid(selector, data) {
    const grid = $(selector).data("kendoGrid");
    if (grid) grid.dataSource.data(data);
  }

  function refreshJson() {
    $("#jsonPreview").val(JSON.stringify(buildRequest(), null, 2));
  }

  function buildRequest() {
    const mode = dropdownValue("#requestMode");
    const request = {
      execution: dropdownValue("#execution") || "sync",
      pipelineVersion: inputValue("#pipelineVersion", ""),
      page: numericValue("#page", 1),
      pageSize: numericValue("#pageSize", 500)
    };

    if (mode === "pipeline") {
      request.pipeline = state.pipeline.map(cleanPipelineStep);
      return request;
    }

    request.sources = state.sources.map(cleanObject);
    request.joins = state.joins.map(cleanObject);
    request.select = state.select.map(cleanObject);
    request.filters = state.filters.map(cleanObject);
    request.orderBy = state.orderBy.map(cleanObject);
    return request;
  }

  function buildPipelineFromForm() {
    const steps = [];
    state.sources.forEach((source) => steps.push(step("source", source)));
    state.joins.forEach((join) => steps.push(step("join", join)));
    if (state.select.length) steps.push(step("select", { fields: state.select.map(cleanObject) }));
    state.filters.forEach((filter) => steps.push(step("filter", filter)));
    if (state.orderBy.length) steps.push(step("sort", { fields: state.orderBy.map(cleanObject) }));
    steps.push(step("limit", { page: numericValue("#page", 1), pageSize: numericValue("#pageSize", 500) }));
    steps.push(step("output", { format: "json" }));
    return steps;
  }

  function ensurePipelineBase() {
    if (dropdownValue("#requestMode") !== "pipeline") return;
    if (!state.sources.length) return;
    if (!state.pipeline.length || onlyGeneratedBaseSteps(state.pipeline)) {
      regeneratePipelineBase(false);
    }
  }

  function regeneratePipelineBase(showMessage) {
    const advanced = (state.pipeline || []).filter((item) => !isGeneratedBaseStep(item));
    state.pipeline = withIds(buildPipelineFromForm().concat(advanced.map((item) => ({ type: item.type, payload: item.payload }))));
    refreshAll();
    if (showMessage) setStatus("Base do pipeline regenerada. Steps avancados foram preservados.", "ok");
  }

  function onlyGeneratedBaseSteps(steps) {
    return (steps || []).every(isGeneratedBaseStep);
  }

  function isGeneratedBaseStep(item) {
    return ["source", "join", "select", "filter", "sort", "limit", "output"].includes(item.type);
  }

  function step(type, payload) {
    return { type, payload: JSON.stringify(cleanObject(payload)) };
  }

  function cleanPipelineStep(item) {
    return { type: item.type, payload: item.payload };
  }

  function cleanObject(item) {
    const out = {};
    Object.keys(item || {}).forEach((key) => {
      if (key !== "__id" && item[key] !== "" && item[key] !== null && item[key] !== undefined) out[key] = item[key];
    });
    return out;
  }

  function setStepPayloadTemplate() {
    const type = dropdownValue("#stepType");
    const templates = {
      source: { nome: "Customer", alias: "customer", banco: sourceDatabase() },
      join: { type: "INNER", leftAlias: "customer", leftField: "CustNum", rightAlias: "order", rightField: "CustNum" },
      select: { fields: [{ sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" }] },
      filter: { sourceAlias: "customer", field: "CustNum", operator: ">=", value: "1" },
      sort: { fields: [{ sourceAlias: "customer", field: "CustNum", direction: "ASC" }] },
      limit: { page: 1, pageSize: 500 },
      map: { fields: [{ from: "codigo", to: "codigo" }, { from: "nome", to: "cliente" }] },
      distinct: { fields: ["codigo"] },
      group: { fields: ["uf"] },
      aggregate: { op: "sum", field: "saldo", as: "saldoTotal" },
      calculated: { name: "tipo-final", type: "character", sourceFields: ["char-1"], expression: "substring(char-1,1,2)" },
      output: { format: "json" }
    };
    $("#stepPayload").val(JSON.stringify(templates[type] || {}, null, 2));
  }

  function onPipelineStepTypeChanged() {
    $(".pipeline-editor-card").attr("data-step-type", dropdownValue("#stepType"));
    buildVisualStepPayload();
  }

  function buildVisualStepPayload() {
    const type = dropdownValue("#stepType");
    const field = comboOrInputValue("#pipelineField");
    const alias = inputValue("#pipelineAlias", "");
    const fields = splitCsv(inputValue("#pipelineFields", ""));
    const expression = inputValue("#pipelineExpression", "");
    const op = dropdownValue("#pipelineOperation") || "sum";
    let payload = {};

    if (type === "source" || type === "join" || type === "select" || type === "filter" || type === "sort" || type === "limit") {
      setStepPayloadTemplate();
      return;
    }
    if (type === "map") {
      payload = { fields: fields.length ? fields.map((name) => ({ from: name, to: name })) : [{ from: field || "codigo", to: alias || field || "codigo" }] };
    } else if (type === "distinct" || type === "group") {
      payload = { fields: fields.length ? fields : [field || "codigo"] };
    } else if (type === "aggregate") {
      payload = { op, field: field || "saldo", as: alias || (op + capitalize(field || "campo")) };
    } else if (type === "calculated") {
      payload = {
        name: alias || field || "campo-calculado",
        type: "character",
        sourceFields: fields,
        expression: expression || "substring(char-1,1,2)"
      };
    } else if (type === "output") {
      payload = { format: dropdownValue("#pipelineOutputFormat") || "json" };
    }

    $("#stepPayload").val(JSON.stringify(payload, null, 2));
  }

  function refreshPipelineFlow() {
    const target = $("#pipelineFlow");
    if (!target.length) return;
    if (!state.pipeline.length) {
      target.html("<div class='pipeline-empty'>Nenhum step. Gere a base da consulta ou adicione um bloco.</div>");
      return;
    }
    target.html(state.pipeline.map((item, index) => {
      const summary = window.pipelineSummary(item).replace(/[<>&]/g, (ch) => ({ "<": "&lt;", ">": "&gt;", "&": "&amp;" }[ch]));
      return `<div class="pipeline-node"><span>${index + 1}</span><strong>${item.type}</strong><small>${summary}</small></div>`;
    }).join("<div class='pipeline-arrow'>↓</div>"));
  }

  function loadCustomerSample() {
    state.sources = withIds([{ nome: "Customer", alias: "customer", banco: sourceDatabase() }]);
    state.joins = [];
    state.select = withIds([
      { sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" },
      { sourceAlias: "customer", field: "Name", outputAlias: "nome" }
    ]);
    state.filters = withIds([{ sourceAlias: "customer", field: "CustNum", operator: ">=", value: "1" }]);
    state.orderBy = withIds([{ sourceAlias: "customer", field: "CustNum", direction: "ASC" }]);
    state.pipeline = [];
    dropdown("#requestMode").value("object");
    dropdown("#execution").value("sync");
    refreshAll();
    setStatus("Exemplo simples carregado.", "ok");
  }

  function loadAdvancedSample() {
    loadCustomerSample();
    state.select = withIds([
      { sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" },
      { sourceAlias: "customer", field: "Name", outputAlias: "nome" },
      { sourceAlias: "customer", field: "State", outputAlias: "estado" },
      { sourceAlias: "customer", field: "Balance", outputAlias: "saldo" }
    ]);
    state.pipeline = withIds(buildPipelineFromForm().concat([
      step("map", { fields: [{ from: "codigo", to: "codigo" }, { from: "nome", to: "cliente" }, { from: "estado", to: "uf" }, { from: "saldo", to: "saldo" }] }),
      step("distinct", { fields: ["codigo"] }),
      step("group", { fields: ["uf"] }),
      step("aggregate", { op: "sum", field: "saldo", as: "saldoTotal" })
    ]));
    dropdown("#requestMode").value("pipeline");
    refreshAll();
    setStatus("Pipeline avancado carregado.", "ok");
  }

  function copyJson() {
    refreshJson();
    navigator.clipboard.writeText($("#jsonPreview").val()).then(
      () => setStatus("JSON copiado.", "ok"),
      () => setStatus("Nao foi possivel copiar pelo navegador.", "error")
    );
  }

  function copyPageHelp() {
    const text = String($("#pageHelpToggle").data("help") || "");
    if (!text) return;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        () => setStatus("Texto de ajuda copiado.", "ok"),
        () => fallbackCopyText(text)
      );
      return;
    }
    fallbackCopyText(text);
  }

  function fallbackCopyText(text) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.left = "-1000px";
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand("copy");
      setStatus("Texto de ajuda copiado.", "ok");
    } catch (_) {
      setStatus("Nao foi possivel copiar o texto de ajuda.", "error");
    }
    document.body.removeChild(textarea);
  }

  function downloadJson() {
    refreshJson();
    const blob = new Blob([$("#jsonPreview").val()], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "sursum-query.json";
    link.click();
    URL.revokeObjectURL(url);
    setStatus("Arquivo JSON gerado pelo navegador.", "ok");
  }

  function openResultPage() {
    refreshJson();
    localStorage.setItem(STORAGE_KEY, $("#jsonPreview").val());
    localStorage.setItem("sursumApiBaseUrl", apiBase());
    localStorage.setItem("sursumDatabaseName", selectedDatabase());
    window.open("query-result.html", "_blank");
    setStatus("Consulta atual enviada para a pagina de resultado.", "ok");
  }

  function saveCurrentQuery() {
    saveQueryRecord(false);
  }

  function saveCurrentQueryAs() {
    saveQueryRecord(true);
  }

  function saveQueryRecord(saveAs) {
    refreshJson();
    let request;
    try {
      request = JSON.parse($("#jsonPreview").val());
    } catch (error) {
      setStatus("JSON invalido. Corrija antes de salvar: " + error.message, "error");
      showStep(MAX_STEP);
      return;
    }

    const now = new Date().toISOString();
    const id = saveAs ? newId() : (state.currentQueryId || newId());
    const baseName = inputValue("#queryName", defaultQueryName(request));
    const name = saveAs ? uniqueQueryName(baseName) : baseName;
    const company = selectedCompany() || { id: "empresa-padrao", name: "Empresa padrao" };
    const items = loadSavedQueries();
    const existing = items.find((item) => item.id === id);
    const saved = {
      id,
      name,
      companyId: company.id,
      companyName: company.name,
      suggestedPath: "queries/" + slugForPath(company.name) + "/" + slugForPath(name) + ".json",
      createdAt: existing ? existing.createdAt : now,
      updatedAt: now,
      json: JSON.stringify(request, null, 2)
    };
    const nextItems = items.filter((item) => item.id !== id).concat([saved]);
    localStorage.setItem(LIBRARY_KEY, JSON.stringify(nextItems, null, 2));
    localStorage.setItem(STORAGE_KEY, saved.json);
    state.currentQueryId = id;
    $("#queryName").val(name);
    setStatus((saveAs ? "Consulta salva como nova copia. " : "Consulta salva. ") + "Use Consultas salvas para listar e alterar depois.", "ok");
  }

  function uniqueQueryName(baseName) {
    const cleanName = String(baseName || "Consulta").trim();
    const items = loadSavedQueries();
    let candidate = cleanName + " - copia";
    let index = 2;
    while (items.some((item) => String(item.name || "").toLowerCase() === candidate.toLowerCase())) {
      candidate = cleanName + " - copia " + index;
      index += 1;
    }
    return candidate;
  }

  function loadQueryForEdit() {
    const params = new URLSearchParams(window.location.search);
    if (params.get("new") === "1") {
      state.currentQueryId = "";
      $("#queryName").val("");
      state.sources = [];
      state.joins = [];
      state.select = [];
      state.filters = [];
      state.orderBy = [];
      state.pipeline = [];
      dropdown("#execution").value("sync");
      dropdown("#requestMode").value("object");
      $("#pipelineVersion").val("");
      $("#page").data("kendoNumericTextBox").value(1);
      $("#pageSize").data("kendoNumericTextBox").value(500);
      refreshAll();
      setStatus("Nova consulta iniciada. Carregue metadados e siga as etapas.", "ok");
      return true;
    }

    const id = params.get("id");
    if (id) {
      const item = loadSavedQueries().find((query) => query.id === id);
      if (!item) {
        setStatus("Consulta informada na URL nao foi encontrada.", "error");
        return false;
      }
      state.currentQueryId = item.id;
      $("#queryName").val(item.name || "");
      applyRequestJson(item.json);
      setStatus("Consulta carregada para alteracao: " + (item.name || item.id), "ok");
      return true;
    }

    const current = localStorage.getItem(STORAGE_KEY);
    if (current) {
      applyRequestJson(current);
      return true;
    }
    return false;
  }

  function applyRequestJson(json) {
    try {
      applyRequest(JSON.parse(json || "{}"));
    } catch (error) {
      setStatus("Nao foi possivel carregar o JSON salvo: " + error.message, "error");
    }
  }

  function applyRequest(request) {
    state.sources = withIds(request.sources || []);
    state.joins = withIds(request.joins || []);
    state.select = withIds(request.select || []);
    state.filters = withIds(request.filters || []);
    state.orderBy = withIds(request.orderBy || []);
    state.pipeline = withIds((request.pipeline || []).map((stepItem) => ({
      type: stepItem.type,
      payload: typeof stepItem.payload === "string" ? stepItem.payload : JSON.stringify(stepItem.payload || {})
    })));

    dropdown("#execution").value(request.execution || "sync");
    dropdown("#requestMode").value(state.pipeline.length ? "pipeline" : "object");
    $("#pipelineVersion").val(request.pipelineVersion || "");
    $("#page").data("kendoNumericTextBox").value(request.page || 1);
    $("#pageSize").data("kendoNumericTextBox").value(request.pageSize || 500);

    const firstSource = state.sources[0] || {};
    $("#sourceDatabase").data("kendoComboBox").value(firstSource.banco || firstRealDatabase());
    $("#sourceTable").val(firstSource.nome || "");
    $("#sourceAlias").val(firstSource.alias || "");
    refreshAll();
  }

  function loadSavedQueries() {
    try { return JSON.parse(localStorage.getItem(LIBRARY_KEY) || "[]"); } catch (_) { return []; }
  }

  function defaultQueryName(request) {
    const source = request.sources && request.sources[0] ? request.sources[0] : null;
    if (source && source.nome) return "Consulta " + source.nome;
    if (request.pipeline && request.pipeline.length) return "Pipeline " + new Date().toLocaleString("pt-BR");
    return "Consulta " + new Date().toLocaleString("pt-BR");
  }

  function slugForPath(value) {
    return String(value || "item").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "item";
  }

  function loadEndpointConfig() {
    if (window.SursumContext && typeof SursumContext.getLegacyConfig === "function") {
      const legacy = SursumContext.getLegacyConfig();
      const config = normalizeEndpointConfig(legacy);
      localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(config, null, 2));
      syncContextSelectionFromLegacy();
      return config;
    }

    let raw = null;
    try { raw = JSON.parse(localStorage.getItem(ENDPOINTS_KEY) || "null"); } catch (_) {}
    const config = normalizeEndpointConfig(raw);
    localStorage.setItem(ENDPOINTS_KEY, JSON.stringify(config, null, 2));
    return config;
  }

  function syncContextSelectionFromLegacy() {
    if (!window.SursumContext || typeof SursumContext.getCurrentCompany !== "function") return;
    const company = SursumContext.getCurrentCompany();
    const environment = SursumContext.getCurrentEnvironment();
    if (company) localStorage.setItem(SELECTED_COMPANY_KEY, company.id);
    if (environment) localStorage.setItem(SELECTED_ENDPOINT_KEY, environment.id);
  }

  function normalizeEndpointConfig(raw) {
    if (raw && Array.isArray(raw.companies)) return { version: 2, companies: normalizeCompanies(raw.companies) };
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
    const list = companies.map((company, index) => {
      const companyId = company.id || "empresa-" + index;
      const endpoints = (company.endpoints || []).map((endpoint) => ({ ...endpoint, companyId, url: String(endpoint.url || "").replace(/\/+$/, "") }));
      if (endpoints.length && !endpoints.some((endpoint) => endpoint.isDefault)) endpoints[0].isDefault = true;
      return { id: companyId, name: company.name || "Empresa", isDefault: !!company.isDefault, endpoints };
    });
    if (!list.some((company) => company.isDefault) && list[0]) list[0].isDefault = true;
    return list;
  }

  function contextEndpointConfig() {
    if (window.SursumContext && typeof window.SursumContext.getConfig === "function") {
      return window.SursumContext.getConfig();
    }
    return null;
  }

  function companiesForSelection() {
    const config = contextEndpointConfig();
    const environment = currentEnvironment();
    if (config && environment && Array.isArray(config.companies)) {
      return config.companies.filter((item) => item.environmentId === environment.id);
    }
    return state.companies || [];
  }

  function currentClient() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentClient === "function") {
      const client = window.SursumContext.getCurrentClient();
      if (client) {
        return client;
      }
    }

    const config = contextEndpointConfig();
    if (config && Array.isArray(config.clients) && config.clients.length) {
      const selectedId = (config.selected || {}).clientId;
      return config.clients.find((item) => item.id === selectedId) || config.clients[0] || null;
    }

    const selectedId = localStorage.getItem(SELECTED_COMPANY_KEY);
    return (state.companies || []).find((item) => item.id === selectedId) || (state.companies || [])[0] || null;
  }

  function currentEnvironment() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentEnvironment === "function") {
      const environment = window.SursumContext.getCurrentEnvironment();
      if (environment) {
        return environment;
      }
    }

    const selectedId = localStorage.getItem(SELECTED_ENDPOINT_KEY);
    return (state.endpoints || []).find((item) => item.id === selectedId) || (state.endpoints || [])[0] || null;
  }

  function endpointUrl(endpoint) {
    if (!endpoint) {
      return DEFAULT_API;
    }
    return endpoint.pasoeBaseUrl || endpoint.url || DEFAULT_API;
  }

  function companyForEnvironment(environmentId, clientId) {
    const config = contextEndpointConfig();
    if (!config || !Array.isArray(config.companies)) {
      return null;
    }

    const companies = config.companies || [];
    const exact = companies.find((item) => item.environmentId === environmentId && (!clientId || item.clientId === clientId));
    if (exact) {
      return exact;
    }

    if (!environmentId) {
      return companies.find((item) => !clientId || item.clientId === clientId) || companies[0] || null;
    }

    return null;
  }
  function updateContextSummary() {
    const client = currentClient();
    const environment = currentEnvironment();
    const target = $("#contextSummary");
    if (!target.length) return;
    if (!client || !environment) {
      target.text("Selecione o contexto na pagina inicial.");
      return;
    }
    target.text((client.name || client.id) + " / " + (environment.name || environment.id));
  }

  function selectedCompany() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentCompany === "function") {
      const company = window.SursumContext.getCurrentCompany();
      if (company) {
        return company;
      }
    }
    const companies = companiesForSelection();
    const selectedId = localStorage.getItem(SELECTED_COMPANY_KEY);
    return companies.find((item) => item.id === selectedId) || companies[0] || null;
  }

  function endpointsForSelectedCompany() {
    const environment = currentEnvironment();
    return environment ? [environment] : [];
  }

  function refreshEndpointCombo(selectedId) {
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    const companies = companiesForSelection();
    const selected = selectedCompany() || companies[0] || null;

    state.companies = companies;

    if (companyCombo) {
      companyCombo.setDataSource(new kendo.data.DataSource({ data: companies }));
      if (selected && selected.id) {
        companyCombo.value(selected.id);
      }
    }

    state.endpoints = endpointsForSelectedCompany();
    if (selected && selected.id) {
      localStorage.setItem(SELECTED_COMPANY_KEY, selected.id);
    }
    applySelectedEndpoint(selectedId);
    updateContextSummary();
  }

  function onApiCompanyChanged() {
    const companyId = this.value();
    const client = currentClient();
    const environment = currentEnvironment();
    if (companyId) {
      localStorage.setItem(SELECTED_COMPANY_KEY, companyId);
    }
    if (client && environment && window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(client.id, environment.id, companyId || "");
    }
    refreshEndpointCombo(localStorage.getItem(SELECTED_ENDPOINT_KEY));
  }

  function applySelectedEndpoint(explicitId) {
    const endpointId = typeof explicitId === "string" ? explicitId : localStorage.getItem(SELECTED_ENDPOINT_KEY);
    const endpoint = currentEnvironment()
      || (state.endpoints || []).find((item) => item.id === endpointId)
      || (state.endpoints || [])[0]
      || null;

    if (!endpoint) {
      updateContextSummary();
      return;
    }

    state.apiBase = endpointUrl(endpoint);
    $("#apiBaseUrl").val(state.apiBase);
    localStorage.setItem(API_URL_KEY, state.apiBase);
    localStorage.setItem(SELECTED_ENDPOINT_KEY, endpoint.id || "");

    const client = currentClient();
    const clientId = endpoint.clientId || (client && client.id) || "";
    const configuredCompany = companyForEnvironment(endpoint.id, clientId);
    const currentCompanySelection = selectedCompany();
    const preferredCompany = currentCompanySelection && currentCompanySelection.environmentId === endpoint.id
      ? currentCompanySelection
      : configuredCompany;

    if (window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(clientId, endpoint.id || "", preferredCompany ? preferredCompany.id : "");
      const selectedCompany = typeof window.SursumContext.getCurrentCompany === "function"
        ? window.SursumContext.getCurrentCompany()
        : preferredCompany;
      const company = selectedCompany && selectedCompany.environmentId === endpoint.id ? selectedCompany : preferredCompany;
      if (company && company.id) {
        localStorage.setItem(SELECTED_COMPANY_KEY, company.id);
      }
    } else if (endpoint.companyId) {
      localStorage.setItem(SELECTED_COMPANY_KEY, endpoint.companyId);
    }
    updateContextSummary();
  }

  function apiBase() {
    return inputValue("#apiBaseUrl", currentContextApiBase() || "http://localhost:8890/web/SursumDynamicQuery").replace(/\/+$/, "");
  }

  function currentContextApiBase() {
    if (window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function") {
      const environment = SursumContext.getCurrentEnvironment();
      if (environment && environment.pasoeBaseUrl) return environment.pasoeBaseUrl;
    }
    return localStorage.getItem("sursumApiBaseUrl") || "";
  }

  function selectedDatabase() {
    return "TODOS";
  }

  function sourceDatabase() {
    return inputValue("#sourceDatabase", "");
  }

  function relationLeftDatabase() {
    return inputValue("#relationLeftDatabase", sourceDatabase());
  }

  function relationRightDatabase() {
    return inputValue("#relationRightDatabase", sourceDatabase());
  }

  function refreshDatabaseCombos() {
    ["#relationLeftDatabase", "#relationRightDatabase"].forEach((selector) => {
      const combo = $(selector).data("kendoComboBox");
      const value = combo.value() || firstRealDatabase();
      combo.setDataSource(new kendo.data.DataSource({ data: state.databases }));
      combo.dataSource.read();
      combo.value(value);
      if (!combo.value()) combo.value(firstRealDatabase());
      combo.refresh();
    });
  }

  function firstRealDatabase() {
    return state.databases.length ? state.databases[0].name : "";
  }

  function setMetadataProgress(message, percent) {
    $("#metadataLoadText").text(message);
    $("#metadataProgressBar").css("width", Math.max(0, Math.min(100, percent || 0)) + "%");
  }

  function saveMetadataCacheMarker(database, response) {
    localStorage.setItem("sursumMetadataCache." + database, JSON.stringify({
      database,
      tableCount: state.tables.length,
      updatedAt: response.updatedAt || new Date().toISOString()
    }));
  }

  function hasMetadataCache(database) {
    return !!localStorage.getItem("sursumMetadataCache." + database);
  }

  function checkServerMetadataCache(done) {
    $.getJSON(apiBase() + "/metadata/cache-status?database=" + encodeURIComponent(selectedDatabase()))
      .done(function (response) {
        if (typeof done === "function") done(!!(response && response.success && response.hasCache));
      })
      .fail(function () {
        if (typeof done === "function") done(hasMetadataCache(selectedDatabase()));
      });
  }

  function apiError(response) {
    return response && response.error ? (response.error.message || response.error.code || "erro") : "erro desconhecido";
  }

  function inputValue(selector, fallback) {
    const widget = $(selector).data("kendoComboBox");
    const raw = widget ? widget.value() : $(selector).val();
    const value = raw === undefined || raw === null ? "" : String(raw).trim();
    return value === "" ? fallback : value;
  }

  function comboOrInputValue(selector) {
    return inputValue(selector, "");
  }

  function splitCsv(value) {
    return String(value || "").split(",").map((item) => item.trim()).filter(Boolean);
  }

  function capitalize(value) {
    const text = String(value || "");
    return text ? text.charAt(0).toUpperCase() + text.slice(1) : "";
  }

  function setComboValue(selector, value) {
    const widget = $(selector).data("kendoComboBox");
    if (widget) {
      widget.value(value || "");
      return;
    }
    $(selector).val(value || "");
  }

  function dropdown(selector) {
    return $(selector).data("kendoDropDownList");
  }

  function dropdownValue(selector) {
    const widget = dropdown(selector);
    return widget ? widget.value() : inputValue(selector, "");
  }

  function numericValue(selector, fallback) {
    const widget = $(selector).data("kendoNumericTextBox");
    return widget ? widget.value() : Number(inputValue(selector, fallback));
  }

  function withIds(items) {
    return items.map((item) => ({ ...item, __id: newId() }));
  }

  function newId() {
    return Date.now() + "-" + Math.random().toString(16).slice(2);
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(function () {
    initWidgets();
    bindEvents();
    refreshEndpointCombo(localStorage.getItem(SELECTED_ENDPOINT_KEY));
    setStepPayloadTemplate();
    if (!loadQueryForEdit()) loadCustomerSample();
    showStep(1);
    setMetadataProgress("Preparando carga inicial de tabelas...", 5);
    loadDatabases(function () {
      state.initializing = false;
      loadMetadata(false);
    });
  });
})();

