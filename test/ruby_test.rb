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

  # TODO: RBS
  # TODO: TypeProf
  # TODO: --help pager echo $PAGER

  class NewArray < Array; end
  def test_array_subclass
    a = NewArray.new
    # Ruby 2.7 returns NewArray
    assert_kind_of Array, a.flatten
    # Array#drop
    # Array#drop_while
    # Array#flatten
    # Array#slice!
    # Array#slice/#[]
    # Array#take
    # Array#take_while
    # Array#uniq
    # Array#*
  end

  def test_env_except
    assert ENV.keys.include?("PATH")
    size = ENV.size

    refute ENV.except("PATH").keys.include?("PATH")
    assert_equal (size - 1), ENV.except("PATH").size
  end

  def test_hash_except
    h = {a: 1, b: 2, c: 3}
    assert h.include?(:b)
    assert_equal({a: 1, c: 3}, h.except(:b))
  end

  def test_hash_transform_keys
    # https://bugs.ruby-lang.org/issues/16274
    hash = {created: "2020-12-25", updated: "2020-12-31", author: "foo"}
    assert_equal(
      {created_at: "2020-12-25", update_time: "2020-12-31", author: "foo"},
      hash.transform_keys(created: :created_at, updated: :update_time)
    )
  end

  require "set"
  def test_clone_freeze
    # https://bugs.ruby-lang.org/issues/14266
    frozen_set = Set[].freeze
    cloned = frozen_set.clone(freeze: false)
    refute cloned.frozen?
    # Ruby 2.7ではtrue
    refute cloned.instance_variable_get(:@hash).frozen?

    cloned = frozen_set.clone(freeze: true)
    assert cloned.frozen?
    assert cloned.instance_variable_get(:@hash).frozen?

    cloned = frozen_set.clone
    assert cloned.frozen?
    assert cloned.instance_variable_get(:@hash).frozen?

    unfrozen_set = Set[]
    cloned = unfrozen_set.clone(freeze: true)
    # Ruby 2.7ではどちらもfalse
    assert cloned.frozen?
    assert cloned.instance_variable_get(:@hash).frozen?
  end

  def test_eval
    # Ruby 2.7
    # (irb):25: warning: __FILE__ in eval may not return location in binding; use Binding#source_location instead
    # (irb):25: warning: in `eval'
    assert_equal '(eval)', eval('__FILE__', binding)

    # Ruby 2.7
    # (irb):26: warning: __LINE__ in eval may not return location in binding; use Binding#source_location instead
    # (irb):26: warning: in `eval'
    assert_equal 1, eval('__LINE__', binding)
  end

  def to_lambda(&b)
    lambda(&b)
  end

  # TODO: なぜ変更する必要があったのかわからない
  def test_lambda
    # needs -w option
    # warning: lambda without a literal block is deprecated; use the proc without lambda instead
    obj = lambda(&:foo)
    assert obj.lambda?
    obj = lambda(&method(:test_lambda))
    assert obj.lambda?

    # no warning
    obj = proc(&:foo)
    # TODO: Ruby 2.7ではfalse
    assert obj.lambda?

    obj = to_lambda { 1 }
    refute obj.lambda?
  end
end
