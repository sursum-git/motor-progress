(function () {
  "use strict";

  let readyRequested = false;

  function applyPtBrCulture() {
    if (window.kendo && typeof window.kendo.culture === "function") {
      window.kendo.culture("pt-BR");
    }
  }

  function reveal() {
    if (!document.body) {
      return;
    }
    document.body.classList.remove("sursum-ui-pending");
    document.body.classList.add("sursum-ui-ready");
  }

  function markReady() {
    readyRequested = true;
    if (window.SursumAuthPending) {
      return;
    }
    reveal();
  }

  function getJQueryTarget(target) {
    if (!window.jQuery || !target) {
      return null;
    }

    const element = window.jQuery(target);
    if (!element.length) {
      return null;
    }

    const grid = element.data("kendoGrid");
    return grid && grid.wrapper ? grid.wrapper : element;
  }

  function setGridLoading(target, loading) {
    if (!window.jQuery || !window.kendo || !window.kendo.ui || typeof window.kendo.ui.progress !== "function") {
      return;
    }
    if (loading && document.body && document.body.classList.contains("sursum-silent-grid-ajax")) {
      return;
    }

    const element = getJQueryTarget(target);
    if (!element || !element.length) {
      return;
    }

    window.kendo.ui.progress(element, Boolean(loading));
  }

  function setVisibleGridsLoading(loading) {
    if (!window.jQuery) {
      return;
    }
    if (loading && document.body && document.body.classList.contains("sursum-silent-grid-ajax")) {
      return;
    }

    window.jQuery(".k-grid:visible").each(function () {
      setGridLoading(this, loading);
    });
  }

  let gridExcelDefaultsBound = false;

  function bindGridExcelDefaults() {
    if (gridExcelDefaultsBound || !window.jQuery || !window.jQuery.fn || typeof window.jQuery.fn.kendoGrid !== "function") {
      return;
    }

    gridExcelDefaultsBound = true;
    const originalKendoGrid = window.jQuery.fn.kendoGrid;
    window.jQuery.fn.kendoGrid = function (options) {
      if (options && typeof options === "object" && !Array.isArray(options)) {
        options = ensureGridExcelToolbar(options, this);
      }
      return originalKendoGrid.call(this, options);
    };
  }

  function ensureGridExcelToolbar(options, target) {
    const nextOptions = window.jQuery.extend({}, options);
    const toolbar = normalizeGridToolbar(nextOptions.toolbar);
    if (!gridToolbarHasExcel(toolbar)) {
      toolbar.unshift("excel");
    }
    nextOptions.toolbar = toolbar;
    nextOptions.excel = window.jQuery.extend({}, {
      fileName: gridExcelFileName(target),
      allPages: true,
      filterable: true
    }, nextOptions.excel || {});
    return nextOptions;
  }

  function normalizeGridToolbar(toolbar) {
    if (Array.isArray(toolbar)) {
      return toolbar.slice();
    }
    if (toolbar) {
      return [toolbar];
    }
    return [];
  }

  function gridToolbarHasExcel(toolbar) {
    return toolbar.some(function (item) {
      return item === "excel" || (item && item.name === "excel");
    });
  }

  function gridExcelFileName(target) {
    const id = target && target.length && target[0] && target[0].id ? target[0].id : "grid";
    return "sursum-" + String(id).replace(/[^a-z0-9_-]+/gi, "-").toLowerCase() + ".xlsx";
  }

  let ajaxGridLoadingBound = false;

  function bindGridAjaxLoading() {
    if (ajaxGridLoadingBound || !window.jQuery) {
      return;
    }

    ajaxGridLoadingBound = true;
    window.jQuery(document)
      .ajaxStart(function () {
        setVisibleGridsLoading(true);
      })
      .ajaxStop(function () {
        setVisibleGridsLoading(false);
      });
  }

  window.SursumGridLoading = {
    set: setGridLoading,
    visible: setVisibleGridsLoading
  };

  applyPtBrCulture();
  bindGridExcelDefaults();
  bindGridAjaxLoading();

  window.SursumUiReady = markReady;
  window.addEventListener("sursum:auth-ready", function () {
    if (readyRequested) {
      reveal();
    }
  });

  window.setTimeout(function () {
    if (document.body && document.body.classList.contains("sursum-ui-pending") && !window.SursumAuthPending) {
      reveal();
    }
  }, 5000);

  window.addEventListener("load", bindGridAjaxLoading);
  window.addEventListener("load", bindGridExcelDefaults);
}());
