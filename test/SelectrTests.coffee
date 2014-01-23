jasmine.getStyleFixtures().fixturesPath = '/base/src/'
jasmine.getFixtures().fixturesPath = '/base/test/fixtures/'

describe "Selectr", ->

  beforeEach ->
    loadStyleFixtures('Selectr.css')
    loadFixtures('selectElement.html.js')
    @select = $("#select-fixture")

  afterEach -> @select = null

  it "should be chainable", -> expect(@select.selectr()).toEqual(@select)
  it "should apply the instance as data on the element", -> expect(@select.selectr().data("selectr")).toBeDefined()

  describe "default settings", ->

    beforeEach -> @settings = @select.selectr().data("selectr")["settings"]
    afterEach -> @settings = null

    it "should contain default options", -> expect(@settings).toBeDefined()
    it "should have a default width of 250", -> expect(@settings.width).toBe(250)
    it "should have a default height of 200", -> expect(@settings.height).toBe(200)

  describe "data", ->
    beforeEach -> @select.selectr()
    it "should create a simple object representing the <option> data", ->
      expect(@select.data("selectr").hasOwnProperty("data")).toBeTruthy()
      expect(@select.data("selectr").data.length).toBe(@select.find("option").length)
  describe "UI setup", ->

    beforeEach -> @select.selectr()

    it "should hide the original input", -> expect(@select).toBeHidden()
    it "should create a wrapper as a sibling to original input", ->
      expect(@select.next(".selectr-wrap")).toExist()
    it "should use default width option for width if it is not provided", ->
      expect(@select.next(".selectr-wrap").width()).toBe(@select.data('selectr').settings.width)
    it "should use the provided width option for width if it is provided", ->
      userWidth = 400
      @select.selectr width: userWidth
      expect(@select.next(".selectr-wrap").width()).toBe(userWidth)

#
#    describe "wrapper & dropdown", ->
#
#      beforeEach ->
#        @wrap = @select.siblings ".selectr-wrap"
#        @drop = @wrap.find(".selectr-drop")
#      afterEach ->
#        @wrap = null
#        @drop = null
#
#      it "should be a sibling to the original select", ->
#        expect(@wrap).toExist()
#
#      it "should have the class \"selectr-wrap\"", ->
#        expect(@wrap).toHaveClass "selectr-wrap"
#
#      it "should have a width based on settings", ->
#        expect(@wrap.width()).toEqual($.fn.selectr.defaultOptions.width)
#
#      it "should have a width based on user-defined settings", ->
#        wrap = $("#select-fixture").selectr({width: 500}).siblings(".selectr-wrap")
#        expect(wrap.width()).not.toEqual($.fn.selectr.defaultOptions.width)
#        expect(wrap.width()).toEqual(500)
#        wrap = null
#
#      it "should have a certain html layout if default", ->
#        expect(@wrap.find("> .selectr-toggle, > .selectr-search, > .selectr-drop")).toExist()
#
#      it "should have a dropdown", ->
#        expect(@drop).toExist()
#
#      it "should have a dropdown that is hidden by default", ->
#        expect(@drop).toBeHidden()
#
#      it "should have a dropdown that should show when toggle is clicked", ->
#        toggle = @wrap.find(".selectr-toggle")
#        toggle.trigger "click"
#        expect(@drop).not.toBeHidden()
#
#      it "should have the class `.selectr-open` when the toggle is clicked", ->
#        toggle = @wrap.find(".selectr-toggle")
#        expect(@wrap).not.toHaveClass "selectr-open"
#        toggle.trigger "click"
#        expect(@wrap).toHaveClass "selectr-open"
#
#
#    describe "results", ->
#      # todo: add search tests
#      it "should not show duplicates", ->
#
#
#      it "should create a unordered list, within the wrapper, using the <select>'s data", ->
#        # todo: handle duplicates. the test below works if there are no duplicates
#        list = @select.next(".selectr-wrap").find(".selectr-results")
##        matching indexes of the <option>s against the indexes of the <li>s that are generated.
#        expect(@select.find("option")).toHaveLength(list.find("li").length)
#        expect(@select.find("option").get(4).value).toEqual($(list.find("li").get(4)).find("button").text())
#        expect(@select.find("option").get(7).value).toEqual($(list.find("li").get(7)).find("button").text())
#        expect(@select.find("option").get(5).value).not.toEqual($(list.find("li").get(7)).find("button").text())
#
#
#  # todo add arrow key tests