jasmine.getStyleFixtures().fixturesPath = '/base/src/'
jasmine.getFixtures().fixturesPath = '/base/test/fixtures/'

describe "Selectr", ->

  loadStyleFixtures('Selectr.css')

  beforeEach ->
    loadFixtures('selectElement.html.js')
    @select = $("#select-fixture")
    @instance = @select.selectr()

  afterEach ->
    @select = null
    @instance = null
    $('.selectr-wrap').remove()

  it "should be chainable", ->
    expect(@instance).toEqual(@select)

  describe "options", ->

    it "should contain default options", ->
      expect($.fn.selectr.defaultOptions).toBeDefined()

    it "should have a default width of 250", ->
      expect($.fn.selectr.defaultOptions.width).toBe(250)

  describe "UI setup", ->

    it "should hide the original input", ->
      expect(@select).toBeHidden()

    describe "wrapper & dropdown", ->

      beforeEach ->
        @wrap = @select.siblings ".selectr-wrap"
        @drop = @wrap.find(".selectr-drop")
      afterEach ->
        @wrap = null
        @drop = null

      it "should be a sibling to the original select", ->
        expect(@wrap).toExist()

      it "should have the class \"selectr-wrap\"", ->
        expect(@wrap).toHaveClass "selectr-wrap"

      it "should have a width based on settings", ->
        expect(@wrap.width()).toEqual($.fn.selectr.defaultOptions.width)

      it "should have a width based on user-defined settings", ->
        wrap = $("#select-fixture").selectr({width: 500}).siblings(".selectr-wrap")
        expect(wrap.width()).not.toEqual($.fn.selectr.defaultOptions.width)
        expect(wrap.width()).toEqual(500)
        wrap = null

      it "should have a certain html layout if default", ->
        expect(@wrap.find("> .selectr-toggle, > .selectr-search, > .selectr-drop")).toExist()

      it "should have a dropdown", ->
        expect(@drop).toExist()

      it "should have a dropdown that is hidden by default", ->
        expect(@drop).toBeHidden()

      it "should have a dropdown that should show when toggle is clicked", ->
        toggle = @wrap.find(".selectr-toggle")
        toggle.trigger "click"
        expect(@drop).not.toBeHidden()

      it "should have the class `.selectr-open` when the toggle is clicked", ->
        toggle = @wrap.find(".selectr-toggle")
        expect(@wrap).not.toHaveClass "selectr-open"
        toggle.trigger "click"
        expect(@wrap).toHaveClass "selectr-open"


    describe "results", ->
      # todo: add search tests
      it "should not show duplicates", ->


      it "should create a unordered list, within the wrapper, using the <select>'s data", ->
        # todo: handle duplicates. the test below works if there are no duplicates
        list = @select.next(".selectr-wrap").find(".selectr-results")
#        matching indexes of the <option>s against the indexes of the <li>s that are generated.
        expect(@select.find("option")).toHaveLength(list.find("li").length)
        expect(@select.find("option").get(4).value).toEqual($(list.find("li").get(4)).find("button").text())
        expect(@select.find("option").get(7).value).toEqual($(list.find("li").get(7)).find("button").text())
        expect(@select.find("option").get(5).value).not.toEqual($(list.find("li").get(7)).find("button").text())


  # todo add arrow key tests