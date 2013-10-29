describe 'Model', ->
  beforeEach: setup
  it 'Model should exist', ->
    expect(EMD.Model).to.be.a('function')
    App.User = EMD.Model.extend
      name: EMD.attr "name"
      emailAddress: EMD.attr "email_address"
      preferences: EMD.attr.object "preferences"

