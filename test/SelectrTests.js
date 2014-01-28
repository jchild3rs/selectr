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
    it("should have a default wrap width of 250", function() {
      return expect(this.settings.wrapWidth).toBe(250);
    });
    return it("should have a default wrap height of 200", function() {
      return expect(this.settings.wrapHeight).toBe(200);
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
  describe("UI setup", function() {
    var drop, wrap;
    drop = null;
    wrap = null;
    beforeEach(function() {
      this.originalTabIndex = this.select.attr('tabindex');
      this.select.selectr();
      wrap = this.select.next(".selectr-wrap");
      return drop = this.select.next(".selectr-wrap").find(".selectr-drop");
    });
    afterEach(function() {
      wrap = null;
      return drop = null;
    });
    it("should hide the original input", function() {
      return expect(this.select).toBeHidden();
    });
    it("should create a wrapper as a sibling to original input", function() {
      return expect(this.select.next(".selectr-wrap")).toExist();
    });
    it("should use default width option for width if it is not provided", function() {
      return expect(this.select.next(".selectr-wrap").width()).toBe(this.select.data('selectr').settings.wrapWidth);
    });
    it("should use the provided width option for width if it is provided", function() {
      var userWidth;
      userWidth = 400;
      this.select.selectr({
        wrapWidth: userWidth
      });
      return expect(this.select.next(".selectr-wrap").width()).toBe(userWidth);
    });
    it("should apply -1 to select's tabindex and update wrap with select's tabindex", function() {
      expect(this.select.attr("tabindex")).toBe("-1");
      return expect(this.select.next(".selectr-wrap").attr("tabindex")).toBe(this.select.data('selectr').settings.tabindex);
    });
    it("should have a dropdown", function() {
      return expect(drop).toExist();
    });
    it("should have a dropdown that is hidden by default", function() {
      return expect(drop).toBeHidden();
    });
    it("should have a dropdown that should show when toggle is clicked", function() {
      var toggle;
      toggle = wrap.find(".selectr-toggle");
      toggle.trigger("click.selectr");
      return expect(drop).not.toBeHidden();
    });
    return it("should have the class `.selectr-open` when the toggle is clicked", function() {
      var toggle;
      toggle = wrap.find(".selectr-toggle");
      expect(wrap).not.toHaveClass("selectr-open");
      toggle.trigger("click.selectr");
      return expect(wrap).toHaveClass("selectr-open");
    });
  });
  describe("result list", function() {
    it("should create a result list from the data model", function() {
      this.select.selectr();
      expect(this.select.next(".selectr-wrap").find(".selectr-results")).toExist();
      expect(this.select.next(".selectr-wrap").find(".selectr-results .selectr-item").length > 1).toBeTruthy();
      return expect($(this.select.next(".selectr-wrap").find(".selectr-results .selectr-item").get(4)).data("value")).toEqual(this.select.data("selectr").data[4].value);
    });
    return it("should have <option> data attached to each result item", function() {
      var item;
      this.select.selectr();
      item = this.select.next(".selectr-wrap").find(".selectr-item");
      expect(item).toExist();
      expect(item.data()).not.toBeEmpty();
      expect(item.data().value).toBeDefined();
      expect(item.data().selected).toBeDefined();
      return expect(item.data().disabled).toBeDefined();
    });
  });
  return describe("item selection", function() {
    return it("should populate the original input's value with the selected value", function() {
      var drop, items, randomItem, wrap;
      this.select.selectr();
      wrap = this.select.next(".selectr-wrap");
      wrap.find(".selectr-toggle").trigger("click.selectr");
      drop = wrap.find(".selectr-drop");
      expect(drop).toBeVisible();
      items = drop.find(".selectr-item");
      randomItem = items.get(Math.floor(Math.random() * items.length) + 1);
      $(randomItem).trigger("click");
      return expect(this.select.val()).toEqual($(randomItem).data("value"));
    });
  });
});
