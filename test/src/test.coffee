# = require_self
# = require_tree .

App = Em.Application.create()
App.setupForTesting()
App.injectTestHelpers()

beforeEach ->
  App.reset()
  @sinon = sinon.sandbox.create()
  @xhr = sinon.fakeServer.create()

afterEach ->
  @xhr.restore()
  @sinon.restore()

describe 'Test Environment', ->
  it 'should create a sane test environment', ->
    expect(Em).to.be.an 'object'
    expect(EMD).to.be.an 'object'
    expect(App).to.be.an 'object'
    expect(@xhr).to.be.an 'object'
    expect(@sinon).to.be.an 'object'