#frozen_string_literal: true
require 'minitest/autorun'

class FrozenStringTest < Minitest::Test
  def foo(str)
    "#{str}"
  end

  def test_frozen_string
    fr1 = 'a'
    fr2 = 'a'
    fr1_1 = foo(fr1)
    fr2_1 = foo(fr2)

    assert_same fr1, fr2
    refute_same fr1_1, fr2_1

    assert fr1.frozen?
    assert fr2.frozen?
    refute fr1_1.frozen?
    refute fr2_1.frozen?

    a = "#{123}"
    b = "#{123}"
    # assert_same a, b
    refute_same a, b

    # assert fr1.frozen?
    # assert fr2.frozen?
    refute a.frozen?
    refute b.frozen?
  end
end
