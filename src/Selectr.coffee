$.fn.extend
  selectr: (options) ->
    this.each ->
      $(this).data "selectr", new Selectr($(this), options)

class Selectr

  constructor: (select, opts) ->
    @select = $(select)
    @settings = $.extend({}, @defaultSettings, opts)
    @settings.multiple = true if @select.attr "multiple"
    @settings.tabindex = @select.attr "tabindex"
    @setup()

  setup: ->
    @data = @createData()
    @wrap = @createSelectrWrap()
    @bindEvents()

  handleDocumentClick: (e) =>
    if e.currentTarget is document and @wrap.find(".selectr-drop").is ":visible"
      @hideAllDropDowns()
      $(document).off("click.selectr", @handleDocumentClick)
    e.preventDefault()
    e.stopPropagation()

  showDropDown: ->
    @wrap.addClass("selectr-open")
    @focusSearchInput() unless @settings.multiple
    @wrap.find(".selectr-drop").show()
    $(document).on("click.selectr", @handleDocumentClick)

  # Always hide all instances for now.
  hideAllDropDowns: ->
    if $(".selectr-open").length > 0
      $(".selectr-open")
        .removeClass("selectr-open")
        .find(".selectr-drop").hide()

  resetDropDown: ->
    newResultsList = @createListFromData(@data)
    @wrap.find(".selectr-results").replaceWith(newResultsList)

  focusSearchInput: =>
    @wrap.find(".selectr-search").trigger("focus.selectr")

  resultItemClick: (e) =>
    @wrap.find(".selectr-active").removeClass("selectr-active")
    $(e.currentTarget).addClass("selectr-active")
    @makeSelection()
    e.stopPropagation()
    e.preventDefault()

  toggleBtnClick: (e) =>
    unless @wrap.find(".selectr-drop").is ":visible"
      @showDropDown()
      @focusSearchInput()
    e.stopPropagation()
    e.preventDefault()
    
  searchInputFocus: (e) =>
    @showDropDown() if @settings.multiple
    e.preventDefault()
    e.stopPropagation()

  searchInputClick: (e) => 
    e.preventDefault()
    e.stopPropagation()

  selectionWrapClick: (e) =>
    @focusSearchInput()
    e.preventDefault()
    e.stopPropagation()


  bindEvents: ->

    @wrap.find(".selectr-toggle").on
      "click.selectr": @toggleBtnClick

    @wrap.find(".selectr-drop").on "click.selectr", ".selectr-item", @resultItemClick

    @wrap.find(".selectr-search").on
      "focus.selectr": @searchInputFocus
      "click.selectr": @searchInputClick
      "keyup.selectr": @searchKeyUp
      "keydown.selectr": @searchKeyDown

    @wrap.find(".selectr-selections").on "click.selectr", @selectionWrapClick

  findMatches: (item, query) ->
    if item.text?
      match = item.text.match(new RegExp(query, "ig"))
      if match?
        match = if match.length is 1 then match[0] else match
        return {
          label: item.label
          text: item.text.replace(match, "<b>" + match + "</b>")
          value: item.value
          selected: item.selected
          disabled: item.disabled
        }

  searchDataModel: (query) ->
    @findMatches(item, query) for item in @data when item.text.match(new RegExp(query, "ig"))

  showNoResults: (query) ->
    @wrap.find(".selectr-results")
      .replaceWith("""<ul class='selectr-results no-results'>
        <li class='selectr-item'>No results found for <b>#{query}</b></li>
      </ul>""")

  searchKeyDown: (e) =>
    stroke = e.which || e.keyCode
    query = e.currentTarget.value
    selected = @wrap.find(".selectr-active")
    hasSelection = selected.length isnt 0
    drop = @wrap.find(".selectr-drop")
    resultList = @wrap.find(".selectr-results")

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
          @wrap.find(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active")
        else
          next = selected.nextAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first()
          if next.length is 0
            break
          else
            gutter = if @settings.multiple then 2 else 1
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
          @makeSelection()
          @wrap.find(".selectr-search").val("")
          @resetDropDown()
          break

      when 8 # delete
        if @settings.multiple and query.length is 0 and @wrap.find(".selectr-pill").length > 0
#          removeMultiSelection(wrap.find(".selectr-pill").last().find("button"), wrap)
          e.preventDefault()

      else
        break


    return this


  makeSelection: ->
    selectedItem = @wrap.find(".selectr-active")
    unless @settings.multiple
      @wrap.find(".selectr-toggle span").text selectedItem.text()
      @wrap.prev("select").val(selectedItem.data("value"))
      @hideAllDropDowns() if @wrap.find(".selectr-drop").is ":visible"
    else
#        addMultiSelection(selectedItem)

  searchKeyUp: (e) =>
    stroke = e.which || e.keyCode

    if isValidKeyCode(stroke)
      query = e.currentTarget.value
      resultContainer = @wrap.find(".selectr-results")
      if query.length > 0
        resultData = @searchDataModel(query)
        # create HTML
        if resultData.length > 0
          newResultsList = @createListFromData(resultData)
          resultContainer.replaceWith(newResultsList.get(0).outerHTML)
        else
          @showNoResults(query)


        # Right now all optgroup labels are added to the data model.
        # this CSS will hide all labels that dont have a .selectr-item sibling.
        # hacky, but works for now.
        @wrap.find(".selectr-label").hide()
        @wrap.find(".selectr-label ~ .selectr-item:visible").prev().show()

        # show results if not aleady visible
        @showDropDown() if not @wrap.find(".selectr-drop").is(":visible")
      else
        # reset list
        @resetDropDown()

      # show results if not aleady visible
      @showDropDown() if not @wrap.find(".selectr-drop").is(":visible")
#    else
#      @resetDropDown()

  createData: -> ({
    label: $(option).attr("label") || "" # is optgroup
    text: $(option).text()
    value: $(option).val()
    disabled: $(option).is(':disabled')
    selected: $(option).is(':selected')
  } for option in @select.find("optgroup, option"))

  createListItem: (row) ->
    unless row.label is "" # is optgroup label
      li = $("<li />", class: "selectr-label").text(row.label)
    else
      button = $("<button />", type: "button")
        .html row.text
      li = $("<li />").append(button).data
        value: row.value
        selected: row.selected
        disabled: row.disabled
      classNames = [
        "selectr-item",
        if row.value is "" then "selectr-hidden" else ""
        if row.selected then "selectr-selected" else ""
        if row.disabled then "selectr-disabled" else ""
      ]
      ((li.addClass(className) if className isnt "") for className in classNames)
    return li

  createListFromData: (data) ->
#    data = @data unless data
    list = $("<ul />", class: "selectr-results")
    lis = (@createListItem(row) for row in data)
    list.append lis
    return list

  setDefaultText: (text) ->
    if @settings.multiple
      @wrap.find(".selectr-search").attr "placeholder", text
    else
      @wrap.find(".selectr-toggle span").text text

  # js setting > data attr > placeholder attr > "empty" option
  getDefaultText: ->
    if @settings.placeholder
      @settings.placeholder
    else if @select.data "placeholder"
      @select.data "placeholder"
    else if @select.attr "placeholder"
      @select.attr "placeholder"
    else if @select.find("option:empty").text()
      @select.find("option:empty").text()
    else
      "Select an option"

  createSelectrWrap: ->
    wrap = $("<div />", class: "selectr-wrap", width: @settings.width)
    toggleBtn = $("<a />",
      class: "selectr-toggle", tabindex: @select.attr("tabindex") or "")
    toggleBtn.append("<span>#{@getDefaultText()}</span><div><i></i></div>")
    searchInput = $("<input />",
      class: "selectr-search", type: "text", autocomplete: "off")
    dropdownWrap = $("<div />", class: "selectr-drop")
    multiSelectWrap = $("<div />", class: "selectr-selections")
    selectionList = $("<ul />")
    searchWrap = $("<li />")
    msSearchInput = $ "<input />",
      type: "text",
      class: "selectr-ms-search selectr-search",
      autocomplete: "off",
      placeholder: @getDefaultText()
      tabindex: @select.attr('tabindex')
      width: @settings.width - 20

    resultsList = @createListFromData(@data)

    if @settings.multiple
      multiSelectWrap.append selectionList.append searchWrap.append msSearchInput
      dropdownWrap.append resultsList
      wrap.append(multiSelectWrap, dropdownWrap).addClass "selectr-multiple"
    else
      dropdownWrap.append searchInput, resultsList
      wrap.append toggleBtn, dropdownWrap

    @select.hide().after(wrap).attr("tabindex", "-1")

    return wrap

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

  defaultSettings:
    width: 250
    height: 200
    multiple: false
    onResultSelect: ->


