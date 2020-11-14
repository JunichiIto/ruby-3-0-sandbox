require 'minitest/autorun'

class EndlessMethodDefinitionTest < Minitest::Test
  def square(x) = x * x

  def test_endless_method_definition
    assert_equal 9, square(3)
  end
end
