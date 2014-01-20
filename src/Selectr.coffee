(($) ->

  class Selectr

    constructor: (@select, opts) ->

      # merge user provided options w/ defaults
      @options = $.extend({}, $.fn.selectr.defaultOptions, opts)

      @setupUI()

    setupUI: ->

      # hide original input
      @select.hide();

      # create wrap
      wrapCss =
        width: @options.width
      wrapProps =
        class: "selectr-wrap"
      wrap = $("<div/>", wrapProps).css(wrapCss)


      @select.after(wrap)


  $.fn.selectr = (options) ->
    return @.each -> # Ensure chainability and apply to multiple instance at the same time.
      return new Selectr($(this), options)

  $.fn.selectr.defaultOptions =
    width: 250


)(jQuery)