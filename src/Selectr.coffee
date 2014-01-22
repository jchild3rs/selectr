(($) ->

  class Selectr

    constructor: (@select, opts) ->

      # merge user provided options w/ defaults
      @options = $.extend({}, $.fn.selectr.defaultOptions, opts)
      @options.multiple = true if @select.attr("multiple")
      setupUI(@select, @options)

    setupUI = (select, options) ->
      placeholder = determinePlaceholderText(select)
      wrap = $("<div/>", {class: "selectr-wrap"}).css width: options.width, maxHeight: options.height
      toggleBtn = $("<a />", {class: "selectr-toggle"}).append("<span>#{placeholder}</span><div><i></i></div>");
      searchInput = $ "<input />", {class: "selectr-search", type: "text", autocomplete: "off"}
      dropdownWrap = $("<div />", {class: "selectr-drop"})
      multiSelectWrap = $("""
        <div class="selectr-selections"> 
          <ul>
            <li class="selectr-search-wrap">
              <input type="text" class="selectr-ms-search selectr-search" data-placeholder="#{placeholder}" placeholder="#{placeholder}" autocomplete='off' />
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

      wrap = bindEvents(select, wrap, options)

      # hide original input and append new wrapper
      select.hide().after(wrap)

    determinePlaceholderText = (select) ->
      if select.attr("placeholder")
        select.attr("placeholder")
      else if select.data("placeholder")
        select.data("placeholder")
      else if select.find(":selected").length > 0
        select.find(":selected").text()
      else
        "Select an option"

    handleDOMClick = (e) ->
      if not $(e.target).parents('.selectr-wrap').length
        hideDrop($(".selectr-wrap.selectr-open"))

    showDrop = (wrap) ->

      $(document).click handleDOMClick

      # hide/reset all open dropdowns
      $(".selectr-drop").hide()
      $(".selectr-open").removeClass("selectr-open")

      wrap.show()
      wrap.addClass "selectr-open"
      wrap.find(".selectr-selected").removeClass("selectr-selected")
      drop = wrap.find(".selectr-drop")
      drop.css "z-index", 99999
      drop.show()

    hideDrop = (wrap) ->
      $(document).unbind "click", handleDOMClick
      wrap.removeClass "selectr-open"
      drop = wrap.find(".selectr-drop")
      drop.css "z-index", "" # reset z-index
      drop.hide()

    searchKeyUp = (e, wrap) ->
      # todo: make sure search works w/ optgroup
      stroke = e.which || e.keyCode
      data = createDataModel wrap.prev("select")
      if isValidKeyCode(stroke)
        query = e.currentTarget.value
        resultContainer = wrap.find(".selectr-results")
        if query.length > 0
          resultData = searchDataModel(query, data)
          # create HTML
          if resultData.length > 0
            newResultsList = createResultsListFromData(resultData)
            resultContainer.replaceWith(newResultsList)
          else
            resultContainer.replaceWith("""
            <ul class='selectr-results no-results'><li class='selectr-item'>No results found for <b>#{query}</b></li></ul>
            """)

          # right now all optgroup labels are added to the data model.
          # this CSS will hide all labels that dont have a .selectr-item sibling.
          # hacky, but works for now.
          wrap.find(".selectr-label").hide()
          wrap.find(".selectr-label ~ .selectr-item:visible").prev().show()

          # show results if not aleady visible
          showDrop(wrap) if not wrap.find(".selectr-drop").is(":visible")
        else
          # reset list
          resetResults(wrap)

    searchKeyDown = (e, wrap, multiple) ->
      stroke = e.which || e.keyCode
      selected = wrap.find(".selectr-selected")
      hasSelection = selected.length isnt 0
      drop = wrap.find(".selectr-drop")
      resultList = wrap.find(".selectr-results")

      switch stroke
        when 38 # up
          if hasSelection and selected.index() isnt 0
            prev = selected.prevAll(".selectr-item:visible").first()
            selected.removeClass("selectr-selected")
            prev.addClass("selectr-selected")
            currentScrollTop = resultList.scrollTop() + resultList.height()
            selectedHeight = ((selected.index() - 1) * selected.height())
            offset = currentScrollTop - (resultList.height() - selected.height())
            if offset > selectedHeight
              resultList.scrollTop(resultList.scrollTop() + selectedHeight - offset)
          e.preventDefault()
          break
        when 40 # down
          if not hasSelection
            wrap.find(".selectr-item:visible").first().addClass("selectr-selected")
          else
            next = selected.nextAll(".selectr-item:visible").first()
            if next.length is 0
              break
            else
              gutter = if multiple then 2 else 1
              selected.removeClass("selectr-selected")
              next.addClass("selectr-selected")
              currentScrollTop = resultList.scrollTop() + resultList.height()
              selectedHeight = (selected.index() + gutter) * selected.height()
              offset = selectedHeight - currentScrollTop
#              console.log "scroll top", currentScrollTop
#              console.log "selection height", selectedHeight
#              console.log "results height", resultList.height(), resultList.outerHeight()
              if selectedHeight > currentScrollTop
                resultList.scrollTop(resultList.scrollTop() + offset)

          e.preventDefault()
          break
        when 13 # enter
          if hasSelection
            selected.removeClass("selectr-selected")
            wrap.find(".selectr-search").val("")
            makeSelection(selected, wrap, multiple)
            # reset results list
            resetResults(wrap)
            break
        else
          break

    resetResults = (wrap) ->
      data = createDataModel wrap.prev("select")
      newResultsList = createResultsListFromData(data)
      wrap.find(".selectr-results").replaceWith(newResultsList)

    makeSelection = (selectedItem, wrap, multiple) ->
      if not multiple
        wrap.find(".selectr-toggle span").text selectedItem.text()
#        hideDrop(wrap)
      else
        addMultiSelection(selectedItem, wrap)
      wrap.prev("select").val(selectedItem.find("button").data("value"))

    addMultiSelection = (selectedItem, wrap) ->
      selectionList = wrap.find(".selectr-selections ul")
      item = $("""<li class="selectr-pill">
        <button data-value="#{selectedItem.data('value')}" data-selected="#{selectedItem.data('selected')}">
          #{selectedItem.text()}
        </button>
      </li>""")
      selectionList.prepend item

    removeMultiSelection = (selectedItem) ->
      item = $(selectedItem).parent()
      item.fadeOut -> item.remove()

    toggleClick = (drop, wrap, searchInput) ->
      if not drop.is(":visible")
        showDrop(wrap)
        searchInput.focus()
      else
        hideDrop(wrap)

#    resultClick = (selected, wrap, multiple) -> makeSelection(selected, wrap, multiple)
    bindEvents = (select, wrap, options) ->
#      'selectr-ms-search'
      toggleBtn = wrap.find ".selectr-toggle"
      drop = wrap.find ".selectr-drop"
      searchInput = wrap.find ".selectr-search"
      multiSelectWrap = wrap.find ".selectr-selections"
      multiSelectSearch = multiSelectWrap.find ".selectr-search"

      multiSelectSearch.on "focus", ->
        multiSelectSearch.attr("placeholder", "")
        multiSelectSearch.width(30)
      multiSelectSearch.on "blur", ->
        multiSelectSearch.attr("placeholder", multiSelectSearch.data("placeholder"))
        multiSelectSearch.width(options.width - 20)
      multiSelectWrap.on "click", ".selectr-pill button", (e) ->
        removeMultiSelection($(e.currentTarget))

      drop.on "mouseover", ".selectr-item", (e) ->
        wrap.find(".selectr-selected").removeClass("selectr-selected")
        $(e.currentTarget).addClass("selectr-selected")

      drop.on "click", ".selectr-item button", (e) ->
        makeSelection($(e.currentTarget).parents('.selectr-item').first(), wrap, options.multiple)
        hideDrop(wrap)

      if options.multiple
        searchInput.focus ->
          showDrop(wrap)
      else
        toggleBtn.click (e) ->
          toggleClick(drop, wrap, searchInput)
          e.preventDefault();

      searchInput.keyup debounce 250, (e) -> searchKeyUp(e, wrap)
      searchInput.keydown (e) -> searchKeyDown(e, wrap, options.multiple)

      return wrap

    createDataModel = (el) ->
      optgroups = $(el).find("optgroup")
      options = $(el).find("option")
      if optgroups.length > 0
        data = []
        optgroups.each (i, og) ->
          data.push label: $(og).attr("label")
          options = $(og).find("option")
          options.each (i, option) ->
            alreadyExists = false
            if data.length > 0
              $(data).each (i, storedItem) ->
                if storedItem.value is $(option).val()
                  alreadyExists = true
                return
            if not alreadyExists
              data.push

                text: $(option).text()
                value: $(option).val()
                selected: $(option).is(":selected")
            return
#          data.push group
          return
      else if options.length > 0
        data = []
        options.each (i, option) ->
          alreadyExists = false
          if data.length > 0
            $(data).each (i, storedItem) ->
              if storedItem.value is $(option).val()
                alreadyExists = true
              return
          if not alreadyExists
            data.push
              text: $(option).text()
              value: $(option).val()
              selected: $(option).is(":selected")
          return
      data

    searchDataModel = (query, model) ->
      matches = []
      $(model).each (i, item) ->
        if item.text?
          match = item.text.match(new RegExp(query, "ig"))
          
          if match?
            match = if match.length is 1 then match[0] else match
            matches.push
              text: item.text.replace(match, "<b>" + match + "</b>")
              value: item.value
              selected: item.selected

          return
        if item.label
          matches.push(label: item.label)
#        console.log matches
#        else if item.label?
#
#          $(item).each (i, item) ->
#            matches = matches.concat(searchDataModel(query, item.options))

      return matches

    createResultsListFromData = (data) ->
      list = $("<ul class=\"selectr-results\"></ul>")
      liHtml = ""
      $(data).each (i, row) ->
        if row.hasOwnProperty("label") # has optgroups
          liHtml += "<li class=\"selectr-label\">#{row.label}</li>"
          $(row.options).each (i, row) ->
            liHtml += "<li class=\"selectr-item\" id=\"selectr-item-#{i}\""
            if row.value is ""
              liHtml += " style=\"display: none;\">"
            else
              liHtml += ">"
            liHtml += "<button type=\"button\" data-value=\"#{row.value}\" data-selected=\"#{row.selected}\">#{row.text}</button></li>"
            return
        else
          liHtml += "<li class=\"selectr-item\" id=\"selectr-item-#{i}\""
          if row.value is ""
            liHtml += " style=\"display: none;\">"
          else
            liHtml += ">"
          liHtml += "<button type=\"button\" data-value=\"#{row.value}\" data-selected=\"#{row.selected}\">#{row.text}</button></li>"
        return

      list.append liHtml

      return list

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
    height: 300
    onResultSelect: ->


)(jQuery)