var App;

describe('sanity', function() {
  return it('dist and libraries should be loaded', function() {
    expect(Em).to.be.an('object');
    return expect(EMD).to.be.an('object');
  });
});

App = Em.Application.create();

App.setupForTesting();

App.injectTestHelpers();

this.setup = function() {
  return App.reset();
};
describe('attr.belongsTo', function() {
  beforeEach(setup);
  it('should have shorthand definition', function() {
    return expect(EMD.attr.hasMany).to.be.an('function');
  });
  return it('should load', function() {
    return App.Parent = EMD.Model.extend(function() {
      return {
        children: EMD.has
      };
    });
  });
});

;
describe('Model', function() {
  ({
    beforeEach: setup
  });
  return it('Model should exist', function() {
    expect(EMD.Model).to.be.a('function');
    return App.User = EMD.Model.extend({
      name: EMD.attr("name"),
      emailAddress: EMD.attr("email_address"),
      preferences: EMD.attr.object("preferences")
    });
  });
});
