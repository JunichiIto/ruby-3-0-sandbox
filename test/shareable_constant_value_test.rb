# shareable_constant_value: literal

require 'minitest/autorun'

class ShareableConstantValueTest < Minitest::Test
  X = 'abc'
  Y = {foo: []}
  def test_constant
    assert X.frozen?
    assert Y.frozen?
    assert Y.keys.first.frozen?
    assert Y[:foo].frozen?
  end
end
