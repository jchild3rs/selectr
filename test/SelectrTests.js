jasmine.getStyleFixtures().fixturesPath = '/base/src/';

jasmine.getFixtures().fixturesPath = '/base/test/fixtures/';

describe("Selectr", function() {
  loadStyleFixtures('Selectr.css');
  beforeEach(function() {
    loadFixtures('selectElement.html.js');
    this.select = $("#select-fixture");
    return this.instance = this.select.selectr();
  });
  afterEach(function() {
    this.select = null;
    this.instance = null;
    return $('.selectr-wrap').remove();
  });
  it("should be chainable", function() {
    return expect(this.instance).toEqual(this.select);
  });
  describe("options", function() {
    it("should contain default options", function() {
      return expect($.fn.selectr.defaultOptions).toBeDefined();
    });
    return it("should have a default width of 250", function() {
      return expect($.fn.selectr.defaultOptions.width).toBe(250);
    });
  });
  return describe("UI setup", function() {
    it("should hide the original input", function() {
      return expect(this.select).toBeHidden();
    });
    describe("wrapper & dropdown", function() {
      beforeEach(function() {
        this.wrap = this.select.siblings(".selectr-wrap");
        return this.drop = this.wrap.find(".selectr-drop");
      });
      afterEach(function() {
        this.wrap = null;
        return this.drop = null;
      });
      it("should be a sibling to the original select", function() {
        return expect(this.wrap).toExist();
      });
      it("should have the class \"selectr-wrap\"", function() {
        return expect(this.wrap).toHaveClass("selectr-wrap");
      });
      it("should have a width based on settings", function() {
        return expect(this.wrap.width()).toEqual($.fn.selectr.defaultOptions.width);
      });
      it("should have a width based on user-defined settings", function() {
        var wrap;
        wrap = $("#select-fixture").selectr({
          width: 500
        }).siblings(".selectr-wrap");
        expect(wrap.width()).not.toEqual($.fn.selectr.defaultOptions.width);
        expect(wrap.width()).toEqual(500);
        return wrap = null;
      });
      it("should have a certain html layout if default", function() {
        return expect(this.wrap.find("> .selectr-toggle, > .selectr-search, > .selectr-drop")).toExist();
      });
      it("should have a dropdown", function() {
        return expect(this.drop).toExist();
      });
      it("should have a dropdown that is hidden by default", function() {
        return expect(this.drop).toBeHidden();
      });
      it("should have a dropdown that should show when toggle is clicked", function() {
        var toggle;
        toggle = this.wrap.find(".selectr-toggle");
        toggle.trigger("click");
        return expect(this.drop).not.toBeHidden();
      });
      return it("should have the class `.selectr-open` when the toggle is clicked", function() {
        var toggle;
        toggle = this.wrap.find(".selectr-toggle");
        expect(this.wrap).not.toHaveClass("selectr-open");
        toggle.trigger("click");
        return expect(this.wrap).toHaveClass("selectr-open");
      });
    });
    return describe("results", function() {
      it("should not show duplicates", function() {});
      return it("should create a unordered list, within the wrapper, using the <select>'s data", function() {
        var list;
        list = this.select.next(".selectr-wrap").find(".selectr-results");
        expect(this.select.find("option")).toHaveLength(list.find("li").length);
        expect(this.select.find("option").get(4).value).toEqual($(list.find("li").get(4)).find("button").text());
        expect(this.select.find("option").get(7).value).toEqual($(list.find("li").get(7)).find("button").text());
        return expect(this.select.find("option").get(5).value).not.toEqual($(list.find("li").get(7)).find("button").text());
      });
    });
  });
});
