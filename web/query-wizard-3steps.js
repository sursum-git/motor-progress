(function () {
  const state = {
    apiBase: localStorage.getItem("sursumApiBaseUrl") || "http://localhost:8890/web/SursumDynamicQuery",
    currentStep: 1,
    databases: [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }],
    selectedDatabase: "",
    selectedTable: "",
    tables: [],
    tableCache: {},
    tableSearchRows: [],
    fields: [],
    fieldsByName: {},
    foreignKeys: [],
    filterRows: [],
    currentRecordRow: null,
    currentRecordJoinFieldOptions: {},
    currentRecordJoinOptions: [],
    foreignKeyCache: {},
    activeFilterId: 1
  };

  const TAB_OPS = [
    { value: "=", label: "Igual" },
    { value: "<>", label: "Diferente" },
    { value: ">", label: "Maior que" },
    { value: ">=", label: "Maior ou igual" },
    { value: "<", label: "Menor que" },
    { value: "<=", label: "Menor ou igual" },
    { value: "between", label: "Entre" },
    { value: "contains", label: "Contém" },
    { value: "begins", label: "Inicia com" },
    { value: "in", label: "Estar em (múltiplas opções)" }
  ];

  const DYNAMIC_OPS = [
    { value: "=", label: "Igual" },
    { value: "<>", label: "Diferente" },
    { value: ">", label: "Maior que" },
    { value: ">=", label: "Maior ou igual" },
    { value: "<", label: "Menor que" },
    { value: "<=", label: "Menor ou igual" },
    { value: "between", label: "Entre" },
    { value: "contains", label: "Contém" },
    { value: "begins", label: "Inicia com" },
    { value: "in", label: "Estar em (múltiplas opções)" }
  ];

  $(init);

  function init() {
    initWidgets();
    refreshContextUi();
    bindEvents();
    loadDatabases(function () {
      setStatus("Metadados prontos. Selecione o banco e a tabela na etapa 1.", "ok");
      showStep(1);
    });
  }

  function initWidgets() {
    $("#apiCompany").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      dataSource: [],
      filter: "contains",
      suggest: true,
      change: onCompanyChanged
    });
    $("#apiBaseUrl").val(state.apiBase.replace(/\/+$/, ""));

    $("#databaseCombo").kendoComboBox({
      dataTextField: "displayName",
      dataValueField: "name",
      dataSource: state.databases,
      filter: "contains",
      suggest: true,
      change: onDatabaseChanged
    });

    $("#selectedTable").kendoTextBox().on("change", onManualTableChanged).on("keydown", function (event) {
      if (event.key === "Enter") {
        onManualTableChanged();
      }
    });

    $("#dynamicFilterField").kendoComboBox({
      dataTextField: "label",
      dataValueField: "name",
      dataSource: [],
      filter: "contains",
      suggest: true,
      placeholder: "Campo",
      change: hydrateDynamicFilterOperator
    });

    $("#dynamicFilterOperator").kendoDropDownList({
      dataTextField: "label",
      dataValueField: "value",
      dataSource: [],
      optionLabel: "Operador",
      change: function () {
        updateDynamicBetweenInputs();
      }
    });

    $("#dynamicFilterValue").addClass("index-filter-value");
    $("#dynamicFilterValue").data("dynamicFilter", true);
    refreshFilterDynamicSelectors();

    $("#queryPage").kendoNumericTextBox({ format: "n0", min: 1, value: 1, decimals: 0 });
    $("#queryPageSize").kendoNumericTextBox({ format: "n0", min: 1, max: 10000, value: 200, decimals: 0 });

    $("#tableSearchText").kendoTextBox();

    $("#tableSearchWindow").kendoWindow({
      title: "Buscar tabela",
      width: "860px",
      height: "600px",
      visible: false,
      modal: true
    });

    $("#tableSearchGrid").kendoGrid({
      dataSource: [],
      height: 450,
      sortable: true,
      filterable: true,
      selectable: "row",
      noRecords: { template: "Nenhuma tabela encontrada." },
      columns: [
        { field: "database", title: "Banco", width: 140 },
        { field: "name", title: "Tabela", width: 180 },
        { field: "label", title: "Descricao", width: 240 },
        { field: "dumpName", title: "Dump-name", width: 180 }
      ]
    });

    $("#foreignKeySearchWindow").kendoWindow({
      title: "Buscar chaves estrangeiras",
      width: "980px",
      height: "620px",
      visible: false,
      modal: true
    });

    $("#foreignKeySearchGrid").kendoGrid({
      dataSource: [],
      height: 430,
      sortable: true,
      filterable: true,
      selectable: "row",
      noRecords: { template: "Nenhuma chave estrangeira para esta tabela." },
      columns: [
        { field: "localField", title: "Campo local", width: 170 },
        { field: "localLabel", title: "Descricao", width: 210 },
        { field: "foreignTable", title: "Tabela FK", width: 220 },
        { field: "localToForeignField", title: "Campo na FK", width: 190 },
        { field: "relationStatus", title: "Status", width: 150 }
      ]
    });

    $("#filtersGrid").kendoGrid({
      dataSource: [],
      height: 200,
      sortable: true,
      noRecords: { template: "Nenhum filtro montado." },
      columns: [
        { field: "indexName", title: "Indice", width: 140 },
        { field: "field", title: "Campo" },
        { field: "operator", title: "Operador", width: 95 },
        { field: "value", title: "Valor" },
        { title: " ", width: 90, template: "<button class='k-button k-button-sm remove-filter' data-id='#: __id #'>Remover</button>" }
      ]
    });

    $("#dataGrid").kendoGrid({
      dataSource: [],
      height: 520,
      sortable: true,
      filterable: true,
      pageable: { buttonCount: 5, pageSize: Number($("#queryPageSize").val()) },
      selectable: "row",
      noRecords: { template: "Nenhum registro encontrado." }
    });

    $("#recordWindow").kendoWindow({
      title: "Registro",
      width: "92vw",
      height: "92vh",
      maxWidth: "100vw",
      maxHeight: "100vh",
      visible: false,
      pinned: false,
      resizable: true,
      animation: false,
      open: function () {
        enforceRecordWindowMaximized(this);
      },
      modal: true
    });

    $("#recordJoinTable").kendoDropDownList({
      autoBind: false,
      dataTextField: "text",
      dataValueField: "value",
      optionLabel: "Selecione a tabela de relacionamento",
      dataSource: [],
      change: onRecordJoinTableChanged
    });

    $("#relatedRecordWindow").kendoWindow({
      title: "Registro relacionado",
      width: "92vw",
      height: "92vh",
      maxWidth: "100vw",
      maxHeight: "100vh",
      visible: false,
      pinned: false,
      resizable: true,
      animation: false,
      open: function () {
        enforceRecordWindowMaximized(this);
      },
      modal: true
    });

    $("#relatedRecordGrid").kendoGrid({
      dataSource: [],
      height: 540,
      sortable: true,
      filterable: true,
      pageable: { buttonCount: 5, pageSize: 200 },
      noRecords: { template: "Sem registros relacionados." }
    });

    $("button").kendoButton();
  }

  function bindEvents() {
    $("#openContextSelector").on("click", function () {
      window.location.href = "context-selector.html";
    });

    $("#refreshMetadata").on("click", function () {
      refreshContextUi();
      loadDatabases(function () {
        setStatus("Metadados atualizados.", "ok");
      });
    });

    $("#openTableSearch").on("click", openTableSearch);
    $("#applyTableSearch").on("click", applyTableSearch);
    $("#cancelTableSearch").on("click", function () {
      $("#tableSearchWindow").data("kendoWindow").close();
    });

    $("#clearSelection").on("click", clearSelection);
    $("#clearFilters").on("click", clearFilters);
    $("#runQuery").on("click", runQuery);
    $("#openForeignKeySearch").on("click", openForeignKeySearch);
    $("#applyForeignKeySearch").on("click", applyForeignKeySearch);
    $("#closeForeignKeySearch").on("click", function () {
      $("#foreignKeySearchWindow").data("kendoWindow").close();
    });

    $("#prevStep").on("click", function () { showStep(state.currentStep - 1); });
    $("#nextStep").on("click", function () {
      if (state.currentStep === 1) {
        if (!state.selectedTable || !state.selectedDatabase || state.selectedDatabase === "TODOS") {
          setFooterStatus("Selecione banco e tabela antes de avançar.", "error");
          return;
        }
        ensureTableFields(loadFilterTabs);
        return;
      }
      if (state.currentStep === 2) {
        if (!state.fields.length) {
          setFooterStatus("Selecione uma tabela valida para montar filtros.", "error");
          return;
        }
        showStep(3);
        return;
      }
      showStep(state.currentStep + 1);
    });

    $(".step-item").on("click", function () {
      const step = Number($(this).data("step"));
      if ((step === 2 || step === 3) && (!state.selectedTable || !state.selectedDatabase)) {
        setFooterStatus("Primeiro selecione banco e tabela na etapa 1.", "error");
        return;
      }
      if (step === 3 && !state.fields.length) {
        setFooterStatus("Selecione uma tabela e aguarde os campos antes de abrir a etapa 3.", "error");
        return;
      }
      state.currentStep = step;
      showStep(step);
    });

    $("#tableSearchGrid").on("dblclick", "tbody tr", function () {
      const grid = $("#tableSearchGrid").data("kendoGrid");
      const row = grid.dataItem(this);
      if (!row) return;
      state.selectedDatabase = row.database || row.logicalName || state.selectedDatabase || "TODOS";
      state.selectedTable = row.name;
      applySelectedTableFromStepSearch(function () {
        $("#tableSearchWindow").data("kendoWindow").close();
        showStep(2);
      });
    });

    $("#filtersGrid").on("click", ".remove-filter", function () {
      const id = String($(this).data("id"));
      state.filterRows = state.filterRows.filter((row) => String(row.__id) !== id);
      refreshFilterGrid();
    });

    $("#foreignKeySearchGrid").on("dblclick", "tbody tr", function () {
      const grid = $("#foreignKeySearchGrid").data("kendoGrid");
      const row = grid.dataItem(this);
      if (!row) return;
      openForeignKeyTable(row);
    });

    $("#indexFilterTabs").on("input change", ".index-filter-value", function () {
      const el = $(this);
      const value = el.val();
      el.data("filterValue", value);
    });

    $("#indexFilterTabs").on("click", ".add-index-filter", function () {
      const row = $(this).closest(".index-filter-item");
      if (!addFilterFromRow(row)) {
        return;
      }
    });

    $("#indexFilterTabs").on("change", ".index-filter-operator", function () {
      const row = $(this).closest(".index-filter-item");
      toggleBetweenInputs(row);
    });

    $("#addDynamicFilter").on("click", addDynamicFilter);

    $("#dataGrid").on("dblclick", "tbody tr", function () {
      const grid = $("#dataGrid").data("kendoGrid");
      const row = grid.dataItem(this);
      if (!row) return;
      openRecordWindow(row);
    });

    $("#closeRecord").on("click", function () {
      $("#recordWindow").data("kendoWindow").close();
    });

    $("#closeRelatedRecord").on("click", function () {
      $("#relatedRecordWindow").data("kendoWindow").close();
    });

    $("#recordForm").on("click", ".record-join-field-btn", onRecordJoinFieldButtonClick);
  }

  function showStep(step) {
    const next = Math.max(1, Math.min(3, step));
    state.currentStep = next;

    $(".step-item").removeClass("is-active");
    $(".step-item[data-step='" + next + "']").addClass("is-active");

    $("[data-step-panel]").removeClass("is-active");
    $("[data-step-panel='" + next + "']").addClass("is-active");

    $("#prevStep").prop("disabled", next === 1);
    $("#nextStep").prop("disabled", next === 3);
    updateSourceSelection();

    if (next === 2 && state.selectedTable && state.fields.length === 0) {
      ensureTableFields(loadFilterTabs);
    }
    if (next === 3 && state.selectedTable && state.fields.length) {
      buildResultColumns();
    }

    setFooterStatus(
      next === 1
        ? "Etapa 1: selecione banco e tabela."
        : (next === 2
          ? "Etapa 2: ajuste filtros por índice e filtros dinâmicos."
          : "Etapa 3: execute a consulta."),
      ""
    );
  }

  function loadDatabases(done) {
    refreshContextUi();
    setStatus("Carregando bancos conectados...", "");
    getJsonUtf8(state.apiBase + "/metadata/databases")
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        const list = normalizeDatabases(response.data || []);
        state.databases = [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }].concat(list);
        const combo = $("#databaseCombo").data("kendoComboBox");
        combo.setDataSource(new kendo.data.DataSource({ data: state.databases }));
        if (!state.selectedDatabase || state.selectedDatabase === "TODOS") {
          combo.value("TODOS");
        } else if (state.databases.some((item) => item.name === state.selectedDatabase)) {
          combo.value(state.selectedDatabase);
        } else {
          combo.value("TODOS");
        }
        combo.refresh();
        onDatabaseChanged();
        state.tableCache = {};
        if (typeof done === "function") done();
        setStatus("Bancos carregados: " + list.length, "ok");
      })
      .fail(function (xhr) {
        setStatus("Falha ao carregar bancos: " + xhr.status + " " + xhr.statusText, "error");
        const combo = $("#databaseCombo").data("kendoComboBox");
        combo.setDataSource(new kendo.data.DataSource({ data: [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }] }));
        combo.value("TODOS");
        if (typeof done === "function") done();
      });
  }

  function normalizeDatabases(rows) {
    const list = Array.isArray(rows) ? rows : [];
    return list.map((item) => {
      const name = item.name || item.logicalName || item.value || "";
      const logicalName = item.logicalName || name;
      const displayName = item.displayName || item.label || item.name || item.logicalName || "";
      return {
        ...item,
        name,
        logicalName,
        displayName
      };
    });
  }

  function onDatabaseChanged() {
    const combo = $("#databaseCombo").data("kendoComboBox");
    const value = resolveSelectedDatabaseValue(combo);
    state.selectedDatabase = value;
    state.tables = [];
    if (state.currentStep !== 1) {
      clearSelection();
    }
    loadTablesForDatabase(value);
    setStatus("Banco selecionado: " + value, "ok");
  }

  function resolveSelectedDatabaseValue(combo) {
    if (!combo) {
      return "TODOS";
    }

    const explicitValue = String(combo.value() || "").trim();
    if (explicitValue) {
      const explicitMatch = state.databases.find((item) => String(item.name || "").toUpperCase() === String(explicitValue).toUpperCase());
      if (explicitMatch) {
        return explicitMatch.name || explicitValue;
      }
      if (explicitValue.toUpperCase() === "TODOS") {
        return "TODOS";
      }
    }

    const typedText = String(combo.text() || "").trim();
    if (!typedText) {
      return "TODOS";
    }

    const textMatch = state.databases.find((item) => (
      String(item.name || "").toUpperCase() === typedText.toUpperCase() ||
      String(item.logicalName || "").toUpperCase() === typedText.toUpperCase() ||
      String(item.displayName || "").toUpperCase() === typedText.toUpperCase()
    ));

    if (textMatch) {
      const resolved = textMatch.name || textMatch.logicalName || typedText;
      combo.value(resolved);
      return resolved;
    }

    return "TODOS";
  }

  function loadTablesForDatabase(database, done) {
    if (state.tableCache[database]) {
      state.tables = state.tableCache[database];
      if (typeof done === "function") done();
      return;
    }

    if (database === "TODOS") {
      loadAllTables(done);
      return;
    }

    let url = state.apiBase + "/metadata/tables";
    if (database && database !== "TODOS") {
      url += "?database=" + encodeURIComponent(database);
    }

    getJsonUtf8(url)
      .done(function (response) {
        const rows = response && response.success === false ? [] : (response.data || []);
        state.tables = normalizeTableRows(rows, database);
        state.tableCache[database] = state.tables;
        if (typeof done === "function") done();
      })
      .fail(function () {
        state.tables = [];
        if (typeof done === "function") done();
      });
  }

  function loadAllTables(done) {
    const dbs = (state.databases || []).map((item) => item && String(item.name || "").trim()).filter((name) => name && name.toUpperCase() !== "TODOS");
    if (!dbs.length) {
      state.tables = [];
      state.tableCache["TODOS"] = [];
      if (typeof done === "function") done();
      return;
    }

    let pending = dbs.length;
    const rows = [];
    let hasFailure = false;

    dbs.forEach((dbName) => {
      const url = state.apiBase + "/metadata/tables?database=" + encodeURIComponent(dbName);
      getJsonUtf8(url)
        .done(function (response) {
          const sourceRows = response && response.success === false ? [] : (response.data || []);
          normalizeTableRows(sourceRows, dbName).forEach(function (row) {
            rows.push(row);
          });
        })
        .fail(function () {
          hasFailure = true;
        })
        .always(function () {
          pending--;
          if (pending === 0) {
            const seen = {};
            const merged = [];
            rows.forEach(function (row) {
              const key = String(row.database || "").toUpperCase() + "|" + String(row.name || "").toUpperCase();
              if (!seen[key]) {
                seen[key] = true;
                merged.push(row);
              }
            });
            state.tables = merged;
            state.tableCache["TODOS"] = merged;
            if (typeof done === "function") done();
            if (hasFailure) {
              setStatus("Falha ao carregar algumas tabelas no modo TODOS.", "error");
            }
          }
        });
    });
  }

  function getJsonUtf8(url) {
    return $.ajax({
      url: url,
      method: "GET",
      dataType: "json",
      cache: false
    });
  }

  function normalizeTableRows(rows, defaultDatabase) {
    return (rows || []).map((item) => ({
      name: item.name || "",
      label: item.label || "",
      dumpName: item.dumpName || "",
      database: item.database || item.logicalName || defaultDatabase || state.selectedDatabase
    }));
  }

  function openTableSearch() {
    const db = state.selectedDatabase || "TODOS";
    loadTablesForDatabase(db, function () {
      applyTableSearch();
      const win = $("#tableSearchWindow").data("kendoWindow");
      win.setOptions({ title: "Buscar tabela em " + db });
      win.center().open();
      if (!$("#tableSearchText").val()) {
        $("#tableSearchText").val("");
      }
      $("#tableSearchText").trigger("focus");
    });
  }

  function applyTableSearch() {
    const text = String($("#tableSearchText").val() || "").trim().toLowerCase();
    const db = state.selectedDatabase || "TODOS";
    let rows = state.tableCache[db] || state.tables || [];

    if (db !== "TODOS") {
      rows = rows.filter((row) => String(row.database || "").toLowerCase() === String(db).toLowerCase());
    }

    if (text) {
      rows = rows.filter((row) => {
        const values = [row.name, row.label, row.dumpName, row.database];
        return values.some((value) => String(value || "").toLowerCase().indexOf(text) >= 0);
      });
    }

    const grid = $("#tableSearchGrid").data("kendoGrid");
    grid.dataSource.data(rows);
  }

  function clearSelection() {
    state.selectedTable = "";
    state.selectedDatabase = state.selectedDatabase || "TODOS";
    state.fields = [];
    state.foreignKeys = [];
    state.foreignKeyCache = {};
    state.filterRows = [];
    $("#selectedTable").val("");
    refreshFilterDynamicSelectors();
    refreshFilterGrid();
    buildFilterTabs([], []);
    setStepSourceInfo();
    setStatus("Selecao limpa.", "ok");
  }

  function onManualTableChanged() {
    const tableName = String($("#selectedTable").val() || "").trim();
    if (!tableName) {
      setFooterStatus("Informe o nome da tabela.", "error");
      return;
    }

    if (!state.selectedDatabase || state.selectedDatabase === "TODOS") {
      setFooterStatus("Selecione um banco específico antes de validar a tabela digitada.", "error");
      return;
    }

    state.currentRecordJoinOptions = [];
    state.currentRecordRow = null;

    loadTablesForDatabase(state.selectedDatabase, function () {
      const rows = state.tableCache[state.selectedDatabase] || [];
      const found = rows.find(function (row) {
        return String(row.name || "").toLowerCase() === tableName.toLowerCase();
      });

      if (!found) {
        setFooterStatus("A tabela informada não existe no banco " + state.selectedDatabase + ".", "error");
        return;
      }

      state.selectedTable = found.name;
      applySelectedTableFromStepSearch();
    });
  }

  function applySelectedTableFromStepSearch(done) {
    $("#selectedTable").val(state.selectedTable || "");
    state.fields = [];
    state.foreignKeys = [];
    state.foreignKeyCache = {};
    state.filterRows = [];
    refreshFilterGrid();
    clearFilterTabs();
    ensureTableFields(loadFilterTabs);
    setStepSourceInfo();
    setFooterStatus("Tabela validada. Carregando campos e indices: " + state.selectedTable, "ok");
    if (typeof done === "function") {
      done();
    }
  }

  function openForeignKeySearch() {
    if (!state.selectedTable || !state.selectedDatabase) {
      setFooterStatus("Selecione banco e tabela para buscar chaves estrangeiras.", "error");
      return;
    }
    if (state.selectedDatabase === "TODOS") {
      setFooterStatus("Defina um banco especifico para consultar chaves estrangeiras.", "error");
      return;
    }
    if (!state.fields.length) {
      setFooterStatus("Carregue os metadados da tabela antes de buscar chaves estrangeiras.", "error");
      return;
    }

    setStatus("Procurando chaves estrangeiras de " + state.selectedDatabase + "." + state.selectedTable + "...", "");
    discoverForeignKeys(function () {
      const grid = $("#foreignKeySearchGrid").data("kendoGrid");
      grid.dataSource.data(state.foreignKeys);
      $("#foreignKeySearchText").val("");
      const win = $("#foreignKeySearchWindow").data("kendoWindow");
      win.setOptions({ title: "Chaves estrangeiras - " + state.selectedDatabase + "." + state.selectedTable });
      win.center().open();
      setStatus("Chaves estrangeiras carregadas: " + state.foreignKeys.length, "ok");
    });
  }

  function setStepSourceInfo() {
    const sourceText = state.selectedDatabase && state.selectedTable
      ? "Selecionado: " + state.selectedDatabase + "." + state.selectedTable
      : "Selecione uma tabela na etapa 1.";
    $("#tableSelectedInfo").text(sourceText);
    $("#selectedTable").val(state.selectedTable);
  }

  function applyForeignKeySearch() {
    const text = String($("#foreignKeySearchText").val() || "").trim().toLowerCase();
    const grid = $("#foreignKeySearchGrid").data("kendoGrid");
    if (!grid) return;

    if (!text) {
      grid.dataSource.data(state.foreignKeys);
      return;
    }

    const filtered = state.foreignKeys.filter(function (item) {
      const values = [
        item.localField,
        item.localLabel,
        item.foreignTable,
        item.localToForeignField,
        item.relationStatus
      ];
      return values.some((value) => String(value || "").toLowerCase().indexOf(text) >= 0);
    });
    grid.dataSource.data(filtered);
  }

  function openForeignKeyTable(item) {
    const table = item && item.foreignTable;
    if (!table) {
      setFooterStatus("Relacao sem tabela destino definida.", "error");
      return;
    }
    const db = item.foreignDatabase || state.selectedDatabase;
    if (!db) {
      setFooterStatus("Nao foi possivel identificar banco da tabela relacionada.", "error");
      return;
    }

    state.fields = [];
    state.filterRows = [];
    refreshFilterGrid();
    clearFilterTabs();

    const combo = $("#databaseCombo").data("kendoComboBox");
    if (combo) {
      combo.value(db);
      combo.refresh();
    }
    setStepSourceInfo();

    loadTablesForDatabase(db, function () {
      ensureTableFields(function () {
        state.foreignKeys = [];
        state.foreignKeyCache = {};
        setStatus("Tabela relacionada selecionada: " + db + "." + table, "ok");
        showStep(2);
      });
    });

    const win = $("#foreignKeySearchWindow").data("kendoWindow");
    if (win) win.close();
  }

  function clearFilterTabs() {
    const tabEl = $("#indexFilterTabs");
    const existing = tabEl.data("kendoTabStrip");
    if (existing) {
      existing.destroy();
    }
    tabEl.empty();
  }

  function updateSourceSelection() {
    const combo = $("#databaseCombo").data("kendoComboBox");
    if (combo) combo.value(state.selectedDatabase || combo.value() || "TODOS");
    setStepSourceInfo();
  }

  function ensureTableFields(done) {
    if (!state.selectedTable || !state.selectedDatabase) {
      setFooterStatus("Selecione banco e tabela.", "error");
      return;
    }

    if (state.selectedDatabase === "TODOS") {
      setFooterStatus("Defina um banco especifico antes de carregar campos.", "error");
      return;
    }

    setStatus("Carregando metadados de campos de " + state.selectedDatabase + "." + state.selectedTable + "...", "");
    getJsonUtf8(state.apiBase + "/metadata/tables/" + encodeURIComponent(state.selectedTable) + "/fields?database=" + encodeURIComponent(state.selectedDatabase))
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        state.fields = (response.fields || response.data || []).map((field, index) => ({
          ...field,
          __seq: index
        }));
        state.fieldsByName = state.fields.reduce((acc, field) => {
          if (field && field.name) {
            acc[field.name] = field;
          }
          return acc;
        }, {});
        state.foreignKeys = [];
        state.foreignKeyCache = {};
        refreshFilterDynamicSelectors();
        setStatus("Campos carregados: " + state.fields.length, "ok");
        state.filterRows = [];
        refreshFilterGrid();
        buildFilterTabs(state.fields);
        if (typeof done === "function") done();
      })
      .fail(function (xhr) {
        const msg = xhr && (xhr.responseText || xhr.statusText) ? ("Erro " + (xhr.status || "") + " " + (xhr.responseText || xhr.statusText)) : "Erro desconhecido";
        setStatus("Falha ao carregar campos: " + msg, "error");
      });
  }

  function discoverForeignKeys(done) {
    const cacheKey = state.selectedDatabase + "::" + state.selectedTable;
    if (state.foreignKeyCache[cacheKey]) {
      state.foreignKeys = state.foreignKeyCache[cacheKey];
      if (typeof done === "function") done();
      return;
    }

    const refs = [];
    const seen = {};
    (state.fields || []).forEach(function (field) {
      const tables = extractForeignTablesFromExpression(field.listExpression || "");
      if (!tables.length) return;
      tables.forEach(function (foreignTable) {
        const key = state.selectedTable + "|" + field.name + "|" + foreignTable;
        if (seen[key]) return;
        seen[key] = true;
        refs.push({
          localField: field.name,
          localLabel: field.label || field.name,
          foreignTable,
          foreignDatabase: state.selectedDatabase,
          localToForeignField: "",
          relationStatus: "Buscando..."
        });
      });
    });

    if (!refs.length) {
      state.foreignKeys = [];
      state.foreignKeyCache[cacheKey] = [];
      if (typeof done === "function") done();
      return;
    }

    Promise.all(refs.map(loadRelationForForeignTable)).then(function (rows) {
      state.foreignKeys = rows.filter(Boolean);
      state.foreignKeyCache[cacheKey] = state.foreignKeys;
      if (typeof done === "function") done();
    }).catch(function () {
      state.foreignKeys = refs;
      state.foreignKeyCache[cacheKey] = state.foreignKeys;
      if (typeof done === "function") done();
    });
  }

  function extractForeignTablesFromExpression(expression) {
    if (!expression || typeof expression !== "string") return [];
    const result = [];
    const regex = /can-find\s*\(\s*([A-Za-z0-9_-]+)\b/g;
    let match;
    while ((match = regex.exec(expression)) !== null) {
      const table = String(match[1] || "").trim();
      if (table && result.indexOf(table) < 0) {
        result.push(table);
      }
    }
    return result;
  }

  function loadRelationForForeignTable(candidate) {
    const database = state.selectedDatabase;
    const localTable = state.selectedTable;
    const foreignTable = candidate.foreignTable;

    return new Promise((resolve) => {
      const resolveCandidate = function (response, swapped) {
        if (!response || response.success === false || !response.relation && !response.leftTable && !response.rightTable) {
          candidate.relationStatus = swapped ? "Sem relacao encontrada (ordem reversa)" : "Sem relacao encontrada";
          resolve(candidate);
          return;
        }

        const rel = normalizeRelation(response.relation || response);
        const remoteField = pickForeignField(rel, localTable, candidate.localField, swapped);
        candidate.relationStatus = "Encontrada";
        candidate.foreignTable = (rel.rightTable === localTable ? rel.leftTable : rel.rightTable) || candidate.foreignTable;
        candidate.foreignDatabase = (rel.rightTable === localTable ? rel.leftDatabase : rel.rightDatabase) || database;
        candidate.localToForeignField = remoteField;
        resolve(candidate);
      };

      const primary = state.apiBase + "/metadata/relations/" + encodeURIComponent(localTable) + "/" + encodeURIComponent(foreignTable) +
        "?leftDatabase=" + encodeURIComponent(database) + "&rightDatabase=" + encodeURIComponent(database);
      const secondary = state.apiBase + "/metadata/relations/" + encodeURIComponent(foreignTable) + "/" + encodeURIComponent(localTable) +
        "?leftDatabase=" + encodeURIComponent(database) + "&rightDatabase=" + encodeURIComponent(database);

      const xhr1 = getJsonUtf8(primary);
      xhr1.done(function (response) {
        if (response && response.success !== false && (response.relation || response.leftTable || response.rightTable)) {
          resolveCandidate(response, false);
          return;
        }
        getJsonUtf8(secondary).done(function (response2) {
          if (response2 && response2.success !== false && (response2.relation || response2.leftTable || response2.rightTable)) {
            resolveCandidate(response2, true);
            return;
          }
          resolveCandidate(null, false);
        }).fail(function () {
          resolveCandidate(null, false);
        });
      }).fail(function () {
        getJsonUtf8(secondary).done(function (response2) {
          if (response2 && response2.success !== false && (response2.relation || response2.leftTable || response2.rightTable)) {
            resolveCandidate(response2, true);
            return;
          }
          resolveCandidate(null, false);
        }).fail(function () {
          resolveCandidate(null, false);
        });
      });
    });
  }

  function normalizeRelation(relation) {
    return {
      leftTable: relation.leftTable || relation.left || "",
      rightTable: relation.rightTable || relation.right || "",
      leftDatabase: relation.leftDatabase || relation.database || state.selectedDatabase,
      rightDatabase: relation.rightDatabase || relation.database || state.selectedDatabase,
      fields: Array.isArray(relation.fields) ? relation.fields : [],
      leftField: relation.leftField || "",
      rightField: relation.rightField || ""
    };
  }

  function readFilterValue($input) {
    const meta = readFilterInputValue($input);
    return meta.raw;
  }

  function readFilterInputValue($input) {
    if (!$input || !$input.length) {
      return { values: [], raw: "", rawToPayload: "", isMulti: false };
    }

    const node = $input[0];
    const $node = $(node);
    const widgetText = $node.data("kendoTextBox");
    const widgetNumeric = $node.data("kendoNumericTextBox");
    const widgetDate = $node.data("kendoDatePicker") || $node.data("kendoDateTimePicker");
    const widgetMulti = $node.data("kendoMultiSelect");

    if (widgetMulti) {
      const rawValues = widgetMulti.value() || [];
      const values = rawValues
        .map(function (value) {
          if (value === null || value === undefined) return "";
          return String(value).trim();
        })
        .filter(function (value) {
          return value.length > 0;
        });
      return {
        values,
        raw: values.join(","),
        rawToPayload: values.join(","),
        isMulti: true
      };
    }

    if (widgetText) {
      const value = widgetText.value();
      const normalized = normalizeScalarFilterText(value);
      return { values: normalized ? [normalized] : [], raw: normalized, rawToPayload: normalized, isMulti: false };
    }
    if (widgetNumeric) {
      const value = widgetNumeric.value();
      const normalized = normalizeScalarFilterText(value);
      return { values: normalized ? [normalized] : [], raw: normalized, rawToPayload: normalized, isMulti: false };
    }
    if (widgetDate) {
      const value = widgetDate.value();
      const normalized = normalizeDateForPayload(value);
      return { values: normalized ? [normalized] : [], raw: normalized, rawToPayload: normalized, isMulti: false };
    }

    const candidates = [];
    const cached = $node.data("filterValue");
    if (cached !== null && cached !== undefined && cached !== "") {
      const normalized = normalizeScalarFilterText(cached);
      return { values: normalized ? [normalized] : [], raw: normalized, rawToPayload: normalized, isMulti: false };
    }

    if ($node.is("input, textarea, select")) {
      candidates.push(node);
    }
    const parentInput = $node.closest(".index-filter-value").find("input, textarea, select").toArray();
    parentInput.forEach(function (candidate) {
      if (candidates.indexOf(candidate) < 0) candidates.push(candidate);
    });
    $node.find("input, textarea, select").toArray().forEach(function (candidate) {
      if (candidates.indexOf(candidate) < 0) candidates.push(candidate);
    });
    $node.parent().find("input, textarea, select").toArray().forEach(function (candidate) {
      if (candidates.indexOf(candidate) < 0) candidates.push(candidate);
    });

    for (let i = 0; i < candidates.length; i++) {
      const value = normalizeScalarFilterText($(candidates[i]).val());
      if (value.length > 0) {
        return { values: [value], raw: value, rawToPayload: value, isMulti: false };
      }
    }

    return { values: [], raw: "", rawToPayload: "", isMulti: false };
  }

  function readFilterOperator($row) {
    const operatorWidget = $row.find(".index-filter-operator").data("kendoDropDownList");
    const direct = operatorWidget && operatorWidget.value() ? operatorWidget.value() : String($row.find(".index-filter-operator").val() || "").trim();
    return direct || TAB_OPS[0].value;
  }

  function addFilterFromRow(row) {
    const field = row.data("field");
    const indexName = String(row.data("index"));
    const operator = readFilterOperator(row);
    const fieldMeta = getFieldMeta(field);
    const valueInput = row.find("input.index-filter-value, textarea.index-filter-value, select.index-filter-value").first();
    const toInput = row.find("input.index-filter-value-to, textarea.index-filter-value-to, select.index-filter-value-to").first();
    const normalized = normalizeFilterValue(fieldMeta, operator, readFilterInputValue(valueInput), readFilterInputValue(toInput), true);

    if (!normalized) {
      return false;
    }

    state.filterRows.push({
      __id: String(state.activeFilterId++),
      indexName: indexName || "Indice",
      field,
      operator: normalized.operator,
      value: normalized.value,
      valueTo: normalized.valueTo,
      sourceAlias: "t"
    });
    refreshFilterGrid();
    const valueText = normalized.valueTo ? `${normalized.value} e ${normalized.valueTo}` : normalized.value;
    setFooterStatus("Filtro adicionado: " + field + " " + normalized.operator + " " + valueText, "ok");
    row.find(".index-filter-value, .index-filter-value-to").each(function () {
      const input = $(this);
      const widgetMulti = input.data("kendoMultiSelect");
      const widgetDate = input.data("kendoDatePicker");
      const widgetDateTime = input.data("kendoDateTimePicker");
      const widgetNum = input.data("kendoNumericTextBox");
      const widgetText = input.data("kendoTextBox");
      if (widgetMulti) widgetMulti.value([]);
      if (widgetDate) widgetDate.value(null);
      if (widgetDateTime) widgetDateTime.value(null);
      if (widgetNum) widgetNum.value(null);
      if (widgetText) widgetText.value("");
      input.val("");
    });
    return true;
  }

  function addDynamicFilter() {
    const combo = $("#dynamicFilterField").data("kendoComboBox");
    const selected = combo ? combo.value() : "";
    const fieldMeta = getFieldMeta(selected);
    if (!fieldMeta) {
      setFooterStatus("Selecione um campo para o filtro dinâmico.", "error");
      return false;
    }
    const operatorWidget = $("#dynamicFilterOperator").data("kendoDropDownList");
    const operator = operatorWidget && operatorWidget.value() ? operatorWidget.value() : DYNAMIC_OPS[0].value;
    const valueInput = $("#dynamicFilterValue");
    const valueInputTo = $("#dynamicFilterValueTo");

    const normalized = normalizeFilterValue(fieldMeta, operator, readFilterInputValue(valueInput), readFilterInputValue(valueInputTo), false);
    if (!normalized) {
      return false;
    }

    state.filterRows.push({
      __id: String(state.activeFilterId++),
      indexName: "Filtro dinâmico",
      field: fieldMeta.name,
      operator: normalized.operator,
      value: normalized.value,
      valueTo: normalized.valueTo,
      sourceAlias: "t"
    });
    refreshFilterGrid();
    const valueText = normalized.valueTo ? `${normalized.value} e ${normalized.valueTo}` : normalized.value;
    setFooterStatus("Filtro dinâmico adicionado: " + fieldMeta.label + " " + normalized.operator + " " + valueText, "ok");
    $("#dynamicFilterValue").val("");
    $("#dynamicFilterValueTo").val("");
    const dynamicFilterInput = $("#dynamicFilterValue");
    if (dynamicFilterInput.data("kendoMultiSelect")) dynamicFilterInput.data("kendoMultiSelect").value([]);
    return true;
  }

  function pickForeignField(relation, localTable, localField) {
    if (relation.leftTable === localTable) {
      if (relation.leftField === localField) return relation.rightField || "";
      const match = (relation.fields || []).find((item) => item.leftField === localField);
      return match ? (match.rightField || "") : "";
    }
    if (relation.rightTable === localTable) {
      if (relation.rightField === localField) return relation.leftField || "";
      const match = (relation.fields || []).find((item) => item.rightField === localField);
      return match ? (match.leftField || "") : "";
    }
    return "";
  }

  function buildFilterTabs(fields) {
    const groups = groupFieldsByIndex(fields);
    const indexNames = Object.keys(groups).sort();
    const tabEl = $("#indexFilterTabs");

    const existing = tabEl.data("kendoTabStrip");
    if (existing) {
      existing.destroy();
      tabEl.empty();
    }

    const dynamicTabId = "index-filter-dynamic-tab";
    const hasIndexes = indexNames.length > 0;
    const moveDynamicFilterSection = function (activeTabId) {
      const targetPanel = $("#" + dynamicTabId);
      const dynamicSection = $("#dynamicFilterSection");
      if (!targetPanel.length || !dynamicSection.length) return;
      dynamicSection.appendTo(targetPanel);
      if (activeTabId) {
        targetPanel.addClass("active");
      } else {
        targetPanel.removeClass("active");
      }
      setTimeout(function () {
        const dynamicValue = $("#dynamicFilterValue");
        if (dynamicValue.length && dynamicValue.closest(".dynamic-filter-grid").length) {
          const operator = $("#dynamicFilterOperator").data("kendoDropDownList");
          if (operator && typeof operator.value === "function" && !operator.value()) {
            refreshFilterDynamicSelectors();
          }
        }
      }, 0);
    };

    const usedTabIds = {};
    const tabs = indexNames.map(function (name, index) {
      const baseId = normalizeTabId(name || `indice-${index}`);
      const tabId = usedTabIds[baseId] ? `${baseId}-${usedTabIds[baseId]}` : baseId;
      usedTabIds[baseId] = (usedTabIds[baseId] || 0) + 1;

      const list = groups[name] || [];
      const rows = list.map(function (field) {
        return `
          <div class="index-filter-item" data-field="${escapeHtml(field.name)}" data-index="${escapeHtml(name)}">
            <label>${escapeHtml(field.label || field.name)}
              <span style="color:#666;font-size:11px;">${escapeHtml(field.name)} | ${escapeHtml(field.type || "")}</span>
            </label>
            <label>
              Operador
              <input class="index-filter-operator" />
            </label>
            <label>
              Valor
              <input class="index-filter-value k-textbox" type="text" placeholder="valor" />
            </label>
            <div class="index-filter-bounds" data-for="between">
              <label>
                Valor final
                <input class="index-filter-value-to k-textbox" type="text" placeholder="valor final" />
              </label>
              <span></span>
            </div>
            <button class="k-button k-button-sm add-index-filter" type="button">Adicionar</button>
          </div>
        `;
      }).join("");

      return {
        name,
        tabId,
        html: `<section id="${tabId}" class="manual-tab-panel ${index === 0 ? "active" : ""}">
          <div class="index-tab-head">Indice: ${escapeHtml(name)}</div>
          ${rows || "<div class=\"status-box\">Sem campo com este indice.</div>"}
        </section>`
      };
    });

    const nav = tabs.map((tab, index) =>
      `<button type="button" class="manual-tab ${index === 0 ? "active" : ""}" data-target="#${tab.tabId}">${escapeHtml(tab.name)}</button>`
    ).join("");
    const dynamicNav = `<button type="button" class="manual-tab ${hasIndexes ? "" : "active"}" data-target="#${dynamicTabId}">Filtros dinâmicos</button>`;
    const dynamicPanel = `<section id="${dynamicTabId}" class="manual-tab-panel ${hasIndexes ? "" : "active"}"></section>`;
    const panels = tabs.map((tab) => tab.html).join("") + dynamicPanel;
    const manualHtml = `<div class="manual-tab-nav">${nav}${dynamicNav}</div><div class="manual-tab-panels">${panels}</div>`;
    tabEl.html(manualHtml);

    tabEl.find(".manual-tab").on("click", function () {
      const target = $(this).data("target");
      tabEl.find(".manual-tab").removeClass("active");
      $(this).addClass("active");
      tabEl.find(".manual-tab-panel").removeClass("active");
      tabEl.find(target).addClass("active");
    });
    moveDynamicFilterSection(!hasIndexes);

    try {
      setFooterStatus(`Filtros por índice/abas: ${indexNames.length} | Campos: ${fields.length}`, "");
    } catch (_) {}

    requestAnimationFrame(function () {
      initIndexFilterWidgets(tabEl);
    });

    return;
  }

  function groupFieldsByIndex(fields) {
    const grouped = {};
    (fields || []).forEach(function (field) {
      const indexList = splitIndices(field.indices || field.indexes || field.index);
      if (!indexList.length) return;
      indexList.forEach(function (indexName) {
        if (!grouped[indexName]) grouped[indexName] = [];
        grouped[indexName].push(field);
      });
    });
    return grouped;
  }

  function splitIndices(value) {
    if (!value) return [];

    if (Array.isArray(value)) {
      return value
        .map((item) => String(item || "").trim())
        .filter((item) => item);
    }

    if (typeof value === "string") {
      const text = String(value).trim();
      if (!text) return [];
      if (text[0] === "[" && text[text.length - 1] === "]") {
        try {
          const parsed = JSON.parse(text);
          if (Array.isArray(parsed)) {
            return parsed.map((item) => String(item || "").trim()).filter((item) => item);
          }
        } catch (_) {}
      }
      return text
        .split(/[,;|\s]+/)
        .map((item) => String(item || "").trim())
        .filter((item) => item);
    }

    if (typeof value !== "string") {
      if (typeof value === "object" && value !== null && !Array.isArray(value)) {
        if (value.name || value.value) {
          return [String(value.name || value.value)].filter((item) => item);
        }
        return [JSON.stringify(value)];
      }

      return [String(value)]
        .map((item) => item.trim())
        .filter((item) => item);
    }
  }

  function hydrateDynamicFilterOperator() {
    const combo = $("#dynamicFilterField").data("kendoComboBox");
    const value = combo ? combo.value() : "";
    const fieldMeta = getFieldMeta(value);
    if (!fieldMeta) {
      const dynamicOperator = $("#dynamicFilterOperator").data("kendoDropDownList");
      if (dynamicOperator) {
        dynamicOperator.setDataSource([]);
        dynamicOperator.value("");
      }
      recreateDynamicFilterInput();
      return;
    }
    configureFilterOperator($("#dynamicFilterOperator").data("kendoDropDownList"), fieldMeta, true);
    recreateDynamicFilterInput(fieldMeta);
    updateDynamicBetweenInputs();
  }

  function configureFilterOperator(dropDown, fieldMeta, fromDynamic) {
    if (!dropDown) return;
    const operators = getAllowedOperators(fieldMeta).map(function (item) {
      return {
        value: item.value,
        label: item.label
      };
    });
    dropDown.setDataSource(operators);
    const current = dropDown.value();
    const valid = operators.some(function (item) { return item.value === current; });
    dropDown.value(valid ? current : operators[0] ? operators[0].value : "");
    if (fromDynamic) {
      dropDown.trigger("change");
    }
  }

  function refreshFilterDynamicSelectors() {
    const fields = state.fields || [];
    const combo = $("#dynamicFilterField").data("kendoComboBox");
    const operator = $("#dynamicFilterOperator").data("kendoDropDownList");
    const items = fields.map(function (field) {
      return {
        name: field.name,
        label: field.label || field.name
      };
    });
    if (combo) {
      combo.setDataSource(items);
      combo.value("");
      if (!items.length) {
        combo.enable(false);
      } else {
        combo.enable(true);
      }
    }
    if (operator) {
      operator.setDataSource([]);
      operator.value("");
      operator.enable(false);
    }
    recreateDynamicFilterInput();
    updateDynamicBetweenInputs();
  }

  function recreateDynamicFilterInput(fieldMeta) {
    const valueWrap = $("#dynamicFilterValueWrap");
    if (!valueWrap.length) return;
    const valueInput = $("#dynamicFilterValue");
    const toInput = $("#dynamicFilterValueTo");
    const existingTo = toInput.closest(".index-filter-bounds");

    if (valueInput.data("kendoMultiSelect")) valueInput.data("kendoMultiSelect").destroy();
    if (valueInput.data("kendoTextBox")) valueInput.data("kendoTextBox").destroy();
    if (valueInput.data("kendoNumericTextBox")) valueInput.data("kendoNumericTextBox").destroy();
    if (valueInput.data("kendoDatePicker")) valueInput.data("kendoDatePicker").destroy();
    if (valueInput.data("kendoDateTimePicker")) valueInput.data("kendoDateTimePicker").destroy();
    valueWrap.empty();
    valueWrap.append("<input id='dynamicFilterValue' />");
    if (existingTo.length) existingTo.remove();
    if (toInput.length) toInput.remove();
    initFilterValueInput($("#dynamicFilterValue"), fieldMeta, true);
  }

  function updateDynamicBetweenInputs() {
    const input = $("#dynamicFilterOperator");
    const op = input.data("kendoDropDownList") ? String(input.data("kendoDropDownList").value() || "").toLowerCase() : "";
    const isBetween = op === "between";
    const combo = $("#dynamicFilterField").data("kendoComboBox");
    const fieldMeta = combo ? getFieldMeta(combo.value()) : null;
    if (!isBetween) {
      $("#dynamicFilterValueToContainer").remove();
      return;
    }

    const valueWrap = $("#dynamicFilterValueWrap");
    const currentOperator = $("#dynamicFilterOperator");
    if ($("#dynamicFilterValueToContainer").length) return;
    const toWrap = $("<div id='dynamicFilterValueToContainer' class='index-filter-bounds active'></div>");
    toWrap.html(`
      <label>Valor final
        <input id="dynamicFilterValueTo" />
      </label>
      <span></span>
    `);
    valueWrap.closest(".dynamic-filter-grid").append(toWrap);
    initFilterValueInput($("#dynamicFilterValueTo"), fieldMeta, true);
    if (fieldMeta && !fieldMeta.options?.length) {
      $("#dynamicFilterValueTo").prop("disabled", true);
      if (fieldMeta.type && isDateType(fieldMeta)) {
        $("#dynamicFilterValueTo").prop("disabled", false);
      }
    }
  }

  function getFieldMeta(fieldName) {
    if (!fieldName) return null;
    return state.fieldsByName[fieldName] || null;
  }

  function getFieldType(fieldMeta) {
    if (!fieldMeta) return "";
    return String(fieldMeta.type || fieldMeta.fieldType || "").toLowerCase();
  }

  function isDateType(fieldMeta) {
    const c = getFieldType(fieldMeta);
    return ["date", "datetime"].indexOf(c) >= 0;
  }

  function isDecimalType(fieldMeta) {
    const c = getFieldType(fieldMeta);
    return ["decimal", "float", "double", "int64", "integer"].indexOf(c) >= 0;
  }

  function isLogicalType(fieldMeta) {
    return getFieldType(fieldMeta) === "logical";
  }

  function parseDateInput(value) {
    if (!value) return null;
    if (Object.prototype.toString.call(value) === "[object Date]") {
      return isNaN(value.getTime()) ? null : value;
    }

    const text = normalizeScalarFilterText(value);
    if (!text) return null;

    const withTTime = text.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?)?$/);
    if (withTTime) {
      const y = Number(withTTime[1]);
      const m = Number(withTTime[2]) - 1;
      const d = Number(withTTime[3]);
      const hh = Number(withTTime[4] || 0);
      const mi = Number(withTTime[5] || 0);
      const ss = Number(withTTime[6] || 0);
      return new Date(y, m, d, hh, mi, ss);
    }

    const br = text.match(/^(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?)?$/);
    if (br) {
      const d = Number(br[1]);
      const m = Number(br[2]) - 1;
      const y = Number(br[3]);
      const hh = Number(br[4] || 0);
      const mi = Number(br[5] || 0);
      const ss = Number(br[6] || 0);
      return new Date(y, m, d, hh, mi, ss);
    }

    return null;
  }

  function toPayloadDateTime(fieldType, raw) {
    const dt = parseDateInput(raw);
    if (!dt) return "";
    const yyyy = dt.getFullYear();
    const mm = String(dt.getMonth() + 1).padStart(2, "0");
    const dd = String(dt.getDate()).padStart(2, "0");
    if (fieldType === "datetime") {
      const hh = String(dt.getHours()).padStart(2, "0");
      const mi = String(dt.getMinutes()).padStart(2, "0");
      const ss = String(dt.getSeconds()).padStart(2, "0");
      return `${yyyy}-${mm}-${dd} ${hh}:${mi}:${ss}`;
    }
    return `${yyyy}-${mm}-${dd}`;
  }

  function isListField(fieldMeta) {
    return !!(fieldMeta && Array.isArray(fieldMeta.options) && fieldMeta.options.length);
  }

  function getAllowedOperators(fieldMeta) {
    const type = getFieldType(fieldMeta);
    if (isLogicalType(fieldMeta)) {
      return TAB_OPS.filter(function (op) {
        return ["="].indexOf(op.value) >= 0;
      });
    }
    if (["character"].indexOf(type) >= 0) {
      return TAB_OPS.filter(function (op) {
        return ["=", "<>", "contains", "begins", "in"].indexOf(op.value) >= 0;
      });
    }
    if (["integer", "int64", "decimal", "date", "datetime"].indexOf(type) >= 0) {
      if (isListField(fieldMeta)) {
        return TAB_OPS.filter(function (op) {
          return ["=", "<>", ">", ">=", "<", "<=", "between", "in"].indexOf(op.value) >= 0;
        });
      }
      return TAB_OPS.filter(function (op) {
        return ["=", "<>", ">", ">=", "<", "<=", "between"].indexOf(op.value) >= 0;
      });
    }
    return DYNAMIC_OPS;
  }

  function normalizeDateForPayload(value) {
    if (!value) return "";
    if (Object.prototype.toString.call(value) === "[object Date]") {
      if (isNaN(value.getTime())) return "";
      const yyyy = value.getFullYear();
      const mm = String(value.getMonth() + 1).padStart(2, "0");
      const dd = String(value.getDate()).padStart(2, "0");
      const hasTime = value.getHours() !== 0 || value.getMinutes() !== 0 || value.getSeconds() !== 0;
      if (!hasTime) return `${yyyy}-${mm}-${dd}`;
      return `${yyyy}-${mm}-${dd} ${String(value.getHours()).padStart(2, "0")}:${String(value.getMinutes()).padStart(2, "0")}:${String(value.getSeconds()).padStart(2, "0")}`;
    }
    const text = normalizeScalarFilterText(value);
    return text;
  }

  function normalizeScalarFilterText(value) {
    if (value === 0) return "0";
    if (value === null || value === undefined) return "";
    return String(value).trim();
  }

  function validateFilterValues(fieldMeta, operator, valueData, valueToData) {
    const type = getFieldType(fieldMeta);
    const isList = isListField(fieldMeta);
    const isBetween = operator === "between";
    const values = Array.isArray(valueData.values) && valueData.values.length ? valueData.values : (valueData.raw ? [valueData.raw] : []);
    const toValues = Array.isArray(valueToData && valueToData.values) ? valueToData.values : ((valueToData && valueToData.raw) ? [valueToData.raw] : []);
    const resolvedOperator = resolveListOperator(operator, values, isList, isBetween);

    if (isBetween) {
      if (!values[0] || !toValues[0]) {
        setFooterStatus("Informe o intervalo inicial e final.", "error");
        return null;
      }
      if (!validateFieldScalar(fieldMeta, values[0]) || !validateFieldScalar(fieldMeta, toValues[0])) {
        return null;
      }
      return {
        operator: "between",
        value: values[0],
        valueTo: toValues[0]
      };
    }

    if (!values[0] && !(isList && values.length > 1)) {
      setFooterStatus("Informe um valor para o filtro.", "error");
      return null;
    }

    if (!validateFieldScalar(fieldMeta, values[0])) return null;
    if (resolvedOperator === "in") {
      const safeValues = values.filter(Boolean).filter(function (item) { return validateFieldScalar(fieldMeta, item); });
      if (!safeValues.length) {
        setFooterStatus("Informe valores válidos para o filtro.", "error");
        return null;
      }
      return {
        operator: "in",
        value: safeValues.join(","),
        valueTo: ""
      };
    }

    return {
      operator: resolvedOperator,
      value: values[0],
      valueTo: ""
    };
  }

  function resolveListOperator(operator, values, isList, isBetween) {
    if (isBetween) return "between";
    if (isList && values.length > 1) return "in";
    if (isList && values.length === 1 && operator === "in") return "=";
    return operator || "=";
  }

  function validateFieldScalar(fieldMeta, value) {
    const text = normalizeScalarFilterText(value);
    if (text === "") return false;
    const type = getFieldType(fieldMeta);
    if (type === "integer" || type === "int64") {
      if (!/^-?\d+$/.test(text)) {
        setFooterStatus("Informe um número inteiro válido para o campo " + (fieldMeta.name || ""), "error");
        return false;
      }
      return true;
    }
    if (type === "decimal" || type === "float" || type === "double" || type === "amount") {
      if (isNaN(Number(text.replace(",", ".")))) {
        setFooterStatus("Informe um número válido para o campo " + (fieldMeta.name || ""), "error");
        return false;
      }
      return true;
    }
    if (type === "date" || type === "datetime") {
      const parsed = parseDateInput(text);
      if (!parsed || isNaN(parsed.getTime())) {
        setFooterStatus("Informe uma data válida para o campo " + (fieldMeta.name || ""), "error");
        return false;
      }
      return true;
    }
    if (isLogicalType(fieldMeta)) {
      const normalized = normalizeLogicalValue(text);
      if (normalized === "") {
        setFooterStatus("Informe um valor lógico válido (true/false/1/0) para " + (fieldMeta.name || ""), "error");
        return false;
      }
    }
    return true;
  }

  function normalizeLogicalValue(value) {
    const normalized = normalizeScalarFilterText(value).toLowerCase();
    if (["true", "false", "1", "0", "sim", "nao", "não"].indexOf(normalized) >= 0) {
      if (["true", "1", "sim"].indexOf(normalized) >= 0) return "true";
      return "false";
    }
    return "";
  }

  function normalizeFilterValue(fieldMeta, operator, valueData, valueToData, _forIndex) {
    const fieldName = fieldMeta ? fieldMeta.name : "";
    const isList = isListField(fieldMeta);
    const isBetween = String(operator || "").toLowerCase() === "between";
    const normalized = validateFilterValues(fieldMeta, operator, valueData || {}, valueToData || {});
    if (!normalized) return null;

    if (isBetween) {
      const toType = valueToData && valueToData.raw;
      if (toType && toType !== "") {
        normalized.valueTo = isList && !isDecimalType(fieldMeta) ? valueToData.raw : valueToData.raw;
      }
    }

    if (isList && normalized.operator === "=" && !isBetween && !isDecimalType(fieldMeta) && fieldMeta && fieldMeta.options && fieldMeta.options.length) {
      normalized.value = valueData.values && valueData.values.length ? valueData.values[0] : valueData.raw;
    }
    if (!normalized.value && valueData && valueData.raw) {
      normalized.value = valueData.raw;
    }
    normalized.value = normalizeScalarFilterValue(fieldMeta, normalized.value);
    if (normalized.valueTo) normalized.valueTo = normalizeScalarFilterValue(fieldMeta, normalized.valueTo);
    if (!normalized.value && normalized.operator !== "in") {
      setFooterStatus("Informe um valor para o filtro de " + (fieldName || "campo"), "error");
      return null;
    }
    return normalized;
  }

  function normalizeScalarFilterValue(fieldMeta, value) {
    const text = normalizeScalarFilterText(value);
    if (!text) return "";
    if (isLogicalType(fieldMeta)) {
      return normalizeLogicalValue(text) || "false";
    }
    if (isDateType(fieldMeta)) {
      const dateType = getFieldType(fieldMeta);
      return toPayloadDateTime(dateType, text);
    }
    if (isDecimalType(fieldMeta)) {
      return String(Number(text.replace(",", ".")));
    }
    return text;
  }

  function normalizeFilterInputByType($input, fieldMeta) {
    if (!$input || !$input.length) return;
    const toDestroy = [];
    const data = $input.data();
    if (data.kendoTextBox) toDestroy.push(data.kendoTextBox);
    if (data.kendoNumericTextBox) toDestroy.push(data.kendoNumericTextBox);
    if (data.kendoDatePicker) toDestroy.push(data.kendoDatePicker);
    if (data.kendoDateTimePicker) toDestroy.push(data.kendoDateTimePicker);
    if (data.kendoMultiSelect) toDestroy.push(data.kendoMultiSelect);
    toDestroy.forEach(function (widget) {
      if (widget && widget.destroy) {
        widget.destroy();
      }
    });

    if (isListField(fieldMeta) && !fieldMeta.noKendoMulti) {
      const dataSource = normalizeListOptions(fieldMeta.options);
      $input.kendoMultiSelect({
        dataTextField: "label",
        dataValueField: "value",
        dataSource,
        autoClose: false,
        filter: "contains",
        placeholder: "Selecione",
        change: function () {
          $input.data("filterValue", $input.val());
        }
      });
      return;
    }

    if (isDateType(fieldMeta)) {
      $input.kendoDatePicker({
        format: "dd/MM/yyyy"
      });
      return;
    }

    if (isDecimalType(fieldMeta)) {
      $input.kendoNumericTextBox({
        decimals: getFieldType(fieldMeta) === "integer" || getFieldType(fieldMeta) === "int64" ? 0 : 2,
        format: getFieldType(fieldMeta) === "integer" || getFieldType(fieldMeta) === "int64" ? "n0" : "n2"
      });
      return;
    }

    $input.kendoTextBox();
  }

  function initFilterValueInput($input, fieldMeta, isDynamic) {
    if (!$input || !$input.length) return;
    const target = $input.closest(".dynamic-filter-grid, .index-filter-item");
    if (isDynamic) {
      target.removeClass("has-error");
    }
    normalizeFilterInputByType($input, fieldMeta);
  }

  function initIndexFilterWidgets(tabEl) {
    tabEl.find(".index-filter-item").each(function () {
      const row = $(this);
      const field = row.data("field");
      const fieldMeta = getFieldMeta(field);
      const operator = row.find(".index-filter-operator").data("kendoDropDownList");
      configureFilterOperator(operator, fieldMeta);
      if (operator) {
        operator.unbind("change");
        operator.bind("change", function () {
          toggleBetweenInputs(row);
          configureFilterOperator($(this).data("kendoDropDownList"), fieldMeta);
        });
      }
      row.find(".index-filter-value, .index-filter-value-to").each(function () {
        initFilterValueInput($(this), fieldMeta, false);
      });
      toggleBetweenInputs(row);
    });
  }

  function toggleBetweenInputs(row) {
    const operator = String(readFilterOperator(row) || "").toLowerCase();
    const bounds = row.find(".index-filter-bounds[data-for='between']");
    if (operator === "between") {
      bounds.addClass("active");
    } else {
      bounds.removeClass("active");
    }
  }

  function normalizeListOptions(options) {
    return (options || []).map(function (option) {
      if (option && typeof option === "object") {
        return {
          label: option.label || option.name || String(option.value || ""),
          value: option.value != null ? String(option.value) : String(option)
        };
      }
      return { label: String(option), value: String(option) };
    });
  }

  function loadFilterTabs() {
    buildFilterTabs(state.fields);
    showStep(2);
  }

  function refreshFilterGrid() {
    const grid = $("#filtersGrid").data("kendoGrid");
    if (!grid) return;
    grid.dataSource.data(state.filterRows);
  }

  function clearFilters() {
    state.filterRows = [];
    refreshFilterGrid();
    setFooterStatus("Filtros limpos.", "ok");
  }

  function buildResultColumns() {
    const grid = $("#dataGrid").data("kendoGrid");
    if (!grid) return;

    const columns = (state.fields || []).map((field) => ({
      field: field.name,
      title: field.label || field.name,
      width: Math.min(Math.max(160, (field.label || field.name).length * 8), 280)
    }));

    if (!columns.length) {
      columns.push({ field: "_noData", title: "Sem metadados" });
    }

    grid.setOptions({
      columns,
      pageable: { pageSize: Number($("#queryPageSize").data("kendoNumericTextBox").value()) }
    });
  }

  function runQuery() {
    if (!state.selectedTable || !state.selectedDatabase) {
      setFooterStatus("Selecione banco e tabela antes de executar.", "error");
      return;
    }

    if (state.selectedDatabase === "TODOS") {
      setFooterStatus("Selecione um banco especifico para executar a consulta.", "error");
      return;
    }

    if (!state.fields.length) {
      setFooterStatus("Carregue os metadados da tabela antes de executar.", "error");
      return;
    }

    const page = Number($("#queryPage").data("kendoNumericTextBox").value()) || 1;
    const pageSize = Number($("#queryPageSize").data("kendoNumericTextBox").value()) || 200;

    const payload = {
      execution: "sync",
      page,
      pageSize,
      sources: [{
        nome: state.selectedTable,
        alias: "t",
        banco: state.selectedDatabase,
        campos: state.fields.map((f) => f.name).join(",")
      }],
      filters: state.filterRows.map(function (row) {
        return {
          sourceAlias: "t",
          field: row.field,
          operator: row.operator,
          value: row.value,
          valueTo: row.valueTo
        };
      }),
      joins: [],
      orderBy: [],
      pipeline: []
    };

    setFooterStatus("Executando consulta...", "");
    $("#resultStatus").text("Executando consulta...");

    $.ajax({
      url: state.apiBase + "/query",
      method: "POST",
      contentType: "application/json",
      dataType: "json",
      data: JSON.stringify(payload)
    })
      .done(function (response) {
        if (!response || response.success === false) {
          const error = response && response.error ? response.error : { message: "Erro da API" };
          setFooterStatus(error.message || "Erro", "error");
          $("#resultStatus").text(error.message || "Erro da API");
          return;
        }
        renderQueryResult(response);
        setFooterStatus("Consulta concluida. Registros retornados: " + (response.recordsReturned || 0), "ok");
      })
      .fail(function (xhr) {
        const msg = "Falha na execucao: " + xhr.status + " " + xhr.statusText;
        setFooterStatus(msg, "error");
        $("#resultStatus").text(msg);
      });
  }

  function renderQueryResult(response) {
    const rows = response.data || [];
    const grid = $("#dataGrid").data("kendoGrid");
    if (!grid) return;

    buildResultColumns();
    grid.dataSource.data(rows);

    const records = Number(response.recordsReturned || rows.length);
    const hasMore = response.hasMore === undefined ? "-" : response.hasMore;
    $("#resultStatus").text("success=" + response.success + " | recordsReturned=" + records + " | hasMore=" + hasMore);

    if (!rows.length) {
      $("#resultStatus").text($("#resultStatus").text() + " | Sem registros para o filtro atual.");
    }
  }

  function openRecordWindow(row) {
    const win = $("#recordWindow").data("kendoWindow");
    const joinDrop = $("#recordJoinTable").data("kendoDropDownList");
    const container = $("#recordForm");
    const metaByName = state.fields.reduce((acc, field) => {
      acc[field.name] = field;
      return acc;
    }, {});

    state.currentRecordRow = row || {};
    state.currentRecordJoinFieldOptions = {};

    if (joinDrop) {
      joinDrop.setDataSource([]);
      joinDrop.value("");
      joinDrop.enable(false);
    }

    function renderRecordFormContent(rowData, rowJoinOptions) {
      const keys = Object.keys(rowData || {});
      container.empty();
      keys
        .filter((fieldName) => {
          if (typeof fieldName !== "string") return false;
          if (!fieldName) return false;
          if (fieldName.startsWith("_")) return false;
          if (fieldName === "uid" || fieldName === "dirty" || fieldName === "__index" || fieldName === "editable") return false;
          return true;
        })
        .filter((fieldName) => {
          return !!metaByName[fieldName];
        })
        .sort((a, b) => {
          const aOrder = metaByName[a] ? metaByName[a].__seq || 0 : 9999;
          const bOrder = metaByName[b] ? metaByName[b].__seq || 0 : 9999;
          return aOrder - bOrder;
        })
        .forEach(function (fieldName) {
          const fieldMeta = metaByName[fieldName] || {};
          const value = rowData[fieldName];
          const longText = isLongTextField(fieldMeta, value);
          const cls = longText ? "record-field full-row" : "record-field";
          const joinButton = getRecordFieldJoinButton(fieldName, value, rowJoinOptions[fieldName]);

          const wrapper = $("<div class='" + cls + "'></div>");
          const label = $("<label></label>").text(fieldMeta.label || fieldName);
          const labelRow = $("<div class='record-field-title-row'></div>");
          if (joinButton) {
            labelRow.append(joinButton);
          }
          labelRow.append(label);
          const input = $("<input type=\"text\" readonly />");
          input.val(value == null ? "" : String(value));
          input.addClass("record-field-input");
          wrapper.append(labelRow, input);
          container.append(wrapper);
          applyRecordFieldWidget(input, fieldMeta);
        });
    }

    discoverForeignKeys(function () {
      const rowJoinOptions = buildRecordJoinOptionsByField(row || {});
      state.currentRecordJoinFieldOptions = rowJoinOptions;
      renderRecordFormContent(row || {}, rowJoinOptions);
      $("#recordInfo").text("Tabela: " + state.selectedDatabase + "." + state.selectedTable);
      populateRecordJoinDropdown(true);
      win.center().open();
      enforceRecordWindowMaximized(win);
      requestAnimationFrame(function () {
        enforceRecordWindowMaximized(win);
      });
      if (typeof win.maximize === "function") {
        win.maximize();
      }
    });
  }

  function populateRecordJoinDropdown(shouldAutoOpenSingle) {
    const joinDrop = $("#recordJoinTable").data("kendoDropDownList");
    if (!joinDrop) return;
    const row = state.currentRecordRow || {};

    const options = buildRecordJoinOptions(row);
    state.currentRecordJoinOptions = options;
    const hasOptions = options.length > 0;
    const dropdownLabel = hasOptions ? `Tabelas de relacionamento (${options.length})` : "Sem relacionamento disponível";

    const data = options.slice();

    joinDrop.setDataSource(data);
    joinDrop.setOptions({ optionLabel: dropdownLabel });
    joinDrop.value("");
    joinDrop.enable(hasOptions);
    joinDrop.refresh();

    if (!hasOptions) {
      return;
    }

    if (shouldAutoOpenSingle && options.length === 1) {
      const first = options[0];
      if (first && first.hasValue) {
        joinDrop.value(first.value);
        openRelatedRecordWindow(first);
        joinDrop.value("");
      } else if (first && !first.hasValue) {
        setFooterStatus("Registro atual sem valor para " + first.localField + ", filtro de join nao pode ser aplicado.", "error");
      }
    }
  }

  function getRecordFieldJoinButton(fieldName, value, joinOptions) {
    if (!fieldName || !Array.isArray(joinOptions) || !joinOptions.length) {
      return null;
    }
    const hasValue = joinOptions.some((item) => item && item.hasValue);
    if (!hasValue) {
      return null;
    }
    const btn = $("<button type='button' class='k-button k-button-sm record-join-field-btn' />");
    btn.text("Relacionar");
    btn.attr("data-field", fieldName);
    if (value === undefined || value === null || String(value).trim() === "") {
      btn.prop("disabled", true);
      btn.attr("title", "Campo sem valor para abrir relacionamento");
    } else {
      btn.attr("title", "Abrir registros relacionados deste campo");
    }
    return btn;
  }

  function onRecordJoinFieldButtonClick(event) {
    const btn = $(event.currentTarget);
    const fieldName = String(btn.data("field") || "").trim();
    if (!fieldName) return;
    const options = (state.currentRecordJoinFieldOptions && state.currentRecordJoinFieldOptions[fieldName]) || [];
    openRecordFieldJoinOptions(options, fieldName);
  }

  function openRecordFieldJoinOptions(options, fieldName) {
    if (!options || !options.length) {
      setFooterStatus("Campo sem relacionamento associado.", "error");
      return;
    }
    const withValue = options.filter((item) => item && item.hasValue);
    if (withValue.length === 0) {
      setFooterStatus("Campo sem valor para aplicar relacionamento.", "error");
      return;
    }
    if (withValue.length === 1) {
      openRelatedRecordWindow(withValue[0]);
      return;
    }

    const joinDrop = $("#recordJoinTable").data("kendoDropDownList");
    if (!joinDrop) {
      setFooterStatus("Controle de relacionamento indisponivel.", "error");
      return;
    }
    const payloadOptions = withValue.slice(0);
    state.currentRecordJoinOptions = payloadOptions;
    joinDrop.setDataSource(payloadOptions);
    joinDrop.setOptions({
      optionLabel: fieldName ? `Relacionamentos de ${fieldName}` : "Relacionamentos"
    });
    joinDrop.value("");
    joinDrop.enable(true);
    joinDrop.refresh();
    if (typeof joinDrop.open === "function") {
      joinDrop.open();
    }
  }

  function buildRecordJoinOptionsByField(row) {
    const rowData = row || {};
    const grouped = {};
    const options = buildRecordJoinOptions(rowData);
    options.forEach(function (option) {
      if (!option || !option.localField) {
        return;
      }
      if (!grouped[option.localField]) {
        grouped[option.localField] = [];
      }
      grouped[option.localField].push(option);
    });
    return grouped;
  }

  function buildRecordJoinOptions(row) {
    const mapByKey = {};
    const candidateRows = Array.isArray(state.foreignKeys) ? state.foreignKeys : [];
    const options = [];

    candidateRows.forEach(function (fk) {
      if (!fk) return;
      if ((fk.relationStatus || "").toLowerCase() !== "encontrada") return;
      if (!fk.foreignTable) return;
      const localField = fk.localField || "";
      const foreignField = fk.localToForeignField || "";
      if (!localField || !foreignField) return;

      const key = `${fk.foreignDatabase || state.selectedDatabase}|${fk.foreignTable}|${localField}|${foreignField}`;
      if (mapByKey[key]) return;
      mapByKey[key] = true;

      const localValue = row[localField];
      const hasValue = localValue !== null && localValue !== undefined && String(localValue).trim() !== "";
      const db = fk.foreignDatabase || state.selectedDatabase;
      const tableLabel = db + "." + fk.foreignTable;
      const suffix = hasValue ? "" : " (sem valor no registro atual)";

      options.push({
        value: key,
        text: `${tableLabel} - ${localField} → ${foreignField}${suffix}`,
        localField,
        foreignField,
        foreignTable: fk.foreignTable,
        foreignDatabase: db,
        localValue,
        hasValue
      });
    });

    return options;
  }

  function onRecordJoinTableChanged() {
    const joinDrop = $("#recordJoinTable").data("kendoDropDownList");
    if (!joinDrop) return;
    const value = String(joinDrop.value() || "");
    if (!value) return;

    const option = (state.currentRecordJoinOptions || []).find((item) => item.value === value);
    joinDrop.value("");
    if (!option) return;
    if (!option.hasValue) {
      setFooterStatus("Registro atual sem valor para " + option.localField + ", filtro de join nao pode ser aplicado.", "error");
      return;
    }
    openRelatedRecordWindow(option);
  }

  function openRelatedRecordWindow(option) {
    if (!option || !option.foreignTable) {
      setFooterStatus("Relacionamento invalido para abrir registros relacionados.", "error");
      return;
    }
    const value = option.localValue;
    if (value === null || value === undefined || String(value).trim() === "") {
      setFooterStatus("Nao foi informado valor para " + option.localField, "error");
      return;
    }

    const relatedWin = $("#relatedRecordWindow").data("kendoWindow");
    const relatedGrid = $("#relatedRecordGrid").data("kendoGrid");

    $("#relatedRecordInfo").text("Relacionamento: " + state.selectedDatabase + "." + state.selectedTable + "." + option.localField + " = " + option.foreignDatabase + "." + option.foreignTable + "." + option.foreignField);

    const basePayload = {
      execution: "sync",
      page: 1,
      pageSize: 200,
      sources: [{
        nome: option.foreignTable,
        alias: "f",
        banco: option.foreignDatabase,
        campos: ""
      }],
      filters: [{
        sourceAlias: "f",
        field: option.foreignField,
        operator: "=",
        value: String(value)
      }],
      joins: [],
      orderBy: [],
      pipeline: []
    };

    setFooterStatus("Carregando metadados da tabela " + option.foreignTable + "...", "");

    getJsonUtf8(state.apiBase + "/metadata/tables/" + encodeURIComponent(option.foreignTable) + "/fields?database=" + encodeURIComponent(option.foreignDatabase))
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        const fields = (response.fields || response.data || []).map((field, index) => ({
          ...field,
          __seq: index
        }));

        const columns = fields.length
          ? fields.map((field) => ({
              field: field.name,
              title: field.label || field.name,
              width: Math.min(Math.max(160, (field.label || field.name).length * 8), 280)
            }))
          : [{ field: "_noData", title: "Sem metadados" }];

        basePayload.sources[0].campos = fields.map((field) => field.name).join(",") || "*";
        relatedGrid.setOptions({ columns: columns });

        const filteredPayload = Object.assign({}, basePayload);
        relatedGrid.dataSource.data([]);

        $.ajax({
          url: state.apiBase + "/query",
          method: "POST",
          contentType: "application/json",
          dataType: "json",
          data: JSON.stringify(filteredPayload)
        })
          .done(function (response) {
            if (!response || response.success === false) {
              const error = response && response.error ? response.error : { message: "Erro da API" };
              setFooterStatus(error.message || "Erro", "error");
              relatedGrid.dataSource.data([]);
              return;
            }

            const rows = response.data || [];
            relatedGrid.dataSource.data(rows);
            relatedWin.center().open();
            enforceRecordWindowMaximized(relatedWin);
            requestAnimationFrame(function () {
              enforceRecordWindowMaximized(relatedWin);
            });
            if (typeof relatedWin.maximize === "function") {
              relatedWin.maximize();
            }
            setFooterStatus("Relacionamento carregado. Registros: " + (response.recordsReturned || rows.length), "ok");
          })
          .fail(function (xhr) {
            const msg = "Falha na consulta relacionada: " + xhr.status + " " + xhr.statusText;
            setFooterStatus(msg, "error");
            relatedGrid.dataSource.data([]);
          });
      })
      .fail(function (xhr) {
        const msg = "Erro ao carregar metadados da tabela relacionada: " + xhr.status + " " + xhr.statusText;
        setFooterStatus(msg, "error");
      });
  }

  function enforceRecordWindowMaximized(win) {
    if (!win || !win.wrapper) return;
    try {
      if (typeof win.restore === "function") {
        win.restore();
      }
      win.wrapper.css({
        top: 0,
        left: 0,
        width: "100vw",
        height: "100vh",
        maxWidth: "100vw",
        maxHeight: "100vh"
      });
      win.element.css("height", "calc(100vh - 84px)");
      if (typeof win.maximize === "function") {
        win.maximize();
      }
    } catch (_) {}
  }

  function normalizeDateFieldValue(raw) {
    if (raw === null || raw === undefined) return null;
    const value = String(raw).trim();
    if (!value) return null;
    const asDate = new Date(value);
    return isNaN(asDate.getTime()) ? null : asDate;
  }

  function applyRecordFieldWidget(input, fieldMeta) {
    if (!input || !input.length) return;
    const type = String(fieldMeta.type || "").toLowerCase();
    const format = String(fieldMeta.format || "").toLowerCase();
    const ext = String(fieldMeta.extendedType || fieldMeta.extType || "").toLowerCase();
    const rawValue = input.val();
    const isDate = /(^|[_-]|\.)(date|datetime|timestamp|time)/.test(type) || /(^|[_-]|\.)(date|datetime|timestamp|time)/.test(format) || /(^|[_-]|\.)(date|datetime|timestamp|time)/.test(ext);
    const isNumeric = /(integer|int|decimal|numeric|number|float|double|currency|money|packed|long|short|byte)/.test(type) ||
      /(integer|int|decimal|numeric|number|float|double|currency|money|packed|long|short|byte)/.test(format) ||
      /(integer|int|decimal|numeric|number|float|double|currency|money|packed|long|short|byte)/.test(ext);

    if (isDate && typeof input.kendoDatePicker === "function") {
      const date = normalizeDateFieldValue(rawValue);
      input.val("");
      input.kendoDatePicker({
        value: date,
        format: "dd/MM/yyyy",
        parseFormats: ["yyyy-MM-dd", "dd/MM/yyyy", "yyyy-MM-ddTHH:mm:ss", "yyyy/MM/dd"]
      });
      const widget = input.data("kendoDatePicker");
      if (widget) {
        widget.readonly(true);
      }
      return;
    }

    if (isNumeric && typeof input.kendoNumericTextBox === "function") {
      const decimal = /decimal|numeric|float|double|currency|money/.test(type);
      const value = Number(rawValue);
      input.kendoNumericTextBox({
        value: Number.isFinite(value) ? value : null,
        decimals: decimal ? 2 : 0,
        spinners: false,
        format: decimal ? "n2" : "n0"
      });
      const numericWidget = input.data("kendoNumericTextBox");
      if (numericWidget) {
        numericWidget.readonly(true);
      }
      return;
    }

    if (!input.data("kendoTextBox")) {
      input.kendoTextBox();
    }

    const textWidget = input.data("kendoTextBox");
    if (textWidget) {
      textWidget.readonly(true);
    }
  }

  function isLongTextField(meta, value) {
    if ((meta.type || "").toLowerCase() !== "character") return false;
    const format = String(meta.format || "");
    const match = /x\((\d+)\)/i.exec(format);
    if (match && Number(match[1]) > 50) return true;
    if (typeof value === "string" && value.length > 50) return true;
    return false;
  }

  function setStatus(message, kind) {
    const status = $("#stepStatus");
    status.removeClass("ok error").addClass(kind || "").text(message);
  }

  function setFooterStatus(message, kind) {
    const status = $("#footerStatus");
    status.removeClass("ok error").addClass(kind || "").text(message);
  }

  function apiError(response) {
    return response && response.error ? (response.error.message || response.error.code || "erro") : "erro desconhecido";
  }

  function escapeHtml(value) {
    const text = String(value == null ? "" : value);
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function normalizeTabId(value) {
    return "tab-" + String(value || "indice")
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9\-_]/gi, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
  }

  function refreshContextUi() {
    const environment = currentEnvironment();
    const client = currentClient();
    const companies = companiesForCurrentEnvironment();
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    const selectedCompany = currentCompany() || companies[0] || null;

    if (environment && environment.pasoeBaseUrl) {
      state.apiBase = String(environment.pasoeBaseUrl || "").replace(/\/+$/, "");
      $("#apiBaseUrl").val(state.apiBase);
      localStorage.setItem("sursumApiBaseUrl", state.apiBase);
    }

    if (companyCombo) {
      companyCombo.setDataSource(new kendo.data.DataSource({ data: companies }));
      companyCombo.value(selectedCompany ? selectedCompany.id : "");
    }

    $("#contextSummary").text(
      client && environment
        ? ((client.name || client.id) + " / " + (environment.name || environment.id))
        : "Selecione o contexto na pagina inicial."
    );
  }

  function onCompanyChanged() {
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    const companyId = companyCombo ? String(companyCombo.value() || "") : "";
    const client = currentClient();
    const environment = currentEnvironment();
    if (client && environment && window.SursumContext && typeof window.SursumContext.setSelection === "function") {
      window.SursumContext.setSelection(client.id, environment.id, companyId || "");
    }
    refreshContextUi();
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

  function currentCompany() {
    if (window.SursumContext && typeof window.SursumContext.getCurrentCompany === "function") {
      return window.SursumContext.getCurrentCompany();
    }
    return null;
  }

  function companiesForCurrentEnvironment() {
    const environment = currentEnvironment();
    if (!environment) {
      return [];
    }
    if (window.SursumContext && typeof window.SursumContext.getCompaniesForEnvironment === "function") {
      return window.SursumContext.getCompaniesForEnvironment(environment.id) || [];
    }
    if (window.SursumContext && typeof window.SursumContext.getConfig === "function") {
      const config = window.SursumContext.getConfig();
      return (config.companies || []).filter(function (item) {
        return item.environmentId === environment.id;
      });
    }
    return [];
  }
})();


