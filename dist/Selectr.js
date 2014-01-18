/*! Selectr - v0.1.0 - 2014-01-18
* https://github.com/jchild3rs/selectr
* Copyright (c) 2014 James Childers; Licensed MIT */
(function($) {

  // Collection method.
  $.fn.selectr = function(options) {
    
    return this.each(function() {
      var select = $(this),
        methods = $.fn.selectr.methods,
        settings = $.extend({}, $.fn.selectr.defaultOptions, options),
            
        data = methods.createDataModel(select),
        list = methods.createListFromData(data, settings);
      
      methods.createNewListSelect(select, list);
      
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
      var list = $("<ul class=\"" + settings.classPrefix + "-list\"></ul>"), liHtml = "";
      $(data).each(function(i, row) {
        liHtml += "<li class=\"" + settings.classPrefix + "-item-" + i + "\"><button type=\"button\" data-value=\"" + row.value + "\" data-selected=\"" + row.selected +"\">" + row.text + "</button></li>";
      });
      list.append(liHtml);
      return list;
    },
    createNewListSelect: function(select, list) {
      $(select).hide().before(list);
    }
  };

  // Static method default options.
  $.fn.selectr.defaultOptions = {
    classPrefix: "selectr" // if this is changed, make sure to update CSS classes.
  };

}(jQuery));
