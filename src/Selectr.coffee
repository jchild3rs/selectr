$.fn.extend
  selectr: (options) ->
    this.each -> $(this).data "selectr", new Selectr($(this), options)

class Selectr

  defaultSettings:
    width: 250
    height: 200
    multiple: false
    onResultSelect: ->

  constructor: (@select, @providedSettings) ->
    @constructSettings()
    @createDataModel()
    @createSelectrWrap()
    @bindEvents()
    
  constructSettings: ->
    @settings = $.extend({}, @defaultSettings, @providedSettings)
    @settings.multiple = true if @select.attr "multiple"
    @settings.tabindex = @select.attr "tabindex"

  # Dropdowns
  showDropDown: ->
    @hideAllDropDowns()
    @wrap.addClass("selectr-open")
    @wrap.find(".selectr-drop").show()
    if @wrap.find(".selectr-active").length is 0
      @wrap.find(".selectr-item")
        .not(".selectr-selected, .selectr-disabled")
        .first().addClass("selectr-active")
    @moveScrollDownToItem()
    $(document).on("click.selectr", @handleDocumentClick)

  hideAllDropDowns: ->
    # Always hide all instances for now.
    if $(".selectr-open").length > 0
      $(".selectr-open")
        .removeClass("selectr-open")
        .find(".selectr-drop").hide()

  resetDropDown: ->
    newResultsList = @createListFromData(@originalData)
    @wrap.find(".selectr-results").replaceWith(newResultsList)

  focusSearchInput: ->
    searchInput = @wrap.find(".selectr-search")
    if not searchInput.is(":focus")
      @wrap.find(".selectr-search").trigger("focus.selectr")

  # Event binding
  bindEvents: ->
    @wrap.find(".selectr-toggle").on
      "click.selectr": @toggleBtnClick
      "keydown.selectr": @toggleBtnKeyDown
    @wrap.find(".selectr-drop").on "click.selectr", ".selectr-item", @resultItemClick
    @wrap.find(".selectr-search").on
      "focus.selectr": @searchInputFocus
      "click.selectr": @searchInputClick
      "keyup.selectr": @searchInputKeyUp
      "keydown.selectr": @searchInputKeyDown
    @wrap.find(".selectr-selections")
      .on("click.selectr", @selectionWrapClick)
      .on("click.selectr", ".selectr-pill", @selectionItemClick)

  selectionItemClick: (e) =>
    e.preventDefault()
    e.stopPropagation()
    @removeSelection($(e.currentTarget))

  handleDocumentClick: (e) =>
    if e.currentTarget is document and @wrap.find(".selectr-drop").is ":visible"
      @hideAllDropDowns()
      $(document).off("click.selectr", @handleDocumentClick)
    e.preventDefault()
    e.stopPropagation()

  resultItemClick: (e) =>
    @wrap.find(".selectr-active").removeClass("selectr-active")
    $(e.currentTarget).addClass("selectr-active")
    @makeSelection()
    e.stopPropagation()
    e.preventDefault()

  # Toggle button
  toggleBtnClick: (e) =>
    unless @wrap.find(".selectr-drop").is ":visible"
      @showDropDown()
      @focusSearchInput()
    else
      @hideAllDropDowns()
    e.stopPropagation()
    e.preventDefault()

  toggleBtnKeyDown: (e) =>
    stroke = e.which or e.keyCode
    # If is down arrow or enter, show drop down
    if stroke is 40 or stroke is 13
      @showDropDown()
      @focusSearchInput()

  # Seach button
  searchInputFocus: (e) =>
    @showDropDown() if @settings.multiple
    e.preventDefault()
    e.stopPropagation()

  searchInputClick: (e) =>
    e.preventDefault()
    e.stopPropagation()

  searchInputKeyDown: (e) =>
    stroke = e.which or e.keyCode
    query = e.currentTarget.value
    selected = @wrap.find(".selectr-active")
    hasSelection = selected.length isnt 0
    drop = @wrap.find(".selectr-drop")
    resultList = @wrap.find(".selectr-results")
    toggleBtn = @wrap.find(".selectr-toggle")

    switch stroke
      when 9 # tab
        if drop.is(":visible")
          @hideAllDropDowns()
          toggleBtn.focus()
      when 27 # esc
        @hideAllDropDowns()
        toggleBtn.focus()
      when 38 # up
        if hasSelection and selected.index() isnt 0
          prev = selected.prevAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first()
          unless prev.length is 0
            selected.removeClass("selectr-active")
            prev.addClass("selectr-active")
            currentScrollTop = resultList.scrollTop() + resultList.height()
            selectedHeight = ((prev.index()) * selected.height())
            offset = currentScrollTop - (resultList.height() - selected.height())
            if offset > selectedHeight
              resultList.scrollTop((resultList.scrollTop() + selectedHeight) - offset)
        e.preventDefault()
        break

      when 40 # down
        if @settings.multiple
          @showDropDown()
          
        if not hasSelection
          @wrap.find(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first().addClass("selectr-active")
        else
          next = selected.nextAll(".selectr-item:visible").not(".selectr-selected, .selectr-disabled").first()
          unless next.length is 0
            gutter = if @settings.multiple then 1 else 0
            selected.removeClass("selectr-active")
            next.addClass("selectr-active")
            @moveScrollDownToItem()

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
          @removeSelection(@wrap.find(".selectr-pill").last())
          e.preventDefault()

      else
        break


    return this

  moveScrollDownToItem: ->
    gutter = if @settings.multiple then 1 else 0
    console.log gutter, @wrap.find(".selectr-hidden").length
    next = @wrap.find(".selectr-active")
    resultList = @wrap.find(".selectr-results")
    currentScrollTop = resultList.scrollTop() + resultList.height()
    selectedHeight = (next.index() + gutter) * next.height()
    offset = selectedHeight - currentScrollTop
    if selectedHeight > currentScrollTop
      resultList.scrollTop(resultList.scrollTop() + offset)

  searchInputKeyUp: (e) =>
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

  ###
  If multiple, we want to focus the input when the user
  clicks on the wrap. The input will have a variable width. ###
  selectionWrapClick: (e) =>
    if @settings.multiple
      @focusSearchInput()
      e.preventDefault()
      e.stopPropagation()


  # Data
  createDataModel: ->
    @originalData = @data = ({
      label: $(option).attr("label") || "" # is optgroup
      text: $(option).text()
      value: $(option).val()
      disabled: $(option).is(':disabled')
      selected: $(option).is(':selected')
    } for option in @select.find("optgroup, option"))

  findMatchesInItem: (item, query) ->
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
    @findMatchesInItem(item, query) for item in @data when item.text.match(new RegExp(query, "ig"))

  # Multi-select
  makeSelection: ->
    selectedItem = @wrap.find(".selectr-active")
    if @settings.multiple
      @addSelection()
    else
      @wrap.find(".selectr-toggle span").text selectedItem.text()
      @setSelectValue(selectedItem.data("value"))
      @hideAllDropDowns() if @wrap.find(".selectr-drop").is ":visible"

  addSelection: ->
    selectedItem = @wrap.find(".selectr-item.selectr-active")
    return if selectedItem.hasClass("selectr-selected")

    val = selectedItem.data("value")

    selectedItem.addClass("selectr-selected")
    #    wrap.find(".selectr-results").scrollTop(0)

    pill = @createSelection(
      selectedItem.text(),
      val,
      selectedItem.data('selected'),
      selectedItem.data('disabled')
    )
    search = @wrap.find(".selectr-ms-search")
    search.parent("li").before pill

    @setSelectValue(val)

    search.focus()
    @hideAllDropDowns()

  removeSelection: (pill) ->
    @unsetSelectValue(pill.data("value"))
    pill.remove()
    @focusSearchInput()

  createSelection: (text, value, selected, disabled) ->
    return $("<li/>", class: "selectr-pill")
      .data(value: value, selected: selected, disabled: disabled)
      .append("<button>#{text}</button>")

  unsetSelectValue: (val) ->
    @wrap.find(".selectr-selected:contains('#{val}')")
      .removeClass("selectr-selected")
      .removeClass("selectr-active")
    opts = @select.find("option[value='#{val}']").prop("selected", false)
    if opts.length is 0 # probably not using value attribute
      @select.find(":contains(#{val})").prop("selected", false)
    item.selected = false for item in @data when item.value is val

  setSelectValue: (val) ->
    match = false
    # update <select>
    @select.find("option").each (i, option) ->
      if $(option).val() is val and not match
        $(option).prop("selected", true)
        match = true
    # update data model
    item.selected = true for item in @data when item.value is val
    #    $(@data).each (i, item) -> item.selected = true if item.value is val
    return this

  getSelectValue: ->
    @select.val()
    return this

  showNoResults: (query) ->
    @wrap.find(".selectr-results")
      .replaceWith("""<ul class='selectr-results no-results'>
          <li class='selectr-item'>No results found for <b>#{query}</b></li>
        </ul>""")

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
    list = $("<ul />", class: "selectr-results")
    lis = (@createListItem(row) for row in data)
    list.append lis
    return list

  setDefaultText: (text) ->
    if @settings.multiple
      @wrap.find(".selectr-ms-search").attr "placeholder", text
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
    @wrap = $("<div />", class: "selectr-wrap", width: @settings.width)
    toggleBtn = $("<a />",
      class: "selectr-toggle", tabindex: @select.attr("tabindex") or "")
    toggleBtn.append("<span></span><div><i></i></div>")
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
      tabindex: @select.attr('tabindex')
      width: @settings.width - 20

    resultsList = @createListFromData(@data)

    if @settings.multiple
      multiSelectWrap.append selectionList.append searchWrap.append msSearchInput
      dropdownWrap.append resultsList
      @wrap.append(multiSelectWrap, dropdownWrap).addClass "selectr-multiple"
    else
      dropdownWrap.append searchInput, resultsList
      @wrap.append toggleBtn, dropdownWrap

    @select.hide().after(@wrap).attr("tabindex", "-1")
    
    @setDefaultText(@getDefaultText())
    
    return @wrap

  isValidKeyCode = (code) ->
    # alpha a-Z = 65-90
    validAlpha = (code >= 65 and code <= 90)
    # numbers (0-9) = 48-57
    validNumber = (code >= 48 and code <= 57)
    # punc = 186-192, 219-222 (except back slash, which breaks regex)
    validPunc = (code >= 185 and code <= 192) or (code >= 219 and code <= 222) and code isnt 220
    # math = 106-111
    validMath = (code >= 106 and code <= 111)
    # space = 32
    isSpace = (code == 32)
    # is not up or down arrow keys
    isntUpOrDown = (code isnt 38 and code isnt 40)
    # not enter
    isntEnter = (code isnt 13)
    # backspace/delete = 8, 46
    backspaceOrDelete = (code is 8 or code is 46)
    isntUpOrDown and isntEnter and (validAlpha or validNumber or validPunc or validMath or isSpace or backspaceOrDelete)