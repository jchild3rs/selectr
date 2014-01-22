(function($) {
  var Selectr;
  Selectr = (function() {
    var bindEvents, createDataModel, createOptGroupListFromData, createResultsListFromData, debounce, determinePlaceholderText, hideDrop, isValidKeyCode, makeSelection, resultClick, searchDataModel, searchKeyDown, searchKeyUp, setupUI, showDrop, toggleClick;

    function Selectr(select, opts) {
      this.select = select;
      this.options = $.extend({}, $.fn.selectr.defaultOptions, opts);
      if (this.select.attr("multiple")) {
        this.options.multiple = true;
      }
      setupUI(this.select, this.options);
    }

    setupUI = function(select, options) {
      var data, dropdownWrap, multiSelectWrap, placeholder, resultsList, searchInput, toggleBtn, wrap;
      placeholder = determinePlaceholderText(select);
      wrap = $("<div/>", {
        "class": "selectr-wrap"
      }).css({
        width: options.width
      });
      toggleBtn = $("<a />", {
        "class": "selectr-toggle"
      }).append("<span>" + placeholder + "</span><div><i></i></div>");
      searchInput = $("<input />", {
        "class": "selectr-search",
        type: "text",
        autocomplete: "off"
      });
      dropdownWrap = $("<div />", {
        "class": "selectr-drop"
      });
      multiSelectWrap = $("<div class=\"selectr-selections\"> \n  <ul>\n    <li>\n      <input type=\"text\" class=\"selectr-ms-input\" placeholder=\"" + placeholder + "\" />\n    </li>\n  </ul>\n</div>");
      data = createDataModel(select);
      resultsList = createResultsListFromData(data);
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

    determinePlaceholderText = function(select) {
      if (select.attr("placeholder")) {
        return select.attr("placeholder");
      } else if (select.data("placeholder")) {
        return select.data("placeholder");
      } else if (select.find(":selected").length > 0) {
        return select.find(":selected").text();
      } else {
        return "Select an option";
      }
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
      var currentScrollTop, drop, dunno, hasSelection, next, offset, prev, resultList, selected, selectedHeight, stroke;
      stroke = e.which || e.keyCode;
      selected = wrap.find(".selectr-selected");
      hasSelection = selected.length !== 0;
      drop = wrap.find(".selectr-drop");
      resultList = wrap.find(".selectr-results");
      switch (stroke) {
        case 38:
          if (hasSelection && selected.index() !== 0) {
            prev = selected.prevAll(".selectr-item:visible").first();
            selected.removeClass("selectr-selected");
            prev.addClass("selectr-selected");
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
            next = selected.nextAll(".selectr-item:visible").first();
            if (next.length === 0) {
              break;
            } else {
              dunno = wrap.prev().find("optgroup").length > 0 ? 2 : 1;
              selected.removeClass("selectr-selected");
              next.addClass("selectr-selected");
              currentScrollTop = resultList.scrollTop() + resultList.height();
              selectedHeight = (selected.index() + dunno) * selected.height();
              offset = selectedHeight - currentScrollTop;
              console.log("scroll top", currentScrollTop);
              console.log("selection height", selectedHeight);
              console.log("results height", resultList.height(), resultList.outerHeight());
              resultList.scrollTop(resultList.scrollTop() + offset);
            }
          }
          e.preventDefault();
          break;
        case 13:
          if (hasSelection) {
            selected.removeClass("selectr-selected");
            makeSelection(selected, wrap);
            break;
          }
          break;
        default:
          break;
      }
    };

    makeSelection = function(selectedItem, wrap) {
      wrap.find(".selectr-toggle span").text(selectedItem.text());
      hideDrop(wrap);
      return wrap.prev("select").val(selectedItem.find("button").data("value"));
    };

    toggleClick = function(drop, wrap, searchInput) {
      if (!drop.is(":visible")) {
        showDrop(wrap);
        return searchInput.focus();
      } else {
        return hideDrop(wrap);
      }
    };

    resultClick = function(e) {
      return makeSelection($(e.currentTarget).parent(), $(e.currentTarget).parents(".selectr-wrap"));
    };

    bindEvents = function(select, wrap) {
      var data, drop, resultsList, searchInput, toggleBtn;
      toggleBtn = wrap.find(".selectr-toggle");
      drop = wrap.find(".selectr-drop");
      searchInput = wrap.find(".selectr-search");
      resultsList = wrap.find(".selectr-results");
      data = createDataModel(resultsList);
      drop.delegate(".selectr-results button", "click", resultClick);
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
      var data, optgroups, options;
      optgroups = $(el).find("optgroup");
      if (optgroups.length > 0) {
        data = [];
        optgroups.each(function(i, og) {
          var group, options;
          group = {
            label: $(og).attr("label"),
            options: []
          };
          options = $(og).find("option");
          options.each(function(i, option) {
            var alreadyExists;
            alreadyExists = false;
            if (data.length > 0) {
              $(data).each(function(i, storedItem) {
                if (storedItem.value === $(option).val()) {
                  alreadyExists = true;
                }
              });
            }
            if (!alreadyExists) {
              group.options.push({
                text: $(option).text(),
                value: $(option).val(),
                selected: $(option).is(":selected")
              });
            }
          });
          data.push(group);
        });
      } else {
        options = $(el).find("option");
        data = [];
        options.each(function(i, option) {
          var alreadyExists;
          alreadyExists = false;
          if (data.length > 0) {
            $(data).each(function(i, storedItem) {
              if (storedItem.value === $(option).val()) {
                alreadyExists = true;
              }
            });
          }
          if (!alreadyExists) {
            data.push({
              text: $(option).text(),
              value: $(option).val(),
              selected: $(option).is(":selected")
            });
          }
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

    createOptGroupListFromData = function(optgroups) {
      var liHtml, list;
      list = $("<ul class=\"selectr-results\"></ul>");
      liHtml = "";
      list.append(liHtml);
      return list;
    };

    createResultsListFromData = function(data) {
      var liHtml, list;
      list = $("<ul class=\"selectr-results\"></ul>");
      liHtml = "";
      $(data).each(function(i, row) {
        if (row.hasOwnProperty("label")) {
          liHtml += "<li class=\"selectr-label\">" + row.label + "</li>";
          $(row.options).each(function(i, row) {
            liHtml += "<li class=\"selectr-item\" id=\"selectr-item-" + i + "\"";
            if (row.value === "") {
              liHtml += " style=\"display: none;\">";
            } else {
              liHtml += ">";
            }
            liHtml += "<button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected + "\">" + row.text + "</button></li>";
          });
        } else {
          liHtml += "<li class=\"selectr-item\" id=\"selectr-item-" + i + "\"";
          if (row.value === "") {
            liHtml += " style=\"display: none;\">";
          } else {
            liHtml += ">";
          }
          liHtml += "<button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected + "\">" + row.text + "</button></li>";
        }
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
