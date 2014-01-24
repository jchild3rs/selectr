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
    @select.hide().after(@wrap)
    @select.attr("tabindex", "-1")
    @bindEvents()

  handleDocumentClick: (e) =>
    if e.currentTarget is document and @wrap.find(".selectr-drop").is ":visible"
      @hideAllDropDowns()
      $(document).off("click", @handleDocumentClick)
    e.preventDefault()
    e.stopPropagation()

  showDropDown: ->
    @hideAllDropDowns()
    drop = @wrap.find(".selectr-drop")
    @wrap.addClass("selectr-open")
    @focusSearchInput() unless @settings.multiple
    drop.show()
    $(document).on("click", @handleDocumentClick)

  # Always hide all instances for now.
  hideAllDropDowns: ->
    if $(".selectr-open").length > 0
      $(".selectr-open")
        .removeClass("selectr-open")
        .find(".selectr-drop").hide()

  toggleDrop: (e) =>
    drop = @wrap.find(".selectr-drop")
    if @wrap.hasClass("selectr-open")
      @hideAllDropDowns()
    else
      @showDropDown()
    e.preventDefault()
    e.stopPropagation()

  focusSearchInput: =>
    @wrap.find(".selectr-search").trigger("focus.selectr")

  resultItemClick: (e) =>
    e.stopPropagation()
    e.preventDefault()

  toggleBtnClick: (e) => @toggleDrop(e)
  toggleBtnFocus: (e) =>
    e.preventDefault()
    e.stopPropagation()
    unless @settings.multiple
      @hideAllDropDowns()
    else
      @wrap.find(".selectr-search").focus()

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
      "click.selectr": @toggleDrop
      "focus.selectr": @toggleBtnFocus

    @wrap.find(".selectr-drop").on "click", ".selectr-item", @resultItemClick

    @wrap.find(".selectr-search").on
      "focus.selectr": @searchInputFocus
      "click.selectr": @searchInputClick

    @wrap.find(".selectr-selections").on "click.selectr", @selectionWrapClick

  createData: -> ({
    label: $(option).attr("label") || "" # is optgroup
    text: $(option).text()
    value: $(option).val()
    disabled: $(option).is(':disabled')
    selected: $(option).is(':selected')
  } for option in @select.find("optgroup, option"))

  createListItem: (row) ->
    unless row.label is "" # is optgroup label
      $("<li />", class: "selectr-label").text(row.label)
    else
      button = $("<button />", type: "button")
        .data
          value: row.value
          selected: row.selected
          disabled: row.disabled
        .text row.text
      li = $("<li />").append(button)
      classNames = [
        "selectr-item",
        if row.value is "" then "selectr-hidden" else ""
        if row.selected then "selectr-selected" else ""
        if row.disabled then "selectr-disabled" else ""
      ]
      ((li.addClass(className) if className isnt "") for className in classNames)
      return li

  createListFromData: (data) ->
    data = @data unless data
    list = $("<ul />", class: "selectr-results")
    lis = (@createListItem(row) for row in @data)
    list.append lis

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
      placeholder: ""
      tabindex: @select.attr('tabindex')


    resultsList = @createListFromData()

    if @settings.multiple
      multiSelectWrap.append selectionList.append searchWrap.append msSearchInput
      dropdownWrap.append resultsList
      wrap.append(multiSelectWrap, dropdownWrap).addClass "selectr-multiple"
    else
      dropdownWrap.append searchInput, resultsList
      wrap.append toggleBtn, dropdownWrap

    return wrap

  defaultSettings:
    width: 250
    height: 200
    multiple: false
    onResultSelect: ->


