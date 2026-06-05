(function () {
  const samples = {
    simple: {
      execution: "sync",
      sources: [
        { nome: "Customer", alias: "customer", campos: "CustNum,Name" }
      ],
      select: [
        { sourceAlias: "customer", field: "CustNum", outputAlias: "codigo" },
        { sourceAlias: "customer", field: "Name", outputAlias: "nome" }
      ],
      orderBy: [
        { sourceAlias: "customer", field: "CustNum", direction: "ASC" }
      ],
      page: 1,
      pageSize: 500
    },
    advanced: {
      execution: "sync",
      pipeline: [
        { type: "source", payload: "{\"nome\":\"Customer\",\"alias\":\"customer\",\"campos\":\"CustNum,Name,State,Balance\"}" },
        { type: "select", payload: "{\"fields\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"outputAlias\":\"codigo\"},{\"sourceAlias\":\"customer\",\"field\":\"Name\",\"outputAlias\":\"nome\"},{\"sourceAlias\":\"customer\",\"field\":\"State\",\"outputAlias\":\"estado\"},{\"sourceAlias\":\"customer\",\"field\":\"Balance\",\"outputAlias\":\"saldo\"}]}" },
        { type: "filter", payload: "{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"operator\":\">=\",\"value\":\"1\"}" },
        { type: "sort", payload: "{\"fields\":[{\"sourceAlias\":\"customer\",\"field\":\"CustNum\",\"direction\":\"ASC\"}]}" },
        { type: "limit", payload: "{\"page\":1,\"pageSize\":500}" },
        { type: "map", payload: "{\"fields\":[{\"from\":\"codigo\",\"to\":\"codigo\"},{\"from\":\"nome\",\"to\":\"cliente\"},{\"from\":\"estado\",\"to\":\"uf\"},{\"from\":\"saldo\",\"to\":\"saldo\"}]}" },
        { type: "distinct", payload: "{\"fields\":[\"codigo\"]}" },
        { type: "group", payload: "{\"fields\":[\"uf\"]}" },
        { type: "aggregate", payload: "{\"op\":\"sum\",\"field\":\"saldo\",\"as\":\"saldoTotal\"}" },
        { type: "output", payload: "{\"format\":\"json\"}" }
      ]
    }
  };

  function init() {
    $("button").kendoButton();
    $("#resultGrid").kendoGrid({
      dataSource: [],
      height: 620,
      sortable: true,
      filterable: true,
      resizable: true,
      pageable: {
        pageSize: 25,
        pageSizes: [25, 50, 100, 500]
      }
    });

    $("#queryFile").on("change", onFileSelected);
    $("#loadSimpleSample").on("click", () => loadSample("simple"));
    $("#loadAdvancedSample").on("click", () => loadSample("advanced"));
    $("#runQuery").on("click", runQuery);

    loadSample("simple");
  }

  function onFileSelected(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) return;

    $("#fileName").text(file.name);
    $("#fileSize").text(formatBytes(file.size));
    $("#parseStatus").text("lendo arquivo...");

    const reader = new FileReader();
    reader.onload = function () {
      const text = String(reader.result || "");
      $("#jsonPreview").val(formatJson(text));
      validatePreview();
    };
    reader.onerror = function () {
      setStatus("Não foi possível ler o arquivo.", "error");
      $("#parseStatus").text("erro de leitura");
    };
    reader.readAsText(file, "utf-8");
  }

  function loadSample(name) {
    const sample = samples[name];
    $("#fileName").text(name === "simple" ? "customer-simple.json" : "customer-pipeline-advanced-request.json");
    $("#fileSize").text("amostra interna");
    $("#jsonPreview").val(JSON.stringify(sample, null, 2));
    validatePreview();
    setStatus("Amostra carregada. Execute para chamar o PASOE.", "ok");
  }

  function validatePreview() {
    try {
      JSON.parse($("#jsonPreview").val());
      $("#parseStatus").text("JSON válido");
      return true;
    } catch (error) {
      $("#parseStatus").text("JSON inválido: " + error.message);
      return false;
    }
  }

  function runQuery() {
    if (!validatePreview()) {
      setStatus("Corrija o JSON antes de executar.", "error");
      return;
    }

    const payload = $("#jsonPreview").val();
    setStatus("Enviando arquivo JSON para a API do PASOE...", "");

    $.ajax({
      url: $("#apiUrl").val(),
      method: "POST",
      contentType: "application/json",
      dataType: "json",
      data: payload
    }).done(function (response) {
      renderResponse(response);
    }).fail(function (xhr) {
      $("#statSuccess").text("false");
      $("#statRecords").text("0");
      $("#statHasMore").text("-");
      updateGrid([{ erro: "Falha HTTP", status: xhr.status, detalhe: xhr.statusText || xhr.responseText }]);
      setStatus("Falha HTTP: " + xhr.status + " " + xhr.statusText, "error");
    });
  }

  function renderResponse(response) {
    $("#statSuccess").text(String(!!response.success));
    $("#statRecords").text(String(response.recordsReturned || (response.data ? response.data.length : 0)));
    $("#statHasMore").text(String(response.hasMore === undefined ? "-" : response.hasMore));

    if (!response.success) {
      const error = response.error || {};
      updateGrid([{ code: error.code || "ERROR", message: error.message || "Erro sem mensagem", details: error.details || "" }]);
      setStatus("Erro da API: " + (error.message || "falha desconhecida"), "error");
      return;
    }

    const rows = Array.isArray(response.data) ? response.data : [];
    updateGrid(rows.length ? rows : [{ mensagem: "Consulta executada sem linhas em data." }]);
    setStatus("Consulta concluída. Registros: " + (response.recordsReturned || rows.length), "ok");
  }

  function updateGrid(rows) {
    const grid = $("#resultGrid").data("kendoGrid");
    const first = rows[0] || {};
    const columns = Object.keys(first).map((field) => ({
      field,
      title: field,
      width: 160
    }));

    grid.setOptions({
      columns: columns.length ? columns : [{ field: "mensagem", title: "Mensagem" }]
    });
    grid.dataSource.data(rows);
  }

  function formatJson(text) {
    try {
      return JSON.stringify(JSON.parse(text), null, 2);
    } catch (_) {
      return text;
    }
  }

  function formatBytes(size) {
    if (size < 1024) return size + " bytes";
    if (size < 1024 * 1024) return (size / 1024).toFixed(1) + " KB";
    return (size / 1024 / 1024).toFixed(1) + " MB";
  }

  function setStatus(message, kind) {
    $("#statusBox").removeClass("ok error").addClass(kind || "").text(message);
  }

  $(init);
})();
