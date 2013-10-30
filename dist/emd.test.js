var App;

App = Em.Application.create();

App.setupForTesting();

App.injectTestHelpers();

beforeEach(function() {
  App.reset();
  this.sinon = sinon.sandbox.create();
  return this.xhr = sinon.fakeServer.create();
});

afterEach(function() {
  this.xhr.restore();
  return this.sinon.restore();
});

describe('Test Environment', function() {
  return it('should create a sane test environment', function() {
    expect(Em).to.be.an('object');
    expect(EMD).to.be.an('object');
    expect(App).to.be.an('object');
    expect(this.xhr).to.be.an('object');
    return expect(this.sinon).to.be.an('object');
  });
});
describe('EMD.attr', function() {
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
      expect(child.toJson().parent_id).to.equal(2);
      parent = App.Parent.create();
      child.set('parent', parent);
      return expect(child.get("_data.parent_id")).to.equal(void 0);
    });
  });
  return describe('#hasMany', function() {
    it('should work', function() {
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
    return it('should allow complex querying', function() {
      var child, children, parent, parent_id;
      App.Child = EMD.Model.extend({
        url: 'http://children',
        visible: EMD.attr('visible'),
        parent: EMD.attr.belongsTo({
          parent_id: 'App.Parent'
        })
      });
      App.Parent = EMD.Model.extend({
        children: EMD.attr.hasMany('App.Child', {
          where: function() {
            return {
              parent: this,
              visible: true
            };
          }
        })
      });
      parent = App.Parent.create();
      children = parent.get('children');
      child = children.create();
      expect(child.get('parent')).to.equal(parent);
      expect(child.get('visible')).to.equal(true);
      expect(child.toJson().parent_id).to.equal(void 0);
      expect(child.toJson().visible).to.equal(true);
      parent.load({
        id: parent_id = 4
      });
      return expect(child.toJson().parent_id).to.equal(parent_id);
    });
  });
});
describe('EMD.Model', function() {
  it('should have a baseUrl', function() {
    var base_url, id, user;
    App.User = EMD.Model.extend({
      baseUrl: base_url = "/user"
    });
    user = App.User.load({
      id: id = 5
    });
    expect(user.get("url")).to.equal(base_url + ("/" + id));
    user = App.User.create();
    return expect(user.get("url")).to.equal(base_url);
  });
  return it('should load data from the baseUrl', function(done) {
    var base_url, headers, name, response, user;
    App.User = EMD.Model.extend({
      baseUrl: base_url = "/users",
      name: EMD.attr('name')
    });
    user = App.User.find(1);
    expect(user.get("isLoading")).to.equal(true);
    expect(user.get("isLoaded")).to.equal(false);
    response = JSON.stringify({
      user: {
        id: 1,
        name: name = "carl"
      }
    });
    headers = {
      "Content-Type": "application/json"
    };
    this.xhr.requests[0].respond(200, headers, response);
    return user.then(function() {
      expect(user.get("isLoading")).to.equal(false);
      expect(user.get("isLoaded")).to.equal(true);
      expect(user.get('name')).to.equal(name);
      return done();
    });
  });
});

;
