(function() {
  var Selectr,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $.fn.extend({
    selectr: function(options) {
      return this.each(function() {
        return $(this).data("selectr", new Selectr($(this), options));
      });
    }
  });

  Selectr = (function() {
    function Selectr(select, opts) {
      this.selectionWrapClick = __bind(this.selectionWrapClick, this);
      this.searchInputClick = __bind(this.searchInputClick, this);
      this.searchInputFocus = __bind(this.searchInputFocus, this);
      this.toggleBtnFocus = __bind(this.toggleBtnFocus, this);
      this.toggleBtnClick = __bind(this.toggleBtnClick, this);
      this.resultItemClick = __bind(this.resultItemClick, this);
      this.focusSearchInput = __bind(this.focusSearchInput, this);
      this.toggleDrop = __bind(this.toggleDrop, this);
      this.handleDocumentClick = __bind(this.handleDocumentClick, this);
      this.select = $(select);
      this.settings = $.extend({}, this.defaultSettings, opts);
      if (this.select.attr("multiple")) {
        this.settings.multiple = true;
      }
      this.settings.tabindex = this.select.attr("tabindex");
      this.setup();
    }

    Selectr.prototype.setup = function() {
      this.data = this.createData();
      this.wrap = this.createSelectrWrap();
      this.select.hide().after(this.wrap);
      this.select.attr("tabindex", "-1");
      return this.bindEvents();
    };

    Selectr.prototype.handleDocumentClick = function(e) {
      if (e.currentTarget === document && this.wrap.find(".selectr-drop").is(":visible")) {
        this.hideAllDropDowns();
        $(document).off("click", this.handleDocumentClick);
      }
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.showDropDown = function() {
      var drop;
      this.hideAllDropDowns();
      drop = this.wrap.find(".selectr-drop");
      this.wrap.addClass("selectr-open");
      if (!this.settings.multiple) {
        this.focusSearchInput();
      }
      drop.show();
      return $(document).on("click", this.handleDocumentClick);
    };

    Selectr.prototype.hideAllDropDowns = function() {
      if ($(".selectr-open").length > 0) {
        return $(".selectr-open").removeClass("selectr-open").find(".selectr-drop").hide();
      }
    };

    Selectr.prototype.toggleDrop = function(e) {
      var drop;
      drop = this.wrap.find(".selectr-drop");
      if (this.wrap.hasClass("selectr-open")) {
        this.hideAllDropDowns();
      } else {
        this.showDropDown();
      }
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.focusSearchInput = function() {
      return this.wrap.find(".selectr-search").trigger("focus.selectr");
    };

    Selectr.prototype.resultItemClick = function(e) {
      e.stopPropagation();
      return e.preventDefault();
    };

    Selectr.prototype.toggleBtnClick = function(e) {
      return this.toggleDrop(e);
    };

    Selectr.prototype.toggleBtnFocus = function(e) {
      e.preventDefault();
      e.stopPropagation();
      if (!this.settings.multiple) {
        return this.hideAllDropDowns();
      } else {
        return this.wrap.find(".selectr-search").focus();
      }
    };

    Selectr.prototype.searchInputFocus = function(e) {
      if (this.settings.multiple) {
        this.showDropDown();
      }
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.searchInputClick = function(e) {
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.selectionWrapClick = function(e) {
      this.focusSearchInput();
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.bindEvents = function() {
      this.wrap.find(".selectr-toggle").on({
        "click.selectr": this.toggleDrop,
        "focus.selectr": this.toggleBtnFocus
      });
      this.wrap.find(".selectr-drop").on("click", ".selectr-item", this.resultItemClick);
      this.wrap.find(".selectr-search").on({
        "focus.selectr": this.searchInputFocus,
        "click.selectr": this.searchInputClick
      });
      return this.wrap.find(".selectr-selections").on("click.selectr", this.selectionWrapClick);
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
        classNames = ["selectr-item", row.value === "" ? "selectr-hidden" : "", row.selected ? "selectr-selected" : "", row.disabled ? "selectr-disabled" : ""];
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
      if (this.settings.placeholder) {
        return this.settings.placeholder;
      } else if (this.select.data("placeholder")) {
        return this.select.data("placeholder");
      } else if (this.select.attr("placeholder")) {
        return this.select.attr("placeholder");
      } else if (this.select.find("option:empty").text()) {
        return this.select.find("option:empty").text();
      } else {
        return "Select an option";
      }
    };

    Selectr.prototype.createSelectrWrap = function() {
      var dropdownWrap, msSearchInput, multiSelectWrap, resultsList, searchInput, searchWrap, selectionList, toggleBtn, wrap;
      wrap = $("<div />", {
        "class": "selectr-wrap",
        width: this.settings.width
      });
      toggleBtn = $("<a />", {
        "class": "selectr-toggle",
        tabindex: this.select.attr("tabindex") || ""
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
        placeholder: "",
        tabindex: this.select.attr('tabindex')
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

}).call(this);

//# sourceMappingURL=../src/Selectr.js.map
