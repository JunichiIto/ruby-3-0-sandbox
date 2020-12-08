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

  # Modified from https://github.com/ruby/ruby/blob/v3_0_0_preview2/test/ruby/test_syntax.rb#L1426-L1445
  def f1 = 42
  def f2() = 42
  def f3(x) = x + 1
  def f4(x) = 1 / x rescue nil
  def f5(x)
    =
    x +
    1
  def f6(x) = @foo = x

  def test_others
    assert_equal 42, f1
    assert_equal 42, f2
    assert_equal 2, f3(1)
    assert_nil f4(0)
    assert_equal 2, f5(1)
    assert_equal 1, f6(1)
    assert_equal 1, @foo
    refute_syntax(<<~RUBY)
      def f7 x = x + 1
    RUBY
  end
end
