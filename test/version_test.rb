require 'minitest/autorun'

class VersionTest < Minitest::Test
  def test_version
    assert_equal '3.0.0', RUBY_VERSION
  end
end
