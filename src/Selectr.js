(function($) {
  var Selectr;
  Selectr = (function() {
    var addMultiSelection, bindEvents, createDataModel, createPill, createResultsListFromData, debounce, determinePlaceholderText, handleDOMClick, handleMultiSelectSearchUI, hideDrop, isValidKeyCode, makeSelection, parseOptions, removeMultiSelection, resetResults, scaleSearchField, searchDataModel, searchKeyDown, searchKeyUp, setupUI, showDrop, toggleClick;

    function Selectr(id, select, options) {
      this.id = id;
      this.select = select;
      this.options = options;
      this.options = $.extend({}, $.fn.selectr.defaultOptions, this.options);
      if (this.select.attr("multiple")) {
        this.options.multiple = true;
      }
      this.select.addClass("selectr-instance-" + id);
      if ($("selectr-instance-" + id).length === 0) {
        setupUI(this.select, this.options);
      }
    }

    setupUI = function(select, options) {
      var data, dropdownWrap, msSearchInput, multiSelectWrap, pills, placeholder, resultsList, searchInput, searchWrap, selectionList, toggleBtn, wrap;
      placeholder = determinePlaceholderText(select);
      wrap = $("<div/>", {
        "class": "selectr-wrap"
      }).css({
        width: options.width,
        maxHeight: options.height
      });
      toggleBtn = $("<a />", {
        "class": "selectr-toggle",
        tabindex: select.attr("tabindex") || -1
      }).append("<span>" + placeholder + "</span><div><i></i></div>");
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
        placeholder: placeholder
      });
      multiSelectWrap.append(selectionList.append(searchWrap.append(msSearchInput)));
      data = createDataModel(select);
      resultsList = createResultsListFromData(data);
      if (options.multiple) {
        dropdownWrap.append(resultsList);
        wrap.append(multiSelectWrap, dropdownWrap).addClass("selectr-multiple");
        selectionList = wrap.find(".selectr-selections ul");
        pills = [];
        select.find("option:selected").each(function() {
          return pills.push(createPill($(this).text(), $(this).val(), $(this).is(':selected'), $(this).is(':disabled')));
        });
        wrap.find(".selectr-ms-search").parent().before(pills);
        scaleSearchField(msSearchInput);
      } else {
        dropdownWrap.append(searchInput, resultsList);
        wrap.append(toggleBtn, dropdownWrap);
      }
      wrap = bindEvents(select, wrap, options);
      return select.attr('tabindex', '-1').hide().after(wrap);
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

    handleDOMClick = function(e) {
      if (!$(e.target).parents('.selectr-wrap').length) {
        return hideDrop($(".selectr-wrap.selectr-open"));
      }
    };

    showDrop = function(wrap) {
      var drop;
      $(document).click(handleDOMClick);
      $(".selectr-drop").hide();
      $(".selectr-open").removeClass("selectr-open");
      wrap.show();
      wrap.addClass("selectr-open");
      drop = wrap.find(".selectr-drop");
      drop.css("z-index", 99999);
      return drop.show();
    };

    hideDrop = function(wrap) {
      var drop;
      $(document).unbind("click", handleDOMClick);
      wrap.removeClass("selectr-open");
      drop = wrap.find(".selectr-drop");
      wrap.find(".selectr-active").removeClass("selectr-active");
      drop.css("z-index", "");
      return drop.hide();
    };

    searchKeyUp = function(e, wrap) {
      var data, newResultsList, query, resultContainer, resultData, stroke;
      stroke = e.which || e.keyCode;
      data = createDataModel(wrap.prev("select"));
      if (isValidKeyCode(stroke)) {
        query = e.currentTarget.value;
        resultContainer = wrap.find(".selectr-results");
        if (query.length > 0) {
          resultData = searchDataModel(query, data);
          if (resultData.length > 0) {
            newResultsList = createResultsListFromData(resultData);
            resultContainer.replaceWith(newResultsList);
          } else {
            resultContainer.replaceWith("<ul class='selectr-results no-results'><li class='selectr-item'>No results found for <b>" + query + "</b></li></ul>");
          }
          wrap.find(".selectr-label").hide();
          wrap.find(".selectr-label ~ .selectr-item:visible").prev().show();
          if (!wrap.find(".selectr-drop").is(":visible")) {
            return showDrop(wrap);
          }
        } else {
          return resetResults(wrap);
        }
      }
    };

    searchKeyDown = function(e, wrap, multiple) {
      var currentScrollTop, drop, gutter, hasSelection, next, offset, prev, query, resultList, selected, selectedHeight, stroke;
      stroke = e.which || e.keyCode;
      query = e.currentTarget.value;
      selected = wrap.find(".selectr-active");
      hasSelection = selected.length !== 0;
      drop = wrap.find(".selectr-drop");
      resultList = wrap.find(".selectr-results");
      switch (stroke) {
        case 38:
          if (hasSelection && selected.index() !== 0) {
            prev = selected.prevAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first();
            selected.removeClass("selectr-active");
            prev.addClass("selectr-active");
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
            wrap.find(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active");
          } else {
            next = selected.nextAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first();
            if (next.length === 0) {
              break;
            } else {
              gutter = multiple ? 2 : 1;
              selected.removeClass("selectr-active");
              next.addClass("selectr-active");
              currentScrollTop = resultList.scrollTop() + resultList.height();
              selectedHeight = (selected.index() + gutter) * selected.height();
              offset = selectedHeight - currentScrollTop;
              if (selectedHeight > currentScrollTop) {
                resultList.scrollTop(resultList.scrollTop() + offset);
              }
            }
          }
          e.preventDefault();
          break;
        case 13:
          if (hasSelection) {
            selected.removeClass("selectr-active");
            wrap.find(".selectr-search").val("");
            makeSelection(selected, wrap, multiple);
            resetResults(wrap);
            break;
          }
          break;
        case 8:
          if (multiple && query.length === 0 && wrap.find(".selectr-pill").length > 0) {
            removeMultiSelection(wrap.find(".selectr-pill").last().find("button"), wrap);
            return e.preventDefault();
          }
          break;
        default:
          break;
      }
    };

    resetResults = function(wrap) {
      var data, newResultsList;
      data = createDataModel(wrap.prev("select"));
      newResultsList = createResultsListFromData(data);
      return wrap.find(".selectr-results").replaceWith(newResultsList);
    };

    makeSelection = function(selectedItem, wrap, multiple) {
      if (!multiple) {
        wrap.find(".selectr-toggle span").text(selectedItem.text());
        hideDrop(wrap);
        return wrap.prev("select").val(selectedItem.find("button").data("value"));
      } else {
        return addMultiSelection(selectedItem, wrap);
      }
    };

    createPill = function(text, value, selected, disabled) {
      return $("<li class=\"selectr-pill\"><button data-value=\"" + value + "\" data-selected=\"" + selected + "\" data-disabled=\"" + disabled + "\">" + text + "</button></li>");
    };

    addMultiSelection = function(selectedItem, wrap) {
      var pill, val;
      if (selectedItem.is("li")) {
        selectedItem = selectedItem.find("button");
      }
      val = selectedItem.data("value");
      $(selectedItem).parent().addClass("selectr-selected");
      wrap.find(".selectr-results").scrollTop(0);
      pill = createPill(selectedItem.text(), val, selectedItem.data('selected'), selectedItem.data('disabled'));
      wrap.find(".selectr-ms-search").parent("li").before(pill);
      wrap.prev('select').find("option[value=\"" + val + "\"]").first().prop("selected", true);
      wrap.find(".selectr-ms-search").focus();
      scaleSearchField(wrap.find(".selectr-ms-search"));
    };

    removeMultiSelection = function(pill, wrap) {
      wrap.prev("select").find("option[value='" + pill.data("value") + "']").prop("selected", false);
      $(pill).parent().remove();
      resetResults(wrap);
    };

    toggleClick = function(drop, wrap, searchInput) {
      if (!drop.is(":visible")) {
        showDrop(wrap);
        searchInput.focus();
      } else {
        hideDrop(wrap);
      }
    };

    handleMultiSelectSearchUI = function(wrap) {
      var multiSelectSearch, selectionWrap;
      multiSelectSearch = wrap.find(".selectr-ms-search");
      selectionWrap = wrap.find(".selectr-selections");
      selectionWrap.click(function() {
        return multiSelectSearch.focus();
      });
      multiSelectSearch.on("keyup", function() {
        return scaleSearchField($(this));
      });
      multiSelectSearch.on("focus", function() {
        return multiSelectSearch.attr("placeholder", "");
      });
      multiSelectSearch.on("blur", function() {
        if (wrap.find(".selectr-pill").length === 0) {
          return multiSelectSearch.attr("placeholder", multiSelectSearch.data("placeholder"));
        }
      });
      return wrap.on("click", ".selectr-pill button", function(e) {
        return removeMultiSelection($(e.currentTarget), wrap);
      });
    };

    scaleSearchField = function(searchInput) {
      var div, inputStyles, newWidth, parent, style, styles, _i, _len;
      newWidth = 0;
      inputStyles = "position:absolute; left: -1000px; top: -1000px; display:none;";
      styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'];
      for (_i = 0, _len = styles.length; _i < _len; _i++) {
        style = styles[_i];
        inputStyles += style + ":" + searchInput.css(style) + ";";
      }
      div = $('<div />', {
        'style': inputStyles
      });
      div.text(searchInput.val());
      $('body').append(div);
      parent = searchInput.parents(".selectr-selections");
      newWidth = div.outerWidth() + 60;
      div.remove();
      if (newWidth > parent.outerWidth()) {
        newWidth = parent.outerWidth() - 20;
      }
      return searchInput.css({
        'width': newWidth + 'px'
      });
    };

    bindEvents = function(select, wrap, options) {
      var drop, searchInput, toggleBtn;
      toggleBtn = wrap.find(".selectr-toggle");
      drop = wrap.find(".selectr-drop");
      searchInput = wrap.find(".selectr-search");
      drop.on("click", ".selectr-item button", function(e) {
        var parent;
        parent = $(e.currentTarget).parent();
        if (!parent.hasClass("selectr-selected") && !parent.hasClass("selectr-disabled")) {
          makeSelection(parent, wrap, options.multiple);
          if (!options.multiple) {
            return hideDrop(wrap);
          } else {
            return searchInput.val("");
          }
        }
      });
      if (options.multiple) {
        handleMultiSelectSearchUI(wrap);
        searchInput.focus(function() {
          return showDrop(wrap);
        });
      } else {
        toggleBtn.on("click", function(e) {
          toggleClick(drop, wrap, searchInput);
          return e.preventDefault();
        });
        toggleBtn.on("focus", function() {});
      }
      searchInput.keyup(debounce(250, function(e) {
        return searchKeyUp(e, wrap);
      }));
      searchInput.keydown(function(e) {
        return searchKeyDown(e, wrap, options.multiple);
      });
      select.prev("label").click(function(e) {
        return showDrop(wrap);
      });
      return wrap;
    };

    parseOptions = function(options) {
      var data;
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
            selected: $(option).is(":selected"),
            disabled: $(option).is(":disabled")
          });
        }
      });
      return data;
    };

    createDataModel = function(el) {
      var data, optgroups, options;
      optgroups = $(el).find("optgroup");
      options = $(el).find("option");
      data = [];
      if (optgroups.length > 0) {
        optgroups.each(function(i, og) {
          data.push({
            label: $(og).attr("label")
          });
          options = $(og).find("option");
          data = data.concat(parseOptions(options));
        });
      } else if (options.length > 0) {
        data = parseOptions(options);
      }
      return data;
    };

    searchDataModel = function(query, model) {
      var matches;
      matches = [];
      $(model).each(function(i, item) {
        var match;
        if (item.text != null) {
          match = item.text.match(new RegExp(query, "ig"));
          if (match != null) {
            match = match.length === 1 ? match[0] : match;
            matches.push({
              text: item.text.replace(match, "<b>" + match + "</b>"),
              value: item.value,
              selected: item.selected,
              disabled: item.disabled
            });
          }
          return;
        }
        if (item.label) {
          return matches.push({
            label: item.label
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
        if (row.hasOwnProperty("label")) {
          liHtml += "<li class=\"selectr-label\">" + row.label + "</li>";
          $(row.options).each(function(i, row) {
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
            liHtml += "<button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected + "\" data-disabled=\"" + row.disabled + "\">" + row.text + "</button></li>";
          });
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
          liHtml += "<button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected + "\" data-disabled=\"" + row.disabled + "\">" + row.text + "</button></li>";
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
    return this.each(function(i) {
      return $(this).data("selectr", new Selectr(i, $(this), options));
    });
  };
  return $.fn.selectr.defaultOptions = {
    width: 250,
    height: 300,
    onResultSelect: function() {}
  };
})(jQuery);

//# sourceMappingURL=../src/Selectr.js.map
