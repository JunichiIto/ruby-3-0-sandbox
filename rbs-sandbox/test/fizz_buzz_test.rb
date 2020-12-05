require 'minitest/autorun'
require_relative '../lib/fizz_buzz'

class RubyTest < Minitest::Test
  def test_run_1
    assert_equal ['1'], FizzBuzz.run(1)
  end

  def test_run_15
    assert_equal ['1', '2', 'Fizz', '4', 'Buzz', 'Fizz', '7', '8', 'Fizz', 'Buzz', '11', 'Fizz', '13', '14', 'FizzBuzz'], FizzBuzz.run(15)
  end
end
