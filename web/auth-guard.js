(function () {
  "use strict";

  const publicPages = new Set(["login.html"]);
  const pageName = String(location.pathname.split("/").pop() || "index.html").toLowerCase();
  if (publicPages.has(pageName)) return;
  window.SursumAuthPending = true;

  fetch("auth.php?action=status", {
    credentials: "same-origin",
    cache: "no-store"
  })
    .then((response) => response.ok ? response.json() : { authenticated: false })
    .then((payload) => {
      if (!payload || !payload.authenticated) {
        const target = encodeURIComponent(location.pathname.split("/").pop() + location.search + location.hash);
        location.href = "login.html?next=" + target;
        return;
      }
      window.SursumAuthPending = false;
      window.SursumAuth = payload;
      window.dispatchEvent(new CustomEvent("sursum:auth-ready", { detail: payload }));
    })
    .catch(() => {
      location.href = "login.html";
    });
})();
