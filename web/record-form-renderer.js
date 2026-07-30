(function (global) {
  function normalizeText(value) {
    if (value === null || value === undefined) return "";
    return String(value).trim();
  }

  function fieldType(field) {
    return String((field && (field.type || field.fieldType || field.dataType)) || "").toLowerCase();
  }

  function isPrimaryKeyField(field) {
    if (!field) return false;
    if (field.primaryKey || field.isPrimaryKey || field.keyField || field.isKey) return true;
    const role = String(field.role || field.keyRole || "").toLowerCase();
    return role === "primary" || role === "pk" || role === "primarykey";
  }

  function typeGroup(field) {
    const type = fieldType(field);
    if (/logical|boolean|bool/.test(type)) return { key: "logical", label: "Logicos", order: 30 };
    if (/date|datetime|timestamp|time/.test(type)) return { key: "date", label: "Datas", order: 40 };
    if (/integer|int64|int|decimal|numeric|number|float|double|amount|currency|money|packed/.test(type)) return { key: "number", label: "Numericos", order: 10 };
    if (/character|char|varchar|longchar|text|string/.test(type)) return { key: "text", label: "Texto", order: 20 };
    return { key: "other", label: "Outros", order: 90 };
  }

  function visibleRowKeys(row) {
    return Object.keys(row || {}).filter(function (fieldName) {
      if (typeof fieldName !== "string") return false;
      if (!fieldName || fieldName.charAt(0) === "_") return false;
      return ["uid", "dirty", "__index", "editable"].indexOf(fieldName) < 0;
    });
  }

  function buildSections(row, fieldsByName, fields) {
    const knownFields = {};
    const sections = [];
    const primary = [];
    const grouped = {};
    const orderedKeys = visibleRowKeys(row)
      .filter(function (fieldName) { return !!fieldsByName[fieldName]; })
      .sort(function (left, right) {
        const leftOrder = fieldsByName[left] ? fieldsByName[left].__seq || 0 : 9999;
        const rightOrder = fieldsByName[right] ? fieldsByName[right].__seq || 0 : 9999;
        return leftOrder - rightOrder;
      });

    (fields || []).forEach(function (field) {
      if (isPrimaryKeyField(field) && field.name && row && Object.prototype.hasOwnProperty.call(row, field.name)) {
        knownFields[field.name] = true;
        primary.push(field.name);
      }
    });

    orderedKeys.forEach(function (fieldName) {
      if (knownFields[fieldName]) return;
      const group = typeGroup(fieldsByName[fieldName]);
      if (!grouped[group.key]) {
        grouped[group.key] = { key: group.key, label: group.label, order: group.order, fields: [] };
      }
      grouped[group.key].fields.push(fieldName);
    });

    if (primary.length) {
      sections.push({ key: "primary", label: "Chave primaria", order: 0, fields: primary });
    }

    Object.keys(grouped)
      .map(function (key) { return grouped[key]; })
      .sort(function (left, right) { return left.order - right.order; })
      .forEach(function (section) {
        if (section.fields.length) sections.push(section);
      });

    return sections;
  }

  function renderField($, panel, context, fieldName) {
    const fieldMeta = context.fieldsByName[fieldName] || {};
    const value = context.row[fieldName];
    const joinOptions = context.joinOptionsByField[fieldName] || [];
    const baseDisplayValue = context.formatValue(fieldMeta, value);
    const description = context.descriptionForField(fieldName, value);
    const displayValue = description ? baseDisplayValue + " - " + description : baseDisplayValue;
    const rawValue = normalizeText(value);
    const hasDescribedValue = displayValue !== rawValue;
    const longText = context.isLongTextField(fieldMeta, value);
    const wrapper = $("<div class='record-field'></div>");
    if (longText) wrapper.addClass("full-row");
    const title = $("<div class='record-field-title-row'></div>");
    const joinButton = context.createJoinButton(fieldName, value, joinOptions);
    if (joinButton) title.append(joinButton);
    title.append($("<label></label>").text(fieldMeta.label || fieldName));
    const input = $("<input type='text' readonly />").addClass("record-field-input");
    input.val(displayValue);
    if (hasDescribedValue) input.attr("title", value == null ? "" : String(value));
    wrapper.append(title, input);
    panel.append(wrapper);
    context.applyWidget(input, fieldMeta, hasDescribedValue);
  }

  function render(options) {
    const $ = global.jQuery || global.$;
    if (!$) throw new Error("jQuery indisponivel para SursumRecordFormRenderer.");
    const container = $(options.container);
    const row = options.row || {};
    const fields = options.fields || [];
    const fieldsByName = fields.reduce(function (acc, field) {
      if (field && field.name) acc[field.name] = field;
      return acc;
    }, {});
    const context = {
      row: row,
      fieldsByName: fieldsByName,
      joinOptionsByField: options.joinOptionsByField || {},
      descriptionValuesByField: options.descriptionValuesByField || {},
      formatValue: options.formatValue || function (_field, value) { return normalizeText(value); },
      descriptionForField: function (fieldName, value) {
        if (!fieldName || value === null || value === undefined || String(value).trim() === "") return "";
        const lookup = (options.descriptionValuesByField || {})[fieldName];
        return lookup ? (lookup[String(value)] || "") : "";
      },
      createJoinButton: options.createJoinButton || function () { return null; },
      applyWidget: options.applyWidget || function () {},
      isLongTextField: options.isLongTextField || function () { return false; }
    };
    const sections = buildSections(row, fieldsByName, fields);
    container.empty();
    container.removeClass("record-form-grid").addClass("record-form-tabs");

    if (!sections.length) {
      container.append("<div class='status-box'>Sem campos para exibir.</div>");
      return { sections: [] };
    }

    const nav = $("<div class='record-form-tab-nav'></div>");
    const panels = $("<div class='record-form-tab-panels'></div>");
    sections.forEach(function (section, index) {
      const panelId = "record-form-panel-" + section.key;
      const tab = $("<button type='button' class='record-form-tab'></button>");
      tab.text(section.label);
      tab.attr("data-target", "#" + panelId);
      if (index === 0) tab.addClass("active");
      nav.append(tab);

      const panel = $("<section class='record-form-panel'></section>");
      panel.attr("id", panelId);
      if (index === 0) panel.addClass("active");
      const fieldsWrap = $("<div class='record-form-fields'></div>");
      section.fields.forEach(function (fieldName) {
        renderField($, fieldsWrap, context, fieldName);
      });
      panel.append(fieldsWrap);
      panels.append(panel);
    });

    container.append(nav, panels);
    container.off("click.sursumRecordFormTabs", ".record-form-tab");
    container.on("click.sursumRecordFormTabs", ".record-form-tab", function () {
      const target = $(this).data("target");
      container.find(".record-form-tab").removeClass("active");
      $(this).addClass("active");
      container.find(".record-form-panel").removeClass("active");
      container.find(target).addClass("active");
    });

    return { sections: sections };
  }

  global.SursumRecordFormRenderer = {
    render: render,
    buildSections: buildSections
  };
})(window);
