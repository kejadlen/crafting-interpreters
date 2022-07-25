require_relative "test_helper"

require "lox"

require "open3"

class TestLox < Lox::Test
  def test_error_on_more_than_one_arg
    lox_path = File.expand_path("../bin/lox", __dir__)
    o, s = Open3.capture2(lox_path, "foo", "bar")
    assert_equal 64, s.exitstatus
    assert_equal "Usage: #{lox_path} [script]\n", o
  end
end
