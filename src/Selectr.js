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
      methods = $.fn.selectr.methods,
      settings = $.extend({}, $.fn.selectr.defaultOptions, options);

      // Override settings based on <select> attributes.
      if (element.multiple) {
        settings.multiple = true;
      }

      var data = methods.createDataModel(select),
      list = methods.createListFromData(data, settings);
      
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
    createListFromData: function(data, settings) {
      var list = $("<ul class=\"" + settings.classPrefix + "-results\"></ul>"), liHtml = "";
      $(data).each(function(i, row) {
        liHtml += "<li class=\"" + settings.classPrefix + "-item\" id=\"" + settings.classPrefix + "-item-" + i + "\"><button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected +"\">" + row.text + "</button></li>";
      });
      list.width(settings.width).append(liHtml);
      return list;
    },
    createToggleButton: function() {
      
    },
    createSingleInput: function() {
      
    }
  };

  // Static method default options.
  $.fn.selectr.defaultOptions = {
    classPrefix: "selectr", // if this is changed, make sure to update CSS classes.
    width: 350,
    multiple: false // will be overriden by "multiple" html attribute.
  };

}(jQuery));
