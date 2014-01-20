jasmine.getFixtures().fixturesPath = '/absolute/Users/james/Projects/Selectr/test/fixtures'

describe "Selectr", ->

  beforeEach ->
    loadFixtures('SelectElement.html')
    @select = $("select")
    @instance = $("select").selectr()

  afterEach ->
    @select = null
    @instance = null

  it "should be chainable", ->
    expect(@instance).toEqual(@select)

  describe "options", ->

    # todo: does this really mean anything?
    it "should contain default options", ->
      expect($.fn.selectr.defaultOptions).toBeDefined()

  describe "UI setup", ->

    it "should hide the original input", ->
      expect(@select).toBeHidden()

    describe "wrapper", ->
      beforeEach ->
        @wrap = @select.siblings(".selectr-wrap")
      afterEach ->
        @wrap = null

      it "should be a sibling to the original select", ->
        expect(@wrap).toExist()

      it "should have the class \"selectr-wrap\"", ->
        expect(@wrap).toHaveClass("selectr-wrap")

      it "should have a width based on settings", ->



