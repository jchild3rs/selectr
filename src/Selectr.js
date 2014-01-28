(function() {
  var Selectr;

  $.fn.extend({
    selectr: function(options) {
      return this.each(function() {
        return $(this).data("selectr", new Selectr($(this), options));
      });
    }
  });

  Selectr = (function() {
    function Selectr(select, providedSettings) {
      this.select = select;
      this.constructSettings(providedSettings);
      this.createDataModel();
      this.createSelectrWrap();
      this.bindEvents();
    }

    Selectr.prototype.defaultSettings = {
      wrapWidth: 250,
      wrapHeight: 200,
      itemHeight: 30,
      multiple: false,
      tabindex: -1,
      placeholder: ""
    };

    Selectr.prototype.constructSettings = function(providedSettings) {
      this.settings = $.extend({}, this.defaultSettings, providedSettings);
      if (this.select.attr("multiple")) {
        this.settings.multiple = true;
      }
      this.settings.tabindex = this.select.attr("tabindex");
      return this.settings.placeholder = this.getDefaultText();
    };

    Selectr.prototype.dropDownShow = function() {
      var _this = this;
      this.dropDownHide();
      this.wrap.addClass("selectr-open");
      this.wrap.find(".selectr-drop").show();
      this.focusFirstItem();
      this.scrollResultsToItem();
      if (this.settings.multiple) {
        this.scaleSearchField();
      }
      return $(document).on("click.selectr", function(e) {
        return _this.handleDocumentClick(e);
      });
    };

    Selectr.prototype.dropDownHide = function() {
      if ($(".selectr-open").length > 0) {
        return $(".selectr-open").removeClass("selectr-open").find(".selectr-drop").hide();
      }
    };

    Selectr.prototype.dropDownReset = function() {
      var newResultsList;
      newResultsList = this.createListFromData(this.originalData);
      this.wrap.find(".selectr-results").replaceWith(newResultsList);
      return this.wrap.trigger("focus.selectr");
    };

    Selectr.prototype.bindEvents = function() {
      var _this = this;
      this.wrap.on({
        "click.selectr": function(e) {
          return _this.wrapClick(e);
        },
        "keydown.selectr": function(e) {
          return _this.wrapKeyDown(e);
        }
      });
      this.wrap.find(".selectr-drop").on("click.selectr", ".selectr-item", function(e) {
        return _this.resultItemClick(e);
      });
      this.wrap.find(".selectr-search").on({
        "focus.selectr": function(e) {
          return _this.searchInputFocus(e);
        },
        "click.selectr": function(e) {
          return _this.searchInputClick(e);
        },
        "keyup.selectr": function(e) {
          return _this.searchInputKeyUp(e);
        },
        "keydown.selectr": function(e) {
          return _this.searchInputKeyDown(e);
        }
      });
      if (this.settings.multiple) {
        return this.wrap.find(".selectr-selections").on("click.selectr", function(e) {
          return _this.selectionWrapClick(e);
        }).on("click.selectr", ".selectr-pill", function(e) {
          return _this.selectionItemClick(e);
        });
      }
    };

    Selectr.prototype.selectionItemClick = function(e) {
      this.removeSelection($(e.currentTarget));
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.handleDocumentClick = function(e) {
      if (e.currentTarget === document) {
        this.dropDownHide();
        $(document).off("click.selectr");
      }
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.resultItemClick = function(e) {
      this.wrap.find(".selectr-active").removeClass("selectr-active");
      $(e.currentTarget).addClass("selectr-active");
      this.makeSelection();
      e.stopPropagation();
      return e.preventDefault();
    };

    Selectr.prototype.wrapClick = function(e) {
      if (!this.wrap.find(".selectr-drop").is(":visible")) {
        this.dropDownShow();
        this.focusSearchInput();
      } else {
        this.dropDownHide();
      }
      e.stopPropagation();
      return e.preventDefault();
    };

    Selectr.prototype.wrapKeyDown = function(e) {
      var stroke;
      stroke = e.which || e.keyCode;
      if (!this.wrap.find(".selectr-drop").is(":visible")) {
        if (stroke === 40) {
          this.dropDownShow();
          this.focusSearchInput();
          e.preventDefault();
          return e.stopPropagation();
        }
      }
    };

    Selectr.prototype.searchInputFocus = function(e) {
      if (this.settings.multiple) {
        this.dropDownShow();
      }
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.searchInputClick = function(e) {
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.searchInputKeyDown = function(e) {
      this.scaleSearchField();
      switch (e.which || e.keyCode) {
        case 9:
          this.searchInputTabPress();
          break;
        case 27:
          this.searchInputUpEscPress(e);
          break;
        case 38:
          this.searchInputUpArrowPress(e);
          break;
        case 40:
          this.searchInputDownArrowPress(e);
          break;
        case 13:
          this.searchInputEnterPress(e);
          break;
        case 8:
          this.searchInputUpDeletePress(e);
          break;
        default:
          break;
      }
    };

    Selectr.prototype.searchInputTabPress = function() {
      this.dropDownHide();
      return this.wrap.focus();
    };

    Selectr.prototype.searchInputEnterPress = function(e) {
      var hasSelection, selected;
      selected = this.wrap.find(".selectr-active");
      hasSelection = selected.length !== 0;
      if (hasSelection) {
        this.makeSelection();
        this.wrap.find(".selectr-search").val("");
        this.dropDownReset();
        this.focusFirstItem();
        this.scrollResultsToItem();
      }
      return e.preventDefault();
    };

    Selectr.prototype.searchInputDownArrowPress = function(e) {
      var hasSelection, next, selected;
      selected = this.wrap.find(".selectr-active");
      hasSelection = selected.length !== 0;
      if (this.settings.multiple) {
        this.dropDownShow();
      }
      if (!hasSelection) {
        this.wrap.find(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active");
      } else {
        next = selected.nextAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first();
        if (next.length !== 0) {
          selected.removeClass("selectr-active");
          next.addClass("selectr-active");
          this.scrollResultsToItem();
        }
      }
      return e.preventDefault();
    };

    Selectr.prototype.searchInputUpArrowPress = function(e) {
      var currentScrollTop, hasSelection, offset, prev, resultList, selected, selectedHeight;
      selected = this.wrap.find(".selectr-active");
      hasSelection = selected.length !== 0;
      resultList = this.wrap.find(".selectr-results");
      if (hasSelection && selected.index() !== 0) {
        prev = selected.prevAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first();
        if (prev.length !== 0) {
          selected.removeClass("selectr-active");
          prev.addClass("selectr-active");
          currentScrollTop = resultList.scrollTop() + resultList.height();
          selectedHeight = (prev.index()) * selected.height();
          offset = currentScrollTop - (resultList.height() - selected.height());
          if (offset > selectedHeight) {
            resultList.scrollTop(resultList.scrollTop() + selectedHeight - offset);
          }
        }
      }
      return e.preventDefault();
    };

    Selectr.prototype.searchInputUpEscPress = function(e) {
      this.dropDownHide();
      this.wrap.focus();
      return e.preventDefault();
    };

    Selectr.prototype.searchInputUpDeletePress = function(e) {
      var query;
      query = e.currentTarget.value;
      if ((this.settings.multiple && query.length === 0) && (this.wrap.find(".selectr-pill").length > 0)) {
        this.removeSelection(this.wrap.find(".selectr-pill").last());
        return e.preventDefault();
      }
    };

    Selectr.prototype.scrollResultsToItem = function() {
      var currentScrollTop, gutter, next, offset, resultList, selectedHeight;
      gutter = this.settings.multiple ? 1 : 0;
      next = this.wrap.find(".selectr-active");
      resultList = this.wrap.find(".selectr-results");
      currentScrollTop = resultList.scrollTop() + resultList.outerHeight();
      selectedHeight = (next.index() + gutter) * next.outerHeight();
      offset = selectedHeight - currentScrollTop;
      if (selectedHeight > currentScrollTop) {
        return resultList.scrollTop(resultList.scrollTop() + offset);
      }
    };

    Selectr.prototype.searchInputKeyUp = function(e) {
      var newResultsList, query, resultContainer, resultData, stroke;
      stroke = e.which || e.keyCode;
      if (this.isValidKeyCode(stroke)) {
        query = e.currentTarget.value;
        resultContainer = this.wrap.find(".selectr-results");
        if (query.length > 0) {
          resultData = this.searchDataModel(query);
          if (resultData.length > 0) {
            newResultsList = this.createListFromData(resultData);
            resultContainer.replaceWith(newResultsList.get(0).outerHTML);
          } else {
            this.showNoResults(query);
          }
          this.wrap.find(".selectr-label").hide();
          this.wrap.find(".selectr-label ~ .selectr-item:visible").prev().show();
          if (!this.wrap.find(".selectr-drop").is(":visible")) {
            this.dropDownShow();
          }
        } else {
          this.dropDownReset();
        }
        if (!this.wrap.find(".selectr-drop").is(":visible")) {
          return this.dropDownShow();
        }
      }
    };

    Selectr.prototype.selectionWrapClick = function(e) {
      if (this.settings.multiple) {
        this.focusSearchInput();
        e.preventDefault();
        return e.stopPropagation();
      }
    };

    Selectr.prototype.scaleSearchField = function() {
      var defaultStyles, div, newWidth, searchField, style, styles, val, wrapWidth, _i, _len;
      if (this.settings.multiple) {
        searchField = this.wrap.find(".selectr-search");
        defaultStyles = "position:absolute;left:-1000px;top:-1000px;display:none;";
        styles = ["font-size", "font-style", "font-weight", "font-family", "line-height", "text-transform", "letter-spacing"];
        for (_i = 0, _len = styles.length; _i < _len; _i++) {
          style = styles[_i];
          defaultStyles += style + ":" + searchField.css(style) + ";";
        }
        div = $("<div />", {
          "style": defaultStyles
        });
        val = searchField.val();
        if (val !== "" && val.length > this.settings.placeholder.length) {
          div.text(searchField.val());
        } else {
          div.text(this.settings.placeholder);
        }
        $("body").append(div);
        newWidth = div.width() + 25;
        div.remove();
        wrapWidth = this.settings.width;
        if (newWidth > wrapWidth - 10) {
          newWidth = wrapWidth - 10;
        }
        return searchField.width(newWidth);
      }
    };

    Selectr.prototype.focusSearchInput = function() {
      var searchInput;
      searchInput = this.wrap.find(".selectr-search");
      if (!searchInput.is(":focus")) {
        return this.wrap.find(".selectr-search").trigger("focus.selectr");
      }
    };

    Selectr.prototype.focusFirstItem = function() {
      if (this.wrap.find(".selectr-active").length === 0) {
        return this.wrap.find(".selectr-item").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active");
      }
    };

    Selectr.prototype.scrollResultsToItem = function() {
      var currentScrollTop, gutter, next, offset, resultList, selectedHeight;
      gutter = this.settings.multiple ? 1 : 0;
      next = this.wrap.find(".selectr-active");
      resultList = this.wrap.find(".selectr-results");
      currentScrollTop = resultList.scrollTop() + resultList.height();
      selectedHeight = (next.index() + gutter) * next.height();
      offset = selectedHeight - currentScrollTop;
      if (selectedHeight > currentScrollTop) {
        return resultList.scrollTop(resultList.scrollTop() + offset);
      }
    };

    Selectr.prototype.createDataModel = function() {
      var option;
      return this.data = this.originalData = (function() {
        var _i, _len, _ref, _results;
        _ref = this.select.find("optgroup, option");
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          option = _ref[_i];
          _results.push({
            label: $(option).attr("label") || "",
            text: $(option).text(),
            value: $(option).val(),
            disabled: $(option).is(":disabled"),
            selected: $(option).is(":selected")
          });
        }
        return _results;
      }).call(this);
    };

    Selectr.prototype.findMatches = function(item, query) {
      var match;
      if (item.text != null) {
        match = item.text.match(new RegExp(query, "ig"));
        if (match != null) {
          match = match.length === 1 ? match[0] : match;
          return {
            label: item.label,
            text: item.text.replace(match, "<b>" + match + "</b>"),
            value: item.value,
            selected: item.selected,
            disabled: item.disabled
          };
        }
      }
    };

    Selectr.prototype.searchDataModel = function(query) {
      var item, _i, _len, _ref, _results;
      _ref = this.data;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item.text.match(new RegExp(query, "ig"))) {
          _results.push(this.findMatches(item, query));
        }
      }
      return _results;
    };

    Selectr.prototype.makeSelection = function() {
      var selectedItem;
      selectedItem = this.wrap.find(".selectr-active");
      if (this.settings.multiple) {
        return this.addSelection();
      } else {
        this.wrap.find(".selectr-toggle span").text(selectedItem.text());
        this.setSelectValue(selectedItem.data("value"));
        return this.dropDownHide();
      }
    };

    Selectr.prototype.addSelection = function() {
      var pill, search, selectedItem, val;
      selectedItem = this.wrap.find(".selectr-item.selectr-active");
      if (selectedItem.hasClass("selectr-selected") || selectedItem.hasClass("selectr-disabled")) {
        return;
      }
      val = selectedItem.data("value");
      selectedItem.addClass("selectr-selected");
      pill = this.createSelection(selectedItem.text(), val, selectedItem.data("selected"), selectedItem.data("disabled"));
      search = this.wrap.find(".selectr-ms-search");
      search.parent("li").before(pill);
      this.setSelectValue(val);
      return this.wrap.trigger("focus.selectr");
    };

    Selectr.prototype.removeSelection = function(pill) {
      this.unsetSelectValue(pill.data("value"));
      pill.remove();
      return this.focusSearchInput();
    };

    Selectr.prototype.createSelection = function(text, value, selected, disabled) {
      return $("<li/>", {
        "class": "selectr-pill"
      }).data({
        value: value,
        selected: selected,
        disabled: disabled
      }).append("<button>" + text + "</button>");
    };

    Selectr.prototype.unsetSelectValue = function(val) {
      var item, opts, _i, _len, _ref, _results;
      this.wrap.find(".selectr-active").removeClass(".selectr-active");
      this.wrap.find(".selectr-selected:contains('" + val + "')").removeClass("selectr-selected").removeClass("selectr-active");
      opts = this.select.find("option[value='" + val + "']").prop("selected", false);
      if (opts.length === 0) {
        this.select.find(":contains('" + val + "')").prop("selected", false);
      }
      _ref = this.data;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item.value === val) {
          _results.push(item.selected = false);
        }
      }
      return _results;
    };

    Selectr.prototype.setSelectValue = function(val) {
      var item, match, _i, _len, _ref;
      match = false;
      this.select.find("option").each(function(i, option) {
        if ($(option).val() === val && !match) {
          $(option).prop("selected", true);
          return match = true;
        }
      });
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item.value === val) {
          item.selected = true;
        }
      }
      return this;
    };

    Selectr.prototype.getSelectValue = function() {
      this.select.val();
      return this;
    };

    Selectr.prototype.showNoResults = function(query) {
      return this.wrap.find(".selectr-results").replaceWith("<ul class=\"selectr-results no-results\">\n  <li class=\"selectr-item\">No results found for <b>" + query + "</b></li>\n</ul>");
    };

    Selectr.prototype.createListItem = function(row) {
      var button, className, classNames, li, _i, _len;
      if (row.label !== "") {
        li = $("<li />", {
          "class": "selectr-label"
        }).text(row.label);
      } else {
        button = $("<button />", {
          type: "button"
        }).html("<span>" + row.text + "</span>");
        li = $("<li />").append(button).data({
          value: row.value,
          selected: row.selected,
          disabled: row.disabled
        });
        li.css("height", this.settings.itemHeight);
        classNames = ["selectr-item", row.value === "" ? "selectr-hidden" : "", row.selected ? "selectr-selected" : "", row.disabled ? "selectr-disabled" : ""];
        for (_i = 0, _len = classNames.length; _i < _len; _i++) {
          className = classNames[_i];
          if (className !== "") {
            li.addClass(className);
          }
        }
      }
      return li;
    };

    Selectr.prototype.createListFromData = function(data) {
      var lis, list, row;
      list = $("<ul />", {
        "class": "selectr-results"
      });
      lis = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          row = data[_i];
          _results.push(this.createListItem(row));
        }
        return _results;
      }).call(this);
      list.append(lis);
      return list;
    };

    Selectr.prototype.setDefaultText = function(text) {
      if (this.settings.multiple) {
        return this.wrap.find(".selectr-ms-search").attr("placeholder", text);
      } else {
        return this.wrap.find(".selectr-toggle span").text(text);
      }
    };

    Selectr.prototype.getDefaultText = function() {
      if (this.settings.placeholder !== "") {
        return this.settings.placeholder;
      } else if (this.select.data("placeholder")) {
        return this.select.data("placeholder");
      } else if (this.select.attr("placeholder")) {
        return this.select.attr("placeholder");
      } else if (this.select.find("option:empty").text()) {
        return this.select.find("option:empty").text();
      } else {
        return "Select an option...";
      }
    };

    Selectr.prototype.setTabIndex = function() {
      var tabindex;
      this.select.attr("tabindex", -1);
      tabindex = this.settings.tabindex;
      if (this.settings.multiple) {
        return this.wrap.find(".selectr-ms-search").attr("tabindex", tabindex);
      } else {
        return this.wrap[0].tabIndex = tabindex;
      }
    };

    Selectr.prototype.createSelectrWrap = function() {
      var dropdownWrap, hasPreselections, msSearchInput, multiSelectWrap, resultsList, searchInput, searchWrap, selectionList, toggleBtn, wrapStyles,
        _this = this;
      wrapStyles = "width: " + this.settings.wrapWidth + "px;";
      wrapStyles += "max-height: " + (parseInt(this.settings.wrapHeight, 10)) + "px;";
      this.wrap = $("<div />", {
        "class": "selectr-wrap",
        style: wrapStyles
      });
      toggleBtn = $("<a />", {
        "class": "selectr-toggle",
        title: "" + this.settings.placeholder
      });
      toggleBtn.append("<span></span><div><i></i></div>");
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
        tabindex: this.select.attr("tabindex"),
        width: this.settings.wrapWidth - 20
      });
      resultsList = this.createListFromData(this.data);
      if (this.settings.multiple) {
        searchWrap.append(msSearchInput);
        selectionList.append(searchWrap);
        multiSelectWrap.append(selectionList);
        dropdownWrap.append(resultsList);
        this.wrap.append(multiSelectWrap, dropdownWrap).addClass("selectr-multiple");
        if (this.select.val() !== "" && this.select.val().length !== 0) {
          hasPreselections = false;
          this.select.find("option:selected").each(function(i, option) {
            var pill;
            if ($(option).val() !== "") {
              hasPreselections = true;
              pill = _this.createSelection($(option).text(), $(option).val(), $(option).is(":selected"), $(option).is(":disabled"));
              return selectionList.prepend(pill);
            }
          });
          if (hasPreselections) {
            this.scaleSearchField();
          }
        }
      } else {
        dropdownWrap.append(searchInput, resultsList);
        this.wrap.append(toggleBtn, dropdownWrap);
      }
      this.select.hide().after(this.wrap).attr("tabindex", "-1");
      this.setDefaultText(this.settings.placeholder);
      this.setTabIndex();
      return this.wrap;
    };

    Selectr.prototype.isValidKeyCode = function(code) {
      var backspaceOrDelete, isSpace, isntEnter, isntUpOrDown, validAlpha, validMath, validNumber, validPunc;
      validAlpha = code >= 65 && code <= 90;
      validNumber = code >= 48 && code <= 57;
      validPunc = (code >= 185 && code <= 192) || (code >= 219 && code <= 222) && code !== 220;
      validMath = code >= 106 && code <= 111;
      isSpace = code === 32;
      isntUpOrDown = code !== 38 && code !== 40;
      isntEnter = code !== 13;
      backspaceOrDelete = code === 8 || code === 46;
      return isntUpOrDown && isntEnter && (validAlpha || validNumber || validPunc || validMath || isSpace || backspaceOrDelete);
    };

    return Selectr;

  })();

}).call(this);

//# sourceMappingURL=../src/Selectr.js.map
