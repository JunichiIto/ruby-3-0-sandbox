require 'minitest/autorun'

class KeywordArgsTest < Minitest::Test
  def test_version
    assert_equal '3.0.0', RUBY_VERSION
  end

  def f1(key: 0)
    key
  end

  def test_f1
    assert_raises(ArgumentError) { f1({key: 42}) }
    assert_equal 42, f1(**{key: 42})
  end

  def f2(**kw)
    kw
  end

  def test_f2
    assert_raises(ArgumentError) { f2({key: 42}) }
    assert_equal({key: 42}, f2(**{key: 42}))
  end

  def f3(h, **kw)
    {h: h, kw: kw}
  end

  def test_f3
    assert_raises(ArgumentError) { f3(key: 42) }
    assert_equal({:h=>{:key=>42}, :kw=>{}}, f3({key: 42}))
  end

  def f4(h, key: 0)
    {h: h, key: key}
  end

  def test_f4
    assert_raises(ArgumentError) { f4(key: 42) }
    assert_equal({:h=>{:key=>42}, :key=>0}, f4({key: 42}))
  end

  def f5(h={}, key: 0)
    {h: h, key: key}
  end

  def test_f5
    assert_raises(ArgumentError) { f5("key" => 43, key: 42) }

    # TODO: エラーにならない（Ruby 2.7でも）
    # assert_raises(ArgumentError) { f5({"key" => 43, key: 42}) }
    assert_equal({:h=>{"key"=>43, :key=>42}, :key=>0}, f5({"key" => 43, key: 42}))
    # Ruby 2.7だと
    # {:h=>{"key"=>43}, :key=>42}

    assert_equal({:h=>{"key"=>43}, :key=>42}, f5({"key" => 43}, key: 42))
  end

  def f6(opt={})
    opt
  end

  def test_f6
    assert_equal({:key=>42}, f6(key: 42))
  end

  def f7(**kw)
    kw
  end

  def test_f7
    assert_equal({"str" => 1}, f7("str" => 1))
  end

  def f8(h, **nil)
    h
  end

  def test_f8
    assert_raises(ArgumentError) { f8(key: 1) }
    assert_raises(ArgumentError) { f8(**{key: 1}) }
    assert_raises(ArgumentError) { f8("str" => 1) }
    assert_equal({key: 1}, f8({key: 1}))
    assert_equal({"str" => 1}, f8({"str" => 1}))
  end

  def f9(*a)
    a
  end

  def test_f9
    assert_equal [], f9(**{})
    assert_equal [{}], f9({})
  end

  def f10(a)
    a
  end

  def test_f10
    assert_raises(ArgumentError) { f10(**{}) }
    assert_equal({}, f10({}))
  end
end
