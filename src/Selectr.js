(function($) {
  var Selectr;
  Selectr = (function() {
    var bindEvents, createDataModel, createResultsListFromData, debounce, searchDataModel, setupUI;

    function Selectr(select, opts) {
      this.select = select;
      this.options = $.extend({}, $.fn.selectr.defaultOptions, opts);
      if (this.select.attr("multiple")) {
        this.options.multiple = true;
      }
      setupUI(this.select, this.options);
    }

    setupUI = function(select, options) {
      var data, dropdownWrap, multiSelectWrap, resultsList, searchInput, selected, toggleBtn, wrap;
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
      data = createDataModel(select);
      resultsList = createResultsListFromData(data);
      if (options.multiple) {
        dropdownWrap.append(resultsList);
        wrap.append(multiSelectWrap, dropdownWrap);
      } else {
        dropdownWrap.append(searchInput, resultsList);
        wrap.append(toggleBtn, dropdownWrap);
      }
      wrap = bindEvents(select, wrap, data);
      return select.hide().after(wrap);
    };

    bindEvents = function(select, wrap, originalData) {
      var data, drop, resultsList, searchInput, toggleBtn;
      toggleBtn = wrap.find(".selectr-toggle");
      drop = wrap.find(".selectr-drop");
      searchInput = wrap.find(".selectr-search");
      resultsList = wrap.find(".selectr-results");
      data = createDataModel(resultsList);
      toggleBtn.click(function() {
        drop.toggle();
        return wrap.toggleClass("selectr-open");
      });
      searchInput.on("keyup", debounce(250, function(e) {
        var newResultsList, query, results, stroke;
        stroke = e.which || e.keyCode;
        query = e.currentTarget.value;
        results = searchDataModel(query, originalData);
        if (!results) {
          newResultsList = createResultsListFromData(originalData);
        } else {
          newResultsList = createResultsListFromData(results);
        }
        wrap.find(".selectr-results").remove();
        return searchInput.after(newResultsList);
      }));
      return wrap;
    };

    createDataModel = function(el) {
      var data, lis, options;
      options = $(el).find("option");
      data = [];
      if (options.length === 0) {
        lis = $(el).find("li");
        lis.each(function() {
          return data.push({
            text: $(this).find("button").text(),
            value: $(this).find("button").data("value"),
            selected: $(this).find("button").data("selected")
          });
        });
      } else {
        options.each(function() {
          return data.push({
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
          if (match.length === 1) {
            match = match[0];
          }
          item.text = item.text.replace(match, "<b>" + match + "</b>");
          return matches.push(item);
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
      var debounced, timeout;
      timeout = void 0;
      return debounced = function() {
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

    return Selectr;

  })();
  $.fn.selectr = function(options) {
    return this.each(function() {
      return new Selectr($(this), options);
    });
  };
  return $.fn.selectr.defaultOptions = {
    width: 250
  };
})(jQuery);

//# sourceMappingURL=../src/Selectr.js.map
