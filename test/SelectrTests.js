jasmine.getStyleFixtures().fixturesPath = '/base/src/';

jasmine.getFixtures().fixturesPath = '/base/test/fixtures/';

describe("Selectr", function() {
  beforeEach(function() {
    loadStyleFixtures('Selectr.css');
    loadFixtures('selectElement.html.js');
    return this.select = $("#select-fixture");
  });
  afterEach(function() {
    return this.select = null;
  });
  it("should be chainable", function() {
    return expect(this.select.selectr()).toEqual(this.select);
  });
  it("should apply the instance as data on the element", function() {
    return expect(this.select.selectr().data("selectr")).toBeDefined();
  });
  describe("default settings", function() {
    beforeEach(function() {
      return this.settings = this.select.selectr().data("selectr")["settings"];
    });
    afterEach(function() {
      return this.settings = null;
    });
    it("should contain default options", function() {
      return expect(this.settings).toBeDefined();
    });
    it("should have a default width of 250", function() {
      return expect(this.settings.width).toBe(250);
    });
    return it("should have a default height of 200", function() {
      return expect(this.settings.height).toBe(200);
    });
  });
  describe("data model", function() {
    beforeEach(function() {
      return this.select.selectr();
    });
    return it("should create a simple object representing the <option> data", function() {
      expect(this.select.data("selectr").hasOwnProperty("data")).toBeTruthy();
      return expect(this.select.data("selectr").data.length).toBe(this.select.find("option").length);
    });
  });
  return describe("UI setup", function() {
    beforeEach(function() {
      return this.select.selectr();
    });
    it("should hide the original input", function() {
      return expect(this.select).toBeHidden();
    });
    it("should create a wrapper as a sibling to original input", function() {
      return expect(this.select.next(".selectr-wrap")).toExist();
    });
    it("should use default width option for width if it is not provided", function() {
      return expect(this.select.next(".selectr-wrap").width()).toBe(this.select.data('selectr').settings.width);
    });
    it("should use the provided width option for width if it is provided", function() {
      var userWidth;
      userWidth = 400;
      this.select.selectr({
        width: userWidth
      });
      return expect(this.select.next(".selectr-wrap").width()).toBe(userWidth);
    });
    return describe("result list", function() {
      return it("should create a result list from the data model", function() {
        expect(this.select.next(".selectr-wrap").find(".selectr-results")).toExist();
        expect(this.select.next(".selectr-wrap").find(".selectr-results .selectr-item").length > 1).toBeTruthy();
        return expect($(this.select.next(".selectr-wrap").find(".selectr-results .selectr-item").get(4)).find("button").data("value")).toEqual(this.select.data("selectr").data[4].value);
      });
    });
  });
});
