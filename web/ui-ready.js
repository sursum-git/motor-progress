(function () {
  "use strict";

  let readyRequested = false;

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
}());
