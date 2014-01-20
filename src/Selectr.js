(function($) {
  var Selectr;
  Selectr = (function() {
    var bindEvents, createDataModel, createResultsListFromData, createWrapper;

    function Selectr(select, opts) {
      this.select = select;
      this.options = $.extend({}, $.fn.selectr.defaultOptions, opts);
      this.setupUI();
    }

    Selectr.prototype.setupUI = function() {
      var dropdownWrap, multiSelectInput, resultsList, searchInput, toggleBtn, wrap;
      wrap = createWrapper(this.options.width);
      resultsList = createResultsListFromData(createDataModel(this.select));
      toggleBtn = $("<a class=\"selectr-toggle\"><span></span><div><i></i></div></a>");
      toggleBtn.text(this.select.find(":selected").text());
      searchInput = $("<input class=\"selectr-search\" type=\"text\" autocomplete=\"off\" />");
      dropdownWrap = $("<div class=\"selectr-drop\"></div>");
      multiSelectInput = $("<div class=\"selectr-selections\"><ul><li><input type=\"text\" class=\"selectr-ms-input\" /></li></ul></div>");
      if (this.options.multiple) {
        dropdownWrap.append(resultsList);
        wrap.append(multiSelectInput, dropdownWrap);
      } else {
        dropdownWrap.append(searchInput, resultsList);
        wrap.append(toggleBtn, dropdownWrap);
      }
      wrap = bindEvents(wrap);
      return this.select.hide().after(wrap);
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
        stroke = e.which || e.keyCode;
        return console.log(stroke);
      });
      return wrap;
    };

    /*
    HTML LAYOUT:
    --------------
    if normal                   else if multiselect
      wrap                        wrap
        - toggle btn                - search field + toggle btn + selections
        - drop                      - drop
          - search field              - results list
          - results list
    */


    createWrapper = function(width) {
      var wrap, wrapCss, wrapProps;
      wrapCss = {
        width: width
      };
      wrapProps = {
        "class": "selectr-wrap"
      };
      wrap = $("<div/>", wrapProps).css(wrapCss);
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
        if (row.value) {
          liHtml += "<li class=\"selectr-item\" id=\"selectr-item-" + i + "\"><button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected + "\">" + row.text + "</button></li>";
        }
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
