(function (global) {
  "use strict";

  const CONTEXT_STORAGE_KEY = "sursumContextV4";
  const LEGACY_CONTEXT_STORAGE_KEY = "sursumContextV3";
  const LEGACY_STORAGE_KEY = "sursumApiEndpoints";
  const LEGACY_SELECTED_COMPANY_KEY = "sursumSelectedCompany";
  const LEGACY_SELECTED_ENDPOINT_KEY = "sursumSelectedApiEndpoint";
  const LEGACY_BASE_URL_KEY = "sursumApiBaseUrl";
  const CURRENT_CLIENT_KEY = "sursumSelectedClientId";
  const CURRENT_ENV_KEY = "sursumSelectedEnvironment";
  const CURRENT_COMPANY_KEY = "sursumSelectedCompanyId";

  const DEFAULT_CONFIG = {
    version: 4,
    clients: [{
      id: "cliente-padrao",
      name: "Cliente padrao"
    }],
    environments: [{
      id: "ambiente-local",
      clientId: "cliente-padrao",
      name: "Ambiente local",
      pasoeBaseUrl: "http://localhost:8890/web/SursumDynamicQuery",
      authMode: "none",
      authorization: "",
      companyIdMode: "query",
      extraQueryParams: ""
    }],
    companies: [{
      id: "empresa-padrao",
      clientId: "cliente-padrao",
      environmentId: "ambiente-local",
      name: "Empresa padrao",
      code: "empresa-padrao"
    }],
    physicalDatabases: [],
    aliases: [],
    selected: {
      clientId: "cliente-padrao",
      environmentId: "ambiente-local",
      companyId: "empresa-padrao"
    }
  };

  const state = { config: null };

  init();

  function init() {
    state.config = normalizeConfig(
      safeParse(localStorage.getItem(CONTEXT_STORAGE_KEY))
      || safeParse(localStorage.getItem(LEGACY_CONTEXT_STORAGE_KEY))
      || safeParse(localStorage.getItem(LEGACY_STORAGE_KEY))
      || DEFAULT_CONFIG
    );
    syncLegacySelection();
    installAjaxHook();
  }

  function safeParse(value) {
    if (!value) return null;
    try { return JSON.parse(value); } catch (_) { return null; }
  }

  function normalizeText(value) {
    return String(value || "").trim();
  }

  function sanitizeUrl(value) {
    return normalizeText(value).replace(/\/+$/, "");
  }

  function slug(value) {
    return normalizeText(value)
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .replace(/-+/g, "-") || "item";
  }

  function ensureId(item, fallback) {
    return item && item.id ? String(item.id) : fallback;
  }

  function parseExtraQueryParams(value) {
    const raw = normalizeText(value);
    if (!raw) return {};
    try {
      if (raw.startsWith("{") || raw.startsWith("[")) {
        const parsed = JSON.parse(raw);
        return normalizeObject(parsed);
      }
    } catch (_) {}
    const params = {};
    raw.split("&").forEach((pair) => {
      if (!pair) return;
      const parts = pair.split("=");
      let key = "";
      let decodedValue = "";
      try {
        key = normalizeText(decodeURIComponent(parts[0] || "")).replace(/\s+/g, "");
        decodedValue = normalizeText(decodeURIComponent(parts.slice(1).join("=")));
      } catch (_) {
        key = normalizeText(parts[0] || "").replace(/\s+/g, "");
        decodedValue = normalizeText(parts.slice(1).join("="));
      }
      if (!key) return;
      params[key] = decodedValue;
    });
    return params;
  }

  function normalizeObject(value) {
    if (!value || typeof value !== "object") return {};
    const out = {};
    Object.keys(value).forEach((key) => {
      if (typeof value[key] === "string" || typeof value[key] === "number" || typeof value[key] === "boolean") {
        out[key] = String(value[key]);
      }
    });
    return out;
  }

  function normalizeConfig(raw) {
    if (!raw) return normalizeConfig(DEFAULT_CONFIG);

    if (raw.version === 4 || Array.isArray(raw.clients)) {
      const normalized = {
        version: 4,
        clients: normalizeClients(Array.isArray(raw.clients) ? raw.clients : []),
        environments: normalizeEnvironments(Array.isArray(raw.environments) ? raw.environments : []),
        companies: normalizeCompanies(Array.isArray(raw.companies) ? raw.companies : []),
        physicalDatabases: normalizePhysicalDatabases(Array.isArray(raw.physicalDatabases) ? raw.physicalDatabases : []),
        aliases: normalizeAliases(Array.isArray(raw.aliases) ? raw.aliases : []),
        selected: normalizeSelected(raw.selected || {})
      };
      ensureRelations(normalized);
      persist(normalized);
      return normalized;
    }

    if (raw.version === 3) {
      return normalizeConfig(fromV3Format(raw));
    }

    if (Array.isArray(raw.companies)) {
      return normalizeConfig(fromLegacyFormat(raw));
    }

    return normalizeConfig(DEFAULT_CONFIG);
  }

  function normalizeClients(list) {
    const out = [];
    const used = new Set();
    list.forEach((client, index) => {
      const id = ensureId(client, `cliente-${index}`);
      if (!id || used.has(id)) return;
      used.add(id);
      out.push({
        id,
        name: normalizeText(client.name) || id
      });
    });
    return out.length ? out : DEFAULT_CONFIG.clients.slice();
  }

  function normalizeEnvironments(list) {
    const out = [];
    const used = new Set();
    list.forEach((environment, index) => {
      const id = ensureId(environment, `ambiente-${index}`);
      if (!id || used.has(id)) return;
      used.add(id);
      out.push({
        id,
        clientId: normalizeText(environment.clientId),
        name: normalizeText(environment.name) || id,
        pasoeBaseUrl: sanitizeUrl(environment.pasoeBaseUrl || environment.baseUrl || environment.url || DEFAULT_CONFIG.environments[0].pasoeBaseUrl),
        authMode: normalizeAuthMode(environment.authMode || "none"),
        authorization: normalizeText(environment.authorization),
        companyIdMode: normalizeCompanyIdMode(environment.companyIdMode || "query"),
        extraQueryParams: normalizeText(environment.extraQueryParams)
      });
    });
    return out.length ? out : DEFAULT_CONFIG.environments.slice();
  }

  function normalizeCompanies(list) {
    const out = [];
    const used = new Set();
    list.forEach((company, index) => {
      const id = ensureId(company, `empresa-${index}`);
      if (!id || used.has(id)) return;
      used.add(id);
      out.push({
        id,
        clientId: normalizeText(company.clientId) || "",
        environmentId: normalizeText(company.environmentId || company.envId || ""),
        name: normalizeText(company.name) || id,
        code: normalizeText(company.code) || slug(normalizeText(company.name) || id)
      });
    });
    return out.length ? out : DEFAULT_CONFIG.companies.slice();
  }

  function normalizePhysicalDatabases(list) {
    const out = [];
    const used = new Set();
    list.forEach((physical, index) => {
      const id = ensureId(physical, `fisico-${index}`);
      if (!id || used.has(id)) return;
      used.add(id);
      const aliasRefs = Array.isArray(physical.aliasMap)
        ? physical.aliasMap
        : (Array.isArray(physical.aliases) ? physical.aliases : []);
      out.push({
        id,
        physicalName: normalizeText(physical.name || physical.physicalName || id),
        shared: Boolean(physical.shared),
        ownerCompanyIds: Array.isArray(physical.ownerCompanyIds) ? Array.from(new Set(physical.ownerCompanyIds.map(String).filter(Boolean))) : [],
        aliasMap: Array.from(new Set(aliasRefs.map(String).map(normalizeText).filter(Boolean))),
        status: normalizeText(physical.status) || "active"
      });
    });
    return out;
  }

  function normalizeAliases(list) {
    const out = [];
    const used = new Set();
    list.forEach((alias, index) => {
      const aliasValue = normalizeText(alias.alias || alias.name || alias.code);
      if (!aliasValue || used.has(aliasValue.toLowerCase())) return;
      used.add(aliasValue.toLowerCase());
      out.push({
        physicalId: ensureId(alias.physicalId, `fisico-${index}`),
        alias: aliasValue,
        status: normalizeText(alias.status) || "active"
      });
    });
    return out;
  }

  function normalizeSelected(raw) {
    return {
      clientId: normalizeText(raw.clientId) || normalizeText(DEFAULT_CONFIG.selected.clientId),
      environmentId: normalizeText(raw.environmentId) || normalizeText(DEFAULT_CONFIG.selected.environmentId),
      companyId: normalizeText(raw.companyId) || normalizeText(DEFAULT_CONFIG.selected.companyId)
    };
  }

  function normalizeAuthMode(value) {
    const candidate = normalizeText(value).toLowerCase();
    return candidate === "header" || candidate === "query" ? candidate : "none";
  }

  function normalizeCompanyIdMode(value) {
    const candidate = normalizeText(value).toLowerCase();
    return candidate === "header" ? "header" : "query";
  }

  function ensureRelations(config) {
    const clientIds = new Set(config.clients.map((client) => client.id));
    if (!config.clients.length) config.clients = DEFAULT_CONFIG.clients.slice();

    config.environments = config.environments.map((environment) => ({
      ...environment,
      clientId: environment.clientId && clientIds.has(environment.clientId) ? environment.clientId : ""
    }));

    const environmentById = {};
    config.environments.forEach((environment) => { environmentById[environment.id] = environment; });

    config.companies = config.companies.map((company) => {
      const env = environmentById[company.environmentId] || config.environments[0];
      return {
        ...company,
        environmentId: env.id,
        clientId: clientIds.has(company.clientId) ? company.clientId : env.clientId
      };
    });

    const physicalIds = new Set(config.physicalDatabases.map((item) => item.id));
    config.aliases = config.aliases.map((alias) => ({
      ...alias,
      physicalId: physicalIds.has(alias.physicalId) ? alias.physicalId : (config.physicalDatabases[0] ? config.physicalDatabases[0].id : "")
    }));

    const selectedClient = config.clients.find((client) => client.id === config.selected.clientId) || config.clients[0];
    const selectedEnvironment = config.environments.find((environment) => environment.id === config.selected.environmentId && environment.clientId === selectedClient.id)
      || config.environments.find((environment) => environment.clientId === selectedClient.id)
      || config.environments[0];
    const selectedCompany = config.companies.find((company) => company.id === config.selected.companyId && company.environmentId === selectedEnvironment.id)
      || config.companies.find((company) => company.environmentId === selectedEnvironment.id)
      || config.companies.find((company) => company.clientId === selectedClient.id)
      || config.companies[0];

    config.selected = {
      clientId: selectedClient ? selectedClient.id : DEFAULT_CONFIG.selected.clientId,
      environmentId: selectedEnvironment ? selectedEnvironment.id : DEFAULT_CONFIG.selected.environmentId,
      companyId: selectedCompany ? selectedCompany.id : DEFAULT_CONFIG.selected.companyId
    };
    return config;
  }

  function fromV3Format(raw) {
    const environments = (raw.environments || []).map((environment) => ({
      ...environment,
      clientId: normalizeText(environment.clientId) || "cliente-migrado"
    }));
    const companies = (raw.companies || []).map((company) => {
      const environment = environments.find((item) => item.id === company.environmentId) || environments[0];
      return {
        ...company,
        clientId: normalizeText(company.clientId) || (environment ? environment.clientId : "cliente-migrado")
      };
    });
    return {
      version: 4,
      clients: [{ id: "cliente-migrado", name: "Cliente migrado" }],
      environments,
      companies,
      physicalDatabases: raw.physicalDatabases || [],
      aliases: raw.aliases || [],
      selected: {
        clientId: "cliente-migrado",
        environmentId: raw.selected && raw.selected.environmentId,
        companyId: raw.selected && raw.selected.companyId
      }
    };
  }

  function fromLegacyFormat(raw) {
    const legacyCompanies = Array.isArray(raw.companies) ? raw.companies : [];
    const clients = [{ id: "cliente-migrado", name: "Cliente migrado" }];
    const environments = [];
    const environmentByUrl = {};

    legacyCompanies.forEach((legacyCompany, companyIndex) => {
      const endpointList = Array.isArray(legacyCompany.endpoints) && legacyCompany.endpoints.length
        ? legacyCompany.endpoints
        : [{ name: "PASOE local", url: DEFAULT_CONFIG.environments[0].pasoeBaseUrl, isDefault: true }];

      endpointList.forEach((endpoint, endpointIndex) => {
        const url = sanitizeUrl(endpoint.url || endpoint.baseUrl || DEFAULT_CONFIG.environments[0].pasoeBaseUrl);
        if (!environmentByUrl[url]) {
          const id = `env-${slug(url)}-${companyIndex}-${endpointIndex}`;
          environmentByUrl[url] = id;
          environments.push({
            id,
            clientId: "cliente-migrado",
            name: normalizeText(endpoint.name || legacyCompany.name || url) || id,
            pasoeBaseUrl: url,
            authMode: "none",
            authorization: normalizeText(endpoint.authorization) || "",
            companyIdMode: "query",
            extraQueryParams: ""
          });
        }
      });
    });

    if (!environments.length) {
      environments.push({
        id: DEFAULT_CONFIG.environments[0].id,
        clientId: "cliente-migrado",
        name: DEFAULT_CONFIG.environments[0].name,
        pasoeBaseUrl: DEFAULT_CONFIG.environments[0].pasoeBaseUrl,
        authMode: "none",
        authorization: "",
        companyIdMode: "query",
        extraQueryParams: ""
      });
    }

    const companies = legacyCompanies.map((legacyCompany, index) => {
      const endpointList = Array.isArray(legacyCompany.endpoints) && legacyCompany.endpoints.length
        ? legacyCompany.endpoints
        : [{ url: environments[0].pasoeBaseUrl }];
      const firstUrl = sanitizeUrl(endpointList[0].url || environments[0].pasoeBaseUrl);
      return {
        id: ensureId(legacyCompany, `empresa-${index}`),
        clientId: "cliente-migrado",
        environmentId: environmentByUrl[firstUrl] || environments[0].id,
        name: normalizeText(legacyCompany.name) || `Empresa ${index + 1}`,
        code: normalizeText(legacyCompany.code) || slug(legacyCompany.name || `empresa-${index}`)
      };
    });

    return {
      version: 4,
      clients,
      environments,
      companies: companies.length ? companies : DEFAULT_CONFIG.companies.slice(),
      physicalDatabases: [],
      aliases: [],
      selected: {
        clientId: "cliente-migrado",
        environmentId: environments[0].id,
        companyId: companies[0] ? companies[0].id : DEFAULT_CONFIG.companies[0].id
      }
    };
  }

  function persist(config) {
    const payload = config || state.config;
    state.config = payload;
    localStorage.setItem(CONTEXT_STORAGE_KEY, JSON.stringify(payload));
    localStorage.setItem(LEGACY_CONTEXT_STORAGE_KEY, JSON.stringify(payload));
    localStorage.setItem(LEGACY_STORAGE_KEY, JSON.stringify(toLegacyConfig(payload)));
    localStorage.setItem(CURRENT_CLIENT_KEY, payload.selected.clientId);
    localStorage.setItem(CURRENT_ENV_KEY, payload.selected.environmentId);
    localStorage.setItem(CURRENT_COMPANY_KEY, payload.selected.companyId);
    const environment = getSelectedEnvironment(payload);
    if (environment) localStorage.setItem(LEGACY_BASE_URL_KEY, environment.pasoeBaseUrl);
    syncLegacySelection();
  }

  function getSelectedClient(config = state.config) {
    return config.clients.find((client) => client.id === config.selected.clientId) || config.clients[0];
  }

  function getSelectedEnvironment(config = state.config) {
    const client = getSelectedClient(config);
    return config.environments.find((environment) => environment.id === config.selected.environmentId && environment.clientId === client.id)
      || config.environments.find((environment) => environment.clientId === client.id)
      || config.environments[0];
  }

  function getSelectedCompany(config = state.config) {
    const client = getSelectedClient(config);
    const environment = getSelectedEnvironment(config);
    return config.companies.find((company) => company.id === config.selected.companyId && company.environmentId === environment.id)
      || config.companies.find((company) => company.environmentId === environment.id)
      || config.companies.find((company) => company.clientId === client.id)
      || config.companies[0];
  }

  function getCompaniesForClient(clientId, config = state.config) {
    return config.companies.filter((company) => company.clientId === clientId);
  }

  function getEnvironmentsForClient(clientId, config = state.config) {
    return config.environments.filter((environment) => environment.clientId === clientId);
  }

  function syncLegacySelection() {
    const client = getSelectedClient(state.config);
    const company = getSelectedCompany(state.config);
    const environment = getSelectedEnvironment(state.config);
    if (client) localStorage.setItem(CURRENT_CLIENT_KEY, client.id);
    if (company) localStorage.setItem(LEGACY_SELECTED_COMPANY_KEY, company.id);
    if (environment) localStorage.setItem(LEGACY_SELECTED_ENDPOINT_KEY, environment.id);
  }

  function toLegacyConfig(config) {
    const selectedCompany = getSelectedCompany(config);
    const environmentsById = {};
    config.environments.forEach((environment) => { environmentsById[environment.id] = environment; });
    const companies = config.companies.map((company) => {
      const environment = environmentsById[company.environmentId] || getSelectedEnvironment(config);
      return {
        id: company.id,
        name: company.name,
        code: company.code,
        isDefault: selectedCompany && company.id === selectedCompany.id,
        endpoints: [toLegacyEndpoint(environment)]
      };
    });
    return { version: 2, companies };
  }

  function toLegacyEndpoint(environment) {
    return {
      id: environment.id,
      name: environment.name,
      url: environment.pasoeBaseUrl,
      isDefault: true,
      companyId: "legacy"
    };
  }

  function parseLegacySelection() {
    const config = state.config;
    const storedClientId = localStorage.getItem(CURRENT_CLIENT_KEY);
    const storedEnvironmentId = localStorage.getItem(CURRENT_ENV_KEY) || localStorage.getItem(LEGACY_SELECTED_ENDPOINT_KEY);
    const storedCompanyId = localStorage.getItem(CURRENT_COMPANY_KEY) || localStorage.getItem(LEGACY_SELECTED_COMPANY_KEY);

    if (storedClientId && config.clients.some((client) => client.id === storedClientId)) {
      config.selected.clientId = storedClientId;
    }
    if (storedEnvironmentId) {
      const environment = config.environments.find((item) => item.id === storedEnvironmentId);
      if (environment) {
        config.selected.environmentId = environment.id;
        config.selected.clientId = environment.clientId;
      }
    }
    if (storedCompanyId) {
      const company = config.companies.find((item) => item.id === storedCompanyId);
      if (company) {
        config.selected.companyId = company.id;
        config.selected.clientId = company.clientId;
        if (company.environmentId) config.selected.environmentId = company.environmentId;
      }
    }
    ensureRelations(config);
    persist(config);
  }

  function applyAjaxContext(url, options = {}) {
    const config = state.config;
    const environment = getSelectedEnvironment(config);
    const company = getSelectedCompany(config);
    if (!environment || !url) return { url, headers: {} };

    const parsed = new URL(url, window.location.href);
    const parsedBase = new URL(environment.pasoeBaseUrl.replace(/\/+$/, ""), window.location.href);
    if (!parsed.href.startsWith(parsedBase.href)) return { url, headers: {} };

    const merged = Object.assign({}, parseExtraQueryParams(environment.extraQueryParams), parseExtraQueryParams(options.extraQueryParams));
    if (environment.companyIdMode === "query" && company && company.code) merged.companyId = company.code;
    if (options.forceCompanyId && options.companyCode) merged.companyId = options.companyCode;
    if (!options.omitCompanyId && options.includeCompanyId === false) delete merged.companyId;

    Object.keys(merged).forEach((key) => {
      if (merged[key] === undefined || merged[key] === null || merged[key] === "") delete merged[key];
    });
    Object.entries(merged).forEach(([key, value]) => {
      if (!parsed.searchParams.has(key) && String(value).length) parsed.searchParams.append(key, String(value));
    });

    const headers = {};
    if ((environment.authMode === "header" || options.forceHeaderAuth) && environment.authorization) {
      headers.Authorization = environment.authorization;
    }
    if (environment.authMode === "query" && environment.authorization && options.includeAuthInQuery) {
      if (!parsed.searchParams.has("authorization")) parsed.searchParams.append("authorization", environment.authorization);
    }
    return { url: parsed.href, headers };
  }

  function installAjaxHook() {
    if (!global.jQuery || global.__sursumContextAjaxPatched) return;
    global.__sursumContextAjaxPatched = true;
    const $ = global.jQuery;
    const originalAjax = $.ajax;
    $.ajax = function (request, settings) {
      const normalized = normalizeAjaxArgs(request, settings);
      if (normalized && normalized.url) {
        const enriched = applyAjaxContext(normalized.url, normalized.contextConfig || {});
        normalized.url = enriched.url || normalized.url;
        if (enriched.headers && Object.keys(enriched.headers).length) {
          normalized.headers = Object.assign({}, normalized.headers || {}, enriched.headers);
        }
      }
      return originalAjax.call(this, normalized);
    };
  }

  function normalizeAjaxArgs(request, settings) {
    if (typeof request === "string") return Object.assign({}, settings || {}, { url: request });
    if (request && typeof request === "object") return Object.assign({}, request);
    return {};
  }

  function setSelection(a, b, c) {
    const config = state.config;
    let clientId = "";
    let environmentId = "";
    let companyId = "";

    if (typeof c !== "undefined") {
      clientId = normalizeText(a);
      environmentId = normalizeText(b);
      companyId = normalizeText(c);
    } else {
      environmentId = normalizeText(a);
      companyId = normalizeText(b);
      const environment = config.environments.find((item) => item.id === environmentId);
      const company = config.companies.find((item) => item.id === companyId);
      clientId = normalizeText((company && company.clientId) || (environment && environment.clientId) || config.selected.clientId);
    }

    const environmentCandidate = environmentId
      ? config.environments.find((item) => item.id === environmentId)
      : null;
    const selectedClient = config.clients.find((item) => item.id === clientId)
      || (environmentCandidate ? config.clients.find((item) => item.id === environmentCandidate.clientId) : null)
      || config.clients[0];
    const selectedEnvironment = config.environments.find((item) => item.id === environmentId && item.clientId === selectedClient.id)
      || config.environments.find((item) => item.clientId === selectedClient.id)
      || config.environments[0];
    const selectedCompany = config.companies.find((item) => item.id === companyId && item.environmentId === selectedEnvironment.id)
      || config.companies.find((item) => item.environmentId === selectedEnvironment.id)
      || config.companies.find((item) => item.clientId === selectedClient.id)
      || config.companies[0];

    config.selected = {
      clientId: selectedClient ? selectedClient.id : config.selected.clientId,
      environmentId: selectedEnvironment ? selectedEnvironment.id : config.selected.environmentId,
      companyId: selectedCompany ? selectedCompany.id : config.selected.companyId
    };
    persist(config);
  }

  function setLegacySelection(legacyCompanyId, legacyEndpointId) {
    const config = state.config;
    const company = config.companies.find((item) => item.id === legacyCompanyId);
    const environment = config.environments.find((item) => item.id === legacyEndpointId);
    const clientId = (company && company.clientId) || (environment && environment.clientId) || config.selected.clientId;
    setSelection(clientId, (company && company.environmentId) || (environment && environment.id) || config.selected.environmentId, (company && company.id) || config.selected.companyId);
  }

  function resolveAlias(aliasName) {
    const alias = normalizeText(aliasName).toLowerCase();
    const found = (state.config.aliases || []).find((entry) => (entry.alias || "").toLowerCase() === alias);
    if (!found) return { alias: aliasName, physicalName: "", status: "missing" };
    const physical = state.config.physicalDatabases.find((item) => item.id === found.physicalId);
    if (!physical) return { alias: aliasName, physicalName: "", status: found.status || "missing" };
    return { alias: aliasName, physicalName: physical.physicalName, physicalId: physical.id, status: found.status || "active" };
  }

  function resolvePhysicalDatabasesForAlias(aliasName) {
    return (state.config.aliases || [])
      .filter((item) => (item.alias || "").toLowerCase() === normalizeText(aliasName).toLowerCase())
      .map((item) => state.config.physicalDatabases.find((physical) => physical.id === item.physicalId))
      .filter(Boolean);
  }

  function metadataNamespaceForCompany(companyId, logicalDatabaseName) {
    const company = state.config.companies.find((item) => item.id === companyId) || getSelectedCompany(state.config);
    const environment = company
      ? state.config.environments.find((item) => item.id === company.environmentId)
      : getSelectedEnvironment(state.config);
    const client = company
      ? state.config.clients.find((item) => item.id === company.clientId)
      : getSelectedClient(state.config);
    const scope = company && company.code ? company.code : "shared";
    const logical = normalizeText(logicalDatabaseName) || "metadata";
    return `conf/metadata/${client.id}/${environment.id}/${scope}/${logical}`;
  }

  function resolveMetadataTargets(aliasName, companyId) {
    const company = state.config.companies.find((item) => item.id === companyId) || getSelectedCompany(state.config);
    const environment = company
      ? state.config.environments.find((item) => item.id === company.environmentId)
      : getSelectedEnvironment(state.config);
    const client = company
      ? state.config.clients.find((item) => item.id === company.clientId)
      : getSelectedClient(state.config);
    const alias = resolveAlias(aliasName);
    const physical = alias && alias.physicalId
      ? state.config.physicalDatabases.find((item) => item.id === alias.physicalId)
      : null;
    return {
      clientId: client ? client.id : "",
      clientName: client ? client.name : "",
      environmentId: environment ? environment.id : "",
      companyId: company ? company.id : "",
      companyCode: company ? company.code : "",
      physicalId: physical ? physical.id : "",
      physicalName: physical ? physical.physicalName : "",
      scope: physical && physical.shared ? "_shared" : (company ? (company.code || company.id) : "")
    };
  }

  function toJson() {
    return {
      version: state.config.version,
      clients: state.config.clients,
      environments: state.config.environments,
      companies: state.config.companies,
      physicalDatabases: state.config.physicalDatabases,
      aliases: state.config.aliases
    };
  }

  function getContext() {
    parseLegacySelection();
    return JSON.parse(JSON.stringify(state.config));
  }

  function getConfig() {
    return getContext();
  }

  function getLegacyConfig() {
    parseLegacySelection();
    return toLegacyConfig(state.config);
  }

  function getCurrentClient() {
    parseLegacySelection();
    return getSelectedClient(state.config);
  }

  function getCurrentEnvironment() {
    parseLegacySelection();
    return getSelectedEnvironment(state.config);
  }

  function getCurrentCompany() {
    parseLegacySelection();
    return getSelectedCompany(state.config);
  }

  function getCompaniesForEnvironment(environmentId, config = state.config) {
    parseLegacySelection();
    const id = normalizeText(environmentId) || normalizeText((config.selected || {}).environmentId);
    return (config.companies || []).filter((item) => item.environmentId === id);
  }

  function getRequestConfig(path, options) {
    return applyAjaxContext(String(path || ""), options || {});
  }

  function getUrl(path, options) {
    return getRequestConfig(path, options).url;
  }

  function setConfig(payload) {
    state.config = normalizeConfig(payload || state.config);
    persist(state.config);
    return getContext();
  }

  function applyLegacyConfig(payload) {
    state.config = normalizeConfig(fromLegacyFormat(payload || {}));
    persist(state.config);
    return getContext();
  }

  function addHistory(environmentId, companyId, fileName, payload) {
    const historyKey = "sursumMetadataSyncHistory";
    const raw = safeParse(localStorage.getItem(historyKey)) || [];
    const history = Array.isArray(raw) ? raw : [];
    const client = getCurrentClient();
    const environment = getCurrentEnvironment();
    const company = getCurrentCompany();
    const record = {
      id: `${Date.now()}-${Math.floor(Math.random() * 99999)}`,
      clientId: client ? client.id : "",
      environmentId: environmentId || (environment ? environment.id : ""),
      companyId: companyId || (company ? company.id : ""),
      fileName,
      createdAt: new Date().toISOString(),
      payload
    };
    history.unshift(record);
    localStorage.setItem(historyKey, JSON.stringify(history, null, 2));
    return record;
  }

  function getHistory() {
    const raw = safeParse(localStorage.getItem("sursumMetadataSyncHistory")) || [];
    return Array.isArray(raw) ? raw : [];
  }

  global.SursumContext = {
    getContext,
    getConfig,
    getLegacyConfig,
    getCurrentClient,
    getCurrentEnvironment,
    getCurrentCompany,
    getCompaniesForClient,
    getCompaniesForEnvironment,
    getEnvironmentsForClient,
    getRequestConfig,
    getUrl,
    setSelection,
    setLegacySelection,
    setConfig,
    applyLegacyConfig,
    resolveAlias,
    resolvePhysicalDatabasesForAlias,
    metadataNamespaceForCompany,
    resolveMetadataTargets,
    toJson,
    addHistory,
    getHistory,
    normalizeLegacyConfig: toLegacyConfig,
    persist
  };
})(window);
