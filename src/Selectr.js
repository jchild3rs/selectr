(function($) {
  var Selectr;
  Selectr = (function() {
    var bindEvents, createDataModel, createResultsListFromData, setupUI;

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
      wrap = bindEvents(wrap);
      return select.hide().after(wrap);
    };

    bindEvents = function(wrap) {
      var drop, searchInput, toggleBtn;
      toggleBtn = wrap.find(".selectr-toggle");
      drop = wrap.find(".selectr-drop");
      searchInput = wrap.find(".selectr-search");
      toggleBtn.click(function() {
        drop.toggle();
        return wrap.toggleClass("selectr-open");
      });
      searchInput.on("keypress", function(e) {
        var stroke;
        return stroke = e.which || e.keyCode;
      });
      return wrap;
    };

    createDataModel = function(select) {
      var data, options;
      options = $(select).find("option");
      data = [];
      options.each(function() {
        return data.push({
          text: $(this).text(),
          value: $(this).val(),
          selected: $(this).is(":selected")
        });
      });
      return data;
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
