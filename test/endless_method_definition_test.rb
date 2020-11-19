require 'minitest/autorun'
require './test/refute_syntax'

class EndlessMethodDefinitionTest < Minitest::Test
  include RefuteSyntax

  def square(x) = x * x

  def test_endless_method_definition
    assert_equal 9, square(3)
  end

  def test_setter_method
    refute_syntax(<<~RUBY)
      def age=(n) = @age = n
    RUBY
  end
end
