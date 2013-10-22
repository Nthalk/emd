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
  return it('Should have shorthand definition', function() {
    return expect(EMD.attr.hasMany).to.be.an('function');
  });
});

;
describe('Model', function() {
  return it('Model should exist', function() {
    return expect(EMD.Model).to.be.an('function');
  });
});
