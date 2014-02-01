# ## Selectr Class definition
class Selectr

  # Constructor gets passed the original select element, and the
  # user provided settings via the jQuery exposure above.
  constructor: (@input, providedSettings) ->
    @constructSettings(providedSettings)
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
  constructSettings: (providedSettings) ->
    @settings = $.extend({}, @defaultSettings, providedSettings)
    @settings.multiple = true if @input.attr "multiple"
    @settings.tabindex = @input.attr "tabindex"
    @settings.placeholder = @getDefaultText()


  # ### Dropdowns
  # Hides all visible dropdowns, then shows the current. Also binds
  # a temporary click event to `document` for closing the drop down.
  dropDownShow: ->
    @dropDownHide()
    @wrap.addClass("selectr-open")
    @wrap.find(".selectr-drop").show()
    @focusFirstItem()
    @scrollResultsToItem()
    @scaleSearchField() if @settings.multiple
    $(document).on("click.selectr", (e) => @handleDocumentClick(e))

  # Hides all visible dropdowns.
  dropDownHide: ->
    if $(".selectr-open").length > 0
      $(".selectr-open")
        .removeClass("selectr-open")
        .find(".selectr-drop").hide()

  # Resets the result list using @originalData
  dropDownReset: ->
    newResultsList = @createListFromData(@originalData)
    @wrap.find(".selectr-results").replaceWith(newResultsList)
    @wrap.trigger("focus.selectr")

  # ### Event binding
  # All bindings are DOM scoped to the wrapper and all
  # event names are namespaced using ".selectr".
  #
  # Using => and passing the event object through to the
  # handler to avoid CoffeeScript creating a bind method
  # and cluttering the constructor.
  bindEvents: ->

    # Wrapper bindings
    @wrap.on
      "click.selectr": (e) => @wrapClick(e)
      "keydown.selectr": (e) => @wrapKeyDown(e)

    # Dropdown bindings
    @wrap.find(".selectr-drop")
      .on("click.selectr", ".selectr-item", (e) => @resultItemClick(e))

    # Search input bindings
    @wrap.find(".selectr-search").on
      "focus.selectr": (e) => @searchInputFocus(e)
      "click.selectr": (e) => @searchInputClick(e)
      "keyup.selectr": (e) => @searchInputKeyUp(e)
      "keydown.selectr": (e) => @searchInputKeyDown(e)

    # Multi-select wrapper bindings
    if @settings.multiple
      @wrap.find(".selectr-selections")
        .on("click.selectr", (e) => @wrapClick(e))
        .on("click.selectr", ".selectr-pill", (e) => @itemClick(e))

  # __[Multi Select]__ Click handler for a "selection" or "pill".
  # For now, it just removes the selection.
  #
  # __TODO: add X or a close button and it's logic to selections__
  itemClick: (e) ->
    @removeSelection($(e.currentTarget))
    e.preventDefault()
    e.stopPropagation()

  # Click handler that gets added to the document when a
  # dropdown is visible. This handler unbinds itself when
  # the document is clicked.
  handleDocumentClick: (e) ->
    if e.currentTarget is document
      @dropDownHide()
      $(document).off("click.selectr")
    e.preventDefault()
    e.stopPropagation()

  # Click handler for items in the result list.
  resultItemClick: (e) ->
    @wrap.find(".selectr-active").removeClass("selectr-active")
    $(e.currentTarget).addClass("selectr-active")
    @makeSelection()
    e.stopPropagation()
    e.preventDefault()

  # Click handler for top-level wrapper.
  wrapClick: (e) ->
    unless @wrap.find(".selectr-drop").is ":visible"
      @dropDownShow()
      @focusSearchInput()
    else
      @dropDownHide()
    e.stopPropagation()
    e.preventDefault()

  # Keydown handler for wrapper. Used mainly for
  # emulating native browser events.
  wrapKeyDown: (e) ->
    stroke = e.which or e.keyCode
    unless @wrap.find(".selectr-drop").is ":visible"
      if stroke is 40
        @dropDownShow()
        @focusSearchInput()
        e.preventDefault()
        e.stopPropagation()

  # Focus handler for the search input.
  searchInputFocus: (e) ->
    @dropDownShow() if @settings.multiple
    e.preventDefault()
    e.stopPropagation()

  # Click handler for the search input.
  searchInputClick: (e) ->
    e.preventDefault()
    e.stopPropagation()

  # Keydown handler for the search input. Keydown has
  # been designated for behavior logic. (keyup for search)
  # Each button has been broken out into it's own function.
  searchInputKeyDown: (e) ->
    @scaleSearchField()
    switch e.which or e.keyCode
      when 9 # tab
        @searchInputTabPress(); break
      when 27 # esc
        @searchInputUpEscPress(e); break
      when 38 # up
        @searchInputUpArrowPress(e); break
      when 40 # down
        @searchInputDownArrowPress(e); break
      when 13 # enter
        @searchInputEnterPress(e); break
      when 8 # delete
        @searchInputUpDeletePress(e); break
      else
        break

  # TAB key press handler for search input.
  searchInputTabPress: ->
    @dropDownHide()
    @wrap.focus()

  # ENTER key press handler for search input.
  searchInputEnterPress: (e) ->
    selected = @wrap.find(".selectr-active")
    hasSelection = selected.length isnt 0
    if hasSelection
      @makeSelection()
      @wrap.find(".selectr-search").val("")
      @dropDownReset()
      @focusFirstItem()
      @scrollResultsToItem()
    e.preventDefault()

  # DOWN key press handler for search input.
  searchInputDownArrowPress: (e) ->
    selected = @wrap.find(".selectr-active")
    hasSelection = selected.length isnt 0
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

  # UP key press handler for search input.
  searchInputUpArrowPress: (e) ->
    selected = @wrap.find(".selectr-active")
    hasSelection = selected.length isnt 0
    resultList = @wrap.find(".selectr-results")
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

  # ESC key press handler for search input.
  searchInputUpEscPress: (e) ->
    @dropDownHide()
    @wrap.focus()
    e.preventDefault()

  # BACKSPACE/DELETE key press handler for search input.
  searchInputUpDeletePress: (e) ->
    query = e.currentTarget.value
    if (@settings.multiple and query.length is 0) and
    (@wrap.find(".selectr-pill").length > 0)
      @removeSelection(@wrap.find(".selectr-pill").last())
      e.preventDefault()

  # Key up handler for search input. Used to search against 
  # the data model and then display the new results.
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

  # We want to focus the input when the user clicks on the wrap. 
  # The input will have a variable width. This event is only binded
  # if is multiple.
  wrapClick: (e) ->
    @focusSearchInput()
    e.preventDefault()
    e.stopPropagation()

  # This method ensures that the active item is visible.
  # If the active item's Y offset is taller than the viewport,
  # it scrolls to the right point using scrollTop()
  scrollResultsToItem: ->
    gutter = if @settings.multiple then 1 else 0
    next = @wrap.find(".selectr-active")
    resultList = @wrap.find(".selectr-results")
    currentScrollTop = resultList.scrollTop() + resultList.outerHeight()

    # Not sure if I should use .position().top) + next.outerHeight(),
    # or the method below...
    selectedHeight = (next.index() + gutter) * next.outerHeight()

    offset = selectedHeight - currentScrollTop
    if selectedHeight > currentScrollTop
      resultList.scrollTop(resultList.scrollTop() + offset)

  # Ensure the multi-select search input acts as if it's an
  # inline selection. Dynamically generates a new width using
  # a dummy block element outside of the viewport.
  scaleSearchField: ->
    if @settings.multiple
      searchField = @wrap.find(".selectr-search")
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

  # Helper method to trigger a focus event on the search input.
  focusSearchInput: ->
    searchInput = @wrap.find(".selectr-search")
    if not searchInput.is(":focus")
      @wrap.find(".selectr-search").trigger("focus.selectr")

  # Sets focus/active on the first non-selected, non-disabled item.
  focusFirstItem: ->
    if @wrap.find(".selectr-active").length is 0
      @wrap.find(".selectr-item")
      .not(".selectr-selected, .selectr-disabled")
      .first().addClass("selectr-active")

  # Creates a global data model from &lt;select&gt; data.
  createDataModel: ->
    @data = @originalData = ({
      label: $(option).attr("label") || "" # is optgroup
      text: $(option).text()
      value: $(option).val()
      disabled: $(option).is(":disabled")
      selected: $(option).is(":selected")
    } for option in @input.find("optgroup, option"))

  # Used in searchDataModel(), this determines if a match is
  # found in the provided item/option.
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

  # Searches query against the data model and returns matches.
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

  # Multi-select function for adding a new selection
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

  # Multi-select function for removing a selection
  removeSelection: (pill) ->
    @unsetSelectValue(pill.data("value"))
    pill.remove()
    @focusSearchInput()

  # Helper method for generating the "pill"/selection HTML object.
  createSelection: (text, value, selected, disabled) ->
    return $("<li/>", class: "selectr-pill")
      .data(value: value, selected: selected, disabled: disabled)
      .append("<button>#{text}</button>")

  # Sets the value of the original &lt;select&gt;
  setSelectValue: (val) ->
    match = false
    # update select
    @input.find("option").each (i, option) ->
      if $(option).val() is val and not match
        $(option).prop("selected", true)
        match = true
    # update data model
    item.selected = true for item in @data when item.value is val
    #    $(@data).each (i, item) -> item.selected = true if item.value is val
    return this

  # Unsets the value of the original &lt;select&gt;. Typically used for multiple.
  unsetSelectValue: (val) ->
    @wrap.find(".selectr-active").removeClass(".selectr-active")
    @wrap.find(".selectr-selected:contains('#{val}')")
      .removeClass("selectr-selected")
      .removeClass("selectr-active")
    opts = @input.find("option[value='#{val}']").prop("selected", false)
    if opts.length is 0 # probably not using value attribute
      @input.find(":contains('#{val}')").prop("selected", false)
    item.selected = false for item in @data when item.value is val

  # Show no results in result list.
  showNoResults: (query) ->
    @wrap.find(".selectr-results")
      .replaceWith("""<ul class="selectr-results no-results">
          <li class="selectr-item">No results found for <b>#{query}</b></li>
        </ul>""")

  # Helper method for generating a row in the result list
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

  # Creates a &lt;ul&gt; for the result list.
  createListFromData: (data) ->
    list = $("<ul />", class: "selectr-results")
    lis = (@createListItem(row) for row in data)
    list.append lis
    return list


  # Determines what value should be used for the placeholder.
  # Hierarchy: js setting > data attr > placeholder attr > "empty" option
  getDefaultText: ->
    if @settings.placeholder isnt ""
      @settings.placeholder
    else if @input.data "placeholder"
      @input.data "placeholder"
    else if @input.attr "placeholder"
      @input.attr "placeholder"
    else if @input.find("option:empty").text()
      @input.find("option:empty").text()
    else
      "Select an option..."

  # Sets old select's tabindex to -1 and the wrapper's
  # tabindex to whatever the select's tabindex value was.
  setTabIndex: ->
    @input.attr("tabindex", -1)
    tabindex = @settings.tabindex
    if @settings.multiple
      @wrap.find(".selectr-ms-search").attr("tabindex", tabindex)
    else
      @wrap[0].tabIndex = tabindex

  # Creates the DOM wrapper for Selectr.
  createSelectrWrap: () ->
    wrapStyles = "width: #{@settings.wrapWidth}px;"
    wrapStyles += "max-height: #{parseInt(@settings.wrapHeight, 10)}px;"
    @wrap = $ "<div />",
      class: "selectr-wrap",
      style: wrapStyles
    toggleBtn = $ "<a />", class: "selectr-toggle", title: "#{@settings.placeholder}"
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
      tabindex: @input.attr("tabindex")
      width: @settings.wrapWidth - 20

    if @settings.external
      @wrap.append searchInput, dropdownWrap

    else
      resultsList = @createListFromData(@data)
      if @settings.multiple
        searchWrap.append msSearchInput
        selectionList.append searchWrap
        multiSelectWrap.append  selectionList
        dropdownWrap.append resultsList
        @wrap.append(multiSelectWrap, dropdownWrap).addClass "selectr-multiple"

        # Create selections from pre-selected options.
        if @input.val() isnt "" and @input.val().length isnt 0
          hasPreselections = false
          @input.find("option:selected").each (i, option) =>
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

    @input.hide().after(@wrap).attr("tabindex", "-1")

    # Set default text
    if @settings.multiple
      @wrap.find(".selectr-ms-search").attr "placeholder", @settings.placeholder
    else
      @wrap.find(".selectr-toggle span").text @settings.placeholder

    @setTabIndex()
    return @wrap

  # Helper for determining if stroke/key is valid.
  # Valid meaning, "okay to search with".
  isValidKeyCode: (code) ->
    validAlpha = (code >= 65 and code <= 90) # alpha a-Z = 65-90
    validNumber = (code >= 48 and code <= 57) # numbers (0-9) = 48-57
    validPunc = (code >= 185 and code <= 192) or
      (code >= 219 and code <= 222) # punc = 186-192, 219-222
    validMath = (code >= 106 and code <= 111) # math = 106-111
    isSpace = (code == 32) # space = 32
    isntUpOrDown = (code isnt 38 and code isnt 40) # is not up or down arrow keys
    isntBackslash = (code isnt 220) # not backslash
    isntEnter = (code isnt 13) # not enter
    backspaceOrDelete = (code is 8 or code is 46) # backspace/delete = 8, 46
    return isntUpOrDown and isntEnter and isntBackslash and
      (validAlpha or validNumber or validPunc or
      validMath or isSpace or backspaceOrDelete)

class AjaxSelectr extends Selectr
  
  constructor: (@input, providedSettings) ->
    @constructSettings(providedSettings)
    @settings.external = true;
    @createDataModel()
    @createSelectrWrap()
    @bindEvents()

  # # Overwritten methods
  createDataModel: (e) ->
    console.log(e)

  searchInputKeyUp: (e) ->
    console.log(e)
    console.log 'does this overwrite?'


  # ## Expose to jQuery
  # Loops through each jQuery selection and returns `this`
  # for chainability. Creates and applies a new instance
  # of Selectr as a data attribute accessible via:
  # `$("#your-select").data("selectr")`
$.fn.extend
  selectr: (options) ->
    return this.each ->
      if $(this).is "select"
        $(this).data "selectr", new Selectr $(this), options
      else

        $(this).data "selectr", new AjaxSelectr $(this), options