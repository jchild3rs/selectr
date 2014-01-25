jasmine.getStyleFixtures().fixturesPath = '/base/src/'
jasmine.getFixtures().fixturesPath = '/base/test/fixtures/'

describe "Selectr", ->
  beforeEach ->
    loadStyleFixtures('Selectr.css')
    loadFixtures('selectElement.html.js')
    @select = $("#select-fixture")

  afterEach ->
    @select = null

  it "should be chainable", ->
    expect(@select.selectr()).toEqual(@select)
  it "should apply the instance as data on the element", ->
    expect(@select.selectr().data("selectr")).toBeDefined()

  describe "default settings", ->
    beforeEach ->
      @settings = @select.selectr().data("selectr")["settings"]
    afterEach ->
      @settings = null

    it "should contain default options", ->
      expect(@settings).toBeDefined()
    it "should have a default width of 250", ->
      expect(@settings.width).toBe(250)
    it "should have a default height of 200", ->
      expect(@settings.height).toBe(200)

  describe "data model", ->
    beforeEach ->
      @select.selectr()
    it "should create a simple object representing the <option> data", ->
      expect(@select.data("selectr").hasOwnProperty("data")).toBeTruthy()
      expect(@select.data("selectr").data.length).toBe(@select.find("option").length)

  describe "UI setup", ->
    drop = null
    wrap = null
    beforeEach ->
      @originalTabIndex = @select.attr('tabindex')
      @select.selectr()
      wrap = @select.next(".selectr-wrap")
      drop = @select.next(".selectr-wrap").find(".selectr-drop")

    it "should hide the original input", ->
      expect(@select).toBeHidden()
    it "should create a wrapper as a sibling to original input", ->
      expect(@select.next(".selectr-wrap")).toExist()
    it "should use default width option for width if it is not provided", ->
      expect(@select.next(".selectr-wrap").width()).toBe(@select.data('selectr').settings.width)
    it "should use the provided width option for width if it is provided", ->
      userWidth = 400
      @select.selectr width: userWidth
      expect(@select.next(".selectr-wrap").width()).toBe(userWidth)
    it "should apply -1 to select's tabindex and update wrap with select's tabindex", ->
      expect(@select.attr("tabindex")).toBe("-1")
      expect(@select.next(".selectr-wrap").find(".selectr-toggle").attr("tabindex")).toBe(@originalTabIndex)
    it "should have a dropdown", ->
      expect(drop).toExist()

    it "should have a dropdown that is hidden by default", ->
      expect(drop).toBeHidden()

    it "should have a dropdown that should show when toggle is clicked", ->
      toggle = wrap.find(".selectr-toggle")
      toggle.trigger "click.selectr"
      expect(drop).not.toBeHidden()

    it "should have the class `.selectr-open` when the toggle is clicked", ->
      toggle = wrap.find(".selectr-toggle")
      expect(wrap).not.toHaveClass "selectr-open"
      toggle.trigger "click.selectr"
      expect(wrap).toHaveClass "selectr-open"


  describe "result list", ->
    it "should create a result list from the data model", ->
      @select.selectr()
      expect(@select.next(".selectr-wrap").find(".selectr-results")).toExist()
      expect(@select.next(".selectr-wrap").find(".selectr-results .selectr-item").length > 1).toBeTruthy()
      expect($(@select.next(".selectr-wrap").find(".selectr-results .selectr-item").get(4))
        .data("value")).toEqual(@select.data("selectr").data[4].value)

    it "should have <option> data attached to each result item", ->
      @select.selectr()
      item = @select.next(".selectr-wrap").find(".selectr-item")
      expect(item).toExist()
      expect(item.data()).not.toBeEmpty()
      expect(item.data().value).toBeDefined()
      expect(item.data().selected).toBeDefined()
      expect(item.data().disabled).toBeDefined()

  describe "item selection", ->

    it "should populate the original input's value with the selected value", ->
      @select.selectr()
      wrap = @select.next(".selectr-wrap")

      wrap.find(".selectr-toggle").trigger("click.selectr")

      drop = wrap.find(".selectr-drop")
      expect(drop).toBeVisible()

      items = drop.find(".selectr-item")
      randomItem = items.get(Math.floor(Math.random() * items.length) + 1)
      $(randomItem).trigger("click")

      expect(@select.val()).toEqual($(randomItem).data("value"))

