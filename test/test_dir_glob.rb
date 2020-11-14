require 'minitest/autorun'

# https://bugs.ruby-lang.org/attachments/3842
class TestDirGlob < Minitest::Test
  def setup
    `mkdir /tmp/rubytest/`
    ["001", "002", "003", "999"].each do |num|
      `touch /tmp/rubytest/#{num}.txt`
    end
  end

  def teardown
    `rm -rf /tmp/rubytest`
  end

  def test_glob
    res = Dir.glob("/tmp/rubytest/*.txt")
    assert_equal(res.sort, res)

    res = Dir.glob("/tmp/rubytest/*.txt", sort: false)
    refute_equal(res.sort, res)
    assert_equal(res.sort, res.sort)
  end

  def test_dir_accessor
    res = Dir["/tmp/rubytest/*.txt"]
    assert_equal(res.sort, res)

    res = Dir["/tmp/rubytest/*.txt", sort: false]
    refute_equal(res.sort, res)
    assert_equal(res.sort, res.sort)
  end
end
