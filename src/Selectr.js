(function($) {
  var Selectr;
  Selectr = (function() {
    function Selectr(select, opts) {
      this.select = select;
      this.options = $.extend({}, $.fn.selectr.defaultOptions, opts);
      this.setupUI();
    }

    Selectr.prototype.setupUI = function() {
      var wrap, wrapCss, wrapProps;
      this.select.hide();
      wrapCss = {
        width: this.options.width
      };
      wrapProps = {
        "class": "selectr-wrap"
      };
      wrap = $("<div/>", wrapProps).css(wrapCss);
      return this.select.after(wrap);
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
