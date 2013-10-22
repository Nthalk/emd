# = require_self
# = require_tree .

describe 'sanity', ->
  it 'dist and libraries should be loaded', ->
    expect(Em).to.be.an('object')
    expect(EMD).to.be.an('object')


App = Em.Application.create()
App.setupForTesting()
App.injectTestHelpers()
@setup = ->
  App.reset()

