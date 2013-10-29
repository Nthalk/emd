describe 'attr.belongsTo', ->
  beforeEach setup
  it 'should have shorthand definition', ->
    expect(EMD.attr.hasMany).to.be.an('function')

  it 'should load', ->
    App.Parent = EMD.Model.extend ->
      children: EMD.has

