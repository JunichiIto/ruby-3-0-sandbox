require 'minitest/autorun'

class RubyTest < Minitest::Test
  def refute_syntax(script, message = nil, debug: false)
    err = assert_raises(SyntaxError) do
      RubyVM::InstructionSequence.compile(script)
    end
    puts err.message if debug
    if message
      assert_includes err.message, message
    end
  end

  def add(a, b, c)
    a + b + c
  end

  def add_with_description_2(a, ...)
    answer = add(a, ...)
    "answer is #{answer}"
  end

  def test_arguments_forwarding
    assert_equal "answer is 6", add_with_description_2(1, 2, 3)
  end

  def test_proc_arguments
    pr = proc{|*a, **kw| [a, kw]}
    assert_equal([[[1]], {}], pr.call([1]))
    assert_equal([[[1, {:a=>1}]], {}], pr.call([1, {a: 1}]))
  end

  def assert_global_safe
    assert_nil $SAFE
  end

  def test_yield
    refute_syntax(<<~RUBY, 'Invalid yield')
      def foo
        class << Object.new
          yield
        end
      end
    RUBY
  end

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

    # Worked in Ruby 2.7
    refute_syntax(<<~RUBY, "syntax error, unexpected `in'")
      {a: 0, b: 1} in {b:}
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
  end

  class C
    @@x = 1
  end

  module M
    @@x = 2
  end

  class D < C
    include M
    def foo
      @@x
    end
  end

  def test_class_var
    d = D.new
    e = assert_raises(RuntimeError) { d.foo }
    assert_equal "class variable @@x of RubyTest::M is overtaken by RubyTest::C", e.message

    # NOTE: accessing a class variable from the toplevel scope is now a RuntimeError
  end
end
