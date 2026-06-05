(function () {
  const state = {
    sources: [],
    select: [],
    filters: [],
    orderBy: [],
    pipeline: []
  };

  function initWidgets() {
    $("#execution").kendoDropDownList({
      dataSource: ["sync", "async", "auto"],
      value: "sync"
    });
    $("#requestMode").kendoDropDownList({
      dataSource: [
        { text: "Objeto estruturado", value: "object" },
        { text: "Pipeline", value: "pipeline" }
      ],
      dataTextField: "text",
      dataValueField: "value",
      value: "object"
    });
    $("#filterOperator").kendoDropDownList({
      dataSource: ["=", "<>", ">", ">=", "<", "<=", "between", "begins", "contains"],
      value: ">="
    });
    $("#orderDirection").kendoDropDownList({
      dataSource: ["ASC", "DESC"],
      value: "ASC"
    });
    $("#stepType").kendoDropDownList({
      dataSource: ["source", "join", "select", "filter", "sort", "limit", "map", "distinct", "group", "aggregate", "output"],
      value: "map",
      change: setStepPayloadTemplate
    });

    $("button").kendoButton();
    $("#page").kendoNumericTextBox({ min: 1, format: "n0", decimals: 0, value: 1 });
    $("#pageSize").kendoNumericTextBox({ min: 1, max: 500, format: "n0", decimals: 0, value: 500 });

    createGrid("#sourcesGrid", state.sources, [
      { field: "nome", title: "Tabela" },
      { field: "alias", title: "Alias" },
      { field: "campos", title: "Campos" },
      commandColumn(removeFrom("sources"))
    ]);
    createGrid("#selectGrid", state.select, [
      { field: "sourceAlias", title: "Alias" },
      { field: "field", title: "Campo" },
      { field: "outputAlias", title: "Saída" },
      commandColumn(removeFrom("select"))
    ]);
    createGrid("#filtersGrid", state.filters, [
      { field: "sourceAlias", title: "Alias" },
      { field: "field", title: "Campo" },
      { field: "operator", title: "Op." },
      { field: "value", title: "Valor" },
      commandColumn(removeFrom("filters"))
    ]);
    createGrid("#ordersGrid", state.orderBy, [
      { field: "sourceAlias", title: "Alias" },
      { field: "field", title: "Campo" },
      { field: "direction", title: "Direção" },
      commandColumn(removeFrom("orderBy"))
    ]);
    createGrid("#pipelineGrid", state.pipeline, [
      { field: "type", title: "Step", width: 120 },
      { field: "payload", title: "Payload" },
      commandColumn(removeFrom("pipeline"))
    ]);
    $("#resultGrid").kendoGrid({
      dataSource: [],
      height: 420,
      sortable: true,
      filterable: true,
      pageable: true
    });
  }

  function createGrid(selector, data, columns) {
    $(selector).kendoGrid({
      dataSource: {
        data,
        schema: { model: { id: "__id" } }
      },
      height: 220,
      sortable: true,
      noRecords: { template: "Nenhum item adicionado." },
      columns
    });
  }

  function commandColumn(handler) {
    return {
      title: " ",
      width: 96,
      template: "<button class='k-button k-button-sm remove-row'>Remover</button>",
      attributes: { "data-role": "remove" }
    };
  }

  function removeFrom(collection) {
    return function (rowIndex) {
      state[collection].splice(rowIndex, 1);
      refreshAll();
    };
  }

  function bindEvents() {
    $(document).on("click", ".remove-row", function (event) {
      const gridElement = $(event.target).closest(".k-grid");
      const grid = gridElement.data("kendoGrid");
      const row = $(event.target).closest("tr");
      const item = grid.dataItem(row);
      const id = item.__id;
      const key = gridElement.attr("id").replace("Grid", "");
      const collection = key === "orders" ? "orderBy" : key;
      state[collection] = state[collection].filter((x) => x.__id !== id);
      refreshAll();
    });

    $("#addSource").on("click", function () {
      addItem("sources", {
        nome: value("#sourceTable", "Customer"),
        alias: value("#sourceAlias", "customer"),
        campos: value("#sourceFields", "CustNum,Name")
      });
    });

    $("#clearSources").on("click", function () {
      state.sources = [];
      refreshAll();
    });

    $("#addSelect").on("click", function () {
      addItem("select", {
        sourceAlias: value("#selectAlias", "customer"),
        field: value("#selectField", "CustNum"),
        outputAlias: value("#selectOutput", "codigo")
      });
    });

    $("#addFilter").on("click", function () {
      addItem("filters", {
        sourceAlias: value("#filterAlias", "customer"),
        field: value("#filterField", "CustNum"),
        operator: dropdownValue("#filterOperator"),
        value: value("#filterValue", "1")
      });
    });

    $("#addOrder").on("click", function () {
      addItem("orderBy", {
        sourceAlias: value("#orderAlias", "customer"),
        field: value("#orderField", "CustNum"),
        direction: dropdownValue("#orderDirection")
      });
    });

    $("#addStep").on("click", function () {
      addItem("pipeline", {
        type: dropdownValue("#stepType"),
        payload: value("#stepPayload", "{}")
      });
    });

    $("#addPipelineFromForm").on("click", function () {
      state.pipeline = buildPipelineFromForm();
      refreshAll();
    });

    $("#clearPipeline").on("click", function () {
      state.pipeline = [];
      refreshAll();
    });

    $("#buildJson").on("click", refreshJson);
    $("#copyJson").on("click", copyJson);
    $("#runQuery").on("click", runQuery);
    $("#loadCustomerSample").on("click", loadCustomerSample);
    $("#loadAdvancedSample").on("click", loadAdvancedSample);
  }

  function addItem(collection, item) {
    item.__id = Date.now() + "-" + Math.random().toString(16).slice(2);
    state[collection].push(item);
    refreshAll();
  }

  function refreshAll() {
    refreshGrid("#sourcesGrid", state.sources);
    refreshGrid("#selectGrid", state.select);
    refreshGrid("#filtersGrid", state.filters);
    refreshGrid("#ordersGrid", state.orderBy);
    refreshGrid("#pipelineGrid", state.pipeline);
    refreshJson();
  }

  function refreshGrid(selector, data) {
    const grid = $(selector).data("kendoGrid");
    grid.dataSource.data(data);
  }

  function refreshJson() {
    const request = buildRequest();
    $("#jsonPreview").val(JSON.stringify(request, null, 2));
  }

  function buildRequest() {
    const mode = dropdownValue("#requestMode");
    const request = {
      execution: dropdownValue("#execution") || "sync",
      pipelineVersion: value("#pipelineVersion", ""),
      page: numericValue("#page", 1),
      pageSize: numericValue("#pageSize", 500)
    };

    if (mode === "pipeline") {
      request.pipeline = state.pipeline.map(cleanPipelineStep);
      return request;
    }

    request.sources = state.sources.map(cleanObject);
    request.select = state.select.map(cleanObject);
    request.filters = state.filters.map(cleanObject);
    request.orderBy = state.orderBy.map(cleanObject);
    return request;
  }

  function buildPipelineFromForm() {
    const steps = [];
    state.sources.forEach((source) => steps.push(step("source", source)));
    if (state.select.length) steps.push(step("select", { fields: state.select.map(cleanObject) }));
    state.filters.forEach((filter) => steps.push(step("filter", filter)));
    if (state.orderBy.length) steps.push(step("sort", { fields: state.orderBy.map(cleanObject) }));
    steps.push(step("limit", { page: numericValue("#page", 1), pageSize: numericValue("#pageSize", 500) }));
    steps.push(step("output", { format: "json" }));
    return steps.map((x) => ({ ...x, __id: Date.now() + "-" + Math.random().toString(16).slice(2) }));
  }

  function step(type, payload) {
    return { type, payload: JSON.stringify(cleanObject(payload)) };
  }

  function cleanPipelineStep(item) {
    return {
      type: item.type,
      payload: item.payload
    };
  }

  function cleanObject(item) {
    const out = {};
    Object.keys(item).forEach((key) => {
      if (key !== "__id" && item[key] !== "" && item[key] !== null && item[key] !== undefined) out[key] = item[key];
    });
    return out;
  }

  function setStepPayloadTemplate() {
    const type = dropdownValue("#stepType");
    const templates = {
      source: { nome: "Customer", alias: "customer", campos: "CustNum,Name,State,Balance" },
      join: { type: "INNER", leftAlias: "customer", leftField: "CustNum", rightAlias: "custOrder", rightField: "CustNum" },
      select: { fields: [{ sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" }] },
      filter: { sourceAlias: "customer", field: "CustNum", operator: ">=", value: "1" },
      sort: { fields: [{ sourceAlias: "customer", field: "CustNum", direction: "ASC" }] },
      limit: { page: 1, pageSize: 500 },
      map: { fields: [{ from: "codigo", to: "codigo" }, { from: "nome", to: "cliente" }] },
      distinct: { fields: ["codigo"] },
      group: { fields: ["uf"] },
      aggregate: { op: "sum", field: "saldo", as: "saldoTotal" },
      output: { format: "json" }
    };
    $("#stepPayload").val(JSON.stringify(templates[type] || {}, null, 2));
  }

  function loadCustomerSample() {
    state.sources = withIds([{ nome: "Customer", alias: "customer", campos: "CustNum,Name" }]);
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
    state.sources = withIds([{ nome: "Customer", alias: "customer", campos: "CustNum,Name,State,Balance" }]);
    state.select = withIds([
      { sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" },
      { sourceAlias: "customer", field: "Name", outputAlias: "nome" },
      { sourceAlias: "customer", field: "State", outputAlias: "estado" },
      { sourceAlias: "customer", field: "Balance", outputAlias: "saldo" }
    ]);
    state.filters = withIds([{ sourceAlias: "customer", field: "CustNum", operator: ">=", value: "1" }]);
    state.orderBy = withIds([{ sourceAlias: "customer", field: "CustNum", direction: "ASC" }]);
    state.pipeline = withIds(buildPipelineFromForm().concat([
      step("map", { fields: [{ from: "codigo", to: "codigo" }, { from: "nome", to: "cliente" }, { from: "estado", to: "uf" }, { from: "saldo", to: "saldo" }] }),
      step("distinct", { fields: ["codigo"] }),
      step("group", { fields: ["uf"] }),
      step("aggregate", { op: "sum", field: "saldo", as: "saldoTotal" })
    ]));
    dropdown("#requestMode").value("pipeline");
    dropdown("#execution").value("sync");
    refreshAll();
    setStatus("Pipeline avançado carregado.", "ok");
  }

  function withIds(items) {
    return items.map((item) => ({ ...item, __id: Date.now() + "-" + Math.random().toString(16).slice(2) }));
  }

  function copyJson() {
    refreshJson();
    navigator.clipboard.writeText($("#jsonPreview").val()).then(
      () => setStatus("JSON copiado.", "ok"),
      () => setStatus("Não foi possível copiar pelo navegador.", "error")
    );
  }

  function runQuery() {
    refreshJson();
    const payload = $("#jsonPreview").val();
    setStatus("Executando consulta...", "");
    $.ajax({
      url: $("#apiUrl").val(),
      method: "POST",
      contentType: "application/json",
      dataType: "json",
      data: payload
    }).done((response) => {
      if (!response.success) {
        setStatus("Erro: " + (response.error && response.error.message ? response.error.message : "falha desconhecida"), "error");
        return;
      }
      const data = response.data || [];
      updateResultGrid(data);
      setStatus("Consulta concluída. Registros: " + (response.recordsReturned || data.length), "ok");
    }).fail((xhr) => {
      setStatus("Falha HTTP: " + xhr.status + " " + xhr.statusText, "error");
    });
  }

  function updateResultGrid(data) {
    const grid = $("#resultGrid").data("kendoGrid");
    const first = data[0] || {};
    const columns = Object.keys(first).map((key) => ({ field: key, title: key }));
    grid.setOptions({ columns: columns.length ? columns : [{ field: "message", title: "Mensagem" }] });
    grid.dataSource.data(columns.length ? data : [{ message: "Sem dados." }]);
  }

  function value(selector, fallback) {
    const v = $(selector).val();
    return v === undefined || v === null || String(v).trim() === "" ? fallback : String(v).trim();
  }

  function dropdown(selector) {
    return $(selector).data("kendoDropDownList");
  }

  function dropdownValue(selector) {
    const widget = dropdown(selector);
    return widget ? widget.value() : value(selector, "");
  }

  function numericValue(selector, fallback) {
    const widget = $(selector).data("kendoNumericTextBox");
    return widget ? widget.value() : Number(value(selector, fallback));
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(function () {
    initWidgets();
    bindEvents();
    setStepPayloadTemplate();
    loadCustomerSample();
  });
})();
