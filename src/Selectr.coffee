(($) ->

  # todo: handle optgroup
  class Selectr

    constructor: (@select, opts) ->

      # merge user provided options w/ defaults
      @options = $.extend({}, $.fn.selectr.defaultOptions, opts)
      @setupUI()

    setupUI: ->
      wrap = createWrapper(@options.width)
      resultsList = createResultsListFromData(createDataModel(@select))
      toggleBtn = $("<a class=\"selectr-toggle\"><span></span><div><i></i></div></a>")
      toggleBtn.text(@select.find(":selected").text())

      searchInput = $("<input class=\"selectr-search\" type=\"text\" autocomplete=\"off\" />")
      dropdownWrap = $("<div class=\"selectr-drop\"></div>")

      multiSelectInput = $("<div class=\"selectr-selections\"><ul><li><input type=\"text\" class=\"selectr-ms-input\" /></li></ul></div>")

      if @options.multiple
        dropdownWrap.append resultsList
        wrap.append multiSelectInput, dropdownWrap
      else
        dropdownWrap.append searchInput, resultsList
        wrap.append toggleBtn, dropdownWrap

      wrap = bindEvents(wrap)

      # hide original input and append new wrapper
      @select.hide().after(wrap)


    bindEvents = (wrap) ->
      toggleBtn = wrap.find ".selectr-toggle"
      drop = wrap.find ".selectr-drop"
      searchInput = wrap.find ".selectr-search"
      toggleBtn.click ->
        drop.toggle()
        wrap.toggleClass "selectr-open"

      searchInput.on "keypress", (e) ->
        stroke = e.which || e.keyCode
        console.log stroke
      wrap

    ###
    HTML LAYOUT:
    --------------
    if normal                   else if multiselect
      wrap                        wrap
        - toggle btn                - search field + toggle btn + selections
        - drop                      - drop
          - search field              - results list
          - results list
    ###
    createWrapper = (width) ->
      wrapCss =
        width: width
      wrapProps =
        class: "selectr-wrap"
      wrap = $("<div/>", wrapProps).css(wrapCss)
      return wrap

    createDataModel = (select) ->
      options = $(select).find("option")
      data = []
      options.each ->
        data.push
          text: $(this).text()
          value: $(this).val()
          selected: $(this).is(":selected")
      data

    createResultsListFromData = (data) ->
      list = $("<ul class=\"selectr-results\"></ul>")
      liHtml = ""
      $(data).each (i, row) ->
        if row.value
          liHtml += "<li class=\"selectr-item\" id=\"selectr-item-#{i}\"><button type=\"button\" data-value=\"#{row.value}\" data-selected=\"#{row.selected}\">#{row.text}</button></li>"
        return
      list.append liHtml
      list


  $.fn.selectr = (options) ->
    return @.each -> # Ensure chainability and apply to multiple instance at the same time.
      return new Selectr($(this), options)

  $.fn.selectr.defaultOptions =
    width: 250


)(jQuery)