(($) ->

  # todo: make sure "no results" cannot be "selected"
  # todo: make sure keyboard-only workflows work

  class Selectr

    constructor: (@id, @select, @options) ->

      # merge user provided options w/ defaults
      @options = $.extend({}, $.fn.selectr.defaultOptions, @options)
      @options.multiple = true if @select.attr("multiple")
      @select.addClass "selectr-instance-#{id}"
      setupUI(@select, @options) if $("selectr-instance-#{id}").length is 0

    setupUI = (select, options) ->
      placeholder = determinePlaceholderText(select)
      wrap = $("<div/>", {class: "selectr-wrap"}).css width: options.width, maxHeight: options.height

      toggleBtn = $("<a />", class: "selectr-toggle", tabindex: select.attr("tabindex") or -1).append("<span>#{placeholder}</span><div><i></i></div>");
      searchInput = $("<input />", class: "selectr-search", type: "text", autocomplete: "off")
      dropdownWrap = $("<div />", class: "selectr-drop")
      multiSelectWrap = $("<div />", class: "selectr-selections")
      selectionList = $("<ul />")
      searchWrap = $("<li />")
      msSearchInput = $("<input />", type: "text", class: "selectr-ms-search selectr-search", autocomplete: "off", placeholder: placeholder)
      multiSelectWrap.append selectionList.append searchWrap.append msSearchInput

      data = createDataModel(select)

      resultsList = createResultsListFromData(data)
      if options.multiple
        dropdownWrap.append resultsList
        wrap.append(multiSelectWrap, dropdownWrap).addClass "selectr-multiple"

        # if pre-selected values, show pills
        selectionList = wrap.find(".selectr-selections ul")
        pills = []
        select.find("option:selected").each ->
          pills.push createPill($(@).text(), $(@).val(), $(@).is(':selected'), $(@).is(':disabled'))
        wrap.find(".selectr-ms-search").parent().before(pills)
        scaleSearchField(msSearchInput)

      else
        dropdownWrap.append searchInput, resultsList
        wrap.append toggleBtn, dropdownWrap

      wrap = bindEvents(select, wrap, options)

      # hide original input and append new wrapper
      select.attr('tabindex', '-1').hide().after(wrap)


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

      drop = wrap.find(".selectr-drop")
      drop.css "z-index", 99999
      drop.show()

    hideDrop = (wrap) ->
      $(document).unbind "click", handleDOMClick
      wrap.removeClass "selectr-open"
      drop = wrap.find(".selectr-drop")
      wrap.find(".selectr-active").removeClass "selectr-active"
      drop.css "z-index", "" # reset z-index
      drop.hide()

    searchKeyUp = (e, wrap) ->
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
      query = e.currentTarget.value
      selected = wrap.find(".selectr-active")
      hasSelection = selected.length isnt 0
      drop = wrap.find(".selectr-drop")
      resultList = wrap.find(".selectr-results")

      switch stroke

        when 38 # up
          if hasSelection and selected.index() isnt 0
            prev = selected.prevAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first()
            selected.removeClass("selectr-active")
            prev.addClass("selectr-active")
            currentScrollTop = resultList.scrollTop() + resultList.height()
            selectedHeight = ((selected.index() - 1) * selected.height())
            offset = currentScrollTop - (resultList.height() - selected.height())
            if offset > selectedHeight
              resultList.scrollTop(resultList.scrollTop() + selectedHeight - offset)
          e.preventDefault()
          break

        when 40 # down
          if not hasSelection
            wrap.find(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active")
          else
            next = selected.nextAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first()
            if next.length is 0
              break
            else
              gutter = if multiple then 2 else 1
              selected.removeClass("selectr-active")
              next.addClass("selectr-active")
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
            selected.removeClass("selectr-active")
            wrap.find(".selectr-search").val("")
            makeSelection(selected, wrap, multiple)
            resetResults(wrap)
            break

        when 8 # delete
          if multiple and query.length is 0 and wrap.find(".selectr-pill").length > 0
            removeMultiSelection(wrap.find(".selectr-pill").last().find("button"), wrap)
            e.preventDefault()

        else
          break

    resetResults = (wrap) ->
      data = createDataModel wrap.prev("select")
      newResultsList = createResultsListFromData(data)
      wrap.find(".selectr-results").replaceWith(newResultsList)

    makeSelection = (selectedItem, wrap, multiple) ->
      if not multiple
        wrap.find(".selectr-toggle span").text selectedItem.text()
        hideDrop(wrap)
        wrap.prev("select").val(selectedItem.find("button").data("value"))
      else
        addMultiSelection(selectedItem, wrap)

    createPill = (text, value, selected, disabled) ->
      return $("""<li class="selectr-pill"><button data-value="#{value}" data-selected="#{selected}" data-disabled="#{disabled}">#{text}</button></li>""")


    addMultiSelection = (selectedItem, wrap) ->

      if selectedItem.is "li"
        selectedItem = selectedItem.find("button")

      val = selectedItem.data("value")

      $(selectedItem).parent().addClass("selectr-selected")
      wrap.find(".selectr-results").scrollTop(0)

      pill = createPill(selectedItem.text(), val, selectedItem.data('selected'), selectedItem.data('disabled'))

      wrap.find(".selectr-ms-search").parent("li").before pill

      wrap.prev('select').find("option[value=\"#{val}\"]").first().prop("selected", true)
      wrap.find(".selectr-ms-search").focus()

      scaleSearchField(wrap.find(".selectr-ms-search"))

      return

    removeMultiSelection = (pill, wrap) ->
      wrap.prev("select").find("option[value='" + pill.data("value") + "']").prop("selected", false)
      $(pill).parent().remove()
      resetResults(wrap)
      return

    toggleClick = (drop, wrap, searchInput) ->
      if not drop.is(":visible")
        showDrop(wrap)
        searchInput.focus()
      else
        hideDrop(wrap)
      return

    handleMultiSelectSearchUI = (wrap) ->

      multiSelectSearch = wrap.find ".selectr-ms-search"
      selectionWrap = wrap.find ".selectr-selections"
      selectionWrap.click ->
        multiSelectSearch.focus()

      multiSelectSearch.on "keyup", ->
        scaleSearchField($(@))

      multiSelectSearch.on "focus", ->
        multiSelectSearch.attr("placeholder", "")

      multiSelectSearch.on "blur", ->
        if wrap.find(".selectr-pill").length is 0
          multiSelectSearch.attr("placeholder", multiSelectSearch.data("placeholder"))
#          hideDrop(wrap)

      wrap.on "click", ".selectr-pill button", (e) ->
        removeMultiSelection($(e.currentTarget), wrap)

    scaleSearchField = (searchInput) ->

      newWidth = 0

      # creates a mock block element and applys the text and CSS to generate a new width.
      inputStyles = "position:absolute; left: -1000px; top: -1000px; display:none;"
      styles = ['font-size','font-style', 'font-weight', 'font-family','line-height', 'text-transform', 'letter-spacing']

      for style in styles
        inputStyles += style + ":" + searchInput.css(style) + ";"

      div = $('<div />', { 'style' : inputStyles })
      div.text searchInput.val()
      $('body').append div

      parent = searchInput.parents(".selectr-selections")

      newWidth = div.outerWidth() + 60

      div.remove()

      newWidth = parent.outerWidth() - 20 if newWidth > parent.outerWidth()

      searchInput.css({'width': newWidth + 'px'})

    bindEvents = (select, wrap, options) ->

      toggleBtn = wrap.find ".selectr-toggle"
      drop = wrap.find ".selectr-drop"
      searchInput = wrap.find ".selectr-search"

      drop.on "click", ".selectr-item button", (e) ->
        parent = $(e.currentTarget).parent()
        if not parent.hasClass("selectr-selected") and not parent.hasClass("selectr-disabled")
          makeSelection(parent, wrap, options.multiple)
          if not options.multiple
            hideDrop(wrap)
          else
            searchInput.val ""

      if options.multiple
        handleMultiSelectSearchUI(wrap)
        searchInput.focus ->
          showDrop(wrap)
#        searchInput.blur ->
#          hideDrop(wrap)
#          searchInput.attr('placeholder', determinePlaceholderText(select))
      else

        toggleBtn.on "click", (e) ->
          toggleClick(drop, wrap, searchInput)
          e.preventDefault();

        toggleBtn.on "focus", ->
#          showDrop(wrap)
#          searchInput.focus()
#        searchInput.blur ->
#          hideDrop(wrap)

      searchInput.keyup debounce 250, (e) -> searchKeyUp(e, wrap)
      searchInput.keydown (e) -> searchKeyDown(e, wrap, options.multiple)

      select.prev("label").click (e) ->
        showDrop(wrap)

      return wrap

    parseOptions = (options) ->
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
            disabled: $(option).is(":disabled")
        return
      data

    createDataModel = (el) ->
      optgroups = $(el).find("optgroup")
      options = $(el).find("option")
      data = []
      if optgroups.length > 0
        optgroups.each (i, og) ->
          data.push label: $(og).attr("label")
          options = $(og).find("option")
          data = data.concat(parseOptions(options))
          return
      else if options.length > 0
        data = parseOptions(options)
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
              disabled: item.disabled

          return
        matches.push label: item.label if item.label

      return matches

    createResultsListFromData = (data) ->
      list = $("<ul class=\"selectr-results\"></ul>")
      liHtml = ""
      $(data).each (i, row) ->
        if row.hasOwnProperty("label") # has optgroups
          liHtml += "<li class=\"selectr-label\">#{row.label}</li>"
          $(row.options).each (i, row) ->
            liHtml += "<li id=\"selectr-item-#{i}\" class=\"selectr-item"
            liHtml += " selectr-hidden" if row.value is ""
            liHtml += " selectr-selected" if row.selected
            liHtml += " selectr-disabled" if row.disabled
            liHtml += "\">"
            liHtml += "<button type=\"button\" data-value=\"#{row.value}\" data-selected=\"#{row.selected}\" data-disabled=\"#{row.disabled}\">#{row.text}</button></li>"
            return
        else
          liHtml += "<li id=\"selectr-item-#{i}\" class=\"selectr-item"
          liHtml += " selectr-hidden" if row.value is ""
          liHtml += " selectr-selected" if row.selected
          liHtml += " selectr-disabled" if row.disabled
          liHtml += "\">"
          liHtml += "<button type=\"button\" data-value=\"#{row.value}\" data-selected=\"#{row.selected}\" data-disabled=\"#{row.disabled}\">#{row.text}</button></li>"
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
    return @.each (i) -> # Ensure chainability and apply to multiple instance at the same time.
      $(@).data "selectr", new Selectr(i, $(this), options)

  $.fn.selectr.defaultOptions =
    width: 250
    height: 300
    onResultSelect: ->


)(jQuery)