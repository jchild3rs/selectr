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

      data = createDataModel(select)
      resultsList = createResultsListFromData(data)

      if options.multiple
        dropdownWrap.append resultsList
        wrap.append multiSelectWrap, dropdownWrap
      else
        dropdownWrap.append searchInput, resultsList
        wrap.append toggleBtn, dropdownWrap

      wrap = bindEvents(select, wrap, data)

      # hide original input and append new wrapper
      select.hide().after(wrap)


    bindEvents = (select, wrap, originalData) ->
      toggleBtn = wrap.find ".selectr-toggle"
      drop = wrap.find ".selectr-drop"
      searchInput = wrap.find ".selectr-search"
      resultsList = wrap.find ".selectr-results"
      data = createDataModel(resultsList)

      toggleBtn.click ->
        drop.toggle()
        wrap.toggleClass "selectr-open"

      searchInput.on "keyup", debounce 250, (e) ->
        stroke = e.which || e.keyCode
        query = e.currentTarget.value

        results = searchDataModel(query, originalData)
        if (!results)
          newResultsList = createResultsListFromData(originalData)
        else
          newResultsList = createResultsListFromData(results)
        wrap.find(".selectr-results").remove()
        searchInput.after(newResultsList);


      wrap

    createDataModel = (el) ->
      options = $(el).find("option")
      data = []
      if options.length is 0
        lis = $(el).find("li")
        lis.each ->
          data.push
            text: $(this).find("button").text()
            value: $(this).find("button").data("value")
            selected: $(this).find("button").data("selected")
      else
        options.each ->
          data.push
            text: $(this).text()
            value: $(this).val()
            selected: $(this).is(":selected")
      data

    searchDataModel = (query, model) ->
      matches = []
      $(model).each (i, item) ->
        match = item.text.match(new RegExp(query, "ig"))
        if match?
          match = match[0] if match.length is 1
          item.text = item.text.replace(match, "<b>" + match + "</b>")
          matches.push(item)
      return matches


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

    debounce = (threshold, func, execAsap) ->
      timeout = undefined
      debounced = ->
        delayed = ->
          func.apply obj, args  unless execAsap
          timeout = null
        obj = this
        args = arguments
        if timeout
          clearTimeout timeout
        else func.apply obj, args  if execAsap
        timeout = setTimeout(delayed, threshold or 100)


  $.fn.selectr = (options) ->
    return @.each -> # Ensure chainability and apply to multiple instance at the same time.
      return new Selectr($(this), options)

  $.fn.selectr.defaultOptions =
    width: 250


)(jQuery)