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
    @wrap = @createSelectrDOM()

  createData: -> ({
    label: $(option).attr("label") || "", # is optgroup
    text: $(option).text(),
    value: $(option).val(),
    disabled: $(option).is(':disabled'),
    selected: $(option).is(':selected')
  } for option in @select.find("optgroup, option"))

  createListFromData: (data) ->
    data = @data unless data
    list = $("<ul class=\"selectr-results\"></ul>")
    liHtml = ""
    $(@data).each (i, row) ->
      if row.label isnt "" # is optgroup label
        liHtml += "<li class=\"selectr-label\">#{row.label}</li>"
      else
        liHtml += "<li id=\"selectr-item-#{i}\" class=\"selectr-item"
        liHtml += " selectr-hidden" if row.value is ""
        liHtml += " selectr-selected" if row.selected
        liHtml += " selectr-disabled" if row.disabled
        liHtml += "\">"
        liHtml += """
            <button type="button" data-value="#{row.value}"
              data-selected="#{row.selected}" data-disabled="#{row.disabled}">
                #{row.text}
            </button>
          </li>
        """
      return

    list.append liHtml
    return list

  getDefaultText: ->
    # js setting > data attr > placeholder attr > "empty" option

    return "Hello!"

  createSelectrDOM: ->
    wrap = ($ "<div />", class: "selectr-wrap", width: @settings.width)
    toggleBtn = ($ "<a />",
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

    @select.hide().after(wrap)
    return wrap

  defaultSettings:
    width: 250
    height: 200
    multiple: false
    onResultSelect: ->


