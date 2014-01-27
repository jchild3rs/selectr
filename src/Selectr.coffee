# ## Expose to jQuery
# Loops through each jQuery selection and returns `this`
# for chainability. Creates and applies a new instance
# of Selectr as a data attribute accessible via:
# `$("#your-select").data("selectr")`

$.fn.extend
  selectr: (options) ->
    return this.each ->
      $(this).data "selectr", new Selectr $(this), options

# ## Selectr Class definition
# As you can see in the constructor below, gets passed the
# select element, and the user provided settings via the
# jQuery exposure above.
class Selectr

  constructor: (@select, @providedSettings) ->
    @constructSettings()
    @createDataModel()
    @createSelectrWrap()
    @bindEvents()

  # These default settings are used if no settings are provided.
  defaultSettings:
    wrapWidth: 250
    wrapHeight: 200
    itemHeight: 30
    multiple: false
    tabindex: -1
    placeholder: ""

  # Merge the default options with the options provided by the user
  # and set the multiple, tabindex, and placeholder values. It exposes
  # everything to `@settings`, which is accessibile in all local methods.
  constructSettings: ->
    @settings = $.extend({}, @defaultSettings, @providedSettings)
    @settings.multiple = true if @select.attr "multiple"
    @settings.tabindex = @select.attr "tabindex"
    @settings.placeholder = @getDefaultText()

  # <b>Dropdowns</b><br/>
  # Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod.
  dropDownShow: ->
    @dropDownHide()
    @wrap.addClass("selectr-open")
    @wrap.find(".selectr-drop").show()
    @focusFirstItem()
    @scrollResultsToItem()
    @scaleSearchField() if @settings.multiple
    $(document).on("click.selectr", (e) => @handleDocumentClick(e))

  dropDownHide: ->
    # Always hide all instances for now.
    if $(".selectr-open").length > 0
      $(".selectr-open")
        .removeClass("selectr-open")
        .find(".selectr-drop").hide()

  dropDownReset: ->
    newResultsList = @createListFromData(@originalData)
    @wrap.find(".selectr-results").replaceWith(newResultsList)
    @wrap.trigger("focus.selectr")

  # Event binding
  bindEvents: ->
    @wrap.on
      "click.selectr": (e) => @wrapClick(e)
      "keydown.selectr": (e) => @wrapKeyDown(e)
    @wrap.find(".selectr-drop")
      .on("click.selectr", ".selectr-item", (e) => @resultItemClick(e))
    @wrap.find(".selectr-search").on
      "focus.selectr": (e) => @searchInputFocus(e)
      "click.selectr": (e) => @searchInputClick(e)
      "keyup.selectr": (e) => @searchInputKeyUp(e)
      "keydown.selectr": (e) => @searchInputKeyDown(e)
    @wrap.find(".selectr-selections")
      .on("click.selectr", (e) => @selectionWrapClick(e))
      .on("click.selectr", ".selectr-pill", (e) => @selectionItemClick(e))

  selectionItemClick: (e) ->
    e.preventDefault()
    e.stopPropagation()
    @removeSelection($(e.currentTarget))

  handleDocumentClick: (e) ->
    if e.currentTarget is document and
    @wrap.find(".selectr-drop").is ":visible"
      @dropDownHide()
      $(document).off("click.selectr")
    e.preventDefault()
    e.stopPropagation()

  resultItemClick: (e) ->
    @wrap.find(".selectr-active").removeClass("selectr-active")
    $(e.currentTarget).addClass("selectr-active")
    @makeSelection()
    e.stopPropagation()
    e.preventDefault()

  # Wrap events
  wrapClick: (e) ->
    unless @wrap.find(".selectr-drop").is ":visible"
      @dropDownShow()
      @focusSearchInput()
    else
      @dropDownHide()
    e.stopPropagation()
    e.preventDefault()

  wrapKeyDown: (e) ->
    stroke = e.which or e.keyCode
    unless @wrap.find(".selectr-drop").is ":visible"
      if stroke is 40
        @dropDownShow()
        @focusSearchInput()
        e.preventDefault()
        e.stopPropagation()

  # Seach button
  searchInputFocus: (e) ->
    @dropDownShow() if @settings.multiple
    e.preventDefault()
    e.stopPropagation()

  searchInputClick: (e) ->
    e.preventDefault()
    e.stopPropagation()

  searchInputKeyDown: (e) ->
    stroke = e.which or e.keyCode
    query = e.currentTarget.value
    selected = @wrap.find(".selectr-active")
    hasSelection = selected.length isnt 0
    drop = @wrap.find(".selectr-drop")
    resultList = @wrap.find(".selectr-results")

    @scaleSearchField()

    switch stroke

      when 9 # tab
        if drop.is(":visible")
          @dropDownHide()
          @wrap.focus()

      when 27 # esc
        @dropDownHide()
        @wrap.focus()

      when 38 # up
        if hasSelection and selected.index() isnt 0
          prev = selected.prevAll(".selectr-item:visible")
            .not(".selectr-selected, .selectr-disabled").first()
          unless prev.length is 0
            selected.removeClass("selectr-active")
            prev.addClass("selectr-active")
            currentScrollTop = resultList.scrollTop() + resultList.height()
            selectedHeight = ((prev.index()) * selected.height())
            offset = currentScrollTop -
              (resultList.height() - selected.height())
            if offset > selectedHeight
              resultList.scrollTop((resultList.scrollTop() +
                (selectedHeight) - offset))
        e.preventDefault()
        break

      when 40 # down
        if @settings.multiple
          @dropDownShow()

        if not hasSelection
          @wrap.find(".selectr-item:visible")
            .not(".selectr-selected, .selectr-disabled")
            .first().addClass("selectr-active")
        else
          next = selected.nextAll(".selectr-item:visible")
            .not(".selectr-selected, .selectr-disabled").first()
          unless next.length is 0
            selected.removeClass("selectr-active")
            next.addClass("selectr-active")
            @scrollResultsToItem()

        e.preventDefault()
        break

      when 13 # enter
        if hasSelection
          @makeSelection()
          @wrap.find(".selectr-search").val("")
          @dropDownReset()
          @focusFirstItem()
          @scrollResultsToItem()
        e.preventDefault()
        break

      when 8 # delete
        if (@settings.multiple and query.length is 0) and
        (@wrap.find(".selectr-pill").length > 0)
          @removeSelection(@wrap.find(".selectr-pill").last())
          e.preventDefault()
          break

      else
        break

    return this

  scrollResultsToItem: ->
    gutter = if @settings.multiple then 1 else 0
    next = @wrap.find(".selectr-active")
    resultList = @wrap.find(".selectr-results")
    currentScrollTop = resultList.scrollTop() + resultList.outerHeight()
    selectedHeight = (next.index() + gutter) * next.outerHeight()
    offset = selectedHeight - currentScrollTop
    if selectedHeight > currentScrollTop
      resultList.scrollTop(resultList.scrollTop() + offset)

  searchInputKeyUp: (e) ->
    stroke = e.which || e.keyCode
    if @isValidKeyCode(stroke)
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
        @dropDownShow() if not @wrap.find(".selectr-drop").is(":visible")
      else
        # reset list
        @dropDownReset()

      # show results if not aleady visible
      @dropDownShow() if not @wrap.find(".selectr-drop").is(":visible")

  ###
  If multiple, we want to focus the input when the user
  clicks on the wrap. The input will have a variable width. ###
  selectionWrapClick: (e) ->
    if @settings.multiple
      @focusSearchInput()
      e.preventDefault()
      e.stopPropagation()

  scaleSearchField: ->
    if @settings.multiple
      searchField = @wrap.find(".selectr-search")
#      searchField.attr "placeholder", ""
      defaultStyles = "position:absolute;left:-1000px;top:-1000px;display:none;"
      styles = ["font-size", "font-style", "font-weight", "font-family",
                "line-height", "text-transform", "letter-spacing"]
      for style in styles
        defaultStyles += style + ":" + searchField.css(style) + ";"
      div = $ "<div />", "style" : defaultStyles
      val = searchField.val()

      if val isnt "" and val.length > @settings.placeholder.length
        div.text searchField.val()
      else
        div.text @settings.placeholder

      $("body").append div
      newWidth = div.width() + 25
      div.remove()
      wrapWidth = @settings.width

      if newWidth > wrapWidth - 10
        newWidth = wrapWidth - 10
      searchField.width(newWidth)

  focusSearchInput: ->
    searchInput = @wrap.find(".selectr-search")
    if not searchInput.is(":focus")
      @wrap.find(".selectr-search").trigger("focus.selectr")

  focusFirstItem: ->
    if @wrap.find(".selectr-active").length is 0
      @wrap.find(".selectr-item")
      .not(".selectr-selected, .selectr-disabled")
      .first().addClass("selectr-active")

  scrollResultsToItem: ->
    gutter = if @settings.multiple then 1 else 0
    next = @wrap.find(".selectr-active")
    resultList = @wrap.find(".selectr-results")
    currentScrollTop = resultList.scrollTop() + resultList.height()
    selectedHeight = (next.index() + gutter) * next.height()
    offset = selectedHeight - currentScrollTop
    if selectedHeight > currentScrollTop
      resultList.scrollTop(resultList.scrollTop() + offset)

  # Data
  createDataModel: ->
    @originalData = @data = ({
      label: $(option).attr("label") || "" # is optgroup
      text: $(option).text()
      value: $(option).val()
      disabled: $(option).is(":disabled")
      selected: $(option).is(":selected")
    } for option in @select.find("optgroup, option"))

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
    for item in @data when item.text.match new RegExp(query, "ig")
      @findMatches(item, query)

  # This method is a proxy for both regular and multiple instances
  # to fire when a user makes a selection.
  makeSelection: ->
    selectedItem = @wrap.find(".selectr-active")
    if @settings.multiple
      @addSelection()
    else
      @wrap.find(".selectr-toggle span").text selectedItem.text()
      @setSelectValue(selectedItem.data("value"))
      @dropDownHide()

  addSelection: ->
    selectedItem = @wrap.find(".selectr-item.selectr-active")
    return if selectedItem.hasClass("selectr-selected") or
      selectedItem.hasClass("selectr-disabled")

    val = selectedItem.data("value")

    selectedItem.addClass("selectr-selected")

    pill = @createSelection(
      selectedItem.text(),
      val,
      selectedItem.data("selected"),
      selectedItem.data("disabled")
    )
    search = @wrap.find(".selectr-ms-search")
    search.parent("li").before pill

    @setSelectValue(val)

    @wrap.trigger("focus.selectr")
#    @focusFirstItem()


  removeSelection: (pill) ->
    @unsetSelectValue(pill.data("value"))
    pill.remove()
    @focusSearchInput()


  createSelection: (text, value, selected, disabled) ->
    return $("<li/>", class: "selectr-pill")
      .data(value: value, selected: selected, disabled: disabled)
      .append("<button>#{text}</button>")

  unsetSelectValue: (val) ->
    @wrap.find(".selectr-active").removeClass(".selectr-active")
    @wrap.find(".selectr-selected:contains('#{val}')")
      .removeClass("selectr-selected")
      .removeClass("selectr-active")
    opts = @select.find("option[value='#{val}']").prop("selected", false)
    if opts.length is 0 # probably not using value attribute
      @select.find(":contains('#{val}')").prop("selected", false)
    item.selected = false for item in @data when item.value is val

  setSelectValue: (val) ->
    match = false
    # update select
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
      .replaceWith("""<ul class="selectr-results no-results">
          <li class="selectr-item">No results found for <b>#{query}</b></li>
        </ul>""")

  createListItem: (row) ->
    unless row.label is "" # is optgroup label
      li = $("<li />", class: "selectr-label").text(row.label)
    else
      button = $("<button />", type: "button")
        .html """<span>#{row.text}</span>"""
      li = $("<li />").append(button).data
        value: row.value
        selected: row.selected
        disabled: row.disabled
      li.css("height", @settings.itemHeight)
      classNames = [
        "selectr-item",
        if row.value is "" then "selectr-hidden" else ""
        if row.selected then "selectr-selected" else ""
        if row.disabled then "selectr-disabled" else ""
      ]
      for className in classNames
        li.addClass(className) if className isnt ""
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
    if @settings.placeholder isnt ""
      @settings.placeholder
    else if @select.data "placeholder"
      @select.data "placeholder"
    else if @select.attr "placeholder"
      @select.attr "placeholder"
    else if @select.find("option:empty").text()
      @select.find("option:empty").text()
    else
      "Select an option..."

  setTabIndex: ->
    @select.attr("tabindex", -1)
    tabindex = @settings.tabindex
    if @settings.multiple
      @wrap.find(".selectr-ms-search").attr("tabindex", tabindex)
    else
      @wrap[0].tabIndex = tabindex

  createSelectrWrap: ->
    wrapStyles = "width: #{@settings.wrapWidth}px;"
    wrapStyles += "max-height: #{parseInt(@settings.wrapHeight, 10)}px;"
    @wrap = $ "<div />",
      class: "selectr-wrap",
      style: wrapStyles
    toggleBtn = $ "<a />",
      class: "selectr-toggle"
      title: "#{@settings.placeholder}"
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
      tabindex: @select.attr("tabindex")
      width: @settings.wrapWidth - 20

    resultsList = @createListFromData(@data)

    if @settings.multiple
      searchWrap.append msSearchInput
      selectionList.append searchWrap
      multiSelectWrap.append  selectionList
      dropdownWrap.append resultsList
      @wrap.append(multiSelectWrap, dropdownWrap).addClass "selectr-multiple"

      # Create selections from pre-selected options.
      if @select.val() isnt "" and @select.val().length isnt 0
        hasPreselections = false
        @select.find("option:selected").each (i, option) =>
          unless $(option).val() is ""
            hasPreselections = true
            pill = @createSelection(
              $(option).text(),
              $(option).val(),
              $(option).is(":selected"),
              $(option).is(":disabled")
            )
            selectionList.prepend pill
        @scaleSearchField() if hasPreselections

    else
      dropdownWrap.append searchInput, resultsList
      @wrap.append toggleBtn, dropdownWrap

    @select.hide().after(@wrap).attr("tabindex", "-1")

    @setDefaultText(@settings.placeholder)
    @setTabIndex()
    return @wrap

  isValidKeyCode: (code) ->
    # alpha a-Z = 65-90
    validAlpha = (code >= 65 and code <= 90)
    # numbers (0-9) = 48-57
    validNumber = (code >= 48 and code <= 57)
    # punc = 186-192, 219-222 (except back slash, which breaks regex)
    validPunc = (code >= 185 and code <= 192) or
      (code >= 219 and code <= 222) and code isnt 220
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
    return isntUpOrDown and isntEnter and
      (validAlpha or validNumber or validPunc or
      validMath or isSpace or backspaceOrDelete)