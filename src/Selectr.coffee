$.fn.extend
  selectr: (options) ->
    this.each ->
      $(this).data "selectr", new Selectr($(this), options)

class Selectr

  constructor: (select, opts) ->
    @select = $(select)
    @settings = $.extend({}, @defaultSettings, opts)
    @settings.multiple = true if @select.attr "multiple"
    @setup()

  setup: ->
    @data = @createData()
    @wrap = @createSelectrWrap()
    @select.hide().after(@wrap)

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
        if row.selected is "" then "selectr-selected" else ""
        if row.disabled is "" then "selectr-disabled" else ""
      ]
      ((li.addClass(className) if className isnt "") for className in classNames)
      return li

  createListFromData: (data) ->
    data = @data unless data
    list = $("<ul />", class: "selectr-results")
    lis = (@createListItem(row) for row in @data)
    list.append lis

  getDefaultText: ->
    # TODO: js setting > data attr > placeholder attr > "empty" option
    return "Hello!"

  createSelectrWrap: ->
    wrap = $("<div />", class: "selectr-wrap", width: @settings.width)
    toggleBtn = $("<a />",
      class: "selectr-toggle", tabindex: @select.attr("tabindex") or -1)
    toggleBtn.append("<span>#{@getDefaultText()}</span><div><i></i></div>")
    searchInput = $("<input />",
      class: "selectr-search", type: "text", autocomplete: "off")
    dropdownWrap = $("<div />", class: "selectr-drop")
    multiSelectWrap = $("<div />", class: "selectr-selections")
    selectionList = $("<ul />")
    searchWrap = $("<li />")
    msSearchInput = $("<input />",
      type: "text", class: "selectr-ms-search selectr-search", autocomplete: "off", placeholder: "")

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


