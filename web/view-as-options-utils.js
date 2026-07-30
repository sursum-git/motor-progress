(function (global) {
  function normalizeScalarText(value) {
    if (value === 0) return "0";
    if (value === null || value === undefined) return "";
    return String(value).trim();
  }

  function getFieldType(fieldMeta) {
    if (!fieldMeta) return "";
    return String(fieldMeta.type || fieldMeta.fieldType || "").toLowerCase();
  }

  function normalizeOptions(options) {
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

  function isNumericField(fieldMeta) {
    const type = getFieldType(fieldMeta);
    return ["integer", "int64", "decimal", "float", "double", "amount"].indexOf(type) >= 0;
  }

  function isLogicalField(fieldMeta) {
    return getFieldType(fieldMeta) === "logical";
  }

  function hasOptions(fieldMeta) {
    return !!(fieldMeta && Array.isArray(fieldMeta.options) && fieldMeta.options.length);
  }

  function buildNumericOptionLookup(fields) {
    const lookup = {};
    (fields || []).forEach(function (field) {
      if (!field || !field.name || !isNumericField(field) || !hasOptions(field)) {
        return;
      }

      const fieldLookup = {};
      normalizeOptions(field.options).forEach(function (option) {
        const value = normalizeScalarText(option.value);
        const label = normalizeScalarText(option.label);
        if (!value || !label) return;
        fieldLookup[value] = label;
        const numericValue = Number(value.replace(",", "."));
        if (!isNaN(numericValue)) {
          fieldLookup[String(numericValue)] = label;
        }
      });

      if (Object.keys(fieldLookup).length) {
        lookup[field.name] = fieldLookup;
      }
    });
    return lookup;
  }

  function normalizeLogicalDisplayValue(value) {
    const normalized = normalizeScalarText(value).toLowerCase();
    if (["true", "1", "sim", "yes", "y"].indexOf(normalized) >= 0) return "Sim";
    if (["false", "0", "nao", "não", "no", "n"].indexOf(normalized) >= 0) return "Não";
    return "";
  }

  function describeFieldValue(fieldMeta, value, lookupSource) {
    const raw = normalizeScalarText(value);
    if (!fieldMeta || !fieldMeta.name || raw === "") return raw;
    if (isLogicalField(fieldMeta)) {
      const logical = normalizeLogicalDisplayValue(raw);
      if (logical) return logical;
    }
    const source = lookupSource || {};
    const lookup = source[fieldMeta.name];
    if (!lookup) return raw;

    const numericKey = String(Number(raw.replace(",", ".")));
    const label = lookup[raw] || (numericKey !== "NaN" ? lookup[numericKey] : "");
    if (!label || label === raw) return raw;
    return raw + " - " + label;
  }

  function displayFieldValue(fieldMeta, value, lookupSource) {
    const text = describeFieldValue(fieldMeta, value, lookupSource);
    return global.kendo && typeof global.kendo.htmlEncode === "function" ? global.kendo.htmlEncode(text) : String(text);
  }

  global.SursumViewAsOptions = {
    normalizeScalarText,
    getFieldType,
    normalizeOptions,
    isNumericField,
    isLogicalField,
    hasOptions,
    buildNumericOptionLookup,
    normalizeLogicalDisplayValue,
    describeFieldValue,
    displayFieldValue
  };
})(window);
