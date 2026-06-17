(function () {
  const DEFAULT_API = "http://localhost:8890/web/SursumDynamicQuery";
  const PASOE_PROXY = "pasoe-proxy.php";
  const TODOS_DATABASE = "Selecionar";
  const LAST_JOB_KEY = "sursumMetadataMaintenanceLastJob";

  const state = {
    apiBase: DEFAULT_API,
    databases: [],
    tables: [],
    currentJob: null,
    running: false,
    selectedCompanyId: localStorage.getItem("sursumSelectedQueryCompany") || ""
  };

  $(function () {
    initWidgets();
    bindEvents();
    refreshContext();
    loadDatabases(false);
    loadLastJob();
  });

  function initWidgets() {
    ensureBatchControls();
    $("#metadataTabs").kendoTabStrip({ animation: false }).data("kendoTabStrip").select(0);
    $("#apiCompany").kendoComboBox({
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
    $("#dbCombo").kendoComboBox({
      dataTextField: "name",
      dataValueField: "name",
      filter: "contains",
      change: function () {
        loadTables();
        loadViewAsRows();
        loadRelationsRows();
      }
    });
    $("#tableName").kendoComboBox({
      dataSource: [],
      filter: "contains",
      suggest: true,
      placeholder: "Opcional para manutencao manual",
      change: function () {
        const table = tableValue();
        $("#viewAsTable,#leftTable").val(table);
        loadViewAsRows();
        loadRelationsRows();
      }
    });
    $("#relationType").kendoDropDownList({ dataSource: ["INNER", "LEFT"], value: "INNER" });
    $("#createJob,#runJob,#pauseJob,#cancelJob,#reloadTables,#openTableBrowser,#saveViewAs,#deleteViewAs,#loadViewAs,#saveRelation,#loadRelations").kendoButton();
    $("#jobGrid").kendoGrid({
      dataSource: [],
      height: 390,
      sortable: true,
      dataBound: function () {
        this.tbody.find(".cancel-job-item,.reprocess-job-item").each(function () {
          const button = $(this);
          if (!button.data("kendoButton")) button.kendoButton();
        });
      },
      toolbar: [
        {
          template: '<div class="job-grid-filters">'
            + '<label class="job-grid-switch"><input id="showPendingOnly" type="checkbox"><span class="switch-control"></span><span class="switch-label">Mostrar apenas pendentes</span></label>'
            + '<label class="job-grid-switch"><input id="showErrorOnly" type="checkbox"><span class="switch-control"></span><span class="switch-label">Mostrar apenas com erro</span></label>'
            + '</div>'
        }
      ],
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
    $("#viewAsGrid").kendoGrid({
      dataSource: [],
      height: 390,
      sortable: true,
      selectable: "row",
      change: function () {
        const item = this.dataItem(this.select());
        if (!item) return;
        $("#viewAsTable").val(item.table || "");
        $("#viewAsField").val(item.field || "");
        $("#viewAsValue").val(item.viewAs || "");
      },
      columns: [
        { field: "table", title: "Tabela", width: 180 },
        { field: "field", title: "Campo", width: 180 },
        { field: "viewAs", title: "View-as" },
        { field: "source", title: "Origem", width: 110 },
        { field: "updatedAt", title: "Atualizado em", width: 190 }
      ]
    });
    $("#relationsGrid").kendoGrid({
      dataSource: [],
      height: 390,
      sortable: true,
      columns: [
        { field: "leftTable", title: "Tabela esq.", width: 160 },
        { field: "leftField", title: "Campo esq.", width: 150 },
        { field: "rightTable", title: "Tabela dir.", width: 160 },
        { field: "rightField", title: "Campo dir.", width: 150 },
        { field: "type", title: "Tipo", width: 90 },
        { field: "source", title: "Origem", width: 110 },
        { field: "updatedAt", title: "Atualizado em", width: 190 }
      ]
    });
  }

  function ensureBatchControls() {
    const actionRow = $(".metadata-batch-options .action-row").first();
    if (actionRow.length && !$("#cancelJob").length) {
      actionRow.prepend('<button id="cancelJob">Cancelar pendentes</button>');
    }
    $(".job-control-row").remove();
  }

  function bindEvents() {
    window.addEventListener("sursum:context-changed", function () {
      refreshContext();
      loadDatabases(true);
    });
    $("#reloadTables").on("click", function () { loadTables(true); });
    $("#openTableBrowser").on("click", function () { window.location.href = "table-browser.html"; });
    $("#createJob").on("click", createJob);
    $("#runJob").on("click", function () { runJob(); });
    $("#pauseJob").on("click", pauseJob);
    $("#cancelJob").on("click", cancelPendingJobItems);
    $("#showPendingOnly,#showErrorOnly").on("change", renderJob);
    $("#jobGrid").on("click", ".cancel-job-item", function () {
      cancelJobItem($(this).attr("data-table") || "");
    });
    $("#jobGrid").on("click", ".reprocess-job-item", function () {
      reprocessJobItem($(this).attr("data-table") || "");
    });
    $("#saveViewAs").on("click", saveManualViewAs);
    $("#deleteViewAs").on("click", deleteManualViewAs);
    $("#loadViewAs").on("click", loadViewAsRows);
    $("#saveRelation").on("click", saveManualRelation);
    $("#loadRelations").on("click", loadRelationsRows);
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

  function loadDatabases(forceReload) {
    setStatus("Carregando bancos...", "");
    $.getJSON(pasoeUrl(forceReload ? "/metadata/databases/sync" : "/metadata/database-catalog"))
      .done(function (response) {
        if (!response || response.success === false) throw new Error(apiError(response));
        const rows = Array.isArray(response.data) ? response.data : [];
        state.databases = [{ name: TODOS_DATABASE }].concat(rows.map(function (item) {
          return { name: item.name || item.logicalName || item.displayName || "" };
        }).filter(function (item) { return item.name; }));
        const combo = $("#dbCombo").data("kendoComboBox");
        combo.setDataSource(new kendo.data.DataSource({ data: state.databases }));
        if (!combo.value()) combo.value(state.databases[0] ? state.databases[0].name : TODOS_DATABASE);
        state.tables = [];
        refreshTableCombo();
        setStatus("Bancos carregados. Selecione um banco para carregar tabelas.", "ok");
      })
      .fail(function (xhr) {
        setStatus("Falha ao carregar bancos: " + ajaxErrorMessage(xhr), "error");
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
        state.tables = (Array.isArray(response.data) ? response.data : []).map(function (item) {
          return item.name || item.table || item.tableName || "";
        }).filter(Boolean);
        refreshTableCombo();
        setStatus(`Tabelas carregadas: ${state.tables.length}.`, "ok");
      })
      .fail(function (xhr) {
        loadTablesBySync(database)
          .done(function (rows) {
            state.tables = rows;
            refreshTableCombo();
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
        const rows = (tableStep && Array.isArray(tableStep.data) ? tableStep.data : [])
          .map(function (item) { return item.name || item.table || item.tableName || ""; })
          .filter(Boolean);
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
    $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope("", database), {
        resource: "job",
        action: "create",
        tables,
        includeRelations: $("#includeRelations").is(":checked"),
        includeViewAs: $("#includeViewAs").is(":checked")
      }))
    }).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao criar fila: " + apiError(response), "error");
        return;
      }
      state.currentJob = response.data;
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
    processNext();
  }

  function loadLastJob() {
    const jobId = localStorage.getItem(LAST_JOB_KEY);
    if (!jobId) return;
    $.getJSON("metadata-store.php?resource=job&id=" + encodeURIComponent(jobId))
      .done(function (response) {
        if (!response || !response.success || !response.data) return;
        state.currentJob = response.data;
        renderJob();
      });
  }

  function pauseJob() {
    state.running = false;
    setStatus("Execucao pausada.", "");
  }

  function cancelPendingJobItems() {
    if (!state.currentJob) {
      setStatus("Crie ou carregue uma fila antes de cancelar.", "error");
      return;
    }
    state.running = false;
    cancelJobRequest("")
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
    cancelJobRequest(table)
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
        if (!state.running) {
          runJob();
        }
      })
      .catch(function (error) {
        setStatus("Falha ao reenfileirar item: " + normalizeErrorMessage(error), "error");
      });
  }

  function processNext() {
    if (!state.running || !state.currentJob) return;
    const item = (state.currentJob.items || []).find(function (row) { return row.status === "pending"; });
    if (!item) {
      finishJob();
      return;
    }
    processTable(item.table)
      .then(function (result) {
        return updateJobItem(item.table, "done", result.message, result.relationCount, result.viewAsCount);
      })
      .catch(function (error) {
        return updateJobItem(item.table, "error", normalizeErrorMessage(error), 0, 0);
      })
      .then(function () {
        if (state.running) window.setTimeout(processNext, 80);
      });
  }

  function processTable(table) {
    const database = selectedDatabase();
    setStatus(`Processando ${database}.${table}...`, "");
    const result = { relationCount: 0, viewAsCount: 0, message: "" };
    return updateJobItem(table, "running", "Processando", 0, 0)
      .then(function () {
        if (!state.currentJob.includeRelations) return null;
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
        result.message = `Joins ${result.relationCount}; view-as ${result.viewAsCount}`;
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
      renderJob();
    });
  }

  function finishJob() {
    state.running = false;
    $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify({ resource: "job", action: "finish", jobId: state.currentJob.id })
    }).done(function (response) {
      if (response && response.success) state.currentJob = response.data;
      renderJob();
      loadViewAsRows();
      loadRelationsRows();
      setStatus("Fila concluida.", "ok");
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
    return $.ajax({
      url: "view-as-resolver.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, database), {
        rows
      }))
    }).then(function (response) {
      if (!response || response.success === false) {
        throw new Error(`Resolver includes de view-as para ${database}.${table}. Detalhe: ${apiError(response)}`);
      }
      return Array.isArray(response.data) ? response.data : rows;
    }, function (xhr) {
      throw new Error(`Resolver includes de view-as para ${database}.${table}. Detalhe: ${ajaxErrorMessage(xhr)}`);
    });
  }

  function saveManualViewAs() {
    const table = String($("#viewAsTable").val() || tableValue()).trim();
    const field = String($("#viewAsField").val() || "").trim();
    const viewAs = String($("#viewAsValue").val() || "").trim();
    if (!table || !field) {
      setStatus("Informe tabela e campo para salvar view-as.", "error");
      return;
    }
    $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, selectedDatabase()), {
        resource: "view-as",
        action: "save",
        source: "manual",
        field,
        viewAs
      }))
    }).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao salvar view-as: " + apiError(response), "error");
        return;
      }
      setStatus("View-as salvo.", "ok");
      loadViewAsRows(table);
    }).fail(function (xhr) {
      setStatus("Falha ao salvar view-as: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function deleteManualViewAs() {
    const table = String($("#viewAsTable").val() || tableValue()).trim();
    const field = String($("#viewAsField").val() || "").trim();
    if (!table || !field) {
      setStatus("Informe tabela e campo para excluir view-as.", "error");
      return;
    }
    $.ajax({
      url: "metadata-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(table, selectedDatabase()), {
        resource: "view-as",
        action: "delete",
        field
      }))
    }).done(function () {
      setStatus("View-as excluido.", "ok");
      loadViewAsRows(table);
    });
  }

  function loadViewAsRows(table) {
    const database = selectedDatabase();
    const targetTable = table || tableValue();
    const params = Object.assign(scope(targetTable, database), { resource: "view-as" });
    $.getJSON("metadata-store.php?" + $.param(params))
      .done(function (response) {
        const rows = response && response.success ? response.data || [] : [];
        $("#viewAsGrid").data("kendoGrid").dataSource.data(rows);
      });
  }

  function saveManualRelation() {
    const database = selectedDatabase();
    const leftTable = String($("#leftTable").val() || tableValue()).trim();
    const rightTable = String($("#rightTable").val() || "").trim();
    const leftField = String($("#leftField").val() || "").trim();
    const rightField = String($("#rightField").val() || "").trim();
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
    $.ajax({
      url: "relation-store.php",
      method: "POST",
      contentType: "application/json; charset=utf-8",
      dataType: "json",
      data: JSON.stringify(Object.assign(scope(leftTable, database), {
        source: "manual",
        relations: [relation]
      }))
    }).done(function (response) {
      if (!response || response.success === false) {
        setStatus("Falha ao salvar join: " + apiError(response), "error");
        return;
      }
      setStatus("Join salvo.", "ok");
      loadRelationsRows(leftTable);
    }).fail(function (xhr) {
      setStatus("Falha ao salvar join: " + ajaxErrorMessage(xhr), "error");
    });
  }

  function loadRelationsRows(table) {
    const database = selectedDatabase();
    const targetTable = table || tableValue();
    if (!database || !targetTable) {
      $("#relationsGrid").data("kendoGrid").dataSource.data([]);
      return;
    }
    $.getJSON("relation-store.php?" + $.param(scope(targetTable, database)))
      .done(function (response) {
        const rows = response && response.success ? response.data || [] : [];
        $("#relationsGrid").data("kendoGrid").dataSource.data(rows);
      });
  }

  function renderJob() {
    const job = state.currentJob;
    let rows = job && Array.isArray(job.items) ? job.items : [];
    const visibleStatuses = [];
    if ($("#showPendingOnly").is(":checked")) visibleStatuses.push("pending");
    if ($("#showErrorOnly").is(":checked")) visibleStatuses.push("error");
    if (visibleStatuses.length) {
      rows = rows.filter(function (item) { return item && visibleStatuses.indexOf(item.status) >= 0; });
    }
    $("#jobGrid").data("kendoGrid").dataSource.data(rows);
    if (!job) {
      $("#jobSummary").text("Nenhuma fila criada.");
      return;
    }
    $("#jobSummary").html(
      `Status: <strong>${escapeHtml(job.status)}</strong><br>` +
      `Banco: ${escapeHtml(job.database)}<br>` +
      `Processadas: ${job.processedTables}/${job.totalTables}<br>` +
      `Canceladas: ${job.cancelledTables || 0}<br>` +
      `Erros: ${job.failedTables}`
    );
  }

  function selectedDatabase() {
    const combo = $("#dbCombo").data("kendoComboBox");
    return combo ? String(combo.value() || "") : "";
  }

  function tableValue() {
    const combo = $("#tableName").data("kendoComboBox");
    return String(combo ? combo.value() : $("#tableName").val() || "").trim();
  }

  function refreshTableCombo() {
    const combo = $("#tableName").data("kendoComboBox");
    if (!combo) return;
    const current = combo.value();
    combo.setDataSource(new kendo.data.DataSource({ data: state.tables }));
    if (current) combo.value(current);
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
        if (response.warning) {
          throw new Error(`${label}. Endpoint: ${endpoint}. Detalhe: ${response.warning}`);
        }
        return response;
      }, function (xhr) {
        throw new Error(`${label}. Endpoint: ${endpoint}. Detalhe: ${ajaxErrorMessage(xhr)}`);
      });
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

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
})();
