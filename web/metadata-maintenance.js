(function () {
  const DEFAULT_API = "http://localhost:8890/web/SursumDynamicQuery";
  const PASOE_PROXY = "pasoe-proxy.php";
  const TODOS_DATABASE = "Selecionar";
  const LAST_JOB_KEY = "sursumMetadataMaintenanceLastJob";

  const state = {
    apiBase: DEFAULT_API,
    databases: [],
    tables: [],
    viewAsTables: [],
    currentJob: null,
    running: false,
    activeExecutions: 0,
    runningTables: Object.create(null),
    finishingJob: false,
    jobRenderTimer: null,
    jobRenderPending: false,
    editingViewAs: null,
    editingRelation: null,
    contextKey: "",
    databaseRequestSeq: 0,
    waitingForInitialContext: true,
    selectedCompanyId: localStorage.getItem("sursumSelectedQueryCompany") || ""
  };

  let viewAsWindow = null;
  let relationWindow = null;

  $(function () {
    initWidgets();
    bindEvents();
    refreshContext();
    state.contextKey = metadataContextKey();
    loadDatabasesWhenContextReady();
    if (hasElement("#jobGrid")) loadLastJob();
  });

  function initWidgets() {
    ensureBatchControls();
    if (hasElement("#metadataTabs")) {
      $("#metadataTabs").kendoTabStrip({ animation: false }).data("kendoTabStrip").select(0);
    }
    if (hasElement("#apiCompany")) $("#apiCompany").kendoComboBox({
      dataTextField: "name",
      dataValueField: "id",
      select: function (event) {
        const item = this.dataItem(event.item);
        if (item && item.id) applyCompanySelection(item.id);
      },
      change: function () {
        applyCompanySelection(this.value());
      }
    });
    if (hasElement("#dbCombo")) $("#dbCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "name",
      filter: "contains",
      change: function () {
        state.tables = [];
        state.viewAsTables = [];
        refreshTableCombo();
        loadTables();
        loadRelationsRows();
      }
    });
    if (hasElement("#tableName")) $("#tableName").kendoComboBox({
      dataSource: [],
      filter: "contains",
      suggest: true,
      placeholder: $("#tableName").attr("placeholder") || "Opcional",
      change: function () {
        const table = tableValue();
        $("#viewAsTable,#leftTable").val(table);
        loadViewAsRows();
        loadRelationsRows();
      }
    });
    if (hasElement("#relationType")) {
      $("#relationType").kendoDropDownList({ dataSource: ["INNER", "LEFT"], value: "INNER" });
    }
    $("#viewAsTable,#viewAsField,#leftTable,#leftField,#rightTable,#rightField").filter(function () {
      return this && this.id;
    }).kendoTextBox();
    if (hasElement("#viewAsWindow")) viewAsWindow = $("#viewAsWindow").kendoWindow({
      width: "720px",
      title: "View-as",
      visible: false,
      modal: true,
      actions: ["Close"]
    }).data("kendoWindow");
    if (hasElement("#relationWindow")) relationWindow = $("#relationWindow").kendoWindow({
      width: "820px",
      title: "Join",
      visible: false,
      modal: true,
      actions: ["Close"]
    }).data("kendoWindow");
    if (hasElement("#parallelExecutions")) $("#parallelExecutions").kendoNumericTextBox({
      format: "n0",
      decimals: 0,
      min: 1,
      step: 1,
      value: 1,
      change: function () {
        this.value(parallelExecutionCount());
        if (state.running) scheduleJob();
      }
    });
    if (hasElement("#existingMetadataBehavior")) $("#existingMetadataBehavior").kendoDropDownList({
      dataTextField: "text",
      dataValueField: "value",
      dataSource: [
        { text: "Desconsiderar", value: "skip" },
        { text: "Atualizar", value: "update" }
      ],
      value: "skip"
    });
    $("#createJob,#runJob,#pauseJob,#cancelJob,#reprocessAllJob,#reloadTables,#openTableBrowser,#addViewAs,#importViewAsCsv,#saveViewAs,#cancelViewAs,#loadViewAs,#addRelation,#saveRelation,#cancelRelation,#loadRelations").kendoButton();
    if (hasElement("#jobGrid")) $("#jobGrid").kendoGrid({
      dataSource: {
        data: [],
        pageSize: 100
      },
      height: 390,
      pageable: {
        pageSizes: [50, 100, 200],
        buttonCount: 5
      },
      sortable: true,
      dataBound: function () {
        this.tbody.find(".cancel-job-item,.reprocess-job-item").each(function () {
          const button = $(this);
          if (!button.data("kendoButton")) button.kendoButton();
        });
      },
      toolbar: [
        "excel",
        {
          template: '<div class="job-grid-filters">'
            + '<label class="job-grid-switch"><input id="showPendingOnly" type="checkbox"><span class="switch-control"></span><span class="switch-label">Mostrar apenas pendentes</span></label>'
            + '<label class="job-grid-switch"><input id="showErrorOnly" type="checkbox"><span class="switch-control"></span><span class="switch-label">Mostrar apenas com erro</span></label>'
            + '</div>'
        }
      ],
      excel: {
        fileName: "sursum-atualizacao-lote-metadados.xlsx",
        allPages: true,
        filterable: true
      },
      columns: [
        { field: "table", title: "Tabela", width: 210 },
        { field: "status", title: "Status", width: 110 },
        { field: "relationCount", title: "Joins", width: 90 },
        { field: "viewAsCount", title: "View-as", width: 90 },
        {
          field: "message",
          title: "Mensagem",
          template: function (item) {
            const message = item && item.message ? item.message : "";
            return '<span class="job-message-cell" title="' + escapeHtml(message) + '">' + escapeHtml(message) + '</span>';
          }
        },
        {
          title: "",
          width: 110,
          template: function (item) {
            if (!item) return "";
            if (item.status === "pending") {
              return '<button type="button" class="cancel-job-item" data-table="' + escapeHtml(item.table || "") + '">Cancelar</button>';
            }
            if (item.status === "error") {
              return '<button type="button" class="reprocess-job-item" data-table="' + escapeHtml(item.table || "") + '">Reprocessar</button>';
            }
            return "";
          }
        }
      ]
    });
    if (hasElement("#viewAsGrid")) $("#viewAsGrid").kendoGrid({
      dataSource: {
        data: [],
        pageSize: 100
      },
      pageable: {
        pageSizes: [50, 100, 200],
        buttonCount: 5
      },
      height: 390,
      sortable: true,
      dataBound: function () {
        initGridActionButtons(this.tbody, ".edit-view-as,.delete-view-as");
      },
      columns: [
        { field: "table", title: "Tabela", width: 180 },
        { field: "field", title: "Campo", width: 180 },
        { field: "viewAs", title: "View-as" },
        {
          field: "listExpression",
          title: "Opcoes",
          width: 260,
          template: function (item) {
            return '<span class="job-message-cell" title="' + escapeHtml(viewAsOptionsText(item)) + '">' + escapeHtml(viewAsOptionsText(item)) + '</span>';
          }
        },
        { field: "source", title: "Origem", width: 110 },
        {
          field: "updatedAt",
          title: "Atualizado em",
          width: 190,
          template: function (item) {
            return escapeHtml(formatBrazilianDateTime(item && item.updatedAt));
          }
        },
        {
          title: "Acoes",
          width: 170,
          template: '<button type="button" class="edit-view-as">Alterar</button><button type="button" class="delete-view-as">Excluir</button>'
        }
      ]
    });
    if (hasElement("#relationsGrid")) $("#relationsGrid").kendoGrid({
      dataSource: [],
      height: 390,
      sortable: true,
      dataBound: function () {
        initGridActionButtons(this.tbody, ".edit-relation,.delete-relation");
      },
      columns: [
        { field: "leftTable", title: "Tabela esq.", width: 160 },
        { field: "leftField", title: "Campo esq.", width: 150 },
        { field: "rightTable", title: "Tabela dir.", width: 160 },
        { field: "rightField", title: "Campo dir.", width: 150 },
        { field: "type", title: "Tipo", width: 90 },
        { field: "source", title: "Origem", width: 110 },
        { field: "updatedAt", title: "Atualizado em", width: 190 },
        {
          title: "Acoes",
          width: 170,
          template: '<button type="button" class="edit-relation">Alterar</button><button type="button" class="delete-relation">Excluir</button>'
        }
      ]
    });
    if (window.SursumUiReady) window.SursumUiReady();
  }

  function hasElement(selector) {
    return $(selector).length > 0;
  }

  function ensureBatchControls() {
    const actionRow = $(".metadata-batch-options .action-row").first();
    if (actionRow.length && !$("#cancelJob").length) {
      actionRow.prepend('<button id="cancelJob">Cancelar pendentes</button>');
    }
    if (actionRow.length && !$("#reprocessAllJob").length) {
      const cancelButton = $("#cancelJob");
      if (cancelButton.length) {
        cancelButton.after('<button id="reprocessAllJob">Reprocessar tudo</button>');
      } else {
        actionRow.prepend('<button id="reprocessAllJob">Reprocessar tudo</button>');
      }
    }
    $(".job-control-row").remove();
  }

  function bindEvents() {
    window.addEventListener("sursum:context-changed", function () {
      const previousKey = state.contextKey;
      refreshContext();
      const nextKey = metadataContextKey();
      if (nextKey !== previousKey) {
        state.contextKey = nextKey;
        if (!state.waitingForInitialContext) {
          loadDatabases(false);
        }
      }
    });
    $("#reloadTables").on("click", function () { loadTables(true); });
    $("#openTableBrowser").on("click", function () { window.location.href = "table-browser.html"; });
    $("#createJob").on("click", createJob);
    $("#runJob").on("click", function () { runJob(); });
    $("#pauseJob").on("click", pauseJob);
    $("#cancelJob").on("click", cancelPendingJobItems);
    $("#reprocessAllJob").on("click", reprocessAllJobErrors);
    $("#showPendingOnly,#showErrorOnly").on("change", renderJob);
    $("#jobGrid").on("click", ".cancel-job-item", function () {
      cancelJobItem($(this).attr("data-table") || "");
    });
    $("#jobGrid").on("click", ".reprocess-job-item", function () {
      reprocessJobItem($(this).attr("data-table") || "");
    });
    $("#addViewAs").on("click", openViewAsCreate);
    $("#importViewAsCsv").on("click", function () {
      $("#viewAsCsvFile").val("").trigger("click");
    });
    $("#viewAsCsvFile").on("change", importViewAsCsvFile);
    $("#saveViewAs").on("click", saveManualViewAs);
    $("#cancelViewAs").on("click", function () {
      if (viewAsWindow) viewAsWindow.close();
    });
    $("#loadViewAs").on("click", loadViewAsRows);
    $("#viewAsGrid").on("click", ".edit-view-as", function () {
      openViewAsEdit(gridRowData("#viewAsGrid", this));
    });
    $("#viewAsGrid").on("click", ".delete-view-as", function () {
      deleteViewAsRow(gridRowData("#viewAsGrid", this));
    });
    $("#addRelation").on("click", openRelationCreate);
    $("#saveRelation").on("click", saveManualRelation);
    $("#cancelRelation").on("click", function () {
      if (relationWindow) relationWindow.close();
    });
    $("#loadRelations").on("click", loadRelationsRows);
    $("#relationsGrid").on("click", ".edit-relation", function () {
      openRelationEdit(gridRowData("#relationsGrid", this));
    });
    $("#relationsGrid").on("click", ".delete-relation", function () {
      deleteRelationRow(gridRowData("#relationsGrid", this));
    });
  }

  function loadDatabasesWhenContextReady() {
    const contextApi = window.SursumContext || null;
    setStatus("Carregando contexto...", "");

    if (contextApi && typeof contextApi.whenReady === "function") {
      contextApi.whenReady().then(function () {
        state.waitingForInitialContext = false;
        refreshContext();
        state.contextKey = metadataContextKey();
        loadDatabases(false);
      });
      return;
    }

    state.waitingForInitialContext = false;
    loadDatabases(false);
  }

  function refreshContext() {
    const companies = companiesForSelection();
    const combo = $("#apiCompany").data("kendoComboBox");
    const selected = selectedCompanyFromId(state.selectedCompanyId)
      || selectedCompanyFromContext()
      || companies[0]
      || null;
    state.selectedCompanyId = selected && selected.id ? selected.id : "";
    if (combo) {
      combo.setDataSource(new kendo.data.DataSource({ data: companies }));
      if (selected && selected.id) combo.value(selected.id);
    }
    state.apiBase = endpointUrl(currentEnvironment());
    $("#apiBaseUrl").val(state.apiBase);
  }

  function metadataContextKey() {
    const environment = currentEnvironment();
    const company = selectedCompany();
    return [
      environment && environment.id ? environment.id : "",
      company && company.id ? company.id : "",
      state.apiBase || ""
    ].join("|");
  }

  function loadDatabases(forceReload) {
    const requestId = ++state.databaseRequestSeq;
    const requestContextKey = metadataContextKey();
    setStatus("Carregando bancos...", "");
    $.getJSON(pasoeUrl(forceReload ? "/metadata/databases/sync" : "/metadata/database-catalog"))
      .done(function (response) {
        if (!isCurrentDatabaseRequest(requestId, requestContextKey)) return;
        if (!response || response.success === false) throw new Error(apiError(response));
        const rows = Array.isArray(response.data) ? response.data : [];
        state.databases = [{ name: TODOS_DATABASE }].concat(rows.map(function (item) {
          return { name: item.name || item.logicalName || item.displayName || "" };
        }).filter(function (item) { return item.name; }));
        const combo = $("#dbCombo").data("kendoComboBox");
        const currentValue = combo.value();
        combo.setDataSource(new kendo.data.DataSource({ data: state.databases }));
        if (databaseExists(currentValue)) {
          combo.value(currentValue);
        } else {
          combo.value(state.databases[0] ? state.databases[0].name : TODOS_DATABASE);
        }
        state.tables = [];
        state.viewAsTables = [];
        refreshTableCombo();
        setStatus("Bancos carregados. Selecione um banco para carregar tabelas.", "ok");
      })
      .fail(function (xhr) {
        if (!isCurrentDatabaseRequest(requestId, requestContextKey)) return;
        setStatus("Falha ao carregar bancos: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function isCurrentDatabaseRequest(requestId, contextKey) {
    return requestId === state.databaseRequestSeq && contextKey === state.contextKey;
  }

  function databaseExists(name) {
    const normalized = String(name || "");
    return state.databases.some(function (item) {
      return item && item.name === normalized;
    });
  }

  function loadTables(forceReload) {
    const database = selectedDatabase();
    if (!database || database === TODOS_DATABASE) {
      state.tables = [];
      refreshTableCombo();
      setStatus("Selecione um banco especifico para carregar tabelas.", "");
      return;
    }
    const path = "/metadata/tables" + (database && database !== TODOS_DATABASE ? "?database=" + encodeURIComponent(database) : "");
    setStatus("Carregando tabelas...", "");
    getPasoeJson(path)
      .done(function (response) {
        if (!response || response.success === false) throw new Error(apiError(response));
        state.tables = uniqueTableNames((Array.isArray(response.data) ? response.data : []).map(tableNameFromMetadataItem));
        refreshTableCombo();
        if (hasElement("#viewAsGrid") && !tableValue()) loadViewAsRows();
        setStatus(`Tabelas carregadas: ${state.tables.length}.`, "ok");
      })
      .fail(function (xhr) {
        loadTablesBySync(database)
          .done(function (rows) {
            state.tables = uniqueTableNames(rows);
            refreshTableCombo();
            if (hasElement("#viewAsGrid") && !tableValue()) loadViewAsRows();
            setStatus(`Tabelas carregadas: ${state.tables.length}.`, "ok");
          })
          .fail(function (syncError) {
            setStatus("Falha ao carregar tabelas. Endpoint: " + state.apiBase + ". Detalhe: " + ajaxErrorMessage(syncError || xhr), "error");
          });
      });
  }

  function loadTablesBySync(database) {
    const deferred = $.Deferred();
    getPasoeJson("/metadata/sync?include=tables&database=" + encodeURIComponent(database))
      .done(function (response) {
        if (!response || response.success === false) {
          deferred.reject(response);
          return;
        }
        const steps = Array.isArray(response.steps) ? response.steps : [];
        const tableStep = steps.find(function (step) { return step && step.step === "tables"; });
        const rows = uniqueTableNames((tableStep && Array.isArray(tableStep.data) ? tableStep.data : []).map(tableNameFromMetadataItem));
        if (!rows.length) {
          deferred.reject({ error: "Sincronizacao nao retornou lista de tabelas." });
          return;
        }
        deferred.resolve(rows);
      })
      .fail(function (xhr) {
        deferred.reject(xhr);
      });
    return deferred.promise();
  }

  function createJob() {
    const database = selectedDatabase();
    let tables = $("#onlyCurrentTable").is(":checked") ? [tableValue()] : state.tables.slice();
    tables = tables.map(function (item) { return String(item || "").trim(); }).filter(Boolean);
    if (!database || database === TODOS_DATABASE) {
      setStatus("Selecione um banco especifico para criar a fila.", "error");
      return;
    }
    if (!tables.length) {
      setStatus("Carregue tabelas ou informe uma tabela antes de criar a fila.", "error");
      return;
    }
    setStatus("Criando fila de sincronizacao...", "");
    withGridLoading("#jobGrid", $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope("", database), {
        resource: "job",
        action: "create",
        tables,
        includeRelations: $("#includeRelations").is(":checked"),
        includeViewAs: $("#includeViewAs").is(":checked"),
        existingMetadataBehavior: existingMetadataBehavior()
      }))
    })).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao criar fila: " + apiError(response), "error");
        return;
      }
      state.currentJob = response.data;
      state.activeExecutions = 0;
      state.runningTables = Object.create(null);
      state.finishingJob = false;
      if (state.currentJob && state.currentJob.id) localStorage.setItem(LAST_JOB_KEY, state.currentJob.id);
      renderJob();
      setStatus(`Fila criada com ${state.currentJob.totalTables} tabelas.`, "ok");
    }).fail(function (xhr) {
      setStatus("Falha ao criar fila: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function runJob() {
    if (!state.currentJob) {
      setStatus("Crie uma fila antes de executar.", "error");
      return;
    }
    if (state.currentJob.status === "cancelled") {
      setStatus("Esta fila esta cancelada.", "error");
      return;
    }
    if (state.running) return;
    state.running = true;
    state.finishingJob = false;
    setBatchRunningUi(true);
    scheduleJob();
  }

  function loadLastJob() {
    const jobId = localStorage.getItem(LAST_JOB_KEY);
    if (!jobId) return;
    withGridLoading("#jobGrid", $.getJSON("metadata-store.php?resource=job&id=" + encodeURIComponent(jobId)))
      .done(function (response) {
        if (!response || !response.success || !response.data) return;
        state.currentJob = response.data;
        renderJob();
      });
  }

  function pauseJob() {
    state.running = false;
    setBatchRunningUi(false);
    renderJob({ immediate: true });
    setStatus("Execucao pausada. Itens em andamento serao concluidos.", "");
  }

  function cancelPendingJobItems() {
    if (!state.currentJob) {
      setStatus("Crie ou carregue uma fila antes de cancelar.", "error");
      return;
    }
    state.running = false;
    setBatchRunningUi(false);
    withGridLoading("#jobGrid", cancelJobRequest(""))
      .done(function (response) {
        if (!response || response.success === false) {
          setStatus("Falha ao cancelar fila: " + apiError(response), "error");
          return;
        }
        state.currentJob = response.data;
        renderJob();
        setStatus("Itens pendentes cancelados.", "ok");
      })
      .fail(function (xhr) {
        setStatus("Falha ao cancelar fila: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function cancelJobItem(table) {
    if (!state.currentJob || !table) return;
    withGridLoading("#jobGrid", cancelJobRequest(table))
      .done(function (response) {
        if (!response || response.success === false) {
          setStatus("Falha ao cancelar item: " + apiError(response), "error");
          return;
        }
        state.currentJob = response.data;
        renderJob();
        setStatus(`Item ${table} cancelado.`, "ok");
      })
      .fail(function (xhr) {
        setStatus("Falha ao cancelar item: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function cancelJobRequest(table) {
    return $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify({
        resource: "job",
        action: "cancel",
        jobId: state.currentJob.id,
        table: table || ""
      })
    });
  }

  function reprocessJobItem(table) {
    if (!state.currentJob || !table) return;
    updateJobItem(table, "pending", "Aguardando reprocessamento", 0, 0)
      .then(function () {
        setStatus(`Item ${table} reenfileirado para reprocessamento.`, "ok");
        if (state.running) {
          scheduleJob();
        } else {
          runJob();
        }
      })
      .catch(function (error) {
        setStatus("Falha ao reenfileirar item: " + normalizeErrorMessage(error), "error");
      });
  }

  function reprocessAllJobErrors() {
    if (!state.currentJob) {
      setStatus("Crie ou carregue uma fila antes de reprocessar.", "error");
      return;
    }
    const errorCount = (state.currentJob.items || []).filter(function (item) {
      return item && item.status === "error";
    }).length;
    if (!errorCount) {
      setStatus("Nao ha itens com erro para reprocessar.", "");
      return;
    }

    withGridLoading("#jobGrid", $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify({
        resource: "job",
        action: "reprocess-errors",
        jobId: state.currentJob.id
      })
    })).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao reprocessar itens: " + apiError(response), "error");
        return;
      }
      state.currentJob = response.data;
      renderJob();
      setStatus(`${errorCount} item(ns) reenfileirado(s) para reprocessamento.`, "ok");
      if (state.running) {
        scheduleJob();
      } else {
        runJob();
      }
    }).fail(function (xhr) {
      setStatus("Falha ao reprocessar itens: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function processNext() {
    scheduleJob();
  }

  function scheduleJob() {
    if (!state.running || !state.currentJob || state.finishingJob) return;

    const limit = parallelExecutionCount();
    let started = 0;
    while (state.activeExecutions < limit) {
      const item = nextPendingJobItem();
      if (!item) break;
      startJobItem(item);
      started += 1;
    }

    if (state.activeExecutions === 0 && !nextPendingJobItem()) {
      finishJob();
      return;
    }

    if (started > 0) {
      setStatus(`Executando ${state.activeExecutions} de ${limit} simultaneas.`, "");
    }
  }

  function nextPendingJobItem() {
    const items = state.currentJob && Array.isArray(state.currentJob.items) ? state.currentJob.items : [];
    return items.find(function (row) {
      return row && row.status === "pending" && !state.runningTables[row.table || ""];
    }) || null;
  }

  function startJobItem(item) {
    const table = item && item.table ? item.table : "";
    if (!table || state.runningTables[table]) return;

    state.runningTables[table] = true;
    state.activeExecutions += 1;
    markLocalJobItem(table, "running", "Processando", 0, 0);
    renderJobItem(table);

    const work = processTable(table)
      .then(function (result) {
        return updateJobItem(table, "done", result.message, result.relationCount, result.viewAsCount);
      }, function (error) {
        return updateJobItem(table, "error", normalizeErrorMessage(error), 0, 0);
      })
      .then(null, function (error) {
        markLocalJobItem(table, "error", normalizeErrorMessage(error), 0, 0);
        renderJobItem(table);
        setStatus(`Falha ao atualizar item ${table}: ${normalizeErrorMessage(error)}`, "error");
      });

    work.always(function () {
      delete state.runningTables[table];
      state.activeExecutions = Math.max(0, state.activeExecutions - 1);
      if (state.running) {
        window.setTimeout(scheduleJob, 80);
      } else {
        renderJob();
      }
    });
  }

  function markLocalJobItem(table, status, message, relationCount, viewAsCount) {
    const items = state.currentJob && Array.isArray(state.currentJob.items) ? state.currentJob.items : [];
    const item = items.find(function (row) {
      return row && row.table === table;
    });
    if (!item) return;
    item.status = status;
    item.message = message;
    item.relationCount = relationCount;
    item.viewAsCount = viewAsCount;
  }

  function parallelExecutionCount() {
    const widget = $("#parallelExecutions").data("kendoNumericTextBox");
    const rawValue = widget ? widget.value() : $("#parallelExecutions").val();
    const count = parseInt(rawValue, 10);
    if (!Number.isFinite(count) || count < 1) {
      return 1;
    }
    return count;
  }

  function existingMetadataBehavior() {
    const widget = $("#existingMetadataBehavior").data("kendoDropDownList");
    const value = widget ? widget.value() : $("#existingMetadataBehavior").val();
    return value === "update" ? "update" : "skip";
  }

  function existingMetadataBehaviorLabel(value) {
    return value === "update" ? "Atualizar" : "Desconsiderar";
  }

  function shouldUpdateExistingMetadata() {
    return (state.currentJob && state.currentJob.existingMetadataBehavior === "update");
  }

  function loadExistingRelations(table, database) {
    return $.getJSON("relation-store.php?" + $.param(scope(table, database)))
      .then(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        return Array.isArray(response.data) ? response.data : [];
      });
  }

  function loadExistingViewAs(table, database) {
    const params = Object.assign(scope(table, database), { resource: "view-as" });
    return $.getJSON("metadata-store.php?" + $.param(params))
      .then(function (response) {
        if (!response || response.success === false) {
          throw new Error(apiError(response));
        }
        return Array.isArray(response.data) ? response.data : [];
      });
  }

  function metadataResultMessage(result) {
    const relations = result.relationsSkipped
      ? `joins existentes ${result.relationCount}`
      : `joins ${result.relationCount}`;
    const viewAs = result.viewAsSkipped
      ? `view-as existentes ${result.viewAsCount}`
      : `view-as ${result.viewAsCount}`;
    return `${relations}; ${viewAs}`;
  }

  function processTable(table) {
    const database = jobDatabase();
    if (!database || database === TODOS_DATABASE) {
      return $.Deferred()
        .reject(new Error("Banco da fila nao definido. Crie a fila novamente selecionando um banco especifico."))
        .promise();
    }
    setStatus(`Processando ${database}.${table}...`, "");
    const result = { relationCount: 0, viewAsCount: 0, relationsSkipped: false, viewAsSkipped: false, message: "" };
    return updateJobItem(table, "running", "Processando", 0, 0)
      .then(function () {
        if (!state.currentJob.includeRelations) return null;
        return shouldUpdateExistingMetadata() ? [] : loadExistingRelations(table, database);
      })
      .then(function (existingRelations) {
        if (!state.currentJob.includeRelations) return null;
        if (Array.isArray(existingRelations) && existingRelations.length > 0) {
          result.relationCount = existingRelations.length;
          result.relationsSkipped = true;
          return null;
        }
        const path = `/metadata/relations/of?table=${encodeURIComponent(table)}&database=${encodeURIComponent(database)}`;
        return getPasoeStepJson(path, `Buscar joins OF de ${database}.${table}`)
          .then(function (response) {
            const relations = Array.isArray(response.data) ? response.data : [];
            result.relationCount = relations.length;
            return saveRelations(table, database, relations);
          });
      })
      .then(function () {
        if (!state.currentJob.includeViewAs) return null;
        return shouldUpdateExistingMetadata() ? [] : loadExistingViewAs(table, database);
      })
      .then(function (existingViewAs) {
        if (!state.currentJob.includeViewAs) return null;
        if (Array.isArray(existingViewAs) && existingViewAs.length > 0) {
          result.viewAsCount = existingViewAs.length;
          result.viewAsSkipped = true;
          return null;
        }
        const path = `/metadata/tables/${encodeURIComponent(table)}/fields?database=${encodeURIComponent(database)}`;
        return getPasoeStepJson(path, `Buscar campos/view-as de ${database}.${table}`)
          .then(function (response) {
            const rows = (Array.isArray(response.data) ? response.data : []).map(function (field) {
              return {
                field: field.name || field.field || "",
                viewAs: field.viewAs || field.viewAS || field.view_as || "",
                listExpression: field.listExpression || "",
                options: Array.isArray(field.options) ? field.options : [],
                source: "PASOE"
              };
            }).filter(function (field) { return field.field && field.viewAs; });
            return resolveViewAsRows(table, database, rows);
          })
          .then(function (rows) {
            result.viewAsCount = rows.length;
            return saveViewAsRows(table, database, rows, "COMPILER");
          });
      })
      .then(function () {
        result.message = metadataResultMessage(result);
        setStatus(`${table}: ${result.message}.`, "ok");
        return result;
      });
  }

  function updateJobItem(table, status, message, relationCount, viewAsCount) {
    return $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify({
        resource: "job",
        action: "item",
        jobId: state.currentJob.id,
        table,
        status,
        message,
        relationCount,
        viewAsCount
      })
    }).then(function (response) {
      if (!response || response.success === false) throw new Error(apiError(response));
      state.currentJob = response.data;
      renderJobItem(table);
    });
  }

  function finishJob() {
    if (state.finishingJob) return;
    state.finishingJob = true;
    state.running = false;
    setBatchRunningUi(false);
    flushJobRender();
    withGridLoading("#jobGrid", $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify({ resource: "job", action: "finish", jobId: state.currentJob.id })
    })).done(function (response) {
      if (response && response.success) state.currentJob = response.data;
      renderJob();
      loadViewAsRows();
      loadRelationsRows();
      setStatus("Fila concluida.", "ok");
    }).always(function () {
      state.finishingJob = false;
      state.activeExecutions = 0;
      state.runningTables = Object.create(null);
      setBatchRunningUi(false);
    });
  }

  function saveRelations(table, database, relations) {
    return $.ajax({
      url: "relation-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, database), {
        source: "OF",
        relations
      }))
    }).then(function (response) {
      if (!response || response.success === false) {
        throw new Error(`Gravar joins OF no SQLite para ${database}.${table}. Detalhe: ${apiError(response)}`);
      }
    }, function (xhr) {
      throw new Error(`Gravar joins OF no SQLite para ${database}.${table}. Detalhe: ${ajaxErrorMessage(xhr)}`);
    });
  }

  function saveViewAsRows(table, database, rows, source) {
    return $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, database), {
        resource: "view-as",
        action: "save",
        source,
        rows
      }))
    }).then(function (response) {
      if (!response || response.success === false) {
        throw new Error(`Gravar view-as no SQLite para ${database}.${table}. Detalhe: ${apiError(response)}`);
      }
    }, function (xhr) {
      throw new Error(`Gravar view-as no SQLite para ${database}.${table}. Detalhe: ${ajaxErrorMessage(xhr)}`);
    });
  }

  function resolveViewAsRows(table, database, rows) {
    if (!rows.length) {
      return $.Deferred().resolve([]).promise();
    }
    return resolveViewAsRowsViaPasoe(table, database, rows);
  }

  function resolveViewAsRowsViaPasoe(table, database, rows) {
    return $.ajax({
      url: pasoeUrl("/metadata/view-as/resolve"),
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, database), {
        environment: viewAsResolverEnvironment(),
        rows
      }))
    }).then(function (response) {
      if (!response || response.success === false) {
        const code = response && response.error && response.error.code ? response.error.code : "";
        const hint = code === "NOT_FOUND"
          ? " Reinicie o PASOE para carregar o endpoint novo ou use a importacao CSV."
          : "";
        if (code === "NOT_FOUND") {
          return $.Deferred().reject(noFallbackError(`Resolver includes de view-as no PASOE para ${database}.${table}. Detalhe: ${apiError(response)}.${hint}`)).promise();
        }
        return $.Deferred().reject(noFallbackError(`Resolver includes de view-as no PASOE para ${database}.${table}. Detalhe: ${apiError(response)}`)).promise();
      }
      return normalizeResolvedViewAsRows(database, table, Array.isArray(response.data) ? response.data : rows, "PASOE");
    }, function (xhr) {
      return $.Deferred().reject(noFallbackError(`Resolver includes de view-as no PASOE para ${database}.${table}. Detalhe: ${ajaxErrorMessage(xhr)}. Verifique o PASOE ou use a importacao CSV.`)).promise();
    });
  }

  function normalizeResolvedViewAsRows(database, table, rows, source) {
    const resolvedRows = rows.map(function (row) {
      const next = Object.assign({ source }, row || {});
      next.listExpression = String(next.listExpression || "").trim();
      next.viewAs = next.viewAs || next.view_as || "";
      if (next.listExpression) {
        next.options = parseViewAsOptionsText(next.listExpression);
      } else if (!Array.isArray(next.options)) {
        next.options = [];
      }
      return next;
    });
    const resolverErrors = resolvedRows.filter(function (row) {
      return row && row.resolverError;
    }).map(function (row) {
      return `${row.include || row.field || "include"}: ${row.resolverError}`;
    });
    if (resolverErrors.length) {
      throw noFallbackError(`Resolver includes de view-as para ${database}.${table}. Detalhe: ${resolverErrors.slice(0, 3).join("; ")}`);
    }
    return resolvedRows;
  }

  function noFallbackError(message) {
    const error = new Error(message);
    error.noFallback = true;
    return error;
  }

  function viewAsResolverEnvironment() {
    const environment = currentEnvironment() || {};
    return {
      id: environment.id || "",
      servidor: environment.servidor || "",
      usuario: environment.usuario || "",
      senha: environment.senha || "",
      arquivoPf: environment.arquivoPf || environment.arquivo_pf || "",
      arquivoAlias: environment.arquivoAlias || environment.arquivo_alias || ""
    };
  }

  function openViewAsCreate() {
    state.editingViewAs = null;
    setInputValue("#viewAsTable", tableValue());
    setInputValue("#viewAsField", "");
    $("#viewAsValue").val("");
    $("#viewAsOptions").val("");
    if (viewAsWindow) {
      viewAsWindow.title("Incluir view-as");
      viewAsWindow.center().open();
    }
  }

  function openViewAsEdit(item) {
    if (!item) return;
    state.editingViewAs = {
      table: item.table || "",
      field: item.field || ""
    };
    setInputValue("#viewAsTable", item.table || tableValue());
    setInputValue("#viewAsField", item.field || "");
    $("#viewAsValue").val(item.viewAs || "");
    $("#viewAsOptions").val(viewAsOptionsText(item));
    if (viewAsWindow) {
      viewAsWindow.title("Alterar view-as");
      viewAsWindow.center().open();
    }
  }

  function saveManualViewAs() {
    const table = inputValue("#viewAsTable") || tableValue();
    const field = inputValue("#viewAsField");
    const listExpression = String($("#viewAsOptions").val() || "").trim();
    const viewAs = String($("#viewAsValue").val() || "").trim();
    if (!table || !field) {
      setStatus("Informe tabela e campo para salvar view-as.", "error");
      return;
    }

    const original = state.editingViewAs;
    const keyChanged = original
      && (String(original.table || "").toLowerCase() !== table.toLowerCase()
        || String(original.field || "").toLowerCase() !== field.toLowerCase());

    const saveRequest = function () {
      return $.ajax({
        url: "metadata-store.php",
        method: "POST",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        data: JSON.stringify(Object.assign(scope(table, selectedDatabase()), {
          resource: "view-as",
          action: "save",
	          source: "manual",
	          field,
	          viewAs,
	          listExpression,
	          options: parseViewAsOptionsText(listExpression)
	        }))
      });
    };

    const request = keyChanged
      ? deleteViewAsRequest(original.table, original.field).then(function (response) {
        if (!response || response.success === false) {
          return $.Deferred().reject({ responseJSON: response }).promise();
        }
        return saveRequest();
      })
      : saveRequest();

    withGridLoading("#viewAsGrid", request).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao salvar view-as: " + apiError(response), "error");
        return;
      }
      state.editingViewAs = null;
      if (viewAsWindow) viewAsWindow.close();
      setStatus("View-as salvo.", "ok");
      loadViewAsRows(tableValue() || table);
    }).fail(function (xhr) {
      setStatus("Falha ao salvar view-as: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function deleteViewAsRequest(table, field) {
    return $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, selectedDatabase()), {
        resource: "view-as",
        action: "delete",
        field
      }))
    });
  }

  function deleteViewAsRow(item) {
    if (!item || !item.table || !item.field) {
      return;
    }
    if (!window.confirm("Excluir o view-as selecionado?")) {
      return;
    }
    withGridLoading("#viewAsGrid", deleteViewAsRequest(item.table, item.field)).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao excluir view-as: " + apiError(response), "error");
        return;
      }
      setStatus("View-as excluido.", "ok");
      loadViewAsRows(tableValue() || item.table);
    }).fail(function (xhr) {
      setStatus("Falha ao excluir view-as: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function loadViewAsRows(table) {
    if (!hasElement("#viewAsGrid")) return;
    const database = selectedDatabase();
    const targetTable = table || tableValue();
    const params = Object.assign(scope(targetTable, database), { resource: "view-as", includeLegacy: "1" });
    const requestTables = viewAsRequestTableNames(database, targetTable);
    setStatus(targetTable ? `Carregando view-as de ${targetTable}...` : "Carregando registros de view-as...", "");
    withGridLoading("#viewAsGrid", viewAsRowsRequest(params, requestTables))
      .done(function (response) {
        const rows = filterViewAsRowsForSelectedDatabase(response && response.success ? response.data || [] : [], database, targetTable);
        const loadedTables = uniqueTableNames(rows.map(function (row) { return row && row.table; }));
        state.viewAsTables = targetTable ? uniqueTableNames([].concat(state.viewAsTables || [], loadedTables, targetTable)) : loadedTables;
        refreshTableCombo();
        const grid = $("#viewAsGrid").data("kendoGrid");
        grid.dataSource.data(rows);
        grid.dataSource.page(1);
        updateViewAsSummary(rows, targetTable);
        setStatus(viewAsLoadMessage(rows, targetTable), "ok");
      })
      .fail(function (xhr) {
        setStatus("Falha ao carregar view-as: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function viewAsRowsRequest(params, tableNames) {
    if (Array.isArray(tableNames) && tableNames.length) {
      return $.ajax({
        url: "metadata-store.php",
        method: "POST",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        data: JSON.stringify(Object.assign({}, params, {
          action: "list",
          tableNames
        }))
      });
    }
    return $.getJSON("metadata-store.php?" + $.param(params));
  }

  function viewAsRequestTableNames(database, table) {
    if (table) return [];
    const selected = String(database || "").trim();
    if (!selected || selected === TODOS_DATABASE) return [];
    return uniqueTableNames(state.tables || []);
  }

  function updateViewAsSummary(rows, table) {
    if (!hasElement("#resultSummary")) return;
    const tableCount = uniqueTableNames(rows.map(function (row) { return row && row.table; })).length;
    const tableText = table ? ` da tabela ${escapeHtml(table)}` : "";
    $("#resultSummary").html(
      `${rows.length} registro(s) de view-as${tableText}; ${tableCount} tabela(s) distinta(s).`
    );
  }

  function viewAsLoadMessage(rows, table) {
    const tableCount = uniqueTableNames(rows.map(function (row) { return row && row.table; })).length;
    if (table) {
      return `View-as carregado: ${rows.length} registro(s) da tabela ${table}.`;
    }
    return `View-as carregado: ${rows.length} registro(s), ${tableCount} tabela(s) distinta(s).`;
  }

  function viewAsOptionsText(item) {
    if (!item) return "";
    const expression = String(item.listExpression || "").trim();
    if (expression) return expression;
    if (Array.isArray(item.options) && item.options.length) {
      return item.options.map(function (option) {
        if (!option || typeof option !== "object") return "";
        const label = option.label != null ? option.label : option.text;
        const value = option.value != null ? option.value : label;
        return quoteOptionToken(label) + "," + quoteOptionToken(value);
      }).filter(Boolean).join(",");
    }
    return "";
  }

  function parseViewAsOptionsText(listExpression) {
    const expression = String(listExpression || "").trim();
    if (!expression) return [];
    const tokens = csvTokens(expression);
    if (!tokens.length) return [];
    const options = [];
    for (let index = 0; index < tokens.length; index += 2) {
      const label = tokens[index] || "";
      const value = tokens[index + 1] != null ? tokens[index + 1] : label;
      if (label !== "") {
        options.push({ label, value });
      }
    }
    return options;
  }

  function csvTokens(value) {
    const tokens = [];
    let token = "";
    let quoted = false;
    const text = String(value || "");
    for (let index = 0; index < text.length; index += 1) {
      const char = text.charAt(index);
      if (char === '"') {
        if (quoted && text.charAt(index + 1) === '"') {
          token += '"';
          index += 1;
        } else {
          quoted = !quoted;
        }
      } else if (char === "," && !quoted) {
        tokens.push(cleanOptionToken(token));
        token = "";
      } else {
        token += char;
      }
    }
    tokens.push(cleanOptionToken(token));
    return tokens.filter(function (item) { return item !== ""; });
  }

  function cleanOptionToken(value) {
    return String(value || "")
      .trim()
      .replace(/^['"]|['"]$/g, "")
      .replace(/\s+(HORIZONTAL|VERTICAL|SIZE|FONT|FORMAT|NO-UNDO|HELP|TOOLTIP)\b.*$/i, "")
      .trim();
  }

  function quoteOptionToken(value) {
    const text = String(value == null ? "" : value);
    return '"' + text.replace(/"/g, '""') + '"';
  }

  function filterViewAsRowsForSelectedDatabase(rows, database, table) {
    const selected = String(database || "").trim().toLowerCase();
    if (!selected || selected === TODOS_DATABASE.toLowerCase()) {
      return rows;
    }
    const selectedTables = Object.create(null);
    (state.tables || []).forEach(function (name) {
      selectedTables[String(name || "").trim().toLowerCase()] = true;
    });
    return rows.filter(function (row) {
      const rowDatabase = String(row && row.database || "").trim().toLowerCase();
      if (rowDatabase) {
        return rowDatabase === selected;
      }
      if (table) {
        return true;
      }
      const rowTable = String(row && row.table || "").trim().toLowerCase();
      return Boolean(selectedTables[rowTable]);
    });
  }

  function importViewAsCsvFile() {
    const file = this.files && this.files.length ? this.files[0] : null;
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function () {
      importViewAsCsv(String(reader.result || ""));
    };
    reader.onerror = function () {
      setStatus("Falha ao ler arquivo CSV de view-as.", "error");
    };
    reader.readAsText(file, "UTF-8");
  }

  function importViewAsCsv(csvText) {
    if (!String(csvText || "").trim()) {
      setStatus("Arquivo CSV de view-as vazio.", "error");
      return;
    }
    withGridLoading("#viewAsGrid", $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(tableValue(), selectedDatabase()), {
        resource: "view-as",
        action: "import-csv",
        csvText
      }))
    })).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao importar CSV de view-as: " + apiError(response), "error");
        return;
      }
      const rows = Array.isArray(response.data) ? response.data : [];
      $("#viewAsGrid").data("kendoGrid").dataSource.data(rows);
      setStatus(`CSV de view-as importado: ${rows.length} registro(s).`, "ok");
    }).fail(function (xhr) {
      setStatus("Falha ao importar CSV de view-as: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function openRelationCreate() {
    state.editingRelation = null;
    setInputValue("#leftTable", tableValue());
    setInputValue("#leftField", "");
    setInputValue("#rightTable", "");
    setInputValue("#rightField", "");
    $("#relationType").data("kendoDropDownList").value("INNER");
    if (relationWindow) {
      relationWindow.title("Incluir join");
      relationWindow.center().open();
    }
  }

  function openRelationEdit(item) {
    if (!item) return;
    state.editingRelation = {
      id: item.id || "",
      leftTable: item.leftTable || ""
    };
    setInputValue("#leftTable", item.leftTable || tableValue());
    setInputValue("#leftField", item.leftField || "");
    setInputValue("#rightTable", item.rightTable || "");
    setInputValue("#rightField", item.rightField || "");
    $("#relationType").data("kendoDropDownList").value(item.type || "INNER");
    if (relationWindow) {
      relationWindow.title("Alterar join");
      relationWindow.center().open();
    }
  }

  function saveManualRelation() {
    const database = selectedDatabase();
    const leftTable = inputValue("#leftTable") || tableValue();
    const rightTable = inputValue("#rightTable");
    const leftField = inputValue("#leftField");
    const rightField = inputValue("#rightField");
    if (!leftTable || !rightTable || !leftField || !rightField) {
      setStatus("Informe tabelas e campos do join.", "error");
      return;
    }
    const relation = {
      database,
      leftDatabase: database,
      leftTable,
      leftField,
      rightDatabase: database,
      rightTable,
      rightField,
      type: $("#relationType").data("kendoDropDownList").value() || "INNER",
      source: "manual",
      fields: [{ leftField, rightField }]
    };
    withGridLoading("#relationsGrid", $.ajax({
      url: "relation-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(leftTable, database), {
        source: "manual",
        replaceId: state.editingRelation && state.editingRelation.id ? state.editingRelation.id : "",
        relations: [relation]
      }))
    })).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao salvar join: " + apiError(response), "error");
        return;
      }
      state.editingRelation = null;
      if (relationWindow) relationWindow.close();
      setStatus("Join salvo.", "ok");
      loadRelationsRows(tableValue() || leftTable);
    }).fail(function (xhr) {
      setStatus("Falha ao salvar join: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function deleteRelationRow(item) {
    if (!item || !item.id) {
      return;
    }
    if (!window.confirm("Excluir o join selecionado?")) {
      return;
    }
    const table = tableValue() || item.leftTable || item.rightTable;
    withGridLoading("#relationsGrid", $.ajax({
      url: "relation-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, selectedDatabase()), {
        action: "delete",
        id: item.id
      }))
    })).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao excluir join: " + apiError(response), "error");
        return;
      }
      setStatus("Join excluido.", "ok");
      loadRelationsRows(table);
    }).fail(function (xhr) {
      setStatus("Falha ao excluir join: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function loadRelationsRows(table) {
    if (!hasElement("#relationsGrid")) return;
    const database = selectedDatabase();
    const targetTable = table || tableValue();
    if (!database || !targetTable) {
      $("#relationsGrid").data("kendoGrid").dataSource.data([]);
      return;
    }
    withGridLoading("#relationsGrid", $.getJSON("relation-store.php?" + $.param(scope(targetTable, database))))
      .done(function (response) {
        const rows = response && response.success ? response.data || [] : [];
        $("#relationsGrid").data("kendoGrid").dataSource.data(rows);
      })
      .fail(function (xhr) {
        setStatus("Falha ao carregar joins: " + ajaxErrorMessage(xhr), "error");
      });
  }

  function renderJob() {
    const options = arguments.length ? arguments[0] || {} : {};
    if (state.running && !options.immediate) {
      scheduleJobRender();
      return;
    }
    renderJobNow();
  }

  function scheduleJobRender() {
    state.jobRenderPending = true;
    if (state.jobRenderTimer) return;
    state.jobRenderTimer = window.setTimeout(function () {
      state.jobRenderTimer = null;
      if (!state.jobRenderPending) return;
      state.jobRenderPending = false;
      renderJobNow();
    }, 160);
  }

  function flushJobRender() {
    if (state.jobRenderTimer) {
      window.clearTimeout(state.jobRenderTimer);
      state.jobRenderTimer = null;
    }
    state.jobRenderPending = false;
    renderJobNow();
  }

  function renderJobNow() {
    if (!hasElement("#jobGrid")) return;
    syncJobGridRows(filteredJobRows());
    renderJobSummary();
  }

  function renderJobItem(table) {
    if (!hasElement("#jobGrid")) return;
    if (!table || jobGridFiltersActive()) {
      renderJob({ immediate: true });
      return;
    }
    syncJobGridRow(table);
    renderJobSummary();
  }

  function filteredJobRows() {
    const job = state.currentJob;
    let rows = job && Array.isArray(job.items) ? job.items : [];
    const visibleStatuses = selectedJobGridStatuses();
    if (visibleStatuses.length) {
      rows = rows.filter(function (item) { return item && visibleStatuses.indexOf(item.status) >= 0; });
    }
    return rows;
  }

  function selectedJobGridStatuses() {
    const visibleStatuses = [];
    if ($("#showPendingOnly").is(":checked")) visibleStatuses.push("pending");
    if ($("#showErrorOnly").is(":checked")) visibleStatuses.push("error");
    return visibleStatuses;
  }

  function jobGridFiltersActive() {
    return selectedJobGridStatuses().length > 0;
  }

  function renderJobSummary() {
    const job = state.currentJob;
    if (!job) {
      $("#jobSummary").text("Nenhuma fila criada.");
      return;
    }
    $("#jobSummary").html(
      `Status: <strong>${escapeHtml(job.status)}</strong><br>` +
      `Banco: ${escapeHtml(job.database)}<br>` +
      `Existentes: ${escapeHtml(existingMetadataBehaviorLabel(job.existingMetadataBehavior))}<br>` +
      `Processadas: ${job.processedTables}/${job.totalTables}<br>` +
      `Canceladas: ${job.cancelledTables || 0}<br>` +
      `Erros: ${job.failedTables}`
    );
  }

  function syncJobGridRow(table) {
    const grid = $("#jobGrid").data("kendoGrid");
    const job = state.currentJob;
    const rows = job && Array.isArray(job.items) ? job.items : [];
    const row = rows.find(function (item) { return item && item.table === table; });
    if (!grid || !row) {
      renderJob({ immediate: true });
      return;
    }
    const current = grid.dataSource.data();
    let model = null;
    for (let index = 0; index < current.length; index += 1) {
      if (current[index] && current[index].table === table) {
        model = current[index];
        break;
      }
    }
    if (!model) {
      renderJob({ immediate: true });
      return;
    }
    updateJobGridModel(model, row);
  }

  function syncJobGridRows(rows) {
    const grid = $("#jobGrid").data("kendoGrid");
    if (!grid) return;
    const dataSource = grid.dataSource;
    const current = dataSource.data();
    const sameShape = current.length === rows.length && rows.every(function (row, index) {
      return current[index] && current[index].table === row.table;
    });
    if (!sameShape) {
      dataSource.data(rows);
      return;
    }

    rows.forEach(function (row, index) {
      updateJobGridModel(current[index], row);
    });
  }

  function updateJobGridModel(model, row) {
    if (!model || !row) return;
    updateGridModel(model, "status", row.status);
    updateGridModel(model, "message", row.message);
    updateGridModel(model, "relationCount", row.relationCount);
    updateGridModel(model, "viewAsCount", row.viewAsCount);
    updateGridModel(model, "updatedAt", row.updatedAt);
  }

  function updateGridModel(model, field, value) {
    if (!model) return;
    const current = typeof model.get === "function" ? model.get(field) : model[field];
    if (current === value) return;
    if (typeof model.set === "function") {
      model.set(field, value);
    } else {
      model[field] = value;
    }
  }

  function selectedDatabase() {
    const combo = $("#dbCombo").data("kendoComboBox");
    return combo ? String(combo.value() || "") : "";
  }

  function jobDatabase() {
    const jobValue = state.currentJob && state.currentJob.database ? String(state.currentJob.database || "").trim() : "";
    return jobValue || selectedDatabase();
  }

  function tableValue() {
    const combo = $("#tableName").data("kendoComboBox");
    return String(combo ? combo.value() : $("#tableName").val() || "").trim();
  }

  function refreshTableCombo() {
    const combo = $("#tableName").data("kendoComboBox");
    if (!combo) return;
    const current = combo.value();
    combo.setDataSource(new kendo.data.DataSource({ data: combinedTableNames() }));
    if (current) combo.value(current);
  }

  function combinedTableNames() {
    return uniqueTableNames([].concat(state.tables || [], state.viewAsTables || []));
  }

  function tableNameFromMetadataItem(item) {
    if (!item || typeof item !== "object") {
      return String(item || "").trim();
    }
    return String(item.table || item.tableName || item.name || "").trim();
  }

  function uniqueTableNames(rows) {
    const seen = Object.create(null);
    return rows.map(function (item) {
      return String(item || "").trim();
    }).filter(function (name) {
      const key = name.toLowerCase();
      if (!name || seen[key]) return false;
      seen[key] = true;
      return true;
    }).sort(function (left, right) {
      return left.localeCompare(right, "pt-BR", { sensitivity: "base" });
    });
  }

  function scope(table, database) {
    const environment = window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function"
      ? SursumContext.getCurrentEnvironment()
      : null;
    const company = selectedCompany();
    return {
      environmentId: environment && environment.id ? environment.id : "",
      companyId: company && company.id ? company.id : "",
      database: database || selectedDatabase() || "",
      table: table || ""
    };
  }

  function companiesForSelection() {
    const config = window.SursumContext && typeof SursumContext.getConfig === "function" ? SursumContext.getConfig() : null;
    const environment = currentEnvironment();
    if (config && environment && Array.isArray(config.companies)) {
      return config.companies.filter(function (item) { return item.environmentId === environment.id; });
    }
    return [];
  }

  function currentEnvironment() {
    if (window.SursumContext && typeof SursumContext.getCurrentEnvironment === "function") {
      return SursumContext.getCurrentEnvironment();
    }
    return null;
  }

  function selectedCompany() {
    return selectedCompanyFromId(state.selectedCompanyId)
      || selectedCompanyFromContext()
      || companiesForSelection()[0]
      || null;
  }

  function selectedCompanyFromId(companyId) {
    const companies = companiesForSelection();
    const selectedId = String(companyId || "").trim();
    if (!selectedId) return null;
    return companies.find(function (item) { return item.id === selectedId; }) || null;
  }

  function selectedCompanyFromContext() {
    const company = window.SursumContext && typeof SursumContext.getCurrentCompany === "function"
      ? SursumContext.getCurrentCompany()
      : null;
    return selectedCompanyFromId(company && company.id ? company.id : "");
  }

  function applyCompanySelection(companyId) {
    const companies = companiesForSelection();
    const company = companies.find(function (item) { return item.id === companyId; }) || null;
    if (!company) {
      refreshContext();
      return;
    }
    state.selectedCompanyId = company.id;
    localStorage.setItem("sursumSelectedQueryCompany", company.id);
    if (window.SursumContext && typeof SursumContext.setSelection === "function") {
      SursumContext.setSelection(company.clientId || "", company.environmentId || "", company.id);
    } else {
      refreshContext();
      state.contextKey = metadataContextKey();
      loadDatabases(true);
    }
  }

  function endpointUrl(endpoint) {
    if (window.SursumContext && typeof SursumContext.resolveApiBase === "function") {
      return SursumContext.resolveApiBase(endpoint, selectedCompany()) || DEFAULT_API;
    }
    return endpoint && (endpoint.pasoeBaseUrl || endpoint.url) ? endpoint.pasoeBaseUrl || endpoint.url : DEFAULT_API;
  }

  function pasoeUrl(path, options) {
    const target = pasoeDirectUrl(path, options);
    return shouldUsePasoeProxy(target) ? PASOE_PROXY + "?target=" + encodeURIComponent(target) : target;
  }

  function pasoeDirectUrl(path, options) {
    const base = String(state.apiBase || DEFAULT_API).replace(/\/+$/, "");
    const suffix = String(path || "").replace(/^\/+/, "");
    let target = base + "/" + suffix;
    if (window.SursumContext && typeof window.SursumContext.getRequestConfig === "function") {
      const request = window.SursumContext.getRequestConfig(target, options || {});
      target = request && request.url ? request.url : target;
    }
    return target;
  }

  function getPasoeJson(path, options) {
    const deferred = $.Deferred();
    $.getJSON(metadataProxyUrl(path))
      .done(function (response) {
        deferred.resolve(response);
      })
      .fail(function (metadataXhr) {
        getPasoeJsonFallback(path, options)
          .done(function (response) {
            deferred.resolve(response);
          })
          .fail(function (xhr) {
            const message = "metadata-pasoe: " + ajaxErrorMessage(metadataXhr) + " | fallback: " + ajaxErrorMessage(xhr);
            deferred.reject({ responseText: message, statusText: message });
          });
      });
    return deferred.promise();
  }

  function getPasoeStepJson(path, label) {
    const endpoint = pasoeDirectUrl(path);
    return getPasoeJson(path)
      .then(function (response) {
        if (!response || response.success === false) {
          throw new Error(`${label}. Endpoint: ${endpoint}. Detalhe: ${apiError(response)}`);
        }
        if (response.warning && !isEmptyPasoeSuccess(response)) {
          throw new Error(`${label}. Endpoint: ${endpoint}. Detalhe: ${response.warning}`);
        }
        return response;
      }, function (xhr) {
        throw new Error(`${label}. Endpoint: ${endpoint}. Detalhe: ${ajaxErrorMessage(xhr)}`);
      });
  }

  function isEmptyPasoeSuccess(response) {
    return response
      && response.success !== false
      && Array.isArray(response.data)
      && response.data.length === 0
      && /corpo vazio/i.test(String(response.warning || ""));
  }

  function getPasoeJsonFallback(path, options) {
    const deferred = $.Deferred();
    const directUrl = pasoeDirectUrl(path, options);
    const proxiedUrl = shouldUsePasoeProxy(directUrl) ? PASOE_PROXY + "?target=" + encodeURIComponent(directUrl) : directUrl;
    $.getJSON(proxiedUrl)
      .done(function (response) {
        deferred.resolve(response);
      })
      .fail(function (proxyXhr) {
        if (proxiedUrl === directUrl) {
          deferred.reject(proxyXhr);
          return;
        }
        $.getJSON(directUrl)
          .done(function (response) {
            deferred.resolve(response);
          })
          .fail(function (directXhr) {
            const message = "proxy: " + ajaxErrorMessage(proxyXhr) + " | direto: " + ajaxErrorMessage(directXhr);
            deferred.reject({ responseText: message, statusText: message });
          });
      });
    return deferred.promise();
  }

  function metadataProxyUrl(path) {
    const currentScope = scope("", selectedDatabase());
    return "metadata-pasoe.php?"
      + "environmentId=" + encodeURIComponent(currentScope.environmentId)
      + "&companyId=" + encodeURIComponent(currentScope.companyId)
      + "&path=" + encodeURIComponent(path);
  }

  function shouldUsePasoeProxy(url) {
    try {
      const parsed = new URL(url, window.location.href);
      return /^https?:$/.test(parsed.protocol) && parsed.origin !== window.location.origin;
    } catch (_) {
      return false;
    }
  }

  function apiError(response) {
    if (!response) return "resposta vazia";
    if (typeof response.error === "string") return response.error;
    if (response.error && response.error.message) return response.error.message;
    return "erro";
  }

  function ajaxErrorMessage(xhr) {
    if (xhr && xhr.responseJSON) {
      const message = apiError(xhr.responseJSON);
      const target = xhr.responseJSON.target ? " Target: " + xhr.responseJSON.target : "";
      const status = xhr.status ? " HTTP " + xhr.status + "." : "";
      return message + status + target;
    }
    const body = xhr && xhr.responseText ? String(xhr.responseText) : "";
    if (body) return body.slice(0, 220);
    if (xhr && xhr.status) return "HTTP " + xhr.status + (xhr.statusText ? " " + xhr.statusText : "");
    return xhr && xhr.statusText ? xhr.statusText : "erro";
  }

  function normalizeErrorMessage(error) {
    if (!error) return "Erro sem detalhe retornado.";
    if (error.message) return String(error.message);
    return ajaxErrorMessage(error);
  }

  function setStatus(message, type) {
    $("#statusBox").removeClass("ok error").addClass(type || "").text(message);
  }

  function inputValue(selector) {
    const widget = $(selector).data("kendoTextBox");
    const value = widget && typeof widget.value === "function" ? widget.value() : $(selector).val();
    return String(value || "").trim();
  }

  function setInputValue(selector, value) {
    const widget = $(selector).data("kendoTextBox");
    if (widget && typeof widget.value === "function") {
      widget.value(value || "");
      return;
    }
    $(selector).val(value || "");
  }

  function gridRowData(gridSelector, element) {
    const grid = $(gridSelector).data("kendoGrid");
    if (!grid) return null;
    return grid.dataItem($(element).closest("tr"));
  }

  function initGridActionButtons(container, selector) {
    $(container).find(selector).each(function () {
      const button = $(this);
      if (!button.data("kendoButton")) button.kendoButton();
    });
  }

  function setGridLoading(selector, loading) {
    const target = $(selector);
    const grid = target.data("kendoGrid");
    const wrapper = grid && grid.wrapper ? grid.wrapper : target;
    wrapper.toggleClass("metadata-grid-loading", Boolean(loading));
    if (window.SursumGridLoading && typeof window.SursumGridLoading.set === "function") {
      window.SursumGridLoading.set(selector, loading);
    }
  }

  function setBatchRunningUi(running) {
    if (!document.body) return;
    document.body.classList.toggle("sursum-silent-grid-ajax", Boolean(running));
  }

  function withGridLoading(selector, request) {
    setGridLoading(selector, true);
    if (request && typeof request.always === "function") {
      request.always(function () {
        setGridLoading(selector, false);
      });
    } else {
      setGridLoading(selector, false);
    }
    return request;
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function formatBrazilianDateTime(value) {
    const text = String(value == null ? "" : value).trim();
    if (!text) return "";

    const match = text.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2})(?::(\d{2}))?)?/);
    if (!match) return text;

    const date = `${match[3]}/${match[2]}/${match[1]}`;
    if (!match[4]) return date;
    return `${date} ${match[4]}:${match[5]}:${match[6] || "00"}`;
  }
})();
