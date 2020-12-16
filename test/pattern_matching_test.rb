require 'minitest/autorun'
require './test/refute_syntax'

class PatternMatchinTest < Minitest::Test
  include RefuteSyntax

  def test_pattern_matching
    # no warning
    case [0, [1, 2, 3]]
    in [a, [b, *c]]
      assert_equal 0, a
      assert_equal 1, b
      assert_equal c, [2, 3]
    end
  end

  def test_one_line_pattern_matching
    {a: 0, b: 1} => {a:}
    assert_equal 0, a

    if {a: 0, b: 1} in {b:}
      assert_equal 1, b
    else
      raise
    end
    x = 1 if {s: 0, t: 1} in {s:}
    assert_equal 1, x

    if {a: 0, b: 1} in {c:}
      raise
    else
      assert true
    end
    refute_syntax(<<~RUBY)
      if {a: 0, b: 1} => {c:}
      end
    RUBY
  end

  def test_find_pattern
    case ["a", 1, "b", "c", 2, "d", "e", "f", 3]
    in [*pre, String => x, String => y, *post]
      assert_equal ["a", 1], pre
      assert_equal "b", x
      assert_equal "c", y
      assert_equal [2, "d", "e", "f", 3], post
    end

    case ['Alice', 'Bob', 'Carol']
    in ['Alice', *others]
      assert_equal(['Bob', 'Carol'], others)
    end

    case ['Bob', 'Carol', 'Alice']
    in [*others, 'Alice']
      assert_equal(['Bob', 'Carol'], others)
    end

    case ['Bob', 'Alice', 'Carol']
    in [*others_before, 'Alice', *others_after]
      assert_equal(['Bob'], others_before)
      assert_equal(['Carol'], others_after)
    end

    case ['Alice']
    in [*others_before, 'Alice', *others_after]
      assert_equal([], others_before)
      assert_equal([], others_after)
    end

    refute_syntax(<<~RUBY)
      case ['Bob', 'Alice', 'Carol', 'Dave']
      in [*others_before, 'Alice', *others_after, 'Dave']
        assert_equal(['Bob'], others_before)
        assert_equal(['Carol'], others_after)
      end
    RUBY
  end
end
