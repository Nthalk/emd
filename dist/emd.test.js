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
describe('EMD.attr', function() {
  ({
    beforeEach: setup
  });
  it(' should define attributes', function() {
    var user;
    App.User = EMD.Model.extend({
      name: EMD.attr("name")
    });
    user = App.User.create();
    expect(user.get('name')).to.be(void 0);
    user.load({
      name: "a"
    });
    return expect(user.get('name')).to.be('a');
  });
  it('should allow defaults', function() {
    var user;
    App.User = EMD.Model.extend({
      name: EMD.attr("name", {
        if_null: 'carl'
      })
    });
    user = App.User.create();
    expect(user.get('name')).to.be('carl');
    user.load({
      name: "a"
    });
    return expect(user.get('name')).to.be('a');
  });
  it('should allow conversions', function() {
    var user;
    App.User = EMD.Model.extend({
      name: EMD.attr("name", {
        if_null: 'carl',
        convertFromData: function(name) {
          return name[0].toUpperCase() + name.substring(1);
        },
        convertToData: function(name) {
          return name.toLowerCase();
        }
      })
    });
    user = App.User.create();
    expect(user.get('name')).to.be('Carl');
    user.load({
      name: "ab"
    });
    expect(user.get('name')).to.be('Ab');
    return expect(user.toJson().name).to.be('ab');
  });
  describe('#belongsTo', function() {
    return it('should work', function() {
      var child, parent;
      App.Child = EMD.Model.extend({
        parent: EMD.attr.belongsTo({
          parent_id: 'App.Parent'
        })
      });
      App.Parent = EMD.Model.extend();
      parent = App.Parent.create({
        id: 1
      });
      child = App.Child.create();
      child.load({
        parent_id: 1
      });
      expect(child.get('parent')).to.equal(parent);
      child.set('parent', App.Parent.create({
        id: 2
      }));
      return expect(child.toJson().parent_id).to.equal(2);
    });
  });
  return describe('#hasMany', function() {
    return it('should work', function() {
      var child, children, parent;
      App.Child = EMD.Model.extend({
        url: 'http://children',
        parent: EMD.attr.belongsTo({
          parent_id: 'App.Parent'
        })
      });
      App.Parent = EMD.Model.extend({
        children: EMD.attr.hasMany({
          parent_id: 'App.Child'
        })
      });
      child = App.Child.create();
      parent = App.Parent.create();
      parent.load({
        id: 4
      });
      children = parent.get('children');
      expect(children.get('url')).to.equal(child.get('url'));
      return expect(children.get('query')).to.eql({
        parent_id: 4
      });
    });
  });
});

;

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
