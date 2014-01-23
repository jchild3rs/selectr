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
    this.wrap = this.createSelectrWrap();
    return this.select.hide().after(this.wrap);
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

  Selectr.prototype.createListItem = function(row) {
    var button, className, classNames, li, _i, _len;
    if (row.label !== "") {
      return $("<li />", {
        "class": "selectr-label"
      }).text(row.label);
    } else {
      button = $("<button />", {
        type: "button"
      }).data({
        value: row.value,
        selected: row.selected,
        disabled: row.disabled
      }).text(row.text);
      li = $("<li />").append(button);
      classNames = ["selectr-item", row.value === "" ? "selectr-hidden" : "", row.selected === "" ? "selectr-selected" : "", row.disabled === "" ? "selectr-disabled" : ""];
      for (_i = 0, _len = classNames.length; _i < _len; _i++) {
        className = classNames[_i];
        if (className !== "") {
          li.addClass(className);
        }
      }
      return li;
    }
  };

  Selectr.prototype.createListFromData = function(data) {
    var lis, list, row;
    if (!data) {
      data = this.data;
    }
    list = $("<ul />", {
      "class": "selectr-results"
    });
    lis = (function() {
      var _i, _len, _ref, _results;
      _ref = this.data;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _results.push(this.createListItem(row));
      }
      return _results;
    }).call(this);
    return list.append(lis);
  };

  Selectr.prototype.getDefaultText = function() {
    return "Hello!";
  };

  Selectr.prototype.createSelectrWrap = function() {
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
