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
    var isValidKeyCode;

    Selectr.prototype.defaultSettings = {
      width: 250,
      height: 200,
      multiple: false,
      onResultSelect: function() {}
    };

    function Selectr(select, providedSettings) {
      this.select = select;
      this.providedSettings = providedSettings;
      this.selectionWrapClick = __bind(this.selectionWrapClick, this);
      this.searchInputKeyUp = __bind(this.searchInputKeyUp, this);
      this.searchInputKeyDown = __bind(this.searchInputKeyDown, this);
      this.searchInputClick = __bind(this.searchInputClick, this);
      this.searchInputFocus = __bind(this.searchInputFocus, this);
      this.toggleBtnKeyDown = __bind(this.toggleBtnKeyDown, this);
      this.toggleBtnClick = __bind(this.toggleBtnClick, this);
      this.resultItemClick = __bind(this.resultItemClick, this);
      this.handleDocumentClick = __bind(this.handleDocumentClick, this);
      this.selectionItemClick = __bind(this.selectionItemClick, this);
      this.constructSettings();
      this.createDataModel();
      this.createSelectrWrap();
      this.bindEvents();
    }

    Selectr.prototype.constructSettings = function() {
      this.settings = $.extend({}, this.defaultSettings, this.providedSettings);
      if (this.select.attr("multiple")) {
        this.settings.multiple = true;
      }
      return this.settings.tabindex = this.select.attr("tabindex");
    };

    Selectr.prototype.showDropDown = function() {
      this.hideAllDropDowns();
      this.wrap.addClass("selectr-open");
      this.wrap.find(".selectr-drop").show();
      if (this.wrap.find(".selectr-active").length === 0) {
        this.wrap.find(".selectr-item").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active");
      }
      this.moveScrollDownToItem();
      return $(document).on("click.selectr", this.handleDocumentClick);
    };

    Selectr.prototype.hideAllDropDowns = function() {
      if ($(".selectr-open").length > 0) {
        return $(".selectr-open").removeClass("selectr-open").find(".selectr-drop").hide();
      }
    };

    Selectr.prototype.resetDropDown = function() {
      var newResultsList;
      newResultsList = this.createListFromData(this.originalData);
      return this.wrap.find(".selectr-results").replaceWith(newResultsList);
    };

    Selectr.prototype.focusSearchInput = function() {
      var searchInput;
      searchInput = this.wrap.find(".selectr-search");
      if (!searchInput.is(":focus")) {
        return this.wrap.find(".selectr-search").trigger("focus.selectr");
      }
    };

    Selectr.prototype.bindEvents = function() {
      this.wrap.find(".selectr-toggle").on({
        "click.selectr": this.toggleBtnClick,
        "keydown.selectr": this.toggleBtnKeyDown
      });
      this.wrap.find(".selectr-drop").on("click.selectr", ".selectr-item", this.resultItemClick);
      this.wrap.find(".selectr-search").on({
        "focus.selectr": this.searchInputFocus,
        "click.selectr": this.searchInputClick,
        "keyup.selectr": this.searchInputKeyUp,
        "keydown.selectr": this.searchInputKeyDown
      });
      return this.wrap.find(".selectr-selections").on("click.selectr", this.selectionWrapClick).on("click.selectr", ".selectr-pill", this.selectionItemClick);
    };

    Selectr.prototype.selectionItemClick = function(e) {
      e.preventDefault();
      e.stopPropagation();
      return this.removeSelection($(e.currentTarget));
    };

    Selectr.prototype.handleDocumentClick = function(e) {
      if (e.currentTarget === document && this.wrap.find(".selectr-drop").is(":visible")) {
        this.hideAllDropDowns();
        $(document).off("click.selectr", this.handleDocumentClick);
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

    Selectr.prototype.toggleBtnClick = function(e) {
      if (!this.wrap.find(".selectr-drop").is(":visible")) {
        this.showDropDown();
        this.focusSearchInput();
      } else {
        this.hideAllDropDowns();
      }
      e.stopPropagation();
      return e.preventDefault();
    };

    Selectr.prototype.toggleBtnKeyDown = function(e) {
      var stroke;
      stroke = e.which || e.keyCode;
      if (stroke === 40 || stroke === 13) {
        this.showDropDown();
        return this.focusSearchInput();
      }
    };

    Selectr.prototype.searchInputFocus = function(e) {
      if (this.settings.multiple) {
        this.showDropDown();
        this.scaleSearchField();
      }
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.scaleSearchField = function() {
      var defaultStyles, div, newWidth, searchField, style, styles, wrapWidth, _i, _len;
      if (this.settings.multiple) {
        searchField = this.wrap.find(".selectr-search").removeAttr("placeholder");
        defaultStyles = "position:absolute; left: -1000px; top: -1000px; display:none;";
        styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'];
        for (_i = 0, _len = styles.length; _i < _len; _i++) {
          style = styles[_i];
          defaultStyles += style + ":" + searchField.css(style) + ";";
        }
        div = $('<div />', {
          'style': defaultStyles
        });
        div.text(searchField.val());
        $('body').append(div);
        newWidth = div.width() + 25;
        div.remove();
        wrapWidth = this.wrap.width();
        if (newWidth > wrapWidth - 10) {
          newWidth = wrapWidth - 10;
        }
        return searchField.width(newWidth);
      }
    };

    Selectr.prototype.searchInputClick = function(e) {
      e.preventDefault();
      return e.stopPropagation();
    };

    Selectr.prototype.searchInputKeyDown = function(e) {
      var currentScrollTop, drop, gutter, hasSelection, next, offset, prev, query, resultList, selected, selectedHeight, stroke, toggleBtn;
      stroke = e.which || e.keyCode;
      query = e.currentTarget.value;
      selected = this.wrap.find(".selectr-active");
      hasSelection = selected.length !== 0;
      drop = this.wrap.find(".selectr-drop");
      resultList = this.wrap.find(".selectr-results");
      toggleBtn = this.wrap.find(".selectr-toggle");
      this.scaleSearchField();
      switch (stroke) {
        case 9:
          if (drop.is(":visible")) {
            this.hideAllDropDowns();
            toggleBtn.focus();
          }
          break;
        case 27:
          this.hideAllDropDowns();
          toggleBtn.focus();
          break;
        case 38:
          if (hasSelection && selected.index() !== 0) {
            prev = selected.prevAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first();
            if (prev.length !== 0) {
              selected.removeClass("selectr-active");
              prev.addClass("selectr-active");
              currentScrollTop = resultList.scrollTop() + resultList.height();
              selectedHeight = (prev.index()) * selected.height();
              offset = currentScrollTop - (resultList.height() - selected.height());
              if (offset > selectedHeight) {
                resultList.scrollTop((resultList.scrollTop() + selectedHeight) - offset);
              }
            }
          }
          e.preventDefault();
          break;
        case 40:
          if (this.settings.multiple) {
            this.showDropDown();
          }
          if (!hasSelection) {
            this.wrap.find(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active");
          } else {
            next = selected.nextAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first();
            if (next.length !== 0) {
              gutter = this.settings.multiple ? 1 : 0;
              selected.removeClass("selectr-active");
              next.addClass("selectr-active");
              this.moveScrollDownToItem();
            }
          }
          e.preventDefault();
          break;
        case 13:
          if (hasSelection) {
            this.makeSelection();
            this.wrap.find(".selectr-search").val("");
            this.resetDropDown();
            break;
          }
          break;
        case 8:
          if (this.settings.multiple && query.length === 0 && this.wrap.find(".selectr-pill").length > 0) {
            this.removeSelection(this.wrap.find(".selectr-pill").last());
            e.preventDefault();
          }
          break;
        default:
          break;
      }
      return this;
    };

    Selectr.prototype.moveScrollDownToItem = function() {
      var currentScrollTop, gutter, next, offset, resultList, selectedHeight;
      gutter = this.settings.multiple ? 1 : 0;
      console.log(gutter, this.wrap.find(".selectr-hidden").length);
      next = this.wrap.find(".selectr-active");
      resultList = this.wrap.find(".selectr-results");
      currentScrollTop = resultList.scrollTop() + resultList.height();
      selectedHeight = (next.index() + gutter) * next.height();
      offset = selectedHeight - currentScrollTop;
      if (selectedHeight > currentScrollTop) {
        return resultList.scrollTop(resultList.scrollTop() + offset);
      }
    };

    Selectr.prototype.searchInputKeyUp = function(e) {
      var newResultsList, query, resultContainer, resultData, stroke;
      stroke = e.which || e.keyCode;
      if (isValidKeyCode(stroke)) {
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
            this.showDropDown();
          }
        } else {
          this.resetDropDown();
        }
        if (!this.wrap.find(".selectr-drop").is(":visible")) {
          return this.showDropDown();
        }
      }
    };

    /*
    If multiple, we want to focus the input when the user
    clicks on the wrap. The input will have a variable width.
    */


    Selectr.prototype.selectionWrapClick = function(e) {
      if (this.settings.multiple) {
        this.focusSearchInput();
        e.preventDefault();
        return e.stopPropagation();
      }
    };

    Selectr.prototype.createDataModel = function() {
      var option;
      return this.originalData = this.data = (function() {
        var _i, _len, _ref, _results;
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
      }).call(this);
    };

    Selectr.prototype.findMatchesInItem = function(item, query) {
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
          _results.push(this.findMatchesInItem(item, query));
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
        if (this.wrap.find(".selectr-drop").is(":visible")) {
          return this.hideAllDropDowns();
        }
      }
    };

    Selectr.prototype.addSelection = function() {
      var pill, search, selectedItem, val;
      selectedItem = this.wrap.find(".selectr-item.selectr-active");
      if (selectedItem.hasClass("selectr-selected")) {
        return;
      }
      val = selectedItem.data("value");
      selectedItem.addClass("selectr-selected");
      pill = this.createSelection(selectedItem.text(), val, selectedItem.data('selected'), selectedItem.data('disabled'));
      search = this.wrap.find(".selectr-ms-search");
      search.parent("li").before(pill);
      this.setSelectValue(val);
      search.focus();
      return this.hideAllDropDowns();
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
      this.wrap.find(".selectr-selected:contains('" + val + "')").removeClass("selectr-selected").removeClass("selectr-active");
      opts = this.select.find("option[value='" + val + "']").prop("selected", false);
      if (opts.length === 0) {
        this.select.find(":contains(" + val + ")").prop("selected", false);
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
      return this.wrap.find(".selectr-results").replaceWith("<ul class='selectr-results no-results'>\n  <li class='selectr-item'>No results found for <b>" + query + "</b></li>\n</ul>");
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
        }).html(row.text);
        li = $("<li />").append(button).data({
          value: row.value,
          selected: row.selected,
          disabled: row.disabled
        });
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
      var dropdownWrap, msSearchInput, multiSelectWrap, resultsList, searchInput, searchWrap, selectionList, toggleBtn;
      this.wrap = $("<div />", {
        "class": "selectr-wrap",
        width: this.settings.width
      });
      toggleBtn = $("<a />", {
        "class": "selectr-toggle",
        tabindex: this.select.attr("tabindex") || ""
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
        tabindex: this.select.attr('tabindex'),
        width: this.settings.width - 20
      });
      resultsList = this.createListFromData(this.data);
      if (this.settings.multiple) {
        multiSelectWrap.append(selectionList.append(searchWrap.append(msSearchInput)));
        dropdownWrap.append(resultsList);
        this.wrap.append(multiSelectWrap, dropdownWrap).addClass("selectr-multiple");
      } else {
        dropdownWrap.append(searchInput, resultsList);
        this.wrap.append(toggleBtn, dropdownWrap);
      }
      this.select.hide().after(this.wrap).attr("tabindex", "-1");
      this.setDefaultText(this.getDefaultText());
      return this.wrap;
    };

    isValidKeyCode = function(code) {
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
