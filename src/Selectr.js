var Selectr;

$.fn.extend({
  selectr: function(options) {
    return this.each(function() {
      return $(this).data("selectr", new Selectr($(this), options));
    });
  }
});

Selectr = (function() {
  function Selectr(select, opts) {
    this.select = $(select);
    this.settings = $.extend({}, this.defaultSettings, opts);
    if (this.select.attr("multiple")) {
      this.settings.multiple = true;
    }
    this.setup();
  }

  Selectr.prototype.setup = function() {
    this.data = this.createData();
    return this.wrap = this.createSelectrDOM();
  };

  Selectr.prototype.createData = function() {
    var option, _i, _len, _ref, _results;
    _ref = this.select.find("optgroup, option");
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      option = _ref[_i];
      _results.push({
        label: $(option).attr("label") || "",
        text: $(option).text(),
        value: $(option).val(),
        disabled: $(option).is(':disabled'),
        selected: $(option).is(':selected')
      });
    }
    return _results;
  };

  Selectr.prototype.createListFromData = function(data) {
    var liHtml, list;
    if (!data) {
      data = this.data;
    }
    list = $("<ul class=\"selectr-results\"></ul>");
    liHtml = "";
    $(this.data).each(function(i, row) {
      if (row.label !== "") {
        liHtml += "<li class=\"selectr-label\">" + row.label + "</li>";
      } else {
        liHtml += "<li id=\"selectr-item-" + i + "\" class=\"selectr-item";
        if (row.value === "") {
          liHtml += " selectr-hidden";
        }
        if (row.selected) {
          liHtml += " selectr-selected";
        }
        if (row.disabled) {
          liHtml += " selectr-disabled";
        }
        liHtml += "\">";
        liHtml += "  <button type=\"button\" data-value=\"" + row.value + "\"\n    data-selected=\"" + row.selected + "\" data-disabled=\"" + row.disabled + "\">\n      " + row.text + "\n  </button>\n</li>";
      }
    });
    list.append(liHtml);
    return list;
  };

  Selectr.prototype.getDefaultText = function() {
    return "Hello!";
  };

  Selectr.prototype.createSelectrDOM = function() {
    var dropdownWrap, msSearchInput, multiSelectWrap, resultsList, searchInput, searchWrap, selectionList, toggleBtn, wrap;
    wrap = $("<div />", {
      "class": "selectr-wrap",
      width: this.settings.width
    });
    toggleBtn = $("<a />", {
      "class": "selectr-toggle",
      tabindex: this.select.attr("tabindex") || -1
    });
    toggleBtn.append("<span>" + (this.getDefaultText()) + "</span><div><i></i></div>");
    searchInput = $("<input />", {
      "class": "selectr-search",
      type: "text",
      autocomplete: "off"
    });
    dropdownWrap = $("<div />", {
      "class": "selectr-drop"
    });
    multiSelectWrap = $("<div />", {
      "class": "selectr-selections"
    });
    selectionList = $("<ul />");
    searchWrap = $("<li />");
    msSearchInput = $("<input />", {
      type: "text",
      "class": "selectr-ms-search selectr-search",
      autocomplete: "off",
      placeholder: ""
    });
    resultsList = this.createListFromData();
    if (this.settings.multiple) {
      multiSelectWrap.append(selectionList.append(searchWrap.append(msSearchInput)));
      dropdownWrap.append(resultsList);
      wrap.append(multiSelectWrap, dropdownWrap).addClass("selectr-multiple");
    } else {
      dropdownWrap.append(searchInput, resultsList);
      wrap.append(toggleBtn, dropdownWrap);
    }
    this.select.hide().after(wrap);
    return wrap;
  };

  Selectr.prototype.defaultSettings = {
    width: 250,
    height: 200,
    multiple: false,
    onResultSelect: function() {}
  };

  return Selectr;

})();

//# sourceMappingURL=../src/Selectr.js.map
