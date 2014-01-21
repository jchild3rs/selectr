(function($) {
  var Selectr;
  Selectr = (function() {
    var bindEvents, createDataModel, createResultsListFromData, debounce, hideDrop, isValidKeyCode, resultClick, searchDataModel, searchKeyDown, searchKeyUp, setupUI, showDrop, toggleClick;

    function Selectr(select, opts) {
      this.select = select;
      this.options = $.extend({}, $.fn.selectr.defaultOptions, opts);
      if (this.select.attr("multiple")) {
        this.options.multiple = true;
      }
      setupUI(this.select, this.options);
    }

    setupUI = function(select, options) {
      var dropdownWrap, multiSelectWrap, resultsList, searchInput, selected, toggleBtn, wrap;
      selected = select.find(":selected");
      wrap = $("<div/>", {
        "class": "selectr-wrap"
      }).css({
        width: options.width
      });
      toggleBtn = $("<a />", {
        "class": "selectr-toggle"
      }).append("<span>" + (selected.text()) + "</span><div><i></i></div>");
      searchInput = $("<input />", {
        "class": "selectr-search",
        type: "text",
        autocomplete: "off"
      });
      dropdownWrap = $("<div />", {
        "class": "selectr-drop"
      });
      multiSelectWrap = $("<div class=\"selectr-selections\"> \n  <ul>\n    <li>\n      <input type=\"text\" class=\"selectr-ms-input\" placeholder=\"" + (selected.text()) + "\" />\n    </li>\n  </ul>\n</div>");
      resultsList = createResultsListFromData(createDataModel(select));
      if (options.multiple) {
        dropdownWrap.append(resultsList);
        wrap.append(multiSelectWrap, dropdownWrap);
      } else {
        dropdownWrap.append(searchInput, resultsList);
        wrap.append(toggleBtn, dropdownWrap);
      }
      wrap = bindEvents(select, wrap);
      return select.hide().after(wrap);
    };

    showDrop = function(wrap) {
      var drop;
      wrap.addClass("selectr-open");
      wrap.find(".selectr-selected").removeClass("selectr-selected");
      drop = wrap.find(".selectr-drop");
      return drop.show();
    };

    hideDrop = function(wrap) {
      var drop;
      wrap.removeClass("selectr-open");
      drop = wrap.find(".selectr-drop");
      return drop.hide();
    };

    searchKeyUp = function(e, data, wrap) {
      var newResultsList, query, resultContainer, resultData, stroke;
      stroke = e.which || e.keyCode;
      if (isValidKeyCode(stroke)) {
        query = e.currentTarget.value;
        resultContainer = wrap.find(".selectr-results");
        if (query.length > 0) {
          resultData = searchDataModel(query, data);
          if (resultData.length > 0) {
            newResultsList = createResultsListFromData(resultData);
            return resultContainer.replaceWith(newResultsList);
          } else {
            return resultContainer.replaceWith("<ul class='selectr-results no-results'><li class='selectr-item'>No results found for <b>" + query + "</b></li></ul>");
          }
        } else {
          newResultsList = createResultsListFromData(data);
          return wrap.find(".selectr-results").replaceWith(newResultsList);
        }
      }
    };

    searchKeyDown = function(e, wrap) {
      var currentScrollTop, drop, hasSelection, offset, resultList, selected, selectedHeight, stroke;
      stroke = e.which || e.keyCode;
      selected = wrap.find(".selectr-selected");
      hasSelection = selected.length !== 0;
      drop = wrap.find(".selectr-drop");
      resultList = wrap.find(".selectr-results");
      switch (stroke) {
        case 38:
          if (hasSelection && selected.index() !== 0) {
            selected.removeClass("selectr-selected");
            selected.prev(":visible").addClass("selectr-selected");
            currentScrollTop = resultList.scrollTop() + resultList.height();
            selectedHeight = (selected.index() - 1) * selected.height();
            offset = currentScrollTop - (resultList.height() - selected.height());
            if (offset > selectedHeight) {
              resultList.scrollTop(resultList.scrollTop() + selectedHeight - offset);
            }
          }
          e.preventDefault();
          break;
        case 40:
          if (!hasSelection) {
            wrap.find(".selectr-item:visible").first().addClass("selectr-selected");
          } else {
            if (selected.next().length === 0) {
              break;
            } else {
              selected.removeClass("selectr-selected");
              selected.next(":visible").addClass("selectr-selected");
              currentScrollTop = resultList.scrollTop() + resultList.height();
              selectedHeight = (selected.index() + 1) * selected.height();
              if (selectedHeight > currentScrollTop) {
                offset = selectedHeight - currentScrollTop;
                resultList.scrollTop(resultList.scrollTop() + offset);
              }
            }
          }
          e.preventDefault();
          break;
        case 13:
          if (hasSelection) {
            selected.removeClass("selectr-selected");
            hideDrop(wrap);
            break;
          }
          break;
        default:
          break;
      }
    };

    toggleClick = function(drop, wrap, searchInput) {
      if (!drop.is(":visible")) {
        showDrop(wrap);
        return searchInput.focus();
      } else {
        return hideDrop(wrap);
      }
    };

    resultClick = function() {};

    bindEvents = function(select, wrap) {
      var data, drop, resultsList, searchInput, toggleBtn;
      toggleBtn = wrap.find(".selectr-toggle");
      drop = wrap.find(".selectr-drop");
      searchInput = wrap.find(".selectr-search");
      resultsList = wrap.find(".selectr-results");
      data = createDataModel(resultsList);
      drop.delegate(".selectr-results button", "click", function() {
        return resultClick();
      });
      drop.delegate(".selectr-item", "mouseover", function(e) {
        wrap.find(".selectr-selected").removeClass("selectr-selected");
        return $(e.currentTarget).addClass("selectr-selected");
      });
      toggleBtn.click(function(e) {
        toggleClick(drop, wrap, searchInput);
        return e.preventDefault();
      });
      searchInput.keyup(debounce(250, function(e) {
        return searchKeyUp(e, data, wrap);
      }));
      searchInput.keydown(function(e) {
        return searchKeyDown(e, wrap);
      });
      return wrap;
    };

    createDataModel = function(el) {
      var data, lis, options;
      options = $(el).find("option");
      data = [];
      if (options.length === 0) {
        lis = $(el).find("li");
        lis.each(function() {
          data.push({
            text: $(this).find("button").text(),
            value: $(this).find("button").data("value"),
            selected: $(this).find("button").data("selected")
          });
        });
      } else {
        options.each(function() {
          data.push({
            text: $(this).text(),
            value: $(this).val(),
            selected: $(this).is(":selected")
          });
        });
      }
      return data;
    };

    searchDataModel = function(query, model) {
      var matches;
      matches = [];
      $(model).each(function(i, item) {
        var match;
        match = item.text.match(new RegExp(query, "ig"));
        if (match != null) {
          match = match.length === 1 ? match[0] : match;
          matches.push({
            text: item.text.replace(match, "<b>" + match + "</b>"),
            value: item.value,
            selected: item.selected
          });
        }
      });
      return matches;
    };

    createResultsListFromData = function(data) {
      var liHtml, list;
      list = $("<ul class=\"selectr-results\"></ul>");
      liHtml = "";
      $(data).each(function(i, row) {
        liHtml += "<li class=\"selectr-item\" id=\"selectr-item-" + i + "\"";
        if (row.value === "") {
          liHtml += " style=\"display: none;\">";
        } else {
          liHtml += ">";
        }
        liHtml += "<button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected + "\">" + row.text + "</button></li>";
      });
      list.append(liHtml);
      return list;
    };

    debounce = function(threshold, func, execAsap) {
      var timeout;
      timeout = void 0;
      return function() {
        var args, delayed, obj;
        delayed = function() {
          if (!execAsap) {
            func.apply(obj, args);
          }
          return timeout = null;
        };
        obj = this;
        args = arguments;
        if (timeout) {
          clearTimeout(timeout);
        } else {
          if (execAsap) {
            func.apply(obj, args);
          }
        }
        return timeout = setTimeout(delayed, threshold || 100);
      };
    };

    isValidKeyCode = function(code) {
      var backspaceOrDelete, isntEnterOrReturn, isntUpOrDown, space, validAlpha, validMath, validNumber, validPunc;
      validAlpha = code >= 65 && code <= 90;
      validNumber = code >= 48 && code <= 57;
      validPunc = (code >= 185 && code <= 192) || (code >= 219 && code <= 222) && code !== 220;
      validMath = code >= 106 && code <= 111;
      space = code === 32;
      isntUpOrDown = code !== 38 && code !== 40;
      isntEnterOrReturn = code !== 13;
      backspaceOrDelete = code === 8 || code === 46;
      return isntUpOrDown && isntEnterOrReturn && (validAlpha || validNumber || validPunc || validMath || space || backspaceOrDelete);
    };

    return Selectr;

  })();
  $.fn.selectr = function(options) {
    return this.each(function() {
      return new Selectr($(this), options);
    });
  };
  return $.fn.selectr.defaultOptions = {
    width: 250,
    onResultSelect: function() {}
  };
})(jQuery);

//# sourceMappingURL=../src/Selectr.js.map
