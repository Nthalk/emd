describe 'EMD.attr', ->
  beforeEach: setup
  it ' should define attributes', ->
    App.User = EMD.Model.extend
      name: EMD.attr "name"
    user = App.User.create()
    expect(user.get 'name').to.be undefined
    user.load {name: "a"}
    expect(user.get 'name').to.be 'a'

  it 'should allow defaults', ->
    App.User = EMD.Model.extend
      name: EMD.attr "name", if_null: 'carl'
    user = App.User.create()
    expect(user.get 'name').to.be 'carl'
    user.load {name: "a"}
    expect(user.get 'name').to.be 'a'

  it 'should allow conversions', ->
    App.User = EMD.Model.extend
      name: EMD.attr "name",
        if_null: 'carl',
        convertFromData: (name)->
          name[0].toUpperCase() + name.substring(1)
        convertToData: (name)->
          name.toLowerCase()

    user = App.User.create()
    expect(user.get 'name').to.be 'Carl'
    user.load {name: "ab"}
    expect(user.get 'name').to.be 'Ab'
    expect(user.toJson().name).to.be 'ab'

  describe '#belongsTo', ->
    it 'should work', ->
      App.Child = EMD.Model.extend
        parent: EMD.attr.belongsTo parent_id: 'App.Parent'
      App.Parent = EMD.Model.extend()

      parent = App.Parent.create(id: 1)
      child = App.Child.create()
      child.load parent_id: 1
      expect(child.get 'parent').to.equal parent
      child.set 'parent', App.Parent.create(id: 2)
      expect(child.toJson().parent_id).to.equal 2

  describe '#hasMany', ->
    it 'should work', ->
      App.Child = EMD.Model.extend
        url: 'http://children'
        parent: EMD.attr.belongsTo parent_id: 'App.Parent'
      App.Parent = EMD.Model.extend
        children: EMD.attr.hasMany parent_id: 'App.Child'

      child = App.Child.create()
      parent = App.Parent.create()
      parent.load id: 4
      children = parent.get 'children'
      expect(children.get 'url').to.equal child.get 'url'
      expect(children.get 'query').to.eql parent_id: 4
