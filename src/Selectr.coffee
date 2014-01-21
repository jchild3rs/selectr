(($) ->

  # todo: handle optgroup
  # todo: add selection logic, make sure selection logic updates original <select>
  
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

      wrap = bindEvents(select, wrap)

      # hide original input and append new wrapper
      select.hide().after(wrap)

    searchKeyUp = (e, data, wrap) ->
      stroke = e.which || e.keyCode
      if isValidKeyCode(stroke)
        query = e.currentTarget.value
        resultContainer = wrap.find(".selectr-results")
        if query.length > 0
          resultData = searchDataModel(query, data)
          if resultData.length > 0
            newResultsList = createResultsListFromData(resultData)
            resultContainer.replaceWith(newResultsList)
          else
            resultContainer.replaceWith("""
            <ul class='selectr-results no-results'><li class='selectr-item'>No results found for <b>#{query}</b></li></ul>
            """)
        else
          # reset list
          newResultsList = createResultsListFromData(data)
          wrap.find(".selectr-results").replaceWith(newResultsList)

    searchKeyDown = (e, wrap) ->
      stroke = e.which || e.keyCode
      selected = wrap.find(".selectr-selected")

      switch stroke
        when 38 # up
          if selected.length isnt 0 and selected.index() isnt 0
            selected.removeClass("selectr-selected")
            selected.prev(":visible").addClass("selectr-selected")
          e.preventDefault()
          break
        when 40 # down
          if selected.length is 0
            wrap.find(".selectr-item:visible").first().addClass("selectr-selected")
          else
            selected.removeClass("selectr-selected")
            selected.next(":visible").addClass("selectr-selected")
          e.preventDefault()
          break
        when 13 # enter
          if selected.length isnt 0
            # todo "select" item on enter (make function for click to use)
        else
          break

    toggleClick = (drop, wrap, searchInput) ->
      if (!drop.is(":visible"))
        drop.show()
        wrap.addClass "selectr-open"
        searchInput.focus()
      else
        drop.hide()
        wrap.removeClass "selectr-open"
    resultClick = ->

    bindEvents = (select, wrap) ->
      toggleBtn = wrap.find ".selectr-toggle"
      drop = wrap.find ".selectr-drop"
      searchInput = wrap.find ".selectr-search"
      resultsList = wrap.find ".selectr-results"
      data = createDataModel resultsList

      drop.delegate ".selectr-results button", "click", -> resultClick()
      toggleBtn.click (e) ->
        toggleClick(drop, wrap, searchInput);
        e.preventDefault();
      searchInput.keyup debounce 250, (e) -> searchKeyUp(e, data, wrap)
      searchInput.keydown (e) -> searchKeyDown(e, wrap)

      return wrap

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
          return
      else
        options.each ->
          data.push
            text: $(this).text()
            value: $(this).val()
            selected: $(this).is(":selected")
          return
      data

    searchDataModel = (query, model) ->
      matches = []
      $(model).each (i, item) ->
        match = item.text.match(new RegExp(query, "ig"))
        if match?
          match = if match.length is 1 then match[0] else match
          matches.push({
            text: item.text.replace(match, "<b>" + match + "</b>"),
            value: item.value,
            selected: item.selected
          })
        return
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
      return ->
        delayed = ->
          func.apply obj, args  unless execAsap
          timeout = null
        obj = this
        args = arguments
        if timeout
          clearTimeout timeout
        else func.apply obj, args  if execAsap
        timeout = setTimeout(delayed, threshold or 100)

    # determines if key code is worthy of firing a search
    isValidKeyCode = (code) ->
      validAlpha = (code >= 65 and code <= 90)
      # alpha a-Z = 65-90
      validNumber = (code >= 48 and code <= 57)
      # numbers (0-9) = 48-57
      validPunc = (code >= 185 and code <= 192) or (code >= 219 and code <= 222) and code isnt 220
      # punc = 186-192, 219-222 (except back slash, which breaks regex)
      validMath = (code >= 106 and code <= 111)
      # math = 106-111
      space = (code == 32)
      # is not up or down arrow keys
      isntUpOrDown = (code isnt 38 and code isnt 40)
      isntEnterOrReturn = (code isnt 13)
      # space = 32
      backspaceOrDelete = (code is 8 or code is 46)
      # backspace/delete = 8, 46
      return isntUpOrDown and  isntEnterOrReturn and (validAlpha or validNumber or validPunc or validMath or space or backspaceOrDelete)



  $.fn.selectr = (options) ->
    return @.each -> # Ensure chainability and apply to multiple instance at the same time.
      return new Selectr($(this), options)

  $.fn.selectr.defaultOptions =
    width: 250
    onResultSelect: ->


)(jQuery)