should = chai.should()
expect = chai.expect
assert = chai.assert

describe 'sanity', ->
  it 'dist and libraries should be loaded', ->
    should.exist Em
    should.exist EMD
