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

    assert fr1.object_id == fr2.object_id
    refute fr1_1.object_id == fr2_1.object_id

    assert fr1.frozen?
    assert fr2.frozen?
    refute fr1_1.frozen?
    refute fr2_1.frozen?
  end
end
