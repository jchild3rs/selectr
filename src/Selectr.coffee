(($) ->

  # todo: handle optgroup
  
  class Selectr

    constructor: (@select, opts) ->

      # merge user provided options w/ defaults
      @options = $.extend({}, $.fn.selectr.defaultOptions, opts)
      @options.multiple = true if @select.attr("multiple")
      setupUI(@select, @options)

    setupUI = (select, options) ->
      selected = select.find(":selected")
      wrap = $("<div/>", {class: "selectr-wrap"}).css({width: options.width})
      toggleBtn = $("<a />", {class: "selectr-toggle"}).append("<span>#{selected.text()}</span><div><i></i></div>");
      searchInput = $ "<input />", {class: "selectr-search", type: "text", autocomplete: "off"}
      dropdownWrap = $("<div />", {class: "selectr-drop"})
      multiSelectWrap = $("""
        <div class="selectr-selections"> 
          <ul>
            <li>
              <input type="text" class="selectr-ms-input" placeholder="#{selected.text()}" />
            </li>
          </ul>
        </div>
      """)

      resultsList = createResultsListFromData(createDataModel(select))

      if options.multiple
        dropdownWrap.append resultsList
        wrap.append multiSelectWrap, dropdownWrap
      else
        dropdownWrap.append searchInput, resultsList
        wrap.append toggleBtn, dropdownWrap

      wrap = bindEvents(wrap)

      # hide original input and append new wrapper
      select.hide().after(wrap)


    bindEvents = (wrap) ->
      toggleBtn = wrap.find ".selectr-toggle"
      drop = wrap.find ".selectr-drop"
      searchInput = wrap.find ".selectr-search"
      toggleBtn.click ->
        drop.toggle()
        wrap.toggleClass "selectr-open"

      searchInput.on "keypress", (e) ->
        stroke = e.which || e.keyCode
      wrap

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
        
        liHtml += "<li class=\"selectr-item\" id=\"selectr-item-#{i}\""
        if row.value is ""
          liHtml += " style=\"display: none;\">"
        else
          liHtml += ">"
        liHtml += "<button type=\"button\" data-value=\"#{row.value}\" data-selected=\"#{row.selected}\">#{row.text}</button></li>"
        return
      list.append liHtml
      list


  $.fn.selectr = (options) ->
    return @.each -> # Ensure chainability and apply to multiple instance at the same time.
      return new Selectr($(this), options)

  $.fn.selectr.defaultOptions =
    width: 250


)(jQuery)