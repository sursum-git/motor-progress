(function () {
  const QUERY_COMPANY_KEY = "sursumQueryCompanyId";
  const METADATA_PROXY = "metadata-pasoe.php";
  const PASOE_PROXY = "pasoe-proxy.php";
  const TABLE_CACHE_PREFIX = "sursumQueryWizardTableCache:v2:";

  const state = {
    apiBase: initialApiBase(),
    currentStep: 1,
    databases: [{ name: "TODOS", logicalName: "TODOS", displayName: "TODOS" }],
    selectedDatabase: "",
    selectedTable: "",
    tables: [],
    tableCache: {},
    tableSearchRows: [],
    fields: [],
    fieldsByName: {},
    indexDescriptions: {},
    fieldOptionLookup: {},
    foreignKeys: [],
    filterRows: [],
    currentRecordRow: null,
    currentRecordJoinFieldOptions: {},
    currentRecordJoinOptions: [],
    foreignKeyCache: {},
    foreignDescriptionCache: {},
    foreignDescriptionValues: {},
    activeFilterId: 1,
    loadedDatabaseApiBase: "",
    tableLoading: {}
  };

  function initialApiBase() {
    if (window.SursumContext && typeof SursumContext.getCurrentApiBase === "function") {
      const apiBase = SursumContext.getCurrentApiBase();
      if (apiBase) return String(apiBase).replace(/\/+$/, "");
    }
    if (window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function") {
      const environment = SursumContext.getCurrentEnvironment();
      if (environment && environment.pasoeBaseUrl) return String(environment.pasoeBaseUrl).replace(/\/+$/, "");
    }
    return localStorage.getItem("sursumApiBaseUrl") || "http://localhost:8890/web/SursumDynamicQuery";
  }

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

  const INDEX_KIND_OVERRIDES = {
    "ems2med|ped-venda|ch-pedseq": "primary",
    "ems2med|ped-venda|ch-pedido": "unique"
  };

  $(init);

  function init() {
    initWidgets();
    refreshContextUi();
    bindEvents();
    window.addEventListener("sursum:context-changed", onSursumContextChanged);
    showStep(1);
    if (window.SursumUiReady) window.SursumUiReady();
    loadDatabasesWhenContextReady(false, function () {
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
    $("#queryPageSize").kendoNumericTextBox({ format: "n0", min: 1, max: 10000, value: 500, decimals: 0 });
    $("#queryGridPageSize").kendoNumericTextBox({ format: "n0", min: 1, max: 1000, value: 50, decimals: 0 });

    $("#tableSearchText").kendoTextBox();

    $("#tableSearchWindow").kendoWindow({
      title: "Buscar tabela",
      width: "860px",
      height: "600px",
      visible: false,
      modal: true,
      animation: false
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
        { field: "foreignDescriptionField", title: "Campo descricao", width: 180 },
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
      pageable: { buttonCount: 5, pageSize: Number($("#queryGridPageSize").val()) || 50 },
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
      loadDatabasesWhenContextReady(true, function () {
        setStatus("Metadados atualizados.", "ok");
      });
    });

    $("#openTableSearch").on("click", openTableSearch);
    $("#applyTableSearch").on("click", applyTableSearch);
    $("#refreshTableSearch").on("click", forceRefreshTableSearch);
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
      $("#tableSearchWindow").data("kendoWindow").close();
      showStep(2);
      applySelectedTableFromStepSearch();
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
      clearIndexFilterError(el.closest(".index-filter-item"));
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

  function loadDatabases(forceSync, done) {
    if (typeof forceSync === "function") {
      done = forceSync;
      forceSync = false;
    }
    refreshContextUi();
    setStatus(forceSync ? "Sincronizando cadastro de bancos..." : "Carregando cadastro de bancos...", "");
    getJsonUtf8(metadataUrl(forceSync ? "/metadata/databases/sync" : "/metadata/database-catalog"))
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
        state.loadedDatabaseApiBase = state.apiBase;
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

  function loadDatabasesWhenContextReady(forceSync, done) {
    const ready = window.SursumContext && typeof window.SursumContext.whenReady === "function"
      ? window.SursumContext.whenReady()
      : Promise.resolve();

    ready.then(function () {
      refreshContextUi();
      loadDatabases(forceSync, done);
    });
  }

  function onSursumContextChanged() {
    const previousApiBase = state.apiBase;
    refreshContextUi();
    if (state.apiBase && state.apiBase !== previousApiBase && state.loadedDatabaseApiBase !== state.apiBase) {
      loadDatabases(false);
    }
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
      if (typeof done === "function") done(true, true);
      return;
    }

    const cached = readTableCache(database);
    if (cached) {
      state.tables = cached;
      state.tableCache[database] = cached;
      if (typeof done === "function") done(true, true);
      return;
    }

    if (state.tableLoading[database]) {
      state.tableLoading[database].push(done);
      return;
    }
    state.tableLoading[database] = [done];

    if (database === "TODOS") {
      loadAllTables(function (success) {
        finishTableLoad(database, success !== false, false);
      });
      return;
    }

    let path = "/metadata/tables";
    if (database && database !== "TODOS") {
      path += "?database=" + encodeURIComponent(database);
    }

    loadTablesFromMetadataStore(database)
      .then(function (localRows) {
        if (Array.isArray(localRows) && localRows.length) {
          return { success: true, data: localRows, __sqlite: true };
        }
        return getJsonUtf8(metadataUrl(path));
      })
      .done(function (response) {
        const rows = response && response.success === false ? [] : (response.data || []);
        state.tables = normalizeTableRows(rows, database);
        state.tableCache[database] = state.tables;
        writeTableCache(database, state.tables);
        finishTableLoad(database, true, false);
      })
      .fail(function () {
        state.tables = [];
        finishTableLoad(database, false, false);
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
      const path = "/metadata/tables?database=" + encodeURIComponent(dbName);
      loadTablesFromMetadataStore(dbName)
        .then(function (localRows) {
          if (Array.isArray(localRows) && localRows.length) {
            return { success: true, data: localRows, __sqlite: true };
          }
          return getJsonUtf8(metadataUrl(path));
        })
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
            writeTableCache("TODOS", merged);
            if (typeof done === "function") done(hasFailure ? false : true);
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
      cache: false,
      beforeSend: function (xhr) {
        if (xhr && typeof xhr.overrideMimeType === "function") {
          xhr.overrideMimeType("application/json; charset=UTF-8");
        }
      }
    });
  }

  function loadTablesFromMetadataStore(database) {
    const deferred = $.Deferred();
    const scope = currentScope();
    getJsonUtf8("metadata-store.php?resource=tables"
      + "&environmentId=" + encodeURIComponent(scope.environmentId || "")
      + "&companyId=" + encodeURIComponent(scope.companyId || "")
      + "&database=" + encodeURIComponent(database || ""))
      .done(function (response) {
        deferred.resolve(response && response.success && Array.isArray(response.data) ? response.data : []);
      })
      .fail(function () {
        deferred.resolve([]);
      });
    return deferred.promise();
  }

  function loadFieldsFromMetadataStore(table, database) {
    const deferred = $.Deferred();
    const scope = currentScope();
    getJsonUtf8("metadata-store.php?resource=fields"
      + "&environmentId=" + encodeURIComponent(scope.environmentId || "")
      + "&companyId=" + encodeURIComponent(scope.companyId || "")
      + "&database=" + encodeURIComponent(database || "")
      + "&table=" + encodeURIComponent(table || ""))
      .done(function (response) {
        deferred.resolve(response && response.success && Array.isArray(response.data) ? response.data : []);
      })
      .fail(function () {
        deferred.resolve([]);
      });
    return deferred.promise();
  }

  function finishTableLoad(database, success, fromCache) {
    const callbacks = state.tableLoading[database] || [];
    delete state.tableLoading[database];
    callbacks.forEach(function (callback) {
      if (typeof callback === "function") callback(success, fromCache);
    });
  }

  function tableCacheKey(database) {
    const scope = currentScope();
    return TABLE_CACHE_PREFIX + [
      String(state.apiBase || "").replace(/\/+$/, ""),
      scope.companyId || "",
      database || "TODOS"
    ].join("|");
  }

  function readTableCache(database) {
    try {
      const raw = localStorage.getItem(tableCacheKey(database));
      if (!raw) return null;
      const payload = JSON.parse(raw);
      if (!payload || !Array.isArray(payload.rows)) return null;
      return payload.rows;
    } catch (_) {
      return null;
    }
  }

  function writeTableCache(database, rows) {
    try {
      localStorage.setItem(tableCacheKey(database), JSON.stringify({
        savedAt: Date.now(),
        rows: Array.isArray(rows) ? rows : []
      }));
    } catch (_) {}
  }

  function clearTableCache(database) {
    try {
      localStorage.removeItem(tableCacheKey(database));
    } catch (_) {}
    delete state.tableCache[database];
    if (database === "TODOS") {
      Object.keys(state.tableCache).forEach(function (key) {
        delete state.tableCache[key];
      });
      const prefix = TABLE_CACHE_PREFIX + String(state.apiBase || "").replace(/\/+$/, "") + "|" + (currentScope().companyId || "") + "|";
      for (let index = localStorage.length - 1; index >= 0; index--) {
        const key = localStorage.key(index);
        if (key && key.indexOf(prefix) === 0) {
          localStorage.removeItem(key);
        }
      }
    }
  }

  function metadataUrl(path) {
    const scope = currentScope();
    if (scope.environmentId && scope.companyId) {
      return METADATA_PROXY
        + "?environmentId=" + encodeURIComponent(scope.environmentId)
        + "&companyId=" + encodeURIComponent(scope.companyId)
        + "&path=" + encodeURIComponent(path);
    }
    return pasoeUrl(path);
  }

  function pasoeUrl(path, options) {
    const target = pasoeDirectUrl(path, options);
    return shouldUsePasoeProxy(target) ? PASOE_PROXY + "?target=" + encodeURIComponent(target) : target;
  }

  function pasoeDirectUrl(path, options) {
    const base = String(state.apiBase || "").replace(/\/+$/, "");
    const suffix = String(path || "").replace(/^\/+/, "");
    let target = base + "/" + suffix;
    if (window.SursumContext && typeof window.SursumContext.getRequestConfig === "function") {
      const request = window.SursumContext.getRequestConfig(target, options || {});
      target = request && request.url ? request.url : target;
    }
    return target;
  }

  function shouldUsePasoeProxy(url) {
    try {
      const parsed = new URL(url, window.location.href);
      return /^https?:$/.test(parsed.protocol) && parsed.origin !== window.location.origin;
    } catch (_) {
      return false;
    }
  }

  function currentScope() {
    const environment = currentEnvironment();
    const company = currentCompany();
    return {
      environmentId: environment && environment.id ? environment.id : "",
      companyId: company && company.id ? company.id : ""
    };
  }

  function normalizeTableRows(rows, defaultDatabase) {
    return (rows || []).map((item) => {
      const name = item.name || item.table || item.tableName || item.dumpName || "";
      return {
        name,
        label: item.label || item.description || item.descricao || name,
        dumpName: item.dumpName || item.dump_name || "",
        database: item.database || item.databaseName || item.logicalName || defaultDatabase || state.selectedDatabase
      };
    }).filter(function (item) {
      return item.name;
    });
  }

  function openTableSearch() {
    const db = state.selectedDatabase || "TODOS";
    const win = $("#tableSearchWindow").data("kendoWindow");
    win.setOptions({ title: "Buscar tabela em " + db });
    win.center().open();
    if (!$("#tableSearchText").val()) {
      $("#tableSearchText").val("");
    }
    $("#tableSearchText").trigger("focus");
    setTableSearchLoading(true);
    loadTablesForDatabase(db, function (success, fromCache) {
      applyTableSearch();
      setTableSearchLoading(false);
      if (success === false) {
        setFooterStatus("Falha ao carregar tabelas para " + db + ".", "error");
      } else if (fromCache) {
        setFooterStatus("Tabelas carregadas do cache local para " + db + ".", "ok");
      } else {
        setFooterStatus("Tabelas carregadas para " + db + ".", "ok");
      }
    });
  }

  function forceRefreshTableSearch() {
    const db = state.selectedDatabase || "TODOS";
    clearTableCache(db);
    setTableSearchLoading(true);
    setFooterStatus("Atualizando lista de tabelas de " + db + "...", "");
    loadTablesForDatabase(db, function (success) {
      applyTableSearch();
      setTableSearchLoading(false);
      setFooterStatus(success === false ? "Falha ao atualizar tabelas para " + db + "." : "Lista de tabelas atualizada para " + db + ".", success === false ? "error" : "ok");
    });
  }

  function setTableSearchLoading(active) {
    const target = $("#tableSearchWindow");
    if (window.kendo && kendo.ui && typeof kendo.ui.progress === "function") {
      kendo.ui.progress(target, !!active);
    }
    $("#applyTableSearch,#refreshTableSearch,#cancelTableSearch").prop("disabled", !!active);
  }

  function setFieldsLoading(active) {
    const target = $("[data-step-panel='2']");
    if (window.kendo && kendo.ui && typeof kendo.ui.progress === "function") {
      kendo.ui.progress(target, !!active);
    }
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
    state.fieldOptionLookup = {};
    state.foreignKeys = [];
    state.foreignKeyCache = {};
    state.foreignDescriptionValues = {};
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

    state.currentRecordJoinOptions = [];
    state.currentRecordRow = null;

    if (!state.selectedDatabase || state.selectedDatabase === "TODOS") {
      loadTablesForDatabase("TODOS", function () {
        const rows = state.tableCache.TODOS || state.tables || [];
        const matches = rows.filter(function (row) {
          return String(row.name || "").toLowerCase() === tableName.toLowerCase();
        });
        const uniqueMatches = uniqueTableDatabaseMatches(matches);

        if (!uniqueMatches.length) {
          setFooterStatus("A tabela informada não foi encontrada em nenhum banco.", "error");
          return;
        }
        if (uniqueMatches.length > 1) {
          const databaseNames = uniqueMatches.map(function (row) {
            return row.database || "sem banco";
          }).join(", ");
          setFooterStatus("Informe o banco para a tabela " + tableName + ". Ela existe em: " + databaseNames + ".", "error");
          return;
        }

        const found = uniqueMatches[0];
        state.selectedDatabase = found.database || "";
        state.selectedTable = found.name;
        const combo = $("#databaseCombo").data("kendoComboBox");
        if (combo) combo.value(state.selectedDatabase);
        applySelectedTableFromStepSearch();
      });
      return;
    }

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

  function uniqueTableDatabaseMatches(rows) {
    const seen = {};
    const result = [];
    (rows || []).forEach(function (row) {
      const key = String(row.database || "").toLowerCase() + "|" + String(row.name || "").toLowerCase();
      if (seen[key]) return;
      seen[key] = true;
      result.push(row);
    });
    return result;
  }

  function applySelectedTableFromStepSearch(done) {
    $("#selectedTable").val(state.selectedTable || "");
    state.fields = [];
    state.fieldOptionLookup = {};
    state.foreignKeys = [];
    state.foreignKeyCache = {};
    state.foreignDescriptionValues = {};
    state.filterRows = [];
    refreshFilterGrid();
    clearFilterTabs();
    setFieldsLoading(true);
    ensureTableFields(function () {
      setFieldsLoading(false);
      loadFilterTabs();
      if (typeof done === "function") {
        done();
      }
    });
    setStepSourceInfo();
    setFooterStatus("Tabela validada. Carregando campos e indices: " + state.selectedTable, "ok");
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
    state.fieldOptionLookup = {};
    state.foreignDescriptionValues = {};
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
        state.foreignDescriptionValues = {};
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

    setFieldsLoading(true);
    setStatus("Carregando metadados de campos de " + state.selectedDatabase + "." + state.selectedTable + "...", "");
    loadFieldsFromMetadataStore(state.selectedTable, state.selectedDatabase)
      .then(function (localRows) {
        if (Array.isArray(localRows) && localRows.length) {
          return { success: true, data: localRows, __sqlite: true };
        }
        return getJsonUtf8(metadataUrl("/metadata/tables/" + encodeURIComponent(state.selectedTable) + "/fields?database=" + encodeURIComponent(state.selectedDatabase)));
      })
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
        state.fieldOptionLookup = buildFieldOptionLookup(state.fields);
        state.foreignKeys = [];
        state.foreignKeyCache = {};
        state.foreignDescriptionValues = {};
        refreshFilterDynamicSelectors();
        setStatus("Campos carregados: " + state.fields.length, "ok");
        state.filterRows = [];
        refreshFilterGrid();
        loadIndexMetadata(function () {
          buildFilterTabs(state.fields);
          setFieldsLoading(false);
          if (typeof done === "function") done();
        });
      })
      .fail(function (xhr) {
        setFieldsLoading(false);
        const msg = xhr && (xhr.responseText || xhr.statusText) ? ("Erro " + (xhr.status || "") + " " + (xhr.responseText || xhr.statusText)) : "Erro desconhecido";
        setStatus("Falha ao carregar campos: " + msg, "error");
      });
  }

  function loadIndexMetadata(done) {
    state.indexDescriptions = {};
    const scope = currentScope();
    const url = "metadata-store.php?resource=indices"
      + "&environmentId=" + encodeURIComponent(scope.environmentId || "")
      + "&companyId=" + encodeURIComponent(scope.companyId || "")
      + "&database=" + encodeURIComponent(state.selectedDatabase || "")
      + "&table=" + encodeURIComponent(state.selectedTable || "");
    getJsonUtf8(url)
      .done(function (response) {
        const rows = response && response.success && Array.isArray(response.data) ? response.data : [];
        rows.forEach(function (row) {
          const name = String(row.name || row.indexName || "").toLowerCase();
          const description = String(row.description || "").trim();
          if (name && description) state.indexDescriptions[name] = description;
        });
      })
      .always(function () {
        if (typeof done === "function") done();
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

    loadOfRelationsForCurrentTable().then(function (ofRows) {
      const directRows = (ofRows || []).map(mapRelationOfToForeignKey).filter(Boolean);
      return Promise.all(refs.map(loadRelationForForeignTable)).then(function (expressionRows) {
        return mergeForeignKeyRows(directRows.concat(expressionRows.filter(Boolean)));
      });
    }).then(function (rows) {
      state.foreignKeys = rows;
      state.foreignKeyCache[cacheKey] = state.foreignKeys;
      if (typeof done === "function") done();
    }).catch(function () {
      state.foreignKeys = refs.length ? refs : [];
      state.foreignKeyCache[cacheKey] = state.foreignKeys;
      if (typeof done === "function") done();
    });
  }

  function loadOfRelationsForCurrentTable() {
    return new Promise(function (resolve) {
      if (!state.selectedTable || !state.selectedDatabase || state.selectedDatabase === "TODOS") {
        resolve([]);
        return;
      }
      getJsonUtf8(metadataUrl("/metadata/relations/of?table=" + encodeURIComponent(state.selectedTable) + "&database=" + encodeURIComponent(state.selectedDatabase)))
        .done(function (response) {
          const rows = response && response.success !== false && Array.isArray(response.data) ? response.data : [];
          resolve(rows);
        })
        .fail(function () {
          resolve([]);
        });
    });
  }

  function mapRelationOfToForeignKey(item) {
    if (!item) return null;
    const localTable = state.selectedTable;
    const localDatabase = state.selectedDatabase;
    const leftMatches = sameName(item.leftTable, localTable);
    const rightMatches = sameName(item.rightTable, localTable);
    if (!leftMatches && !rightMatches) return null;

    if (leftMatches) {
      return {
        relationStatus: "Encontrada",
        source: item.source || "OF",
        localDatabase: item.leftDatabase || localDatabase,
        localTable,
        localField: item.leftField || "",
        localLabel: item.leftField || "",
        foreignDatabase: item.rightDatabase || localDatabase,
        foreignTable: item.rightTable || "",
        localToForeignField: item.rightField || "",
        relationPath: item.updatedAt || item.path || item.fileName || "",
        foreignDescriptionField: item.descriptionField || ""
      };
    }

    return {
      relationStatus: "Encontrada",
      source: item.source || "OF",
      localDatabase: item.rightDatabase || localDatabase,
      localTable,
      localField: item.rightField || "",
      localLabel: item.rightField || "",
      foreignDatabase: item.leftDatabase || localDatabase,
      foreignTable: item.leftTable || "",
      localToForeignField: item.leftField || "",
      relationPath: item.updatedAt || item.path || item.fileName || "",
      foreignDescriptionField: item.descriptionField || ""
    };
  }

  function mergeForeignKeyRows(rows) {
    const seen = {};
    return (rows || []).filter(function (row) {
      if (!row || !row.localField || !row.foreignTable || !row.localToForeignField) return false;
      const key = [
        row.localDatabase || state.selectedDatabase,
        row.localTable || state.selectedTable,
        row.localField,
        row.foreignDatabase || state.selectedDatabase,
        row.foreignTable,
        row.localToForeignField
      ].map(function (part) {
        return String(part || "").toLowerCase();
      }).join("|");
      if (seen[key]) return false;
      seen[key] = true;
      return true;
    });
  }

  function sameName(left, right) {
    return String(left || "").toLowerCase() === String(right || "").toLowerCase();
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
        candidate.foreignDescriptionField = rel.descriptionField || "";
        resolve(candidate);
      };

      const primary = metadataUrl("/metadata/relations/" + encodeURIComponent(localTable) + "/" + encodeURIComponent(foreignTable) +
        "?leftDatabase=" + encodeURIComponent(database) + "&rightDatabase=" + encodeURIComponent(database));
      const secondary = metadataUrl("/metadata/relations/" + encodeURIComponent(foreignTable) + "/" + encodeURIComponent(localTable) +
        "?leftDatabase=" + encodeURIComponent(database) + "&rightDatabase=" + encodeURIComponent(database));

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
      rightField: relation.rightField || "",
      descriptionField: relation.descriptionField || relation.description_field || ""
    };
  }

  function readFilterValue($input) {
    const meta = readFilterInputValue($input);
    return meta.raw;
  }

  function collectAssociatedInputs($node) {
    const candidates = [];
    function add(candidate) {
      if (candidate && candidates.indexOf(candidate) < 0) candidates.push(candidate);
    }

    if ($node.is("input, textarea, select")) add($node[0]);
    $node.closest(".index-filter-value, .index-filter-value-to").find("input, textarea, select").toArray().forEach(add);
    $node.find("input, textarea, select").toArray().forEach(add);
    $node.parent().find("input, textarea, select").toArray().forEach(add);
    $node.closest(".k-widget, .k-numerictextbox, .k-picker, .k-multiselect, .k-input").find("input, textarea, select").toArray().forEach(add);
    $node.next(".k-widget, .k-numerictextbox, .k-picker, .k-multiselect, .k-input").find("input, textarea, select").toArray().forEach(add);
    $node.prev(".k-widget, .k-numerictextbox, .k-picker, .k-multiselect, .k-input").find("input, textarea, select").toArray().forEach(add);
    return candidates;
  }

  function findAssociatedKendoWidget($node, widgetName) {
    const direct = $node.data(widgetName);
    if (direct) return direct;
    const candidates = collectAssociatedInputs($node);
    for (let i = 0; i < candidates.length; i++) {
      const widget = $(candidates[i]).data(widgetName);
      if (widget) return widget;
    }
    return null;
  }

  function readFilterInputValue($input) {
    if (!$input || !$input.length) {
      return { values: [], raw: "", rawToPayload: "", isMulti: false };
    }

    const node = $input[0];
    const $node = $(node);
    const widgetText = findAssociatedKendoWidget($node, "kendoTextBox");
    const widgetNumeric = findAssociatedKendoWidget($node, "kendoNumericTextBox");
    const widgetDate = findAssociatedKendoWidget($node, "kendoDatePicker") || findAssociatedKendoWidget($node, "kendoDateTimePicker");
    const widgetMulti = findAssociatedKendoWidget($node, "kendoMultiSelect");

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
      if (normalized) return { values: [normalized], raw: normalized, rawToPayload: normalized, isMulti: false };
    }
    if (widgetNumeric) {
      const value = widgetNumeric.value();
      const normalized = normalizeScalarFilterText(value);
      if (normalized) return { values: [normalized], raw: normalized, rawToPayload: normalized, isMulti: false };
    }
    if (widgetDate) {
      const value = widgetDate.value();
      const normalized = normalizeDateForPayload(value);
      if (normalized) return { values: [normalized], raw: normalized, rawToPayload: normalized, isMulti: false };
    }

    const cached = $node.data("filterValue");
    if (cached !== null && cached !== undefined && cached !== "") {
      const normalized = normalizeScalarFilterText(cached);
      return { values: normalized ? [normalized] : [], raw: normalized, rawToPayload: normalized, isMulti: false };
    }
    const candidates = collectAssociatedInputs($node);

    for (let i = 0; i < candidates.length; i++) {
      const value = normalizeScalarFilterText($(candidates[i]).val());
      if (value.length > 0) {
        return { values: [value], raw: value, rawToPayload: value, isMulti: false };
      }
    }

    return { values: [], raw: "", rawToPayload: "", isMulti: false };
  }

  function readFilterOperator($row) {
    const operatorWidget = $row.data("operatorWidget")
      || $row.find("input.index-filter-operator").data("kendoDropDownList")
      || $row.find(".index-filter-operator").data("kendoDropDownList");
    const direct = operatorWidget && operatorWidget.value() ? operatorWidget.value() : String($row.find("input.index-filter-operator").val() || $row.find(".index-filter-operator").val() || "").trim();
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
      showIndexFilterError(row, "Informe um valor valido para adicionar o filtro.");
      return false;
    }

    clearIndexFilterError(row);
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

  function showIndexFilterError(row, message) {
    if (!row || !row.length) return;
    row.addClass("has-error");
    row.find(".index-filter-error").text(message || "Nao foi possivel adicionar o filtro.");
  }

  function clearIndexFilterError(row) {
    if (!row || !row.length) return;
    row.removeClass("has-error");
    row.find(".index-filter-error").text("");
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
    const indexNames = sortedIndexNames(groups);
    const tabEl = $("#indexFilterTabs");

    const existing = tabEl.data("kendoTabStrip");
    if (existing) {
      existing.destroy();
      tabEl.empty();
    }
    const existingIndexSelector = $("#indexSelector").data("kendoComboBox");
    if (existingIndexSelector) {
      existingIndexSelector.destroy();
    }

    const dynamicTabId = "index-filter-dynamic-tab";
    const hasIndexes = indexNames.length > 0;
    const moveDynamicFilterSection = function () {
      const targetPanel = $("#" + dynamicTabId);
      const dynamicSection = $("#dynamicFilterSection");
      if (!targetPanel.length || !dynamicSection.length) return;
      dynamicSection.appendTo(targetPanel);
      targetPanel.addClass("active");
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
            <div class="index-filter-error" role="alert"></div>
          </div>
        `;
      }).join("");

      return {
        name,
        tabId,
        description: indexDescription(name),
        group: indexKindGroupLabel(groups[name] && groups[name].kind ? groups[name].kind : "normal"),
        kind: groups[name] && groups[name].kind ? groups[name].kind : "normal",
        html: `<section id="${tabId}" class="manual-tab-panel ${index === 0 ? "active" : ""}">
          <div class="index-tab-head">Indice: ${escapeHtml(name)}</div>
          ${rows || "<div class=\"status-box\">Sem campo com este indice.</div>"}
        </section>`
      };
    });

    const selectorHtml = hasIndexes
      ? `<div class="index-selector-shell">
          <label for="indexSelector">Índice</label>
          <input id="indexSelector" />
        </div>`
      : `<div class="status-box">Nenhum índice encontrado para esta tabela.</div>`;
    const dynamicPanel = `<section id="${dynamicTabId}" class="manual-tab-panel active dynamic-filter-panel"></section>`;
    const panels = tabs.map((tab) => tab.html).join("") + dynamicPanel;
    const manualHtml = `${selectorHtml}<div class="manual-tab-panels">${panels}</div>`;
    tabEl.html(manualHtml);

    if (hasIndexes) {
      $("#indexSelector").kendoComboBox({
        dataTextField: "displayText",
        dataValueField: "name",
        filter: "contains",
        suggest: true,
        placeholder: "Digite para filtrar índices",
        template: '#: name # # if (description) { #<span class="index-description">#: description #</span># } # # if (kindLabel) { #<span class="index-kind-badge">#: kindLabel #</span># } #',
        groupTemplate: "#= data #",
        dataSource: {
          data: tabs.map(function (tab) {
            return {
              name: tab.name,
              displayText: indexDisplayText(tab.name, tab.kind, tab.description),
              tabId: tab.tabId,
              description: tab.description,
              kind: tab.kind,
              kindLabel: indexKindText(tab.kind),
              group: tab.group
            };
          }),
          group: { field: "group" }
        },
        change: function () {
          const item = this.dataItem();
          activateIndexPanel(item && item.tabId ? item.tabId : tabs[0].tabId);
        },
        select: function (event) {
          const item = this.dataItem(event.item);
          activateIndexPanel(item && item.tabId ? item.tabId : tabs[0].tabId);
        }
      });
      const selector = $("#indexSelector").data("kendoComboBox");
      selector.value(tabs[0].name);
      selector.text(tabs[0].displayText || tabs[0].name);
      activateIndexPanel(tabs[0].tabId);
    }
    moveDynamicFilterSection();

    try {
      setFooterStatus(`Filtros por índice: ${indexNames.length} | Campos: ${fields.length}`, "");
    } catch (_) {}

    initIndexFilterWidgets(tabEl);

    return;
  }

  function indexDescription(name) {
    return state.indexDescriptions[String(name || "").toLowerCase()] || "";
  }

  function indexDisplayText(name, kind, description) {
    const parts = [name];
    if (description) {
      parts.push(description);
    } else if (kind === "primary") {
      parts.push("Primário");
    } else if (kind === "unique") {
      parts.push("Único");
    }
    return parts.filter(Boolean).join(" - ");
  }

  function activateIndexPanel(tabId) {
    const tabEl = $("#indexFilterTabs");
    tabEl.find(".manual-tab-panel").not(".dynamic-filter-panel").removeClass("active");
    tabEl.find("#" + tabId).addClass("active");
  }

  function indexKindGroupLabel(kind) {
    if (kind === "primary") return "Chave primária";
    if (kind === "unique") return "Chave única";
    return "Demais índices";
  }

  function indexKindText(kind) {
    if (kind === "primary") return "Primário";
    if (kind === "unique") return "Único";
    return "";
  }

  function indexKindOverride(indexName) {
    const database = String(state.selectedDatabase || "").toLowerCase();
    const table = String(state.selectedTable || "").toLowerCase();
    const index = String(indexName || "").toLowerCase();
    return INDEX_KIND_OVERRIDES[`${database}|${table}|${index}`] || "normal";
  }

  function groupFieldsByIndex(fields) {
    const grouped = {};
    (fields || []).forEach(function (field) {
      const indexList = splitIndices(field.indices || field.indexes || field.index);
      const metadataList = splitIndices(field.indexMetadata || field.indexInfos || field.indicesInfo || field.indexDetails);
      const metadataByName = metadataList.reduce(function (acc, item) {
        if (item.name) acc[item.name.toLowerCase()] = item;
        return acc;
      }, {});
      const resolvedIndexList = indexList.length ? indexList : metadataList;
      if (!resolvedIndexList.length) return;
      const fieldIndexKind = indexKindFromField(field);
      resolvedIndexList.forEach(function (indexInfo) {
        const indexName = indexInfo.name || "";
        if (!indexName) return;
        const metadataInfo = metadataByName[indexName.toLowerCase()] || {};
        if (!grouped[indexName]) grouped[indexName] = [];
        grouped[indexName].push(field);
        grouped[indexName].kind = strongerIndexKind(
          grouped[indexName].kind || "normal",
          strongerIndexKind(
            strongerIndexKind(
              strongerIndexKind(indexInfo.kind || "normal", metadataInfo.kind || "normal"),
              indexKindOverride(indexName)
            ),
            fieldIndexKind
          )
        );
      });
    });
    return grouped;
  }

  function splitIndices(value) {
    if (!value) return [];

    if (Array.isArray(value)) {
      return value
        .map(normalizeIndexInfo)
        .filter((item) => item.name);
    }

    if (typeof value === "string") {
      const text = String(value).trim();
      if (!text) return [];
      if (text[0] === "[" && text[text.length - 1] === "]") {
        try {
          const parsed = JSON.parse(text);
          if (Array.isArray(parsed)) {
            return parsed.map(normalizeIndexInfo).filter((item) => item.name);
          }
        } catch (_) {}
      }
      return text
        .split(/[,;|\s]+/)
        .map(normalizeIndexInfo)
        .filter((item) => item.name);
    }

    if (typeof value !== "string") {
      return [normalizeIndexInfo(value)].filter((item) => item.name);
    }
  }

  function normalizeIndexInfo(value) {
    if (!value) return { name: "", kind: "normal" };
    if (typeof value === "object") {
      const name = String(value.name || value.indexName || value.index || value.idx || value.idxName || value.value || "").trim();
      return { name, kind: strongerIndexKind(indexKindFromMetadata(value), indexKindFromName(name)) };
    }
    const name = String(value || "").trim();
    return { name, kind: indexKindFromName(name) };
  }

  function indexKindFromMetadata(meta) {
    const type = String(meta.type || meta.kind || meta.indexType || meta.indexKind || meta.category || meta.keyType || meta.keyKind || "").toLowerCase();
    if (isTrueLike(meta.primary) || isTrueLike(meta.primaryKey) || isTrueLike(meta.isPrimary) || isTrueLike(meta.isPrimaryKey) ||
      isTrueLike(meta.primaryIndex) || isTrueLike(meta.isPrimaryIndex) || hasIndexKindText(type, "primary")) {
      return "primary";
    }
    if (isTrueLike(meta.unique) || isTrueLike(meta.isUnique) || isTrueLike(meta.uniqueKey) || isTrueLike(meta.isUniqueKey) ||
      isTrueLike(meta.uniqueIndex) || isTrueLike(meta.isUniqueIndex) || hasIndexKindText(type, "unique")) {
      return "unique";
    }
    return "normal";
  }

  function indexKindFromField(field) {
    if (!field) return "normal";
    const type = String(field.indexType || field.indexKind || field.indexCategory || field.keyType || field.keyKind || "").toLowerCase();
    const text = String(field.indexMeta || field.indexInfo || field.indexDescription || "").toLowerCase();
    if (isTrueLike(field.primary) || isTrueLike(field.primaryKey) || isTrueLike(field.isPrimary) || isTrueLike(field.isPrimaryKey) ||
      isTrueLike(field.primaryIndex) || isTrueLike(field.isPrimaryIndex) || hasIndexKindText(type, "primary") || hasIndexKindText(text, "primary")) {
      return "primary";
    }
    if (isTrueLike(field.unique) || isTrueLike(field.isUnique) || isTrueLike(field.uniqueKey) || isTrueLike(field.isUniqueKey) ||
      isTrueLike(field.uniqueIndex) || isTrueLike(field.isUniqueIndex) || hasIndexKindText(type, "unique") || hasIndexKindText(text, "unique")) {
      return "unique";
    }
    return "normal";
  }

  function isTrueLike(value) {
    if (value === true || value === 1) return true;
    if (typeof value !== "string") return false;
    const normalized = value.trim().toLowerCase();
    return normalized === "true" || normalized === "yes" || normalized === "sim" || normalized === "1";
  }

  function hasIndexKindText(text, kind) {
    const normalized = String(text || "").toLowerCase();
    if (!normalized) return false;
    if (kind === "primary") return /\b(primary|primario|primário|pk)\b/.test(normalized);
    if (kind === "unique") return /\b(unique|unico|único|uniq)\b/.test(normalized);
    return false;
  }

  function indexKindFromName(name) {
    const normalized = String(name || "").trim().toLowerCase();
    if (!normalized) return "normal";
    if (normalized === "indice1" || normalized === "primary" || normalized === "primarykey" || normalized === "pk") return "primary";
    if (/(\b|[_-])(primary|primario|primário|pk)(\b|[_-])/.test(normalized)) return "primary";
    if (/(\b|[_-])(unique|unico|único|uniq)(\b|[_-])/.test(normalized)) return "unique";
    return "normal";
  }

  function strongerIndexKind(current, next) {
    const order = { primary: 0, unique: 1, normal: 2 };
    return (order[next] ?? 2) < (order[current] ?? 2) ? next : current;
  }

  function sortedIndexNames(groups) {
    const order = { primary: 0, unique: 1, normal: 2 };
    return Object.keys(groups).sort(function (left, right) {
      const leftKind = groups[left] && groups[left].kind ? groups[left].kind : "normal";
      const rightKind = groups[right] && groups[right].kind ? groups[right].kind : "normal";
      const leftOrder = order[leftKind] ?? 2;
      const rightOrder = order[rightKind] ?? 2;
      if (leftOrder !== rightOrder) return leftOrder - rightOrder;
      return left.localeCompare(right, "pt-BR", { sensitivity: "base" });
    });
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

  function normalizeIntegerFilterText(value) {
    const text = normalizeScalarFilterText(value);
    if (!text) return "";
    if (/^-?\d{1,3}([.,\s]\d{3})+$/.test(text)) {
      return text.replace(/[.,\s]/g, "");
    }
    return text;
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
      if (!/^-?\d+$/.test(normalizeIntegerFilterText(text))) {
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
    if (getFieldType(fieldMeta) === "integer" || getFieldType(fieldMeta) === "int64") {
      return normalizeIntegerFilterText(text);
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
        format: "dd/MM/yyyy",
        change: function () {
          $input.data("filterValue", this.value());
          clearIndexFilterError($input.closest(".index-filter-item"));
        }
      });
      return;
    }

    if (isDecimalType(fieldMeta)) {
      $input.kendoNumericTextBox({
        decimals: getFieldType(fieldMeta) === "integer" || getFieldType(fieldMeta) === "int64" ? 0 : 2,
        format: getFieldType(fieldMeta) === "integer" || getFieldType(fieldMeta) === "int64" ? "n0" : "n2",
        change: function () {
          $input.data("filterValue", this.value());
          clearIndexFilterError($input.closest(".index-filter-item"));
        },
        spin: function () {
          $input.data("filterValue", this.value());
          clearIndexFilterError($input.closest(".index-filter-item"));
        }
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
      const operatorInput = row.find(".index-filter-operator");
      if (!operatorInput.data("kendoDropDownList")) {
        operatorInput.kendoDropDownList({
          dataTextField: "label",
          dataValueField: "value",
          dataSource: []
        });
      }
      const operator = operatorInput.data("kendoDropDownList");
      row.data("operatorWidget", operator);
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
    return window.SursumViewAsOptions.normalizeOptions(options);
  }

  function isNumericType(fieldMeta) {
    return window.SursumViewAsOptions.isNumericField(fieldMeta);
  }

  function buildFieldOptionLookup(fields) {
    return window.SursumViewAsOptions.buildNumericOptionLookup(fields);
  }

  function describeFieldValue(fieldMeta, value, lookupSource) {
    return window.SursumViewAsOptions.describeFieldValue(fieldMeta, value, lookupSource || state.fieldOptionLookup);
  }

  function normalizeLogicalDisplayValue(value) {
    return window.SursumViewAsOptions.normalizeLogicalDisplayValue(value);
  }

  function displayFieldValue(fieldMeta, value, lookupSource) {
    return window.SursumViewAsOptions.displayFieldValue(fieldMeta, value, lookupSource || state.fieldOptionLookup);
  }

  function displayFieldValueWithForeignDescription(fieldMeta, value, lookupSource) {
    const displayValue = displayFieldValue(fieldMeta, value, lookupSource);
    const fieldName = fieldMeta && fieldMeta.name ? fieldMeta.name : "";
    const description = foreignDescriptionForValue(fieldName, value);
    if (!description) return displayValue;
    return displayValue + " - " + description;
  }

  function foreignDescriptionForValue(fieldName, value) {
    if (!fieldName || value === null || value === undefined || String(value).trim() === "") {
      return "";
    }
    const lookup = state.foreignDescriptionValues && state.foreignDescriptionValues[fieldName];
    if (!lookup) return "";
    return lookup[String(value)] || "";
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
      width: Math.min(Math.max(160, (field.label || field.name).length * 8), 280),
      template: function (dataItem) {
        return displayFieldValueWithForeignDescription(field, dataItem ? dataItem[field.name] : "");
      }
    }));

    if (!columns.length) {
      columns.push({ field: "_noData", title: "Sem metadados" });
    }

    grid.setOptions({
      columns,
      pageable: { pageSize: getGridPageSize() }
    });
  }

  function getGridPageSize() {
    const widget = $("#queryGridPageSize").data("kendoNumericTextBox");
    return Number(widget && widget.value ? widget.value() : $("#queryGridPageSize").val()) || 50;
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
    const pageSize = Number($("#queryPageSize").data("kendoNumericTextBox").value()) || 500;

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
      url: pasoeUrl("/query"),
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
    grid.dataSource.pageSize(getGridPageSize());
    grid.dataSource.data(rows);
    ensureForeignKeysDiscovered().then(function () {
      return loadForeignDescriptionValues(rows);
    }).then(function () {
      grid.refresh();
    });

    const records = Number(response.recordsReturned || rows.length);
    const hasMore = response.hasMore === undefined ? "-" : response.hasMore;
    $("#resultStatus").text("success=" + response.success + " | recordsReturned=" + records + " | hasMore=" + hasMore);

    if (!rows.length) {
      $("#resultStatus").text($("#resultStatus").text() + " | Sem registros para o filtro atual.");
    }
  }

  function ensureForeignKeysDiscovered() {
    if (Array.isArray(state.foreignKeys) && state.foreignKeys.length) {
      return Promise.resolve(state.foreignKeys);
    }
    return new Promise(function (resolve) {
      discoverForeignKeys(function () {
        resolve(state.foreignKeys || []);
      });
    });
  }

  function loadForeignDescriptionValues(rows) {
    const candidates = descriptionRelationCandidates();
    if (!rows || !rows.length || !candidates.length) {
      return Promise.resolve();
    }

    return Promise.all(candidates.map(function (candidate) {
      const values = uniqueNonEmptyValues(rows.map(function (row) {
        return row ? row[candidate.localField] : "";
      }));
      if (!values.length) return Promise.resolve();
      return loadForeignDescriptionValuesForCandidate(candidate, values);
    }));
  }

  function descriptionRelationCandidates() {
    const seen = {};
    return (state.foreignKeys || []).filter(function (fk) {
      if (!fk || (fk.relationStatus || "").toLowerCase() !== "encontrada") return false;
      if (!fk.localField || !fk.localToForeignField || !fk.foreignTable || !fk.foreignDescriptionField) return false;
      const key = [
        fk.localField,
        fk.foreignDatabase || state.selectedDatabase,
        fk.foreignTable,
        fk.localToForeignField,
        fk.foreignDescriptionField
      ].join("|").toLowerCase();
      if (seen[key]) return false;
      seen[key] = true;
      return true;
    });
  }

  function uniqueNonEmptyValues(values) {
    const seen = {};
    const result = [];
    (values || []).forEach(function (value) {
      if (value === null || value === undefined || String(value).trim() === "") return;
      const key = String(value);
      if (seen[key]) return;
      seen[key] = true;
      result.push(key);
    });
    return result;
  }

  function loadForeignDescriptionValuesForCandidate(candidate, values) {
    const db = candidate.foreignDatabase || state.selectedDatabase;
    const cacheKey = [
      db,
      candidate.foreignTable,
      candidate.localToForeignField,
      candidate.foreignDescriptionField,
      values.slice().sort().join("\u001f")
    ].join("|");

    if (state.foreignDescriptionCache[cacheKey]) {
      mergeForeignDescriptionValues(candidate.localField, state.foreignDescriptionCache[cacheKey]);
      return Promise.resolve(state.foreignDescriptionCache[cacheKey]);
    }

    const payload = {
      execution: "sync",
      page: 1,
      pageSize: Math.max(values.length, 1),
      sources: [{
        nome: candidate.foreignTable,
        alias: "d",
        banco: db,
        campos: [candidate.localToForeignField, candidate.foreignDescriptionField].filter(Boolean).join(",")
      }],
      filters: [{
        sourceAlias: "d",
        field: candidate.localToForeignField,
        operator: values.length === 1 ? "=" : "in",
        value: values.length === 1 ? values[0] : values.join(",")
      }],
      joins: [],
      orderBy: [],
      pipeline: []
    };

    return $.ajax({
      url: pasoeUrl("/query"),
      method: "POST",
      contentType: "application/json",
      dataType: "json",
      data: JSON.stringify(payload)
    }).then(function (response) {
      if (!response || response.success === false) return {};
      const lookup = {};
      (response.data || []).forEach(function (row) {
        const keyValue = row ? row[candidate.localToForeignField] : "";
        const description = row ? row[candidate.foreignDescriptionField] : "";
        if (keyValue === null || keyValue === undefined || String(keyValue).trim() === "") return;
        if (description === null || description === undefined || String(description).trim() === "") return;
        lookup[String(keyValue)] = String(description);
      });
      state.foreignDescriptionCache[cacheKey] = lookup;
      mergeForeignDescriptionValues(candidate.localField, lookup);
      return lookup;
    }, function () {
      return {};
    });
  }

  function mergeForeignDescriptionValues(localField, lookup) {
    if (!localField || !lookup) return;
    if (!state.foreignDescriptionValues[localField]) {
      state.foreignDescriptionValues[localField] = {};
    }
    Object.keys(lookup).forEach(function (key) {
      state.foreignDescriptionValues[localField][key] = lookup[key];
    });
  }

  function openRecordWindow(row) {
    const win = $("#recordWindow").data("kendoWindow");
    const joinDrop = $("#recordJoinTable").data("kendoDropDownList");
    const container = $("#recordForm");

    state.currentRecordRow = row || {};
    state.currentRecordJoinFieldOptions = {};

    if (joinDrop) {
      joinDrop.setDataSource([]);
      joinDrop.value("");
      joinDrop.enable(false);
    }

    function renderRecordFormContent(rowData, rowJoinOptions) {
      if (!window.SursumRecordFormRenderer || typeof SursumRecordFormRenderer.render !== "function") {
        container.empty().append("<div class='status-box error'>Renderizador de formulario indisponivel.</div>");
        return;
      }
      SursumRecordFormRenderer.render({
        container,
        row: rowData || {},
        fields: state.fields,
        joinOptionsByField: rowJoinOptions || {},
        descriptionValuesByField: state.foreignDescriptionValues,
        formatValue: describeFieldValue,
        createJoinButton: getRecordFieldJoinButton,
        applyWidget: applyRecordFieldWidget,
        isLongTextField
      });
    }

    discoverForeignKeys(function () {
      const rowJoinOptions = buildRecordJoinOptionsByField(row || {});
      state.currentRecordJoinFieldOptions = rowJoinOptions;
      loadForeignDescriptionValues([row || {}]).then(function () {
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
        foreignDescriptionField: fk.foreignDescriptionField || "",
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

    getJsonUtf8(metadataUrl("/metadata/tables/" + encodeURIComponent(option.foreignTable) + "/fields?database=" + encodeURIComponent(option.foreignDatabase)))
      .done(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        const fields = (response.fields || response.data || []).map((field, index) => ({
          ...field,
          __seq: index
        }));

        const relatedOptionLookup = buildFieldOptionLookup(fields);
        const columns = fields.length
          ? fields.map((field) => ({
              field: field.name,
              title: field.label || field.name,
              width: Math.min(Math.max(160, (field.label || field.name).length * 8), 280),
              template: function (dataItem) {
                return displayFieldValue(field, dataItem ? dataItem[field.name] : "", relatedOptionLookup);
              }
            }))
          : [{ field: "_noData", title: "Sem metadados" }];

        basePayload.sources[0].campos = fields.map((field) => field.name).join(",") || "*";
        relatedGrid.setOptions({ columns: columns });

        const filteredPayload = Object.assign({}, basePayload);
        relatedGrid.dataSource.data([]);

        $.ajax({
          url: pasoeUrl("/query"),
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

  function applyRecordFieldWidget(input, fieldMeta, forceText) {
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

    if (!forceText && isNumeric && typeof input.kendoNumericTextBox === "function") {
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
      state.apiBase = window.SursumContext && typeof SursumContext.resolveApiBase === "function"
        ? String(SursumContext.resolveApiBase(environment, selectedCompany) || "").replace(/\/+$/, "")
        : String(environment.pasoeBaseUrl || "").replace(/\/+$/, "");
      $("#apiBaseUrl").val(state.apiBase);
      localStorage.setItem("sursumApiBaseUrl", state.apiBase);
    }

    if (companyCombo) {
      companyCombo.setDataSource(new kendo.data.DataSource({ data: companies }));
      companyCombo.value(selectedCompany ? selectedCompany.id : "");
    }

    void client;
  }

  function onCompanyChanged() {
    const companyCombo = $("#apiCompany").data("kendoComboBox");
    const companyId = companyCombo ? String(companyCombo.value() || "") : "";
    const company = resolveCompanySelection(companyCombo, companyId);
    if (!company) {
      refreshContextUi();
      return;
    }

    localStorage.setItem(QUERY_COMPANY_KEY, company.id);
    if (window.SursumContext && typeof SursumContext.setSelection === "function") {
      SursumContext.setSelection(company.clientId || "", company.environmentId || "", company.id);
      return;
    }

    refreshContextUi();
    loadDatabases(false);
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

  function resolveCompanySelection(companyCombo, companyId) {
    const companies = companiesForCurrentEnvironment();
    const selectedId = String(companyId || "").trim();
    if (selectedId) {
      const byId = companies.find(function (item) {
        return item.id === selectedId;
      });
      if (byId) return byId;
    }

    const typedText = companyCombo && typeof companyCombo.text === "function"
      ? String(companyCombo.text() || "").trim().toLowerCase()
      : "";
    if (!typedText) return null;

    return companies.find(function (item) {
      return String(item.name || "").trim().toLowerCase() === typedText
        || String(item.code || "").trim().toLowerCase() === typedText
        || String(item.pathParam || "").trim().toLowerCase() === typedText;
    }) || null;
  }
})();
