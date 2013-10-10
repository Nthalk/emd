var assert, expect, should;

should = chai.should();

expect = chai.expect;

assert = chai.assert;

describe('sanity', function() {
  return it('dist and libraries should be loaded', function() {
    should.exist(Em);
    return should.exist(D);
  });
});
