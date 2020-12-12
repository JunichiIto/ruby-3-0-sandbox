require 'minitest/autorun'
require './test/refute_syntax'

module Warning
  def self.warn(*message, category: nil)
    super(*message.map { |msg| msg.chomp + " <<#{category}>>\n" })
  end
end

class RubyTest < Minitest::Test
  include RefuteSyntax

  def add(a, b, c)
    a + b + c
  end

  def add_with_description_2(a, ...)
    answer = add(a, ...)
    "answer is #{answer}"
  end

  def add_with_description_3(a, b, ...)
    answer = add(a, b, ...)
    "answer is #{answer}"
  end

  def test_arguments_forwarding
    assert_equal "answer is 6", add_with_description_2(1, 2, 3)
    assert_equal "answer is 15", add_with_description_3(4, 5, 6)
  end

  def test_proc_arguments
    pr = proc{|*a| a}
    assert_equal([[1]], pr.call([1]))

    pr = proc{|*a, **kw| [a, kw]}
    assert_equal([[[1]], {}], pr.call([1]))
    assert_equal([[[1, {:a=>1}]], {}], pr.call([1, {a: 1}]))
  end

  def assert_global_safe
    assert_nil $SAFE
  end

  def assert_global_kcode
    assert_nil $KCODE
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

  module CV
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
  end

  def test_class_var
    d = CV::D.new
    e = assert_raises(RuntimeError) { d.foo }
    assert_equal "class variable @@x of RubyTest::CV::M is overtaken by RubyTest::CV::C", e.message

    # NOTE: accessing a class variable from the toplevel scope is now a RuntimeError
  end

  # TODO: RBS
  # TODO: TypeProf
  # TODO: --help pager echo $PAGER

  class NewArray < Array; end
  def test_array_subclass
    a = NewArray.new
    # Ruby 2.7 returns NewArray
    assert_instance_of Array, a.flatten
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

  def test_dir_sort
    path = File.expand_path('../fixtures/*', __FILE__)
    assert_equal ['a.txt', 'b.txt', 'c.txt'], Dir.glob(path).map{|s| File.basename(s)}
    assert_equal ['a.txt', 'b.txt', 'c.txt'], Dir.glob(path, sort: false).map{|s| File.basename(s)}.sort

    assert_equal ['a.txt', 'b.txt', 'c.txt'], Dir[path].map{|s| File.basename(s)}
    assert_equal ['a.txt', 'b.txt', 'c.txt'], Dir[path, sort: false].map{|s| File.basename(s)}.sort
  end

  def test_env_except
    assert ENV.keys.include?("PATH")
    size = ENV.size

    refute ENV.except("PATH").keys.include?("PATH")
    assert_equal (size - 1), ENV.except("PATH").size

    assert_instance_of Object, ENV
    assert_instance_of Hash, ENV.except("PATH")
  end

  def test_hash_except
    h = {a: 1, b: 2, c: 3}
    assert h.include?(:b)
    assert_equal({a: 1, c: 3}, h.except(:b))
    assert_equal({b: 2}, h.except(:a, :c))
  end

  def test_hash_transform_keys
    # https://bugs.ruby-lang.org/issues/16274
    hash = {created: "2020-12-25", updated: "2020-12-31", author: "foo"}
    assert_equal(
      {created_at: "2020-12-25", update_time: "2020-12-31", author: "foo"},
      hash.transform_keys(created: :created_at, updated: :update_time)
    )
    assert_equal(
      {created_at: "2020-12-25", update_time: "2020-12-31", author: "foo"},
      hash.transform_keys do |key|
        case key
        when :created then :created_at
        when :updated then :update_time
        else key
        end
      end
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

  def test_lambda
    # needs -w option
    # warning: lambda without a literal block is deprecated; use the proc without lambda instead
    obj = lambda(&:foo)
    # Ruby 2.7ではfalse
    assert obj.lambda?
    obj = lambda(&method(:test_lambda))
    # Ruby 2.7でもtrue
    assert obj.lambda?

    # no warning
    obj = proc(&:foo)
    assert obj.lambda?

    obj = to_lambda { 1 }
    refute obj.lambda?
  end

  module MD
    class C; end
    module M1; end
    module M2; def foo; end end
  end

  def test_module_include
    MD::C.include MD::M1
    MD::M1.include MD::M2
    # Ruby 2.7ではM2が含まれない
    assert_equal [MD::C, MD::M1, MD::M2, Object, Minitest::Expectations, Kernel, BasicObject], MD::C.ancestors
    # Ruby 2.7ではfooが呼べない
    assert MD::C.new.respond_to?(:foo)
  end

  module Shoutable
    def shout
      "#{hello.upcase}!!!"
    end
  end
  module Speakable
    def hello
      'Hello'
    end
  end
  module Whisperable
    def hello
      msg = super
      "#{msg.downcase}..."
    end
  end
  class Person
    include Speakable
  end
  def test_person
    person = Person.new
    assert_equal 'Hello', person.hello
    Speakable.include Shoutable
    # Ruby 2.7では NoMethodError (undefined method `shout' for #<Person:0x00007feaa4a63c68>)
    assert_equal 'HELLO!!!', person.shout

    Speakable.prepend Whisperable
    # Ruby 2.7では Hello
    assert_equal 'hello...', person.hello
    assert_equal 'HELLO...!!!', person.shout

    p Person.ancestors
  end

  module StaticSample
    module Shoutable
      def shout
        "#{hello.upcase}!!!"
      end
    end
    module Whisperable
      def hello
        msg = super
        "#{msg.downcase}..."
      end
    end
    module Speakable
      include Shoutable
      prepend Whisperable
      def hello
        'Hello'
      end
    end
    class Person
      include Speakable
    end
  end
  def test_static_person
    person = StaticSample::Person.new
    assert_equal 'hello...', person.hello
    assert_equal 'HELLO...!!!', person.shout
  end

  def return_proc(&block)
    block
  end

  def return_procs(&block)
    proc_1 = return_proc(&block)
    proc_2 = return_proc(&block)
    [proc_1, proc_2]
  end

  def test_proc_eql
    proc_1, proc_2 = return_procs { }
    assert proc_1 == proc_2
    assert proc_1.eql?(proc_2)

    other_1, other_2 = return_procs { }
    refute proc_1 == other_1
    refute proc_1.eql?(other_1)
  end

  class NewString < String; end
  def test_string_subclass
    s = NewString.new
    # Ruby 2.7 returns NewString
    assert_instance_of String, s.upcase
    # String#*
    # String#capitalize
    # String#center
    # String#chomp
    # String#chop
    # String#delete
    # String#delete_prefix
    # String#delete_suffix
    # String#downcase
    # String#dump
    # String#each_char
    # String#each_grapheme_cluster
    # String#each_line
    # String#gsub
    # String#ljust
    # String#lstrip
    # String#partition
    # String#reverse
    # String#rjust
    # String#rpartition
    # String#rstrip
    # String#scrub
    # String#slice!
    # String#slice / String#[]
    # String#split
    # String#squeeze
    # String#strip
    # String#sub
    # String#succ / String#next
    # String#swapcase
    # String#tr
    # String#tr_s
    # String#upcase
  end

  def test_range_frozen
    assert (1..2).frozen?
    assert Range.new(1, 2).frozen?
  end

  # TODO: thread, Kernel.sleep関係
  # https://bugs.ruby-lang.org/issues/16786
  # TODO: ractor関係

  def test_symbol_to_proc
    # https://bugs.ruby-lang.org/issues/16260
    assert :to_s.to_proc.lambda?
  end

  def test_symbol_name
    assert_equal 'a', :a.name
    assert_equal 'a', :a.to_s

    assert :a.name.frozen?
    refute :a.to_s.frozen?

    assert :a.name.equal?(:a.name)
    refute :a.to_s.equal?(:a.to_s)
  end

  # Warning.warnのテストは省略

  # TODO: GC.auto_compact=, GC.auto_compact

  require 'ostruct'
  def test_open_struct_initialization
    # Ruby 2.7では ArgumentError (wrong number of arguments (given 0, expected 1))
    os = OpenStruct.new(method: :foo)
    assert_equal :foo, os.send(:method)
    assert_equal :foo, os.method

    assert_equal OpenStruct, os.method!(:to_s).owner
    # Ruby 2.7ではnil
    assert_equal '#<OpenStruct method=:foo>', os.to_s!
  end

  # Improved support for YAMLのテストは省略
  # https://bugs.ruby-lang.org/issues/8382
  # https://github.com/ruby/ostruct/commit/683c3d63e9fa5478e12d1fa0b09b3151f577cb57

  def test_regex_frozen
    assert(/\d+/.frozen?)
    refute Regexp.new('\\d+').frozen?

    re = /a/
    assert_raises(FrozenError) { def re.foo; end }

    re = Regexp.new('a')
    def re.foo; 123 end
    assert_equal 123, re.foo
  end

  # EXPERIMENTAL
  def test_hash_yield
    h = {a: 1}
    h.each do |k, v|
      assert_equal :a, k
      assert_equal 1, v
    end
    pr = proc do |k, v|
      assert_equal :a, k
      assert_equal 1, v
    end
    h.each(&pr)
    l_two = lambda do |k, v|
      assert_equal :a, k
      assert_equal 1, v
    end
    assert_raises(ArgumentError) { h.each(&l_two) }
    l_one = lambda do |(k, v)|
      assert_equal :a, k
      assert_equal 1, v
    end
    h.each(&l_one)
  end

  # TODO: When writing to STDOUT redirected to a closed pipe, no broken pipe error message will be shown now.
  # https://bugs.ruby-lang.org/issues/14413
  # https://github.com/ruby/ruby/commit/6f28ebd585fba1aff1c9591ced08ed11b68ba9e3

  def test_removed_constants
    assert_raises(NameError) { TRUE }
    assert_raises(NameError) { FALSE }
    assert_raises(NameError) { NIL }
  end

  def test_integer_zero
    assert_equal Integer, 1.method(:zero?).owner
  end

  ruby2_keywords def with_r2k(*args)
    args
  end
  def without_r2k(*args)
    args
  end
  def test_ruby2_keywords
    # Ruby 2.7では[{}]
    assert_equal [], with_r2k(**{})

    assert_equal [], without_r2k(**{})
  end

  def test_numbered_args
    refute_syntax(<<~RUBY, '_1 is reserved for numbered parameter')
      _1 = 123
    RUBY
  end

  def test_numbered_methods
    refute_syntax(<<~RUBY, '_1 is reserved for numbered parameter')
      def _1; end
    RUBY
  end

  # --backtrace-limit option
end
