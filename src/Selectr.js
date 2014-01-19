/*
 * Selectr
 * https://github.com/jchild3rs/selectr
 *
 * Copyright (c) 2014 James Childers
 * Licensed under the MIT license.
 */

(function($) {

  // Collection method.
  $.fn.selectr = function(options) {
    
    return this.each(function(i, element) {
      var select = $(element),
        selectedOption = select.find("option:selected"),
      methods = $.fn.selectr.methods,
      settings = $.extend({}, $.fn.selectr.defaultOptions, options);

      // Override settings based on <select> attributes.
      if (element.multiple) {
        settings.multiple = true;
      }

      var data = methods.createDataModel(select),
      list = methods.createListFromData(data),
      toggleBtn = methods.createToggleButton().text(selectedOption.text()),
      searchInput = methods.createSingleInput(),
      drop = $("<div class=\"selectr-drop\"></div>"),
      wrap = $("<div class=\"selectr-wrap\"></div>").width(settings.width);

      if (!settings.multiple) {
        drop.append(searchInput, list);
        wrap.append(toggleBtn, drop);
      } else {
        //todo handle multiple
        wrap = $();
      }
      console.log(wrap);

      select.hide().after(wrap);

      // normal html layout
      // - wrap
      //   - toggle button
      //   - drop
      //     - search field
      //     - results list
      
    });
    
  };
  
  $.fn.selectr.methods = {
    createDataModel: function(select) {
      // todo: handle optgroup
      var options = $(select).find("option"),
      data = [];
      options.each(function() {
        data.push({
          text: $(this).text(),
          value: $(this).val(),
          selected: $(this).is(":selected")
        });
      });
      return data;
    },
    createListFromData: function(data) {
      var list = $("<ul class=\"selectr-results\"></ul>"), liHtml = "",
        ref = this;
      $(data).each(function(i, row) {
        if (row.value) {
          liHtml += "<li class=\"selectr-item\" id=\"selectr-item-" + i + "\"><button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected +"\">" + row.text + "</button></li>";
        }
      });
      list.append(liHtml);
      return list;
    },
    createToggleButton: function() {
      return $("<a class=\"selectr-toggle\"><span></span><div><i></i></div></a>");
    },
    createSingleInput: function() {
      return $("<input class=\"selectr-search\" type=\"text\" autocomplete=\"off\" />");
    }
  };

  // Static method default options.
  $.fn.selectr.defaultOptions = {
    width: 350,
    multiple: false // will be overridden by "multiple" html attribute.
  };

}(jQuery));
